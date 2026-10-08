using System;
using System.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class BagNativePrefabValidator
    {
        private const string NativePrefab = "Assets/Prefabs/Bag/beibao.prefab";
        private const string CatalogPath = "Assets/Prefabs/Catalog/Catalog.asset";
        private const string LegacyRoot = "Assets/ProjectX/res/";
        private static readonly (string key, string prefab, string reference, string source)[] NativeViews =
        {
            ("beibao", "Assets/Prefabs/Bag/beibao.prefab", "Assets/Prefabs/Catalog/beibao.asset", "Unity/Bag"),
            ("BagPopupFrame", "Assets/Prefabs/Bag/BagPopupFrame.prefab", "Assets/Prefabs/Catalog/BagPopupFrame.asset", "Unity/Bag/BagPopupFrame"),
            ("BagEnterNumLayer", "Assets/Prefabs/Bag/EnterNumLayer.prefab", "Assets/Prefabs/Catalog/BagEnterNumLayer.asset", "Unity/Bag/BagEnterNumLayer"),
            ("BagOpenBox", "Assets/Prefabs/Bag/OpenBox_1Layer.prefab", "Assets/Prefabs/Catalog/BagOpenBox.asset", "Unity/Bag/BagOpenBox"),
            ("BagItemSource", "Assets/Prefabs/Bag/huoqutujing.prefab", "Assets/Prefabs/Catalog/BagItemSource.asset", "Unity/Bag/BagItemSource"),
        };

        [MenuItem("Tools/ProjectX UI/Validate Unity-owned Bag Prefab")]
        public static void Validate()
        {
            UiPrefabCatalog catalog = AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>(CatalogPath);
            if (catalog == null) throw new InvalidOperationException("UI Prefab Catalog could not be loaded.");
            foreach (var view in NativeViews)
            {
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(view.prefab);
                if (prefab == null) throw new InvalidOperationException("Unity-owned Bag Prefab could not be loaded: " + view.prefab);
                string[] legacyComponents = prefab.GetComponentsInChildren<Component>(true)
                    .Where(component => component != null)
                    .Select(component => component.GetType().Name)
                    .Where(typeName => typeName == "UiPrefabIdentity"
                        || typeName == "CocosTimelinePlayer"
                        || typeName == "CocosUiBinding")
                    .Distinct()
                    .ToArray();
                if (legacyComponents.Length != 0)
                    throw new InvalidOperationException(view.key + " contains legacy components: "
                        + string.Join(", ", legacyComponents));
                string[] legacyDependencies = AssetDatabase.GetDependencies(view.prefab, true)
                    .Where(path => path.StartsWith(LegacyRoot, StringComparison.OrdinalIgnoreCase))
                    .ToArray();
                if (legacyDependencies.Length != 0)
                    throw new InvalidOperationException(view.key + " depends on preserved legacy assets: "
                        + string.Join(", ", legacyDependencies));
                if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(prefab) != 0)
                    throw new InvalidOperationException(view.key + " has missing scripts.");
                UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(view.reference);
                if (reference == null || reference.Prefab != prefab)
                    throw new InvalidOperationException(view.key + " UiPrefabReference does not point to its Unity-owned Prefab.");
                UiPrefabCatalogEntry entry = catalog.Entries.FirstOrDefault(candidate => candidate.Key == view.key);
                if (entry == null || entry.Source != view.source)
                    throw new InvalidOperationException(view.key + " Catalog entry is not marked as Unity-owned.");
                Debug.Log($"[BagNativePrefabValidator] {view.key}: nodes={prefab.GetComponentsInChildren<Transform>(true).Length}, missingScripts=0, legacyDependencies=0.");
            }
        }
    }
}
