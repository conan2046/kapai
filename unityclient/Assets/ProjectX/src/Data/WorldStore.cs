using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class WorldChapterRecord
    {
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public ushort OpenLevel { get; set; }
        public byte MaximumStars { get; set; }
        public ushort OwnedStars { get; set; }
        public byte ClaimedBoxes { get; set; }
    }

    public sealed class WorldStarBoxRecord
    {
        public byte RequiredStars { get; set; }
        public uint RewardId { get; set; }
        public byte State { get; set; }
    }

    public sealed class WorldStageRecord
    {
        private readonly List<RewardRecord> rewards = new List<RewardRecord>();
        private readonly List<RewardRecord> currencyRewards = new List<RewardRecord>();
        private readonly List<RewardRecord> itemRewards = new List<RewardRecord>();

        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public byte Stars { get; set; }
        public byte RemainingAttempts { get; set; }
        public byte SpiritCost { get; set; }
        public byte RemainingResets { get; set; }
        public ushort ResetCost { get; set; }
        public uint NextStageId { get; set; }
        public uint RewardBoxId { get; set; }
        public byte RewardBoxState { get; set; }
        public byte FoughtCount { get; set; }
        public IReadOnlyList<RewardRecord> Rewards => rewards;
        public IReadOnlyList<RewardRecord> CurrencyRewards => currencyRewards;
        public IReadOnlyList<RewardRecord> ItemRewards => itemRewards;
        public bool IsUnlocked => Stars != byte.MaxValue;

        public void AddReward(RewardRecord reward, bool isCurrency)
        {
            if (reward.Amount == 0) return;
            rewards.Add(reward);
            (isCurrency ? currencyRewards : itemRewards).Add(reward);
        }
    }

    public sealed class WorldStore
    {
        private readonly List<WorldChapterRecord> chapters = new List<WorldChapterRecord>();
        private readonly List<WorldStageRecord> stages = new List<WorldStageRecord>();
        private readonly List<WorldStarBoxRecord> starBoxes = new List<WorldStarBoxRecord>();

        public event Action Changed;
        public IReadOnlyList<WorldChapterRecord> Chapters => chapters;
        public IReadOnlyList<WorldStageRecord> Stages => stages;
        public IReadOnlyList<WorldStarBoxRecord> StarBoxes => starBoxes;
        public byte MapType { get; private set; } = 1;
        public uint CurrentChapterId { get; private set; }
        public uint CurrentStageId { get; private set; }
        public uint SelectedChapterId { get; private set; }
        public string SelectedChapterName { get; private set; } = string.Empty;
        public uint SelectedStageId { get; private set; }
        public int ChapterCount => chapters.Count;
        public int StageCount => stages.Count;
        public WorldStageRecord SelectedStage => stages.FirstOrDefault(value => value.Id == SelectedStageId);

        public void ReplaceChapters(byte mapType, uint currentChapterId, uint currentStageId,
            IEnumerable<WorldChapterRecord> values)
        {
            MapType = mapType;
            CurrentChapterId = currentChapterId;
            CurrentStageId = currentStageId;
            chapters.Clear();
            if (values != null) chapters.AddRange(values.OrderBy(value => value.Id));
            Changed?.Invoke();
        }

        public void ReplaceStages(byte mapType, uint chapterId, string chapterName,
            IEnumerable<WorldStageRecord> values, IEnumerable<WorldStarBoxRecord> boxes)
        {
            MapType = mapType;
            SelectedChapterId = chapterId;
            SelectedChapterName = chapterName ?? string.Empty;
            stages.Clear();
            if (values != null) stages.AddRange(values);
            starBoxes.Clear();
            if (boxes != null) starBoxes.AddRange(boxes);
            WorldStageRecord preferred = stages.FirstOrDefault(value => value.Id == CurrentStageId)
                ?? stages.FirstOrDefault(value => value.IsUnlocked)
                ?? stages.FirstOrDefault();
            SelectedStageId = preferred?.Id ?? 0;
            Changed?.Invoke();
        }

        public bool SelectStage(uint stageId)
        {
            if (!stages.Any(value => value.Id == stageId)) return false;
            SelectedStageId = stageId;
            Changed?.Invoke();
            return true;
        }

        public void UpdateStageStatus(byte mapType, uint chapterId, uint stageId, byte stars,
            byte foughtCount, byte remainingResets)
        {
            MapType = mapType;
            SelectedChapterId = chapterId;
            WorldStageRecord stage = stages.FirstOrDefault(value => value.Id == stageId);
            if (stage == null) return;
            stage.Stars = stars;
            stage.FoughtCount = foughtCount;
            stage.RemainingResets = remainingResets;
            SelectedStageId = stageId;
            Changed?.Invoke();
        }

        public void ApplyBattleResult(byte foughtCount, uint foughtStageId, uint unlockedChapterId,
            uint unlockedStageId, byte stars)
        {
            WorldStageRecord stage = stages.FirstOrDefault(value => value.Id == foughtStageId);
            if (stage != null)
            {
                stage.Stars = Math.Max(stage.Stars == byte.MaxValue ? (byte)0 : stage.Stars, stars);
                stage.FoughtCount = foughtCount;
                if (stage.RemainingAttempts > 0) stage.RemainingAttempts--;
            }
            if (unlockedChapterId > 0) CurrentChapterId = unlockedChapterId;
            if (unlockedStageId > 0) CurrentStageId = unlockedStageId;
            Changed?.Invoke();
        }

        public void ApplySweep(uint stageId, byte count)
        {
            WorldStageRecord stage = stages.FirstOrDefault(value => value.Id == stageId);
            if (stage == null) return;
            stage.RemainingAttempts = (byte)Math.Max(0, stage.RemainingAttempts - count);
            stage.FoughtCount = (byte)Math.Min(byte.MaxValue, stage.FoughtCount + count);
            SelectedStageId = stageId;
            Changed?.Invoke();
        }

        public void ApplyReset(uint stageId, byte usedResets)
        {
            WorldStageRecord stage = stages.FirstOrDefault(value => value.Id == stageId);
            if (stage == null) return;
            SelectedStageId = stageId;
            Changed?.Invoke();
        }

        public void ApplyClaimedBox(uint chapterId, uint boxId)
        {
            WorldStarBoxRecord box = starBoxes.FirstOrDefault(value => value.RewardId == boxId);
            if (box != null) box.State = 2;
            WorldStageRecord stage = stages.FirstOrDefault(value => value.RewardBoxId == boxId);
            if (stage != null) stage.RewardBoxState = 2;
            WorldChapterRecord chapter = chapters.FirstOrDefault(value => value.Id == chapterId);
            if (chapter != null) chapter.ClaimedBoxes++;
            Changed?.Invoke();
        }

        public void Clear()
        {
            chapters.Clear();
            stages.Clear();
            starBoxes.Clear();
            MapType = 1;
            CurrentChapterId = CurrentStageId = SelectedChapterId = SelectedStageId = 0;
            SelectedChapterName = string.Empty;
            Changed?.Invoke();
        }
    }
}
