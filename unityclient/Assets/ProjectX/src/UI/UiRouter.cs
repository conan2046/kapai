using System;
using System.Linq;
using ProjectX.UI.Migration;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif

namespace ProjectX.UI
{
    public sealed class UiRouter
    {
        public const string MainHudSourceToken = "common/UImainLayer_new";
        private readonly IUiAssetProvider assets;

        public UiRouter()
        {
        }

        public UiRouter(IUiAssetProvider assets)
        {
            this.assets = assets ?? throw new ArgumentNullException(nameof(assets));
        }

        public CocosUiView FindBySource(string sourceToken, bool excludeBackup = false)
        {
            UiPrefabIdentity identity = Resources.FindObjectsOfTypeAll<UiPrefabIdentity>()
                .Where(item => IsRuntimeSceneObject(item.gameObject)
                    && !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0
                    && (!excludeBackup || item.Source.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0))
                .OrderByDescending(item => item.gameObject.activeInHierarchy)
                .ThenBy(item => item.GetInstanceID())
                .FirstOrDefault();
            return identity != null
                ? new CocosUiView(identity)
                : assets?.FindOrLoadBySource(sourceToken, excludeBackup);
        }

        public void SetExclusiveVisibleBySource(string sourceToken, CocosUiView selected, bool visible)
        {
            var identityRoots = Resources.FindObjectsOfTypeAll<UiPrefabIdentity>()
                .Where(item => IsRuntimeSceneObject(item.gameObject)
                    && !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0)
                .Select(item => item.gameObject);
            foreach (GameObject root in identityRoots.Distinct())
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
