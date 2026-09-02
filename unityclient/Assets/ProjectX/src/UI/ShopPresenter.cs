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
        private readonly Action<ShopRecord, int> requestConfirmation;
        private readonly VirtualList<ShopRow> list;
        private readonly Dictionary<ushort, Button> cellButtons = new Dictionary<ushort, Button>();
        private readonly ShopQuantityPresenter quantityPresenter;
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
        private readonly Button minusButton;
        private readonly Button plusButton;
        private readonly Button quantityButton;
        private readonly Button baseTabButton;
        private ushort selectedId;
        private int selectedQuantity = 1;
        private int missingIconCount;

        public ShopPresenter(CocosUiView view, ShopStore store, CurrencyStore currencies,
            ResourceService resources, ServerTimeService serverTime, CocosUiView quantityInputSource,
            Action<ShopRecord, int> requestConfirmation, Action requestRefresh)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            if (serverTime == null) throw new ArgumentNullException(nameof(serverTime));
            this.requestConfirmation = requestConfirmation ?? throw new ArgumentNullException(nameof(requestConfirmation));
            if (requestRefresh == null) throw new ArgumentNullException(nameof(requestRefresh));
            quantityPresenter = new ShopQuantityPresenter(quantityInputSource);

            GameObject viewport = Require("List");
            GameObject template = Require("Item");
            float itemHeight = Math.Max(1f, template.GetComponent<RectTransform>()?.rect.height ?? 115f);
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
            buyText.gameObject.SetActive(true);
            buyText.text = "购 买";
            Transform leftTabs = Require("ListView_left").transform;
            foreach (Transform child in leftTabs)
                child.gameObject.SetActive(child.name == "Panel_button");
            Transform baseTabPanel = Require("ListView_left/Panel_button").transform;
            foreach (Transform child in baseTabPanel)
                child.gameObject.SetActive(child.name == "Button_1");
            GameObject baseTab = Require("ListView_left/Panel_button/Button_1");
            baseTabButton = baseTab.GetComponent<Button>() ?? baseTab.AddComponent<Button>();
            Image baseTabImage = baseTab.GetComponent<Image>();
            baseTabButton.targetGraphic = baseTabImage ?? baseTab.GetComponentInChildren<Graphic>(true);
            Sprite selectedTabSprite = baseTabButton.spriteState.disabledSprite;
            if (baseTabImage != null && selectedTabSprite != null)
            {
                baseTabImage.sprite = selectedTabSprite;
                baseTabImage.color = Color.white;
            }
            baseTabButton.transition = Selectable.Transition.None;
            Text baseTabText = baseTab.transform.Find("Text")?.GetComponent<Text>();
            if (baseTabText != null)
            {
                baseTabText.text = "道具购买";
                baseTabText.rectTransform.sizeDelta = new Vector2(112f, baseTabText.rectTransform.sizeDelta.y);
                baseTabText.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            baseTabButton.onClick.RemoveAllListeners();
            baseTabButton.onClick.AddListener(Render);
            baseTabButton.interactable = false;
            Require("bg/bg_Num/TextField").SetActive(false);
            GameObject quantityNode = Require("bg/bg_Num/TextButton");
            quantityNode.SetActive(true);
            foreach (Text legacyLabel in quantityNode.GetComponentsInChildren<Text>(true))
                legacyLabel.gameObject.SetActive(false);
            quantityButton = quantityNode.GetComponent<Button>() ?? quantityNode.AddComponent<Button>();
            quantityButton.targetGraphic = quantityNode.GetComponent<Graphic>()
                ?? quantityNode.GetComponentInChildren<Graphic>(true);
            quantity.gameObject.SetActive(true);
            GameObject minusNode = Require("bg/btn_Minus");
            GameObject plusNode = Require("bg/btn_Plus");
            minusNode.SetActive(true);
            plusNode.SetActive(true);
            minusButton = minusNode.GetComponent<Button>() ?? minusNode.AddComponent<Button>();
            plusButton = plusNode.GetComponent<Button>() ?? plusNode.AddComponent<Button>();
            minusButton.targetGraphic = minusNode.GetComponent<Graphic>();
            plusButton.targetGraphic = plusNode.GetComponent<Graphic>();
            minusButton.onClick.RemoveAllListeners();
            plusButton.onClick.RemoveAllListeners();
            quantityButton.onClick.RemoveAllListeners();
            minusButton.onClick.AddListener(() => AdjustQuantity(-1));
            plusButton.onClick.AddListener(() => AdjustQuantity(1));
            quantityButton.onClick.AddListener(OpenQuantityInput);
            EnsureButtonRaycast(baseTabButton);
            EnsureButtonRaycast(buyButton);
            EnsureButtonRaycast(minusButton);
            EnsureButtonRaycast(plusButton);
            EnsureButtonRaycast(quantityButton);
            store.Changed += Render;
            currencies.Changed += RenderDetails;
            Render();
        }

        public int ItemCount => store.Count;
        public int MissingIconCount => missingIconCount;
        public ushort SelectedId => selectedId;
        public int SelectedQuantity => selectedQuantity;
        public bool IsQuantityInputVisible => quantityPresenter.IsVisible;
        public bool IsRefreshControlHiddenForBaseShop => store.Type == 1
            && view.GameObject.transform.Find("RuntimeShopRefreshButton") == null;
        public bool IsEmptyStateVisible => store.Count == 0 && detailName.text == "暂无商品"
            && !buyButton.interactable;
        public bool HasInteractiveContract
        {
            get
            {
                if (!HasRaycastTarget(buyButton) || !HasRaycastTarget(minusButton)
                    || !HasRaycastTarget(plusButton) || !HasRaycastTarget(quantityButton)) return false;
                foreach (Button button in cellButtons.Values)
                    if (!HasRaycastTarget(button)) return false;
                return true;
            }
        }

        public bool InvokeBaseTab()
        {
            if (baseTabButton == null || baseTabButton.interactable) return false;
            Render();
            return true;
        }

        public bool ScrollToBottom() => list.ScrollToBottom();

        public bool InvokeSelect(ushort id)
        {
            cellButtons.TryGetValue(id, out Button button);
            if (button == null) return false;
            button.onClick.Invoke();
            return selectedId == id;
        }

        public bool InvokeFirstBound(out ushort id)
        {
            foreach (KeyValuePair<ushort, Button> pair in cellButtons)
            {
                id = pair.Key;
                pair.Value.onClick.Invoke();
                return selectedId == id;
            }
            id = 0;
            return false;
        }

        public bool InvokeMinus()
        {
            if (!minusButton.interactable) return false;
            minusButton.onClick.Invoke();
            return true;
        }

        public bool InvokePlus()
        {
            if (!plusButton.interactable) return false;
            plusButton.onClick.Invoke();
            return true;
        }

        public bool InvokeQuantityInput()
        {
            if (!quantityButton.interactable) return false;
            quantityButton.onClick.Invoke();
            return quantityPresenter.IsVisible;
        }

        public bool InvokeQuantityDigit(int digit) => quantityPresenter.InvokeDigit(digit);
        public bool InvokeQuantityDelete() => quantityPresenter.InvokeDelete();
        public bool InvokeQuantityConfirm() => quantityPresenter.InvokeConfirm();
        public bool InvokeQuantityCancel() => quantityPresenter.InvokeClose();

        public bool InvokeBuy()
        {
            if (!buyButton.interactable) return false;
            buyButton.onClick.Invoke();
            return true;
        }

        public void Tick()
        {
        }

        public void Render()
        {
            IReadOnlyList<ShopRecord> items = store.Items;
            cellButtons.Clear();
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
                selectedQuantity = 1;
                quantityPresenter.Hide();
                detailName.text = "暂无商品";
                detailDescription.text = "当前商店没有可显示的商品。";
                quantity.text = "0";
                owned.text = "0";
                expenditure.text = "0";
                buyButton.interactable = false;
                return;
            }
            if (!store.TryGet(selectedId, out _))
            {
                selectedId = items[0].Id;
                selectedQuantity = 1;
            }
            RenderDetails();
        }

        public bool Select(ushort id)
        {
            if (!store.TryGet(id, out _)) return false;
            selectedId = id;
            selectedQuantity = 1;
            Render();
            return true;
        }

        public void ResetTransientState()
        {
            selectedId = 0;
            selectedQuantity = 1;
            quantityPresenter.Hide();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= RenderDetails;
            list.Dispose();
            quantityPresenter.Dispose();
        }

        private void BindRow(RectTransform row, ShopRow value, int index)
        {
            BindCell(row, "Item1", value.First, index * 3);
            BindCell(row, "Item2", value.Second, index * 3 + 1);
            BindCell(row, "Item3", value.Third, index * 3 + 2);
        }

        private void BindCell(Transform row, string path, ShopRecord item, int index)
        {
            Transform cell = FindDescendant(row, path);
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
                RectTransform iconRect = icon.rectTransform;
                iconRect.sizeDelta = new Vector2(64f, 64f);
            }
            Image costIcon = cell.Find("bg_Price/Icon")?.GetComponent<Image>();
            SetCurrencyIcon(costIcon, item.CostPicture);
            Button button = cell.GetComponent<Button>() ?? cell.gameObject.AddComponent<Button>();
            button.targetGraphic = cell.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
            EnsureButtonRaycast(button);
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => Select(item.Id));
            cellButtons[item.Id] = button;
        }

        private static Transform FindDescendant(Transform root, string name)
        {
            Transform direct = root.Find(name);
            if (direct != null) return direct;
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child != root && child.name == name) return child;
            return null;
        }

        private void RenderDetails()
        {
            if (!store.TryGet(selectedId, out ShopRecord item)) return;
            detailName.text = item.Name;
            detailDescription.text = item.Description;
            selectedQuantity = Mathf.Clamp(selectedQuantity, 1, MaximumQuantity(item));
            quantity.text = selectedQuantity.ToString();
            limitLabel.text = item.Limit < 0 ? "已购次数：" : $"限购 {item.Limit} 次，剩余：";
            limitValue.text = item.Limit < 0 ? $"{item.BuyCount}次" : $"{item.RemainingLimit}次";
            owned.text = currencies.Get(item.CostType).ToString();
            long totalCost = item.TotalCost(selectedQuantity);
            expenditure.text = totalCost.ToString();
            SetCurrencyIcon(ownedIcon, item.CostPicture);
            SetCurrencyIcon(expenditureIcon, item.CostPicture);
            bool purchasable = !item.IsSoldOut && selectedQuantity > 0
                && currencies.Get(item.CostType) >= totalCost;
            buyButton.interactable = purchasable;
            minusButton.interactable = selectedQuantity > 1;
            plusButton.interactable = selectedQuantity < MaximumQuantity(item);
            quantityButton.interactable = !item.IsSoldOut;
            buyButton.onClick.RemoveAllListeners();
            if (purchasable)
                buyButton.onClick.AddListener(() => requestConfirmation(item, selectedQuantity));
        }

        private void AdjustQuantity(int delta)
        {
            if (!store.TryGet(selectedId, out ShopRecord item)) return;
            selectedQuantity = Mathf.Clamp(selectedQuantity + delta, 1, MaximumQuantity(item));
            RenderDetails();
        }

        private void OpenQuantityInput()
        {
            if (!store.TryGet(selectedId, out ShopRecord item) || item.IsSoldOut) return;
            quantityPresenter.Show(selectedQuantity, MaximumQuantity(item), value =>
            {
                selectedQuantity = value;
                RenderDetails();
            });
        }

        private static int MaximumQuantity(ShopRecord item)
        {
            int limit = item.RemainingLimit < 0 ? 200 : item.RemainingLimit;
            return Mathf.Max(1, Mathf.Min(200, limit));
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

        private static void EnsureButtonRaycast(Button button)
        {
            if (button?.targetGraphic != null) button.targetGraphic.raycastTarget = true;
        }

        private static bool HasRaycastTarget(Button button) => button != null
            && button.targetGraphic != null && button.targetGraphic.raycastTarget;

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
