using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class BagPresenter : IDisposable
    {
        private const string BasePath = "Layer/beibao_layer";
        private readonly CocosUiView view;
        private readonly BagStore store;
        private readonly Action<BagItemRecord> useAction;
        private readonly Core.ResourceService resources;
        private readonly GameObject viewportObject;
        private readonly GameObject rowTemplate;
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Image detailIcon;
        private readonly Button useButton;
        private RectTransform content;
        private int missingIconCount;

        public BagPresenter(CocosUiView view, BagStore store, Core.ResourceService resources, Action<BagItemRecord> useAction)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.useAction = useAction;
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            viewportObject = Require("Bag/TableView");
            rowTemplate = Require("Bag/ItemCell");
            detailName = Require("item/Namebg/Name").GetComponent<Text>();
            detailDescription = Require("item/miaoshu/Content").GetComponent<Text>();
            detailIcon = Require("item/Node/Icon").GetComponent<Image>();
            useButton = Require("item/Btn_use").GetComponent<Button>();
            Require("item/Btn_use").SetActive(false);
            rowTemplate.SetActive(false);
            ConfigureScrollView();
            store.Changed += Render;
            Render();
        }

        public int ItemCount => store.Count;
        public int MissingIconCount => missingIconCount;

        public void Render()
        {
            IReadOnlyList<BagItemRecord> items = store.Items;
            ClearRows();
            missingIconCount = 0;
            foreach (BagItemRecord item in items)
            {
                bool placeholder = true;
                Sprite sprite = item.Picture > 0 ? resources.LoadItemIcon(item.Picture, out placeholder) : null;
                if (sprite != null && !placeholder) continue;
                missingIconCount++;
                Debug.LogWarning($"[BagPresenter] Missing icon for itemId={item.ItemId}, picture={item.Picture}, name={item.Name}.");
            }
            int rowCount = Mathf.Max(1, Mathf.CeilToInt(items.Count / 5f));
            RectTransform templateRect = rowTemplate.GetComponent<RectTransform>();
            float rowHeight = Mathf.Max(1f, templateRect.rect.height > 0 ? templateRect.rect.height : templateRect.sizeDelta.y);
            for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) CreateRow(rowIndex, rowHeight);
            content.sizeDelta = new Vector2(content.sizeDelta.x, rowCount * rowHeight);
            ShowDetails(items.Count > 0 ? items[0] : default, items.Count > 0);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            ClearRows();
        }

        private void ConfigureScrollView()
        {
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();
            GameObject contentObject = new GameObject("RuntimeBagContent", typeof(RectTransform));
            contentObject.transform.SetParent(viewport, false);
            content = contentObject.GetComponent<RectTransform>();
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 30f;
        }

        private void ClearRows()
        {
            if (content == null) return;
            for (int index = content.childCount - 1; index >= 0; index--)
                UnityEngine.Object.Destroy(content.GetChild(index).gameObject);
        }

        private void CreateRow(int rowIndex, float rowHeight)
        {
            IReadOnlyList<BagItemRecord> items = store.Items;
            GameObject row = UnityEngine.Object.Instantiate(rowTemplate, content, false);
            row.name = $"RuntimeRow{rowIndex + 1}";
            row.SetActive(true);
            RectTransform rowRect = row.GetComponent<RectTransform>();
            rowRect.anchorMin = new Vector2(0f, 1f);
            rowRect.anchorMax = new Vector2(0f, 1f);
            rowRect.pivot = new Vector2(0f, 1f);
            rowRect.anchoredPosition = new Vector2(0f, -rowIndex * rowHeight);

            for (int column = 0; column < 5; column++)
            {
                int itemIndex = rowIndex * 5 + column;
                Transform slot = row.transform.Find($"Item{column + 1}");
                if (slot == null) continue;
                bool occupied = itemIndex < items.Count;
                slot.gameObject.SetActive(occupied);
                if (!occupied) continue;
                BagItemRecord item = items[itemIndex];
                Text nameText = slot.Find("Name")?.GetComponent<Text>();
                if (nameText != null) nameText.text = item.Name;
                ApplyIcon(slot.Find("Icon")?.GetComponent<Image>(), item.Picture);
                AddQuantityLabel(slot, item.Quantity);
                Button button = slot.GetComponent<Button>() ?? slot.gameObject.AddComponent<Button>();
                button.targetGraphic = slot.GetComponent<Graphic>() ?? slot.GetComponentInChildren<Graphic>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => ShowDetails(item, true));
            }
        }

        private static void AddQuantityLabel(Transform slot, int quantity)
        {
            GameObject labelObject = new GameObject("RuntimeQuantity", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            labelObject.transform.SetParent(slot, false);
            RectTransform rect = labelObject.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.45f, 0f);
            rect.anchorMax = new Vector2(1f, 0.35f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 18;
            label.alignment = TextAnchor.LowerRight;
            label.color = Color.white;
            label.text = quantity > 1 ? quantity.ToString() : string.Empty;
        }

        private void ShowDetails(BagItemRecord item, bool hasItem)
        {
            if (detailName != null) detailName.text = hasItem ? item.Name : "背包为空";
            if (detailDescription != null)
                detailDescription.text = hasItem
                    ? $"{item.Description}\n物品ID：{item.ItemId}　数量：{item.Quantity}　格位：{item.Slot}"
                    : "暂无物品";
            ApplyIcon(detailIcon, hasItem ? item.Picture : 0);
            if (useButton != null)
            {
                bool canUse = hasItem && item.UseType > 0 && useAction != null;
                useButton.gameObject.SetActive(canUse);
                useButton.onClick.RemoveAllListeners();
                if (canUse) useButton.onClick.AddListener(() => useAction(item));
            }
        }

        private void ApplyIcon(Image image, int picture)
        {
            if (image == null) return;
            Sprite sprite = picture > 0 ? LoadIcon(picture) : null;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private Sprite LoadIcon(int picture)
        {
            return resources.LoadItemIcon(picture);
        }

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            if (result == null) throw new InvalidOperationException($"Bag UI node was not found: {BasePath}/{relativePath}");
            return result;
        }
    }
}
