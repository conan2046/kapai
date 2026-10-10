using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Data;

namespace ProjectX.Editor
{
    // Isolated business-state tests: no live account, database or rewards are modified.
    public static class RedDotRuleTests
    {
        public static string Run()
        {
            var passed = new List<string>();
            Action<string, bool> check = (name, value) =>
            {
                if (!value) throw new InvalidOperationException("Red-dot regression: " + name);
                passed.Add(name);
            };
            var dots = new RedDotStore();
            dots.Define("player"); dots.Define("realm", "player"); dots.Define("mail", "player");
            check("initially-off", !dots.IsVisible("player"));
            dots.Set("realm", true);
            check("leaf-propagates", dots.IsVisible("player"));
            dots.Set("mail", true); dots.Set("realm", false);
            check("other-child-keeps-parent", dots.IsVisible("player"));
            dots.SetEnabled("mail", false);
            check("locked-child-excluded", !dots.IsVisible("player"));
            dots.SetEnabled("mail", true);
            check("unlock-restores-business-state", dots.IsVisible("player"));
            dots.SetEnabled("player", false);
            check("locked-parent-off", !dots.IsVisible("player"));
            dots.SetEnabled("player", true); dots.Clear();
            check("clear-removes-account-state", !dots.IsVisible("player") && !dots.IsVisible("mail"));

            JingJieDefinition target = JsonConvert.DeserializeObject<JingJieDefinition>(
                "{\"jingjie_id\":1,\"level_limit\":10,\"zhanli_limit\":50000,\"tupo_cost\":[[60000,0,10000],[861,0,2]]}");
            var state = new JingJieViewState();
            Func<int, ulong, long, int, JingJieUpgradeBlock> evaluate = (level, power, gold, material) =>
                JingJieUpgradeEligibility.Evaluate(state, target, level, power, gold, material);
            check("realm-waits-for-authority", evaluate(10, 50000, 10000, 2) == JingJieUpgradeBlock.Synchronizing);
            state.ApplyCurrent(0);
            check("realm-exact-boundaries-ready", evaluate(10, 50000, 10000, 2) == JingJieUpgradeBlock.None);
            check("realm-level-insufficient", evaluate(9, 50000, 10000, 2) == JingJieUpgradeBlock.Level);
            check("realm-power-insufficient", evaluate(10, 49999, 10000, 2) == JingJieUpgradeBlock.Power);
            check("realm-gold-insufficient", evaluate(10, 50000, 9999, 2) == JingJieUpgradeBlock.Gold);
            check("realm-material-insufficient", evaluate(10, 50000, 10000, 1) == JingJieUpgradeBlock.Material);
            state.BeginUpgrade();
            check("realm-pending-does-not-prompt", evaluate(10, 50000, 10000, 2) == JingJieUpgradeBlock.Pending);
            state.FinishUpgrade();
            check("realm-rejection-restores-ready", evaluate(10, 50000, 10000, 2) == JingJieUpgradeBlock.None);
            check("realm-maximum-off", JingJieUpgradeEligibility.Evaluate(state, null, 10, 50000, 10000, 2)
                == JingJieUpgradeBlock.Maximum);
            state.Clear();
            check("realm-cleared-state-off", evaluate(10, 50000, 10000, 2) == JingJieUpgradeBlock.Synchronizing);

            var mails = new MailStore();
            mails.SetUnreadHint(true);
            check("mail-push-before-snapshot", mails.HasUnreadPrompt && !mails.HasUnread);
            mails.Replace(new[] { new MailRecord(1, 0, "test", 0, "body", null),
                new MailRecord(2, 0, "test", 0, "body", null) });
            mails.MoveToHistory(1);
            check("mail-one-read-keeps-another", mails.HasUnreadPrompt);
            mails.MoveToHistory(2);
            check("mail-last-read-clears", !mails.HasUnreadPrompt);
            mails.SetUnreadHint(true); mails.Replace(Array.Empty<MailRecord>());
            check("mail-authoritative-empty-clears-hint", !mails.HasUnreadPrompt);
            mails.SetUnreadHint(true); mails.Clear();
            check("mail-account-reset-clears-hint", !mails.HasUnreadPrompt);

            var bag = new BagStore();
            var usable = new BagItemRecord(1, 3201, 1, "usable", "", 0, 1, 1, 0, 0);
            var material = new BagItemRecord(2, 1001, 1, "material", "", 0, 1, 0, 0, 0);
            var jump = new BagItemRecord(3, 1002, 1, "jump", "", 0, 1, 0, 1010, 0);
            var gift = new BagItemRecord(4, 1003, 1, "gift", "", 0, 1, 0, 0, 0, 6);
            check("bag-direct-use-ready", usable.CanUseDirectly);
            check("bag-gift-ready", gift.CanUseDirectly);
            check("bag-material-off", !material.CanUseDirectly);
            check("bag-pure-jump-off", !jump.CanUseDirectly);
            check("bag-empty-stack-off", !new BagItemRecord(1, 3201, 0, "", "", 0, 1, 1, 0, 0).CanUseDirectly);
            bag.Replace(new[] { usable, material, jump, gift });
            check("bag-any-usable-keeps-prompt", bag.HasDirectlyUsableItems);
            bag.Replace(new[] { material, jump });
            check("bag-consumed-last-clears", !bag.HasDirectlyUsableItems);
            bag.Clear();
            check("bag-reset-clears", !bag.HasDirectlyUsableItems);

            var fragments = new HeroFragmentCatalog(new[]
            {
                new EquipmentComposeDefinition { Id = 1, Type = 2,
                    Items = new[] { new[] { 2401, 0, 150 }, new[] { 60000, 0, 10 } },
                    Target = new[] { 60002, 10, 1 } }
            });
            var heroes = new HeroStore();
            var fragmentBag = new BagStore();
            var money = new CurrencyStore();
            Func<int, BagItemRecord> fragment = amount =>
                new BagItemRecord(1, 2401, amount, "fragment", "任意描述不决定门槛", 0, 1, 0, 0, 0, 2);
            fragmentBag.Replace(new[] { fragment(150) });
            money.Set(CurrencyIds.Gold, 10);
            check("hero-fragment-waits-for-owned-snapshot", !fragments.CanCompose(2401, heroes, fragmentBag, money));
            heroes.Replace(0, Array.Empty<HeroRecord>());
            check("hero-fragment-formal-threshold", fragments.GetRequiredFragments(2401) == 150);
            check("hero-fragment-exact-boundary-ready", fragments.CanCompose(2401, heroes, fragmentBag, money));
            fragmentBag.Replace(new[] { fragment(149) });
            check("hero-fragment-one-below-off", !fragments.CanCompose(2401, heroes, fragmentBag, money));
            fragmentBag.Replace(new[] { fragment(70),
                new BagItemRecord(2, 2401, 80, "fragment", "", 0, 1, 0, 0, 0, 2) });
            check("hero-fragment-split-stacks-count-together", fragments.CanCompose(2401, heroes, fragmentBag, money));
            money.Set(CurrencyIds.Gold, 9);
            check("hero-fragment-other-cost-required", !fragments.CanCompose(2401, heroes, fragmentBag, money));
            money.Set(CurrencyIds.Gold, 10);
            check("hero-fragment-pending-off", !fragments.CanCompose(2401, heroes, fragmentBag, money, true));
            check("hero-fragment-failure-restores", fragments.CanCompose(2401, heroes, fragmentBag, money));
            heroes.Replace(0, new[] { new HeroRecord(10, 0, "owned", 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0) });
            check("hero-fragment-owned-target-off", !fragments.CanCompose(2401, heroes, fragmentBag, money));
            check("hero-fragment-unknown-recipe-off", !fragments.CanCompose(9999, heroes, fragmentBag, money));
            heroes.Clear();
            check("hero-fragment-account-clear-off", !heroes.HasAuthoritativeState
                && !fragments.CanCompose(2401, heroes, fragmentBag, money));
            check("hero-level-feed-ready", HeroLevelEligibility.CanFeed(1, 8, 8, 1, 10, true, true));
            check("hero-level-feed-can-add-partial-experience", HeroLevelEligibility.CanFeed(1, 100, 8, 1, 1, true, true));
            check("hero-level-feed-no-material-off", !HeroLevelEligibility.CanFeed(1, 100, 8, 0, 10, true, true));
            check("hero-level-feed-player-cap-off", !HeroLevelEligibility.CanFeed(100, 100, 8, 1, 10, true, true));
            check("hero-level-feed-locked-off", !HeroLevelEligibility.CanFeed(1, 7, 8, 1, 10, true, true));
            check("hero-level-feed-awaits-authority", !HeroLevelEligibility.CanFeed(1, 100, 8, 1, 10, false, true));
            check("hero-level-feed-unknown-level-off", !HeroLevelEligibility.CanFeed(1, 100, 8, 1, 10, true, false));
            check("hero-level-feed-invalid-experience-off", !HeroLevelEligibility.CanFeed(1, 100, 8, 1, 0, true, true));
            check("hero-level-auto-exact-experience-ready", HeroLevelEligibility.CanAutoLevel(1, 2, 8, 8, 20, 20, true, true));
            check("hero-level-auto-one-below-off", !HeroLevelEligibility.CanAutoLevel(1, 2, 8, 8, 20, 19, true, true));
            check("hero-level-auto-no-target-off", !HeroLevelEligibility.CanAutoLevel(1, 1, 8, 8, 0, 20, true, true));
            check("hero-level-auto-player-cap-off", !HeroLevelEligibility.CanAutoLevel(1, 9, 8, 8, 20, 20, true, true));
            check("hero-level-auto-missing-exp-config-off", !HeroLevelEligibility.CanAutoLevel(1, 2, 8, 8, 0, 20, true, false));
            check("hero-level-auto-locked-off", !HeroLevelEligibility.CanAutoLevel(1, 2, 7, 8, 20, 20, true, true));
            check("hero-level-auto-awaits-authority", !HeroLevelEligibility.CanAutoLevel(1, 2, 8, 8, 20, 20, false, true));
            check("hero-level-auto-stored-experience-needs-no-new-books", HeroLevelEligibility.CanAutoLevel(1, 2, 8, 8, 0, 0, true, true));
            check("hero-break-exact-boundaries-ready", HeroBreakEligibility.CanBreak(5, 4, 4, 5, true, true, true));
            check("hero-break-awaits-authority", !HeroBreakEligibility.CanBreak(5, 4, 4, 5, true, true, false));
            check("hero-break-function-locked-off", !HeroBreakEligibility.CanBreak(5, 3, 4, 5, true, true, true));
            check("hero-break-hero-level-insufficient-off", !HeroBreakEligibility.CanBreak(4, 100, 4, 5, true, true, true));
            check("hero-break-no-next-off", !HeroBreakEligibility.CanBreak(100, 100, 4, 0, false, true, true));
            check("hero-break-missing-cost-off", !HeroBreakEligibility.CanBreak(5, 100, 4, 5, true, false, true));
            check("hero-break-invalid-hero-off", !HeroBreakEligibility.CanBreak(0, 100, 4, 0, true, true, true));
            check("hero-break-quality-one-times", HeroBreakEligibility.ScaleCost(5, 10000) == 5);
            check("hero-break-quality-one-half-truncates", HeroBreakEligibility.ScaleCost(5, 15000) == 7);
            check("hero-break-quality-gold-scales", HeroBreakEligibility.ScaleCost(10000, 15000) == 15000);
            check("hero-break-quality-three-times", HeroBreakEligibility.ScaleCost(5, 30000) == 15);
            check("hero-break-quality-six-times", HeroBreakEligibility.ScaleCost(5, 60000) == 30);
            var heroDots = new RedDotStore();
            heroDots.Define("hero"); heroDots.Define("break", "hero"); heroDots.Define("fragments", "hero");
            heroDots.Set("break", true); heroDots.Set("fragments", true); heroDots.Set("break", false);
            check("hero-break-cleared-keeps-fragments-parent", heroDots.IsVisible("hero"));
            heroDots.Set("fragments", false);
            check("hero-break-last-business-clears-parent", !heroDots.IsVisible("hero"));
            check("hero-star-exact-count-ready", HeroStarEligibility.CanStarUp(1, 5, 5, 20, 20, true, true));
            check("hero-star-one-below-off", !HeroStarEligibility.CanStarUp(1, 100, 5, 19, 20, true, true));
            check("hero-star-awaits-authority-off", !HeroStarEligibility.CanStarUp(1, 100, 5, 20, 20, true, false));
            check("hero-star-function-locked-off", !HeroStarEligibility.CanStarUp(1, 4, 5, 20, 20, true, true));
            check("hero-star-no-next-off-even-with-fragments", !HeroStarEligibility.CanStarUp(7, 100, 5, 999, 0, false, true));
            check("hero-star-invalid-state-off", !HeroStarEligibility.CanStarUp(0, 100, 5, 20, 20, true, true));
            check("hero-star-invalid-cost-off", !HeroStarEligibility.CanStarUp(1, 100, 5, 20, -1, true, true));
            check("hero-star-negative-quantity-off", !HeroStarEligibility.CanStarUp(1, 100, 5, -1, 20, true, true));
            heroDots.Define("star", "hero"); heroDots.Define("level", "hero");
            heroDots.Set("star", true); heroDots.Set("level", true); heroDots.Set("star", false);
            check("hero-star-max-keeps-level-parent", heroDots.IsVisible("hero"));
            heroDots.Set("level", false);
            check("hero-star-last-cultivation-clears-parent", !heroDots.IsVisible("hero"));
            check("hero-training-single-material-ready", HeroCultivationEligibility.CanTrain(20, 20, 1000, 1, true, true));
            check("hero-training-missing-material-off", !HeroCultivationEligibility.CanTrain(20, 20, 4, 0, true, true));
            check("hero-training-level-locked-off", !HeroCultivationEligibility.CanTrain(19, 20, 4, 1, true, true));
            check("hero-training-full-progress-off", !HeroCultivationEligibility.CanTrain(20, 20, 0, 1, true, true));
            check("hero-training-awaits-authority-off", !HeroCultivationEligibility.CanTrain(20, 20, 4, 1, true, false));
            check("hero-training-no-next-off", !HeroCultivationEligibility.CanTrain(100, 0, 4, 1, false, true));
            check("hero-training-invalid-progress-off", !HeroCultivationEligibility.CanTrain(20, 20, -1, 1, true, true));
            check("hero-activation-exact-progress-ready", HeroCultivationEligibility.CanActivate(20, 20, 0, true, true, true));
            check("hero-activation-incomplete-progress-off", !HeroCultivationEligibility.CanActivate(20, 20, 1, true, true, true));
            check("hero-activation-cost-insufficient-off", !HeroCultivationEligibility.CanActivate(20, 20, 0, false, true, true));
            check("hero-activation-level-locked-off", !HeroCultivationEligibility.CanActivate(19, 20, 0, true, true, true));
            check("hero-activation-awaits-authority-off", !HeroCultivationEligibility.CanActivate(20, 20, 0, true, true, false));
            check("hero-activation-no-next-off", !HeroCultivationEligibility.CanActivate(100, 0, 0, true, false, true));
            check("hero-activation-invalid-progress-off", !HeroCultivationEligibility.CanActivate(20, 20, -1, true, true, true));
            heroDots.Define("train", "hero"); heroDots.Define("activate", "hero");
            heroDots.Set("train", true); heroDots.Set("activate", true); heroDots.Set("train", false);
            check("hero-training-complete-keeps-activation-parent", heroDots.IsVisible("hero"));
            heroDots.Set("level", true); heroDots.Set("activate", false);
            check("hero-activation-success-keeps-level-parent", heroDots.IsVisible("hero"));
            heroDots.Set("level", false);
            check("hero-training-last-business-clears-parent", !heroDots.IsVisible("hero"));
            check("hero-book-free-owned-activation-ready", HeroBookEligibility.CanActivate(35, 35, true, true, true, false));
            check("hero-book-unowned-activation-off", !HeroBookEligibility.CanActivate(100, 35, false, true, true, false));
            check("hero-book-activation-locked-off", !HeroBookEligibility.CanActivate(34, 35, true, true, true, false));
            check("hero-book-activation-awaits-snapshot", !HeroBookEligibility.CanActivate(100, 35, true, true, false, false));
            check("hero-book-activation-pending-off", !HeroBookEligibility.CanActivate(100, 35, true, true, true, true));
            check("hero-book-activation-missing-definition-off", !HeroBookEligibility.CanActivate(100, 35, true, false, true, false));
            check("hero-book-upgrade-exact-boundaries-ready", HeroBookEligibility.CanUpgrade(35, 35, true, 2, 2, true, true, 10, 10, true, false));
            check("hero-book-upgrade-star-insufficient-off", !HeroBookEligibility.CanUpgrade(100, 35, true, 1, 2, true, true, 10, 10, true, false));
            check("hero-book-upgrade-material-one-below-off", !HeroBookEligibility.CanUpgrade(100, 35, true, 2, 2, true, true, 9, 10, true, false));
            check("hero-book-upgrade-unowned-off", !HeroBookEligibility.CanUpgrade(100, 35, false, 2, 2, true, true, 10, 10, true, false));
            check("hero-book-upgrade-max-off", !HeroBookEligibility.CanUpgrade(100, 35, true, 7, 0, false, true, 999, 0, true, false));
            check("hero-book-upgrade-missing-quality-cost-off", !HeroBookEligibility.CanUpgrade(100, 35, true, 2, 2, true, false, 999, 0, true, false));
            check("hero-book-upgrade-awaits-snapshot", !HeroBookEligibility.CanUpgrade(100, 35, true, 2, 2, true, true, 10, 10, false, false));
            check("hero-book-upgrade-pending-off", !HeroBookEligibility.CanUpgrade(100, 35, true, 2, 2, true, true, 10, 10, true, true));
            var bookState = new HeroBookStore();
            check("hero-book-initial-state-not-authoritative", !bookState.HasAuthoritativeState);
            bookState.Replace(0, 0, 0, 10, Array.Empty<HeroBookEntry>(), Array.Empty<HeroBookAttribute>(), Array.Empty<HeroBookAttribute>());
            bookState.SetPending(57);
            check("hero-book-snapshot-and-pending-state", bookState.HasAuthoritativeState && bookState.PendingHeroId == 57);
            bookState.SetPending(0);
            check("hero-book-rejection-clears-pending", bookState.PendingHeroId == 0);
            bookState.Clear();
            check("hero-book-account-clear-removes-authority", !bookState.HasAuthoritativeState && bookState.PendingHeroId == 0);
            var formationState = new FormationStore();
            var formationBag = new BagStore();
            var formationMoney = new CurrencyStore();
            formationMoney.Set(CurrencyIds.Gold, 200000);
            formationBag.Replace(new[] { new BagItemRecord(1, 2725, 1, "book", "", 0, 1, 0, 0, 0),
                new BagItemRecord(2, 2726, 1, "book", "", 0, 1, 0, 0, 0) });
            check("formation-awaits-authority", !FormationCatalog.Shared.AnyReady(formationState, formationBag, formationMoney));
            formationState.Replace(1, new[] { new FormationRecord(1, 0) }, Array.Empty<int>(), Array.Empty<int>());
            check("formation-learn-exact-cost", FormationCatalog.Shared.CanUpgrade(formationState, formationBag, formationMoney, 1));
            formationState.SetPending(1);
            check("formation-pending-current-off", !FormationCatalog.Shared.CanUpgrade(formationState, formationBag, formationMoney, 1));
            check("formation-pending-keeps-sibling", FormationCatalog.Shared.CanUpgrade(formationState, formationBag, formationMoney, 2));
            formationState.SetPending(0);
            check("formation-rejection-restores", FormationCatalog.Shared.CanUpgrade(formationState, formationBag, formationMoney, 1));
            formationState.Replace(1, new[] { new FormationRecord(1, 1) }, Array.Empty<int>(), Array.Empty<int>());
            check("formation-next-level-needs-three-books", !FormationCatalog.Shared.CanUpgrade(formationState, formationBag, formationMoney, 1));
            formationMoney.Set(CurrencyIds.Gold, 99999);
            check("formation-gold-short", !FormationCatalog.Shared.AnyReady(formationState, formationBag, formationMoney));
            formationState.Clear();
            check("formation-account-clear", !formationState.HasAuthoritativeState && formationState.PendingFormationId == 0);
            var formationPlayer = new PlayerStore();
            formationPlayer.Initialize(1, "test", 0, 0, 0, 1, 0, 0, 0, 0, 500);
            heroes.Replace(0, new[] { new HeroRecord(57, 0, "bench", 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0) });
            check("formation-fill-awaits-authority", !FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 1));
            formationState.Replace(1, new[] { new FormationRecord(1, 1) }, Array.Empty<int>(), new[] { 0, 0, 0, 0, 0 });
            check("formation-fill-first-slot-exact-level", FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 1));
            check("formation-fill-locked-slot-off", !FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 2));
            check("formation-fill-invalid-slot-off", !FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 6));
            formationState.Replace(1, new[] { new FormationRecord(1, 1) }, Array.Empty<int>(), new[] { 57, 0, 0, 0, 0 });
            check("formation-fill-occupied-slot-off", !FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 1));
            formationPlayer.Initialize(1, "test", 0, 0, 0, 100, 0, 0, 0, 0, 500);
            check("formation-fill-no-bench-hero-off", !FormationCatalog.CanFillPosition(formationState, heroes, formationPlayer, 2));
            var draw = new DrawStore();
            check("draw-awaits-authority", !draw.CanFreeDraw(1, 100));
            draw.ReplacePools(new[] { new DrawPoolRecord { Kind=1, FreeTimes=2, FreeCooldownSeconds=10 },
                new DrawPoolRecord { Kind=2, FreeTimes=1, FreeCooldownSeconds=20 },
                new DrawPoolRecord { Kind=3, FreeTimes=10, FreeCooldownSeconds=0 } },100);
            check("draw-normal-before-boundary", !draw.CanFreeDraw(1,109));
            check("draw-normal-exact-boundary", draw.CanFreeDraw(1,110));
            check("draw-advanced-before-boundary", !draw.CanFreeDraw(2,119));
            check("draw-advanced-exact-boundary", draw.CanFreeDraw(2,120));
            check("draw-friendship-no-free-rule", !draw.CanFreeDraw(3,120));
            draw.SetPending(1);
            check("draw-pending-current-suppressed", !draw.CanFreeDraw(1,120));
            check("draw-pending-sibling-preserved", draw.CanFreeDraw(2,120));
            draw.SetPending(0);
            check("draw-failure-restores-ready", draw.CanFreeDraw(1,120));
            draw.SetResult(new DrawResultRecord { Kind=1, DrawType=1, FreeTimes=1, FreeCooldownSeconds=600 },115);
            check("draw-result-current-cooldown", !draw.CanFreeDraw(1,120));
            check("draw-result-keeps-sibling-clock", draw.CanFreeDraw(2,120));
            draw.SetResult(new DrawResultRecord { Kind=1, DrawType=2 },130);
            check("draw-paid-result-keeps-free-clock", draw.RemainingCooldown(1,130)==585);
            check("draw-unsynchronized-clock-off", !draw.CanFreeDraw(2,0));
            draw.SetResult(new DrawResultRecord { Kind=2, DrawType=1, FreeTimes=0, FreeCooldownSeconds=0 },130);
            check("draw-no-free-times-off", !draw.CanFreeDraw(2,130));
            draw.SetPending(1);draw.Clear();
            check("draw-account-clear", !draw.HasAuthoritativeState && draw.PendingKind==0 && !draw.HasFreeDrawAt(1000));
            draw.ReplacePools(new[]{new DrawPoolRecord { Kind=1, FreeTimes=1, FreeCooldownSeconds=20 }},0);
            check("draw-late-clock-anchors-countdown", draw.RemainingCooldown(1,100)==20 && draw.CanFreeDraw(1,120));
            var world = new WorldStore();
            check("world-achievement-awaits-chapters", !world.CanClaimAchievement(1));
            world.ReplaceChapters(1,1002,10011,new[]{new WorldChapterRecord{Id=1001,OpenLevel=1,OwnedStars=18,ClaimedBoxes=2}});
            check("world-achievement-awaits-bitmap", !world.CanClaimAchievement(1));
            world.SetAchievement(1,0);
            check("world-achievement-ready", world.CanClaimAchievement(1));
            check("world-achievement-next-condition-off", !world.CanClaimAchievement(2));
            world.SetAchievementPending(1);check("world-achievement-pending-off", !world.CanClaimAchievement(1));
            check("world-pending-achievement-keeps-box-parent", world.HasReadyBoxes(100));
            world.SetAchievementPending(0);check("world-achievement-failure-restores", world.CanClaimAchievement(1));
            var normalBoxes=new[]{new WorldStageRecord{Id=10003,RewardBoxId=10011,RewardBoxState=1}};
            var starBoxes=new[]{new WorldStarBoxRecord{RewardId=20011,State=1}};
            world.ApplyBoxSnapshot(1001,normalBoxes,starBoxes);
            check("world-background-snapshot-does-not-select-chapter", world.SelectedChapterId==0);
            check("world-normal-and-star-ready", world.HasReadyBoxKind(false,100)&&world.HasReadyBoxKind(true,100));
            world.SetBoxPending(1001,20011);
            check("world-star-pending-only-current-off", !world.HasReadyBoxKind(true,100)&&world.HasReadyBoxKind(false,100));
            world.ApplyClaimedBox(1001,20011);world.SetBoxPending(0,0);
            check("world-star-claim-keeps-normal", !world.HasReadyBoxKind(true,100)&&world.HasReadyBoxKind(false,100));
            world.ApplyClaimedBox(1001,10011);
            check("world-last-box-off-keeps-achievement", !world.HasReadyBoxes(100)&&world.CanClaimAchievement(1));
            world.SetAchievement(1,2);check("world-claimed-achievement-off", !world.CanClaimAchievement(1));
            world.ReplaceChapters(1,1002,10011,new[]{new WorldChapterRecord{Id=1001,OpenLevel=1,OwnedStars=18,ClaimedBoxes=1}});
            world.ReplaceStages(1,1001,"test",new[]{new WorldStageRecord{Id=10001,RewardBoxId=10000,RewardBoxState=1},new WorldStageRecord{Id=10002,RewardBoxId=10000,RewardBoxState=1}},new WorldStarBoxRecord[0]);
            world.ApplyClaimedBox(1001,10000);
            check("world-shared-reward-id-updates-all-nodes", world.Stages.All(s=>s.RewardBoxState==2)&&!world.HasReadyBoxes(100));
            world.SetAchievementPending(1);world.SetBoxPending(1001,10000);world.Clear();
            check("world-account-clear-authority-and-pending", !world.HasChapterState&&!world.HasAchievementState&&world.PendingAchievementIndex==0&&world.PendingBoxId==0);
            return JsonConvert.SerializeObject(new { count = passed.Count, passed });
        }
    }
}
