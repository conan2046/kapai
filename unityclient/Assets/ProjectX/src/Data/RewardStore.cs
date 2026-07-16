using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct RewardRecord
    {
        public RewardRecord(int type, uint id, uint amount, string name, int picture, int quality)
        {
            Type = type;
            Id = id;
            Amount = amount;
            Name = string.IsNullOrEmpty(name) ? $"奖励 #{id}" : name;
            Picture = picture;
            Quality = quality;
        }

        public int Type { get; }
        public uint Id { get; }
        public uint Amount { get; }
        public string Name { get; }
        public int Picture { get; }
        public int Quality { get; }
    }

    public sealed class RewardStore
    {
        private RewardRecord[] records = Array.Empty<RewardRecord>();
        public event Action Changed;
        public string Title { get; private set; } = "获得奖励";
        public IReadOnlyList<RewardRecord> Items => records;
        public int Count => records.Length;

        public void Replace(string title, IEnumerable<RewardRecord> values)
        {
            Title = string.IsNullOrEmpty(title) ? "获得奖励" : title;
            records = (values ?? Array.Empty<RewardRecord>()).Where(value => value.Amount > 0).ToArray();
            Changed?.Invoke();
        }

        public void Clear()
        {
            Title = "获得奖励";
            records = Array.Empty<RewardRecord>();
            Changed?.Invoke();
        }
    }
}
