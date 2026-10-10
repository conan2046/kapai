using System;
using System.Collections.Generic;
using ProjectX.Diagnostics;
using ProjectX.Foundation;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed class ResourceService : IDisposable, IUiResourceProvider
    {
        private readonly Dictionary<string, Sprite> sprites = new Dictionary<string, Sprite>(StringComparer.Ordinal);
        private readonly HashSet<string> missingPaths = new HashSet<string>(StringComparer.Ordinal);
        private readonly List<Sprite> runtimeSprites = new List<Sprite>();

        public int CachedSpriteCount => sprites.Count;
        public int MissingSpriteCount => missingPaths.Count;
        public IReadOnlyCollection<string> MissingPaths => missingPaths;

        public Sprite LoadItemIcon(int picture) => LoadItemIcon(picture, out _);

        public Sprite LoadItemIcon(int picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (picture <= 0) return null;
            Sprite sprite = LoadFirst($"Art/Icons/Items/equip{picture}", $"Art/Portraits/Monsters/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"ItemIcon/{picture}");
            return LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadGameplayShopIcon(int picture, out bool usesItemIcon,
            out bool usedPlaceholder)
        {
            // ItemIcons carry their own shard corner; MonsterBust fallbacks do not.
            usesItemIcon = false;
            usedPlaceholder = false;
            if (picture <= 0) return null;
            Sprite sprite = LoadSprite($"Art/Icons/Items/equip{picture}", false);
            if (sprite != null)
            {
                usesItemIcon = true;
                return sprite;
            }
            sprite = LoadFirst($"Art/Portraits/Monsters/{picture}_tou", $"Art/Portraits/Monsters/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"GameplayShopIcon/{picture}");
            return LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadHeroPortrait(int picture) => LoadHeroPortrait(picture, out _);

        public Sprite LoadHeroBodyPortrait(int picture) => LoadHeroBodyPortrait(picture, out _);

        public Sprite LoadPlayerRoundPortrait(int head)
        {
            int resolvedHead = head == 4 || head == 5 ? head : 5;
            return LoadFirst($"Art/Portraits/Roles/{resolvedHead}_touxiang", $"Art/Portraits/Monsters/{resolvedHead}_tou");
        }

        public Sprite LoadPlayerSavePortrait(int picture)
        {
            if (picture <= 0) return null;
            int resolvedHead = picture == 4 || picture == 5 ? picture : 5;
            return LoadFirst($"Art/Portraits/Monsters/{picture}", $"Art/Portraits/Roles/{resolvedHead}_touxiang",
                $"Art/Portraits/Monsters/{picture}_tou", "Art/Portraits/Monsters/1", "Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadEquipmentIcon(string picture) => LoadEquipmentIcon(picture, out _);

        public Sprite LoadEquipmentIcon(string picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (string.IsNullOrWhiteSpace(picture))
            {
                usedPlaceholder = true;
                RecordMissing("EquipmentIcon/empty");
                return LoadSprite("Art/Portraits/Monsters/head_defult");
            }
            string token = picture.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
                ? picture.Substring(0, picture.Length - 4) : picture;
            Sprite sprite = LoadFirst($"Art/Icons/Items/{token}", $"Art/Icons/Items/equip{token}", $"Art/Portraits/Monsters/{token}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"EquipmentIcon/{token}");
            return LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadFaBaoIcon(string picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (string.IsNullOrWhiteSpace(picture))
            {
                usedPlaceholder = true;
                RecordMissing("FaBaoIcon/empty");
                return LoadSprite("Art/Portraits/Monsters/head_defult");
            }
            string token = picture.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
                ? picture.Substring(0, picture.Length - 4) : picture;
            Sprite sprite = LoadFirst($"Art/Icons/FaBao/{token}", $"Art/Icons/Items/{token}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"FaBaoIcon/{token}");
            return LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadHeroPortrait(int picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (picture <= 0) return LoadSprite("Art/Portraits/Monsters/head_defult");
            Sprite sprite = LoadFirst($"Art/Portraits/Monsters/{picture}_tou", $"Art/Portraits/Monsters/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"HeroPortrait/{picture}");
            return LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadHeroBodyPortrait(int picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (picture > 0)
            {
                Sprite sprite = LoadSprite($"Art/Portraits/Monsters/{picture}", false);
                if (sprite != null) return sprite;
            }
            usedPlaceholder = true;
            RecordMissing($"HeroBodyPortrait/{picture}");
            return LoadSprite("Art/Portraits/Monsters/1", false) ?? LoadSprite("Art/Portraits/Monsters/head_defult");
        }

        public Sprite LoadFirst(params string[] resourcePaths)
        {
            if (resourcePaths == null) return null;
            foreach (string path in resourcePaths)
            {
                Sprite sprite = LoadSprite(path, false);
                if (sprite != null) return sprite;
            }
            foreach (string path in resourcePaths)
                if (!string.IsNullOrWhiteSpace(path)) RecordMissing(path);
            return null;
        }

        public Sprite LoadSprite(string resourcePath) => LoadSprite(resourcePath, true);

        public void Clear()
        {
            foreach (Sprite sprite in runtimeSprites)
                if (sprite != null) UnityEngine.Object.Destroy(sprite);
            runtimeSprites.Clear();
            sprites.Clear();
            missingPaths.Clear();
        }

        public void Dispose() => Clear();

        private Sprite LoadSprite(string resourcePath, bool recordMissing)
        {
            if (string.IsNullOrWhiteSpace(resourcePath)) return null;
            if (sprites.TryGetValue(resourcePath, out Sprite cached)) return cached;

            Sprite sprite = ResourceLoader.Load<Sprite>(resourcePath);
            if (sprite == null)
            {
                Texture2D texture = ResourceLoader.Load<Texture2D>(resourcePath);
                if (texture != null)
                {
                    sprite = Sprite.Create(texture, new Rect(0f, 0f, texture.width, texture.height),
                        new Vector2(0.5f, 0.5f), 100f);
                    sprite.name = texture.name + "_RuntimeSprite";
                    runtimeSprites.Add(sprite);
                }
            }

            sprites[resourcePath] = sprite;
            if (sprite == null && recordMissing) RecordMissing(resourcePath);
            return sprite;
        }

        private void RecordMissing(string resourcePath)
        {
            if (missingPaths.Add(resourcePath))
                ClientLog.Warning("Resource", "Sprite was not found", resourcePath);
        }
    }
}
