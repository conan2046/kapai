using System;

namespace ProjectX.Data
{
    public sealed class FengShenStoryStore
    {
        public event Action Changed;
        public uint ChapterId { get; private set; }
        public uint LevelId { get; private set; }
        public byte RemainingChallenges { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(uint chapterId, uint levelId, byte remainingChallenges)
        {
            ChapterId = chapterId;
            LevelId = levelId;
            RemainingChallenges = remainingChallenges;
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void Clear()
        {
            ChapterId = LevelId = 0;
            RemainingChallenges = 0;
            HasAuthoritativeResponse = false;
            Changed?.Invoke();
        }
    }
}
