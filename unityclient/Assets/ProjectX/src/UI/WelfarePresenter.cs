using System;
using System.Collections.Generic;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class WelfarePresenter : IDisposable
    {
        private readonly CocosUiView welfareView;
        private readonly CocosUiView signView;
        private readonly CocosUiView onlineView;
        private readonly WelfareStore store;
        private readonly ServerTimeService serverTime;
        private readonly ResourceService resources;
        private readonly Action claimSign;
        private readonly VirtualList<WelfareSignRecord> signList;
        private readonly VirtualList<WelfareOnlineRecord> onlineList;
        private readonly GameObject stageEmpty;
        private readonly Text periodText;
        private readonly ImodAnimationPlayer signAnimation;
        private int tab;

        public WelfarePresenter(CocosUiView welfareView, CocosUiView signView, CocosUiView onlineView,
            WelfareStore store, ServerTimeService serverTime, ResourceService resources,
            Action claimSign, Action close)
        {
            this.welfareView = welfareView ?? throw new ArgumentNullException(nameof(welfareView));
            this.signView = signView ?? throw new ArgumentNullException(nameof(signView));
            this.onlineView = onlineView ?? throw new ArgumentNullException(nameof(onlineView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.claimSign = claimSign ?? throw new ArgumentNullException(nameof(claimSign));

            Reparent(signView, welfareView.GameObject.transform);
            Reparent(onlineView, welfareView.GameObject.transform);
            Normalize(signView.GameObject);
            Normalize(onlineView.GameObject);
            signList = new VirtualList<WelfareSignRecord>(Require(signView, "Layer/LoginGiftUI/ListView"),
                Require(signView, "Layer/LoginGiftUI/Item"), 112f, BindSign);
            Require(signView, "Layer/LoginGiftUI/ItemList").SetActive(false);
            onlineList = new VirtualList<WelfareOnlineRecord>(Require(onlineView, "Layer/LoginGiftUI/ListView"),
                Require(onlineView, "Layer/LoginGiftUI/Item"), 112f, BindOnline);
            periodText = CreateText(welfareView.GameObject.transform, "WelfarePeriod", new Vector2(0.29f, 0.88f),
                new Vector2(0.93f, 0.95f), 22, TextAnchor.MiddleLeft);
            stageEmpty = CreateText(welfareView.GameObject.transform, "StageGoalEmpty", new Vector2(0.27f, 0.22f),
                new Vector2(0.94f, 0.82f), 28, TextAnchor.MiddleCenter).gameObject;
            signAnimation = CreateSignAnimation(signView.GameObject.transform);
            CreateTab("签到", 0, 0.68f);
            CreateTab("在线奖励", 1, 0.56f);
            CreateTab("阶段目标", 2, 0.44f);
            Bind(welfareView, "Layer/WelfareUI/Bg/btn_Close", close);
            store.Changed += Render;
            Render();
        }

        public int SignCount => signList.Count;
        public int OnlineCount => onlineList.Count;
        public int MissingIconCount { get; private set; }
        public int SelectedTab => tab;

        public void Tick()
        {
            if (tab == 1) RenderPeriod();
        }

        public void SelectTab(int value)
        {
            tab = Mathf.Clamp(value, 0, 2);
            Render();
        }

        public void Render()
        {
            signView.GameObject.SetActive(tab == 0);
            onlineView.GameObject.SetActive(tab == 1);
            stageEmpty.SetActive(tab == 2);
            if (signAnimation != null)
                signAnimation.gameObject.SetActive(tab == 0 && store.NextSign != null);
            MissingIconCount = 0;
            signList.SetItems(store.Signs);
            onlineList.SetItems(store.Online);
            Text count = Find(signView, "Layer/LoginGiftUI/bg_Tips/Count")?.GetComponent<Text>();
            if (count != null) count.text = store.SignedDays.ToString();
            Text empty = stageEmpty.GetComponent<Text>();
            empty.text = store.StageGoalAvailable ? "暂无阶段目标" : "阶段目标服务端当前未启用\n/223 处理主体为空，保留真实空态";
            RenderPeriod();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            signList.Dispose();
            onlineList.Dispose();
        }

        private void RenderPeriod()
        {
            if (!serverTime.IsSynchronized) { periodText.text = "服务器时间同步中"; return; }
            if (tab == 0)
            {
                periodText.text = $"每日福利 · 本月累计签到 {store.SignedDays} 天 · 今日{(store.SignedToday ? "已领取" : "可领取")}";
                return;
            }
            if (tab == 2) { periodText.text = "阶段目标 · 服务端边界独立于日常任务 /37"; return; }
            WelfareOnlineRecord next = null;
            foreach (WelfareOnlineRecord value in store.Online)
                if (value.Id == store.OnlineClaimedCount + 1) { next = value; break; }
            uint elapsed = store.OnlineAccumulatedSeconds + Math.Max(0u, serverTime.UnixSeconds - store.OnlineSnapshotUnixSeconds);
            uint remaining = next == null || elapsed >= next.RequiredSeconds ? 0 : next.RequiredSeconds - elapsed;
            periodText.text = next == null ? "今日在线奖励已全部领取"
                : $"每日在线福利 · 下一档 {next.CumulativeMinutes} 分钟 · 剩余 {remaining / 60:D2}:{remaining % 60:D2}";
        }

        private void BindSign(RectTransform row, WelfareSignRecord value, int index)
        {
            SetNamedText(row, "Title", $"第 {value.Day} 天");
            string rewardName = string.IsNullOrEmpty(value.Reward.Name) ? $"奖励 #{value.Reward.Type}" : value.Reward.Name;
            SetNamedText(row, "Name", $"{rewardName}×{value.Reward.Amount}");
            Transform tag = FindNamed(row, "bg_Tag");
            if (tag != null) tag.gameObject.SetActive(value.VipMultiple > 1);
            SetNamedText(row, "Text", $"V{value.VipLevel}×{value.VipMultiple}");
            Transform chosen = FindNamed(row, "choose");
            if (chosen != null) chosen.gameObject.SetActive(value.State == WelfareRewardState.Claimed);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>(true);
            button.interactable = value.State == WelfareRewardState.Claimable;
            button.onClick.RemoveAllListeners();
            if (button.interactable) button.onClick.AddListener(() => claimSign());
        }

        private void BindOnline(RectTransform row, WelfareOnlineRecord value, int index)
        {
            Text title = FindNamed(row, "Title")?.GetComponent<Text>();
            if (title != null)
            {
                string rewardName = string.IsNullOrEmpty(value.Reward.Name) ? $"奖励#{value.Reward.Type}" : value.Reward.Name;
                title.text = $"在线 {value.CumulativeMinutes} 分钟  ·  {rewardName}×{value.Reward.Amount}";
                title.fontSize = 24;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
                RectTransform rect = title.rectTransform;
                rect.anchorMin = new Vector2(0.08f, 0.08f);
                rect.anchorMax = new Vector2(0.72f, 0.92f);
                rect.offsetMin = rect.offsetMax = Vector2.zero;
            }
            SetNamedText(row, "Text", value.State == WelfareRewardState.Claimed ? "已领取" : value.State == WelfareRewardState.Claimable ? "可领取" : "等待中");
            foreach (Text text in row.GetComponentsInChildren<Text>(true))
                if (text.gameObject.name == "Num") text.text = value.Reward.Amount.ToString();
            Image icon = FindNamed(row, "Icon")?.GetComponent<Image>() ?? FindNamed(row, "Item")?.GetComponent<Image>();
            if (icon != null)
            {
                Sprite sprite = value.Reward.Picture > 0 ? resources.LoadItemIcon(value.Reward.Picture) : null;
                icon.sprite = sprite;
                icon.enabled = sprite != null;
                icon.preserveAspect = true;
                if (value.Reward.Picture > 0 && sprite == null) MissingIconCount++;
            }
            Button button = FindNamed(row, "btn_Get")?.GetComponent<Button>();
            if (button != null) button.interactable = false;
            Transform mark = FindNamed(row, "Mark");
            if (mark != null) mark.gameObject.SetActive(value.State == WelfareRewardState.Claimed);
        }

        private void CreateTab(string label, int value, float y)
        {
            var go = new GameObject("WelfareTab" + value, typeof(RectTransform), typeof(Image), typeof(Button));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(welfareView.GameObject.transform, false);
            rect.anchorMin = new Vector2(0.045f, y);
            rect.anchorMax = new Vector2(0.235f, y + 0.09f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = go.GetComponent<Image>();
            image.color = new Color(0.45f, 0.22f, 0.12f, 0.96f);
            go.GetComponent<Button>().onClick.AddListener(() => SelectTab(value));
            Text text = CreateText(rect, "Label", Vector2.zero, Vector2.one, 24, TextAnchor.MiddleCenter);
            text.text = label;
        }

        private static ImodAnimationPlayer CreateSignAnimation(Transform parent)
        {
            var go = new GameObject("SignClaimAnimation", typeof(RectTransform));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(320f, 320f);
            rect.anchoredPosition = new Vector2(180f, -20f);
            ImodAnimationPlayer player = go.AddComponent<ImodAnimationPlayer>();
            if (!player.LoadResource("ProjectXAnimation/res2/fx/qiandao"))
            {
                UnityEngine.Object.Destroy(go);
                return null;
            }
            player.PlayActionRepeat(0);
            return player;
        }

        private static Text CreateText(Transform parent, string name, Vector2 min, Vector2 max, int size, TextAnchor align)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); text.fontSize = size;
            text.alignment = align; text.color = Color.white;
            return text;
        }

        private static void Reparent(CocosUiView view, Transform parent) => view.GameObject.transform.SetParent(parent, false);
        private static void Normalize(GameObject value)
        {
            RectTransform rect = value.GetComponent<RectTransform>();
            if (rect == null) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero;
        }
        private static void Bind(CocosUiView view, string path, Action action)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => action());
        }
        private static GameObject Require(CocosUiView view, string path) => Find(view, path)
            ?? throw new InvalidOperationException("Welfare UI node was not found: " + path);
        private static GameObject Find(CocosUiView view, string path) => view.Binding.Find(path);
        private static Transform FindNamed(Transform root, string name)
        {
            foreach (Transform value in root.GetComponentsInChildren<Transform>(true)) if (value.name == name) return value;
            return null;
        }
        private static void SetNamedText(Transform root, string name, string value)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true)) if (text.gameObject.name == name) text.text = value ?? string.Empty;
        }
    }
}
