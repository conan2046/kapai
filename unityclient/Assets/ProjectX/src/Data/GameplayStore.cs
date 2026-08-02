using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class GameplayRecord
    {
        public GameplayRecord(GameplayDefinition definition, ushort playerLevel)
        {
            Definition = definition ?? throw new ArgumentNullException(nameof(definition));
            IsOpen = playerLevel >= definition.OpenLevel;
        }

        public GameplayDefinition Definition { get; }
        public bool IsOpen { get; }
        public bool HasHotPoint { get; internal set; }
    }

    public sealed class GameplayStore
    {
        private static readonly Dictionary<ushort, int> HotPointToFunction = new Dictionary<ushort, int>
        {
            { 101, 6 }, { 51, 8 }, { 103, 9 }
        };

        private readonly List<GameplayRecord> items = new List<GameplayRecord>();
        private readonly Dictionary<int, bool> hotPointCache = new Dictionary<int, bool>();

        public event Action Changed;
        public IReadOnlyList<GameplayRecord> Items => items;
        public int Count => items.Count;
        public int OpenCount => items.Count(value => value.IsOpen);
        public bool HasHotPoint => items.Any(value => value.HasHotPoint);

        public void Load(IEnumerable<GameplayDefinition> values, ushort playerLevel)
        {
            items.Clear();
            if (values != null) items.AddRange(values.Select(value => new GameplayRecord(value, playerLevel)));
            foreach (GameplayRecord item in items)
                item.HasHotPoint = hotPointCache.TryGetValue(item.Definition.Id, out bool visible) && visible;
            Changed?.Invoke();
        }

        public void SetHotPoint(ushort type, bool visible)
        {
            if (!HotPointToFunction.TryGetValue(type, out int functionId)) return;
            SetFunctionHotPoint(functionId, visible);
        }

        public void SetFunctionHotPoint(int functionId, bool visible)
        {
            hotPointCache[functionId] = visible;
            GameplayRecord value = items.FirstOrDefault(item => item.Definition.Id == functionId);
            if (value == null || value.HasHotPoint == visible) return;
            value.HasHotPoint = visible;
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear();
            hotPointCache.Clear();
            Changed?.Invoke();
        }
    }
}
