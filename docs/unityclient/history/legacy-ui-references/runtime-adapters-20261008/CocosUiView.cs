using System;
using System.Collections.Generic;
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
        public OneLevelFrameCoordinator(UnityUiView view)
        {
            View = view ?? throw new ArgumentNullException(nameof(view));
        }

        public UnityUiView View { get; }
        public OneLevelFrameMode Mode { get; private set; } = OneLevelFrameMode.Hidden;

        public void SetVisible(bool visible) => View.SetVisible(visible);

        public void AttachContent(IUiStackView content, bool keepSiblingOrder = false)
        {
            if (content == null || !content.IsAlive || content.GameObject == null) return;

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
            GameObject target = View.FindNode(path);
            if (target != null) target.SetActive(active);
        }
    }

    public sealed class CocosUiView : IUiStackView
    {
        private readonly Dictionary<string, GameObject> nodesByUnityPath =
            new Dictionary<string, GameObject>(StringComparer.Ordinal);
        private readonly GameObject root;
        private readonly UiPrefabIdentity identity;

        public CocosUiView(UiPrefabIdentity identity)
            : this(identity != null ? identity.gameObject : null, identity)
        {
            if (identity == null) throw new ArgumentNullException(nameof(identity));
        }

        public CocosUiView(GameObject root)
            : this(root, root != null
                ? root.GetComponent<UiPrefabIdentity>() ?? root.GetComponentInChildren<UiPrefabIdentity>(true)
                : null)
        {
        }

        private CocosUiView(GameObject root, UiPrefabIdentity identity)
        {
            this.root = root != null ? root : throw new ArgumentNullException(nameof(root));
            this.identity = identity;
            InitializeRoot();
        }

        public UiPrefabIdentity Identity => identity;
        public bool IsAlive => root != null;
        public GameObject GameObject => IsAlive ? root : null;

        private void InitializeRoot()
        {
            UiViewSetup.Initialize(root);
        }

        public GameObject FindNode(string unityPath)
        {
            if (!IsAlive || string.IsNullOrWhiteSpace(unityPath)) return null;
            if (nodesByUnityPath.TryGetValue(unityPath, out GameObject cached) && cached != null)
                return cached;

            GameObject identified = identity != null ? identity.Find(unityPath) : null;
            if (identified != null)
            {
                nodesByUnityPath[unityPath] = identified;
                return identified;
            }

            Transform rootTransform = root.transform;
            Transform resolved = rootTransform.Find(unityPath);
            if (resolved == null && unityPath.StartsWith("Layer/", StringComparison.Ordinal))
                resolved = rootTransform.Find(unityPath.Substring("Layer/".Length));
            if (resolved == null) return null;

            GameObject target = resolved.gameObject;
            nodesByUnityPath[unityPath] = target;
            return target;
        }

        public GameObject GetSerializedNodeByActionTag(int actionTag, string expectedSource, string expectedPath)
        {
            if (!IsAlive) throw new InvalidOperationException("The UI view has already been destroyed.");
            if (identity == null)
                throw new InvalidOperationException("Serialized ActionTag lookup is unavailable for a path-only UI view.");
            if (string.IsNullOrWhiteSpace(expectedSource) || string.IsNullOrWhiteSpace(expectedPath))
                throw new ArgumentException("A serialized node requires its expected source and path.");
            if (!string.Equals(identity.Source, expectedSource, StringComparison.Ordinal))
                throw new InvalidOperationException(
                    $"UI node source mismatch for ActionTag {actionTag}: expected {expectedSource}, got {identity.Source}.");

            CocosNodeReference match = null;
            IReadOnlyList<CocosNodeReference> nodes = identity.Nodes;
            for (int index = 0; nodes != null && index < nodes.Count; index++)
            {
                CocosNodeReference candidate = nodes[index];
                if (candidate == null || candidate.actionTag != actionTag) continue;
                if (match != null)
                    throw new InvalidOperationException(
                        $"UI node ActionTag is not unique in {expectedSource}: {actionTag}.");
                match = candidate;
            }

            if (match == null || match.target == null)
                throw new InvalidOperationException(
                    $"Serialized UI node was not found in {expectedSource}: ActionTag {actionTag}.");
            if (!string.Equals(match.path, expectedPath, StringComparison.Ordinal))
                throw new InvalidOperationException(
                    $"UI node path mismatch for ActionTag {actionTag}: expected {expectedPath}, got {match.path}.");

            return match.target;
        }

        public GameObject GetSerializedNodeByActionTag(int actionTag)
        {
            if (!IsAlive) throw new InvalidOperationException("The UI view has already been destroyed.");
            if (identity == null)
                throw new InvalidOperationException("Serialized ActionTag lookup is unavailable for a path-only UI view.");
            CocosNodeReference match = null;
            IReadOnlyList<CocosNodeReference> nodes = identity.Nodes;
            for (int index = 0; nodes != null && index < nodes.Count; index++)
            {
                CocosNodeReference candidate = nodes[index];
                if (candidate == null || candidate.actionTag != actionTag) continue;
                if (match != null)
                    throw new InvalidOperationException($"UI node ActionTag is not unique: {actionTag}.");
                match = candidate;
            }
            if (match == null || match.target == null)
                throw new InvalidOperationException($"Serialized UI node was not found: ActionTag {actionTag}.");
            return match.target;
        }

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
            GameObject node = FindNode(nodePath);
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

    }
}
