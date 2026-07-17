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
        private readonly MailStore store;
        private readonly Core.ResourceService resources;
        private readonly Action<uint> claim;
        private readonly VirtualList<MailRecord> list;
        private readonly GameObject emptyPanel;
        private readonly GameObject contentPanel;
        private readonly Text title;
        private readonly Text body;
        private readonly Text deleteTime;
        private readonly Button claimButton;
        private readonly GameObject attachmentViewport;
        private readonly GameObject attachmentTemplate;
        private RectTransform attachmentContent;
        private uint selectedId;
        private int missingIconCount;

        public MailPresenter(CocosUiView view, MailStore store, Core.ResourceService resources, Action<uint> claim)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.claim = claim ?? throw new ArgumentNullException(nameof(claim));
            emptyPanel = Require("None");
            contentPanel = Require("Panel");
            GameObject viewport = Require("Panel/MailList/MailBg/MailListView");
            GameObject template = Require("Panel/MailList/MailBg/MailListView/MailBtn");
            EnsureDetailBackground();
            float itemHeight = Math.Max(100f, template.GetComponent<RectTransform>()?.rect.height ?? 100f);
            list = new VirtualList<MailRecord>(viewport, template, itemHeight, BindRow);
            title = Require("Panel/MailScreem/MailBg/TitleBg/TitleName").GetComponent<Text>();
            body = CreateRuntimeBody(Require("Panel/MailScreem/MailBg/ScrollView_1/MailContent").GetComponent<Text>());
            deleteTime = Require("Panel/MailScreem/MailBg/DeleteTime").GetComponent<Text>();
            claimButton = Require("Panel/MailBtn/ReceiveBtn").GetComponent<Button>();
            attachmentViewport = Require("Panel/MailScreem/BtnBg/ListView");
            attachmentTemplate = Require("Panel/MailScreem/BtnBg/IconBg");
            Require("Panel/MailScreem/BtnBg/IconColor").SetActive(false);
            ConfigureAttachments();
            Require("Panel/MailList/MailBg/ReceiveBtn").SetActive(false);
            Require("Panel/MailList/MailBg/DeleteBtn").SetActive(false);
            store.Changed += Render;
            Render();
        }

        public int ItemCount => store.Count;
        public int MissingIconCount => missingIconCount;
        public uint SelectedId => selectedId;

        public void Render()
        {
            IReadOnlyList<MailRecord> items = store.Items;
            emptyPanel.SetActive(items.Count == 0);
            contentPanel.SetActive(items.Count > 0);
            list.SetItems(items);
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
            store.MarkRead(id);
            RenderDetails(item.WithRead(true));
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
            SetText(row, "Name", string.IsNullOrEmpty(item.Sender) ? "系统邮件" : $"来自{item.Sender}的邮件");
            SetText(row, "From", item.FromId == 0 ? "系统" : item.Sender);
            DateTimeOffset date = DateTimeOffset.FromUnixTimeSeconds(item.ExpireAt).ToLocalTime().AddDays(-3);
            SetText(row, "Time", date.ToString("yyyy-MM-dd"));
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
            if (title != null) title.text = string.IsNullOrEmpty(item.Sender) ? "系统邮件" : $"来自{item.Sender}的邮件";
            if (body != null) body.text = item.Message;
            if (deleteTime != null)
            {
                DateTimeOffset expires = DateTimeOffset.FromUnixTimeSeconds(item.ExpireAt).ToLocalTime();
                deleteTime.text = $"{expires:yyyy-MM-dd HH:mm} 后自动删除";
            }
            claimButton.gameObject.SetActive(item.HasAttachments);
            claimButton.onClick.RemoveAllListeners();
            if (item.HasAttachments) claimButton.onClick.AddListener(() => claim(item.Id));
            RenderAttachments(item.Attachments);
        }

        private void ConfigureAttachments()
        {
            RectTransform viewport = attachmentViewport.GetComponent<RectTransform>();
            if (attachmentViewport.GetComponent<RectMask2D>() == null) attachmentViewport.AddComponent<RectMask2D>();
            ScrollRect scroll = attachmentViewport.GetComponent<ScrollRect>() ?? attachmentViewport.AddComponent<ScrollRect>();
            scroll.enabled = false;
            attachmentContent = viewport;
            attachmentTemplate.SetActive(false);
        }

        private Text CreateRuntimeBody(Text source)
        {
            if (source != null) source.gameObject.SetActive(false);
            Transform parent = Require("Panel/MailScreem/MailBg").transform;
            var bodyObject = new GameObject("RuntimeMailBody", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            bodyObject.transform.SetParent(parent, false);
            RectTransform rect = bodyObject.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.zero;
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(20f, 275f);
            rect.sizeDelta = new Vector2(580f, 210f);
            Text result = bodyObject.GetComponent<Text>();
            result.font = source != null ? source.font : Resources.GetBuiltinResource<Font>("Arial.ttf");
            result.fontSize = source != null ? source.fontSize : 20;
            result.color = source != null ? source.color : new Color32(110, 56, 48, 255);
            result.alignment = TextAnchor.UpperLeft;
            result.horizontalOverflow = HorizontalWrapMode.Wrap;
            result.verticalOverflow = VerticalWrapMode.Truncate;
            result.raycastTarget = false;
            return result;
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
            const float width = 96f;
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
            }
            if (attachmentContent != null)
            {
                LayoutRebuilder.ForceRebuildLayoutImmediate(attachmentContent);
            }
        }

        private void ClearAttachments()
        {
            if (attachmentContent == null) return;
            for (int index = attachmentContent.childCount - 1; index >= 0; index--)
            {
                Transform child = attachmentContent.GetChild(index);
                if (child.name.StartsWith("MailReward_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
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

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            return result ?? throw new InvalidOperationException($"Mail UI node was not found: {BasePath}/{relativePath}");
        }
    }
}
