using Newtonsoft.Json;
namespace ProjectX.Data
{
    public sealed class SpiritEnvelope
    {
        [JsonProperty("schema")] public int Schema;
        [JsonProperty("operation")] public int Operation;
        [JsonProperty("request_id")] public string RequestId;
        [JsonProperty("revision")] public string Revision;
        [JsonProperty("error")] public string Error;
        [JsonProperty("configured")] public bool Configured;
        [JsonProperty("unlocked")] public bool Unlocked;
        [JsonProperty("open_level")] public int OpenLevel;
        [JsonProperty("record_id")] public int RecordId;
        [JsonProperty("level")] public int Level;
        [JsonProperty("next_id")] public int NextId;
        [JsonProperty("growth_reduction_bp")] public int Growth;
        [JsonProperty("yield_bonus_bp")] public int Yield;
        [JsonProperty("root_level_cap")] public int RootLevelCap;
        [JsonProperty("spirit_per_second")] public int SpiritPerSecond;
        [JsonProperty("storage")] public string Storage;
        [JsonProperty("production_period_ms")] public int ProductionPeriodMs;
        [JsonProperty("production_elapsed_ms")] public int ProductionElapsedMs;
        [JsonProperty("spirit")] public string Spirit;
        [JsonProperty("roots")] public SpiritRootState[] Roots;
        [JsonProperty("position_attributes")] public SpiritPositionBonus[] Positions;
        [JsonProperty("costs")] public long[][] Costs;
    }
    public sealed class SpiritRootState
    {
        [JsonProperty("name")] public string Name;
        [JsonProperty("root_type")] public int Type;
        [JsonProperty("configured")] public bool Configured;
        [JsonProperty("record_id")] public int RecordId;
        [JsonProperty("level")] public int Level;
        [JsonProperty("next_id")] public int NextId;
        [JsonProperty("capped")] public bool Capped;
        [JsonProperty("growth_reduction_bp")] public int Growth;
        [JsonProperty("yield_bonus_bp")] public int Yield;
        [JsonProperty("spirit_cost")] public string SpiritCost;
        [JsonProperty("costs")] public long[][] Costs;
        [JsonProperty("combat_attributes")] public int[][] Attributes;
        [JsonProperty("target_positions")] public int[] TargetPositions;
    }
    public sealed class SpiritPositionBonus
    {
        [JsonProperty("position")] public int Position;
        [JsonProperty("attributes")] public int[][] Attributes;
    }
}
