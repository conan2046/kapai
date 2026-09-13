using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class JingJieRenderBridge : IDisposable
    {
        private const string Root = "Layer/JingjieUI/Panel";
        private readonly CocosUiView view;
        private readonly CocosUiView preview;
        private readonly JingJieViewState state;
        private readonly JingJieConfigData config;
        private readonly PlayerStore player;
        private readonly CurrencyStore currencies;
        private readonly BagStore bag;
        private readonly Core.ResourceService resources;
        private readonly Action requestUpgrade;
        private readonly Action<JingJieDefinition> showMaterial;
        private readonly Action<string> feedback;
        private readonly List<GameObject> generatedRows = new List<GameObject>();
        private readonly List<GameObject> previewRows = new List<GameObject>();
        private readonly Color levelDefaultColor;
        private readonly Color powerDefaultColor;
        private readonly Color materialDefaultColor;
        private readonly Color goldDefaultColor;
        private readonly ImodAnimationPlayer effectPlayer;
        private readonly JingJieEffectLifetime effectLifetime;
        private JingJieDefinition nextDefinition;

        public JingJieRenderBridge(CocosUiView view, CocosUiView preview, JingJieViewState state,
            JingJieConfigData config, PlayerStore player, CurrencyStore currencies, BagStore bag,
            Core.ResourceService resources, Action requestUpgrade,
            Action<JingJieDefinition> showMaterial, Action<string> feedback)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.preview = preview ?? throw new ArgumentNullException(nameof(preview));
            this.state = state ?? throw new ArgumentNullException(nameof(state));
            this.config = config ?? throw new ArgumentNullException(nameof(config));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.requestUpgrade = requestUpgrade ?? throw new ArgumentNullException(nameof(requestUpgrade));
            this.showMaterial = showMaterial ?? throw new ArgumentNullException(nameof(showMaterial));
            this.feedback = feedback ?? (_ => { });

            Button leftHelp = RequireButton(view, Root + "/Panel_L/title_bg/Btn_xiangxi");
            Button endHelp = RequireButton(view, Root + "/Panel_End/title_bg/Btn_xiangxi");
            Button upgrade = RequireButton(view, Root + "/Panel_tupo/Button");
            Button material = RequireButton(view, Root + "/Panel_tupo/bg_cost/btn_Material");
            leftHelp.onClick.RemoveAllListeners();
            endHelp.onClick.RemoveAllListeners();
            upgrade.onClick.RemoveAllListeners();
            material.onClick.RemoveAllListeners();
            leftHelp.onClick.AddListener(ShowPreview);
            endHelp.onClick.AddListener(ShowPreview);
            upgrade.onClick.AddListener(() => this.requestUpgrade());
            material.onClick.AddListener(() => { if (nextDefinition != null) this.showMaterial(nextDefinition); });
            preview.BindClick("Layer/Popup/Btn_close", HidePreview, true);

            levelDefaultColor = RequireText(view, Root + "/Panel_tupo/bg_limit/Panel_level/Text/value").color;
            powerDefaultColor = RequireText(view, Root + "/Panel_tupo/bg_limit/Panel_zhanli/Text/value").color;
            materialDefaultColor = RequireText(view, Root + "/Panel_tupo/bg_cost/btn_Material/Value").color;
            goldDefaultColor = RequireText(view, Root + "/Panel_tupo/bg_cost/xiaohao/Num").color;

            GameObject effect = Require(view, Root + "/effect_jingjietupo_1");
            effect.SetActive(false);
            effectPlayer = effect.GetComponent<ImodAnimationPlayer>() ?? effect.AddComponent<ImodAnimationPlayer>();
            effectPlayer.SetPlayOnEnable(false);
            if (!effectPlayer.LoadLegacy("res2/animation/effect_jingjietupo_1"))
                throw new InvalidOperationException("JingJie breakthrough Imod resource is missing.");
            effectLifetime = effect.GetComponent<JingJieEffectLifetime>() ?? effect.AddComponent<JingJieEffectLifetime>();

            state.Changed += Render;
            player.Changed += Render;
            currencies.Changed += Render;
            bag.Changed += Render;
            RenderPreview();
            Render();
        }

        public bool IsVisible => view.GameObject.activeInHierarchy;
        public bool IsPreviewVisible => preview.GameObject.activeInHierarchy;
        public int CurrentId => state.CurrentId;
        public int PreviewRowCount => previewRows.Count;
        public bool HasNextDefinition => nextDefinition != null;
        public bool IsUpgradeEffectVisible => effectPlayer != null && effectPlayer.gameObject.activeInHierarchy;
        public Button PreviewControl => RequireButton(view, Root + "/Panel_L/title_bg/Btn_xiangxi");
        public Button PreviewCloseControl => RequireButton(preview, "Layer/Popup/Btn_close");
        public Button MaterialControl => RequireButton(view, Root + "/Panel_tupo/bg_cost/btn_Material");
        public Button UpgradeControl => RequireButton(view, Root + "/Panel_tupo/Button");

        public void Dispose()
        {
            state.Changed -= Render;
            player.Changed -= Render;
            currencies.Changed -= Render;
            bag.Changed -= Render;
            ClearRows(generatedRows);
            ClearRows(previewRows);
        }

        public void Show()
        {
            view.SetVisible(true);
            Render();
        }

        public void Hide()
        {
            HidePreview();
            view.SetVisible(false);
        }

        public void ShowPreview()
        {
            preview.SetVisible(true);
            preview.GameObject.transform.SetAsLastSibling();
        }

        public void HidePreview() => preview.SetVisible(false);

        public bool TryBeginUpgrade()
        {
            if (!state.HasAuthoritativeState)
            {
                feedback("境界数据同步中");
                return false;
            }
            if (!config.TryGet(state.CurrentId + 1, out JingJieDefinition target))
            {
                feedback("已达到最高境界");
                return false;
            }
            if (player.Level < target.LevelLimit)
            {
                feedback($"角色等级达到{target.LevelLimit}级后可突破");
                return false;
            }
            if (player.Power < (ulong)target.PowerLimit)
            {
                feedback($"战力达到{target.PowerLimit}后可突破");
                return false;
            }
            int owned = target.MaterialId > 0 ? bag.GetTotalQuantityByItemId(target.MaterialId) : 0;
            if (target.MaterialId > 0 && owned < target.MaterialAmount)
            {
                feedback("突破材料不足");
                return false;
            }
            if (currencies.Gold < target.GoldAmount)
            {
                feedback("金币不足");
                return false;
            }
            return state.BeginUpgrade();
        }

        private void Render()
        {
            if (view.GameObject == null) return;
            bool atMaximum = state.HasAuthoritativeState && state.CurrentId >= config.Count;
            SetActive(view, Root + "/Panel_L", !atMaximum);
            SetActive(view, Root + "/Panel_R", !atMaximum);
            SetActive(view, Root + "/Panel_End", atMaximum);
            SetActive(view, Root + "/Image_jiantou", !atMaximum);
            if (atMaximum)
            {
                RenderStage(Root + "/Panel_End", config.Get(config.Count), true);
                RenderBreakthrough(null);
            }
            else
            {
                bool empty = !state.HasAuthoritativeState || state.CurrentId == 0;
                SetActive(view, Root + "/Panel_L/Panel_0", empty);
                SetActive(view, Root + "/Panel_L/bg_L", !empty);
                SetActive(view, Root + "/Panel_L/Panel_shuxing", !empty);
                if (!empty) RenderStage(Root + "/Panel_L", config.Get(state.CurrentId), false);
                JingJieDefinition target = config.Get(Math.Max(1, state.CurrentId + 1));
                RenderStage(Root + "/Panel_R", target, false);
                RenderBreakthrough(target);
            }
            if (IsVisible && state.ConsumeUpgradeEffect()) PlayUpgradeEffect();
        }

        private void RenderStage(string panelPath, JingJieDefinition definition, bool endPanel)
        {
            string iconPath = panelPath + "/bg_L/Icon";
            Image icon = Require(view, iconPath).GetComponent<Image>();
            Sprite sprite = resources.LoadSprite("JingJieIcons/" + definition.Icon);
            icon.sprite = sprite;
            icon.enabled = sprite != null;
            icon.preserveAspect = true;
            Text name = RequireText(view, panelPath + "/bg_L/Panel_name/name");
            name.text = definition.Name;
            name.color = QualityColor(definition.Quality);
            Text title = RequireText(view, panelPath + "/Panel_shuxing/Text");
            title.text = definition.Name + "加成";
            string listPath = panelPath + "/Panel_shuxing/Attr_List";
            Transform list = Require(view, listPath).transform;
            Transform template = endPanel
                ? Require(view, listPath + "/Attribute1").transform
                : Require(view, panelPath + "/Panel_shuxing/Attribute1").transform;
            PopulateAttributes(list, template, definition.Attributes, generatedRows);
        }

        private void RenderBreakthrough(JingJieDefinition target)
        {
            nextDefinition = target;
            bool available = target != null;
            SetActive(view, Root + "/Panel_tupo/bg_limit", available);
            SetActive(view, Root + "/Panel_tupo/bg_cost", available);
            SetActive(view, Root + "/Panel_tupo/Button", available);
            SetActive(view, Root + "/Panel_tupo/Panel_end", !available);
            if (!available) return;

            Text level = RequireText(view, Root + "/Panel_tupo/bg_limit/Panel_level/Text/value");
            Text power = RequireText(view, Root + "/Panel_tupo/bg_limit/Panel_zhanli/Text/value");
            Text material = RequireText(view, Root + "/Panel_tupo/bg_cost/btn_Material/Value");
            Text gold = RequireText(view, Root + "/Panel_tupo/bg_cost/xiaohao/Num");
            bool hasMaterialCost = target.MaterialId > 0 && target.MaterialAmount > 0;
            int owned = hasMaterialCost ? bag.GetTotalQuantityByItemId(target.MaterialId) : 0;
            level.text = target.LevelLimit.ToString();
            power.text = target.PowerLimit.ToString();
            material.text = hasMaterialCost ? $"{owned}/{target.MaterialAmount}" : string.Empty;
            gold.text = target.GoldAmount.ToString();
            level.color = player.Level < target.LevelLimit ? Color.red : levelDefaultColor;
            power.color = player.Power < (ulong)target.PowerLimit ? Color.red : powerDefaultColor;
            material.color = hasMaterialCost && owned < target.MaterialAmount ? Color.red : materialDefaultColor;
            gold.color = currencies.Gold < target.GoldAmount ? Color.red : goldDefaultColor;
            GameObject materialObject = Require(view, Root + "/Panel_tupo/bg_cost/btn_Material");
            materialObject.SetActive(hasMaterialCost);
            if (hasMaterialCost)
            {
                Image materialIcon = materialObject.GetComponent<Image>();
                int picture = 3014 + Math.Max(0, Math.Min(4, target.MaterialId - 861));
                materialIcon.sprite = resources.LoadItemIcon(picture);
                materialIcon.enabled = materialIcon.sprite != null;
                materialIcon.preserveAspect = true;
                materialIcon.rectTransform.sizeDelta = new Vector2(55f, 55f);
            }
            RequireButton(view, Root + "/Panel_tupo/Button").interactable = !state.UpgradePending;
        }

        private void RenderPreview()
        {
            ClearRows(previewRows);
            Transform list = Require(preview, "Layer/Popup/ListView").transform;
            GameObject template = Require(preview, "Layer/Popup/Panel_1");
            template.SetActive(false);
            RectTransform templateRect = template.GetComponent<RectTransform>();
            float rowHeight = Math.Max(150f, templateRect.rect.height > 1f ? templateRect.rect.height : templateRect.sizeDelta.y);
            int index = 0;
            foreach (JingJieDefinition definition in config.Items)
            {
                GameObject row = UnityEngine.Object.Instantiate(template, list, false);
                row.name = $"Panel_{definition.Id}";
                row.SetActive(true);
                RectTransform rect = row.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, 1f);
                rect.pivot = new Vector2(.5f, 1f);
                rect.anchoredPosition = new Vector2(0f, -rowHeight * index);
                SetText(row.transform, "title_bg/value", definition.Name, QualityColor(definition.Quality));
                RectTransform nameRect = row.transform.Find("title_bg/value") as RectTransform;
                if (nameRect != null)
                {
                    nameRect.anchorMin = nameRect.anchorMax = new Vector2(.5f, .5f);
                    nameRect.pivot = new Vector2(.5f, .5f);
                    nameRect.anchoredPosition = Vector2.zero;
                    Text nameText = nameRect.GetComponent<Text>();
                    if (nameText != null)
                    {
                        nameText.horizontalOverflow = HorizontalWrapMode.Overflow;
                        nameText.verticalOverflow = VerticalWrapMode.Overflow;
                        nameText.alignment = TextAnchor.MiddleCenter;
                    }
                }
                for (int attrIndex = 0; attrIndex < 7; attrIndex++)
                {
                    int[] attribute = definition.Attributes != null && attrIndex < definition.Attributes.Length
                        ? definition.Attributes[attrIndex] : null;
                    Transform label = row.transform.Find($"Attribute{attrIndex + 1}");
                    if (label == null) continue;
                    label.gameObject.SetActive(attribute != null && attribute.Length >= 2);
                    if (attribute == null || attribute.Length < 2) continue;
                    Text key = label.GetComponent<Text>();
                    Text value = label.Find("Value")?.GetComponent<Text>();
                    if (key != null) key.text = HeroBookCatalog.AttributeName(attribute[0]) + "：";
                    if (value != null) value.text = FormatAttribute(attribute[0], attribute[1]);
                }
                previewRows.Add(row);
                index++;
            }
            JingJiePreviewScroller scroller = list.GetComponent<JingJiePreviewScroller>()
                ?? list.gameObject.AddComponent<JingJiePreviewScroller>();
            scroller.Configure(previewRows.Select(row => row.GetComponent<RectTransform>()),
                Math.Max(0f, rowHeight * config.Count - ((RectTransform)list).rect.height));
        }

        private void PopulateAttributes(Transform list, Transform template, int[][] attributes,
            List<GameObject> owner)
        {
            foreach (GameObject row in owner.Where(row => row != null && row.transform.parent == list).ToArray())
            {
                owner.Remove(row);
                UnityEngine.Object.Destroy(row);
            }
            template.gameObject.SetActive(false);
            RectTransform templateRect = template as RectTransform;
            float rowHeight = Math.Max(28f, templateRect != null && templateRect.rect.height > 1f
                ? templateRect.rect.height : 28f);
            int index = 0;
            foreach (int[] attribute in attributes ?? Array.Empty<int[]>())
            {
                if (attribute == null || attribute.Length < 2) continue;
                GameObject row = UnityEngine.Object.Instantiate(template.gameObject, list, false);
                row.name = $"Attribute{index + 1}";
                row.SetActive(true);
                RectTransform rect = row.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(0f, 1f);
                rect.anchoredPosition = new Vector2(6f, -rowHeight * index);
                Text label = row.GetComponent<Text>();
                Text value = row.transform.Find("Value")?.GetComponent<Text>();
                if (label != null) label.text = HeroBookCatalog.AttributeName(attribute[0]) + "：";
                if (value != null) value.text = FormatAttribute(attribute[0], attribute[1]);
                owner.Add(row);
                index++;
            }
        }

        private void PlayUpgradeEffect()
        {
            effectPlayer.gameObject.SetActive(true);
            effectPlayer.PlayAction(0);
            effectLifetime.HideAfter(3f);
        }

        private static string FormatAttribute(int type, int value) =>
            type >= 10 ? $"{value / 100d:0.##}%" : value.ToString();

        private static Color QualityColor(int quality)
        {
            switch (quality)
            {
                case 2: return new Color32(36, 155, 48, 255);
                case 3: return new Color32(35, 98, 174, 255);
                case 4: return new Color32(135, 32, 151, 255);
                case 5: return new Color32(203, 91, 27, 255);
                case 6: return new Color32(190, 35, 35, 255);
                case 7: return new Color32(209, 148, 24, 255);
                default: return new Color32(132, 83, 61, 255);
            }
        }

        private static GameObject Require(CocosUiView target, string path) =>
            target.Binding.Find(path) ?? throw new InvalidOperationException("JingJie imported node was not found: " + path);
        private static Text RequireText(CocosUiView target, string path) =>
            Require(target, path).GetComponent<Text>() ?? throw new InvalidOperationException("JingJie imported Text was not found: " + path);
        private static Button RequireButton(CocosUiView target, string path) =>
            Require(target, path).GetComponent<Button>() ?? throw new InvalidOperationException("JingJie imported Button was not found: " + path);
        private static void SetActive(CocosUiView target, string path, bool active) => Require(target, path).SetActive(active);
        private static void SetText(Transform root, string path, string value, Color color)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            text.text = value;
            text.color = color;
        }
        private static void ClearRows(List<GameObject> rows)
        {
            foreach (GameObject row in rows) if (row != null) UnityEngine.Object.Destroy(row);
            rows.Clear();
        }
    }

    internal sealed class JingJieEffectLifetime : MonoBehaviour
    {
        private Coroutine routine;
        public void HideAfter(float seconds)
        {
            if (routine != null) StopCoroutine(routine);
            routine = StartCoroutine(HideRoutine(seconds));
        }
        private IEnumerator HideRoutine(float seconds)
        {
            yield return new WaitForSecondsRealtime(seconds);
            gameObject.SetActive(false);
            routine = null;
        }
    }

    internal sealed class JingJiePreviewScroller : MonoBehaviour, IBeginDragHandler, IDragHandler, IScrollHandler
    {
        private readonly List<RectTransform> rows = new List<RectTransform>();
        private readonly List<Vector2> origins = new List<Vector2>();
        private float maxOffset;
        private float offset;

        public void Configure(IEnumerable<RectTransform> values, float maximum)
        {
            rows.Clear(); origins.Clear();
            foreach (RectTransform row in values.Where(value => value != null))
            {
                rows.Add(row);
                origins.Add(row.anchoredPosition);
            }
            maxOffset = Mathf.Max(0f, maximum);
            offset = 0f;
            Apply();
            Image hit = GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            hit.color = Color.clear;
            hit.raycastTarget = true;
        }

        public void OnBeginDrag(PointerEventData eventData) { }
        public void OnDrag(PointerEventData eventData) => Move(eventData.delta.y);
        public void OnScroll(PointerEventData eventData) => Move(-eventData.scrollDelta.y * 35f);
        private void Move(float delta) { offset = Mathf.Clamp(offset + delta, 0f, maxOffset); Apply(); }
        private void Apply()
        {
            for (int index = 0; index < rows.Count; index++)
                if (rows[index] != null) rows[index].anchoredPosition = origins[index] + new Vector2(0f, offset);
        }
    }
}
