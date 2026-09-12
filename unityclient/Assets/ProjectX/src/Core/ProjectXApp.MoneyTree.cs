using System;
using System.Collections.Generic;
using ProjectX.Data;
using ProjectX.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private LuaFunction onMoneyTreeClicked;
        private LuaFunction onMoneyTreeShake;
        private CocosUiView moneyTreeView;
        private MoneyTreePresenter moneyTreePresenter;
        private readonly List<MoneyTreeRecord> pendingMoneyTreeRecords = new List<MoneyTreeRecord>();

        public void ShowMoneyTree(int functionId)
        {
            GameplayDefinition definition = services.GameplayCatalog.Find(functionId);
            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            if (definition == null || route.Target != "MoneyTree" || string.IsNullOrWhiteSpace(route.PrefabKey))
            {
                Fail($"MoneyTree route config is incomplete: id={functionId}.");
                return;
            }
            EnsureMoneyTreePresenter(route);
            gameplayPresenter?.HideDetail();
            gameplayContentView?.SetVisible(false);
            if (services.UiStack.Current != moneyTreeView) services.UiStack.Push(moneyTreeView, false);
            SetStatus($"MoneyTree UI active: id={functionId}; awaiting /222 op=17 query.");
        }

        public void BeginMoneyTreeState() => pendingMoneyTreeRecords.Clear();

        public void AddMoneyTreeRecord(int type, int usedCount, int freeCount, int maxCount,
            int costType, double costValue, int rewardType, double rewardValue)
        {
            pendingMoneyTreeRecords.Add(new MoneyTreeRecord(checked((byte)type), checked((byte)usedCount),
                checked((byte)freeCount), checked((byte)maxCount), checked((ushort)costType),
                checked((uint)costValue), checked((ushort)rewardType), checked((uint)rewardValue)));
        }

        public void CommitMoneyTreeState() => services.MoneyTree.Replace(pendingMoneyTreeRecords);
        public bool BeginMoneyTreeShake(int type) => services.MoneyTree.BeginShake(checked((byte)type));

        public void CompleteMoneyTreeShake(int type, int usedCount, int freeCount, int maxCount,
            int costType, double costValue, int rewardType, double rewardValue)
        {
            MoneyTreeRecord record = new MoneyTreeRecord(checked((byte)type), checked((byte)usedCount),
                checked((byte)freeCount), checked((byte)maxCount), checked((ushort)costType),
                checked((uint)costValue), checked((ushort)rewardType), checked((uint)rewardValue));
            services.MoneyTree.CompleteShake(record, true);
        }

        public void FailMoneyTreeShake(int type) => services.MoneyTree.FailShake(checked((byte)type));
        public void ClearMoneyTreeState(){services.MoneyTree.Clear();pendingMoneyTreeRecords.Clear();}
        private void RequestMoneyTreeShake(byte type) =>
            InvokeLuaOrFail(onMoneyTreeShake, "MoneyTree.Shake", (double)type);

        private bool TryHandleMoneyTreeBack()
        {
            if (moneyTreeView == null || services?.UiStack.Current != moneyTreeView) return false;
            bool popped = PopUiStackWithHudRefresh();
            if (popped) gameplayContentView?.SetVisible(true);
            return popped;
        }

        private void EnsureMoneyTreePresenter(FunctionRouteDefinition route)
        {
            if (moneyTreeView == null)
            {
                if (!configuredGameplayViews.TryGetValue(route.PrefabKey, out moneyTreeView) || moneyTreeView?.GameObject == null)
                {
                    moneyTreeView = UiPrefabLoader.Load(route.PrefabKey, gameplayView.GameObject.transform);
                    configuredGameplayViews[route.PrefabKey] = moneyTreeView;
                }
            }
            if (moneyTreePresenter != null) return;
            if (!string.IsNullOrWhiteSpace(route.ClosePath))
                moneyTreeView.BindClick(route.ClosePath, () => { TryHandleMoneyTreeBack(); });
            moneyTreePresenter = new MoneyTreePresenter(moneyTreeView, services.MoneyTree,
                RequestMoneyTreeShake,
                () => ShowToast("额外次数由贵族配置决定，贵族界面暂未迁移。", 3f),
                ShowMoneyTreeReward);
        }

        private void ShowMoneyTreeReward(MoneyTreeRecord reward)
        {
            RewardRecord described = services.ShopCatalog.DescribeReward(
                reward.RewardType, 0, reward.RewardValue);
            ShowToast($"{described.Name} +{reward.RewardValue}", 2f);
            SetStatus($"MoneyTree reward: type={reward.RewardType}, value={reward.RewardValue}; currency remains server-authoritative.");
        }
    }
}
