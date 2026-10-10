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
        private readonly bool ownsContent;
        private readonly Vector2 contentOrigin;
        private readonly Vector2 rowOrigin;
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
        private readonly Dictionary<RectTransform, bool> authoredRows = new Dictionary<RectTransform, bool>();
        private readonly List<VirtualListScrollDragRelay> ownedRowRelays = new List<VirtualListScrollDragRelay>();
        private IReadOnlyList<T> items = Array.Empty<T>();
        private int lastFirstIndex = -1;

        public VirtualList(GameObject viewportObject, GameObject templateObject, float itemHeight,
            Action<RectTransform, T, int> bind, RectTransform authoredContent = null)
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
            ownsContent = authoredContent == null;
            if (ownsContent)
            {
                var contentObject = new GameObject("VirtualContent", typeof(RectTransform));
                content = contentObject.GetComponent<RectTransform>();
                content.SetParent(viewport, false);
                content.anchorMin = new Vector2(0f, 1f);
                content.anchorMax = new Vector2(1f, 1f);
                content.pivot = new Vector2(0.5f, 1f);
                content.anchoredPosition = Vector2.zero;
                content.sizeDelta = Vector2.zero;
            }
            else
            {
                content = authoredContent;
                if (content.parent != viewport || template.parent != content)
                    throw new InvalidOperationException("Authored list requires its template inside the viewport's content.");
                if (content.GetComponent<VerticalLayoutGroup>() == null
                    || content.GetComponent<ContentSizeFitter>() == null)
                    throw new InvalidOperationException("Authored list requires prefab layout and content sizing components.");
            }
            contentOrigin = content.anchoredPosition;
            rowOrigin = ownsContent ? Vector2.zero : template.anchoredPosition;
            scrollRect.viewport = viewport;
            scrollRect.content = content;
            if (ownsContent)
            {
                scrollRect.horizontal = false;
                scrollRect.vertical = true;
                scrollRect.movementType = ScrollRect.MovementType.Clamped;
                scrollRect.inertia = true;
                scrollRect.scrollSensitivity = 30f;
            }
            scrollRect.onValueChanged.AddListener(HandleScroll);
            templateWasActive = templateObject.activeSelf;
            if (ownsContent) templateObject.SetActive(false);
            else
            {
                foreach (Transform child in content)
                {
                    RectTransform row = child as RectTransform;
                    if (row == null || (row.name != template.name
                        && !row.name.StartsWith(template.name + " (", StringComparison.Ordinal))) continue;
                    authoredRows.Add(row, row.gameObject.activeSelf);
                    rows.Add(row);
                    VirtualListScrollDragRelay relay = row.GetComponent<VirtualListScrollDragRelay>();
                    if (relay == null)
                    {
                        relay = row.gameObject.AddComponent<VirtualListScrollDragRelay>();
                        ownedRowRelays.Add(relay);
                    }
                    relay.Initialize(scrollRect);
                }
            }
        }

        public int Count => items.Count;

        public bool ScrollToBottom()
        {
            Canvas.ForceUpdateCanvases();
            if (scrollRect == null || content == null || viewport == null
                || content.rect.height <= viewport.rect.height) return false;
            scrollRect.verticalNormalizedPosition = 0f;
            if (ownsContent)
                content.anchoredPosition = new Vector2(content.anchoredPosition.x,
                    contentOrigin.y + Math.Max(0f, content.rect.height - viewport.rect.height));
            RefreshVisible(true);
            return true;
        }

        public void ScrollToTop()
        {
            if (scrollRect == null || content == null) return;
            scrollRect.StopMovement();
            scrollRect.verticalNormalizedPosition = 1f;
            if (ownsContent)
                content.anchoredPosition = new Vector2(content.anchoredPosition.x, contentOrigin.y);
            RefreshVisible(true);
        }

        public void RefreshVisibleItems() => RefreshVisible(true);

        public void SetItems(IReadOnlyList<T> values) => SetItems(values, false);

        public void SetItemsPreservingScroll(IReadOnlyList<T> values) => SetItems(values, true);

        private void SetItems(IReadOnlyList<T> values, bool preserveScrollPosition)
        {
            if (!ownsContent)
            {
                SetAuthoredItems(values, preserveScrollPosition);
                return;
            }
            float previousOffset = content.anchoredPosition.y - contentOrigin.y;
            items = values ?? Array.Empty<T>();
            content.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical,
                items.Count * itemHeight + Math.Max(0f, -rowOrigin.y));
            int visibleCount = Math.Max(1, Mathf.CeilToInt(Math.Max(viewport.rect.height, itemHeight * 5f) / itemHeight) + 2);
            int required = Math.Min(items.Count, visibleCount);
            while (rows.Count < required)
            {
                RectTransform row = UnityEngine.Object.Instantiate(template, content, false);
                row.gameObject.name = $"VirtualRow_{rows.Count}";
                if (ownsContent)
                {
                    row.anchorMin = new Vector2(0f, 1f);
                    row.anchorMax = new Vector2(1f, 1f);
                    row.pivot = new Vector2(0.5f, 1f);
                    row.sizeDelta = new Vector2(0f, itemHeight);
                }
                row.gameObject.AddComponent<VirtualListScrollDragRelay>().Initialize(scrollRect);
                row.gameObject.SetActive(true);
                rows.Add(row);
            }
            for (int i = required; i < rows.Count; i++) rows[i].gameObject.SetActive(false);
            float maximumOffset = Math.Max(0f, content.rect.height - viewport.rect.height);
            float targetOffset = preserveScrollPosition
                ? Mathf.Clamp(previousOffset, 0f, maximumOffset)
                : 0f;
            content.anchoredPosition = new Vector2(content.anchoredPosition.x, contentOrigin.y + targetOffset);
            lastFirstIndex = -1;
            RefreshVisible(true);
        }

        private void SetAuthoredItems(IReadOnlyList<T> values, bool preserveScrollPosition)
        {
            float previousPosition = scrollRect.verticalNormalizedPosition;
            items = values ?? Array.Empty<T>();
            while (rows.Count < items.Count)
            {
                RectTransform row = UnityEngine.Object.Instantiate(template, content, false);
                row.gameObject.name = $"VirtualRow_{rows.Count}";
                VirtualListScrollDragRelay relay = row.GetComponent<VirtualListScrollDragRelay>()
                    ?? row.gameObject.AddComponent<VirtualListScrollDragRelay>();
                relay.Initialize(scrollRect);
                rows.Add(row);
            }
            RefreshVisible(true);
            LayoutRebuilder.ForceRebuildLayoutImmediate(content);
            scrollRect.StopMovement();
            scrollRect.verticalNormalizedPosition = preserveScrollPosition ? previousPosition : 1f;
        }

        public void Dispose()
        {
            if (scrollRect != null) scrollRect.onValueChanged.RemoveListener(HandleScroll);
            if (content != null)
            {
                if (ownsContent) DestroyOwnedObject(content.gameObject);
                else
                {
                    foreach (RectTransform row in rows)
                    {
                        if (row == null) continue;
                        if (authoredRows.TryGetValue(row, out bool wasActive)) row.gameObject.SetActive(wasActive);
                        else DestroyOwnedObject(row.gameObject);
                    }
                    foreach (VirtualListScrollDragRelay relay in ownedRowRelays)
                        if (relay != null) DestroyOwnedObject(relay);
                }
            }
            if (template != null) template.gameObject.SetActive(templateWasActive);
            if (!ownsContent && content != null) LayoutRebuilder.MarkLayoutForRebuild(content);
            if (existingDragSurface != null) existingDragSurface.raycastTarget = originalDragSurfaceRaycastTarget;
            if (ownedDragSurface != null) DestroyOwnedObject(ownedDragSurface);
            if (ownedMask != null) DestroyOwnedObject(ownedMask);
            if (ownsScrollRect)
            {
                if (scrollRect != null) DestroyOwnedObject(scrollRect);
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

        private static void DestroyOwnedObject(UnityEngine.Object target)
        {
            if (target == null) return;
            if (Application.isPlaying) UnityEngine.Object.Destroy(target);
            else UnityEngine.Object.DestroyImmediate(target);
        }

        private void HandleScroll(Vector2 _)
        {
            if (ownsContent) RefreshVisible();
        }

        private void RefreshVisible(bool force = false)
        {
            if (!ownsContent)
            {
                for (int i = 0; i < rows.Count; i++)
                {
                    bool active = i < items.Count;
                    rows[i].gameObject.SetActive(active);
                    if (active) bind(rows[i], items[i], i);
                }
                return;
            }
            int maxFirst = Math.Max(0, items.Count - rows.Count);
            int first = Mathf.Clamp(Mathf.FloorToInt(Math.Max(0f,
                content.anchoredPosition.y - contentOrigin.y + rowOrigin.y) / itemHeight), 0, maxFirst);
            if (!force && first == lastFirstIndex && rows.Count > 0) return;
            lastFirstIndex = first;
            for (int i = 0; i < rows.Count; i++)
            {
                int index = first + i;
                RectTransform row = rows[i];
                bool active = index < items.Count;
                row.gameObject.SetActive(active);
                if (!active) continue;
                row.anchoredPosition = new Vector2(rowOrigin.x, rowOrigin.y - index * itemHeight);
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
