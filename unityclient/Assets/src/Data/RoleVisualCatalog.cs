using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class RoleVisualDefinition
    {
        [JsonProperty("visual_id")] public int Id { get; private set; }
        [JsonProperty("male_prefab")] public string MalePrefab { get; private set; }
        [JsonProperty("female_prefab")] public string FemalePrefab { get; private set; }
        [JsonProperty("male_avatar")] public string MaleAvatar { get; private set; }
        [JsonProperty("female_avatar")] public string FemaleAvatar { get; private set; }
        [JsonProperty("animation")] public string Animation { get; private set; }
        [JsonProperty("create_default")] public int CreateDefault { get; private set; }
        public string Template => "role_{sex}_" + Id.ToString("00");
        public string Prefab(byte sex) => sex == 0 ? MalePrefab : sex == 1 ? FemalePrefab
            : throw new ArgumentOutOfRangeException(nameof(sex));
        public string AvatarKey(byte sex) => "Art/Portraits/Players/" + (sex == 0 ? MaleAvatar
            : sex == 1 ? FemaleAvatar : throw new ArgumentOutOfRangeException(nameof(sex)));
    }

    public sealed class RoleVisualCatalog
    {
        private static RoleVisualCatalog current;
        public static RoleVisualCatalog Current => current ?? (current = new RoleVisualCatalog());
        private readonly Dictionary<int, RoleVisualDefinition> byId;
        public RoleVisualDefinition CreationDefault { get; }
        public IReadOnlyCollection<RoleVisualDefinition> Items => byId.Values;

        private RoleVisualCatalog()
        {
            TextAsset asset = Resources.Load<TextAsset>("ProjectXData/Configs/role-visuals");
            if (asset == null) throw new InvalidOperationException("role_visual Excel export is missing.");
            var rows = JsonConvert.DeserializeObject<RoleVisualDefinition[]>(asset.text);
            if (rows == null || rows.Length == 0) throw new InvalidOperationException("role_visual has no rows.");
            byId = rows.ToDictionary(row => row.Id);
            CreationDefault = rows.Single(row => row.CreateDefault == 1);
            foreach (var row in rows)
            {
                if (row.Id <= 0 || row.Id > 99 || string.IsNullOrWhiteSpace(row.Animation)
                    || !ValidName(row.MalePrefab) || !ValidName(row.FemalePrefab)
                    || !ValidName(row.MaleAvatar) || !ValidName(row.FemaleAvatar))
                    throw new InvalidOperationException("Invalid role_visual row: " + row.Id);
            }
        }

        private static bool ValidName(string name) => name != null && Regex.IsMatch(name, "^[A-Za-z0-9_]+$");

        public RoleVisualDefinition Resolve(string template)
        {
            Match match = Regex.Match(template ?? string.Empty, @"^role_\{sex\}_([0-9]{2})$");
            if (!match.Success || !byId.TryGetValue(int.Parse(match.Groups[1].Value), out var visual))
                throw new InvalidOperationException("Unknown role_visual template: " + template);
            return visual;
        }
    }
}
