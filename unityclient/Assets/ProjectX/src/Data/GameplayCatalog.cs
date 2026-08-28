using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class GameplayDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("page")] public int Page { get; set; }
        [JsonProperty("openLevel")] public int OpenLevel { get; set; }
        [JsonProperty("icon")] public string Icon { get; set; }
        [JsonProperty("description")] public string Description { get; set; }
        [JsonProperty("steamEnabled")] public bool? SteamEnabled { get; set; }
        [JsonProperty("migrationReady")] public bool? MigrationReady { get; set; }
    }

    public sealed class GameplayCatalog
    {
        private readonly List<GameplayDefinition> items;

        public GameplayCatalog()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/gameplay");
            if (asset == null) throw new InvalidOperationException("Gameplay config is missing: Resources/Configs/gameplay.json");
            items = (JsonConvert.DeserializeObject<GameplayDefinition[]>(asset.text) ?? Array.Empty<GameplayDefinition>())
                .Where(value => value != null && value.Id < 999 && value.Page != 0
                    && value.SteamEnabled != false && value.MigrationReady != false)
                .OrderBy(value => value.Id)
                .ToList();
            ClientLog.Info("Config", "Loaded Configs/gameplay", $"{items.Count} records");
        }

        public IReadOnlyList<GameplayDefinition> Items => items;
        public GameplayDefinition Find(int id) => items.FirstOrDefault(value => value.Id == id);
        public void Clear() => items.Clear();
    }
}
