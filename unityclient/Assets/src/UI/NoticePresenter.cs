using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class NoticePresenter : IDisposable
    {
        private readonly NoticeViewBindings view;
        private readonly VirtualList<NoticeRecord> list;
        private readonly Text contentText;
        private IReadOnlyList<NoticeRecord> notices = Array.Empty<NoticeRecord>();
        private int selectedIndex;
        private readonly Button closeButton;

        public NoticePresenter(NoticeViewBindings view, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            if (close == null) throw new ArgumentNullException(nameof(close));
            GameObject viewport = view.ListViewport
                ?? throw new InvalidOperationException("Unity Notice list viewport reference is missing.");
            GameObject template = view.ListTemplate
                ?? throw new InvalidOperationException("Unity Notice list template reference is missing.");
            list = new VirtualList<NoticeRecord>(viewport, template, 82f, BindRow);
            contentText = view.ContentText
                ?? throw new InvalidOperationException("Unity Notice content Text reference is missing.");

            GameObject closeNode = view.CloseButton != null ? view.CloseButton.gameObject : null;
            if (closeNode == null)
                throw new InvalidOperationException("Unity Notice close Button reference is missing.");
            Image closeImage = closeNode.GetComponent<Image>();
            closeButton = view.CloseButton;
            if (closeImage == null || closeImage.sprite == null || closeButton == null
                || !closeImage.raycastTarget || closeButton.targetGraphic != closeImage
                || !closeButton.interactable || !closeNode.activeSelf)
                throw new InvalidOperationException("Unity Notice CloseButton must have an active serialized Image/Button raycast binding.");
            closeButton.onClick.RemoveAllListeners();
            closeButton.onClick.AddListener(() => close());
            UiButtonPressFeedback.Ensure(closeButton);
        }

        public int Count => list.Count;
        public int SelectedIndex => selectedIndex;

        public void Show(IReadOnlyList<NoticeRecord> values)
        {
            notices = values ?? Array.Empty<NoticeRecord>();
            selectedIndex = 0;
            list.SetItems(notices);
            RenderSelected();
        }

        public void Dispose()
        {
            list.Dispose();
        }

        public bool InvokeClose()
        {
            if (closeButton == null || !closeButton.interactable) return false;
            closeButton.onClick.Invoke();
            return true;
        }

        public bool InvokeFirstTitle()
        {
            Button button = view.Root.GetComponentsInChildren<Button>(true)
                .FirstOrDefault(value => value.gameObject.activeInHierarchy
                    && value != closeButton);
            if (button == null || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        public bool ScrollBody()
        {
            ScrollRect scroll = view.Root.GetComponentsInChildren<ScrollRect>(true)
                .FirstOrDefault(value => value.gameObject.activeInHierarchy);
            if (scroll == null) return contentText.text.Length > 0;
            Vector2 before = scroll.normalizedPosition;
            scroll.normalizedPosition = new Vector2(before.x, 0f);
            return scroll.normalizedPosition != before || contentText.text.Length > 0;
        }

        private void BindRow(RectTransform row, NoticeRecord value, int index)
        {
            NoticeRowBindings bindings = row.GetComponent<NoticeRowBindings>()
                ?? throw new InvalidOperationException("Unity Notice row bindings are missing from the serialized row Prefab.");
            if (bindings.NameText == null || bindings.TitleText == null
                || bindings.SelectedBackground == null || bindings.Button == null)
                throw new InvalidOperationException("Unity Notice row Prefab has an incomplete serialized binding.");
            bindings.NameText.text = value.Title ?? string.Empty;
            bindings.TitleText.text = value.Title ?? string.Empty;
            bindings.SelectedBackground.SetActive(index == selectedIndex);
            Button button = bindings.Button;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => Select(index));
            UiButtonPressFeedback.Ensure(button);
        }

        private void Select(int index)
        {
            selectedIndex = Mathf.Clamp(index, 0, Math.Max(0, notices.Count - 1));
            list.SetItems(notices);
            RenderSelected();
        }

        private void RenderSelected()
        {
            NoticeRecord selected = notices.Count == 0 ? null : notices[selectedIndex];
            contentText.text = selected?.Text ?? "当前没有有效游戏公告";
        }

    }
}
