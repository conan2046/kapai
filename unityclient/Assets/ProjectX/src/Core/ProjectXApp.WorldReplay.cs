using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private void BeginWorldBattlePlayback()
        {
            EnsureWorldBattlePlaybackPresenter();
            WorldBattlePlaybackPresenter playbackPresenter = ActiveBattlePlaybackPresenter;
            if (battlePlaybackContext == BattlePlaybackContext.Monopoly)
            {
                // The shared replay presenter survives between guard fights;
                // SkipRequested is valid only for this newly loaded replay.
                playbackPresenter.ResetSkipRequest();
            }
            // Current Cocos suppresses HUD chat and transient system broadcasts
            // for the whole fight/result stack. A queued login broadcast used to
            // float above the imported FightLayer in Unity.
            chatMiniView?.SetVisible(false);
            toastPresenter?.Clear();
            if (ActiveBattlePlaybackCoroutine != null) StopCoroutine(ActiveBattlePlaybackCoroutine);
            GetBattlePlaybackRuntime(battlePlaybackContext).SuppressSettlementForSkippedPlayback = false;
            // 龙崖模式 2：BOSS 结算经 ShowWorldBattleResult 排队（pending=true）后，
            // /38 回放可能晚到并触发本函数；此处不得冲掉已排队的结算，否则 BOSS 结算丢失。
            // Preserve a result already queued for this same battle context.
            Coroutine playbackCoroutine = StartCoroutine(PlayWorldBattleReplay());
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory) fengShenBattlePlaybackCoroutine = playbackCoroutine;
            else if (battlePlaybackContext == BattlePlaybackContext.Monopoly) monopolyBattlePlaybackCoroutine = playbackCoroutine;
            else worldBattlePlaybackCoroutine = playbackCoroutine;
        }

        private IEnumerator PlayWorldBattleReplay()
        {
            BattlePlaybackContext battlePlaybackContext = this.battlePlaybackContext;
            BattlePlaybackRuntimeState runtime = GetBattlePlaybackRuntime(battlePlaybackContext);
            WorldBattlePlaybackPresenter worldBattlePlaybackPresenter = battlePlaybackContext switch
            {
                BattlePlaybackContext.FengShenStory => fengShenBattlePlaybackPresenter,
                BattlePlaybackContext.Monopoly => monopolyBattlePlaybackPresenter,
                _ => worldBattleWorldPresenter
            };
            WorldBattleReplayStore replay = battlePlaybackContext switch
            {
                BattlePlaybackContext.FengShenStory => services.FengShenBattleReplay,
                BattlePlaybackContext.Monopoly => services.MonopolyBattleReplay,
                _ => services.WorldBattleReplay
            };
            bool captureFengShenStory = services.Options.BattleFengShenStoryValidation
                && battlePlaybackContext == BattlePlaybackContext.FengShenStory;
            bool backgroundAtStart = battlePlaybackContext == BattlePlaybackContext.World
                && !CanShowWorldBattleUi();
            worldBattlePlaybackPresenter.Show(!backgroundAtStart);
            Debug.LogWarning($"[ProjectX][WorldBattle] ReplayStarted context={battlePlaybackContext} fight={replay.FightId} actions={replay.Actions.Count} skip={worldBattlePlaybackPresenter.SkipRequested}");
            if (backgroundAtStart)
                SetStatus("World battle replay running in background; authoritative action timing is preserved.");
            foreach (WorldBattleUnitRecord unit in replay.Units)
                ProjectX.Diagnostics.ClientLog.Verbose($"WORLD_BATTLE_UNIT_DATA position={unit.Position} type={unit.Type} picture={unit.Picture} "
                    + $"quality={unit.Quality} scale={unit.ScaleRatio:0.##} state={unit.State} buffs={string.Join(",", unit.BuffIds)}");
            if (services.Options.WorldBattleValidation)
            {
                MarkValidationControl("WORLD-28-BATTLE-PLAYBACK-ENTER");
                if (replay.Units.Count > 0)
                    MarkValidationControl("WORLD-29-BATTLE-UNIT-IDENTITY");
            }
            if (captureFengShenStory)
            {
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-START.png"));
            }
            string playbackOwner = battlePlaybackContext == BattlePlaybackContext.FengShenStory ? "FengShenStory"
                : battlePlaybackContext == BattlePlaybackContext.Monopoly ? "Monopoly" : "World";
            SetStatus($"{playbackOwner} authoritative /38 replay active: fight={replay.FightId}, units={replay.Units.Count}, actionGroups={replay.Actions.Count}.");
            float battleStartElapsed = 0f;
            while (battleStartElapsed < 1.12f)
            {
                battleStartElapsed += Time.unscaledDeltaTime;
                worldBattlePlaybackPresenter.SetBattleStartElapsed(battleStartElapsed);
                yield return null;
            }
            // WORLD-BATTLE-ENTRY is paired with the frozen Cocos standing frame,
            // not its transient zhandoukaishi overlay. Capture only after the
            // authoritative 1.1-second start effect has fully cleared and before
            // the first /22 action begins.
            if (services.Options.WorldBattleValidation)
            {
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-entry.png"));
            }
            if (captureFengShenStory)
            {
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-STAND.png"));
            }
            // Small local-test fights may contain only one to three authoritative
            // action groups.  Playing every group at the old fixed 0.78 seconds
            // made the complete battle disappear behind the packet/scene refresh
            // and look like a direct jump to settlement.  Preserve every /22
            // action while guaranteeing a readable action phase at normal speed;
            // the explicit x3 control still accelerates it.
            float normalActionDuration = Mathf.Max(1.35f, 4.2f / Mathf.Max(1, replay.Actions.Count));
            int actionIndex = 0;
            bool shakeFrameCaptured = false;
            bool normalAttackFrameCaptured = false;
            bool skillFrameCaptured = false;
            bool hurtDamageFrameCaptured = false;
            bool deathFrameCaptured = false;
            int stableDeathCaptureRound = 0;
            HashSet<int> stableDeadPositions = new HashSet<int>();
            bool roundRhythmFrameCaptured = false;
            bool fengMoveFrameCaptured = false;
            bool fengSkillFrameCaptured = false;
            bool fengDamageFrameCaptured = false;
            bool fengStatusFrameCaptured = false;
            bool fengDeathFrameCaptured = false;
            bool preservePassiveDamage = false;
            foreach (WorldBattleActionRecord action in replay.Actions)
            {
                actionIndex++;
                if (worldBattlePlaybackPresenter.SkipRequested)
                {
                    Debug.LogWarning($"[ProjectX][WorldBattle] ReplayInterruptedBeforeAction index={actionIndex} skip=true");
                    break;
                }
                bool passiveAction = action.FirstActionType == 6;
                if (!passiveAction && preservePassiveDamage)
                    yield return new WaitForSecondsRealtime(.5f
                        / Mathf.Max(1f, worldBattlePlaybackPresenter.PlaybackSpeed));
                bool actionHasPassiveCarry = preservePassiveDamage;
                worldBattlePlaybackPresenter.BeginAction(action, actionHasPassiveCarry);
                preservePassiveDamage = false;
                ProjectX.Diagnostics.ClientLog.Verbose($"WORLD_BATTLE_PRESENTATION sequence={action.Sequence} {worldBattlePlaybackPresenter.LastActionTrace}");
                string actionTargets = string.Join(",", action.Targets.Select(value =>
                    $"{value.Position}:hit={value.Hit}:crit={value.Critical}:damage={value.Damage}:healing={value.Healing}:state={value.State}:dead={value.Dead}:buffs=[{string.Join("/", value.BuffIds)}]"));
                ProjectX.Diagnostics.ClientLog.Verbose($"WORLD_BATTLE_ACTION_DATA sequence={action.Sequence} round={action.Round} "
                    + $"type={action.FirstActionType} source={action.FirstSourcePosition} skill={action.SkillId} "
                    + $"sourceState={action.SourceState} sourceBuffs=[{string.Join("/", action.SourceBuffIds)}] targets={actionTargets}");
                if (services.Options.WorldBattleValidation)
                    MarkValidationControl("WORLD-30-BATTLE-ACTION-SEQUENCE");
                // The current native Cocos death reference is a stable sw pose:
                // the following round is already visible, two defeated units
                // remain on the field, and impact damage/skill markers are gone.
                // Capture before advancing the first action of that next round;
                // an impact-time capture would compare a different lifecycle.
                if (services.Options.WorldBattleValidation && !deathFrameCaptured
                    && stableDeathCaptureRound > 0 && action.Round >= stableDeathCaptureRound)
                {
                    deathFrameCaptured = true;
                    yield return new WaitForEndOfFrame();
                    ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-death.png"));
                }
                if (captureFengShenStory && !fengDeathFrameCaptured
                    && stableDeathCaptureRound > 0 && action.Round >= stableDeathCaptureRound)
                {
                    fengDeathFrameCaptured = true;
                    yield return new WaitForEndOfFrame();
                    ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-DEATH.png"));
                }
                if (services.Options.WorldBattleValidation && !roundRhythmFrameCaptured)
                {
                    roundRhythmFrameCaptured = true;
                    yield return new WaitForEndOfFrame();
                    ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-round-rhythm.png"));
                }
                if (passiveAction)
                {
                    // LBattleLogic:ActionStart collapses consecutive BAT_PASSIVE
                    // records, applies them immediately, and carries only the
                    // maximum 0.5 second wait into the next visible action.
                    float stablePassiveProgress = Mathf.Min(1f,
                        worldBattlePlaybackPresenter.ImpactProgress + .12f
                        / Mathf.Max(.01f, worldBattlePlaybackPresenter.RecommendedActionDurationSeconds));
                    worldBattlePlaybackPresenter.SetActionProgress(stablePassiveProgress);
                    worldBattlePlaybackPresenter.EndAction(preserveDamage: true);
                    preservePassiveDamage = true;
                    continue;
                }
                float configuredDuration = worldBattlePlaybackPresenter.RecommendedActionDurationSeconds;
                float actionDuration = Mathf.Max(normalActionDuration, configuredDuration)
                    / Mathf.Max(1f, worldBattlePlaybackPresenter.PlaybackSpeed);
                bool canonicalLightningSkill = action.SkillId == 191;
                bool skillAction = action.SkillId > 0 || action.FirstActionType == 2 || action.FirstActionType == 3;
                float actionCaptureProgress = canonicalLightningSkill
                    ? worldBattlePlaybackPresenter.RecommendedSkillCaptureProgress
                    : Mathf.Clamp(worldBattlePlaybackPresenter.ImpactProgress + .02f, .45f, .96f);
                float elapsed = 0f;
                bool actionFrameCaptured = false;
                while (elapsed < actionDuration && !worldBattlePlaybackPresenter.SkipRequested)
                {
                    elapsed += Time.unscaledDeltaTime;
                    float progress = elapsed / actionDuration;
                    worldBattlePlaybackPresenter.SetActionProgress(progress);
                    if (captureFengShenStory && !fengMoveFrameCaptured && action.FirstActionType == 1 && progress >= .25f)
                    {
                        fengMoveFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-MOVE.png"));
                    }
                    if (captureFengShenStory && !fengSkillFrameCaptured && skillAction && progress >= actionCaptureProgress)
                    {
                        fengSkillFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-SKILL.png"));
                    }
                    if (services.Options.WorldBattleValidation && !shakeFrameCaptured
                        && worldBattlePlaybackPresenter.IsCameraShaking)
                    {
                        shakeFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath($"world-battle-shake-{actionIndex:D2}.png"));
                    }
                    if (services.Options.WorldBattleValidation && !actionFrameCaptured
                        && progress >= actionCaptureProgress)
                    {
                        actionFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        string actionKind = action.SkillId > 0 || action.FirstActionType == 2 || action.FirstActionType == 3
                            ? "skill"
                            : "normal";
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath($"world-battle-{actionKind}-{actionIndex:D2}.png"));
                    }
                    if (services.Options.WorldBattleValidation && progress >= actionCaptureProgress
                        && canonicalLightningSkill && !skillFrameCaptured)
                    {
                        skillFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-skill.png"));
                    }
                    float normalAttackCaptureProgress = actionHasPassiveCarry ? .12f : actionCaptureProgress;
                    if (services.Options.WorldBattleValidation && progress >= normalAttackCaptureProgress
                        && !skillAction && action.FirstActionType == 1 && !normalAttackFrameCaptured)
                    {
                        normalAttackFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-normal-attack.png"));
                    }
                    // Computer Use captures the current Cocos damage state after
                    // its scale-in has settled. Capture the Unity comparison at
                    // the same stable post-impact phase, while the overlapping
                    // skill effect is still visible.
                    bool impactState = progress >= Mathf.Min(0.98f, worldBattlePlaybackPresenter.ImpactProgress + .22f);
                    if (captureFengShenStory && impactState && !fengDamageFrameCaptured
                        && action.Targets.Any(value => value.Hit && (value.Damage > 0 || value.Healing > 0)))
                    {
                        fengDamageFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-DAMAGE.png"));
                    }
                    if (captureFengShenStory && impactState && !fengStatusFrameCaptured
                        && (action.SourceBuffIds.Length > 0 || action.Targets.Any(value => value.BuffIds.Length > 0)))
                    {
                        fengStatusFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-STATUS.png"));
                    }
                    if (services.Options.WorldBattleValidation && impactState && canonicalLightningSkill
                        && !hurtDamageFrameCaptured
                        && action.Targets.Any(value => value.Hit && (value.Damage > 0 || value.Healing > 0)))
                    {
                        hurtDamageFrameCaptured = true;
                        yield return new WaitForEndOfFrame();
                        ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-hurt-damage.png"));
                    }
                    yield return null;
                }
                worldBattlePlaybackPresenter.EndAction();
                if (action.SourceDead)
                    stableDeadPositions.Add(action.FirstSourcePosition);
                foreach (WorldBattleTargetRecord target in action.Targets.Where(value => value.Dead))
                    stableDeadPositions.Add(target.Position);
                if (!deathFrameCaptured && stableDeadPositions.Count >= (captureFengShenStory ? 1 : 2))
                    stableDeathCaptureRound = Mathf.Max(stableDeathCaptureRound, action.Round + 1);
                if (worldBattlePlaybackPresenter.SkipRequested)
                {
                    Debug.LogWarning($"[ProjectX][WorldBattle] ReplayInterruptedAfterAction index={actionIndex} skip=true");
                    break;
                }
                yield return new WaitForSecondsRealtime(.18f
                    / Mathf.Max(1f, worldBattlePlaybackPresenter.PlaybackSpeed));
            }
            if (preservePassiveDamage && !worldBattlePlaybackPresenter.SkipRequested)
                yield return new WaitForSecondsRealtime(.5f
                    / Mathf.Max(1f, worldBattlePlaybackPresenter.PlaybackSpeed));
            // The current LieZhuan fixture resolves every action in round one.
            // There is therefore no next-round action on which the generic
            // stable-death capture can trigger. Preserve the final sw pose for
            // one readable frame before opening settlement.
            if (captureFengShenStory && !fengDeathFrameCaptured
                && stableDeadPositions.Count > 0 && !worldBattlePlaybackPresenter.SkipRequested)
            {
                yield return new WaitForSecondsRealtime(.35f
                    / Mathf.Max(1f, worldBattlePlaybackPresenter.PlaybackSpeed));
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-DEATH.png"));
                fengDeathFrameCaptured = true;
            }
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory
                && worldBattlePlaybackPresenter.SkipRequested)
            {
                // Only an explicit skip returns straight to the parent map.
                // Natural completion continues below into the authoritative
                // op10 settlement lifecycle.
                runtime.SuppressSettlementForSkippedPlayback = true;
                runtime.PendingResult = false;
                runtime.PendingStars = 0;
                deferredFengShenRewardPush = false;
                services.FengShenStory.AcknowledgeRewardPush();
                worldBattleResultView?.SetVisible(false);
                worldBattleStatisticsView?.SetVisible(false);
                worldBattlePlaybackPresenter.Hide();
                ClearBattlePlaybackCoroutine(battlePlaybackContext);
                InvokeLuaOrFail(onFengShenStoryClicked, "FengShenStory.BattleDirectReturn");
                SetStatus("FengShenStory fightType=19 returned directly to the parent map without Unity settlement.");
                if (captureFengShenStory)
                {
                    yield return new WaitForEndOfFrame();
                    // Keep the natural settlement return (which owns the op26
                    // reward popup) distinct from the explicit-skip return.
                    // Reusing BFS-BATTLE-RETURN here overwrote the G5 state with
                    // the product-correct skip-without-settlement map frame.
                    ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("BFS-BATTLE-SKIP-RETURN.png"));
                }
                yield break;
            }
            if (battlePlaybackContext == BattlePlaybackContext.World && !CanShowWorldBattleUi())
            {
                worldBattlePlaybackPresenter.Hide();
                ClearBattlePlaybackCoroutine(battlePlaybackContext);
                if (battlePlaybackContext != BattlePlaybackContext.Monopoly && runtime.PendingResult)
                {
                    int stars = runtime.PendingStars;
                    runtime.PendingResult = false;
                    ShowWorldBattleResultNow(stars, battlePlaybackContext);
                }
                yield break;
            }
            worldBattlePlaybackPresenter.ShowOutcome();
            Debug.LogWarning($"[ProjectX][WorldBattle] ReplayOutcome context={battlePlaybackContext} skip={worldBattlePlaybackPresenter.SkipRequested}");
            if (services.Options.WorldBattleValidation)
            {
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-outcome.png"));
            }
            yield return new WaitForSecondsRealtime(.72f);
            // Current Cocos keeps the completed battle scene, units and HUD
            // beneath zhandoujiesuanLayer. Hide only when no settlement is
            // queued; Continue/Replay performs the eventual lifecycle cleanup.
            if (battlePlaybackContext != BattlePlaybackContext.Monopoly && !runtime.PendingResult)
                worldBattlePlaybackPresenter.Hide();
            ClearBattlePlaybackCoroutine(battlePlaybackContext);
            if (battlePlaybackContext == BattlePlaybackContext.Monopoly)
            {
                CompleteMonopolyBattlePlayback();
                yield break;
            }
            if (battlePlaybackContext != BattlePlaybackContext.Monopoly && runtime.PendingResult)
            {
                int stars = runtime.PendingStars;
                runtime.PendingResult = false;
                if (services.Options.WorldBattleValidation)
                    MarkValidationControl("WORLD-31-BATTLE-TO-SETTLEMENT");
                ShowWorldBattleResultNow(stars, battlePlaybackContext);
            }
        }

        private void ReturnFromWorldBattleReplayControl()
        {
            BattlePlaybackContext context = battlePlaybackContext;
            GetBattlePlaybackRuntime(context).PendingResult = false;
                GetBattlePlaybackPresenter(context)?.Hide();
                EnsureWorldPresenter();
            worldPresenter.ShowStages();
            SetStatus("World replay control entered the current Cocos transient chapter-map state.");
            StartCoroutine(ReplayWorldBattleAfterCocosDelay(context));
        }

        private void ContinueBattleOutcomeControl()
        {
            if (worldChainAutoSettlementCoroutine != null)
            {
                worldChainAutoSettlementToken++;
                StopCoroutine(worldChainAutoSettlementCoroutine);
                worldChainAutoSettlementCoroutine = null;
            }
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory)
            {
                // FirstFightResultUI sends ExitBattle before closing its result
                // layer. The imported result presenter hides itself, but the
                // sibling playback overlay must leave the stack here as well.
                // Otherwise the deferred reward modal covers a still-live fight
                // and closing that modal reveals the completed battlefield.
                fengShenBattleRuntime.PendingResult = false;
                fengShenBattlePlaybackPresenter?.Hide();
                InvokeLuaOrFail(onFengShenStoryClicked, "FengShenStory.Continue");
                if (deferredFengShenRewardPush)
                    StartCoroutine(PresentDeferredFengShenRewardPushAfterReturn());
                return;
            }
            // FirstFightResultUI exits the completed fight before it refreshes
            // the chapter map.  The settlement view hides itself, but its
            // sibling playback overlay otherwise remains above the refreshed
            // World UI and leaves the player looking at a dead battlefield.
            worldBattleRuntime.PendingResult = false;
            worldBattleWorldPresenter?.Hide();
            // 本章内逐关续战由 Lua 在存在下一关时处理；结算层区分 Boss 胜利与失败。
            if (worldChainMode && worldChainNextStageId != 0)
            {
                // 失败时服务端下发本章第一关作为 nextNodeId；自动挑战未勾选时停止，
                // 不能因为 CheckBox_2 勾选就把普通关失败误判成 Boss 胜利并切下一章。
                worldPresenter?.ShowChapterPage();
                StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
                SetStatus("World chain stopped after defeat: returned to chapter page.");
            }
            else if (worldChainMode && worldChainAutoNext)
            {
                // nextNodeId == 0 表示本章 Boss 胜利；此时才允许「自动挑战下一章」切章。
                uint nextChapter = services.World.CurrentChapterId;
                bool hasChapter = nextChapter > 0 && services.World.Chapters.Any(value => value.Id == nextChapter);
                if (hasChapter)
                {
                    pendingAutoNextChapter = nextChapter;
                    RememberLastWorldChapter(nextChapter);
                    InvokeLuaOrFail(onWorldRequestChapter, "World.RequestChapter", (double)nextChapter);
                    SetStatus($"World chain auto next chapter: requesting {nextChapter}.");
                }
                else
                {
                    pendingAutoNextChapter = 0;
                    SetStatus("World chain auto next chapter: no further chapter, staying put.");
                }
            }
            else if (worldChainMode && worldChainAuto)
            {
                // Boss 胜利、只勾「自动挑战」：从本章第一关重新开始，不切下一章。
                worldPresenter?.BeginChainStage();
                worldBattleInFlight = true;
                InvokeLuaOrFail(onWorldRestartChain, "World.RestartChain");
                SetStatus("World chain auto challenge: restarting current chapter.");
            }
            else if (!worldChainMode)
            {
                // 类型 1：保持原刷新行为（结算确认 → op=1 刷新章节状态）
                InvokeLuaOrFail(onWorldRefresh, "World.Continue");
            }
            else
            {
                // 类型 2 未勾任何自动：返回章节选择页。
                // 不能只调用 ShowStages() 停在大底图，否则 WorldMapNewLayer 根节点虽在，
                // chapterPage 的 btn_1..5 / Button_1 / Button_2 会因 showChapters=false 被隐藏。
                worldPresenter?.ShowChapterPage();
                StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
                SetStatus("World chain stopped after settlement: returned to chapter page.");
            }
        }

        private IEnumerator PresentDeferredFengShenRewardPushAfterReturn()
        {
            yield return new WaitForEndOfFrame();
            if (deferredFengShenRewardPush && IsFengShenStoryOpen
                && fengShenBattlePlaybackCoroutine == null
                && monopolyBattlePlaybackCoroutine == null
                && worldBattlePlaybackCoroutine == null)
                PresentFengShenRewardPush();
        }

        private void ReplayBattleOutcomeControl()
        {
            BattlePlaybackContext context = battlePlaybackContext;
            if (context == BattlePlaybackContext.FengShenStory)
            {
                fengShenBattleRuntime.PendingResult = false;
                fengShenBattlePlaybackPresenter?.Hide();
                EnsureFengShenStoryPresenter();
                SetStatus("FengShenStory replay control entered the current Cocos transient parent state.");
                StartCoroutine(ReplayWorldBattleAfterCocosDelay(context));
                return;
            }
            ReturnFromWorldBattleReplayControl();
        }

        private IEnumerator ReplayWorldBattleAfterCocosDelay(BattlePlaybackContext context)
        {
            // FirstFightResultUI:OnBtnReplayClick closes immediately, then calls
            // ReplayBattle(true) after 0.5 seconds.  Current native evidence for
            // stage 10023 proves the transient map, replay and second settlement.
            yield return new WaitForSecondsRealtime(.5f);
            if (battlePlaybackContext != context)
            {
                SetStatus($"Discarded stale {context} replay request after the active battle context changed to {battlePlaybackContext}.");
                yield break;
            }
            BeginWorldBattlePlayback();
            // BeginWorldBattlePlayback clears any result queued for the previous
            // run. Queue the cached authoritative result only after that reset so
            // this replay reaches its own second settlement.
            GetBattlePlaybackRuntime(context).PendingResult = true;
            SetStatus($"{(context == BattlePlaybackContext.FengShenStory ? "FengShenStory" : "World")} cached authoritative /38 replay restarted after the current Cocos 0.5-second delay.");
        }

    }
}

