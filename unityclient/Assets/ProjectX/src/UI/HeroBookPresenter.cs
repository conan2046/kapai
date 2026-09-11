using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HeroBookPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly CocosUiView upgradeView;
        private readonly CocosUiView activateResultView;
        private readonly CocosUiView upgradeResultView;
        private readonly CocosUiView attributesView;
        private readonly CocosUiView achievementView;
        private readonly CocosUiView levelResultView;
        private readonly HeroBookStore store;
        private readonly HeroBookCatalog catalog;
        private readonly HeroStore heroes;
        private readonly BagStore bag;
        private readonly EquipmentCatalog itemCatalog;
        private readonly ResourceService resources;
        private readonly Action<int> requestUpgrade;
        private readonly Action<string> feedback;
        private readonly List<KeyValuePair<int, HeroDefinition>> definitions =
            new List<KeyValuePair<int, HeroDefinition>>();
        private readonly List<GameObject> cards = new List<GameObject>();
        private ScrollRect cardScroll;
        private RectTransform cardContent;
        private string cardOrder = string.Empty;
        private int selectedIndex;
        private int modalHeroId;

        public HeroBookPresenter(CocosUiView view, CocosUiView upgradeView,
            CocosUiView activateResultView, CocosUiView upgradeResultView,
            CocosUiView attributesView, CocosUiView achievementView, CocosUiView levelResultView,
            HeroBookStore store, HeroBookCatalog catalog, HeroStore heroes, BagStore bag,
            EquipmentCatalog itemCatalog, ResourceService resources, Action<int> requestUpgrade,
            Action<string> feedback)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.upgradeView = upgradeView ?? throw new ArgumentNullException(nameof(upgradeView));
            this.activateResultView = activateResultView ?? throw new ArgumentNullException(nameof(activateResultView));
            this.upgradeResultView = upgradeResultView ?? throw new ArgumentNullException(nameof(upgradeResultView));
            this.attributesView = attributesView ?? throw new ArgumentNullException(nameof(attributesView));
            this.achievementView = achievementView ?? throw new ArgumentNullException(nameof(achievementView));
            this.levelResultView = levelResultView ?? throw new ArgumentNullException(nameof(levelResultView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.itemCatalog = itemCatalog ?? throw new ArgumentNullException(nameof(itemCatalog));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.requestUpgrade = requestUpgrade ?? throw new ArgumentNullException(nameof(requestUpgrade));
            this.feedback = feedback ?? (_ => { });
            BindMainControls();
            HidePopups();
            store.Changed += Render;
            store.UpgradeCompleted += HandleUpgradeCompleted;
            heroes.Changed += Render;
            bag.Changed += Render;
        }

        public void Show()
        {
            view.SetVisible(true);
            Render();
        }

        public void Hide()
        {
            HidePopups();
            view.SetVisible(false);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            store.UpgradeCompleted -= HandleUpgradeCompleted;
            heroes.Changed -= Render;
            bag.Changed -= Render;
            if (cardContent != null) UnityEngine.Object.Destroy(cardContent.gameObject);
            cards.Clear();
            cardContent = null;
            cardScroll = null;
            cardOrder = string.Empty;
        }

        private void BindMainControls()
        {
            Bind(view, "Layer/tujianUI/Button_l", () => Move(-1));
            Bind(view, "Layer/tujianUI/Button_r", () => Move(1));
            Bind(view, "Layer/tujianUI/Panel/Slider_Bg/Btn_tujian", ShowAchievements);
            Bind(view, "Layer/tujianUI/Panel/Btn_tujian", ShowAchievements);
            Bind(view, "Layer/tujianUI/Panel/Btn_shuxing", ShowAllAttributes);
            Bind(view, "Layer/tujianUI/Panel/Btn_Rank", () =>
                feedback("排行榜属于竞技/玩家依赖模块，当前不可用。"));
        }

        private void Move(int direction)
        {
            if (definitions.Count == 0) return;
            selectedIndex = Mathf.Clamp(selectedIndex + direction, 0, definitions.Count - 1);
            RenderCards();
            ScrollToSelected();
        }

        private void Render()
        {
            int selectedHeroId = definitions.Count > 0 && selectedIndex < definitions.Count
                ? definitions[selectedIndex].Key : 0;
            definitions.Clear();
            definitions.AddRange(catalog.Heroes
                .OrderByDescending(item => ActivationPriority(item.Key, item.Value))
                .ThenByDescending(item => item.Value.Quality)
                .ThenBy(item => item.Key));
            selectedIndex = selectedHeroId > 0
                ? Math.Max(0, definitions.FindIndex(item => item.Key == selectedHeroId))
                : Mathf.Clamp(selectedIndex, 0, Math.Max(0, definitions.Count - 1));
            EnsureCards();
            RenderCards();
            int owned = definitions.Count(item => heroes.TryGet(item.Key, out _));
            SetText(view, "Layer/tujianUI/Panel/Text_jindu/Value", $"{owned}/{definitions.Count}");
            SetText(view, "Layer/tujianUI/Panel/Slider_Bg/tujianzhi/Value", store.Score.ToString());
            HeroBookLevelDefinition next = ResolveNextLevel();
            long target = next.Score > 0 ? next.Score : Math.Max(1, store.Score);
            string progress = $"{store.Score}/{target}";
            SetText(view, "Layer/tujianUI/Panel/Text_chaju/Value", progress);
            SetText(view, "Layer/tujianUI/Panel/Slider_Bg/Value", progress);
            Image bar = Find(view, "Layer/tujianUI/Panel/Slider_Bg/LoadingBar")?.GetComponent<Image>();
            if (bar != null)
            {
                bar.type = Image.Type.Filled;
                bar.fillMethod = Image.FillMethod.Horizontal;
                bar.fillAmount = Mathf.Clamp01(store.Score / (float)target);
            }
            for (int index = 0; index < 3; index++)
            {
                GameObject targetNode = Find(view,
                    $"Layer/tujianUI/Panel/Slider_Bg/Btn_tujian/Image/Attribute_{index + 1}");
                bool visible = index < next.Attributes.Count;
                if (targetNode != null) targetNode.SetActive(visible);
                if (visible) SetText(targetNode, HeroBookCatalog.FormatAttribute(next.Attributes[index], true));
            }
            if (modalHeroId > 0 && upgradeView.GameObject.activeSelf) RenderUpgradePopup(modalHeroId);
        }

        private int ActivationPriority(int heroId, HeroDefinition definition)
        {
            if (!heroes.TryGet(heroId, out HeroRecord owned)) return 0;
            if (!store.TryGet(heroId, out HeroBookEntry entry)) return 3;
            int nextStar = entry.Star + 1;
            if (!catalog.TryGetStar(nextStar, out HeroBookStarDefinition next)) return 1;
            HeroBookCost cost = next.GetCost(definition.Quality);
            return owned.Star >= next.Condition
                && (cost.ItemId <= 0 || bag.GetTotalQuantityByItemId(cost.ItemId) >= cost.Quantity) ? 2 : 1;
        }

        private HeroBookLevelDefinition ResolveNextLevel()
        {
            if (catalog.TryGetLevel(store.Level + 1, out HeroBookLevelDefinition next)) return next;
            return catalog.Levels.Count > 0 ? catalog.Levels[catalog.Levels.Count - 1] : default;
        }

        private void EnsureCards()
        {
            GameObject template = Find(view, "Layer/tujianUI/Item");
            GameObject host = Find(view, "Layer/tujianUI/TableView");
            if (template == null || host == null)
                throw new InvalidOperationException("HeroBook card template/TableView binding is missing.");
            template.SetActive(false);
            if (cardScroll == null)
            {
                RectTransform viewport = host.GetComponent<RectTransform>();
                RectMask2D mask = host.GetComponent<RectMask2D>() ?? host.AddComponent<RectMask2D>();
                mask.padding = Vector4.zero;
                cardScroll = host.GetComponent<ScrollRect>() ?? host.AddComponent<ScrollRect>();
                cardScroll.viewport = viewport;
                cardScroll.horizontal = true;
                cardScroll.vertical = false;
                cardScroll.movementType = ScrollRect.MovementType.Clamped;
                cardScroll.inertia = true;
                cardScroll.scrollSensitivity = 30f;

                var contentObject = new GameObject("RuntimeHeroBookContent", typeof(RectTransform),
                    typeof(HorizontalLayoutGroup), typeof(ContentSizeFitter));
                cardContent = contentObject.GetComponent<RectTransform>();
                cardContent.SetParent(host.transform, false);
                cardContent.anchorMin = new Vector2(0f, 0f);
                cardContent.anchorMax = new Vector2(0f, 1f);
                cardContent.pivot = new Vector2(0f, 0.5f);
                cardContent.anchoredPosition = Vector2.zero;
                HorizontalLayoutGroup layout = contentObject.GetComponent<HorizontalLayoutGroup>();
                layout.childAlignment = TextAnchor.MiddleLeft;
                layout.childControlWidth = false;
                layout.childControlHeight = false;
                layout.childForceExpandWidth = false;
                layout.childForceExpandHeight = false;
                layout.spacing = 0f;
                ContentSizeFitter fitter = contentObject.GetComponent<ContentSizeFitter>();
                fitter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
                fitter.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
                cardScroll.content = cardContent;
            }

            string order = string.Join(",", definitions.Select(item => item.Key));
            if (order == cardOrder && cards.Count == definitions.Count) return;
            foreach (GameObject oldCard in cards)
            {
                if (oldCard == null) continue;
                oldCard.SetActive(false);
                UnityEngine.Object.Destroy(oldCard);
            }
            cards.Clear();
            cardOrder = order;
            for (int index = 0; index < definitions.Count; index++)
            {
                GameObject runtimeCard = UnityEngine.Object.Instantiate(template, cardContent, false);
                runtimeCard.name = $"RuntimeHeroBookCard_{definitions[index].Key}";
                runtimeCard.SetActive(true);
                RectTransform rect = runtimeCard.GetComponent<RectTransform>();
                if (rect != null)
                {
                    rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
                    rect.sizeDelta = new Vector2(300f, 441f);
                    rect.localScale = Vector3.one;
                }
                int capturedIndex = index;
                Button select = EnsureButton(runtimeCard.transform.Find("Item")?.gameObject);
                if (select != null)
                {
                    select.onClick.RemoveAllListeners();
                    select.onClick.AddListener(() =>
                    {
                        selectedIndex = capturedIndex;
                        RenderCards();
                        ScrollToSelected();
                    });
                }
                cards.Add(runtimeCard);
            }
            Canvas.ForceUpdateCanvases();
        }

        private void RenderCards()
        {
            for (int index = 0; index < cards.Count && index < definitions.Count; index++)
                RenderCard(cards[index], definitions[index], index);
        }

        private void RenderCard(GameObject runtimeCard,
            KeyValuePair<int, HeroDefinition> selected, int index)
        {
            if (runtimeCard == null) return;
            int heroId = selected.Key;
            HeroDefinition definition = selected.Value;
            store.TryGet(heroId, out HeroBookEntry entry);
            int level = entry.HeroId > 0 ? entry.Star : 1;
            int score = entry.HeroId > 0 ? entry.Score
                : catalog.TryGetStar(1, out HeroBookStarDefinition first) ? first.GetScore(definition.Quality) : 0;
            SetText(runtimeCard, "Item/Namebg/Name", string.IsNullOrEmpty(definition.Name) ? $"神将 #{heroId}" : definition.Name);
            SetText(runtimeCard, "Item/Level", $"{level}级图鉴");
            SetText(runtimeCard, "Item/Value", $"图鉴值：{score}");
            Transform body = runtimeCard.transform.Find("Item");
            if (body != null) body.localScale = index == selectedIndex ? Vector3.one : Vector3.one * .8f;
            Image portrait = runtimeCard.transform.Find("Item/Panel/Icon")?.GetComponent<Image>();
            if (portrait != null)
            {
                portrait.sprite = resources.LoadHeroBodyPortrait(definition.Picture);
                portrait.enabled = portrait.sprite != null;
                portrait.type = Image.Type.Simple;
                portrait.preserveAspect = true;
            }
            Button action = EnsureButton(runtimeCard.transform.Find("Item/Btn_shengji")?.gameObject);
            bool owned = heroes.TryGet(heroId, out _);
            bool activated = entry.HeroId > 0;
            string label = activated ? (entry.Star >= catalog.MaxStar ? "已满级" : "升级") : "激活";
            SetText(runtimeCard, "Item/Btn_shengji/Text_1", label);
            SetText(runtimeCard, "Item/Btn_shengji/Text_2", label);
            if (action != null)
            {
                action.interactable = true;
                action.onClick.RemoveAllListeners();
                action.onClick.AddListener(() =>
                {
                    if (!owned) { feedback("拥有对应神将后方可激活"); return; }
                    if (activated && entry.Star >= catalog.MaxStar) { feedback("已达到最高级"); return; }
                    if (activated) ShowUpgrade(heroId); else requestUpgrade(heroId);
                });
            }
        }

        private void ScrollToSelected()
        {
            if (cardScroll == null || cardContent == null || definitions.Count <= 1) return;
            Canvas.ForceUpdateCanvases();
            float viewportWidth = cardScroll.viewport != null ? cardScroll.viewport.rect.width : 0f;
            float contentWidth = cardContent.rect.width;
            float maximumOffset = Mathf.Max(0f, contentWidth - viewportWidth);
            if (maximumOffset <= 0f) return;
            float targetOffset = Mathf.Clamp(selectedIndex * 300f + 150f - viewportWidth * .5f,
                0f, maximumOffset);
            cardScroll.horizontalNormalizedPosition = targetOffset / maximumOffset;
        }

        private void ShowUpgrade(int heroId)
        {
            modalHeroId = heroId;
            RenderUpgradePopup(heroId);
            upgradeView.SetVisible(true);
            upgradeView.GameObject.transform.SetAsLastSibling();
        }

        private void RenderUpgradePopup(int heroId)
        {
            if (!catalog.TryGetHero(heroId, out HeroDefinition definition)
                || !store.TryGet(heroId, out HeroBookEntry entry)) return;
            int nextStar = entry.Star + 1;
            if (!catalog.TryGetStar(nextStar, out HeroBookStarDefinition next)) return;
            SetText(upgradeView, "Layer/Popup/IconColor/Name", definition.Name);
            SetText(upgradeView, "Layer/Popup/shuxing/Level_1", $"{entry.Star}级图鉴");
            SetText(upgradeView, "Layer/Popup/shuxing/Level_2", $"{nextStar}级图鉴");
            SetText(upgradeView, "Layer/Popup/shuxing/tujianzhi_1", $"图鉴值：{entry.Score}");
            SetText(upgradeView, "Layer/Popup/shuxing/tujianzhi_2",
                $"图鉴值：{entry.Score + next.GetScore(definition.Quality)}");
            ConfigureHeroIcon(upgradeView, "Layer/Popup/IconColor", definition);
            HeroBookAttribute[] current = CalculateHeroAttributes(definition, entry.Star);
            HeroBookAttribute[] target = CalculateHeroAttributes(definition, nextStar);
            for (int index = 0; index < 4; index++)
            {
                SetText(upgradeView, $"Layer/Popup/shuxing/Attribute_{index + 1}",
                    HeroBookCatalog.FormatAttribute(current[index]));
                SetText(upgradeView, $"Layer/Popup/shuxing/Attribute_{index + 5}",
                    HeroBookCatalog.FormatAttribute(target[index]));
            }
            HeroBookCost cost = next.GetCost(definition.Quality);
            int held = cost.ItemId > 0 ? bag.GetTotalQuantityByItemId(cost.ItemId) : 0;
            SetText(upgradeView, "Layer/Popup/tiaojian/Value",
                $"达到{(heroes.TryGet(heroId, out HeroRecord hero) ? hero.Star : 0)}/{next.Condition}星");
            SetText(upgradeView, "Layer/Popup/xiaohao/Value", cost.ItemId > 0 ? $"{held}/{cost.Quantity}" : "0/0");
            Image costIcon = Find(upgradeView, "Layer/Popup/xiaohao/Icon")?.GetComponent<Image>();
            EquipmentMaterialDefinition item = cost.ItemId > 0 ? itemCatalog.GetItem(cost.ItemId) : null;
            if (costIcon != null) costIcon.sprite = item == null ? null : resources.LoadItemIcon(item.Picture);
            Bind(upgradeView, "Layer/Popup/Btn_close", CloseUpgrade);
            Bind(upgradeView, "Layer/Mask", CloseUpgrade);
            Bind(upgradeView, "Layer/Popup/Btn_shengji", () => requestUpgrade(heroId));
        }

        private HeroBookAttribute[] CalculateHeroAttributes(HeroDefinition definition, int star)
        {
            int totalHandbook = 0;
            for (int level = 1; level <= star; level++)
                if (catalog.TryGetStar(level, out HeroBookStarDefinition value)) totalHandbook += value.Handbook;
            double ratio = catalog.GetQualityRatio(definition.Quality) / 10000d;
            return new[]
            {
                new HeroBookAttribute(1, (long)(totalHandbook * ratio * definition.AttackGrowth)),
                new HeroBookAttribute(2, (long)(totalHandbook * ratio * definition.PhysicalDefenseGrowth)),
                new HeroBookAttribute(3, (long)(totalHandbook * ratio * definition.MagicDefenseGrowth)),
                new HeroBookAttribute(4, (long)(totalHandbook * ratio * definition.HealthGrowth))
            };
        }

        private void CloseUpgrade()
        {
            modalHeroId = 0;
            upgradeView.SetVisible(false);
        }

        private void ShowAllAttributes()
        {
            RenderAttributeSection(attributesView, "Layer/Popup/Content_1/Atrribute_", store.HeroAttributes, 4);
            RenderAttributeSection(attributesView, "Layer/Popup/Content_2/Atrribute_", store.ScoreAttributes, 8);
            Bind(attributesView, "Layer/Popup/Btn_close", () => attributesView.SetVisible(false));
            Bind(attributesView, "Layer/Mask", () => attributesView.SetVisible(false));
            attributesView.SetVisible(true);
            attributesView.GameObject.transform.SetAsLastSibling();
        }

        private static void RenderAttributeSection(CocosUiView popup, string path,
            IReadOnlyDictionary<int, long> values, int capacity)
        {
            HeroBookAttribute[] attrs = values.OrderBy(item => item.Key)
                .Select(item => new HeroBookAttribute(item.Key, item.Value)).ToArray();
            for (int index = 0; index < capacity; index++)
            {
                GameObject node = Find(popup, path + (index + 1));
                bool visible = index < attrs.Length;
                if (node != null) node.SetActive(visible);
                if (visible) SetText(node, HeroBookCatalog.FormatAttribute(attrs[index]));
            }
        }

        private void ShowAchievements()
        {
            SetText(achievementView, "Layer/Popup/tujianzhi/Value", store.Score.ToString());
            HeroBookLevelDefinition next = ResolveNextLevel();
            SetText(achievementView, "Layer/Popup/Tips", $"达到{next.Score}激活下一成就");
            GameObject list = Find(achievementView, "Layer/Popup/ListView");
            GameObject template = Find(achievementView, "Layer/Popup/Item");
            if (list != null && template != null)
            {
                for (int index = list.transform.childCount - 1; index >= 0; index--)
                    UnityEngine.Object.Destroy(list.transform.GetChild(index).gameObject);
                template.SetActive(false);
                VerticalLayoutGroup layout = list.GetComponent<VerticalLayoutGroup>() ?? list.AddComponent<VerticalLayoutGroup>();
                layout.childControlHeight = false;
                layout.childControlWidth = true;
                layout.childForceExpandHeight = false;
                layout.spacing = 4f;
                foreach (HeroBookLevelDefinition level in catalog.Levels)
                {
                    GameObject item = UnityEngine.Object.Instantiate(template, list.transform, false);
                    item.SetActive(true);
                    SetText(item, "Title", $"图鉴值达到{level.Score}激活：");
                    for (int index = 0; index < 3; index++)
                    {
                        GameObject attr = item.transform.Find($"Attribute_{index + 1}")?.gameObject;
                        bool visible = index < level.Attributes.Count;
                        if (attr != null) attr.SetActive(visible);
                        if (visible) SetText(attr, HeroBookCatalog.FormatAttribute(level.Attributes[index]));
                    }
                    if (level.Id <= store.Level)
                        foreach (Text text in item.GetComponentsInChildren<Text>(true)) text.color = new Color32(35, 161, 46, 255);
                }
            }
            Bind(achievementView, "Layer/Popup/Btn_close", () => achievementView.SetVisible(false));
            Bind(achievementView, "Layer/Mask", () => achievementView.SetVisible(false));
            achievementView.SetVisible(true);
            achievementView.GameObject.transform.SetAsLastSibling();
        }

        private void HandleUpgradeCompleted(HeroBookUpgradeResult result)
        {
            CloseUpgrade();
            CocosUiView popup = result.Star <= 1 ? activateResultView : upgradeResultView;
            if (result.Star <= 1) RenderActivationResult(popup, result);
            else RenderUpgradeResult(popup, result);
            popup.SetVisible(true);
            popup.GameObject.transform.SetAsLastSibling();
        }

        private void RenderActivationResult(CocosUiView popup, HeroBookUpgradeResult result)
        {
            if (!catalog.TryGetHero(result.HeroId, out HeroDefinition definition)) return;
            ConfigureHeroIcon(popup, "Layer/jihuochenggongUI/IconColor", definition);
            SetText(popup, "Layer/jihuochenggongUI/Text", $"激活神将图鉴：{definition.Name}");
            SetText(popup, "Layer/jihuochenggongUI/tujianzhi/Value", result.AddedScore.ToString());
            for (int index = 0; index < 4; index++)
            {
                GameObject node = Find(popup, $"Layer/jihuochenggongUI/Atrribute_{index + 1}");
                bool visible = index < result.CardAttributes.Count;
                if (node != null) node.SetActive(visible);
                if (visible)
                {
                    SetText(node, HeroBookCatalog.AttributeName(result.CardAttributes[index].Type) + "：");
                    SetText(popup, $"Layer/jihuochenggongUI/Atrribute_{index + 1}/Value",
                        result.CardAttributes[index].Value.ToString());
                }
            }
            Bind(popup, "Layer/jihuochenggongUI/Btn_Close", () => CloseResult(popup, result));
            Bind(popup, "Layer/Mask", () => CloseResult(popup, result));
        }

        private void RenderUpgradeResult(CocosUiView popup, HeroBookUpgradeResult result)
        {
            if (!catalog.TryGetHero(result.HeroId, out HeroDefinition definition)) return;
            SetText(popup, "Layer/shengjichenggongUI/IconColor_1/Name", $"{definition.Name}图鉴{result.Star - 1}级");
            SetText(popup, "Layer/shengjichenggongUI/IconColor_2/Name", $"{definition.Name}图鉴{result.Star}级");
            ConfigureHeroIcon(popup, "Layer/shengjichenggongUI/IconColor_1", definition);
            ConfigureHeroIcon(popup, "Layer/shengjichenggongUI/IconColor_2", definition);
            store.TryGet(result.HeroId, out HeroBookEntry entry);
            SetText(popup, "Layer/shengjichenggongUI/tujianzhi/Value_1", (entry.Score - result.AddedScore).ToString());
            SetText(popup, "Layer/shengjichenggongUI/tujianzhi/Value_2", entry.Score.ToString());
            SetText(popup, "Layer/shengjichenggongUI/tujianzhi/Value_3", result.AddedScore.ToString());
            HeroBookAttribute[] oldAttrs = CalculateHeroAttributes(definition, result.Star - 1);
            HeroBookAttribute[] newAttrs = CalculateHeroAttributes(definition, result.Star);
            for (int index = 0; index < 4; index++)
            {
                string root = $"Layer/shengjichenggongUI/Atrribute_{index + 1}";
                SetText(popup, root, HeroBookCatalog.AttributeName(index + 1));
                SetText(popup, root + "/Value_1", oldAttrs[index].Value.ToString());
                SetText(popup, root + "/Value_2", newAttrs[index].Value.ToString());
                SetText(popup, root + "/Value_3", (newAttrs[index].Value - oldAttrs[index].Value).ToString());
            }
            Bind(popup, "Layer/shengjichenggongUI/Btn_Close", () => CloseResult(popup, result));
            Bind(popup, "Layer/Mask", () => CloseResult(popup, result));
        }

        private void CloseResult(CocosUiView popup, HeroBookUpgradeResult result)
        {
            popup.SetVisible(false);
            if (result.LevelAdvanced) ShowLevelResult();
        }

        private void ShowLevelResult()
        {
            HeroBookLevelDefinition level = catalog.TryGetLevel(store.Level, out HeroBookLevelDefinition value)
                ? value : ResolveNextLevel();
            SetText(levelResultView, "Layer/jihuochengjiuUI/tujianzhi", $"图鉴值达到：{store.Score}");
            for (int index = 0; index < 3; index++)
            {
                GameObject node = Find(levelResultView, $"Layer/jihuochengjiuUI/Atrribute_{index + 1}");
                bool visible = index < level.Attributes.Count;
                if (node != null) node.SetActive(visible);
                if (visible)
                {
                    SetText(node, "全体" + HeroBookCatalog.AttributeName(level.Attributes[index].Type) + "：");
                    SetText(levelResultView, $"Layer/jihuochengjiuUI/Atrribute_{index + 1}/Value",
                        "+" + HeroBookCatalog.FormatAttribute(level.Attributes[index]).Split('+').Last());
                }
            }
            Bind(levelResultView, "Layer/jihuochengjiuUI/Btn_Close", () => levelResultView.SetVisible(false));
            levelResultView.SetVisible(true);
            levelResultView.GameObject.transform.SetAsLastSibling();
        }

        private void HidePopups()
        {
            modalHeroId = 0;
            foreach (CocosUiView popup in new[] { upgradeView, activateResultView, upgradeResultView,
                         attributesView, achievementView, levelResultView }) popup.SetVisible(false);
        }

        private void ConfigureHeroIcon(CocosUiView target, string framePath, HeroDefinition definition)
        {
            Image frame = Find(target, framePath)?.GetComponent<Image>();
            if (frame != null)
            {
                frame.sprite = resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(definition.Quality, 1, 7):00}");
                frame.enabled = frame.sprite != null;
                frame.type = Image.Type.Simple;
                frame.preserveAspect = true;
            }

            Image portrait = Find(target, framePath + "/Icon")?.GetComponent<Image>();
            if (portrait == null) return;
            portrait.sprite = resources.LoadHeroPortrait(definition.Picture);
            portrait.enabled = portrait.sprite != null;
            portrait.type = Image.Type.Simple;
            portrait.preserveAspect = true;
        }

        private static Button Bind(CocosUiView target, string path, Action action)
        {
            GameObject node = Find(target, path);
            Button button = EnsureButton(node);
            if (button == null) return null;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
            return button;
        }

        private static Button EnsureButton(GameObject node)
        {
            if (node == null) return null;
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            Graphic graphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.targetGraphic = graphic;
            button.interactable = true;
            if (graphic != null) graphic.raycastTarget = true;
            return button;
        }

        private static GameObject Find(CocosUiView target, string path) => target?.Binding.Find(path);
        private static void SetText(CocosUiView target, string path, string value) => SetText(Find(target, path), value);
        private static void SetText(GameObject root, string path, string value)
            => SetText(root?.transform.Find(path)?.gameObject, value);
        private static void SetText(GameObject target, string value)
        {
            Text text = target?.GetComponent<Text>() ?? target?.GetComponentInChildren<Text>(true);
            if (text != null) text.text = value ?? string.Empty;
        }
    }
}
