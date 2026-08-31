using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class WorldPresenter : IDisposable
    {
        private const string ListViewportPath = "Layer/Popup/ListView";
        private const string ListTemplatePath = "Layer/Popup/ListView/Button_1";
        private const string DetailRoot = "Layer/Panel_1/Pane/Descbg";
        private static readonly Dictionary<string, Sprite> RuntimeSprites = new Dictionary<string, Sprite>();
        private readonly Dictionary<uint, Button> normalBoxButtons = new Dictionary<uint, Button>();
        private readonly CocosUiView worldView;
        private readonly CocosUiView stageView;
        private readonly CocosUiView mapView;
        private readonly CocosUiView detailView;
        private readonly WorldStore store;
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly PlayerStore player;
        private readonly ResourceService resources;
        private readonly CurrencyStore currencies;
        private readonly ShopCatalog itemCatalog;
        private readonly EquipmentCatalog equipmentCatalog;
        private readonly Action<uint> requestChapter;
        private readonly Action<uint> requestStage;
        private readonly Action challenge;
        private readonly Action sweep;
        private readonly Action<WorldStageRecord> requestReset;
        private readonly Action<uint> claimBox;
        private readonly Action<WorldStageRecord> showNormalBox;
        private readonly Action openFormation;
        private readonly Action close;
        private readonly Action closeStage;
        private readonly Action<string> validationControl;
        private readonly VirtualList<ListEntry> list;
        private readonly ScrollRect stageMapScroll;
        private readonly RectTransform stageMapContent;
        private ImodAnimationPlayer stagePlayerModel;
        private bool showChapters = true;
        private bool showDetail;
        private bool showDropdown;
        private int chapterPageStart;

        public WorldPresenter(CocosUiView worldView, CocosUiView stageView, CocosUiView mapView, CocosUiView detailView,
            WorldStore store, HeroStore heroes, FormationStore formation, PlayerStore player, ResourceService resources, CurrencyStore currencies,
            ShopCatalog itemCatalog,
            EquipmentCatalog equipmentCatalog,
            Action<uint> requestChapter, Action<uint> requestStage, Action challenge, Action sweep,
            Action<WorldStageRecord> requestReset, Action<uint> claimBox, Action<WorldStageRecord> showNormalBox, Action openFormation, Action close,
            Action closeStage,
            Action<string> validationControl = null)
        {
            this.worldView = worldView ?? throw new ArgumentNullException(nameof(worldView));
            this.stageView = stageView ?? throw new ArgumentNullException(nameof(stageView));
            this.mapView = mapView ?? throw new ArgumentNullException(nameof(mapView));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.itemCatalog = itemCatalog ?? throw new ArgumentNullException(nameof(itemCatalog));
            this.equipmentCatalog = equipmentCatalog ?? throw new ArgumentNullException(nameof(equipmentCatalog));
            this.requestChapter = requestChapter ?? throw new ArgumentNullException(nameof(requestChapter));
            this.requestStage = requestStage ?? throw new ArgumentNullException(nameof(requestStage));
            this.challenge = challenge ?? throw new ArgumentNullException(nameof(challenge));
            this.sweep = sweep ?? throw new ArgumentNullException(nameof(sweep));
            this.requestReset = requestReset ?? throw new ArgumentNullException(nameof(requestReset));
            this.claimBox = claimBox ?? throw new ArgumentNullException(nameof(claimBox));
            this.showNormalBox = showNormalBox ?? throw new ArgumentNullException(nameof(showNormalBox));
            this.openFormation = openFormation ?? throw new ArgumentNullException(nameof(openFormation));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.closeStage = closeStage ?? throw new ArgumentNullException(nameof(closeStage));
            this.validationControl = validationControl;

            EnsureWorldMapBackdrop();
            ReparentOverlay(stageView, worldView.GameObject.transform, false);
            ReparentOverlay(mapView, worldView.GameObject.transform, true);
            ReparentOverlay(detailView, stageView.GameObject.transform, false);
            ConfigureDetailMask();
            (stageMapScroll, stageMapContent) = CreateStageMapScroll();
            GameObject popup = Require(mapView, "Layer/Popup");
            popup.SetActive(false);
            RectTransform popupRect = popup.GetComponent<RectTransform>();
            if (popupRect != null)
            {
                popupRect.anchorMin = new Vector2(0.03f, 0.16f);
                popupRect.anchorMax = new Vector2(0.43f, 0.82f);
                popupRect.offsetMin = popupRect.offsetMax = Vector2.zero;
            }
            GameObject viewport = Require(mapView, ListViewportPath);
            RectTransform viewportRect = viewport.GetComponent<RectTransform>();
            if (viewportRect != null)
            {
                viewportRect.anchorMin = Vector2.zero;
                viewportRect.anchorMax = Vector2.one;
                viewportRect.offsetMin = new Vector2(18f, 18f);
                viewportRect.offsetMax = new Vector2(-18f, -18f);
            }
            list = new VirtualList<ListEntry>(viewport, Require(mapView, ListTemplatePath), 76f, BindRow);

            Bind(mapView, "Layer/Panel_zuoshang/Button_xiala", () => { showDropdown = !showDropdown; Render(); Mark("WORLD-04-CHAPTER-DROPDOWN"); });
            Bind(mapView, "Layer/Title/CloseBtn", () =>
            {
                closeStage();
                Mark("WORLD-08-STAGE-CLOSE");
            });
            Bind(worldView, "Layer/Button_1", () => { NavigateChapter(-1); Mark("WORLD-02-CHAPTER-PREV"); });
            Bind(worldView, "Layer/Button_2", () => { NavigateChapter(1); Mark("WORLD-03-CHAPTER-NEXT"); });
            for (int index = 1; index <= 5; index++)
            {
                int slot = index - 1;
                Bind(worldView, $"Layer/chapterPage/btn_{index}", () => { OpenChapterSlot(slot); Mark("WORLD-06-CHAPTER-NODE"); });
            }
            for (int index = 1; index <= 3; index++)
            {
                int slot = index - 1;
                Bind(mapView, $"Layer/Panel_1/Box{index}/Button", () => ClaimBoxSlot(slot));
                Bind(mapView, $"Layer/Panel_1/Box{index}/Button1", () => ClaimBoxSlot(slot));
            }
            Bind(detailView, $"{DetailRoot}/Close", () => { CloseDetail(); Mark("WORLD-13-STAGE-DETAIL-CLOSE"); });
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2", () => { challenge(); Mark("WORLD-14-CHALLENGE"); });
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_1", () => { challenge(); Mark("WORLD-14-CHALLENGE"); });
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_3", () => { sweep(); Mark("WORLD-15-SWEEP"); });
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_4/TimesBg/AddBtn", () => { requestReset(store.SelectedStage); Mark("WORLD-16-RESET-ATTEMPTS"); });
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_1/Buzhen", () => { openFormation(); Mark("WORLD-18-PRECHALLENGE-FORMATION"); });
            SetButtonLabel(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2", "挑战");
            SetButtonLabel(detailView, $"{DetailRoot}/Image_bg/Panel_1/Buzhen", "布 阵");
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_1/Duizhan", false);
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_1/Buzhen/Image", true);
            SetActive(detailView, "Layer/IconColor", false);
            SetActive(detailView, "Layer/IconBg1", false);
            SetActive(mapView, "Layer/Panel_youxia/Button_zhuxianchengjiu", true);
            SetActive(mapView, "Layer/Panel_youxia/Button_fengshenshilian", false);
            SetActive(mapView, "Layer/Panel_youxia/Button_youlisanjie", false);
            SetActive(mapView, "Layer/Panel_1/Button_paihangbang", true);
            // The imported decorative title background overlaps Button_xiala.
            // Cocos does not treat that ImageView as an input surface, while a
            // Unity Image defaults to raycastTarget=true and blocks real clicks.
            Image titleBackground = Find(mapView, "Layer/Title/bg")?.GetComponent<Image>();
            if (titleBackground != null) titleBackground.raycastTarget = false;

            store.Changed += Render;
            heroes.Changed += Render;
            formation.Changed += Render;
            currencies.Changed += Render;
            Render();
        }

        public int RenderedCount => list.Count;
        public int RenderedRewardCount { get; private set; }
        public bool DetailVisible => showDetail && store.SelectedStage != null;

        public Button FindNormalBoxButton(uint stageId) =>
            normalBoxButtons.TryGetValue(stageId, out Button button) ? button : null;

        public void ShowWorld()
        {
            showDetail = false;
            showDropdown = false;
            // /320 op=1 is the Cocos world/chapters surface regardless of a
            // previous op=2 cache.  Do not leak a prior chapter's stage rows over
            // the actual world map while a fresh world response is being rendered.
            showChapters = true;
            Render();
        }

        public void ShowStages()
        {
            showDetail = false;
            showDropdown = false;
            showChapters = false;
            Render();
        }

        public void ShowSelectedStage()
        {
            showChapters = false;
            showDetail = store.SelectedStage != null;
            showDropdown = false;
            Render();
        }

        public void Render()
        {
            // The Cocos root owns the chapter-page map. DadituuiLayer contributes
            // the shared top chrome on both chapter and stage surfaces.
            stageView.GameObject.SetActive(!showChapters);
            mapView.GameObject.SetActive(!showDetail);
            detailView.GameObject.SetActive(DetailVisible);
            SetActive(mapView, "Layer/Panel_1", !showChapters);
            GameObject popup = Find(mapView, "Layer/Popup");
            if (popup != null) popup.SetActive(!showChapters && !showDetail && showDropdown);
            IReadOnlyList<ListEntry> entries = (showChapters || showDropdown)
                ? store.Chapters.Select(ListEntry.ForChapter).ToArray()
                : store.Stages.Select(ListEntry.ForStage).ToArray();
            list.SetItems(entries);
            RenderWorldChapters();
            RenderStageMap();
            RenderStarBoxes();
            string chapterName = store.SelectedChapterName;
            if (string.IsNullOrWhiteSpace(chapterName)
                && WorldVisualCatalog.TryGetChapter(store.SelectedChapterId, out WorldChapterVisualDefinition selectedVisual))
                chapterName = selectedVisual.Name;
            SetText(mapView, "Layer/Panel_zuoshang/Image_bg2/guanqia",
                showChapters ? "章节列表" : string.IsNullOrEmpty(chapterName) ? "关卡"
                    : $"{store.SelectedChapterId % 1000} {chapterName}");
            Text chapterTitle = Find(mapView, "Layer/Panel_zuoshang/Image_bg2/guanqia")?.GetComponent<Text>();
            if (chapterTitle != null)
            {
                chapterTitle.horizontalOverflow = HorizontalWrapMode.Overflow;
                RectTransform titleRect = chapterTitle.transform as RectTransform;
                if (titleRect != null) titleRect.sizeDelta = new Vector2(260f, titleRect.sizeDelta.y);
            }
            RenderCurrencies();
            RenderDetail(store.SelectedStage);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            heroes.Changed -= Render;
            formation.Changed -= Render;
            currencies.Changed -= Render;
            normalBoxButtons.Clear();
            list.Dispose();
        }

        private void ShowChapterList()
        {
            showDetail = false;
            showChapters = true;
            showDropdown = false;
            Render();
        }

        private void CloseDetail()
        {
            showDetail = false;
            showChapters = false;
            showDropdown = false;
            Render();
        }

        private void NavigateChapter(int delta)
        {
            int current = Math.Max(0, store.Chapters.ToList().FindIndex(value => value.Id == store.SelectedChapterId));
            int target = current + delta;
            if (target < 0 || target >= store.Chapters.Count) return;
            requestChapter(store.Chapters[target].Id);
        }

        private void OpenChapterSlot(int slot)
        {
            int chapterIndex = chapterPageStart + slot;
            if (chapterIndex < 0 || chapterIndex >= store.Chapters.Count) return;
            requestChapter(store.Chapters[chapterIndex].Id);
        }

        private void ClaimBoxSlot(int slot)
        {
            WorldStarBoxRecord box = slot >= 0 && slot < store.StarBoxes.Count ? store.StarBoxes[slot] : null;
            if (box == null || box.State != 1) return;
            claimBox(box.RewardId);
            Mark("WORLD-12-STAR-BOX");
        }

        private void RenderWorldChapters()
        {
            int currentIndex = Math.Max(0, store.Chapters.ToList()
                .FindIndex(value => value.Id == store.CurrentChapterId));
            chapterPageStart = currentIndex / 5 * 5;
            WorldChapterVisualDefinition pageVisual = null;
            for (int index = 0; index < 5; index++)
            {
                int chapterIndex = chapterPageStart + index;
                WorldChapterRecord chapter = chapterIndex < store.Chapters.Count
                    ? store.Chapters[chapterIndex] : null;
                string root = $"Layer/chapterPage/btn_{index + 1}";
                SetActive(worldView, root, chapter != null);
                if (chapter == null) continue;

                WorldVisualCatalog.TryGetChapter(chapter.Id, out WorldChapterVisualDefinition visual);
                pageVisual = pageVisual ?? visual;
                GameObject buttonObject = Find(worldView, root);
                if (buttonObject != null && visual != null)
                {
                    RectTransform rect = buttonObject.transform as RectTransform;
                    if (rect != null) rect.anchoredPosition = visual.Position;
                    Image image = buttonObject.GetComponent<Image>();
                    if (image != null)
                    {
                        image.sprite = LoadRuntimeSprite($"WorldUI/Chapters/{visual.ButtonImage}");
                        image.enabled = image.sprite != null;
                        image.preserveAspect = true;
                    }
                }

                bool unlocked = chapter.Id <= store.CurrentChapterId;
                bool current = chapter.Id == store.CurrentChapterId;
                SetText(worldView, root + "/Label/Text", chapter.Name);
                SetText(worldView, root + "/Label/Text/xuhao", (chapter.Id % 1000).ToString());
                SetText(worldView, root + "/Text_xing", $"{chapter.OwnedStars}/{chapter.MaximumStars}");
                SetText(worldView, root + "/suo/lock", string.Empty);
                SetActive(worldView, root + "/Label", unlocked);
                SetActive(worldView, root + "/Text_xing", unlocked);
                SetActive(worldView, root + "/suo", !unlocked);
                SetActive(worldView, root + "/HeadBg", current);
                Image portrait = Find(worldView, root + "/HeadBg/Icon")?.GetComponent<Image>();
                if (portrait != null && current)
                {
                    portrait.sprite = resources.LoadPlayerRoundPortrait(player.Head);
                    portrait.enabled = portrait.sprite != null;
                    portrait.preserveAspect = true;
                }
                SetActive(worldView, root + "/Finish", unlocked && !current
                    && chapter.OwnedStars < chapter.MaximumStars);
                SetActive(worldView, root + "/perfect", unlocked && chapter.MaximumStars > 0
                    && chapter.OwnedStars >= chapter.MaximumStars);
                SetActive(worldView, root + "/boxBg", chapter.ClaimedBoxes > 0);
            }

            SetActive(worldView, "Layer/Image_qipao_L", false);
            SetActive(worldView, "Layer/Image_qipao_R", false);
            if (pageVisual != null)
            {
                Image background = Find(worldView, "Layer/chapterPage/Image")?.GetComponent<Image>();
                if (background != null)
                {
                    background.sprite = LoadRuntimeSprite($"WorldUI/Chapters/{pageVisual.Background}");
                    background.enabled = background.sprite != null;
                    background.preserveAspect = false;
                }
            }
        }

        private void RenderCurrencies()
        {
            SetText(mapView, "Layer/GoldCheck/GoldIcon1/GoldNumBg/Num", FormatCompact(currencies.Gold));
            SetText(mapView, "Layer/GoldCheck/GoldIcon3/GoldNumBg/Num", currencies.Premium.ToString());
            SetText(mapView, "Layer/GoldCheck/GoldIcon4/GoldNumBg/Num", $"{currencies.Stamina}/100");
        }

        private static string FormatCompact(long value)
        {
            if (value >= 10000) return (value / 10000) + "万";
            return value.ToString();
        }

        private void RenderStarBoxes()
        {
            WorldChapterRecord selectedChapter = store.Chapters.FirstOrDefault(
                value => value.Id == store.SelectedChapterId);
            if (selectedChapter != null)
                SetText(mapView, "Layer/Panel_1/xingshu",
                    $"{selectedChapter.OwnedStars}/{selectedChapter.MaximumStars}");
            for (int index = 0; index < 3; index++)
            {
                WorldStarBoxRecord box = index < store.StarBoxes.Count ? store.StarBoxes[index] : null;
                bool open = box != null && box.State >= 2;
                bool claimable = box != null && box.State == 1;
                SetActive(mapView, $"Layer/Panel_1/Box{index + 1}/Button", open);
                SetActive(mapView, $"Layer/Panel_1/Box{index + 1}/Button1", !open && box != null);
                SetActive(mapView, $"Layer/Panel_1/Box{index + 1}/Button1/Image_1", claimable);
                SetActive(mapView, $"Layer/Panel_1/Box{index + 1}/effect_tuitu_1", claimable);
            }
        }

        private void BindRow(RectTransform row, ListEntry entry, int index)
        {
            SetNamedText(row, "zhangjie", entry.Title);
            SetNamedText(row, "xing_num", entry.Subtitle);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>(true);
            button.interactable = entry.Enabled;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                if (entry.IsChapter)
                {
                    showChapters = false;
                    showDetail = false;
                    showDropdown = false;
                    requestChapter(entry.Id);
                    Mark("WORLD-05-CHAPTER-QUICK-ROW");
                }
                else
                {
                    requestStage(entry.Id);
                    showDetail = true;
                    Render();
                    Mark("WORLD-10-STAGE-NODE");
                }
            });
        }

        private void RenderDetail(WorldStageRecord stage)
        {
            if (stage == null) return;
            string stageTitle = WorldVisualCatalog.TryGetStage(stage.Id, out WorldStageVisualDefinition visual)
                && !string.IsNullOrWhiteSpace(visual.Name) ? visual.Name : stage.Name;
            SetText(detailView, "Layer/Panel_1/Pane/Panel_left/TextPanel/Text_num", stageTitle);
            for (int index = 1; index <= 3; index++)
                SetActive(detailView, $"Layer/Panel_1/Pane/Panel_left/StarList/Star{index}/Star", stage.Stars >= index);
            int maxAttempts = visual?.MaxAttempts > 0 ? visual.MaxAttempts : stage.RemainingAttempts;
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_4/TimesBg/Icon/Num",
                $"{stage.RemainingAttempts}/{maxAttempts}");
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_1/Tili", true);
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_1/Tili/Value", stage.SpiritCost.ToString());
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_1/Desc/Desc_0", FormationSummary());
            GameObject challengeButton = Require(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2");
            Button challengeComponent = challengeButton.GetComponent<Button>();
            if (challengeComponent != null) challengeComponent.interactable = stage.IsUnlocked && stage.RemainingAttempts > 0;
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_1", false);
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_3", stage.IsUnlocked && stage.Stars > 0);
            int sweepCount = Math.Min(5, (int)stage.RemainingAttempts);
            SetButtonLabel(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_3", $"扫荡{sweepCount}次");
            Button sweepButton = Find(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_3")?.GetComponent<Button>();
            if (sweepButton != null) sweepButton.interactable = stage.RemainingAttempts > 0;
            Button resetButton = Find(detailView, $"{DetailRoot}/Image_bg/Panel_4/TimesBg/AddBtn")?.GetComponent<Button>();
            if (resetButton != null) resetButton.interactable = stage.RemainingAttempts == 0 && stage.RemainingResets > 0;

            BuildStagePreviewRewards(stage, out RewardRecord[] currencyRewards, out RewardRecord[] itemRewards);
            RenderedRewardCount = currencyRewards.Length + itemRewards.Length;
            for (int index = 0; index < 4; index++)
            {
                string root = $"{DetailRoot}/Image_bg/Panel_2/GoldIcon{index + 1}";
                bool active = index < currencyRewards.Length;
                SetActive(detailView, root, active);
                if (!active) continue;
                RewardRecord reward = currencyRewards[index];
                SetText(detailView, root + "/Num", reward.Amount.ToString());
                Image icon = Find(detailView, root + "/Icon")?.GetComponent<Image>();
                if (icon != null)
                {
                    Sprite sprite = reward.Picture > 0 ? resources.LoadItemIcon(reward.Picture) : null;
                    icon.sprite = sprite;
                    icon.enabled = sprite != null;
                    icon.preserveAspect = true;
                }
            }
            RenderStageDrops(itemRewards);
        }

        private void BuildStagePreviewRewards(WorldStageRecord stage, out RewardRecord[] currencyRewards,
            out RewardRecord[] itemRewards)
        {
            if (!WorldVisualCatalog.TryGetStage(stage.Id, out WorldStageVisualDefinition visual)
                || visual.ShowRewards.Length == 0)
            {
                currencyRewards = stage.CurrencyRewards.Take(4).ToArray();
                itemRewards = stage.ItemRewards.Take(4).ToArray();
                return;
            }

            var currenciesFromConfig = new List<RewardRecord>();
            var itemsFromConfig = new List<RewardRecord>();
            foreach (WorldConfiguredReward configured in visual.ShowRewards)
            {
                uint amount = checked((uint)Math.Max(0, configured.Amount));
                if (configured.Type == 60052 && amount == 0)
                {
                    amount = checked((uint)(Math.Max(1, visual.Hope) * Math.Max(1, CurrentPlayerLevel()) * 2));
                }
                RewardRecord reward;
                if (configured.Type == 60005)
                {
                    EquipmentDefinition equipment = equipmentCatalog.GetEquipment(configured.Id);
                    reward = new RewardRecord(configured.Type, checked((uint)Math.Max(0, configured.Id)), amount,
                        equipment.Name, 0, equipment.Quality);
                }
                else reward = itemCatalog.DescribeReward(configured.Type, configured.Id, amount);
                if (IsCocosSpecialItem(configured.Type)) currenciesFromConfig.Add(reward);
                else itemsFromConfig.Add(reward);
            }
            currencyRewards = currenciesFromConfig
                .OrderBy(value => CurrencyPreviewOrder(value.Type)).Take(4).ToArray();
            itemRewards = itemsFromConfig.Take(4).ToArray();
        }

        private int CurrentPlayerLevel()
        {
            return Math.Max(1, (int)player.Level);
        }

        private static bool IsCocosSpecialItem(int type)
        {
            switch (type)
            {
                case 60000: case 60001: case 60003: case 60006: case 60007: case 60008:
                case 60009: case 60010: case 60011: case 60014: case 60015: case 60021:
                case 60025: case 60026: case 60027: case 60029: case 60030: case 60050:
                case 60051: case 60052: case 60053:
                    return true;
                default:
                    return false;
            }
        }

        private static int CurrencyPreviewOrder(int type)
        {
            if (type == 60052) return 0;
            if (type == 60000) return 1;
            if (type == 60006) return 2;
            return 3;
        }

        private void RenderStageDrops(IReadOnlyList<RewardRecord> values)
        {
            Transform host = Find(detailView, $"{DetailRoot}/Image_bg/Panel_3/ListView_1")?.transform;
            GameObject template = Find(detailView, "Layer/IconBg1");
            if (host == null || template == null) return;
            foreach (Transform child in host)
            {
                if (!child.name.StartsWith("RuntimeStageDrop_", StringComparison.Ordinal)) continue;
                child.gameObject.SetActive(false);
                UnityEngine.Object.Destroy(child.gameObject);
            }
            for (int index = 0; index < values.Count; index++)
            {
                RewardRecord reward = values[index];
                GameObject entry = UnityEngine.Object.Instantiate(template, host, false);
                entry.name = "RuntimeStageDrop_" + index;
                entry.SetActive(true);
                RectTransform rect = entry.transform as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = rect.anchorMax = new Vector2(0f, 0.5f);
                    rect.pivot = new Vector2(0f, 0.5f);
                    rect.anchoredPosition = new Vector2(index * 130f, 0f);
                    rect.localScale = Vector3.one;
                }
                Transform iconHost = entry.transform.Find("Bg");
                if (iconHost != null)
                {
                    Image qualityFrame = iconHost.GetComponent<Image>();
                    if (qualityFrame != null)
                    {
                        qualityFrame.sprite = resources.LoadFirst(
                            $"HeroUI/common_quality_{Mathf.Clamp(reward.Quality, 1, 7):00}");
                        qualityFrame.enabled = qualityFrame.sprite != null;
                    }
                    GameObject iconObject = new GameObject("RuntimeIcon", typeof(RectTransform),
                        typeof(CanvasRenderer), typeof(Image));
                    RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                    iconRect.SetParent(iconHost, false);
                    iconRect.anchorMin = new Vector2(0.12f, 0.18f);
                    iconRect.anchorMax = new Vector2(0.88f, 0.94f);
                    iconRect.offsetMin = iconRect.offsetMax = Vector2.zero;
                    Image icon = iconObject.GetComponent<Image>();
                    icon.sprite = reward.Type == 60005
                        ? resources.LoadEquipmentIcon(equipmentCatalog.GetEquipment(checked((int)reward.Id)).Picture)
                        : itemCatalog.IsCocosHeroSoul(reward.Type)
                            ? resources.LoadHeroPortrait(reward.Picture)
                        : reward.Picture > 0 ? resources.LoadItemIcon(reward.Picture) : null;
                    icon.enabled = icon.sprite != null;
                    icon.preserveAspect = true;
                    icon.raycastTarget = false;
                }
                Text name = entry.transform.Find("Bg/TextBg/Name")?.GetComponent<Text>();
                if (name != null) name.text = reward.Name;
                CreateStageLabel(entry.transform, "RuntimeAmount", reward.Amount.ToString(),
                    new Vector2(0.56f, 0.12f), new Vector2(0.96f, 0.36f), 18);
            }
        }

        private string FormationSummary()
        {
            var names = new List<string>();
            foreach (int heroId in formation.CombatHeroes)
            {
                if (heroId <= 0) continue;
                names.Add(heroes.TryGet(heroId, out HeroRecord hero) ? hero.Name : $"神将#{heroId}");
            }
            return names.Count == 0 ? "当前阵容：主角" : "当前阵容：" + string.Join("、", names);
        }

        private static void ReparentOverlay(CocosUiView view, Transform parent, bool active)
        {
            RectTransform rect = view.GameObject.transform as RectTransform;
            view.GameObject.transform.SetParent(parent, false);
            // Cocos Studio's runtime calls doLayout after adding these full-screen
            // layers.  Imported Prefabs do not receive that pass automatically;
            // normalize their roots to the 1334x750 parent before showing them.
            if (rect != null)
            {
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                rect.localScale = Vector3.one;
            }
            view.GameObject.SetActive(active);
        }

        private void ConfigureDetailMask()
        {
            GameObject maskObject = Find(detailView, "Layer/Panel_1/Black");
            if (maskObject == null) return;
            RectTransform rect = maskObject.transform as RectTransform;
            if (rect != null)
            {
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
            }
            Image image = maskObject.GetComponent<Image>() ?? maskObject.AddComponent<Image>();
            // Cocos blends this 0.8 black panel in gamma space.  The Unity project
            // renders UI in linear space, so 0.55 gives the same captured darkness.
            image.color = new Color(0f, 0f, 0f, 0.55f);
            image.raycastTarget = false;
            maskObject.SetActive(true);
            maskObject.transform.SetAsFirstSibling();
        }

        private void EnsureWorldMapBackdrop()
        {
            const string name = "WorldMapBackdrop";
            Transform existing = worldView.GameObject.transform.Find(name);
            if (existing != null) return;
            Sprite sprite = Resources.Load<Sprite>("WorldUI/worldmap");
            if (sprite == null)
            {
                Texture2D texture = Resources.Load<Texture2D>("WorldUI/worldmap");
                if (texture == null) return;
                sprite = Sprite.Create(texture, new Rect(0f, 0f, texture.width, texture.height),
                    new Vector2(0.5f, 0.5f), 100f);
            }
            // `chapterPage/Image` is the opaque Cocos background node.  Replacing
            // that node is required: adding a sibling beneath it leaves the
            // original white ImageView in front of the new texture.
            Image cocosBackground = Find(worldView, "Layer/chapterPage/Image")?.GetComponent<Image>();
            if (cocosBackground != null)
            {
                cocosBackground.sprite = sprite;
                cocosBackground.enabled = true;
                cocosBackground.preserveAspect = false;
                return;
            }

            Transform contentRoot = worldView.GameObject.transform;
            GameObject layer = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            layer.transform.SetParent(contentRoot, false);
            RectTransform rect = layer.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = layer.GetComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = false;
            image.raycastTarget = false;
            layer.transform.SetAsFirstSibling();
        }

        private (ScrollRect scroll, RectTransform content) CreateStageMapScroll()
        {
            GameObject viewportObject = new GameObject("RuntimeStageMapViewport", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image), typeof(RectMask2D), typeof(ScrollRect));
            viewportObject.transform.SetParent(stageView.GameObject.transform, false);
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            viewport.anchorMin = new Vector2(0.08f, 0.17f);
            viewport.anchorMax = new Vector2(0.92f, 0.78f);
            viewport.offsetMin = viewport.offsetMax = Vector2.zero;
            Image background = viewportObject.GetComponent<Image>();
            background.color = Color.clear;
            background.raycastTarget = true;
            GameObject contentObject = new GameObject("Content", typeof(RectTransform));
            contentObject.transform.SetParent(viewport, false);
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.anchorMin = new Vector2(0f, 0.5f);
            content.anchorMax = new Vector2(0f, 0.5f);
            content.pivot = new Vector2(0f, 0.5f);
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = true;
            scroll.vertical = false;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.inertia = true;
            scroll.scrollSensitivity = 24f;
            viewportObject.SetActive(false);
            return (scroll, content);
        }

        private void RenderStageMap()
        {
            if (stageMapScroll == null || stageMapContent == null) return;
            bool visible = !showChapters && !showDetail;
            stageMapScroll.gameObject.SetActive(visible);
            if (!visible) return;
            WorldChapterVisualDefinition chapterVisual = null;
            WorldMapVisualDefinition mapVisual = null;
            if (WorldVisualCatalog.TryGetChapter(store.SelectedChapterId, out chapterVisual))
                WorldVisualCatalog.TryGetMap(chapterVisual.BundleId, out mapVisual);
            RenderStageBackdrop(mapVisual);

            // FuBenDetailUI positions and fills these native Cocos nodes from
            // map_res/maplist/fight/monster data after loading the CSB. Mirror
            // that dynamic pass instead of exposing the design-time placeholders.
            for (int index = 0; index < 10; index++)
            {
                GameObject nativeNode = Find(stageView, $"Layer/ScrollPanel/Node_{index + 1}");
                WorldStageRecord stage = index < store.Stages.Count ? store.Stages[index] : null;
                if (nativeNode == null) continue;
                nativeNode.SetActive(stage != null);
                if (stage != null) RenderNativeStage(nativeNode, stage, index, mapVisual);
            }
            RenderStagePlayer(mapVisual);
            PositionStageCamera(mapVisual);
            foreach (Transform child in stageMapContent)
            {
                // Destroy is deferred until end-of-frame.  Chapter switching and
                // validation can happen in the same frame, so retire the old
                // controls synchronously before creating the new chapter nodes.
                child.gameObject.SetActive(false);
                child.name = "Retired_" + child.name;
                UnityEngine.Object.Destroy(child.gameObject);
            }
            float width = 184f;
            float height = Math.Max(160f, stageMapScroll.viewport.rect.height - 36f);
            for (int index = 0; index < store.Stages.Count; index++)
            {
                WorldStageRecord stage = store.Stages[index];
                GameObject node = new GameObject("Stage_" + stage.Id, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
                node.transform.SetParent(stageMapContent, false);
                RectTransform rect = node.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 0.5f);
                rect.pivot = new Vector2(0f, 0.5f);
                rect.sizeDelta = new Vector2(width - 16f, height);
                rect.anchoredPosition = new Vector2(16f + index * width, 0f);
                Image image = node.GetComponent<Image>();
                image.color = Color.clear;
                Button button = node.GetComponent<Button>();
                button.targetGraphic = image;
                button.interactable = stage.IsUnlocked;
                uint stageId = stage.Id;
                button.onClick.AddListener(() => { requestStage(stageId); showDetail = true; Render(); Mark("WORLD-10-STAGE-NODE"); });
            }
            float backdropWidth = mapVisual != null ? mapVisual.Size.x * (750f / 1080f) : 0f;
            stageMapContent.sizeDelta = new Vector2(Math.Max(stageMapScroll.viewport.rect.width,
                Math.Max(store.Stages.Count * width + 16f, backdropWidth)), stageMapScroll.viewport.rect.height);
            stageMapScroll.horizontalNormalizedPosition = 0f;
        }

        private void RenderStageBackdrop(WorldMapVisualDefinition map)
        {
            Transform scroll = Find(stageView, "Layer/ScrollPanel")?.transform;
            Transform mapPanel = Find(stageView, "Layer/ScrollPanel/MapPanel")?.transform;
            if (scroll == null || mapPanel == null || map == null) return;
            RectTransform scrollRect = scroll as RectTransform;
            if (scrollRect != null && map.CameraCoordinates.Length > 0)
                scrollRect.anchoredPosition = -map.CameraCoordinates[0];
            RectTransform mapRect = mapPanel as RectTransform;
            if (mapRect != null)
            {
                mapRect.sizeDelta = map.Size;
                // FuBenDetailUI.lua scales only MapPanel by 750/1080. Stage nodes
                // remain direct ScrollPanel children and therefore stay unscaled.
                mapRect.localScale = Vector3.one * (750f / 1080f);
            }

            string marker = "RuntimeMap_" + map.Folder;
            if (mapPanel.Find(marker) != null) return;
            foreach (Transform child in mapPanel)
                if (child.name.StartsWith("RuntimeMap_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            GameObject root = new GameObject(marker, typeof(RectTransform));
            RectTransform rootRect = root.GetComponent<RectTransform>();
            rootRect.SetParent(mapPanel, false);
            rootRect.anchorMin = rootRect.anchorMax = Vector2.zero;
            rootRect.pivot = Vector2.zero;
            rootRect.anchoredPosition = Vector2.zero;
            rootRect.sizeDelta = map.Size;
            root.transform.SetAsFirstSibling();

            int columns = Mathf.CeilToInt(map.Size.x / 1024f);
            int rows = Mathf.CeilToInt(map.Size.y / 1024f);
            int tile = 1;
            for (int row = 0; row < rows; row++)
            {
                for (int column = 0; column < columns; column++, tile++)
                {
                    Sprite sprite = LoadRuntimeSprite($"WorldUI/Maps/{map.Folder}/map_{tile}");
                    if (sprite == null) continue;
                    GameObject imageObject = new GameObject("Tile_" + tile,
                        typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                    RectTransform rect = imageObject.GetComponent<RectTransform>();
                    rect.SetParent(rootRect, false);
                    rect.anchorMin = rect.anchorMax = Vector2.zero;
                    rect.pivot = new Vector2(0f, 1f);
                    rect.anchoredPosition = new Vector2(column * 1024f, map.Size.y - row * 1024f);
                    rect.sizeDelta = sprite.rect.size;
                    Image image = imageObject.GetComponent<Image>();
                    image.sprite = sprite;
                    image.raycastTarget = false;
                }
            }
        }

        private void RenderNativeStage(GameObject node, WorldStageRecord stage, int index,
            WorldMapVisualDefinition map)
        {
            RectTransform rect = node.transform as RectTransform;
            if (rect != null && map != null && index < map.MonsterCoordinates.Length)
                rect.anchoredPosition = map.MonsterCoordinates[index] + new Vector2(0f, 100f);
            Text name = node.transform.Find("Text_name")?.GetComponent<Text>();
            if (name != null)
            {
                name.text = stage.Name;
                name.gameObject.SetActive(stage.IsUnlocked);
            }
            Transform speech = node.transform.Find("Image_qipao");
            bool currentStage = stage.Id == store.CurrentStageId;
            if (speech != null)
            {
                speech.gameObject.SetActive(currentStage);
                if (currentStage && WorldVisualCatalog.TryGetStage(stage.Id,
                    out WorldStageVisualDefinition currentVisual))
                {
                    Text speechText = speech.Find("Text_1_4")?.GetComponent<Text>();
                    if (speechText != null) speechText.text = currentVisual.Description;
                }
            }
            Transform battle = node.transform.Find("zhandou");
            if (battle != null) battle.gameObject.SetActive(currentStage);
            for (int star = 0; star < 3; star++)
            {
                Transform bright = node.transform.Find("laingxing_" + star);
                Transform dark = node.transform.Find("anxing_" + star);
                if (bright != null) bright.gameObject.SetActive(stage.Stars != byte.MaxValue && stage.Stars > star);
                if (dark != null) dark.gameObject.SetActive(stage.Stars == byte.MaxValue || stage.Stars <= star);
            }

            Transform touch = node.transform.Find("touchLayer");
            if (touch != null)
            {
                Button button = touch.GetComponent<Button>() ?? touch.gameObject.AddComponent<Button>();
                button.targetGraphic = touch.GetComponent<Graphic>() ?? touch.GetComponentInChildren<Graphic>(true);
                button.interactable = stage.IsUnlocked;
                button.onClick.RemoveAllListeners();
                uint stageId = stage.Id;
                button.onClick.AddListener(() =>
                {
                    requestStage(stageId);
                    showDetail = true;
                    Render();
                    Mark("WORLD-10-STAGE-NODE");
                });
            }

            CreateNormalBox(node.transform, stage);
            RenderMonsterModel(node.transform, stage.Id);
        }

        private void RenderStagePlayer(WorldMapVisualDefinition map)
        {
            Transform scroll = Find(stageView, "Layer/ScrollPanel")?.transform;
            if (scroll == null || map == null || map.RoleCoordinates.Length == 0)
            {
                if (stagePlayerModel != null) stagePlayerModel.gameObject.SetActive(false);
                return;
            }
            int currentIndex = store.Stages.ToList().FindIndex(value => value.Id == store.CurrentStageId);
            if (currentIndex < 0) currentIndex = 0;
            currentIndex = Mathf.Clamp(currentIndex, 0, map.RoleCoordinates.Length - 1);

            GameObject value = stagePlayerModel != null ? stagePlayerModel.gameObject
                : new GameObject("RuntimeStagePlayer", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(scroll, false);
            rect.anchorMin = rect.anchorMax = Vector2.zero;
            rect.pivot = new Vector2(0.5f, 0f);
            rect.anchoredPosition = map.RoleCoordinates[currentIndex] + new Vector2(0f, 33f);
            rect.sizeDelta = Vector2.zero;
            rect.localScale = Vector3.one;
            stagePlayerModel = value.GetComponent<ImodAnimationPlayer>()
                ?? value.AddComponent<ImodAnimationPlayer>();
            string legacyPath = player.Model == 4 ? "hero/H_0_fd" : "hero/K_0_fd";
            bool loaded = stagePlayerModel.LoadLegacy(legacyPath);
            value.SetActive(loaded);
            if (!loaded) return;
            try { stagePlayerModel.Play(4, true); }
            catch (ArgumentOutOfRangeException) { stagePlayerModel.Play(0, true); }
            catch (InvalidOperationException) { stagePlayerModel.Play(0, true); }
        }

        private void PositionStageCamera(WorldMapVisualDefinition map)
        {
            RectTransform scroll = Find(stageView, "Layer/ScrollPanel")?.GetComponent<RectTransform>();
            if (scroll == null || map == null || map.RoleCoordinates.Length == 0) return;
            int currentIndex = store.Stages.ToList().FindIndex(value => value.Id == store.CurrentStageId);
            if (currentIndex < 0) currentIndex = 0;
            currentIndex = Mathf.Clamp(currentIndex, 0, map.RoleCoordinates.Length - 1);
            float fightX = map.RoleCoordinates[currentIndex].x;
            RectTransform root = stageView.GameObject.transform as RectTransform;
            float halfScreen = root != null && root.rect.width > 0f ? root.rect.width * .5f : 667f;
            float aimX = -fightX;
            if (fightX >= halfScreen) aimX += halfScreen;
            float maximumScroll = Mathf.Max(0f, map.Size.x * (750f / 1080f) - halfScreen * 2f);
            aimX = Mathf.Clamp(aimX, -maximumScroll, 0f);
            scroll.anchoredPosition = new Vector2(aimX, -FindStageCameraY(-aimX, map.CameraCoordinates));
        }

        private static float FindStageCameraY(float x, IReadOnlyList<Vector2> coordinates)
        {
            if (coordinates == null || coordinates.Count == 0) return 0f;
            if (x <= coordinates[0].x) return coordinates[0].y;
            for (int index = 0; index < coordinates.Count - 1; index++)
            {
                Vector2 current = coordinates[index];
                Vector2 next = coordinates[index + 1];
                if (x < current.x || x > next.x) continue;
                float t = Mathf.InverseLerp(current.x, next.x, x);
                return Mathf.Lerp(current.y, next.y, t);
            }
            return coordinates[coordinates.Count - 1].y;
        }

        private static void RenderMonsterModel(Transform host, uint stageId)
        {
            Transform old = host.Find("RuntimeMonster");
            if (!WorldVisualCatalog.TryGetStage(stageId, out WorldStageVisualDefinition visual)
                || visual.MonsterPicture <= 0)
            {
                if (old != null) old.gameObject.SetActive(false);
                return;
            }
            GameObject value = old != null ? old.gameObject
                : new GameObject("RuntimeMonster", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(0f, -85f);
            rect.sizeDelta = Vector2.zero;
            rect.localScale = Vector3.one * visual.MonsterScale;
            ImodAnimationPlayer player = value.GetComponent<ImodAnimationPlayer>()
                ?? value.AddComponent<ImodAnimationPlayer>();
            bool loaded = player.LoadLegacy($"Monster/btm{visual.MonsterPicture}_zd");
            value.SetActive(loaded);
            if (!loaded) return;
            try { player.Play(3, true); }
            catch (ArgumentOutOfRangeException) { player.Play(0, true); }
            catch (InvalidOperationException) { player.Play(0, true); }
        }

        private void CreateNormalBox(Transform stageNode, WorldStageRecord stage)
        {
            Transform existing = stageNode.Find("NormalBox_" + stage.Id);
            if (stage.RewardBoxId == 0)
            {
                normalBoxButtons.Remove(stage.Id);
                if (existing != null) existing.gameObject.SetActive(false);
                return;
            }
            // FuBenDetailUI clones the hidden `Layer/Box` prototype, then applies
            // the authoritative Cocos offset (+120, -50) inside the stage node.
            GameObject template = Find(stageView, "Layer/Box");
            if (template == null) return;
            GameObject box = existing != null
                ? existing.gameObject
                : UnityEngine.Object.Instantiate(template, stageNode, false);
            box.name = "NormalBox_" + stage.Id;
            box.SetActive(true);
            RectTransform rect = box.transform as RectTransform;
            if (rect != null)
            {
                rect.anchorMin = rect.anchorMax = Vector2.zero;
                rect.pivot = Vector2.zero;
                rect.anchoredPosition = new Vector2(120f, -50f);
                rect.localScale = Vector3.one;
            }
            bool opened = stage.RewardBoxState >= 2;
            bool claimable = stage.RewardBoxState == 1;
            Transform closed = box.transform.Find("Button1");
            Transform openedButton = box.transform.Find("Button");
            if (closed != null)
            {
                closed.gameObject.SetActive(!opened);
                Button button = closed.GetComponent<Button>();
                if (button != null)
                {
                    button.onClick.RemoveAllListeners();
                    button.interactable = true;
                    button.onClick.AddListener(() => { showNormalBox(stage); Mark("WORLD-11-NORMAL-BOX"); });
                    normalBoxButtons[stage.Id] = button;
                }
                Transform prompt = closed.Find("Image_1");
                if (prompt != null) prompt.gameObject.SetActive(claimable);
            }
            if (openedButton != null)
            {
                openedButton.gameObject.SetActive(opened);
                Button button = openedButton.GetComponent<Button>();
                if (button != null)
                {
                    button.onClick.RemoveAllListeners();
                    button.interactable = true;
                    button.onClick.AddListener(() => { showNormalBox(stage); Mark("WORLD-11-NORMAL-BOX"); });
                }
            }
            if (opened && normalBoxButtons.ContainsKey(stage.Id))
                normalBoxButtons.Remove(stage.Id);
            Transform effect = box.transform.Find("effect_tuitu_1");
            if (effect != null) effect.gameObject.SetActive(claimable);
        }

        private static void CreateStageLabel(Transform parent, string name, string value, Vector2 min, Vector2 max, int size)
        {
            GameObject labelObject = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            labelObject.transform.SetParent(parent, false);
            RectTransform rect = labelObject.GetComponent<RectTransform>();
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = size;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.horizontalOverflow = HorizontalWrapMode.Wrap;
            label.verticalOverflow = VerticalWrapMode.Overflow;
            label.text = value;
        }

        private static void Bind(CocosUiView view, string path, Action action)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void Mark(string controlId) => validationControl?.Invoke(controlId);

        private static void SetButtonLabel(CocosUiView view, string path, string value)
        {
            Text label = Find(view, path + "/Text")?.GetComponent<Text>()
                ?? Find(view, path)?.GetComponentInChildren<Text>(true);
            if (label != null) label.text = value;
        }

        private static void SetText(CocosUiView view, string path, string value)
        {
            Text label = Find(view, path)?.GetComponent<Text>();
            if (label != null) label.text = value ?? string.Empty;
        }

        private static void SetActive(CocosUiView view, string path, bool active)
        {
            GameObject target = Find(view, path);
            if (target != null) target.SetActive(active);
        }

        private static Sprite LoadRuntimeSprite(string resourcePath)
        {
            if (string.IsNullOrEmpty(resourcePath)) return null;
            if (RuntimeSprites.TryGetValue(resourcePath, out Sprite cached)) return cached;
            Sprite sprite = Resources.Load<Sprite>(resourcePath);
            if (sprite == null)
            {
                Texture2D texture = Resources.Load<Texture2D>(resourcePath);
                if (texture != null)
                    sprite = Sprite.Create(texture, new Rect(0f, 0f, texture.width, texture.height),
                        new Vector2(0.5f, 0.5f), 100f);
            }
            RuntimeSprites[resourcePath] = sprite;
            return sprite;
        }

        private static GameObject Require(CocosUiView view, string path) => Find(view, path)
            ?? throw new InvalidOperationException($"World UI node was not found: {path}");

        private static GameObject Find(CocosUiView view, string path) => view.Binding.Find(path);

        private static void SetNamedText(Transform root, string name, string value)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
                if (text.gameObject.name == name) text.text = value ?? string.Empty;
        }

        private sealed class ListEntry
        {
            public uint Id;
            public string Title;
            public string Subtitle;
            public bool Enabled;
            public bool IsChapter;

            public static ListEntry ForChapter(WorldChapterRecord value) => new ListEntry
            {
                Id = value.Id,
                Title = value.Name,
                Subtitle = $"{value.OwnedStars}/{value.MaximumStars} 星  Lv.{value.OpenLevel}",
                Enabled = true,
                IsChapter = true
            };

            public static ListEntry ForStage(WorldStageRecord value) => new ListEntry
            {
                Id = value.Id,
                Title = value.Name,
                Subtitle = value.IsUnlocked ? $"{value.Stars}/3 星  剩余 {value.RemainingAttempts} 次" : "未解锁",
                Enabled = value.IsUnlocked,
                IsChapter = false
            };
        }
    }
}
