using System;
using ProjectX.Data;
using Spine.Unity;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // A UI instance of the selected role asset; the player's persisted sex owns selection.
    public sealed class RoleSpinePortrait : MonoBehaviour
    {
        private string prefabKey;
        private SkeletonGraphic portrait;
        public string PrefabName => portrait == null ? string.Empty : portrait.gameObject.name.Replace("(Clone)", "");
        public bool IsPlaying => portrait != null && portrait.gameObject.activeInHierarchy
            && portrait.AnimationState?.GetCurrent(0) != null && !portrait.freeze;

        public static string ResolvePrefabName(string template, byte sex)
        {
            if (sex > 1) throw new ArgumentOutOfRangeException(nameof(sex));
            return RoleVisualCatalog.Current.Resolve(template).Prefab(sex);
        }

        public void Show(string template, byte sex)
        {
            string key = "Prefabs/Spine/UI/Role/" + ResolvePrefabName(template, sex);
            if (portrait != null && prefabKey == key) return;
            GameObject prefab = UnityAssetReference.LoadAsset<GameObject>(key);
            if (prefab == null) throw new InvalidOperationException("Missing JingJie Spine prefab: " + key);
            if (portrait == null) portrait = GetComponentInChildren<SkeletonGraphic>(true);
            var source = prefab.GetComponent<SkeletonGraphic>();
            if (portrait == null || portrait.skeletonDataAsset != source.skeletonDataAsset)
            {
                if (portrait != null) { portrait.gameObject.SetActive(false); Destroy(portrait.gameObject); }
                var instance = Instantiate(prefab, transform, false);
                portrait = instance.GetComponent<SkeletonGraphic>();
            }
            if (portrait == null) throw new InvalidOperationException("JingJie prefab requires SkeletonGraphic: " + key);
            prefabKey = key;
            portrait.raycastTarget = false;
            portrait.Initialize(false);
            string animation = RoleVisualCatalog.Current.Resolve(template).Animation;
            if (portrait.Skeleton.Data.FindAnimation(animation) == null)
                throw new InvalidOperationException("Missing role_visual animation: " + key + "/" + animation);
            portrait.AnimationState.SetAnimation(0, animation, true);
        }

        public void Clear()
        {
            if (portrait != null) Destroy(portrait.gameObject);
            portrait = null;
            prefabKey = null;
        }

    }
}
