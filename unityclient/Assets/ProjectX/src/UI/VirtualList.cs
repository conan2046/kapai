using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class VirtualList<T> : IDisposable
    {
        private readonly RectTransform viewport;
        private readonly RectTransform content;
        private readonly RectTransform template;
        private readonly ScrollRect scrollRect;
        private readonly bool ownsScrollRect;
        private readonly RectMask2D ownedMask;
        private readonly Graphic ownedDragSurface;
        private readonly Graphic existingDragSurface;
        private readonly bool originalDragSurfaceRaycastTarget;
        private readonly RectTransform originalScrollViewport;
        private readonly RectTransform originalScrollContent;
        private readonly bool originalHorizontal;
        private readonly bool originalVertical;
        private readonly ScrollRect.MovementType originalMovementType;
        private readonly bool originalInertia;
        private readonly float originalScrollSensitivity;
        private readonly bool templateWasActive;
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

            scrollRect = viewportObject.GetComponent<ScrollRect>();
            ownsScrollRect = scrollRect == null;
            if (ownsScrollRect) scrollRect = viewportObject.AddComponent<ScrollRect>();
            originalScrollViewport = scrollRect.viewport;
            originalScrollContent = scrollRect.content;
            originalHorizontal = scrollRect.horizontal;
            originalVertical = scrollRect.vertical;
            originalMovementType = scrollRect.movementType;
            originalInertia = scrollRect.inertia;
            originalScrollSensitivity = scrollRect.scrollSensitivity;
            if (viewportObject.GetComponent<RectMask2D>() == null)
                ownedMask = viewportObject.AddComponent<RectMask2D>();
            Graphic dragSurface = viewportObject.GetComponent<Graphic>();
            if (dragSurface == null)
            {
                Image image = viewportObject.AddComponent<Image>();
                image.color = new Color(1f, 1f, 1f, 0.001f);
                dragSurface = image;
                ownedDragSurface = image;
            }
            else
            {
                existingDragSurface = dragSurface;
                originalDragSurfaceRaycastTarget = dragSurface.raycastTarget;
            }
            dragSurface.raycastTarget = true;
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
            scrollRect.inertia = true;
            scrollRect.scrollSensitivity = 30f;
            scrollRect.onValueChanged.AddListener(HandleScroll);
            templateWasActive = templateObject.activeSelf;
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
            RefreshVisible(true);
            return true;
        }

        public void ScrollToTop()
        {
            if (scrollRect == null || content == null) return;
            scrollRect.StopMovement();
            scrollRect.verticalNormalizedPosition = 1f;
            content.anchoredPosition = new Vector2(content.anchoredPosition.x, 0f);
            RefreshVisible(true);
        }

        public void RefreshVisibleItems() => RefreshVisible(true);

        public void SetItems(IReadOnlyList<T> values) => SetItems(values, false);

        public void SetItemsPreservingScroll(IReadOnlyList<T> values) => SetItems(values, true);

        private void SetItems(IReadOnlyList<T> values, bool preserveScrollPosition)
        {
            float previousOffset = content.anchoredPosition.y;
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
                row.gameObject.AddComponent<VirtualListScrollDragRelay>().Initialize(scrollRect);
                row.gameObject.SetActive(true);
                rows.Add(row);
            }
            for (int i = required; i < rows.Count; i++) rows[i].gameObject.SetActive(false);
            float maximumOffset = Math.Max(0f, content.rect.height - viewport.rect.height);
            float targetOffset = preserveScrollPosition
                ? Mathf.Clamp(previousOffset, 0f, maximumOffset)
                : 0f;
            content.anchoredPosition = new Vector2(content.anchoredPosition.x, targetOffset);
            lastFirstIndex = -1;
            RefreshVisible(true);
        }

        public void Dispose()
        {
            if (scrollRect != null) scrollRect.onValueChanged.RemoveListener(HandleScroll);
            if (content != null) UnityEngine.Object.Destroy(content.gameObject);
            if (template != null) template.gameObject.SetActive(templateWasActive);
            if (existingDragSurface != null) existingDragSurface.raycastTarget = originalDragSurfaceRaycastTarget;
            if (ownedDragSurface != null) UnityEngine.Object.Destroy(ownedDragSurface);
            if (ownedMask != null) UnityEngine.Object.Destroy(ownedMask);
            if (ownsScrollRect)
            {
                if (scrollRect != null) UnityEngine.Object.Destroy(scrollRect);
            }
            else if (scrollRect != null)
            {
                scrollRect.viewport = originalScrollViewport;
                scrollRect.content = originalScrollContent;
                scrollRect.horizontal = originalHorizontal;
                scrollRect.vertical = originalVertical;
                scrollRect.movementType = originalMovementType;
                scrollRect.inertia = originalInertia;
                scrollRect.scrollSensitivity = originalScrollSensitivity;
            }
        }

        private void HandleScroll(Vector2 _) => RefreshVisible();

        private void RefreshVisible(bool force = false)
        {
            int maxFirst = Math.Max(0, items.Count - rows.Count);
            int first = Mathf.Clamp(Mathf.FloorToInt(Math.Max(0f, content.anchoredPosition.y) / itemHeight), 0, maxFirst);
            if (!force && first == lastFirstIndex && rows.Count > 0) return;
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

    public sealed class VirtualListScrollDragRelay : MonoBehaviour,
        IInitializePotentialDragHandler, IBeginDragHandler, IDragHandler, IEndDragHandler, IScrollHandler
    {
        private ScrollRect target;

        public void Initialize(ScrollRect value) => target = value;

        public void OnInitializePotentialDrag(PointerEventData eventData)
            => target?.OnInitializePotentialDrag(eventData);

        public void OnBeginDrag(PointerEventData eventData) => target?.OnBeginDrag(eventData);

        public void OnDrag(PointerEventData eventData) => target?.OnDrag(eventData);

        public void OnEndDrag(PointerEventData eventData) => target?.OnEndDrag(eventData);

        public void OnScroll(PointerEventData eventData) => target?.OnScroll(eventData);
    }
}
