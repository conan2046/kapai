using System;
using System.IO;
using ProjectX.UI.Migration;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class CocosTimelineVisualValidation
    {
        private sealed class Sample
        {
            public string prefabPath;
            public string clip;
            public float frame;
            public string output;
        }

        public static void CaptureTimelineSamplesBatch()
        {
            var samples = new[]
            {
                new Sample
                {
                    prefabPath = "Assets/ProjectX/res/csd/Prefabs/csb/FengShenLayer.prefab",
                    clip = "M_1", frame = 142f, output = "timeline-fengshen-csb.png",
                },
                new Sample
                {
                    prefabPath = "Assets/ProjectX/res/csd/Prefabs/TowerLayer3.prefab",
                    clip = "animation2", frame = 110f, output = "timeline-tower.png",
                },
                new Sample
                {
                    prefabPath = "Assets/ProjectX/res/csd/Prefabs/wanfa/XunbaoLayer.prefab",
                    clip = "RedOpen", frame = 232f, output = "timeline-xunbao.png",
                },
            };
            foreach (Sample sample in samples) Capture(sample);
            Debug.Log("ProjectX Timeline visual capture completed: 3 representative prefabs.");
        }

        private static void Capture(Sample sample)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(sample.prefabPath);
            if (prefab == null) throw new FileNotFoundException("Timeline prefab is missing", sample.prefabPath);
            var cameraObject = new GameObject("TimelineCaptureCamera", typeof(Camera));
            var canvasObject = new GameObject(
                "TimelineCaptureCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler));
            GameObject instance = null;
            RenderTexture target = null;
            Texture2D capture = null;
            try
            {
                Camera camera = cameraObject.GetComponent<Camera>();
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = new Color(0.025f, 0.025f, 0.035f, 1f);
                camera.orthographic = true;
                camera.orthographicSize = 375f;
                cameraObject.transform.position = new Vector3(0f, 0f, -10f);
                target = new RenderTexture(1334, 750, 24, RenderTextureFormat.ARGB32);
                camera.targetTexture = target;

                Canvas canvas = canvasObject.GetComponent<Canvas>();
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = camera;
                canvas.planeDistance = 1f;
                CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                scaler.referenceResolution = new Vector2(1334f, 750f);

                instance = PrefabUtility.InstantiatePrefab(prefab) as GameObject;
                RectTransform rect = instance != null ? instance.transform as RectTransform : null;
                if (rect == null) throw new InvalidOperationException("Timeline prefab root is not a RectTransform.");
                rect.SetParent(canvasObject.transform, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = Vector2.zero;
                CocosTimelinePlayer player = instance.GetComponent<CocosTimelinePlayer>();
                if (player == null || !player.TryPlay(sample.clip, false))
                    throw new InvalidOperationException($"Cannot play visual sample clip: {sample.clip}");
                player.Apply(sample.frame);

                Canvas.ForceUpdateCanvases();
                camera.Render();
                RenderTexture previous = RenderTexture.active;
                RenderTexture.active = target;
                capture = new Texture2D(1334, 750, TextureFormat.RGBA32, false);
                capture.ReadPixels(new Rect(0, 0, 1334, 750), 0, 0);
                capture.Apply();
                RenderTexture.active = previous;
                string path = Path.GetFullPath(
                    Path.Combine(Application.dataPath, "../../.local/validation", sample.output));
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                File.WriteAllBytes(path, capture.EncodeToPNG());
                Debug.Log($"ProjectX Timeline visual capture: {sample.prefabPath} -> {path}");
            }
            finally
            {
                if (capture != null) UnityEngine.Object.DestroyImmediate(capture);
                if (target != null) UnityEngine.Object.DestroyImmediate(target);
                if (instance != null) UnityEngine.Object.DestroyImmediate(instance);
                UnityEngine.Object.DestroyImmediate(canvasObject);
                UnityEngine.Object.DestroyImmediate(cameraObject);
            }
        }
    }
}
