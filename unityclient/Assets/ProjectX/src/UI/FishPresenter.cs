using System;
using System.Collections.Generic;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FishPresenter : IDisposable
    {
        private const string FishRootPath = "Layer/FishUI";

        private readonly CocosUiView view;
        private readonly FishStore store;
        private readonly ResourceService resources;
        private readonly ShopCatalog items;
        private readonly Action start;
        private readonly Action stop;
        private readonly Action<ushort> collect;
        private readonly GameObject sceneRuntime;
        private readonly OneLevelFrameCoordinator oneLevelFrame;
        private readonly CocosUiView oneLevelView;
        private readonly GameObject basketRoot;
        private readonly GameObject basketViewportObject;
        private readonly GameObject basketRowTemplate;
        private readonly RectTransform basketContent;
        private readonly ScrollRect basketScroll;
        private readonly Text stateText;
        private readonly Text countdownText;
        private readonly Text frameTitle;
        private readonly GameObject frameHelpButton;
        private readonly Text startLabel;
        private readonly Text basketButtonLabel;
        private readonly Button startButton;
        private readonly Button collectButton;
        private readonly Image progressFill;
        private readonly FishCountdownDriver countdownDriver;
        private readonly List<GameObject> basketRows = new List<GameObject>();
        private readonly Dictionary<ushort, Button> basketSlotButtons = new Dictionary<ushort, Button>();
        private ushort currentCycleDuration;
        private ushort selectedSlot = ushort.MaxValue;
        private bool moduleVisible;

        public FishPresenter(CocosUiView view, OneLevelFrameCoordinator oneLevelFrame,
            FishStore store, ResourceService resources,
            ShopCatalog items, Action start, Action stop, Action<ushort> collect,
            Action close, Action help)
        {
            if (view == null || view.GameObject == null) throw new ArgumentNullException(nameof(view));
            if (oneLevelFrame == null || oneLevelFrame.View?.GameObject == null)
                throw new ArgumentNullException(nameof(oneLevelFrame));
            this.view = view;
            this.oneLevelFrame = oneLevelFrame;
            oneLevelView = oneLevelFrame.View;
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.items = items ?? throw new ArgumentNullException(nameof(items));
            this.start = start ?? throw new ArgumentNullException(nameof(start));
            this.stop = stop ?? throw new ArgumentNullException(nameof(stop));
            this.collect = collect ?? throw new ArgumentNullException(nameof(collect));
            if (close == null) throw new ArgumentNullException(nameof(close));
            if (help == null) throw new ArgumentNullException(nameof(help));

            Normalize(view.GameObject.transform);
            Transform fishRoot = Require(view, FishRootPath).transform;
            Hide(view, FishRootPath + "/Panel");
            Hide(view, FishRootPath + "/btn_Locker");
            Hide(view, FishRootPath + "/yulan");

            sceneRuntime = CreateSceneRuntime(fishRoot);

            startButton = view.BindClick(FishRootPath + "/Panel_caozuo/btn_shouqi",
                HandleStartStop, true);
            startLabel = RequireText(view, FishRootPath + "/Panel_caozuo/btn_shouqi/Text");
            startLabel.horizontalOverflow = HorizontalWrapMode.Overflow;
            startLabel.verticalOverflow = VerticalWrapMode.Overflow;
            view.BindClick(FishRootPath + "/Panel_caozuo/btn_yulan", ToggleBasket, true);
            basketButtonLabel = RequireText(view, FishRootPath + "/Panel_caozuo/btn_yulan/Text");
            stateText = RequireText(view, FishRootPath + "/Panel_caozuo/Time/Reset");
            countdownText = RequireText(view, FishRootPath + "/Panel_caozuo/Time/Value");
            progressFill = Require(view, FishRootPath + "/Panel_caozuo/Time/LoadingBar").GetComponent<Image>();
            if (progressFill == null)
                throw new InvalidOperationException("Fish formal loading bar has no Image component.");
            progressFill.type = Image.Type.Filled;
            progressFill.fillMethod = Image.FillMethod.Horizontal;
            progressFill.fillOrigin = 0;

            Transform gameplayFrame = view.GameObject.transform.parent;
            if (gameplayFrame == null || gameplayFrame.parent == null)
                throw new InvalidOperationException("Fish UI requires the gameplay frame hierarchy.");
            view.GameObject.transform.SetParent(oneLevelView.GameObject.transform, false);
            view.GameObject.transform.SetSiblingIndex(0);
            Normalize(oneLevelView.GameObject.transform);
            frameTitle = RequireText(oneLevelView, "Layer/Panel_12/Title/TitleName");
            ConfigureFrameTitle(frameTitle);
            frameHelpButton = Require(oneLevelView, "Layer/Panel_12/Title/TitleName/Button_1");
            oneLevelView.BindClick("Layer/Panel_12/Title/TitleName/Button_1", help, true);
            oneLevelView.BindClick("Layer/Panel_12/Title/CloseBtn", () =>
            {
                if (IsBasketVisible) SetBasketVisible(false); else close();
            }, true);
            basketRoot = Require(view, FishRootPath + "/yulan");
            basketViewportObject = Require(view, FishRootPath + "/yulan/ListView");
            basketRowTemplate = Require(view, FishRootPath + "/yulan/Item");
            basketRowTemplate.SetActive(false);
            basketContent = ConfigureBasketScroll(basketViewportObject, out basketScroll);
            view.BindClick(FishRootPath + "/yulan/btn_Close", () => SetBasketVisible(false), true);
            collectButton = view.BindClick(FishRootPath + "/yulan/btn_shouhuo", CollectSelected, true);
            RequireText(view, FishRootPath + "/yulan/btn_shouhuo/Text").text = "收获";
            SetBasketVisible(false);
            SetModuleVisible(false);

            countdownDriver = sceneRuntime.AddComponent<FishCountdownDriver>();
            countdownDriver.Configure(UpdateCountdown);
            store.Changed += Render;
            store.Caught += HandleCaught;
            Render();
        }

        public int RenderedSlotCount => basketSlotButtons.Count;
        public bool IsBasketVisible => basketRoot.activeSelf;
        public bool IsOuterFrameVisible => oneLevelView.Binding.Find("Layer/Panel_12")?.activeSelf == true;
        public ScrollRect BasketScroll => basketScroll;
        public bool HasSourceBasketHierarchy => basketContent != null
            && basketContent.name == "RuntimeFishBasketContent"
            && basketContent.parent == basketViewportObject.transform
            && basketRoot.transform.Find("ListView/RuntimeFishBasketContent") == basketContent
            && view.GameObject.transform.Find("FishBasketView") == null;
        public bool HasRenderableBasketQuantities
        {
            get
            {
                foreach (GameObject row in basketRows)
                {
                    Text value = row?.transform.Find("bg_Icon/Value")?.GetComponent<Text>();
                    if (value == null || value.rectTransform.rect.width <= 0f
                        || value.rectTransform.rect.height <= 0f) return false;
                }
                return basketRows.Count == basketSlotButtons.Count;
            }
        }

        public void SetModuleVisible(bool visible)
        {
            moduleVisible = visible;
            if (!visible)
            {
                basketRoot.SetActive(false);
                oneLevelFrame.Apply(OneLevelFrameMode.Hidden);
                return;
            }
            oneLevelFrame.Apply(OneLevelFrameMode.Fish);
            SetBasketVisible(false);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            store.Caught -= HandleCaught;
            ClearBasketRows();
            if (sceneRuntime != null) UnityEngine.Object.Destroy(sceneRuntime);
        }

        private static GameObject CreateSceneRuntime(Transform fishRoot)
        {
            Transform fishScene = fishRoot.Find("FishScene")
                ?? throw new InvalidOperationException("FishLayer prefab is missing FishUI/FishScene.");
            Transform position = fishScene.Find("pos")
                ?? throw new InvalidOperationException("FishLayer prefab is missing FishUI/FishScene/pos.");
            fishScene.gameObject.SetActive(true);
            RectTransform modelHost = CreateRect("FishingShape2000", position,
                new Vector2(.5f, .5f), new Vector2(.5f, .5f), Vector2.zero, Vector2.zero);
            ImodAnimationPlayer fishingModel = modelHost.gameObject.AddComponent<ImodAnimationPlayer>();
            fishingModel.SetPlayOnEnable(false);
            if (!fishingModel.LoadLegacy("Monster/btm2000_zd"))
                throw new InvalidOperationException("Fishing model is missing: Monster/btm2000_zd (ShapeId=2000).");
            fishingModel.SetFlippedX(true);
            fishingModel.SetVisualScale(.72f);
            fishingModel.Play(2, true);

            return modelHost.gameObject;
        }

        private static void ConfigureFrameTitle(Text title)
        {
            title.alignment = TextAnchor.MiddleLeft;
            title.horizontalOverflow = HorizontalWrapMode.Overflow;
            RectTransform rect = title.rectTransform;
            rect.sizeDelta = new Vector2(300f, rect.sizeDelta.y);
            RectTransform help = title.transform.Find("Button_1")?.GetComponent<RectTransform>();
            if (help != null) help.anchoredPosition = new Vector2(278f, help.anchoredPosition.y);
        }

        private static RectTransform ConfigureBasketScroll(GameObject viewportObject, out ScrollRect scroll)
        {
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            Image hitArea = viewportObject.GetComponent<Image>() ?? viewportObject.AddComponent<Image>();
            hitArea.color = Color.clear;
            hitArea.raycastTarget = true;
            scroll = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();

            GameObject contentObject = new GameObject("RuntimeFishBasketContent", typeof(RectTransform));
            contentObject.transform.SetParent(viewport, false);
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;

            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 30f;
            return content;
        }

        private void HandleStartStop()
        {
            if (!store.HasAuthoritativeState) return;
            if (store.IsFishing) stop(); else start();
        }

        private void ToggleBasket() => SetBasketVisible(!IsBasketVisible);

        private void SetBasketVisible(bool visible)
        {
            visible = moduleVisible && visible;
            basketRoot.SetActive(visible);
            oneLevelFrame.Apply(!moduleVisible
                ? OneLevelFrameMode.Hidden
                : visible ? OneLevelFrameMode.FishBasket : OneLevelFrameMode.Fish);
            SetVisible(oneLevelView, "Layer/Panel_12/Title/TitleName/Button_1", true);
            if (!moduleVisible) return;
            oneLevelView.GameObject.transform.SetAsLastSibling();
            if (visible) basketRoot.transform.SetAsLastSibling();
            RenderHeader();
            Canvas.ForceUpdateCanvases();
        }

        private void HandleCaught(FishCatchRecord record)
        {
            if (record != null && !IsBasketVisible) SetBasketVisible(true);
        }

        private void CollectSelected()
        {
            if (selectedSlot == ushort.MaxValue || !basketSlotButtons.ContainsKey(selectedSlot)) return;
            collect(selectedSlot);
        }

        private void Render()
        {
            if (!store.HasAuthoritativeState)
            {
                RenderHeader();
                stateText.text = "同步中";
                countdownText.text = "--";
                startButton.interactable = false;
                collectButton.interactable = false;
                return;
            }

            RenderHeader();
            stateText.text = store.IsFishing ? "垂钓中" : "准备";
            startLabel.text = store.IsFishing ? "收杆" : "开始";
            basketButtonLabel.text = "鱼篓";
            startButton.interactable = store.IsFishing || store.Gold >= store.GoldCost;
            if (store.IsFishing && store.RemainingSeconds > currentCycleDuration - .5d)
                currentCycleDuration = (ushort)Math.Max(1, Math.Ceiling(store.RemainingSeconds));
            if (!store.IsFishing) currentCycleDuration = 0;
            RebuildBasket();
            UpdateCountdown();
        }

        private void RenderHeader()
        {
            if (frameTitle == null) return;
            frameTitle.text = !store.HasAuthoritativeState
                ? "钓鱼 · 同步中"
                : IsBasketVisible
                    ? $"鱼篓 · {store.OccupiedSlots}/{store.BasketCapacity}格"
                    : $"钓鱼 · {store.GoldCost:N0}金币/次";
            if (frameHelpButton != null) frameHelpButton.SetActive(!IsBasketVisible);
        }

        private void UpdateCountdown()
        {
            if (!store.HasAuthoritativeState || !store.IsFishing)
            {
                countdownText.text = "--";
                progressFill.fillAmount = 0f;
                return;
            }
            double remaining = store.RemainingSeconds;
            countdownText.text = $"{Math.Ceiling(remaining):0}s";
            progressFill.fillAmount = currentCycleDuration > 0
                ? Mathf.Clamp01(1f - (float)(remaining / currentCycleDuration))
                : 0f;
        }

        private void RebuildBasket()
        {
            ClearBasketRows();
            basketSlotButtons.Clear();
            List<FishBasketSlot> slots = new List<FishBasketSlot>(store.Slots);
            if (!ContainsSlot(slots, selectedSlot))
                selectedSlot = slots.Count > 0 ? slots[0].SlotIndex : ushort.MaxValue;

            RectTransform templateRect = basketRowTemplate.GetComponent<RectTransform>();
            float rowHeight = Mathf.Max(1f,
                templateRect.rect.height > 0 ? templateRect.rect.height : templateRect.sizeDelta.y);
            int rowCount = slots.Count;
            for (int rowIndex = 0; rowIndex < slots.Count; rowIndex++)
                CreateBasketRow(slots[rowIndex], rowIndex, rowHeight);
            basketContent.sizeDelta = new Vector2(basketContent.sizeDelta.x, rowCount * rowHeight);
            UpdateBasketSelection();
            collectButton.interactable = selectedSlot != ushort.MaxValue;
        }

        private void CreateBasketRow(FishBasketSlot slot, int rowIndex, float rowHeight)
        {
            GameObject row = UnityEngine.Object.Instantiate(basketRowTemplate, basketContent, false);
            row.name = $"Row_{rowIndex + 1}";
            row.SetActive(true);
            RectTransform rowRect = row.GetComponent<RectTransform>();
            rowRect.anchorMin = rowRect.anchorMax = new Vector2(0f, 1f);
            rowRect.pivot = new Vector2(0f, 1f);
            rowRect.anchoredPosition = new Vector2(0f, -rowIndex * rowHeight);
            basketRows.Add(row);

            RewardRecord item = items.DescribeServerReward(slot.ItemId, 0, slot.Quantity);
            Text name = row.transform.Find("Name")?.GetComponent<Text>();
            if (name != null)
            {
                name.text = item.Name;
                name.color = QualityColor(item.Quality);
            }
            Transform iconRoot = row.transform.Find("bg_Icon");
            ApplyIcon(iconRoot?.Find("Icon")?.GetComponent<Image>(),
                item.Picture > 0 ? item.Picture : slot.ItemId);
            Image qualityFrame = iconRoot?.GetComponent<Image>();
            if (qualityFrame != null) ItemQualityVisual.ApplyFrame(qualityFrame, item.Quality, resources);
            Text quantity = iconRoot?.Find("Value")?.GetComponent<Text>();
            if (quantity != null) quantity.text = slot.Quantity.ToString();
            Button button = ConfigureItemHitArea(row.transform);
            ushort capturedSlot = slot.SlotIndex;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                selectedSlot = capturedSlot;
                UpdateBasketSelection();
            });
            basketSlotButtons[slot.SlotIndex] = button;
        }

        private void UpdateBasketSelection()
        {
            foreach (KeyValuePair<ushort, Button> pair in basketSlotButtons)
            {
                Transform choose = pair.Value.transform.parent.Find("Choose");
                if (choose != null) choose.gameObject.SetActive(pair.Key == selectedSlot);
            }
        }

        private void ClearBasketRows()
        {
            foreach (GameObject row in basketRows)
                if (row != null) UnityEngine.Object.Destroy(row);
            basketRows.Clear();
        }

        private void ApplyIcon(Image image, int picture)
        {
            if (image == null) return;
            Sprite sprite = picture > 0 ? resources.LoadItemIcon(picture) : null;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            image.raycastTarget = false;
        }

        private static Button ConfigureItemHitArea(Transform slot)
        {
            foreach (Graphic graphic in slot.GetComponentsInChildren<Graphic>(true))
                graphic.raycastTarget = false;
            GameObject hitObject = new GameObject("RuntimeHitArea", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image), typeof(Button));
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
            return button;
        }

        private static bool ContainsSlot(IReadOnlyCollection<FishBasketSlot> slots, ushort slotIndex)
        {
            foreach (FishBasketSlot slot in slots)
                if (slot.SlotIndex == slotIndex) return true;
            return false;
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

        private static Text CloneFormalText(Text template, Transform parent, string name,
            Vector2 anchorMin, Vector2 anchorMax, int size, TextAnchor alignment)
        {
            GameObject clone = UnityEngine.Object.Instantiate(template.gameObject, parent, false);
            clone.name = name;
            RectTransform rect = clone.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            Text text = clone.GetComponent<Text>();
            text.fontSize = size;
            text.alignment = alignment;
            text.raycastTarget = false;
            return text;
        }

        private static RectTransform CreateRect(string name, Transform parent, Vector2 anchorMin,
            Vector2 anchorMax, Vector2 anchoredPosition, Vector2 sizeDelta)
        {
            GameObject value = new GameObject(name, typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = anchoredPosition;
            rect.sizeDelta = sizeDelta;
            return rect;
        }

        private static GameObject Require(CocosUiView view, string path) =>
            view.Binding.Find(path) ?? throw new InvalidOperationException($"Fish UI node was not found: {path}");

        private static Text RequireText(CocosUiView view, string path) =>
            Require(view, path).GetComponent<Text>()
            ?? throw new InvalidOperationException($"Fish UI text was not found: {path}");

        private static void Hide(CocosUiView view, string path) => view.Binding.Find(path)?.SetActive(false);

        private static void SetVisible(CocosUiView view, string path, bool visible) =>
            view.Binding.Find(path)?.SetActive(visible);

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }

    public sealed class FishCountdownDriver : MonoBehaviour
    {
        private Action tick;
        public void Configure(Action value) => tick = value;
        private void Update() => tick?.Invoke();
    }
}
