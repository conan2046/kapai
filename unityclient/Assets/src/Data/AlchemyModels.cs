using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Foundation;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class AlchemyRecipe
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("realm_id")] public int Realm;
        [JsonProperty("series_id")] public int Series;
        [JsonProperty("use_jingjie_id")] public int Level;
        [JsonProperty("learn_item_id")] public int LearnItem;
        [JsonProperty("cost_items")] public int[][] Costs;
        [JsonProperty("duration_seconds")] public int Seconds;
        [JsonProperty("batch_limit")] public int Limit;
        [JsonProperty("output_item_id")] public int Output;
        [JsonProperty("output_count")] public int OutputCount;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class AlchemyEffect
    {
        [JsonProperty("item_id")] public int Item;
        [JsonProperty("attributes")] public int[][] Attributes;
        [JsonProperty("target_positions")] public int[] Positions;
        [JsonProperty("limit_group")] public string Group;
        [JsonProperty("limit_count")] public int Limit;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class AlchemyItem
    {
        [JsonProperty("id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("des")] public string Description;
        [JsonProperty("pic")] public int Picture;
        [JsonProperty("quality")] public int Quality;
        [JsonProperty("max_stack")] public int MaxStack;
    }
    public sealed class AlchemyRealm
    {
        [JsonProperty("realm_id")] public int Id;
        [JsonProperty("name")] public string Name;
        [JsonProperty("first_jingjie_id")] public int First;
        [JsonProperty("last_jingjie_id")] public int Last;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class AlchemyShopItem
    {
        [JsonProperty("item_id")] public int Item;
        [JsonProperty("price_gold")] public int Price;
        [JsonProperty("enabled")] public int Enabled;
    }
    public sealed class AlchemyEnvelope
    {
        [JsonProperty("schema")] public int Schema;
        [JsonProperty("operation")] public int Operation;
        [JsonProperty("request_id")] public string Request;
        [JsonProperty("revision")] public string Revision;
        [JsonProperty("server_ms")] public string Server;
        [JsonProperty("finish_ms")] public string Finish;
        [JsonProperty("gold")] public string Gold;
        [JsonProperty("error")] public string Error;
        [JsonProperty("result")] public string Result;
        [JsonProperty("recipe_id")] public int Recipe;
        [JsonProperty("count")] public int Count;
        [JsonProperty("jingjie_id")] public int Level;
        [JsonProperty("craft_reduction_bp")] public int Reduction;
        [JsonProperty("learned")] public int[] Learned = Array.Empty<int>();
        [JsonProperty("owned")] public int[][] Owned = Array.Empty<int[]>();
        [JsonProperty("used")] public int[][] Used = Array.Empty<int[]>();
        [JsonProperty("shop")] public int[] Shop = Array.Empty<int>();
        public int Quantity(int item) => Owned.FirstOrDefault(x=>x.Length==2&&x[0]==item)?[1]??0;
    }
    public sealed class AlchemyClaim
    {
        [JsonProperty("item_id")] public int Item;
        [JsonProperty("count")] public int Count;
        [JsonProperty("mailed")] public int Mailed;
        [JsonProperty("used")] public int Used;
        [JsonProperty("sold")] public int Sold;
        [JsonProperty("gold")] public long Gold;
    }
    public sealed class AlchemyCatalog
    {
        public readonly Dictionary<int,AlchemyRecipe> Recipes;
        public readonly Dictionary<int,AlchemyEffect> Effects;
        public readonly Dictionary<int,AlchemyItem> Items;
        public readonly Dictionary<int,AlchemyShopItem> Shop;
        public readonly AlchemyRealm[] Realms;
        public AlchemyCatalog()
        {
            Recipes=Read<AlchemyRecipe>("dongfu_alchemy_recipe").Where(x=>x.Enabled==1).ToDictionary(x=>x.Id);
            Effects=Read<AlchemyEffect>("dongfu_effect").Where(x=>x.Enabled==1).ToDictionary(x=>x.Item);
            Items=Read<AlchemyItem>("item").ToDictionary(x=>x.Id);
            Shop=Read<AlchemyShopItem>("dongfu_material_shop").Where(x=>x.Enabled==1).ToDictionary(x=>x.Item);
            Realms=Read<AlchemyRealm>("jingjie_realm").Where(x=>x.Enabled==1).OrderBy(x=>x.Id).ToArray();
        }
        static T[] Read<T>(string key)
        {
            var asset=ResourceLoader.Load<TextAsset>("ProjectXData/Configs/"+key);
            if(asset==null)throw new InvalidOperationException("正式炼丹配置缺失："+key);
            return JsonConvert.DeserializeObject<T[]>(asset.text)??Array.Empty<T>();
        }
        public long UsedCount(AlchemyEnvelope state,int item)
        {
            if(state==null||!Effects.TryGetValue(item,out var effect))return 0;
            return state.Used.Where(x=>x.Length==2&&Effects.TryGetValue(x[0],out var other)&&other.Group==effect.Group).Sum(x=>(long)x[1]);
        }
        public static string Attribute(int[] pair)
        {
            if(pair[0]==34)return "境界修炼经验产速 +"+(pair[1]/100m).ToString("0.##")+"%";
            if(pair[0]==35)return "聚灵阵灵气产速 +"+(pair[1]/100m).ToString("0.##")+"%";
            return LibraryCatalogData.Attribute(pair);
        }
        public string EffectText(int item)
        {
            var e=Effects[item];string target=e.Positions.Contains(0)?"主角":"上阵神将 "+string.Join("、",e.Positions)+"号位";
            return target+"\n"+string.Join("\n",e.Attributes.Select(Attribute))+"\n服用上限："+e.Limit+"次";
        }
    }
}
