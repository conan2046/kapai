using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.Core;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class XunBaoPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly XunBaoStore store;
        private readonly BagStore bag;
        private readonly EquipmentCatalog catalog;
        private readonly Text remaining;
        private readonly Text recovery;
        private readonly Text name;
        private readonly ResourceService resources;
        private readonly Image treasureIcon;
        private readonly Text runtimeDescription;
        private readonly CocosTimelinePlayer timeline;
        private readonly List<GameObject> treasureCards = new List<GameObject>();
        private List<FaBaoSearchDefinition> searches = new List<FaBaoSearchDefinition>();
        private readonly Action<ushort, ushort> search;
        private readonly Action<ushort> searchAll;
        private readonly Action<ushort> compose;
        private readonly Action composeAll;
        private readonly Action addTimes;
        private readonly Action help;
        private readonly Action staminaAdd;
        private readonly Action goldAdd;
        private readonly Action taskEntry;
        private readonly Action<string> notify;
        private int selected;

        public XunBaoPresenter(CocosUiView view, XunBaoStore store, BagStore bag,
            ResourceService resources, EquipmentCatalog catalog, Action close,
            Action<ushort, ushort> search, Action<ushort> searchAll,
            Action<ushort> compose, Action composeAll, Action addTimes, Action help,
            Action staminaAdd, Action goldAdd, Action taskEntry, Action<string> notify)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.search = search ?? throw new ArgumentNullException(nameof(search));
            this.searchAll = searchAll ?? throw new ArgumentNullException(nameof(searchAll));
            this.compose = compose ?? throw new ArgumentNullException(nameof(compose));
            this.composeAll = composeAll ?? throw new ArgumentNullException(nameof(composeAll));
            this.addTimes = addTimes ?? throw new ArgumentNullException(nameof(addTimes));
            this.help = help ?? throw new ArgumentNullException(nameof(help));
            this.staminaAdd = staminaAdd ?? throw new ArgumentNullException(nameof(staminaAdd));
            this.goldAdd = goldAdd ?? throw new ArgumentNullException(nameof(goldAdd));
            this.taskEntry = taskEntry ?? throw new ArgumentNullException(nameof(taskEntry));
            this.notify = notify ?? throw new ArgumentNullException(nameof(notify));
            Transform root = view.GameObject.transform;
            timeline = view.GameObject.GetComponent<CocosTimelinePlayer>();
            if (timeline != null) timeline.AnimationCompleted += HandleAnimationCompleted;
            Normalize(root);
            SetVisible(root.Find("Panel"), true);
            SetVisible(root.Find("Xunbao"), true);
            SetVisible(root.Find("Xunbao/Red"), false);
            SetVisible(root.Find("Xunbao/Orange"), false);
            SetVisible(root.Find("Xunbao/Purple"), false);
            SetVisible(root.Find("Xunbao/Blue"), true);
            SetVisible(root.Find("Panel/DescBg/Bg/jichushuxing"), true);
            SetVisible(root.Find("Panel/DescBg/Bg/qianghuashuxing"), true);
            SetVisible(root.Find("Panel/DescBg/Bg/jinglianshuxing"), true);
            SetVisible(root.Find("Panel/DescBg/Bg/zhuangbeimiaoshu"), true);
            remaining = RequireText(root, "Panel/XunbaoBg/TimesBg/Icon/Num");
            recovery = RequireText(root, "Panel/XunbaoBg/TimesBg/Tips");
            name = root.Find("Panel/DescBg/Bg/Namebg/Name")?.GetComponent<Text>();
            treasureIcon = root.Find("Xunbao/Red/Icon")?.GetComponent<Image>();
            runtimeDescription = BuildDescription(root);
            RefreshSearchDefinitions();
            BuildTreasureStrip(root);
            BindClose(root, close);
            BindActions(root);
            store.Changed += Render;
            bag.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null && recovery != null;
        public int ActionBindingCount { get; private set; }
        public int VisibleTreasureCount => searches.Count;
        public int SelectedFaBaoId => CurrentSearch()?.FaBaoId ?? 0;
        public string CurrentAnimationClip => timeline?.CurrentClip ?? string.Empty;
        public bool IsAnimationPlaying => timeline?.IsPlaying == true;
        public string RemainingText => remaining?.text ?? string.Empty;
        public string RecoveryText => recovery?.text ?? string.Empty;
        public int VisibleQualityPanelCount => new[] { "Red", "Orange", "Purple", "Blue" }
            .Count(value => view.GameObject.transform.Find($"Xunbao/{value}")?.gameObject.activeInHierarchy == true);
        public Button GetButton(string path) => view.GameObject.transform.Find(path)?.GetComponent<Button>();
        public Button GetTreasureCardButton(int index)
        {
            if (index < 0 || index >= treasureCards.Count || treasureCards[index] == null) return null;
            return treasureCards[index].GetComponent<Button>();
        }
        public Button GetTreasureCardButtonByFaBaoId(int faBaoId)
        {
            for (int index = 0; index < searches.Count && index < treasureCards.Count; index++)
                if (searches[index].FaBaoId == faBaoId)
                    return treasureCards[index]?.GetComponent<Button>();
            return null;
        }
        public Button GetFragmentButton(int slot)
        {
            if (slot < 1 || slot > 8) return null;
            string quality = QualityPanelName(CurrentDefinition()?.Quality ?? 3);
            return GetButton($"Xunbao/{quality}/Image/Add{slot}");
        }
        public Button OneKeySearchButton => GetButton("Xunbao/Btn_1");
        public Button ComposeButton => GetButton("Xunbao/Btn_2");
        public Button ComposeAllButton => GetButton("Xunbao/Btn_3");
        public bool IsButtonDisabled(string path)
        {
            Button button = GetButton(path);
            return button == null || !button.gameObject.activeInHierarchy || !button.interactable;
        }
        public void Dispose()
        {
            store.Changed -= Render;
            bag.Changed -= Render;
            if (timeline != null) timeline.AnimationCompleted -= HandleAnimationCompleted;
        }

        private void Render()
        {
            Button premiumButton = GetButton("Panel/GoldCheck/GoldIcon4/AddBtn");
            if (premiumButton != null)
            {
                premiumButton.interactable = false;
                premiumButton.gameObject.SetActive(false);
            }
            if (RefreshSearchDefinitions()) BuildTreasureStrip(view.GameObject.transform);
            if (!store.HasAuthoritativeResponse)
            {
                remaining.text = "--";
                recovery.text = "正在读取搜索次数";
                return;
            }
            remaining.text = store.Remaining.ToString();
            recovery.text = store.RecoverySeconds > 0 ? $"恢复倒计时：{FormatTime(store.RecoverySeconds)}" : "搜索次数已满";
            EquipmentDefinition definition = CurrentDefinition();
            if (definition == null) return;
            if (name != null) name.text = definition.Name ?? $"法宝 #{definition.Id}";
            if (treasureIcon != null)
            {
                treasureIcon.sprite = resources.LoadFaBaoIcon(definition.Picture, out _);
                treasureIcon.preserveAspect = true;
                treasureIcon.color = Color.white;
            }
            int quality = Mathf.Clamp(definition.Quality, 3, 6);
            foreach (string panelName in new[] { "Red", "Orange", "Purple", "Blue" })
            {
                SetVisible(view.GameObject.transform.Find($"Xunbao/{panelName}"),
                    panelName == QualityPanelName(quality));
                Image qualityIcon = view.GameObject.transform.Find($"Xunbao/{panelName}/Icon")?.GetComponent<Image>();
                if (qualityIcon == null) continue;
                qualityIcon.sprite = resources.LoadFaBaoIcon(definition.Picture, out _);
                qualityIcon.preserveAspect = true;
                qualityIcon.color = Color.white;
            }
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/jichushuxing/Atrribute_1/Value", FormatAttribute(definition.BaseAttribute));
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/qianghuashuxing/Atrribute_1/Value", FormatAttribute(definition.GetPrimaryStrengthAttribute()));
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/jinglianshuxing/Atrribute_1/Value", FormatAttributes(definition.RefineAttributes));
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/zhuangbeimiaoshu/Content", definition.Description ?? string.Empty);
            if (runtimeDescription != null)
                runtimeDescription.text = $"基础属性\n{FormatAttribute(definition.BaseAttribute)}\n\n每级强化\n{FormatAttribute(definition.GetPrimaryStrengthAttribute())}\n\n每级精炼\n{FormatAttributes(definition.RefineAttributes)}\n\n装备描述\n{definition.Description ?? string.Empty}";
            RenderFragmentCounts();
            Button composeAllButton = GetButton("Xunbao/Btn_3");
            if (composeAllButton != null)
                composeAllButton.gameObject.SetActive(CountComposable() > 1);
            for (int index = 0; index < treasureCards.Count; index++)
            {
                Image cardIcon = treasureCards[index]?.transform.Find("Big/Icon")?.GetComponent<Image>();
                if (cardIcon != null)
                    cardIcon.color = index == selected ? Color.white : new Color(.58f, .58f, .58f, 1f);
            }
        }

        private static string FormatTime(uint seconds) => $"{seconds / 3600:00}:{seconds % 3600 / 60:00}:{seconds % 60:00}";

        private FaBaoSearchDefinition CurrentSearch()
            => searches.Count == 0 || selected < 0 || selected >= searches.Count ? null : searches[selected];

        private EquipmentDefinition CurrentDefinition()
        {
            FaBaoSearchDefinition searchDefinition = CurrentSearch();
            return searchDefinition == null ? null : catalog.GetFaBao(searchDefinition.FaBaoId);
        }

        private bool RefreshSearchDefinitions()
        {
            IReadOnlyList<FaBaoSearchDefinition> configured = catalog.GetFaBaoSearches();
            List<FaBaoSearchDefinition> next = new List<FaBaoSearchDefinition>();
            foreach (FaBaoSearchDefinition candidate in configured)
            {
                EquipmentDefinition definition = catalog.GetFaBao(candidate.FaBaoId);
                bool visible = definition.Quality == 3 && candidate.FaBaoId != 615;
                if (!visible && candidate.FragmentIds != null)
                    foreach (int fragmentId in candidate.FragmentIds)
                        if (bag.GetTotalQuantityByItemId(fragmentId) > 0) { visible = true; break; }
                if (visible) next.Add(candidate);
            }
            if (next.Count == 0 && configured.Count > 0) next.Add(configured[0]);
            bool changed = next.Count != searches.Count;
            if (!changed)
                for (int i = 0; i < next.Count; i++)
                    if (next[i].FaBaoId != searches[i].FaBaoId) { changed = true; break; }
            searches = next;
            if (selected >= searches.Count) selected = Math.Max(0, searches.Count - 1);
            return changed;
        }

        private static string QualityPanelName(int quality)
            => quality >= 6 ? "Red" : quality == 5 ? "Orange" : quality == 4 ? "Purple" : "Blue";

        private static string FormatAttribute(int[] value)
            => value == null || value.Length < 2 ? string.Empty : $"{AttributeName(value[0])}：+{value[1]}";

        private static string AttributeName(int type)
        {
            string[] names = { "", "攻击", "物防", "法防", "生命", "速度", "命中", "闪避", "暴击", "抗暴", "攻击加成", "物防加成", "法防加成", "生命加成", "速度加成", "命中率", "闪避率", "暴击率", "抗暴率", "增伤率", "物免率", "法免率" };
            return type > 0 && type < names.Length && !string.IsNullOrEmpty(names[type]) ? names[type] : $"属性{type}";
        }

        private static string FormatAttributes(int[][] values)
        {
            if (values == null || values.Length == 0) return string.Empty;
            List<string> lines = new List<string>();
            foreach (int[] value in values)
                if (value != null && value.Length >= 2) lines.Add($"{AttributeName(value[0])}：+{value[1]}");
            return string.Join("\n", lines);
        }

        private static void BindClose(Transform root, Action close)
        {
            Button button = root.Find("Panel/Title/CloseBtn")?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => close?.Invoke());
        }

        private void BindActions(Transform root)
        {
            BindAction(root, "Xunbao/Btn_1", () =>
            {
                if (timeline?.IsPlaying == true) return;
                if (store.Remaining == 0)
                {
                    store.SetOperationResult(false, "搜索次数不足，请使用搜宝令补充");
                    addTimes();
                    return;
                }
                store.SetOperationResult(false, "正在一键寻宝…");
                FaBaoSearchDefinition current = CurrentSearch();
                if (current != null) searchAll(checked((ushort)current.FaBaoId));
            });
            BindAction(root, "Xunbao/Btn_2", () =>
            {
                if (timeline?.IsPlaying == true) return;
                if (!CanComposeSelected())
                {
                    store.SetOperationResult(false, "法宝碎片不足，无法合成");
                    notify("法宝碎片不足，无法合成");
                    return;
                }
                store.SetOperationResult(false, "正在合成法宝…");
                FaBaoSearchDefinition current = CurrentSearch();
                if (current != null) compose(checked((ushort)current.FaBaoId));
            });
            BindAction(root, "Xunbao/Btn_3", () =>
            {
                if (timeline?.IsPlaying == true) return;
                if (!CanComposeAny())
                {
                    store.SetOperationResult(false, "法宝碎片不足，无法一键合成");
                    notify("法宝碎片不足，无法一键合成");
                    return;
                }
                store.SetOperationResult(false, "正在一键合成…");
                composeAll();
            });
            BindAction(root, "Panel/XunbaoBg/TimesBg/AddBtn", addTimes);
            BindAction(root, "Panel/XunbaoBg/Btn_1", taskEntry);
            BindAction(root, "Panel/Title/TitleName/btn_help", help);
            BindAction(root, "Panel/GoldCheck/GoldIcon1/AddBtn", staminaAdd);
            BindAction(root, "Panel/GoldCheck/GoldIcon3/AddBtn", goldAdd);
            // The source UI keeps the premium-currency add button hidden/disabled. Preserve that boundary.
            Button premiumButton = root.Find("Panel/GoldCheck/GoldIcon4/AddBtn")?.GetComponent<Button>();
            if (premiumButton != null && premiumButton.gameObject.activeInHierarchy)
            {
                premiumButton.onClick.RemoveAllListeners();
                premiumButton.interactable = false;
                premiumButton.gameObject.SetActive(false);
            }
            foreach (string quality in new[] { "Red", "Orange", "Purple", "Blue" })
            for (int index = 1; index <= 8; index++)
            {
                int fragmentOffset = index - 1;
                BindAction(root, $"Xunbao/{quality}/Image/Add{index}", () =>
                {
                    if (timeline?.IsPlaying == true) return;
                    if (store.Remaining == 0)
                    {
                        store.SetOperationResult(false, "搜索次数不足，请使用搜宝令补充");
                        addTimes();
                        return;
                    }
                    FaBaoSearchDefinition current = CurrentSearch();
                    if (current == null || current.FragmentIds == null || fragmentOffset >= current.FragmentIds.Length) return;
                    int required = current.FragmentCosts != null && fragmentOffset < current.FragmentCosts.Length
                        ? current.FragmentCosts[fragmentOffset] : 1;
                    int fragmentId = current.FragmentIds[fragmentOffset];
                    // Formal Cocos SeekCallBack returns when value.sign == 0: a completed
                    // fragment must not emit op28, because the server intentionally has no
                    // response payload for that invalid repeat request.
                    if (bag.GetTotalQuantityByItemId(fragmentId) >= required) return;
                    search(checked((ushort)current.FaBaoId), checked((ushort)fragmentId));
                });
            }
        }

        private void RenderFragmentCounts()
        {
            Transform root = view.GameObject.transform;
            string[] qualities = { "Red", "Orange", "Purple", "Blue" };
            FaBaoSearchDefinition current = CurrentSearch();
            EquipmentDefinition definition = CurrentDefinition();
            string selectedQuality = definition == null ? "Blue" : QualityPanelName(definition.Quality);
            for (int slot = 1; slot <= 8; slot++)
            {
                bool hasFragment = current != null && current.FragmentIds != null && slot <= current.FragmentIds.Length;
                int fragmentId = hasFragment ? current.FragmentIds[slot - 1] : 0;
                int quantity = hasFragment ? bag.GetTotalQuantityByItemId(fragmentId) : 0;
                foreach (string quality in qualities)
                {
                    Transform add = root.Find($"Xunbao/{quality}/Image/Add{slot}");
                    if (add != null) add.gameObject.SetActive(quality == selectedQuality && hasFragment);
                    if (add == null || quality != selectedQuality || !hasFragment) continue;
                    int cost = current.FragmentCosts != null && slot <= current.FragmentCosts.Length
                        ? current.FragmentCosts[slot - 1] : 1;
                    bool complete = quantity >= cost;
                    Text count = add.Find("Num")?.GetComponent<Text>();
                    if (count != null) count.text = quantity > 0 ? quantity.ToString() : string.Empty;
                    Image itemIcon = add.Find("Icon_0")?.GetComponent<Image>();
                    EquipmentMaterialDefinition item = catalog.GetItem(fragmentId);
                    if (itemIcon != null)
                    {
                        Sprite sprite = item == null ? null : resources.LoadItemIcon(item.Picture);
                        if (sprite != null) itemIcon.sprite = sprite;
                        itemIcon.preserveAspect = true;
                        itemIcon.color = complete ? Color.white : new Color(0.498f, 0.498f, 0.498f, 1f);
                    }
                    SetVisible(add.Find("Icon"), !complete);
                    SetVisible(add.Find("Particle"), complete);
                }
            }
        }

        private bool CanComposeSelected()
        {
            FaBaoSearchDefinition current = CurrentSearch();
            if (current == null || current.FragmentIds == null || current.FragmentCosts == null
                || current.FragmentIds.Length != current.FragmentCosts.Length) return false;
            for (int i = 0; i < current.FragmentIds.Length; i++)
                if (bag.GetTotalQuantityByItemId(current.FragmentIds[i]) < current.FragmentCosts[i]) return false;
            return current.FragmentIds.Length > 0;
        }

        private bool CanComposeAny()
        {
            int original = selected;
            bool canCompose = false;
            for (int i = 0; i < searches.Count; i++)
            {
                selected = i;
                if (CanComposeSelected()) { canCompose = true; break; }
            }
            selected = Mathf.Clamp(original, 0, Math.Max(0, searches.Count - 1));
            return canCompose;
        }

        private int CountComposable()
        {
            int original = selected;
            int count = 0;
            for (int i = 0; i < searches.Count; i++)
            {
                selected = i;
                if (CanComposeSelected()) count++;
            }
            selected = Mathf.Clamp(original, 0, Math.Max(0, searches.Count - 1));
            return count;
        }

        private void BindAction(Transform root, string path, Action action)
        {
            if (Bind(root, path, action)) ActionBindingCount++;
        }

        public bool PlayComposeFeedback()
        {
            EquipmentDefinition definition = CurrentDefinition();
            if (definition == null || timeline == null) return false;
            SetFragmentParticles(true);
            return timeline.TryPlay(QualityPanelName(definition.Quality) + "Compose", false);
        }

        private void HandleAnimationCompleted(string clip)
        {
            if (!string.IsNullOrEmpty(clip) && clip.EndsWith("Compose", StringComparison.Ordinal))
                Render();
        }

        private void SetFragmentParticles(bool visible)
        {
            string quality = QualityPanelName(CurrentDefinition()?.Quality ?? 3);
            FaBaoSearchDefinition current = CurrentSearch();
            int count = current?.FragmentIds?.Length ?? 0;
            for (int slot = 1; slot <= count; slot++)
                SetVisible(view.GameObject.transform.Find($"Xunbao/{quality}/Image/Add{slot}/Particle"), visible);
        }

        private void PlayOpenFeedback()
        {
            EquipmentDefinition definition = CurrentDefinition();
            if (definition != null && timeline != null)
                timeline.TryPlay(QualityPanelName(definition.Quality) + "Open", false);
        }

        private void BuildTreasureStrip(Transform root)
        {
            Transform list = root.Find("Xunbao/Panel/List");
            Transform template = root.Find("Xunbao/Panel/Item");
            if (list == null || template == null) return;
            Transform old = list.Find("RuntimeTreasures");
            if (old != null)
            {
                old.gameObject.SetActive(false);
                old.name = "RuntimeTreasures_Stale";
                UnityEngine.Object.Destroy(old.gameObject);
            }
            treasureCards.Clear();
            template.gameObject.SetActive(false);
            GameObject host = new GameObject("RuntimeTreasures", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(ContentSizeFitter));
            RectTransform hostRect = host.GetComponent<RectTransform>();
            hostRect.SetParent(list, false); hostRect.anchorMin = new Vector2(0f, .5f); hostRect.anchorMax = new Vector2(0f, .5f);
            hostRect.pivot = new Vector2(0f, .5f); hostRect.anchoredPosition = Vector2.zero;
            HorizontalLayoutGroup layout = host.GetComponent<HorizontalLayoutGroup>();
            layout.spacing = 18f; layout.childAlignment = TextAnchor.MiddleLeft; layout.childControlWidth = false; layout.childControlHeight = false;
            layout.childForceExpandWidth = false; layout.childForceExpandHeight = false;
            host.GetComponent<ContentSizeFitter>().horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            for (int i = 0; i < searches.Count; i++)
            {
                int index = i;
                EquipmentDefinition definition = catalog.GetFaBao(searches[i].FaBaoId);
                GameObject card = UnityEngine.Object.Instantiate(template.gameObject, hostRect, false);
                card.name = $"Treasure_{i + 1}"; card.SetActive(true);
                treasureCards.Add(card);
                Image icon = card.transform.Find("Big/Icon")?.GetComponent<Image>();
                if (icon != null) { icon.sprite = resources.LoadFaBaoIcon(definition.Picture, out _); icon.preserveAspect = true; icon.color = Color.white; }
                SetText(card.transform, "Big/Name", definition.Name ?? $"法宝 #{definition.Id}");
                Button cardButton = card.GetComponent<Button>() ?? card.AddComponent<Button>();
                Graphic cardGraphic = card.transform.Find("Big")?.GetComponent<Graphic>()
                    ?? card.GetComponentInChildren<Graphic>(true);
                if (cardGraphic == null)
                    throw new InvalidOperationException("XunBao treasure Item has no visible Graphic raycast target.");
                cardGraphic.raycastTarget = true;
                cardButton.targetGraphic = cardGraphic;
                cardButton.onClick.RemoveAllListeners();
                cardButton.interactable = true;
                cardButton.onClick.AddListener(() =>
                {
                    if (timeline?.IsPlaying == true || selected == index) return;
                    selected = index;
                    Render();
                    PlayOpenFeedback();
                });
            }
        }

        private Text BuildDescription(Transform root)
        {
            Transform panel = root.Find("Panel/DescBg");
            if (panel == null) return null;
            Transform existing = panel.Find("RuntimeDescription");
            if (existing != null) return existing.GetComponent<Text>();
            GameObject go = new GameObject("RuntimeDescription", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>(); rect.SetParent(panel, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f); rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(39f, -170f); rect.sizeDelta = new Vector2(300f, 340f);
            Text text = go.GetComponent<Text>(); text.font = name != null ? name.font : Resources.GetBuiltinResource<Font>("Arial.ttf");
            text.fontSize = 18; text.color = new Color(.96f, .93f, .9f, 1f); text.alignment = TextAnchor.UpperLeft;
            text.horizontalOverflow = HorizontalWrapMode.Wrap; text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        private static bool Bind(Transform root, string path, Action action)
        {
            Button button = root.Find(path)?.GetComponent<Button>();
            if (button == null) return false;
            button.onClick.RemoveAllListeners();
            button.interactable = true;
            button.onClick.AddListener(() => action());
            return true;
        }

        private static Text RequireText(Transform root, string path) => root.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"XunBao imported text was not found: {path}");
        private static void SetText(Transform root, string path, string value) { Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value; }
        private static void SetVisible(Transform target, bool visible) { if (target != null) target.gameObject.SetActive(visible); }
        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero; rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity;
        }
    }
}
