using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    [Serializable]
    public sealed class JingJieDefinition
    {
        [JsonProperty("jingjie_id")] public int Id { get; private set; }
        [JsonProperty("name")] public string Name { get; private set; }
        [JsonProperty("quality")] public int Quality { get; private set; }
        [JsonProperty("level_limit")] public int LevelLimit { get; private set; }
        [JsonProperty("zhanli_limit")] public long PowerLimit { get; private set; }
        [JsonProperty("tupo_cost")] public int[][] Costs { get; private set; }
        [JsonProperty("attr")] public int[][] Attributes { get; private set; }
        [JsonProperty("icon")] public string Icon { get; private set; }

        public int MaterialId => Costs?
            .FirstOrDefault(cost => cost != null && cost.Length == 3 && cost[0] > 0 && cost[0] < 60000)?[0] ?? 0;
        public int MaterialAmount => Costs?
            .FirstOrDefault(cost => cost != null && cost.Length == 3 && cost[0] > 0 && cost[0] < 60000)?[2] ?? 0;
        public int GoldAmount => Costs?
            .Where(cost => cost != null && cost.Length == 3 && cost[0] == 60000)
            .Sum(cost => cost[2]) ?? 0;

        private static int Value(int[][] values, int row, int column) =>
            values != null && row >= 0 && row < values.Length && values[row] != null
            && column >= 0 && column < values[row].Length ? values[row][column] : 0;
    }

    public sealed class JingJieConfigData
    {
        private readonly Dictionary<int, JingJieDefinition> byId;

        public JingJieConfigData()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/jingjie");
            if (asset == null)
                throw new InvalidOperationException("JingJie authoritative config is missing: Resources/Configs/jingjie.json");
            JingJieDefinition[] values = JsonConvert.DeserializeObject<JingJieDefinition[]>(asset.text)
                ?? Array.Empty<JingJieDefinition>();
            byId = values.ToDictionary(value => value.Id);
            if (byId.Count == 0) throw new InvalidOperationException("JingJie config has no rows.");
            for (int id = 1; id <= byId.Count; id++)
            {
                if (!byId.TryGetValue(id, out JingJieDefinition value))
                    throw new InvalidOperationException($"JingJie config sequence is missing id={id}.");
                if (value.Costs == null || value.Costs.Length == 0
                    || value.Costs.Any(cost => cost == null || cost.Length != 3))
                    throw new InvalidOperationException($"JingJie id={id} cost must use [itemId,subType,amount].");
                if (value.GoldAmount <= 0)
                    throw new InvalidOperationException($"JingJie id={id} has an invalid breakthrough cost.");
            }
        }

        public int Count => byId.Count;
        public IReadOnlyList<JingJieDefinition> Items => byId.Values.OrderBy(value => value.Id).ToArray();
        public bool TryGet(int id, out JingJieDefinition value) => byId.TryGetValue(id, out value);
        public JingJieDefinition Get(int id) => byId.TryGetValue(id, out JingJieDefinition value)
            ? value : throw new InvalidOperationException($"JingJie config is missing id={id}.");
    }
}
