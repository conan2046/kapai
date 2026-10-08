using System;
using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class StartupPresenter : IDisposable
    {
        private readonly StartupViewBindings bindings;
        private readonly GameObject root;
        private readonly Image background;
        private readonly Image tipBackground;
        private readonly Text tip;

        public StartupPresenter(UnityUiView view)
        {
            if (view == null) throw new ArgumentNullException(nameof(view));
            root = view.GameObject;
            bindings = root != null ? root.GetComponent<StartupViewBindings>() : null;
            if (bindings == null || bindings.Background == null || bindings.TipBackground == null
                || bindings.Tip == null || bindings.LogoSprite == null || bindings.PreloadSprite == null
                || bindings.TipBackgroundSprite == null)
                throw new InvalidOperationException("Unity StartupLayer has incomplete serialized bindings or sprites.");
            background = bindings.Background;
            tipBackground = bindings.TipBackground;
            tip = bindings.Tip;
        }

        public bool LogoShown { get; private set; }
        public bool PreloadShown { get; private set; }
        public bool Completed { get; private set; }
        public int StartupResourceCount => bindings.LogoSprite != null
            && bindings.PreloadSprite != null && bindings.TipBackgroundSprite != null ? 3 : 0;

        public void ShowServerPreparation(string detail)
        {
            if (bindings.PreloadSprite == null || bindings.TipBackgroundSprite == null)
                throw new InvalidOperationException("Unity startup textures are incomplete.");
            root.SetActive(true);
            background.sprite = bindings.PreloadSprite;
            tipBackground.sprite = bindings.TipBackgroundSprite;
            tipBackground.gameObject.SetActive(true);
            tip.text = string.IsNullOrWhiteSpace(detail) ? "正在准备本机游戏服务…" : detail;
        }

        public void ShowServerFailure(string detail)
        {
            ShowServerPreparation(string.IsNullOrWhiteSpace(detail)
                ? "本机游戏服务启动失败，请重新启动客户端。"
                : detail);
            tip.color = new Color(1f, 0.82f, 0.72f, 1f);
        }

        public IEnumerator Play()
        {
            if (StartupResourceCount != 3)
                throw new InvalidOperationException("Unity startup Prefab sprites are incomplete.");

            root.SetActive(true);
            background.sprite = bindings.LogoSprite;
            tipBackground.gameObject.SetActive(false);
            LogoShown = true;
            yield return new WaitForSecondsRealtime(0.5f);

            background.sprite = bindings.PreloadSprite;
            tipBackground.sprite = bindings.TipBackgroundSprite;
            tipBackground.gameObject.SetActive(true);
            tip.text = "上仙，封神世界正在创建中，片刻即好...";
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
            if (StartupResourceCount != 3)
            { detail = $"startup resource count is {StartupResourceCount}"; return false; }
            detail = "Unity Prefab sprites: bg3 -> bg_jzzs/tipbg";
            return true;
        }

        public void Dispose()
        {
            if (root != null) root.SetActive(false);
        }
    }
}
