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

    public readonly struct ImodAnimationPreparedAssets
    {
        public ImodAnimationPreparedAssets(TextAsset animation, Texture2D texture, ImodAnimationData data,
            Sprite[] sprites, string legacyPath)
        {
            Animation = animation;
            Texture = texture;
            Data = data;
            Sprites = sprites;
            LegacyPath = legacyPath;
        }

        public TextAsset Animation { get; }
        public Texture2D Texture { get; }
        public ImodAnimationData Data { get; }
        public Sprite[] Sprites { get; }
        public string LegacyPath { get; }
        public bool IsValid => Animation != null && Texture != null && Data != null
            && Sprites != null && Sprites.Length == Data.modules.Length;
    }

    public static class ImodAnimationResources
    {
        private const string CatalogResource = "ProjectXAnimation/catalog";
        private static Dictionary<string, ImodAnimationCatalogEntry> entries;
        private static readonly Dictionary<string, ImodAnimationAssets> loadedAssets =
            new Dictionary<string, ImodAnimationAssets>(StringComparer.OrdinalIgnoreCase);
        private static readonly Dictionary<string, ImodAnimationPreparedAssets> preparedAssets =
            new Dictionary<string, ImodAnimationPreparedAssets>(StringComparer.Ordinal);

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

        public static bool TryLoadPrepared(string legacyPath, out ImodAnimationPreparedAssets assets)
        {
            if (!TryLoad(legacyPath, out ImodAnimationAssets loaded))
            {
                assets = default;
                return false;
            }
            return TryPrepare(loaded, out assets);
        }

        public static bool TryLoadPrepared(string texturePath, string animationPath,
            out ImodAnimationPreparedAssets assets)
        {
            if (!TryLoad(texturePath, animationPath, out ImodAnimationAssets loaded))
            {
                assets = default;
                return false;
            }
            return TryPrepare(loaded, out assets);
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

        internal static void ResetForTests()
        {
            entries = null;
            loadedAssets.Clear();
            preparedAssets.Clear();
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ResetRuntimeCaches()
        {
            entries = null;
            loadedAssets.Clear();
            preparedAssets.Clear();
        }

        private static bool TryLoadEntry(
            ImodAnimationCatalogEntry entry,
            string textureOverride,
            out ImodAnimationAssets assets)
        {
            string textureKey = textureOverride ?? entry.textureResourceKey;
            string cacheKey = entry.animationResourceKey + "|" + textureKey;
            if (loadedAssets.TryGetValue(cacheKey, out assets) && assets.IsValid) return true;
            TextAsset animation = Resources.Load<TextAsset>(entry.animationResourceKey);
            Texture2D texture = Resources.Load<Texture2D>(textureKey);
            assets = new ImodAnimationAssets(animation, texture, entry.legacyPath);
            if (assets.IsValid) loadedAssets[cacheKey] = assets;
            return assets.IsValid;
        }

        private static bool TryPrepare(ImodAnimationAssets loaded, out ImodAnimationPreparedAssets assets)
        {
            string cacheKey = loaded.Animation.GetInstanceID() + "|" + loaded.Texture.GetInstanceID();
            if (preparedAssets.TryGetValue(cacheKey, out assets) && assets.IsValid) return true;

            ImodAnimationData data = ImodAnimationData.Parse(loaded.Animation.text);
            var sprites = new Sprite[data.modules.Length];
            for (int index = 0; index < data.modules.Length; index++)
            {
                ImodModule module = data.modules[index];
                int y = loaded.Texture.height - module.y - module.height;
                var rect = new Rect(module.x, y, module.width, module.height);
                if (rect.xMin < 0 || rect.yMin < 0 || rect.xMax > loaded.Texture.width
                    || rect.yMax > loaded.Texture.height || rect.width <= 0 || rect.height <= 0)
                    throw new InvalidOperationException(
                        $"Imod module {module.id} is outside texture {loaded.Texture.name}: {rect}");
                Sprite sprite = Sprite.Create(loaded.Texture, rect, new Vector2(.5f, .5f), 100f);
                sprite.name = $"{loaded.Texture.name}_ImodModule_{module.id}";
                sprites[index] = sprite;
            }
            assets = new ImodAnimationPreparedAssets(loaded.Animation, loaded.Texture, data, sprites,
                loaded.LegacyPath);
            preparedAssets[cacheKey] = assets;
            return true;
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
