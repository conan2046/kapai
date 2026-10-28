using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    [Serializable]
    public sealed class GlobalEventDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("num")] public int Target { get; set; }
        [JsonProperty("param1")] public int Parameter1 { get; set; }
        [JsonProperty("param2")] public int Parameter2 { get; set; }
        [JsonProperty("count_start")] public int CountStart { get; set; }
        [JsonProperty("cycle")] public int Cycle { get; set; }
        [JsonProperty("enabled")] public int Enabled { get; set; }
    }

    // Shared read-only catalog for task targets and future story subscriptions.
    // Authoritative business progress remains on the server.
    public sealed class GlobalEventCatalog
    {
        private readonly Dictionary<int, GlobalEventDefinition> definitions = new Dictionary<int, GlobalEventDefinition>();
        public GlobalEventCatalog()
        {
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>("ProjectXData/Configs/event");
            if (asset == null) throw new InvalidOperationException("Global event config is missing.");
            var rows = JsonConvert.DeserializeObject<GlobalEventDefinition[]>(asset.text) ?? Array.Empty<GlobalEventDefinition>();
            foreach (var row in rows)
            {
                if (row.Id <= 0 || row.Target <= 0 || row.Enabled != 1 || definitions.ContainsKey(row.Id))
                    throw new InvalidOperationException("Invalid global event: " + row.Id);
                definitions.Add(row.Id, row);
            }
            if (definitions.Count == 0) throw new InvalidOperationException("Global event config is empty.");
        }
        public GlobalEventDefinition Get(int id)
        {
            if (!definitions.TryGetValue(id, out var value))
                throw new InvalidOperationException("Global event reference is missing: " + id);
            return value;
        }
        public int Count => definitions.Count;
    }
}
