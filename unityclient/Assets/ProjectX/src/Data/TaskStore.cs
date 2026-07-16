using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    [Serializable]
    public sealed class TaskDefinitionCollection
    {
        public TaskDefinition[] items;
    }

    [Serializable]
    public sealed class TaskDefinition
    {
        public int id;
        public int type;
        public string title;
        public string description;
        public int target;
    }

    public readonly struct TaskRecord
    {
        public TaskRecord(int id, uint progress, byte state, TaskDefinition definition)
        {
            Id = id;
            Progress = progress;
            State = state;
            Definition = definition;
        }

        public int Id { get; }
        public uint Progress { get; }
        public byte State { get; }
        public TaskDefinition Definition { get; }
        public int Target => Math.Max(1, Definition?.target ?? 1);
        public string Title => string.IsNullOrEmpty(Definition?.title) ? $"任务 {Id}" : Definition.title;
        public string Description => Definition?.description ?? string.Empty;
    }

    public sealed class TaskStore
    {
        private readonly Dictionary<int, TaskDefinition> definitions;
        private readonly Dictionary<int, TaskRecord> records = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, string> trackedMissions = new Dictionary<int, string>();

        public TaskStore(ConfigService configs)
        {
            TaskDefinitionCollection collection = configs.Load<TaskDefinitionCollection>("Config/daily_tasks");
            definitions = (collection.items ?? Array.Empty<TaskDefinition>())
                .GroupBy(item => item.id)
                .ToDictionary(group => group.Key, group => group.First());
        }

        public event Action Changed;
        public int Count => records.Count;
        public int TrackedMissionCount => trackedMissions.Count;
        public bool HasClaimable => records.Values.Any(item => item.State == 1);
        public IReadOnlyList<TaskRecord> Items => records.Values
            .OrderBy(item => item.State == 1 ? 0 : item.State == 0 ? 1 : 2)
            .ThenBy(item => item.Id)
            .ToArray();

        public void Replace(IEnumerable<TaskRecord> values)
        {
            records.Clear();
            foreach (TaskRecord value in values ?? Array.Empty<TaskRecord>()) records[value.Id] = value;
            Changed?.Invoke();
        }

        public TaskRecord CreateRecord(int id, uint progress, byte state)
        {
            definitions.TryGetValue(id, out TaskDefinition definition);
            return new TaskRecord(id, progress, state, definition);
        }

        public void Upsert(int id, uint progress, byte state)
        {
            records[id] = CreateRecord(id, progress, state);
            Changed?.Invoke();
        }

        public bool TryGet(int id, out TaskRecord record) => records.TryGetValue(id, out record);

        public void MarkClaimed(int id)
        {
            if (!records.TryGetValue(id, out TaskRecord record)) return;
            records[id] = CreateRecord(id, record.Progress, 2);
            Changed?.Invoke();
        }

        public void UpsertTrackedMission(int id, string name)
        {
            trackedMissions[id] = name ?? string.Empty;
        }

        public void RemoveTrackedMission(int id) => trackedMissions.Remove(id);

        public void Clear()
        {
            records.Clear();
            trackedMissions.Clear();
            Changed?.Invoke();
        }
    }
}
