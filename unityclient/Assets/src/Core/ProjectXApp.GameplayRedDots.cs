using System.Linq;
using ProjectX.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private static readonly int[] EffectiveGameplayIds = { 1, 3, 9, 10, 21, 23, 27, 29, 32 };
        private bool gameplayRedDotsSubscribed;
        private long gameplayRedDotSecond = -1;
        private long gameplaySnapshotDay = -1;
        private bool gameplayDayRefreshPending;
        private readonly System.Collections.Generic.HashSet<ushort> fishReminderSlots = new System.Collections.Generic.HashSet<ushort>();

        public bool IsGameplayReminderOpen(int id)
        {
            var definition = services?.GameplayCatalog.Find(id);
            return EffectiveGameplayIds.Contains(id) && definition != null && services.Player.Level >= definition.OpenLevel;
        }

        private void InitializeGameplayRedDots()
        {
            redDots.Define("gameplay");
            foreach (int id in EffectiveGameplayIds) redDots.Define("gameplay." + id, "gameplay");
            redDots.Define("gameplay.23.coin", "gameplay.23");
            redDots.Define("gameplay.3.challenge", "gameplay.3");
            redDots.Define("gameplay.9.search", "gameplay.9");
            redDots.Define("gameplay.9.compose", "gameplay.9");
            redDots.Define("gameplay.9.rewards", "gameplay.9");
            redDots.Define("gameplay.10.daily", "gameplay.10");
            redDots.Define("gameplay.10.activity", "gameplay.10");
            redDots.Define("gameplay.21.roll", "gameplay.21");
            redDots.Define("gameplay.21.continue", "gameplay.21");
            redDots.Define("gameplay.21.round", "gameplay.21");
            redDots.Define("gameplay.27.round", "gameplay.27");
            redDots.Define("gameplay.27.question", "gameplay.27");
            redDots.Define("gameplay.29.single", "gameplay.29");
            redDots.Define("gameplay.29.multi", "gameplay.29");
            services.HappyWheel.Changed += RefreshGameplayRedDots;
            redDots.Define("gameplay.32.basket", "gameplay.32");
            services.Fish.Changed += RefreshGameplayRedDots;
            InitializeShopRedDots();
            services.Gameplay.Changed += RefreshGameplayRedDots;
            services.YouLi.Changed += RefreshGameplayRedDots;
            services.MoneyTree.Changed += RefreshGameplayRedDots;
            services.FengShenStory.Changed += RefreshGameplayRedDots;
            services.Currencies.Changed += RefreshGameplayRedDots;
            services.XunBao.Changed += RefreshGameplayRedDots;
            services.Bag.Changed += RefreshGameplayRedDots;
            services.Tasks.Changed += RefreshGameplayRedDots;
            services.Player.Changed += RefreshGameplayRedDots;
            gameplayRedDotsSubscribed = true;
        }

        private void RefreshGameplayRedDots()
        {
            if (!gameplayRedDotsSubscribed) return;
            foreach (int id in EffectiveGameplayIds)
            {
                var definition = services.GameplayCatalog.Find(id);
                bool open = definition != null && services.Player.Level >= definition.OpenLevel;
                bool ready = id == 1
                    ? services.YouLi.Items.Any(x => services.YouLi.CanClaim(x, services.Player.Level, services.ServerTime.UnixSeconds))
                    : id == 23 ? services.MoneyTree.HasFreeShake
                    : id == 3 ? services.Currencies.Has(ProjectX.Data.CurrencyIds.Stamina)
                        && services.FengShenStory.CanChallenge(services.Player.Level, services.Currencies.Stamina)
                    : services.Gameplay.Items.Any(x => x.Definition.Id == id && x.HasHotPoint);
                redDots.SetEnabled("gameplay." + id, open);
                if (id == 9)
                {
                    var searches = services.EquipmentCatalog.GetFaBaoSearches();
                    redDots.Set("gameplay.9.search", searches.Any(x => services.XunBao.CanSearch(x, services.EquipmentCatalog, services.Bag)));
                    redDots.Set("gameplay.9.compose", searches.Any(x => services.XunBao.CanCompose(x, services.Bag, services.Player.Level)));
                    redDots.Set("gameplay.9.rewards", services.Tasks.HasXunBaoClaimable);
                    redDots.Set("gameplay.9", false);
                }
                else if (id == 10)
                {
                    redDots.Set("gameplay.10.daily", services.Tasks.HasDailyClaimable);
                    redDots.Set("gameplay.10.activity", services.Tasks.HasActivityClaimable);
                    redDots.Set("gameplay.10", false);
                }
                else if (id == 21)
                {
                    bool authoritative = monopolyReminderAuthority && !monopolyReminderPending && monopolyReminderEntries > 0;
                    redDots.Set("gameplay.21.roll", authoritative && monopolyReminderHasBoard && monopolyReminderRolls > 0 && monopolyReminderEvent == 0);
                    redDots.Set("gameplay.21.continue", authoritative && monopolyReminderHasBoard && monopolyReminderEvent != 0);
                    redDots.Set("gameplay.21.round", authoritative && (!monopolyReminderHasBoard || monopolyReminderRolls == 0 && monopolyReminderEvent == 0));
                    redDots.Set("gameplay.21", false);
                }
                else if (id == 27)
                {
                    redDots.Set("gameplay.27.round", answerReminderAuthority && !answerReminderPending && answerReminderRounds > 0 && !answerReminderQuestion);
                    redDots.Set("gameplay.27.question", answerReminderAuthority && !answerReminderPending && answerReminderQuestion);
                    redDots.Set("gameplay.27", false);
                }
                else if (id == 29)
                {
                    redDots.Set("gameplay.29.single", services.HappyWheel.CanSpin(0, services.Bag, services.ServerTime.UnixSeconds));
                    redDots.Set("gameplay.29.multi", services.HappyWheel.CanSpin(1, services.Bag, services.ServerTime.UnixSeconds));
                    redDots.Set("gameplay.29", false);
                }
                else if (id == 32)
                {
                    foreach (var fish in services.Fish.Slots)
                    {
                        if (fishReminderSlots.Add(fish.SlotIndex))
                            redDots.Define("gameplay.32.slot." + fish.SlotIndex, "gameplay.32.basket");
                    }
                    foreach (ushort slot in fishReminderSlots)
                        redDots.Set("gameplay.32.slot." + slot, services.Fish.CanCollect(slot));
                    redDots.Set("gameplay.32.basket", false);
                    redDots.Set("gameplay.32", false);
                }
                else redDots.Set(id == 23 ? "gameplay.23.coin" : id == 3 ? "gameplay.3.challenge" : "gameplay." + id, ready);
            }
            services.Gameplay.SetFunctionHotPoint(1, redDots.IsVisible("gameplay.1"));
            services.Gameplay.SetFunctionHotPoint(23, redDots.IsVisible("gameplay.23"));
            services.Gameplay.SetFunctionHotPoint(3, redDots.IsVisible("gameplay.3"));
            services.Gameplay.SetFunctionHotPoint(9, redDots.IsVisible("gameplay.9"));
            services.Gameplay.SetFunctionHotPoint(10, redDots.IsVisible("gameplay.10"));
            services.Gameplay.SetFunctionHotPoint(21, redDots.IsVisible("gameplay.21"));
            services.Gameplay.SetFunctionHotPoint(27, redDots.IsVisible("gameplay.27"));
            services.Gameplay.SetFunctionHotPoint(29, redDots.IsVisible("gameplay.29"));
            services.Gameplay.SetFunctionHotPoint(32, redDots.IsVisible("gameplay.32"));
            fishPresenter?.RefreshRedDots(RedDotTemplate);
            happyWheelPresenter?.RefreshRedDots(redDots.IsVisible("gameplay.29.single"), redDots.IsVisible("gameplay.29.multi"), RedDotTemplate);
            monopolyPresenter?.RefreshRedDots(redDots.IsVisible("gameplay.21.roll") || redDots.IsVisible("gameplay.21.continue"), redDots.IsVisible("gameplay.21.round"), RedDotTemplate);
            foreach (string hand in new[] { "btn_Stone", "btn_Scissor", "btn_Cloth" })
                RedDotVisual.Set(monopolyHandView?.FindNode("Layer/caiquanUI/caiquanbg/" + hand)?.transform,
                    redDots.IsVisible("gameplay.21.continue") && monopolyReminderEvent == 2, RedDotTemplate);
            taskPresenter?.RefreshRedDots(RedDotTemplate);
            xunBaoPopupPresenter?.RefreshTaskRedDots(RedDotTemplate);
            xunBaoPresenter?.RefreshTaskRedDot(redDots.IsVisible("gameplay.9.rewards"), RedDotTemplate);
            RedDotVisual.Set(FindMainHudNode(TaskPath)?.transform, redDots.IsVisible("gameplay.10"), RedDotTemplate);
            RedDotVisual.Set(taskBackgroundView?.FindNode("Layer/Panel_1/Btn_ListView/Panel_1/Button")?.transform, redDots.IsVisible("gameplay.10"), RedDotTemplate);
            xunBaoPresenter?.RefreshRedDots(services.Player.Level, services.ServerTime.UnixSeconds, RedDotTemplate);
            fengShenStoryPresenter?.RefreshRedDot(redDots.IsVisible("gameplay.3"), RedDotTemplate);
            moneyTreePresenter?.RefreshRedDot(redDots.IsVisible("gameplay.23"), RedDotTemplate);
            RedDotVisual.Set(FindMainHudNode(GameplayPath)?.transform, redDots.IsVisible("gameplay"), RedDotTemplate);
            RedDotVisual.Set(worldMapView?.FindNode("Layer/Panel_youxia/Button_youlisanjie")?.transform,
                redDots.IsVisible("gameplay.1"), RedDotTemplate);
            youLiPresenter?.Tick(services.ServerTime.UnixSeconds, services.Player.Level);
        }

        private void TickGameplayRedDots()
        {
            if (services == null || !gameplayRedDotsSubscribed) return;
            long second = (long)services.ServerTime.UnixSeconds;
            if (second == gameplayRedDotSecond) return;
            gameplayRedDotSecond = second;
            if (services.ServerTime.IsSynchronized)
            {
                long day = (second - services.ServerTime.TodaySeconds) / 86400;
                if (gameplaySnapshotDay >= 0 && day != gameplaySnapshotDay) gameplayDayRefreshPending = true;
                gameplaySnapshotDay = day;
                if (gameplayDayRefreshPending && services.MoneyTree.PendingShakeType == 0)
                {
                    gameplayDayRefreshPending = false;
                    using (var refresh = services.Lua.GetFunction("OnMoneyTreeRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "MoneyTree.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnFengShenStoryRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "FengShenStory.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnTaskRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "Task.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnMonopolyRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "Monopoly.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnAnswerRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "Answer.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnHappyWheelRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "HappyWheel.DayRefresh");
                    using (var refresh = services.Lua.GetFunction("OnShopRedDotRefresh"))
                        InvokeLuaOrFail(refresh, "Shop.DayRefresh");
                }
            }
            RefreshGameplayRedDots();
            TickShopRedDots();
        }

        public void SetYouLiPending(int id) => services.YouLi.SetPending(checked((byte)id));

        private void DisposeGameplayRedDots()
        {
            if (!gameplayRedDotsSubscribed) return;
            services.Gameplay.Changed -= RefreshGameplayRedDots;
            services.YouLi.Changed -= RefreshGameplayRedDots;
            services.MoneyTree.Changed -= RefreshGameplayRedDots;
            services.FengShenStory.Changed -= RefreshGameplayRedDots;
            services.Currencies.Changed -= RefreshGameplayRedDots;
            services.XunBao.Changed -= RefreshGameplayRedDots;
            services.Bag.Changed -= RefreshGameplayRedDots;
            services.Tasks.Changed -= RefreshGameplayRedDots;
            services.Player.Changed -= RefreshGameplayRedDots;
            services.HappyWheel.Changed -= RefreshGameplayRedDots;
            services.Fish.Changed -= RefreshGameplayRedDots;
            services.GameplayShops.Changed -= RefreshShopRedDots;
            gameplayRedDotsSubscribed = false;
        }
    }
}
