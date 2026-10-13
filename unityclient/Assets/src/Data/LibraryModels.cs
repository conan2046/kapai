using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class LibraryRealmDefinition
    {
        [JsonProperty("realm_id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("sort_order")] public int Order;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class LibrarySetDefinition
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("realm_id")] public int Realm;
        [JsonProperty("book_ids")] public int[] Books;
        [JsonProperty("sort_order")] public int Order;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class LibraryBookDefinition
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("item_id")] public int Item;
        [JsonProperty("set_id")] public int Set;
        [JsonProperty("icon_key")] public string Icon;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class LibraryRewardDefinition
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("set_id")] public int Set;
        [JsonProperty("condition_kind")] public string Kind;
        [JsonProperty("required_count")] public int Count;
        [JsonProperty("required_book_ids")] public int[] Required;
        [JsonProperty("attributes")] public int[][] Attributes;
        [JsonProperty("sort_order")] public int Order;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class LibraryEnvelope
    {
        [JsonProperty("schema")] public int Schema;
        [JsonProperty("operation")] public int Operation;
        [JsonProperty("request_id")] public string Request;
        [JsonProperty("revision")] public string Revision;
        [JsonProperty("gold")] public string Gold;
        [JsonProperty("error")] public string Error;
        [JsonProperty("configured")] public bool Configured;
        [JsonProperty("unlocked")] public bool Unlocked;
        [JsonProperty("realm_id")] public int Realm;
        [JsonProperty("obtained")] public int[] Obtained = Array.Empty<int>();
        [JsonProperty("activated_books")] public int[] Books = Array.Empty<int>();
        [JsonProperty("activated_rewards")] public int[] Rewards = Array.Empty<int>();
        [JsonProperty("owned")] public int[][] Owned = Array.Empty<int[]>();
        [JsonProperty("attributes")] public int[][] Attributes = Array.Empty<int[]>();
        public bool Activated(int book) => Books.Contains(book);
        public int Quantity(int book) => Owned.FirstOrDefault(p => p.Length == 2 && p[0] == book)?[1] ?? 0;
    }
    public sealed class LibraryCatalogData
    {
        public IReadOnlyList<LibraryRealmDefinition> Realms { get; }
        public Dictionary<int, LibrarySetDefinition> Sets { get; }
        public Dictionary<int, LibraryBookDefinition> Books { get; }
        public Dictionary<int, LibraryRewardDefinition> Rewards { get; }
        public LibraryCatalogData()
        {
            Realms = Read<LibraryRealmDefinition>("jingjie_realm").Where(x => x.Enabled == 1).OrderBy(x => x.Order).ThenBy(x => x.Id).ToArray();
            Sets = Read<LibrarySetDefinition>("dongfu_book_set").Where(x => x.Enabled == 1).ToDictionary(x => x.Id);
            Books = Read<LibraryBookDefinition>("dongfu_book").Where(x => x.Enabled == 1).ToDictionary(x => x.Id);
            Rewards = Read<LibraryRewardDefinition>("dongfu_book_reward").Where(x => x.Enabled == 1).ToDictionary(x => x.Id);
            foreach (var set in Sets.Values)
                if (set.Books == null || set.Books.Length < 1 || set.Books.Length > 4 || set.Books.Distinct().Count() != set.Books.Length
                    || !Realms.Any(r => r.Id == set.Realm) || set.Books.Any(id => !Books.ContainsKey(id) || Books[id].Set != set.Id))
                    throw new InvalidOperationException("藏书套装配置错误");
        }
        private static T[] Read<T>(string name)
        {
            var asset = Resources.Load<TextAsset>("ProjectXData/Configs/" + name);
            if (asset == null) throw new InvalidOperationException("藏书阁配置缺失：" + name);
            return JsonConvert.DeserializeObject<T[]>(asset.text) ?? Array.Empty<T>();
        }
        public IEnumerable<LibrarySetDefinition> InRealm(int realm) => Sets.Values.Where(s => s.Realm == realm).OrderBy(s => s.Order).ThenBy(s => s.Id);
        public IEnumerable<LibraryRewardDefinition> InSet(int set) => Rewards.Values.Where(r => r.Set == set).OrderBy(r => r.Order).ThenBy(r => r.Id);
        public bool Eligible(LibraryEnvelope state, LibraryRewardDefinition reward)
        {
            if (state == null || !state.Configured || !state.Unlocked || !string.IsNullOrEmpty(state.Error)
                || Sets[reward.Set].Realm > state.Realm || state.Rewards.Contains(reward.Id)) return false;
            if (reward.Kind == "book") return reward.Required.Length == 1 && !state.Activated(reward.Required[0]) && state.Quantity(reward.Required[0]) > 0;
            if (reward.Kind == "count") return Sets[reward.Set].Books.Count(state.Activated) >= reward.Count;
            if (reward.Kind == "complete") return Sets[reward.Set].Books.All(state.Activated);
            return reward.Kind == "combination" && reward.Required.All(state.Activated);
        }
        private static readonly string[] Names = { "", "攻击", "物防", "法防", "生命", "速度", "命中", "闪避", "暴击", "抗暴", "攻击加成", "物防加成", "法防加成", "生命加成", "速度加成", "命中率", "闪避率", "暴击率", "抗暴率", "增伤率", "物免率", "法免率", "暴击伤害", "反击率", "抗反率", "反击伤害", "连击率", "抗连率", "连击伤害", "反震率", "抗震率", "反震伤害", "负面强化", "负面抵抗" };
        public static string Attribute(int[] pair) => pair == null || pair.Length != 2 ? "—" : (pair[0] > 0 && pair[0] < Names.Length ? Names[pair[0]] : "属性") + " +" + (pair[0] > 9 ? (pair[1] / 100m).ToString("0.##") + "%" : pair[1].ToString());
        public static string AttributeText(int[][] attrs, string separator = "  ") => attrs == null || attrs.Length == 0 ? "暂无属性加成" : string.Join(separator, attrs.Select(Attribute));
    }
}
