using System;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class CocosUiView
    {
        public CocosUiView(CocosUiBinding binding)
        {
            Binding = binding ?? throw new ArgumentNullException(nameof(binding));
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

        public Button BindClick(string nodePath, Action callback, bool addButtonIfMissing = false)
        {
            if (!IsAlive) throw new InvalidOperationException("The UI view has already been destroyed.");
            GameObject node = Binding.Find(nodePath);
            if (node == null)
                throw new InvalidOperationException($"UI node was not found: {nodePath}");
            Button button = node.GetComponent<Button>();
            if (button == null && addButtonIfMissing)
            {
                button = node.AddComponent<Button>();
                button.targetGraphic = node.GetComponent<Graphic>();
            }
            if (button == null)
                throw new InvalidOperationException($"Button component was not found: {nodePath}");
            button.interactable = true;
            if (button.targetGraphic == null)
                button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
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
