using Newtonsoft.Json;

namespace ProjectX.Data
{
    public sealed class JingJieEnvelope
    {
        [JsonProperty("schema")] public int Schema;
        [JsonProperty("kind")] public string Kind;
        [JsonProperty("error")] public string Error;
        [JsonProperty("gain")] public string Gain;
        [JsonProperty("state")] public JingJieSnapshot State;
        [JsonProperty("offline")] public JingJieOfflineNotice Offline;
        [JsonProperty("trial")] public JingJieTrial Trial;
        [JsonProperty("result")] public JingJieTrial Result;
    }
    public sealed class JingJieSnapshot
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("experience")] public string Experience;
        [JsonProperty("need_exp")] public string NeedExperience;
        [JsonProperty("revision")] public string Revision;
        [JsonProperty("server_ms")] public string ServerMilliseconds;
        [JsonProperty("cycle_ms")] public string CycleMilliseconds;
        [JsonProperty("power")] public string Power;
        [JsonProperty("failures")] public int Failures;
        [JsonProperty("rate")] public int Rate;
        [JsonProperty("next_id")] public int NextId;
        [JsonProperty("interval_ms")] public int IntervalMilliseconds;
    }
    public sealed class JingJieOfflineNotice
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("seconds")] public int Seconds;
        [JsonProperty("experience")] public string Experience;
    }
    public sealed class JingJieTrial
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("before_id")] public int BeforeId;
        [JsonProperty("success")] public bool Success;
        [JsonProperty("big")] public bool Big;
        [JsonProperty("guaranteed")] public bool Guaranteed;
        [JsonProperty("visual")] public string Visual;
        [JsonProperty("max_hp")] public string MaximumHealth;
        [JsonProperty("damages")] public int[] Damages;
    }
    public sealed class JingJieRuntimeRules
    {
        [JsonProperty("online_interval_ms")] public int OnlineMilliseconds;
        [JsonProperty("offline_cap_seconds")] public int OfflineSeconds;
        [JsonProperty("offline_rate")] public int OfflineRate;
        [JsonProperty("cloud_intro_ms")] public int CloudMilliseconds;
        [JsonProperty("lightning_interval_ms")] public int LightningMilliseconds;
        [JsonProperty("result_stay_ms")] public int ResultMilliseconds;
        [JsonProperty("minimum_success_display_hp")] public int MinimumSuccessHealth;
    }
}
