using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public readonly struct FunctionUnlockDefinition
    {
        public FunctionUnlockDefinition(int functionId, string name, int openLevel, string icon)
        {
            FunctionId = functionId;
            Name = name ?? string.Empty;
            OpenLevel = openLevel;
            Icon = icon ?? string.Empty;
        }

        public int FunctionId { get; }
        public string Name { get; }
        public int OpenLevel { get; }
        public string Icon { get; }
    }

    public static class FunctionUnlockCatalog
    {
        private const string ResourcePath = "ProjectXData/Configs/function-unlocks";
        private static Dictionary<int, FunctionUnlockDefinition> definitions;
        private static readonly Dictionary<string, string> IconResourcePaths = new Dictionary<string, string>
        {
            { "ui_icon_jianghunshangdian", "Art/Icons/Gameplay/ui_icon_jianghunshangdian" },
            { "ui_icon_wanfa_diaoyu", "Art/Icons/Gameplay/ui_icon_wanfa_diaoyu" },
            { "duanzao", "Art/UI/RoleLevelUp/Icons/duanzao" },
            { "ui_icon_zhuangbei", "Art/UI/Main/Icon/ui_main_icon/ui_icon_zhuangbei" },
            { "ui_main_icon_fuben", "Art/UI/Main/Icon/ui_main_icon/ui_main_icon_fuben" },
            { "ui_icon_fabao", "Art/UI/Main/Icon/ui_main_icon/ui_icon_fabao" },
            { "ui_bangpai_icon_youjian", "Art/UI/RoleLevelUp/Icons/ui_bangpai_icon_youjian" }
        };

        public static FunctionUnlockDefinition Resolve(int functionId)
        {
            EnsureLoaded();
            if (!definitions.TryGetValue(functionId, out FunctionUnlockDefinition definition))
                throw new InvalidOperationException($"Unity function unlock config is missing function_id={functionId}.");
            return definition;
        }

        public static FunctionUnlockDefinition[] GetUpcoming(int currentLevel, int maximumCount)
        {
            if (maximumCount <= 0) return Array.Empty<FunctionUnlockDefinition>();
            EnsureLoaded();
            return definitions.Values
                .Where(item => item.OpenLevel >= currentLevel)
                .OrderBy(item => item.OpenLevel)
                .ThenBy(item => item.FunctionId)
                .Take(maximumCount)
                .ToArray();
        }

        public static Sprite LoadIcon(FunctionUnlockDefinition definition)
        {
            if (string.IsNullOrWhiteSpace(definition.Icon)) return null;
            if (!IconResourcePaths.TryGetValue(definition.Icon, out string resourcePath))
                throw new InvalidOperationException($"Unity function icon mapping is missing: {definition.Icon}.");

            Sprite sprite = ProjectX.Foundation.ResourceLoader.Load<Sprite>(resourcePath);
            if (sprite == null)
                throw new InvalidOperationException($"Unity function icon resource is missing: {resourcePath}.");
            return sprite;
        }

        private static void EnsureLoaded()
        {
            if (definitions != null) return;
            TextAsset asset = ProjectX.Foundation.ResourceLoader.Load<TextAsset>(ResourcePath);
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
                    new FunctionUnlockDefinition(row.FunctionId, row.Name, row.OpenLevel, row.Icon)))
                    throw new InvalidOperationException($"Unity function unlock config contains duplicate function_id={row.FunctionId}.");
            }
        }

        private sealed class FunctionUnlockRow
        {
            [JsonProperty("functionId")] public int FunctionId { get; set; }
            [JsonProperty("name")] public string Name { get; set; }
            [JsonProperty("openLevel")] public int OpenLevel { get; set; }
            [JsonProperty("icon")] public string Icon { get; set; }
        }
    }
}
