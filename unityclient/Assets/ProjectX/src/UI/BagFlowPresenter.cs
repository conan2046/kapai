using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class BagFlowPresenter : IDisposable
    {
        private sealed class Choice
        {
            public int Id;
            public string Name;
            public string Description;
            public int Picture;
            public int Quality;
            public int ItemType;
            public int Quantity;
            public string ItemFrom;
            public string Sources;
        }

        private readonly CocosUiView inputView;
        private readonly CocosUiView popupFrameView;
        private readonly CocosUiView giftView;
        private readonly CocosUiView sourceView;
        private readonly CocosUiView equipmentInfoView;
        private readonly Core.ResourceService resources;
        private readonly EquipmentCatalog equipmentCatalog;
        private readonly Func<int, int> ownedQuantity;
        private readonly Action<BagItemRecord, int, int> useAction;
        private readonly Action beforeItemJump;
        private readonly Action<int> jumpAction;
        private readonly Func<int, bool> canJump;
        private readonly Action<string> feedback;
        private readonly List<Choice> choices = new List<Choice>();
        private readonly Dictionary<int, Button> giftChoiceButtons = new Dictionary<int, Button>();
        private BagItemRecord activeItem;
        private Choice selectedChoice;
        private Choice sourceChoice;
        private int quantity;
        private int maxQuantity;
        private int inputDigitMask;
        private Text inputDisplay;
        private Text giftQuantity;
        private RectTransform giftContent;
        private GameObject giftTemplate;
        private RectTransform sourceContent;
        private GameObject sourceTemplate;

        public BagFlowPresenter(
            CocosUiView inputView,
            CocosUiView popupFrameView,
            CocosUiView giftView,
            CocosUiView sourceView,
            CocosUiView equipmentInfoView,
            Core.ResourceService resources,
            EquipmentCatalog equipmentCatalog,
            Func<int, int> ownedQuantity,
            Action<BagItemRecord, int, int> useAction,
            Action beforeItemJump,
            Action<int> jumpAction,
            Func<int, bool> canJump,
            Action<string> feedback)
        {
            this.inputView = inputView ?? throw new ArgumentNullException(nameof(inputView));
            this.popupFrameView = popupFrameView ?? throw new ArgumentNullException(nameof(popupFrameView));
            this.giftView = giftView ?? throw new ArgumentNullException(nameof(giftView));
            this.sourceView = sourceView ?? throw new ArgumentNullException(nameof(sourceView));
            this.equipmentInfoView = equipmentInfoView ?? throw new ArgumentNullException(nameof(equipmentInfoView));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.equipmentCatalog = equipmentCatalog ?? throw new ArgumentNullException(nameof(equipmentCatalog));
            this.ownedQuantity = ownedQuantity ?? throw new ArgumentNullException(nameof(ownedQuantity));
            this.useAction = useAction ?? throw new ArgumentNullException(nameof(useAction));
            this.beforeItemJump = beforeItemJump ?? throw new ArgumentNullException(nameof(beforeItemJump));
            this.jumpAction = jumpAction ?? throw new ArgumentNullException(nameof(jumpAction));
            this.canJump = canJump ?? (_ => false);
            this.feedback = feedback ?? (_ => { });
            ConfigureInput();
            ConfigureGift();
            ConfigureSource();
            ConfigureEquipmentInfo();
            CloseAll();
        }

        public bool IsInputOpen => inputView.GameObject.activeSelf;
        public bool IsGiftOpen => giftView.GameObject.activeSelf;
        public bool IsSourceOpen => sourceView.GameObject.activeSelf;
        public bool IsEquipmentInfoOpen => equipmentInfoView.GameObject.activeSelf;
        public int Quantity => quantity;
        public string InputDisplayText => inputDisplay == null ? string.Empty : inputDisplay.text;
        public int ChoiceCount => choices.Count;
        public bool HasSelection => selectedChoice != null;
        public int SelectedChoiceId => selectedChoice?.Id ?? 0;
        public int SourceChoiceId => sourceChoice?.Id ?? 0;
        public Button GetInputDigitControl(int digit) => digit >= 0 && digit <= 9
            ? inputView.Binding.Find($"Layer/Panel/Bg/BtnList/Btn{digit}")?.GetComponent<Button>()
            : null;
        public Button InputConfirmControl =>
            inputView.Binding.Find("Layer/Panel/Bg/BtnList/Btn12")?.GetComponent<Button>();

        public bool SelectGiftChoice(int index)
        {
            if (!giftChoiceButtons.TryGetValue(index, out Button button)) return false;
            button.onClick.Invoke();
            return true;
        }

        public void ResetGiftScroll()
        {
            ScrollRect scroll = Require(giftView, "Layer/OpenBox/Panel/Bg/ListView").GetComponent<ScrollRect>();
            if (scroll == null || scroll.content == null) return;
            Canvas.ForceUpdateCanvases();
            LayoutRebuilder.ForceRebuildLayoutImmediate(scroll.content);
            scroll.horizontalNormalizedPosition = 0f;
        }

        public void Dispose()
        {
            ClearChildren(giftContent);
            ClearChildren(sourceContent);
            CloseAll();
        }

        public void ShowUseFlow(BagItemRecord item)
        {
            activeItem = item;
            if (item.ItemType == 6)
            {
                ShowGift(item);
                return;
            }
            if (item.UseType > 0)
            {
                if (item.Quantity > 1 && item.UseType == 2)
                    ShowInput(item);
                else
                    useAction(item, 1, 0);
                return;
            }
            if (item.UseJump > 0)
            {
                beforeItemJump();
                jumpAction(item.UseJump);
                return;
            }
            feedback("当前道具不可使用");
        }

        public void ShowMailAttachment(RewardRecord item)
        {
            choices.Clear();
            var choice = new Choice
            {
                Id = checked((int)item.Id),
                Name = item.Name,
                Description = "邮件附件奖励",
                Picture = item.Picture,
                Quality = item.Quality,
                Quantity = checked((int)item.Amount),
                ItemFrom = "来源：系统邮件",
                Sources = string.Empty,
            };
            sourceChoice = choice;
            popupFrameView.SetVisible(false);
            giftView.SetVisible(false);
            sourceView.SetVisible(true);
            sourceView.GameObject.transform.SetAsLastSibling();
            SetText(sourceView, "Layer/Popup/Panel_name/txt_name", choice.Name);
            SetText(sourceView, "Layer/Popup/Panel_name/txt_num", $"数量：{choice.Quantity}");
            SetText(sourceView, "Layer/Popup/Panel_name/txt_tips", choice.Description);
            SetImage(sourceView, "Layer/Popup/Panel_name/Panel_icon/Icon", resources.LoadItemIcon(choice.Picture));
            ClearChildren(sourceContent);
            GameObject row = UnityEngine.Object.Instantiate(sourceTemplate, sourceContent, false);
            row.name = "RuntimeMailSource";
            row.SetActive(true);
            SetRowText(row, "Name_1", choice.ItemFrom);
            SetRowText(row, "Name_2", string.Empty);
            SetRowText(row, "times", string.Empty);
            SetRowActive(row, "Button_1", false);
            SetRowActive(row, "Button_2", false);
            SetRowActive(row, "Button_3", false);
            SetRowActive(row, "item_icon", false);
        }

        public void CloseAll()
        {
            inputView.SetVisible(false);
            giftView.SetVisible(false);
            popupFrameView.SetVisible(false);
            sourceView.SetVisible(false);
            equipmentInfoView.SetVisible(false);
            selectedChoice = null;
            sourceChoice = null;
            quantity = 0;
            maxQuantity = 0;
        }

        public bool InvokeControl(string controlId)
        {
            switch (controlId)
            {
                case "BAG-08-INPUT-DIGITS":
                    for (int digit = 0; digit <= 9; digit++)
                        if (!Invoke(inputView, $"Layer/Panel/Bg/BtnList/Btn{digit}")) return false;
                    bool allDigitsInvoked = inputDigitMask == 0x3ff;
                    quantity = 0;
                    RenderQuantity();
                    bool enteredTen = Invoke(inputView, "Layer/Panel/Bg/BtnList/Btn1")
                        && Invoke(inputView, "Layer/Panel/Bg/BtnList/Btn0");
                    return allDigitsInvoked && enteredTen && quantity == Mathf.Min(10, maxQuantity);
                case "BAG-09-INPUT-DELETE": return Invoke(inputView, "Layer/Panel/Bg/BtnList/Btn10");
                case "BAG-10-INPUT-CONFIRM": return Invoke(inputView, "Layer/Panel/Bg/BtnList/Btn12");
                case "BAG-11-INPUT-CLOSE": return Invoke(inputView, "Layer/Panel/Bg/Close");
                case "BAG-12-GIFT-OPTION":
                    if (giftChoiceButtons.Count == 0) return false;
                    giftChoiceButtons[giftChoiceButtons.Keys.Min()].onClick.Invoke();
                    return true;
                case "BAG-13-GIFT-SCROLL": return ScrollToEnd(giftView, "Layer/OpenBox/Panel/Bg/ListView");
                case "BAG-14-GIFT-SUB-ONE": return Invoke(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L");
                case "BAG-15-GIFT-ADD-ONE": return Invoke(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R");
                case "BAG-16-GIFT-SUB-TEN": return Invoke(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L_0");
                case "BAG-17-GIFT-ADD-TEN": return Invoke(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R_0");
                case "BAG-18-GIFT-CONFIRM": return Invoke(giftView, "Layer/OpenBox/Panel/Button");
                case "BAG-19-GIFT-CLOSE": return Invoke(popupFrameView, "Layer/shopBg/Popup/Btn_close");
                case "BAG-20-GIFT-REWARD-DETAIL":
                    int selectedIndex = selectedChoice == null ? -1 : choices.IndexOf(selectedChoice);
                    IEnumerable<Button> detailButtons = selectedIndex >= 0
                        && giftChoiceButtons.TryGetValue(selectedIndex, out Button selectedButton)
                        ? new[] { selectedButton }
                        : giftChoiceButtons.Values;
                    foreach (Button button in detailButtons)
                    {
                        Transform icon = FindDescendant(button.transform, "IconBg");
                        Button detail = icon?.GetComponent<Button>();
                        if (detail == null) continue;
                        detail.onClick.Invoke();
                        return true;
                    }
                    return false;
                case "BAG-21-SOURCE-CLOSE": return Invoke(sourceView, "Layer/Popup/Title/Btn_close");
                case "BAG-22-SOURCE-ICON": return Invoke(sourceView, "Layer/Popup/Panel_name/Panel_icon");
                case "BAG-23-SOURCE-SCROLL": return ScrollToEnd(sourceView, "Layer/Popup/ListView");
                case "BAG-24-SOURCE-ACTION":
                    if (sourceContent == null || sourceContent.childCount == 0) return false;
                    Button action = FindDescendant(sourceContent.GetChild(0), "Button_3")?.GetComponent<Button>();
                    if (action == null) return false;
                    action.onClick.Invoke();
                    return true;
                case "BAG-25-EQUIP-INFO-CLOSE": return Invoke(equipmentInfoView, "Layer/zhuangbeiInfoUI/Popup/Btn_close");
                case "BAG-26-EQUIP-INFO-SCROLL":
                    return ScrollToEnd(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/ListView");
                default: return false;
            }
        }

        public bool InvokeInputDigit(int digit)
        {
            if (digit < 0 || digit > 9 || !IsInputOpen) return false;
            return Invoke(inputView, $"Layer/Panel/Bg/BtnList/Btn{digit}");
        }

        public bool Validate(out string detail)
        {
            var required = new[]
            {
                RequireButton(inputView, "Layer/Panel/Bg/BtnList/Btn0"),
                RequireButton(inputView, "Layer/Panel/Bg/BtnList/Btn9"),
                RequireButton(inputView, "Layer/Panel/Bg/BtnList/Btn10"),
                RequireButton(inputView, "Layer/Panel/Bg/BtnList/Btn12"),
                RequireButton(inputView, "Layer/Panel/Bg/Close"),
                RequireButton(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L"),
                RequireButton(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R"),
                RequireButton(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L_0"),
                RequireButton(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R_0"),
                RequireButton(giftView, "Layer/OpenBox/Panel/Button"),
                RequireButton(popupFrameView, "Layer/shopBg/Popup/Btn_close"),
                RequireButton(sourceView, "Layer/Popup/Title/Btn_close"),
                RequireButton(sourceView, "Layer/Popup/Panel_name/Panel_icon"),
                RequireButton(equipmentInfoView, "Layer/zhuangbeiInfoUI/Popup/Btn_close"),
            };
            foreach (Button button in required)
                if (button == null) { detail = "required modal button missing"; return false; }
            ScrollRect giftScroll = Require(giftView, "Layer/OpenBox/Panel/Bg/ListView").GetComponent<ScrollRect>();
            ScrollRect sourceScroll = Require(sourceView, "Layer/Popup/ListView").GetComponent<ScrollRect>();
            ScrollRect equipmentScroll = Require(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/ListView").GetComponent<ScrollRect>();
            bool scrolls = giftScroll != null && giftScroll.content != null
                && sourceScroll != null && sourceScroll.content != null
                && equipmentScroll != null && equipmentScroll.content != null;
            detail = $"modal-buttons={required.Length}, scrolls={(scrolls ? 3 : 0)}/3";
            return scrolls;
        }

        private void ConfigureInput()
        {
            GameObject inputNode = Require(inputView, "Layer/Panel/Bg/Num/TextField");
            InputField inputField = inputNode.GetComponent<InputField>();
            Text importedValue = inputField?.textComponent
                ?? inputNode.transform.Find("Text")?.GetComponent<Text>()
                ?? inputNode.GetComponentsInChildren<Text>(true)
                    .FirstOrDefault(text => text.gameObject.name == "Text");
            Text importedPlaceholder = inputField?.placeholder as Text
                ?? inputNode.transform.Find("Placeholder")?.GetComponent<Text>();
            if (inputField != null) inputField.enabled = false;
            if (importedValue != null) importedValue.gameObject.SetActive(false);
            if (importedPlaceholder != null) importedPlaceholder.gameObject.SetActive(false);
            GameObject display = new GameObject("RuntimeInputDisplay",
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform displayRect = display.GetComponent<RectTransform>();
            RectTransform inputRect = inputNode.GetComponent<RectTransform>();
            displayRect.SetParent(inputNode.transform.parent, false);
            displayRect.anchorMin = inputRect.anchorMin;
            displayRect.anchorMax = inputRect.anchorMax;
            displayRect.pivot = inputRect.pivot;
            displayRect.anchoredPosition = inputRect.anchoredPosition;
            displayRect.sizeDelta = inputRect.sizeDelta;
            displayRect.localScale = inputRect.localScale;
            displayRect.SetAsLastSibling();
            inputDisplay = display.GetComponent<Text>();
            inputDisplay.font = importedValue?.font
                ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            inputDisplay.fontSize = 20;
            inputDisplay.alignment = TextAnchor.MiddleCenter;
            inputDisplay.raycastTarget = false;
            for (int digit = 0; digit <= 9; digit++)
            {
                int value = digit;
                Bind(inputView, $"Layer/Panel/Bg/BtnList/Btn{digit}", () =>
                {
                    inputDigitMask |= 1 << value;
                    int next = quantity * 10 + value;
                    quantity = Mathf.Clamp(next, 0, maxQuantity);
                    RenderQuantity();
                });
            }
            Bind(inputView, "Layer/Panel/Bg/BtnList/Btn10", () =>
            {
                quantity /= 10;
                RenderQuantity();
            });
            Bind(inputView, "Layer/Panel/Bg/BtnList/Btn12", () =>
            {
                if (quantity > 0)
                {
                    useAction(activeItem, quantity, 0);
                    inputView.SetVisible(false);
                }
                else inputView.SetVisible(false);
            });
            Bind(inputView, "Layer/Panel/Bg/Close", () => inputView.SetVisible(false));
        }

        private void ShowInput(BagItemRecord item)
        {
            CloseAll();
            activeItem = item;
            maxQuantity = Mathf.Min(item.Quantity, 200);
            quantity = 0;
            inputDigitMask = 0;
            RenderQuantity();
            inputView.SetVisible(true);
            inputView.GameObject.transform.SetAsLastSibling();
        }

        private void ConfigureGift()
        {
            Text popupTitle = FindText(popupFrameView, "Layer/shopBg/Popup/Title/Title");
            if (popupTitle != null)
            {
                popupTitle.text = "多选一礼包";
                popupTitle.fontSize = Mathf.Min(popupTitle.fontSize, 28);
                RectTransform titleRect = popupTitle.GetComponent<RectTransform>();
                titleRect.sizeDelta = new Vector2(Mathf.Max(360f, titleRect.sizeDelta.x), titleRect.sizeDelta.y);
            }
            GameObject help = popupFrameView.Binding.Find("Layer/shopBg/Popup/Title/Title/Button_1");
            if (help != null) help.SetActive(false);
            GameObject tabs = popupFrameView.Binding.Find("Layer/shopBg/Btn_ListView");
            if (tabs != null) tabs.SetActive(false);
            GameObject list = Require(giftView, "Layer/OpenBox/Panel/Bg/ListView");
            giftTemplate = Require(giftView, "Layer/OpenBox/Panel/Item");
            giftTemplate.SetActive(false);
            giftContent = EnsureContent(list, "RuntimeGiftContent", false);
            giftQuantity = FindText(giftView, "Layer/OpenBox/Panel/TimesBg/Value");
            ConfigureGiftLabel(giftQuantity, new Color32(116, 71, 49, 255), 30);
            Bind(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L", () => AdjustGift(-1));
            Bind(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R", () => AdjustGift(1));
            Bind(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_L_0", () => AdjustGift(-10));
            Bind(giftView, "Layer/OpenBox/Panel/TimesBg/Btn_R_0", () => AdjustGift(10));
            GameObject use = Require(giftView, "Layer/OpenBox/Panel/Button");
            Text useLabel = use.GetComponentInChildren<Text>(true);
            ConfigureGiftLabel(useLabel, Color.white, 30);
            if (useLabel != null) useLabel.text = "使用";
            Bind(giftView, "Layer/OpenBox/Panel/Button", ConfirmGift);
            Bind(popupFrameView, "Layer/shopBg/Popup/Btn_close", () =>
            {
                giftView.SetVisible(false);
                popupFrameView.SetVisible(false);
                selectedChoice = null;
            });
        }

        private void ShowGift(BagItemRecord item)
        {
            CloseAll();
            activeItem = item;
            choices.Clear();
            choices.AddRange(ParseChoices(item.Choices));
            selectedChoice = null;
            quantity = 1;
            maxQuantity = Mathf.Min(item.Quantity, 100);
            ClearChildren(giftContent);
            giftChoiceButtons.Clear();
            for (int index = 0; index < choices.Count; index++)
            {
                Choice choice = choices[index];
                GameObject row = UnityEngine.Object.Instantiate(giftTemplate, giftContent, false);
                row.name = $"RuntimeGiftChoice{index + 1}";
                row.SetActive(true);
                Transform iconBg = FindDescendant(row.transform, "IconBg");
                Text name = iconBg?.Find("Name")?.GetComponent<Text>();
                if (name != null)
                {
                    name.text = choice.Name;
                    name.color = QualityColor(choice.Quality);
                    name.resizeTextForBestFit = true;
                    name.resizeTextMinSize = 16;
                    name.resizeTextMaxSize = Mathf.Max(16, name.fontSize);
                }
                Text owned = FindDescendant(row.transform, "Num")?.GetComponent<Text>();
                if (owned != null) owned.text = $"拥有:{ownedQuantity(choice.Id)}";
                if (iconBg != null)
                {
                    Transform grid = iconBg.Find("Bg") ?? iconBg;
                    Image quality = grid.GetComponent<Image>();
                    if (quality != null)
                    {
                        quality.sprite = resources.LoadFirst(
                            $"HeroUI/common_quality_{Mathf.Clamp(choice.Quality, 1, 7):00}");
                        quality.preserveAspect = true;
                    }
                    CreateChoiceIcon(grid, resources.LoadItemIcon(choice.Picture));
                }
                Button select = row.GetComponent<Button>() ?? row.AddComponent<Button>();
                Toggle importedToggle = FindDescendant(row.transform, "CheckBox")?.GetComponent<Toggle>();
                if (importedToggle != null)
                {
                    importedToggle.interactable = true;
                    importedToggle.SetIsOnWithoutNotify(false);
                    importedToggle.onValueChanged.RemoveAllListeners();
                    importedToggle.onValueChanged.AddListener(isOn =>
                    {
                        if (isOn) selectedChoice = choice;
                        RenderGiftSelection();
                    });
                }
                select.onClick.RemoveAllListeners();
                select.onClick.AddListener(() => { selectedChoice = choice; RenderGiftSelection(); });
                giftChoiceButtons[index] = select;
                Transform icon = FindDescendant(row.transform, "IconBg") ?? FindDescendant(row.transform, "Item");
                if (icon != null)
                {
                    Button detail = icon.GetComponent<Button>() ?? icon.gameObject.AddComponent<Button>();
                    detail.onClick.RemoveAllListeners();
                    detail.onClick.AddListener(() => ShowSource(choice));
                }
            }
            RenderQuantity();
            RenderGiftSelection();
            popupFrameView.SetVisible(true);
            giftView.SetVisible(true);
            GameObject tabs = popupFrameView.Binding.Find("Layer/shopBg/Btn_ListView");
            if (tabs != null) tabs.SetActive(false);
            popupFrameView.GameObject.transform.SetAsLastSibling();
            giftView.GameObject.transform.SetAsLastSibling();
            ScrollRect scroll = Require(giftView, "Layer/OpenBox/Panel/Bg/ListView").GetComponent<ScrollRect>();
            if (scroll != null) scroll.horizontalNormalizedPosition = 0f;
        }

        private void AdjustGift(int delta)
        {
            quantity = Mathf.Clamp(quantity + delta, 1, Mathf.Max(1, maxQuantity));
            RenderQuantity();
        }

        private void ConfirmGift()
        {
            if (selectedChoice == null)
            {
                feedback("请选择");
                return;
            }
            useAction(activeItem, Mathf.Max(1, quantity), choices.IndexOf(selectedChoice) + 1);
            giftView.SetVisible(false);
            popupFrameView.SetVisible(false);
        }

        private void RenderGiftSelection()
        {
            foreach (KeyValuePair<int, Button> pair in giftChoiceButtons)
            {
                bool selected = pair.Key >= 0 && pair.Key < choices.Count && choices[pair.Key] == selectedChoice;
                Toggle toggle = FindDescendant(pair.Value.transform, "CheckBox")?.GetComponent<Toggle>();
                if (toggle != null) toggle.SetIsOnWithoutNotify(selected);
                Transform checkmark = FindDescendant(pair.Value.transform, "__Checkmark");
                if (checkmark != null) checkmark.gameObject.SetActive(selected);
            }
        }

        private void ConfigureSource()
        {
            sourceTemplate = Require(sourceView, "Layer/Popup/itemlayer_1");
            sourceTemplate.SetActive(false);
            sourceContent = EnsureContent(Require(sourceView, "Layer/Popup/ListView"), "RuntimeSourceContent", true);
            Bind(sourceView, "Layer/Popup/Title/Btn_close", () =>
            {
                sourceView.SetVisible(false);
                if (choices.Count > 0)
                {
                    popupFrameView.SetVisible(true);
                    giftView.SetVisible(true);
                    popupFrameView.GameObject.transform.SetAsLastSibling();
                    giftView.GameObject.transform.SetAsLastSibling();
                }
            });
            Bind(sourceView, "Layer/Popup/Panel_name/Panel_icon", ShowEquipmentInfo);
        }

        private void ShowSource(Choice choice)
        {
            sourceChoice = choice;
            popupFrameView.SetVisible(true);
            giftView.SetVisible(true);
            sourceView.SetVisible(true);
            sourceView.GameObject.transform.SetAsLastSibling();
            SetText(sourceView, "Layer/Popup/Panel_name/txt_name", choice.Name);
            SetText(sourceView, "Layer/Popup/Panel_name/txt_num", "数量：0");
            SetText(sourceView, "Layer/Popup/Panel_name/txt_tips", choice.Description);
            SetImage(sourceView, "Layer/Popup/Panel_name/Panel_icon/Icon", resources.LoadItemIcon(choice.Picture));
            ClearChildren(sourceContent);
            string[] sources = (choice.Sources ?? string.Empty).Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            for (int index = 0; index < sources.Length; index++)
            {
                if (!int.TryParse(sources[index], out int functionId)) continue;
                GameObject row = UnityEngine.Object.Instantiate(sourceTemplate, sourceContent, false);
                row.name = $"RuntimeSource{functionId}";
                row.SetActive(true);
                SetRowText(row, "Name_1", "来源：" + SourceName(functionId));
                bool available = canJump(functionId);
                SetRowText(row, "Name_2", available ? string.Empty : "当前版本暂未开放");
                SetRowText(row, "times", string.Empty);
                SetRowActive(row, "Button_1", false);
                SetRowActive(row, "Button_2", false);
                SetRowActive(row, "Button_3", true);
                SetRowActive(row, "item_icon", false);
                Button action = FindDescendant(row.transform, "Button_3")?.GetComponent<Button>() ?? row.AddComponent<Button>();
                action.onClick.RemoveAllListeners();
                action.interactable = available;
                if (available) action.onClick.AddListener(() =>
                {
                    sourceView.SetVisible(false);
                    giftView.SetVisible(false);
                    popupFrameView.SetVisible(false);
                    jumpAction(functionId);
                });
            }
            if (sourceContent.childCount == 0)
            {
                GameObject row = UnityEngine.Object.Instantiate(sourceTemplate, sourceContent, false);
                row.name = "RuntimeSourceText";
                row.SetActive(true);
                string text = string.IsNullOrWhiteSpace(choice.ItemFrom) ? "来源：暂无" : choice.ItemFrom;
                SetRowText(row, "Name_1", text);
                SetRowText(row, "Name_2", string.Empty);
                SetRowText(row, "times", string.Empty);
                SetRowActive(row, "Button_1", false);
                SetRowActive(row, "Button_2", false);
                SetRowActive(row, "Button_3", false);
                SetRowActive(row, "item_icon", false);
            }
        }

        private void ConfigureEquipmentInfo()
        {
            Image mask = equipmentInfoView.Binding.Find("Layer/zhuangbeiInfoUI/Mask")?.GetComponent<Image>();
            if (mask != null) mask.color = new Color(0f, 0f, 0f, 0.95f);
            Bind(equipmentInfoView, "Layer/zhuangbeiInfoUI/Popup/Btn_close", () =>
            {
                equipmentInfoView.SetVisible(false);
                sourceView.SetVisible(true);
                sourceView.GameObject.transform.SetAsLastSibling();
            });
            foreach (string path in new[]
            {
                "Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan",
                "Layer/zhuangbeiInfoUI/zhuangbei/Btn_xiexia",
                "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua",
                "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian",
                "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing",
                "Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu",
            })
            {
                GameObject node = equipmentInfoView.Binding.Find(path);
                if (node != null) node.SetActive(false);
            }
            GameObject list = Require(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/ListView");
            RectTransform content = EnsureContent(list, "RuntimeBagEquipmentInfoContent", true);
            foreach (string section in new[]
            {
                "jichushuxing", "qianghuashuxing", "jinglianshuxing",
                "juexingshuxing", "shenzhushuxing", "zhuangbeitaozhuang", "zhuangbeimiaoshu"
            })
            {
                GameObject node = equipmentInfoView.Binding.Find($"Layer/zhuangbeiInfoUI/Info/{section}");
                if (node != null) node.transform.SetParent(content, false);
            }
        }

        private void ShowEquipmentInfo()
        {
            if (sourceChoice == null) return;
            EquipmentDefinition definition = equipmentCatalog.GetEquipmentByFragment(sourceChoice.Id);
            sourceView.SetVisible(false);
            equipmentInfoView.SetVisible(true);
            equipmentInfoView.GameObject.transform.SetAsLastSibling();
            SetText(equipmentInfoView, "Layer/zhuangbeiInfoUI/zhuangbei/Namebg/Name", definition.Name);
            SetText(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/zhuangbeimiaoshu/Content", definition.Description);
            if (definition.BaseAttribute != null && definition.BaseAttribute.Length >= 2)
            {
                SetText(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1",
                    AttributeName(definition.BaseAttribute[0]) + "：");
                SetText(equipmentInfoView, "Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1/Value",
                    "+" + definition.BaseAttribute[1].ToString(CultureInfo.InvariantCulture));
            }
            foreach (string section in new[]
            {
                "qianghuashuxing", "jinglianshuxing", "juexingshuxing", "shenzhushuxing"
            })
            {
                GameObject node = equipmentInfoView.Binding.Find($"Layer/zhuangbeiInfoUI/Info/{section}");
                if (node != null) node.SetActive(false);
            }
            GameObject host = equipmentInfoView.Binding.Find("Layer/zhuangbeiInfoUI/zhuangbei/Node");
            if (host != null)
            {
                Transform existing = host.transform.Find("RuntimeEquipmentIcon");
                GameObject icon = existing != null ? existing.gameObject
                    : new GameObject("RuntimeEquipmentIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform rect = icon.GetComponent<RectTransform>();
                rect.SetParent(host.transform, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = new Vector2(190f, 190f);
                Image image = icon.GetComponent<Image>();
                image.sprite = resources.LoadEquipmentIcon(definition.Picture);
                image.enabled = image.sprite != null;
                image.preserveAspect = true;
            }
            RenderEquipmentSuit(definition);
            Canvas.ForceUpdateCanvases();
        }

        private void RenderEquipmentSuit(EquipmentDefinition definition)
        {
            GameObject section = equipmentInfoView.Binding.Find(
                "Layer/zhuangbeiInfoUI/Info/zhuangbeitaozhuang");
            if (section == null) return;
            section.SetActive(definition.Suit > 0);
            if (definition.Suit <= 0) return;

            Transform list = FindDescendant(section.transform, "List");
            Transform template = FindDescendant(section.transform, "Item");
            if (list != null && template != null)
            {
                for (int index = list.childCount - 1; index >= 0; index--)
                    if (list.GetChild(index).name.StartsWith("RuntimeSuit", StringComparison.Ordinal))
                        UnityEngine.Object.Destroy(list.GetChild(index).gameObject);
                template.gameObject.SetActive(false);
                IReadOnlyList<EquipmentDefinition> values = equipmentCatalog.GetEquipmentSuit(definition.Suit);
                for (int index = 0; index < values.Count; index++)
                {
                    EquipmentDefinition value = values[index];
                    GameObject item = UnityEngine.Object.Instantiate(template.gameObject, list, false);
                    item.name = $"RuntimeSuit{index + 1}";
                    item.SetActive(true);
                    SetRowText(item, "Name", value.Name);
                    Transform iconHost = FindDescendant(item.transform, "Icon") ?? item.transform;
                    CreateEquipmentIcon(iconHost, value);
                }
            }

            Transform oldVisuals = section.transform.Find("RuntimeSuitVisuals");
            GameObject visuals = oldVisuals != null ? oldVisuals.gameObject
                : new GameObject("RuntimeSuitVisuals", typeof(RectTransform));
            RectTransform visualsRect = visuals.GetComponent<RectTransform>();
            visualsRect.SetParent(section.transform, false);
            visualsRect.anchorMin = new Vector2(0f, 1f);
            visualsRect.anchorMax = new Vector2(1f, 1f);
            visualsRect.pivot = new Vector2(0.5f, 1f);
            visualsRect.anchoredPosition = new Vector2(0f, -28f);
            visualsRect.sizeDelta = new Vector2(-16f, 120f);
            for (int index = visuals.transform.childCount - 1; index >= 0; index--)
                UnityEngine.Object.Destroy(visuals.transform.GetChild(index).gameObject);
            IReadOnlyList<EquipmentDefinition> suitItems = equipmentCatalog.GetEquipmentSuit(definition.Suit);
            int count = Mathf.Min(4, suitItems.Count);
            for (int index = 0; index < count; index++)
            {
                EquipmentDefinition value = suitItems[index];
                GameObject cell = new GameObject($"RuntimeSuitCell{index + 1}", typeof(RectTransform));
                RectTransform cellRect = cell.GetComponent<RectTransform>();
                cellRect.SetParent(visuals.transform, false);
                cellRect.anchorMin = cellRect.anchorMax = new Vector2(0f, 1f);
                cellRect.pivot = new Vector2(0f, 1f);
                cellRect.anchoredPosition = new Vector2(8f + index * 102f, 0f);
                cellRect.sizeDelta = new Vector2(96f, 112f);
                CreateSuitCellVisual(cell.transform, value);
            }

            Transform oldEffects = section.transform.Find("RuntimeSuitEffects");
            GameObject effects = oldEffects != null ? oldEffects.gameObject
                : new GameObject("RuntimeSuitEffects", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform effectsRect = effects.GetComponent<RectTransform>();
            effectsRect.SetParent(section.transform, false);
            effectsRect.anchorMin = new Vector2(0f, 0f);
            effectsRect.anchorMax = new Vector2(1f, 0f);
            effectsRect.pivot = new Vector2(0.5f, 0f);
            effectsRect.anchoredPosition = new Vector2(0f, 4f);
            effectsRect.sizeDelta = new Vector2(-20f, 92f);
            Text label = effects.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 18;
            label.color = new Color32(123, 82, 62, 255);
            label.alignment = TextAnchor.UpperLeft;
            label.horizontalOverflow = HorizontalWrapMode.Wrap;
            label.verticalOverflow = VerticalWrapMode.Overflow;
            label.text = FormatSuitEffects(equipmentCatalog.GetSuit(definition.Suit));
        }

        private void CreateEquipmentIcon(Transform parent, EquipmentDefinition definition)
        {
            Transform existing = parent.Find("RuntimeSuitIcon");
            GameObject icon = existing != null ? existing.gameObject
                : new GameObject("RuntimeSuitIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = icon.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(0f, 10f);
            rect.sizeDelta = new Vector2(76f, 76f);
            Image image = icon.GetComponent<Image>();
            image.sprite = resources.LoadEquipmentIcon(definition.Picture);
            image.enabled = image.sprite != null;
            image.preserveAspect = true;
        }

        private void CreateSuitCellVisual(Transform parent, EquipmentDefinition definition)
        {
            GameObject frameObject = new GameObject("Quality", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform frameRect = frameObject.GetComponent<RectTransform>();
            frameRect.SetParent(parent, false);
            frameRect.anchorMin = frameRect.anchorMax = new Vector2(0.5f, 1f);
            frameRect.pivot = new Vector2(0.5f, 1f);
            frameRect.anchoredPosition = Vector2.zero;
            frameRect.sizeDelta = new Vector2(82f, 82f);
            Image frame = frameObject.GetComponent<Image>();
            frame.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(definition.Quality, 1, 7):00}");
            frame.preserveAspect = true;

            GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform iconRect = iconObject.GetComponent<RectTransform>();
            iconRect.SetParent(parent, false);
            iconRect.anchorMin = iconRect.anchorMax = new Vector2(0.5f, 1f);
            iconRect.pivot = new Vector2(0.5f, 1f);
            iconRect.anchoredPosition = new Vector2(0f, -3f);
            iconRect.sizeDelta = new Vector2(76f, 76f);
            Image icon = iconObject.GetComponent<Image>();
            icon.sprite = resources.LoadEquipmentIcon(definition.Picture);
            icon.preserveAspect = true;

            GameObject nameObject = new GameObject("Name", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform nameRect = nameObject.GetComponent<RectTransform>();
            nameRect.SetParent(parent, false);
            nameRect.anchorMin = nameRect.anchorMax = new Vector2(0.5f, 1f);
            nameRect.pivot = new Vector2(0.5f, 1f);
            nameRect.anchoredPosition = new Vector2(0f, -82f);
            nameRect.sizeDelta = new Vector2(104f, 25f);
            Text name = nameObject.GetComponent<Text>();
            name.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            name.fontSize = 15;
            name.alignment = TextAnchor.UpperCenter;
            name.color = QualityColor(definition.Quality);
            name.text = definition.Name;
        }

        private static string FormatSuitEffects(EquipmentSuitDefinition suit)
        {
            if (suit?.Effects == null) return string.Empty;
            List<string> lines = new List<string>();
            for (int index = 0; index < suit.Effects.Length; index++)
            {
                List<string> values = new List<string>();
                foreach (int[] effect in suit.Effects[index] ?? Array.Empty<int[]>())
                {
                    if (effect == null || effect.Length < 3) continue;
                    values.Add(effect[0] == 2
                        ? $"技能 {effect[1]} Lv.{effect[2]}"
                        : FormatAttribute(effect[1], effect[2]));
                }
                if (values.Count > 0) lines.Add($"{index + 2}件套效果　{string.Join("　", values)}");
            }
            return string.Join("\n", lines);
        }

        private static string FormatAttribute(int id, int value)
        {
            string name;
            switch (id)
            {
                case 1: name = "攻击"; break;
                case 4: name = "生命"; break;
                case 6: name = "命中"; break;
                case 7: name = "闪避"; break;
                case 8: name = "暴击"; break;
                case 9: name = "抗暴"; break;
                case 19: name = "增伤率"; break;
                case 20: name = "减伤率"; break;
                case 21: name = "治疗率"; break;
                default: name = $"属性{id}"; break;
            }
            string suffix = id > 9 ? $"+{value / 100f:0.##}%" : $"+{value}";
            return name + suffix;
        }

        private static string AttributeName(int id)
        {
            switch (id)
            {
                case 1: return "攻击";
                case 2:
                case 4: return "生命";
                default: return $"属性{id}";
            }
        }

        private static string FormatBaseAttribute(int[] attribute)
        {
            if (attribute == null || attribute.Length < 2) return string.Empty;
            string name = attribute[0] == 1 ? "攻击" : attribute[0] == 2 ? "生命" : $"属性{attribute[0]}";
            return $"{name}： +{attribute[1]}";
        }

        private void RenderQuantity()
        {
            string numericValue = quantity.ToString(CultureInfo.InvariantCulture);
            if (inputDisplay != null)
            {
                bool empty = quantity == 0;
                inputDisplay.text = empty ? "请输入数量" : numericValue;
                inputDisplay.color = empty
                    ? new Color32(112, 91, 82, 180)
                    : new Color32(91, 55, 44, 255);
            }
            if (giftQuantity != null) giftQuantity.text = numericValue;
        }

        private static IEnumerable<Choice> ParseChoices(string encoded)
        {
            if (string.IsNullOrWhiteSpace(encoded)) yield break;
            string[] rows = encoded.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (string row in rows)
            {
                string[] fields = row.Split('\t');
                if (fields.Length < 9) continue;
                yield return new Choice
                {
                    Id = Parse(fields[0]),
                    Name = fields[1],
                    Description = fields[2],
                    Picture = Parse(fields[3]),
                    Quality = Parse(fields[4]),
                    ItemType = Parse(fields[5]),
                    Quantity = Parse(fields[6]),
                    ItemFrom = fields[7],
                    Sources = fields[8],
                };
            }
        }

        private static int Parse(string value) =>
            int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out int result) ? result : 0;

        private static string SourceName(int functionId)
        {
            switch (functionId)
            {
                case 4: return "主线副本";
                case 6: return "竞技场";
                case 7: return "决战昆仑";
                case 8: return "血战到底";
                case 13: return "商城";
                case 15: return "将魂商店";
                case 16: return "竞技场商店";
                case 17: return "血战商店";
                case 20: return "玩法商店";
                case 1010:
                case 1011: return "神将招募";
                case 2125: return "帮派商店";
                default: return $"来源 {functionId}";
            }
        }

        private static RectTransform EnsureContent(GameObject viewportObject, string name, bool vertical)
        {
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            Transform old = viewport.Find(name);
            GameObject contentObject = old != null ? old.gameObject : new GameObject(name, typeof(RectTransform));
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.SetParent(viewport, false);
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            if (vertical)
            {
                VerticalLayoutGroup layout = contentObject.GetComponent<VerticalLayoutGroup>() ?? contentObject.AddComponent<VerticalLayoutGroup>();
                layout.childControlHeight = false;
                layout.childControlWidth = false;
                layout.childForceExpandHeight = false;
                layout.childForceExpandWidth = false;
                ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>() ?? contentObject.AddComponent<ContentSizeFitter>();
                fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            }
            else
            {
                content.anchorMin = new Vector2(0f, 1f);
                content.anchorMax = new Vector2(0f, 1f);
                content.pivot = new Vector2(0f, 1f);
                content.anchoredPosition = Vector2.zero;
                HorizontalLayoutGroup layout = contentObject.GetComponent<HorizontalLayoutGroup>() ?? contentObject.AddComponent<HorizontalLayoutGroup>();
                layout.childControlHeight = false;
                layout.childControlWidth = false;
                layout.childForceExpandHeight = false;
                layout.childForceExpandWidth = false;
                ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>() ?? contentObject.AddComponent<ContentSizeFitter>();
                fitter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            }
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = !vertical;
            scroll.vertical = vertical;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            return content;
        }

        private static void ClearChildren(RectTransform content)
        {
            if (content == null) return;
            for (int index = content.childCount - 1; index >= 0; index--)
                UnityEngine.Object.Destroy(content.GetChild(index).gameObject);
        }

        private static GameObject Require(CocosUiView view, string path)
        {
            GameObject value = view.Binding.Find(path);
            if (value == null) throw new InvalidOperationException($"Bag flow node missing: {view.Binding.Source} :: {path}");
            return value;
        }

        private static Button RequireButton(CocosUiView view, string path)
        {
            GameObject node = Require(view, path);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>();
            return button;
        }

        private static void Bind(CocosUiView view, string path, Action action)
        {
            Button button = RequireButton(view, path);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private static bool Invoke(CocosUiView view, string path)
        {
            GameObject node = view.Binding.Find(path);
            Button button = node == null ? null : node.GetComponent<Button>();
            if (button == null) return false;
            button.onClick.Invoke();
            return true;
        }

        private static bool ScrollToEnd(CocosUiView view, string path)
        {
            ScrollRect scroll = view.Binding.Find(path)?.GetComponent<ScrollRect>();
            if (scroll == null || scroll.content == null) return false;
            Canvas.ForceUpdateCanvases();
            LayoutRebuilder.ForceRebuildLayoutImmediate(scroll.content);
            if (scroll.vertical) scroll.verticalNormalizedPosition = 0f;
            if (scroll.horizontal) scroll.horizontalNormalizedPosition = 1f;
            Canvas.ForceUpdateCanvases();
            return true;
        }

        private static Text FindText(CocosUiView view, string path) =>
            view.Binding.Find(path)?.GetComponent<Text>();

        private static void SetText(CocosUiView view, string path, string value)
        {
            Text text = FindText(view, path);
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetImage(CocosUiView view, string path, Sprite sprite)
        {
            GameObject node = view.Binding.Find(path);
            if (node == null) return;
            Image image = node.GetComponent<Image>() ?? node.GetComponentInChildren<Image>(true);
            if (image == null) image = node.AddComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = true;
        }

        private static void SetFirstText(GameObject root, string value)
        {
            Text text = root.GetComponentInChildren<Text>(true);
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetRowText(GameObject root, string name, string value)
        {
            Text text = FindDescendant(root.transform, name)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetRowActive(GameObject root, string name, bool active)
        {
            Transform value = FindDescendant(root.transform, name);
            if (value != null) value.gameObject.SetActive(active);
        }

        private static void SetFirstImage(GameObject root, Sprite sprite)
        {
            Image image = root.GetComponentInChildren<Image>(true);
            if (image != null) { image.sprite = sprite; image.preserveAspect = true; }
        }

        private static void CreateChoiceIcon(Transform parent, Sprite sprite)
        {
            Transform existing = parent.Find("RuntimeChoiceIcon");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeChoiceIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(76f, 76f);
            Image image = value.GetComponent<Image>();
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            rect.SetAsLastSibling();
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

        private static void ConfigureGiftLabel(Text label, Color color, int fontSize)
        {
            if (label == null) return;
            label.gameObject.SetActive(true);
            label.enabled = true;
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = fontSize;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = color;
            label.raycastTarget = false;
            RectTransform rect = label.rectTransform;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.SetAsLastSibling();
        }

        private static Transform FindDescendant(Transform root, string name)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) return child;
            return null;
        }
    }
}
