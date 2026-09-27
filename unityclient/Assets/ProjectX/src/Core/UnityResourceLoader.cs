using ProjectX.Foundation;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed class UnityResourceLoader : IResourceLoader
    {
        public T Load<T>(string resourcePath) where T : class
        {
            Object asset = Resources.Load(resourcePath, typeof(T));
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
