using System;
using System.Collections.Generic;
using UnityEngine;

namespace ProjectX.UI
{
    public static class UnityNativeBattleEffectCatalog
    {
        private const string ResourceKey = "Animations/World/BattleEffects/Catalog";
        private static Dictionary<uint, SkillEntry> skills;
        private static Dictionary<uint, BuffEntry> buffs;
        private static bool loadAttempted;

        public static bool TryResolveSkill(uint id, bool rightSide, out string resourceKey)
        {
            EnsureLoaded();
            resourceKey = string.Empty;
            if (skills == null || !skills.TryGetValue(id, out SkillEntry entry)) return false;
            resourceKey = !string.IsNullOrEmpty(entry.path)
                ? entry.path
                : rightSide ? entry.right : entry.left;
            return !string.IsNullOrEmpty(resourceKey);
        }

        public static bool TryResolveAnimatedBuff(uint id, out string resourceKey)
        {
            EnsureLoaded();
            resourceKey = string.Empty;
            if (buffs == null || !buffs.TryGetValue(id, out BuffEntry entry)) return false;
            resourceKey = entry.path;
            return !string.IsNullOrEmpty(resourceKey);
        }

        private static void EnsureLoaded()
        {
            if (loadAttempted) return;
            loadAttempted = true;
            TextAsset json = ProjectX.UI.UnityAssetReference.LoadAsset<TextAsset>(ResourceKey);
            if (json == null)
            {
                Debug.LogError("Unity native battle effect catalog is missing: " + ResourceKey);
                return;
            }

            Database database = JsonUtility.FromJson<Database>(json.text);
            if (database == null || database.schemaVersion != 1)
            {
                Debug.LogError("Unity native battle effect catalog is invalid: " + ResourceKey);
                return;
            }

            skills = new Dictionary<uint, SkillEntry>();
            if (database.skillEffects != null)
                foreach (SkillEntry entry in database.skillEffects)
                    if (entry != null) skills[entry.id] = entry;
            buffs = new Dictionary<uint, BuffEntry>();
            if (database.buffs != null)
                foreach (BuffEntry entry in database.buffs)
                    if (entry != null) buffs[entry.id] = entry;
        }

        [Serializable]
        private sealed class Database
        {
            public int schemaVersion;
            public SkillEntry[] skillEffects = Array.Empty<SkillEntry>();
            public BuffEntry[] buffs = Array.Empty<BuffEntry>();
        }

        [Serializable]
        private sealed class SkillEntry
        {
            public uint id;
            public string path;
            public string left;
            public string right;
        }

        [Serializable]
        private sealed class BuffEntry
        {
            public uint id;
            public string path;
        }
    }
}
