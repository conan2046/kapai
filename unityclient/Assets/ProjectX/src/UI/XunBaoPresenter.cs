using System;
using System.Collections.Generic;
using ProjectX.Data;
using ProjectX.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class XunBaoPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly XunBaoStore store;
        private readonly BagStore bag;
        private readonly Text remaining;
        private readonly Text recovery;
        private readonly Text name;
        private readonly ResourceService resources;
        private readonly Image treasureIcon;
        private readonly Text runtimeDescription;
        private readonly List<GameObject> treasureCards = new List<GameObject>();
        private readonly Action<ushort, ushort> search;
        private readonly Action<ushort, byte> searchAll;
        private readonly Action<ushort> compose;
        private readonly Action composeAll;
        private readonly Action addTimes;
        private int selected;
        private static readonly ushort[] Treasures = { 1001, 1002, 1003 };
        private static readonly string[] Names = { "散瘟鞭", "捆龙索", "混元伞" };
        private static readonly string[] Pictures = { "1002", "1003", "1001" };
        private static readonly string[] Descriptions = { "一种被施过妖法的长鞭，使人混乱，无法战斗。", "自动捆绑敌人。", "伞皆明珠穿成，撑开时天昏地暗。" };

        public XunBaoPresenter(CocosUiView view, XunBaoStore store, BagStore bag,
            ResourceService resources, Action close,
            Action<ushort, ushort> search, Action<ushort, byte> searchAll,
            Action<ushort> compose, Action composeAll, Action addTimes)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.search = search ?? throw new ArgumentNullException(nameof(search));
            this.searchAll = searchAll ?? throw new ArgumentNullException(nameof(searchAll));
            this.compose = compose ?? throw new ArgumentNullException(nameof(compose));
            this.composeAll = composeAll ?? throw new ArgumentNullException(nameof(composeAll));
            this.addTimes = addTimes ?? throw new ArgumentNullException(nameof(addTimes));
            Transform root = view.GameObject.transform;
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
            BuildTreasureStrip(root);
            BindClose(root, close);
            BindActions(root);
            store.Changed += Render;
            bag.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null && recovery != null;
        public int ActionBindingCount { get; private set; }
        public void Dispose()
        {
            store.Changed -= Render;
            bag.Changed -= Render;
        }

        private void Render()
        {
            if (!store.HasAuthoritativeResponse)
            {
                remaining.text = "--";
                recovery.text = "正在读取搜索次数";
                return;
            }
            remaining.text = store.Remaining.ToString();
            recovery.text = store.RecoverySeconds > 0 ? $"恢复倒计时：{FormatTime(store.RecoverySeconds)}" : "搜索次数已满";
            if (name != null) name.text = Names[selected];
            if (treasureIcon != null)
            {
                treasureIcon.sprite = resources.LoadFaBaoIcon(Pictures[selected], out _);
                treasureIcon.preserveAspect = true;
                treasureIcon.color = Color.white;
            }
            foreach (string quality in new[] { "Red", "Orange", "Purple", "Blue" })
            {
                Image qualityIcon = view.GameObject.transform.Find($"Xunbao/{quality}/Icon")?.GetComponent<Image>();
                if (qualityIcon == null) continue;
                qualityIcon.sprite = resources.LoadFaBaoIcon(Pictures[selected], out _);
                qualityIcon.preserveAspect = true;
                qualityIcon.color = Color.white;
            }
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/jichushuxing/Atrribute_1/Value", selected == 0 ? "+400" : "+1200");
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/qianghuashuxing/Atrribute_1/Value", selected == 0 ? "+40" : "+120");
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/jinglianshuxing/Atrribute_1/Value", selected == 0 ? "+80\n+20" : "+240\n+60");
            SetText(view.GameObject.transform, "Panel/DescBg/Bg/zhuangbeimiaoshu/Content", Descriptions[selected]);
            if (runtimeDescription != null)
                runtimeDescription.text = $"基础属性\n攻击：  {(selected == 0 ? "+400" : "+1200")}\n\n每级强化\n攻击：  {(selected == 0 ? "+40" : "+120")}\n\n每级精炼\n攻击：  {(selected == 0 ? "+80" : "+240")}\n命中：  {(selected == 0 ? "+20" : "+60")}\n\n装备描述\n{Descriptions[selected]}";
            if (!string.IsNullOrWhiteSpace(store.LastMessage)) recovery.text = store.LastMessage;
            RenderFragmentCounts();
            for (int index = 0; index < treasureCards.Count; index++)
            {
                Image cardIcon = treasureCards[index]?.transform.Find("Big/Icon")?.GetComponent<Image>();
                if (cardIcon != null)
                    cardIcon.color = index == selected ? Color.white : new Color(.58f, .58f, .58f, 1f);
            }
        }

        private static string FormatTime(uint seconds) => $"{seconds / 3600:00}:{seconds % 3600 / 60:00}:{seconds % 60:00}";

        private static void BindClose(Transform root, Action close)
        {
            Button button = root.Find("Panel/Title/CloseBtn")?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => close?.Invoke());
        }

        private void BindActions(Transform root)
        {
            BindActionWithHitTarget(root, "Xunbao/Btn_1", () =>
            {
                if (store.Remaining == 0)
                {
                    store.SetOperationResult(false, "搜索次数不足，请使用搜宝令补充");
                    addTimes();
                    return;
                }
                store.SetOperationResult(false, "正在一键寻宝…");
                searchAll(Treasures[selected], 0);
            });
            BindActionWithHitTarget(root, "Xunbao/Btn_2", () =>
            {
                if (!CanComposeSelected())
                {
                    store.SetOperationResult(false, "法宝碎片不足，无法合成");
                    return;
                }
                store.SetOperationResult(false, "正在合成法宝…");
                compose(Treasures[selected]);
            });
            BindActionWithHitTarget(root, "Xunbao/Btn_3", () =>
            {
                store.SetOperationResult(false, "正在一键合成…");
                composeAll();
            });
            BindAction(root, "Xunbao/Panel/Button_L", () => Select(-1));
            BindAction(root, "Xunbao/Panel/Button_R", () => Select(1));
            BindAction(root, "Panel/XunbaoBg/TimesBg/AddBtn", addTimes);
            BindAction(root, "Panel/XunbaoBg/Btn_1", () => store.SetOperationResult(true, "搜索奖励任务入口已开放"));
            foreach (string quality in new[] { "Red", "Orange", "Purple", "Blue" })
            for (int index = 1; index <= 8; index++)
            {
                int fragmentOffset = index - 1;
                BindAction(root, $"Xunbao/{quality}/Image/Add{index}", () =>
                {
                    if (store.Remaining == 0)
                    {
                        store.SetOperationResult(false, "搜索次数不足，请使用搜宝令补充");
                        addTimes();
                        return;
                    }
                    search(Treasures[selected], checked((ushort)(4701 + selected * 3 + fragmentOffset % 3)));
                });
            }
        }

        private void RenderFragmentCounts()
        {
            Transform root = view.GameObject.transform;
            string[] qualities = { "Red", "Orange", "Purple", "Blue" };
            for (int slot = 1; slot <= 8; slot++)
            {
                int fragmentId = 4701 + selected * 3 + (slot - 1) % 3;
                int quantity = bag.GetTotalQuantityByItemId(fragmentId);
                foreach (string quality in qualities)
                {
                    Transform add = root.Find($"Xunbao/{quality}/Image/Add{slot}");
                    if (quality == "Blue" && add != null) add.gameObject.SetActive(slot <= 3);
                    Text count = add?.Find("Num")?.GetComponent<Text>();
                    if (count != null) count.text = quantity.ToString();
                }
            }
        }

        private bool CanComposeSelected()
        {
            int firstFragmentId = 4701 + selected * 3;
            return bag.GetTotalQuantityByItemId(firstFragmentId) > 0
                && bag.GetTotalQuantityByItemId(firstFragmentId + 1) > 0
                && bag.GetTotalQuantityByItemId(firstFragmentId + 2) > 0;
        }

        private void BindAction(Transform root, string path, Action action)
        {
            if (Bind(root, path, action)) ActionBindingCount++;
        }

        private void BindActionWithHitTarget(Transform root, string path, Action action)
        {
            Transform target = root.Find(path);
            if (target == null) return;
            BindAction(root, path, action);
            Transform existing = target.Find("RuntimeActionHit");
            if (existing != null) UnityEngine.Object.Destroy(existing.gameObject);
            GameObject hit = new GameObject("RuntimeActionHit", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image), typeof(Button));
            RectTransform rect = hit.GetComponent<RectTransform>();
            rect.SetParent(target, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image image = hit.GetComponent<Image>();
            image.color = new Color(1f, 1f, 1f, .01f);
            Button button = hit.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(() => action());
            hit.transform.SetAsLastSibling();
        }

        private void Select(int delta)
        {
            selected = (selected + delta + Treasures.Length) % Treasures.Length;
            Render();
        }

        private void BuildTreasureStrip(Transform root)
        {
            Transform list = root.Find("Xunbao/Panel/List");
            Transform template = root.Find("Xunbao/Panel/Item");
            if (list == null || template == null || list.Find("RuntimeTreasures") != null) return;
            template.gameObject.SetActive(false);
            GameObject host = new GameObject("RuntimeTreasures", typeof(RectTransform), typeof(HorizontalLayoutGroup), typeof(ContentSizeFitter));
            RectTransform hostRect = host.GetComponent<RectTransform>();
            hostRect.SetParent(list, false); hostRect.anchorMin = new Vector2(0f, .5f); hostRect.anchorMax = new Vector2(0f, .5f);
            hostRect.pivot = new Vector2(0f, .5f); hostRect.anchoredPosition = Vector2.zero;
            HorizontalLayoutGroup layout = host.GetComponent<HorizontalLayoutGroup>();
            layout.spacing = 18f; layout.childAlignment = TextAnchor.MiddleLeft; layout.childControlWidth = false; layout.childControlHeight = false;
            layout.childForceExpandWidth = false; layout.childForceExpandHeight = false;
            host.GetComponent<ContentSizeFitter>().horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            for (int i = 0; i < 3; i++)
            {
                int index = i;
                GameObject card = UnityEngine.Object.Instantiate(template.gameObject, hostRect, false);
                card.name = $"Treasure_{i + 1}"; card.SetActive(true);
                treasureCards.Add(card);
                Image icon = card.transform.Find("Big/Icon")?.GetComponent<Image>();
                if (icon != null) { icon.sprite = resources.LoadFaBaoIcon(Pictures[i], out _); icon.preserveAspect = true; icon.color = Color.white; }
                SetText(card.transform, "Big/Name", Names[i]);
                Bind(card.transform, "Big", () => { selected = index; Render(); });
                GameObject hit = new GameObject("RuntimeSelectHit", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image), typeof(Button));
                RectTransform hitRect = hit.GetComponent<RectTransform>();
                hitRect.SetParent(card.transform, false);
                hitRect.anchorMin = Vector2.zero; hitRect.anchorMax = Vector2.one;
                hitRect.offsetMin = Vector2.zero; hitRect.offsetMax = Vector2.zero;
                Image hitImage = hit.GetComponent<Image>();
                hitImage.color = new Color(1f, 1f, 1f, .01f);
                Button hitButton = hit.GetComponent<Button>();
                hitButton.targetGraphic = hitImage;
                hitButton.onClick.AddListener(() => { selected = index; Render(); });
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
            rect.anchoredPosition = new Vector2(24f, -132f); rect.sizeDelta = new Vector2(300f, 340f);
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
