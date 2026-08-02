using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameplayPresenter : IDisposable
    {
        private const float RowHeight = 130f;
        private const float RowSpacing = 2f;
        private const float FirstRowTopOffset = 65f;
        private const float ActivityHorizontalLayoutCorrection = -16f;

        private readonly CocosUiView frameView;
        private readonly CocosUiView contentView;
        private readonly GameplayStore store;
        private readonly ResourceService resources;
        private readonly Action<int> enter;
        private readonly Action close;
        private readonly List<GameObject> runtimeRows = new List<GameObject>();
        private readonly Dictionary<int, Button> enterButtons = new Dictionary<int, Button>();
        private readonly RectTransform listContent;
        private readonly ScrollRect listScroll;
        private readonly Transform rowTemplate;
        private Button frameCloseButton;

        public GameplayPresenter(CocosUiView frameView, CocosUiView contentView,
            GameplayStore store, ResourceService resources, Action<int> enter, Action close)
        {
            this.frameView = frameView ?? throw new ArgumentNullException(nameof(frameView));
            this.contentView = contentView ?? throw new ArgumentNullException(nameof(contentView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.enter = enter ?? throw new ArgumentNullException(nameof(enter));
            this.close = close ?? throw new ArgumentNullException(nameof(close));

            NormalizeRoot(frameView.GameObject.transform);
            NormalizeRoot(contentView.GameObject.transform);
            contentView.SetVisible(true);

            ConfigureFrame();
            ConfigureTransientLayers();

            Transform activityBackground = FindNamed(contentView.GameObject.transform, "ActivityBg")
                ?? throw new InvalidOperationException("Gameplay ActivityBg was not found in common/ActivityLayer.");
            RectTransform activityRect = activityBackground.GetComponent<RectTransform>();
            if (activityRect != null)
                activityRect.anchoredPosition += new Vector2(ActivityHorizontalLayoutCorrection, 0f);
            rowTemplate = FindNamed(activityBackground, "ActivityList")
                ?? throw new InvalidOperationException("Gameplay ActivityList template was not found.");
            rowTemplate.gameObject.SetActive(false);
            listContent = ConfigureList(activityBackground);
            listScroll = activityBackground.GetComponent<ScrollRect>();

            store.Changed += Render;
            Render();
        }

        public int RenderedCount { get; private set; }
        public int MissingIconCount { get; private set; }
        public int EnterButtonCount => enterButtons.Count;
        public bool EmptyStateVisible => RenderedCount == 0;
        public float VerticalNormalizedPosition => listScroll == null ? 1f : listScroll.verticalNormalizedPosition;
        public bool CardBodiesInert => runtimeRows.TrueForAll(row =>
            row == null || AllCardBodiesInert(row.transform));

        public void InvokeClose() => frameCloseButton?.onClick.Invoke();

        public bool InvokeEnter(int functionId)
        {
            if (!enterButtons.TryGetValue(functionId, out Button button) || button == null || !button.interactable)
                return false;
            button.onClick.Invoke();
            return true;
        }

        public void HideDetail() { }

        public void ResetScrollToTop()
        {
            if (listScroll == null) return;
            Canvas.ForceUpdateCanvases();
            listScroll.StopMovement();
            listScroll.verticalNormalizedPosition = 1f;
        }

        public void ScrollToBottom()
        {
            if (listScroll == null) return;
            Canvas.ForceUpdateCanvases();
            listScroll.StopMovement();
            listScroll.verticalNormalizedPosition = 0f;
        }

        public bool IsHotPointVisible(int functionId)
        {
            Transform card = runtimeRows.SelectMany(row => row.GetComponentsInChildren<Transform>(true))
                .FirstOrDefault(value => value.name == $"Function_{functionId}");
            return FindDirect(card, "Prompt")?.gameObject.activeSelf == true;
        }

        public void Dispose()
        {
            store.Changed -= Render;
            if (frameCloseButton != null) frameCloseButton.onClick.RemoveAllListeners();
        }

        private void ConfigureFrame()
        {
            Transform shopBackground = FindNamed(frameView.GameObject.transform, "shopBg")
                ?? throw new InvalidOperationException("Gameplay shop/shop_bg root was not found.");
            Transform popup = FindDirect(shopBackground, "Popup")
                ?? throw new InvalidOperationException("Gameplay shop/shop_bg Popup was not found.");
            Transform titleRoot = FindDirect(popup, "Title");
            Text title = FindDirect(titleRoot, "Title")?.GetComponent<Text>();
            if (title != null) title.text = "玩法";
            frameCloseButton = Bind(FindDirect(popup, "Btn_close"), close);
            SetVisible(FindDirect(shopBackground, "Btn_ListView"), false);

            // Keep shopBg/Image in its imported Cocos sibling order. It precedes
            // Popup, so the title frame masks the middle of the fan decoration.
            Transform decoration = FindDirect(shopBackground, "Image");
            if (decoration != null)
            {
                Vector3 scale = decoration.localScale;
                decoration.localScale = new Vector3(-Mathf.Abs(scale.x), scale.y, scale.z);
                decoration.localEulerAngles = Vector3.zero;
                RectTransform decorationRect = decoration.GetComponent<RectTransform>();
                if (decorationRect != null) decorationRect.anchoredPosition += new Vector2(24f, 0f);
            }
        }

        private void ConfigureTransientLayers()
        {
            // TaskPopupLayer is an unreachable legacy detail surface: native card bodies
            // have touchEnabled=false. Keep the imported asset available but never show it
            // as part of the current hall.
            SetVisible(FindDirect(frameView.GameObject.transform, "TaskPopupLayer"), false);
            Transform notice = FindDirect(frameView.GameObject.transform, "FloatNoticeLayer")
                ?? throw new InvalidOperationException("Gameplay FloatNoticeLayer was not found.");
            // The native G1 stable frames had no live server announcement. Do not fabricate
            // one merely because the reusable FloatNotice prefab exists in the scene.
            notice.gameObject.SetActive(false);
        }

        private static RectTransform ConfigureList(Transform activityBackground)
        {
            RectTransform viewport = activityBackground.GetComponent<RectTransform>();
            if (viewport == null) throw new InvalidOperationException("Gameplay ActivityBg has no RectTransform.");
            if (activityBackground.GetComponent<RectMask2D>() == null)
                activityBackground.gameObject.AddComponent<RectMask2D>();
            ScrollRect scroll = activityBackground.GetComponent<ScrollRect>()
                ?? activityBackground.gameObject.AddComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            scroll.elasticity = 0.1f;
            scroll.decelerationRate = 0.135f;
            scroll.scrollSensitivity = 45f;
            scroll.viewport = viewport;

            GameObject contentObject = new GameObject("RuntimeGameplayContent", typeof(RectTransform));
            RectTransform content = contentObject.GetComponent<RectTransform>();
            content.SetParent(activityBackground, false);
            content.anchorMin = new Vector2(0f, 1f);
            content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            content.sizeDelta = Vector2.zero;
            scroll.content = content;
            return content;
        }

        private void Render()
        {
            Vector2 previousPosition = listContent.anchoredPosition;
            foreach (GameObject row in runtimeRows)
            {
                if (row == null) continue;
                row.SetActive(false);
                UnityEngine.Object.Destroy(row);
            }
            runtimeRows.Clear();
            enterButtons.Clear();
            RenderedCount = 0;
            MissingIconCount = 0;

            IReadOnlyList<GameplayRecord> values = store.Items;
            int rowCount = (values.Count + 1) / 2;
            listContent.sizeDelta = new Vector2(0f, rowCount == 0
                ? 0f : rowCount * RowHeight + Math.Max(0, rowCount - 1) * RowSpacing);
            for (int rowIndex = 0; rowIndex < rowCount; rowIndex++)
            {
                GameObject row = UnityEngine.Object.Instantiate(rowTemplate.gameObject, listContent, false);
                row.name = $"GameplayRow{rowIndex + 1}";
                row.SetActive(true);
                RectTransform rect = row.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(0f, 0.5f);
                rect.sizeDelta = new Vector2(940f, RowHeight);
                rect.anchoredPosition = new Vector2(15f, -FirstRowTopOffset - rowIndex * (RowHeight + RowSpacing));
                runtimeRows.Add(row);

                int first = rowIndex * 2;
                ConfigureCard(FindDirect(row.transform, "TaskBtn1"), values[first]);
                Transform secondCard = FindDirect(row.transform, "TaskBtn2");
                if (first + 1 < values.Count) ConfigureCard(secondCard, values[first + 1]);
                else SetVisible(secondCard, false);
            }
            listContent.anchoredPosition = values.Count == 0 ? Vector2.zero : previousPosition;
        }

        private void ConfigureCard(Transform card, GameplayRecord value)
        {
            if (card == null) throw new InvalidOperationException("Gameplay row card was not found.");
            card.gameObject.name = $"Function_{value.Definition.Id}";
            card.gameObject.SetActive(true);
            int functionId = value.Definition.Id;
            Button cardButton = card.GetComponent<Button>();
            if (cardButton != null)
            {
                cardButton.onClick.RemoveAllListeners();
                ColorBlock colors = cardButton.colors;
                colors.normalColor = Color.white;
                colors.highlightedColor = Color.white;
                colors.pressedColor = Color.white;
                colors.selectedColor = Color.white;
                colors.disabledColor = Color.white;
                colors.colorMultiplier = 1f;
                colors.fadeDuration = 0f;
                cardButton.colors = colors;
                cardButton.transition = Selectable.Transition.None;
                cardButton.interactable = false;
                if (cardButton.targetGraphic != null) cardButton.targetGraphic.color = Color.white;
            }

            SetNamedText(card, "TaskName", value.Definition.Name);
            Text taskName = FindDirect(card, "TaskName")?.GetComponent<Text>();
            if (taskName != null) taskName.alignment = TextAnchor.MiddleLeft;
            Transform openLevel = FindDirect(card, "OpenLevel");
            SetText(openLevel, $"{value.Definition.OpenLevel}级开启");
            SetVisible(openLevel, !value.IsOpen);

            Transform enterButton = FindDirect(card, "EnterBtn");
            SetVisible(enterButton, value.IsOpen);
            Button button = Bind(enterButton, () => enter(functionId));
            if (button != null)
            {
                button.interactable = value.IsOpen;
                if (value.IsOpen) enterButtons[functionId] = button;
            }

            Image icon = FindDirect(card, "Icon")?.GetComponent<Image>();
            Sprite sprite = resources.LoadSprite($"GameplayIcons/{value.Definition.Icon}");
            if (icon != null)
            {
                icon.sprite = sprite;
                icon.enabled = sprite != null;
                icon.preserveAspect = true;
            }
            if (sprite == null) MissingIconCount++;
            SetVisible(FindDirect(card, "Prompt"), value.HasHotPoint);
            SetVisible(FindDirect(card, "Choose"), false);
            SetVisible(FindDirect(card, "State"), false);
            SetVisible(FindDirect(card, "win"), false);
            RenderedCount++;
        }

        private static bool AllCardBodiesInert(Transform row)
        {
            foreach (Transform child in row)
            {
                if (!child.name.StartsWith("Function_", StringComparison.Ordinal)) continue;
                Button button = child.GetComponent<Button>();
                if (button != null && button.interactable) return false;
            }
            return true;
        }

        private static Button Bind(Transform target, Action callback)
        {
            if (target == null) return null;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            if (button.targetGraphic == null) button.targetGraphic = target.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private static Transform FindNamed(Transform root, string name)
        {
            if (root == null) return null;
            foreach (Transform value in root.GetComponentsInChildren<Transform>(true))
                if (value.name == name) return value;
            return null;
        }

        private static Transform FindDirect(Transform root, string name)
        {
            if (root == null) return null;
            for (int index = 0; index < root.childCount; index++)
            {
                Transform child = root.GetChild(index);
                if (child.name == name) return child;
            }
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            Transform target = FindDirect(root, name);
            SetText(target, value);
        }

        private static void SetText(Transform target, string value)
        {
            Text text = target?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(Transform target, bool visible)
        {
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void NormalizeRoot(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localPosition = Vector3.zero;
        }
    }
}
