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
        public uint SnapshotUnixSeconds { get; set; }
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
        public bool HasAuthoritativeState { get; private set; }
        public byte PendingKind { get; private set; }
        public void SetPending(int kind) { PendingKind = checked((byte)kind); }
        public int Count => pools.Count;
        public bool HasFreeDraw => pools.Any(value => value.FreeTimes > 0 && value.FreeCooldownSeconds == 0);
        public uint RemainingCooldown(int kind, uint now)
        {
            DrawPoolRecord pool = pools.FirstOrDefault(value => value.Kind == kind);
            if (pool == null) return 0;
            if (pool.SnapshotUnixSeconds == 0 && now > 0) pool.SnapshotUnixSeconds = now;
            uint elapsed = now > pool.SnapshotUnixSeconds ? now - pool.SnapshotUnixSeconds : 0;
            return pool.FreeCooldownSeconds > elapsed ? pool.FreeCooldownSeconds - elapsed : 0;
        }
        public bool CanFreeDraw(int kind, uint now) => HasAuthoritativeState && now > 0 && kind >= 1 && kind <= 2
            && PendingKind != kind && pools.Any(value => value.Kind == kind && value.FreeTimes > 0)
            && RemainingCooldown(kind, now) == 0;
        public bool HasFreeDrawAt(uint now) => pools.Any(value => CanFreeDraw(value.Kind, now));

        public void ReplacePools(IEnumerable<DrawPoolRecord> values, uint snapshotUnixSeconds)
        {
            HasAuthoritativeState = true;
            pools.Clear();
            if (values != null) pools.AddRange(values.OrderBy(value => value.Kind));
            foreach (DrawPoolRecord pool in pools) pool.SnapshotUnixSeconds = snapshotUnixSeconds;
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
                    pool.SnapshotUnixSeconds = snapshotUnixSeconds;
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
            HasAuthoritativeState = false; PendingKind = 0;
            pools.Clear();
            LastResult = null;
            SnapshotUnixSeconds = 0;
            Changed?.Invoke();
        }
    }
}
