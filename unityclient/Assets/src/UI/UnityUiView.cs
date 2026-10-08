using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Unity Transform-based view access for modules being removed from the
    /// Cocos identity and ActionTag compatibility layer.
    /// </summary>
    public sealed class UnityUiView : IUiStackView
    {
        private readonly GameObject root;
        private readonly Dictionary<string, GameObject> nodesByPath =
            new Dictionary<string, GameObject>(StringComparer.Ordinal);

        public UnityUiView(GameObject root)
        {
            this.root = root != null ? root : throw new ArgumentNullException(nameof(root));
            UiViewSetup.Initialize(this.root);
        }

        public GameObject GameObject => root != null ? root : null;
        public bool IsAlive => root != null;

        public GameObject FindNode(string path)
        {
            if (root == null || string.IsNullOrWhiteSpace(path)) return null;
            if (nodesByPath.TryGetValue(path, out GameObject cached) && cached != null)
                return cached;

            Transform target = root.transform.Find(path);
            if (target == null && path.StartsWith("Layer/", StringComparison.Ordinal))
                target = root.transform.Find(path.Substring("Layer/".Length));
            if (target == null) return null;

            nodesByPath[path] = target.gameObject;
            return target.gameObject;
        }

        public void SetVisible(bool visible)
        {
            if (root != null) root.SetActive(visible);
        }

        public void ShowPopup()
        {
            if (root == null) return;
            root.SetActive(true);
            if (root.transform.parent != null) root.transform.SetAsLastSibling();
        }

        public Button BindClick(string path, Action callback, bool addButtonIfMissing = false)
        {
            if (root == null) throw new InvalidOperationException("The UI view has already been destroyed.");
            GameObject node = FindNode(path);
            if (node == null) throw new InvalidOperationException($"UI node was not found: {path}");

            return BindClickNode(node, callback, addButtonIfMissing, path);
        }

        public Button BindClickNode(GameObject node, Action callback, bool addButtonIfMissing = false, string nodePath = null)
        {
            if (root == null) throw new InvalidOperationException("The UI view has already been destroyed.");
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
            if (button.targetGraphic == null)
            {
                Image hitTarget = node.GetComponent<Image>() ?? node.AddComponent<Image>();
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
