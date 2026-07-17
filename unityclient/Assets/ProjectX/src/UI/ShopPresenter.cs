using System;
using System.Collections.Generic;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ShopPresenter : IDisposable
    {
        private const string BasePath = "Layer/ShopUI";
        private readonly CocosUiView view;
        private readonly ShopStore store;
        private readonly CurrencyStore currencies;
        private readonly ResourceService resources;
        private readonly ServerTimeService serverTime;
        private readonly Action<ShopRecord> requestConfirmation;
        private readonly VirtualList<ShopRow> list;
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Text quantity;
        private readonly Text limitLabel;
        private readonly Text limitValue;
        private readonly Text owned;
        private readonly Text expenditure;
        private readonly Image ownedIcon;
        private readonly Image expenditureIcon;
        private readonly Button buyButton;
        private readonly Text refreshText;
        private ushort selectedId;
        private int missingIconCount;
        private uint lastRefreshSecond = uint.MaxValue;

        public ShopPresenter(CocosUiView view, ShopStore store, CurrencyStore currencies,
            ResourceService resources, ServerTimeService serverTime, Action<ShopRecord> requestConfirmation)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.requestConfirmation = requestConfirmation ?? throw new ArgumentNullException(nameof(requestConfirmation));

            GameObject viewport = Require("List");
            GameObject template = Require("Item");
            float itemHeight = Math.Max(150f, template.GetComponent<RectTransform>()?.rect.height ?? 180f);
            list = new VirtualList<ShopRow>(viewport, template, itemHeight, BindRow);
            detailName = RequireText("bg/name");
            detailDescription = RequireText("bg/desc");
            quantity = RequireText("bg/bg_Num/Text");
            limitLabel = RequireText("bg/Image_bg/limitNum/text");
            limitValue = RequireText("bg/Image_bg/limitNum");
            owned = RequireText("bg_Own/Value");
            expenditure = RequireText("bg_Expenditure/Value");
            ownedIcon = Require("bg_Own/Icon").GetComponent<Image>();
            expenditureIcon = Require("bg_Expenditure/Icon").GetComponent<Image>();
            buyButton = Require("btn_Buy").GetComponent<Button>() ?? Require("btn_Buy").AddComponent<Button>();
            Text buyText = RequireText("btn_Buy/Text");
            buyText.gameObject.SetActive(false);
            CreateBuyLabel(buyText.font ?? detailName.font);
            refreshText = CreateRefreshText();
            Require("bg/bg_Num/TextField").SetActive(false);
            Require("bg/bg_Num/TextButton").SetActive(false);
            quantity.gameObject.SetActive(true);
            Require("bg/btn_Minus").SetActive(false);
            Require("bg/btn_Plus").SetActive(false);
            store.Changed += Render;
            currencies.Changed += RenderDetails;
            serverTime.Synchronized += RenderRefreshTime;
            Render();
        }

        public int ItemCount => store.Count;
        public int MissingIconCount => missingIconCount;
        public ushort SelectedId => selectedId;

        public void Tick()
        {
            if (!view.GameObject.activeInHierarchy || !serverTime.IsSynchronized) return;
            uint second = serverTime.UnixSeconds;
            if (second == lastRefreshSecond) return;
            lastRefreshSecond = second;
            RenderRefreshTime();
        }

        public void Render()
        {
            IReadOnlyList<ShopRecord> items = store.Items;
            missingIconCount = 0;
            foreach (ShopRecord item in items)
            {
                bool placeholder = true;
                Sprite sprite = item.Picture > 0 ? resources.LoadItemIcon(item.Picture, out placeholder) : null;
                if (sprite == null || placeholder) missingIconCount++;
            }
            list.SetItems(BuildRows(items));
            if (items.Count == 0)
            {
                selectedId = 0;
                detailName.text = "暂无商品";
                detailDescription.text = "当前商店没有可显示的商品。";
                buyButton.interactable = false;
                return;
            }
            if (!store.TryGet(selectedId, out _)) selectedId = items[0].Id;
            RenderDetails();
            RenderRefreshTime();
        }

        public bool Select(ushort id)
        {
            if (!store.TryGet(id, out _)) return false;
            selectedId = id;
            Render();
            return true;
        }

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= RenderDetails;
            serverTime.Synchronized -= RenderRefreshTime;
            list.Dispose();
        }

        private void BindRow(RectTransform row, ShopRow value, int index)
        {
            BindCell(row, "Item1", value.First, index * 3);
            BindCell(row, "Item2", value.Second, index * 3 + 1);
            BindCell(row, "Item3", value.Third, index * 3 + 2);
        }

        private void BindCell(Transform row, string path, ShopRecord item, int index)
        {
            Transform cell = row.Find(path);
            if (cell == null) return;
            cell.gameObject.SetActive(item != null);
            if (item == null) return;
            SetText(cell, "Name", item.Name);
            SetText(cell, "bg_Price/Value", item.UnitCost.ToString());
            SetText(cell, "Discount/Value", item.DiscountPercent >= 100
                ? string.Empty
                : $"{item.DiscountPercent / 10f:0.#}折");
            SetText(cell, "CostPrice", item.DiscountPercent >= 100 ? string.Empty : $"原价 {item.BaseCost}");
            SetVisible(cell, "Discount", item.DiscountPercent < 100);
            SetVisible(cell, "CostPrice", item.DiscountPercent < 100);
            SetVisible(cell, "Tag", item.IsSoldOut);
            SetVisible(cell, "Choose", item.Id == selectedId);
            Image icon = cell.Find("bg_icon/Icon")?.GetComponent<Image>();
            bool placeholder = true;
            Sprite sprite = item.Picture > 0 ? resources.LoadItemIcon(item.Picture, out placeholder) : null;
            if (icon != null)
            {
                icon.sprite = sprite;
                icon.enabled = sprite != null;
                icon.preserveAspect = true;
            }
            Image costIcon = cell.Find("bg_Price/Icon")?.GetComponent<Image>();
            SetCurrencyIcon(costIcon, item.CostPicture);
            Button button = cell.GetComponent<Button>() ?? cell.gameObject.AddComponent<Button>();
            button.targetGraphic = cell.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => Select(item.Id));
            cell.gameObject.name = $"Shop_{item.Id}_{index}";
        }

        private void RenderDetails()
        {
            if (!store.TryGet(selectedId, out ShopRecord item)) return;
            detailName.text = item.Name;
            detailDescription.text = item.Description;
            quantity.text = "1";
            limitLabel.text = item.Limit < 0 ? "已购次数：" : $"限购 {item.Limit} 次，剩余：";
            limitValue.text = item.Limit < 0 ? $"{item.BuyCount}次" : $"{item.RemainingLimit}次";
            owned.text = currencies.Get(item.CostType).ToString();
            expenditure.text = item.UnitCost.ToString();
            SetCurrencyIcon(ownedIcon, item.CostPicture);
            SetCurrencyIcon(expenditureIcon, item.CostPicture);
            buyButton.interactable = !item.IsSoldOut && currencies.Get(item.CostType) >= item.UnitCost;
            buyButton.onClick.RemoveAllListeners();
            if (!item.IsSoldOut) buyButton.onClick.AddListener(() => requestConfirmation(item));
        }

        private void RenderRefreshTime()
        {
            if (refreshText == null) return;
            TimeSpan remaining;
            string prefix;
            if (store.RefreshDeadlineUnix > 0 && serverTime.IsSynchronized)
            {
                remaining = serverTime.RemainingUntil(store.RefreshDeadlineUnix);
                prefix = store.FreeRefreshTimes > 0 ? $"免费刷新 {store.FreeRefreshTimes} 次" : "下次免费刷新";
            }
            else if (serverTime.IsSynchronized)
            {
                remaining = TimeSpan.FromSeconds(Math.Max(0, 86400 - serverTime.TodaySeconds));
                prefix = "每日刷新";
            }
            else
            {
                refreshText.text = "刷新时间：等待服务器时间";
                return;
            }
            refreshText.text = $"{prefix}  {FormatDuration(remaining)}";
        }

        private Text CreateRefreshText()
        {
            Transform parent = view.GameObject.transform;
            var node = new GameObject("RuntimeShopRefresh", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(parent, false);
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(1f, 1f);
            rect.anchorMax = new Vector2(1f, 1f);
            rect.pivot = new Vector2(1f, 1f);
            rect.anchoredPosition = new Vector2(-110f, -165f);
            rect.sizeDelta = new Vector2(440f, 38f);
            Text value = node.GetComponent<Text>();
            value.font = detailName.font;
            value.fontSize = 19;
            value.color = new Color32(125, 70, 50, 255);
            value.alignment = TextAnchor.MiddleRight;
            value.raycastTarget = false;
            return value;
        }

        private Text CreateBuyLabel(Font font)
        {
            Transform parent = buyButton.transform;
            var node = new GameObject("RuntimeBuyLabel", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(parent, false);
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text value = node.GetComponent<Text>();
            value.text = "购 买";
            value.font = font;
            value.fontSize = 28;
            value.fontStyle = FontStyle.Bold;
            value.color = Color.white;
            value.alignment = TextAnchor.MiddleCenter;
            value.raycastTarget = false;
            return value;
        }

        private void SetCurrencyIcon(Image target, int picture)
        {
            if (target == null) return;
            bool placeholder = true;
            Sprite sprite = picture > 0 ? resources.LoadItemIcon(picture, out placeholder) : null;
            target.sprite = sprite;
            target.enabled = sprite != null;
            target.preserveAspect = true;
        }

        private static IReadOnlyList<ShopRow> BuildRows(IReadOnlyList<ShopRecord> items)
        {
            var rows = new List<ShopRow>((items.Count + 2) / 3);
            for (int index = 0; index < items.Count; index += 3)
                rows.Add(new ShopRow(items[index], index + 1 < items.Count ? items[index + 1] : null,
                    index + 2 < items.Count ? items[index + 2] : null));
            return rows;
        }

        private static string FormatDuration(TimeSpan value)
        {
            int hours = (int)value.TotalHours;
            return $"{hours:00}:{value.Minutes:00}:{value.Seconds:00}";
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

        private Text RequireText(string path)
        {
            Text value = Require(path).GetComponent<Text>();
            return value ?? throw new InvalidOperationException($"Shop UI text was not found: {BasePath}/{path}");
        }

        private GameObject Require(string relativePath)
        {
            string path = string.IsNullOrEmpty(relativePath) ? BasePath : $"{BasePath}/{relativePath}";
            GameObject result = view.Binding.Find(path);
            return result ?? throw new InvalidOperationException($"Shop UI node was not found: {path}");
        }

        private sealed class ShopRow
        {
            public ShopRow(ShopRecord first, ShopRecord second, ShopRecord third)
            {
                First = first;
                Second = second;
                Third = third;
            }
            public ShopRecord First { get; }
            public ShopRecord Second { get; }
            public ShopRecord Third { get; }
        }
    }
}
