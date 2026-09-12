using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private LuaFunction onHappyWheelClicked;
        private LuaFunction onHappyWheelSpin;
        private CocosUiView happyWheelView;
        private HappyWheelPresenter happyWheelPresenter;
        private readonly List<HappyWheelReward> pendingHappyWheelRewards = new List<HappyWheelReward>();
        private readonly List<string> pendingHappyWheelHistory = new List<string>();
        private readonly List<int> pendingHappyWheelSpinIndexes = new List<int>();
        private uint pendingHappyWheelSpinScore;
        private int pendingHappyWheelSelectedIndex;

        public void ShowHappyWheel(int functionId)
        {
            GameplayDefinition definition = services.GameplayCatalog.Find(functionId);
            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            if (definition == null || route.Target != "HappyWheel" || string.IsNullOrWhiteSpace(route.PrefabKey))
            {
                Fail($"HappyWheel route config is incomplete: id={functionId}.");
                return;
            }
            EnsureHappyWheelPresenter(route);
            gameplayPresenter?.HideDetail();
            gameplayContentView?.SetVisible(false);
            if (services.UiStack.Current != happyWheelView) services.UiStack.Push(happyWheelView, false);
            SetStatus($"HappyWheel UI active: id={functionId}; awaiting /222 op=33 query.");
        }

        public void BeginHappyWheelState()
        {
            pendingHappyWheelRewards.Clear();
            pendingHappyWheelHistory.Clear();
        }

        public void AddHappyWheelReward(int type, double amount, int featured) =>
            pendingHappyWheelRewards.Add(new HappyWheelReward(checked((ushort)type),
                checked((uint)amount), checked((byte)featured)));

        public void AddHappyWheelHistory(string value)
        {
            if (!string.IsNullOrWhiteSpace(value)) pendingHappyWheelHistory.Add(value);
        }

        public void CommitHappyWheelState(double score, double activitySeconds, double resetSeconds,
            int costItemId, int singleDrawCount, int singleKeyCost,
            int multiDrawCount, int multiKeyCost, int scorePerDraw, int historyLimit)
        {
            services.HappyWheel.Replace(checked((uint)score), checked((uint)activitySeconds),
                checked((uint)resetSeconds), pendingHappyWheelRewards, pendingHappyWheelHistory,
                checked((ushort)costItemId), checked((byte)singleDrawCount), checked((byte)singleKeyCost),
                checked((byte)multiDrawCount), checked((byte)multiKeyCost), checked((ushort)scorePerDraw),
                checked((byte)historyLimit));
        }

        public bool BeginHappyWheelSpin(int drawType) => services.HappyWheel.BeginSpin(drawType);

        public void BeginHappyWheelSpinResult(double score, int selectedIndex)
        {
            pendingHappyWheelSpinScore = checked((uint)score);
            pendingHappyWheelSelectedIndex = selectedIndex;
            pendingHappyWheelHistory.Clear();
            pendingHappyWheelSpinIndexes.Clear();
        }

        public void AddHappyWheelSpinHistory(string value)
        {
            if (!string.IsNullOrWhiteSpace(value)) pendingHappyWheelHistory.Add(value);
        }

        public void AddHappyWheelSpinIndex(int index) => pendingHappyWheelSpinIndexes.Add(index);

        public void CommitHappyWheelSpinResult() => services.HappyWheel.CompleteSpin(
            pendingHappyWheelSpinScore, pendingHappyWheelSelectedIndex,
            pendingHappyWheelHistory, pendingHappyWheelSpinIndexes);

        public void FailHappyWheelSpin() => services.HappyWheel.FailSpin();

        public void ClearHappyWheelState()
        {
            services.HappyWheel.Clear();
            pendingHappyWheelRewards.Clear();
            pendingHappyWheelHistory.Clear();
            pendingHappyWheelSpinIndexes.Clear();
        }

        private void RequestHappyWheelSpin(byte drawType) =>
            InvokeLuaOrFail(onHappyWheelSpin, "HappyWheel.Spin", (double)drawType);

        private void OpenHappyWheelShop()
        {
            TryHandleHappyWheelBack();
            ShowShop();
        }

        private bool TryHandleHappyWheelBack()
        {
            if (happyWheelView == null || services?.UiStack.Current != happyWheelView) return false;
            bool popped = PopUiStackWithHudRefresh();
            if (popped) gameplayContentView?.SetVisible(true);
            return popped;
        }

        private void EnsureHappyWheelPresenter(FunctionRouteDefinition route)
        {
            if (happyWheelView == null)
            {
                if (!configuredGameplayViews.TryGetValue(route.PrefabKey, out happyWheelView)
                    || happyWheelView?.GameObject == null)
                {
                    happyWheelView = UiPrefabLoader.Load(route.PrefabKey, gameplayView.GameObject.transform);
                    configuredGameplayViews[route.PrefabKey] = happyWheelView;
                }
            }
            if (happyWheelPresenter != null) return;
            if (!string.IsNullOrWhiteSpace(route.ClosePath))
                happyWheelView.BindClick(route.ClosePath, () => { TryHandleHappyWheelBack(); });
            happyWheelPresenter = new HappyWheelPresenter(happyWheelView, services.HappyWheel,
                services.Bag, services.Currencies, services.Resources, services.ShopCatalog,
                RequestHappyWheelSpin, OpenHappyWheelShop, ShowHappyWheelRewards,
                ShowHappyWheelRewardTip);
        }

        private void ShowHappyWheelRewards(IReadOnlyList<RewardRecord> rewards)
        {
            if (rewards == null || rewards.Count == 0) return;
            string summary = string.Join("、", rewards.GroupBy(value => value.Name)
                .Select(group => $"{group.Key} +{group.Sum(value => (long)value.Amount)}"));
            SetStatus($"HappyWheel reward received: {summary}; inventory and currencies remain server-authoritative.");
        }

        private void ShowHappyWheelRewardTip(RewardRecord reward)
        {
            services.ShopCatalog.TryGetServerItemPresentation(reward.Type,
                out string description, out string source);
            var lines = new List<string> { reward.Name, $"数量：{reward.Amount}" };
            if (!string.IsNullOrWhiteSpace(description)) lines.Add(description);
            if (!string.IsNullOrWhiteSpace(source)) lines.Add(source);
            EnsureErrorPresenter();
            errorPresenter.Show("道具详情", string.Join("\n", lines));
        }
    }
}
