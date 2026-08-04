using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public enum FengShenStageState
    {
        Passed,
        Current,
        Locked
    }

    public readonly struct FengShenRewardRecord
    {
        public FengShenRewardRecord(ushort type, uint id, uint amount, string name)
        {
            Type = type;
            Id = id;
            Amount = amount;
            Name = name ?? string.Empty;
        }

        public ushort Type { get; }
        public uint Id { get; }
        public uint Amount { get; }
        public string Name { get; }
    }

    public sealed class FengShenStoryStore
    {
        public const int MaxChapterCount = 371;
        public const int MaxChallengeCount = 5;
        public const int PageChapterCount = 6;

        public event Action Changed;
        public uint ChapterId { get; private set; }
        public uint LevelId { get; private set; }
        public byte RemainingChallenges { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }
        public int SelectedChapter { get; private set; }
        public int FirstVisibleChapter { get; private set; } = 1;
        public bool ChallengePending { get; private set; }
        public bool IsDisconnected { get; private set; }
        public string LastChallengeError { get; private set; } = string.Empty;
        public IReadOnlyList<FengShenRewardRecord> RewardPush => rewardPush;

        private readonly List<FengShenRewardRecord> rewardPush = new List<FengShenRewardRecord>();

        public int CurrentChapter => HasAuthoritativeResponse ? checked((int)ChapterId + 1) : 0;
        public int HighestSelectableChapter => Math.Min(MaxChapterCount, Math.Max(1, CurrentChapter));

        public void Replace(uint chapterId, uint levelId, byte remainingChallenges)
        {
            ChapterId = chapterId;
            LevelId = levelId;
            RemainingChallenges = remainingChallenges;
            HasAuthoritativeResponse = true;
            ChallengePending = false;
            IsDisconnected = false;
            LastChallengeError = string.Empty;
            SelectedChapter = CurrentChapter;
            FirstVisibleChapter = InitialViewportStartFor(SelectedChapter);
            Changed?.Invoke();
        }

        public bool SelectChapter(int chapter)
        {
            if (!HasAuthoritativeResponse || chapter < 1 || chapter > HighestSelectableChapter) return false;
            SelectedChapter = chapter;
            if (chapter < FirstVisibleChapter || chapter >= FirstVisibleChapter + PageChapterCount)
                FirstVisibleChapter = PageStartFor(chapter);
            Changed?.Invoke();
            return true;
        }

        public bool PageLeft()
        {
            int next = Math.Max(1, FirstVisibleChapter - PageChapterCount);
            if (next == FirstVisibleChapter) return false;
            FirstVisibleChapter = next;
            Changed?.Invoke();
            return true;
        }

        public bool PageRight()
        {
            int lastStart = PageStartFor(HighestSelectableChapter);
            int next = Math.Min(lastStart, FirstVisibleChapter + PageChapterCount);
            if (next == FirstVisibleChapter) return false;
            FirstVisibleChapter = next;
            Changed?.Invoke();
            return true;
        }

        public FengShenStageState GetStageState(int chapter, int level)
        {
            uint stageId = ToNodeId(chapter, level);
            if (!HasAuthoritativeResponse || stageId > LevelId) return FengShenStageState.Locked;
            if (stageId == LevelId) return FengShenStageState.Current;
            return FengShenStageState.Passed;
        }

        public bool IsChapterBoxOpened(int chapter) => HasAuthoritativeResponse
            && ToNodeId(chapter, 4) < LevelId;

        public void BeginChallenge()
        {
            ChallengePending = true;
            LastChallengeError = string.Empty;
            Changed?.Invoke();
        }

        public void SetChallengeResult(bool succeeded, string error)
        {
            ChallengePending = false;
            LastChallengeError = succeeded ? string.Empty : (error ?? string.Empty);
            Changed?.Invoke();
        }

        public void ApplyFightPush(uint chapterId, uint levelId, byte remainingChallenges,
            uint unlockedChapterId, uint unlockedLevelId)
        {
            ChapterId = unlockedChapterId;
            LevelId = unlockedLevelId;
            RemainingChallenges = remainingChallenges;
            HasAuthoritativeResponse = true;
            ChallengePending = false;
            IsDisconnected = false;
            LastChallengeError = string.Empty;
            SelectedChapter = CurrentChapter;
            FirstVisibleChapter = PageStartFor(SelectedChapter);
            Changed?.Invoke();
        }

        public void SetRewardPush(IEnumerable<FengShenRewardRecord> rewards)
        {
            rewardPush.Clear();
            if (rewards != null) rewardPush.AddRange(rewards);
            Changed?.Invoke();
        }

        public void AcknowledgeRewardPush()
        {
            rewardPush.Clear();
            Changed?.Invoke();
        }

        public void SetDisconnected()
        {
            ChallengePending = false;
            IsDisconnected = true;
            LastChallengeError = string.Empty;
            rewardPush.Clear();
            Changed?.Invoke();
        }

        public void Clear()
        {
            ChapterId = LevelId = 0;
            RemainingChallenges = 0;
            HasAuthoritativeResponse = false;
            SelectedChapter = 0;
            FirstVisibleChapter = 1;
            ChallengePending = false;
            IsDisconnected = false;
            LastChallengeError = string.Empty;
            rewardPush.Clear();
            Changed?.Invoke();
        }

        private static int PageStartFor(int chapter) =>
            ((Math.Max(1, chapter) - 1) / PageChapterCount) * PageChapterCount + 1;

        private static int InitialViewportStartFor(int chapter) =>
            Math.Max(1, Math.Min(MaxChapterCount - PageChapterCount + 1,
                Math.Max(1, chapter) - PageChapterCount + 1));

        private static uint ToNodeId(int chapter, int level)
        {
            if (chapter < 1 || chapter > MaxChapterCount || level < 1 || level > 4)
                return uint.MaxValue;
            return checked((uint)((4000 + chapter) * 10 + level));
        }
    }
}
