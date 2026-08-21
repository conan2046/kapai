using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class BagPresenter : IDisposable
    {
        private const string BasePath = "Layer/beibao_layer";
        private readonly CocosUiView view;
        private readonly CocosUiView frameView;
        private readonly BagStore store;
        private readonly Action<BagItemRecord> useAction;
        private readonly Core.ResourceService resources;
        private readonly GameObject viewportObject;
        private readonly GameObject rowTemplate;
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Image detailIcon;
        private readonly Button useButton;
        private readonly Button tabButton;
        private readonly Button detailButton;
        private RectTransform content;
        private int missingIconCount;
        private int tabClickCount;
        private int detailClickCount;
        private readonly Dictionary<int, Button> itemButtons = new Dictionary<int, Button>();
        private readonly Dictionary<int, Transform> itemSlots = new Dictionary<int, Transform>();
        private int selectedSlot;

        public BagPresenter(CocosUiView view, CocosUiView frameView, BagStore store,
            Core.ResourceService resources, Action<BagItemRecord> useAction, Action closeAction)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.frameView = frameView ?? throw new ArgumentNullException(nameof(frameView));
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
            Button close = this.frameView.BindClick("Layer/Panel_12/Title/CloseBtn", closeAction, true);
            tabButton = this.frameView.BindClick("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1",
                () => tabClickCount++, true);
            tabButton.interactable = true;
            SetFrameText("Layer/Panel_12/Title/TitleName", "道具背包");
            SetFrameText("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1/BtnName", "全部");
            SetFrameText("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1/ChooseBg/BtnName", "全部");
            GameObject detailTouch = Require("item/Node/Icon");
            detailButton = detailTouch.GetComponent<Button>() ?? detailTouch.AddComponent<Button>();
            detailButton.onClick.RemoveAllListeners();
            detailButton.onClick.AddListener(() => detailClickCount++);
            ConfigureScrollView();
            store.Changed += Render;
            Render();
        }

        public int ItemCount => store.Items.Count;
        public int MissingIconCount => missingIconCount;
        public int SelectedSlot => selectedSlot;
        public ScrollRect Scroll => viewportObject.GetComponent<ScrollRect>();

        public void ResetSelection()
        {
            selectedSlot = int.MinValue;
            Render();
        }

        public void Render()
        {
            IReadOnlyList<BagItemRecord> items = store.Items;
            ClearRows();
            itemButtons.Clear();
            itemSlots.Clear();
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
            BagItemRecord selected = items.FirstOrDefault(item => item.Slot == selectedSlot);
            if (selected.ItemId <= 0 && items.Count > 0)
                selected = items.FirstOrDefault(item => item.ItemId == 500);
            if (selected.ItemId <= 0 && items.Count > 0) selected = items[0];
            selectedSlot = selected.ItemId > 0 ? selected.Slot : 0;
            UpdateSelectionVisuals();
            ShowDetails(selected, selected.ItemId > 0);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            ClearRows();
        }

        public bool SelectItem(int itemId)
        {
            BagItemRecord item = store.Items.FirstOrDefault(value => value.ItemId == itemId);
            if (item.ItemId <= 0 || !itemButtons.TryGetValue(item.Slot, out Button button)) return false;
            button.onClick.Invoke();
            return true;
        }

        public bool InvokeControl(string controlId)
        {
            switch (controlId)
            {
                case "BAG-02-CLOSE":
                    return Invoke(frameView, "Layer/Panel_12/Title/CloseBtn");
                case "BAG-03-TAB":
                    int tabBefore = tabClickCount;
                    tabButton.onClick.Invoke();
                    return tabClickCount == tabBefore + 1;
                case "BAG-04-LIST-ITEM":
                    foreach (Button button in itemButtons.Values) { button.onClick.Invoke(); return true; }
                    return false;
                case "BAG-05-LIST-SCROLL":
                    if (Scroll == null) return false;
                    Scroll.verticalNormalizedPosition = 0f;
                    Canvas.ForceUpdateCanvases();
                    return true;
                case "BAG-06-DETAIL-ICON":
                    int detailBefore = detailClickCount;
                    detailButton.onClick.Invoke();
                    return detailClickCount == detailBefore + 1;
                case "BAG-07-USE":
                    if (useButton == null || !useButton.gameObject.activeSelf) return false;
                    useButton.onClick.Invoke();
                    return true;
                default:
                    return false;
            }
        }

        public bool Validate(out string detail)
        {
            ScrollRect scroll = Scroll;
            bool structure = scroll != null && scroll.viewport != null && scroll.content == content
                && viewportObject.GetComponent<RectMask2D>() != null && !scroll.horizontal && scroll.vertical;
            bool controls = frameView.Binding.Find("Layer/Panel_12/Title/CloseBtn") != null
                && frameView.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1") != null
                && useButton != null && detailIcon != null && detailButton != null
                && tabButton != null && tabButton.interactable;
            detail = $"items={ItemCount}, buttons={itemButtons.Count}, scroll={structure}, controls={controls}, "
                + $"tabClicks={tabClickCount}, detailClicks={detailClickCount}";
            return structure && controls && itemButtons.Count == ItemCount;
        }

        private void ConfigureScrollView()
        {
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            Image viewportHitArea = viewportObject.GetComponent<Image>() ?? viewportObject.AddComponent<Image>();
            viewportHitArea.color = Color.clear;
            viewportHitArea.raycastTarget = true;
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
                BagItemRecord capturedItem = item;
                Text nameText = slot.Find("Name")?.GetComponent<Text>();
                if (nameText != null)
                {
                    nameText.text = item.Name;
                    nameText.color = QualityColor(item.Quality);
                }
                ApplyQuality(slot, item.Quality);
                ApplyIcon(slot.Find("Icon")?.GetComponent<Image>(), item.Picture);
                AddQuantityLabel(slot, slot.Find("Icon"), item.Quantity);
                Button button = ConfigureItemHitArea(slot);
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() =>
                {
                    selectedSlot = capturedItem.Slot;
                    UpdateSelectionVisuals();
                    ShowDetails(capturedItem, true);
                    Debug.Log($"[BagPresenter] Selected slot={capturedItem.Slot}, itemId={capturedItem.ItemId}, name={capturedItem.Name}.");
                });
                itemButtons[item.Slot] = button;
                itemSlots[item.Slot] = slot;
            }
        }

        private static Button ConfigureItemHitArea(Transform slot)
        {
            foreach (Graphic graphic in slot.GetComponentsInChildren<Graphic>(true))
                graphic.raycastTarget = false;

            Transform existing = slot.Find("RuntimeHitArea");
            GameObject hitObject = existing != null
                ? existing.gameObject
                : new GameObject("RuntimeHitArea", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
            hitObject.transform.SetParent(slot, false);
            hitObject.transform.SetAsLastSibling();
            RectTransform rect = hitObject.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = hitObject.GetComponent<Image>();
            image.color = Color.clear;
            image.raycastTarget = true;
            Button button = hitObject.GetComponent<Button>();
            button.targetGraphic = image;
            button.transition = Selectable.Transition.None;
            button.interactable = true;
            return button;
        }

        private void ApplyQuality(Transform slot, int quality)
        {
            Transform icon = slot.Find("Icon");
            if (icon == null) return;
            Transform existing = slot.Find("RuntimeQuality");
            GameObject qualityObject = existing != null
                ? existing.gameObject
                : new GameObject("RuntimeQuality", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            qualityObject.transform.SetParent(slot, false);
            RectTransform source = icon.GetComponent<RectTransform>();
            RectTransform rect = qualityObject.GetComponent<RectTransform>();
            rect.anchorMin = source.anchorMin;
            rect.anchorMax = source.anchorMax;
            rect.pivot = source.pivot;
            rect.anchoredPosition = source.anchoredPosition;
            rect.sizeDelta = source.sizeDelta;
            rect.localScale = source.localScale;
            Image image = qualityObject.GetComponent<Image>();
            image.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
            image.preserveAspect = true;
            image.raycastTarget = false;
            qualityObject.transform.SetSiblingIndex(icon.GetSiblingIndex());
        }

        private static void AddQuantityLabel(Transform slot, Transform icon, int quantity)
        {
            GameObject labelObject = new GameObject("RuntimeQuantity", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            labelObject.transform.SetParent(slot, false);
            RectTransform rect = labelObject.GetComponent<RectTransform>();
            RectTransform source = icon?.GetComponent<RectTransform>();
            if (source != null)
            {
                rect.anchorMin = source.anchorMin;
                rect.anchorMax = source.anchorMax;
                rect.pivot = source.pivot;
                rect.anchoredPosition = source.anchoredPosition;
                rect.sizeDelta = source.sizeDelta;
                rect.localScale = source.localScale;
            }
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 17;
            label.alignment = TextAnchor.LowerRight;
            label.color = Color.white;
            label.text = quantity.ToString();
            label.raycastTarget = false;
        }

        private void UpdateSelectionVisuals()
        {
            foreach (KeyValuePair<int, Transform> pair in itemSlots)
            {
                Transform choose = pair.Value.Find("Choose");
                if (choose != null) choose.gameObject.SetActive(pair.Key == selectedSlot);
            }
        }

        private void ShowDetails(BagItemRecord item, bool hasItem)
        {
            if (detailName != null)
            {
                detailName.text = hasItem ? item.Name : "背包为空";
                detailName.color = hasItem ? QualityColor(item.Quality) : QualityColor(1);
            }
            if (detailDescription != null)
                detailDescription.text = hasItem
                    ? item.Description
                    : "暂无物品";
            ApplyIcon(detailIcon, hasItem ? item.Picture : 0);
            if (useButton != null)
            {
                bool canUse = hasItem
                    && (item.UseType > 0 || item.UseJump > 0 || item.ItemType == 6)
                    && useAction != null;
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

        private static Color QualityColor(int quality)
        {
            switch (quality)
            {
                case 2: return new Color32(36, 155, 48, 255);
                case 3: return new Color32(35, 98, 174, 255);
                case 4: return new Color32(135, 32, 151, 255);
                case 5: return new Color32(203, 91, 27, 255);
                case 6: return new Color32(190, 35, 35, 255);
                case 7: return new Color32(209, 148, 24, 255);
                default: return new Color32(132, 83, 61, 255);
            }
        }

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            if (result == null) throw new InvalidOperationException($"Bag UI node was not found: {BasePath}/{relativePath}");
            return result;
        }

        private void SetFrameText(string path, string value)
        {
            Text label = frameView.Binding.Find(path)?.GetComponent<Text>();
            if (label != null) label.text = value;
        }

        private static bool Invoke(CocosUiView target, string path)
        {
            GameObject node = target.Binding.Find(path);
            Button button = node == null ? null : node.GetComponent<Button>();
            if (button == null) return false;
            button.onClick.Invoke();
            return true;
        }
    }
}
