using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class YouLiPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly YouLiStore store;
        private readonly int playerLevel;
        private readonly ResourceService resources;
        private readonly List<GameObject> cards = new List<GameObject>();
        private readonly Transform template;
        private readonly RectTransform content;
        private readonly Action<byte> start;
        private readonly Action<byte> claim;
        private Button oneKeyStart;
        private Button oneKeyClaim;

        public YouLiPresenter(CocosUiView view, YouLiStore store, int playerLevel, ResourceService resources, Action<byte> start, Action<byte> claim, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.playerLevel = playerLevel;
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.start = start ?? throw new ArgumentNullException(nameof(start));
            this.claim = claim ?? throw new ArgumentNullException(nameof(claim));
            Normalize(view.GameObject.transform);
            InstallBackground(view.GameObject.transform);

            Transform root = Require(view.GameObject.transform, "youliUI");
            root.gameObject.SetActive(true);
            InstallTitle(root);
            template = Require(root, "Item");
            template.gameObject.SetActive(false);
            Transform list = Require(root, "ListView");
            content = CreateContent(list);

            oneKeyStart = Bind(Find(root, "Btn_youli"), StartFirstAvailable);
            oneKeyClaim = Bind(Find(root, "Btn_lingqu"), ClaimFirstReady);
            store.Changed += Render;
            Render();
        }

        public int RenderedCount { get; private set; }
        public int StartButtonCount { get; private set; }
        public bool OneKeyStartAvailable => oneKeyStart != null && oneKeyStart.interactable;
        public bool ClaimBindingReady => oneKeyClaim != null;
        public bool EmptyStateVisible => store.HasAuthoritativeResponse && store.ServerRecordCount == 0;

        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            foreach (GameObject card in cards)
                if (card != null) UnityEngine.Object.Destroy(card);
            cards.Clear();
            RenderedCount = 0;
            StartButtonCount = 0;

            foreach (YouLiRecord value in store.Items)
            {
                GameObject card = UnityEngine.Object.Instantiate(template.gameObject, content, false);
                card.name = $"Location_{value.Definition.Id}";
                card.SetActive(true);
                RectTransform rect = card.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = Vector2.zero;
                rect.localScale = Vector3.one;

                Transform item = Find(card.transform, "Item");
                bool unlocked = playerLevel >= value.Definition.UnlockLevel;
                SetText(Find(item, "Namebg/Name"), value.Definition.Name);
                Image locationImage = Find(item, "Image")?.GetComponent<Image>();
                if (locationImage != null)
                {
                    locationImage.sprite = resources.LoadSprite($"YouLiLocations/{value.Definition.Picture}");
                    locationImage.preserveAspect = false;
                    locationImage.color = Color.white;
                    RectTransform imageRect = locationImage.rectTransform;
                    RectTransform cardBackground = Find(item, "Bg/bg2") as RectTransform;
                    if (cardBackground != null)
                    {
                        imageRect.anchorMin = cardBackground.anchorMin;
                        imageRect.anchorMax = cardBackground.anchorMax;
                        imageRect.pivot = cardBackground.pivot;
                        imageRect.anchoredPosition = cardBackground.anchoredPosition;
                        imageRect.sizeDelta = cardBackground.sizeDelta;
                        imageRect.localScale = Vector3.one;
                    }
                }
                SetVisible(Find(item, "Lock"), !unlocked);
                SetText(Find(item, "Lock/Condition"), $"等级达到{value.Definition.UnlockLevel}开启");
                SetVisible(Find(item, "Btn_youli"), unlocked && !value.IsActive);
                Button startButton = Bind(Find(item, "Btn_youli"), () => start(value.Definition.Id));
                if (startButton != null) startButton.interactable = unlocked && !value.IsActive;
                if (startButton != null) StartButtonCount++;
                SetVisible(Find(item, "Text_1"), unlocked && value.IsActive && value.EndTime > 0 && value.EndTime <= (uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                SetVisible(Find(item, "Text_2"), unlocked && value.IsActive);
                SetVisible(Find(item, "TimeBg"), unlocked && value.IsActive);
                SetText(Find(item, "TimeBg/Time"), value.IsActive ? FormatRemaining(value.EndTime) : string.Empty);
                SetVisible(Find(item, "Bg/bg1"), !value.IsActive);
                SetVisible(Find(item, "Bg/bg2"), value.IsActive);

                cards.Add(card);
                RenderedCount++;
            }
            if (oneKeyStart != null) oneKeyStart.interactable = store.Items.Any(value => playerLevel >= value.Definition.UnlockLevel && !value.IsActive);
            if (oneKeyClaim != null) oneKeyClaim.interactable = store.Items.Any(IsReady);
            SetVisible(Find(view.GameObject.transform, "youliUI/Panel"), store.ServerRecordCount > 0);
        }

        private bool IsReady(YouLiRecord value) => value.IsActive && value.EndTime > 0 && value.EndTime <= (uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        private void StartFirstAvailable()
        {
            YouLiRecord value = store.Items.FirstOrDefault(item => playerLevel >= item.Definition.UnlockLevel && !item.IsActive);
            if (value != null) start(value.Definition.Id);
        }
        private void ClaimFirstReady()
        {
            YouLiRecord value = store.Items.FirstOrDefault(IsReady);
            if (value != null) claim(value.Definition.Id);
        }

        private static RectTransform CreateContent(Transform list)
        {
            ScrollRect scroll = list.GetComponent<ScrollRect>() ?? list.gameObject.AddComponent<ScrollRect>();
            scroll.horizontal = true;
            scroll.vertical = false;
            scroll.movementType = ScrollRect.MovementType.Elastic;
            GameObject go = new GameObject("RuntimeYouLiLocations", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(ContentSizeFitter));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(list, false);
            rect.anchorMin = new Vector2(0f, 0f);
            rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = Vector2.zero;
            HorizontalLayoutGroup layout = go.GetComponent<HorizontalLayoutGroup>();
            layout.spacing = 8f;
            layout.padding = new RectOffset(4, 4, 0, 0);
            layout.childAlignment = TextAnchor.MiddleLeft;
            layout.childControlWidth = false;
            layout.childControlHeight = false;
            layout.childForceExpandWidth = false;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = go.GetComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.viewport = list.GetComponent<RectTransform>();
            scroll.content = rect;
            return rect;
        }

        private static string FormatRemaining(uint endTime)
        {
            long seconds = Math.Max(0, (long)endTime - DateTimeOffset.UtcNow.ToUnixTimeSeconds());
            return $"{seconds / 3600:00}:{seconds / 60 % 60:00}:{seconds % 60:00}";
        }

        private static void SetButtonEnabled(Transform target, bool enabled)
        {
            Button button = target?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = enabled;
        }

        private static void InstallBackground(Transform root)
        {
            if (root.Find("RuntimeYouLiBackground") != null) return;
            Sprite sprite = Resources.Load<Sprite>("Backgrounds/bg_xuezhan");
            if (sprite == null)
            {
                Texture2D texture = Resources.Load<Texture2D>("Backgrounds/bg_xuezhan");
                if (texture != null) sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(.5f, .5f), 100f);
            }
            if (sprite == null) return;
            GameObject go = new GameObject("RuntimeYouLiBackground", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(root, false);
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = go.GetComponent<Image>(); image.sprite = sprite; image.preserveAspect = false;
            rect.SetAsFirstSibling();
        }

        private static void InstallTitle(Transform root)
        {
            if (root.Find("RuntimeTitle") != null) return;
            Text source = root.Find("Item/Item/Namebg/Name")?.GetComponent<Text>();
            GameObject go = new GameObject("RuntimeTitle", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>(); rect.SetParent(root, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f); rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(150f, -10f); rect.sizeDelta = new Vector2(260f, 54f);
            Text title = go.GetComponent<Text>(); title.font = source != null ? source.font : Resources.GetBuiltinResource<Font>("Arial.ttf");
            title.fontSize = 30; title.color = new Color(.96f, .9f, .78f, 1f); title.alignment = TextAnchor.MiddleLeft; title.text = "游历三界";
        }

        private static Button Bind(Transform target, Action action)
        {
            if (target == null) return null;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => action());
            return button;
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

        private static Transform Require(Transform root, string path) => Find(root, path)
            ?? throw new InvalidOperationException($"YouLi imported node was not found: {path}");

        private static Transform Find(Transform root, string path) => root?.Find(path);

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }
}
