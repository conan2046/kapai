using System;
using System.Linq;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif

namespace ProjectX.UI
{
    public sealed class UiRouter
    {
        private readonly IUiAssetProvider unityAssets;

        public UiRouter()
        {
        }

        public UiRouter(IUiAssetProvider unityAssets)
        {
            this.unityAssets = unityAssets ?? throw new ArgumentNullException(nameof(unityAssets));
        }

        public UnityUiView FindByKey(string key, bool excludeBackup = false)
        {
            if (string.IsNullOrWhiteSpace(key))
                throw new ArgumentException("UI prefab key is required.", nameof(key));

            UiPrefabKey marker = Resources.FindObjectsOfTypeAll<UiPrefabKey>()
                .Where(item => IsRuntimeSceneObject(item.gameObject)
                    && string.Equals(item.Key, key, StringComparison.OrdinalIgnoreCase)
                    && (!excludeBackup || item.Key.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0))
                .OrderByDescending(item => item.gameObject.activeInHierarchy)
                .ThenBy(item => item.GetInstanceID())
                .FirstOrDefault();
            return marker != null
                ? new UnityUiView(marker.gameObject)
                : unityAssets?.GetUnityOrCreate(key);
        }

        public void SetExclusiveVisibleByKey(string key, UnityUiView selected, bool visible)
        {
            var roots = Resources.FindObjectsOfTypeAll<UiPrefabKey>()
                .Where(item => IsRuntimeSceneObject(item.gameObject)
                    && string.Equals(item.Key, key, StringComparison.OrdinalIgnoreCase))
                .Select(item => item.gameObject);
            foreach (GameObject root in roots.Distinct())
                root.SetActive(visible && selected?.GameObject == root);
        }

        private static bool IsRuntimeSceneObject(GameObject gameObject)
        {
            if (gameObject == null || !gameObject.scene.IsValid()) return false;
#if UNITY_EDITOR
            if (EditorSceneManager.IsPreviewScene(gameObject.scene)) return false;
#endif
            return true;
        }
    }
}
