using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ActivityPresenter : IDisposable
    {
        public const uint DailyRechargeTag = 1;

        private readonly CocosUiView rootView;
        private readonly CocosUiView backgroundView;
        private readonly CocosUiView dailyRechargeView;
        private readonly ActivityStore store;
        private readonly ServerTimeService serverTime;
        private readonly Action<uint> select;
        private readonly Action close;
        private readonly RectTransform tabRoot;
        private readonly Text emptyText;
        private readonly Text periodText;
        private readonly Text rewardSummary;
        private readonly List<GameObject> tabs = new List<GameObject>();

        public ActivityPresenter(CocosUiView rootView, CocosUiView backgroundView,
            CocosUiView dailyRechargeView, ActivityStore store, ServerTimeService serverTime,
            Action<uint> select, Action close)
        {
            this.rootView = rootView ?? throw new ArgumentNullException(nameof(rootView));
            this.backgroundView = backgroundView ?? throw new ArgumentNullException(nameof(backgroundView));
            this.dailyRechargeView = dailyRechargeView ?? throw new ArgumentNullException(nameof(dailyRechargeView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.select = select ?? throw new ArgumentNullException(nameof(select));
            this.close = close ?? throw new ArgumentNullException(nameof(close));

            Reparent(backgroundView, rootView.GameObject.transform);
            Reparent(dailyRechargeView, rootView.GameObject.transform);
            Normalize(backgroundView.GameObject);
            Normalize(dailyRechargeView.GameObject);
            Transform importedTemplate = FindNamed(backgroundView.GameObject.transform, "Button1");
            if (importedTemplate != null) importedTemplate.gameObject.SetActive(false);
            Transform importedClose = FindNamed(backgroundView.GameObject.transform, "CloseBtn");
            if (importedClose != null) Bind(importedClose.gameObject, close);

            tabRoot = CreatePanel(rootView.GameObject.transform, "ActivityTabs",
                new Vector2(0.035f, 0.18f), new Vector2(0.245f, 0.83f), new Color(0, 0, 0, 0));
            periodText = CreateText(rootView.GameObject.transform, "ActivityPeriod",
                new Vector2(0.28f, 0.86f), new Vector2(0.91f, 0.93f), 23, TextAnchor.MiddleLeft);
            emptyText = CreateText(rootView.GameObject.transform, "ActivityEmpty",
                new Vector2(0.28f, 0.24f), new Vector2(0.92f, 0.82f), 28, TextAnchor.MiddleCenter);
            rewardSummary = CreateText(rootView.GameObject.transform, "ActivityRewards",
                new Vector2(0.33f, 0.25f), new Vector2(0.88f, 0.40f), 22, TextAnchor.MiddleCenter);

            store.Changed += Render;
            Render();
        }

        public int TabCount => tabs.Count;
        public bool EmptyStateVisible => emptyText.gameObject.activeSelf;
        public bool DailyRechargeVisible => dailyRechargeView.GameObject.activeSelf;
        public int RewardCount => store.DailyRecharge?.Rewards.Count ?? 0;
        public bool HasCountdown => store.Items.Any(value => value.RemainingSeconds > 0);

        public void Tick()
        {
            RenderPeriod();
        }

        public void Render()
        {
            RebuildTabs();
            ActivityListRecord selected = store.Items.FirstOrDefault(value => value.Tag == store.SelectedTag);
            bool daily = selected?.Tag == DailyRechargeTag && store.DailyRecharge != null;
            dailyRechargeView.GameObject.SetActive(daily);
            emptyText.gameObject.SetActive(!daily);
            if (selected == null)
                emptyText.text = "当前没有进行中的活动\n/222 op=0xFF 返回空列表";
            else if (!daily)
                emptyText.text = $"{selected.Name}\n当前子页不在第一阶段迁移边界内";
            rewardSummary.gameObject.SetActive(daily);
            if (daily)
            {
                DailyRechargeActivityState state = store.DailyRecharge;
                rewardSummary.text = state.Rewards.Count == 0 ? "当前奖励配置为空"
                    : string.Join("    ", state.Rewards.Select(value =>
                        $"{(string.IsNullOrEmpty(value.Name) ? $"奖励#{value.Type}" : value.Name)} × {value.Amount}"));
                ConfigureDailyRechargeButtons(state);
            }
            RenderPeriod();
        }

        public void Dispose()
        {
            store.Changed -= Render;
        }

        private void RebuildTabs()
        {
            foreach (GameObject value in tabs) UnityEngine.Object.Destroy(value);
            tabs.Clear();
            for (int i = 0; i < store.Items.Count; i++)
            {
                ActivityListRecord item = store.Items[i];
                var go = new GameObject("ActivityTab" + item.Tag, typeof(RectTransform), typeof(Image), typeof(Button));
                RectTransform rect = go.GetComponent<RectTransform>();
                rect.SetParent(tabRoot, false);
                float top = 1f - i * 0.14f;
                rect.anchorMin = new Vector2(0f, top - 0.12f);
                rect.anchorMax = new Vector2(1f, top);
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                Image image = go.GetComponent<Image>();
                image.color = item.Tag == store.SelectedTag
                    ? new Color(0.72f, 0.35f, 0.12f, 0.98f)
                    : new Color(0.36f, 0.18f, 0.10f, 0.94f);
                uint tag = item.Tag;
                go.GetComponent<Button>().onClick.AddListener(() => select(tag));
                Text label = CreateText(rect, "BtnName", Vector2.zero, Vector2.one, 22, TextAnchor.MiddleCenter);
                label.text = item.Name;
                if (item.IsNew) label.text += "  新";
                if (item.HasHotPoint)
                {
                    RectTransform dot = CreatePanel(rect, "Prompt", new Vector2(0.88f, 0.68f),
                        new Vector2(0.98f, 0.90f), new Color(0.95f, 0.08f, 0.04f, 1f));
                    dot.gameObject.AddComponent<CanvasGroup>().blocksRaycasts = false;
                }
                tabs.Add(go);
            }
        }

        private void ConfigureDailyRechargeButtons(DailyRechargeActivityState state)
        {
            Transform recharge = FindNamed(dailyRechargeView.GameObject.transform, "RechargeBtn");
            if (recharge != null)
            {
                Button button = recharge.GetComponent<Button>() ?? recharge.gameObject.AddComponent<Button>();
                button.interactable = !state.Claimed;
                string label = !state.Recharged ? "前往充值" : state.Claimed ? "已领取" : "领取奖励";
                SetNamedText(recharge, "Text", label);
                EnsureButtonLabel(recharge, label);
            }
            Transform receive = FindNamed(dailyRechargeView.GameObject.transform, "ReceiveBtn");
            if (receive != null)
            {
                receive.gameObject.SetActive(state.WeChatRewardVisible);
                Button button = receive.GetComponent<Button>() ?? receive.gameObject.AddComponent<Button>();
                button.interactable = state.WeChatRecharged && !state.WeChatClaimed;
                string label = state.WeChatClaimed ? "已领取" : "微信奖励";
                SetNamedText(receive, "Text", label);
                EnsureButtonLabel(receive, label);
            }
        }

        private void RenderPeriod()
        {
            ActivityListRecord selected = store.Items.FirstOrDefault(value => value.Tag == store.SelectedTag);
            if (selected == null) { periodText.text = "活动"; return; }
            uint elapsed = serverTime.IsSynchronized && serverTime.UnixSeconds > store.ListSnapshotUnixSeconds
                ? serverTime.UnixSeconds - store.ListSnapshotUnixSeconds : 0;
            uint remaining = selected.RemainingSeconds > elapsed ? selected.RemainingSeconds - elapsed : 0;
            periodText.text = selected.RemainingSeconds == 0 ? selected.Name
                : $"{selected.Name} · 剩余 {remaining / 86400:D2}天 {(remaining % 86400) / 3600:D2}:{(remaining % 3600) / 60:D2}:{remaining % 60:D2}";
        }

        private static RectTransform CreatePanel(Transform parent, string name, Vector2 min, Vector2 max, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            go.GetComponent<Image>().color = color;
            return rect;
        }

        private static Text CreateText(Transform parent, string name, Vector2 min, Vector2 max, int size, TextAnchor alignment)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size; text.alignment = alignment; text.color = Color.white;
            return text;
        }

        private static void Reparent(CocosUiView view, Transform parent) => view.GameObject.transform.SetParent(parent, false);
        private static void Normalize(GameObject value)
        {
            RectTransform rect = value.GetComponent<RectTransform>();
            if (rect == null) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static void Bind(GameObject target, Action action)
        {
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => action());
        }

        private static Transform FindNamed(Transform root, string name)
        {
            foreach (Transform value in root.GetComponentsInChildren<Transform>(true))
                if (value.name == name) return value;
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
                if (text.gameObject.name == name) text.text = value ?? string.Empty;
        }

        private static void EnsureButtonLabel(Transform button, string value)
        {
            Transform existing = button.Find("ActivityButtonLabel");
            Text text = existing == null
                ? CreateText(button, "ActivityButtonLabel", Vector2.zero, Vector2.one, 22, TextAnchor.MiddleCenter)
                : existing.GetComponent<Text>();
            text.text = value ?? string.Empty;
            text.color = Color.white;
        }
    }
}
