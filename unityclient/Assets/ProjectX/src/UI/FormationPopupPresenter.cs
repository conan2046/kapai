using System;
using System.Collections.Generic;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FormationPopupPresenter : IDisposable
    {
        private static readonly FormationDefinition[] Definitions =
        {
            new FormationDefinition(1, "七星阵", new[]{2,4,6,7,9}, new[]{3,5}),
            new FormationDefinition(2, "玄火阵", new[]{2,4,5,6,8}, new[]{1,6}),
            new FormationDefinition(3, "急流阵", new[]{1,2,3,5,8}, new[]{2,5}),
            new FormationDefinition(4, "地绝阵", new[]{2,5,7,8,9}, new[]{3,6}),
            new FormationDefinition(5, "密林阵", new[]{1,3,4,6,8}, new[]{2,4}),
            new FormationDefinition(6, "山岳阵", new[]{1,3,5,7,9}, new[]{1,3})
        };

        private readonly CocosUiView view;
        private readonly FormationStore formation;
        private readonly HeroStore heroes;
        private readonly BagStore bag;
        private readonly CurrencyStore currencies;
        private readonly ResourceService resources;
        private readonly Action<int,int> swap;
        private readonly Action<int> upgrade;
        private readonly Action<int> use;
        private readonly Action<string> feedback;
        private readonly VirtualList<FormationDefinition> list;
        private readonly ImodAnimationPlayer[] models = new ImodAnimationPlayer[5];
        private readonly Image runtimeDim;
        private readonly Text runtimeTitle;
        private readonly Button closeInteractionButton;
        private int selectedFormationId;
        private int selectedCombatPosition;

        public FormationPopupPresenter(CocosUiView view, FormationStore formation, HeroStore heroes,
            BagStore bag, CurrencyStore currencies, ResourceService resources,
            Action<int,int> swap, Action<int> upgrade, Action<int> use,
            Action<string> feedback, Action close)
        {
            this.view = view; this.formation = formation; this.heroes = heroes;
            this.bag = bag; this.currencies = currencies;
            this.resources = resources; this.swap = swap; this.upgrade = upgrade; this.use = use;
            this.feedback = feedback;
            selectedFormationId = formation.ActiveFormationId > 0 ? formation.ActiveFormationId : 1;
            runtimeDim = CreateDim(view.Binding.Find("Layer")?.transform ?? view.Binding.transform);
            runtimeTitle = CreateTitle(view.Binding.Find("Layer")?.transform ?? view.Binding.transform,
                view.Binding.Find("Layer/Bg/Popup/Title/Title")?.GetComponent<Text>());
            GameObject viewport = Require("Layer/FormationUI/List_Formation/ListView");
            GameObject template = Require("Layer/FormationUI/List_Formation/Item");
            float height = template.GetComponent<RectTransform>().rect.height;
            list = new VirtualList<FormationDefinition>(viewport, template, height, BindFormation);
            view.BindClick("Layer/Bg/Popup/Btn_close", close, true);
            closeInteractionButton = CreateCloseInteraction(close);
            for (int combat = 1; combat <= models.Length; combat++)
                models[combat - 1] = CreateModel(Require($"Layer/FormationUI/Show/Formation/Node_{combat}").transform, combat);
            view.BindClick("Layer/FormationUI/Show/Info/btn_Upgrade", UpgradeSelectedFormation, true);
            view.BindClick("Layer/FormationUI/List_Formation/btn_Use", () => use?.Invoke(selectedFormationId), true);
            for (int grid = 1; grid <= 9; grid++)
            {
                int captured = grid;
                view.BindClick($"Layer/FormationUI/Show/Formation/Position{grid}", () => SelectGrid(captured), true);
            }
            formation.Changed += Render;
        }

        public Button CloseInteractionButton => closeInteractionButton;

        public void RefreshCloseInteraction()
        {
            Canvas.ForceUpdateCanvases();
            GameObject target = Require("Layer/Bg/Popup/Btn_close");
            RectTransform targetRect = target.transform as RectTransform;
            RectTransform rootRect = view.GameObject.transform as RectTransform;
            RectTransform rect = closeInteractionButton.transform as RectTransform;
            if (targetRect == null || rootRect == null || rect == null) return;
            Vector3[] corners = new Vector3[4];
            targetRect.GetWorldCorners(corners);
            Vector3 min = rootRect.InverseTransformPoint(corners[0]);
            Vector3 max = rootRect.InverseTransformPoint(corners[2]);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            // The imported root uses a bottom-left pivot. anchoredPosition would
            // add the parent's anchor reference a second time and place this
            // proxy half a screen beyond the visible close button.
            rect.localPosition = new Vector3((min.x + max.x) * .5f, (min.y + max.y) * .5f, 0f);
            rect.sizeDelta = new Vector2(Mathf.Abs(max.x - min.x), Mathf.Abs(max.y - min.y));
            Image image = closeInteractionButton.targetGraphic as Image;
            if (image == null) return;
            image.enabled = false;
            image.enabled = true;
            image.raycastTarget = true;
            image.canvasRenderer.cullTransparentMesh = false;
            image.SetAllDirty();
            Canvas canvas = image.canvas;
            if (canvas != null)
            {
                GraphicRegistry.RegisterGraphicForCanvas(canvas, image);
                GraphicRegistry.RegisterRaycastGraphicForCanvas(canvas, image);
            }
            closeInteractionButton.transform.SetAsLastSibling();
        }

        private Button CreateCloseInteraction(Action close)
        {
            GameObject proxy = new GameObject("RuntimeFormationClose", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image), typeof(Button));
            proxy.transform.SetParent(view.GameObject.transform, false);
            Image image = proxy.GetComponent<Image>();
            image.color = new Color(1f, 1f, 1f, .001f);
            image.raycastTarget = true;
            image.canvasRenderer.cullTransparentMesh = false;
            Button button = proxy.GetComponent<Button>();
            button.targetGraphic = image;
            button.interactable = true;
            button.onClick.AddListener(() => close());
            return button;
        }

        public void Render()
        {
            list.SetItems(Definitions);
            FormationDefinition definition = Array.Find(Definitions, item => item.Id == selectedFormationId);
            if (definition.Id == 0) definition = Definitions[0];
            for (int grid = 1; grid <= 9; grid++)
            {
                int combat = Array.IndexOf(definition.GridPositions, grid) + 1;
                Transform position = Find($"Layer/FormationUI/Show/Formation/Position{grid}");
                Text number = position?.Find("Num")?.GetComponent<Text>();
                if (number != null) { number.gameObject.SetActive(combat > 0); number.text = combat > 0 ? combat.ToString() : ""; }
                Transform lockNode = position?.Find("Lock");
                if (lockNode != null) lockNode.gameObject.SetActive(false);
                if (position != null)
                {
                    Image image = position.GetComponent<Image>();
                    if (image != null) image.color = new Color(1f,1f,1f,combat > 0 ? 1f : .4f);
                }
            }
            int currentLevel = GetFormationLevel(definition.Id);
            int displayLevel = Mathf.Max(1, currentLevel);
            string[] attrs = BuildAttributes(definition.Id, displayLevel);
            for (int i = 1; i <= 5; i++)
            {
                Text attribute = Find($"Layer/FormationUI/Show/Info/Attribute{i}/Content")?.GetComponent<Text>();
                if (attribute != null) { attribute.text = attrs[i-1]; attribute.horizontalOverflow = HorizontalWrapMode.Overflow; }
            }
            SetText("Layer/FormationUI/Show/Info/Restriction/Content", BuildRestraintText(definition));
            Text restriction = Find("Layer/FormationUI/Show/Info/Restriction/Content")?.GetComponent<Text>();
            if (restriction != null) restriction.horizontalOverflow = HorizontalWrapMode.Overflow;
            bool maxLevel = currentLevel >= 10;
            int requiredBooks = maxLevel ? 0 : UpgradeBookCosts[Mathf.Clamp(currentLevel, 0, UpgradeBookCosts.Length - 1)];
            int ownedBooks = GetBagQuantity(2724 + definition.Id);
            int requiredGold = maxLevel ? 0 : (currentLevel + 1) * 100000;
            SetText("Layer/FormationUI/Show/Info/CoinBg/Num", maxLevel ? string.Empty : requiredGold.ToString());
            SetText("Layer/FormationUI/Show/Info/btn_Material/Value", maxLevel ? string.Empty : $"{ownedBooks}/{requiredBooks}");
            SetText("Layer/FormationUI/Show/Info/bg_Name/Name", definition.Name + "法书");
            SetText("Layer/FormationUI/Show/Info/btn_Upgrade/Text", currentLevel == 0 ? "学习" : "升级");
            Text coinValue = Find("Layer/FormationUI/Show/Info/CoinBg/Num")?.GetComponent<Text>();
            if (coinValue != null) coinValue.color = currencies.Gold >= requiredGold ? Color.white : new Color(.85f,.16f,.12f,1f);
            Text materialValue = Find("Layer/FormationUI/Show/Info/btn_Material/Value")?.GetComponent<Text>();
            if (materialValue != null) materialValue.color = ownedBooks >= requiredBooks ? Color.white : new Color(.85f,.16f,.12f,1f);
            Text popupTitle = Find("Layer/Bg/Popup/Title/Title")?.GetComponent<Text>();
            if (popupTitle != null)
            {
                popupTitle.gameObject.SetActive(true);
                popupTitle.text = "阵容";
                popupTitle.color = new Color(0.45f, 0.16f, 0.08f, 1f);
            }
            if (runtimeTitle != null) runtimeTitle.text = "阵容";
            Image materialIcon = Find("Layer/FormationUI/Show/Info/btn_Material/Icon")?.GetComponent<Image>();
            if (materialIcon != null) materialIcon.sprite = resources.LoadFirst("ItemIcons/equip1817");
            SetTransparent("Layer/FormationUI/Show/Info/btn_Material");
            SetTransparent("Layer/FormationUI/Show/Info/bg_Name");
            Image dim = Find("Layer/Bg")?.GetComponent<Image>();
            if (dim != null) dim.color = new Color(0f, 0f, 0f, .9f);
            if (runtimeDim != null) runtimeDim.color = new Color(0f, 0f, 0f, .82f);
            Transform useButton = Find("Layer/FormationUI/List_Formation/btn_Use");
            if (useButton != null) useButton.gameObject.SetActive(currentLevel > 0 && formation.ActiveFormationId != definition.Id);
            Transform upgradeButton = Find("Layer/FormationUI/Show/Info/btn_Upgrade");
            if (upgradeButton != null) upgradeButton.gameObject.SetActive(!maxLevel);
            Transform coinPanel = Find("Layer/FormationUI/Show/Info/CoinBg");
            if (coinPanel != null) coinPanel.gameObject.SetActive(!maxLevel);
            Transform materialButton = Find("Layer/FormationUI/Show/Info/btn_Material");
            if (materialButton != null) materialButton.gameObject.SetActive(!maxLevel);
            Transform materialName = Find("Layer/FormationUI/Show/Info/bg_Name");
            if (materialName != null) materialName.gameObject.SetActive(!maxLevel);
            foreach (Transform child in view.Binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
            RenderedModelCount = 0;
            for (int combatPosition = 1; combatPosition <= models.Length; combatPosition++)
            {
                ImodAnimationPlayer model = models[combatPosition - 1];
                int heroId = combatPosition <= formation.CombatHeroes.Count
                    ? formation.CombatHeroes[combatPosition - 1] : 0;
                int grid = definition.GridPositions[combatPosition - 1];
                Transform host = Find($"Layer/FormationUI/Show/Formation/Node_{grid}");
                if (host != null && model.transform.parent != host)
                {
                    model.transform.SetParent(host, false);
                    model.transform.localScale = new Vector3(.85f, .85f, 1f);
                    if (model.transform is RectTransform modelRect)
                        modelRect.anchoredPosition = Vector2.zero;
                }
                bool loaded = heroId > 0 && HeroCatalog.TryGet(heroId, out HeroDefinition hero)
                    && model.LoadLegacy($"Monster/btm{hero.Picture}_zd");
                model.gameObject.SetActive(loaded);
                if (loaded) { model.Play(1, true); RenderedModelCount++; }
            }
        }

        public int RenderedModelCount { get; private set; }

        public void Dispose() { formation.Changed -= Render; list.Dispose(); }

        private void BindFormation(RectTransform row, FormationDefinition item, int index)
        {
            SetRowText(row, "bg_Formation/Name", item.Name);
            int level = 0;
            foreach (FormationRecord record in formation.Formations) if (record.Id == item.Id) level = record.Level;
            Text levelText = row.Find("bg_Formation/Level")?.GetComponent<Text>();
            if (levelText != null) { levelText.text = level > 0 ? $"Lv.{level}" : "未学习"; levelText.horizontalOverflow = HorizontalWrapMode.Overflow; }
            Image icon = row.Find("bg_Formation/Icon")?.GetComponent<Image>();
            if (icon != null) icon.sprite = resources.LoadFirst($"HeroUI/formation_{item.Id}");
            Transform tag = row.Find("Tag"); if (tag != null) tag.gameObject.SetActive(formation.ActiveFormationId == item.Id);
            Transform choose = row.Find("Choose"); if (choose != null) choose.gameObject.SetActive(selectedFormationId == item.Id);
            Transform prompt = row.Find("Prompt"); if (prompt != null) prompt.gameObject.SetActive(false);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>();
            button.interactable = true;
            if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
            button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => { selectedFormationId = item.Id; Render(); });
        }

        private void SelectGrid(int grid)
        {
            FormationDefinition definition = Array.Find(Definitions, item => item.Id == selectedFormationId);
            int combat = Array.IndexOf(definition.GridPositions, grid) + 1;
            if (combat <= 0) return;
            if (selectedCombatPosition == 0)
            {
                if (combat <= formation.CombatHeroes.Count && formation.CombatHeroes[combat-1] > 0)
                    selectedCombatPosition = combat;
                return;
            }
            int sourcePosition = selectedCombatPosition;
            selectedCombatPosition = 0;
            if (sourcePosition != combat) swap?.Invoke(sourcePosition, combat);
        }

        private static readonly int[] UpgradeBookCosts = {1,3,7,13,20,30,45,60,75,100};

        private int GetFormationLevel(int id)
        {
            foreach (FormationRecord record in formation.Formations) if (record.Id == id) return record.Level;
            return 0;
        }

        private int GetBagQuantity(int itemId)
        {
            foreach (BagItemRecord item in bag.Items) if (item.ItemId == itemId) return item.Quantity;
            return 0;
        }

        private void UpgradeSelectedFormation()
        {
            FormationDefinition definition = Array.Find(Definitions, item => item.Id == selectedFormationId);
            if (definition.Id == 0) return;
            int level = GetFormationLevel(definition.Id);
            if (level >= 10) return;
            int requiredBooks = UpgradeBookCosts[Mathf.Clamp(level, 0, UpgradeBookCosts.Length - 1)];
            if (GetBagQuantity(2724 + definition.Id) < requiredBooks)
            {
                feedback?.Invoke(definition.Name + "法书不足");
                return;
            }
            int requiredGold = (level + 1) * 100000;
            if (currencies.Gold < requiredGold)
            {
                feedback?.Invoke("铜钱不足");
                return;
            }
            upgrade?.Invoke(definition.Id);
        }

        private static string BuildRestraintText(FormationDefinition definition)
        {
            var names = new List<string>();
            foreach (int id in definition.Restraints)
            {
                FormationDefinition target = Array.Find(Definitions, item => item.Id == id);
                if (target.Id > 0) names.Add(target.Name);
            }
            return string.Join("  ", names);
        }

        private static string[] BuildAttributes(int formationId, int level)
        {
            int low = level >= 10 ? 800 : 300 + (level - 1) * 50;
            int high = level >= 10 ? 1500 : 500 + (level - 1) * 100;
            switch (formationId)
            {
                case 2: return new[]{Ratio("反击率", low), Ratio("暴击率", low), Ratio("命中率", low), Ratio("连击率", low), Ratio("增伤率", high)};
                case 3: return new[]{Ratio("负面强化", low), Ratio("命中率", high), Ratio("命中率", high), Ratio("物免率", low) + "  " + Ratio("法免率", low), Ratio("增伤率", high)};
                case 4: return new[]{Ratio("负面抵抗", low), Ratio("增伤率", low), Ratio("负面抵抗", low), Ratio("负面抵抗", low), Ratio("负面抵抗", low)};
                case 5: return new[]{Ratio("暴击率", low), Ratio("暴击率", low), Ratio("暴击率", low), Ratio("暴击率", low), Ratio("暴击率", low)};
                case 6: return new[]{Ratio("闪避率", low), Ratio("抗暴率", low), Ratio("命中率", high), Ratio("物免率", high), Ratio("法免率", high)};
                default: return new[]{Ratio("闪避率", low), Ratio("物免率", high), Ratio("法免率", high), Ratio("增伤率", low), Ratio("增伤率", low)};
            }
        }

        private static string Ratio(string name, int basisPoints) => $"{name}+{basisPoints / 100f:0.##}%";

        private static ImodAnimationPlayer CreateModel(Transform parent, int combatPosition)
        {
            var go = new GameObject($"RuntimeFormationHero_{combatPosition}", typeof(RectTransform));
            RectTransform rect = go.GetComponent<RectTransform>(); rect.SetParent(parent, false);
            rect.localScale = new Vector3(.85f,.85f,1f);
            return go.AddComponent<ImodAnimationPlayer>();
        }
        private static Image CreateDim(Transform parent)
        {
            Transform existing = parent.Find("RuntimeFormationDim");
            GameObject go = existing != null ? existing.gameObject
                : new GameObject("RuntimeFormationDim", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.SetAsFirstSibling();
            Image image = go.GetComponent<Image>(); image.raycastTarget = true;
            return image;
        }
        private static Text CreateTitle(Transform parent, Text source)
        {
            Transform existing = parent.Find("RuntimeFormationTitle");
            GameObject go = existing != null ? existing.gameObject
                : new GameObject("RuntimeFormationTitle", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>(); rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, 1f); rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = new Vector2(0f, -91f); rect.sizeDelta = new Vector2(100f, 48f);
            rect.SetAsLastSibling();
            Text text = go.GetComponent<Text>();
            if (source != null) text.font = source.font;
            text.fontSize = 36; text.alignment = TextAnchor.MiddleCenter;
            text.color = new Color(.45f, .16f, .08f, 1f); text.raycastTarget = false;
            return text;
        }
        private GameObject Require(string path) => view.Binding.Find(path) ?? throw new InvalidOperationException("Formation UI node missing: " + path);
        private Transform Find(string path) => view.Binding.Find(path)?.transform;
        private void SetText(string path, string value) { Text text = Find(path)?.GetComponent<Text>(); if (text != null) text.text = value; }
        private void SetTransparent(string path) { Image image = Find(path)?.GetComponent<Image>(); if (image != null) image.color = new Color(1f,1f,1f,0f); }
        private static void SetRowText(Transform row, string path, string value) { Text text=row.Find(path)?.GetComponent<Text>(); if(text!=null)text.text=value; }

        private readonly struct FormationDefinition
        {
            public FormationDefinition(int id, string name, int[] gridPositions, int[] restraints = null)
            { Id=id; Name=name; GridPositions=gridPositions; Restraints=restraints ?? Array.Empty<int>(); }
            public int Id { get; } public string Name { get; } public int[] GridPositions { get; }
            public int[] Restraints { get; }
        }
    }
}
