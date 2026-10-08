using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class ResourceRecoveryStore
    {
        private readonly List<ResourceRecoveryRecord> items = new List<ResourceRecoveryRecord>();

        public event Action Changed;
        public IReadOnlyList<ResourceRecoveryRecord> Items => items;

        public void Replace(IEnumerable<ResourceRecoveryRecord> values)
        {
            items.Clear();
            if (values != null) items.AddRange(values);
            Changed?.Invoke();
        }

        public void Reset()
        {
            items.Clear();
            Changed?.Invoke();
        }
    }

    public sealed class ResourceRecoveryReward
    {
        public ResourceRecoveryReward(int itemId, int subtype, uint amount)
        { ItemId = itemId; Subtype = subtype; Amount = amount; }
        public int ItemId { get; }
        public int Subtype { get; }
        public uint Amount { get; }
    }

    public sealed class ResourceRecoveryRecord
    {
        public ResourceRecoveryRecord(int functionId, ushort leftTimes, int costId, int costSubtype,
            uint costAmount, IReadOnlyList<ResourceRecoveryReward> rewards)
        {
            FunctionId = functionId;
            LeftTimes = leftTimes;
            CostId = costId;
            CostSubtype = costSubtype;
            CostAmount = costAmount;
            Rewards = rewards ?? Array.Empty<ResourceRecoveryReward>();
        }
        public int FunctionId { get; }
        public ushort LeftTimes { get; }
        public int CostId { get; }
        public int CostSubtype { get; }
        public uint CostAmount { get; }
        public IReadOnlyList<ResourceRecoveryReward> Rewards { get; }
    }
}
