using System;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HeroPresenter : IDisposable
    {
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly ResourceService resources;
        private readonly VirtualList<FormationSlot> list;
        private readonly VirtualList<HeroBagRow> bagList;
        private readonly Text summary;
        private readonly Text power;
        private readonly Text attack;
        private readonly Text health;
        private readonly Text physicalDefense;
        private readonly Text magicDefense;
        private readonly Text attackType;
        private readonly Text skillName;
        private readonly Text skillDescription;
        private readonly Image skillIcon;
        private readonly ImodAnimationPlayer detailModel;
        private readonly Image detailFallbackPortrait;
        private int selectedId;

        public HeroPresenter(CocosUiView listView, CocosUiView detailView, CocosUiView bagView,
            HeroStore heroes, FormationStore formation, ResourceService resources)
        {
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            GameObject viewport = Require(listView, "Layer/shenjiangListUI/List/Panel");
            RectTransform viewportRect = viewport.GetComponent<RectTransform>();
            viewportRect.anchoredPosition += new Vector2(-9.33f, 6.67f);
            GameObject template = Require(listView, "Layer/shenjiangListUI/List/Item");
            // Cocos list advances formation slots by 102 px even though the imported template bounds are taller.
            float height = 102f;
            list = new VirtualList<FormationSlot>(viewport, template, height, BindRow);
            GameObject bagViewport = Require(bagView, "Layer/yingxiongbeibaoUI/TableView");
            RectTransform bagViewportRect = bagViewport.GetComponent<RectTransform>();
            bagViewportRect.anchoredPosition += new Vector2(-5f, -5f);
            GameObject bagTemplate = Require(bagView, "Layer/yingxiongbeibaoUI/ItemCell");
            float bagRowHeight = Mathf.Max(160f, bagTemplate.GetComponent<RectTransform>().rect.height);
            bagList = new VirtualList<HeroBagRow>(bagViewport, bagTemplate, bagRowHeight, BindBagRow);
            summary = RequireText(detailView, "Layer/EquipUI/Bg/bg/Image_bg/Tips_2");
            power = RequireText(detailView, "Layer/EquipUI/Bg/bg/Image_bg/bg_zhanli/Value");
            attack = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_1");
            health = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_2");
            physicalDefense = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_3");
            magicDefense = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_4");
            attackType = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_0");
            skillName = RequireText(detailView, "Layer/EquipUI/Bg/Btn_Skill/Panel_skill/Text");
            skillDescription = RequireText(detailView, "Layer/EquipUI/Bg/Btn_Skill/Panel_skill/ListView/Text_miaoshu");
            skillDescription.alignment = TextAnchor.UpperLeft;
            skillDescription.horizontalOverflow = HorizontalWrapMode.Wrap;
            skillDescription.verticalOverflow = VerticalWrapMode.Overflow;
            skillDescription.rectTransform.anchoredPosition = new Vector2(82f, 45.5f);
            skillDescription.rectTransform.sizeDelta = new Vector2(190f, 115f);
            skillIcon = Require(detailView, "Layer/EquipUI/Bg/Btn_Skill/Icon").GetComponent<Image>();
            GameObject portraitHost = Require(detailView, "Layer/EquipUI/Bg/bg/Image/BaseImage");
            GameObject modelHost = Require(detailView, "Layer/EquipUI/Bg/bg/Image/BaseImage/Node");
            detailModel = CreateModel(modelHost.transform);
            detailFallbackPortrait = CreatePortrait(portraitHost.transform);
            ClearPrefabPlaceholders(detailView.Binding);
            HidePrompts(listView.Binding.transform);
            HidePrompts(detailView.Binding.transform);
            HidePrompts(bagView.Binding.transform);
            heroes.Changed += Render;
            formation.Changed += Render;
            Render();
        }

        public int ItemCount => heroes.Items.Count;
        public int BagItemCount { get; private set; }
        public int SelectedId => selectedId;

        public void Render()
        {
            var items = heroes.Items;
            if (selectedId == 0 || !heroes.TryGet(selectedId, out _)) selectedId = items.Count > 0 ? items[0].Id : 0;
            var slots = new System.Collections.Generic.List<FormationSlot>(5);
            for (int position = 1; position <= 5; position++)
            {
                int heroId = position <= formation.CombatHeroes.Count ? formation.CombatHeroes[position - 1] : 0;
                HeroRecord slotHero = default;
                bool occupied = heroId > 0 && heroes.TryGet(heroId, out slotHero);
                slots.Add(new FormationSlot(position, slotHero, occupied));
            }
            list.SetItems(slots);
            var rows = new System.Collections.Generic.List<HeroBagRow>();
            for (int start = 0; start < items.Count; start += 5)
                rows.Add(new HeroBagRow(items, start));
            BagItemCount = items.Count;
            bagList.SetItems(rows);
            ShowDetails();
        }

        public void Dispose()
        {
            heroes.Changed -= Render;
            formation.Changed -= Render;
            list.Dispose();
            bagList.Dispose();
        }

        private void BindRow(RectTransform row, FormationSlot slot, int index)
        {
            HeroRecord item = slot.Hero;
            bool occupied = slot.Occupied;
            Transform head = row.Find("bg_Head");
            Transform add = row.Find("bg_add");
            Transform locked = row.Find("bg_Lock");
            if (head != null) head.gameObject.SetActive(occupied);
            if (add != null) add.gameObject.SetActive(!occupied);
            if (locked != null) locked.gameObject.SetActive(false);
            if (!occupied)
            {
                Transform chooseEmpty = row.Find("Choose");
                if (chooseEmpty != null) chooseEmpty.gameObject.SetActive(false);
                Button emptyButton = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
                emptyButton.onClick.RemoveAllListeners();
                row.gameObject.name = $"FormationEmpty_{slot.Position}";
                return;
            }
            Text level = row.Find("bg_Head/Value")?.GetComponent<Text>();
            Text name = row.Find("bg_Head/Name")?.GetComponent<Text>();
            if (level != null) level.gameObject.SetActive(false);
            if (name != null) { name.gameObject.SetActive(true); name.text = item.Name; }
            Image portrait = row.Find("bg_Head/Icon")?.GetComponent<Image>();
            if (portrait != null) portrait.sprite = LoadPortrait(item.Id, false);
            Image frame = row.Find("bg_Head")?.GetComponent<Image>();
            if (frame != null && HeroCatalog.TryGet(item.Id, out HeroDefinition rowDefinition))
                frame.sprite = resources.LoadFirst($"HeroUI/common_quality_{rowDefinition.Quality:00}");
            Transform color = row.Find("bg_Head/Color");
            if (color != null) color.gameObject.SetActive(false);
            Transform choose = row.Find("Choose");
            if (choose != null) choose.gameObject.SetActive(item.Id == selectedId);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => { selectedId = item.Id; Render(); });
            row.gameObject.name = $"Hero_{item.Id}_{index}";
        }

        private sealed class FormationSlot
        {
            public FormationSlot(int position, HeroRecord hero, bool occupied) { Position = position; Hero = hero; Occupied = occupied; }
            public int Position { get; }
            public HeroRecord Hero { get; }
            public bool Occupied { get; }
        }

        private void ShowDetails()
        {
            if (!heroes.TryGet(selectedId, out HeroRecord hero))
            {
                summary.text = "暂无神将";
                power.text = attack.text = health.text = physicalDefense.text = magicDefense.text = "-";
                attackType.text = skillName.text = skillDescription.text = "";
                detailModel.gameObject.SetActive(false);
                detailFallbackPortrait.sprite = null;
                detailFallbackPortrait.gameObject.SetActive(false);
                return;
            }
            summary.text = $"{hero.Level}级  {hero.Name} +{hero.BreakLevel}";
            power.text = hero.Power.ToString();
            attack.text = $"攻击：{hero.Attack}";
            health.text = $"生命：{hero.Health}";
            physicalDefense.text = $"物防：{hero.PhysicalDefense}";
            magicDefense.text = $"法防：{hero.MagicDefense}";
            if (HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
            {
                attackType.text = definition.PhysicalAttack ? "类型：物" : "类型：法";
                skillName.text = definition.SkillName;
                skillDescription.text = definition.SkillDescription;
                if (skillIcon != null)
                    skillIcon.sprite = definition.SkillId > 0
                        ? resources.LoadFirst($"HeroUI/skill_{definition.SkillId}")
                        : null;
            }
            else
            {
                attackType.text = skillName.text = skillDescription.text = "";
                if (skillIcon != null) skillIcon.sprite = null;
            }
            ShowDetailModel(hero.Id);
        }

        private void BindBagRow(RectTransform row, HeroBagRow data, int rowIndex)
        {
            for (int slot = 1; slot <= 5; slot++)
            {
                Transform cell = row.Find($"Item{slot}");
                if (cell == null) continue;
                int itemIndex = slot - 1;
                bool active = itemIndex < data.Items.Count;
                cell.gameObject.SetActive(active);
                if (!active) continue;
                HeroRecord hero = data.Items[itemIndex];
                Text name = cell.Find("Name")?.GetComponent<Text>();
                Text level = cell.Find("Level")?.GetComponent<Text>();
                if (name != null) name.text = $"{hero.Name}   +{hero.BreakLevel}";
                if (level != null) level.text = hero.Level.ToString();
                Image portrait = cell.Find("Panel_icon/Icon")?.GetComponent<Image>();
                if (portrait != null) portrait.sprite = LoadPortrait(hero.Id, true);
                if (HeroCatalog.TryGet(hero.Id, out HeroDefinition bagDefinition))
                {
                    Image quality = cell.Find("Quality")?.GetComponent<Image>();
                    if (quality != null) quality.sprite = resources.LoadFirst($"HeroUI/bag_quality_{bagDefinition.Quality:00}");
                    Image qualityLevel = cell.Find("Quality_Level")?.GetComponent<Image>();
                    if (qualityLevel != null) qualityLevel.sprite = resources.LoadFirst($"HeroUI/bag_level_{bagDefinition.Quality:00}");
                }
                Transform stars = cell.Find("StarList");
                if (stars != null) SetStars(stars, hero.Star);
                Transform deployed = cell.Find("shangzhen");
                if (deployed != null)
                {
                    deployed.gameObject.SetActive(formation.GetCombatPosition(hero.Id) > 0);
                    Text deployedText = deployed.GetComponentInChildren<Text>(true);
                    if (deployedText != null)
                    {
                        deployedText.text = "上阵";
                        deployedText.verticalOverflow = VerticalWrapMode.Overflow;
                    }
                }
                Button button = cell.GetComponent<Button>() ?? cell.gameObject.AddComponent<Button>();
                button.targetGraphic = cell.GetComponent<Graphic>() ?? cell.GetComponentInChildren<Graphic>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => { selectedId = hero.Id; Render(); });
            }
        }

        private Sprite LoadPortrait(int heroId, bool body)
        {
            if (!HeroCatalog.TryGet(heroId, out HeroDefinition definition))
                return resources.LoadHeroPortrait(heroId);
            return body
                ? resources.LoadFirst($"MonsterBust/{definition.Picture}", $"MonsterBust/{definition.Picture}_tou")
                : resources.LoadHeroPortrait(definition.Picture);
        }

        private void ShowDetailModel(int heroId)
        {
            bool loaded = HeroCatalog.TryGet(heroId, out HeroDefinition definition)
                && detailModel.LoadLegacy($"Monster/btm{definition.Picture}_zd_show");
            detailModel.gameObject.SetActive(loaded);
            detailFallbackPortrait.gameObject.SetActive(!loaded);
            if (loaded)
            {
                // MonsterBig maps to the dedicated *_zd_show Imod, whose stand loop is action 0.
                detailModel.Play(0, true);
                detailFallbackPortrait.sprite = null;
            }
            else
            {
                detailFallbackPortrait.sprite = LoadPortrait(heroId, true);
            }
        }

        private static void SetStars(Transform root, int count)
        {
            Image[] stars = root.GetComponentsInChildren<Image>(true);
            int shown = 0;
            foreach (Image star in stars)
            {
                if (star.transform == root || star.name == "Image_bg") continue;
                star.gameObject.SetActive(shown++ < count);
            }
        }

        private static Image CreatePortrait(Transform parent)
        {
            GameObject instance = new GameObject("HeroPortrait", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = instance.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = instance.GetComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
            return image;
        }

        private static ImodAnimationPlayer CreateModel(Transform parent)
        {
            Transform old = parent.Find("RuntimeHeroModel");
            GameObject instance = old != null ? old.gameObject
                : new GameObject("RuntimeHeroModel", typeof(RectTransform));
            RectTransform rect = instance.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = Vector2.zero;
            return instance.GetComponent<ImodAnimationPlayer>()
                ?? instance.AddComponent<ImodAnimationPlayer>();
        }

        private static void ClearPrefabPlaceholders(ProjectX.UI.Migration.CocosUiBinding binding)
        {
            for (int slot = 1; slot <= 6; slot++)
            {
                Text name = binding.Find($"Layer/EquipUI/Bg/bg/EquipIcon{slot}/name")?.GetComponent<Text>();
                if (name != null) name.text = "";
            }
        }

        private static void HidePrompts(Transform root)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private sealed class HeroBagRow
        {
            public HeroBagRow(System.Collections.Generic.IReadOnlyList<HeroRecord> source, int start)
            {
                var items = new System.Collections.Generic.List<HeroRecord>(5);
                for (int index = start; index < source.Count && index < start + 5; index++) items.Add(source[index]);
                Items = items;
            }

            public System.Collections.Generic.IReadOnlyList<HeroRecord> Items { get; }
        }

        private static GameObject Require(CocosUiView view, string path)
            => view.Binding.Find(path) ?? throw new InvalidOperationException($"Hero UI node was not found: {path}");
        private static Text RequireText(CocosUiView view, string path)
            => Require(view, path).GetComponent<Text>() ?? throw new InvalidOperationException($"Hero UI text was not found: {path}");
    }
}
