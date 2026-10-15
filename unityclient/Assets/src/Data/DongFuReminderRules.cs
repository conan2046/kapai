using System;
using System.Linq;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class DongFuReminderInputs
    {
        readonly Dictionary<int, long> quantities = new Dictionary<int, long>();
        public bool Observe(int key, long value)
        {
            bool changed = !quantities.TryGetValue(key, out long previous) || previous != value;
            quantities[key] = value;
            return changed;
        }
        public void Clear() => quantities.Clear();
    }

    public static class DongFuReminderRules
    {
        public static bool Harvest(GardenPlotSnapshot plot) =>
            plot != null && plot.Unlocked && plot.CropId > 0 && plot.Stage == 3;

        public static bool SpiritFull(SpiritEnvelope state) =>
            state != null && state.Configured && state.Unlocked
            && long.TryParse(state.Storage, out long capacity) && capacity > 0
            && long.TryParse(state.Spirit, out long owned) && owned >= capacity;

        public static bool RootUpgrade(SpiritEnvelope state, SpiritRootState root) =>
            state != null && state.Configured && state.Unlocked && root != null
            && root.Configured && root.NextId > 0 && !root.Capped
            && string.IsNullOrEmpty(state.Error)
            && (root.Costs ?? Array.Empty<long[]>()).All(p => p.Length == 3 && p[2] >= p[1])
            && long.TryParse(state.Spirit, out long owned)
            && long.TryParse(root.SpiritCost, out long needed) && owned >= needed;

        public static bool AlchemyClaim(AlchemyEnvelope state, long serverMilliseconds) =>
            state != null && state.Recipe > 0 && state.Count > 0
            && long.TryParse(state.Finish, out long finish) && finish > 0
            && serverMilliseconds >= finish;

        public static bool LibrarySet(LibraryCatalogData catalog, LibraryEnvelope state, int set) =>
            catalog != null && catalog.InSet(set).Any(r => catalog.Eligible(state, r));
    }
}
