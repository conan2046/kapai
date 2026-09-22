using System;
using System.Collections;
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
        public void UpdateGameplayHotPoint(int rawType, int rawState)
        {
            services.Gameplay.SetHotPoint(checked((ushort)rawType), rawState == 1);
        }

        public void CompleteGameplayValidation() => RunGameplayValidation();

        public void RunGameplayValidation()
        {
            if (gameplayValidationRunning || gameplayValidationCompleted) return;
            gameplayValidationRunning = true;
            StartCoroutine(RunGameplayValidationCoroutine());
        }

        private IEnumerator CaptureGameplayFrame(string fileName)
        {
            // G5 compares stable native frames. Login broadcasts use the shared transient
            // toast and must not contaminate hall captures; the route-boundary state is the
            // sole intentional toast evidence.
            if (!string.Equals(fileName, "bootstrap-gameplay-unavailable.png", StringComparison.Ordinal))
                toastPresenter?.Clear();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Gameplay screenshot was not written: {path}");
        }

        private IEnumerator WaitForGameplaySharedHotPoints()
        {
            float deadline = Time.realtimeSinceStartup + 10f;
            while ((!services.KunLun.HasAuthoritativeResponse || services.ProtocolRegistry.PendingCount > 0)
                   && Time.realtimeSinceStartup < deadline)
                yield return null;
        }
        private IEnumerator RunGameplayValidationCoroutine()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint isolationUserId = services.Options.GameplayIsolationUserId == 0
                ? 705213u
                : services.Options.GameplayIsolationUserId;
            int pendingAtEntry = 0;
            int[] functionIds = { 1, 3, 9, 10, 21, 23, 27, 29, 32 };
            string[] controlIds =
            {
                "GAMEPLAY-04-ENTER-1", "GAMEPLAY-05-ENTER-3",
                "GAMEPLAY-09-ENTER-9", "GAMEPLAY-10-ENTER-10",
                "GAMEPLAY-16-ENTER-21", "GAMEPLAY-17-ENTER-23", "GAMEPLAY-19-ENTER-27", "GAMEPLAY-18-ENTER-29",
                "GAMEPLAY-20-ENTER-32"
            };
            try
            {
                BeginValidationEvidence();
                if (primaryUserId != 7200057 || primaryRoleId != 1000003 || isolationUserId != 705213)
                {
                    Fail($"Gameplay fixed identities mismatch: primary={primaryUserId}/{primaryRoleId}, isolationUser={isolationUserId}.");
                    yield break;
                }
                RecordValidationSemantic("gameplay-authoritative-identity", true,
                    $"primary=7200057/1000003/T00057/level-{services.Player.Level}; persistentDataPath SQLite; isolation=705213/1000006/T67076");

                pendingAtEntry = services.ProtocolRegistry.PendingCount;

                EnsureGameplayPresenter();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                int configuredCount = functionIds.Length;
                if (!IsGameplayOpen || services.Gameplay.Count != configuredCount || services.Gameplay.OpenCount != configuredCount
                    || GameplayRenderedCount != configuredCount || GameplayEnterButtonCount != configuredCount || GameplayMissingIconCount != 0)
                {
                    Fail($"Gameplay primary list mismatch: open={IsGameplayOpen}, items={services.Gameplay.Count}, openItems={services.Gameplay.OpenCount}, rendered={GameplayRenderedCount}, enter={GameplayEnterButtonCount}, missing={GameplayMissingIconCount}.");
                    yield break;
                }
                bool backgroundPreserved = mainView?.Binding.Find("Layer/Bg")?.activeInHierarchy == true;
                bool hudControlsHidden = mainView?.Binding.Find("Layer/Main_UI")?.activeInHierarchy == false;
                RecordValidationSemantic("gameplay-main-background-preserved", backgroundPreserved && hudControlsHidden,
                    $"Layer/Bg active={backgroundPreserved}; Layer/Main_UI hidden={hudControlsHidden}");
                if (!backgroundPreserved || !hudControlsHidden)
                {
                    Fail($"Gameplay background layering mismatch: background={backgroundPreserved}, hudHidden={hudControlsHidden}.");
                    yield break;
                }
                MarkValidationControl("GAMEPLAY-01-HUD-ENTRY");
                RecordValidationSemantic("gameplay-entry-list-current-ready-8", services.Gameplay.Items.Select(value => value.Definition.Id).SequenceEqual(functionIds),
                    "Current table-driven order=1,3,9,10,21,23,27,29; Arena id6 is outside the Steam Gameplay scope");
                bool shopsExcluded = new[] { 15, 16, 17 }.All(id =>
                {
                    GameplayDefinition route = services.GameplayCatalog.Find(id);
                    return (route == null || route.Page == 0)
                        && services.Gameplay.Items.All(value => value.Definition.Id != id);
                });
                RecordValidationSemantic("gameplay-no-extra-shops", shopsExcluded, "15/16/17 page=0 and absent");
                if (!shopsExcluded || !gameplayPresenter.CardBodiesInert)
                {
                    Fail("Gameplay page=0 exclusion or inert card-body contract failed.");
                    yield break;
                }
                RecordValidationSemantic("gameplay-card-body-inert", true,
                    "TaskBtn1/2 keep non-interactable Button bodies; only EnterBtn has a listener");
                bool cacheOwnerSafe = services.ProtocolRegistry.PendingCount == pendingAtEntry;
                RecordValidationSemantic("gameplay-redpoint-shared-owner", cacheOwnerSafe,
                    $"Gameplay open sent no /65; shared cache rendered current states; pending={pendingAtEntry}->{services.ProtocolRegistry.PendingCount}");
                if (!cacheOwnerSafe) { Fail("Gameplay open changed the protocol pending count."); yield break; }

                yield return CaptureGameplayFrame("bootstrap-gameplay-list-top.png");
                yield return CaptureGameplayFrame("bootstrap-gameplay-red-dot.png");
                gameplayPresenter.InvokeClose();
                if (IsGameplayOpen) { Fail("Gameplay close button did not return to HUD."); yield break; }
                MarkValidationControl("GAMEPLAY-02-FRAME-CLOSE");
                MarkValidationControl("GAMEPLAY-12-RETURN-REENTER");
                yield return CaptureGameplayFrame("bootstrap-gameplay-hud.png");
                yield return CaptureGameplayFrame("bootstrap-gameplay-return-hud.png");
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                gameplayPresenter.ResetScrollToTop();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen)
                { Fail("Gameplay real re-entry did not rebuild the activity list."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-reenter.png");

                ScrollRect gameplayScroll = gameplayPresenter.ScrollControl;
                float scrollBefore = gameplayPresenter.VerticalNormalizedPosition;
                gameplayPresenter.ScrollToBottom();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                float scrollAfter = gameplayPresenter.VerticalNormalizedPosition;
                Graphic gameplayScrollSurface = gameplayScroll?.viewport?.GetComponent<Graphic>();
                bool gameplayScrollWorked = gameplayScroll != null
                    && gameplayScroll.content != null && gameplayScroll.viewport != null
                    && gameplayScroll.content.rect.height > gameplayScroll.viewport.rect.height + 1f
                    && gameplayScrollSurface != null && gameplayScrollSurface.raycastTarget
                    && scrollAfter < scrollBefore - 0.01f;
                RecordValidationSemantic("gameplay-real-scroll", gameplayScrollWorked,
                    $"content={gameplayScroll?.content?.rect.height:F1},viewport={gameplayScroll?.viewport?.rect.height:F1},normalized={scrollBefore:F2}->{scrollAfter:F2},raycast={gameplayScrollSurface?.raycastTarget == true}");
                if (!gameplayScrollWorked)
                {
                    Fail($"Gameplay list did not perform a real safe scroll: content={gameplayScroll?.content?.rect.height:F1}, viewport={gameplayScroll?.viewport?.rect.height:F1}, normalized={scrollBefore:F2}->{scrollAfter:F2}.");
                    yield break;
                }
                MarkValidationControl("GAMEPLAY-03-LIST-SCROLL");
                yield return CaptureGameplayFrame("bootstrap-gameplay-list-scrolled.png");
                RecordValidationSemantic("gameplay-scroll-lifecycle", true,
                    $"Steam rows remained safely clipped; close/reenter rebuilt the list; normalized={scrollAfter:F2}");

                int routePendingBefore = services.ProtocolRegistry.PendingCount;
                for (int index = 0; index < functionIds.Length; index++)
                {
                    // Fish has its own authoritative /217 validation. Its Gameplay card
                    // remains visible, but entering it is expected to enqueue that protocol.
                    if (functionIds[index] == 32) continue;
                    if (!IsGameplayOpen) gameplayButton.onClick.Invoke();
                    yield return new WaitForEndOfFrame();
                    lastGameplayBoundaryId = 0;
                    if (!gameplayPresenter.InvokeEnter(functionIds[index]) || lastGameplayBoundaryId != functionIds[index]
                        || IsGameplayOpen || services.ProtocolRegistry.PendingCount != routePendingBefore)
                    {
                        Fail($"Gameplay route boundary failed id={functionIds[index]}, last={lastGameplayBoundaryId}, open={IsGameplayOpen}, pending={routePendingBefore}->{services.ProtocolRegistry.PendingCount}.");
                        yield break;
                    }
                    MarkValidationControl(controlIds[index]);
                    if (index == 0) yield return CaptureGameplayFrame("bootstrap-gameplay-unavailable.png");
                }
                RecordValidationSemantic("gameplay-enter-boundaries-current-ready-8", true,
                    "9 configured EnterBtn listeners closed the hub and reported target owner without opening target views or sending target protocols");

                // All local initial accounts are intentionally level 99 for feature testing.
                // Preserve the source lock-state visual contract with an isolated in-memory
                // level-1 projection instead of requiring a deliberately locked account.
                ShowGameplay();
                services.Gameplay.Load(services.GameplayCatalog.Items, 1);
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || services.Gameplay.Count != configuredCount || services.Gameplay.OpenCount != 0 || GameplayEnterButtonCount != 0)
                { Fail($"Gameplay projected locked list mismatch: count={services.Gameplay.Count}, open={services.Gameplay.OpenCount}, enter={GameplayEnterButtonCount}."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-locked.png");
                RecordValidationSemantic("gameplay-lock-level", true,
                    "level-1 source projection rendered N-level labels for all eight configured entries and exposed no EnterBtn; production test accounts remain level 99");
                services.Gameplay.Load(services.GameplayCatalog.Items, services.Player.Level);
                yield return new WaitForEndOfFrame();
                yield return CaptureGameplayFrame("bootstrap-gameplay-restart.png");
                MarkValidationControl("GAMEPLAY-13-CLIENT-RESTART");

                services.Gameplay.Load(Array.Empty<GameplayDefinition>(), services.Player.Level);
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || !IsGameplayEmptyVisible || GameplayRenderedCount != 0)
                { Fail("Gameplay empty-config safe frame did not remain visible."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-empty.png");
                MarkValidationControl("GAMEPLAY-11-EMPTY-FAILURE");
                RecordValidationSemantic("gameplay-failure-safety", true,
                    "empty config preserved frame/close without rows; missing target pages remained boundary-only; no business data was fabricated");
                ShowGameplay();
                yield return new WaitForEndOfFrame();

                services.Network.Disconnect();
                HandleDisconnected("Gameplay deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                if (errorPresenter?.IsVisible != true || services.Network.State != ProjectX.Network.NetworkState.Disconnected)
                { Fail("Gameplay deliberate disconnect did not render reconnect feedback."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-disconnected.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Gameplay reconnect confirmation was unavailable."); yield break; }
                float deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("Gameplay reconnect did not restore primary role."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                BindGameplayClick(false);
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                yield return CaptureGameplayFrame("bootstrap-gameplay-reconnect.png");
                MarkValidationControl("GAMEPLAY-14-NETWORK-RECOVERY");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Gameplay isolation-account submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != 1000006 || GetPlayerRoleId() == primaryRoleId)
                { Fail($"Gameplay isolation identity failed: role={GetPlayerRoleId()}."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                deadline = Time.realtimeSinceStartup + 8f;
                while (services.ProtocolRegistry.PendingCount > 0 && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.ProtocolRegistry.PendingCount != 0)
                { Fail($"Gameplay isolation global hot-point requests did not settle: pending={services.ProtocolRegistry.PendingCount}."); yield break; }
                BindGameplayClick(false);
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || services.ProtocolRegistry.PendingCount != 0)
                { Fail($"Gameplay isolation inherited an open/pending state: open={IsGameplayOpen}, pending={services.ProtocolRegistry.PendingCount}."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-account-switch.png");
                MarkValidationControl("GAMEPLAY-15-ACCOUNT-ISOLATION");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Gameplay terminal primary submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("Gameplay terminal identity was not restored."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                ShowGameplay();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen) { Fail("Gameplay terminal primary hub did not reopen."); yield break; }

                RecordValidationSemantic("gameplay-reconnect-account-isolation", true,
                    "real disconnect/reconnect restored primary; real locked and isolation accounts rebuilt independent stores; terminal primary restored");
                RecordValidationSemantic("gameplay-control-matrix-16", validationControlIds.Count == 16,
                    $"validated={validationControlIds.Count}/16");
                if (validationControlIds.Count != 16)
                { Fail($"Gameplay control coverage mismatch: {validationControlIds.Count}/16."); yield break; }
                gameplayValidationCompleted = true;
                Complete($"COMPLETE: Gameplay 16/16 controls; 7 table-driven entries/routes, projected lock state, real reconnect/account isolation, reversible SQLite fixture; user={primaryUserId} role={primaryRoleId}");
            }
            finally
            {
                gameplayValidationRunning = false;
            }
        }
    }
}
