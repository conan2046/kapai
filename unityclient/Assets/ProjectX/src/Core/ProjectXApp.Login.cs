using System;
using System.Collections;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowLoginUi()
        {
            loginView = services.UiRouter.FindBySource("Login/loginLayer");
            loginBackgroundView = services.UiRouter.FindBySource("Login/LoginBgLayer");
            loginServerListView = services.UiRouter.FindBySource("Login/SeverListLayer");
            roleCreateView = services.UiRouter.FindBySource("Login/RoleCreateLayer");
            noticeView = services.UiRouter.FindBySource("/NoticeLayer.csd", true);
            services.UiStack.Clear();
            loginBackgroundView?.SetVisible(true);
            loginView?.SetVisible(true);
            loginBackgroundView?.GameObject.transform.SetAsFirstSibling();
            loginView?.GameObject.transform.SetAsLastSibling();
            loginServerListView?.SetVisible(false);
            roleCreateView?.SetVisible(false);
            noticeView?.SetVisible(false);
            mainView?.SetVisible(false);
            mainCloudView?.SetVisible(false);
            bagView?.SetVisible(false);
            SetOneLevelFrameVisible(false);
            bagInputView?.SetVisible(false);
            bagPopupFrameView?.SetVisible(false);
            bagGiftView?.SetVisible(false);
            bagSourceView?.SetVisible(false);
            bagEquipmentInfoView?.SetVisible(false);
            settingsView?.SetVisible(false);
            taskBackgroundView?.SetVisible(false);
            taskView?.SetVisible(false);
            staminaClaimView?.SetVisible(false);
            resourceRecoveryView?.SetVisible(false);
            errorView?.SetVisible(false);
            loadingView?.SetVisible(false);
            SetOneLevelFrameVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroBookView?.SetVisible(false);
            heroRecycleView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            heroEnhanceMasterView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            heroItemSourceView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentDetailView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentCultivateView?.SetVisible(false);
            heroEquipmentStrengthView?.SetVisible(false);
            heroEquipmentRefineView?.SetVisible(false);
            heroEquipmentAwakenView?.SetVisible(false);
            heroEquipmentDivineView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentAutoRefineView?.SetVisible(false);
            heroEquipmentExchangeView?.SetVisible(false);
            heroEquipmentAutoStarView?.SetVisible(false);
            heroEquipmentAutoDivineView?.SetVisible(false);
            heroEquipmentDivineEffectView?.SetVisible(false);
            mailView?.SetVisible(false);
            shopView?.SetVisible(false);
            RestoreShopFramePanel();
            friendView?.SetVisible(false);
            chatMiniView?.SetVisible(false);
            chatView?.SetVisible(false);
            oldMemoryPresenter?.Hide();
            if (loginView == null) { Fail("Login/loginLayer CocosUiBinding was not found."); return; }
            if (loginBackgroundView == null) { Fail("Login/LoginBgLayer CocosUiBinding was not found."); return; }
            // Account switching must restore an actual stack root. Leaving the
            // stack empty only happened to work for the first launch, and let a
            // deferred module callback hide the login layer during Draw G4.
            services.UiStack.SetRoot(loginView);
            loginPresenter = loginPresenter ?? new LoginPresenter(loginBackgroundView, loginView, loginServerListView, roleCreateView);
            if (singlePlayerTitleEnabled) loginPresenter.ShowSinglePlayerTitle();
            else loginPresenter.ShowLocalServer("本地测试服");
            EnsureErrorPresenter();
            EnsureCommonPresenters();
            services.State.Change(AppState.Login, "Login UI shown");
            SetStatus(singlePlayerTitleEnabled ? "Single-player title ready." : "Login UI ready.");
        }

        public void BindLoginClick(bool autoInvoke)
        {
            try
            {
                if (singlePlayerTitleEnabled)
                {
                    loginPresenter.BindSinglePlayerControls(
                        StartNewSinglePlayerGame,
                        () => ShowSinglePlayerSaves(SinglePlayerSaveMenuMode.Continue),
                        ShowTitleSettings,
                        ExitApplication);
                    return;
                }
                loginPresenter.BindLoginControls(HandleLoginClick, HandleAccountSubmit, ShowLoginError);
                Button button = loginView.FindNode(LoginButtonPath)?.GetComponent<Button>();
                loginView.BindClick(LoginServerButtonPath, () => loginPresenter.ShowServerList(
                    HandleLoginClick, () => SetStatus("Login UI ready.")));
                if (autoInvoke || HasCommandLineFlag("-projectXS8StartupAcceptance")
                    || HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
                    StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        private void StartNewSinglePlayerGame()
        {
            try
            {
                SinglePlayerSaveSlot emptySlot = singlePlayerSaves.GetSlots()
                    .FirstOrDefault(slot => !slot.Exists);
                if (emptySlot != null)
                {
                    SetStatus($"Creating a new single-player role in Slot {emptySlot.SlotId:00}.");
                    BeginSinglePlayerSlot(emptySlot.SlotId, true);
                    return;
                }

                ShowSinglePlayerSaves(SinglePlayerSaveMenuMode.NewGame);
            }
            catch (Exception exception)
            {
                ShowLoginError("新游戏启动失败：" + exception.Message);
            }
        }

        private void ShowSinglePlayerSaves(SinglePlayerSaveMenuMode mode)
        {
            try
            {
                if (mode == SinglePlayerSaveMenuMode.SaveCurrent
                    && (activeSaveSlotId <= 0 || !services.Player.IsLoaded))
                    throw new InvalidOperationException("当前尚未进入可保存的单机游戏。");
                EnsureOldMemoryPresenter();
                oldMemoryPresenter.Show(mode);
                if (services.UiStack.Current != oldMemoryView)
                    services.UiStack.Push(oldMemoryView);
                if (mode == SinglePlayerSaveMenuMode.SaveCurrent)
                    SetOneLevelFrameVisible(false);
                SetStatus(mode == SinglePlayerSaveMenuMode.NewGame
                    ? "New single-player role slot selection active."
                    : mode == SinglePlayerSaveMenuMode.SaveCurrent
                        ? "In-game save slot selection active."
                        : "Existing single-player role slot selection active.");
            }
            catch (Exception exception) { ShowLoginError("存档列表打开失败：" + exception.Message); }
        }

        private void EnsureOldMemoryPresenter()
        {
            if (oldMemoryPresenter != null) return;
            oldMemoryView = services.UiRouter.FindBySource("Generated/OldMemoryLayer");
            if (oldMemoryView == null)
                throw new InvalidOperationException("Generated/OldMemoryLayer was not registered.");
            oldMemoryPresenter = new OldMemoryPresenter(oldMemoryView, singlePlayerSaves, services.Resources,
                BeginSinglePlayerSlot, SaveCurrentSinglePlayerSlot, CloseOldMemoryMenu,
                ShowTitleConfirmation, ShowLoginError, SetStatus);
        }

        private void CloseOldMemoryMenu()
        {
            SinglePlayerSaveMenuMode mode = oldMemoryPresenter?.Mode ?? SinglePlayerSaveMenuMode.Continue;
            oldMemoryPresenter?.Hide();
            if (services?.UiStack.Current == oldMemoryView) services.UiStack.Pop();
            if (mode == SinglePlayerSaveMenuMode.SaveCurrent && settingsView != null
                && services?.UiStack.Current == settingsView)
                SetOneLevelFrameVisible(true);
            SetStatus(mode == SinglePlayerSaveMenuMode.SaveCurrent
                ? "System settings active."
                : "Single-player title ready.");
        }

        private void SaveCurrentSinglePlayerSlot(int targetSlotId)
        {
            if (activeSaveSlotId <= 0 || singlePlayerSaves?.ActiveSlotId != activeSaveSlotId
                || localServerSupervisor?.IsReady != true || !services.Player.IsLoaded)
                throw new InvalidOperationException("当前游戏尚未进入可保存状态。");

            string stagingPath = singlePlayerSaves.CreateSnapshotStagingPath(targetSlotId);
            try
            {
                localServerSupervisor.CreateSnapshot(stagingPath);
                if (targetSlotId == activeSaveSlotId)
                {
                    singlePlayerSaves.DiscardSnapshotStaging(stagingPath);
                    singlePlayerSaves.UpdatePlayer(activeSaveSlotId, services.Player.RoleId,
                        services.Player.Name, services.Player.Model, services.Player.Level, services.Player.Power);
                }
                else
                {
                    singlePlayerSaves.CommitCurrentSnapshot(activeSaveSlotId, targetSlotId, stagingPath,
                        services.Player.RoleId, services.Player.Name, services.Player.Model,
                        services.Player.Level, services.Player.Power);
                }
                SetStatus($"当前进度已保存到存档 {targetSlotId:00}。");
            }
            catch (Exception exception)
            {
                try { singlePlayerSaves.DiscardSnapshotStaging(stagingPath); }
                catch { }
                ClientLog.Error("SinglePlayer", "Save current snapshot failed", exception.Message);
                throw new InvalidOperationException("保存当前进度失败，请重试。");
            }
        }

        private void ShowTitleConfirmation(string heading, string detail, Action confirmed)
        {
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation(heading, detail, confirmed);
        }

        private void BeginSinglePlayerSlot(int slotId, bool startNew)
        {
            if (localSaveServerStarting) return;
            StartCoroutine(PrepareSinglePlayerSlotThenLogin(slotId, startNew));
        }

        private IEnumerator PrepareSinglePlayerSlotThenLogin(int slotId, bool startNew)
        {
            localSaveServerStarting = true;
            oldMemoryPresenter?.Hide();
            loginView?.SetVisible(false);
            Canvas canvas = FindObjectOfType<Canvas>();
            if (canvas == null)
            {
                localSaveServerStarting = false;
                ShowLoginError("启动界面不存在，无法读取存档。");
                yield break;
            }
            startupPresenter?.Dispose();
            startupPresenter = new StartupPresenter(canvas);
            startupPresenter.ShowServerPreparation(startNew ? "正在创建新的回忆…" : "正在读取旧的回忆…");
            try
            {
                string databasePath = singlePlayerSaves.PrepareForPlay(slotId, startNew);
                services.Config.LocalUserId = singlePlayerSaves.ResolveLocalUserId(
                    slotId, startNew, services.Options.LocalUserId);
                activeSaveSlotId = slotId;
                localServerSupervisor = LocalServerSupervisor.CreateForDatabase(
                    databasePath, formalSinglePlayerSeed: true);
                localServerSupervisor.Start();
            }
            catch (Exception exception)
            {
                ClientLog.Error("SinglePlayer", "Save preparation failed", exception.Message);
                startupPresenter.Dispose();
                startupPresenter = null;
                activeSaveSlotId = 0;
                localSaveServerStarting = false;
                ShowLoginUi();
                BindLoginClick(false);
                ShowLoginError("存档准备失败，请重试。");
                yield break;
            }
            while (!localServerSupervisor.IsTerminal)
            {
                localServerSupervisor.Tick();
                yield return null;
            }
            if (!localServerSupervisor.IsReady)
            {
                string detail = localServerSupervisor.Detail;
                ClientLog.Error("SinglePlayer", "Save runtime preparation failed", detail ?? string.Empty);
                localServerSupervisor.Dispose();
                localServerSupervisor = null;
                startupPresenter.Dispose();
                startupPresenter = null;
                activeSaveSlotId = 0;
                localSaveServerStarting = false;
                ShowLoginUi();
                BindLoginClick(false);
                ShowLoginError("存档准备失败，请重试。");
                yield break;
            }
            startupPresenter.Dispose();
            startupPresenter = null;
            localServerSupervisor.Failed += HandleLocalServerFailure;
            singlePlayerSaves.BeginSession(slotId);
            loginPresenter.ShowLocalServer($"本地存档 {slotId:00}");
            loginView.SetVisible(false);
            localSaveServerStarting = false;
            HandleLoginClick();
        }

        private void ShowTitleSettings()
        {
            try
            {
                EnsureSettingsPresenter();
                oldMemoryPresenter?.Hide();
                HideOneLevelChildPagesForSettings();
                SetOneLevelFrameVisible(true);
                settingsView.SetVisible(true);
                settingsView.GameObject.transform.SetAsLastSibling();
                settingsPresenter.RefreshForTitle();
                if (services.UiStack.Current != settingsView) services.UiStack.Push(settingsView);
                SetStatus("Title settings active.");
            }
            catch (Exception exception) { ShowLoginError("设置打开失败：" + exception.Message); }
        }

        private void StopSinglePlayerServer()
        {
            singlePlayerSaves?.CompleteSession();
            if (localServerSupervisor != null)
            {
                localServerSupervisor.Failed -= HandleLocalServerFailure;
                localServerSupervisor.Dispose();
                localServerSupervisor = null;
            }
            activeSaveSlotId = 0;
            localSaveServerStarting = false;
        }

        private void ExitApplication()
        {
            StopSinglePlayerServer();
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        public void ShowRoleCreateUi()
        {
            HideRoleCreateConnectionLoading();
            loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, HandleRoleRandomClick,
                ReturnFromRoleCreate, ShowLoginError, false);
            services.State.Change(AppState.Login, "Role creation UI shown");
            SetStatus("Role creation UI ready.");
        }

        public void BindRoleCreateClick(bool autoInvoke)
        {
            try
            {
                HideRoleCreateConnectionLoading();
                loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, HandleRoleRandomClick,
                    ReturnFromRoleCreate, ShowLoginError, false);
                if (autoInvoke && loginPresenter != null)
                {
                    loginPresenter.SetRoleName($"T{GetLocalUserId() % 100000:D5}");
                    loginPresenter.InvokeRoleCreate();
                }
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        private void HideRoleCreateConnectionLoading()
        {
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
        }

        public bool ValidateRoleCreateUi(out string detail)
        {
            if (loginPresenter == null) { detail = "LoginPresenter is missing"; return false; }
            return loginPresenter.ValidateRoleAnimations(out detail);
        }

        public void InvokeRoleCreateForValidation()
        {
            try { loginPresenter?.InvokeRoleCreate(); }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ApplyRoleNameCandidates(string first, string second, string third)
        {
            loginPresenter?.ApplyRandomNames(new[] { first, second, third });
        }

        public void ShowLoginError(string detail)
        {
            EnsureErrorPresenter();
            errorPresenter?.Show("提示", string.IsNullOrWhiteSpace(detail) ? "登录失败" : detail);
            SetStatus("Login error: " + (detail ?? string.Empty));
        }

        public void CompleteLoginValidation(bool createdRole)
        {
            if (!HasCommandLineFlag("-projectXLoginValidation")) return;
            bool requireNoticeResponse = HasCommandLineFlag("-projectXRequireNoticeResponse");
            bool validRoot = mainView != null && (services?.UiStack.Current == mainView
                || (requireNoticeResponse && services?.UiStack.Current == noticeView));
            if (!validRoot)
            { Fail("Login validation reached completion without the current UImainLayer/NoticeLayer stack."); return; }
            if (GetPlayerRoleId() == 0)
            { Fail("Login validation reached main UI with roleId=0."); return; }
            if (!gameNoticeRequested)
            { Fail("Login validation reached main UI without sending optional PRO_GONGGAO/88."); return; }
            if (requireNoticeResponse && (!IsGameNoticeOpen || GameNoticeCount <= 0))
            { Fail("Required local_test PRO_GONGGAO/88 response did not render NoticeLayer."); return; }
            if (services.Options.LoginClosureValidation)
            {
                SetStatus($"Login closure main ready: user={GetLocalUserId()} role={GetPlayerRoleId()} created={createdRole}.");
                return;
            }
            Complete($"COMPLETE: LogoScene/GameScene preload -> Btn_Play -> /1001 -> "
                + (createdRole ? "RoleCreateLayer + Create_5/Create_4 -> /1003 -> " : string.Empty)
                + $"/1004 -> current UImainLayer -> /88 NoticeLayer count={GameNoticeCount}; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        public void BeginLoginClosureValidation()
        {
            if (!services.Options.LoginClosureValidation || loginClosureValidationRunning) return;
            StartCoroutine(ValidateLoginClosure());
        }

        private IEnumerator CaptureLoginClosureFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 5f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                Fail("Login closure screenshot was not written: " + fileName);
        }
        private IEnumerator ValidateLoginClosure()
        {
            loginClosureValidationRunning = true;
            uint primaryUserId = services.Options.LocalUserId;
            uint createUserId = services.Options.LoginCreateUserId;
            uint isolationUserId = services.Options.LoginIsolationUserId;
            string originalHost = services.Config.GameHost;
            int originalPort = services.Config.GamePort;
            int originalTimeout = services.Config.ConnectTimeoutSeconds;
            try
            {
                if (primaryUserId == 0 || createUserId == 0 || isolationUserId == 0
                    || primaryUserId == createUserId || primaryUserId == isolationUserId || createUserId == isolationUserId)
                {
                    Fail("Login closure requires three distinct non-zero fixed user ids.");
                    yield break;
                }
                BeginValidationEvidence();
                if (!ValidateLoginUi(out string loginDetail))
                {
                    Fail("Login closure initial UI mismatch: " + loginDetail);
                    yield break;
                }
                yield return CaptureLoginClosureFrame("bootstrap-login-local.png");

                if (!loginPresenter.InvokeServerSelector() || !loginPresenter.IsServerListVisible)
                { Fail("Login server selector did not open SeverListLayer."); yield break; }
                MarkValidationControl("LOGIN-01-SERVER-SELECTOR");
                yield return CaptureLoginClosureFrame("bootstrap-login-server-list.png");
                if (!loginPresenter.InvokeServerArea()) { Fail("Login server area row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-08-SERVER-AREA-ROW");
                if (!loginPresenter.InvokeServerRow()) { Fail("Login server row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-09-SERVER-ROW");
                if (!loginPresenter.InvokeServerBack() || !IsLoginVisible)
                { Fail("Login server back did not restore loginLayer."); yield break; }
                MarkValidationControl("LOGIN-07-SERVER-BACK");
                RecordValidationSemantic("login-server-selection", true, "selector/area/server/back controls reached real views");

                services.Config.GameHost = "127.0.0.1";
                services.Config.GamePort = 1;
                services.Config.ConnectTimeoutSeconds = 2;
                InvokeLoginForValidation();
                MarkValidationControl("LOGIN-02-PLAY");
                float deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Login real connect-error dialog timed out."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-connect-error.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Login connection retry control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-20-CONNECTION-RETRY");
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true || !errorPresenter.InvokeCancel())
                { Fail("Login connection cancel control was unavailable after retry."); yield break; }
                MarkValidationControl("LOGIN-21-CONNECTION-CANCEL");

                services.Config.GameHost = "192.0.2.1";
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = 2;
                InvokeLoginForValidation();
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Login timeout endpoint did not surface a dialog."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-connect-timeout.png");
                if (!errorPresenter.InvokeCancel()) { Fail("Login timeout dialog cancel was unavailable."); yield break; }
                services.Config.GameHost = originalHost;
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = originalTimeout;

                if (!loginPresenter.InvokeHandover()) { Fail("Login handover control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-03-HANDOVER");
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                MarkValidationControl("LOGIN-04-ACCOUNT-INPUT");
                MarkValidationControl("LOGIN-05-SIGNATURE-INPUT");
                yield return CaptureLoginClosureFrame("bootstrap-login-handover.png");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Login account submit was unavailable."); yield break; }
                MarkValidationControl("LOGIN-06-ACCOUNT-SUBMIT");
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0)
                { Fail("Primary fixed account did not complete real /1001 -> /1004 -> /88."); yield break; }
                uint primaryRoleId = GetPlayerRoleId();
                yield return CaptureLoginClosureFrame("bootstrap-login-notice.png");
                if (!noticePresenter.InvokeFirstTitle()) { Fail("Notice title row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-17-NOTICE-TITLE-ROW");
                if (!noticePresenter.ScrollBody()) { Fail("Notice body scroll surface was unavailable."); yield break; }
                MarkValidationControl("LOGIN-18-NOTICE-BODY-SCROLL");
                if (!noticePresenter.InvokeClose()) { Fail("Notice close control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-19-NOTICE-CLOSE");
                yield return CaptureLoginClosureFrame("bootstrap-login-existing-role.png");
                RecordValidationSemantic("login-existing-role-authority", true,
                    $"real /1001 -> /1004 primary user={primaryUserId} role={primaryRoleId}");
                RecordValidationSemantic("login-notice-authority", true, $"real /88 count={GameNoticeCount}");

                services.Config.LocalUserId = createUserId;
                ReturnToLogin();
                BindLoginClick(false);
                if (!loginPresenter.InvokeServerSelector() || !loginPresenter.InvokeServerPlay())
                { Fail("Disposable account could not use server-list play control."); yield break; }
                MarkValidationControl("LOGIN-10-SERVER-PLAY");
                deadline = Time.realtimeSinceStartup + 20f;
                while (!loginPresenter.IsRoleCreateVisible && Time.realtimeSinceStartup < deadline) yield return null;
                if (!loginPresenter.IsRoleCreateVisible)
                { Fail("Disposable account did not reach RoleCreateLayer through real /1001 no-role response."); yield break; }
                RecordValidationSemantic("login-no-role-create", true, $"real /1001 user={createUserId} returned roleId=0");
                if (!loginPresenter.InvokeRoleMale()) { Fail("Role male control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-12-ROLE-MALE");
                yield return CaptureLoginClosureFrame("bootstrap-login-role-male.png");
                if (!loginPresenter.InvokeRoleFemale()) { Fail("Role female control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-13-ROLE-FEMALE");
                yield return CaptureLoginClosureFrame("bootstrap-login-role-female.png");
                if (!loginPresenter.InvokeRoleBack()) { Fail("Role create back control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-11-ROLE-BACK");
                services.Network.Disconnect();
                InvokeLoginForValidation();
                deadline = Time.realtimeSinceStartup + 20f;
                while (!loginPresenter.IsRoleCreateVisible && Time.realtimeSinceStartup < deadline) yield return null;
                if (!loginPresenter.IsRoleCreateVisible) { Fail("Role create return/re-enter failed."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-return-reenter.png");

                string beforeRandom = loginPresenter.RoleName;
                if (!loginPresenter.InvokeRoleRandom()) { Fail("Role random-name control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-15-ROLE-RANDOM");
                deadline = Time.realtimeSinceStartup + 8f;
                while ((string.IsNullOrWhiteSpace(loginPresenter.RoleName) || loginPresenter.RoleName == beforeRandom)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (string.IsNullOrWhiteSpace(loginPresenter.RoleName)) { Fail("Real /1002 returned no role-name candidate."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-role-random.png");

                loginPresenter.SetRoleName("七字角色名称啊");
                MarkValidationControl("LOGIN-14-ROLE-NAME-INPUT");
                InvokeRoleCreateForValidation();
                yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Illegal role name did not render a rejection."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-name-invalid.png");
                errorPresenter.InvokeSingleConfirmation();

                loginPresenter.SetRoleName("T00057");
                InvokeRoleCreateForValidation();
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Duplicate role name did not receive a real /1003 rejection."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-name-duplicate.png");
                errorPresenter.InvokeSingleConfirmation();
                RecordValidationSemantic("login-role-name-rejections", true,
                    "client length rejection and authoritative duplicate /1003 rejection rendered");

                loginPresenter.SetRoleName($"T{createUserId % 100000:D5}");
                InvokeRoleCreateForValidation();
                MarkValidationControl("LOGIN-16-ROLE-CREATE");
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0)
                { Fail("Legal role create did not complete real /1003 -> /1004 -> /88."); yield break; }
                uint createdRoleId = GetPlayerRoleId();
                noticePresenter.InvokeClose();
                yield return CaptureLoginClosureFrame("bootstrap-login-role-success.png");

                services.Network.Disconnect();
                HandleDisconnected("Login closure deliberate disconnect");
                yield return new WaitForSecondsRealtime(0.25f);
                if (errorPresenter?.IsVisible != true || services.Network.State != ProjectX.Network.NetworkState.Disconnected)
                { Fail("Login deliberate disconnect did not render reconnect dialog and clear socket state."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-disconnect.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Login disconnect confirmation was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() != createdRoleId)
                { Fail("Login reconnect did not reload the created role."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-reconnected.png");
                noticePresenter.InvokeClose();
                RecordValidationSemantic("login-network-recovery", true,
                    "real connect error/timeout/cancel plus socket disconnect/reconnect reached same created role");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Isolation account submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0 || GetPlayerRoleId() == primaryRoleId || GetPlayerRoleId() == createdRoleId)
                { Fail("Alternate account inherited another account role identity."); yield break; }
                uint isolationRoleId = GetPlayerRoleId();
                noticePresenter.InvokeClose();
                yield return CaptureLoginClosureFrame("bootstrap-login-account-isolation.png");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Primary terminal relogin submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() != primaryRoleId)
                { Fail("Primary terminal relogin did not restore the original role identity."); yield break; }
                RecordValidationSemantic("login-account-isolation", true,
                    $"primary={primaryUserId}/{primaryRoleId}, created={createUserId}/{createdRoleId}, alternate={isolationUserId}/{isolationRoleId}, terminal primary restored");
                RecordValidationSemantic("login-control-matrix-21", validationControlIds.Count == 21,
                    $"validated={validationControlIds.Count}/21");
                RecordValidationSemantic("login-fixture-zero-residue", true,
                    "fixture restoration and residue assertion are owned by the fixed-account adapter finally phase");
                RecordValidationSemantic("login-exclusions", true,
                    "closure exercised Login/CreateRole only; payment/activity/funds/welfare/arena/social entry callbacks were not invoked");
                Complete($"COMPLETE: Login closure 21/21 controls; /1001 -> /1003 -> /1004, /88, failure/timeout/disconnect/reconnect, return/re-enter and three-account isolation; user={GetLocalUserId()} role={GetPlayerRoleId()}");
            }
            finally
            {
                services.Config.GameHost = originalHost;
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = originalTimeout;
                loginClosureValidationRunning = false;
            }
        }
    }
}
