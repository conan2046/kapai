using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class TaskPresenter : IDisposable
    {
        private const string BasePath = "Layer/Renwu";
        private readonly CocosUiView view;
        private readonly TaskStore store;
        private readonly ResourceService resources;
        private readonly VirtualList<TaskRecord> list;
        private readonly Text emptyText;
        private readonly Action<TaskRecord> go;
        private readonly Action<TaskRecord> claim;
        private readonly Action<TaskRecord> previewBox;

        public TaskPresenter(CocosUiView view, TaskStore store, ResourceService resources,
            Action<TaskRecord> go, Action<TaskRecord> claim, Action<TaskRecord> previewBox)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.go = go ?? throw new ArgumentNullException(nameof(go));
            this.claim = claim ?? throw new ArgumentNullException(nameof(claim));
            this.previewBox = previewBox ?? throw new ArgumentNullException(nameof(previewBox));
            GameObject viewport = Require(BasePath + "/Content/ListView");
            GameObject template = Require(BasePath + "/Item");
            float itemHeight = Math.Max(130f, template.GetComponent<RectTransform>()?.rect.height ?? 130f);
            list = new VirtualList<TaskRecord>(viewport, template, itemHeight, BindRow);
            emptyText = CreateEmptyText(viewport.transform);
            store.Changed += Render;
            Render();
        }

        public int ItemCount => list.Count;
        public int ActivityBoxCount { get; private set; }
        public bool HasActionLabel(string label) =>
            view.GameObject.GetComponentsInChildren<Text>(true).Any(text => text.text == label);

        public bool ScrollToBottom()
        {
            ScrollRect scroll = view.Binding.Find(BasePath + "/Content/ListView")?.GetComponent<ScrollRect>();
            if (scroll == null) return false;
            scroll.verticalNormalizedPosition = 0f;
            Canvas.ForceUpdateCanvases();
            return true;
        }

        public bool InvokeGo(int jump)
        {
            foreach (TaskRecord item in store.Items)
                if (item.State == 0 && item.Jump == jump) { go(item); return true; }
            return false;
        }

        public bool InvokeFirstDailyClaim(out int id)
        {
            foreach (TaskRecord item in store.Items)
                if (item.State == 1) { id = item.Id; claim(item); return true; }
            id = 0;
            return false;
        }

        public bool InvokeActivityBox(int state, out int id)
        {
            foreach (TaskRecord item in store.ActivityBoxes)
                if (item.State == state) { id = item.Id; previewBox(item); return true; }
            id = 0;
            return false;
        }

        public void Render()
        {
            IReadOnlyList<TaskRecord> items = store.Items;
            list.SetItems(items);
            emptyText.gameObject.SetActive(items.Count == 0);
            RenderActivityBoxes();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            list.Dispose();
        }

        private void BindRow(RectTransform row, TaskRecord item, int index)
        {
            SetText(row, "Panel/TitleBg/Text", item.Title);
            SetText(row, "Panel/Text", item.Description);
            SetText(row, "Panel/Times", $"{Math.Min(item.Progress, (uint)item.Target)}/{item.Target}");
            EnsureButtonLabel(row.Find("Panel/Btn"), "前 往");
            EnsureButtonLabel(row.Find("Panel/Btn_0"), "领 取");
            SetVisible(row, "Panel/Get", item.State >= 2);
            SetVisible(row, "Panel/Btn", item.State == 0 && item.Jump != 0);
            SetVisible(row, "Panel/Btn_0", item.State == 1);
            Bind(row.Find("Panel/Btn"), item.State == 0 && item.Jump != 0 ? () => go(item) : null);
            Bind(row.Find("Panel/Btn_0"), item.State == 1 ? () => claim(item) : null);
            RenderRewards(row.Find("Panel/ListView"), item.Rewards);
            row.gameObject.name = $"Task_{item.Id}_{index}";
        }

        private void RenderActivityBoxes()
        {
            IReadOnlyList<TaskRecord> boxes = store.ActivityBoxes;
            ActivityBoxCount = boxes.Count;
            uint activity = store.ActivityValue;
            SetText(RequireTransform(BasePath + "/Content/TitleBg/LoadingBg/Icon/Value"), activity.ToString());
            Image bar = RequireTransform(BasePath + "/Content/TitleBg/LoadingBg/LoadingBar").GetComponent<Image>();
            if (bar != null)
            {
                bar.type = Image.Type.Filled;
                bar.fillMethod = Image.FillMethod.Horizontal;
                bar.fillAmount = Mathf.Clamp01(activity / 200f);
            }
            for (int index = 0; index < 4; index++)
            {
                Transform panel = RequireTransform($"{BasePath}/Content/TitleBg/LoadingBg/Panel_{index + 1}");
                bool occupied = index < boxes.Count;
                panel.gameObject.SetActive(occupied);
                if (!occupied) continue;
                TaskRecord box = boxes[index];
                SetVisible(panel, "Close", box.State < 2);
                SetVisible(panel, "Open", box.State >= 2);
                SetVisible(panel, "Node", box.State == 1);
                SetText(RequireTransform($"{BasePath}/Content/TitleBg/LoadingBg/Point_{index + 1}/Text"),
                    box.Target.ToString());
                Button button = panel.GetComponent<Button>() ?? panel.gameObject.AddComponent<Button>();
                button.targetGraphic = panel.GetComponent<Graphic>();
                button.onClick.RemoveAllListeners();
                button.interactable = true;
                button.onClick.AddListener(() => previewBox(box));
            }
        }

        private void RenderRewards(Transform host, IReadOnlyList<TaskRewardDefinition> rewards)
        {
            if (host == null) return;
            for (int index = host.childCount - 1; index >= 0; index--)
                if (host.GetChild(index).name.StartsWith("RuntimeReward_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(host.GetChild(index).gameObject);
            int count = Math.Min(3, rewards?.Count ?? 0);
            for (int index = 0; index < count; index++)
            {
                TaskRewardDefinition reward = rewards[index];
                GameObject cell = new GameObject($"RuntimeReward_{index}", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform rect = cell.GetComponent<RectTransform>();
                rect.SetParent(host, false);
                rect.anchorMin = new Vector2(0f, 0.5f);
                rect.anchorMax = new Vector2(0f, 0.5f);
                rect.pivot = new Vector2(0f, 0.5f);
                rect.sizeDelta = new Vector2(64f, 64f);
                rect.anchoredPosition = new Vector2(index * 72f, 0f);
                Image icon = cell.GetComponent<Image>();
                icon.sprite = resources.LoadItemIcon(reward.picture);
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
                Text amount = CreateText(cell.transform, "Amount", 16, TextAnchor.LowerRight);
                amount.text = $"×{reward.amount}";
            }
        }

        private GameObject Require(string path) =>
            view.Binding.Find(path) ?? throw new InvalidOperationException($"Task UI node was not found: {path}");

        private Transform RequireTransform(string path) => Require(path).transform;

        private static void Bind(Transform target, Action action)
        {
            Button button = target?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = action != null;
            if (action != null) button.onClick.AddListener(() => action());
        }

        private static void EnsureButtonLabel(Transform button, string value)
        {
            if (button == null) return;
            Text text = button.Find("Text")?.GetComponent<Text>();
            if (text == null)
                text = CreateText(button, "RuntimeLabel", 26, TextAnchor.MiddleCenter);
            text.text = value;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 26;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = new Color(0.5764706f, 0.25882354f, 0.14117648f, 1f);
            text.raycastTarget = false;
            text.transform.SetAsLastSibling();
        }

        private static Text CreateEmptyText(Transform parent)
        {
            Text text = CreateText(parent, "EmptyTaskText", 28, TextAnchor.MiddleCenter);
            RectTransform rect = text.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            text.text = "暂无可显示任务";
            return text;
        }

        private static Text CreateText(Transform parent, string name, int size, TextAnchor alignment)
        {
            var gameObject = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            gameObject.transform.SetParent(parent, false);
            RectTransform rect = gameObject.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text text = gameObject.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size;
            text.alignment = alignment;
            text.color = Color.white;
            return text;
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetText(Transform target, string value)
        {
            Text text = target?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform root, string path, bool visible)
        {
            Transform target = root.Find(path);
            if (target != null) target.gameObject.SetActive(visible);
        }
    }
}
