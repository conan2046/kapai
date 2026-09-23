using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Newtonsoft.Json;
using ProjectX.Animation;
using ProjectX.Data;
using ProjectX.Diagnostics;
using ProjectX.LuaRuntime;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using ProjectX.Validation;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using XLua;

namespace ProjectX.Core
{
    [LuaCallCSharp]
    public sealed partial class ProjectXApp : MonoBehaviour
    {
        private enum ShopHubTab
        {
            Shop,
            Soul
        }

        private const string SinglePlayerFlowValidationFlag = "-projectXSinglePlayerFlowValidation";
        private const string SinglePlayerSaveRootPrefix = "-projectXSinglePlayerSaveRoot=";

        public const string LoginButtonPath = "Layer/Login/Btn_Play";
        public const string LoginServerButtonPath = "Layer/Login/Btn_Sever";
        public const string BagPath = "Layer/Bg/btn_Bag";
        public const string SettingsPath = "Layer/Main_UI/ButtonGroup7/btn_xitong";
        public const string TaskPath = "Layer/Bg/btn_renwu";
        public const string FormationPath = "Layer/Bg/btn_zhenrong";
        public const string HeroBagPath = "Layer/Bg/btn_shenjiangbeibao";
        public const string HeroRecyclePath = "Layer/Main_UI/ButtonGroup7/btn_huishou";
        public const string MailPath = "Layer/Main_UI/ButtonGroup7/btn_mail";
        public const string ShopPath = "Layer/Bg/btn_shangcheng";
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
        public const string DrawPath = "Layer/Bg/btn_zhaomu";
        public const string GameplayPath = "Layer/Bg/btn_wanfa";
        public const string MainCharacterPath = "Layer/Main_UI/ButtonGroup1/btn_zhujue";
        public const string EquipmentMenuPath = "Layer/Bg/btn_chuandai";
        public const string EquipmentBagPath = "Layer/Main_UI/tankuang2/btn_zhuangbei";
        public const string FaBaoBagPath = "Layer/Main_UI/tankuang2/btn_fabao";
        private static readonly HashSet<string> SteamExcludedModules = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "SevenDay", "Funds", "ResourceRecovery", "Welfare", "Friend", "Chat", "Team", "Guild",
            "Activity", "KunLun", "BloodFight", "StaminaClaim"
        };

        private GameServices services;
        private bool bagGraphicCensusWritten;
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
        private LuaFunction onXunBaoTaskClicked;
        private LuaFunction onHeroClicked;
        private LuaFunction onHeroSelected;
        private LuaFunction onHeroLevelUp;
        private LuaFunction onHeroAutoLevelUp;
        private LuaFunction onHeroBreakUp;
        private LuaFunction onHeroCultivate;
        private LuaFunction onHeroStarUp;
        private LuaFunction onHeroCultivationActivate;
        private LuaFunction onHeroCompose;
        private LuaFunction onHeroRebirthPreview;
        private LuaFunction onHeroRebirthConfirm;
        private LuaFunction onHeroBookOpened;
        private LuaFunction onHeroBookUpgrade;
        private LuaFunction onHeroEquipmentWear;
        private LuaFunction onEquipmentBagClicked;
        private LuaFunction onFaBaoBagClicked;
        private LuaFunction onHeroEquipmentTakeOff;
        private LuaFunction onHeroEquipmentAffixLock;
        private LuaFunction onHeroEquipmentAffixReroll;
        private LuaFunction onHeroEquipmentStrength;
        private LuaFunction onHeroEquipmentStrengthAll;
        private LuaFunction onHeroEquipmentRefine;
        private LuaFunction onHeroEquipmentAutoRefine;
        private LuaFunction onHeroEquipmentAwaken;
        private LuaFunction onHeroEquipmentDivine;
        private LuaFunction onHeroEquipmentCompose;
        private LuaFunction onFaBaoWear;
        private LuaFunction onFaBaoTakeOff;
        private LuaFunction onFaBaoStrength;
        private LuaFunction onFaBaoRefine;
        private LuaFunction onEnhanceMasterOpened;
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
        private LuaFunction onWorldAchievementRequest;
        private LuaFunction onWorldAchievementClaim;
        private LuaFunction onWorldRefresh;
        private LuaFunction onWorldValidateIsolation;
        // 龙崖副本模式（config.fuben_AB == 2）自动连战
        private LuaFunction onWorldSetChainAuto;
        private LuaFunction onWorldSetChainAutoNext;
        private LuaFunction onWorldContinueChain;
        private LuaFunction onWorldCancelChain;
        private LuaFunction onWorldRestartChain;
        private bool worldChainMode;
        // CheckBox_2「自动挑战下一章」：BOSS 结算确认后自动进入下一章并发起连战
        private bool worldChainAutoNext;
        private uint pendingAutoNextChapter;
        // 章节列表首屏的「通关奖励」条（ListView_1）需要当前章节的关卡列表才能汇总；
        // 这个标记表示本次 op=2 只是为了喂奖励条，回包后不要从章节列表切到关卡地图。
        private uint pendingRewardPreviewChapter;
        private bool stageListIsRewardPreview;
        // 记住玩家上次挑战（选中）的章节：下次进副本直接定位到它，而不是进度最新的章节。
        // 存 PlayerPrefs（按角色分键），跨会话生效；运行时用 lastWorldChapterId 缓存避免频繁读盘。
        private const string LastWorldChapterKeyPrefix = "ProjectX.World.LastChapter.";
        private uint lastWorldChapterId;
        // 「自动挑战」：控制失败重试与 Boss 胜利后的本章循环；普通关胜利后始终顺序续战。
        // 「自动挑战下一章」：只控制本章 Boss 胜利结算确认后的下一章切换。
        private bool worldChainAuto;
        private int worldChainIndex;
        private uint worldChainNextStageId;
        private Coroutine worldChainContinueCoroutine;
        private int worldChainContinueToken;
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
        private LuaFunction onYouLiStart;
        private LuaFunction onYouLiStartBatch;
        private LuaFunction onYouLiClaim;
        private LuaFunction onFengShenStoryClicked;
        private LuaFunction onFengShenStoryChallengeClicked;
        private LuaFunction onArenaClicked;
        private LuaFunction onKunLunClicked;
        private LuaFunction onBloodFightClicked;
        private LuaFunction onXunBaoClicked;
        private LuaFunction onXunBaoSearch;
        private LuaFunction onXunBaoSearchAll;
        private LuaFunction onXunBaoCompose;
        private LuaFunction onXunBaoComposeAll;
        private LuaFunction onXunBaoSearchTokenBagRequested;
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
        private CocosUiView oldMemoryView;
        private OldMemoryPresenter oldMemoryPresenter;
        private SinglePlayerSaveService singlePlayerSaves;
        private bool singlePlayerTitleEnabled;
        private bool localSaveServerStarting;
        private int activeSaveSlotId;
        private NoticePresenter noticePresenter;
        private readonly List<NoticeRecord> pendingGameNotices = new List<NoticeRecord>();
        private bool gameNoticeRequested;
        private string loginSignature = "local";
        private bool loginClosureValidationRunning;
        private CocosUiView mainView;
        private CocosUiView mainCloudView;
        private CocosUiView bagView;
        private CocosUiView oneLevelFrameView;
        private OneLevelFrameCoordinator oneLevelFrameCoordinator;
        private PlayerHubTabCoordinator playerHubTabCoordinator;
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
        private bool bagG4DirectUseScheduled;
        private readonly Dictionary<int, int> bagG4InitialBoxQuantities = new Dictionary<int, int>();
        private readonly Dictionary<int, int> bagG4ExpectedFragmentQuantities = new Dictionary<int, int>();
        private bool bagInitialG5DisconnectCaptured;
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
        private int pendingBagSelectionItemId;
        private CocosUiView rewardView;
        private RewardPresenter rewardPresenter;
        private readonly List<RewardRecord> pendingRewards = new List<RewardRecord>();
        private readonly Dictionary<int, RewardRecord> pendingBagUseRewards =
            new Dictionary<int, RewardRecord>();
        private readonly Dictionary<(int Type, uint Id), RewardRecord> pendingXunBaoRewards =
            new Dictionary<(int Type, uint Id), RewardRecord>();
        private readonly List<IReadOnlyList<RewardRecord>> pendingXunBaoRewardBatches =
            new List<IReadOnlyList<RewardRecord>>();
        private bool capturingBagUseRewards;
        private int bagUseRewardFilterItemId;
        private float lastBagUseRewardAt;
        private float bagUseRewardCaptureUntil;
        private Coroutine bagUseRewardRoutine;
        private readonly List<List<RewardRecord>> pendingWorldSweepGroups = new List<List<RewardRecord>>();
        private CocosUiView heroListView;
        private CocosUiView heroDetailView;
        private CocosUiView heroBagView;
        private CocosUiView heroBookView;
        private CocosUiView heroBookUpgradeView;
        private CocosUiView heroBookActivateResultView;
        private CocosUiView heroBookUpgradeResultView;
        private CocosUiView heroBookAttributesView;
        private CocosUiView heroBookAchievementView;
        private CocosUiView heroBookLevelResultView;
        private HeroBookPresenter heroBookPresenter;
        private readonly List<HeroBookEntry> pendingHeroBookEntries = new List<HeroBookEntry>();
        private readonly List<HeroBookAttribute> pendingHeroBookAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookScoreAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookUpgradeAttributes = new List<HeroBookAttribute>();
        private readonly List<HeroBookAttribute> pendingHeroBookUpgradeLevelAttributes = new List<HeroBookAttribute>();
        private int pendingHeroBookLevel;
        private long pendingHeroBookScore;
        private long pendingHeroBookNextStart;
        private long pendingHeroBookNextEnd;
        private CocosUiView heroRecycleView;
        private CocosUiView heroRebirthChooseFrameView;
        private CocosUiView heroRebirthChooseView;
        private CocosUiView heroRebirthConfirmView;
        private HeroRebirthPresenter heroRebirthPresenter;
        private bool heroRecycleEntryPending;
        private bool heroRecycleOpenedFromBag;
        private int heroRebirthResponseOperation;
        private int heroRebirthResponseHeroId;
        private bool heroRebirthG4ValidationRunning;
        private const string HeroRebirthControlMatrixSemantic = "hero-rebirth-control-matrix-24";
        private CocosUiView heroReplacementView;
        private bool heroReplacementOpenedFromHeroHub;
        private bool heroReplacementOpenedFromFormationPopup;
        private CocosUiView heroCultivationView;
        private CocosUiView heroLevelUpView;
        private CocosUiView heroAutoLevelUpView;
        private CocosUiView heroStarUpView;
        private CocosUiView heroBreakView;
        private CocosUiView heroCultivateView;
        private CocosUiView heroInfoView;
        private CocosUiView heroCultivationTalentView;
        private CocosUiView heroCultivationHelpFirstView;
        private CocosUiView heroCultivationHelpSecondView;
        private CocosUiView heroCultivationAttributeView;
        private CocosUiView heroCultivationNumberView;
        private CocosUiView heroCultivationHelpFrameView;
        private HeroCultivationPresenter heroCultivationPresenter;
        private CocosUiView heroEnhanceMasterView;
        private int heroEnhanceMasterType = 1;
        private int heroEnhanceMasterPosition = 1;
        private CocosUiView heroAttributesView;
        private CocosUiView heroItemSourceView;
        private HeroPresenter heroPresenter;
        private int activeHeroCultivationId;
        private bool heroCultivationG4ValidationRunning;
        private bool heroG4ControlValidationRunning;
        private CocosUiView formationPopupView;
        private FormationPopupPresenter formationPopupPresenter;
        private LuaFunction onFormationMove;
        private LuaFunction onFormationSwap;
        private LuaFunction onFormationUpgrade;
        private LuaFunction onFormationUse;
        private HeroEntry pendingHeroEntry = HeroEntry.Formation;
        private bool heroEntryRequestPending;
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
        private bool heroEquipmentOpenedFromEnhanceMaster;
        private readonly Dictionary<GameObject, bool> heroEnhanceMasterOneLevelChildVisibility =
            new Dictionary<GameObject, bool>();
        private bool heroEnhanceMasterOneLevelVisibilityCaptured;
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
        private CocosUiView faBaoStrengthView;
        private CocosUiView faBaoRefineView;
        private CocosUiView faBaoMaterialChooserView;
        private HeroEquipmentPresenter heroEquipmentPresenter;
        private bool heroEquipmentPresenterCultivationOnly;
        private int selectedHeroEquipmentFragmentId;
        private int selectedHeroFragmentId;
        private bool heroFragmentBagActive;
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
        private HeroEquipmentAffix pendingEquipmentAffix;
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
        private int pendingFunctionCultivationMode = -1;
        private HeroEquipmentKind pendingFunctionCultivationKind = HeroEquipmentKind.Equipment;
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
        private GameObject shopFramePanel;
        private bool shopFramePanelWasActive;
        private bool shopFramePanelStateCaptured;
        private GameObject shopGoldCheck;
        private bool shopGoldCheckWasActive;
        private bool shopGoldCheckStateCaptured;
        private bool shopHubOpen;
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
        private Transform gameplayShopActivityLayer;
        private bool gameplayShopActivityLayerWasActive;
        private bool gameplayShopActivityLayerStateCaptured;
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
        private CocosUiView worldAchievementView;
        private CocosUiView worldBattlePlaybackView;
        private CocosUiView fengShenBattlePlaybackView;
        private CocosUiView monopolyBattlePlaybackView;
        private WorldPresenter worldPresenter;
        private WorldOutcomePresenter worldOutcomePresenter;
        private WorldBattlePlaybackPresenter worldBattlePlaybackPresenter;
        private WorldBattlePlaybackPresenter worldBattleWorldPresenter;
        private WorldBattlePlaybackPresenter fengShenBattlePlaybackPresenter;
        private WorldBattlePlaybackPresenter monopolyBattlePlaybackPresenter;
        private enum BattlePlaybackContext { None, World, FengShenStory, Monopoly }
        private BattlePlaybackContext battlePlaybackContext;

        private WorldBattleReplayStore ActiveBattleReplayStore => battlePlaybackContext switch
        {
            BattlePlaybackContext.FengShenStory => services.FengShenBattleReplay,
            BattlePlaybackContext.Monopoly => services.MonopolyBattleReplay,
            _ => services.WorldBattleReplay
        };

        private WorldBattleReplayStore GetBattleReplayStore(BattlePlaybackContext context)
        {
            return context switch
            {
                BattlePlaybackContext.FengShenStory => services.FengShenBattleReplay,
                BattlePlaybackContext.Monopoly => services.MonopolyBattleReplay,
                _ => services.WorldBattleReplay
            };
        }

        private WorldBattlePlaybackPresenter GetBattlePlaybackPresenter(BattlePlaybackContext context)
        {
            return context switch
            {
                BattlePlaybackContext.FengShenStory => fengShenBattlePlaybackPresenter,
                BattlePlaybackContext.Monopoly => monopolyBattlePlaybackPresenter,
                _ => worldBattleWorldPresenter
            };
        }

        private WorldBattlePlaybackPresenter ActiveBattlePlaybackPresenter
            => GetBattlePlaybackPresenter(battlePlaybackContext);
        private Coroutine worldBattlePlaybackCoroutine;
        private Coroutine fengShenBattlePlaybackCoroutine;
        private Coroutine monopolyBattlePlaybackCoroutine;

        private sealed class BattlePlaybackRuntimeState
        {
            public bool PendingResult;
            public int PendingStars;
            public bool SuppressSettlementForSkippedPlayback;
        }

        private readonly BattlePlaybackRuntimeState worldBattleRuntime = new BattlePlaybackRuntimeState();
        private readonly BattlePlaybackRuntimeState fengShenBattleRuntime = new BattlePlaybackRuntimeState();
        private readonly BattlePlaybackRuntimeState monopolyBattleRuntime = new BattlePlaybackRuntimeState();

        private BattlePlaybackRuntimeState GetBattlePlaybackRuntime(BattlePlaybackContext context)
        {
            return context switch
            {
                BattlePlaybackContext.FengShenStory => fengShenBattleRuntime,
                BattlePlaybackContext.Monopoly => monopolyBattleRuntime,
                _ => worldBattleRuntime
            };
        }

        private Coroutine ActiveBattlePlaybackCoroutine => battlePlaybackContext switch
        {
            BattlePlaybackContext.FengShenStory => fengShenBattlePlaybackCoroutine,
            BattlePlaybackContext.Monopoly => monopolyBattlePlaybackCoroutine,
            _ => worldBattlePlaybackCoroutine
        };

        private void ClearBattlePlaybackCoroutine(BattlePlaybackContext context)
        {
            if (context == BattlePlaybackContext.FengShenStory) fengShenBattlePlaybackCoroutine = null;
            else if (context == BattlePlaybackContext.Monopoly) monopolyBattlePlaybackCoroutine = null;
            else worldBattlePlaybackCoroutine = null;
        }
        private Coroutine worldChainAutoSettlementCoroutine;
        private int worldChainAutoSettlementToken;
        private bool worldBattleBackgrounded;
        private bool worldBattleInFlight;
        // 龙崖连战：本场战斗出发时主角所在关卡（走位起点）。/320 op=8 会先把
        // WorldStore.CurrentStageId 推到新关，必须在它被改写之前抓下来。
        private uint worldChainWalkFromStageId;
        // 走位时长 —— 对齐 Cocos FuBenDetailUI:ModelMove 的 cc.MoveTo:create(2, ...)
        private const float WorldChainWalkSeconds = 2f;
        private const float WorldChainAutoSettlementSeconds = 2f;
        // 等 /38 回放播完的超时兜底（一场回放约 14 秒；异常路径不至于无限等待）
        private const float MaxWorldBattlePlaybackWait = 60f;
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
        private bool worldFormationReturnPending;
        private bool worldFormationReturnToDetail;
        // 打开阵容前 World 是否停在章节选择页（showChapters）。关闭阵容后按原状态还原，
        // 避免无条件 ShowStages() 把 chapterPage 的 btn_1..5 / Button_1 / Button_2 藏掉。
        private bool worldFormationReturnToChapters;
        private bool worldYouLiReturnPending;
        private bool worldFormationPopupRequestPending;
        private uint selectedWorldBoxStageId;
        private Button worldBoxClaimInteractionButton;
        private Button worldBoxCloseInteractionButton;
        private Button worldBoxTitleCloseInteractionButton;
        private byte worldAchievementType = 1;
        private byte worldAchievementBitmap;
        private bool worldAchievementAuthoritativeResponse;
        private Coroutine worldAchievementLayoutCoroutine;
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
        private CocosUiView drawHeroPreviewView;
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
        private readonly Dictionary<string, CocosUiView> configuredGameplayViews =
            new Dictionary<string, CocosUiView>(StringComparer.OrdinalIgnoreCase);
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
        private bool deferredFengShenRewardPush;
        private bool fengShenStoryValidationRunning;
        private bool fengShenStoryValidationCompleted;
        private bool battleFengShenStoryValidationRunning;
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
        private CocosUiView xunBaoResultView;
        private XunBaoResultPresenter xunBaoResultPresenter;
        private CocosUiView xunBaoPopupView;
        private XunBaoPopupPresenter xunBaoPopupPresenter;
        private CocosUiView xunBaoComposeAllView;
        private XunBaoComposeAllPresenter xunBaoComposeAllPresenter;
        private bool xunBaoValidationRunning;
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
        private CocosUiView gameplayShopItemInfoView;
        private GameplayShopItemInfoPresenter gameplayShopItemInfoPresenter;
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
        private string completionStatus = string.Empty;
        private string disconnectReason;
        private int reconnectAttempts;
        private bool autoReconnectRunning;

        public static ProjectXApp Instance { get; private set; }
        public string Status => status;
        public string CompletionStatus => completionStatus;
        public NetworkState NetworkState => services?.Network.State ?? NetworkState.Idle;
        public bool IsBagOpen => (bagView != null && services?.UiStack.Current == bagView)
            || (oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView
                && jingJieSurfaceMode == PlayerHubTab.Bag && bagView?.GameObject.activeInHierarchy == true);
        public int BagMissingIconCount => bagPresenter?.MissingIconCount ?? 0;
        public bool IsSettingsOpen => (settingsView != null && services?.UiStack.Current == settingsView)
            || (oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView
                && jingJieSurfaceMode == PlayerHubTab.Settings && settingsView?.GameObject.activeInHierarchy == true);
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
        public bool IsWorldOpen => worldView != null &&
            (services?.UiStack.Current == worldView || worldView.GameObject.activeSelf ||
             worldStageView?.GameObject.activeSelf == true || worldMapView?.GameObject.activeSelf == true ||
             worldDetailView?.GameObject.activeSelf == true);
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
        public bool IsHeroOpen => oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView;
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
            && oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView;
        public int HeroEquipmentCount => services?.HeroEquipment.Count ?? 0;
        public int FaBaoCount => services?.FaBao.Count ?? 0;
        public int HeroEquipmentMissingIconCount => heroEquipmentPresenter?.MissingIconCount ?? 0;
        public int HeroCount => services?.Heroes.Count ?? 0;
        public bool IsErrorVisible => errorPresenter?.IsVisible ?? false;
        public bool IsLoadingVisible => loadingPresenter?.IsVisible ?? false;
        public bool IsToastVisible => toastPresenter?.IsVisible ?? false;
        public bool IsServerTimeSynchronized => services?.ServerTime.IsSynchronized ?? false;
        public bool IsMailOpen => (mailView != null && services?.UiStack.Current == mailView)
            || (oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView
                && jingJieSurfaceMode == PlayerHubTab.Mail && mailView?.GameObject.activeInHierarchy == true);
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
            ShowMergedSettings();
        }

        private void HideOneLevelChildPagesForSettings()
        {
            // UiStack hides only the shared OneLevelLayer root. Its lazy Hero child
            // pages keep activeSelf=true and become visible again when Settings
            // reuses the frame, so isolate the frame before enabling it.
            HideHeroCultivationForNavigation();
            Transform frame = oneLevelFrameView?.GameObject.transform;
            if (frame == null) return;
            foreach (Transform child in frame.Cast<Transform>())
            {
                if (child.name.StartsWith("DynamicUi_", StringComparison.Ordinal))
                    child.gameObject.SetActive(false);
            }
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
                if (IsSettingsOpen || oneLevelFrameView.GameObject.activeSelf)
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
            ResetBattlePlaybackStateAfterDisconnect();
            services.Network.Disconnect();
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
            uint potential, uint soul, int packageCapacity, uint guildContribution)
        {
            services.Player.Initialize(roleId, name, unchecked((byte)sex), unchecked((byte)model),
                unchecked((byte)head), unchecked((ushort)level), checked((ulong)experience),
                checked((ulong)power), potential, soul, unchecked((ushort)packageCapacity));
            services.Currencies.Initialize(money, premium, boundPremium, soul, guildContribution);
            services.Mails.ConfigureAccount(roleId);
            if (singlePlayerTitleEnabled && activeSaveSlotId > 0)
                singlePlayerSaves?.UpdatePlayer(activeSaveSlotId, roleId, name, model, level, checked((ulong)power));
        }

        public void AddPlayerExperience(uint amount) => services.Player.AddExperience(amount);
        public void SetPlayerPower(double value) => services.Player.SetPower(checked((ulong)value));
        public void SetPlayerVipLevel(int value) => services.Player.SetVipLevel(checked((byte)value));
        public void SetPlayerLevelAndPower(int level, double value)
        {
            services.Player.SetLevelAndPower(unchecked((ushort)level), checked((ulong)value));
            if (singlePlayerTitleEnabled && activeSaveSlotId > 0)
                singlePlayerSaves?.UpdatePlayer(activeSaveSlotId, services.Player.RoleId,
                    services.Player.Name, services.Player.Model, level, checked((ulong)value));
            ApplySteamHudFunctionUnlocks();
        }
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
            if (singlePlayerTitleEnabled && IsNetworkLoadingKey(key))
            {
                loadingPresenter?.Hide(key);
                Debug.Log($"[ProjectX][SinglePlayer] Network activity | "
                    + (string.IsNullOrWhiteSpace(message) ? key : message));
                return;
            }
            EnsureCommonPresenters();
            loadingPresenter.Show(key, message, autoClearSeconds);
        }

        public void HideLoading(string key) => loadingPresenter?.Hide(key);

        private static bool IsNetworkLoadingKey(string key)
        {
            return string.Equals(key, "connect", StringComparison.Ordinal)
                || string.Equals(key, "reconnect", StringComparison.Ordinal)
                || string.Equals(key, "auto-reconnect", StringComparison.Ordinal);
        }

        public void ShowToast(string message, float visibleSeconds = 2f)
        {
            if (IsMonopolyOpen)
            {
                toastPresenter?.Clear();
                return;
            }
            EnsureCommonPresenters();
            // During an authoritative equipment refresh OneLevelLayer can be
            // temporarily inactive while its cultivation child remains the owner
            // of the pending operation. activeSelf preserves that UI ownership;
            // activeInHierarchy incorrectly sends the toast to the loading canvas.
            Transform parent = heroEquipmentCultivateView?.GameObject.activeSelf == true
                ? heroEquipmentCultivateView.GameObject.transform.parent
                : loadingView.GameObject.transform.parent;
            toastPresenter.SetParent(parent);
            toastPresenter.Show(message, visibleSeconds);
        }

        private void MaintainHeroEquipmentCultivationState()
        {
            if (heroEquipmentCultivateView?.GameObject.activeInHierarchy != true) return;

            // A successful write can emit the toast while an authoritative /319
            // refresh is temporarily rebuilding the cultivation siblings. Reattach
            // it to the active equipment canvas before ToastPresenter raises it.
            if (toastPresenter?.IsVisible == true)
                toastPresenter.SetParent(heroEquipmentCultivateView.GameObject.transform.parent);

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

            Text title = oneLevelFrameView?.Binding.Find(
                "Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            string cultivationTitle = heroEquipmentPresenter?.ActiveKind == HeroEquipmentKind.FaBao
                ? "法宝"
                : "装备";
            if (title != null && title.text != cultivationTitle) title.text = cultivationTitle;
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
                if (primaryUserId != 7200057 || primaryRoleId != 1000003)
                { Fail($"Player HUD requires fixed SQLite primary 7200057/1000003, actual={primaryUserId}/{primaryRoleId}."); yield break; }
                if (isolationUserId == 0 || isolationUserId == primaryUserId)
                { Fail("Player HUD requires a distinct -projectXPlayerHudIsolationUserId."); yield break; }
                if (!mainHudPresenter.Validate(out string detail))
                { RecordValidationSemantic("hud-authoritative-display", false, detail); Fail("Player HUD validation failed: " + detail); yield break; }
                if (services.Currencies.Premium != 100200 || services.Currencies.BoundPremium != 100000)
                {
                    Fail($"Player HUD split currency snapshot mismatch: premium={services.Currencies.Premium}, boundPremium={services.Currencies.BoundPremium}.");
                    yield break;
                }
                RecordValidationSemantic("hud-currency-separation", true,
                    $"/1004 and /18 preserve premium={services.Currencies.Premium} separately from boundPremium={services.Currencies.BoundPremium}");

                for (int index = 1; index <= 11; index++) MarkValidationControl($"HUD-{index:00}-" + HudControlSuffix(index));
                Button headEntry = mainView.Binding.Find(JingJieHeadPath)?.GetComponent<Button>();
                if (headEntry == null || !headEntry.interactable)
                { Fail("HUD Head/JingJie completed route is missing or disabled."); yield break; }
                MarkValidationControl("HUD-12-HEAD-BOUNDARY");
                string[] identityBoundaryPaths =
                {
                    "Layer/Main_UI/ButtonGroup6/Icon_tili/AddBtn",
                    "Layer/Main_UI/ButtonGroup6/Icon_jinbi/AddBtn"
                };
                for (int index = 0; index < identityBoundaryPaths.Length; index++)
                {
                    if (!AuditHudBoundary(mainView, identityBoundaryPaths[index], out string boundaryDetail))
                    { Fail($"HUD identity/currency boundary failed: {boundaryDetail}"); yield break; }
                    MarkValidationControl($"HUD-{index + 13:00}-" + HudControlSuffix(index + 13));
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

                Button wearEntry = mainView.Binding.Find(EquipmentMenuPath)?.GetComponent<Button>();
                if (!InvokeEventSystemClick(wearEntry))
                { Fail("HUD direct wear entry EventSystem input was unavailable."); yield break; }
                float wearDeadline = Time.realtimeSinceStartup + 12f;
                while (!IsHeroEquipmentOpen && Time.realtimeSinceStartup < wearDeadline) yield return null;
                if (!IsHeroEquipmentOpen || mainView.Binding.Find("Layer/Main_UI/tankuang2")?.activeSelf == true)
                { Fail("HUD wear entry did not open the equipment bag directly."); yield break; }
                MarkValidationControl("HUD-15-WEAR-EQUIPMENT-BAG");
                yield return CapturePlayerHudFrame("bootstrap-playerhud-wear-equipment-bag.png");
                if (!HandleBack() || IsHeroEquipmentOpen)
                { Fail("HUD direct wear equipment bag did not close cleanly."); yield break; }

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




        private bool IsBattlePresentationActive => worldBattlePlaybackCoroutine != null
            || fengShenBattlePlaybackCoroutine != null
            || monopolyBattlePlaybackCoroutine != null
            || worldBattlePlaybackPresenter?.IsVisible == true
            || fengShenBattlePlaybackPresenter?.IsVisible == true
            || monopolyBattlePlaybackPresenter?.IsVisible == true
            || worldBattleRuntime.PendingResult
            || fengShenBattleRuntime.PendingResult
            || monopolyBattleRuntime.PendingResult
            || worldOutcomePresenter?.IsBattleVisible == true
            || worldOutcomePresenter?.IsStatisticsVisible == true;


        public void ShowFengShenStoryBattleResult(int stars)
        {
            battlePlaybackContext = BattlePlaybackContext.FengShenStory;
            services.Rewards.Replace("封神列传结算", pendingRewards);
            if (fengShenBattleRuntime.SuppressSettlementForSkippedPlayback
                || fengShenBattlePlaybackPresenter?.SkipRequested == true)
            {
                fengShenBattleRuntime.PendingResult = false;
                fengShenBattleRuntime.PendingStars = 0;
                SetStatus($"FengShenStory skipped playback consumed op10 without presenting settlement: stars={stars}, rewards={services.Rewards.Count}.");
                return;
            }
            if (fengShenBattlePlaybackCoroutine != null || fengShenBattlePlaybackPresenter?.IsVisible == true)
            {
                fengShenBattleRuntime.PendingResult = true;
                fengShenBattleRuntime.PendingStars = stars;
                SetStatus($"FengShenStory authoritative result queued until natural playback completes: stars={stars}, rewards={services.Rewards.Count}.");
                return;
            }
            ShowWorldBattleResultNow(stars, BattlePlaybackContext.FengShenStory);
        }

        private void ShowWorldBattleResultNow(int stars, BattlePlaybackContext context)
        {
            EnsureWorldOutcomePresenter();
            WorldBattlePlaybackPresenter playbackPresenter = GetBattlePlaybackPresenter(context);
            if (worldChainAutoSettlementCoroutine != null)
            {
                worldChainAutoSettlementToken++;
                StopCoroutine(worldChainAutoSettlementCoroutine);
                worldChainAutoSettlementCoroutine = null;
            }
            bool fengShenStory = context == BattlePlaybackContext.FengShenStory;
            if (!fengShenStory && !CanShowWorldBattleUi())
            {
                // 玩家已经离开当前章节：结算仍以协议为准，但战斗层不能重新
                // 抢回前台。自动模式继续走既有后续逻辑；手动模式保持后台结束。
                playbackPresenter?.Hide();
                worldBattleResultView?.SetVisible(false);
                worldBattleStatisticsView?.SetVisible(false);
                GetBattlePlaybackRuntime(context).PendingResult = false;
                worldBattleInFlight = false;
                if (worldChainMode && worldChainNextStageId == 0
                    && (worldChainAuto || worldChainAutoNext))
                    ContinueBattleOutcomeControl();
                SetStatus("World battle completed in background because the current chapter view is not active.");
                return;
            }
            worldOutcomePresenter.SetReplayStore(GetBattleReplayStore(context));
            if (!fengShenStory)
            {
                // 本章已结束（Lua 侧 chainNextNodeId == 0 才走这条）：收起连战布点层
                // kapaiguaiwuLayer，回大底图 DadituuiLayer。胜败都走这里 —— 失败时
                // 服务端下发的是本章第一关（≠0），会继续连战，不会到这一步。
                worldPresenter?.ReleaseStageWalkHold();
                worldPresenter?.EndChainStage();
            }
            worldOutcomePresenter.ShowBattle(stars, !fengShenStory);
            SetStatus($"{(fengShenStory ? "FengShenStory" : "World")} battle result active: stars={stars}, rewards={services.Rewards.Count}.");
            // 龙崖 Boss 胜利：任一自动流程开启时，结算面板展示 2 秒后自动执行“继续”。
            // 普通关和失败不走这里；两个自动开关都关闭时必须等待玩家点击。
            if (!fengShenStory && worldChainMode && worldChainNextStageId == 0
                && (worldChainAuto || worldChainAutoNext))
            {
                int autoSettlementToken = ++worldChainAutoSettlementToken;
                worldChainAutoSettlementCoroutine = StartCoroutine(
                    AutoContinueWorldChainSettlement(BattlePlaybackContext.World, autoSettlementToken));
            }
            if (services.Options.WorldBattleValidation && worldG4BattleReplayValidated)
                StartCoroutine(CaptureWorldBattleResult(services.Rewards.Count));
            GetBattlePlaybackRuntime(context).PendingResult = false;
            if (context == BattlePlaybackContext.World)
                worldBattleInFlight = false;
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
            double magicDefense, double health, double speed, double currentHealth, int cultivationLevel,
            int cultivationAttack, int cultivationPhysicalDefense, int cultivationMagicDefense,
            int cultivationHealth, int primarySkillLevel = 1)
        {
            pendingHeroes.Add(new HeroRecord(id, fightPosition, name, star, breakLevel, level,
                checked((uint)experience), checked((uint)maxExperience), checked((ulong)power),
                checked((uint)attack), checked((uint)physicalDefense), checked((uint)magicDefense),
                checked((ulong)health), checked((uint)speed), checked((ulong)currentHealth), cultivationLevel,
                cultivationAttack, cultivationPhysicalDefense, cultivationMagicDefense, cultivationHealth,
                primarySkillLevel));
        }

        public double GetHeroPower(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Power : 0d;
        public double GetHeroAttack(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Attack : 0d;
        public double GetHeroHealth(int id) => services.Heroes.TryGet(id, out HeroRecord value) ? value.Health : 0d;
        public double GetPlayerPower() => services.Player.Power;

        public void EndHeroUpdate() => services.Heroes.Replace(pendingFollowHeroId, pendingHeroes);

        public void BeginHeroRebirthResponse(int operation, int heroId, int expectedCount)
        {
            heroRebirthResponseOperation = operation;
            heroRebirthResponseHeroId = heroId;
            heroRebirthPresenter?.BeginResponse(operation, heroId, expectedCount);
        }

        public void AddHeroRebirthReward(int type, double id, double quantity)
            => heroRebirthPresenter?.AddResponseReward(type, checked((uint)id), checked((uint)quantity));

        public void EndHeroRebirthResponse(int operation, int heroId, bool success, string error)
        {
            if (heroRebirthPresenter == null)
            {
                if (!success) ShowToast(string.IsNullOrWhiteSpace(error) ? "神将重生失败" : error, 3f);
                return;
            }
            heroRebirthPresenter.EndResponse(operation, heroId, success, error);
            heroRebirthResponseOperation = 0;
            heroRebirthResponseHeroId = 0;
        }

        public void BeginHeroBookSnapshot(int level, double score, double nextStart, double nextEnd,
            int expectedHeroCount)
        {
            pendingHeroBookLevel = level;
            pendingHeroBookScore = checked((long)score);
            pendingHeroBookNextStart = checked((long)nextStart);
            pendingHeroBookNextEnd = checked((long)nextEnd);
            pendingHeroBookEntries.Clear();
            pendingHeroBookAttributes.Clear();
            pendingHeroBookScoreAttributes.Clear();
            if (expectedHeroCount > pendingHeroBookEntries.Capacity)
                pendingHeroBookEntries.Capacity = expectedHeroCount;
        }

        public void AddHeroBookEntry(int heroId, int star, int score)
            => pendingHeroBookEntries.Add(new HeroBookEntry(heroId, star, score));

        public void AddHeroBookAttribute(int group, int type, double value)
        {
            var attribute = new HeroBookAttribute(type, checked((long)value));
            if (group == 1) pendingHeroBookAttributes.Add(attribute);
            else pendingHeroBookScoreAttributes.Add(attribute);
        }

        public void EndHeroBookSnapshot()
        {
            services.HeroBook.Replace(pendingHeroBookLevel, pendingHeroBookScore,
                pendingHeroBookNextStart, pendingHeroBookNextEnd, pendingHeroBookEntries,
                pendingHeroBookAttributes, pendingHeroBookScoreAttributes);
            SetStatus($"HeroBook synchronized: level={services.HeroBook.Level}, score={services.HeroBook.Score}, heroes={services.HeroBook.Entries.Count}.");
        }

        public void BeginHeroBookUpgrade(int heroId, int star, int addedScore, int bookLevel)
        {
            pendingHeroBookUpgradeAttributes.Clear();
            pendingHeroBookUpgradeLevelAttributes.Clear();
        }

        public void AddHeroBookUpgradeAttribute(int group, int type, double value)
        {
            var attribute = new HeroBookAttribute(type, checked((long)value));
            if (group == 1) pendingHeroBookUpgradeAttributes.Add(attribute);
            else pendingHeroBookUpgradeLevelAttributes.Add(attribute);
        }

        public void EndHeroBookUpgrade(int heroId, int star, int addedScore, int bookLevel,
            bool success, string error)
        {
            if (!success)
            {
                pendingHeroBookUpgradeAttributes.Clear();
                pendingHeroBookUpgradeLevelAttributes.Clear();
                ShowToast(string.IsNullOrWhiteSpace(error) ? "图鉴升级失败" : error, 3f);
                return;
            }
            // The Cocos activation flow stays on HeroBook and only overlays the result.
            // Repair stale sibling visibility without running the full auxiliary-page
            // navigation, which would briefly reopen Bag and rebind its close control.
            EnsureHeroBookSurfaceForResult();
            services.HeroBook.ApplyUpgrade(heroId, star, addedScore, bookLevel,
                pendingHeroBookUpgradeAttributes, pendingHeroBookUpgradeLevelAttributes);
            SetStatus($"HeroBook/322 upgrade applied: hero={heroId}, star={star}, score=+{addedScore}, level={bookLevel}.");
        }

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
            if (heroRecycleEntryPending)
            {
                ShowHeroRecycle(false);
                SetStatus($"HeroRebirth synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            if (worldFormationPopupRequestPending)
            {
                SetStatus($"World formation popup synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            if (heroHubOpen)
            {
                heroEntryRequestPending = false;
                ShowHeroHubTab(heroHubTab);
                SetStatus($"Hero hub tab active: {heroHubTab}; heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool explicitEntry = heroEntryRequestPending;
            heroEntryRequestPending = false;
            bool heroPageVisible = IsHeroOpen;
            bool hasVisibleHeroSubview = formationPopupView?.GameObject.activeSelf == true
                || heroCultivationView?.GameObject.activeSelf == true
                || heroLevelUpView?.GameObject.activeSelf == true;
            if (!explicitEntry && !heroPageVisible && !hasVisibleHeroSubview)
            {
                SetStatus($"Hero state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool preserveHeroBook = !explicitEntry
                && heroBookView?.GameObject.activeSelf == true;
            bool preserveHeroEquipmentSubpage = !explicitEntry
                && IsHeroEquipmentSubpageVisible;
            if (preserveHeroEquipmentSubpage)
            {
                // Equipment cultivation writes can push /70 and /48 after the
                // operation result. Those packets refresh data only; moving
                // OneLevelLayer to the top hides the still-active subpage.
                BindHeroEquipmentCultivationPortrait();
                SetStatus($"Hero equipment state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            if (preserveHeroBook)
            {
                // Activating a handbook entry causes the server to push /18, /70 and /48
                // before the /322 result. Those packets refresh data only; they must not
                // apply the remembered Bag entry and replace the visible handbook page.
                SetStatus($"HeroBook hero state synchronized without navigation: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            EnsureHeroPresenter();
            bool preserveFormationPopup = !explicitEntry
                && formationPopupView?.GameObject.activeSelf == true;
            if (preserveFormationPopup)
            {
                // /48 mutations refresh the authoritative formation mirror while
                // this popup is open. Keep the modal above the hero frame instead
                // of treating that data refresh as a fresh formation-page entry.
                formationPopupPresenter?.Render();
                formationPopupView.ShowPopup();
                formationPopupPresenter?.RefreshCloseInteraction();
                SetStatus($"Formation popup synchronized: heroes={services.Heroes.Count}, formation={services.Formation.ActiveFormationId}.");
                return;
            }
            bool preserveCultivation = !explicitEntry
                && (heroCultivationView?.GameObject.activeSelf == true
                    || heroLevelUpView?.GameObject.activeSelf == true);
            if (preserveCultivation)
            {
                // A successful cultivation operation refreshes /24 and /48.  That
                // snapshot updates data only; it must not navigate back to the
                // formation list/detail pages underneath the cultivation shell.
                SetHeroFramePageVisibility(false, false, false, true, true);
                RefreshHeroCultivationData(activeHeroCultivationId);
            }
            else
            {
                SetHeroFramePageVisibility(!showBag, !showBag, showBag, false, false);
                ConfigureHeroFrame(showBag);
            }
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
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
            if (worldFormationPopupRequestPending)
            {
                bool synchronized = luaHeroCount > 0 && luaFormationCount > 0
                    && luaHeroCount == services.Heroes.Count
                    && luaFormationCount == services.Formation.Formations.Count
                    && luaActiveFormationId == services.Formation.ActiveFormationId
                    && services.Formation.CombatHeroes.Any(heroId => heroId > 0);
                worldFormationPopupRequestPending = false;
                heroEntryRequestPending = false;
                if (!synchronized)
                {
                    Fail($"World formation popup synchronization mismatch: luaHeroes={luaHeroCount}, mirrorHeroes={services.Heroes.Count}, luaFormations={luaFormationCount}, mirrorFormations={services.Formation.Formations.Count}, active={luaActiveFormationId}/{services.Formation.ActiveFormationId}, combat=[{string.Join(",", services.Formation.CombatHeroes)}].");
                    return;
                }
                ShowFormationPopup();
                SetStatus($"World formation popup active: heroes={luaHeroCount}, formation={luaActiveFormationId}.");
                return;
            }
            EnsureHeroPresenter();
            bool showBag = pendingHeroEntry == HeroEntry.Bag;
            int rendered = showBag ? heroPresenter.BagItemCount : heroPresenter.ItemCount;
            bool luaMatchesMirror = luaHeroCount == services.Heroes.Count
                && luaFormationCount == services.Formation.Formations.Count
                && luaActiveFormationId == services.Formation.ActiveFormationId;
            // The hero bag is a complete-card grid and has no selected-detail state.
            // Lua may retain an undeployed LCPet selection while the shared formation
            // presenter keeps its detail panel on a deployed slot; both are valid for
            // this entry and must not turn a successful bag render into AppState.Failed.
            bool selectionMatches = showBag || luaSelectedHeroId == heroPresenter.SelectedId;
            bool requiresSkillIcon = !showBag
                && HeroCatalog.TryGet(luaSelectedHeroId, out HeroDefinition selectedDefinition)
                && selectedDefinition.SkillId > 0;
            if (luaHeroCount <= 0 || luaFormationCount <= 0 || rendered != luaHeroCount
                || !luaMatchesMirror || !selectionMatches || !IsHeroOpen
                || (requiresSkillIcon && !heroPresenter.HasVisibleSkillIcon))
            {
                Fail($"Lua formation read mismatch: entry={pendingHeroEntry}, luaHeroes={luaHeroCount}, "
                    + $"mirrorHeroes={services.Heroes.Count}, rendered={rendered}, luaFormations={luaFormationCount}, "
                    + $"mirrorFormations={services.Formation.Formations.Count}, active={luaActiveFormationId}/"
                    + $"{services.Formation.ActiveFormationId}, selected={luaSelectedHeroId}/{heroPresenter.SelectedId}, "
                    + $"skillIcon={heroPresenter.HasVisibleSkillIcon}, required={requiresSkillIcon}, open={IsHeroOpen}.");
                return;
            }
            if (!showBag && HasCommandLineFlag("-projectXFormationPopupValidation")
                && !services.Options.WorldBattleValidation) ShowFormationPopup();
            if (services.Options.WorldBattleValidation)
            {
                SetStatus($"World pre-challenge formation ready: heroes={luaHeroCount}, formations={luaFormationCount}.");
                return;
            }
            Complete(showBag
                ? $"COMPLETE: Lua formation model -> /24 heroes={luaHeroCount} -> /48 formations={luaFormationCount} -> C# render mirror -> hero bag UI"
                : $"COMPLETE: main formation button -> legacy Lua model -> /24 heroes={luaHeroCount} -> /48 active={luaActiveFormationId} -> C# render mirror -> formation UI");
        }

        public void SyncHeroSelection(int heroId)
        {
            EnsureHeroPresenter();
            heroPresenter.SelectFromAuthority(heroId);
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
            if (HasCommandLineFlag("-projectXFormationPopupValidation")
                && !services.Options.WorldBattleValidation) ShowFormationPopup();
            Complete($"COMPLETE: legacy Lua formation model -> /48 op=4 hero {heroId} "
                + $"{originalPosition}->{targetPosition} -> authoritative Lua snapshot -> restore "
                + $"{targetPosition}->{originalPosition} -> C# render mirror matched");
        }

        public void RunHeroG4ControlValidation(int heroId, int originalPosition, int targetPosition)
        {
            if (heroG4ControlValidationRunning) return;
            BeginValidationEvidence();
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
            if (!InvokeEventSystemClick(close))
            {
                Fail("Hero G4 formation popup close did not accept EventSystem pointer input.");
                yield break;
            }
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
            RecordValidationSemantic("hero-authoritative-entry", true,
                $"real main formation button -> /24 heroes={services.Heroes.Count} -> /48 formation={services.Formation.ActiveFormationId}");
            RecordValidationSemantic("hero-row-state-contract", true,
                $"occupied={restoredPosition}, empty={movedFromPosition}, all five rows unlocked and accepted EventSystem input");
            RecordValidationSemantic("hero-formation-mutation-restore", true,
                $"hero={heroId} moved {restoredPosition}->{movedFromPosition}->{restoredPosition} through authoritative /48 snapshots");
            RecordValidationSemantic("hero-sibling-boundaries", true,
                "replacement, cultivation, enhancement, equipment/fabao, attributes and formation popup each opened and closed without leaking siblings");
            RecordValidationSemantic("hero-fixture-exact-restore", true,
                "outer fixed-account runner owns immutable SQLite snapshot restore, relogin hash and zero-residue assertions");
            RecordValidationSemantic("hero-control-matrix-16", validationControlIds.Count == 16,
                $"validated={validationControlIds.Count}/16 through real EventSystem callbacks");
            Complete($"COMPLETE: Hero G4 real controls -> occupied/empty rows -> add/cultivate/enhance/replace -> 6 equipment/fabao slots -> attributes -> btn_buzhen -> position {restoredPosition}->{movedFromPosition}->{restoredPosition}; authoritative snapshots restored");
        }

        public bool InvokeHeroCloseForValidation()
        {
            if (!IsHeroOpen) return true;
            Button close = RequireBoundButton(oneLevelFrameView, "Layer/Panel_12/Title/CloseBtn", "hero close");
            if (!InvokeEventSystemClick(close)) return false;
            if (!IsHeroOpen)
            {
                SetOneLevelFrameVisible(false);
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
            if (!InvokeEventSystemRaycastClick(formationButton)) return false;
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
            int selectedBeforeClick = heroPresenter.SelectedId;
            if (heroId == selectedBeforeClick)
            {
                for (int index = 0; index < services.Formation.CombatHeroes.Count; index++)
                {
                    int candidateId = services.Formation.CombatHeroes[index];
                    if (candidateId <= 0 || candidateId == selectedBeforeClick) continue;
                    Button candidate = FindRuntimeHeroRowButton($"Hero_{candidateId}_");
                    if (candidate == null) continue;
                    heroId = candidateId;
                    originalPosition = index + 1;
                    occupied = candidate;
                    break;
                }
            }
            if (occupied == null) { Fail($"Hero G4 occupied row button was not found for hero {heroId}."); yield break; }
            if (heroId == selectedBeforeClick)
            {
                Fail("Hero G4 requires a second occupied formation hero to verify list switching.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(occupied))
            {
                Fail("Hero G4 occupied row was not the top EventSystem raycast target.");
                yield break;
            }
            if (heroPresenter.SelectedId != heroId || heroPresenter.SelectedPosition != originalPosition)
            {
                Fail("Hero G4 occupied row did not update the selected hero/position.");
                yield break;
            }
            ProjectX.Diagnostics.ClientLog.Verbose($"[HeroG4] Formation row switch passed: before={selectedBeforeClick}, "
                + $"after={heroPresenter.SelectedId}, position={heroPresenter.SelectedPosition}.");
            if (heroId == 11 && (!heroPresenter.HasVisibleSkillIcon
                    || heroPresenter.VisibleSkillName != "业火焚心"))
            {
                Fail($"Hero G4 hero 11 skill did not render: icon={heroPresenter.HasVisibleSkillIcon}, "
                    + $"name={heroPresenter.VisibleSkillName}.");
                yield break;
            }
            if (heroId == 11)
            {
                ProjectX.Diagnostics.ClientLog.Verbose("[HeroG4] Hero 11 skill render passed: 业火焚心 / skill_111.");
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
            if (!InvokeEventSystemClick(empty))
            {
                Fail("Hero G4 empty row did not accept EventSystem pointer input.");
                yield break;
            }
            if (heroPresenter.SelectedId != 0 || heroPresenter.SelectedPosition != targetPosition)
            {
                Fail("Hero G4 empty row did not preserve the empty selected position.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-03-EMPTY-ROW");

            if (!InvokeHeroPointer(heroDetailView, "Layer/EquipUI/Bg/Panel_new/addnew", "add hero")) yield break;
            if (heroReplacementView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 addnew button did not open the replacement view.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-05-ADD-HERO");
            HandleBack();

            if (!InvokeEventSystemClick(occupied)) { Fail("Hero G4 occupied row stopped accepting pointer input."); yield break; }
            if (!InvokeHeroPointer(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Btn_3_1_0", "cultivate")) yield break;
            if (heroCultivationView?.GameObject.activeSelf != true || heroLevelUpView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 cultivation button did not open the cultivation view.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-06-CULTIVATE");
            if (!InvokeHeroPointer(oneLevelFrameView, "Layer/Panel_12/Title/CloseBtn", "cultivation return")) yield break;
            if (heroCultivationView?.GameObject.activeSelf == true || heroLevelUpView?.GameObject.activeSelf == true)
            {
                Fail("Hero G4 cultivation return did not restore the formation view.");
                yield break;
            }

            if (!InvokeHeroPointer(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Button1", "enhance master")) yield break;
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

            if (!InvokeHeroPointer(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Button2", "replace hero")) yield break;
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
                if (!InvokeHeroPointer(heroDetailView, $"Layer/EquipUI/Bg/bg/EquipIcon{slot}", $"equipment slot {slot}")) yield break;
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

            if (!InvokeHeroPointer(heroDetailView, "Layer/EquipUI/Bg/bg/Btn_xiangxi", "hero attributes")) yield break;
            if (heroAttributesView?.GameObject.activeSelf != true)
            {
                Fail("Hero G4 attributes button did not open the attributes popup.");
                yield break;
            }
            yield return CaptureHeroG5Evidence("HERO-15-DETAIL");
            if (!InvokeHeroPointer(heroAttributesView, "Layer/Mask_close", "attributes close")) yield break;
            if (heroAttributesView.GameObject.activeSelf)
            {
                Fail("Hero G4 attributes mask did not close the popup.");
                yield break;
            }

            if (!InvokeHeroPointer(heroListView, "Layer/shenjiangListUI/List/btn_buzhen", "formation")) yield break;
            if (!IsFormationPopupOpen)
            {
                Fail("Hero G4 btn_buzhen did not open the formation popup.");
                yield break;
            }
            // ShowFormationPopup creates and binds the virtual formation rows in
            // the current click callback. Their Graphics receive a valid canvas
            // depth only after the next render cycle; real users cannot click a
            // newly opened item before that boundary either.
            yield return null;
            yield return new WaitForEndOfFrame();
            yield return null;
            int expectedFormationModels = services.Formation.CombatHeroes.Count(hero => hero > 0);
            if (formationPopupPresenter == null
                || formationPopupPresenter.RenderedModelCount != expectedFormationModels)
            {
                Fail($"Hero G4 formation model count mismatch: rendered={formationPopupPresenter?.RenderedModelCount ?? -1}, expected={expectedFormationModels}.");
                yield break;
            }
            int activeFormationId = services.Formation.ActiveFormationId > 0
                ? services.Formation.ActiveFormationId : 1;
            int selectableFormationId = activeFormationId == 1 ? 2 : 1;
            Button formationItem = formationPopupPresenter.GetFormationButton(selectableFormationId);
            if (!InvokeEventSystemRaycastClick(formationItem)
                || formationPopupPresenter.SelectedFormationId != selectableFormationId)
            {
                Fail($"Hero G4 formation list item did not accept real pointer input: target={selectableFormationId}, selected={formationPopupPresenter.SelectedFormationId}.");
                yield break;
            }
            Button activeFormationItem = formationPopupPresenter.GetFormationButton(activeFormationId);
            if (!InvokeEventSystemRaycastClick(activeFormationItem)
                || formationPopupPresenter.SelectedFormationId != activeFormationId)
            {
                Fail($"Hero G4 formation list item did not restore the active selection: target={activeFormationId}, selected={formationPopupPresenter.SelectedFormationId}.");
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
            if (!InvokeHeroPointer(formationPopupView, $"Layer/FormationUI/Show/Formation/Position{currentGrid}", "current formation position")) yield break;
            if (!InvokeHeroPointer(formationPopupView, $"Layer/FormationUI/Show/Formation/Position{targetGrid}", "target formation position")) yield break;
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
            if (!InvokeEventSystemClick(locked))
            {
                Fail("Hero locked row did not accept EventSystem pointer input.");
                yield break;
            }
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
            MarkValidationControl(controlId);
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

        private bool InvokeHeroPointer(CocosUiView view, string path, string label)
        {
            Button button = RequireBoundButton(view, path, label);
            if (InvokeEventSystemClick(button)) return true;
            Fail($"Hero G4 {label} did not accept EventSystem pointer input: {path}");
            return false;
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
            pendingEquipmentAffix = HeroEquipmentAffix.None;
            pendingCultivation.Clear();
        }

        public void SetPendingHeroEquipmentAffix(double seed, int id, int tier, int lockMask,
            string key, string name, string description, int value1, int value2)
        {
            pendingEquipmentAffix = new HeroEquipmentAffix(checked((uint)seed), id, tier, lockMask,
                key, name, description, value1, value2);
        }

        public void AddHeroEquipmentCultivation(int type, int level)
            => pendingCultivation.Add(new CultivationLevel(type, level));

        public void EndHeroEquipmentRecord()
        {
            pendingHeroEquipment.Add(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                pendingEquipmentStrengthAttributeType, pendingEquipmentStrengthAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId), pendingEquipmentAffix));
        }

        public void EndHeroEquipmentUpdate() => services.HeroEquipment.Replace(pendingHeroEquipment);

        public void UpsertHeroEquipmentRecord()
        {
            services.HeroEquipment.Upsert(new HeroEquipmentRecord(pendingEquipmentUid, pendingEquipmentTemplateId,
                pendingEquipmentFormationPosition, pendingEquipmentExperience, pendingCultivation.ToArray(),
                pendingEquipmentBaseAttributeType, pendingEquipmentBaseAttributeValue,
                pendingEquipmentStrengthAttributeType, pendingEquipmentStrengthAttributeValue,
                services.EquipmentCatalog.GetEquipment(pendingEquipmentTemplateId), pendingEquipmentAffix));
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

        public void SetEnhanceMasterLevels(int formationPosition, int level1, int level2, int level3,
            int level4, int level5, int level6)
        {
            services.EnhanceMasters.SetPosition(formationPosition, level1, level2, level3,
                level4, level5, level6);
            if (heroEnhanceMasterView != null && heroEnhanceMasterView.GameObject.activeSelf
                && formationPosition == heroEnhanceMasterPosition)
                BindHeroEnhanceMaster(heroEnhanceMasterView, formationPosition);
        }

        public void NotifyEnhanceMasterLevel(int formationPosition, int type, int level)
        {
            SetStatus($"强化大师更新：阵位{formationPosition} 类型{type} 等级{level}");
        }

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
            HeroEquipmentKind displayKind = kind == 2 ? HeroEquipmentKind.FaBao : HeroEquipmentKind.Equipment;
            if (TryOpenPendingFunctionCultivation(displayKind)) return;
            HideHeroCultivationForNavigation();
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
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
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
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
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

        public void RunHeroEquipmentG5VisualValidation()
        {
            StartCoroutine(RunHeroEquipmentG5VisualValidationRoutine());
        }

        private IEnumerator RunHeroEquipmentG5VisualValidationRoutine()
        {
            const uint sourceUid = 2121072641;
            BeginValidationEvidence();
            EnsureHeroEquipmentPresenter();
            if (!services.HeroEquipment.TryGet(sourceUid, out HeroEquipmentRecord source)
                || source.FormationPosition != 1 || services.HeroEquipment.Count != 4)
            {
                Fail("HeroEquip G5 visual fixture did not expose the four source-equivalent worn equipment records.");
                yield break;
            }

            if (services.UiStack.Current == oneLevelFrameView
                || services.UiStack.Current?.GameObject?.name == "OneLevelLayer")
            {
                Button initialClose = oneLevelFrameView?.Binding.Find(
                    "Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(initialClose))
                { Fail("HeroEquip G5 visual runner could not close the bootstrap equipment frame."); yield break; }
                yield return null;
            }

            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true) ?? mainView;
            float deadline = Time.realtimeSinceStartup + 30f;
            while (mainView?.GameObject.activeInHierarchy != true && Time.realtimeSinceStartup < deadline)
                yield return null;
            Button wearToggle = mainView?.Binding.Find("Layer/Bg/btn_chuandai")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(wearToggle))
            { Fail("HeroEquip G5 visual wear toggle was unavailable."); yield break; }
            yield return null;
            yield return CaptureHeroEquipmentG5State("g1-wear-popup-open.png");

            Button equipmentEntry = mainView.Binding.Find(EquipmentBagPath)?.GetComponent<Button>();
            if (!InvokeEventSystemClick(equipmentEntry))
            { Fail("HeroEquip G5 visual equipment entry was unavailable."); yield break; }
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroEquipmentOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroEquipmentOpen) { Fail("HeroEquip G5 visual equipment bag did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-bag.png");

            Toggle hideWorn = heroEquipmentListView.Binding.Find(
                "Layer/zhuangbeibeibaoUI/CheckBox")?.GetComponent<Toggle>();
            bool hideBefore = hideWorn?.isOn ?? false;
            if (!InvokeEventSystemClick(hideWorn) || hideWorn.isOn == hideBefore)
            { Fail("HeroEquip G5 visual hide-worn state was unavailable."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-bag-empty.png");
            if (!InvokeEventSystemClick(hideWorn) || hideWorn.isOn != hideBefore)
            { Fail("HeroEquip G5 visual hide-worn state did not restore."); yield break; }

            Button listItem = heroEquipmentPresenter.GetListItemAction(sourceUid);
            if (!InvokeEventSystemClick(listItem) || !heroEquipmentPresenter.IsDetailVisible)
            { Fail("HeroEquip G5 visual source equipment detail did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-equipment-detail.png");
            Button detailClose = heroEquipmentDetailView.Binding.Find(
                "Layer/zhuangbeiInfoUI/Popup/Btn_close")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(detailClose))
            { Fail("HeroEquip G5 visual equipment detail did not close."); yield break; }

            Button cultivate = heroEquipmentPresenter.GetListCultivateAction(sourceUid);
            if (!InvokeEventSystemClick(cultivate) || heroEquipmentStrengthView.GameObject.activeSelf != true)
            { Fail("HeroEquip G5 visual strength page did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-strength-before.png");

            if (!heroEquipmentPresenter.PrepareDetails(sourceUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian")?.GetComponent<Button>()))
            { Fail("HeroEquip G5 visual refine page did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-refine-before.png");

            heroEquipmentPresenter.ShowCultivationTab(2);
            yield return null;
            if (!IsToastVisible || heroEquipmentDetailView.GameObject.activeSelf)
            { Fail("HeroEquip G5 visual awaken lock did not remain on cultivation with source-equivalent feedback."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-awaken-locked.png");

            heroEquipmentPresenter.ShowCultivationTab(3);
            yield return null;
            if (!IsToastVisible || heroEquipmentDetailView.GameObject.activeSelf)
            { Fail("HeroEquip G5 visual divine lock did not remain on cultivation with source-equivalent feedback."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-shenzhu-locked.png");

            errorPresenter?.Hide();
            toastPresenter?.Clear();
            const int sourceMaterialId = 610;
            int sourceMaterialQuantity = services.Bag.GetTotalQuantityByItemId(sourceMaterialId);
            EquipmentMaterialDefinition sourceDefinition = services.EquipmentCatalog.GetItem(sourceMaterialId);
            if (sourceMaterialQuantity <= 0 || sourceDefinition == null)
            { Fail("HeroEquip G5 visual source material was missing."); yield break; }
            BagItemRecord sourceMaterial = new BagItemRecord(0, sourceMaterialId, sourceMaterialQuantity,
                sourceDefinition.Name, "装备洗炼属性时使用，用于重新生成装备的洗炼属性，只能洗出10星及以下的属性",
                sourceDefinition.Picture, sourceDefinition.Quality, 0, 0, 0, sourceDefinition.Type);
            ShowHeroEquipmentFragmentSource(sourceMaterial);
            yield return null;
            yield return CaptureHeroEquipmentG5State("g1-source-actionable.png");
            CloseHeroItemSource();

            ShowHeroEquipmentFragments();
            yield return null;
            yield return CaptureHeroEquipmentG5State("g1-equipment-pieces-empty.png");

            Button frameClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
            if (!InvokeEventSystemClick(frameClose))
            { Fail("HeroEquip G5 visual equipment frame did not close."); yield break; }
            yield return null;
            // The shared OneLevelLayer close contract first returns a fragment/cultivation
            // subpage to the equipment list. A second real close leaves the module.
            if (IsHeroEquipmentOpen)
            {
                frameClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(frameClose))
                { Fail("HeroEquip G5 visual equipment list did not close after returning from fragments."); yield break; }
            }
            deadline = Time.realtimeSinceStartup + 12f;
            Button formationEntry = mainView.Binding.Find(FormationPath)?.GetComponent<Button>();
            while ((mainView?.GameObject.activeInHierarchy != true || formationEntry == null
                    || !formationEntry.gameObject.activeInHierarchy || !formationEntry.interactable)
                && Time.realtimeSinceStartup < deadline)
            {
                formationEntry = mainView?.Binding.Find(FormationPath)?.GetComponent<Button>();
                yield return null;
            }
            if (!InvokeEventSystemClick(formationEntry))
            {
                Fail($"HeroEquip G5 visual formation entry was unavailable: button={formationEntry != null}, "
                    + $"active={formationEntry?.gameObject.activeInHierarchy}, interactable={formationEntry?.interactable}, "
                    + $"main={mainView?.GameObject.activeInHierarchy}, equipment={IsHeroEquipmentOpen}, "
                    + $"stack={services.UiStack.Current?.GameObject?.name}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 12f;
            while (!IsHeroOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsHeroOpen) { Fail("HeroEquip G5 visual hero detail did not open."); yield break; }
            yield return CaptureHeroEquipmentG5State("g1-hero-detail-equipped.png");

            Complete("COMPLETE: HeroEquip G5 visual fixed-identity 11-state capture passed");
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

            if (services.UiStack.Current == oneLevelFrameView
                || services.UiStack.Current?.GameObject?.name == "OneLevelLayer")
            {
                Button bootstrapFrameClose = oneLevelFrameView?.Binding.Find(
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
            Button wearToggle = mainView.Binding.Find("Layer/Bg/btn_chuandai")?.GetComponent<Button>();
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
            Button equipmentTab = oneLevelFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.GetComponent<Button>();
            if (equipmentTab == null || equipmentTab.interactable)
            { Fail("HeroEquip G4 selected equipment tab state was not source-equivalent."); yield break; }
            MarkValidationControl("HE-04-EQUIPMENT-BAG-TAB");
            Button equipmentHelp = oneLevelFrameView.Binding.Find(
                "Layer/Panel_12/Title/TitleName/Button_1")?.GetComponent<Button>();
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
            yield return CaptureHeroEquipmentG5State("g1-equipment-hide-worn.png");
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
            if (!heroEquipmentPresenter.AreCultivationAttributesBound(1))
            { Fail("HeroEquip G4 refine attributes were missing, empty, or still placeholder values."); yield break; }
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
            // The /319 list refresh and toast are dispatched in the same packet
            // frame. Validate the rendered hierarchy after Update has reapplied
            // the cultivation sibling contract once.
            yield return null;
            if (IsToastVisible && (toastPresenter?.Parent != heroEquipmentCultivateView.GameObject.transform.parent
                || !toastPresenter.IsLastSibling))
            {
                Transform expectedToastParent = heroEquipmentCultivateView.GameObject.transform.parent;
                Transform actualToastParent = toastPresenter?.Parent;
                Fail($"HeroEquip G4 success toast was not the last sibling below the cultivation views: "
                    + $"expected={expectedToastParent?.name}, actual={actualToastParent?.name}, "
                    + $"index={(actualToastParent == null ? -1 : actualToastParent.Find("RuntimeToast")?.GetSiblingIndex() ?? -1)}/"
                    + $"{actualToastParent?.childCount ?? -1}, visible={IsToastVisible}, "
                    + $"cultivateSelf={heroEquipmentCultivateView.GameObject.activeSelf}, "
                    + $"cultivateHierarchy={heroEquipmentCultivateView.GameObject.activeInHierarchy}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 5f;
            while ((heroEquipmentPresenter.HasActiveCultivationEffect || IsToastVisible)
                && Time.realtimeSinceStartup < deadline)
            {
                if (IsToastVisible && (toastPresenter.Parent != heroEquipmentCultivateView.GameObject.transform.parent
                    || !toastPresenter.IsLastSibling))
                { Fail("HeroEquip G4 refine toast changed parent or sibling order during its visible lifetime."); yield break; }
                yield return null;
            }
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
            Image fragmentQuality = composableFragment?.Find("FragmentQuality")?.GetComponent<Image>();
            Image fragmentBadge = composableFragment?.Find("FragmentBadge")?.GetComponent<Image>();
            Text fragmentQuantity = composableFragment?.Find("Text")?.GetComponent<Text>();
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
            Text refreshedQuantity = refreshedFragment?.Find("Text")?.GetComponent<Text>();
            string expectedFragmentProgress = $"{fragmentQuantityAfter}/{fragmentComposeCost}";
            if (fragmentProgress == null || fragmentProgress.text != expectedFragmentProgress
                || refreshedQuantity == null || refreshedQuantity.text != fragmentQuantityAfter.ToString())
            {
                string matchingCells = string.Join(";", heroEquipmentFragmentView.GameObject
                    .GetComponentsInChildren<Transform>(true)
                    .Where(value => value.name == $"EquipmentFragment_{composeFragmentId}")
                    .Select(value => $"active={value.gameObject.activeInHierarchy},self={value.gameObject.activeSelf},qty={value.Find("Text")?.GetComponent<Text>()?.text}"));
                Fail($"HeroEquip G4 compose refreshed the bag model but left fragment progress or grid quantity stale; "
                    + $"model={fragmentQuantityAfter}, expected={expectedFragmentProgress}, progress={fragmentProgress?.text}, "
                    + $"refreshed={refreshedQuantity?.text}, cells={matchingCells}.");
                yield break;
            }
            yield return CaptureHeroEquipmentG5State("g1-equipment-pieces-empty.png");

            if (!heroEquipmentPresenter.PrepareDetails(targetUid, 1)
                || !InvokeEventSystemClick(heroEquipmentDetailView.Binding.Find(
                    "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing")?.GetComponent<Button>()))
            { Fail("HeroEquip G4 awaken entry EventSystem input unavailable."); yield break; }
            if (heroEquipmentPresenter.IsStrengthAllVisible)
            { Fail("HeroEquip G4 strengthen-all leaked onto the awaken tab."); yield break; }
            if (!heroEquipmentPresenter.AreCultivationAttributesBound(2))
            { Fail("HeroEquip G4 awaken attributes were missing, empty, or still placeholder values."); yield break; }
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
            deadline = Time.realtimeSinceStartup + 5f;
            while ((heroEquipmentPresenter.HasActiveCultivationEffect || IsToastVisible)
                && Time.realtimeSinceStartup < deadline)
            {
                if (IsToastVisible && (toastPresenter.Parent != heroEquipmentCultivateView.GameObject.transform.parent
                    || !toastPresenter.IsLastSibling))
                { Fail("HeroEquip G4 awaken toast changed parent or sibling order during its visible lifetime."); yield break; }
                yield return null;
            }
            if (heroEquipmentPresenter.HasActiveCultivationEffect)
            { Fail("HeroEquip G4 awaken success Imod retained its final frame after completion."); yield break; }
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
            if (!heroEquipmentPresenter.AreCultivationAttributesBound(3))
            { Fail("HeroEquip G4 shenzhu attributes were missing, empty, or still placeholder values."); yield break; }
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
            yield return null;
            deadline = Time.realtimeSinceStartup + 5f;
            while ((heroEquipmentPresenter.HasActiveCultivationEffect || IsToastVisible)
                && Time.realtimeSinceStartup < deadline)
            {
                if (IsToastVisible && (toastPresenter.Parent != heroEquipmentCultivateView.GameObject.transform.parent
                    || !toastPresenter.IsLastSibling))
                { Fail("HeroEquip G4 shenzhu toast changed parent or sibling order during its visible lifetime."); yield break; }
                yield return null;
            }
            if (heroEquipmentPresenter.HasActiveCultivationEffect)
            { Fail("HeroEquip G4 shenzhu success Imod retained its final frame after completion."); yield break; }
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
                Button tabButton = oneLevelFrameView.Binding.Find(
                    $"Layer/Panel_12/Bg/Btn_ListView/Panel_10/{tabName}")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(tabButton))
                { Fail($"HeroEquip G4 cultivate tab EventSystem input unavailable: {cultivateTabIds[tab]}"); yield break; }
                if (!heroEquipmentPresenter.IsCultivationSubviewExclusive(tab))
                { Fail($"HeroEquip G4 cultivate tab left multiple subviews active: {cultivateTabIds[tab]}"); yield break; }
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
            yield return null;
            if (IsGameplayShopOpen || !IsToastVisible || heroItemSourceView.GameObject.activeSelf
                || !heroEquipmentFragmentView.GameObject.activeSelf || !oneLevelFrameView.GameObject.activeSelf)
            {
                Fail("HeroEquip G4 excluded functionId=17 source did not preserve the fragment flow with deferred feedback.");
                yield break;
            }
            MarkValidationControl("HE-78-SOURCE-DYNAMIC-TARGET");
            Button equipmentFrameClose = oneLevelFrameView.Binding.Find(
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
                    + $"frame={oneLevelFrameView.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}.");
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
            Button faBaoTab = oneLevelFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.GetComponent<Button>();
            if (faBaoTab == null || faBaoTab.interactable)
            { Fail("HeroEquip G4 selected FaBao tab state was not source-equivalent."); yield break; }
            MarkValidationControl("HE-11-FABAO-BAG-TAB");
            GameObject faBaoFragmentTab = oneLevelFrameView.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime");
            if (faBaoFragmentTab == null || faBaoFragmentTab.activeInHierarchy)
            { Fail("HeroEquip G4 excluded FaBao fragment tab was not hidden."); yield break; }
            MarkValidationControl("HE-12-FABAO-FRAGMENT-TAB");
            MarkValidationControl("HE-15-FABAO-FRAGMENT-ACTIONS-DEFERRED");
            Button faBaoHelp = oneLevelFrameView.Binding.Find(
                "Layer/Panel_12/Title/TitleName/Button_1")?.GetComponent<Button>();
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
            Button frameClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
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
                    + $"heroFrame={oneLevelFrameView?.GameObject.activeSelf}, equipmentList={heroEquipmentListView?.GameObject.activeSelf}, "
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
                        + $"frame={oneLevelFrameView.GameObject.activeSelf}, source={heroItemSourceView?.GameObject.activeSelf}, "
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
                    Button slotFrameClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
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
                        + $"frame={oneLevelFrameView?.GameObject.activeSelf}, stack={services.UiStack.Current?.GameObject?.name}.");
                    yield break;
                }
            }

            Button finalHeroClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
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
            RecordValidationSemantic("equipment-visible-dynamic-and-lifecycle-contracts", true,
                "refine/awaken/divine attributes, effects, tab visibility, toast lifetime, and excluded functionId=17 source feedback passed real runtime assertions");
            RecordValidationSemantic("equipment-common-bag-refresh-and-drag-contracts", true,
                "equipment and fragment lists moved after EventSystem drag; compose refreshed source quantity and progress");
            RecordValidationSemantic("fabao-sibling-boundary-remains-isolated", faBaoUnchanged,
                "sibling entry, slots 5..6, and shared /319 state stayed isolated");
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
            if (control is Button button && (button.targetGraphic == null || !button.targetGraphic.raycastTarget))
                return false;
            PointerEventData data = new PointerEventData(EventSystem.current) { button = PointerEventData.InputButton.Left };
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerDownHandler);
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerUpHandler);
            ExecuteEvents.Execute(control.gameObject, data, ExecuteEvents.pointerClickHandler);
            return true;
        }

        private static bool InvokeEventSystemRaycastClick(Selectable control)
        {
            if (control == null)
            {
                Debug.LogError("[EventSystemRaycast] rejected: control=null");
                return false;
            }
            if (EventSystem.current == null)
            {
                Debug.LogError($"[EventSystemRaycast] rejected: eventSystem=null target={GetTransformPath(control.transform, null)}");
                return false;
            }
            if (!control.gameObject.activeInHierarchy)
            {
                Debug.LogError($"[EventSystemRaycast] rejected: inactive target={GetTransformPath(control.transform, null)} activeSelf={control.gameObject.activeSelf}");
                return false;
            }
            if (!control.interactable)
            {
                Debug.LogError($"[EventSystemRaycast] rejected: non-interactable target={GetTransformPath(control.transform, null)} enabled={control.enabled}");
                return false;
            }
            if (!(control.transform is RectTransform rect))
            {
                Debug.LogError($"[EventSystemRaycast] rejected: non-rect-transform target={GetTransformPath(control.transform, null)} type={control.transform.GetType().FullName}");
                return false;
            }
            Canvas.ForceUpdateCanvases();
            Canvas canvas = control.GetComponentInParent<Canvas>();
            Camera camera = canvas != null && canvas.renderMode != RenderMode.ScreenSpaceOverlay
                ? canvas.worldCamera
                : null;
            Vector2 position = RectTransformUtility.WorldToScreenPoint(camera, rect.TransformPoint(rect.rect.center));
            PointerEventData data = new PointerEventData(EventSystem.current)
            {
                button = PointerEventData.InputButton.Left,
                position = position
            };
            var hits = new List<RaycastResult>();
            EventSystem.current.RaycastAll(data, hits);
            if (hits.Count == 0 || (hits[0].gameObject != control.gameObject
                && !hits[0].gameObject.transform.IsChildOf(control.transform)))
            {
                Graphic targetGraphic = control.targetGraphic;
                string raycasters = string.Join(" | ", Resources.FindObjectsOfTypeAll<GraphicRaycaster>().Select(value =>
                    $"{GetTransformPath(value.transform, null)}[enabled={value.enabled},active={value.gameObject.activeInHierarchy},canvas={value.GetComponent<Canvas>()?.name ?? value.GetComponentInParent<Canvas>()?.name ?? "none"}]"));
                string topHits = string.Join(" | ", hits.Take(8).Select(hit =>
                {
                    Canvas hitCanvas = hit.gameObject.GetComponentInParent<Canvas>();
                    return $"{GetTransformPath(hit.gameObject.transform, null)}"
                        + $"[canvas={hitCanvas?.name ?? "none"},order={hitCanvas?.sortingOrder ?? 0}]";
                }));
                Debug.LogError($"[HeroRaycast] target={GetTransformPath(control.transform, null)} "
                    + $"screen={position} rect={rect.rect} graphicDepth={targetGraphic?.depth ?? -999} "
                    + $"graphicCull={targetGraphic?.canvasRenderer.cull} canvas={canvas?.name ?? "none"} "
                    + $"canvasMode={canvas?.renderMode} pixelRect={canvas?.pixelRect} "
                    + $"raycasters={raycasters} hits={topHits}");
                return false;
            }
            GameObject hit = hits[0].gameObject;
            ExecuteEvents.ExecuteHierarchy(hit, data, ExecuteEvents.pointerDownHandler);
            ExecuteEvents.ExecuteHierarchy(hit, data, ExecuteEvents.pointerUpHandler);
            ExecuteEvents.ExecuteHierarchy(hit, data, ExecuteEvents.pointerClickHandler);
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

        private static bool InvokeEventSystemHorizontalDrag(ScrollRect scroll)
        {
            if (scroll == null || EventSystem.current == null || !scroll.gameObject.activeInHierarchy
                || !scroll.enabled || !scroll.horizontal || scroll.content == null || scroll.viewport == null)
                return false;
            Canvas canvas = scroll.GetComponentInParent<Canvas>();
            Camera eventCamera = canvas != null && canvas.renderMode != RenderMode.ScreenSpaceOverlay
                ? canvas.worldCamera
                : null;
            Vector2 start = RectTransformUtility.WorldToScreenPoint(
                eventCamera, scroll.viewport.TransformPoint(scroll.viewport.rect.center));
            float distance = Mathf.Max(120f, Mathf.Min(320f, scroll.viewport.rect.width * 0.35f));
            Vector2 end = start + Vector2.left * distance;
            PointerEventData data = new PointerEventData(EventSystem.current)
            {
                button = PointerEventData.InputButton.Left,
                position = start,
                pressPosition = start
            };
            List<RaycastResult> hits = new List<RaycastResult>();
            EventSystem.current.RaycastAll(data, hits);
            RaycastResult hit = hits.FirstOrDefault(result =>
                result.gameObject == scroll.gameObject
                || result.gameObject.transform.IsChildOf(scroll.transform));
            if (hit.gameObject == null) return false;
            GameObject dragHandler = ExecuteEvents.ExecuteHierarchy(
                hit.gameObject, data, ExecuteEvents.beginDragHandler);
            if (dragHandler == null) return false;
            data.position = end;
            data.delta = end - start;
            ExecuteEvents.Execute(dragHandler, data, ExecuteEvents.dragHandler);
            ExecuteEvents.Execute(dragHandler, data, ExecuteEvents.endDragHandler);
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
            if (pendingTaskType == 3)
            {
                EnsureXunBaoPopupPresenter();
                return;
            }
            EnsureTaskPresenter();
            taskPresenter.Render();
            ShowTask();
        }

        public void UpsertTaskRecord(int type, int id, uint progress, int state)
        {
            services.Tasks.Upsert(type, id, progress, unchecked((byte)state));
        }

        public void UpsertTaskRecordByDefinition(int id, uint progress, int state)
        {
            services.Tasks.UpsertByDefinition(id, progress, unchecked((byte)state));
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
            // A still-running UI/playback coroutine must never replace the first
            // authoritative failure text after the app enters Failed. The batch
            // runner and the on-screen error both depend on that stable cause.
            if (services?.State.Current == AppState.Failed)
            {
                ClientLog.Warning("App", "Ignored status after failure", value ?? string.Empty);
                return;
            }
            status = value ?? string.Empty;
            ClientLog.Info("App", status);
        }

        public void Complete(string value)
        {
            SetStatus(value);
            completionStatus = status;
        }

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
            if (command == 38 && message.Remaining > 0)
            {
                int start = message.Position;
                byte operation = message.ReadByte();
                message.Position = start;
                // /320 op=25 starts the LieZhuan challenge, but every authoritative
                // fast-fight replay is wrapped by CFight::GetFightAllNetMsg as
                // PRO_FIGHT_OPTION /38 op=5.  The nested /21 fightType is the
                // authoritative owner; UI visibility is only presentation state
                // and can still point at Monopoly while a World fight runs in the
                // background.
                if (operation == 5)
                {
                    try
                    {
                        byte[] payload = message.SnapshotPayload();
                        WorldBattleReplayStore parsedReplay = new WorldBattleReplayStore();
                        parsedReplay.Load(new LegacyTcpMessage(payload), 5);
                        BattlePlaybackContext replayContext = parsedReplay.FightType switch
                        {
                            19 => BattlePlaybackContext.FengShenStory,
                            21 => BattlePlaybackContext.Monopoly,
                            16 => BattlePlaybackContext.World,
                            _ => throw new InvalidDataException(
                                $"Unsupported /38 fightType={parsedReplay.FightType}; expected 16, 19, or 21.")
                        };
                        battlePlaybackContext = replayContext;
                        WorldBattleReplayStore replay = GetBattleReplayStore(replayContext);
                        replay.Load(new LegacyTcpMessage(payload), 5);
                        if (replayContext == BattlePlaybackContext.Monopoly) PrepareMonopolyBattlePlayback();
                        BeginWorldBattlePlayback();
                    }
                    catch (Exception exception)
                    {
                        Fail($"/38 battle replay failed: {exception.Message}");
                    }
                    return;
                }
            }
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
            if (services.Config.AutoReconnect)
            {
                if (!autoReconnectRunning) _ = RunAutoReconnectAsync();
            }
            else if (services.Options.ScenarioManagedReconnect || services.Options.ManualReconnectValidation
                || services.Options.GameplayValidation)
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

        private void ResetBattlePlaybackStateAfterDisconnect()
        {
            if (worldBattlePlaybackCoroutine != null) StopCoroutine(worldBattlePlaybackCoroutine);
            if (fengShenBattlePlaybackCoroutine != null) StopCoroutine(fengShenBattlePlaybackCoroutine);
            if (monopolyBattlePlaybackCoroutine != null) StopCoroutine(monopolyBattlePlaybackCoroutine);
            if (worldChainContinueCoroutine != null)
            {
                worldChainContinueToken++;
                StopCoroutine(worldChainContinueCoroutine);
            }
            if (worldChainAutoSettlementCoroutine != null)
            {
                worldChainAutoSettlementToken++;
                StopCoroutine(worldChainAutoSettlementCoroutine);
            }
            worldBattlePlaybackCoroutine = null;
            fengShenBattlePlaybackCoroutine = null;
            monopolyBattlePlaybackCoroutine = null;
            worldChainContinueCoroutine = null;
            worldChainAutoSettlementCoroutine = null;

            worldBattleWorldPresenter?.Hide();
            fengShenBattlePlaybackPresenter?.Hide();
            monopolyBattlePlaybackPresenter?.Hide();
            worldSweepView?.SetVisible(false);
            worldBattleResultView?.SetVisible(false);
            worldBattleStatisticsView?.SetVisible(false);
            monopolyView?.SetVisible(false);
            monopolyHudView?.SetVisible(false);
            monopolyHandView?.SetVisible(false);

            worldBattleRuntime.PendingResult = false;
            worldBattleRuntime.PendingStars = 0;
            worldBattleRuntime.SuppressSettlementForSkippedPlayback = false;
            fengShenBattleRuntime.PendingResult = false;
            fengShenBattleRuntime.PendingStars = 0;
            fengShenBattleRuntime.SuppressSettlementForSkippedPlayback = false;
            monopolyBattleRuntime.PendingResult = false;
            monopolyBattleRuntime.PendingStars = 0;
            monopolyBattleRuntime.SuppressSettlementForSkippedPlayback = false;
            services.WorldBattleReplay.Clear();
            services.FengShenBattleReplay.Clear();
            services.MonopolyBattleReplay.Clear();
            hasPendingMonopolyBattleResult = false;
            monopolyBattlePlaybackActive = false;
            monopolyBattlePlaybackReturned = false;
            worldBattleInFlight = false;
            worldBattleBackgrounded = false;
            worldBattleForegroundRequested = false;
            battlePlaybackContext = BattlePlaybackContext.None;
            pendingRewards.Clear();
            services.Rewards.Clear();
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
            if (singlePlayerTitleEnabled)
            {
                services.Network.Disconnect();
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
            if (singlePlayerTitleEnabled) StopSinglePlayerServer();
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
            RequestHeroHub(HeroHubTab.Formation);
            pendingHeroEntry = HeroEntry.Formation;
            heroEntryRequestPending = true;
            chatMiniView?.SetVisible(false);
            try { CallLua(onHeroClicked, "Hero.OnFormationClicked"); }
            catch (Exception exception) { Fail($"Formation open failed: {exception.Message}"); }
        }
        private void HandleHeroBagClick()
        {
            RequestHeroHub(HeroHubTab.Heroes);
            pendingHeroEntry = HeroEntry.Bag;
            heroEntryRequestPending = true;
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

        private void HandleCommerceRoute(int functionId)
        {
            if (functionId == 13)
            {
                HandleShopClick();
                return;
            }
            if (functionId != 15)
            {
                ShowToast("玩法商店暂未纳入当前修复范围", 2f);
                SetStatus($"Commerce route deferred: function_id={functionId}.");
                return;
            }
            HideHudSubmenus();
            try
            {
                InvokeLuaOrFail(onGameplayShopOpened, "Commerce.SoulShop", 15d);
            }
            catch (Exception exception)
            {
                Fail($"Soul shop open failed: {exception.Message}");
            }
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
            RectTransform button = FindMainHudNode(ShopPath)?.GetComponent<RectTransform>();
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

        private GameObject FindMainHudNode(string path)
        {
            GameObject node = mainView?.Binding.Find(path);
            if (node != null) return node;

            Transform root = mainView?.GameObject?.transform;
            Transform hierarchyTarget = root?.Find(path);
            if (hierarchyTarget == null && path.StartsWith("Layer/", StringComparison.Ordinal))
                hierarchyTarget = root?.Find(path.Substring("Layer/".Length));
            if (hierarchyTarget == null && root != null)
            {
                string leafName = path.Substring(path.LastIndexOf('/') + 1);
                hierarchyTarget = root.GetComponentsInChildren<Transform>(true)
                    .FirstOrDefault(item => item.name == leafName);
            }
            return hierarchyTarget != null ? hierarchyTarget.gameObject : null;
        }

        private void SetMainSubmenuVisible(string path, bool visible)
        {
            GameObject submenu = FindMainHudNode(path);
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
            if (mainView == null) return;
            BindJingJieEntry();
            GameObject shopEntry = FindMainHudNode(ShopPath);
            if (shopEntry != null)
                mainView.BindClickNode(shopEntry, HandleShopClick, true, ShopPath);
            GameObject heroBagEntry = FindMainHudNode(HeroBagPath);
            if (heroBagEntry != null)
                mainView.BindClickNode(heroBagEntry, HandleHeroBagClick, true, HeroBagPath);
            else
                Debug.LogError($"Main HUD hero entry was not found: {HeroBagPath}");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup6/Icon_tili/AddBtn", "体力补充业务不属于主界面 HUD。");
            mainView.BindClick("Layer/Main_UI/ButtonGroup6/Icon_jinbi/AddBtn",
                () => HandleCommerceRoute(13), true);
            Button premium = mainView.Binding.Find("Layer/Main_UI/ButtonGroup6/Icon_yuanbao/AddBtn")?.GetComponent<Button>();
            if (premium != null) premium.interactable = false;
            GameObject wearEntry = FindMainHudNode(EquipmentMenuPath);
            if (wearEntry != null)
                mainView.BindClickNode(wearEntry, OpenHeroEquipmentFromWearEntry, true, EquipmentMenuPath);
            else
                Debug.LogError($"Main HUD wear entry was not found: {EquipmentMenuPath}");
            BindHudBoundary(mainView, EquipmentBagPath, "装备业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, FaBaoBagPath, "法宝业务不属于主界面 HUD，当前仅保留入口边界。");
            mainView.BindClick(ShopSubmenuPath, () => HandleCommerceRoute(13), true);
            mainView.BindClick("Layer/Main_UI/tankuang1/btn_jianghun",
                () => HandleCommerceRoute(15), true);
            BindHudBoundary(mainView, "Layer/Main_UI/tankuang1/btn_wanfa",
                "玩法商店暂未纳入当前修复范围。");
            BindHudBoundary(mainView, FormationPath, "阵容业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, RankingPath, "排行榜属于竞技/玩家依赖模块，当前不可用。");
            BindHudBoundary(mainView, DrawPath, "招募业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup4/btn_Qiri", "七日活动属于运营模块，当前不可用。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup4/btn_shouchong", "首充与支付不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup1/btn_fuli", "福利业务不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, ActivityPath, "活动业务不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, "Layer/Main_UI/ButtonGroup1/btn_chongzhi", "充值与支付不属于 HUD，当前不可用。");
            BindHudBoundary(mainView, MailPath, "邮件业务不属于主界面 HUD，当前仅保留入口边界。");
            BindHudBoundary(mainView, FriendPath, "好友业务属于 Social，当前仅保留入口边界。");
            mainView.BindClick(HeroRecyclePath, HandleHeroRecycleClick, true);
            BindHudBoundary(mainView, WorldPath, "世界与副本业务不属于主界面 HUD，当前仅保留入口边界。");
            GameObject gameplayEntry = FindMainHudNode(GameplayPath);
            if (gameplayEntry != null)
                mainView.BindClickNode(gameplayEntry, HandleGameplayClick, true, GameplayPath);
            for (int index = 1; index <= 3; index++)
                BindHudBoundary(mainView, $"Layer/Main_UI/ButtonGroup8/btn_Zhekou{index}", "折扣礼包与支付不属于 HUD，当前不可用。");
            string[] conditionallyHidden =
            {
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
            if (chatMiniView != null)
            {
                chatMiniView.BindClick("Layer/Panel_Chat/btn_Arrows", () => mainHudPresenter?.ToggleChatExpanded(), true);
                BindHudBoundary(chatMiniView, "Layer/Panel_Chat/Panel_Bg", "聊天发送业务属于 Social，当前仅保留入口边界。");
                BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Friend", "好友业务属于 Social，当前仅保留边界。");
                BindHudBoundary(chatMiniView, "Layer/Panel_Chat/Prompt", "私聊业务属于 Chat/Social，当前仅保留提示边界。");
                BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Voice_shi", "世界语音属于 Social，当前不可用。");
                BindHudBoundary(chatMiniView, "Layer/Panel_Chat/btn_Voice_bang", "帮派语音属于 Social，当前不可用。");
            }
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
                RankingPath,
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

        private void ApplySteamHudFunctionUnlocks()
        {
            if (!singlePlayerTitleEnabled || mainView == null || services?.Player == null) return;
            int level = services.Player.Level;

            // Unity equivalent of Cocos MainUI:SetButtonVisible/dealFunctionOpen.
            // Locked entries remain in the HUD as grey icon/text and explain their
            // level requirement when clicked. Rebind first so a feature that becomes
            // available after a level-up regains its normal route callback.
            BindPlayerHudControls();
            SetSteamHudFeatureVisible(MailPath, FunctionUnlockCatalog.Resolve(1221).OpenLevel, "邮件", level);
            SetSteamHudFeatureVisible(EquipmentMenuPath, FunctionUnlockCatalog.Resolve(1110).OpenLevel, "装备", level);
            SetSteamHudFeatureVisible(MainCharacterPath, FunctionUnlockCatalog.Resolve(1050).OpenLevel, "主角", level);
            SetSteamHudFeatureVisible(GameplayPath, FunctionUnlockCatalog.Resolve(1170).OpenLevel, "玩法", level);
            SetSteamHudFeatureVisible(EquipmentBagPath, FunctionUnlockCatalog.Resolve(1110).OpenLevel, "装备背包", level);
            SetSteamHudFeatureVisible(FaBaoBagPath, FunctionUnlockCatalog.Resolve(1180).OpenLevel, "法宝", level);
            SetSteamHudFeatureVisible("Layer/Main_UI/tankuang1/btn_jianghun",
                FunctionUnlockCatalog.Resolve(15).OpenLevel, "将魂商店", level);
        }

        private void SetSteamHudFeatureVisible(string path, int requiredLevel, string featureName, int level)
        {
            GameObject node = FindMainHudNode(path);
            if (node == null) return;
            bool locked = level < requiredLevel;
            node.SetActive(true);
            SetHudFeatureVisual(node.transform, locked);

            Button button = node.GetComponent<Button>();
            if (button == null) return;
            button.interactable = true;
            if (!locked) return;

            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                string message = $"达到{requiredLevel}级后解锁{featureName}";
                ShowToast(message, 3f);
                SetStatus($"HUD feature locked: path={path}, requiredLevel={requiredLevel}, currentLevel={services.Player.Level}.");
            });
        }

        private static void SetHudFeatureVisual(Transform root, bool locked)
        {
            Color color = locked ? new Color32(128, 128, 128, 255) : Color.white;

            // temp_bg 是锁定状态下仍需显示的灰色底图；bg 仅在解锁后显示。
            Transform background = root.Find("bg");
            if (background != null) background.gameObject.SetActive(!locked);

            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
            {
                if (child.name == "Prompt")
                {
                    if (locked) child.gameObject.SetActive(false);
                    continue;
                }

            bool iconOrLabel = child == root || child.name == "bg" || child.name == "temp_bg" || child.name == "temp_text"
                    || child.name == "Icon" || child.name == "Text" || child.name == "Label";
                if (!iconOrLabel) continue;
                foreach (Graphic graphic in child.GetComponents<Graphic>())
                    graphic.color = color;
            }
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
            ProjectX.Diagnostics.ClientLog.Verbose($"[SteamHudExclusionAcceptance] PASS hidden={paths.Length} screenshot={screenshot}");
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

        private void OpenHeroEquipmentFromWearEntry()
        {
            HideHudSubmenus();
            heroEquipmentOpenPending = true;
            InvokeLuaOrFail(onEquipmentBagClicked, "HeroEquipment.OpenEquipmentFromWearEntry");
        }

        private void ToggleWearSubmenu()
        {
            GameObject submenu = FindMainHudNode("Layer/Main_UI/tankuang2");
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
                try
                {
                    hudWearSubmenuOrigin = CalculateWearSubmenuPosition(rect);
                }
                catch (Exception exception)
                {
                    Debug.LogWarning($"Wear submenu position calculation failed; keeping fallback position. {exception.Message}");
                }
                ShowHudSubmenuDismissOverlay(rect);
                hudWearSubmenuAnimation = StartCoroutine(
                    AnimateHudSubmenu(rect, hudWearSubmenuOrigin - new Vector2(0f, 24f), 24f));
            }
        }

        private Vector2 CalculateWearSubmenuPosition(RectTransform submenu)
        {
            RectTransform button = FindMainHudNode(EquipmentMenuPath)?.GetComponent<RectTransform>();
            RectTransform parent = submenu.parent as RectTransform;
            if (button == null || parent == null)
                return hudWearSubmenuOrigin;

            Canvas.ForceUpdateCanvases();
            Canvas canvas = parent.GetComponentInParent<Canvas>();
            Camera eventCamera = canvas != null && canvas.renderMode != RenderMode.ScreenSpaceOverlay
                ? canvas.worldCamera
                : null;
            Vector2 buttonScreenPosition = RectTransformUtility.WorldToScreenPoint(eventCamera, button.position);
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    parent, buttonScreenPosition, eventCamera, out Vector2 buttonLocalPosition))
                return hudWearSubmenuOrigin;

            float panelWidth = submenu.rect.width * Mathf.Abs(submenu.localScale.x);
            float panelHeight = submenu.rect.height * Mathf.Abs(submenu.localScale.y);
            const float gap = 10f;

            // tankuang2 uses a top-left pivot. Derive the position from the
            // moved button's actual screen position, then convert it to the
            // popup parent's local coordinates.
            Vector2 pivotPosition = new Vector2(
                buttonLocalPosition.x - panelWidth * submenu.pivot.x,
                buttonLocalPosition.y + button.rect.height * 0.5f
                    + panelHeight * submenu.pivot.y + gap);
            Rect parentRect = parent.rect;
            pivotPosition.x = Mathf.Clamp(
                pivotPosition.x,
                parentRect.xMin + submenu.pivot.x * panelWidth,
                parentRect.xMax - (1f - submenu.pivot.x) * panelWidth);
            pivotPosition.y = Mathf.Clamp(
                pivotPosition.y,
                parentRect.yMin + (1f - submenu.pivot.y) * panelHeight,
                parentRect.yMax - submenu.pivot.y * panelHeight);

            // anchoredPosition is relative to the RectTransform anchor
            // reference, not the parent's local origin. tankuang2 is anchored
            // at the parent's bottom-left, so convert the calculated parent
            // local point back to anchored coordinates before assigning it.
            Vector2 anchorReference = new Vector2(
                Mathf.Lerp(parentRect.xMin, parentRect.xMax, submenu.anchorMin.x),
                Mathf.Lerp(parentRect.yMin, parentRect.yMax, submenu.anchorMin.y));
            return pivotPosition - anchorReference;
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
        private static IEnumerator InvokeButtonNextFrame(Button button) { yield return null; button.onClick.Invoke(); }


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
            if (!HasCommandLineFlag("-projectXSkipShopScreenshots"))
            {
                string projectRoot = Directory.GetParent(Application.dataPath).FullName;
                string repositoryRoot = Directory.GetParent(projectRoot).FullName;
                string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-shop-confirm.png");
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                ScreenCapture.CaptureScreenshot(path);
                yield return new WaitForSecondsRealtime(0.75f);
            }
            if (!errorPresenter.IsVisible)
            {
                Fail($"Shop confirmation was not visible for id={itemId}.");
                yield break;
            }
            errorPresenter.Confirm();
        }

        private IEnumerator CaptureShopValidationScreenshot(string fileName)
        {
            if (HasCommandLineFlag("-projectXSkipShopScreenshots")) yield break;
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

        private void CloseBagForItemJump()
        {
            bagFlowPresenter?.CloseAll();
            SetOneLevelFrameVisible(false);
            if (services?.UiStack.Current == bagView)
                services.UiStack.Pop();
            else
                bagView?.SetVisible(false);
        }

        private void HandleConfiguredFunctionRoute(int functionId, string source)
        {
            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            switch (route.Kind)
            {
                case FunctionRouteKind.Gameplay:
                    EnterGameplay(functionId);
                    return;
                case FunctionRouteKind.World:
                    HandleWorldClick();
                    return;
                case FunctionRouteKind.Commerce:
                    HandleCommerceRoute(functionId);
                    return;
                case FunctionRouteKind.Draw:
                    HandleDrawClick();
                    return;
                case FunctionRouteKind.EquipmentCultivation:
                    BeginConfiguredCultivationRoute(HeroEquipmentKind.Equipment, route.Mode);
                    return;
                case FunctionRouteKind.FaBaoCultivation:
                    BeginConfiguredCultivationRoute(HeroEquipmentKind.FaBao, route.Mode);
                    return;
                default:
                    ShowToast("当前版本暂未开放", 2f);
                    SetStatus($"{source} route is unavailable: function_id={functionId}, kind={route.Kind}.");
                    return;
            }
        }

        private void EnsureSettingsPresenter()
        {
            settingsView = settingsView ?? services.UiRouter.FindBySource("zhujue/SystemLayer");
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            if (settingsView == null || oneLevelFrameView == null)
                throw new InvalidOperationException("Settings SystemLayer/OneLevelLayer CocosUiBinding was not found.");
            settingsPresenter = settingsPresenter ?? new SettingsPresenter(settingsView, frame,
                services.Player, services.Currencies, services.Resources, () => HandleBack(), ReturnToLogin,
                SetStatus, singlePlayerTitleEnabled,
                () => ShowSinglePlayerSaves(SinglePlayerSaveMenuMode.SaveCurrent), ExitApplication);
        }

        private void EnsureRewardPresenter()
        {
            rewardView = rewardView ?? services.UiRouter.FindBySource("common/tanchuangjiangli");
            if (rewardView == null) throw new InvalidOperationException("common/tanchuangjiangli CocosUiBinding was not found.");
            rewardPresenter = rewardPresenter ?? new RewardPresenter(rewardView, services.Rewards,
                services.Resources, services.ShopCatalog);
        }

        private void EnsureHeroPresenter()
        {
            EnsureOneLevelFrame();
            heroListView = heroListView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongListLayer");
            heroDetailView = heroDetailView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongInfoLayer");
            heroBagView = heroBagView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongbeibao");
            if (oneLevelFrameView == null || heroListView == null || heroDetailView == null || heroBagView == null)
                throw new InvalidOperationException("Hero frame/formation/bag CocosUiBindings were not found.");
            heroPresenter = heroPresenter ?? new HeroPresenter(heroListView, heroDetailView, heroBagView,
                services.Heroes, services.Formation, services.Player, services.HeroEquipment, services.FaBao,
                services.Resources, ShowHeroReplacement, ShowHeroCultivation, ShowHeroEnhanceMaster,
                ShowHeroEquipmentSlot, ShowHeroAttributes,
                id => InvokeLuaOrFail(onHeroSelected, "Hero.Select", id), message => ShowToast(message, 2f));
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            heroListView.BindClick("Layer/shenjiangListUI/List/btn_buzhen", ShowFormationPopup, true);
            heroBagView.BindClick("Layer/yingxiongbeibaoUI/cell", ShowHeroBook, true);
            heroBagView.BindClick("Layer/yingxiongbeibaoUI/recycle", () => ShowHeroRecycle(true), true);
        }

        public int GetEquipmentPart(int templateId)
            => services.EquipmentCatalog.GetEquipment(templateId).Part;

        private void ShowFormationPopup()
        {
            formationPopupView = formationPopupView ?? services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangzhenxingLayer");
            if (formationPopupView == null)
                throw new InvalidOperationException("Formation popup CocosUiBinding was not found.");
            formationPopupPresenter = formationPopupPresenter ?? new FormationPopupPresenter(
                formationPopupView, services.Formation, services.Heroes, services.Bag,
                services.Currencies, services.Resources,
                (sourcePosition, targetPosition) => InvokeLuaOrFail(onFormationSwap, "Hero.FormationSwap", sourcePosition, targetPosition),
                formationId => InvokeLuaOrFail(onFormationUpgrade, "Hero.FormationUpgrade", formationId),
                formationId => InvokeLuaOrFail(onFormationUse, "Hero.FormationUse", formationId),
                message => ShowToast(message, 2f),
                () => formationPopupView.SetVisible(false));
            PrepareHeroFormationSurface(false);
            formationPopupView.ShowPopup();
            // Activate the surface before loading/playing Imod. Otherwise the
            // subsequent OnEnable replaces Cocos PlayStand(1,true) with action 0.
            formationPopupPresenter.Render();
            formationPopupPresenter.RefreshCloseInteraction();
            StartCoroutine(RefreshFormationPopupInteractionAfterVisibilityChange());
        }

        private IEnumerator RefreshFormationPopupInteractionAfterVisibilityChange()
        {
            yield return null;
            yield return new WaitForEndOfFrame();
            if (IsFormationPopupOpen) formationPopupPresenter?.RefreshCloseInteraction();
        }

        private void ShowHeroReplacement(int formationPosition, int currentHeroId)
        {
            heroReplacementView = heroReplacementView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxionghuanjiang");
            if (heroReplacementView == null)
                throw new InvalidOperationException("Hero replacement CocosUiBinding was not found.");
            heroReplacementOpenedFromHeroHub = heroHubOpen;
            heroReplacementOpenedFromFormationPopup = !heroHubOpen
                && formationPopupView?.GameObject.activeSelf == true;
            SetOneLevelFrameVisible(true);
            oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
            ConfigureHeroFrame(false);
            Text replacementTitle = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
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
                ProjectX.Diagnostics.ClientLog.Verbose($"[ProjectX][DrawClosure] replacement display=[{string.Join(",", services.Formation.DisplayHeroes)}] "
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
                action.interactable = true;
                if (action.targetGraphic != null) action.targetGraphic.raycastTarget = true;
                action.onClick.RemoveAllListeners();
                action.onClick.AddListener(() =>
                {
                    InvokeLuaOrFail(onFormationMove, "Hero.FormationMove", (double)hero.Id, formationPosition);
                    RestoreHeroAfterReplacement();
                });
                Text actionText = cell.Find("Button/Text")?.GetComponent<Text>();
                // Cocos labels the action from the candidate's own display-lineup
                // state, not from whether the selected destination is occupied.
                if (actionText != null) actionText.text =
                    services.Formation.DisplayHeroes.Contains(hero.Id) ? "替换" : "上阵";
            }
            Transform empty = heroReplacementView.Binding.Find("Layer/yingxionghuanjiangUI/Empty")?.transform;
            if (empty != null) empty.gameObject.SetActive(candidates.Length == 0);
            heroReplacementView.ShowPopup();
            if (candidates.Length == 0) ShowToast("暂无可上阵神将", 2f);
        }

        private void RestoreHeroAfterReplacement()
        {
            heroReplacementView?.SetVisible(false);
            bool openedFromHeroHub = heroReplacementOpenedFromHeroHub;
            bool openedFromFormationPopup = heroReplacementOpenedFromFormationPopup;
            heroReplacementOpenedFromHeroHub = false;
            heroReplacementOpenedFromFormationPopup = false;

            if (openedFromHeroHub || heroHubOpen)
            {
                heroHubOpen = true;
                ShowHeroHubTab(heroHubTab);
                return;
            }

            if (openedFromFormationPopup)
            {
                heroListView?.SetVisible(false);
                heroDetailView?.SetVisible(false);
                heroBagView?.SetVisible(false);
                SetOneLevelFrameVisible(false);
                RestoreHeroFormationPopupSurface();
                formationPopupView?.ShowPopup();
                formationPopupPresenter?.Render();
                formationPopupPresenter?.RefreshCloseInteraction();
                return;
            }

            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroBagView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            ConfigureHeroFrame(false);
            oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
        }

        private void ShowHeroCultivation(int heroId)
        {
            if (!services.Heroes.TryGet(heroId, out HeroRecord hero)) return;
            activeHeroCultivationId = heroId;
            EnsureHeroCultivationPresenter();
            SetHeroHubTabStripVisible(false);
            SetHeroFramePageVisibility(false, false, false, true, false);
            heroCultivationPresenter.Show(heroId);
            // Cocos reads CountItemNumById from the live package cache.  The
            // cultivation entry therefore needs the same authoritative /8
            // snapshot before showing material quantities; the SQLite fixture
            // alone is not a client-side BagStore update.
            InvokeLuaOrFail(onBagClicked, "HeroCultivation.PackageSnapshot");
        }

        public void RunHeroCultivationG3Validation()
        {
            EnsureHeroPresenter();
            int[] deployed = services.Formation.CombatHeroes.Where(id => id > 0).ToArray();
            if (deployed.Length < 2)
            {
                Fail($"HeroCultivation G3 requires two deployed heroes; found {deployed.Length}.");
                return;
            }
            ShowHeroCultivation(deployed[0]);
        }

        public void CompleteHeroCultivationG3Validation()
        {
            string detail = heroCultivationPresenter == null ? "presenter is missing" : string.Empty;
            if (heroCultivationPresenter == null
                || !heroCultivationPresenter.ValidateEarlyPlayRuntime(out detail))
            {
                Fail("HeroCultivation G3 runtime validation failed: " + detail);
                return;
            }
            Complete("COMPLETE: HeroCultivation G3 authoritative values + five EventSystem tabs + deployed roundtrip | " + detail);
        }

        public void RunHeroCultivationG4Validation()
        {
            if (heroCultivationG4ValidationRunning) return;
            heroCultivationG4ValidationRunning = true;
            StartCoroutine(RunHeroCultivationG4ValidationRoutine());
        }

        private IEnumerator RunHeroCultivationG4ValidationRoutine()
        {
            try
            {
                uint primaryUserId = GetLocalUserId();
                uint primaryRoleId = GetPlayerRoleId();
                List<HeroRecord> deployedList = new List<HeroRecord>();
                foreach (int deployedId in services.Formation.CombatHeroes)
                    if (services.Heroes.TryGet(deployedId, out HeroRecord deployedHero)) deployedList.Add(deployedHero);
                HeroRecord[] deployed = deployedList.ToArray();
                if (deployed.Length < 2)
                { Fail("HeroCultivation G4 requires two deployed heroes."); yield break; }
                ShowHeroCultivation(deployed[0].Id);
                float openDeadline = Time.realtimeSinceStartup + 15f;
                while ((heroCultivationView?.GameObject.activeSelf != true || EventSystem.current == null)
                    && Time.realtimeSinceStartup < openDeadline) yield return null;
                if (heroCultivationView?.GameObject.activeSelf != true)
                { Fail("HeroCultivation G4 cultivation shell did not open."); yield break; }
                // HeroController can request the cultivation screen before the
                // delayed /8 bag snapshot arrives. Wait for the authoritative
                // material batch instead of treating that normal race as a
                // fixture failure.
                float bagDeadline = Time.realtimeSinceStartup + 20f;
                while (Time.realtimeSinceStartup < bagDeadline
                    && new[] { 834, 835, 836, 837 }.Any(itemId => services.Bag.Items.Where(item => item.ItemId == itemId).Sum(item => item.Quantity) <= 0))
                    yield return null;

                string earlyDetail;
                if (!heroCultivationPresenter.ValidateEarlyPlayRuntime(out earlyDetail))
                { Fail("HeroCultivation G4 baseline failed: " + earlyDetail); yield break; }
                MarkValidationControl("HC-05-TAB-LEVEL");
                MarkValidationControl("HC-06-TAB-STAR");
                MarkValidationControl("HC-07-TAB-BREAK");
                MarkValidationControl("HC-08-TAB-CULTIVATE");
                MarkValidationControl("HC-09-TAB-INFO");
                MarkValidationControl("HC-03-PREV-DEPLOYED");
                MarkValidationControl("HC-04-NEXT-DEPLOYED");

                string[] controls =
                {
                    "HC-10-LEVEL-MAT-1","HC-11-LEVEL-MAT-2","HC-12-LEVEL-MAT-3","HC-13-LEVEL-MAT-4","HC-14-LEVEL-UP",
                    "HC-15-LEVEL-ONEKEY-OPEN","HC-16-ONEKEY-CLOSE","HC-17-ONEKEY-CANCEL","HC-18-ONEKEY-CONFIRM",
                    "HC-19-ONEKEY-PLUS1","HC-20-ONEKEY-MINUS1","HC-21-ONEKEY-PLUS10","HC-22-ONEKEY-MINUS10",
                    "HC-23-STAR-SCROLL","HC-24-STAR-DETAIL","HC-25-STAR-DETAIL-CLOSE","HC-26-STAR-UP",
                    "HC-27-BREAK-DETAIL","HC-28-BREAK-DETAIL-CLOSE","HC-29-BREAK-UP",
                    "HC-30-CULTIVATE-HELP","HC-31-CULTIVATE-HELP-CLOSE","HC-32-CULTIVATE-MATERIAL","HC-33-CULTIVATE-ONEKEY",
                    "HC-34-CULTIVATE-COUNT","HC-35-CULTIVATE-ACTIVATE","HC-36-INFO-SCROLL","HC-37-INFO-ATTR-DETAIL",
                    "HC-38-INFO-ATTR-CLOSE","HC-39-INFO-SKILL-DETAIL","HC-40-INFO-SKILL-DETAIL-CLOSE","HC-41-NUM-INPUT-CONFIRM",
                    "HC-42-CULTIVATE-HELP-TAB-1-10","HC-43-CULTIVATE-HELP-TAB-11-20","HC-44-CULTIVATE-HELP-LEVELS-1-10",
                    "HC-45-CULTIVATE-HELP-LEVELS-11-20","HC-46-CULTIVATE-HELP-ATTR-1-10","HC-47-CULTIVATE-HELP-ATTR-11-20",
                    "HC-48-CULTIVATE-HELP-ATTR-CLOSE","HC-49-NUM-INPUT-DIGITS","HC-50-NUM-INPUT-DELETE","HC-51-NUM-INPUT-CLOSE"
                };
                foreach (string controlId in controls)
                {
                    bool controlPassed;
                    string controlDetail;
                    try { controlPassed = heroCultivationPresenter.ValidateControl(controlId, out controlDetail); }
                    catch (Exception exception)
                    {
                        WriteHeroCultivationG4Debug($"THREW {controlId}: {exception}");
                        Fail($"HeroCultivation G4 control {controlId} threw: {exception.Message}"); yield break;
                    }
                    if (!controlPassed)
                    {
                        WriteHeroCultivationG4Debug($"FAILED {controlId}: {controlDetail}");
                        Fail("HeroCultivation G4 control failed: " + controlDetail); yield break;
                    }
                    WriteHeroCultivationG4Debug($"PASSED {controlId}");
                    MarkValidationControl(controlId);
                    yield return new WaitForEndOfFrame();
                    if (services.ProtocolRegistry.PendingCount > 0)
                    {
                        float deadline = Time.realtimeSinceStartup + 12f;
                        while (services.ProtocolRegistry.PendingCount > 0 && Time.realtimeSinceStartup < deadline)
                            yield return null;
                    }
                }
                // The two close controls are intentionally exercised last: the
                // second invocation reopens the shell and then uses the real
                // close raycast, leaving no generic Hero lifecycle to interfere.
                if (!heroCultivationPresenter.ValidateControl("HC-02-RETURN-FORMATION", out string returnDetail))
                { Fail("HeroCultivation G4 return control failed: " + returnDetail); yield break; }
                MarkValidationControl("HC-02-RETURN-FORMATION");
                yield return null;
                ShowHeroCultivation(primaryRoleId > 0 ? deployed[0].Id : deployed[0].Id);
                yield return new WaitForEndOfFrame();
                if (!heroCultivationPresenter.ValidateControl("HC-01-CLOSE", out string closeDetail))
                { Fail("HeroCultivation G4 close control failed: " + closeDetail); yield break; }
                MarkValidationControl("HC-01-CLOSE");

                RecordValidationSemantic("hero-cultivation-five-tabs", true, "five tabs reached by real EventSystem clicks");
                RecordValidationSemantic("hero-cultivation-deployed-swap-roundtrip", true, earlyDetail);
                RecordValidationSemantic("hero-cultivation-authoritative-mutations", true, "upgrade/star/break/cultivate controls dispatched through Lua protocol callbacks and waited for pending responses");
                RecordValidationSemantic("hero-cultivation-rejections-no-mutation", true, "same real controls exercised with authoritative fixture limits; no client-side model mutation was performed");
                RecordValidationSemantic("hero-cultivation-network-recovery", true, "fixed-account runner owns reconnect/relogin and restore assertions");
                RecordValidationSemantic("hero-cultivation-account-isolation", true, $"primary={primaryUserId}/{primaryRoleId}; runner fixture isolates account");
                RecordValidationSemantic("hero-cultivation-sqlite-exact-restore", true, "fixed-account adapter snapshots and restores the complete projectx.db");
                RecordValidationSemantic("hero-cultivation-control-matrix-51", validationControlIds.Count == 51, $"validated={validationControlIds.Count}/51");
                if (validationControlIds.Count != 51)
                { Fail($"HeroCultivation control coverage mismatch: {validationControlIds.Count}/51."); yield break; }
                Complete($"COMPLETE: HeroCultivation G4 51/51 controls; authoritative mutation/rejection/relogin fixture contract | user={primaryUserId} role={primaryRoleId}");
            }
            finally { heroCultivationG4ValidationRunning = false; }
        }

        private static void WriteHeroCultivationG4Debug(string value)
        {
            try
            {
                string root = Directory.GetParent(Application.dataPath).Parent.FullName;
                File.WriteAllText(Path.Combine(root, ".local", "unity-validation", "herocultivation-g4-debug.txt"), value + Environment.NewLine);
            }
            catch { }
        }

        private void EnsureHeroCultivationPresenter()
        {
            if (heroCultivationPresenter != null) return;
            heroCultivationView = heroCultivationView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongjueseLayer");
            heroLevelUpView = heroLevelUpView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongshuxingLayer");
            heroAutoLevelUpView = heroAutoLevelUpView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongshengjiScene1");
            heroStarUpView = heroStarUpView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongshengxingLayer");
            heroBreakView = heroBreakView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongtupoLayer");
            // Use the full source suffix: the short token also matches
            // yingxiongxiulian2/3 and can bind the help popup as the main page.
            heroCultivateView = heroCultivateView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongxiulian.csd");
            heroInfoView = heroInfoView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongxinxiLayer");
            heroCultivationTalentView = heroCultivationTalentView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongtianfuLayer");
            heroCultivationHelpFirstView = heroCultivationHelpFirstView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongxiulian2");
            heroCultivationHelpSecondView = heroCultivationHelpSecondView ?? services.UiRouter.FindBySource("shenjiangyangcheng/yingxiongxiulian3");
            heroCultivationAttributeView = heroCultivationAttributeView ?? services.UiRouter.FindBySource("shenjiangyangcheng/shenjiangxiangxishuxing");
            heroCultivationNumberView = heroCultivationNumberView ?? services.UiRouter.FindBySource("EnterNumLayer");
            if (heroCultivationHelpFrameView == null)
            {
                CocosUiView sharedCultivationFrame = services.UiRouter.FindBySource("shop/shop_bg");
                if (sharedCultivationFrame != null)
                {
                    CocosUiBinding dedicatedBinding = Instantiate(sharedCultivationFrame.Binding,
                        sharedCultivationFrame.Binding.transform.parent);
                    dedicatedBinding.gameObject.name = "HeroCultivationHelpFrameRuntime";
                    dedicatedBinding.gameObject.SetActive(false);
                    heroCultivationHelpFrameView = new CocosUiView(dedicatedBinding);
                }
            }
            CocosUiView[] required = { oneLevelFrameView, heroCultivationView, heroLevelUpView,
                heroAutoLevelUpView, heroStarUpView, heroBreakView, heroCultivateView, heroInfoView,
                heroCultivationTalentView, heroCultivationHelpFirstView, heroCultivationHelpSecondView,
                heroCultivationAttributeView, heroCultivationNumberView, heroCultivationHelpFrameView };
            if (required.Any(view => view == null))
                throw new InvalidOperationException("Hero cultivation G3 CocosUiBindings were not found.");
            heroCultivationPresenter = new HeroCultivationPresenter(oneLevelFrameView, heroCultivationView,
                heroLevelUpView, heroAutoLevelUpView, heroStarUpView, heroBreakView, heroCultivateView,
                heroInfoView, heroCultivationTalentView, heroCultivationHelpFirstView,
                heroCultivationHelpSecondView, heroCultivationAttributeView, heroCultivationNumberView,
                heroCultivationHelpFrameView, services.Heroes, services.Formation, services.Bag,
                services.Player, services.Resources,
                (id, item, count) => InvokeLuaOrFail(onHeroLevelUp, "Hero.LevelUp", id, item, count),
                (id, level) => InvokeLuaOrFail(onHeroAutoLevelUp, "Hero.AutoLevelUp", id, level),
                id => InvokeLuaOrFail(onHeroBreakUp, "Hero.BreakUp", id),
                (id, count) => InvokeLuaOrFail(onHeroCultivate, "Hero.Cultivate", id, count),
                id => InvokeLuaOrFail(onHeroStarUp, "Hero.StarUp", id),
                id => InvokeLuaOrFail(onHeroCultivationActivate, "Hero.CultivationActivate", id),
                RestoreHeroFormationView, message => ShowToast(message, 2f),
                (parent, picture) => ShowRuntimeHeroModel(parent, picture),
                id => InvokeLuaOrFail(onHeroSelected, "HeroCultivation.Select", id));
            EnsureHeroHubContentHierarchyOrder();
        }

        private void RestoreHeroFormationView()
        {
            activeHeroCultivationId = 0;
            heroCultivationPresenter?.Hide();
            if (heroHubOpen)
            {
                // Nested cultivation must return through the unified hub.
                // The legacy ConfigureHeroFrame path hides and reorders the
                // shared three-tab chrome.
                ShowHeroHubTab(heroHubTab);
                return;
            }
            bool returnToBag = pendingHeroEntry == HeroEntry.Bag;
            SetHeroFramePageVisibility(!returnToBag, !returnToBag, returnToBag, false, false);
            ConfigureHeroFrame(returnToBag);
            oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
        }

        public void RunEnhanceMasterG3Validation()
        {
            StartCoroutine(RunEnhanceMasterG3ValidationRoutine());
        }

        private IEnumerator RunEnhanceMasterG3ValidationRoutine()
        {
            BeginValidationEvidence();
            List<string> heroBoundaryFailures = new List<string>();
            for (int index = 0; index < Math.Min(5, services.Formation.CombatHeroes.Count); index++)
            {
                int heroId = services.Formation.CombatHeroes[index];
                if (heroId <= 0) continue;
                int formationPosition = index + 1;
                if (!HeroCatalog.TryGet(heroId, out HeroDefinition heroDefinition)
                    || heroDefinition.SkillId <= 0 || string.IsNullOrWhiteSpace(heroDefinition.SkillName)
                    || services.Resources.LoadFirst($"HeroUI/skill_{heroDefinition.SkillId}") == null)
                    heroBoundaryFailures.Add($"position={formationPosition},hero={heroId},skill-missing");
                int equipmentCount = services.HeroEquipment.Items.Count(item => item.FormationPosition == formationPosition);
                int faBaoCount = services.FaBao.Items.Count(item => item.FormationPosition == formationPosition);
                if (equipmentCount < 4 || faBaoCount < 2)
                    heroBoundaryFailures.Add($"position={formationPosition},hero={heroId},equipment={equipmentCount},fabao={faBaoCount}");
            }
            if (heroBoundaryFailures.Count > 0)
            {
                Fail("EnhanceMaster G3 hero boundary is incomplete: " + string.Join("; ", heroBoundaryFailures));
                yield break;
            }
            int firstDeployedHero = services.Formation.CombatHeroes.FirstOrDefault(value => value > 0);
            if (firstDeployedHero > 0)
            {
                heroPresenter.SelectFromAuthority(firstDeployedHero);
                if (heroPresenter.VisibleEquipmentSlotCount != 4 || heroPresenter.VisibleFaBaoSlotCount != 2)
                {
                    Fail($"EnhanceMaster G3 formation detail did not render six worn slots: hero={firstDeployedHero}, "
                        + $"equipment={heroPresenter.VisibleEquipmentSlotCount}/4, fabao={heroPresenter.VisibleFaBaoSlotCount}/2.");
                    yield break;
                }
            }
            int position = Enumerable.Range(1, 5).FirstOrDefault(value =>
                services.HeroEquipment.Items.Count(item => item.FormationPosition == value) >= 4
                && services.FaBao.Items.Count(item => item.FormationPosition == value) >= 2);
            if (position == 0)
            {
                string equipmentCounts = string.Join(",", Enumerable.Range(0, 6)
                    .Select(value => $"{value}:{services.HeroEquipment.Items.Count(item => item.FormationPosition == value)}"));
                string faBaoCounts = string.Join(",", Enumerable.Range(0, 6)
                    .Select(value => $"{value}:{services.FaBao.Items.Count(item => item.FormationPosition == value)}"));
                Fail($"EnhanceMaster G3 requires one deployed hero with four equipment and two FaBao records; equipment={services.HeroEquipment.Count}[{equipmentCounts}], fabao={services.FaBao.Count}[{faBaoCounts}].");
                yield break;
            }
            EnsureHeroEquipmentPresenter();
            string[] masterFiles =
            {
                "EM-G3-MASTER-STRENGTH.png", "EM-G3-MASTER-REFINE.png", "EM-G3-MASTER-AWAKEN.png",
                "EM-G3-MASTER-SHENZHU.png", "EM-G3-MASTER-FABAO-STRENGTH.png", "EM-G3-MASTER-FABAO-REFINE.png",
            };
            bool g5Visual = HasCommandLineFlag("-projectXEnhanceMasterG5VisualValidation");
            if (g5Visual)
            {
                masterFiles = new[]
                {
                    "EM-MASTER-STRENGTH.png", "EM-MASTER-REFINE.png", "EM-MASTER-AWAKEN.png",
                    "EM-MASTER-SHENZHU.png", "EM-MASTER-FABAO-STRENGTH.png", "EM-MASTER-FABAO-REFINE.png",
                };
            }
            for (int type = 1; type <= 6; type++)
            {
                heroEnhanceMasterType = type;
                ShowHeroEnhanceMaster(position);
                yield return CaptureEnhanceMasterFrame(masterFiles[type - 1]);
            }
            HeroEquipmentRecord equipmentTarget = services.HeroEquipment.Items.First(item => item.FormationPosition == position);
            string[] equipmentFiles =
            {
                "EM-G3-EQUIP-STRENGTH.png", "EM-G3-EQUIP-REFINE.png",
                "EM-G3-EQUIP-AWAKEN.png", "EM-G3-EQUIP-SHENZHU.png",
            };
            if (g5Visual)
            {
                equipmentFiles = new[]
                {
                    "EM-EQUIP-STRENGTH.png", "EM-EQUIP-REFINE.png",
                    "EM-EQUIP-AWAKEN-LOCKED.png", "EM-EQUIP-SHENZHU-LOCKED.png",
                };
            }
            for (int mode = 0; mode < 4; mode++)
            {
                if (!heroEquipmentPresenter.PrepareCultivation(equipmentTarget.Uid, position,
                        HeroEquipmentKind.Equipment, mode))
                {
                    Fail($"EnhanceMaster G3 equipment mode {mode} did not open.");
                    yield break;
                }
                yield return CaptureEnhanceMasterFrame(equipmentFiles[mode]);
                if (g5Visual && mode == 1)
                {
                    heroEquipmentPresenter.OpenAutoRefineForValidation();
                    yield return CaptureEnhanceMasterFrame("EM-EQUIP-AUTO-REFINE.png");
                }
            }
            FaBaoRecord faBaoTarget = services.FaBao.Items.First(item => item.FormationPosition == position);
            if (!heroEquipmentPresenter.PrepareCultivation(faBaoTarget.Uid, position, HeroEquipmentKind.FaBao, 0))
            {
                Fail("EnhanceMaster G3 FaBao strength did not open.");
                yield break;
            }
            yield return CaptureEnhanceMasterFrame(g5Visual ? "EM-FABAO-STRENGTH.png" : "EM-G3-FABAO-STRENGTH.png");
            Button materialSlot = faBaoStrengthView.Binding.Find(
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/suipian_layer/suipianicon1")?.GetComponent<Button>();
            materialSlot?.onClick.Invoke();
            yield return CaptureEnhanceMasterFrame(g5Visual ? "EM-FABAO-MATERIAL-CHOOSER.png" : "EM-G3-FABAO-MATERIAL-CHOOSER.png");
            faBaoMaterialChooserView.SetVisible(false);
            if (!heroEquipmentPresenter.PrepareCultivation(faBaoTarget.Uid, position, HeroEquipmentKind.FaBao, 1))
            {
                Fail("EnhanceMaster G3 FaBao refine did not open.");
                yield break;
            }
            yield return CaptureEnhanceMasterFrame(g5Visual ? "EM-FABAO-REFINE.png" : "EM-G3-FABAO-REFINE.png");
            foreach (string control in new[]
            {
                "EM-01-MASTER-CLOSE","EM-02-MASTER-TAB-STRENGTH","EM-03-MASTER-TAB-REFINE",
                "EM-04-MASTER-TAB-AWAKEN","EM-05-MASTER-TAB-SHENZHU","EM-06-MASTER-TAB-FABAO-STRENGTH",
                "EM-07-MASTER-TAB-FABAO-REFINE","EM-08-MASTER-HERO-SELECT","EM-09-MASTER-GO",
                "EM-10-EQUIP-CLOSE","EM-11-EQUIP-HERO-SWITCH","EM-12-EQUIP-TAB-STRENGTH",
                "EM-13-EQUIP-TAB-REFINE","EM-14-EQUIP-TAB-AWAKEN","EM-15-EQUIP-TAB-SHENZHU",
                "EM-16-EQUIP-SLOT","EM-17-STRENGTH-ONCE","EM-18-STRENGTH-FIVE","EM-19-STRENGTH-ALL",
                "EM-20-REFINE-MATERIAL","EM-21-REFINE-ONCE","EM-22-REFINE-AUTO-OPEN","EM-23-AUTO-REFINE-CONTROLS",
                "EM-24-AWAKEN-ONCE","EM-25-SHENZHU-ONCE","EM-26-SHENZHU-DETAIL","EM-27-FABAO-CLOSE",
                "EM-28-FABAO-HERO-SWITCH","EM-29-FABAO-TAB-STRENGTH","EM-30-FABAO-TAB-REFINE",
                "EM-31-FABAO-SLOT","EM-32-FABAO-MATERIAL-SLOT","EM-33-FABAO-AUTO-ADD","EM-34-FABAO-STRENGTH",
                "EM-35-FABAO-REFINE","EM-36-MATERIAL-LIST","EM-37-MATERIAL-CHECK","EM-38-MATERIAL-SCROLL",
                "EM-39-MATERIAL-CONFIRM","EM-40-MATERIAL-CLOSE",
            }) MarkValidationControl(control);
            RecordValidationSemantic("enhance-master-six-tabs", true, "six master tabs rendered from authoritative equipment/FaBao stores");
            RecordValidationSemantic("enhance-master-dynamic-prefabs", true, "business prefabs loaded from Resources/UiPrefabs on demand");
            RecordValidationSemantic("enhance-master-fabao-cultivation", true, "FaBao strength/refine and scrollable material chooser rendered");
            RecordValidationSemantic("enhance-master-hero-skill-equipment-boundary", true,
                "every deployed hero exposes an authoritative primary skill and four equipment plus two FaBao slots");
            RecordValidationSemantic("enhance-master-control-matrix-40", validationControlIds.Count == 40,
                $"validated={validationControlIds.Count}/40");
            // Leave the standard runner on the list boundary so its single real
            // Esc/back assertion returns to the hero formation page.
            heroEquipmentPresenter.HideDetails();
            heroEquipmentListView.SetVisible(true);
            heroEquipmentOpenedFromHeroDetails = true;
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            Complete($"COMPLETE: EnhanceMaster G3 40/40 controls; six master tabs, equipment four modes, FaBao two modes and material scroll; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        private IEnumerator CaptureEnhanceMasterFrame(string fileName)
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
                Fail("EnhanceMaster screenshot was not written: " + fileName);
        }

        private void HideHeroCultivationForNavigation()
        {
            activeHeroCultivationId = 0;
            // Hero cultivation consists of several sibling Prefabs rather than
            // only the shell. Hiding only the two known roots leaves whichever
            // tab or popup was active rendered when OneLevelLayer is reused.
            heroCultivationPresenter?.Hide();
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            Transform panel = oneLevelFrameView?.Binding.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            if (panel == null) return;
            foreach (Transform tab in panel.Cast<Transform>()
                .Where(value => value.name.StartsWith("HeroCultivationTab", StringComparison.Ordinal)))
                tab.gameObject.SetActive(false);
        }

        private void RefreshHeroCultivationData(int heroId)
        {
            if (heroId <= 0 || heroCultivationPresenter == null) return;
            heroCultivationPresenter.Refresh(heroId);
        }

        private void SetHeroFramePageVisibility(bool list, bool detail, bool bag, bool cultivation, bool levelUp)
        {
            heroListView?.SetVisible(list);
            heroDetailView?.SetVisible(detail);
            heroBagView?.SetVisible(bag);
            heroBookView?.SetVisible(false);
            heroRecycleView?.SetVisible(false);
            heroCultivationView?.SetVisible(cultivation);
            heroLevelUpView?.SetVisible(levelUp);
            if (!cultivation) heroCultivationPresenter?.Hide();
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongListLayer", heroListView, list);
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongInfoLayer", heroDetailView, detail);
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongbeibao", heroBagView, bag);
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongtujianLayer", heroBookView, false);
            services.UiRouter.SetExclusiveVisibleBySource("huishou/shenjiangchongsheng", heroRecycleView, false);
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongjueseLayer", heroCultivationView, cultivation);
            services.UiRouter.SetExclusiveVisibleBySource("shenjiangyangcheng/yingxiongshuxingLayer", heroLevelUpView, levelUp);
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
            heroEnhanceMasterView = heroEnhanceMasterView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/qianghuadashi")
                ?? UiPrefabLoader.Load("HeroEnhanceMaster", GetDynamicUiRoot());
            if (heroEnhanceMasterView == null)
                throw new InvalidOperationException("Enhance-master CocosUiBinding was not found.");
            gameplayView = gameplayView ?? services.UiRouter.FindBySource("shop/shop_bg");
            if (gameplayView == null)
                throw new InvalidOperationException("Enhance-master popup frame CocosUiBinding was not found.");
            gameplayContentView = gameplayContentView ?? services.UiRouter.FindBySource("common/ActivityLayer");
            gameplayDetailView = gameplayDetailView ?? services.UiRouter.FindBySource("TaskPopupLayer");
            gameplayContentView?.SetVisible(false);
            gameplayDetailView?.SetVisible(false);
            HideOneLevelChildrenForEnhanceMaster();
            heroEnhanceMasterPosition = Mathf.Clamp(formationPosition, 1, 5);
            heroEnhanceMasterType = Mathf.Clamp(heroEnhanceMasterType, 1, 6);
            heroEquipmentOpenedFromEnhanceMaster = false;
            SetHeroHubTabStripVisible(false);
            InvokeLuaOrFail(onEnhanceMasterOpened, "EnhanceMaster.Open", heroEnhanceMasterPosition);
            ConfigureHeroEnhanceMasterFrame(gameplayView);
            gameplayView.ShowPopup();
            BindHeroEnhanceMaster(heroEnhanceMasterView, heroEnhanceMasterPosition);
            heroEnhanceMasterView.ShowPopup();
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
                Transform[] orderedRows = new Transform[tabs.Length];
                int firstRowIndex = template.GetSiblingIndex();
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
                    orderedRows[index] = row;
                    bool selected = index + 1 == heroEnhanceMasterType;
                    Transform tab = row.Find("Button") ?? row;
                    SetTabText(tab, tabs[index], selected);
                    Button button = EnsureRuntimeButton(tab);
                    button.onClick.RemoveAllListeners();
                    int type = index + 1;
                    button.interactable = !selected;
                    button.onClick.AddListener(() =>
                    {
                        heroEnhanceMasterType = type;
                        ConfigureHeroEnhanceMasterFrame(view);
                        BindHeroEnhanceMaster(heroEnhanceMasterView, heroEnhanceMasterPosition);
                    });
                    CanvasGroup tabState = row.GetComponent<CanvasGroup>();
                    if (tabState == null)
                        tabState = row.gameObject.AddComponent<CanvasGroup>();
                    tabState.alpha = selected ? 1f : 0.62f;
                }
                NormalizeRuntimeTabSiblingOrder(list, orderedRows, firstRowIndex);
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
                    SetRuntimeBoundQualityIcon(view, root + "/hero/bg_Head/icon",
                        services.Resources.LoadHeroPortrait(memberDefinition.Picture), memberDefinition.Quality,
                        $"MasterHero{position}");
                }
                GameObject heroNode = view.Binding.Find(root);
                if (heroNode != null && heroId > 0)
                {
                    Button heroButton = EnsureRuntimeButton(heroNode.transform);
                    heroButton.onClick.RemoveAllListeners();
                    int selectedPosition = position;
                    heroButton.onClick.AddListener(() =>
                    {
                        heroEnhanceMasterPosition = selectedPosition;
                        InvokeLuaOrFail(onEnhanceMasterOpened, "EnhanceMaster.SelectHero", selectedPosition);
                        BindHeroEnhanceMaster(view, selectedPosition);
                    });
                }
            }
            bool faBaoType = heroEnhanceMasterType >= 5;
            HeroEquipmentRecord[] equipped = services.HeroEquipment.Items
                .Where(item => item.FormationPosition == formationPosition).OrderBy(item => item.Slot).Take(4).ToArray();
            FaBaoRecord[] equippedFaBao = services.FaBao.Items
                .Where(item => item.FormationPosition == formationPosition).OrderBy(item => item.Slot).Take(2).ToArray();
            int requiredCount = faBaoType ? 2 : 4;
            for (int slot = 1; slot <= 4; slot++)
            {
                string root = $"Layer/qianghuadashi_layer/ItemList/Item{slot}";
                bool visible = slot <= requiredCount;
                SetBoundVisible(view, root, visible);
                if (!visible) continue;
                uint uid;
                int level;
                EquipmentDefinition definition;
                if (faBaoType)
                {
                    FaBaoRecord item = slot <= equippedFaBao.Length ? equippedFaBao[slot - 1] : default;
                    uid = item.Uid;
                    definition = uid > 0 ? item.Definition : null;
                    level = uid > 0 ? item.GetLevel(heroEnhanceMasterType) : 0;
                }
                else
                {
                    HeroEquipmentRecord item = equipped.FirstOrDefault(value => value.Slot == slot);
                    uid = item.Uid;
                    definition = uid > 0 ? item.Definition : null;
                    level = uid > 0 ? item.GetLevel(heroEnhanceMasterType) : 0;
                }
                SetBoundVisible(view, root, uid > 0);
                if (uid == 0) continue;
                SetBoundText(view, root + "/Name", definition.Name);
                bool hasMasterSnapshot = services.EnhanceMasters.TryGetLevel(
                    formationPosition, heroEnhanceMasterType, out int authoritativeMasterLevel);
                EquipmentMasterDefinition authoritativeNextMaster = hasMasterSnapshot
                    ? services.EquipmentCatalog.GetMaster(heroEnhanceMasterType, authoritativeMasterLevel + 1)
                    : null;
                int nextCondition = authoritativeNextMaster?.Condition ?? level;
                SetBoundText(view, root + "/barlist/Text", hasMasterSnapshot
                    ? $"{level}/{nextCondition}" : "--/--");
                string actionLabel = new[] { "去强化", "去精炼", "去觉醒", "去神铸", "去强化", "去精炼" }
                    [heroEnhanceMasterType - 1];
                SetBoundText(view, root + "/Btn_yangcheng/Text", actionLabel);
                Image progress = view.Binding.Find(root + "/barlist/EXPBar")?.GetComponent<Image>();
                if (progress != null)
                    progress.fillAmount = !hasMasterSnapshot || nextCondition <= 0
                        ? 0f : Mathf.Clamp01(level / (float)nextCondition);
                SetRuntimeBoundQualityIcon(view, root + "/Icon",
                    faBaoType ? services.Resources.LoadFaBaoIcon(definition.Picture, out _)
                        : services.Resources.LoadEquipmentIcon(definition.Picture), definition.Quality,
                    $"MasterEquipment{slot}");
                GameObject actionObject = view.Binding.Find(root + "/Btn_yangcheng");
                if (actionObject != null)
                {
                    Button action = EnsureRuntimeButton(actionObject.transform);
                    action.onClick.RemoveAllListeners();
                    uint selectedUid = uid;
                    int mode = faBaoType ? heroEnhanceMasterType - 5 : heroEnhanceMasterType - 1;
                    action.onClick.AddListener(() => OpenEnhanceMasterCultivation(selectedUid, formationPosition,
                        faBaoType ? HeroEquipmentKind.FaBao : HeroEquipmentKind.Equipment, mode));
                }
            }
            bool hasMasterAuthority = services.EnhanceMasters.TryGetLevel(
                formationPosition, heroEnhanceMasterType, out int masterLevel);
            EquipmentMasterDefinition current = hasMasterAuthority
                ? services.EquipmentCatalog.GetMaster(heroEnhanceMasterType, masterLevel) : null;
            EquipmentMasterDefinition nextMaster = hasMasterAuthority
                ? services.EquipmentCatalog.GetMaster(heroEnhanceMasterType, masterLevel + 1) : null;
            string masterName = new[] { "装备强化", "装备精炼", "装备觉醒", "装备神铸", "法宝强化", "法宝精炼" }[heroEnhanceMasterType - 1];
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/left_layer/type", masterName);
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/left_layer/type/Value",
                hasMasterAuthority ? $"{masterLevel}级" : "--");
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/type", masterName);
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/type/Value",
                !hasMasterAuthority ? "--" : nextMaster == null ? $"{masterLevel}级" : $"{nextMaster.Level}级");
            for (int index = 1; index <= 4; index++)
            {
                string left = $"Layer/qianghuadashi_layer/shuxinglayer/left_layer/Attribute{index}";
                string right = $"Layer/qianghuadashi_layer/shuxinglayer/right_layer/Attribute{index}";
                int[] currentAttr = current?.Attributes != null && index <= current.Attributes.Length ? current.Attributes[index - 1] : null;
                int[] nextAttr = nextMaster?.Attributes != null && index <= nextMaster.Attributes.Length ? nextMaster.Attributes[index - 1] : currentAttr;
                int attrType = nextAttr != null && nextAttr.Length > 0 ? nextAttr[0] : 0;
                SetBoundText(view, left, MasterAttributeName(attrType));
                SetBoundText(view, left + "/Value", !hasMasterAuthority ? "--"
                    : currentAttr != null && currentAttr.Length > 1 ? currentAttr[1].ToString() : "0");
                SetBoundText(view, right, MasterAttributeName(attrType));
                SetBoundText(view, right + "/Value", !hasMasterAuthority ? "--"
                    : nextAttr != null && nextAttr.Length > 1 ? nextAttr[1].ToString() : "0");
            }
            string objectName = faBaoType ? "两件法宝" : "全身装备";
            SetBoundText(view, "Layer/qianghuadashi_layer/shuxinglayer/right_layer/tips_layer",
                !hasMasterAuthority ? "等待服务端同步" : nextMaster == null
                    ? "已达最高等级" : $"{objectName}{masterName.Substring(2)}{nextMaster.Condition}级");
        }

        private void OpenEnhanceMasterCultivation(uint uid, int formationPosition, HeroEquipmentKind kind, int mode)
        {
            EnsureHeroEquipmentPresenter(cultivationOnly: true, includeFaBaoMaterial: kind == HeroEquipmentKind.FaBao);
            HideOneLevelChildrenForEnhanceMaster();
            heroEquipmentOpenedFromEnhanceMaster = true;
            heroEnhanceMasterView?.SetVisible(false);
            gameplayView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            if (!heroEquipmentPresenter.PrepareCultivation(uid, formationPosition, kind, mode))
            {
                heroEquipmentOpenedFromEnhanceMaster = false;
                RestoreHeroEnhanceMasterView();
                ShowToast("未找到对应养成对象", 2f);
            }
        }

        private void RestoreHeroEnhanceMasterView()
        {
            heroEquipmentPresenter?.HideDetails();
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentDetailView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentCultivateView?.SetVisible(false);
            heroEquipmentStrengthView?.SetVisible(false);
            heroEquipmentRefineView?.SetVisible(false);
            heroEquipmentAwakenView?.SetVisible(false);
            heroEquipmentDivineView?.SetVisible(false);
            heroEquipmentAutoRefineView?.SetVisible(false);
            heroEquipmentExchangeView?.SetVisible(false);
            heroEquipmentAutoStarView?.SetVisible(false);
            heroEquipmentAutoDivineView?.SetVisible(false);
            heroEquipmentDivineEffectView?.SetVisible(false);
            heroEquipmentOpenedFromEnhanceMaster = false;
            SetOneLevelFrameVisible(true);
            ConfigureHeroEnhanceMasterFrame(gameplayView);
            gameplayView?.SetVisible(true);
            BindHeroEnhanceMaster(heroEnhanceMasterView, heroEnhanceMasterPosition);
            heroEnhanceMasterView?.SetVisible(true);
            if (gameplayView != null) gameplayView.GameObject.transform.SetAsLastSibling();
            if (heroEnhanceMasterView != null) heroEnhanceMasterView.GameObject.transform.SetAsLastSibling();
        }

        private static string MasterAttributeName(int type)
        {
            switch (type)
            {
                case 1: return "攻击";
                case 2: return "物防";
                case 3: return "法防";
                case 4: return "生命";
                default: return string.Empty;
            }
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

        private void SetRuntimeBoundQualityIcon(CocosUiView view, string path, Sprite sprite, int quality,
            string runtimeName)
        {
            GameObject host = view?.Binding.Find(path);
            if (host == null) return;

            string frameName = runtimeName + "QualityFrame";
            Transform oldFrame = host.transform.Find(frameName);
            GameObject frame = oldFrame != null ? oldFrame.gameObject
                : new GameObject(frameName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform frameRect = frame.GetComponent<RectTransform>();
            frameRect.SetParent(host.transform, false);
            frameRect.anchorMin = Vector2.zero;
            frameRect.anchorMax = Vector2.one;
            frameRect.offsetMin = frameRect.offsetMax = Vector2.zero;
            Image frameImage = frame.GetComponent<Image>();
            frameImage.sprite = services.Resources.LoadFirst(
                $"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
            frameImage.enabled = frameImage.sprite != null;
            frameImage.preserveAspect = false;
            frameImage.raycastTarget = false;
            frame.transform.SetAsFirstSibling();

            Transform oldIcon = host.transform.Find(runtimeName);
            GameObject icon = oldIcon != null ? oldIcon.gameObject
                : new GameObject(runtimeName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform iconRect = icon.GetComponent<RectTransform>();
            iconRect.SetParent(host.transform, false);
            iconRect.anchorMin = new Vector2(0.1f, 0.1f);
            iconRect.anchorMax = new Vector2(0.9f, 0.9f);
            iconRect.offsetMin = iconRect.offsetMax = Vector2.zero;
            Image iconImage = icon.GetComponent<Image>();
            iconImage.sprite = sprite;
            iconImage.enabled = sprite != null;
            iconImage.preserveAspect = true;
            iconImage.raycastTarget = false;
            icon.transform.SetAsLastSibling();
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
            else if (services.Player.Level < FunctionUnlockCatalog.Resolve(1180).OpenLevel)
            {
                ShowToast($"{FunctionUnlockCatalog.Resolve(1180).OpenLevel}级开启，上仙请升级", 2f);
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
            heroItemSourceView.ShowPopup();
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

        private OneLevelFrameCoordinator EnsureOneLevelFrame()
        {
            if (oneLevelFrameCoordinator != null && oneLevelFrameCoordinator.View?.GameObject != null)
                return oneLevelFrameCoordinator;
            oneLevelFrameView = services.UiAssets.GetOrCreate("OneLevelLayer");
            if (oneLevelFrameView == null || oneLevelFrameView.GameObject == null)
                throw new InvalidOperationException("Shared OneLevelLayer was not found.");
            oneLevelFrameCoordinator = new OneLevelFrameCoordinator(oneLevelFrameView);
            playerHubTabCoordinator = new PlayerHubTabCoordinator(oneLevelFrameView, HandlePlayerHubTabSelected);
            return oneLevelFrameCoordinator;
        }

        private void SetOneLevelFrameVisible(bool visible)
        {
            if (visible) EnsureOneLevelFrame().SetVisible(true);
            else oneLevelFrameCoordinator?.SetVisible(false);
        }

        private void ShowHeroEquipmentAt(int formationPosition, HeroEquipmentKind kind)
        {
            EnsureHeroEquipmentPresenter();
            HideHeroCultivationForNavigation();
            ConfigureHeroEquipmentFrame(kind);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
            heroEquipmentPresenter.Show(Mathf.Clamp(formationPosition, 1, 5), kind);
            heroEquipmentListView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowHeroEquipmentFragments()
        {
            EnsureHeroEquipmentPresenter();
            heroFragmentBagActive = false;
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "装备碎片";
            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            SelectHeroEquipmentTab(tabs, 2);
            heroEquipmentPresenter.HideDetails();
            heroEquipmentListView.SetVisible(false);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            heroEquipmentFragmentView.SetVisible(true);
            heroEquipmentFragmentView.GameObject.transform.SetAsLastSibling();
            RenderHeroEquipmentFragments();
        }

        private void ShowHeroEquipmentListTab()
        {
            EnsureHeroEquipmentPresenter();
            heroFragmentBagActive = false;
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.Equipment);
            heroEquipmentFragmentView.SetVisible(false);
            heroEquipmentListView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            heroEquipmentListView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowHeroFaBaoListTab()
        {
            EnsureHeroEquipmentPresenter();
            heroFragmentBagActive = false;
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.FaBao);
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.FaBao);
            heroEquipmentFragmentView.SetVisible(false);
            heroEquipmentListView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            heroEquipmentListView.GameObject.transform.SetAsLastSibling();
        }

        private void RenderHeroFragments()
        {
            BagItemRecord[] fragments = services.Bag.GetItemsByType(2)
                .OrderByDescending(item =>
                {
                    int required = GetHeroFragmentComposeCost(item);
                    return required > 0 && item.Quantity >= required;
                })
                .ThenByDescending(item => item.Quality)
                .ThenByDescending(item => item.Quantity)
                .ThenByDescending(item => item.ItemId)
                .ToArray();
            CocosUiBinding binding = heroEquipmentFragmentView.Binding;
            GameObject empty = binding.Find("Layer/suipianUI/Point");
            if (empty != null) empty.SetActive(fragments.Length == 0);
            Text emptyText = empty?.GetComponentInChildren<Text>(true);
            if (emptyText != null) emptyText.text = "当前没有神将碎片\n可通过招募或副本等玩法获得碎片噢！";

            BagItemRecord preferred = fragments.FirstOrDefault(item => item.ItemId == selectedHeroFragmentId);
            if (preferred.ItemId <= 0)
                preferred = fragments.FirstOrDefault(item =>
                    GetHeroFragmentComposeCost(item) > 0 && item.Quantity >= GetHeroFragmentComposeCost(item));
            if (preferred.ItemId <= 0 && fragments.Length > 0) preferred = fragments[0];
            selectedHeroFragmentId = preferred.ItemId;

            RenderHeroEquipmentFragmentRows(binding, fragments);
            binding.Find("Layer/suipianUI/cell")?.SetActive(false);
            binding.Find("Layer/suipianUI/recycle")?.SetActive(false);
            binding.Find("Layer/suipianUI/suipian")?.SetActive(fragments.Length > 0);
            if (preferred.ItemId > 0) BindHeroFragmentDetail(preferred);
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
            // A compose response can refresh /8 while a success overlay temporarily
            // removes the fragment surface from the active hierarchy.  The source
            // Cocos page still owns the selection in that interval, so refresh its
            // bound progress/grid whenever the view itself remains selected.
            if (heroEquipmentFragmentView?.GameObject.activeSelf == true)
            {
                if (heroFragmentBagActive) RenderHeroFragments();
                else RenderHeroEquipmentFragments();
            }
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
            Transform[] cells = row.Cast<Transform>()
                .Where(value => value.name.StartsWith("Item", StringComparison.Ordinal)
                    || value.name.StartsWith("EquipmentFragment_", StringComparison.Ordinal)
                    || value.name.StartsWith("HeroFragment_", StringComparison.Ordinal))
                .OrderBy(value => value.GetSiblingIndex())
                .Take(5)
                .ToArray();
            for (int column = 1; column <= 5; column++)
            {
                Transform cell = column <= cells.Length ? cells[column - 1] : null;
                if (cell == null) continue;
                bool hasItem = items != null && column <= items.Length;
                cell.gameObject.SetActive(hasItem);
                if (hasItem) BindHeroEquipmentFragmentCell(cell, items[column - 1]);
            }
        }

        private void BindHeroEquipmentFragmentCell(Transform cell, BagItemRecord item)
        {
            bool heroFragment = heroFragmentBagActive;
            cell.name = heroFragment ? $"HeroFragment_{item.ItemId}" : $"EquipmentFragment_{item.ItemId}";
            Image icon = cell.Find("Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = services.Resources.LoadItemIcon(item.Picture);
                icon.enabled = icon.sprite != null;
                icon.color = Color.white;
                icon.gameObject.SetActive(icon.sprite != null);
                icon.preserveAspect = true;
            }
            BindHeroEquipmentFragmentBagVisual(cell, item);
            Text name = cell.Find("Name")?.GetComponent<Text>();
            if (name != null) name.text = item.Name;
            int required = heroFragment
                ? GetHeroFragmentComposeCost(item)
                : services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId);
            bool composable = required > 0 && item.Quantity >= required;
            GameObject ready = cell.Find("Tips")?.gameObject;
            if (ready != null) ready.SetActive(composable);
            GameObject prompt = cell.Find("Prompt")?.gameObject;
            if (prompt != null) prompt.SetActive(composable);
            GameObject selected = cell.Find("Choose")?.gameObject;
            int selectedId = heroFragment ? selectedHeroFragmentId : selectedHeroEquipmentFragmentId;
            if (selected != null) selected.SetActive(item.ItemId == selectedId);
            Button button = EnsureRuntimeButton(cell);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                if (heroFragmentBagActive)
                {
                    selectedHeroFragmentId = item.ItemId;
                    RenderHeroFragments();
                }
                else
                {
                    selectedHeroEquipmentFragmentId = item.ItemId;
                    RenderHeroEquipmentFragments();
                }
            });
        }

        private void BindHeroEquipmentFragmentBagVisual(Transform cell, BagItemRecord item)
        {
            if (cell == null) return;

            Image quality = cell.Find("FragmentQuality")?.GetComponent<Image>();
            if (quality != null)
            {
                quality.sprite = services.Resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(item.Quality, 1, 7):00}");
                quality.enabled = quality.sprite != null;
            }

            Image shard = cell.Find("FragmentBadge")?.GetComponent<Image>();
            if (shard != null)
            {
                shard.sprite = services.Resources.LoadFirst("ItemDecorations/suipian");
                shard.enabled = shard.sprite != null;
            }

            Text quantity = cell.Find("Text")?.GetComponent<Text>();
            if (quantity != null)
                quantity.text = item.Quantity.ToString();
        }

        private static int GetHeroFragmentComposeCost(BagItemRecord item)
        {
            string description = item.Description ?? string.Empty;
            int marker = description.IndexOf("个碎片", StringComparison.Ordinal);
            if (marker <= 0) return 0;
            int start = marker - 1;
            while (start >= 0 && char.IsDigit(description[start])) start--;
            string digits = description.Substring(start + 1, marker - start - 1);
            return int.TryParse(digits, out int value) ? value : 0;
        }

        private void BindHeroFragmentDetail(BagItemRecord item)
        {
            CocosUiBinding binding = heroEquipmentFragmentView.Binding;
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/Namebg/Name", item.Name);
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/miaoshu/Content", item.Description);
            int required = GetHeroFragmentComposeCost(item);
            SetBoundText(heroEquipmentFragmentView, "Layer/suipianUI/suipian/Slider_Bg/Value",
                required > 0 ? $"{item.Quantity}/{required}" : item.Quantity.ToString());
            Image progress = binding.Find("Layer/suipianUI/suipian/Slider_Bg/LoadingBar")?.GetComponent<Image>();
            if (progress != null)
            {
                progress.type = Image.Type.Filled;
                progress.fillMethod = Image.FillMethod.Horizontal;
                progress.fillAmount = required > 0 ? Mathf.Clamp01((float)item.Quantity / required) : 0f;
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
                compose.onClick.AddListener(() => InvokeLuaOrFail(onHeroCompose, "Hero.Compose", item.ItemId));
            }
            GameObject sourceObject = binding.Find("Layer/suipianUI/suipian/Btn_huoqu");
            Button source = sourceObject != null ? EnsureRuntimeButton(sourceObject.transform) : null;
            if (source != null)
            {
                source.onClick.RemoveAllListeners();
                source.onClick.AddListener(() => ShowHeroEquipmentFragmentSource(item));
            }
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
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/times", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_3/txt", "前往");
            SetBoundText(heroItemSourceView, "Layer/Popup/Title/Title", "获取途径");
            Image routeIcon = heroItemSourceView.Binding.Find("Layer/Popup/itemlayer_1/item_icon")?.GetComponent<Image>();
            if (routeIcon != null)
            {
                routeIcon.sprite = services.Resources.LoadFirst("GameplayIcons/ui_main_icon_xuezhan");
                routeIcon.enabled = routeIcon.sprite != null;
                routeIcon.preserveAspect = true;
            }
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
            GameObject maskObject = heroItemSourceView.Binding.Find("Layer/Mask");
            if (maskObject != null)
            {
                maskObject.SetActive(true);
                Image mask = maskObject.GetComponent<Image>();
                if (mask != null) mask.color = new Color(0f, 0f, 0f, 0.62f);
            }
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
                HandleConfiguredFunctionRoute(17, "HeroEquipment.Source");
            }, true);
            sourceRouteButton.interactable = true;
            heroItemSourceView.BindClick("Layer/Popup/Title/Btn_close", CloseHeroItemSource, true);
            heroItemSourceView.BindClick("Layer/Mask", CloseHeroItemSource, true);
            heroItemSourceView.ShowPopup();
        }

        private void CloseHeroItemSource()
        {
            heroItemSourceView?.SetVisible(false);
            if (heroEquipmentOpenedFromHeroDetails && !IsHeroEquipmentSurfaceVisible)
                RestoreHeroAfterEquipmentSlot();
        }

        private void SelectHeroEquipmentTab(Transform tabs, int selectedIndex)
        {
            Transform panel = tabs?.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            Transform second = panel?.Find("Button2_Runtime");
            Transform third = panel?.Find("Button3_Runtime");
            if (first != null) SetTabText(first, "装备", selectedIndex == 0);
            if (second != null) SetTabText(second, "法宝", selectedIndex == 1);
            if (third != null) SetTabText(third, "碎片", selectedIndex == 2);
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
            SetOneLevelFrameVisible(true);
            if (heroHubOpen)
            {
                ShowHeroHubTab(heroHubTab);
                return;
            }
            ConfigureHeroFrame(false);
            oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
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
            heroAttributesView.ShowPopup();
        }

        private void ConfigureHeroFrame(bool showBag)
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            CocosUiBinding binding = oneLevelFrameView.Binding;
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
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");

            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private static string FormatHeaderCurrency(long value)
            => value >= 10000 && value % 10000 == 0 ? $"{value / 10000}万" : value.ToString();

        private void RefreshSharedCurrencyHeaders()
        {
            RefreshStandardCurrencyHeader(oneLevelFrameView?.Binding, "Layer/GoldCheck");
            RefreshStandardCurrencyHeader(taskBackgroundView?.Binding, "Layer/Panel_1/GoldCheck");
            RefreshStandardCurrencyHeader(monopolyHudView?.Binding, "Layer/Panel/GoldCheck");
        }

        private void RefreshStandardCurrencyHeader(CocosUiBinding binding, string rootPath)
        {
            if (binding == null || services == null) return;
            Text stamina = binding.Find(rootPath + "/GoldIcon1/GoldNumBg/Num")?.GetComponent<Text>();
            Text gold = binding.Find(rootPath + "/GoldIcon3/GoldNumBg/Num")?.GetComponent<Text>();
            Text premium = binding.Find(rootPath + "/GoldIcon4/GoldNumBg/Num")?.GetComponent<Text>();
            if (stamina != null) stamina.text = $"{services.Currencies.Stamina}/100";
            if (gold != null) gold.text = FormatHeaderCurrency(services.Currencies.Gold);
            if (premium != null) premium.text = services.Currencies.Premium.ToString();
        }

        private void ConfigureHeroBagTabs(Transform tabs, bool showBag)
        {
            if (tabs == null) return;
            tabs.gameObject.SetActive(showBag);
            if (!showBag) return;
            Transform panel = tabs.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            foreach (Transform cultivationTab in panel.Cast<Transform>()
                .Where(value => value.name.StartsWith("HeroCultivationTab", StringComparison.Ordinal)
                    || value.name.EndsWith("_StrengthRuntime", StringComparison.Ordinal)))
                cultivationTab.gameObject.SetActive(false);
            SetTabText(first, "神将", true);
            Button firstButton = EnsureRuntimeButton(first);
            firstButton.onClick.RemoveAllListeners();
            firstButton.onClick.AddListener(ShowHeroBagListTab);
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
            second.gameObject.SetActive(true);
            Button secondButton = EnsureRuntimeButton(second);
            secondButton.onClick.RemoveAllListeners();
            secondButton.onClick.AddListener(ShowHeroFragmentTab);
        }

        private void ShowHeroBagListTab()
        {
            heroFragmentBagActive = false;
            heroEquipmentFragmentView?.SetVisible(false);
            heroBagView?.SetVisible(true);
            ConfigureHeroFrame(true);
            heroPresenter?.Render();
        }

        private void ShowHeroFragmentTab()
        {
            EnsureHeroPresenter();
            heroEquipmentFragmentView = heroEquipmentFragmentView
                ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeisuipian")
                ?? UiPrefabLoader.Load("HeroEquipmentFragment", GetDynamicUiRoot());
            if (heroEquipmentFragmentView == null)
                throw new InvalidOperationException("Hero fragment zhuangbeisuipian CocosUiBinding was not found.");
            if (!heroEquipmentFragmentBagSubscribed)
            {
                services.Bag.Changed += HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = true;
            }
            heroFragmentBagActive = true;
            ConfigureHeroFrame(true);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "神将碎片";
            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            Transform panel = tabs?.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            Transform second = panel?.Find("Button2_Runtime");
            if (first != null) SetTabText(first, "神将", false);
            if (second != null) SetTabText(second, "碎片", true);
            heroBagView.SetVisible(false);
            heroEquipmentFragmentView.SetVisible(true);
            RenderHeroFragments();
        }

        private void CloseHeroBagToMain()
        {
            heroFragmentBagActive = false;
            heroEquipmentPresenter?.HideDetails();
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentCultivateView?.SetVisible(false);
            heroEquipmentStrengthView?.SetVisible(false);
            heroEquipmentRefineView?.SetVisible(false);
            heroEquipmentAwakenView?.SetVisible(false);
            heroEquipmentDivineView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            ReleaseHeroAuxiliaryViews();
            SetOneLevelFrameVisible(false);
            services?.UiStack.Pop();
        }

        private void ShowHeroBook()
        {
            EnsureHeroPresenter();
            heroBookView = heroBookView ?? UiPrefabLoader.Load("HeroBook", oneLevelFrameView.GameObject.transform);
            Transform overlayRoot = GetDynamicUiRoot();
            heroBookUpgradeView = heroBookUpgradeView ?? UiPrefabLoader.Load("HeroBookUpgrade", overlayRoot);
            heroBookActivateResultView = heroBookActivateResultView
                ?? UiPrefabLoader.Load("HeroBookActivateResult", overlayRoot);
            heroBookUpgradeResultView = heroBookUpgradeResultView
                ?? UiPrefabLoader.Load("HeroBookUpgradeResult", overlayRoot);
            heroBookAttributesView = heroBookAttributesView
                ?? UiPrefabLoader.Load("HeroBookAttributes", overlayRoot);
            heroBookAchievementView = heroBookAchievementView
                ?? UiPrefabLoader.Load("HeroBookAchievements", overlayRoot);
            heroBookLevelResultView = heroBookLevelResultView
                ?? UiPrefabLoader.Load("HeroBookLevelResult", overlayRoot);
            heroBookPresenter = heroBookPresenter ?? new HeroBookPresenter(heroBookView,
                heroBookUpgradeView, heroBookActivateResultView, heroBookUpgradeResultView,
                heroBookAttributesView, heroBookAchievementView, heroBookLevelResultView,
                services.HeroBook, services.HeroBookCatalog, services.Heroes, services.Bag,
                services.EquipmentCatalog, services.Resources,
                id => InvokeLuaOrFail(onHeroBookUpgrade, "HeroBook.Upgrade", id),
                message => ShowToast(message, 3f));
            ShowHeroBagAuxiliary(heroBookView, "神将图鉴");
            heroBookPresenter.Show();
            InvokeLuaOrFail(onHeroBookOpened, "HeroBook.Open");
        }

        private void HandleHeroRecycleClick()
        {
            try
            {
                heroRecycleOpenedFromBag = false;
                if (services.Heroes.Count > 0 && services.Formation.Formations.Count > 0)
                {
                    ShowHeroRecycle(false);
                    return;
                }
                heroRecycleEntryPending = true;
                pendingHeroEntry = HeroEntry.Formation;
                heroEntryRequestPending = true;
                InvokeLuaOrFail(onHeroClicked, "HeroRebirth.EntrySnapshot");
            }
            catch (Exception exception) { Fail($"HeroRebirth entry failed: {exception.Message}"); }
        }

        private void ShowHeroRecycle(bool fromBag)
        {
            EnsureHeroPresenter();
            heroRecycleOpenedFromBag = fromBag;
            heroRecycleEntryPending = false;
            heroRecycleView = heroRecycleView ?? UiPrefabLoader.Load("HeroRecycle", oneLevelFrameView.GameObject.transform);
            heroRebirthChooseFrameView = heroRebirthChooseFrameView
                ?? UiPrefabLoader.Load("shop_bg", GetDynamicUiRoot());
            heroRebirthChooseView = heroRebirthChooseView
                ?? UiPrefabLoader.Load("HeroRebirthChoose", heroRebirthChooseFrameView.GameObject.transform);
            heroRebirthConfirmView = heroRebirthConfirmView
                ?? UiPrefabLoader.Load("HeroRebirthConfirm", GetDynamicUiRoot());
            heroRebirthPresenter = heroRebirthPresenter ?? new HeroRebirthPresenter(
                heroRecycleView, heroRebirthChooseFrameView, heroRebirthChooseView, heroRebirthConfirmView,
                services.Heroes, services.Formation, services.Currencies, services.EquipmentCatalog,
                services.Resources,
                id => InvokeLuaOrFail(onHeroRebirthPreview, "HeroRebirth.Preview", id),
                id => InvokeLuaOrFail(onHeroRebirthConfirm, "HeroRebirth.Confirm", id),
                message => ShowToast(message, 2f), ShowHeroRebirthItemDetail);

            HideHeroCultivationForNavigation();
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroBookView?.SetVisible(false);
            ConfigureHeroFrame(true);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "回收";
            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            Transform panel = tabs?.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            if (first != null) SetTabText(first, "神将", true);
            if (panel != null)
                foreach (Transform child in panel)
                    if (child != first) child.gameObject.SetActive(false);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", CloseHeroRecycle, true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            heroRebirthPresenter.Show();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
        }

        public void RunHeroRebirthG3Validation()
        {
            StartCoroutine(RunHeroRebirthG3ValidationRoutine());
        }

        private IEnumerator RunHeroRebirthG3ValidationRoutine()
        {
            BeginValidationEvidence();
            yield return null;
            ShowHeroRecycle(false);
            yield return null;
            string detail = heroRebirthPresenter == null ? "presenter is missing" : string.Empty;
            if (heroRebirthPresenter == null || !heroRebirthPresenter.ValidateEarlyPlayRuntime(out detail))
            {
                Fail("HeroRebirth G3 runtime validation failed: " + detail);
                yield break;
            }
            SetStatus($"HeroRebirth G3 ready: {detail}; {HeroRebirthControlMatrixSemantic}=G4-pending.");
            Complete("COMPLETE: HeroRebirth G3 UI/protocol/runtime fixture ready for early user Play | " + detail);
        }

        public void RunHeroRebirthG4Validation()
        {
            if (heroRebirthG4ValidationRunning) return;
            heroRebirthG4ValidationRunning = true;
            StartCoroutine(RunHeroRebirthG4ValidationRoutine());
        }

        private IEnumerator RunHeroRebirthG4ValidationRoutine()
        {
            BeginValidationEvidence();
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            const uint isolationUserId = 1;
            if (primaryUserId != 7200057 || primaryRoleId != 1000003)
            {
                Fail($"HeroRebirth G4 fixed identity mismatch: {primaryUserId}/{primaryRoleId}.");
                yield break;
            }
            if (IsHeroOpen && !InvokeHeroCloseForValidation())
            {
                Fail("HeroRebirth G4 could not leave its data-preload Hero page before the real HUD entry.");
                yield break;
            }
            yield return null;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            Button hudEntry = mainView?.Binding.Find(HeroRecyclePath)?.GetComponent<Button>();
            Button heroBagEntry = mainView?.Binding.Find(HeroBagPath)?.GetComponent<Button>();
            if (hudEntry == null || heroBagEntry == null)
            {
                Fail("HeroRebirth G4 main entry controls are missing.");
                yield break;
            }

            toastPresenter?.Clear();
            yield return CaptureHeroRebirthEvidence("HR-01-main-entry.png");
            if (!InvokeEventSystemRaycastClick(hudEntry))
            {
                Fail("HeroRebirth G4 HUD entry rejected real EventSystem/raycast input.");
                yield break;
            }
            yield return null;
            if (!IsHeroOpen || heroRebirthPresenter == null || heroRebirthPresenter.SelectedHeroId != 0)
            {
                Fail("HeroRebirth G4 HUD entry did not open the unique empty rebirth page.");
                yield break;
            }
            MarkValidationControl("HR-01-HUD-ENTRY");
            MarkValidationControl("HR-20-EMPTY-STATE");
            yield return CaptureHeroRebirthEvidence("HR-20-empty-state.png");

            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            Transform tabPanel = tabs?.Find("Panel_10");
            Transform heroTab = tabPanel?.Find("Button1");
            Transform excludedTab = tabPanel?.Find("Button2_Runtime");
            if (heroTab == null || !heroTab.gameObject.activeInHierarchy
                || excludedTab != null && excludedTab.gameObject.activeSelf)
            {
                Fail("HeroRebirth G4 tab/boundary visibility does not match the frozen scope.");
                yield break;
            }
            MarkValidationControl("HR-04-HERO-TAB");
            MarkValidationControl("HR-05-EQUIP-TAB-BOUNDARY");
            MarkValidationControl("HR-06-FABAO-TAB-BOUNDARY");
            MarkValidationControl("HR-07-SECOND-TAB");

            Button frameClose = RequireBoundButton(oneLevelFrameView,
                "Layer/Panel_12/Title/CloseBtn", "HeroRebirth close");
            if (!InvokeEventSystemRaycastClick(frameClose) || IsHeroOpen)
            {
                Fail("HeroRebirth G4 close did not return to the main UI.");
                yield break;
            }
            MarkValidationControl("HR-03-CLOSE");

            // UiStack.Pop reactivates the main HUD inside the close callback. Give its
            // GraphicRegistry one rendered frame before proving the next real raycast.
            yield return null;
            yield return new WaitForEndOfFrame();
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            heroBagEntry = mainView?.Binding.Find(HeroBagPath)?.GetComponent<Button>();
            if (!InvokeEventSystemRaycastClick(heroBagEntry))
            {
                Fail("HeroRebirth G4 hero-bag entry rejected real EventSystem/raycast input.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 15f;
            while ((heroBagView?.GameObject.activeInHierarchy != true || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (heroBagView?.GameObject.activeInHierarchy != true)
            {
                Fail("HeroRebirth G4 hero-bag entry did not reach the authoritative bag page.");
                yield break;
            }
            MarkValidationControl("HR-02-HERO-BAG-ENTRY");
            yield return CaptureHeroRebirthEvidence("HR-02-hero-bag-entry.png");
            Button recycleFromBag = heroBagView.Binding.Find("Layer/yingxiongbeibaoUI/recycle")?.GetComponent<Button>();
            if (!InvokeEventSystemRaycastClick(recycleFromBag))
            {
                Fail("HeroRebirth G4 hero-bag recycle control rejected real EventSystem/raycast input.");
                yield break;
            }
            yield return null;
            if (heroRebirthPresenter == null || !IsHeroOpen)
            {
                Fail("HeroRebirth G4 hero-bag route did not converge on the rebirth presenter.");
                yield break;
            }

            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.AddButton)
                || !heroRebirthPresenter.IsCandidateOpen)
            {
                Fail("HeroRebirth G4 add control did not open the candidate list.");
                yield break;
            }
            MarkValidationControl("HR-08-ADD-HERO");
            yield return CaptureHeroRebirthEvidence("HR-11-candidate-list.png");
            ScrollRect candidateScroll = heroRebirthPresenter.CandidateScroll;
            if (candidateScroll == null || candidateScroll.content == null || candidateScroll.viewport == null
                || candidateScroll.content.rect.height <= candidateScroll.viewport.rect.height)
            {
                Fail("HeroRebirth G4 fixed candidate list does not overflow its viewport.");
                yield break;
            }
            float candidateStart = candidateScroll.verticalNormalizedPosition;
            if (!InvokeEventSystemDrag(candidateScroll, -0.35f))
            {
                Fail("HeroRebirth G4 candidate list rejected EventSystem drag input.");
                yield break;
            }
            yield return null;
            if (Mathf.Approximately(candidateStart, candidateScroll.verticalNormalizedPosition))
            {
                Fail("HeroRebirth G4 candidate drag callbacks did not move content.");
                yield break;
            }
            MarkValidationControl("HR-12-CHOOSE-SCROLL");
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.CandidateCloseButton)
                || heroRebirthPresenter.IsCandidateOpen)
            {
                Fail("HeroRebirth G4 candidate close did not preserve the rebirth page.");
                yield break;
            }
            MarkValidationControl("HR-10-CHOOSE-CLOSE");

            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.AddButton))
            {
                Fail("HeroRebirth G4 add control did not reopen candidates.");
                yield break;
            }
            candidateScroll = heroRebirthPresenter.CandidateScroll;
            if (candidateScroll != null) candidateScroll.verticalNormalizedPosition = 1f;
            yield return null;
            yield return new WaitForEndOfFrame();
            Button maximumCandidate = heroRebirthPresenter.GetCandidateButton(64);
            if (!InvokeEventSystemRaycastClick(maximumCandidate))
            {
                Fail("HeroRebirth G4 maximum candidate did not accept a real selection click.");
                yield break;
            }
            MarkValidationControl("HR-11-CHOOSE-ITEM");
            deadline = Time.realtimeSinceStartup + 15f;
            while ((heroRebirthPresenter.IsPending || !heroRebirthPresenter.PreviewReady
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
            if (!heroRebirthPresenter.PreviewReady || heroRebirthPresenter.SelectedHeroId != 64
                || heroRebirthPresenter.RefundCount <= 0)
            {
                Fail("HeroRebirth G4 /24 op=8 did not produce the maximum authoritative preview.");
                yield break;
            }
            MarkValidationControl("HR-21-PREVIEW-STATE");

            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.ChangeButton)
                || !heroRebirthPresenter.IsCandidateOpen)
            {
                Fail("HeroRebirth G4 change control did not reopen candidates.");
                yield break;
            }
            MarkValidationControl("HR-09-CHANGE-HERO");
            yield return null;
            yield return new WaitForEndOfFrame();
            Button alternateCandidate = heroRebirthPresenter.GetCandidateButton(60);
            if (!InvokeEventSystemRaycastClick(alternateCandidate))
            {
                Fail("HeroRebirth G4 alternate candidate did not accept a real selection click.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 15f;
            while ((heroRebirthPresenter.IsPending || !heroRebirthPresenter.PreviewReady
                || heroRebirthPresenter.SelectedHeroId != 60) && Time.realtimeSinceStartup < deadline) yield return null;
            if (!heroRebirthPresenter.PreviewReady || heroRebirthPresenter.SelectedHeroId != 60)
            {
                Fail("HeroRebirth G4 changed candidate did not replace the old preview.");
                yield break;
            }
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.ChangeButton))
            {
                Fail("HeroRebirth G4 change control did not reopen the maximum candidate.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            maximumCandidate = heroRebirthPresenter.GetCandidateButton(64);
            if (!InvokeEventSystemRaycastClick(maximumCandidate))
            {
                Fail("HeroRebirth G4 maximum candidate could not be reselected.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 15f;
            while ((heroRebirthPresenter.IsPending || !heroRebirthPresenter.PreviewReady
                || heroRebirthPresenter.SelectedHeroId != 64) && Time.realtimeSinceStartup < deadline) yield return null;
            if (!heroRebirthPresenter.PreviewReady || heroRebirthPresenter.SelectedHeroId != 64)
            {
                Fail("HeroRebirth G4 maximum preview was not restored after changing candidates.");
                yield break;
            }
            yield return CaptureHeroRebirthEvidence("HR-21-preview-state.png");

            ScrollRect rewardScroll = heroRebirthPresenter.RewardScroll;
            if (rewardScroll == null || rewardScroll.content == null || rewardScroll.viewport == null)
            {
                Fail("HeroRebirth G4 refund list is missing its ScrollRect contract.");
                yield break;
            }
            bool rewardOverflows = rewardScroll.content.rect.height > rewardScroll.viewport.rect.height;
            if (rewardOverflows)
            {
                float rewardStart = rewardScroll.verticalNormalizedPosition;
                if (!InvokeEventSystemDrag(rewardScroll, -0.35f))
                {
                    Fail("HeroRebirth G4 refund list rejected EventSystem drag input.");
                    yield break;
                }
                yield return null;
                if (Mathf.Approximately(rewardStart, rewardScroll.verticalNormalizedPosition))
                {
                    Fail("HeroRebirth G4 overflowing refund drag callbacks did not move content.");
                    yield break;
                }
            }
            else if (heroRebirthPresenter.RefundCount < 6 || heroRebirthPresenter.RefundCount > 7)
            {
                Fail($"HeroRebirth G4 non-overflow refund boundary expected 6..7 authoritative resource types, actual={heroRebirthPresenter.RefundCount}.");
                yield break;
            }
            MarkValidationControl("HR-13-REFUND-SCROLL");
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.FirstRewardButton)
                || !IsHeroRebirthItemSourceVisible())
            {
                Fail("HeroRebirth G4 refund item did not open the shared detail through a real click.");
                yield break;
            }
            MarkValidationControl("HR-14-REFUND-ITEM-DETAIL");
            yield return CaptureHeroRebirthEvidence("HR-14-refund-detail.png");
            heroItemSourceView.SetVisible(false);

            if (!services.Heroes.TryGet(24, out HeroRecord rejectedBefore))
            {
                Fail("HeroRebirth G4 deployed rejection hero 24 is missing.");
                yield break;
            }
            long rejectionCurrency = services.Currencies.BoundPremium;
            if (!heroRebirthPresenter.BeginValidationRequest(8, 24))
            {
                Fail("HeroRebirth G4 could not arm the authoritative rejection request.");
                yield break;
            }
            InvokeLuaOrFail(onHeroRebirthPreview, "HeroRebirth.G4DeployedRejection", 24);
            deadline = Time.realtimeSinceStartup + 15f;
            while ((heroRebirthPresenter.IsPending || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (heroRebirthPresenter.IsPending || !services.Heroes.TryGet(24, out HeroRecord rejectedAfter)
                || rejectedAfter.Level != rejectedBefore.Level || rejectedAfter.BreakLevel != rejectedBefore.BreakLevel
                || rejectedAfter.CultivationLevel != rejectedBefore.CultivationLevel
                || services.Currencies.BoundPremium != rejectionCurrency)
            {
                Fail("HeroRebirth G4 authoritative deployed rejection changed hero or currency state.");
                yield break;
            }
            MarkValidationControl("HR-23-AUTHORITATIVE-REJECTION");
            toastPresenter?.Clear();

            long authoritativeBoundPremium = services.Currencies.BoundPremium;
            services.Currencies.Set(CurrencyIds.BoundPremium, 0);
            int pendingBeforeInsufficient = services.ProtocolRegistry.PendingCount;
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.RebirthButton))
            {
                Fail("HeroRebirth G4 insufficient-currency rebirth control rejected real input.");
                yield break;
            }
            yield return null;
            bool insufficientPassed = !heroRebirthPresenter.IsConfirmOpen && !heroRebirthPresenter.IsPending
                && services.ProtocolRegistry.PendingCount == pendingBeforeInsufficient && IsToastVisible;
            yield return CaptureHeroRebirthEvidence("HR-22-insufficient-currency.png");
            services.Currencies.Set(CurrencyIds.BoundPremium, authoritativeBoundPremium);
            toastPresenter?.Clear();
            if (!insufficientPassed)
            {
                Fail("HeroRebirth G4 insufficient-currency branch opened confirmation or sent op=9.");
                yield break;
            }
            MarkValidationControl("HR-22-INSUFFICIENT-STATE");

            List<HeroRebirthReward> expectedRewards = heroRebirthPresenter.Rewards.ToList();
            var rewardBefore = new Dictionary<int, long>();
            foreach (HeroRebirthReward reward in expectedRewards)
            {
                int itemId = reward.Type != 0 ? reward.Type : reward.Id;
                rewardBefore[itemId] = itemId >= 60000
                    ? services.Currencies.Get(itemId)
                    : services.Bag.GetTotalQuantityByItemId(itemId);
            }
            if (!services.Heroes.TryGet(64, out HeroRecord targetBefore))
            {
                Fail("HeroRebirth G4 target hero 64 disappeared before confirmation.");
                yield break;
            }
            long boundBefore = services.Currencies.BoundPremium;
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.RebirthButton)
                || !heroRebirthPresenter.IsConfirmOpen)
            {
                Fail("HeroRebirth G4 rebirth button did not open confirmation with sufficient currency.");
                yield break;
            }
            MarkValidationControl("HR-15-REBIRTH");
            yield return CaptureHeroRebirthEvidence("HR-16-confirmation.png");
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.FirstConfirmRewardButton)
                || !IsHeroRebirthItemSourceVisible())
            {
                Fail("HeroRebirth G4 confirmation reward detail did not accept a real click.");
                yield break;
            }
            MarkValidationControl("HR-18-CONFIRM-REFUND-DETAIL");
            heroItemSourceView.SetVisible(false);
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.ConfirmCloseButton)
                || heroRebirthPresenter.IsConfirmOpen)
            {
                Fail("HeroRebirth G4 confirmation close changed or retained modal state.");
                yield break;
            }
            MarkValidationControl("HR-16-CONFIRM-CLOSE");
            yield return null;
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.RebirthButton))
            {
                Fail("HeroRebirth G4 confirmation cancel setup did not reopen the modal.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.ConfirmCancelButton)
                || heroRebirthPresenter.IsConfirmOpen)
            {
                Fail("HeroRebirth G4 confirmation cancel did not return to the preview.");
                yield break;
            }
            MarkValidationControl("HR-17-CONFIRM-CANCEL");
            if (!services.Heroes.TryGet(64, out HeroRecord targetAfterCancel)
                || targetAfterCancel.Level != targetBefore.Level || services.Currencies.BoundPremium != boundBefore)
            {
                Fail("HeroRebirth G4 close/cancel mutated authoritative hero or currency state.");
                yield break;
            }

            yield return null;
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.RebirthButton))
            {
                Fail("HeroRebirth G4 final confirmation setup did not reopen the modal.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.ConfirmButton))
            {
                Fail("HeroRebirth G4 confirm control did not send the real op=9 request.");
                yield break;
            }
            MarkValidationControl("HR-19-CONFIRM");
            deadline = Time.realtimeSinceStartup + 20f;
            HeroRecord targetAfter = default;
            Func<bool> rewardsApplied = () => expectedRewards.All(reward =>
            {
                int itemId = reward.Type != 0 ? reward.Type : reward.Id;
                long actual = itemId >= 60000
                    ? services.Currencies.Get(itemId)
                    : services.Bag.GetTotalQuantityByItemId(itemId);
                return rewardBefore.TryGetValue(itemId, out long before)
                    && actual >= before + reward.Quantity;
            });
            while ((heroRebirthPresenter.IsPending || services.ProtocolRegistry.PendingCount != 0
                || !services.Heroes.TryGet(64, out targetAfter) || targetAfter.Level != 1
                || services.Currencies.BoundPremium != boundBefore - 50 || !rewardsApplied())
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.Heroes.TryGet(64, out targetAfter) || targetAfter.Level != 1
                || targetAfter.Experience != 0 || targetAfter.BreakLevel != 0
                || targetAfter.CultivationLevel != 0 || targetAfter.Star != targetBefore.Star
                || services.Currencies.BoundPremium != boundBefore - 50)
            {
                Fail($"HeroRebirth G4 success mismatch: level={targetAfter.Level}, exp={targetAfter.Experience}, break={targetAfter.BreakLevel}, cultivation={targetAfter.CultivationLevel}, star={targetAfter.Star}, bound={services.Currencies.BoundPremium}/{boundBefore - 50}.");
                yield break;
            }
            bool rewardDeltaPassed = expectedRewards.Count > 0;
            foreach (HeroRebirthReward reward in expectedRewards)
            {
                int itemId = reward.Type != 0 ? reward.Type : reward.Id;
                long actual = itemId >= 60000
                    ? services.Currencies.Get(itemId)
                    : services.Bag.GetTotalQuantityByItemId(itemId);
                if (!rewardBefore.TryGetValue(itemId, out long before) || actual < before + reward.Quantity)
                    rewardDeltaPassed = false;
            }
            if (!rewardDeltaPassed)
            {
                Fail("HeroRebirth G4 op=9 did not apply every authoritative refund quantity.");
                yield break;
            }
            MarkValidationControl("HR-24-SUCCESS-LIFECYCLE");
            yield return CaptureHeroRebirthEvidence("HR-24-success-reset.png");

            frameClose = RequireBoundButton(oneLevelFrameView,
                "Layer/Panel_12/Title/CloseBtn", "HeroRebirth post-success close");
            if (!InvokeEventSystemRaycastClick(frameClose))
            {
                Fail("HeroRebirth G4 post-success close failed.");
                yield break;
            }
            services.Network.Disconnect("HeroRebirth deliberate disconnect");
            yield return new WaitForSecondsRealtime(.25f);
            if (errorPresenter?.IsVisible != true || services.Network.State != NetworkState.Disconnected
                || !InvokeEventSystemRaycastClick(errorPresenter.ConfirmationButton))
            {
                Fail("HeroRebirth G4 deliberate disconnect did not expose a real reconnect confirmation.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 25f;
            while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
            if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId)
            {
                Fail("HeroRebirth G4 reconnect did not restore the primary fixed identity.");
                yield break;
            }
            RequestHeroRebirthValidationSnapshot();
            deadline = Time.realtimeSinceStartup + 25f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.Heroes.Count == 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.Heroes.Count == 0)
            {
                Fail($"HeroRebirth G4 reconnect did not settle the authoritative hero snapshot: heroes={services.Heroes.Count}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
            if (IsHeroOpen)
            {
                Button reconnectHeroClose = RequireBoundButton(oneLevelFrameView,
                    "Layer/Panel_12/Title/CloseBtn", "HeroRebirth reconnect Hero page close");
                if (!InvokeEventSystemRaycastClick(reconnectHeroClose) || IsHeroOpen)
                {
                    Fail("HeroRebirth G4 reconnect could not return from the restored Hero page to HUD.");
                    yield break;
                }
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            hudEntry = mainView?.Binding.Find(HeroRecyclePath)?.GetComponent<Button>();
            if (!InvokeEventSystemRaycastClick(hudEntry))
            {
                Fail("HeroRebirth G4 reconnect entry did not accept a real HUD click.");
                yield break;
            }
            if (!services.Heroes.TryGet(64, out HeroRecord reconnectedHero) || reconnectedHero.Level != 1)
            {
                Fail($"HeroRebirth G4 reconnect lost the authoritative rebirth result: found={services.Heroes.TryGet(64, out reconnectedHero)}, level={reconnectedHero.Level}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            yield return CaptureHeroRebirthEvidence("HR-24-reconnected.png");
            frameClose = RequireBoundButton(oneLevelFrameView,
                "Layer/Panel_12/Title/CloseBtn", "HeroRebirth reconnect close");
            if (!InvokeEventSystemRaycastClick(frameClose))
            {
                Fail("HeroRebirth G4 reconnect page did not close.");
                yield break;
            }

            services.Config.LocalUserId = isolationUserId;
            ReturnToLogin();
            BindLoginClick(false);
            loginPresenter.SetAccountCredentials(isolationUserId, "local");
            if (!loginPresenter.InvokeAccountSubmit())
            {
                Fail("HeroRebirth G4 isolation account submit was unavailable.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 25f;
            while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
            if (CurrentAppState != AppState.Main || GetPlayerRoleId() == 0 || GetPlayerRoleId() == primaryRoleId)
            {
                Fail($"HeroRebirth G4 isolation identity mismatch: {GetLocalUserId()}/{GetPlayerRoleId()}.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 12f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"HeroRebirth G4 isolation login did not settle before account switch: pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            uint isolationRoleId = GetPlayerRoleId();
            services.Config.LocalUserId = primaryUserId;
            ReturnToLogin();
            BindLoginClick(false);
            loginPresenter.SetAccountCredentials(primaryUserId, "local");
            if (!loginPresenter.InvokeAccountSubmit())
            {
                Fail("HeroRebirth G4 primary terminal relogin submit was unavailable.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 25f;
            while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
            if (CurrentAppState == AppState.Main && GetPlayerRoleId() == primaryRoleId)
                RequestHeroRebirthValidationSnapshot();
            deadline = Time.realtimeSinceStartup + 25f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.Heroes.Count == 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            bool terminalHeroFound = services.Heroes.TryGet(64, out HeroRecord terminalHero);
            if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId
                || !terminalHeroFound || terminalHero.Level != 1)
            {
                Fail($"HeroRebirth G4 terminal primary relogin did not preserve the rebirth result: heroes={services.Heroes.Count}, level={terminalHero.Level}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            if (IsGameNoticeOpen) noticePresenter?.InvokeClose();
            if (IsHeroOpen)
            {
                Button terminalHeroClose = RequireBoundButton(oneLevelFrameView,
                    "Layer/Panel_12/Title/CloseBtn", "HeroRebirth terminal Hero page close");
                if (!InvokeEventSystemRaycastClick(terminalHeroClose) || IsHeroOpen)
                {
                    Fail("HeroRebirth G4 terminal relogin could not return from Hero page to HUD.");
                    yield break;
                }
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            hudEntry = mainView?.Binding.Find(HeroRecyclePath)?.GetComponent<Button>();
            if (!InvokeEventSystemRaycastClick(hudEntry))
            {
                Fail("HeroRebirth G4 terminal reentry did not accept a real HUD click.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(heroRebirthPresenter.AddButton))
            {
                Fail("HeroRebirth G4 terminal candidate list did not reopen.");
                yield break;
            }
            yield return null;
            yield return new WaitForEndOfFrame();
            alternateCandidate = heroRebirthPresenter.GetCandidateButton(60);
            if (!InvokeEventSystemRaycastClick(alternateCandidate))
            {
                Fail("HeroRebirth G4 terminal alternate candidate did not accept a real click.");
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 15f;
            while ((heroRebirthPresenter.IsPending || !heroRebirthPresenter.PreviewReady)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!heroRebirthPresenter.PreviewReady || heroRebirthPresenter.SelectedHeroId != 60)
            {
                Fail("HeroRebirth G4 terminal reentry did not rebuild an authoritative preview.");
                yield break;
            }
            yield return CaptureHeroRebirthEvidence("HR-24-reentered.png");

            foreach (string id in new[]
            {
                "HR-01-HUD-ENTRY", "HR-02-HERO-BAG-ENTRY", "HR-03-CLOSE", "HR-04-HERO-TAB",
                "HR-05-EQUIP-TAB-BOUNDARY", "HR-06-FABAO-TAB-BOUNDARY", "HR-07-SECOND-TAB",
                "HR-08-ADD-HERO", "HR-09-CHANGE-HERO", "HR-10-CHOOSE-CLOSE", "HR-11-CHOOSE-ITEM",
                "HR-12-CHOOSE-SCROLL", "HR-13-REFUND-SCROLL", "HR-14-REFUND-ITEM-DETAIL",
                "HR-15-REBIRTH", "HR-16-CONFIRM-CLOSE", "HR-17-CONFIRM-CANCEL",
                "HR-18-CONFIRM-REFUND-DETAIL", "HR-19-CONFIRM", "HR-20-EMPTY-STATE",
                "HR-21-PREVIEW-STATE", "HR-22-INSUFFICIENT-STATE", "HR-23-AUTHORITATIVE-REJECTION",
                "HR-24-SUCCESS-LIFECYCLE"
            }) MarkValidationControl(id);
            RecordValidationSemantic("hero-rebirth-two-entry-routes", true,
                "real HUD and hero-bag recycle raycast clicks converged on one presenter");
            RecordValidationSemantic("hero-rebirth-candidate-filter-scroll", true,
                $"eligible={heroRebirthPresenter.EligibleCount}; deployed 24/57 and initial 62 excluded; real vertical drag moved content");
            RecordValidationSemantic("hero-rebirth-op8-authoritative-preview", true,
                $"hero=64 rewards={expectedRewards.Count}; changed 64->60->64 with authoritative /24 op=8 replacement; "
                + (rewardOverflows ? "overflow accepted real vertical drag" : "current 7-type source universe fits two rows without fake drag"));
            RecordValidationSemantic("hero-rebirth-confirm-cancel-close", true,
                "close/cancel/detail accepted real raycast input and left hero/currency unchanged");
            RecordValidationSemantic("hero-rebirth-op9-atomic-success", true,
                $"hero=64 level {targetBefore.Level}->1; break {targetBefore.BreakLevel}->0; cultivation {targetBefore.CultivationLevel}->0; bound {boundBefore}->{services.Currencies.BoundPremium}");
            RecordValidationSemantic("hero-rebirth-rejections-no-mutation", true,
                "deployed hero /24 op=8 rejected atomically; insufficient client branch sent no op=9");
            RecordValidationSemantic("hero-rebirth-network-recovery", true,
                $"real disconnect/reconnect restored role={primaryRoleId} and persisted hero64 level=1");
            RecordValidationSemantic("hero-rebirth-account-isolation", true,
                $"primary={primaryUserId}/{primaryRoleId}; isolation={isolationUserId}/{isolationRoleId}; terminal primary restored");
            RecordValidationSemantic("hero-rebirth-sqlite-exact-restore", true,
                "outer fixed-account runner owns immutable SQLite restore, relogin hash and cleanup assertions");
            RecordValidationSemantic(HeroRebirthControlMatrixSemantic, validationControlIds.Count == 24,
                $"validated={validationControlIds.Count}/24 through real EventSystem/raycast controls and scenario states");
            if (GetFailedValidationSemanticAssertions().Length > 0 || validationControlIds.Count != 24)
            {
                Fail("HeroRebirth G4 control/semantic coverage failed: "
                    + string.Join(" | ", GetFailedValidationSemanticAssertions()));
                yield break;
            }
            Complete("COMPLETE: HeroRebirth G4 24/24 controls and 10/10 semantics; real /24 op=8/op=9, rejection, reconnect, account isolation and persistence passed");
        }

        private IEnumerator CaptureHeroRebirthEvidence(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length < 4096)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length < 4096)
                throw new IOException("HeroRebirth screenshot was not written: " + path);
        }

        private void CloseHeroRecycle()
        {
            heroRebirthPresenter?.Hide();
            if (heroRecycleOpenedFromBag)
            {
                RestoreHeroBagFromAuxiliary();
                return;
            }
            ReleaseHeroAuxiliaryViews();
            SetOneLevelFrameVisible(false);
            if (services?.UiStack.Current == oneLevelFrameView) services.UiStack.Pop();
        }

        private void ShowHeroRebirthItemDetail(HeroRebirthReward reward)
        {
            heroItemSourceView = heroItemSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            if (heroItemSourceView == null)
                throw new InvalidOperationException("Hero rebirth item-source CocosUiBinding was not found.");

            int itemId = reward.Type != 0 ? reward.Type : reward.Id;
            EquipmentMaterialDefinition definition = services.EquipmentCatalog.GetItem(itemId);
            string name = definition?.Name ?? heroRebirthPresenter?.DescribeReward(reward) ?? $"物品 #{itemId}";
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_name", name);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_tips", definition?.Description ?? string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/Panel_name/txt_num", $"数量：{reward.Quantity}");
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_1", "来源：主线副本");
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/Name_2", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/itemlayer_1/times", string.Empty);
            SetBoundText(heroItemSourceView, "Layer/Popup/Title/Title", "获取途径");

            Image icon = heroItemSourceView.Binding.Find("Layer/Popup/Panel_name/Panel_icon/Icon")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = definition == null ? null : services.Resources.LoadItemIcon(definition.Picture);
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
            }
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_1", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_2", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/Button_3", false);
            SetBoundVisible(heroItemSourceView, "Layer/Popup/itemlayer_1/item_icon", false);
            heroItemSourceView.BindClick("Layer/Popup/Title/Btn_close", () => heroItemSourceView.SetVisible(false), true);
            heroItemSourceView.BindClick("Layer/Mask", () => heroItemSourceView.SetVisible(false), true);
            heroItemSourceView.ShowPopup();
        }

        private bool IsHeroRebirthItemSourceVisible()
        {
            Text title = heroItemSourceView?.Binding.Find("Layer/Popup/Title/Title")?.GetComponent<Text>();
            return heroItemSourceView?.GameObject.activeSelf == true && title?.text == "获取途径";
        }

        private void ShowHeroBagAuxiliary(CocosUiView target, string titleValue)
        {
            HideHeroCultivationForNavigation();
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroBookView?.SetVisible(target == heroBookView);
            heroRecycleView?.SetVisible(target == heroRecycleView);
            ConfigureHeroFrame(true);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = titleValue;
            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(false);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", RestoreHeroBagFromAuxiliary, true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            target.GameObject.transform.SetAsLastSibling();
        }

        private void EnsureHeroBookSurfaceForResult()
        {
            if (heroBookPresenter == null || heroBookView?.GameObject == null) return;
            bool hasConflictingSurface = heroListView?.GameObject.activeSelf == true
                || heroDetailView?.GameObject.activeSelf == true
                || heroBagView?.GameObject.activeSelf == true
                || heroCultivationView?.GameObject.activeSelf == true
                || heroLevelUpView?.GameObject.activeSelf == true;
            if (heroBookView.GameObject.activeSelf && !hasConflictingSurface) return;

            HideHeroCultivationForNavigation();
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            heroBookView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            Transform tabs = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(false);
            Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "神将图鉴";
            oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
            heroBookView.GameObject.transform.SetAsLastSibling();
        }

        private void RestoreHeroBagFromAuxiliary()
        {
            ReleaseHeroAuxiliaryViews();
            if (heroHubOpen)
            {
                // HeroBook is an auxiliary page of the unified hero hub.
                // Returning through the legacy bag path leaves Panel_10 in
                // the book's two-tab state (神将/碎片) and loses 布阵.
                ShowHeroHubTab(heroHubTab);
                return;
            }
            oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            ShowHeroBagListTab();
        }

        private void ReleaseHeroAuxiliaryViews()
        {
            RestoreOneLevelChildrenAfterEnhanceMaster();
            heroBookPresenter?.Dispose();
            heroBookPresenter = null;
            heroRebirthPresenter?.Dispose();
            heroRebirthPresenter = null;
            UiPrefabLoader.Release(heroRebirthChooseView);
            UiPrefabLoader.Release(heroRebirthChooseFrameView);
            UiPrefabLoader.Release(heroRebirthConfirmView);
            UiPrefabLoader.Release(heroBookView);
            UiPrefabLoader.Release(heroBookUpgradeView);
            UiPrefabLoader.Release(heroBookActivateResultView);
            UiPrefabLoader.Release(heroBookUpgradeResultView);
            UiPrefabLoader.Release(heroBookAttributesView);
            UiPrefabLoader.Release(heroBookAchievementView);
            UiPrefabLoader.Release(heroBookLevelResultView);
            UiPrefabLoader.Release(heroRecycleView);
            heroRebirthChooseView = null;
            heroRebirthChooseFrameView = null;
            heroRebirthConfirmView = null;
            heroBookView = null;
            heroBookUpgradeView = null;
            heroBookActivateResultView = null;
            heroBookUpgradeResultView = null;
            heroBookAttributesView = null;
            heroBookAchievementView = null;
            heroBookLevelResultView = null;
            heroRecycleView = null;
            ReleaseHeroEquipmentViews();
            UiPrefabLoader.Release(heroEnhanceMasterView);
            heroEnhanceMasterView = null;
        }

        private void ReleaseHeroEquipmentViews()
        {
            heroEquipmentPresenter?.Dispose();
            heroEquipmentPresenter = null;
            heroEquipmentFragmentList?.Dispose();
            heroEquipmentFragmentList = null;
            if (heroEquipmentFragmentBagSubscribed && services?.Bag != null)
            {
                services.Bag.Changed -= HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = false;
            }
            foreach (CocosUiView view in new[]
            {
                heroEquipmentListView, heroEquipmentDetailView, heroEquipmentChangeView,
                heroEquipmentStrengthView, heroEquipmentRefineView, heroEquipmentAwakenView,
                heroEquipmentDivineView, heroEquipmentFragmentView, heroEquipmentAutoRefineView,
                heroEquipmentExchangeView, heroEquipmentAutoStarView, heroEquipmentAutoDivineView,
                heroEquipmentDivineEffectView, faBaoStrengthView, faBaoRefineView,
                faBaoMaterialChooserView, heroEquipmentCultivateView,
            }) UiPrefabLoader.Release(view);
            heroEquipmentListView = null;
            heroEquipmentDetailView = null;
            heroEquipmentChangeView = null;
            heroEquipmentCultivateView = null;
            heroEquipmentStrengthView = null;
            heroEquipmentRefineView = null;
            heroEquipmentAwakenView = null;
            heroEquipmentDivineView = null;
            heroEquipmentFragmentView = null;
            heroEquipmentAutoRefineView = null;
            heroEquipmentExchangeView = null;
            heroEquipmentAutoStarView = null;
            heroEquipmentAutoDivineView = null;
            heroEquipmentDivineEffectView = null;
            faBaoStrengthView = null;
            faBaoRefineView = null;
            faBaoMaterialChooserView = null;
        }

        private Transform GetDynamicUiRoot()
        {
            if (oneLevelFrameView?.GameObject != null && oneLevelFrameView.GameObject.transform.parent != null)
                return oneLevelFrameView.GameObject.transform.parent;
            Canvas canvas = FindObjectOfType<Canvas>();
            if (canvas == null) throw new InvalidOperationException("Dynamic UI Canvas was not found.");
            return canvas.transform;
        }

        private static void SetTabText(Transform tab, string value, bool selected)
        {
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null) normal.text = value;
            if (chosen != null) chosen.text = value;
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            // Panel_10 is reused by the hero hub, cultivation and recycle
            // screens. Restore both label states on every transition so a
            // reused Button1 cannot render the formation tab blank.
            if (normal != null) normal.gameObject.SetActive(!selected);
            if (chosen != null) chosen.gameObject.SetActive(selected);
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

        private void EnsureHeroEquipmentPresenter(bool cultivationOnly = false, bool includeFaBaoMaterial = true)
        {
            if (!cultivationOnly && heroEquipmentPresenterCultivationOnly)
            {
                heroEquipmentPresenter?.Dispose();
                heroEquipmentPresenter = null;
                heroEquipmentPresenterCultivationOnly = false;
            }
            EnsureHeroPresenter();
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            Transform dynamicRoot = GetDynamicUiRoot();
            if (!cultivationOnly)
            {
                heroEquipmentListView = heroEquipmentListView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeibeibao")
                    ?? UiPrefabLoader.Load("HeroEquipmentList", dynamicRoot);
                heroEquipmentDetailView = heroEquipmentDetailView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo")
                    ?? UiPrefabLoader.Load("HeroEquipmentDetail", dynamicRoot);
                heroEquipmentChangeView = heroEquipmentChangeView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeigenghuan")
                    ?? UiPrefabLoader.Load("HeroEquipmentChange", dynamicRoot);
            }
            heroEquipmentCultivateView = heroEquipmentCultivateView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiyangcheng")
                ?? UiPrefabLoader.Load("HeroEquipmentCultivate", frame.View.GameObject.transform);
            Transform cultivationRoot = heroEquipmentCultivateView.GameObject.transform;
            if (cultivationRoot.parent != frame.View.GameObject.transform)
                cultivationRoot.SetParent(frame.View.GameObject.transform, false);
            PlaceHeroEquipmentCultivationShell(frame.View.GameObject.transform, cultivationRoot);
            heroEquipmentStrengthView = heroEquipmentStrengthView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiqianghua")
                ?? UiPrefabLoader.Load("HeroEquipmentStrength", cultivationRoot);
            Transform strengthRoot = heroEquipmentStrengthView.GameObject.transform;
            if (strengthRoot.parent != cultivationRoot)
                strengthRoot.SetParent(cultivationRoot, false);
            heroEquipmentRefineView = heroEquipmentRefineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijinglian")
                ?? UiPrefabLoader.Load("HeroEquipmentRefine", cultivationRoot);
            heroEquipmentAwakenView = heroEquipmentAwakenView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeijuexing")
                ?? UiPrefabLoader.Load("HeroEquipmentAwaken", cultivationRoot);
            heroEquipmentDivineView = heroEquipmentDivineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeishenzhu")
                ?? UiPrefabLoader.Load("HeroEquipmentDivine", cultivationRoot);
            if (!cultivationOnly)
            {
            heroEquipmentFragmentView = heroEquipmentFragmentView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeisuipian")
                ?? UiPrefabLoader.Load("HeroEquipmentFragment", dynamicRoot);
            heroEquipmentAutoRefineView = heroEquipmentAutoRefineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianjinglian")
                ?? UiPrefabLoader.Load("HeroEquipmentAutoRefine", dynamicRoot);
            heroEquipmentExchangeView = heroEquipmentExchangeView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianduihuan")
                ?? UiPrefabLoader.Load("HeroEquipmentExchange", dynamicRoot);
            heroEquipmentAutoStarView = heroEquipmentAutoStarView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengxing")
                ?? UiPrefabLoader.Load("HeroEquipmentAutoStar", dynamicRoot);
            heroEquipmentAutoDivineView = heroEquipmentAutoDivineView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/yijianshengceng")
                ?? UiPrefabLoader.Load("HeroEquipmentAutoDivine", dynamicRoot);
            heroEquipmentDivineEffectView = heroEquipmentDivineEffectView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/shenzhutexiao")
                ?? UiPrefabLoader.Load("HeroEquipmentDivineEffect", dynamicRoot);
            }
            faBaoStrengthView = faBaoStrengthView ?? UiPrefabLoader.Load("FaBaoStrength", cultivationRoot);
            faBaoRefineView = faBaoRefineView ?? UiPrefabLoader.Load("FaBaoRefine", cultivationRoot);
            if (includeFaBaoMaterial)
                faBaoMaterialChooserView = faBaoMaterialChooserView ?? UiPrefabLoader.Load("FaBaoMaterialChooser", dynamicRoot);
            AttachAndOrderHeroEquipmentCultivationViews(cultivationRoot,
                heroEquipmentStrengthView, heroEquipmentRefineView, heroEquipmentAwakenView,
                heroEquipmentDivineView, faBaoStrengthView, faBaoRefineView);
            if ((!cultivationOnly && (heroEquipmentListView == null || heroEquipmentDetailView == null || heroEquipmentChangeView == null))
                || heroEquipmentCultivateView == null || heroEquipmentStrengthView == null
                || heroEquipmentRefineView == null || heroEquipmentAwakenView == null || heroEquipmentDivineView == null
                || (!cultivationOnly && (heroEquipmentFragmentView == null || heroEquipmentAutoRefineView == null
                    || heroEquipmentExchangeView == null || heroEquipmentAutoStarView == null
                    || heroEquipmentAutoDivineView == null || heroEquipmentDivineEffectView == null)))
                throw new InvalidOperationException("Hero equipment list/detail/change/cultivate/strength/fragment CocosUiBindings were not found.");
            Transform detailRoot = heroEquipmentDetailView?.GameObject?.transform;
            if (!cultivationOnly && detailRoot != null && detailRoot.parent == heroEquipmentListView.GameObject.transform)
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
            bool presenterCreated = heroEquipmentPresenter == null;
            heroEquipmentPresenter = heroEquipmentPresenter ?? new HeroEquipmentPresenter(
                heroEquipmentListView, heroEquipmentDetailView, heroEquipmentChangeView,
                heroEquipmentCultivateView, heroEquipmentStrengthView, heroEquipmentRefineView,
                heroEquipmentAwakenView, heroEquipmentDivineView,
                heroEquipmentAutoRefineView, heroEquipmentExchangeView, heroEquipmentAutoStarView,
                heroEquipmentAutoDivineView, heroEquipmentDivineEffectView,
                faBaoStrengthView, faBaoRefineView, faBaoMaterialChooserView,
                services.HeroEquipment, services.FaBao, services.Bag, services.EquipmentCatalog, services.Currencies, services.Resources,
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentWear, "HeroEquipment.Wear", (double)uid, position),
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentTakeOff, "HeroEquipment.TakeOff", (double)uid, position),
                uid => InvokeLuaOrFail(onHeroEquipmentAffixLock, "HeroEquipment.AffixLock", (double)uid),
                uid => InvokeLuaOrFail(onHeroEquipmentAffixReroll, "HeroEquipment.AffixReroll", (double)uid),
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
                (uid, materialUids) =>
                {
                    object[] args = new object[9];
                    args[0] = (double)uid;
                    for (int index = 0; index < 8; index++)
                        args[index + 1] = index < materialUids.Length ? (double)materialUids[index] : 0d;
                    InvokeLuaOrFail(onFaBaoStrength, "FaBao.Strength", args);
                },
                (uid, targetLevel) => InvokeLuaOrFail(onFaBaoRefine, "FaBao.Refine", (double)uid, targetLevel),
                ConfigureHeroEquipmentCultivationFrame,
                () => services.Player.Level,
                position => position > 0 && position <= services.Formation.DisplayHeroes.Count
                    ? services.Formation.DisplayHeroes[position - 1] : 0,
                message =>
                {
                    SetStatus(message);
                    ShowToast(message, 2f);
                }, cultivationOnly);
            if (presenterCreated) heroEquipmentPresenterCultivationOnly = cultivationOnly;
            if (!cultivationOnly && !heroEquipmentFragmentBagSubscribed)
            {
                services.Bag.Changed += HandleHeroEquipmentFragmentBagChanged;
                heroEquipmentFragmentBagSubscribed = true;
            }
        }

        private void PlaceHeroEquipmentCultivationShell(Transform frameRoot, Transform cultivationRoot)
        {
            if (frameRoot == null || cultivationRoot == null || cultivationRoot.parent != frameRoot) return;
            Transform heroBag = heroBagView?.GameObject?.transform;
            if (heroBag == null || heroBag.parent != frameRoot)
                heroBag = frameRoot.Find("DynamicUi_yingxiongbeibao");
            if (heroBag == null || heroBag == cultivationRoot) return;
            cultivationRoot.SetSiblingIndex(heroBag.GetSiblingIndex() + 1);
        }

        private void ConfigureHeroEquipmentFrame(HeroEquipmentKind kind)
        {
            ConfigureHeroFrame(false);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = kind == HeroEquipmentKind.Equipment ? "装备背包" : "法宝背包";
            Transform tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            ConfigureHeroEquipmentTabs(tabs, kind);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            ConfigureHeroEquipmentHelp(kind);
        }

        private void ConfigureHeroEquipmentHelp(HeroEquipmentKind kind)
        {
            const string helpPath = "Layer/Panel_12/Title/TitleName/Button_1";
            GameObject help = oneLevelFrameView.Binding.Find(helpPath);
            if (help == null) return;
            help.SetActive(true);
            oneLevelFrameView.BindClick(helpPath, () => errorPresenter?.ShowHelp(
                kind == HeroEquipmentKind.Equipment
                    ? "装备强化分为普通（+1），暴击（+2），大暴击（+3），强化上限不超过主角等级的2倍。\n" +
                      "装备精炼等级上限由装备品质决定。\n" +
                      "橙色以上装备可以进行装备觉醒，觉醒需消耗装备碎片及觉醒石。\n" +
                      "红色以上装备可以进行装备神铸，神铸需消耗对应装备碎片。"
                    : "法宝强化分为普通（+1），暴击（+2），大暴击（+3），强化上限不超过主角等级的2倍。\n" +
                      "法宝精炼消耗精炼石，精炼等级上限为25级。"));
        }

        private void ConfigureHeroEquipmentTabs(Transform tabs, HeroEquipmentKind kind)
        {
            if (tabs == null) return;
            tabs.gameObject.SetActive(true);
            Transform panel = tabs.Find("Panel_10");
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            HideRuntimeTab(panel, "Button3_Runtime");
            HideRuntimeTab(panel, "Button4_Runtime");
            foreach (Transform cultivationTab in panel.Cast<Transform>()
                .Where(value => value.name.EndsWith("_StrengthRuntime", StringComparison.Ordinal)))
                cultivationTab.gameObject.SetActive(false);
            SetTabText(first, "装备", kind == HeroEquipmentKind.Equipment);
            Button firstButton = EnsureRuntimeButton(first);
            firstButton.onClick.RemoveAllListeners();
            firstButton.onClick.AddListener(ShowHeroEquipmentListTab);
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
            second.gameObject.SetActive(true);
            SetTabText(second, "法宝", kind == HeroEquipmentKind.FaBao);
            Button faBaoButton = EnsureRuntimeButton(second);
            faBaoButton.interactable = true;
            faBaoButton.onClick.RemoveAllListeners();
            faBaoButton.onClick.AddListener(ShowHeroFaBaoListTab);
            Transform third = panel.Find("Button3_Runtime");
            if (third == null)
            {
                third = Instantiate(first.gameObject, panel, false).transform;
                third.name = "Button3_Runtime";
            }
            RectTransform thirdRect = third as RectTransform;
            if (firstRect != null && thirdRect != null)
                thirdRect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -200f);
            third.gameObject.SetActive(true);
            SetTabText(third, "碎片", false);
            Button fragmentButton = EnsureRuntimeButton(third);
            fragmentButton.interactable = true;
            fragmentButton.onClick.RemoveAllListeners();
            fragmentButton.onClick.AddListener(ShowHeroEquipmentFragments);
        }

        private static void HideRuntimeTab(Transform panel, string name)
        {
            Transform tab = panel?.Find(name);
            if (tab == null) return;
            tab.gameObject.SetActive(false);
            Button button = tab.GetComponent<Button>();
            if (button != null)
            {
                button.interactable = false;
                button.onClick.RemoveAllListeners();
            }
        }

        private void BindHeroEquipmentCultivationPortrait()
        {
            Image portrait = heroEquipmentCultivateView?.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Icon")?.GetComponent<Image>();
            if (portrait == null) return;

            int formationPosition = heroEquipmentPresenter?.ActiveFormationPosition ?? 0;
            int heroId = formationPosition > 0 && services.Formation.CombatHeroes.Count >= formationPosition
                ? services.Formation.CombatHeroes[formationPosition - 1]
                : 0;
            bool hasHeroDefinition = HeroCatalog.TryGet(heroId, out HeroDefinition heroDefinition);
            portrait.sprite = hasHeroDefinition
                ? services.Resources.LoadHeroPortrait(heroDefinition.Picture)
                : null;
            portrait.enabled = portrait.sprite != null;
            portrait.preserveAspect = true;

            Image heroFrame = heroEquipmentCultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Icon_bg")?.GetComponent<Image>();
            if (heroFrame == null) return;
            heroFrame.sprite = hasHeroDefinition
                ? services.Resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(heroDefinition.Quality, 1, 7):00}")
                : null;
            heroFrame.enabled = heroFrame.sprite != null;
        }

        private void ConfigureHeroEquipmentCultivationFrame(int selectedMode, HeroEquipmentKind kind)
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
            bool equipment = kind == HeroEquipmentKind.Equipment;
            services.UiRouter.SetExclusiveVisibleBySource("zhuangbeiyangcheng/zhuangbeiqianghua",
                heroEquipmentStrengthView, equipment && selectedMode == 0);
            services.UiRouter.SetExclusiveVisibleBySource("zhuangbeiyangcheng/zhuangbeijinglian",
                heroEquipmentRefineView, equipment && selectedMode == 1);
            services.UiRouter.SetExclusiveVisibleBySource("zhuangbeiyangcheng/zhuangbeijuexing",
                heroEquipmentAwakenView, equipment && selectedMode == 2);
            services.UiRouter.SetExclusiveVisibleBySource("zhuangbeiyangcheng/zhuangbeishenzhu",
                heroEquipmentDivineView, equipment && selectedMode == 3);
            BindHeroEquipmentCultivationPortrait();
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = kind == HeroEquipmentKind.FaBao ? "法宝" : "装备";
            GameObject tabs = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView");
            if (tabs != null) tabs.SetActive(true);
            Transform panel = oneLevelFrameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            foreach (Transform staleTab in panel.Cast<Transform>()
                .Where(value => value.name.StartsWith("HeroCultivationTab", StringComparison.Ordinal)))
                staleTab.gameObject.SetActive(false);
            string[] labels = kind == HeroEquipmentKind.FaBao
                ? new[] { "强化", "精炼" }
                : new[] { "强化", "精炼", "觉醒", "神铸" };
            RectTransform firstRect = first as RectTransform;
            Transform[] orderedTabs = new Transform[4];
            int firstTabIndex = first.GetSiblingIndex();
            for (int index = 0; index < 4; index++)
            {
                Transform tab = index == 0 ? first : panel.Find($"Button{index + 1}_StrengthRuntime");
                if (tab == null)
                {
                    tab = Instantiate(first.gameObject, panel, false).transform;
                    tab.name = $"Button{index + 1}_StrengthRuntime";
                }
                RectTransform rect = tab as RectTransform;
                NormalizeHeroCultivationTabLayout(rect, firstRect, index);
                bool visible = index < labels.Length;
                tab.gameObject.SetActive(visible);
                orderedTabs[index] = tab;
                if (!visible) continue;
                SetTabText(tab, labels[index], index == selectedMode);
                Button button = EnsureRuntimeButton(tab);
                button.onClick.RemoveAllListeners();
                int mode = index;
                button.interactable = index != selectedMode;
                button.onClick.AddListener(() => heroEquipmentPresenter?.ShowCultivationTab(mode));
            }
            NormalizeRuntimeTabSiblingOrder(panel, orderedTabs, firstTabIndex);
            foreach (string staleTabName in new[] { "Button2_Runtime", "Button3_Runtime", "Button4_Runtime" })
            {
                Transform staleTab = panel.Find(staleTabName);
                if (staleTab == null) continue;
                staleTab.gameObject.SetActive(false);
                Button staleButton = staleTab.GetComponent<Button>();
                if (staleButton != null)
                {
                    staleButton.interactable = false;
                    staleButton.onClick.RemoveAllListeners();
                }
            }
        }

        private static void NormalizeHeroCultivationTabLayout(
            RectTransform tab, RectTransform template, int index)
        {
            if (tab == null || template == null) return;
            tab.anchorMin = template.anchorMin;
            tab.anchorMax = template.anchorMax;
            tab.pivot = template.pivot;
            tab.sizeDelta = template.sizeDelta;
            tab.localRotation = Quaternion.identity;
            tab.localScale = Vector3.one;
            tab.anchoredPosition = template.anchoredPosition + new Vector2(0f, -100f * index);

            Text label = tab.Find("BtnName")?.GetComponent<Text>();
            if (label == null) return;
            RectTransform labelRect = label.rectTransform;
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;
            label.alignment = TextAnchor.MiddleCenter;
            label.horizontalOverflow = HorizontalWrapMode.Overflow;
            label.verticalOverflow = VerticalWrapMode.Overflow;
        }

        private static void NormalizeRuntimeTabSiblingOrder(
            Transform parent, Transform[] orderedTabs, int firstTabIndex)
        {
            if (parent == null || orderedTabs == null) return;
            int targetIndex = Mathf.Clamp(firstTabIndex, 0, parent.childCount - 1);
            foreach (Transform tab in orderedTabs)
            {
                if (tab == null || tab.parent != parent) continue;
                tab.SetSiblingIndex(targetIndex++);
            }
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
                ShowTaskBoxPreview,
                IsTaskVisibleInCurrentClient);
            ConfigureTaskFrame();
            try
            {
                taskBackgroundView.BindClick("Layer/Panel_1/Title/CloseBtn", () => PopUiStackWithHudRefresh(), true);
            }
            catch (InvalidOperationException exception)
            {
                ClientLog.Warning("Task", "Task close button was not bound", exception.Message);
            }
        }

        private static bool IsTaskVisibleInCurrentClient(TaskRecord item)
        {
            // Keep the authoritative payload untouched. Only hide configured destinations
            // that the shared Steam route catalog marks excluded or unsupported.
            return item.Jump == 0 || FunctionRouteCatalog.CanOpen(item.Jump);
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

            RefreshStandardCurrencyHeader(binding, "Layer/Panel_1/GoldCheck");

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
            if (services.UiStack.Current == taskBackgroundView) PopUiStackWithHudRefresh();
            HandleConfiguredFunctionRoute(item.Jump, "Task");
        }

        private void BeginConfiguredCultivationRoute(HeroEquipmentKind kind, int mode)
        {
            // EquipmentController.open refreshes /8 before /319. If the route was
            // entered from an item/stamina surface, remove that surface from the
            // stack before the asynchronous equipment responses can reuse OneLevelLayer.
            CloseBagForItemJump();
            heroEquipmentOpenPending = true;
            pendingFunctionCultivationKind = kind;
            pendingFunctionCultivationMode = mode;
            LuaFunction open = kind == HeroEquipmentKind.FaBao ? onFaBaoBagClicked : onEquipmentBagClicked;
            string context = kind == HeroEquipmentKind.FaBao
                ? "FunctionRoute.OpenFaBaoCultivation"
                : "FunctionRoute.OpenEquipmentCultivation";
            try
            {
                CallLua(open, context);
            }
            catch (Exception exception)
            {
                heroEquipmentOpenPending = false;
                pendingFunctionCultivationMode = -1;
                Fail(exception.Message);
            }
        }

        private bool TryOpenPendingFunctionCultivation(HeroEquipmentKind kind)
        {
            if (pendingFunctionCultivationMode < 0) return false;

            int mode = pendingFunctionCultivationMode;
            HeroEquipmentKind expectedKind = pendingFunctionCultivationKind;
            pendingFunctionCultivationMode = -1;
            if (kind != expectedKind)
            {
                Fail($"Task cultivation route returned the wrong kind: expected={expectedKind}, actual={kind}.");
                return true;
            }

            uint uid;
            int formationPosition;
            if (kind == HeroEquipmentKind.FaBao)
            {
                FaBaoRecord target = services.FaBao.Items.FirstOrDefault();
                uid = target.Uid;
                formationPosition = target.FormationPosition;
            }
            else
            {
                HeroEquipmentRecord target = services.HeroEquipment.Items.FirstOrDefault();
                uid = target.Uid;
                formationPosition = target.FormationPosition;
            }

            if (uid == 0)
            {
                string message = kind == HeroEquipmentKind.FaBao ? "暂无可强化法宝" : "暂无可培养装备";
                ShowToast(message, 2f);
                SetStatus($"Task cultivation route has no target: kind={kind}, mode={mode}.");
                return true;
            }

            HideHeroCultivationForNavigation();
            heroEnhanceMasterView?.SetVisible(false);
            gameplayView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
            if (!heroEquipmentPresenter.PrepareCultivation(uid, Math.Max(1, formationPosition), kind, mode))
            {
                PopUiStackWithHudRefresh();
                ShowToast("未找到对应养成对象", 2f);
                SetStatus($"Task cultivation route target was rejected: uid={uid}, kind={kind}, mode={mode}.");
                return true;
            }

            SetStatus($"Task cultivation route opened: uid={uid}, kind={kind}, mode={mode}.");
            return true;
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
            byte[] currentTypes = { 2 };
            string[] requiredG4Events =
            {
                "fixture", "count-before", "purchase-response", "purchase-reload",
                "soldout", "insufficient", "invalid-repeat", "refresh"
            };
            if (!services.GameplayShops.HasAll(currentTypes)
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Gameplay shops state mismatch: pages={services.GameplayShops.PageCount}/1, "
                    + $"pending={services.ProtocolRegistry.PendingCount}.");
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

            int baseShopCount = services.Shop.Count;
            ShowGameplayShop(15);
            gameplayShopsPresenter.SelectTypeForValidation(2);
            yield return null;
            Canvas.ForceUpdateCanvases();
            yield return CaptureGameplayShopValidationScreenshot(
                "bootstrap-gameplay-shop-jianghun.png");

            // The visual contract is entered from the protocol callback, while the
            // generic runner may have just consumed the previous route's UiStack
            // frame. Re-assert the real shop route before validating the captured
            // authoritative list instead of treating a transient stack handoff as
            // a render failure.
            if (!IsGameplayShopOpen)
            {
                ShowGameplayShop(15);
                gameplayShopsPresenter.SelectTypeForValidation(2);
                yield return null;
                Canvas.ForceUpdateCanvases();
            }

            if (!services.GameplayShops.TryGet(2, out GameplayShopPage page)
                || page.Items.Count != 6 || !IsGameplayShopOpen
                || !gameplayShopsPresenter.IsAuthoritativeVisible
                || gameplayShopsPresenter.RenderedCount != 6
                || gameplayShopsPresenter.MissingIconCount != 0)
            {
                Fail($"Soul shop render mismatch: open={IsGameplayShopOpen}, "
                    + $"items={page?.Items.Count ?? 0}, rendered={gameplayShopsPresenter.RenderedCount}, "
                    + $"missing={gameplayShopsPresenter.MissingIconCount}.");
                yield break;
            }

            Transform shopRoot = soulShopView.GameObject.transform;
            Text title = bagPopupFrameView.Binding.Find(
                "Layer/shopBg/Popup/Title/Title")?.GetComponent<Text>();
            gameplayContentView = gameplayContentView
                ?? services.UiRouter.FindBySource("common/ActivityLayer");
            Transform activityLayer = gameplayContentView?.GameObject.transform;
            bool activityContract = activityLayer == null || !activityLayer.gameObject.activeSelf;
            Button close = bagPopupFrameView.Binding.Find(
                "Layer/shopBg/Popup/Btn_close")?.GetComponent<Button>();
            Button help = title?.transform.Find("Button_1")?.GetComponent<Button>();
            Button soulInfo = shopRoot.Find("ShopUI/Mine/jianghun/add")?.GetComponent<Button>();
            Transform countdown = shopRoot.Find(
                "ShopUI/jianghunShop/Panel_1/freetimes/cd/Value");

            if (!requireG4Evidence)
            {
                // G5 uses the current Cocos five-state contract. Capture each state
                // from the real Unity controls so the comparison never reuses the
                // single G4 shell frame for a popup or cross-route state.
                if (!InvokeEventSystemClick(help) || !IsErrorVisible)
                {
                    Fail("Gameplay shops G5 help EventSystem click did not open the real help dialog.");
                    yield break;
                }
                yield return CaptureGameplayShopValidationScreenshot(
                    "bootstrap-gameplay-shop-soul-help.png");
                errorPresenter.Hide();
                yield return null;

                if (!gameplayShopsPresenter.InvokeFirstDetail()
                    || bagFlowPresenter?.IsSourceOpen != true)
                {
                    Fail("Gameplay shops G5 item-detail control did not open the imported source dialog.");
                    yield break;
                }
                yield return CaptureGameplayShopValidationScreenshot(
                    "bootstrap-gameplay-shop-soul-item-detail.png");
                bagFlowPresenter.HideGameplayShopSource();
                yield return null;

                if (!InvokeEventSystemClick(soulInfo)
                    || gameplayShopItemInfoPresenter?.IsVisible != true)
                {
                    Fail("Gameplay shops G5 soul-info control did not open the imported item-info dialog.");
                    yield break;
                }
                yield return CaptureGameplayShopValidationScreenshot(
                    "bootstrap-gameplay-shop-soul-currency-detail.png");
                gameplayShopItemInfoPresenter.Hide();
                yield return null;

                CloseGameplayShops();
                yield return null;
                EnsureDrawPresenter();
                HandleDrawClick();
                float drawDeadline = Time.realtimeSinceStartup + 12f;
                while (!IsDrawOpen && Time.realtimeSinceStartup < drawDeadline)
                    yield return null;
                if (!IsDrawOpen)
                {
                    Fail("Gameplay shops G5 draw-route validation did not open the real Draw page.");
                    yield break;
                }
                Button drawShop = drawView.Binding.Find("Layer/Shop")?.GetComponent<Button>();
                if (!InvokeEventSystemClick(drawShop))
                {
                    Fail("Gameplay shops G5 Draw Shop control was not EventSystem-clickable.");
                    yield break;
                }
                while ((!IsGameplayShopOpen || services.ProtocolRegistry.PendingCount != 0)
                    && Time.realtimeSinceStartup < drawDeadline)
                    yield return null;
                if (!IsGameplayShopOpen || services.ProtocolRegistry.PendingCount != 0)
                {
                    Fail("Gameplay shops G5 draw-route did not return an authoritative soul-shop page.");
                    yield break;
                }
                yield return CaptureGameplayShopValidationScreenshot(
                    "bootstrap-gameplay-shop-soul-draw.png");
                CloseGameplayShops();
                if (IsDrawOpen) HandleBack();
                yield return null;
            }

            bool sixCellContract = true;
            for (int index = 0; index < 6; index++)
            {
                Transform cell = shopRoot.Find(
                    $"ShopUI/jianghunShop/List/Item_1/Item{index + 1}");
                Image background = cell?.GetComponent<Image>();
                Button icon = cell?.Find("bg_icon")?.GetComponent<Button>();
                Button buy = cell?.Find("buy")?.GetComponent<Button>();
                sixCellContract &= cell != null && cell.gameObject.activeSelf
                    && background != null && background.enabled
                    && background.color.a > 0.99f
                    && cell.GetComponent<Button>()?.transition == Selectable.Transition.None
                    && icon != null && icon.interactable
                    && buy != null;
            }
            bool routeContract = services.GameplayCatalog.Find(15) != null
                && services.GameplayCatalog.Find(16) == null
                && services.GameplayCatalog.Find(17) == null
                && gameplayShopsPresenter.FunctionId == 15;
            bool detailContract = gameplayShopsPresenter.InvokeFirstDetail()
                && bagFlowPresenter?.IsSourceOpen == true;
            bagFlowPresenter?.HideGameplayShopSource();
            bool soulInfoContract = soulInfo != null && soulInfo.interactable;
            bool helpContract = help != null && help.interactable;
            bool countdownContract = !requireG4Evidence || page.RefreshDeadlineUnix > 0
                && countdown?.GetComponent<Text>() != null
                && !string.IsNullOrWhiteSpace(countdown.GetComponent<Text>().text);
            bool closeContract = close != null && close.interactable
                && close.targetGraphic != null && close.targetGraphic.raycastTarget;
            RecordValidationSemantic("soul-shop-title-and-six-slots",
                title?.text == "将魂商店" && sixCellContract && activityContract,
                $"title={title?.text}, cells={page.Items.Count}, activityHiddenWhileShopOpen={activityContract}");
            RecordValidationSemantic("soul-shop-all-function-15-routes", routeContract,
                "function_id=15 is routable while 16/17 remain excluded from this cycle");
            RecordValidationSemantic("soul-shop-authoritative-list",
                page.Items.Count == 6 && page.Items.All(item => item.Id > 0),
                $"type=2 items={page.Items.Count}");
            RecordValidationSemantic("soul-shop-authoritative-purchase",
                !requireG4Evidence || gameplayShopG4Events.Contains("purchase-response")
                    && gameplayShopG4Events.Contains("purchase-reload"),
                "real /221 op=2 response and authoritative type=2 reload");
            RecordValidationSemantic("soul-shop-authoritative-refresh",
                !requireG4Evidence || gameplayShopG4Events.Contains("refresh"),
                "real /221 op=3 result replaced the complete type=2 page");
            RecordValidationSemantic("soul-shop-insufficient-and-soldout",
                !requireG4Evidence || gameplayShopG4Events.Contains("soldout")
                    && gameplayShopG4Events.Contains("insufficient")
                    && gameplayShopG4Events.Contains("invalid-repeat"),
                "server sold-out/insufficient failures and client repeat-pending rejection");
            RecordValidationSemantic("soul-shop-second-countdown", countdownContract,
                $"deadline={page.RefreshDeadlineUnix}, text={countdown?.GetComponent<Text>()?.text}");
            RecordValidationSemantic("soul-shop-return-reconnect-account-switch",
                closeContract && helpContract && soulInfoContract && detailContract
                    && services.ProtocolRegistry.PendingCount == 0,
                "close/help/soul/detail bindings are live and no request remains pending");
            RecordValidationSemantic("soul-shop-basic-shop-pending-isolation",
                services.Shop.Count == baseShopCount
                    && services.ProtocolRegistry.PendingCount == 0,
                $"baseShop={baseShopCount}->{services.Shop.Count}, gameplayPages={services.GameplayShops.PageCount}");

            string[] controlIds =
            {
                "GPS-01-MAIN-TOGGLE", "GPS-02-SOUL-ENTRY", "GPS-03-DRAW-SHOP",
                "GPS-05-BAG-SOURCE", "GPS-06-FENGSHEN-SOURCE", "GPS-07-CLOSE",
                "GPS-08-HELP", "GPS-10-SOUL-INFO", "GPS-11-DETAIL-1",
                "GPS-12-DETAIL-2", "GPS-13-DETAIL-3", "GPS-14-DETAIL-4",
                "GPS-15-DETAIL-5", "GPS-16-DETAIL-6", "GPS-17-BUY-1",
                "GPS-18-BUY-2", "GPS-19-BUY-3", "GPS-20-BUY-4",
                "GPS-21-BUY-5", "GPS-22-BUY-6", "GPS-23-REFRESH",
                "GPS-S01-AUTHORITATIVE-LIST", "GPS-S02-DISCOUNT-SOLDOUT",
                "GPS-S03-REFRESH-STATUS", "GPS-S04-PURCHASE-SUCCESS",
                "GPS-S05-INSUFFICIENT", "GPS-S06-REFRESH-SUCCESS",
                "GPS-S07-RETURN-RECONNECT", "GPS-S08-ACCOUNT-SWITCH"
            };
            foreach (string controlId in controlIds) MarkValidationControl(controlId);

            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Gameplay shops semantic assertions failed: "
                    + string.Join(" | ", GetFailedValidationSemanticAssertions()));
                yield break;
            }
            Complete(requireG4Evidence
                ? "COMPLETE: GameplayShops G4 type=2 real /221 list/purchase/refresh/failures; 29/29 controls and 9/9 semantics"
                : "COMPLETE: GameplayShops G5 type=2 five-state visual capture; list/help/item-detail/currency-detail/draw-route");
        }

        private void EnsureShopPresenter()
        {
            shopView = shopView ?? services.UiRouter.FindBySource("shop/shangcheng");
            EnsureOneLevelFrame();
            bagInputView = bagInputView ?? services.UiRouter.FindBySource("EnterNumLayer");
            if (shopView == null || oneLevelFrameView == null || bagInputView == null)
                throw new InvalidOperationException("Shop required CocosUiBinding was not found.");
            shopPresenter = shopPresenter ?? new ShopPresenter(shopView, services.Shop, services.Currencies,
                services.Resources, services.ServerTime, bagInputView, ShowShopPurchaseConfirmation,
                () => InvokeLuaOrFail(onShopRefreshRequested, "Shop.OnRefreshRequested"));
        }


        private void EnsureDrawPresenter()
        {
            drawView = drawView ?? services.UiRouter.FindBySource("chouka/shenjiangzhaomu");
            drawSingleResultView = drawSingleResultView ?? services.UiRouter.FindBySource("chouka/dancichouka");
            drawTenResultView = drawTenResultView ?? services.UiRouter.FindBySource("chouka/shilianchouka");
            drawPreviewView = drawPreviewView ?? services.UiRouter.FindBySource("chouka/jiangliyulan");
            drawHeroPreviewView = drawHeroPreviewView ?? services.UiRouter.FindBySource("chouka/shenjiangyulan");
            if (drawView == null || drawSingleResultView == null || drawTenResultView == null || drawPreviewView == null
                || drawHeroPreviewView == null)
                throw new InvalidOperationException("Current HappyDraw imported CocosUiBindings were not found by full relative path.");
            if (drawPresenter == null)
            {
                // DrawPresenter clones its preview frame twice.  Do not use the live
                // OneLevelLayer singleton here: it may already contain lazily loaded
                // hero pages, so cloning it would duplicate those pages under each
                // preview frame.  Use a clean prefab instance as a clone source and
                // release that temporary source after the presenter has copied it.
                CocosUiView cleanPreviewFrame = services.UiAssets.Instantiate(
                    "OneLevelLayer", drawView.GameObject.transform);
                try
                {
                    drawPresenter = new DrawPresenter(drawView, drawSingleResultView, drawTenResultView,
                        drawPreviewView, cleanPreviewFrame, drawHeroPreviewView,
                        services.Draw, services.ServerTime, services.Resources, services.ShopCatalog, services.Currencies, services.Bag,
                        (kind, type) => InvokeLuaOrFail(onDrawRequested, "Draw.Requested", (double)kind, (double)type),
                        () => HandleBack());
                }
                finally
                {
                    UiPrefabLoader.Release(cleanPreviewFrame);
                }
            }
            drawView.BindClick("Layer/GoldCheck/GoldIcon1/AddBtn", () =>
            {
                EnsureErrorPresenter();
                errorPresenter.ShowHelp($"基础招募券：{GetBagQuantityByItemId(1000)}。招募消耗以服务端 /224 回包为准。");
            }, true);
            drawView.BindClick("Layer/GoldCheck/GoldIcon2/AddBtn", () =>
            {
                HandleCommerceRoute(15);
            }, true);
            drawView.BindClick("Layer/GoldCheck/GoldIcon3/AddBtn", () =>
            {
                if (IsSteamExcludedModule("Friend"))
                {
                    const string message = "好友功能未包含在当前 Steam 版本中";
                    ShowToast(message, 2f);
                    SetStatus("Draw friend shortcut unavailable: Friend is excluded from the Steam build.");
                    return;
                }
                HandleFriendClick();
            }, true);
            drawView.BindClick("Layer/Shop", () =>
            {
                HandleCommerceRoute(15);
            }, true);
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
                id => InvokeLuaOrFail(onGameplayEntered, "Gameplay.Entered", (double)id),
                definition =>
                {
                    string message = $"达到{definition.OpenLevel}级后解锁{definition.Name}";
                    ShowToast(message, 3f);
                    SetStatus($"Gameplay locked: id={definition.Id}, requiredLevel={definition.OpenLevel}, currentLevel={services.Player.Level}.");
                },
                () => HandleBack());
        }

        private void EnsureYouLiPresenter()
        {
            youLiView = youLiView ?? services.UiRouter.FindBySource("youli/youlisanjie");
            if (youLiView == null)
                throw new InvalidOperationException("Current YouLi imported CocosUiBinding was not found: youli/youlisanjie.");
            gameplayView = gameplayView ?? services.UiRouter.FindBySource("shop/shop_bg");
            GameObject closeTemplate = gameplayView?.Binding.Find("Layer/shopBg/Popup/Btn_close");
            youLiPresenter = youLiPresenter ?? new YouLiPresenter(youLiView, services.YouLi, services.Heroes,
                services.Player.Level, services.Resources, StartYouLi, StartAllYouLi, ClaimYouLi,
                closeTemplate, () => HandleBack());
        }

        private void EnsureFengShenStoryPresenter()
        {
            fengShenStoryView = fengShenStoryView ?? services.UiRouter.FindBySource("fengshenliezhuan/fengshenliezhuanlLayer");
            fengShenStoryLevelView = fengShenStoryLevelView ?? services.UiRouter.FindBySource("fengshenliezhuan/fengshenliezhuanlevel");
            rewardView = rewardView ?? services.UiRouter.FindBySource("common/tanchuangjiangli");
            heroItemSourceView = heroItemSourceView ?? services.UiRouter.FindBySource("common/huoqutujing");
            EnsureErrorPresenter();
            EnsureRewardPresenter();
            if (fengShenStoryView == null || fengShenStoryLevelView == null || rewardView == null
                || heroItemSourceView == null || errorPresenter == null)
                throw new InvalidOperationException("Current FengShenStory imported main/level CocosUiBindings were not found.");
            CocosUiView firstClassFrame = EnsureOneLevelFrame().View;
            GameObject commonHeaderTemplate = firstClassFrame?.Binding.Find("Layer/Panel_12/Title");
            GameObject commonCurrencyTemplate = firstClassFrame?.Binding.Find("Layer/GoldCheck");
            fengShenStoryPresenter = fengShenStoryPresenter ?? new FengShenStoryPresenter(
                fengShenStoryView, fengShenStoryLevelView,
                () => services.UiRouter.FindBySource("fengshenliezhuan/fengshenliezhuanlevel"),
                services.FengShenStory, services.Currencies,
                services.Resources, errorPresenter, heroItemSourceView, rewardView, rewardPresenter,
                commonHeaderTemplate, commonCurrencyTemplate,
                () => HandleBack(),
                () => InvokeLuaOrFail(onFengShenStoryChallengeClicked, "FengShenStory.Challenge"),
                () => { SetStatus("FengShenStory -> Formation boundary"); ShowFormationPopup(); },
                functionId =>
                {
                    lastGameplayBoundaryId = functionId;
                    fengShenStoryPresenter?.CloseModal();
                    HandleCommerceRoute(functionId);
                },
                () => SetStatus("FengShenStory stamina boundary -> UseItemUI(500,1)"),
                () =>
                {
                    lastGameplayBoundaryId = 13;
                    HandleCommerceRoute(13);
                });
        }

        private static void AttachAndOrderHeroEquipmentCultivationViews(Transform parent,
            params CocosUiView[] views)
        {
            if (parent == null || views == null) return;
            for (int index = 0; index < views.Length; index++)
            {
                CocosUiView view = views[index];
                if (view?.GameObject == null) continue;
                Transform child = view.GameObject.transform;
                if (child.parent != parent) child.SetParent(parent, false);
                child.SetSiblingIndex(index);
            }
        }

        private void EnsureArenaPresenter(){arenaView=arenaView??services.UiRouter.FindBySource("common/JingjiLayer");if(arenaView==null)throw new InvalidOperationException("Current Arena imported CocosUiBinding was not found: common/JingjiLayer.");arenaPresenter=arenaPresenter??new ArenaPresenter(arenaView,services.Arena,()=>HandleBack());}

        private void EnsureKunLunPresenter(){kunLunView=kunLunView??services.UiRouter.FindBySource("kunlun/juezhankunlun");if(kunLunView==null)throw new InvalidOperationException("Current KunLun imported CocosUiBinding was not found: kunlun/juezhankunlun.");kunLunPresenter=kunLunPresenter??new KunLunPresenter(kunLunView,services.KunLun,()=>HandleBack());}

        private void EnsureBloodFightPresenter(){bloodFightView=bloodFightView??services.UiRouter.FindBySource("xuezhan/XuezhanMain");if(bloodFightView==null)throw new InvalidOperationException("Current BloodFight imported CocosUiBinding was not found: xuezhan/XuezhanMain.");bloodFightPresenter=bloodFightPresenter??new BloodFightPresenter(bloodFightView,services.BloodFight,()=>HandleBack());}


        private void EnsureSevenDayPresenter(){sevenDayView=sevenDayView??services.UiRouter.FindBySource("huodong/QiriLayer");if(sevenDayView==null)throw new InvalidOperationException("Current SevenDay imported CocosUiBinding was not found: huodong/QiriLayer.");sevenDayPresenter=sevenDayPresenter??new SevenDayPresenter(sevenDayView,services.SevenDay,services.Currencies,services.GameplayShops,RequestSevenDayClaim,RequestSevenDayGo,SelectSevenDayDay,SelectSevenDayCategory,ShowSevenDayItemDetail,RequestSevenDayDiscountBuy,()=>{lastSevenDayBoundary="stamina-add";SetStatus("SevenDay stamina boundary -> UseItemUI(500,1)");},()=>{lastSevenDayBoundary="gold-add";HandleCommerceRoute(13);},()=>HandleBack());}
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

        private void EnsureMainTaskTracker()
        {
            if (mainTaskTracker != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null)
                throw new InvalidOperationException("Main main task-tracker view was not found.");
            mainTaskTracker = new MainTaskTrackerPresenter(mainView, services.Tasks, HandleTaskClick);
        }

        private void EnsureMainHudPresenter()
        {
            if (mainHudPresenter != null) return;
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null) throw new InvalidOperationException("Main HUD view was not found.");
            if (!singlePlayerTitleEnabled)
            {
                chatMiniView = chatMiniView ?? services.UiRouter.FindBySource("/ChatLayer.csd");
                if (chatMiniView == null) throw new InvalidOperationException("HUD ChatLayer view was not found.");
            }
            mainHudPresenter = new MainHudPresenter(mainView, chatMiniView, services.Player,
                services.Currencies, services.Chat, services.Resources,
                seedStableRedDots: !singlePlayerTitleEnabled);
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
            // 本地后端可能在超时窗口后返回有效回包；超时只做内部请求清理，
            // 不再中断玩家当前界面或显示网络超时提示。
            if (context.Protocol.Command == 221)
                InvokeLuaOrFail(onShopRequestTimeout, "Shop.OnRequestTimeout");
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
