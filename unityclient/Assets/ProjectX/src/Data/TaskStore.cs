using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

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
        public int daily;
        public int show;
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
        public string pictureName;
        public int quality;
        public bool isFaBao;
    }

    [Serializable]
    internal sealed class FormalTaskDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("daily")] public int Daily { get; set; }
        [JsonProperty("show")] public int Show { get; set; }
        [JsonProperty("des")] public string Description { get; set; }
        [JsonProperty("condition")] public int[] Condition { get; set; }
        [JsonProperty("reward")] public int[][] Rewards { get; set; }
        [JsonProperty("jump")] public int Jump { get; set; }
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
        public string Title => Type == 0 ? "活跃度奖励" : Type == 3 ? "寻宝奖励" : "每日任务";
        public string Description => string.IsNullOrEmpty(Definition?.des) ? $"任务 {Id}" : Definition.des;
        public IReadOnlyList<TaskRewardDefinition> Rewards =>
            Definition?.rewards ?? Array.Empty<TaskRewardDefinition>();
    }

    public sealed class TaskStore
    {
        private readonly Dictionary<int, TaskDefinition> definitions;
        private readonly Dictionary<int, TaskRecord> dailyRecords = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, TaskRecord> activityBoxes = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, TaskRecord> xunBaoRecords = new Dictionary<int, TaskRecord>();
        private readonly Dictionary<int, string> trackedMissions = new Dictionary<int, string>();

        public TaskStore(ConfigService configs, EquipmentCatalog equipmentCatalog)
        {
            TaskDefinitionCollection collection = configs.Load<TaskDefinitionCollection>("Config/daily_tasks");
            definitions = (collection.items ?? Array.Empty<TaskDefinition>())
                .GroupBy(item => item.id)
                .ToDictionary(group => group.Key, group => group.First());
            LoadFormalXunBaoDefinitions(equipmentCatalog ?? throw new ArgumentNullException(nameof(equipmentCatalog)));
        }

        public event Action Changed;
        public int Count => dailyRecords.Count;
        public int ActivityBoxCount => activityBoxes.Count;
        public int XunBaoCount => xunBaoRecords.Count;
        public uint ActivityValue => activityBoxes.Count == 0 ? 0u : activityBoxes.Values.Max(item => item.Progress);
        public int TrackedMissionCount => trackedMissions.Count;
        public bool HasClaimable => dailyRecords.Values.Any(item => item.State == 1)
            || activityBoxes.Values.Any(item => item.State == 1)
            || xunBaoRecords.Values.Any(item => item.State == 1);
        public IReadOnlyList<TaskRecord> Items => dailyRecords.Values
            .OrderBy(item => item.State == 1 ? 0 : item.State == 0 ? 1 : 2)
            .ThenByDescending(item => item.Id)
            .ToArray();
        public IReadOnlyList<TaskRecord> ActivityBoxes => activityBoxes.Values
            .OrderBy(item => item.Target)
            .ToArray();
        public IReadOnlyList<TaskRecord> XunBaoItems
        {
            get
            {
                TaskRecord[] visible = xunBaoRecords.Values
                    .Where(item => item.Definition == null || item.Definition.show == 0
                        || xunBaoRecords.TryGetValue(item.Definition.show, out TaskRecord previous)
                        && previous.State == 2)
                    .ToArray();
                HashSet<int> superseded = new HashSet<int>(visible
                    .Where(item => item.Definition != null && item.Definition.show > 0)
                    .Select(item => item.Definition.show));
                return visible.Where(item => !superseded.Contains(item.Id))
                    .OrderBy(item => item.State == 1 ? 0 : item.State == 0 ? 1 : 2)
                    .ThenBy(item => item.Id)
                    .ToArray();
            }
        }

        public void Replace(int type, IEnumerable<TaskRecord> values)
        {
            Dictionary<int, TaskRecord> target = RecordsFor(type);
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
            RecordsFor(type)[id] = CreateRecord(id, progress, state);
            Changed?.Invoke();
        }

        public bool TryGet(int type, int id, out TaskRecord record) =>
            RecordsFor(type).TryGetValue(id, out record);

        public void UpsertByDefinition(int id, uint progress, byte state)
        {
            definitions.TryGetValue(id, out TaskDefinition definition);
            Upsert(definition?.type ?? 2, id, progress, state);
        }

        public void MarkClaimed(int type, int id)
        {
            Dictionary<int, TaskRecord> target = RecordsFor(type);
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
            xunBaoRecords.Clear();
            trackedMissions.Clear();
            Changed?.Invoke();
        }

        private Dictionary<int, TaskRecord> RecordsFor(int type) =>
            type == 0 ? activityBoxes : type == 3 ? xunBaoRecords : dailyRecords;

        private void LoadFormalXunBaoDefinitions(EquipmentCatalog equipmentCatalog)
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/daily");
            if (asset == null)
                throw new InvalidOperationException("Formal task config is missing: Resources/Configs/daily.json");
            FormalTaskDefinition[] values = JsonConvert.DeserializeObject<FormalTaskDefinition[]>(asset.text)
                ?? Array.Empty<FormalTaskDefinition>();
            foreach (FormalTaskDefinition value in values.Where(item => item != null && item.Type == 3))
            {
                definitions[value.Id] = new TaskDefinition
                {
                    id = value.Id,
                    type = value.Type,
                    daily = value.Daily,
                    show = value.Show,
                    des = value.Description,
                    condition = value.Condition,
                    rewards = (value.Rewards ?? Array.Empty<int[]>()).Select(reward =>
                        CreateReward(reward, equipmentCatalog)).Where(reward => reward != null).ToArray(),
                    jump = value.Jump,
                };
            }
        }

        private static TaskRewardDefinition CreateReward(int[] reward, EquipmentCatalog equipmentCatalog)
        {
            if (reward == null || reward.Length < 3) return null;
            int id = reward[0];
            int subtype = reward[1];
            if (id == 60028 && subtype > 0)
            {
                EquipmentDefinition faBao = equipmentCatalog.GetFaBao(subtype);
                return new TaskRewardDefinition
                {
                    id = id,
                    subtype = subtype,
                    amount = unchecked((uint)Math.Max(0, reward[2])),
                    name = faBao.Name,
                    pictureName = faBao.Picture,
                    quality = faBao.Quality,
                    isFaBao = true,
                };
            }
            EquipmentMaterialDefinition item = equipmentCatalog.GetItem(id);
            return new TaskRewardDefinition
            {
                id = id,
                subtype = subtype,
                amount = unchecked((uint)Math.Max(0, reward[2])),
                name = item?.Name ?? $"物品 #{id}",
                picture = item?.Picture ?? 0,
                quality = item?.Quality ?? 0,
                isFaBao = false,
            };
        }
    }
}
