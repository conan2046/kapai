using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    [Serializable]
    internal sealed class ShopDefinition
    {
        [JsonProperty("id")] public ushort Id { get; set; }
        [JsonProperty("type")] public byte Type { get; set; }
        [JsonProperty("cell")] public byte Grid { get; set; }
        [JsonProperty("itemid")] public int[] Item { get; set; }
        [JsonProperty("count")] public int[] Count { get; set; }
        [JsonProperty("price")] public int[][] Price { get; set; }
        [JsonProperty("price_real")] public int[] PricePercentages { get; set; }
    }

    [Serializable]
    internal sealed class ShopItemDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("name")] public string Name { get; set; }
        [JsonProperty("des")] public string Description { get; set; }
        [JsonProperty("pic")] public int Picture { get; set; }
        [JsonProperty("quality")] public int Quality { get; set; }
        [JsonProperty("type")] public int Type { get; set; }
    }

    [Serializable]
    internal sealed class SynthesisDefinition
    {
        [JsonProperty("id")] public int Id { get; set; }
        [JsonProperty("type")] public int Type { get; set; }
        [JsonProperty("item")] public int[][] Items { get; set; }
    }

    public sealed class ShopCatalog
    {
        private readonly Dictionary<ushort, ShopDefinition> shops = new Dictionary<ushort, ShopDefinition>();
        private readonly Dictionary<int, ShopItemDefinition> items = new Dictionary<int, ShopItemDefinition>();
        private readonly Dictionary<int, SynthesisDefinition> synthesis =
            new Dictionary<int, SynthesisDefinition>();
        private readonly Dictionary<int, int> synthesisCosts = new Dictionary<int, int>();

        public ShopCatalog()
        {
            Load("Configs/shop", shops, value => value.Id);
            Load("Configs/item", items, value => value.Id);
            Load("Configs/hecheng", synthesis, value => value.Id);
            foreach (SynthesisDefinition definition in synthesis.Values)
            {
                if (definition.Type != 2 && definition.Type != 4) continue;
                int itemId = definition.Items != null && definition.Items.Length > 0
                    ? Value(definition.Items[0], 0)
                    : 0;
                int cost = definition.Items != null && definition.Items.Length > 0
                    ? Value(definition.Items[0], 2)
                    : 0;
                if (itemId > 0 && cost > 0) synthesisCosts[itemId] = cost;
            }
        }

        public int GetDisplayItemId(ushort id)
        {
            ShopDefinition definition = Get(id);
            if (definition.Item == null || definition.Item.Length == 0) return 0;
            return definition.Item[0];
        }

        public int GetSynthesisCost(int itemId) =>
            synthesisCosts.TryGetValue(itemId, out int cost) ? cost : 0;

        public bool IsShard(int itemId)
        {
            ShopItemDefinition item = FindItem(itemId);
            return item != null && (item.Type == 2 || item.Type == 7);
        }

        public ShopRecord Build(byte grid, ushort id, ushort buyCount, string fallbackName,
            string fallbackDescription, int fallbackPicture, int fallbackQuality)
        {
            ShopDefinition definition = Get(id);
            int rewardType = Value(definition.Item, 0);
            int rewardId = Value(definition.Item, 1);
            uint rewardAmount = checked((uint)Math.Max(0, Value(definition.Item, 2)));
            int configuredCostType = definition.Price != null && definition.Price.Length > 0
                ? Value(definition.Price[0], 0)
                : 0;
            // The authoritative server NoLockDelCostMaterial path charges both HDAT_BANG_YB/60001
            // and HDAT_YB/60003 through AddTongBao(type=0), so the displayed balance must follow
            // the actual unbound-premium update (60003) rather than the legacy icon/config id.
            int costType = configuredCostType == CurrencyIds.BoundPremium
                ? CurrencyIds.Premium
                : configuredCostType;
            int baseCost = definition.Price != null && definition.Price.Length > 0
                ? Value(definition.Price[0], 2)
                : 0;
            int limit = definition.Count != null && definition.Count.Length > 1
                ? definition.Count[1]
                : -1;

            ShopItemDefinition item = FindItem(rewardType);
            ShopItemDefinition currency = FindItem(configuredCostType) ?? FindItem(costType);
            // The shipped Lua catalog is the visual authority for normal items, while
            // hero-soul entries (item type 2) intentionally use their item-id portrait
            // from the current JSON catalog. This mirrors Cocos GetItemCellValue output.
            int picture = item?.Type == 2 && item.Picture > 0
                ? item.Picture
                : fallbackPicture > 0 ? fallbackPicture : item?.Picture ?? 0;
            return new ShopRecord(grid, id, buyCount, rewardType, rewardId, rewardAmount,
                NonEmpty(fallbackName, item?.Name, $"商品 #{rewardType}"),
                NonEmpty(fallbackDescription, item?.Description, "暂无描述"),
                picture,
                fallbackQuality > 0 ? fallbackQuality : item?.Quality ?? 0,
                costType, currency?.Picture ?? 0, NonEmpty(currency?.Name, $"货币 #{costType}"),
                baseCost, limit, definition.PricePercentages);
        }

        public void Clear()
        {
            shops.Clear();
            items.Clear();
            synthesis.Clear();
            synthesisCosts.Clear();
        }

        private ShopDefinition Get(ushort id) => shops.TryGetValue(id, out ShopDefinition value)
            ? value
            : throw new InvalidOperationException($"Shop config is missing id={id}.");

        private ShopItemDefinition FindItem(int id) =>
            items.TryGetValue(id, out ShopItemDefinition value) ? value : null;

        private static int Value(int[] values, int index) =>
            values != null && index >= 0 && index < values.Length ? values[index] : 0;

        private static string NonEmpty(params string[] values)
        {
            foreach (string value in values)
                if (!string.IsNullOrWhiteSpace(value)) return value;
            return string.Empty;
        }

        private static void Load<T, TKey>(string resourcePath, IDictionary<TKey, T> target, Func<T, TKey> key)
            where T : class
        {
            TextAsset asset = Resources.Load<TextAsset>(resourcePath);
            if (asset == null) throw new InvalidOperationException($"Shop config is missing: Resources/{resourcePath}.json");
            T[] values = JsonConvert.DeserializeObject<T[]>(asset.text) ?? Array.Empty<T>();
            foreach (T value in values)
                if (value != null) target[key(value)] = value;
            ClientLog.Info("Config", $"Loaded {resourcePath}", $"{target.Count} records");
        }
    }
}
