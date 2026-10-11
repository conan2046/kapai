using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class JingJieRenderBridge : IDisposable
    {
        private const string Root = "Layer/JingjieUI/Panel";
        private readonly UnityUiView view;
        private readonly UnityUiView preview;
        private readonly JingJieViewState state;
        private readonly JingJieConfigData config;
        private readonly PlayerStore player;
        private readonly CurrencyStore currencies;
        private readonly BagStore bag;
        private readonly IUiResourceProvider resources;
        private readonly Action requestUpgrade;
        private readonly Action<string> feedback;
        private readonly List<GameObject> previewRows = new List<GameObject>();
        private readonly GameObject effectRoot;
        private readonly Animator effectPlayer;
        private readonly JingJieEffectLifetime effectLifetime;
        private readonly JingJieIncomeView income;
        private readonly Text experienceRequirement;
        private readonly Button previewControl;
        private JingJieDefinition nextDefinition;

        public JingJieRenderBridge(UnityUiView view, UnityUiView preview, JingJieViewState state,
            JingJieConfigData config, PlayerStore player, CurrencyStore currencies, BagStore bag,
            IUiResourceProvider resources, Action requestUpgrade,
            Action<string> feedback)
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
            this.feedback = feedback ?? (_ => { });

            // The authored preview button may be reparented without changing its identity.
            previewControl = view.GameObject.GetComponentsInChildren<Button>(true)
                .SingleOrDefault(button => button.name == "Btn_xiangxi")
                ?? throw new InvalidOperationException("Jingjie prefab preview button Btn_xiangxi is missing.");
            Button upgrade = RequireButton(view, Root + "/Panel_tupo/Button");
            Button material = RequireButton(view, Root + "/Panel_tupo/bg_cost/btn_Material");
            previewControl.onClick.RemoveAllListeners();
            upgrade.onClick.RemoveAllListeners();
            material.onClick.RemoveAllListeners();
            previewControl.onClick.AddListener(ShowPreview);
            upgrade.onClick.AddListener(() => this.requestUpgrade());
            preview.BindClick("Layer/Popup/Btn_close", HidePreview, true);

            GameObject effect = Require(view, Root + "/effect_jingjietupo_1");
            effectRoot = effect;
            effectPlayer = effect.GetComponentInChildren<Animator>(true)
                ?? throw new InvalidOperationException("Jingjie prefab breakthrough Animator is missing.");
            effectLifetime = effect.GetComponent<JingJieEffectLifetime>()
                ?? throw new InvalidOperationException("Jingjie prefab breakthrough lifetime is missing.");

            state.Changed += Render;
            player.Changed += Render;
            currencies.Changed += Render;
            bag.Changed += Render;
            Transform expectation = Require(view, Root + "/expect").transform;
            Text rate = expectation.GetComponentsInChildren<Text>(true).FirstOrDefault(t => string.Equals(t.name, "num", StringComparison.OrdinalIgnoreCase));
            income = view.GameObject.GetComponent<JingJieIncomeView>()
                ?? throw new InvalidOperationException("Jingjie prefab income component is missing.");
            income.Bind(state, expectation.GetComponent<Scrollbar>(), rate);
            experienceRequirement = RequireText(view, Root + "/Panel_tupo/bg_limit/ExperienceRequirement");
            Render();
        }

        public bool IsVisible => view.GameObject.activeInHierarchy;
        public bool IsPreviewVisible => preview.GameObject.activeInHierarchy;
        public int CurrentId => state.CurrentId;
        public int PreviewRowCount => previewRows.Count > 0 ? config.Count : 0;
        public bool HasNextDefinition => nextDefinition != null;
        public bool IsUpgradeEffectVisible => effectPlayer != null && effectPlayer.gameObject.activeInHierarchy;
        public Button PreviewControl => previewControl;
        public Button PreviewCloseControl => RequireButton(preview, "Layer/Popup/Btn_close");
        public Button MaterialControl => RequireButton(view, Root + "/Panel_tupo/bg_cost/btn_Material");
        public Button UpgradeControl => RequireButton(view, Root + "/Panel_tupo/Button");

        public void Dispose()
        {
            state.Changed -= Render;
            player.Changed -= Render;
            currencies.Changed -= Render;
            bag.Changed -= Render;
            previewRows.Clear();
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
            preview.ShowPopup();
            Canvas.ForceUpdateCanvases();
            RenderPreview();
        }


        public void HidePreview() => preview.SetVisible(false);

        public bool TryBeginUpgrade()
        {
            config.TryGet(state.CurrentId + 1, out JingJieDefinition target);
            JingJieUpgradeBlock block = JingJieUpgradeEligibility.Evaluate(state, target);
            switch (block)
            {
                case JingJieUpgradeBlock.Synchronizing: feedback("境界数据同步中"); return false;
                case JingJieUpgradeBlock.Maximum: feedback("已达到最高境界"); return false;
                case JingJieUpgradeBlock.Pending: return false;
                case JingJieUpgradeBlock.Experience: feedback("修为不足"); return false;
            }
            return state.BeginUpgrade();
        }

        private void Render()
        {
            if (view.GameObject == null) return;
            bool atMaximum = state.HasAuthoritativeState && state.CurrentId >= config.Count;
            bool empty = !state.HasAuthoritativeState || state.CurrentId == 0;
            JingJieDefinition current = empty ? null : config.Get(state.CurrentId);
            JingJieDefinition target = atMaximum ? null : config.Get(Math.Max(1, state.CurrentId + 1));
            SetActive(view, Root + "/Panel_L", true);
            SetActive(view, Root + "/Panel_L/Panel_0", empty);
            SetActive(view, Root + "/Panel_L/bg_L", !empty);
            if (current != null) RenderStage(current);
            RenderAttributeComparison(current, target);
            RenderBreakthrough(target);
            if (IsVisible && state.ConsumeUpgradeEffect()) PlayUpgradeEffect();
        }

        private void RenderStage(JingJieDefinition definition)
        {
            string panelPath = Root + "/Panel_L";
            string iconPath = panelPath + "/bg_L/Icon";
            Image icon = Require(view, iconPath).GetComponent<Image>();
            if (definition.Icon != null && definition.Icon.StartsWith("role_{sex}_", StringComparison.Ordinal))
            {
                icon.enabled = false;
                if (player.IsLoaded)
                {
                    Transform anchor = icon.transform.Find("SpineAnchor");
                    if (anchor == null) throw new InvalidOperationException("JingJie Icon/SpineAnchor is missing.");
                    RoleSpinePortrait portrait = anchor.GetComponent<RoleSpinePortrait>()
                        ?? anchor.gameObject.AddComponent<RoleSpinePortrait>();
                    portrait.Show(definition.Icon, player.Sex);
                    RoleCultivationAura aura = anchor.GetComponent<RoleCultivationAura>()
                        ?? throw new InvalidOperationException("Jingjie prefab aura component is missing.");
                    aura.Show(definition.VisualStage, QualityColor(definition.Quality));
                }
            }
            else
            {
                Sprite sprite = resources.LoadSprite("Art/Icons/JingJie/" + definition.Icon);
                icon.sprite = sprite;
                icon.enabled = sprite != null;
                icon.preserveAspect = true;
            }
            Text name = RequireText(view, panelPath + "/bg_L/Panel_name/name");
            name.text = definition.Name;
        }

        private void RenderAttributeComparison(JingJieDefinition current, JingJieDefinition target)
        {
            Transform comparison = Require(view, Root + "/AttributeComparison").transform;
            SetText(comparison, "CurrentStage", current?.Name ?? "境界同步中");
            SetText(comparison, "NextStage", target?.Name ?? "已达最高境界");
            int[][] currentAttributes = current?.Attributes ?? Array.Empty<int[]>();
            int[][] targetAttributes = target?.Attributes ?? Array.Empty<int[]>();
            int[] types = currentAttributes.Concat(targetAttributes).Where(a => a != null && a.Length >= 2)
                .Select(a => a[0]).Distinct().ToArray();
            for (int index = 0; index < 7; index++)
            {
                Transform row = comparison.Find("Attr_List/Attribute" + (index + 1))
                    ?? throw new InvalidOperationException("Jingjie prefab comparison row is missing.");
                row.gameObject.SetActive(index < types.Length);
                if (index >= types.Length) continue;
                int type = types[index];
                int before = currentAttributes.FirstOrDefault(a => a != null && a.Length >= 2 && a[0] == type)?[1] ?? 0;
                int after = targetAttributes.FirstOrDefault(a => a != null && a.Length >= 2 && a[0] == type)?[1] ?? 0;
                SetText(row, "Value_0", HeroBookCatalog.AttributeName(type));
                SetText(row, "Value_1", FormatAttribute(type, before));
                SetText(row, "Value_2", target == null ? "—" : FormatAttribute(type, after));
                SetText(row, "Value_3", target == null ? string.Empty : FormatAttribute(type, after - before));
                row.Find("To").gameObject.SetActive(target != null);
                row.Find("Image").gameObject.SetActive(target != null && after > before);
            }
        }

        private void RenderBreakthrough(JingJieDefinition target)
        {
            nextDefinition = target;
            bool available = target != null;
            SetActive(view, Root + "/Panel_tupo/bg_limit", available || state.HasAuthoritativeState);
            SetActive(view, Root + "/Panel_tupo/Button", available);
            SetActive(view, Root + "/Panel_tupo/Panel_end", !available);
            if (!available)
            {
                experienceRequirement.gameObject.SetActive(true);
                experienceRequirement.text = $"累计修为 {state.Experience:N0}";
                return;
            }

            experienceRequirement.gameObject.SetActive(true);
            experienceRequirement.text = state.HasAuthoritativeState
                ? $"修为 {state.Experience:N0} / {state.RequiredExperience:N0}" : "修为同步中";
            bool big = state.HasAuthoritativeState && config.Get(state.CurrentId).Stage == 10;
            Button upgrade = RequireButton(view, Root + "/Panel_tupo/Button");
            foreach (Text label in upgrade.GetComponentsInChildren<Text>(true)) label.text = big ? "渡劫" : "升级";
            upgrade.interactable = state.HasAuthoritativeState && !state.UpgradePending && state.Experience >= state.RequiredExperience;
        }

        private void RenderPreview()
        {
            previewRows.Clear();
            Transform list = Require(preview, "Layer/Popup/ListView").transform;
            JingJiePreviewScroller scroller = list.GetComponent<JingJiePreviewScroller>()
                ?? throw new InvalidOperationException("Jingjie preview prefab scroller is missing.");
            int index = 0;
            foreach (JingJieDefinition definition in config.Items.Take(8))
            {
                GameObject row = list.Find($"PreviewRow{index + 1}")?.gameObject
                    ?? throw new InvalidOperationException("Jingjie preview prefab row is missing.");
                row.SetActive(true);
                BindPreviewRow(row.transform, definition.Id - 1);
                previewRows.Add(row);
                index++;
            }
            scroller.Configure(previewRows.Select(row => row.GetComponent<RectTransform>()),
                config.Count, BindPreviewRow);
        }

        private void BindPreviewRow(Transform row, int index)
        {
            JingJieDefinition definition = config.Get(index + 1);
            SetText(row, "title_bg/value", definition.Name);
            for (int attrIndex = 0; attrIndex < 7; attrIndex++)
            {
                int[] attribute = definition.Attributes != null && attrIndex < definition.Attributes.Length ? definition.Attributes[attrIndex] : null;
                Transform label = row.Find($"Attribute{attrIndex + 1}");
                if (label == null) continue;
                label.gameObject.SetActive(attribute != null && attribute.Length >= 2);
                if (attribute == null || attribute.Length < 2) continue;
                Text key = label.GetComponent<Text>();
                Text value = label.Find("Value")?.GetComponent<Text>();
                if (key != null) key.text = HeroBookCatalog.AttributeName(attribute[0]) + "：";
                if (value != null) value.text = FormatAttribute(attribute[0], attribute[1]);
            }
        }


        private void PlayUpgradeEffect()
        {
            effectRoot.SetActive(true);
            effectPlayer.gameObject.SetActive(true);
            effectPlayer.enabled = true;
            effectPlayer.Play("JingJieBreakthrough", 0, 0f);
            effectLifetime.HideAfter(3f);
        }

        private static string FormatAttribute(int type, int value) =>
            type >= 10 ? $"{value / 100d:0.##}%" : value.ToString();

        public static Color QualityColor(int quality)
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

        private static GameObject Require(UnityUiView target, string path) =>
            target.FindNode(path) ?? throw new InvalidOperationException("JingJie imported node was not found: " + path);
        private static Text RequireText(UnityUiView target, string path) =>
            Require(target, path).GetComponent<Text>() ?? throw new InvalidOperationException("JingJie imported Text was not found: " + path);
        private static Button RequireButton(UnityUiView target, string path) =>
            Require(target, path).GetComponent<Button>() ?? throw new InvalidOperationException("JingJie imported Button was not found: " + path);
        private static void RetireGeneratedAttributeMetadata(UnityUiView target, string panelPath,
            bool templateInsideList = false)
        {
            Transform rows = Require(target, panelPath + "/Attr_List").transform;
            Transform template = Require(target, templateInsideList
                ? panelPath + "/Attr_List/Attribute1"
                : panelPath + "/Attribute1").transform;
        }
        private static void SetActive(UnityUiView target, string path, bool active) => Require(target, path).SetActive(active);
        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text == null) return;
            text.text = value;
        }
        private static void ClearRows(List<GameObject> rows)
        {
            foreach (GameObject row in rows) if (row != null) UnityEngine.Object.Destroy(row);
            rows.Clear();
        }
    }

}
