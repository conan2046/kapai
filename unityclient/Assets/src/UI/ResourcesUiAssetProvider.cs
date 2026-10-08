using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace ProjectX.UI
{
    public sealed class ResourcesUiAssetProvider : IUiAssetProvider
    {
        private const string ResourceRoot = "UiPrefabs/";
        private const string CatalogPath = ResourceRoot + "Catalog";

        private readonly Transform root;
        private readonly UiPrefabCatalog catalog;
        private readonly Dictionary<string, UiPrefabCatalogEntry> entriesByKey;
        private readonly Dictionary<string, UiPrefabCatalogEntry[]> childrenByParentKey;
        private readonly Dictionary<string, GameObject> singletons =
            new Dictionary<string, GameObject>(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, UnityUiView> unityViews =
            new Dictionary<string, UnityUiView>(StringComparer.OrdinalIgnoreCase);
        private readonly HashSet<GameObject> transients = new HashSet<GameObject>();
        private readonly HashSet<string> loading = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private bool disposed;

        public ResourcesUiAssetProvider(Transform root)
        {
            this.root = root != null ? root : throw new ArgumentNullException(nameof(root));
            catalog = ProjectX.Foundation.ResourceLoader.Load<UiPrefabCatalog>(CatalogPath);
            if (catalog == null)
                throw new InvalidOperationException($"UI prefab catalog was not found: Resources/{CatalogPath}");
            entriesByKey = catalog.Entries
                .Where(entry => entry != null && !string.IsNullOrWhiteSpace(entry.Key))
                .GroupBy(entry => entry.Key, StringComparer.OrdinalIgnoreCase)
                .ToDictionary(group => group.Key, group => group.Single(), StringComparer.OrdinalIgnoreCase);
            childrenByParentKey = entriesByKey.Values
                .Where(entry => !string.IsNullOrWhiteSpace(entry.ParentKey))
                .GroupBy(entry => entry.ParentKey, StringComparer.OrdinalIgnoreCase)
                .ToDictionary(group => group.Key, group => group.OrderBy(entry => entry.Key,
                    StringComparer.OrdinalIgnoreCase).ToArray(), StringComparer.OrdinalIgnoreCase);
        }

        public int LoadedSingletonCount => singletons.Values.Count(IsAlive);
        public int LoadedTransientCount => transients.Count(IsAlive);

        internal IEnumerable<UiPrefabCatalogEntry> CatalogEntries => entriesByKey.Values;

        public UnityUiView GetUnityOrCreate(string key, Transform parent = null)
        {
            ThrowIfDisposed();
            UiPrefabCatalogEntry entry = RequireEntry(key);
            if (unityViews.TryGetValue(entry.Key, out UnityUiView existing) && IsAlive(existing))
                return existing;
            GameObject instance = GetOrCreateObject(entry, parent);
            UnityUiView view = new UnityUiView(instance);
            unityViews[entry.Key] = view;
            return view;
        }

        private GameObject GetOrCreateObject(UiPrefabCatalogEntry entry, Transform parent)
        {
            if (singletons.TryGetValue(entry.Key, out GameObject existing) && IsAlive(existing))
                return existing;
            singletons.Remove(entry.Key);
            unityViews.Remove(entry.Key);
            if (!loading.Add(entry.Key))
                throw new InvalidOperationException($"Circular UI prefab parent dependency: {entry.Key}");
            try
            {
                Transform resolvedParent = parent;
                if (resolvedParent == null && !string.IsNullOrWhiteSpace(entry.ParentKey))
                    resolvedParent = GetOrCreateObject(RequireEntry(entry.ParentKey), null).transform;
                GameObject instance = Create(entry.Key, resolvedParent ?? root, entry.DefaultActive);
                singletons.Add(entry.Key, instance);
                return instance;
            }
            finally
            {
                loading.Remove(entry.Key);
            }
        }

        public UnityUiView InstantiateUnity(string key, Transform parent)
        {
            ThrowIfDisposed();
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            return new UnityUiView(InstantiateObject(key, parent));
        }

        private GameObject InstantiateObject(string key, Transform parent)
        {
            GameObject instance = Create(RequireEntry(key).Key, parent, false);
            transients.Add(instance);
            return instance;
        }

        public bool Release(UnityUiView view) => ReleaseObject(view?.GameObject);

        internal bool Release(GameObject view) => ReleaseObject(view);

        private bool ReleaseObject(GameObject target)
        {
            if (target == null) return false;
            string singletonKey = singletons
                .Where(pair => pair.Value != null && pair.Value == target)
                .Select(pair => pair.Key)
                .FirstOrDefault();
            bool owned = transients.Remove(target);
            if (!string.IsNullOrEmpty(singletonKey))
            {
                ReleaseSingletonTree(singletonKey);
                owned = true;
            }
            else if (owned && target != null) DestroyOwned(target);
            return owned;
        }

        public void Dispose()
        {
            if (disposed) return;
            disposed = true;
            foreach (GameObject view in transients.Concat(singletons.Values).Distinct().ToArray())
                if (view != null) DestroyOwned(view);
            transients.Clear();
            singletons.Clear();
            unityViews.Clear();
            if (catalog != null) ProjectX.Foundation.ResourceLoader.Unload(catalog);
        }

        private GameObject Create(string key, Transform parent, bool active)
        {
            UiPrefabReference reference = ProjectX.Foundation.ResourceLoader.Load<UiPrefabReference>(ResourceRoot + key);
            if (reference == null || reference.Prefab == null)
                throw new InvalidOperationException($"UI prefab reference was not found: {key}");
            GameObject instance = UnityEngine.Object.Instantiate(reference.Prefab, parent, false);
            instance.name = $"DynamicUi_{key}";
            instance.SetActive(active);
            UiViewSetup.Initialize(instance);
            NormalizeFixedRootOrder(key, instance.transform);
            ProjectX.Foundation.ResourceLoader.Unload(reference);
            return instance;
        }

        private void NormalizeFixedRootOrder(string key, Transform instance)
        {
            if (instance == null || !string.Equals(key, "OneLevelLayer", StringComparison.OrdinalIgnoreCase)
                && !string.Equals(key, "shop_bg", StringComparison.OrdinalIgnoreCase))
                return;

            Transform oneLevel = string.Equals(key, "OneLevelLayer", StringComparison.OrdinalIgnoreCase)
                ? instance
                : root.Find("DynamicUi_OneLevelLayer");
            Transform shopBackground = string.Equals(key, "shop_bg", StringComparison.OrdinalIgnoreCase)
                ? instance
                : root.Find("DynamicUi_shop_bg");
            if (oneLevel == null || shopBackground == null || oneLevel.parent != root
                || shopBackground.parent != root)
                return;

            int firstIndex = Math.Min(oneLevel.GetSiblingIndex(), shopBackground.GetSiblingIndex());
            oneLevel.SetSiblingIndex(firstIndex);
            shopBackground.SetSiblingIndex(firstIndex + 1);
        }

        private void ReleaseSingletonTree(string key)
        {
            if (childrenByParentKey.TryGetValue(key, out UiPrefabCatalogEntry[] children))
                foreach (UiPrefabCatalogEntry child in children)
                    ReleaseSingletonTree(child.Key);
            if (!singletons.TryGetValue(key, out GameObject view)) return;
            singletons.Remove(key);
            unityViews.Remove(key);
            if (view != null) DestroyOwned(view);
        }

        private UiPrefabCatalogEntry RequireEntry(string key)
        {
            if (string.IsNullOrWhiteSpace(key))
                throw new ArgumentException("UI prefab key is required.", nameof(key));
            if (!entriesByKey.TryGetValue(key, out UiPrefabCatalogEntry entry))
                throw new InvalidOperationException($"UI prefab is not registered: {key}");
            return entry;
        }

        private void ThrowIfDisposed()
        {
            if (disposed) throw new ObjectDisposedException(nameof(ResourcesUiAssetProvider));
        }

        private static bool IsAlive(UnityUiView view) => view?.GameObject != null;
        private static bool IsAlive(GameObject view) => view != null;

        private static void DestroyOwned(UnityEngine.Object value)
        {
            if (value == null) return;
            if (Application.isPlaying) UnityEngine.Object.Destroy(value);
            else UnityEngine.Object.DestroyImmediate(value);
        }
    }
}
