using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public static class HeroCultivationEligibility
    {
        public static bool CanTrain(int heroLevel, int requiredLevel, int remaining, int owned,
            bool hasNext, bool authoritative) => authoritative && hasNext && heroLevel > 0
            && heroLevel >= requiredLevel && remaining > 0 && owned > 0;

        public static bool CanActivate(int heroLevel, int requiredLevel, int remaining, bool affordable,
            bool hasNext, bool authoritative) => authoritative && hasNext && heroLevel > 0
            && heroLevel >= requiredLevel && remaining == 0 && affordable;
    }

    public sealed class HeroCultivationDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("level_need")] public int RequiredLevel { get; set; }
        [JsonProperty("cost_type")] public int RequiredCount { get; set; }
        [JsonProperty("cost_xiulian")] public int[][] ActivationCosts { get; set; }
    }

    public sealed class HeroCultivationCatalog
    {
        private static HeroCultivationCatalog shared;
        public static HeroCultivationCatalog Shared => shared ?? (shared = new HeroCultivationCatalog());
        private readonly Dictionary<int, HeroCultivationDefinition> levels;
        private readonly Dictionary<int, int> attributeUnits;
        public int TrainingItemId { get; }

        private HeroCultivationCatalog()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/hero-cultivation");
            if (asset == null) throw new InvalidOperationException("Formal Unity hero cultivation config is missing.");
            Config data = JsonConvert.DeserializeObject<Config>(asset.text)
                ?? throw new InvalidOperationException("Invalid formal hero cultivation config.");
            if (data.TrainingItemId <= 0 || data.Units == null || data.Levels == null
                || data.Units.Any(u => u == null || u.Length != 2 || u[0] < 1 || u[0] > 4 || u[1] <= 0)
                || data.Levels.Any(r => r.Level <= 0 || r.RequiredLevel <= 0 || r.RequiredCount <= 0
                    || r.ActivationCosts == null || r.ActivationCosts.Any(c => c == null || c.Length != 3
                        || c[0] <= 0 || c[1] != 0 || c[2] < 0)))
                throw new InvalidOperationException("Invalid formal hero cultivation requirements.");
            TrainingItemId = data.TrainingItemId;
            levels = data.Levels.ToDictionary(r => r.Level);
            attributeUnits = data.Units.ToDictionary(u => u[0], u => u[1]);
            if (attributeUnits.Count != 4) throw new InvalidOperationException("Incomplete formal cultivation attributes.");
        }

        public bool TryGetNext(HeroRecord hero, out HeroCultivationDefinition next)
        {
            next = null;
            return hero.Id > 0 && levels.TryGetValue(hero.CultivationLevel + 1, out next);
        }

        public int GetAttributeUnit(int id) => attributeUnits[id];

        public int Remaining(HeroRecord hero)
        {
            if (!TryGetNext(hero, out HeroCultivationDefinition next)) return -1;
            int[] counts = { hero.CultivationAttack, hero.CultivationPhysicalDefense,
                hero.CultivationMagicDefense, hero.CultivationHealth };
            if (counts.Any(c => c < 0 || c > next.RequiredCount)) return -1;
            return counts.Sum(c => next.RequiredCount - c);
        }

        public bool CanTrain(HeroRecord hero, BagStore bag, bool authoritative)
        {
            bool hasNext = TryGetNext(hero, out HeroCultivationDefinition next);
            return HeroCultivationEligibility.CanTrain(hero.Level, next?.RequiredLevel ?? 0, Remaining(hero),
                bag.GetTotalQuantityByItemId(TrainingItemId), hasNext, authoritative);
        }

        public int AvailableCount(HeroRecord hero, BagStore bag) => Math.Max(0,
            Math.Min(ushort.MaxValue, Math.Min(Remaining(hero), bag.GetTotalQuantityByItemId(TrainingItemId))));

        public bool CanActivate(HeroRecord hero, BagStore bag, CurrencyStore money, bool authoritative)
        {
            bool hasNext = TryGetNext(hero, out HeroCultivationDefinition next);
            bool affordable = hasNext && next.ActivationCosts.GroupBy(c => c[0]).All(cost =>
                (cost.Key >= 60000 ? money?.Get(cost.Key) ?? 0 : bag.GetTotalQuantityByItemId(cost.Key))
                >= cost.Sum(c => (long)c[2]));
            return HeroCultivationEligibility.CanActivate(hero.Level, next?.RequiredLevel ?? 0,
                Remaining(hero), affordable, hasNext, authoritative);
        }

        private sealed class Config
        {
            [JsonProperty("trainingItemId")] public int TrainingItemId { get; set; }
            [JsonProperty("attributeUnits")] public int[][] Units { get; set; }
            [JsonProperty("levels")] public HeroCultivationDefinition[] Levels { get; set; }
        }
    }
}
