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
        private const string BasketRootPath = "Layer/beibao_layer";

        private readonly FishStore store;
        private readonly ResourceService resources;
        private readonly ShopCatalog items;
        private readonly Action start;
        private readonly Action stop;
        private readonly Action<ushort> collect;
        private readonly GameObject sceneRuntime;
        private readonly CocosUiView basketView;
        private readonly CocosUiView oneLevelView;
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
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Image detailIcon;
        private readonly Button startButton;
        private readonly Button collectButton;
        private readonly Image progressFill;
        private readonly FishCountdownDriver countdownDriver;
        private readonly List<GameObject> basketRows = new List<GameObject>();
        private readonly Dictionary<ushort, Button> basketSlotButtons = new Dictionary<ushort, Button>();
        private ushort currentCycleDuration;
        private ushort selectedSlot = ushort.MaxValue;
        private bool moduleVisible;

        public FishPresenter(CocosUiView view, FishStore store, ResourceService resources,
            ShopCatalog items, Action start, Action stop, Action<ushort> collect,
            Action close, Action help)
        {
            if (view == null || view.GameObject == null) throw new ArgumentNullException(nameof(view));
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
            Transform containerParent = gameplayFrame != null ? gameplayFrame.parent : null;
            if (gameplayFrame == null || containerParent == null)
                throw new InvalidOperationException("Fish UI requires the gameplay frame hierarchy.");
            oneLevelView = UiPrefabLoader.Load("OneLevelLayer", containerParent);
            view.GameObject.transform.SetParent(oneLevelView.GameObject.transform, false);
            view.GameObject.transform.SetSiblingIndex(0);
            gameplayFrame.SetParent(oneLevelView.GameObject.transform, false);
            gameplayFrame.SetAsLastSibling();
            basketView = UiPrefabLoader.Load("beibao", view.GameObject.transform);
            basketView.GameObject.name = "FishBasketView";
            Normalize(oneLevelView.GameObject.transform);
            Normalize(basketView.GameObject.transform);
            Hide(oneLevelView, "Layer/Bg");
            Hide(oneLevelView, "Layer/GoldCheck");
            Hide(oneLevelView, "Layer/Panel_12/Bg/Btn_ListView");
            Hide(oneLevelView, "Layer/Panel_12/SubBtnList");
            frameTitle = RequireText(oneLevelView, "Layer/Panel_12/Title/TitleName");
            ConfigureFrameTitle(frameTitle);
            frameHelpButton = Require(oneLevelView, "Layer/Panel_12/Title/TitleName/Button_1");
            oneLevelView.BindClick("Layer/Panel_12/Title/TitleName/Button_1", help, true);
            oneLevelView.BindClick("Layer/Panel_12/Title/CloseBtn", () =>
            {
                if (IsBasketVisible) SetBasketVisible(false); else close();
            }, true);
            basketViewportObject = Require(basketView, BasketRootPath + "/Bag/TableView");
            basketRowTemplate = Require(basketView, BasketRootPath + "/Bag/ItemCell");
            basketRowTemplate.SetActive(false);
            basketContent = ConfigureBasketScroll(basketViewportObject, out basketScroll);
            detailName = RequireText(basketView, BasketRootPath + "/item/Namebg/Name");
            detailDescription = RequireText(basketView, BasketRootPath + "/item/miaoshu/Content");
            detailIcon = Require(basketView, BasketRootPath + "/item/Node/Icon").GetComponent<Image>();
            collectButton = basketView.BindClick(BasketRootPath + "/item/Btn_use", CollectSelected, true);
            RequireText(basketView, BasketRootPath + "/item/Btn_use/Text").text = "收获";
            SetBasketVisible(false);
            SetModuleVisible(false);

            countdownDriver = sceneRuntime.AddComponent<FishCountdownDriver>();
            countdownDriver.Configure(UpdateCountdown);
            store.Changed += Render;
            store.Caught += HandleCaught;
            Render();
        }

        public int RenderedSlotCount => basketSlotButtons.Count;
        public bool IsBasketVisible => basketView.GameObject.activeSelf;
        public ScrollRect BasketScroll => basketScroll;

        public void SetModuleVisible(bool visible)
        {
            moduleVisible = visible;
            if (!visible) basketView.SetVisible(false);
            oneLevelView.SetVisible(true);
            SetVisible(oneLevelView, "Layer/Panel_12", visible);
            SetVisible(oneLevelView, "Layer/Bg", false);
            SetVisible(oneLevelView, "Layer/GoldCheck", false);
            if (!visible) return;
            SetBasketVisible(false);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            store.Caught -= HandleCaught;
            ClearBasketRows();
            UiPrefabLoader.Release(basketView);
            UiPrefabLoader.Release(oneLevelView);
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
            basketView.SetVisible(visible);
            oneLevelView.SetVisible(true);
            SetVisible(oneLevelView, "Layer/Panel_12/BlackBg", visible);
            SetVisible(oneLevelView, "Layer/Panel_12/Bg", visible);
            SetVisible(oneLevelView, "Layer/Panel_12/Title/TitleName/Button_1", !visible);
            if (!moduleVisible) return;
            oneLevelView.GameObject.transform.SetAsLastSibling();
            if (visible) basketView.GameObject.transform.SetAsLastSibling();
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
            int rowCount = Mathf.Max(1, Mathf.CeilToInt(slots.Count / 5f));
            for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
                CreateBasketRow(slots, rowIndex, rowHeight);
            basketContent.sizeDelta = new Vector2(basketContent.sizeDelta.x, rowCount * rowHeight);
            UpdateBasketSelection();
            ShowSelectedDetails(slots);
        }

        private void CreateBasketRow(IReadOnlyList<FishBasketSlot> slots, int rowIndex, float rowHeight)
        {
            GameObject row = UnityEngine.Object.Instantiate(basketRowTemplate, basketContent, false);
            row.name = $"Row_{rowIndex + 1}";
            row.SetActive(true);
            RectTransform rowRect = row.GetComponent<RectTransform>();
            rowRect.anchorMin = rowRect.anchorMax = new Vector2(0f, 1f);
            rowRect.pivot = new Vector2(0f, 1f);
            rowRect.anchoredPosition = new Vector2(0f, -rowIndex * rowHeight);
            basketRows.Add(row);

            for (int column = 0; column < 5; column++)
            {
                Transform slotNode = row.transform.Find($"Item{column + 1}");
                if (slotNode == null) continue;
                int itemIndex = rowIndex * 5 + column;
                bool occupied = itemIndex < slots.Count;
                slotNode.gameObject.SetActive(occupied);
                if (!occupied) continue;

                FishBasketSlot slot = slots[itemIndex];
                RewardRecord item = items.DescribeServerReward(slot.ItemId, 0, slot.Quantity);
                Text name = slotNode.Find("Name")?.GetComponent<Text>();
                if (name != null)
                {
                    name.text = item.Name;
                    name.color = QualityColor(item.Quality);
                }
                ApplyIcon(slotNode.Find("Icon")?.GetComponent<Image>(),
                    item.Picture > 0 ? item.Picture : slot.ItemId);
                ApplyQuality(slotNode, item.Quality);
                AddQuantityLabel(slotNode, slotNode.Find("Icon"), slot.Quantity);
                Button button = ConfigureItemHitArea(slotNode);
                ushort capturedSlot = slot.SlotIndex;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() =>
                {
                    selectedSlot = capturedSlot;
                    UpdateBasketSelection();
                    ShowSelectedDetails(store.Slots);
                });
                basketSlotButtons[slot.SlotIndex] = button;
            }
        }

        private void ShowSelectedDetails(IReadOnlyCollection<FishBasketSlot> slots)
        {
            FishBasketSlot selected = default;
            bool found = false;
            foreach (FishBasketSlot slot in slots)
            {
                if (slot.SlotIndex != selectedSlot) continue;
                selected = slot;
                found = true;
                break;
            }
            if (!found)
            {
                detailName.text = "鱼篓为空";
                detailDescription.text = "暂无鱼类";
                detailIcon.enabled = false;
                collectButton.interactable = false;
                return;
            }
            RewardRecord item = items.DescribeServerReward(selected.ItemId, 0, selected.Quantity);
            detailName.text = item.Name;
            detailName.color = QualityColor(item.Quality);
            detailDescription.text = $"当前格数量：{selected.Quantity}/{store.StackLimit}\n点击收获可取出这一格。";
            ApplyIcon(detailIcon, item.Picture > 0 ? item.Picture : selected.ItemId);
            collectButton.interactable = true;
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

        private void ApplyQuality(Transform slot, int quality)
        {
            Transform icon = slot.Find("Icon");
            if (icon == null) return;
            GameObject qualityObject = new GameObject("RuntimeQuality", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            qualityObject.transform.SetParent(slot, false);
            RectTransform source = icon.GetComponent<RectTransform>();
            RectTransform rect = qualityObject.GetComponent<RectTransform>();
            CopyRect(source, rect);
            Image image = qualityObject.GetComponent<Image>();
            image.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
            image.preserveAspect = true;
            image.raycastTarget = false;
            qualityObject.transform.SetSiblingIndex(icon.GetSiblingIndex());
        }

        private static void AddQuantityLabel(Transform slot, Transform icon, int quantity)
        {
            GameObject labelObject = new GameObject("RuntimeQuantity", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Text), typeof(Outline));
            labelObject.transform.SetParent(slot, false);
            RectTransform source = icon?.GetComponent<RectTransform>();
            if (source != null) CopyRect(source, labelObject.GetComponent<RectTransform>());
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 17;
            label.alignment = TextAnchor.LowerRight;
            label.color = Color.white;
            label.text = quantity.ToString();
            label.raycastTarget = false;
            Outline outline = labelObject.GetComponent<Outline>();
            outline.effectColor = Color.black;
            outline.effectDistance = new Vector2(1f, -1f);
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

        private static void CopyRect(RectTransform source, RectTransform target)
        {
            target.anchorMin = source.anchorMin;
            target.anchorMax = source.anchorMax;
            target.pivot = source.pivot;
            target.anchoredPosition = source.anchoredPosition;
            target.sizeDelta = source.sizeDelta;
            target.localScale = source.localScale;
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
