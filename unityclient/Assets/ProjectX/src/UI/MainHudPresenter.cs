using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MainHudPresenter : IDisposable
    {
        private const int StaminaLimit = 100;
        private readonly CocosUiView view;
        private readonly CocosUiView chatView;
        private readonly PlayerStore player;
        private readonly CurrencyStore currencies;
        private readonly ChatStore chat;
        private readonly Core.ResourceService resources;
        private readonly Image portrait;
        private readonly Text nameText;
        private readonly Text levelText;
        private readonly Text vipText;
        private readonly Text powerText;
        private readonly Text goldText;
        private readonly Text premiumText;
        private readonly Text staminaText;
        private readonly Image experienceBar;
        private readonly GameObject powerWan;
        private readonly GameObject onlineButton;
        private readonly GameObject onlineTimeRoot;
        private readonly Text onlineTimeText;
        private readonly Image onlineRewardIcon;
        private readonly Text onlineRewardAmount;
        private readonly GameObject[] discountButtons = new GameObject[3];
        private readonly Text[] discountTimeTexts = new Text[3];
        private readonly Dictionary<int, bool> serverRedDots = new Dictionary<int, bool>();
        private static readonly string[] StableVisiblePromptPaths =
        {
            "Layer/Main_UI/btn_wanfa/Prompt",
            "Layer/Main_UI/ButtonGroup1/btn_chuandai/Prompt",
            "Layer/Main_UI/ButtonGroup1/btn_shenjiangbeibao/Prompt",
            "Layer/Main_UI/ButtonGroup1/btn_zhenrong/Prompt",
            "Layer/Main_UI/ButtonGroup3/btn_zhaomu/Prompt",
            "Layer/Main_UI/ButtonGroup5/btn_renwu/Prompt",
            "Layer/Main_UI/ButtonGroup5/btn_shangcheng/Prompt"
        };
        private readonly List<GameObject> summaryRows = new List<GameObject>();
        private readonly RectTransform chatPanel;
        private readonly RectTransform chatList;
        private readonly RectTransform chatBackground;
        private readonly RectTransform chatArrow;
        private readonly GameObject chatTemplate;
        private readonly RectTransform[] chatMovingControls;
        private readonly Vector2[] chatMovingOrigins;
        private int chatVisibleStartIndex;
        private bool systemChatSummaryVisible;
        private bool chatExpanded;
        private bool welfareVisible = true;
        private bool discountEntriesEnabled = true;

        public MainHudPresenter(CocosUiView view, CocosUiView chatView, PlayerStore player,
            CurrencyStore currencies, ChatStore chat, Core.ResourceService resources)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.chatView = chatView ?? throw new ArgumentNullException(nameof(chatView));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.chat = chat ?? throw new ArgumentNullException(nameof(chat));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            nameText = RequireText(view, "Layer/Main_UI/Head/name_bg/name");
            levelText = RequireText(view, "Layer/Main_UI/Head/bg_Level/Value");
            vipText = RequireText(view, "Layer/Main_UI/Head/bg_VIP/Value");
            powerText = RequireText(view, "Layer/Main_UI/Head/bg_CombatEffetiveness/Value");
            goldText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_jinbi/NumBg/Num");
            premiumText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_yuanbao/GoldNumBg/Num");
            staminaText = RequireText(view, "Layer/Main_UI/ButtonGroup6/Icon_tili/NumBg/Num");
            portrait = view.Binding.Find("Layer/Main_UI/Head/Icon")?.GetComponent<Image>();
            experienceBar = view.Binding.Find("Layer/Main_UI/Head/EXPBar")?.GetComponent<Image>();
            powerWan = view.Binding.Find("Layer/Main_UI/Head/bg_CombatEffetiveness/Value/Wan");
            RectTransform powerRect = powerText.rectTransform;
            powerRect.localScale = Vector3.one;
            powerRect.sizeDelta = new Vector2(108f, 24f);
            powerRect.anchoredPosition = new Vector2(128.0234f, 22.6932f);
            powerText.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            powerText.fontSize = 22;
            powerText.alignment = TextAnchor.MiddleLeft;
            powerText.horizontalOverflow = HorizontalWrapMode.Overflow;
            powerText.verticalOverflow = VerticalWrapMode.Overflow;
            powerText.color = new Color32(220, 180, 104, 255);
            Outline powerOutline = powerText.GetComponent<Outline>() ?? powerText.gameObject.AddComponent<Outline>();
            powerOutline.effectColor = new Color32(92, 48, 34, 255);
            powerOutline.effectDistance = new Vector2(1f, -1f);
            onlineButton = view.Binding.Find("Layer/Main_UI/btn_online");
            onlineTimeRoot = view.Binding.Find("Layer/Main_UI/btn_online/Time");
            onlineTimeText = view.Binding.Find("Layer/Main_UI/btn_online/Time/temp_text")?.GetComponent<Text>();
            Image premiumCurrencyIcon = view.Binding.Find("Layer/Main_UI/ButtonGroup6/Icon_yuanbao/Icon")?.GetComponent<Image>();
            if (onlineButton != null)
            {
                Image importedPlaceholder = onlineButton.GetComponent<Image>();
                if (importedPlaceholder != null) importedPlaceholder.enabled = false;
                var rewardVisual = new GameObject("ItemIconLayer.csb", typeof(RectTransform), typeof(Image));
                RectTransform rewardRect = rewardVisual.GetComponent<RectTransform>();
                rewardRect.SetParent(onlineButton.transform, false);
                rewardRect.anchorMin = rewardRect.anchorMax = rewardRect.pivot = new Vector2(.5f, .5f);
                rewardRect.anchoredPosition = new Vector2(0f, 17f);
                rewardRect.sizeDelta = new Vector2(92f, 78f);
                onlineRewardIcon = rewardVisual.GetComponent<Image>();
                onlineRewardIcon.sprite = premiumCurrencyIcon?.sprite;
                onlineRewardIcon.preserveAspect = true;
                onlineRewardIcon.raycastTarget = false;

                var amountVisual = new GameObject("Count", typeof(RectTransform), typeof(Text), typeof(Outline));
                RectTransform amountRect = amountVisual.GetComponent<RectTransform>();
                amountRect.SetParent(rewardRect, false);
                amountRect.anchorMin = amountRect.anchorMax = new Vector2(1f, 0f);
                amountRect.pivot = new Vector2(1f, 0f);
                amountRect.anchoredPosition = new Vector2(2f, -2f);
                amountRect.sizeDelta = new Vector2(52f, 28f);
                onlineRewardAmount = amountVisual.GetComponent<Text>();
                onlineRewardAmount.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                onlineRewardAmount.fontSize = 20;
                onlineRewardAmount.alignment = TextAnchor.LowerRight;
                onlineRewardAmount.color = Color.white;
                onlineRewardAmount.raycastTarget = false;
                Outline outline = amountVisual.GetComponent<Outline>();
                outline.effectColor = new Color32(72, 39, 22, 255);
                outline.effectDistance = new Vector2(1f, -1f);
            }
            for (int index = 0; index < discountButtons.Length; index++)
            {
                string root = $"Layer/Main_UI/ButtonGroup8/btn_Zhekou{index + 1}";
                discountButtons[index] = view.Binding.Find(root);
                discountTimeTexts[index] = view.Binding.Find(root + "/Image/Text")?.GetComponent<Text>();
            }
            InitializeStableRedDots();
            chatPanel = chatView.Binding.Find("Layer/Panel_Chat")?.GetComponent<RectTransform>();
            chatList = chatView.Binding.Find("Layer/Panel_Chat/ListView")?.GetComponent<RectTransform>();
            chatBackground = chatView.Binding.Find("Layer/Panel_Chat/bg")?.GetComponent<RectTransform>();
            chatArrow = chatView.Binding.Find("Layer/Panel_Chat/btn_Arrows")?.GetComponent<RectTransform>();
            chatMovingControls = new[]
            {
                chatArrow,
                chatView.Binding.Find("Layer/Panel_Chat/btn_Friend")?.GetComponent<RectTransform>(),
                chatView.Binding.Find("Layer/Panel_Chat/btn_Voice_shi")?.GetComponent<RectTransform>(),
                chatView.Binding.Find("Layer/Panel_Chat/btn_Voice_bang")?.GetComponent<RectTransform>(),
                chatView.Binding.Find("Layer/Panel_Chat/btn_laba")?.GetComponent<RectTransform>()
            };
            chatMovingOrigins = chatMovingControls.Select(control => control != null ? control.anchoredPosition : Vector2.zero).ToArray();
            chatTemplate = chatView.Binding.Find("Layer/Panel_Chat/Item");
            if (chatTemplate != null) chatTemplate.SetActive(false);
            SetChatControlVisible("Layer/Panel_Chat/Prompt", false);
            SetChatControlVisible("Layer/Panel_Chat/btn_Friend", false);
            SetChatControlVisible("Layer/Panel_Chat/btn_Voice_shi", false);
            SetChatControlVisible("Layer/Panel_Chat/btn_Voice_bang", false);
            SetChatControlVisible("Layer/Panel_Chat/btn_laba", false);
            SetChatControlVisible("Layer/Panel_Chat/btn_Set", false);
            if (chatList != null && chatList.GetComponent<RectMask2D>() == null)
                chatList.gameObject.AddComponent<RectMask2D>();
            if (portrait != null)
            {
                portrait.preserveAspect = true;
                portrait.color = Color.white;
            }
            // UImainLayer_new and native Cocos ship the three rotating-offer entries visible.
            // The Steam product scope disables them after presenter construction;
            // later /222 pushes must not make an excluded commercial entry visible.
            // Native ChatMini does not replay messages received before the HUD
            // node exists and suppresses the initial-login system broadcasts.
            // A real reconnect starts a new visible window for the broadcasts
            // arriving after that reconnect begins.
            chatVisibleStartIndex = chat.Count;
            systemChatSummaryVisible = false;
            SetChatExpanded(false);
            player.Changed += Render;
            currencies.Changed += Render;
            chat.Changed += RenderChatSummary;
            Render();
            RenderChatSummary();
        }

        public bool IsChatExpanded => chatExpanded;
        public int VisibleDiscountCount => discountButtons.Count(button => button != null && button.activeInHierarchy);
        public int VisibleRedDotCount => StableVisiblePromptPaths.Count(path => view.Binding.Find(path)?.activeInHierarchy == true);
        public string VisibleRedDotSummary => string.Join(",", StableVisiblePromptPaths
            .Where(path => view.Binding.Find(path)?.activeInHierarchy == true));

        public void Render()
        {
            nameText.text = player.Name ?? string.Empty;
            levelText.text = player.Level.ToString();
            vipText.text = "贵族" + player.VipLevel;
            bool compactPower = player.Power >= 1000000;
            powerText.text = compactPower ? (player.Power / 10000UL).ToString() : player.Power.ToString();
            if (powerWan != null) powerWan.SetActive(compactPower);
            if (portrait != null) portrait.sprite = resources.LoadPlayerRoundPortrait(player.Head);
            goldText.text = FormatGold(currencies.Gold);
            premiumText.text = Math.Max(0, currencies.Premium).ToString();
            staminaText.text = $"{Math.Max(0, currencies.Stamina)}/{StaminaLimit}";
            if (experienceBar != null)
            {
                int limit = Math.Max(1, WorldVisualCatalog.GetPlayerExperienceLimit(player.Level));
                experienceBar.fillAmount = Mathf.Clamp01((float)player.Experience / limit);
            }
        }

        public void SetOnlineReward(int claimedIndex, int elapsedSeconds)
        {
            if (!welfareVisible)
            {
                if (onlineButton != null) onlineButton.SetActive(false);
                return;
            }
            if (onlineButton != null) onlineButton.SetActive(true);
            int[] minutes = {3, 8, 15, 25, 40, 60, 85, 120, 150, 180, 210, 240};
            int[] amounts = {50, 100, 150, 200, 250, 1, 300, 1, 350, 1, 1, 1};
            int next = Mathf.Clamp(claimedIndex, 0, minutes.Length - 1);
            int previous = next == 0 ? 0 : minutes[next - 1];
            int remaining = Math.Max(0, (minutes[next] - previous) * 60 - elapsedSeconds);
            if (onlineRewardIcon != null) onlineRewardIcon.gameObject.SetActive(true);
            if (onlineRewardAmount != null) onlineRewardAmount.text = amounts[next].ToString();
            if (onlineTimeRoot != null) onlineTimeRoot.SetActive(remaining > 0);
            if (onlineTimeText != null) onlineTimeText.text = FormatDuration(remaining);
        }

        public void SetWelfareVisible(bool visible)
        {
            welfareVisible = visible;
            if (onlineButton != null) onlineButton.SetActive(visible);
        }

        public void SetDiscountEntriesEnabled(bool enabled)
        {
            discountEntriesEnabled = enabled;
            if (enabled) return;
            foreach (GameObject button in discountButtons)
                if (button != null) button.SetActive(false);
        }

        public void SetDiscountState(int operation, uint seconds, bool available)
        {
            int index = operation - 89;
            if (index < 0 || index >= discountButtons.Length) return;
            if (discountButtons[index] != null)
                discountButtons[index].SetActive(discountEntriesEnabled && available && seconds > 0);
            if (discountTimeTexts[index] != null) discountTimeTexts[index].text = FormatDuration(checked((int)Math.Min(seconds, int.MaxValue)));
        }

        public void SetRedDot(int redType, bool visible)
        {
            serverRedDots[redType] = visible;
            string target = redType switch
            {
                >= 1 and <= 5 => "Layer/Main_UI/ButtonGroup3/btn_bangpai",
                21 or 22 => "Layer/Main_UI/ButtonGroup7/btn_friend",
                31 => "Layer/Main_UI/ButtonGroup7/btn_mail",
                41 or 51 or 101 or 103 => "Layer/Main_UI/btn_wanfa",
                61 or 63 or 64 => "Layer/Main_UI/btn_fuben",
                71 or 72 => "Layer/Main_UI/ButtonGroup5/btn_shangcheng",
                102 => "Layer/Main_UI/ButtonGroup5/btn_renwu",
                111 or 121 => "Layer/Main_UI/ButtonGroup5/btn_fuli",
                131 => "Layer/Main_UI/ButtonGroup1/btn_shenjiangbeibao",
                201 => "Layer/Main_UI/ButtonGroup4/btn_Qiri",
                _ => string.Empty
            };
            if (string.IsNullOrEmpty(target)) return;
            GameObject root = view.Binding.Find(target);
            if (root == null) return;
            bool aggregate = serverRedDots.Any(entry => RedDotTarget(entry.Key) == target && entry.Value);
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(aggregate);
        }

        public void ToggleChatExpanded() => SetChatExpanded(!chatExpanded);

        public void BeginReconnectChatSummary()
        {
            chatVisibleStartIndex = 0;
            systemChatSummaryVisible = true;
            RenderChatSummary();
        }

        public void SetChatExpanded(bool expanded)
        {
            chatExpanded = expanded;
            const float collapsedListHeight = 100.8287f;
            const float collapsedBackgroundHeight = 92.2f;
            const float expansionOffset = 115.8287f;
            if (chatList != null)
                chatList.sizeDelta = new Vector2(chatList.sizeDelta.x, collapsedListHeight + (expanded ? collapsedListHeight : 0f));
            if (chatBackground != null)
                chatBackground.sizeDelta = new Vector2(chatBackground.sizeDelta.x, collapsedBackgroundHeight + (expanded ? collapsedListHeight : 0f));
            for (int index = 0; index < chatMovingControls.Length; index++)
            {
                RectTransform control = chatMovingControls[index];
                if (control != null) control.anchoredPosition = chatMovingOrigins[index] + Vector2.up * (expanded ? expansionOffset : 0f);
            }
            if (chatArrow != null) chatArrow.localEulerAngles = new Vector3(0f, 0f, expanded ? 180f : 0f);
            RenderChatSummary();
        }

        public bool Validate(out string detail)
        {
            detail = string.Empty;
            if (!player.IsLoaded || string.IsNullOrEmpty(player.Name)) { detail = "player snapshot is not loaded"; return false; }
            if (nameText.text != player.Name || levelText.text != player.Level.ToString()) { detail = "name/level HUD mismatch"; return false; }
            if (vipText.text != "贵族" + player.VipLevel) { detail = "VIP HUD mismatch"; return false; }
            if (goldText.text != FormatGold(currencies.Gold)) { detail = "gold HUD mismatch"; return false; }
            if (premiumText.text != Math.Max(0, currencies.Premium).ToString()) { detail = "premium HUD mismatch"; return false; }
            if (!currencies.Has(CurrencyIds.Stamina) || staminaText.text != $"{currencies.Stamina}/{StaminaLimit}") { detail = "stamina HUD mismatch"; return false; }
            detail = $"role={player.RoleId} name={player.Name} level={player.Level} vip={player.VipLevel} exp={player.Experience} power={player.Power} gold={currencies.Gold} premium={currencies.Premium} stamina={currencies.Stamina}";
            return true;
        }

        public void Dispose()
        {
            player.Changed -= Render;
            currencies.Changed -= Render;
            chat.Changed -= RenderChatSummary;
            ClearSummaryRows();
        }

        private void RenderChatSummary()
        {
            ClearSummaryRows();
            if (chatList == null) return;
            IReadOnlyList<ChatMessageRecord> records = chat.Messages;
            List<ChatMessageRecord> visibleRecords = records
                .Skip(Math.Min(chatVisibleStartIndex, records.Count))
                .Where(record => systemChatSummaryVisible || record.Channel != ChatChannel.System)
                .ToList();
            int visibleCount = chatExpanded ? 4 : 2;
            int start = Math.Max(0, visibleRecords.Count - visibleCount);
            const float rowHeight = 58f;
            for (int index = start; index < visibleRecords.Count; index++)
            {
                ChatMessageRecord record = visibleRecords[index];
                GameObject row = chatTemplate != null
                    ? UnityEngine.Object.Instantiate(chatTemplate, chatList, false)
                    : new GameObject($"HudChatSummary_{index}", typeof(RectTransform));
                row.name = $"HudChatSummary_{index}";
                row.SetActive(true);
                RectTransform rect = row.GetComponent<RectTransform>();
                if (rect.parent != chatList) rect.SetParent(chatList, false);
                rect.anchorMin = new Vector2(0f, 1f);
                rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(0f, 1f);
                rect.anchoredPosition = new Vector2(0f, -(index - start) * rowHeight);
                rect.sizeDelta = new Vector2(Math.Max(1f, chatList.rect.width), rowHeight);

                Transform tagRoot = row.transform.Find("Tag");
                if (tagRoot != null)
                {
                    RectTransform tagRect = tagRoot.GetComponent<RectTransform>();
                    tagRect.anchorMin = tagRect.anchorMax = new Vector2(0f, 1f);
                    tagRect.pivot = new Vector2(0f, 1f);
                    tagRect.anchoredPosition = new Vector2(4f, -1f);
                    tagRect.sizeDelta = new Vector2(56f, 24f);
                    Image tagImage = tagRoot.GetComponent<Image>();
                    if (tagImage != null) { tagImage.sprite = null; tagImage.color = new Color32(196, 48, 45, 255); }
                    Text tagText = tagRoot.GetComponentInChildren<Text>(true);
                    if (tagText == null)
                    {
                        var label = new GameObject("Channel", typeof(RectTransform), typeof(Text));
                        label.transform.SetParent(tagRoot, false);
                        tagText = label.GetComponent<Text>();
                        RectTransform labelRect = label.GetComponent<RectTransform>();
                        labelRect.anchorMin = Vector2.zero;
                        labelRect.anchorMax = Vector2.one;
                        labelRect.offsetMin = labelRect.offsetMax = Vector2.zero;
                    }
                    tagText.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                    tagText.fontSize = 18;
                    tagText.alignment = TextAnchor.MiddleCenter;
                    tagText.color = Color.white;
                    tagText.text = record.Channel == ChatChannel.System ? "系统" : "世界";
                }
                SetChildActive(row.transform, "Tag_laba", false);
                SetChildActive(row.transform, "Content_laba", false);
                SetChildActive(row.transform, "Prompt", false);

                Text text = row.transform.Find("Content")?.GetComponent<Text>();
                if (text == null) text = row.AddComponent<Text>();
                RectTransform textRect = text.rectTransform;
                textRect.anchorMin = textRect.anchorMax = new Vector2(0f, 1f);
                textRect.pivot = new Vector2(0f, 1f);
                textRect.anchoredPosition = new Vector2(68f, 0f);
                textRect.sizeDelta = new Vector2(Math.Max(1f, chatList.rect.width - 72f), rowHeight);
                text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                text.fontSize = 20;
                text.alignment = TextAnchor.UpperLeft;
                text.horizontalOverflow = HorizontalWrapMode.Wrap;
                text.verticalOverflow = VerticalWrapMode.Overflow;
                text.lineSpacing = .8f;
                text.color = Color.white;
                text.supportRichText = true;
                string content = (record.Content ?? string.Empty)
                    .Replace("[c/n]", string.Empty)
                    .Replace("[c/]", string.Empty)
                    .Replace("[/c]", string.Empty);
                if (!string.IsNullOrWhiteSpace(player.Name))
                    content = content.Replace(player.Name, $"<color=#29A9D6>{player.Name}</color>");
                text.text = record.Channel == ChatChannel.System
                    ? content
                    : string.IsNullOrWhiteSpace(record.Sender.Name) ? content : $"{record.Sender.Name}：{content}";
                summaryRows.Add(row);
            }
            ScrollRect scroll = chatList.GetComponentInParent<ScrollRect>();
            if (scroll != null && scroll.content != null) scroll.verticalNormalizedPosition = 0f;
        }

        private void ClearSummaryRows()
        {
            foreach (GameObject row in summaryRows) if (row != null) UnityEngine.Object.Destroy(row);
            summaryRows.Clear();
        }

        private void SetChatControlVisible(string path, bool visible)
        {
            GameObject control = chatView.Binding.Find(path);
            if (control != null) control.SetActive(visible);
        }

        private static void SetChildActive(Transform root, string path, bool visible)
        {
            Transform child = root.Find(path);
            if (child != null) child.gameObject.SetActive(visible);
        }

        private void InitializeStableRedDots()
        {
            foreach (Transform child in view.GameObject.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
            foreach (string path in StableVisiblePromptPaths)
                view.Binding.Find(path)?.SetActive(true);
        }

        private static string RedDotTarget(int redType)
        {
            return redType switch
            {
                >= 1 and <= 5 => "Layer/Main_UI/ButtonGroup3/btn_bangpai",
                21 or 22 => "Layer/Main_UI/ButtonGroup7/btn_friend",
                31 => "Layer/Main_UI/ButtonGroup7/btn_mail",
                41 or 51 or 101 or 103 => "Layer/Main_UI/btn_wanfa",
                61 or 63 or 64 => "Layer/Main_UI/btn_fuben",
                71 or 72 => "Layer/Main_UI/ButtonGroup5/btn_shangcheng",
                102 => "Layer/Main_UI/ButtonGroup5/btn_renwu",
                111 or 121 => "Layer/Main_UI/ButtonGroup5/btn_fuli",
                131 => "Layer/Main_UI/ButtonGroup1/btn_shenjiangbeibao",
                201 => "Layer/Main_UI/ButtonGroup4/btn_Qiri",
                _ => string.Empty
            };
        }

        private static Text RequireText(CocosUiView owner, string path)
        {
            GameObject node = owner?.Binding.Find(path) ?? throw new InvalidOperationException($"Main HUD node was not found: {path}");
            return node.GetComponent<Text>() ?? throw new InvalidOperationException($"Main HUD node has no Text component: {path}");
        }

        private static string FormatGold(long raw)
        {
            long value = Math.Max(0, raw);
            return value >= 1000000 ? $"{value / 10000}万" : value.ToString();
        }

        private static string FormatDuration(int seconds)
        {
            seconds = Math.Max(0, seconds);
            int hours = seconds / 3600;
            return $"{hours:00}:{seconds / 60 % 60:00}:{seconds % 60:00}";
        }
    }
}
