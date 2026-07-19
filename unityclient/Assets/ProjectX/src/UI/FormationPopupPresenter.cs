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
            new FormationDefinition(1, "七星阵", new[]{2,4,6,7,9}),
            new FormationDefinition(2, "玄火阵", new[]{2,4,5,6,8}),
            new FormationDefinition(3, "急流阵", new[]{1,2,3,5,8}),
            new FormationDefinition(4, "地绝阵", new[]{2,5,7,8,9}),
            new FormationDefinition(5, "密林阵", new[]{1,3,4,6,8}),
            new FormationDefinition(6, "山岳阵", new[]{1,3,5,7,9})
        };

        private readonly CocosUiView view;
        private readonly FormationStore formation;
        private readonly HeroStore heroes;
        private readonly ResourceService resources;
        private readonly Action<int,int> move;
        private readonly VirtualList<FormationDefinition> list;
        private readonly ImodAnimationPlayer model;
        private readonly Image runtimeDim;
        private readonly Text runtimeTitle;
        private int selectedFormationId;
        private int selectedCombatPosition;

        public FormationPopupPresenter(CocosUiView view, FormationStore formation, HeroStore heroes,
            ResourceService resources, Action<int,int> move, Action close)
        {
            this.view = view; this.formation = formation; this.heroes = heroes;
            this.resources = resources; this.move = move;
            selectedFormationId = formation.ActiveFormationId > 0 ? formation.ActiveFormationId : 1;
            runtimeDim = CreateDim(view.Binding.Find("Layer")?.transform ?? view.Binding.transform);
            runtimeTitle = CreateTitle(view.Binding.Find("Layer")?.transform ?? view.Binding.transform,
                view.Binding.Find("Layer/Bg/Popup/Title/Title")?.GetComponent<Text>());
            GameObject viewport = Require("Layer/FormationUI/List_Formation/ListView");
            GameObject template = Require("Layer/FormationUI/List_Formation/Item");
            float height = template.GetComponent<RectTransform>().rect.height;
            list = new VirtualList<FormationDefinition>(viewport, template, height, BindFormation);
            view.BindClick("Layer/Bg/Popup/Btn_close", close, true);
            model = CreateModel(Require("Layer/FormationUI/Show/Formation/Node_2").transform);
            for (int grid = 1; grid <= 9; grid++)
            {
                int captured = grid;
                view.BindClick($"Layer/FormationUI/Show/Formation/Position{grid}", () => SelectGrid(captured), true);
            }
            formation.Changed += Render;
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
            string[] attrs = {"闪避率+3%", "物免率+5%", "法免率+5%", "增伤率+3%", "增伤率+3%"};
            for (int i = 1; i <= 5; i++)
            {
                Text attribute = Find($"Layer/FormationUI/Show/Info/Attribute{i}/Content")?.GetComponent<Text>();
                if (attribute != null) { attribute.text = attrs[i-1]; attribute.horizontalOverflow = HorizontalWrapMode.Overflow; }
            }
            SetText("Layer/FormationUI/Show/Info/Restriction/Content", "急流阵  密林阵");
            Text restriction = Find("Layer/FormationUI/Show/Info/Restriction/Content")?.GetComponent<Text>();
            if (restriction != null) restriction.horizontalOverflow = HorizontalWrapMode.Overflow;
            SetText("Layer/FormationUI/Show/Info/CoinBg/Num", "200000");
            SetText("Layer/FormationUI/Show/Info/btn_Material/Value", "0/3");
            SetText("Layer/FormationUI/Show/Info/bg_Name/Name", "七星阵法书");
            SetText("Layer/FormationUI/Show/Info/btn_Upgrade/Text", "升级");
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
            if (useButton != null) useButton.gameObject.SetActive(false);
            foreach (Transform child in view.Binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
            int heroId = 0;
            int combatPosition = 0;
            for (int index = 0; index < formation.CombatHeroes.Count; index++)
            {
                if (formation.CombatHeroes[index] <= 0) continue;
                heroId = formation.CombatHeroes[index];
                combatPosition = index + 1;
                break;
            }
            if (combatPosition > 0 && combatPosition <= definition.GridPositions.Length)
            {
                int grid = definition.GridPositions[combatPosition - 1];
                Transform host = Find($"Layer/FormationUI/Show/Formation/Position{grid}/Panel");
                if (host != null)
                {
                    model.transform.SetParent(host, false);
                    model.transform.localScale = new Vector3(.85f, .85f, 1f);
                    if (model.transform is RectTransform modelRect)
                        modelRect.anchoredPosition = new Vector2(0f, -88f);
                }
            }
            bool loaded = heroId > 0 && HeroCatalog.TryGet(heroId, out HeroDefinition hero)
                && model.LoadLegacy($"Monster/btm{hero.Picture}_zd");
            model.gameObject.SetActive(loaded);
            if (loaded) model.Play(1, true);
        }

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
            int heroId = formation.CombatHeroes[selectedCombatPosition-1];
            selectedCombatPosition = 0;
            if (heroId > 0 && move != null) move(heroId, combat);
        }

        private static ImodAnimationPlayer CreateModel(Transform parent)
        {
            var go = new GameObject("RuntimeFormationHero", typeof(RectTransform));
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
            public FormationDefinition(int id, string name, int[] gridPositions) { Id=id; Name=name; GridPositions=gridPositions; }
            public int Id { get; } public string Name { get; } public int[] GridPositions { get; }
        }
    }
}
