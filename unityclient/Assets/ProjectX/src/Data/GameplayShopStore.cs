using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class GameplayShopPage
    {
        public GameplayShopPage(byte type, ushort refreshTimes, byte freeRefreshTimes,
            ushort refreshRemainingSeconds, uint serverUnixSeconds, IEnumerable<ShopRecord> items)
        {
            Type = type;
            RefreshTimes = refreshTimes;
            FreeRefreshTimes = freeRefreshTimes;
            RefreshDeadlineUnix = refreshRemainingSeconds > 0 && serverUnixSeconds > 0
                ? serverUnixSeconds + refreshRemainingSeconds
                : 0;
            Items = (items ?? Array.Empty<ShopRecord>())
                .Where(item => item != null)
                .OrderBy(item => item.Grid)
                .ThenBy(item => item.Id)
                .ToArray();
        }

        public byte Type { get; }
        public ushort RefreshTimes { get; }
        public byte FreeRefreshTimes { get; }
        public uint RefreshDeadlineUnix { get; }
        public IReadOnlyList<ShopRecord> Items { get; }
    }

    public sealed class GameplayShopStore
    {
        private readonly Dictionary<byte, GameplayShopPage> pages = new Dictionary<byte, GameplayShopPage>();

        public event Action Changed;
        public int PageCount => pages.Count;
        public IReadOnlyCollection<byte> LoadedTypes => pages.Keys.OrderBy(type => type).ToArray();

        public void Replace(byte type, ushort refreshTimes, byte freeRefreshTimes,
            ushort refreshRemainingSeconds, uint serverUnixSeconds, IEnumerable<ShopRecord> items)
        {
            pages[type] = new GameplayShopPage(type, refreshTimes, freeRefreshTimes,
                refreshRemainingSeconds, serverUnixSeconds, items);
            Changed?.Invoke();
        }

        public bool TryGet(byte type, out GameplayShopPage page) => pages.TryGetValue(type, out page);

        public bool TryGet(byte type, ushort id, out ShopRecord record)
        {
            record = null;
            if (!pages.TryGetValue(type, out GameplayShopPage page)) return false;
            foreach (ShopRecord item in page.Items)
            {
                if (item.Id != id) continue;
                record = item;
                return true;
            }
            return false;
        }

        public bool ApplyPurchase(byte type, ushort id, ushort buyCount)
        {
            if (!pages.TryGetValue(type, out GameplayShopPage page)) return false;
            var values = new List<ShopRecord>(page.Items.Count);
            bool found = false;
            foreach (ShopRecord item in page.Items)
            {
                if (item.Id == id)
                {
                    values.Add(item.WithBuyCount(buyCount));
                    found = true;
                }
                else values.Add(item);
            }
            if (!found) return false;
            pages[type] = new GameplayShopPage(page.Type, page.RefreshTimes, page.FreeRefreshTimes,
                RemainingSeconds(page.RefreshDeadlineUnix), 0, values);
            Changed?.Invoke();
            return true;
        }

        public bool HasAll(params byte[] types)
        {
            if (types == null || types.Length == 0) return false;
            foreach (byte type in types)
                if (!pages.TryGetValue(type, out GameplayShopPage page) || page.Items.Count == 0)
                    return false;
            return true;
        }

        public int TotalItemCount(params byte[] types)
        {
            int total = 0;
            foreach (byte type in types ?? Array.Empty<byte>())
                if (pages.TryGetValue(type, out GameplayShopPage page)) total += page.Items.Count;
            return total;
        }

        public void Clear()
        {
            pages.Clear();
            Changed?.Invoke();
        }

        private static ushort RemainingSeconds(uint deadline)
        {
            if (deadline == 0) return 0;
            uint now = checked((uint)DateTimeOffset.UtcNow.ToUnixTimeSeconds());
            return checked((ushort)Math.Min(ushort.MaxValue, deadline > now ? deadline - now : 0));
        }
    }
}
