using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    internal sealed class XunBaoResultSequence : MonoBehaviour
    {
        private Coroutine routine;

        public void Play(IReadOnlyList<IReadOnlyList<RewardRecord>> batches,
            Action<int, IReadOnlyList<RewardRecord>> append)
        {
            Cancel();
            routine = StartCoroutine(Run(batches, append));
        }

        public void Cancel()
        {
            if (routine == null) return;
            StopCoroutine(routine);
            routine = null;
        }

        private IEnumerator Run(IReadOnlyList<IReadOnlyList<RewardRecord>> batches,
            Action<int, IReadOnlyList<RewardRecord>> append)
        {
            for (int index = 0; index < batches.Count; index++)
            {
                append(index, batches[index]);
                if (index + 1 < batches.Count) yield return new WaitForSecondsRealtime(0.3f);
            }
            routine = null;
        }
    }

    public sealed class XunBaoResultPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly ResourceService resources;
        private readonly Transform list;
        private readonly RectTransform listContent;
        private readonly GameObject rewardTemplate;
        private readonly GameObject itemTemplate;
        private readonly GameObject legacyBottomButton;
        private readonly GameObject runtimeCloseControl;
        private readonly Button closeButton;
        private readonly XunBaoResultSequence sequence;
        private Action closeAction;
        private bool continueToToken;

        public XunBaoResultPresenter(CocosUiView view, ResourceService resources, GameObject closeTemplate)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            Normalize(view.GameObject.transform);
            list = Require("Layer/Souxun/Popup/ListView").transform;
            rewardTemplate = Require("Layer/Souxun/Reward");
            itemTemplate = Require("Layer/Souxun/Item");
            rewardTemplate.SetActive(false);
            itemTemplate.SetActive(false);
            legacyBottomButton = Require("Layer/Souxun/Button_1");
            legacyBottomButton.SetActive(false);
            runtimeCloseControl = InstallTopRightClose(closeTemplate);
            closeButton = runtimeCloseControl.GetComponent<Button>();
            sequence = view.GameObject.GetComponent<XunBaoResultSequence>()
                ?? view.GameObject.AddComponent<XunBaoResultSequence>();
            listContent = EnsureVerticalLayout(list.gameObject);
        }

        public bool IsVisible => view.GameObject.activeSelf;
        public int RenderedBatchCount { get; private set; }
        public int ExpectedBatchCount { get; private set; }
        public bool IsSequenceComplete => ExpectedBatchCount > 0 && RenderedBatchCount == ExpectedBatchCount;
        public Button CloseControl => closeButton;

        public void Show(IReadOnlyList<IReadOnlyList<RewardRecord>> batches,
            bool shouldContinueToToken, Action onClose)
        {
            if (batches == null || batches.Count == 0)
                throw new ArgumentException("At least one XunBao reward batch is required.", nameof(batches));
            ClearRows();
            ExpectedBatchCount = batches.Count;
            continueToToken = shouldContinueToToken;
            closeAction = onClose;
            legacyBottomButton.SetActive(false);
            runtimeCloseControl.SetActive(true);
            closeButton.interactable = true;
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
            sequence.Play(batches, AppendBatch);
        }

        public void Hide()
        {
            sequence.Cancel();
            view.SetVisible(false);
            Action callback = continueToToken ? closeAction : null;
            closeAction = null;
            continueToToken = false;
            callback?.Invoke();
        }

        public void Dispose()
        {
            sequence.Cancel();
            closeAction = null;
            ClearRows();
            if (runtimeCloseControl != null) UnityEngine.Object.Destroy(runtimeCloseControl);
        }

        private void AppendBatch(int index, IReadOnlyList<RewardRecord> rewards)
        {
            GameObject row = UnityEngine.Object.Instantiate(rewardTemplate, listContent, false);
            row.name = $"RuntimeSearchResult_{index + 1}";
            row.SetActive(true);
            SetText(row.transform, "TitleBg/Times", $"第{index + 1}次");
            SetText(row.transform, "TitleBg/Times/Text", rewards.Count == 0
                ? "本次未发现法宝碎片" : "寻宝成功，获得" + string.Join("、", rewards.Select(value => $"{value.Name}×{value.Amount}")));
            Transform itemList = row.transform.Find("ListView");
            if (itemList != null)
            {
                EnsureHorizontalLayout(itemList.gameObject);
                foreach (RewardRecord reward in rewards) AddReward(itemList, reward);
            }
            RenderedBatchCount++;
            Canvas.ForceUpdateCanvases();
            ScrollRect scroll = list.GetComponent<ScrollRect>();
            if (scroll != null) scroll.verticalNormalizedPosition = 0f;
        }

        private void AddReward(Transform parent, RewardRecord reward)
        {
            GameObject item = UnityEngine.Object.Instantiate(itemTemplate, parent, false);
            item.name = $"Reward_{reward.Type}_{reward.Id}";
            item.SetActive(true);
            Image frame = item.GetComponent<Image>();
            Sprite sprite = resources.LoadItemIcon(reward.Picture);
            if (frame != null)
            {
                Sprite qualityFrame = reward.Quality > 0
                    ? resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(reward.Quality, 1, 7):00}")
                    : null;
                if (qualityFrame != null) frame.sprite = qualityFrame;
                frame.enabled = frame.sprite != null;
                frame.preserveAspect = true;
            }
            GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            iconObject.transform.SetParent(item.transform, false);
            Image icon = iconObject.GetComponent<Image>();
            icon.sprite = sprite;
            icon.enabled = sprite != null;
            icon.preserveAspect = true;
            icon.raycastTarget = false;
            RectTransform iconRect = icon.rectTransform;
            iconRect.anchorMin = new Vector2(0.08f, 0.08f);
            iconRect.anchorMax = new Vector2(0.92f, 0.92f);
            iconRect.offsetMin = iconRect.offsetMax = Vector2.zero;
            Text amount = CreateText(item.transform, "Amount", $"×{reward.Amount}", TextAnchor.LowerRight);
            RectTransform rect = amount.rectTransform;
            rect.anchorMin = new Vector2(0.35f, 0f);
            rect.anchorMax = new Vector2(1f, 0.35f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private void ClearRows()
        {
            RenderedBatchCount = 0;
            ExpectedBatchCount = 0;
            for (int index = listContent.childCount - 1; index >= 0; index--)
            {
                Transform child = listContent.GetChild(index);
                if (child.name.StartsWith("RuntimeSearchResult_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            }
        }

        private static RectTransform EnsureVerticalLayout(GameObject target)
        {
            RectTransform viewport = target.GetComponent<RectTransform>()
                ?? throw new InvalidOperationException("XunBao result ListView RectTransform is missing.");
            ScrollRect scroll = target.GetComponent<ScrollRect>() ?? target.AddComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            RectTransform content = target.transform.Find("RuntimeContent") as RectTransform;
            if (content == null)
            {
                GameObject contentObject = new GameObject("RuntimeContent", typeof(RectTransform));
                content = contentObject.GetComponent<RectTransform>();
                content.SetParent(target.transform, false);
            }
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            VerticalLayoutGroup layout = content.GetComponent<VerticalLayoutGroup>()
                ?? content.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.spacing = 10f;
            layout.childControlWidth = true;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = content.GetComponent<ContentSizeFitter>()
                ?? content.gameObject.AddComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.content = content;
            return content;
        }

        private static void EnsureHorizontalLayout(GameObject target)
        {
            HorizontalLayoutGroup layout = target.GetComponent<HorizontalLayoutGroup>()
                ?? target.AddComponent<HorizontalLayoutGroup>();
            layout.spacing = 8f;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
        }

        private Text CreateText(Transform parent, string name, string value, TextAnchor alignment)
        {
            Text source = view.Binding.Find("Layer/Souxun/Button_1/Text")?.GetComponent<Text>();
            GameObject node = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(parent, false);
            Text text = node.GetComponent<Text>();
            text.font = source != null ? source.font : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = source != null ? source.fontSize : 18;
            text.color = Color.white;
            text.alignment = alignment;
            text.raycastTarget = false;
            text.text = value;
            return text;
        }

        private Button Bind(string path, Action action)
        {
            GameObject node = Require(path);
            Button button = node.GetComponent<Button>()
                ?? throw new InvalidOperationException($"XunBao result Button is missing: {path}");
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
            return button;
        }

        private GameObject InstallTopRightClose(GameObject template)
        {
            if (template == null)
                throw new InvalidOperationException("XunBao shared second-class close template was not found.");
            Transform popup = Require("Layer/Souxun/Popup").transform;
            GameObject control = UnityEngine.Object.Instantiate(template, popup, false);
            control.name = "RuntimeXunBaoResultClose";
            control.SetActive(true);
            RectTransform rect = control.GetComponent<RectTransform>();
            if (rect != null)
            {
                rect.anchorMin = rect.anchorMax = Vector2.one;
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(-12f, -12f);
                rect.localScale = Vector3.one;
                rect.localRotation = Quaternion.identity;
            }
            control.transform.SetAsLastSibling();
            Button button = control.GetComponent<Button>() ?? control.AddComponent<Button>();
            button.targetGraphic = control.GetComponent<Graphic>() ?? control.GetComponentInChildren<Graphic>(true);
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(Hide);
            return control;
        }

        private GameObject Require(string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException($"XunBao result node is missing: {path}");

        private void SetText(string path, string value)
            => SetText(Require(path).transform.parent, Require(path).name, value);

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
        }
    }

    public sealed class XunBaoComposeAllPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly ResourceService resources;
        private readonly Transform tableView;
        private readonly RectTransform listContent;
        private readonly GameObject rowTemplate;
        private readonly Button closeButton;
        private readonly CocosTimelinePlayer timeline;

        public XunBaoComposeAllPresenter(CocosUiView view, ResourceService resources)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            Normalize(view.GameObject.transform);
            GameObject panel = Require("Layer/saodangchenggong");
            tableView = Require("Layer/saodangchenggong/TableView").transform;
            rowTemplate = Require("Layer/saodangchenggong/ItemList");
            rowTemplate.SetActive(false);
            Image closeGraphic = panel.GetComponent<Image>() ?? panel.AddComponent<Image>();
            closeGraphic.color = Color.clear;
            closeGraphic.raycastTarget = true;
            closeButton = panel.GetComponent<Button>() ?? panel.AddComponent<Button>();
            closeButton.targetGraphic = closeGraphic;
            closeButton.onClick.RemoveAllListeners();
            closeButton.onClick.AddListener(Hide);
            timeline = view.GameObject.GetComponent<CocosTimelinePlayer>();
            listContent = EnsureVerticalLayout(tableView.gameObject);
            Hide();
        }

        public bool IsVisible => view.GameObject.activeSelf;
        public bool IsAnimationPlaying => timeline?.IsPlaying == true;
        public Button CloseControl => closeButton;
        public int RenderedRewardCount { get; private set; }

        public void Show(IReadOnlyList<RewardRecord> rewards)
        {
            if (rewards == null || rewards.Count == 0)
                throw new ArgumentException("At least one XunBao compose-all reward is required.", nameof(rewards));
            ClearRows();
            for (int start = 0; start < rewards.Count; start += 7)
            {
                GameObject row = UnityEngine.Object.Instantiate(rowTemplate, listContent, false);
                row.name = $"RuntimeSaoDangRow_{start / 7 + 1}";
                row.SetActive(true);
                RectTransform rowRect = row.GetComponent<RectTransform>();
                LayoutElement rowLayout = row.GetComponent<LayoutElement>() ?? row.AddComponent<LayoutElement>();
                rowLayout.preferredHeight = rowRect != null ? rowRect.rect.height : 142f;
                for (int slot = 0; slot < 7; slot++)
                {
                    Transform cell = row.transform.Find($"itemlayer_{slot + 1}");
                    if (cell == null) continue;
                    int rewardIndex = start + slot;
                    cell.gameObject.SetActive(rewardIndex < rewards.Count);
                    if (rewardIndex >= rewards.Count) continue;
                    RenderCell(cell, rewards[rewardIndex]);
                    RenderedRewardCount++;
                }
            }
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
            if (timeline != null && timeline.Duration > 0)
                timeline.Play(0, timeline.Duration, false);
            Canvas.ForceUpdateCanvases();
        }

        public void Hide()
        {
            timeline?.Stop();
            view.SetVisible(false);
        }

        public void Dispose()
        {
            timeline?.Stop();
            ClearRows();
        }

        private void RenderCell(Transform cell, RewardRecord reward)
        {
            Text name = cell.Find("Name")?.GetComponent<Text>();
            if (name != null) name.text = $"{reward.Name}×{reward.Amount}";
            Image icon = cell.Find("item")?.GetComponent<Image>();
            Sprite sprite = resources.LoadItemIcon(reward.Picture);
            if (icon != null && sprite != null)
            {
                icon.sprite = sprite;
                icon.preserveAspect = true;
                icon.color = Color.white;
            }
        }

        private void ClearRows()
        {
            RenderedRewardCount = 0;
            for (int index = listContent.childCount - 1; index >= 0; index--)
            {
                Transform child = listContent.GetChild(index);
                if (child.name.StartsWith("RuntimeSaoDangRow_", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            }
        }

        private static RectTransform EnsureVerticalLayout(GameObject target)
        {
            RectTransform viewport = target.GetComponent<RectTransform>()
                ?? throw new InvalidOperationException("XunBao SaoDang TableView RectTransform is missing.");
            ScrollRect scroll = target.GetComponent<ScrollRect>() ?? target.AddComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            RectTransform content = target.transform.Find("RuntimeContent") as RectTransform;
            if (content == null)
            {
                GameObject contentObject = new GameObject("RuntimeContent", typeof(RectTransform));
                content = contentObject.GetComponent<RectTransform>();
                content.SetParent(target.transform, false);
            }
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            VerticalLayoutGroup layout = content.GetComponent<VerticalLayoutGroup>()
                ?? content.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.spacing = 2f;
            layout.childControlWidth = true;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = content.GetComponent<ContentSizeFitter>()
                ?? content.gameObject.AddComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.content = content;
            return content;
        }

        private GameObject Require(string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException($"XunBao SaoDang source node is missing: {path}");

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
        }
    }

    public sealed class XunBaoPopupPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly ResourceService resources;
        private readonly TaskStore tasks;
        private readonly Action<TaskRecord> claimTask;
        private readonly GameObject composePanel;
        private readonly GameObject confirmPanel;
        private readonly GameObject taskPanel;
        private readonly VirtualList<TaskRecord> taskList;
        private readonly GameObject taskTemplate;
        private readonly GameObject rewardIconTemplate;
        private readonly Dictionary<int, Button> taskClaimButtons = new Dictionary<int, Button>();
        private readonly Toggle suppressToggle;
        private readonly Toggle autoUseToggle;
        private readonly Button confirmButton;
        private readonly CocosTimelinePlayer timeline;
        private Action<bool> confirmAction;

        public XunBaoPopupPresenter(CocosUiView view, ResourceService resources, TaskStore tasks,
            Action<TaskRecord> claimTask)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.tasks = tasks ?? throw new ArgumentNullException(nameof(tasks));
            this.claimTask = claimTask ?? throw new ArgumentNullException(nameof(claimTask));
            Normalize(view.GameObject.transform);
            composePanel = Require("Layer/Hecheng");
            confirmPanel = Require("Layer/Popup");
            taskPanel = Require("Layer/Rewards");
            GameObject taskViewport = Require("Layer/Rewards/Popup/bg/Image2/ListView");
            taskTemplate = Require("Layer/Rewards/Popup/Reward");
            rewardIconTemplate = Require("Layer/Rewards/Popup/IconBg");
            taskTemplate.SetActive(false);
            rewardIconTemplate.SetActive(false);
            float taskHeight = Math.Max(120f, taskTemplate.GetComponent<RectTransform>()?.rect.height ?? 120f);
            taskList = new VirtualList<TaskRecord>(taskViewport, taskTemplate, taskHeight, BindTaskRow);
            suppressToggle = Require("Layer/Popup/CheckBox_0").GetComponent<Toggle>()
                ?? throw new InvalidOperationException("XunBao suppress-confirm Toggle is missing.");
            autoUseToggle = Require("Layer/Popup/bg/Panel_1/CheckBox").GetComponent<Toggle>()
                ?? throw new InvalidOperationException("XunBao auto-use Toggle is missing.");
            suppressToggle.isOn = false;
            autoUseToggle.isOn = true;
            confirmButton = Bind("Layer/Popup/Btn_1", Confirm);
            Bind("Layer/Popup/bg/Btn_close", Hide);
            Bind("Layer/Popup/Btn_2", Hide);
            // Formal CSB PanelOptions: ColorType=1, RGB=0/0/0, BackColorAlpha=178,
            // TouchEnable=true. Restore that visible panel graphic and bind its click.
            Bind("Layer/Hecheng/Black", Hide, true);
            Bind("Layer/Rewards/Popup/Btn_close", Hide);
            timeline = view.GameObject.GetComponent<CocosTimelinePlayer>();
            tasks.Changed += HandleTasksChanged;
            Hide();
        }

        public bool IsVisible => view.GameObject.activeSelf;
        public int Mode { get; private set; }
        public bool SuppressSearchConfirmation => suppressToggle.isOn;
        public bool AutoUseSearchToken => autoUseToggle.isOn;
        public Button ConfirmControl => confirmButton;
        public Toggle SuppressControl => suppressToggle;
        public Toggle AutoUseControl => autoUseToggle;
        public Button CancelControl => Require("Layer/Popup/Btn_2").GetComponent<Button>();
        public Button ComposeCloseControl => Require("Layer/Hecheng/Black").GetComponent<Button>();
        public Button TaskCloseControl => Require("Layer/Rewards/Popup/Btn_close").GetComponent<Button>();
        public int RenderedTaskCount { get; private set; }
        public int RenderedRewardCount { get; private set; }
        public Button GetFirstClaimableControl(out int taskId)
        {
            TaskRecord record = tasks.XunBaoItems.FirstOrDefault(item => item.State == 1);
            taskId = record.Id;
            return taskId > 0 && taskClaimButtons.TryGetValue(taskId, out Button button) ? button : null;
        }
        public string ComposeAttributeText => Require("Layer/Hecheng/TextBg/Text_3").GetComponent<Text>()?.text ?? string.Empty;
        public bool ComposeAttributeFits
        {
            get
            {
                Text text = Require("Layer/Hecheng/TextBg/Text_3").GetComponent<Text>();
                return text != null && (text.horizontalOverflow == HorizontalWrapMode.Overflow
                    || text.preferredWidth <= text.rectTransform.rect.width + 0.5f);
            }
        }

        public void ShowSearchConfirm(EquipmentDefinition definition, Action<bool> onConfirm)
        {
            if (definition == null) throw new ArgumentNullException(nameof(definition));
            Mode = 2;
            confirmAction = onConfirm;
            SetText("Layer/Popup/bg/Panel_1/text/Name", definition.Name ?? $"法宝 #{definition.Id}");
            SetMode(confirmPanel);
        }

        public void ShowCompose(EquipmentDefinition definition)
        {
            if (definition == null) throw new ArgumentNullException(nameof(definition));
            Mode = 1;
            confirmAction = null;
            SetText("Layer/Hecheng/NameBg/Name", $"{definition.Name}X1");
            Text attribute = Require("Layer/Hecheng/TextBg/Text_3").GetComponent<Text>();
            if (attribute != null)
            {
                attribute.horizontalOverflow = HorizontalWrapMode.Overflow;
                attribute.text = FormatAttribute(definition.BaseAttribute);
            }
            Image icon = Require("Layer/Hecheng/Bg/Icon").GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = resources.LoadFaBaoIcon(definition.Picture, out _);
                icon.preserveAspect = true;
                icon.color = Color.white;
            }
            SetMode(composePanel);
            if (timeline != null && timeline.Duration > 0) timeline.Play(0, timeline.Duration, true);
        }

        public void ShowTaskBoundary()
        {
            Mode = 3;
            confirmAction = null;
            SetText("Layer/Rewards/Popup/bg/Times/Text", tasks.XunBaoCount == 0 ? "加载中" : GetTodaySearchCount());
            SetMode(taskPanel);
            RenderTaskRewards();
        }

        public void RenderTaskRewards()
        {
            taskClaimButtons.Clear();
            IReadOnlyList<TaskRecord> items = tasks.XunBaoItems;
            RenderedTaskCount = items.Count;
            RenderedRewardCount = items.Sum(item => item.Rewards?.Count ?? 0);
            taskList.SetItems(items);
            SetText("Layer/Rewards/Popup/bg/Times/Text", GetTodaySearchCount());
            Canvas.ForceUpdateCanvases();
        }

        public void Hide()
        {
            timeline?.Stop();
            confirmAction = null;
            Mode = 0;
            view.SetVisible(false);
        }

        public void Dispose()
        {
            tasks.Changed -= HandleTasksChanged;
            confirmAction = null;
            timeline?.Stop();
            taskList.Dispose();
        }

        private void HandleTasksChanged()
        {
            if (Mode == 3) RenderTaskRewards();
        }

        private void BindTaskRow(RectTransform row, TaskRecord item, int index)
        {
            row.gameObject.name = $"XunBaoTask_{item.Id}_{index}";
            SetText(row, "Num", item.Description);
            SetText(row, "Value", $"{Math.Min(item.Progress, (uint)item.Target)}/{item.Target}");
            Transform rewardList = row.Find("ListView");
            if (rewardList != null)
            {
                ClearRuntimeChildren(rewardList);
                EnsureHorizontalLayout(rewardList.gameObject);
                for (int rewardIndex = 0; rewardIndex < item.Rewards.Count; rewardIndex++)
                {
                    TaskRewardDefinition reward = item.Rewards[rewardIndex];
                    GameObject iconCell = UnityEngine.Object.Instantiate(rewardIconTemplate, rewardList, false);
                    iconCell.name = $"RuntimeReward_{item.Id}_{rewardIndex}";
                    iconCell.SetActive(true);
                    Image qualityFrame = iconCell.GetComponent<Image>();
                    Sprite frameSprite = reward.quality > 0
                        ? resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(reward.quality, 1, 7):00}")
                        : null;
                    if (qualityFrame != null && frameSprite != null)
                    {
                        qualityFrame.sprite = frameSprite;
                        qualityFrame.enabled = true;
                    }
                    Image icon = iconCell.transform.Find("Icon")?.GetComponent<Image>();
                    if (icon != null)
                    {
                        icon.sprite = reward.isFaBao
                            ? resources.LoadFaBaoIcon(reward.pictureName, out _)
                            : resources.LoadItemIcon(reward.picture, out _);
                        icon.enabled = icon.sprite != null;
                        icon.preserveAspect = true;
                    }
                    SetText(iconCell.transform, "Text_5", $"×{reward.amount}");
                }
                if (rewardList is RectTransform rewardRect)
                    LayoutRebuilder.ForceRebuildLayoutImmediate(rewardRect);
            }
            bool claimed = item.State == 2;
            Transform buttonTransform = row.Find("Btn");
            Button button = buttonTransform?.GetComponent<Button>();
            if (button != null)
            {
                button.gameObject.SetActive(!claimed);
                button.onClick.RemoveAllListeners();
                button.interactable = item.State == 1;
                if (item.State == 1) button.onClick.AddListener(() => claimTask(item));
                taskClaimButtons[item.Id] = button;
            }
            Transform claimedMark = row.Find("Get");
            if (claimedMark != null) claimedMark.gameObject.SetActive(claimed);
        }

        private string GetTodaySearchCount()
        {
            TaskRecord search = tasks.XunBaoItems
                .Where(item => item.Definition != null && item.Definition.daily == 1
                    && item.Definition.condition != null && item.Definition.condition.Length > 0
                    && item.Definition.condition[0] == 14)
                .OrderByDescending(item => item.Id)
                .FirstOrDefault();
            return search.Definition == null ? "0" : Math.Min(search.Progress, (uint)search.Target).ToString();
        }

        private static void ClearRuntimeChildren(Transform parent)
        {
            for (int index = parent.childCount - 1; index >= 0; index--)
            {
                Transform child = parent.GetChild(index);
                if (child.name.StartsWith("Runtime", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            }
        }

        private static void EnsureHorizontalLayout(GameObject target)
        {
            HorizontalLayoutGroup layout = target.GetComponent<HorizontalLayoutGroup>()
                ?? target.AddComponent<HorizontalLayoutGroup>();
            layout.spacing = 8f;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
        }

        private void Confirm()
        {
            Action<bool> callback = confirmAction;
            bool autoUse = autoUseToggle.isOn;
            confirmAction = null;
            Hide();
            callback?.Invoke(autoUse);
        }

        private void SetMode(GameObject selected)
        {
            composePanel.SetActive(ReferenceEquals(selected, composePanel));
            confirmPanel.SetActive(ReferenceEquals(selected, confirmPanel));
            taskPanel.SetActive(ReferenceEquals(selected, taskPanel));
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        private Button Bind(string path, Action action, bool addIfMissing = false)
        {
            GameObject node = Require(path);
            Button button = node.GetComponent<Button>();
            if (addIfMissing)
            {
                Image panelMask = node.GetComponent<Image>() ?? node.AddComponent<Image>();
                panelMask.color = new Color32(0, 0, 0, 178);
                panelMask.raycastTarget = true;
                if (button == null) button = node.AddComponent<Button>();
                button.targetGraphic = panelMask;
            }
            if (button == null) throw new InvalidOperationException($"XunBao popup Button is missing: {path}");
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
            return button;
        }

        private GameObject Require(string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException($"XunBao popup node is missing: {path}");

        private void SetText(string path, string value)
        {
            Text text = Require(path).GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static string FormatAttribute(int[] value)
        {
            if (value == null || value.Length < 2) return string.Empty;
            int type = value[0];
            int amount = value[1];
            string amountText = type > 9 ? $"{amount / 100f:0.##}%" : amount.ToString();
            return $"{AttributeName(type)}+{amountText}";
        }

        private static string AttributeName(int type)
        {
            string[] names =
            {
                "", "攻击", "物防", "法防", "生命", "速度", "命中", "闪避", "暴击", "抗暴",
                "攻击加成", "物防加成", "法防加成", "生命加成", "速度加成", "命中率", "闪避率", "暴击率", "抗暴率",
                "增伤率", "物免率", "法免率", "暴击伤害", "反击率", "抗反率", "反击伤害", "连击率", "抗连率",
                "连击伤害", "反震率", "抗震率", "反震伤害", "负面强化", "负面抵抗"
            };
            return type > 0 && type < names.Length && !string.IsNullOrEmpty(names[type]) ? names[type] : $"属性{type}";
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
        }
    }
}
