using System;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Data
{
    public static class HeroBuildGearCatalog
    {
        private sealed class Artifact
        {
            public int id, family, quality;
            public string name, description;
        }
        private sealed class Set
        {
            public int id;
            public string name, two, four;
        }
        private sealed class Catalog
        {
            public string artifactSelection;
            public Artifact[] artifacts = Array.Empty<Artifact>();
            public Set[] sets = Array.Empty<Set>();
        }
        private static Catalog catalog;

        public static string Describe(int family, int setId)
        {
            if (catalog == null)
            {
                var asset = Resources.Load<TextAsset>("Configs/hero_build_gear");
                catalog = asset == null ? new Catalog() : JsonConvert.DeserializeObject<Catalog>(asset.text) ?? new Catalog();
            }
            var result = new StringBuilder();
            var set = catalog.sets.FirstOrDefault(x => x.id == setId);
            if (set != null)
                result.Append("<b>").Append(set.name).Append("套装</b>\n2件：").Append(set.two)
                    .Append("\n4件：").Append(set.four).Append('\n');
            foreach (var artifact in catalog.artifacts.Where(x => x.family == family).OrderBy(x => x.quality))
                result.Append('\n').Append(artifact.name).Append("：").Append(artifact.description);
            if (result.Length > 0) result.Append('\n').Append(catalog.artifactSelection);
            return result.ToString();
        }
    }
}
