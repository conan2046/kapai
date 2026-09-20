using System;
using System.Linq;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class HeroBuildSkillDetail
    {
        public int id;
        public string name, description, role;
        public int cd, cost;
    }
    public sealed class HeroBuildDetail
    {
        public int hero_id;
        public int artifact_a, artifact_b, set_a, set_b;
        public string name, build_a, build_b, description_a, description_b;
        public HeroBuildSkillDetail[] skills;
    }
    public static class HeroBuildDetailCatalog
    {
        private static HeroBuildDetail[] rows;
        public static HeroBuildDetail Find(int id)
        {
            if (rows == null)
            {
                TextAsset asset = Resources.Load<TextAsset>("Configs/hero_build_detail");
                rows = asset == null ? Array.Empty<HeroBuildDetail>()
                    : JsonConvert.DeserializeObject<HeroBuildDetail[]>(asset.text) ?? Array.Empty<HeroBuildDetail>();
            }
            return rows.FirstOrDefault(x => x.hero_id == id);
        }
    }
}
