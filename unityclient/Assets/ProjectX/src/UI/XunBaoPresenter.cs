using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class XunBaoPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly XunBaoStore store;
        private readonly Text remaining;
        private readonly Text recovery;

        public XunBaoPresenter(CocosUiView view, XunBaoStore store, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            Transform root = view.GameObject.transform;
            Normalize(root);
            SetVisible(root.Find("Panel"), true);
            SetVisible(root.Find("Xunbao"), true);
            SetVisible(root.Find("Xunbao/Red"), true);
            SetVisible(root.Find("Xunbao/Orange"), false);
            SetVisible(root.Find("Xunbao/Purple"), false);
            SetVisible(root.Find("Xunbao/Blue"), false);
            remaining = RequireText(root, "Panel/XunbaoBg/TimesBg/Icon/Num");
            recovery = RequireText(root, "Panel/XunbaoBg/TimesBg/Tips");
            BindClose(root, close);
            DisableActions(root);
            SetText(root, "Panel/DescBg/Bg/Namebg/Name", "法宝搜索");
            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null && recovery != null;
        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            if (!store.HasAuthoritativeResponse)
            {
                remaining.text = "--";
                recovery.text = "正在读取搜索次数";
                return;
            }
            remaining.text = store.Remaining.ToString();
            recovery.text = store.RecoverySeconds > 0 ? $"恢复倒计时：{FormatTime(store.RecoverySeconds)}" : "搜索次数已满";
        }

        private static string FormatTime(uint seconds) => $"{seconds / 3600:00}:{seconds % 3600 / 60:00}:{seconds % 60:00}";

        private static void BindClose(Transform root, Action close)
        {
            Button button = root.Find("Panel/Title/CloseBtn")?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => close?.Invoke());
        }

        private static void DisableActions(Transform root)
        {
            string[] paths = { "Panel/XunbaoBg/TimesBg/AddBtn", "Panel/XunbaoBg/Btn_1", "Xunbao/Btn_1", "Xunbao/Btn_2", "Xunbao/Btn_3", "Xunbao/Panel/Button_L", "Xunbao/Panel/Button_R" };
            foreach (string path in paths) Disable(root.Find(path)?.GetComponent<Button>());
            foreach (string quality in new[] { "Red", "Orange", "Purple", "Blue" })
            for (int index = 1; index <= 6; index++) Disable(root.Find($"Xunbao/{quality}/Image/Add{index}")?.GetComponent<Button>());
        }

        private static void Disable(Button button)
        {
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = false;
        }

        private static Text RequireText(Transform root, string path) => root.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"XunBao imported text was not found: {path}");
        private static void SetText(Transform root, string path, string value) { Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value; }
        private static void SetVisible(Transform target, bool visible) { if (target != null) target.gameObject.SetActive(visible); }
        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero; rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity;
        }
    }
}
