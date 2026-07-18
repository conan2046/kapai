using System;
using System.Collections.Generic;
using System.IO;
using ProjectX.Animation;
using ProjectX.UI.Migration;
using Newtonsoft.Json;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class ImodAnimationValidation
    {
        private const string SignResource = "ProjectXAnimation/res2/fx/qiandao";
        private static readonly string[] StaticUiResources =
        {
            "effect/biaobai/butflay", "effect/hehua/hehua_yu", "item/equipLight", "jiazaiquan",
            "res2/animation/battle/quality2", "res2/animation/battle/quality7",
            "res2/fx/choukaluzi", "res2/fx/choukashenjiang", "res2/fx/jieshourenwu",
            "res2/fx/loading", "res2/fx/lvdian", "res2/fx/qiandao", "res2/fx/renwulan",
            "res2/fx/shengji_yuan", "res2/fx/shengxing", "res2/fx/shenqizhanshi",
            "res2/fx/wancheng", "res2/fx/yueka", "res2/fx/zhandoukaishi",
            "res2/skill_name/battle_hero_anger_boom",
            "res2/skill_name/battle_hero_anger_burning",
            "res2/skill_name/battle_pet_anger_boom",
            "res2/skill_name/battle_pet_anger_burning", "UI/role",
        };

        [MenuItem("Tools/ProjectX UI/Validate Imod Animation")]
        public static void ValidateMenu() => ValidateAllImodAnimationsBatch();

        public static void ValidateAllImodAnimationsBatch()
        {
            TextAsset catalogJson = Resources.Load<TextAsset>("ProjectXAnimation/catalog");
            if (catalogJson == null) throw new InvalidOperationException("Imod catalog is missing.");
            Catalog catalog = JsonConvert.DeserializeObject<Catalog>(catalogJson.text);
            if (catalog == null || catalog.schemaVersion != 1 || catalog.entries == null)
                throw new InvalidOperationException("Imod catalog is invalid.");

            int animations = 0;
            int actions = 0;
            int sequenceFrames = 0;
            var unavailable = new List<string>();
            foreach (CatalogEntry entry in catalog.entries)
            {
                if (!entry.playable)
                {
                    unavailable.Add(entry.legacyPath);
                    continue;
                }
                TextAsset json = Resources.Load<TextAsset>(entry.animationResourceKey);
                Texture2D texture = Resources.Load<Texture2D>(entry.textureResourceKey);
                if (json == null || texture == null)
                    throw new InvalidOperationException($"Imod resource is missing: {entry.legacyPath}");
                ImodAnimationData data = ImodAnimationData.Parse(json.text);
                var root = new GameObject("ImodValidation_" + animations, typeof(RectTransform));
                try
                {
                    ImodAnimationPlayer player = root.AddComponent<ImodAnimationPlayer>();
                    player.Load(json, texture);
                    foreach (ImodAction action in data.actions)
                    {
                        if (action.frames == null || action.frames.Length == 0)
                            throw new InvalidOperationException(
                                $"Imod action has no frames: {entry.legacyPath}/{action.id}");
                        bool completed = false;
                        player.Completed += _ => completed = true;
                        player.PlayAction(action.id);
                        float duration = 0f;
                        foreach (ImodActionFrame frame in action.frames)
                            duration += Mathf.Max(1, frame.durationTicks) / (float)data.frameRate;
                        player.Advance(duration + 0.001f);
                        if (player.IsPlaying || !completed)
                            throw new InvalidOperationException(
                                $"Imod action did not complete: {entry.legacyPath}/{action.id}");
                        player.PlayActionRepeat(action.id);
                        player.Advance(duration + 0.001f);
                        if (!player.IsPlaying)
                            throw new InvalidOperationException(
                                $"Imod action did not loop: {entry.legacyPath}/{action.id}");
                        player.Stop();
                        actions++;
                        sequenceFrames += action.frames.Length;
                    }
                    animations++;
                }
                finally
                {
                    UnityEngine.Object.DestroyImmediate(root);
                    Resources.UnloadAsset(json);
                    Resources.UnloadAsset(texture);
                }
            }

            if (unavailable.Count != 1
                || !string.Equals(unavailable[0], "Skill/skill_5_h_l", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException(
                    "Unexpected unavailable Imod resources: " + string.Join(", ", unavailable));
            if (!ImodAnimationResources.TryLoad("res2/fx/jieshourenwu", out ImodAnimationAssets alias)
                || !alias.IsValid)
                throw new InvalidOperationException("Legacy jieshourenwu alias did not resolve.");

            ValidateSpeedScaleCompatibility();
            ValidateLegacyCompatibilitySurface();
            ValidateWelfareAnimationBatch();
            CaptureStaticUiContactSheet();
            Debug.Log(
                $"ProjectX Imod full validation completed: {animations} playable animations, "
                + $"{actions} actions, {sequenceFrames} action frames, "
                + $"{unavailable.Count} unavailable source asset ({unavailable[0]})." );
        }

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

        private static void CaptureStaticUiContactSheet()
        {
            const int columns = 6;
            const int rows = 4;
            const int cellWidth = 256;
            const int cellHeight = 256;
            const int width = columns * cellWidth;
            const int height = rows * cellHeight;
            var cameraObject = new GameObject("ImodSheetCamera", typeof(Camera));
            var canvasObject = new GameObject("ImodSheetCanvas", typeof(RectTransform), typeof(Canvas));
            RenderTexture target = null;
            Texture2D capture = null;
            try
            {
                Camera camera = cameraObject.GetComponent<Camera>();
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = new Color(0.035f, 0.04f, 0.055f, 1f);
                camera.orthographic = true;
                camera.orthographicSize = height * 0.5f;
                cameraObject.transform.position = new Vector3(0f, 0f, -10f);
                target = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
                camera.targetTexture = target;

                Canvas canvas = canvasObject.GetComponent<Canvas>();
                canvas.renderMode = RenderMode.WorldSpace;
                canvas.worldCamera = camera;
                RectTransform canvasRect = canvasObject.GetComponent<RectTransform>();
                canvasRect.sizeDelta = new Vector2(width, height);

                Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                for (int index = 0; index < StaticUiResources.Length; index++)
                {
                    int column = index % columns;
                    int row = index / columns;
                    float x = -width * 0.5f + cellWidth * (column + 0.5f);
                    float y = height * 0.5f - cellHeight * (row + 0.5f);
                    var panel = new GameObject(
                        "Cell_" + index, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                    RectTransform panelRect = panel.GetComponent<RectTransform>();
                    panelRect.SetParent(canvasRect, false);
                    panelRect.anchoredPosition = new Vector2(x, y);
                    panelRect.sizeDelta = new Vector2(cellWidth - 6, cellHeight - 6);
                    panel.GetComponent<Image>().color = new Color(0.10f, 0.11f, 0.15f, 1f);

                    var animationObject = new GameObject("Animation", typeof(RectTransform));
                    RectTransform animationRect = animationObject.GetComponent<RectTransform>();
                    animationRect.SetParent(panelRect, false);
                    animationRect.anchoredPosition = new Vector2(0f, 12f);
                    ImodAnimationPlayer player = animationObject.AddComponent<ImodAnimationPlayer>();
                    bool loaded = player.LoadLegacy(StaticUiResources[index]);
                    if (loaded)
                    {
                        player.PlayActionRepeat(0);
                        player.Advance(0.21f);
                        RectTransform part = animationRect.Find("__ImodPart") as RectTransform;
                        if (part != null)
                        {
                            float extentX = Mathf.Abs(part.anchoredPosition.x) + part.sizeDelta.x * 0.5f;
                            float extentY = Mathf.Abs(part.anchoredPosition.y) + part.sizeDelta.y * 0.5f;
                            float scale = Mathf.Min(210f / Mathf.Max(1f, extentX * 2f),
                                190f / Mathf.Max(1f, extentY * 2f), 1f);
                            animationRect.localScale = Vector3.one * scale;
                        }
                    }
                    else panel.GetComponent<Image>().color = new Color(0.30f, 0.07f, 0.08f, 1f);

                    var labelObject = new GameObject(
                        "Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                    RectTransform labelRect = labelObject.GetComponent<RectTransform>();
                    labelRect.SetParent(panelRect, false);
                    labelRect.anchoredPosition = new Vector2(0f, -111f);
                    labelRect.sizeDelta = new Vector2(cellWidth - 12, 28f);
                    Text label = labelObject.GetComponent<Text>();
                    label.font = font;
                    label.fontSize = 13;
                    label.alignment = TextAnchor.MiddleCenter;
                    label.color = Color.white;
                    label.text = (loaded ? string.Empty : "[MISSING] ") + StaticUiResources[index];
                }

                Canvas.ForceUpdateCanvases();
                camera.Render();
                RenderTexture previous = RenderTexture.active;
                RenderTexture.active = target;
                capture = new Texture2D(width, height, TextureFormat.RGBA32, false);
                capture.ReadPixels(new Rect(0, 0, width, height), 0, 0);
                capture.Apply();
                RenderTexture.active = previous;
                string path = Path.GetFullPath(Path.Combine(
                    Application.dataPath, "../../.local/validation/imod-static-ui-contact-sheet.png"));
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                File.WriteAllBytes(path, capture.EncodeToPNG());
                Debug.Log("ProjectX Imod static UI contact sheet: " + path);
            }
            finally
            {
                if (capture != null) UnityEngine.Object.DestroyImmediate(capture);
                if (target != null) UnityEngine.Object.DestroyImmediate(target);
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

        private static void ValidateSpeedScaleCompatibility()
        {
            if (!ImodAnimationResources.TryLoad("res2/fx/qiandao", out ImodAnimationAssets assets))
                throw new InvalidOperationException("Qiandao assets are unavailable for speed validation.");
            var fastRoot = new GameObject("ImodFast", typeof(RectTransform));
            var slowRoot = new GameObject("ImodSlow", typeof(RectTransform));
            try
            {
                ImodAnimationPlayer fast = fastRoot.AddComponent<ImodAnimationPlayer>();
                fast.Load(assets.Animation, assets.Texture);
                fast.SetSpeedScale(0.5f);
                fast.PlayActionRepeat(0);
                int fastInitial = fast.CurrentFrame;
                fast.Advance(0.09f);
                if (fast.CurrentFrame == fastInitial)
                    throw new InvalidOperationException("Legacy speed scale 0.5 did not accelerate playback.");

                ImodAnimationPlayer slow = slowRoot.AddComponent<ImodAnimationPlayer>();
                slow.Load(assets.Animation, assets.Texture);
                slow.SetSpeedScale(2f);
                slow.PlayActionRepeat(0);
                int slowInitial = slow.CurrentFrame;
                slow.Advance(0.09f);
                if (slow.CurrentFrame != slowInitial)
                    throw new InvalidOperationException("Legacy speed scale 2 unexpectedly accelerated playback.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(fastRoot);
                UnityEngine.Object.DestroyImmediate(slowRoot);
            }
        }

        private static void ValidateLegacyCompatibilitySurface()
        {
            var root = new GameObject("ImodLegacyCompatibility", typeof(RectTransform));
            try
            {
                ImodAnimationPlayer player = root.AddComponent<ImodAnimationPlayer>();
                if (!player.LoadLegacy(
                    "res2/fx/jieshourenwu.png", "res2/fx/jishourenwu.ani"))
                    throw new InvalidOperationException("Explicit legacy PNG/ANI loading failed.");
                if (!player.AddLegacyLayer("item/equipLight.png", "item/equipLight.ani", 2))
                    throw new InvalidOperationException("Legacy additional animation layer failed.");
                player.SetFlippedX(true);
                player.SetFlippedY(true);
                player.SetColor(new Color(0.7f, 0.8f, 0.9f, 1f));
                player.SetOpacity(192);
                player.PlayNewAction(0, true);
                ImodAnimationPlayer[] layers = root.GetComponentsInChildren<ImodAnimationPlayer>(true);
                if (layers.Length != 2 || !layers[0].IsPlaying || !layers[1].IsPlaying)
                    throw new InvalidOperationException("Legacy layered playback did not start.");
                foreach (ImodAnimationPlayer layer in layers) layer.Advance(0.2f);
                player.StopCurrentAnimation();
                if (layers[0].IsPlaying || layers[1].IsPlaying)
                    throw new InvalidOperationException("Legacy layered playback did not stop.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(root);
            }
        }

        [Serializable]
        private sealed class Catalog
        {
            public int schemaVersion;
            public CatalogEntry[] entries;
        }

        [Serializable]
        private sealed class CatalogEntry
        {
            public string legacyPath;
            public string animationResourceKey;
            public string textureResourceKey;
            public bool playable;
        }
    }
}
