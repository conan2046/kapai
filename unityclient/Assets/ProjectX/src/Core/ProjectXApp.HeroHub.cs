using System;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private enum HeroHubTab
        {
            Formation,
            Heroes,
            Fragments
        }

        private HeroHubTab heroHubTab = HeroHubTab.Formation;
        private bool heroHubOpen;

        private void RequestHeroHub(HeroHubTab tab)
        {
            heroHubTab = tab;
            heroHubOpen = true;
        }

        private void ShowHeroHubTab(HeroHubTab tab)
        {
            heroHubTab = tab;
            heroHubOpen = true;
            EnsureHeroPresenter();
            ConfigureHeroHubFrame(tab);
            HideHeroHubContent();

            switch (tab)
            {
                case HeroHubTab.Formation:
                    ShowHeroRosterSurface();
                    break;
                case HeroHubTab.Heroes:
                    AttachHeroHubContent(heroBagView);
                    heroBagView?.SetVisible(true);
                    heroPresenter?.Render();
                    heroBagView?.GameObject.transform.SetAsLastSibling();
                    break;
                case HeroHubTab.Fragments:
                    ShowHeroFragmentSurface();
                    break;
            }

            RaiseHeroHubChrome();
            ApplyHeroHubSiblingOrder(tab);
            if (services?.UiStack.Current != oneLevelFrameView)
                services?.UiStack.Push(oneLevelFrameView);
            oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", CloseHeroHub, true);
        }

        private void ShowHeroRosterSurface()
        {
            EnsureHeroPresenter();
            // The first hub page is the existing 阵容 surface.  The actual
            // formation board remains a child action of btn_buzhen inside this
            // list/detail page and is not the default landing surface.
            SetHeroFramePageVisibility(true, true, false, false, false);
            ConfigureHeroFrame(false);
            AttachHeroHubContent(heroListView);
            AttachHeroHubContent(heroDetailView);
            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroPresenter?.Render();
            ConfigureHeroHubTabs(HeroHubTab.Formation);
            RaiseHeroHubChrome();
            ApplyHeroHubSiblingOrder(HeroHubTab.Formation);
        }

        private void ApplyHeroHubSiblingOrder(HeroHubTab tab)
        {
            Transform root = oneLevelFrameView?.GameObject.transform;
            if (root == null) return;

            // Panel_12 stays before the functional surfaces so its visible
            // background renders behind them while its chrome remains in the
            // requested hierarchy position.
            SetSiblingIndex(root.Find("Bg"), 0);
            SetSiblingIndex(root.Find("Panel_12"), 1);
            if (tab == HeroHubTab.Formation)
            {
                SetSiblingIndex(root.Find("DynamicUi_yingxiongInfoLayer"), 2);
                SetSiblingIndex(root.Find("DynamicUi_yingxiongListLayer"), 3);
            }
            else if (tab == HeroHubTab.Heroes)
            {
                SetSiblingIndex(root.Find("DynamicUi_yingxiongbeibao"), 2);
            }
            else if (heroEquipmentFragmentView != null)
            {
                SetSiblingIndex(heroEquipmentFragmentView.GameObject.transform, 2);
            }

            SetSiblingIndex(root.Find("GoldCheck"), 4);
        }

        private static void SetSiblingIndex(Transform target, int index)
        {
            if (target == null) return;
            target.SetSiblingIndex(Mathf.Clamp(index, 0, target.parent.childCount - 1));
        }

        private void ConfigureHeroHubFrame(HeroHubTab selected)
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            ConfigureHeroHubTabs(selected);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = selected == HeroHubTab.Formation ? "阵容"
                    : selected == HeroHubTab.Heroes ? "神将" : "神将碎片";
                title.alignment = TextAnchor.MiddleLeft;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
                title.rectTransform.anchoredPosition = new Vector2(192.8862f, 28.1468f);
                title.rectTransform.sizeDelta = new Vector2(240f, title.rectTransform.sizeDelta.y);
                Transform help = title.transform.Find("Button_1");
                if (help != null) help.gameObject.SetActive(false);
            }

            RefreshStandardCurrencyHeader(oneLevelFrameView.Binding, "Layer/GoldCheck");
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
        }

        private void ConfigureHeroHubTabs(HeroHubTab selected)
        {
            Transform panel = oneLevelFrameView?.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (panel == null || first == null) return;

            // ConfigureHeroFrame(false) hides the legacy bag tab container
            // while preparing the roster page. Re-enable the shared tab list
            // before installing the three hub buttons.
            panel.gameObject.SetActive(true);
            panel.parent?.gameObject.SetActive(true);

            Transform second = panel.Find("Button2_Runtime");
            if (second == null) second = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform;
            second.name = "Button2_Runtime";

            Transform third = panel.Find("Button3_Runtime");
            if (third == null) third = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform;
            third.name = "Button3_Runtime";

            // Panel_10 is shared with the legacy hero cultivation screen. Its
            // imported Button2/Button3/Button4 are the old
            // "突破/修炼/信息" tabs. They must not remain active underneath
            // the unified hero hub after returning from cultivation.
            foreach (Transform child in panel)
                if (child != first && child != second && child != third)
                    child.gameObject.SetActive(false);

            RectTransform firstRect = first as RectTransform;
            RectTransform secondRect = second as RectTransform;
            RectTransform thirdRect = third as RectTransform;
            if (firstRect != null && secondRect != null)
                secondRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f);
            if (firstRect != null && thirdRect != null)
                thirdRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -200f);

            SetHeroHubTab(first, "布阵", selected == HeroHubTab.Formation);
            SetHeroHubTab(second, "神将", selected == HeroHubTab.Heroes);
            SetHeroHubTab(third, "碎片", selected == HeroHubTab.Fragments);
            BindHeroHubTab(first, HeroHubTab.Formation);
            BindHeroHubTab(second, HeroHubTab.Heroes);
            BindHeroHubTab(third, HeroHubTab.Fragments);
        }

        private void SetHeroHubTab(Transform tab, string text, bool selected)
        {
            if (tab == null) return;
            SetTabText(tab, text, selected);
            tab.gameObject.SetActive(true);
        }

        private void BindHeroHubTab(Transform tab, HeroHubTab target)
        {
            Button button = EnsureTabClick(tab);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => ShowHeroHubTab(target));
        }

        private void HideHeroHubContent()
        {
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            if (formationPopupView != null)
            {
                formationPopupView.SetVisible(false);
                RestoreHeroFormationPopupSurface();
            }
        }

        private void ShowHeroFormationSurface()
        {
            formationPopupView = formationPopupView
                ?? services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangzhenxingLayer");
            if (formationPopupView == null)
                throw new InvalidOperationException("Formation surface CocosUiBinding was not found.");
            formationPopupPresenter = formationPopupPresenter ?? new FormationPopupPresenter(
                formationPopupView, services.Formation, services.Heroes, services.Bag,
                services.Currencies, services.Resources,
                (sourcePosition, targetPosition) => InvokeLuaOrFail(onFormationSwap,
                    "Hero.FormationSwap", sourcePosition, targetPosition),
                formationId => InvokeLuaOrFail(onFormationUpgrade, "Hero.FormationUpgrade", formationId),
                formationId => InvokeLuaOrFail(onFormationUse, "Hero.FormationUse", formationId),
                message => ShowToast(message, 2f), CloseHeroHub);

            PrepareHeroFormationSurface(true);
            AttachHeroHubContent(formationPopupView);
            // The formation surface carries its own battle-board background.
            // The standard OneLevelFrame paper would otherwise cover it when
            // this legacy popup is embedded into the shared hero hub.
            SetBoundVisible(oneLevelFrameView, "Layer/Bg", false);
            formationPopupView.SetVisible(true);
            formationPopupPresenter.Render();
            formationPopupPresenter.RefreshCloseInteraction();
            formationPopupView.GameObject.transform.SetAsLastSibling();
            RaiseHeroHubChrome();
        }

        private void ShowHeroFragmentSurface()
        {
            heroEquipmentFragmentView = heroEquipmentFragmentView
                ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeisuipian")
                ?? UiPrefabLoader.Load("HeroEquipmentFragment", GetDynamicUiRoot());
            if (heroEquipmentFragmentView == null)
                throw new InvalidOperationException("Hero fragment CocosUiBinding was not found.");
            if (!heroEquipmentFragmentBagSubscribed)
            {
                services.Bag.Changed += HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = true;
            }
            heroFragmentBagActive = true;
            AttachHeroHubContent(heroEquipmentFragmentView);
            heroEquipmentFragmentView.SetVisible(true);
            heroEquipmentFragmentView.GameObject.transform.SetAsLastSibling();
            RenderHeroFragments();
            RaiseHeroHubChrome();
            ApplyHeroHubSiblingOrder(HeroHubTab.Fragments);
        }

        private void RaiseHeroHubChrome()
        {
            if (oneLevelFrameView == null) return;
            Transform root = oneLevelFrameView.GameObject.transform;
            Transform panel = oneLevelFrameView.Binding.Find("Layer/Panel_12")?.transform;
            Transform gold = oneLevelFrameView.Binding.Find("Layer/GoldCheck")?.transform;
            if (panel != null) panel.SetAsLastSibling();
            if (gold != null) gold.SetAsLastSibling();
            // The title and right-side tabs must remain above the embedded
            // formation/fragment surfaces while retaining the shared canvas.
            if (root.childCount > 0 && panel != null) panel.SetAsLastSibling();
            if (gold != null) gold.SetAsLastSibling();
        }

        private void AttachHeroHubContent(CocosUiView content)
        {
            if (content == null || !content.IsAlive) return;
            EnsureOneLevelFrame().AttachContent(content);
            NormalizeHeroHubRect(oneLevelFrameView?.GameObject.transform as RectTransform);
            NormalizeHeroHubRect(content.GameObject.transform as RectTransform);
        }

        private static void NormalizeHeroHubRect(RectTransform rect)
        {
            if (rect == null) return;
            rect.pivot = new Vector2(0f, 1f);
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }

        private void CloseHeroHub()
        {
            heroHubOpen = false;
            heroFragmentBagActive = false;
            heroEquipmentFragmentView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            if (formationPopupView != null)
            {
                formationPopupView.SetVisible(false);
                RestoreHeroFormationPopupSurface();
            }
            SetOneLevelFrameVisible(false);
            if (services?.UiStack.Current == oneLevelFrameView) services.UiStack.Pop();
        }

        private void PrepareHeroFormationSurface(bool embedded)
        {
            if (formationPopupView == null) return;
            if (embedded)
            {
                EnsureOneLevelFrame().AttachContent(formationPopupView);
                // The formation prefab's own Bg contains the board and hero
                // slots. Keep it visible when embedded; only the shared hub
                // paper background is disabled by ShowHeroFormationSurface.
                SetBoundVisible(formationPopupView, "Layer/Bg", true);
                SetBoundVisible(formationPopupView, "Layer/FormationUI", true);
            }
            else
            {
                RestoreHeroFormationPopupSurface();
                SetBoundVisible(formationPopupView, "Layer/Bg", true);
            }
        }

        private void RestoreHeroFormationPopupSurface()
        {
            if (formationPopupView == null) return;
            Transform dynamicRoot = GetDynamicUiRoot();
            if (dynamicRoot != null && formationPopupView.GameObject.transform.parent != dynamicRoot)
                formationPopupView.GameObject.transform.SetParent(dynamicRoot, false);
            SetBoundVisible(formationPopupView, "Layer/Bg", true);
        }
    }
}
