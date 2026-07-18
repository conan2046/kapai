using System;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class DrawPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly CocosUiView singleResultView;
        private readonly CocosUiView tenResultView;
        private readonly DrawStore store;
        private readonly ServerTimeService serverTime;
        private readonly Action<byte, byte> draw;
        private readonly Action close;
        private readonly ResourceService resources;
        private readonly Text statusText;
        private readonly Text resultText;
        private readonly Image resultIcon;
        private readonly GameObject furnaceEffect;

        public DrawPresenter(CocosUiView view, CocosUiView singleResultView, CocosUiView tenResultView,
            DrawStore store, ServerTimeService serverTime, ResourceService resources,
            Action<byte, byte> draw, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.singleResultView = singleResultView ?? throw new ArgumentNullException(nameof(singleResultView));
            this.tenResultView = tenResultView ?? throw new ArgumentNullException(nameof(tenResultView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.draw = draw ?? throw new ArgumentNullException(nameof(draw));
            this.close = close ?? throw new ArgumentNullException(nameof(close));

            Reparent(singleResultView, view.GameObject.transform);
            Reparent(tenResultView, view.GameObject.transform);
            Normalize(singleResultView.GameObject);
            Normalize(tenResultView.GameObject);
            singleResultView.GameObject.SetActive(false);
            tenResultView.GameObject.SetActive(false);
            Bind(FindNamed(view.GameObject.transform, "CloseBtn"), close);
            BindDrawButtons();
            statusText = CreateText(view.GameObject.transform, "RuntimeDrawStatus",
                new Vector2(0.25f, 0.08f), new Vector2(0.82f, 0.17f), 22, TextAnchor.MiddleCenter);
            RectTransform resultCard = CreatePanel(singleResultView.GameObject.transform, "RuntimeSingleDrawCard",
                new Vector2(0.37f, 0.25f), new Vector2(0.63f, 0.68f), new Color(0.12f, 0.18f, 0.34f, 0.94f));
            resultIcon = CreateImage(resultCard, "RuntimeSingleDrawIcon",
                new Vector2(0.20f, 0.32f), new Vector2(0.80f, 0.90f));
            resultText = CreateText(resultCard, "RuntimeSingleDrawResult",
                new Vector2(0.05f, 0.02f), new Vector2(0.95f, 0.32f), 25, TextAnchor.MiddleCenter);
            Bind(FindNamed(singleResultView.GameObject.transform, "CloseBtn"), HideResult);
            Bind(FindNamed(singleResultView.GameObject.transform, "ReturnBtn"), HideResult);
            furnaceEffect = CreateFurnaceEffect(view.GameObject.transform);
            store.Changed += Render;
            Render();
        }

        public int PoolCount => store.Count;
        public int ResultCount => store.LastResult?.Rewards.Count ?? 0;
        public bool IsSingleResultVisible => singleResultView.GameObject.activeSelf;
        public bool FurnaceEffectLoaded => furnaceEffect != null;

        public void Tick()
        {
            if (view.GameObject.activeInHierarchy && !IsSingleResultVisible) RenderPools();
        }

        public void Render()
        {
            RenderPools();
            DrawResultRecord result = store.LastResult;
            if (result == null) return;
            bool single = result.DrawType == 1;
            singleResultView.GameObject.SetActive(single);
            tenResultView.GameObject.SetActive(!single);
            if (single)
            {
                DrawRewardRecord reward = result.Rewards.FirstOrDefault();
                resultText.text = reward == null ? "招募成功"
                    : $"招募成功\n{RewardName(reward)} × {reward.Amount}";
                bool placeholder = true;
                Sprite sprite = reward != null && reward.Picture > 0
                    ? resources.LoadItemIcon(reward.Picture, out placeholder) : null;
                resultIcon.sprite = sprite;
                resultIcon.enabled = sprite != null;
                resultIcon.preserveAspect = true;
                CocosTimelinePlayer timeline = singleResultView.GameObject.GetComponent<CocosTimelinePlayer>();
                if (timeline != null && timeline.Duration > 0) timeline.GotoFrameAndPlay(0, false);
            }
        }

        public void Dispose()
        {
            store.Changed -= Render;
        }

        private void BindDrawButtons()
        {
            for (byte kind = 1; kind <= 3; kind++)
            {
                Transform popup = FindNamed(view.GameObject.transform, "Popup" + kind);
                if (popup == null) continue;
                byte captured = kind;
                Bind(FindNamed(popup, "Btn_Recruit_2"), () => draw(captured, 1));
                Bind(FindNamed(popup, "Btn_Recruit_1"), () => draw(captured, 2));
            }
        }

        private void RenderPools()
        {
            uint elapsed = serverTime.IsSynchronized && serverTime.UnixSeconds > store.SnapshotUnixSeconds
                ? serverTime.UnixSeconds - store.SnapshotUnixSeconds : 0;
            foreach (DrawPoolRecord pool in store.Pools)
            {
                Transform popup = FindNamed(view.GameObject.transform, "Popup" + pool.Kind);
                if (popup == null) continue;
                uint cd = pool.FreeCooldownSeconds > elapsed ? pool.FreeCooldownSeconds - elapsed : 0;
                Transform single = FindNamed(popup, "Btn_Recruit_2");
                Transform ten = FindNamed(popup, "Btn_Recruit_1");
                SetButtonLabel(single, pool.FreeTimes > 0 && cd == 0 ? "免费招募" : "招募×1");
                SetButtonLabel(ten, "招募×10");
                SetNamedText(single, "Num", pool.FreeTimes.ToString());
                SetNamedText(single, "Comment", cd == 0 ? "可免费" : $"{cd / 60:00}:{cd % 60:00} 后免费");
                SetNamedVisible(single, "Prompt", pool.FreeTimes > 0 && cd == 0);
            }
            statusText.text = store.Count == 0 ? "等待 /224 op=1 招募信息"
                : string.Join("    ", store.Pools.Select(value =>
                    $"{KindName(value.Kind)}：累计 {value.TotalDraws}，免费 {value.FreeTimes}"));
        }

        private void HideResult()
        {
            singleResultView.GameObject.SetActive(false);
            tenResultView.GameObject.SetActive(false);
            store.ClearResult();
        }

        private static GameObject CreateFurnaceEffect(Transform parent)
        {
            var effect = new GameObject("RuntimeDrawFurnace", typeof(RectTransform));
            RectTransform rect = effect.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(420f, 420f);
            rect.anchoredPosition = new Vector2(-25f, -65f);
            ImodAnimationPlayer player = effect.AddComponent<ImodAnimationPlayer>();
            if (!player.LoadLegacy("res2/fx/choukaluzi"))
            {
                UnityEngine.Object.Destroy(effect);
                return null;
            }
            player.PlayAction(0);
            effect.SetActive(false);
            return effect;
        }

        private static string KindName(byte kind) => kind == 1 ? "基础" : kind == 2 ? "高级" : "友情";
        private static string RewardName(DrawRewardRecord reward)
        {
            if (!string.IsNullOrEmpty(reward.Name)) return reward.Name;
            if (reward.Type == 60002) return reward.TransformItemId == 0 ? $"神将#{reward.Id}" : $"神将碎片#{reward.TransformItemId}";
            if (reward.Type == 60014) return "将魂";
            return reward.Id == 0 ? $"奖励#{reward.Type}" : $"奖励#{reward.Type}/{reward.Id}";
        }

        private static void Reparent(CocosUiView child, Transform parent) => child.GameObject.transform.SetParent(parent, false);
        private static void Normalize(GameObject value)
        {
            RectTransform rect = value.GetComponent<RectTransform>();
            if (rect == null) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static void Bind(Transform target, Action action)
        {
            if (target == null) return;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private static Transform FindNamed(Transform root, string name)
        {
            if (root == null) return null;
            foreach (Transform value in root.GetComponentsInChildren<Transform>(true))
                if (value.name == name) return value;
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            if (root == null) return;
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
                if (text.gameObject.name == name) text.text = value ?? string.Empty;
        }

        private static void SetNamedVisible(Transform root, string name, bool visible)
        {
            Transform target = FindNamed(root, name);
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void SetButtonLabel(Transform button, string value)
        {
            if (button == null) return;
            Transform existing = button.Find("RuntimeDrawLabel");
            Text text = existing == null
                ? CreateText(button, "RuntimeDrawLabel", Vector2.zero, Vector2.one, 22, TextAnchor.MiddleCenter)
                : existing.GetComponent<Text>();
            text.text = value;
            text.color = Color.white;
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
            text.raycastTarget = false;
            return text;
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

        private static Image CreateImage(Transform parent, string name, Vector2 min, Vector2 max)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            return go.GetComponent<Image>();
        }
    }
}
