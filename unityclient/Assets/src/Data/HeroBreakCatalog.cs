using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public static class HeroBreakEligibility
    {
        public static bool CanBreak(int heroLevel, int playerLevel, int openLevel, int requiredLevel,
            bool hasNext, bool affordable, bool authoritative) => authoritative && hasNext
            && heroLevel > 0 && playerLevel >= openLevel && heroLevel >= requiredLevel && affordable;

        // The server multiplies its integer costValue by break_ratio / 10000.0 and truncates.
        public static int ScaleCost(int cost, int ratio) => checked((int)(cost * (ratio / 10000.0)));
    }

    public sealed class HeroBreakDefinition
    {
        public HeroBreakDefinition(int requiredLevel, int attributeMultiplier, int[][] costs)
        { RequiredLevel = requiredLevel; AttributeMultiplier = attributeMultiplier; Costs = costs; }
        public int RequiredLevel { get; }
        public int AttributeMultiplier { get; }
        public int[][] Costs { get; }
        public int Cost(int id) => Costs.Where(c => c[0] == id).Sum(c => c[2]);
    }

    public sealed class HeroBreakCatalog
    {
        private static HeroBreakCatalog shared;
        public static HeroBreakCatalog Shared => shared ?? (shared = new HeroBreakCatalog());
        private readonly Dictionary<int, LevelRow> levels;
        private readonly Dictionary<int, int> ratios;
        private readonly Dictionary<int, int> heroQualities;

        private HeroBreakCatalog()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/hero-break");
            if (asset == null) throw new InvalidOperationException("Formal Unity hero breakthrough config is missing.");
            var data = JsonConvert.DeserializeObject<Config>(asset.text)
                ?? throw new InvalidOperationException("Invalid formal hero breakthrough config.");
            levels = data.Levels.ToDictionary(r => r.BreakLevel);
            ratios = data.Qualities.ToDictionary(r => r.Quality, r => r.Ratio);
            heroQualities = data.Heroes.ToDictionary(r => r.Id, r => r.Quality);
            if (levels.Values.Any(r => r.BreakLevel <= 0 || r.Level < 0 || r.Attr < 0 || r.Costs == null
                || r.Costs.Any(c => c == null || c.Length != 3 || c[0] <= 0 || c[1] != 0 || c[2] < 0))
                || ratios.Any(r => r.Key <= 0 || r.Value <= 0))
                throw new InvalidOperationException("Invalid formal hero breakthrough costs.");
        }

        public bool TryGet(int heroId, int nextBreakLevel, out HeroBreakDefinition definition)
        {
            definition = null;
            if (!heroQualities.TryGetValue(heroId, out int quality) || !ratios.TryGetValue(quality, out int ratio)
                || !levels.TryGetValue(nextBreakLevel, out LevelRow row)) return false;
            definition = new HeroBreakDefinition(row.Level, row.Attr, row.Costs.Select(c =>
                new[] { c[0], c[1], HeroBreakEligibility.ScaleCost(c[2], ratio) }).ToArray());
            return true;
        }

        public bool CanBreak(HeroRecord hero, int playerLevel, int openLevel, BagStore bag,
            CurrencyStore money, bool authoritative)
        {
            bool hasNext = TryGet(hero.Id, hero.BreakLevel + 1, out HeroBreakDefinition next);
            bool affordable = hasNext && money != null && next.Costs.GroupBy(c => c[0]).All(cost =>
                (cost.Key >= 60000 ? money.Get(cost.Key) : bag.GetTotalQuantityByItemId(cost.Key))
                >= cost.Sum(c => (long)c[2]));
            return HeroBreakEligibility.CanBreak(hero.Level, playerLevel, openLevel,
                next?.RequiredLevel ?? 0, hasNext, affordable, authoritative);
        }

        private sealed class Config
        {
            [JsonProperty("levels")] public LevelRow[] Levels { get; set; }
            [JsonProperty("qualities")] public QualityRow[] Qualities { get; set; }
            [JsonProperty("heroes")] public HeroRow[] Heroes { get; set; }
        }
        private sealed class LevelRow
        {
            [JsonProperty("break_level")] public int BreakLevel { get; set; }
            [JsonProperty("level")] public int Level { get; set; }
            [JsonProperty("attr")] public int Attr { get; set; }
            [JsonProperty("cost")] public int[][] Costs { get; set; }
        }
        private sealed class QualityRow
        {
            [JsonProperty("quality")] public int Quality { get; set; }
            [JsonProperty("break_ratio")] public int Ratio { get; set; }
        }
        private sealed class HeroRow
        {
            [JsonProperty("id")] public int Id { get; set; }
            [JsonProperty("quality")] public int Quality { get; set; }
        }
    }
}
