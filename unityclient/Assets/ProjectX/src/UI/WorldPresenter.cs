using System;
using System.Collections.Generic;
using System.Linq;
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
        private readonly CocosUiView worldView;
        private readonly CocosUiView mapView;
        private readonly CocosUiView detailView;
        private readonly WorldStore store;
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly ResourceService resources;
        private readonly Action<uint> requestChapter;
        private readonly Action<uint> requestStage;
        private readonly Action challenge;
        private readonly Action close;
        private readonly VirtualList<ListEntry> list;
        private bool showChapters = true;
        private bool showDetail;

        public WorldPresenter(CocosUiView worldView, CocosUiView mapView, CocosUiView detailView,
            WorldStore store, HeroStore heroes, FormationStore formation, ResourceService resources,
            Action<uint> requestChapter, Action<uint> requestStage, Action challenge, Action close)
        {
            this.worldView = worldView ?? throw new ArgumentNullException(nameof(worldView));
            this.mapView = mapView ?? throw new ArgumentNullException(nameof(mapView));
            this.detailView = detailView ?? throw new ArgumentNullException(nameof(detailView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.requestChapter = requestChapter ?? throw new ArgumentNullException(nameof(requestChapter));
            this.requestStage = requestStage ?? throw new ArgumentNullException(nameof(requestStage));
            this.challenge = challenge ?? throw new ArgumentNullException(nameof(challenge));
            this.close = close ?? throw new ArgumentNullException(nameof(close));

            ReparentOverlay(mapView, worldView.GameObject.transform, true);
            ReparentOverlay(detailView, worldView.GameObject.transform, false);
            GameObject popup = Require(mapView, "Layer/Popup");
            popup.SetActive(true);
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

            Bind(mapView, "Layer/Panel_zuoshang/Button_xiala", ShowChapterList);
            Bind(mapView, "Layer/Title/CloseBtn", close);
            Bind(detailView, $"{DetailRoot}/Close", CloseDetail);
            Bind(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2", challenge);
            SetButtonLabel(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2", "挑 战");
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_1", false);
            SetActive(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_3", false);
            SetButtonLabel(detailView, $"{DetailRoot}/Image_bg/Panel_1/Buzhen", "当前阵容");

            store.Changed += Render;
            heroes.Changed += Render;
            formation.Changed += Render;
            Render();
        }

        public int RenderedCount => list.Count;
        public int RenderedRewardCount { get; private set; }
        public bool DetailVisible => showDetail && store.SelectedStage != null;

        public void ShowWorld()
        {
            showDetail = false;
            showChapters = store.StageCount == 0;
            Render();
        }

        public void ShowStages()
        {
            showDetail = false;
            showChapters = false;
            Render();
        }

        public void ShowSelectedStage()
        {
            showChapters = false;
            showDetail = store.SelectedStage != null;
            Render();
        }

        public void Render()
        {
            mapView.GameObject.SetActive(!showDetail);
            detailView.GameObject.SetActive(DetailVisible);
            IReadOnlyList<ListEntry> entries = showChapters
                ? store.Chapters.Select(ListEntry.ForChapter).ToArray()
                : store.Stages.Select(ListEntry.ForStage).ToArray();
            list.SetItems(entries);
            SetText(mapView, "Layer/Panel_zuoshang/Image_bg2/guanqia",
                showChapters ? "主线章节" : string.IsNullOrEmpty(store.SelectedChapterName) ? "关卡" : store.SelectedChapterName);
            RenderDetail(store.SelectedStage);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            heroes.Changed -= Render;
            formation.Changed -= Render;
            list.Dispose();
        }

        private void ShowChapterList()
        {
            showDetail = false;
            showChapters = true;
            Render();
        }

        private void CloseDetail()
        {
            showDetail = false;
            showChapters = false;
            Render();
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
                    requestChapter(entry.Id);
                }
                else
                {
                    requestStage(entry.Id);
                    showDetail = true;
                    Render();
                }
            });
        }

        private void RenderDetail(WorldStageRecord stage)
        {
            if (stage == null) return;
            SetText(detailView, "Layer/Panel_1/Pane/Panel_left/TextPanel/Text_num", stage.Name);
            for (int index = 1; index <= 3; index++)
                SetActive(detailView, $"Layer/Panel_1/Pane/Panel_left/StarList/Star{index}/Star", stage.Stars >= index);
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_4/TimesBg/Icon/Num", stage.RemainingAttempts.ToString());
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_1/Tili/Value", stage.SpiritCost.ToString());
            SetText(detailView, $"{DetailRoot}/Image_bg/Panel_1/Desc/Desc_0", FormationSummary());
            GameObject challengeButton = Require(detailView, $"{DetailRoot}/Image_bg/Panel_4/Button_2");
            Button challengeComponent = challengeButton.GetComponent<Button>();
            if (challengeComponent != null) challengeComponent.interactable = stage.IsUnlocked && stage.RemainingAttempts > 0;

            RenderedRewardCount = Math.Min(4, stage.Rewards.Count);
            for (int index = 0; index < 4; index++)
            {
                string root = $"{DetailRoot}/Image_bg/Panel_2/GoldIcon{index + 1}";
                bool active = index < stage.Rewards.Count;
                SetActive(detailView, root, active);
                if (!active) continue;
                RewardRecord reward = stage.Rewards[index];
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
            view.GameObject.transform.SetParent(parent, false);
            view.GameObject.SetActive(active);
        }

        private static void Bind(CocosUiView view, string path, Action action)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

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
