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

        private readonly CocosUiView listView;
        private readonly CocosUiView detailView;
        private readonly HeroEquipmentStore equipment;
        private readonly FaBaoStore faBao;
        private readonly Core.ResourceService resources;
        private readonly Action<uint, int> wearEquipment;
        private readonly Action<uint, int> takeOffEquipment;
        private readonly Action<uint, int, int> wearFaBao;
        private readonly Action<uint> takeOffFaBao;
        private readonly VirtualList<DisplayRecord> list;
        private readonly Text number;
        private readonly GameObject emptyState;
        private readonly Text detailName;
        private readonly Text detailDescription;
        private readonly Text detailBaseAttribute;
        private readonly Text detailStrength;
        private readonly Text detailRefine;
        private readonly Image detailIcon;
        private readonly Button wearButton;
        private readonly Button takeOffButton;
        private readonly List<DisplayRecord> items = new List<DisplayRecord>();
        private DisplayRecord selected;
        private int formationPosition = 1;
        private int missingIconCount;

        public HeroEquipmentPresenter(CocosUiView listView, CocosUiView detailView,
            HeroEquipmentStore equipment, FaBaoStore faBao, Core.ResourceService resources,
            Action<uint, int> wearEquipment, Action<uint, int> takeOffEquipment,
            Action<uint, int, int> wearFaBao, Action<uint> takeOffFaBao)
        {
            this.listView = listView ?? throw new ArgumentNullException(nameof(listView));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.equipment = equipment ?? throw new ArgumentNullException(nameof(equipment));
            this.faBao = faBao ?? throw new ArgumentNullException(nameof(faBao));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.wearEquipment = wearEquipment;
            this.takeOffEquipment = takeOffEquipment;
            this.wearFaBao = wearFaBao;
            this.takeOffFaBao = takeOffFaBao;

            GameObject viewport = Require(listView, "Layer/zhuangbeibeibaoUI/TableView");
            GameObject template = Require(listView, "Layer/zhuangbeibeibaoUI/ItemList");
            float height = Mathf.Max(120f, template.GetComponent<RectTransform>().rect.height);
            list = new VirtualList<DisplayRecord>(viewport, template, height, BindRow);
            number = RequireText(listView, "Layer/zhuangbeibeibaoUI/Number");
            emptyState = Require(listView, "Layer/zhuangbeibeibaoUI/Point");
            Require(listView, "Layer/zhuangbeibeibaoUI/recycle").SetActive(false);
            Require(listView, "Layer/zhuangbeibeibaoUI/cell").SetActive(false);
            Require(listView, "Layer/zhuangbeibeibaoUI/CheckBox").SetActive(false);

            detailName = RequireText(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Namebg/Name");
            detailDescription = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/zhuangbeimiaoshu/Content");
            detailBaseAttribute = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jichushuxing/Atrribute_1/Value");
            detailStrength = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Level/Value");
            detailRefine = RequireText(detailView, "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Level/Value");
            detailIcon = Require(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Bg/Image").GetComponent<Image>();
            wearButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_genghuan");
            takeOffButton = RequireButton(detailView, "Layer/zhuangbeiInfoUI/zhuangbei/Btn_xiexia");
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

        public void Show(int selectedFormationPosition)
        {
            formationPosition = Mathf.Clamp(selectedFormationPosition, 1, 5);
            Render();
            listView.SetVisible(true);
            if (items.Count > 0) ShowDetails(items[0]);
        }

        public void HideDetails() => detailView.SetVisible(false);

        public void Render()
        {
            uint selectedUid = selected.Uid;
            HeroEquipmentKind selectedKind = selected.Kind;
            items.Clear();
            items.AddRange(equipment.Items.Select(value => new DisplayRecord(value)));
            items.AddRange(faBao.Items.Select(value => new DisplayRecord(value)));
            number.text = $"装备：{equipment.Count}　法宝：{faBao.Count}";
            emptyState.SetActive(items.Count == 0);
            missingIconCount = items.Count(item => IsMissing(item.Definition.Picture));
            list.SetItems(items);
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
        }

        private void BindRow(RectTransform row, DisplayRecord item, int index)
        {
            Transform first = row.Find("Item1");
            Transform second = row.Find("Item2");
            if (first == null) throw new InvalidOperationException("Equipment list template Item1 was not found.");
            if (second != null) second.gameObject.SetActive(false);
            first.gameObject.SetActive(true);
            SetText(first, "Name_1", $"[{(item.Kind == HeroEquipmentKind.FaBao ? "法宝" : "装备")}] {item.Definition.Name}");
            SetText(first, "Name_2", $"UID {item.Uid}");
            SetText(first, "Atrribute_1", $"强化 +{item.StrengthLevel}");
            SetText(first, "Atrribute_2", $"精炼 +{item.RefineLevel}");
            Transform worn = first.Find("yichuandai");
            if (worn != null) worn.gameObject.SetActive(item.FormationPosition > 0);
            ApplyIcon(first.Find("Icon")?.GetComponent<Image>(), item.Definition.Picture);
            Button button = first.GetComponent<Button>() ?? first.gameObject.AddComponent<Button>();
            button.targetGraphic = first.GetComponent<Graphic>() ?? first.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => ShowDetails(item));
            Button cultivate = first.Find("Btn_yangcheng")?.GetComponent<Button>();
            if (cultivate != null)
            {
                cultivate.onClick.RemoveAllListeners();
                cultivate.onClick.AddListener(() => ShowDetails(item));
            }
            row.gameObject.name = $"{item.Kind}_{item.Uid}_{index}";
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
            detailBaseAttribute.text = $"属性 {attrType}：{attrValue}";
            detailStrength.text = item.StrengthLevel.ToString();
            detailRefine.text = item.RefineLevel.ToString();
            ApplyIcon(detailIcon, item.Definition.Picture);
            bool worn = item.FormationPosition > 0;
            wearButton.gameObject.SetActive(!worn);
            takeOffButton.gameObject.SetActive(worn);
            wearButton.onClick.RemoveAllListeners();
            takeOffButton.onClick.RemoveAllListeners();
            if (item.Kind == HeroEquipmentKind.Equipment)
            {
                wearButton.onClick.AddListener(() => wearEquipment?.Invoke(item.Uid, formationPosition));
                takeOffButton.onClick.AddListener(() => takeOffEquipment?.Invoke(item.Uid, item.FormationPosition));
            }
            else
            {
                int targetSlot = SelectFaBaoSlot(formationPosition);
                wearButton.onClick.AddListener(() => wearFaBao?.Invoke(item.Uid, formationPosition, targetSlot));
                takeOffButton.onClick.AddListener(() => takeOffFaBao?.Invoke(item.Uid));
            }
            detailView.SetVisible(true);
        }

        private int SelectFaBaoSlot(int position)
        {
            bool slot5Used = faBao.Items.Any(item => item.FormationPosition == position && item.Slot == 5);
            return slot5Used ? 6 : 5;
        }

        private bool IsMissing(string picture)
        {
            bool placeholder;
            resources.LoadEquipmentIcon(picture, out placeholder);
            return placeholder;
        }

        private void ApplyIcon(Image image, string picture)
        {
            if (image == null) return;
            image.sprite = resources.LoadEquipmentIcon(picture);
            image.enabled = image.sprite != null;
            image.preserveAspect = true;
        }

        private void DisableCultivationButtons()
        {
            foreach (string path in new[]
            {
                "Layer/zhuangbeiInfoUI/Info/qianghuashuxing/Btn_qianghua",
                "Layer/zhuangbeiInfoUI/Info/jinglianshuxing/Btn_jinglian",
                "Layer/zhuangbeiInfoUI/Info/juexingshuxing/Btn_juexing",
                "Layer/zhuangbeiInfoUI/Info/shenzhushuxing/Btn_shenzhu",
            })
            {
                GameObject button = detailView.Binding.Find(path);
                if (button != null) button.SetActive(false);
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
