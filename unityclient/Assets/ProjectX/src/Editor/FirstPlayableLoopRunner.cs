using System;
using System.IO;
using ProjectX.LuaRuntime;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    [InitializeOnLoad]
    public static class FirstPlayableLoopRunner
    {
        private const string ArmedKey = "ProjectX.FirstPlayableLoop.Armed";
        private const string StartTimeKey = "ProjectX.FirstPlayableLoop.StartTime";
        private const string BatchKey = "ProjectX.FirstPlayableLoop.Batch";
        private const double TimeoutSeconds = 60d;
        private const string ValidationScene = "Assets/ProjectX/Scenes/FirstPlayableLoop.unity";
        private const string LoginBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/LoginBgLayer.prefab";
        private const string LoginPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/loginLayer.prefab";
        private const string MainPrefab = "Assets/ProjectX/res/csd/Prefabs/common/UImainLayer_new.prefab";

        static FirstPlayableLoopRunner()
        {
            EditorApplication.update -= Monitor;
            EditorApplication.update += Monitor;
            EditorApplication.delayCall += RunPendingRequest;
        }

        [MenuItem("Tools/ProjectX Lua/Run First Playable Loop %#l", priority = 100)]
        public static void Run()
        {
            if (EditorApplication.isPlaying || EditorApplication.isPlayingOrWillChangePlaymode)
            {
                Debug.LogWarning("[FirstPlayableLoop] Unity is already entering or running Play Mode.");
                return;
            }

            CreateValidationScene();
            SessionState.SetBool(ArmedKey, true);
            SessionState.SetString(StartTimeKey, EditorApplication.timeSinceStartup.ToString("R"));
            DeletePreviousResult();
            Debug.Log("[FirstPlayableLoop] Runner armed; entering Play Mode.");
            EditorApplication.isPlaying = true;
        }

        public static void RunBatch()
        {
            SessionState.SetBool(BatchKey, true);
            Run();
        }

        private static void CreateValidationScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1334f, 750f);
            scaler.matchWidthOrHeight = 0.5f;
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            Instantiate(LoginBackgroundPrefab, canvasObject.transform, true);
            Instantiate(LoginPrefab, canvasObject.transform, true);
            Instantiate(MainPrefab, canvasObject.transform, false);
            EditorSceneManager.SaveScene(scene, ValidationScene);
        }

        private static void Instantiate(string assetPath, Transform parent, bool active)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
            if (prefab == null)
            {
                throw new FileNotFoundException($"Validation prefab is missing: {assetPath}");
            }

            GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
            instance.SetActive(active);
        }

        private static void Monitor()
        {
            RunPendingRequest();

            if (!SessionState.GetBool(ArmedKey, false) || !EditorApplication.isPlaying)
            {
                return;
            }

            if (FirstPlayableLoopBridge.LastRunFailed)
            {
                WriteResult(false, FirstPlayableLoopBridge.LastRunStatus);
                Finish(false);
                return;
            }

            if (FirstPlayableLoopBridge.LastRunCompleted)
            {
                WriteResult(true, FirstPlayableLoopBridge.LastRunStatus);
                Finish(true);
                return;
            }

            if (!double.TryParse(SessionState.GetString(StartTimeKey, "0"), out double startTime))
            {
                startTime = EditorApplication.timeSinceStartup;
            }

            if (EditorApplication.timeSinceStartup - startTime > TimeoutSeconds)
            {
                WriteResult(false, FirstPlayableLoopBridge.LastRunStatus + " (timeout)");
                Debug.LogError("[FirstPlayableLoop] Timed out before the package response was received.");
                Finish(false);
            }
        }

        private static void RunPendingRequest()
        {
            string requestPath = GetRequestPath();
            if (!File.Exists(requestPath))
            {
                return;
            }

            if (EditorApplication.isPlaying)
            {
                EditorApplication.isPlaying = false;
                return;
            }

            if (EditorApplication.isPlayingOrWillChangePlaymode)
            {
                return;
            }

            Run();
            File.Delete(requestPath);
        }

        private static void Finish(bool success)
        {
            SessionState.SetBool(ArmedKey, false);
            if (SessionState.GetBool(BatchKey, false))
            {
                SessionState.SetBool(BatchKey, false);
                EditorApplication.Exit(success ? 0 : 1);
                return;
            }
            EditorApplication.isPlaying = false;
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
            Debug.Log($"[FirstPlayableLoop] Result written: {path}");
        }

        private static void DeletePreviousResult()
        {
            string path = GetResultPath();
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        private static string GetResultPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "first-playable-loop-result.json");
        }

        private static string GetRequestPath()
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            return Path.Combine(repositoryRoot, "build", "ui-migration", "run-first-playable-loop.request");
        }
    }
}
