using System;
using System.Collections.Generic;
using System.IO;
using ProjectX.Animation;
using ProjectX.UI.Migration;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class ImodAnimationValidation
    {
        private const string SignResource = "ProjectXAnimation/res2/fx/qiandao";

        [MenuItem("Tools/ProjectX UI/Validate Imod Animation")]
        public static void ValidateMenu() => ValidateWelfareAnimationBatch();

        public static void ValidateWelfareAnimationBatch()
        {
            TextAsset json = Resources.Load<TextAsset>(SignResource);
            Texture2D texture = Resources.Load<Texture2D>(SignResource);
            if (json == null || texture == null)
                throw new InvalidOperationException("Prepared qiandao Imod animation resources are missing.");
            ImodAnimationData data = ImodAnimationData.Parse(json.text);
            if (data.modules.Length != 10 || data.frames.Length != 10 || data.actions.Length != 1)
                throw new InvalidOperationException(
                    $"Unexpected qiandao ANI structure: {data.modules.Length}/{data.frames.Length}/{data.actions.Length}");

            var root = new GameObject("ImodAnimationValidation", typeof(RectTransform));
            try
            {
                ImodAnimationPlayer player = root.AddComponent<ImodAnimationPlayer>();
                player.Load(json, texture);
                player.PlayActionRepeat(0);
                int initialFrame = player.CurrentFrame;
                player.Advance(0.11f);
                if (!player.IsPlaying || player.CurrentFrame == initialFrame)
                    throw new InvalidOperationException("Imod animation did not advance to the next frame.");
                ValidateTimeline(root);
                CaptureSignFrame(json, texture);
                Debug.Log(
                    $"ProjectX Imod animation validation completed: {data.source}, "
                    + $"{data.modules.Length} modules, {data.frames.Length} frames, "
                    + $"{data.actions.Length} action, texture {texture.width}x{texture.height}.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(root);
            }
        }

        private static void CaptureSignFrame(TextAsset json, Texture2D texture)
        {
            var cameraObject = new GameObject("ImodCaptureCamera", typeof(Camera));
            var canvasObject = new GameObject(
                "ImodCaptureCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler));
            var animationObject = new GameObject("QiandaoAnimation", typeof(RectTransform));
            RenderTexture target = null;
            Texture2D capture = null;
            try
            {
                Camera camera = cameraObject.GetComponent<Camera>();
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = new Color(0.08f, 0.06f, 0.04f, 1f);
                camera.orthographic = true;
                camera.orthographicSize = 256f;
                cameraObject.transform.position = new Vector3(0f, 0f, -10f);
                target = new RenderTexture(512, 512, 24, RenderTextureFormat.ARGB32);
                camera.targetTexture = target;

                Canvas canvas = canvasObject.GetComponent<Canvas>();
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = camera;
                canvas.planeDistance = 1f;
                CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ConstantPixelSize;

                RectTransform rect = animationObject.GetComponent<RectTransform>();
                rect.SetParent(canvasObject.transform, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.sizeDelta = new Vector2(320f, 320f);
                ImodAnimationPlayer player = animationObject.AddComponent<ImodAnimationPlayer>();
                player.Load(json, texture);
                player.PlayActionRepeat(0);
                player.Advance(0.31f);

                Canvas.ForceUpdateCanvases();
                camera.Render();
                RenderTexture previous = RenderTexture.active;
                RenderTexture.active = target;
                capture = new Texture2D(512, 512, TextureFormat.RGBA32, false);
                capture.ReadPixels(new Rect(0, 0, 512, 512), 0, 0);
                capture.Apply();
                RenderTexture.active = previous;
                string path = Path.GetFullPath(
                    Path.Combine(Application.dataPath, "../../.local/validation/qiandao-unity.png"));
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                File.WriteAllBytes(path, capture.EncodeToPNG());
                Debug.Log("ProjectX Imod visual capture: " + path);
            }
            finally
            {
                if (capture != null) UnityEngine.Object.DestroyImmediate(capture);
                if (target != null) UnityEngine.Object.DestroyImmediate(target);
                UnityEngine.Object.DestroyImmediate(animationObject);
                UnityEngine.Object.DestroyImmediate(canvasObject);
                UnityEngine.Object.DestroyImmediate(cameraObject);
            }
        }

        private static void ValidateTimeline(GameObject root)
        {
            var target = new GameObject("TimelineTarget", typeof(RectTransform));
            target.transform.SetParent(root.transform, false);
            var references = new List<CocosNodeReference>
            {
                new CocosNodeReference { path = "Root/Target", actionTag = 7, target = target }
            };
            root.AddComponent<CocosUiBinding>().Initialize("validation.csb", references);
            var definition = new CocosTimelineDefinition
            {
                duration = 30,
                frameRate = 60,
                timelines = new[]
                {
                    new CocosTimelineTrack
                    {
                        actionTag = 7,
                        property = "Position",
                        frames = new[]
                        {
                            new CocosTimelineFrame { frame = 0, x = 0f, y = 0f },
                            new CocosTimelineFrame { frame = 30, x = 100f, y = 20f },
                        }
                    },
                    new CocosTimelineTrack
                    {
                        actionTag = 7,
                        property = "Alpha",
                        frames = new[]
                        {
                            new CocosTimelineFrame { frame = 0, value = 0f },
                            new CocosTimelineFrame { frame = 30, value = 255f },
                        }
                    },
                }
            };
            CocosTimelinePlayer timeline = root.AddComponent<CocosTimelinePlayer>();
            timeline.Initialize(definition);
            timeline.Play(0, 30);
            timeline.Advance(0.25f);
            RectTransform rect = target.GetComponent<RectTransform>();
            CanvasGroup group = target.GetComponent<CanvasGroup>();
            if (Vector2.Distance(rect.anchoredPosition, new Vector2(50f, 10f)) > 0.01f
                || group == null || Mathf.Abs(group.alpha - 0.5f) > 0.01f)
                throw new InvalidOperationException("Cocos timeline interpolation validation failed.");
        }
    }
}
