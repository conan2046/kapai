using System;
using System.Collections.Generic;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameplayShopsPresenter : IDisposable
    {
        private static readonly byte[] ArenaTypes = { 3, 4 };
        private static readonly byte[] BloodTypes = { 5, 6, 7, 8 };
        private readonly CocosUiView soulView;
        private readonly CocosUiView multiView;
        private readonly GameplayShopStore store;
        private readonly CurrencyStore currencies;
        private readonly ResourceService resources;
        private readonly ServerTimeService serverTime;
        private readonly Action<byte> requestPage;
        private readonly Action close;
        private int functionId = 15;
        private byte selectedType = 2;
        private int renderedCount;
        private int missingIconCount;

        public GameplayShopsPresenter(CocosUiView soulView, CocosUiView multiView,
            GameplayShopStore store, CurrencyStore currencies, ResourceService resources,
            ServerTimeService serverTime, Action<byte> requestPage, Action close)
        {
            this.soulView = soulView ?? throw new ArgumentNullException(nameof(soulView));
            this.multiView = multiView ?? throw new ArgumentNullException(nameof(multiView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.requestPage = requestPage ?? throw new ArgumentNullException(nameof(requestPage));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            Normalize(soulView.GameObject.transform);
            Normalize(multiView.GameObject.transform);
            BuildHeader(soulView.GameObject.transform, "将魂商店");
            BuildHeader(multiView.GameObject.transform, "玩法商店");
            BindSoulRefresh();
            BindMultiTabs();
            DisableOriginalPurchaseButtons(soulView.GameObject.transform);
            DisableOriginalPurchaseButtons(multiView.GameObject.transform);
            store.Changed += Render;
            currencies.Changed += Render;
            serverTime.Synchronized += Render;
        }

        public int FunctionId => functionId;
        public byte SelectedType => selectedType;
        public int RenderedCount => renderedCount;
        public int MissingIconCount => missingIconCount;
        public CocosUiView ActiveView => functionId == 15 ? soulView : multiView;
        public bool IsAuthoritativeVisible => store.TryGet(selectedType, out GameplayShopPage page) && page.Items.Count > 0;

        public void ShowFunction(int id)
        {
            functionId = id;
            selectedType = id == 15 ? (byte)2 : id == 16 ? (byte)3 : (byte)5;
            soulView.SetVisible(id == 15);
            multiView.SetVisible(id != 15);
            Render();
        }

        public void SelectType(byte type, bool requestIfMissing)
        {
            if (!IsAllowedType(type)) return;
            selectedType = type;
            Render();
            if (requestIfMissing && !store.TryGet(type, out _)) requestPage(type);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= Render;
            serverTime.Synchronized -= Render;
        }

        private bool IsAllowedType(byte type)
        {
            if (functionId == 15) return type == 2;
            byte[] allowed = functionId == 16 ? ArenaTypes : BloodTypes;
            return Array.IndexOf(allowed, type) >= 0;
        }

        private void Render()
        {
            renderedCount = 0;
            missingIconCount = 0;
            if (functionId == 15) RenderSoul();
            else RenderMulti();
        }

        private void RenderSoul()
        {
            Transform root = soulView.GameObject.transform;
            GameplayShopPage page = PageOrNull(2);
            SetText(root, "ShopUI/Mine/yuanbao/Value", currencies.Get(CurrencyIds.Premium).ToString());
            SetText(root, "ShopUI/Mine/jianghun/Value", currencies.Get(CurrencyIds.Soul).ToString());
            Transform list = root.Find("ShopUI/jianghunShop/List/Item_1");
            for (int i = 0; i < 6; i++)
            {
                Transform cell = list?.Find($"Item{i + 1}");
                ShopRecord item = page != null && i < page.Items.Count ? page.Items[i] : null;
                BindSoulCell(cell, item);
            }
            ushort refreshTimes = page?.RefreshTimes ?? 0;
            byte freeTimes = page?.FreeRefreshTimes ?? 0;
            SetText(root, "ShopUI/jianghunShop/Panel_1/freetimes/num", $"{freeTimes}/10");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Remaining/num", $"{Math.Max(0, 100 - refreshTimes)}/100");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Consumables/Panel/Value", currencies.Get(400).ToString());
            SetText(root, "ShopUI/jianghunShop/Panel_1/freetimes/cd/Value", FormatRemaining(page));
        }

        private void BindSoulCell(Transform cell, ShopRecord item)
        {
            if (cell == null) return;
            cell.gameObject.SetActive(item != null);
            if (item == null) return;
            renderedCount++;
            SetText(cell, "Name", item.Name);
            SetText(cell, "buy/Value", item.UnitCost.ToString());
            SetText(cell, "Discount/Value", item.DiscountPercent < 100 ? $"{item.DiscountPercent / 10f:0.#}折" : string.Empty);
            SetVisible(cell.Find("Discount"), item.DiscountPercent < 100);
            SetVisible(cell.Find("bg_yigoumai"), item.IsSoldOut);
            SetVisible(cell.Find("buy"), !item.IsSoldOut);
            SetIcon(EnsureRuntimeIcon(cell.Find("bg_icon")), item);
            SetCurrencyIcon(cell.Find("buy/Icon")?.GetComponent<Image>(), item.CostPicture);
        }

        private void RenderMulti()
        {
            Transform root = multiView.GameObject.transform;
            GameplayShopPage page = PageOrNull(selectedType);
            byte[] types = functionId == 16 ? ArenaTypes : BloodTypes;
            string[] names = functionId == 16
                ? new[] { "商品", "奖励" }
                : new[] { "初级装备", "中级装备", "高级装备", "血战奖励" };
            for (int i = 0; i < 5; i++)
            {
                Transform tab = root.Find($"ShopUI/Panel_yeqian_1/yeqian{i + 1}");
                bool visible = i < types.Length;
                SetVisible(tab, visible);
                if (!visible || tab == null) continue;
                SetText(tab, "Text", names[i]);
                SetVisible(tab.Find("Choose"), types[i] == selectedType);
            }
            RenderRuntimeRows(root.Find("TableView"), root.Find("ItemList_1")?.gameObject, page);
            RenderCurrencySummary(root, page);
        }

        private void RenderRuntimeRows(Transform parent, GameObject template, GameplayShopPage page)
        {
            if (parent == null || template == null) return;
            for (int i = parent.childCount - 1; i >= 0; i--)
                if (parent.GetChild(i).name.StartsWith("GameplayShopRuntimeRow", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(parent.GetChild(i).gameObject);
            template.SetActive(false);
            IReadOnlyList<ShopRecord> items = page?.Items ?? Array.Empty<ShopRecord>();
            int rows = Math.Min(6, (items.Count + 1) / 2);
            for (int rowIndex = 0; rowIndex < rows; rowIndex++)
            {
                GameObject row = UnityEngine.Object.Instantiate(template, parent, false);
                row.name = $"GameplayShopRuntimeRow_{rowIndex}";
                row.SetActive(true);
                if (row.transform is RectTransform rect)
                {
                    rect.anchorMin = new Vector2(0.5f, 1f);
                    rect.anchorMax = new Vector2(0.5f, 1f);
                    rect.pivot = new Vector2(0.5f, 1f);
                    rect.anchoredPosition = new Vector2(0f, -rowIndex * Math.Max(120f, rect.rect.height));
                }
                BindMultiCell(row.transform.Find("Item1"), items, rowIndex * 2);
                BindMultiCell(row.transform.Find("Item2"), items, rowIndex * 2 + 1);
            }
        }

        private void BindMultiCell(Transform cell, IReadOnlyList<ShopRecord> items, int index)
        {
            if (cell == null) return;
            ShopRecord item = index < items.Count ? items[index] : null;
            cell.gameObject.SetActive(item != null);
            if (item == null) return;
            renderedCount++;
            SetText(cell, "Name", item.Name);
            SetText(cell, "huobi_1/Value", item.BaseCost.ToString());
            SetText(cell, "huobi_2/Value", item.UnitCost.ToString());
            SetText(cell, "times", item.Limit < 0 ? "不限购" : item.IsSoldOut ? "已售罄" : $"可购 {item.RemainingLimit} 次");
            SetText(cell, "txt_1", item.Description);
            SetVisible(cell.Find("huobi_2"), item.DiscountPercent < 100);
            SetIcon(cell.Find("Icon")?.GetComponent<Image>(), item);
            SetCurrencyIcon(cell.Find("huobi_1/Icon")?.GetComponent<Image>(), item.CostPicture);
            SetCurrencyIcon(cell.Find("huobi_2/Icon")?.GetComponent<Image>(), item.CostPicture);
            Button buy = cell.Find("Btn_Buy")?.GetComponent<Button>();
            if (buy != null) { buy.onClick.RemoveAllListeners(); buy.interactable = false; }
        }

        private void RenderCurrencySummary(Transform root, GameplayShopPage page)
        {
            var types = new List<int>();
            foreach (ShopRecord item in page?.Items ?? Array.Empty<ShopRecord>())
                if (!types.Contains(item.CostType)) types.Add(item.CostType);
            Transform mine = root.Find("ShopUI/Mine");
            Transform first = mine?.Find("jianghun");
            Transform second = mine?.Find("yuanbao");
            SetVisible(first, types.Count > 0);
            SetVisible(second, types.Count > 1);
            if (types.Count > 0)
            {
                SetText(first, "Value", currencies.Get(types[0]).ToString());
                SetCurrencyIcon(first?.Find("Icon")?.GetComponent<Image>(), FindCostPicture(page, types[0]));
            }
            if (types.Count > 1)
            {
                SetText(second, "Value", currencies.Get(types[1]).ToString());
                SetCurrencyIcon(second?.Find("Icon")?.GetComponent<Image>(), FindCostPicture(page, types[1]));
            }
        }

        private GameplayShopPage PageOrNull(byte type) => store.TryGet(type, out GameplayShopPage page) ? page : null;

        private string FormatRemaining(GameplayShopPage page)
        {
            if (page == null || page.RefreshDeadlineUnix == 0 || !serverTime.IsSynchronized) return "--:--:--";
            uint seconds = page.RefreshDeadlineUnix > serverTime.UnixSeconds
                ? page.RefreshDeadlineUnix - serverTime.UnixSeconds
                : 0;
            return TimeSpan.FromSeconds(seconds).ToString(@"hh\:mm\:ss");
        }

        private int FindCostPicture(GameplayShopPage page, int type)
        {
            if (page == null) return 0;
            foreach (ShopRecord item in page.Items) if (item.CostType == type) return item.CostPicture;
            return 0;
        }

        private void SetIcon(Image image, ShopRecord item)
        {
            if (image == null || item == null) return;
            bool placeholder = true;
            Sprite sprite = item.Picture > 0 ? resources.LoadItemIcon(item.Picture, out placeholder) : null;
            if (sprite == null || placeholder) missingIconCount++;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private static Image EnsureRuntimeIcon(Transform parent)
        {
            if (parent == null) return null;
            const string iconName = "GameplayShopIconRuntime";
            Transform existing = parent.Find(iconName);
            if (existing != null) return existing.GetComponent<Image>();

            var iconObject = new GameObject(iconName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            iconObject.transform.SetParent(parent, false);
            var rect = iconObject.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.1f, 0.1f);
            rect.anchorMax = new Vector2(0.9f, 0.9f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            var image = iconObject.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private void SetCurrencyIcon(Image image, int picture)
        {
            if (image == null || picture <= 0) return;
            bool placeholder;
            Sprite sprite = resources.LoadItemIcon(picture, out placeholder);
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private void BindSoulRefresh()
        {
            Button refresh = soulView.GameObject.transform.Find("ShopUI/jianghunShop/Panel_1/btn_Refresh")?.GetComponent<Button>();
            if (refresh == null) return;
            refresh.onClick.RemoveAllListeners();
            refresh.interactable = false;
        }

        private void BindMultiTabs()
        {
            Transform root = multiView.GameObject.transform;
            for (int i = 0; i < 5; i++)
            {
                int captured = i;
                Transform tab = root.Find($"ShopUI/Panel_yeqian_1/yeqian{i + 1}");
                if (tab == null) continue;
                Button button = tab.GetComponent<Button>() ?? tab.gameObject.AddComponent<Button>();
                button.targetGraphic = tab.GetComponent<Graphic>() ?? tab.GetComponentInChildren<Graphic>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() =>
                {
                    byte[] types = functionId == 16 ? ArenaTypes : BloodTypes;
                    if (captured < types.Length) SelectType(types[captured], true);
                });
            }
        }

        private void BuildHeader(Transform root, string title)
        {
            Transform existing = root.Find("GameplayShopHeaderRuntime");
            if (existing != null) return;
            GameObject header = new GameObject("GameplayShopHeaderRuntime", typeof(RectTransform));
            header.transform.SetParent(root, false);
            RectTransform rect = (RectTransform)header.transform;
            rect.anchorMin = new Vector2(0.5f, 1f);
            rect.anchorMax = new Vector2(0.5f, 1f);
            rect.pivot = new Vector2(0.5f, 1f);
            rect.anchoredPosition = new Vector2(0f, -12f);
            rect.sizeDelta = new Vector2(560f, 62f);
            Text label = CreateText(header.transform, "Title", title, 32, TextAnchor.MiddleCenter);
            Stretch(label.rectTransform);
            Button button = CreateButton(header.transform, "Close", "×");
            RectTransform closeRect = (RectTransform)button.transform;
            closeRect.anchorMin = closeRect.anchorMax = new Vector2(1f, 0.5f);
            closeRect.pivot = new Vector2(1f, 0.5f);
            closeRect.anchoredPosition = new Vector2(360f, 0f);
            closeRect.sizeDelta = new Vector2(72f, 56f);
            button.onClick.AddListener(() => close());
        }

        private static Button CreateButton(Transform parent, string name, string value)
        {
            GameObject go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            Image image = go.GetComponent<Image>(); image.color = new Color(0.25f, 0.12f, 0.05f, 0.9f);
            Button button = go.GetComponent<Button>(); button.targetGraphic = image;
            Text text = CreateText(go.transform, "Text", value, 34, TextAnchor.MiddleCenter); Stretch(text.rectTransform);
            return button;
        }

        private static Text CreateText(Transform parent, string name, string value, int size, TextAnchor anchor)
        {
            GameObject go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            Text text = go.GetComponent<Text>(); text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); text.text = value;
            text.fontSize = size; text.alignment = anchor; text.color = Color.white; text.raycastTarget = false;
            return text;
        }

        private static void Stretch(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static void DisableOriginalPurchaseButtons(Transform root)
        {
            foreach (Button button in root.GetComponentsInChildren<Button>(true))
            {
                string name = button.name.ToLowerInvariant();
                if (name.Contains("buy") || name.Contains("refresh"))
                {
                    button.onClick.RemoveAllListeners();
                    button.interactable = false;
                }
            }
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero; rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity;
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root?.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform target, bool value)
        {
            if (target != null) target.gameObject.SetActive(value);
        }
    }
}
