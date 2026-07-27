using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class VirtualList<T> : IDisposable
    {
        private readonly RectTransform viewport;
        private readonly RectTransform content;
        private readonly RectTransform template;
        private readonly ScrollRect scrollRect;
        private readonly Action<RectTransform, T, int> bind;
        private readonly float itemHeight;
        private readonly List<RectTransform> rows = new List<RectTransform>();
        private IReadOnlyList<T> items = Array.Empty<T>();
        private int lastFirstIndex = -1;

        public VirtualList(GameObject viewportObject, GameObject templateObject, float itemHeight,
            Action<RectTransform, T, int> bind)
        {
            if (viewportObject == null) throw new ArgumentNullException(nameof(viewportObject));
            if (templateObject == null) throw new ArgumentNullException(nameof(templateObject));
            this.itemHeight = Math.Max(1f, itemHeight);
            this.bind = bind ?? throw new ArgumentNullException(nameof(bind));
            viewport = viewportObject.GetComponent<RectTransform>()
                ?? throw new InvalidOperationException("VirtualList viewport requires RectTransform.");
            template = templateObject.GetComponent<RectTransform>()
                ?? throw new InvalidOperationException("VirtualList template requires RectTransform.");

            scrollRect = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();
            RectMask2D mask = viewportObject.GetComponent<RectMask2D>() ?? viewportObject.AddComponent<RectMask2D>();
            _ = mask;
            var contentObject = new GameObject("VirtualContent", typeof(RectTransform));
            content = contentObject.GetComponent<RectTransform>();
            content.SetParent(viewport, false);
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            scrollRect.viewport = viewport;
            scrollRect.content = content;
            scrollRect.horizontal = false;
            scrollRect.vertical = true;
            scrollRect.movementType = ScrollRect.MovementType.Clamped;
            scrollRect.onValueChanged.AddListener(HandleScroll);
            templateObject.SetActive(false);
        }

        public int Count => items.Count;

        public bool ScrollToBottom()
        {
            if (scrollRect == null || content == null || viewport == null
                || content.rect.height <= viewport.rect.height) return false;
            Canvas.ForceUpdateCanvases();
            scrollRect.verticalNormalizedPosition = 0f;
            content.anchoredPosition = new Vector2(content.anchoredPosition.x,
                Math.Max(0f, content.rect.height - viewport.rect.height));
            RefreshVisible();
            return true;
        }

        public void SetItems(IReadOnlyList<T> values)
        {
            items = values ?? Array.Empty<T>();
            content.sizeDelta = new Vector2(content.sizeDelta.x, items.Count * itemHeight);
            int visibleCount = Math.Max(1, Mathf.CeilToInt(Math.Max(viewport.rect.height, itemHeight * 5f) / itemHeight) + 2);
            int required = Math.Min(items.Count, visibleCount);
            while (rows.Count < required)
            {
                RectTransform row = UnityEngine.Object.Instantiate(template, content, false);
                row.gameObject.name = $"VirtualRow_{rows.Count}";
                row.anchorMin = new Vector2(0f, 1f);
                row.anchorMax = new Vector2(1f, 1f);
                row.pivot = new Vector2(0.5f, 1f);
                row.sizeDelta = new Vector2(0f, itemHeight);
                row.gameObject.SetActive(true);
                rows.Add(row);
            }
            for (int i = required; i < rows.Count; i++) rows[i].gameObject.SetActive(false);
            content.anchoredPosition = new Vector2(content.anchoredPosition.x, 0f);
            lastFirstIndex = -1;
            RefreshVisible();
        }

        public void Dispose()
        {
            if (scrollRect != null) scrollRect.onValueChanged.RemoveListener(HandleScroll);
            if (content != null) UnityEngine.Object.Destroy(content.gameObject);
        }

        private void HandleScroll(Vector2 _) => RefreshVisible();

        private void RefreshVisible()
        {
            int maxFirst = Math.Max(0, items.Count - rows.Count);
            int first = Mathf.Clamp(Mathf.FloorToInt(Math.Max(0f, content.anchoredPosition.y) / itemHeight), 0, maxFirst);
            if (first == lastFirstIndex && rows.Count > 0) return;
            lastFirstIndex = first;
            for (int i = 0; i < rows.Count; i++)
            {
                int index = first + i;
                RectTransform row = rows[i];
                bool active = index < items.Count;
                row.gameObject.SetActive(active);
                if (!active) continue;
                row.anchoredPosition = new Vector2(0f, -index * itemHeight);
                bind(row, items[index], index);
            }
        }
    }
}
