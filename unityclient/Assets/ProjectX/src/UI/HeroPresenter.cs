using System;
using System.Linq;
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
        private readonly PlayerStore player;
        private readonly HeroEquipmentStore equipment;
        private readonly FaBaoStore faBao;
        private readonly ResourceService resources;
        private readonly CocosUiView detailView;
        private readonly Action<int, int> openReplacement;
        private readonly Action<int> openCultivation;
        private readonly Action<int> openEnhanceMaster;
        private readonly Action<int, int> openEquipmentSlot;
        private readonly Action<int> openAttributes;
        private readonly Action<int> selectHero;
        private readonly Action<string> feedback;
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
        private int selectedPosition = 1;
        private bool selectionInitialized;
        private static readonly int[] FormationOpenLevels = { 1, 2, 5, 11, 15 };

        public HeroPresenter(CocosUiView listView, CocosUiView detailView, CocosUiView bagView,
            HeroStore heroes, FormationStore formation, PlayerStore player,
            HeroEquipmentStore equipment, FaBaoStore faBao, ResourceService resources,
            Action<int, int> openReplacement, Action<int> openCultivation,
            Action<int> openEnhanceMaster, Action<int, int> openEquipmentSlot,
            Action<int> openAttributes, Action<int> selectHero, Action<string> feedback)
        {
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.equipment = equipment ?? throw new ArgumentNullException(nameof(equipment));
            this.faBao = faBao ?? throw new ArgumentNullException(nameof(faBao));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.openReplacement = openReplacement ?? throw new ArgumentNullException(nameof(openReplacement));
            this.openCultivation = openCultivation ?? throw new ArgumentNullException(nameof(openCultivation));
            this.openEnhanceMaster = openEnhanceMaster ?? throw new ArgumentNullException(nameof(openEnhanceMaster));
            this.openEquipmentSlot = openEquipmentSlot ?? throw new ArgumentNullException(nameof(openEquipmentSlot));
            this.openAttributes = openAttributes ?? throw new ArgumentNullException(nameof(openAttributes));
            this.selectHero = selectHero ?? throw new ArgumentNullException(nameof(selectHero));
            this.feedback = feedback ?? throw new ArgumentNullException(nameof(feedback));
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
            skillDescription.supportRichText = true;
            skillDescription.alignment = TextAnchor.UpperLeft;
            skillDescription.horizontalOverflow = HorizontalWrapMode.Wrap;
            skillDescription.verticalOverflow = VerticalWrapMode.Overflow;
            skillIcon = Require(detailView, "Layer/EquipUI/Bg/Btn_Skill/Icon").GetComponent<Image>();
            GameObject portraitHost = Require(detailView, "Layer/EquipUI/Bg/bg/Image/BaseImage");
            GameObject modelHost = Require(detailView, "Layer/EquipUI/Bg/bg/Image/BaseImage/Node");
            detailModel = CreateModel(modelHost.transform);
            detailFallbackPortrait = CreatePortrait(portraitHost.transform);
            ClearPrefabPlaceholders(detailView.Binding);
            BindDetailControls();
            HidePrompts(listView.Binding.transform);
            HidePrompts(detailView.Binding.transform);
            HidePrompts(bagView.Binding.transform);
            heroes.Changed += Render;
            formation.Changed += Render;
            player.Changed += Render;
            equipment.Changed += Render;
            faBao.Changed += Render;
            Render();
        }

        public int ItemCount => heroes.Items.Count;
        public int BagItemCount { get; private set; }
        public int SelectedId => selectedId;
        public int SelectedPosition => selectedPosition;
        public bool HasVisibleSkillIcon => skillIcon != null && skillIcon.enabled && skillIcon.sprite != null;
        public string VisibleSkillName => skillName != null ? skillName.text : string.Empty;
        public int VisibleEquipmentSlotCount => CountVisibleSlotIcons(1, 4);
        public int VisibleFaBaoSlotCount => CountVisibleSlotIcons(5, 6);

        public void SelectFromAuthority(int heroId)
        {
            if (heroId <= 0 || !heroes.TryGet(heroId, out _)) return;
            selectedId = heroId;
            int position = formation.GetCombatPosition(heroId);
            if (position > 0) selectedPosition = position;
            selectionInitialized = true;
            Render();
        }

        public void Render()
        {
            var items = heroes.Items;
            if (items.Count == 0)
            {
                selectionInitialized = false;
                selectedId = 0;
                selectedPosition = 1;
            }
            else if (!selectionInitialized || (selectedId > 0 && !heroes.TryGet(selectedId, out _)))
            {
                int firstOccupiedPosition = 0;
                int firstOccupiedHero = 0;
                for (int position = 1; position <= formation.CombatHeroes.Count; position++)
                {
                    int heroId = formation.CombatHeroes[position - 1];
                    if (heroId <= 0 || !heroes.TryGet(heroId, out _)) continue;
                    firstOccupiedPosition = position;
                    firstOccupiedHero = heroId;
                    break;
                }
                selectedPosition = firstOccupiedPosition > 0 ? firstOccupiedPosition : 1;
                selectedId = firstOccupiedHero > 0 ? firstOccupiedHero : items[0].Id;
                selectionInitialized = true;
            }
            else if (selectedId == 0 && selectedPosition > 0
                && selectedPosition <= formation.CombatHeroes.Count)
            {
                int deployedHeroId = formation.CombatHeroes[selectedPosition - 1];
                if (deployedHeroId > 0 && heroes.TryGet(deployedHeroId, out _))
                    selectedId = deployedHeroId;
            }
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
            player.Changed -= Render;
            equipment.Changed -= Render;
            faBao.Changed -= Render;
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
            int openLevel = FormationOpenLevels[Mathf.Clamp(slot.Position - 1, 0, FormationOpenLevels.Length - 1)];
            bool isLocked = player.Level < openLevel;
            Text lockLevel = row.Find("bg_Lock/level")?.GetComponent<Text>();
            if (lockLevel != null) lockLevel.text = openLevel.ToString();
            if (head != null) head.gameObject.SetActive(occupied);
            if (add != null) add.gameObject.SetActive(!occupied && !isLocked);
            if (locked != null) locked.gameObject.SetActive(isLocked);
            Button rowButton = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            Image hitArea = row.GetComponent<Image>() ?? row.gameObject.AddComponent<Image>();
            hitArea.enabled = true;
            hitArea.color = new Color(1f, 1f, 1f, 0.001f);
            hitArea.raycastTarget = true;
            rowButton.targetGraphic = hitArea;
            rowButton.interactable = true;
            rowButton.onClick.RemoveAllListeners();
            if (isLocked)
            {
                Transform chooseLocked = row.Find("Choose");
                if (chooseLocked != null) chooseLocked.gameObject.SetActive(false);
                rowButton.onClick.AddListener(() => feedback($"{openLevel}级开启，上仙请升级"));
                row.gameObject.name = $"FormationLocked_{slot.Position}";
                return;
            }
            if (!occupied)
            {
                Transform chooseEmpty = row.Find("Choose");
                if (chooseEmpty != null) chooseEmpty.gameObject.SetActive(selectedId == 0 && selectedPosition == slot.Position);
                rowButton.onClick.AddListener(() =>
                {
                    selectedPosition = slot.Position;
                    selectedId = 0;
                    selectionInitialized = true;
                    Render();
                });
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
            if (choose != null) choose.gameObject.SetActive(item.Id == selectedId && selectedPosition == slot.Position);
                rowButton.onClick.AddListener(() =>
                {
                    selectedPosition = slot.Position;
                    selectedId = item.Id;
                    selectionInitialized = true;
                    selectHero(selectedId);
                    Render();
                });
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
            GameObject addPanel = detailView.Binding.Find("Layer/EquipUI/Bg/Panel_new");
            GameObject background = detailView.Binding.Find("Layer/EquipUI/Bg");
            if (!heroes.TryGet(selectedId, out HeroRecord hero))
            {
                if (background != null) background.SetActive(true);
                if (addPanel != null) addPanel.SetActive(true);
                SetDetailContentVisible(false);
                summary.text = "暂无神将";
                power.text = attack.text = health.text = physicalDefense.text = magicDefense.text = "-";
                attackType.text = skillName.text = skillDescription.text = "";
                detailModel.gameObject.SetActive(false);
                detailFallbackPortrait.sprite = null;
                detailFallbackPortrait.gameObject.SetActive(false);
                return;
            }
            if (background != null) background.SetActive(true);
            if (addPanel != null) addPanel.SetActive(false);
            SetDetailContentVisible(true);
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
                skillDescription.text = HeroCatalog.ResolveSkillDescription(
                    definition.SkillDescription, hero.PrimarySkillLevel);
                if (skillIcon != null)
                {
                    skillIcon.sprite = definition.SkillId > 0
                        ? resources.LoadFirst($"HeroUI/skill_{definition.SkillId}")
                        : null;
                    skillIcon.enabled = skillIcon.sprite != null;
                }
            }
            else
            {
                attackType.text = skillName.text = skillDescription.text = "";
                if (skillIcon != null) { skillIcon.sprite = null; skillIcon.enabled = false; }
            }
            ShowDetailModel(hero.Id);
            RenderEquipmentSlots();
        }

        private void BindDetailControls()
        {
            Bind("Layer/EquipUI/Bg/Panel_new/addnew", () => openReplacement(selectedPosition, 0));
            Bind("Layer/EquipUI/Bg/bg/Image_bg/Btn_3_1_0", () =>
            {
                if (selectedId > 0) openCultivation(selectedId);
            });
            Bind("Layer/EquipUI/Bg/bg/Image_bg/Button1", () =>
            {
                if (selectedId > 0) openEnhanceMaster(selectedPosition);
            });
            Bind("Layer/EquipUI/Bg/bg/Image_bg/Button2", () =>
            {
                if (selectedId > 0) openReplacement(selectedPosition, selectedId);
            });
            Bind("Layer/EquipUI/Bg/bg/Btn_xiangxi", () =>
            {
                if (selectedId > 0) openAttributes(selectedId);
            });
            for (int slot = 1; slot <= 6; slot++)
            {
                int captured = slot;
                Bind($"Layer/EquipUI/Bg/bg/EquipIcon{slot}", () =>
                {
                    if (selectedId > 0) openEquipmentSlot(selectedPosition, captured);
                });
            }
        }

        private void SetDetailContentVisible(bool visible)
        {
            foreach (string child in new[] { "bg", "Equip", "Btn_Skill" })
            {
                GameObject target = detailView.Binding.Find($"Layer/EquipUI/Bg/{child}");
                if (target != null) target.SetActive(visible);
            }
        }

        private void Bind(string path, Action action)
        {
            GameObject target = Require(detailView, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>();
            button.interactable = true;
            if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void RenderEquipmentSlots()
        {
            int authorityPosition = selectedId > 0 ? formation.GetCombatPosition(selectedId) : 0;
            if (authorityPosition > 0) selectedPosition = authorityPosition;
            for (int slot = 1; slot <= 6; slot++)
            {
                GameObject iconHost = detailView.Binding.Find($"Layer/EquipUI/Bg/bg/EquipIcon{slot}/IconBase");
                Image icon = EnsureRuntimeIcon(iconHost, $"EquippedItemIcon{slot}");
                Text name = detailView.Binding.Find($"Layer/EquipUI/Bg/bg/EquipIcon{slot}/name")?.GetComponent<Text>();
                Sprite sprite = null;
                string label = string.Empty;
                int quality = 0;
                if (slot <= 4)
                {
                    HeroEquipmentRecord item = equipment.Items.FirstOrDefault(value =>
                        value.FormationPosition == selectedPosition && value.Slot == slot);
                    if (item.Uid > 0)
                    {
                        sprite = resources.LoadEquipmentIcon(item.Definition.Picture);
                        label = item.GetLevel(1) > 0 ? $"{item.Definition.Name}+{item.GetLevel(1)}" : item.Definition.Name;
                        quality = item.Definition.Quality;
                    }
                }
                else
                {
                    FaBaoRecord item = faBao.Items.FirstOrDefault(value =>
                        value.FormationPosition == selectedPosition && value.Slot == slot);
                    if (item.Uid > 0)
                    {
                        sprite = resources.LoadFaBaoIcon(item.Definition.Picture, out _);
                        label = item.Definition.Name;
                        quality = item.Definition.Quality;
                    }
                }
                Image qualityFrame = EnsureRuntimeQualityFrame(iconHost, $"EquippedItemQuality{slot}");
                if (qualityFrame != null)
                {
                    qualityFrame.sprite = quality > 0
                        ? resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}")
                        : null;
                    qualityFrame.enabled = qualityFrame.sprite != null;
                    qualityFrame.gameObject.SetActive(qualityFrame.enabled);
                }
                if (icon != null)
                {
                    icon.sprite = sprite;
                    icon.enabled = sprite != null;
                    icon.color = Color.white;
                    icon.preserveAspect = true;
                    icon.canvasRenderer.SetAlpha(1f);
                    icon.gameObject.SetActive(sprite != null);
                }
                if (name != null) name.text = label;
            }
        }

        private static Image EnsureRuntimeIcon(GameObject host, string name)
        {
            if (host == null) return null;
            Transform existing = host.transform.Find(name);
            GameObject value = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host.transform, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(5f, 5f);
            rect.offsetMax = new Vector2(-5f, -5f);
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            image.color = Color.white;
            image.canvasRenderer.SetAlpha(1f);
            value.transform.SetAsLastSibling();
            return image;
        }

        private static Image EnsureRuntimeQualityFrame(GameObject host, string name)
        {
            if (host == null) return null;
            Transform existing = host.transform.Find(name);
            GameObject value = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host.transform, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            image.preserveAspect = false;
            value.transform.SetAsFirstSibling();
            return image;
        }

        private int CountVisibleSlotIcons(int first, int last)
        {
            int count = 0;
            for (int slot = first; slot <= last; slot++)
            {
                Image image = detailView.Binding.Find($"Layer/EquipUI/Bg/bg/EquipIcon{slot}/IconBase")
                    ?.transform.Find($"EquippedItemIcon{slot}")?.GetComponent<Image>();
                if (image != null && image.gameObject.activeInHierarchy && image.enabled && image.sprite != null)
                    count++;
            }
            return count;
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
                button.interactable = true;
                if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() =>
                {
                    selectedId = hero.Id;
                    selectionInitialized = true;
                    openCultivation(selectedId);
                });
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
