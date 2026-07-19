using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
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
        [JsonProperty("atrr_qianghua")] public JToken StrengthAttributeData { get; set; }

        public int[] GetPrimaryStrengthAttribute()
        {
            if (!(StrengthAttributeData is JArray values) || values.Count == 0)
                return Array.Empty<int>();
            JArray pair = values[0] as JArray ?? values;
            return pair.Count >= 2 ? new[] { pair[0].Value<int>(), pair[1].Value<int>() } : Array.Empty<int>();
        }

        public static EquipmentDefinition Missing(int id, HeroEquipmentKind kind) => new EquipmentDefinition
        {
            Id = id,
            Name = kind == HeroEquipmentKind.FaBao ? $"法宝 #{id}" : $"装备 #{id}",
            Part = 0,
            Picture = string.Empty,
            Description = "配置缺失",
        };
    }

    [Serializable]
    public sealed class EquipmentStrengthDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("cost")] public int[] Cost { get; set; }
    }

    public sealed class EquipmentCatalog
    {
        private readonly Dictionary<int, EquipmentDefinition> equipment = new Dictionary<int, EquipmentDefinition>();
        private readonly Dictionary<int, EquipmentDefinition> faBao = new Dictionary<int, EquipmentDefinition>();
        private readonly Dictionary<int, EquipmentStrengthDefinition> strength = new Dictionary<int, EquipmentStrengthDefinition>();

        public EquipmentCatalog()
        {
            Load("Configs/equip", equipment);
            Load("Configs/fabao", faBao);
            LoadStrength();
        }

        public EquipmentDefinition GetEquipment(int id)
            => equipment.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.Equipment);

        public EquipmentDefinition GetFaBao(int id)
            => faBao.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.FaBao);

        public int GetStrengthCost(int nextLevel, int quality)
        {
            if (!strength.TryGetValue(nextLevel, out EquipmentStrengthDefinition value)
                || value.Cost == null || value.Cost.Length < 3) return 0;
            int[] ratios = { 0, 10000, 5000, 7500, 10000, 12500, 15000, 20000 };
            int ratio = quality >= 1 && quality < ratios.Length ? ratios[quality] : 10000;
            return checked(value.Cost[2] * ratio / 10000);
        }

        public int MaxStrengthLevel => strength.Count;

        public void Clear() { equipment.Clear(); faBao.Clear(); strength.Clear(); }

        private void LoadStrength()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/equip_qianghua");
            if (asset == null) throw new InvalidOperationException("Equipment strength config is missing: Resources/Configs/equip_qianghua.json");
            EquipmentStrengthDefinition[] values = JsonConvert.DeserializeObject<EquipmentStrengthDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentStrengthDefinition>();
            foreach (EquipmentStrengthDefinition value in values)
                if (value != null && value.Level > 0) strength[value.Level] = value;
            ClientLog.Info("Config", "Loaded Configs/equip_qianghua", $"{strength.Count} records");
        }

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
