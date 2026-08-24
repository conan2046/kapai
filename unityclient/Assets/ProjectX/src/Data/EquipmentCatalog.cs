using System;
using System.Collections.Generic;
using System.Linq;
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
        [JsonProperty("suit")] public int Suit { get; set; }
        [JsonProperty("quality")] public int Quality { get; set; }
        [JsonProperty("pic")] public string Picture { get; set; }
        [JsonProperty("des")] public string Description { get; set; }
        [JsonProperty("item_from")] public string Source { get; set; }
        [JsonProperty("shenzhu_cost")] public int DivineCostItemId { get; set; }
        [JsonProperty("equip")] public int CanEquip { get; set; }
        [JsonProperty("exp")] public int ExperienceValue { get; set; }
        [JsonProperty("attr")] public int[] BaseAttribute { get; set; }
        [JsonProperty("atrr_qianghua")] public JToken StrengthAttributeData { get; set; }
        [JsonProperty("attr_jinglian")] public int[][] RefineAttributes { get; set; }
        [JsonProperty("attr_juexing")] public int[][] AwakenAttributes { get; set; }
        [JsonProperty("attr_shenzhu")] public int[][] DivineAttributes { get; set; }

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
    public sealed class EquipmentSuitDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("suit")] public int[][][] Effects { get; set; }
    }

    [Serializable]
    public sealed class EquipmentStrengthDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("cost")] public int[] Cost { get; set; }
    }

    [Serializable]
    public sealed class EquipmentComposeDefinition
    {
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("item")] public int[][] Items { get; set; }
        [JsonProperty("target")] public int[] Target { get; set; }
    }

    [Serializable]
    public sealed class EquipmentRefineDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("exp")] public int Experience { get; set; }
    }

    [Serializable]
    public sealed class EquipmentAwakenDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("cost")] public int[][] Cost { get; set; }
    }

    [Serializable]
    public sealed class EquipmentDivineDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("cost_count")] public int FragmentCount { get; set; }
        [JsonProperty("money")] public int[][] Money { get; set; }
    }

    [Serializable]
    public sealed class EquipmentMaterialDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("pic")] public int Picture { get; set; }
        [JsonProperty("quality")] public int Quality { get; set; }
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("sub_value")] public int[][] Values { get; set; }
        public int RefineExperience => Values != null && Values.Length > 0 && Values[0] != null && Values[0].Length > 1
            ? Values[0][1] : 0;
    }

    [Serializable]
    public sealed class EquipmentQualityDefinition
    {
        [JsonProperty("quality")] public int Quality { get; set; }
        [JsonProperty("jinglian_ratio")] public int RefineRatio { get; set; }
        [JsonProperty("fabao_qianghua")] public int FaBaoStrengthRatio { get; set; }
    }

    [Serializable]
    public sealed class FaBaoStrengthDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("exp")] public int Experience { get; set; }
    }

    [Serializable]
    public sealed class FaBaoRefineDefinition
    {
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("cost")] public int[][] Cost { get; set; }
    }

    [Serializable]
    public sealed class EquipmentMasterDefinition
    {
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("level")] public int Level { get; set; }
        [JsonProperty("condition")] public int Condition { get; set; }
        [JsonProperty("attr")] public int[][] Attributes { get; set; }
    }

    public sealed class EquipmentCatalog
    {
        private readonly Dictionary<int, EquipmentDefinition> equipment = new Dictionary<int, EquipmentDefinition>();
        private readonly Dictionary<int, EquipmentDefinition> faBao = new Dictionary<int, EquipmentDefinition>();
        private readonly Dictionary<int, EquipmentStrengthDefinition> strength = new Dictionary<int, EquipmentStrengthDefinition>();
        private readonly Dictionary<int, EquipmentSuitDefinition> suits = new Dictionary<int, EquipmentSuitDefinition>();
        private readonly Dictionary<int, int> equipmentByFragment = new Dictionary<int, int>();
        private readonly Dictionary<int, int> fragmentComposeCost = new Dictionary<int, int>();
        private readonly Dictionary<int, EquipmentRefineDefinition> refine = new Dictionary<int, EquipmentRefineDefinition>();
        private readonly Dictionary<int, EquipmentAwakenDefinition> awaken = new Dictionary<int, EquipmentAwakenDefinition>();
        private readonly Dictionary<int, EquipmentDivineDefinition> divine = new Dictionary<int, EquipmentDivineDefinition>();
        private readonly Dictionary<int, EquipmentMaterialDefinition> items = new Dictionary<int, EquipmentMaterialDefinition>();
        private readonly Dictionary<int, EquipmentMaterialDefinition> refineMaterials = new Dictionary<int, EquipmentMaterialDefinition>();
        private readonly Dictionary<int, EquipmentQualityDefinition> qualities = new Dictionary<int, EquipmentQualityDefinition>();
        private readonly Dictionary<int, FaBaoStrengthDefinition> faBaoStrength = new Dictionary<int, FaBaoStrengthDefinition>();
        private readonly Dictionary<int, FaBaoRefineDefinition> faBaoRefine = new Dictionary<int, FaBaoRefineDefinition>();
        private readonly Dictionary<int, Dictionary<int, EquipmentMasterDefinition>> masters =
            new Dictionary<int, Dictionary<int, EquipmentMasterDefinition>>();

        public EquipmentCatalog()
        {
            Load("Configs/equip", equipment);
            Load("Configs/fabao", faBao);
            LoadStrength();
            LoadSuits();
            LoadComposition();
            LoadCultivation();
            LoadFaBaoCultivation();
            LoadMasters();
        }

        public EquipmentDefinition GetEquipment(int id)
            => equipment.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.Equipment);

        public EquipmentDefinition GetFaBao(int id)
            => faBao.TryGetValue(id, out EquipmentDefinition value)
                ? value : EquipmentDefinition.Missing(id, HeroEquipmentKind.FaBao);

        public EquipmentDefinition GetEquipmentByFragment(int itemId)
        {
            return equipmentByFragment.TryGetValue(itemId, out int equipmentId)
                ? GetEquipment(equipmentId)
                : EquipmentDefinition.Missing(itemId, HeroEquipmentKind.Equipment);
        }

        public bool IsEquipmentFragment(int itemId) => equipmentByFragment.ContainsKey(itemId);
        public int GetEquipmentComposeCost(int itemId)
            => fragmentComposeCost.TryGetValue(itemId, out int value) ? value : 0;

        public EquipmentRefineDefinition GetRefine(int level)
            => refine.TryGetValue(level, out EquipmentRefineDefinition value) ? value : null;

        public EquipmentAwakenDefinition GetAwaken(int level)
            => awaken.TryGetValue(level, out EquipmentAwakenDefinition value) ? value : null;

        public EquipmentDivineDefinition GetDivine(int level)
            => divine.TryGetValue(level, out EquipmentDivineDefinition value) ? value : null;

        public int GetRefineMaterialExperience(int itemId)
            => refineMaterials.TryGetValue(itemId, out EquipmentMaterialDefinition value) ? value.RefineExperience : 0;

        public EquipmentMaterialDefinition GetItem(int itemId)
            => items.TryGetValue(itemId, out EquipmentMaterialDefinition value) ? value : null;

        public int GetRefineExperience(int level, int quality)
        {
            if (!refine.TryGetValue(level, out EquipmentRefineDefinition value)) return 0;
            int ratio = qualities.TryGetValue(quality, out EquipmentQualityDefinition definition)
                ? definition.RefineRatio : 10000;
            return checked(value.Experience * ratio / 10000);
        }

        public IReadOnlyList<int> GetRefineMaterialIds()
        {
            List<int> values = new List<int>(refineMaterials.Keys);
            values.Sort();
            return values;
        }

        public IReadOnlyList<EquipmentDefinition> GetEquipmentSuit(int suitId)
        {
            List<EquipmentDefinition> result = new List<EquipmentDefinition>();
            foreach (EquipmentDefinition value in equipment.Values)
                if (value.Suit == suitId) result.Add(value);
            result.Sort((left, right) => left.Part.CompareTo(right.Part));
            return result;
        }

        public EquipmentSuitDefinition GetSuit(int suitId)
            => suits.TryGetValue(suitId, out EquipmentSuitDefinition value) ? value : null;

        public int GetStrengthCost(int nextLevel, int quality)
        {
            if (!strength.TryGetValue(nextLevel, out EquipmentStrengthDefinition value)
                || value.Cost == null || value.Cost.Length < 3) return 0;
            int[] ratios = { 0, 10000, 5000, 7500, 10000, 12500, 15000, 20000 };
            int ratio = quality >= 1 && quality < ratios.Length ? ratios[quality] : 10000;
            return checked(value.Cost[2] * ratio / 10000);
        }

        public int MaxStrengthLevel => strength.Count;

        public int MaxFaBaoStrengthLevel => faBaoStrength.Count == 0 ? 0 : faBaoStrength.Keys.Max();

        public int GetFaBaoStrengthExperience(int level, int quality)
        {
            if (!faBaoStrength.TryGetValue(level, out FaBaoStrengthDefinition value)) return 0;
            int ratio = qualities.TryGetValue(quality, out EquipmentQualityDefinition definition)
                && definition.FaBaoStrengthRatio > 0 ? definition.FaBaoStrengthRatio : 10000;
            return checked(value.Experience * ratio / 10000);
        }

        public FaBaoRefineDefinition GetFaBaoRefine(int level)
            => faBaoRefine.TryGetValue(level, out FaBaoRefineDefinition value) ? value : null;

        public EquipmentMasterDefinition GetMaster(int type, int level)
            => masters.TryGetValue(type, out Dictionary<int, EquipmentMasterDefinition> values)
                && values.TryGetValue(level, out EquipmentMasterDefinition value) ? value : null;

        public int GetMasterLevel(int type, int minimumCultivationLevel)
        {
            if (!masters.TryGetValue(type, out Dictionary<int, EquipmentMasterDefinition> values)) return 0;
            int result = 0;
            foreach (EquipmentMasterDefinition value in values.Values)
                if (value.Condition <= minimumCultivationLevel && value.Level > result) result = value.Level;
            return result;
        }

        public void Clear()
        {
            equipment.Clear(); faBao.Clear(); strength.Clear(); suits.Clear(); equipmentByFragment.Clear(); fragmentComposeCost.Clear();
            refine.Clear(); awaken.Clear(); divine.Clear(); items.Clear(); refineMaterials.Clear(); qualities.Clear();
            faBaoStrength.Clear(); faBaoRefine.Clear(); masters.Clear();
        }

        private void LoadFaBaoCultivation()
        {
            LoadByLevel("Configs/fabao_qianghua", faBaoStrength);
            LoadByLevel("Configs/fabao_jinglian", faBaoRefine);
            ClientLog.Info("Config", "Loaded FaBao cultivation configs",
                $"strength={faBaoStrength.Count}, refine={faBaoRefine.Count}");
        }

        private void LoadMasters()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/master");
            if (asset == null) throw new InvalidOperationException("Equipment master config is missing: Resources/Configs/master.json");
            EquipmentMasterDefinition[] values = JsonConvert.DeserializeObject<EquipmentMasterDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentMasterDefinition>();
            foreach (EquipmentMasterDefinition value in values)
            {
                if (value == null || value.Type < 1 || value.Level < 1) continue;
                if (!masters.TryGetValue(value.Type, out Dictionary<int, EquipmentMasterDefinition> group))
                {
                    group = new Dictionary<int, EquipmentMasterDefinition>();
                    masters[value.Type] = group;
                }
                group[value.Level] = value;
            }
            ClientLog.Info("Config", "Loaded Configs/master", $"types={masters.Count}, records={values.Length}");
        }

        private void LoadCultivation()
        {
            LoadByLevel("Configs/equip_jinglian", refine);
            LoadByLevel("Configs/equip_juexing", awaken);
            LoadByLevel("Configs/equip_shenzhu", divine);
            TextAsset qualityAsset = Resources.Load<TextAsset>("Configs/quality");
            if (qualityAsset == null) throw new InvalidOperationException("Equipment quality config is missing: Resources/Configs/quality.json");
            EquipmentQualityDefinition[] qualityValues = JsonConvert.DeserializeObject<EquipmentQualityDefinition[]>(qualityAsset.text)
                ?? Array.Empty<EquipmentQualityDefinition>();
            foreach (EquipmentQualityDefinition value in qualityValues)
                if (value != null && value.Quality > 0 && value.RefineRatio > 0) qualities[value.Quality] = value;
            TextAsset asset = Resources.Load<TextAsset>("Configs/item");
            if (asset == null) throw new InvalidOperationException("Equipment material config is missing: Resources/Configs/item.json");
            EquipmentMaterialDefinition[] values = JsonConvert.DeserializeObject<EquipmentMaterialDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentMaterialDefinition>();
            foreach (EquipmentMaterialDefinition value in values)
            {
                if (value == null || value.Id <= 0) continue;
                items[value.Id] = value;
                if (value.Type == 4 && value.RefineExperience > 0)
                    refineMaterials[value.Id] = value;
            }
            ClientLog.Info("Config", "Loaded equipment cultivation configs",
                $"refine={refine.Count}, awaken={awaken.Count}, divine={divine.Count}, materials={refineMaterials.Count}, qualities={qualities.Count}");
        }

        private static void LoadByLevel<T>(string resourcePath, IDictionary<int, T> target) where T : class
        {
            TextAsset asset = Resources.Load<TextAsset>(resourcePath);
            if (asset == null) throw new InvalidOperationException($"Equipment cultivation config is missing: Resources/{resourcePath}.json");
            JArray values = JArray.Parse(asset.text);
            foreach (JToken token in values)
            {
                int level = token.Value<int?>("level") ?? -1;
                T value = token.ToObject<T>();
                if (level >= 0 && value != null) target[level] = value;
            }
        }

        private void LoadComposition()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/hecheng");
            if (asset == null) throw new InvalidOperationException("Equipment composition config is missing: Resources/Configs/hecheng.json");
            EquipmentComposeDefinition[] values = JsonConvert.DeserializeObject<EquipmentComposeDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentComposeDefinition>();
            foreach (EquipmentComposeDefinition value in values)
            {
                if (value == null || value.Type != 4 || value.Items == null || value.Items.Length != 1
                    || value.Items[0] == null || value.Items[0].Length < 3
                    || value.Target == null || value.Target.Length < 3 || value.Target[0] <= 0) continue;
                int fragmentId = value.Items[0][0];
                if (fragmentId > 0)
                {
                    equipmentByFragment[fragmentId] = value.Target[0];
                    fragmentComposeCost[fragmentId] = value.Items[0][2];
                }
            }
            ClientLog.Info("Config", "Loaded equipment fragment composition", $"{equipmentByFragment.Count} records");
        }

        private void LoadSuits()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/suit");
            if (asset == null) throw new InvalidOperationException("Equipment suit config is missing: Resources/Configs/suit.json");
            EquipmentSuitDefinition[] values = JsonConvert.DeserializeObject<EquipmentSuitDefinition[]>(asset.text)
                ?? Array.Empty<EquipmentSuitDefinition>();
            foreach (EquipmentSuitDefinition value in values)
                if (value != null && value.Id > 0) suits[value.Id] = value;
            ClientLog.Info("Config", "Loaded Configs/suit", $"{suits.Count} records");
        }

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
