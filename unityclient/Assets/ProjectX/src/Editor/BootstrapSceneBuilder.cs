using System.IO;
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

        [MenuItem("Tools/ProjectX App/Rebuild Bootstrap Scene", priority = 90)]
        public static void Build()
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

            Instantiate(LoginBackgroundPrefab, canvasObject.transform, true);
            Instantiate(LoginPrefab, canvasObject.transform, true);
            Instantiate(MainPrefab, canvasObject.transform, false);
            Instantiate(BackupMainPrefab, canvasObject.transform, false);
            Instantiate(BagPrefab, canvasObject.transform, false);
            Instantiate(SettingsPrefab, canvasObject.transform, false);
            GameObject taskBackground = Instantiate(TaskBackgroundPrefab, canvasObject.transform, false);
            Instantiate(TaskPrefab, taskBackground.transform, true);
            Instantiate(ErrorPrefab, canvasObject.transform, false);
            Instantiate(RewardPrefab, canvasObject.transform, false);
            Instantiate(LoadingPrefab, canvasObject.transform, false);
            GameObject heroList = Instantiate(HeroListPrefab, canvasObject.transform, false);
            Instantiate(HeroDetailPrefab, heroList.transform, true);
            GameObject heroEquipmentList = Instantiate(HeroEquipmentListPrefab, canvasObject.transform, false);
            Instantiate(HeroEquipmentDetailPrefab, heroEquipmentList.transform, false);
            new GameObject("ProjectXApp", typeof(ProjectXApp));

            Directory.CreateDirectory(Path.GetDirectoryName(BootstrapScene));
            EditorSceneManager.SaveScene(scene, BootstrapScene);
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(BootstrapScene, true),
                new EditorBuildSettingsScene(FirstPlayableScene, false)
            };
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
    }
}
