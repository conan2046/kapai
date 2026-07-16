using System;
using System.Collections;
using System.Collections.Generic;
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
        public const string LoginButtonPath = "Layer/Login/Btn_Login";
        public const string BagPath = "Layer/Main_UI/ButtonGroup1/btn_Bag";
        public const string SettingsPath = "Layer/Main_UI/ButtonGroup7/btn_xitong";
        public const string TaskPath = "Layer/Main_UI/ButtonGroup5/btn_renwu";
        public const string HeroPath = "Layer/Main_UI/ButtonGroup1/btn_zhenrong";

        private GameServices services;
        private LuaFunction onConnected;
        private LuaFunction onDisconnected;
        private LuaFunction onPacket;
        private LuaFunction onLoginClicked;
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
        private CocosUiView loginBackgroundView;
        private CocosUiView loginView;
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
        public bool IsTaskOpen => taskBackgroundView != null && services?.UiStack.Current == taskBackgroundView;
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
                using (LuaFunction begin = services.Lua.GetFunction("Begin")) CallLua(begin, "Bootstrap.Begin");
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
            if (Input.GetKeyDown(KeyCode.Escape)) HandleBack();
        }

        private void OnDestroy()
        {
            onConnected?.Dispose();
            onDisconnected?.Dispose();
            onPacket?.Dispose();
            onLoginClicked?.Dispose();
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
            bagPresenter?.Dispose();
            rewardPresenter?.Dispose();
            heroPresenter?.Dispose();
            heroEquipmentPresenter?.Dispose();
            taskPresenter?.Dispose();
            mainTaskTracker?.Dispose();
            mainHudPresenter?.Dispose();
            loadingPresenter?.Dispose();
            toastPresenter?.Dispose();
            services?.State.Change(AppState.ShuttingDown, "ProjectXApp destroyed");
            services?.Dispose();
            if (Instance == this) Instance = null;
        }

        private void OnGUI()
        {
            GUI.depth = -1000;
            GUI.Box(new Rect(12f, 12f, 700f, 54f), $"ProjectX App\n{status}");
            if (!string.IsNullOrEmpty(disconnectReason)
                && GUI.Button(new Rect(12f, 72f, 180f, 36f), "Reconnect"))
                Reconnect();
        }

        public bool IsAutomation() => services?.Options.Automation ?? false;
        public bool HasCommandLineFlag(string flag) => services?.Options.HasFlag(flag) ?? false;
        public uint GetLocalUserId() => services?.Config.LocalUserId ?? 1;
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
                services.ProtocolRegistry.TrackSend(message.OutgoingCommand);
                services.Network.Send(message);
            }
            catch (Exception exception) { Fail($"Send failed: {exception.Message}"); }
        }

        public void ShowLoginUi()
        {
            loginView = services.UiRouter.FindBySource("Login/loginLayer");
            loginBackgroundView = services.UiRouter.FindBySource("Login/LoginBgLayer");
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
            services.UiStack.Clear();
            loginBackgroundView?.SetVisible(true);
            loginView?.SetVisible(true);
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
            if (loginView == null) { Fail("Login/loginLayer CocosUiBinding was not found."); return; }
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
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowMainUi()
        {
            mainView = services.UiRouter.FindBySource("UImainLayer", true);
            if (mainView == null) { Fail("UImainLayer CocosUiBinding was not found."); return; }
            loginView?.SetVisible(false);
            loginBackgroundView?.SetVisible(false);
            services.UiStack.SetRoot(mainView);
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
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
            services.Heroes.Clear();
            services.Formation.Clear();
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
        private static IEnumerator InvokeButtonNextFrame(Button button) { yield return null; button.onClick.Invoke(); }

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
