using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Core
{
    internal readonly struct FunctionUnlockDefinition
    {
        public FunctionUnlockDefinition(int functionId, string name, int openLevel)
        {
            FunctionId = functionId;
            Name = name ?? string.Empty;
            OpenLevel = openLevel;
        }

        public int FunctionId { get; }
        public string Name { get; }
        public int OpenLevel { get; }
    }

    internal static class FunctionUnlockCatalog
    {
        private const string ResourcePath = "ProjectXData/Configs/function-unlocks";
        private static Dictionary<int, FunctionUnlockDefinition> definitions;

        public static FunctionUnlockDefinition Resolve(int functionId)
        {
            EnsureLoaded();
            if (!definitions.TryGetValue(functionId, out FunctionUnlockDefinition definition))
                throw new InvalidOperationException($"Unity function unlock config is missing function_id={functionId}.");
            return definition;
        }

        private static void EnsureLoaded()
        {
            if (definitions != null) return;
            TextAsset asset = Resources.Load<TextAsset>(ResourcePath);
            if (asset == null)
                throw new InvalidOperationException($"Unity function unlock config is missing: Resources/{ResourcePath}.json");

            FunctionUnlockRow[] rows = JsonConvert.DeserializeObject<FunctionUnlockRow[]>(asset.text)
                ?? Array.Empty<FunctionUnlockRow>();
            definitions = new Dictionary<int, FunctionUnlockDefinition>(rows.Length);
            foreach (FunctionUnlockRow row in rows)
            {
                if (row == null || row.FunctionId <= 0 || row.OpenLevel < 0)
                    throw new InvalidOperationException("Unity function unlock config contains an invalid row.");
                if (!definitions.TryAdd(row.FunctionId,
                    new FunctionUnlockDefinition(row.FunctionId, row.Name, row.OpenLevel)))
                    throw new InvalidOperationException($"Unity function unlock config contains duplicate function_id={row.FunctionId}.");
            }
        }

        private sealed class FunctionUnlockRow
        {
            [JsonProperty("functionId")] public int FunctionId { get; set; }
            [JsonProperty("name")] public string Name { get; set; }
            [JsonProperty("openLevel")] public int OpenLevel { get; set; }
        }
    }
}
