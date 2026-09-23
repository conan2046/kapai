using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.UI.Migration;
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
        private readonly Dictionary<string, CocosUiView> singletons =
            new Dictionary<string, CocosUiView>(StringComparer.OrdinalIgnoreCase);
        private readonly HashSet<CocosUiView> transients = new HashSet<CocosUiView>();
        private readonly HashSet<string> loading = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private bool disposed;

        public ResourcesUiAssetProvider(Transform root)
        {
            this.root = root != null ? root : throw new ArgumentNullException(nameof(root));
            catalog = Resources.Load<UiPrefabCatalog>(CatalogPath);
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

        public CocosUiView FindOrLoadBySource(string sourceToken, bool excludeBackup = false)
        {
            ThrowIfDisposed();
            if (string.IsNullOrWhiteSpace(sourceToken))
                throw new ArgumentException("UI source token is required.", nameof(sourceToken));
            UiPrefabCatalogEntry entry = entriesByKey.Values
                .Where(item => !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0
                    && (!excludeBackup || item.Source.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0))
                .OrderBy(item => item.Key, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();
            return entry == null ? null : GetOrCreate(entry.Key);
        }

        public CocosUiView GetOrCreate(string key, Transform parent = null)
        {
            ThrowIfDisposed();
            UiPrefabCatalogEntry entry = RequireEntry(key);
            if (singletons.TryGetValue(entry.Key, out CocosUiView existing) && IsAlive(existing))
                return existing;
            singletons.Remove(entry.Key);
            if (!loading.Add(entry.Key))
                throw new InvalidOperationException($"Circular UI prefab parent dependency: {entry.Key}");
            try
            {
                Transform resolvedParent = parent;
                if (resolvedParent == null && !string.IsNullOrWhiteSpace(entry.ParentKey))
                    resolvedParent = GetOrCreate(entry.ParentKey).GameObject.transform;
                CocosUiView view = Create(entry.Key, resolvedParent ?? root, entry.DefaultActive);
                singletons.Add(entry.Key, view);
                return view;
            }
            finally
            {
                loading.Remove(entry.Key);
            }
        }

        public CocosUiView Instantiate(string key, Transform parent)
        {
            ThrowIfDisposed();
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            CocosUiView view = Create(RequireEntry(key).Key, parent, false);
            transients.Add(view);
            return view;
        }

        public bool Release(CocosUiView view)
        {
            if (view == null) return false;
            // UiRouter may wrap an already-owned binding in a new CocosUiView.
            // Ownership is therefore tied to the runtime GameObject, not the
            // short-lived wrapper instance passed by the caller.
            GameObject target = view.GameObject;
            string singletonKey = singletons
                .Where(pair => pair.Value?.GameObject != null && pair.Value.GameObject == target)
                .Select(pair => pair.Key)
                .FirstOrDefault();
            CocosUiView transient = transients
                .FirstOrDefault(item => item?.GameObject != null && item.GameObject == target);
            bool owned = transient != null;
            if (owned) transients.Remove(transient);
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
            foreach (CocosUiView view in transients.Concat(singletons.Values).Distinct().ToArray())
                if (view?.GameObject != null) DestroyOwned(view.GameObject);
            transients.Clear();
            singletons.Clear();
            if (catalog != null) Resources.UnloadAsset(catalog);
        }

        private CocosUiView Create(string key, Transform parent, bool active)
        {
            UiPrefabReference reference = Resources.Load<UiPrefabReference>(ResourceRoot + key);
            if (reference == null || reference.Prefab == null)
                throw new InvalidOperationException($"UI prefab reference was not found: {key}");
            GameObject instance = UnityEngine.Object.Instantiate(reference.Prefab, parent, false);
            instance.name = $"DynamicUi_{key}";
            CocosUiBinding binding = instance.GetComponent<CocosUiBinding>()
                ?? instance.GetComponentInChildren<CocosUiBinding>(true);
            if (binding == null)
            {
                DestroyOwned(instance);
                throw new InvalidOperationException($"UI prefab has no CocosUiBinding: {key}");
            }
            instance.SetActive(active);
            NormalizeFixedRootOrder(key, instance.transform);
            Resources.UnloadAsset(reference);
            return new CocosUiView(binding);
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
            if (!singletons.TryGetValue(key, out CocosUiView view)) return;
            singletons.Remove(key);
            if (view?.GameObject != null) DestroyOwned(view.GameObject);
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

        private static bool IsAlive(CocosUiView view) => view?.GameObject != null;

        private static void DestroyOwned(UnityEngine.Object value)
        {
            if (value == null) return;
            if (Application.isPlaying) UnityEngine.Object.Destroy(value);
            else UnityEngine.Object.DestroyImmediate(value);
        }
    }
}
