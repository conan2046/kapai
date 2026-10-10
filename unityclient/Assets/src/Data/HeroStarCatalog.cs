using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public static class HeroStarEligibility
    {
        public static bool CanStarUp(int currentStar, int playerLevel, int openLevel, int owned,
            int required, bool hasNext, bool authoritative) => authoritative && hasNext
            && currentStar > 0 && playerLevel >= openLevel && required >= 0 && owned >= required;
    }

    public readonly struct HeroStarDefinition
    {
        public HeroStarDefinition(int targetStar, int fragmentId, int required)
        { TargetStar = targetStar; FragmentId = fragmentId; Required = required; }
        public int TargetStar { get; }
        public int FragmentId { get; }
        public int Required { get; }
    }

    public sealed class HeroStarCatalog
    {
        private static HeroStarCatalog shared;
        public static HeroStarCatalog Shared => shared ?? (shared = new HeroStarCatalog());
        private readonly Dictionary<int, Dictionary<int, int>> costs;
        private readonly Dictionary<int, HeroRow> heroes;

        private HeroStarCatalog()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/hero-star");
            if (asset == null) throw new InvalidOperationException("Formal Unity hero star config is missing.");
            var data = JsonConvert.DeserializeObject<Config>(asset.text)
                ?? throw new InvalidOperationException("Invalid formal hero star config.");
            if (data.Stars == null || data.Heroes == null || data.Stars.Any(r => r.Star <= 0 || r.Costs == null
                || r.Costs.Any(c => c == null || c.Length != 2 || c[0] <= 0 || c[1] < 0)))
                throw new InvalidOperationException("Invalid formal hero star costs.");
            costs = data.Stars.ToDictionary(r => r.Star, r => r.Costs.ToDictionary(c => c[0], c => c[1]));
            heroes = data.Heroes.ToDictionary(r => r.Id);
        }

        public bool TryGet(int heroId, int targetStar, out HeroStarDefinition definition)
        {
            definition = default;
            if (!heroes.TryGetValue(heroId, out HeroRow hero) || hero.ItemId <= 0
                || !costs.TryGetValue(targetStar, out Dictionary<int, int> byQuality)
                || !byQuality.TryGetValue(hero.Quality, out int required)) return false;
            definition = new HeroStarDefinition(targetStar, hero.ItemId, required);
            return true;
        }

        public int GetFragmentItem(int heroId) => heroes.TryGetValue(heroId, out HeroRow hero) ? hero.ItemId : 0;

        public bool CanStarUp(HeroRecord hero, int playerLevel, int openLevel, BagStore bag, bool authoritative)
        {
            bool hasNext = TryGet(hero.Id, hero.Star + 1, out HeroStarDefinition next);
            return HeroStarEligibility.CanStarUp(hero.Star, playerLevel, openLevel,
                hasNext ? bag.GetTotalQuantityByItemId(next.FragmentId) : 0, next.Required, hasNext, authoritative);
        }

        private sealed class Config
        {
            [JsonProperty("stars")] public StarRow[] Stars { get; set; }
            [JsonProperty("heroes")] public HeroRow[] Heroes { get; set; }
        }
        private sealed class StarRow
        {
            [JsonProperty("star")] public int Star { get; set; }
            [JsonProperty("cost")] public int[][] Costs { get; set; }
        }
        private sealed class HeroRow
        {
            [JsonProperty("id")] public int Id { get; set; }
            [JsonProperty("quality")] public int Quality { get; set; }
            [JsonProperty("itemId")] public int ItemId { get; set; }
        }
    }
}
