using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UnityEditor;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;

namespace ProjectX.Editor
{
    public static class UnityNativeSpriteAtlasBuilder
    {
        private const string Root = "Assets/Art/Atlases";
        private const string GroupingSchema = "original-source-directory";

        [MenuItem("Tools/ProjectX 资源/重建原生 UI 图集")]
        public static void Rebuild()
        {
            if (EditorApplication.isPlaying) throw new InvalidOperationException("Build atlases in Edit mode.");
            if (!AssetDatabase.IsValidFolder(Root)) AssetDatabase.CreateFolder("Assets/Art", "Atlases");
            string settings = Path.GetFullPath(Path.Combine(Application.dataPath, "../ProjectSettings/ProjectXSpriteAtlases.json"));
            JObject previous = File.Exists(settings) ? JObject.Parse(File.ReadAllText(settings)) : null;
            var groupMerges = ReadGroupMerges(previous);
            var fixedExclusions = new Dictionary<string, string>(StringComparer.Ordinal);
            foreach (JToken entry in previous?["excluded"] ?? new JArray())
            {
                string reason = (string)entry["reason"];
                if (reason != "raw-texture-and-runtime-slicing" && reason != "standalone-background") continue;
                string guid = (string)entry["guid"] ?? AssetDatabase.AssetPathToGUID((string)entry["path"]);
                if (!string.IsNullOrEmpty(guid)) fixedExclusions[guid] = reason;
            }
            var groups = new SortedDictionary<string, List<Texture2D>>(StringComparer.Ordinal);
            var excluded = new List<object>();
            foreach (string path in AssetDatabase.FindAssets("t:Texture2D", new[] { "Assets/Art" })
                .Select(AssetDatabase.GUIDToAssetPath).OrderBy(value => value, StringComparer.Ordinal))
            {
                if (path.StartsWith(Root + "/", StringComparison.Ordinal)) continue;
                TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                Texture2D texture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                string sourceGuid = AssetDatabase.AssetPathToGUID(path);
                string reason = null;
                if (importer == null || importer.textureType != TextureImporterType.Sprite || texture == null)
                    reason = "not-source-sprite";
                else if (path.StartsWith("Assets/Art/AnimationFrames/", StringComparison.Ordinal))
                    reason = "existing-animation-sheet";
                else if (fixedExclusions.TryGetValue(sourceGuid, out string fixedReason))
                    reason = fixedReason;
                else if (path.StartsWith("Assets/Art/Backgrounds/", StringComparison.Ordinal)
                    || texture.width >= 1000 || texture.height >= 750
                    || path.StartsWith("Assets/Art/World/Maps/", StringComparison.Ordinal))
                    reason = "standalone-background-or-map";
                if (reason != null) { excluded.Add(new { path, guid = sourceGuid, reason }); continue; }
                string group = GetGroupName(path, importer, groupMerges);
                if (!groups.TryGetValue(group, out List<Texture2D> values)) groups[group] = values = new List<Texture2D>();
                values.Add(texture);
            }
            var stalePaths = (previous?["atlases"] ?? new JArray()).Select(entry => (string)entry["path"])
                .Where(path => !groups.Keys.Any(name => path == Root + "/" + name + ".spriteatlasv2")).ToArray();
            foreach (string path in stalePaths)
                if (string.IsNullOrEmpty(path) || !path.StartsWith(Root + "/", StringComparison.Ordinal)
                    || !path.EndsWith(".spriteatlasv2", StringComparison.Ordinal))
                    throw new InvalidDataException("Invalid retired atlas output: " + path);
            var records = new List<object>();
            foreach (var pair in groups)
            {
                string path = Root + "/" + pair.Key + ".spriteatlasv2";
                var existing = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(path);
                var existingImporter = AssetImporter.GetAtPath(path) as SpriteAtlasImporter;
                TextureImporter groupSource = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(pair.Value[0])) as TextureImporter;
                if (existing != null && existingImporter != null && existingImporter.includeInBuild
                    && !existingImporter.packingSettings.enableRotation && !existingImporter.packingSettings.enableTightPacking
                    && existingImporter.packingSettings.padding == 4
                    && existingImporter.textureSettings.filterMode == groupSource.filterMode
                    && existingImporter.textureSettings.sRGB == groupSource.sRGBTexture
                    && existingImporter.textureSettings.generateMipMaps == groupSource.mipmapEnabled
                    && !existingImporter.textureSettings.readable
                    && HasPlatformSettings(existingImporter, "DefaultTexturePlatform", false)
                    && HasPlatformSettings(existingImporter, "Standalone", true)
                    && HasDeclaredPackables(path, pair.Value.Select(AssetDatabase.GetAssetPath))
                    && existing.GetPackables().Select(AssetDatabase.GetAssetPath).OrderBy(value => value, StringComparer.Ordinal)
                        .SequenceEqual(pair.Value.Select(AssetDatabase.GetAssetPath).OrderBy(value => value, StringComparer.Ordinal)))
                {
                    records.Add(new { name = pair.Key, path, textureGuids = pair.Value.Select(value =>
                        AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(value))).ToArray() });
                    continue;
                }
                var asset = new SpriteAtlasAsset();
                asset.Add(pair.Value.Cast<UnityEngine.Object>().ToArray());
                SpriteAtlasAsset.Save(asset, path);
                UnityEngine.Object.DestroyImmediate(asset);
                AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate | ImportAssetOptions.ForceSynchronousImport);
                var importer = AssetImporter.GetAtPath(path) as SpriteAtlasImporter;
                if (importer == null) throw new InvalidDataException("Missing SpriteAtlas V2 importer: " + path);
                TextureImporter source = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(pair.Value[0])) as TextureImporter;
                var packing = importer.packingSettings;
                packing.enableRotation = false;
                packing.enableTightPacking = false;
                packing.padding = 4;
                importer.packingSettings = packing;
                var texture = importer.textureSettings;
                texture.filterMode = source.filterMode;
                texture.sRGB = source.sRGBTexture;
                texture.generateMipMaps = source.mipmapEnabled;
                texture.readable = false;
                importer.textureSettings = texture;
                importer.includeInBuild = true;
                foreach (string platform in new[] { "DefaultTexturePlatform", "Standalone" })
                    importer.SetPlatformSettings(new TextureImporterPlatformSettings
                    {
                        name = platform, overridden = platform == "Standalone", maxTextureSize = 2048,
                        format = TextureImporterFormat.RGBA32, textureCompression = TextureImporterCompression.Uncompressed
                    });
                importer.SaveAndReimport();
                records.Add(new { name = pair.Key, path, textureGuids = pair.Value.Select(value =>
                    AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(value))).ToArray() });
            }
            AssetDatabase.StartAssetEditing();
            try
            {
                foreach (string path in stalePaths)
                    if (File.Exists(path) && !AssetDatabase.DeleteAsset(path))
                        throw new InvalidDataException("Cannot retire generated atlas: " + path);
            }
            finally { AssetDatabase.StopAssetEditing(); }
            File.WriteAllText(settings, JsonConvert.SerializeObject(new
            {
                atlasRoot = Root, groupingSchema = GroupingSchema, maxTextureSize = 2048, rotation = false, tightPacking = false, padding = 4,
                target = "StandaloneWindows64", groupMerges, atlases = records, excluded
            }, Formatting.Indented));
            AssetDatabase.SaveAssets();
            Debug.Log($"Native UI atlases: {groups.Count} groups, {groups.Values.Sum(values => values.Count)} textures.");
        }

        private static Dictionary<string, string> ReadGroupMerges(JObject settings)
        {
            return settings?["groupMerges"]?.ToObject<Dictionary<string, string>>()
                ?? new Dictionary<string, string>(StringComparer.Ordinal);
        }

        private static string GetGroupName(string path, TextureImporter importer, IDictionary<string, string> groupMerges)
        {
            string[] segments = path.Substring("Assets/Art/".Length).Split('/');
            string group = segments[0] == "UI" ? "UI_" + segments[1]
                : segments[0] == "Icons" || segments[0] == "Portraits"
                    ? segments[0] + "_" + (segments.Length > 2 ? segments[1] : "Common") : segments[0];
            if (path.StartsWith("Assets/Art/Portraits/Monsters/", StringComparison.Ordinal)
                && Path.GetFileNameWithoutExtension(path).EndsWith("_tou", StringComparison.Ordinal))
                group = "Portraits_Monsters_Heads";
            string suffix = "_" + importer.filterMode + (importer.sRGBTexture ? "_sRGB" : "_Linear")
                + (importer.mipmapEnabled ? "_Mips" : "");
            group += suffix;
            if (!groupMerges.TryGetValue(group, out string merged)) return group;
            if (string.IsNullOrEmpty(merged) || !System.Text.RegularExpressions.Regex.IsMatch(merged, "^[A-Za-z0-9_]+$")
                || !merged.EndsWith(suffix, StringComparison.Ordinal))
                throw new InvalidDataException("Incompatible atlas group merge: " + group + " -> " + merged);
            return merged;
        }

        private static bool HasDeclaredPackables(string path, IEnumerable<string> expectedPaths)
        {
            var definition = SpriteAtlasAsset.Load(path);
            if (definition == null) return false;
            try
            {
                var serialized = new SerializedObject(definition);
                SerializedProperty packables = serialized.FindProperty("m_ImporterData.packables");
                string[] expected = expectedPaths.OrderBy(value => value, StringComparer.Ordinal).ToArray();
                if (packables == null || packables.arraySize != expected.Length) return false;
                var actual = new List<string>();
                for (int i = 0; i < packables.arraySize; i++)
                {
                    UnityEngine.Object source = packables.GetArrayElementAtIndex(i).objectReferenceValue;
                    if (source == null) return false;
                    actual.Add(AssetDatabase.GetAssetPath(source));
                }
                return actual.OrderBy(value => value, StringComparer.Ordinal).SequenceEqual(expected);
            }
            finally { UnityEngine.Object.DestroyImmediate(definition); }
        }

        private static bool HasPlatformSettings(SpriteAtlasImporter importer, string platform, bool overridden)
        {
            TextureImporterPlatformSettings settings = importer.GetPlatformSettings(platform);
            return settings.overridden == overridden && settings.maxTextureSize == 2048
                && settings.format == TextureImporterFormat.RGBA32
                && settings.textureCompression == TextureImporterCompression.Uncompressed;
        }

        [MenuItem("Tools/ProjectX 资源/验证原生 UI 图集")]
        public static void Validate()
        {
            var failures = new List<string>();
            var ownedTextures = new HashSet<string>(StringComparer.Ordinal);
            JObject settings = JObject.Parse(File.ReadAllText(Path.GetFullPath(Path.Combine(Application.dataPath,
                "../ProjectSettings/ProjectXSpriteAtlases.json"))));
            var groupMerges = ReadGroupMerges(settings);
            var excludedGuids = new HashSet<string>((settings["excluded"] ?? new JArray())
                .Select(entry => (string)entry["guid"] ?? AssetDatabase.AssetPathToGUID((string)entry["path"])), StringComparer.Ordinal);
            var previewMethod = typeof(SpriteAtlasExtensions).GetMethod("GetPreviewTextures",
                System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
            if (previewMethod == null) throw new InvalidOperationException("SpriteAtlas V2 Pack Preview API is unavailable.");
            foreach (string path in AssetDatabase.FindAssets("t:SpriteAtlas", new[] { Root }).Select(AssetDatabase.GUIDToAssetPath))
            {
                var atlas = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(path);
                var importer = AssetImporter.GetAtPath(path) as SpriteAtlasImporter;
                if (atlas == null || importer == null) { failures.Add(path + ": missing"); continue; }
                if (!HasDeclaredPackables(path, atlas.GetPackables().Select(AssetDatabase.GetAssetPath)))
                    failures.Add(path + ": missing or obsolete serialized packable references");
                if (importer.packingSettings.enableRotation || importer.packingSettings.enableTightPacking || !importer.includeInBuild)
                    failures.Add(path + ": unsafe UI packing");
                var pages = previewMethod.Invoke(null, new object[] { atlas }) as Texture2D[];
                if (pages == null || pages.Length == 0) failures.Add(path + ": no packed pages");
                else if (pages.Any(page => page.width > 2048 || page.height > 2048))
                    failures.Add(path + ": packed page exceeds 2048");
                foreach (UnityEngine.Object source in atlas.GetPackables())
                {
                    string sourcePath = AssetDatabase.GetAssetPath(source);
                    string guid = AssetDatabase.AssetPathToGUID(sourcePath);
                    if (!ownedTextures.Add(guid)) failures.Add(path + ": texture belongs to multiple atlases: " + sourcePath);
                    if (sourcePath.StartsWith("Assets/Art/Backgrounds/", StringComparison.Ordinal)
                        || sourcePath.StartsWith("Assets/Art/AnimationFrames/", StringComparison.Ordinal)
                        || excludedGuids.Contains(guid))
                        failures.Add(path + ": excluded source must not be packed: " + sourcePath);
                    if (sourcePath.StartsWith("Assets/Art/", StringComparison.Ordinal))
                    {
                        var sourceImporter = AssetImporter.GetAtPath(sourcePath) as TextureImporter;
                        string group = GetGroupName(sourcePath, sourceImporter, groupMerges);
                        if (Path.GetFileName(path) != group + ".spriteatlasv2")
                            failures.Add(path + ": source-directory group mismatch: " + sourcePath);
                    }
                    foreach (Sprite sprite in AssetDatabase.LoadAllAssetsAtPath(AssetDatabase.GetAssetPath(source)).OfType<Sprite>())
                        if (!atlas.CanBindTo(sprite)) failures.Add(path + ": cannot bind " + sprite.name);
                }
            }
            if (failures.Count != 0) throw new InvalidDataException(string.Join("; ", failures));
        }
    }
}
