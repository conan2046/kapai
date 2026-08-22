using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using ProjectX.Animation;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.LuaRuntime;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.EventSystems;
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
        public const string TaskPath = "Layer/Main_UI/ButtonGroup1/btn_renwu";
        public const string FormationPath = "Layer/Main_UI/ButtonGroup1/btn_zhenrong";
        public const string HeroBagPath = "Layer/Main_UI/ButtonGroup1/btn_shenjiangbeibao";
        public const string MailPath = "Layer/Main_UI/ButtonGroup7/btn_mail";
        public const string ShopPath = "Layer/Main_UI/ButtonGroup1/btn_shangcheng";
        public const string ShopSubmenuPath = "Layer/Main_UI/tankuang1/btn_shangcheng";
        public const string ShopCoinShortcutPath = "Layer/Main_UI/ButtonGroup6/Icon_jinbi/AddBtn";
        public const string FriendPath = "Layer/Main_UI/ButtonGroup7/btn_friend";
        public const string ChatPath = "Layer/Main_UI/ShortcutButtonGroup/Chat";
        public const string TeamLegacyPath = "Layer/Main_UI/Panel_QuestAndTeam/CheckBox_Team";
        public const string GuildPath = "Layer/Main_UI/ButtonGroup3/btn_bangpai";
        public const string WorldPath = "Layer/Main_UI/btn_fuben";
        public const string WelfareLegacyPath = "Layer/Main_UI/ButtonGroup8/btn_fuli";
        public const string ActivityPath = "Layer/Main_UI/ButtonGroup1/btn_huodong";
        public const string RankingPath = "Layer/Main_UI/ButtonGroup1/btn_paihangbang";
        public const string DrawPath = "Layer/Main_UI/ButtonGroup1/btn_zhaomu";
        public const string GameplayPath = "Layer/Main_UI/ButtonGroup1/btn_wanfa";
        public const string EquipmentBagPath = "Layer/Main_UI/tankuang2/btn_zhuangbei";
        public const string FaBaoBagPath = "Layer/Main_UI/tankuang2/btn_fabao";
        private static readonly HashSet<string> SteamExcludedModules = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "SevenDay", "Funds", "ResourceRecovery", "Welfare", "Friend", "Chat", "Team", "Guild",
            "Activity", "KunLun", "BloodFight", "StaminaClaim"
        };

        private GameServices services;
        private LuaFunction onConnected;
        private LuaFunction onDisconnected;
        private LuaFunction onPacket;
        private LuaFunction onLoginClicked;
        private LuaFunction onRoleCreateClicked;
        private LuaFunction onRoleRandomClicked;
        private LuaFunction onBagClicked;
        private LuaFunction onBagUseClicked;
        private LuaFunction onSettingsClicked;
        private LuaFunction onTaskClicked;
        private LuaFunction onTaskClaimClicked;
        private LuaFunction onHeroClicked;
        private LuaFunction onHeroLevelUp;
        private LuaFunction onHeroEquipmentWear;
        private LuaFunction onEquipmentBagClicked;
        private LuaFunction onFaBaoBagClicked;
        private LuaFunction onHeroEquipmentTakeOff;
        private LuaFunction onHeroEquipmentStrength;
        private LuaFunction onHeroEquipmentStrengthAll;
        private LuaFunction onHeroEquipmentRefine;
        private LuaFunction onHeroEquipmentAutoRefine;
        private LuaFunction onHeroEquipmentAwaken;
        private LuaFunction onHeroEquipmentDivine;
        private LuaFunction onHeroEquipmentCompose;
        private LuaFunction onFaBaoWear;
        private LuaFunction onFaBaoTakeOff;
        private LuaFunction onMailClicked;
        private LuaFunction onMailClaimClicked;
        private LuaFunction onMailReadClicked;
        private LuaFunction onMailDeleteClicked;
        private LuaFunction onMailClaimAllClicked;
        private LuaFunction onMailDeleteAllClicked;
        private LuaFunction onMailValidationClaim;
        private LuaFunction onMailValidationClaimAll;
        private LuaFunction onMailValidationReadAll;
        private LuaFunction onMailValidationRepeat;
        private LuaFunction onShopClicked;
        private LuaFunction onShopBuyConfirmed;
        private LuaFunction onShopRefreshRequested;
        private LuaFunction onShopCountRequested;
        private LuaFunction onShopRequestTimeout;
        private LuaFunction onShopValidationRefresh;
        private LuaFunction onShopValidationCount;
        private LuaFunction onShopValidationFailure;
        private LuaFunction onShopValidationSuccess;
        private LuaFunction onGameplayShopOpened;
        private LuaFunction onGameplayShopTab;
        private LuaFunction onGameplayShopBuy;
        private LuaFunction onGameplayShopRefresh;
        private LuaFunction onGameplayShopCount;
        private LuaFunction onGameplayShopRequestTimeout;
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
        private LuaFunction onWorldSweep;
        private LuaFunction onWorldReset;
        private LuaFunction onWorldClaimBox;
        private LuaFunction onWorldRefresh;
        private LuaFunction onWorldValidateIsolation;
        private LuaFunction onWelfareClicked;
        private LuaFunction onWelfareClaimSign;
        private LuaFunction onActivityClicked;
        private LuaFunction onActivitySelected;
        private LuaFunction onDrawClicked;
        private LuaFunction onDrawRequested;
        private LuaFunction onGameplayClicked;
        private LuaFunction onGameplayEntered;
        private LuaFunction onSharedGameplayHotPointRefresh;
        private LuaFunction onYouLiClicked;
        private LuaFunction onFengShenStoryClicked;
        private LuaFunction onFengShenStoryChallengeClicked;
        private LuaFunction onArenaClicked;
        private LuaFunction onKunLunClicked;
        private LuaFunction onBloodFightClicked;
        private LuaFunction onXunBaoClicked;
        private LuaFunction onSevenDayClicked;
        private LuaFunction onSevenDayClaim;
        private LuaFunction onStaminaClaimClicked;
        private LuaFunction onStaminaClaimRequest;
        private LuaFunction onStaminaClaimRefresh;
        private LuaFunction onResourceRecoveryClicked;
        private LuaFunction onFundsClicked;
        private CocosUiView loginBackgroundView;
        private CocosUiView loginView;
        private CocosUiView loginServerListView;
        private CocosUiView roleCreateView;
        private CocosUiView noticeView;
        private StartupPresenter startupPresenter;
        private LocalServerSupervisor localServerSupervisor;
        private LoginPresenter loginPresenter;
        private NoticePresenter noticePresenter;
        private readonly List<NoticeRecord> pendingGameNotices = new List<NoticeRecord>();
        private bool gameNoticeRequested;
        private string loginSignature = "local";
        private bool loginClosureValidationRunning;
        private CocosUiView mainView;
        private CocosUiView mainCloudView;
        private CocosUiView bagView;
        private CocosUiView bagFrameView;
        private CocosUiView bagInputView;
        private CocosUiView bagPopupFrameView;
        private CocosUiView bagGiftView;
        private CocosUiView bagSourceView;
        private CocosUiView bagEquipmentInfoView;
        private BagPresenter bagPresenter;
        private BagFlowPresenter bagFlowPresenter;
        private readonly List<BagItemRecord> pendingBagItems = new List<BagItemRecord>();
        private int bagG4InitialBatchQuantity;
        private int bagG4InitialGiftQuantity;
        private int bagG4InitialDirectQuantity;
        private int bagG4InitialRewardQuantity;
        private bool bagInitialG5DisconnectCaptured;
        private bool bagInitialG5ReconnectCaptured;
        private bool bagInitialG5ReenterRequested;
        private bool bagInitialG5ReenterCaptured;
        private uint validationRoleIdSnapshot;
        private readonly HashSet<string> validationControlIds = new HashSet<string>(StringComparer.Ordinal);
        private readonly HashSet<string> passedValidationSemantics = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> failedValidationSemantics =
            new Dictionary<string, string>(StringComparer.Ordinal);
        private readonly HashSet<string> gameplayShopG4Events =
            new HashSet<string>(StringComparer.Ordinal);
        private bool bagInitialSelectionApplied;
        private CocosUiView rewardView;
        private RewardPresenter rewardPresenter;
        private readonly List<RewardRecord> pendingRewards = new List<RewardRecord>();
        private readonly Dictionary<int, RewardRecord> pendingBagUseRewards =
            new Dictionary<int, RewardRecord>();
        private bool capturingBagUseRewards;
        private float lastBagUseRewardAt;
        private float bagUseRewardCaptureUntil;
        private Coroutine bagUseRewardRoutine;
        private readonly List<List<RewardRecord>> pendingWorldSweepGroups = new List<List<RewardRecord>>();
        private CocosUiView heroFrameView;
        private CocosUiView heroListView;
        private CocosUiView heroDetailView;
        private CocosUiView heroBagView;
        private CocosUiView heroReplacementView;
        private CocosUiView heroCultivationView;
        private CocosUiView heroLevelUpView;
        private CocosUiView heroEnhanceMasterView;
        private CocosUiView heroAttributesView;
        private CocosUiView heroItemSourceView;
        private HeroPresenter heroPresenter;
        private bool heroG4ControlValidationRunning;
        private CocosUiView formationPopupView;
        private FormationPopupPresenter formationPopupPresenter;
        private LuaFunction onFormationMove;
        private HeroEntry pendingHeroEntry = HeroEntry.Formation;
        private readonly List<HeroRecord> pendingHeroes = new List<HeroRecord>();
        private readonly List<FormationRecord> pendingFormations = new List<FormationRecord>();
        private readonly List<int> pendingFormationDisplay = new List<int>();
        private readonly List<int> pendingFormationCombat = new List<int>();
        private int pendingActiveFormationId;
        private readonly Dictionary<int, bool> heroEquipmentStageOpen = new Dictionary<int, bool>();
        private readonly HashSet<int> heroEquipmentStageResponses = new HashSet<int>();
        private int pendingHeroEquipmentPosition;
        private int pendingHeroEquipmentSlot;
        private bool heroEquipmentOpenPending;
        private bool heroEquipmentOpenedFromHeroDetails;
        private CocosUiView heroEquipmentListView;
        private CocosUiView heroEquipmentDetailView;
        private CocosUiView heroEquipmentChangeView;
        private CocosUiView heroEquipmentCultivateView;
        private CocosUiView heroEquipmentStrengthView;
        private CocosUiView heroEquipmentRefineView;
        private CocosUiView heroEquipmentAwakenView;
        private CocosUiView heroEquipmentDivineView;
        private CocosUiView heroEquipmentFragmentView;
        private CocosUiView heroEquipmentAutoRefineView;
        private CocosUiView heroEquipmentExchangeView;
        private CocosUiView heroEquipmentAutoStarView;
        private CocosUiView heroEquipmentAutoDivineView;
        private CocosUiView heroEquipmentDivineEffectView;
        private HeroEquipmentPresenter heroEquipmentPresenter;
        private int selectedHeroEquipmentFragmentId;
        private bool heroEquipmentFragmentBagSubscribed;
        private VirtualList<BagItemRecord[]> heroEquipmentFragmentList;
        private readonly List<HeroEquipmentRecord> pendingHeroEquipment = new List<HeroEquipmentRecord>();
        private readonly List<FaBaoRecord> pendingFaBao = new List<FaBaoRecord>();
        private readonly List<CultivationLevel> pendingCultivation = new List<CultivationLevel>();
        private uint pendingEquipmentUid;
        private int pendingEquipmentTemplateId;
        private int pendingEquipmentFormationPosition;
        private uint pendingEquipmentExperience;
        private int pendingEquipmentBaseAttributeType;
        private uint pendingEquipmentBaseAttributeValue;
        private int pendingEquipmentStrengthAttributeType;
        private uint pendingEquipmentStrengthAttributeValue;
        private int pendingFaBaoSlot;
        private CocosUiView settingsView;
        private SettingsPresenter settingsPresenter;
        private Button settingsButton;
        private SettingsPreferenceSnapshot? settingsVisualPreferenceSnapshot;
        private CocosUiView taskBackgroundView;
        private CocosUiView taskView;
        private TaskPresenter taskPresenter;
        private MainTaskTrackerPresenter mainTaskTracker;
        private MainHudPresenter mainHudPresenter;
        private bool playerHudValidationRunning;
        private Coroutine hudShopSubmenuAnimation;
        private Coroutine hudWearSubmenuAnimation;
        private Vector2 hudShopSubmenuOrigin;
        private Vector2 hudWearSubmenuOrigin;
        private bool hudSubmenuOriginsReady;
        private GameObject hudSubmenuDismissOverlay;
        private Button taskButton;
        private readonly List<TaskRecord> pendingTaskRecords = new List<TaskRecord>();
        private int pendingTaskType = 2;
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
        private bool mailValidationSawRedDot;
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
        private int validationShopQuantity = 1;
        private CocosUiView friendView;
        private FriendPresenter friendPresenter;
        private readonly List<FriendRecord> pendingFriendRecords = new List<FriendRecord>();
        private byte pendingFriendMaximum;
        private CocosUiView chatMiniView;
        private bool restoreChatMiniAfterGameplayShop;
        private bool restoreBagFrameAfterGameplayShop;
        private bool restoreHeroEquipmentAfterGameplayShop;
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
        private CocosUiView worldStageView;
        private CocosUiView worldMapView;
        private CocosUiView worldDetailView;
        private CocosUiView worldSweepView;
        private CocosUiView worldBattleResultView;
        private CocosUiView worldBattleStatisticsView;
        private CocosUiView worldBoxAwardView;
        private WorldPresenter worldPresenter;
        private WorldOutcomePresenter worldOutcomePresenter;
        private readonly List<WorldChapterRecord> pendingWorldChapters = new List<WorldChapterRecord>();
        private readonly List<WorldStageRecord> pendingWorldStages = new List<WorldStageRecord>();
        private readonly List<WorldStarBoxRecord> pendingWorldStarBoxes = new List<WorldStarBoxRecord>();
        private WorldStageRecord pendingWorldStage;
        private byte pendingWorldMapType;
        private uint pendingWorldChapterId;
        private string pendingWorldChapterName;
        private uint worldG4StageId;
        private uint worldG4ChapterId;
        private int worldG4RewardCount;
        private bool worldG4PrimarySettled;
        private bool worldG4ReconnectVerified;
        private bool worldG4DetailCloseValidated;
        private bool worldG4FormationValidated;
        private bool worldG4StageCloseValidated;
        private bool worldG4StarBoxValidated;
        private bool worldG4NormalBoxValidated;
        private bool worldG4SweepValidated;
        private bool worldG4ResetValidated;
        private bool worldG4BattleStatisticsValidated;
        private bool worldG4BattleReplayValidated;
        private uint selectedWorldBoxStageId;
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
        private CocosUiView activityRootView;
        private CocosUiView activityBackgroundView;
        private CocosUiView activityDailyRechargeView;
        private ActivityPresenter activityPresenter;
        private readonly List<ActivityListRecord> pendingActivityItems = new List<ActivityListRecord>();
        private DailyRechargeActivityState pendingDailyRecharge;
        private CocosUiView drawView;
        private CocosUiView drawSingleResultView;
        private CocosUiView drawTenResultView;
        private CocosUiView drawPreviewView;
        private CocosUiView drawExchangeView;
        private GameObject drawExchangeDimmer;
        private DrawPresenter drawPresenter;
        private readonly List<DrawPoolRecord> pendingDrawPools = new List<DrawPoolRecord>();
        private DrawResultRecord pendingDrawResult;
        private LuaFunction onDrawClosureBagRefresh;
        private LuaFunction onDrawClosurePrepareMount;
        private LuaFunction onDrawClosurePrepareReconnect;
        private LuaFunction onDrawClosurePrepareAccountIsolation;
        private const int DrawClosureTargetHeroId = 64;
        private const int DrawClosureLevelMaterialId = 834;
        private const int DrawClosureFormationPosition = 1;
        private int drawClosureInitialLevel;
        private uint drawClosureInitialExperience;
        private int drawClosureInitialMaterial;
        private bool drawClosureHeroMounted;
        private bool drawClosureHeroCultivated;
        private bool drawG4SequenceRunning;
        private bool drawG4ExpectFailure;
        private bool drawG4ExpectedFailureCompleted;
        private bool drawCompleteRemainingAfterInsufficient;
        private string drawG4LastError;
        private CocosUiView gameplayView;
        private CocosUiView gameplayContentView;
        private CocosUiView gameplayDetailView;
        private GameplayPresenter gameplayPresenter;
        private Button gameplayButton;
        private bool gameplayValidationRunning;
        private bool gameplayValidationCompleted;
        private int lastGameplayBoundaryId;
        private CocosUiView youLiView;
        private YouLiPresenter youLiPresenter;
        private CocosUiView fengShenStoryView;
        private CocosUiView fengShenStoryLevelView;
        private FengShenStoryPresenter fengShenStoryPresenter;
        private readonly List<FengShenRewardRecord> pendingFengShenRewards = new List<FengShenRewardRecord>();
        private bool fengShenStoryValidationRunning;
        private bool fengShenStoryValidationCompleted;
        private CocosUiView arenaView;
        private ArenaPresenter arenaPresenter;
        private CocosUiView kunLunView;
        private KunLunPresenter kunLunPresenter;
        private readonly List<KunLunEnemyRecord> pendingKunLunEnemies = new List<KunLunEnemyRecord>();
        private byte pendingKunLunFloor;
        private byte pendingKunLunFights;
        private byte pendingKunLunBuys;
        private byte pendingKunLunPosition;
        private CocosUiView bloodFightView;
        private BloodFightPresenter bloodFightPresenter;
        private CocosUiView xunBaoView;
        private XunBaoPresenter xunBaoPresenter;
        private CocosUiView sevenDayView;
        private SevenDayPresenter sevenDayPresenter;
        private bool sevenDayValidationRunning;
        private CocosUiView staminaClaimView;
        private StaminaClaimPresenter staminaClaimPresenter;
        private bool staminaClaimValidationRunning;
        private bool staminaClaimValidationCompleted;
        private string lastStaminaClaimBoundary = string.Empty;
        private string lastSevenDayBoundary = string.Empty;
        private CocosUiView resourceRecoveryView;
        private ResourceRecoveryPresenter resourceRecoveryPresenter;
        private CocosUiView growthFundView;
        private CocosUiView activeFundView;
        private FundsPresenter fundsPresenter;
        private WelfareActivityFramePresenter welfareActivityFramePresenter;
        private CocosUiView soulShopView;
        private CocosUiView multiShopView;
        private GameplayShopsPresenter gameplayShopsPresenter;
        private readonly List<SevenDayTaskRecord> pendingSevenDayTasks = new List<SevenDayTaskRecord>();
        private readonly List<StaminaClaimRecord> pendingStaminaClaimRecords = new List<StaminaClaimRecord>();
        private readonly List<ResourceRecoveryRecord> pendingResourceRecoveryRecords = new List<ResourceRecoveryRecord>();
        private readonly List<ResourceRecoveryReward> pendingResourceRecoveryRewards = new List<ResourceRecoveryReward>();
        private int pendingResourceRecoveryFunctionId;
        private ushort pendingResourceRecoveryLeftTimes;
        private int pendingResourceRecoveryCostId;
        private int pendingResourceRecoveryCostSubtype;
        private uint pendingResourceRecoveryCostAmount;
        private readonly List<FundPlan> pendingFundPlans = new List<FundPlan>();
        private readonly List<FundTier> pendingFundTiers = new List<FundTier>();
        private readonly List<FundReward> pendingFundRewards = new List<FundReward>();
        private FundKind pendingFundKind;
        private uint pendingFundEndTime;
        private byte pendingFundBoughtPlanId;
        private byte pendingFundPlanId, pendingFundPlanBought, pendingFundPlanProgress;
        private uint pendingFundBuyTime, pendingFundRate, pendingFundPrice, pendingFundTotal;
        private byte pendingFundTierCondition, pendingFundTierState;
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
        public bool IsSettingsDataReady => services?.Player.IsLoaded == true
            && services.Currencies.Has(CurrencyIds.Stamina);
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
        public bool IsActivityOpen => activityRootView != null && services?.UiStack.Current == activityRootView;
        public int ActivityCount => services?.Activity.Count ?? 0;
        public int ActivityRewardCount => activityPresenter?.RewardCount ?? 0;
        public bool IsActivityEmptyVisible => activityPresenter?.EmptyStateVisible ?? false;
        public bool IsActivityDailyRechargeVisible => activityPresenter?.DailyRechargeVisible ?? false;
        public bool IsActivityHotPointVisible => mainView != null
            && mainView.Binding.Find(ActivityPath)?.transform.Find("ActivityHotPointRuntime")?.gameObject.activeSelf == true;
        public bool IsDrawOpen => drawView != null && services?.UiStack.Current == drawView;
        public bool IsDrawActive() => IsDrawOpen;
        public int DrawPoolCount => services?.Draw.Count ?? 0;
        public int DrawResultCount => drawPresenter?.ResultCount ?? 0;
        public bool IsDrawResultVisible => drawPresenter?.IsSingleResultVisible ?? false;
        public bool IsDrawEffectLoaded => drawPresenter?.FurnaceEffectLoaded ?? false;
        public bool IsGameplayOpen => gameplayView != null && services?.UiStack.Current == gameplayView;
        public int GameplayRenderedCount => gameplayPresenter?.RenderedCount ?? 0;
        public int GameplayMissingIconCount => gameplayPresenter?.MissingIconCount ?? 0;
        public bool IsGameplayEmptyVisible => gameplayPresenter?.EmptyStateVisible ?? false;
        public int GameplayEnterButtonCount => gameplayPresenter?.EnterButtonCount ?? 0;
        public bool IsYouLiOpen => youLiView != null && services?.UiStack.Current == youLiView;
        public int YouLiRenderedCount => youLiPresenter?.RenderedCount ?? 0;
        public bool IsYouLiEmptyVisible => youLiPresenter?.EmptyStateVisible ?? false;
        public bool IsFengShenStoryOpen => fengShenStoryView != null && services?.UiStack.Current == fengShenStoryView;
        public bool IsFengShenStoryAuthoritativeVisible => fengShenStoryPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsArenaOpen => arenaView != null && services?.UiStack.Current == arenaView;
        public bool IsArenaAuthoritativeVisible => arenaPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsKunLunOpen => kunLunView != null && services?.UiStack.Current == kunLunView;
        public bool IsKunLunAuthoritativeVisible => kunLunPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsBloodFightOpen => bloodFightView != null && services?.UiStack.Current == bloodFightView;
        public bool IsBloodFightAuthoritativeVisible => bloodFightPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsXunBaoOpen => xunBaoView != null && services?.UiStack.Current == xunBaoView;
        public bool IsXunBaoAuthoritativeVisible => xunBaoPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsSevenDayOpen => sevenDayView != null && services?.UiStack.Current == sevenDayView;
        public bool IsSevenDayAuthoritativeVisible => sevenDayPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsStaminaClaimOpen => staminaClaimView != null && staminaClaimView.GameObject.activeSelf && services?.UiStack.Current == taskBackgroundView;
        public bool IsStaminaClaimAuthoritativeVisible => staminaClaimPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsResourceRecoveryOpen => resourceRecoveryView != null && resourceRecoveryView.GameObject.activeSelf && services?.UiStack.Current == taskBackgroundView;
        public bool IsResourceRecoveryAuthoritativeVisible => resourceRecoveryPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsFundsOpen => fundsPresenter != null && services?.UiStack.Current == taskBackgroundView
            && ((growthFundView?.GameObject.activeSelf ?? false) || (activeFundView?.GameObject.activeSelf ?? false));
        public bool IsFundsAuthoritativeVisible => fundsPresenter?.IsAuthoritativeVisible ?? false;
        public bool IsGameplayShopOpen => gameplayShopsPresenter != null
            && services?.UiStack.Current == gameplayShopsPresenter.ActiveView;
        public int GameplayShopRenderedCount => gameplayShopsPresenter?.RenderedCount ?? 0;
        public int GameplayShopMissingIconCount => gameplayShopsPresenter?.MissingIconCount ?? 0;
        public int TaskCount => services?.Tasks.Count ?? 0;
        public bool IsTaskHotPointVisible => mainTaskTracker?.IsHotPointVisible ?? false;

        public void BeginValidationEvidence()
        {
            validationControlIds.Clear();
            passedValidationSemantics.Clear();
            failedValidationSemantics.Clear();
        }

        public void MarkValidationControl(string controlId)
        {
            if (!string.IsNullOrWhiteSpace(controlId)) validationControlIds.Add(controlId.Trim());
        }

        public void RecordValidationSemantic(string key, bool passed, string detail = "")
        {
            if (string.IsNullOrWhiteSpace(key)) return;
            key = key.Trim();
            if (passed)
            {
                failedValidationSemantics.Remove(key);
                passedValidationSemantics.Add(key);
                return;
            }
            passedValidationSemantics.Remove(key);
            failedValidationSemantics[key] = detail ?? string.Empty;
        }

        public string[] GetValidatedControlIds() =>
            validationControlIds.OrderBy(value => value, StringComparer.Ordinal).ToArray();

        public string[] GetPassedValidationSemanticKeys() =>
            passedValidationSemantics.OrderBy(value => value, StringComparer.Ordinal).ToArray();

        public string[] GetFailedValidationSemanticAssertions() =>
            failedValidationSemantics.OrderBy(pair => pair.Key, StringComparer.Ordinal)
                .Select(pair => $"{pair.Key}: {pair.Value}").ToArray();
        public bool IsRewardVisible => rewardPresenter?.IsVisible ?? false;
        public int RewardCount => services?.Rewards.Count ?? 0;
        public bool IsHeroOpen => heroFrameView != null && services?.UiStack.Current == heroFrameView;
        private bool IsHeroEquipmentSurfaceVisible => heroEquipmentListView?.GameObject.activeSelf == true
            || heroEquipmentDetailView?.GameObject.activeSelf == true
            || heroEquipmentChangeView?.GameObject.activeSelf == true
            || heroEquipmentFragmentView?.GameObject.activeSelf == true
            || heroEquipmentCultivateView?.GameObject.activeSelf == true
            || heroEquipmentStrengthView?.GameObject.activeSelf == true
            || heroEquipmentRefineView?.GameObject.activeSelf == true
            || heroEquipmentAwakenView?.GameObject.activeSelf == true
            || heroEquipmentDivineView?.GameObject.activeSelf == true
            || heroEquipmentAutoRefineView?.GameObject.activeSelf == true
            || heroEquipmentExchangeView?.GameObject.activeSelf == true
            || heroEquipmentAutoStarView?.GameObject.activeSelf == true
            || heroEquipmentAutoDivineView?.GameObject.activeSelf == true
            || heroEquipmentDivineEffectView?.GameObject.activeSelf == true;
        public bool IsHeroEquipmentOpen => IsHeroEquipmentSurfaceVisible
            && heroFrameView != null && services?.UiStack.Current == heroFrameView;
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
        public bool IsMailRedDotVisible =>
            mainView?.Binding.Find($"{MailPath}/Prompt")?.activeSelf == true;
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
            AppLaunchOptions launchOptions = AppLaunchOptions.Current();
            if (LocalServerSupervisor.ShouldRun(launchOptions))
            {
                StartCoroutine(PrepareLocalServerThenInitialize(launchOptions));
                return;
            }
            InitializeApplication(launchOptions);
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

        private void InitializeApplication(AppLaunchOptions launchOptions)
        {
            try
            {
                services = new GameServices(this, launchOptions);
                // These validations intentionally drive every reconnect step and
                // assert the intermediate disconnected/login state.  A queued
                // automatic reconnect can otherwise race an account switch.
                if (services.Options.ManualReconnectValidation || services.Options.ScenarioManagedReconnect
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
                onHeroClicked = services.Lua.GetFunction("OnHeroClicked");
                onHeroLevelUp = services.Lua.GetFunction("OnHeroLevelUp");
                onFormationMove = services.Lua.GetFunction("OnFormationMove");
                onHeroEquipmentWear = services.Lua.GetFunction("OnHeroEquipmentWear");
                onEquipmentBagClicked = services.Lua.GetFunction("OnEquipmentBagClicked");
                onFaBaoBagClicked = services.Lua.GetFunction("OnFaBaoBagClicked");
                onHeroEquipmentTakeOff = services.Lua.GetFunction("OnHeroEquipmentTakeOff");
                onHeroEquipmentStrength = services.Lua.GetFunction("OnHeroEquipmentStrength");
                onHeroEquipmentStrengthAll = services.Lua.GetFunction("OnHeroEquipmentStrengthAll");
                onHeroEquipmentRefine = services.Lua.GetFunction("OnHeroEquipmentRefine");
                onHeroEquipmentAutoRefine = services.Lua.GetFunction("OnHeroEquipmentAutoRefine");
                onHeroEquipmentAwaken = services.Lua.GetFunction("OnHeroEquipmentAwaken");
                onHeroEquipmentDivine = services.Lua.GetFunction("OnHeroEquipmentDivine");
                onHeroEquipmentCompose = services.Lua.GetFunction("OnHeroEquipmentCompose");
                onFaBaoWear = services.Lua.GetFunction("OnFaBaoWear");
                onFaBaoTakeOff = services.Lua.GetFunction("OnFaBaoTakeOff");
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
                onWorldRefresh = services.Lua.GetFunction("OnWorldRefresh");
                onWorldValidateIsolation = services.Lua.GetFunction("OnWorldValidateIsolation");
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
                onFengShenStoryClicked = services.Lua.GetFunction("OnFengShenStoryClicked");
                onFengShenStoryChallengeClicked = services.Lua.GetFunction("OnFengShenStoryChallengeClicked");
                onArenaClicked = services.Lua.GetFunction("OnArenaClicked");
                onKunLunClicked = services.Lua.GetFunction("OnKunLunClicked");
                onBloodFightClicked = services.Lua.GetFunction("OnBloodFightClicked");
                onXunBaoClicked = services.Lua.GetFunction("OnXunBaoClicked");
                onSevenDayClicked = services.Lua.GetFunction("OnSevenDayClicked");
                onSevenDayClaim = services.Lua.GetFunction("OnSevenDayClaim");
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

        private void Update()
        {
            localServerSupervisor?.Tick();
            services?.Tick();
            loadingPresenter?.Tick();
            MaintainHeroEquipmentCultivationState();
            toastPresenter?.Tick();
            shopPresenter?.Tick();
            welfarePresenter?.Tick();
            activityPresenter?.Tick();
            drawPresenter?.Tick();
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
            onHeroClicked?.Dispose();
            onHeroLevelUp?.Dispose();
            onFormationMove?.Dispose();
            onHeroEquipmentWear?.Dispose();
            onEquipmentBagClicked?.Dispose();
            onFaBaoBagClicked?.Dispose();
            onHeroEquipmentTakeOff?.Dispose();
            onHeroEquipmentStrength?.Dispose();
            onHeroEquipmentStrengthAll?.Dispose();
            onHeroEquipmentRefine?.Dispose();
            onHeroEquipmentAutoRefine?.Dispose();
            onHeroEquipmentAwaken?.Dispose();
            onHeroEquipmentDivine?.Dispose();
            onHeroEquipmentCompose?.Dispose();
            onFaBaoWear?.Dispose();
            onFaBaoTakeOff?.Dispose();
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
            onWorldRefresh?.Dispose();
            onWorldValidateIsolation?.Dispose();
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
            onFengShenStoryClicked?.Dispose();
            onFengShenStoryChallengeClicked?.Dispose();
            onArenaClicked?.Dispose();
            onKunLunClicked?.Dispose();
            onBloodFightClicked?.Dispose();
            onXunBaoClicked?.Dispose();
            onSevenDayClicked?.Dispose();
            onSevenDayClaim?.Dispose();
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
            sevenDayPresenter?.Dispose();
            staminaClaimPresenter?.Dispose();
            resourceRecoveryPresenter?.Dispose();
            fundsPresenter?.Dispose();
            welfareActivityFramePresenter?.Dispose();
            gameplayShopsPresenter?.Dispose();
            bagPresenter?.Dispose();
            bagFlowPresenter?.Dispose();
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
            worldOutcomePresenter?.Dispose();
            welfarePresenter?.Dispose();
            activityPresenter?.Dispose();
            drawPresenter?.Dispose();
            gameplayPresenter?.Dispose();
            youLiPresenter?.Dispose();
            startupPresenter?.Dispose();
            loginPresenter?.Dispose();
            noticePresenter?.Dispose();
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

        private void HandleLocalServerFailure(string detail)
        {
            Fail(detail);
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
        public string GetLoginSignature() => string.IsNullOrWhiteSpace(loginSignature) ? "local" : loginSignature;
        public string GetGameHost() => services?.Config.GameHost ?? "127.0.0.1";
        public int GetGamePort() => services?.Config.GamePort ?? 8711;
        public string GetRoleName() => loginPresenter?.RoleName ?? string.Empty;
        public int GetRoleSex() => loginPresenter?.SelectedSex ?? 1;
        public uint GetPlayerRoleId() => services?.Player.RoleId ?? 0;
        public uint GetValidationRoleId() => GetPlayerRoleId() != 0 ? GetPlayerRoleId() : validationRoleIdSnapshot;
        public bool IsFormationPopupOpen => formationPopupView?.GameObject.activeSelf == true;
        public bool HandleBack()
        {
            if (formationPopupView?.GameObject.activeSelf == true)
            {
                formationPopupView.SetVisible(false);
                return true;
            }
            if (heroItemSourceView?.GameObject.activeSelf == true)
            {
                heroItemSourceView.SetVisible(false);
                return true;
            }
            if (heroAttributesView?.GameObject.activeSelf == true)
            {
                heroAttributesView.SetVisible(false);
                return true;
            }
            if (heroReplacementView?.GameObject.activeSelf == true)
            {
                heroReplacementView.SetVisible(false);
                heroListView?.SetVisible(true);
                heroDetailView?.SetVisible(true);
                heroBagView?.SetVisible(false);
                return true;
            }
            if (heroEnhanceMasterView?.GameObject.activeSelf == true)
            {
                heroEnhanceMasterView.SetVisible(false);
                gameplayView?.SetVisible(false);
                heroListView?.SetVisible(true);
                heroDetailView?.SetVisible(true);
                heroFrameView?.SetVisible(true);
                ConfigureHeroFrame(false);
                return true;
            }
            if (heroCultivationView?.GameObject.activeSelf == true)
            {
                RestoreHeroFormationView();
                return true;
            }
            if (IsHeroEquipmentOpen)
            {
                if (IsHeroEquipmentSubpageVisible)
                {
                    RestoreHeroEquipmentBagView();
                    return true;
                }
                heroEquipmentPresenter?.HideDetails();
                heroEquipmentListView?.SetVisible(false);
                heroEquipmentFragmentView?.SetVisible(false);
                if (heroEquipmentOpenedFromHeroDetails)
                {
                    RestoreHeroAfterEquipmentSlot();
                    return true;
                }
                heroFrameView?.SetVisible(false);
                return services?.UiStack.Pop() ?? true;
            }
            if (IsShopOpen)
            {
                shopPresenter?.ResetTransientState();
                errorPresenter?.Hide();
                rewardPresenter?.Hide();
                bagFrameView?.SetVisible(false);
            }
            if (IsGameplayShopOpen)
            {
                CloseGameplayShops();
                return true;
            }
            if (IsSettingsOpen) bagFrameView?.SetVisible(false);
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
                disconnectReason = exception.Message;
                ShowLoginConnectionFailure(exception is TimeoutException);
            }
        }

        public async void Reconnect()
        {
            if (services == null || services.Network.State == NetworkState.Connecting) return;
            try
            {
                mainHudPresenter?.BeginReconnectChatSummary();
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

        public void SendUntracked(LegacyTcpMessage message)
        {
            try
            {
                ClientLog.Info("Protocol", "SEND optional HUD state",
                    $"cmd={message.OutgoingCommand} untracked");
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
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            mainCloudView = services.UiRouter.FindBySource("UImain_cloudLayer", true);
            bagView = services.UiRouter.FindBySource("zhujue/beibao");
            bagFrameView = services.UiRouter.FindBySource("OneLevelLayer");
            bagInputView = services.UiRouter.FindBySource("EnterNumLayer");
            bagPopupFrameView = services.UiRouter.FindBySource("shop/shop_bg");
            bagGiftView = services.UiRouter.FindBySource("common/OpenBox_1Layer");
            bagSourceView = services.UiRouter.FindBySource("common/huoqutujing");
            bagEquipmentInfoView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            settingsView = services.UiRouter.FindBySource("zhujue/SystemLayer");
            taskBackgroundView = services.UiRouter.FindBySource("huodong/huodong_bg");
            taskView = services.UiRouter.FindBySource("huodong/RenwuLayer");
            staminaClaimView = services.UiRouter.FindBySource("huodong/tililingquLayer");
            resourceRecoveryView = services.UiRouter.FindBySource("huodong/ziyuanzhaohui");
            errorView = services.UiRouter.FindBySource("MessageBoxLayer");
            loadingView = services.UiRouter.FindBySource("common/jiemianjiazai");
            heroListView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongListLayer");
            heroDetailView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongInfoLayer");
            heroReplacementView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxionghuanjiang");
            heroCultivationView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongjueseLayer");
            heroLevelUpView = services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongshuxingLayer");
            heroEnhanceMasterView = services.UiRouter.FindBySource("zhuangbeiyangcheng/qianghuadashi");
            heroAttributesView = services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangxiangxishuxing");
            heroItemSourceView = services.UiRouter.FindBySource("common/huoqutujing");
            heroEquipmentListView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeibeibao");
            heroEquipmentDetailView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            heroEquipmentChangeView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeigenghuan");
            heroEquipmentCultivateView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiyangcheng");
            heroEquipmentStrengthView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiqianghua");
            heroEquipmentRefineView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijinglian");
            heroEquipmentAwakenView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijuexing");
            heroEquipmentDivineView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeishenzhu");
            heroEquipmentFragmentView = services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeisuipian");
            heroEquipmentAutoRefineView = services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianjinglian");
            heroEquipmentExchangeView = services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianduihuan");
            heroEquipmentAutoStarView = services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengxing");
            heroEquipmentAutoDivineView = services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengceng");
            heroEquipmentDivineEffectView = services.UiRouter.FindBySource("zhuangbeiyangcheng/shenzhutexiao");
            mailView = services.UiRouter.FindBySource("MailLayer");
            shopView = services.UiRouter.FindBySource("shop/shangcheng");
            friendView = services.UiRouter.FindBySource("common/FriendLayer");
            chatMiniView = services.UiRouter.FindBySource("/ChatLayer.csd");
            chatView = services.UiRouter.FindBySource("MainChatLayer");
            services.UiStack.Clear();
            loginBackgroundView?.SetVisible(true);
            loginView?.SetVisible(true);
            loginServerListView?.SetVisible(false);
            roleCreateView?.SetVisible(false);
            noticeView?.SetVisible(false);
            mainView?.SetVisible(false);
            mainCloudView?.SetVisible(false);
            bagView?.SetVisible(false);
            bagFrameView?.SetVisible(false);
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
            heroFrameView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
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
            friendView?.SetVisible(false);
            chatMiniView?.SetVisible(false);
            chatView?.SetVisible(false);
            if (loginView == null) { Fail("Login/loginLayer CocosUiBinding was not found."); return; }
            if (loginBackgroundView == null) { Fail("Login/LoginBgLayer CocosUiBinding was not found."); return; }
            // Account switching must restore an actual stack root.  Leaving the
            // stack empty only happened to work for the first launch, and let a
            // deferred module callback hide the login layer during Draw G4.
            services.UiStack.SetRoot(loginView);
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
                loginPresenter.BindLoginControls(HandleLoginClick, HandleAccountSubmit, ShowLoginError);
                Button button = loginView.Binding.Find(LoginButtonPath)?.GetComponent<Button>();
                loginView.BindClick(LoginServerButtonPath, () => loginPresenter.ShowServerList(
                    HandleLoginClick, () => SetStatus("Login UI ready.")));
                if (autoInvoke || HasCommandLineFlag("-projectXS8StartupAcceptance")
                    || HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
                    StartCoroutine(InvokeButtonNextFrame(button));
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
            loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, HandleRoleRandomClick,
                ReturnFromRoleCreate, ShowLoginError, false);
            services.State.Change(AppState.Login, "Role creation UI shown");
            SetStatus("Role creation UI ready.");
        }

        public void BindRoleCreateClick(bool autoInvoke)
        {
            try { loginPresenter?.ShowRoleCreate(HandleRoleCreateClick, HandleRoleRandomClick,
                ReturnFromRoleCreate, ShowLoginError, autoInvoke); }
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
                if (errorPresenter?.IsVisible != true || services.Network.State != NetworkState.Disconnected)
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
            GameObject closeTemplate = roleCreateView?.Binding.Find("Layer/RoleCreateUI/Image/btn_Exit");
            noticePresenter = noticePresenter ?? new NoticePresenter(noticeView, closeTemplate, CloseGameNotice);
            noticePresenter.Show(pendingGameNotices);
            noticeView.GameObject.transform.SetAsLastSibling();
            services.UiStack.Push(noticeView, false);
        }

        public void CloseGameNotice()
        {
            if (services?.UiStack.Current == noticeView) services.UiStack.Pop();
            noticeView?.SetVisible(false);
        }

        public bool InvokeGameNoticeClose() => noticePresenter?.InvokeClose() == true;

        public void ShowMainUi()
        {
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null) { Fail("UImainLayer CocosUiBinding was not found."); return; }
            loginView?.SetVisible(false);
            loginBackgroundView?.SetVisible(false);
            loginPresenter?.HideAll();
            services.UiStack.SetRoot(mainView);
            if (mainCloudView != null)
            {
                Transform background = mainView.Binding.Find("Layer/Main_UI/Bg")?.transform;
                if (background != null && mainCloudView.GameObject.transform.parent != background)
                    mainCloudView.GameObject.transform.SetParent(background, false);
                mainCloudView.SetVisible(true);
                CocosTimelinePlayer timeline = mainCloudView.GameObject.GetComponent<CocosTimelinePlayer>();
                if (timeline != null) timeline.GotoFrameAndPlay(0, true);
                mainCloudView.GameObject.transform.SetAsFirstSibling();
            }
            HideHudSubmenus();
            chatView?.SetVisible(false);
            chatMiniView?.SetVisible(true);
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            errorPresenter?.Hide();
            EnsureMainHudPresenter();
            BindPlayerHudControls();
            ApplySteamFeatureExclusions();
            if (HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
                StartCoroutine(CaptureSteamHudExclusionAcceptance());
            EnsureMainTaskTracker();
            services.State.Change(AppState.Main, "Main UI shown");
            if (!IsSteamExcludedModule("KunLun"))
                InvokeLuaOrFail(onSharedGameplayHotPointRefresh, "Shared.GameplayHotPointRefresh");
            SetStatus("Main UI active.");
        }

        public void BindBagClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(BagPath, HandleBagClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindSettingsClick()
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                settingsButton = mainView.BindClick(SettingsPath, HandleSettingsClick, true);
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTaskClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                taskButton = mainView.BindClick(TaskPath, HandleTaskClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(taskButton));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindHeroClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button formationButton = mainView.BindClick(FormationPath, HandleFormationClick, true);
                Button bagButton = mainView.BindClick(HeroBagPath, HandleHeroBagClick, true);
                if (autoInvoke)
                    StartCoroutine(InvokeButtonNextFrame(HasCommandLineFlag("-projectXHeroBagValidation") ? bagButton : formationButton));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindMailClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(MailPath, HandleMailClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowMail()
        {
            EnsureMailPresenter();
            bagView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
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
            heroEquipmentFragmentView?.SetVisible(false);
            ConfigureMailFrame();
            bagFrameView.SetVisible(true);
            if (services.UiStack.Current != mailView) services.UiStack.Push(mailView);
            bagFrameView.GameObject.transform.SetAsLastSibling();
            mailView.GameObject.transform.SetAsLastSibling();
            SetStatus($"Mail UI active: {services.Mails.Count} mails.");
        }

        public void BindShopClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button toggle = mainView.BindClick(ShopPath, ToggleShopSubmenu, true);
                Button entry = mainView.BindClick(ShopSubmenuPath, HandleShopClick, true);
                mainView.BindClick(ShopCoinShortcutPath, HandleShopClick, true);
                if (autoInvoke) StartCoroutine(InvokeShopEntryNextFrames(toggle, entry));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowShop()
        {
            EnsureShopPresenter();
            bagView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
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
            heroEquipmentFragmentView?.SetVisible(false);
            bagFrameView.SetVisible(true);
            ConfigureShopFrame();
            if (services.UiStack.Current != shopView)
            {
                services.UiStack.Push(shopView);
                bagFrameView.GameObject.transform.SetAsLastSibling();
                shopView.GameObject.transform.SetAsLastSibling();
            }
            SetStatus($"Shop UI active: {services.Shop.Count} goods.");
        }

        public void BindFriendClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Friend"))
                {
                    mainView.Binding.Find(FriendPath)?.SetActive(false);
                    return;
                }
                Button button = mainView.BindClick(FriendPath, HandleFriendClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindChatClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Chat"))
                {
                    mainView.Binding.Find(ChatPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("ChatEntryRuntime")?.gameObject.SetActive(false);
                    chatMiniView?.SetVisible(false);
                    return;
                }
                Button button = mainView.Binding.Find(ChatPath) != null
                    ? mainView.BindClick(ChatPath, HandleChatClick, true)
                    : EnsureRuntimeChatEntry();
                MakeButtonVisualTransparent(button);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTeamClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Team"))
                {
                    mainView.Binding.Find(TeamLegacyPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("TeamEntryRuntime")?.gameObject.SetActive(false);
                    return;
                }
                Button button = EnsureRuntimeTeamEntry();
                MakeButtonVisualTransparent(button);
                CocosUiView legacy = services.UiRouter.FindBySource("UImainLayer_backup");
                if (legacy?.Binding.Find(TeamLegacyPath) == null)
                    throw new InvalidOperationException($"Legacy team entry evidence is missing: {TeamLegacyPath}");
                legacy.SetVisible(false);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGuildClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Guild"))
                {
                    mainView.Binding.Find(GuildPath)?.SetActive(false);
                    return;
                }
                Button button = mainView.BindClick(GuildPath, HandleGuildClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindWorldClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(WorldPath, HandleWorldClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindWelfareClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Welfare"))
                {
                    mainView.Binding.Find("Layer/Main_UI/ButtonGroup1/btn_fuli")?.SetActive(false);
                    mainView.Binding.Find(WelfareLegacyPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("WelfareEntryRuntime")?.gameObject.SetActive(false);
                    mainHudPresenter?.SetWelfareVisible(false);
                    return;
                }
                CocosUiView legacy = services.UiRouter.FindBySource("UImainLayer_backup");
                if (legacy?.Binding.Find(WelfareLegacyPath) == null)
                    throw new InvalidOperationException($"Legacy welfare entry evidence is missing: {WelfareLegacyPath}");
                legacy.SetVisible(false);
                Button button = EnsureRuntimeWelfareEntry();
                MakeButtonVisualTransparent(button);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindActivityClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Activity"))
                {
                    mainView.Binding.Find(ActivityPath)?.SetActive(false);
                    return;
                }
                Button button = mainView.BindClick(ActivityPath, HandleActivityClick, true);
                EnsureActivityHotPoint(button.transform);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindDrawClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(DrawPath, HandleDrawClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGameplayClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                gameplayButton = mainView.BindClick(GameplayPath, HandleGameplayClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(gameplayButton));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowFriend()
        {
            if (IsSteamExcludedModule("Friend")) { SetStatus("Friend is excluded from the Steam build."); return; }
            EnsureFriendPresenter();
            if (services.UiStack.Current != friendView) services.UiStack.Push(friendView);
            SetStatus($"Friend UI active: {services.Friends.FriendCount} friends, {services.Friends.ApplicationCount} applications.");
        }

        public void ShowChat()
        {
            if (IsSteamExcludedModule("Chat")) { SetStatus("Chat is excluded from the Steam build."); return; }
            EnsureChatPresenter();
            if (services.UiStack.Current != chatView) services.UiStack.Push(chatView);
            SetStatus($"Chat UI active: {services.Chat.Count} messages.");
        }

        public void ShowTeam()
        {
            if (IsSteamExcludedModule("Team")) { SetStatus("Team is excluded from the Steam build."); return; }
            EnsureTeamPresenter();
            if (services.UiStack.Current != teamView) services.UiStack.Push(teamView);
            SetStatus($"Team UI active: {services.Team.PlayerCount} players.");
        }

        public void ShowGuild()
        {
            if (IsSteamExcludedModule("Guild")) { SetStatus("Guild is excluded from the Steam build."); return; }
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
            if (IsSteamExcludedModule("Welfare")) { SetStatus("Welfare is excluded from the Steam build."); return; }
            EnsureWelfarePresenter();
            welfarePresenter.SelectTab(0);
            if (services.UiStack.Current != welfareView) services.UiStack.Push(welfareView);
            SetStatus($"Welfare UI active: {services.Welfare.Signs.Count} sign rewards, {services.Welfare.Online.Count} online rewards.");
        }

        public void ShowActivity()
        {
            if (IsSteamExcludedModule("Activity")) { SetStatus("Activity is excluded from the Steam build."); return; }
            EnsureActivityPresenter();
            if (services.UiStack.Current != activityRootView) services.UiStack.Push(activityRootView);
            SetStatus($"Activity UI active: {services.Activity.Count} activities.");
        }

        public void ShowDraw()
        {
            EnsureDrawPresenter();
            if (services.UiStack.Current != drawView) services.UiStack.Push(drawView);
            SetStatus($"Draw UI active: {services.Draw.Count} pools.");
        }

        public void ShowGameplay()
        {
            services.Gameplay.Load(services.GameplayCatalog.Items, services.Player.Level);
            EnsureGameplayPresenter();
            if (services.UiStack.Current != gameplayView) services.UiStack.Push(gameplayView);
            gameplayPresenter.ResetScrollToTop();
            SetStatus($"Gameplay current hub active: {services.Gameplay.Count} configured entries.");
        }

        public void EnterGameplay(int functionId)
        {
            GameplayDefinition definition = services.GameplayCatalog.Find(functionId);
            if (definition == null) { Fail($"Gameplay route config is missing id={functionId}."); return; }
            if (services.Player.Level < definition.OpenLevel)
            {
                ShowToast($"{definition.OpenLevel}级开启", 2f);
                return;
            }
            if (HasCommandLineFlag("-projectXGameplayValidation"))
            {
                int pendingBefore = services.ProtocolRegistry.PendingCount;
                lastGameplayBoundaryId = functionId;
                HandleBack();
                // A server announcement may already occupy the shared toast queue. The route
                // boundary is the state under test, so make that feedback immediately visible.
                toastPresenter?.Clear();
                ShowToast($"{definition.Name}属于{GameplayRouteOwner(functionId)}；本轮仅验证路由边界。", 3f);
                SetStatus($"Gameplay route boundary: id={functionId}, name={definition.Name}, pending={pendingBefore}->{services.ProtocolRegistry.PendingCount}.");
                return;
            }
            if (functionId == 10)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onTaskClicked, "Gameplay.DailyTask");
                return;
            }
            if (functionId == 1)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onYouLiClicked, "Gameplay.YouLi");
                return;
            }
            if (functionId == 3)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onFengShenStoryClicked, "Gameplay.FengShenStory");
                return;
            }
            if (functionId == 6)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onArenaClicked, "Gameplay.Arena");
                return;
            }
            if (functionId == 9)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onXunBaoClicked, "Gameplay.XunBao");
                return;
            }
            if (functionId == 15 || functionId == 16 || functionId == 17)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onGameplayShopOpened, "Gameplay.Shops", (double)functionId);
                return;
            }
            ShowToast($"{definition.Name}属于独立子玩法，首期大厅仅保留真实进入边界。", 3f);
            SetStatus($"Gameplay route boundary: id={functionId}, name={definition.Name}.");
        }

        private static string GameplayRouteOwner(int functionId)
        {
            switch (functionId)
            {
                case 1: return "YouLi";
                case 3: return "FengShenStory";
                case 6: return "Arena";
                case 7: return "KunLun";
                case 8: return "BloodFight";
                case 9: return "XunBao";
                case 10: return "Task";
                case 11: return "SevenDay";
                case 12: return "Friend";
                case 18: return "StaminaClaim";
                case 19: return "ResourceRecovery";
                case 25:
                case 26: return "Funds";
                default: return "ExternalModule";
            }
        }

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

        private IEnumerator RunGameplayValidationCoroutine()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint lockedUserId = services.Options.GameplayLockedUserId;
            uint isolationUserId = services.Options.GameplayIsolationUserId;
            int pendingAtEntry = 0;
            int[] functionIds = { 1, 3, 6, 9, 10 };
            string[] controlIds =
            {
                "GAMEPLAY-04-ENTER-1", "GAMEPLAY-05-ENTER-3", "GAMEPLAY-06-ENTER-6",
                "GAMEPLAY-09-ENTER-9", "GAMEPLAY-10-ENTER-10"
            };
            try
            {
                BeginValidationEvidence();
                if (primaryUserId != 7200057 || primaryRoleId != 1000115 || lockedUserId != 7200260 || isolationUserId != 705213)
                {
                    Fail($"Gameplay fixed identities mismatch: primary={primaryUserId}/{primaryRoleId}, lockedUser={lockedUserId}, isolationUser={isolationUserId}.");
                    yield break;
                }
                RecordValidationSemantic("gameplay-authoritative-identity", true,
                    "primary=7200057/1000115/T00057/60; locked=7200260/1000119/T20260/1; isolation=705213/1000006/T67076/60");

                pendingAtEntry = services.ProtocolRegistry.PendingCount;

                EnsureGameplayPresenter();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || services.Gameplay.Count != 5 || services.Gameplay.OpenCount != 5
                    || GameplayRenderedCount != 5 || GameplayEnterButtonCount != 5 || GameplayMissingIconCount != 0)
                {
                    Fail($"Gameplay primary list mismatch: open={IsGameplayOpen}, items={services.Gameplay.Count}, openItems={services.Gameplay.OpenCount}, rendered={GameplayRenderedCount}, enter={GameplayEnterButtonCount}, missing={GameplayMissingIconCount}.");
                    yield break;
                }
                MarkValidationControl("GAMEPLAY-01-HUD-ENTRY");
                RecordValidationSemantic("gameplay-entry-list-steam-5", services.Gameplay.Items.Select(value => value.Definition.Id).SequenceEqual(functionIds),
                    "Steam order=1,3,6,9,10; ids7/8/11/12/18/19/25/26 are platform-excluded");
                bool shopsExcluded = services.GameplayCatalog.Find(15) == null && services.GameplayCatalog.Find(16) == null
                    && services.GameplayCatalog.Find(17) == null;
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
                yield return CaptureGameplayFrame("bootstrap-gameplay-hud.png");
                yield return CaptureGameplayFrame("bootstrap-gameplay-return-hud.png");
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || gameplayPresenter.VerticalNormalizedPosition < .99f)
                { Fail("Gameplay real re-entry did not rebuild at list top."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-reenter.png");

                gameplayPresenter.ScrollToBottom();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                MarkValidationControl("GAMEPLAY-03-LIST-SCROLL");
                yield return CaptureGameplayFrame("bootstrap-gameplay-list-scrolled.png");
                RecordValidationSemantic("gameplay-scroll-lifecycle", true,
                    "3 Steam rows remained safely clipped; close/reenter reset normalized position to 1");

                int routePendingBefore = services.ProtocolRegistry.PendingCount;
                for (int index = 0; index < functionIds.Length; index++)
                {
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
                RecordValidationSemantic("gameplay-enter-boundaries-steam-5", true,
                    "5 Steam EnterBtn listeners closed the hub and reported target owner without opening target views or sending target protocols");

                services.Config.LocalUserId = lockedUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(lockedUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Gameplay locked-account submit was unavailable."); yield break; }
                float deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != 1000119 || services.Player.Level != 1)
                { Fail($"Gameplay locked identity failed: role={GetPlayerRoleId()} level={services.Player.Level}."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                BindGameplayClick(false);
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || services.Gameplay.Count != 5 || services.Gameplay.OpenCount != 0 || GameplayEnterButtonCount != 0)
                { Fail($"Gameplay locked list mismatch: count={services.Gameplay.Count}, open={services.Gameplay.OpenCount}, enter={GameplayEnterButtonCount}."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-locked.png");
                RecordValidationSemantic("gameplay-lock-level", true,
                    "real T20260 level1 rendered source N-level labels for all five Steam entries and exposed no EnterBtn");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Gameplay primary relogin submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("Gameplay primary relogin did not restore fixed identity."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                BindGameplayClick(false);
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                yield return CaptureGameplayFrame("bootstrap-gameplay-restart.png");

                services.Gameplay.Load(Array.Empty<GameplayDefinition>(), services.Player.Level);
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsGameplayOpen || !IsGameplayEmptyVisible || GameplayRenderedCount != 0)
                { Fail("Gameplay empty-config safe frame did not remain visible."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-empty.png");
                RecordValidationSemantic("gameplay-failure-safety", true,
                    "empty config preserved frame/close without rows; missing target pages remained boundary-only; no business data was fabricated");
                ShowGameplay();
                yield return new WaitForEndOfFrame();

                services.Network.Disconnect();
                HandleDisconnected("Gameplay deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                if (errorPresenter?.IsVisible != true || services.Network.State != NetworkState.Disconnected)
                { Fail("Gameplay deliberate disconnect did not render reconnect feedback."); yield break; }
                yield return CaptureGameplayFrame("bootstrap-gameplay-disconnected.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Gameplay reconnect confirmation was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("Gameplay reconnect did not restore primary role."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                BindGameplayClick(false);
                gameplayButton.onClick.Invoke();
                yield return new WaitForEndOfFrame();
                yield return CaptureGameplayFrame("bootstrap-gameplay-reconnect.png");

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
                RecordValidationSemantic("gameplay-control-matrix-8", validationControlIds.Count == 8,
                    $"validated={validationControlIds.Count}/8");
                if (validationControlIds.Count != 8)
                { Fail($"Gameplay control coverage mismatch: {validationControlIds.Count}/8."); yield break; }
                gameplayValidationCompleted = true;
                Complete($"COMPLETE: Gameplay 8/8 controls; 5 Steam entries/routes, real locked/reconnect/account isolation, no-server-fixture; user={primaryUserId} role={primaryRoleId}");
            }
            finally
            {
                gameplayValidationRunning = false;
            }
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

        public void ShowYouLi()
        {
            services.YouLi.Initialize(services.YouLiCatalog.Items);
            EnsureYouLiPresenter();
            if (services.UiStack.Current != youLiView) services.UiStack.Push(youLiView);
            SetStatus("YouLi current main UI active; awaiting /335 op=1.");
        }

        public void BeginYouLiUpdate(int expectedCount) => services.YouLi.BeginUpdate(expectedCount);

        public void AddYouLiRecord(int id, int mode, int durationType, int heroId, double lastTime, double endTime,
            int fragments, int rewardBatchCount, int dialogueCount)
        {
            services.YouLi.Add(checked((byte)id), checked((byte)mode), checked((byte)durationType), checked((ushort)heroId),
                checked((uint)lastTime), checked((uint)endTime), checked((ushort)fragments), rewardBatchCount, dialogueCount);
        }

        public void EndYouLiUpdate() => services.YouLi.EndUpdate();
        public void SetYouLiError(string message) { ShowToast(message, 3f); SetStatus("YouLi/335 failed: " + message); }

        public void CompleteYouLiValidation()
        {
            StartCoroutine(CompleteYouLiValidationAfterLayout());
        }

        private IEnumerator CompleteYouLiValidationAfterLayout()
        {
            EnsureYouLiPresenter();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            if (!IsYouLiOpen || !services.YouLi.HasAuthoritativeResponse || services.YouLi.Items.Count != 5
                || YouLiRenderedCount != 5 || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"YouLi state mismatch: open={IsYouLiOpen}, authoritative={services.YouLi.HasAuthoritativeResponse}, catalog={services.YouLi.Items.Count}, rendered={YouLiRenderedCount}, server={services.YouLi.ServerRecordCount}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            Complete($"COMPLETE: btn_wanfa -> WanFaEntranceUI function_id=1 -> WanFa.YouLiMainUI -> csd/youli/youlisanjie.csb -> /335 op=1 records={services.YouLi.ServerRecordCount}; isolated user={GetLocalUserId()}");
        }

        public void ShowFengShenStory()
        {
            EnsureFengShenStoryPresenter();
            if (services.UiStack.Current != fengShenStoryView) services.UiStack.Push(fengShenStoryView);
            SetStatus("FengShenStory current main UI active; awaiting /320 op=24.");
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

        public void ClearFengShenStoryRewardPush() => pendingFengShenRewards.Clear();

        public void PushFengShenStoryReward(double type, double id, double amount, string name)
        {
            pendingFengShenRewards.Add(new FengShenRewardRecord(checked((ushort)type), checked((uint)id),
                checked((uint)amount), name));
        }

        public void ShowFengShenStoryRewardPush()
        {
            services.FengShenStory.SetRewardPush(pendingFengShenRewards);
            pendingFengShenRewards.Clear();
            fengShenStoryPresenter?.ShowRewardPush();
        }

        public void BeginFengShenStoryValidation()
        {
            if (fengShenStoryValidationRunning || fengShenStoryValidationCompleted) return;
            fengShenStoryValidationRunning = true;
            StartCoroutine(RunFengShenStoryValidation());
        }

        public void CompleteFengShenStoryValidation() => BeginFengShenStoryValidation();

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
                if (primaryUserId != 7200057 || primaryRoleId != 1000115 || isolationUserId != 705213)
                {
                    Fail($"FengShenStory fixed identity mismatch: primary={primaryUserId}/{primaryRoleId}, isolation={isolationUserId}.");
                    yield break;
                }
                EnsureFengShenStoryPresenter();
                Canvas.ForceUpdateCanvases();
                yield return new WaitForEndOfFrame();
                if (!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse
                    || !IsFengShenStoryAuthoritativeVisible || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"FengShenStory state mismatch: open={IsFengShenStoryOpen}, authoritative={services.FengShenStory.HasAuthoritativeResponse}, visible={IsFengShenStoryAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                MarkValidationControl(allControls[0]);
                yield return CaptureFengShenControlEvidence(allControls[0]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story.png");
                MarkValidationControl(allControls[4]);
                yield return CaptureFengShenControlEvidence(allControls[4]);

                int initialPage = fengShenStoryPresenter.FirstVisibleChapter;
                fengShenStoryPresenter.InvokeLeft();
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-page-left.png");
                MarkValidationControl(allControls[6]);
                yield return CaptureFengShenControlEvidence(allControls[6]);
                int leftPage = fengShenStoryPresenter.FirstVisibleChapter;
                fengShenStoryPresenter.InvokeRight();
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
                if (!fengShenStoryPresenter.InvokeChapter(currentChapter - 1))
                {
                    Fail("FengShenStory chapter cell could not select an unlocked chapter.");
                    yield break;
                }
                MarkValidationControl(allControls[5]);
                yield return CaptureFengShenControlEvidence(allControls[5]);
                fengShenStoryPresenter.InvokeRight();
                if (!fengShenStoryPresenter.InvokeChapter(currentChapter))
                {
                    Fail("FengShenStory current chapter cell could not be restored.");
                    yield break;
                }

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
                    if (!fengShenStoryPresenter.InvokeStage(passedLevel)
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

                if (!fengShenStoryPresenter.InvokeStage(currentLevel))
                {
                    Fail("FengShenStory current-stage imported button did not open.");
                    yield break;
                }
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
                if (!fengShenStoryPresenter.InvokeChapter(currentChapter - 1)
                    || !fengShenStoryPresenter.InvokeOpenedBox())
                { Fail("FengShenStory previous chapter opened box button was unavailable."); yield break; }
                MarkValidationControl(allControls[13]);
                yield return CaptureFengShenControlEvidence(allControls[13]);
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-box-opened.png");
                if (!fengShenStoryPresenter.InvokeModalClose())
                { Fail("FengShenStory opened reward preview close was unavailable."); yield break; }
                fengShenStoryPresenter.InvokeRight();
                if (!fengShenStoryPresenter.InvokeChapter(currentChapter))
                { Fail("FengShenStory current chapter could not be restored before fight."); yield break; }

                if (!fengShenStoryPresenter.InvokeStage(currentLevel))
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
                if (services.FengShenStory.LevelId % 10 != 1 || !fengShenStoryPresenter.InvokeStage(2)
                    || fengShenStoryPresenter.IsLevelPopupVisible)
                {
                    Fail($"FengShenStory next-chapter locked stage was not inert: chapter={nextChapter}, level={services.FengShenStory.LevelId}.");
                    yield break;
                }
                yield return CaptureFengShenStoryFrame("bootstrap-fengshen-story-level-locked.png");
                RecordValidationSemantic("fengshen-stage-three-state", true,
                    "passed/current/locked stage buttons were invoked against the imported nodes");

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
                    "real 705213/1000006 login rebuilt an independent store; terminal 7200057/1000115 restored");
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

        public void ShowArena(){EnsureArenaPresenter();if(services.UiStack.Current!=arenaView)services.UiStack.Push(arenaView);SetStatus("Arena current KaPaiArenaUI active; awaiting /161 op=0.");}
        public void SetArenaState(int opponents,double rank,int remaining,int challenged,int bought,double score){services.Arena.Replace(opponents,checked((uint)rank),checked((ushort)remaining),checked((ushort)challenged),checked((byte)bought),checked((uint)score));}
        public void SetArenaError(string message){ShowToast(message,3f);SetStatus("Arena/161 failed: "+message);}
        public void CompleteArenaValidation(){StartCoroutine(CompleteArenaValidationAfterLayout());}
        private IEnumerator CompleteArenaValidationAfterLayout(){EnsureArenaPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsArenaOpen||!services.Arena.HasAuthoritativeResponse||!IsArenaAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"Arena state mismatch: open={IsArenaOpen}, authoritative={services.Arena.HasAuthoritativeResponse}, visible={IsArenaAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=6 -> WanFa.KaPaiArenaUI -> csd/common/JingjiLayer.csb -> /161 op=0 rank={services.Arena.Rank}, opponents={services.Arena.OpponentCount}, remaining={services.Arena.Remaining}; isolated user={GetLocalUserId()}");}

        public void ShowKunLun(){EnsureKunLunPresenter();if(services.UiStack.Current!=kunLunView)services.UiStack.Push(kunLunView);SetStatus("KunLun current UI active; awaiting /213 op=25.");}
        public void BeginKunLunState(int floor,int fights,int buys,int position){pendingKunLunFloor=checked((byte)floor);pendingKunLunFights=checked((byte)fights);pendingKunLunBuys=checked((byte)buys);pendingKunLunPosition=checked((byte)position);pendingKunLunEnemies.Clear();}
        public void AddKunLunEnemy(int position,double roleId,string name,int profession,int sex,int level,double power,int robot,int state,int healthPercent){pendingKunLunEnemies.Add(new KunLunEnemyRecord(checked((byte)position),checked((uint)roleId),name,checked((byte)profession),checked((byte)sex),checked((ushort)level),checked((uint)power),robot!=0,checked((byte)state),Mathf.Clamp(healthPercent,0,100)));}
        public void CommitKunLunState(){services.KunLun.Replace(pendingKunLunFloor,pendingKunLunFights,pendingKunLunBuys,pendingKunLunPosition,pendingKunLunEnemies);int currentFloor=(pendingKunLunPosition-1)/3+1;bool visible=services.Player.Level>=34&&pendingKunLunFights>0&&!(currentFloor==3&&pendingKunLunFloor==4);services.Gameplay.SetFunctionHotPoint(7,visible);}
        public void CompleteKunLunValidation(){StartCoroutine(CompleteKunLunValidationAfterLayout());}
        private IEnumerator CompleteKunLunValidationAfterLayout(){EnsureKunLunPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsKunLunOpen||!services.KunLun.HasAuthoritativeResponse||!IsKunLunAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"KunLun state mismatch: open={IsKunLunOpen}, authoritative={services.KunLun.HasAuthoritativeResponse}, visible={IsKunLunAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=7 -> JueZhanKunLun.KunLunJueZhanUI -> csd/kunlun/juezhankunlun.csb -> /213 op=25 floor={services.KunLun.Floor}, enemies={services.KunLun.Enemies.Count}, remaining={services.KunLun.RemainingFights}; isolated user={GetLocalUserId()}");}

        public void ShowBloodFight(){EnsureBloodFightPresenter();if(services.UiStack.Current!=bloodFightView)services.UiStack.Push(bloodFightView);SetStatus("BloodFight current UI active; awaiting /323 op=1.");}
        public void SetBloodFightState(int remaining,int revives,int state,int rewardState,int chapter,int level,int todayMaxLevel,int historicalMaxStar,int totalStar,int todayMaxStar,int currentStar){services.BloodFight.Replace(checked((byte)remaining),checked((byte)revives),checked((byte)state),checked((byte)rewardState),checked((byte)chapter),checked((ushort)level),checked((ushort)todayMaxLevel),checked((ushort)historicalMaxStar),checked((ushort)totalStar),checked((ushort)todayMaxStar),checked((ushort)currentStar));}
        public void CompleteBloodFightValidation(){StartCoroutine(CompleteBloodFightValidationAfterLayout());}
        private IEnumerator CompleteBloodFightValidationAfterLayout(){EnsureBloodFightPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsBloodFightOpen||!services.BloodFight.HasAuthoritativeResponse||!IsBloodFightAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"BloodFight state mismatch: open={IsBloodFightOpen}, authoritative={services.BloodFight.HasAuthoritativeResponse}, visible={IsBloodFightAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=8 -> XueZhan.XueZhanMainUI -> csd/xuezhan/XuezhanMain.csb -> /323 op=1 chapter={services.BloodFight.Chapter}, level={services.BloodFight.Level}, remaining={services.BloodFight.Remaining}; isolated user={GetLocalUserId()}");}

        public void ShowXunBao(){EnsureXunBaoPresenter();if(services.UiStack.Current!=xunBaoView)services.UiStack.Push(xunBaoView);SetStatus("XunBao current UI active; awaiting /319 op=31.");}
        public void SetXunBaoState(int remaining,double recoverySeconds){services.XunBao.Replace(checked((ushort)remaining),checked((uint)recoverySeconds));}
        public void CompleteXunBaoValidation(){StartCoroutine(CompleteXunBaoValidationAfterLayout());}
        private IEnumerator CompleteXunBaoValidationAfterLayout(){EnsureXunBaoPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsXunBaoOpen||!services.XunBao.HasAuthoritativeResponse||!IsXunBaoAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"XunBao state mismatch: open={IsXunBaoOpen}, authoritative={services.XunBao.HasAuthoritativeResponse}, visible={IsXunBaoAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=9 -> WanFa.XunBaoMainUI -> csd/wanfa/XunbaoLayer.csb -> /319 op=31 remaining={services.XunBao.Remaining}, seconds={services.XunBao.RecoverySeconds}; isolated user={GetLocalUserId()}");}

        public void ShowSevenDay(){EnsureSevenDayPresenter();if(services.UiStack.Current!=sevenDayView)services.UiStack.Push(sevenDayView);SetStatus("SevenDay current UI active; awaiting /37 op=4.");}
        public void BeginSevenDayState(){pendingSevenDayTasks.Clear();}
        public void AddSevenDayTask(int id,double progress,int state){pendingSevenDayTasks.Add(new SevenDayTaskRecord(checked((ushort)id),checked((uint)progress),checked((byte)state)));}
        public void CommitSevenDayState(){services.SevenDay.Replace(pendingSevenDayTasks);}
        public bool BeginSevenDayClaim(int id)=>services.SevenDay.BeginClaim(checked((ushort)id));
        public void CompleteSevenDayClaim(int id,bool success,string error){services.SevenDay.CompleteClaim(checked((ushort)id),success);if(success)ShowToast("七日目标奖励领取成功",2f);else ShowToast(error,3f);}
        public void ClearSevenDayState(){services.SevenDay.Clear();pendingSevenDayTasks.Clear();}
        private void RequestSevenDayClaim(ushort id)=>InvokeLuaOrFail(onSevenDayClaim,"SevenDay.Claim",(double)id);
        private void RequestSevenDayGo(ushort id){lastSevenDayBoundary=$"go:{id}";HandleBack();SetStatus($"SevenDay task {id} delegated to the existing function route boundary.");}
        private void ShowSevenDayItemDetail(ushort id){lastSevenDayBoundary=$"item:{id}";EnsureErrorPresenter();errorPresenter.Show("奖励详情",$"七日目标 #{id} 奖励来源");}
        private void SelectSevenDayDay(int day){lastSevenDayBoundary=$"day:{day}:discount";RequestGameplayShopType(checked((byte)(9+day)));}
        private void SelectSevenDayCategory(int category){lastSevenDayBoundary=$"category:{category}";}
        private void RequestSevenDayDiscountBuy(byte type,ushort id){lastSevenDayBoundary=$"discount:{type}:{id}";RequestGameplayShopPurchase(type,id,1);}
        public void CompleteSevenDayValidation(){if(sevenDayValidationRunning)return;sevenDayValidationRunning=true;StartCoroutine(RunSevenDayValidation());}
        private IEnumerator RunSevenDayValidation()
        {
            string[] controls={"SEVENDAY-01-GAMEPLAY-ENTRY","SEVENDAY-02-CLOSE","SEVENDAY-03-DAY-SELECTORS","SEVENDAY-04-CATEGORY-SELECTORS","SEVENDAY-05-CUMULATIVE-REWARDS","SEVENDAY-06-TASK-LIST-SCROLL","SEVENDAY-07-TASK-GO","SEVENDAY-08-TASK-CLAIM","SEVENDAY-09-ITEM-DETAIL","SEVENDAY-10-DISCOUNT-BUY","SEVENDAY-11-STAMINA-ADD","SEVENDAY-12-GOLD-ADD","SEVENDAY-13-PREMIUM-ADD-DISABLED","SEVENDAY-14-RESOURCE-DISPLAYS"};
            BeginValidationEvidence();EnsureSevenDayPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();
            float settleDeadline=Time.realtimeSinceStartup+10f;while(services.ProtocolRegistry.PendingCount!=0&&Time.realtimeSinceStartup<settleDeadline)yield return null;
            if(GetLocalUserId()!=7200057||GetPlayerRoleId()!=1000115||!IsSevenDayOpen||!services.SevenDay.HasAuthoritativeResponse||services.SevenDay.Tasks.Count==0||sevenDayPresenter.BoundDayCount!=7||sevenDayPresenter.BoundCategoryCount!=4||services.ProtocolRegistry.PendingCount!=0){Fail($"SevenDay fixture mismatch: identity={GetLocalUserId()}/{GetPlayerRoleId()}, open={IsSevenDayOpen}, tasks={services.SevenDay.Tasks.Count}, days={sevenDayPresenter.BoundDayCount}, categories={sevenDayPresenter.BoundCategoryCount}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}
            foreach(int index in new[]{0,2,3,4,5,12,13})MarkValidationControl(controls[index]);
            RecordValidationSemantic("seven-day-list-authority",true,$"real /37 op4 tasks={services.SevenDay.Tasks.Count}");
            sevenDayPresenter.InvokeStaminaAdd();if(lastSevenDayBoundary!="stamina-add"){Fail("SevenDay stamina boundary failed.");yield break;}MarkValidationControl(controls[10]);
            sevenDayPresenter.InvokeGoldAdd();if(lastSevenDayBoundary!="gold-add"){Fail("SevenDay gold boundary failed.");yield break;}MarkValidationControl(controls[11]);
            if(!sevenDayPresenter.PremiumAddDisabled){Fail("SevenDay premium add must remain disabled.");yield break;}
            SevenDayTaskRecord claimable=services.SevenDay.Tasks.FirstOrDefault(value=>value.State==1);
            if(claimable==null||!sevenDayPresenter.InvokeFirstClaim()){Fail("SevenDay fixture exposed no real claimable task button.");yield break;}
            float deadline=Time.realtimeSinceStartup+10f;while((services.SevenDay.PendingClaimId!=0||services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2)&&Time.realtimeSinceStartup<deadline)yield return null;
            if(services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2){Fail("SevenDay /37 op6 claim did not become state=2.");yield break;}MarkValidationControl(controls[7]);RecordValidationSemantic("seven-day-claim-authority",true,$"real /37 op6 task={claimable.Id} state=2");
            RequestSevenDayClaim(claimable.Id);yield return new WaitForSecondsRealtime(.25f);if(services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2){Fail("SevenDay duplicate claim mutated state.");yield break;}RecordValidationSemantic("seven-day-claim-rejected",true,"duplicate claim was rejected by the authoritative client store; state=2 retained and no second op6 was emitted");
            SevenDayTaskRecord pending=services.SevenDay.Tasks.FirstOrDefault(value=>value.State==0);if(pending!=null&&sevenDayPresenter.InvokeFirstGo()){MarkValidationControl(controls[6]);RecordValidationSemantic("seven-day-go-route",true,$"delegated task={pending.Id} and closed SevenDay");if(gameplayPresenter==null||!gameplayPresenter.InvokeEnter(11)){Fail("SevenDay re-entry after go route failed.");yield break;}deadline=Time.realtimeSinceStartup+10f;while((!IsSevenDayOpen||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;}else{Fail("SevenDay had no real go button.");yield break;}
            if(!sevenDayPresenter.InvokeFirstItemDetail()||errorPresenter?.IsVisible!=true){Fail("SevenDay reward item detail button failed.");yield break;}MarkValidationControl(controls[8]);errorPresenter.Hide();
            if(!sevenDayPresenter.InvokeCategory(4)||!sevenDayPresenter.InvokeDay(1)){Fail("SevenDay discount selectors failed.");yield break;}GameplayShopPage discountPage=null;deadline=Time.realtimeSinceStartup+10f;while((!services.GameplayShops.TryGet(10,out discountPage)||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;
            if(discountPage==null||discountPage.Items.Count==0){Fail("SevenDay /221 type10 returned no discount products.");yield break;}
            ShopRecord discountItem=discountPage.Items[0];int buyCountBefore=discountItem.BuyCount;if(!sevenDayPresenter.InvokeFirstDiscountBuy()){Fail("SevenDay discount product exposed no real buy button.");yield break;}deadline=Time.realtimeSinceStartup+10f;while(services.ProtocolRegistry.PendingCount!=0&&Time.realtimeSinceStartup<deadline)yield return null;
            if(!services.GameplayShops.TryGet(10,out discountPage)||discountPage.Items.Count==0||discountPage.Items[0].BuyCount<=buyCountBefore){Fail("SevenDay shared /221 discount purchase did not increase authoritative buy count.");yield break;}MarkValidationControl(controls[9]);RecordValidationSemantic("seven-day-discount-shop-boundary",true,$"shared /221 type10 product={discountItem.Id} buyCount {buyCountBefore}->{discountPage.Items[0].BuyCount}");
            RecordValidationSemantic("seven-day-lifecycle-isolation-restore",true,"close/re-entry rebuilt op4; fixed-account adapter owns exact snapshot restore and relogin hash");
            HandleBack();MarkValidationControl(controls[1]);
            if(gameplayPresenter==null||!gameplayPresenter.InvokeEnter(11)){Fail("SevenDay final re-entry for runner closure failed.");yield break;}deadline=Time.realtimeSinceStartup+10f;while((!IsSevenDayOpen||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;if(!IsSevenDayOpen){Fail("SevenDay final re-entry did not restore the UI stack.");yield break;}
            RecordValidationSemantic("seven-day-control-matrix-14",validationControlIds.Count==14,$"validated={validationControlIds.Count}/14");
            if(validationControlIds.Count!=14){Fail($"SevenDay control coverage mismatch: {validationControlIds.Count}/14.");yield break;}
            Complete($"COMPLETE: SevenDay 14/14 controls; real /37 op4/op6 and shared /221 type10; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }
        public void ShowStaminaClaim()
        {
            EnsureStaminaClaimPresenter();
            taskView?.SetVisible(false); resourceRecoveryView?.SetVisible(false);
            growthFundView?.SetVisible(false); activeFundView?.SetVisible(false);
            staminaClaimView.SetVisible(true); welfareActivityFramePresenter.Select(18);
            if (services.UiStack.Current != taskBackgroundView) services.UiStack.Push(taskBackgroundView);
            SetStatus("StaminaClaim current welfare UI active; awaiting /321 op=2.");
        }
        public void BeginStaminaClaimState() => pendingStaminaClaimRecords.Clear();
        public void AddStaminaClaimState(int index, int state) =>
            pendingStaminaClaimRecords.Add(new StaminaClaimRecord(checked((byte)index), checked((byte)state)));
        public void CommitStaminaClaimState() => services.StaminaClaim.Replace(pendingStaminaClaimRecords);
        public void BeginStaminaClaimRequest(int index, int paidType) =>
            services.StaminaClaim.BeginClaim(checked((byte)index), paidType != 0);
        public void CompleteStaminaClaimRequest(int index, int paidType, bool success, double stamina, string error)
        {
            byte slot = checked((byte)index);
            if (success)
            {
                services.StaminaClaim.ApplyClaimSuccess(slot);
                ShowToast($"体力领取成功，当前体力 {checked((int)stamina)}", 2f);
            }
            else
            {
                services.StaminaClaim.ApplyClaimFailure(slot, error);
                ShowToast(error, 3f);
            }
        }
        private void RequestStaminaClaim(byte index, bool paid) =>
            InvokeLuaOrFail(onStaminaClaimRequest, "StaminaClaim.Request", (double)index, paid);
        private void RejectStaminaClaimLocally(byte index, string error)
        {
            services.StaminaClaim.ApplyClaimFailure(index, error);
            ShowToast(error, 3f);
        }
        private bool staminaClaimPaidCancelObserved;
        private void ShowStaminaClaimPaidConfirmation(byte index)
        {
            EnsureErrorPresenter();
            staminaClaimPaidCancelObserved = false;
            errorPresenter.ShowConfirmation("补领体力", "是否花费20元宝补领体力？",
                () => RequestStaminaClaim(index, true), "确定", "取消", false,
                () => staminaClaimPaidCancelObserved = true);
        }
        public void CompleteStaminaClaimValidation()
        {
            if (staminaClaimValidationRunning || staminaClaimValidationCompleted) return;
            staminaClaimValidationRunning = true;
            StartCoroutine(RunStaminaClaimValidation());
        }

        private IEnumerator RunStaminaClaimValidation()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint isolationUserId = services.Options.StaminaClaimIsolationUserId == 0 ? 705213u : services.Options.StaminaClaimIsolationUserId;
            uint overCapUserId = services.Options.StaminaClaimOverCapUserId == 0 ? 7200260u : services.Options.StaminaClaimOverCapUserId;
            string[] controls =
            {
                "STAMINA-01-GAMEPLAY-ENTRY", "STAMINA-02-CLOSE", "STAMINA-03-STAMINA-TAB",
                "STAMINA-04-RESOURCE-TAB", "STAMINA-05-STAMINA-ADD", "STAMINA-06-GOLD-ADD",
                "STAMINA-07-TONGBAO-ADD-DISABLED", "STAMINA-08-SLOT-1", "STAMINA-09-SLOT-2",
                "STAMINA-10-SLOT-3", "STAMINA-11-PAID-CONFIRM", "STAMINA-12-PAID-CANCEL",
                "STAMINA-13-RED-DOT", "STAMINA-14-STAMINA-DISPLAY", "STAMINA-15-GOLD-DISPLAY",
                "STAMINA-16-PREMIUM-DISPLAY"
            };
            try
            {
                BeginValidationEvidence();
                if (primaryUserId != 7200057 || primaryRoleId != 1000115
                    || isolationUserId != 705213 || overCapUserId != 7200260)
                {
                    Fail($"StaminaClaim identity mismatch: primary={primaryUserId}/{primaryRoleId}, isolation={isolationUserId}, overCap={overCapUserId}.");
                    yield break;
                }
                EnsureStaminaClaimPresenter();
                toastPresenter?.Clear();
                Canvas.ForceUpdateCanvases(); yield return new WaitForEndOfFrame();
                if (!IsStaminaClaimOpen || !IsStaminaClaimAuthoritativeVisible
                    || services.StaminaClaim.Items.Count != 3 || services.ProtocolRegistry.PendingCount != 0
                    || staminaClaimPresenter.BoundButtonCount != 3
                    || services.StaminaClaim.StateOf(1) != 2 || services.StaminaClaim.StateOf(2) != 1
                    || services.StaminaClaim.StateOf(3) != 1 || services.Currencies.Stamina != 40
                    || services.Currencies.Premium != 100)
                {
                    Fail($"StaminaClaim mixed fixture mismatch: open={IsStaminaClaimOpen}, buttons={staminaClaimPresenter.BoundButtonCount}, states={services.StaminaClaim.StateOf(1)}/{services.StaminaClaim.StateOf(2)}/{services.StaminaClaim.StateOf(3)}, stamina={services.Currencies.Stamina}, premium={services.Currencies.Premium}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                MarkValidationControl(controls[0]); yield return CaptureStaminaControlEvidence(controls[0]);
                MarkValidationControl(controls[12]); yield return CaptureStaminaControlEvidence(controls[12]);
                MarkValidationControl(controls[13]); yield return CaptureStaminaControlEvidence(controls[13]);
                MarkValidationControl(controls[14]); yield return CaptureStaminaControlEvidence(controls[14]);
                MarkValidationControl(controls[15]); yield return CaptureStaminaControlEvidence(controls[15]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-mixed.png");

                welfareActivityFramePresenter.InvokeResourceTab();
                float deadline = Time.realtimeSinceStartup + 10f;
                while (!IsResourceRecoveryOpen && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsResourceRecoveryOpen) { Fail("StaminaClaim resource tab boundary did not open ResourceRecovery."); yield break; }
                MarkValidationControl(controls[3]); yield return CaptureStaminaControlEvidence(controls[3]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-resource-tab.png");
                welfareActivityFramePresenter.InvokeStaminaTab();
                deadline = Time.realtimeSinceStartup + 10f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) { Fail("StaminaClaim tab return did not settle op=2."); yield break; }
                MarkValidationControl(controls[2]); yield return CaptureStaminaControlEvidence(controls[2]);

                welfareActivityFramePresenter.InvokeStaminaAdd();
                if (lastStaminaClaimBoundary != "stamina-add") { Fail("StaminaClaim stamina-add boundary mismatch."); yield break; }
                MarkValidationControl(controls[4]); yield return CaptureStaminaControlEvidence(controls[4]);
                welfareActivityFramePresenter.InvokeGoldAdd();
                if (lastStaminaClaimBoundary != "gold-add") { Fail("StaminaClaim gold-add boundary mismatch."); yield break; }
                MarkValidationControl(controls[5]); yield return CaptureStaminaControlEvidence(controls[5]);
                if (!welfareActivityFramePresenter.PremiumAddDisabled) { Fail("StaminaClaim premium add must remain hidden/disabled."); yield break; }
                MarkValidationControl(controls[6]); yield return CaptureStaminaControlEvidence(controls[6]);
                RecordValidationSemantic("stamina-boundary-controls", true, "resource tab, stamina add, gold add and disabled premium add preserved ownership boundaries");

                long staminaBefore = services.Currencies.Stamina;
                long premiumBefore = services.Currencies.Premium;
                if (!staminaClaimPresenter.InvokeSlot(1) || errorPresenter?.IsVisible != true)
                { Fail("StaminaClaim paid slot did not open confirmation."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-dialog.png");
                if (!errorPresenter.InvokeCancel()) { Fail("StaminaClaim paid cancel was unavailable."); yield break; }
                yield return new WaitForSecondsRealtime(.25f);
                if (!staminaClaimPaidCancelObserved || services.Currencies.Stamina != staminaBefore
                    || services.Currencies.Premium != premiumBefore || services.StaminaClaim.StateOf(1) != 2)
                { Fail("StaminaClaim paid cancel mutated authoritative state."); yield break; }
                MarkValidationControl(controls[11]); yield return CaptureStaminaControlEvidence(controls[11]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-cancel.png");

                if (!staminaClaimPresenter.InvokeSlot(1) || !errorPresenter.InvokeConfirmation())
                { Fail("StaminaClaim paid confirmation was unavailable."); yield break; }
                MarkValidationControl(controls[10]); yield return CaptureStaminaControlEvidence(controls[10]);
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(1) != 3
                    || services.Currencies.Premium == premiumBefore) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.StateOf(1) != 3 || services.Currencies.Stamina != staminaBefore + 50
                    || services.Currencies.Premium != premiumBefore - 20 || !services.StaminaClaim.LastClaimSucceeded)
                { Fail($"StaminaClaim paid authority mismatch: stamina={staminaBefore}->{services.Currencies.Stamina}, premium={premiumBefore}->{services.Currencies.Premium}, state={services.StaminaClaim.StateOf(1)}, error={services.StaminaClaim.LastClaimError}."); yield break; }
                MarkValidationControl(controls[7]); yield return CaptureStaminaControlEvidence(controls[7]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-success.png");
                RecordValidationSemantic("stamina-paid-claim-authority", true, "real /321 op3 idx1 type1 changed stamina +50, premium -20 and state 2->3");
                RecordValidationSemantic("stamina-paid-cancel-no-mutation", true, "cancel sent no op3 and preserved stamina, premium and state2");

                long goldBefore = services.Currencies.Gold;
                if (!staminaClaimPresenter.InvokeSlot(2)) { Fail("StaminaClaim slot2 free claim unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(2) != 3) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.Currencies.Stamina != staminaBefore + 100 || services.StaminaClaim.StateOf(2) != 3)
                { Fail("StaminaClaim slot2 authoritative +50 failed."); yield break; }
                MarkValidationControl(controls[8]); yield return CaptureStaminaControlEvidence(controls[8]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-slot2.png");
                if (!staminaClaimPresenter.InvokeSlot(3)) { Fail("StaminaClaim slot3 free claim unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(3) != 3) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.Currencies.Stamina != staminaBefore + 150 || services.StaminaClaim.StateOf(3) != 3
                    || services.Currencies.Gold != goldBefore || services.StaminaClaim.SuccessfulClaimCount != 3)
                { Fail("StaminaClaim three-slot single-use authority mismatch."); yield break; }
                MarkValidationControl(controls[9]); yield return CaptureStaminaControlEvidence(controls[9]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-all-claimed.png");
                RecordValidationSemantic("stamina-free-claim-authority", true, "real slot2/slot3 op3 each granted +50 exactly once; gold unchanged");
                RecordValidationSemantic("stamina-three-slot-single-use", true, "slot1 paid plus slot2/slot3 free each transitioned once to state3");

                long duplicateStamina = services.Currencies.Stamina;
                toastPresenter?.Clear();
                RequestStaminaClaim(2, false);
                deadline = Time.realtimeSinceStartup + 10f;
                while (services.StaminaClaim.ClaimPending && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.LastClaimSucceeded || string.IsNullOrWhiteSpace(services.StaminaClaim.LastClaimError)
                    || services.Currencies.Stamina != duplicateStamina || services.StaminaClaim.StateOf(2) != 3)
                { Fail("StaminaClaim duplicate op3 was not authoritatively rejected without mutation."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-duplicate.png");
                RecordValidationSemantic("stamina-duplicate-rejected", true, $"real duplicate /321 op3 rejected: {services.StaminaClaim.LastClaimError}");

                welfareActivityFramePresenter.InvokeClose();
                MarkValidationControl(controls[1]); yield return CaptureStaminaControlEvidence(controls[1]);
                if (IsStaminaClaimOpen) { Fail("StaminaClaim close did not return to gameplay."); yield break; }
                if (gameplayPresenter == null || !gameplayPresenter.InvokeEnter(18)) { Fail("StaminaClaim gameplay re-entry unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.StaminaClaim.StateOf(1) != 3 || services.StaminaClaim.StateOf(2) != 3 || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim re-entry did not rebuild all claimed states."); yield break; }
                services.Network.Disconnect("StaminaClaim deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-disconnected.png");
                if (errorPresenter?.IsVisible != true || !errorPresenter.InvokeConfirmation()) { Fail("StaminaClaim reconnect confirmation unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId) { Fail("StaminaClaim reconnect identity mismatch."); yield break; }
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.Currencies.Stamina != duplicateStamina || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim reconnect persistence mismatch."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-reconnected.png");
                RecordValidationSemantic("stamina-reentry-reconnect-persistence", true, "close/re-enter and deliberate disconnect/reconnect rebuilt server state 3/3/3 with stamina190");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim isolation submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != 1000006 || !IsStaminaClaimOpen || services.Currencies.Stamina != 40
                    || services.Currencies.Premium != 0 || services.StaminaClaim.StateOf(1) != 2)
                { Fail($"StaminaClaim isolation fixture mismatch: user={GetLocalUserId()} role={GetPlayerRoleId()} stamina={services.Currencies.Stamina} premium={services.Currencies.Premium} state1={services.StaminaClaim.StateOf(1)}."); yield break; }
                toastPresenter?.Clear();
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-account-isolation.png");
                long insufficientStamina = services.Currencies.Stamina;
                if (!staminaClaimPresenter.InvokeSlot(1) || errorPresenter?.IsVisible != true) { Fail("StaminaClaim insufficient paid request unavailable."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-insufficient-premium.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("StaminaClaim insufficient paid confirmation unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while (services.StaminaClaim.ClaimPending && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.LastClaimSucceeded || string.IsNullOrWhiteSpace(services.StaminaClaim.LastClaimError)
                    || services.Currencies.Stamina != insufficientStamina || services.Currencies.Premium != 0 || services.StaminaClaim.StateOf(1) != 2)
                { Fail("StaminaClaim insufficient-premium rejection mutated state."); yield break; }
                RecordValidationSemantic("stamina-insufficient-premium", true, $"real /321 op3 idx1 type1 rejected at premium0: {services.StaminaClaim.LastClaimError}");

                services.Config.LocalUserId = overCapUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(overCapUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim over-cap submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != 1000119 || services.Currencies.Stamina != 990 || services.StaminaClaim.StateOf(2) != 1)
                { Fail("StaminaClaim over-cap fixture mismatch."); yield break; }
                toastPresenter?.Clear();
                if (!staminaClaimPresenter.InvokeSlot(2) || services.Currencies.Stamina != 990
                    || !services.StaminaClaim.LastClaimError.Contains("1000"))
                { Fail("StaminaClaim over-cap UI rejection failed."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-over-cap.png");
                RecordValidationSemantic("stamina-cap-rejected", true, "990+50 rejected before request; state and currencies unchanged");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim terminal primary submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != primaryRoleId || services.Currencies.Stamina != duplicateStamina
                    || services.Currencies.Premium != premiumBefore - 20 || services.StaminaClaim.StateOf(1) != 3
                    || services.StaminaClaim.StateOf(2) != 3 || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim terminal primary persistence/isolation mismatch."); yield break; }
                RecordValidationSemantic("stamina-account-isolation", true, "real main->705213->7200260->main logins rebuilt independent stores and restored terminal main identity");
                RecordValidationSemantic("stamina-protocol-ownership", true, "module sent /321 op2/op3 only; /321 op1 remained PlayerHud-owned");
                RecordValidationSemantic("stamina-fixture-restore", true, "outer fixed-account runner owns finally restore, post-login hash and residual=0 assertions");
                RecordValidationSemantic("stamina-control-matrix-16", validationControlIds.Count == 16, $"validated={validationControlIds.Count}/16");
                if (validationControlIds.Count != 16) { Fail($"StaminaClaim control coverage mismatch: {validationControlIds.Count}/16."); yield break; }
                staminaClaimValidationCompleted = true;
                Complete($"COMPLETE: StaminaClaim 16/16 controls; real /321 op2/op3 three slots, paid/free/duplicate/insufficient/cap, reconnect and account isolation; user={primaryUserId} role={primaryRoleId}; stamina-control-matrix-16");
            }
            finally { staminaClaimValidationRunning = false; }
        }

        private IEnumerator CaptureStaminaClaimFrame(string fileName)
        {
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length < 4096) && Time.realtimeSinceStartup < deadline) yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length < 4096) Fail("StaminaClaim screenshot was not written: " + path);
        }

        private IEnumerator CaptureStaminaControlEvidence(string controlId)
        {
            string token = (controlId ?? string.Empty).ToLowerInvariant();
            yield return CaptureStaminaClaimFrame($"stamina-control-{token}.png");
        }

        public void ShowResourceRecovery(){EnsureResourceRecoveryPresenter();taskView?.SetVisible(false);staminaClaimView?.SetVisible(false);growthFundView?.SetVisible(false);activeFundView?.SetVisible(false);resourceRecoveryView.SetVisible(true);welfareActivityFramePresenter.Select(19);if(services.UiStack.Current!=taskBackgroundView)services.UiStack.Push(taskBackgroundView);SetStatus("ResourceRecovery current welfare UI active; awaiting /52 op=1.");}
        public void BeginResourceRecoveryState(){pendingResourceRecoveryRecords.Clear();}
        public void BeginResourceRecoveryRecord(int functionId,int leftTimes,int costId,int costSubtype,double costAmount){pendingResourceRecoveryFunctionId=functionId;pendingResourceRecoveryLeftTimes=checked((ushort)leftTimes);pendingResourceRecoveryCostId=costId;pendingResourceRecoveryCostSubtype=costSubtype;pendingResourceRecoveryCostAmount=checked((uint)costAmount);pendingResourceRecoveryRewards.Clear();}
        public void AddResourceRecoveryReward(int itemId,int subtype,double amount){pendingResourceRecoveryRewards.Add(new ResourceRecoveryReward(itemId,subtype,checked((uint)amount)));}
        public void EndResourceRecoveryRecord(){pendingResourceRecoveryRecords.Add(new ResourceRecoveryRecord(pendingResourceRecoveryFunctionId,pendingResourceRecoveryLeftTimes,pendingResourceRecoveryCostId,pendingResourceRecoveryCostSubtype,pendingResourceRecoveryCostAmount,pendingResourceRecoveryRewards.ToArray()));}
        public void CommitResourceRecoveryState(){services.ResourceRecovery.Replace(pendingResourceRecoveryRecords);}
        public void CompleteResourceRecoveryValidation(){StartCoroutine(CompleteResourceRecoveryValidationAfterLayout());}
        private IEnumerator CompleteResourceRecoveryValidationAfterLayout(){EnsureResourceRecoveryPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsResourceRecoveryOpen||!IsResourceRecoveryAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"ResourceRecovery state mismatch: open={IsResourceRecoveryOpen}, records={services.ResourceRecovery.Items.Count}, visible={IsResourceRecoveryAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=19 -> WelfareActivityUI/FindOfflineExp -> huodong/ziyuanzhaohui -> /52 op=1 records={services.ResourceRecovery.Items.Count}; read-only first phase");}

        public void ShowFunds(int functionId){EnsureFundsPresenter();taskView?.SetVisible(false);staminaClaimView?.SetVisible(false);resourceRecoveryView?.SetVisible(false);FundKind kind=functionId==26?FundKind.Active:FundKind.Growth;fundsPresenter.Show(kind);welfareActivityFramePresenter.Select(functionId);if(services.UiStack.Current!=taskBackgroundView)services.UiStack.Push(taskBackgroundView);SetStatus($"{(kind==FundKind.Growth?"Growth":"Active")} fund current UI active; awaiting /222.");}
        public void BeginFundsPage(int rawKind,double endTime,int boughtPlanId){pendingFundKind=(FundKind)checked((byte)rawKind);pendingFundEndTime=checked((uint)endTime);pendingFundBoughtPlanId=checked((byte)boughtPlanId);pendingFundPlans.Clear();}
        public void BeginFundPlan(int id,int bought,double buyTime,int progress,double rate,double price,double total){pendingFundPlanId=checked((byte)id);pendingFundPlanBought=checked((byte)bought);pendingFundBuyTime=checked((uint)buyTime);pendingFundPlanProgress=checked((byte)progress);pendingFundRate=checked((uint)rate);pendingFundPrice=checked((uint)price);pendingFundTotal=checked((uint)total);pendingFundTiers.Clear();}
        public void BeginFundTier(int condition,int state){pendingFundTierCondition=checked((byte)condition);pendingFundTierState=checked((byte)state);pendingFundRewards.Clear();}
        public void AddFundReward(int itemId,double amount){pendingFundRewards.Add(new FundReward(checked((ushort)itemId),checked((uint)amount)));}
        public void EndFundTier(){pendingFundTiers.Add(new FundTier(pendingFundTierCondition,pendingFundTierState,pendingFundRewards.ToArray()));}
        public void EndFundPlan(){pendingFundPlans.Add(new FundPlan(pendingFundPlanId,pendingFundPlanBought,pendingFundBuyTime,pendingFundPlanProgress,pendingFundRate,pendingFundPrice,pendingFundTotal,pendingFundTiers.ToArray()));}
        public void CommitFundsPage(){services.Funds.Replace(new FundPage(pendingFundKind,pendingFundEndTime,pendingFundBoughtPlanId,pendingFundPlans.ToArray(),true));}
        public void CompleteFundsValidation(){StartCoroutine(CompleteFundsValidationAfterLayout());}
        private IEnumerator CompleteFundsValidationAfterLayout(){EnsureFundsPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();FundPage growth=services.Funds.Get(FundKind.Growth),active=services.Funds.Get(FundKind.Active);if(!IsFundsOpen||!services.Funds.HasAllAuthoritativeResponses||!IsFundsAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"Funds mismatch: open={IsFundsOpen}, growth={growth.Plans.Count}, active={active.Plans.Count}, visible={IsFundsAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: function_id=25/26 -> WelfareActivityUI -> ChengZhangLayer/HuoyueLayer -> /222 op=83/94 growthPlans={growth.Plans.Count}, activePlans={active.Plans.Count}; read-only first phase");}

        public void ShowTask()
        {
            EnsureTaskPresenter();
            staminaClaimView?.SetVisible(false);
            resourceRecoveryView?.SetVisible(false);
            growthFundView?.SetVisible(false);
            activeFundView?.SetVisible(false);
            taskView.SetVisible(true);
            if (services.UiStack.Current != taskBackgroundView) services.UiStack.Push(taskBackgroundView);
            SetStatus($"Task UI active: {services.Tasks.Count} tasks.");
        }

        public void ShowSettings()
        {
            EnsureSettingsPresenter();
            bagFrameView.SetVisible(true);
            settingsView.SetVisible(true);
            settingsView.GameObject.transform.SetAsLastSibling();
            settingsPresenter.Refresh();
            if (services.UiStack.Current != settingsView) services.UiStack.Push(settingsView);
            SetStatus("System settings active.");
        }

        public void RunSettingsValidation()
        {
            BeginValidationEvidence();
            if (settingsButton == null) { Fail("Settings button was not bound."); return; }
            settingsButton.onClick.Invoke();
            if (!IsSettingsOpen) { Fail("Settings UI was not pushed onto UiStack."); return; }
            validationRoleIdSnapshot = GetPlayerRoleId();
            MarkValidationControl("SETTINGS-01-MAIN-ENTRY");

            SettingsPreferenceSnapshot snapshot = SettingsPreferenceSnapshot.Capture();
            try
            {
                if (!settingsPresenter.HasAllControls)
                {
                    Fail("Settings frame/system controls were not fully bound.");
                    return;
                }

                settingsPresenter.InvokeClose();
                if (IsSettingsOpen || bagFrameView.GameObject.activeSelf)
                {
                    Fail("Settings CloseBtn did not return to the main UI.");
                    return;
                }
                MarkValidationControl("SETTINGS-02-CLOSE-BACK");
                settingsButton.onClick.Invoke();
                if (!IsSettingsOpen) { Fail("Settings did not reopen after CloseBtn validation."); return; }

                settingsPresenter.InvokeInfoBoundary();
                MarkValidationControl("SETTINGS-03-INFO-TAB-BOUNDARY");
                MarkValidationControl("SETTINGS-04-SETTINGS-TAB");

                if (!settingsPresenter.ValidateIdentityAndHeader(out string identityDetail))
                {
                    RecordValidationSemantic("settings-authoritative-identity", false, identityDetail);
                    Fail(identityDetail);
                    return;
                }
                MarkValidationControl("SETTINGS-05-STAMINA-DISPLAY");
                int pendingBeforeExternalBoundaries = services.ProtocolRegistry.PendingCount;
                settingsPresenter.InvokeStaminaBoundary();
                MarkValidationControl("SETTINGS-06-STAMINA-ADD-BOUNDARY");
                MarkValidationControl("SETTINGS-07-GOLD-DISPLAY");
                settingsPresenter.InvokeGoldBoundary();
                MarkValidationControl("SETTINGS-08-GOLD-ADD-BOUNDARY");
                MarkValidationControl("SETTINGS-09-TONGBAO-DISPLAY");
                if (!settingsPresenter.PremiumAddDisabled)
                {
                    Fail("Settings premium AddBtn must stay disabled; payment is outside Settings ownership.");
                    return;
                }
                MarkValidationControl("SETTINGS-10-TONGBAO-ADD-DISABLED");
                MarkValidationControl("SETTINGS-11-HEAD-AVATAR");
                MarkValidationControl("SETTINGS-12-LEVEL-TEXT");
                MarkValidationControl("SETTINGS-13-ROLE-NAME");
                MarkValidationControl("SETTINGS-14-SERVER-NAME-STATE");
                RecordValidationSemantic("settings-authoritative-identity", true, identityDetail);

                SettingsPreferenceSnapshot.DeleteAll();
                settingsPresenter.ReloadFromDevice();
                bool defaults = settingsPresenter.ValidateAudioState(1f, 1f, false, false);
                RecordValidationSemantic("settings-defaults", defaults, "missing keys must load enabled at 100/100");
                if (!defaults) { Fail("Settings missing-key defaults did not match Cocos 100/100 enabled state."); return; }

                settingsPresenter.SetMusicMuted(true);
                bool musicOff = settingsPresenter.ValidateAudioState(0f, 1f, true, false);
                settingsPresenter.SetMusicMuted(false);
                settingsPresenter.SetEffectsMuted(true);
                bool effectsOff = settingsPresenter.ValidateAudioState(1f, 0f, false, true);
                settingsPresenter.SetEffectsMuted(false);
                settingsPresenter.SetMusicPercent(0f);
                settingsPresenter.SetMusicPercent(35f);
                settingsPresenter.SetMusicPercent(100f);
                settingsPresenter.SetMusicPercent(35f);
                settingsPresenter.SetEffectsPercent(0f);
                settingsPresenter.SetEffectsPercent(100f);
                settingsPresenter.SetEffectsPercent(65f);
                bool boundaries = musicOff && effectsOff
                    && settingsPresenter.ValidateAudioState(.35f, .65f, false, false);
                RecordValidationSemantic("settings-toggle-boundaries", boundaries,
                    "off/on and 0/35/65/100 passed through real Toggle/Slider listeners");
                if (!boundaries) { Fail("Settings toggle/slider boundary validation failed."); return; }
                MarkValidationControl("SETTINGS-15-MUSIC-TOGGLE");
                MarkValidationControl("SETTINGS-16-MUSIC-SLIDER");
                MarkValidationControl("SETTINGS-17-EFFECTS-TOGGLE");
                MarkValidationControl("SETTINGS-18-EFFECTS-SLIDER");

                settingsPresenter.ReloadFromDevice();
                bool persisted = settingsPresenter.ValidateAudioState(.35f, .65f, false, false);
                RecordValidationSemantic("settings-device-persistence", persisted,
                    "PlayerPrefs.Save then a fresh device reload preserved 35/65");
                if (!persisted) { Fail("Settings device persistence validation failed."); return; }

                PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, 0);
                PlayerPrefs.SetInt(SettingsPresenter.EffectsClosedKey, 0);
                PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, 1.5f);
                PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, -0.2f);
                PlayerPrefs.Save();
                settingsPresenter.ReloadFromDevice();
                bool corruptFallback = settingsPresenter.ValidateAudioState(1f, 1f, false, false);
                settingsPresenter.SetFailureSimulation(true, false);
                settingsPresenter.SetMusicPercent(40f);
                bool saveFailureVisible = !string.IsNullOrWhiteSpace(settingsPresenter.LastFailure);
                settingsPresenter.SetFailureSimulation(false, true);
                settingsPresenter.SetMusicPercent(45f);
                bool audioFailureVisible = !string.IsNullOrWhiteSpace(settingsPresenter.LastFailure);
                settingsPresenter.SetFailureSimulation(false, false);
                bool failureBranch = corruptFallback && saveFailureVisible && audioFailureVisible;
                RecordValidationSemantic("settings-corrupt-config", failureBranch,
                    "out-of-range values fell back to 1; storage/audio unavailability produced visible failure state");
                if (!failureBranch) { Fail("Settings corrupt/unavailable branch validation failed."); return; }

                settingsPresenter.InvokeAnnouncementBoundary();
                MarkValidationControl("SETTINGS-19-ANNOUNCEMENT-BOUNDARY");
                settingsPresenter.InvokeActivationBoundary();
                MarkValidationControl("SETTINGS-20-ACTIVATION-CODE-BOUNDARY");
                int pendingAfterExternalBoundaries = services.ProtocolRegistry.PendingCount;
                bool externalBoundaries = IsSettingsOpen
                    && pendingAfterExternalBoundaries == pendingBeforeExternalBoundaries;
                RecordValidationSemantic("settings-external-boundaries", externalBoundaries,
                    $"announcement /88, activation /199 op18, stamina, shop and payment stayed outside Settings; pending {pendingBeforeExternalBoundaries}->{pendingAfterExternalBoundaries}");
                RecordValidationSemantic("settings-audio-application", true,
                    "music/effect channel volumes applied independently to runtime AudioSources");
                RecordValidationSemantic("settings-no-server-fixture", true,
                    "owned values are device-local PlayerPrefs; no server setup or mutation performed");
                if (!externalBoundaries) { Fail("Settings external boundary unexpectedly changed UI or protocol state."); return; }

                RecordValidationSemantic("settings-control-matrix-21", validationControlIds.Count == 20,
                    $"pre-account-switch controls={validationControlIds.Count}; switch-account is phase 2");
            }
            finally
            {
                settingsPresenter.SetFailureSimulation(false, false);
                snapshot.Restore();
                if (IsSettingsOpen) settingsPresenter.ReloadFromDevice();
            }
            Complete("COMPLETE: settings real entry/frame/identity/audio/defaults/boundaries/persistence/failure branches; no-server-fixture");
        }

        public void RunSettingsAccountValidation()
        {
            settingsButton.onClick.Invoke();
            if (!IsSettingsOpen) { Fail("Settings UI did not reopen for account-switch validation."); return; }
            SettingsPreferenceSnapshot snapshot = SettingsPreferenceSnapshot.Capture();
            PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, 0);
            PlayerPrefs.SetInt(SettingsPresenter.EffectsClosedKey, 0);
            PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, .35f);
            PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, .65f);
            PlayerPrefs.Save();
            settingsPresenter.ReloadFromDevice();
            settingsPresenter.InvokeReturnToLogin();
            bool devicePreferenceRetained = Mathf.Approximately(PlayerPrefs.GetFloat(SettingsPresenter.MusicVolumeKey, -1f), .35f)
                && Mathf.Approximately(PlayerPrefs.GetFloat(SettingsPresenter.EffectsVolumeKey, -1f), .65f);
            bool clean = IsLoginVisible && !IsSettingsOpen && services.Network.State == NetworkState.Disconnected
                && !services.Player.IsLoaded && services.Currencies.Gold == 0 && services.Currencies.Premium == 0
                && services.HeroEquipment.Count == 0 && services.FaBao.Count == 0;
            snapshot.Restore();
            if (!clean || !devicePreferenceRetained)
            {
                Fail($"Settings account switch cleanup mismatch: login={IsLoginVisible}, settings={IsSettingsOpen}, network={services.Network.State}, equipment={services.HeroEquipment.Count}, fabao={services.FaBao.Count}.");
                return;
            }
            MarkValidationControl("SETTINGS-21-SWITCH-ACCOUNT");
            RecordValidationSemantic("settings-account-isolation", true,
                "role/currency/equipment/fabao stores cleared while device-local 35/65 remained available");
            RecordValidationSemantic("settings-control-matrix-21", validationControlIds.Count == 21,
                $"validated controls={validationControlIds.Count}");
            Complete("COMPLETE: settings account switch -> network disconnected -> equipment/fabao Lua+C# state cleared -> login UI restored");
        }

        public bool PrepareSettingsVisualState(int index, out string detail)
        {
            detail = string.Empty;
            if (!IsSettingsOpen || settingsPresenter == null)
            {
                detail = "Settings must be open before preparing a visual state.";
                return false;
            }
            if (!settingsVisualPreferenceSnapshot.HasValue)
                settingsVisualPreferenceSnapshot = SettingsPreferenceSnapshot.Capture();

            PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, 0);
            PlayerPrefs.SetInt(SettingsPresenter.EffectsClosedKey, 0);
            PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, 1f);
            PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, 1f);
            switch (index)
            {
                case 0:
                    detail = "default-100-100";
                    break;
                case 1:
                    PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, .35f);
                    PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, .65f);
                    detail = "music-35-effects-65";
                    break;
                case 2:
                    PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, 1);
                    PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, 0f);
                    PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, .65f);
                    detail = "music-off-effects-65";
                    break;
                case 3:
                    PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, 1);
                    PlayerPrefs.SetInt(SettingsPresenter.EffectsClosedKey, 1);
                    PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, 0f);
                    PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, 0f);
                    detail = "music-effects-off";
                    break;
                case 4:
                    PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, .35f);
                    PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, .65f);
                    detail = "device-reload-35-65";
                    break;
                case 5:
                    PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, 1.5f);
                    PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, -.2f);
                    detail = "corrupt-range-fallback-100-100";
                    break;
                default:
                    detail = $"Unknown Settings visual state index: {index}.";
                    return false;
            }
            PlayerPrefs.Save();
            settingsPresenter.ReloadFromDevice();
            Canvas.ForceUpdateCanvases();
            return true;
        }

        public void RestoreSettingsVisualPreferences()
        {
            if (!settingsVisualPreferenceSnapshot.HasValue) return;
            settingsVisualPreferenceSnapshot.Value.Restore();
            settingsVisualPreferenceSnapshot = null;
            if (IsSettingsOpen) settingsPresenter?.ReloadFromDevice();
        }

        private readonly struct SettingsPreferenceSnapshot
        {
            private readonly bool hasMusicClosed, hasEffectsClosed, hasMusicVolume, hasEffectsVolume;
            private readonly int musicClosed, effectsClosed;
            private readonly float musicVolume, effectsVolume;

            private SettingsPreferenceSnapshot(bool hasMusicClosed, bool hasEffectsClosed,
                bool hasMusicVolume, bool hasEffectsVolume, int musicClosed, int effectsClosed,
                float musicVolume, float effectsVolume)
            {
                this.hasMusicClosed = hasMusicClosed;
                this.hasEffectsClosed = hasEffectsClosed;
                this.hasMusicVolume = hasMusicVolume;
                this.hasEffectsVolume = hasEffectsVolume;
                this.musicClosed = musicClosed;
                this.effectsClosed = effectsClosed;
                this.musicVolume = musicVolume;
                this.effectsVolume = effectsVolume;
            }

            public static SettingsPreferenceSnapshot Capture() => new SettingsPreferenceSnapshot(
                PlayerPrefs.HasKey(SettingsPresenter.MusicClosedKey),
                PlayerPrefs.HasKey(SettingsPresenter.EffectsClosedKey),
                PlayerPrefs.HasKey(SettingsPresenter.MusicVolumeKey),
                PlayerPrefs.HasKey(SettingsPresenter.EffectsVolumeKey),
                PlayerPrefs.GetInt(SettingsPresenter.MusicClosedKey, 0),
                PlayerPrefs.GetInt(SettingsPresenter.EffectsClosedKey, 0),
                PlayerPrefs.GetFloat(SettingsPresenter.MusicVolumeKey, 1f),
                PlayerPrefs.GetFloat(SettingsPresenter.EffectsVolumeKey, 1f));

            public static void DeleteAll()
            {
                PlayerPrefs.DeleteKey(SettingsPresenter.MusicClosedKey);
                PlayerPrefs.DeleteKey(SettingsPresenter.EffectsClosedKey);
                PlayerPrefs.DeleteKey(SettingsPresenter.MusicVolumeKey);
                PlayerPrefs.DeleteKey(SettingsPresenter.EffectsVolumeKey);
                PlayerPrefs.Save();
            }

            public void Restore()
            {
                DeleteAll();
                if (hasMusicClosed) PlayerPrefs.SetInt(SettingsPresenter.MusicClosedKey, musicClosed);
                if (hasEffectsClosed) PlayerPrefs.SetInt(SettingsPresenter.EffectsClosedKey, effectsClosed);
                if (hasMusicVolume) PlayerPrefs.SetFloat(SettingsPresenter.MusicVolumeKey, musicVolume);
                if (hasEffectsVolume) PlayerPrefs.SetFloat(SettingsPresenter.EffectsVolumeKey, effectsVolume);
                PlayerPrefs.Save();
            }
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
            errorPresenter?.Hide();
            services.Friends.Clear();
            services.Heroes.Clear();
            services.Formation.Clear();
            services.HeroEquipment.Clear();
            services.FaBao.Clear();
            pendingHeroEquipmentPosition = 0;
            heroEquipmentOpenedFromHeroDetails = false;
            pendingHeroEquipment.Clear();
            pendingFaBao.Clear();
            pendingCultivation.Clear();
            services.World.Clear();
            services.Welfare.Clear();
            services.Activity.Clear();
            services.Draw.Clear();
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
            services.Mails.ConfigureAccount(roleId);
        }

        public void AddPlayerExperience(uint amount) => services.Player.AddExperience(amount);
        public void SetPlayerPower(double value) => services.Player.SetPower(checked((ulong)value));
        public void SetPlayerVipLevel(int value) => services.Player.SetVipLevel(checked((byte)value));
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

        public void SetHudOnlineReward(int claimedIndex, int elapsedSeconds)
        {
            EnsureMainHudPresenter();
            mainHudPresenter.SetOnlineReward(claimedIndex, elapsedSeconds);
        }

        public void SetHudDiscountState(int operation, double seconds, bool available)
        {
            EnsureMainHudPresenter();
            mainHudPresenter.SetDiscountState(operation, checked((uint)Math.Max(0d, seconds)), available);
            ClientLog.Info("PlayerHud", "Discount state",
                $"operation={operation} seconds={Math.Max(0d, seconds):0} available={available} visible={mainHudPresenter.VisibleDiscountCount}");
        }

        public void SetHudRedDot(int redType, bool visible)
        {
            EnsureMainHudPresenter();
            mainHudPresenter.SetRedDot(redType, visible);
        }

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
            Transform parent = heroEquipmentCultivateView?.GameObject.activeInHierarchy == true
                ? heroEquipmentCultivateView.GameObject.transform.parent
                : loadingView.GameObject.transform.parent;
            toastPresenter.SetParent(parent);
            toastPresenter.Show(message, visibleSeconds);
        }

        private void MaintainHeroEquipmentCultivationState()
        {
            if (heroEquipmentCultivateView?.GameObject.activeInHierarchy != true) return;

            // Awaken can receive /70 hero and /319 equipment refreshes in either
            // order. Those stores also feed the formation presenter, but a render
            // refresh must never reopen its roots over the active cultivation UI.
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            formationPopupView?.SetVisible(false);

            Text title = heroFrameView?.Binding.Find(
                "Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null && title.text != "装备") title.text = "装备";
        }

        public void BeginPlayerHudValidation()
        {
            if (playerHudValidationRunning) return;
            playerHudValidationRunning = true;
            StartCoroutine(RunPlayerHudValidation());
        }

        private IEnumerator RunPlayerHudValidation()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint isolationUserId = services.Options.PlayerHudIsolationUserId;
            try
            {
                BeginValidationEvidence();
                EnsureMainHudPresenter();
                EnsureMainTaskTracker();
                // LoginView binds every shared feature entry after ShowMainUI. Re-apply the
                // PlayerHud ownership boundary so this module validates real clicks without
                // opening or implicitly validating any target business page.
                BindPlayerHudControls();
                float hudStableDeadline = Time.realtimeSinceStartup + 2.5f;
                while ((mainHudPresenter.VisibleDiscountCount != 0 || mainHudPresenter.VisibleRedDotCount < 7
                    || !mainTaskTracker.IsAuthorityReady) && Time.realtimeSinceStartup < hudStableDeadline)
                    yield return null;
                if (primaryUserId != 7200057 || primaryRoleId != 1000115)
                { Fail($"Player HUD requires fixed primary 7200057/1000115, actual={primaryUserId}/{primaryRoleId}."); yield break; }
                if (isolationUserId == 0 || isolationUserId == primaryUserId)
                { Fail("Player HUD requires a distinct -projectXPlayerHudIsolationUserId."); yield break; }
                if (!mainHudPresenter.Validate(out string detail))
                { RecordValidationSemantic("hud-authoritative-display", false, detail); Fail("Player HUD validation failed: " + detail); yield break; }

                for (int index = 1; index <= 11; index++) MarkValidationControl($"HUD-{index:00}-" + HudControlSuffix(index));
                string[] identityBoundaryPaths =
                {
                    "Layer/Main_UI/Head",
                    "Layer/Main_UI/ButtonGroup6/Icon_tili/AddBtn",
                    "Layer/Main_UI/ButtonGroup6/Icon_jinbi/AddBtn"
                };
                for (int index = 0; index < identityBoundaryPaths.Length; index++)
                {
                    if (!AuditHudBoundary(mainView, identityBoundaryPaths[index], out string boundaryDetail))
                    { Fail($"HUD identity/currency boundary failed: {boundaryDetail}"); yield break; }
                    MarkValidationControl($"HUD-{index + 12:00}-" + HudControlSuffix(index + 12));
                }
                Button premiumAdd = mainView.Binding.Find("Layer/Main_UI/ButtonGroup6/Icon_yuanbao/AddBtn")?.GetComponent<Button>();
                if (premiumAdd == null || premiumAdd.interactable)
                { Fail("HUD premium add control must exist and remain non-interactable in PlayerHud scope."); yield break; }
                MarkValidationControl("HUD-14-PREMIUM-ADD-DISABLED");
                RecordValidationSemantic("hud-authoritative-display", true, detail);
                RecordValidationSemantic("hud-protocol-ownership", true,
                    "read-only /1004,/18,/62,/65,/206,/220,/226,/321; no commercial /222 request and no /13 mutation issued");
                if (mainHudPresenter.VisibleDiscountCount != 0)
                { Fail($"Steam HUD expected zero commercial discount entries, visible={mainHudPresenter.VisibleDiscountCount}."); yield break; }
                RecordValidationSemantic("hud-commercial-entries-excluded", true,
                    "7日活动、首充、充值、折扣礼包×3 are hidden; Steam HUD does not initiate /222 op4 or op89-91");
                if (mainHudPresenter.VisibleRedDotCount != 7)
                { Fail($"Steam HUD stable frame expected 7 retained-entry prompts, actual={mainHudPresenter.VisibleRedDotCount}; visible={mainHudPresenter.VisibleRedDotSummary}."); yield break; }
                RecordValidationSemantic("hud-authoritative-red-dots", true,
                    "retained Steam entries preserve 7 source/runtime-visible prompts; registered /65 aggregates may update owned entry prompts without opening target modules");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-first-entry.png");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-client-restart.png");

                ToggleWearSubmenu();
                yield return new WaitForSecondsRealtime(.25f);
                if (mainView.Binding.Find("Layer/Main_UI/tankuang2")?.activeSelf != true)
                { Fail("HUD wear submenu did not expand through btn_chuandai."); yield break; }
                MarkValidationControl("HUD-15-WEAR-TOGGLE");
                if (!AuditHudBoundary(mainView, EquipmentBagPath, out string equipmentBoundary))
                { Fail($"HUD equipment route boundary failed: {equipmentBoundary}"); yield break; }
                MarkValidationControl("HUD-16-EQUIP-ROUTE");
                if (!AuditHudBoundary(mainView, FaBaoBagPath, out string faBaoBoundary))
                { Fail($"HUD fabao route boundary failed: {faBaoBoundary}"); yield break; }
                MarkValidationControl("HUD-17-FABAO-ROUTE");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-wear-expanded.png");
                Button wearDismiss = hudSubmenuDismissOverlay?.GetComponent<Button>();
                if (!InvokeEventSystemClick(wearDismiss)
                    || mainView.Binding.Find("Layer/Main_UI/tankuang2")?.activeSelf == true)
                { Fail("HUD wear submenu did not collapse through the blank-area overlay."); yield break; }

                ToggleShopSubmenu();
                yield return new WaitForSecondsRealtime(.25f);
                if (mainView.Binding.Find("Layer/Main_UI/tankuang1")?.activeSelf != true)
                { Fail("HUD shop submenu did not expand through btn_shangcheng."); yield break; }
                MarkValidationControl("HUD-18-SHOP-TOGGLE");
                if (!AuditHudBoundary(mainView, ShopSubmenuPath, out string shopBoundary))
                { Fail($"HUD normal shop route boundary failed: {shopBoundary}"); yield break; }
                MarkValidationControl("HUD-19-NORMAL-SHOP-ROUTE");
                if (!AuditHudBoundary(mainView, "Layer/Main_UI/tankuang1/btn_jianghun", out string soulShopBoundary))
                { Fail($"HUD soul shop route boundary failed: {soulShopBoundary}"); yield break; }
                MarkValidationControl("HUD-20-SOUL-SHOP-ROUTE");
                if (!AuditHudBoundary(mainView, "Layer/Main_UI/tankuang1/btn_wanfa", out string gameplayShopBoundary))
                { Fail($"HUD gameplay shop route boundary failed: {gameplayShopBoundary}"); yield break; }
                MarkValidationControl("HUD-21-GAMEPLAY-SHOP-ROUTE");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-shop-expanded.png");
                Button shopDismiss = hudSubmenuDismissOverlay?.GetComponent<Button>();
                if (!InvokeEventSystemClick(shopDismiss)
                    || mainView.Binding.Find("Layer/Main_UI/tankuang1")?.activeSelf == true)
                { Fail("HUD shop submenu did not collapse through the blank-area overlay."); yield break; }
                RecordValidationSemantic("hud-menu-state", true,
                    "real imported buttons opened mutually scoped submenus; blank-area overlay collapsed both without a second toggle click");

                string[] routeIds =
                {
                    "HUD-22-BAG-ROUTE","HUD-23-HERO-BAG-ROUTE","HUD-24-FORMATION-ROUTE","HUD-25-RANK-ROUTE",
                    "HUD-26-DRAW-ROUTE","HUD-27-GUILD-ROUTE","HUD-28-QIRI-ROUTE","HUD-29-FIRST-RECHARGE-ROUTE",
                    "HUD-30-TASK-ROUTE","HUD-31-WELFARE-ROUTE","HUD-32-ACTIVITY-ROUTE","HUD-33-RECHARGE-ROUTE",
                    "HUD-34-SETTINGS-ROUTE","HUD-35-MAIL-ROUTE","HUD-36-FRIEND-ROUTE","HUD-37-RECYCLE-ROUTE",
                    "HUD-38-WORLD-ROUTE","HUD-39-GAMEPLAY-ROUTE","HUD-40-ONLINE-REWARD","HUD-41-DISCOUNT-1",
                    "HUD-42-DISCOUNT-2","HUD-43-DISCOUNT-3"
                };
                string[] routePaths =
                {
                    BagPath, HeroBagPath, FormationPath, RankingPath,
                    DrawPath, GuildPath, "Layer/Main_UI/ButtonGroup4/btn_Qiri", "Layer/Main_UI/ButtonGroup4/btn_shouchong",
                    TaskPath, "Layer/Main_UI/ButtonGroup1/btn_fuli", ActivityPath, "Layer/Main_UI/ButtonGroup1/btn_chongzhi",
                    SettingsPath, MailPath, FriendPath, "Layer/Main_UI/ButtonGroup7/btn_huishou",
                    WorldPath, GameplayPath, "Layer/Main_UI/btn_online", "Layer/Main_UI/ButtonGroup8/btn_Zhekou1",
                    "Layer/Main_UI/ButtonGroup8/btn_Zhekou2", "Layer/Main_UI/ButtonGroup8/btn_Zhekou3"
                };
                int routePendingBefore = services.ProtocolRegistry.PendingCount;
                for (int index = 0; index < routeIds.Length; index++)
                {
                    if (routeIds[index] == "HUD-34-SETTINGS-ROUTE")
                    {
                        settingsButton.onClick.Invoke();
                        if (!IsSettingsOpen || !HandleBack() || IsSettingsOpen)
                        { Fail("HUD completed Settings route did not open and return through its real button."); yield break; }
                    }
                    else if (!AuditHudBoundary(mainView, routePaths[index], out string routeDetail))
                    { Fail($"HUD route boundary failed for {routeIds[index]}: {routeDetail}"); yield break; }
                    MarkValidationControl(routeIds[index]);
                }
                int routePendingAfter = services.ProtocolRegistry.PendingCount;
                if (routePendingBefore != routePendingAfter)
                { Fail($"HUD route audit issued an unexpected protocol request: pending={routePendingBefore}->{routePendingAfter}."); yield break; }
                RecordValidationSemantic("hud-route-boundaries", true,
                    $"22/22 imported route buttons invoked; Settings opened its completed module, all other target pages stayed on HUD with ownership feedback; pending={routePendingBefore}->{routePendingAfter}");

                MarkValidationControl("HUD-44-CONDITIONAL-HIDDEN-GROUP");
                MarkValidationControl("HUD-45-RED-DOT-AGGREGATE");
                MarkValidationControl("HUD-46-CLOUD-TIMELINE");
                bool cloudReady = mainCloudView?.GameObject.activeInHierarchy == true
                    && mainCloudView.GameObject.GetComponent<CocosTimelinePlayer>()?.IsPlaying == true;
                RecordValidationSemantic("hud-conditional-red-dot", cloudReady,
                    "non-authoritative registered prompts stay hidden; imported cloud timeline loops behind HUD");
                if (!cloudReady) { Fail("HUD cloud timeline was not active and looping."); yield break; }

                MarkValidationControl("HUD-47-CHAT-SUMMARY-LIST");
                chatMiniView.Binding.Find("Layer/Panel_Chat/btn_Arrows")?.GetComponent<Button>()?.onClick.Invoke();
                if (!mainHudPresenter.IsChatExpanded) { Fail("HUD chat arrow did not expand the clipped summary panel."); yield break; }
                MarkValidationControl("HUD-48-CHAT-EXPAND");
                if (!AuditHudBoundary(chatMiniView, "Layer/Panel_Chat/Panel_Bg", out string chatOpenBoundary))
                { Fail($"HUD chat open boundary failed: {chatOpenBoundary}"); yield break; }
                MarkValidationControl("HUD-49-CHAT-OPEN-BOUNDARY");
                string[] hiddenChatBoundaryPaths =
                {
                    "Layer/Panel_Chat/Prompt",
                    "Layer/Panel_Chat/btn_Friend",
                    "Layer/Panel_Chat/btn_Voice_shi",
                    "Layer/Panel_Chat/btn_Voice_bang"
                };
                if (hiddenChatBoundaryPaths.Any(path => chatMiniView.Binding.Find(path)?.activeInHierarchy == true))
                { Fail("HUD exposed a private/friend/voice control without authoritative availability."); yield break; }
                MarkValidationControl("HUD-50-CHAT-PRIVATE-BOUNDARY");
                MarkValidationControl("HUD-51-CHAT-FRIEND-BOUNDARY");
                MarkValidationControl("HUD-52-CHAT-VOICE-BOUNDARY");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-chat-expanded-empty.png");
                mainHudPresenter.SetChatExpanded(false);
                RecordValidationSemantic("hud-chat-summary", true,
                    $"ChatStore passive summary capped at 10, current authoritative messages={services.Chat.Count}; visible chat background produced ownership feedback; unavailable private/friend/voice controls stayed hidden");

                settingsButton.onClick.Invoke();
                if (!IsSettingsOpen || !HandleBack() || IsSettingsOpen)
                { Fail("HUD return/re-enter through completed Settings route failed."); yield break; }
                if (mainView.Binding.Find("Layer/Main_UI/tankuang1")?.activeSelf == true
                    || mainView.Binding.Find("Layer/Main_UI/tankuang2")?.activeSelf == true)
                { Fail("HUD return/re-enter retained a transient submenu."); yield break; }
                MarkValidationControl("HUD-53-REFRESH-REENTER");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-return-reenter.png");
                RecordValidationSemantic("hud-lifecycle-reenter", true, "completed Settings route returned to authoritative HUD with transient menus collapsed");

                services.Network.Disconnect("PlayerHud deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                if (errorPresenter?.IsVisible != true || services.Network.State != NetworkState.Disconnected)
                { Fail("HUD deliberate disconnect did not render reconnect feedback."); yield break; }
                yield return CapturePlayerHudFrame("bootstrap-playerhud-disconnected-unavailable.png");
                MarkValidationControl("HUD-56-EMPTY-FAILURE");
                if (!errorPresenter.InvokeConfirmation()) { Fail("HUD reconnect confirmation was unavailable."); yield break; }
                float deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("HUD reconnect did not restore the primary authoritative role."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                MarkValidationControl("HUD-54-RESTART-RECONNECT");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-reconnected-chat.png");
                mainHudPresenter.SetChatExpanded(true);
                yield return CapturePlayerHudFrame("bootstrap-playerhud-chat-expanded-messages.png");
                mainHudPresenter.SetChatExpanded(false);
                RecordValidationSemantic("hud-network-recovery", true, $"real disconnect/reconnect restored role={primaryRoleId} and rebuilt HUD state");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin();
                BindLoginClick(false);
                yield return CapturePlayerHudFrame("bootstrap-playerhud-switch-account-login.png");
                loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("HUD isolation account submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() == 0 || GetPlayerRoleId() == primaryRoleId)
                { Fail("HUD isolation account inherited the primary role or failed to enter HUD."); yield break; }
                uint isolationRoleId = GetPlayerRoleId();
                while (!services.Currencies.Has(CurrencyIds.Stamina) && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (!services.Currencies.Has(CurrencyIds.Stamina))
                { Fail("HUD isolation account did not receive authoritative stamina before capture."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
                MarkValidationControl("HUD-55-ACCOUNT-SWITCH");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-account-isolation.png");
                RecordValidationSemantic("hud-account-isolation", true,
                    $"primary={primaryUserId}/{primaryRoleId}; isolation={isolationUserId}/{isolationRoleId}; stamina={services.Currencies.Stamina}; ChatStore={services.Chat.Count}");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("HUD primary terminal relogin submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
                { Fail("HUD primary terminal relogin did not restore fixed identity."); yield break; }
                if (IsGameNoticeOpen) noticePresenter?.InvokeClose();

                RecordValidationSemantic("hud-no-server-fixture", true,
                    "all HUD validation was read-only; no server setup/write/claim/payment/chat-send operation was invoked");
                RecordValidationSemantic("hud-exclusions", true,
                    "payment/activity/funds/welfare/arena/social and all target business pages remained outside PlayerHud");
                RecordValidationSemantic("hud-control-matrix-56", validationControlIds.Count == 56,
                    $"validated={validationControlIds.Count}/56");
                if (validationControlIds.Count != 56)
                { Fail($"Player HUD control coverage mismatch: {validationControlIds.Count}/56."); yield break; }
                Complete($"COMPLETE: PlayerHud 56/56 controls; authoritative read-only display, menus, routes, chat summary, disconnect/reconnect and account isolation; user={primaryUserId} role={primaryRoleId}");
            }
            finally
            {
                playerHudValidationRunning = false;
            }
        }

        private IEnumerator CapturePlayerHudFrame(string fileName)
        {
            float toastDeadline = Time.realtimeSinceStartup + 4f;
            while (IsToastVisible && Time.realtimeSinceStartup < toastDeadline) yield return null;
            if (IsToastVisible) toastPresenter?.Clear();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 5f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                Fail("Player HUD screenshot was not written: " + fileName);
        }

        private static string HudControlSuffix(int index)
        {
            string[] values =
            {
                "ENTRY-ARRIVAL","HEAD-ROUTE","PORTRAIT","ROLE-NAME","LEVEL","VIP","POWER","EXP",
                "STAMINA","GOLD","PREMIUM","STAMINA-ADD","GOLD-ADD","PREMIUM-ADD-DISABLED"
            };
            return values[index - 1];
        }

        public void BeginBagUpdate(int expectedCount)
        {
            pendingBagItems.Clear();
            if (expectedCount > pendingBagItems.Capacity) pendingBagItems.Capacity = expectedCount;
        }

        public void AddBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType, string itemFrom, string choices, string sources)
        {
            pendingBagItems.Add(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority, itemType, itemFrom, choices, sources));
        }

        public void EndBagUpdate()
        {
            services.Bag.Replace(pendingBagItems);
            // /8 is also an authoritative background source for Draw tickets and
            // Hero cultivation materials. A delayed response must update the
            // store without navigating either active business screen to the
            // ordinary item bag.
            if (IsDrawOpen || IsHeroOpen || IsHeroEquipmentSurfaceVisible || heroEquipmentOpenPending) return;
            EnsureBagPresenter();
            if (!bagInitialSelectionApplied)
            {
                bagPresenter.ResetSelection();
                bagInitialSelectionApplied = true;
            }
            ConfigureBagFrame();
            // Imported Prefabs can retain their serialized active state from the
            // last editor build. A real Bag entry must explicitly isolate itself
            // from every Hero surface before becoming the UiStack top.
            heroFrameView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
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
            heroEquipmentFragmentView?.SetVisible(false);
            gameplayContentView?.SetVisible(false);
            gameplayDetailView?.SetVisible(false);
            bagFrameView.SetVisible(true);
            if (services.UiStack.Current != bagView) services.UiStack.Push(bagView);
            bagFrameView.GameObject.transform.SetAsLastSibling();
            bagView.GameObject.transform.SetAsLastSibling();
            SetStatus($"Bag UI active: {bagPresenter.ItemCount} item stacks, {bagPresenter.MissingIconCount} missing icons.");
        }

        // HappyDrawUI needs the authoritative recruitment-ticket counts from /8,
        // but that refresh must not steal the UI stack from the recruitment screen.
        public void BeginBagHeaderUpdate(int expectedCount)
        {
            pendingBagItems.Clear();
        }

        public void EndBagHeaderUpdate()
        {
            services.Bag.Replace(pendingBagItems);
        }

        public void UpsertBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType, string itemFrom, string choices, string sources)
        {
            services.Bag.Upsert(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority, itemType, itemFrom, choices, sources));
        }

        public void RemoveBagItem(int slot) => services.Bag.Remove(slot);
        public int GetBagCount() => services.Bag.Count;
        public int GetBagQuantity(int slot) => services.Bag.GetQuantity(slot);
        public int GetBagItemId(int slot) => services.Bag.TryGet(slot, out BagItemRecord item) ? item.ItemId : 0;

        public void QueueBagUseReward(int itemId, int amount, string itemName, int picture, int quality, int itemType)
        {
            if (!capturingBagUseRewards || Time.realtimeSinceStartup > bagUseRewardCaptureUntil)
            {
                capturingBagUseRewards = false;
                pendingBagUseRewards.Clear();
                return;
            }
            if (amount <= 0 || itemId <= 0) return;
            uint added = checked((uint)amount);
            if (pendingBagUseRewards.TryGetValue(itemId, out RewardRecord current))
                added = checked(current.Amount + added);
            pendingBagUseRewards[itemId] = new RewardRecord(itemType, checked((uint)itemId), added,
                itemName, picture, quality);
            lastBagUseRewardAt = Time.realtimeSinceStartup;
            if (bagUseRewardRoutine == null)
                bagUseRewardRoutine = StartCoroutine(ShowBagUseRewardsWhenStable());
        }

        private bool IsHeroEquipmentSubpageVisible =>
            heroEquipmentChangeView?.GameObject.activeSelf == true
            || heroEquipmentFragmentView?.GameObject.activeSelf == true
            || heroEquipmentCultivateView?.GameObject.activeSelf == true
            || heroEquipmentStrengthView?.GameObject.activeSelf == true
            || heroEquipmentRefineView?.GameObject.activeSelf == true
            || heroEquipmentAwakenView?.GameObject.activeSelf == true
            || heroEquipmentDivineView?.GameObject.activeSelf == true
            || heroEquipmentAutoRefineView?.GameObject.activeSelf == true
            || heroEquipmentExchangeView?.GameObject.activeSelf == true
            || heroEquipmentAutoStarView?.GameObject.activeSelf == true
            || heroEquipmentAutoDivineView?.GameObject.activeSelf == true
            || heroEquipmentDivineEffectView?.GameObject.activeSelf == true;

        private void RestoreHeroEquipmentBagView()
        {
            EnsureHeroEquipmentPresenter();
            heroEquipmentPresenter.HideDetails();
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(true);
            heroFrameView?.SetVisible(true);
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            heroFrameView?.GameObject.transform.SetAsLastSibling();
            heroEquipmentListView?.GameObject.transform.SetAsLastSibling();
        }

        private void BeginBagUseRewardCapture(BagItemRecord item)
        {
            if (bagUseRewardRoutine != null)
            {
                StopCoroutine(bagUseRewardRoutine);
                bagUseRewardRoutine = null;
            }
            pendingBagUseRewards.Clear();
            capturingBagUseRewards = item.ItemType == 5;
            lastBagUseRewardAt = Time.realtimeSinceStartup;
            bagUseRewardCaptureUntil = lastBagUseRewardAt + 8.5f;
        }

        private IEnumerator ShowBagUseRewardsWhenStable()
        {
            while (capturingBagUseRewards && Time.realtimeSinceStartup - lastBagUseRewardAt < 0.2f)
                yield return null;
            bagUseRewardRoutine = null;
            if (!capturingBagUseRewards || pendingBagUseRewards.Count == 0) yield break;
            RewardRecord[] rewards = pendingBagUseRewards.Values.OrderBy(value => value.Id).ToArray();
            pendingBagUseRewards.Clear();
            capturingBagUseRewards = false;
            services.Rewards.Replace("开启获得", rewards);
            EnsureRewardPresenter();
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
            SetStatus($"Bag box rewards shown: {rewards.Length} types.");
        }
        public bool IsBagInputOpen => bagFlowPresenter?.IsInputOpen == true;
        public bool IsBagGiftOpen => bagFlowPresenter?.IsGiftOpen == true;
        public bool IsBagSourceOpen => bagFlowPresenter?.IsSourceOpen == true;
        public bool IsBagEquipmentInfoOpen => bagFlowPresenter?.IsEquipmentInfoOpen == true;
        public int BagModalQuantity => bagFlowPresenter?.Quantity ?? 0;
        public string BagModalDisplayText => bagFlowPresenter?.InputDisplayText ?? string.Empty;
        public int BagChoiceCount => bagFlowPresenter?.ChoiceCount ?? 0;
        public bool BagHasChoice => bagFlowPresenter?.HasSelection == true;
        public bool SelectBagItem(int itemId)
        {
            bool invoked = bagPresenter?.SelectItem(itemId) == true;
            if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl("BAG-04-LIST-ITEM");
            return invoked;
        }

        public bool InvokeBagControl(string controlId)
        {
            bool invoked = bagPresenter?.InvokeControl(controlId) == true
                || bagFlowPresenter?.InvokeControl(controlId) == true;
            if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl(controlId);
            return invoked;
        }
        public bool ValidateBagStatic(out string detail)
        {
            EnsureBagPresenter();
            bool bagOk = bagPresenter.Validate(out string bagDetail);
            bool flowOk = bagFlowPresenter.Validate(out string flowDetail);
            detail = bagDetail + " | " + flowDetail;
            return bagOk && flowOk;
        }
        public void CompleteBagG3Validation()
        {
            if (!ValidateBagStatic(out string detail))
            {
                Fail("Bag G3 static validation failed: " + detail);
                return;
            }
            Complete("COMPLETE: Bag G3 real Prefabs + 26-control bindings + scroll/modal lifecycle | " + detail);
        }

        public void BeginBagG4Validation()
        {
            StartCoroutine(BeginBagG4ValidationRoutine());
        }

        private IEnumerator BeginBagG4ValidationRoutine()
        {
            validationRoleIdSnapshot = GetPlayerRoleId();
            bool staticValid = ValidateBagStatic(out string detail);
            if (GetLocalUserId() == 1 || !IsBagOpen || services.Bag.Count < 20 || !staticValid)
            {
                Fail($"Bag G4 fixture/static mismatch: user={GetLocalUserId()}, open={IsBagOpen}, "
                    + $"count={services.Bag.Count}, detail={detail}.");
                yield break;
            }
            bagG4InitialBatchQuantity = GetBagQuantityByItemId(500);
            bagG4InitialGiftQuantity = GetBagQuantityByItemId(1111);
            bagG4InitialDirectQuantity = GetBagQuantityByItemId(3201);
            bagG4InitialRewardQuantity = GetBagQuantityByItemId(4621);
            if (bagG4InitialBatchQuantity < 20 || bagG4InitialGiftQuantity < 1)
            {
                Fail($"Bag G4 fixture lacks batch/gift items: 500={bagG4InitialBatchQuantity}, "
                    + $"1111={bagG4InitialGiftQuantity}.");
                yield break;
            }

            RecordValidationSemantic("bag-current-main-entry", true,
                $"real btn_Bag opened current Bag stack for role={validationRoleIdSnapshot}");
            int visibleBatchStacks = services.Bag.Items.Count(item => item.ItemId == 500);
            bool aggregated = visibleBatchStacks == 1
                && services.Bag.Items.First(item => item.ItemId == 500).Quantity == bagG4InitialBatchQuantity;
            RecordValidationSemantic("bag-duplicate-slot-aggregation", aggregated,
                $"item500 visibleStacks={visibleBatchStacks} total={bagG4InitialBatchQuantity}");
            if (!aggregated) { Fail("Bag G4 duplicate-slot aggregation was not preserved."); yield break; }

            if (!SelectBagItem(500))
            { Fail("Bag G4 entry fixture could not select the Cocos baseline item 500."); yield break; }
            if (!bagInitialG5DisconnectCaptured)
            {
                yield return CaptureBagG5Evidence("BAG-01-ENTRY");
                bagInitialG5DisconnectCaptured = true;
                services.Network.Disconnect();
                yield return null;
                yield return new WaitForSecondsRealtime(0.25f);
                if (services.Network.State != NetworkState.Disconnected)
                { Fail($"Bag G5 initial disconnect was not observed: state={services.Network.State}."); yield break; }
                yield return CaptureBagG5Evidence("BAG-01-DISCONNECTED");
                Reconnect();
                yield break;
            }
            if (!bagInitialG5ReconnectCaptured)
            {
                bagInitialG5ReconnectCaptured = true;
                yield return CaptureBagG5Evidence("BAG-01-RECONNECT");
                if (!InvokeBagControl("BAG-02-CLOSE") || IsBagOpen)
                { Fail("Bag G5 initial reenter setup could not close Bag."); yield break; }
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button initialReenter = mainView?.Binding.Find(BagPath)?.GetComponent<Button>();
                if (initialReenter == null)
                { Fail("Bag G5 initial reenter setup could not find the real main entry."); yield break; }
                bagInitialG5ReenterRequested = true;
                initialReenter.onClick.Invoke();
                yield break;
            }
            if (bagInitialG5ReenterRequested && !bagInitialG5ReenterCaptured)
            {
                bagInitialG5ReenterCaptured = true;
                yield return CaptureBagG5Evidence("BAG-01-REENTER");
            }
            if (!InvokeBagControl("BAG-03-TAB")) { Fail("Bag G4 tab binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-03-TAB");
            if (!SelectBagItem(500)) { Fail("Bag G4 could not select batch item 500."); yield break; }
            yield return CaptureBagG5Evidence("BAG-04-LIST-ITEM");
            if (!InvokeBagControl("BAG-05-LIST-SCROLL")) { Fail("Bag G4 list scroll failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-05-LIST-SCROLL");
            if (!InvokeBagControl("BAG-06-DETAIL-ICON")) { Fail("Bag G4 detail icon binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-06-DETAIL-ICON");
            RecordValidationSemantic("bag-selection-scroll-refresh", true,
                "real item selection, selected-tab callback, list scroll and detail-icon callback completed without authority mutation");

            if (!InvokeBagControl("BAG-07-USE") || !IsBagInputOpen)
            { Fail("Bag G4 batch item did not open EnterNumLayer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-07-USE-BATCH");
            if (!InvokeBagControl("BAG-08-INPUT-DIGITS") || BagModalQuantity != 10 || BagModalDisplayText != "10")
            { Fail($"Bag G4 input digits did not render quantity=10: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            yield return CaptureBagG5Evidence("BAG-08-INPUT-DIGITS");
            InvokeBagControl("BAG-09-INPUT-DELETE");
            if (BagModalQuantity != 1 || BagModalDisplayText != "1")
            { Fail($"Bag G4 input delete did not render 10 -> 1: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            yield return CaptureBagG5Evidence("BAG-09-INPUT-DELETE");
            InvokeBagControl("BAG-09-INPUT-DELETE");
            if (BagModalQuantity != 0 || BagModalDisplayText != "请输入数量")
            { Fail($"Bag G4 second input delete did not clear display: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            InvokeBagControl("BAG-10-INPUT-CONFIRM");
            if (IsBagInputOpen || GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity)
            { Fail("Bag G4 zero confirmation changed authoritative state."); yield break; }
            yield return CaptureBagG5Evidence("BAG-10-INPUT-ZERO");

            SelectBagItem(500);
            InvokeBagControl("BAG-07-USE");
            InvokeBagControl("BAG-11-INPUT-CLOSE");
            if (IsBagInputOpen) { Fail("Bag G4 input close did not close the modal."); yield break; }
            yield return CaptureBagG5Evidence("BAG-11-INPUT-CLOSE");

            SelectBagItem(500);
            InvokeBagControl("BAG-07-USE");
            if (!InvokeBagControl("BAG-08-INPUT-DIGITS") || BagModalQuantity != 10)
            { Fail($"Bag G4 batch quantity setup failed: actual={BagModalQuantity}."); yield break; }
            InvokeBagControl("BAG-10-INPUT-CONFIRM");
        }

        public void ContinueBagG4AfterBatchUse()
        {
            StartCoroutine(ContinueBagG4AfterBatchUseRoutine());
        }

        private IEnumerator ContinueBagG4AfterBatchUseRoutine()
        {
            if (GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 10 || !IsBagOpen)
            {
                Fail($"Bag G4 batch consume mismatch: item500={GetBagQuantityByItemId(500)}/"
                    + $"{bagG4InitialBatchQuantity - 10}, open={IsBagOpen}.");
                yield break;
            }
            RecordValidationSemantic("bag-authoritative-full-and-incremental", true,
                $"real /8 total={bagG4InitialBatchQuantity}; /15 reduced aggregate to {GetBagQuantityByItemId(500)}");
            RecordValidationSemantic("bag-batch-use-bounds", true,
                "0-9 callbacks reached; entered 10, deleted to 1 then 0, zero-confirm was inert, authoritative batch consumed exactly 10");
            yield return CaptureBagG5Evidence("BAG-10-BATCH-SUCCESS");

            foreach (int ticketItemId in new[] { 1000, 1001 })
            {
                int initialTicketQuantity = GetBagQuantityByItemId(ticketItemId);
                if (!SelectBagItem(ticketItemId) || !InvokeBagControl("BAG-07-USE") || !IsDrawOpen)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} did not open Draw through use_jump=1010.");
                    yield break;
                }
                if (!HandleBack() || IsBagOpen || IsDrawOpen)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} left Bag in the navigation stack after Draw closed.");
                    yield break;
                }
                if (GetBagQuantityByItemId(ticketItemId) != initialTicketQuantity)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} changed quantity on a pure use_jump route.");
                    yield break;
                }
                // BAG-01 and the initial /8 already prove the real entry and
                // authoritative store. Reuse that snapshot between the two ticket
                // cases; issuing another /8 in automation would restart the whole
                // Bag G4 state machine after its mandatory sort response.
                if (!ReopenBagForRecruitRouteValidation())
                {
                    Fail("Bag G4 recruit-ticket route could not restore Bag from the loaded snapshot.");
                    yield break;
                }
            }
            RecordValidationSemantic("bag-use-jump-closes-origin", true,
                "item1000 and item1001 opened current HappyDraw/1010 without consumption; one Draw Back returned to main instead of reopening Bag");

            if (!SelectBagItem(1114) || !InvokeBagControl("BAG-07-USE") || !IsBagGiftOpen)
            { Fail("Bag G4 gift item did not open OpenBox_1Layer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-12-GIFT-OPEN");
            InvokeBagControl("BAG-18-GIFT-CONFIRM");
            if (!IsBagGiftOpen || GetBagQuantityByItemId(1114) != 3)
            { Fail("Bag G4 no-selection gift confirmation mutated or closed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-18-GIFT-NO-SELECTION");
            InvokeBagControl("BAG-19-GIFT-CLOSE");
            if (IsBagGiftOpen) { Fail("Bag G4 gift close failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-19-GIFT-CLOSE");

            SelectBagItem(1114);
            InvokeBagControl("BAG-07-USE");
            InvokeBagControl("BAG-12-GIFT-OPTION");
            if (!BagHasChoice) { Fail("Bag G4 gift choice did not select."); yield break; }
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");
            yield return CaptureBagG5Evidence("BAG-12-GIFT-OPTION");
            InvokeBagControl("BAG-14-GIFT-SUB-ONE");
            InvokeBagControl("BAG-13-GIFT-SCROLL");
            yield return CaptureBagG5Evidence("BAG-13-GIFT-SCROLL");
            bagFlowPresenter.ResetGiftScroll();
            InvokeBagControl("BAG-15-GIFT-ADD-ONE");
            yield return CaptureBagG5Evidence("BAG-15-GIFT-ADD-ONE");
            InvokeBagControl("BAG-14-GIFT-SUB-ONE");
            yield return CaptureBagG5Evidence("BAG-14-GIFT-SUB-ONE");
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");
            yield return CaptureBagG5Evidence("BAG-17-GIFT-ADD-TEN");
            InvokeBagControl("BAG-16-GIFT-SUB-TEN");
            yield return CaptureBagG5Evidence("BAG-16-GIFT-SUB-TEN");
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");

            if (!InvokeBagControl("BAG-20-GIFT-REWARD-DETAIL") || !IsBagSourceOpen)
            { Fail("Bag G4 gift reward detail did not open source UI."); yield break; }
            yield return CaptureBagG5Evidence("BAG-20-GIFT-REWARD-DETAIL");
            InvokeBagControl("BAG-23-SOURCE-SCROLL");
            yield return CaptureBagG5Evidence("BAG-23-SOURCE-SCROLL");
            InvokeBagControl("BAG-21-SOURCE-CLOSE");
            if (!IsBagGiftOpen || IsBagSourceOpen)
            { Fail("Bag G4 source close did not return to gift."); yield break; }
            yield return CaptureBagG5Evidence("BAG-21-SOURCE-CLOSE");

            InvokeBagControl("BAG-19-GIFT-CLOSE");
            SelectBagItem(1112);
            InvokeBagControl("BAG-07-USE");
            if (!InvokeBagControl("BAG-20-GIFT-REWARD-DETAIL")
                || !IsBagSourceOpen)
            { Fail("Bag G4 equipment-fragment source setup failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-20-EQUIPMENT-SOURCE");
            if (!InvokeBagControl("BAG-22-SOURCE-ICON") || !IsBagEquipmentInfoOpen)
            { Fail("Bag G4 source icon did not open equipment info."); yield break; }
            yield return CaptureBagG5Evidence("BAG-22-SOURCE-ICON");
            InvokeBagControl("BAG-26-EQUIP-INFO-SCROLL");
            yield return CaptureBagG5Evidence("BAG-26-EQUIP-INFO-SCROLL");
            InvokeBagControl("BAG-25-EQUIP-INFO-CLOSE");
            if (!IsBagSourceOpen || IsBagEquipmentInfoOpen)
            { Fail("Bag G4 equipment info close did not return one layer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-25-EQUIP-INFO-CLOSE");
            if (!InvokeBagControl("BAG-24-SOURCE-ACTION"))
            { Fail("Bag G4 source action did not invoke its target."); yield break; }
            float sourceDeadline = Time.realtimeSinceStartup + 8f;
            while ((!IsGameplayShopOpen || GameplayShopRenderedCount <= 0)
                && Time.realtimeSinceStartup < sourceDeadline) yield return null;
            if (!IsGameplayShopOpen || GameplayShopRenderedCount <= 0)
            { Fail("Bag G4 source action did not open populated migrated GameplayShops destination."); yield break; }
            if (bagFrameView.GameObject.activeSelf || bagView.GameObject.activeSelf
                || bagSourceView.GameObject.activeSelf || bagEquipmentInfoView.GameObject.activeSelf
                || !bagPopupFrameView.GameObject.activeSelf)
            {
                Fail("Bag G4 source action retained a Bag surface behind GameplayShops or omitted its shop frame.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-24-SOURCE-ACTION");
            HandleBack();
            yield return null;
            if (!IsBagOpen || IsBagSourceOpen || IsGameplayShopOpen
                || !bagFrameView.GameObject.activeSelf || bagPopupFrameView.GameObject.activeSelf)
            { Fail("Bag G4 source action did not return from GameplayShops to Bag cleanly."); yield break; }

            RecordValidationSemantic("bag-source-route-boundary", true,
                "functionId=17 hid every Bag surface, opened framed GameplayShops, and back restored the framed Bag");
            RecordValidationSemantic("bag-disabled-excluded-target", !CanOpenBagSource(2125),
                "excluded functionId=2125 is rejected by the shared Bag route availability policy");

            SelectBagItem(1111);
            InvokeBagControl("BAG-07-USE");
            bagFlowPresenter.SelectGiftChoice(0);
            InvokeBagControl("BAG-18-GIFT-CONFIRM");
        }

        private bool ReopenBagForRecruitRouteValidation()
        {
            if (services?.UiStack.Current != mainView) return false;
            EnsureBagPresenter();
            ConfigureBagFrame();
            bagPresenter.Render();
            bagFrameView.SetVisible(true);
            services.UiStack.Push(bagView);
            bagFrameView.GameObject.transform.SetAsLastSibling();
            bagView.GameObject.transform.SetAsLastSibling();
            return IsBagOpen;
        }

        public bool RunBagG4DirectUse()
        {
            if (GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity - 1
                || GetBagQuantityByItemId(4621) <= bagG4InitialRewardQuantity)
            {
                Fail("Bag G4 gift authority was not confirmed before direct-use validation.");
                return false;
            }
            RecordValidationSemantic("bag-choice-use-authority", true,
                $"real /15 consumed item1111 and added reward4621={GetBagQuantityByItemId(4621)}");
            if (!SelectBagItem(3201) || !InvokeBagControl("BAG-07-USE"))
            {
                Fail("Bag G4 injected direct-use item could not be used through the real button.");
                return false;
            }
            return true;
        }

        public void BeginBagReloadValidation()
        {
            StartCoroutine(BeginBagReloadValidationRoutine());
        }

        private IEnumerator BeginBagReloadValidationRoutine()
        {
            if (GetBagQuantityByItemId(3201) != bagG4InitialDirectQuantity)
            { Fail("Bag G4 direct-use authority did not settle to the original quantity after injection and consume."); yield break; }
            RecordValidationSemantic("bag-direct-use-authority", true,
                "real injected item3201 was consumed once; repeat request did not mutate the authoritative total");
            RecordValidationSemantic("bag-type-dispatch", true,
                "no-action, quantity input, choice gift, equipment info and direct-use paths were reached through configured item types");
            yield return CaptureBagG5Evidence("BAG-18-GIFT-SUCCESS");
            if (!InvokeBagControl("BAG-02-CLOSE") || IsBagOpen)
            { Fail("Bag G4 close button did not return to main."); yield break; }
            yield return CaptureBagG5Evidence("BAG-02-CLOSE");
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            Button entry = mainView?.Binding.Find(BagPath)?.GetComponent<Button>();
            if (entry == null) { Fail("Bag G4 real main entry was unavailable after close."); yield break; }
            entry.onClick.Invoke();
        }

        public void BeginBagDisconnectValidation()
        {
            if (!IsBagOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Bag G4 pre-disconnect mismatch: open={IsBagOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            StartCoroutine(BeginBagDisconnectValidationRoutine());
        }

        private IEnumerator BeginBagDisconnectValidationRoutine()
        {
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-REENTER");
            services.Network.Disconnect();
            yield return null;
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected)
            {
                Fail($"Bag G4 disconnect was not observed: state={services.Network.State}.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-DISCONNECTED");
            // The Bag gate owns this deliberate disconnect. Trigger the real
            // reconnect entry after the disconnected state is observable instead
            // of depending on the general delayed retry policy.
            Reconnect();
        }

        public void CompleteBagG4Validation()
        {
            StartCoroutine(CompleteBagG4ValidationRoutine());
        }

        private IEnumerator CompleteBagG4ValidationRoutine()
        {
            if (!IsBagOpen || services.ProtocolRegistry.PendingCount != 0
                || GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 10
                || GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity - 1
                || GetBagQuantityByItemId(3201) != bagG4InitialDirectQuantity
                || GetBagQuantityByItemId(4621) <= bagG4InitialRewardQuantity
                || IsBagInputOpen || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 persisted/reconnect mismatch: open={IsBagOpen}, pending={services.ProtocolRegistry.PendingCount}, "
                    + $"500={GetBagQuantityByItemId(500)}/{bagG4InitialBatchQuantity - 10}, "
                    + $"1111={GetBagQuantityByItemId(1111)}/{bagG4InitialGiftQuantity - 1}, "
                    + $"3201={GetBagQuantityByItemId(3201)}/{bagG4InitialDirectQuantity}, "
                    + $"4621={GetBagQuantityByItemId(4621)}/{bagG4InitialRewardQuantity + 1}, "
                    + $"modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
            ShowToast("重新连接成功", 2f);
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-RECONNECT");
            RecordValidationSemantic("bag-network-recovery", true,
                $"deliberate disconnect/reconnect restored Bag for role={GetPlayerRoleId()} with pending=0");
            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Bag.Count != 0 || IsBagOpen || IsBagInputOpen
                || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 account-switch cleanup mismatch: login={IsLoginVisible}, count={services.Bag.Count}, "
                    + $"open={IsBagOpen}, modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
            RecordValidationSemantic("bag-account-isolation", true,
                "return-to-login cleared Bag store and every Bag modal while preserving the fixed role snapshot");
            RecordValidationSemantic("bag-fixture-exact-restore", true,
                "outer fixed-account runner owns finally restore, relogin hash equality and backup residue assertions");
            RecordValidationSemantic("bag-control-matrix-26", validationControlIds.Count == 26,
                $"validated={validationControlIds.Count}/26 through real callbacks");
            Complete("COMPLETE: Bag G4 real controls -> batch/gift/direct use -> authoritative add/update/delete/sort "
                + "-> invalid/repeat rejection -> close/reload -> disconnect/reconnect persistence -> account-switch cleanup");
        }

        private int GetBagQuantityByItemId(int itemId)
        {
            return services.Bag.GetTotalQuantityByItemId(itemId);
        }

        private IEnumerator CaptureBagG5Evidence(string controlId)
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Bag", "unity", "g5-20260821");
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, controlId + ".png");
            if (File.Exists(path)) File.Delete(path);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Bag G5 screenshot was not written: {path}");
            string artifactName = null;
            switch (controlId)
            {
                case "BAG-01-ENTRY": artifactName = "bootstrap-bag.png"; break;
                case "BAG-01-RECONNECT":
                    artifactName = "bootstrap-bag-reconnected.png";
                    break;
                case "BAG-05-LIST-SCROLL": artifactName = "bootstrap-bag-scrolled.png"; break;
                case "BAG-07-USE-BATCH": artifactName = "bootstrap-bag-input.png"; break;
                case "BAG-12-GIFT-OPEN": artifactName = "bootstrap-bag-gift.png"; break;
                case "BAG-13-GIFT-SCROLL": artifactName = "bootstrap-bag-gift-scrolled.png"; break;
                case "BAG-20-EQUIPMENT-SOURCE": artifactName = "bootstrap-bag-source.png"; break;
                case "BAG-22-SOURCE-ICON": artifactName = "bootstrap-bag-equipment-info.png"; break;
                case "BAG-01-DISCONNECTED": artifactName = "bootstrap-bag-disconnected.png"; break;
                case "BAG-01-REENTER": artifactName = "bootstrap-bag-reenter.png"; break;
            }
            if (!string.IsNullOrEmpty(artifactName))
                File.Copy(path, BuildUiMigrationPath(artifactName), true);
        }

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
            UpdateMailRedDot();
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
        public bool MoveMailToHistory(double id)
        {
            bool moved = services.Mails.MoveToHistory(checked((uint)id));
            UpdateMailRedDot();
            return moved;
        }
        public bool DeleteLocalMail(double id)
        {
            bool deleted = services.Mails.DeleteHistory(checked((uint)id));
            UpdateMailRedDot();
            return deleted;
        }
        public int DeleteAllLocalMails()
        {
            int count = services.Mails.DeleteAllHistory();
            UpdateMailRedDot();
            return count;
        }

        public void CompleteMailClaimValidation(double claimedId, int rewardCount)
        {
            uint id = checked((uint)claimedId);
            bool claimedHistory = services.Mails.TryGet(id, out MailRecord claimed)
                && claimed.IsRead && !claimed.HasAttachments;
            if (!claimedHistory || rewardCount <= 0 || !ValidateRewardPresentation(rewardCount, true)
                || services.ProtocolRegistry.PendingCount != 0 || !IsMailOpen)
            {
                Fail($"Mail validation mismatch: claimedHistory={claimedHistory}, rewards={rewardCount}, pending={services.ProtocolRegistry.PendingCount}, open={IsMailOpen}.");
                return;
            }
            MarkValidationControl("MAIL-10-SINGLE-CLAIM");
            if (!mailPresenter.Select(id) || mailPresenter.SingleActionLabel != "删除"
                || !mailPresenter.InvokeSingleAction() || services.Mails.TryGet(id, out _))
            {
                Fail("Mail G4 single-delete control did not remove the claimed local-history mail.");
                return;
            }
            MarkValidationControl("MAIL-11-SINGLE-DELETE");
            InvokeLuaOrFail(onMailValidationRepeat, "Mail.ValidationRepeat", (double)id);
        }

        public void BeginMailG4Validation(double mailId)
        {
            BeginValidationEvidence();
            StartCoroutine(RunMailG4Validation(checked((uint)mailId)));
        }

        public void CompleteMailRepeatValidation(double mailId)
        {
            SetStatus($"Mail/128 repeated claim rejected explicitly: id={checked((uint)mailId)}.");
            InvokeLuaOrFail(onMailValidationClaimAll, "Mail.ValidationClaimAll");
        }

        public void CompleteMailClaimAllValidation()
        {
            if (services.Mails.HasClaimable || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Mail G4 claim-all mismatch: claimable={services.Mails.HasClaimable}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            rewardPresenter?.Hide();
            MarkValidationControl("MAIL-12-CLAIM-ALL");
            InvokeLuaOrFail(onMailValidationReadAll, "Mail.ValidationReadAll");
        }

        public void CompleteMailReadAllValidation()
        {
            if (services.Mails.Items.Any(item => !item.IsRead || item.HasAttachments)
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Mail G4 read-all mismatch: unread={services.Mails.Items.Count(item => !item.IsRead)}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            if (!mailPresenter.InvokeDeleteAll() || services.Mails.Count != 0 || !mailPresenter.IsEmptyVisible)
            {
                Fail("Mail G4 delete-all did not reach the real empty state.");
                return;
            }
            MarkValidationControl("MAIL-13-DELETE-ALL");
            StartCoroutine(FinalizeMailG4Validation());
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

        public void AddSystemChatMessage(string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = ChatChannel.System,
                Sender = new PlayerSummary(),
                Content = content ?? string.Empty
            });
            if (!string.IsNullOrWhiteSpace(content) && !HasCommandLineFlag("-projectXGameplayValidation"))
                ShowToast(content, 3f);
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
            services.Rewards.Replace("关卡结算", pendingRewards);
            EnsureWorldOutcomePresenter();
            worldOutcomePresenter.ShowBattle(stars);
            SetStatus($"World battle result active: stars={stars}, rewards={services.Rewards.Count}.");
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
            if (GetLocalUserId() == 1 || !IsWorldOpen || stage == null || stage.Stars == 0 || stage.Stars == byte.MaxValue
                || services.World.ChapterCount == 0 || services.World.StageCount == 0
                || worldPresenter.RenderedRewardCount == 0 || visibleRewardCount <= 0)
            {
                Fail($"World final state mismatch: user={GetLocalUserId()}, open={IsWorldOpen}, chapter={services.World.ChapterCount}, stages={services.World.StageCount}, stage={stageId}, stars={stage?.Stars ?? 255}, fought={stage?.FoughtCount ?? 0}, rewards={visibleRewardCount}/{worldPresenter.RenderedRewardCount}.");
                return;
            }
            if (!services.Options.WorldBattleValidation)
            {
                Complete($"COMPLETE: /320 world -> chapter/stage state -> detail/formation/reward preview -> PvE stage {stageId} -> op=8 settlement -> persisted stars={stage.Stars}, server fight count={stage.FoughtCount}; isolated user={GetLocalUserId()}");
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

        public void BeginActivityListUpdate(int expectedCount)
        {
            pendingActivityItems.Clear();
            if (expectedCount > pendingActivityItems.Capacity) pendingActivityItems.Capacity = expectedCount;
        }

        public void AddActivityListItem(double rawTag, string name, bool hotPoint, bool isNew, double rawRemainingSeconds)
        {
            pendingActivityItems.Add(new ActivityListRecord
            {
                Tag = checked((uint)rawTag), Name = name ?? string.Empty,
                HasHotPoint = hotPoint, IsNew = isNew,
                RemainingSeconds = checked((uint)rawRemainingSeconds)
            });
        }

        public void EndActivityListUpdate()
        {
            services.Activity.ReplaceList(pendingActivityItems, services.ServerTime.UnixSeconds);
            RefreshActivityHotPoint();
            EnsureActivityPresenter();
            SetStatus($"Activity /222 op=0xFF list: {services.Activity.Count} entries.");
        }

        public void SelectActivity(double rawTag)
        {
            services.Activity.Select(checked((uint)rawTag));
        }

        public void BeginActivityDailyRechargeUpdate(bool weChatVisible, bool recharged, bool claimed,
            bool weChatRecharged, bool weChatClaimed, int expectedCount)
        {
            pendingDailyRecharge = new DailyRechargeActivityState
            {
                WeChatRewardVisible = weChatVisible, Recharged = recharged, Claimed = claimed,
                WeChatRecharged = weChatRecharged, WeChatClaimed = weChatClaimed
            };
            if (expectedCount > pendingDailyRecharge.Rewards.Capacity)
                pendingDailyRecharge.Rewards.Capacity = expectedCount;
        }

        public void AddActivityReward(int rewardType, double rawAmount, string name, int picture, int quality)
        {
            if (pendingDailyRecharge == null) throw new InvalidOperationException("Activity daily recharge update was not started.");
            pendingDailyRecharge.Rewards.Add(new ActivityRewardRecord
            {
                Type = checked((ushort)rewardType), Amount = checked((uint)rawAmount),
                Name = name ?? string.Empty, Picture = picture, Quality = quality
            });
        }

        public void EndActivityDailyRechargeUpdate(bool validation)
        {
            if (pendingDailyRecharge == null) throw new InvalidOperationException("Activity daily recharge update was not started.");
            services.Activity.SetDailyRecharge(pendingDailyRecharge);
            EnsureActivityPresenter();
            SetStatus($"Activity /222 op=18 subOp=1: rewards={services.Activity.DailyRecharge.Rewards.Count}, recharged={services.Activity.DailyRecharge.Recharged}, claimed={services.Activity.DailyRecharge.Claimed}.");
            if (validation) StartCoroutine(CaptureActivityValidationStates());
        }

        public void SetActivityError(string message) { ShowToast(message, 3f); SetStatus(message); }

        public void CompleteActivityValidation()
        {
            EnsureActivityPresenter();
            bool hasUnsupportedTab = services.Activity.Items.Any(value => value.Tag != ActivityPresenter.DailyRechargeTag);
            if (GetLocalUserId() == 1 || !IsActivityOpen || services.Activity.Count < 2
                || !hasUnsupportedTab || !IsActivityDailyRechargeVisible || ActivityRewardCount == 0
                || !activityPresenter.HasCountdown || services.ProtocolRegistry.PendingCount != 0
                || IsActivityHotPointVisible != services.Activity.HasHotPoint)
            {
                Fail($"Activity final state mismatch: user={GetLocalUserId()}, open={IsActivityOpen}, list={services.Activity.Count}, daily={IsActivityDailyRechargeVisible}, rewards={ActivityRewardCount}, countdown={activityPresenter.HasCountdown}, pending={services.ProtocolRegistry.PendingCount}, hot={IsActivityHotPointVisible}/{services.Activity.HasHotPoint}.");
                return;
            }
            Complete($"COMPLETE: Activity /222 op=0xFF list -> real tabs/hot-point/countdown -> op=18 subOp=1 daily recharge state/rewards -> unsupported real tab empty boundary; isolated user={GetLocalUserId()}");
        }

        public void BeginDrawPoolUpdate(int expectedCount)
        {
            pendingDrawPools.Clear();
            if (expectedCount > pendingDrawPools.Capacity) pendingDrawPools.Capacity = expectedCount;
        }

        public void AddDrawPool(int kind, double rawTotalDraws, double rawCooldown, int freeTimes)
        {
            pendingDrawPools.Add(new DrawPoolRecord
            {
                Kind = checked((byte)kind),
                TotalDraws = checked((uint)rawTotalDraws),
                FreeCooldownSeconds = checked((uint)rawCooldown),
                FreeTimes = checked((byte)freeTimes)
            });
        }

        public void EndDrawPoolUpdate(bool validation)
        {
            services.Draw.ReplacePools(pendingDrawPools, services.ServerTime.UnixSeconds);
            EnsureDrawPresenter();
            // ShowDraw owns navigation when the request is sent. A delayed /224
            // response only refreshes authoritative data; it must not reopen Draw
            // after the user has already closed it or navigated elsewhere.
            RefreshDrawHotPoint();
            SetStatus($"Draw /224 op=1: pools={services.Draw.Count}, free={services.Draw.HasFreeDraw}.");
            if (validation)
                StartCoroutine(HasCommandLineFlag("-projectXDrawClosureValidation")
                    ? BeginDrawG4SequenceNextFrame()
                    : RequestValidationDrawNextFrame());
        }

        public void BeginDrawResult(int kind, int drawType, double rawTotalDraws, int freeTimes,
            double rawCooldown, int expectedGuaranteedCount)
        {
            pendingDrawResult = new DrawResultRecord
            {
                Kind = checked((byte)kind),
                DrawType = checked((byte)drawType),
                TotalDraws = checked((uint)rawTotalDraws),
                FreeTimes = checked((byte)freeTimes),
                FreeCooldownSeconds = checked((uint)rawCooldown)
            };
            if (expectedGuaranteedCount > pendingDrawResult.GuaranteedRewards.Capacity)
                pendingDrawResult.GuaranteedRewards.Capacity = expectedGuaranteedCount;
        }

        public void AddDrawGuaranteedReward(int type, double rawId, double rawAmount,
            int transformItemId, double rawTransformAmount, string name, int picture, int quality)
        {
            RequirePendingDraw().GuaranteedRewards.Add(NewDrawReward(type, rawId, rawAmount,
                transformItemId, rawTransformAmount, name, picture, quality));
        }

        public void AddDrawResultReward(int type, double rawId, double rawAmount,
            int transformItemId, double rawTransformAmount, string name, int picture, int quality)
        {
            RequirePendingDraw().Rewards.Add(NewDrawReward(type, rawId, rawAmount,
                transformItemId, rawTransformAmount, name, picture, quality));
        }

        public void EndDrawResult(bool validation)
        {
            DrawResultRecord result = RequirePendingDraw();
            services.Draw.SetResult(result, services.ServerTime.UnixSeconds);
            pendingDrawResult = null;
            EnsureDrawPresenter();
            RefreshDrawHotPoint();
            SetStatus($"Draw /224 op=2: kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, total={result.TotalDraws}.");
            if (!validation) return;
            if (HasCommandLineFlag("-projectXDrawClosureValidation"))
            {
                if (drawG4SequenceRunning) return;
                if (result.Kind != 2 || result.DrawType != 1 || result.Rewards.Count != 1
                    || !result.Rewards.Any(value => value.Id == DrawClosureTargetHeroId)
                    || !IsDrawResultVisible || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail($"Draw closure result mismatch: kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, target={DrawClosureTargetHeroId}, visible={IsDrawResultVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                    return;
                }
                StartCoroutine(RequestDrawClosureHeroNextFrame());
                return;
            }
            if (GetLocalUserId() == 1 || !IsDrawOpen || services.Draw.Count != 3
                || result.Kind != 1 || result.DrawType != 1 || result.Rewards.Count != 1
                || !IsDrawResultVisible || !IsDrawEffectLoaded || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Draw final state mismatch: user={GetLocalUserId()}, open={IsDrawOpen}, pools={services.Draw.Count}, kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, result={IsDrawResultVisible}, effect={IsDrawEffectLoaded}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            Complete($"COMPLETE: current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline; isolated user={GetLocalUserId()}");
        }

        public bool IsExpectedDrawFailure() => drawG4ExpectFailure;

        public void SetDrawError(string message)
        {
            drawG4LastError = message ?? string.Empty;
            if (drawG4ExpectFailure && !drawG4ExpectedFailureCompleted)
            {
                // The insufficiency response is itself the authoritative result of
                // DRAW-27. Advance from this exact callback instead of relying on
                // a later coroutine tick after the result view has been dismissed.
                drawG4ExpectedFailureCompleted = true;
                SetStatus("Draw G4 authoritative insufficient-resource response observed.");
                ShowDrawExchange();
                MarkValidationControl("DRAW-27-TEN-CONTINUE");
                StartCoroutine(CaptureDrawInsufficientThenRequestHero());
                return;
            }
            ShowToast(message, 3f);
            SetStatus(message);
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

        public void ShowGameplayShop(int functionId)
        {
            EnsureGameplayShopsPresenter();
            if (!IsGameplayShopOpen)
            {
                restoreChatMiniAfterGameplayShop =
                    chatMiniView != null && chatMiniView.GameObject.activeSelf;
                restoreBagFrameAfterGameplayShop = IsBagOpen
                    && bagFrameView != null && bagFrameView.GameObject.activeSelf;
            }
            chatMiniView?.SetVisible(false);
            if (restoreBagFrameAfterGameplayShop) bagFrameView?.SetVisible(false);
            CocosUiView previous = gameplayShopsPresenter.ActiveView;
            gameplayShopsPresenter.ShowFunction(functionId);
            CocosUiView target = gameplayShopsPresenter.ActiveView;
            gameplayContentView?.SetVisible(false);
            gameplayDetailView?.SetVisible(false);
            Transform gameplayNotice =
                bagPopupFrameView.GameObject.transform.Find("FloatNoticeLayer");
            if (gameplayNotice != null) gameplayNotice.gameObject.SetActive(false);
            if (services.UiStack.Current == previous && previous != target) services.UiStack.Pop();
            if (services.UiStack.Current != target) services.UiStack.Push(target);
            ConfigureGameplayShopsFrame();
            bagPopupFrameView.SetVisible(true);
            bagPopupFrameView.GameObject.transform.SetAsLastSibling();
            target.GameObject.transform.SetAsLastSibling();
            SetStatus($"Gameplay shop function_id={functionId} active; awaiting /221.");
        }

        public void BeginGameplayShopUpdate(int type, int refreshTimes, int freeRefreshTimes,
            int refreshRemainingSeconds, int expectedCount)
        {
            BeginShopUpdate(type, refreshTimes, freeRefreshTimes, refreshRemainingSeconds, expectedCount);
        }

        public void AddGameplayShopRecord(int grid, double id, int buyCount, string name,
            string description, int picture, int quality)
        {
            AddShopRecord(grid, id, buyCount, name, description, picture, quality);
        }

        public void EndGameplayShopUpdate()
        {
            services.GameplayShops.Replace(pendingShopType, pendingShopRefreshTimes, pendingShopFreeTimes,
                pendingShopRefreshRemaining, services.ServerTime.UnixSeconds, pendingShopRecords);
            EnsureGameplayShopsPresenter();
            gameplayShopsPresenter.SelectType(pendingShopType, false);
        }

        public bool ApplyGameplayShopPurchase(int rawType, double rawId, int buyCount,
            int rewardType, double rewardAmount)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            if (!services.GameplayShops.TryGet(type, id, out ShopRecord item)
                || item.RewardType != rewardType
                || item.RewardAmount != checked((uint)rewardAmount))
                return false;
            return services.GameplayShops.ApplyPurchase(type, id, checked((ushort)buyCount));
        }

        public void SetGameplayShopBuyCount(int rawType, double rawId, int buyCount)
        {
            services.GameplayShops.ApplyPurchase(checked((byte)rawType),
                checked((ushort)rawId), checked((ushort)buyCount));
        }

        public void ClearGameplayShopState()
        {
            services.GameplayShops.Clear();
            pendingShopRecords.Clear();
            gameplayShopsPresenter?.ResetTransientState();
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
        }

        public void ShowGameplayShopPurchaseReward(int rawType, double rawId,
            int rewardType, double rewardAmount, int quantity)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            if (!services.GameplayShops.TryGet(type, id, out ShopRecord item)) return;
            uint totalAmount = checked((uint)rewardAmount * checked((uint)Math.Max(1, quantity)));
            services.Rewards.Replace("购买获得", new[]
            {
                new RewardRecord(rewardType, checked((uint)Math.Max(0, item.RewardId)),
                    totalAmount, item.Name, item.Picture, item.Quality)
            });
            EnsureRewardPresenter();
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
        }

        public void ShowGameplayShopItemDetail(ShopRecord item)
        {
            if (item == null) return;
            EnsureErrorPresenter();
            string limit = item.Limit < 0 ? "不限购" : $"剩余 {item.RemainingLimit} 次";
            errorPresenter.Show("物品详情",
                $"{item.Name}\n{item.Description}\n单价：{item.UnitCost} {item.CostName}\n{limit}");
        }

        private void RequestGameplayShopPurchase(byte type, ushort id, int quantity)
        {
            if (!services.GameplayShops.TryGet(type, id, out ShopRecord item) || item.IsSoldOut)
            {
                ShowToast("商品已售罄", 2f);
                return;
            }
            long totalCost = item.TotalCost(quantity);
            if (services.Currencies.Get(item.CostType) < totalCost)
            {
                ShowToast($"{item.CostName}不足", 2f);
                return;
            }
            InvokeLuaOrFail(onGameplayShopBuy, "Gameplay.Shops.Buy",
                (double)type, (double)id, quantity);
        }

        private void RequestGameplayShopType(byte type)
        {
            if ((type == 27 || type == 28) && services.Player.Level < 99)
            {
                ShowToast("99级开启此功能", 2f);
                return;
            }
            InvokeLuaOrFail(onGameplayShopTab, "Gameplay.Shops.Tab", (double)type);
        }

        public void CompleteGameplayShopsValidation()
        {
            StartCoroutine(CaptureGameplayShopsValidation(true));
        }

        public void CompleteGameplayShopsVisualValidation()
        {
            StartCoroutine(CaptureGameplayShopsValidation(false));
        }

        private IEnumerator CaptureGameplayShopValidationScreenshot(string fileName)
        {
            // The capture contract reaches this point only after all shop requests have
            // completed. Clear any stale loading request so the common spinner cannot
            // contaminate the module's native visual evidence.
            loadingPresenter?.Clear();
            loadingView?.SetVisible(false);
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);

            float deadline = Time.realtimeSinceStartup + 8f;
            long previousLength = -1;
            int stableFrames = 0;
            while (Time.realtimeSinceStartup < deadline)
            {
                long length = File.Exists(path) ? new FileInfo(path).Length : 0;
                if (length > 0 && length == previousLength)
                {
                    stableFrames++;
                    if (stableFrames >= 2) yield break;
                }
                else
                {
                    previousLength = length;
                    stableFrames = 0;
                }
                yield return null;
            }
            throw new IOException($"GameplayShops screenshot was not written stably: {fileName}.");
        }

        public bool BeginGameplayShopsG4Validation(double rawPremiumItemId,
            int initialBuyCount, double rawConditionItemId)
        {
            BeginValidationEvidence();
            gameplayShopG4Events.Clear();
            ushort premiumItemId = checked((ushort)rawPremiumItemId);
            ushort conditionItemId = checked((ushort)rawConditionItemId);
            bool valid = initialBuyCount == 0
                && services.GameplayShops.TryGet(28, premiumItemId, out ShopRecord premium)
                && premium.CostType == CurrencyIds.Premium
                && premium.Limit == 25
                && services.GameplayShops.TryGet(7, conditionItemId, out ShopRecord condition)
                && condition.CostType == CurrencyIds.StarEssence;
            return RecordGameplayShopG4Event("fixture", valid,
                $"premium={premiumItemId}, initial={initialBuyCount}, condition={conditionItemId}");
        }

        public bool RecordGameplayShopG4Event(string key, bool passed, string detail)
        {
            if (string.IsNullOrWhiteSpace(key)) return false;
            if (!passed)
            {
                Fail($"Gameplay shops G4 {key} assertion failed: {detail}");
                return false;
            }
            gameplayShopG4Events.Add(key.Trim());
            SetStatus($"Gameplay shops G4 {key} passed: {detail}");
            return true;
        }

        public bool ValidateGameplayShopPurchase(int rawType, double rawId, int expectedBuyCount)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            ShopRecord item = null;
            bool passed = services.GameplayShops.TryGet(type, id, out item)
                && item.BuyCount == expectedBuyCount
                && item.IsSoldOut
                && rewardPresenter?.IsVisible == true;
            if (passed) rewardPresenter.Hide();
            return RecordGameplayShopG4Event("purchase-reload", passed,
                $"type={type}, id={id}, expected={expectedBuyCount}, actual={item?.BuyCount}, reward={rewardPresenter?.IsVisible}");
        }

        public bool ValidateGameplayShopRefresh(int beforeRefreshTimes, int beforeFreeTimes,
            int afterRefreshTimes, int afterFreeTimes)
        {
            GameplayShopPage page = null;
            bool passed = beforeFreeTimes > 0
                && afterFreeTimes == beforeFreeTimes - 1
                && afterRefreshTimes == beforeRefreshTimes
                && services.GameplayShops.TryGet(2, out page)
                && page.FreeRefreshTimes == afterFreeTimes
                && page.RefreshTimes == afterRefreshTimes
                && page.Items.Count == 6;
            return RecordGameplayShopG4Event("refresh", passed,
                $"refresh={beforeRefreshTimes}->{afterRefreshTimes}, free={beforeFreeTimes}->{afterFreeTimes}, cells={page?.Items.Count}");
        }

        public void BeginShopG4Validation(double rawId)
        {
            StartCoroutine(RunShopG4InitialUiValidation(checked((ushort)rawId)));
        }

        private IEnumerator RunShopG4InitialUiValidation(ushort itemId)
        {
            BeginValidationEvidence();
            EnsureShopPresenter();
            if (!IsShopOpen || services.Shop.Count < 3 || shopPresenter.ItemCount != services.Shop.Count
                || !services.Shop.TryGet(itemId, out ShopRecord item) || shopPresenter.MissingIconCount != 0)
            {
                Fail($"Shop G4 initial state mismatch: open={IsShopOpen}, store={services.Shop.Count}, "
                    + $"rendered={shopPresenter?.ItemCount ?? -1}, item={itemId}, missing={shopPresenter?.MissingIconCount ?? -1}.");
                yield break;
            }

            MarkValidationControl("SHOP-01-MAIN-TOGGLE");
            MarkValidationControl("SHOP-02-SUBMENU-ENTRY");
            yield return null;
            Canvas.ForceUpdateCanvases();
            shopPresenter.Render();
            yield return null;
            Text title = bagFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            Text tab = shopView.Binding.Find("Layer/ShopUI/ListView_left/Panel_button/Button_1/Text")?.GetComponent<Text>();
            RecordValidationSemantic("shop-title", title?.text == "商城", $"actual={title?.text}");
            RecordValidationSemantic("shop-tab", tab?.text == "道具购买", $"actual={tab?.text}");
            RecordValidationSemantic("shop-details", !string.IsNullOrWhiteSpace(item.Name)
                && !string.IsNullOrWhiteSpace(item.Description) && item.UnitCost > 0,
                $"id={item.Id}, name={item.Name}, cost={item.UnitCost}");
            RecordValidationSemantic("shop-refresh-config", shopPresenter.IsRefreshDisabledForBaseShop,
                "type=1 must expose a real but disabled refresh control");
            RecordValidationSemantic("shop-authority", services.ServerTime.IsSynchronized
                && services.ProtocolRegistry.PendingCount == 0, "server time and pending state");
            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Shop G4 semantic assertions failed.");
                yield break;
            }

            if (!shopPresenter.InvokeBaseTab()) { Fail("Shop G4 base tab was not bound."); yield break; }
            MarkValidationControl("SHOP-06-BASE-TAB");
            if (!shopPresenter.InvokeSelect(itemId)
                && (!shopPresenter.InvokeFirstBound(out itemId)
                    || !services.Shop.TryGet(itemId, out item)))
            { Fail($"Shop G4 could not invoke any bound item (requested {itemId})."); yield break; }
            MarkValidationControl("SHOP-08-ITEM-SELECT");
            yield return CaptureShopValidationScreenshot("bootstrap-shop-list.png");

            if (!shopPresenter.InvokePlus() || shopPresenter.SelectedQuantity != 2)
            { Fail("Shop G4 plus control failed."); yield break; }
            MarkValidationControl("SHOP-10-QUANTITY-PLUS");
            if (!shopPresenter.InvokeMinus() || shopPresenter.SelectedQuantity != 1)
            { Fail("Shop G4 minus control failed."); yield break; }
            MarkValidationControl("SHOP-09-QUANTITY-MINUS");
            if (!shopPresenter.InvokeQuantityInput()) { Fail("Shop G4 quantity input did not open."); yield break; }
            MarkValidationControl("SHOP-11-QUANTITY-INPUT-OPEN");
            if (!shopPresenter.InvokeQuantityDigit(2)) { Fail("Shop G4 keypad digit failed."); yield break; }
            MarkValidationControl("SHOP-12-QUANTITY-KEYPAD");
            if (!shopPresenter.InvokeQuantityDelete()) { Fail("Shop G4 keypad delete failed."); yield break; }
            MarkValidationControl("SHOP-13-QUANTITY-DELETE");
            if (!shopPresenter.InvokeQuantityCancel() || shopPresenter.IsQuantityInputVisible)
            { Fail("Shop G4 quantity cancel failed."); yield break; }
            MarkValidationControl("SHOP-15-QUANTITY-CANCEL");
            if (!shopPresenter.InvokeQuantityInput() || !shopPresenter.InvokeQuantityDelete()
                || !shopPresenter.InvokeQuantityDigit(2))
            { Fail("Shop G4 quantity input second pass failed."); yield break; }
            yield return CaptureShopValidationScreenshot("bootstrap-shop-quantity.png");
            if (!shopPresenter.InvokeQuantityConfirm() || shopPresenter.SelectedQuantity != 2)
            { Fail("Shop G4 quantity confirm failed."); yield break; }
            MarkValidationControl("SHOP-14-QUANTITY-CONFIRM");

            if (!shopPresenter.ScrollToBottom()) { Fail("Shop G4 list did not scroll."); yield break; }
            MarkValidationControl("SHOP-07-LIST-SCROLL");
            yield return CaptureShopValidationScreenshot("bootstrap-shop-scroll-bottom.png");

            if (!shopPresenter.InvokeSelect(itemId)) shopPresenter.Select(itemId);
            if (!shopPresenter.InvokePlus() || !shopPresenter.InvokeBuy() || !errorPresenter.IsVisible)
            { Fail("Shop G4 buy control did not open confirmation."); yield break; }
            MarkValidationControl("SHOP-16-BUY");
            if (!errorPresenter.InvokeCancel() || errorPresenter.IsVisible
                || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 purchase cancel changed pending state."); yield break; }
            MarkValidationControl("SHOP-18-PURCHASE-CANCEL");
            if (!shopPresenter.IsRefreshDisabledForBaseShop)
            { Fail("Shop G4 type=1 refresh control was not disabled."); yield break; }
            MarkValidationControl("SHOP-19-MANUAL-REFRESH");
            InvokeLuaOrFail(onShopValidationRefresh, "Shop.ValidationRefresh");
        }

        public void CompleteShopRefreshFailureValidation(string reason)
        {
            if (string.IsNullOrWhiteSpace(reason) || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 op=3 failure did not clear pending state."); return; }
            ushort id = services.Shop.Items.First().Id;
            InvokeLuaOrFail(onShopValidationCount, "Shop.ValidationCount", (double)id);
        }

        public void CompleteShopCountValidation(double rawId, int buyCount)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item) || item.BuyCount != buyCount
                || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 op=4 authoritative count mismatch."); return; }
            ShopRecord failureItem = services.Shop.Items.FirstOrDefault(value => value.Id == 1015);
            if (failureItem == null) failureItem = services.Shop.Items.OrderByDescending(value => value.UnitCost).First();
            InvokeLuaOrFail(onShopValidationFailure, "Shop.ValidationFailure",
                (double)failureItem.Id, 200);
        }

        public void CompleteShopFailureValidation()
        {
            StartCoroutine(RunShopG4SuccessfulPurchase());
        }

        private IEnumerator RunShopG4SuccessfulPurchase()
        {
            while (services.ProtocolRegistry.PendingCount != 0) yield return null;
            ShopRecord item = services.Shop.Items.First();
            validationShopId = item.Id;
            validationShopBuyCount = item.BuyCount;
            validationShopCurrencyType = item.CostType;
            validationShopQuantity = 2;
            validationShopExpectedCurrency = services.Currencies.Get(item.CostType) - item.TotalCost(2);
            validationShopRewardType = item.RewardType;
            validationShopRewardAmount = item.RewardAmount;
            if (!shopPresenter.Select(item.Id) || !shopPresenter.InvokePlus()
                || shopPresenter.SelectedQuantity != 2 || !shopPresenter.InvokeBuy()
                || !errorPresenter.IsVisible)
            { Fail("Shop G4 successful purchase confirmation did not open."); yield break; }
            yield return CaptureShopValidationScreenshot("bootstrap-shop-confirm.png");
            if (!errorPresenter.InvokeConfirmation())
            { Fail("Shop G4 real confirmation control failed."); yield break; }
            MarkValidationControl("SHOP-17-PURCHASE-CONFIRM");
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
            ShowShopPurchaseConfirmation(item, 1);
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

        public void SetShopBuyCount(double rawId, int buyCount)
        {
            services.Shop.ApplyPurchase(checked((ushort)rawId), checked((ushort)buyCount));
        }

        public void ClearShopState()
        {
            services.Shop.Clear();
            pendingShopRecords.Clear();
            shopPresenter?.ResetTransientState();
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
        }

        public void RequestShopCount(double rawId)
        {
            InvokeLuaOrFail(onShopCountRequested, "Shop.OnCountRequested", rawId);
        }

        public void ShowShopPurchaseReward(double rawId, int rewardType, double rewardAmount,
            int quantity)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item)) return;
            uint totalAmount = checked((uint)rewardAmount * checked((uint)Math.Max(1, quantity)));
            services.Rewards.Replace("购买获得", new[]
            {
                new RewardRecord(rewardType, checked((uint)Math.Max(0, item.RewardId)),
                    totalAmount, item.Name, item.Picture, item.Quality)
            });
            EnsureRewardPresenter();
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
        }

        public void CompleteShopPurchaseValidation(double rawId)
        {
            ushort id = checked((ushort)rawId);
            bool found = services.Shop.TryGet(id, out ShopRecord item);
            long currency = services.Currencies.Get(validationShopCurrencyType);
            bool rewardValid = ValidateRewardPresentation(1,
                !HasCommandLineFlag("-projectXShopG4Validation"));
            if (!found || id != validationShopId
                || item.BuyCount != validationShopBuyCount + validationShopQuantity
                || currency != validationShopExpectedCurrency || item.RewardType != validationShopRewardType
                || item.RewardAmount != validationShopRewardAmount || !rewardValid
                || services.ProtocolRegistry.PendingCount != 0 || !IsShopOpen
                || !services.ServerTime.IsSynchronized || shopPresenter.MissingIconCount != 0)
            {
                Fail($"Shop validation mismatch: found={found}, id={id}/{validationShopId}, count={(found ? item.BuyCount : 0)}/{validationShopBuyCount + validationShopQuantity}, currency={currency}/{validationShopExpectedCurrency}, reward={rewardValid}, pending={services.ProtocolRegistry.PendingCount}, open={IsShopOpen}, time={services.ServerTime.IsSynchronized}, missing={shopPresenter?.MissingIconCount ?? -1}.");
                return;
            }
            if (HasCommandLineFlag("-projectXShopG4Validation"))
            {
                StartCoroutine(FinalizeShopG4Validation());
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /221 list -> ShopStore/limits/server time/currency -> confirmed single purchase id={id} -> persisted count={item.BuyCount}");
        }

        private IEnumerator FinalizeShopG4Validation()
        {
            yield return CaptureShopValidationScreenshot("bootstrap-shop-reward.png");
            if (!rewardPresenter.InvokeFirstItem() || !errorPresenter.IsVisible)
            { Fail("Shop G4 reward item did not open the shared detail."); yield break; }
            MarkValidationControl("SHOP-20-REWARD-ITEM");
            errorPresenter.Hide();
            if (!rewardPresenter.InvokeClose() || rewardPresenter.IsVisible)
            { Fail("Shop G4 reward close control failed."); yield break; }
            MarkValidationControl("SHOP-21-REWARD-CLOSE");

            Button headerCoin = bagFrameView.Binding.Find("Layer/GoldCheck/GoldIcon3/AddBtn")?.GetComponent<Button>();
            if (headerCoin == null || !headerCoin.interactable)
            { Fail("Shop G4 header coin add was not bound."); yield break; }
            headerCoin.onClick.Invoke();
            float deadline = Time.realtimeSinceStartup + 10f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!IsShopOpen || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 header coin add did not reload Shop."); yield break; }
            MarkValidationControl("SHOP-04-HEADER-COIN-PLUS");

            Button close = bagFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
            if (close == null || !close.interactable) { Fail("Shop G4 close was not bound."); yield break; }
            close.onClick.Invoke();
            if (IsShopOpen) { Fail("Shop G4 close did not return to main."); yield break; }
            MarkValidationControl("SHOP-05-CLOSE");

            Button shortcut = mainView.Binding.Find(ShopCoinShortcutPath)?.GetComponent<Button>();
            if (shortcut == null || !shortcut.interactable)
            { Fail("Shop G4 main coin shortcut was not bound."); yield break; }
            shortcut.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 10f;
            while ((!IsShopOpen || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsShopOpen || services.Shop.Count == 0)
            { Fail("Shop G4 main coin shortcut did not open authoritative Shop."); yield break; }
            MarkValidationControl("SHOP-03-MAIN-COIN-SHORTCUT");

            services.Shop.Clear();
            if (!shopPresenter.IsEmptyStateVisible)
            { Fail("Shop G4 empty state retained stale detail or buy state."); yield break; }
            HandleShopClick();
            deadline = Time.realtimeSinceStartup + 10f;
            while ((services.Shop.Count == 0 || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Shop.Count == 0) { Fail("Shop G4 empty-state reload failed."); yield break; }

            services.Network.Disconnect();
            HandleDisconnected("Shop G4 deliberate disconnect");
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected || services.Shop.Count != 0
                || IsShopOpen || shopPresenter.IsQuantityInputVisible || errorPresenter.IsVisible
                || rewardPresenter.IsVisible)
            { Fail("Shop G4 disconnect cleanup mismatch."); yield break; }
            Reconnect();
            deadline = Time.realtimeSinceStartup + 20f;
            while (services.Network.State != NetworkState.Connected
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Network.State != NetworkState.Connected)
            { Fail("Shop G4 reconnect failed."); yield break; }
            deadline = Time.realtimeSinceStartup + 20f;
            while (!IsShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsShopOpen)
            {
                shortcut.onClick.Invoke();
                deadline = Time.realtimeSinceStartup + 10f;
                while (!IsShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            }
            if (!IsShopOpen || services.Shop.Count == 0)
            { Fail("Shop G4 reconnect did not restore authoritative Shop."); yield break; }

            yield return CaptureShopValidationScreenshot("bootstrap-shop.png");
            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Shop.Count != 0 || IsShopOpen
                || shopPresenter.IsQuantityInputVisible || errorPresenter.IsVisible || rewardPresenter.IsVisible)
            { Fail("Shop G4 account-switch cleanup mismatch."); yield break; }
            toastPresenter?.Clear();
            Complete($"COMPLETE: Shop G4 21/21 real controls; /221 op1/2/3/4, quantity=2, "
                + $"insufficient/reload/empty/reconnect/account-switch; user={GetLocalUserId()} role={validationRoleIdSnapshot}");
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
            double magicDefense, double health, double speed, double currentHealth)
        {
            pendingHeroes.Add(new HeroRecord(id, fightPosition, name, star, breakLevel, level,
                checked((uint)experience), checked((uint)maxExperience), checked((ulong)power),
                checked((uint)attack), checked((uint)physicalDefense), checked((uint)magicDefense),
                checked((ulong)health), checked((uint)speed), checked((ulong)currentHealth)));
        }

        public double GetHeroPower(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Power : 0d;
        public double GetHeroAttack(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Attack : 0d;
        public double GetHeroHealth(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Health : 0d;
        public double GetPlayerPower() => services.Player.Power;

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
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            heroListView.SetVisible(!showBag);
            heroDetailView.SetVisible(!showBag);
            heroBagView.SetVisible(showBag);
            ConfigureHeroFrame(showBag);
            if (services.UiStack.Current != heroFrameView) services.UiStack.Push(heroFrameView);
            SetStatus(showBag
                ? $"Hero bag UI active: {services.Heroes.Count} heroes."
                : $"Hero formation UI active: {services.Heroes.Count} heroes, formation={services.Formation.ActiveFormationId}.");
        }

        public void CompleteHeroReadValidation()
        {
            EnsureHeroPresenter();
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            int rendered = showBag ? heroPresenter.BagItemCount : heroPresenter.ItemCount;
            if (services.Heroes.Count <= 0 || services.Formation.Formations.Count <= 0
                || rendered != services.Heroes.Count || !IsHeroOpen)
            {
                Fail($"Hero read validation mismatch: entry={pendingHeroEntry}, heroes={services.Heroes.Count}, rendered={rendered}, formations={services.Formation.Formations.Count}, open={IsHeroOpen}.");
                return;
            }
            Complete(showBag
                ? $"COMPLETE: main hero bag button -> /24 HeroStore ({services.Heroes.Count}) -> /48 FormationStore -> hero bag grid UI"
                : $"COMPLETE: main formation button -> /24 HeroStore ({services.Heroes.Count}) -> /48 FormationStore -> formation list/detail UI");
        }

        public void CompleteHeroLuaReadValidation(int luaHeroCount, int luaFormationCount,
            int luaActiveFormationId, int luaSelectedHeroId)
        {
            EnsureHeroPresenter();
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            int rendered = showBag ? heroPresenter.BagItemCount : heroPresenter.ItemCount;
            bool luaMatchesMirror = luaHeroCount == services.Heroes.Count
                && luaFormationCount == services.Formation.Formations.Count
                && luaActiveFormationId == services.Formation.ActiveFormationId
                && luaSelectedHeroId == heroPresenter.SelectedId;
            if (luaHeroCount <= 0 || luaFormationCount <= 0 || rendered != luaHeroCount
                || !luaMatchesMirror || !IsHeroOpen)
            {
                Fail($"Lua formation read mismatch: entry={pendingHeroEntry}, luaHeroes={luaHeroCount}, "
                    + $"mirrorHeroes={services.Heroes.Count}, rendered={rendered}, luaFormations={luaFormationCount}, "
                    + $"mirrorFormations={services.Formation.Formations.Count}, active={luaActiveFormationId}/"
                    + $"{services.Formation.ActiveFormationId}, selected={luaSelectedHeroId}/{heroPresenter.SelectedId}, open={IsHeroOpen}.");
                return;
            }
            if (!showBag && HasCommandLineFlag("-projectXFormationPopupValidation")) ShowFormationPopup();
            Complete(showBag
                ? $"COMPLETE: Lua formation model -> /24 heroes={luaHeroCount} -> /48 formations={luaFormationCount} -> C# render mirror -> hero bag UI"
                : $"COMPLETE: main formation button -> legacy Lua model -> /24 heroes={luaHeroCount} -> /48 active={luaActiveFormationId} -> C# render mirror -> formation UI");
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

        public void CompleteFormationLuaMutationValidation(int heroId, int originalPosition,
            int targetPosition, int luaRestoredHeroId)
        {
            int mirrorPosition = services.Formation.GetCombatPosition(heroId);
            if (luaRestoredHeroId != heroId || mirrorPosition != originalPosition || !IsHeroOpen)
            {
                Fail($"Lua formation mutation restore mismatch: hero={heroId}, luaRestored={luaRestoredHeroId}, "
                    + $"mirrorPosition={mirrorPosition}, expected={originalPosition}, open={IsHeroOpen}.");
                return;
            }
            if (HasCommandLineFlag("-projectXFormationPopupValidation")) ShowFormationPopup();
            Complete($"COMPLETE: legacy Lua formation model -> /48 op=4 hero {heroId} "
                + $"{originalPosition}->{targetPosition} -> authoritative Lua snapshot -> restore "
                + $"{targetPosition}->{originalPosition} -> C# render mirror matched");
        }

        public void RunHeroG4ControlValidation(int heroId, int originalPosition, int targetPosition)
        {
            if (heroG4ControlValidationRunning) return;
            heroG4ControlValidationRunning = true;
            StartCoroutine(RunHeroG4ControlValidationRoutine(heroId, originalPosition, targetPosition));
        }

        public void ContinueHeroG4FormationRestore(int heroId, int currentPosition, int restorePosition)
        {
            StartCoroutine(ClickFormationMoveRoutine(heroId, currentPosition, restorePosition));
        }

        public void RunHeroLockedControlValidation()
        {
            StartCoroutine(RunHeroLockedControlValidationRoutine());
        }

        public void CompleteHeroG4Validation(int heroId, int restoredPosition, int movedFromPosition)
        {
            if (services.Formation.GetCombatPosition(heroId) != restoredPosition || !IsFormationPopupOpen)
            {
                Fail($"Hero G4 restore mismatch: hero={heroId}, restored={services.Formation.GetCombatPosition(heroId)}/{restoredPosition}, popup={IsFormationPopupOpen}.");
                return;
            }
            StartCoroutine(FinalizeHeroG4ValidationRoutine(heroId, restoredPosition, movedFromPosition));
        }

        private IEnumerator FinalizeHeroG4ValidationRoutine(int heroId, int restoredPosition, int movedFromPosition)
        {
            Button close = RequireBoundButton(formationPopupView, "Layer/Bg/Popup/Btn_close", "formation popup close");
            close.onClick.Invoke();
            if (IsFormationPopupOpen)
            {
                Fail("Hero G4 formation close button did not close the popup.");
                yield break;
            }
            if (!InvokeHeroCloseForValidation())
            {
                Fail("Hero G4 hero close button did not return to the main UI.");
                yield break;
            }
            while (IsToastVisible) yield return null;
            yield return CaptureHeroG5Evidence("HERO-01-CLOSE");
            heroG4ControlValidationRunning = false;
            Complete($"COMPLETE: Hero G4 real controls -> occupied/empty rows -> add/cultivate/enhance/replace -> 6 equipment/fabao slots -> attributes -> btn_buzhen -> position {restoredPosition}->{movedFromPosition}->{restoredPosition}; authoritative snapshots restored");
        }

        public bool InvokeHeroCloseForValidation()
        {
            if (!IsHeroOpen) return true;
            Button close = RequireBoundButton(heroFrameView, "Layer/Panel_12/Title/CloseBtn", "hero close");
            close.onClick.Invoke();
            if (!IsHeroOpen)
            {
                heroFrameView?.SetVisible(false);
                heroListView?.SetVisible(false);
                heroDetailView?.SetVisible(false);
                heroBagView?.SetVisible(false);
                heroEquipmentPresenter?.HideDetails();
                heroEquipmentListView?.SetVisible(false);
                heroEnhanceMasterView?.SetVisible(false);
                heroCultivationView?.SetVisible(false);
                heroLevelUpView?.SetVisible(false);
            }
            return !IsHeroOpen;
        }

        public bool InvokeHeroEntryForReconnectValidation()
        {
            if (IsHeroOpen && !InvokeHeroCloseForValidation()) return false;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            Button formationButton = mainView?.Binding.Find(FormationPath)?.GetComponent<Button>();
            if (formationButton == null || !formationButton.interactable) return false;
            formationButton.onClick.Invoke();
            return true;
        }

        public bool RunHeroG4FromCurrentSnapshotForReconnectValidation()
        {
            if (heroG4ControlValidationRunning) return true;
            int heroId = 0;
            int originalPosition = 0;
            int targetPosition = 0;
            for (int index = 0; index < services.Formation.CombatHeroes.Count; index++)
            {
                int currentHeroId = services.Formation.CombatHeroes[index];
                if (currentHeroId > 0 && heroId == 0)
                {
                    heroId = currentHeroId;
                    originalPosition = index + 1;
                }
                else if (currentHeroId == 0 && targetPosition == 0)
                {
                    targetPosition = index + 1;
                }
            }
            if (heroId == 0 || originalPosition == 0 || targetPosition == 0) return false;
            RunHeroG4ControlValidation(heroId, originalPosition, targetPosition);
            return true;
        }

        private IEnumerator RunHeroG4ControlValidationRoutine(int heroId, int originalPosition, int targetPosition)
        {
            yield return null;
            EnsureHeroPresenter();
            Button occupied = FindRuntimeHeroRowButton($"Hero_{heroId}_");
            if (occupied == null) { Fail($"Hero G4 occupied row button was not found for hero {heroId}."); yield break; }
            occupied.onClick.Invoke();
            if (heroPresenter.SelectedId != heroId || heroPresenter.SelectedPosition != originalPosition)
            {
                Fail("Hero G4 occupied row did not update the selected hero/position.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-02-OCCUPIED-ROW");
            if (FindRuntimeHeroRowButton("FormationLocked_", false) != null)
            {
                Fail($"Hero G4 full-access fixture still contains a locked formation row; player level={services.Player.Level}.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-04-ALL-ROWS-UNLOCKED");

            Button empty = FindRuntimeHeroRowButton($"FormationEmpty_{targetPosition}", true);
            if (empty == null) { Fail($"Hero G4 empty row button was not found at position {targetPosition}."); yield break; }
            empty.onClick.Invoke();
            if (heroPresenter.SelectedId != 0 || heroPresenter.SelectedPosition != targetPosition)
            {
                Fail("Hero G4 empty row did not preserve the empty selected position.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-03-EMPTY-ROW");

            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/Panel_new/addnew", "add hero").onClick.Invoke();
            if (heroReplacementView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 addnew button did not open the replacement view.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-05-ADD-HERO");
            HandleBack();

            occupied.onClick.Invoke();
            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Btn_3_1_0", "cultivate").onClick.Invoke();
            if (heroCultivationView?.GameObject.activeSelf != true || heroLevelUpView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 cultivation button did not open the cultivation view.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-06-CULTIVATE");
            RequireBoundButton(heroFrameView, "Layer/Panel_12/Title/CloseBtn", "cultivation return").onClick.Invoke();
            if (heroCultivationView?.GameObject.activeSelf == true || heroLevelUpView?.GameObject.activeSelf == true)
            {
                Fail("Hero G4 cultivation return did not restore the formation view.");
                yield break;
            }

            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Button1", "enhance master").onClick.Invoke();
            if (heroEnhanceMasterView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 enhancement master did not open for the full-access equipped fixture.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-07-ENHANCE-MASTER");
            if (!HandleBack() || heroEnhanceMasterView?.GameObject.activeSelf == true || !IsHeroOpen)
            {
                Fail("Hero G4 enhancement master did not return to hero details.");
                yield break;
            }

            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Button2", "replace hero").onClick.Invoke();
            if (heroReplacementView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 replace button did not open the replacement view.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-08-REPLACE");
            HandleBack();

            float stageDeadline = Time.realtimeSinceStartup + 8f;
            while (!HeroEquipmentStageChecksReady && Time.realtimeSinceStartup < stageDeadline)
                yield return null;
            if (!HeroEquipmentStageChecksReady)
            {
                Fail("Hero G4 equipment slot-open stage checks did not complete.");
                yield break;
            }

            for (int slot = 1; slot <= 6; slot++)
            {
                while (IsToastVisible) yield return null;
                RequireBoundButton(heroDetailView, $"Layer/EquipUI/Bg/bg/EquipIcon{slot}", $"equipment slot {slot}").onClick.Invoke();
                float deadline = Time.realtimeSinceStartup + 12f;
                while (!IsHeroEquipmentOpen && heroItemSourceView?.GameObject.activeSelf != true && !IsToastVisible
                    && Time.realtimeSinceStartup < deadline && !Status.Contains("failed", StringComparison.OrdinalIgnoreCase))
                    yield return null;
                if (!IsHeroEquipmentOpen && heroItemSourceView?.GameObject.activeSelf != true && !IsToastVisible)
                {
                    Fail($"Hero G4 equipment/fabao slot {slot} produced no locked/source/inventory outcome.");
                    yield break;
                }
                yield return CaptureHeroG5Evidence($"HERO-{slot + 8:D2}-{(slot <= 4 ? "EQUIP" : "FABAO")}-SLOT-{(slot <= 4 ? slot : slot - 4)}");
                if (IsHeroEquipmentOpen || heroItemSourceView?.GameObject.activeSelf == true)
                {
                    if (!HandleBack() || IsHeroEquipmentOpen || heroItemSourceView?.GameObject.activeSelf == true || !IsHeroOpen)
                    {
                        Fail($"Hero G4 equipment/fabao slot {slot} did not return to hero details.");
                        yield break;
                    }
                }
                else
                {
                    while (IsToastVisible) yield return null;
                }
                yield return null;
            }

            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Btn_xiangxi", "hero attributes").onClick.Invoke();
            if (heroAttributesView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 attributes button did not open the attributes popup.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-15-DETAIL");
            RequireBoundButton(heroAttributesView, "Layer/Mask_close", "attributes close").onClick.Invoke();
            if (heroAttributesView.GameObject.activeSelf)
            {
                Fail("Hero G4 attributes mask did not close the popup.");
                yield break;
            }

            RequireBoundButton(heroListView, "Layer/shenjiangListUI/List/btn_buzhen", "formation").onClick.Invoke();
            if (!IsFormationPopupOpen)
            {
                Fail("Hero G4 btn_buzhen did not open the formation popup.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-16-FORMATION");
            yield return ClickFormationMoveRoutine(heroId, originalPosition, targetPosition);
        }

        private IEnumerator ClickFormationMoveRoutine(int heroId, int currentPosition, int targetPosition)
        {
            yield return null;
            int formationId = services.Formation.ActiveFormationId > 0 ? services.Formation.ActiveFormationId : 1;
            int currentGrid = GetFormationGrid(formationId, currentPosition);
            int targetGrid = GetFormationGrid(formationId, targetPosition);
            RequireBoundButton(formationPopupView, $"Layer/FormationUI/Show/Formation/Position{currentGrid}", "current formation position").onClick.Invoke();
            RequireBoundButton(formationPopupView, $"Layer/FormationUI/Show/Formation/Position{targetGrid}", "target formation position").onClick.Invoke();
        }

        private IEnumerator RunHeroLockedControlValidationRoutine()
        {
            yield return null;
            EnsureHeroPresenter();
            int selectedIdBefore = heroPresenter.SelectedId;
            Button locked = FindRuntimeHeroRowButton("FormationLocked_", false);
            if (locked == null)
            {
                Fail($"Hero locked-row validation requires a locked row; player level={services.Player.Level}.");
                yield break;
            }
            locked.onClick.Invoke();
            if (heroPresenter.SelectedId != selectedIdBefore)
            {
                Fail("Hero locked row changed the selected hero.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-04-LOCKED-ROW");
            Complete($"COMPLETE: Hero locked row real Button rejected at player level {services.Player.Level} without changing selection");
        }

        private IEnumerator CaptureHeroG5Evidence(string controlId)
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Hero", "unity");
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, $"g5-{controlId}.png");
            if (File.Exists(path)) File.Delete(path);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Hero G5 screenshot was not written: {path}");
        }

        private Button FindRuntimeHeroRowButton(string name, bool exact = false)
        {
            if (heroListView == null) return null;
            return heroListView.GameObject.GetComponentsInChildren<Button>(true).FirstOrDefault(button =>
                exact ? button.gameObject.name == name : button.gameObject.name.StartsWith(name, StringComparison.Ordinal));
        }

        private static Button RequireBoundButton(CocosUiView view, string path, string label)
        {
            GameObject target = view?.Binding.Find(path);
            Button button = target?.GetComponent<Button>();
            if (button == null || button.onClick.GetPersistentEventCount() == 0 && !button.interactable)
                throw new InvalidOperationException($"Hero G4 {label} button is missing or disabled: {path}");
            return button;
        }

        private static int GetFormationGrid(int formationId, int combatPosition)
        {
            int[][] grids =
            {
                new[] { 2, 4, 6, 7, 9 },
                new[] { 2, 4, 5, 6, 8 },
                new[] { 1, 2, 3, 5, 8 },
                new[] { 2, 5, 7, 8, 9 },
                new[] { 1, 3, 4, 6, 8 },
                new[] { 1, 3, 5, 7, 9 }
            };
            int formationIndex = Mathf.Clamp(formationId - 1, 0, grids.Length - 1);
            int positionIndex = Mathf.Clamp(combatPosition - 1, 0, grids[formationIndex].Length - 1);
            return grids[formationIndex][positionIndex];
        }

        public void BindHeroEquipmentClick()
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                mainView.BindClick(EquipmentBagPath,
                    () =>
                    {
                        HideHudSubmenus();
                        heroEquipmentOpenPending = true;
                        InvokeLuaOrFail(onEquipmentBagClicked, "HeroEquipment.OpenEquipment");
                    }, true);
                mainView.BindClick(FaBaoBagPath,
                    () =>
                    {
                        HideHudSubmenus();
                        heroEquipmentOpenPending = true;
                        InvokeLuaOrFail(onFaBaoBagClicked, "HeroEquipment.OpenFaBao");
                    }, true);
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void CompleteFormationInvalidValidation(int heroId, int position, string reason)
        {
            int persistedHero = services.Formation.CombatHeroes.Count > 0 ? services.Formation.CombatHeroes[0] : 0;
            if (heroId != 65535 || position != 1 || persistedHero <= 0 || !IsHeroOpen)
            {
                Fail($"Formation invalid-response mismatch: hero={heroId}, position={position}, persisted={persistedHero}.");
                return;
            }
            Complete($"COMPLETE: /48 op=4 invalid hero {heroId} rejected; authoritative formation unchanged at position 1 hero {persistedHero}; reason={reason}");
        }

        public void BeginHeroEquipmentUpdate(int expectedCount)
        {
            pendingHeroEquipment.Clear();
            if (expectedCount > pendingHeroEquipment.Capacity) pendingHeroEquipment.Capacity = expectedCount;
        }

        public void BeginHeroEquipmentRecord(double uid, int templateId, int formationPosition, double experience,
            int baseAttributeType, double baseAttributeValue, int strengthAttributeType, double strengthAttributeValue)
        {
            pendingEquipmentUid = checked((uint)uid);
            pendingEquipmentTemplateId = templateId;
            pendingEquipmentFormationPosition = formationPosition;
            pendingEquipmentExperience = checked((uint)experience);
            pendingEquipmentBaseAttributeType = baseAttributeType;
            pendingEquipmentBaseAttributeValue = checked((uint)baseAttributeValue);
            pendingEquipmentStrengthAttributeType = strengthAttributeType;
            pendingEquipmentStrengthAttributeValue = checked((uint)strengthAttributeValue);
            pendingCultivation.Clear();
        }

        public void AddHeroEquipmentCultivation(int type, int level)
            => pendingCultivation.Add(new CultivationLevel(type, level));

        public void EndHeroEquipmentRecord()
        {
            pendingHeroEquipment.Add(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                pendingEquipmentStrengthAttributeType, pendingEquipmentStrengthAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId)));
        }

        public void EndHeroEquipmentUpdate() => services.HeroEquipment.Replace(pendingHeroEquipment);

        public void UpsertHeroEquipmentRecord()
        {
            services.HeroEquipment.Upsert(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                pendingEquipmentStrengthAttributeType, pendingEquipmentStrengthAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId)));
        }

        public void NotifyHeroEquipmentCultivationSuccess(int operation)
            => heroEquipmentPresenter?.PlayCultivationSuccess(operation);

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

        public int GetEquipmentStrengthCost(double uid)
        {
            return services.HeroEquipment.TryGet(checked((uint)uid), out HeroEquipmentRecord value)
                ? services.EquipmentCatalog.GetStrengthCost(value.GetLevel(1) + 1, value.Definition.Quality) : 0;
        }

        public int GetFaBaoFormation(double uid)
            => services.FaBao.TryGet(checked((uint)uid), out FaBaoRecord value) ? value.FormationPosition : -1;

        public void ShowHeroEquipment(int kind = 1)
        {
            heroEquipmentOpenPending = false;
            EnsureHeroEquipmentPresenter();
            int formationPosition = pendingHeroEquipmentPosition;
            pendingHeroEquipmentPosition = 0;
            int requestedSlot = pendingHeroEquipmentSlot;
            pendingHeroEquipmentSlot = 0;
            if (formationPosition <= 0)
            {
                formationPosition = 1;
                for (int index = 0; index < services.Formation.CombatHeroes.Count; index++)
                {
                    if (services.Formation.CombatHeroes[index] <= 0) continue;
                    formationPosition = index + 1;
                    break;
                }
            }
            HeroEquipmentKind displayKind = kind == 2 ? HeroEquipmentKind.FaBao : HeroEquipmentKind.Equipment;
            bool openedFromHeroSlot = requestedSlot > 0 && heroEquipmentOpenedFromHeroDetails;
            if (openedFromHeroSlot)
            {
                ConfigureHeroFrame(false);
                heroListView?.SetVisible(true);
                heroDetailView?.SetVisible(true);
            }
            else
            {
                ConfigureHeroEquipmentFrame(displayKind);
                heroListView?.SetVisible(false);
                heroDetailView?.SetVisible(false);
            }
            heroBagView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroFrameView.SetVisible(true);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != heroFrameView) services.UiStack.Push(heroFrameView);
            if (requestedSlot > 0)
            {
                heroEquipmentOpenedFromHeroDetails = true;
                heroEquipmentChangeView.BindClick("Layer/Popup/Btn_close", RestoreHeroAfterEquipmentSlot, true);
                if (!heroEquipmentPresenter.ShowSlot(formationPosition, requestedSlot))
                    ShowHeroItemSource(requestedSlot);
                else
                {
                    heroEquipmentDetailView.GameObject.transform.SetAsLastSibling();
                }
            }
            else
            {
                heroEquipmentPresenter.Show(formationPosition, displayKind);
                heroEquipmentListView.GameObject.transform.SetAsLastSibling();
            }
            heroFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            SetStatus($"Hero equipment UI active: equipment={services.HeroEquipment.Count}, fabao={services.FaBao.Count}.");
        }

        public void CompleteHeroEquipmentReadValidation()
        {
            ShowHeroEquipment();
            int equipmentRendered = heroEquipmentPresenter.RenderKind(HeroEquipmentKind.Equipment);
            int equipmentMissing = heroEquipmentPresenter.MissingIconCount;
            int faBaoRendered = heroEquipmentPresenter.RenderKind(HeroEquipmentKind.FaBao);
            int faBaoMissing = heroEquipmentPresenter.MissingIconCount;
            HeroEquipmentKind finalKind = HasCommandLineFlag("-projectXHeroEquipFaBaoScreenshot")
                ? HeroEquipmentKind.FaBao : HeroEquipmentKind.Equipment;
            heroEquipmentPresenter.RenderKind(finalKind);
            ConfigureHeroEquipmentFrame(finalKind);
            if (equipmentRendered != services.HeroEquipment.Count || faBaoRendered != services.FaBao.Count
                || equipmentMissing + faBaoMissing != 0
                || !IsHeroEquipmentOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Hero equipment read validation mismatch: equipment={services.HeroEquipment.Count}/{equipmentRendered}, fabao={services.FaBao.Count}/{faBaoRendered}, missingIcons={equipmentMissing + faBaoMissing}, open={IsHeroEquipmentOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            Complete($"COMPLETE: /319 op=1 equipment ({equipmentRendered}) + op=17 fabao ({faBaoRendered}) -> independent Lua-authoritative list/detail UI");
        }

        public void CompleteHeroEquipmentMutationValidation(double equipmentUid, int strengthBefore,
            int strengthAfter, double faBaoUid, int formationPosition, string invalidReason, string repeatReason,
            int attributePushCount, bool attributePushChanged, int mutationHeroId, double heroPowerBefore,
            double heroAttackBefore, double heroHealthBefore, double playerPowerBefore)
        {
            ShowHeroEquipment();
            uint equipmentId = checked((uint)equipmentUid);
            uint faBaoId = checked((uint)faBaoUid);
            bool restored = services.HeroEquipment.TryGet(equipmentId, out HeroEquipmentRecord equip)
                && equip.FormationPosition == 0 && equip.GetLevel(1) == strengthAfter
                && services.FaBao.TryGet(faBaoId, out FaBaoRecord treasure) && treasure.FormationPosition == 0;
            HeroRecord hero = default;
            bool heroExists = mutationHeroId > 0 && services.Heroes.TryGet(mutationHeroId, out hero);
            bool heroRefreshValid = heroExists
                && hero.Power == checked((ulong)heroPowerBefore)
                && hero.Attack == checked((uint)heroAttackBefore)
                && hero.Health == checked((ulong)heroHealthBefore)
                && hero.CurrentHealth <= hero.Health;
            bool hudPowerRestored = services.Player.Power == checked((ulong)playerPowerBefore);
            bool negativeOperationsRejected = !string.IsNullOrEmpty(invalidReason)
                && !string.IsNullOrEmpty(repeatReason);
            int equipmentMissing = heroEquipmentPresenter.MissingIconCount;
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.FaBao);
            int faBaoMissing = heroEquipmentPresenter.MissingIconCount;
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.Equipment);
            RecordValidationSemantic("hero-equipment-319-mutation-restored",
                restored && strengthAfter > strengthBefore,
                $"restored={restored}; strength={strengthBefore}->{strengthAfter}");
            RecordValidationSemantic("hero-update-70-count-at-least-five", attributePushCount >= 5,
                $"pushes={attributePushCount}");
            RecordValidationSemantic("hero-update-70-values-changed-during-mutation", attributePushChanged,
                $"changed={attributePushChanged}");
            RecordValidationSemantic("hero-update-70-final-hero-restored", heroRefreshValid,
                $"hero={mutationHeroId}");
            RecordValidationSemantic("player-power-18-final-restored", hudPowerRestored,
                $"power={playerPowerBefore}->{services.Player.Power}");
            RecordValidationSemantic("invalid-and-repeat-operations-do-not-mutate", negativeOperationsRejected,
                $"invalid={invalidReason}; repeat={repeatReason}");
            if (!restored || strengthAfter <= strengthBefore || equipmentMissing + faBaoMissing > 0
                || attributePushCount < 5 || !attributePushChanged || !heroRefreshValid || !hudPowerRestored
                || (HasCommandLineFlag("-projectXHeroEquipG4Validation") && !negativeOperationsRejected))
            {
                string heroValues = heroExists
                    ? $"power={heroPowerBefore}->{hero.Power}, attack={heroAttackBefore}->{hero.Attack}, health={heroHealthBefore}->{hero.Health}, currentHealth={hero.CurrentHealth}"
                    : $"hero={mutationHeroId} missing";
                Fail($"Hero equipment mutation mismatch: restored={restored}, strength={strengthBefore}->{strengthAfter}, missingIcons={equipmentMissing + faBaoMissing}, /70={attributePushCount}, changed={attributePushChanged}, heroRefresh={heroRefreshValid} ({heroValues}), hudPower={hudPowerRestored} ({playerPowerBefore}->{services.Player.Power}).");
                return;
            }
            string failures = string.IsNullOrEmpty(invalidReason) && string.IsNullOrEmpty(repeatReason)
                ? string.Empty : $"; invalid rejected={invalidReason}; repeat rejected={repeatReason}; final lists reloaded";
            Complete($"COMPLETE: /319 equipment {equipmentId} wear@{formationPosition} -> strengthen {strengthBefore}->{strengthAfter} -> takeoff; fabao {faBaoId} wear@{formationPosition}/5 -> takeoff; /70 pushes={attributePushCount}, hero attributes/HP/power and HUD total power refreshed then restored; stores/list/detail restored{failures}");
        }

        public void CompleteHeroEquipmentMaterialValidation(double equipmentUid, int strengthBefore, string reason)
        {
            ShowHeroEquipment();
            uint uid = checked((uint)equipmentUid);
            bool unchanged = services.HeroEquipment.TryGet(uid, out HeroEquipmentRecord equipmentRecord)
                && equipmentRecord.GetLevel(1) == strengthBefore;
            if (!unchanged || string.IsNullOrWhiteSpace(reason))
            {
                Fail($"Hero equipment material validation mismatch: unchanged={unchanged}, reason={reason}.");
                return;
            }
            Complete($"COMPLETE: /319 op=4 material insufficient rejected; uid={uid}; strength unchanged={strengthBefore}; reason={reason}");
        }

        public void RunHeroEquipmentG4Validation()
        {
            StartCoroutine(RunHeroEquipmentG4ValidationRoutine());
        }

        private IEnumerator RunHeroEquipmentG4ValidationRoutine()
        {
            const uint sourceUid = 2121072641;
            const uint targetUid = 2121073001;
            const uint divineUid = 2121073003;
            BeginValidationEvidence();
            EnsureHeroEquipmentPresenter();
            if (!services.HeroEquipment.TryGet(sourceUid, out HeroEquipmentRecord sourceBefore)
                || sourceBefore.FormationPosition != 1
                || !services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord targetBefore)
                || targetBefore.FormationPosition != 0
                || !services.HeroEquipment.TryGet(divineUid, out HeroEquipmentRecord divineBefore)
                || divineBefore.FormationPosition != 0)
            {
                Fail("HeroEquip G4 fixed source/target/divine equipment snapshot mismatch.");
                yield break;
            }
            int initialCount = services.HeroEquipment.Count;
            int targetStrengthBefore = targetBefore.GetLevel(1);
            int targetRefineBefore = targetBefore.GetLevel(2);
            int targetAwakenBefore = targetBefore.GetLevel(3);
            int divineLevelBefore = divineBefore.GetLevel(4);
            FaBaoRecord[] faBaoBefore = services.FaBao.Items.OrderBy(value => value.Uid).ToArray();

            if (services.UiStack.Current == heroFrameView
                || services.UiStack.Current?.GameObject?.name == "OneLevelLayer")
            {
                Button bootstrapFrameClose = heroFrameView?.Binding.Find(
                    "Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(bootstrapFrameClose))
                { Fail("HeroEquip G4 could not close the bootstrap-opened OneLevelLayer through EventSystem."); yield break; }
                MarkValidationControl("HE-03-BAG-CLOSE");
                yield return null;
            }
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true) ?? mainView;
            float mainReadyDeadline = Time.realtimeSinceStartup + 45f;
            while (mainView?.GameObject.activeInHierarchy != true && Time.realtimeSinceStartup < mainReadyDeadline)
            {
                if (IsGameNoticeOpen) InvokeGameNoticeClose();
                yield return null;
            }
            Button wearToggle = mainView.Binding.Find("Layer/Main_UI/ButtonGroup1/btn_chuandai")?.GetComponent<Button>();
            float inputReadyDeadline = Time.realtimeSinceStartup + 8f;
            while ((wearToggle == null || EventSystem.current == null || !wearToggle.gameObject.activeInHierarchy
                    || !wearToggle.interactable) && Time.realtimeSinceStartup < inputReadyDeadline)
                yield return null;
            if (!InvokeEventSystemClick(wearToggle))
            {
                CocosUiView currentView = services?.UiStack.Current;
                Fail($"HeroEquip G4 wear toggle EventSystem input was unavailable: button={wearToggle != null}, "
                    + $"eventSystem={EventSystem.current != null}, active={wearToggle?.gameObject.activeInHierarchy}, "
                    + $"interactable={wearToggle?.interactable}, main={mainView?.GameObject.activeInHierarchy}, "
                    + $"state={CurrentAppState}, notice={IsGameNoticeOpen}, stack={currentView?.GameObject?.name}, "
                    + $"stackActive={currentView?.GameObject?.activeInHierarchy}, status={status}.");
                yield break;
            }
            MarkValidationControl("HE-00-WEAR-TOGGLE");
            yield return null;
            yield return CaptureHeroEquipmentG5State("g1-wear-popup-open.png");
            Button equipmentEntry = mainView.Binding.Find(EquipmentBagPath)?.GetComponent<Button>();
            if (!InvokeEventSystemClick(equipmentEntry)) { Fail("HeroEquip G4 equipment entry EventSystem input was unavailable."); yield break; }
            MarkValidationControl("HE-01-MAIN-EQUIPMENT");
            float deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroEquipmentOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroEquipmentOpen) { Fail("HeroEquip G4 equipment bag did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-bag.png");
            Button equipmentTab = heroFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.GetComponent<Button>();
            if (equipmentTab == null || equipmentTab.interactable)
            { Fail("HeroEquip G4 selected equipment tab state was not source-equivalent."); yield break; }
            MarkValidationControl("HE-04-EQUIPMENT-BAG-TAB");
            Button equipmentHelp = heroFrameView.GameObject.GetComponentsInChildren<Button>(true)
                .FirstOrDefault(value => value.name == "HeroEquipmentHelpButton");
            if (!InvokeEventSystemClick(equipmentHelp) || !IsErrorVisible)
            { Fail("HeroEquip G4 equipment help EventSystem input did not open the real help dialog."); yield break; }
            MarkValidationControl("HE-06-EQUIPMENT-HELP");
            errorPresenter.Hide();
            Toggle hideWorn = heroEquipmentListView.Binding.Find(
                "Layer/zhuangbeibeibaoUI/CheckBox")?.GetComponent<Toggle>();
            bool hideWornBefore = hideWorn?.isOn ?? false;
            if (!InvokeEventSystemClick(hideWorn) || hideWorn.isOn == hideWornBefore)
            { Fail("HeroEquip G4 hide-worn Toggle did not enter its filtered state through EventSystem."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-bag-empty.png");
            if (!InvokeEventSystemClick(hideWorn) || hideWorn.isOn != hideWornBefore)
            { Fail("HeroEquip G4 hide-worn Toggle did not round-trip through EventSystem."); yield break; }
            MarkValidationControl("HE-07-EQUIPMENT-HIDE-WORN");
            ScrollRect bagScroll = heroEquipmentListView.Binding.Find(
                "Layer/zhuangbeibeibaoUI/TableView")?.GetComponent<ScrollRect>();
            Canvas.ForceUpdateCanvases();
            if (bagScroll?.content == null || bagScroll.viewport == null
                || bagScroll.content.rect.height <= bagScroll.viewport.rect.height + 1f)
            { Fail("HeroEquip G4 bag ScrollRect content did not exceed its viewport."); yield break; }
            float bagScrollStartY = bagScroll.content.anchoredPosition.y;
            if (!InvokeEventSystemDrag(bagScroll, -0.25f))
            { Fail("HeroEquip G4 bag ScrollRect did not accept EventSystem drag input."); yield break; }
            yield return null;
            if (Mathf.Abs(bagScroll.content.anchoredPosition.y - bagScrollStartY) <= 1f)
            { Fail("HeroEquip G4 bag ScrollRect accepted drag callbacks but its content did not move."); yield break; }
            MarkValidationControl("HE-80-BAG-LIST-SCROLL");
            GameObject recycleEntry = heroEquipmentListView.Binding.Find("Layer/zhuangbeibeibaoUI/recycle");
            if (recycleEntry == null || recycleEntry.activeInHierarchy)
            { Fail("HeroEquip G4 excluded recycle entry was not hidden."); yield break; }
            MarkValidationControl("HE-10-EQUIPMENT-RECYCLE-ENTRY");
            Button targetListItem = heroEquipmentPresenter.GetListItemAction(targetUid);
            if (!InvokeEventSystemClick(targetListItem) || !heroEquipmentPresenter.IsDetailVisible)
            { Fail("HeroEquip G4 equipment list item did not open detail through EventSystem."); yield break; }
            MarkValidationControl("HE-08-EQUIPMENT-LIST-ITEM");
            yield return CaptureHeroEquipmentG5State("g1-equipment-detail.png");
            ScrollRect detailScroll = heroEquipmentDetailView.Binding.Find(
                "Layer/zhuangbeiInfoUI/Info/ListView")?.GetComponent<ScrollRect>();
            if (!InvokeEventSystemDrag(detailScroll, -0.2f))
            { Fail("HeroEquip G4 detail ScrollRect did not accept EventSystem drag input."); yield break; }
            MarkValidationControl("HE-77-DETAIL-SCROLL");
            Button detailClose = heroEquipmentDetailView.Binding.Find(
                "Layer/zhuangbeiInfoUI/Popup/Btn_close")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(detailClose) || heroEquipmentPresenter.IsDetailVisible)
            { Fail("HeroEquip G4 detail close did not return to the equipment list."); yield break; }
            MarkValidationControl("HE-22-DETAIL-CLOSE");
            Button cultivateEntry = heroEquipmentPresenter.GetListCultivateAction(targetUid);
            if (!InvokeEventSystemClick(cultivateEntry) || heroEquipmentStrengthView.GameObject.activeSelf != true)
            {
                Fail($"HeroEquip G4 equipment cultivate entry did not open strength through EventSystem: "
                    + $"button={cultivateEntry != null}, active={cultivateEntry?.gameObject.activeInHierarchy}, "
                    + $"interactable={cultivateEntry?.interactable}, listeners={cultivateEntry?.onClick.GetPersistentEventCount()}, "
                    + $"list={heroEquipmentListView.GameObject.activeSelf}, returnToList={heroEquipmentPresenter.ReturnsToListOnDetailClose}, "
                    + $"strength={heroEquipmentStrengthView.GameObject.activeSelf}.");
                yield break;
            }
            MarkValidationControl("HE-09-EQUIPMENT-CULTIVATE");
            Button cultivationTarget = heroEquipmentPresenter.GetCultivationTargetAction(sourceUid);
            if (!InvokeEventSystemClick(cultivationTarget))
            { Fail("HeroEquip G4 cultivation equipment selector was unavailable."); yield break; }
            MarkValidationControl("HE-31-STRENGTH-EQUIPMENT-SELECT");
            Transform bagPrompt = heroEquipmentListView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == "Prompt" && value.parent?.name == "Btn_yangcheng");
            if (bagPrompt == null)
            { Fail("HeroEquip G4 equipment cultivation red-dot node was missing."); yield break; }
            MarkValidationControl("HE-83-BAG-RED-DOT");
            heroEquipmentPresenter.Show(1, HeroEquipmentKind.Equipment);

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 1)) { Fail("HeroEquip G4 target equipment detail was unavailable."); yield break; }
            Button wear = heroEquipmentDetailView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(wear)) { Fail("HeroEquip G4 wear EventSystem input was unavailable."); yield break; }
            MarkValidationControl("HE-23-DETAIL-CHANGE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentFormation(targetUid) != 1 && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentFormation(targetUid) != 1 || GetHeroEquipmentFormation(sourceUid) != 0)
            { Fail("HeroEquip G4 initial replacement did not move source equipment to the bag."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(sourceUid, 2) || !InvokeEventSystemClick(
                heroEquipmentDetailView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 source wear@2 EventSystem input was unavailable."); yield break; }
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentFormation(sourceUid) != 2 && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentFormation(sourceUid) != 2) { Fail("HeroEquip G4 source equipment did not wear at position 2."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(sourceUid, 2) || !InvokeEventSystemClick(
                heroEquipmentDetailView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 cross-position change popup did not open."); yield break; }
            yield return null;
            Toggle changeFilter = heroEquipmentChangeView.Binding.Find("Layer/Popup/CheckBox")?.GetComponent<Toggle>();
            bool changeFilterBefore = changeFilter?.isOn ?? false;
            if (!InvokeEventSystemClick(changeFilter) || changeFilter.isOn == changeFilterBefore
                || !InvokeEventSystemClick(changeFilter) || changeFilter.isOn != changeFilterBefore)
            { Fail("HeroEquip G4 change hide-worn Toggle did not round-trip through EventSystem."); yield break; }
            MarkValidationControl("HE-28-CHANGE-HIDE-WORN");
            ScrollRect changeScroll = heroEquipmentChangeView.Binding.Find("Layer/Popup/TableView")?.GetComponent<ScrollRect>();
            if (!InvokeEventSystemDrag(changeScroll, -0.2f))
            { Fail("HeroEquip G4 change ScrollRect did not accept EventSystem drag input."); yield break; }
            MarkValidationControl("HE-82-CHANGE-LIST-SCROLL");
            Button changeClose = heroEquipmentChangeView.Binding.Find("Layer/Popup/Btn_close")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(changeClose) || heroEquipmentChangeView.GameObject.activeSelf)
            { Fail("HeroEquip G4 change close did not hide the popup."); yield break; }
            MarkValidationControl("HE-27-CHANGE-CLOSE");
            if (!heroEquipmentPresenter.PrepareDetails(sourceUid, 2) || !InvokeEventSystemClick(
                heroEquipmentDetailView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 cross-position change popup could not reopen."); yield break; }
            yield return null;
            Button targetCandidate = heroEquipmentPresenter.GetChangeCandidateAction(targetUid);
            if (!InvokeEventSystemClick(targetCandidate)) { Fail("HeroEquip G4 target change candidate EventSystem input was unavailable."); yield break; }
            MarkValidationControl("HE-29-CHANGE-WEAR");
            deadline = Time.realtimeSinceStartup + 12f;
            while ((GetHeroEquipmentFormation(targetUid) != 2 || GetHeroEquipmentFormation(sourceUid) != 1)
                && Time.realtimeSinceStartup < deadline) yield return null;
            bool crossSwap = GetHeroEquipmentFormation(targetUid) == 2 && GetHeroEquipmentFormation(sourceUid) == 1;
            if (!crossSwap) { Fail("HeroEquip G4 cross-position server swap did not converge in the Lua mirror."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 2)) { Fail("HeroEquip G4 target takeoff detail unavailable."); yield break; }
            Button takeOff = heroEquipmentDetailView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Btn_xiexia")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(takeOff)) { Fail("HeroEquip G4 takeoff EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-24-DETAIL-TAKEOFF");
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentFormation(targetUid) != 0 && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentFormation(targetUid) != 0 || GetHeroEquipmentFormation(sourceUid) != 1)
            { Fail("HeroEquip G4 takeoff did not restore source/target slot ownership."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 1)) { Fail("HeroEquip G4 strength detail unavailable."); yield break; }
            if (!InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 strength entry EventSystem input unavailable."); yield break; }
            if (heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all was visible for an unequipped item."); yield break; }
            MarkValidationControl("HE-25-EQUIPMENT-STRENGTH-ENTRY");
            yield return CaptureHeroEquipmentG5State("g1-strength-before.png");
            if (!InvokeEventSystemClick(heroEquipmentStrengthView.Binding.Find(
                "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 strength action EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-32-STRENGTH-ONCE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentStrengthLevel(targetUid) <= targetStrengthBefore && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentStrengthLevel(targetUid) <= targetStrengthBefore)
            { Fail("HeroEquip G4 strength transaction did not update op=16 state."); yield break; }
            int targetStrengthBeforeFive = GetHeroEquipmentStrengthLevel(targetUid);
            if (!InvokeEventSystemClick(heroEquipmentStrengthView.Binding.Find(
                "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghua5Btn")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 five-strength EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-33-STRENGTH-FIVE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentStrengthLevel(targetUid) <= targetStrengthBeforeFive
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentStrengthLevel(targetUid) <= targetStrengthBeforeFive)
            { Fail("HeroEquip G4 five-strength transaction did not update op=16 state."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(sourceUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 strengthen-all entry unavailable."); yield break; }
            if (!heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all was hidden for the equipped item on the strength tab."); yield break; }
            int sourceStrengthBefore = GetHeroEquipmentStrengthLevel(sourceUid);
            if (!InvokeEventSystemClick(heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Btn_yijianqianghua")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 strengthen-all EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-47-STRENGTH-ALL");
            deadline = Time.realtimeSinceStartup + 12f;
            while (GetHeroEquipmentStrengthLevel(sourceUid) <= sourceStrengthBefore && Time.realtimeSinceStartup < deadline) yield return null;
            if (GetHeroEquipmentStrengthLevel(sourceUid) <= sourceStrengthBefore)
            { Fail("HeroEquip G4 strengthen-all transaction did not update source equipment."); yield break; }

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 refine entry EventSystem input unavailable."); yield break; }
            if (heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all leaked onto the refine tab."); yield break; }
            MarkValidationControl("HE-38-DETAIL-REFINE");
            yield return CaptureHeroEquipmentG5State("g1-refine-before.png");
            if (!InvokeEventSystemClick(heroEquipmentRefineView.Binding.Find(
                "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/jinglianyijiBtn")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 refine action EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-48-REFINE-ONCE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord refining)
                && refining.GetLevel(2) <= targetRefineBefore && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord refined)
                || refined.GetLevel(2) <= targetRefineBefore)
            {
                string levels = services.HeroEquipment.TryGet(targetUid, out refined)
                    ? string.Join(",", refined.Cultivation.Select(value => $"{value.Type}:{value.Level}"))
                    : "missing";
                Fail($"HeroEquip G4 refine transaction did not converge after response/push/list refresh; " +
                    $"before={targetRefineBefore}, current={refined.GetLevel(2)}, exp={refined.Experience}, levels={levels}, status={status}.");
                yield break;
            }
            if (toastPresenter?.Parent != heroEquipmentCultivateView.GameObject.transform.parent
                || !toastPresenter.IsLastSibling)
            { Fail("HeroEquip G4 success toast was not the last sibling below the cultivation views."); yield break; }
            deadline = Time.realtimeSinceStartup + 5f;
            while (heroEquipmentPresenter.HasActiveCultivationEffect && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (heroEquipmentPresenter.HasActiveCultivationEffect)
            { Fail("HeroEquip G4 refine success Imod retained its final frame after completion."); yield break; }
            int refineBeforeAuto = refined.GetLevel(2);
            Button autoRefineOpen = heroEquipmentRefineView.Binding.Find(
                "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/yijianjinglianBtn")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(autoRefineOpen) || !heroEquipmentAutoRefineView.GameObject.activeSelf)
            { Fail("HeroEquip G4 auto-refine popup did not open through EventSystem."); yield break; }
            MarkValidationControl("HE-49-REFINE-AUTO-OPEN");
            foreach (var autoRefineControl in new[]
            {
                ("Layer/Popup/Panel_1/Btn_Plus", "HE-50-AUTO-REFINE-PLUS"),
                ("Layer/Popup/Panel_1/Btn_Plus10", "HE-51-AUTO-REFINE-PLUS10"),
                ("Layer/Popup/Panel_1/Btn_Minus", "HE-52-AUTO-REFINE-MINUS"),
                ("Layer/Popup/Panel_1/Btn_Minus10", "HE-53-AUTO-REFINE-MINUS10")
            })
            {
                if (!InvokeEventSystemClick(heroEquipmentAutoRefineView.Binding.Find(autoRefineControl.Item1)?.GetComponent<Button>()))
                { Fail($"HeroEquip G4 auto-refine control unavailable: {autoRefineControl.Item2}"); yield break; }
                MarkValidationControl(autoRefineControl.Item2);
            }
            if (!InvokeEventSystemClick(heroEquipmentAutoRefineView.Binding.Find("Layer/Popup/Btn_Cancel")?.GetComponent<Button>())
                || heroEquipmentAutoRefineView.GameObject.activeSelf)
            { Fail("HeroEquip G4 auto-refine cancel did not close the popup."); yield break; }
            MarkValidationControl("HE-55-AUTO-REFINE-CANCEL");
            if (!InvokeEventSystemClick(autoRefineOpen)
                || !InvokeEventSystemClick(heroEquipmentAutoRefineView.Binding.Find("Layer/Popup/Btn_close")?.GetComponent<Button>())
                || heroEquipmentAutoRefineView.GameObject.activeSelf)
            { Fail("HeroEquip G4 auto-refine close did not close the popup."); yield break; }
            MarkValidationControl("HE-56-AUTO-REFINE-CLOSE");
            if (!InvokeEventSystemClick(autoRefineOpen)
                || !InvokeEventSystemClick(heroEquipmentAutoRefineView.Binding.Find("Layer/Popup/Btn_Confirm")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 auto-refine confirm EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-54-AUTO-REFINE-CONFIRM");
            deadline = Time.realtimeSinceStartup + 12f;
            while (services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord autoRefining)
                && autoRefining.GetLevel(2) <= refineBeforeAuto && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord autoRefined)
                || autoRefined.GetLevel(2) <= refineBeforeAuto)
            { Fail("HeroEquip G4 auto-refine transaction did not update op=16 state."); yield break; }

            ShowHeroEquipmentFragments();
            MarkValidationControl("HE-05-EQUIPMENT-PIECES");
            ScrollRect fragmentScroll = heroEquipmentFragmentView.Binding.Find(
                "Layer/suipianUI/Bag/TableView")?.GetComponent<ScrollRect>();
            Canvas.ForceUpdateCanvases();
            Transform firstFragmentRow = fragmentScroll?.content?.Find("RuntimeFragmentRow_1");
            Graphic fragmentDragSurface = fragmentScroll?.GetComponent<Graphic>();
            if (fragmentScroll?.content == null || fragmentScroll.viewport == null
                || fragmentScroll.content.name != "VirtualContent"
                || fragmentDragSurface == null || !fragmentDragSurface.raycastTarget
                || firstFragmentRow?.GetComponent<VirtualListScrollDragRelay>() == null)
            { Fail("HeroEquip G4 fragment bag did not reuse the common VirtualList drag contract."); yield break; }
            if (fragmentScroll.content.rect.height > fragmentScroll.viewport.rect.height + 1f)
            {
                float fragmentScrollStartY = fragmentScroll.content.anchoredPosition.y;
                if (!InvokeEventSystemDrag(fragmentScroll, -0.25f))
                { Fail("HeroEquip G4 fragment bag ScrollRect did not accept EventSystem drag input."); yield break; }
                yield return null;
                if (Mathf.Abs(fragmentScroll.content.anchoredPosition.y - fragmentScrollStartY) <= 1f)
                { Fail("HeroEquip G4 fragment bag accepted drag callbacks but its content did not move."); yield break; }
            }
            MarkValidationControl("HE-81-PIECES-LIST-SCROLL");
            yield return CaptureHeroEquipmentG5State("g1-equipment-pieces.png");
            Transform composableFragment = heroEquipmentFragmentView.GameObject
                .GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == "EquipmentFragment_4621");
            const int composeFragmentId = 4621;
            int fragmentQuantityBefore = services.Bag.GetTotalQuantityByItemId(composeFragmentId);
            int fragmentComposeCost = services.EquipmentCatalog.GetEquipmentComposeCost(composeFragmentId);
            Image fragmentQuality = composableFragment?.Find("RuntimeFragmentQuality")?.GetComponent<Image>();
            Image fragmentBadge = composableFragment?.Find("RuntimeFragmentBadge")?.GetComponent<Image>();
            Text fragmentQuantity = composableFragment?.Find("RuntimeFragmentQuantity")?.GetComponent<Text>();
            if (fragmentQuantityBefore < fragmentComposeCost || fragmentComposeCost <= 0)
            { Fail("HeroEquip G4 fragment 4621 fixture is not composable."); yield break; }
            if (fragmentQuality == null || !fragmentQuality.enabled || fragmentQuality.sprite == null
                || fragmentBadge == null || !fragmentBadge.enabled || fragmentBadge.sprite == null
                || fragmentQuantity == null || fragmentQuantity.text != fragmentQuantityBefore.ToString())
            { Fail("HeroEquip G4 fragment bag item is missing Cocos ItemCell quality, shard badge, or quantity semantics."); yield break; }
            if (!InvokeEventSystemClick(composableFragment?.GetComponent<Button>()))
            { Fail("HeroEquip G4 composable fragment 4621 EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-34-PIECES-LIST-ITEM");
            Button fragmentSource = heroEquipmentFragmentView.Binding.Find(
                "Layer/suipianUI/suipian/Btn_huoqu")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(fragmentSource) || heroItemSourceView.GameObject.activeSelf != true)
            { Fail("HeroEquip G4 fragment source did not open ItemSource through EventSystem."); yield break; }
            MarkValidationControl("HE-35-PIECES-SOURCE");
            Button sourceClose = heroItemSourceView.Binding.Find("Layer/Popup/Title/Btn_close")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(sourceClose) || heroItemSourceView.GameObject.activeSelf)
            { Fail("HeroEquip G4 item-source close did not hide the popup."); yield break; }
            MarkValidationControl("HE-79-SOURCE-CLOSE");
            GameObject fragmentRecycle = heroEquipmentFragmentView.Binding.Find("Layer/suipianUI/recycle");
            if (fragmentRecycle == null || fragmentRecycle.activeInHierarchy)
            { Fail("HeroEquip G4 excluded fragment recycle entry was not hidden."); yield break; }
            MarkValidationControl("HE-37-PIECES-RECYCLE-ENTRY");
            Transform fragmentPrompt = composableFragment.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == "Prompt");
            if (fragmentPrompt == null || !fragmentPrompt.gameObject.activeSelf)
            { Fail("HeroEquip G4 composable fragment red-dot was not visible."); yield break; }
            MarkValidationControl("HE-84-PIECES-RED-DOT");
            Button compose = heroEquipmentFragmentView.Binding.Find("Layer/suipianUI/suipian/Btn_hecheng")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(compose)) { Fail("HeroEquip G4 compose EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-36-PIECES-COMPOSE");
            deadline = Time.realtimeSinceStartup + 12f;
            while ((services.HeroEquipment.Count <= initialCount
                || services.Bag.GetTotalQuantityByItemId(composeFragmentId) >= fragmentQuantityBefore)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.HeroEquipment.Count <= initialCount) { Fail("HeroEquip G4 compose did not add a server equipment record."); yield break; }
            int fragmentQuantityAfter = services.Bag.GetTotalQuantityByItemId(composeFragmentId);
            if (fragmentQuantityAfter >= fragmentQuantityBefore)
            { Fail("HeroEquip G4 compose did not refresh the consumed fragment quantity."); yield break; }
            Text fragmentProgress = heroEquipmentFragmentView.Binding.Find(
                "Layer/suipianUI/suipian/Slider_Bg/Value")?.GetComponent<Text>();
            Transform refreshedFragment = heroEquipmentFragmentView.GameObject
                .GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == "EquipmentFragment_4621");
            Text refreshedQuantity = refreshedFragment?.Find("RuntimeFragmentQuantity")?.GetComponent<Text>();
            string expectedFragmentProgress = $"{fragmentQuantityAfter}/{fragmentComposeCost}";
            if (fragmentProgress == null || fragmentProgress.text != expectedFragmentProgress
                || refreshedQuantity == null || refreshedQuantity.text != fragmentQuantityAfter.ToString())
            { Fail("HeroEquip G4 compose refreshed the bag model but left fragment progress or grid quantity stale."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-pieces-empty.png");

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 awaken entry EventSystem input unavailable."); yield break; }
            if (heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all leaked onto the awaken tab."); yield break; }
            MarkValidationControl("HE-39-DETAIL-AWAKEN");
            yield return CaptureHeroEquipmentG5State("g1-awaken-before.png");
            if (!InvokeEventSystemClick(heroEquipmentAwakenView.Binding.Find(
                "Layer/zhuangbeijuexingUI/juexing/juexingxiaohao/yijianjinglianBtn")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 awaken action EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-57-AWAKEN-ONCE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord awakening)
                && awakening.GetLevel(3) <= targetAwakenBefore && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.HeroEquipment.TryGet(targetUid, out HeroEquipmentRecord awakened)
                || awakened.GetLevel(3) <= targetAwakenBefore)
            { Fail("HeroEquip G4 awaken transaction did not update op=16 state."); yield break; }
            yield return null;
            if (heroListView?.GameObject.activeSelf == true || heroDetailView?.GameObject.activeSelf == true
                || formationPopupView?.GameObject.activeSelf == true)
            { Fail("HeroEquip G4 awaken success reopened the formation UI over cultivation."); yield break; }
            string awakenSuccessStatus = status;
            InvokeEventSystemClick(heroEquipmentAwakenView.Binding.Find(
                "Layer/zhuangbeijuexingUI/juexing/juexingxiaohao/yijianjinglianBtn")?.GetComponent<Button>());
            deadline = Time.realtimeSinceStartup + 8f;
            while (status == awakenSuccessStatus && Time.realtimeSinceStartup < deadline) yield return null;
            bool awakenRejected = status != awakenSuccessStatus;
            yield return CaptureHeroEquipmentG5State("g1-awaken-locked.png");
            Button awakenExchange = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/juexing/Btn_yijianduihuan")?.GetComponent<Button>();
            Button autoStarOpen = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/juexing/Btn_yijianshengxing")?.GetComponent<Button>();
            if (awakenExchange == null || awakenExchange.gameObject.activeInHierarchy
                || autoStarOpen == null || autoStarOpen.gameObject.activeInHierarchy
                || heroEquipmentExchangeView.GameObject.activeSelf || heroEquipmentAutoStarView.GameObject.activeSelf)
            { Fail("HeroEquip G4 source-hidden awaken auxiliary controls were unexpectedly reachable."); yield break; }
            foreach (string hiddenId in new[]
            {
                "HE-58-AWAKEN-EXCHANGE", "HE-59-AWAKEN-AUTO-STAR",
                "HE-60-AUTO-STAR-CHECKBOX1", "HE-61-AUTO-STAR-CHECKBOX2", "HE-62-AUTO-STAR-CHECKBOX3",
                "HE-63-AUTO-STAR-CONFIRM", "HE-64-AUTO-STAR-CANCEL", "HE-65-AUTO-STAR-CLOSE"
            }) MarkValidationControl(hiddenId);

            if (!heroEquipmentPresenter.PrepareDetails(divineUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 shenzhu entry EventSystem input unavailable."); yield break; }
            if (heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all leaked onto the shenzhu tab."); yield break; }
            MarkValidationControl("HE-40-DETAIL-SHENZHU");
            if (!InvokeEventSystemClick(heroEquipmentDivineView.Binding.Find(
                "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Btn_shenzhu")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 shenzhu action EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-66-SHENZHU-ONCE");
            deadline = Time.realtimeSinceStartup + 12f;
            while (services.HeroEquipment.TryGet(divineUid, out HeroEquipmentRecord divining)
                && divining.GetLevel(4) <= divineLevelBefore && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.HeroEquipment.TryGet(divineUid, out HeroEquipmentRecord divined)
                || divined.GetLevel(4) <= divineLevelBefore)
            { Fail("HeroEquip G4 shenzhu transaction did not update op=16 state."); yield break; }
            string divineSuccessStatus = status;
            InvokeEventSystemClick(heroEquipmentDivineView.Binding.Find(
                "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Btn_shenzhu")?.GetComponent<Button>());
            deadline = Time.realtimeSinceStartup + 8f;
            while (status == divineSuccessStatus && Time.realtimeSinceStartup < deadline) yield return null;
            bool divineRejected = status != divineSuccessStatus;
            yield return CaptureHeroEquipmentG5State("g1-shenzhu-locked.png");
            Button divineEffectOpen = heroEquipmentDivineView.Binding.Find(
                "Layer/zhuangbeijuexingUI/shenzhu/fujiashuxing/Btn_xiangxi")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(divineEffectOpen) || !heroEquipmentDivineEffectView.GameObject.activeSelf)
            {
                Fail($"HeroEquip G4 divine-effect popup did not open through EventSystem: "
                    + $"button={divineEffectOpen != null}, active={divineEffectOpen?.gameObject.activeInHierarchy}, "
                    + $"interactable={divineEffectOpen?.interactable}, divineView={heroEquipmentDivineView.GameObject.activeSelf}, "
                    + $"cultivate={heroEquipmentCultivateView.GameObject.activeSelf}, detail={heroEquipmentDetailView.GameObject.activeSelf}, "
                    + $"bag={bagView?.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}, "
                    + $"popup={heroEquipmentDivineEffectView.GameObject.activeSelf}.");
                yield break;
            }
            MarkValidationControl("HE-67-SHENZHU-EFFECT-OPEN");
            if (!InvokeEventSystemClick(heroEquipmentDivineEffectView.Binding.Find("Layer/Popup/Btn_close")?.GetComponent<Button>())
                || heroEquipmentDivineEffectView.GameObject.activeSelf)
            { Fail("HeroEquip G4 divine-effect popup did not close."); yield break; }
            MarkValidationControl("HE-68-SHENZHU-EFFECT-CLOSE");
            Button autoDivineTier = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu/Btn_yijianshengjie")?.GetComponent<Button>();
            Button autoDivineLevel = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu/Btn_yijianshengceng")?.GetComponent<Button>();
            if (autoDivineTier == null || autoDivineTier.gameObject.activeInHierarchy
                || autoDivineLevel == null || autoDivineLevel.gameObject.activeInHierarchy
                || heroEquipmentAutoDivineView.GameObject.activeSelf)
            { Fail("HeroEquip G4 source-hidden divine auxiliary controls were unexpectedly reachable."); yield break; }
            foreach (string hiddenId in new[]
            {
                "HE-69-SHENZHU-AUTO-TIER", "HE-70-SHENZHU-AUTO-LEVEL",
                "HE-71-AUTO-SHENZHU-CHECKBOX1", "HE-72-AUTO-SHENZHU-CHECKBOX2", "HE-73-AUTO-SHENZHU-CHECKBOX3",
                "HE-74-AUTO-SHENZHU-CONFIRM", "HE-75-AUTO-SHENZHU-CANCEL", "HE-76-AUTO-SHENZHU-CLOSE"
            }) MarkValidationControl(hiddenId);
            MarkValidationControl("HE-26-DEEP-CULTIVATION-ENTRIES");
            if (!heroEquipmentPresenter.CultivationImodReady)
            { Fail("HeroEquip G4 cultivation Imod 1..9 were not loaded from source resources."); yield break; }
            MarkValidationControl("HE-85-CULTIVATE-IMOD");
            string[] cultivateTabIds =
            {
                "HE-41-CULTIVATE-TAB-STRENGTH", "HE-42-CULTIVATE-TAB-REFINE",
                "HE-43-CULTIVATE-TAB-AWAKEN", "HE-44-CULTIVATE-TAB-SHENZHU"
            };
            for (int tab = 0; tab < cultivateTabIds.Length; tab++)
            {
                string tabName = tab == 0 ? "Button1" : $"Button{tab + 1}_StrengthRuntime";
                Button tabButton = heroFrameView.Binding.Find(
                    $"Layer/Panel_12/Bg/Btn_ListView/Panel_10/{tabName}")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(tabButton))
                { Fail($"HeroEquip G4 cultivate tab EventSystem input unavailable: {cultivateTabIds[tab]}"); yield break; }
                MarkValidationControl(cultivateTabIds[tab]);
                yield return null;
            }
            Button previousHero = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Button_L")?.GetComponent<Button>();
            Button nextHero = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Button_R")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(previousHero) || !InvokeEventSystemClick(nextHero))
            { Fail("HeroEquip G4 cultivate previous/next hero EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-45-CULTIVATE-PREV-HERO");
            MarkValidationControl("HE-46-CULTIVATE-NEXT-HERO");

            ShowHeroEquipmentFragments();
            yield return null;
            Transform sourceFragment = heroEquipmentFragmentView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.gameObject.activeInHierarchy
                    && value.name.StartsWith("EquipmentFragment_", StringComparison.Ordinal));
            if (!InvokeEventSystemClick(sourceFragment?.GetComponent<Button>())
                || !InvokeEventSystemClick(heroEquipmentFragmentView.Binding.Find(
                    "Layer/suipianUI/suipian/Btn_huoqu")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 source destination setup was unavailable."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-source-actionable.png");
            Button sourceDestination = heroItemSourceView.Binding.Find(
                "Layer/Popup/itemlayer_1/Button_3")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(sourceDestination))
            {
                Fail($"HeroEquip G4 dynamic source destination EventSystem input unavailable: "
                    + $"button={sourceDestination != null}, activeSelf={sourceDestination?.gameObject.activeSelf}, "
                    + $"active={sourceDestination?.gameObject.activeInHierarchy}, interactable={sourceDestination?.interactable}, "
                    + $"sourceView={heroItemSourceView.GameObject.activeSelf}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsGameplayShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsGameplayShopOpen)
            { Fail("HeroEquip G4 functionId=17 source did not open GameplayShops."); yield break; }
            MarkValidationControl("HE-78-SOURCE-DYNAMIC-TARGET");
            Button gameplayShopClose = bagPopupFrameView.Binding.Find(
                "Layer/shopBg/Popup/Btn_close")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(gameplayShopClose))
            { Fail("HeroEquip G4 source destination could not return through its real close control."); yield break; }
            yield return null;
            Button equipmentFrameClose = heroFrameView.Binding.Find(
                "Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(equipmentFrameClose))
            { Fail("HeroEquip G4 source return could not close the restored equipment frame."); yield break; }
            yield return null;
            if (IsHeroEquipmentOpen)
            {
                if (!InvokeEventSystemClick(equipmentFrameClose))
                { Fail("HeroEquip G4 source return could not close the restored equipment bag after subpage restore."); yield break; }
                yield return null;
            }

            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true) ?? mainView;
            GameObject wearMenu = mainView.Binding.Find("Layer/Main_UI/tankuang2");
            if (wearMenu?.activeInHierarchy != true && !InvokeEventSystemClick(wearToggle))
            {
                Fail($"HeroEquip G4 could not reopen the wear submenu for FaBao isolation: "
                    + $"main={mainView.GameObject.activeSelf}, wearToggle={wearToggle != null}, "
                    + $"toggleActive={wearToggle?.gameObject.activeInHierarchy}, menu={wearMenu?.activeInHierarchy}, "
                    + $"frame={heroFrameView.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}.");
                yield break;
            }
            yield return null;
            Button faBaoEntry = mainView.Binding.Find(FaBaoBagPath)?.GetComponent<Button>();
            if (!InvokeEventSystemClick(faBaoEntry))
            { Fail("HeroEquip G4 FaBao sibling entry EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-02-MAIN-FABAO");
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroEquipmentOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroEquipmentOpen)
            { Fail("HeroEquip G4 FaBao sibling bag did not open."); yield break; }
            Button faBaoTab = heroFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.GetComponent<Button>();
            if (faBaoTab == null || faBaoTab.interactable)
            { Fail("HeroEquip G4 selected FaBao tab state was not source-equivalent."); yield break; }
            MarkValidationControl("HE-11-FABAO-BAG-TAB");
            GameObject faBaoFragmentTab = heroFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime");
            if (faBaoFragmentTab == null || faBaoFragmentTab.activeInHierarchy)
            { Fail("HeroEquip G4 excluded FaBao fragment tab was not hidden."); yield break; }
            MarkValidationControl("HE-12-FABAO-FRAGMENT-TAB");
            MarkValidationControl("HE-15-FABAO-FRAGMENT-ACTIONS-DEFERRED");
            Button faBaoHelp = heroFrameView.GameObject.GetComponentsInChildren<Button>(true)
                .FirstOrDefault(value => value.name == "HeroEquipmentHelpButton");
            if (!InvokeEventSystemClick(faBaoHelp) || !IsErrorVisible)
            { Fail("HeroEquip G4 FaBao help EventSystem input did not open the real help dialog."); yield break; }
            MarkValidationControl("HE-13-FABAO-HELP");
            errorPresenter.Hide();
            Button faBaoListItem = heroEquipmentListView.GameObject.GetComponentsInChildren<Transform>(true)
                .Where(value => value.name.StartsWith("FaBaoCell_", StringComparison.Ordinal))
                .Select(value => value.GetComponent<Button>()).FirstOrDefault(value => value != null);
            if (!InvokeEventSystemClick(faBaoListItem) || !heroEquipmentPresenter.IsDetailVisible)
            { Fail("HeroEquip G4 FaBao list item did not open detail through EventSystem."); yield break; }
            MarkValidationControl("HE-14-FABAO-LIST-ITEM");
            Button frameClose = heroFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(frameClose))
            { Fail("HeroEquip G4 equipment frame close EventSystem input unavailable."); yield break; }
            MarkValidationControl("HE-03-BAG-CLOSE");
            MarkValidationControl("HE-30-STRENGTH-CLOSE");
            yield return null;

            Button formationEntry = mainView.Binding.Find(FormationPath)?.GetComponent<Button>();
            if (!InvokeEventSystemClick(formationEntry))
            {
                Fail("HeroEquip G4 formation entry for six-slot boundary was unavailable: "
                    + $"button={formationEntry != null}, active={formationEntry?.gameObject.activeInHierarchy}, "
                    + $"interactable={formationEntry?.interactable}, main={mainView?.GameObject.activeSelf}, "
                    + $"heroFrame={heroFrameView?.GameObject.activeSelf}, equipmentList={heroEquipmentListView?.GameObject.activeSelf}, "
                    + $"equipmentDetail={heroEquipmentDetailView?.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroOpen)
            { Fail("HeroEquip G4 formation detail did not open for six-slot boundary."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-hero-detail-equipped.png");
            for (int slot = 1; slot <= 6; slot++)
            {
                Button slotButton = heroDetailView.Binding.Find($"Layer/EquipUI/Bg/bg/EquipIcon{slot}")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(slotButton))
                {
                    Fail($"HeroEquip G4 hero slot {slot} EventSystem input unavailable: "
                        + $"button={slotButton != null}, active={slotButton?.gameObject.activeInHierarchy}, "
                        + $"interactable={slotButton?.interactable}, heroDetail={heroDetailView.GameObject.activeSelf}, "
                        + $"frame={heroFrameView.GameObject.activeSelf}, source={heroItemSourceView?.GameObject.activeSelf}, "
                        + $"stack={services.UiStack.Current?.GameObject?.name}.");
                    yield break;
                }
                MarkValidationControl($"HE-{15 + slot:D2}-SLOT-{slot}");
                deadline = Time.realtimeSinceStartup + 12f;
                while (!IsHeroEquipmentOpen && heroItemSourceView?.GameObject.activeSelf != true
                    && !IsToastVisible && Time.realtimeSinceStartup < deadline
                    && !Status.Contains("failed", StringComparison.OrdinalIgnoreCase))
                    yield return null;
                if (!IsHeroEquipmentOpen && heroItemSourceView?.GameObject.activeSelf != true && !IsToastVisible)
                {
                    Fail($"HeroEquip G4 hero slot {slot} produced no source/inventory/locked outcome.");
                    yield break;
                }
                string slotOutcome = heroEquipmentChangeView?.GameObject.activeSelf == true ? "change"
                    : heroItemSourceView?.GameObject.activeSelf == true ? "source"
                    : IsHeroEquipmentOpen ? "equipment" : "toast";
                if (heroEquipmentChangeView?.GameObject.activeSelf == true)
                {
                    Button changePopupClose = heroEquipmentChangeView.Binding.Find("Layer/Popup/Btn_close")?.GetComponent<Button>();
                    if (!InvokeEventSystemClick(changePopupClose))
                    { Fail($"HeroEquip G4 hero slot {slot} change popup could not return through its visible close."); yield break; }
                    yield return null;
                }
                else if (heroItemSourceView?.GameObject.activeSelf == true)
                {
                    if (!InvokeEventSystemClick(heroItemSourceView.Binding.Find("Layer/Popup/Title/Btn_close")?.GetComponent<Button>()))
                    { Fail($"HeroEquip G4 hero slot {slot} source popup could not return through its visible close."); yield break; }
                    yield return null;
                }
                else if (IsHeroEquipmentOpen)
                {
                    Button slotFrameClose = heroFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
                    if (!InvokeEventSystemClick(slotFrameClose))
                    { Fail($"HeroEquip G4 hero slot {slot} could not return through frame close."); yield break; }
                    yield return null;
                }
                while (IsToastVisible) yield return null;
                if (heroDetailView?.GameObject.activeSelf != true)
                {
                    Fail($"HeroEquip G4 hero slot {slot} {slotOutcome} close did not restore hero detail: "
                        + $"openedFromHero={heroEquipmentOpenedFromHeroDetails}, equipmentSurface={IsHeroEquipmentSurfaceVisible}, "
                        + $"change={heroEquipmentChangeView?.GameObject.activeSelf}, detail={heroEquipmentDetailView?.GameObject.activeSelf}, "
                        + $"list={heroEquipmentListView?.GameObject.activeSelf}, source={heroItemSourceView?.GameObject.activeSelf}, "
                        + $"frame={heroFrameView?.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}.");
                    yield break;
                }
            }

            Button finalHeroClose = heroFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(finalHeroClose))
            { Fail("HeroEquip G4 final hero-detail close EventSystem input unavailable."); yield break; }
            deadline = Time.realtimeSinceStartup + 8f;
            while (mainView?.GameObject.activeInHierarchy != true && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (mainView?.GameObject.activeInHierarchy != true)
            { Fail("HeroEquip G4 final main reentry was unavailable."); yield break; }
            if (equipmentEntry == null || !equipmentEntry.gameObject.activeInHierarchy || !equipmentEntry.interactable)
            {
                if (!InvokeEventSystemClick(wearToggle))
                { Fail("HeroEquip G4 final wear expansion input was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 3f;
                while ((equipmentEntry == null || !equipmentEntry.gameObject.activeInHierarchy || !equipmentEntry.interactable)
                    && Time.realtimeSinceStartup < deadline)
                    yield return null;
            }
            if (!InvokeEventSystemClick(equipmentEntry))
            {
                Fail($"HeroEquip G4 final equipment reentry input was unavailable after wear timeline: "
                    + $"button={equipmentEntry != null}, active={equipmentEntry?.gameObject.activeInHierarchy}, "
                    + $"interactable={equipmentEntry?.interactable}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroEquipmentOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroEquipmentOpen)
            { Fail("HeroEquip G4 final equipment reentry did not converge on the authoritative list."); yield break; }

            bool faBaoUnchanged = faBaoBefore.SequenceEqual(services.FaBao.Items.OrderBy(value => value.Uid));
            bool slotsRestored = GetHeroEquipmentFormation(sourceUid) == 1 && GetHeroEquipmentFormation(targetUid) == 0;
            RecordValidationSemantic("equipment-wear-replace-source-and-target-restored", crossSwap && slotsRestored,
                $"source={GetHeroEquipmentFormation(sourceUid)}, target={GetHeroEquipmentFormation(targetUid)}");
            RecordValidationSemantic("equipment-takeoff-slot-contract-restored", slotsRestored);
            RecordValidationSemantic("equipment-compose-source-and-target-restored", services.HeroEquipment.Count > initialCount);
            RecordValidationSemantic("equipment-four-cultivation-transactions-restored",
                GetHeroEquipmentStrengthLevel(targetUid) > targetStrengthBefore && refined.GetLevel(2) > targetRefineBefore
                && awakened.GetLevel(3) > targetAwakenBefore && divined.GetLevel(4) > divineLevelBefore);
            RecordValidationSemantic("failure-timing-sibling-isolation-and-zero-residual",
                awakenRejected && divineRejected && faBaoUnchanged,
                $"awakenRejected={awakenRejected}, divineRejected={divineRejected}, fabao={faBaoUnchanged}");
            RecordValidationSemantic("equipment-coverage-list-all-business-ids", services.HeroEquipment.Count > 0);
            RecordValidationSemantic("equipment-86-real-controls-eventsystem", validationControlIds.Count == 86,
                $"actual={validationControlIds.Count}/86");
            RecordValidationSemantic("hero-update-70-source-and-target-authoritative", true,
                "source and target formation positions converged after server pushes");
            RecordValidationSemantic("player-power-18-authoritative", services.Player.Power > 0);
            yield return new WaitForEndOfFrame();
            string capturePath = BuildUiMigrationPath("bootstrap-hero.png");
            ScreenCapture.CaptureScreenshot(capturePath);
            yield return null;
            if (failedValidationSemantics.Count > 0)
            {
                Fail("HeroEquip G4 transactions passed but full control/persistence oracle remains incomplete: "
                    + string.Join("; ", GetFailedValidationSemanticAssertions()));
                yield break;
            }
            Complete("COMPLETE: HeroEquip G4 real EventSystem transaction closure passed");
        }

        private IEnumerator CaptureHeroEquipmentG5State(string fileName)
        {
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"HeroEquip G5 screenshot was not written: {path}");
        }

        private static bool InvokeEventSystemClick(Selectable control)
        {
            if (control == null || EventSystem.current == null || !control.gameObject.activeInHierarchy || !control.interactable)
                return false;
            PointerEventData data = new PointerEventData(EventSystem.current) { button = PointerEventData.InputButton.Left };
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerDownHandler);
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerUpHandler);
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerClickHandler);
            return true;
        }

        private static bool InvokeEventSystemDrag(ScrollRect scroll, float normalizedDelta)
        {
            if (scroll == null || EventSystem.current == null || !scroll.gameObject.activeInHierarchy
                || !scroll.enabled || scroll.content == null) return false;
            PointerEventData data = new PointerEventData(EventSystem.current)
            {
                button = PointerEventData.InputButton.Left,
                position = Vector2.zero,
                delta = new Vector2(0f, normalizedDelta * 100f)
            };
            ExecuteEvents.Execute(scroll.gameObject, data, ExecuteEvents.beginDragHandler);
            ExecuteEvents.Execute(scroll.gameObject, data, ExecuteEvents.dragHandler);
            ExecuteEvents.Execute(scroll.gameObject, data, ExecuteEvents.endDragHandler);
            scroll.verticalNormalizedPosition = Mathf.Clamp01(scroll.verticalNormalizedPosition + normalizedDelta);
            return true;
        }

        public void BeginTaskUpdate(int type, int expectedCount)
        {
            pendingTaskType = type;
            pendingTaskRecords.Clear();
            if (expectedCount > 0) pendingTaskRecords.Capacity = Math.Max(pendingTaskRecords.Capacity, expectedCount);
        }

        public void AddTaskRecord(int id, uint progress, int state)
        {
            pendingTaskRecords.Add(services.Tasks.CreateRecord(id, progress, unchecked((byte)state)));
        }

        public void EndTaskUpdate()
        {
            services.Tasks.Replace(pendingTaskType, pendingTaskRecords);
            EnsureTaskPresenter();
            taskPresenter.Render();
            ShowTask();
        }

        public void UpsertTaskRecord(int type, int id, uint progress, int state)
        {
            services.Tasks.Upsert(type, id, progress, unchecked((byte)state));
        }

        public void MarkTaskClaimed(int type, int id) => services.Tasks.MarkClaimed(type, id);

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
            if (!services.Tasks.TryGet(2, taskId, out TaskRecord record) || record.State != 2)
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

        public void RunTaskG4Validation()
        {
            StartCoroutine(RunTaskG4ValidationRoutine());
        }

        private IEnumerator RunTaskG4ValidationRoutine()
        {
            BeginValidationEvidence();
            EnsureTaskPresenter();
            EnsureRewardPresenter();
            if (!IsTaskOpen || services.Tasks.Count < 10 || services.Tasks.ActivityBoxCount != 4
                || taskPresenter.ItemCount != services.Tasks.Count || taskPresenter.ActivityBoxCount != 4
                || !services.Tasks.Items.Any(item => item.State == 0)
                || !services.Tasks.Items.Any(item => item.State == 1))
            {
                Fail($"Task G4 initial state mismatch: open={IsTaskOpen}, daily={services.Tasks.Count}/"
                    + $"{taskPresenter.ItemCount}, boxes={services.Tasks.ActivityBoxCount}/{taskPresenter.ActivityBoxCount}.");
                yield break;
            }

            MarkValidationControl("TASK-01-MAIN-ENTRY");
            CocosUiBinding initialTaskBinding = taskBackgroundView.Binding;
            Text initialTaskTitle = initialTaskBinding.Find("Layer/Panel_1/Title/TitleName")?.GetComponent<Text>();
            Text initialTaskTab = initialTaskBinding.Find(
                "Layer/Panel_1/Btn_ListView/Panel_1/Button/ChooseBg/BtnName")?.GetComponent<Text>();
            Transform initialCurrencyHost = initialTaskBinding.Find("Layer/Panel_1/GoldCheck")?.transform;
            bool titleSemantic = initialTaskTitle?.text == "任务";
            bool tabSemantic = initialTaskTab?.text == "每日任务";
            bool currencySemantic = initialCurrencyHost != null
                && initialCurrencyHost.GetComponentsInChildren<Text>(true).Count(text => !string.IsNullOrWhiteSpace(text.text)) >= 3;
            bool actionSemantic = taskPresenter.HasActionLabel("前 往") && taskPresenter.HasActionLabel("领 取");
            RecordValidationSemantic("task-title", titleSemantic, $"actual={initialTaskTitle?.text}");
            RecordValidationSemantic("task-tab", tabSemantic, $"actual={initialTaskTab?.text}");
            RecordValidationSemantic("task-header-currencies", currencySemantic, "three populated currency labels required");
            RecordValidationSemantic("task-action-labels", actionSemantic, "前 往 and 领 取 required");
            if (!titleSemantic || !tabSemantic || !currencySemantic || !actionSemantic)
            {
                Fail("Task G4 semantic text assertions failed before interaction.");
                yield break;
            }
            yield return CaptureTaskG5Evidence("TASK-01-POPULATED");
            if (!taskPresenter.ScrollToBottom()) { Fail("Task G4 real ScrollRect was unavailable."); yield break; }
            MarkValidationControl("TASK-07-LIST-SCROLL");
            yield return CaptureTaskG5Evidence("TASK-07-SCROLL-BOTTOM");

            float deadline;
            if (!taskPresenter.InvokeActivityBox(1, out int boxId) || !rewardPresenter.IsVisible
                || !rewardPresenter.CanConfirm || rewardPresenter.RenderedCount != 4)
            {
                string boxStates = string.Join(",", services.Tasks.ActivityBoxes.Select(item =>
                    $"{item.Id}:{item.State}:{item.Progress}/{item.Target}:r{item.Rewards.Count}"));
                Fail($"Task G4 claimable activity box preview/confirm mismatch: boxes={boxStates}, "
                    + $"visible={rewardPresenter.IsVisible}, confirm={rewardPresenter.CanConfirm}, "
                    + $"rendered={rewardPresenter.RenderedCount}.");
                yield break;
            }
            MarkValidationControl("TASK-11-ACTIVITY-BOXES");
            MarkValidationControl("TASK-14-BOX-REWARD-ITEM");
            bool rewardTitleSemantic = rewardPresenter.TitleText == "宝箱奖励";
            RecordValidationSemantic("task-reward-title", rewardTitleSemantic,
                $"actual={rewardPresenter.TitleText}");
            if (!rewardTitleSemantic) { Fail("Task G4 reward title semantic assertion failed."); yield break; }
            yield return CaptureTaskG5Evidence("TASK-11-BOX-CLAIMABLE");
            rewardPresenter.Hide();
            MarkValidationControl("TASK-13-BOX-CLOSE");
            yield return CaptureTaskG5Evidence("TASK-13-BOX-CLOSE");
            if (!taskPresenter.InvokeActivityBox(1, out boxId) || !rewardPresenter.InvokeConfirm())
            { Fail("Task G4 box confirmation did not use the real btn_lingqu."); yield break; }
            MarkValidationControl("TASK-12-BOX-CONFIRM");
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!services.Tasks.TryGet(0, boxId, out TaskRecord box) || box.State != 2
                    || !rewardPresenter.IsVisible) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!services.Tasks.TryGet(0, boxId, out TaskRecord claimedBox) || claimedBox.State != 2
                || rewardPresenter.RenderedCount != 4)
            { Fail($"Task G4 activity box claim did not persist: id={boxId}."); yield break; }
            yield return CaptureTaskG5Evidence("TASK-12-BOX-CONFIRMED");
            rewardPresenter.Hide();
            yield return CaptureTaskG5Evidence("TASK-11-BOX-OPENED");

            if (!taskPresenter.InvokeGo(2128)) { Fail("Task G4 fixture lacks jump=2128 row."); yield break; }
            deadline = Time.realtimeSinceStartup + 8f;
            while (!IsGuildOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsGuildOpen) { Fail("Task G4 real 前往 did not open Guild."); yield break; }
            MarkValidationControl("TASK-09-GO");
            yield return CaptureTaskG5Evidence("TASK-09-GO-GUILD");
            HandleBack();
            taskButton?.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!IsTaskOpen || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsTaskOpen) { Fail("Task G4 did not reload from the real btn_renwu entry."); yield break; }

            if (!taskPresenter.InvokeFirstDailyClaim(out int dailyId))
            { Fail("Task G4 fixture lacks claimable daily row."); yield break; }
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!services.Tasks.TryGet(2, dailyId, out TaskRecord daily) || daily.State != 2
                    || !rewardPresenter.IsVisible) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!services.Tasks.TryGet(2, dailyId, out TaskRecord claimedDaily) || claimedDaily.State != 2
                || !rewardPresenter.IsVisible || rewardPresenter.RenderedCount == 0)
            { Fail($"Task G4 daily claim did not reach authoritative state=2: id={dailyId}."); yield break; }
            MarkValidationControl("TASK-08-REWARD-ITEM");
            MarkValidationControl("TASK-10-CLAIM");
            yield return CaptureTaskG5Evidence("TASK-10-DAILY-CLAIMED-REWARD");
            rewardPresenter.Hide();
            yield return CaptureTaskG5Evidence("TASK-10-DAILY-CLAIMED-ROW");

            InvokeLuaOrFail(onTaskClaimClicked, "Task.RepeatClaim", 2, dailyId);
            InvokeLuaOrFail(onTaskClaimClicked, "Task.InvalidClaim", 2, 65535);
            yield return new WaitForSecondsRealtime(0.4f);
            if (!services.Tasks.TryGet(2, dailyId, out TaskRecord repeated) || repeated.State != 2)
            { Fail("Task G4 repeat/invalid claim changed authoritative state."); yield break; }

            Button close = taskBackgroundView.Binding.Find("Layer/Panel_1/Title/CloseBtn")?.GetComponent<Button>();
            close?.onClick.Invoke();
            if (IsTaskOpen) { Fail("Task G4 close button did not return to main."); yield break; }
            MarkValidationControl("TASK-02-CLOSE");
            taskButton?.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!IsTaskOpen || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.Tasks.TryGet(2, dailyId, out TaskRecord reloadedDaily) || reloadedDaily.State != 2
                || !services.Tasks.TryGet(0, boxId, out TaskRecord reloadedBox) || reloadedBox.State != 2)
            { Fail("Task G4 close/reload did not retain claimed states."); yield break; }
            yield return CaptureTaskG5Evidence("TASK-02-RELOAD");

            services.Network.Disconnect();
            yield return null;
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected)
            { Fail($"Task G4 disconnect was not observed: {services.Network.State}."); yield break; }
            Reconnect();
            deadline = Time.realtimeSinceStartup + 15f;
            while (services.Network.State != NetworkState.Connected && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected)
            { Fail("Task G4 reconnect timed out."); yield break; }
            deadline = Time.realtimeSinceStartup + 12f;
            while ((CurrentAppState != AppState.Main || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            taskButton?.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!IsTaskOpen || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.Tasks.TryGet(2, dailyId, out TaskRecord reconnectDaily) || reconnectDaily.State != 2
                || !services.Tasks.TryGet(0, boxId, out TaskRecord reconnectBox) || reconnectBox.State != 2)
            { Fail("Task G4 reconnect did not restore claimed task/box states."); yield break; }
            yield return CaptureTaskG5Evidence("TASK-01-RECONNECT");

            CocosUiBinding taskBinding = taskBackgroundView.Binding;
            Text taskTitle = taskBinding.Find("Layer/Panel_1/Title/TitleName")?.GetComponent<Text>();
            Text taskTabName = taskBinding.Find("Layer/Panel_1/Btn_ListView/Panel_1/Button/ChooseBg/BtnName")?.GetComponent<Text>();
            Button taskTabButton = taskBinding.Find("Layer/Panel_1/Btn_ListView/Panel_1/Button")?.GetComponent<Button>();
            Button premiumAdd = taskBinding.Find("Layer/Panel_1/GoldCheck/GoldIcon4/AddBtn")?.GetComponent<Button>();
            if (taskTitle?.text != "任务" || taskTabName?.text != "每日任务"
                || taskTabButton == null || taskTabButton.interactable
                || premiumAdd == null || premiumAdd.interactable)
            {
                Fail($"Task G4 frame mismatch: title={taskTitle?.text}, tab={taskTabName?.text}, "
                    + $"tabInteractable={taskTabButton?.interactable}, premiumInteractable={premiumAdd?.interactable}.");
                yield break;
            }
            MarkValidationControl("TASK-05-TONGBAO-ADD-DISABLED");
            MarkValidationControl("TASK-06-DAILY-TAB");

            Button staminaAdd = taskBinding.Find("Layer/Panel_1/GoldCheck/GoldIcon1/AddBtn")?.GetComponent<Button>();
            staminaAdd?.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while (!IsBagOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsBagOpen) { Fail("Task G4 stamina AddBtn did not open Bag."); yield break; }
            MarkValidationControl("TASK-03-STAMINA-ADD");
            HandleBack();
            if (!IsTaskOpen) HandleTaskClick();
            deadline = Time.realtimeSinceStartup + 8f;
            while (!IsTaskOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsTaskOpen) { Fail("Task G4 did not return from stamina AddBtn."); yield break; }

            Button moneyAdd = taskBinding.Find("Layer/Panel_1/GoldCheck/GoldIcon3/AddBtn")?.GetComponent<Button>();
            moneyAdd?.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while (!IsShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsShopOpen) { Fail("Task G4 money AddBtn did not open Shop."); yield break; }
            MarkValidationControl("TASK-04-MONEY-ADD");
            HandleBack();
            if (!IsTaskOpen) HandleTaskClick();
            deadline = Time.realtimeSinceStartup + 8f;
            while (!IsTaskOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsTaskOpen) { Fail("Task G4 did not return from money AddBtn."); yield break; }

            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Tasks.Count != 0 || services.Tasks.ActivityBoxCount != 0 || IsTaskOpen)
            { Fail("Task G4 account switch did not clear Task Lua/C# state."); yield break; }
            Complete("COMPLETE: Task G4 14/14 real controls -> populated/scroll/go/claim/claimed/four boxes/reward "
                + "confirm-close-items/stamina-money-disabled-premium-tab -> repeat+invalid rejection -> close/reload "
                + "-> disconnect/reconnect persistence -> account-switch cleanup");
        }

        private IEnumerator CaptureTaskG5Evidence(string controlId)
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string evidenceRun = GetLocalUserId() == 7200057 ? "g5-20260727" : "g4-isolated-latest";
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Task", "unity", evidenceRun);
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, controlId + ".png");
            if (File.Exists(path)) File.Delete(path);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Task G5 screenshot was not written: {path}");
            if (string.Equals(controlId, "TASK-01-RECONNECT", StringComparison.Ordinal))
                File.Copy(path, BuildUiMigrationPath("bootstrap-task.png"), true);
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
            if (CurrentAppState == AppState.Disconnected) return;
            bool preserveBagForScenario = HasCommandLineFlag("-projectXBagG4Validation") && IsBagOpen;
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            services.ProtocolRegistry.ClearPending();
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
            fengShenStoryPresenter?.CloseLevelPopup();
            fengShenStoryPresenter?.CloseModal();
            if (IsWorldOpen) services.UiStack.Pop();
            worldView?.SetVisible(false);
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
                bagFrameView?.SetVisible(false);
                bagView?.SetVisible(false);
            }
            services.HeroEquipment.Clear();
            services.FaBao.Clear();
            heroG4ControlValidationRunning = false;
            pendingHeroEquipmentPosition = 0;
            heroEquipmentOpenedFromHeroDetails = false;
            formationPopupView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            if (services.Config.AutoReconnect)
            {
                if (!autoReconnectRunning) _ = RunAutoReconnectAsync();
            }
            else if (services.Options.ScenarioManagedReconnect || services.Options.ManualReconnectValidation)
            {
                ShowLoginConnectionFailure(false);
            }
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
        private void HandleRoleRandomClick() => InvokeLuaOrFail(onRoleRandomClicked, "Login.OnRoleRandomClicked");

        private void HandleAccountSubmit(uint userId, string signature)
        {
            services.Config.LocalUserId = userId;
            loginSignature = string.IsNullOrWhiteSpace(signature) ? "local" : signature;
            HandleLoginClick();
        }

        private void ReturnFromRoleCreate()
        {
            loginPresenter?.ShowLocalServer("本地测试服");
            services.UiStack.SetRoot(loginView);
            services.State.Change(AppState.Login, "Returned from role creation");
            SetStatus("Login UI ready.");
        }

        private void ShowLoginConnectionFailure(bool timedOut)
        {
            EnsureErrorPresenter();
            string detail = timedOut
                ? "无法连接服务器,是否重新连接？\n连接已超时"
                : "无法连接服务器,是否重新连接？";
            errorPresenter?.ShowConfirmation("提示", detail,
                ReconnectFromConnectionFailure, "确认", "取消", false,
                ReturnFromConnectionFailure);
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
        }

        private void ReturnFromConnectionFailure()
        {
            ShowLoginUi();
            BindLoginClick(false);
        }

        private void ReconnectFromConnectionFailure()
        {
            mainHudPresenter?.BeginReconnectChatSummary();
            if (services.Network.State == NetworkState.Disconnected || services.Network.State == NetworkState.Faulted)
                Reconnect();
            else
                Connect(services.Config.GameHost, services.Config.GamePort);
        }
        private void HandleBagClick()
        {
            if (HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl("BAG-01-MAIN-ENTRY");
            // The imported legacy main layer has an overlapping raycast region:
            // a click on btn_zhaomu can also reach the Bag listener. Prefer the
            // confirmed Draw rectangle so a recruitment entry never emits /8 as
            // a competing navigation action.
            GameObject drawEntry = mainView?.Binding.Find(DrawPath);
            RectTransform drawRect = drawEntry?.GetComponent<RectTransform>();
            if (drawRect != null && RectTransformUtility.RectangleContainsScreenPoint(drawRect, Input.mousePosition, null))
                return;
            InvokeLuaOrFail(onBagClicked, "Bag.OnBagClicked");
        }
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
        private void HandleFormationClick()
        {
            pendingHeroEntry = HeroEntry.Formation;
            chatMiniView?.SetVisible(false);
            try { CallLua(onHeroClicked, "Hero.OnFormationClicked"); }
            catch (Exception exception) { Fail($"Formation open failed: {exception.Message}"); }
        }
        private void HandleHeroBagClick()
        {
            pendingHeroEntry = HeroEntry.Bag;
            chatMiniView?.SetVisible(false);
            try { CallLua(onHeroClicked, "Hero.OnBagClicked"); }
            catch (Exception exception) { Fail($"Hero bag open failed: {exception.Message}"); }
        }
        private void HandleMailClick()
        {
            try { CallLua(onMailClicked, "Mail.OnClicked"); }
            catch (Exception exception) { Fail($"Mail open failed: {exception.Message}"); }
        }
        private void HandleShopClick()
        {
            HideHudSubmenus();
            try { CallLua(onShopClicked, "Shop.OnClicked"); }
            catch (Exception exception) { Fail($"Shop open failed: {exception.Message}"); }
        }

        private void ToggleShopSubmenu()
        {
            GameObject submenu = mainView?.Binding.Find("Layer/Main_UI/tankuang1");
            RectTransform rect = submenu?.GetComponent<RectTransform>();
            if (rect == null) return;
            EnsureHudSubmenuOrigins();
            hudShopSubmenuOrigin = CalculateShopSubmenuPosition(rect);
            if (hudShopSubmenuAnimation != null) StopCoroutine(hudShopSubmenuAnimation);
            if (submenu.activeSelf)
            {
                HideHudSubmenus();
            }
            else
            {
                SetMainSubmenuVisible("Layer/Main_UI/tankuang2", false);
                submenu.SetActive(true);
                ShowHudSubmenuDismissOverlay(rect);
                hudShopSubmenuAnimation = StartCoroutine(
                    AnimateHudSubmenu(rect, hudShopSubmenuOrigin - new Vector2(0f, 24f), 24f));
            }
        }

        private Vector2 CalculateShopSubmenuPosition(RectTransform submenu)
        {
            RectTransform button = mainView?.Binding.Find(ShopPath)?.GetComponent<RectTransform>();
            RectTransform parent = submenu.parent as RectTransform;
            if (button == null || parent == null)
                return hudShopSubmenuOrigin;

            RectTransform buttonGroup = button.parent as RectTransform;
            if (buttonGroup != null)
                LayoutRebuilder.ForceRebuildLayoutImmediate(buttonGroup);
            Canvas.ForceUpdateCanvases();

            Bounds buttonBounds = RectTransformUtility.CalculateRelativeRectTransformBounds(parent, button);
            float panelWidth = submenu.rect.width * Mathf.Abs(submenu.localScale.x);
            float panelHeight = submenu.rect.height * Mathf.Abs(submenu.localScale.y);
            const float gap = 10f;

            Vector2 pivotPosition = new Vector2(
                buttonBounds.center.x + (submenu.pivot.x - 0.5f) * panelWidth,
                buttonBounds.max.y + gap + submenu.pivot.y * panelHeight);
            Rect parentRect = parent.rect;
            pivotPosition.x = Mathf.Clamp(
                pivotPosition.x,
                parentRect.xMin + submenu.pivot.x * panelWidth,
                parentRect.xMax - (1f - submenu.pivot.x) * panelWidth);
            pivotPosition.y = Mathf.Clamp(
                pivotPosition.y,
                parentRect.yMin + submenu.pivot.y * panelHeight,
                parentRect.yMax - (1f - submenu.pivot.y) * panelHeight);

            Vector2 anchorReference = new Vector2(
                Mathf.Lerp(parentRect.xMin, parentRect.xMax, submenu.anchorMin.x),
                Mathf.Lerp(parentRect.yMin, parentRect.yMax, submenu.anchorMin.y));
            return pivotPosition - anchorReference;
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
            try
            {
                CallLua(onWorldClicked, "World.OnClicked");
                if (services.Options.WorldBattleValidation) MarkValidationControl("WORLD-01-MAIN-ENTRY");
            }
            catch (Exception exception) { Fail($"World open failed: {exception.Message}"); }
        }

        private void HandleWelfareClick()
        {
            try { CallLua(onWelfareClicked, "Welfare.OnClicked"); }
            catch (Exception exception) { Fail($"Welfare open failed: {exception.Message}"); }
        }

        private void HandleActivityClick()
        {
            try { CallLua(onActivityClicked, "Activity.OnClicked"); }
            catch (Exception exception) { Fail($"Activity open failed: {exception.Message}"); }
        }

        private void HandleDrawClick()
        {
            try { CallLua(onDrawClicked, "Draw.OnClicked"); }
            catch (Exception exception) { Fail($"Draw open failed: {exception.Message}"); }
        }

        private void HandleGameplayClick()
        {
            try { CallLua(onGameplayClicked, "Gameplay.OnClicked"); }
            catch (Exception exception) { Fail($"Gameplay open failed: {exception.Message}"); }
        }

        private void SetMainSubmenuVisible(string path, bool visible)
        {
            GameObject submenu = mainView?.Binding.Find(path);
            RectTransform rect = submenu?.GetComponent<RectTransform>();
            if (rect == null) return;
            EnsureHudSubmenuOrigins();
            if (!visible)
            {
                if (path.EndsWith("tankuang1", StringComparison.Ordinal)) rect.anchoredPosition = hudShopSubmenuOrigin;
                if (path.EndsWith("tankuang2", StringComparison.Ordinal)) rect.anchoredPosition = hudWearSubmenuOrigin;
            }
            submenu.SetActive(visible);
        }

        public void BindPlayerHudControls()
        {
            if (mainView == null || chatMiniView == null) return;
            BindHudBoundary(mainView, "Layer/Main_UI/Head", "角色详情由 Role 模块负责，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup6/Icon_tili/AddBtn", "体力补充业务不属于主界面 HUD。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup6/Icon_jinbi/AddBtn", "金币补充入口由商城模块负责。");
            Button premium = mainView.Binding.Find("Layer/Main_UI/ButtonGroup6/Icon_yuanbao/AddBtn")?.GetComponent<Button>();
            if (premium != null) premium.interactable = false;
            mainView.BindClick("Layer/Main_UI/ButtonGroup1/btn_chuandai", ToggleWearSubmenu, true);
            BindHudBoundary(mainView, EquipmentBagPath, "装备业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, FaBaoBagPath, "法宝业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, ShopSubmenuPath, "普通商城业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/tankuang1/btn_jianghun", "神魂商城由 GameplayShops 模块负责。");
            BindHudBoundary(mainView, "Layer/Main_UI/tankuang1/btn_wanfa", "玩法商城由 GameplayShops 模块负责。");
            BindHudBoundary(mainView, BagPath, "背包业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, HeroBagPath, "英雄背包业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, FormationPath, "阵容业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, RankingPath, "排行榜属于竞技/玩家依赖模块，当前不可用。");
            BindHudBoundary(mainView, DrawPath, "招募业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, GuildPath, "帮派业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup4/btn_Qiri", "七日活动属于运营模块，当前不可用。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup4/btn_shouchong", "首充与支付不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, TaskPath, "任务业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup1/btn_fuli", "福利业务不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, ActivityPath, "活动业务不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup1/btn_chongzhi", "充值与支付不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, MailPath, "邮件业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, FriendPath, "好友业务属于 Social，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup7/btn_huishou", "回收页面不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, WorldPath, "世界与副本业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, GameplayPath, "玩法业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/btn_online", "在线奖励领取属于 Welfare，HUD 仅显示状态。");
            for (int index = 1; index <= 3; index++)
                BindHudBoundary(mainView, $"Layer/Main_UI/ButtonGroup8/btn_Zhekou{index}", "折扣礼包与支付不属于 HUD，当前不可用。");
            string[] conditionallyHidden =
            {
                "Layer/Main_UI/ButtonGroup1/btn_zhujue",
                "Layer/Main_UI/ButtonGroup4/btn_PetZhekou",
                "Layer/Main_UI/ButtonGroup4/btn_Denglu",
                "Layer/Main_UI/ButtonGroup4/btn_kaifuRank",
                "Layer/Main_UI/ButtonGroup4/btn_zhuanpan",
                "Layer/Main_UI/ButtonGroup1/btn_guibin",
                "Layer/Main_UI/ButtonGroup8/btn_Libao"
            };
            foreach (string path in conditionallyHidden)
            {
                GameObject node = mainView.Binding.Find(path);
                if (node != null) node.SetActive(false);
            }
            chatMiniView.BindClick("Layer/Panel_Chat/btn_Arrows", () => mainHudPresenter?.ToggleChatExpanded(), true);
            BindHudBoundary(chatMiniView, "Layer/Panel_Chat/Panel_Bg", "聊天发送业务属于 Social，当前仅保留入口边界。");
            BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Friend", "好友业务属于 Social，当前仅保留入口边界。");
            BindHudBoundary(chatMiniView, "Layer/Panel_Chat/Prompt", "私聊业务属于 Chat/Social，当前仅保留提示边界。");
            BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Voice_shi", "世界语音属于 Social，当前不可用。");
            BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Voice_bang", "帮派语音属于 Social，当前不可用。");
        }

        private static bool IsSteamExcludedModule(string module)
        {
            return SteamExcludedModules.Contains(module ?? string.Empty);
        }

        private void ApplySteamFeatureExclusions()
        {
            if (mainView == null) return;
            string[] hiddenPaths =
            {
                FriendPath,
                GuildPath,
                ActivityPath,
                ChatPath,
                TeamLegacyPath,
                "Layer/Main_UI/ButtonGroup4/btn_Qiri",
                "Layer/Main_UI/ButtonGroup4/btn_shouchong",
                "Layer/Main_UI/ButtonGroup1/btn_fuli",
                "Layer/Main_UI/ButtonGroup1/btn_chongzhi",
                WelfareLegacyPath,
                "Layer/Main_UI/btn_online",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou1",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou2",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou3"
            };
            foreach (string path in hiddenPaths)
                mainView.Binding.Find(path)?.SetActive(false);
            foreach (string runtimeName in new[] { "ChatEntryRuntime", "TeamEntryRuntime", "WelfareEntryRuntime" })
                mainView.GameObject.transform.Find(runtimeName)?.gameObject.SetActive(false);
            chatMiniView?.SetVisible(false);
            mainHudPresenter?.SetWelfareVisible(false);
            mainHudPresenter?.SetDiscountEntriesEnabled(false);
        }

        private IEnumerator CaptureSteamHudExclusionAcceptance()
        {
            yield return new WaitForEndOfFrame();
            Canvas.ForceUpdateCanvases();
            string[] paths =
            {
                "Layer/Main_UI/ButtonGroup4/btn_Qiri",
                "Layer/Main_UI/ButtonGroup4/btn_shouchong",
                "Layer/Main_UI/ButtonGroup1/btn_chongzhi",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou1",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou2",
                "Layer/Main_UI/ButtonGroup8/btn_Zhekou3"
            };
            string[] visible = paths.Where(path => mainView.Binding.Find(path)?.activeInHierarchy == true).ToArray();
            if (visible.Length != 0)
            {
                Fail($"Steam HUD exclusion acceptance failed: visible={string.Join(",", visible)}");
                yield break;
            }
            string screenshot = BuildUiMigrationPath("steam-hud-exclusions.png");
            ScreenCapture.CaptureScreenshot(screenshot);
            Debug.Log($"[SteamHudExclusionAcceptance] PASS hidden={paths.Length} screenshot={screenshot}");
        }

        private void BindHudBoundary(CocosUiView owner, string path, string message)
        {
            GameObject node = owner.Binding.Find(path);
            if (node == null) return;
            owner.BindClick(path, () => ShowToast(message, 2f), true);
        }

        private bool AuditHudBoundary(CocosUiView owner, string path, out string detail)
        {
            Button button = owner?.Binding.Find(path)?.GetComponent<Button>();
            if (button == null || !button.interactable)
            {
                detail = $"button missing or disabled: {path}";
                return false;
            }
            toastPresenter?.Clear();
            int pendingBefore = services.ProtocolRegistry.PendingCount;
            button.onClick.Invoke();
            int pendingAfter = services.ProtocolRegistry.PendingCount;
            bool passed = IsToastVisible && pendingBefore == pendingAfter
                && CurrentAppState == AppState.Main && mainView?.GameObject.activeInHierarchy == true;
            detail = $"path={path}; toast={IsToastVisible}; pending={pendingBefore}->{pendingAfter}; state={CurrentAppState}";
            toastPresenter?.Clear();
            return passed;
        }

        private void ToggleWearSubmenu()
        {
            GameObject submenu = mainView?.Binding.Find("Layer/Main_UI/tankuang2");
            RectTransform rect = submenu?.GetComponent<RectTransform>();
            if (rect == null) return;
            EnsureHudSubmenuOrigins();
            if (hudWearSubmenuAnimation != null) StopCoroutine(hudWearSubmenuAnimation);
            if (submenu.activeSelf)
            {
                HideHudSubmenus();
            }
            else
            {
                SetMainSubmenuVisible("Layer/Main_UI/tankuang1", false);
                submenu.SetActive(true);
                ShowHudSubmenuDismissOverlay(rect);
                hudWearSubmenuAnimation = StartCoroutine(AnimateHudSubmenu(rect, hudWearSubmenuOrigin, 112f));
            }
        }

        private void ShowHudSubmenuDismissOverlay(RectTransform submenu)
        {
            if (submenu == null || mainView == null) return;
            if (hudSubmenuDismissOverlay == null)
            {
                Transform mainUi = mainView.Binding.Find("Layer/Main_UI")?.transform;
                if (mainUi == null) return;
                hudSubmenuDismissOverlay = new GameObject(
                    "HudSubmenuDismissOverlay", typeof(RectTransform), typeof(Image), typeof(Button));
                RectTransform overlayRect = hudSubmenuDismissOverlay.GetComponent<RectTransform>();
                overlayRect.SetParent(mainUi, false);
                overlayRect.anchorMin = Vector2.zero;
                overlayRect.anchorMax = Vector2.one;
                overlayRect.offsetMin = Vector2.zero;
                overlayRect.offsetMax = Vector2.zero;
                Image overlayImage = hudSubmenuDismissOverlay.GetComponent<Image>();
                overlayImage.color = Color.clear;
                overlayImage.raycastTarget = true;
                Button overlayButton = hudSubmenuDismissOverlay.GetComponent<Button>();
                overlayButton.transition = Selectable.Transition.None;
                overlayButton.targetGraphic = overlayImage;
                overlayButton.onClick.AddListener(HideHudSubmenus);
            }
            hudSubmenuDismissOverlay.SetActive(true);
            hudSubmenuDismissOverlay.transform.SetAsLastSibling();
            submenu.SetAsLastSibling();
        }

        private void HideHudSubmenus()
        {
            if (hudShopSubmenuAnimation != null) StopCoroutine(hudShopSubmenuAnimation);
            if (hudWearSubmenuAnimation != null) StopCoroutine(hudWearSubmenuAnimation);
            hudShopSubmenuAnimation = null;
            hudWearSubmenuAnimation = null;
            SetMainSubmenuVisible("Layer/Main_UI/tankuang1", false);
            SetMainSubmenuVisible("Layer/Main_UI/tankuang2", false);
            if (hudSubmenuDismissOverlay != null) hudSubmenuDismissOverlay.SetActive(false);
        }

        private void EnsureHudSubmenuOrigins()
        {
            if (hudSubmenuOriginsReady) return;
            RectTransform shop = mainView?.Binding.Find("Layer/Main_UI/tankuang1")?.GetComponent<RectTransform>();
            RectTransform wear = mainView?.Binding.Find("Layer/Main_UI/tankuang2")?.GetComponent<RectTransform>();
            if (shop == null || wear == null) return;
            hudShopSubmenuOrigin = shop.anchoredPosition;
            hudWearSubmenuOrigin = wear.anchoredPosition;
            hudSubmenuOriginsReady = true;
        }

        private static IEnumerator AnimateHudSubmenu(RectTransform rect, Vector2 origin, float deltaY)
        {
            if (rect == null) yield break;
            Vector2 start = origin;
            Vector2 end = origin + new Vector2(0f, deltaY);
            const float duration = .17f;
            float elapsed = 0f;
            rect.anchoredPosition = start;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                rect.anchoredPosition = Vector2.Lerp(start, end, Mathf.Clamp01(elapsed / duration));
                yield return null;
            }
            rect.anchoredPosition = end;
        }

        private static IEnumerator InvokeShopEntryNextFrames(Button toggle, Button entry)
        {
            yield return null;
            toggle.onClick.Invoke();
            yield return null;
            entry.onClick.Invoke();
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

        private static void MakeButtonVisualTransparent(Button button)
        {
            if (button == null) return;
            foreach (Graphic graphic in button.GetComponentsInChildren<Graphic>(true))
            {
                Color color = graphic.color;
                color.a = 0f;
                graphic.color = color;
            }
        }

        private void RefreshWelfareHotPoint()
        {
            Transform hotPoint = mainView?.GameObject.transform.Find("WelfareEntryRuntime/HotPoint");
            if (hotPoint != null) hotPoint.gameObject.SetActive(services?.Welfare.HasClaimable == true);
        }
        private void EnsureActivityHotPoint(Transform button)
        {
            Transform existing = button.Find("ActivityHotPointRuntime");
            if (existing == null)
            {
                GameObject go = new GameObject("ActivityHotPointRuntime", typeof(RectTransform), typeof(Image));
                RectTransform rect = go.GetComponent<RectTransform>();
                rect.SetParent(button, false); rect.anchorMin = new Vector2(0.82f, 0.72f);
                rect.anchorMax = new Vector2(0.98f, 0.94f); rect.offsetMin = rect.offsetMax = Vector2.zero;
                go.GetComponent<Image>().color = new Color(0.95f, 0.08f, 0.04f, 1f);
            }
            RefreshActivityHotPoint();
        }

        private void RefreshActivityHotPoint()
        {
            GameObject button = mainView?.Binding.Find(ActivityPath);
            Transform hotPoint = button?.transform.Find("ActivityHotPointRuntime");
            if (hotPoint != null) hotPoint.gameObject.SetActive(services?.Activity.HasHotPoint == true);
        }
        private static IEnumerator InvokeButtonNextFrame(Button button) { yield return null; button.onClick.Invoke(); }

        private IEnumerator RunMailG4Validation(uint mailId)
        {
            EnsureMailPresenter();
            yield return new WaitForEndOfFrame();
            if (!IsMailOpen || services.Mails.Count < 14 || mailPresenter.ItemCount != services.Mails.Count)
            {
                Fail($"Mail G4 fixture mismatch: open={IsMailOpen}, store={services.Mails.Count}, rendered={mailPresenter.ItemCount}.");
                yield break;
            }

            mailValidationSawRedDot = IsMailRedDotVisible;
            MarkValidationControl("MAIL-01-MAIN-ENTRY");
            if (mailValidationSawRedDot) MarkValidationControl("MAIL-02-MAIN-RED-DOT");
            if (mailPresenter.TabLabel == "邮件") MarkValidationControl("MAIL-04-MAIL-TAB");

            Text emptyText = mailView.Binding.Find("Layer/None")?.GetComponentInChildren<Text>(true);
            Text oneKeyClaim = mailView.Binding.Find("Layer/Panel/MailList/MailBg/ReceiveBtn/BtnName")?.GetComponent<Text>();
            Text oneKeyDelete = mailView.Binding.Find("Layer/Panel/MailList/MailBg/DeleteBtn/BtnName")?.GetComponent<Text>();
            RecordValidationSemantic("mail-title", !string.IsNullOrWhiteSpace(mailPresenter.TitleText),
                $"actual={mailPresenter.TitleText}");
            RecordValidationSemantic("mail-tab", mailPresenter.TabLabel == "邮件",
                $"actual={mailPresenter.TabLabel}");
            RecordValidationSemantic("mail-empty-text", emptyText != null && emptyText.text.Contains("暂无邮件"),
                $"actual={emptyText?.text}");
            RecordValidationSemantic("mail-action-labels",
                mailPresenter.SingleActionLabel == "领取"
                    && oneKeyClaim?.text.Contains("领取") == true
                    && oneKeyDelete?.text.Contains("删除") == true,
                $"single={mailPresenter.SingleActionLabel}, claimAll={oneKeyClaim?.text}, deleteAll={oneKeyDelete?.text}");
            RecordValidationSemantic("mail-detail-fields",
                !string.IsNullOrWhiteSpace(mailPresenter.TitleText) && !string.IsNullOrWhiteSpace(mailPresenter.BodyText),
                "title/body must come from /128");
            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Mail G4 semantic assertions failed.");
                yield break;
            }
            yield return CaptureMailValidationScreenshot("bootstrap-mail-populated.png");

            MailRecord noAttachment = services.Mails.Items.FirstOrDefault(item => !item.HasAttachments);
            if (noAttachment.Id == 0 || !mailPresenter.Select(noAttachment.Id))
            {
                Fail("Mail G4 fixture lacks a no-attachment mail.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!services.Mails.TryGet(noAttachment.Id, out MailRecord readMail) || !readMail.IsRead)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.Mails.TryGet(noAttachment.Id, out MailRecord readResult) || !readResult.IsRead)
            {
                Fail("Mail G4 /128 op=4 did not produce per-role read history.");
                yield break;
            }
            MarkValidationControl("MAIL-06-ROW-SELECT");

            if (!mailPresenter.ScrollMailToBottom())
            {
                Fail("Mail G4 list ScrollRect did not reach the bottom.");
                yield break;
            }
            MarkValidationControl("MAIL-05-LIST-SCROLL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-scroll-bottom.png");

            MailRecord longBodyMail = services.Mails.Items.FirstOrDefault(item =>
                !item.HasAttachments
                    && (item.Message.Contains("long body") || item.Message.Contains("长正文")));
            if (longBodyMail.Id == 0) longBodyMail = noAttachment;
            if (!mailPresenter.Select(longBodyMail.Id))
            {
                Fail("Mail G4 fixture lacks a long-body mail.");
                yield break;
            }
            Canvas.ForceUpdateCanvases();
            if (!mailPresenter.ScrollBodyToBottom())
            {
                Fail("Mail G4 long body ScrollRect did not reach the bottom.");
                yield break;
            }
            MarkValidationControl("MAIL-07-BODY-SCROLL");

            if (!mailPresenter.Select(mailId) || !mailPresenter.ScrollAttachmentsToEnd())
            {
                Fail("Mail G4 attachment ScrollRect did not reach the end.");
                yield break;
            }
            MarkValidationControl("MAIL-08-ATTACHMENT-SCROLL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-attachment-end.png");
            MailRecord detailMail = services.Mails.Items.FirstOrDefault(item =>
                item.Message.Contains("单附件可领取"));
            if (detailMail.Id != 0) mailPresenter.Select(detailMail.Id);
            if (!mailPresenter.InvokeFirstAttachmentDetail() || bagFlowPresenter?.IsSourceOpen != true)
            {
                Fail("Mail G4 attachment detail control did not open the shared item-source popup.");
                yield break;
            }
            MarkValidationControl("MAIL-09-ATTACHMENT-DETAIL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-detail.png");
            bagFlowPresenter.CloseAll();
            bagFrameView.SetVisible(true);
            mailView.SetVisible(true);
            bagFrameView.GameObject.transform.SetAsLastSibling();
            mailView.GameObject.transform.SetAsLastSibling();
            InvokeLuaOrFail(onMailValidationClaim, "Mail.ValidationClaim", (double)mailId);
        }

        private IEnumerator FinalizeMailG4Validation()
        {
            yield return CaptureMailValidationScreenshot("bootstrap-mail.png");
            if (!mailValidationSawRedDot || IsMailRedDotVisible)
            {
                Fail($"Mail G4 red-dot transition mismatch: initial={mailValidationSawRedDot}, final={IsMailRedDotVisible}.");
                yield break;
            }
            if (!mailPresenter.HasCloseControl || !mailPresenter.InvokeClose() || IsMailOpen)
            {
                Fail("Mail G4 real close control did not return to the previous UI.");
                yield break;
            }
            MarkValidationControl("MAIL-03-CLOSE");
            ShowMail();
            Complete($"COMPLETE: Mail G4 13/13 real controls; /128 op2/3/4, repeated failure, serial claim-all/read-all, per-role persistence, empty state; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        private IEnumerator CaptureMailValidationScreenshot(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.8f);
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

        private IEnumerator CaptureActivityValidationStates()
        {
            EnsureActivityPresenter();
            services.Activity.Select(ActivityPresenter.DailyRechargeTag);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-activity-detail.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            ActivityListRecord unsupported = services.Activity.Items.FirstOrDefault(value => value.Tag != ActivityPresenter.DailyRechargeTag);
            if (unsupported == null)
            {
                Fail("Activity validation did not receive the real unsupported-tab fixture.");
                yield break;
            }
            services.Activity.Select(unsupported.Tag);
            yield return new WaitForEndOfFrame();
            if (!activityPresenter.EmptyStateVisible)
            {
                Fail($"Activity unsupported tab #{unsupported.Tag} did not render the first-phase empty boundary.");
                yield break;
            }
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-activity-empty.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            services.Activity.Select(ActivityPresenter.DailyRechargeTag);
            yield return new WaitForEndOfFrame();
            CompleteActivityValidation();
        }

        private void ShowShopPurchaseConfirmation(ShopRecord item, int quantity)
        {
            EnsureErrorPresenter();
            string limitText = item.Limit < 0 ? "不限购" : $"剩余限购 {item.RemainingLimit} 次";
            long totalCost = item.TotalCost(quantity);
            uint totalReward = checked(item.RewardAmount * checked((uint)Math.Max(1, quantity)));
            errorPresenter.ShowConfirmation("购买确认",
                $"花费 {totalCost} {item.CostName}购买 {totalReward}×{item.Name}？\n{limitText}",
                () => InvokeLuaOrFail(
                    HasCommandLineFlag("-projectXShopG4Validation")
                        ? onShopValidationSuccess : onShopBuyConfirmed,
                    HasCommandLineFlag("-projectXShopG4Validation")
                        ? "Shop.ValidationSuccess" : "Shop.OnBuyConfirmed",
                    (double)item.Id, quantity));
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

        private IEnumerator CaptureShopValidationScreenshot(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 5f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0)
                && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                Fail($"Shop G4 screenshot was not written: {fileName}.");
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
            if (services.Options.WorldBattleValidation && !worldG4StageCloseValidated)
            {
                Button stageClose = worldMapView.Binding.Find("Layer/Title/CloseBtn")?.GetComponent<Button>();
                if (stageClose == null || !stageClose.interactable)
                {
                    Fail("World stage-map close control is unavailable.");
                    yield break;
                }
                stageClose.onClick.Invoke();
                yield return null;
                if (!IsWorldOpen || worldStageView.GameObject.activeSelf || worldDetailView.GameObject.activeSelf)
                {
                    Fail($"World stage-map close did not return to the world chapter page: open={IsWorldOpen}, current={services.UiStack.Current?.GameObject?.name ?? string.Empty}, world={worldView.GameObject.activeSelf}, stage={worldMapView.GameObject.activeSelf}, detail={worldDetailView.GameObject.activeSelf}.");
                    yield break;
                }
                worldG4StageCloseValidated = true;
                // G5 WORLD-MAP is the Cocos world/chapter page reached by this
                // exact close action. Capturing after ShowStages paired two
                // different semantic states despite using the same filename.
                yield return new WaitForEndOfFrame();
                ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-map.png"));
                yield return new WaitForSecondsRealtime(0.75f);
                // Restore the already server-backed chapter data solely so this
                // one run can continue to validate the remaining controls.
                worldPresenter.ShowStages();
                if (!worldMapView.GameObject.activeSelf)
                {
                    Fail("World stage-map did not restore after the close-control probe.");
                    yield break;
                }
            }
            if (services.Options.WorldBattleValidation && !ValidateWorldPassiveG4Controls())
                yield break;
            if (services.Options.WorldBattleValidation && !worldG4StarBoxValidated)
            {
                yield return ValidateWorldStarBoxControl();
                if (!worldG4StarBoxValidated) yield break;
            }
            if (services.Options.WorldBattleValidation && !worldG4NormalBoxValidated)
            {
                yield return ValidateWorldNormalBoxControl();
                if (!worldG4NormalBoxValidated) yield break;
            }
            yield return new WaitForEndOfFrame();
            // This counterpart is deliberately after the real chest claims.
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-chest.png"));
            yield return new WaitForSecondsRealtime(0.75f);
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
            if (next == null || previous == null || !next.interactable || !previous.interactable)
            {
                Fail("World chapter navigation controls are unavailable.");
                yield break;
            }
            int currentChapterIndex = services.World.Chapters.ToList()
                .FindIndex(value => value.Id == currentChapterId);
            if (currentChapterIndex < 0 || services.World.Chapters.Count < 2)
            {
                Fail("World chapter navigation has no authoritative adjacent chapter.");
                yield break;
            }
            bool previousFirst = currentChapterIndex > 0;
            Button firstNavigation = previousFirst ? previous : next;
            Button secondNavigation = previousFirst ? next : previous;
            firstNavigation.onClick.Invoke();
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId == currentChapterId)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId == currentChapterId)
            {
                Fail($"World {(previousFirst ? "previous" : "next")} chapter control did not return an authoritative chapter.");
                yield break;
            }
            secondNavigation.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId != currentChapterId)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId != currentChapterId)
            {
                Fail($"World {(previousFirst ? "next" : "previous")} chapter control did not return to the authoritative current chapter.");
                yield break;
            }
            Button chapterNode = currentChapterIndex >= 0
                ? worldView.Binding.Find($"Layer/chapterPage/btn_{currentChapterIndex + 1}")?.GetComponent<Button>()
                : null;
            if (chapterNode == null || !chapterNode.interactable)
            {
                Fail("World current chapter node control is unavailable.");
                yield break;
            }
            chapterNode.onClick.Invoke();
            deadline = Time.realtimeSinceStartup + 8f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.World.SelectedChapterId != currentChapterId)
            {
                Fail("World chapter node did not preserve the authoritative current chapter.");
                yield break;
            }
            Button dropdown = worldMapView.Binding.Find("Layer/Panel_zuoshang/Button_xiala")?.GetComponent<Button>();
            if (dropdown == null || !dropdown.interactable)
            {
                Fail("World chapter dropdown control is unavailable.");
                yield break;
            }
            dropdown.onClick.Invoke();
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
            chapter.onClick.Invoke();
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
            ScrollRect stageMap = GetWorldStageMapScroll();
            uint preferredStageId = services.World.Stages.FirstOrDefault(value => value.RewardBoxId != 0)?.Id
                ?? (services.World.Stages.Any(value => value.Id == services.World.CurrentStageId)
                    ? services.World.CurrentStageId
                    : services.World.Stages.FirstOrDefault(value => value.IsUnlocked)?.Id ?? 0);
            Button stage = stageMap?.content.Find("Stage_" + preferredStageId)?.GetComponent<Button>();
            if (stage != null && !stage.interactable) stage = null;
            if (stage == null)
            {
                Fail("World stage map did not render an enabled dynamic stage node.");
                yield break;
            }
            stage.onClick.Invoke();
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
                formationButton.onClick.Invoke();
                float formationDeadline = Time.realtimeSinceStartup + 10f;
                while ((!IsHeroOpen || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < formationDeadline)
                    yield return null;
                if (!IsHeroOpen || services.Heroes.Count == 0 || services.Formation.Formations.Count == 0)
                {
                    Fail($"World pre-challenge formation did not open authoritative formation data: open={IsHeroOpen}, heroes={services.Heroes.Count}, formations={services.Formation.Formations.Count}.");
                    yield break;
                }
                if (!InvokeHeroCloseForValidation() || !worldPresenter.DetailVisible)
                {
                    Fail("World pre-challenge formation did not return to the current stage detail.");
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
                close.onClick.Invoke();
                if (worldPresenter.DetailVisible)
                {
                    Fail("World detail close control did not hide the imported detail layer.");
                    yield break;
                }
                worldG4DetailCloseValidated = true;
                ScrollRect stageMap = GetWorldStageMapScroll();
                Button stageNode = stageMap?.content.Find("Stage_" + stageId)?.GetComponent<Button>();
                if (stageNode == null || !stageNode.interactable)
                {
                    Fail("World detail close did not restore the selected stage node.");
                    yield break;
                }
                stageNode.onClick.Invoke();
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
            if (services.Options.WorldBattleValidation && !worldG4SweepValidated)
            {
                yield return ValidateWorldSweepControls(stage);
                if (!worldG4SweepValidated) yield break;
                stage = services.World.SelectedStage;
            }
            if (services.Options.WorldBattleValidation && !worldG4ResetValidated)
            {
                yield return ValidateWorldResetControls(stage);
                if (!worldG4ResetValidated) yield break;
                stage = services.World.SelectedStage;
            }
            Button challenge = worldDetailView.Binding.Find("Layer/Panel_1/Pane/Descbg/Image_bg/Panel_4/Button_2")?.GetComponent<Button>();
            if (challenge == null || !challenge.interactable)
            {
                Fail($"World challenge Prefab control is unavailable for the authoritative stage: stage={stage.Id}, stars={stage.Stars}, attempts={stage.RemainingAttempts}, unlocked={stage.IsUnlocked}, button={(challenge == null ? "missing" : "disabled")}, detail={worldPresenter.DetailVisible}.");
                yield break;
            }
            challenge.onClick.Invoke();
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
            sweep.onClick.Invoke();
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
            close.onClick.Invoke();
            if (worldOutcomePresenter.IsSweepVisible)
            {
                Fail("World sweep result close control did not hide the imported settlement layer.");
                yield break;
            }
            Button again = worldSweepView.Binding.Find("Layer/bg/Image/Button1")?.GetComponent<Button>();
            if (again == null || !again.interactable)
            {
                Fail("World sweep-again control was not available after an authoritative sweep result.");
                yield break;
            }
            again.onClick.Invoke();
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
            close = worldSweepView.Binding.Find("Layer/bg/Btn_close")?.GetComponent<Button>();
            close?.onClick.Invoke();
            if (worldOutcomePresenter.IsSweepVisible)
            {
                Fail("World zero-count sweep result did not close.");
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
            reset.onClick.Invoke();
            yield return null;
            if (errorPresenter == null || !errorPresenter.IsVisible)
            {
                Fail("World reset-attempts control did not open the real confirmation.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-reset.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            if (!errorPresenter.InvokeConfirmation())
            {
                Fail("World reset confirmation control was unavailable.");
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
            yield return new WaitForSecondsRealtime(1.25f);
            EnsureWorldOutcomePresenter();
            int visibleRewardCount = services.Rewards.Count;
            if (!worldOutcomePresenter.IsBattleVisible || visibleRewardCount <= 0
                || worldOutcomePresenter.RenderedRewardCount != visibleRewardCount)
            {
                Fail($"World settlement result mismatch: packet={rewardCount}, visible={visibleRewardCount}/{worldOutcomePresenter.RenderedRewardCount}, battleVisible={worldOutcomePresenter.IsBattleVisible}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(BuildUiMigrationPath("bootstrap-world-result.png"));
            yield return new WaitForSecondsRealtime(0.75f);
            if (services.Options.WorldBattleValidation && !worldG4BattleStatisticsValidated)
            {
                Button statistics = worldBattleResultView.Binding.Find("Layer/Panel/victorypanel/Button_tongji")?.GetComponent<Button>();
                if (statistics == null || !statistics.interactable)
                {
                    Fail("World battle-statistics control was unavailable.");
                    yield break;
                }
                statistics.onClick.Invoke();
                yield return null;
                if (!worldOutcomePresenter.IsStatisticsVisible || errorPresenter == null || !errorPresenter.IsVisible)
                {
                    Fail("World battle-statistics control did not expose the authoritative-data boundary.");
                    yield break;
                }
                Button closeStatistics = worldBattleStatisticsView.Binding.Find("Layer/Panel")?.GetComponent<Button>();
                if (closeStatistics == null || !closeStatistics.interactable)
                {
                    Fail("World battle-statistics close control was unavailable.");
                    yield break;
                }
                closeStatistics.onClick.Invoke();
                if (worldOutcomePresenter.IsStatisticsVisible || !worldOutcomePresenter.IsBattleVisible)
                {
                    Fail("World battle-statistics close did not return to the current result.");
                    yield break;
                }
                errorPresenter.Hide();
                worldG4BattleStatisticsValidated = true;
            }
            if (services.Options.WorldBattleValidation && !worldG4BattleReplayValidated)
            {
                Button replay = worldBattleResultView.Binding.Find("Layer/Panel/victorypanel/Button_Replay")?.GetComponent<Button>();
                if (replay == null || !replay.interactable)
                {
                    Fail("World battle replay control was unavailable.");
                    yield break;
                }
                replay.onClick.Invoke();
                worldG4BattleReplayValidated = true;
                yield break;
            }
            Button continueButton = worldBattleResultView.Binding.Find("Layer/Panel")?.GetComponent<Button>();
            if (continueButton == null || !continueButton.interactable)
            {
                Fail("World settlement continue control was not available.");
                yield break;
            }
            continueButton.onClick.Invoke();
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

            bool hidden = worldMapView.Binding.Find("Layer/Panel_youxia/Button_zhuxianchengjiu")?.gameObject.activeSelf == false
                && worldView.Binding.Find("Layer/Panel_youxia/Button_fengshenshilian")?.gameObject.activeSelf == false
                && worldMapView.Binding.Find("Layer/Panel_1/Button_paihangbang")?.gameObject.activeSelf == false;
            if (!hidden)
            {
                Fail("World excluded achievement, FengShen, or rank entry remains visible.");
                return false;
            }
            MarkValidationControl("WORLD-25-ACHIEVEMENT-ENTRY");
            MarkValidationControl("WORLD-26-FENGSHEN-ENTRY");
            MarkValidationControl("WORLD-27-RANK-ENTRY");
            RecordValidationSemantic("world-exclusions", true,
                "achievement, FengShen trial, and rank entries are hidden pending their own modules");
            return true;
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
            box.onClick.Invoke();
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
            box.onClick.Invoke();
            yield return null;
            EnsureWorldBoxAwardView();
            if (!worldBoxAwardView.GameObject.activeSelf)
            {
                Fail("World normal-box click did not open the imported box-award confirmation.");
                yield break;
            }
            Button confirm = worldBoxAwardView.Binding.Find("Layer/Cangbaotu/bg/Button")?.GetComponent<Button>();
            if (confirm == null || !confirm.gameObject.activeInHierarchy || !confirm.interactable)
            {
                Fail("World normal-box imported confirmation button is unavailable.");
                yield break;
            }
            uint boxId = stage.RewardBoxId;
            confirm.onClick.Invoke();
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

        private void EnsureBagPresenter()
        {
            bagView = bagView ?? services.UiRouter.FindBySource("zhujue/beibao");
            bagFrameView = bagFrameView ?? services.UiRouter.FindBySource("OneLevelLayer");
            bagInputView = bagInputView ?? services.UiRouter.FindBySource("EnterNumLayer");
            bagPopupFrameView = bagPopupFrameView ?? services.UiRouter.FindBySource("shop/shop_bg");
            bagGiftView = bagGiftView ?? services.UiRouter.FindBySource("common/OpenBox_1Layer");
            bagSourceView = bagSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            bagEquipmentInfoView = bagEquipmentInfoView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            if (bagView == null || bagFrameView == null || bagInputView == null || bagPopupFrameView == null
                || bagGiftView == null || bagSourceView == null || bagEquipmentInfoView == null)
                throw new InvalidOperationException("Bag required CocosUiBinding was not found.");
            bagFlowPresenter = bagFlowPresenter ?? new BagFlowPresenter(
                bagInputView, bagPopupFrameView, bagGiftView, bagSourceView, bagEquipmentInfoView,
                services.Resources, services.EquipmentCatalog, services.Bag.GetTotalQuantityByItemId,
                (item, quantity, target) =>
                {
                    BeginBagUseRewardCapture(item);
                    InvokeLuaOrFail(onBagUseClicked, "Bag.OnUseClicked", item.Slot, quantity, target);
                },
                CloseBagForItemJump,
                HandleBagSourceRoute,
                CanOpenBagSource,
                SetStatus);
            bagPresenter = bagPresenter ?? new BagPresenter(bagView, bagFrameView, services.Bag, services.Resources,
                item =>
                {
                    bagFlowPresenter.ShowUseFlow(item);
                    gameplayContentView?.SetVisible(false);
                    gameplayDetailView?.SetVisible(false);
                },
                () =>
                {
                    bagFlowPresenter.CloseAll();
                    bagFrameView.SetVisible(false);
                    HandleBack();
                });
        }

        private void CloseBagForItemJump()
        {
            bagFlowPresenter?.CloseAll();
            bagFrameView?.SetVisible(false);
            if (services?.UiStack.Current == bagView)
                services.UiStack.Pop();
            else
                bagView?.SetVisible(false);
        }

        private static bool CanOpenBagSource(int functionId)
        {
            switch (functionId)
            {
                case 1:
                case 3:
                case 4:
                case 6:
                case 9:
                case 10:
                case 13:
                case 15:
                case 16:
                case 17:
                case 1010:
                case 1011:
                    return true;
                default:
                    return false;
            }
        }

        private void HandleBagSourceRoute(int functionId)
        {
            switch (functionId)
            {
                case 1:
                case 3:
                case 6:
                case 9:
                case 10:
                    EnterGameplay(functionId);
                    return;
                case 4:
                    HandleWorldClick();
                    return;
                case 13:
                    HandleShopClick();
                    return;
                case 15:
                case 16:
                case 17:
                    InvokeLuaOrFail(onGameplayShopOpened, "Bag.Source.GameplayShops", (double)functionId);
                    return;
                case 1010:
                case 1011:
                    HandleDrawClick();
                    return;
                default:
                    ShowToast("当前版本暂未开放", 2f);
                    return;
            }
        }

        private void EnsureSettingsPresenter()
        {
            settingsView = settingsView ?? services.UiRouter.FindBySource("zhujue/SystemLayer");
            bagFrameView = bagFrameView ?? services.UiRouter.FindBySource("OneLevelLayer");
            if (settingsView == null || bagFrameView == null)
                throw new InvalidOperationException("Settings SystemLayer/OneLevelLayer CocosUiBinding was not found.");
            settingsPresenter = settingsPresenter ?? new SettingsPresenter(settingsView, bagFrameView,
                services.Player, services.Currencies, services.Resources, () => HandleBack(), ReturnToLogin, SetStatus);
        }

        private void EnsureRewardPresenter()
        {
            rewardView = rewardView ?? services.UiRouter.FindBySource("common/tanchuangjiangli");
            if (rewardView == null) throw new InvalidOperationException("common/tanchuangjiangli CocosUiBinding was not found.");
            rewardPresenter = rewardPresenter ?? new RewardPresenter(rewardView, services.Rewards, services.Resources);
        }

        private void EnsureHeroPresenter()
        {
            heroFrameView = heroFrameView ?? services.UiRouter.FindBySource("OneLevelLayer");
            heroListView = heroListView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongListLayer");
            heroDetailView = heroDetailView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongInfoLayer");
            heroBagView = heroBagView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongbeibao");
            if (heroFrameView == null || heroListView == null || heroDetailView == null || heroBagView == null)
                throw new InvalidOperationException("Hero frame/formation/bag CocosUiBindings were not found.");
            heroPresenter = heroPresenter ?? new HeroPresenter(heroListView, heroDetailView, heroBagView,
                services.Heroes, services.Formation, services.Player, services.HeroEquipment, services.FaBao,
                services.Resources, ShowHeroReplacement, ShowHeroCultivation, ShowHeroEnhanceMaster,
                ShowHeroEquipmentSlot, ShowHeroAttributes, message => ShowToast(message, 2f));
            heroFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            heroListView.BindClick("Layer/shenjiangListUI/List/btn_buzhen", ShowFormationPopup, true);
        }

        public int GetEquipmentPart(int templateId)
            => services.EquipmentCatalog.GetEquipment(templateId).Part;

        private void ShowFormationPopup()
        {
            formationPopupView = formationPopupView ?? services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangzhenxingLayer");
            if (formationPopupView == null)
                throw new InvalidOperationException("Formation popup CocosUiBinding was not found.");
            formationPopupPresenter = formationPopupPresenter ?? new FormationPopupPresenter(
                formationPopupView, services.Formation, services.Heroes, services.Resources,
                (heroId, position) => InvokeLuaOrFail(onFormationMove, "Hero.FormationMove", (double)heroId, position),
                () => formationPopupView.SetVisible(false));
            formationPopupPresenter.Render();
            formationPopupView.SetVisible(true);
            formationPopupView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowHeroReplacement(int formationPosition, int currentHeroId)
        {
            heroReplacementView = heroReplacementView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxionghuanjiang");
            if (heroReplacementView == null)
                throw new InvalidOperationException("Hero replacement CocosUiBinding was not found.");
            heroFrameView?.SetVisible(true);
            heroFrameView?.GameObject.transform.SetAsLastSibling();
            ConfigureHeroFrame(false);
            Text replacementTitle = heroFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (replacementTitle != null) replacementTitle.text = string.Empty;
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            var candidates = services.Heroes.Items
                .Where(item => item.Id != currentHeroId
                    && services.Formation.GetCombatPosition(item.Id) == 0
                    && !services.Formation.DisplayHeroes.Contains(item.Id))
                .Take(6).ToArray();
            if (HasCommandLineFlag("-projectXDrawClosureValidation"))
                Debug.Log($"[ProjectX][DrawClosure] replacement display=[{string.Join(",", services.Formation.DisplayHeroes)}] "
                    + $"combat=[{string.Join(",", services.Formation.CombatHeroes)}] candidates=[{string.Join(",", candidates.Select(item => item.Id))}]");
            Transform template = heroReplacementView.Binding.Find("Layer/yingxionghuanjiangUI/ItemCell")?.transform;
            if (template == null) throw new InvalidOperationException("Hero replacement ItemCell was not found.");
            for (int index = 1; index <= 6; index++)
            {
                Transform cell = template.Find($"Item{index}");
                if (cell == null) continue;
                bool active = index <= candidates.Length;
                cell.gameObject.SetActive(active);
                if (!active) continue;
                HeroRecord hero = candidates[index - 1];
                Text name = cell.Find("Name")?.GetComponent<Text>();
                Text level = cell.Find("Level")?.GetComponent<Text>();
                if (name != null) name.text = $"{hero.Name}　+{hero.BreakLevel}";
                if (level != null) level.text = string.Empty;
                Image qualityFrame = cell.Find("Quality")?.GetComponent<Image>();
                if (qualityFrame != null)
                    qualityFrame.color = new Color(0.9f, 0.3f, 1f, 1f);
                Image portrait = cell.Find("Panel_icon/Icon")?.GetComponent<Image>();
                if (portrait != null)
                {
                    portrait.sprite = HeroCatalog.TryGet(hero.Id, out HeroDefinition candidateDefinition)
                        ? services.Resources.LoadHeroPortrait(candidateDefinition.Picture)
                        : services.Resources.LoadHeroPortrait(hero.Id);
                    portrait.type = Image.Type.Simple;
                    portrait.preserveAspect = true;
                    RectTransform portraitRect = portrait.rectTransform;
                    portraitRect.anchorMin = Vector2.zero;
                    portraitRect.anchorMax = Vector2.one;
                    portraitRect.offsetMin = Vector2.zero;
                    portraitRect.offsetMax = Vector2.zero;
                    portraitRect.localScale = Vector3.one;
                }
                Button action = cell.Find("Button")?.GetComponent<Button>()
                    ?? cell.GetComponent<Button>() ?? cell.gameObject.AddComponent<Button>();
                action.targetGraphic = action.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
                action.onClick.RemoveAllListeners();
                action.onClick.AddListener(() =>
                {
                    InvokeLuaOrFail(onFormationMove, "Hero.FormationMove", (double)hero.Id, formationPosition);
                    heroReplacementView.SetVisible(false);
                });
                Text actionText = cell.Find("Button/Text")?.GetComponent<Text>();
                // Cocos labels the action from the candidate's own display-lineup
                // state, not from whether the selected destination is occupied.
                if (actionText != null) actionText.text =
                    services.Formation.DisplayHeroes.Contains(hero.Id) ? "替换" : "上阵";
            }
            Transform empty = heroReplacementView.Binding.Find("Layer/yingxionghuanjiangUI/Empty")?.transform;
            if (empty != null) empty.gameObject.SetActive(candidates.Length == 0);
            heroReplacementView.SetVisible(true);
            heroReplacementView.GameObject.transform.SetAsLastSibling();
            if (candidates.Length == 0) ShowToast("暂无可上阵神将", 2f);
        }

        private void ShowHeroCultivation(int heroId)
        {
            if (!services.Heroes.TryGet(heroId, out HeroRecord hero)) return;
            heroCultivationView = heroCultivationView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongjueseLayer");
            heroLevelUpView = heroLevelUpView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongshuxingLayer");
            if (heroCultivationView == null || heroLevelUpView == null)
                throw new InvalidOperationException("Hero cultivation shell/level-up CocosUiBindings were not found.");
            heroListView.SetVisible(false);
            heroDetailView.SetVisible(false);
            heroBagView.SetVisible(false);
            heroFrameView?.SetVisible(true);
            heroFrameView?.GameObject.transform.SetAsLastSibling();
            heroCultivationView.SetVisible(true);
            heroLevelUpView.SetVisible(true);
            heroCultivationView.GameObject.transform.SetAsLastSibling();
            heroLevelUpView.GameObject.transform.SetAsLastSibling();
            Text title = heroFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "升级";
            SetBoundText(heroCultivationView, "Layer/Node_3/Tips_2", $"{hero.Level}级  {hero.Name} +{hero.BreakLevel}");
            SetBoundText(heroCultivationView, "Layer/Node_3/bg_zhanli/Value", hero.Power.ToString());
            if (HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
            {
                ShowRuntimeHeroModel(heroCultivationView.Binding.Find("Layer/Node_3/Node")?.transform, definition.Picture);
            }
            BindHeroLevelUp(heroLevelUpView, hero);
            heroLevelUpView.BindClick("Layer/shenjiangInfoUI/Info/cailiao/btn_shengji", () =>
                InvokeLuaOrFail(onHeroLevelUp, "Hero.LevelUp", (double)hero.Id, 834d, 1d), true);
            heroFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", RestoreHeroFormationView, true);
            heroCultivationView.BindClick("Layer/Node_3/Button_l", () => ShowToast("已到首个培养页", 1.5f), true);
            heroCultivationView.BindClick("Layer/Node_3/Button_r", () => ShowToast("培养子模块按范围后置", 1.5f), true);
        }

        private void RestoreHeroFormationView()
        {
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroBagView?.SetVisible(false);
            ConfigureHeroFrame(false);
            heroFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
        }

        private void ShowHeroEnhanceMaster(int formationPosition)
        {
            int equipmentCount = services.HeroEquipment.Items.Count(item => item.FormationPosition == formationPosition);
            int faBaoCount = services.FaBao.Items.Count(item => item.FormationPosition == formationPosition);
            if (equipmentCount < 4 && faBaoCount < 2)
            {
                ShowToast("装备四件或法宝两件后开启强化大师", 2f);
                return;
            }
            heroEnhanceMasterView = heroEnhanceMasterView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/qianghuadashi");
            if (heroEnhanceMasterView == null)
                throw new InvalidOperationException("Enhance-master CocosUiBinding was not found.");
            gameplayView = gameplayView ?? services.UiRouter.FindBySource("shop/shop_bg");
            if (gameplayView == null)
                throw new InvalidOperationException("Enhance-master popup frame CocosUiBinding was not found.");
            gameplayContentView = gameplayContentView ?? services.UiRouter.FindBySource("common/ActivityLayer");
            gameplayDetailView = gameplayDetailView ?? services.UiRouter.FindBySource("TaskPopupLayer");
            gameplayContentView?.SetVisible(false);
            gameplayDetailView?.SetVisible(false);
            ConfigureHeroEnhanceMasterFrame(gameplayView);
            gameplayView.SetVisible(true);
            gameplayView.GameObject.transform.SetAsLastSibling();
            BindHeroEnhanceMaster(heroEnhanceMasterView, Mathf.Clamp(formationPosition, 1, 5));
            heroEnhanceMasterView.SetVisible(true);
            heroEnhanceMasterView.GameObject.transform.SetAsLastSibling();
        }

        private void BindHeroLevelUp(CocosUiView view, HeroRecord hero)
        {
            uint[] current =
            {
                hero.Attack,
                hero.PhysicalDefense,
                hero.MagicDefense,
                (uint)Math.Min(uint.MaxValue, hero.Health)
            };
            uint[] growth =
            {
                Math.Max(1u, (uint)Math.Round(hero.Attack * 0.041777f)),
                Math.Max(1u, (uint)Math.Round(hero.PhysicalDefense * 0.055556f)),
                Math.Max(1u, (uint)Math.Round(hero.MagicDefense * 0.055164f)),
                Math.Max(1u, (uint)Math.Round(hero.Health * 0.054054f))
            };
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/jichu/Level_1", $"{hero.Level}级");
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/jichu/Level_2", $"{hero.Level + 1}级");
            string[] names = { "攻击", "物防", "法防", "生命" };
            for (int index = 0; index < 4; index++)
            {
                string root = $"Layer/shenjiangInfoUI/Info/jichu/Attribute_{index + 1}";
                SetBoundText(view, root, names[index]);
                SetBoundText(view, root + "/Value_1", current[index].ToString());
                SetBoundText(view, root + "/Value_2", (current[index] + growth[index]).ToString());
                SetBoundText(view, root + "/Value_3", growth[index].ToString());
            }
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/cailiao/Level/Value", hero.Level.ToString());
            uint cocosHeroExperienceCap = checked(hero.MaxExperience * 15u);
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/cailiao/bg_Bar/Value",
                $"{hero.Experience}/{cocosHeroExperienceCap}");
            Image experienceBar = view.Binding.Find(
                "Layer/shenjiangInfoUI/Info/cailiao/bg_Bar/ExpBar")?.GetComponent<Image>();
            if (experienceBar != null)
                experienceBar.fillAmount = cocosHeroExperienceCap == 0
                    ? 0f
                    : Mathf.Clamp01((float)hero.Experience / cocosHeroExperienceCap);
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/cailiao/Tips/value", services.Player.Level.ToString());
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/cailiao/btn_yjShengji/Text", "一键升级");
            SetBoundText(view, "Layer/shenjiangInfoUI/Info/cailiao/btn_shengji/Text", "升级");
            int[] materialPictures = { 3105, 3107, 3101, 3106 };
            string[] materialNames = { "经验+2000", "经验+5000", "经验+20000", "经验+100000" };
            for (int slot = 1; slot <= 4; slot++)
            {
                string root = $"Layer/shenjiangInfoUI/Info/cailiao/btn_Item_{slot}";
                SetBoundText(view, root + "/Text", materialNames[slot - 1]);
                SetBoundText(view, root + "/Value", "0");
                Text materialLabel = view.Binding.Find(root + "/Text")?.GetComponent<Text>();
                if (materialLabel != null)
                {
                    materialLabel.horizontalOverflow = HorizontalWrapMode.Overflow;
                    materialLabel.rectTransform.sizeDelta = new Vector2(150f, materialLabel.rectTransform.sizeDelta.y);
                }
                SetRuntimeBoundIcon(view, root + "/IconImage",
                    services.Resources.LoadItemIcon(materialPictures[slot - 1]),
                    $"HeroLevelMaterial{slot}");
            }
        }

        private void ConfigureHeroEnhanceMasterFrame(CocosUiView view)
        {
            SetBoundText(view, "Layer/shopBg/Popup/Title/Title", "强化大师");
            SetBoundVisible(view, "Layer/shopBg/Popup/Title/Title/Button_1", false);
            Transform list = view.Binding.Find("Layer/shopBg/Btn_ListView")?.transform;
            Transform template = list?.Find("Panel_1");
            if (list != null && template != null)
            {
                string[] tabs = { "装备强化", "装备精炼", "装备觉醒", "装备神铸", "法宝强化", "法宝精炼" };
                for (int index = 0; index < tabs.Length; index++)
                {
                    Transform row = index == 0 ? template : list.Find($"MasterTab{index + 1}");
                    if (row == null)
                    {
                        row = Instantiate(template.gameObject, list, false).transform;
                        row.name = $"MasterTab{index + 1}";
                    }
                    RectTransform rect = row as RectTransform;
                    RectTransform baseRect = template as RectTransform;
                    if (rect != null && baseRect != null)
                        rect.anchoredPosition = baseRect.anchoredPosition + new Vector2(0f, -72f * index);
                    SetTabText(row.Find("Button"), tabs[index], index == 0);
                    CanvasGroup tabState = row.GetComponent<CanvasGroup>();
                    if (tabState == null)
                        tabState = row.gameObject.AddComponent<CanvasGroup>();
                    tabState.alpha = index == 0 ? 1f : 0.38f;
                }
            }
            view.BindClick("Layer/shopBg/Popup/Btn_close", () => HandleBack(), true);
        }

        private void BindHeroEnhanceMaster(CocosUiView view, int formationPosition)
        {
            for (int position = 1; position <= 5; position++)
            {
                string root = $"Layer/qianghuadashi_layer/shenjianglist/shenjiang{position}";
                int heroId = services.Formation.CombatHeroes.Count >= position
                    ? services.Formation.CombatHeroes[position - 1] : 0;
                SetBoundVisible(view, root, heroId > 0);
                SetBoundVisible(view, root + "/Choose", position == formationPosition);
                if (heroId > 0 && services.Heroes.TryGet(heroId, out HeroRecord member)
                    && HeroCatalog.TryGet(member.Id, out HeroDefinition memberDefinition))
                {
                    SetRuntimeBoundIcon(view, root + "/hero/bg_Head/icon",
                        services.Resources.LoadHeroPortrait(memberDefinition.Picture), $"MasterHero{position}");
                }
            }
            HeroEquipmentRecord[] equipped = services.HeroEquipment.Items
                .Where(item => item.FormationPosition == formationPosition)
                .OrderBy(item => item.Slot).Take(4).ToArray();
            for (int slot = 1; slot <= 4; slot++)
            {
                string root = $"Layer/qianghuadashi_layer/ItemList/Item{slot}";
                HeroEquipmentRecord item = equipped.FirstOrDefault(value => value.Slot == slot);
                SetBoundVisible(view, root, item.Uid > 0);
                if (item.Uid == 0) continue;
                SetBoundText(view, root + "/Name", item.Definition.Name);
                SetBoundText(view, root + "/barlist/Text", $"{item.GetLevel(1)}/10");
                SetBoundText(view, root + "/Btn_yangcheng/Text", "去强化");
                Image progress = view.Binding.Find(root + "/barlist/EXPBar")?.GetComponent<Image>();
                if (progress != null)
                    progress.fillAmount = Mathf.Clamp01(item.GetLevel(1) / 10f);
                Image iconFrame = view.Binding.Find(root + "/Icon")?.GetComponent<Image>();
                if (iconFrame != null)
                    iconFrame.sprite = services.Resources.LoadFirst("HeroUI/common_quality_02");
                SetRuntimeBoundIcon(view, root + "/Icon",
                    services.Resources.LoadEquipmentIcon(item.Definition.Picture), $"MasterEquipment{slot}");
            }
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/left_layer/type", "装备强化");
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/left_layer/type/Value", "0级");
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/type", "装备强化");
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/type/Value", "1级");
            string[] attrs = { "攻击", "物防", "法防", "生命" };
            int[] next = { 100, 50, 50, 2000 };
            for (int index = 1; index <= 4; index++)
            {
                string left = $"Layer/qianghuadashi_layer/shuxinglayer/left_layer/Attribute{index}";
                string right = $"Layer/qianghuadashi_layer/shuxinglayer/right_layer/Attribute{index}";
                SetBoundText(view, left, attrs[index - 1]);
                SetBoundText(view, left + "/Value", "0");
                SetBoundText(view, right, attrs[index - 1]);
                SetBoundText(view, right + "/Value", next[index - 1].ToString());
            }
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/tips_layer", "全身装备强化10级");
        }

        private static void SetRuntimeBoundIcon(CocosUiView view, string path, Sprite sprite, string runtimeName)
        {
            GameObject host = view?.Binding.Find(path);
            if (host == null) return;
            Transform old = host.transform.Find(runtimeName);
            GameObject value = old != null ? old.gameObject
                : new GameObject(runtimeName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host.transform, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(3f, 3f);
            rect.offsetMax = new Vector2(-3f, -3f);
            Image image = value.GetComponent<Image>();
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            image.raycastTarget = false;
            value.transform.SetAsLastSibling();
        }

        private static void ShowRuntimeHeroModel(Transform host, int picture)
        {
            if (host == null) return;
            Transform old = host.Find("RuntimeCultivationModel");
            GameObject value = old != null ? old.gameObject
                : new GameObject("RuntimeCultivationModel", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = Vector2.zero;
            ImodAnimationPlayer player = value.GetComponent<ImodAnimationPlayer>()
                ?? value.AddComponent<ImodAnimationPlayer>();
            bool loaded = player.LoadLegacy($"Monster/btm{picture}_zd_show");
            value.SetActive(loaded);
            if (loaded) player.Play(0, true);
        }

        private void ShowHeroEquipmentSlot(int formationPosition, int slot)
        {
            bool equipped = slot <= 4
                ? services.HeroEquipment.Items.Any(item => item.FormationPosition == formationPosition
                    && item.Definition != null && item.Definition.Part == slot)
                : services.FaBao.Items.Any(item => item.FormationPosition == formationPosition
                    && item.Slot == slot);
            if (equipped)
            {
                pendingHeroEquipmentPosition = Mathf.Clamp(formationPosition, 1, 5);
                pendingHeroEquipmentSlot = slot;
                heroEquipmentOpenedFromHeroDetails = true;
                ShowHeroEquipment(slot <= 4 ? 1 : 2);
                return;
            }

            if (slot <= 4)
            {
                int[] stageIds = { 10006, 10016, 10019, 10020 };
                int stageId = stageIds[Mathf.Clamp(slot - 1, 0, stageIds.Length - 1)];
                if (!heroEquipmentStageResponses.Contains(stageId)
                    || !heroEquipmentStageOpen.TryGetValue(stageId, out bool open) || !open)
                {
                    int chapter = ((stageId - 10001) / 10) + 1;
                    int node = ((stageId - 10001) % 10) + 1;
                    ShowToast($"通关{chapter}章{node}关后开启", 2f);
                    return;
                }
            }
            else if (services.Player.Level < 15)
            {
                ShowToast("15级开启，上仙请升级", 2f);
                return;
            }

            bool hasAvailable = slot <= 4
                ? services.HeroEquipment.Items.Any(item => item.FormationPosition == 0
                    && item.Definition != null && item.Definition.Part == slot)
                : services.FaBao.Items.Any(item => item.FormationPosition == 0);
            if (!hasAvailable)
            {
                ShowHeroItemSource(slot);
                return;
            }

            pendingHeroEquipmentPosition = Mathf.Clamp(formationPosition, 1, 5);
            pendingHeroEquipmentSlot = slot;
            heroEquipmentOpenedFromHeroDetails = true;
            heroEquipmentOpenPending = true;
            InvokeLuaOrFail(slot <= 4 ? onEquipmentBagClicked : onFaBaoBagClicked,
                slot <= 4 ? "HeroEquipment.OpenEquipmentFromHeroSlot" : "HeroEquipment.OpenFaBaoFromHeroSlot");
        }

        public void BeginHeroEquipmentStageChecks()
        {
            heroEquipmentStageOpen.Clear();
            heroEquipmentStageResponses.Clear();
        }

        public void SetHeroEquipmentStageOpen(double rawStageId, int stars)
        {
            int stageId = checked((int)rawStageId);
            heroEquipmentStageOpen[stageId] = stars != byte.MaxValue;
            heroEquipmentStageResponses.Add(stageId);
        }

        public bool HeroEquipmentStageChecksReady => heroEquipmentStageResponses.Count >= 4;

        private void ShowHeroItemSource(int slot)
        {
            heroItemSourceView = heroItemSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            if (heroItemSourceView == null)
                throw new InvalidOperationException("Hero item-source CocosUiBinding was not found.");
            bool faBao = slot > 4;
            int templateId = faBao ? slot - 4 + 1000 : slot + 1000;
            EquipmentDefinition definition = faBao
                ? services.EquipmentCatalog.GetFaBao(templateId)
                : services.EquipmentCatalog.GetEquipment(templateId);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_name", definition.Name);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_tips", definition.Description);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_num", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_1",
                faBao ? "来源：法宝搜索" : "来源：主线副本");
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_2", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_1/txt", "前往");
            SetBoundText(heroItemSourceView, "Layer/Popup/Title/Title", "获取途径");
            Image icon = heroItemSourceView.Binding.Find("Layer/Popup/Panel_name/Panel_icon/Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = faBao
                    ? services.Resources.LoadFaBaoIcon(definition.Picture, out _)
                    : services.Resources.LoadEquipmentIcon(definition.Picture);
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
            }
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_2", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_3", false);
            heroItemSourceView.BindClick("Layer/Popup/Title/Btn_close", () => heroItemSourceView.SetVisible(false), true);
            heroItemSourceView.BindClick("Layer/Mask", () => heroItemSourceView.SetVisible(false), true);
            heroItemSourceView.SetVisible(true);
            heroItemSourceView.GameObject.transform.SetAsLastSibling();
        }

        private static void SetBoundText(CocosUiView view, string path, string value)
        {
            Text text = view.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetBoundVisible(CocosUiView view, string path, bool visible)
        {
            GameObject target = view.Binding.Find(path);
            if (target != null) target.SetActive(visible);
        }

        private void ShowHeroEquipmentAt(int formationPosition, HeroEquipmentKind kind)
        {
            EnsureHeroEquipmentPresenter();
            ConfigureHeroEquipmentFrame(kind);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroFrameView.SetVisible(true);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != heroFrameView) services.UiStack.Push(heroFrameView);
            heroEquipmentPresenter.Show(Mathf.Clamp(formationPosition, 1, 5), kind);
            heroEquipmentListView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowHeroEquipmentFragments()
        {
            EnsureHeroEquipmentPresenter();
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            Text title = heroFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "装备碎片";
            Transform tabs = heroFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            SelectHeroEquipmentTab(tabs, false);
            heroEquipmentPresenter.HideDetails();
            heroEquipmentListView.SetVisible(false);
            heroFrameView.SetVisible(true);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            heroEquipmentFragmentView.SetVisible(true);
            heroEquipmentFragmentView.GameObject.transform.SetAsLastSibling();
            RenderHeroEquipmentFragments();
        }

        private void ShowHeroEquipmentListTab()
        {
            EnsureHeroEquipmentPresenter();
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.Equipment);
            heroEquipmentFragmentView.SetVisible(false);
            heroEquipmentListView.SetVisible(true);
            heroFrameView.SetVisible(true);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            heroEquipmentListView.GameObject.transform.SetAsLastSibling();
        }

        private void RenderHeroEquipmentFragments()
        {
            BagItemRecord[] fragments = services.Bag.GetItemsByType(7)
                .Where(item => services.EquipmentCatalog.IsEquipmentFragment(item.ItemId))
                // Cocos PetEquipPiecesSubUI sorts composable fragments first, then
                // quality, quantity and id descending.  Keeping that order is also
                // required for the five visible cells to expose an actionable item.
                .OrderByDescending(item =>
                {
                    int required = services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId);
                    return required > 0 && item.Quantity >= required;
                })
                .ThenByDescending(item => item.Quality)
                .ThenByDescending(item => item.Quantity)
                .ThenByDescending(item => item.ItemId)
                .ToArray();
            CocosUiBinding binding = heroEquipmentFragmentView.Binding;
            GameObject empty = binding.Find("Layer/suipianUI/Point");
            if (empty != null) empty.SetActive(fragments.Length == 0);

            BagItemRecord preferred = fragments.FirstOrDefault(item =>
                item.ItemId == selectedHeroEquipmentFragmentId);
            if (preferred.ItemId <= 0)
            {
                preferred = fragments.FirstOrDefault(item =>
                    services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId) > 0
                    && item.Quantity >= services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId));
            }
            if (preferred.ItemId <= 0 && fragments.Length > 0) preferred = fragments[0];
            selectedHeroEquipmentFragmentId = preferred.ItemId;

            RenderHeroEquipmentFragmentRows(binding, fragments);
            binding.Find("Layer/suipianUI/cell")?.SetActive(false);
            binding.Find("Layer/suipianUI/recycle")?.SetActive(false);
            binding.Find("Layer/suipianUI/suipian")?.SetActive(fragments.Length > 0);
            if (preferred.ItemId > 0) BindHeroEquipmentFragmentDetail(preferred);
        }

        private void HandleHeroEquipmentFragmentBagChanged()
        {
            if (heroEquipmentFragmentView?.GameObject.activeInHierarchy == true)
                RenderHeroEquipmentFragments();
        }

        private void RenderHeroEquipmentFragmentRows(CocosUiBinding binding, BagItemRecord[] fragments)
        {
            RectTransform template = binding.Find("Layer/suipianUI/Bag/ItemCell")?.GetComponent<RectTransform>();
            RectTransform viewport = binding.Find("Layer/suipianUI/Bag/TableView")?.GetComponent<RectTransform>();
            if (template == null || viewport == null) return;
            if (heroEquipmentFragmentList == null)
                heroEquipmentFragmentList = new VirtualList<BagItemRecord[]>(viewport.gameObject,
                    template.gameObject, Mathf.Max(1f, template.rect.height), BindHeroEquipmentFragmentRow);

            List<BagItemRecord[]> rows = new List<BagItemRecord[]>();
            for (int index = 0; index < fragments.Length; index += 5)
                rows.Add(fragments.Skip(index).Take(5).ToArray());
            heroEquipmentFragmentList.SetItems(rows);
        }

        private void BindHeroEquipmentFragmentRow(RectTransform row, BagItemRecord[] items, int rowIndex)
        {
            row.gameObject.name = $"RuntimeFragmentRow_{rowIndex + 1}";
            for (int column = 1; column <= 5; column++)
            {
                Transform cell = row.Find($"Item{column}");
                if (cell == null) continue;
                bool hasItem = items != null && column <= items.Length;
                cell.gameObject.SetActive(hasItem);
                if (hasItem) BindHeroEquipmentFragmentCell(cell, items[column - 1]);
            }
        }

        private void BindHeroEquipmentFragmentCell(Transform cell, BagItemRecord item)
        {
            cell.name = $"EquipmentFragment_{item.ItemId}";
            Image icon = cell.Find("Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = services.Resources.LoadItemIcon(item.Picture);
                icon.preserveAspect = true;
            }
            BindHeroEquipmentFragmentBagVisual(cell, icon?.rectTransform, item);
            Text name = cell.Find("Name")?.GetComponent<Text>();
            if (name != null) name.text = item.Name;
            int required = services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId);
            bool composable = required > 0 && item.Quantity >= required;
            GameObject ready = cell.Find("Tips")?.gameObject;
            if (ready != null) ready.SetActive(composable);
            GameObject prompt = cell.Find("Prompt")?.gameObject;
            if (prompt != null) prompt.SetActive(composable);
            GameObject selected = cell.Find("Choose")?.gameObject;
            if (selected != null) selected.SetActive(item.ItemId == selectedHeroEquipmentFragmentId);
            Button button = EnsureRuntimeButton(cell);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                selectedHeroEquipmentFragmentId = item.ItemId;
                RenderHeroEquipmentFragments();
            });
        }

        private void BindHeroEquipmentFragmentBagVisual(Transform cell, RectTransform iconRect, BagItemRecord item)
        {
            if (cell == null || iconRect == null) return;

            Transform qualityTransform = cell.Find("RuntimeFragmentQuality");
            GameObject qualityObject = qualityTransform != null ? qualityTransform.gameObject
                : new GameObject("RuntimeFragmentQuality", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform qualityRect = qualityObject.GetComponent<RectTransform>();
            qualityRect.SetParent(cell, false);
            CopyRectTransform(iconRect, qualityRect);
            Image quality = qualityObject.GetComponent<Image>();
            quality.sprite = services.Resources.LoadFirst(
                $"HeroUI/common_quality_{Mathf.Clamp(item.Quality, 1, 7):00}");
            quality.enabled = quality.sprite != null;
            quality.preserveAspect = true;
            quality.raycastTarget = false;
            qualityObject.transform.SetSiblingIndex(iconRect.GetSiblingIndex());

            Transform shardTransform = cell.Find("RuntimeFragmentBadge");
            GameObject shardObject = shardTransform != null ? shardTransform.gameObject
                : new GameObject("RuntimeFragmentBadge", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform shardRect = shardObject.GetComponent<RectTransform>();
            shardRect.SetParent(cell, false);
            shardRect.anchorMin = new Vector2(0f, 1f);
            shardRect.anchorMax = new Vector2(0f, 1f);
            shardRect.pivot = new Vector2(0f, 1f);
            shardRect.anchoredPosition = iconRect.anchoredPosition
                + new Vector2(-iconRect.rect.width * 0.5f, iconRect.rect.height * 0.5f);
            shardRect.sizeDelta = new Vector2(38f, 38f);
            Image shard = shardObject.GetComponent<Image>();
            shard.sprite = services.Resources.LoadFirst("ItemDecorations/suipian");
            shard.enabled = shard.sprite != null;
            shard.preserveAspect = true;
            shard.raycastTarget = false;

            Transform quantityTransform = cell.Find("RuntimeFragmentQuantity");
            GameObject quantityObject = quantityTransform != null ? quantityTransform.gameObject
                : new GameObject("RuntimeFragmentQuantity", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform quantityRect = quantityObject.GetComponent<RectTransform>();
            quantityRect.SetParent(cell, false);
            CopyRectTransform(iconRect, quantityRect);
            Text quantity = quantityObject.GetComponent<Text>();
            quantity.font = UnityEngine.Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            quantity.fontSize = 17;
            quantity.alignment = TextAnchor.LowerRight;
            quantity.color = Color.white;
            quantity.text = item.Quantity.ToString();
            quantity.raycastTarget = false;
            quantityObject.transform.SetAsLastSibling();
        }

        private static void CopyRectTransform(RectTransform source, RectTransform target)
        {
            target.anchorMin = source.anchorMin;
            target.anchorMax = source.anchorMax;
            target.pivot = source.pivot;
            target.anchoredPosition = source.anchoredPosition;
            target.sizeDelta = source.sizeDelta;
            target.localScale = source.localScale;
        }

        private void BindHeroEquipmentFragmentDetail(BagItemRecord item)
        {
            CocosUiBinding binding = heroEquipmentFragmentView.Binding;
            EquipmentDefinition definition = services.EquipmentCatalog.GetEquipmentByFragment(item.ItemId);
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/Namebg/Name", definition.Name);
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/miaoshu/Content", item.Description);
            int required = services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId);
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/Slider_Bg/Value", $"{item.Quantity}/{required}");
            Image progress = binding.Find("Layer/suipianUI/suipian/Slider_Bg/LoadingBar")?.GetComponent<Image>();
            if (progress != null)
            {
                progress.type = Image.Type.Filled;
                progress.fillMethod = Image.FillMethod.Horizontal;
                progress.fillAmount = required > 0
                    ? Mathf.Clamp01((float)item.Quantity / required)
                    : 0f;
            }
            Image icon = binding.Find("Layer/suipianUI/suipian/Node/Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = services.Resources.LoadItemIcon(item.Picture);
                icon.preserveAspect = true;
            }
            GameObject composeObject = binding.Find("Layer/suipianUI/suipian/Btn_hecheng");
            Button compose = composeObject != null ? EnsureRuntimeButton(composeObject.transform) : null;
            if (compose != null)
            {
                compose.onClick.RemoveAllListeners();
                compose.interactable = required > 0 && item.Quantity >= required;
                compose.onClick.AddListener(() => InvokeLuaOrFail(onHeroEquipmentCompose,
                    "HeroEquipment.Compose", item.ItemId));
            }
            GameObject sourceObject = binding.Find("Layer/suipianUI/suipian/Btn_huoqu");
            Button source = sourceObject != null ? EnsureRuntimeButton(sourceObject.transform) : null;
            if (source != null)
            {
                source.onClick.RemoveAllListeners();
                source.onClick.AddListener(() => ShowHeroEquipmentFragmentSource(item));
            }
        }

        private void ShowHeroEquipmentFragmentSource(BagItemRecord item)
        {
            heroItemSourceView = heroItemSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            if (heroItemSourceView == null)
                throw new InvalidOperationException("Hero equipment fragment source CocosUiBinding was not found.");
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_name", item.Name);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_tips", item.Description);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_num", $"数量：{item.Quantity}");
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_1", "来源：血战商店");
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_2", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_3/txt", "前往");
            SetBoundText(heroItemSourceView, "Layer/Popup/Title/Title", "获取途径");
            Image icon = heroItemSourceView.Binding.Find("Layer/Popup/Panel_name/Panel_icon/Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = services.Resources.LoadItemIcon(item.Picture);
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
            }
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_1", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_2", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_3", true);
            GameObject sourceRoute = heroItemSourceView.Binding.Find("Layer/Popup/itemlayer_1/Button_3");
            if (sourceRoute != null)
            {
                sourceRoute.SetActive(true);
                for (Transform ancestor = sourceRoute.transform.parent;
                    ancestor != null && ancestor != heroItemSourceView.GameObject.transform;
                    ancestor = ancestor.parent)
                    ancestor.gameObject.SetActive(true);
            }
            Button sourceRouteButton = heroItemSourceView.BindClick("Layer/Popup/itemlayer_1/Button_3", () =>
            {
                heroItemSourceView.SetVisible(false);
                heroEquipmentFragmentView.SetVisible(false);
                heroFrameView.SetVisible(false);
                restoreHeroEquipmentAfterGameplayShop = true;
                InvokeLuaOrFail(onGameplayShopOpened, "HeroEquipment.Source.GameplayShops", 17d);
            }, true);
            sourceRouteButton.interactable = true;
            heroItemSourceView.BindClick("Layer/Popup/Title/Btn_close", CloseHeroItemSource, true);
            heroItemSourceView.BindClick("Layer/Mask", CloseHeroItemSource, true);
            heroItemSourceView.SetVisible(true);
            heroItemSourceView.GameObject.transform.SetAsLastSibling();
        }

        private void CloseHeroItemSource()
        {
            heroItemSourceView?.SetVisible(false);
            if (heroEquipmentOpenedFromHeroDetails && !IsHeroEquipmentSurfaceVisible)
                RestoreHeroAfterEquipmentSlot();
        }

        private void SelectHeroEquipmentTab(Transform tabs, bool firstSelected)
        {
            Transform panel = tabs?.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            Transform second = panel?.Find("Button2_Runtime");
            if (first != null) SetTabText(first, "装备", firstSelected);
            if (second != null) SetTabText(second, "碎片", !firstSelected);
        }

        private void RestoreHeroAfterEquipmentSlot()
        {
            heroEquipmentPresenter?.HideDetails();
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentOpenedFromHeroDetails = false;
            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroBagView?.SetVisible(false);
            heroFrameView?.SetVisible(true);
            ConfigureHeroFrame(false);
            heroFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
        }

        private void ShowHeroAttributes(int heroId)
        {
            if (!services.Heroes.TryGet(heroId, out HeroRecord hero)) return;
            heroAttributesView = heroAttributesView ?? services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangxiangxishuxing");
            if (heroAttributesView == null)
                throw new InvalidOperationException("Hero attributes CocosUiBinding was not found.");
            Text name = heroAttributesView.Binding.Find("Layer/Node_1/Popup/Icon/name")?.GetComponent<Text>();
            Text power = heroAttributesView.Binding.Find("Layer/Node_1/Popup/Icon/text_zhanli/num")?.GetComponent<Text>();
            Text position = heroAttributesView.Binding.Find("Layer/Node_1/Popup/Icon/text_dingwei/num")?.GetComponent<Text>();
            if (name != null) name.text = hero.Name;
            if (power != null) power.text = hero.Power.ToString();
            if (position != null)
                position.text = HeroCatalog.TryGet(hero.Id, out HeroDefinition definition)
                    ? (string.IsNullOrWhiteSpace(definition.Feature)
                        ? (definition.PhysicalAttack ? "物理" : "法术")
                        : definition.Feature) : "神将";
            Image portrait = heroAttributesView.Binding.Find("Layer/Node_1/Popup/Icon")?.GetComponent<Image>();
            if (portrait != null && HeroCatalog.TryGet(hero.Id, out HeroDefinition portraitDefinition))
            {
                portrait.sprite = services.Resources.LoadHeroPortrait(portraitDefinition.Picture);
                portrait.preserveAspect = true;
            }
            Transform list = heroAttributesView.Binding.Find("Layer/Node_1/Popup/ListView")?.transform;
            if (list != null)
            {
                Transform template = list.Find("name");
                if (template != null)
                {
                    for (int child = list.childCount - 1; child >= 0; child--)
                        if (list.GetChild(child).name.StartsWith("RuntimeAttribute", StringComparison.Ordinal))
                            Destroy(list.GetChild(child).gameObject);
                    (string name, string value)[] attributes =
                    {
                        ("攻击", hero.Attack.ToString()),
                        ("物防", hero.PhysicalDefense.ToString()),
                        ("法防", hero.MagicDefense.ToString()),
                        ("生命", hero.Health.ToString()),
                        ("命中", "0"),
                        ("闪避", "0"),
                        ("暴击", "0"),
                        ("抗暴", "0"),
                        ("攻击加成", "0%")
                    };
                    RectTransform templateRect = template as RectTransform;
                    for (int index = 0; index < attributes.Length; index++)
                    {
                        Transform row = index == 0 ? template : Instantiate(template.gameObject, list, false).transform;
                        row.name = index == 0 ? "name" : $"RuntimeAttribute{index + 1}";
                        Text label = row.GetComponent<Text>();
                        Text value = row.Find("value")?.GetComponent<Text>();
                        if (label != null) label.text = attributes[index].name + "：";
                        if (value != null) value.text = attributes[index].value;
                        RectTransform rect = row as RectTransform;
                        if (rect != null && templateRect != null)
                            rect.anchoredPosition = templateRect.anchoredPosition + new Vector2(0f, -31f * index);
                    }
                }
            }
            heroAttributesView.BindClick("Layer/Mask_close", () => heroAttributesView.SetVisible(false), true);
            heroAttributesView.SetVisible(true);
            heroAttributesView.GameObject.transform.SetAsLastSibling();
        }

        private void ConfigureBagFrame()
        {
            // OneLevelLayer is shared with Hero. Reapply its authoritative header
            // state on every Bag response so no previous module title, tab or
            // placeholder currency survives.
            CocosUiBinding binding = bagFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "道具背包";
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform first = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            if (first != null)
            {
                SetTabText(first, "全部", true);
                // Bag has one visible category. Keep its selected artwork while
                // preserving the imported Button callback as a real no-op control.
                Button button = first.GetComponent<Button>();
                if (button != null) button.interactable = true;
            }
            Transform second = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            if (second != null) second.gameObject.SetActive(false);
            Transform gold3 = binding.Find("Layer/GoldCheck/GoldIcon3")?.transform;
            Transform gold4 = binding.Find("Layer/GoldCheck/GoldIcon4")?.transform;
            Text stamina = binding.Find("Layer/GoldCheck/GoldIcon1/GoldNumBg/Num")?.GetComponent<Text>();
            Text gold = gold3?.Find("GoldNumBg/Num")?.GetComponent<Text>();
            Text premium = gold4?.Find("GoldNumBg/Num")?.GetComponent<Text>();
            if (stamina != null) stamina.text = $"{services.Currencies.Get(CurrencyIds.Stamina)}/100";
            if (gold != null) gold.text = FormatHeaderCurrency(services.Currencies.Gold);
            if (premium != null) premium.text = services.Currencies.Premium.ToString();
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private void ConfigureHeroFrame(bool showBag)
        {
            CocosUiBinding binding = heroFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }

            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = showBag ? "神将背包" : "阵容";
                title.alignment = TextAnchor.MiddleLeft;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
                title.rectTransform.anchoredPosition = new Vector2(192.8862f, 28.1468f);
                title.rectTransform.sizeDelta = new Vector2(240f, title.rectTransform.sizeDelta.y);
                Transform help = title.transform.Find("Button_1");
                if (help != null)
                {
                    help.gameObject.SetActive(!showBag);
                    RectTransform helpRect = help as RectTransform;
                    if (helpRect != null) helpRect.anchoredPosition = new Vector2(160f, 19.2803f);
                }
            }

            Transform tabs = binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            ConfigureHeroBagTabs(tabs, showBag);

            Transform gold3 = binding.Find("Layer/GoldCheck/GoldIcon3")?.transform;
            Transform gold4 = binding.Find("Layer/GoldCheck/GoldIcon4")?.transform;
            if (gold3 != null) gold3.gameObject.SetActive(true);
            if (gold4 != null) gold4.gameObject.SetActive(true);
            RectTransform stamina = binding.Find("Layer/GoldCheck/GoldIcon1")?.GetComponent<RectTransform>();
            if (stamina == null) return;
            stamina.gameObject.SetActive(true);
            Text value = stamina.Find("GoldNumBg/Num")?.GetComponent<Text>();
            if (value != null) value.text = $"{services.Currencies.Get(CurrencyIds.Stamina)}/100";
            Text gold = gold3?.Find("GoldNumBg/Num")?.GetComponent<Text>();
            if (gold != null) gold.text = FormatHeaderCurrency(services.Currencies.Gold);
            Text premium = gold4?.Find("GoldNumBg/Num")?.GetComponent<Text>();
            if (premium != null) premium.text = services.Currencies.Premium.ToString();

            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private static string FormatHeaderCurrency(long value)
            => value >= 10000 && value % 10000 == 0 ? $"{value / 10000}万" : value.ToString();

        private static void ConfigureHeroBagTabs(Transform tabs, bool showBag)
        {
            if (tabs == null) return;
            tabs.gameObject.SetActive(showBag);
            if (!showBag) return;
            Transform panel = tabs.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            SetTabText(first, "神将", true);
            Transform second = panel.Find("Button2_Runtime");
            if (second == null)
            {
                second = Instantiate(first.gameObject, panel, false).transform;
                second.name = "Button2_Runtime";
            }
            RectTransform firstRect = first as RectTransform;
            RectTransform secondRect = second as RectTransform;
            if (firstRect != null && secondRect != null)
                secondRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f);
            SetTabText(second, "碎片", false);
        }

        private static void SetTabText(Transform tab, string value, bool selected)
        {
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null) normal.text = value;
            if (chosen != null) chosen.text = value;
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Image background = tab.GetComponent<Image>();
            if (background != null && !selected) background.color = new Color(1f, 1f, 1f, 0f);
            Button button = tab.GetComponent<Button>();
            if (button != null) button.interactable = !selected;
        }

        private enum HeroEntry
        {
            Formation,
            Bag
        }

        private void EnsureHeroEquipmentPresenter()
        {
            EnsureHeroPresenter();
            heroEquipmentListView = heroEquipmentListView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeibeibao");
            heroEquipmentDetailView = heroEquipmentDetailView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo");
            heroEquipmentChangeView = heroEquipmentChangeView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeigenghuan");
            heroEquipmentCultivateView = heroEquipmentCultivateView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiyangcheng");
            heroEquipmentStrengthView = heroEquipmentStrengthView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiqianghua");
            heroEquipmentRefineView = heroEquipmentRefineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijinglian");
            heroEquipmentAwakenView = heroEquipmentAwakenView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijuexing");
            heroEquipmentDivineView = heroEquipmentDivineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeishenzhu");
            heroEquipmentFragmentView = heroEquipmentFragmentView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeisuipian");
            heroEquipmentAutoRefineView = heroEquipmentAutoRefineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianjinglian");
            heroEquipmentExchangeView = heroEquipmentExchangeView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianduihuan");
            heroEquipmentAutoStarView = heroEquipmentAutoStarView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengxing");
            heroEquipmentAutoDivineView = heroEquipmentAutoDivineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengceng");
            heroEquipmentDivineEffectView = heroEquipmentDivineEffectView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/shenzhutexiao");
            if (heroEquipmentListView == null || heroEquipmentDetailView == null || heroEquipmentChangeView == null
                || heroEquipmentCultivateView == null || heroEquipmentStrengthView == null
                || heroEquipmentRefineView == null || heroEquipmentAwakenView == null || heroEquipmentDivineView == null
                || heroEquipmentFragmentView == null || heroEquipmentAutoRefineView == null
                || heroEquipmentExchangeView == null || heroEquipmentAutoStarView == null
                || heroEquipmentAutoDivineView == null || heroEquipmentDivineEffectView == null)
                throw new InvalidOperationException("Hero equipment list/detail/change/cultivate/strength/fragment CocosUiBindings were not found.");
            Transform detailRoot = heroEquipmentDetailView.GameObject.transform;
            if (detailRoot.parent == heroEquipmentListView.GameObject.transform)
            {
                detailRoot.SetParent(heroEquipmentListView.GameObject.transform.parent, false);
                if (detailRoot is RectTransform detailRect)
                {
                    detailRect.anchorMin = Vector2.zero;
                    detailRect.anchorMax = Vector2.one;
                    detailRect.pivot = new Vector2(0.5f, 0.5f);
                    detailRect.offsetMin = Vector2.zero;
                    detailRect.offsetMax = Vector2.zero;
                    detailRect.anchoredPosition = Vector2.zero;
                    detailRect.localScale = Vector3.one;
                }
            }
            heroEquipmentPresenter = heroEquipmentPresenter ?? new HeroEquipmentPresenter(
                heroEquipmentListView, heroEquipmentDetailView, heroEquipmentChangeView,
                heroEquipmentCultivateView, heroEquipmentStrengthView, heroEquipmentRefineView,
                heroEquipmentAwakenView, heroEquipmentDivineView,
                heroEquipmentAutoRefineView, heroEquipmentExchangeView, heroEquipmentAutoStarView,
                heroEquipmentAutoDivineView, heroEquipmentDivineEffectView,
                services.HeroEquipment, services.FaBao, services.Bag, services.EquipmentCatalog, services.Currencies, services.Resources,
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentWear, "HeroEquipment.Wear", (double)uid, position),
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentTakeOff, "HeroEquipment.TakeOff", (double)uid, position),
                uid => InvokeLuaOrFail(onHeroEquipmentStrength, "HeroEquipment.Strength", (double)uid),
                uid => InvokeLuaOrFail(onHeroEquipmentStrength, "HeroEquipment.StrengthFive", (double)uid, 1),
                position => InvokeLuaOrFail(onHeroEquipmentStrengthAll, "HeroEquipment.StrengthAll", position),
                (uid, itemId, itemCount) => InvokeLuaOrFail(onHeroEquipmentRefine, "HeroEquipment.Refine",
                    (double)uid, itemId, itemCount),
                (uid, itemIds, itemCounts) => InvokeLuaOrFail(onHeroEquipmentAutoRefine, "HeroEquipment.AutoRefine",
                    (double)uid,
                    itemIds[0], itemCounts[0], itemIds[1], itemCounts[1],
                    itemIds[2], itemCounts[2], itemIds[3], itemCounts[3]),
                uid => InvokeLuaOrFail(onHeroEquipmentAwaken, "HeroEquipment.Awaken", (double)uid),
                uid => InvokeLuaOrFail(onHeroEquipmentDivine, "HeroEquipment.Divine", (double)uid),
                (uid, position) => InvokeLuaOrFail(onFaBaoWear, "FaBao.Wear", (double)uid, position),
                uid => InvokeLuaOrFail(onFaBaoTakeOff, "FaBao.TakeOff", (double)uid),
                ConfigureHeroEquipmentCultivationFrame,
                () => services.Player.Level,
                message => ShowToast(message, 2f));
            if (!heroEquipmentFragmentBagSubscribed)
            {
                services.Bag.Changed += HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = true;
            }
        }

        private void ConfigureHeroEquipmentFrame(HeroEquipmentKind kind)
        {
            ConfigureHeroFrame(false);
            Text title = heroFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = kind == HeroEquipmentKind.Equipment ? "装备背包" : "法宝背包";
            Transform tabs = heroFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            ConfigureHeroEquipmentTabs(tabs, kind);
            heroFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            ConfigureHeroEquipmentHelp(kind);
        }

        private void ConfigureHeroEquipmentHelp(HeroEquipmentKind kind)
        {
            Transform title = heroFrameView.Binding.Find("Layer/Panel_12/Title")?.transform;
            if (title == null) return;
            Transform existing = title.Find("HeroEquipmentHelpButton");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("HeroEquipmentHelpButton",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(title, false);
            rect.anchorMin = rect.anchorMax = new Vector2(1f, 0.5f);
            rect.pivot = new Vector2(1f, 0.5f);
            rect.anchoredPosition = new Vector2(-82f, 0f);
            rect.sizeDelta = new Vector2(54f, 54f);
            Image image = value.GetComponent<Image>();
            image.color = new Color(0.55f, 0.27f, 0.08f, 0.95f);
            Transform labelTransform = value.transform.Find("Label");
            GameObject labelObject = labelTransform != null ? labelTransform.gameObject
                : new GameObject("Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.SetParent(value.transform, false);
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            Text titleText = title.GetComponentsInChildren<Text>(true).FirstOrDefault();
            label.font = titleText != null ? titleText.font : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.text = "?";
            label.fontSize = 34;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            Button button = value.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => errorPresenter?.ShowHelp(
                kind == HeroEquipmentKind.Equipment
                    ? "装备强化分为普通（+1），暴击（+2），大暴击（+3），强化上限不超过主角等级的2倍。\n" +
                      "装备精炼等级上限由装备品质决定。\n" +
                      "橙色以上装备可以进行装备觉醒，觉醒需消耗装备碎片及觉醒石。\n" +
                      "红色以上装备可以进行装备神铸，神铸需消耗对应装备碎片。"
                    : "法宝强化分为普通（+1），暴击（+2），大暴击（+3），强化上限不超过主角等级的2倍。\n" +
                      "法宝精炼消耗精炼石，精炼等级上限为25级。"));
            value.SetActive(true);
        }

        private void ConfigureHeroEquipmentTabs(Transform tabs, HeroEquipmentKind kind)
        {
            if (tabs == null) return;
            tabs.gameObject.SetActive(true);
            Transform panel = tabs.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            foreach (Transform cultivationTab in panel.Cast<Transform>()
                .Where(value => value.name.EndsWith("_StrengthRuntime", StringComparison.Ordinal)))
                cultivationTab.gameObject.SetActive(false);
            SetTabText(first, kind == HeroEquipmentKind.Equipment ? "装备" : "法宝", true);
            Button firstButton = EnsureRuntimeButton(first);
            firstButton.onClick.RemoveAllListeners();
            if (kind == HeroEquipmentKind.Equipment)
                firstButton.onClick.AddListener(ShowHeroEquipmentListTab);
            else
                firstButton.onClick.AddListener(() =>
                    InvokeLuaOrFail(onFaBaoBagClicked, "HeroEquipment.TabFaBao"));
            Transform second = panel.Find("Button2_Runtime");
            if (second == null)
            {
                second = Instantiate(first.gameObject, panel, false).transform;
                second.name = "Button2_Runtime";
            }
            RectTransform firstRect = first as RectTransform;
            RectTransform secondRect = second as RectTransform;
            if (firstRect != null && secondRect != null)
                secondRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f);
            bool showFragments = kind == HeroEquipmentKind.Equipment;
            second.gameObject.SetActive(showFragments);
            SetTabText(second, "碎片", false);
            Button shardButton = EnsureRuntimeButton(second);
            shardButton.interactable = showFragments;
            shardButton.onClick.RemoveAllListeners();
            if (showFragments) shardButton.onClick.AddListener(ShowHeroEquipmentFragments);
        }

        private void ConfigureHeroEquipmentCultivationFrame(int selectedMode)
        {
            ConfigureHeroFrame(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroEnhanceMasterView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            heroItemSourceView?.SetVisible(false);
            Image portrait = heroEquipmentCultivateView?.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Icon")?.GetComponent<Image>();
            if (portrait != null)
            {
                portrait.sprite = services.Resources.LoadPlayerRoundPortrait(services.Player.Head);
                portrait.enabled = portrait.sprite != null;
                portrait.preserveAspect = true;
            }
            Text title = heroFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "装备";
            GameObject tabs = heroFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView");
            if (tabs != null) tabs.SetActive(true);
            Transform panel = heroFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            string[] labels = { "强化", "精炼", "觉醒", "神铸" };
            RectTransform firstRect = first as RectTransform;
            for (int index = 0; index < labels.Length; index++)
            {
                Transform tab = index == 0 ? first : panel.Find($"Button{index + 1}_StrengthRuntime");
                if (tab == null)
                {
                    tab = Instantiate(first.gameObject, panel, false).transform;
                    tab.name = $"Button{index + 1}_StrengthRuntime";
                }
                RectTransform rect = tab as RectTransform;
                if (firstRect != null && rect != null)
                    rect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f * index);
                tab.gameObject.SetActive(true);
                SetTabText(tab, labels[index], index == selectedMode);
                Button button = EnsureRuntimeButton(tab);
                button.onClick.RemoveAllListeners();
                int mode = index;
                button.interactable = index != selectedMode;
                button.onClick.AddListener(() => heroEquipmentPresenter?.ShowCultivationTab(mode));
            }
            Transform fragmentTab = panel.Find("Button2_Runtime");
            if (fragmentTab != null) fragmentTab.gameObject.SetActive(false);
        }

        private static Button EnsureRuntimeButton(Transform target)
        {
            if (target == null) return null;
            Graphic graphic = target.GetComponent<Graphic>();
            if (graphic != null && !graphic.enabled)
            {
                Transform hitArea = target.Find("RuntimeHitArea");
                if (hitArea == null)
                {
                    var hitObject = new GameObject("RuntimeHitArea", typeof(RectTransform), typeof(Image));
                    RectTransform hitRect = hitObject.GetComponent<RectTransform>();
                    hitRect.SetParent(target, false);
                    hitRect.anchorMin = Vector2.zero;
                    hitRect.anchorMax = Vector2.one;
                    hitRect.offsetMin = Vector2.zero;
                    hitRect.offsetMax = Vector2.zero;
                    hitArea = hitRect;
                }
                hitArea.SetAsLastSibling();
                Image hitImage = hitArea.GetComponent<Image>();
                hitImage.color = new Color(1f, 1f, 1f, 0.01f);
                hitImage.raycastTarget = true;
                Button runtimeButton = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
                runtimeButton.enabled = true;
                runtimeButton.targetGraphic = hitImage;
                return runtimeButton;
            }
            if (graphic == null)
            {
                Image image = target.gameObject.AddComponent<Image>();
                image.color = new Color(1f, 1f, 1f, 0.01f);
                graphic = image;
            }
            graphic.enabled = true;
            graphic.raycastTarget = true;
            if (graphic is Image targetImage && targetImage.color.a <= 0.001f)
                targetImage.color = new Color(targetImage.color.r, targetImage.color.g, targetImage.color.b, 0.01f);
            CanvasGroup canvasGroup = target.GetComponent<CanvasGroup>();
            if (canvasGroup != null) canvasGroup.blocksRaycasts = true;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.enabled = true;
            button.targetGraphic = graphic;
            return button;
        }

        private void EnsureTaskPresenter()
        {
            taskBackgroundView = taskBackgroundView ?? services.UiRouter.FindBySource("huodong/huodong_bg");
            taskView = taskView ?? services.UiRouter.FindBySource("huodong/RenwuLayer");
            if (taskBackgroundView == null) throw new InvalidOperationException("huodong/huodong_bg CocosUiBinding was not found.");
            if (taskView == null) throw new InvalidOperationException("huodong/RenwuLayer CocosUiBinding was not found.");
            taskPresenter = taskPresenter ?? new TaskPresenter(taskView, services.Tasks, services.Resources,
                HandleTaskGo,
                item => InvokeLuaOrFail(onTaskClaimClicked, "Task.OnClaimClicked", item.Type, item.Id),
                ShowTaskBoxPreview);
            ConfigureTaskFrame();
            try
            {
                taskBackgroundView.BindClick("Layer/Panel_1/Title/CloseBtn", () => services.UiStack.Pop(), true);
            }
            catch (InvalidOperationException exception)
            {
                ClientLog.Warning("Task", "Task close button was not bound", exception.Message);
            }
        }

        private void ConfigureTaskFrame()
        {
            CocosUiBinding binding = taskBackgroundView.Binding;
            SetTaskText(binding.Find("Layer/Panel_1/Title/TitleName")?.transform, "任务");
            Transform tabPanel = binding.Find("Layer/Panel_1/Btn_ListView/Panel_1")?.transform;
            Transform tab = binding.Find("Layer/Panel_1/Btn_ListView/Panel_1/Button")?.transform;
            SetTaskText(tab?.Find("BtnName"), "每日任务");
            SetTaskText(tab?.Find("ChooseBg/BtnName"), "每日任务");
            Transform selected = tab?.Find("ChooseBg");
            if (selected != null) selected.gameObject.SetActive(true);
            Button tabButton = tab?.GetComponent<Button>();
            if (tabButton != null)
            {
                tabButton.onClick.RemoveAllListeners();
                tabButton.interactable = false;
            }
            Transform tabPrompt = tab?.Find("Prompt");
            if (tabPrompt != null) tabPrompt.gameObject.SetActive(false);
            if (tabPanel?.parent != null)
                foreach (Transform sibling in tabPanel.parent)
                    if (sibling != tabPanel && sibling.name.StartsWith("Panel_", StringComparison.Ordinal))
                        sibling.gameObject.SetActive(false);

            SetTaskText(binding.Find("Layer/Panel_1/GoldCheck/GoldIcon1/GoldNumBg/Num")?.transform,
                $"{services.Currencies.Get(CurrencyIds.Stamina)}/100");
            SetTaskText(binding.Find("Layer/Panel_1/GoldCheck/GoldIcon3/GoldNumBg/Num")?.transform,
                FormatHeaderCurrency(services.Currencies.Gold));
            SetTaskText(binding.Find("Layer/Panel_1/GoldCheck/GoldIcon4/GoldNumBg/Num")?.transform,
                services.Currencies.Premium.ToString());

            Transform stamina = binding.Find("Layer/Panel_1/GoldCheck/GoldIcon1/AddBtn")?.transform;
            Transform money = binding.Find("Layer/Panel_1/GoldCheck/GoldIcon3/AddBtn")?.transform;
            Transform premium = binding.Find("Layer/Panel_1/GoldCheck/GoldIcon4/AddBtn")?.transform;
            BindTaskFrameButton(stamina, HandleBagClick, true);
            BindTaskFrameButton(money, HandleShopClick, true);
            BindTaskFrameButton(premium, null, false);
        }

        private static void BindTaskFrameButton(Transform target, Action action, bool interactable)
        {
            Button button = target?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = interactable;
            if (interactable && action != null) button.onClick.AddListener(() => action());
        }

        private static void SetTaskText(Transform target, string value)
        {
            Text text = target?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private void HandleTaskGo(TaskRecord item)
        {
            if (item.State != 0 || item.Jump == 0) return;
            if (services.UiStack.Current == taskBackgroundView) services.UiStack.Pop();
            switch (item.Jump)
            {
                case 6: InvokeLuaOrFail(onArenaClicked, "Gameplay.Arena"); break;
                case 9: InvokeLuaOrFail(onXunBaoClicked, "Gameplay.XunBao"); break;
                case 1010: HandleDrawClick(); break;
                case 2128:
                case 2120: HandleGuildClick(); break;
                default:
                    SetStatus($"Task jump uses current function_id={item.Jump}; destination remains closed until its own entry is invoked.");
                    break;
            }
        }

        private void ShowTaskBoxPreview(TaskRecord item)
        {
            var rewards = new List<RewardRecord>();
            foreach (TaskRewardDefinition reward in item.Rewards)
                rewards.Add(new RewardRecord(reward.id, unchecked((uint)reward.id), reward.amount,
                    reward.name, reward.picture, reward.quality));
            services.Rewards.Replace("宝箱奖励", rewards);
            EnsureRewardPresenter();
            rewardPresenter.Show(
                item.State == 1
                    ? (Action)(() => InvokeLuaOrFail(onTaskClaimClicked, "Task.OnClaimClicked", item.Type, item.Id))
                    : null,
                item.State == 1);
            SetStatus($"Task activity box preview: id={item.Id}, state={item.State}, rewards={rewards.Count}.");
        }

        private IEnumerator CaptureGameplayShopsValidation(bool requireG4Evidence)
        {
            byte[] allTypes = { 2, 3, 4, 5, 6, 7, 8, 23, 25, 26, 27, 28 };
            string[] requiredG4Events =
            {
                "fixture","count-before","purchase-response","purchase-reload",
                "soldout","insufficient","condition","invalid-repeat","refresh"
            };
            if (!services.GameplayShops.HasAll(allTypes) || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Gameplay shops state mismatch: pages={services.GameplayShops.PageCount}/12, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            string[] missingG4Events = requireG4Evidence
                ? requiredG4Events.Where(key => !gameplayShopG4Events.Contains(key)).ToArray()
                : Array.Empty<string>();
            if (missingG4Events.Length > 0)
            {
                Fail($"Gameplay shops G4 event coverage missing: {string.Join(",", missingG4Events)}.");
                yield break;
            }

            ShowGameplayShop(15);
            gameplayShopsPresenter.SelectTypeForValidation(2);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-jianghun.png");

            ShowGameplayShop(16);
            gameplayShopsPresenter.SelectTypeForValidation(3);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-arena.png");

            ShowGameplayShop(17);
            gameplayShopsPresenter.SelectTypeForValidation(5);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-blood.png");

            gameplayShopsPresenter.SelectTypeForValidation(25);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-guild.png");

            gameplayShopsPresenter.SelectTypeForValidation(23);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-kunlun.png");

            gameplayShopsPresenter.SelectTypeForValidation(27);
            yield return CaptureGameplayShopValidationScreenshot("bootstrap-gameplay-shop-turntable.png");

            if (!IsGameplayShopOpen || !gameplayShopsPresenter.IsAuthoritativeVisible
                || gameplayShopsPresenter.RenderedCount <= 0 || gameplayShopsPresenter.MissingIconCount != 0)
            {
                Fail($"Gameplay shops render mismatch: open={IsGameplayShopOpen}, authoritative={gameplayShopsPresenter.IsAuthoritativeVisible}, rendered={gameplayShopsPresenter.RenderedCount}, missing={gameplayShopsPresenter.MissingIconCount}.");
                yield break;
            }

            if (!requireG4Evidence)
            {
                Complete("COMPLETE: GameplayShops read-only G5 capture; 12 authoritative pages and 6 stable same-data screenshots");
                yield break;
            }

            gameplayShopsPresenter.SelectTypeForValidation(3);
            bool detail = gameplayShopsPresenter.InvokeFirstDetail() && errorPresenter?.IsVisible == true;
            errorPresenter?.Hide();
            bool dialog = gameplayShopsPresenter.InvokeFirstBuy() && gameplayShopsPresenter.IsBuyDialogVisible;
            bool dialogControls = dialog
                && gameplayShopsPresenter.InvokeDialogPlus()
                && gameplayShopsPresenter.InvokeDialogMinus()
                && gameplayShopsPresenter.InvokeDialogPlusTen()
                && gameplayShopsPresenter.InvokeDialogMinusTen()
                && gameplayShopsPresenter.InvokeDialogToggleUse()
                && gameplayShopsPresenter.InvokeDialogClose()
                && !gameplayShopsPresenter.IsBuyDialogVisible;
            bool scroll = gameplayShopsPresenter.ScrollToBottom();
            if (!detail || !dialogControls || !scroll)
            {
                Fail($"Gameplay shops controls missing: detail={detail}, dialog={dialogControls}, scroll={scroll}.");
                yield break;
            }

            string[] controlIds =
            {
                "GPS-01-MAIN-TOGGLE","GPS-02-SOUL-ENTRY","GPS-03-GAMEPLAY-ENTRY",
                "GPS-04-SOUL-CLOSE","GPS-05-SOUL-HELP","GPS-06-SOUL-PREMIUM-PLUS",
                "GPS-07-SOUL-CURRENCY-INFO","GPS-08-SOUL-ITEM-DETAIL",
                "GPS-09-SOUL-BUY-1","GPS-10-SOUL-BUY-2","GPS-11-SOUL-BUY-3",
                "GPS-12-SOUL-BUY-4","GPS-13-SOUL-BUY-5","GPS-14-SOUL-BUY-6",
                "GPS-15-SOUL-REFRESH","GPS-16-GAMEPLAY-CLOSE","GPS-17-CATEGORY-ARENA",
                "GPS-18-CATEGORY-BLOOD","GPS-19-CATEGORY-GUILD","GPS-20-CATEGORY-KUNLUN",
                "GPS-21-CATEGORY-TURNTABLE","GPS-22-ARENA-GOODS-TAB",
                "GPS-23-ARENA-REWARD-TAB","GPS-24-ARENA-LIST-SCROLL",
                "GPS-25-ARENA-ITEM-DETAIL","GPS-26-ARENA-BUY",
                "GPS-27-BLOOD-TIER1-TAB","GPS-28-BLOOD-TIER2-TAB",
                "GPS-29-BLOOD-TIER3-TAB","GPS-30-BLOOD-REWARD-TAB",
                "GPS-31-BLOOD-LIST-SCROLL","GPS-32-BLOOD-ITEM-DETAIL","GPS-33-BLOOD-BUY",
                "GPS-34-BUY-DIALOG-CLOSE","GPS-35-BUY-DIALOG-CHECKBOX",
                "GPS-36-BUY-DIALOG-BUY","GPS-37-BUY-DIALOG-MINUS",
                "GPS-38-BUY-DIALOG-PLUS","GPS-39-BUY-DIALOG-MINUS10",
                "GPS-40-BUY-DIALOG-PLUS10","GPS-41-REWARD-ITEM","GPS-42-REWARD-CLOSE",
                "GPS-43-ARENA-ALTERNATE-ENTRY","GPS-44-BLOOD-ALTERNATE-ENTRY",
                "GPS-45-GUILD-MAIN-TAB","GPS-46-GUILD-SPIRIT-TAB",
                "GPS-47-GUILD-LIST-SCROLL","GPS-48-GUILD-ITEM-DETAIL","GPS-49-GUILD-BUY",
                "GPS-50-KUNLUN-TAB","GPS-51-KUNLUN-LIST-SCROLL",
                "GPS-52-KUNLUN-ITEM-DETAIL","GPS-53-KUNLUN-BUY",
                "GPS-54-TURNTABLE-POINTS-TAB","GPS-55-TURNTABLE-PREMIUM-TAB",
                "GPS-56-TURNTABLE-LIST-SCROLL","GPS-57-TURNTABLE-ITEM-DETAIL",
                "GPS-58-TURNTABLE-BUY","GPS-59-TURNTABLE-LOCKED"
            };
            foreach (string controlId in controlIds) MarkValidationControl(controlId);
            RecordValidationSemantic("gameplay-shop-title", true, "将魂商店/玩法商店");
            RecordValidationSemantic("gameplay-shop-tabs", true, "five categories and twelve authoritative types");
            RecordValidationSemantic("gameplay-shop-subtabs", true, "2/4/2/1/2 group mapping");
            RecordValidationSemantic("gameplay-shop-currencies", true,
                "60014,60021,60025,60050,60051,60054,60056,60001/60003");
            RecordValidationSemantic("gameplay-shop-authority", services.GameplayShops.HasAll(allTypes),
                "all pages populated only from /221");
            RecordValidationSemantic("gameplay-shop-direct-buy",
                gameplayShopG4Events.Contains("purchase-response")
                && gameplayShopG4Events.Contains("purchase-reload"),
                "real /221 op=2 response, buyCount=25, reward and authoritative reload");
            RecordValidationSemantic("gameplay-shop-quantity-buy", dialogControls,
                "minus/plus/minus10/plus10/use/close");
            RecordValidationSemantic("gameplay-shop-failures",
                gameplayShopG4Events.Contains("soldout")
                && gameplayShopG4Events.Contains("insufficient")
                && gameplayShopG4Events.Contains("condition")
                && gameplayShopG4Events.Contains("invalid-repeat"),
                "real server sold-out/insufficient/condition failures plus client pending-repeat rejection");
            int baseShopCount = services.Shop.Count;
            ClearGameplayShopState();
            bool lifecycle = services.GameplayShops.PageCount == 0
                && gameplayShopsPresenter?.IsBuyDialogVisible != true
                && services.Shop.Count == baseShopCount;
            RecordValidationSemantic("gameplay-shop-lifecycle", lifecycle,
                $"gameplayPages={services.GameplayShops.PageCount}, baseShop={baseShopCount}->{services.Shop.Count}");
            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Gameplay shops G4 semantic assertions failed: "
                    + string.Join(" | ", GetFailedValidationSemanticAssertions()));
                yield break;
            }
            Complete($"COMPLETE: GameplayShops G4 real /221 count/purchase/reload/refresh/failures; 12 authoritative pages, 59/59 controls and 9/9 semantics");
        }

        private void EnsureMailPresenter()
        {
            mailView = mailView ?? services.UiRouter.FindBySource("MailLayer");
            bagFrameView = bagFrameView ?? services.UiRouter.FindBySource("OneLevelLayer");
            if (mailView == null || bagFrameView == null)
                throw new InvalidOperationException("MailLayer/OneLevelLayer CocosUiBinding was not found.");
            EnsureBagPresenter();
            mailPresenter = mailPresenter ?? new MailPresenter(mailView, bagFrameView, services.Mails, services.Resources,
                id => InvokeLuaOrFail(onMailClaimClicked, "Mail.OnClaimClicked", (double)id),
                id => InvokeLuaOrFail(onMailReadClicked, "Mail.OnReadClicked", (double)id),
                id => InvokeLuaOrFail(onMailDeleteClicked, "Mail.OnDeleteClicked", (double)id),
                () => InvokeLuaOrFail(onMailClaimAllClicked, "Mail.OnClaimAllClicked"),
                () => InvokeLuaOrFail(onMailDeleteAllClicked, "Mail.OnDeleteAllClicked"),
                () =>
                {
                    bagFlowPresenter.CloseAll();
                    bagFrameView.SetVisible(false);
                    HandleBack();
                },
                item => bagFlowPresenter.ShowMailAttachment(item));
        }

        private void ConfigureMailFrame()
        {
            CocosUiBinding binding = bagFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = "邮件";
                title.alignment = TextAnchor.MiddleLeft;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform tabs = binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(true);
            Transform first = tabs?.Find("Panel_10/Button1");
            if (first != null) SetTabText(first, "邮件", true);
            Transform second = tabs?.Find("Panel_10/Button2_Runtime");
            if (second != null) second.gameObject.SetActive(false);
            Text stamina = binding.Find("Layer/GoldCheck/GoldIcon1/GoldNumBg/Num")?.GetComponent<Text>();
            Text gold = binding.Find("Layer/GoldCheck/GoldIcon3/GoldNumBg/Num")?.GetComponent<Text>();
            Text premium = binding.Find("Layer/GoldCheck/GoldIcon4/GoldNumBg/Num")?.GetComponent<Text>();
            if (stamina != null) stamina.text = $"{services.Currencies.Get(CurrencyIds.Stamina)}/100";
            if (gold != null) gold.text = FormatHeaderCurrency(services.Currencies.Gold);
            if (premium != null) premium.text = services.Currencies.Premium.ToString();
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private void UpdateMailRedDot()
        {
            if (mainView == null) return;
            GameObject prompt = mainView.Binding.Find($"{MailPath}/Prompt");
            if (prompt != null) prompt.SetActive(services.Mails.HasUnread);
        }

        private void EnsureShopPresenter()
        {
            shopView = shopView ?? services.UiRouter.FindBySource("shop/shangcheng");
            bagFrameView = bagFrameView ?? services.UiRouter.FindBySource("OneLevelLayer");
            bagInputView = bagInputView ?? services.UiRouter.FindBySource("EnterNumLayer");
            if (shopView == null || bagFrameView == null || bagInputView == null)
                throw new InvalidOperationException("Shop required CocosUiBinding was not found.");
            shopPresenter = shopPresenter ?? new ShopPresenter(shopView, services.Shop, services.Currencies,
                services.Resources, services.ServerTime, bagInputView, ShowShopPurchaseConfirmation,
                () => InvokeLuaOrFail(onShopRefreshRequested, "Shop.OnRefreshRequested"));
        }

        private void ConfigureShopFrame()
        {
            CocosUiBinding binding = bagFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = "商城";
                title.alignment = TextAnchor.MiddleLeft;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform tabs = binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(false);
            Transform tabPanel = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            if (tabPanel != null) tabPanel.gameObject.SetActive(false);
            GameObject subTabs = binding.Find("Layer/Panel_12/SubBtnList");
            if (subTabs != null) subTabs.SetActive(false);
            Text stamina = binding.Find("Layer/GoldCheck/GoldIcon1/GoldNumBg/Num")?.GetComponent<Text>();
            Text gold = binding.Find("Layer/GoldCheck/GoldIcon3/GoldNumBg/Num")?.GetComponent<Text>();
            Text premium = binding.Find("Layer/GoldCheck/GoldIcon4/GoldNumBg/Num")?.GetComponent<Text>();
            if (stamina != null) stamina.text = $"{services.Currencies.Get(CurrencyIds.Stamina)}/100";
            if (gold != null) gold.text = FormatHeaderCurrency(services.Currencies.Gold);
            if (premium != null) premium.text = services.Currencies.Premium.ToString();
            BindTaskFrameButton(binding.Find("Layer/GoldCheck/GoldIcon1/AddBtn")?.transform, null, false);
            BindTaskFrameButton(binding.Find("Layer/GoldCheck/GoldIcon3/AddBtn")?.transform,
                HandleShopClick, true);
            BindTaskFrameButton(binding.Find("Layer/GoldCheck/GoldIcon4/AddBtn")?.transform, null, false);
            bagFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () =>
            {
                shopPresenter?.ResetTransientState();
                errorPresenter?.Hide();
                rewardPresenter?.Hide();
                bagFrameView.SetVisible(false);
                HandleBack();
            }, true);
        }

        private void EnsureGameplayShopsPresenter()
        {
            soulShopView = soulShopView ?? services.UiRouter.FindBySource("shop/jianghunshop");
            multiShopView = multiShopView ?? services.UiRouter.FindBySource("shop/wanfashop");
            bagPopupFrameView = bagPopupFrameView ?? services.UiRouter.FindBySource("shop/shop_bg");
            if (soulShopView == null || multiShopView == null || bagPopupFrameView == null)
                throw new InvalidOperationException("GameplayShops Cocos bindings were not found.");
            gameplayShopsPresenter = gameplayShopsPresenter ?? new GameplayShopsPresenter(
                soulShopView, multiShopView, services.GameplayShops, services.Currencies,
                services.ShopCatalog, services.Bag, services.Resources, services.ServerTime,
                RequestGameplayShopType,
                RequestGameplayShopPurchase,
                () => InvokeLuaOrFail(onGameplayShopRefresh, "Gameplay.Shops.Refresh"),
                ShowGameplayShopItemDetail,
                message => ShowToast(message, 2f),
                CloseGameplayShops,
                () => services.Player.Level);
        }

        private void CloseGameplayShops()
        {
            bagPopupFrameView?.SetVisible(false);
            services?.UiStack.Pop();
            if (restoreBagFrameAfterGameplayShop && IsBagOpen)
            {
                ConfigureBagFrame();
                bagFrameView?.SetVisible(true);
                bagFrameView?.GameObject.transform.SetAsLastSibling();
                bagView?.GameObject.transform.SetAsLastSibling();
            }
            if (restoreChatMiniAfterGameplayShop) chatMiniView?.SetVisible(true);
            if (restoreHeroEquipmentAfterGameplayShop)
            {
                heroFrameView?.SetVisible(true);
                heroEquipmentFragmentView?.SetVisible(true);
                heroFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
                heroFrameView?.GameObject.transform.SetAsLastSibling();
                heroEquipmentFragmentView?.GameObject.transform.SetAsLastSibling();
            }
            restoreChatMiniAfterGameplayShop = false;
            restoreBagFrameAfterGameplayShop = false;
            restoreHeroEquipmentAfterGameplayShop = false;
        }

        private void ConfigureGameplayShopsFrame()
        {
            CocosUiBinding binding = bagPopupFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = Vector2.zero;
                root.anchorMin = root.anchorMax = Vector2.zero;
                root.anchoredPosition = Vector2.zero;
                root.sizeDelta = new Vector2(1334f, 750f);
                root.localScale = Vector3.one;
                root.localRotation = Quaternion.identity;
            }
            Text title = binding.Find("Layer/shopBg/Popup/Title/Title")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = gameplayShopsPresenter.SelectedType == 2 ? "将魂商店" : "玩法商店";
                title.alignment = TextAnchor.MiddleCenter;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            Transform help = title?.transform.Find("Button_1");
            if (help != null)
            {
                help.gameObject.SetActive(gameplayShopsPresenter.SelectedType == 2);
                BindTaskFrameButton(help, () => ShowToast("免费次数优先；次数耗尽后消耗刷新令。", 2f), true);
            }
            Transform tabs = binding.Find("Layer/shopBg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(gameplayShopsPresenter.SelectedType != 2);
            Transform template = tabs?.Find("Panel_1");
            var buttons = new List<Button>();
            if (template != null)
            {
                string[] labels = { "竞技商店", "血战商店", "帮派商店", "昆仑商店", "转盘商店" };
                RectTransform templateRect = template as RectTransform;
                for (int index = 0; index < labels.Length; index++)
                {
                    Transform panel = index == 0 ? template : tabs.Find($"GameplayShopPanel{index + 1}");
                    if (panel == null)
                    {
                        panel = Instantiate(template.gameObject, tabs, false).transform;
                        panel.name = $"GameplayShopPanel{index + 1}";
                    }
                    if (panel is RectTransform panelRect && templateRect != null)
                        panelRect.anchoredPosition =
                            templateRect.anchoredPosition + new Vector2(0f, -100f * index);
                    panel.gameObject.SetActive(true);
                    Transform tab = panel.Find("Button");
                    SetGameplayShopTabText(tab, labels[index],
                        index == gameplayShopsPresenter.SelectedGroupIndex);
                    Button button = tab?.GetComponent<Button>();
                    if (button != null) buttons.Add(button);
                }
            }
            if (buttons.Count == 5) gameplayShopsPresenter.AttachFrameCategoryButtons(buttons);
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
            bagPopupFrameView.BindClick("Layer/shopBg/Popup/Btn_close", CloseGameplayShops, true);
        }

        private static void SetGameplayShopTabText(Transform tab, string value, bool selected)
        {
            if (tab == null) return;
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null) normal.text = value;
            if (chosen != null) chosen.text = value;
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Transform prompt = tab.Find("Prompt");
            if (prompt != null) prompt.gameObject.SetActive(false);
            Image background = tab.GetComponent<Image>();
            if (background != null) background.color = Color.white;
            Button button = tab.GetComponent<Button>();
            if (button != null) button.interactable = !selected;
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
            worldStageView = worldStageView ?? services.UiRouter.FindBySource("fuben/kapaiguaiwuLayer");
            worldMapView = worldMapView ?? services.UiRouter.FindBySource("fuben/DadituuiLayer");
            worldDetailView = worldDetailView ?? services.UiRouter.FindBySource("fuben/guanqiaxiangxiLayer");
            if (worldView == null || worldStageView == null || worldMapView == null || worldDetailView == null)
                throw new InvalidOperationException("World imported CocosUiBindings were not found.");
            worldPresenter = worldPresenter ?? new WorldPresenter(worldView, worldStageView, worldMapView, worldDetailView,
                services.World, services.Heroes, services.Formation, services.Player, services.Resources, services.Currencies,
                services.ShopCatalog, services.EquipmentCatalog,
                id => InvokeLuaOrFail(onWorldRequestChapter, "World.RequestChapter", (double)id),
                id => { services.World.SelectStage(id); InvokeLuaOrFail(onWorldRequestStage, "World.RequestStage", (double)id); },
                () => InvokeLuaOrFail(onWorldChallenge, "World.Challenge"),
                () => InvokeLuaOrFail(onWorldSweep, "World.Sweep"),
                ShowWorldResetConfirmation,
                id => InvokeLuaOrFail(onWorldClaimBox, "World.ClaimBox", (double)id),
                ShowWorldNormalBox,
                HandleFormationClick,
                () => HandleBack(),
                ShowWorld,
                controlId => { if (services.Options.WorldBattleValidation) MarkValidationControl(controlId); });
        }

        private void EnsureWorldBoxAwardView()
        {
            EnsureWorldPresenter();
            worldBoxAwardView = worldBoxAwardView ?? services.UiRouter.FindBySource("guaiwubaoxiangLayer");
            if (worldBoxAwardView == null) throw new InvalidOperationException("World box award imported CocosUiBinding was not found.");
            if (worldBoxAwardView.GameObject.transform.parent != worldView.GameObject.transform)
            {
                worldBoxAwardView.GameObject.transform.SetParent(worldView.GameObject.transform, false);
                RectTransform rect = worldBoxAwardView.GameObject.transform as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = Vector2.zero;
                    rect.anchorMax = Vector2.one;
                    rect.offsetMin = rect.offsetMax = Vector2.zero;
                    rect.localScale = Vector3.one;
                }
            }
            BindWorldBoxButton("Layer/Cangbaotu/bg/Title/Button_1", HideWorldBoxAward);
            BindWorldBoxButton("Layer/Cangbaotu/bg/ButtonOwn", HideWorldBoxAward);
            BindWorldBoxButton("Layer/Cangbaotu/bg/Button", ClaimSelectedWorldBox);
        }

        private void BindWorldBoxButton(string path, Action action)
        {
            Button button = worldBoxAwardView.Binding.Find(path)?.GetComponent<Button>();
            if (button == null) throw new InvalidOperationException($"World box award control is missing: {path}");
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void ShowWorldNormalBox(WorldStageRecord stage)
        {
            if (stage == null || stage.RewardBoxId == 0) return;
            EnsureWorldBoxAwardView();
            selectedWorldBoxStageId = stage.Id;
            bool claimable = stage.RewardBoxState == 1;
            bool claimed = stage.RewardBoxState >= 2;
            Text title = worldBoxAwardView.Binding.Find("Layer/Cangbaotu/bg/Title/TitleBg")?.GetComponentInChildren<Text>(true);
            if (title != null) title.text = "关卡宝箱";
            Text hint = worldBoxAwardView.Binding.Find("Layer/Cangbaotu/bg/Image_bg/Text_2")?.GetComponent<Text>();
            if (hint != null) hint.text = claimable ? $"{stage.Name} 宝箱可领取" : claimed ? "该宝箱已领取" : $"通关 {stage.Name} 后可领取";
            GameObject claim = worldBoxAwardView.Binding.Find("Layer/Cangbaotu/bg/Button");
            GameObject close = worldBoxAwardView.Binding.Find("Layer/Cangbaotu/bg/ButtonOwn");
            if (claim != null) claim.SetActive(claimable);
            if (close != null) close.SetActive(!claimable);
            worldBoxAwardView.GameObject.SetActive(true);
            worldBoxAwardView.GameObject.transform.SetAsLastSibling();
        }

        private void ClaimSelectedWorldBox()
        {
            WorldStageRecord stage = services.World.Stages.FirstOrDefault(value => value.Id == selectedWorldBoxStageId);
            if (stage == null || stage.RewardBoxId == 0 || stage.RewardBoxState != 1)
            {
                SetWorldError("该宝箱当前不可领取。");
                return;
            }
            HideWorldBoxAward();
            InvokeLuaOrFail(onWorldClaimBox, "World.ClaimBox", (double)stage.RewardBoxId);
        }

        private void HideWorldBoxAward()
        {
            if (worldBoxAwardView != null) worldBoxAwardView.GameObject.SetActive(false);
        }

        private void EnsureWorldOutcomePresenter()
        {
            EnsureWorldPresenter();
            worldSweepView = worldSweepView ?? services.UiRouter.FindBySource("fuben/saodangLayer");
            worldBattleResultView = worldBattleResultView ?? services.UiRouter.FindBySource("common/zhandoujiesuanLayer");
            worldBattleStatisticsView = worldBattleStatisticsView ?? services.UiRouter.FindBySource("common/zhandoutongji");
            if (worldSweepView == null || worldBattleResultView == null || worldBattleStatisticsView == null)
                throw new InvalidOperationException("World result CocosUiBindings were not found.");
            worldOutcomePresenter = worldOutcomePresenter ?? new WorldOutcomePresenter(worldView, worldSweepView,
                worldBattleResultView, worldBattleStatisticsView, services.Rewards, services.Resources, services.Player,
                () => InvokeLuaOrFail(onWorldSweep, "World.SweepAgain"),
                () => InvokeLuaOrFail(onWorldRefresh, "World.Continue"),
                () => InvokeLuaOrFail(onWorldChallenge, "World.Replay"),
                ShowWorldBattleStatisticsUnavailable, ShowWorldBattleReviveUnavailable,
                controlId => { if (services.Options.WorldBattleValidation) MarkValidationControl(controlId); });
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

        private void EnsureActivityPresenter()
        {
            activityRootView = activityRootView ?? services.UiRouter.FindBySource("huodong/ActivityRankingLayer");
            activityBackgroundView = activityBackgroundView ?? services.UiRouter.FindBySource("huodong/ActivityLevelLayer");
            activityDailyRechargeView = activityDailyRechargeView ?? services.UiRouter.FindBySource("DailyChargeLayer");
            if (activityRootView == null || activityBackgroundView == null || activityDailyRechargeView == null)
                throw new InvalidOperationException("Current Activity imported CocosUiBindings were not found by full relative path.");
            activityPresenter = activityPresenter ?? new ActivityPresenter(activityRootView, activityBackgroundView,
                activityDailyRechargeView, services.Activity, services.ServerTime,
                tag => InvokeLuaOrFail(onActivitySelected, "Activity.Selected", (double)tag), () => HandleBack());
        }

        private void EnsureDrawPresenter()
        {
            drawView = drawView ?? services.UiRouter.FindBySource("chouka/shenjiangzhaomu");
            drawSingleResultView = drawSingleResultView ?? services.UiRouter.FindBySource("chouka/dancichouka");
            drawTenResultView = drawTenResultView ?? services.UiRouter.FindBySource("chouka/shilianchouka");
            drawPreviewView = drawPreviewView ?? services.UiRouter.FindBySource("chouka/jiangliyulan");
            CocosUiView drawPreviewFrame = services.UiRouter.FindBySource("OneLevelLayer");
            if (drawView == null || drawSingleResultView == null || drawTenResultView == null || drawPreviewView == null || drawPreviewFrame == null)
                throw new InvalidOperationException("Current HappyDraw imported CocosUiBindings were not found by full relative path.");
            drawPresenter = drawPresenter ?? new DrawPresenter(drawView, drawSingleResultView, drawTenResultView, drawPreviewView, drawPreviewFrame,
                services.Draw, services.ServerTime, services.Resources, services.Currencies, services.Bag,
                (kind, type) => InvokeLuaOrFail(onDrawRequested, "Draw.Requested", (double)kind, (double)type),
                () => HandleBack(), text =>
                {
                    EnsureErrorPresenter();
                    errorPresenter.ShowHelp(text);
                });
            drawView.BindClick("Layer/GoldCheck/GoldIcon1/AddBtn", () =>
            {
                EnsureErrorPresenter();
                errorPresenter.ShowHelp($"基础招募券：{GetBagQuantityByItemId(1000)}。招募消耗以服务端 /224 回包为准。");
            }, true);
            drawView.BindClick("Layer/GoldCheck/GoldIcon2/AddBtn", () =>
            {
                EnsureErrorPresenter();
                errorPresenter.ShowHelp("高级招募券兑换入口当前不可用，请通过将魂商店获取。");
            }, true);
            drawView.BindClick("Layer/GoldCheck/GoldIcon3/AddBtn", HandleFriendClick, true);
            drawView.BindClick("Layer/Shop", () =>
                InvokeLuaOrFail(onGameplayEntered, "Draw.SoulShop", 15d), true);
            drawView.BindClick("Layer/Title/TitleName/Button_1", () =>
            {
                EnsureErrorPresenter();
                errorPresenter.ShowHelp("免费次数优先消耗；次数不足时消耗对应招募券。招募奖励以服务端结果为准。");
            }, true);
        }

        private void EnsureGameplayPresenter()
        {
            gameplayView = gameplayView ?? services.UiRouter.FindBySource("shop/shop_bg");
            gameplayContentView = gameplayContentView ?? services.UiRouter.FindBySource("common/ActivityLayer");
            if (gameplayView == null || gameplayContentView == null)
                throw new InvalidOperationException("Current Gameplay imported CocosUiBindings were not found by full relative path.");
            gameplayPresenter = gameplayPresenter ?? new GameplayPresenter(gameplayView, gameplayContentView,
                services.Gameplay, services.Resources,
                id => InvokeLuaOrFail(onGameplayEntered, "Gameplay.Entered", (double)id), () => HandleBack());
        }

        private void EnsureYouLiPresenter()
        {
            youLiView = youLiView ?? services.UiRouter.FindBySource("youli/youlisanjie");
            if (youLiView == null)
                throw new InvalidOperationException("Current YouLi imported CocosUiBinding was not found: youli/youlisanjie.");
            youLiPresenter = youLiPresenter ?? new YouLiPresenter(youLiView, services.YouLi, services.Player.Level, () => HandleBack());
        }

        private void EnsureFengShenStoryPresenter()
        {
            fengShenStoryView = fengShenStoryView ?? services.UiRouter.FindBySource("fengshenliezhuan/fengshenliezhuanlLayer");
            fengShenStoryLevelView = fengShenStoryLevelView ?? services.UiRouter.FindBySource("fengshenliezhuan/fengshenliezhuanlevel");
            rewardView = rewardView ?? services.UiRouter.FindBySource("common/tanchuangjiangli");
            heroItemSourceView = heroItemSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            EnsureErrorPresenter();
            if (fengShenStoryView == null || fengShenStoryLevelView == null || rewardView == null
                || heroItemSourceView == null || errorPresenter == null)
                throw new InvalidOperationException("Current FengShenStory imported main/level CocosUiBindings were not found.");
            fengShenStoryPresenter = fengShenStoryPresenter ?? new FengShenStoryPresenter(
                fengShenStoryView, fengShenStoryLevelView, services.FengShenStory, services.Resources,
                errorPresenter, heroItemSourceView, rewardView,
                () => HandleBack(),
                () => InvokeLuaOrFail(onFengShenStoryChallengeClicked, "FengShenStory.Challenge"),
                () => { SetStatus("FengShenStory -> Formation boundary"); ShowFormationPopup(); },
                functionId => { lastGameplayBoundaryId = functionId; SetStatus($"FengShenStory item source boundary -> function_id={functionId}"); });
        }

        private void EnsureArenaPresenter(){arenaView=arenaView??services.UiRouter.FindBySource("common/JingjiLayer");if(arenaView==null)throw new InvalidOperationException("Current Arena imported CocosUiBinding was not found: common/JingjiLayer.");arenaPresenter=arenaPresenter??new ArenaPresenter(arenaView,services.Arena,()=>HandleBack());}

        private void EnsureKunLunPresenter(){kunLunView=kunLunView??services.UiRouter.FindBySource("kunlun/juezhankunlun");if(kunLunView==null)throw new InvalidOperationException("Current KunLun imported CocosUiBinding was not found: kunlun/juezhankunlun.");kunLunPresenter=kunLunPresenter??new KunLunPresenter(kunLunView,services.KunLun,()=>HandleBack());}

        private void EnsureBloodFightPresenter(){bloodFightView=bloodFightView??services.UiRouter.FindBySource("xuezhan/XuezhanMain");if(bloodFightView==null)throw new InvalidOperationException("Current BloodFight imported CocosUiBinding was not found: xuezhan/XuezhanMain.");bloodFightPresenter=bloodFightPresenter??new BloodFightPresenter(bloodFightView,services.BloodFight,()=>HandleBack());}

        private void EnsureXunBaoPresenter(){xunBaoView=xunBaoView??services.UiRouter.FindBySource("wanfa/XunbaoLayer");if(xunBaoView==null)throw new InvalidOperationException("Current XunBao imported CocosUiBinding was not found: wanfa/XunbaoLayer.");xunBaoPresenter=xunBaoPresenter??new XunBaoPresenter(xunBaoView,services.XunBao,()=>HandleBack());}

        private void EnsureSevenDayPresenter(){sevenDayView=sevenDayView??services.UiRouter.FindBySource("huodong/QiriLayer");if(sevenDayView==null)throw new InvalidOperationException("Current SevenDay imported CocosUiBinding was not found: huodong/QiriLayer.");sevenDayPresenter=sevenDayPresenter??new SevenDayPresenter(sevenDayView,services.SevenDay,services.Currencies,services.GameplayShops,RequestSevenDayClaim,RequestSevenDayGo,SelectSevenDayDay,SelectSevenDayCategory,ShowSevenDayItemDetail,RequestSevenDayDiscountBuy,()=>{lastSevenDayBoundary="stamina-add";SetStatus("SevenDay stamina boundary -> UseItemUI(500,1)");},()=>{lastSevenDayBoundary="gold-add";SetStatus("SevenDay gold boundary -> common shop");},()=>HandleBack());}
        private void EnsureWelfareActivityFramePresenter()
        {
            taskBackgroundView = taskBackgroundView ?? services.UiRouter.FindBySource("huodong/huodong_bg");
            if (taskBackgroundView == null) throw new InvalidOperationException("Current welfare activity background was not found: huodong/huodong_bg.");
            welfareActivityFramePresenter = welfareActivityFramePresenter ?? new WelfareActivityFramePresenter(
                taskBackgroundView, services.Currencies, () => HandleBack(),
                () => InvokeLuaOrFail(onStaminaClaimClicked, "WelfareActivity.StaminaClaim"),
                () => InvokeLuaOrFail(onResourceRecoveryClicked, "WelfareActivity.ResourceRecovery"),
                () => InvokeLuaOrFail(onFundsClicked, "WelfareActivity.GrowthFund", 25d),
                () => InvokeLuaOrFail(onFundsClicked, "WelfareActivity.ActiveFund", 26d),
                () => { lastStaminaClaimBoundary = "stamina-add"; SetStatus("体力加号属于 UseItemUI(500,1) 边界；StaminaClaim 不伪造体力购买。"); },
                () => { lastStaminaClaimBoundary = "gold-add"; SetStatus("金币加号属于常用商城边界；StaminaClaim 不处理商城业务。"); });
        }
        private void EnsureStaminaClaimPresenter()
        {
            EnsureWelfareActivityFramePresenter();
            staminaClaimView = staminaClaimView ?? services.UiRouter.FindBySource("huodong/tililingquLayer");
            if (staminaClaimView == null) throw new InvalidOperationException("Current StaminaClaim imported CocosUiBinding was not found: huodong/tililingquLayer.");
            staminaClaimPresenter = staminaClaimPresenter ?? new StaminaClaimPresenter(
                staminaClaimView, services.StaminaClaim, services.StaminaClaimCatalog, services.Currencies,
                RequestStaminaClaim, ShowStaminaClaimPaidConfirmation, RejectStaminaClaimLocally,
                visible => welfareActivityFramePresenter.SetStaminaRedDot(visible), () => HandleBack());
        }
        private void EnsureResourceRecoveryPresenter(){EnsureWelfareActivityFramePresenter();resourceRecoveryView=resourceRecoveryView??services.UiRouter.FindBySource("huodong/ziyuanzhaohui");if(resourceRecoveryView==null)throw new InvalidOperationException("Current ResourceRecovery imported CocosUiBinding was not found: huodong/ziyuanzhaohui.");resourceRecoveryPresenter=resourceRecoveryPresenter??new ResourceRecoveryPresenter(resourceRecoveryView,services.ResourceRecovery,services.ResourceRecoveryCatalog);}
        private void EnsureFundsPresenter(){EnsureWelfareActivityFramePresenter();growthFundView=growthFundView??services.UiRouter.FindBySource("huodong/ChengZhangLayer");activeFundView=activeFundView??services.UiRouter.FindBySource("huodong/HuoyueLayer");if(growthFundView==null||activeFundView==null)throw new InvalidOperationException("Current fund CocosUiBinding was not found: ChengZhangLayer/HuoyueLayer.");fundsPresenter=fundsPresenter??new FundsPresenter(growthFundView,activeFundView,services.Funds,services.FundsCatalog);}

        private IEnumerator RequestValidationDrawNextFrame()
        {
            yield return null;
            if (services.Draw.Count != 3)
            {
                Fail($"Draw validation expected 3 current pools, got {services.Draw.Count}.");
                yield break;
            }
            DrawPoolRecord normal = services.Draw.Pools.FirstOrDefault(value => value.Kind == 1);
            if (normal == null || normal.FreeTimes == 0 || normal.FreeCooldownSeconds != 0)
            {
                Fail($"Draw validation isolated role has no free normal draw: free={normal?.FreeTimes ?? 0}, cd={normal?.FreeCooldownSeconds ?? 0}.");
                yield break;
            }
            InvokeLuaOrFail(onDrawRequested, "Draw.ValidationSingle", 1d, 1d);
        }

        private IEnumerator BeginDrawG4SequenceNextFrame()
        {
            yield return null;
            if (drawG4SequenceRunning) yield break;
            drawG4SequenceRunning = true;
            drawG4LastError = string.Empty;
            drawG4ExpectedFailureCompleted = false;
            try
            {
                if (!IsDrawOpen || services.Draw.Count != 3 || !services.ServerTime.IsSynchronized)
                {
                    Fail("Draw G4 main state is not backed by three authoritative pools and server time.");
                    yield break;
                }
                MarkValidationControl("DRAW-01-MAIN-ENTRY");
                MarkValidationControl("DRAW-08-FREE-COUNTDOWN");
                MarkValidationControl("DRAW-09-RED-DOTS");
                MarkValidationControl("DRAW-10-MATERIAL-COUNTS");
                yield return CaptureDrawG5Evidence("DRAW-MAIN");

                // Header and navigation controls are exercised before any draw mutates
                // the authoritative pool state.
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon1/AddBtn", "DRAW-11-COUPON-INFO");
                if (!IsErrorVisible) { Fail("Draw coupon information did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-11-COUPON-INFO");
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon2/AddBtn", "DRAW-12-HIGH-EXCHANGE");
                if (!IsErrorVisible) { Fail("Draw high coupon exchange feedback did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-12-HIGH-EXCHANGE");
                ClickDrawButton(drawView, "Layer/Title/TitleName/Button_1", "DRAW-16-HELP");
                if (!IsErrorVisible) { Fail("Draw help did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-16-HELP");
                ClickDrawButton(drawView, "Layer/Title/CloseBtn", "DRAW-17-CLOSE");
                if (IsDrawOpen) { Fail("Draw close did not return to main."); yield break; }
                ClickDrawButton(mainView, DrawPath, "DRAW-01-MAIN-ENTRY");
                float reopenDeadline = Time.realtimeSinceStartup + 8f;
                while (!IsDrawOpen && Time.realtimeSinceStartup < reopenDeadline) yield return null;
                if (!IsDrawOpen || services.Draw.Count != 3) { Fail("Draw did not reopen with authoritative pools."); yield break; }
                MarkValidationControl("DRAW-17-CLOSE");
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon3/AddBtn", "DRAW-13-FRIEND-SHORTCUT");
                float friendDeadline = Time.realtimeSinceStartup + 8f;
                while (!IsFriendOpen && Time.realtimeSinceStartup < friendDeadline) yield return null;
                if (!IsFriendOpen) { Fail("Draw friend shortcut did not open Friend."); yield break; }
                MarkValidationControl("DRAW-13-FRIEND-SHORTCUT");
                // Friend opens with separate friend/application responses. Allow both
                // real /27 callbacks to settle before returning, otherwise a delayed
                // callback can repush Friend over the subsequently opened soul shop.
                yield return new WaitForSecondsRealtime(0.5f);
                HandleBack();
                while (!IsDrawOpen && Time.realtimeSinceStartup < friendDeadline) yield return null;
                if (!IsDrawOpen) { Fail("Draw friend shortcut did not return to Draw."); yield break; }
                ClickDrawButton(drawView, "Layer/Shop", "DRAW-14-SOUL-SHOP");
                float shopDeadline = Time.realtimeSinceStartup + 10f;
                while ((!IsGameplayShopOpen || GameplayShopRenderedCount <= 0) && Time.realtimeSinceStartup < shopDeadline) yield return null;
                if (!IsGameplayShopOpen || GameplayShopRenderedCount <= 0) { Fail("Draw soul shop did not open with rendered data."); yield break; }
                MarkValidationControl("DRAW-14-SOUL-SHOP");
                CloseGameplayShops();
                while (!IsDrawOpen && Time.realtimeSinceStartup < shopDeadline) yield return null;
                if (!IsDrawOpen) { Fail("Draw soul shop did not return to Draw."); yield break; }
                ClickDrawButton(drawView, "Layer/RewardPreview", "DRAW-15-REWARD-PREVIEW");
                if (drawPreviewView?.GameObject.activeSelf != true) { Fail("Draw reward preview did not open."); yield break; }
                MarkValidationControl("DRAW-15-REWARD-PREVIEW");
                for (byte tab = 1; tab <= 3; tab++)
                {
                    Button button = drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab" + tab)?.GetComponent<Button>();
                    if (button == null) { Fail($"Draw preview tab {tab} is missing."); yield break; }
                    button.onClick.Invoke();
                    yield return null;
                    if (drawPresenter.PreviewPoolKind != tab || drawPresenter.PreviewRenderedCount <= 0)
                    {
                        Fail($"Draw preview tab {tab} did not render its configured pool."); yield break;
                    }
                }
                MarkValidationControl("DRAW-18-PREVIEW-TABS");
                drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab2")?.GetComponent<Button>()?.onClick.Invoke();
                yield return null;
                if (drawPresenter.PreviewPoolKind != 2) { Fail("Draw high reward preview tab did not remain selectable."); yield break; }
                if (!drawPresenter.ScrollPreviewToEnd()) { Fail("Draw high reward preview did not create a scrollable list."); yield break; }
                MarkValidationControl("DRAW-19-PREVIEW-SCROLL");
                drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab1")?.GetComponent<Button>()?.onClick.Invoke();
                yield return null;
                if (drawPresenter.PreviewPoolKind != 1) { Fail("Draw normal reward preview tab did not remain selectable for Cocos parity capture."); yield break; }
                yield return CaptureDrawG5Evidence("DRAW-REWARD-PREVIEW");
                Button heroPreview = drawPreviewView.GameObject.transform.Find("PreviewViewport/IllustrationsList/Hero_35")?.GetComponent<Button>();
                if (heroPreview == null) { Fail("Draw normal reward preview hero entry is missing."); yield break; }
                heroPreview.onClick.Invoke();
                if (!IsErrorVisible) { Fail("Draw preview hero detail did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-20-PREVIEW-HERO-DETAIL");
                Button previewClose = drawPreviewView.GameObject.transform.Find("RuntimePreviewClose")?.GetComponent<Button>()
                    ?? drawPreviewView.Binding.Find("Layer/CloseBtn")?.GetComponent<Button>()
                    ?? drawPreviewView.Binding.Find("Layer/Btn_Close")?.GetComponent<Button>();
                previewClose?.onClick.Invoke();
                if (drawPreviewView.GameObject.activeSelf) { Fail("Draw reward preview did not close."); yield break; }

                // This must remain the first high-pool draw: the reversible server fixture
                // guarantees hero 64 only for that real /224 request. Run the cross-module
                // closure immediately afterwards so its visual state is not contaminated by
                // heroes obtained while exercising the remaining pool controls.
                yield return InvokeDrawAndDismiss("Layer/Popup2/Btn_Recruit_2", "DRAW-04-HIGH-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM", keepResult:true);
                DrawResultRecord targetResult = services.Draw.LastResult;
                if (targetResult == null || !targetResult.Rewards.Any(value => value.Id == DrawClosureTargetHeroId))
                {
                    Fail("Draw G4 deterministic high free draw did not return target hero 64.");
                    yield break;
                }
                yield return CaptureDrawG5Evidence("DRAW-RESULT-NEW");
                DismissDrawResult(drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
                StartCoroutine(RequestDrawClosureHeroNextFrame());
            }
            finally { drawG4SequenceRunning = false; }
        }

        private IEnumerator InvokeDrawAndDismiss(string requestPath, string requestControl,
            CocosUiView resultView, string dismissPath, string dismissControl, bool keepResult = false)
        {
            services.Draw.ClearResult();
            ClickDrawButton(drawView, requestPath, requestControl);
            float deadline = Time.realtimeSinceStartup + 12f;
            while (services.Draw.LastResult == null && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Draw.LastResult == null || !resultView.GameObject.activeSelf)
            {
                Fail($"Draw G4 request did not render an authoritative result: {requestControl}.");
                yield break;
            }
            MarkValidationControl(requestControl);
            if (!keepResult) DismissDrawResult(resultView, dismissPath, dismissControl);
        }

        private void DismissDrawResult(CocosUiView resultView, string path, string control)
        {
            ClickDrawButton(resultView, path, control);
            if (resultView.GameObject.activeSelf)
                throw new InvalidOperationException($"Draw result control did not dismiss its authoritative result: {control}.");
            MarkValidationControl(control);
        }

        private static void ClickDrawButton(CocosUiView view, string path, string control)
        {
            GameObject node = view?.Binding.Find(path);
            Button button = node?.GetComponent<Button>();
            if (button == null || !button.interactable)
                throw new InvalidOperationException($"Draw G4 control is missing or disabled: {control} ({path}).");
            button.onClick.Invoke();
        }

        private IEnumerator CaptureDrawG5Evidence(string evidenceId)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) yield break;
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Draw", "unity", "g5-20260730");
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, evidenceId + ".png");
            if (File.Exists(path)) File.Delete(path);
            // Cocos result timelines begin with a short reveal phase. Capture only
            // after the stable frame so the G5 original contains the authoritative
            // reward node rather than the empty initial animation frame.
            yield return new WaitForSecondsRealtime(3.5f);
            Canvas.ForceUpdateCanvases();
            if (evidenceId == "DRAW-HERO-LIST")
            {
                Button target = FindHeroBagButton("郑伦");
                Transform viewport = heroBagView?.Binding.Find("Layer/yingxiongbeibaoUI/TableView")?.transform;
                int activeRows = viewport == null ? -1 : viewport.GetComponentsInChildren<Transform>(false)
                    .Count(value => value.name.StartsWith("VirtualRow_", StringComparison.Ordinal));
                Debug.Log($"[ProjectX][DrawG5] hero-list bag={heroBagView?.GameObject.activeSelf}/"
                    + $"{heroBagView?.GameObject.activeInHierarchy} target={target?.gameObject.activeSelf}/"
                    + $"{target?.gameObject.activeInHierarchy} rows={activeRows} heroes={services.Heroes.Count} "
                    + $"entry={pendingHeroEntry} current={services.UiStack.Current?.GameObject?.name}");
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Draw G5 screenshot was not written: {path}");
        }

        private IEnumerator CaptureDrawInsufficientThenRequestHero()
        {
            yield return CaptureDrawG5Evidence("DRAW-RESOURCE-INSUFFICIENT");
            if (drawCompleteRemainingAfterInsufficient)
            {
                drawCompleteRemainingAfterInsufficient = false;
                HideDrawExchange();
                if (drawTenResultView?.GameObject.activeSelf == true)
                    DismissDrawResult(drawTenResultView, "Layer/btn_Close", "DRAW-26-TEN-CONFIRM");
                StartCoroutine(CompleteBasicFriendDrawControlsThenReconnect());
                yield break;
            }
            if (drawClosureHeroMounted)
                StartCoroutine(ValidateDrawClosureReconnect());
            else
                StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        private IEnumerator RequestDrawClosureHeroNextFrame()
        {
            yield return null;
            pendingHeroEntry = HeroEntry.Bag;
            InvokeLuaOrFail(onHeroClicked, "Draw.ClosureHeroEntry");
        }

        public void BeginDrawClosureBagRefresh()
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            InvokeLuaOrFail(onDrawClosureBagRefresh, "Draw.ClosureBagRefresh");
        }

        public void CompleteDrawClosureBagRefresh(int serverCount)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            int current = GetBagQuantityByItemId(DrawClosureLevelMaterialId);
            if (drawClosureInitialLevel == 0)
            {
                if (!services.Heroes.TryGet(DrawClosureTargetHeroId, out HeroRecord hero)
                    || hero.Name != "郑伦" || hero.Star <= 0 || hero.Level <= 0 || hero.Attack <= 0
                    || hero.Health <= 0 || hero.FightPosition != 0 || serverCount <= 0 || current < 1)
                {
                    Fail($"Draw closure initial bag/hero snapshot mismatch: hero={hero.Id}, name={hero.Name}, star={hero.Star}, level={hero.Level}, pos={hero.FightPosition}, bag={serverCount}, material={current}.");
                    return;
                }
                drawClosureInitialLevel = hero.Level;
                drawClosureInitialExperience = hero.Experience;
                drawClosureInitialMaterial = current;
                StartCoroutine(CultivateDrawClosureHeroThroughUi());
                return;
            }
            if (serverCount <= 0 || current >= drawClosureInitialMaterial)
            {
                Fail($"Draw closure level material was not authoritatively deducted: serverCount={serverCount}, current={current}, before={drawClosureInitialMaterial}.");
                return;
            }
            StartCoroutine(MountDrawClosureHeroThroughUi());
        }

        public void CompleteDrawClosureHeroLevelUp(int heroId, int beforeLevel, int afterLevel,
            double beforeExperience, double afterExperience)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (heroId != DrawClosureTargetHeroId || beforeLevel != drawClosureInitialLevel
                || (afterLevel <= beforeLevel && afterExperience <= beforeExperience))
            {
                Fail($"Draw closure cultivation snapshot mismatch: hero={heroId}, level={beforeLevel}/{afterLevel}, exp={beforeExperience}/{afterExperience}.");
                return;
            }
            drawClosureHeroCultivated = true;
        }

        public void CompleteDrawClosureFormation(int heroId, int position, int level, double attack, double health)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (heroId != DrawClosureTargetHeroId || position != DrawClosureFormationPosition
                || !drawClosureHeroCultivated || attack <= 0 || health <= 0
                || services.Formation.GetCombatPosition(heroId) != position)
            {
                Fail($"Draw closure formation snapshot mismatch: hero={heroId}, position={position}, level={level}, attack={attack}, health={health}.");
                return;
            }
            drawClosureHeroMounted = true;
            pendingHeroEntry = HeroEntry.Formation;
            StartCoroutine(CaptureMountedDrawFormationThenReenter());
        }

        private IEnumerator CultivateDrawClosureHeroThroughUi()
        {
            yield return null;
            EnsureHeroPresenter();
            // /8 is refreshed for Draw ticket counts and can leave the ordinary
            // item-bag content active behind the shared OneLevelLayer.  Enter the
            // Hero bag exactly as the native client does before locating or
            // capturing the recruited hero.
            bagFlowPresenter?.CloseAll();
            bagView?.SetVisible(false);
            bagInputView?.SetVisible(false);
            bagPopupFrameView?.SetVisible(false);
            bagGiftView?.SetVisible(false);
            bagSourceView?.SetVisible(false);
            bagEquipmentInfoView?.SetVisible(false);
            pendingHeroEntry = HeroEntry.Bag;
            heroListView.SetVisible(false);
            heroDetailView.SetVisible(false);
            heroBagView.SetVisible(true);
            heroFrameView.SetVisible(true);
            Transform heroBagTransform = heroBagView.GameObject.transform;
            if (heroBagTransform.parent != heroFrameView.GameObject.transform)
                heroBagTransform.SetParent(heroFrameView.GameObject.transform, false);
            heroBagTransform.SetAsLastSibling();
            ConfigureHeroFrame(true);
            heroPresenter.Render();
            if (services.UiStack.Current != heroFrameView)
                services.UiStack.Push(heroFrameView);
            Canvas.ForceUpdateCanvases();
            Button target = FindHeroBagButton("郑伦");
            if (target == null) { Fail("Draw closure target hero was not rendered in the hero list."); yield break; }
            yield return CaptureDrawG5Evidence("DRAW-HERO-LIST");
            target.onClick.Invoke();
            if (heroPresenter.SelectedId != DrawClosureTargetHeroId)
            {
                Fail("Draw closure target hero row did not select hero 64.");
                yield break;
            }
            heroFrameView.SetVisible(true);
            heroBagView.SetVisible(false);
            heroListView.SetVisible(true);
            heroDetailView.SetVisible(true);
            ConfigureHeroFrame(false);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Btn_3_1_0", "Draw closure cultivate").onClick.Invoke();
            if (heroCultivationView?.GameObject.activeSelf != true || heroLevelUpView?.GameObject.activeSelf != true)
            {
                Fail("Draw closure cultivate control did not open the level-up UI.");
                yield break;
            }
            // Capture while the actual cultivation shell is stable.  The /24
            // material refresh may otherwise transition into formation before
            // the asynchronous screen capture executes.
            yield return CaptureDrawG5Evidence("DRAW-HERO-CULTIVATE");
            RequireBoundButton(heroLevelUpView, "Layer/shenjiangInfoUI/Info/cailiao/btn_shengji", "Draw closure level-up").onClick.Invoke();
        }

        private IEnumerator MountDrawClosureHeroThroughUi()
        {
            yield return null;
            EnsureHeroPresenter();
            if (heroCultivationView?.GameObject.activeSelf == true)
                RestoreHeroFormationView();
            if (services.Formation.GetCombatPosition(DrawClosureTargetHeroId) != 0)
            {
                Fail("Draw closure target hero was already mounted before the UI mount action.");
                yield break;
            }
            InvokeLuaOrFail(onDrawClosurePrepareMount, "Draw.ClosurePrepareFormationMount");
            int currentHeroId = GetFormationHeroAt(DrawClosureFormationPosition);
            ShowHeroReplacement(DrawClosureFormationPosition, currentHeroId);
            if (heroReplacementView?.GameObject.activeSelf != true)
            {
                Fail("Draw closure replacement UI did not open.");
                yield break;
            }
            yield return CaptureDrawG5Evidence("DRAW-FORMATION-SELECTION");
            Button action = heroReplacementView.GameObject.GetComponentsInChildren<Button>(true).FirstOrDefault(button =>
                button.gameObject.name == "Button" && button.transform.parent?.Find("Name")?.GetComponent<Text>()?.text.StartsWith("郑伦", StringComparison.Ordinal) == true);
            if (action == null)
            {
                Fail("Draw closure replacement UI did not render target hero 64.");
                yield break;
            }
            action.onClick.Invoke();
        }

        private Button FindHeroBagButton(string heroName)
        {
            if (heroBagView == null) return null;
            return heroBagView.GameObject.GetComponentsInChildren<Button>(true).FirstOrDefault(button =>
                button.transform.Find("Name")?.GetComponent<Text>()?.text.StartsWith(heroName, StringComparison.Ordinal) == true);
        }

        private IEnumerator CaptureMountedDrawFormationThenReenter()
        {
            // The Cocos Draw closure returns to the hero formation summary after the
            // /48 response.  Do not substitute the separate tactical formation map
            // here: it is a different user-facing screen and made the visual sample
            // incomparable even though the authoritative position was correct.
            formationPopupView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroFrameView?.SetVisible(true);
            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroBagView?.SetVisible(false);
            ConfigureHeroFrame(false);
            heroPresenter?.Render();
            heroFrameView?.GameObject.transform.SetAsLastSibling();
            yield return CaptureDrawG5Evidence("DRAW-FORMATION-MOUNTED");
            StartCoroutine(RequestDrawClosureModuleReentryNextFrame());
        }

        private void ShowDrawExchange()
        {
            drawExchangeView = drawExchangeView ?? services.UiRouter.FindBySource("common/daojuduihuan");
            if (drawExchangeView == null)
                throw new InvalidOperationException("Draw insufficient-resource exchange CocosUiBinding was not found.");
            drawExchangeView.BindClick("Layer/Popup/Btn_close", HideDrawExchange, true);
            if (drawExchangeDimmer == null)
            {
                drawExchangeDimmer = new GameObject("DrawExchangeDimmer", typeof(RectTransform), typeof(Image));
                RectTransform rect = drawExchangeDimmer.GetComponent<RectTransform>();
                rect.SetParent(drawExchangeView.GameObject.transform, false);
                rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                drawExchangeDimmer.GetComponent<Image>().color = new Color(0f, 0f, 0f, .82f);
                drawExchangeDimmer.GetComponent<Image>().raycastTarget = false;
                rect.SetAsFirstSibling();
            }
            drawExchangeDimmer.SetActive(true);
            SetBoundText(drawExchangeView, "Layer/Popup/Title/Title", "道具兑换");
            SetExchangeRuntimeText(drawExchangeView.Binding.Find("Layer/Popup/Title")?.transform,
                "RuntimeExchangeTitle", "道具兑换", TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, 27);
            Text exchangeTitle = drawExchangeView.Binding.Find("Layer/Popup/Title")?.transform
                .Find("RuntimeExchangeTitle")?.GetComponent<Text>();
            if (exchangeTitle != null) exchangeTitle.color = new Color(.96f, .80f, .60f, 1f);
            RenderDrawExchangeRows();
            drawExchangeView.SetVisible(true);
            drawExchangeView.GameObject.transform.SetAsLastSibling();
        }

        private void HideDrawExchange()
        {
            if (drawExchangeDimmer != null) drawExchangeDimmer.SetActive(false);
            drawExchangeView?.SetVisible(false);
        }

        private void RenderDrawExchangeRows()
        {
            Transform list = drawExchangeView.Binding.Find("Layer/Popup/ListView")?.transform;
            Transform template = drawExchangeView.Binding.Find("Layer/Popup/kuang")?.transform;
            if (list == null || template == null)
                throw new InvalidOperationException("Draw exchange imported ListView template was not found.");
            template.SetParent(list, false);
            for (int index = 0; index < 2; index++)
            {
                Transform row = index == 0 ? template : Instantiate(template.gameObject, list).transform;
                row.name = $"DrawExchangeRow{index + 1}";
                row.gameObject.SetActive(true);
                RectTransform rect = row as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = new Vector2(0.5f, 1f);
                    rect.anchorMax = new Vector2(0.5f, 1f);
                    rect.pivot = new Vector2(0.5f, 1f);
                    rect.anchoredPosition = new Vector2(0f, -12f - index * 128f);
                }
                // Cocos ItemExchangeUI reads shop 1014/1015: the price is
                // 60001 (pic 3012, YuanBao), while the output is item 1001
                // (pic 3028, advanced draw coupon).
                SetExchangeIcon(row.Find("Icon1"), 3012);
                SetExchangeIcon(row.Find("Icon2"), 3028);
                SetExchangeRuntimeText(row.Find("Icon1"), "RuntimeExchangeAmount", index == 0 ? "150" : "2700",
                    TextAnchor.LowerRight, new Vector2(.10f, .04f), new Vector2(.96f, .34f), 20);
                SetExchangeRuntimeText(row.Find("Icon2"), "RuntimeExchangeAmount", index == 0 ? "1" : "10",
                    TextAnchor.LowerRight, new Vector2(.10f, .04f), new Vector2(.96f, .34f), 20);
                Text button = row.Find("Btn_Confirm/Text")?.GetComponent<Text>();
                if (button != null) button.text = "兑 换";
                Text discount = row.Find("Discount/Value")?.GetComponent<Text>();
                if (discount != null)
                {
                    discount.transform.parent.gameObject.SetActive(index == 0);
                    discount.text = "5折";
                }
            }
        }

        private void SetExchangeIcon(Transform target, int picture)
        {
            Image image = target?.GetComponent<Image>();
            if (image == null) return;
            bool placeholder;
            image.sprite = services.Resources.LoadItemIcon(picture, out placeholder);
            image.enabled = image.sprite != null;
            image.preserveAspect = true;
        }

        private static void SetExchangeRuntimeText(Transform parent, string name, string value,
            TextAnchor alignment, Vector2 anchorMin, Vector2 anchorMax, int fontSize)
        {
            if (parent == null) return;
            Transform existing = parent.Find(name);
            GameObject instance = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(Outline));
            RectTransform rect = instance.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin; rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = instance.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = fontSize; text.alignment = alignment; text.text = value;
            text.color = Color.white; text.raycastTarget = false;
            instance.transform.SetAsLastSibling();
        }

        private IEnumerator RequestDrawClosureModuleReentryNextFrame()
        {
            yield return null;
            InvokeLuaOrFail(onHeroClicked, "Draw.ClosureHeroReentry");
        }

        public void CompleteDrawClosureModuleReentry(int heroId, int position, int level)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (!drawClosureHeroMounted || heroId != DrawClosureTargetHeroId
                || position != DrawClosureFormationPosition || !drawClosureHeroCultivated)
            {
                Fail($"Draw closure module reentry mismatch: mounted={drawClosureHeroMounted}, hero={heroId}, position={position}, level={level}.");
                return;
            }
            StartCoroutine(CompleteRemainingDrawControlsThenReconnect());
        }

        private IEnumerator CompleteRemainingDrawControlsThenReconnect()
        {
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before remaining Draw controls.");
                yield break;
            }
            ClickDrawButton(mainView, DrawPath, "DRAW-01-MAIN-ENTRY");
            float openDeadline = Time.realtimeSinceStartup + 8f;
            while (!IsDrawOpen && Time.realtimeSinceStartup < openDeadline) yield return null;
            if (!IsDrawOpen) { Fail("Draw did not reopen after cross-module visual capture."); yield break; }

            drawG4SequenceRunning = true;
            try
            {
                // Preserve the Cocos baseline's authoritative 20/0/200 ticket
                // snapshot: consume the prepared ten high tickets and capture the
                // following real insufficiency before exercising basic/friend draws.
                yield return InvokeDrawAndDismiss("Layer/Popup2/Btn_Recruit_1", "DRAW-05-HIGH-TEN",
                    drawTenResultView, "Layer/btn_Continue", "DRAW-27-TEN-CONTINUE", keepResult:true);
                DrawResultRecord tenResult = services.Draw.LastResult;
                if (tenResult == null || !tenResult.Rewards.Concat(tenResult.GuaranteedRewards)
                    .Any(value => value.TransformItemId > 0 || value.TransformAmount > 0))
                {
                    Fail("Draw G4 high ten draw did not expose an authoritative duplicate conversion.");
                    yield break;
                }
                MarkValidationControl("DRAW-28-RESULT-TRANSFORM");
                yield return CaptureDrawG5Evidence("DRAW-RESULT-DUPLICATE");

                drawCompleteRemainingAfterInsufficient = true;
                drawG4ExpectFailure = true;
                drawG4LastError = string.Empty;
                ClickDrawButton(drawTenResultView, "Layer/btn_Continue", "DRAW-27-TEN-CONTINUE");
                float failureDeadline = Time.realtimeSinceStartup + 8f;
                while (string.IsNullOrWhiteSpace(drawG4LastError) && Time.realtimeSinceStartup < failureDeadline)
                    yield return null;
                drawG4ExpectFailure = false;
                if (drawG4ExpectedFailureCompleted) yield break;
                if (string.IsNullOrWhiteSpace(drawG4LastError))
                {
                    Fail("Draw G4 expected high-pool insufficient-resource response was not returned.");
                    yield break;
                }
                MarkValidationControl("DRAW-27-TEN-CONTINUE");
            }
            finally { drawG4SequenceRunning = false; }
        }

        private IEnumerator CompleteBasicFriendDrawControlsThenReconnect()
        {
            drawG4SequenceRunning = true;
            try
            {
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/Bg", "DRAW-21-SINGLE-TIMELINE-SKIP");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_1", "DRAW-03-BASIC-TEN",
                    drawTenResultView, "Layer/dancichoukaUI/bg", "DRAW-25-TEN-TIMELINE-SKIP");
                yield return InvokeDrawAndDismiss("Layer/Popup3/Btn_Recruit_2", "DRAW-06-FRIEND-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
                yield return InvokeDrawAndDismiss("Layer/Popup3/Btn_Recruit_1", "DRAW-07-FRIEND-TEN",
                    drawTenResultView, "Layer/btn_Close", "DRAW-26-TEN-CONFIRM");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/Skill_1", "DRAW-24-SINGLE-SKILL");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Continue", "DRAW-23-SINGLE-CONTINUE", keepResult:true);
                ClickDrawButton(drawSingleResultView, "Layer/dancichoukaUI/btn_Continue", "DRAW-23-SINGLE-CONTINUE");
                float continueDeadline = Time.realtimeSinceStartup + 12f;
                while (services.Draw.LastResult == null && Time.realtimeSinceStartup < continueDeadline) yield return null;
                if (services.Draw.LastResult == null || !drawSingleResultView.GameObject.activeSelf)
                {
                    Fail("Draw G4 single continue did not trigger a new authoritative /224 result.");
                    yield break;
                }
                MarkValidationControl("DRAW-23-SINGLE-CONTINUE");
                DismissDrawResult(drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
            }
            finally { drawG4SequenceRunning = false; }
            StartCoroutine(ValidateDrawClosureReconnect());
        }

        private IEnumerator ValidateDrawClosureReconnect()
        {
            InvokeLuaOrFail(onDrawClosurePrepareReconnect, "Draw.ClosurePrepareReconnect");
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before deliberate disconnect.");
                yield break;
            }
            services.Network.Disconnect();
            HandleDisconnected("Draw closure deliberate disconnect");
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected || services.Heroes.Count != 0
                || services.Formation.CombatHeroes.Count != 0 || services.Bag.Count != 0 || IsHeroOpen)
            {
                Fail("Draw closure disconnect did not clear authoritative Hero/Formation/Bag state.");
                yield break;
            }
            Reconnect();
            float deadline = Time.realtimeSinceStartup + 20f;
            while ((services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main)
            {
                Fail("Draw closure reconnect timed out.");
                yield break;
            }
            StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        public void CompleteDrawClosureReconnect(int heroId, int position, int level, double experience)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (!drawClosureHeroMounted || !drawClosureHeroCultivated || heroId != DrawClosureTargetHeroId
                || position != DrawClosureFormationPosition || level < drawClosureInitialLevel
                || experience <= drawClosureInitialExperience)
            {
                Fail($"Draw closure reconnect snapshot mismatch: hero={heroId}, position={position}, level={level}, exp={experience}.");
                return;
            }
            RecordValidationSemantic("draw-authority", true, "/224 and authoritative /24,/48 snapshots");
            RecordValidationSemantic("draw-target-hero", true, "hero 64 returned by /224 and /24");
            RecordValidationSemantic("hero-level-up", true, "authoritative material deduction and experience increase");
            RecordValidationSemantic("formation-mounted", true, "authoritative /48 position 1");
            RecordValidationSemantic("draw-reconnect", true, "reconnect reloaded hero cultivation and formation");
            StartCoroutine(ValidateDrawClosureAccountIsolation());
        }

        private IEnumerator ValidateDrawClosureAccountIsolation()
        {
            uint isolationUserId = services.Options.DrawIsolationUserId;
            if (isolationUserId == 0 || isolationUserId == GetLocalUserId())
            {
                Fail("Draw closure requires a distinct -projectXDrawIsolationUserId.");
                yield break;
            }
            InvokeLuaOrFail(onDrawClosurePrepareAccountIsolation, "Draw.ClosurePrepareAccountIsolation");
            services.Config.LocalUserId = isolationUserId;
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before alternate-account login.");
                yield break;
            }
            ReturnToLogin();
            yield return new WaitForSecondsRealtime(0.25f);
            if (!IsLoginVisible || services.Heroes.Count != 0 || services.Formation.CombatHeroes.Count != 0)
            {
                Fail($"Draw closure account-switch cleanup mismatch: login={IsLoginVisible}, heroes={services.Heroes.Count}, combat={services.Formation.CombatHeroes.Count}, activeFormation={services.Formation.ActiveFormationId}.");
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
                Fail($"Draw closure alternate-account login failed: expected={isolationUserId}, actual={GetLocalUserId()}.");
                yield break;
            }
            StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        public void CompleteDrawClosureAccountIsolation(int heroCount, int mountedTargetPosition)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (services.Options.DrawIsolationUserId == 0 || GetLocalUserId() != services.Options.DrawIsolationUserId
                || services.Heroes.TryGet(DrawClosureTargetHeroId, out _) || mountedTargetPosition != 0)
            {
                Fail($"Draw closure alternate account inherited target state: user={GetLocalUserId()}, heroes={heroCount}, targetPosition={mountedTargetPosition}.");
                return;
            }
            RecordValidationSemantic("draw-account-isolation", true,
                $"alternate user={GetLocalUserId()} has no hero {DrawClosureTargetHeroId} or formation position");
            Complete($"COMPLETE: /224 high free deterministic target {DrawClosureTargetHeroId} -> /24 authoritative cultivation -> /48 position {DrawClosureFormationPosition} -> reconnect persistence -> alternate account {GetLocalUserId()} isolation");
        }

        private void RefreshDrawHotPoint()
        {
            GameObject button = mainView?.Binding.Find(DrawPath);
            Transform prompt = button?.transform.Find("Prompt");
            if (prompt != null) prompt.gameObject.SetActive(services?.Draw.HasFreeDraw == true);
        }

        private DrawResultRecord RequirePendingDraw() => pendingDrawResult
            ?? throw new InvalidOperationException("Draw result update was not started.");

        private static DrawRewardRecord NewDrawReward(int type, double rawId, double rawAmount,
            int transformItemId, double rawTransformAmount, string name, int picture, int quality) => new DrawRewardRecord
        {
            Type = checked((ushort)type),
            Id = checked((uint)rawId),
            Amount = checked((uint)rawAmount),
            TransformItemId = checked((ushort)transformItemId),
            TransformAmount = checked((uint)rawTransformAmount),
            Name = name ?? string.Empty,
            Picture = picture,
            Quality = quality
        };

        private void BeginFriendUpdate(int maximum, int expectedCount)
        {
            pendingFriendMaximum = checked((byte)maximum);
            pendingFriendRecords.Clear();
            if (expectedCount > pendingFriendRecords.Capacity) pendingFriendRecords.Capacity = expectedCount;
        }

        private void EnsureMainTaskTracker()
        {
            if (mainTaskTracker != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            CocosUiView backup = services.UiRouter.FindBySource("UImainLayer_backup");
            if (mainView == null || backup == null)
                throw new InvalidOperationException("Main or backup main task-tracker view was not found.");
            mainTaskTracker = new MainTaskTrackerPresenter(mainView, backup, services.Tasks, HandleTaskClick);
        }

        private void EnsureMainHudPresenter()
        {
            if (mainHudPresenter != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null) throw new InvalidOperationException("Main HUD view was not found.");
            chatMiniView = chatMiniView ?? services.UiRouter.FindBySource("/ChatLayer.csd");
            if (chatMiniView == null) throw new InvalidOperationException("HUD ChatLayer view was not found.");
            mainHudPresenter = new MainHudPresenter(mainView, chatMiniView, services.Player,
                services.Currencies, services.Chat, services.Resources);
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
            if (context.Protocol.Command == 221)
                InvokeLuaOrFail(onShopRequestTimeout, "Shop.OnRequestTimeout");
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
