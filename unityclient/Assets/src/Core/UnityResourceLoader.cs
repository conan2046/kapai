using ProjectX.Foundation;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed class UnityResourceLoader : IResourceLoader
    {
        public T Load<T>(string resourcePath) where T : class
        {
            Object asset = UnityAssetReference.Load(resourcePath, typeof(T))
                ?? Resources.Load(resourcePath, typeof(T));
            return asset as T;
        }

        public void Unload(object asset)
        {
            if (asset == null) return;
            if (!(asset is Object unityAsset))
                throw new System.ArgumentException("Only Unity assets can be unloaded.", nameof(asset));
            Resources.UnloadAsset(unityAsset);
        }
    }
}
