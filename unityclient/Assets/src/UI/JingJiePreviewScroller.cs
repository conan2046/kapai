using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;

namespace ProjectX.UI
{
    public sealed class JingJiePreviewScroller : MonoBehaviour, IBeginDragHandler, IDragHandler, IScrollHandler
    {
        [SerializeField, Min(1f)] private float rowHeight = 150f;
        [SerializeField] private float scrollStep = 35f;
        private readonly List<RectTransform> rows = new List<RectTransform>();
        private readonly List<Vector2> origins = new List<Vector2>();
        private int total;
        private Action<Transform, int> bind;
        private int previousFirst = -1;
        private float maxOffset;
        private float offset;

        public void Configure(IEnumerable<RectTransform> values, int count, Action<Transform, int> bindRow)
        {
            // Capture authored positions once. Reopening never treats a scrolled position as the layout.
            if (rows.Count == 0)
                foreach (RectTransform row in values.Where(value => value != null))
                {
                    rows.Add(row);
                    origins.Add(row.anchoredPosition);
                }
            total = count;
            bind = bindRow;
            previousFirst = -1;
            maxOffset = Mathf.Max(0f, rowHeight * count - ((RectTransform)transform).rect.height);
            offset = 0f;
            Apply();
        }
        public void OnBeginDrag(PointerEventData eventData) { }
        public void OnDrag(PointerEventData eventData) => Move(eventData.delta.y);
        public void OnScroll(PointerEventData eventData) => Move(-eventData.scrollDelta.y * scrollStep);
        private void Move(float delta) { offset = Mathf.Clamp(offset + delta, 0f, maxOffset); Apply(); }
        private void Apply()
        {
            int first = Mathf.FloorToInt(offset / rowHeight);
            for (int index = 0; index < rows.Count; index++)
            {
                if (rows[index] == null) continue;
                int entry = first + index;
                rows[index].gameObject.SetActive(entry < total);
                if (entry >= total) continue;
                if (first != previousFirst) bind(rows[index], entry);
                rows[index].anchoredPosition = origins[index] + Vector2.up * (offset - first * rowHeight);
            }
            previousFirst = first;
        }
    }
}
