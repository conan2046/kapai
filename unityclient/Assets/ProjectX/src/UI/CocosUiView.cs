using System;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public enum OneLevelFrameMode
    {
        Hidden,
        Standard,
        Fish,
        FishBasket,
        FengShenStory
    }

    public sealed class OneLevelFrameCoordinator
    {
        public OneLevelFrameCoordinator(CocosUiView view)
        {
            View = view ?? throw new ArgumentNullException(nameof(view));
        }

        public CocosUiView View { get; }
        public OneLevelFrameMode Mode { get; private set; } = OneLevelFrameMode.Hidden;

        public void SetVisible(bool visible) => View.SetVisible(visible);

        public void AttachContent(CocosUiView content, bool keepSiblingOrder = false)
        {
            if (content == null || !content.IsAlive) return;

            Transform frame = View.GameObject.transform;
            Transform contentTransform = content.GameObject.transform;
            if (contentTransform.parent != frame)
                contentTransform.SetParent(frame, false);
            if (!keepSiblingOrder)
                contentTransform.SetAsLastSibling();
        }

        public void Apply(OneLevelFrameMode mode)
        {
            Mode = mode;
            if (mode == OneLevelFrameMode.Hidden)
            {
                View.SetVisible(false);
                return;
            }

            NormalizeFrameRect();
            View.SetVisible(true);
            bool standard = mode == OneLevelFrameMode.Standard;
            bool fish = mode == OneLevelFrameMode.Fish;
            bool fengShenStory = mode == OneLevelFrameMode.FengShenStory;
            SetActive("Layer/Bg", standard || fengShenStory);
            SetActive("Layer/Panel_12", standard || fish);
            SetActive("Layer/Panel_12/BlackBg", false);
            SetActive("Layer/Panel_12/Bg", standard);
            SetActive("Layer/Panel_12/Title", standard || fish);
            SetActive("Layer/Panel_12/Bg/Btn_ListView", standard);
            SetActive("Layer/Panel_12/Bg/Btn_ListView/Panel_10", standard);
            SetActive("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1", standard);
            SetActive("Layer/Panel_12/SubBtnList", false);
            SetActive("Layer/GoldCheck", standard);
            SetActive("Layer/GoldCheck/GoldIcon1", standard);
            SetActive("Layer/GoldCheck/GoldIcon3", standard);
            SetActive("Layer/GoldCheck/GoldIcon4", standard);
        }

        private void NormalizeFrameRect()
        {
            RectTransform root = View.GameObject.transform as RectTransform;
            if (root == null) return;

            // Fish temporarily stretches the shared frame. When another module
            // switches it back to a point anchor, Unity otherwise preserves the
            // stretched sizeDelta (0, 0) and places the whole UI above the screen.
            root.pivot = new Vector2(0f, 1f);
            root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
            root.anchoredPosition = Vector2.zero;
            root.sizeDelta = new Vector2(1334f, 750f);
            root.localScale = Vector3.one;
            root.localRotation = Quaternion.identity;
        }

        private void SetActive(string path, bool active)
        {
            GameObject target = View.Binding.Find(path);
            if (target != null) target.SetActive(active);
        }
    }

    public sealed class CocosUiView
    {
        public CocosUiView(CocosUiBinding binding)
        {
            Binding = binding ?? throw new ArgumentNullException(nameof(binding));
            if (Binding.GetComponent<UiButtonFeedbackScope>() == null)
                Binding.gameObject.AddComponent<UiButtonFeedbackScope>();
            ApplyLegacyTextPixelRoundingPadding(Binding.gameObject);
        }

        public CocosUiBinding Binding { get; }
        public bool IsAlive => Binding != null;
        public GameObject GameObject => IsAlive ? Binding.gameObject : null;

        public void SetVisible(bool visible)
        {
            GameObject gameObject = GameObject;
            if (gameObject != null) gameObject.SetActive(visible);
        }

        /// <summary>
        /// Shows a modal/popup view above its current parent's other children.
        /// Functional pages must use SetVisible instead so their reserved
        /// sibling order remains stable.
        /// </summary>
        public void ShowPopup()
        {
            GameObject gameObject = GameObject;
            if (gameObject == null) return;
            gameObject.SetActive(true);
            if (gameObject.transform.parent != null)
                gameObject.transform.SetAsLastSibling();
        }

        public Button BindClick(string nodePath, Action callback, bool addButtonIfMissing = false)
        {
            if (!IsAlive) throw new InvalidOperationException("The UI view has already been destroyed.");
            GameObject node = Binding.Find(nodePath);
            if (node == null)
                throw new InvalidOperationException($"UI node was not found: {nodePath}");

            return BindClickNode(node, callback, addButtonIfMissing, nodePath);
        }

        public Button BindClickNode(GameObject node, Action callback, bool addButtonIfMissing = false, string nodePath = null)
        {
            if (!IsAlive) throw new InvalidOperationException("The UI view has already been destroyed.");
            if (node == null) throw new InvalidOperationException($"UI node was not found: {nodePath ?? "<null>"}");
            Button button = node.GetComponent<Button>();
            if (button == null && addButtonIfMissing)
            {
                button = node.AddComponent<Button>();
                button.targetGraphic = node.GetComponent<Graphic>();
            }
            if (button == null)
                throw new InvalidOperationException($"Button component was not found: {nodePath ?? node.name}");
            UiButtonPressFeedback.Ensure(button);
            button.interactable = true;
            if (button.targetGraphic == null)
                button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);

            // Some moved legacy buttons have no usable Graphic of their own.
            // Add a transparent hit target so the Unity Button stays clickable
            // after the hierarchy migration.
            if (button.targetGraphic == null)
            {
                Image hitTarget = node.GetComponent<Image>();
                if (hitTarget == null) hitTarget = node.AddComponent<Image>();
                hitTarget.color = new Color(0f, 0f, 0f, 0f);
                hitTarget.raycastTarget = true;
                button.targetGraphic = hitTarget;
            }

            if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private static void ApplyLegacyTextPixelRoundingPadding(GameObject root)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
            {
                if (text == null || string.IsNullOrEmpty(text.text)
                    || text.verticalOverflow != VerticalWrapMode.Truncate) continue;

                RectTransform rect = text.rectTransform;
                float currentHeight = rect.rect.height;
                float preferredHeight = text.preferredHeight;
                float canvasScale = text.canvas != null ? Mathf.Max(0.01f, text.canvas.scaleFactor) : 1f;
                float oneScreenPixel = 1f / canvasScale;
                float shortfall = preferredHeight - currentHeight;
                if (shortfall <= 0f || shortfall > oneScreenPixel) continue;

                rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, preferredHeight + oneScreenPixel);
                text.SetVerticesDirty();
            }
        }
    }
}
