using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FengShenStoryPresenter : IDisposable
    {
        public const int PageChapterCount = FengShenStoryStore.PageChapterCount;

        private readonly CocosUiView view;
        private CocosUiView levelView;
        private readonly Func<CocosUiView> resolveLevelView;
        private readonly FengShenStoryStore store;
        private readonly CurrencyStore currencies;
        private readonly ResourceService resources;
        private readonly GameErrorPresenter errorPresenter;
        private readonly CocosUiView itemSourceView;
        private readonly CocosUiView rewardView;
        private readonly RewardPresenter sharedRewardPresenter;
        private readonly Action close;
        private readonly Action challenge;
        private readonly Action formation;
        private readonly Action<int> routeBoundary;
        private readonly Text remaining;
        private readonly Text chapter;
        private readonly Text chapterTitle;
        private readonly RectTransform chapterViewport;
        private readonly RectTransform chapterContent;
        private readonly GameObject chapterTemplate;
        private readonly List<GameObject> chapterCells = new List<GameObject>();
        private readonly Button leftButton;
        private readonly Button rightButton;
        private Button levelCloseButton;
        private Button fightButton;
        private Button formationButton;
        private readonly Button closedBoxButton;
        private readonly Button openedBoxButton;
        private readonly List<Button> rewardIconButtons = new List<Button>();
        private readonly Dictionary<int, Button> sourceRouteButtons = new Dictionary<int, Button>();
        private readonly Dictionary<int, Button> stageHitButtons = new Dictionary<int, Button>();
        private GameObject modal;
        private Button modalCloseButton;
        private Button sourceIconButton;
        private Action modalAcknowledge;
        private ImodAnimationPlayer enemyModel;
        private Image enemyFallback;
        private GameObject rewardRuntimeRow;
        private GameObject commonHeader;
        private GameObject commonCurrency;
        private int renderedLevelRewardCount;
        private int renderedCurrentStageMarkerCount;
        private int popupStageId;

        public FengShenStoryPresenter(CocosUiView view, CocosUiView levelView, Func<CocosUiView> resolveLevelView,
            FengShenStoryStore store,
            CurrencyStore currencies, ResourceService resources, GameErrorPresenter errorPresenter,
            CocosUiView itemSourceView, CocosUiView rewardView, RewardPresenter sharedRewardPresenter,
            GameObject commonHeaderTemplate, GameObject commonCurrencyTemplate,
            Action close, Action challenge, Action formation, Action<int> routeBoundary,
            Action staminaAdd, Action goldAdd)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.levelView = levelView ?? throw new ArgumentNullException(nameof(levelView));
            this.resolveLevelView = resolveLevelView ?? throw new ArgumentNullException(nameof(resolveLevelView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.errorPresenter = errorPresenter ?? throw new ArgumentNullException(nameof(errorPresenter));
            this.itemSourceView = itemSourceView ?? throw new ArgumentNullException(nameof(itemSourceView));
            this.rewardView = rewardView ?? throw new ArgumentNullException(nameof(rewardView));
            this.sharedRewardPresenter = sharedRewardPresenter
                ?? throw new ArgumentNullException(nameof(sharedRewardPresenter));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.challenge = challenge ?? throw new ArgumentNullException(nameof(challenge));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.routeBoundary = routeBoundary ?? throw new ArgumentNullException(nameof(routeBoundary));

            Normalize(view.GameObject.transform);
            Transform root = view.GameObject.transform;
            InstallCommonHeader(commonHeaderTemplate, commonCurrencyTemplate, staminaAdd, goldAdd);
            SetVisible(root.Find("Panel_1"), true);
            SetVisible(root.Find("Panel_2"), true);
            remaining = RequireText(root, "Panel_1/today/num");
            chapter = RequireText(root, "Panel_1/Image_78/list");
            chapterTitle = RequireText(root, "Panel_1/Image_78/text2");

            chapterViewport = RequireRect(root, "Panel_2/TableView");
            chapterViewport.gameObject.SetActive(true);
            if (chapterViewport.GetComponent<RectMask2D>() == null) chapterViewport.gameObject.AddComponent<RectMask2D>();
            chapterTemplate = Require(root, "Panel_2/TableView/reel").gameObject;
            chapterTemplate.SetActive(false);
            chapterContent = CreateChapterContent(chapterViewport);

            leftButton = Bind(root, "Panel_2/Button_l", () => PageLeft());
            rightButton = Bind(root, "Panel_2/Button_r", () => PageRight());
            NormalizeMirroredRaycastButton(leftButton);
            closedBoxButton = Bind(root, "Panel_1/Box1/Button1", () => ShowRewardPreview(false));
            openedBoxButton = Bind(root, "Panel_1/Box1/Button", () => ShowRewardPreview(true));
            BindStageButtons(root);
            InstallStageHitTargets(root);

            BindLevelView(this.levelView);
            this.levelView.SetVisible(false);
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);

            store.Changed += Render;
            currencies.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null;
        public int FirstVisibleChapter => store.FirstVisibleChapter;
        public int SelectedChapter => store.SelectedChapter;
        public int RenderedChapterCount => chapterCells.Count;
        public int RenderedLevelRewardCount => renderedLevelRewardCount;
        public int RenderedCurrentStageMarkerCount => renderedCurrentStageMarkerCount;
        public bool IsCurrencyHeaderVisible => commonCurrency != null && commonCurrency.activeInHierarchy;
        public bool IsLevelPopupVisible => levelView?.GameObject?.activeSelf == true;
        public bool IsModalVisible => errorPresenter.IsVisible || itemSourceView.GameObject.activeSelf
            || rewardView.GameObject.activeSelf || (modal != null && modal.activeSelf);
        public int PopupStageId => popupStageId;

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= Render;
            if (modal != null) UnityEngine.Object.Destroy(modal);
            if (commonHeader != null) UnityEngine.Object.Destroy(commonHeader);
            if (commonCurrency != null) UnityEngine.Object.Destroy(commonCurrency);
        }

        public bool SelectChapter(int selectedChapter) => store.SelectChapter(selectedChapter);
        public bool PageLeft() => store.PageLeft();
        public bool PageRight() => store.PageRight();
        public Button LeftPageControl => leftButton;
        public Button RightPageControl => rightButton;
        public bool InvokeLeft() { leftButton.onClick.Invoke(); return true; }
        public bool InvokeRight() { rightButton.onClick.Invoke(); return true; }
        public bool InvokeClose() { close(); return true; }

        private void InstallCommonHeader(GameObject template, GameObject currencyTemplate,
            Action staminaAdd, Action goldAdd)
        {
            if (template == null)
                throw new InvalidOperationException("FengShenStory shared FirstClassBg title template was not found.");
            if (currencyTemplate == null)
                throw new InvalidOperationException("FengShenStory shared FirstClassBg GoldCheck template was not found.");
            commonHeader = UnityEngine.Object.Instantiate(template, view.GameObject.transform, false);
            commonHeader.name = "RuntimeFengShenStoryFirstClassHeader";
            commonHeader.SetActive(true);
            commonHeader.transform.SetAsLastSibling();
            Text title = commonHeader.transform.Find("TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "封神列传";
            Button closeButton = commonHeader.transform.Find("CloseBtn")?.GetComponent<Button>();
            if (closeButton == null)
                throw new InvalidOperationException("FengShenStory shared FirstClassBg close button was not found.");
            closeButton.interactable = true;
            closeButton.onClick.RemoveAllListeners();
            closeButton.onClick.AddListener(() => close());
            Button helpButton = commonHeader.transform.Find("TitleName/Button_1")?.GetComponent<Button>();
            if (helpButton != null)
            {
                helpButton.gameObject.SetActive(true);
                helpButton.interactable = true;
                helpButton.onClick.RemoveAllListeners();
                helpButton.onClick.AddListener(ShowHelp);
            }

            commonCurrency = UnityEngine.Object.Instantiate(currencyTemplate, view.GameObject.transform, false);
            commonCurrency.name = "RuntimeFengShenStoryGoldCheck";
            commonCurrency.SetActive(true);
            commonCurrency.transform.SetAsLastSibling();
            Bind(commonCurrency.transform, "GoldIcon1/AddBtn", staminaAdd ?? (() => { }));
            Bind(commonCurrency.transform, "GoldIcon3/AddBtn", goldAdd ?? (() => { }));
            Button premiumAdd = commonCurrency.transform.Find("GoldIcon4/AddBtn")?.GetComponent<Button>();
            if (premiumAdd != null)
            {
                premiumAdd.onClick.RemoveAllListeners();
                premiumAdd.interactable = false;
            }
        }
        public bool InvokeChapter(int chapterId)
        {
            return InvokeVisible(GetChapterControl(chapterId));
        }

        public Button GetChapterControl(int chapterId)
        {
            GameObject cell = chapterCells.FirstOrDefault(value => value != null && value.name == $"chapter_{chapterId}");
            return cell?.GetComponent<Button>();
        }

        public Button GetStageControl(int level) => stageHitButtons.TryGetValue(level, out Button button)
            ? button
            : null;
        public Button FightControl => fightButton;
        public Button ModalCloseButton => modalCloseButton;

        public bool InvokeStage(int level)
        {
            if (level < 1 || level > 4) return false;
            return stageHitButtons.TryGetValue(level, out Button button) && InvokeVisible(button);
        }

        public bool ShowLevelPopup(int stageId)
        {
            int selected = store.SelectedChapter;
            int level = stageId % 10;
            if (stageId / 10 != selected || level < 1 || level > 4) return false;
            FengShenStageState state = store.GetStageState(selected, level);
            if (state == FengShenStageState.Locked) return false;
            if (!EnsureLevelView())
            {
                errorPresenter.Show("提示", "关卡详情界面已失效，请重新进入封神列传。");
                return false;
            }
            popupStageId = stageId;
            Transform root = levelView.GameObject.transform;
            uint rawStageId = RawStageId(selected, level);
            WorldVisualCatalog.TryGetStage(rawStageId, out WorldStageVisualDefinition definition);
            RequireText(root, "Popup/Title/Title").text = definition?.Name ?? $"第{selected}章 第{level}关";
            RequireText(root, "Popup/Image_1/description").text = definition?.Description ??
                (state == FengShenStageState.Current ? "击败敌军，继续封神列传。" : "本关已通关");
            RequireText(root, "Popup/Btn_Confirm/tili/num").text = (definition?.Hope ?? 5).ToString();
            RenderLevelRewards(definition?.FirstRewards);
            RenderEnemy(definition);
            SetVisible(root.Find("Popup/Pass_bg"), state == FengShenStageState.Passed);
            SetVisible(root.Find("Popup/Pass"), state == FengShenStageState.Passed);
            fightButton.gameObject.SetActive(state == FengShenStageState.Current);
            formationButton.gameObject.SetActive(state == FengShenStageState.Current);
            levelView.SetVisible(true);
            levelView.GameObject.transform.SetAsLastSibling();
            return true;
        }

        public bool CloseLevelPopup()
        {
            levelView?.SetVisible(false);
            popupStageId = 0;
            return true;
        }

        public bool InvokeLevelClose() => InvokeVisible(levelCloseButton);
        public bool InvokeFight() => InvokeVisible(fightButton);
        public bool InvokeFormation() => InvokeVisible(formationButton);
        public bool InvokeClosedBox() => InvokeVisible(closedBoxButton);
        public bool InvokeOpenedBox() => InvokeVisible(openedBoxButton);
        public bool InvokeRewardIcon(int index) => index >= 0 && index < rewardIconButtons.Count
            && InvokeVisible(rewardIconButtons[index]);

        public void ShowHelp()
        {
            CloseImportedModals();
            errorPresenter.ShowHelp("每章节有4个列传关卡，玩家可通过关卡了解神将的传奇故事。\n每日挑战次数有限，挑战消耗5点体力。");
        }
        public void ShowItemSource()
        {
            CloseImportedModals();
            SetViewText(itemSourceView, "Layer/Popup/Title/Title", "获取途径");
            SetViewText(itemSourceView, "Layer/Popup/Panel_name/txt_name", "首通奖励");
            SetViewText(itemSourceView, "Layer/Popup/Panel_name/txt_tips", "挑战列传关卡可获得");
            SetViewText(itemSourceView, "Layer/Popup/Panel_name/txt_num", string.Empty);
            Image sourceIcon = itemSourceView.Binding.Find("Layer/Popup/Panel_name/Panel_icon/Icon")?.GetComponent<Image>();
            if (sourceIcon != null)
            {
                sourceIcon.sprite = resources.LoadItemIcon(3005);
                sourceIcon.preserveAspect = true;
                sourceIcon.color = Color.white;
            }
            SetViewText(itemSourceView, "Layer/Popup/itemlayer_1/Name_1", "商城");
            SetViewText(itemSourceView, "Layer/Popup/itemlayer_1/Name_2", "将魂商店");
            sourceIconButton = BindView(itemSourceView, "Layer/Popup/Panel_name/Panel_icon/Icon", () => { });
            sourceRouteButtons[13] = BindView(itemSourceView, "Layer/Popup/itemlayer_1/Button_1", () => routeBoundary(13));
            sourceRouteButtons[15] = BindView(itemSourceView, "Layer/Popup/itemlayer_1/Button_2", () => routeBoundary(15));
            SetViewVisible(itemSourceView, "Layer/Popup/itemlayer_1/Button_3", false);
            modalCloseButton = BindView(itemSourceView, "Layer/Popup/Title/Btn_close", () => CloseModal());
            itemSourceView.SetVisible(true);
            itemSourceView.GameObject.transform.SetAsLastSibling();
        }
        public void ShowRewardPreview(bool opened) => ShowImportedReward(
            opened ? "宝箱已开启" : "宝箱奖励", opened ? "奖励已领取" : "通关本章后可领取", null);

        public void ShowRewardPush()
        {
            ShowImportedReward("宝箱奖励", string.Empty, store.AcknowledgeRewardPush);
        }

        public bool CloseModal()
        {
            bool wasVisible = IsModalVisible;
            if (errorPresenter.IsVisible) errorPresenter.Hide();
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);
            sharedRewardPresenter.ResumeSharedViewRendering();
            if (modal != null) modal.SetActive(false);
            Action acknowledge = modalAcknowledge;
            modalAcknowledge = null;
            acknowledge?.Invoke();
            sourceRouteButtons.Clear();
            sourceIconButton = null;
            modalCloseButton = null;
            return wasVisible;
        }

        public bool InvokeModalClose()
        {
            if (errorPresenter.IsVisible) return errorPresenter.InvokeSingleConfirmation();
            return InvokeVisible(modalCloseButton);
        }

        public bool ValidateRewardPushPresentation(out string detail)
        {
            uint[] expectedIds = { 60014, 851 };
            string[] expectedNames = { "神魂", "突破丹" };
            int[] expectedPictures = { 3005, 710 };
            int[] expectedQualities = { 4, 3 };
            uint[] expectedAmounts = { 200, 100 };
            Text title = rewardView.Binding.Find("Layer/Popup/Title/Title_1")?.GetComponent<Text>();
            Text tips = rewardView.Binding.Find("Layer/Popup/tips")?.GetComponent<Text>();
            Text confirm = rewardView.Binding.Find("Layer/Popup/btn_lingqu/Text1")?.GetComponent<Text>();
            Image confirmGraphic = modalCloseButton?.targetGraphic as Image;
            if (!rewardView.GameObject.activeSelf || title?.text != "宝箱奖励"
                || !string.IsNullOrEmpty(tips?.text) || store.RewardPush.Count != 2
                || rewardRuntimeRow == null || modalCloseButton == null
                || !modalCloseButton.gameObject.activeInHierarchy || !modalCloseButton.interactable
                || confirm?.text != "确定" || confirmGraphic == null || !confirmGraphic.enabled
                || confirmGraphic.sprite == null)
            {
                detail = $"visible={rewardView.GameObject.activeSelf}, title='{title?.text}', tips='{tips?.text}', "
                    + $"rewards={store.RewardPush.Count}, row={rewardRuntimeRow != null}, "
                    + $"confirm={modalCloseButton?.gameObject.activeInHierarchy}/{modalCloseButton?.interactable}, "
                    + $"label='{confirm?.text}', graphic={confirmGraphic?.sprite != null}";
                return false;
            }
            for (int index = 0; index < store.RewardPush.Count; index++)
            {
                FengShenRewardRecord reward = store.RewardPush[index];
                uint displayId = reward.Id > 0 ? reward.Id : reward.Type;
                Transform cell = rewardRuntimeRow.transform.Find($"itemlayer_{index + 1}");
                Text name = cell?.Find("Name")?.GetComponent<Text>();
                Transform runtimeCell = cell?.Find("item/RuntimeFengShenItemCell");
                Image icon = runtimeCell?.Find("Icon")?.GetComponent<Image>();
                Text amount = runtimeCell?.Find("Amount")?.GetComponent<Text>();
                if (displayId != expectedIds[index] || reward.Name != expectedNames[index]
                    || reward.Picture != expectedPictures[index] || reward.Quality != expectedQualities[index]
                    || reward.Amount != expectedAmounts[index]
                    || cell?.gameObject.activeSelf != true
                    || name?.text != reward.Name || icon?.sprite == null || amount?.text != reward.Amount.ToString())
                {
                    detail = $"item={index}, active={cell?.gameObject.activeSelf}, "
                        + $"displayId={displayId}/{expectedIds[index]} (type={reward.Type},id={reward.Id}), "
                        + $"name='{name?.text}'/'{reward.Name}'/'{expectedNames[index]}', "
                        + $"picture={reward.Picture}/{expectedPictures[index]}, quality={reward.Quality}/{expectedQualities[index]}, "
                        + $"icon={icon?.sprite != null}, amount='{amount?.text}'/'{reward.Amount}'";
                    return false;
                }
            }
            Text invalidText = rewardView.GameObject.GetComponentsInChildren<Text>(true)
                .FirstOrDefault(value => value.gameObject.activeInHierarchy
                    && (value.text == "获得奖励" || value.text.StartsWith("奖励 #", StringComparison.Ordinal)));
            if (invalidText != null)
            {
                detail = $"unexpected active text '{invalidText.text}' at {HierarchyPath(invalidText.transform)}";
                return false;
            }
            detail = string.Join(",", store.RewardPush.Select(value =>
                $"{value.Name}:{value.Picture}:q{value.Quality}x{value.Amount}"));
            return true;
        }

        public bool InvokeLevelMask()
        {
            if (!IsLevelPopupVisible || EventSystem.current == null) return false;
            Transform mask = levelView.GameObject.transform.Find("Mask");
            if (mask == null) return false;
            ExecuteEvents.Execute(mask.gameObject, new PointerEventData(EventSystem.current), ExecuteEvents.pointerClickHandler);
            return IsLevelPopupVisible;
        }

        public bool InvokeSourceIcon() => InvokeVisible(sourceIconButton) && IsModalVisible;

        public bool InvokeSourceRoute(int functionId)
        {
            return sourceRouteButtons.TryGetValue(functionId, out Button button) && InvokeVisible(button);
        }

        private void Render()
        {
            RenderCurrencyHeader();
            if (!store.HasAuthoritativeResponse)
            {
                remaining.text = "--/5";
                chapter.text = "--";
                chapterTitle.text = "等待数据";
                ClearChapterCells();
                return;
            }

            remaining.text = $"{store.RemainingChallenges}/{FengShenStoryStore.MaxChallengeCount}";
            chapter.text = store.SelectedChapter.ToString();
            chapterTitle.text = WorldVisualCatalog.TryGetChapter((uint)(4000 + store.SelectedChapter), out WorldChapterVisualDefinition selected)
                ? selected.Name : $"第{store.SelectedChapter}章";
            RenderChapterPage();
            RenderStages();
            RenderBoxes();
            leftButton.interactable = store.FirstVisibleChapter > 1;
            rightButton.interactable = store.FirstVisibleChapter + PageChapterCount <= store.HighestSelectableChapter;
        }

        private void RenderChapterPage()
        {
            ClearChapterCells();
            for (int offset = 0; offset < PageChapterCount; offset++)
            {
                int chapterId = store.FirstVisibleChapter + offset;
                if (chapterId > store.HighestSelectableChapter) break;
                GameObject cell = UnityEngine.Object.Instantiate(chapterTemplate, chapterContent, false);
                cell.name = $"chapter_{chapterId}";
                cell.SetActive(true);
                Text id = FindText(cell.transform, "Image_2/Text_2");
                Text title = FindText(cell.transform, "Image_2/Text_1");
                if (id != null) id.text = $"第{chapterId}章";
                if (title != null) title.text = WorldVisualCatalog.TryGetChapter((uint)(4000 + chapterId), out WorldChapterVisualDefinition definition)
                    ? definition.Name : (chapterId % 3 == 0 ? "Boss章节" : "封神列传");
                SetVisible(cell.transform.Find("Image_3"), chapterId < store.CurrentChapter);
                SetVisible(cell.transform.Find("Image_2"), chapterId == store.SelectedChapter);
                int captured = chapterId;
                Image hitGraphic = cell.GetComponent<Image>() ?? cell.AddComponent<Image>();
                hitGraphic.sprite = null;
                hitGraphic.color = new Color(1f, 1f, 1f, .01f);
                hitGraphic.raycastTarget = true;
                Button button = cell.GetComponent<Button>() ?? cell.AddComponent<Button>();
                button.enabled = true;
                button.interactable = true;
                button.targetGraphic = hitGraphic;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => SelectChapter(captured));
                chapterCells.Add(cell);
            }
            chapterContent.sizeDelta = new Vector2(PageChapterCount * 165f, 126f);
            chapterContent.anchoredPosition = Vector2.zero;
        }

        private void RenderStages()
        {
            Transform panel = view.GameObject.transform.Find("Panel_1");
            if (panel == null) return;
            renderedCurrentStageMarkerCount = 0;
            for (int level = 1; level <= 4; level++)
            {
                FengShenStageState state = store.GetStageState(store.SelectedChapter, level);
                int activeVariant = state == FengShenStageState.Passed ? 1 : state == FengShenStageState.Current ? 2 : 3;
                for (int variant = 1; variant <= 3; variant++)
                {
                    Transform node = panel.Find($"chapter_{level}{variant}");
                    if (node == null) continue;
                    node.gameObject.SetActive(variant == activeVariant);
                    if (variant != activeVariant) continue;
                    WorldVisualCatalog.TryGetStage(RawStageId(store.SelectedChapter, level), out WorldStageVisualDefinition definition);
                    Text name = FindText(node, "Image_3/Text_1");
                    if (name != null) name.text = definition?.Name ?? $"第{level}关";
                    bool isCurrent = state == FengShenStageState.Current;
                    SetVisible(node.Find("Image_4"), isCurrent);
                    if (isCurrent) renderedCurrentStageMarkerCount++;
                    Image icon = node.Find("Icon")?.GetComponent<Image>();
                    if (icon != null)
                    {
                        icon.sprite = resources.LoadHeroPortrait(definition?.MonsterPicture ?? 0);
                        icon.preserveAspect = true;
                        icon.color = state == FengShenStageState.Locked ? Color.gray : Color.white;
                    }
                    PositionStageHitTarget(level, node);
                }
            }
        }

        private void RenderEnemy(WorldStageVisualDefinition definition)
        {
            int picture = definition?.MonsterPicture ?? 0;
            bool loaded = picture > 0 && enemyModel.LoadLegacy($"Monster/btm{picture}_zd_show");
            enemyModel.gameObject.SetActive(loaded);
            enemyFallback.gameObject.SetActive(!loaded);
            if (loaded)
            {
                enemyModel.transform.localScale = Vector3.one * .8f;
                enemyModel.Play(0, true);
                enemyFallback.sprite = null;
            }
            else
            {
                enemyFallback.sprite = resources.LoadHeroPortrait(picture);
                enemyFallback.preserveAspect = true;
            }
            Text name = FindText(levelView.GameObject.transform, "Popup/Enemy/Namebg/Name");
            if (name != null) name.text = definition?.Name ?? string.Empty;
        }

        private static uint RawStageId(int chapterId, int level) => checked((uint)((4000 + chapterId) * 10 + level));

        private static ImodAnimationPlayer CreateEnemyModel(Transform parent)
        {
            Transform existing = parent.Find("RuntimeFengShenEnemy");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeFengShenEnemy", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = Vector2.zero;
            return value.GetComponent<ImodAnimationPlayer>() ?? value.AddComponent<ImodAnimationPlayer>();
        }

        private static Image CreateEnemyFallback(Transform parent)
        {
            Transform existing = parent.Find("RuntimeFengShenEnemyFallback");
            GameObject value = existing != null ? existing.gameObject
                : new GameObject("RuntimeFengShenEnemyFallback", typeof(RectTransform), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(180f, 220f);
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private void RenderBoxes()
        {
            Transform box = view.GameObject.transform.Find("Panel_1/Box1");
            if (box == null) return;
            bool opened = store.IsChapterBoxOpened(store.SelectedChapter);
            SetVisible(box.Find("Button1"), !opened);
            SetVisible(box.Find("Button"), opened);
            SetVisible(box.Find("Button1/Prompt"), false);
        }

        private void BindStageButtons(Transform root)
        {
            for (int level = 1; level <= 4; level++)
            for (int variant = 1; variant <= 3; variant++)
            {
                Transform node = root.Find($"Panel_1/chapter_{level}{variant}");
                if (node == null) continue;
                int capturedLevel = level;
                Button button = node.GetComponent<Button>() ?? node.gameObject.AddComponent<Button>();
                button.targetGraphic = node.GetComponent<Graphic>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => HandleStageClick(capturedLevel));
            }
        }

        private void InstallStageHitTargets(Transform root)
        {
            for (int level = 1; level <= 4; level++)
            {
                Transform existing = root.Find($"RuntimeFengShenStageHit_{level}");
                if (existing != null) UnityEngine.Object.DestroyImmediate(existing.gameObject);
                GameObject hit = new GameObject($"RuntimeFengShenStageHit_{level}", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image), typeof(Button));
                RectTransform rect = hit.GetComponent<RectTransform>();
                rect.SetParent(root, false);
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
                Image image = hit.GetComponent<Image>();
                image.color = new Color(1f, 1f, 1f, .01f);
                Button button = hit.GetComponent<Button>();
                button.targetGraphic = image;
                int capturedLevel = level;
                button.onClick.AddListener(() => HandleStageClick(capturedLevel));
                stageHitButtons[level] = button;
                hit.transform.SetAsLastSibling();
            }
        }

        private void PositionStageHitTarget(int level, Transform node)
        {
            if (!stageHitButtons.TryGetValue(level, out Button button)) return;
            RectTransform rect = button.transform as RectTransform;
            if (rect == null) return;
            Bounds bounds = RectTransformUtility.CalculateRelativeRectTransformBounds(view.GameObject.transform, node);
            rect.anchoredPosition = bounds.center;
            rect.sizeDelta = new Vector2(Mathf.Max(140f, bounds.size.x), Mathf.Max(140f, bounds.size.y));
            button.gameObject.SetActive(node.gameObject.activeInHierarchy);
            button.transform.SetAsLastSibling();
        }

        private bool HandleStageClick(int level)
        {
            FengShenStageState state = store.GetStageState(store.SelectedChapter, level);
            if (state == FengShenStageState.Locked)
            {
                errorPresenter.Show("提示", "该关卡尚未解锁，请先通关前一关。");
                return true;
            }
            return ShowLevelPopup(store.SelectedChapter * 10 + level);
        }

        private void OnFightClicked()
        {
            store.BeginChallenge();
            challenge();
            // Cocos FengShenStoryLevelUI closes immediately after sending op=25.
            // Keeping the old stage popup open lets the op=10 push turn it into
            // a passed-stage panel with no actions, which looks like lost buttons.
            CloseLevelPopup();
        }

        private void OnFormationClicked()
        {
            formation();
            // Cocos also closes the level popup when entering formation.
            CloseLevelPopup();
        }

        private void BindRewardIcons(Transform root)
        {
            rewardIconButtons.Clear();
            for (int index = 1; index <= 3; index++)
            {
                Transform icon = root.Find($"Popup/ListView/Icon_{index}");
                if (icon == null) continue;
                Button button = icon.GetComponent<Button>() ?? icon.gameObject.AddComponent<Button>();
                button.targetGraphic = icon.GetComponent<Graphic>();
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(ShowItemSource);
                rewardIconButtons.Add(button);
            }
        }

        private bool EnsureLevelView()
        {
            if (levelView?.GameObject != null && levelCloseButton != null
                && fightButton != null && formationButton != null
                && enemyModel != null && enemyFallback != null)
                return true;

            CocosUiView current = resolveLevelView();
            if (current?.GameObject == null) return false;
            BindLevelView(current);
            return true;
        }

        private void BindLevelView(CocosUiView current)
        {
            levelView = current ?? throw new ArgumentNullException(nameof(current));
            Transform levelRoot = levelView.GameObject?.transform
                ?? throw new InvalidOperationException("FengShenStory level view was destroyed before binding.");
            Normalize(levelRoot);
            levelCloseButton = Bind(levelRoot, "Popup/Btn_close", () => CloseLevelPopup());
            fightButton = Bind(levelRoot, "Popup/Btn_Confirm", OnFightClicked);
            formationButton = Bind(levelRoot, "Popup/Btn_buzhen", OnFormationClicked);
            Transform enemyNode = Require(levelRoot, "Popup/Enemy/Node").transform;
            enemyModel = CreateEnemyModel(enemyNode);
            enemyFallback = CreateEnemyFallback(enemyNode);
            BindRewardIcons(levelRoot);
        }

        private void RenderLevelRewards(IReadOnlyList<WorldConfiguredReward> rewards)
        {
            Transform root = levelView.GameObject.transform;
            renderedLevelRewardCount = 0;
            for (int index = 0; index < 3; index++)
            {
                Transform slot = root.Find($"Popup/ListView/Icon_{index + 1}");
                if (slot == null) continue;
                bool active = rewards != null && index < rewards.Count;
                slot.gameObject.SetActive(active);
                if (!active) continue;

                WorldConfiguredReward reward = rewards[index];
                if (RenderItemCell(slot, RewardPicture(reward.Type), reward.Amount, 3, false))
                    renderedLevelRewardCount++;
            }
        }

        private void RenderCurrencyHeader()
        {
            if (commonCurrency == null) return;
            Text stamina = FindText(commonCurrency.transform, "GoldIcon1/GoldNumBg/Num");
            Text gold = FindText(commonCurrency.transform, "GoldIcon3/GoldNumBg/Num");
            Text premium = FindText(commonCurrency.transform, "GoldIcon4/GoldNumBg/Num");
            if (stamina != null) stamina.text = $"{currencies.Stamina}/100";
            if (gold != null) gold.text = FormatHeaderCurrency(currencies.Gold);
            if (premium != null) premium.text = currencies.Premium.ToString();
        }

        private static int RewardPicture(int id)
        {
            switch (id)
            {
                case CurrencyIds.Gold: return 3006;
                case CurrencyIds.BoundPremium: return 3021;
                case CurrencyIds.Soul: return 3005;
                default: return id;
            }
        }

        private static string FormatHeaderCurrency(long value) =>
            value >= 10000 && value % 10000 == 0 ? $"{value / 10000}万" : value.ToString();

        private void ShowModal(string title, string body, Action acknowledge)
        {
            if (modal != null) UnityEngine.Object.Destroy(modal);
            modalCloseButton = null;
            sourceIconButton = null;
            sourceRouteButtons.Clear();
            modal = new GameObject("FengShenStoryRuntimeModal", typeof(RectTransform), typeof(Image));
            RectTransform modalRect = (RectTransform)modal.transform;
            modalRect.SetParent(view.GameObject.transform.parent, false);
            modalRect.anchorMin = Vector2.zero;
            modalRect.anchorMax = Vector2.one;
            modalRect.offsetMin = modalRect.offsetMax = Vector2.zero;
            modal.GetComponent<Image>().color = new Color(0f, 0f, 0f, .72f);

            GameObject panel = CreateUiObject("Panel", modalRect, new Vector2(620f, 390f), new Color(.16f, .11f, .06f, .98f));
            RectTransform panelRect = (RectTransform)panel.transform;
            panelRect.anchorMin = panelRect.anchorMax = panelRect.pivot = new Vector2(.5f, .5f);
            panelRect.anchoredPosition = Vector2.zero;
            CreateText("Title", panelRect, title, 30, new Vector2(0f, 130f), new Vector2(520f, 55f));
            CreateText("Body", panelRect, body, 24, new Vector2(0f, 10f), new Vector2(520f, 190f));
            GameObject closeObject = CreateUiObject("Close", panelRect, new Vector2(130f, 52f), new Color(.55f, .24f, .08f, 1f));
            RectTransform closeRect = (RectTransform)closeObject.transform;
            closeRect.anchorMin = closeRect.anchorMax = closeRect.pivot = new Vector2(.5f, .5f);
            closeRect.anchoredPosition = new Vector2(0f, -145f);
            CreateText("Label", closeRect, acknowledge == null ? "关闭" : "确定", 24, Vector2.zero, closeRect.sizeDelta);
            modalCloseButton = closeObject.AddComponent<Button>();
            modalCloseButton.targetGraphic = closeObject.GetComponent<Image>();
            modalCloseButton.onClick.AddListener(() => { acknowledge?.Invoke(); CloseModal(); });
            modal.transform.SetAsLastSibling();
        }

        private void ShowImportedReward(string title, string body, Action acknowledge)
        {
            CloseImportedModals();
            rewardView.SetVisible(true);
            rewardView.GameObject.transform.SetAsLastSibling();
            sharedRewardPresenter.SuspendSharedViewRendering();
            modalAcknowledge = acknowledge;
            GameObject rewardLayer = rewardView.Binding.Find("Layer")
                ?? throw new InvalidOperationException("FengShenStory reward modal is missing Layer.");
            Image rewardDimmer = rewardLayer.GetComponent<Image>();
            if (rewardDimmer == null) rewardDimmer = rewardLayer.AddComponent<Image>();
            rewardDimmer.color = new Color(0f, 0f, 0f,
                1f - Mathf.GammaToLinearSpace(1f - 150f / 255f));
            rewardDimmer.raycastTarget = true;
            SetViewText(rewardView, "Layer/Popup/Title/Title_1", title);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_1", true);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_2", false);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_3", false);
            SetViewText(rewardView, "Layer/Popup/tips", body);
            SetViewVisible(rewardView, "Layer/Popup/tips", !string.IsNullOrEmpty(body));
            SetViewVisible(rewardView, "Layer/Popup/tips_3", false);
            Transform rewardRow = BuildRewardRow();
            RenderRewardItem(rewardRow, 1, 3005, "神魂", 100, 4, acknowledge != null ? 0 : -1);
            RenderRewardItem(rewardRow, 2, 710, "突破丹", 80, 3, acknowledge != null ? 1 : -1);
            SetChildVisible(rewardRow, "itemlayer_3", false);
            SetChildVisible(rewardRow, "itemlayer_4", false);
            Button closeButton = BindView(rewardView, "Layer/Popup/Btn_close", () => CloseModal());
            Button confirmButton = BindView(rewardView, "Layer/Popup/btn_lingqu", () => CloseModal());
            confirmButton.gameObject.SetActive(acknowledge != null);
            confirmButton.enabled = true;
            confirmButton.interactable = true;
            Image confirmGraphic = confirmButton.targetGraphic as Image;
            if (confirmGraphic != null)
            {
                confirmGraphic.enabled = true;
                confirmGraphic.color = Color.white;
                confirmGraphic.raycastTarget = true;
            }
            SetViewText(rewardView, "Layer/Popup/btn_lingqu/Text1", "确定");
            modalCloseButton = acknowledge == null ? closeButton : confirmButton;
        }

        private Transform BuildRewardRow()
        {
            if (rewardRuntimeRow != null)
            {
                rewardRuntimeRow.SetActive(false);
                UnityEngine.Object.Destroy(rewardRuntimeRow);
            }
            GameObject template = rewardView.Binding.Find("Layer/Popup/ItemList")
                ?? throw new InvalidOperationException("FengShenStory reward row template is missing.");
            Transform list = rewardView.Binding.Find("Layer/Popup/ListView")?.transform
                ?? throw new InvalidOperationException("FengShenStory reward list is missing.");
            template.SetActive(false);
            rewardRuntimeRow = UnityEngine.Object.Instantiate(template, list, false);
            rewardRuntimeRow.name = "RuntimeFengShenRewardRow";
            rewardRuntimeRow.SetActive(true);
            for (int index = 0; index < list.childCount; index++)
            {
                Transform child = list.GetChild(index);
                if (child != rewardRuntimeRow.transform) child.gameObject.SetActive(false);
            }
            RectTransform rect = rewardRuntimeRow.transform as RectTransform;
            if (rect != null)
            {
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = Vector2.zero;
                rect.localScale = Vector3.one;
            }
            return rewardRuntimeRow.transform;
        }

        private void RenderRewardItem(Transform row, int index, int picture, string fallbackName,
            int fallbackAmount, int quality, int rewardIndex)
        {
            Transform cell = row.Find($"itemlayer_{index}");
            if (cell == null) return;
            cell.gameObject.SetActive(true);
            SetOnlyDirectChildrenVisible(cell, "Name", "item");
            string nameValue = fallbackName;
            long amountValue = fallbackAmount;
            if (rewardIndex >= 0 && rewardIndex < store.RewardPush.Count)
            {
                FengShenRewardRecord reward = store.RewardPush[rewardIndex];
                if (reward.Picture > 0) picture = reward.Picture;
                if (reward.Quality > 0) quality = reward.Quality;
                nameValue = reward.Name;
                amountValue = reward.Amount;
            }
            // The current Cocos ItemCell renders the soul currency with the
            // common blue reward-cell frame even though its catalog metadata
            // reports quality 4. Preserve the authoritative metadata for
            // validation, but use the source presentation rule here.
            int visualQuality = picture == 3005 ? 3 : quality;
            Transform itemHost = cell.Find("item");
            if (itemHost != null)
            {
                itemHost.gameObject.SetActive(true);
                SetOnlyDirectChildrenVisible(itemHost, "RuntimeFengShenItemCell");
                RenderItemCell(itemHost, picture, amountValue, visualQuality, false);
            }
            Text name = cell.Find("Name")?.GetComponent<Text>();
            if (name != null)
            {
                name.gameObject.SetActive(true);
                name.text = nameValue;
            }
        }

        private bool RenderItemCell(Transform host, int picture, long amount, int quality, bool multiplyPrefix)
        {
            Image hostImage = host.GetComponent<Image>();
            if (hostImage != null)
            {
                hostImage.sprite = null;
                hostImage.enabled = true;
                hostImage.color = new Color(1f, 1f, 1f, .001f);
                hostImage.raycastTarget = true;
            }

            Transform existing = host.Find("RuntimeFengShenItemCell");
            GameObject cellObject = existing != null ? existing.gameObject
                : new GameObject("RuntimeFengShenItemCell", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            cellObject.SetActive(true);
            RectTransform cellRect = cellObject.GetComponent<RectTransform>();
            cellRect.SetParent(host, false);
            cellRect.anchorMin = Vector2.zero;
            cellRect.anchorMax = Vector2.one;
            cellRect.pivot = new Vector2(.5f, .5f);
            cellRect.offsetMin = Vector2.zero;
            cellRect.offsetMax = Vector2.zero;
            cellRect.localScale = Vector3.one;

            Image frame = cellObject.GetComponent<Image>();
            frame.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
            frame.enabled = frame.sprite != null;
            frame.preserveAspect = true;
            frame.color = Color.white;
            frame.raycastTarget = false;

            Image icon = EnsureItemCellImage(cellRect, "Icon", new Vector2(.08f, .08f), new Vector2(.92f, .92f));
            icon.sprite = resources.LoadItemIcon(picture);
            icon.enabled = icon.sprite != null;
            icon.preserveAspect = true;
            icon.color = Color.white;

            Text amountText = EnsureItemCellAmount(cellRect);
            amountText.text = multiplyPrefix ? $"×{amount}" : amount.ToString();
            cellObject.transform.SetAsLastSibling();
            return frame.sprite != null && icon.sprite != null && !string.IsNullOrEmpty(amountText.text);
        }

        private static Image EnsureItemCellImage(Transform parent, string name, Vector2 anchorMin, Vector2 anchorMax)
        {
            Transform existing = parent.Find(name);
            GameObject imageObject = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = imageObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = imageObject.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private static Text EnsureItemCellAmount(Transform parent)
        {
            Transform existing = parent.Find("Amount");
            GameObject amountObject = existing != null ? existing.gameObject
                : new GameObject("Amount", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(Outline));
            RectTransform rect = amountObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(.18f, 0f);
            rect.anchorMax = new Vector2(.98f, .34f);
            rect.pivot = new Vector2(1f, 0f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text text = amountObject.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 18;
            text.alignment = TextAnchor.LowerRight;
            text.color = Color.white;
            text.raycastTarget = false;
            Outline outline = amountObject.GetComponent<Outline>();
            outline.effectColor = new Color(0f, 0f, 0f, .9f);
            outline.effectDistance = new Vector2(1f, -1f);
            amountObject.transform.SetAsLastSibling();
            return text;
        }

        private static void SetChildVisible(Transform root, string path, bool visible)
        {
            Transform child = root?.Find(path);
            if (child != null) child.gameObject.SetActive(visible);
        }

        private static void SetOnlyDirectChildrenVisible(Transform root, params string[] visibleNames)
        {
            if (root == null) return;
            for (int index = 0; index < root.childCount; index++)
            {
                Transform child = root.GetChild(index);
                child.gameObject.SetActive(Array.IndexOf(visibleNames, child.name) >= 0);
            }
        }

        private static string HierarchyPath(Transform node)
        {
            if (node == null) return "<null>";
            List<string> segments = new List<string>();
            for (Transform current = node; current != null; current = current.parent)
                segments.Add(current.name);
            segments.Reverse();
            return string.Join("/", segments);
        }

        private void CloseImportedModals()
        {
            errorPresenter.Hide();
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);
            sharedRewardPresenter.ResumeSharedViewRendering();
            modalAcknowledge = null;
            modalCloseButton = null;
            sourceIconButton = null;
            sourceRouteButtons.Clear();
        }

        private static Button BindView(CocosUiView targetView, string path, Action callback)
        {
            GameObject node = targetView.Binding.Find(path)
                ?? throw new InvalidOperationException("FengShenStory imported modal node not found: " + path);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private static void SetViewText(CocosUiView targetView, string path, string value)
        {
            Text text = targetView.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static void SetViewVisible(CocosUiView targetView, string path, bool visible)
        {
            GameObject node = targetView.Binding.Find(path);
            if (node != null) node.SetActive(visible);
        }

        private void BuildItemSourceControls()
        {
            RectTransform panel = modal?.transform.Find("Panel") as RectTransform;
            if (panel == null) return;
            sourceIconButton = CreateButton("CurrencyIcon", panel, "金币", new Vector2(-180f, 38f), new Vector2(120f, 70f), null);
            sourceRouteButtons[13] = CreateButton("Route13", panel, "商城", new Vector2(40f, 38f), new Vector2(150f, 70f), () => routeBoundary(13));
            sourceRouteButtons[15] = CreateButton("Route15", panel, "将魂商店", new Vector2(220f, 38f), new Vector2(170f, 70f), () => routeBoundary(15));
        }

        private static Button CreateButton(string name, Transform parent, string label, Vector2 position, Vector2 size, Action action)
        {
            GameObject gameObject = CreateUiObject(name, parent, size, new Color(.38f, .22f, .08f, 1f));
            RectTransform rect = (RectTransform)gameObject.transform;
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = position;
            CreateText("Label", rect, label, 22, Vector2.zero, size);
            Button button = gameObject.AddComponent<Button>();
            button.targetGraphic = gameObject.GetComponent<Image>();
            if (action != null) button.onClick.AddListener(() => action());
            return button;
        }

        private static bool InvokeVisible(Button button)
        {
            if (button == null || !button.gameObject.activeInHierarchy || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        private static RectTransform CreateChapterContent(RectTransform viewport)
        {
            Transform previous = viewport.Find("RuntimeFengShenChapterContent");
            if (previous != null) UnityEngine.Object.DestroyImmediate(previous.gameObject);
            GameObject content = new GameObject("RuntimeFengShenChapterContent", typeof(RectTransform), typeof(HorizontalLayoutGroup));
            RectTransform rect = (RectTransform)content.transform;
            rect.SetParent(viewport, false);
            rect.anchorMin = new Vector2(0f, 0f);
            rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, .5f);
            rect.anchoredPosition = Vector2.zero;
            HorizontalLayoutGroup layout = content.GetComponent<HorizontalLayoutGroup>();
            layout.spacing = 0f;
            layout.childAlignment = TextAnchor.MiddleLeft;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
            return rect;
        }

        private void ClearChapterCells()
        {
            foreach (GameObject cell in chapterCells) if (cell != null) UnityEngine.Object.Destroy(cell);
            chapterCells.Clear();
        }

        private static GameObject CreateUiObject(string name, Transform parent, Vector2 size, Color color)
        {
            GameObject gameObject = new GameObject(name, typeof(RectTransform), typeof(Image));
            RectTransform rect = (RectTransform)gameObject.transform;
            rect.SetParent(parent, false);
            rect.sizeDelta = size;
            gameObject.GetComponent<Image>().color = color;
            return gameObject;
        }

        private static Text CreateText(string name, Transform parent, string value, int fontSize, Vector2 position, Vector2 size)
        {
            GameObject gameObject = new GameObject(name, typeof(RectTransform), typeof(Text));
            RectTransform rect = (RectTransform)gameObject.transform;
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Text text = gameObject.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = fontSize;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = new Color(1f, .91f, .63f, 1f);
            text.text = value;
            return text;
        }

        private static Button Bind(Transform root, string path, Action callback)
        {
            Transform node = root.Find(path) ?? throw new InvalidOperationException($"FengShenStory node not found: {path}");
            Button button = node.GetComponent<Button>() ?? node.gameObject.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private static void NormalizeMirroredRaycastButton(Button button)
        {
            if (button == null) return;
            RectTransform rect = button.transform as RectTransform;
            if (rect == null || Vector3.Dot(rect.forward, Vector3.forward) >= 0f) return;
            Vector3 scale = rect.localScale;
            rect.localRotation = Quaternion.identity;
            rect.localScale = new Vector3(-Mathf.Abs(scale.x), scale.y, scale.z);
        }

        private static GameObject Require(Transform root, string path) => root.Find(path)?.gameObject
            ?? throw new InvalidOperationException($"FengShenStory imported node was not found: {path}");

        private static RectTransform RequireRect(Transform root, string path) => root.Find(path) as RectTransform
            ?? throw new InvalidOperationException($"FengShenStory imported RectTransform was not found: {path}");

        private static Text RequireText(Transform root, string path) => FindText(root, path)
            ?? throw new InvalidOperationException($"FengShenStory imported text was not found: {path}");

        private static Text FindText(Transform root, string path) => root.Find(path)?.GetComponent<Text>();

        private static void SetVisible(Transform target, bool visible)
        {
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }
}
