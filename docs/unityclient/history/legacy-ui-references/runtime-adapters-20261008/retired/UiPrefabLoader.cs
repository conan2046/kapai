using System;
using UnityEngine;

namespace ProjectX.UI
{
    public static class UiPrefabLoader
    {
        private static ICocosUiAssetProvider provider;
        private static Func<ICocosUiAssetProvider> providerFactory;

        public static void Configure(ICocosUiAssetProvider value)
        {
            provider = value;
            providerFactory = null;
        }

        public static void Configure(Func<ICocosUiAssetProvider> factory)
        {
            provider = null;
            providerFactory = factory ?? throw new ArgumentNullException(nameof(factory));
        }

        private static ICocosUiAssetProvider Provider => provider ??= providerFactory?.Invoke();

        public static CocosUiView Load(string key, Transform parent)
        {
            if (Provider == null)
                throw new InvalidOperationException("UI asset provider has not been configured.");
            return Provider.Instantiate(key, parent);
        }

        public static bool Release(CocosUiView view)
        {
            if (view == null) return false;
            if (provider == null && providerFactory == null)
                throw new InvalidOperationException("UI asset provider has not been configured.");
            if (provider == null) return false;
            // Parent release also releases registered children. Subsequent child
            // cleanup must therefore be idempotent during page teardown/OnDestroy.
            return Provider.Release(view);
        }
    }
}
