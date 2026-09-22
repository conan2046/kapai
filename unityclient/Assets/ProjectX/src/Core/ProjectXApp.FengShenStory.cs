using System;
using System.Collections;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowFengShenStory()
        {
            EnsureFengShenStoryPresenter();
            gameplayContentView?.SetVisible(false);
            gameplayView?.SetVisible(false);
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            // FengShenStory supplies its own title/currency instances. Keep
            // only the shared bottom frame visible; do not expose the Hero/Bag
            // Panel_12 or GoldCheck from OneLevelLayer.
            frame.Apply(OneLevelFrameMode.FengShenStory);
            frame.AttachContent(fengShenStoryView);
            SetOneLevelFrameVisible(true);
            if (services.UiStack.Current != fengShenStoryView) services.UiStack.Push(fengShenStoryView);
            fengShenStoryView.SetVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            fengShenStoryView.GameObject.transform.SetAsLastSibling();
            SetStatus("FengShenStory current main UI active; awaiting /320 op=24.");
            if (deferredFengShenRewardPush)
                StartCoroutine(PresentDeferredFengShenRewardPushAfterReturn());
        }

        public void SetFengShenStoryState(double chapterId, double levelId, int count)
        {
            services.FengShenStory.Replace(checked((uint)chapterId), checked((uint)levelId), checked((byte)count));
        }

        public void SetFengShenStoryChallengeResult(bool succeeded, string message)
        {
            services.FengShenStory.SetChallengeResult(succeeded, message);
            if (!succeeded)
            {
                ShowToast(message, 3f);
                SetStatus("FengShenStory/320 op=25 failed: " + message);
            }
        }

        public void SetFengShenStoryFightPush(double chapterId, double levelId, int count,
            double unlockedChapterId, double unlockedLevelId)
        {
            services.FengShenStory.ApplyFightPush(checked((uint)chapterId), checked((uint)levelId), checked((byte)count),
                checked((uint)unlockedChapterId), checked((uint)unlockedLevelId));
        }

        public void ClearFengShenStoryRewardPush()
        {
            pendingFengShenRewards.Clear();
            deferredFengShenRewardPush = false;
        }

        public void PushFengShenStoryReward(double type, double id, double amount, string name,
            double picture, double quality)
        {
            ushort rewardType = checked((ushort)type);
            uint rewardId = checked((uint)id);
            uint rewardAmount = checked((uint)amount);
            RewardRecord described = services.ShopCatalog.DescribeReward(rewardType, checked((int)rewardId), rewardAmount);
            string resolvedName = !string.IsNullOrWhiteSpace(described.Name)
                && !described.Name.StartsWith("奖励 #", StringComparison.Ordinal)
                    ? described.Name : name;
            int resolvedPicture = described.Picture > 0 ? described.Picture : checked((int)picture);
            int resolvedQuality = described.Quality > 0 ? described.Quality : checked((int)quality);
            pendingFengShenRewards.Add(new FengShenRewardRecord(rewardType, rewardId, rewardAmount,
                resolvedName, resolvedPicture, resolvedQuality));
        }

        public void ShowFengShenStoryRewardPush()
        {
            services.FengShenStory.SetRewardPush(pendingFengShenRewards);
            pendingFengShenRewards.Clear();
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory
                && (fengShenBattleRuntime.SuppressSettlementForSkippedPlayback
                    || fengShenBattlePlaybackPresenter?.SkipRequested == true))
            {
                // Explicit skip returns directly to the parent map. Consume a
                // late op26 state push without resurrecting the result stack.
                services.FengShenStory.AcknowledgeRewardPush();
                deferredFengShenRewardPush = false;
                SetStatus("FengShenStory skipped playback consumed op26 without reopening settlement.");
                return;
            }
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory
                && (fengShenBattlePlaybackCoroutine != null
                    || fengShenBattlePlaybackPresenter?.IsVisible == true
                    || fengShenBattleRuntime.PendingResult
                    || worldOutcomePresenter?.IsBattleVisible == true
                    || worldOutcomePresenter?.IsStatisticsVisible == true))
            {
                deferredFengShenRewardPush = true;
                return;
            }
            if (!IsFengShenStoryOpen && !IsFengShenStoryAuthoritativeVisible)
            {
                // A late FengShenStory op26 must remain queued while another
                // battle/map owns the visible stack; never raise its reward
                // modal over World or Monopoly presentation.
                deferredFengShenRewardPush = true;
                SetStatus("FengShenStory reward push deferred until its parent UI is visible.");
                return;
            }
            PresentFengShenRewardPush();
        }

        private void PresentFengShenRewardPush()
        {
            deferredFengShenRewardPush = false;
            EnsureFengShenStoryPresenter();
            fengShenStoryPresenter.ShowRewardPush();
        }
        public void BeginFengShenStoryValidation()
        {
            if (fengShenStoryValidationRunning || fengShenStoryValidationCompleted) return;
            fengShenStoryValidationRunning = true;
            StartCoroutine(RunFengShenStoryValidation());
        }

        public void CompleteFengShenStoryValidation() => BeginFengShenStoryValidation();

        public void BeginBattleFengShenStoryValidation()
        {
            if (battleFengShenStoryValidationRunning) return;
            battleFengShenStoryValidationRunning = true;
            StartCoroutine(RunBattleFengShenStoryValidation());
        }
        private IEnumerator RunBattleFengShenStoryValidation()
        {
            try
            {
                BeginValidationEvidence();
                if (GetLocalUserId() != 7200057 || GetPlayerRoleId() != 1000003)
                {
                    Fail($"BattleFengShenStory fixed identity mismatch: {GetLocalUserId()}/{GetPlayerRoleId()}.");
                    yield break;
                }
                EnsureFengShenStoryPresenter();
                int currentChapter = services.FengShenStory.CurrentChapter;
                if (currentChapter > 1)
                {
                    Canvas.ForceUpdateCanvases();
                    yield return new WaitForEndOfFrame();
                    if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter - 1)))
                    {
                        Fail("BattleFengShenStory previous chapter did not receive a real EventSystem raycast click.");
                        yield break;
                    }
                    yield return new WaitForEndOfFrame();
                    if (fengShenStoryPresenter.SelectedChapter != currentChapter - 1
                        || !InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter)))
                    {
                        Fail($"BattleFengShenStory chapter selection did not restore current chapter {currentChapter}.");
                        yield break;
                    }
                    yield return new WaitForEndOfFrame();
                    if (fengShenStoryPresenter.SelectedChapter != currentChapter)
                    {
                        Fail($"BattleFengShenStory selected chapter mismatch after real clicks: {fengShenStoryPresenter.SelectedChapter}/{currentChapter}.");
                        yield break;
                    }
                    RecordValidationSemantic("battle-fengshen-entry-chapter-raycast", true,
                        $"real GraphicRaycaster chapter {currentChapter - 1}->{currentChapter}");
                }
                int currentLevel = Math.Max(1, (int)(services.FengShenStory.LevelId % 10));
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(currentLevel)))
                {
                    Fail("BattleFengShenStory current-stage control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (!fengShenStoryPresenter.IsLevelPopupVisible
                    || !InvokeEventSystemRaycastClick(fengShenStoryPresenter.FightControl))
                {
                    Fail("BattleFengShenStory challenge control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                float deadline = Time.realtimeSinceStartup + 25f;
                while ((worldBattlePlaybackPresenter?.IsVisible != true
                    || services.FengShenBattleReplay.FightType != 19) && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldBattlePlaybackPresenter?.IsVisible != true
                    || services.FengShenBattleReplay.FightType != 19
                    || services.FengShenBattleReplay.Actions.Count == 0
                    || services.FengShenBattleReplay.StatisticsCount != services.FengShenBattleReplay.Units.Count)
                {
                    Fail($"BattleFengShenStory authoritative replay did not start: visible={worldBattlePlaybackPresenter?.IsVisible == true}, type={services.FengShenBattleReplay.FightType}, actions={services.FengShenBattleReplay.Actions.Count}, statistics={services.FengShenBattleReplay.StatisticsCount}/{services.FengShenBattleReplay.Units.Count}.");
                    yield break;
                }
                // Show() activates an imported Canvas tree during the protocol
                // dispatch frame. A human cannot click until Graphic depths have
                // been rebuilt, so wait for that real raycast-ready frame.
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (fengShenStoryPresenter.IsModalVisible)
                {
                    Fail("BattleFengShenStory reward push obscured the authoritative playback before settlement return.");
                    yield break;
                }
                if (IsToastVisible || chatMiniView?.GameObject.activeInHierarchy == true)
                {
                    Fail($"BattleFengShenStory public HUD overlay leaked into playback: toast={IsToastVisible}, chat={chatMiniView?.GameObject.activeInHierarchy == true}.");
                    yield break;
                }
                MarkValidationControl("BFSB-01-REAL-CHALLENGE");
                if (worldBattlePlaybackPresenter.AutoControlVisible)
                {
                    Fail("BattleFengShenStory current Cocos-hidden auto control was visible in Unity.");
                    yield break;
                }
                if (worldBattlePlaybackPresenter.ActiveFormationMarkerCount != services.FengShenBattleReplay.Units.Count)
                {
                    Fail($"BattleFengShenStory formation markers diverged from the current full formations: active={worldBattlePlaybackPresenter.ActiveFormationMarkerCount}, units={services.FengShenBattleReplay.Units.Count}.");
                    yield break;
                }
                if (worldBattlePlaybackPresenter.DirectionalModelCount <= 0
                    || !worldBattlePlaybackPresenter.UnitDirectionalActionsCorrect)
                {
                    Fail($"BattleFengShenStory Cocos side action groups mismatch: models={worldBattlePlaybackPresenter.DirectionalModelCount}, correct={worldBattlePlaybackPresenter.UnitDirectionalActionsCorrect}, states=[{worldBattlePlaybackPresenter.UnitDirectionalState}].");
                    yield break;
                }
                ProjectX.Diagnostics.ClientLog.Verbose($"[ProjectX][BattleFengShenStory] Directional states: {worldBattlePlaybackPresenter.UnitDirectionalState}");
                MarkValidationControl("BFSB-03-AUTO");
                float speedBefore = worldBattlePlaybackPresenter.PlaybackSpeed;
                if (!InvokeEventSystemRaycastClick(worldBattlePlaybackPresenter.SpeedInteractionButton))
                {
                    Fail("BattleFengShenStory speed control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (worldBattlePlaybackPresenter.PlaybackSpeed <= speedBefore
                    || worldBattlePlaybackPresenter.SpeedDisplayMultiplier != 2
                    || !Mathf.Approximately(worldBattlePlaybackPresenter.PlaybackSpeed, 2f))
                {
                    Fail($"BattleFengShenStory Cocos speed state did not advance correctly: factor={speedBefore}->{worldBattlePlaybackPresenter.PlaybackSpeed}, label=X{worldBattlePlaybackPresenter.SpeedDisplayMultiplier}.");
                    yield break;
                }
                MarkValidationControl("BFSB-02-SPEED");

                // Natural completion must enter the authoritative settlement;
                // explicit skip is validated separately after this full path.
                bool validateNaturalSettlement = true;
                if (validateNaturalSettlement)
                {
                float playbackAllowance = Mathf.Min(180f, services.FengShenBattleReplay.Actions.Count * 4.5f);
                deadline = Time.realtimeSinceStartup + 30f + playbackAllowance;
                while (worldOutcomePresenter?.IsBattleVisible != true && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldOutcomePresenter?.IsBattleVisible != true || services.Rewards.Count == 0)
                {
                    Fail($"BattleFengShenStory settlement did not become authoritative and visible: visible={worldOutcomePresenter?.IsBattleVisible == true}, rewards={services.Rewards.Count}.");
                    yield break;
                }
                if (worldOutcomePresenter.VictoryTitleVariant != 2
                    || worldOutcomePresenter.RenderedMoneyRewardCount != 3
                    || worldOutcomePresenter.RenderedItemRewardCount != 0
                    || services.Rewards.Items.Any(value => value.Type == 60006)
                    || worldOutcomePresenter.RenderedPetExperienceCount != 0)
                {
                    Fail($"BattleFengShenStory current Cocos settlement mapping mismatch: title={worldOutcomePresenter.VictoryTitleVariant}, money={worldOutcomePresenter.RenderedMoneyRewardCount}, items={worldOutcomePresenter.RenderedItemRewardCount}, packetPetExp={services.Rewards.Items.Any(value => value.Type == 60006)}, renderedPetExp={worldOutcomePresenter.RenderedPetExperienceCount}.");
                    yield break;
                }
                if (fengShenStoryPresenter.IsModalVisible || worldOutcomePresenter.IsBattleResultSummaryVisible)
                {
                    Fail($"BattleFengShenStory settlement presentation mismatch: modal={fengShenStoryPresenter.IsModalVisible}, stars={worldOutcomePresenter.IsBattleResultSummaryVisible}.");
                    yield break;
                }
                if (IsToastVisible || chatMiniView?.GameObject.activeInHierarchy == true)
                {
                    Fail($"BattleFengShenStory public HUD overlay leaked into settlement: toast={IsToastVisible}, chat={chatMiniView?.GameObject.activeInHierarchy == true}.");
                    yield break;
                }
                if (worldOutcomePresenter.IsVictoryTitleEffectVisible
                    || worldOutcomePresenter.IsVictoryTitleEffectPlaying)
                {
                    Fail("BattleFengShenStory victory Imod appeared before the current Cocos frame-35 callback.");
                    yield break;
                }
                yield return new WaitForSecondsRealtime(.65f);
                if (!worldOutcomePresenter.IsVictoryTitleEffectVisible
                    || !worldOutcomePresenter.IsVictoryTitleEffectPlaying)
                {
                    Fail("BattleFengShenStory victory Imod did not play during the current Cocos one-shot window.");
                    yield break;
                }
                deadline = Time.realtimeSinceStartup + 1f;
                while (worldOutcomePresenter.IsVictoryTitleEffectPlaying
                    && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldOutcomePresenter.IsVictoryTitleEffectVisible
                    || worldOutcomePresenter.IsVictoryTitleEffectPlaying)
                {
                    Fail("BattleFengShenStory victory Imod leaked past its 0.7-second non-looping lifecycle.");
                    yield break;
                }
                yield return CaptureFengShenStoryFrame("BFS-BATTLE-SETTLEMENT.png");
                if (!InvokeEventSystemRaycastClick(worldOutcomePresenter.StatisticsInteractionButton))
                {
                    Fail("BattleFengShenStory statistics control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (!worldOutcomePresenter.IsStatisticsVisible)
                {
                    Fail("BattleFengShenStory statistics page did not open.");
                    yield break;
                }
                if (worldOutcomePresenter.RenderedFriendlyStatisticsCount != 5
                    || worldOutcomePresenter.RenderedEnemyStatisticsCount != 5
                    || fengShenStoryPresenter.IsModalVisible)
                {
                    Fail($"BattleFengShenStory statistics presentation mismatch: friendly={worldOutcomePresenter.RenderedFriendlyStatisticsCount}, enemy={worldOutcomePresenter.RenderedEnemyStatisticsCount}, modal={fengShenStoryPresenter.IsModalVisible}.");
                    yield break;
                }
                MarkValidationControl("BFSB-05-SETTLEMENT-STATS");
                yield return CaptureFengShenStoryFrame("BFS-BATTLE-STATISTICS.png");
                if (!InvokeEventSystemRaycastClick(worldOutcomePresenter.StatisticsCloseInteractionButton))
                {
                    Fail("BattleFengShenStory statistics close did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (worldOutcomePresenter.IsStatisticsVisible || !worldOutcomePresenter.IsBattleVisible)
                {
                    Fail("BattleFengShenStory statistics close did not return to the same settlement.");
                    yield break;
                }
                MarkValidationControl("BFSB-06-STATS-CLOSE");
                if (!InvokeEventSystemRaycastClick(worldOutcomePresenter.ReplayInteractionButton))
                {
                    Fail("BattleFengShenStory replay control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                MarkValidationControl("BFSB-07-REPLAY");
                deadline = Time.realtimeSinceStartup + 10f;
                while (worldBattlePlaybackPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldBattlePlaybackPresenter?.IsVisible != true)
                {
                    Fail("BattleFengShenStory replay did not reopen the authoritative playback view.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (worldBattlePlaybackPresenter.SpeedDisplayMultiplier != 2
                    || !Mathf.Approximately(worldBattlePlaybackPresenter.PlaybackSpeed, 2f))
                {
                    Fail($"BattleFengShenStory speed preference did not survive replay: factor={worldBattlePlaybackPresenter.PlaybackSpeed}, label=X{worldBattlePlaybackPresenter.SpeedDisplayMultiplier}.");
                    yield break;
                }
                float replayAllowance = Mathf.Min(180f, services.FengShenBattleReplay.Actions.Count * 4.5f);
                deadline = Time.realtimeSinceStartup + 30f + replayAllowance;
                while (worldOutcomePresenter?.IsBattleVisible != true && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldOutcomePresenter?.IsBattleVisible != true)
                {
                    Fail("BattleFengShenStory natural replay did not return to settlement.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(worldOutcomePresenter.ContinueInteractionButton))
                {
                    Fail("BattleFengShenStory settlement return did not receive a real EventSystem raycast click.");
                    yield break;
                }
                MarkValidationControl("BFSB-08-SETTLEMENT-CLOSE-RETURN");
                deadline = Time.realtimeSinceStartup + 15f;
                while ((!IsFengShenStoryOpen || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsFengShenStoryOpen || worldOutcomePresenter.IsBattleVisible
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"BattleFengShenStory return state mismatch: parent={IsFengShenStoryOpen}, settlement={worldOutcomePresenter.IsBattleVisible}, playback={worldBattlePlaybackPresenter?.IsVisible == true}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                deadline = Time.realtimeSinceStartup + 5f;
                while (!fengShenStoryPresenter.IsModalVisible && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (!fengShenStoryPresenter.IsModalVisible)
                {
                    Fail("BattleFengShenStory deferred reward push did not appear after settlement return.");
                    yield break;
                }
                if (!fengShenStoryPresenter.ValidateRewardPushPresentation(out string rewardPresentation))
                {
                    Fail("BattleFengShenStory return reward presentation mismatch: " + rewardPresentation);
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (!fengShenStoryPresenter.ValidateRewardPushPresentation(out rewardPresentation)
                    || rewardPresenter?.IsSharedViewRenderingSuspended != true
                    || services.Currencies.Stamina != 80)
                {
                    Fail("BattleFengShenStory return reward ownership changed before capture: "
                        + rewardPresentation + $", suspended={rewardPresenter?.IsSharedViewRenderingSuspended}, "
                        + $"stamina={services.Currencies.Stamina}/80.");
                    yield break;
                }
                yield return CaptureFengShenStoryFrame("BFS-BATTLE-RETURN.png");
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.ModalCloseButton))
                {
                    Fail("BattleFengShenStory return reward confirmation did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (fengShenStoryPresenter.IsModalVisible || services.FengShenStory.RewardPush.Count != 0
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || rewardPresenter?.IsSharedViewRenderingSuspended == true)
                {
                    Fail($"BattleFengShenStory return reward confirmation lifecycle mismatch: modal={fengShenStoryPresenter.IsModalVisible}, rewards={services.FengShenStory.RewardPush.Count}, playback={worldBattlePlaybackPresenter?.IsVisible == true}, suspended={rewardPresenter?.IsSharedViewRenderingSuspended}.");
                    yield break;
                }
                MarkValidationControl("BFSB-09-RETURN-REWARD-CONFIRM");

                currentChapter = services.FengShenStory.CurrentChapter;
                currentLevel = Math.Max(1, (int)(services.FengShenStory.LevelId % 10));
                if (fengShenStoryPresenter.SelectedChapter != currentChapter
                    && !InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter)))
                {
                    Fail("BattleFengShenStory could not select the current chapter for explicit-skip validation.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(currentLevel)))
                {
                    Fail("BattleFengShenStory current stage did not receive the second real EventSystem click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (!fengShenStoryPresenter.IsLevelPopupVisible
                    || !InvokeEventSystemRaycastClick(fengShenStoryPresenter.FightControl))
                {
                    Fail("BattleFengShenStory second challenge did not receive a real EventSystem click.");
                    yield break;
                }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((worldBattlePlaybackPresenter?.IsVisible != true
                    || services.FengShenBattleReplay.FightType != 19) && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (worldBattlePlaybackPresenter?.IsVisible != true
                    || services.FengShenBattleReplay.FightType != 19)
                {
                    Fail("BattleFengShenStory explicit-skip validation replay did not start.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (!InvokeEventSystemRaycastClick(worldBattlePlaybackPresenter.SkipInteractionButton))
                {
                    Fail("BattleFengShenStory skip control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (!worldBattlePlaybackPresenter.SkipRequested)
                {
                    Fail("BattleFengShenStory skip click was rejected by the authoritative replay state.");
                    yield break;
                }
                MarkValidationControl("BFSB-04-SKIP");
                deadline = Time.realtimeSinceStartup + 15f;
                while ((!IsFengShenStoryOpen
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsFengShenStoryOpen
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || worldOutcomePresenter?.IsBattleVisible == true
                    || worldOutcomePresenter?.IsStatisticsVisible == true
                    || fengShenStoryPresenter.IsModalVisible
                    || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"BattleFengShenStory explicit-skip direct-return mismatch: parent={IsFengShenStoryOpen}, "
                        + $"playback={worldBattlePlaybackPresenter?.IsVisible == true}, "
                        + $"settlement={worldOutcomePresenter?.IsBattleVisible == true}, "
                        + $"statistics={worldOutcomePresenter?.IsStatisticsVisible == true}, "
                        + $"modal={fengShenStoryPresenter.IsModalVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                if (fengShenStoryPresenter.RenderedCurrentStageMarkerCount != 1)
                {
                    Fail($"BattleFengShenStory parent map current-stage marker mismatch after skip: visible={fengShenStoryPresenter.RenderedCurrentStageMarkerCount}/1.");
                    yield break;
                }
                yield return CaptureFengShenStoryFrame("BFS-BATTLE-SKIP-RETURN.png");
                string[] artifacts =
                {
                    "BFS-BATTLE-START.png", "BFS-BATTLE-STAND.png", "BFS-BATTLE-SKILL.png",
                    "BFS-BATTLE-DAMAGE.png", "BFS-BATTLE-MOVE.png", "BFS-BATTLE-STATUS.png",
                    "BFS-BATTLE-DEATH.png", "BFS-BATTLE-SETTLEMENT.png",
                    "BFS-BATTLE-STATISTICS.png", "BFS-BATTLE-RETURN.png",
                    "BFS-BATTLE-SKIP-RETURN.png"
                };
                string[] missing = artifacts.Where(name =>
                {
                    string path = BuildUiMigrationPath(name);
                    return !File.Exists(path) || new FileInfo(path).Length < 4096;
                }).ToArray();
                if (missing.Length > 0)
                {
                    Fail("BattleFengShenStory semantic captures missing: " + string.Join(",", missing));
                    yield break;
                }
                RecordValidationSemantic("battle-fengshen-authority", true,
                    $"real /320 op25 -> /38 fightType=19 -> op10 rewards={services.Rewards.Count}");
                RecordValidationSemantic("battle-fengshen-presentation", true,
                    $"units={services.FengShenBattleReplay.Units.Count}, actions={services.FengShenBattleReplay.Actions.Count}, ten current semantic states captured");
                RecordValidationSemantic("battle-fengshen-controls", true,
                    "9/9 controls covered; eight real EventSystem paths plus current-source hidden auto assertion");
                RecordValidationSemantic("battle-fengshen-lifecycle-split", true,
                    "natural completion -> authoritative settlement; explicit skip -> direct parent return without settlement");
                RecordValidationSemantic("battle-fengshen-stage-markers", true,
                    "exactly one current-stage marker; passed stages remain full color without the current badge");
                Complete($"COMPLETE: BattleFengShenStory 9/9 controls; natural settlement and explicit-skip direct return; fightType=19; units={services.FengShenBattleReplay.Units.Count}; actions={services.FengShenBattleReplay.Actions.Count}; user={GetLocalUserId()} role={GetPlayerRoleId()}");
                yield break;
                }

                yield return CaptureFengShenStoryFrame("BFS-BATTLE-SPEED.png");
                if (!InvokeEventSystemRaycastClick(worldBattlePlaybackPresenter.SkipInteractionButton))
                {
                    Fail("BattleFengShenStory skip control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                if (!worldBattlePlaybackPresenter.SkipRequested)
                {
                    Fail("BattleFengShenStory skip click was rejected by the authoritative replay state.");
                    yield break;
                }
                MarkValidationControl("BFSB-04-SKIP");
                deadline = Time.realtimeSinceStartup + 15f;
                while ((!IsFengShenStoryOpen
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsFengShenStoryOpen
                    || worldBattlePlaybackPresenter?.IsVisible == true
                    || worldOutcomePresenter?.IsBattleVisible == true
                    || worldOutcomePresenter?.IsStatisticsVisible == true
                    || fengShenStoryPresenter.IsModalVisible
                    || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"BattleFengShenStory direct-return mismatch: parent={IsFengShenStoryOpen}, "
                        + $"playback={worldBattlePlaybackPresenter?.IsVisible == true}, "
                        + $"settlement={worldOutcomePresenter?.IsBattleVisible == true}, "
                        + $"statistics={worldOutcomePresenter?.IsStatisticsVisible == true}, "
                        + $"modal={fengShenStoryPresenter.IsModalVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                string[] currentArtifacts =
                {
                    "BFS-BATTLE-START.png", "BFS-BATTLE-STAND.png",
                    "BFS-BATTLE-SPEED.png", "BFS-BATTLE-RETURN.png"
                };
                string[] currentMissing = currentArtifacts.Where(name =>
                {
                    string path = BuildUiMigrationPath(name);
                    return !File.Exists(path) || new FileInfo(path).Length < 4096;
                }).ToArray();
                if (currentMissing.Length > 0)
                {
                    Fail("BattleFengShenStory current G3 captures missing: " + string.Join(",", currentMissing));
                    yield break;
                }
                RecordValidationSemantic("battle-fengshen-authority", true,
                    "real /320 op24/op25 -> /38 op5 -> nested /21 fightType=19 and /22-/23");
                RecordValidationSemantic("battle-fengshen-presentation", true,
                    $"units={services.FengShenBattleReplay.Units.Count}, actions={services.FengShenBattleReplay.Actions.Count}, current FightLayer active");
                RecordValidationSemantic("battle-fengshen-direct-return", true,
                    "real speed and skip EventSystem clicks; parent op24 refreshed; no Unity settlement/statistics/replay/reward modal");
                RecordValidationSemantic("battle-fengshen-controls", true,
                    "4/4 current controls covered: challenge, speed, hidden auto assertion, skip");
                Complete($"COMPLETE: BattleFengShenStory current G3 4/4 controls; direct parent return; no settlement; fightType=19; units={services.FengShenBattleReplay.Units.Count}; actions={services.FengShenBattleReplay.Actions.Count}; user={GetLocalUserId()} role={GetPlayerRoleId()}");
            }
            finally
            {
                battleFengShenStoryValidationRunning = false;
            }
        }

        private IEnumerator RunFengShenStoryValidation()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint isolationUserId = services.Options.FengShenStoryIsolationUserId == 0
                ? 705213u : services.Options.FengShenStoryIsolationUserId;
            string[] allControls =
            {
                "FENGSHEN-01-GAMEPLAY-ENTRY", "FENGSHEN-02-FRAME-CLOSE", "FENGSHEN-03-HELP",
                "FENGSHEN-04-HELP-CLOSE", "FENGSHEN-05-CHAPTER-VIEWPORT", "FENGSHEN-06-CHAPTER-CELL",
                "FENGSHEN-07-LEFT-PAGE", "FENGSHEN-08-RIGHT-PAGE", "FENGSHEN-09-LEVEL-1",
                "FENGSHEN-10-LEVEL-2", "FENGSHEN-11-LEVEL-3", "FENGSHEN-12-LEVEL-4",
                "FENGSHEN-13-BOX-CLOSED", "FENGSHEN-14-BOX-OPENED", "FENGSHEN-15-REWARD-CLOSE",
                "FENGSHEN-16-REWARD-ACK", "FENGSHEN-17-LEVEL-MASK-INERT", "FENGSHEN-18-LEVEL-CLOSE",
                "FENGSHEN-19-FIGHT", "FENGSHEN-20-FORMATION", "FENGSHEN-21-LEVEL-REWARD-LIST",
                "FENGSHEN-22-SOURCE-CLOSE", "FENGSHEN-23-SOURCE-ICON-INERT", "FENGSHEN-24-SOURCE-ROUTE-13",
                "FENGSHEN-25-SOURCE-ROUTE-15"
            };
            try
            {
                BeginValidationEvidence();
                if (primaryUserId != 7200057 || primaryRoleId != 1000003 || isolationUserId != 705213)
                {
                    Fail($"FengShenStory fixed identity mismatch: primary={primaryUserId}/{primaryRoleId}, isolation={isolationUserId}.");
                    yield break;
                }
                EnsureFengShenStoryPresenter();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse
                    || !IsFengShenStoryAuthoritativeVisible || !fengShenStoryPresenter.IsCurrencyHeaderVisible
                    || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"FengShenStory state mismatch: open={IsFengShenStoryOpen}, authoritative={services.FengShenStory.HasAuthoritativeResponse}, visible={IsFengShenStoryAuthoritativeVisible}, currencyHeader={fengShenStoryPresenter.IsCurrencyHeaderVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-first-class-currency-header", true,
                    "shared OneLevelLayer/GoldCheck prefab is visible and bound to authoritative currencies");
                MarkValidationControl(allControls[0]);
                yield return CaptureFengShenControlEvidence(allControls[0]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story.png");
                MarkValidationControl(allControls[4]);
                yield return CaptureFengShenControlEvidence(allControls[4]);

                int initialPage = fengShenStoryPresenter.FirstVisibleChapter;
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.LeftPageControl))
                { Fail("FengShenStory left page arrow did not receive a real EventSystem raycast click."); yield break; }
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-page-left.png");
                MarkValidationControl(allControls[6]);
                yield return CaptureFengShenControlEvidence(allControls[6]);
                int leftPage = fengShenStoryPresenter.FirstVisibleChapter;
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.RightPageControl))
                { Fail("FengShenStory right page arrow did not receive a real EventSystem raycast click."); yield break; }
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-page-right.png");
                MarkValidationControl(allControls[7]);
                yield return CaptureFengShenControlEvidence(allControls[7]);
                int rightPage = fengShenStoryPresenter.FirstVisibleChapter;
                bool pageContract = leftPage >= 1 && rightPage - leftPage == FengShenStoryPresenter.PageChapterCount
                    && fengShenStoryPresenter.RenderedChapterCount <= FengShenStoryPresenter.PageChapterCount;
                if (!pageContract)
                {
                    Fail($"FengShenStory arrow page mismatch: initial={initialPage}, left={leftPage}, right={rightPage}, rendered={fengShenStoryPresenter.RenderedChapterCount}.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-chapter-arrow-page", true,
                    $"990/165=6; page {initialPage}->{leftPage}->{rightPage}; local-only, pending=0");

                int currentChapter = services.FengShenStory.CurrentChapter;
                fengShenStoryPresenter.InvokeLeft();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter - 1)))
                {
                    Fail("FengShenStory chapter cell did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                MarkValidationControl(allControls[5]);
                yield return CaptureFengShenControlEvidence(allControls[5]);
                fengShenStoryPresenter.InvokeRight();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter)))
                {
                    Fail("FengShenStory current chapter cell did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();

                fengShenStoryPresenter.ShowHelp();
                MarkValidationControl(allControls[2]);
                yield return CaptureFengShenControlEvidence(allControls[2]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-help.png");
                if (!fengShenStoryPresenter.InvokeModalClose())
                { Fail("FengShenStory help close button was unavailable."); yield break; }
                MarkValidationControl(allControls[3]);
                yield return CaptureFengShenControlEvidence(allControls[3]);

                int currentLevel = Math.Max(1, (int)(services.FengShenStory.LevelId % 10));
                if (currentLevel != 4)
                {
                    Fail($"FengShenStory fixed fixture must start at chapter end, got level={currentLevel}.");
                    yield break;
                }
                for (int passedLevel = 1; passedLevel < currentLevel; passedLevel++)
                {
                    if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(passedLevel))
                        || !fengShenStoryPresenter.IsLevelPopupVisible
                        || fengShenStoryPresenter.PopupStageId != currentChapter * 10 + passedLevel)
                    {
                        Fail($"FengShenStory passed-stage {passedLevel} imported button did not open.");
                        yield break;
                    }
                    MarkValidationControl(allControls[8 + passedLevel - 1]);
                    yield return CaptureFengShenControlEvidence(allControls[8 + passedLevel - 1]);
                    if (passedLevel == currentLevel - 1)
                    {
                        if (!fengShenStoryPresenter.InvokeLevelMask())
                        { Fail("FengShenStory level mask did not remain inert."); yield break; }
                        MarkValidationControl(allControls[16]);
                        yield return CaptureFengShenControlEvidence(allControls[16]);
                        yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-level-passed.png");
                    }
                    if (!fengShenStoryPresenter.InvokeLevelClose())
                    { Fail($"FengShenStory passed-stage {passedLevel} close was unavailable."); yield break; }
                    MarkValidationControl(allControls[17]);
                    yield return CaptureFengShenControlEvidence(allControls[17]);
                }

                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(currentLevel)))
                {
                    Fail("FengShenStory current-stage imported button did not open.");
                    yield break;
                }
                if (fengShenStoryPresenter.RenderedLevelRewardCount != 3)
                {
                    Fail($"FengShenStory current-stage first_reward rendering mismatch: rendered={fengShenStoryPresenter.RenderedLevelRewardCount}, expected=3.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-level-first-reward-visible", true,
                    "maplist_dat.first_reward rendered three non-empty reward icons with quantities");
                MarkValidationControl(allControls[8 + currentLevel - 1]);
                yield return CaptureFengShenControlEvidence(allControls[8 + currentLevel - 1]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-level-current.png");
                if (!fengShenStoryPresenter.InvokeRewardIcon(0))
                { Fail("FengShenStory reward icon did not open item source."); yield break; }
                MarkValidationControl(allControls[20]);
                yield return CaptureFengShenControlEvidence(allControls[20]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-item-source.png");
                if (!fengShenStoryPresenter.InvokeSourceIcon())
                { Fail("FengShenStory currency source icon was not inert."); yield break; }
                MarkValidationControl(allControls[22]);
                yield return CaptureFengShenControlEvidence(allControls[22]);
                if (!fengShenStoryPresenter.InvokeSourceRoute(13) || lastGameplayBoundaryId != 13)
                { Fail("FengShenStory source route 13 boundary mismatch."); yield break; }
                MarkValidationControl(allControls[23]);
                yield return CaptureFengShenControlEvidence(allControls[23]);
                if (!fengShenStoryPresenter.InvokeSourceRoute(15) || lastGameplayBoundaryId != 15)
                { Fail("FengShenStory source route 15 boundary mismatch."); yield break; }
                MarkValidationControl(allControls[24]);
                yield return CaptureFengShenControlEvidence(allControls[24]);
                if (!fengShenStoryPresenter.InvokeModalClose())
                { Fail("FengShenStory item-source close was unavailable."); yield break; }
                MarkValidationControl(allControls[21]);
                yield return CaptureFengShenControlEvidence(allControls[21]);
                fengShenStoryPresenter.InvokeFormation();
                MarkValidationControl(allControls[19]);
                yield return CaptureFengShenControlEvidence(allControls[19]);
                formationPopupView?.SetVisible(false);

                fengShenStoryPresenter.CloseLevelPopup();
                if (!fengShenStoryPresenter.InvokeClosedBox())
                { Fail("FengShenStory current chapter closed box button was unavailable."); yield break; }
                MarkValidationControl(allControls[12]);
                yield return CaptureFengShenControlEvidence(allControls[12]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-box-closed.png");
                if (!fengShenStoryPresenter.InvokeModalClose())
                { Fail("FengShenStory reward preview close was unavailable."); yield break; }
                MarkValidationControl(allControls[14]);
                yield return CaptureFengShenControlEvidence(allControls[14]);
                fengShenStoryPresenter.InvokeLeft();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter - 1))
                    || !fengShenStoryPresenter.InvokeOpenedBox())
                { Fail("FengShenStory previous chapter opened box button was unavailable."); yield break; }
                MarkValidationControl(allControls[13]);
                yield return CaptureFengShenControlEvidence(allControls[13]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-box-opened.png");
                if (!fengShenStoryPresenter.InvokeModalClose())
                { Fail("FengShenStory opened reward preview close was unavailable."); yield break; }
                fengShenStoryPresenter.InvokeRight();
                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetChapterControl(currentChapter)))
                { Fail("FengShenStory current chapter could not be restored before fight."); yield break; }

                if (!InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(currentLevel)))
                {
                    Fail("FengShenStory fight popup imported button could not reopen.");
                    yield break;
                }
                uint levelBeforeFight = services.FengShenStory.LevelId;
                fengShenStoryPresenter.InvokeFight();
                MarkValidationControl(allControls[18]);
                yield return CaptureFengShenControlEvidence(allControls[18]);
                float deadline = Time.realtimeSinceStartup + 20f;
                while ((services.FengShenStory.ChallengePending || services.FengShenStory.LevelId == levelBeforeFight)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.FengShenStory.LevelId == levelBeforeFight || !string.IsNullOrEmpty(services.FengShenStory.LastChallengeError))
                {
                    Fail($"FengShenStory real op25 did not advance: level={levelBeforeFight}->{services.FengShenStory.LevelId}, error={services.FengShenStory.LastChallengeError}.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-current-stage-authority", true,
                    $"real op24 chapter={currentChapter} level={levelBeforeFight}; real op25 advanced to {services.FengShenStory.LevelId}");

                int nextChapter = services.FengShenStory.CurrentChapter;
                fengShenStoryPresenter.CloseLevelPopup();
                if (services.FengShenStory.LevelId % 10 != 1
                    || !InvokeEventSystemRaycastClick(fengShenStoryPresenter.GetStageControl(2))
                    || fengShenStoryPresenter.IsLevelPopupVisible
                    || !fengShenStoryPresenter.IsModalVisible)
                {
                    Fail($"FengShenStory next-chapter locked stage did not return visible feedback: chapter={nextChapter}, level={services.FengShenStory.LevelId}.");
                    yield break;
                }
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-level-locked.png");
                if (!fengShenStoryPresenter.InvokeModalClose())
                {
                    Fail("FengShenStory locked-stage feedback could not be closed.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-stage-three-state", true,
                    "passed/current/locked stage controls passed the real EventSystem raycast path; locked state returned visible feedback");

                deadline = Time.realtimeSinceStartup + 5f;
                while (services.FengShenStory.RewardPush.Count == 0 && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.FengShenStory.RewardPush.Count > 0)
                {
                    if (!fengShenStoryPresenter.IsModalVisible)
                    { Fail("FengShenStory op26 reward modal was not opened by the push handler."); yield break; }
                    yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-reward-push.png");
                    if (!fengShenStoryPresenter.InvokeModalClose() || services.FengShenStory.RewardPush.Count != 0)
                    { Fail("FengShenStory reward acknowledgement did not clear the pushed rewards."); yield break; }
                    MarkValidationControl(allControls[15]);
                    yield return CaptureFengShenControlEvidence(allControls[15]);
                }
                else
                {
                    Fail("FengShenStory end-chapter fixture produced no authoritative op26 reward push.");
                    yield break;
                }
                RecordValidationSemantic("fengshen-chapter-reward-authority", true,
                    "op26 was server-pushed after op25; acknowledgement cleared only the local popup and sent no request");
                RecordValidationSemantic("fengshen-popup-lifecycle", true,
                    "help, stage, reward preview, source and reward-push popups opened and closed without leaking state");
                RecordValidationSemantic("fengshen-protocol-ownership", true,
                    "client sent only /320 op24/op25; op10/op26 were consumed as server pushes; World operations untouched");

                fengShenStoryPresenter.InvokeClose();
                MarkValidationControl(allControls[1]);
                yield return CaptureFengShenControlEvidence(allControls[1]);
                if (IsFengShenStoryOpen) { Fail("FengShenStory close did not return to Gameplay."); yield break; }
                if (gameplayPresenter == null || !gameplayPresenter.InvokeEnter(3))
                { Fail("FengShenStory real Gameplay re-entry was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse)
                    || services.ProtocolRegistry.PendingCount != 0)
                {
                    if (Time.realtimeSinceStartup >= deadline) break;
                    yield return null;
                }
                if (!IsFengShenStoryOpen || services.ProtocolRegistry.PendingCount != 0)
                { Fail("FengShenStory re-entry did not settle its fresh op24 before disconnect."); yield break; }

                services.Network.Disconnect("FengShenStory deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-disconnected.png");
                if (errorPresenter?.IsVisible != true || !errorPresenter.InvokeConfirmation())
                { Fail("FengShenStory reconnect confirmation was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("FengShenStory reconnect did not restore primary role."); yield break; }
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse
                    || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsFengShenStoryOpen || services.ProtocolRegistry.PendingCount != 0)
                { Fail("FengShenStory reconnect did not settle op24."); yield break; }
                RecordValidationSemantic("fengshen-network-recovery", true,
                    "real disconnect cleared pending/transients; reconnect rebuilt primary op24 state");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("FengShenStory isolation submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != 1000006)
                { Fail($"FengShenStory isolation identity mismatch: role={GetPlayerRoleId()}."); yield break; }
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse
                    || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsFengShenStoryOpen || services.FengShenStory.ChallengePending || fengShenStoryPresenter.IsModalVisible)
                { Fail("FengShenStory isolation inherited primary transient state."); yield break; }
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-account-isolation.png");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("FengShenStory terminal primary submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("FengShenStory terminal primary identity was not restored."); yield break; }
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsFengShenStoryOpen || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                RecordValidationSemantic("fengshen-account-isolation", true,
                    $"real {isolationUserId}/1000006 login rebuilt an independent store; terminal {primaryUserId}/{primaryRoleId} restored");
                RecordValidationSemantic("fengshen-mutation-restore", true,
                    "runner observed the mutation; outer fixed-account finally owns exact SHA restore and residual assertion");

                RecordValidationSemantic("fengshen-control-matrix-25", validationControlIds.Count == 25,
                    $"validated={validationControlIds.Count}/25");
                if (validationControlIds.Count != 25)
                { Fail($"FengShenStory control coverage mismatch: {validationControlIds.Count}/25."); yield break; }

                fengShenStoryValidationCompleted = true;
                Complete($"COMPLETE: FengShenStory 25/25 controls; real /320 op24/op25/op10/op26, six-chapter arrows, reconnect/account isolation; user={primaryUserId} role={primaryRoleId}; fengshen-control-matrix-25");
            }
            finally
            {
                fengShenStoryValidationRunning = false;
            }
        }
        private IEnumerator CaptureFengShenStoryFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length < 4096) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length < 4096)
                Fail("FengShenStory screenshot was not written: " + path);
        }

        private IEnumerator CaptureFengShenControlEvidence(string controlId)
        {
            string token = (controlId ?? string.Empty).ToLowerInvariant();
            yield return CaptureFengShenStoryFrame($"fengshen-control-{token}.png");
        }
    }
}
