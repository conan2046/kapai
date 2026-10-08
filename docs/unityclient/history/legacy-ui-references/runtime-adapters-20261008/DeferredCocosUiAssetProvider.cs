using System;
using UnityEngine;

namespace ProjectX.UI
{
    /// <summary>
    /// Creates the legacy Cocos-view adapter only when a module first requests
    /// a source-token or identity-backed view.
    /// </summary>
    public sealed class DeferredCocosUiAssetProvider : ICocosUiAssetProvider
    {
        private readonly Func<ICocosUiAssetProvider> factory;
        private ICocosUiAssetProvider provider;

        public DeferredCocosUiAssetProvider(Func<ICocosUiAssetProvider> factory)
        {
            this.factory = factory ?? throw new ArgumentNullException(nameof(factory));
        }

        public bool IsCreated => provider != null;

        private ICocosUiAssetProvider Provider => provider ??= factory()
            ?? throw new InvalidOperationException("Legacy UI asset provider factory returned null.");

        public CocosUiView FindOrLoadBySource(string sourceToken, bool excludeBackup = false) =>
            Provider.FindOrLoadBySource(sourceToken, excludeBackup);

        public CocosUiView GetOrCreate(string key, Transform parent = null) =>
            Provider.GetOrCreate(key, parent);

        public CocosUiView Instantiate(string key, Transform parent) =>
            Provider.Instantiate(key, parent);

        public bool Release(CocosUiView view) => provider != null && provider.Release(view);
    }
}
