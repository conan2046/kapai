using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HeroCultivationPresenter : IDisposable
    {
        private readonly CocosUiView frame, shell, level, autoLevel, star, breakUp, cultivate, info;
        private readonly CocosUiView talent, helpFirst, helpSecond, attributes, number, helpFrame;
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly BagStore bag;
        private readonly PlayerStore player;
        private readonly ResourceService resources;
        private readonly Action<int, int, int> levelAction;
        private readonly Action<int, int> autoLevelAction, cultivateAction;
        private readonly Action<int> breakAction, starAction, activateAction;
        private readonly Action close;
        private readonly Action<string> toast;
        private readonly Action<Transform, int> showModel;
        private readonly Action<int> selectHero;
        private readonly List<Transform> tabs = new List<Transform>();
        private readonly HeroCultivationConfig config = new HeroCultivationConfig();
        private int heroId, page, levelItemId = 834, cultivationCount = 1, helpPage, helpSelectedLevel = 1;
        private bool subscribed;

        public HeroCultivationPresenter(CocosUiView frame, CocosUiView shell, CocosUiView level,
            CocosUiView autoLevel, CocosUiView star, CocosUiView breakUp, CocosUiView cultivate,
            CocosUiView info, CocosUiView talent, CocosUiView helpFirst, CocosUiView helpSecond,
            CocosUiView attributes, CocosUiView number, CocosUiView helpFrame, HeroStore heroes,
            FormationStore formation, BagStore bag, PlayerStore player, ResourceService resources,
            Action<int, int, int> levelAction, Action<int, int> autoLevelAction,
            Action<int> breakAction, Action<int, int> cultivateAction, Action<int> starAction,
            Action<int> activateAction, Action close, Action<string> toast,
            Action<Transform, int> showModel, Action<int> selectHero)
        {
            this.frame = frame; this.shell = shell; this.level = level; this.autoLevel = autoLevel;
            this.star = star; this.breakUp = breakUp; this.cultivate = cultivate; this.info = info;
            this.talent = talent; this.helpFirst = helpFirst; this.helpSecond = helpSecond;
            this.attributes = attributes; this.number = number; this.helpFrame = helpFrame;
            this.heroes = heroes; this.formation = formation; this.bag = bag; this.player = player;
            this.resources = resources; this.levelAction = levelAction; this.autoLevelAction = autoLevelAction;
            this.breakAction = breakAction; this.cultivateAction = cultivateAction;
            this.starAction = starAction; this.activateAction = activateAction;
            this.close = close; this.toast = toast; this.showModel = showModel;
            this.selectHero = selectHero ?? throw new ArgumentNullException(nameof(selectHero));
            BindStaticControls();
            heroes.Changed += HandleChanged;
            formation.Changed += HandleChanged;
            bag.Changed += HandleChanged;
            subscribed = true;
            Hide();
        }

        public void Show(int selectedHeroId)
        {
            heroId = selectedHeroId;
            selectHero(heroId);
            frame.SetVisible(true); shell.SetVisible(true);
            frame.GameObject.transform.SetAsLastSibling(); shell.GameObject.transform.SetAsLastSibling();
            ConfigureTabs();
            ShowPage(0);
        }

        public void Refresh(int selectedHeroId)
        {
            heroId = selectedHeroId;
            if (shell.GameObject.activeInHierarchy) Render();
        }

        public void Hide()
        {
            foreach (CocosUiView view in PageViews()) view?.SetVisible(false);
            autoLevel.SetVisible(false); talent.SetVisible(false); attributes.SetVisible(false);
            number.SetVisible(false); helpFrame.SetVisible(false); helpFirst.SetVisible(false); helpSecond.SetVisible(false);
            shell.SetVisible(false);
        }

        public bool ValidateEarlyPlayRuntime(out string detail)
        {
            int[] materialIds = { 834, 835, 836, 837 };
            int[] quantities = materialIds.Select(ItemQuantity).ToArray();
            if (quantities.Any(value => value <= 0))
            {
                detail = "missing level materials: " + string.Join("/", quantities);
                return false;
            }
            if (EventSystem.current == null || tabs.Count != 5)
            {
                detail = $"EventSystem/tabs unavailable: eventSystem={EventSystem.current != null}, tabs={tabs.Count}";
                return false;
            }
            Transform tabPanel = frame.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            if (tabPanel == null || tabPanel.Find("Button2_Runtime") == null
                || tabPanel.Find("HeroCultivationTab2") != null)
            {
                detail = "cultivation tab 2 did not reuse the shared Button2_Runtime slot";
                return false;
            }

            Canvas.ForceUpdateCanvases();
            string[] labels = { "升级", "升星", "突破", "修炼", "信息" };
            int[] order = { 1, 2, 3, 4, 0 };
            foreach (int index in order)
            {
                Button button = tabs[index].GetComponent<Button>();
                if (!InvokePointer(button, out string top))
                {
                    detail = $"tab {labels[index]} raycast failed; top={top}";
                    return false;
                }
                CocosUiView active = PageViews().ElementAt(index);
                Text title = frame.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
                if (!active.GameObject.activeInHierarchy || title == null || title.text != labels[index])
                {
                    detail = $"tab {labels[index]} did not activate its page/title";
                    return false;
                }
                string placeholder = active.GameObject.GetComponentsInChildren<Text>(true)
                    .Where(text => text.gameObject.activeInHierarchy)
                    .Select(text => text.text ?? string.Empty)
                    .FirstOrDefault(text => text.Contains("123456", StringComparison.Ordinal)
                        || text.Contains("9999", StringComparison.Ordinal)
                        || text.Contains("技能描述", StringComparison.Ordinal)
                        || text.Contains("天赋描述", StringComparison.Ordinal)
                        || text == "英雄描述");
                if (!string.IsNullOrEmpty(placeholder))
                {
                    detail = $"tab {labels[index]} retained placeholder '{placeholder}'";
                    return false;
                }
                if (index == 0 && Enumerable.Range(1, 4).Any(value =>
                    !HasVisibleChildSprite(active,
                        $"Layer/shenjiangInfoUI/Info/cailiao/btn_Item_{value}",
                        $"HeroLevelMaterial{value}Frame")))
                {
                    detail = "level page material quality frame is missing";
                    return false;
                }
                if (index == 1 && (!HasVisibleSprite(active, "Layer/yingxiongshengxingUI/Info/jichu/Btn_Skill/Icon")
                    || !HasVisibleSprite(active, "Layer/yingxiongshengxingUI/Info/cailiao/Icon")
                    || !HasVisibleChildSprite(active, "Layer/yingxiongshengxingUI/Info/cailiao/Icon", "HeroStarFragmentFrame")))
                {
                    detail = "star page skill/fragment icon or quality frame is missing";
                    return false;
                }
                if (index == 2 && (!HasVisibleSprite(active, "Layer/shenjiangInfoUI/Info/tupo/Item")
                    || !HasVisibleChildSprite(active, "Layer/shenjiangInfoUI/Info/tupo/Item", "HeroBreakMaterialFrame")))
                {
                    detail = "break page material icon or quality frame is missing";
                    return false;
                }
                if (index == 3 && (!HasVisibleSprite(active,
                        "Layer/shenjiangxiulian/Info/cailiao/btn_Item_1")
                    || !HasVisibleChildSprite(active,
                        "Layer/shenjiangxiulian/Info/cailiao/btn_Item_1", "HeroCultivationMaterialFrame")))
                {
                    detail = "cultivation page material icon or quality frame is missing";
                    return false;
                }
            }

            OpenTalent(true);
            Text[] popupTexts = talent.GameObject.GetComponentsInChildren<Text>(true);
            if (popupTexts.Any(text => (text.text ?? string.Empty).Contains("一百字", StringComparison.Ordinal))
                || popupTexts.Count(text => text.gameObject.activeInHierarchy
                    && text.transform.parent != null && text.transform.parent.name == "Text_skill") < 1)
            {
                detail = "break talent popup retained placeholder or generated no current-source rows";
                return false;
            }
            if (!InvokePointer(tabs[4].GetComponent<Button>(), out string popupCloseTop)
                || talent.GameObject.activeSelf || attributes.GameObject.activeSelf
                || helpFrame.GameObject.activeSelf || number.GameObject.activeSelf || autoLevel.GameObject.activeSelf)
            {
                detail = $"page switch did not close transient popup; top={popupCloseTop}";
                return false;
            }
            ShowPage(0);

            int original = heroId;
            Button right = shell.Binding.Find("Layer/Node_3/Button_r")?.GetComponent<Button>();
            Button left = shell.Binding.Find("Layer/Node_3/Button_l")?.GetComponent<Button>();
            if (!InvokePointer(right, out string rightTop) || heroId == original)
            {
                detail = $"right deployed switch failed; top={rightTop}, hero={original}->{heroId}";
                return false;
            }
            int alternate = heroId;
            if (!InvokePointer(left, out string leftTop) || heroId != original)
            {
                detail = $"left deployed restore failed; top={leftTop}, hero={alternate}->{heroId}";
                return false;
            }
            detail = $"materials={string.Join("/", quantities)}, tabs=5/5, deployed={original}->{alternate}->{heroId}";
            return true;
        }

        private static bool InvokePointer(Button button, out string top)
        {
            top = "none";
            if (button == null || EventSystem.current == null || !button.gameObject.activeInHierarchy
                || !button.interactable || button.targetGraphic == null || !button.targetGraphic.raycastTarget)
                return false;
            RectTransform rect = button.transform as RectTransform;
            if (rect == null) return false;
            PointerEventData data = new PointerEventData(EventSystem.current)
            {
                button = PointerEventData.InputButton.Left,
                position = RectTransformUtility.WorldToScreenPoint(null, rect.TransformPoint(rect.rect.center))
            };
            List<RaycastResult> hits = new List<RaycastResult>();
            EventSystem.current.RaycastAll(data, hits);
            if (hits.Count > 0) top = hits[0].gameObject.name;
            if (hits.Count == 0 || hits[0].gameObject.GetComponentInParent<Button>() != button) return false;
            ExecuteEvents.Execute(button.gameObject, data, ExecuteEvents.pointerDownHandler);
            ExecuteEvents.Execute(button.gameObject, data, ExecuteEvents.pointerUpHandler);
            ExecuteEvents.Execute(button.gameObject, data, ExecuteEvents.pointerClickHandler);
            return true;
        }

        private static bool HasVisibleSprite(CocosUiView view, string path)
        {
            GameObject host = view?.Binding.Find(path);
            return host != null && host.GetComponentsInChildren<Image>(true)
                .Any(image => image.enabled && image.sprite != null);
        }

        private static bool HasVisibleChildSprite(CocosUiView view, string path, string childName)
        {
            Transform child = view?.Binding.Find(path)?.transform.Find(childName);
            Image image = child?.GetComponent<Image>();
            return image != null && image.enabled && image.sprite != null;
        }

        private IEnumerable<CocosUiView> PageViews()
        {
            yield return level; yield return star; yield return breakUp; yield return cultivate; yield return info;
        }

        private void HandleChanged()
        {
            if (heroId > 0 && shell.GameObject.activeInHierarchy) Render();
        }

        private void BindStaticControls()
        {
            frame.BindClick("Layer/Panel_12/Title/CloseBtn", close, true);
            shell.BindClick("Layer/Node_3/duiwu", close, true);
            shell.BindClick("Layer/Node_3/Button_l", () => SwitchDeployed(-1), true);
            shell.BindClick("Layer/Node_3/Button_r", () => SwitchDeployed(1), true);
            int[] items = { 834, 835, 836, 837 };
            for (int index = 0; index < items.Length; index++)
            {
                int captured = items[index];
                level.BindClick($"Layer/shenjiangInfoUI/Info/cailiao/btn_Item_{index + 1}", () =>
                { levelItemId = captured; RenderLevel(); }, true);
            }
            level.BindClick("Layer/shenjiangInfoUI/Info/cailiao/btn_shengji", () =>
                levelAction(heroId, levelItemId, 1), true);
            level.BindClick("Layer/shenjiangInfoUI/Info/cailiao/btn_yjShengji", OpenAutoLevel, true);
            autoLevel.BindClick("Layer/bg/Btn_close", () => autoLevel.SetVisible(false), true);
            autoLevel.BindClick("Layer/bg/Button1", () => autoLevel.SetVisible(false), true);
            autoLevel.BindClick("Layer/bg/Button", () =>
            { autoLevel.SetVisible(false); autoLevelAction(heroId, Math.Min(player.Level, CurrentHero().Level + cultivationCount)); }, true);
            BindDelta(autoLevel, "Layer/bg/Button_+", 1);
            BindDelta(autoLevel, "Layer/bg/Button_-", -1);
            BindDelta(autoLevel, "Layer/bg/Button_+10", 10);
            BindDelta(autoLevel, "Layer/bg/Button_-10", -10);
            star.BindClick("Layer/yingxiongshengxingUI/Info/jichu/Btn_xiangxi", () => OpenTalent(false), true);
            star.BindClick("Layer/yingxiongshengxingUI/Info/cailiao/Btn_shengxing", () => starAction(heroId), true);
            breakUp.BindClick("Layer/shenjiangInfoUI/Info/jichu/Btn_xiangxi", () => OpenTalent(true), true);
            breakUp.BindClick("Layer/shenjiangInfoUI/Info/tupo/btn_shengji", () => breakAction(heroId), true);
            cultivate.BindClick("Layer/shenjiangxiulian/Info/jichu/Button", OpenHelp, true);
            cultivate.BindClick("Layer/shenjiangxiulian/Info/cailiao/btn_Item_1", () => cultivateAction(heroId, 1), true);
            cultivate.BindClick("Layer/shenjiangxiulian/Info/cailiao/btn_yjxl", () => cultivateAction(heroId, RemainingCultivation()), true);
            cultivate.BindClick("Layer/shenjiangxiulian/Info/cailiao/btn_xl", OpenNumber, true);
            cultivate.BindClick("Layer/shenjiangxiulian/Info/cailiao/btn_dxl", () => activateAction(heroId), true);
            info.BindClick("Layer/shenjiangInfoUI/Info/ScrollView_1/jichu/Button", () => OpenAttributes(), true);
            info.BindClick("Layer/shenjiangInfoUI/Info/ScrollView_1/Skill/Item/Button", () => OpenTalent(false), true);
            talent.BindClick("Layer/bg/Btn_close", () => talent.SetVisible(false), true);
            attributes.BindClick("Layer/Mask_close", () => attributes.SetVisible(false), true);
            helpFrame.BindClick("Layer/shopBg/Popup/Btn_close", CloseHelp, true);
            helpFirst.BindClick("Layer/shenjaingxiiuliantanchuang/Popup/Button", OpenCultivationAttributes, true);
            helpSecond.BindClick("Layer/Popup/Btn_close", () => helpSecond.SetVisible(false), true);
            for (int digit = 0; digit <= 9; digit++)
            {
                int captured = digit;
                number.BindClick($"Layer/Panel/Bg/BtnList/Btn{digit}", () => AppendDigit(captured), true);
            }
            number.BindClick("Layer/Panel/Bg/BtnList/Btn10", DeleteDigit, true);
            number.BindClick("Layer/Panel/Bg/BtnList/Btn12", ConfirmNumber, true);
            number.BindClick("Layer/Panel/Bg/Close", () => number.SetVisible(false), true);
        }

        private void ConfigureTabs()
        {
            GameObject listObject = frame.Binding.Find("Layer/Panel_12/Bg/Btn_ListView");
            Transform panel = frame.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (listObject == null || panel == null || first == null)
                throw new InvalidOperationException("Hero cultivation tab template is missing.");
            panel.parent.gameObject.SetActive(true);
            // Cultivation pages are full-screen siblings under OneLevelLayer.
            // A nested sorting canvas keeps the visible right-side tabs above
            // their transparent raycast surfaces, matching Cocos touch order.
            // Unity components use a native "fake null" after a Play-domain
            // teardown, so null-coalescing can retain a destroyed Canvas.
            Canvas tabCanvas = listObject.GetComponent<Canvas>();
            if (tabCanvas == null) tabCanvas = listObject.AddComponent<Canvas>();
            tabCanvas.overrideSorting = true;
            tabCanvas.sortingOrder = 200;
            GraphicRaycaster tabRaycaster = listObject.GetComponent<GraphicRaycaster>();
            if (tabRaycaster == null) listObject.AddComponent<GraphicRaycaster>();
            string[] labels = { "升级", "升星", "突破", "修炼", "信息" };
            tabs.Clear();
            for (int index = 0; index < labels.Length; index++)
            {
                Transform tab;
                if (index == 0) tab = first;
                else if (index == 1)
                {
                    Transform sharedSecond = panel.Find("Button2_Runtime");
                    Transform duplicate = panel.Find("HeroCultivationTab2");
                    if (sharedSecond != null && duplicate != null && duplicate != sharedSecond)
                        UnityEngine.Object.Destroy(duplicate.gameObject);
                    if (sharedSecond != null) tab = sharedSecond;
                    else if (duplicate != null) { duplicate.name = "Button2_Runtime"; tab = duplicate; }
                    else
                    {
                        tab = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform;
                        tab.name = "Button2_Runtime";
                    }
                }
                else tab = panel.Find($"HeroCultivationTab{index + 1}");
                if (tab == null) { tab = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform; tab.name = $"HeroCultivationTab{index + 1}"; }
                RectTransform rect = tab as RectTransform;
                RectTransform firstRect = first as RectTransform;
                if (rect != null && firstRect != null) rect.anchoredPosition = firstRect.anchoredPosition + new Vector2(0f, -100f * index);
                int captured = index;
                Button button = tab.GetComponent<Button>() ?? tab.gameObject.AddComponent<Button>();
                Image hitArea = tab.GetComponent<Image>() ?? tab.gameObject.AddComponent<Image>();
                if (hitArea.sprite == null)
                {
                    Color transparent = hitArea.color;
                    transparent.a = 0.001f;
                    hitArea.color = transparent;
                }
                hitArea.enabled = true;
                hitArea.raycastTarget = true;
                button.targetGraphic = hitArea;
                tab.gameObject.SetActive(true);
                button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => ShowPage(captured));
                SetTab(tab, labels[index], index == page);
                tabs.Add(tab);
            }
        }

        private void ShowPage(int index)
        {
            CloseTransientPopups();
            page = Mathf.Clamp(index, 0, 4);
            int cursor = 0;
            foreach (CocosUiView view in PageViews()) view.SetVisible(cursor++ == page);
            for (int i = 0; i < tabs.Count; i++) SetTab(tabs[i], new[] { "升级", "升星", "突破", "修炼", "信息" }[i], i == page);
            Text title = frame.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = new[] { "升级", "升星", "突破", "修炼", "信息" }[page];
            CocosUiView active = PageViews().ElementAt(page);
            active.GameObject.transform.SetAsLastSibling();
            Render();
        }

        private void CloseTransientPopups()
        {
            autoLevel.SetVisible(false);
            talent.SetVisible(false);
            attributes.SetVisible(false);
            number.SetVisible(false);
            CloseHelp();
        }

        private void SwitchDeployed(int direction)
        {
            int[] deployed = formation.CombatHeroes.Where(id => id > 0).ToArray();
            int current = Array.IndexOf(deployed, heroId);
            if (deployed.Length < 2 || current < 0) { toast("暂无其他已上阵神将"); return; }
            heroId = deployed[(current + direction + deployed.Length) % deployed.Length];
            selectHero(heroId);
            Render();
        }

        private HeroRecord CurrentHero()
        {
            if (!heroes.TryGet(heroId, out HeroRecord hero)) throw new InvalidOperationException($"Hero {heroId} is missing.");
            return hero;
        }

        private void Render()
        {
            HeroRecord hero = CurrentHero();
            SetText(shell, "Layer/Node_3/Tips_2", $"{hero.Level}级  {hero.Name} +{hero.BreakLevel}");
            SetText(shell, "Layer/Node_3/bg_zhanli/Value", hero.Power.ToString());
            if (HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
                showModel(shell.Binding.Find("Layer/Node_3/Node")?.transform, definition.Picture);
            RenderLevel(); RenderStar(); RenderBreak(); RenderCultivate(); RenderInfo();
        }

        private void RenderLevel()
        {
            HeroRecord hero = CurrentHero();
            uint[] current =
            {
                hero.Attack,
                hero.PhysicalDefense,
                hero.MagicDefense,
                (uint)Math.Min(uint.MaxValue, hero.Health)
            };
            uint[] growth = config.GetGrowth(hero.Id, hero.Star);
            string[] names = { "攻击：", "物防：", "法防：", "生命：" };
            SetText(level, "Layer/shenjiangInfoUI/Info/jichu/Level_1", $"{hero.Level}级");
            SetText(level, "Layer/shenjiangInfoUI/Info/jichu/Level_2", $"{hero.Level + 1}级");
            for (int i = 0; i < current.Length; i++)
            {
                string root = $"Layer/shenjiangInfoUI/Info/jichu/Attribute_{i + 1}";
                SetText(level, root, names[i]);
                SetText(level, root + "/Value_1", current[i].ToString());
                SetText(level, root + "/Value_2", checked(current[i] + growth[i]).ToString());
                SetText(level, root + "/Value_3", growth[i].ToString());
            }
            SetText(level, "Layer/shenjiangInfoUI/Info/cailiao/Level/Value", hero.Level.ToString());
            uint maximum = config.GetExperienceCap(hero.Level, checked(hero.MaxExperience * 15u));
            SetText(level, "Layer/shenjiangInfoUI/Info/cailiao/bg_Bar/Value", $"{hero.Experience}/{maximum}");
            FitText(level, "Layer/shenjiangInfoUI/Info/cailiao/bg_Bar/Value", 14);
            Image experience = level.Binding.Find(
                "Layer/shenjiangInfoUI/Info/cailiao/bg_Bar/ExpBar")?.GetComponent<Image>();
            if (experience != null)
                experience.fillAmount = maximum == 0 ? 0f : Mathf.Clamp01((float)hero.Experience / maximum);
            SetText(level, "Layer/shenjiangInfoUI/Info/cailiao/Tips/value", player.Level.ToString());
            int[] ids = { 834, 835, 836, 837 };
            int[] pictures = { 3105, 3107, 3101, 3106 };
            int[] experienceValues = { 2000, 5000, 20000, 100000 };
            for (int i = 0; i < ids.Length; i++)
            {
                string root = $"Layer/shenjiangInfoUI/Info/cailiao/btn_Item_{i + 1}";
                SetText(level, $"Layer/shenjiangInfoUI/Info/cailiao/btn_Item_{i + 1}/Value", ItemQuantity(ids[i]).ToString());
                SetText(level, root + "/Text", $"经验+{experienceValues[i]}");
                FitText(level, root + "/Text", 12);
                SetMaterialIcon(level, root, resources.LoadItemIcon(pictures[i]),
                    $"HeroLevelMaterial{i + 1}", config.GetItemQuality(ids[i]));
            }
        }

        private void RenderStar()
        {
            HeroRecord hero = CurrentHero();
            uint[] increase = config.GetStarUpgrade(hero.Id, hero.Star + 1, hero.Level);
            uint[] ordered = { increase[0], increase[3], increase[1], increase[2] };
            for (int i = 0; i < ordered.Length; i++)
                SetText(star, $"Layer/yingxiongshengxingUI/Info/jichu/Attribute_{i + 1}/Value", $"+{ordered[i]}");
            for (int value = 1; value <= 8; value++)
            {
                GameObject node = star.Binding.Find($"Layer/yingxiongshengxingUI/Info/jichu/StarList/Star_{value}");
                if (node != null) node.SetActive(value <= hero.Star);
            }
            if (HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
            {
                SetText(star, "Layer/yingxiongshengxingUI/Info/jichu/SkillName", definition.SkillName);
                SetText(star, "Layer/yingxiongshengxingUI/Info/jichu/ScrollView/SkillInfo",
                    ResolveSkillDescription(hero, definition));
                Image skill = star.Binding.Find(
                    "Layer/yingxiongshengxingUI/Info/jichu/Btn_Skill/Icon")?.GetComponent<Image>();
                if (skill != null)
                {
                    skill.sprite = definition.SkillId > 0
                        ? resources.LoadFirst($"HeroUI/skill_{definition.SkillId}") : null;
                    skill.enabled = skill.sprite != null;
                    skill.preserveAspect = true;
                }
            }
            int fragmentId = config.GetFragmentItem(hero.Id);
            int cost = config.GetStarCost(hero.Star + 1, definition.Quality);
            SetText(star, "Layer/yingxiongshengxingUI/Info/cailiao/Name", $"{hero.Name}碎片");
            SetText(star, "Layer/yingxiongshengxingUI/Info/cailiao/Slider_Bg/Value",
                $"{ItemQuantity(fragmentId)}/{cost}");
            SetMaterialIcon(star, "Layer/yingxiongshengxingUI/Info/cailiao/Icon",
                resources.LoadItemIcon(config.GetItemPicture(fragmentId)), "HeroStarFragment",
                config.GetItemQuality(fragmentId));
        }

        private void RenderBreak()
        {
            HeroRecord hero = CurrentHero();
            BreakConfig next = config.GetBreak(hero.BreakLevel + 1);
            uint[] current = { hero.Attack, (uint)Math.Min(uint.MaxValue, hero.Health),
                hero.PhysicalDefense, hero.MagicDefense };
            uint[] baseGrowth = config.GetBaseGrowth(hero.Id);
            uint[] growth = { baseGrowth[0], baseGrowth[3], baseGrowth[1], baseGrowth[2] };
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/jichu/Level_1", $"突破+{hero.BreakLevel}");
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/jichu/Level_2", $"突破+{hero.BreakLevel + 1}");
            for (int i = 0; i < current.Length; i++)
            {
                uint added = checked(growth[i] * (uint)Math.Max(0, next.AttributeMultiplier));
                string root = $"Layer/shenjiangInfoUI/Info/jichu/Attribute_{i + 1}";
                SetText(breakUp, root + "/Value_1", current[i].ToString());
                SetText(breakUp, root + "/Value_2", checked(current[i] + added).ToString());
                SetText(breakUp, root + "/Value_3", added.ToString());
            }
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/jichu/text_tianfu", "突破后解锁新的神将天赋");
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/tupo/Name", "突破丹");
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/tupo/Value", $"{ItemQuantity(851)}/{next.ItemCost}");
            SetMaterialIcon(breakUp, "Layer/shenjiangInfoUI/Info/tupo/Item",
                resources.LoadItemIcon(config.GetItemPicture(851)), "HeroBreakMaterial",
                config.GetItemQuality(851));
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/tupo/cailiao/Value", next.RequiredLevel.ToString());
            SetText(breakUp, "Layer/shenjiangInfoUI/Info/tupo/xiaohao/Num", next.GoldCost.ToString());
        }

        private void RenderCultivate()
        {
            HeroRecord hero = CurrentHero();
            TrainingConfig next = config.GetTraining(hero.CultivationLevel + 1);
            SetText(cultivate, "Layer/shenjiangxiulian/Info/jichu/Image_bg/txt_2", next.Name);
            SetText(cultivate, "Layer/shenjiangxiulian/Info/jichu/txt_3", "攻击、物防、法防、生命属性提升");
            SetText(cultivate, "Layer/shenjiangxiulian/Info/jichu/txt_4", "完成本阶修炼后激活天命加成");
            SetText(cultivate, "Layer/shenjiangxiulian/Info/jichu/txt_5", $"（开启等级：{next.RequiredLevel}级）");
            int[] values = { hero.CultivationAttack, hero.CultivationPhysicalDefense,
                hero.CultivationMagicDefense, hero.CultivationHealth };
            for (int i = 0; i < values.Length; i++)
            {
                int amount = next.AttributeUnit[i];
                string root = $"Layer/shenjiangxiulian/Info/jichu/att_{i + 1}";
                SetText(cultivate, root + "/bg_Bar/Value", $"{values[i] * amount}/{next.RequiredCount * amount}");
                SetText(cultivate, root + "/Value_1", amount.ToString());
            }
            SetText(cultivate, "Layer/shenjiangxiulian/Info/cailiao/btn_Item_1/Value_1",
                ItemQuantity(852).ToString());
            SetMaterialIcon(cultivate, "Layer/shenjiangxiulian/Info/cailiao/btn_Item_1",
                resources.LoadItemIcon(config.GetItemPicture(852)), "HeroCultivationMaterial",
                config.GetItemQuality(852));
        }

        private void RenderInfo()
        {
            HeroRecord hero = CurrentHero();
            uint[] values = { hero.Attack, (uint)Math.Min(uint.MaxValue, hero.Health),
                hero.PhysicalDefense, hero.MagicDefense };
            for (int i = 0; i < values.Length; i++)
                SetText(info, $"Layer/shenjiangInfoUI/Info/ScrollView_1/jichu/Attribute_{i + 1}/Value", values[i].ToString());
            if (HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
            {
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/Info/dingwei/Value", definition.Feature);
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/Skill/Item/SkillName", definition.SkillName);
                string skillDescription = ResolveSkillDescription(hero, definition);
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/Skill/Item/SkillInfo", skillDescription);
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/shengxingtianfu/Item/Title", $"升至{hero.Star}星开启");
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/shengxingtianfu/Item/SkillInfo", skillDescription);
                SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/miaoshu/Item/Content", definition.Feature);
            }
            SetText(info, "Layer/shenjiangInfoUI/Info/ScrollView_1/jinjietianfu/Item/TalentInfo",
                hero.BreakLevel > 0 ? $"已激活突破+{hero.BreakLevel}天赋" : "突破后解锁天赋");
        }

        private int ItemQuantity(int itemId) => bag.Items.Where(item => item.ItemId == itemId).Sum(item => item.Quantity);
        private int RemainingCultivation()
        {
            HeroRecord hero = CurrentHero();
            int completed = hero.CultivationAttack + hero.CultivationPhysicalDefense
                + hero.CultivationMagicDefense + hero.CultivationHealth;
            return Mathf.Clamp(ItemQuantity(852), 1, Math.Max(1, 400 - completed));
        }

        private void OpenAutoLevel()
        {
            cultivationCount = 1;
            SetText(autoLevel, "Layer/bg/Num", cultivationCount.ToString());
            autoLevel.SetVisible(true); autoLevel.GameObject.transform.SetAsLastSibling();
        }

        private void BindDelta(CocosUiView view, string path, int delta) => view.BindClick(path, () =>
        {
            cultivationCount = Mathf.Clamp(cultivationCount + delta, 1, Math.Max(1, player.Level - CurrentHero().Level));
            SetText(autoLevel, "Layer/bg/Num", cultivationCount.ToString());
        }, true);

        private void OpenNumber()
        {
            cultivationCount = 1; SetText(number, "Layer/Panel/Bg/Num", "1");
            number.SetVisible(true); number.GameObject.transform.SetAsLastSibling();
        }
        private void AppendDigit(int digit)
        {
            cultivationCount = Mathf.Clamp(cultivationCount * 10 + digit, 1, RemainingCultivation());
            SetText(number, "Layer/Panel/Bg/Num", cultivationCount.ToString());
        }
        private void DeleteDigit()
        {
            cultivationCount = Math.Max(0, cultivationCount / 10);
            SetText(number, "Layer/Panel/Bg/Num", cultivationCount.ToString());
        }
        private void ConfirmNumber()
        {
            number.SetVisible(false);
            if (cultivationCount <= 0) { toast("请输入修炼次数"); return; }
            cultivateAction(heroId, cultivationCount);
        }

        private void OpenTalent(bool breakTalent)
        {
            HeroRecord hero = CurrentHero();
            HeroCatalog.TryGet(hero.Id, out HeroDefinition definition);
            SetText(talent, "Layer/bg/Title", breakTalent ? "突破天赋" : "技能详情");
            talent.Binding.Find("Layer/bg/Title")?.transform.SetAsLastSibling();
            string[] titles;
            string[] descriptions;
            if (breakTalent)
            {
                descriptions = config.GetBreakTalentDescriptions(hero.Id, definition).ToArray();
                titles = Enumerable.Range(1, descriptions.Length).Select(value => $"突破至{value}开启").ToArray();
            }
            else
            {
                string description = ResolveSkillDescription(hero, definition);
                descriptions = Enumerable.Range(1, 8).Select(_ => description).ToArray();
                titles = Enumerable.Range(1, 8).Select(value => value == 1 ? "默认开启" : $"升至{value - 1}星开启").ToArray();
            }
            PopulateTalentRows(titles, descriptions, breakTalent ? hero.BreakLevel : hero.Star + 1);
            talent.SetVisible(true); talent.GameObject.transform.SetAsLastSibling();
        }

        private static string ResolveSkillDescription(HeroRecord hero, HeroDefinition definition) =>
            HeroCatalog.ResolveSkillDescription(definition.SkillDescription, hero.PrimarySkillLevel);

        private void PopulateTalentRows(IReadOnlyList<string> titles, IReadOnlyList<string> descriptions, int activeLevel)
        {
            GameObject listObject = talent.Binding.Find("Layer/bg/ListView");
            GameObject templateObject = talent.Binding.Find("Layer/bg/ListView/Panel_2");
            if (listObject == null || templateObject == null) return;
            RectTransform template = templateObject.transform as RectTransform;
            foreach (Transform child in listObject.transform.Cast<Transform>().ToArray())
                if (child.name.StartsWith("HeroCultivationTalentRow_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            Vector2 origin = template != null ? template.anchoredPosition : Vector2.zero;
            float step = Math.Max(78f, template != null ? template.rect.height : 78f);
            for (int index = 0; index < Math.Min(titles.Count, descriptions.Count); index++)
            {
                GameObject row = index == 0 ? templateObject : UnityEngine.Object.Instantiate(templateObject, listObject.transform, false);
                if (index > 0) row.name = $"HeroCultivationTalentRow_{index + 1}";
                RectTransform rect = row.transform as RectTransform;
                if (rect != null) rect.anchoredPosition = origin + new Vector2(0f, -step * index);
                Text openText = row.transform.Find("Text")?.GetComponent<Text>();
                Transform detailHost = row.transform.Find("Text_skill");
                Text detailText = detailHost?.Find("Text")?.GetComponent<Text>();
                if (detailHost is RectTransform detailHostRect)
                {
                    detailHostRect.anchorMin = detailHostRect.anchorMax = Vector2.zero;
                    detailHostRect.pivot = Vector2.zero;
                    detailHostRect.anchoredPosition = Vector2.zero;
                    detailHostRect.sizeDelta = new Vector2(540f, 100f);
                }
                Text legacySkillLabel = detailHost?.GetComponent<Text>();
                if (legacySkillLabel != null)
                {
                    legacySkillLabel.text = string.Empty;
                    legacySkillLabel.enabled = false;
                }
                if (openText != null)
                {
                    openText.text = titles[index];
                    openText.fontSize = 18;
                    openText.resizeTextForBestFit = false;
                    openText.alignment = TextAnchor.MiddleLeft;
                    openText.horizontalOverflow = HorizontalWrapMode.Overflow;
                    RectTransform openRect = openText.rectTransform;
                    openRect.anchorMin = openRect.anchorMax = Vector2.zero;
                    openRect.pivot = new Vector2(0f, 0.5f);
                    openRect.anchoredPosition = new Vector2(90f, 78f);
                    openRect.sizeDelta = new Vector2(430f, 24f);
                }
                if (detailText != null)
                {
                    detailText.text = descriptions[index] ?? string.Empty;
                    detailText.supportRichText = true;
                    detailText.fontSize = 18;
                    detailText.resizeTextForBestFit = false;
                    detailText.alignment = TextAnchor.UpperLeft;
                    detailText.horizontalOverflow = HorizontalWrapMode.Wrap;
                    detailText.verticalOverflow = VerticalWrapMode.Overflow;
                    RectTransform detailRect = detailText.rectTransform;
                    detailRect.anchorMin = detailRect.anchorMax = Vector2.zero;
                    detailRect.pivot = Vector2.zero;
                    detailRect.anchoredPosition = new Vector2(90f, 4f);
                    detailRect.sizeDelta = new Vector2(430f, 58f);
                }
                Color color = index + 1 == activeLevel ? new Color(0.18f, 0.65f, 0.12f) : new Color(0.36f, 0.20f, 0.14f);
                if (openText != null) openText.color = color;
                if (detailText != null) detailText.color = color;
                row.SetActive(true);
            }
            if (listObject.transform is RectTransform listRect)
                listRect.sizeDelta = new Vector2(listRect.sizeDelta.x, Math.Max(listRect.sizeDelta.y, step * titles.Count));
        }
        private void OpenAttributes()
        {
            HeroRecord hero = CurrentHero();
            HeroCatalog.TryGet(hero.Id, out HeroDefinition definition);
            SetText(attributes, "Layer/Node_1/Popup/Icon/name", hero.Name);
            SetText(attributes, "Layer/Node_1/Popup/Icon/text_zhanli/num", hero.Power.ToString());
            SetText(attributes, "Layer/Node_1/Popup/Icon/text_dingwei/num", definition.Feature);
            SetMaterialIcon(attributes, "Layer/Node_1/Popup/Icon",
                resources.LoadHeroPortrait(definition.Picture), "HeroAttributePortrait", definition.Quality);
            Transform portraitFrame = attributes.Binding.Find("Layer/Node_1/Popup/Icon")?.transform
                .Find("HeroAttributePortraitFrame");
            Transform portrait = attributes.Binding.Find("Layer/Node_1/Popup/Icon")?.transform
                .Find("HeroAttributePortrait");
            portraitFrame?.SetSiblingIndex(0);
            portrait?.SetSiblingIndex(1);
            PopulateHeroAttributeRows(hero);
            attributes.SetVisible(true); attributes.GameObject.transform.SetAsLastSibling();
        }

        private void PopulateHeroAttributeRows(HeroRecord hero)
        {
            GameObject list = attributes.Binding.Find("Layer/Node_1/Popup/ListView");
            GameObject template = attributes.Binding.Find("Layer/Node_1/Popup/ListView/name");
            if (list == null || template == null) return;
            foreach (Transform child in list.transform.Cast<Transform>().ToArray())
                if (child.name.StartsWith("HeroAttributeRow_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            string[] names = { "攻击", "物防", "法防", "生命", "速度" };
            string[] values = { hero.Attack.ToString(), hero.PhysicalDefense.ToString(),
                hero.MagicDefense.ToString(), hero.Health.ToString(), hero.Speed.ToString() };
            RectTransform templateRect = template.transform as RectTransform;
            Vector2 origin = templateRect != null ? templateRect.anchoredPosition : Vector2.zero;
            float step = Math.Max(28f, templateRect != null ? templateRect.rect.height : 28f);
            for (int index = 0; index < names.Length; index++)
            {
                GameObject row = index == 0 ? template : UnityEngine.Object.Instantiate(template, list.transform, false);
                if (index > 0) row.name = $"HeroAttributeRow_{index + 1}";
                RectTransform rowRect = row.transform as RectTransform;
                if (rowRect != null) rowRect.anchoredPosition = origin + new Vector2(0f, -step * index);
                Text label = row.GetComponent<Text>();
                Text value = row.transform.Find("value")?.GetComponent<Text>();
                if (label != null) label.text = names[index] + "：";
                if (value != null) value.text = values[index];
                row.SetActive(true);
            }
        }

        private void OpenHelp()
        {
            HeroRecord hero = CurrentHero();
            helpPage = hero.CultivationLevel >= 10 ? 1 : 0;
            helpSelectedLevel = Mathf.Clamp(hero.CultivationLevel > 0 ? hero.CultivationLevel : helpPage * 10 + 1,
                helpPage * 10 + 1, helpPage * 10 + 10);
            helpFrame.SetVisible(true); helpFirst.SetVisible(true); helpSecond.SetVisible(false);
            ConfigureHelpFrame();
            helpFrame.GameObject.transform.SetAsLastSibling(); helpFirst.GameObject.transform.SetAsLastSibling();
            ConfigureHelpTabs(); RenderCultivationDestinyPage();
        }
        private void CloseHelp() { helpFirst.SetVisible(false); helpSecond.SetVisible(false); helpFrame.SetVisible(false); }
        private void ConfigureHelpFrame()
        {
            SetText(helpFrame, "Layer/shopBg/Popup/Title/Title", "天命激活");
            GameObject helpButton = helpFrame.Binding.Find("Layer/shopBg/Popup/Title/Title/Button_1");
            if (helpButton != null) helpButton.SetActive(false);
            // Cocos ChangeBg replaces Popup/bg/Image1 while retaining Popup/bg itself as
            // the decorative frame. Hiding the whole node drops the frame as well.
            GameObject sharedBody = helpFrame.Binding.Find("Layer/shopBg/Popup/bg");
            if (sharedBody != null) sharedBody.SetActive(true);
            ConfigureDestinyBackground(sharedBody);
            ConfigureOverlayCanvas(helpFirst.GameObject, 202);
            ConfigureOverlayCanvas(helpFrame.Binding.Find("Layer/shopBg/Popup/Title"), 203);
            ConfigureOverlayCanvas(helpFrame.Binding.Find("Layer/shopBg/Popup/Btn_close"), 203);
            ConfigureOverlayCanvas(helpFrame.Binding.Find("Layer/shopBg/Btn_ListView/Panel_1"), 203);
            foreach (Transform child in helpFrame.GameObject.GetComponentsInChildren<Transform>(true))
                if (child.name.StartsWith("RuntimeGameplayContent", StringComparison.Ordinal)
                    || child.name.StartsWith("ActivityBg", StringComparison.Ordinal)
                    || child.name.StartsWith("GameplayRow", StringComparison.Ordinal))
                    child.gameObject.SetActive(false);
        }

        private void ConfigureDestinyBackground(GameObject sharedBody)
        {
            if (sharedBody == null) return;
            Image image = sharedBody.transform.Find("Image1")?.GetComponent<Image>();
            if (image == null) return;
            image.gameObject.SetActive(true);
            image.sprite = resources.LoadSprite("HeroCultivation/bg_shenjiangtujian");
            image.color = Color.white;
            image.preserveAspect = false;
            image.raycastTarget = false;
        }
        private void ConfigureHelpTabs()
        {
            Transform panel = helpFrame.Binding.Find("Layer/shopBg/Btn_ListView/Panel_1")?.transform;
            Transform first = panel?.Find("Button");
            if (first == null) return;
            Transform second = panel.Find("HeroCultivationHelpTab2");
            if (second == null) { second = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform; second.name = "HeroCultivationHelpTab2"; }
            RectTransform a = first as RectTransform, b = second as RectTransform;
            if (a != null && b != null) b.anchoredPosition = a.anchoredPosition + new Vector2(0f, -100f);
            BindTransformButton(first, () => SelectHelp(0)); BindTransformButton(second, () => SelectHelp(1));
            SetTab(first, "第一天命", helpPage == 0); SetTab(second, "第二天命", helpPage == 1);
        }
        private void SelectHelp(int selected)
        {
            helpPage = selected;
            helpSelectedLevel = selected * 10 + 1;
            helpFirst.SetVisible(true);
            ConfigureHelpTabs(); RenderCultivationDestinyPage();
        }
        private void OpenCultivationAttributes()
        {
            RenderCultivationAttributeSummary();
            helpSecond.SetVisible(true);
            ConfigureAttributeOverlay();
            ConfigureOverlayCanvas(helpSecond.GameObject, 204);
            helpSecond.GameObject.transform.SetAsLastSibling();
        }

        private void ConfigureAttributeOverlay()
        {
            Transform existing = helpSecond.GameObject.transform.Find("HeroCultivationAttributeDimmer");
            GameObject dimmer = existing == null
                ? new GameObject("HeroCultivationAttributeDimmer", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image))
                : existing.gameObject;
            dimmer.transform.SetParent(helpSecond.GameObject.transform, false);
            dimmer.transform.SetAsFirstSibling();
            RectTransform rect = dimmer.transform as RectTransform;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = dimmer.GetComponent<Image>();
            image.sprite = null;
            image.color = new Color(0f, 0f, 0f, 0.72f);
            image.raycastTarget = true;

            GameObject list = helpSecond.Binding.Find("Layer/Popup/ListView_1");
            if (list != null)
            {
                // The Cocos ScrollView stores three stacked content panels with a baked
                // top offset. The generic importer has no single ScrollRect.content, so
                // normalize those panels directly to the source's initial top position.
                string[] names = { "Content_1", "Content_2", "Content_3" };
                float[] y = { 293.15f, 185f, 80f };
                for (int index = 0; index < names.Length; index++)
                {
                    RectTransform content = list.transform.Find(names[index]) as RectTransform;
                    if (content != null)
                        content.anchoredPosition = new Vector2(content.anchoredPosition.x, y[index]);
                }
            }
        }

        private static void ConfigureOverlayCanvas(GameObject target, int sortingOrder)
        {
            if (target == null) return;
            Canvas canvas = target.GetComponent<Canvas>();
            if (canvas == null) canvas = target.AddComponent<Canvas>();
            canvas.overrideSorting = true;
            canvas.sortingOrder = sortingOrder;
            if (target.GetComponent<GraphicRaycaster>() == null)
                target.AddComponent<GraphicRaycaster>();
        }

        private void RenderCultivationDestinyPage()
        {
            HeroRecord hero = CurrentHero();
            GameObject panel = helpFirst.Binding.Find("Layer/shenjaingxiiuliantanchuang/Popup/Panel_xing");
            GameObject template = helpFirst.Binding.Find("Layer/shenjaingxiiuliantanchuang/Popup/Panel_xing/Button");
            if (panel == null || template == null) return;
            template.SetActive(false);
            for (int levelValue = 1; levelValue <= 20; levelValue++)
            {
                GameObject node = helpFirst.Binding.Find(
                    $"Layer/shenjaingxiiuliantanchuang/Popup/Panel_xing/Node_{levelValue}");
                if (node == null) continue;
                Transform old = node.transform.Find("HeroDestinyButton");
                if (old != null) UnityEngine.Object.Destroy(old.gameObject);
                if (levelValue <= helpPage * 10 || levelValue > helpPage * 10 + 10) continue;
                GameObject item = UnityEngine.Object.Instantiate(template, node.transform, false);
                item.name = "HeroDestinyButton";
                item.SetActive(true);
                RectTransform itemRect = item.transform as RectTransform;
                if (itemRect != null) itemRect.anchoredPosition = Vector2.zero;
                TrainingConfig training = config.GetTraining(levelValue);
                SetChildText(item.transform, "Image_bg_1/txt_1", training.Name);
                SetChildText(item.transform, "Image_bg_2/txt_1", training.Name);
                GameObject unlocked = item.transform.Find("Image_bg_1")?.gameObject;
                GameObject locked = item.transform.Find("Image_bg_2")?.gameObject;
                if (unlocked != null) unlocked.SetActive(levelValue <= hero.CultivationLevel);
                if (locked != null) locked.SetActive(levelValue > hero.CultivationLevel);
                GameObject selected = item.transform.Find("Image_choose")?.gameObject;
                if (selected != null) selected.SetActive(levelValue == helpSelectedLevel);
                int captured = levelValue;
                BindTransformButton(item.transform, () =>
                {
                    helpSelectedLevel = captured;
                    RenderCultivationDestinyPage();
                });
            }
            TrainingConfig current = config.GetTraining(helpSelectedLevel);
            string[] names = { "攻击加成", "物防加成", "法防加成", "生命加成" };
            for (int index = 0; index < names.Length; index++)
            {
                GameObject bonusObject = helpFirst.Binding.Find(
                    $"Layer/shenjaingxiiuliantanchuang/Popup/Panel_di/txt_{index + 1}");
                Text bonusText = bonusObject?.GetComponent<Text>();
                if (bonusText != null)
                {
                    bonusText.horizontalOverflow = HorizontalWrapMode.Overflow;
                    bonusText.text = $"{names[index]}+{current.BonusBasisPoints / 100d:0.##}%";
                }
            }
            string extra = config.GetTrainingExtraDescription(helpSelectedLevel);
            GameObject extraRoot = helpFirst.Binding.Find("Layer/shenjaingxiiuliantanchuang/Popup/Panel_di/txt_5");
            if (extraRoot != null) extraRoot.SetActive(!string.IsNullOrEmpty(extra));
            SetText(helpFirst, "Layer/shenjaingxiiuliantanchuang/Popup/Panel_di/txt_5/txt_5_0", extra);
            Text destinyName = helpFirst.Binding.Find(
                "Layer/shenjaingxiiuliantanchuang/Popup/Panel_di/txt_0")?.GetComponent<Text>();
            if (destinyName != null)
            {
                destinyName.horizontalOverflow = HorizontalWrapMode.Overflow;
                destinyName.text = $"【{current.Name}】";
                RectTransform nameRect = destinyName.rectTransform;
                nameRect.sizeDelta = new Vector2(Mathf.Max(140f, nameRect.sizeDelta.x), nameRect.sizeDelta.y);
                destinyName.transform.SetAsLastSibling();
            }
        }

        private void RenderCultivationAttributeSummary()
        {
            HeroRecord hero = CurrentHero();
            long[] baseTotals = { hero.CultivationAttack * 2L, hero.CultivationPhysicalDefense,
                hero.CultivationMagicDefense, hero.CultivationHealth * 40L };
            double percentage = 0d;
            List<string> extras = new List<string>();
            for (int levelValue = 1; levelValue <= hero.CultivationLevel; levelValue++)
            {
                TrainingConfig training = config.GetTraining(levelValue);
                for (int index = 0; index < baseTotals.Length; index++)
                    baseTotals[index] += (long)training.RequiredCount * training.AttributeUnit[index];
                percentage += training.BonusBasisPoints / 100d;
                string extra = config.GetTrainingExtraDescription(levelValue);
                if (!string.IsNullOrEmpty(extra)) extras.Add(extra);
            }
            string[] names = { "攻击", "物防", "法防", "生命" };
            for (int index = 0; index < names.Length; index++)
            {
                SetText(helpSecond, $"Layer/Popup/ListView_1/Content_1/Atrribute_{index + 1}",
                    $"{names[index]}+{baseTotals[index]}");
                SetText(helpSecond, $"Layer/Popup/ListView_1/Content_2/Atrribute_{index + 1}",
                    $"{names[index]}加成+{percentage:0.##}%");
                Text percentText = helpSecond.Binding.Find(
                    $"Layer/Popup/ListView_1/Content_2/Atrribute_{index + 1}")?.GetComponent<Text>();
                if (percentText != null)
                    percentText.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            GameObject extraTextObject = helpSecond.Binding.Find(
                "Layer/Popup/ListView_1/Content_3/Atrribute_1");
            if (extraTextObject != null)
            {
                extraTextObject.SetActive(extras.Count > 0);
                Text extraText = extraTextObject.GetComponent<Text>();
                if (extraText != null && extras.Count > 0)
                    extraText.text = string.Join("；", extras.Distinct());
            }
        }

        private static void SetChildText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void BindTransformButton(Transform transform, Action action)
        {
            Button button = transform.GetComponent<Button>() ?? transform.gameObject.AddComponent<Button>();
            Image hitArea = transform.GetComponent<Image>();
            if (hitArea != null)
            {
                if (hitArea.sprite == null)
                    hitArea.color = new Color(1f, 1f, 1f, 0f);
                hitArea.raycastTarget = true;
                button.targetGraphic = hitArea;
            }
            button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => action());
        }
        private static void SetTab(Transform tab, string label, bool selected)
        {
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null) normal.text = label; if (chosen != null) chosen.text = label;
            Transform choose = tab.Find("ChooseBg"); if (choose != null) choose.gameObject.SetActive(selected);
            Button button = tab.GetComponent<Button>(); if (button != null) button.interactable = !selected;
        }
        private static void SetText(CocosUiView view, string path, string value)
        {
            Text text = view.Binding.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            text.supportRichText = true;
            text.text = value ?? string.Empty;
        }

        private static void FitText(CocosUiView view, string path, int minimumSize)
        {
            Text text = view.Binding.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = Math.Max(8, minimumSize);
            text.resizeTextMaxSize = Math.Max(text.resizeTextMinSize, text.fontSize);
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
        }

        private void SetMaterialIcon(CocosUiView view, string path, Sprite sprite, string runtimeName, int quality = 0)
        {
            GameObject host = view.Binding.Find(path);
            if (host == null) return;
            Image hostImage = host.GetComponent<Image>();
            if (hostImage != null) hostImage.color = new Color(1f, 1f, 1f, 0f);
            if (quality > 0)
            {
                string frameName = runtimeName + "Frame";
                Transform existingFrame = host.transform.Find(frameName);
                GameObject frame = existingFrame != null ? existingFrame.gameObject
                    : new GameObject(frameName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform frameRect = frame.GetComponent<RectTransform>();
                frameRect.SetParent(host.transform, false);
                frameRect.anchorMin = Vector2.zero;
                frameRect.anchorMax = Vector2.one;
                frameRect.offsetMin = frameRect.offsetMax = Vector2.zero;
                Image frameImage = frame.GetComponent<Image>();
                frameImage.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
                frameImage.enabled = frameImage.sprite != null;
                frameImage.preserveAspect = false;
                frameImage.raycastTarget = false;
                frame.transform.SetAsFirstSibling();
            }
            Transform existing = host.transform.Find(runtimeName);
            GameObject value = existing != null ? existing.gameObject
                : new GameObject(runtimeName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host.transform, false);
            rect.anchorMin = new Vector2(0.12f, 0.12f);
            rect.anchorMax = new Vector2(0.88f, 0.88f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = value.GetComponent<Image>();
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
            image.raycastTarget = false;
            value.transform.SetAsLastSibling();
        }

        private readonly struct BreakConfig
        {
            public BreakConfig(int requiredLevel, int attributeMultiplier, int goldCost, int itemCost)
            { RequiredLevel = requiredLevel; AttributeMultiplier = attributeMultiplier; GoldCost = goldCost; ItemCost = itemCost; }
            public int RequiredLevel { get; }
            public int AttributeMultiplier { get; }
            public int GoldCost { get; }
            public int ItemCost { get; }
        }

        private readonly struct TrainingConfig
        {
            public TrainingConfig(string name, int requiredLevel, int requiredCount, int[] attributeUnit,
                int bonusBasisPoints, int extraType = 0, int extraValue = 0)
            {
                Name = name ?? string.Empty; RequiredLevel = requiredLevel; RequiredCount = requiredCount;
                AttributeUnit = attributeUnit; BonusBasisPoints = bonusBasisPoints;
                ExtraType = extraType; ExtraValue = extraValue;
            }
            public string Name { get; }
            public int RequiredLevel { get; }
            public int RequiredCount { get; }
            public int[] AttributeUnit { get; }
            public int BonusBasisPoints { get; }
            public int ExtraType { get; }
            public int ExtraValue { get; }
        }

        private sealed class HeroCultivationConfig
        {
            private readonly Dictionary<int, uint[]> growth = new Dictionary<int, uint[]>();
            private readonly Dictionary<int, uint> starRatios = new Dictionary<int, uint>();
            private readonly Dictionary<int, uint> starAdds = new Dictionary<int, uint>();
            private readonly Dictionary<int, Dictionary<int, int>> starCosts = new Dictionary<int, Dictionary<int, int>>();
            private readonly Dictionary<int, uint> experienceCaps = new Dictionary<int, uint>();
            private readonly Dictionary<int, int> fragments = new Dictionary<int, int>();
            private readonly Dictionary<int, BreakConfig> breaks = new Dictionary<int, BreakConfig>();
            private readonly Dictionary<int, TrainingConfig> trainings = new Dictionary<int, TrainingConfig>();
            private readonly Dictionary<int, int> itemPictures = new Dictionary<int, int>();
            private readonly Dictionary<int, int> itemQualities = new Dictionary<int, int>();
            private readonly Dictionary<int, List<BreakTalent>> breakTalents = new Dictionary<int, List<BreakTalent>>();

            public HeroCultivationConfig()
            {
                LoadHeroGrowth();
                LoadStarRatios();
                LoadExperienceCaps();
                LoadBreaks();
                LoadTrainings();
                LoadItemPictures();
            }

            public uint[] GetGrowth(int heroId, int star)
            {
                uint[] result = new uint[4];
                if (!growth.TryGetValue(heroId, out uint[] source)) return result;
                uint ratio = starRatios.TryGetValue(star, out uint value) ? value : 10000u;
                for (int index = 0; index < result.Length; index++)
                    result[index] = checked((uint)(((ulong)source[index] * ratio + 5000u) / 10000u));
                return result;
            }

            public uint[] GetBaseGrowth(int heroId) => growth.TryGetValue(heroId, out uint[] value)
                ? (uint[])value.Clone() : new uint[4];

            public uint GetExperienceCap(int level, uint fallback) =>
                experienceCaps.TryGetValue(level, out uint value) ? value : fallback;

            public int GetFragmentItem(int heroId) => fragments.TryGetValue(heroId, out int value) ? value : 0;

            public int GetItemPicture(int itemId) => itemPictures.TryGetValue(itemId, out int value) ? value : 0;

            public int GetItemQuality(int itemId) => itemQualities.TryGetValue(itemId, out int value) ? value : 0;

            public IReadOnlyList<string> GetBreakTalentDescriptions(int heroId, HeroDefinition definition)
            {
                if (!breakTalents.TryGetValue(heroId, out List<BreakTalent> values) || values.Count == 0)
                    return new[] { "解锁天赋：无" };
                return values.Select(value => DescribeBreakTalent(value, definition)).ToArray();
            }

            public int GetStarCost(int star, int quality)
            {
                return starCosts.TryGetValue(star, out Dictionary<int, int> costs)
                    && costs.TryGetValue(quality, out int value) ? value : 0;
            }

            public uint[] GetStarUpgrade(int heroId, int star, int level)
            {
                uint[] result = new uint[4];
                if (!growth.TryGetValue(heroId, out uint[] source)) return result;
                uint ratio = starRatios.TryGetValue(star, out uint value) ? value : 10000u;
                uint added = 0;
                for (int current = 1; current <= star; current++)
                    if (starAdds.TryGetValue(current, out uint item)) added += item;
                for (int i = 0; i < result.Length; i++)
                    result[i] = checked((uint)Math.Floor(source[i] * (ratio / 10000d) * level + source[i] * added));
                return result;
            }

            public BreakConfig GetBreak(int level) => breaks.TryGetValue(level, out BreakConfig value)
                ? value : new BreakConfig(0, 0, 0, 0);

            public TrainingConfig GetTraining(int level) => trainings.TryGetValue(level, out TrainingConfig value)
                ? value : new TrainingConfig("已满级", 0, 1, new[] { 0, 0, 0, 0 }, 0);

            public string GetTrainingExtraDescription(int level)
            {
                TrainingConfig value = GetTraining(level);
                if (value.ExtraType <= 0 || value.ExtraValue == 0) return string.Empty;
                string amount = value.ExtraType >= 10
                    ? $"{value.ExtraValue / 100d:0.##}%" : value.ExtraValue.ToString();
                return $"{AttributeName(value.ExtraType)}+{amount}";
            }

            private void LoadHeroGrowth()
            {
                TextAsset asset = Resources.Load<TextAsset>("WorldUI/Config/hero_dat");
                if (asset == null) return;
                foreach (string entry in SplitLuaEntries(asset.text))
                {
                    Match id = Regex.Match(entry, @"\bid\s*=\s*(\d+)");
                    Match attack = Regex.Match(entry, @"\bgongji_lv\s*=\s*(\d+)");
                    Match physical = Regex.Match(entry, @"\bwufang_lv\s*=\s*(\d+)");
                    Match magic = Regex.Match(entry, @"\bfafang_lv\s*=\s*(\d+)");
                    Match health = Regex.Match(entry, @"\bqixue_lv\s*=\s*(\d+)");
                    Match fragment = Regex.Match(entry, @"\bitemId\s*=\s*(\d+)");
                    if (!id.Success || !attack.Success || !physical.Success || !magic.Success || !health.Success) continue;
                    growth[int.Parse(id.Groups[1].Value)] = new[]
                    {
                        uint.Parse(attack.Groups[1].Value), uint.Parse(physical.Groups[1].Value),
                        uint.Parse(magic.Groups[1].Value), uint.Parse(health.Groups[1].Value)
                    };
                    if (fragment.Success) fragments[int.Parse(id.Groups[1].Value)] = int.Parse(fragment.Groups[1].Value);
                    Match breakField = Regex.Match(entry, @"\bbreakattr\s*=\s*\{(.*)\}\s*", RegexOptions.Singleline);
                    if (breakField.Success)
                    {
                        List<BreakTalent> values = new List<BreakTalent>();
                        foreach (Match triple in Regex.Matches(breakField.Groups[1].Value,
                            @"\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}"))
                            values.Add(new BreakTalent(int.Parse(triple.Groups[1].Value),
                                int.Parse(triple.Groups[2].Value), int.Parse(triple.Groups[3].Value)));
                        breakTalents[int.Parse(id.Groups[1].Value)] = values;
                    }
                }
            }

            private void LoadStarRatios()
            {
                TextAsset asset = Resources.Load<TextAsset>("WorldUI/Config/star_dat");
                if (asset == null) return;
                foreach (string entry in SplitLuaEntries(asset.text))
                {
                    Match star = Regex.Match(entry, @"\bstar\s*=\s*(\d+)");
                    Match ratio = Regex.Match(entry, @"\battr_ratio\s*=\s*(\d+)");
                    Match add = Regex.Match(entry, @"\battr_add\s*=\s*(\d+)");
                    if (star.Success && ratio.Success)
                    {
                        int starValue = int.Parse(star.Groups[1].Value);
                        starRatios[starValue] = uint.Parse(ratio.Groups[1].Value);
                        starAdds[starValue] = add.Success ? uint.Parse(add.Groups[1].Value) : 0u;
                        Dictionary<int, int> costs = new Dictionary<int, int>();
                        Match costField = Regex.Match(entry,
                            @"\bcost\s*=\s*\{(.*?)\}\s*,\s*skill_level", RegexOptions.Singleline);
                        if (costField.Success)
                            foreach (Match pair in Regex.Matches(costField.Groups[1].Value, @"\{\s*(\d+)\s*,\s*(\d+)\s*\}"))
                                costs[int.Parse(pair.Groups[1].Value)] = int.Parse(pair.Groups[2].Value);
                        starCosts[starValue] = costs;
                    }
                }
            }

            private void LoadBreaks()
            {
                TextAsset asset = Resources.Load<TextAsset>("WorldUI/Config/break_dat");
                if (asset == null) return;
                foreach (string entry in SplitLuaEntries(asset.text))
                {
                    Match breakLevel = Regex.Match(entry, @"\bbreak_level\s*=\s*(\d+)");
                    Match required = Regex.Match(entry, @"\blevel\s*=\s*(\d+)");
                    Match attr = Regex.Match(entry, @"\battr\s*=\s*(\d+)");
                    Match gold = Regex.Match(entry, @"\{\s*60000\s*,\s*0\s*,\s*(\d+)\s*\}");
                    Match item = Regex.Match(entry, @"\{\s*851\s*,\s*0\s*,\s*(\d+)\s*\}");
                    if (breakLevel.Success && required.Success && attr.Success)
                        breaks[int.Parse(breakLevel.Groups[1].Value)] = new BreakConfig(
                            int.Parse(required.Groups[1].Value), int.Parse(attr.Groups[1].Value),
                            gold.Success ? int.Parse(gold.Groups[1].Value) : 0,
                            item.Success ? int.Parse(item.Groups[1].Value) : 0);
                }
            }

            private void LoadTrainings()
            {
                TextAsset asset = Resources.Load<TextAsset>("WorldUI/Config/xiulian_dat");
                if (asset == null) return;
                foreach (string entry in SplitLuaEntries(asset.text))
                {
                    Match level = Regex.Match(entry, @"\blevel\s*=\s*(\d+)");
                    Match name = Regex.Match(entry, "\\bname\\s*=\\s*\"([^\"]*)\"");
                    Match required = Regex.Match(entry, @"\blevel_need\s*=\s*(\d+)");
                    Match count = Regex.Match(entry, @"\bcost_type\s*=\s*(\d+)");
                    MatchCollection attributes = Regex.Matches(entry,
                        @"\{\s*1\s*,\s*(\d+)\s*,\s*(\d+)\s*\}");
                    if (level.Success && required.Success && count.Success)
                    {
                        int bonus = attributes.Count > 0 ? int.Parse(attributes[0].Groups[2].Value) : 0;
                        int extraType = attributes.Count > 4 ? int.Parse(attributes[4].Groups[1].Value) : 0;
                        int extraValue = attributes.Count > 4 ? int.Parse(attributes[4].Groups[2].Value) : 0;
                        trainings[int.Parse(level.Groups[1].Value)] = new TrainingConfig(
                            name.Success ? name.Groups[1].Value : $"天命{level.Groups[1].Value}",
                            int.Parse(required.Groups[1].Value), int.Parse(count.Groups[1].Value),
                            new[] { 2, 1, 1, 40 }, bonus, extraType, extraValue);
                    }
                }
            }

            private void LoadExperienceCaps()
            {
                TextAsset asset = Resources.Load<TextAsset>("WorldUI/Config/exp_dat");
                if (asset == null) return;
                foreach (string entry in SplitLuaEntries(asset.text))
                {
                    Match level = Regex.Match(entry, @"\blevel\s*=\s*(\d+)");
                    Match cap = Regex.Match(entry, @"\bexp_hero\s*=\s*(\d+)");
                    if (level.Success && cap.Success)
                        experienceCaps[int.Parse(level.Groups[1].Value)] = uint.Parse(cap.Groups[1].Value);
                }
            }

            private void LoadItemPictures()
            {
                TextAsset asset = Resources.Load<TextAsset>("Configs/item");
                if (asset == null) return;
                foreach (Match entry in Regex.Matches(asset.text, @"\{[^{}]*\}"))
                {
                    Match id = Regex.Match(entry.Value, "\\\"id\\\"\\s*:\\s*(\\d+)");
                    Match picture = Regex.Match(entry.Value, "\\\"pic\\\"\\s*:\\s*(\\d+)");
                    Match quality = Regex.Match(entry.Value, "\\\"quality\\\"\\s*:\\s*(\\d+)");
                    if (id.Success && picture.Success)
                        itemPictures[int.Parse(id.Groups[1].Value)] = int.Parse(picture.Groups[1].Value);
                    if (id.Success && quality.Success)
                        itemQualities[int.Parse(id.Groups[1].Value)] = int.Parse(quality.Groups[1].Value);
                }
            }

            private static string DescribeBreakTalent(BreakTalent talent, HeroDefinition definition)
            {
                if (talent.Kind == 3)
                    return $"解锁天赋：获得技能：{definition.SkillName}强化（等级{talent.Value}）";
                string name = AttributeName(talent.Type);
                string amount = talent.Type >= 10 ? $"{talent.Value / 100d:0.##}%" : talent.Value.ToString();
                string prefix = talent.Kind == 2 ? "全队" : string.Empty;
                return $"解锁天赋：{prefix}{name}+{amount}";
            }

            private static string AttributeName(int type)
            {
                string[] values = { "", "攻击", "物防", "法防", "生命", "速度", "命中", "闪避", "暴击", "抗暴",
                    "攻击加成", "物防加成", "法防加成", "生命加成", "速度加成", "命中率", "闪避率", "暴击率", "抗暴率",
                    "增伤率", "物免率", "法免率", "暴击伤害", "反击率", "抗反率", "反击伤害", "连击率", "抗连率",
                    "连击伤害", "反震率", "抗震率", "反震伤害", "负面强化", "负面抵抗" };
                return type >= 0 && type < values.Length ? values[type] : $"属性{type}";
            }

            private readonly struct BreakTalent
            {
                public BreakTalent(int kind, int type, int value) { Kind = kind; Type = type; Value = value; }
                public int Kind { get; }
                public int Type { get; }
                public int Value { get; }
            }

            private static IEnumerable<string> SplitLuaEntries(string source)
            {
                int depth = 0, start = -1;
                bool inString = false, escaped = false;
                for (int index = 0; index < source.Length; index++)
                {
                    char current = source[index];
                    if (inString)
                    {
                        if (escaped) escaped = false;
                        else if (current == '\\') escaped = true;
                        else if (current == '"') inString = false;
                        continue;
                    }
                    if (current == '"') { inString = true; continue; }
                    if (current == '{') { depth++; if (depth == 2) start = index; }
                    else if (current == '}')
                    {
                        if (depth == 2 && start >= 0)
                        {
                            yield return source.Substring(start, index - start + 1);
                            start = -1;
                        }
                        if (depth > 0) depth--;
                    }
                }
            }
        }

        public void Dispose()
        {
            if (!subscribed) return;
            heroes.Changed -= HandleChanged; formation.Changed -= HandleChanged; bag.Changed -= HandleChanged;
            subscribed = false;
        }
    }
}
