using System;
using UnityEngine;

namespace ProjectX.UI
{
    // Consumer-side capability used by UI presenters. The implementation stays
    // in Core for now; presenters must not depend on Core.ResourceService.
    public interface IUiResourceProvider
    {
        Sprite LoadItemIcon(int picture, out bool usedPlaceholder);
        Sprite LoadFirst(params string[] resourcePaths);
    }

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
