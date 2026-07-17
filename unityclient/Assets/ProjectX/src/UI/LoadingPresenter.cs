using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class LoadingPresenter : IDisposable
    {
        private sealed class Request
        {
            public string Message;
            public float Deadline;
        }

        private readonly CocosUiView view;
        private readonly Dictionary<string, Request> requests = new Dictionary<string, Request>(StringComparer.Ordinal);
        private readonly Text message;

        public LoadingPresenter(CocosUiView view)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            message = CreateMessage(view.GameObject.transform);
            view.SetVisible(false);
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public int RequestCount => requests.Count;

        public void Show(string key, string text = null, float autoClearSeconds = 15f)
        {
            if (string.IsNullOrWhiteSpace(key)) throw new ArgumentException("Loading key is required.", nameof(key));
            requests[key] = new Request
            {
                Message = text ?? string.Empty,
                Deadline = autoClearSeconds > 0f ? Time.unscaledTime + autoClearSeconds : 0f
            };
            Refresh();
        }

        public void Hide(string key)
        {
            if (!string.IsNullOrWhiteSpace(key)) requests.Remove(key);
            Refresh();
        }

        public void Tick()
        {
            if (requests.Count == 0) return;
            float now = Time.unscaledTime;
            var expired = new List<string>();
            foreach (KeyValuePair<string, Request> pair in requests)
                if (pair.Value.Deadline > 0f && now >= pair.Value.Deadline) expired.Add(pair.Key);
            foreach (string key in expired) requests.Remove(key);
            if (expired.Count > 0) Refresh();
        }

        public void Clear()
        {
            requests.Clear();
            Refresh();
        }

        public void Dispose() => Clear();

        private void Refresh()
        {
            if (view.GameObject == null) return;
            bool visible = requests.Count > 0;
            view.SetVisible(visible);
            if (!visible) return;
            view.GameObject.transform.SetAsLastSibling();
            string text = string.Empty;
            foreach (Request request in requests.Values) text = request.Message;
            message.text = text;
            message.gameObject.SetActive(!string.IsNullOrEmpty(text));
        }

        private static Text CreateMessage(Transform parent)
        {
            GameObject node = new GameObject("RuntimeLoadingMessage", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(parent, false);
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.25f, 0.12f);
            rect.anchorMax = new Vector2(0.75f, 0.22f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text label = node.GetComponent<Text>();
            label.font = UnityEngine.Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 22;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.raycastTarget = false;
            return label;
        }
    }
}
