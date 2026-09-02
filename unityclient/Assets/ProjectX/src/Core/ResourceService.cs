using System;
using System.Collections.Generic;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed class ResourceService : IDisposable
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
            Sprite sprite = LoadFirst($"ItemIcons/equip{picture}", $"MonsterBust/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"ItemIcon/{picture}");
            return LoadSprite("MonsterBust/head_defult");
        }

        public Sprite LoadGameplayShopIcon(int picture, out bool usesItemIcon,
            out bool usedPlaceholder)
        {
            // ItemIcons carry their own shard corner; MonsterBust fallbacks do not.
            usesItemIcon = false;
            usedPlaceholder = false;
            if (picture <= 0) return null;
            Sprite sprite = LoadSprite($"ItemIcons/equip{picture}", false);
            if (sprite != null)
            {
                usesItemIcon = true;
                return sprite;
            }
            sprite = LoadFirst($"MonsterBust/{picture}_tou", $"MonsterBust/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"GameplayShopIcon/{picture}");
            return LoadSprite("MonsterBust/head_defult");
        }

        public Sprite LoadHeroPortrait(int picture) => LoadHeroPortrait(picture, out _);

        public Sprite LoadPlayerRoundPortrait(int head)
        {
            int resolvedHead = head == 4 || head == 5 ? head : 5;
            return LoadFirst($"RoleBust/{resolvedHead}_touxiang", $"MonsterBust/{resolvedHead}_tou");
        }

        public Sprite LoadEquipmentIcon(string picture) => LoadEquipmentIcon(picture, out _);

        public Sprite LoadEquipmentIcon(string picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (string.IsNullOrWhiteSpace(picture))
            {
                usedPlaceholder = true;
                RecordMissing("EquipmentIcon/empty");
                return LoadSprite("MonsterBust/head_defult");
            }
            string token = picture.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
                ? picture.Substring(0, picture.Length - 4) : picture;
            Sprite sprite = LoadFirst($"ItemIcons/{token}", $"ItemIcons/equip{token}", $"MonsterBust/{token}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"EquipmentIcon/{token}");
            return LoadSprite("MonsterBust/head_defult");
        }

        public Sprite LoadFaBaoIcon(string picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (string.IsNullOrWhiteSpace(picture))
            {
                usedPlaceholder = true;
                RecordMissing("FaBaoIcon/empty");
                return LoadSprite("MonsterBust/head_defult");
            }
            string token = picture.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
                ? picture.Substring(0, picture.Length - 4) : picture;
            Sprite sprite = LoadFirst($"FaBaoIcons/{token}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"FaBaoIcon/{token}");
            return LoadSprite("MonsterBust/head_defult");
        }

        public Sprite LoadHeroPortrait(int picture, out bool usedPlaceholder)
        {
            usedPlaceholder = false;
            if (picture <= 0) return LoadSprite("MonsterBust/head_defult");
            Sprite sprite = LoadFirst($"MonsterBust/{picture}_tou", $"MonsterBust/{picture}");
            if (sprite != null) return sprite;
            usedPlaceholder = true;
            RecordMissing($"HeroPortrait/{picture}");
            return LoadSprite("MonsterBust/head_defult");
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

            Sprite sprite = UnityEngine.Resources.Load<Sprite>(resourcePath);
            if (sprite == null)
            {
                Texture2D texture = UnityEngine.Resources.Load<Texture2D>(resourcePath);
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
