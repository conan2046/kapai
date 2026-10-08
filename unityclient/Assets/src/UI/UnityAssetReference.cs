using System;
using System.Linq;
using UnityEngine;

namespace ProjectX.UI
{
    /// <summary>Small, per-key Unity references keep artwork outside Resources without eager bulk loading.</summary>
    public sealed class UnityAssetReference : ScriptableObject
    {
        [SerializeField] private UnityEngine.Object[] assets = Array.Empty<UnityEngine.Object>();
        [SerializeField] private Sprite primarySprite;
        [SerializeField] private Sprite[] sprites = Array.Empty<Sprite>();

        public void Initialize(UnityEngine.Object[] values, Sprite preferredSprite, Sprite[] spriteAssets)
        {
            assets = values ?? Array.Empty<UnityEngine.Object>();
            primarySprite = preferredSprite;
            sprites = spriteAssets ?? Array.Empty<Sprite>();
        }

        public static UnityEngine.Object Load(string key, Type type)
        {
            UnityAssetReference reference = Resources.Load<UnityAssetReference>("AssetReferences/" + key);
            if (reference == null) return null;
            if (reference.assets.Length == 0 || reference.assets.Any(value => value == null))
            {
                Resources.UnloadAsset(reference);
                reference = Resources.Load<UnityAssetReference>("AssetReferences/" + key);
                if (reference == null) return null;
            }
            if (type == typeof(Sprite)) return reference.primarySprite;
            return reference.assets.FirstOrDefault(value => value != null && type.IsInstanceOfType(value));
        }

        public static T LoadAsset<T>(string key) where T : UnityEngine.Object =>
            Load(key, typeof(T)) as T ?? Resources.Load<T>(key);

        public static T[] LoadAll<T>(string key) where T : UnityEngine.Object
        {
            UnityAssetReference reference = Resources.Load<UnityAssetReference>("AssetReferences/" + key);
            if (reference == null) return Resources.LoadAll<T>(key);
            if (typeof(T) == typeof(Sprite)) return reference.sprites.OfType<T>().ToArray();
            return reference.assets.OfType<T>().ToArray();
        }
    }
}
