using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class RewardPresenter : IDisposable
    {
        private const string BasePath = "Layer/Popup";
        private readonly CocosUiView view;
        private readonly RewardStore store;
        private readonly Text title;
        private readonly Text tips;
        private readonly GameObject[] cells = new GameObject[4];
        private readonly Core.ResourceService resources;

        public RewardPresenter(CocosUiView view, RewardStore store, Core.ResourceService resources)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            title = Require("Title/Title_1").GetComponent<Text>();
            tips = Require("tips").GetComponent<Text>();
            NormalizeItemListLayout();
            for (int index = 0; index < cells.Length; index++)
                cells[index] = Require($"ItemList/itemlayer_{index + 1}");
            BindClose("Btn_close");
            BindClose("btn_lingqu");
            Text confirm = Require("btn_lingqu/Text1").GetComponent<Text>();
            if (confirm != null) confirm.text = "确 定";
            store.Changed += Render;
            Render();
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public int RenderedCount { get; private set; }

        public void Show()
        {
            Render();
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Hide() => view.SetVisible(false);

        public void Render()
        {
            IReadOnlyList<RewardRecord> items = store.Items;
            RenderedCount = Mathf.Min(items.Count, cells.Length);
            if (title != null) title.text = store.Title;
            if (tips != null) tips.text = items.Count > cells.Length ? $"另有 {items.Count - cells.Length} 项奖励已发放" : string.Empty;
            for (int index = 0; index < cells.Length; index++)
            {
                bool occupied = index < items.Count;
                GameObject cell = cells[index];
                cell.SetActive(occupied);
                if (!occupied) continue;
                RewardRecord item = items[index];
                Text name = cell.transform.Find("Name")?.GetComponent<Text>();
                if (name != null) name.text = item.Name;
                Image icon = cell.transform.Find("item")?.GetComponent<Image>();
                ApplyIcon(icon, item.Picture);
                AddOrUpdateAmount(cell.transform, item.Amount);
            }
        }

        public void Dispose()
        {
            store.Changed -= Render;
        }

        private void BindClose(string relativePath)
        {
            GameObject node = Require(relativePath);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(Hide);
        }

        private static void AddOrUpdateAmount(Transform cell, uint amount)
        {
            Transform existing = cell.Find("RuntimeAmount");
            Text label;
            if (existing == null)
            {
                GameObject labelObject = new GameObject("RuntimeAmount", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                labelObject.transform.SetParent(cell, false);
                RectTransform rect = labelObject.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(0.45f, 0.18f);
                rect.anchorMax = new Vector2(0.95f, 0.48f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                label = labelObject.GetComponent<Text>();
                label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                label.fontSize = 18;
                label.alignment = TextAnchor.LowerRight;
                label.color = Color.white;
            }
            else label = existing.GetComponent<Text>();
            label.text = $"×{amount}";
        }

        private void ApplyIcon(Image image, int picture)
        {
            if (image == null) return;
            Sprite sprite = resources.LoadItemIcon(picture);
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private void NormalizeItemListLayout()
        {
            RectTransform list = Require("ItemList").GetComponent<RectTransform>();
            if (list == null) return;
            list.anchorMin = new Vector2(0.5f, 0.5f);
            list.anchorMax = new Vector2(0.5f, 0.5f);
            list.pivot = Vector2.zero;
            list.anchoredPosition = new Vector2(-280f, -70f);
        }

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            return result ?? throw new InvalidOperationException($"Reward UI node was not found: {BasePath}/{relativePath}");
        }
    }
}
