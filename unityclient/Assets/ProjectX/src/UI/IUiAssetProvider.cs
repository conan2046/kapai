using System;
using UnityEngine;

namespace ProjectX.UI
{
    // Consumer-side capability used by UI presenters. The implementation stays
    // in Core for now; presenters must not depend on Core.ResourceService.
    public interface IUiResourceProvider
    {
        Sprite LoadEquipmentIcon(string picture);
        Sprite LoadEquipmentIcon(string picture, out bool usedPlaceholder);
        Sprite LoadFaBaoIcon(string picture, out bool usedPlaceholder);
        Sprite LoadGameplayShopIcon(int picture, out bool usesItemIcon, out bool usedPlaceholder);
        Sprite LoadHeroBodyPortrait(int picture);
        Sprite LoadHeroBodyPortrait(int picture, out bool usedPlaceholder);
        Sprite LoadHeroPortrait(int picture);
        Sprite LoadHeroPortrait(int picture, out bool usedPlaceholder);
        Sprite LoadItemIcon(int picture);
        Sprite LoadItemIcon(int picture, out bool usedPlaceholder);
        Sprite LoadFirst(params string[] resourcePaths);
        Sprite LoadPlayerRoundPortrait(int head);
        Sprite LoadPlayerSavePortrait(int picture);
        Sprite LoadSprite(string resourcePath);
    }

    public interface IServerTimeProvider
    {
        event Action Synchronized;
        bool IsSynchronized { get; }
        uint UnixSeconds { get; }
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
