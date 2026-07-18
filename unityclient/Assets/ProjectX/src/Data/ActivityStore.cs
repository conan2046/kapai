using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class ActivityListRecord
    {
        public uint Tag { get; set; }
        public string Name { get; set; }
        public bool HasHotPoint { get; set; }
        public bool IsNew { get; set; }
        public uint RemainingSeconds { get; set; }
    }

    public sealed class ActivityRewardRecord
    {
        public ushort Type { get; set; }
        public uint Amount { get; set; }
        public string Name { get; set; }
        public int Picture { get; set; }
        public int Quality { get; set; }
    }

    public sealed class DailyRechargeActivityState
    {
        public bool WeChatRewardVisible { get; set; }
        public bool Recharged { get; set; }
        public bool Claimed { get; set; }
        public bool WeChatRecharged { get; set; }
        public bool WeChatClaimed { get; set; }
        public List<ActivityRewardRecord> Rewards { get; } = new List<ActivityRewardRecord>();
    }

    public sealed class ActivityStore
    {
        private readonly List<ActivityListRecord> items = new List<ActivityListRecord>();

        public event Action Changed;
        public IReadOnlyList<ActivityListRecord> Items => items;
        public DailyRechargeActivityState DailyRecharge { get; private set; }
        public uint SelectedTag { get; private set; }
        public uint ListSnapshotUnixSeconds { get; private set; }
        public int Count => items.Count;
        public bool HasHotPoint => items.Any(value => value.HasHotPoint);

        public void ReplaceList(IEnumerable<ActivityListRecord> values, uint snapshotUnixSeconds)
        {
            items.Clear();
            if (values != null) items.AddRange(values);
            ListSnapshotUnixSeconds = snapshotUnixSeconds;
            if (items.All(value => value.Tag != SelectedTag))
                SelectedTag = items.Count == 0 ? 0 : items[0].Tag;
            Changed?.Invoke();
        }

        public void Select(uint tag)
        {
            if (SelectedTag == tag) return;
            SelectedTag = tag;
            Changed?.Invoke();
        }

        public void SetDailyRecharge(DailyRechargeActivityState value)
        {
            DailyRecharge = value;
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear();
            DailyRecharge = null;
            SelectedTag = 0;
            ListSnapshotUnixSeconds = 0;
            Changed?.Invoke();
        }
    }
}
