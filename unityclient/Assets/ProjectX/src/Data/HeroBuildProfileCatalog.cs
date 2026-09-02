using System;
using Newtonsoft.Json;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    public static class HeroBuildProfileCatalog
    {
        private static HeroBuildProfile[] profiles;

        public static HeroBuildProfile[] Profiles
        {
            get
            {
                if (profiles != null) return profiles;
                TextAsset asset = Resources.Load<TextAsset>("Configs/hero_build_profile");
                if (asset == null)
                {
                    ClientLog.Warning("Config", "Missing Configs/hero_build_profile; build guidance unavailable.");
                    return profiles = Array.Empty<HeroBuildProfile>();
                }
                profiles = JsonConvert.DeserializeObject<HeroBuildProfile[]>(asset.text)
                    ?? Array.Empty<HeroBuildProfile>();
                return profiles;
            }
        }
    }
}
