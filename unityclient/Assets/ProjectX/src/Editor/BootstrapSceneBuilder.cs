using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Core;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class BootstrapSceneBuilder
    {
        private const string BootstrapScene = "Assets/ProjectX/Scenes/Bootstrap.unity";
        private const string FirstPlayableScene = "Assets/ProjectX/Scenes/FirstPlayableLoop.unity";
        private const string LoginBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/LoginBgLayer.prefab";
        private const string LoginPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/loginLayer.prefab";
        private const string LoginServerListPrefab = "Assets/ProjectX/res/csd/Prefabs/Login/SeverListLayer.prefab";
        private const string RoleCreatePrefab = "Assets/ProjectX/res/csd/Prefabs/Login/RoleCreateLayer.prefab";
        private const string NoticePrefab = "Assets/ProjectX/res/csd/Prefabs/NoticeLayer.prefab";
        private const string MainPrefab = "Assets/ProjectX/res/csd/Prefabs/common/UImainLayer_new.prefab";
        private const string BackupMainPrefab = "Assets/ProjectX/res/csd/Prefabs/UImainLayer_backup.prefab";
        private const string BagPrefab = "Assets/ProjectX/res/csd/Prefabs/zhujue/beibao.prefab";
        private const string SettingsPrefab = "Assets/ProjectX/res/csd/Prefabs/zhujue/SystemLayer.prefab";
        private const string TaskBackgroundPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/huodong_bg.prefab";
        private const string TaskPrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/RenwuLayer.prefab";
        private const string ErrorPrefab = "Assets/ProjectX/res/csd/Prefabs/MessageBoxLayer.prefab";
        private const string RewardPrefab = "Assets/ProjectX/res/csd/Prefabs/common/tanchuangjiangli.prefab";
        private const string HeroListPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongListLayer.prefab";
        private const string HeroDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/shenjiangyangcheng/yingxiongInfoLayer.prefab";
        private const string HeroEquipmentListPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeibeibao.prefab";
        private const string HeroEquipmentDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/zhuangbeiyangcheng/zhuangbeiInfo.prefab";
        private const string LoadingPrefab = "Assets/ProjectX/res/csd/Prefabs/common/jiemianjiazai.prefab";
        private const string MailPrefab = "Assets/ProjectX/res/csd/Prefabs/MailLayer.prefab";
        private const string ShopPrefab = "Assets/ProjectX/res/csd/Prefabs/shop/shangcheng.prefab";
        private const string FriendPrefab = "Assets/ProjectX/res/csd/Prefabs/common/FriendLayer.prefab";
        private const string ChatPrefab = "Assets/ProjectX/res/csd/Prefabs/MainChatLayer.prefab";
        private const string TeamMembersPrefab = "Assets/ProjectX/res/csd/Prefabs/TeamMembersLayer.prefab";
        private const string TeamInvitePrefab = "Assets/ProjectX/res/csd/Prefabs/TeamInviteListLayer.prefab";
        private const string GuildListPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsApplyLayer.prefab";
        private const string GuildInfoPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsLayer.prefab";
        private const string GuildMemberPrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsMemberLayer.prefab";
        private const string GuildCreatePrefab = "Assets/ProjectX/res/csd/Prefabs/bangpai/GangsfoundLayer.prefab";
        private const string WorldPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/WorldMapNewLayer.prefab";
        private const string WorldMapPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/DadituuiLayer.prefab";
        private const string WorldDetailPrefab = "Assets/ProjectX/res/csd/Prefabs/fuben/guanqiaxiangxiLayer.prefab";
        private const string WelfarePrefab = "Assets/ProjectX/res/csd/Prefabs/WelfareLayer.prefab";
        private const string WelfareSignPrefab = "Assets/ProjectX/res/csd/Prefabs/SignLayer.prefab";
        private const string WelfareOnlinePrefab = "Assets/ProjectX/res/csd/Prefabs/huodong/LoginGiftLayer.prefab";

        private readonly struct PrefabSpec
        {
            public PrefabSpec(string path, bool active, string parentPath = null)
            {
                Path = path;
                Active = active;
                ParentPath = parentPath;
            }

            public string Path { get; }
            public bool Active { get; }
            public string ParentPath { get; }
        }

        private static readonly PrefabSpec[] PrefabSpecs =
        {
            new PrefabSpec(LoginBackgroundPrefab, true),
            new PrefabSpec(LoginPrefab, true),
            new PrefabSpec(LoginServerListPrefab, false),
            new PrefabSpec(RoleCreatePrefab, false),
            new PrefabSpec(NoticePrefab, false),
            new PrefabSpec(MainPrefab, false),
            new PrefabSpec(BackupMainPrefab, false),
            new PrefabSpec(BagPrefab, false),
            new PrefabSpec(SettingsPrefab, false),
            new PrefabSpec(TaskBackgroundPrefab, false),
            new PrefabSpec(TaskPrefab, true, TaskBackgroundPrefab),
            new PrefabSpec(ErrorPrefab, false),
            new PrefabSpec(RewardPrefab, false),
            new PrefabSpec(LoadingPrefab, false),
            new PrefabSpec(MailPrefab, false),
            new PrefabSpec(ShopPrefab, false),
            new PrefabSpec(FriendPrefab, false),
            new PrefabSpec(ChatPrefab, false),
            new PrefabSpec(TeamMembersPrefab, false),
            new PrefabSpec(TeamInvitePrefab, false),
            new PrefabSpec(GuildListPrefab, false),
            new PrefabSpec(GuildInfoPrefab, false),
            new PrefabSpec(GuildMemberPrefab, false),
            new PrefabSpec(GuildCreatePrefab, false),
            new PrefabSpec(WorldPrefab, false),
            new PrefabSpec(WorldMapPrefab, false),
            new PrefabSpec(WorldDetailPrefab, false),
            new PrefabSpec(WelfarePrefab, false),
            new PrefabSpec(WelfareSignPrefab, false),
            new PrefabSpec(WelfareOnlinePrefab, false),
            new PrefabSpec(HeroListPrefab, false),
            new PrefabSpec(HeroDetailPrefab, true, HeroListPrefab),
            new PrefabSpec(HeroEquipmentListPrefab, false),
            new PrefabSpec(HeroEquipmentDetailPrefab, false, HeroEquipmentListPrefab)
        };

        [MenuItem("Tools/ProjectX App/Ensure Bootstrap Scene", priority = 90)]
        public static void Build()
        {
            if (IsBootstrapSceneCurrent())
            {
                EnsureBuildSettings();
                Debug.Log("[ProjectXApp] Bootstrap scene semantic signature unchanged; rebuild skipped.");
                return;
            }

            Rebuild();
        }

        [MenuItem("Tools/ProjectX App/Force Rebuild Bootstrap Scene", priority = 91)]
        public static void ForceRebuild()
        {
            Rebuild();
        }

        private static void Rebuild()
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            GameObject cameraObject = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            cameraObject.tag = "MainCamera";
            Camera camera = cameraObject.GetComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            camera.orthographic = true;
            cameraObject.transform.position = new Vector3(0f, 0f, -10f);

            GameObject lightObject = new GameObject("Directional Light", typeof(Light));
            lightObject.GetComponent<Light>().type = LightType.Directional;
            lightObject.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            GameObject canvasObject = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1334f, 750f);
            scaler.matchWidthOrHeight = 0.5f;
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var instances = new Dictionary<string, GameObject>();
            foreach (PrefabSpec spec in PrefabSpecs)
            {
                Transform parent = spec.ParentPath == null ? canvasObject.transform : instances[spec.ParentPath].transform;
                instances.Add(spec.Path, Instantiate(spec.Path, parent, spec.Active));
            }
            new GameObject("ProjectXApp", typeof(ProjectXApp));

            Directory.CreateDirectory(Path.GetDirectoryName(BootstrapScene));
            EditorSceneManager.SaveScene(scene, BootstrapScene);
            EnsureBuildSettings();
            AssetDatabase.SaveAssets();
            Debug.Log("[ProjectXApp] Bootstrap scene rebuilt and set as build index 0.");
        }

        public static void BuildBatch()
        {
            Build();
        }

        private static GameObject Instantiate(string assetPath, Transform parent, bool active)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
            if (prefab == null) throw new FileNotFoundException($"Bootstrap prefab is missing: {assetPath}");
            GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab, parent);
            instance.SetActive(active);
            return instance;
        }

        private static bool IsBootstrapSceneCurrent()
        {
            if (!File.Exists(BootstrapScene)) return false;
            Scene scene = EditorSceneManager.OpenScene(BootstrapScene, OpenSceneMode.Single);
            GameObject[] roots = scene.GetRootGameObjects();
            if (!roots.Select(root => root.name).SequenceEqual(new[]
                { "Main Camera", "Directional Light", "Canvas", "EventSystem", "ProjectXApp" })) return false;

            GameObject canvas = roots.SingleOrDefault(root => root.name == "Canvas");
            if (canvas == null || roots.Single(root => root.name == "ProjectXApp").GetComponent<ProjectXApp>() == null) return false;

            PrefabSpec[] actual = canvas.GetComponentsInChildren<Transform>(true)
                .Where(transform => transform != canvas.transform && PrefabUtility.IsAnyPrefabInstanceRoot(transform.gameObject))
                .Select(transform => new PrefabSpec(
                    PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(transform.gameObject),
                    transform.gameObject.activeSelf,
                    GetParentPrefabPath(transform.parent)))
                .ToArray();
            if (actual.Length != PrefabSpecs.Length) return false;
            for (int index = 0; index < PrefabSpecs.Length; index++)
            {
                PrefabSpec expected = PrefabSpecs[index];
                PrefabSpec found = actual[index];
                if (expected.Path != found.Path || expected.Active != found.Active || expected.ParentPath != found.ParentPath)
                    return false;
            }
            return true;
        }

        private static string GetParentPrefabPath(Transform parent)
        {
            while (parent != null)
            {
                if (PrefabUtility.IsAnyPrefabInstanceRoot(parent.gameObject))
                    return PrefabUtility.GetPrefabAssetPathOfNearestInstanceRoot(parent.gameObject);
                parent = parent.parent;
            }
            return null;
        }

        private static void EnsureBuildSettings()
        {
            var expected = new[]
            {
                new EditorBuildSettingsScene(BootstrapScene, true),
                new EditorBuildSettingsScene(FirstPlayableScene, false)
            };
            if (EditorBuildSettings.scenes.Length == expected.Length &&
                EditorBuildSettings.scenes.Zip(expected, (actual, item) =>
                    actual.path == item.path && actual.enabled == item.enabled).All(matches => matches)) return;
            EditorBuildSettings.scenes = expected;
        }
    }
}
