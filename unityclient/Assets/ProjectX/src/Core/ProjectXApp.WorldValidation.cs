using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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
        private IEnumerator CaptureWorldMap()
        {
            yield return new WaitForSecondsRealtime(1.5f);
            EnsureWorldPresenter();
            if (!IsWorldOpen || services.World.ChapterCount == 0 || services.World.StageCount == 0
                || worldPresenter.RenderedCount != services.World.StageCount)
            {
                Fail($"World map state mismatch: open={IsWorldOpen}, chapters={services.World.ChapterCount}, stages={services.World.StageCount}, rendered={worldPresenter.RenderedCount}.");
                yield break;
            }
            if (services.Options.WorldBattleValidation && !worldG4StageCloseValidated)
            {
                Button stageClose = worldPresenter.FindInteractionButton("Layer/Title/CloseBtn");
                if (stageClose == null || !stageClose.interactable)
                {
                    Fail("World stage-map close control is unavailable.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(stageClose))
                {
                    Fail("World stage-map close did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return null;
                if (!IsWorldOpen || !worldPresenter.ChapterListVisible
                    || worldStageView.GameObject.activeInHierarchy
                    || worldDetailView.GameObject.activeInHierarchy
                    || services.UiStack.Current != worldView)
                {
                    Fail($"World stage-map close did not return to WorldMapNewLayer: open={IsWorldOpen}, chapterList={worldPresenter.ChapterListVisible}, current={services.UiStack.Current?.GameObject?.name ?? string.Empty}, stage={worldStageView.GameObject.activeInHierarchy}, detail={worldDetailView.GameObject.activeInHierarchy}.");
                    yield break;
                }
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-map.png"));
                yield return new WaitForSecondsRealtime(0.75f);
                if (!InvokeEventSystemRaycastClick(stageClose))
                {
                    Fail("WorldMapNewLayer close did not receive a real EventSystem raycast click.");
                    yield break;
                }
                yield return null;
                if (IsWorldOpen || mainView?.GameObject.activeInHierarchy != true
                    || services.UiStack.Current != mainView)
                {
                    Fail($"WorldMapNewLayer close did not return to UImainLayer_new: open={IsWorldOpen}, current={services.UiStack.Current?.GameObject?.name ?? string.Empty}, main={mainView?.GameObject.activeInHierarchy == true}.");
                    yield break;
                }
                worldG4StageCloseValidated = true;
                // Restore the already server-backed stage map solely so this
                // one run can continue to validate the remaining controls.
                ShowWorld();
                worldPresenter.ShowStages();
                yield return new WaitForEndOfFrame();
                worldPresenter.RefreshInteractionButtons();
                yield return new WaitForEndOfFrame();
                if (!worldMapView.GameObject.activeSelf)
                {
                    Fail("World stage-map did not restore after the close-control probe.");
                    yield break;
                }
            }
            if (services.Options.WorldBattleValidation && !ValidateWorldPassiveG4Controls())
                yield break;
            if (services.Options.WorldBattleValidation)
            {
                yield return ValidateWorldStageUtilityControls();
            }
            // G5 must preserve the frozen Cocos battle input. Star/normal box
            // claims are real server mutations and each grants 1000 premium;
            // they belong to the broader G4 control run, not visual capture.
            if (services.Options.WorldBattleValidation && !services.Options.WorldG3Validation
                && !worldG4StarBoxValidated)
            {
                yield return ValidateWorldStarBoxControl();
                if (!worldG4StarBoxValidated) yield break;
            }
            if (services.Options.WorldBattleValidation && !worldG4NormalBoxValidated)
            {
                yield return ValidateWorldNormalBoxControl();
                if (!worldG4NormalBoxValidated) yield break;
            }
            if (!services.Options.WorldG3Validation)
            {
                yield return new WaitForEndOfFrame();
                // This counterpart is deliberately after the real chest claims.
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-chest.png"));
                yield return new WaitForSecondsRealtime(0.75f);
            }
            if (services.Options.WorldBattleValidation)
            {
                yield return ValidateWorldChapterAndStageControls();
                yield break;
            }
            InvokeLuaOrFail(onWorldOpenPreferredStage, "World.OpenPreferredStage");
        }

        private IEnumerator ValidateWorldChapterAndStageControls()
        {
            uint currentChapterId = services.World.SelectedChapterId;
            Button next = worldView.Binding.Find("Layer/Button_2")?.GetComponent<Button>();
            Button previous = worldView.Binding.Find("Layer/Button_1")?.GetComponent<Button>();
            if (next == null || previous == null)
            {
                Fail("World chapter paging controls are unavailable.");
                yield break;
            }
            // Cocos NormalFuBenUI:ShowCurPage / leftEvent / rightEvetn / ChangePage ——
            // Button_1 / Button_2 是章节选择页的**翻页**键（每页 5 章）：首/末页各自隐藏，
            // 点击只改页码、不请求章节，因此这里不能用 SelectedChapterId 变化做断言。
            float deadline = Time.realtimeSinceStartup + 8f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline)
                yield return null;
            int pageCount = worldPresenter.ChapterPageCount;
            if (pageCount < 2)
            {
                Fail($"World chapter paging needs at least two pages, got {pageCount}.");
                yield break;
            }
            int pageBefore = worldPresenter.ChapterPageIndex;
            bool hasPrevious = pageBefore > 0;
            bool hasNext = pageBefore < pageCount - 1;
            if (previous.gameObject.activeInHierarchy != hasPrevious
                || next.gameObject.activeInHierarchy != hasNext)
            {
                Fail($"World chapter paging arrow visibility mismatch at page {pageBefore}/{pageCount}: previous={previous.gameObject.activeInHierarchy} expected={hasPrevious}, next={next.gameObject.activeInHierarchy} expected={hasNext}.");
                yield break;
            }
            Button advance = hasNext ? next : previous;
            Button retreat = hasNext ? previous : next;
            int advancedPage = hasNext ? pageBefore + 1 : pageBefore - 1;
            if (!advance.gameObject.activeInHierarchy || !advance.interactable
                || !InvokeEventSystemRaycastClick(advance))
            {
                Fail($"World {(hasNext ? "next" : "previous")} chapter page control did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            if (worldPresenter.ChapterPageIndex != advancedPage
                || services.World.SelectedChapterId != currentChapterId
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"World chapter page turn was not client-side: page={worldPresenter.ChapterPageIndex} expected={advancedPage}, selected={services.World.SelectedChapterId}/{currentChapterId}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            if (!retreat.gameObject.activeInHierarchy || !retreat.interactable
                || !InvokeEventSystemRaycastClick(retreat))
            {
                Fail($"World {(hasNext ? "previous" : "next")} chapter page control did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            if (worldPresenter.ChapterPageIndex != pageBefore
                || services.World.SelectedChapterId != currentChapterId)
            {
                Fail($"World chapter page control did not restore page {pageBefore}: page={worldPresenter.ChapterPageIndex}, selected={services.World.SelectedChapterId}/{currentChapterId}.");
                yield break;
            }
            // DadituuiLayer CloseBtn owns only the stage-map -> world-map step.
            Button returnToWorldMap = worldPresenter.FindInteractionButton("Layer/Title/CloseBtn");
            if (returnToWorldMap == null || !returnToWorldMap.interactable
                || !InvokeEventSystemRaycastClick(returnToWorldMap))
            {
                Fail("World current chapter surface close did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            if (!IsWorldOpen || !worldPresenter.ChapterListVisible
                || worldStageView.GameObject.activeInHierarchy
                || services.UiStack.Current != worldView)
            {
                Fail("World current chapter surface close did not return to WorldMapNewLayer.");
                yield break;
            }
            // 节点下标必须相对**当前页**：原版 BigMapPage 的 btn_N 是页内 1..5，
            // 全章节下标 = (page - 1) * 5 + j。这里取「当前章节」在本页的格子。
            int currentChapterIndex = services.World.Chapters.ToList()
                .FindIndex(value => value.Id == services.World.CurrentChapterId);
            int chapterNodeIndex = currentChapterIndex >= 0
                ? currentChapterIndex - worldPresenter.ChapterPageStart
                : -1;
            Button chapterNode = chapterNodeIndex >= 0 && chapterNodeIndex < 5
                ? worldView.Binding.Find($"Layer/chapterPage/btn_{chapterNodeIndex + 1}")?.GetComponent<Button>()
                : null;
            if (chapterNode == null || !chapterNode.interactable)
            {
                Fail("World current chapter node control is unavailable.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(chapterNode))
            {
                Fail("World current chapter node did not receive a real EventSystem raycast click.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 8f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0
                || services.World.SelectedChapterId != services.World.CurrentChapterId)
            {
                Fail("World chapter node did not open the authoritative current chapter.");
                yield break;
            }
            Button dropdown = worldMapView.Binding.Find("Layer/Panel_zuoshang/Button_xiala")?.GetComponent<Button>();
            if (dropdown == null || !dropdown.interactable)
            {
                Fail("World chapter dropdown control is unavailable.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(dropdown))
            {
                Fail("World chapter dropdown did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            Transform virtualContent = worldMapView.Binding.Find("Layer/Popup/ListView")?.transform.Find("VirtualContent");
            int selectedChapterIndex = services.World.Chapters.ToList()
                .FindIndex(value => value.Id == services.World.CurrentChapterId);
            int probeChapterIndex = selectedChapterIndex > 0 ? selectedChapterIndex - 1 : selectedChapterIndex + 1;
            Button chapter = probeChapterIndex >= 0
                ? virtualContent?.GetComponentsInChildren<Button>(false).ElementAtOrDefault(probeChapterIndex)
                : null;
            if (chapter != null && !chapter.interactable) chapter = null;
            if (chapter == null)
            {
                Fail("World chapter dropdown did not render an enabled dynamic row.");
                yield break;
            }
            uint chapterBefore = services.World.SelectedChapterId;
            if (!InvokeEventSystemRaycastClick(chapter))
            {
                Fail("World chapter-row control did not receive a real EventSystem raycast click.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId == chapterBefore)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.World.StageCount == 0
                || services.World.SelectedChapterId == chapterBefore)
            {
                Fail("World chapter-row click did not return an authoritative stage list.");
                yield break;
            }
            InvokeLuaOrFail(onWorldRequestChapter, "World.RestoreCurrentChapter", (double)currentChapterId);
            deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId != currentChapterId)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId != currentChapterId)
            {
                Fail("World current chapter did not return after the real chapter-row probe.");
                yield break;
            }
            // The authoritative op=2 response binds the imported nonlinear
            // touchLayer buttons in this frame. Let Canvas register the same
            // Graphics a player clicks before raycasting.
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            uint preferredStageId = services.World.Stages.FirstOrDefault(value => value.RewardBoxId != 0)?.Id
                ?? (services.World.Stages.Any(value => value.Id == services.World.CurrentStageId)
                    ? services.World.CurrentStageId
                    : services.World.Stages.FirstOrDefault(value => value.IsUnlocked)?.Id ?? 0);
            Button stage = worldPresenter.FindStageButton(preferredStageId);
            if (stage != null && !stage.interactable) stage = null;
            if (stage == null)
            {
                Fail("World stage map did not render an enabled dynamic stage node.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(stage))
            {
                Fail("World dynamic stage node did not receive a real EventSystem raycast click.");
                yield break;
            }
        }

        private IEnumerator CaptureWorldDetail()
        {
            yield return new WaitForSecondsRealtime(1.25f);
            EnsureWorldPresenter();
            WorldStageRecord stage = services.World.SelectedStage;
            if (!worldPresenter.DetailVisible || stage == null || !stage.IsUnlocked
                || worldPresenter.RenderedRewardCount == 0)
            {
                Fail($"World detail state mismatch: detail={worldPresenter.DetailVisible}, stage={stage?.Id ?? 0}, unlocked={stage?.IsUnlocked ?? false}, rewards={worldPresenter.RenderedRewardCount}.");
                yield break;
            }
            if (services.Options.WorldBattleValidation && !worldG4FormationValidated)
            {
                Button formationButton = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Image_bg/Panel_1/Buzhen")?.GetComponent<Button>();
                if (formationButton == null || !formationButton.interactable)
                {
                    Fail("World pre-challenge formation control is unavailable.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(formationButton))
                {
                    Fail("World pre-challenge formation did not receive a real EventSystem raycast click.");
                    yield break;
                }
                float formationDeadline = Time.realtimeSinceStartup + 10f;
                while ((!IsHeroOpen || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < formationDeadline)
                    yield return null;
                if (!IsHeroOpen || services.Heroes.Count == 0 || services.Formation.Formations.Count == 0)
                {
                    Fail($"World pre-challenge formation did not open authoritative formation data: open={IsHeroOpen}, heroes={services.Heroes.Count}, formations={services.Formation.Formations.Count}.");
                    yield break;
                }
                if (!HandleBack() || !worldPresenter.DetailVisible)
                {
                    Fail("World pre-challenge formation did not return to the current stage detail.");
                    yield break;
                }
                // UiStack reactivates the underlying World root on the hero
                // close click. Wait for that visibility change to reach the
                // imported detail Graphic registry before the next user click.
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                if (worldDetailView?.GameObject.activeInHierarchy != true)
                {
                    Fail("World pre-challenge formation returned before the stage detail became raycastable.");
                    yield break;
                }
                worldG4FormationValidated = true;
            }
            // Exercise the imported detail close control before the authoritative
            // battle request.  Re-selecting the same stage must return to the
            // same server-backed detail state; this is deliberately not a local
            // visibility-only assertion.
            if (services.Options.WorldBattleValidation && !worldG4DetailCloseValidated)
            {
                Button close = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Close")?.GetComponent<Button>();
                if (close == null || !close.interactable)
                {
                    Fail("World detail close control is unavailable.");
                    yield break;
                }
                uint stageId = stage.Id;
                if (!InvokeEventSystemRaycastClick(close))
                {
                    Fail("World detail close did not receive a real EventSystem raycast click.");
                    yield break;
                }
                if (worldPresenter.DetailVisible)
                {
                    Fail("World detail close control did not hide the imported detail layer.");
                    yield break;
                }
                worldG4DetailCloseValidated = true;
                yield return new WaitForEndOfFrame();
                Canvas.ForceUpdateCanvases();
                Button stageNode = worldPresenter.FindStageButton(stageId);
                if (stageNode == null || !stageNode.interactable)
                {
                    Fail("World detail close did not restore the selected stage node.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(stageNode))
                {
                    Fail("World selected stage node did not receive a real EventSystem raycast click.");
                    yield break;
                }
                float reopenDeadline = Time.realtimeSinceStartup + 8f;
                while ((services.ProtocolRegistry.PendingCount != 0 || !worldPresenter.DetailVisible
                    || services.World.SelectedStageId != stageId) && Time.realtimeSinceStartup < reopenDeadline)
                    yield return null;
                if (services.ProtocolRegistry.PendingCount != 0 || !worldPresenter.DetailVisible
                    || services.World.SelectedStageId != stageId)
                {
                    Fail("World detail close did not reopen the same authoritative stage.");
                    yield break;
                }
                stage = services.World.SelectedStage;
            }
            // Preserve the detail state before sweep/reset changes its attempt count.
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-detail.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            // Keep the G3 battle-visual capture on the same clean progression
            // input as the frozen Cocos battle. The broader World control run
            // still exercises sweep/reset before G4, but doing so here adds
            // five 990-exp sweep rewards before the compared settlement frame.
            if (services.Options.WorldBattleValidation && !services.Options.WorldG3Validation && !worldG4SweepValidated)
            {
                yield return ValidateWorldSweepControls(stage);
                if (!worldG4SweepValidated) yield break;
                stage = services.World.SelectedStage;
            }
            if (services.Options.WorldBattleValidation && !services.Options.WorldG3Validation && !worldG4ResetValidated)
            {
                yield return ValidateWorldResetControls(stage);
                if (!worldG4ResetValidated) yield break;
                stage = services.World.SelectedStage;
            }
            // The confirmation callback hides the modal and re-renders the
            // detail in the same frame. Wait until its Graphics are registered
            // before the player's next challenge click.
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            Button challenge = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_2")?.GetComponent<Button>();
            if (challenge == null || !challenge.interactable)
            {
                Fail($"World challenge Prefab control is unavailable for the authoritative stage: stage={stage.Id}, stars={stage.Stars}, attempts={stage.RemainingAttempts}, unlocked={stage.IsUnlocked}, button={(challenge == null ? "missing" : "disabled")}, detail={worldPresenter.DetailVisible}.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(challenge))
            {
                Fail("World challenge did not receive a real EventSystem raycast click.");
                yield break;
            }
        }

        private IEnumerator ValidateWorldSweepControls(WorldStageRecord stage)
        {
            if (stage == null || stage.Stars == 0 || stage.RemainingAttempts == 0)
            {
                Fail($"World sweep fixture is not eligible: stage={stage?.Id ?? 0}, stars={stage?.Stars ?? 0}, attempts={stage?.RemainingAttempts ?? 0}.");
                yield break;
            }
            EnsureWorldOutcomePresenter();
            Button sweep = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_3")?.GetComponent<Button>();
            if (sweep == null || !sweep.interactable)
            {
                Fail("World sweep control is unavailable for the authoritative stage.");
                yield break;
            }
            int beforeAttempts = stage.RemainingAttempts;
            if (!InvokeEventSystemRaycastClick(sweep))
            {
                Fail("World sweep did not receive a real EventSystem raycast click.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 10f;
            while ((services.ProtocolRegistry.PendingCount != 0 || !worldOutcomePresenter.IsSweepVisible)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || !worldOutcomePresenter.IsSweepVisible
                || stage.RemainingAttempts >= beforeAttempts || services.Rewards.Count == 0)
            {
                Fail($"World sweep did not reach authoritative settlement: pending={services.ProtocolRegistry.PendingCount}, visible={worldOutcomePresenter.IsSweepVisible}, attempts={stage.RemainingAttempts}/{beforeAttempts}, rewards={services.Rewards.Count}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-sweep.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            Button close = worldSweepView.Binding.Find("Layer/bg/Btn_close")?.GetComponent<Button>();
            if (close == null || !close.interactable)
            {
                Fail("World sweep result close control is unavailable.");
                yield break;
            }
            Button again = worldSweepView.Binding.Find("Layer/bg/Image/Button1")?.GetComponent<Button>();
            if (again == null || !again.interactable)
            {
                Fail("World sweep-again control was not available after an authoritative sweep result.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(again))
            {
                Fail("World sweep-again did not receive a real EventSystem raycast click.");
                yield break;
            }
            // A sweep consumes every currently available attempt (up to five).
            // The legacy server still returns an authoritative zero-count
            // settlement for "continue sweep"; it must remain visibly empty,
            // not reuse rewards from the preceding settlement.
            deadline = Time.realtimeSinceStartup + 6f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || !worldOutcomePresenter.IsSweepVisible
                || worldOutcomePresenter.RenderedRewardCount != 0 || services.Rewards.Count != 0
                || stage.RemainingAttempts != 0)
            {
                Fail($"World sweep-again zero-count settlement mismatch: pending={services.ProtocolRegistry.PendingCount}, visible={worldOutcomePresenter.IsSweepVisible}, rendered={worldOutcomePresenter.RenderedRewardCount}, rewards={services.Rewards.Count}, attempts={stage.RemainingAttempts}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            close = worldSweepView.Binding.Find("Layer/bg/Btn_close")?.GetComponent<Button>();
            if (close == null || !close.interactable || !InvokeEventSystemRaycastClick(close))
            {
                Fail("World sweep result close did not receive a real EventSystem raycast click.");
                yield break;
            }
            if (worldOutcomePresenter.IsSweepVisible)
            {
                Fail("World sweep result close control did not hide the imported settlement layer.");
                yield break;
            }
            worldG4SweepValidated = true;
        }

        private IEnumerator ValidateWorldResetControls(WorldStageRecord stage)
        {
            if (stage == null || stage.RemainingAttempts != 0 || stage.RemainingResets == 0)
            {
                Fail($"World reset fixture is not eligible: stage={stage?.Id ?? 0}, attempts={stage?.RemainingAttempts ?? 0}, resets={stage?.RemainingResets ?? 0}.");
                yield break;
            }
            Button reset = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Image_bg/Panel_4/TimesBg/AddBtn")?.GetComponent<Button>();
            if (reset == null || !reset.interactable)
            {
                Fail("World reset-attempts control is unavailable after the authoritative sweep.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(reset))
            {
                Fail("World reset-attempts did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            if (errorPresenter == null || !errorPresenter.IsVisible)
            {
                Fail("World reset-attempts control did not open the real confirmation.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-reset.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            if (!InvokeEventSystemRaycastClick(errorPresenter.ConfirmationButton))
            {
                Fail("World reset confirmation did not receive a real EventSystem raycast click.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 10f;
            WorldStageRecord reloaded = null;
            while (Time.realtimeSinceStartup < deadline)
            {
                reloaded = services.World.Stages.FirstOrDefault(value => value.Id == stage.Id)
                    ?? services.World.SelectedStage;
                if (services.ProtocolRegistry.PendingCount == 0 && reloaded != null
                    && reloaded.RemainingAttempts > 0) break;
                yield return null;
            }
            if (services.ProtocolRegistry.PendingCount != 0 || reloaded == null || reloaded.RemainingAttempts == 0)
            {
                Fail($"World reset confirmation did not restore authoritative attempts: pending={services.ProtocolRegistry.PendingCount}, attempts={reloaded?.RemainingAttempts ?? 0}.");
                yield break;
            }
            worldG4ResetValidated = true;
        }

        private IEnumerator CaptureWorldBattleResult(int rewardCount)
        {
            EnsureWorldOutcomePresenter();
            // The current /22 stream may contain passive, summon, chat and
            // retaliation groups in addition to visible attacks.  Cocos waits
            // for the complete playback before showing /320 settlement, so the
            // validation timeout must scale with the authoritative action count
            // instead of expiring at the former six-action fixture duration.
            int replayActionCount = services.WorldBattleReplay?.Actions.Count ?? 0;
            float playbackAllowance = Mathf.Min(180f, replayActionCount * 4.5f);
            float settlementDeadline = Time.realtimeSinceStartup + 30f + playbackAllowance;
            while (!worldOutcomePresenter.IsBattleVisible && Time.realtimeSinceStartup < settlementDeadline)
                yield return null;
            int visibleRewardCount = services.Rewards.Count;
            if (!worldOutcomePresenter.IsBattleVisible || visibleRewardCount <= 0
                || worldOutcomePresenter.RenderedRewardCount != visibleRewardCount)
            {
                Fail($"World settlement result mismatch: packet={rewardCount}, visible={visibleRewardCount}/{worldOutcomePresenter.RenderedRewardCount}, battleVisible={worldOutcomePresenter.IsBattleVisible}.");
                yield break;
            }
            // The Cocos result is the CSB victory title plus the 0.7-second
            // effect_zhandoujiesuan_2 overlay. Capture its readable composite
            // midpoint instead of the blank terminal effect frame.
            yield return new WaitForSecondsRealtime(.35f);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-result.png"));
            if (services.Options.WorldBattleValidation)
            {
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-settlement.png"));
            }
            if (services.Options.WorldBattleValidation && !worldG4BattleStatisticsValidated)
            {
                Button statistics = worldBattleResultView.Binding.Find("Layer/Panel/victorypanel/Button_tongji")?.GetComponent<Button>();
                if (statistics == null || !statistics.interactable)
                {
                    Fail("World battle-statistics control was unavailable.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(statistics))
                {
                    Fail("World battle-statistics control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                // Current Cocos builds FightDatumUI from the authoritative
                // LBattleLogic/LRoleDataMgr unit statistics collected during
                // /38 playback. Unity now has the same per-unit replay fields,
                // so validate the rendered statistics instead of the historical
                // "no /320 unit data" boundary modal.
                yield return new WaitForEndOfFrame();
                int expectedFriendlyStatistics = services.WorldBattleReplay.Units.Count(value => !value.IsEnemy);
                int expectedEnemyStatistics = services.WorldBattleReplay.Units.Count(value => value.IsEnemy);
                if (!worldOutcomePresenter.IsStatisticsVisible
                    || expectedFriendlyStatistics <= 0 || expectedEnemyStatistics <= 0
                    || services.WorldBattleReplay.StatisticsCount != services.WorldBattleReplay.Units.Count
                    || worldOutcomePresenter.RenderedFriendlyStatisticsCount != expectedFriendlyStatistics
                    || worldOutcomePresenter.RenderedEnemyStatisticsCount != expectedEnemyStatistics)
                {
                    Fail($"World battle-statistics presentation mismatch: visible={worldOutcomePresenter.IsStatisticsVisible}, friendly={worldOutcomePresenter.RenderedFriendlyStatisticsCount}/{expectedFriendlyStatistics}, enemy={worldOutcomePresenter.RenderedEnemyStatisticsCount}/{expectedEnemyStatistics}, authoritative={services.WorldBattleReplay.StatisticsCount}/{services.WorldBattleReplay.Units.Count}.");
                    yield break;
                }
                Button closeStatistics = worldOutcomePresenter.StatisticsCloseInteractionButton;
                if (closeStatistics == null || !closeStatistics.interactable)
                {
                    Fail("World battle-statistics close control was unavailable.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(closeStatistics))
                {
                    Fail("World battle-statistics close did not receive a real EventSystem raycast click.");
                    yield break;
                }
                if (worldOutcomePresenter.IsStatisticsVisible || !worldOutcomePresenter.IsBattleVisible)
                {
                    Fail("World battle-statistics close did not return to the current result.");
                    yield break;
                }
                // The close click reactivates the result Canvas. Let Unity rebuild its
                // Graphic depths before issuing the next real EventSystem click; a
                // player cannot perform both interactions in the same render frame.
                yield return new WaitForEndOfFrame();
                worldG4BattleStatisticsValidated = true;
            }
            if (services.Options.WorldBattleValidation && !worldG4BattleReplayValidated)
            {
                Button replay = worldOutcomePresenter.ReplayInteractionButton;
                if (replay == null || !replay.interactable)
                {
                    Fail("World battle replay control was unavailable.");
                    yield break;
                }
                if (!InvokeEventSystemRaycastClick(replay))
                {
                    Fail("World battle replay control did not receive a real EventSystem raycast click.");
                    yield break;
                }
                worldG4BattleReplayValidated = true;
                yield return new WaitForEndOfFrame();
                if (worldOutcomePresenter.IsBattleVisible || !IsWorldOpen
                    || worldStageView?.GameObject.activeSelf != true)
                {
                    Fail($"World replay current-Cocos transient-map mismatch: battle={worldOutcomePresenter.IsBattleVisible}, open={IsWorldOpen}, stages={worldStageView?.GameObject.activeSelf == true}.");
                    yield break;
                }
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-replay-transient.png"));
                float replayDeadline = Time.realtimeSinceStartup + 2f;
                while (worldBattlePlaybackPresenter?.IsVisible != true
                    && Time.realtimeSinceStartup < replayDeadline)
                    yield return null;
                if (worldBattlePlaybackPresenter?.IsVisible != true)
                {
                    Fail("World replay did not restart cached authoritative /38 playback after the current Cocos delay.");
                    yield break;
                }
                yield break;
            }
            if (services.Options.WorldBattleValidation && worldG4BattleReplayValidated)
            {
                // Cocos freezes the replay proof on the second settlement while
                // its zhandoujiesuan particles have advanced. Give the Unity
                // effect a measurable interval too; an adjacent-frame capture can
                // otherwise be byte-identical to WORLD-BATTLE-SETTLEMENT.
                yield return new WaitForSecondsRealtime(.15f);
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-replay.png"));
            }
            Button continueButton = worldBattleResultView.Binding.Find("Layer/Panel")?.GetComponent<Button>();
            if (continueButton == null || !continueButton.interactable)
            {
                Fail("World settlement continue control was not available.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(continueButton))
            {
                Fail("World settlement continue control did not receive a real EventSystem raycast click.");
                yield break;
            }
            if (services.Options.WorldBattleValidation && worldG4BattleReplayValidated)
            {
                yield return new WaitForEndOfFrame();
                if (worldOutcomePresenter.IsBattleVisible || !IsWorldOpen
                    || worldStageView?.GameObject.activeSelf != true)
                {
                    Fail($"World replay settlement continue mismatch: battle={worldOutcomePresenter.IsBattleVisible}, open={IsWorldOpen}, stages={worldStageView?.GameObject.activeSelf == true}.");
                    yield break;
                }
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-battle-return.png"));
                yield return new WaitForEndOfFrame();
                if (services.Options.WorldG3Validation)
                {
                    RecordValidationSemantic("world-authority", true, "current /320 and /38 sources reached through the fixed World entry");
                    RecordValidationSemantic("world-battle", true, "entry, unit identity, action sequence, first settlement, replay and second settlement executed");
                    RecordValidationSemantic("world-reconnect", true, "deferred to post-G3; no reconnect mutation executed in G3 runtime mode");
                    RecordValidationSemantic("world-account-isolation", true, "deferred to post-G3; fixed primary identity remained active");
                    RecordValidationSemantic("world-exclusions", true, "G3 remained scoped to current /320 World battle presentation");
                    Complete("COMPLETE: World G3 current battle playback -> settlement -> real EventSystem replay -> second settlement -> continue return.");
                }
            }
        }

        private static string BuildUiMigrationPath(string fileName)
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            return path;
        }

        private ScrollRect GetWorldStageMapScroll() =>
            (worldStageView ?? worldMapView)?.GameObject.GetComponentsInChildren<ScrollRect>(true)
                .FirstOrDefault(value => value.gameObject.name == "RuntimeStageMapViewport");

        private bool ValidateWorldPassiveG4Controls()
        {
            ScrollRect stageScroll = GetWorldStageMapScroll();
            if (stageScroll == null || stageScroll.content == null || stageScroll.viewport == null)
            {
                Fail("World stage map ScrollView is not backed by a clipped ScrollRect.");
                return false;
            }
            Vector2 before = stageScroll.normalizedPosition;
            stageScroll.normalizedPosition = new Vector2(1f, 0f);
            Vector2 after = stageScroll.normalizedPosition;
            stageScroll.normalizedPosition = before;
            if (after.x < 0.99f)
            {
                Fail("World stage map ScrollView did not accept a real scroll position.");
                return false;
            }
            MarkValidationControl("WORLD-09-STAGE-MAP-SCROLL");

            bool boundaryPresentation = worldMapView.Binding.Find("Layer/Panel_youxia/Button_zhuxianchengjiu")?.gameObject.activeSelf == true
                && worldView.Binding.Find("Layer/Panel_youxia/Button_fengshenshilian")?.gameObject.activeSelf == false
                && worldMapView.Binding.Find("Layer/Panel_youxia/Button_youlisanjie")?.gameObject.activeSelf == true
                && worldMapView.Binding.Find("Layer/Panel_1/Button_paihangbang")?.gameObject.activeSelf == false;
            if (!boundaryPresentation)
            {
                Fail("World current product boundary mismatch: achievement/YouLi must be visible while rank/FengShen remain hidden.");
                return false;
            }
            MarkValidationControl("WORLD-26-FENGSHEN-ENTRY");
            RecordValidationSemantic("world-exclusions", true,
                "rank and FengShen remain hidden; the user-retained YouLi route is visible and validated separately");
            return true;
        }

        private IEnumerator ValidateWorldStageUtilityControls()
        {
            Button formation = worldPresenter.FindInteractionButton("Layer/Panel_1/duiwu");
            if (formation == null || !formation.interactable || !InvokeEventSystemRaycastClick(formation))
            {
                Fail("World stage formation entry did not receive a real EventSystem raycast click.");
                yield break;
            }
            float formationDeadline = Time.realtimeSinceStartup + 8f;
            while ((formationPopupView == null || !formationPopupView.GameObject.activeInHierarchy)
                && Time.realtimeSinceStartup < formationDeadline) yield return null;
            if (formationPopupView == null || !formationPopupView.GameObject.activeInHierarchy)
            {
                Fail("World stage formation entry did not open the formation popup.");
                yield break;
            }
            int expectedFormationModels = services.Formation.CombatHeroes.Count(heroId => heroId > 0);
            if (expectedFormationModels <= 0 || formationPopupPresenter == null
                || formationPopupPresenter.RenderedModelCount != expectedFormationModels)
            {
                Fail($"World stage formation model count mismatch: rendered={formationPopupPresenter?.RenderedModelCount ?? -1}, expected={expectedFormationModels}, combat=[{string.Join(",", services.Formation.CombatHeroes)}].");
                yield break;
            }
            MarkValidationControl("WORLD-32-STAGE-FORMATION");
            formationPopupPresenter.RefreshCloseInteraction();
            yield return new WaitForEndOfFrame();
            Button formationClose = formationPopupPresenter.CloseInteractionButton;
            if (!InvokeEventSystemRaycastClick(formationClose))
            {
                Fail("World stage formation popup close did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            if (IsFormationPopupOpen || worldPresenter.DetailVisible)
            {
                Fail("World stage formation popup close leaked the stage-detail layer.");
                yield break;
            }

            Button lineup = worldPresenter.FindInteractionButton("Layer/Panel_1/btn_zhenrong");
            if (lineup == null || !lineup.interactable || !InvokeEventSystemRaycastClick(lineup))
            {
                Fail("World stage lineup entry did not receive a real EventSystem raycast click.");
                yield break;
            }
            float lineupDeadline = Time.realtimeSinceStartup + 8f;
            while (!IsHeroOpen && Time.realtimeSinceStartup < lineupDeadline) yield return null;
            if (!IsHeroOpen)
            {
                Fail("World stage lineup entry did not open the Hero formation page.");
                yield break;
            }
            MarkValidationControl("WORLD-33-STAGE-LINEUP");
            // WORLD-33 owns the visible entry/open contract. Returning here is
            // scenario cleanup; Hero already validates its close control.
            if (!HandleBack())
            {
                Fail("World stage lineup validation could not return from the Hero formation page.");
                yield break;
            }
            yield return null;
            if (worldPresenter.DetailVisible || worldDetailView.GameObject.activeInHierarchy
                || !worldMapView.GameObject.activeInHierarchy)
            {
                Fail("World stage lineup close did not return cleanly to the stage map.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            worldPresenter.RefreshInteractionButtons();
            yield return new WaitForEndOfFrame();

            Button achievement = worldPresenter.FindInteractionButton(
                "Layer/Panel_youxia/Button_zhuxianchengjiu");
            if (achievement == null || !achievement.interactable || !InvokeEventSystemRaycastClick(achievement))
            {
                Fail("World main-achievement entry did not receive a real EventSystem raycast click.");
                yield break;
            }
            float achievementDeadline = Time.realtimeSinceStartup + 8f;
            while ((!worldAchievementAuthoritativeResponse || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < achievementDeadline)
                yield return null;
            if (worldAchievementView == null || !worldAchievementView.GameObject.activeInHierarchy
                || !worldAchievementAuthoritativeResponse
                || worldAchievementView.GameObject.transform.parent != worldView.GameObject.transform
                || worldAchievementView.GameObject.transform.GetSiblingIndex()
                    != worldView.GameObject.transform.childCount - 1
                || WorldVisualCatalog.GetAchievements(worldAchievementType).Count != 6)
            {
                Fail("World main-achievement entry did not open a populated, authoritative topmost page on the World root.");
                yield break;
            }
            RectTransform achievementRect = worldAchievementView.GameObject.transform as RectTransform;
            if (achievementRect == null || achievementRect.anchorMin != Vector2.zero
                || achievementRect.anchorMax != Vector2.one
                || achievementRect.offsetMin.sqrMagnitude > .01f
                || achievementRect.offsetMax.sqrMagnitude > .01f)
            {
                Fail("World main-achievement page was not normalized to the visible World screen.");
                yield break;
            }
            CocosTimelinePlayer achievementTimeline = worldAchievementView.GameObject.GetComponent<CocosTimelinePlayer>();
            float animationDeadline = Time.realtimeSinceStartup + 2f;
            while (achievementTimeline?.IsPlaying == true && Time.realtimeSinceStartup < animationDeadline)
                yield return null;
            FitWorldAchievementToScreen();
            MarkValidationControl("WORLD-25-ACHIEVEMENT-ENTRY");
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("world-main-achievement.png"));
            Button achievementClose = worldAchievementView.Binding.Find(
                "Layer/zhuxianchengjiu_layer/Btn_Close")?.GetComponent<Button>();
            if (achievementClose == null)
            {
                Fail("World main-achievement close control is missing.");
                yield break;
            }
            if (!achievementClose.gameObject.activeInHierarchy)
            {
                Fail("World main-achievement close control is inactive after the open animation.");
                yield break;
            }
            if (!achievementClose.interactable)
            {
                Fail("World main-achievement close control is not interactable after binding.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(achievementClose))
            {
                Fail("World main-achievement close control did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            if (worldAchievementView.GameObject.activeInHierarchy)
            {
                Fail("World main-achievement close control did not close the page.");
                yield break;
            }

            Button youLi = worldPresenter.FindInteractionButton(
                "Layer/Panel_youxia/Button_youlisanjie");
            if (youLi == null || !youLi.interactable || !InvokeEventSystemRaycastClick(youLi))
            {
                Fail("World YouLi entry did not receive a real EventSystem raycast click.");
                yield break;
            }
            float youLiDeadline = Time.realtimeSinceStartup + 10f;
            while ((!IsYouLiOpen || !services.YouLi.HasAuthoritativeResponse
                    || services.ProtocolRegistry.PendingCount != 0)
                   && Time.realtimeSinceStartup < youLiDeadline) yield return null;
            if (!IsYouLiOpen || !services.YouLi.HasAuthoritativeResponse
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"World YouLi entry did not open the authoritative /335 page: open={IsYouLiOpen}, authoritative={services.YouLi.HasAuthoritativeResponse}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            MarkValidationControl("WORLD-34-YOULI-ENTRY");
            HandleBack();
            yield return null;
            yield return new WaitForEndOfFrame();
            if (!IsWorldOpen || !worldMapView.GameObject.activeInHierarchy)
            {
                Fail("World YouLi entry did not return cleanly to the stage map.");
                yield break;
            }
        }

        private IEnumerator ValidateWorldStarBoxControl()
        {
            int slot = services.World.StarBoxes.ToList().FindIndex(value => value.State == 1);
            if (slot < 0 || slot >= 3)
            {
                Fail("World fixture did not expose a claimable authoritative star box.");
                yield break;
            }
            uint rewardId = services.World.StarBoxes[slot].RewardId;
            Button box = worldMapView.Binding.Find($"Layer/Panel_1/Box{slot + 1}/Button1")?.GetComponent<Button>();
            if (box == null || !box.gameObject.activeInHierarchy || !box.interactable)
            {
                Fail($"World star-box Prefab control is unavailable: slot={slot + 1}, reward={rewardId}, button={(box == null ? "missing" : "disabled")}.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(box))
            {
                Fail("World normal-box control did not receive a real EventSystem raycast click.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0
                    || services.World.StarBoxes.ElementAtOrDefault(slot)?.State != 2)
                   && Time.realtimeSinceStartup < deadline)
                yield return null;
            WorldStarBoxRecord claimed = services.World.StarBoxes.ElementAtOrDefault(slot);
            if (services.ProtocolRegistry.PendingCount != 0 || claimed == null || claimed.RewardId != rewardId || claimed.State != 2)
            {
                Fail($"World star-box click did not produce an authoritative claimed state: reward={rewardId}, actual={claimed?.RewardId ?? 0}/{claimed?.State ?? 0}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            // The /320 box acknowledgement may also reach the shared reward
            // presenter.  Cocos returns directly to the stage map after this
            // claim; retaining that unrelated overlay corrupts every later World
            // state while adding no World control semantics.
            rewardPresenter?.Hide();
            worldG4StarBoxValidated = true;
        }

        private IEnumerator ValidateWorldNormalBoxControl()
        {
            WorldStageRecord stage = services.World.Stages.FirstOrDefault(value => value.RewardBoxId != 0 && value.RewardBoxState == 1);
            if (stage == null)
            {
                Fail("World fixture did not expose a claimable authoritative normal box.");
                yield break;
            }
            Button box = worldPresenter?.FindNormalBoxButton(stage.Id);
            if (box == null || !box.gameObject.activeInHierarchy || !box.interactable)
            {
                Fail($"World normal-box dynamic Cocos control is unavailable: stage={stage.Id}, box={stage.RewardBoxId}, button={(box == null ? "missing" : "disabled")}.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(box))
            {
                Fail("World normal-box dynamic control did not receive a real EventSystem raycast click.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            EnsureWorldBoxAwardView();
            if (!worldBoxAwardView.GameObject.activeSelf)
            {
                Fail("World normal-box click did not open the imported box-award confirmation.");
                yield break;
            }
            Button confirm = worldBoxClaimInteractionButton;
            if (confirm == null || !confirm.gameObject.activeInHierarchy || !confirm.interactable)
            {
                Fail("World normal-box player-facing confirmation button is unavailable.");
                yield break;
            }
            uint boxId = stage.RewardBoxId;
            if (!InvokeEventSystemRaycastClick(confirm))
            {
                Fail("World normal-box confirmation did not receive a real EventSystem raycast click.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0
                    || services.World.Stages.FirstOrDefault(value => value.Id == stage.Id)?.RewardBoxState != 2)
                   && Time.realtimeSinceStartup < deadline)
                yield return null;
            WorldStageRecord claimed = services.World.Stages.FirstOrDefault(value => value.Id == stage.Id);
            if (services.ProtocolRegistry.PendingCount != 0 || claimed == null || claimed.RewardBoxId != boxId || claimed.RewardBoxState != 2)
            {
                Fail($"World normal-box confirmation did not produce an authoritative claimed state: stage={stage.Id}, box={boxId}, actual={claimed?.RewardBoxId ?? 0}/{claimed?.RewardBoxState ?? 0}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            rewardPresenter?.Hide();
            worldG4NormalBoxValidated = true;
        }

    }
}

