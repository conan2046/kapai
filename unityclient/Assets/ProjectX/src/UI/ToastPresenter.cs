using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ToastPresenter : IDisposable
    {
        private readonly Queue<string> pending = new Queue<string>();
        private readonly GameObject root;
        private readonly CanvasGroup group;
        private readonly Text label;
        private float remaining;
        private float duration;

        public ToastPresenter(Transform parent)
        {
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            root = new GameObject("RuntimeToast", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(CanvasGroup));
            root.transform.SetParent(parent, false);
            RectTransform rect = root.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.25f, 0.68f);
            rect.anchorMax = new Vector2(0.75f, 0.78f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image background = root.GetComponent<Image>();
            background.color = new Color(0f, 0f, 0f, 0.78f);
            background.raycastTarget = false;
            group = root.GetComponent<CanvasGroup>();

            GameObject textNode = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            textNode.transform.SetParent(root.transform, false);
            RectTransform textRect = textNode.GetComponent<RectTransform>();
            textRect.anchorMin = Vector2.zero;
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = new Vector2(20f, 6f);
            textRect.offsetMax = new Vector2(-20f, -6f);
            label = textNode.GetComponent<Text>();
            label.font = UnityEngine.Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 24;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.raycastTarget = false;
            root.SetActive(false);
        }

        public bool IsVisible => root != null && root.activeSelf;
        public int PendingCount => pending.Count;

        public void Show(string text, float visibleSeconds = 2f)
        {
            if (string.IsNullOrWhiteSpace(text)) return;
            pending.Enqueue(text);
            if (!IsVisible) BeginNext(Mathf.Max(0.25f, visibleSeconds));
        }

        public void Tick()
        {
            if (!IsVisible) return;
            remaining -= Time.unscaledDeltaTime;
            if (remaining <= 0f) { BeginNext(duration); return; }
            float fadeWindow = Mathf.Min(0.25f, duration * 0.25f);
            group.alpha = fadeWindow <= 0f ? 1f : Mathf.Clamp01(remaining / fadeWindow);
        }

        public void Clear()
        {
            pending.Clear();
            remaining = 0f;
            if (root != null) root.SetActive(false);
        }

        public void Dispose()
        {
            Clear();
            if (root != null) UnityEngine.Object.Destroy(root);
        }

        private void BeginNext(float visibleSeconds)
        {
            if (pending.Count == 0)
            {
                root.SetActive(false);
                return;
            }
            duration = Mathf.Max(0.25f, visibleSeconds);
            remaining = duration;
            label.text = pending.Dequeue();
            group.alpha = 1f;
            root.SetActive(true);
            root.transform.SetAsLastSibling();
        }
    }
}
