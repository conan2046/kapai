using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class HeroPresenter : IDisposable
    {
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly VirtualList<HeroRecord> list;
        private readonly Text summary;
        private readonly Text power;
        private readonly Text attack;
        private readonly Text health;
        private readonly Text physicalDefense;
        private readonly Text magicDefense;
        private int selectedId;

        public HeroPresenter(CocosUiView listView, CocosUiView detailView, HeroStore heroes, FormationStore formation)
        {
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            GameObject viewport = Require(listView, "Layer/shenjiangListUI/List");
            GameObject template = Require(listView, "Layer/shenjiangListUI/List/Item");
            float height = Mathf.Max(90f, template.GetComponent<RectTransform>().rect.height);
            list = new VirtualList<HeroRecord>(viewport, template, height, BindRow);
            summary = RequireText(detailView, "Layer/EquipUI/Bg/bg/Image_bg/Tips_2");
            power = RequireText(detailView, "Layer/EquipUI/Bg/bg/Image_bg/bg_zhanli/Value");
            attack = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_1");
            health = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_2");
            physicalDefense = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_3");
            magicDefense = RequireText(detailView, "Layer/EquipUI/Bg/Equip/Text_4");
            heroes.Changed += Render;
            formation.Changed += Render;
            Render();
        }

        public int ItemCount => list.Count;
        public int SelectedId => selectedId;

        public void Render()
        {
            var items = heroes.Items;
            if (selectedId == 0 || !heroes.TryGet(selectedId, out _)) selectedId = items.Count > 0 ? items[0].Id : 0;
            list.SetItems(items);
            ShowDetails();
        }

        public void Dispose()
        {
            heroes.Changed -= Render;
            formation.Changed -= Render;
            list.Dispose();
        }

        private void BindRow(RectTransform row, HeroRecord item, int index)
        {
            Text level = row.Find("bg_Head/Value")?.GetComponent<Text>();
            Text name = row.Find("bg_Head/Name")?.GetComponent<Text>();
            if (level != null) level.text = $"Lv.{item.Level}";
            if (name != null) { name.gameObject.SetActive(true); name.text = item.Name; }
            Transform choose = row.Find("Choose");
            if (choose != null) choose.gameObject.SetActive(item.Id == selectedId);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => { selectedId = item.Id; Render(); });
            row.gameObject.name = $"Hero_{item.Id}_{index}";
        }

        private void ShowDetails()
        {
            if (!heroes.TryGet(selectedId, out HeroRecord hero))
            {
                summary.text = "暂无神将";
                power.text = attack.text = health.text = physicalDefense.text = magicDefense.text = "-";
                return;
            }
            int position = formation.GetCombatPosition(hero.Id);
            summary.text = $"{hero.Level}级  {hero.Name} +{hero.BreakLevel}" + (position > 0 ? $"  阵位{position}" : "  未上阵");
            power.text = hero.Power.ToString();
            attack.text = $"攻击：{hero.Attack}";
            health.text = $"生命：{hero.Health}";
            physicalDefense.text = $"物防：{hero.PhysicalDefense}";
            magicDefense.text = $"法防：{hero.MagicDefense}";
        }

        private static GameObject Require(CocosUiView view, string path)
            => view.Binding.Find(path) ?? throw new InvalidOperationException($"Hero UI node was not found: {path}");
        private static Text RequireText(CocosUiView view, string path)
            => Require(view, path).GetComponent<Text>() ?? throw new InvalidOperationException($"Hero UI text was not found: {path}");
    }
}
