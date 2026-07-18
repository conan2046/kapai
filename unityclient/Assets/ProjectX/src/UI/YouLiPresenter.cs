using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class YouLiPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly YouLiStore store;
        private readonly int playerLevel;
        private readonly List<GameObject> cards = new List<GameObject>();
        private readonly Transform template;
        private readonly RectTransform content;

        public YouLiPresenter(CocosUiView view, YouLiStore store, int playerLevel, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.playerLevel = playerLevel;
            Normalize(view.GameObject.transform);

            Transform root = Require(view.GameObject.transform, "youliUI");
            root.gameObject.SetActive(true);
            template = Require(root, "Item");
            template.gameObject.SetActive(false);
            Transform list = Require(root, "ListView");
            content = CreateContent(list);

            SetButtonEnabled(Find(root, "Btn_youli"), false);
            SetButtonEnabled(Find(root, "Btn_lingqu"), false);
            store.Changed += Render;
            Render();
        }

        public int RenderedCount { get; private set; }
        public bool EmptyStateVisible => store.HasAuthoritativeResponse && store.ServerRecordCount == 0;

        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            foreach (GameObject card in cards)
                if (card != null) UnityEngine.Object.Destroy(card);
            cards.Clear();
            RenderedCount = 0;

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
                SetVisible(Find(item, "Lock"), !unlocked);
                SetText(Find(item, "Lock/Condition"), $"等级达到{value.Definition.UnlockLevel}开启");
                SetVisible(Find(item, "Btn_youli"), unlocked && !value.IsActive);
                SetButtonEnabled(Find(item, "Btn_youli"), false);
                SetVisible(Find(item, "Text_1"), unlocked && value.IsActive && value.EndTime > 0 && value.EndTime <= (uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
                SetVisible(Find(item, "Text_2"), unlocked && value.IsActive);
                SetVisible(Find(item, "TimeBg"), unlocked && value.IsActive);
                SetText(Find(item, "TimeBg/Time"), value.IsActive ? FormatRemaining(value.EndTime) : string.Empty);
                SetVisible(Find(item, "Bg/bg1"), !value.IsActive);
                SetVisible(Find(item, "Bg/bg2"), value.IsActive);

                cards.Add(card);
                RenderedCount++;
            }
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
