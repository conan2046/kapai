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
        public string des;
        public int[] condition;
        public TaskRewardDefinition[] rewards;
        public int jump;
    }

    [Serializable]
    public sealed class TaskRewardDefinition
    {
        public int id;
        public int subtype;
        public uint amount;
        public string name;
        public int picture;
        public int quality;
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
        public int Type => Definition?.type ?? 2;
        public int Target => Math.Max(1, Definition?.condition != null && Definition.condition.Length > 1
            ? Definition.condition[1] : 1);
        public int Jump => Definition?.jump ?? 0;
        public string Title => Type == 0 ? "活跃度奖励" : "每日任务";
        public string Description => string.IsNullOrEmpty(Definition?.des) ? $"任务 {Id}" : Definition.des;
        public IReadOnlyList<TaskRewardDefinition> Rewards =>
            Definition?.rewards ?? Array.Empty<TaskRewardDefinition>();
    }

    public sealed class TaskStore
    {
        private readonly Dictionary<int, TaskDefinition> definitions;
        private readonly Dictionary<int, TaskRecord> dailyRecords = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, TaskRecord> activityBoxes = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, string> trackedMissions = new Dictionary<int, string>();

        public TaskStore(ConfigService configs)
        {
            TaskDefinitionCollection collection = configs.Load<TaskDefinitionCollection>("Config/daily_tasks");
            definitions = (collection.items ?? Array.Empty<TaskDefinition>())
                .GroupBy(item => item.id)
                .ToDictionary(group => group.Key, group => group.First());
        }

        public event Action Changed;
        public int Count => dailyRecords.Count;
        public int ActivityBoxCount => activityBoxes.Count;
        public uint ActivityValue => activityBoxes.Count == 0 ? 0u : activityBoxes.Values.Max(item => item.Progress);
        public int TrackedMissionCount => trackedMissions.Count;
        public bool HasClaimable => dailyRecords.Values.Any(item => item.State == 1)
            || activityBoxes.Values.Any(item => item.State == 1);
        public IReadOnlyList<TaskRecord> Items => dailyRecords.Values
            .OrderBy(item => item.State == 1 ? 0 : item.State == 0 ? 1 : 2)
            .ThenByDescending(item => item.Id)
            .ToArray();
        public IReadOnlyList<TaskRecord> ActivityBoxes => activityBoxes.Values
            .OrderBy(item => item.Target)
            .ToArray();

        public void Replace(int type, IEnumerable<TaskRecord> values)
        {
            Dictionary<int, TaskRecord> target = type == 0 ? activityBoxes : dailyRecords;
            target.Clear();
            foreach (TaskRecord value in values ?? Array.Empty<TaskRecord>()) target[value.Id] = value;
            Changed?.Invoke();
        }

        public TaskRecord CreateRecord(int id, uint progress, byte state)
        {
            definitions.TryGetValue(id, out TaskDefinition definition);
            return new TaskRecord(id, progress, state, definition);
        }

        public void Upsert(int type, int id, uint progress, byte state)
        {
            (type == 0 ? activityBoxes : dailyRecords)[id] = CreateRecord(id, progress, state);
            Changed?.Invoke();
        }

        public bool TryGet(int type, int id, out TaskRecord record) =>
            (type == 0 ? activityBoxes : dailyRecords).TryGetValue(id, out record);

        public void MarkClaimed(int type, int id)
        {
            Dictionary<int, TaskRecord> target = type == 0 ? activityBoxes : dailyRecords;
            if (!target.TryGetValue(id, out TaskRecord record)) return;
            target[id] = CreateRecord(id, record.Progress, 2);
            Changed?.Invoke();
        }

        public void UpsertTrackedMission(int id, string name)
        {
            trackedMissions[id] = name ?? string.Empty;
        }

        public void RemoveTrackedMission(int id) => trackedMissions.Remove(id);

        public void Clear()
        {
            dailyRecords.Clear();
            activityBoxes.Clear();
            trackedMissions.Clear();
            Changed?.Invoke();
        }
    }
}
