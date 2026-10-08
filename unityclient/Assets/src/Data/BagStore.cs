using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct BagItemRecord
    {
        public BagItemRecord(int slot, int itemId, int quantity, string name, string description,
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType = 0, string itemFrom = "", string choices = "", string sources = "")
        {
            Slot = slot;
            ItemId = itemId;
            Quantity = quantity;
            Name = string.IsNullOrEmpty(name) ? $"物品 #{itemId}" : name;
            Description = description ?? string.Empty;
            Picture = picture;
            Quality = quality;
            UseType = useType;
            UseJump = useJump;
            SortPriority = sortPriority;
            ItemType = itemType;
            ItemFrom = itemFrom ?? string.Empty;
            Choices = choices ?? string.Empty;
            Sources = sources ?? string.Empty;
        }

        public int Slot { get; }
        public int ItemId { get; }
        public int Quantity { get; }
        public string Name { get; }
        public string Description { get; }
        public int Picture { get; }
        public int Quality { get; }
        public int UseType { get; }
        public int UseJump { get; }
        public int SortPriority { get; }
        public int ItemType { get; }
        public string ItemFrom { get; }
        public string Choices { get; }
        public string Sources { get; }
    }

    public sealed class BagStore
    {
        private readonly Dictionary<int, BagItemRecord> bySlot = new Dictionary<int, BagItemRecord>();
        public event Action Changed;
        public int Count => bySlot.Count;
        public IReadOnlyList<BagItemRecord> Items
        {
            get
            {
                List<BagItemRecord> visible = bySlot.Values
                    .Where(item => item.ItemId > 0 && item.Quantity > 0)
                    .Where(item => item.ItemType != 2 && item.ItemType != 7
                        && item.ItemType != 13 && item.ItemType != 16)
                    .OrderBy(item => item.Slot)
                    .GroupBy(item => item.ItemId)
                    .Select(group =>
                    {
                        BagItemRecord representative = group.First();
                        return new BagItemRecord(representative.Slot, representative.ItemId,
                            group.Sum(item => item.Quantity), representative.Name, representative.Description,
                            representative.Picture, representative.Quality, representative.UseType,
                            representative.UseJump, representative.SortPriority, representative.ItemType,
                            representative.ItemFrom, representative.Choices, representative.Sources);
                    })
                    .ToList();
                LuaPrioritySort(visible, 0, visible.Count - 1);
                return visible;
            }
        }

        // KaPaiBagSubUI.lua uses Lua 5.1 table.sort with only sort_priority in
        // the comparator. Equal priorities therefore follow Lua's deterministic
        // quicksort permutation, not itemId order or a stable LINQ tie-breaker.
        private static void LuaPrioritySort(List<BagItemRecord> items, int lower, int upper)
        {
            while (lower < upper)
            {
                if (items[upper].SortPriority < items[lower].SortPriority) Swap(items, lower, upper);
                if (upper - lower == 1) break;
                int middle = (lower + upper) / 2;
                if (items[middle].SortPriority < items[lower].SortPriority) Swap(items, middle, lower);
                else if (items[upper].SortPriority < items[middle].SortPriority) Swap(items, middle, upper);
                if (upper - lower == 2) break;
                Swap(items, middle, upper - 1);
                int left = lower;
                int right = upper - 1;
                BagItemRecord pivot = items[upper - 1];
                while (true)
                {
                    while (items[++left].SortPriority < pivot.SortPriority) { }
                    while (pivot.SortPriority < items[--right].SortPriority) { }
                    if (right < left) break;
                    Swap(items, left, right);
                }
                Swap(items, left, upper - 1);
                if (left - lower < upper - left)
                {
                    LuaPrioritySort(items, lower, left - 1);
                    lower = left + 1;
                }
                else
                {
                    LuaPrioritySort(items, left + 1, upper);
                    upper = left - 1;
                }
            }
        }

        private static void Swap(List<BagItemRecord> items, int first, int second)
        {
            BagItemRecord value = items[first];
            items[first] = items[second];
            items[second] = value;
        }

        public void Replace(IEnumerable<BagItemRecord> items)
        {
            bySlot.Clear();
            foreach (BagItemRecord item in items ?? Array.Empty<BagItemRecord>())
                if (item.ItemId > 0 && item.Quantity > 0) bySlot[item.Slot] = item;
            Changed?.Invoke();
        }

        public void Upsert(BagItemRecord item)
        {
            if (item.ItemId <= 0 || item.Quantity <= 0) bySlot.Remove(item.Slot);
            else bySlot[item.Slot] = item;
            Changed?.Invoke();
        }

        public void Remove(int slot)
        {
            if (bySlot.Remove(slot)) Changed?.Invoke();
        }

        public bool TryGet(int slot, out BagItemRecord item) => bySlot.TryGetValue(slot, out item);
        public int GetQuantity(int slot) => bySlot.TryGetValue(slot, out BagItemRecord item) ? item.Quantity : 0;
        public int GetTotalQuantityByItemId(int itemId) => bySlot.Values
            .Where(item => item.ItemId == itemId && item.Quantity > 0)
            .Sum(item => item.Quantity);
        public IReadOnlyList<BagItemRecord> GetItemsByType(int itemType)
        {
            return bySlot.Values
                .Where(item => item.ItemId > 0 && item.Quantity > 0 && item.ItemType == itemType)
                .OrderBy(item => item.Slot)
                .GroupBy(item => item.ItemId)
                .Select(group =>
                {
                    BagItemRecord representative = group.First();
                    return new BagItemRecord(representative.Slot, representative.ItemId,
                        group.Sum(item => item.Quantity), representative.Name, representative.Description,
                        representative.Picture, representative.Quality, representative.UseType,
                        representative.UseJump, representative.SortPriority, representative.ItemType,
                        representative.ItemFrom, representative.Choices, representative.Sources);
                })
                .ToList();
        }

        public void Clear()
        {
            bySlot.Clear();
            Changed?.Invoke();
        }
    }
}
