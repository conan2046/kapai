using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const string HeroDot = "hero";
        private static readonly string[] HeroTabDots = { "hero.formation", "hero.heroes", "hero.fragments" };
        private bool heroRedDotsSubscribed;
        private bool heroComposePending;
        private int heroComposePendingFragment;
        private LuaFunction onHeroRedDotRefresh;
        private LuaFunction onHeroBookRedDotRefresh;

        private void InitializeHeroRedDots()
        {
            redDots.Define(HeroDot);
            foreach (string key in HeroTabDots) redDots.Define(key, HeroDot);
            redDots.Define("hero.deployed.level", HeroTabDots[0]);
            redDots.Define("hero.formation.upgrade", HeroTabDots[0]);
            redDots.Define("hero.formation.fill", HeroTabDots[0]);
            redDots.Define("hero.roster.level", HeroTabDots[1]);
            redDots.Define("hero.deployed.break", HeroTabDots[0]);
            redDots.Define("hero.roster.break", HeroTabDots[1]);
            redDots.Define("hero.deployed.star", HeroTabDots[0]);
            redDots.Define("hero.roster.star", HeroTabDots[1]);
            redDots.Define("hero.deployed.train", HeroTabDots[0]);
            redDots.Define("hero.roster.train", HeroTabDots[1]);
            redDots.Define("hero.deployed.activate", HeroTabDots[0]);
            redDots.Define("hero.roster.activate", HeroTabDots[1]);
            redDots.Define("hero.roster.book", HeroTabDots[1]);
            redDots.Define("hero.book.activate", "hero.roster.book");
            redDots.Define("hero.book.upgrade", "hero.roster.book");
            redDots.Changed += RenderHeroRedDots;
            services.Bag.Changed += RefreshHeroRedDots;
            services.Heroes.Changed += RefreshHeroRedDots;
            services.Player.Changed += RefreshHeroRedDots;
            services.Currencies.Changed += RefreshHeroRedDots;
            services.Formation.Changed += RefreshHeroRedDots;
            services.HeroBook.Changed += RefreshHeroRedDots;
            heroRedDotsSubscribed = true;
            RefreshHeroRedDots();
        }

        private bool CanComposeHeroFragment(BagItemRecord item) => item.ItemType == 2
            && HeroFragmentCatalog.Shared.CanCompose(item.ItemId, services.Heroes, services.Bag,
                services.Currencies, heroComposePending && item.ItemId == heroComposePendingFragment);

        private bool CanLevelUpHero(HeroRecord hero) => HeroCultivationPresenter.CanLevelUp(hero,
            services.Player, services.Bag, services.Heroes.HasAuthoritativeState);

        private bool CanBreakUpHero(HeroRecord hero) => HeroCultivationPresenter.CanBreakUp(hero,
            services.Player, services.Bag, services.Currencies, services.Heroes.HasAuthoritativeState);

        private bool CanStarUpHero(HeroRecord hero) => HeroCultivationPresenter.CanStarUp(hero,
            services.Player, services.Bag, services.Heroes.HasAuthoritativeState);

        private bool CanTrainHero(HeroRecord hero) => HeroCultivationCatalog.Shared.CanTrain(hero,
            services.Bag, services.Heroes.HasAuthoritativeState);

        private bool CanActivateHero(HeroRecord hero) => HeroCultivationCatalog.Shared.CanActivate(hero,
            services.Bag, services.Currencies, services.Heroes.HasAuthoritativeState);

        private bool CanCultivateHero(HeroRecord hero) => CanLevelUpHero(hero) || CanBreakUpHero(hero) || CanStarUpHero(hero)
            || CanTrainHero(hero) || CanActivateHero(hero);

        public bool IsHeroBookUnlocked() => services != null
            && services.Player.Level >= FunctionUnlockCatalog.Resolve(1090).OpenLevel;

        public bool CanUpgradeHeroBook(int heroId) => services.HeroBookCatalog.CanUpgrade(heroId,
            services.HeroBook, services.Heroes, services.Bag, services.Player.Level);

        public void SetHeroBookPending(int heroId, bool pending) => services.HeroBook.SetPending(pending ? heroId : 0);

        public void SetFormationUpgradePending(int id, bool pending) => services.Formation.SetPending(pending ? id : 0);

        public void SetHeroComposePending(int fragmentId, bool pending)
        {
            heroComposePending = pending;
            heroComposePendingFragment = pending ? fragmentId : 0;
            RefreshHeroRedDots();
            if (heroFragmentBagActive && heroEquipmentFragmentView?.GameObject.activeInHierarchy == true)
                RenderHeroFragments();
        }

        private void RefreshHeroRedDots()
        {
            if (!heroRedDotsSubscribed || services == null) return;
            redDots.SetEnabled(HeroDot, services.Player.Level > 0 && services.Heroes.HasAuthoritativeState);
            redDots.Set(HeroTabDots[2], services.Bag.GetItemsByType(2).Any(CanComposeHeroFragment));
            redDots.Set("hero.formation.upgrade", FormationCatalog.Shared.AnyReady(services.Formation, services.Bag, services.Currencies));
            redDots.Set("hero.formation.fill", Enumerable.Range(1, 5).Any(position =>
                FormationCatalog.CanFillPosition(services.Formation, services.Heroes, services.Player, position)));
            redDots.Set("hero.roster.level", services.Heroes.Items.Any(CanLevelUpHero));
            redDots.Set("hero.deployed.level", services.Heroes.Items.Any(hero =>
                services.Formation.GetCombatPosition(hero.Id) > 0 && CanLevelUpHero(hero)));
            redDots.Set("hero.roster.break", services.Heroes.Items.Any(CanBreakUpHero));
            redDots.Set("hero.deployed.break", services.Heroes.Items.Any(hero =>
                services.Formation.GetCombatPosition(hero.Id) > 0 && CanBreakUpHero(hero)));
            redDots.Set("hero.roster.star", services.Heroes.Items.Any(CanStarUpHero));
            redDots.Set("hero.deployed.star", services.Heroes.Items.Any(hero =>
                services.Formation.GetCombatPosition(hero.Id) > 0 && CanStarUpHero(hero)));
            redDots.Set("hero.roster.train", services.Heroes.Items.Any(CanTrainHero));
            redDots.Set("hero.roster.activate", services.Heroes.Items.Any(CanActivateHero));
            redDots.Set("hero.deployed.train", services.Heroes.Items.Any(hero =>
                services.Formation.GetCombatPosition(hero.Id) > 0 && CanTrainHero(hero)));
            redDots.Set("hero.deployed.activate", services.Heroes.Items.Any(hero =>
                services.Formation.GetCombatPosition(hero.Id) > 0 && CanActivateHero(hero)));
            int[] bookReady = services.HeroBookCatalog.Heroes.Select(h => h.Key).Where(CanUpgradeHeroBook).ToArray();
            redDots.Set("hero.book.activate", bookReady.Any(id => !services.HeroBook.TryGet(id, out _)));
            redDots.Set("hero.book.upgrade", bookReady.Any(id => services.HeroBook.TryGet(id, out _)));
            RenderHeroRedDots();
        }

        private void RenderHeroRedDots()
        {
            if (mainView?.GameObject == null) return;
            RedDotVisual.Set(FindMainHudNode(FormationPath)?.transform, redDots.IsVisible(HeroDot), RedDotTemplate);
            RedDotVisual.Set(FindMainHudNode(HeroBagPath)?.transform, redDots.IsVisible(HeroDot), RedDotTemplate);
            RedDotVisual.Set(worldMapView?.FindNode("Layer/Panel_1/btn_zhenrong")?.transform, redDots.IsVisible(HeroDot), RedDotTemplate);
            RedDotVisual.Set(worldMapView?.FindNode("Layer/Panel_1/duiwu")?.transform, redDots.IsVisible("hero.formation.upgrade"), RedDotTemplate);
            RedDotVisual.Set(heroBagView?.FindNode("Layer/yingxiongbeibaoUI/cell")?.transform,
                redDots.IsVisible("hero.roster.book"), RedDotTemplate);
            RedDotVisual.Set(heroListView?.FindNode("Layer/shenjiangListUI/List/btn_buzhen")?.transform,
                redDots.IsVisible("hero.formation.upgrade"), RedDotTemplate);
            if (heroHubOpen && (heroListView?.GameObject.activeInHierarchy == true
                || heroBagView?.GameObject.activeInHierarchy == true
                || heroFragmentBagActive && heroEquipmentFragmentView?.GameObject.activeInHierarchy == true))
                ApplyHeroHubTabRedDots();
        }

        private void ApplyHeroHubTabRedDots()
        {
            RedDotVisual.Set(heroListView?.FindNode("Layer/shenjiangListUI/List/btn_buzhen")?.transform,
                redDots.IsVisible("hero.formation.upgrade"), RedDotTemplate);
            RedDotVisual.Set(heroBagView?.FindNode("Layer/yingxiongbeibaoUI/cell")?.transform,
                redDots.IsVisible("hero.roster.book"), RedDotTemplate);
            Transform panel = oneLevelFrameView?.FindNode("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            string[] names = { "Button1", "Button2_Runtime", "Button3_Runtime" };
            for (int index = 0; index < names.Length; index++)
                RedDotVisual.Set(panel?.Find(names[index]), redDots.IsVisible(HeroTabDots[index]), RedDotTemplate);
        }

        private void DisposeHeroRedDots()
        {
            if (!heroRedDotsSubscribed) return;
            redDots.Changed -= RenderHeroRedDots;
            services.Bag.Changed -= RefreshHeroRedDots;
            services.Heroes.Changed -= RefreshHeroRedDots;
            services.Player.Changed -= RefreshHeroRedDots;
            services.Currencies.Changed -= RefreshHeroRedDots;
            services.Formation.Changed -= RefreshHeroRedDots;
            services.HeroBook.Changed -= RefreshHeroRedDots;
            heroRedDotsSubscribed = false;
            onHeroRedDotRefresh?.Dispose();
            onHeroRedDotRefresh = null;
            onHeroBookRedDotRefresh?.Dispose();
            onHeroBookRedDotRefresh = null;
        }
    }
}
