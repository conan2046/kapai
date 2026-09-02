using System;
using UnityEngine;

namespace ProjectX.UI
{
    public interface IUiAssetProvider : IDisposable
    {
        CocosUiView FindOrLoadBySource(string sourceToken, bool excludeBackup = false);
        CocosUiView GetOrCreate(string key, Transform parent = null);
        CocosUiView Instantiate(string key, Transform parent);
        bool Release(CocosUiView view);
        int LoadedSingletonCount { get; }
        int LoadedTransientCount { get; }
    }
}
