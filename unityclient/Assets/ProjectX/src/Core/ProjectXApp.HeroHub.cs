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

        private bool TryRestoreHeroHubAfterNestedSurface()
        {
            if (!heroHubOpen) return false;
            ShowHeroHubTab(heroHubTab);
            return true;
        }

        private void SetHeroHubTabStripVisible(bool visible)
        {
            GameObject tabs = oneLevelFrameView?.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView");
            if (tabs != null) tabs.SetActive(visible);
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
                    break;
                case HeroHubTab.Fragments:
                    ShowHeroFragmentSurface();
                    break;
            }

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

            EnsureHeroHubTabHierarchyOrder(panel, first, second, third);

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
            RenderHeroFragments();
            // The unified hero hub can be entered before the ordinary Bag page
            // has requested /8. Refresh the authoritative package here so the
            // fragment list does not depend on a previous page visit.
            InvokeLuaOrFail(onBagClicked, "Hero.FragmentBagSnapshot");
        }

        private static void EnsureHeroHubTabHierarchyOrder(
            Transform panel, Transform first, Transform second, Transform third)
        {
            if (panel == null) return;
            Transform[] tabs = { first, second, third };
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

            // Legacy cultivation tabs may occupy the first slots. Normalize
            // the three hero-hub tabs once; switching only changes visibility.
            if (alreadyOrdered) return;
            for (int index = 0; index < tabs.Length; index++)
            {
                Transform tab = tabs[index];
                if (tab != null && tab.parent == panel)
                    tab.SetSiblingIndex(index);
            }
        }

        private void AttachHeroHubContent(CocosUiView content)
        {
            if (content == null || !content.IsAlive) return;
            EnsureOneLevelFrame().AttachContent(content, keepSiblingOrder: true);
            NormalizeHeroHubRect(oneLevelFrameView?.GameObject.transform as RectTransform);
            NormalizeHeroHubRect(content.GameObject.transform as RectTransform);
            EnsureHeroHubContentHierarchyOrder();
        }

        private void EnsureHeroHubContentHierarchyOrder()
        {
            Transform frameRoot = oneLevelFrameView?.GameObject?.transform;
            Transform goldCheck = frameRoot?.Find("GoldCheck");
            if (frameRoot == null || goldCheck == null) return;

            // The formation surface historically owns the first two slots.
            // The unified hub appends the bag and fragment pages after them.
            // This is a one-time structural normalization; tab switching only
            // toggles visibility and never promotes the selected page.
            Transform[] fixedContentOrder =
            {
                heroDetailView?.GameObject?.transform,
                heroListView?.GameObject?.transform,
                heroBagView?.GameObject?.transform,
                heroEquipmentFragmentView?.GameObject?.transform,
                // Keep the cultivation shell and its five functional pages
                // before all cultivation popups.  The selected page is
                // switched with SetActive only; it must never be promoted.
                heroCultivationView?.GameObject?.transform,
                heroLevelUpView?.GameObject?.transform,
                heroStarUpView?.GameObject?.transform,
                heroBreakView?.GameObject?.transform,
                heroCultivateView?.GameObject?.transform,
                heroInfoView?.GameObject?.transform,
                // Popups are deliberately kept after the functional pages.
                heroAutoLevelUpView?.GameObject?.transform,
                heroCultivationTalentView?.GameObject?.transform,
                heroCultivationHelpFirstView?.GameObject?.transform,
                heroCultivationHelpSecondView?.GameObject?.transform,
                heroCultivationAttributeView?.GameObject?.transform,
                heroCultivationNumberView?.GameObject?.transform,
                heroCultivationHelpFrameView?.GameObject?.transform,
                formationPopupView?.GameObject?.transform
            };
            int firstContentIndex = goldCheck.GetSiblingIndex() + 1;
            int nextIndex = firstContentIndex;
            bool alreadyOrdered = true;
            foreach (Transform child in fixedContentOrder)
            {
                if (child == null || child.parent != frameRoot) continue;
                if (child.GetSiblingIndex() != nextIndex)
                {
                    alreadyOrdered = false;
                    break;
                }
                nextIndex++;
            }

            if (alreadyOrdered) return;
            nextIndex = firstContentIndex;
            foreach (Transform child in fixedContentOrder)
            {
                if (child == null || child.parent != frameRoot) continue;
                child.SetSiblingIndex(nextIndex++);
            }
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
                AttachHeroHubContent(formationPopupView);
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
