using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using UnityEngine;

namespace ProjectX.Animation
{
    public readonly struct ImodAnimationAssets
    {
        public ImodAnimationAssets(TextAsset animation, Texture2D texture, string legacyPath)
        {
            Animation = animation;
            Texture = texture;
            LegacyPath = legacyPath;
        }

        public TextAsset Animation { get; }
        public Texture2D Texture { get; }
        public string LegacyPath { get; }
        public bool IsValid => Animation != null && Texture != null;
    }

    public static class ImodAnimationResources
    {
        private const string CatalogResource = "ProjectXAnimation/catalog";
        private static Dictionary<string, ImodAnimationCatalogEntry> entries;

        public static bool TryLoad(string legacyPath, out ImodAnimationAssets assets)
        {
            EnsureCatalog();
            string normalized = NormalizeLegacyPath(legacyPath);
            if (!entries.TryGetValue(normalized, out ImodAnimationCatalogEntry entry))
            {
                assets = default;
                return false;
            }
            return TryLoadEntry(entry, null, out assets);
        }

        public static bool TryLoad(string texturePath, string animationPath, out ImodAnimationAssets assets)
        {
            EnsureCatalog();
            string normalizedAnimation = NormalizeLegacyPath(animationPath);
            if (!entries.TryGetValue(normalizedAnimation, out ImodAnimationCatalogEntry entry))
            {
                assets = default;
                return false;
            }
            string textureKey = string.IsNullOrWhiteSpace(texturePath)
                ? null
                : "ProjectXAnimation/" + NormalizeLegacyPath(texturePath);
            return TryLoadEntry(entry, textureKey, out assets);
        }

        public static string NormalizeLegacyPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) return string.Empty;
            string value = path.Trim().Replace('\\', '/');
            while (value.StartsWith("./", StringComparison.Ordinal)) value = value.Substring(2);
            if (value.StartsWith("res/", StringComparison.OrdinalIgnoreCase)) value = value.Substring(4);
            if (value.StartsWith("ProjectXAnimation/", StringComparison.OrdinalIgnoreCase))
                value = value.Substring("ProjectXAnimation/".Length);
            if (value.EndsWith(".ani", StringComparison.OrdinalIgnoreCase)
                || value.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                value = value.Substring(0, value.Length - 4);
            return value.TrimStart('/');
        }

        internal static void ResetForTests() => entries = null;

        private static bool TryLoadEntry(
            ImodAnimationCatalogEntry entry,
            string textureOverride,
            out ImodAnimationAssets assets)
        {
            TextAsset animation = Resources.Load<TextAsset>(entry.animationResourceKey);
            Texture2D texture = Resources.Load<Texture2D>(textureOverride ?? entry.textureResourceKey);
            assets = new ImodAnimationAssets(animation, texture, entry.legacyPath);
            return assets.IsValid;
        }

        private static void EnsureCatalog()
        {
            if (entries != null) return;
            TextAsset json = Resources.Load<TextAsset>(CatalogResource);
            if (json == null)
                throw new InvalidOperationException($"Imod animation catalog is missing: {CatalogResource}");
            ImodAnimationCatalog catalog = JsonConvert.DeserializeObject<ImodAnimationCatalog>(json.text);
            if (catalog == null || catalog.schemaVersion != 1 || catalog.entries == null)
                throw new InvalidOperationException("Unsupported Imod animation catalog.");
            entries = new Dictionary<string, ImodAnimationCatalogEntry>(StringComparer.OrdinalIgnoreCase);
            foreach (ImodAnimationCatalogEntry entry in catalog.entries)
            {
                if (entry == null || string.IsNullOrWhiteSpace(entry.legacyPath)) continue;
                entries[NormalizeLegacyPath(entry.legacyPath)] = entry;
                if (entry.aliases == null) continue;
                foreach (string alias in entry.aliases)
                    if (!string.IsNullOrWhiteSpace(alias)) entries[NormalizeLegacyPath(alias)] = entry;
            }
        }

        [Serializable]
        private sealed class ImodAnimationCatalog
        {
            public int schemaVersion;
            public ImodAnimationCatalogEntry[] entries;
        }

        [Serializable]
        private sealed class ImodAnimationCatalogEntry
        {
            public string legacyPath;
            public string animationResourceKey;
            public string textureResourceKey;
            public string[] aliases;
            public bool playable;
            public bool texturePadded;
        }
    }
}
