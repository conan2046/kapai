using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.Foundation;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private bool intentionalLoginTransitionDisconnect;
        private Task singlePlayerSaveTask = Task.CompletedTask;
        private Task singlePlayerStopTask = Task.CompletedTask;
        private bool applicationDestroyed;
        private bool exitRequested;
        private bool quitAfterShutdown;
        private int singlePlayerPreparationVersion;

        private void HandleLoginClick() => InvokeLuaOrFail(onLoginClicked, "Login.OnLoginClicked");
        private void HandleRoleCreateClick() => InvokeLuaOrFail(onRoleCreateClicked, "Login.OnRoleCreateClicked");
        private void HandleRoleRandomClick() => InvokeLuaOrFail(onRoleRandomClicked, "Login.OnRoleRandomClicked");

        private void HandleAccountSubmit(uint userId, string signature)
        {
            services.Config.LocalUserId = userId;
            loginSignature = string.IsNullOrWhiteSpace(signature) ? "local" : signature;
            HandleLoginClick();
        }

        private void ReturnFromRoleCreate()
        {
            if (singlePlayerTitleEnabled)
            {
                DisconnectForLoginTransition();
                StopSinglePlayerServer();
                ShowLoginUi();
                BindLoginClick(false);
                return;
            }
            loginPresenter?.ShowLocalServer("本地测试服");
            services.UiStack.SetRoot(loginView);
            services.State.Change(AppState.Login, "Returned from role creation");
            SetStatus("Login UI ready.");
        }

        private void ShowLoginConnectionFailure(bool timedOut)
        {
            if (singlePlayerTitleEnabled)
            {
                ClientLog.Warning("SinglePlayer", timedOut
                    ? "Local save connection timed out"
                    : "Local save connection failed", disconnectReason ?? string.Empty);
                ReturnFromConnectionFailure();
                return;
            }

            EnsureErrorPresenter();
            string detail = timedOut
                ? "无法连接服务器,是否重新连接？\n连接已超时"
                : "无法连接服务器,是否重新连接？";
            errorPresenter?.ShowConfirmation("提示", detail,
                ReconnectFromConnectionFailure, "确认", "取消", false,
                ReturnFromConnectionFailure);
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            SetStatus(services.Options.PlayerHudValidation
                ? (timedOut ? "Player HUD reconnect timeout confirmation." : "Player HUD reconnect confirmation.")
                : services.Options.LoginClosureValidation
                    ? (timedOut ? "Login connection timeout dialog." : "Login connection dialog.")
                    : services.Options.GameplayValidation
                        ? (timedOut ? "Gameplay reconnect timeout confirmation." : "Gameplay reconnect confirmation.")
                        : services.Options.FengShenStoryValidation
                            ? (timedOut ? "FengShenStory reconnect timeout confirmation." : "FengShenStory reconnect confirmation.")
                            : services.Options.StaminaClaimValidation
                                ? (timedOut ? "StaminaClaim reconnect timeout confirmation." : "StaminaClaim reconnect confirmation.")
                                : (timedOut ? "Login connection timeout." : "Login connection failed."));
#else
            SetStatus(timedOut ? "Login connection timeout." : "Login connection failed.");
#endif
        }

        private void ReturnFromConnectionFailure()
        {
            DisconnectForLoginTransition();
            if (singlePlayerTitleEnabled) StopSinglePlayerServer();
            ShowLoginUi();
            BindLoginClick(false);
        }

        private void DisconnectForLoginTransition()
        {
            InvalidateConnectionOperations();
            intentionalLoginTransitionDisconnect = true;
            try { services.Network.Disconnect(); }
            finally { intentionalLoginTransitionDisconnect = false; }
        }

        private void ReconnectFromConnectionFailure()
        {
            mainHudPresenter?.BeginReconnectChatSummary();
            if (services.Network.State == NetworkState.Disconnected || services.Network.State == NetworkState.Faulted)
                Reconnect();
            else
                Connect(services.Config.GameHost, services.Config.GamePort);
        }

        private void HandleNetworkState(NetworkState state)
        {
            if (applicationDestroyed || exitRequested) return;
            SetStatus($"Network: {state}");
        }

        private void HandleDisconnected(string reason)
        {
            if (applicationDestroyed) return;
            if (CurrentAppState == AppState.Disconnected) return;
            bool preserveBagForScenario = false;
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            preserveBagForScenario = HasCommandLineFlag("-projectXBagG4Validation") && IsBagOpen;
#endif
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            services.ProtocolRegistry.ClearPending();
            ResetBattlePlaybackStateAfterDisconnect();
            disconnectReason = reason;
            services.State.Change(AppState.Disconnected, reason);
            SetStatus($"Disconnected: {reason}");
            try { CallLua(onDisconnected, "Network.OnDisconnected", reason); }
            catch (Exception exception) { Fail(exception.Message); }
            services.Heroes.Clear();
            services.Formation.Clear();
            if (!preserveBagForScenario)
            {
                services.Bag.Clear();
                bagFlowPresenter?.CloseAll();
            }
            services.Shop.Clear();
            shopPresenter?.ResetTransientState();
            services.GameplayShops.Clear();
            gameplayShopsPresenter?.ResetTransientState();
            services.World.Clear();
            services.FengShenStory.SetDisconnected();
            pendingFengShenRewards.Clear();
            deferredFengShenRewardPush = false;
            fengShenStoryPresenter?.CloseLevelPopup();
            fengShenStoryPresenter?.CloseModal();
            if (IsWorldOpen) services.UiStack.Pop();
            worldView?.SetVisible(false);
            worldStageView?.SetVisible(false);
            worldMapView?.SetVisible(false);
            worldDetailView?.SetVisible(false);
            worldSweepView?.SetVisible(false);
            worldBattleResultView?.SetVisible(false);
            worldBattleStatisticsView?.SetVisible(false);
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
            if (IsShopOpen) services.UiStack.Pop();
            shopView?.SetVisible(false);
            soulShopView?.SetVisible(false);
            multiShopView?.SetVisible(false);
            if (!preserveBagForScenario)
            {
                SetOneLevelFrameVisible(false);
                bagView?.SetVisible(false);
            }
            services.HeroEquipment.Clear();
            services.FaBao.Clear();
            services.EnhanceMasters.Clear();
            activeHeroCultivationId = 0;
            heroG4ControlValidationRunning = false;
            pendingHeroEquipmentPosition = 0;
            heroEquipmentOpenedFromHeroDetails = false;
            heroReplacementOpenedFromHeroHub = false;
            heroReplacementOpenedFromFormationPopup = false;
            pendingFunctionCultivationMode = -1;
            formationPopupView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            if (intentionalLoginTransitionDisconnect) return;
            if (singlePlayerTitleEnabled)
            {
                if (localServerSupervisor != null) ShowLoginConnectionFailure(false);
                return;
            }
            if (services.Config.AutoReconnect)
            {
                if (!autoReconnectRunning) _ = RunAutoReconnectAsync();
            }
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            else if (services.Options.ScenarioManagedReconnect || services.Options.ManualReconnectValidation
                || services.Options.GameplayValidation)
            {
                ShowLoginConnectionFailure(false);
            }
#endif
        }

        private async Task RunAutoReconnectAsync()
        {
            if (!services.Config.AutoReconnect) return;
            CancellationToken token = connectionOperations.Token;
            autoReconnectRunning = true;
            try
            {
                while (OwnsConnectionOperation(token) && services.Network.State != NetworkState.Connected
                    && reconnectAttempts < services.Config.MaxReconnectAttempts)
                {
                    reconnectAttempts++;
                    int backoffMultiplier = 1 << ((reconnectAttempts - 1) * 2);
                    int delayMilliseconds = Math.Min(
                        services.Config.ReconnectDelayMilliseconds * backoffMultiplier,
                        20000);
                    SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts} in {delayMilliseconds} ms...");
                    await Task.Delay(delayMilliseconds, token);
                    if (!OwnsConnectionOperation(token) || services.Network.State == NetworkState.Connected) return;
                    try
                    {
                        ShowLoading("auto-reconnect", "正在重新连接…", 25f);
                        SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts}...");
                        await services.Network.ReconnectAsync(services.Config.ConnectTimeoutSeconds, token);
                        if (!OwnsConnectionOperation(token) || !services.Network.IsConnected) return;
                        reconnectAttempts = 0;
                        disconnectReason = null;
                        services.State.Change(AppState.LoadingRole, "Auto reconnect succeeded");
                        CallLua(onConnected, "Login.OnConnected.AfterAutoReconnect");
                        return;
                    }
                    catch (Exception exception)
                    {
                        if (!OwnsConnectionOperation(token)) return;
                        HideLoading("auto-reconnect");
                        disconnectReason = exception.Message;
                        SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts} failed: {exception.Message}");
                    }
                }
            }
            catch (OperationCanceledException) { }
            finally
            {
                if (token == connectionOperations.Token) autoReconnectRunning = false;
            }
        }

        public void ReturnToLogin()
        {
            ResetBattlePlaybackStateAfterDisconnect();
            DisconnectForLoginTransition();
            if (singlePlayerTitleEnabled) StopSinglePlayerServer();
            mainHudPresenter?.Dispose();
            mainHudPresenter = null;
            mainTaskTracker?.Dispose();
            mainTaskTracker = null;
            services.Tasks.Clear();
            services.Player.Clear();
            services.Currencies.Clear();
            services.Bag.Clear();
            bagFlowPresenter?.CloseAll();
            services.Rewards.Clear();
            services.Mails.Clear();
            services.Shop.Clear();
            shopPresenter?.ResetTransientState();
            RestoreShopFramePanel();
            errorPresenter?.Hide();
            services.Friends.Clear();
            services.Heroes.Clear();
            services.Formation.Clear();
            services.HeroEquipment.Clear();
            services.FaBao.Clear();
            services.EnhanceMasters.Clear();
            activeHeroCultivationId = 0;
            pendingHeroEquipmentPosition = 0;
            heroEquipmentOpenedFromHeroDetails = false;
            heroEquipmentOpenedFromEnhanceMaster = false;
            heroReplacementOpenedFromHeroHub = false;
            heroReplacementOpenedFromFormationPopup = false;
            pendingFunctionCultivationMode = -1;
            pendingHeroEquipment.Clear();
            pendingFaBao.Clear();
            pendingCultivation.Clear();
            services.World.Clear();
            pendingFengShenRewards.Clear();
            deferredFengShenRewardPush = false;
            fengShenStoryPresenter?.CloseModal();
            services.Welfare.Clear();
            services.Activity.Clear();
            services.Draw.Clear();
            services.ServerTime.Reset();
            loadingPresenter?.Clear();
            toastPresenter?.Clear();
            rewardPresenter?.Hide();
            ShowLoginUi();
            if (singlePlayerTitleEnabled) BindLoginClick(false);
        }

        public void InitializePlayer(uint roleId, string name, int sex, int model, int head, int level,
            double experience, double power, int money, int premium, int boundPremium,
            uint potential, uint soul, int packageCapacity, uint guildContribution, bool createdRole)
        {
            loginCreatedRole = createdRole;
            services.Player.Initialize(roleId, name, unchecked((byte)sex), unchecked((byte)model),
                unchecked((byte)head), unchecked((ushort)level), checked((ulong)experience),
                checked((ulong)power), potential, soul, unchecked((ushort)packageCapacity));
            services.Currencies.Initialize(money, premium, boundPremium, soul, guildContribution);
            services.Mails.ConfigureAccount(roleId);
            if (singlePlayerTitleEnabled && activeSaveSlotId > 0)
            {
                singlePlayerSaves.UpdatePlayer(activeSaveSlotId, roleId, name, model, level, checked((ulong)power));
                if (singlePlayerSaves.ActiveSlotId != activeSaveSlotId)
                    singlePlayerSaves.BeginSession(activeSaveSlotId);
            }
        }

        public void ShowLoginUi()
        {
            loginView = services.UiAssets.GetUnityOrCreate("loginLayer");
            loginBackgroundView = services.UiAssets.GetUnityOrCreate("LoginBgLayer");
            loginServerListView = services.UiAssets.GetUnityOrCreate("SeverListLayer");
            roleCreateView = services.UiAssets.GetUnityOrCreate("RoleCreateLayer");
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
            bagFlowInputView?.SetVisible(false);
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
            if (loginView == null) { Fail("Login UI catalog entry 'loginLayer' could not be loaded."); return; }
            if (loginBackgroundView == null) { Fail("Login UI catalog entry 'LoginBgLayer' could not be loaded."); return; }
            // Account switching must restore an actual stack root. Leaving the
            // stack empty only happened to work for the first launch, and let a
            // deferred module callback hide the login layer during Draw G4.
            services.UiStack.SetRoot(loginView);
            loginPresenter = loginPresenter ?? new LoginPresenter(
                loginBackgroundView,
                loginView,
                loginServerListView,
                roleCreateView);
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
#if UNITY_EDITOR || DEVELOPMENT_BUILD
                if (autoInvoke || HasCommandLineFlag("-projectXS8StartupAcceptance")
                    || HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
#else
                if (autoInvoke)
#endif
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
            oldMemoryView = services.UiAssets.GetUnityOrCreate("OldMemoryLayer");
            if (oldMemoryView == null)
                throw new InvalidOperationException("Generated/OldMemoryLayer was not registered.");
            oldMemoryPresenter = new OldMemoryPresenter(oldMemoryView, singlePlayerSaves, services.Resources,
                BeginSinglePlayerSlot, SaveCurrentSinglePlayerSlot, CloseOldMemoryMenu,
                ShowTitleConfirmation, ShowLoginError, SetStatus);
        }

        private void CloseOldMemoryMenu()
        {
            if (oldMemoryPresenter?.IsSaving == true) return;
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

        private Task SaveCurrentSinglePlayerSlot(int targetSlotId)
        {
            if (applicationDestroyed || exitRequested || !singlePlayerSaveTask.IsCompleted
                || !singlePlayerStopTask.IsCompleted)
                throw new InvalidOperationException("存档保存或关闭正在进行，请稍候。");
            singlePlayerSaveTask = SaveCurrentSinglePlayerSlotAsync(targetSlotId);
            return singlePlayerSaveTask;
        }

        private async Task SaveCurrentSinglePlayerSlotAsync(int targetSlotId)
        {
            if (activeSaveSlotId <= 0 || singlePlayerSaves?.ActiveSlotId != activeSaveSlotId
                || localServerSupervisor?.IsReady != true || !services.Player.IsLoaded)
                throw new InvalidOperationException("当前游戏尚未进入可保存状态。");

            LocalServerSupervisor supervisor = localServerSupervisor;
            SinglePlayerSaveService saves = singlePlayerSaves;
            int sourceSlotId = activeSaveSlotId;
            uint roleId = services.Player.RoleId;
            string roleName = services.Player.Name;
            int model = services.Player.Model;
            int level = services.Player.Level;
            ulong power = services.Player.Power;
            string stagingPath = saves.CreateSnapshotStagingPath(targetSlotId);
            try
            {
                await supervisor.CreateSnapshotAsync(stagingPath);
                if (targetSlotId == sourceSlotId)
                {
                    saves.DiscardSnapshotStaging(stagingPath);
                    saves.UpdatePlayer(sourceSlotId, roleId, roleName, model, level, power);
                }
                else
                {
                    saves.CommitCurrentSnapshot(sourceSlotId, targetSlotId, stagingPath,
                        roleId, roleName, model, level, power);
                }
                if (this && !applicationDestroyed && !exitRequested && localServerSupervisor == supervisor)
                    SetStatus($"当前进度已保存到存档 {targetSlotId:00}。");
            }
            catch (Exception exception)
            {
                try { saves.DiscardSnapshotStaging(stagingPath); }
                catch { }
                ClientLog.Error("SinglePlayer", "Save current snapshot failed", exception.Message);
                throw new InvalidOperationException("保存当前进度失败，请重试。", exception);
            }
        }

        private void ShowTitleConfirmation(string heading, string detail, Action confirmed)
        {
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation(heading, detail, confirmed);
        }

        private void BeginSinglePlayerSlot(int slotId, bool startNew)
        {
            if (localSaveServerStarting || applicationDestroyed || exitRequested || !singlePlayerSaveTask.IsCompleted
                || localServerSupervisor != null) return;
            StartCoroutine(PrepareSinglePlayerSlotThenLogin(slotId, startNew, ++singlePlayerPreparationVersion));
        }

        private IEnumerator PrepareSinglePlayerSlotThenLogin(int slotId, bool startNew, int version)
        {
            localSaveServerStarting = true;
            while (!singlePlayerStopTask.IsCompleted) yield return null;
            if (!this || applicationDestroyed || exitRequested || version != singlePlayerPreparationVersion) yield break;
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
            startupPresenter = new StartupPresenter(
                services.UiAssets.GetUnityOrCreate("StartupLayer", canvas.transform));
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
                StopSinglePlayerServer();
                ShowLoginUi();
                BindLoginClick(false);
                ShowLoginError("存档准备失败，请重试。");
                yield break;
            }
            LocalServerSupervisor preparedSupervisor = localServerSupervisor;
            while (localServerSupervisor == preparedSupervisor && !preparedSupervisor.IsTerminal)
            {
                preparedSupervisor.Tick();
                yield return null;
            }
            if (!this || applicationDestroyed || exitRequested || version != singlePlayerPreparationVersion
                || localServerSupervisor != preparedSupervisor) yield break;
            if (!localServerSupervisor.IsReady)
            {
                string detail = localServerSupervisor.Detail;
                ClientLog.Error("SinglePlayer", "Save runtime preparation failed", detail ?? string.Empty);
                StopSinglePlayerServer();
                while (!singlePlayerStopTask.IsCompleted) yield return null;
                if (!this || applicationDestroyed || exitRequested) yield break;
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
            singlePlayerPreparationVersion++;
            localSaveServerStarting = false;
            if (!singlePlayerStopTask.IsCompleted) return;
            LocalServerSupervisor supervisor = localServerSupervisor;
            localServerSupervisor = null;
            activeSaveSlotId = 0;
            localSaveServerStarting = false;
            if (supervisor != null) supervisor.Failed -= HandleLocalServerFailure;
            singlePlayerStopTask = StopSinglePlayerServerAsync(supervisor, singlePlayerSaves, singlePlayerSaveTask);
        }

        private static async Task StopSinglePlayerServerAsync(LocalServerSupervisor supervisor,
            SinglePlayerSaveService saves, Task pendingSave)
        {
            // Accepted saves finish their existing staging/commit transaction before shutdown.
            try { await pendingSave; }
            catch (Exception exception) { ClientLog.Error("SinglePlayer", "待完成的保存失败，继续关闭会话。", exception.ToString()); }
            Exception[] errors = CleanupSequence.Run(() => saves?.CompleteSession());
            try
            {
                if (supervisor != null) await supervisor.DisposeAsync();
                saves?.DiscardPendingCreation();
            }
            catch (Exception exception) { ClientLog.Error("SinglePlayer", "本机服务关闭失败。", exception.ToString()); }
            foreach (Exception error in errors)
                ClientLog.Error("SinglePlayer", "结束存档会话时发生错误，已继续执行清理。", error.ToString());
        }

        private async void ExitApplication()
        {
            if (exitRequested) return;
            exitRequested = true;
            if (services != null) DisconnectForLoginTransition();
            StopSinglePlayerServer();
            await singlePlayerStopTask;
            // Even an already-finished shutdown must return from wantsToQuit before requesting quit again.
            await Task.Yield();
            if (!this || applicationDestroyed) return;
            quitAfterShutdown = true;
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        private bool WaitForSinglePlayerShutdownBeforeQuit()
        {
            if (quitAfterShutdown || !singlePlayerTitleEnabled || applicationDestroyed) return true;
            ExitApplication();
            return false;
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

    }
}
