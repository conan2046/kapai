using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Foundation;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class GardenCropDefinition
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("seed_item_id")] public int SeedItemId;
        [JsonProperty("grow_seconds")] public int GrowSeconds;
        [JsonProperty("outputs")] public int[][] Outputs;
        [JsonProperty("icon_key")] public string IconResource;
        [JsonProperty("initial_resource_key")] public string InitialResource;
        [JsonProperty("middle_resource_key")] public string MiddleResource;
        [JsonProperty("mature_resource_key")] public string MatureResource;
        [JsonProperty("middle_progress_bp")] public int MiddleProgressBp;
        [JsonProperty("water_after_seconds")] public int WaterAfterSeconds;
        [JsonProperty("bug_after_seconds")] public int BugAfterSeconds;
        [JsonProperty("abnormal_extension_bp")] public int AbnormalExtensionBp;
        [JsonProperty("enabled")] public int Enabled;
        [JsonProperty("seed_price_gold")] public int SeedPriceGold;
        public string StageResource(int stage) => stage == 3 ? MatureResource : stage == 2 ? MiddleResource : InitialResource;
    }
    public sealed class GardenPlotSnapshot
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("required_realm")] public int RequiredRealm;
        [JsonProperty("unlocked")] public bool Unlocked;
        [JsonProperty("crop_id")] public int CropId;
        [JsonProperty("stage")] public int Stage;
        [JsonProperty("water")] public bool Water;
        [JsonProperty("bugs")] public bool Bugs;
        [JsonProperty("revision")] public string Revision;
        [JsonProperty("remaining_ms")] public string RemainingMs;
        [JsonProperty("progress_units")] public string ProgressUnits;
        [JsonProperty("duration_ms")] public long DurationMs;
        [JsonProperty("progress_scale")] public int ProgressScale;
        public float Progress => DurationMs <= 0 ? 0 : Mathf.Clamp01(long.Parse(ProgressUnits) / (DurationMs * (float)ProgressScale));
    }
    public sealed class GardenSeedStock
    {
        [JsonProperty("crop_id")] public int CropId;
        [JsonProperty("count")] public int Count;
    }
    public sealed class GardenEnvelope
    {
        [JsonProperty("schema")] public int Schema;
        [JsonProperty("operation")] public int Operation;
        [JsonProperty("request_id")] public string RequestId;
        [JsonProperty("error")] public string Error;
        [JsonProperty("plots")] public GardenPlotSnapshot[] Plots;
        [JsonProperty("stock")] public GardenSeedStock[] Stock;
    }
    public sealed class GardenConfig
    {
        public IReadOnlyDictionary<int, GardenCropDefinition> Crops { get; }
        public GardenConfig()
        {
            TextAsset source = ResourceLoader.Load<TextAsset>("ProjectXData/Configs/dongfu_crop");
            if (source == null) throw new InvalidOperationException("灵植正式配置缺失");
            Crops = (JsonConvert.DeserializeObject<GardenCropDefinition[]>(source.text) ?? Array.Empty<GardenCropDefinition>())
                .Where(c => c.Enabled == 1).ToDictionary(c => c.Id);
            foreach (GardenCropDefinition crop in Crops.Values)
                if (crop.GrowSeconds < 1 || crop.MiddleProgressBp <= 0 || crop.MiddleProgressBp >= 10000
                    || string.IsNullOrEmpty(crop.IconResource) || string.IsNullOrEmpty(crop.InitialResource) || string.IsNullOrEmpty(crop.MiddleResource) || string.IsNullOrEmpty(crop.MatureResource))
                    throw new InvalidOperationException("灵植阶段配置不完整：" + crop.Id);
        }
    }
}
