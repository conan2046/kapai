using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameplayShopsPresenter : IDisposable
    {
        private static readonly byte[] AllTypes = { 2 };
        private static readonly byte[][] Groups =
        {
            new byte[] { 3, 4 },
            new byte[] { 5, 6, 7, 8 },
            new byte[] { 25, 26 },
            new byte[] { 23 },
            new byte[] { 27, 28 }
        };
        private static readonly string[][] GroupNames =
        {
            new[] { "商品", "奖励" },
            new[] { "初级装备", "中级装备", "高级装备", "奖励" },
            new[] { "帮派商店", "圣灵商店" },
            new[] { "昆仑商店" },
            new[] { "积分商店", "元宝商店" }
        };
        private static readonly string[] CategoryNames = { "竞技", "血战", "帮派", "昆仑", "转盘" };

        private readonly CocosUiView soulView;
        private readonly CocosUiView multiView;
        private readonly GameplayShopStore store;
        private readonly CurrencyStore currencies;
        private readonly ShopCatalog catalog;
        private readonly BagStore bag;
        private readonly ResourceService resources;
        private readonly ServerTimeService serverTime;
        private readonly Action<byte> requestPage;
        private readonly Action<byte, ushort, int> purchase;
        private readonly Action requestRefresh;
        private readonly Action<ShopRecord> showDetail;
        private readonly Action showSoulDetail;
        private readonly Action<string> showMessage;
        private readonly Action close;
        private readonly Func<int> getPlayerLevel;
        private readonly GameplayBuyDialog buyDialog;
        private readonly Button[] categoryButtons = new Button[5];
        private ScrollRect multiScroll;
        private RectTransform multiScrollContent;
        private int functionId = 15;
        private byte selectedType = 2;
        private int renderedCount;
        private int missingIconCount;
        private float nextCountdownRenderAt;

        public GameplayShopsPresenter(CocosUiView soulView, CocosUiView multiView,
            GameplayShopStore store, CurrencyStore currencies, ShopCatalog catalog, BagStore bag,
            ResourceService resources,
            ServerTimeService serverTime, Action<byte> requestPage,
            Action<byte, ushort, int> purchase, Action requestRefresh,
            Action<ShopRecord> showDetail, Action showSoulDetail, Action<string> showMessage,
            Action close, Func<int> getPlayerLevel)
        {
            this.soulView = soulView ?? throw new ArgumentNullException(nameof(soulView));
            this.multiView = multiView ?? throw new ArgumentNullException(nameof(multiView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.requestPage = requestPage ?? throw new ArgumentNullException(nameof(requestPage));
            this.purchase = purchase ?? throw new ArgumentNullException(nameof(purchase));
            this.requestRefresh = requestRefresh ?? throw new ArgumentNullException(nameof(requestRefresh));
            this.showDetail = showDetail ?? throw new ArgumentNullException(nameof(showDetail));
            this.showSoulDetail = showSoulDetail ?? throw new ArgumentNullException(nameof(showSoulDetail));
            this.showMessage = showMessage ?? throw new ArgumentNullException(nameof(showMessage));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.getPlayerLevel = getPlayerLevel ?? throw new ArgumentNullException(nameof(getPlayerLevel));
            Normalize(soulView.GameObject.transform);
            Normalize(multiView.GameObject.transform);
            BindSoulControls();
            BindMultiTabs();
            ConfigureMultiScroll(out multiScroll, out multiScrollContent);
            buyDialog = new GameplayBuyDialog(multiView.GameObject.transform, ConfirmDialogPurchase);
            store.Changed += Render;
            currencies.Changed += Render;
            bag.Changed += Render;
            serverTime.Synchronized += Render;
        }

        public int FunctionId => functionId;
        public byte SelectedType => selectedType;
        public int RenderedCount => renderedCount;
        public int MissingIconCount => missingIconCount;
        public CocosUiView ActiveView => selectedType == 2 ? soulView : multiView;
        public bool IsAuthoritativeVisible =>
            store.TryGet(selectedType, out GameplayShopPage page) && page.Items.Count > 0;
        public bool IsBuyDialogVisible => buyDialog.IsVisible;
        public int BuyDialogQuantity => buyDialog.Quantity;
        public int SelectedGroupIndex => GroupIndex(selectedType);

        public void Tick()
        {
            if (selectedType != 2 || !soulView.GameObject.activeInHierarchy
                || Time.unscaledTime < nextCountdownRenderAt) return;
            nextCountdownRenderAt = Time.unscaledTime + 0.25f;
            GameplayShopPage page = PageOrNull(2);
            Transform countdown = soulView.GameObject.transform.Find(
                "ShopUI/jianghunShop/Panel_1/freetimes/cd");
            bool showCountdown = page != null && page.RefreshDeadlineUnix > 0;
            SetVisible(countdown, showCountdown);
            if (showCountdown) SetText(countdown, "Value", FormatRemaining(page));
        }

        public void ShowFunction(int id)
        {
            functionId = id;
            selectedType = id == 15 ? (byte)2 : id == 17 ? (byte)5 : (byte)3;
            soulView.SetVisible(selectedType == 2);
            multiView.SetVisible(selectedType != 2);
            buyDialog.Hide();
            Render();
        }

        public bool SelectType(byte type, bool requestIfMissing)
        {
            if (Array.IndexOf(AllTypes, type) < 0) return false;
            if ((type == 27 || type == 28) && getPlayerLevel() < 99)
            {
                showMessage("99级开启此功能");
                return false;
            }
            selectedType = type;
            if (type != 2) functionId = type >= 5 && type <= 8 ? 17 : 16;
            soulView.SetVisible(type == 2);
            multiView.SetVisible(type != 2);
            buyDialog.Hide();
            Render();
            if (requestIfMissing || !store.TryGet(type, out _)) requestPage(type);
            return true;
        }

        public bool SelectTypeForValidation(byte type)
        {
            if (Array.IndexOf(AllTypes, type) < 0) return false;
            selectedType = type;
            soulView.SetVisible(type == 2);
            multiView.SetVisible(type != 2);
            buyDialog.Hide();
            Render();
            return true;
        }

        public bool InvokeCategory(int index)
        {
            if (index < 0 || index >= Groups.Length) return false;
            categoryButtons[index]?.onClick.Invoke();
            return true;
        }

        public void AttachFrameCategoryButtons(IReadOnlyList<Button> buttons)
        {
            if (buttons == null || buttons.Count != categoryButtons.Length)
                throw new ArgumentException("Gameplay shop frame requires five category buttons.", nameof(buttons));
            for (int index = 0; index < categoryButtons.Length; index++)
            {
                int captured = index;
                categoryButtons[index] = buttons[index];
                categoryButtons[index].onClick.RemoveAllListeners();
                categoryButtons[index].onClick.AddListener(() => SelectType(Groups[captured][0], true));
            }
        }

        public bool InvokeSubTab(int index)
        {
            byte[] types = CurrentGroup();
            if (index < 0 || index >= types.Length) return false;
            return SelectType(types[index], true);
        }

        public bool InvokeFirstDetail()
        {
            GameplayShopPage page = PageOrNull(selectedType);
            ShopRecord item = page?.Items.FirstOrDefault();
            if (item == null) return false;
            showDetail(item);
            return true;
        }

        public bool InvokeFirstBuy()
        {
            GameplayShopPage page = PageOrNull(selectedType);
            ShopRecord item = page?.Items.FirstOrDefault(value => !value.IsSoldOut);
            if (item == null) return false;
            BeginPurchase(item);
            return true;
        }

        public bool InvokeDialogMinus() => buyDialog.InvokeDelta(-1);
        public bool InvokeDialogPlus() => buyDialog.InvokeDelta(1);
        public bool InvokeDialogMinusTen() => buyDialog.InvokeDelta(-10);
        public bool InvokeDialogPlusTen() => buyDialog.InvokeDelta(10);
        public bool InvokeDialogToggleUse() => buyDialog.InvokeToggle();
        public bool InvokeDialogBuy() => buyDialog.InvokeBuy();
        public bool InvokeDialogClose() => buyDialog.InvokeClose();

        public bool ScrollToBottom()
        {
            if (multiScroll == null || multiScroll.content == null
                || multiScroll.content.childCount < 2) return false;
            Canvas.ForceUpdateCanvases();
            multiScroll.verticalNormalizedPosition = 0f;
            Canvas.ForceUpdateCanvases();
            return true;
        }

        public void ResetTransientState()
        {
            buyDialog.Hide();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= Render;
            bag.Changed -= Render;
            serverTime.Synchronized -= Render;
            buyDialog.Dispose();
        }

        private void Render()
        {
            renderedCount = 0;
            missingIconCount = 0;
            if (selectedType == 2) RenderSoul();
            else RenderMulti();
        }

        private void RenderSoul()
        {
            Transform root = soulView.GameObject.transform;
            GameplayShopPage page = PageOrNull(2);
            SetText(root, "ShopUI/Mine/yuanbao/Value", currencies.Get(CurrencyIds.Premium).ToString());
            SetText(root, "ShopUI/Mine/jianghun/Value", currencies.Get(CurrencyIds.Soul).ToString());
            Transform list = root.Find("ShopUI/jianghunShop/List/Item_1");
            for (int index = 0; index < 6; index++)
            {
                Transform cell = list?.Find($"Item{index + 1}");
                ShopRecord item = page != null && index < page.Items.Count ? page.Items[index] : null;
                BindSoulCell(cell, item);
            }
            ushort refreshTimes = page?.RefreshTimes ?? 0;
            byte freeTimes = page?.FreeRefreshTimes ?? 0;
            SetText(root, "ShopUI/jianghunShop/Panel_1/freetimes/text", "免费刷新次数：");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Consumables/text", "拥有刷新令：");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Remaining/text", "今日剩余次数：");
            SetText(root, "ShopUI/jianghunShop/Panel_1/freetimes/num", $"{freeTimes}/10");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Remaining/num", $"{Math.Max(0, 100 - refreshTimes)}/100");
            SetText(root, "ShopUI/jianghunShop/Panel_1/Consumables/Panel/Value", currencies.Get(400).ToString());
            ConfigureSoulFooterText(root, "ShopUI/jianghunShop/Panel_1/freetimes/text");
            ConfigureSoulFooterText(root, "ShopUI/jianghunShop/Panel_1/Consumables/text");
            ConfigureSoulFooterText(root, "ShopUI/jianghunShop/Panel_1/Remaining/text");
            ConfigureSoulFooterText(root, "ShopUI/jianghunShop/Panel_1/Remaining/num", 90f);
            Transform countdown = root.Find("ShopUI/jianghunShop/Panel_1/freetimes/cd");
            bool showCountdown = page != null && page.RefreshDeadlineUnix > 0;
            SetVisible(countdown, showCountdown);
            if (showCountdown) SetText(countdown, "Value", FormatRemaining(page));
            Image refreshToken =
                root.Find("ShopUI/jianghunShop/Panel_1/Consumables/Panel/Icon")?.GetComponent<Image>();
            if (refreshToken != null)
            {
                refreshToken.sprite = resources.LoadFirst("CurrencyIcons/huobi_701");
                refreshToken.enabled = refreshToken.sprite != null;
                refreshToken.preserveAspect = true;
            }
        }

        private static void ConfigureSoulFooterText(Transform root, string path, float minimumWidth = 0f)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
            if (minimumWidth > 0f && text.rectTransform.sizeDelta.x < minimumWidth)
                text.rectTransform.sizeDelta =
                    new Vector2(minimumWidth, text.rectTransform.sizeDelta.y);
        }

        private void BindSoulCell(Transform cell, ShopRecord item)
        {
            if (cell == null) return;
            cell.gameObject.SetActive(item != null);
            if (item == null) return;
            ConfigureSoulCellBackground(cell);
            renderedCount++;
            SetText(cell, "Name", item.Name);
            SetText(cell, "buy/Value", item.UnitCost.ToString());
            SetText(cell, "Discount/Value",
                item.DiscountPercent < 100 ? $"{item.DiscountPercent / 10f:0.#}折" : string.Empty);
            SetVisible(cell.Find("Discount"), item.DiscountPercent < 100);
            SetVisible(cell.Find("bg_yigoumai"), item.IsSoldOut);
            SetVisible(cell.Find("buy"), !item.IsSoldOut);
            Transform iconHost = cell.Find("bg_icon");
            Image icon = BindItemVisual(iconHost, item, true);
            BindButton(iconHost?.gameObject, () => showDetail(item), true);
            SetCurrencyIcon(cell.Find("buy/Icon")?.GetComponent<Image>(), item.CostPicture);
            BindButton(cell.Find("buy")?.gameObject, () => purchase(2, item.Id, 1), !item.IsSoldOut);
        }

        private void RenderMulti()
        {
            Transform root = multiView.GameObject.transform;
            GameplayShopPage page = PageOrNull(selectedType);
            byte[] types = CurrentGroup();
            string[] names = GroupNames[GroupIndex(selectedType)];
            for (int index = 0; index < 5; index++)
            {
                Transform tab = root.Find($"ShopUI/Panel_yeqian_1/yeqian{index + 1}");
                bool visible = index < types.Length;
                SetVisible(tab, visible);
                if (!visible || tab == null) continue;
                SetText(tab, "Text", names[index]);
                Text tabText = tab.Find("Text")?.GetComponent<Text>();
                if (tabText != null) tabText.horizontalOverflow = HorizontalWrapMode.Overflow;
                SetVisible(tab.Find("Choose"), types[index] == selectedType);
            }
            for (int index = 0; index < categoryButtons.Length; index++)
                if (categoryButtons[index] != null)
                {
                    categoryButtons[index].interactable = index != GroupIndex(selectedType);
                    SetVisible(categoryButtons[index].transform.Find("ChooseBg"),
                        index == GroupIndex(selectedType));
                }
            RenderRuntimeRows(multiScrollContent, root.Find("ItemList_1")?.gameObject, page);
            RenderCurrencySummary(root, page);
        }

        private void RenderRuntimeRows(Transform parent, GameObject template, GameplayShopPage page)
        {
            if (parent == null || template == null) return;
            for (int index = parent.childCount - 1; index >= 0; index--)
                if (parent.GetChild(index).name.StartsWith("GameplayShopRuntimeRow", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(parent.GetChild(index).gameObject);
            template.SetActive(false);
            IReadOnlyList<ShopRecord> items = page?.Items ?? Array.Empty<ShopRecord>();
            int rows = Math.Min(20, (items.Count + 1) / 2);
            float rowHeight = Math.Max(120f,
                (template.transform as RectTransform)?.rect.height ?? 120f);
            if (parent is RectTransform content)
                content.sizeDelta = new Vector2(content.sizeDelta.x, rows * rowHeight);
            for (int rowIndex = 0; rowIndex < rows; rowIndex++)
            {
                GameObject row = UnityEngine.Object.Instantiate(template, parent, false);
                row.name = $"GameplayShopRuntimeRow_{rowIndex}";
                row.SetActive(true);
                if (row.transform is RectTransform rect)
                {
                    rect.anchorMin = new Vector2(0f, 1f);
                    rect.anchorMax = new Vector2(0f, 1f);
                    rect.pivot = new Vector2(0f, 1f);
                    rect.anchoredPosition = new Vector2(0f, -rowIndex * rowHeight);
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
            Text nameText = cell.Find("Name")?.GetComponent<Text>();
            if (nameText != null) nameText.alignment = TextAnchor.MiddleLeft;
            SetText(cell, "huobi_1/Value", item.BaseCost.ToString());
            SetText(cell, "huobi_2/Value", item.UnitCost.ToString());
            Transform remaining = cell.Find("txt_1");
            SetVisible(remaining, item.Limit >= 0);
            SetText(remaining, "num", item.IsSoldOut ? "已售罄" : $"{item.RemainingLimit}次");
            SetVisible(cell.Find("txt_2"), false);
            SetVisible(cell.Find("Recommend"), false);
            Transform synthesis = cell.Find("havenum");
            int synthesisCost = catalog.GetSynthesisCost(item.RewardType);
            SetVisible(synthesis, synthesisCost > 0);
            Text synthesisText = synthesis?.GetComponent<Text>();
            if (synthesisText != null && synthesisCost > 0)
            {
                synthesisText.text =
                    $"({bag.GetTotalQuantityByItemId(item.RewardType)}/{synthesisCost})";
                synthesisText.alignment = TextAnchor.MiddleLeft;
                synthesisText.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            SetVisible(cell.Find("huobi_2"), item.DiscountPercent < 100);
            Transform iconHost = cell.Find("Icon");
            BindItemVisual(iconHost, item, false);
            BindButton(iconHost?.gameObject, () => showDetail(item), true);
            SetCurrencyIcon(cell.Find("huobi_1/Icon")?.GetComponent<Image>(), item.CostPicture);
            SetCurrencyIcon(cell.Find("huobi_2/Icon")?.GetComponent<Image>(), item.CostPicture);
            BindButton(cell.Find("Btn_Buy")?.gameObject, () => BeginPurchase(item), !item.IsSoldOut);
        }

        private void BeginPurchase(ShopRecord item)
        {
            if (item == null || item.IsSoldOut) return;
            int remaining = item.RemainingLimit < 0 ? 200 : item.RemainingLimit;
            if (remaining <= 1) purchase(selectedType, item.Id, 1);
            else buyDialog.Show(selectedType, item, remaining);
        }

        private void ConfirmDialogPurchase(byte type, ShopRecord item, int quantity, bool use)
        {
            purchase(type, item.Id, quantity);
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

        private void BindSoulControls()
        {
            Transform root = soulView.GameObject.transform;
            BindButton(root.Find("ShopUI/jianghunShop/Panel_1/btn_Refresh")?.gameObject, requestRefresh, true);
            BindButton(root.Find("ShopUI/Mine/jianghun/add")?.gameObject, showSoulDetail, true);
        }

        private void ConfigureMultiScroll(out ScrollRect scroll, out RectTransform content)
        {
            SetVisible(multiView.GameObject.transform.Find("ItemList_1"), false);
            SetVisible(multiView.GameObject.transform.Find("ItemList_2"), false);
            RectTransform viewport = multiView.GameObject.transform.Find("TableView") as RectTransform;
            if (viewport == null)
                throw new InvalidOperationException("wanfashop/TableView viewport is missing.");
            scroll = viewport.GetComponent<ScrollRect>() ?? viewport.gameObject.AddComponent<ScrollRect>();
            if (viewport.GetComponent<RectMask2D>() == null)
                viewport.gameObject.AddComponent<RectMask2D>();
            Transform existing = viewport.Find("GameplayShopRuntimeContent");
            content = existing as RectTransform;
            if (content == null)
            {
                var node = new GameObject("GameplayShopRuntimeContent", typeof(RectTransform));
                content = node.GetComponent<RectTransform>();
                content.SetParent(viewport, false);
            }
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = new Vector2(0f, viewport.rect.height);
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
        }

        private void BindMultiTabs()
        {
            Transform root = multiView.GameObject.transform;
            for (int index = 0; index < 5; index++)
            {
                int captured = index;
                Transform tab = root.Find($"ShopUI/Panel_yeqian_1/yeqian{index + 1}");
                BindButton(tab?.gameObject, () =>
                {
                    byte[] types = CurrentGroup();
                    if (captured < types.Length) SelectType(types[captured], true);
                }, true);
            }
        }

        private GameplayShopPage PageOrNull(byte type) =>
            store.TryGet(type, out GameplayShopPage page) ? page : null;

        private byte[] CurrentGroup() => Groups[GroupIndex(selectedType)];

        private static int GroupIndex(byte type)
        {
            if (type == 3 || type == 4) return 0;
            if (type >= 5 && type <= 8) return 1;
            if (type == 25 || type == 26) return 2;
            if (type == 23) return 3;
            return 4;
        }

        private string FormatRemaining(GameplayShopPage page)
        {
            if (page == null || page.RefreshDeadlineUnix == 0 || !serverTime.IsSynchronized) return "--:--:--";
            uint seconds = page.RefreshDeadlineUnix > serverTime.UnixSeconds
                ? page.RefreshDeadlineUnix - serverTime.UnixSeconds : 0;
            return TimeSpan.FromSeconds(seconds).ToString(@"hh\:mm\:ss");
        }

        private static int FindCostPicture(GameplayShopPage page, int type)
        {
            if (page == null) return 0;
            foreach (ShopRecord item in page.Items)
                if (item.CostType == type) return item.CostPicture;
            return 0;
        }

        private bool SetIcon(Image image, ShopRecord item)
        {
            if (image == null || item == null) return false;
            bool placeholder = true;
            bool usesItemIcon = false;
            Sprite sprite = item.Picture > 0
                ? resources.LoadGameplayShopIcon(item.Picture, out usesItemIcon, out placeholder)
                : null;
            if (sprite == null || placeholder) missingIconCount++;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            return usesItemIcon;
        }

        private void SetCurrencyIcon(Image image, int picture)
        {
            if (image == null) return;
            bool placeholder = true;
            Sprite sprite = picture > 0 ? resources.LoadItemIcon(picture, out placeholder) : null;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private Image BindItemVisual(Transform host, ShopRecord item, bool preserveHostImage)
        {
            if (host == null || item == null) return null;

            Image quality;
            if (preserveHostImage)
            {
                quality = EnsureRuntimeImage(host, "GameplayShopQualityRuntime",
                    new Vector2(0.04f, 0.04f), new Vector2(0.96f, 0.96f));
            }
            else
            {
                quality = host.GetComponent<Image>() ?? host.gameObject.AddComponent<Image>();
            }
            quality.sprite = resources.LoadFirst(
                $"HeroUI/common_quality_{Mathf.Clamp(item.Quality, 1, 7):00}");
            quality.enabled = quality.sprite != null;
            quality.preserveAspect = true;
            quality.raycastTarget = false;

            Image icon = EnsureRuntimeImage(host, "GameplayShopIconRuntime",
                new Vector2(0.04f, 0.04f), new Vector2(0.96f, 0.96f));
            bool usesItemIcon = SetIcon(icon, item);
            icon.raycastTarget = false;
            icon.transform.SetAsLastSibling();

            Image shard = EnsureRuntimeShard(host);
            bool showShard = catalog.IsShard(item.RewardType) && !usesItemIcon;
            shard.gameObject.SetActive(showShard);
            if (showShard)
            {
                shard.sprite = resources.LoadFirst("ItemDecorations/suipian");
                shard.enabled = shard.sprite != null;
                shard.transform.SetAsLastSibling();
            }

            Text quantity = EnsureRuntimeQuantity(host);
            quantity.text = item.RewardAmount > 0 ? item.RewardAmount.ToString() : string.Empty;
            quantity.gameObject.SetActive(item.RewardAmount > 0);
            quantity.transform.SetAsLastSibling();
            return icon;
        }

        private static void ConfigureSoulCellBackground(Transform cell)
        {
            Image background = cell.GetComponent<Image>();
            if (background != null)
            {
                background.enabled = background.sprite != null;
                background.type = Image.Type.Sliced;
                background.preserveAspect = false;
                background.color = Color.white;
            }
            Button button = cell.GetComponent<Button>();
            if (button != null)
            {
                button.transition = Selectable.Transition.None;
                button.interactable = false;
            }
        }

        private static Image EnsureRuntimeImage(Transform parent, string name,
            Vector2 anchorMin, Vector2 anchorMax)
        {
            Transform existing = parent.Find(name);
            GameObject go = existing != null
                ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            RectTransform rect = (RectTransform)go.transform;
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = go.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private static Image EnsureRuntimeShard(Transform parent)
        {
            Transform existing = parent.Find("GameplayShopShardRuntime");
            GameObject go = existing != null
                ? existing.gameObject
                : new GameObject("GameplayShopShardRuntime",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.transform.SetParent(parent, false);
            RectTransform rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = Vector2.zero;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(15f, 13.9128f);
            rect.sizeDelta = new Vector2(25f, 25f);
            rect.localEulerAngles = new Vector3(0f, 0f, 45.0001f);
            Image image = go.GetComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
            return image;
        }

        private static Text EnsureRuntimeQuantity(Transform parent)
        {
            Transform existing = parent.Find("GameplayShopQuantityRuntime");
            GameObject go = existing != null
                ? existing.gameObject
                : new GameObject("GameplayShopQuantityRuntime",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            RectTransform rect = (RectTransform)go.transform;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(5f, 4f);
            rect.offsetMax = new Vector2(-5f, -4f);
            Text label = go.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 17;
            label.alignment = TextAnchor.LowerRight;
            label.color = Color.white;
            label.raycastTarget = false;
            return label;
        }

        private static void BindButton(GameObject node, Action action, bool interactable)
        {
            if (node == null) return;
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.interactable = interactable;
            if (action != null) button.onClick.AddListener(() => action());
        }

        private static Button CreateButton(Transform parent, string name, string value)
        {
            GameObject go = new GameObject(name,
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            Image image = go.GetComponent<Image>();
            image.color = new Color(0.25f, 0.12f, 0.05f, 0.92f);
            Button button = go.GetComponent<Button>();
            button.targetGraphic = image;
            Text text = CreateText(go.transform, "Text", value, 24, TextAnchor.MiddleCenter);
            Stretch(text.rectTransform);
            return button;
        }

        private static Text CreateText(Transform parent, string name, string value, int size, TextAnchor anchor)
        {
            GameObject go = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            go.transform.SetParent(parent, false);
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.text = value;
            text.fontSize = size;
            text.alignment = anchor;
            text.color = Color.white;
            text.raycastTarget = false;
            return text;
        }

        private static void Stretch(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root?.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform target, bool value)
        {
            if (target != null) target.gameObject.SetActive(value);
        }

        private sealed class GameplayBuyDialog : IDisposable
        {
            private readonly GameObject root;
            private readonly Text title;
            private readonly Text quantityText;
            private readonly Toggle useToggle;
            private readonly Action<byte, ShopRecord, int, bool> accepted;
            private byte type;
            private ShopRecord item;
            private int maximum;
            private int quantity;

            public GameplayBuyDialog(Transform parent, Action<byte, ShopRecord, int, bool> accepted)
            {
                this.accepted = accepted;
                root = new GameObject("GameplayShopBuyDialogRuntime",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                root.transform.SetParent(parent, false);
                RectTransform panel = (RectTransform)root.transform;
                panel.anchorMin = panel.anchorMax = new Vector2(0.5f, 0.5f);
                panel.sizeDelta = new Vector2(520f, 330f);
                root.GetComponent<Image>().color = new Color(0.12f, 0.065f, 0.025f, 0.98f);
                title = CreateText(root.transform, "Title", string.Empty, 28, TextAnchor.MiddleCenter);
                SetRect(title.rectTransform, new Vector2(0f, 115f), new Vector2(440f, 60f));
                quantityText = CreateText(root.transform, "Quantity", "1", 36, TextAnchor.MiddleCenter);
                SetRect(quantityText.rectTransform, new Vector2(0f, 35f), new Vector2(140f, 60f));
                CreateDialogButton("-10", new Vector2(-180f, 35f), () => Change(-10));
                CreateDialogButton("-", new Vector2(-90f, 35f), () => Change(-1));
                CreateDialogButton("+", new Vector2(90f, 35f), () => Change(1));
                CreateDialogButton("+10", new Vector2(180f, 35f), () => Change(10));
                GameObject toggleNode = new GameObject("UseToggle",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Toggle));
                toggleNode.transform.SetParent(root.transform, false);
                SetRect((RectTransform)toggleNode.transform, new Vector2(-95f, -45f), new Vector2(34f, 34f));
                useToggle = toggleNode.GetComponent<Toggle>();
                useToggle.targetGraphic = toggleNode.GetComponent<Image>();
                Text toggleText = CreateText(root.transform, "UseText", "购买后使用", 22, TextAnchor.MiddleLeft);
                SetRect(toggleText.rectTransform, new Vector2(25f, -45f), new Vector2(190f, 42f));
                CreateDialogButton("购买", new Vector2(80f, -120f), Confirm, new Vector2(150f, 56f));
                CreateDialogButton("关闭", new Vector2(-80f, -120f), Hide, new Vector2(150f, 56f));
                root.SetActive(false);
            }

            public bool IsVisible => root != null && root.activeSelf;
            public int Quantity => quantity;

            public void Show(byte valueType, ShopRecord value, int max)
            {
                type = valueType;
                item = value;
                maximum = Mathf.Clamp(max, 1, 200);
                quantity = 1;
                useToggle.isOn = false;
                title.text = $"{value.Name}  可购 {maximum}";
                Render();
                root.SetActive(true);
                root.transform.SetAsLastSibling();
            }

            public void Hide()
            {
                item = null;
                root.SetActive(false);
            }

            public bool InvokeDelta(int delta)
            {
                if (!IsVisible) return false;
                Change(delta);
                return true;
            }

            public bool InvokeToggle()
            {
                if (!IsVisible) return false;
                useToggle.isOn = !useToggle.isOn;
                return true;
            }

            public bool InvokeBuy()
            {
                if (!IsVisible) return false;
                Confirm();
                return true;
            }

            public bool InvokeClose()
            {
                if (!IsVisible) return false;
                Hide();
                return true;
            }

            public void Dispose()
            {
                if (root != null) UnityEngine.Object.Destroy(root);
            }

            private void Change(int delta)
            {
                quantity = Mathf.Clamp(quantity + delta, 1, maximum);
                Render();
            }

            private void Confirm()
            {
                ShopRecord value = item;
                byte valueType = type;
                int valueQuantity = quantity;
                bool use = useToggle.isOn;
                Hide();
                if (value != null) accepted(valueType, value, valueQuantity, use);
            }

            private void Render()
            {
                quantityText.text = quantity.ToString();
            }

            private void CreateDialogButton(string label, Vector2 position, Action callback,
                Vector2? size = null)
            {
                Button button = CreateButton(root.transform, "Button" + label, label);
                SetRect((RectTransform)button.transform, position, size ?? new Vector2(74f, 52f));
                button.onClick.AddListener(() => callback());
            }

            private static void SetRect(RectTransform rect, Vector2 position, Vector2 size)
            {
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = position;
                rect.sizeDelta = size;
            }
        }
    }
}
