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
        public IReadOnlyList<BagItemRecord> Items => bySlot.Values
            .Where(item => item.ItemId > 0 && item.Quantity > 0)
            .Where(item => item.ItemType != 2 && item.ItemType != 7
                && item.ItemType != 13 && item.ItemType != 16)
            .OrderBy(item => item.SortPriority)
            .ThenBy(item => item.ItemId)
            .ThenBy(item => item.Slot)
            .ToArray();

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

        public void Clear()
        {
            bySlot.Clear();
            Changed?.Invoke();
        }
    }
}
