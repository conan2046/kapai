using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class TaskPresenter : IDisposable
    {
        private const string BasePath = "Layer/Renwu";
        private readonly TaskStore store;
        private readonly VirtualList<TaskRecord> list;
        private readonly Text emptyText;
        private readonly Action<TaskRecord> claim;

        public TaskPresenter(CocosUiView view, TaskStore store, Action<TaskRecord> claim)
        {
            if (view == null) throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.claim = claim ?? throw new ArgumentNullException(nameof(claim));
            GameObject viewport = Require(view, BasePath + "/Content/ListView");
            GameObject template = Require(view, BasePath + "/Item");
            float itemHeight = Math.Max(130f, template.GetComponent<RectTransform>()?.rect.height ?? 130f);
            list = new VirtualList<TaskRecord>(viewport, template, itemHeight, BindRow);
            emptyText = CreateEmptyText(viewport.transform);
            store.Changed += Render;
            Render();
        }

        public int ItemCount => list.Count;

        public void Render()
        {
            IReadOnlyList<TaskRecord> items = store.Items;
            list.SetItems(items);
            emptyText.gameObject.SetActive(items.Count == 0);
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
            SetText(row, "Panel/Btn/Text", item.State == 1 ? "可领取" : item.State >= 2 ? "已领取" : "进行中");
            SetText(row, "Panel/Btn_0/Text", item.State == 1 ? "领取" : "前往");
            SetVisible(row, "Panel/Get", item.State >= 2);
            SetVisible(row, "Panel/Btn", item.State < 2);
            SetVisible(row, "Panel/Btn_0", false);
            Button button = row.Find("Panel/Btn")?.GetComponent<Button>();
            if (button != null)
            {
                button.onClick.RemoveAllListeners();
                button.interactable = item.State == 1;
                if (item.State == 1) button.onClick.AddListener(() => claim(item));
            }
            row.gameObject.name = $"Task_{item.Id}_{index}";
        }

        private static Text CreateEmptyText(Transform parent)
        {
            var gameObject = new GameObject("EmptyTaskText", typeof(RectTransform), typeof(Text));
            RectTransform rect = gameObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text text = gameObject.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 28;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            text.text = "暂无可显示任务";
            return text;
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

        private static GameObject Require(CocosUiView view, string path)
        {
            GameObject value = view.Binding.Find(path);
            return value ?? throw new InvalidOperationException($"Task UI node was not found: {path}");
        }
    }
}
