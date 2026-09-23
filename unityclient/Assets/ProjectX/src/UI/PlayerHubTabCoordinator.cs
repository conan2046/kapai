using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public enum PlayerHubTab
    {
        JingJie,
        Bag,
        Mail,
        Settings
    }

    /// <summary>
    /// Owns the shared OneLevelLayer player-hub tab strip.
    /// Feature code owns content and data; this class owns only tab lifetime,
    /// selected state, click listeners and stale-tab cleanup.
    /// </summary>
    public sealed class PlayerHubTabCoordinator
    {
        private static readonly string[] Labels = { "境界", "背包", "邮件", "系统" };
        private readonly CocosUiView frameView;
        private readonly Action<PlayerHubTab> onSelected;

        public PlayerHubTabCoordinator(CocosUiView frameView, Action<PlayerHubTab> onSelected)
        {
            this.frameView = frameView ?? throw new ArgumentNullException(nameof(frameView));
            this.onSelected = onSelected ?? throw new ArgumentNullException(nameof(onSelected));
        }

        public PlayerHubTab CurrentTab { get; private set; }
        public int VisibleTabCount { get; private set; }

        public void Configure(PlayerHubTab selected)
        {
            Transform panel = frameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (first == null)
            {
                VisibleTabCount = 0;
                return;
            }

            Transform[] tabs =
            {
                first,
                EnsureRuntimeTab(panel, "Button2_Runtime", first, -100f),
                EnsureRuntimeTab(panel, "Button3_Runtime", first, -200f),
                EnsureRuntimeTab(panel, "Button4_Runtime", first, -300f)
            };
            int selectedIndex = (int)selected;
            for (int index = 0; index < tabs.Length; index++)
            {
                Transform tab = tabs[index];
                if (tab == null) continue;
                tab.gameObject.SetActive(true);
                SetTabText(tab, Labels[index], index == selectedIndex);
                Button button = EnsureTabClick(tab);
                button.onClick.RemoveAllListeners();
                PlayerHubTab target = (PlayerHubTab)index;
                button.onClick.AddListener(() => onSelected(target));
            }

            if (panel != null)
            {
                foreach (Transform child in panel)
                {
                    if (child != tabs[0] && child != tabs[1] && child != tabs[2] && child != tabs[3])
                        child.gameObject.SetActive(false);
                }
            }

            EnsureTabHierarchyOrder(panel, tabs);

            CurrentTab = selected;
            VisibleTabCount = tabs.Length;
        }

        private static void EnsureTabHierarchyOrder(Transform panel, Transform[] tabs)
        {
            if (panel == null || tabs == null) return;

            bool alreadyOrdered = true;
            for (int index = 0; index < tabs.Length; index++)
            {
                Transform tab = tabs[index];
                if (tab == null || tab.parent != panel || tab.GetSiblingIndex() != index)
                {
                    alreadyOrdered = false;
                    break;
                }
            }

            // Runtime tabs are created beside legacy Cocos tabs. Establish the
            // authored order once, then normal tab switches never move them.
            if (alreadyOrdered) return;
            for (int index = 0; index < tabs.Length; index++)
            {
                Transform tab = tabs[index];
                if (tab != null && tab.parent == panel)
                    tab.SetSiblingIndex(index);
            }
        }

        private static Transform EnsureRuntimeTab(Transform panel, string name, Transform template, float yOffset)
        {
            if (panel == null || template == null) return null;
            Transform tab = panel.Find(name);
            if (tab == null)
            {
                tab = UnityEngine.Object.Instantiate(template.gameObject, panel, false).transform;
                tab.name = name;
            }
            RectTransform source = template as RectTransform;
            RectTransform target = tab as RectTransform;
            if (source != null && target != null)
                target.anchoredPosition = source.anchoredPosition + new Vector2(0f, yOffset);
            return tab;
        }

        private static Button EnsureTabClick(Transform tab)
        {
            Graphic own = tab.GetComponent<Graphic>();
            if (own != null) own.raycastTarget = true;
            Button button = tab.GetComponent<Button>();
            if (button == null) button = tab.gameObject.AddComponent<Button>();

            Transform carrier = tab.Find("RuntimeClickArea");
            Image carrierImage;
            if (carrier == null)
            {
                GameObject carrierObject = new GameObject("RuntimeClickArea", typeof(RectTransform), typeof(Image));
                carrier = carrierObject.transform;
                carrier.SetParent(tab, false);
                carrierImage = carrierObject.GetComponent<Image>();
                RectTransform carrierRect = carrier as RectTransform;
                carrierRect.anchorMin = Vector2.zero;
                carrierRect.anchorMax = Vector2.one;
                carrierRect.offsetMin = Vector2.zero;
                carrierRect.offsetMax = Vector2.zero;
            }
            else
            {
                carrierImage = carrier.GetComponent<Image>();
                if (carrierImage == null) carrierImage = carrier.gameObject.AddComponent<Image>();
            }

            carrierImage.color = new Color(0f, 0f, 0f, 0f);
            carrierImage.raycastTarget = true;
            if (carrier.GetSiblingIndex() != tab.childCount - 1)
                carrier.SetSiblingIndex(tab.childCount - 1);
            button.transition = Selectable.Transition.None;
            button.targetGraphic = carrierImage;
            button.interactable = true;
            UiButtonPressFeedback.Ensure(button);
            return button;
        }

        private static void SetTabText(Transform tab, string value, bool selected)
        {
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null)
            {
                normal.text = value;
                normal.gameObject.SetActive(!selected);
            }
            if (chosen != null) chosen.text = value;
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Image background = tab.GetComponent<Image>();
            if (background != null)
            {
                background.color = selected ? Color.white : new Color(1f, 1f, 1f, 0f);
                background.raycastTarget = true;
            }
        }
    }
}
