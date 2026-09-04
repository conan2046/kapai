using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Data;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HeroEquipmentPresenter : IDisposable
    {
        private readonly struct DisplayRecord
        {
            public DisplayRecord(HeroEquipmentRecord equipment)
            {
                Kind = HeroEquipmentKind.Equipment; Equipment = equipment; FaBao = default;
            }
            public DisplayRecord(FaBaoRecord faBao)
            {
                Kind = HeroEquipmentKind.FaBao; Equipment = default; FaBao = faBao;
            }
            public HeroEquipmentKind Kind { get; }
            public HeroEquipmentRecord Equipment { get; }
            public FaBaoRecord FaBao { get; }
            public uint Uid => Kind == HeroEquipmentKind.Equipment ? Equipment.Uid : FaBao.Uid;
            public int FormationPosition => Kind == HeroEquipmentKind.Equipment ? Equipment.FormationPosition : FaBao.FormationPosition;
            public int Slot => Kind == HeroEquipmentKind.Equipment ? Equipment.Slot : FaBao.Slot;
            public uint Experience => Kind == HeroEquipmentKind.Equipment ? Equipment.Experience : FaBao.Experience;
            public EquipmentDefinition Definition => Kind == HeroEquipmentKind.Equipment ? Equipment.Definition : FaBao.Definition;
            public int StrengthLevel => Kind == HeroEquipmentKind.Equipment ? Equipment.GetLevel(1) : FaBao.GetLevel(5);
            public int RefineLevel => Kind == HeroEquipmentKind.Equipment ? Equipment.GetLevel(2) : FaBao.GetLevel(6);
        }

        private readonly struct DisplayPair
        {
            public DisplayPair(DisplayRecord first, DisplayRecord second, bool hasSecond)
            { First = first; Second = second; HasSecond = hasSecond; }
            public DisplayRecord First { get; }
            public DisplayRecord Second { get; }
            public bool HasSecond { get; }
        }

        private readonly CocosUiView listView;
        private readonly CocosUiView detailView;
        private readonly CocosUiView changeView;
        private readonly CocosUiView cultivateView;
        private readonly CocosUiView strengthView;
        private readonly CocosUiView refineView;
        private readonly CocosUiView awakenView;
        private readonly CocosUiView divineView;
        private readonly CocosUiView autoRefineView;
        private readonly CocosUiView exchangeView;
        private readonly CocosUiView autoStarView;
        private readonly CocosUiView autoDivineView;
        private readonly CocosUiView divineEffectView;
        private readonly CocosUiView faBaoStrengthView;
        private readonly CocosUiView faBaoRefineView;
        private readonly CocosUiView faBaoMaterialChooserView;
        private readonly HeroEquipmentStore equipment;
        private readonly FaBaoStore faBao;
        private readonly BagStore bag;
        private readonly EquipmentCatalog catalog;
        private readonly CurrencyStore currencies;
        private readonly Core.ResourceService resources;
        private readonly Action<uint, int> wearEquipment;
        private readonly Action<uint, int> takeOffEquipment;
        private readonly Action<uint> toggleAffixLock;
        private readonly Action<uint> rerollAffix;
        private readonly Action<uint> strengthEquipment;
        private readonly Action<uint> strengthFiveEquipment;
        private readonly Action<int> strengthAllEquipment;
        private readonly Action<uint, int, int> refineEquipment;
        private readonly Action<uint, int[], int[]> autoRefineEquipment;
        private readonly Action<uint> awakenEquipment;
        private readonly Action<uint> divineEquipment;
        private readonly Action<uint, int> wearFaBao;
        private readonly Action<uint> takeOffFaBao;
        private readonly Action<uint, uint[]> strengthFaBao;
        private readonly Action<uint, int> refineFaBao;
        private readonly Action<int, HeroEquipmentKind> showCultivationFrame;
        private readonly Func<int> getPlayerLevel;
        private readonly Func<int, int> getHeroAtDisplayPosition;
        private Text buildRecommendationText;
        private readonly Action<string> showFeedback;
        private readonly VirtualList<DisplayPair> list;
        private readonly VirtualList<DisplayPair> changeList;
        private readonly Text number;
        private readonly GameObject emptyState;
        private readonly GameObject recycleButton;
        private readonly GameObject hideWornToggle;
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Text detailBaseAttribute;
        private readonly Text detailStrength;
        private readonly Text detailRefine;
        private readonly Image detailIcon;
        private readonly Image detailQualityFrame;
        private readonly Button wearButton;
        private readonly Button takeOffButton;
        private readonly Button strengthButton;
        private readonly Button strengthOnceButton;
        private readonly Button refineOnceButton;
        private readonly Button awakenOnceButton;
        private readonly Button divineOnceButton;
        private GameObject affixActionRow;
        private Button affixLockButton;
        private Button affixRerollButton;
        private readonly List<DisplayRecord> items = new List<DisplayRecord>();
        private readonly List<DisplayPair> rows = new List<DisplayPair>();
        private readonly List<ImodAnimationPlayer> cultivationEffects = new List<ImodAnimationPlayer>();
        private DisplayRecord selected;
        private DisplayRecord changeCurrent;
        private bool returnToListOnDetailClose = true;
        private HeroEquipmentKind activeKind = HeroEquipmentKind.Equipment;
        private int formationPosition = 1;
        private int missingIconCount;
        private bool hideWorn;
        private bool changeHideWorn;
        private bool changeHasCurrentEquipped;
        private int autoRefineLevels = 1;
        private int activeCultivationMode = -1;

        public HeroEquipmentKind ActiveKind => activeKind;
        public int ActiveFormationPosition => formationPosition;
        private readonly List<FaBaoRecord> selectedFaBaoMaterials = new List<FaBaoRecord>();

        public HeroEquipmentPresenter(CocosUiView listView, CocosUiView detailView, CocosUiView changeView,
            CocosUiView cultivateView, CocosUiView strengthView, CocosUiView refineView,
            CocosUiView awakenView, CocosUiView divineView,
            CocosUiView autoRefineView, CocosUiView exchangeView, CocosUiView autoStarView,
            CocosUiView autoDivineView, CocosUiView divineEffectView,
            CocosUiView faBaoStrengthView, CocosUiView faBaoRefineView, CocosUiView faBaoMaterialChooserView,
            HeroEquipmentStore equipment, FaBaoStore faBao, BagStore bag,
            EquipmentCatalog catalog, CurrencyStore currencies, Core.ResourceService resources,
            Action<uint, int> wearEquipment, Action<uint, int> takeOffEquipment,
            Action<uint> toggleAffixLock, Action<uint> rerollAffix,
            Action<uint> strengthEquipment, Action<uint> strengthFiveEquipment, Action<int> strengthAllEquipment,
            Action<uint, int, int> refineEquipment, Action<uint, int[], int[]> autoRefineEquipment,
            Action<uint> awakenEquipment, Action<uint> divineEquipment,
            Action<uint, int> wearFaBao, Action<uint> takeOffFaBao,
            Action<uint, uint[]> strengthFaBao, Action<uint, int> refineFaBao,
            Action<int, HeroEquipmentKind> showCultivationFrame,
            Func<int> getPlayerLevel, Func<int, int> getHeroAtDisplayPosition, Action<string> showFeedback)
        {
            this.listView = listView ?? throw new ArgumentNullException(nameof(listView));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.changeView = changeView ?? throw new ArgumentNullException(nameof(changeView));
            this.cultivateView = cultivateView ?? throw new ArgumentNullException(nameof(cultivateView));
            this.strengthView = strengthView ?? throw new ArgumentNullException(nameof(strengthView));
            this.refineView = refineView ?? throw new ArgumentNullException(nameof(refineView));
            this.awakenView = awakenView ?? throw new ArgumentNullException(nameof(awakenView));
            this.divineView = divineView ?? throw new ArgumentNullException(nameof(divineView));
            this.autoRefineView = autoRefineView ?? throw new ArgumentNullException(nameof(autoRefineView));
            this.exchangeView = exchangeView ?? throw new ArgumentNullException(nameof(exchangeView));
            this.autoStarView = autoStarView ?? throw new ArgumentNullException(nameof(autoStarView));
            this.autoDivineView = autoDivineView ?? throw new ArgumentNullException(nameof(autoDivineView));
            this.divineEffectView = divineEffectView ?? throw new ArgumentNullException(nameof(divineEffectView));
            this.faBaoStrengthView = faBaoStrengthView ?? throw new ArgumentNullException(nameof(faBaoStrengthView));
            this.faBaoRefineView = faBaoRefineView ?? throw new ArgumentNullException(nameof(faBaoRefineView));
            this.faBaoMaterialChooserView = faBaoMaterialChooserView ?? throw new ArgumentNullException(nameof(faBaoMaterialChooserView));
            this.equipment = equipment ?? throw new ArgumentNullException(nameof(equipment));
            this.faBao = faBao ?? throw new ArgumentNullException(nameof(faBao));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.wearEquipment = wearEquipment;
            this.takeOffEquipment = takeOffEquipment;
            this.toggleAffixLock = toggleAffixLock;
            this.rerollAffix = rerollAffix;
            this.getHeroAtDisplayPosition = getHeroAtDisplayPosition;
            this.strengthEquipment = strengthEquipment;
            this.strengthFiveEquipment = strengthFiveEquipment;
            this.strengthAllEquipment = strengthAllEquipment;
            this.refineEquipment = refineEquipment;
            this.autoRefineEquipment = autoRefineEquipment;
            this.awakenEquipment = awakenEquipment;
            this.divineEquipment = divineEquipment;
            this.wearFaBao = wearFaBao;
            this.takeOffFaBao = takeOffFaBao;
            this.strengthFaBao = strengthFaBao;
            this.refineFaBao = refineFaBao;
            this.showCultivationFrame = showCultivationFrame;
            this.getPlayerLevel = getPlayerLevel ?? throw new ArgumentNullException(nameof(getPlayerLevel));
            this.showFeedback = showFeedback;

            GameObject viewport = Require(listView, "Layer/zhuangbeibeibaoUI/TableView");
            GameObject template = Require(listView, "Layer/zhuangbeibeibaoUI/ItemList");
            float height = Mathf.Max(120f, template.GetComponent<RectTransform>().rect.height);
            list = new VirtualList<DisplayPair>(viewport, template, height, BindRow);
            GameObject changeViewport = Require(changeView, "Layer/Popup/TableView");
            GameObject changeTemplate = Require(changeView, "Layer/ItemList");
            float changeHeight = Mathf.Max(120f, changeTemplate.GetComponent<RectTransform>().rect.height);
            changeList = new VirtualList<DisplayPair>(changeViewport, changeTemplate, changeHeight, BindChangeRow);
            RequireButton(changeView, "Layer/Popup/Btn_close").onClick.AddListener(() => changeView.SetVisible(false));
            number = RequireText(listView, "Layer/zhuangbeibeibaoUI/Number");
            emptyState = Require(listView, "Layer/zhuangbeibeibaoUI/Point");
            recycleButton = Require(listView, "Layer/zhuangbeibeibaoUI/recycle");
            recycleButton.SetActive(false);
            Require(listView, "Layer/zhuangbeibeibaoUI/cell").SetActive(false);
            hideWornToggle = Require(listView, "Layer/zhuangbeibeibaoUI/CheckBox");
            Toggle hideWorn = hideWornToggle.GetComponent<Toggle>();
            if (hideWorn != null)
            {
                hideWorn.isOn = false;
                hideWorn.onValueChanged.RemoveAllListeners();
                hideWorn.onValueChanged.AddListener(value =>
                {
                    this.hideWorn = value;
                    Render();
                });
            }
            Toggle changeFilter = Require(changeView, "Layer/Popup/CheckBox").GetComponent<Toggle>();
            if (changeFilter != null)
            {
                changeFilter.isOn = false;
                changeFilter.onValueChanged.RemoveAllListeners();
                changeFilter.onValueChanged.AddListener(value =>
                {
                    changeHideWorn = value;
                    RenderChange();
                });
            }

            detailName = RequireText(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Namebg/Name");
            detailDescription = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/zhuangbeimiaoshu/Content");
            detailBaseAttribute = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1/Value");
            detailStrength = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Level/Value");
            detailRefine = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Level/Value");
            Transform detailIconHost = Require(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Node").transform;
            detailQualityFrame = EnsureDetailQualityFrame(detailIconHost);
            detailIcon = EnsureDetailIcon(detailIconHost);
            wearButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan");
            takeOffButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_xiexia");
            strengthButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua");
            strengthOnceButton = RequireButton(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn");
            refineOnceButton = RequireButton(refineView, "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/jinglianyijiBtn");
            awakenOnceButton = RequireButton(awakenView, "Layer/zhuangbeijuexingUI/juexing/juexingxiaohao/yijianjinglianBtn");
            divineOnceButton = RequireButton(divineView, "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Btn_shenzhu");
            GameObject strengthFive = strengthView.Binding.Find("Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghua5Btn");
            if (strengthFive != null) strengthFive.SetActive(true);
            cultivateView.SetVisible(false);
            strengthView.SetVisible(false);
            refineView.SetVisible(false);
            awakenView.SetVisible(false);
            divineView.SetVisible(false);
            autoRefineView.SetVisible(false);
            exchangeView.SetVisible(false);
            autoStarView.SetVisible(false);
            autoDivineView.SetVisible(false);
            divineEffectView.SetVisible(false);
            changeView.SetVisible(false);
            Button close = RequireButton(detailView, "Layer/zhuangbeiInfoUI/Popup/Btn_close");
            close.onClick.RemoveAllListeners();
            close.onClick.AddListener(() =>
            {
                HideDetails();
                listView.SetVisible(returnToListOnDetailClose);
            });
            ConfigureCultivationButtons();
            ConfigureDetailListLayout();
            ConfigureBuildRecommendation();
            ConfigureAffixActions();
            ConfigureSecondaryControls();
            ConfigureCultivationEffects();

            equipment.Changed += Render;
            faBao.Changed += Render;
            Render();
        }

        public int ItemCount => items.Count;
        public int MissingIconCount => missingIconCount;
        public bool IsDetailVisible => detailView.GameObject.activeSelf;
        public bool ReturnsToListOnDetailClose => returnToListOnDetailClose;
        public bool CultivationImodReady => cultivationEffects.Count == 9
            && cultivationEffects.All(value => value != null && value.IsLoaded);
        public bool HasActiveCultivationEffect => cultivationEffects.Any(value => value != null && value.gameObject.activeSelf);
        public bool IsCultivationSubviewExclusive(int mode)
        {
            if (!cultivateView.GameObject.activeSelf || activeCultivationMode != mode || mode < 0 || mode > 3)
                return false;
            bool[] active =
            {
                strengthView.GameObject.activeSelf,
                refineView.GameObject.activeSelf,
                awakenView.GameObject.activeSelf,
                divineView.GameObject.activeSelf
            };
            return active.Count(value => value) == 1 && active[mode];
        }
        public bool IsStrengthAllVisible => cultivateView.Binding.Find(
            "Layer/zhuangbeiyangchengUI/zhuangbei/Btn_yijianqianghua")?.activeSelf == true;

        public bool AreCultivationAttributesBound(int mode)
        {
            CocosUiView view = mode == 1 ? refineView : mode == 2 ? awakenView : mode == 3 ? divineView : null;
            string templatePath = mode == 1
                ? "Layer/zhuangbeijinglianUI/jinglian/jichushuxing/ListView/Panel_1"
                : mode == 2
                    ? "Layer/zhuangbeijuexingUI/juexing/jichushuxing/ListView/Panel_1"
                    : "Layer/zhuangbeijuexingUI/shenzhu/jichushuxing/ListView/Panel_1";
            Transform template = view?.Binding.Find(templatePath)?.transform;
            if (template?.parent == null) return false;
            Transform[] rows = template.parent.Cast<Transform>()
                .Where(value => value.gameObject.activeInHierarchy
                    && (value == template || value.name.StartsWith("RuntimeCultivationAttribute_", StringComparison.Ordinal)))
                .ToArray();
            return rows.Length > 0 && rows.All(row =>
            {
                string name = row.Find("Value_0")?.GetComponent<Text>()?.text;
                string current = row.Find("Value_1")?.GetComponent<Text>()?.text;
                return !string.IsNullOrWhiteSpace(name) && !string.IsNullOrWhiteSpace(current)
                    && current != "123456789";
            });
        }

        public Button GetListItemAction(uint uid)
        {
            Transform cell = listView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == $"EquipmentCell_{uid}" || value.name == $"FaBaoCell_{uid}");
            return cell?.GetComponent<Button>();
        }

        public Button GetListCultivateAction(uint uid)
            => GetListItemAction(uid)?.transform.Find("Btn_yangcheng")?.GetComponent<Button>();

        public Button GetCultivationTargetAction(uint uid)
        {
            Transform marker = cultivateView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == $"StrengthTargetUid_{uid}");
            return marker?.parent?.GetComponent<Button>();
        }

        public void Show(int selectedFormationPosition, HeroEquipmentKind kind = HeroEquipmentKind.Equipment)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            activeKind = kind;
            selected = default;
            returnToListOnDetailClose = true;
            HideDetails();
            Render();
            listView.SetVisible(true);
        }

        public bool ShowSlot(int selectedFormationPosition, int slot)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            activeKind = slot <= 4 ? HeroEquipmentKind.Equipment : HeroEquipmentKind.FaBao;
            returnToListOnDetailClose = false;
            Render();
            DisplayRecord item = items.FirstOrDefault(value =>
                value.FormationPosition == formationPosition && value.Slot == slot);
            bool equipped = item.Uid != 0;
            if (!equipped)
                item = activeKind == HeroEquipmentKind.Equipment
                    ? items.FirstOrDefault(value => value.FormationPosition == 0 && value.Slot == slot)
                    : items.FirstOrDefault(value => value.FormationPosition == 0);
            if (item.Uid == 0) return false;
            listView.SetVisible(false);
            if (equipped) ShowDetails(item);
            else ShowChange(item, false);
            return true;
        }

        public int RenderKind(HeroEquipmentKind kind)
        {
            activeKind = kind;
            selected = default;
            HideDetails();
            Render();
            return items.Count;
        }

        public void HideDetails()
        {
            activeCultivationMode = -1;
            detailView.SetVisible(false);
            changeView.SetVisible(false);
            strengthView.SetVisible(false);
            refineView.SetVisible(false);
            awakenView.SetVisible(false);
            divineView.SetVisible(false);
            autoRefineView.SetVisible(false);
            exchangeView.SetVisible(false);
            autoStarView.SetVisible(false);
            autoDivineView.SetVisible(false);
            divineEffectView.SetVisible(false);
            faBaoStrengthView.SetVisible(false);
            faBaoRefineView.SetVisible(false);
            faBaoMaterialChooserView.SetVisible(false);
            cultivateView.SetVisible(false);
        }

        public void ShowCultivationTab(int mode)
        {
            if (selected.Uid == 0) return;
            if (selected.Kind == HeroEquipmentKind.FaBao)
            {
                if (mode == 1) ShowFaBaoRefine(selected);
                else ShowFaBaoStrength(selected);
                return;
            }
            if (mode == 1) ShowRefine(selected);
            else if (mode == 2) ShowAwaken(selected);
            else if (mode == 3) ShowDivine(selected);
            else ShowStrength(selected);
        }

        public void PlayCultivationSuccess(int operation)
        {
            int mode = operation == 13 ? 1 : operation == 14 ? 2 : operation == 15 ? 3 : 0;
            if (!cultivateView.GameObject.activeSelf || activeCultivationMode != mode) return;
            int effectIndex = mode + 1;
            if (mode == 3)
            {
                int currentLevel = selected.Equipment.GetLevel(4);
                effectIndex = currentLevel <= 0 ? 4 : 4 + ((currentLevel - 1) % 5);
            }
            ShowCultivationEffect(effectIndex);
        }

        public void Render()
        {
            uint selectedUid = selected.Uid;
            HeroEquipmentKind selectedKind = selected.Kind;
            bool detailWasVisible = detailView.GameObject.activeSelf;
            int preservedCultivationMode = activeCultivationMode;
            items.Clear();
            if (activeKind == HeroEquipmentKind.Equipment)
                items.AddRange(equipment.Items
                    .Where(value => !hideWorn || value.FormationPosition == 0)
                    .Select(value => new DisplayRecord(value)));
            else
                items.AddRange(faBao.Items.Select(value => new DisplayRecord(value)));
            number.text = activeKind == HeroEquipmentKind.Equipment
                ? $"数量：{equipment.Count}/1000" : $"数量：{faBao.Count}/999";
            recycleButton.SetActive(false);
            hideWornToggle.SetActive(activeKind == HeroEquipmentKind.Equipment);
            emptyState.SetActive(items.Count == 0);
            missingIconCount = items.Count(IsMissing);
            Text emptyText = emptyState.GetComponentInChildren<Text>(true);
            if (emptyText != null) emptyText.text = activeKind == HeroEquipmentKind.Equipment
                ? "背包中还没有装备哦！" : "背包中还没有法宝哦！";
            rows.Clear();
            for (int index = 0; index < items.Count; index += 2)
                rows.Add(new DisplayPair(items[index], index + 1 < items.Count ? items[index + 1] : default,
                    index + 1 < items.Count));
            list.SetItems(rows);
            if (selectedUid > 0)
            {
                int index = items.FindIndex(item => item.Uid == selectedUid && item.Kind == selectedKind);
                if (index >= 0)
                {
                    bool preservedReturnTarget = returnToListOnDetailClose;
                    if (items[index].Kind == HeroEquipmentKind.FaBao && preservedCultivationMode >= 0)
                    {
                        selected = items[index];
                        ShowCultivationTab(preservedCultivationMode);
                    }
                    else if (preservedCultivationMode == 3) ShowDivine(items[index]);
                    else if (preservedCultivationMode == 2) ShowAwaken(items[index]);
                    else if (preservedCultivationMode == 1) ShowRefine(items[index]);
                    else if (preservedCultivationMode == 0) ShowStrength(items[index]);
                    else if (detailWasVisible) ShowDetails(items[index]);
                    returnToListOnDetailClose = preservedReturnTarget;
                }
            }
        }

        public void Dispose()
        {
            equipment.Changed -= Render;
            faBao.Changed -= Render;
            list.Dispose();
            changeList.Dispose();
        }

        private void BindRow(RectTransform row, DisplayPair pair, int index)
        {
            Transform[] directChildren = row.Cast<Transform>().ToArray();
            Transform first = row.Find("Item1") ?? row.Find("Item_1")
                ?? directChildren.FirstOrDefault(IsBoundListCell);
            Transform second = row.Find("Item2") ?? row.Find("Item_2")
                ?? directChildren.Where(IsBoundListCell).Skip(1).FirstOrDefault();
            if (first == null)
            {
                string children = string.Join(",", row.Cast<Transform>().Select(value => value.name));
                CocosNodeMetadata metadata = row.GetComponent<CocosNodeMetadata>();
                throw new InvalidOperationException(
                    $"Equipment list template Item1/Item_1 was not found; root={row.name}; children={children}; cocosPath={metadata?.CocosPath ?? "<none>"}.");
            }
            BindCell(first, pair.First);
            if (second != null)
            {
                second.gameObject.SetActive(pair.HasSecond);
                if (pair.HasSecond) BindCell(second, pair.Second);
            }
            row.gameObject.name = $"{activeKind}_Row_{index}";
        }

        private static bool IsBoundListCell(Transform value) => value != null
            && (value.name.StartsWith("EquipmentCell_", StringComparison.Ordinal)
                || value.name.StartsWith("FaBaoCell_", StringComparison.Ordinal));

        private void BindCell(Transform cell, DisplayRecord item)
        {
            cell.gameObject.SetActive(true);
            cell.gameObject.name = $"{item.Kind}Cell_{item.Uid}";
            SetText(cell, "Name_1", item.StrengthLevel > 0 ? $"{item.Definition.Name}+{item.StrengthLevel}" : item.Definition.Name);
            SetText(cell, "Name_2", string.Empty);
            int attrType = item.Kind == HeroEquipmentKind.Equipment ? item.Equipment.BaseAttributeType
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 0 ? item.Definition.BaseAttribute[0] : 0;
            uint attrValue = item.Kind == HeroEquipmentKind.Equipment ? item.Equipment.BaseAttributeValue
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 1
                    ? unchecked((uint)item.Definition.BaseAttribute[1]) : 0;
            if (item.Kind == HeroEquipmentKind.Equipment) attrValue += item.Equipment.StrengthAttributeValue;
            SetText(cell, "Atrribute_1", $"{AttributeName(attrType)} +{attrValue}");
            SetText(cell, "Atrribute_2", string.Empty);
            Transform worn = cell.Find("yichuandai");
            if (worn != null) worn.gameObject.SetActive(item.FormationPosition > 0);
            ApplyIcon(cell.Find("Icon")?.GetComponent<Image>(), item);
            Button button = EnsureClickable(cell);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                returnToListOnDetailClose = true;
                ShowDetails(item);
            });
            Transform cultivateTransform = cell.Find("Btn_yangcheng");
            if (cultivateTransform != null)
            {
                Button cultivate = EnsureClickable(cultivateTransform);
                cultivate.gameObject.SetActive(true);
                cultivate.onClick.RemoveAllListeners();
                cultivate.onClick.AddListener(() => ShowStrength(item));
                Transform prompt = cultivate.transform.Find("Prompt");
                if (prompt != null)
                {
                    int nextLevel = Mathf.Min(item.StrengthLevel + 1, catalog.MaxStrengthLevel);
                    int cost = catalog.GetStrengthCost(nextLevel, item.Definition.Quality);
                    prompt.gameObject.SetActive(item.Kind == HeroEquipmentKind.Equipment
                        && nextLevel > item.StrengthLevel && cost > 0 && currencies.Gold >= cost);
                }
            }
        }

        private void ShowDetails(DisplayRecord item)
        {
            activeCultivationMode = -1;
            selected = item;
            Button activeClose = RequireButton(detailView, "Layer/zhuangbeiInfoUI/Popup/Btn_close");
            activeClose.onClick.RemoveAllListeners();
            activeClose.onClick.AddListener(() =>
            {
                HideDetails();
                listView.SetVisible(returnToListOnDetailClose);
            });
            Text popupTitle = detailView.GameObject.GetComponentsInChildren<Text>(true)
                .FirstOrDefault(text => text.text == "装备信息" || text.text == "法宝信息");
            if (popupTitle != null)
                popupTitle.text = item.Kind == HeroEquipmentKind.FaBao ? "法宝信息" : "装备信息";
            detailName.text = item.Definition.Name;
            string description = string.IsNullOrEmpty(item.Definition.Description)
                ? $"模板：{item.Definition.Id}　品质：{item.Definition.Quality}　槽位：{item.Slot}"
                : item.Definition.Description;
            if (item.Kind == HeroEquipmentKind.Equipment && item.Equipment.Affix.IsValid)
            {
                HeroEquipmentAffix affix = item.Equipment.Affix;
                string lockState = (affix.LockMask & 1) != 0 ? "已锁定" : "未锁定";
                description += $"\n<color=#D56A30>[特殊词条·T{affix.Tier}·{lockState}] {affix.Name}</color>\n{affix.Description}" +
                    $"\n<color=#4F8FBC>推荐：{AffixBuildRecommendation(affix.Key)}</color>";
            }
            detailDescription.text = description;
            RefreshBuildRecommendation(item);
            bool hasAffixActions = item.Kind == HeroEquipmentKind.Equipment && item.Equipment.Affix.IsValid;
            affixActionRow.SetActive(hasAffixActions);
            if (hasAffixActions)
            {
                bool locked = (item.Equipment.Affix.LockMask & 1) != 0;
                int baseCost = item.Definition.Quality >= 7 ? 50000 : 30000;
                SetRuntimeButtonLabel(affixLockButton, locked ? "解锁词条" : "锁定词条");
                SetRuntimeButtonLabel(affixRerollButton, $"重铸 {(locked ? baseCost * 2 : baseCost) / 10000}万");
                affixLockButton.onClick.RemoveAllListeners();
                affixLockButton.onClick.AddListener(() => toggleAffixLock?.Invoke(item.Uid));
                affixRerollButton.onClick.RemoveAllListeners();
                affixRerollButton.onClick.AddListener(() => rerollAffix?.Invoke(item.Uid));
            }
            int attrType = item.Kind == HeroEquipmentKind.Equipment
                ? item.Equipment.BaseAttributeType
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 0 ? item.Definition.BaseAttribute[0] : 0;
            uint attrValue = item.Kind == HeroEquipmentKind.Equipment
                ? item.Equipment.BaseAttributeValue
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 1
                    ? unchecked((uint)item.Definition.BaseAttribute[1]) : 0;
            SetDetailText("Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1",
                AttributeName(attrType) + "：");
            detailBaseAttribute.text = $"+{attrValue}";
            detailStrength.text = item.Kind == HeroEquipmentKind.Equipment
                ? $"{item.StrengthLevel}/240" : $"{item.StrengthLevel}/19";
            detailRefine.text = item.Kind == HeroEquipmentKind.Equipment
                ? $"{item.RefineLevel}/50" : $"{item.RefineLevel}/24";
            SetDetailText("Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Atrribute_1",
                AttributeName(attrType) + "：");
            SetDetailText("Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Atrribute_1/Value",
                $"+{(item.Kind == HeroEquipmentKind.Equipment ? item.Equipment.StrengthAttributeValue : 0u)}");
            ApplyIcon(detailIcon, item);
            bool worn = item.FormationPosition > 0;
            wearButton.gameObject.SetActive(true);
            takeOffButton.gameObject.SetActive(worn);
            wearButton.onClick.RemoveAllListeners();
            takeOffButton.onClick.RemoveAllListeners();
            strengthButton.onClick.RemoveAllListeners();
            strengthButton.gameObject.SetActive(true);
            SetSectionVisible("jichushuxing", true);
            SetSectionVisible("qianghuashuxing", true);
            SetSectionVisible("jinglianshuxing", true);
            SetSectionVisible("juexingshuxing", item.Kind == HeroEquipmentKind.Equipment && item.Definition.Quality >= 5);
            SetSectionVisible("shenzhushuxing", item.Kind == HeroEquipmentKind.Equipment && item.Definition.Quality >= 6);
            SetSectionVisible("zhuangbeitaozhuang", false);
            if (item.Kind == HeroEquipmentKind.Equipment)
            {
                wearButton.onClick.AddListener(() =>
                {
                    if (item.FormationPosition == 0) wearEquipment?.Invoke(item.Uid, formationPosition);
                    else ShowChange(item);
                });
                takeOffButton.onClick.AddListener(() => takeOffEquipment?.Invoke(item.Uid, item.FormationPosition));
                strengthButton.onClick.AddListener(() => ShowStrength(item));
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian", true,
                    () => ShowRefine(item));
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing",
                    item.Definition.Quality >= 5, () => ShowAwaken(item));
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu",
                    item.Definition.Quality >= 6, () => ShowDivine(item));
            }
            else
            {
                wearButton.onClick.AddListener(() => ShowChange(item));
                takeOffButton.onClick.AddListener(() => takeOffFaBao?.Invoke(item.Uid));
                strengthButton.onClick.AddListener(() => ShowFaBaoStrength(item));
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian", true,
                    () => ShowFaBaoRefine(item));
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing", false, null);
                BindDetailCultivationButton("Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu", false, null);
            }
            listView.SetVisible(false);
            detailView.SetVisible(true);
            detailView.GameObject.transform.SetAsLastSibling();
            Canvas.ForceUpdateCanvases();
            foreach (ScrollRect scroll in detailView.GameObject.GetComponentsInChildren<ScrollRect>(true))
            {
                if (scroll.content == null)
                {
                    continue;
                }

                scroll.StopMovement();
                scroll.verticalNormalizedPosition = 1f;
            }
        }

        private void ShowChange(DisplayRecord current, bool hasCurrentEquipped = true)
        {
            changeCurrent = current;
            changeHasCurrentEquipped = hasCurrentEquipped;
            changeHideWorn = false;
            Transform changeViewport = changeView.Binding.Find("Layer/Popup/TableView")?.transform;
            Transform changeBackground = changeView.Binding.Find("Layer/Popup/bg")?.transform;
            if (changeViewport != null && changeBackground != null)
                changeViewport.SetSiblingIndex(changeBackground.GetSiblingIndex() + 1);
            Toggle filter = changeView.Binding.Find("Layer/Popup/CheckBox")?.GetComponent<Toggle>();
            if (filter != null) filter.SetIsOnWithoutNotify(false);
            RenderChange();
            Text title = RequireText(changeView, "Layer/Popup/Title/Title");
            title.text = current.Kind == HeroEquipmentKind.Equipment ? "装备更换" : "法宝更换";
            changeView.SetVisible(true);
            changeView.GameObject.transform.SetAsLastSibling();
        }

        private void RenderChange()
        {
            if (changeCurrent.Uid == 0) return;
            List<DisplayRecord> candidates = changeCurrent.Kind == HeroEquipmentKind.Equipment
                ? equipment.Items.Where(value => value.Slot == changeCurrent.Slot
                    && (!changeHideWorn || value.FormationPosition == 0))
                    .Select(value => new DisplayRecord(value)).ToList()
                : faBao.Items.Where(value => !changeHideWorn || value.FormationPosition == 0)
                    .Select(value => new DisplayRecord(value)).ToList();
            List<DisplayPair> candidateRows = new List<DisplayPair>();
            for (int index = 0; index < candidates.Count; index += 2)
                candidateRows.Add(new DisplayPair(candidates[index], index + 1 < candidates.Count ? candidates[index + 1] : default,
                    index + 1 < candidates.Count));
            changeList.SetItems(candidateRows);
        }

        private void BindChangeRow(RectTransform row, DisplayPair pair, int index)
        {
            Transform[] directChildren = row.Cast<Transform>().ToArray();
            Transform first = row.Find("Item1") ?? row.Find("Item_1")
                ?? directChildren.FirstOrDefault(IsChangeListCell);
            Transform second = row.Find("Item2") ?? row.Find("Item_2")
                ?? directChildren.Where(IsChangeListCell).Skip(1).FirstOrDefault();
            if (first == null) throw new InvalidOperationException("Equipment change template first cell was not found.");
            BindChangeCell(first, pair.First);
            if (second != null)
            {
                second.gameObject.SetActive(pair.HasSecond);
                if (pair.HasSecond) BindChangeCell(second, pair.Second);
            }
        }

        private void BindChangeCell(Transform cell, DisplayRecord item)
        {
            BindCell(cell, item);
            cell.gameObject.name = $"ChangeCandidate_{item.Uid}";
            Transform actionTransform = cell.Find("Btn_yangcheng");
            if (actionTransform == null) return;
            Button action = EnsureClickable(actionTransform);
            action.gameObject.SetActive(true);
            Text label = action.GetComponentInChildren<Text>(true);
            if (label != null)
            {
                label.text = changeHasCurrentEquipped && item.Uid == changeCurrent.Uid ? "已穿戴" : "穿戴";
                RectTransform labelRect = label.rectTransform;
                labelRect.anchorMin = Vector2.zero;
                labelRect.anchorMax = Vector2.one;
                labelRect.anchoredPosition = Vector2.zero;
                labelRect.sizeDelta = Vector2.zero;
                label.alignment = TextAnchor.MiddleCenter;
                label.horizontalOverflow = HorizontalWrapMode.Overflow;
                label.verticalOverflow = VerticalWrapMode.Overflow;
            }
            action.interactable = !changeHasCurrentEquipped || item.Uid != changeCurrent.Uid;
            action.onClick.RemoveAllListeners();
            action.onClick.AddListener(() =>
            {
                if (item.Kind == HeroEquipmentKind.Equipment) wearEquipment?.Invoke(item.Uid, formationPosition);
                else wearFaBao?.Invoke(item.Uid, formationPosition);
                changeView.SetVisible(false);
            });
        }

        private void ShowStrength(DisplayRecord item)
        {
            if (item.Kind == HeroEquipmentKind.FaBao)
            {
                ShowFaBaoStrength(item);
                return;
            }
            if (!CanOpenCultivation(item, 0)) return;
            HideCultivationEffects();
            activeCultivationMode = 0;
            selected = item;
            showCultivationFrame?.Invoke(0, item.Kind);
            int currentLevel = item.StrengthLevel;
            int nextLevel = Mathf.Min(currentLevel + 1, catalog.MaxStrengthLevel);
            SetBoundText(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/Level_1", $"{currentLevel}级");
            SetBoundText(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/Level_2", $"{nextLevel}级");
            int[] strengthAttribute = item.Definition.GetPrimaryStrengthAttribute();
            int attrType = strengthAttribute.Length >= 2 ? strengthAttribute[0] : item.Equipment.BaseAttributeType;
            int perLevel = strengthAttribute.Length >= 2 ? strengthAttribute[1] : 0;
            Transform panel = Require(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/ListView/Panel_1").transform;
            SetText(panel, "Value_0", AttributeName(attrType));
            SetText(panel, "Value_1", (perLevel * currentLevel).ToString());
            SetText(panel, "Value_2", (perLevel * nextLevel).ToString());
            SetText(panel, "Value_3", perLevel.ToString());
            SetBoundText(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/ConsumeBg/Value",
                catalog.GetStrengthCost(nextLevel, item.Definition.Quality).ToString());
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Name", item.Definition.Name);
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Name/addnum", $"+{currentLevel}");
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/level_text", "等级：");
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/level_text/levelnum", $"{currentLevel}级");
            GameObject cultivateIconObject = cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/equip");
            ApplyIcon(cultivateIconObject?.GetComponent<Image>(), item);
            if (cultivateIconObject != null)
            {
                cultivateIconObject.SetActive(true);
                RectTransform iconRect = cultivateIconObject.GetComponent<RectTransform>();
                if (iconRect != null) iconRect.sizeDelta = new Vector2(180f, 180f);
            }
            SetBoundText(strengthView,
                "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn/Text", "强化");
            SetButtonLabel(cultivateView,
                "Layer/zhuangbeiyangchengUI/zhuangbei/Btn_yijianqianghua", "一键强化");
            Text strengthActionLabel = strengthView.Binding.Find(
                "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn/Text")?.GetComponent<Text>();
            if (strengthActionLabel != null)
            {
                RectTransform labelRect = strengthActionLabel.rectTransform;
                labelRect.anchorMin = Vector2.zero;
                labelRect.anchorMax = Vector2.one;
                labelRect.anchoredPosition = Vector2.zero;
                labelRect.sizeDelta = Vector2.zero;
                strengthActionLabel.alignment = TextAnchor.MiddleCenter;
                strengthActionLabel.horizontalOverflow = HorizontalWrapMode.Overflow;
                strengthActionLabel.verticalOverflow = VerticalWrapMode.Overflow;
            }
            foreach (string hiddenPath in new[]
            {
                "Layer/zhuangbeiyangchengUI/zhuangbei/juexing",
                "Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu"
            })
                cultivateView.Binding.Find(hiddenPath)?.SetActive(false);
            GameObject strengthAllObject = cultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Btn_yijianqianghua");
            if (strengthAllObject != null)
            {
                Button strengthAll = EnsureClickable(strengthAllObject.transform);
                strengthAll.gameObject.SetActive(item.FormationPosition > 0);
                strengthAll.onClick.RemoveAllListeners();
                strengthAll.onClick.AddListener(() => strengthAllEquipment?.Invoke(formationPosition));
            }
            strengthOnceButton.onClick.RemoveAllListeners();
            strengthOnceButton.onClick.AddListener(() => strengthEquipment?.Invoke(item.Uid));
            Button strengthFive = strengthView.Binding.Find(
                "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghua5Btn")?.GetComponent<Button>();
            if (strengthFive != null)
            {
                strengthFive.gameObject.SetActive(true);
                strengthFive.onClick.RemoveAllListeners();
                strengthFive.onClick.AddListener(() => strengthFiveEquipment?.Invoke(item.Uid));
            }
            BindStrengthTargets(item);
            listView.SetVisible(false);
            detailView.SetVisible(false);
            changeView.SetVisible(false);
            cultivateView.SetVisible(true);
            SetEquipmentCultivationSubview(0);
            cultivateView.GameObject.transform.SetAsLastSibling();
            strengthView.GameObject.transform.SetAsLastSibling();
        }

        public bool PrepareDetails(uint uid, int selectedFormationPosition)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            if (!equipment.TryGet(uid, out HeroEquipmentRecord value)) return false;
            activeKind = HeroEquipmentKind.Equipment;
            Render();
            ShowDetails(new DisplayRecord(value));
            return true;
        }

        public bool PrepareCultivation(uint uid, int selectedFormationPosition, HeroEquipmentKind kind, int mode)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            activeKind = kind;
            if (kind == HeroEquipmentKind.Equipment)
            {
                if (!equipment.TryGet(uid, out HeroEquipmentRecord equipmentValue)) return false;
                selected = new DisplayRecord(equipmentValue);
            }
            else
            {
                if (!faBao.TryGet(uid, out FaBaoRecord faBaoValue)) return false;
                selected = new DisplayRecord(faBaoValue);
            }
            ShowCultivationTab(mode);
            return true;
        }

        private void ShowFaBaoStrength(DisplayRecord item)
        {
            if (!CanOpenCultivation(item, 0)) return;
            HideCultivationEffects();
            activeCultivationMode = 0;
            selected = item;
            showCultivationFrame?.Invoke(0, HeroEquipmentKind.FaBao);
            int currentLevel = item.StrengthLevel;
            int nextLevel = Mathf.Min(currentLevel + 1, catalog.MaxFaBaoStrengthLevel);
            SetBoundText(faBaoStrengthView, "Layer/fabaoqianghuaUI/qianghua/jichushuxing/Level_1", $"{currentLevel}级");
            SetBoundText(faBaoStrengthView, "Layer/fabaoqianghuaUI/qianghua/jichushuxing/Level_2", $"{nextLevel}级");
            int[] strengthAttribute = item.Definition.GetPrimaryStrengthAttribute();
            int attrType = strengthAttribute.Length >= 2 ? strengthAttribute[0] : 1;
            int perLevel = strengthAttribute.Length >= 2 ? strengthAttribute[1] : 0;
            int baseValue = item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length >= 2
                && item.Definition.BaseAttribute[0] == attrType ? item.Definition.BaseAttribute[1] : 0;
            Transform panel = Require(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/jichushuxing/ListView/Panel_1").transform;
            SetText(panel, "Value_0", AttributeName(attrType));
            SetText(panel, "Value_1", (baseValue + perLevel * currentLevel).ToString());
            SetText(panel, "Value_2", (baseValue + perLevel * nextLevel).ToString());
            SetText(panel, "Value_3", perLevel.ToString());
            int required = catalog.GetFaBaoStrengthExperience(currentLevel, item.Definition.Quality);
            int selectedExperience = selectedFaBaoMaterials.Sum(value => Mathf.Max(0, value.Definition.ExperienceValue));
            SetBoundText(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/Slider_Bg/Value", $"{item.Experience}/{required}");
            SetBoundText(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/Slider_Bg/Value/Value_up",
                selectedExperience > 0 ? $"+{selectedExperience}" : string.Empty);
            SetBoundText(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/Level", $"{currentLevel}级");
            SetBoundText(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/Level/Levelup", $"+{Mathf.Max(0, nextLevel - currentLevel)}");
            SetBoundText(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/ConsumeBg/Value", selectedExperience.ToString());
            BindCultivationShell(item);
            BindFaBaoMaterialSlots();
            Button autoAdd = RequireButton(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/yijiantianjiaBtn");
            autoAdd.onClick.RemoveAllListeners();
            autoAdd.onClick.AddListener(() =>
            {
                selectedFaBaoMaterials.Clear();
                selectedFaBaoMaterials.AddRange(GetEligibleFaBaoMaterials().Take(8));
                ShowFaBaoStrength(selected);
            });
            Button action = RequireButton(faBaoStrengthView,
                "Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn");
            action.onClick.RemoveAllListeners();
            action.onClick.AddListener(() => strengthFaBao?.Invoke(item.Uid,
                selectedFaBaoMaterials.Select(value => value.Uid).ToArray()));
            listView.SetVisible(false);
            detailView.SetVisible(false);
            cultivateView.SetVisible(true);
            strengthView.SetVisible(false);
            refineView.SetVisible(false);
            awakenView.SetVisible(false);
            divineView.SetVisible(false);
            faBaoRefineView.SetVisible(false);
            faBaoStrengthView.SetVisible(true);
            cultivateView.GameObject.transform.SetAsLastSibling();
            faBaoStrengthView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowFaBaoRefine(DisplayRecord item)
        {
            if (!CanOpenCultivation(item, 1)) return;
            HideCultivationEffects();
            activeCultivationMode = 1;
            selected = item;
            showCultivationFrame?.Invoke(1, HeroEquipmentKind.FaBao);
            int currentLevel = item.RefineLevel;
            FaBaoRefineDefinition next = catalog.GetFaBaoRefine(currentLevel);
            int nextLevel = next != null && next.Cost != null && next.Cost.Length > 0 ? currentLevel + 1 : currentLevel;
            SetBoundText(faBaoRefineView, "Layer/fabaojuexing_layer/juexing/juexingshuxing/Level_1", $"{currentLevel}级");
            SetBoundText(faBaoRefineView, "Layer/fabaojuexing_layer/juexing/juexingshuxing/Level_2", $"{nextLevel}级");
            BindCultivationAttributes(faBaoRefineView,
                "Layer/fabaojuexing_layer/juexing/juexingshuxing/ListView/Panel_1",
                item.Definition.RefineAttributes, currentLevel, nextLevel);
            int[] itemCost = next?.Cost?.FirstOrDefault(value => value != null && value.Length >= 3
                && value[0] != 60000);
            int essenceItemId = itemCost != null ? itemCost[0] : 0;
            int essence = itemCost != null ? itemCost[2] : 0;
            int gold = next?.Cost?.FirstOrDefault(value => value != null && value.Length >= 3 && value[0] == 60000)?[2] ?? 0;
            EquipmentMaterialDefinition essenceDefinition = catalog.GetItem(essenceItemId);
            SetBoundText(faBaoRefineView, "Layer/fabaojuexing_layer/juexing/jinglianxiaohao/Name",
                essenceDefinition?.Name ?? "法宝精华");
            SetBoundText(faBaoRefineView, "Layer/fabaojuexing_layer/juexing/jinglianxiaohao/Value",
                $"{bag.GetTotalQuantityByItemId(essenceItemId)}/{essence}");
            ApplyMaterialIcon(faBaoRefineView.Binding.Find(
                "Layer/fabaojuexing_layer/juexing/jinglianxiaohao/Item")?.GetComponent<Image>(), essenceDefinition);
            SetBoundText(faBaoRefineView, "Layer/fabaojuexing_layer/juexing/jinglianxiaohao/ConsumeBg/Value", gold.ToString());
            Button action = RequireButton(faBaoRefineView,
                "Layer/fabaojuexing_layer/juexing/jinglianxiaohao/Btn_shenzhu");
            action.onClick.RemoveAllListeners();
            action.onClick.AddListener(() => refineFaBao?.Invoke(item.Uid, nextLevel));
            BindCultivationShell(item);
            listView.SetVisible(false);
            detailView.SetVisible(false);
            cultivateView.SetVisible(true);
            strengthView.SetVisible(false);
            refineView.SetVisible(false);
            awakenView.SetVisible(false);
            divineView.SetVisible(false);
            faBaoStrengthView.SetVisible(false);
            faBaoRefineView.SetVisible(true);
            cultivateView.GameObject.transform.SetAsLastSibling();
            faBaoRefineView.GameObject.transform.SetAsLastSibling();
        }

        private void BindCultivationShell(DisplayRecord item)
        {
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Name", item.Definition.Name);
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Name/addnum", $"+{item.RefineLevel}");
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/level_text", "等级：");
            SetBoundText(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/level_text/levelnum", $"{item.StrengthLevel}级");
            GameObject mainIconObject = cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/equip");
            ApplyIcon(mainIconObject?.GetComponent<Image>(), item);
            if (mainIconObject != null)
            {
                mainIconObject.SetActive(true);
                RectTransform iconRect = mainIconObject.GetComponent<RectTransform>();
                if (iconRect != null) iconRect.sizeDelta = new Vector2(150f, 150f);
            }
            BindFaBaoCultivationList(item);
            SetStrengthAllVisible(false);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/juexing")?.SetActive(false);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu")?.SetActive(false);
        }

        private IEnumerable<FaBaoRecord> GetEligibleFaBaoMaterials()
        {
            return faBao.Items.Where(value => value.Uid != selected.Uid && value.FormationPosition == 0
                && value.GetLevel(5) == 0 && value.GetLevel(6) == 0 && value.Definition.ExperienceValue > 0)
                .OrderBy(value => value.Definition.Quality).ThenBy(value => value.Uid);
        }

        private void BindFaBaoCultivationList(DisplayRecord current)
        {
            Transform listRoot = cultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/List")?.transform;
            Transform template = listRoot?.Find("item_layer");
            if (template == null) return;
            foreach (Transform old in listRoot.Cast<Transform>()
                .Where(value => value.name.StartsWith("RuntimeFaBaoCultivationItem_", StringComparison.Ordinal))
                .ToArray())
                UnityEngine.Object.Destroy(old.gameObject);

            FaBaoRecord[] values = faBao.Items
                .Where(value => value.FormationPosition == current.FormationPosition)
                .OrderBy(value => value.Slot)
                .ToArray();
            RectTransform templateRect = template as RectTransform;
            Vector2 start = templateRect != null ? templateRect.anchoredPosition : Vector2.zero;
            for (int index = 0; index < values.Length; index++)
            {
                FaBaoRecord value = values[index];
                Transform cell = index == 0 ? template
                    : UnityEngine.Object.Instantiate(template, listRoot, false);
                cell.name = index == 0 ? "item_layer" : $"RuntimeFaBaoCultivationItem_{index}";
                RectTransform cellRect = cell as RectTransform;
                if (cellRect != null) cellRect.anchoredPosition = start + new Vector2(90f * index, 0f);
                cell.gameObject.SetActive(true);
                Transform iconHost = cell.Find("zhuangbeiIcon");
                BindFaBaoQualityIcon(iconHost, value);
                Transform choose = cell.Find("Choose");
                if (choose != null) choose.gameObject.SetActive(value.Uid == current.Uid);
                Button button = EnsureClickable(cell);
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() =>
                {
                    selected = new DisplayRecord(value);
                    selectedFaBaoMaterials.Clear();
                    ShowCultivationTab(activeCultivationMode);
                });
            }
            if (values.Length == 0) template.gameObject.SetActive(false);
        }

        private void BindFaBaoQualityIcon(Transform host, FaBaoRecord value)
        {
            if (host == null) return;
            Image frame = host.GetComponent<Image>();
            if (frame != null)
            {
                frame.sprite = resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(value.Definition.Quality, 1, 7):00}");
                frame.enabled = frame.sprite != null;
                frame.preserveAspect = false;
            }
            Transform old = host.Find("RuntimeFaBaoCultivationIcon");
            GameObject iconObject = old != null ? old.gameObject
                : new GameObject("RuntimeFaBaoCultivationIcon",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = iconObject.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = new Vector2(0.1f, 0.1f);
            rect.anchorMax = new Vector2(0.9f, 0.9f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image icon = iconObject.GetComponent<Image>();
            icon.sprite = resources.LoadFaBaoIcon(value.Definition.Picture, out _);
            icon.enabled = icon.sprite != null;
            icon.preserveAspect = true;
            icon.raycastTarget = false;
            iconObject.transform.SetAsLastSibling();
        }

        private void BindFaBaoMaterialSlots()
        {
            for (int index = 0; index < 8; index++)
            {
                string root = $"Layer/fabaoqianghuaUI/qianghua/qianghuaxiaohao/suipian_layer/suipianicon{index + 1}";
                GameObject slot = faBaoStrengthView.Binding.Find(root);
                if (slot == null) continue;
                bool populated = index < selectedFaBaoMaterials.Count;
                GameObject iconObject = faBaoStrengthView.Binding.Find(root + "/IconBase");
                GameObject addObject = faBaoStrengthView.Binding.Find(root + "/AddIcon");
                if (iconObject != null)
                {
                    iconObject.SetActive(populated);
                    if (populated) ApplyIcon(iconObject.GetComponent<Image>(), new DisplayRecord(selectedFaBaoMaterials[index]));
                }
                if (addObject != null) addObject.SetActive(!populated);
                Button button = EnsureClickable(slot.transform);
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(OpenFaBaoMaterialChooser);
            }
        }

        private void OpenFaBaoMaterialChooser()
        {
            List<FaBaoRecord> candidates = GetEligibleFaBaoMaterials().ToList();
            GameObject viewportObject = Require(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/TableView");
            GameObject template = Require(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/ItemList");
            Transform oldContent = viewportObject.transform.Find("RuntimeFaBaoMaterialContent");
            if (oldContent != null) UnityEngine.Object.Destroy(oldContent.gameObject);
            GameObject contentObject = new GameObject("RuntimeFaBaoMaterialContent", typeof(RectTransform),
                typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.SetParent(viewportObject.transform, false);
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            VerticalLayoutGroup layout = contentObject.GetComponent<VerticalLayoutGroup>();
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            for (int index = 0; index < candidates.Count; index += 2)
            {
                Transform row = UnityEngine.Object.Instantiate(template, content).transform;
                row.name = $"FaBaoMaterialRow_{index / 2}";
                row.gameObject.SetActive(true);
                BindFaBaoMaterialCell(row.Find("Item1"), candidates[index]);
                Transform second = row.Find("Item2");
                if (index + 1 < candidates.Count) BindFaBaoMaterialCell(second, candidates[index + 1]);
                else if (second != null) second.gameObject.SetActive(false);
            }
            template.SetActive(false);
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>() ?? viewportObject.AddComponent<ScrollRect>();
            scroll.viewport = viewportObject.GetComponent<RectTransform>();
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            if (viewportObject.GetComponent<RectMask2D>() == null) viewportObject.AddComponent<RectMask2D>();
            SetBoundText(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/Number/Value", selectedFaBaoMaterials.Count.ToString());
            SetBoundText(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/Btn_Choose/Text", "确定");
            Button confirm = RequireButton(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/Btn_Choose");
            confirm.onClick.RemoveAllListeners();
            confirm.onClick.AddListener(() =>
            {
                faBaoMaterialChooserView.SetVisible(false);
                ShowFaBaoStrength(selected);
            });
            faBaoMaterialChooserView.SetVisible(true);
            faBaoMaterialChooserView.GameObject.transform.SetAsLastSibling();
        }

        private void BindFaBaoMaterialCell(Transform cell, FaBaoRecord value)
        {
            if (cell == null) return;
            cell.gameObject.SetActive(true);
            SetText(cell, "Name", value.Definition.Name);
            SetText(cell, "Text_1", $"强化：{value.GetLevel(5)}级");
            SetText(cell, "Text_2", $"精炼：{value.GetLevel(6)}级");
            SetText(cell, "Text_3", $"提供经验：{Mathf.Max(0, value.Definition.ExperienceValue)}");
            ApplyIcon(cell.Find("Icon")?.GetComponent<Image>(), new DisplayRecord(value));
            Toggle toggle = cell.Find("CheckBox")?.GetComponent<Toggle>();
            if (toggle != null)
            {
                toggle.onValueChanged.RemoveAllListeners();
                toggle.isOn = selectedFaBaoMaterials.Any(item => item.Uid == value.Uid);
                toggle.onValueChanged.AddListener(isOn =>
                {
                    selectedFaBaoMaterials.RemoveAll(item => item.Uid == value.Uid);
                    if (isOn && selectedFaBaoMaterials.Count < 8) selectedFaBaoMaterials.Add(value);
                    SetBoundText(faBaoMaterialChooserView, "Layer/ChooseUI/Popup/Number/Value",
                        selectedFaBaoMaterials.Count.ToString());
                });
            }
        }

        public Button GetChangeCandidateAction(uint uid)
        {
            Transform candidate = changeView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == $"ChangeCandidate_{uid}");
            return candidate?.Find("Btn_yangcheng")?.GetComponent<Button>();
        }

        private void ShowRefine(DisplayRecord item)
        {
            if (!CanOpenCultivation(item, 1)) return;
            ShowStrength(item);
            activeCultivationMode = 1;
            showCultivationFrame?.Invoke(1, item.Kind);
            int currentLevel = item.RefineLevel;
            EquipmentRefineDefinition config = catalog.GetRefine(currentLevel);
            int nextLevel = catalog.GetRefine(currentLevel + 1) != null ? currentLevel + 1 : currentLevel;
            SetBoundText(refineView, "Layer/zhuangbeijinglianUI/jinglian/jichushuxing/Level_1", $"{currentLevel}级");
            SetBoundText(refineView, "Layer/zhuangbeijinglianUI/jinglian/jichushuxing/Level_2", $"{nextLevel}级");
            BindCultivationAttributes(refineView,
                "Layer/zhuangbeijinglianUI/jinglian/jichushuxing/ListView/Panel_1",
                item.Definition.RefineAttributes, currentLevel, nextLevel);
            SetBoundText(refineView, "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/Slider_Bg/Value",
                $"{item.Experience}/{config?.Experience ?? 0}");
            IReadOnlyList<int> materialIds = catalog.GetRefineMaterialIds();
            BagItemRecord material = bag.Items.FirstOrDefault(value => catalog.GetRefineMaterialExperience(value.ItemId) > 0
                && value.Quantity > 0);
            int materialId = material.ItemId > 0 ? material.ItemId : materialIds.FirstOrDefault();
            int perItem = Mathf.Max(1, catalog.GetRefineMaterialExperience(materialId));
            int requiredExperience = catalog.GetRefineExperience(currentLevel, item.Definition.Quality);
            int remaining = Mathf.Max(1, (requiredExperience > 0 ? requiredExperience : config?.Experience ?? perItem) - (int)item.Experience);
            int requested = Mathf.Max(1, Mathf.CeilToInt(remaining / (float)perItem));
            int count = material.Quantity > 0 ? Mathf.Min(material.Quantity, requested) : 1;
            BindRefineMaterials(materialIds);
            SetButtonLabel(refineView,
                "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/yijianjinglianBtn", "一键精炼");
            SetButtonLabel(refineView,
                "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/jinglianyijiBtn", "精炼一级");
            refineOnceButton.onClick.RemoveAllListeners();
            refineOnceButton.onClick.AddListener(() => refineEquipment?.Invoke(item.Uid, materialId, count));
            SetStrengthAllVisible(false);
            SetEquipmentCultivationSubview(1);
            refineView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowAwaken(DisplayRecord item)
        {
            if (!CanOpenCultivation(item, 2)) return;
            ShowStrength(item);
            activeCultivationMode = 2;
            showCultivationFrame?.Invoke(2, item.Kind);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/juexing")?.SetActive(true);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu")?.SetActive(false);
            int currentLevel = item.Equipment.GetLevel(3);
            EquipmentAwakenDefinition config = catalog.GetAwaken(currentLevel + 1);
            int nextLevel = config != null ? currentLevel + 1 : currentLevel;
            EquipmentAwakenDefinition currentConfig = catalog.GetAwaken(currentLevel);
            SetBoundText(awakenView, "Layer/zhuangbeijuexingUI/juexing/jichushuxing/Level_1",
                currentConfig?.Name ?? "0星0品");
            SetBoundText(awakenView, "Layer/zhuangbeijuexingUI/juexing/jichushuxing/Level_2",
                config?.Name ?? currentConfig?.Name ?? "0星0品");
            BindCultivationAttributes(awakenView,
                "Layer/zhuangbeijuexingUI/juexing/jichushuxing/ListView/Panel_1",
                item.Definition.AwakenAttributes, currentLevel, nextLevel);
            int gold = config?.Cost?.FirstOrDefault(value => value != null && value.Length >= 3 && value[0] == 60000)?[2] ?? 0;
            SetBoundText(awakenView, "Layer/zhuangbeijuexingUI/juexing/juexingxiaohao/ConsumeBg/Value", gold.ToString());
            awakenOnceButton.onClick.RemoveAllListeners();
            awakenOnceButton.onClick.AddListener(() => awakenEquipment?.Invoke(item.Uid));
            SetButtonLabel(awakenView,
                "Layer/zhuangbeijuexingUI/juexing/juexingxiaohao/yijianjinglianBtn", "觉醒");
            SetStrengthAllVisible(false);
            SetEquipmentCultivationSubview(2);
            awakenView.GameObject.transform.SetAsLastSibling();
        }

        private void ShowDivine(DisplayRecord item)
        {
            if (!CanOpenCultivation(item, 3)) return;
            ShowStrength(item);
            activeCultivationMode = 3;
            showCultivationFrame?.Invoke(3, item.Kind);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/juexing")?.SetActive(false);
            cultivateView.Binding.Find("Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu")?.SetActive(true);
            int currentLevel = item.Equipment.GetLevel(4);
            EquipmentDivineDefinition config = catalog.GetDivine(currentLevel + 1);
            int nextLevel = config != null ? currentLevel + 1 : currentLevel;
            EquipmentDivineDefinition currentConfig = catalog.GetDivine(currentLevel);
            SetBoundText(divineView, "Layer/zhuangbeijuexingUI/shenzhu/jichushuxing/Level_1",
                currentConfig?.Name ?? "0阶0层");
            SetBoundText(divineView, "Layer/zhuangbeijuexingUI/shenzhu/jichushuxing/Level_2",
                config?.Name ?? currentConfig?.Name ?? "0阶0层");
            BindCultivationAttributes(divineView,
                "Layer/zhuangbeijuexingUI/shenzhu/jichushuxing/ListView/Panel_1",
                item.Definition.DivineAttributes, currentLevel, nextLevel);
            int divineItemId = item.Definition.DivineCostItemId;
            EquipmentMaterialDefinition divineItem = catalog.GetItem(divineItemId);
            int divineOwned = bag.GetTotalQuantityByItemId(divineItemId);
            int divineRequired = config?.FragmentCount ?? 0;
            string divineItemPath = "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Item";
            string divineNamePath = "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Name";
            string divineValuePath = "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Value";
            Image divineItemIcon = divineView.Binding.Find(divineItemPath)?.GetComponent<Image>();
            bool showDivineMaterial = divineItemId > 0 && divineItem != null && divineRequired > 0
                && ApplyMaterialIcon(divineItemIcon, divineItem);
            divineView.Binding.Find(divineItemPath)?.SetActive(showDivineMaterial);
            divineView.Binding.Find(divineNamePath)?.SetActive(showDivineMaterial);
            divineView.Binding.Find(divineValuePath)?.SetActive(showDivineMaterial);
            SetBoundText(divineView, "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Name",
                divineItem?.Name ?? string.Empty);
            SetBoundText(divineView, "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Value",
                $"{divineOwned}/{divineRequired}");
            int gold = config?.Money?.FirstOrDefault(value => value != null && value.Length >= 3 && value[0] == 60000)?[2] ?? 0;
            SetBoundText(divineView, "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/ConsumeBg/Value", gold.ToString());
            divineOnceButton.onClick.RemoveAllListeners();
            divineOnceButton.onClick.AddListener(() =>
            {
                if (config == null)
                {
                    showFeedback?.Invoke("神铸已达上限");
                    return;
                }
                if (divineItemId <= 0 || divineItem == null || divineRequired <= 0)
                {
                    showFeedback?.Invoke("该装备没有有效的神铸消耗配置");
                    return;
                }
                if (divineOwned < divineRequired)
                {
                    showFeedback?.Invoke($"{divineItem.Name}不足");
                    return;
                }
                if (currencies.Gold < gold)
                {
                    showFeedback?.Invoke("金币不足");
                    return;
                }
                divineEquipment?.Invoke(item.Uid);
            });
            SetButtonLabel(divineView,
                "Layer/zhuangbeijuexingUI/shenzhu/juexingxiaohao/Btn_shenzhu", "神铸");
            SetStrengthAllVisible(false);
            BindButton(divineView, "Layer/zhuangbeijuexingUI/shenzhu/fujiashuxing/Btn_xiangxi", () =>
            {
                BindButton(divineEffectView, "Layer/Popup/Btn_close", () => divineEffectView.SetVisible(false));
                ShowPopup(divineEffectView);
            });
            SetEquipmentCultivationSubview(3);
            divineView.GameObject.transform.SetAsLastSibling();
        }

        private void SetEquipmentCultivationSubview(int mode)
        {
            strengthView.SetVisible(mode == 0);
            refineView.SetVisible(mode == 1);
            awakenView.SetVisible(mode == 2);
            divineView.SetVisible(mode == 3);
            faBaoStrengthView.SetVisible(false);
            faBaoRefineView.SetVisible(false);
        }

        private void ConfigureSecondaryControls()
        {
            BindButton(refineView, "Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/yijianjinglianBtn",
                OpenAutoRefine);
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/juexing/Btn_yijianduihuan",
                () => { BindPopupDismiss(exchangeView, false); ShowPopup(exchangeView); });
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/juexing/Btn_yijianshengxing",
                () => { BindPopupDismiss(autoStarView, false); ShowPopup(autoStarView); });
            BindButton(divineView, "Layer/zhuangbeijuexingUI/shenzhu/fujiashuxing/Btn_xiangxi",
                () =>
                {
                    BindButton(divineEffectView, "Layer/Popup/Btn_close", () => divineEffectView.SetVisible(false));
                    ShowPopup(divineEffectView);
                });
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu/Btn_yijianshengjie",
                () => { BindPopupDismiss(autoDivineView, false); ShowPopup(autoDivineView); });
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/shenzhu/Btn_yijianshengceng",
                () => { BindPopupDismiss(autoDivineView, false); ShowPopup(autoDivineView); });
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Button_L",
                () => CycleFormation(-1));
            BindButton(cultivateView, "Layer/zhuangbeiyangchengUI/zhuangbei/Panel_zhujue/Button_R",
                () => CycleFormation(1));

            BindPopupDismiss(exchangeView, false);
            BindPopupDismiss(autoStarView, false);
            BindPopupDismiss(autoDivineView, false);
            BindButton(divineEffectView, "Layer/Popup/Btn_close", () => divineEffectView.SetVisible(false));

            BindButton(autoRefineView, "Layer/Popup/Panel_1/Btn_Plus", () => SetAutoRefineLevels(autoRefineLevels + 1));
            BindButton(autoRefineView, "Layer/Popup/Panel_1/Btn_Plus10", () => SetAutoRefineLevels(autoRefineLevels + 10));
            BindButton(autoRefineView, "Layer/Popup/Panel_1/Btn_Minus", () => SetAutoRefineLevels(autoRefineLevels - 1));
            BindButton(autoRefineView, "Layer/Popup/Panel_1/Btn_Minus10", () => SetAutoRefineLevels(autoRefineLevels - 10));
            BindButton(autoRefineView, "Layer/Popup/Btn_Cancel", () => autoRefineView.SetVisible(false));
            BindButton(autoRefineView, "Layer/Popup/Btn_close", () => autoRefineView.SetVisible(false));
            BindButton(autoRefineView, "Layer/Popup/Btn_Confirm", ConfirmAutoRefine);
        }

        private void ConfigureCultivationEffects()
        {
            cultivationEffects.Clear();
            for (int index = 1; index <= 9; index++)
            {
                GameObject host = cultivateView.Binding.Find(
                    $"Layer/zhuangbeiyangchengUI/zhuangbei/effect_zhuangbeiyangcheng_{index}");
                if (host == null) continue;
                ImodAnimationPlayer player = host.GetComponent<ImodAnimationPlayer>()
                    ?? host.AddComponent<ImodAnimationPlayer>();
                if (!player.IsLoaded && !player.LoadLegacy($"res2/animation/effect_zhuangbeiyangcheng_{index}"))
                    throw new InvalidOperationException($"Equipment cultivation Imod resource {index} is missing.");
                player.Completed += _ =>
                {
                    player.Stop();
                    player.gameObject.SetActive(false);
                };
                player.Stop();
                host.SetActive(false);
                cultivationEffects.Add(player);
            }
        }

        private static bool IsChangeListCell(Transform value) => value != null
            && (IsBoundListCell(value) || value.name.StartsWith("ChangeCandidate_", StringComparison.Ordinal));

        private void ShowCultivationEffect(int index, bool repeat = false)
        {
            for (int offset = 0; offset < cultivationEffects.Count; offset++)
            {
                ImodAnimationPlayer player = cultivationEffects[offset];
                bool selectedEffect = offset + 1 == index;
                player.gameObject.SetActive(selectedEffect);
                if (selectedEffect) player.Play(0, repeat);
                else player.Stop();
            }
        }

        private void HideCultivationEffects()
        {
            foreach (ImodAnimationPlayer player in cultivationEffects)
            {
                player.Stop();
                player.gameObject.SetActive(false);
            }
        }

        private bool CanOpenCultivation(DisplayRecord item, int mode)
        {
            int minimumLevel = mode == 0 ? 6 : mode == 1 ? 30 : mode == 2 ? 50 : 70;
            if (getPlayerLevel() < minimumLevel)
            {
                showFeedback?.Invoke($"{minimumLevel}级开启");
                return false;
            }
            if (mode == 2 && item.Definition.Quality < 5)
            {
                showFeedback?.Invoke("需要橙色以上装备");
                return false;
            }
            if (mode == 3 && item.Definition.Quality < 6)
            {
                showFeedback?.Invoke("需要红色以上装备");
                return false;
            }
            if (mode == 3 && (item.Definition.DivineCostItemId <= 0
                || item.Definition.DivineAttributes == null || item.Definition.DivineAttributes.Length == 0))
            {
                showFeedback?.Invoke("该装备没有有效的神铸配置");
                return false;
            }
            return true;
        }

        private void SetStrengthAllVisible(bool visible)
        {
            GameObject strengthAll = cultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/Btn_yijianqianghua");
            if (strengthAll != null) strengthAll.SetActive(visible);
        }

        private void OpenAutoRefine()
        {
            if (selected.Uid == 0 || selected.Kind != HeroEquipmentKind.Equipment) return;
            SetBoundText(autoRefineView, "Layer/Popup/Panel_1/Name", selected.Definition.Name);
            ApplyIcon(autoRefineView.Binding.Find("Layer/Popup/Panel_1/Item")?.GetComponent<Image>(), selected);
            SetButtonLabel(autoRefineView, "Layer/Popup/Btn_Cancel", "取消");
            SetButtonLabel(autoRefineView, "Layer/Popup/Btn_Confirm", "确定");
            SetButtonLabel(autoRefineView, "Layer/Popup/Panel_1/Btn_Minus", "-1");
            SetButtonLabel(autoRefineView, "Layer/Popup/Panel_1/Btn_Minus10", "-10");
            SetButtonLabel(autoRefineView, "Layer/Popup/Panel_1/Btn_Plus", "+1");
            SetButtonLabel(autoRefineView, "Layer/Popup/Panel_1/Btn_Plus10", "+10");
            IReadOnlyList<int> materialIds = catalog.GetRefineMaterialIds();
            for (int index = 0; index < 4; index++)
            {
                string path = $"Layer/Popup/Panel_2/Item_{index + 1}";
                GameObject slot = autoRefineView.Binding.Find(path);
                if (slot == null) continue;
                EquipmentMaterialDefinition material = index < materialIds.Count
                    ? catalog.GetItem(materialIds[index]) : null;
                slot.SetActive(material != null);
                if (material == null) continue;
                SetBoundText(autoRefineView, path + "/Value",
                    bag.GetTotalQuantityByItemId(material.Id).ToString());
                ApplyMaterialIcon(EnsureMaterialIcon(slot.transform), material);
            }
            autoRefineLevels = 1;
            SetAutoRefineLevels(1);
            ShowPopup(autoRefineView);
        }

        private void SetAutoRefineLevels(int value)
        {
            autoRefineLevels = Mathf.Clamp(value, 1, 50);
            SetBoundText(autoRefineView, "Layer/Popup/Panel_1/Count/Value", autoRefineLevels.ToString());
        }

        private void ConfirmAutoRefine()
        {
            if (selected.Uid == 0 || selected.Kind != HeroEquipmentKind.Equipment) return;
            int need = -unchecked((int)selected.Experience);
            for (int level = selected.RefineLevel; level < selected.RefineLevel + autoRefineLevels; level++)
                need += catalog.GetRefineExperience(level, selected.Definition.Quality);
            int remaining = Mathf.Max(1, need);
            int[] itemIds = new int[4];
            int[] itemCounts = new int[4];
            int materialIndex = 0;
            foreach (BagItemRecord material in bag.GetItemsByType(4)
                .Where(value => catalog.GetRefineMaterialExperience(value.ItemId) > 0 && value.Quantity > 0)
                .OrderByDescending(value => catalog.GetRefineMaterialExperience(value.ItemId))
                .ThenBy(value => value.ItemId))
            {
                if (materialIndex >= itemIds.Length || remaining <= 0) break;
                int perItem = catalog.GetRefineMaterialExperience(material.ItemId);
                int count = Mathf.Clamp(Mathf.CeilToInt(remaining / (float)perItem), 1, material.Quantity);
                itemIds[materialIndex] = material.ItemId;
                itemCounts[materialIndex] = count;
                remaining -= count * perItem;
                materialIndex++;
            }
            autoRefineView.SetVisible(false);
            if (materialIndex > 0) autoRefineEquipment?.Invoke(selected.Uid, itemIds, itemCounts);
        }

        private void CycleFormation(int delta)
        {
            int next = formationPosition;
            for (int attempt = 0; attempt < 5; attempt++)
            {
                next = (next - 1 + delta + 5) % 5 + 1;
                HeroEquipmentRecord value = equipment.Items.FirstOrDefault(item => item.FormationPosition == next);
                if (value.Uid == 0) continue;
                formationPosition = next;
                ShowStrength(new DisplayRecord(value));
                return;
            }
        }

        private static void BindButton(CocosUiView view, string path, UnityEngine.Events.UnityAction action)
        {
            GameObject target = view?.Binding.Find(path);
            if (target == null) return;
            Button button = EnsureClickable(target.transform);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(action);
        }

        private static void BindPopupDismiss(CocosUiView view, bool confirmWrites)
        {
            if (view == null) return;
            BindButton(view, "Layer/Popup/Btn_close", () => view.SetVisible(false));
            BindButton(view, "Layer/Popup/Btn_Cancel", () => view.SetVisible(false));
            if (!confirmWrites) BindButton(view, "Layer/Popup/Btn_Confirm", () => view.SetVisible(false));
        }

        private static void ShowPopup(CocosUiView view)
        {
            if (view == null) return;
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        private void BindStrengthTargets(DisplayRecord current)
        {
            DisplayRecord[] targets = equipment.Items
                .Select(value => new DisplayRecord(value))
                .Where(value => value.FormationPosition == formationPosition)
                .OrderBy(value => value.Slot)
                .Take(4)
                .ToArray();
            GameObject template = cultivateView.Binding.Find(
                "Layer/zhuangbeiyangchengUI/zhuangbei/List/item_layer");
            if (template == null) return;
            Transform parent = template.transform.parent;
            foreach (Transform child in parent.Cast<Transform>()
                .Where(value => value.name.StartsWith("RuntimeStrengthTarget_", StringComparison.Ordinal))
                .ToArray())
                UnityEngine.Object.Destroy(child.gameObject);
            if (targets.Length == 0)
            {
                template.SetActive(false);
                return;
            }
            RectTransform templateRect = template.GetComponent<RectTransform>();
            Vector2 start = templateRect != null ? templateRect.anchoredPosition : Vector2.zero;
            for (int index = 0; index < targets.Length; index++)
            {
                Transform slot = index == 0 ? template.transform
                    : UnityEngine.Object.Instantiate(template, parent, false).transform;
                DisplayRecord target = targets[index];
                slot.name = index == 0 ? "item_layer" : $"RuntimeStrengthTarget_{index}";
                foreach (Transform marker in slot.Cast<Transform>()
                    .Where(value => value.name.StartsWith("StrengthTargetUid_", StringComparison.Ordinal)).ToArray())
                    UnityEngine.Object.Destroy(marker.gameObject);
                var markerObject = new GameObject($"StrengthTargetUid_{target.Uid}", typeof(RectTransform));
                markerObject.transform.SetParent(slot, false);
                RectTransform rect = slot as RectTransform;
                if (rect != null) rect.anchoredPosition = start + new Vector2(index * 88f, 0f);
                slot.gameObject.SetActive(true);
                ApplyIcon(slot.Find("zhuangbeiIcon")?.GetComponent<Image>(), target);
                Transform choose = slot.Find("Choose");
                if (choose != null) choose.gameObject.SetActive(target.Uid == current.Uid);
                Button button = EnsureClickable(slot);
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => ShowStrength(target));
            }
        }

        private void BindRefineMaterials(IReadOnlyList<int> materialIds)
        {
            for (int index = 0; index < 4; index++)
            {
                string path = $"Layer/zhuangbeijinglianUI/jinglian/jinglianxiaohao/Item_{index + 1}";
                GameObject slot = refineView.Binding.Find(path);
                if (slot == null) continue;
                EquipmentMaterialDefinition material = index < materialIds.Count
                    ? catalog.GetItem(materialIds[index]) : null;
                slot.SetActive(material != null);
                if (material == null) continue;
                SetBoundText(refineView, path + "/Value",
                    bag.GetTotalQuantityByItemId(material.Id).ToString());
                SetBoundText(refineView, path + "/Text", $"经验+{material.RefineExperience}");
                ApplyMaterialIcon(EnsureMaterialIcon(slot.transform), material);
            }
        }

        private static void BindCultivationAttributes(CocosUiView view, string templatePath,
            IReadOnlyList<int[]> attributes, int currentLevel, int nextLevel)
        {
            GameObject templateObject = view.Binding.Find(templatePath);
            if (templateObject == null) return;
            Transform template = templateObject.transform;
            Transform parent = template.parent;
            foreach (Transform child in parent.Cast<Transform>()
                .Where(value => value.name.StartsWith("RuntimeCultivationAttribute_", StringComparison.Ordinal))
                .ToArray())
            {
                child.gameObject.SetActive(false);
                UnityEngine.Object.Destroy(child.gameObject);
            }

            int[][] validAttributes = attributes == null
                ? Array.Empty<int[]>()
                : attributes.Where(value => value != null && value.Length >= 2).ToArray();
            templateObject.SetActive(validAttributes.Length > 0);
            if (validAttributes.Length == 0) return;

            RectTransform templateRect = template.GetComponent<RectTransform>();
            Vector2 start = templateRect != null ? templateRect.anchoredPosition : Vector2.zero;
            float rowHeight = templateRect != null ? Mathf.Max(1f, templateRect.rect.height) : 35f;
            bool isMax = nextLevel <= currentLevel;
            for (int index = 0; index < validAttributes.Length; index++)
            {
                Transform row = index == 0 ? template
                    : UnityEngine.Object.Instantiate(template, parent, false);
                row.name = index == 0 ? template.name : $"RuntimeCultivationAttribute_{index}";
                RectTransform rowRect = row.GetComponent<RectTransform>();
                if (rowRect != null) rowRect.anchoredPosition = start + new Vector2(0f, -rowHeight * index);
                row.gameObject.SetActive(true);

                int type = validAttributes[index][0];
                int perLevel = validAttributes[index][1];
                SetText(row, "Value_0", AttributeName(type));
                SetText(row, "Value_1", checked(perLevel * currentLevel).ToString());
                SetText(row, "Value_2", checked(perLevel * nextLevel).ToString());
                SetText(row, "Value_3", perLevel.ToString());
                SetActive(row, "Image", !isMax);
                SetActive(row, "To", !isMax);
                SetActive(row, "Value_2", !isMax);
                SetActive(row, "Value_3", !isMax);
            }
        }

        private static Image EnsureMaterialIcon(Transform slot)
        {
            Transform existing = slot.Find("RuntimeMaterialIcon");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeMaterialIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(slot, false);
            rect.anchorMin = new Vector2(0.08f, 0.08f);
            rect.anchorMax = new Vector2(0.92f, 0.92f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.SetAsFirstSibling();
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private bool ApplyMaterialIcon(Image image, EquipmentMaterialDefinition material)
        {
            if (image == null) return false;
            bool usedPlaceholder = false;
            Sprite sprite = material != null && material.Picture > 0
                ? resources.LoadItemIcon(material.Picture, out usedPlaceholder) : null;
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            return image.enabled;
        }

        private static void SetButtonLabel(CocosUiView view, string path, string value)
        {
            GameObject target = view?.Binding.Find(path);
            if (target == null) return;
            Text label = target.GetComponentsInChildren<Text>(true).FirstOrDefault();
            if (label == null)
            {
                GameObject labelObject = new GameObject("RuntimeLabel",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                RectTransform rect = labelObject.GetComponent<RectTransform>();
                rect.SetParent(target.transform, false);
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                label = labelObject.GetComponent<Text>();
                label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                label.fontSize = 24;
                label.color = new Color(0.55f, 0.18f, 0.04f, 1f);
            }
            label.text = value;
            label.alignment = TextAnchor.MiddleCenter;
            label.horizontalOverflow = HorizontalWrapMode.Overflow;
            label.verticalOverflow = VerticalWrapMode.Overflow;
            label.raycastTarget = false;
            label.gameObject.SetActive(true);
        }

        private bool IsMissing(DisplayRecord item)
        {
            bool placeholder;
            if (item.Kind == HeroEquipmentKind.FaBao)
                resources.LoadFaBaoIcon(item.Definition.Picture, out placeholder);
            else
                resources.LoadEquipmentIcon(item.Definition.Picture, out placeholder);
            return placeholder;
        }

        private void ApplyIcon(Image image, DisplayRecord item)
        {
            if (image == null) return;
            image.sprite = item.Kind == HeroEquipmentKind.FaBao
                ? resources.LoadFaBaoIcon(item.Definition.Picture, out _)
                : resources.LoadEquipmentIcon(item.Definition.Picture);
            image.enabled = image.sprite != null;
            image.preserveAspect = true;
            RectTransform rect = image.rectTransform;
            bool isDetail = image == detailIcon;
            float size = isDetail ? (item.Kind == HeroEquipmentKind.FaBao ? 100f : 140f) : 100f;
            rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, size);
            rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, size);
            if (isDetail && detailQualityFrame != null)
                detailQualityFrame.gameObject.SetActive(item.Kind == HeroEquipmentKind.FaBao
                    && detailQualityFrame.sprite != null);
        }

        private static Image EnsureDetailQualityFrame(Transform host)
        {
            Transform existing = host.Find("RuntimeEquipmentDetailQualityFrame");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeEquipmentDetailQualityFrame",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(140f, 140f);
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            image.preserveAspect = true;
            image.sprite = Resources.FindObjectsOfTypeAll<Sprite>()
                .FirstOrDefault(sprite => sprite != null && sprite.name == "ui_common_icon_kuang_03");
            value.SetActive(false);
            return image;
        }

        private static Image EnsureDetailIcon(Transform host)
        {
            Transform existing = host.Find("RuntimeEquipmentDetailIcon");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeEquipmentDetailIcon",
                    typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(140f, 140f);
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            image.preserveAspect = true;
            return image;
        }

        private void ConfigureDetailListLayout()
        {
            GameObject viewportObject = Require(detailView, "Layer/zhuangbeiInfoUI/Info/ListView");
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            Transform existing = viewport.Find("RuntimeDetailContent");
            GameObject contentObject = existing != null ? existing.gameObject
                : new GameObject("RuntimeDetailContent", typeof(RectTransform),
                    typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.SetParent(viewport, false);
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;

            VerticalLayoutGroup layout = contentObject.GetComponent<VerticalLayoutGroup>();
            layout.padding = new RectOffset();
            layout.spacing = 0f;
            layout.childAlignment = TextAnchor.UpperCenter;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;

            ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            string[] sections =
            {
                "jichushuxing", "qianghuashuxing", "jinglianshuxing",
                "juexingshuxing", "shenzhushuxing", "zhuangbeitaozhuang",
                "zhuangbeimiaoshu",
            };
            foreach (string section in sections)
            {
                GameObject node = detailView.Binding.Find($"Layer/zhuangbeiInfoUI/Info/{section}");
                if (node != null)
                    node.transform.SetParent(content, false);
            }

            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>();
            if (scroll != null)
            {
                scroll.viewport = viewport;
                scroll.content = content;
                scroll.horizontal = false;
                scroll.vertical = true;
            }
        }

        private void ConfigureBuildRecommendation()
        {
            Transform content = detailView.GameObject.GetComponentsInChildren<Transform>(true)
                .First(value => value.name == "RuntimeDetailContent");
            Transform existing = content.Find("RuntimeBuildRecommendation");
            GameObject row = existing != null ? existing.gameObject
                : new GameObject("RuntimeBuildRecommendation", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Text), typeof(LayoutElement));
            RectTransform rect = row.GetComponent<RectTransform>();
            rect.SetParent(content, false);
            rect.sizeDelta = new Vector2(410f, 60f);
            buildRecommendationText = row.GetComponent<Text>();
            buildRecommendationText.font = detailDescription.font;
            buildRecommendationText.fontSize = 20;
            buildRecommendationText.color = new Color32(120, 84, 60, 255);
            buildRecommendationText.alignment = TextAnchor.UpperLeft;
            buildRecommendationText.horizontalOverflow = HorizontalWrapMode.Wrap;
            buildRecommendationText.verticalOverflow = VerticalWrapMode.Overflow;
            buildRecommendationText.raycastTarget = false;
            row.SetActive(false);
        }

        private void RefreshBuildRecommendation(DisplayRecord item)
        {
            bool visible = item.Kind == HeroEquipmentKind.Equipment && item.Equipment.Affix.IsValid;
            buildRecommendationText.gameObject.SetActive(visible);
            if (!visible) return;
            int heroId = item.FormationPosition > 0
                ? getHeroAtDisplayPosition?.Invoke(item.FormationPosition) ?? 0 : 0;
            buildRecommendationText.text = HeroBuildRecommendation.Describe(
                HeroBuildProfileCatalog.Profiles, heroId, item.Equipment.Affix.Key);
            float height = Mathf.Max(60f, buildRecommendationText.preferredHeight + 20f);
            buildRecommendationText.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, height);
            LayoutElement element = buildRecommendationText.GetComponent<LayoutElement>();
            element.preferredWidth = 410f;
            element.preferredHeight = height;
            LayoutRebuilder.MarkLayoutForRebuild(buildRecommendationText.rectTransform.parent as RectTransform);
        }

        private void ConfigureAffixActions()
        {
            Transform content = detailView.GameObject.GetComponentsInChildren<Transform>(true)
                .FirstOrDefault(value => value.name == "RuntimeDetailContent");
            if (content == null) throw new InvalidOperationException("RuntimeDetailContent was not created.");
            Transform existing = content.Find("RuntimeAffixActions");
            affixActionRow = existing != null ? existing.gameObject
                : new GameObject("RuntimeAffixActions", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(LayoutElement));
            RectTransform rect = affixActionRow.GetComponent<RectTransform>();
            rect.SetParent(content, false);
            rect.sizeDelta = new Vector2(440f, 72f);
            LayoutElement element = affixActionRow.GetComponent<LayoutElement>();
            element.preferredWidth = 440f;
            element.preferredHeight = 72f;
            HorizontalLayoutGroup layout = affixActionRow.GetComponent<HorizontalLayoutGroup>();
            layout.padding = new RectOffset(20, 20, 10, 10);
            layout.spacing = 24f;
            layout.childAlignment = TextAnchor.MiddleCenter;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
            affixLockButton = EnsureRuntimeAffixButton(affixActionRow.transform, "AffixLockButton");
            affixRerollButton = EnsureRuntimeAffixButton(affixActionRow.transform, "AffixRerollButton");
            affixActionRow.SetActive(false);
        }

        private static Button EnsureRuntimeAffixButton(Transform parent, string name)
        {
            Transform existing = parent.Find(name);
            GameObject value = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button), typeof(LayoutElement));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.sizeDelta = new Vector2(185f, 52f);
            LayoutElement element = value.GetComponent<LayoutElement>();
            element.preferredWidth = 185f;
            element.preferredHeight = 52f;
            Image image = value.GetComponent<Image>();
            image.color = new Color(0.95f, 0.63f, 0.25f, 1f);
            Button button = value.GetComponent<Button>();
            Transform labelTransform = value.transform.Find("Label");
            GameObject labelObject = labelTransform != null ? labelTransform.gameObject
                : new GameObject("Label", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform labelRect = labelObject.GetComponent<RectTransform>();
            labelRect.SetParent(value.transform, false);
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 22;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = new Color(0.35f, 0.12f, 0.04f, 1f);
            return button;
        }

        private static void SetRuntimeButtonLabel(Button button, string value)
        {
            Text label = button?.GetComponentInChildren<Text>(true);
            if (label != null) label.text = value;
        }

        private static string AffixBuildRecommendation(string key)
        {
            string prefix = string.IsNullOrEmpty(key) ? string.Empty : key.Split('-')[0];
            switch (prefix)
            {
                case "SHIELD": return "护盾守护流｜护盾、援护、减伤";
                case "HEAL": return "治疗复苏流｜治疗、净化、复活";
                case "GUARD": return "嘲讽承伤流｜前排坦克、援护";
                case "COUNTER": return "反击荆棘流｜受击反打、分伤";
                case "CRIT": return "暴击斩杀流｜单体爆发、收割";
                case "COMBO": return "连击追击流｜普攻连段、追加行动";
                case "BREAK": return "破盾破法流｜穿透、驱盾、法术爆发";
                case "CONTROL": return "控制先手流｜眩晕、沉默、速度压制";
                case "DOT": return "持续伤害流｜毒、灼烧、异常扩散";
                case "DEBUFF": return "弱化禁疗流｜减益、禁疗、易伤";
                case "DEATH": return "献祭召唤流｜死亡触发、召唤";
                case "TACTIC": return "战意战法流｜战法循环、团队辅助";
                default: return "通用构筑｜按神将技能标签搭配";
            }
        }

        private void ConfigureCultivationButtons()
        {
            foreach (string path in new[]
            {
                "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian",
                "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing",
                "Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu",
            })
            {
                GameObject button = detailView.Binding.Find(path);
                if (button != null) button.SetActive(true);
            }
        }

        private void BindDetailCultivationButton(string path, bool visible, UnityEngine.Events.UnityAction action)
        {
            Button button = detailView.Binding.Find(path)?.GetComponent<Button>();
            if (button == null) return;
            button.gameObject.SetActive(visible);
            button.onClick.RemoveAllListeners();
            if (visible) button.onClick.AddListener(action);
        }

        private void SetSectionVisible(string section, bool visible)
        {
            foreach (string path in new[]
            {
                $"Layer/zhuangbeiInfoUI/Info/{section}",
                $"Layer/zhuangbeiInfoUI/Info/ListView/{section}",
            })
            {
                GameObject value = detailView.Binding.Find(path);
                if (value != null) value.SetActive(visible);
            }

            GameObject info = detailView.Binding.Find("Layer/zhuangbeiInfoUI/Info");
            if (info == null) return;
            foreach (Transform value in info.GetComponentsInChildren<Transform>(true))
                if (value.name == section) value.gameObject.SetActive(visible);
        }

        private void SetDetailText(string path, string value)
        {
            Text text = detailView.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static string AttributeName(int type)
        {
            switch (type)
            {
                case 1: return "攻击";
                case 2: return "物防";
                case 3: return "法防";
                case 4: return "生命";
                case 5: return "速度";
                case 6: return "命中";
                case 7: return "闪避";
                case 8: return "暴击";
                case 9: return "抗暴";
                case 10: return "攻击加成";
                case 11: return "物防加成";
                case 12: return "法防加成";
                case 13: return "生命加成";
                case 14: return "速度加成";
                case 15: return "命中率";
                case 16: return "闪避率";
                case 17: return "暴击率";
                case 18: return "抗暴率";
                default: return "基础属性";
            }
        }

        private static void SetActive(Transform root, string path, bool value)
        {
            Transform target = root.Find(path);
            if (target != null) target.gameObject.SetActive(value);
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static void SetBoundText(CocosUiView view, string path, string value)
        {
            Text text = view.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static GameObject Require(CocosUiView view, string path)
            => view.Binding.Find(path) ?? throw new InvalidOperationException($"Hero equipment UI node was not found: {path}");
        private static Text RequireText(CocosUiView view, string path)
            => Require(view, path).GetComponent<Text>() ?? throw new InvalidOperationException($"Hero equipment UI text was not found: {path}");
        private static Button RequireButton(CocosUiView view, string path)
            => EnsureClickable(Require(view, path).transform);

        private static Button EnsureClickable(Transform target)
        {
            Graphic graphic = target.GetComponent<Graphic>();
            if (graphic == null)
            {
                Image image = target.gameObject.AddComponent<Image>();
                image.color = new Color(1f, 1f, 1f, 0.01f);
                graphic = image;
            }
            graphic.enabled = true;
            graphic.raycastTarget = true;
            if (graphic is Image imageGraphic && imageGraphic.color.a <= 0.001f)
                imageGraphic.color = new Color(imageGraphic.color.r, imageGraphic.color.g, imageGraphic.color.b, 0.01f);
            CanvasGroup canvasGroup = target.GetComponent<CanvasGroup>();
            if (canvasGroup != null) canvasGroup.blocksRaycasts = true;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.enabled = true;
            button.targetGraphic = graphic;
            return button;
        }

    }
}
