using System;
using System.Collections.Generic;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private readonly List<HeroRecord> pendingHeroes = new List<HeroRecord>();
        private int pendingFollowHeroId;
        private readonly List<HeroBookEntry> pendingHeroBookEntries = new List<HeroBookEntry>();
        private readonly List<HeroBookAttribute> pendingHeroBookAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookScoreAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookUpgradeAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookUpgradeLevelAttributes = new List<HeroBookAttribute>();
        private int pendingHeroBookLevel;
        private long pendingHeroBookScore;
        private long pendingHeroBookNextStart;
        private long pendingHeroBookNextEnd;
        private int heroRebirthResponseOperation;
        private int heroRebirthResponseHeroId;
        private readonly List<FormationRecord> pendingFormations = new List<FormationRecord>();
        private readonly List<int> pendingFormationDisplay = new List<int>();
        private readonly List<int> pendingFormationCombat = new List<int>();
        private int pendingActiveFormationId;

        public void BeginHeroUpdate(int followHeroId, int expectedCount)
        {
            pendingHeroes.Clear();
            if (expectedCount > pendingHeroes.Capacity) pendingHeroes.Capacity = expectedCount;
            pendingFollowHeroId = followHeroId;
        }

        public void AddHeroRecord(int id, int fightPosition, string name, int star, int breakLevel, int level,
            double experience, double maxExperience, double power, double attack, double physicalDefense,
            double magicDefense, double health, double speed, double currentHealth, int cultivationLevel,
            int cultivationAttack, int cultivationPhysicalDefense, int cultivationMagicDefense,
            int cultivationHealth, int primarySkillLevel = 1)
        {
            pendingHeroes.Add(new HeroRecord(id, fightPosition, name, star, breakLevel, level,
                checked((uint)experience), checked((uint)maxExperience), checked((ulong)power),
                checked((uint)attack), checked((uint)physicalDefense), checked((uint)magicDefense),
                checked((ulong)health), checked((uint)speed), checked((ulong)currentHealth), cultivationLevel,
                cultivationAttack, cultivationPhysicalDefense, cultivationMagicDefense, cultivationHealth,
                primarySkillLevel));
        }

        public double GetHeroPower(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Power : 0d;
        public double GetHeroAttack(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Attack : 0d;
        public double GetHeroHealth(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Health : 0d;
        public double GetPlayerPower() => services.Player.Power;
        public void EndHeroUpdate() => services.Heroes.Replace(pendingFollowHeroId, pendingHeroes);

        public void BeginHeroRebirthResponse(int operation, int heroId, int expectedCount)
        {
            heroRebirthResponseOperation = operation;
            heroRebirthResponseHeroId = heroId;
            heroRebirthPresenter?.BeginResponse(operation, heroId, expectedCount);
        }

        public void AddHeroRebirthReward(int type, double id, double quantity)
            => heroRebirthPresenter?.AddResponseReward(type, checked((uint)id), checked((uint)quantity));

        public void EndHeroRebirthResponse(int operation, int heroId, bool success, string error)
        {
            if (heroRebirthPresenter == null)
            {
                if (!success) ShowToast(string.IsNullOrWhiteSpace(error) ? "神将重生失败" : error, 3f);
                return;
            }
            heroRebirthPresenter.EndResponse(operation, heroId, success, error);
            heroRebirthResponseOperation = 0;
            heroRebirthResponseHeroId = 0;
        }

        public void BeginHeroBookSnapshot(int level, double score, double nextStart, double nextEnd,
            int expectedHeroCount)
        {
            pendingHeroBookLevel = level;
            pendingHeroBookScore = checked((long)score);
            pendingHeroBookNextStart = checked((long)nextStart);
            pendingHeroBookNextEnd = checked((long)nextEnd);
            pendingHeroBookEntries.Clear();
            pendingHeroBookAttributes.Clear();
            pendingHeroBookScoreAttributes.Clear();
            if (expectedHeroCount > pendingHeroBookEntries.Capacity)
                pendingHeroBookEntries.Capacity = expectedHeroCount;
        }

        public void AddHeroBookEntry(int heroId, int star, int score)
            => pendingHeroBookEntries.Add(new HeroBookEntry(heroId, star, score));

        public void AddHeroBookAttribute(int group, int type, double value)
        {
            var attribute = new HeroBookAttribute(type, checked((long)value));
            if (group == 1) pendingHeroBookAttributes.Add(attribute);
            else pendingHeroBookScoreAttributes.Add(attribute);
        }

        public void EndHeroBookSnapshot()
        {
            services.HeroBook.Replace(pendingHeroBookLevel, pendingHeroBookScore,
                pendingHeroBookNextStart, pendingHeroBookNextEnd, pendingHeroBookEntries,
                pendingHeroBookAttributes, pendingHeroBookScoreAttributes);
            SetStatus($"HeroBook synchronized: level={services.HeroBook.Level}, score={services.HeroBook.Score}, heroes={services.HeroBook.Entries.Count}.");
        }

        public void BeginHeroBookUpgrade(int heroId, int star, int addedScore, int bookLevel)
        {
            pendingHeroBookUpgradeAttributes.Clear();
            pendingHeroBookUpgradeLevelAttributes.Clear();
        }

        public void AddHeroBookUpgradeAttribute(int group, int type, double value)
        {
            var attribute = new HeroBookAttribute(type, checked((long)value));
            if (group == 1) pendingHeroBookUpgradeAttributes.Add(attribute);
            else pendingHeroBookUpgradeLevelAttributes.Add(attribute);
        }

        public void EndHeroBookUpgrade(int heroId, int star, int addedScore, int bookLevel,
            bool success, string error)
        {
            if (!success)
            {
                pendingHeroBookUpgradeAttributes.Clear();
                pendingHeroBookUpgradeLevelAttributes.Clear();
                ShowToast(string.IsNullOrWhiteSpace(error) ? "图鉴升级失败" : error, 3f);
                return;
            }
            // The Cocos activation flow stays on HeroBook and only overlays the result.
            // Repair stale sibling visibility without running the full auxiliary-page
            // navigation, which would briefly reopen Bag and rebind its close control.
            EnsureHeroBookSurfaceForResult();
            services.HeroBook.ApplyUpgrade(heroId, star, addedScore, bookLevel,
                pendingHeroBookUpgradeAttributes, pendingHeroBookUpgradeLevelAttributes);
            SetStatus($"HeroBook/322 upgrade applied: hero={heroId}, star={star}, score=+{addedScore}, level={bookLevel}.");
        }

        public void BeginFormationUpdate(int activeId, int expectedCount)
        {
            pendingActiveFormationId = activeId;
            pendingFormations.Clear();
            pendingFormationDisplay.Clear();
            pendingFormationCombat.Clear();
            if (expectedCount > pendingFormations.Capacity) pendingFormations.Capacity = expectedCount;
        }

        public void AddFormationRecord(int id, int level) => pendingFormations.Add(new FormationRecord(id, level));

        public void AddFormationDisplayHero(int index, int heroId)
        {
            while (pendingFormationDisplay.Count < index) pendingFormationDisplay.Add(0);
            pendingFormationDisplay[index - 1] = heroId;
        }

        public void AddFormationCombatHero(int index, int heroId)
        {
            while (pendingFormationCombat.Count < index) pendingFormationCombat.Add(0);
            pendingFormationCombat[index - 1] = heroId;
        }

        public void EndFormationUpdate()
        {
            services.Formation.Replace(pendingActiveFormationId, pendingFormations,
                pendingFormationDisplay, pendingFormationCombat);
            var positions = new Dictionary<int, int>();
            for (int index = 0; index < pendingFormationCombat.Count; index++)
                if (pendingFormationCombat[index] > 0) positions[pendingFormationCombat[index]] = index + 1;
            services.Heroes.SetFightPositions(positions);
            if (heroRecycleEntryPending)
            {
                ShowHeroRecycle(false);
                SetStatus($"HeroRebirth synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            if (worldFormationPopupRequestPending)
            {
                SetStatus($"World formation popup synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            if (heroHubOpen)
            {
                heroEntryRequestPending = false;
                ShowHeroHubTab(heroHubTab);
                SetStatus($"Hero hub tab active: {heroHubTab}; heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool explicitEntry = heroEntryRequestPending;
            heroEntryRequestPending = false;
            bool heroPageVisible = IsHeroOpen;
            bool hasVisibleHeroSubview = formationPopupView?.GameObject.activeSelf == true
                || heroCultivationView?.GameObject.activeSelf == true
                || heroLevelUpView?.GameObject.activeSelf == true;
            if (!explicitEntry && !heroPageVisible && !hasVisibleHeroSubview)
            {
                SetStatus($"Hero state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool preserveHeroBook = !explicitEntry && heroBookView?.GameObject.activeSelf == true;
            bool preserveHeroEquipmentSubpage = !explicitEntry && IsHeroEquipmentSubpageVisible;
            if (preserveHeroEquipmentSubpage)
            {
                BindHeroEquipmentCultivationPortrait();
                SetStatus($"Hero equipment state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            if (preserveHeroBook)
            {
                SetStatus($"HeroBook hero state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            EnsureHeroPresenter();
            bool preserveFormationPopup = !explicitEntry && formationPopupView?.GameObject.activeSelf == true;
            if (preserveFormationPopup)
            {
                formationPopupPresenter?.Render();
                formationPopupView.ShowPopup();
                formationPopupPresenter?.RefreshCloseInteraction();
                SetStatus($"Formation popup synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool preserveCultivation = !explicitEntry
                && (heroCultivationView?.GameObject.activeSelf == true || heroLevelUpView?.GameObject.activeSelf == true);
            if (preserveCultivation)
            {
                SetHeroFramePageVisibility(false, false, false, true, true);
                RefreshHeroCultivationData(activeHeroCultivationId);
            }
            else
            {
                SetHeroFramePageVisibility(!showBag, !showBag, showBag, false, false);
                ConfigureHeroFrame(showBag);
            }
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
            SetStatus(showBag
                ? $"Hero bag UI active: {services.Heroes.Count} heroes."
                : $"Hero formation UI active: {services.Heroes.Count} heroes, formation={services.Formation.ActiveFormationId}.");
        }

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
            GameObject tabs = oneLevelFrameView?.FindNode(
                "Layer/Panel_12/Bg/Btn_ListView");
            if (tabs != null) tabs.SetActive(visible);
        }

        private void ShowHeroHubTab(HeroHubTab tab)
        {
            // The cultivation help popup is a Canvas sibling of OneLevelLayer.
            // Hiding the shared frame alone leaves that popup over the next hub page.
            HideHeroCultivationForNavigation();
            heroHubTab = tab;
            heroHubOpen = true;
            EnsureHeroPresenter();
            // Clear cached player-hub and hero pages before reusing the frame.
            HideOneLevelDynamicChildren();
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
            Text title = oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
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

            RefreshStandardCurrencyHeader(oneLevelFrameView, "Layer/GoldCheck");
            SetOneLevelFrameVisible(true);
        }

        private void ConfigureHeroHubTabs(HeroHubTab selected)
        {
            Transform panel = oneLevelFrameView?.FindNode(
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
                ?? services.UiRouter.FindByKey("shenjiangzhenxingLayer");
            if (formationPopupView == null)
                throw new InvalidOperationException("Unity formation surface prefab was not found.");
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
                ?? services.UiAssets.InstantiateUnity("HeroEquipmentFragment", GetDynamicUiRoot());
            if (heroEquipmentFragmentView == null)
                throw new InvalidOperationException("Hero fragment Unity UI view was not found.");
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

        private void AttachHeroHubContent(IUiStackView content)
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
            HideHeroCultivationForNavigation();
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
