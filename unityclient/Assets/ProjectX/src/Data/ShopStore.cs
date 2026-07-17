using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class ShopRecord
    {
        private readonly int[] pricePercentages;

        public ShopRecord(byte grid, ushort id, ushort buyCount, int rewardType, int rewardId,
            uint rewardAmount, string name, string description, int picture, int quality,
            int costType, int costPicture, string costName, int baseCost, int limit,
            int[] pricePercentages)
        {
            Grid = grid;
            Id = id;
            BuyCount = buyCount;
            RewardType = rewardType;
            RewardId = rewardId;
            RewardAmount = rewardAmount;
            Name = name ?? string.Empty;
            Description = description ?? string.Empty;
            Picture = picture;
            Quality = quality;
            CostType = costType;
            CostPicture = costPicture;
            CostName = costName ?? string.Empty;
            BaseCost = Math.Max(0, baseCost);
            Limit = limit;
            this.pricePercentages = pricePercentages == null || pricePercentages.Length == 0
                ? new[] { 100 }
                : (int[])pricePercentages.Clone();
        }

        public byte Grid { get; }
        public ushort Id { get; }
        public ushort BuyCount { get; }
        public int RewardType { get; }
        public int RewardId { get; }
        public uint RewardAmount { get; }
        public string Name { get; }
        public string Description { get; }
        public int Picture { get; }
        public int Quality { get; }
        public int CostType { get; }
        public int CostPicture { get; }
        public string CostName { get; }
        public int BaseCost { get; }
        public int Limit { get; }
        public int RemainingLimit => Limit < 0 ? -1 : Math.Max(0, Limit - BuyCount);
        public bool IsSoldOut => RemainingLimit == 0;
        public int DiscountPercent => pricePercentages[Math.Min(BuyCount, pricePercentages.Length - 1)];
        public int UnitCost => Math.Max(0, (int)(BaseCost * (DiscountPercent / 100f)));

        public ShopRecord WithBuyCount(ushort value) =>
            new ShopRecord(Grid, Id, value, RewardType, RewardId, RewardAmount, Name, Description,
                Picture, Quality, CostType, CostPicture, CostName, BaseCost, Limit, pricePercentages);
    }

    public sealed class ShopStore
    {
        private readonly Dictionary<ushort, ShopRecord> records = new Dictionary<ushort, ShopRecord>();

        public event Action Changed;
        public byte Type { get; private set; }
        public ushort RefreshTimes { get; private set; }
        public byte FreeRefreshTimes { get; private set; }
        public uint RefreshDeadlineUnix { get; private set; }
        public int Count => records.Count;
        public IReadOnlyList<ShopRecord> Items => records.Values
            .OrderBy(item => item.Grid)
            .ThenBy(item => item.Id)
            .ToArray();

        public void Replace(byte type, ushort refreshTimes, byte freeRefreshTimes,
            ushort refreshRemainingSeconds, uint serverUnixSeconds, IEnumerable<ShopRecord> values)
        {
            Type = type;
            RefreshTimes = refreshTimes;
            FreeRefreshTimes = freeRefreshTimes;
            RefreshDeadlineUnix = refreshRemainingSeconds > 0 && serverUnixSeconds > 0
                ? serverUnixSeconds + refreshRemainingSeconds
                : 0;
            records.Clear();
            foreach (ShopRecord value in values ?? Array.Empty<ShopRecord>())
                if (value != null) records[value.Id] = value;
            Changed?.Invoke();
        }

        public bool TryGet(ushort id, out ShopRecord value) => records.TryGetValue(id, out value);

        public bool ApplyPurchase(ushort id, ushort buyCount)
        {
            if (!records.TryGetValue(id, out ShopRecord value)) return false;
            records[id] = value.WithBuyCount(buyCount);
            Changed?.Invoke();
            return true;
        }

        public void Clear()
        {
            records.Clear();
            Type = 0;
            RefreshTimes = 0;
            FreeRefreshTimes = 0;
            RefreshDeadlineUnix = 0;
            Changed?.Invoke();
        }
    }
}
