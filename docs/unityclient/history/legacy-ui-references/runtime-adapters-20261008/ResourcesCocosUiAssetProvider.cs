using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace ProjectX.UI
{
    /// <summary>
    /// Transitional adapter for modules that still resolve Cocos source tokens
    /// and consume identity-backed views. New Unity UI must use
    /// <see cref="ResourcesUiAssetProvider"/> directly.
    /// </summary>
    public sealed class ResourcesCocosUiAssetProvider : ICocosUiAssetProvider
    {
        private readonly ResourcesUiAssetProvider unityAssets;
        private readonly Dictionary<string, CocosUiView> singletonViews =
            new Dictionary<string, CocosUiView>(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<CocosUiView, UnityUiView> backingViews =
            new Dictionary<CocosUiView, UnityUiView>();

        public ResourcesCocosUiAssetProvider(ResourcesUiAssetProvider unityAssets)
        {
            this.unityAssets = unityAssets ?? throw new ArgumentNullException(nameof(unityAssets));
        }

        public CocosUiView FindOrLoadBySource(string sourceToken, bool excludeBackup = false)
        {
            if (string.IsNullOrWhiteSpace(sourceToken))
                throw new ArgumentException("UI source token is required.", nameof(sourceToken));

            UiPrefabCatalogEntry entry = unityAssets.CatalogEntries
                .Where(item => !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0
                    && (!excludeBackup || item.Source.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0))
                .OrderBy(item => item.Key, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();
            return entry == null ? null : GetOrCreate(entry.Key);
        }

        public CocosUiView GetOrCreate(string key, Transform parent = null)
        {
            if (singletonViews.TryGetValue(key, out CocosUiView existing) && existing?.GameObject != null)
                return existing;

            UnityUiView unityView = unityAssets.GetUnityOrCreate(key, parent);
            return Track(unityView, key);
        }

        public CocosUiView Instantiate(string key, Transform parent)
        {
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            return Track(unityAssets.InstantiateUnity(key, parent), null);
        }

        public bool Release(CocosUiView view)
        {
            if (view == null || !backingViews.TryGetValue(view, out UnityUiView unityView))
                return false;

            backingViews.Remove(view);
            foreach (string key in singletonViews
                .Where(pair => pair.Value == view)
                .Select(pair => pair.Key)
                .ToArray())
                singletonViews.Remove(key);
            return unityAssets.Release(unityView);
        }

        private CocosUiView Track(UnityUiView unityView, string singletonKey)
        {
            if (unityView == null || unityView.GameObject == null) return null;
            var cocosView = new CocosUiView(unityView.GameObject);
            backingViews[cocosView] = unityView;
            if (!string.IsNullOrEmpty(singletonKey)) singletonViews[singletonKey] = cocosView;
            return cocosView;
        }
    }
}
