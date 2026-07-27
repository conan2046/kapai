using System;
using System.IO;
using System.Reflection;
using ProjectX.Core;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace ProjectX.Editor
{
    [InitializeOnLoad]
    public static class BootstrapAppRunner
    {
        private const string ArmedKey = "ProjectX.BootstrapApp.Armed";
        private const string StartTimeKey = "ProjectX.BootstrapApp.StartTime";
        private const string ReconnectPhaseKey = "ProjectX.BootstrapApp.ReconnectPhase";
        private const string ScreenshotPendingKey = "ProjectX.BootstrapApp.ScreenshotPending";
        private const string ScreenshotStartKey = "ProjectX.BootstrapApp.ScreenshotStart";
        private const string SettingsPhaseKey = "ProjectX.BootstrapApp.SettingsPhase";
        private const string LoginPhaseKey = "ProjectX.BootstrapApp.LoginPhase";
        private const double DefaultTimeoutSeconds = 300d;
        private const string BootstrapScene = "Assets/ProjectX/Scenes/Bootstrap.unity";
        private const int RequiredGameViewWidth = 1334;
        private const int RequiredGameViewHeight = 750;

        static BootstrapAppRunner()
        {
            EditorApplication.update -= Monitor;
            EditorApplication.update += Monitor;
            EditorApplication.delayCall -= ApplyRequiredGameViewResolution;
            EditorApplication.delayCall += ApplyRequiredGameViewResolution;
        }

        [MenuItem("Tools/ProjectX App/Set GameView 1334x750", priority = 89)]
        public static void ApplyRequiredGameViewResolution()
        {
            if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
            SetGameViewResolution(RequiredGameViewWidth, RequiredGameViewHeight);
        }

        [MenuItem("Tools/ProjectX App/Run Bootstrap Validation", priority = 91)]
        public static void Run()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
                throw new InvalidOperationException("Unity is already entering or running Play Mode.");
            if (!File.Exists(Path.Combine(Directory.GetParent(Application.dataPath).FullName, BootstrapScene)))
                throw new FileNotFoundException("Bootstrap scene is missing. Rebuild it first.", BootstrapScene);

            EditorSceneManager.OpenScene(BootstrapScene);
            ApplyRequiredGameViewResolution();
            SessionState.SetBool(ArmedKey, true);
            SessionState.SetString(StartTimeKey, EditorApplication.timeSinceStartup.ToString("R"));
            SessionState.SetInt(ReconnectPhaseKey, 0);
            SessionState.SetBool(ScreenshotPendingKey, false);
            SessionState.SetInt(SettingsPhaseKey, 0);
            SessionState.SetInt(LoginPhaseKey, 0);
            DeletePreviousResult();
            Debug.Log("[BootstrapAppRunner] Runner armed; entering Play Mode.");
            EditorApplication.isPlaying = true;
        }

        public static void RunBatch()
        {
            if (Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXAutomation") < 0)
                throw new InvalidOperationException("RunBatch requires -projectXAutomation.");
            Run();
        }

        private static void SetGameViewResolution(int width, int height)
        {
            Assembly editorAssembly = typeof(EditorWindow).Assembly;
            Type sizesType = editorAssembly.GetType("UnityEditor.GameViewSizes", true);
            Type singletonType = typeof(ScriptableSingleton<>).MakeGenericType(sizesType);
            object sizes = singletonType.GetProperty("instance", BindingFlags.Public | BindingFlags.Static)?.GetValue(null);
            object group = sizesType.GetProperty("currentGroup", BindingFlags.Public | BindingFlags.Instance)?.GetValue(sizes);
            Type groupType = group?.GetType() ?? throw new InvalidOperationException("GameView size group is unavailable.");
            MethodInfo getBuiltinCount = groupType.GetMethod("GetBuiltinCount", BindingFlags.Public | BindingFlags.Instance);
            MethodInfo getCustomCount = groupType.GetMethod("GetCustomCount", BindingFlags.Public | BindingFlags.Instance);
            MethodInfo getSize = groupType.GetMethod("GetGameViewSize", BindingFlags.Public | BindingFlags.Instance);
            int count = (int)getBuiltinCount.Invoke(group, null) + (int)getCustomCount.Invoke(group, null);
            int selected = -1;
            for (int index = 0; index < count; index++)
            {
                object size = getSize.Invoke(group, new object[] { index });
                Type sizeType = size.GetType();
                int candidateWidth = (int)sizeType.GetProperty("width").GetValue(size);
                int candidateHeight = (int)sizeType.GetProperty("height").GetValue(size);
                if (candidateWidth == width && candidateHeight == height) { selected = index; break; }
            }
            if (selected < 0)
            {
                Type sizeType = editorAssembly.GetType("UnityEditor.GameViewSize", true);
                Type sizeKindType = editorAssembly.GetType("UnityEditor.GameViewSizeType", true);
                object fixedResolution = Enum.Parse(sizeKindType, "FixedResolution");
                object size = Activator.CreateInstance(sizeType, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic,
                    null, new[] { fixedResolution, (object)width, height, $"ProjectX {width}x{height}" }, null);
                groupType.GetMethod("AddCustomSize", BindingFlags.Public | BindingFlags.Instance).Invoke(group, new[] { size });
                selected = count;
            }
            Type gameViewType = editorAssembly.GetType("UnityEditor.GameView", true);
            EditorWindow gameView = EditorWindow.GetWindow(gameViewType);
            gameViewType.GetProperty("selectedSizeIndex", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
                ?.SetValue(gameView, selected);
            gameView.Repaint();
            Debug.Log($"[BootstrapAppRunner] GameView fixed at {width}x{height}.");
        }

        private static void Monitor()
        {
            if (!SessionState.GetBool(ArmedKey, false) || !EditorApplication.isPlaying) return;

            ProjectXApp app = ProjectXApp.Instance;
            string status = app?.Status ?? "Waiting for ProjectXApp...";
            bool reconnectValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXReconnectValidation") >= 0;
            bool manualReconnectValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXManualReconnectValidation") >= 0;
            bool bagG4Validation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXBagG4Validation") >= 0;
            bool settingsValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXSettingsValidation") >= 0;
            bool taskG4Validation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXTaskG4Validation") >= 0;
            bool taskValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXTaskValidation") >= 0
                || taskG4Validation;
            bool playerHudValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXPlayerHudValidation") >= 0;
            bool heroValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroBagValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroG4Validation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroLockedValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFormationMutationValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFormationInvalidValidation") >= 0;
            bool heroEquipmentValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipMutationValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipG4Validation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipMaterialValidation") >= 0;
            bool mailValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXMailValidation") >= 0;
            bool shopValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXShopValidation") >= 0;
            bool gameplayShopsValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXGameplayShopsValidation") >= 0;
            bool friendValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFriendValidation") >= 0;
            bool chatValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXChatValidation") >= 0;
            bool teamValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXTeamValidation") >= 0;
            bool guildValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXGuildValidation") >= 0;
            bool worldValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXWorldBattleValidation") >= 0;
            bool welfareValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXWelfareValidation") >= 0;
            bool activityValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXActivityValidation") >= 0;
            bool drawValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXDrawValidation") >= 0;
            bool gameplayValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXGameplayValidation") >= 0;
            bool youLiValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXYouLiValidation") >= 0;
            bool fengShenStoryValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFengShenStoryValidation") >= 0;
            bool arenaValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXArenaValidation") >= 0;
            bool kunLunValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXKunLunValidation") >= 0;
            bool bloodFightValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXBloodFightValidation") >= 0;
            bool xunBaoValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXXunBaoValidation") >= 0;
            bool sevenDayValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXSevenDayValidation") >= 0;
            bool staminaClaimValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXStaminaClaimValidation") >= 0;
            bool resourceRecoveryValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXResourceRecoveryValidation") >= 0;
            bool fundsValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFundsValidation") >= 0;
            bool loginValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXLoginValidation") >= 0;
            bool requiresReconnectValidation = reconnectValidation || manualReconnectValidation;

            if (loginValidation && status == "Login UI ready.")
            {
                int loginPhase = SessionState.GetInt(LoginPhaseKey, 0);
                if (loginPhase == 0)
                {
                    if (!app.ValidateLoginUi(out string loginDetail))
                    {
                        WriteResult(false, "Login UI validation failed: " + loginDetail);
                        Finish(false);
                        return;
                    }
                    string screenshot = GetLoginScreenshotPath();
                    Directory.CreateDirectory(Path.GetDirectoryName(screenshot));
                    if (File.Exists(screenshot)) File.Delete(screenshot);
                    ScreenCapture.CaptureScreenshot(screenshot);
                    SessionState.SetInt(LoginPhaseKey, 1);
                    Debug.Log("[BootstrapAppRunner] Login code evidence validated; waiting for screenshot.");
                    return;
                }
                if (loginPhase == 1 && File.Exists(GetLoginScreenshotPath())
                    && new FileInfo(GetLoginScreenshotPath()).Length > 0)
                {
                    SessionState.SetInt(LoginPhaseKey, 2);
                    app.InvokeLoginForValidation();
                    return;
                }
            }
            if (loginValidation && status == "No role found. RoleCreateLayer is active."
                && SessionState.GetInt(LoginPhaseKey, 0) == 2)
            {
                if (!app.ValidateRoleCreateUi(out string roleDetail))
                {
                    WriteResult(false, "Role creation UI validation failed: " + roleDetail);
                    Finish(false);
                    return;
                }
                SessionState.SetInt(LoginPhaseKey, 3);
                Debug.Log("[BootstrapAppRunner] RoleCreateLayer and Create_5/Create_4 animations validated.");
                app.InvokeRoleCreateForValidation();
                return;
            }
            if (status.StartsWith("COMPLETE:", StringComparison.Ordinal))
            {
                if (taskG4Validation
                    && !status.StartsWith("COMPLETE: Task G4", StringComparison.Ordinal))
                    return;
                if (taskValidation && !taskG4Validation
                    && !status.StartsWith("COMPLETE: real btn_renwu", StringComparison.Ordinal))
                    return;
                if (loginValidation)
                {
                    int loginPhase = SessionState.GetInt(LoginPhaseKey, 0);
                    bool requireNoticeResponse = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXRequireNoticeResponse") >= 0;
                    if (loginPhase != 3 && loginPhase != 4)
                    {
                        WriteResult(false, status + " (isolated role-creation evidence phase did not complete)");
                        Finish(false);
                        return;
                    }
                    if (requireNoticeResponse && loginPhase == 3)
                    {
                        string noticeScreenshot = GetLoginNoticeScreenshotPath();
                        Directory.CreateDirectory(Path.GetDirectoryName(noticeScreenshot));
                        if (File.Exists(noticeScreenshot)) File.Delete(noticeScreenshot);
                        ScreenCapture.CaptureScreenshot(noticeScreenshot);
                        SessionState.SetInt(LoginPhaseKey, 4);
                        Debug.Log("[BootstrapAppRunner] /88 NoticeLayer validated; waiting for screenshot.");
                        return;
                    }
                    if (requireNoticeResponse && (loginPhase != 4 || !File.Exists(GetLoginNoticeScreenshotPath())
                        || new FileInfo(GetLoginNoticeScreenshotPath()).Length == 0)) return;
                    WriteResult(true, status + " | login code/UI/animation evidence passed");
                    Finish(true);
                    return;
                }
                if (bagG4Validation)
                {
                    // Bag G4 owns its 26 state captures and finishes by exercising
                    // account-switch cleanup, so the expected terminal UI is Login,
                    // not an open Bag on UiStack.
                    WriteResult(true, status);
                    Finish(true);
                    return;
                }
                if (taskG4Validation)
                {
                    WriteResult(true, status);
                    Finish(true);
                    return;
                }
                int phase = SessionState.GetInt(ReconnectPhaseKey, 0);
                int settingsPhase = SessionState.GetInt(SettingsPhaseKey, 0);
                bool checkingSettings = settingsValidation && settingsPhase == 1;
                bool checkingTask = taskValidation;
                bool checkingPlayerHud = playerHudValidation;
                bool checkingHero = heroValidation;
                bool checkingHeroEquipment = heroEquipmentValidation;
                bool checkingMail = mailValidation;
                bool checkingShop = shopValidation;
                bool checkingGameplayShops = gameplayShopsValidation;
                bool checkingFriend = friendValidation;
                bool checkingChat = chatValidation;
                bool checkingTeam = teamValidation;
                bool checkingGuild = guildValidation;
                bool checkingWorld = worldValidation;
                bool checkingWelfare = welfareValidation;
                bool checkingActivity = activityValidation;
                bool checkingDraw = drawValidation;
                bool checkingGameplay = gameplayValidation;
                bool checkingYouLi = youLiValidation;
                bool checkingFengShenStory = fengShenStoryValidation;
                bool checkingArena = arenaValidation;
                bool checkingKunLun = kunLunValidation;
                bool checkingBloodFight = bloodFightValidation;
                bool checkingXunBao = xunBaoValidation;
                bool checkingSevenDay = sevenDayValidation;
                bool checkingStaminaClaim = staminaClaimValidation;
                bool checkingResourceRecovery = resourceRecoveryValidation;
                bool checkingFunds = fundsValidation;
                if (settingsValidation && settingsPhase == 2)
                {
                    if (!app.IsLoginVisible || app.NetworkState != ProjectX.Network.NetworkState.Disconnected)
                    {
                        WriteResult(false, status + " (account switch did not leave the app at disconnected login UI)");
                        Finish(false);
                        return;
                    }
                    WriteResult(true, status);
                    Finish(true);
                    return;
                }
                if (requiresReconnectValidation && phase == 1) return;
                if (!SessionState.GetBool(ScreenshotPendingKey, false))
                {
                    if (checkingTask && !app.ValidateFoundation(out string foundationDetail))
                    {
                        WriteResult(false, status + " (foundation validation failed: " + foundationDetail + ")");
                        Finish(false);
                        return;
                    }
                    if (!checkingPlayerHud && (checkingTask ? !app.IsTaskOpen : checkingSettings ? !app.IsSettingsOpen
                        : checkingHeroEquipment ? !app.IsHeroEquipmentOpen : checkingHero
                            ? !app.IsHeroOpen && Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroG4Validation") < 0
                        : checkingMail ? !app.IsMailOpen : checkingGameplayShops ? !app.IsGameplayShopOpen : checkingShop ? !app.IsShopOpen
                        : checkingFriend ? !app.IsFriendOpen : checkingChat ? !app.IsChatOpen
                        : checkingTeam ? !app.IsTeamOpen : checkingGuild ? !app.IsGuildOpen
                        : checkingWorld ? !app.IsWorldOpen : checkingWelfare ? !app.IsWelfareOpen
                        : checkingActivity ? !app.IsActivityOpen : checkingDraw ? !app.IsDrawOpen
                        : checkingFunds ? !app.IsFundsOpen : checkingResourceRecovery ? !app.IsResourceRecoveryOpen : checkingStaminaClaim ? !app.IsStaminaClaimOpen : checkingSevenDay ? !app.IsSevenDayOpen : checkingXunBao ? !app.IsXunBaoOpen : checkingBloodFight ? !app.IsBloodFightOpen : checkingKunLun ? !app.IsKunLunOpen : checkingArena ? !app.IsArenaOpen : checkingFengShenStory ? !app.IsFengShenStoryOpen : checkingYouLi ? !app.IsYouLiOpen : checkingGameplay ? !app.IsGameplayOpen : !app.IsBagOpen))
                    {
                        WriteResult(false, status + (checkingTask
                            ? " (task UI was not pushed onto UiStack)"
                            : checkingSettings
                            ? " (settings UI was not pushed onto UiStack)"
                            : checkingHeroEquipment
                            ? " (hero equipment UI was not pushed onto UiStack)"
                            : checkingHero
                            ? " (hero UI was not pushed onto UiStack)"
                            : checkingMail
                            ? " (mail UI was not pushed onto UiStack)"
                            : checkingGameplayShops
                            ? " (gameplay shops UI was not pushed onto UiStack)"
                            : checkingShop
                            ? " (shop UI was not pushed onto UiStack)"
                            : checkingFriend
                            ? " (friend UI was not pushed onto UiStack)"
                            : checkingChat
                            ? " (chat UI was not pushed onto UiStack)"
                            : checkingTeam
                            ? " (team UI was not pushed onto UiStack)"
                            : checkingGuild
                            ? " (guild UI was not pushed onto UiStack)"
                            : checkingWorld
                            ? " (world UI was not pushed onto UiStack)"
                            : checkingWelfare
                            ? " (welfare UI was not pushed onto UiStack)"
                            : checkingActivity
                            ? " (activity UI was not pushed onto UiStack)"
                            : checkingDraw
                            ? " (draw UI was not pushed onto UiStack)"
                            : checkingSevenDay
                            ? " (SevenDay UI was not pushed onto UiStack)"
                            : checkingStaminaClaim
                            ? " (StaminaClaim UI was not pushed onto UiStack)"
                            : checkingResourceRecovery
                            ? " (ResourceRecovery UI was not pushed onto UiStack)"
                            : checkingFunds
                            ? " (Funds UI was not pushed onto UiStack)"
                            : checkingXunBao
                            ? " (XunBao UI was not pushed onto UiStack)"
                            : checkingBloodFight
                            ? " (BloodFight UI was not pushed onto UiStack)"
                            : checkingKunLun
                            ? " (KunLun UI was not pushed onto UiStack)"
                            : checkingArena
                            ? " (Arena UI was not pushed onto UiStack)"
                            : checkingFengShenStory
                            ? " (FengShenStory UI was not pushed onto UiStack)"
                            : checkingYouLi
                            ? " (YouLi UI was not pushed onto UiStack)"
                            : checkingGameplay
                            ? " (gameplay UI was not pushed onto UiStack)"
                            : " (bag UI was not pushed onto UiStack)"));
                        Finish(false);
                        return;
                    }
                    if (checkingHeroEquipment && app.HeroEquipmentMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.HeroEquipmentMissingIconCount} equipment icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (checkingMail && app.MailMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.MailMissingIconCount} mail attachment icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (checkingShop && app.ShopMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.ShopMissingIconCount} shop icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (checkingWelfare && app.WelfareMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.WelfareMissingIconCount} welfare icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (checkingGameplayShops && app.GameplayShopMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.GameplayShopMissingIconCount} gameplay-shop icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (checkingGameplay && app.GameplayMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.GameplayMissingIconCount} gameplay icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    if (!checkingTask && !checkingSettings && !checkingHero && !checkingHeroEquipment && !checkingMail && !checkingShop && !checkingGameplayShops && !checkingFriend && !checkingChat && !checkingTeam && !checkingGuild && !checkingWorld && !checkingWelfare && !checkingActivity && !checkingDraw && !checkingGameplay && !checkingYouLi && !checkingFengShenStory && !checkingArena && !checkingKunLun && !checkingBloodFight && !checkingXunBao && !checkingSevenDay && !checkingStaminaClaim && !checkingResourceRecovery && !checkingFunds && app.BagMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.BagMissingIconCount} item icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    string screenshotPath = checkingPlayerHud ? GetMainHudScreenshotPath()
                        : checkingTask ? GetTaskScreenshotPath() : checkingHero || checkingHeroEquipment ? GetHeroScreenshotPath()
                        : checkingMail ? GetMailScreenshotPath() : checkingGameplayShops ? GetGameplayShopsScreenshotPath() : checkingShop ? GetShopScreenshotPath()
                        : checkingFriend ? GetFriendScreenshotPath() : checkingChat ? GetChatScreenshotPath()
                        : checkingTeam ? GetTeamScreenshotPath() : checkingGuild ? GetGuildScreenshotPath()
                        : checkingWorld ? GetWorldScreenshotPath() : checkingWelfare ? GetWelfareScreenshotPath()
                        : checkingActivity ? GetActivityScreenshotPath() : checkingDraw ? GetDrawScreenshotPath()
                        : checkingFunds ? GetFundsScreenshotPath() : checkingResourceRecovery ? GetResourceRecoveryScreenshotPath() : checkingStaminaClaim ? GetStaminaClaimScreenshotPath() : checkingSevenDay ? GetSevenDayScreenshotPath() : checkingXunBao ? GetXunBaoScreenshotPath() : checkingBloodFight ? GetBloodFightScreenshotPath() : checkingKunLun ? GetKunLunScreenshotPath() : checkingArena ? GetArenaScreenshotPath() : checkingFengShenStory ? GetFengShenStoryScreenshotPath() : checkingYouLi ? GetYouLiScreenshotPath() : checkingGameplay ? GetGameplayScreenshotPath() : GetBagScreenshotPath();
                    Directory.CreateDirectory(Path.GetDirectoryName(screenshotPath));
                    ScreenCapture.CaptureScreenshot(screenshotPath);
                    SessionState.SetBool(ScreenshotPendingKey, true);
                    SessionState.SetString(ScreenshotStartKey, EditorApplication.timeSinceStartup.ToString("R"));
                    return;
                }

                double.TryParse(SessionState.GetString(ScreenshotStartKey, "0"), out double screenshotStart);
                if (EditorApplication.timeSinceStartup - screenshotStart < 0.75d) return;
                SessionState.SetBool(ScreenshotPendingKey, false);
                if (checkingPlayerHud)
                {
                    WriteResult(true, status);
                    Finish(true);
                    return;
                }
                bool realHeroClose = checkingHero && (Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroG4Validation") >= 0
                    || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroLockedValidation") >= 0);
                bool backHandled = realHeroClose ? app.InvokeHeroCloseForValidation() : app.HandleBack();
                if (checkingHero && Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFormationPopupValidation") >= 0)
                    backHandled = app.HandleBack() && backHandled;
                if (!backHandled || (checkingTask ? app.IsTaskOpen : checkingSettings ? app.IsSettingsOpen
                    : checkingHeroEquipment ? app.IsHeroEquipmentOpen : checkingHero ? app.IsHeroOpen
                    : checkingMail ? app.IsMailOpen : checkingGameplayShops ? app.IsGameplayShopOpen : checkingShop ? app.IsShopOpen
                    : checkingFriend ? app.IsFriendOpen : checkingChat ? app.IsChatOpen
                    : checkingTeam ? app.IsTeamOpen : checkingGuild ? app.IsGuildOpen
                    : checkingWorld ? app.IsWorldOpen : checkingWelfare ? app.IsWelfareOpen
                    : checkingActivity ? app.IsActivityOpen : checkingDraw ? app.IsDrawOpen
                    : checkingFunds ? app.IsFundsOpen : checkingResourceRecovery ? app.IsResourceRecoveryOpen : checkingStaminaClaim ? app.IsStaminaClaimOpen : checkingSevenDay ? app.IsSevenDayOpen : checkingXunBao ? app.IsXunBaoOpen : checkingBloodFight ? app.IsBloodFightOpen : checkingKunLun ? app.IsKunLunOpen : checkingArena ? app.IsArenaOpen : checkingFengShenStory ? app.IsFengShenStoryOpen : checkingYouLi ? app.IsYouLiOpen : checkingGameplay ? app.IsGameplayOpen : app.IsBagOpen))
                {
                    WriteResult(false, status + (checkingTask
                        ? " (Esc/back did not return from task UI to main UI)"
                        : checkingSettings
                        ? " (Esc/back did not return from settings UI to main UI)"
                        : checkingHeroEquipment
                        ? " (Esc/back did not return from hero equipment UI to hero UI)"
                        : checkingHero
                        ? " (Esc/back did not return from hero UI to main UI)"
                        : checkingMail
                        ? " (Esc/back did not return from mail UI to main UI)"
                        : checkingGameplayShops
                        ? " (Esc/back did not return from gameplay shops UI to gameplay hub)"
                        : checkingShop
                        ? " (Esc/back did not return from shop UI to main UI)"
                        : checkingFriend
                        ? " (Esc/back did not return from friend UI to main UI)"
                        : checkingChat
                        ? " (Esc/back did not return from chat UI to main UI)"
                        : checkingTeam
                        ? " (Esc/back did not return from team UI to main UI)"
                        : checkingGuild
                        ? " (Esc/back did not return from guild UI to main UI)"
                        : checkingWorld
                        ? " (Esc/back did not return from world UI to main UI)"
                            : checkingWelfare
                            ? " (Esc/back did not return from welfare UI to main UI)"
                            : checkingActivity
                            ? " (Esc/back did not return from activity UI to main UI)"
                            : checkingDraw
                            ? " (Esc/back did not return from draw UI to main UI)"
                            : checkingSevenDay
                            ? " (Esc/back did not return from SevenDay UI to gameplay hub)"
                            : checkingStaminaClaim
                            ? " (Esc/back did not return from StaminaClaim UI to gameplay hub)"
                            : checkingResourceRecovery
                            ? " (Esc/back did not return from ResourceRecovery UI to gameplay hub)"
                            : checkingFunds
                            ? " (Esc/back did not return from Funds UI to gameplay hub)"
                            : checkingXunBao
                            ? " (Esc/back did not return from XunBao UI to gameplay hub)"
                            : checkingBloodFight
                            ? " (Esc/back did not return from BloodFight UI to gameplay hub)"
                            : checkingKunLun
                            ? " (Esc/back did not return from KunLun UI to gameplay hub)"
                            : checkingArena
                            ? " (Esc/back did not return from Arena UI to gameplay hub)"
                            : checkingFengShenStory
                            ? " (Esc/back did not return from FengShenStory UI to gameplay hub)"
                            : checkingYouLi
                            ? " (Esc/back did not return from YouLi UI to gameplay hub)"
                            : checkingGameplay
                            ? " (Esc/back did not return from gameplay UI to main UI)"
                            : " (Esc/back did not return from bag UI to main UI)"));
                    Finish(false);
                    return;
                }

                if (settingsValidation && settingsPhase == 0)
                {
                    SessionState.SetInt(SettingsPhaseKey, 1);
                    app.RunSettingsValidation();
                    return;
                }

                if (settingsValidation && settingsPhase == 1)
                {
                    SessionState.SetInt(SettingsPhaseKey, 2);
                    app.RunSettingsAccountValidation();
                    return;
                }

                if (requiresReconnectValidation && phase == 0)
                {
                    SessionState.SetInt(ReconnectPhaseKey, 1);
                    Debug.Log("[BootstrapAppRunner] INITIAL_COMPLETE: waiting for the server disconnect.");
                    return;
                }
                WriteResult(true, status);
                Finish(true);
                return;
            }

            if (requiresReconnectValidation && SessionState.GetInt(ReconnectPhaseKey, 0) == 1
                && (status.StartsWith("Disconnected:", StringComparison.Ordinal)
                    || status.StartsWith("Auto reconnect", StringComparison.Ordinal)))
            {
                SessionState.SetInt(ReconnectPhaseKey, 2);
                Debug.Log("[BootstrapAppRunner] DISCONNECT_OBSERVED: waiting for recovery.");
            }

            if (manualReconnectValidation && SessionState.GetInt(ReconnectPhaseKey, 0) == 2
                && File.Exists(GetManualReconnectRequestPath()))
            {
                File.Delete(GetManualReconnectRequestPath());
                Debug.Log("[BootstrapAppRunner] MANUAL_RECONNECT_REQUESTED.");
                app.Reconnect();
            }

            if (requiresReconnectValidation && SessionState.GetInt(ReconnectPhaseKey, 0) == 2
                && Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroG4Validation") >= 0
                && status.StartsWith("Hero formation UI active:", StringComparison.Ordinal))
            {
                SessionState.SetInt(ReconnectPhaseKey, 3);
                if (!app.InvokeHeroEntryForReconnectValidation())
                {
                    WriteResult(false, status + " (real Hero entry could not be clicked after reconnect)");
                    Finish(false);
                    return;
                }
                Debug.Log("[BootstrapAppRunner] HERO_RECONNECT_ENTRY_CLICKED: rerunning real controls.");
                return;
            }

            if (requiresReconnectValidation && SessionState.GetInt(ReconnectPhaseKey, 0) == 3
                && Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroG4Validation") >= 0
                && status.StartsWith("Hero formation UI active:", StringComparison.Ordinal))
            {
                SessionState.SetInt(ReconnectPhaseKey, 4);
                if (!app.RunHeroG4FromCurrentSnapshotForReconnectValidation())
                {
                    WriteResult(false, status + " (authoritative Hero snapshot could not start the reconnect control rerun)");
                    Finish(false);
                    return;
                }
                Debug.Log("[BootstrapAppRunner] HERO_RECONNECT_CONTROLS_STARTED: authoritative snapshot ready.");
                return;
            }

            if (!requiresReconnectValidation && status.IndexOf("failed", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                WriteResult(false, status);
                Finish(false);
                return;
            }

            if (!double.TryParse(SessionState.GetString(StartTimeKey, "0"), out double startTime))
                startTime = EditorApplication.timeSinceStartup;
            double timeoutSeconds = GetRunnerTimeoutSeconds();
            if (requiresReconnectValidation)
                timeoutSeconds = Math.Max(timeoutSeconds, 120d);
            if (EditorApplication.timeSinceStartup - startTime <= timeoutSeconds) return;

            WriteResult(false, status + " (timeout)");
            Debug.LogError("[BootstrapAppRunner] Timed out before the package response was received.");
            Finish(false);
        }

        private static double GetRunnerTimeoutSeconds()
        {
            const string prefix = "-projectXRunnerTimeoutSeconds=";
            foreach (string argument in Environment.GetCommandLineArgs())
            {
                if (!argument.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) continue;
                if (double.TryParse(argument.Substring(prefix.Length), out double value))
                    return Math.Max(60d, Math.Min(900d, value));
            }
            return DefaultTimeoutSeconds;
        }

        private static void Finish(bool success)
        {
            SessionState.SetBool(ArmedKey, false);
            EditorApplication.Exit(success ? 0 : 1);
        }

        private static void WriteResult(bool success, string status)
        {
            string path = GetResultPath();
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ProjectXApp app = ProjectXApp.Instance;
            uint userId = app?.GetLocalUserId() ?? 0;
            uint roleId = app?.GetValidationRoleId() ?? 0;
            string scenario = GetLaunchArgumentValue("-projectXValidationScenario=");
            string json = "{\n"
                + $"  \"success\": {(success ? "true" : "false")},\n"
                + $"  \"status\": \"{EscapeJson(status)}\",\n"
                + $"  \"scenario\": \"{EscapeJson(scenario)}\",\n"
                + $"  \"userId\": {userId},\n"
                + $"  \"roleId\": {roleId},\n"
                + $"  \"screenWidth\": {Screen.width},\n"
                + $"  \"screenHeight\": {Screen.height},\n"
                + $"  \"utc\": \"{DateTime.UtcNow:O}\"\n"
                + "}\n";
            File.WriteAllText(path, json);
            Debug.Log($"[BootstrapAppRunner] Result written: {path}");
        }

        private static string GetLaunchArgumentValue(string prefix)
        {
            foreach (string argument in Environment.GetCommandLineArgs())
                if (argument.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                    return argument.Substring(prefix.Length);
            return string.Empty;
        }

        private static string EscapeJson(string value) =>
            (value ?? string.Empty)
                .Replace("\\", "\\\\")
                .Replace("\"", "\\\"")
                .Replace("\r", "\\r")
                .Replace("\n", "\\n");

        private static void DeletePreviousResult()
        {
            string path = GetResultPath();
            if (File.Exists(path)) File.Delete(path);
        }

        private static string GetResultPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-app-result.json");
        }

        private static string GetBagScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-bag.png");
        }

        private static string GetLoginScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-login.png");
        }

        private static string GetLoginNoticeScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-login-notice.png");
        }

        private static string GetTaskScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-task.png");
        }

        private static string GetMainHudScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-main-hud.png");
        }

        private static string GetHeroScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-hero.png");
        }

        private static string GetMailScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-mail.png");
        }

        private static string GetShopScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-shop.png");
        }

        private static string GetGameplayShopsScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-gameplay-shop-blood.png");
        }

        private static string GetFriendScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-friend.png");
        }

        private static string GetChatScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-chat.png");
        }

        private static string GetTeamScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-team.png");
        }

        private static string GetGuildScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-guild.png");
        }

        private static string GetWorldScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-world-final.png");
        }

        private static string GetWelfareScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-welfare.png");
        }

        private static string GetActivityScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-activity.png");
        }

        private static string GetDrawScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-draw.png");
        }

        private static string GetGameplayScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-gameplay.png");
        }

        private static string GetYouLiScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-youli.png");
        }

        private static string GetFengShenStoryScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-fengshen-story.png");
        }

        private static string GetArenaScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-arena.png");
        }

        private static string GetKunLunScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-kunlun.png");
        }

        private static string GetBloodFightScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-blood-fight.png");
        }

        private static string GetXunBaoScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-xunbao.png");
        }

        private static string GetSevenDayScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-seven-day.png");
        }

        private static string GetStaminaClaimScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-stamina-claim.png");
        }

        private static string GetResourceRecoveryScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-resource-recovery.png");
        }

        private static string GetFundsScreenshotPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-funds.png");
        }

        private static string GetManualReconnectRequestPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "manual-reconnect.request");
        }

    }
}
