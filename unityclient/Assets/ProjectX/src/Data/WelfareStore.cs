using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public enum WelfareRewardState : byte { Waiting, Claimable, Claimed }

    public sealed class WelfareSignRecord
    {
        public byte Day { get; set; }
        public RewardRecord Reward { get; set; }
        public byte VipLevel { get; set; }
        public byte VipMultiple { get; set; }
        public WelfareRewardState State { get; set; }
    }

    public sealed class WelfareOnlineRecord
    {
        public byte Id { get; set; }
        public ushort CumulativeMinutes { get; set; }
        public uint RequiredSeconds { get; set; }
        public RewardRecord Reward { get; set; }
        public WelfareRewardState State { get; set; }
    }

    public sealed class WelfareStore
    {
        private readonly List<WelfareSignRecord> signs = new List<WelfareSignRecord>();
        private readonly List<WelfareOnlineRecord> online = new List<WelfareOnlineRecord>();

        public event Action Changed;
        public IReadOnlyList<WelfareSignRecord> Signs => signs;
        public IReadOnlyList<WelfareOnlineRecord> Online => online;
        public bool SignedToday { get; private set; }
        public byte SignedDays { get; private set; }
        public byte OnlineClaimedCount { get; private set; }
        public uint OnlineAccumulatedSeconds { get; private set; }
        public uint OnlineSnapshotUnixSeconds { get; private set; }
        public bool StageGoalAvailable { get; private set; }
        public bool HasClaimable => signs.Any(value => value.State == WelfareRewardState.Claimable)
            || online.Any(value => value.State == WelfareRewardState.Claimable);
        public WelfareSignRecord NextSign => signs.FirstOrDefault(value => value.State == WelfareRewardState.Claimable);

        public void ReplaceSigns(bool signedToday, byte signedDays, IEnumerable<WelfareSignRecord> values)
        {
            SignedToday = signedToday;
            SignedDays = signedDays;
            signs.Clear();
            if (values != null) signs.AddRange(values.OrderBy(value => value.Day));
            foreach (WelfareSignRecord value in signs)
                value.State = value.Day <= signedDays ? WelfareRewardState.Claimed
                    : !signedToday && value.Day == signedDays + 1 ? WelfareRewardState.Claimable
                    : WelfareRewardState.Waiting;
            Changed?.Invoke();
        }

        public void ReplaceOnline(byte claimedCount, uint accumulatedSeconds, uint snapshotUnixSeconds,
            IEnumerable<WelfareOnlineRecord> values)
        {
            OnlineClaimedCount = claimedCount;
            OnlineAccumulatedSeconds = accumulatedSeconds;
            OnlineSnapshotUnixSeconds = snapshotUnixSeconds;
            online.Clear();
            if (values != null) online.AddRange(values.OrderBy(value => value.Id));
            foreach (WelfareOnlineRecord value in online)
                value.State = value.Id <= claimedCount ? WelfareRewardState.Claimed
                    : value.Id == claimedCount + 1 && accumulatedSeconds >= value.RequiredSeconds
                        ? WelfareRewardState.Claimable : WelfareRewardState.Waiting;
            Changed?.Invoke();
        }

        public void SetStageGoalAvailable(bool available)
        {
            StageGoalAvailable = available;
            Changed?.Invoke();
        }

        public void Clear()
        {
            signs.Clear();
            online.Clear();
            SignedToday = false;
            SignedDays = OnlineClaimedCount = 0;
            OnlineAccumulatedSeconds = OnlineSnapshotUnixSeconds = 0;
            StageGoalAvailable = false;
            Changed?.Invoke();
        }
    }
}
