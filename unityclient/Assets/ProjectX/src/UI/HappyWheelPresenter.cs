using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HappyWheelPresenter : IDisposable
    {
        private const string Base = "Layer/Panel/Bg";
        private const string PrefabSource = "cocosstudio/csd/huodong/ZhuanpanLayer.csd";
        private static readonly int[] IconHostTags =
            { 1956339026, 411740716, -451003694, 514210924, -812370300,
              1236698567, 1123380672, -686470730, -1407177206, 1579238474 };
        private static readonly int[] AmountTags =
            { -1279046915, 2123008869, -2126963876, 1710536175, 985570196,
              -1343447413, 1550615214, 479763923, 1992811106, -986618302 };
        private readonly CocosUiView view;
        private readonly HappyWheelStore store;
        private readonly BagStore bag;
        private readonly CurrencyStore currencies;
        private readonly IUiResourceProvider resources;
        private readonly ShopCatalog catalog;
        private readonly Action<byte> spin;
        private readonly Action openShop;
        private readonly Action<IReadOnlyList<RewardRecord>> showRewards;
        private readonly Action<RewardRecord> showRewardTip;
        private readonly GameObject content;
        private readonly Text activityTime;
        private readonly Text resetTime;
        private readonly Text score;
        private readonly Text keyCount;
        private readonly Text premiumCount;
        private readonly Text singleCost;
        private readonly Text multiCost;
        private readonly Text personalRecordTemplate;
        private readonly RectTransform personalRecordContent;
        private readonly ScrollRect personalRecordScroll;
        private readonly Button singleButton;
        private readonly Button multiButton;
        private readonly Button shopButton;
        private readonly Image[] icons = new Image[10];
        private readonly Text[] amounts = new Text[10];
        private readonly Button[] rewardButtons = new Button[10];
        private readonly List<Text> historyRows = new List<Text>();
        private readonly HappyWheelSpinEffect effect;
        private string renderedHistorySignature;

        public HappyWheelPresenter(CocosUiView view, HappyWheelStore store, BagStore bag,
            CurrencyStore currencies, IUiResourceProvider resources, ShopCatalog catalog,
            Action<byte> spin, Action openShop, Action<IReadOnlyList<RewardRecord>> showRewards,
            Action<RewardRecord> showRewardTip)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.spin = spin ?? throw new ArgumentNullException(nameof(spin));
            this.openShop = openShop ?? throw new ArgumentNullException(nameof(openShop));
            this.showRewards = showRewards ?? throw new ArgumentNullException(nameof(showRewards));
            this.showRewardTip = showRewardTip ?? throw new ArgumentNullException(nameof(showRewardTip));

            Normalize(view.GameObject.transform);
            content = Node(-1236041657, Base);
            activityTime = FindText(-1438819398, Base + "/TitleBg/Text/Time");
            resetTime = FindText(2083558303, Base + "/Draw/Button3/Bg2/Num");
            score = FindText(-723641997, Base + "/Draw/Button3/Bg1/Num");
            keyCount = FindText(-579775541, Base + "/HaveBg_1/Value");
            premiumCount = FindText(662150212, Base + "/HaveBg/Value");
            singleCost = FindText(-1293489476, Base + "/Draw/Button1/Bg/Num");
            multiCost = FindText(-49516096, Base + "/Draw/Button2/Bg/Num");
            personalRecordTemplate = FindText(-1501974914, Base + "/RecordBg/TitleBg1/bg/Text");
            personalRecordContent = Node(2116577027, Base + "/RecordBg/TitleBg1/bg/List")
                .GetComponent<RectTransform>();
            if (personalRecordContent == null)
                throw new InvalidOperationException("HappyWheel personal record List requires RectTransform.");
            personalRecordScroll = ConfigureHistoryScroll(
                Node(966573082, Base + "/RecordBg/TitleBg1/bg"), personalRecordContent);
            if (personalRecordTemplate != null) personalRecordTemplate.gameObject.SetActive(false);
            singleButton = BindButton(1825890577, Base + "/Draw/Button1", 0);
            multiButton = BindButton(1101508221, Base + "/Draw/Button2", 1);
            shopButton = BindShopButton(-1263212707, Base + "/Draw/Button3");
            SetVisible(Node(-2086126345, Base + "/RecordBg/TitleBg2"), false);

            for (int index = 0; index < icons.Length; index++)
            {
                GameObject host = Node(IconHostTags[index], Base + $"/Panel_17/RewardBg/IconBg_{index + 1}");
                icons[index] = CreateRuntimeIcon(host.transform, index + 1);
                rewardButtons[index] = BindRewardButton(host, icons[index], index);
                amounts[index] = FindText(AmountTags[index], Base + $"/Panel_17/RewardBg/RewardBg{index + 1}");
            }

            RectTransform pointer = Node(-1642080601, Base + "/Panel_17/ZhenImage").GetComponent<RectTransform>();
            RectTransform selection = Node(-99373565, Base + "/Panel_17/RewardBg/Choose").GetComponent<RectTransform>();
            effect = view.GameObject.GetComponent<HappyWheelSpinEffect>()
                ?? view.GameObject.AddComponent<HappyWheelSpinEffect>();
            effect.Initialize(pointer, selection);
            store.Changed += RenderState;
            store.Spun += HandleSpun;
            bag.Changed += Render;
            currencies.Changed += Render;
            RenderState();
        }

        public void Dispose()
        {
            store.Changed -= RenderState;
            store.Spun -= HandleSpun;
            bag.Changed -= Render;
            currencies.Changed -= Render;
            effect?.Clear();
        }

        public void Tick(float deltaTime)
        {
            if (!store.HasAuthoritativeResponse || store.ResetSeconds == 0 || resetTime == null) return;
            // Server time is authoritative at response time. The presenter only performs a visual countdown.
            uint elapsed = (uint)Mathf.Max(0, Mathf.FloorToInt(Time.unscaledTime - effect.StateReceivedAt));
            resetTime.text = FormatTime(store.ResetSeconds > elapsed ? store.ResetSeconds - elapsed : 0);
        }

        private void Render()
        {
            bool ready = store.HasAuthoritativeResponse;
            content.SetActive(ready);
            if (!ready) return;
            if (activityTime != null) activityTime.text = store.ActivitySeconds == 0
                ? "常驻" : FormatTime(store.ActivitySeconds);
            if (resetTime != null) resetTime.text = FormatTime(store.ResetSeconds);
            if (score != null) score.text = store.Score.ToString();
            int ownedKeys = bag.GetTotalQuantityByItemId(store.CostItemId);
            if (keyCount != null) keyCount.text = ownedKeys.ToString();
            if (premiumCount != null) premiumCount.text = currencies.Premium.ToString();
            if (singleCost != null) singleCost.text = $"{store.SingleKeyCost}/{ownedKeys}";
            if (multiCost != null) multiCost.text = $"{store.MultiKeyCost}/{ownedKeys}";

            for (int index = 0; index < icons.Length; index++)
            {
                bool visible = index < store.Rewards.Count;
                icons[index].gameObject.SetActive(visible);
                rewardButtons[index].interactable = visible;
                if (!visible) continue;
                HappyWheelReward configured = store.Rewards[index];
                RewardRecord reward = catalog.DescribeServerReward(configured.Type, 0, configured.Amount);
                icons[index].sprite = resources.LoadItemIcon(reward.Picture);
                icons[index].preserveAspect = true;
                if (amounts[index] != null) amounts[index].text = "x" + configured.Amount;
            }

            bool idle = store.PendingDrawType < 0;
            singleButton.interactable = idle;
            multiButton.interactable = idle;
            shopButton.interactable = idle;
        }

        private void RenderState()
        {
            effect.MarkStateReceived();
            Render();
            RenderHistory();
        }

        private void HandleSpun(IReadOnlyList<int> indexes)
        {
            if (indexes == null || indexes.Count == 0) return;
            int selected = Mathf.Clamp(indexes[indexes.Count - 1], 0, Math.Max(0, store.Rewards.Count - 1));
            effect.Play(selected, Math.Max(1, store.Rewards.Count), () =>
            {
                List<RewardRecord> rewards = new List<RewardRecord>();
                foreach (int rawIndex in indexes)
                {
                    int index = Mathf.Clamp(rawIndex, 0, Math.Max(0, store.Rewards.Count - 1));
                    HappyWheelReward configured = store.Rewards[index];
                    rewards.Add(catalog.DescribeServerReward(configured.Type, 0, configured.Amount));
                }
                showRewards(rewards);
            });
        }

        private Button BindButton(int actionTag, string path, byte drawType)
        {
            GameObject node = Node(actionTag, path);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => spin(drawType));
            return button;
        }

        private Button BindShopButton(int actionTag, string path)
        {
            GameObject node = Node(actionTag, path);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => openShop());
            return button;
        }

        private Button BindRewardButton(GameObject host, Graphic target, int index)
        {
            Button button = host.GetComponent<Button>() ?? host.AddComponent<Button>();
            button.targetGraphic = target;
            button.transition = Selectable.Transition.None;
            if (target != null) target.raycastTarget = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                if (index < 0 || index >= store.Rewards.Count) return;
                HappyWheelReward configured = store.Rewards[index];
                showRewardTip(catalog.DescribeServerReward(configured.Type, 0, configured.Amount));
            });
            return button;
        }

        private static ScrollRect ConfigureHistoryScroll(GameObject viewportObject, RectTransform list)
        {
            RectTransform viewport = viewportObject.GetComponent<RectTransform>()
                ?? throw new InvalidOperationException(
                    "HappyWheel personal record viewport requires RectTransform.");
            Image background = viewportObject.GetComponent<Image>();
            if (background != null) background.raycastTarget = true;
            if (viewportObject.GetComponent<RectMask2D>() == null)
                viewportObject.AddComponent<RectMask2D>();
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>()
                ?? viewportObject.AddComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.content = list;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.inertia = true;
            scroll.scrollSensitivity = 24f;

            list.anchorMin = new Vector2(0f, 1f);
            list.anchorMax = new Vector2(1f, 1f);
            list.pivot = new Vector2(0.5f, 1f);
            list.anchoredPosition = Vector2.zero;
            list.sizeDelta = Vector2.zero;
            VerticalLayoutGroup layout = list.GetComponent<VerticalLayoutGroup>()
                ?? list.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.padding = new RectOffset(6, 6, 4, 4);
            layout.spacing = 2f;
            layout.childAlignment = TextAnchor.UpperLeft;
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = list.GetComponent<ContentSizeFitter>()
                ?? list.gameObject.AddComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            return scroll;
        }

        private void RenderHistory()
        {
            if (!store.HasAuthoritativeResponse)
            {
                renderedHistorySignature = null;
                foreach (Text row in historyRows) row.gameObject.SetActive(false);
                return;
            }
            string[] entries = store.PersonalHistory.Reverse().Take(store.HistoryLimit)
                .Select(StripMarkup).Where(value => !string.IsNullOrWhiteSpace(value)).ToArray();
            if (entries.Length == 0) entries = new[] { "暂无抽奖记录" };
            string signature = string.Join("\u001f", entries);
            if (signature == renderedHistorySignature) return;
            renderedHistorySignature = signature;
            for (int index = 0; index < entries.Length; index++)
            {
                Text row = GetOrCreateHistoryRow(index);
                row.text = entries[index];
                row.gameObject.SetActive(true);
            }
            for (int index = entries.Length; index < historyRows.Count; index++)
                historyRows[index].gameObject.SetActive(false);
            Canvas.ForceUpdateCanvases();
            personalRecordScroll.verticalNormalizedPosition = 1f;
        }

        private Text GetOrCreateHistoryRow(int index)
        {
            if (index < historyRows.Count) return historyRows[index];
            GameObject node = new GameObject($"HappyWheelHistoryRow{index + 1}",
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(LayoutElement));
            node.transform.SetParent(personalRecordContent, false);
            Text row = node.GetComponent<Text>();
            if (personalRecordTemplate != null)
            {
                row.font = personalRecordTemplate.font;
                row.fontSize = personalRecordTemplate.fontSize;
                row.fontStyle = personalRecordTemplate.fontStyle;
                row.color = personalRecordTemplate.color;
                row.lineSpacing = personalRecordTemplate.lineSpacing;
            }
            row.alignment = TextAnchor.MiddleLeft;
            row.horizontalOverflow = HorizontalWrapMode.Wrap;
            row.verticalOverflow = VerticalWrapMode.Truncate;
            row.supportRichText = false;
            row.raycastTarget = false;
            LayoutElement element = node.GetComponent<LayoutElement>();
            element.minHeight = 28f;
            element.preferredHeight = 28f;
            historyRows.Add(row);
            return row;
        }

        private Image CreateRuntimeIcon(Transform parent, int index)
        {
            Transform existing = parent.Find("RuntimeHappyWheelIcon");
            if (existing != null) return existing.GetComponent<Image>();
            GameObject node = new GameObject("RuntimeHappyWheelIcon", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(.08f, .08f);
            rect.anchorMax = new Vector2(.92f, .92f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = node.GetComponent<Image>();
            image.raycastTarget = true;
            return image;
        }

        private GameObject Node(int actionTag, string path) =>
            view.GetSerializedNodeByActionTag(actionTag, PrefabSource, path);

        private Text FindText(int actionTag, string path)
        {
            GameObject node = Node(actionTag, path);
            return node.GetComponent<Text>() ?? node.GetComponentInChildren<Text>(true);
        }

        private static void SetVisible(GameObject node, bool visible)
        {
            if (node != null) node.SetActive(visible);
        }

        private static string StripMarkup(string value) => string.IsNullOrEmpty(value)
            ? string.Empty : Regex.Replace(value, @"\[/?c[^\]]*\]", string.Empty);

        private static string FormatTime(uint seconds)
        {
            TimeSpan value = TimeSpan.FromSeconds(seconds);
            return value.TotalDays >= 1 ? $"{(int)value.TotalDays}天{value:hh\\:mm\\:ss}" : value.ToString(@"hh\:mm\:ss");
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }

    public sealed class HappyWheelSpinEffect : MonoBehaviour
    {
        private RectTransform pointer;
        private RectTransform selection;
        private Coroutine routine;
        private float baseAngle;
        private float selectionBaseAngle;
        public float StateReceivedAt { get; private set; }

        public void Initialize(RectTransform target, RectTransform selectionTarget)
        {
            pointer = target;
            selection = selectionTarget;
            baseAngle = pointer != null ? pointer.localEulerAngles.z : 0f;
            selectionBaseAngle = selection != null ? selection.localEulerAngles.z : 0f;
            MarkStateReceived();
        }

        public void MarkStateReceived() => StateReceivedAt = Time.unscaledTime;

        public void Play(int selectedIndex, int slotCount, Action completed)
        {
            Clear();
            if (!isActiveAndEnabled || (pointer == null && selection == null))
            {
                completed?.Invoke();
                return;
            }
            routine = StartCoroutine(SpinRoutine(selectedIndex, slotCount, completed));
        }

        public void Clear()
        {
            if (routine != null) StopCoroutine(routine);
            routine = null;
        }

        private IEnumerator SpinRoutine(int selectedIndex, int slotCount, Action completed)
        {
            float start = pointer != null ? pointer.localEulerAngles.z : baseAngle;
            float selectionStart = selection != null ? selection.localEulerAngles.z : selectionBaseAngle;
            float slotAngle = 360f / Mathf.Max(1, slotCount);
            float desired = Mathf.Repeat(baseAngle - selectedIndex * slotAngle, 360f);
            float clockwiseDistance = Mathf.Repeat(start - desired, 360f);
            float target = start - 1080f - clockwiseDistance;
            const float duration = 1.5f;
            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                float progress = Mathf.Clamp01(elapsed / duration);
                float eased = 1f - Mathf.Pow(1f - progress, 3f);
                float angle = Mathf.LerpUnclamped(start, target, eased);
                if (pointer != null)
                    pointer.localRotation = Quaternion.Euler(0f, 0f, angle);
                if (selection != null)
                    selection.localRotation = Quaternion.Euler(
                        0f, 0f, selectionStart + (angle - start));
                yield return null;
            }
            if (pointer != null)
                pointer.localRotation = Quaternion.Euler(0f, 0f, target);
            if (selection != null)
                selection.localRotation = Quaternion.Euler(
                    0f, 0f, selectionStart + (target - start));
            routine = null;
            completed?.Invoke();
        }

        private void OnDisable() => Clear();
    }
}
