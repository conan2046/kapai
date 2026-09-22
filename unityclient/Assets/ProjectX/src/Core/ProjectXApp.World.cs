using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BeginWorldChapterList(int mapType, int expectedCount)
        {
            pendingWorldMapType = checked((byte)mapType);
            pendingWorldChapters.Clear();
            if (expectedCount > pendingWorldChapters.Capacity) pendingWorldChapters.Capacity = expectedCount;
        }

        public void AddWorldChapter(double id, string name, int openLevel, int maximumStars)
        {
            pendingWorldChapters.Add(new WorldChapterRecord
            {
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                OpenLevel = checked((ushort)openLevel),
                MaximumStars = checked((byte)maximumStars)
            });
        }

        public void SetWorldChapterProgress(double id, int ownedStars, int claimedBoxes)
        {
            uint chapterId = checked((uint)id);
            WorldChapterRecord chapter = pendingWorldChapters.FirstOrDefault(value => value.Id == chapterId);
            if (chapter == null) return;
            chapter.OwnedStars = checked((ushort)ownedStars);
            chapter.ClaimedBoxes = checked((byte)claimedBoxes);
        }

        public void EndWorldChapterList(double currentChapterId, double currentStageId)
        {
            services.World.ReplaceChapters(pendingWorldMapType, checked((uint)currentChapterId),
                checked((uint)currentStageId), pendingWorldChapters);
            EnsureWorldPresenter();
            // 默认章节＝上次挑战过的章节（没有记录时退回进度章）
            uint preferredChapterId = ResolveLastWorldChapterId();
            worldPresenter.ShowWorld(preferredChapterId);
            // 底栏「通关奖励」条（DadituuiLayer/bg/Panel_2/ListView_1）由
            // WorldPresenter.RenderBossRewardPreview() 汇总 store.Stages[].Rewards 绘制。
            // 而 SelectedChapterId / Stages 只在 ReplaceStages（/320 op=2 回包）里赋值，
            // 章节列表态下恒为 0 / 空 ⇒ 奖励条永远是空的（进副本看到一条空框）。
            // 这里补一次「当前章节」请求（与章节行点击同一条 Lua 通路 World.RequestChapter），
            // 把玩家当前章节的关卡列表拉下来，奖励条即可在章节选择页显示本章通关收益。
            StartCoroutine(RequestWorldRewardPreviewChapter(
                preferredChapterId != 0 ? preferredChapterId : checked((uint)currentChapterId)));
            SetStatus($"World/320 map: {services.World.ChapterCount} chapters, current={checked((uint)currentChapterId)}/{checked((uint)currentStageId)}.");
        }

        // 延后一帧再发：EndWorldChapterList 是 Lua op=1 回调的同步出口，
        // 直接在里面回呼 Lua 会重入 Lua 状态机。
        // 玩家点了某个章节（＝选中并准备挑战它）时记录，下次进副本默认回到这一章。
        private void RememberLastWorldChapter(uint chapterId)
        {
            if (chapterId == 0) return;
            lastWorldChapterId = chapterId;
            PlayerPrefs.SetInt(LastWorldChapterKey, checked((int)chapterId));
            PlayerPrefs.Save();
        }

        private string LastWorldChapterKey
        {
            get
            {
                uint roleId = services != null && services.Player != null ? services.Player.RoleId : 0;
                return LastWorldChapterKeyPrefix + roleId;
            }
        }

        // 取上次章节：先看运行时缓存，没有再读本地存档；仍没有则为 0（调用方退回进度章）。
        private uint ResolveLastWorldChapterId()
        {
            if (lastWorldChapterId != 0) return lastWorldChapterId;
            int saved = PlayerPrefs.GetInt(LastWorldChapterKey, 0);
            lastWorldChapterId = saved > 0 ? checked((uint)saved) : 0;
            return lastWorldChapterId;
        }

        private IEnumerator RequestWorldRewardPreviewChapter(uint chapterId)
        {
            yield return null;
            if (chapterId == 0) yield break;
            if (services.World.Chapters.All(value => value.Id != chapterId)) yield break;
            // 已有该章节的关卡数据就不重复请求（例如从别处返回章节列表）。
            if (services.World.SelectedChapterId == chapterId && services.World.StageCount > 0) yield break;
            pendingRewardPreviewChapter = chapterId;
            InvokeLuaOrFail(onWorldRequestChapter, "World.RequestChapter", (double)chapterId);
        }

        public double GetFirstWorldChapterId() => services.World.Chapters.FirstOrDefault()?.Id ?? 0;
        public double GetWorldSelectedChapterId() => services.World.SelectedChapterId;
        public double GetWorldPreferredStageId() => services.World.SelectedStageId;
        // Lua controls must use the stage currently opened by the player.  Keep
        // the older name above for existing callers while making that contract
        // explicit for new World interactions.
        public double GetWorldSelectedStageId() => services.World.SelectedStageId;

        public void BeginWorldStageList(int mapType, double chapterId, string chapterName, int expectedCount)
        {
            pendingWorldMapType = checked((byte)mapType);
            pendingWorldChapterId = checked((uint)chapterId);
            pendingWorldChapterName = chapterName ?? string.Empty;
            pendingWorldStages.Clear();
            pendingWorldStarBoxes.Clear();
            pendingWorldStage = null;
            // 判定这次 op=2 是不是「只为喂通关奖励条」的后台预热请求，并立刻清掉挂起标记
            // （避免回包丢失时污染后续的章节行点击）。
            stageListIsRewardPreview = pendingRewardPreviewChapter != 0
                && checked((uint)chapterId) == pendingRewardPreviewChapter;
            pendingRewardPreviewChapter = 0;
            if (expectedCount > pendingWorldStages.Capacity) pendingWorldStages.Capacity = expectedCount;
        }

        public void BeginWorldStage(double id, string name, int stars, int attempts, int spiritCost,
            int remainingResets, int resetCost, double nextStageId, double rewardBoxId, int rewardBoxState)
        {
            pendingWorldStage = new WorldStageRecord
            {
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                Stars = checked((byte)stars),
                RemainingAttempts = checked((byte)attempts),
                SpiritCost = checked((byte)spiritCost),
                RemainingResets = checked((byte)remainingResets),
                ResetCost = checked((ushort)resetCost),
                NextStageId = checked((uint)nextStageId),
                RewardBoxId = checked((uint)rewardBoxId),
                RewardBoxState = checked((byte)rewardBoxState)
            };
        }

        public void AddWorldStageReward(int type, double id, double amount, string name, int picture, int quality,
            bool isCurrency)
        {
            if (pendingWorldStage == null) throw new InvalidOperationException("World stage reward arrived without a stage.");
            pendingWorldStage.AddReward(new RewardRecord(type, checked((uint)id), checked((uint)amount),
                name, picture, quality), isCurrency);
        }

        public void EndWorldStage()
        {
            if (pendingWorldStage == null) throw new InvalidOperationException("World stage end arrived without a stage.");
            pendingWorldStages.Add(pendingWorldStage);
            pendingWorldStage = null;
        }

        public void AddWorldStarBox(int requiredStars, double rewardId, int state)
        {
            pendingWorldStarBoxes.Add(new WorldStarBoxRecord
            {
                RequiredStars = checked((byte)requiredStars),
                RewardId = checked((uint)rewardId),
                State = checked((byte)state)
            });
        }

        public void EndWorldStageList()
        {
            services.World.ReplaceStages(pendingWorldMapType, pendingWorldChapterId, pendingWorldChapterName,
                pendingWorldStages, pendingWorldStarBoxes);
            EnsureWorldPresenter();
            worldFormationReturnPending = false;
            worldFormationReturnToDetail = false;
            worldFormationReturnToChapters = false;
            // 只为喂「通关奖励」条（ListView_1）而发的后台 op=2：保持章节列表首屏，
            // 只重绘一次让奖励条汇总出数据，不要切到关卡地图打断玩家的章节选择。
            // （标记在 BeginWorldStageList 里按章节号判定并清除。）
            bool rewardPreviewOnly = stageListIsRewardPreview;
            stageListIsRewardPreview = false;
            if (rewardPreviewOnly) worldPresenter.Render();
            // 类型 2（龙崖）：点章节图标＝「选中」该章——只刷新选中头像与下方奖励条，
            // 章节列表必须留在原地，玩家才能连续切换已通关章节；离开章节页改由
            // 点「挑战」(bg/Button_1) 或连战开始触发（BeginChainStage 内收起）。
            else if (worldChainMode) worldPresenter.Render();
            else worldPresenter.ShowStages();
            StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
            SetStatus($"World/320 chapter {pendingWorldChapterId}: {services.World.StageCount} stages.");
            if (rewardPreviewOnly) return;
            // 「自动挑战下一章」：下一章关卡列表就绪后自动发起连战
            if (pendingAutoNextChapter != 0 && services.World.SelectedChapterId == pendingAutoNextChapter
                && services.World.StageCount > 0)
            {
                pendingAutoNextChapter = 0;
                StartCoroutine(AutoNextChainStart());
            }
            else if (pendingAutoNextChapter != 0 && pendingWorldChapterId == pendingAutoNextChapter
                && services.World.StageCount == 0)
            {
                // 下一章无关卡数据（异常/末章）：清除挂起，避免滞留
                pendingAutoNextChapter = 0;
            }
        }

        private IEnumerator AutoNextChainStart()
        {
            // 等一帧让布点层渲染就绪，再置连战态并发起挑战（沿用当前选中关）
            yield return null;
            if (battlePlaybackContext != BattlePlaybackContext.World || !IsWorldOpen)
                yield break;
            worldPresenter?.BeginChainStage();
            worldBattleInFlight = true;
            InvokeLuaOrFail(onWorldChallenge, "World.Challenge");
        }

        public void SetWorldStageStatus(int mapType, double chapterId, double stageId, int stars,
            int foughtCount, int remainingResets)
        {
            services.World.UpdateStageStatus(checked((byte)mapType), checked((uint)chapterId), checked((uint)stageId),
                checked((byte)stars), checked((byte)foughtCount), checked((byte)remainingResets));
            EnsureWorldPresenter();
            worldPresenter.ShowSelectedStage();
            SetStatus($"World/320 stage {checked((uint)stageId)}: stars={stars}, fought={foughtCount}, resets={remainingResets}.");
        }

        public void ApplyWorldBattleResult(int foughtCount, double foughtStageId, double unlockedChapterId,
            double unlockedStageId, double unlockedBoxId, double unlockedStarBoxId, int stars,
            int chainIndex = 0, int chainTotal = 0, double chainNextStageId = 0)
        {
            // 走位起点＝**本场刚打完的这一关**（它必定属于当前选中的章）。
            // ⚠️ 不能用 CurrentStageId：那是服务端的 curNodeId，跨章选关时它仍停在
            // 「别的章」的关卡上（例如进度第 6 章时去打第 1 章，它一直是 10055）。
            // 这个 id 在 store.Stages（当前章）里找不到 → ResolveStagePlayerPosition
            // 回落 index 0 → 主角瞬移到「章节第一个点」再跑向下一关，
            // 表现就是玩家看到的「从章节初始位置跑过去」。
            uint foughtStage = foughtStageId > 0 ? checked((uint)foughtStageId) : 0u;
            uint walkFromStageId = foughtStage != 0 ? foughtStage : services.World.CurrentStageId;
            services.World.ApplyBattleResult(checked((byte)foughtCount), checked((uint)foughtStageId),
                checked((uint)unlockedChapterId), checked((uint)unlockedStageId), checked((byte)stars));
            // 龙崖连战：序号 / 总场次 / 下一关（0 = 本章已通关）
            worldChainIndex = chainIndex;
            worldChainNextStageId = chainNextStageId > 0 ? checked((uint)chainNextStageId) : 0u;
            if (worldChainNextStageId > 0 && walkFromStageId > 0 && worldChainMode)
            {
                // 还有下一场 → 锁住走位起点。结算回调已把主角推到终点，不回锁就没有
                // 「从当前点走到下一个目标点」的过程（原版 FuBenDetailUI:ModelMove）。
                worldChainWalkFromStageId = walkFromStageId;
                EnsureWorldPresenter();
                worldPresenter?.HoldStageWalkOrigin(walkFromStageId);
            }
            SetStatus($"World/320 PvE result: stage={checked((uint)foughtStageId)}, stars={stars}, next={checked((uint)unlockedStageId)}, box={checked((uint)unlockedBoxId)}/{checked((uint)unlockedStarBoxId)}"
                + (chainTotal > 0 ? $", chain={chainIndex}/{chainTotal}, chainNext={worldChainNextStageId}." : "."));
        }

        // /320 op=28 失败回包不携带完整奖励结果，但结算层仍需知道这是失败，
        // 以阻止「自动挑战下一章」把失败误判为 Boss 胜利。
        public void ApplyWorldChainLose(double nextStageId)
        {
            worldChainNextStageId = nextStageId > 0 ? checked((uint)nextStageId) : 0u;
        }

        // 龙崖副本模式（fuben_AB == 2）：模式下发、自动挑战开关、连战续接
        public void SetWorldChainMode(bool enabled)
        {
            worldChainMode = enabled;
            if (enabled)
            {
                worldBattleRuntime.PendingResult = false;
                worldBattleRuntime.PendingStars = 0;
            }
            worldPresenter?.SetChainMode(enabled);
            worldOutcomePresenter?.SetChainMode(enabled);
            SetStatus($"World chain mode {(enabled ? "enabled" : "disabled")}.");
        }

        public void SetWorldChainAuto(bool enabled)
        {
            worldChainAuto = enabled;
            // 逻辑态与 CheckBox_1 勾选态必须一致：否则会出现「界面上没勾但仍在循环重跑」
            // 这类不可解释的状态。
            worldPresenter?.SetChainAutoState(enabled);
            InvokeLuaOrFail(onWorldSetChainAuto, "World.SetChainAuto", enabled ? 1d : 0d);
            SetStatus($"World chain auto challenge {(enabled ? "on" : "off")}.");
        }

        // CheckBox_2「自动挑战下一章」：本章 BOSS 结算确认后自动进入下一章并发起连战
        public void SetWorldChainAutoNext(bool enabled)
        {
            worldChainAutoNext = enabled;
            InvokeLuaOrFail(onWorldSetChainAutoNext, "World.SetChainAutoNext", enabled ? 1d : 0d);
            SetStatus($"World chain auto next chapter {(enabled ? "on" : "off")}.");
        }

        // Lua 在「本场结束且还有下一关」时调用（胜利未到 BOSS、或失败回到第一关）。
        public void ContinueWorldChain(double nextStageId)
        {
            uint next = nextStageId > 0 ? checked((uint)nextStageId) : 0u;
            if (!worldChainMode || next == 0)
            {
                worldChainContinueToken++;
                if (worldChainContinueCoroutine != null) StopCoroutine(worldChainContinueCoroutine);
                worldChainContinueCoroutine = null;
                // 没有下一场就不会走位：释放结算时锁住的走位起点，别让主角停在旧点
                worldPresenter?.ReleaseStageWalkHold();
                return;
            }
            worldBattleInFlight = true;
            if (worldChainContinueCoroutine != null)
            {
                worldChainContinueToken++;
                StopCoroutine(worldChainContinueCoroutine);
            }
            int continueToken = ++worldChainContinueToken;
            worldChainContinueCoroutine = StartCoroutine(ContinueWorldChainAfterDelay(next, continueToken));
        }

        private IEnumerator ContinueWorldChainAfterDelay(uint nextStageId, int token)
        {
            // 龙崖节奏必须等 /38 回放播完再往下走（玩家点「跳过」时协程会提前结束并置空）。
            // 旧实现是「点挑战后无条件等 2 秒就 Hide 回放层」，于是战斗才播完起手动画
            // 画面就被切走 —— 玩家观感就是被踢出战斗。超时只为兜住异常路径。
            float playbackDeadline = Time.realtimeSinceStartup + MaxWorldBattlePlaybackWait;
            while (worldBattlePlaybackCoroutine != null && Time.realtimeSinceStartup < playbackDeadline)
                yield return null;
            if (token != worldChainContinueToken || battlePlaybackContext != BattlePlaybackContext.World)
            {
                // A Monopoly/FengShenStory overlay may replace the active
                // playback context while this World continuation is waiting.
                // Do not leave a dead Coroutine handle behind: ShowWorld()
                // treats it as an active battle and the next World fight then
                // remains permanently blocked.
                if (token == worldChainContinueToken)
                    worldChainContinueCoroutine = null;
                yield break;
            }
            worldChainContinueCoroutine = null;
            worldBattleRuntime.PendingResult = false;
            worldBattleRuntime.PendingStars = 0;
            worldBattleWorldPresenter?.Hide();
            EnsureWorldPresenter();
            services.World.SelectStage(nextStageId);
            bool background = !CanShowWorldBattleUi();
            if (!background)
            {
                worldPresenter.ShowStages();
                // 客户端走位：播跑步动画 + 镜头平滑跟随，2 秒走到下一个目标点后才请求战斗
                // （原版 FuBenDetailUI:ModelMove → ModelMove 完成回调里才发挑战）
                yield return worldPresenter.PlayStageWalk(nextStageId, WorldChainWalkSeconds);
            }
            else
            {
                // 后台战斗不能跳过原有节奏，也不能把章节地图重新显示出来。
                // 保留同等等待时间后再发起下一场，避免退出即瞬间结算/连战。
                yield return new WaitForSecondsRealtime(WorldChainWalkSeconds);
            }
            if (token != worldChainContinueToken || battlePlaybackContext != BattlePlaybackContext.World)
                yield break;
            // Lua 已确认这是本章普通关胜利，并请求顺序续战；失败重试由 op=28 单独处理。
            worldBattleInFlight = true;
            InvokeLuaOrFail(onWorldContinueChain, "World.ContinueChain");
        }

        public void CancelWorldChain()
        {
            if (worldChainContinueCoroutine != null)
            {
                worldChainContinueToken++;
                StopCoroutine(worldChainContinueCoroutine);
                worldChainContinueCoroutine = null;
            }
            worldPresenter?.ReleaseStageWalkHold();
            worldPresenter?.EndChainStage();
            InvokeLuaOrFail(onWorldCancelChain, "World.CancelChain");
        }

        public void ApplyWorldSweep(double stageId, int count)
        {
            services.World.ApplySweep(checked((uint)stageId), checked((byte)count));
            SetStatus($"World/320 sweep: stage={checked((uint)stageId)}, count={count}.");
        }

        public void BeginWorldSweepRewards(int sweepCount)
        {
            pendingWorldSweepGroups.Clear();
            for (int index = 0; index < sweepCount; index++)
                pendingWorldSweepGroups.Add(new List<RewardRecord>());
        }

        public void AddWorldSweepReward(int sweepIndex, int type, double id, double amount,
            string name, int picture, int quality)
        {
            int index = sweepIndex - 1;
            if (index < 0 || index >= pendingWorldSweepGroups.Count)
                throw new InvalidOperationException($"World sweep reward group is out of range: {sweepIndex}/{pendingWorldSweepGroups.Count}.");
            pendingWorldSweepGroups[index].Add(new RewardRecord(type, checked((uint)id), checked((uint)amount),
                name, picture, quality));
        }

        public void ShowWorldSweepResult(int sweepCount)
        {
            services.Rewards.Replace("扫荡结算", pendingRewards);
            EnsureWorldOutcomePresenter();
            worldOutcomePresenter.ShowSweep(sweepCount, pendingWorldSweepGroups);
            SetStatus($"World sweep result active: {services.Rewards.Count} rewards.");
        }

        public void ShowWorldBattleResult(int stars)
        {
            battlePlaybackContext = BattlePlaybackContext.World;
            services.Rewards.Replace("关卡结算", pendingRewards);
            if (worldBattlePlaybackCoroutine != null || worldBattleWorldPresenter?.IsVisible == true)
            {
                worldBattleRuntime.PendingResult = true;
                worldBattleRuntime.PendingStars = stars;
                SetStatus($"World authoritative result queued until /38 playback completes: stars={stars}, rewards={services.Rewards.Count}.");
                return;
            }
            ShowWorldBattleResultNow(stars, BattlePlaybackContext.World);
        }

        private bool CanShowWorldBattleUi()
        {
            return !worldBattleBackgrounded && IsWorldOpen
                && !IsMonopolyOpen && !IsFengShenStoryOpen
                && (worldPresenter?.IsCurrentChapterView == true || worldBattleForegroundRequested);
        }

        private bool worldBattleForegroundRequested;

        private void HandleWorldChallengeRequest()
        {
            bool hasBattle = worldBattleInFlight
                || worldBattlePlaybackCoroutine != null
                || worldBattleRuntime.PendingResult;
            if (hasBattle)
            {
                worldBattleBackgrounded = false;
                worldBattleForegroundRequested = true;
                worldBattlePlaybackPresenter?.SetVisible(true);
                SetStatus("World challenge clicked while a battle is active; resumed the existing battle.");
                return;
            }
            worldBattleForegroundRequested = true;
            worldBattleInFlight = true;
            InvokeLuaOrFail(onWorldChallenge, "World.Challenge");
        }

        private void BackgroundWorldBattle()
        {
            worldBattleBackgrounded = true;
            worldBattleForegroundRequested = false;
            if (worldChainAutoSettlementCoroutine != null)
            {
                worldChainAutoSettlementToken++;
                StopCoroutine(worldChainAutoSettlementCoroutine);
                worldChainAutoSettlementCoroutine = null;
            }
            worldBattlePlaybackPresenter?.Hide();
            worldBattleResultView?.SetVisible(false);
            worldBattleStatisticsView?.SetVisible(false);
            worldSweepView?.SetVisible(false);
            SetStatus("World battle presentation moved to background after leaving the current chapter.");
        }

        private IEnumerator AutoContinueWorldChainSettlement(BattlePlaybackContext context, int token)
        {
            yield return new WaitForSecondsRealtime(WorldChainAutoSettlementSeconds);
            if (token != worldChainAutoSettlementToken || battlePlaybackContext != context)
            {
                // A page transition or another battle owner may invalidate
                // this delayed settlement. Clear only our own token's handle;
                // never erase a newer auto-settlement coroutine.
                if (token == worldChainAutoSettlementToken)
                    worldChainAutoSettlementCoroutine = null;
                yield break;
            }
            worldChainAutoSettlementCoroutine = null;
            if (worldOutcomePresenter?.IsBattleVisible == true)
            {
                SetStatus("World chain auto settlement: closing result after 2 seconds.");
                worldOutcomePresenter.InvokeContinue();
            }
        }

        public void ApplyWorldReset(double stageId, int usedResets, int cost)
        {
            services.World.ApplyReset(checked((uint)stageId), checked((byte)usedResets));
            SetStatus($"World/320 reset: stage={checked((uint)stageId)}, used={usedResets}, cost={cost}.");
        }

        private void ShowWorldBattleStatisticsUnavailable()
        {
            EnsureErrorPresenter();
            errorPresenter.Show("战斗统计不可用", "当前 /320 结算包未下发逐单位战报，不能以本地假数据填充。");
        }

        private void ShowWorldBattleReviveUnavailable()
        {
            EnsureErrorPresenter();
            errorPresenter.Show("复活不可用", "当前世界副本 /320 未定义复活请求，不能以本地扣费或假结果代替。");
        }

        public void ApplyWorldBoxClaim(double chapterId, double boxId)
        {
            services.World.ApplyClaimedBox(checked((uint)chapterId), checked((uint)boxId));
            SetStatus($"World/320 box claimed: chapter={checked((uint)chapterId)}, box={checked((uint)boxId)}.");
        }

        private void ShowWorldResetConfirmation(WorldStageRecord stage)
        {
            if (stage == null) return;
            if (stage.RemainingAttempts > 0) { SetWorldError("还有挑战次数，暂不能重置。"); return; }
            if (stage.RemainingResets == 0) { SetWorldError("今日重置次数已用尽。"); return; }
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation("提示",
                $"您是否要花费{stage.ResetCost}元宝重置关卡\n<color=#ff2a20>今日还可重置{stage.RemainingResets}次</color>",
                () =>
                {
                    if (services.Options.WorldBattleValidation) MarkValidationControl("WORLD-17-RESET-CONFIRM");
                    InvokeLuaOrFail(onWorldReset, "World.Reset", (double)stage.Id);
                }, "确认", "取消", true);
        }

        public void SetWorldError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureWorldMapAndContinue() => StartCoroutine(CaptureWorldMap());
        public void CaptureWorldDetailAndChallenge() => StartCoroutine(CaptureWorldDetail());
        public void CaptureWorldBattleAndRefresh(int rewardCount) => StartCoroutine(CaptureWorldBattleResult(rewardCount));

        public void CompleteWorldBattleValidation(double expectedStageId, int expectedRewardCount)
        {
            EnsureWorldPresenter();
            EnsureWorldOutcomePresenter();
            uint stageId = checked((uint)expectedStageId);
            int visibleRewardCount = services.Rewards.Count;
            WorldStageRecord stage = services.World.Stages.FirstOrDefault(value => value.Id == stageId);
            if (!services.Options.WorldBattleValidation)
            {
                SetStatus($"World settlement closed: stage={stageId}, stars={stage?.Stars ?? 0}, rewards={visibleRewardCount}.");
                return;
            }
            if (GetLocalUserId() == 1 || !IsWorldOpen || stage == null || stage.Stars == 0 || stage.Stars == byte.MaxValue
                || services.World.ChapterCount == 0 || services.World.StageCount == 0
                || worldPresenter.RenderedRewardCount == 0 || visibleRewardCount <= 0)
            {
                Fail($"World final state mismatch: user={GetLocalUserId()}, open={IsWorldOpen}, chapter={services.World.ChapterCount}, stages={services.World.StageCount}, stage={stageId}, stars={stage?.Stars ?? 255}, fought={stage?.FoughtCount ?? 0}, rewards={visibleRewardCount}/{worldPresenter.RenderedRewardCount}.");
                return;
            }
            if (!worldG4PrimarySettled)
            {
                worldG4PrimarySettled = true;
                worldG4StageId = stageId;
                worldG4ChapterId = services.World.SelectedChapterId;
                worldG4RewardCount = visibleRewardCount;
                RecordValidationSemantic("world-authority", true,
                    $"/320 op=1/2/27 stage={stageId} and op=8 visible rewards={visibleRewardCount}");
                RecordValidationSemantic("world-battle", true,
                    $"authoritative stage={stageId} settled with stars={stage.Stars}");
                StartCoroutine(ValidateWorldReconnect());
                return;
            }
            if (!worldG4ReconnectVerified)
            {
                if (stageId != worldG4StageId || stage.Stars == 0 || visibleRewardCount != worldG4RewardCount)
                {
                    Fail($"World reconnect persistence mismatch: stage={stageId}/{worldG4StageId}, stars={stage.Stars}, rewards={visibleRewardCount}/{worldG4RewardCount}.");
                    return;
                }
                worldG4ReconnectVerified = true;
                RecordValidationSemantic("world-reconnect", true,
                    $"reloaded stage={stageId} stars={stage.Stars} rewards={visibleRewardCount}");
                StartCoroutine(ValidateWorldAccountIsolation());
                return;
            }
            Fail("World validation received an unexpected extra persistence completion.");
        }

        private IEnumerator ValidateWorldReconnect()
        {
            // The result "continue" action has just requested the authoritative
            // world refresh. Do not sever its response mid-dispatch: a stale
            // chapter callback would otherwise send a stage query after the
            // deliberate disconnect.
            float settleDeadline = Time.realtimeSinceStartup + 5f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < settleDeadline)
                yield return null;
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.ProtocolRegistry.PendingCount != 0)
            {
                Fail("World reconnect could not reach a quiescent protocol state before disconnect.");
                yield break;
            }
            services.Network.Disconnect();
            HandleDisconnected("World G4 deliberate disconnect");
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected || services.World.ChapterCount != 0
                || services.World.StageCount != 0 || IsWorldOpen)
            {
                Fail($"World reconnect cleanup mismatch: network={services.Network.State}, chapters={services.World.ChapterCount}, stages={services.World.StageCount}, open={IsWorldOpen}.");
                yield break;
            }
            Reconnect();
            float deadline = Time.realtimeSinceStartup + 20f;
            while ((services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main)
            {
                Fail("World reconnect timed out.");
                yield break;
            }
            ShowWorld();
            InvokeLuaOrFail(onWorldRefresh, "World.ReconnectRefresh");
        }

        private IEnumerator ValidateWorldAccountIsolation()
        {
            uint isolationUserId = services.Options.WorldIsolationUserId;
            if (isolationUserId == 0 || isolationUserId == GetLocalUserId())
            {
                Fail("World validation requires a distinct -projectXWorldIsolationUserId.");
                yield break;
            }
            services.Config.LocalUserId = isolationUserId;
            ReturnToLogin();
            yield return new WaitForSecondsRealtime(0.25f);
            if (!IsLoginVisible || services.World.ChapterCount != 0 || services.World.StageCount != 0)
            {
                Fail($"World account-switch cleanup mismatch: login={IsLoginVisible}, chapters={services.World.ChapterCount}, stages={services.World.StageCount}.");
                yield break;
            }
            Reconnect();
            float deadline = Time.realtimeSinceStartup + 20f;
            while ((services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || GetLocalUserId() != isolationUserId)
            {
                Fail($"World alternate-account login failed: expected={isolationUserId}, actual={GetLocalUserId()}.");
                yield break;
            }
            ShowWorld();
            InvokeLuaOrFail(onWorldValidateIsolation, "World.AccountIsolation");
        }

        public void CompleteWorldAccountIsolationValidation(double chapterId, double stageId, int stars)
        {
            if (!services.Options.WorldBattleValidation || services.Options.WorldIsolationUserId == 0
                || GetLocalUserId() != services.Options.WorldIsolationUserId
                || (checked((uint)chapterId) == worldG4ChapterId && checked((uint)stageId) == worldG4StageId) || stars != 0)
            {
                Fail($"World alternate-account isolation mismatch: user={GetLocalUserId()}, chapter={chapterId}, stage={stageId}/{worldG4StageId}, stars={stars}.");
                return;
            }
            RecordValidationSemantic("world-account-isolation", true,
                $"alternate user={GetLocalUserId()} stage={stageId} has stars={stars}");
            Complete($"COMPLETE: /320 world -> chapter/stage state -> detail/formation/reward preview -> PvE stage {worldG4StageId} -> op=8 settlement -> reconnect persistence -> alternate account {GetLocalUserId()} isolation.");
        }
    }
}
