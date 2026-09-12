using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Core
{
    internal enum FunctionRouteKind
    {
        Unsupported,
        Gameplay,
        World,
        Commerce,
        Draw,
        EquipmentCultivation,
        FaBaoCultivation,
        SteamExcluded,
    }

    internal readonly struct FunctionRouteDefinition
    {
        public FunctionRouteDefinition(int functionId, FunctionRouteKind kind, int mode,
            string target, string prefabKey, string presentation, string closePath)
        {
            FunctionId = functionId;
            Kind = kind;
            Mode = mode;
            Target = target ?? string.Empty;
            PrefabKey = prefabKey ?? string.Empty;
            Presentation = presentation ?? string.Empty;
            ClosePath = closePath ?? string.Empty;
        }

        public int FunctionId { get; }
        public FunctionRouteKind Kind { get; }
        public int Mode { get; }
        public string Target { get; }
        public string PrefabKey { get; }
        public string Presentation { get; }
        public string ClosePath { get; }
        public bool CanOpen => Kind != FunctionRouteKind.Unsupported
            && Kind != FunctionRouteKind.SteamExcluded;
    }

    internal static class FunctionRouteCatalog
    {
        private const string ResourcePath = "Configs/function-routes";
        private static Dictionary<int, FunctionRouteDefinition> routes;

        public static FunctionRouteDefinition Resolve(int functionId)
        {
            EnsureLoaded();
            return routes.TryGetValue(functionId, out FunctionRouteDefinition route)
                ? route
                : new FunctionRouteDefinition(functionId, FunctionRouteKind.Unsupported, 0,
                    null, null, null, null);
        }

        public static bool CanOpen(int functionId) => Resolve(functionId).CanOpen;

        private static void EnsureLoaded()
        {
            if (routes != null) return;
            TextAsset asset = Resources.Load<TextAsset>(ResourcePath);
            if (asset == null)
                throw new InvalidOperationException($"Function route config is missing: Resources/{ResourcePath}.json");
            RouteRow[] rows = JsonConvert.DeserializeObject<RouteRow[]>(asset.text) ?? Array.Empty<RouteRow>();
            routes = new Dictionary<int, FunctionRouteDefinition>(rows.Length);
            foreach (RouteRow row in rows)
            {
                if (row == null || row.FunctionId <= 0)
                    throw new InvalidOperationException("Function route config contains an invalid functionId.");
                if (!Enum.TryParse(row.Kind, true, out FunctionRouteKind kind))
                    throw new InvalidOperationException($"Function route {row.FunctionId} has invalid kind '{row.Kind}'.");
                if (routes.ContainsKey(row.FunctionId))
                    throw new InvalidOperationException($"Function route config contains duplicate id={row.FunctionId}.");
                routes.Add(row.FunctionId, new FunctionRouteDefinition(row.FunctionId, kind, row.Mode,
                    row.Target, row.PrefabKey, row.Presentation, row.ClosePath));
            }
        }

        private sealed class RouteRow
        {
            [JsonProperty("functionId")] public int FunctionId { get; set; }
            [JsonProperty("kind")] public string Kind { get; set; }
            [JsonProperty("mode")] public int Mode { get; set; }
            [JsonProperty("target")] public string Target { get; set; }
            [JsonProperty("prefabKey")] public string PrefabKey { get; set; }
            [JsonProperty("presentation")] public string Presentation { get; set; }
            [JsonProperty("closePath")] public string ClosePath { get; set; }
        }
    }
}
