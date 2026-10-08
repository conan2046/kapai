using System;
using UnityEngine;

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

}
