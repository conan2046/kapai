using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    [Serializable]
    public sealed class EquipmentDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("part")] public int Part { get; set; }
        [JsonProperty("quality")] public int Quality { get; set; }
        [JsonProperty("pic")] public string Picture { get; set; }
        [JsonProperty("des")] public string Description { get; set; }
        [JsonProperty("item_from")] public string Source { get; set; }
        [JsonProperty("equip")] public int CanEquip { get; set; }
        [JsonProperty("attr")] public int[] BaseAttribute { get; set; }

        public static EquipmentDefinition Missing(int id, HeroEquipmentKind kind) => new EquipmentDefinition
        {
            Id = id,
            Name = kind == HeroEquipmentKind.FaBao ? $"法宝 #{id}" : $"装备 #{id}",
            Part = 0,
            Picture = string.Empty,
            Description = "配置缺失",
        };
    }

    public sealed class EquipmentCatalog
    {
        private readonly Dictionary<int, EquipmentDefinition> equipment = new Dictionary<int, EquipmentDefinition>();
        private readonly Dictionary<int, EquipmentDefinition> faBao = new Dictionary<int, EquipmentDefinition>();

        public EquipmentCatalog()
        {
            Load("Configs/equip", equipment);
            Load("Configs/fabao", faBao);
        }

        public EquipmentDefinition GetEquipment(int id)
            => equipment.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.Equipment);

        public EquipmentDefinition GetFaBao(int id)
            => faBao.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.FaBao);

        public void Clear() { equipment.Clear(); faBao.Clear(); }

        private static void Load(string resourcePath, IDictionary<int, EquipmentDefinition> target)
        {
            TextAsset asset = Resources.Load<TextAsset>(resourcePath);
            if (asset == null) throw new InvalidOperationException($"Equipment config is missing: Resources/{resourcePath}.json");
            EquipmentDefinition[] values = JsonConvert.DeserializeObject<EquipmentDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentDefinition>();
            foreach (EquipmentDefinition value in values)
                if (value != null && value.Id > 0) target[value.Id] = value;
            ClientLog.Info("Config", $"Loaded {resourcePath}", $"{target.Count} records");
        }
    }
}
