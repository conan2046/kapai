using System;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class FormationCatalog
    {
        [Serializable] private sealed class Row
        {
            public int id;
            public int level;
            public int[][] cost;
        }
        private static FormationCatalog shared;
        private readonly Row[] rows;
        public static FormationCatalog Shared => shared ?? (shared = new FormationCatalog());
        private FormationCatalog()
        {
            var asset = Resources.Load<TextAsset>("ProjectXData/Configs/formation-level");
            if (asset == null) throw new InvalidOperationException("Formal formation costs are missing.");
            rows = JsonConvert.DeserializeObject<Row[]>(asset.text);
        }
        public int Level(FormationStore store, int id) => store.Formations.FirstOrDefault(x => x.Id == id).Level;
        private Row Target(FormationStore store, int id) => rows.FirstOrDefault(x => x.id == id && x.level == Level(store, id));
        public int BookId(FormationStore store, int id) => Target(store, id)?.cost?.FirstOrDefault(x => x.Length == 3 && x[0] != CurrencyIds.Gold)?[0] ?? 0;
        public int BookCost(FormationStore store, int id) => Target(store, id)?.cost?.FirstOrDefault(x => x.Length == 3 && x[0] != CurrencyIds.Gold)?[2] ?? 0;
        public int GoldCost(FormationStore store, int id) => Target(store, id)?.cost?.FirstOrDefault(x => x.Length == 3 && x[0] == CurrencyIds.Gold)?[2] ?? 0;
        public bool CanUpgrade(FormationStore store, BagStore bag, CurrencyStore money, int id)
        {
            Row target = Target(store, id);
            return store.HasAuthoritativeState && store.PendingFormationId != id && target?.cost != null
                && target.cost.Any(x => x.Length == 3 && x[2] > 0)
                && target.cost.All(x => x.Length == 3 && x[2] >= 0 && (x[0] == CurrencyIds.Gold
                    ? money.Gold >= x[2] : bag.GetTotalQuantityByItemId(x[0]) >= x[2]));
        }
        public bool AnyReady(FormationStore store, BagStore bag, CurrencyStore money)
            => rows.Select(x => x.id).Distinct().Any(id => CanUpgrade(store, bag, money, id));
        public static bool CanFillPosition(FormationStore store, HeroStore heroes, PlayerStore player, int position)
            => store.HasAuthoritativeState && heroes.HasAuthoritativeState && position >= 1 && position <= 5
                && player.Level >= FunctionUnlockCatalog.Resolve(1030 + position).OpenLevel
                && (position > store.CombatHeroes.Count || store.CombatHeroes[position - 1] == 0)
                && heroes.Items.Any(h => store.GetCombatPosition(h.Id) == 0);
    }
}
