using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class DrawPoolRecord
    {
        public byte Kind { get; set; }
        public uint TotalDraws { get; set; }
        public uint FreeCooldownSeconds { get; set; }
        public byte FreeTimes { get; set; }
    }

    public sealed class DrawRewardRecord
    {
        public ushort Type { get; set; }
        public uint Id { get; set; }
        public uint Amount { get; set; }
        public ushort TransformItemId { get; set; }
        public uint TransformAmount { get; set; }
        public string Name { get; set; }
        public int Picture { get; set; }
        public int Quality { get; set; }
    }

    public sealed class DrawResultRecord
    {
        public byte Kind { get; set; }
        public byte DrawType { get; set; }
        public uint TotalDraws { get; set; }
        public byte FreeTimes { get; set; }
        public uint FreeCooldownSeconds { get; set; }
        public List<DrawRewardRecord> GuaranteedRewards { get; } = new List<DrawRewardRecord>();
        public List<DrawRewardRecord> Rewards { get; } = new List<DrawRewardRecord>();
    }

    public sealed class DrawStore
    {
        private readonly List<DrawPoolRecord> pools = new List<DrawPoolRecord>();

        public event Action Changed;
        public IReadOnlyList<DrawPoolRecord> Pools => pools;
        public DrawResultRecord LastResult { get; private set; }
        public uint SnapshotUnixSeconds { get; private set; }
        public int Count => pools.Count;
        public bool HasFreeDraw => pools.Any(value => value.FreeTimes > 0 && value.FreeCooldownSeconds == 0);

        public void ReplacePools(IEnumerable<DrawPoolRecord> values, uint snapshotUnixSeconds)
        {
            pools.Clear();
            if (values != null) pools.AddRange(values.OrderBy(value => value.Kind));
            SnapshotUnixSeconds = snapshotUnixSeconds;
            Changed?.Invoke();
        }

        public void SetResult(DrawResultRecord value, uint snapshotUnixSeconds)
        {
            LastResult = value ?? throw new ArgumentNullException(nameof(value));
            SnapshotUnixSeconds = snapshotUnixSeconds;
            DrawPoolRecord pool = pools.FirstOrDefault(item => item.Kind == value.Kind);
            if (pool != null)
            {
                pool.TotalDraws = value.TotalDraws;
                if (value.DrawType == 1)
                {
                    pool.FreeTimes = value.FreeTimes;
                    pool.FreeCooldownSeconds = value.FreeCooldownSeconds;
                }
            }
            Changed?.Invoke();
        }

        public void ClearResult()
        {
            LastResult = null;
            Changed?.Invoke();
        }

        public void Clear()
        {
            pools.Clear();
            LastResult = null;
            SnapshotUnixSeconds = 0;
            Changed?.Invoke();
        }
    }
}
