using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public readonly struct HeroBookLevelDefinition
    {
        public HeroBookLevelDefinition(int id, int score, IEnumerable<HeroBookAttribute> attributes)
        {
            Id = id;
            Score = score;
            Attributes = (attributes ?? Array.Empty<HeroBookAttribute>()).ToArray();
        }
        public int Id { get; }
        public int Score { get; }
        public IReadOnlyList<HeroBookAttribute> Attributes { get; }
    }

    public readonly struct HeroBookCost
    {
        public HeroBookCost(int itemId, int quantity) { ItemId = itemId; Quantity = quantity; }
        public int ItemId { get; }
        public int Quantity { get; }
    }

    public sealed class HeroBookStarDefinition
    {
        private readonly Dictionary<int, int> scores;
        private readonly Dictionary<int, HeroBookCost> costs;

        public HeroBookStarDefinition(int star, int handbook, int condition,
            IEnumerable<int[]> values, IEnumerable<int[]> costValues)
        {
            Star = star;
            Handbook = handbook;
            Condition = condition;
            scores = (values ?? Array.Empty<int[]>())
                .Where(value => value != null && value.Length >= 2)
                .ToDictionary(value => value[0], value => value[1]);
            costs = (costValues ?? Array.Empty<int[]>())
                .Where(value => value != null && value.Length >= 3)
                .ToDictionary(value => value[0], value => new HeroBookCost(value[1], value[2]));
        }

        public int Star { get; }
        public int Handbook { get; }
        public int Condition { get; }
        public int GetScore(int quality) => scores.TryGetValue(quality, out int value) ? value : 0;
        public HeroBookCost GetCost(int quality) => costs.TryGetValue(quality, out HeroBookCost value) ? value : default;
    }

    public sealed class HeroBookCatalog
    {
        [Serializable] private sealed class RawLevel
        {
            public int id { get; set; }
            public int handbook_value { get; set; }
            public int[][] attr { get; set; }
        }

        [Serializable] private sealed class RawStar
        {
            public int star { get; set; }
            public int handbook { get; set; }
            public int handbook_condition { get; set; }
            public int[][] handbook_value { get; set; }
            public int[][] handbook_cost { get; set; }
        }

        [Serializable] private sealed class RawQuality
        {
            public int quality { get; set; }
            public int handbook_ratio { get; set; }
        }

        [Serializable] private sealed class RawHero
        {
            public int id { get; set; }
            public string name { get; set; }
            public int pic { get; set; }
            public int quality { get; set; }
            public int attack_type { get; set; }
            public int itemId { get; set; }
            public int gongji { get; set; }
            public int wufang { get; set; }
            public int fashang { get; set; }
            public int qixue { get; set; }
            public int gongji_lv { get; set; }
            public int wufang_lv { get; set; }
            public int fafang_lv { get; set; }
            public int qixue_lv { get; set; }
        }

        private readonly List<HeroBookLevelDefinition> levels = new List<HeroBookLevelDefinition>();
        private readonly Dictionary<int, HeroBookStarDefinition> stars = new Dictionary<int, HeroBookStarDefinition>();
        private readonly Dictionary<int, int> qualityRatios = new Dictionary<int, int>();
        private readonly Dictionary<int, HeroDefinition> heroes = new Dictionary<int, HeroDefinition>();

        public HeroBookCatalog()
        {
            Load();
        }

        public IReadOnlyList<HeroBookLevelDefinition> Levels => levels;
        public IReadOnlyList<KeyValuePair<int, HeroDefinition>> Heroes => heroes.ToArray();
        public int MaxStar => stars.Count == 0 ? 0 : stars.Keys.Max();
        public bool TryGetLevel(int id, out HeroBookLevelDefinition value)
        {
            value = levels.FirstOrDefault(item => item.Id == id);
            return value.Id > 0;
        }
        public bool TryGetStar(int star, out HeroBookStarDefinition value) => stars.TryGetValue(star, out value);
        public bool TryGetHero(int id, out HeroDefinition value) => heroes.TryGetValue(id, out value);
        public int GetQualityRatio(int quality) => qualityRatios.TryGetValue(quality, out int value) ? value : 0;

        public static string AttributeName(int type)
        {
            string[] names = { "", "攻击", "物防", "法防", "生命", "速度", "命中", "闪避", "暴击", "抗暴",
                "攻击", "物防", "法防", "生命", "速度", "命中率", "闪避率", "暴击率", "抗暴率",
                "增伤率", "物免率", "法免率", "暴击伤害", "反击率", "抗反率", "反击伤害",
                "连击率", "抗连率", "连击伤害", "反震率", "抗震率", "反震伤害", "负面强化", "负面抵抗" };
            return type > 0 && type < names.Length ? names[type] : $"属性{type}";
        }

        public static string FormatAttribute(HeroBookAttribute attribute, bool allPrefix = false)
        {
            string value = attribute.Type >= 10 ? $"{attribute.Value / 100d:0.##}%" : attribute.Value.ToString();
            return $"{(allPrefix ? "全体" : "")}{AttributeName(attribute.Type)}+{value}";
        }

        private void Load()
        {
            TextAsset levelAsset = Resources.Load<TextAsset>("Configs/handbook");
            TextAsset starAsset = Resources.Load<TextAsset>("Configs/star");
            TextAsset qualityAsset = Resources.Load<TextAsset>("Configs/quality");
            TextAsset heroAsset = Resources.Load<TextAsset>("Configs/hero");
            if (levelAsset == null || starAsset == null || qualityAsset == null || heroAsset == null)
                throw new InvalidOperationException("HeroBook authoritative hero/handbook/star/quality JSON resources are missing.");
            foreach (RawLevel raw in JsonConvert.DeserializeObject<List<RawLevel>>(levelAsset.text) ?? new List<RawLevel>())
                levels.Add(new HeroBookLevelDefinition(raw.id, raw.handbook_value,
                    (raw.attr ?? Array.Empty<int[]>()).Where(item => item?.Length >= 2)
                    .Select(item => new HeroBookAttribute(item[0], item[1]))));
            foreach (RawStar raw in JsonConvert.DeserializeObject<List<RawStar>>(starAsset.text) ?? new List<RawStar>())
                stars[raw.star] = new HeroBookStarDefinition(raw.star, raw.handbook,
                    raw.handbook_condition, raw.handbook_value, raw.handbook_cost);
            foreach (RawQuality raw in JsonConvert.DeserializeObject<List<RawQuality>>(qualityAsset.text) ?? new List<RawQuality>())
                qualityRatios[raw.quality] = raw.handbook_ratio;
            foreach (RawHero raw in JsonConvert.DeserializeObject<List<RawHero>>(heroAsset.text) ?? new List<RawHero>())
            {
                if (raw.id <= 0 || raw.pic <= 0) continue;
                heroes[raw.id] = new HeroDefinition(raw.pic, raw.quality,
                    physicalAttack: raw.attack_type == 1, name: raw.name, itemId: raw.itemId,
                    attack: raw.gongji, physicalDefense: raw.wufang, magicDefense: raw.fashang,
                    health: raw.qixue, attackGrowth: raw.gongji_lv,
                    physicalDefenseGrowth: raw.wufang_lv, magicDefenseGrowth: raw.fafang_lv,
                    healthGrowth: raw.qixue_lv);
            }
            levels.Sort((left, right) => left.Id.CompareTo(right.Id));
            if (levels.Count == 0 || stars.Count == 0 || heroes.Count == 0)
                throw new InvalidOperationException("HeroBook authoritative JSON resources are empty.");
        }
    }
}
