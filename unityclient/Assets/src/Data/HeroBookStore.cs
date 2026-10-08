using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct HeroBookEntry
    {
        public HeroBookEntry(int heroId, int star, int score)
        {
            HeroId = heroId;
            Star = star;
            Score = score;
        }

        public int HeroId { get; }
        public int Star { get; }
        public int Score { get; }
    }

    public readonly struct HeroBookAttribute
    {
        public HeroBookAttribute(int type, long value)
        {
            Type = type;
            Value = value;
        }

        public int Type { get; }
        public long Value { get; }
    }

    public sealed class HeroBookUpgradeResult
    {
        public HeroBookUpgradeResult(int heroId, int star, int addedScore, int bookLevel,
            IEnumerable<HeroBookAttribute> cardAttributes,
            IEnumerable<HeroBookAttribute> levelAttributes, bool levelAdvanced)
        {
            HeroId = heroId;
            Star = star;
            AddedScore = addedScore;
            BookLevel = bookLevel;
            CardAttributes = (cardAttributes ?? Array.Empty<HeroBookAttribute>()).ToArray();
            LevelAttributes = (levelAttributes ?? Array.Empty<HeroBookAttribute>()).ToArray();
            LevelAdvanced = levelAdvanced;
        }

        public int HeroId { get; }
        public int Star { get; }
        public int AddedScore { get; }
        public int BookLevel { get; }
        public IReadOnlyList<HeroBookAttribute> CardAttributes { get; }
        public IReadOnlyList<HeroBookAttribute> LevelAttributes { get; }
        public bool LevelAdvanced { get; }
    }

    public sealed class HeroBookStore
    {
        private readonly Dictionary<int, HeroBookEntry> entries = new Dictionary<int, HeroBookEntry>();
        private readonly Dictionary<int, long> heroAttributes = new Dictionary<int, long>();
        private readonly Dictionary<int, long> scoreAttributes = new Dictionary<int, long>();

        public event Action Changed;
        public event Action<HeroBookUpgradeResult> UpgradeCompleted;

        public int Level { get; private set; }
        public long Score { get; private set; }
        public long NextLevelStart { get; private set; }
        public long NextLevelEnd { get; private set; }
        public IReadOnlyDictionary<int, HeroBookEntry> Entries => entries;
        public IReadOnlyDictionary<int, long> HeroAttributes => heroAttributes;
        public IReadOnlyDictionary<int, long> ScoreAttributes => scoreAttributes;

        public void Replace(int level, long score, long nextLevelStart, long nextLevelEnd,
            IEnumerable<HeroBookEntry> heroEntries, IEnumerable<HeroBookAttribute> bookAttributes,
            IEnumerable<HeroBookAttribute> levelAttributes)
        {
            Level = Math.Max(0, level);
            Score = Math.Max(0, score);
            NextLevelStart = Math.Max(0, nextLevelStart);
            NextLevelEnd = Math.Max(0, nextLevelEnd);
            entries.Clear();
            foreach (HeroBookEntry entry in heroEntries ?? Array.Empty<HeroBookEntry>())
                if (entry.HeroId > 0) entries[entry.HeroId] = entry;
            ReplaceAttributes(heroAttributes, bookAttributes);
            ReplaceAttributes(scoreAttributes, levelAttributes);
            Changed?.Invoke();
        }

        public void ApplyUpgrade(int heroId, int star, int addedScore, int bookLevel,
            IEnumerable<HeroBookAttribute> cardAttributes,
            IEnumerable<HeroBookAttribute> levelAttributes)
        {
            int oldLevel = Level;
            int oldScore = entries.TryGetValue(heroId, out HeroBookEntry oldEntry) ? oldEntry.Score : 0;
            entries[heroId] = new HeroBookEntry(heroId, star, oldScore + Math.Max(0, addedScore));
            Score += Math.Max(0, addedScore);
            Level = Math.Max(Level, bookLevel);
            HeroBookAttribute[] card = (cardAttributes ?? Array.Empty<HeroBookAttribute>()).ToArray();
            HeroBookAttribute[] levelAttrs = (levelAttributes ?? Array.Empty<HeroBookAttribute>()).ToArray();
            AddAttributes(heroAttributes, card);
            AddAttributes(scoreAttributes, levelAttrs);
            var result = new HeroBookUpgradeResult(heroId, star, addedScore, Level,
                card, levelAttrs, Level > oldLevel);
            Changed?.Invoke();
            UpgradeCompleted?.Invoke(result);
        }

        public bool TryGet(int heroId, out HeroBookEntry entry) => entries.TryGetValue(heroId, out entry);

        public void Clear()
        {
            Level = 0;
            Score = 0;
            NextLevelStart = 0;
            NextLevelEnd = 0;
            entries.Clear();
            heroAttributes.Clear();
            scoreAttributes.Clear();
            Changed?.Invoke();
        }

        private static void ReplaceAttributes(IDictionary<int, long> target,
            IEnumerable<HeroBookAttribute> values)
        {
            target.Clear();
            foreach (HeroBookAttribute value in values ?? Array.Empty<HeroBookAttribute>())
                target[value.Type] = value.Value;
        }

        private static void AddAttributes(IDictionary<int, long> target,
            IEnumerable<HeroBookAttribute> values)
        {
            foreach (HeroBookAttribute value in values ?? Array.Empty<HeroBookAttribute>())
                target[value.Type] = (target.TryGetValue(value.Type, out long old) ? old : 0) + value.Value;
        }
    }
}
