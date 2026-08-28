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
        private readonly CocosUiView levelView;
        private readonly FengShenStoryStore store;
        private readonly ResourceService resources;
        private readonly GameErrorPresenter errorPresenter;
        private readonly CocosUiView itemSourceView;
        private readonly CocosUiView rewardView;
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
        private readonly Button levelCloseButton;
        private readonly Button fightButton;
        private readonly Button formationButton;
        private readonly Button closedBoxButton;
        private readonly Button openedBoxButton;
        private readonly List<Button> rewardIconButtons = new List<Button>();
        private readonly Dictionary<int, Button> sourceRouteButtons = new Dictionary<int, Button>();
        private readonly Dictionary<int, Button> stageHitButtons = new Dictionary<int, Button>();
        private GameObject modal;
        private Button modalCloseButton;
        private Button sourceIconButton;
        private Action modalAcknowledge;
        private readonly ImodAnimationPlayer enemyModel;
        private readonly Image enemyFallback;
        private GameObject rewardRuntimeRow;
        private GameObject commonHeader;
        private int popupStageId;

        public FengShenStoryPresenter(CocosUiView view, CocosUiView levelView, FengShenStoryStore store,
            ResourceService resources, GameErrorPresenter errorPresenter,
            CocosUiView itemSourceView, CocosUiView rewardView,
            GameObject commonHeaderTemplate, Action close, Action challenge, Action formation, Action<int> routeBoundary)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.levelView = levelView ?? throw new ArgumentNullException(nameof(levelView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.errorPresenter = errorPresenter ?? throw new ArgumentNullException(nameof(errorPresenter));
            this.itemSourceView = itemSourceView ?? throw new ArgumentNullException(nameof(itemSourceView));
            this.rewardView = rewardView ?? throw new ArgumentNullException(nameof(rewardView));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.challenge = challenge ?? throw new ArgumentNullException(nameof(challenge));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.routeBoundary = routeBoundary ?? throw new ArgumentNullException(nameof(routeBoundary));

            Normalize(view.GameObject.transform);
            Normalize(levelView.GameObject.transform);
            Transform root = view.GameObject.transform;
            InstallCommonHeader(commonHeaderTemplate);
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
            closedBoxButton = Bind(root, "Panel_1/Box1/Button1", () => ShowRewardPreview(false));
            openedBoxButton = Bind(root, "Panel_1/Box1/Button", () => ShowRewardPreview(true));
            BindStageButtons(root);
            InstallStageHitTargets(root);

            Transform levelRoot = levelView.GameObject.transform;
            levelCloseButton = Bind(levelRoot, "Popup/Btn_close", () => CloseLevelPopup());
            fightButton = Bind(levelRoot, "Popup/Btn_Confirm", OnFightClicked);
            formationButton = Bind(levelRoot, "Popup/Btn_buzhen", formation);
            Transform enemyNode = Require(levelRoot, "Popup/Enemy/Node").transform;
            enemyModel = CreateEnemyModel(enemyNode);
            enemyFallback = CreateEnemyFallback(enemyNode);
            BindRewardIcons(levelRoot);
            levelView.SetVisible(false);
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);

            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null;
        public int FirstVisibleChapter => store.FirstVisibleChapter;
        public int SelectedChapter => store.SelectedChapter;
        public int RenderedChapterCount => chapterCells.Count;
        public bool IsLevelPopupVisible => levelView.GameObject.activeSelf;
        public bool IsModalVisible => errorPresenter.IsVisible || itemSourceView.GameObject.activeSelf
            || rewardView.GameObject.activeSelf || (modal != null && modal.activeSelf);
        public int PopupStageId => popupStageId;

        public void Dispose()
        {
            store.Changed -= Render;
            if (modal != null) UnityEngine.Object.Destroy(modal);
            if (commonHeader != null) UnityEngine.Object.Destroy(commonHeader);
        }

        public bool SelectChapter(int selectedChapter) => store.SelectChapter(selectedChapter);
        public bool PageLeft() => store.PageLeft();
        public bool PageRight() => store.PageRight();
        public bool InvokeLeft() { leftButton.onClick.Invoke(); return true; }
        public bool InvokeRight() { rightButton.onClick.Invoke(); return true; }
        public bool InvokeClose() { close(); return true; }

        private void InstallCommonHeader(GameObject template)
        {
            if (template == null)
                throw new InvalidOperationException("FengShenStory shared FirstClassBg title template was not found.");
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
        }
        public bool InvokeChapter(int chapterId)
        {
            GameObject cell = chapterCells.FirstOrDefault(value => value != null && value.name == $"chapter_{chapterId}");
            return cell != null && InvokeVisible(cell.GetComponent<Button>());
        }

        public Button GetStageControl(int level) => stageHitButtons.TryGetValue(level, out Button button)
            ? button
            : null;

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
            popupStageId = stageId;
            Transform root = levelView.GameObject.transform;
            uint rawStageId = RawStageId(selected, level);
            WorldVisualCatalog.TryGetStage(rawStageId, out WorldStageVisualDefinition definition);
            RequireText(root, "Popup/Title/Title").text = definition?.Name ?? $"第{selected}章 第{level}关";
            RequireText(root, "Popup/Image_1/description").text = definition?.Description ??
                (state == FengShenStageState.Current ? "击败敌军，继续封神列传。" : "本关已通关");
            RequireText(root, "Popup/Btn_Confirm/tili/num").text = (definition?.Hope ?? 5).ToString();
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
            levelView.SetVisible(false);
            popupStageId = 0;
            return true;
        }

        public bool InvokeLevelClose() { levelCloseButton.onClick.Invoke(); return true; }
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
            string body = store.RewardPush.Count == 0
                ? "奖励已由服务端发放"
                : string.Join("\n", store.RewardPush.Select(value => $"{value.Name} ×{value.Amount}"));
            ShowImportedReward("获得奖励", body, store.AcknowledgeRewardPush);
        }

        public bool CloseModal()
        {
            bool wasVisible = IsModalVisible;
            if (errorPresenter.IsVisible) errorPresenter.Hide();
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);
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
                Button button = cell.GetComponent<Button>() ?? cell.AddComponent<Button>();
                button.targetGraphic = cell.GetComponent<Graphic>();
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
            GameObject value = new GameObject("RuntimeFengShenEnemy", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = Vector2.zero;
            return value.AddComponent<ImodAnimationPlayer>();
        }

        private static Image CreateEnemyFallback(Transform parent)
        {
            GameObject value = new GameObject("RuntimeFengShenEnemyFallback", typeof(RectTransform), typeof(Image));
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
        }

        private void BindRewardIcons(Transform root)
        {
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
            modalAcknowledge = acknowledge;
            SetViewText(rewardView, "Layer/Popup/Title/Title_1", title);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_1", true);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_2", false);
            SetViewVisible(rewardView, "Layer/Popup/Title/Title_3", false);
            SetViewText(rewardView, "Layer/Popup/tips", body);
            SetViewVisible(rewardView, "Layer/Popup/tips", true);
            SetViewVisible(rewardView, "Layer/Popup/tips_3", false);
            Transform rewardRow = BuildRewardRow();
            RenderRewardItem(rewardRow, 1, 3005, acknowledge == null ? "神魂×100" : RewardLabel(0, "神魂"));
            RenderRewardItem(rewardRow, 2, 612, acknowledge == null ? "突破丹×80" : RewardLabel(1, "突破丹"));
            SetChildVisible(rewardRow, "itemlayer_3", false);
            SetChildVisible(rewardRow, "itemlayer_4", false);
            Button closeButton = BindView(rewardView, "Layer/Popup/Btn_close", () => CloseModal());
            Button confirmButton = BindView(rewardView, "Layer/Popup/btn_lingqu", () => CloseModal());
            confirmButton.gameObject.SetActive(acknowledge != null);
            modalCloseButton = acknowledge == null ? closeButton : confirmButton;
            rewardView.SetVisible(true);
            rewardView.GameObject.transform.SetAsLastSibling();
        }

        private string RewardLabel(int index, string fallback)
        {
            if (index < 0 || index >= store.RewardPush.Count) return fallback;
            FengShenRewardRecord reward = store.RewardPush[index];
            return $"{reward.Name}×{reward.Amount}";
        }

        private Transform BuildRewardRow()
        {
            if (rewardRuntimeRow != null) UnityEngine.Object.Destroy(rewardRuntimeRow);
            GameObject template = rewardView.Binding.Find("Layer/Popup/ItemList")
                ?? throw new InvalidOperationException("FengShenStory reward row template is missing.");
            Transform list = rewardView.Binding.Find("Layer/Popup/ListView")?.transform
                ?? throw new InvalidOperationException("FengShenStory reward list is missing.");
            rewardRuntimeRow = UnityEngine.Object.Instantiate(template, list, false);
            rewardRuntimeRow.name = "RuntimeFengShenRewardRow";
            rewardRuntimeRow.SetActive(true);
            RectTransform rect = rewardRuntimeRow.transform as RectTransform;
            if (rect != null)
            {
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = Vector2.zero;
                rect.localScale = Vector3.one;
            }
            return rewardRuntimeRow.transform;
        }

        private void RenderRewardItem(Transform row, int index, int picture, string label)
        {
            Transform cell = row.Find($"itemlayer_{index}");
            if (cell == null) return;
            cell.gameObject.SetActive(true);
            Image icon = cell.Find("item")?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = resources.LoadItemIcon(picture);
                icon.preserveAspect = true;
                icon.color = Color.white;
            }
            Text name = cell.Find("Name")?.GetComponent<Text>();
            if (name != null) name.text = label;
        }

        private static void SetChildVisible(Transform root, string path, bool visible)
        {
            Transform child = root?.Find(path);
            if (child != null) child.gameObject.SetActive(visible);
        }

        private void CloseImportedModals()
        {
            errorPresenter.Hide();
            itemSourceView.SetVisible(false);
            rewardView.SetVisible(false);
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
