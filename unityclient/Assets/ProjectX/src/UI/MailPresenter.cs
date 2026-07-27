using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MailPresenter : IDisposable
    {
        private const string BasePath = "Layer";
        private readonly CocosUiView view;
        private readonly CocosUiView frameView;
        private readonly MailStore store;
        private readonly Core.ResourceService resources;
        private readonly Action<uint> claim;
        private readonly Action<uint> read;
        private readonly Action<uint> delete;
        private readonly Action claimAll;
        private readonly Action deleteAll;
        private readonly Action close;
        private readonly Action<RewardRecord> showAttachment;
        private readonly VirtualList<MailRecord> list;
        private readonly GameObject emptyPanel;
        private readonly GameObject contentPanel;
        private readonly Text title;
        private readonly Text body;
        private readonly Text deleteTime;
        private readonly Button claimButton;
        private readonly Button claimAllButton;
        private readonly Button deleteAllButton;
        private Button closeButton;
        private Button tabButton;
        private readonly GameObject attachmentViewport;
        private readonly GameObject attachmentTemplate;
        private RectTransform attachmentContent;
        private ScrollRect bodyScroll;
        private ScrollRect attachmentScroll;
        private uint selectedId;
        private int missingIconCount;

        public MailPresenter(CocosUiView view, CocosUiView frameView, MailStore store, Core.ResourceService resources,
            Action<uint> claim, Action<uint> read, Action<uint> delete,
            Action claimAll, Action deleteAll, Action close, Action<RewardRecord> showAttachment)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.frameView = frameView ?? throw new ArgumentNullException(nameof(frameView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.claim = claim ?? throw new ArgumentNullException(nameof(claim));
            this.read = read ?? throw new ArgumentNullException(nameof(read));
            this.delete = delete ?? throw new ArgumentNullException(nameof(delete));
            this.claimAll = claimAll ?? throw new ArgumentNullException(nameof(claimAll));
            this.deleteAll = deleteAll ?? throw new ArgumentNullException(nameof(deleteAll));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.showAttachment = showAttachment ?? throw new ArgumentNullException(nameof(showAttachment));
            emptyPanel = Require("None");
            contentPanel = Require("Panel");
            Text emptyText = emptyPanel.GetComponentInChildren<Text>(true);
            if (emptyText != null)
            {
                emptyText.enabled = true;
                emptyText.color = new Color32(120, 66, 63, 255);
                emptyText.fontSize = 36;
                emptyText.alignment = TextAnchor.MiddleCenter;
                emptyText.horizontalOverflow = HorizontalWrapMode.Overflow;
                RectTransform emptyRect = emptyText.rectTransform;
                emptyRect.anchorMin = Vector2.zero;
                emptyRect.anchorMax = Vector2.one;
                emptyRect.pivot = new Vector2(0.5f, 0.5f);
                emptyRect.anchoredPosition = Vector2.zero;
                emptyRect.offsetMin = Vector2.zero;
                emptyRect.offsetMax = Vector2.zero;
                emptyRect.localScale = Vector3.one;
            }
            GameObject viewport = Require("Panel/MailList/MailBg/MailListView");
            GameObject template = Require("Panel/MailList/MailBg/MailListView/MailBtn");
            EnsureDetailBackground();
            float itemHeight = Math.Max(100f, template.GetComponent<RectTransform>()?.rect.height ?? 100f);
            list = new VirtualList<MailRecord>(viewport, template, itemHeight, BindRow);
            title = Require("Panel/MailScreem/MailBg/TitleBg/TitleName").GetComponent<Text>();
            if (emptyText != null && title != null)
            {
                emptyText.font = title.font;
                emptyText.material = title.material;
            }
            body = ConfigureBody(Require("Panel/MailScreem/MailBg/ScrollView_1/MailContent").GetComponent<Text>());
            deleteTime = Require("Panel/MailScreem/MailBg/DeleteTime").GetComponent<Text>();
            if (deleteTime != null)
            {
                deleteTime.rectTransform.sizeDelta = new Vector2(420f, deleteTime.rectTransform.sizeDelta.y);
                deleteTime.alignment = TextAnchor.MiddleCenter;
                deleteTime.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            claimButton = Require("Panel/MailBtn/ReceiveBtn").GetComponent<Button>();
            attachmentViewport = Require("Panel/MailScreem/BtnBg/ListView");
            attachmentTemplate = Require("Panel/MailScreem/BtnBg/IconBg");
            Require("Panel/MailScreem/BtnBg/IconColor").SetActive(false);
            ConfigureAttachments();
            claimAllButton = Require("Panel/MailList/MailBg/ReceiveBtn").GetComponent<Button>();
            deleteAllButton = Require("Panel/MailList/MailBg/DeleteBtn").GetComponent<Button>();
            claimAllButton.onClick.RemoveAllListeners();
            claimAllButton.onClick.AddListener(() => this.claimAll());
            deleteAllButton.onClick.RemoveAllListeners();
            deleteAllButton.onClick.AddListener(() => this.deleteAll());
            closeButton = this.frameView.BindClick(
                "Layer/Panel_12/Title/CloseBtn", () => this.close(), true);
            tabButton = this.frameView.BindClick(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1", () => { }, true);
            tabButton.interactable = false;
            store.Changed += Render;
            Render();
        }

        public int ItemCount => store.Count;
        public int MissingIconCount => missingIconCount;
        public uint SelectedId => selectedId;
        public bool HasScrollableMailList => list.Count > 5;
        public bool HasScrollableBody => bodyScroll != null && bodyScroll.content != null
            && bodyScroll.content.rect.height > bodyScroll.viewport.rect.height;
        public bool HasScrollableAttachments => attachmentScroll != null && attachmentScroll.content != null
            && attachmentScroll.content.rect.width > attachmentScroll.viewport.rect.width;
        public string TitleText => title?.text ?? string.Empty;
        public string BodyText => body?.text ?? string.Empty;
        public bool IsEmptyVisible => emptyPanel.activeSelf;
        public string SingleActionLabel => claimButton.GetComponentInChildren<Text>(true)?.text ?? string.Empty;
        public string TabLabel => tabButton?.GetComponentInChildren<Text>(true)?.text ?? string.Empty;
        public bool HasCloseControl => closeButton != null && closeButton.gameObject.activeInHierarchy;

        public bool ScrollMailToBottom() => list.ScrollToBottom();
        public bool ScrollBodyToBottom()
        {
            Canvas.ForceUpdateCanvases();
            if (!HasScrollableBody) return false;
            bodyScroll.verticalNormalizedPosition = 0f;
            return true;
        }
        public bool ScrollAttachmentsToEnd()
        {
            Canvas.ForceUpdateCanvases();
            if (!HasScrollableAttachments) return false;
            attachmentScroll.horizontalNormalizedPosition = 1f;
            return true;
        }
        public bool InvokeFirstAttachmentDetail()
        {
            if (attachmentContent == null) return false;
            for (int index = 0; index < attachmentContent.childCount; index++)
            {
                Button button = attachmentContent.GetChild(index).GetComponent<Button>();
                if (button == null || !button.gameObject.activeSelf) continue;
                button.onClick.Invoke();
                return true;
            }
            return false;
        }
        public bool InvokeSingleAction()
        {
            if (!claimButton.gameObject.activeSelf || !claimButton.interactable) return false;
            claimButton.onClick.Invoke();
            return true;
        }
        public bool InvokeClaimAll()
        {
            if (!claimAllButton.gameObject.activeSelf || !claimAllButton.interactable) return false;
            claimAllButton.onClick.Invoke();
            return true;
        }
        public bool InvokeDeleteAll()
        {
            if (!deleteAllButton.gameObject.activeSelf || !deleteAllButton.interactable) return false;
            deleteAllButton.onClick.Invoke();
            return true;
        }
        public bool InvokeClose()
        {
            if (closeButton == null) return false;
            closeButton.onClick.Invoke();
            return true;
        }

        public void Render()
        {
            IReadOnlyList<MailRecord> items = store.Items;
            emptyPanel.SetActive(items.Count == 0);
            contentPanel.SetActive(items.Count > 0);
            list.SetItems(items);
            claimAllButton.gameObject.SetActive(items.Count > 0);
            deleteAllButton.gameObject.SetActive(true);
            if (items.Count == 0)
            {
                selectedId = 0;
                ClearAttachments();
                return;
            }
            bool found = false;
            foreach (MailRecord item in items)
                if (item.Id == selectedId) { found = true; break; }
            Select(found ? selectedId : items[0].Id);
        }

        public bool Select(uint id)
        {
            if (!store.TryGet(id, out MailRecord item)) return false;
            selectedId = id;
            RenderDetails(item);
            if (!item.IsRead && !item.HasAttachments) read(id);
            return true;
        }

        public void Dispose()
        {
            store.Changed -= Render;
            list.Dispose();
            ClearAttachments();
        }

        private void BindRow(RectTransform row, MailRecord item, int index)
        {
            string sender = DisplaySender(item);
            SetText(row, "Name", $"来自{sender}的邮件");
            SetText(row, "From", item.FromId == 0 ? "系统" : sender);
            DateTimeOffset date = DateTimeOffset.FromUnixTimeSeconds(item.ExpireAt).ToLocalTime().AddDays(-3);
            SetText(row, "Time", date.ToString("yyyy-MM-dd"));
            ConfigureRowText(row, "Name", 178f, TextAnchor.MiddleLeft);
            ConfigureRowText(row, "Time", 108f, TextAnchor.MiddleRight);
            SetVisible(row, "ChooseBg", item.Id == selectedId);
            SetVisible(row, "OpenImage", !item.IsRead);
            SetVisible(row, "CloseImage", item.IsRead);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => Select(item.Id));
            row.gameObject.name = $"Mail_{item.Id}_{index}";
        }

        private void RenderDetails(MailRecord item)
        {
            if (title != null) title.text = $"来自{DisplaySender(item)}的邮件";
            if (body != null) body.text = item.Message;
            if (deleteTime != null)
            {
                DateTimeOffset expires = DateTimeOffset.FromUnixTimeSeconds(item.ExpireAt).ToLocalTime();
                deleteTime.text = $"[{expires:yyyy-MM-dd HH:mm:ss} 后自动删除]";
            }
            claimButton.gameObject.SetActive(item.HasAttachments);
            claimButton.onClick.RemoveAllListeners();
            if (item.HasAttachments)
            {
                SetText(claimButton.transform, "BtnName", "领取");
                claimButton.onClick.AddListener(() => claim(item.Id));
            }
            else if (item.IsRead)
            {
                claimButton.gameObject.SetActive(true);
                SetText(claimButton.transform, "BtnName", "删除");
                claimButton.onClick.AddListener(() => delete(item.Id));
            }
            RenderAttachments(item.Attachments);
        }

        private void ConfigureAttachments()
        {
            RectTransform viewport = attachmentViewport.GetComponent<RectTransform>();
            viewport.sizeDelta = new Vector2(520f, viewport.sizeDelta.y);
            if (attachmentViewport.GetComponent<RectMask2D>() == null) attachmentViewport.AddComponent<RectMask2D>();
            attachmentScroll = attachmentViewport.GetComponent<ScrollRect>() ?? attachmentViewport.AddComponent<ScrollRect>();
            var contentObject = new GameObject("RuntimeAttachmentContent", typeof(RectTransform));
            attachmentContent = contentObject.GetComponent<RectTransform>();
            attachmentContent.SetParent(viewport, false);
            attachmentContent.anchorMin = new Vector2(0f, 0f);
            attachmentContent.anchorMax = new Vector2(0f, 1f);
            attachmentContent.pivot = new Vector2(0f, 0.5f);
            attachmentContent.anchoredPosition = Vector2.zero;
            attachmentContent.sizeDelta = Vector2.zero;
            attachmentScroll.viewport = viewport;
            attachmentScroll.content = attachmentContent;
            attachmentScroll.horizontal = true;
            attachmentScroll.vertical = false;
            attachmentScroll.movementType = ScrollRect.MovementType.Clamped;
            attachmentTemplate.SetActive(false);
        }

        private Text ConfigureBody(Text source)
        {
            if (source == null) return null;
            GameObject viewportObject = Require("Panel/MailScreem/MailBg/ScrollView_1");
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            RectTransform rect = source.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(1f, 1f);
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = Vector2.zero;
            source.alignment = TextAnchor.UpperLeft;
            source.horizontalOverflow = HorizontalWrapMode.Wrap;
            source.verticalOverflow = VerticalWrapMode.Overflow;
            source.raycastTarget = false;
            ContentSizeFitter fitter = source.GetComponent<ContentSizeFitter>() ?? source.gameObject.AddComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            bodyScroll = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();
            bodyScroll.viewport = viewport;
            bodyScroll.content = rect;
            bodyScroll.horizontal = false;
            bodyScroll.vertical = true;
            bodyScroll.movementType = ScrollRect.MovementType.Elastic;
            return source;
        }

        private void EnsureDetailBackground()
        {
            GameObject target = Require("Panel/MailScreem/MailBg");
            if (target.GetComponent<Graphic>() != null) return;
            Image background = target.AddComponent<Image>();
            background.color = new Color32(239, 222, 199, 255);
            background.raycastTarget = false;
        }

        private void RenderAttachments(IReadOnlyList<RewardRecord> attachments)
        {
            ClearAttachments();
            missingIconCount = 0;
            const float width = 104f;
            for (int index = 0; index < attachments.Count; index++)
            {
                RewardRecord item = attachments[index];
                GameObject cell = UnityEngine.Object.Instantiate(attachmentTemplate, attachmentContent, false);
                cell.name = $"MailReward_{index}_{item.Id}";
                cell.SetActive(true);
                RectTransform rect = cell.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(0f, 0.5f);
                rect.anchorMax = new Vector2(0f, 0.5f);
                rect.pivot = new Vector2(0f, 0.5f);
                rect.anchoredPosition = new Vector2(index * width, 0f);
                rect.sizeDelta = new Vector2(88f, 88f);
                Image icon = cell.transform.Find("EquipIcon")?.GetComponent<Image>();
                bool placeholder = true;
                Sprite sprite = item.Picture > 0 ? resources.LoadItemIcon(item.Picture, out placeholder) : null;
                if (icon != null)
                {
                    icon.sprite = sprite;
                    icon.enabled = sprite != null;
                    icon.preserveAspect = true;
                }
                if (sprite == null || placeholder) missingIconCount++;
                Text amount = cell.transform.Find("EquipNum")?.GetComponent<Text>();
                if (amount != null)
                {
                    amount.gameObject.SetActive(true);
                    amount.text = item.Amount > 1 ? $"×{item.Amount}" : string.Empty;
                }
                Button detail = cell.GetComponent<Button>() ?? cell.AddComponent<Button>();
                detail.targetGraphic = cell.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
                detail.onClick.RemoveAllListeners();
                detail.onClick.AddListener(() => showAttachment(item));
            }
            if (attachmentContent != null)
            {
                attachmentContent.sizeDelta = new Vector2(Math.Max(
                    attachmentViewport.GetComponent<RectTransform>().rect.width,
                    attachments.Count * width), 0f);
                LayoutRebuilder.ForceRebuildLayoutImmediate(attachmentContent);
                attachmentScroll.horizontalNormalizedPosition = 0f;
            }
        }

        private void ClearAttachments()
        {
            if (attachmentContent == null) return;
            for (int index = attachmentContent.childCount - 1; index >= 0; index--)
            {
                Transform child = attachmentContent.GetChild(index);
                if (child.name.StartsWith("MailReward_", StringComparison.Ordinal))
                {
                    child.gameObject.SetActive(false);
                    UnityEngine.Object.Destroy(child.gameObject);
                }
            }
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform root, string path, bool visible)
        {
            Transform target = root.Find(path);
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static string DisplaySender(MailRecord item)
        {
            if (string.IsNullOrWhiteSpace(item.Sender)
                || string.Equals(item.Sender, "System", StringComparison.OrdinalIgnoreCase))
                return "系统";
            return item.Sender;
        }

        private static void ConfigureRowText(Transform row, string path, float width, TextAnchor alignment)
        {
            Text text = row.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            RectTransform rect = text.rectTransform;
            rect.sizeDelta = new Vector2(width, rect.sizeDelta.y);
            text.alignment = alignment;
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
        }

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            return result ?? throw new InvalidOperationException($"Mail UI node was not found: {BasePath}/{relativePath}");
        }
    }
}
