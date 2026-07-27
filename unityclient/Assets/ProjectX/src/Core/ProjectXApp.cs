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
        public const string FormationPath = "Layer/Main_UI/ButtonGroup1/btn_zhenrong";
        public const string HeroBagPath = "Layer/Main_UI/ButtonGroup1/btn_shenjiangbeibao";
        public const string MailPath = "Layer/Main_UI/ButtonGroup7/btn_mail";
        public const string ShopPath = "Layer/Main_UI/ButtonGroup5/btn_shangcheng";
        public const string ShopSubmenuPath = "Layer/Main_UI/tankuang1/btn_shangcheng";
        public const string FriendPath = "Layer/Main_UI/ButtonGroup7/btn_friend";
        public const string ChatPath = "Layer/Main_UI/ShortcutButtonGroup/Chat";
        public const string TeamLegacyPath = "Layer/Main_UI/Panel_QuestAndTeam/CheckBox_Team";
        public const string GuildPath = "Layer/Main_UI/ButtonGroup3/btn_bangpai";
        public const string WorldPath = "Layer/Main_UI/btn_fuben";
        public const string WelfareLegacyPath = "Layer/Main_UI/ButtonGroup8/btn_fuli";
        public const string ActivityPath = "Layer/Main_UI/ButtonGroup5/btn_huodong";
        public const string DrawPath = "Layer/Main_UI/ButtonGroup3/btn_zhaomu";
        public const string GameplayPath = "Layer/Main_UI/btn_wanfa";
        public const string EquipmentBagPath = "Layer/Main_UI/tankuang2/btn_zhuangbei";
        public const string FaBaoBagPath = "Layer/Main_UI/tankuang2/btn_fabao";

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
        private LuaFunction onEquipmentBagClicked;
        private LuaFunction onFaBaoBagClicked;
        private LuaFunction onHeroEquipmentTakeOff;
        private LuaFunction onHeroEquipmentStrength;
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
        private LuaFunction onGameplayShopOpened;
        private LuaFunction onGameplayShopTab;
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
        private LuaFunction onActivityClicked;
        private LuaFunction onActivitySelected;
        private LuaFunction onDrawClicked;
        private LuaFunction onDrawRequested;
        private LuaFunction onGameplayClicked;
        private LuaFunction onGameplayEntered;
        private LuaFunction onYouLiClicked;
        private LuaFunction onFengShenStoryClicked;
        private LuaFunction onArenaClicked;
        private LuaFunction onKunLunClicked;
        private LuaFunction onBloodFightClicked;
        private LuaFunction onXunBaoClicked;
        private LuaFunction onSevenDayClicked;
        private LuaFunction onStaminaClaimClicked;
        private LuaFunction onResourceRecoveryClicked;
        private LuaFunction onFundsClicked;
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
        private uint validationRoleIdSnapshot;
        private readonly HashSet<string> validationControlIds = new HashSet<string>(StringComparer.Ordinal);
        private readonly HashSet<string> passedValidationSemantics = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> failedValidationSemantics =
            new Dictionary<string, string>(StringComparer.Ordinal);
        private bool bagInitialSelectionApplied;
        private CocosUiView rewardView;
        private RewardPresenter rewardPresenter;
        private readonly List<RewardRecord> pendingRewards = new List<RewardRecord>();
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
        private bool heroEquipmentOpenedFromHeroDetails;
        private CocosUiView heroEquipmentListView;
        private CocosUiView heroEquipmentDetailView;
        private CocosUiView heroEquipmentChangeView;
        private CocosUiView heroEquipmentCultivateView;
        private CocosUiView heroEquipmentStrengthView;
        private CocosUiView heroEquipmentFragmentView;
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
        private int pendingEquipmentStrengthAttributeType;
        private uint pendingEquipmentStrengthAttributeValue;
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
        private CocosUiView friendView;
        private FriendPresenter friendPresenter;
        private readonly List<FriendRecord> pendingFriendRecords = new List<FriendRecord>();
        private byte pendingFriendMaximum;
        private CocosUiView chatMiniView;
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
        private CocosUiView activityRootView;
        private CocosUiView activityBackgroundView;
        private CocosUiView activityDailyRechargeView;
        private ActivityPresenter activityPresenter;
        private readonly List<ActivityListRecord> pendingActivityItems = new List<ActivityListRecord>();
        private DailyRechargeActivityState pendingDailyRecharge;
        private CocosUiView drawView;
        private CocosUiView drawSingleResultView;
        private CocosUiView drawTenResultView;
        private DrawPresenter drawPresenter;
        private readonly List<DrawPoolRecord> pendingDrawPools = new List<DrawPoolRecord>();
        private DrawResultRecord pendingDrawResult;
        private CocosUiView gameplayView;
        private CocosUiView gameplayContentView;
        private CocosUiView gameplayDetailView;
        private GameplayPresenter gameplayPresenter;
        private CocosUiView youLiView;
        private YouLiPresenter youLiPresenter;
        private CocosUiView fengShenStoryView;
        private FengShenStoryPresenter fengShenStoryPresenter;
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
        private CocosUiView staminaClaimView;
        private StaminaClaimPresenter staminaClaimPresenter;
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
        public int DrawPoolCount => services?.Draw.Count ?? 0;
        public int DrawResultCount => drawPresenter?.ResultCount ?? 0;
        public bool IsDrawResultVisible => drawPresenter?.IsSingleResultVisible ?? false;
        public bool IsDrawEffectLoaded => drawPresenter?.FurnaceEffectLoaded ?? false;
        public bool IsGameplayOpen => gameplayView != null && services?.UiStack.Current == gameplayView;
        public int GameplayRenderedCount => gameplayPresenter?.RenderedCount ?? 0;
        public int GameplayMissingIconCount => gameplayPresenter?.MissingIconCount ?? 0;
        public bool IsGameplayDetailVisible => gameplayPresenter?.IsDetailVisible ?? false;
        public int GameplaySelectedFunctionId => gameplayPresenter?.SelectedFunctionId ?? 0;
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
        public bool IsHeroEquipmentOpen => (heroEquipmentListView?.GameObject.activeSelf == true
            || heroEquipmentDetailView?.GameObject.activeSelf == true
            || heroEquipmentFragmentView?.GameObject.activeSelf == true)
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
                onFormationMove = services.Lua.GetFunction("OnFormationMove");
                onHeroEquipmentWear = services.Lua.GetFunction("OnHeroEquipmentWear");
                onEquipmentBagClicked = services.Lua.GetFunction("OnEquipmentBagClicked");
                onFaBaoBagClicked = services.Lua.GetFunction("OnFaBaoBagClicked");
                onHeroEquipmentTakeOff = services.Lua.GetFunction("OnHeroEquipmentTakeOff");
                onHeroEquipmentStrength = services.Lua.GetFunction("OnHeroEquipmentStrength");
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
                onGameplayShopOpened = services.Lua.GetFunction("OnGameplayShopOpened");
                onGameplayShopTab = services.Lua.GetFunction("OnGameplayShopTab");
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
                onActivityClicked = services.Lua.GetFunction("OnActivityClicked");
                onActivitySelected = services.Lua.GetFunction("OnActivitySelected");
                onDrawClicked = services.Lua.GetFunction("OnDrawClicked");
                onDrawRequested = services.Lua.GetFunction("OnDrawRequested");
                onGameplayClicked = services.Lua.GetFunction("OnGameplayClicked");
                onGameplayEntered = services.Lua.GetFunction("OnGameplayEntered");
                onYouLiClicked = services.Lua.GetFunction("OnYouLiClicked");
                onFengShenStoryClicked = services.Lua.GetFunction("OnFengShenStoryClicked");
                onArenaClicked = services.Lua.GetFunction("OnArenaClicked");
                onKunLunClicked = services.Lua.GetFunction("OnKunLunClicked");
                onBloodFightClicked = services.Lua.GetFunction("OnBloodFightClicked");
                onXunBaoClicked = services.Lua.GetFunction("OnXunBaoClicked");
                onSevenDayClicked = services.Lua.GetFunction("OnSevenDayClicked");
                onStaminaClaimClicked = services.Lua.GetFunction("OnStaminaClaimClicked");
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
            services?.Tick();
            loadingPresenter?.Tick();
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
            onFormationMove?.Dispose();
            onHeroEquipmentWear?.Dispose();
            onEquipmentBagClicked?.Dispose();
            onFaBaoBagClicked?.Dispose();
            onHeroEquipmentTakeOff?.Dispose();
            onHeroEquipmentStrength?.Dispose();
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
            onGameplayShopOpened?.Dispose();
            onGameplayShopTab?.Dispose();
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
            onActivityClicked?.Dispose();
            onActivitySelected?.Dispose();
            onDrawClicked?.Dispose();
            onDrawRequested?.Dispose();
            onGameplayClicked?.Dispose();
            onGameplayEntered?.Dispose();
            onYouLiClicked?.Dispose();
            onFengShenStoryClicked?.Dispose();
            onArenaClicked?.Dispose();
            onKunLunClicked?.Dispose();
            onBloodFightClicked?.Dispose();
            onXunBaoClicked?.Dispose();
            onSevenDayClicked?.Dispose();
            onStaminaClaimClicked?.Dispose();
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
                heroEquipmentPresenter?.HideDetails();
                heroEquipmentListView?.SetVisible(false);
                heroEquipmentFragmentView?.SetVisible(false);
                if (heroEquipmentOpenedFromHeroDetails)
                {
                    heroEquipmentOpenedFromHeroDetails = false;
                    heroListView?.SetVisible(true);
                    heroDetailView?.SetVisible(true);
                    heroBagView?.SetVisible(false);
                    heroFrameView?.SetVisible(true);
                    ConfigureHeroFrame(false);
                    heroFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
                    return true;
                }
                heroFrameView?.SetVisible(false);
            }
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
            heroEquipmentFragmentView = services.UiRouter.FindBySource("zhuangbeiyangcheng/fabaosuipianbeibao");
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
            heroEquipmentFragmentView?.SetVisible(false);
            mailView?.SetVisible(false);
            shopView?.SetVisible(false);
            friendView?.SetVisible(false);
            chatMiniView?.SetVisible(false);
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
            SetMainSubmenuVisible("Layer/Main_UI/tankuang1", false);
            SetMainSubmenuVisible("Layer/Main_UI/tankuang2", false);
            chatView?.SetVisible(false);
            chatMiniView?.SetVisible(true);
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
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
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
                MakeButtonVisualTransparent(button);
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
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
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
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(DrawPath, HandleDrawClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGameplayClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                Button button = mainView.BindClick(GameplayPath, HandleGameplayClick, true);
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

        public void ShowActivity()
        {
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
            if (functionId == 7)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onKunLunClicked, "Gameplay.KunLun");
                return;
            }
            if (functionId == 8)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onBloodFightClicked, "Gameplay.BloodFight");
                return;
            }
            if (functionId == 9)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onXunBaoClicked, "Gameplay.XunBao");
                return;
            }
            if (functionId == 11)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onSevenDayClicked, "Gameplay.SevenDay");
                return;
            }
            if (functionId == 15 || functionId == 16 || functionId == 17)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onGameplayShopOpened, "Gameplay.Shops", (double)functionId);
                return;
            }
            if (functionId == 18)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onStaminaClaimClicked, "Gameplay.StaminaClaim");
                return;
            }
            if (functionId == 19)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onResourceRecoveryClicked, "Gameplay.ResourceRecovery");
                return;
            }
            if (functionId == 25 || functionId == 26)
            {
                gameplayPresenter?.HideDetail();
                InvokeLuaOrFail(onFundsClicked, "Gameplay.Funds", (double)functionId);
                return;
            }
            ShowToast($"{definition.Name}属于独立子玩法，首期大厅仅保留真实进入边界。", 3f);
            SetStatus($"Gameplay route boundary: id={functionId}, name={definition.Name}.");
        }

        public void UpdateGameplayHotPoint(int rawType, int rawState)
        {
            services.Gameplay.SetHotPoint(checked((ushort)rawType), rawState == 1);
        }

        public void CompleteGameplayValidation()
        {
            StartCoroutine(CaptureGameplayValidationStates());
        }

        private IEnumerator CaptureGameplayValidationStates()
        {
            EnsureGameplayPresenter();
            if (!IsGameplayOpen || services.Gameplay.Count != 16 || services.Gameplay.OpenCount != 16
                || GameplayRenderedCount != 16 || GameplayMissingIconCount != 0
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Gameplay list state mismatch: open={IsGameplayOpen}, items={services.Gameplay.Count}, openItems={services.Gameplay.OpenCount}, rendered={GameplayRenderedCount}, missing={GameplayMissingIconCount}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string listPath = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-gameplay-list.png");
            Directory.CreateDirectory(Path.GetDirectoryName(listPath));
            ScreenCapture.CaptureScreenshot(listPath);
            yield return new WaitForSecondsRealtime(0.8f);
            gameplayPresenter.ShowDetail(1);
            yield return new WaitForEndOfFrame();
            if (!IsGameplayDetailVisible || GameplaySelectedFunctionId != 1)
            {
                Fail($"Gameplay detail state mismatch: detail={IsGameplayDetailVisible}, selected={GameplaySelectedFunctionId}.");
                yield break;
            }
            Complete($"COMPLETE: current btn_wanfa -> shop/shop_bg + Main.WanFaEntranceUI -> function config 16 entries/level gates -> /65 types 101,51,103 authoritative hidden states -> YouLi detail/enter boundary; user={GetLocalUserId()}");
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

        public void CompleteFengShenStoryValidation()
        {
            StartCoroutine(CompleteFengShenStoryValidationAfterLayout());
        }

        private IEnumerator CompleteFengShenStoryValidationAfterLayout()
        {
            EnsureFengShenStoryPresenter();
            Canvas.ForceUpdateCanvases(); yield return new WaitForEndOfFrame();
            if (!IsFengShenStoryOpen || !services.FengShenStory.HasAuthoritativeResponse
                || !IsFengShenStoryAuthoritativeVisible || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"FengShenStory state mismatch: open={IsFengShenStoryOpen}, authoritative={services.FengShenStory.HasAuthoritativeResponse}, visible={IsFengShenStoryAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            Complete($"COMPLETE: btn_wanfa -> function_id=3 -> FengShenStoryMainUI -> csd/fengshenliezhuan/fengshenliezhuanlLayer.csb -> /320 op=24 chapter={services.FengShenStory.ChapterId}, level={services.FengShenStory.LevelId}, count={services.FengShenStory.RemainingChallenges}; isolated user={GetLocalUserId()}");
        }

        public void ShowArena(){EnsureArenaPresenter();if(services.UiStack.Current!=arenaView)services.UiStack.Push(arenaView);SetStatus("Arena current KaPaiArenaUI active; awaiting /161 op=0.");}
        public void SetArenaState(int opponents,double rank,int remaining,int challenged,int bought,double score){services.Arena.Replace(opponents,checked((uint)rank),checked((ushort)remaining),checked((ushort)challenged),checked((byte)bought),checked((uint)score));}
        public void SetArenaError(string message){ShowToast(message,3f);SetStatus("Arena/161 failed: "+message);}
        public void CompleteArenaValidation(){StartCoroutine(CompleteArenaValidationAfterLayout());}
        private IEnumerator CompleteArenaValidationAfterLayout(){EnsureArenaPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsArenaOpen||!services.Arena.HasAuthoritativeResponse||!IsArenaAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"Arena state mismatch: open={IsArenaOpen}, authoritative={services.Arena.HasAuthoritativeResponse}, visible={IsArenaAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=6 -> WanFa.KaPaiArenaUI -> csd/common/JingjiLayer.csb -> /161 op=0 rank={services.Arena.Rank}, opponents={services.Arena.OpponentCount}, remaining={services.Arena.Remaining}; isolated user={GetLocalUserId()}");}

        public void ShowKunLun(){EnsureKunLunPresenter();if(services.UiStack.Current!=kunLunView)services.UiStack.Push(kunLunView);SetStatus("KunLun current UI active; awaiting /213 op=25.");}
        public void BeginKunLunState(int floor,int fights,int buys,int position){pendingKunLunFloor=checked((byte)floor);pendingKunLunFights=checked((byte)fights);pendingKunLunBuys=checked((byte)buys);pendingKunLunPosition=checked((byte)position);pendingKunLunEnemies.Clear();}
        public void AddKunLunEnemy(int position,double roleId,string name,int profession,int sex,int level,double power,int robot,int state,int healthPercent){pendingKunLunEnemies.Add(new KunLunEnemyRecord(checked((byte)position),checked((uint)roleId),name,checked((byte)profession),checked((byte)sex),checked((ushort)level),checked((uint)power),robot!=0,checked((byte)state),Mathf.Clamp(healthPercent,0,100)));}
        public void CommitKunLunState(){services.KunLun.Replace(pendingKunLunFloor,pendingKunLunFights,pendingKunLunBuys,pendingKunLunPosition,pendingKunLunEnemies);}
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
        public void CompleteSevenDayValidation(){StartCoroutine(CompleteSevenDayValidationAfterLayout());}
        private IEnumerator CompleteSevenDayValidationAfterLayout(){EnsureSevenDayPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsSevenDayOpen||!services.SevenDay.HasAuthoritativeResponse||!IsSevenDayAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"SevenDay state mismatch: open={IsSevenDayOpen}, authoritative={services.SevenDay.HasAuthoritativeResponse}, visible={IsSevenDayAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=11 -> OperationalActivity.SevenDay -> csd/huodong/QiriLayer.csb -> /37 op=4 tasks={services.SevenDay.Tasks.Count}; isolated user={GetLocalUserId()}");}
        public void ShowStaminaClaim(){EnsureStaminaClaimPresenter();taskView?.SetVisible(false);resourceRecoveryView?.SetVisible(false);growthFundView?.SetVisible(false);activeFundView?.SetVisible(false);staminaClaimView.SetVisible(true);welfareActivityFramePresenter.Select(18);if(services.UiStack.Current!=taskBackgroundView)services.UiStack.Push(taskBackgroundView);SetStatus("StaminaClaim current welfare UI active; awaiting /321 op=2.");}
        public void BeginStaminaClaimState(){pendingStaminaClaimRecords.Clear();}
        public void AddStaminaClaimState(int index,int state){pendingStaminaClaimRecords.Add(new StaminaClaimRecord(checked((byte)index),checked((byte)state)));}
        public void CommitStaminaClaimState(){services.StaminaClaim.Replace(pendingStaminaClaimRecords);}
        public void CompleteStaminaClaimValidation(){StartCoroutine(CompleteStaminaClaimValidationAfterLayout());}
        private IEnumerator CompleteStaminaClaimValidationAfterLayout(){EnsureStaminaClaimPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsStaminaClaimOpen||!services.StaminaClaim.HasAuthoritativeResponse||!IsStaminaClaimAuthoritativeVisible||services.StaminaClaim.Items.Count!=3||services.ProtocolRegistry.PendingCount!=0){Fail($"StaminaClaim state mismatch: open={IsStaminaClaimOpen}, records={services.StaminaClaim.Items.Count}, authoritative={services.StaminaClaim.HasAuthoritativeResponse}, visible={IsStaminaClaimAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=18 -> WelfareActivityUI/ReceiveTiliUI -> huodong/tililingquLayer -> /321 op=2 slots={services.StaminaClaim.Items.Count}; read-only first phase");}

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
            if (!IsLoginVisible || IsSettingsOpen || services.Network.State != NetworkState.Disconnected
                || services.HeroEquipment.Count != 0 || services.FaBao.Count != 0)
            {
                Fail($"Settings account switch cleanup mismatch: login={IsLoginVisible}, settings={IsSettingsOpen}, network={services.Network.State}, equipment={services.HeroEquipment.Count}, fabao={services.FaBao.Count}.");
                return;
            }
            Complete("COMPLETE: settings account switch -> network disconnected -> equipment/fabao Lua+C# state cleared -> login UI restored");
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
            bagFlowPresenter?.CloseAll();
            services.Rewards.Clear();
            services.Mails.Clear();
            services.Shop.Clear();
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
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType, string itemFrom, string choices, string sources)
        {
            pendingBagItems.Add(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority, itemType, itemFrom, choices, sources));
        }

        public void EndBagUpdate()
        {
            services.Bag.Replace(pendingBagItems);
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
        public bool IsBagInputOpen => bagFlowPresenter?.IsInputOpen == true;
        public bool IsBagGiftOpen => bagFlowPresenter?.IsGiftOpen == true;
        public bool IsBagSourceOpen => bagFlowPresenter?.IsSourceOpen == true;
        public bool IsBagEquipmentInfoOpen => bagFlowPresenter?.IsEquipmentInfoOpen == true;
        public int BagModalQuantity => bagFlowPresenter?.Quantity ?? 0;
        public int BagChoiceCount => bagFlowPresenter?.ChoiceCount ?? 0;
        public bool BagHasChoice => bagFlowPresenter?.HasSelection == true;
        public bool SelectBagItem(int itemId) => bagPresenter?.SelectItem(itemId) == true;
        public bool InvokeBagControl(string controlId) =>
            bagPresenter?.InvokeControl(controlId) == true || bagFlowPresenter?.InvokeControl(controlId) == true;
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
            if (bagG4InitialBatchQuantity < 2 || bagG4InitialGiftQuantity < 1)
            {
                Fail($"Bag G4 fixture lacks batch/gift items: 500={bagG4InitialBatchQuantity}, "
                    + $"1111={bagG4InitialGiftQuantity}.");
                yield break;
            }

            if (!SelectBagItem(500))
            { Fail("Bag G4 entry fixture could not select the Cocos baseline item 500."); yield break; }
            yield return CaptureBagG5Evidence("BAG-01-ENTRY");
            if (!InvokeBagControl("BAG-03-TAB")) { Fail("Bag G4 tab binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-03-TAB");
            if (!SelectBagItem(500)) { Fail("Bag G4 could not select batch item 500."); yield break; }
            yield return CaptureBagG5Evidence("BAG-04-LIST-ITEM");
            if (!InvokeBagControl("BAG-05-LIST-SCROLL")) { Fail("Bag G4 list scroll failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-05-LIST-SCROLL");
            if (!InvokeBagControl("BAG-06-DETAIL-ICON")) { Fail("Bag G4 detail icon binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-06-DETAIL-ICON");

            if (!InvokeBagControl("BAG-07-USE") || !IsBagInputOpen)
            { Fail("Bag G4 batch item did not open EnterNumLayer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-07-USE-BATCH");
            InvokeBagControl("BAG-08-INPUT-DIGITS");
            if (BagModalQuantity != 1) { Fail("Bag G4 input digit did not set quantity=1."); yield break; }
            yield return CaptureBagG5Evidence("BAG-08-INPUT-DIGITS");
            InvokeBagControl("BAG-09-INPUT-DELETE");
            if (BagModalQuantity != 0) { Fail("Bag G4 input delete did not clear quantity."); yield break; }
            yield return CaptureBagG5Evidence("BAG-09-INPUT-DELETE");
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
            InvokeBagControl("BAG-08-INPUT-DIGITS");
            InvokeBagControl("BAG-10-INPUT-CONFIRM");
        }

        public void ContinueBagG4AfterBatchUse()
        {
            StartCoroutine(ContinueBagG4AfterBatchUseRoutine());
        }

        private IEnumerator ContinueBagG4AfterBatchUseRoutine()
        {
            if (GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 1 || !IsBagOpen)
            {
                Fail($"Bag G4 batch consume mismatch: item500={GetBagQuantityByItemId(500)}/"
                    + $"{bagG4InitialBatchQuantity - 1}, open={IsBagOpen}.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-10-BATCH-SUCCESS");
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
            if (!bagFlowPresenter.SelectGiftChoice(0)
                || !InvokeBagControl("BAG-20-GIFT-REWARD-DETAIL")
                || !IsBagSourceOpen)
            { Fail("Bag G4 equipment-fragment source setup failed."); yield break; }
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
            yield return CaptureBagG5Evidence("BAG-24-SOURCE-ACTION");
            if (!IsBagOpen || IsBagSourceOpen)
            { Fail("Bag G4 source action escaped Bag or left the source popup open."); yield break; }

            SelectBagItem(1111);
            InvokeBagControl("BAG-07-USE");
            bagFlowPresenter.SelectGiftChoice(0);
            InvokeBagControl("BAG-18-GIFT-CONFIRM");
        }

        public bool RunBagG4DirectUse()
        {
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
            yield return CaptureBagG5Evidence("BAG-18-GIFT-SUCCESS");
            if (!InvokeBagControl("BAG-02-CLOSE") || IsBagOpen)
            { Fail("Bag G4 close button did not return to main."); yield break; }
            yield return CaptureBagG5Evidence("BAG-02-CLOSE");
            mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
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
            services.Network.Disconnect();
            yield return null;
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected)
            {
                Fail($"Bag G4 disconnect was not observed: state={services.Network.State}.");
                yield break;
            }
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
                || GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 1
                || GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity - 1
                || GetBagQuantityByItemId(3201) != bagG4InitialDirectQuantity
                || GetBagQuantityByItemId(4621) <= bagG4InitialRewardQuantity
                || IsBagInputOpen || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 persisted/reconnect mismatch: open={IsBagOpen}, pending={services.ProtocolRegistry.PendingCount}, "
                    + $"500={GetBagQuantityByItemId(500)}/{bagG4InitialBatchQuantity - 1}, "
                    + $"1111={GetBagQuantityByItemId(1111)}/{bagG4InitialGiftQuantity - 1}, "
                    + $"3201={GetBagQuantityByItemId(3201)}/{bagG4InitialDirectQuantity}, "
                    + $"4621={GetBagQuantityByItemId(4621)}/{bagG4InitialRewardQuantity + 1}, "
                    + $"modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-01-RECONNECT");
            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Bag.Count != 0 || IsBagOpen || IsBagInputOpen
                || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 account-switch cleanup mismatch: login={IsLoginVisible}, count={services.Bag.Count}, "
                    + $"open={IsBagOpen}, modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
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
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Bag", "unity", "g5-20260727");
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
            if (string.Equals(controlId, "BAG-01-RECONNECT", StringComparison.Ordinal))
                File.Copy(path, BuildUiMigrationPath("bootstrap-bag.png"), true);
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
            RefreshDrawHotPoint();
            SetStatus($"Draw /224 op=1: pools={services.Draw.Count}, free={services.Draw.HasFreeDraw}.");
            if (validation) StartCoroutine(RequestValidationDrawNextFrame());
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
            if (GetLocalUserId() == 1 || !IsDrawOpen || services.Draw.Count != 3
                || result.Kind != 1 || result.DrawType != 1 || result.Rewards.Count != 1
                || !IsDrawResultVisible || !IsDrawEffectLoaded || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Draw final state mismatch: user={GetLocalUserId()}, open={IsDrawOpen}, pools={services.Draw.Count}, kind={result.Kind}, type={result.DrawType}, rewards={result.Rewards.Count}, result={IsDrawResultVisible}, effect={IsDrawEffectLoaded}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            Complete($"COMPLETE: current btn_zhaomu -> HappyDrawUI -> /224 op=1 three pools/free countdown/red-point -> op=2 kind=1 single free draw -> authoritative reward/result timeline; isolated user={GetLocalUserId()}");
        }

        public void SetDrawError(string message) { ShowToast(message, 3f); SetStatus(message); }

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
            CocosUiView previous = gameplayShopsPresenter.ActiveView;
            gameplayShopsPresenter.ShowFunction(functionId);
            CocosUiView target = gameplayShopsPresenter.ActiveView;
            if (services.UiStack.Current == previous && previous != target) services.UiStack.Pop();
            if (services.UiStack.Current != target) services.UiStack.Push(target);
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

        public void CompleteGameplayShopsValidation()
        {
            StartCoroutine(CaptureGameplayShopsValidation());
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
            mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
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
                mainView = mainView ?? services.UiRouter.FindBySource("UImainLayer", true);
                mainView.BindClick(EquipmentBagPath,
                    () => InvokeLuaOrFail(onEquipmentBagClicked, "HeroEquipment.OpenEquipment"), true);
                mainView.BindClick(FaBaoBagPath,
                    () => InvokeLuaOrFail(onFaBaoBagClicked, "HeroEquipment.OpenFaBao"), true);
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
                if (!heroEquipmentPresenter.ShowSlot(formationPosition, requestedSlot))
                    ShowHeroItemSource(requestedSlot);
                else
                    heroEquipmentDetailView.GameObject.transform.SetAsLastSibling();
            }
            else
            {
                heroEquipmentPresenter.Show(formationPosition, displayKind);
                heroEquipmentListView.GameObject.transform.SetAsLastSibling();
            }
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
            int strengthAfter, double faBaoUid, int formationPosition, string invalidReason, string repeatReason)
        {
            ShowHeroEquipment();
            uint equipmentId = checked((uint)equipmentUid);
            uint faBaoId = checked((uint)faBaoUid);
            bool restored = services.HeroEquipment.TryGet(equipmentId, out HeroEquipmentRecord equip)
                && equip.FormationPosition == 0 && equip.GetLevel(1) == strengthAfter
                && services.FaBao.TryGet(faBaoId, out FaBaoRecord treasure) && treasure.FormationPosition == 0;
            int equipmentMissing = heroEquipmentPresenter.MissingIconCount;
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.FaBao);
            int faBaoMissing = heroEquipmentPresenter.MissingIconCount;
            heroEquipmentPresenter.RenderKind(HeroEquipmentKind.Equipment);
            if (!restored || strengthAfter <= strengthBefore || equipmentMissing + faBaoMissing > 0)
            {
                Fail($"Hero equipment mutation mismatch: restored={restored}, strength={strengthBefore}->{strengthAfter}, missingIcons={equipmentMissing + faBaoMissing}.");
                return;
            }
            string failures = string.IsNullOrEmpty(invalidReason) && string.IsNullOrEmpty(repeatReason)
                ? string.Empty : $"; invalid rejected={invalidReason}; repeat rejected={repeatReason}; final lists reloaded";
            Complete($"COMPLETE: /319 equipment {equipmentId} wear@{formationPosition} -> strengthen {strengthBefore}->{strengthAfter} -> takeoff; fabao {faBaoId} wear@{formationPosition}/5 -> takeoff; stores/list/detail restored{failures}");
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
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            disconnectReason = reason;
            services.State.Change(AppState.Disconnected, reason);
            SetStatus($"Disconnected: {reason}");
            try { CallLua(onDisconnected, "Network.OnDisconnected", reason); }
            catch (Exception exception) { Fail(exception.Message); }
            services.Heroes.Clear();
            services.Formation.Clear();
            services.Bag.Clear();
            bagFlowPresenter?.CloseAll();
            bagFrameView?.SetVisible(false);
            bagView?.SetVisible(false);
            services.HeroEquipment.Clear();
            services.FaBao.Clear();
            heroG4ControlValidationRunning = false;
            pendingHeroEquipmentPosition = 0;
            heroEquipmentOpenedFromHeroDetails = false;
            formationPopupView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
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
            if (submenu != null) submenu.SetActive(visible);
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
                services.Resources, services.EquipmentCatalog,
                (item, quantity, target) => InvokeLuaOrFail(onBagUseClicked, "Bag.OnUseClicked",
                    item.Slot, quantity, target),
                functionId =>
                {
                    // Bag must not present another module's placeholder data as an
                    // authoritative destination. Keep the real source click bound,
                    // close only the source popup, and leave Bag active until that
                    // destination has completed its own migration gates.
                    SetStatus($"Bag source target is not migrated: function_id={functionId}; Bag remains active.");
                },
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
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            var candidates = services.Heroes.Items
                .Where(item => item.Id != currentHeroId && services.Formation.GetCombatPosition(item.Id) == 0)
                .Take(6).ToArray();
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
                if (actionText != null) actionText.text = currentHeroId == 0 ? "上阵" : "替换";
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
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.FaBao);
            heroEquipmentPresenter.HideDetails();
            heroEquipmentListView.SetVisible(false);
            heroEquipmentFragmentView.SetVisible(true);
            heroEquipmentFragmentView.GameObject.transform.SetAsLastSibling();
            heroFrameView.SetVisible(true);
            heroFrameView.GameObject.transform.SetAsLastSibling();
            RenderHeroEquipmentFragments();
        }

        private void RenderHeroEquipmentFragments()
        {
            BagItemRecord[] fragments = services.Bag.Items
                .Where(item => item.Name.Contains("法宝") && item.Name.Contains("碎片"))
                .Take(6)
                .ToArray();
            Transform root = heroEquipmentFragmentView.GameObject.transform;
            Text numberText = root.GetComponentsInChildren<Text>(true)
                .FirstOrDefault(value => value.name == "Number");
            if (numberText != null) numberText.text = $"数量：{fragments.Length}";
            for (int index = 1; index <= 6; index++)
            {
                Transform iconNode = root.GetComponentsInChildren<Transform>(true)
                    .FirstOrDefault(value => value.name == $"Icon_suipian_{index}");
                bool hasItem = index <= fragments.Length;
                if (iconNode == null) continue;
                iconNode.gameObject.SetActive(hasItem);
                if (!hasItem) continue;
                BagItemRecord item = fragments[index - 1];
                Image icon = iconNode.GetComponent<Image>();
                if (icon != null)
                {
                    icon.sprite = services.Resources.LoadItemIcon(item.Picture);
                    icon.preserveAspect = true;
                }
                Text name = iconNode.parent?.GetComponentsInChildren<Text>(true)
                    .FirstOrDefault(value => value.name == "Name");
                if (name != null) name.text = $"{item.Name} ×{item.Quantity}";
            }
            foreach (string disabledName in new[] { "xunbaoBtn", "recycle", "Button" })
            {
                foreach (Transform value in root.GetComponentsInChildren<Transform>(true)
                    .Where(value => value.name == disabledName))
                {
                    Button button = value.GetComponent<Button>();
                    if (button != null)
                    {
                        button.onClick.RemoveAllListeners();
                        button.interactable = false;
                    }
                }
            }
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
            if (first != null) SetTabText(first, "全部", true);
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
            heroEquipmentFragmentView = heroEquipmentFragmentView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/fabaosuipianbeibao");
            if (heroEquipmentListView == null || heroEquipmentDetailView == null || heroEquipmentChangeView == null
                || heroEquipmentCultivateView == null || heroEquipmentStrengthView == null
                || heroEquipmentFragmentView == null)
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
                heroEquipmentCultivateView, heroEquipmentStrengthView,
                services.HeroEquipment, services.FaBao, services.EquipmentCatalog, services.Resources,
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentWear, "HeroEquipment.Wear", (double)uid, position),
                (uid, position) => InvokeLuaOrFail(onHeroEquipmentTakeOff, "HeroEquipment.TakeOff", (double)uid, position),
                uid => InvokeLuaOrFail(onHeroEquipmentStrength, "HeroEquipment.Strength", (double)uid),
                (uid, position) => InvokeLuaOrFail(onFaBaoWear, "FaBao.Wear", (double)uid, position),
                uid => InvokeLuaOrFail(onFaBaoTakeOff, "FaBao.TakeOff", (double)uid),
                ConfigureHeroEquipmentStrengthFrame);
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
            label.font = titleText != null ? titleText.font : Resources.GetBuiltinResource<Font>("Arial.ttf");
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
            SetTabText(first, kind == HeroEquipmentKind.Equipment ? "装备" : "法宝", true);
            Button firstButton = first.GetComponent<Button>() ?? first.gameObject.AddComponent<Button>();
            firstButton.onClick.RemoveAllListeners();
            firstButton.onClick.AddListener(() =>
                InvokeLuaOrFail(kind == HeroEquipmentKind.Equipment ? onEquipmentBagClicked : onFaBaoBagClicked,
                    kind == HeroEquipmentKind.Equipment ? "HeroEquipment.TabEquipment" : "HeroEquipment.TabFaBao"));
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
            bool showFragments = kind == HeroEquipmentKind.FaBao;
            second.gameObject.SetActive(showFragments);
            SetTabText(second, "碎片", false);
            Button shardButton = second.GetComponent<Button>() ?? second.gameObject.AddComponent<Button>();
            shardButton.interactable = showFragments;
            shardButton.onClick.RemoveAllListeners();
            if (showFragments) shardButton.onClick.AddListener(ShowHeroEquipmentFragments);
        }

        private void ConfigureHeroEquipmentStrengthFrame()
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
                SetTabText(tab, labels[index], index == 0);
                Button button = tab.GetComponent<Button>() ?? tab.gameObject.AddComponent<Button>();
                button.onClick.RemoveAllListeners();
                button.interactable = false;
            }
            Transform fragmentTab = panel.Find("Button2_Runtime");
            if (fragmentTab != null) fragmentTab.gameObject.SetActive(false);
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
                case 7: InvokeLuaOrFail(onKunLunClicked, "Gameplay.KunLun"); break;
                case 8: InvokeLuaOrFail(onBloodFightClicked, "Gameplay.BloodFight"); break;
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

        private IEnumerator CaptureGameplayShopsValidation()
        {
            byte[] allTypes = { 2, 3, 4, 5, 6, 7, 8 };
            if (!services.GameplayShops.HasAll(allTypes) || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Gameplay shops state mismatch: pages={services.GameplayShops.PageCount}/7, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }

            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);

            ShowGameplayShop(15);
            gameplayShopsPresenter.SelectType(2, false);
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-gameplay-shop-jianghun.png"));
            yield return new WaitForSecondsRealtime(0.8f);

            ShowGameplayShop(16);
            gameplayShopsPresenter.SelectType(3, false);
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-gameplay-shop-arena.png"));
            yield return new WaitForSecondsRealtime(0.8f);

            ShowGameplayShop(17);
            gameplayShopsPresenter.SelectType(5, false);
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-gameplay-shop-blood.png"));
            yield return new WaitForSecondsRealtime(0.8f);

            if (!IsGameplayShopOpen || !gameplayShopsPresenter.IsAuthoritativeVisible
                || gameplayShopsPresenter.RenderedCount <= 0 || gameplayShopsPresenter.MissingIconCount != 0)
            {
                Fail($"Gameplay shops render mismatch: open={IsGameplayShopOpen}, authoritative={gameplayShopsPresenter.IsAuthoritativeVisible}, rendered={gameplayShopsPresenter.RenderedCount}, missing={gameplayShopsPresenter.MissingIconCount}.");
                yield break;
            }
            Complete($"COMPLETE: function_id=15/16/17 -> current JiangHunShop/WanFaShopMainUI -> /221 types 2,3,4,5,6,7,8 -> {services.GameplayShops.TotalItemCount(allTypes)} authoritative goods across 7 pages; read-only first phase");
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
            if (shopView == null) throw new InvalidOperationException("shop/shangcheng CocosUiBinding was not found.");
            shopPresenter = shopPresenter ?? new ShopPresenter(shopView, services.Shop, services.Currencies,
                services.Resources, services.ServerTime, ShowShopPurchaseConfirmation);
        }

        private void EnsureGameplayShopsPresenter()
        {
            soulShopView = soulShopView ?? services.UiRouter.FindBySource("shop/jianghunshop");
            multiShopView = multiShopView ?? services.UiRouter.FindBySource("shop/wanfashop");
            if (soulShopView == null) throw new InvalidOperationException("shop/jianghunshop CocosUiBinding was not found.");
            if (multiShopView == null) throw new InvalidOperationException("shop/wanfashop CocosUiBinding was not found.");
            gameplayShopsPresenter = gameplayShopsPresenter ?? new GameplayShopsPresenter(
                soulShopView, multiShopView, services.GameplayShops, services.Currencies,
                services.Resources, services.ServerTime,
                type => InvokeLuaOrFail(onGameplayShopTab, "Gameplay.Shops.Tab", (double)type),
                () => HandleBack());
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
            if (drawView == null || drawSingleResultView == null || drawTenResultView == null)
                throw new InvalidOperationException("Current HappyDraw imported CocosUiBindings were not found by full relative path.");
            drawPresenter = drawPresenter ?? new DrawPresenter(drawView, drawSingleResultView, drawTenResultView,
                services.Draw, services.ServerTime, services.Resources,
                (kind, type) => InvokeLuaOrFail(onDrawRequested, "Draw.Requested", (double)kind, (double)type),
                () => HandleBack());
        }

        private void EnsureGameplayPresenter()
        {
            gameplayView = gameplayView ?? services.UiRouter.FindBySource("shop/shop_bg");
            gameplayContentView = gameplayContentView ?? services.UiRouter.FindBySource("common/ActivityLayer");
            gameplayDetailView = gameplayDetailView ?? services.UiRouter.FindBySource("TaskPopupLayer");
            if (gameplayView == null || gameplayContentView == null || gameplayDetailView == null)
                throw new InvalidOperationException("Current Gameplay imported CocosUiBindings were not found by full relative path.");
            string marqueeRoleName = HasCommandLineFlag("-projectXGameplayValidation")
                ? "Test01"
                : (string.IsNullOrWhiteSpace(services.Player.Name) ? "Test01" : services.Player.Name);
            gameplayPresenter = gameplayPresenter ?? new GameplayPresenter(gameplayView, gameplayContentView, gameplayDetailView,
                services.Gameplay, services.Resources,
                id => InvokeLuaOrFail(onGameplayEntered, "Gameplay.Entered", (double)id), () => HandleBack(), marqueeRoleName);
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
            if (fengShenStoryView == null)
                throw new InvalidOperationException("Current FengShenStory imported CocosUiBinding was not found: fengshenliezhuan/fengshenliezhuanlLayer.");
            fengShenStoryPresenter = fengShenStoryPresenter ?? new FengShenStoryPresenter(fengShenStoryView, services.FengShenStory, () => HandleBack());
        }

        private void EnsureArenaPresenter(){arenaView=arenaView??services.UiRouter.FindBySource("common/JingjiLayer");if(arenaView==null)throw new InvalidOperationException("Current Arena imported CocosUiBinding was not found: common/JingjiLayer.");arenaPresenter=arenaPresenter??new ArenaPresenter(arenaView,services.Arena,()=>HandleBack());}

        private void EnsureKunLunPresenter(){kunLunView=kunLunView??services.UiRouter.FindBySource("kunlun/juezhankunlun");if(kunLunView==null)throw new InvalidOperationException("Current KunLun imported CocosUiBinding was not found: kunlun/juezhankunlun.");kunLunPresenter=kunLunPresenter??new KunLunPresenter(kunLunView,services.KunLun,()=>HandleBack());}

        private void EnsureBloodFightPresenter(){bloodFightView=bloodFightView??services.UiRouter.FindBySource("xuezhan/XuezhanMain");if(bloodFightView==null)throw new InvalidOperationException("Current BloodFight imported CocosUiBinding was not found: xuezhan/XuezhanMain.");bloodFightPresenter=bloodFightPresenter??new BloodFightPresenter(bloodFightView,services.BloodFight,()=>HandleBack());}

        private void EnsureXunBaoPresenter(){xunBaoView=xunBaoView??services.UiRouter.FindBySource("wanfa/XunbaoLayer");if(xunBaoView==null)throw new InvalidOperationException("Current XunBao imported CocosUiBinding was not found: wanfa/XunbaoLayer.");xunBaoPresenter=xunBaoPresenter??new XunBaoPresenter(xunBaoView,services.XunBao,()=>HandleBack());}

        private void EnsureSevenDayPresenter(){sevenDayView=sevenDayView??services.UiRouter.FindBySource("huodong/QiriLayer");if(sevenDayView==null)throw new InvalidOperationException("Current SevenDay imported CocosUiBinding was not found: huodong/QiriLayer.");sevenDayPresenter=sevenDayPresenter??new SevenDayPresenter(sevenDayView,services.SevenDay,()=>HandleBack());}
        private void EnsureWelfareActivityFramePresenter(){taskBackgroundView=taskBackgroundView??services.UiRouter.FindBySource("huodong/huodong_bg");if(taskBackgroundView==null)throw new InvalidOperationException("Current welfare activity background was not found: huodong/huodong_bg.");welfareActivityFramePresenter=welfareActivityFramePresenter??new WelfareActivityFramePresenter(taskBackgroundView,services.Currencies,()=>HandleBack(),()=>InvokeLuaOrFail(onStaminaClaimClicked,"WelfareActivity.StaminaClaim"),()=>InvokeLuaOrFail(onResourceRecoveryClicked,"WelfareActivity.ResourceRecovery"),()=>InvokeLuaOrFail(onFundsClicked,"WelfareActivity.GrowthFund",25d),()=>InvokeLuaOrFail(onFundsClicked,"WelfareActivity.ActiveFund",26d));}
        private void EnsureStaminaClaimPresenter(){EnsureWelfareActivityFramePresenter();staminaClaimView=staminaClaimView??services.UiRouter.FindBySource("huodong/tililingquLayer");if(staminaClaimView==null)throw new InvalidOperationException("Current StaminaClaim imported CocosUiBinding was not found: huodong/tililingquLayer.");staminaClaimPresenter=staminaClaimPresenter??new StaminaClaimPresenter(staminaClaimView,services.StaminaClaim,services.StaminaClaimCatalog,()=>HandleBack());}
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
            mainHudPresenter = new MainHudPresenter(mainView, services.Player, services.Currencies,
                services.Resources);
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
