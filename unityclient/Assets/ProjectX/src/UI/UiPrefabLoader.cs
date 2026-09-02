using System;
using UnityEngine;

namespace ProjectX.UI
{
    public static class UiPrefabLoader
    {
        private static IUiAssetProvider provider;

        public static void Configure(IUiAssetProvider value) => provider = value;

        public static CocosUiView Load(string key, Transform parent)
        {
            if (provider == null)
                throw new InvalidOperationException("UI asset provider has not been configured.");
            return provider.Instantiate(key, parent);
        }

        public static void Release(CocosUiView view)
        {
            if (view == null) return;
            if (provider == null)
                throw new InvalidOperationException("UI asset provider has not been configured.");
            // Parent release also releases registered children.  Subsequent child
            // cleanup must therefore be idempotent during page teardown/OnDestroy.
            provider.Release(view);
        }
    }
}
