using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class YouLiDefinition
    {
        [JsonProperty("id")] public byte Id { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("quality")] public byte Quality { get; set; }
        [JsonProperty("unlock")] public ushort UnlockLevel { get; set; }
        [JsonProperty("pic1")] public string Picture { get; set; }
        [JsonProperty("show")] public uint[][] PreviewRewards { get; set; }
    }

    public sealed class YouLiCatalog
    {
        private readonly List<YouLiDefinition> items;

        public YouLiCatalog()
        {
            TextAsset asset = Resources.Load<TextAsset>("Configs/sanjie");
            if (asset == null) throw new InvalidOperationException("YouLi config is missing: Resources/Configs/sanjie.json");
            items = (JsonConvert.DeserializeObject<YouLiDefinition[]>(asset.text) ?? Array.Empty<YouLiDefinition>())
                .Where(value => value != null && value.Id > 0).OrderBy(value => value.Id).ToList();
            ClientLog.Info("Config", "Loaded Configs/sanjie", $"{items.Count} records");
        }

        public IReadOnlyList<YouLiDefinition> Items => items;
    }
}
