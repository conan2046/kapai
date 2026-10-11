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
        [JsonProperty("realm")] public int Realm { get; private set; }
        [JsonProperty("stage")] public int Stage { get; private set; }
        [JsonProperty("next_id")] public int NextId { get; private set; }
        [JsonProperty("need_exp")] public long RequiredExperience { get; private set; }
        [JsonProperty("exp")] public int ExperiencePerSecond { get; private set; }
        [JsonProperty("upgrade_probability")] public int Probability { get; private set; }
        [JsonProperty("thunder_number")] public int[] ThunderCount { get; private set; }
        [JsonProperty("thunder_damage")] public int[] ThunderDamage { get; private set; }
        [JsonProperty("fail_upgrade")] public int FailurePenalty { get; private set; }
        [JsonProperty("Threshold")] public int FailureThreshold { get; private set; }
        [JsonProperty("visual_stage")] public int VisualStage { get; private set; }
        [JsonProperty("attr")] public int[][] Attributes { get; private set; }
        [JsonProperty("icon")] public string Icon { get; private set; }

        public bool IsBreakthrough => Stage == 10 && NextId != 0;

        private static int Value(int[][] values, int row, int column) =>
            values != null && row >= 0 && row < values.Length && values[row] != null
            && column >= 0 && column < values[row].Length ? values[row][column] : 0;
    }

    public sealed class JingJieConfigData
    {
        private readonly Dictionary<int, JingJieDefinition> byId;

        public JingJieConfigData()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/jingjie");
            if (asset == null)
                throw new InvalidOperationException("JingJie authoritative config is missing: Resources/ProjectXData/Configs/jingjie.json");
            JingJieDefinition[] values = JsonConvert.DeserializeObject<JingJieDefinition[]>(asset.text)
                ?? Array.Empty<JingJieDefinition>();
            byId = values.ToDictionary(value => value.Id);
            if (byId.Count != 550) throw new InvalidOperationException("Unity JingJie must contain 550 stages.");
            for (int id = 1; id <= byId.Count; id++)
            {
                if (!byId.TryGetValue(id, out JingJieDefinition value))
                    throw new InvalidOperationException($"JingJie config sequence is missing id={id}.");
                if (value.Realm != (id-1)/10+1 || value.Stage != (id-1)%10+1
                    || value.NextId != (id==550?0:id+1) || value.RequiredExperience<=0 || value.ExperiencePerSecond<=0
                    || value.Attributes == null || value.Attributes.Any(attribute=>attribute==null||attribute.Length!=2))
                    throw new InvalidOperationException($"Invalid Unity JingJie definition: id={id}");
            }
        }

        public int Count => byId.Count;
        public IReadOnlyList<JingJieDefinition> Items => byId.Values.OrderBy(value => value.Id).ToArray();
        public bool TryGet(int id, out JingJieDefinition value) => byId.TryGetValue(id, out value);
        public JingJieDefinition Get(int id) => byId.TryGetValue(id, out JingJieDefinition value)
            ? value : throw new InvalidOperationException($"JingJie config is missing id={id}.");
    }
}
