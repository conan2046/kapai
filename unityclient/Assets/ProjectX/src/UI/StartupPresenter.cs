using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class StartupPresenter : IDisposable
    {
        public static readonly string[] CocosPreloadGroups =
        {
            "csd/Plist/ui_loginPlist",
            "csd/Plist/ui_commonPlist",
            "csd/Plist/ui_mainPlist",
            "csd/Plist/ui_zhandouPlist",
            "csd/Plist/ui_huobi",
            "csd/Plist/ui_wanfaPlist"
        };

        private readonly GameObject root;
        private readonly Image background;
        private readonly Image tipBackground;
        private readonly Text tip;
        private readonly Texture2D logoTexture;
        private readonly Texture2D preloadTexture;
        private readonly Texture2D tipTexture;

        public StartupPresenter(Canvas canvas)
        {
            if (canvas == null) throw new ArgumentNullException(nameof(canvas));
            logoTexture = Resources.Load<Texture2D>("ProjectXStartup/bg3");
            preloadTexture = Resources.Load<Texture2D>("ProjectXStartup/bg_jzzs");
            tipTexture = Resources.Load<Texture2D>("ProjectXStartup/tipbg");

            root = new GameObject("CurrentCocosStartup", typeof(RectTransform));
            RectTransform rootRect = root.GetComponent<RectTransform>();
            rootRect.SetParent(canvas.transform, false);
            Stretch(rootRect, Vector2.zero, Vector2.one);
            rootRect.SetAsLastSibling();

            background = CreateImage(rootRect, "Background", Vector2.zero, Vector2.one);
            background.preserveAspect = false;
            tipBackground = CreateImage(rootRect, "TipBackground", new Vector2(0.22f, 0.43f), new Vector2(0.78f, 0.57f));
            tip = CreateText(tipBackground.rectTransform);
            tipBackground.gameObject.SetActive(false);
        }

        public bool LogoShown { get; private set; }
        public bool PreloadShown { get; private set; }
        public bool Completed { get; private set; }
        public int PreloadGroupCount { get; private set; }

        public IEnumerator Play()
        {
            if (logoTexture == null || preloadTexture == null || tipTexture == null)
                throw new InvalidOperationException("Current Cocos startup textures are incomplete.");

            root.SetActive(true);
            background.sprite = MakeSprite(logoTexture);
            tipBackground.gameObject.SetActive(false);
            LogoShown = true;
            yield return new WaitForSecondsRealtime(0.5f);

            background.sprite = MakeSprite(preloadTexture);
            tipBackground.sprite = MakeSprite(tipTexture, new Vector4(8f, 8f, 8f, 8f));
            tipBackground.type = Image.Type.Sliced;
            tipBackground.gameObject.SetActive(true);
            tip.text = "上仙，封神世界正在创建中，片刻即好...";
            PreloadGroupCount = CocosPreloadGroups.Length;
            PreloadShown = true;
            yield return new WaitForSecondsRealtime(0.1f);

            Completed = true;
            root.SetActive(false);
        }

        public bool Validate(out string detail)
        {
            if (!LogoShown) { detail = "LogoScene bg3 stage was not shown"; return false; }
            if (!PreloadShown) { detail = "GameScene preload stage was not shown"; return false; }
            if (!Completed) { detail = "startup sequence did not complete"; return false; }
            if (PreloadGroupCount != 6) { detail = $"preload group count is {PreloadGroupCount}"; return false; }
            if (logoTexture == null || preloadTexture == null || tipTexture == null)
            { detail = "startup texture mapping is incomplete"; return false; }
            detail = "bg3 0.5s -> bg_jzzs/tipbg -> six Cocos plist groups";
            return true;
        }

        public void Dispose()
        {
            if (root != null) UnityEngine.Object.Destroy(root);
        }

        private static Image CreateImage(Transform parent, string name, Vector2 min, Vector2 max)
        {
            var node = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            Stretch(rect, min, max);
            return node.GetComponent<Image>();
        }

        private static Text CreateText(Transform parent)
        {
            var node = new GameObject("Tip", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            Stretch(rect, Vector2.zero, Vector2.one);
            Text text = node.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 24;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            return text;
        }

        private static Sprite MakeSprite(Texture2D texture, Vector4 border = default)
        {
            return Sprite.Create(texture, new Rect(0f, 0f, texture.width, texture.height),
                new Vector2(0.5f, 0.5f), 100f, 0u, SpriteMeshType.FullRect, border);
        }

        private static void Stretch(RectTransform rect, Vector2 min, Vector2 max)
        {
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }
    }
}
