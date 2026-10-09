using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Core;
using ProjectX.Foundation;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class UnityNativeUiAssetValidator
    {
        [Serializable]
        private sealed class ResourceReferenceDefinition
        {
            public string key;
            public string guid;
        }

        [MenuItem("Tools/ProjectX 界面/重建原生资源引用索引")]
        public static void RebuildResourceReferences()
        {
            string settings = Path.GetFullPath(Path.Combine(Application.dataPath,
                "../ProjectSettings/ProjectXAssetReferences.json"));
            var entries = JsonConvert.DeserializeObject<List<ResourceReferenceDefinition>>(File.ReadAllText(settings));
            var keys = new HashSet<string>(StringComparer.Ordinal);
            AssetDatabase.StartAssetEditing();
            try
            {
                foreach (var group in entries.GroupBy(entry => entry.key))
                {
                    ResourceReferenceDefinition entry = group.First();
                    if (string.IsNullOrWhiteSpace(entry.key) || entry.key.Contains("..") || !keys.Add(entry.key))
                        throw new InvalidDataException("Invalid or duplicate native resource key: " + entry.key);
                    string[] assetPaths = group.Select(item => AssetDatabase.GUIDToAssetPath(item.guid)).ToArray();
                    UnityEngine.Object[] assets = assetPaths.Select(AssetDatabase.LoadMainAssetAtPath).ToArray();
                    if (assets.Any(asset => asset == null)) throw new InvalidDataException("Missing resource for key: " + entry.key);
                    string referencePath = "Assets/Resources/AssetReferences/" + entry.key + ".asset";
                    string parent = Path.GetDirectoryName(referencePath).Replace('\\', '/');
                    string current = "Assets";
                    foreach (string part in parent.Split('/').Skip(1))
                    {
                        string next = current + "/" + part;
                        if (!AssetDatabase.IsValidFolder(next)) AssetDatabase.CreateFolder(current, part);
                        current = next;
                    }
                    UnityAssetReference reference = AssetDatabase.LoadAssetAtPath<UnityAssetReference>(referencePath);
                    bool created = reference == null;
                    if (created) reference = ScriptableObject.CreateInstance<UnityAssetReference>();
                    Sprite preferred = assetPaths.Select(AssetDatabase.LoadAssetAtPath<Sprite>).FirstOrDefault(sprite => sprite != null);
                    Sprite[] sprites = assetPaths.SelectMany(AssetDatabase.LoadAllAssetsAtPath).OfType<Sprite>().ToArray();
                    reference.Initialize(assets, preferred, sprites);
                    if (created) AssetDatabase.CreateAsset(reference, referencePath);
                    else EditorUtility.SetDirty(reference);
                }
            }
            finally { AssetDatabase.StopAssetEditing(); }
            AssetDatabase.SaveAssets();
            Debug.Log($"Native resource references rebuilt: {keys.Count} keys; artwork remains outside Resources.");
        }

        [MenuItem("Tools/ProjectX 界面/验证全部原生 Prefab")]
        public static void ValidateBatch()
        {
            string[] paths = AssetDatabase.FindAssets("t:Prefab", new[] { "Assets/Prefabs" })
                .Select(AssetDatabase.GUIDToAssetPath).OrderBy(path => path).ToArray();
            var failures = new List<string>();
            foreach (string path in paths)
            {
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                Component[] components = prefab.GetComponentsInChildren<Component>(true);
                if (components.Any(component => component == null))
                    failures.Add(path + ": missing script");
                if (components.Any(component => component != null
                    && (component.GetType().Name == "UiPrefabIdentity"
                        || component.GetType().Name == "CocosUiBinding"
                        || component.GetType().Name == "CocosTimelinePlayer"
                        || component.GetType().Name == "ImodAnimationPlayer")))
                    failures.Add(path + ": legacy runtime component");
                if (AssetDatabase.GetDependencies(path, true).Any(IsLegacyPath))
                    failures.Add(path + ": legacy resource dependency");
                if ((path == "Assets/Prefabs/OneLevel/JingjieLayer.prefab"
                        || path == "Assets/Prefabs/OneLevel/Jingjieyulan.prefab")
                    && components.OfType<UnityEngine.UI.Image>().Any(image => image.sprite == null))
                    failures.Add(path + ": required JingJie Sprite is missing");
            }
            UiPrefabCatalog catalog = AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>(
                "Assets/Prefabs/Catalog/Catalog.asset");
            if (catalog == null) throw new InvalidDataException("Unity UI Catalog is missing.");
            foreach (UiPrefabCatalogEntry entry in catalog.Entries)
            {
                if (!entry.Source.StartsWith("Unity/", StringComparison.Ordinal))
                    failures.Add(entry.Key + ": legacy Catalog source");
                UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(
                    "Assets/Prefabs/Catalog/" + entry.Key + ".asset");
                if (reference == null || reference.Prefab == null)
                    failures.Add(entry.Key + ": missing Prefab reference");
            }
            ResourceLoader.Configure(new UnityResourceLoader());
            var host = new GameObject("__UnityNativeUiValidation", typeof(RectTransform));
            host.SetActive(false);
            int instantiated = 0;
            try
            {
                using (var provider = new ResourcesUiAssetProvider(host.transform))
                {
                    foreach (UiPrefabCatalogEntry entry in catalog.Entries)
                    {
                        UnityUiView view = null;
                        try
                        {
                            view = provider.InstantiateUnity(entry.Key, host.transform);
                            if (view == null || !view.IsAlive) throw new InvalidDataException("No view");
                            instantiated++;
                        }
                        catch (Exception exception) { failures.Add(entry.Key + ": " + exception.Message); }
                        finally
                        {
                            if (view != null && !provider.Release(view))
                                failures.Add(entry.Key + ": release failed");
                        }
                    }
                    if (provider.LoadedTransientCount != 0)
                        failures.Add("Native provider transient leak");
                }
                if (host.transform.childCount != 0) failures.Add("Native provider disposal leak");
            }
            finally { UnityEngine.Object.DestroyImmediate(host); }
            string report = Path.GetFullPath(Path.Combine(Application.dataPath,
                "../../.local/unity-validation/unity-native-assets-validation.json"));
            File.WriteAllText(report, JsonConvert.SerializeObject(new
            {
                prefabs = paths.Length,
                catalogEntries = catalog.Entries.Count,
                instantiated,
                failures,
                checkedUtc = DateTime.UtcNow.ToString("O"),
                playTested = false
            }, Formatting.Indented));
            if (failures.Count != 0)
                throw new InvalidDataException("Native UI validation failed: " + string.Join("; ", failures));
            Debug.Log($"Unity native UI validation passed: {paths.Length} Prefabs, {instantiated} Catalog instances.");
        }

        private static bool IsLegacyPath(string path) =>
            path.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase)
            || path.StartsWith("Assets/Screenshots/", StringComparison.OrdinalIgnoreCase)
            || path.StartsWith("Assets/Resources/ProjectXAnimation/", StringComparison.OrdinalIgnoreCase);
    }
}
