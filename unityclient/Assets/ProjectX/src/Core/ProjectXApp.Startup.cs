using System;
using System.Collections;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using XLua;

namespace ProjectX.Core
{
    public interface IRuntimeSnapshotContext
    {
        string AppStateName { get; }
        uint LocalUserId { get; }
        uint PlayerRoleId { get; }
        string PlayerName { get; }
        bool IsNetworkDisconnectedOrFaulted { get; }
        event Action<ProtocolPacketTrace> PacketObserved;
    }

    public sealed partial class ProjectXApp
    {
        public static event Action<GameObject, IRuntimeSnapshotContext> RuntimeServicesReady;

        private void InitializeApplication(AppLaunchOptions launchOptions)
        {
            try
            {
                Canvas canvas = FindObjectOfType<Canvas>();
                if (canvas == null) throw new InvalidOperationException("Startup Canvas was not found.");
                services = new GameServices(this, launchOptions, canvas.transform);
                RuntimeServicesReady?.Invoke(gameObject, services);
                // Keep every shared FirstClassBg/GoldCheck consumer synchronized while it remains open.
                services.Currencies.Changed += RefreshSharedCurrencyHeaders;
                // These validations intentionally drive every reconnect step and
                // assert the intermediate disconnected/login state.  A queued
                // automatic reconnect can otherwise race an account switch.
                if (services.Options.ManualReconnectValidation || services.Options.ScenarioManagedReconnect
                    || services.Options.GameplayValidation || services.Options.FishValidation
                    || services.Options.DrawClosureValidation || services.Options.WorldBattleValidation)
                    services.Config.AutoReconnect = false;
                services.Network.StateChanged += HandleNetworkState;
                services.Network.Disconnected += HandleDisconnected;
                services.Protocols.UnhandledPacket += DispatchToLua;
                services.ProtocolRegistry.RequestTimedOut += HandleRequestTimeout;
                services.Lua.ExecuteResource("Lua/Bootstrap", "Bootstrap.lua");
                onConnected = services.Lua.GetFunction("OnConnected");
                onDisconnected = services.Lua.GetFunction("OnDisconnected");
                onPacket = services.Lua.GetFunction("OnPacket");
                onLoginClicked = services.Lua.GetFunction("OnLoginClicked");
                onRoleCreateClicked = services.Lua.GetFunction("OnRoleCreateClicked");
                onRoleRandomClicked = services.Lua.GetFunction("OnRoleRandomClicked");
                onBagClicked = services.Lua.GetFunction("OnBagClicked");
                onBagUseClicked = services.Lua.GetFunction("OnBagUseClicked");
                onSettingsClicked = services.Lua.GetFunction("OnSettingsClicked");
                onTaskClicked = services.Lua.GetFunction("OnTaskClicked");
                onTaskClaimClicked = services.Lua.GetFunction("OnTaskClaimClicked");
                onXunBaoTaskClicked = services.Lua.GetFunction("OnXunBaoTaskClicked");
                onHeroClicked = services.Lua.GetFunction("OnHeroClicked");
                onHeroSelected = services.Lua.GetFunction("OnHeroSelected");
                onHeroLevelUp = services.Lua.GetFunction("OnHeroLevelUp");
                onHeroAutoLevelUp = services.Lua.GetFunction("OnHeroAutoLevelUp");
                onHeroBreakUp = services.Lua.GetFunction("OnHeroBreakUp");
                onHeroCultivate = services.Lua.GetFunction("OnHeroCultivate");
                onHeroStarUp = services.Lua.GetFunction("OnHeroStarUp");
                onHeroCultivationActivate = services.Lua.GetFunction("OnHeroCultivationActivate");
                onHeroCompose = services.Lua.GetFunction("OnHeroCompose");
                onHeroRebirthPreview = services.Lua.GetFunction("OnHeroRebirthPreview");
                onHeroRebirthConfirm = services.Lua.GetFunction("OnHeroRebirthConfirm");
                onHeroBookOpened = services.Lua.GetFunction("OnHeroBookOpened");
                onHeroBookUpgrade = services.Lua.GetFunction("OnHeroBookUpgrade");
                onFormationMove = services.Lua.GetFunction("OnFormationMove");
                onFormationSwap = services.Lua.GetFunction("OnFormationSwap");
                onFormationUpgrade = services.Lua.GetFunction("OnFormationUpgrade");
                onFormationUse = services.Lua.GetFunction("OnFormationUse");
                onHeroEquipmentWear = services.Lua.GetFunction("OnHeroEquipmentWear");
                onEquipmentBagClicked = services.Lua.GetFunction("OnEquipmentBagClicked");
                onFaBaoBagClicked = services.Lua.GetFunction("OnFaBaoBagClicked");
                onHeroEquipmentTakeOff = services.Lua.GetFunction("OnHeroEquipmentTakeOff");
                onHeroEquipmentAffixLock = services.Lua.GetFunction("OnHeroEquipmentAffixLock");
                onHeroEquipmentAffixReroll = services.Lua.GetFunction("OnHeroEquipmentAffixReroll");
                onHeroEquipmentStrength = services.Lua.GetFunction("OnHeroEquipmentStrength");
                onHeroEquipmentStrengthAll = services.Lua.GetFunction("OnHeroEquipmentStrengthAll");
                onHeroEquipmentRefine = services.Lua.GetFunction("OnHeroEquipmentRefine");
                onHeroEquipmentAutoRefine = services.Lua.GetFunction("OnHeroEquipmentAutoRefine");
                onHeroEquipmentAwaken = services.Lua.GetFunction("OnHeroEquipmentAwaken");
                onHeroEquipmentDivine = services.Lua.GetFunction("OnHeroEquipmentDivine");
                onHeroEquipmentCompose = services.Lua.GetFunction("OnHeroEquipmentCompose");
                onFaBaoWear = services.Lua.GetFunction("OnFaBaoWear");
                onFaBaoTakeOff = services.Lua.GetFunction("OnFaBaoTakeOff");
                onFaBaoStrength = services.Lua.GetFunction("OnFaBaoStrength");
                onFaBaoRefine = services.Lua.GetFunction("OnFaBaoRefine");
                onEnhanceMasterOpened = services.Lua.GetFunction("OnEnhanceMasterOpened");
                onMailClicked = services.Lua.GetFunction("OnMailClicked");
                onMailClaimClicked = services.Lua.GetFunction("OnMailClaimClicked");
                onMailReadClicked = services.Lua.GetFunction("OnMailReadClicked");
                onMailDeleteClicked = services.Lua.GetFunction("OnMailDeleteClicked");
                onMailClaimAllClicked = services.Lua.GetFunction("OnMailClaimAllClicked");
                onMailDeleteAllClicked = services.Lua.GetFunction("OnMailDeleteAllClicked");
                onMailValidationClaim = services.Lua.GetFunction("OnMailValidationClaim");
                onMailValidationClaimAll = services.Lua.GetFunction("OnMailValidationClaimAll");
                onMailValidationReadAll = services.Lua.GetFunction("OnMailValidationReadAll");
                onMailValidationRepeat = services.Lua.GetFunction("OnMailValidationRepeat");
                onShopClicked = services.Lua.GetFunction("OnShopClicked");
                onShopBuyConfirmed = services.Lua.GetFunction("OnShopBuyConfirmed");
                onShopRefreshRequested = services.Lua.GetFunction("OnShopRefreshRequested");
                onShopCountRequested = services.Lua.GetFunction("OnShopCountRequested");
                onShopRequestTimeout = services.Lua.GetFunction("OnShopRequestTimeout");
                onShopValidationRefresh = services.Lua.GetFunction("OnShopValidationRefresh");
                onShopValidationCount = services.Lua.GetFunction("OnShopValidationCount");
                onShopValidationFailure = services.Lua.GetFunction("OnShopValidationFailure");
                onShopValidationSuccess = services.Lua.GetFunction("OnShopValidationSuccess");
                onGameplayShopOpened = services.Lua.GetFunction("OnGameplayShopOpened");
                onGameplayShopTab = services.Lua.GetFunction("OnGameplayShopTab");
                onGameplayShopBuy = services.Lua.GetFunction("OnGameplayShopBuy");
                onGameplayShopRefresh = services.Lua.GetFunction("OnGameplayShopRefresh");
                onGameplayShopCount = services.Lua.GetFunction("OnGameplayShopCount");
                onGameplayShopRequestTimeout = services.Lua.GetFunction("OnGameplayShopRequestTimeout");
                onFriendClicked = services.Lua.GetFunction("OnFriendClicked");
                onFriendRequestList = services.Lua.GetFunction("OnFriendRequestList");
                onFriendRequestApplications = services.Lua.GetFunction("OnFriendRequestApplications");
                onFriendApply = services.Lua.GetFunction("OnFriendApply");
                onFriendDeal = services.Lua.GetFunction("OnFriendDeal");
                onFriendDelete = services.Lua.GetFunction("OnFriendDelete");
                onChatClicked = services.Lua.GetFunction("OnChatClicked");
                onChatSend = services.Lua.GetFunction("OnChatSend");
                onTeamClicked = services.Lua.GetFunction("OnTeamClicked");
                onTeamCreate = services.Lua.GetFunction("OnTeamCreate");
                onTeamInvite = services.Lua.GetFunction("OnTeamInvite");
                onTeamRespond = services.Lua.GetFunction("OnTeamRespond");
                onTeamLeave = services.Lua.GetFunction("OnTeamLeave");
                onGuildClicked = services.Lua.GetFunction("OnGuildClicked");
                onGuildCreate = services.Lua.GetFunction("OnGuildCreate");
                onGuildRequestMembers = services.Lua.GetFunction("OnGuildRequestMembers");
                onGuildLeave = services.Lua.GetFunction("OnGuildLeave");
                onWorldClicked = services.Lua.GetFunction("OnWorldClicked");
                onWorldRequestChapter = services.Lua.GetFunction("OnWorldRequestChapter");
                onWorldRequestStage = services.Lua.GetFunction("OnWorldRequestStage");
                onWorldOpenPreferredStage = services.Lua.GetFunction("OnWorldOpenPreferredStage");
                onWorldChallenge = services.Lua.GetFunction("OnWorldChallenge");
                onWorldSweep = services.Lua.GetFunction("OnWorldSweep");
                onWorldReset = services.Lua.GetFunction("OnWorldReset");
                onWorldClaimBox = services.Lua.GetFunction("OnWorldClaimBox");
                onWorldAchievementRequest = services.Lua.GetFunction("OnWorldAchievementRequest");
                onWorldAchievementClaim = services.Lua.GetFunction("OnWorldAchievementClaim");
                onWorldRefresh = services.Lua.GetFunction("OnWorldRefresh");
                onWorldValidateIsolation = services.Lua.GetFunction("OnWorldValidateIsolation");
                onWorldSetChainAuto = services.Lua.GetFunction("OnWorldSetChainAuto");
                onWorldSetChainAutoNext = services.Lua.GetFunction("OnWorldSetChainAutoNext");
                onWorldContinueChain = services.Lua.GetFunction("OnWorldContinueChain");
                onWorldCancelChain = services.Lua.GetFunction("OnWorldCancelChain");
                onWorldRestartChain = services.Lua.GetFunction("OnWorldRestartChain");
                onWelfareClicked = services.Lua.GetFunction("OnWelfareClicked");
                onWelfareClaimSign = services.Lua.GetFunction("OnWelfareClaimSign");
                onActivityClicked = services.Lua.GetFunction("OnActivityClicked");
                onActivitySelected = services.Lua.GetFunction("OnActivitySelected");
                onDrawClicked = services.Lua.GetFunction("OnDrawClicked");
                onDrawRequested = services.Lua.GetFunction("OnDrawRequested");
                onDrawClosureBagRefresh = services.Lua.GetFunction("OnDrawClosureBagRefresh");
                onDrawClosurePrepareMount = services.Lua.GetFunction("OnDrawClosurePrepareMount");
                onDrawClosurePrepareReconnect = services.Lua.GetFunction("OnDrawClosurePrepareReconnect");
                onDrawClosurePrepareAccountIsolation = services.Lua.GetFunction("OnDrawClosurePrepareAccountIsolation");
                onGameplayClicked = services.Lua.GetFunction("OnGameplayClicked");
                onGameplayEntered = services.Lua.GetFunction("OnGameplayEntered");
                onSharedGameplayHotPointRefresh = services.Lua.GetFunction("OnSharedGameplayHotPointRefresh");
                onYouLiClicked = services.Lua.GetFunction("OnYouLiClicked");
                onYouLiStart = services.Lua.GetFunction("OnYouLiStart");
                onYouLiStartBatch = services.Lua.GetFunction("OnYouLiStartBatch");
                onYouLiClaim = services.Lua.GetFunction("OnYouLiClaim");
                onFengShenStoryClicked = services.Lua.GetFunction("OnFengShenStoryClicked");
                onFengShenStoryChallengeClicked = services.Lua.GetFunction("OnFengShenStoryChallengeClicked");
                onArenaClicked = services.Lua.GetFunction("OnArenaClicked");
                onKunLunClicked = services.Lua.GetFunction("OnKunLunClicked");
                onBloodFightClicked = services.Lua.GetFunction("OnBloodFightClicked");
                onXunBaoClicked = services.Lua.GetFunction("OnXunBaoClicked");
                onXunBaoSearch = services.Lua.GetFunction("OnXunBaoSearch");
                onXunBaoSearchAll = services.Lua.GetFunction("OnXunBaoSearchAll");
                onXunBaoCompose = services.Lua.GetFunction("OnXunBaoCompose");
                onXunBaoComposeAll = services.Lua.GetFunction("OnXunBaoComposeAll");
                onXunBaoSearchTokenBagRequested = services.Lua.GetFunction("OnXunBaoSearchTokenBagRequested");
                onSevenDayClicked = services.Lua.GetFunction("OnSevenDayClicked");
                onSevenDayClaim = services.Lua.GetFunction("OnSevenDayClaim");
                onMoneyTreeClicked = services.Lua.GetFunction("OnMoneyTreeClicked");
                onMoneyTreeShake = services.Lua.GetFunction("OnMoneyTreeShake");
                onFishClicked = services.Lua.GetFunction("OnFishClicked");
                onFishStart = services.Lua.GetFunction("OnFishStart");
                onFishStop = services.Lua.GetFunction("OnFishStop");
                onFishCollect = services.Lua.GetFunction("OnFishCollect");
                onFishExit = services.Lua.GetFunction("OnFishExit");
                onAnswerClicked = services.Lua.GetFunction("OnAnswerClicked");
                onAnswerSelected = services.Lua.GetFunction("OnAnswerSelected");
                onAnswerNextRequested = services.Lua.GetFunction("OnAnswerNextRequested");
                onJingJieClicked = services.Lua.GetFunction("OnJingJieClicked");
                onJingJieUpgrade = services.Lua.GetFunction("OnJingJieUpgrade");
                onMonopolyClicked = services.Lua.GetFunction("OnMonopolyClicked");
                onMonopolyRoll = services.Lua.GetFunction("OnMonopolyRoll");
                onMonopolyMoveEnd = services.Lua.GetFunction("OnMonopolyMoveEnd");
                onMonopolyReset = services.Lua.GetFunction("OnMonopolyReset");
                onMonopolyQueryBuy = services.Lua.GetFunction("OnMonopolyQueryBuy");
                onMonopolyBuyRoll = services.Lua.GetFunction("OnMonopolyBuyRoll");
                onMonopolyFightGuard = services.Lua.GetFunction("OnMonopolyFightGuard");
                onMonopolyPlayHand = services.Lua.GetFunction("OnMonopolyPlayHand");
                onMonopolyClose = services.Lua.GetFunction("OnMonopolyClose");
                onHappyWheelClicked = services.Lua.GetFunction("OnHappyWheelClicked");
                onHappyWheelSpin = services.Lua.GetFunction("OnHappyWheelSpin");
                onStaminaClaimClicked = services.Lua.GetFunction("OnStaminaClaimClicked");
                onStaminaClaimRequest = services.Lua.GetFunction("OnStaminaClaimRequest");
                onStaminaClaimRefresh = services.Lua.GetFunction("OnStaminaClaimRefresh");
                onResourceRecoveryClicked = services.Lua.GetFunction("OnResourceRecoveryClicked");
                onFundsClicked = services.Lua.GetFunction("OnFundsClicked");
                StartCoroutine(RunCurrentCocosStartup());
            }
            catch (Exception exception)
            {
                Fail($"App bootstrap failed: {exception.Message}");
            }
        }

        private void OnDestroy()
        {
            ReleaseHeroAuxiliaryViews();
            DisposeJingJie();
            if (services != null)
                services.Currencies.Changed -= RefreshSharedCurrencyHeaders;
            if (heroEquipmentFragmentBagSubscribed && services != null)
            {
                services.Bag.Changed -= HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = false;
            }
            heroEquipmentFragmentList?.Dispose();
            heroEquipmentFragmentList = null;
            onConnected?.Dispose();
            onDisconnected?.Dispose();
            onPacket?.Dispose();
            onLoginClicked?.Dispose();
            onRoleCreateClicked?.Dispose();
            onRoleRandomClicked?.Dispose();
            onBagClicked?.Dispose();
            onBagUseClicked?.Dispose();
            onSettingsClicked?.Dispose();
            onTaskClicked?.Dispose();
            onTaskClaimClicked?.Dispose();
            onXunBaoTaskClicked?.Dispose();
            onHeroClicked?.Dispose();
            onHeroSelected?.Dispose();
            onHeroLevelUp?.Dispose();
            onHeroAutoLevelUp?.Dispose();
            onHeroBreakUp?.Dispose();
            onHeroCultivate?.Dispose();
            onHeroStarUp?.Dispose();
            onHeroCultivationActivate?.Dispose();
            onHeroCompose?.Dispose();
            onHeroRebirthPreview?.Dispose();
            onHeroRebirthConfirm?.Dispose();
            onHeroBookOpened?.Dispose();
            onHeroBookUpgrade?.Dispose();
            onFormationMove?.Dispose();
            onFormationSwap?.Dispose();
            onFormationUpgrade?.Dispose();
            onFormationUse?.Dispose();
            onHeroEquipmentWear?.Dispose();
            onEquipmentBagClicked?.Dispose();
            onFaBaoBagClicked?.Dispose();
            onHeroEquipmentTakeOff?.Dispose();
            onHeroEquipmentAffixLock?.Dispose();
            onHeroEquipmentAffixReroll?.Dispose();
            onHeroEquipmentStrength?.Dispose();
            onHeroEquipmentStrengthAll?.Dispose();
            onHeroEquipmentRefine?.Dispose();
            onHeroEquipmentAutoRefine?.Dispose();
            onHeroEquipmentAwaken?.Dispose();
            onHeroEquipmentDivine?.Dispose();
            onHeroEquipmentCompose?.Dispose();
            onFaBaoWear?.Dispose();
            onFaBaoTakeOff?.Dispose();
            onFaBaoStrength?.Dispose();
            onFaBaoRefine?.Dispose();
            onEnhanceMasterOpened?.Dispose();
            onMailClicked?.Dispose();
            onMailClaimClicked?.Dispose();
            onMailReadClicked?.Dispose();
            onMailDeleteClicked?.Dispose();
            onMailClaimAllClicked?.Dispose();
            onMailDeleteAllClicked?.Dispose();
            onMailValidationClaim?.Dispose();
            onMailValidationClaimAll?.Dispose();
            onMailValidationReadAll?.Dispose();
            onMailValidationRepeat?.Dispose();
            onShopClicked?.Dispose();
            onShopBuyConfirmed?.Dispose();
            onShopRefreshRequested?.Dispose();
            onShopCountRequested?.Dispose();
            onShopRequestTimeout?.Dispose();
            onShopValidationRefresh?.Dispose();
            onShopValidationCount?.Dispose();
            onShopValidationFailure?.Dispose();
            onShopValidationSuccess?.Dispose();
            onGameplayShopOpened?.Dispose();
            onGameplayShopTab?.Dispose();
            onGameplayShopBuy?.Dispose();
            onGameplayShopRefresh?.Dispose();
            onGameplayShopCount?.Dispose();
            onGameplayShopRequestTimeout?.Dispose();
            onFriendClicked?.Dispose();
            onFriendRequestList?.Dispose();
            onFriendRequestApplications?.Dispose();
            onFriendApply?.Dispose();
            onFriendDeal?.Dispose();
            onFriendDelete?.Dispose();
            onChatClicked?.Dispose();
            onChatSend?.Dispose();
            onTeamClicked?.Dispose();
            onTeamCreate?.Dispose();
            onTeamInvite?.Dispose();
            onTeamRespond?.Dispose();
            onTeamLeave?.Dispose();
            onGuildClicked?.Dispose();
            onGuildCreate?.Dispose();
            onGuildRequestMembers?.Dispose();
            onGuildLeave?.Dispose();
            onWorldClicked?.Dispose();
            onWorldRequestChapter?.Dispose();
            onWorldRequestStage?.Dispose();
            onWorldOpenPreferredStage?.Dispose();
            onWorldChallenge?.Dispose();
            onWorldSweep?.Dispose();
            onWorldReset?.Dispose();
            onWorldClaimBox?.Dispose();
            onWorldAchievementRequest?.Dispose();
            onWorldAchievementClaim?.Dispose();
            onWorldRefresh?.Dispose();
            onWorldValidateIsolation?.Dispose();
            onWorldSetChainAuto?.Dispose();
            onWorldSetChainAutoNext?.Dispose();
            onWorldContinueChain?.Dispose();
            onWorldCancelChain?.Dispose();
            onWorldRestartChain?.Dispose();
            onWelfareClicked?.Dispose();
            onWelfareClaimSign?.Dispose();
            onActivityClicked?.Dispose();
            onActivitySelected?.Dispose();
            onDrawClicked?.Dispose();
            onDrawRequested?.Dispose();
            onDrawClosureBagRefresh?.Dispose();
            onDrawClosurePrepareMount?.Dispose();
            onDrawClosurePrepareReconnect?.Dispose();
            onDrawClosurePrepareAccountIsolation?.Dispose();
            onGameplayClicked?.Dispose();
            onGameplayEntered?.Dispose();
            onSharedGameplayHotPointRefresh?.Dispose();
            onYouLiClicked?.Dispose();
            onYouLiStart?.Dispose();
            onYouLiStartBatch?.Dispose();
            onYouLiClaim?.Dispose();
            onFengShenStoryClicked?.Dispose();
            onFengShenStoryChallengeClicked?.Dispose();
            onArenaClicked?.Dispose();
            onKunLunClicked?.Dispose();
            onBloodFightClicked?.Dispose();
            onXunBaoClicked?.Dispose();
            onXunBaoSearch?.Dispose();
            onXunBaoSearchAll?.Dispose();
            onXunBaoCompose?.Dispose();
            onXunBaoComposeAll?.Dispose();
            onXunBaoSearchTokenBagRequested?.Dispose();
            onSevenDayClicked?.Dispose();
            onSevenDayClaim?.Dispose();
            onMoneyTreeClicked?.Dispose();
            onMoneyTreeShake?.Dispose();
            onFishClicked?.Dispose();
            onFishStart?.Dispose();
            onFishStop?.Dispose();
            onFishCollect?.Dispose();
            onFishExit?.Dispose();
            onAnswerClicked?.Dispose();
            onAnswerSelected?.Dispose();
            onAnswerNextRequested?.Dispose();
            onMonopolyClicked?.Dispose(); onMonopolyRoll?.Dispose(); onMonopolyMoveEnd?.Dispose(); onMonopolyReset?.Dispose();
            onMonopolyQueryBuy?.Dispose(); onMonopolyBuyRoll?.Dispose(); onMonopolyFightGuard?.Dispose(); onMonopolyClose?.Dispose();
            onMonopolyPlayHand?.Dispose();
            onHappyWheelClicked?.Dispose();
            onHappyWheelSpin?.Dispose();
            onStaminaClaimClicked?.Dispose();
            onStaminaClaimRequest?.Dispose();
            onStaminaClaimRefresh?.Dispose();
            onResourceRecoveryClicked?.Dispose();
            onFundsClicked?.Dispose();
            youLiPresenter?.Dispose();
            fengShenStoryPresenter?.Dispose();
            arenaPresenter?.Dispose();
            kunLunPresenter?.Dispose();
            bloodFightPresenter?.Dispose();
            xunBaoPresenter?.Dispose();
            xunBaoResultPresenter?.Dispose();
            xunBaoPopupPresenter?.Dispose();
            xunBaoComposeAllPresenter?.Dispose();
            sevenDayPresenter?.Dispose();
            moneyTreePresenter?.Dispose();
            fishPresenter?.Dispose();
            answerPresenter?.Dispose();
            monopolyPresenter?.Dispose();
            happyWheelPresenter?.Dispose();
            staminaClaimPresenter?.Dispose();
            resourceRecoveryPresenter?.Dispose();
            fundsPresenter?.Dispose();
            welfareActivityFramePresenter?.Dispose();
            gameplayShopsPresenter?.Dispose();
            bagPresenter?.Dispose();
            bagFlowPresenter?.Dispose();
            rewardPresenter?.Dispose();
            heroPresenter?.Dispose();
            heroCultivationPresenter?.Dispose();
            heroEquipmentPresenter?.Dispose();
            taskPresenter?.Dispose();
            mainTaskTracker?.Dispose();
            mainHudPresenter?.Dispose();
            loadingPresenter?.Dispose();
            toastPresenter?.Dispose();
            mailPresenter?.Dispose();
            shopPresenter?.Dispose();
            friendPresenter?.Dispose();
            chatPresenter?.Dispose();
            teamPresenter?.Dispose();
            guildPresenter?.Dispose();
            worldPresenter?.Dispose();
            worldOutcomePresenter?.Dispose();
            worldBattleWorldPresenter?.Dispose();
            fengShenBattlePlaybackPresenter?.Dispose();
            monopolyBattlePlaybackPresenter?.Dispose();
            UiPrefabLoader.Release(worldBattlePlaybackView);
            UiPrefabLoader.Release(fengShenBattlePlaybackView);
            UiPrefabLoader.Release(monopolyBattlePlaybackView);
            welfarePresenter?.Dispose();
            activityPresenter?.Dispose();
            drawPresenter?.Dispose();
            gameplayPresenter?.Dispose();
            youLiPresenter?.Dispose();
            startupPresenter?.Dispose();
            oldMemoryPresenter?.Dispose();
            loginPresenter?.Dispose();
            noticePresenter?.Dispose();
            singlePlayerSaves?.CompleteSession();
            services?.State.Change(AppState.ShuttingDown, "ProjectXApp destroyed");
            services?.Dispose();
            if (localServerSupervisor != null)
            {
                localServerSupervisor.Failed -= HandleLocalServerFailure;
                localServerSupervisor.Dispose();
                localServerSupervisor = null;
            }
            if (Instance == this) Instance = null;
        }


        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            AppLaunchOptions launchOptions = AppLaunchOptions.Current();
            singlePlayerTitleEnabled = ShouldUseSinglePlayerTitle(launchOptions);
            if (singlePlayerTitleEnabled)
            {
                singlePlayerSaves = new SinglePlayerSaveService(ResolveSinglePlayerSaveRoot());
                InitializeApplication(launchOptions);
                return;
            }
            if (LocalServerSupervisor.ShouldRun(launchOptions))
            {
                StartCoroutine(PrepareLocalServerThenInitialize(launchOptions));
                return;
            }
            InitializeApplication(launchOptions);
        }

        private static bool ShouldUseSinglePlayerTitle(AppLaunchOptions options)
        {
            if (Application.isBatchMode || options == null || options.Automation
                || options.HasFlag("-projectXExternalServer")) return false;
            string[] arguments = Environment.GetCommandLineArgs();
            if (arguments.Any(argument => string.Equals(argument,
                SinglePlayerFlowValidationFlag, StringComparison.OrdinalIgnoreCase))) return true;
            // Normal Editor feature validation uses the canonical LocalServer database.
            // Slot-based saves remain available only through the explicit flow-validation flag;
            // packaged non-Editor launches keep their one-click single-player default.
            if (Application.isEditor) return false;
            return !arguments.Any(argument =>
                argument != null && argument.StartsWith("-projectX", StringComparison.OrdinalIgnoreCase));
        }

        private static string ResolveSinglePlayerSaveRoot()
        {
            string[] arguments = Environment.GetCommandLineArgs();
            bool validation = arguments.Any(argument => string.Equals(argument,
                SinglePlayerFlowValidationFlag, StringComparison.OrdinalIgnoreCase));
            if (!validation) return Application.persistentDataPath;

            string argument = arguments.FirstOrDefault(value => value != null
                && value.StartsWith(SinglePlayerSaveRootPrefix, StringComparison.OrdinalIgnoreCase));
            string candidate = argument == null
                ? string.Empty
                : argument.Substring(SinglePlayerSaveRootPrefix.Length).Trim().Trim('"');
            if (string.IsNullOrWhiteSpace(candidate) || !Path.IsPathRooted(candidate))
            {
                throw new InvalidOperationException(
                    "Single-player flow validation requires an absolute isolated save root.");
            }
            return Path.GetFullPath(candidate);
        }

        private IEnumerator PrepareLocalServerThenInitialize(AppLaunchOptions launchOptions)
        {
            Canvas canvas = FindObjectOfType<Canvas>();
            if (canvas == null)
            {
                Fail("Startup Canvas was not found before local-server preparation.");
                yield break;
            }
            startupPresenter = new StartupPresenter(canvas);
            startupPresenter.ShowServerPreparation("正在准备本机游戏服务…");
            localServerSupervisor = LocalServerSupervisor.CreateDefault();
            localServerSupervisor.Start();
            while (!localServerSupervisor.IsTerminal)
            {
                localServerSupervisor.Tick();
                startupPresenter.ShowServerPreparation(localServerSupervisor.Detail);
                yield return null;
            }
            if (!localServerSupervisor.IsReady)
            {
                string detail = localServerSupervisor.Detail;
                status = detail;
                ClientLog.Error("App", detail);
                startupPresenter.ShowServerFailure(detail);
                yield break;
            }
            startupPresenter.Dispose();
            startupPresenter = null;
            localServerSupervisor.Failed += HandleLocalServerFailure;
            InitializeApplication(launchOptions);
        }

        private void Update()
        {
            localServerSupervisor?.Tick();
            services?.Tick();
            loadingPresenter?.Tick();
            MaintainHeroEquipmentCultivationState();
            toastPresenter?.Tick();
            shopPresenter?.Tick();
            gameplayShopsPresenter?.Tick();
            welfarePresenter?.Tick();
            activityPresenter?.Tick();
            drawPresenter?.Tick();
            happyWheelPresenter?.Tick(Time.unscaledDeltaTime);
            if (Input.GetKeyDown(KeyCode.Escape)) HandleBack();
        }

        private IEnumerator RunCurrentCocosStartup()
        {
            Canvas canvas = FindObjectOfType<Canvas>();
            if (canvas == null) { Fail("Startup Canvas was not found."); yield break; }
            startupPresenter = new StartupPresenter(canvas);
            SetStatus("LogoScene -> GameScene preload sequence.");
            yield return startupPresenter.Play();
            using (LuaFunction begin = services.Lua.GetFunction("Begin")) CallLua(begin, "Bootstrap.Begin");
        }

        private void HandleLocalServerFailure(string detail)
        {
            if (!singlePlayerTitleEnabled)
            {
                Fail(detail);
                return;
            }

            ClientLog.Error("SinglePlayer", "Local runtime stopped", detail ?? string.Empty);
            StopSinglePlayerServer();
            ShowLoginUi();
            BindLoginClick(false);
            ShowLoginError("当前回忆已中断，请重新进入。");
        }

        private void OnGUI()
        {
            if (!HasCommandLineFlag("-projectXDebugOverlay")) return;
            GUI.depth = -1000;
            GUI.Box(new Rect(12f, 12f, 700f, 54f), $"ProjectX App\n{status}");
            if (!string.IsNullOrEmpty(disconnectReason)
                && GUI.Button(new Rect(12f, 72f, 180f, 36f), "Reconnect"))
                Reconnect();
        }
    }
}
