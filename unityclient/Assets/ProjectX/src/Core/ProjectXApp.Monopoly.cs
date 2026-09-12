using System;
using System.Collections.Generic;
using ProjectX.Data;
using ProjectX.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private LuaFunction onMonopolyClicked, onMonopolyRoll, onMonopolyMoveEnd, onMonopolyReset;
        private LuaFunction onMonopolyQueryBuy, onMonopolyBuyRoll, onMonopolyFightGuard, onMonopolyClose;
        private LuaFunction onMonopolyPlayHand;
        private CocosUiView monopolyView, monopolyHudView, monopolyHandView;
        private MonopolyPresenter monopolyPresenter;
        private readonly List<MonopolyCell> pendingMonopolyCells = new List<MonopolyCell>();
        private uint pendingMonopolyCurrent, pendingMonopolyRollMax, pendingMonopolyRollUse;
        private uint pendingMonopolyMonsterMax, pendingMonopolyMonsterKill, pendingMonopolyExp, pendingMonopolyCoin, pendingMonopolyGold;
        private bool hasPendingMonopolyBattleResult, pendingMonopolyBattleWin;
        private uint pendingMonopolyBattleDestination, pendingMonopolyBattleExp, pendingMonopolyBattleCoin;
        private uint pendingMonopolyBattleGold, pendingMonopolyBattleMaxKill, pendingMonopolyBattleCurKill;
        private uint pendingMonopolyBattleStars;
        private string pendingMonopolyBattleRewards = string.Empty;

        private bool IsMonopolyOpen => monopolyView != null && monopolyView.GameObject != null
            && services?.UiStack.Current == monopolyView;

        public void ShowMonopoly(int functionId)
        {
            GameplayDefinition definition = services.GameplayCatalog.Find(functionId);
            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            if (definition == null || route.Target != "Monopoly" || string.IsNullOrWhiteSpace(route.PrefabKey))
            { Fail($"Monopoly route config is incomplete: id={functionId}."); return; }
            EnsureMonopolyPresenter(route);
            gameplayPresenter?.HideDetail(); gameplayContentView?.SetVisible(false);
            if (services.UiStack.Current != monopolyView) services.UiStack.Push(monopolyView, true);
            monopolyHudView.SetVisible(true);
            SetStatus("Monopoly/213 single-player board active; op=15 query requested.");
        }

        public void BeginMonopolyBoard(double timediff, double exp, double coin, double gold, double rollMax,
            double rollUse, double monsterMax, double monsterKill, double cellCount, double current)
        {
            pendingMonopolyCells.Clear();
            pendingMonopolyExp = checked((uint)exp); pendingMonopolyCoin = checked((uint)coin); pendingMonopolyGold = checked((uint)gold);
            pendingMonopolyRollMax = checked((uint)rollMax); pendingMonopolyRollUse = checked((uint)rollUse);
            pendingMonopolyMonsterMax = checked((uint)monsterMax); pendingMonopolyMonsterKill = checked((uint)monsterKill);
            pendingMonopolyCurrent = checked((uint)current);
        }

        public void AddMonopolyCell(double id, double eventId, double eventCount, double roleId, double career,
            double level, double sex, double power, string name, double awardType, double awardAmount)
        {
            pendingMonopolyCells.Add(new MonopolyCell {
                Id=checked((uint)id), EventId=checked((uint)eventId), EventCount=checked((uint)eventCount),
                RoleId=checked((uint)roleId), Career=checked((uint)career), Level=checked((uint)level), Sex=checked((uint)sex),
                Power=checked((uint)power), Name=name??string.Empty, AwardType=checked((uint)awardType), AwardAmount=checked((uint)awardAmount)
            });
        }

        public void CommitMonopolyBoard()
        {
            monopolyPresenter?.Replace(pendingMonopolyCurrent, pendingMonopolyRollMax, pendingMonopolyRollUse,
                pendingMonopolyMonsterMax, pendingMonopolyMonsterKill, pendingMonopolyExp, pendingMonopolyCoin,
                pendingMonopolyGold, pendingMonopolyCells);
            SetStatus($"Monopoly/213 op=15 received: cells={pendingMonopolyCells.Count}, current={pendingMonopolyCurrent}, rolls={pendingMonopolyRollUse}/{pendingMonopolyRollMax}.");
        }

        public void CompleteMonopolyRoll(double destination, double dice, double maximum, double remaining)
            => monopolyPresenter?.RollTo(checked((uint)destination), checked((uint)dice), checked((uint)maximum), checked((uint)remaining));
        public void ResolveMonopolyEvent(double eventId, double target)
            => monopolyPresenter?.ResolveEvent(checked((uint)eventId), checked((uint)target));
        public void UpdateMonopolyRewards(double exp, double coin, double gold)
            => monopolyPresenter?.UpdateRewards(checked((uint)exp), checked((uint)coin), checked((uint)gold));
        public void CompleteMonopolyBuy(double maximum, double remaining)
        { monopolyPresenter?.UpdateRolls(checked((uint)maximum), checked((uint)remaining)); ShowToast("骰子次数购买成功", 2f); }
        public void CompleteMonopolyBattle(double win, double destination, double exp, double coin, double gold,
            double maxKill, double curKill, double stars, string rewards)
        {
            pendingMonopolyBattleWin = win != 0;
            pendingMonopolyBattleDestination = checked((uint)destination);
            pendingMonopolyBattleExp = checked((uint)exp);
            pendingMonopolyBattleCoin = checked((uint)coin);
            pendingMonopolyBattleGold = checked((uint)gold);
            pendingMonopolyBattleMaxKill = checked((uint)maxKill);
            pendingMonopolyBattleCurKill = checked((uint)curKill);
            pendingMonopolyBattleStars = checked((uint)stars);
            pendingMonopolyBattleRewards = rewards ?? string.Empty;
            hasPendingMonopolyBattleResult = true;
            if (battlePlaybackContext != BattlePlaybackContext.Monopoly
                || (worldBattlePlaybackCoroutine == null && worldBattlePlaybackPresenter?.IsVisible != true))
                ApplyPendingMonopolyBattleResult();
        }
        public void CompleteMonopolyHand(double result, string detail)
            => monopolyPresenter?.CompleteHand(checked((uint)result), detail ?? string.Empty);
        public void FailMonopolyOperation(double code, string detail)
        { monopolyPresenter?.SetBusy(false); ShowToast(string.IsNullOrWhiteSpace(detail) ? $"闯关操作失败({code})" : detail, 3f); }
        public void ShowMonopolyGuard() => ShowMonopolyGuardConfirmation();
        public void ClearMonopolyState() { pendingMonopolyCells.Clear(); monopolyPresenter?.SetBusy(false); }

        public void ShowMonopolyBuy(double useType, double price, double bought, double maximum)
        {
            EnsureErrorPresenter();
            if (bought >= maximum) { ShowToast("本轮购买次数已达上限", 2f); return; }
            errorPresenter.ShowConfirmation("购买骰子", $"消耗{checked((uint)price)}（货币类型{checked((uint)useType)}）购买1次骰子？\n本轮已购买 {checked((uint)bought)}/{checked((uint)maximum)} 次。",
                () => InvokeLuaOrFail(onMonopolyBuyRoll, "Monopoly.BuyRoll"));
        }

        public void CloseMonopolyFromServer() => TryHandleMonopolyBack();

        private void EnsureMonopolyPresenter(FunctionRouteDefinition route)
        {
            if (monopolyView == null || monopolyView.GameObject == null)
                monopolyView = UiPrefabLoader.Load(route.PrefabKey, GetDynamicUiRoot());
            if (monopolyHudView == null || monopolyHudView.GameObject == null)
                monopolyHudView = UiPrefabLoader.Load("GameLayer", monopolyView.GameObject.transform);
            if (monopolyHandView == null || monopolyHandView.GameObject == null)
            {
                monopolyHandView = UiPrefabLoader.Load("caiquanLayer", GetDynamicUiRoot());
                monopolyHandView.SetVisible(false);
            }
            if (monopolyPresenter != null) return;
            monopolyPresenter = new MonopolyPresenter(monopolyView, monopolyHudView, monopolyHandView, services.Player.Model, services.Player.Level,
                () => InvokeLuaOrFail(onMonopolyRoll, "Monopoly.Roll"),
                () => InvokeLuaOrFail(onMonopolyQueryBuy, "Monopoly.QueryBuy"),
                ShowMonopolyResetConfirmation,
                () => InvokeLuaOrFail(onMonopolyClose, "Monopoly.Close"),
                () => InvokeLuaOrFail(onMonopolyMoveEnd, "Monopoly.MoveEnd"),
                ShowMonopolyGuardConfirmation,
                choice => InvokeLuaOrFail(onMonopolyPlayHand, "Monopoly.PlayHand", (double)choice),
                message => ShowToast(message, 3f), ShowMonopolyHelp);
            monopolyPresenter.BindRuntimePlayer();
        }

        private void ShowMonopolyResetConfirmation()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation("重置闯关", "重置会放弃本轮进度并扣除1次参与次数，是否继续？",
                () => InvokeLuaOrFail(onMonopolyReset, "Monopoly.Reset"));
        }
        private void ShowMonopolyGuardConfirmation()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation("挑战守卫", "击败当前机器人守卫后才能继续前进。", () =>
                InvokeLuaOrFail(onMonopolyFightGuard, "Monopoly.FightGuard"), "挑战");
        }
        private void PrepareMonopolyBattlePlayback()
        {
            monopolyPresenter?.SetBusy(true);
            monopolyHandView?.SetVisible(false);
            monopolyHudView?.SetVisible(false);
            monopolyView?.SetVisible(false);
        }
        private void CompleteMonopolyBattlePlayback()
        {
            monopolyView?.SetVisible(true);
            monopolyHudView?.SetVisible(true);
            ApplyPendingMonopolyBattleResult();
            SetStatus("Monopoly fightType=21 playback completed and returned to the board.");
        }
        private void ApplyPendingMonopolyBattleResult()
        {
            if (!hasPendingMonopolyBattleResult) return;
            hasPendingMonopolyBattleResult = false;
            monopolyPresenter?.BattleResult(pendingMonopolyBattleWin, pendingMonopolyBattleDestination,
                pendingMonopolyBattleExp, pendingMonopolyBattleCoin, pendingMonopolyBattleGold,
                pendingMonopolyBattleMaxKill, pendingMonopolyBattleCurKill, pendingMonopolyBattleStars,
                pendingMonopolyBattleRewards);
        }
        private void ShowMonopolyHelp()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowHelp("1、每天可以参与2次。\n2、每轮有25次投掷机会，次数不足可购买。\n3、骰子点数决定前进格数。\n4、金币、元宝、宝箱会获得奖励，问号为随机事件。\n5、遇到机器人守卫需击败后继续。\n6、到达终点获得最终奖励；次数用尽可重置本轮。");
        }
        private bool TryHandleMonopolyBack()
        {
            if (monopolyView == null || services?.UiStack.Current != monopolyView) return false;
            monopolyPresenter?.SetBusy(false);
            monopolyHandView?.SetVisible(false);
            bool popped = PopUiStackWithHudRefresh();
            if (popped) gameplayContentView?.SetVisible(true);
            return popped;
        }
    }
}
