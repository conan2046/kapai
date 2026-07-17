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
        private const double TimeoutSeconds = 120d;
        private const string BootstrapScene = "Assets/ProjectX/Scenes/Bootstrap.unity";

        static BootstrapAppRunner()
        {
            EditorApplication.update -= Monitor;
            EditorApplication.update += Monitor;
        }

        [MenuItem("Tools/ProjectX App/Run Bootstrap Validation", priority = 91)]
        public static void Run()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode)
                throw new InvalidOperationException("Unity is already entering or running Play Mode.");
            if (!File.Exists(Path.Combine(Directory.GetParent(Application.dataPath).FullName, BootstrapScene)))
                throw new FileNotFoundException("Bootstrap scene is missing. Rebuild it first.", BootstrapScene);

            EditorSceneManager.OpenScene(BootstrapScene);
            SetGameViewResolution(1334, 750);
            SessionState.SetBool(ArmedKey, true);
            SessionState.SetString(StartTimeKey, EditorApplication.timeSinceStartup.ToString("R"));
            SessionState.SetInt(ReconnectPhaseKey, 0);
            SessionState.SetBool(ScreenshotPendingKey, false);
            SessionState.SetInt(SettingsPhaseKey, 0);
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
            bool settingsValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXSettingsValidation") >= 0;
            bool taskValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXTaskValidation") >= 0;
            bool playerHudValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXPlayerHudValidation") >= 0;
            bool heroValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroValidation") >= 0;
            bool heroEquipmentValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipValidation") >= 0
                || Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXHeroEquipMutationValidation") >= 0;
            bool mailValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXMailValidation") >= 0;
            bool shopValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXShopValidation") >= 0;
            bool friendValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXFriendValidation") >= 0;
            bool chatValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXChatValidation") >= 0;
            bool teamValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXTeamValidation") >= 0;
            bool guildValidation = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXGuildValidation") >= 0;
            bool requiresReconnectValidation = reconnectValidation || manualReconnectValidation;
            if (status.StartsWith("COMPLETE:", StringComparison.Ordinal))
            {
                int phase = SessionState.GetInt(ReconnectPhaseKey, 0);
                int settingsPhase = SessionState.GetInt(SettingsPhaseKey, 0);
                bool checkingSettings = settingsValidation && settingsPhase == 1;
                bool checkingTask = taskValidation;
                bool checkingPlayerHud = playerHudValidation;
                bool checkingHero = heroValidation;
                bool checkingHeroEquipment = heroEquipmentValidation;
                bool checkingMail = mailValidation;
                bool checkingShop = shopValidation;
                bool checkingFriend = friendValidation;
                bool checkingChat = chatValidation;
                bool checkingTeam = teamValidation;
                bool checkingGuild = guildValidation;
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
                        : checkingHeroEquipment ? !app.IsHeroEquipmentOpen : checkingHero ? !app.IsHeroOpen
                        : checkingMail ? !app.IsMailOpen : checkingShop ? !app.IsShopOpen
                        : checkingFriend ? !app.IsFriendOpen : checkingChat ? !app.IsChatOpen
                        : checkingTeam ? !app.IsTeamOpen : checkingGuild ? !app.IsGuildOpen : !app.IsBagOpen))
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
                    if (!checkingTask && !checkingSettings && !checkingHero && !checkingHeroEquipment && !checkingMail && !checkingShop && !checkingFriend && !checkingChat && !checkingTeam && !checkingGuild && app.BagMissingIconCount > 0)
                    {
                        WriteResult(false, status + $" ({app.BagMissingIconCount} item icons were not resolved)");
                        Finish(false);
                        return;
                    }
                    string screenshotPath = checkingPlayerHud ? GetMainHudScreenshotPath()
                        : checkingTask ? GetTaskScreenshotPath() : checkingHero || checkingHeroEquipment ? GetHeroScreenshotPath()
                        : checkingMail ? GetMailScreenshotPath() : checkingShop ? GetShopScreenshotPath()
                        : checkingFriend ? GetFriendScreenshotPath() : checkingChat ? GetChatScreenshotPath()
                        : checkingTeam ? GetTeamScreenshotPath() : checkingGuild ? GetGuildScreenshotPath() : GetBagScreenshotPath();
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
                if (!app.HandleBack() || (checkingTask ? app.IsTaskOpen : checkingSettings ? app.IsSettingsOpen
                    : checkingHeroEquipment ? app.IsHeroEquipmentOpen : checkingHero ? app.IsHeroOpen
                    : checkingMail ? app.IsMailOpen : checkingShop ? app.IsShopOpen
                    : checkingFriend ? app.IsFriendOpen : checkingChat ? app.IsChatOpen
                    : checkingTeam ? app.IsTeamOpen : checkingGuild ? app.IsGuildOpen : app.IsBagOpen))
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

            if (!requiresReconnectValidation && status.IndexOf("failed", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                WriteResult(false, status);
                Finish(false);
                return;
            }

            if (!double.TryParse(SessionState.GetString(StartTimeKey, "0"), out double startTime))
                startTime = EditorApplication.timeSinceStartup;
            double timeoutSeconds = requiresReconnectValidation ? 120d : TimeoutSeconds;
            if (EditorApplication.timeSinceStartup - startTime <= timeoutSeconds) return;

            WriteResult(false, status + " (timeout)");
            Debug.LogError("[BootstrapAppRunner] Timed out before the package response was received.");
            Finish(false);
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
            string escapedStatus = (status ?? string.Empty).Replace("\\", "\\\\").Replace("\"", "\\\"");
            string json = "{\n"
                + $"  \"success\": {(success ? "true" : "false")},\n"
                + $"  \"status\": \"{escapedStatus}\",\n"
                + $"  \"utc\": \"{DateTime.UtcNow:O}\"\n"
                + "}\n";
            File.WriteAllText(path, json);
            Debug.Log($"[BootstrapAppRunner] Result written: {path}");
        }

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

        private static string GetManualReconnectRequestPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "manual-reconnect.request");
        }

    }
}
