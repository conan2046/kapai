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

        public event Action Changed;
        public IReadOnlyList<GameplayRecord> Items => items;
        public GameplayRecord Selected { get; private set; }
        public int Count => items.Count;
        public int OpenCount => items.Count(value => value.IsOpen);
        public bool HasHotPoint => items.Any(value => value.HasHotPoint);

        public void Load(IEnumerable<GameplayDefinition> values, ushort playerLevel)
        {
            items.Clear();
            if (values != null) items.AddRange(values.Select(value => new GameplayRecord(value, playerLevel)));
            Selected = null;
            Changed?.Invoke();
        }

        public bool Select(int functionId)
        {
            GameplayRecord value = items.FirstOrDefault(item => item.Definition.Id == functionId);
            if (value == null) return false;
            Selected = value;
            Changed?.Invoke();
            return true;
        }

        public void SetHotPoint(ushort type, bool visible)
        {
            if (!HotPointToFunction.TryGetValue(type, out int functionId)) return;
            GameplayRecord value = items.FirstOrDefault(item => item.Definition.Id == functionId);
            if (value == null || value.HasHotPoint == visible) return;
            value.HasHotPoint = visible;
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear();
            Selected = null;
            Changed?.Invoke();
        }
    }
}
