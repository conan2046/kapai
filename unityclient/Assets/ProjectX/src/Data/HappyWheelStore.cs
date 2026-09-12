using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class HappyWheelReward
    {
        public HappyWheelReward(ushort type, uint amount, byte featured)
        {
            Type = type;
            Amount = amount;
            Featured = featured;
        }

        public ushort Type { get; }
        public uint Amount { get; }
        public byte Featured { get; }
    }

    public sealed class HappyWheelStore
    {
        private readonly List<HappyWheelReward> rewards = new List<HappyWheelReward>();
        private readonly List<string> personalHistory = new List<string>();
        private readonly List<int> lastRewardIndexes = new List<int>();

        public event Action Changed;
        public event Action<IReadOnlyList<int>> Spun;

        public bool HasAuthoritativeResponse { get; private set; }
        public int PendingDrawType { get; private set; } = -1;
        public uint Score { get; private set; }
        public uint ActivitySeconds { get; private set; }
        public uint ResetSeconds { get; private set; }
        public ushort CostItemId { get; private set; }
        public byte SingleDrawCount { get; private set; }
        public byte SingleKeyCost { get; private set; }
        public byte MultiDrawCount { get; private set; }
        public byte MultiKeyCost { get; private set; }
        public ushort ScorePerDraw { get; private set; }
        public byte HistoryLimit { get; private set; }
        public IReadOnlyList<HappyWheelReward> Rewards => rewards;
        public IReadOnlyList<string> PersonalHistory => personalHistory;

        public void Replace(uint score, uint activitySeconds, uint resetSeconds,
            IEnumerable<HappyWheelReward> configuredRewards, IEnumerable<string> history,
            ushort costItemId, byte singleDrawCount, byte singleKeyCost,
            byte multiDrawCount, byte multiKeyCost, ushort scorePerDraw, byte historyLimit)
        {
            rewards.Clear();
            if (configuredRewards != null) rewards.AddRange(configuredRewards);
            personalHistory.Clear();
            if (history != null) personalHistory.AddRange(history);
            Score = score;
            ActivitySeconds = activitySeconds;
            ResetSeconds = resetSeconds;
            CostItemId = costItemId;
            SingleDrawCount = singleDrawCount;
            SingleKeyCost = singleKeyCost;
            MultiDrawCount = multiDrawCount;
            MultiKeyCost = multiKeyCost;
            ScorePerDraw = scorePerDraw;
            HistoryLimit = historyLimit;
            PendingDrawType = -1;
            HasAuthoritativeResponse = rewards.Count > 0 && costItemId > 0;
            Changed?.Invoke();
        }

        public bool BeginSpin(int drawType)
        {
            if (!HasAuthoritativeResponse || PendingDrawType >= 0 || drawType < 0 || drawType > 1)
                return false;
            PendingDrawType = drawType;
            Changed?.Invoke();
            return true;
        }

        public void CompleteSpin(uint score, int selectedIndex, IEnumerable<string> history,
            IEnumerable<int> rewardIndexes)
        {
            if (PendingDrawType < 0) return;
            Score = score;
            personalHistory.Clear();
            if (history != null) personalHistory.AddRange(history);
            lastRewardIndexes.Clear();
            if (rewardIndexes != null) lastRewardIndexes.AddRange(rewardIndexes);
            if (lastRewardIndexes.Count == 0 && selectedIndex >= 0) lastRewardIndexes.Add(selectedIndex);
            PendingDrawType = -1;
            Changed?.Invoke();
            Spun?.Invoke(lastRewardIndexes);
        }

        public void FailSpin()
        {
            if (PendingDrawType < 0) return;
            PendingDrawType = -1;
            Changed?.Invoke();
        }

        public void Clear()
        {
            rewards.Clear();
            personalHistory.Clear();
            lastRewardIndexes.Clear();
            HasAuthoritativeResponse = false;
            PendingDrawType = -1;
            Score = 0;
            ActivitySeconds = 0;
            ResetSeconds = 0;
            CostItemId = 0;
            SingleDrawCount = 0;
            SingleKeyCost = 0;
            MultiDrawCount = 0;
            MultiKeyCost = 0;
            ScorePerDraw = 0;
            HistoryLimit = 0;
            Changed?.Invoke();
        }
    }
}
