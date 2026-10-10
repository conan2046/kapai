using System.Linq;

namespace ProjectX.Data
{
    public static class EquipmentRedDotEligibility
    {
        private static bool Costs(int[][] costs, BagStore bag, CurrencyStore currencies) => costs != null
            && costs.Length > 0 && costs.All(c => c != null && c.Length == 3 && c[2] >= 0
                && (c[0] >= 60000 ? currencies.Get(c[0]) >= c[2] : bag.GetTotalQuantityByItemId(c[0]) >= c[2]));

        public static bool Equipment(HeroEquipmentRecord item, int mode, int playerLevel,
            EquipmentCatalog catalog, BagStore bag, CurrencyStore currencies, bool authoritative, bool pending)
        {
            if (!authoritative || pending || item.Uid == 0 || mode < 0 || mode > 3
                || playerLevel < FunctionUnlockCatalog.Resolve(1120 + mode * 10).OpenLevel) return false;
            int level = item.GetLevel(mode + 1);
            if (mode == 0)
            {
                int cost = catalog.GetStrengthCost(level + 1, item.Definition.Quality);
                return level < playerLevel * 2 && level < catalog.MaxStrengthLevel && cost > 0 && currencies.Gold >= cost;
            }
            if (mode == 1)
            {
                int required = catalog.GetRefineExperience(level, item.Definition.Quality);
                long materials = bag.Items.Sum(x => (long)x.Quantity * catalog.GetRefineMaterialExperience(x.ItemId));
                return required > 0 && catalog.GetRefine(level + 1) != null && item.Experience + materials >= required && materials > 0;
            }
            if (mode == 2) return item.Definition.Quality >= 5 && Costs(catalog.GetAwaken(level + 1)?.Cost, bag, currencies);
            EquipmentDivineDefinition divine = catalog.GetDivine(level + 1);
            return item.Definition.Quality >= 6 && divine != null && divine.FragmentCount > 0
                && item.Definition.DivineCostItemId > 0
                && bag.GetTotalQuantityByItemId(item.Definition.DivineCostItemId) >= divine.FragmentCount
                && Costs(divine.Money, bag, currencies);
        }

        public static bool FaBao(FaBaoRecord item, int mode, int playerLevel, EquipmentCatalog catalog,
            FaBaoStore store, BagStore bag, CurrencyStore currencies, bool authoritative, bool pending)
        {
            if (!authoritative || pending || item.Uid == 0 || mode < 0 || mode > 1
                || playerLevel < FunctionUnlockCatalog.Resolve(1120 + mode * 10).OpenLevel) return false;
            int level = item.GetLevel(5 + mode);
            if (mode == 0) return level < catalog.MaxFaBaoStrengthLevel
                && store.Items.Any(x => x.Uid != item.Uid && x.FormationPosition == 0
                    && x.GetLevel(5) == 0 && x.GetLevel(6) == 0 && x.Definition.ExperienceValue > 0
                    && currencies.Gold >= x.Definition.ExperienceValue);
            return Costs(catalog.GetFaBaoRefine(level + 1)?.Cost, bag, currencies);
        }
    }
}
