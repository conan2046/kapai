using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
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
        private readonly HeroEquipmentStore equipment;
        private readonly FaBaoStore faBao;
        private readonly EquipmentCatalog catalog;
        private readonly Core.ResourceService resources;
        private readonly Action<uint, int> wearEquipment;
        private readonly Action<uint, int> takeOffEquipment;
        private readonly Action<uint> strengthEquipment;
        private readonly Action<uint, int> wearFaBao;
        private readonly Action<uint> takeOffFaBao;
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
        private readonly Button wearButton;
        private readonly Button takeOffButton;
        private readonly Button strengthButton;
        private readonly Button strengthOnceButton;
        private readonly List<DisplayRecord> items = new List<DisplayRecord>();
        private readonly List<DisplayPair> rows = new List<DisplayPair>();
        private DisplayRecord selected;
        private HeroEquipmentKind activeKind = HeroEquipmentKind.Equipment;
        private int formationPosition = 1;
        private int missingIconCount;

        public HeroEquipmentPresenter(CocosUiView listView, CocosUiView detailView, CocosUiView changeView,
            CocosUiView cultivateView, CocosUiView strengthView,
            HeroEquipmentStore equipment, FaBaoStore faBao, EquipmentCatalog catalog, Core.ResourceService resources,
            Action<uint, int> wearEquipment, Action<uint, int> takeOffEquipment,
            Action<uint> strengthEquipment,
            Action<uint, int> wearFaBao, Action<uint> takeOffFaBao)
        {
            this.listView = listView ?? throw new ArgumentNullException(nameof(listView));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.changeView = changeView ?? throw new ArgumentNullException(nameof(changeView));
            this.cultivateView = cultivateView ?? throw new ArgumentNullException(nameof(cultivateView));
            this.strengthView = strengthView ?? throw new ArgumentNullException(nameof(strengthView));
            this.equipment = equipment ?? throw new ArgumentNullException(nameof(equipment));
            this.faBao = faBao ?? throw new ArgumentNullException(nameof(faBao));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.wearEquipment = wearEquipment;
            this.takeOffEquipment = takeOffEquipment;
            this.strengthEquipment = strengthEquipment;
            this.wearFaBao = wearFaBao;
            this.takeOffFaBao = takeOffFaBao;

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
            Require(listView, "Layer/zhuangbeibeibaoUI/cell").SetActive(false);
            hideWornToggle = Require(listView, "Layer/zhuangbeibeibaoUI/CheckBox");
            Toggle hideWorn = hideWornToggle.GetComponent<Toggle>();
            if (hideWorn != null) hideWorn.isOn = false;

            detailName = RequireText(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Namebg/Name");
            detailDescription = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/zhuangbeimiaoshu/Content");
            detailBaseAttribute = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1/Value");
            detailStrength = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Level/Value");
            detailRefine = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Level/Value");
            detailIcon = Require(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Bg/Image").GetComponent<Image>();
            wearButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan");
            takeOffButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_xiexia");
            strengthButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua");
            strengthOnceButton = RequireButton(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghuaBtn");
            GameObject strengthFive = strengthView.Binding.Find("Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/qianghua5Btn");
            if (strengthFive != null) strengthFive.SetActive(false);
            cultivateView.SetVisible(false);
            strengthView.SetVisible(false);
            changeView.SetVisible(false);
            Button close = RequireButton(detailView, "Layer/zhuangbeiInfoUI/Popup/Btn_close");
            close.onClick.RemoveAllListeners();
            close.onClick.AddListener(HideDetails);
            DisableCultivationButtons();

            equipment.Changed += Render;
            faBao.Changed += Render;
            Render();
        }

        public int ItemCount => items.Count;
        public int MissingIconCount => missingIconCount;
        public bool IsDetailVisible => detailView.GameObject.activeSelf;

        public void Show(int selectedFormationPosition, HeroEquipmentKind kind = HeroEquipmentKind.Equipment)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            activeKind = kind;
            Render();
            listView.SetVisible(true);
            if (items.Count > 0) ShowDetails(items[0]);
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
            detailView.SetVisible(false);
            changeView.SetVisible(false);
            strengthView.SetVisible(false);
            cultivateView.SetVisible(false);
        }

        public void Render()
        {
            uint selectedUid = selected.Uid;
            HeroEquipmentKind selectedKind = selected.Kind;
            items.Clear();
            if (activeKind == HeroEquipmentKind.Equipment)
                items.AddRange(equipment.Items.Select(value => new DisplayRecord(value)));
            else
                items.AddRange(faBao.Items.Select(value => new DisplayRecord(value)));
            number.text = activeKind == HeroEquipmentKind.Equipment
                ? $"数量：{equipment.Count}/1000" : $"数量：{faBao.Count}/999";
            recycleButton.SetActive(activeKind == HeroEquipmentKind.Equipment);
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
                if (index >= 0) ShowDetails(items[index]);
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
            Transform first = row.Find("Item1");
            Transform second = row.Find("Item2");
            if (first == null) throw new InvalidOperationException("Equipment list template Item1 was not found.");
            BindCell(first, pair.First);
            if (second != null)
            {
                second.gameObject.SetActive(pair.HasSecond);
                if (pair.HasSecond) BindCell(second, pair.Second);
            }
            row.gameObject.name = $"{activeKind}_Row_{index}";
        }

        private void BindCell(Transform cell, DisplayRecord item)
        {
            cell.gameObject.SetActive(true);
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
            Button button = cell.GetComponent<Button>() ?? cell.gameObject.AddComponent<Button>();
            button.targetGraphic = cell.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => ShowDetails(item));
            Button cultivate = cell.Find("Btn_yangcheng")?.GetComponent<Button>();
            if (cultivate != null)
            {
                cultivate.gameObject.SetActive(true);
                cultivate.onClick.RemoveAllListeners();
                cultivate.onClick.AddListener(() => ShowDetails(item));
            }
        }

        private void ShowDetails(DisplayRecord item)
        {
            selected = item;
            detailName.text = item.Definition.Name;
            detailDescription.text = string.IsNullOrEmpty(item.Definition.Description)
                ? $"模板：{item.Definition.Id}　品质：{item.Definition.Quality}　槽位：{item.Slot}"
                : item.Definition.Description;
            int attrType = item.Kind == HeroEquipmentKind.Equipment
                ? item.Equipment.BaseAttributeType
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 0 ? item.Definition.BaseAttribute[0] : 0;
            uint attrValue = item.Kind == HeroEquipmentKind.Equipment
                ? item.Equipment.BaseAttributeValue
                : item.Definition.BaseAttribute != null && item.Definition.BaseAttribute.Length > 1
                    ? unchecked((uint)item.Definition.BaseAttribute[1]) : 0;
            detailBaseAttribute.text = $"{AttributeName(attrType)}：{attrValue}";
            detailStrength.text = item.StrengthLevel.ToString();
            detailRefine.text = item.RefineLevel.ToString();
            ApplyIcon(detailIcon, item);
            bool worn = item.FormationPosition > 0;
            wearButton.gameObject.SetActive(true);
            takeOffButton.gameObject.SetActive(worn);
            wearButton.onClick.RemoveAllListeners();
            takeOffButton.onClick.RemoveAllListeners();
            strengthButton.onClick.RemoveAllListeners();
            strengthButton.gameObject.SetActive(item.Kind == HeroEquipmentKind.Equipment);
            SetSectionVisible("jichushuxing", true);
            SetSectionVisible("qianghuashuxing", item.Kind == HeroEquipmentKind.Equipment);
            SetSectionVisible("jinglianshuxing", false);
            SetSectionVisible("juexingshuxing", false);
            SetSectionVisible("shenzhushuxing", false);
            if (item.Kind == HeroEquipmentKind.Equipment)
            {
                wearButton.onClick.AddListener(() => ShowChange(item));
                takeOffButton.onClick.AddListener(() => takeOffEquipment?.Invoke(item.Uid, item.FormationPosition));
                strengthButton.onClick.AddListener(() => ShowStrength(item));
            }
            else
            {
                wearButton.onClick.AddListener(() => ShowChange(item));
                takeOffButton.onClick.AddListener(() => takeOffFaBao?.Invoke(item.Uid));
            }
            detailView.SetVisible(true);
        }

        private void ShowChange(DisplayRecord current)
        {
            List<DisplayRecord> candidates = current.Kind == HeroEquipmentKind.Equipment
                ? equipment.Items.Where(value => value.FormationPosition == 0 && value.Slot == current.Slot)
                    .Select(value => new DisplayRecord(value)).ToList()
                : faBao.Items.Where(value => value.FormationPosition == 0)
                    .Select(value => new DisplayRecord(value)).ToList();
            if (current.FormationPosition == 0 && candidates.All(value => value.Uid != current.Uid)) candidates.Insert(0, current);
            List<DisplayPair> candidateRows = new List<DisplayPair>();
            for (int index = 0; index < candidates.Count; index += 2)
                candidateRows.Add(new DisplayPair(candidates[index], index + 1 < candidates.Count ? candidates[index + 1] : default,
                    index + 1 < candidates.Count));
            changeList.SetItems(candidateRows);
            Text title = RequireText(changeView, "Layer/Popup/Title/Title");
            title.text = current.Kind == HeroEquipmentKind.Equipment ? "装备更换" : "法宝更换";
            changeView.SetVisible(true);
            changeView.GameObject.transform.SetAsLastSibling();
        }

        private void BindChangeRow(RectTransform row, DisplayPair pair, int index)
        {
            BindChangeCell(row.Find("Item1"), pair.First);
            Transform second = row.Find("Item2");
            if (second != null)
            {
                second.gameObject.SetActive(pair.HasSecond);
                if (pair.HasSecond) BindChangeCell(second, pair.Second);
            }
        }

        private void BindChangeCell(Transform cell, DisplayRecord item)
        {
            BindCell(cell, item);
            Button action = cell.Find("Btn_yangcheng")?.GetComponent<Button>();
            if (action == null) return;
            action.gameObject.SetActive(true);
            Text label = action.GetComponentInChildren<Text>(true);
            if (label != null) label.text = "穿戴";
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
            int currentLevel = item.StrengthLevel;
            int nextLevel = Mathf.Min(currentLevel + 1, catalog.MaxStrengthLevel);
            SetText(strengthView.Binding.transform, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/Level_1", $"当前等级 {currentLevel}");
            SetText(strengthView.Binding.transform, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/Level_2", $"下一等级 {nextLevel}");
            int[] strengthAttribute = item.Definition.GetPrimaryStrengthAttribute();
            int attrType = strengthAttribute.Length >= 2 ? strengthAttribute[0] : item.Equipment.BaseAttributeType;
            int perLevel = strengthAttribute.Length >= 2 ? strengthAttribute[1] : 0;
            Transform panel = Require(strengthView, "Layer/zhuangbeiqianghuaUI/qianghua/jichushuxing/ListView/Panel_1").transform;
            SetText(panel, "Value_0", AttributeName(attrType));
            SetText(panel, "Value_1", (perLevel * currentLevel).ToString());
            SetText(panel, "Value_2", (perLevel * nextLevel).ToString());
            SetText(panel, "Value_3", perLevel.ToString());
            SetText(strengthView.Binding.transform, "Layer/zhuangbeiqianghuaUI/qianghua/qianghuaxiaohao/ConsumeBg/Value",
                catalog.GetStrengthCost(nextLevel, item.Definition.Quality).ToString());
            strengthOnceButton.onClick.RemoveAllListeners();
            strengthOnceButton.onClick.AddListener(() => strengthEquipment?.Invoke(item.Uid));
            cultivateView.SetVisible(true);
            strengthView.SetVisible(true);
            cultivateView.GameObject.transform.SetAsLastSibling();
            strengthView.GameObject.transform.SetAsLastSibling();
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
            rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, 100f);
            rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, 100f);
        }

        private void DisableCultivationButtons()
        {
            foreach (string path in new[]
            {
                "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian",
                "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing",
                "Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu",
            })
            {
                GameObject button = detailView.Binding.Find(path);
                if (button != null) button.SetActive(false);
            }
        }

        private void SetSectionVisible(string section, bool visible)
        {
            GameObject value = detailView.Binding.Find($"Layer/zhuangbeiInfoUI/Info/{section}")
                ?? detailView.Binding.Find($"Layer/zhuangbeiInfoUI/Info/ListView/{section}");
            if (value != null) value.SetActive(visible);
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
                default: return "基础属性";
            }
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static GameObject Require(CocosUiView view, string path)
            => view.Binding.Find(path) ?? throw new InvalidOperationException($"Hero equipment UI node was not found: {path}");
        private static Text RequireText(CocosUiView view, string path)
            => Require(view, path).GetComponent<Text>() ?? throw new InvalidOperationException($"Hero equipment UI text was not found: {path}");
        private static Button RequireButton(CocosUiView view, string path)
            => Require(view, path).GetComponent<Button>() ?? Require(view, path).AddComponent<Button>();
    }
}
