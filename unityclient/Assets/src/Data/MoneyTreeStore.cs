using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class MoneyTreeRecord
    {
        public MoneyTreeRecord(byte type, byte usedCount, byte freeCount, byte maxCount,
            ushort costType, uint costValue, ushort rewardType, uint rewardValue)
        {
            Type = type;
            UsedCount = usedCount;
            FreeCount = freeCount;
            MaxCount = maxCount;
            CostType = costType;
            CostValue = costValue;
            RewardType = rewardType;
            RewardValue = rewardValue;
        }

        public byte Type { get; }
        public byte UsedCount { get; }
        public byte FreeCount { get; }
        public byte MaxCount { get; }
        public ushort CostType { get; }
        public uint CostValue { get; }
        public ushort RewardType { get; }
        public uint RewardValue { get; }
        public int RemainingCount => Math.Max(0, MaxCount - UsedCount);
        public int RemainingFreeCount => Math.Max(0, FreeCount - UsedCount);
    }

    public sealed class MoneyTreeStore
    {
        private readonly Dictionary<byte, MoneyTreeRecord> records =
            new Dictionary<byte, MoneyTreeRecord>();
        private MoneyTreeRecord pendingReward;

        public event Action Changed;
        public event Action<MoneyTreeRecord> Rewarded;

        public bool HasAuthoritativeResponse { get; private set; }
        public byte PendingShakeType { get; private set; }
        public IReadOnlyDictionary<byte, MoneyTreeRecord> Records => records;

        public bool TryGet(byte type, out MoneyTreeRecord record) => records.TryGetValue(type, out record);

        public void Replace(IEnumerable<MoneyTreeRecord> values)
        {
            records.Clear();
            if (values != null)
            {
                foreach (MoneyTreeRecord value in values)
                    if (value != null) records[value.Type] = value;
            }
            HasAuthoritativeResponse = true;
            PendingShakeType = 0;
            pendingReward = null;
            Changed?.Invoke();
        }

        public bool BeginShake(byte type)
        {
            if (PendingShakeType != 0 || !records.TryGetValue(type, out MoneyTreeRecord record)
                || record.RemainingCount <= 0)
                return false;
            PendingShakeType = type;
            // The shake response contains the next tier's record. Preserve the
            // current authoritative tier so feedback shows the reward actually
            // granted by this request rather than the following shake's value.
            pendingReward = record;
            Changed?.Invoke();
            return true;
        }

        public void CompleteShake(MoneyTreeRecord value, bool success)
        {
            if (PendingShakeType == 0 || value == null || value.Type != PendingShakeType) return;
            MoneyTreeRecord completedReward = pendingReward;
            PendingShakeType = 0;
            pendingReward = null;
            if (success) records[value.Type] = value;
            Changed?.Invoke();
            if (success && completedReward != null) Rewarded?.Invoke(completedReward);
        }

        public void FailShake(byte type)
        {
            if (PendingShakeType != type) return;
            PendingShakeType = 0;
            pendingReward = null;
            Changed?.Invoke();
        }

        public void Clear()
        {
            records.Clear();
            HasAuthoritativeResponse = false;
            PendingShakeType = 0;
            pendingReward = null;
            Changed?.Invoke();
        }
    }
}
