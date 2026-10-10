using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class HeroFragmentCatalog
    {
        private readonly Dictionary<int, EquipmentComposeDefinition> recipes =
            new Dictionary<int, EquipmentComposeDefinition>();
        private static HeroFragmentCatalog shared;
        public static HeroFragmentCatalog Shared => shared ?? (shared = new HeroFragmentCatalog());

        public HeroFragmentCatalog() : this(Load()) { }

        public HeroFragmentCatalog(IEnumerable<EquipmentComposeDefinition> definitions)
        {
            foreach (EquipmentComposeDefinition value in definitions ?? Array.Empty<EquipmentComposeDefinition>())
            {
                if (value.Type != 2) continue;
                if (value.Target == null || value.Target.Length != 3 || value.Target[0] != 60002
                    || value.Target[1] <= 0 || value.Target[2] != 1 || value.Items == null
                    || value.Items.Length == 0 || value.Items.Any(cost => cost == null || cost.Length != 3
                        || cost[0] <= 0 || cost[1] != 0 || cost[2] <= 0))
                    throw new InvalidOperationException("Invalid formal hero composition recipe: " + value.Id);
                int fragmentId = value.Items[0][0];
                if (fragmentId >= 60000 || recipes.ContainsKey(fragmentId))
                    throw new InvalidOperationException("Ambiguous formal hero fragment: " + fragmentId);
                recipes.Add(fragmentId, value);
            }
        }

        public int GetRequiredFragments(int fragmentId) => recipes.TryGetValue(fragmentId, out EquipmentComposeDefinition recipe)
            ? recipe.Items.Where(cost => cost[0] == fragmentId).Sum(cost => cost[2]) : 0;

        public bool CanCompose(int fragmentId, HeroStore heroes, BagStore bag, CurrencyStore currencies,
            bool pending = false)
        {
            if (pending || !heroes.HasAuthoritativeState || !recipes.TryGetValue(fragmentId, out EquipmentComposeDefinition recipe)
                || heroes.TryGet(recipe.Target[1], out _)) return false;
            foreach (IGrouping<int, int[]> costs in recipe.Items.GroupBy(cost => cost[0]))
            {
                long required = costs.Sum(cost => (long)cost[2]);
                long owned = costs.Key >= 60000 ? currencies.Get(costs.Key) : bag.GetTotalQuantityByItemId(costs.Key);
                if (owned < required) return false;
            }
            return true;
        }

        private static IEnumerable<EquipmentComposeDefinition> Load()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/hecheng");
            if (asset == null) throw new InvalidOperationException("Formal hero composition config is missing: hecheng.json");
            return JsonConvert.DeserializeObject<EquipmentComposeDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentComposeDefinition>();
        }
    }
}
