using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.EditorTools
{
    // First-time authoring only. Never regenerate over a manually adjusted prefab.
    public static class DongFuGardenAssetBuilder
    {
        private const string PrefabPath = "Assets/Prefabs/DongFu/DongFuGardenScene.prefab";
        private const string MapPath = "Assets/Art/Backgrounds/dongfu_garden_map.jpg";

        [MenuItem("Tools/ProjectX 洞府/创建灵园地图预制体（仅首次）")]
        public static void Create()
        {
            if (File.Exists(PrefabPath))
                throw new InvalidOperationException("灵园预制体已存在，请直接编辑，禁止覆盖手调布局。");
            AssetDatabase.Refresh();
            ImportSprite(MapPath, 2048);
            for (int i = 1; i <= 8; i++) ImportSprite(TilePath(i), 256);
            GameObject root = Node("DongFuGardenScene", null, new Vector2(1334, 750));
            try
            {
                RectTransform rootRect = root.GetComponent<RectTransform>();
                rootRect.anchorMin = Vector2.zero;
                rootRect.anchorMax = Vector2.one;
                rootRect.sizeDelta = Vector2.zero;
                GameObject area = Node("MapArea", root.transform, new Vector2(1334, 750));
                GameObject background = Node("Background", area.transform, new Vector2(1334, 750));
                SetImage(background, MapPath);
                GameObject plots = Node("Plots", area.transform, new Vector2(1334, 750));
                for (int i = 1; i <= 8; i++)
                {
                    GameObject plot = Node("Plot_" + i.ToString("00"), plots.transform, new Vector2(160, 160));
                    int column = (i - 1) % 4;
                    int row = (i - 1) / 4;
                    plot.GetComponent<RectTransform>().anchoredPosition = new Vector2(-270 + column * 180, 95 - row * 190);
                    SetImage(plot, TilePath(i));
                }
                if (!PrefabUtility.SaveAsPrefabAsset(root, PrefabPath))
                    throw new InvalidOperationException("Failed to save garden prefab.");
                AssetDatabase.SaveAssets();
            }
            finally { UnityEngine.Object.DestroyImmediate(root); }
            Capture();
            Debug.Log("GARDEN_ASSET_SUCCESS: " + PrefabPath + " | 1 map, 8 independent plots, no runtime layout components.");
        }

        private static string TilePath(int i) => "Assets/Art/UI/ui_dongfu/garden_plot_" + i.ToString("00") + ".png";

        private static void ImportSprite(string path, int maximum)
        {
            AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceSynchronousImport);
            var importer = (TextureImporter)AssetImporter.GetAtPath(path);
            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.spritePixelsPerUnit = 100;
            var settings = new TextureImporterSettings();
            importer.ReadTextureSettings(settings);
            settings.spriteMeshType = SpriteMeshType.FullRect;
            importer.SetTextureSettings(settings);
            importer.mipmapEnabled = false;
            importer.isReadable = false;
            importer.alphaIsTransparency = path.EndsWith(".png", StringComparison.OrdinalIgnoreCase);
            importer.wrapMode = TextureWrapMode.Clamp;
            importer.filterMode = FilterMode.Bilinear;
            importer.npotScale = TextureImporterNPOTScale.None;
            importer.maxTextureSize = maximum;
            importer.textureCompression = TextureImporterCompression.CompressedHQ;
            importer.SaveAndReimport();
            if (!AssetDatabase.LoadAssetAtPath<Sprite>(path))
                throw new InvalidOperationException("Sprite import failed: " + path);
        }

        private static GameObject Node(string name, Transform parent, Vector2 size)
        {
            var obj = new GameObject(name, typeof(RectTransform));
            obj.layer = LayerMask.NameToLayer("UI");
            var rect = obj.GetComponent<RectTransform>();
            if (parent) rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.sizeDelta = size;
            return obj;
        }

        private static void SetImage(GameObject obj, string path)
        {
            Image image = obj.AddComponent<Image>();
            image.sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
            image.type = Image.Type.Simple;
            image.raycastTarget = false;
        }

        private static void Capture()
        {
            var scene = EditorSceneManager.NewPreviewScene();
            RenderTexture previous = RenderTexture.active;
            RenderTexture target = null;
            Camera camera = null;
            Texture2D pixels = null;
            try
            {
                var cameraObject = new GameObject("PreviewCamera", typeof(Camera));
                UnityEngine.SceneManagement.SceneManager.MoveGameObjectToScene(cameraObject, scene);
                camera = cameraObject.GetComponent<Camera>();
                camera.scene = scene;
                camera.orthographic = true;
                camera.orthographicSize = 375;
                camera.transform.position = new Vector3(0, 0, -100);
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = Color.black;
                target = new RenderTexture(1334, 750, 24);
                camera.targetTexture = target;
                var canvasObject = new GameObject("PreviewCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler));
                UnityEngine.SceneManagement.SceneManager.MoveGameObjectToScene(canvasObject, scene);
                Canvas canvas = canvasObject.GetComponent<Canvas>();
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = camera;
                canvas.planeDistance = 10;
                CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                scaler.referenceResolution = new Vector2(1334, 750);
                GameObject instance = UnityEngine.Object.Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath), canvasObject.transform, false);
                foreach (Component component in instance.GetComponentsInChildren<Component>(true))
                    if (!component) throw new InvalidOperationException("Missing component in garden prefab.");
                Image[] images = instance.GetComponentsInChildren<Image>(true);
                if (images.Length != 9) throw new InvalidOperationException("Expected map and eight plots.");
                foreach (Image image in images)
                    if (!image.sprite) throw new InvalidOperationException("Missing garden sprite.");
                Canvas.ForceUpdateCanvases();
                camera.Render();
                RenderTexture.active = target;
                pixels = new Texture2D(1334, 750, TextureFormat.RGB24, false);
                pixels.ReadPixels(new Rect(0, 0, 1334, 750), 0, 0);
                pixels.Apply();
                string directory = Path.GetFullPath(Path.Combine(Application.dataPath, "../Captures/Editor/DongFuReferences"));
                Directory.CreateDirectory(directory);
                File.WriteAllBytes(Path.Combine(directory, "09-garden-prefab-initial.png"), pixels.EncodeToPNG());
            }
            finally
            {
                RenderTexture.active = previous;
                if (camera) camera.targetTexture = null;
                if (pixels) UnityEngine.Object.DestroyImmediate(pixels);
                if (target) { target.Release(); UnityEngine.Object.DestroyImmediate(target); }
                EditorSceneManager.ClosePreviewScene(scene);
            }
        }
    }
}
