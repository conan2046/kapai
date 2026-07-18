using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.LuaRuntime;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace ProjectX.Core
{
    [LuaCallCSharp]
    public sealed class ProjectXApp : MonoBehaviour
    {
        public const string LoginButtonPath = "Layer/Login/Btn_Play";
        public const string LoginServerButtonPath = "Layer/Login/Btn_Sever";
        public const string BagPath = "Layer/Main_UI/ButtonGroup1/btn_Bag";
        public const string SettingsPath = "Layer/Main_UI/ButtonGroup7/btn_xitong";
        public const string TaskPath = "Layer/Main_UI/ButtonGroup5/btn_renwu";
        public const string HeroPath = "Layer/Main_UI/ButtonGroup1/btn_zhenrong";
        public const string MailPath = "Layer/Main_UI/ButtonGroup7/btn_mail";
        public const string ShopPath = "Layer/Main_UI/ButtonGroup5/btn_shangcheng";
        public const string ShopSubmenuPath = "Layer/Main_UI/tankuang1/btn_shangcheng";
        public const string FriendPath = "Layer/Main_UI/ButtonGroup7/btn_friend";
        public const string ChatPath = "Layer/Main_UI/ShortcutButtonGroup/Chat";
        public const string TeamLegacyPath = "Layer/Main_UI/Panel_QuestAndTeam/CheckBox_Team";
        public const string GuildPath = "Layer/Main_UI/ButtonGroup3/btn_bangpai";
        public const string WorldPath = "Layer/Main_UI/btn_fuben";
        public const string WelfareLegacyPath = "Layer/Main_UI/ButtonGroup8/btn_fuli";

        private GameServices services;
        private LuaFunction onConnected;
        private LuaFunction onDisconnected;
        private LuaFunction onPacket;
        private LuaFunction onLoginClicked;
        private LuaFunction onRoleCreateClicked;
        private LuaFunction onBagClicked;
        private LuaFunction onBagUseClicked;
        private LuaFunction onSettingsClicked;
        private LuaFunction onTaskClicked;
        private LuaFunction onTaskClaimClicked;
        private LuaFunction onHeroClicked;
        private LuaFunction onHeroEquipmentWear;
        private LuaFunction onHeroEquipmentTakeOff;
        private LuaFunction onFaBaoWear;
        private LuaFunction onFaBaoTakeOff;
        private LuaFunction onMailClicked;
        private LuaFunction onMailClaimClicked;
        private LuaFunction onShopClicked;
        private LuaFunction onShopBuyConfirmed;
        private LuaFunction onFriendClicked;
        private LuaFunction onFriendRequestList;
        private LuaFunction onFriendRequestApplications;
        private LuaFunction onFriendApply;
        private LuaFunction onFriendDeal;
        private LuaFunction onFriendDelete;
        private LuaFunction onChatClicked;
        private LuaFunction onChatSend;
        private LuaFunction onTeamClicked;
        private LuaFunction onTeamCreate;
        private LuaFunction onTeamInvite;
        private LuaFunction onTeamRespond;
        private LuaFunction onTeamLeave;
        private LuaFunction onGuildClicked;
        private LuaFunction onGuildCreate;
        private LuaFunction onGuildRequestMembers;
        private LuaFunction onGuildLeave;
        private LuaFunction onWorldClicked;
        private LuaFunction onWorldRequestChapter;
        private LuaFunction onWorldRequestStage;
        private LuaFunction onWorldOpenPreferredStage;
        private LuaFunction onWorldChallenge;
        private LuaFunction onWorldRefresh;
        private LuaFunction onWelfareClicked;
        private LuaFunction onWelfareClaimSign;
        private CocosUiView loginBackgroundView;
        private CocosUiView loginView;
        private CocosUiView loginServerListView;
        private CocosUiView roleCreateView;
        private CocosUiView noticeView;
        private StartupPresenter startupPresenter;
        private LoginPresenter loginPresenter;
        private NoticePresenter noticePresenter;
        private readonly List<NoticeRecord> pendingGameNotices = new List<NoticeRecord>();
        private bool gameNoticeRequested;
        private CocosUiView mainView;
        private CocosUiView bagView;
        private BagPresenter bagPresenter;
        private readonly List<BagItemRecord> pendingBagItems = new List<BagItemRecord>();
        private CocosUiView rewardView;
        private RewardPresenter rewardPresenter;
        private readonly List<RewardRecord> pendingRewards = new List<RewardRecord>();
        private CocosUiView heroListView;
        private CocosUiView heroDetailView;
        private HeroPresenter heroPresenter;
        private readonly List<HeroRecord> pendingHeroes = new List<HeroRecord>();
        private readonly List<FormationRecord> pendingFormations = new List<FormationRecord>();
        private readonly List<int> pendingFormationDisplay = new List<int>();
        private readonly List<int> pendingFormationCombat = new List<int>();
        private int pendingActiveFormationId;
        private CocosUiView heroEquipmentListView;
        private CocosUiView heroEquipmentDetailView;
        private HeroEquipmentPresenter heroEquipmentPresenter;
        private readonly List<HeroEquipmentRecord> pendingHeroEquipment = new List<HeroEquipmentRecord>();
        private readonly List<FaBaoRecord> pendingFaBao = new List<FaBaoRecord>();
        private readonly List<CultivationLevel> pendingCultivation = new List<CultivationLevel>();
        private uint pendingEquipmentUid;
        private int pendingEquipmentTemplateId;
        private int pendingEquipmentFormationPosition;
        private uint pendingEquipmentExperience;
        private int pendingEquipmentBaseAttributeType;
        private uint pendingEquipmentBaseAttributeValue;
        private int pendingFaBaoSlot;
        private CocosUiView settingsView;
        private SettingsPresenter settingsPresenter;
        private Button settingsButton;
        private CocosUiView taskBackgroundView;
        private CocosUiView taskView;
        private TaskPresenter taskPresenter;
        private MainTaskTrackerPresenter mainTaskTracker;
        private MainHudPresenter mainHudPresenter;
        private Button taskButton;
        private readonly List<TaskRecord> pendingTaskRecords = new List<TaskRecord>();
        private CocosUiView errorView;
        private GameErrorPresenter errorPresenter;
        private CocosUiView loadingView;
        private LoadingPresenter loadingPresenter;
        private ToastPresenter toastPresenter;
        private CocosUiView mailView;
        private MailPresenter mailPresenter;
        private readonly List<MailRecord> pendingMails = new List<MailRecord>();
        private readonly List<RewardRecord> pendingMailAttachments = new List<RewardRecord>();
        private uint pendingMailId;
        private uint pendingMailFromId;
        private string pendingMailSender;
        private uint pendingMailExpireAt;
        private string pendingMailMessage;
        private CocosUiView shopView;
        private ShopPresenter shopPresenter;
        private readonly List<ShopRecord> pendingShopRecords = new List<ShopRecord>();
        private byte pendingShopType;
        private ushort pendingShopRefreshTimes;
        private byte pendingShopFreeTimes;
        private ushort pendingShopRefreshRemaining;
        private ushort validationShopId;
        private ushort validationShopBuyCount;
        private int validationShopCurrencyType;
        private long validationShopExpectedCurrency;
        private int validationShopRewardType;
        private uint validationShopRewardAmount;
        private CocosUiView friendView;
        private FriendPresenter friendPresenter;
        private readonly List<FriendRecord> pendingFriendRecords = new List<FriendRecord>();
        private byte pendingFriendMaximum;
        private CocosUiView chatView;
        private ChatPresenter chatPresenter;
        private CocosUiView teamView;
        private TeamPresenter teamPresenter;
        private readonly List<TeamMemberRecord> pendingTeamMembers = new List<TeamMemberRecord>();
        private byte pendingTeamType;
        private ushort pendingTeamFormationId;
        private CocosUiView guildView;
        private CocosUiView guildInfoView;
        private CocosUiView guildMemberView;
        private CocosUiView guildCreateView;
        private GuildPresenter guildPresenter;
        private readonly List<GuildRecord> pendingGuildRecords = new List<GuildRecord>();
        private readonly List<GuildMemberRecord> pendingGuildMembers = new List<GuildMemberRecord>();
        private CocosUiView worldView;
        private CocosUiView worldMapView;
        private CocosUiView worldDetailView;
        private WorldPresenter worldPresenter;
        private readonly List<WorldChapterRecord> pendingWorldChapters = new List<WorldChapterRecord>();
        private readonly List<WorldStageRecord> pendingWorldStages = new List<WorldStageRecord>();
        private readonly List<WorldStarBoxRecord> pendingWorldStarBoxes = new List<WorldStarBoxRecord>();
        private WorldStageRecord pendingWorldStage;
        private byte pendingWorldMapType;
        private uint pendingWorldChapterId;
        private string pendingWorldChapterName;
        private CocosUiView welfareView;
        private CocosUiView welfareSignView;
        private CocosUiView welfareOnlineView;
        private WelfarePresenter welfarePresenter;
        private readonly List<WelfareSignRecord> pendingWelfareSigns = new List<WelfareSignRecord>();
        private readonly List<WelfareOnlineRecord> pendingWelfareOnline = new List<WelfareOnlineRecord>();
        private bool pendingWelfareSignedToday;
        private byte pendingWelfareSignedDays;
        private byte pendingWelfareOnlineClaimed;
        private uint pendingWelfareOnlineSeconds;
        private string status = "Starting ProjectX...";
        private string disconnectReason;
        private int reconnectAttempts;
        private bool autoReconnectRunning;

        public static ProjectXApp Instance { get; private set; }
        public string Status => status;
        public NetworkState NetworkState => services?.Network.State ?? NetworkState.Idle;
        public bool IsBagOpen => bagView != null && services?.UiStack.Current == bagView;
        public int BagMissingIconCount => bagPresenter?.MissingIconCount ?? 0;
        public bool IsSettingsOpen => settingsView != null && services?.UiStack.Current == settingsView;
        public bool IsLoginVisible => loginView != null && loginView.GameObject.activeSelf;
        public int LoginPlayingAnimationCount => loginPresenter?.PlayingAnimationCount ?? 0;
        public bool IsRoleCreateVisible => loginPresenter?.IsRoleCreateVisible ?? false;
        public bool IsGameNoticeOpen => noticeView != null && services?.UiStack.Current == noticeView;
        public int GameNoticeCount => noticePresenter?.Count ?? 0;
        public bool GameNoticeRequested => gameNoticeRequested;
        public bool IsTaskOpen => taskBackgroundView != null && services?.UiStack.Current == taskBackgroundView;
        public bool IsGuildOpen => guildView != null && services?.UiStack.Current == guildView;
        public bool IsWorldOpen => worldView != null && services?.UiStack.Current == worldView;
        public bool IsWelfareOpen => welfareView != null && services?.UiStack.Current == welfareView;
        public int WorldChapterCount => services?.World.ChapterCount ?? 0;
        public int WorldStageCount => services?.World.StageCount ?? 0;
        public int WelfareSignCount => services?.Welfare.Signs.Count ?? 0;
        public int WelfareOnlineCount => services?.Welfare.Online.Count ?? 0;
        public int WelfareMissingIconCount => welfarePresenter?.MissingIconCount ?? 0;
        public bool IsWelfareHotPointVisible => mainView != null
            && mainView.GameObject.transform.Find("WelfareEntryRuntime/HotPoint")?.gameObject.activeSelf == true;
        public int TaskCount => services?.Tasks.Count ?? 0;
        public bool IsTaskHotPointVisible => mainTaskTracker?.IsHotPointVisible ?? false;
        public bool IsRewardVisible => rewardPresenter?.IsVisible ?? false;
        public int RewardCount => services?.Rewards.Count ?? 0;
        public bool IsHeroOpen => heroListView != null && services?.UiStack.Current == heroListView;
        public bool IsHeroEquipmentOpen => heroEquipmentListView != null && services?.UiStack.Current == heroEquipmentListView;
        public int HeroEquipmentCount => services?.HeroEquipment.Count ?? 0;
        public int FaBaoCount => services?.FaBao.Count ?? 0;
        public int HeroEquipmentMissingIconCount => heroEquipmentPresenter?.MissingIconCount ?? 0;
        public int HeroCount => services?.Heroes.Count ?? 0;
        public bool IsErrorVisible => errorPresenter?.IsVisible ?? false;
        public bool IsLoadingVisible => loadingPresenter?.IsVisible ?? false;
        public bool IsToastVisible => toastPresenter?.IsVisible ?? false;
        public bool IsServerTimeSynchronized => services?.ServerTime.IsSynchronized ?? false;
        public bool IsMailOpen => mailView != null && services?.UiStack.Current == mailView;
        public int MailCount => services?.Mails.Count ?? 0;
        public int MailMissingIconCount => mailPresenter?.MissingIconCount ?? 0;
        public bool IsShopOpen => shopView != null && services?.UiStack.Current == shopView;
        public int ShopCount => services?.Shop.Count ?? 0;
        public int ShopMissingIconCount => shopPresenter?.MissingIconCount ?? 0;
        public bool IsFriendOpen => friendView != null && services?.UiStack.Current == friendView;
        public int FriendCount => services?.Friends.FriendCount ?? 0;
        public int FriendApplicationCount => services?.Friends.ApplicationCount ?? 0;
        public int FriendRenderedCount => friendPresenter?.RenderedCount ?? 0;
        public bool IsChatOpen => chatView != null && services?.UiStack.Current == chatView;
        public int ChatCount => services?.Chat.Count ?? 0;
        public int ChatRenderedCount => chatPresenter?.RenderedCount ?? 0;
        public bool IsTeamOpen => teamView != null && services?.UiStack.Current == teamView;
        public int TeamPlayerCount => services?.Team.PlayerCount ?? 0;
        public int TeamRenderedPlayerCount => teamPresenter?.RenderedPlayerCount ?? 0;
        public AppState CurrentAppState => services?.State.Current ?? ProjectX.Core.AppState.Booting;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            try
            {
                services = new GameServices(this, AppLaunchOptions.Current());
                if (services.Options.ManualReconnectValidation)
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
                onBagClicked = services.Lua.GetFunction("OnBagClicked");
                onBagUseClicked = services.Lua.GetFunction("OnBagUseClicked");
                onSettingsClicked = services.Lua.GetFunction("OnSettingsClicked");
                onTaskClicked = services.Lua.GetFunction("OnTaskClicked");
                onTaskClaimClicked = services.Lua.GetFunction("OnTaskClaimClicked");
                onHeroClicked = services.Lua.GetFunction("OnHeroClicked");
                onHeroEquipmentWear = services.Lua.GetFunction("OnHeroEquipmentWear");
                onHeroEquipmentTakeOff = services.Lua.GetFunction("OnHeroEquipmentTakeOff");
                onFaBaoWear = services.Lua.GetFunction("OnFaBaoWear");
                onFaBaoTakeOff = services.Lua.GetFunction("OnFaBaoTakeOff");
                onMailClicked = services.Lua.GetFunction("OnMailClicked");
                onMailClaimClicked = services.Lua.GetFunction("OnMailClaimClicked");
                onShopClicked = services.Lua.GetFunction("OnShopClicked");
                onShopBuyConfirmed = services.Lua.GetFunction("OnShopBuyConfirmed");
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
                onWorldRefresh = services.Lua.GetFunction("OnWorldRefresh");
                onWelfareClicked = services.Lua.GetFunction("OnWelfareClicked");
                onWelfareClaimSign = services.Lua.GetFunction("OnWelfareClaimSign");
                StartCoroutine(RunCurrentCocosStartup());
            }
            catch (Exception exception)
            {
                Fail($"App bootstrap failed: {exception.Message}");
            }
        }

        private void Update()
        {
            services?.Tick();
            loadingPresenter?.Tick();
            toastPresenter?.Tick();
            shopPresenter?.Tick();
            welfarePresenter?.Tick();
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

        private void OnDestroy()
        {
            onConnected?.Dispose();
            onDisconnected?.Dispose();
            onPacket?.Dispose();
            onLoginClicked?.Dispose();
            onRoleCreateClicked?.Dispose();
            onBagClicked?.Dispose();
            onBagUseClicked?.Dispose();
            onSettingsClicked?.Dispose();
            onTaskClicked?.Dispose();
            onTaskClaimClicked?.Dispose();
            onHeroClicked?.Dispose();
            onHeroEquipmentWear?.Dispose();
            onHeroEquipmentTakeOff?.Dispose();
            onFaBaoWear?.Dispose();
            onFaBaoTakeOff?.Dispose();
            onMailClicked?.Dispose();
            onMailClaimClicked?.Dispose();
            onShopClicked?.Dispose();
            onShopBuyConfirmed?.Dispose();
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
            onWorldRefresh?.Dispose();
            onWelfareClicked?.Dispose();
            onWelfareClaimSign?.Dispose();
            bagPresenter?.Dispose();
            rewardPresenter?.Dispose();
            heroPresenter?.Dispose();
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
            welfarePresenter?.Dispose();
            startupPresenter?.Dispose();
            loginPresenter?.Dispose();
            noticePresenter?.Dispose();
            services?.State.Change(AppState.ShuttingDown, "ProjectXApp destroyed");
            services?.Dispose();
            if (Instance == this) Instance = null;
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

        public bool IsAutomation() => services?.Options.Automation ?? false;
        public bool HasCommandLineFlag(string flag) => services?.Options.HasFlag(flag) ?? false;
        public uint GetLocalUserId() => services?.Config.LocalUserId ?? 1;
        public uint GetPlayerRoleId() => services?.Player.RoleId ?? 0;
        public bool HandleBack()
        {
            if (IsHeroEquipmentOpen) heroEquipmentPresenter?.HideDetails();
            return services?.UiStack.Pop() ?? false;
        }

        public async void Connect(string host, int port)
        {
            try
            {
                ShowLoading("connect", "正在连接服务器…", 20f);
                disconnectReason = null;
                services.State.Change(AppState.Connecting, $"{host}:{port}");
                await services.Network.ConnectAsync(host, port, services.Config.ConnectTimeoutSeconds);
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Connected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected");
            }
            catch (Exception exception)
            {
                HideLoading("connect");
                Fail($"Connect failed: {exception.Message}");
            }
        }

        public async void Reconnect()
        {
            if (services == null || services.Network.State == NetworkState.Connecting) return;
            try
            {
                ShowLoading("reconnect", "正在重新连接…", 25f);
                disconnectReason = null;
                await services.Network.ReconnectAsync(services.Config.ConnectTimeoutSeconds);
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Reconnected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected.AfterReconnect");
            }
            catch (Exception exception)
            {
                HideLoading("reconnect");
                disconnectReason = exception.Message;
                SetStatus($"Reconnect failed: {exception.Message}");
            }
        }

        public void Send(LegacyTcpMessage message)
        {
            try
            {
                if (message.OutgoingCommand == 88) gameNoticeRequested = true;
                services.ProtocolRegistry.TrackSend(message.OutgoingCommand);
                services.Network.Send(message);
            }
            catch (Exception exception) { Fail($"Send failed: {exception.Message}"); }
        }

        public void ShowLoginUi()
        {
            loginView = services.UiRouter.FindBySource("Login/loginLayer");
            loginBackgroundView = services.UiRouter.FindBySource("Login/LoginBgLayer");
            loginServerListView = services.UiRouter.FindBySource("Login/SeverListLayer");
            roleCreateView = services.UiRouter.FindBySource("Login/RoleCreateLayer");
            noticeView = services.UiRouter.FindBySource("/NoticeLayer.csd", true);
            mainView = services.UiRouter.FindBySource("UImainLayer", true);
            bagView = services.UiRouter.FindBySource("zhujue/beibao");
            settingsView = services.UiRouter.FindBySource("zhujue/SystemLayer");
            taskBackgroundView = services.UiRouter.FindBySource("huodong/huodong_bg");
            taskView = services.UiRouter.FindBySource("huodong/RenwuLayer");
            errorView = services.UiRouter.FindBySource("MessageBoxLayer");
            loadingView = services.UiRouter.FindBySource("common/jiemianjiazai");
            heroListView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongListLayer");
            heroDetailView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongInfoLayer");
            heroEquipmentListView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeibeibao");
            heroEquipmentDetailView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            mailView = services.UiRouter.FindBySource("MailLayer");
            shopView = services.UiRouter.FindBySource("shop/shangcheng");
            friendView = services.UiRouter.FindBySource("common/FriendLayer");
            chatView = services.UiRouter.FindBySource("MainChatLayer");
            services.UiStack.Clear();
            loginBackgroundView?.SetVisible(true);
            loginView?.SetVisible(true);
            loginServerListView?.SetVisible(false);
            roleCreateView?.SetVisible(false);
            noticeView?.SetVisible(false);
            mainView?.SetVisible(false);
            bagView?.SetVisible(false);
            settingsView?.SetVisible(false);
            taskBackgroundView?.SetVisible(false);
            taskView?.SetVisible(false);
            errorView?.SetVisible(false);
            loadingView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentDetailView?.SetVisible(false);
            mailView?.SetVisible(false);
            shopView?.SetVisible(false);
            friendView?.SetVisible(false);
            chatView?.SetVisible(false);
            if (loginView == null) { Fail("Login/loginLayer CocosUiBinding was not found."); return; }
            if (loginBackgroundView == null) { Fail("Login/LoginBgLayer CocosUiBinding was not found."); return; }
            loginPresenter = loginPresenter ?? new LoginPresenter(loginBackgroundView, loginView, loginServerListView, roleCreateView);
            loginPresenter.ShowLocalServer("本地测试服");
            EnsureErrorPresenter();
            EnsureCommonPresenters();
            services.State.Change(AppState.Login, "Login UI shown");
            SetStatus("Login UI ready.");
        }

        public void BindLoginClick(bool autoInvoke)
        {
            try
            {
                Button button = loginView.BindClick(LoginButtonPath, HandleLoginClick);
                loginView.BindClick(LoginServerButtonPath, () => loginPresenter.ShowServerList(() =>
                    loginPresenter.ShowLocalServer("本地测试服")));
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void InvokeLoginForValidation()
        {
            Button button = loginView?.Binding.Find(LoginButtonPath)?.GetComponent<Button>();
            if (button == null) throw new InvalidOperationException("Local Btn_Play is not bound.");
            button.onClick.Invoke();
        }

        public bool ValidateLoginUi(out string detail)
        {
            GameObject play = loginView?.Binding.Find(LoginButtonPath);
            GameObject accountLogin = loginView?.Binding.Find("Layer/Login/Btn_Login");
            GameObject server = loginView?.Binding.Find(LoginServerButtonPath);
            Text serverName = loginView?.Binding.Find(LoginServerButtonPath + "/SeverName")?.GetComponent<Text>();
            if (!IsLoginVisible) { detail = "loginLayer is hidden"; return false; }
            if (play == null || !play.activeInHierarchy) { detail = "Btn_Play is not the active local entry"; return false; }
            if (accountLogin != null && accountLogin.activeInHierarchy) { detail = "account Btn_Login must be hidden for local openType=1"; return false; }
            if (server == null || !server.activeInHierarchy || serverName == null || serverName.text != "本地测试服")
            { detail = "local server selector is not configured"; return false; }
            if (LoginPlayingAnimationCount <= 0) { detail = "effect_chuangjue_1 is not playing"; return false; }
            string startupDetail = "StartupPresenter is missing";
            if (startupPresenter == null || !startupPresenter.Validate(out startupDetail))
            { detail = "startup mismatch: " + startupDetail; return false; }
            detail = startupDetail + " -> Btn_Play/local server/effect_chuangjue_1 match Cocos openType=1";
            return true;
        }

        public void ShowRoleCreateUi()
        {
            loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, false);
            services.State.Change(AppState.Login, "Role creation UI shown");
            SetStatus("Role creation UI ready.");
        }

        public void BindRoleCreateClick(bool autoInvoke)
        {
            try { loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, autoInvoke); }
            catch (Exception exception) { Fail(exception.Message); }
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
            Complete($"COMPLETE: LogoScene/GameScene preload -> Btn_Play -> /1001 -> "
                + (createdRole ? "RoleCreateLayer + Create_5/Create_4 -> /1003 -> " : string.Empty)
                + $"/1004 -> current UImainLayer -> /88 NoticeLayer count={GameNoticeCount}; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        public void BeginGameNotice(int expectedCount)
        {
            pendingGameNotices.Clear();
            if (expectedCount > 0) pendingGameNotices.Capacity = Math.Max(pendingGameNotices.Capacity, expectedCount);
        }

        public void AddGameNotice(string title, string text, int id, int operationType)
        {
            pendingGameNotices.Add(new NoticeRecord
            {
                Title = title ?? string.Empty,
                Text = text ?? string.Empty,
                Id = checked((byte)id),
                OperationType = checked((byte)operationType)
            });
        }

        public void ShowGameNotice()
        {
            if (noticeView == null) { Fail("NoticeLayer CocosUiBinding was not found."); return; }
            noticePresenter = noticePresenter ?? new NoticePresenter(noticeView);
            noticePresenter.Show(pendingGameNotices);
            noticeView.GameObject.transform.SetAsLastSibling();
            services.UiStack.Push(noticeView, false);
        }

        public void ShowMainUi()
        {
            mainView = services.UiRouter.FindBySource("UImainLayer", true);
            if (mainView == null) { Fail("UImainLayer CocosUiBinding was not found."); return; }
            loginView?.SetVisible(false);
            loginBackgroundView?.SetVisible(false);
            loginPresenter?.HideAll();
            services.UiStack.SetRoot(mainView);
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            errorPresenter?.Hide();
            EnsureMainHudPresenter();
            EnsureMainTaskTracker();
            services.State.Change(AppState.Main, "Main UI shown");
            SetStatus("Main UI active.");
        }

        public void BindBagClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(BagPath, HandleBagClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindSettingsClick()
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                settingsButton = mainView.BindClick(SettingsPath, HandleSettingsClick, true);
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTaskClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                taskButton = mainView.BindClick(TaskPath, HandleTaskClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(taskButton));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindHeroClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(HeroPath, HandleHeroClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindMailClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(MailPath, HandleMailClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowMail()
        {
            EnsureMailPresenter();
            if (services.UiStack.Current != mailView) services.UiStack.Push(mailView);
            SetStatus($"Mail UI active: {services.Mails.Count} mails.");
        }

        public void BindShopClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(ShopPath, HandleShopClick, true);
                mainView.BindClick(ShopSubmenuPath, HandleShopClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowShop()
        {
            EnsureShopPresenter();
            if (services.UiStack.Current != shopView) services.UiStack.Push(shopView);
            SetStatus($"Shop UI active: {services.Shop.Count} goods.");
        }

        public void BindFriendClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(FriendPath, HandleFriendClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindChatClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.Binding.Find(ChatPath) != null
                    ? mainView.BindClick(ChatPath, HandleChatClick, true)
                    : EnsureRuntimeChatEntry();
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTeamClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = EnsureRuntimeTeamEntry();
                CocosUiView legacy = services.UiRouter.FindBySource("UImainLayer_backup");
                if (legacy?.Binding.Find(TeamLegacyPath) == null)
                    throw new InvalidOperationException($"Legacy team entry evidence is missing: {TeamLegacyPath}");
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGuildClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(GuildPath, HandleGuildClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindWorldClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(WorldPath, HandleWorldClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindWelfareClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                CocosUiView legacy = services.UiRouter.FindBySource("UImainLayer_backup");
                if (legacy?.Binding.Find(WelfareLegacyPath) == null)
                    throw new InvalidOperationException($"Legacy welfare entry evidence is missing: {WelfareLegacyPath}");
                Button button = EnsureRuntimeWelfareEntry();
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowFriend()
        {
            EnsureFriendPresenter();
            if (services.UiStack.Current != friendView) services.UiStack.Push(friendView);
            SetStatus($"Friend UI active: {services.Friends.FriendCount} friends, {services.Friends.ApplicationCount} applications.");
        }

        public void ShowChat()
        {
            EnsureChatPresenter();
            if (services.UiStack.Current != chatView) services.UiStack.Push(chatView);
            SetStatus($"Chat UI active: {services.Chat.Count} messages.");
        }

        public void ShowTeam()
        {
            EnsureTeamPresenter();
            if (services.UiStack.Current != teamView) services.UiStack.Push(teamView);
            SetStatus($"Team UI active: {services.Team.PlayerCount} players.");
        }

        public void ShowGuild()
        {
            EnsureGuildPresenter();
            if (services.UiStack.Current != guildView) services.UiStack.Push(guildView);
            SetStatus(services.Guild.HasGuild
                ? $"Guild UI active: {services.Guild.Info.Name}, {services.Guild.MemberCount} members."
                : $"Guild UI active: no guild, {services.Guild.Items.Count} guilds listed.");
        }

        public void ShowWorld()
        {
            EnsureWorldPresenter();
            worldPresenter.ShowWorld();
            if (services.UiStack.Current != worldView) services.UiStack.Push(worldView);
            SetStatus($"World UI active: {services.World.ChapterCount} chapters, {services.World.StageCount} stages.");
        }

        public void ShowWelfare()
        {
            EnsureWelfarePresenter();
            welfarePresenter.SelectTab(0);
            if (services.UiStack.Current != welfareView) services.UiStack.Push(welfareView);
            SetStatus($"Welfare UI active: {services.Welfare.Signs.Count} sign rewards, {services.Welfare.Online.Count} online rewards.");
        }

        public void ShowTask()
        {
            EnsureTaskPresenter();
            taskView.SetVisible(true);
            if (services.UiStack.Current != taskBackgroundView) services.UiStack.Push(taskBackgroundView);
            SetStatus($"Task UI active: {services.Tasks.Count} tasks.");
        }

        public void ShowSettings()
        {
            EnsureSettingsPresenter();
            settingsPresenter.Refresh(GetLocalUserId());
            if (services.UiStack.Current != settingsView) services.UiStack.Push(settingsView);
            SetStatus("System settings active.");
        }

        public void RunSettingsValidation()
        {
            if (settingsButton == null) { Fail("Settings button was not bound."); return; }
            settingsButton.onClick.Invoke();
            if (!IsSettingsOpen) { Fail("Settings UI was not pushed onto UiStack."); return; }
            if (!settingsPresenter.ValidatePersistence(out string detail)) { Fail(detail); return; }
            Complete("COMPLETE: main settings button -> SystemLayer -> audio toggles/sliders -> PlayerPrefs persistence");
        }

        public void RunSettingsAccountValidation()
        {
            settingsButton.onClick.Invoke();
            if (!IsSettingsOpen) { Fail("Settings UI did not reopen for account-switch validation."); return; }
            settingsPresenter.InvokeReturnToLogin();
            if (!IsLoginVisible || IsSettingsOpen || services.Network.State != NetworkState.Disconnected)
            {
                Fail("Settings account switch did not restore the disconnected login state.");
                return;
            }
            Complete("COMPLETE: settings account switch -> network disconnected -> login UI restored");
        }

        public bool ValidateFoundation(out string detail)
        {
            detail = string.Empty;
            if (!services.Options.TaskValidation)
            {
                detail = "AppLaunchOptions did not retain -projectXTaskValidation.";
                return false;
            }
            if (services.State.Current != ProjectX.Core.AppState.Main)
            {
                detail = $"AppState expected Main, got {services.State.Current}.";
                return false;
            }
            if (services.ProtocolRegistry.PendingCount != 0)
            {
                detail = $"ProtocolRegistry still has {services.ProtocolRegistry.PendingCount} pending requests.";
                return false;
            }
            if (services.Tasks.Count <= 0 || taskPresenter == null || taskPresenter.ItemCount != services.Tasks.Count)
            {
                detail = "ConfigService/TaskStore/VirtualList counts are inconsistent.";
                return false;
            }
            if (!services.ServerTime.IsSynchronized || services.ServerTime.UnixSeconds == 0)
            {
                detail = "ServerTimeService did not receive MSG_SYNC_TIME/206.";
                return false;
            }
            if (services.Resources.LoadHeroPortrait(0) == null)
            {
                detail = "ResourceService could not resolve the default hero portrait.";
                return false;
            }
            EnsureCommonPresenters();
            loadingPresenter.Show("foundation-self-test", "底层加载自检", 1f);
            if (!loadingPresenter.IsVisible || loadingPresenter.RequestCount != 1)
            {
                detail = "LoadingPresenter did not become visible.";
                return false;
            }
            loadingPresenter.Hide("foundation-self-test");
            if (loadingPresenter.IsVisible)
            {
                detail = "LoadingPresenter did not clear its keyed request.";
                return false;
            }
            toastPresenter.Show("通用提示自检", 0.25f);
            if (!toastPresenter.IsVisible)
            {
                detail = "ToastPresenter did not become visible.";
                return false;
            }
            toastPresenter.Clear();
            EnsureErrorPresenter();
            if (errorPresenter == null)
            {
                detail = "GameErrorPresenter is unavailable.";
                return false;
            }
            errorPresenter.Show("底层自检", "通用错误弹窗显隐测试");
            if (!errorPresenter.IsVisible)
            {
                detail = "GameErrorPresenter did not become visible.";
                return false;
            }
            errorPresenter.Hide();
            if (errorPresenter.IsVisible)
            {
                detail = "GameErrorPresenter did not close.";
                return false;
            }
            detail = $"foundation ok; tasks={services.Tasks.Count}; serverTime={services.ServerTime.UnixSeconds}; sprites={services.Resources.CachedSpriteCount}; missing={services.Resources.MissingSpriteCount}";
            return true;
        }

        public void ReturnToLogin()
        {
            services.Network.Disconnect();
            services.Tasks.Clear();
            services.Player.Clear();
            services.Currencies.Clear();
            services.Bag.Clear();
            services.Rewards.Clear();
            services.Mails.Clear();
            services.Shop.Clear();
            services.Friends.Clear();
            services.Heroes.Clear();
            services.Formation.Clear();
            services.World.Clear();
            services.Welfare.Clear();
            services.ServerTime.Reset();
            loadingPresenter?.Clear();
            toastPresenter?.Clear();
            rewardPresenter?.Hide();
            ShowLoginUi();
        }

        public void InitializePlayer(uint roleId, string name, int sex, int model, int head, int level,
            double experience, double power, int money, int premium, int boundPremium,
            uint potential, uint soul, int packageCapacity, uint guildContribution)
        {
            services.Player.Initialize(roleId, name, unchecked((byte)sex), unchecked((byte)model),
                unchecked((byte)head), unchecked((ushort)level), checked((ulong)experience),
                checked((ulong)power), potential, soul, unchecked((ushort)packageCapacity));
            services.Currencies.Initialize(money, premium, boundPremium, soul, guildContribution);
        }

        public void AddPlayerExperience(uint amount) => services.Player.AddExperience(amount);
        public void SetPlayerPower(double value) => services.Player.SetPower(checked((ulong)value));
        public void SetPlayerLevelAndPower(int level, double value) =>
            services.Player.SetLevelAndPower(unchecked((ushort)level), checked((ulong)value));
        public void SetPlayerPotential(uint value) => services.Player.SetPotential(value);
        public void SetPlayerSoul(uint value)
        {
            services.Player.SetSoul(value);
            services.Currencies.Set(CurrencyIds.Soul, value);
        }
        public void SetCurrency(int id, double value) => services.Currencies.Set(id, checked((long)value));

        public double GetCurrency(int id) => services.Currencies.Get(id);

        public void SynchronizeServerTime(double todaySeconds, double unixSeconds)
        {
            services.ServerTime.Synchronize(checked((uint)todaySeconds), checked((uint)unixSeconds));
            ClientLog.Info("ServerTime", "Synchronized",
                $"unix={services.ServerTime.UnixSeconds} today={services.ServerTime.TodaySeconds}");
        }

        public double GetServerUnixSeconds() => services.ServerTime.UnixSeconds;
        public double GetServerTodaySeconds() => services.ServerTime.TodaySeconds;

        public void ShowLoading(string key, string message = null, float autoClearSeconds = 15f)
        {
            EnsureCommonPresenters();
            loadingPresenter.Show(key, message, autoClearSeconds);
        }

        public void HideLoading(string key) => loadingPresenter?.Hide(key);

        public void ShowToast(string message, float visibleSeconds = 2f)
        {
            EnsureCommonPresenters();
            toastPresenter.Show(message, visibleSeconds);
        }

        public void CompletePlayerHudValidation(double expectedGold, double expectedPremium)
        {
            EnsureMainHudPresenter();
            if (services.Currencies.Gold != checked((long)expectedGold)
                || services.Currencies.Premium != checked((long)expectedPremium)
                || services.Currencies.Stamina <= 0)
            {
                Fail($"Player HUD validation currency mismatch: gold={services.Currencies.Gold}/{expectedGold}, premium={services.Currencies.Premium}/{expectedPremium}, stamina={services.Currencies.Stamina}.");
                return;
            }
            if (!mainHudPresenter.Validate(out string detail)) { Fail("Player HUD validation failed: " + detail); return; }
            Complete("COMPLETE: /1004 player snapshot -> PlayerStore/CurrencyStore -> main HUD -> /18 gold/premium increments | " + detail);
        }

        public void BeginBagUpdate(int expectedCount)
        {
            pendingBagItems.Clear();
            if (expectedCount > pendingBagItems.Capacity) pendingBagItems.Capacity = expectedCount;
        }

        public void AddBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority)
        {
            pendingBagItems.Add(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority));
        }

        public void EndBagUpdate()
        {
            services.Bag.Replace(pendingBagItems);
            EnsureBagPresenter();
            if (services.UiStack.Current != bagView) services.UiStack.Push(bagView);
            SetStatus($"Bag UI active: {bagPresenter.ItemCount} item stacks, {bagPresenter.MissingIconCount} missing icons.");
        }

        public void UpsertBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority)
        {
            services.Bag.Upsert(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority));
        }

        public void RemoveBagItem(int slot) => services.Bag.Remove(slot);
        public int GetBagCount() => services.Bag.Count;
        public int GetBagQuantity(int slot) => services.Bag.GetQuantity(slot);

        public void BeginRewardUpdate(int expectedCount)
        {
            pendingRewards.Clear();
            if (expectedCount > pendingRewards.Capacity) pendingRewards.Capacity = expectedCount;
        }

        public void AddRewardRecord(int type, double id, double amount, string name, int picture, int quality)
        {
            pendingRewards.Add(new RewardRecord(type, checked((uint)id), checked((uint)amount), name, picture, quality));
        }

        public void EndRewardUpdate(string title)
        {
            services.Rewards.Replace(title, pendingRewards);
            EnsureRewardPresenter();
            rewardPresenter.Show();
            SetStatus($"Reward UI active: {services.Rewards.Count} rewards.");
        }

        public bool ValidateRewardPresentation(int expectedCount, bool dismiss)
        {
            EnsureRewardPresenter();
            bool valid = expectedCount > 0 && services.Rewards.Count == expectedCount
                && rewardPresenter.RenderedCount == Math.Min(expectedCount, 4) && rewardPresenter.IsVisible;
            if (valid && dismiss) rewardPresenter.Hide();
            return valid;
        }

        public void BeginMailUpdate(int expectedCount)
        {
            pendingMails.Clear();
            if (expectedCount > pendingMails.Capacity) pendingMails.Capacity = expectedCount;
        }

        public void BeginMailRecord(double id, double fromId, string sender, double expireAt,
            string message, int expectedAttachmentCount)
        {
            pendingMailId = checked((uint)id);
            pendingMailFromId = checked((uint)fromId);
            pendingMailSender = sender ?? string.Empty;
            pendingMailExpireAt = checked((uint)expireAt);
            pendingMailMessage = message ?? string.Empty;
            pendingMailAttachments.Clear();
            if (expectedAttachmentCount > pendingMailAttachments.Capacity)
                pendingMailAttachments.Capacity = expectedAttachmentCount;
        }

        public void AddMailAttachment(int type, double id, double amount, string name, int picture, int quality)
        {
            pendingMailAttachments.Add(new RewardRecord(type, checked((uint)id), checked((uint)amount),
                name, picture, quality));
        }

        public void EndMailRecord()
        {
            pendingMails.Add(new MailRecord(pendingMailId, pendingMailFromId, pendingMailSender,
                pendingMailExpireAt, pendingMailMessage, pendingMailAttachments.ToArray()));
        }

        public void EndMailUpdate()
        {
            services.Mails.Replace(pendingMails);
            EnsureMailPresenter();
            ShowMail();
        }

        public bool SelectMail(double id)
        {
            EnsureMailPresenter();
            return mailPresenter.Select(checked((uint)id));
        }

        public bool IsMailRead(double id) =>
            services.Mails.TryGet(checked((uint)id), out MailRecord value) && value.IsRead;

        public int GetMailAttachmentCount(double id) =>
            services.Mails.TryGet(checked((uint)id), out MailRecord value) ? value.Attachments.Count : 0;

        public bool HasMail(double id) => services.Mails.TryGet(checked((uint)id), out _);
        public void RemoveMail(double id) => services.Mails.Remove(checked((uint)id));

        public void CompleteMailClaimValidation(double claimedId, int rewardCount)
        {
            uint id = checked((uint)claimedId);
            if (services.Mails.TryGet(id, out _) || rewardCount <= 0 || !ValidateRewardPresentation(rewardCount, true)
                || services.ProtocolRegistry.PendingCount != 0 || !IsMailOpen)
            {
                Fail($"Mail validation mismatch: claimedStillPresent={services.Mails.TryGet(id, out _)}, rewards={rewardCount}, pending={services.ProtocolRegistry.PendingCount}, open={IsMailOpen}.");
                return;
            }
            Complete($"COMPLETE: /128 list -> MailStore/read/attachments -> claim id={id} -> RewardStore/RewardPresenter ({rewardCount}) -> persisted removal");
        }

        public void CaptureMailDetailAndClaimValidation(double mailId)
        {
            StartCoroutine(CaptureMailDetailAndClaim((uint)mailId));
        }

        public int GetShopDisplayItemId(double id) =>
            services.ShopCatalog.GetDisplayItemId(checked((ushort)id));

        public void BeginShopUpdate(int type, int refreshTimes, int freeRefreshTimes,
            int refreshRemainingSeconds, int expectedCount)
        {
            pendingShopType = checked((byte)type);
            pendingShopRefreshTimes = checked((ushort)refreshTimes);
            pendingShopFreeTimes = checked((byte)freeRefreshTimes);
            pendingShopRefreshRemaining = checked((ushort)refreshRemainingSeconds);
            pendingShopRecords.Clear();
            if (expectedCount > pendingShopRecords.Capacity) pendingShopRecords.Capacity = expectedCount;
        }

        public void BeginFriendListUpdate(int maximum, int expectedCount) => BeginFriendUpdate(maximum, expectedCount);
        public void BeginFriendApplicationUpdate(int maximum, int expectedCount) => BeginFriendUpdate(maximum, expectedCount);

        public void AddFriendRecord(double id, string name, int level, int sex, int head, double power,
            double offlineSeconds, double guildId, string guildName, double intimacy, int sendFlag)
        {
            pendingFriendRecords.Add(new FriendRecord(checked((uint)id), name, checked((ushort)level),
                checked((byte)sex), checked((byte)head), checked((ulong)power), checked((uint)offlineSeconds),
                checked((uint)guildId), guildName, checked((uint)intimacy), checked((byte)sendFlag)));
        }

        public void EndFriendListUpdate()
        {
            services.Friends.ReplaceFriends(pendingFriendMaximum, pendingFriendRecords);
            EnsureFriendPresenter();
            ShowFriend();
        }

        public void EndFriendApplicationUpdate()
        {
            services.Friends.ReplaceApplications(pendingFriendMaximum, pendingFriendRecords);
            EnsureFriendPresenter();
            ShowFriend();
        }

        public bool RemoveFriend(double id) => services.Friends.RemoveFriend(checked((uint)id));
        public bool RemoveFriendApplication(double id) => services.Friends.RemoveApplication(checked((uint)id));

        public void CaptureFriendAndDeleteValidation(double id)
        {
            EnsureFriendPresenter();
            friendPresenter.ShowFriends(false);
            toastPresenter?.Clear();
            StartCoroutine(CaptureFriendAndDelete(checked((uint)id)));
        }

        public void CompleteFriendMutationValidation(double rejectedId, double acceptedId)
        {
            EnsureFriendPresenter();
            friendPresenter.ShowFriends(false);
            if (!IsFriendOpen || services.Friends.FriendCount != 0 || services.Friends.ApplicationCount != 0
                || friendPresenter.RenderedCount != 0)
            {
                Fail($"Friend final state mismatch: open={IsFriendOpen}, friends={services.Friends.FriendCount}, applications={services.Friends.ApplicationCount}, rendered={friendPresenter.RenderedCount}.");
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /27 seeded applications -> reject {checked((uint)rejectedId)} -> add/duplicate-error -> accept {checked((uint)acceptedId)} -> FriendStore/UI -> delete -> persisted empty state");
        }

        public void AddLocalChatMessage(int channel, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = checked((ChatChannel)(byte)channel),
                Sender = services.Player.Summary,
                Content = content ?? string.Empty,
                IsLocalEcho = true
            });
        }

        public void AddChatMessage(int channel, double senderId, string senderName, int vip, int head, int sex, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = checked((ChatChannel)(byte)channel),
                Sender = new PlayerSummary(checked((uint)senderId), senderName, sex: checked((byte)sex), head: checked((byte)head)),
                VipLevel = checked((byte)vip),
                Content = content ?? string.Empty
            });
        }

        public void AddPrivateChatMessage(double senderId, string senderName, int vip, int head, int sex,
            int level, double teamId, double guildId, double recipientId, double serverTime, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = ChatChannel.Private,
                Sender = new PlayerSummary(checked((uint)senderId), senderName, checked((ushort)level),
                    checked((byte)sex), checked((byte)head), teamId: checked((uint)teamId), guildId: checked((uint)guildId)),
                VipLevel = checked((byte)vip),
                RecipientRoleId = checked((uint)recipientId),
                ServerTime = checked((uint)serverTime),
                Content = content ?? string.Empty
            });
        }

        public void SetChatError(int channel, string message)
        {
            services.Chat.SetError(message);
            ShowToast(message, 3f);
        }

        public void CompleteChatValidation(string worldText, string privateText, string error)
        {
            EnsureChatPresenter();
            chatPresenter.SelectChannel(ChatChannel.Combined);
            if (GetLocalUserId() == 1 || !IsChatOpen
                || !services.Chat.Contains(ChatChannel.World, worldText)
                || !services.Chat.Contains(ChatChannel.Private, privateText)
                || string.IsNullOrWhiteSpace(error) || chatPresenter.RenderedCount < 2)
            {
                Fail($"Chat validation mismatch: user={GetLocalUserId()}, open={IsChatOpen}, messages={services.Chat.Count}, rendered={chatPresenter.RenderedCount}, error={error}.");
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /26 world local echo -> self-private server packet -> ChatStore/UI -> invalid-target error ({services.Chat.Count} messages)");
        }

        public uint GetTeamPeerRoleId() => services?.Options.TeamPeerRoleId ?? 0;
        public uint GetTeamLeaderId() => services?.Team.LeaderId ?? 0;
        public int GetTeamPlayerCount() => services?.Team.PlayerCount ?? 0;
        public bool TeamContainsPlayer(double roleId) => services?.Team.ContainsPlayer(checked((uint)roleId)) ?? false;

        public void BeginTeamUpdate(int teamType, int formationId, int expectedCount)
        {
            pendingTeamType = checked((byte)teamType);
            pendingTeamFormationId = checked((ushort)formationId);
            pendingTeamMembers.Clear();
            if (expectedCount > pendingTeamMembers.Capacity) pendingTeamMembers.Capacity = expectedCount;
        }

        public void AddTeamPlayerMember(int sourcePosition, int lineupPosition, bool isLeader, double roleId,
            string name, int level, int sex, int head, double power, bool temporarilyAway,
            double serverZone, double serverId, double shapeId)
        {
            pendingTeamMembers.Add(new TeamMemberRecord
            {
                Kind = TeamMemberKind.Player,
                SourcePosition = checked((byte)sourcePosition),
                LineupPosition = checked((byte)lineupPosition),
                IsLeader = isLeader,
                IsTemporarilyAway = temporarilyAway,
                Player = new PlayerSummary(checked((uint)roleId), name, checked((ushort)level), checked((byte)sex),
                    checked((byte)head), checked((ulong)power)),
                ServerZone = checked((uint)serverZone),
                ServerId = checked((uint)serverId),
                ShapeId = checked((uint)shapeId)
            });
        }

        public void AddTeamPetMember(int sourcePosition, int lineupPosition, double petId, string name,
            int level, int star, int breakLevel, double power)
        {
            pendingTeamMembers.Add(new TeamMemberRecord
            {
                Kind = TeamMemberKind.Pet,
                SourcePosition = checked((byte)sourcePosition),
                LineupPosition = checked((byte)lineupPosition),
                PetId = checked((uint)petId),
                PetName = name ?? string.Empty,
                PetLevel = checked((ushort)level),
                PetStar = checked((byte)star),
                PetBreakLevel = checked((byte)breakLevel),
                PetPower = checked((ulong)power)
            });
        }

        public void EndTeamUpdate()
        {
            services.Team.Replace(pendingTeamType, pendingTeamFormationId, pendingTeamMembers);
            EnsureTeamPresenter();
            ShowTeam();
        }

        public void MarkTeamCreated() => services.Team.MarkCreated(services.Player.RoleId);
        public void ClearTeamState() => services.Team.Leave();
        public void AddTeamInvitation(double id, string name, int level, int sex, int head, double power) =>
            services.Team.AddInvitation(new PlayerSummary(checked((uint)id), name, checked((ushort)level),
                checked((byte)sex), checked((byte)head), checked((ulong)power)));
        public void RemoveTeamInvitation(double id) => services.Team.RemoveInvitation(checked((uint)id));
        public void SetTeamError(string message) { ShowToast(message, 3f); SetStatus(message); }

        public void CaptureTeamAndLeaveValidation(double peerRoleId) =>
            StartCoroutine(CaptureTeamAndLeave(checked((uint)peerRoleId)));

        public void CompleteTeamValidation(double peerRoleId)
        {
            EnsureTeamPresenter();
            if (GetLocalUserId() == 1 || !IsTeamOpen || services.Team.HasTeam || services.Team.PlayerCount != 0
                || teamPresenter.RenderedPlayerCount != 1)
            {
                Fail($"Team final state mismatch: user={GetLocalUserId()}, open={IsTeamOpen}, hasTeam={services.Team.HasTeam}, players={services.Team.PlayerCount}, rendered={teamPresenter.RenderedPlayerCount}.");
                return;
            }
            Complete($"COMPLETE: /29 empty -> create -> invite/peer accept {checked((uint)peerRoleId)} -> 2-player TeamStore/UI -> leave -> persisted empty state; /30 refresh active");
        }

        public void BeginGuildList(int expectedCount)
        {
            pendingGuildRecords.Clear();
            if (expectedCount > pendingGuildRecords.Capacity) pendingGuildRecords.Capacity = expectedCount;
        }

        public void AddGuildRecord(int rank, double id, string name, int level, string leaderName,
            int memberCount, int maximumMembers, int plantedCount, string notice, bool applied, int autoAcceptLevel)
        {
            pendingGuildRecords.Add(new GuildRecord
            {
                Rank = checked((ushort)rank),
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                Level = checked((byte)level),
                LeaderName = leaderName ?? string.Empty,
                MemberCount = checked((ushort)memberCount),
                MaximumMembers = checked((ushort)maximumMembers),
                PlantedCount = checked((ushort)plantedCount),
                Notice = notice ?? string.Empty,
                HasApplied = applied,
                AutoAcceptLevel = checked((ushort)autoAcceptLevel)
            });
        }

        public void EndGuildList()
        {
            services.Guild.ReplaceList(pendingGuildRecords);
            EnsureGuildPresenter();
        }

        public void SetGuildInfo(double id, string name, string leaderName, int level, int legacyId,
            int memberCount, double prosperity, string notice, string slogan, int autoAcceptLevel)
        {
            services.Guild.SetInfo(new GuildInfo
            {
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                LeaderName = leaderName ?? string.Empty,
                Level = checked((byte)level),
                LegacyId = checked((ushort)legacyId),
                MemberCount = checked((ushort)memberCount),
                Prosperity = checked((uint)prosperity),
                Notice = notice ?? string.Empty,
                Slogan = slogan ?? string.Empty,
                AutoAcceptLevel = checked((ushort)autoAcceptLevel)
            });
            EnsureGuildPresenter();
            guildPresenter.ShowInfo();
            SetStatus($"Guild/54 info: {name}, {memberCount} members.");
        }

        public void BeginGuildMembers(int expectedCount)
        {
            pendingGuildMembers.Clear();
            if (expectedCount > pendingGuildMembers.Capacity) pendingGuildMembers.Capacity = expectedCount;
        }

        public void AddGuildMember(double roleId, string name, int level, int rank, int head,
            double contribution, int sex, double power, int vip, double lastOfflineSeconds, double dailyActivity)
        {
            uint guildId = services.Guild.Info?.Id ?? 0;
            pendingGuildMembers.Add(new GuildMemberRecord
            {
                Player = new PlayerSummary(checked((uint)roleId), name, checked((ushort)level),
                    checked((byte)sex), checked((byte)head), checked((ulong)power), guildId: guildId),
                Rank = checked((byte)rank),
                Contribution = checked((uint)contribution),
                VipLevel = checked((byte)vip),
                LastOfflineSeconds = checked((uint)lastOfflineSeconds),
                DailyActivity = checked((uint)dailyActivity)
            });
        }

        public void EndGuildMembers()
        {
            services.Guild.ReplaceMembers(pendingGuildMembers);
            EnsureGuildPresenter();
            guildPresenter.ShowMembers(false);
            SetStatus($"Guild/54 member list: {services.Guild.MemberCount} players.");
        }

        public void ClearGuildState()
        {
            services.Guild.ClearGuild();
            guildPresenter?.ShowInfo();
        }

        public string MakeGuildValidationName() => $"验{GetLocalUserId() % 100000:D5}";
        public void SetGuildError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureGuildAndLeaveValidation() => StartCoroutine(CaptureGuildAndLeave());

        public void CompleteGuildValidation(string expectedName)
        {
            EnsureGuildPresenter();
            if (GetLocalUserId() == 1 || !IsGuildOpen || services.Guild.HasGuild
                || services.Guild.MemberCount != 0 || guildPresenter.ShowingMembers)
            {
                Fail($"Guild final state mismatch: user={GetLocalUserId()}, open={IsGuildOpen}, hasGuild={services.Guild.HasGuild}, members={services.Guild.MemberCount}, memberView={guildPresenter.ShowingMembers}.");
                return;
            }
            Complete($"COMPLETE: /54 empty/list -> create {expectedName} -> guild info -> PlayerSummary member list -> leave/dismiss -> persisted empty state");
        }

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
            worldPresenter.ShowWorld();
            SetStatus($"World/320 map: {services.World.ChapterCount} chapters, current={checked((uint)currentChapterId)}/{checked((uint)currentStageId)}.");
        }

        public double GetFirstWorldChapterId() => services.World.Chapters.FirstOrDefault()?.Id ?? 0;
        public double GetWorldSelectedChapterId() => services.World.SelectedChapterId;
        public double GetWorldPreferredStageId() => services.World.SelectedStageId;

        public void BeginWorldStageList(int mapType, double chapterId, string chapterName, int expectedCount)
        {
            pendingWorldMapType = checked((byte)mapType);
            pendingWorldChapterId = checked((uint)chapterId);
            pendingWorldChapterName = chapterName ?? string.Empty;
            pendingWorldStages.Clear();
            pendingWorldStarBoxes.Clear();
            pendingWorldStage = null;
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

        public void AddWorldStageReward(int type, double id, double amount, string name, int picture, int quality)
        {
            if (pendingWorldStage == null) throw new InvalidOperationException("World stage reward arrived without a stage.");
            pendingWorldStage.AddReward(new RewardRecord(type, checked((uint)id), checked((uint)amount),
                name, picture, quality));
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
            worldPresenter.ShowStages();
            SetStatus($"World/320 chapter {pendingWorldChapterId}: {services.World.StageCount} stages.");
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
            double unlockedStageId, double unlockedBoxId, double unlockedStarBoxId, int stars)
        {
            services.World.ApplyBattleResult(checked((byte)foughtCount), checked((uint)foughtStageId),
                checked((uint)unlockedChapterId), checked((uint)unlockedStageId), checked((byte)stars));
            SetStatus($"World/320 PvE result: stage={checked((uint)foughtStageId)}, stars={stars}, next={checked((uint)unlockedStageId)}, box={checked((uint)unlockedBoxId)}/{checked((uint)unlockedStarBoxId)}.");
        }

        public void SetWorldError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureWorldMapAndContinue() => StartCoroutine(CaptureWorldMap());
        public void CaptureWorldDetailAndChallenge() => StartCoroutine(CaptureWorldDetail());
        public void CaptureWorldBattleAndRefresh(int rewardCount) => StartCoroutine(CaptureWorldBattleResult(rewardCount));

        public void CompleteWorldBattleValidation(double expectedStageId, int expectedRewardCount)
        {
            EnsureWorldPresenter();
            uint stageId = checked((uint)expectedStageId);
            WorldStageRecord stage = services.World.Stages.FirstOrDefault(value => value.Id == stageId);
            if (GetLocalUserId() == 1 || !IsWorldOpen || stage == null || stage.Stars == 0 || stage.Stars == byte.MaxValue
                || services.World.ChapterCount == 0 || services.World.StageCount == 0
                || worldPresenter.RenderedRewardCount == 0 || expectedRewardCount <= 0)
            {
                Fail($"World final state mismatch: user={GetLocalUserId()}, open={IsWorldOpen}, chapter={services.World.ChapterCount}, stages={services.World.StageCount}, stage={stageId}, stars={stage?.Stars ?? 255}, fought={stage?.FoughtCount ?? 0}, rewards={expectedRewardCount}/{worldPresenter.RenderedRewardCount}.");
                return;
            }
            rewardPresenter?.Hide();
            Complete($"COMPLETE: /320 world -> chapter/stage state -> detail/formation/reward preview -> PvE stage {stageId} -> op=8 settlement -> persisted stars={stage.Stars}, server fight count={stage.FoughtCount}; isolated user={GetLocalUserId()}");
        }

        public void BeginWelfareSignUpdate(bool signedToday, int signedDays, int expectedCount)
        {
            pendingWelfareSignedToday = signedToday;
            pendingWelfareSignedDays = checked((byte)signedDays);
            pendingWelfareSigns.Clear();
            if (expectedCount > pendingWelfareSigns.Capacity) pendingWelfareSigns.Capacity = expectedCount;
        }

        public void AddWelfareSign(int day, int rewardType, double rewardId, double amount, double rewardValue,
            int vipLevel, int vipMultiple, string name, int picture, int quality)
        {
            pendingWelfareSigns.Add(new WelfareSignRecord
            {
                Day = checked((byte)day),
                Reward = new RewardRecord(rewardType, checked((uint)rewardId), checked((uint)amount), name, picture, quality),
                VipLevel = checked((byte)vipLevel),
                VipMultiple = checked((byte)vipMultiple)
            });
        }

        public void EndWelfareSignUpdate()
        {
            services.Welfare.ReplaceSigns(pendingWelfareSignedToday, pendingWelfareSignedDays, pendingWelfareSigns);
            RefreshWelfareHotPoint();
            EnsureWelfarePresenter();
            SetStatus($"Welfare /199 sign: today={pendingWelfareSignedToday}, days={pendingWelfareSignedDays}, rewards={pendingWelfareSigns.Count}.");
        }

        public void BeginWelfareOnlineUpdate(int claimedCount, double accumulatedSeconds, int expectedCount)
        {
            pendingWelfareOnlineClaimed = checked((byte)claimedCount);
            pendingWelfareOnlineSeconds = checked((uint)accumulatedSeconds);
            pendingWelfareOnline.Clear();
            if (expectedCount > pendingWelfareOnline.Capacity) pendingWelfareOnline.Capacity = expectedCount;
        }

        public void AddWelfareOnline(int id, int cumulativeMinutes, double requiredSeconds, int rewardType,
            double rewardId, double amount, string name, int picture, int quality)
        {
            pendingWelfareOnline.Add(new WelfareOnlineRecord
            {
                Id = checked((byte)id), CumulativeMinutes = checked((ushort)cumulativeMinutes),
                RequiredSeconds = checked((uint)requiredSeconds),
                Reward = new RewardRecord(rewardType, checked((uint)rewardId), checked((uint)amount), name, picture, quality)
            });
        }

        public void EndWelfareOnlineUpdate()
        {
            services.Welfare.ReplaceOnline(pendingWelfareOnlineClaimed, pendingWelfareOnlineSeconds,
                services.ServerTime.UnixSeconds, pendingWelfareOnline);
            RefreshWelfareHotPoint();
            EnsureWelfarePresenter();
            SetStatus($"Welfare /222 online: claimed={pendingWelfareOnlineClaimed}, elapsed={pendingWelfareOnlineSeconds}s, rewards={pendingWelfareOnline.Count}.");
        }

        public void SetWelfareError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureWelfareAndClaim() => StartCoroutine(CaptureWelfareTabsAndClaim());

        public void CompleteWelfareValidation(int signedDays)
        {
            EnsureWelfarePresenter();
            if (GetLocalUserId() == 1 || !IsWelfareOpen || !services.Welfare.SignedToday
                || services.Welfare.SignedDays != signedDays || services.Welfare.Signs.Count == 0
                || services.Welfare.Online.Count == 0 || services.ProtocolRegistry.PendingCount != 0
                || IsWelfareHotPointVisible != services.Welfare.HasClaimable)
            {
                Fail($"Welfare final state mismatch: user={GetLocalUserId()}, open={IsWelfareOpen}, today={services.Welfare.SignedToday}, days={services.Welfare.SignedDays}/{signedDays}, sign={services.Welfare.Signs.Count}, online={services.Welfare.Online.Count}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            rewardPresenter?.Hide();
            welfarePresenter.SelectTab(0);
            Complete($"COMPLETE: /199 sign list -> single daily claim -> authoritative re-pull days={signedDays}; /222 online status={services.Welfare.OnlineClaimedCount}/{services.Welfare.Online.Count}; /223 unavailable empty state; isolated user={GetLocalUserId()}");
        }

        public void AddShopRecord(int grid, double id, int buyCount, string name,
            string description, int picture, int quality)
        {
            pendingShopRecords.Add(services.ShopCatalog.Build(checked((byte)grid), checked((ushort)id),
                checked((ushort)buyCount), name, description, picture, quality));
        }

        public void EndShopUpdate()
        {
            services.Shop.Replace(pendingShopType, pendingShopRefreshTimes, pendingShopFreeTimes,
                pendingShopRefreshRemaining, services.ServerTime.UnixSeconds, pendingShopRecords);
            EnsureShopPresenter();
            ShowShop();
        }

        public bool PrepareShopPurchaseValidation(double rawId)
        {
            ushort id = checked((ushort)rawId);
            if (GetLocalUserId() == 1)
            {
                Fail("Shop mutation validation requires an isolated userId, not default userId=1.");
                return false;
            }
            if (!services.ServerTime.IsSynchronized)
            {
                Fail("Shop validation requires synchronized server time.");
                return false;
            }
            if (!services.Shop.TryGet(id, out ShopRecord item) || item.IsSoldOut)
            {
                Fail($"Shop validation item is missing or sold out: id={id}.");
                return false;
            }
            long currency = services.Currencies.Get(item.CostType);
            if (currency < item.UnitCost)
            {
                Fail($"Shop validation currency is insufficient: type={item.CostType}, have={currency}, need={item.UnitCost}.");
                return false;
            }
            validationShopId = id;
            validationShopBuyCount = item.BuyCount;
            validationShopCurrencyType = item.CostType;
            validationShopExpectedCurrency = currency - item.UnitCost;
            validationShopRewardType = item.RewardType;
            validationShopRewardAmount = item.RewardAmount;
            EnsureShopPresenter();
            if (!shopPresenter.Select(id))
            {
                Fail($"Shop validation could not select id={id}.");
                return false;
            }
            ShowShopPurchaseConfirmation(item);
            StartCoroutine(CaptureShopConfirmationAndConfirm(id));
            return true;
        }

        public bool ApplyShopPurchase(double rawId, int buyCount, int rewardType, double rewardAmount)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item)
                || item.RewardType != rewardType || item.RewardAmount != checked((uint)rewardAmount))
                return false;
            return services.Shop.ApplyPurchase(id, checked((ushort)buyCount));
        }

        public void ShowShopPurchaseReward(double rawId, int rewardType, double rewardAmount)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item)) return;
            services.Rewards.Replace("购买获得", new[]
            {
                new RewardRecord(rewardType, checked((uint)Math.Max(0, item.RewardId)),
                    checked((uint)rewardAmount), item.Name, item.Picture, item.Quality)
            });
            EnsureRewardPresenter();
            rewardPresenter.Show();
        }

        public void CompleteShopPurchaseValidation(double rawId)
        {
            ushort id = checked((ushort)rawId);
            bool found = services.Shop.TryGet(id, out ShopRecord item);
            long currency = services.Currencies.Get(validationShopCurrencyType);
            bool rewardValid = ValidateRewardPresentation(1, true);
            if (!found || id != validationShopId || item.BuyCount != validationShopBuyCount + 1
                || currency != validationShopExpectedCurrency || item.RewardType != validationShopRewardType
                || item.RewardAmount != validationShopRewardAmount || !rewardValid
                || services.ProtocolRegistry.PendingCount != 0 || !IsShopOpen
                || !services.ServerTime.IsSynchronized || shopPresenter.MissingIconCount != 0)
            {
                Fail($"Shop validation mismatch: found={found}, id={id}/{validationShopId}, count={(found ? item.BuyCount : 0)}/{validationShopBuyCount + 1}, currency={currency}/{validationShopExpectedCurrency}, reward={rewardValid}, pending={services.ProtocolRegistry.PendingCount}, open={IsShopOpen}, time={services.ServerTime.IsSynchronized}, missing={shopPresenter?.MissingIconCount ?? -1}.");
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /221 list -> ShopStore/limits/server time/currency -> confirmed single purchase id={id} -> persisted count={item.BuyCount}");
        }

        public void BeginHeroUpdate(int followHeroId, int expectedCount)
        {
            pendingHeroes.Clear();
            if (expectedCount > pendingHeroes.Capacity) pendingHeroes.Capacity = expectedCount;
            pendingFollowHeroId = followHeroId;
        }

        private int pendingFollowHeroId;

        public void AddHeroRecord(int id, int fightPosition, string name, int star, int breakLevel, int level,
            double experience, double maxExperience, double power, double attack, double physicalDefense,
            double magicDefense, double health, double speed)
        {
            pendingHeroes.Add(new HeroRecord(id, fightPosition, name, star, breakLevel, level,
                checked((uint)experience), checked((uint)maxExperience), checked((ulong)power),
                checked((uint)attack), checked((uint)physicalDefense), checked((uint)magicDefense),
                checked((ulong)health), checked((uint)speed)));
        }

        public void EndHeroUpdate() => services.Heroes.Replace(pendingFollowHeroId, pendingHeroes);

        public void BeginFormationUpdate(int activeId, int expectedCount)
        {
            pendingActiveFormationId = activeId;
            pendingFormations.Clear();
            pendingFormationDisplay.Clear();
            pendingFormationCombat.Clear();
            if (expectedCount > pendingFormations.Capacity) pendingFormations.Capacity = expectedCount;
        }

        public void AddFormationRecord(int id, int level) => pendingFormations.Add(new FormationRecord(id, level));

        public void AddFormationDisplayHero(int index, int heroId)
        {
            while (pendingFormationDisplay.Count < index) pendingFormationDisplay.Add(0);
            pendingFormationDisplay[index - 1] = heroId;
        }

        public void AddFormationCombatHero(int index, int heroId)
        {
            while (pendingFormationCombat.Count < index) pendingFormationCombat.Add(0);
            pendingFormationCombat[index - 1] = heroId;
        }

        public void EndFormationUpdate()
        {
            services.Formation.Replace(pendingActiveFormationId, pendingFormations,
                pendingFormationDisplay, pendingFormationCombat);
            var positions = new Dictionary<int, int>();
            for (int index = 0; index < pendingFormationCombat.Count; index++)
                if (pendingFormationCombat[index] > 0) positions[pendingFormationCombat[index]] = index + 1;
            services.Heroes.SetFightPositions(positions);
            EnsureHeroPresenter();
            heroDetailView.SetVisible(true);
            if (services.UiStack.Current != heroListView) services.UiStack.Push(heroListView);
            SetStatus($"Hero formation UI active: {services.Heroes.Count} heroes, formation={services.Formation.ActiveFormationId}.");
        }

        public void CompleteHeroReadValidation()
        {
            EnsureHeroPresenter();
            if (services.Heroes.Count <= 0 || services.Formation.Formations.Count <= 0
                || heroPresenter.ItemCount != services.Heroes.Count || !IsHeroOpen)
            {
                Fail($"Hero read validation mismatch: heroes={services.Heroes.Count}, rendered={heroPresenter.ItemCount}, formations={services.Formation.Formations.Count}, open={IsHeroOpen}.");
                return;
            }
            Complete($"COMPLETE: main formation button -> /24 HeroStore ({services.Heroes.Count}) -> /48 FormationStore -> hero list/detail UI");
        }

        public int GetFormationCombatCount() => services.Formation.CombatHeroes.Count;
        public int GetFormationHeroAt(int position)
            => position > 0 && position <= services.Formation.CombatHeroes.Count
                ? services.Formation.CombatHeroes[position - 1] : 0;

        public void CompleteFormationMutationValidation(int heroId, int originalPosition, int targetPosition)
        {
            if (services.Formation.GetCombatPosition(heroId) != originalPosition || !IsHeroOpen)
            {
                Fail($"Formation mutation restore mismatch: hero={heroId}, current={services.Formation.GetCombatPosition(heroId)}, expected={originalPosition}.");
                return;
            }
            Complete($"COMPLETE: /24 HeroStore -> /48 snapshot -> /48 op=4 hero {heroId} position {originalPosition}->{targetPosition} -> pushed snapshot -> restore {targetPosition}->{originalPosition} -> pushed snapshot");
        }

        public void BeginHeroEquipmentUpdate(int expectedCount)
        {
            pendingHeroEquipment.Clear();
            if (expectedCount > pendingHeroEquipment.Capacity) pendingHeroEquipment.Capacity = expectedCount;
        }

        public void BeginHeroEquipmentRecord(double uid, int templateId, int formationPosition, double experience,
            int baseAttributeType, double baseAttributeValue)
        {
            pendingEquipmentUid = checked((uint)uid);
            pendingEquipmentTemplateId = templateId;
            pendingEquipmentFormationPosition = formationPosition;
            pendingEquipmentExperience = checked((uint)experience);
            pendingEquipmentBaseAttributeType = baseAttributeType;
            pendingEquipmentBaseAttributeValue = checked((uint)baseAttributeValue);
            pendingCultivation.Clear();
        }

        public void AddHeroEquipmentCultivation(int type, int level)
            => pendingCultivation.Add(new CultivationLevel(type, level));

        public void EndHeroEquipmentRecord()
        {
            pendingHeroEquipment.Add(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId)));
        }

        public void EndHeroEquipmentUpdate() => services.HeroEquipment.Replace(pendingHeroEquipment);

        public void UpsertHeroEquipmentRecord()
        {
            services.HeroEquipment.Upsert(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId)));
        }

        public void BeginFaBaoUpdate(int expectedCount)
        {
            pendingFaBao.Clear();
            if (expectedCount > pendingFaBao.Capacity) pendingFaBao.Capacity = expectedCount;
        }

        public void BeginFaBaoRecord(double uid, int templateId, int formationPosition, int slot, double experience)
        {
            pendingEquipmentUid = checked((uint)uid);
            pendingEquipmentTemplateId = templateId;
            pendingEquipmentFormationPosition = formationPosition;
            pendingFaBaoSlot = slot;
            pendingEquipmentExperience = checked((uint)experience);
            pendingCultivation.Clear();
        }

        public void AddFaBaoCultivation(int type, int level)
            => pendingCultivation.Add(new CultivationLevel(type, level));

        public void EndFaBaoRecord()
        {
            pendingFaBao.Add(new FaBaoRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingFaBaoSlot, pendingEquipmentExperience,
                pendingCultivation.ToArray(), services.EquipmentCatalog.GetFaBao(pendingEquipmentTemplateId)));
        }

        public void EndFaBaoUpdate() => services.FaBao.Replace(pendingFaBao);

        public void UpsertFaBaoRecord()
        {
            services.FaBao.Upsert(new FaBaoRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingFaBaoSlot, pendingEquipmentExperience,
                pendingCultivation.ToArray(), services.EquipmentCatalog.GetFaBao(pendingEquipmentTemplateId)));
        }

        public bool SetHeroEquipmentFormation(double uid, int formationPosition)
            => services.HeroEquipment.SetFormation(checked((uint)uid), formationPosition);

        public bool SetFaBaoFormation(double uid, int formationPosition, int slot)
            => services.FaBao.SetFormation(checked((uint)uid), formationPosition, slot);

        public double GetFirstHeroEquipmentUid(bool unwornOnly)
        {
            HeroEquipmentRecord value = services.HeroEquipment.Items
                .FirstOrDefault(item => !unwornOnly || item.FormationPosition == 0);
            return value.Uid;
        }

        public double GetFirstFaBaoUid(bool unwornOnly)
        {
            FaBaoRecord value = services.FaBao.Items
                .FirstOrDefault(item => !unwornOnly || item.FormationPosition == 0);
            return value.Uid;
        }

        public int GetHeroEquipmentFormation(double uid)
            => services.HeroEquipment.TryGet(checked((uint)uid), out HeroEquipmentRecord value) ? value.FormationPosition : -1;

        public int GetHeroEquipmentStrengthLevel(double uid)
            => services.HeroEquipment.TryGet(checked((uint)uid), out HeroEquipmentRecord value) ? value.GetLevel(1) : -1;

        public int GetFaBaoFormation(double uid)
            => services.FaBao.TryGet(checked((uint)uid), out FaBaoRecord value) ? value.FormationPosition : -1;

        public void ShowHeroEquipment()
        {
            EnsureHeroEquipmentPresenter();
            int formationPosition = 1;
            for (int index = 0; index < services.Formation.CombatHeroes.Count; index++)
            {
                if (services.Formation.CombatHeroes[index] <= 0) continue;
                formationPosition = index + 1;
                break;
            }
            heroEquipmentPresenter.Show(formationPosition);
            if (services.UiStack.Current != heroEquipmentListView) services.UiStack.Push(heroEquipmentListView);
            SetStatus($"Hero equipment UI active: equipment={services.HeroEquipment.Count}, fabao={services.FaBao.Count}.");
        }

        public void CompleteHeroEquipmentReadValidation()
        {
            ShowHeroEquipment();
            if (heroEquipmentPresenter.ItemCount != services.HeroEquipment.Count + services.FaBao.Count
                || !IsHeroEquipmentOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Hero equipment read validation mismatch: equipment={services.HeroEquipment.Count}, fabao={services.FaBao.Count}, rendered={heroEquipmentPresenter.ItemCount}, open={IsHeroEquipmentOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            Complete($"COMPLETE: /319 op=1 HeroEquipmentStore ({services.HeroEquipment.Count}) + op=17 FaBaoStore ({services.FaBao.Count}) -> list/detail UI");
        }

        public void CompleteHeroEquipmentMutationValidation(double equipmentUid, int strengthBefore,
            int strengthAfter, double faBaoUid, int formationPosition)
        {
            ShowHeroEquipment();
            uint equipmentId = checked((uint)equipmentUid);
            uint faBaoId = checked((uint)faBaoUid);
            bool restored = services.HeroEquipment.TryGet(equipmentId, out HeroEquipmentRecord equip)
                && equip.FormationPosition == 0 && equip.GetLevel(1) == strengthAfter
                && services.FaBao.TryGet(faBaoId, out FaBaoRecord treasure) && treasure.FormationPosition == 0;
            if (!restored || strengthAfter <= strengthBefore || heroEquipmentPresenter.MissingIconCount > 0)
            {
                Fail($"Hero equipment mutation mismatch: restored={restored}, strength={strengthBefore}->{strengthAfter}, missingIcons={heroEquipmentPresenter.MissingIconCount}.");
                return;
            }
            Complete($"COMPLETE: /319 equipment {equipmentId} wear@{formationPosition} -> strengthen {strengthBefore}->{strengthAfter} -> takeoff; fabao {faBaoId} wear@{formationPosition}/5 -> takeoff; stores/list/detail restored");
        }

        public void BeginTaskUpdate(int expectedCount)
        {
            pendingTaskRecords.Clear();
            if (expectedCount > 0) pendingTaskRecords.Capacity = Math.Max(pendingTaskRecords.Capacity, expectedCount);
        }

        public void AddTaskRecord(int id, uint progress, int state)
        {
            pendingTaskRecords.Add(services.Tasks.CreateRecord(id, progress, unchecked((byte)state)));
        }

        public void EndTaskUpdate()
        {
            services.Tasks.Replace(pendingTaskRecords);
            EnsureTaskPresenter();
            taskPresenter.Render();
            ShowTask();
        }

        public void UpsertTaskRecord(int id, uint progress, int state)
        {
            services.Tasks.Upsert(id, progress, unchecked((byte)state));
        }

        public void MarkTaskClaimed(int id) => services.Tasks.MarkClaimed(id);

        public void UpsertTrackedMission(int id, string name)
        {
            services.Tasks.UpsertTrackedMission(id, name);
            ClientLog.Info("Task", $"Tracked mission added: {id}", name);
        }

        public void RemoveTrackedMission(int id)
        {
            services.Tasks.RemoveTrackedMission(id);
            ClientLog.Info("Task", $"Tracked mission removed: {id}");
        }

        public void UpdateTaskHotPoint(int type, int state)
        {
            if (type != 101) return;
            EnsureMainTaskTracker();
            mainTaskTracker.SetServerHotPoint(state != 0);
        }

        public void CompleteTaskMutationValidation(int taskId, int rewardCount)
        {
            if (!services.Tasks.TryGet(taskId, out TaskRecord record) || record.State != 2)
            {
                Fail($"Task mutation validation did not persist claimed state for task {taskId}.");
                return;
            }
            EnsureMainTaskTracker();
            if (rewardCount <= 0)
            {
                Fail("Task mutation validation returned no reward records.");
                return;
            }
            if (!ValidateRewardPresentation(rewardCount, true))
            {
                Fail($"Task mutation validation reward presentation mismatch: protocol={rewardCount}, model={services.Rewards.Count}.");
                return;
            }
            if (services.Tasks.HasClaimable || mainTaskTracker.IsHotPointVisible)
            {
                Fail("Task mutation validation red dot did not clear after claiming the only completed task.");
                return;
            }
            Complete($"COMPLETE: /37 op=2 incremental -> red dot/tracker -> /37 op=3 claim -> RewardStore/RewardPresenter ({rewardCount}) -> persisted state=2");
        }

        public void SetStatus(string value)
        {
            status = value ?? string.Empty;
            ClientLog.Info("App", status);
        }

        public void Complete(string value) => SetStatus(value);

        public void Fail(string value)
        {
            status = value ?? "Unknown error";
            services?.State.Change(AppState.Failed, status);
            ClientLog.Error("App", status);
            loadingPresenter?.Clear();
            try
            {
                EnsureErrorPresenter();
                errorPresenter?.Show("运行错误", status);
            }
            catch (Exception presenterException)
            {
                ClientLog.Error("UI", "Error presenter failed", presenterException.Message);
            }
        }

        private void DispatchToLua(ushort command, LegacyTcpMessage message)
        {
            try { CallLua(onPacket, $"Protocol.OnPacket/{command}", (int)command, message); }
            catch (Exception exception) { Fail($"Lua packet handler failed for command {command}: {exception.Message}"); }
        }

        private void HandleNetworkState(NetworkState state)
        {
            SetStatus($"Network: {state}");
        }

        private void HandleDisconnected(string reason)
        {
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            disconnectReason = reason;
            services.State.Change(AppState.Disconnected, reason);
            SetStatus($"Disconnected: {reason}");
            try { CallLua(onDisconnected, "Network.OnDisconnected", reason); }
            catch (Exception exception) { Fail(exception.Message); }
            if (!autoReconnectRunning) _ = RunAutoReconnectAsync();
        }

        private async Task RunAutoReconnectAsync()
        {
            if (!services.Config.AutoReconnect) return;
            autoReconnectRunning = true;
            try
            {
                while (this && services.Network.State != NetworkState.Connected
                    && reconnectAttempts < services.Config.MaxReconnectAttempts)
                {
                    reconnectAttempts++;
                    int backoffMultiplier = 1 << ((reconnectAttempts - 1) * 2);
                    int delayMilliseconds = Math.Min(
                        services.Config.ReconnectDelayMilliseconds * backoffMultiplier,
                        20000);
                    SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts} in {delayMilliseconds} ms...");
                    await Task.Delay(delayMilliseconds);
                    if (!this || services.Network.State == NetworkState.Connected) return;
                    try
                    {
                        ShowLoading("auto-reconnect", "正在重新连接…", 25f);
                        SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts}...");
                        await services.Network.ReconnectAsync(services.Config.ConnectTimeoutSeconds);
                        reconnectAttempts = 0;
                        disconnectReason = null;
                        services.State.Change(AppState.LoadingRole, "Auto reconnect succeeded");
                        CallLua(onConnected, "Login.OnConnected.AfterAutoReconnect");
                        return;
                    }
                    catch (Exception exception)
                    {
                        HideLoading("auto-reconnect");
                        disconnectReason = exception.Message;
                        SetStatus($"Auto reconnect {reconnectAttempts}/{services.Config.MaxReconnectAttempts} failed: {exception.Message}");
                    }
                }
            }
            finally
            {
                autoReconnectRunning = false;
            }
        }

        private void HandleLoginClick() => InvokeLuaOrFail(onLoginClicked, "Login.OnLoginClicked");
        private void HandleRoleCreateClick() => InvokeLuaOrFail(onRoleCreateClicked, "Login.OnRoleCreateClicked");
        private void HandleBagClick() => InvokeLuaOrFail(onBagClicked, "Bag.OnBagClicked");
        private void HandleSettingsClick()
        {
            try { CallLua(onSettingsClicked, "Settings.OnClicked"); }
            catch (Exception exception) { Fail($"Settings open failed: {exception.Message}"); }
        }
        private void HandleTaskClick()
        {
            try { CallLua(onTaskClicked, "Task.OnClicked"); }
            catch (Exception exception) { Fail($"Task open failed: {exception.Message}"); }
        }
        private void HandleHeroClick()
        {
            try { CallLua(onHeroClicked, "Hero.OnClicked"); }
            catch (Exception exception) { Fail($"Hero open failed: {exception.Message}"); }
        }
        private void HandleMailClick()
        {
            try { CallLua(onMailClicked, "Mail.OnClicked"); }
            catch (Exception exception) { Fail($"Mail open failed: {exception.Message}"); }
        }
        private void HandleShopClick()
        {
            try { CallLua(onShopClicked, "Shop.OnClicked"); }
            catch (Exception exception) { Fail($"Shop open failed: {exception.Message}"); }
        }
        private void HandleFriendClick()
        {
            try { CallLua(onFriendClicked, "Friend.OnClicked"); }
            catch (Exception exception) { Fail($"Friend open failed: {exception.Message}"); }
        }
        private void HandleChatClick()
        {
            try { CallLua(onChatClicked, "Chat.OnClicked"); }
            catch (Exception exception) { Fail($"Chat open failed: {exception.Message}"); }
        }

        private void HandleTeamClick()
        {
            try { CallLua(onTeamClicked, "Team.OnClicked"); }
            catch (Exception exception) { Fail($"Team open failed: {exception.Message}"); }
        }

        private void HandleGuildClick()
        {
            try { CallLua(onGuildClicked, "Guild.OnClicked"); }
            catch (Exception exception) { Fail($"Guild open failed: {exception.Message}"); }
        }

        private void HandleWorldClick()
        {
            try { CallLua(onWorldClicked, "World.OnClicked"); }
            catch (Exception exception) { Fail($"World open failed: {exception.Message}"); }
        }

        private void HandleWelfareClick()
        {
            try { CallLua(onWelfareClicked, "Welfare.OnClicked"); }
            catch (Exception exception) { Fail($"Welfare open failed: {exception.Message}"); }
        }

        private Button EnsureRuntimeTeamEntry()
        {
            Transform existing = mainView.GameObject.transform.Find("TeamEntryRuntime");
            if (existing != null) return existing.GetComponent<Button>();
            GameObject entry = new GameObject("TeamEntryRuntime", typeof(RectTransform), typeof(Image), typeof(Button));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(mainView.GameObject.transform, false);
            rect.anchorMin = new Vector2(0.125f, 0.025f);
            rect.anchorMax = new Vector2(0.23f, 0.105f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = entry.GetComponent<Image>();
            image.color = new Color(0.42f, 0.22f, 0.12f, 0.95f);
            Button button = entry.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(HandleTeamClick);
            GameObject labelObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            RectTransform labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.SetParent(rect, false);
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 20;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.text = "队伍";
            return button;
        }

        private Button EnsureRuntimeChatEntry()
        {
            Transform existing = mainView.GameObject.transform.Find("ChatEntryRuntime");
            if (existing != null) return existing.GetComponent<Button>();
            GameObject entry = new GameObject("ChatEntryRuntime", typeof(RectTransform), typeof(Image), typeof(Button));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(mainView.GameObject.transform, false);
            rect.anchorMin = new Vector2(0.015f, 0.025f);
            rect.anchorMax = new Vector2(0.12f, 0.105f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = entry.GetComponent<Image>();
            image.color = new Color(0.12f, 0.25f, 0.42f, 0.95f);
            Button button = entry.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(HandleChatClick);
            GameObject labelObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            RectTransform labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.SetParent(rect, false);
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 20;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.text = "聊天";
            return button;
        }

        private Button EnsureRuntimeWelfareEntry()
        {
            Transform existing = mainView.GameObject.transform.Find("WelfareEntryRuntime");
            if (existing != null) { RefreshWelfareHotPoint(); return existing.GetComponent<Button>(); }
            GameObject entry = new GameObject("WelfareEntryRuntime", typeof(RectTransform), typeof(Image), typeof(Button));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(mainView.GameObject.transform, false);
            rect.anchorMin = new Vector2(0.82f, 0.87f);
            rect.anchorMax = new Vector2(0.94f, 0.95f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = entry.GetComponent<Image>();
            image.color = new Color(0.68f, 0.24f, 0.16f, 0.96f);
            Button button = entry.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(HandleWelfareClick);
            GameObject labelObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            RectTransform labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.SetParent(rect, false); labelRect.anchorMin = Vector2.zero; labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); label.fontSize = 22;
            label.alignment = TextAnchor.MiddleCenter; label.color = Color.white; label.text = "福利";
            GameObject hotPoint = new GameObject("HotPoint", typeof(RectTransform), typeof(Image));
            RectTransform hotRect = hotPoint.GetComponent<RectTransform>();
            hotRect.SetParent(rect, false); hotRect.anchorMin = new Vector2(0.86f, 0.72f); hotRect.anchorMax = new Vector2(0.98f, 0.94f);
            hotRect.offsetMin = hotRect.offsetMax = Vector2.zero;
            hotPoint.GetComponent<Image>().color = new Color(0.95f, 0.08f, 0.05f, 1f);
            RefreshWelfareHotPoint();
            return button;
        }

        private void RefreshWelfareHotPoint()
        {
            Transform hotPoint = mainView?.GameObject.transform.Find("WelfareEntryRuntime/HotPoint");
            if (hotPoint != null) hotPoint.gameObject.SetActive(services?.Welfare.HasClaimable == true);
        }
        private static IEnumerator InvokeButtonNextFrame(Button button) { yield return null; button.onClick.Invoke(); }

        private IEnumerator CaptureMailDetailAndClaim(uint mailId)
        {
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-mail-detail.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onMailClaimClicked, "Mail.OnClaimClicked", (double)mailId);
        }

        private IEnumerator CaptureWelfareTabsAndClaim()
        {
            EnsureWelfarePresenter();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            welfarePresenter.SelectTab(0);
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-sign.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(1);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-online.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(2);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-stage-empty.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(0);
            InvokeLuaOrFail(onWelfareClaimSign, "Welfare.ClaimSign");
        }

        private void ShowShopPurchaseConfirmation(ShopRecord item)
        {
            EnsureErrorPresenter();
            string limitText = item.Limit < 0 ? "不限购" : $"剩余限购 {item.RemainingLimit} 次";
            errorPresenter.ShowConfirmation("购买确认",
                $"花费 {item.UnitCost} {item.CostName}购买 {item.RewardAmount}×{item.Name}？\n{limitText}",
                () => InvokeLuaOrFail(onShopBuyConfirmed, "Shop.OnBuyConfirmed", (double)item.Id));
        }

        private IEnumerator CaptureShopConfirmationAndConfirm(ushort itemId)
        {
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-shop-confirm.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            if (!errorPresenter.IsVisible)
            {
                Fail($"Shop confirmation was not visible for id={itemId}.");
                yield break;
            }
            errorPresenter.Confirm();
        }

        private IEnumerator CaptureFriendAndDelete(uint roleId)
        {
            yield return new WaitForSecondsRealtime(2.1f);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-friend-list.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onFriendDelete, "Friend.OnDelete", (double)roleId);
        }

        private IEnumerator CaptureTeamAndLeave(uint peerRoleId)
        {
            yield return new WaitForSecondsRealtime(1.5f);
            EnsureTeamPresenter();
            if (!services.Team.ContainsPlayer(peerRoleId) || services.Team.PlayerCount != 2
                || teamPresenter.RenderedPlayerCount != 2)
            {
                Fail($"Team joined-state mismatch: peer={peerRoleId}, players={services.Team.PlayerCount}, rendered={teamPresenter.RenderedPlayerCount}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-team-members.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onTeamLeave, "Team.OnLeave");
        }

        private IEnumerator CaptureGuildAndLeave()
        {
            yield return new WaitForSecondsRealtime(1.5f);
            EnsureGuildPresenter();
            uint roleId = services.Player.RoleId;
            if (!services.Guild.HasGuild || services.Guild.MemberCount != 1
                || !services.Guild.ContainsMember(roleId) || guildPresenter.RenderedMemberCount != 1)
            {
                Fail($"Guild joined-state mismatch: guild={services.Guild.Info?.Id ?? 0}, role={roleId}, members={services.Guild.MemberCount}, rendered={guildPresenter.RenderedMemberCount}.");
                yield break;
            }
            guildPresenter.ShowMembers(false);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-guild-members.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onGuildLeave, "Guild.OnLeave");
        }

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
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onWorldOpenPreferredStage, "World.OpenPreferredStage");
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
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-detail.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onWorldChallenge, "World.Challenge");
        }

        private IEnumerator CaptureWorldBattleResult(int rewardCount)
        {
            yield return new WaitForSecondsRealtime(1.25f);
            if (!ValidateRewardPresentation(rewardCount, false))
            {
                Fail($"World settlement reward presentation mismatch: expected={rewardCount}, actual={services.Rewards.Count}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-result.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            rewardPresenter?.Hide();
            InvokeLuaOrFail(onWorldRefresh, "World.RefreshAfterBattle");
        }

        private static string BuildUiMigrationPath(string fileName)
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            return path;
        }

        private void EnsureBagPresenter()
        {
            bagView = bagView ?? services.UiRouter.FindBySource("zhujue/beibao");
            if (bagView == null) throw new InvalidOperationException("zhujue/beibao CocosUiBinding was not found.");
            bagPresenter = bagPresenter ?? new BagPresenter(bagView, services.Bag, services.Resources,
                item => InvokeLuaOrFail(onBagUseClicked, "Bag.OnUseClicked", item.Slot, item.Quantity));
        }

        private void EnsureSettingsPresenter()
        {
            settingsView = settingsView ?? services.UiRouter.FindBySource("zhujue/SystemLayer");
            if (settingsView == null) throw new InvalidOperationException("zhujue/SystemLayer CocosUiBinding was not found.");
            settingsPresenter = settingsPresenter ?? new SettingsPresenter(settingsView, ReturnToLogin, SetStatus);
        }

        private void EnsureRewardPresenter()
        {
            rewardView = rewardView ?? services.UiRouter.FindBySource("common/tanchuangjiangli");
            if (rewardView == null) throw new InvalidOperationException("common/tanchuangjiangli CocosUiBinding was not found.");
            rewardPresenter = rewardPresenter ?? new RewardPresenter(rewardView, services.Rewards, services.Resources);
        }

        private void EnsureHeroPresenter()
        {
            heroListView = heroListView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongListLayer");
            heroDetailView = heroDetailView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongInfoLayer");
            if (heroListView == null || heroDetailView == null)
                throw new InvalidOperationException("Hero list/detail CocosUiBindings were not found.");
            heroPresenter = heroPresenter ?? new HeroPresenter(heroListView, heroDetailView, services.Heroes, services.Formation);
        }

        private void EnsureHeroEquipmentPresenter()
        {
            heroEquipmentListView = heroEquipmentListView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeibeibao");
            heroEquipmentDetailView = heroEquipmentDetailView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            if (heroEquipmentListView == null || heroEquipmentDetailView == null)
                throw new InvalidOperationException("Hero equipment list/detail CocosUiBindings were not found.");
            heroEquipmentPresenter = heroEquipmentPresenter ?? new HeroEquipmentPresenter(
                heroEquipmentListView, heroEquipmentDetailView, services.HeroEquipment, services.FaBao, services.Resources,
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentWear, "HeroEquipment.Wear", (double)uid, position),
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentTakeOff, "HeroEquipment.TakeOff", (double)uid, position),
                (uid, position, slot) => InvokeLuaOrFail(onFaBaoWear, "FaBao.Wear", (double)uid, position, slot),
                uid => InvokeLuaOrFail(onFaBaoTakeOff, "FaBao.TakeOff", (double)uid));
        }

        private void EnsureTaskPresenter()
        {
            taskBackgroundView = taskBackgroundView ?? services.UiRouter.FindBySource("huodong/huodong_bg");
            taskView = taskView ?? services.UiRouter.FindBySource("huodong/RenwuLayer");
            if (taskBackgroundView == null) throw new InvalidOperationException("huodong/huodong_bg CocosUiBinding was not found.");
            if (taskView == null) throw new InvalidOperationException("huodong/RenwuLayer CocosUiBinding was not found.");
            taskPresenter = taskPresenter ?? new TaskPresenter(taskView, services.Tasks,
                item => InvokeLuaOrFail(onTaskClaimClicked, "Task.OnClaimClicked", item.Id));
            try
            {
                taskBackgroundView.BindClick("Layer/Panel_1/Title/CloseBtn", () => services.UiStack.Pop(), true);
            }
            catch (InvalidOperationException exception)
            {
                ClientLog.Warning("Task", "Task close button was not bound", exception.Message);
            }
        }

        private void EnsureMailPresenter()
        {
            mailView = mailView ?? services.UiRouter.FindBySource("MailLayer");
            if (mailView == null) throw new InvalidOperationException("MailLayer CocosUiBinding was not found.");
            mailPresenter = mailPresenter ?? new MailPresenter(mailView, services.Mails, services.Resources,
                id => InvokeLuaOrFail(onMailClaimClicked, "Mail.OnClaimClicked", (double)id));
        }

        private void EnsureShopPresenter()
        {
            shopView = shopView ?? services.UiRouter.FindBySource("shop/shangcheng");
            if (shopView == null) throw new InvalidOperationException("shop/shangcheng CocosUiBinding was not found.");
            shopPresenter = shopPresenter ?? new ShopPresenter(shopView, services.Shop, services.Currencies,
                services.Resources, services.ServerTime, ShowShopPurchaseConfirmation);
        }

        private void EnsureFriendPresenter()
        {
            friendView = friendView ?? services.UiRouter.FindBySource("common/FriendLayer");
            if (friendView == null) throw new InvalidOperationException("common/FriendLayer CocosUiBinding was not found.");
            friendPresenter = friendPresenter ?? new FriendPresenter(friendView, services.Friends,
                () => InvokeLuaOrFail(onFriendRequestList, "Friend.RequestList"),
                () => InvokeLuaOrFail(onFriendRequestApplications, "Friend.RequestApplications"),
                id => InvokeLuaOrFail(onFriendApply, "Friend.Apply", (double)id),
                (id, accept) => InvokeLuaOrFail(onFriendDeal, "Friend.Deal", (double)id, accept),
                id => InvokeLuaOrFail(onFriendDelete, "Friend.Delete", (double)id));
        }

        private void EnsureChatPresenter()
        {
            chatView = chatView ?? services.UiRouter.FindBySource("MainChatLayer");
            if (chatView == null) throw new InvalidOperationException("MainChatLayer CocosUiBinding was not found.");
            chatPresenter = chatPresenter ?? new ChatPresenter(chatView, services.Chat,
                (channel, content, targetId) => InvokeLuaOrFail(onChatSend, "Chat.Send", channel, content, (double)targetId));
        }

        private void EnsureTeamPresenter()
        {
            teamView = teamView ?? services.UiRouter.FindBySource("TeamMembersLayer");
            if (teamView == null) throw new InvalidOperationException("TeamMembersLayer CocosUiBinding was not found.");
            teamPresenter = teamPresenter ?? new TeamPresenter(teamView, services.Team, services.Player,
                () => InvokeLuaOrFail(onTeamCreate, "Team.Create"),
                id => InvokeLuaOrFail(onTeamInvite, "Team.Invite", (double)id),
                () => InvokeLuaOrFail(onTeamLeave, "Team.Leave"));
        }

        private void EnsureGuildPresenter()
        {
            guildView = guildView ?? services.UiRouter.FindBySource("bangpai/GangsApplyLayer");
            guildInfoView = guildInfoView ?? services.UiRouter.FindBySource("bangpai/GangsLayer");
            guildMemberView = guildMemberView ?? services.UiRouter.FindBySource("bangpai/GangsMemberLayer");
            guildCreateView = guildCreateView ?? services.UiRouter.FindBySource("bangpai/GangsfoundLayer");
            if (guildView == null || guildInfoView == null || guildMemberView == null || guildCreateView == null)
                throw new InvalidOperationException("Guild imported CocosUiBindings were not found.");
            guildPresenter = guildPresenter ?? new GuildPresenter(guildView, guildInfoView, guildMemberView,
                guildCreateView, services.Guild, services.Player,
                name => InvokeLuaOrFail(onGuildCreate, "Guild.Create", name),
                () => InvokeLuaOrFail(onGuildRequestMembers, "Guild.RequestMembers"),
                () => InvokeLuaOrFail(onGuildLeave, "Guild.Leave"));
        }

        private void EnsureWorldPresenter()
        {
            worldView = worldView ?? services.UiRouter.FindBySource("fuben/WorldMapNewLayer");
            worldMapView = worldMapView ?? services.UiRouter.FindBySource("fuben/DadituuiLayer");
            worldDetailView = worldDetailView ?? services.UiRouter.FindBySource("fuben/guanqiaxiangxiLayer");
            if (worldView == null || worldMapView == null || worldDetailView == null)
                throw new InvalidOperationException("World imported CocosUiBindings were not found.");
            worldPresenter = worldPresenter ?? new WorldPresenter(worldView, worldMapView, worldDetailView,
                services.World, services.Heroes, services.Formation, services.Resources,
                id => InvokeLuaOrFail(onWorldRequestChapter, "World.RequestChapter", (double)id),
                id => { services.World.SelectStage(id); InvokeLuaOrFail(onWorldRequestStage, "World.RequestStage", (double)id); },
                () => InvokeLuaOrFail(onWorldChallenge, "World.Challenge"),
                () => HandleBack());
        }

        private void EnsureWelfarePresenter()
        {
            welfareView = welfareView ?? services.UiRouter.FindBySource("WelfareLayer");
            welfareSignView = welfareSignView ?? services.UiRouter.FindBySource("SignLayer");
            welfareOnlineView = welfareOnlineView ?? services.UiRouter.FindBySource("huodong/LoginGiftLayer");
            if (welfareView == null || welfareSignView == null || welfareOnlineView == null)
                throw new InvalidOperationException("Welfare imported CocosUiBindings were not found.");
            welfarePresenter = welfarePresenter ?? new WelfarePresenter(welfareView, welfareSignView, welfareOnlineView,
                services.Welfare, services.ServerTime, services.Resources,
                () => InvokeLuaOrFail(onWelfareClaimSign, "Welfare.ClaimSign"), () => HandleBack());
        }

        private void BeginFriendUpdate(int maximum, int expectedCount)
        {
            pendingFriendMaximum = checked((byte)maximum);
            pendingFriendRecords.Clear();
            if (expectedCount > pendingFriendRecords.Capacity) pendingFriendRecords.Capacity = expectedCount;
        }

        private void EnsureMainTaskTracker()
        {
            if (mainTaskTracker != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
            CocosUiView backup = services.UiRouter.FindBySource("UImainLayer_backup");
            if (mainView == null || backup == null)
                throw new InvalidOperationException("Main or backup main task-tracker view was not found.");
            mainTaskTracker = new MainTaskTrackerPresenter(mainView, backup, services.Tasks, HandleTaskClick);
        }

        private void EnsureMainHudPresenter()
        {
            if (mainHudPresenter != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
            if (mainView == null) throw new InvalidOperationException("Main HUD view was not found.");
            mainHudPresenter = new MainHudPresenter(mainView, services.Player, services.Currencies);
        }

        private void EnsureErrorPresenter()
        {
            if (services == null || errorPresenter != null) return;
            errorView = errorView ?? services.UiRouter.FindBySource("MessageBoxLayer");
            if (errorView != null) errorPresenter = new GameErrorPresenter(errorView);
        }

        private void EnsureCommonPresenters()
        {
            if (services == null) return;
            loadingView = loadingView ?? services.UiRouter.FindBySource("common/jiemianjiazai");
            if (loadingView == null)
                throw new InvalidOperationException("common/jiemianjiazai CocosUiBinding was not found.");
            loadingPresenter = loadingPresenter ?? new LoadingPresenter(loadingView);
            if (toastPresenter == null)
            {
                Transform parent = loadingView.GameObject.transform.parent;
                if (parent == null) throw new InvalidOperationException("Common UI canvas was not found.");
                toastPresenter = new ToastPresenter(parent);
            }
        }

        private void HandleRequestTimeout(RequestContext context)
        {
            string detail = $"{context.Protocol.Name} 请求超时（{context.Protocol.TimeoutSeconds:F0}秒）";
            SetStatus(detail);
            EnsureErrorPresenter();
            errorPresenter?.Show("网络超时", detail);
        }

        private void CallLua(LuaFunction function, string context, params object[] arguments)
        {
            services?.Lua.Call(function, context, arguments);
        }

        private void InvokeLuaOrFail(LuaFunction function, string context, params object[] arguments)
        {
            try { CallLua(function, context, arguments); }
            catch (Exception exception) { Fail(exception.Message); }
        }
    }
}
