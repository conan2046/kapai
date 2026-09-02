using System;
using System.Linq;
using ProjectX.UI.Migration;
using UnityEngine;

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
            CocosUiBinding binding = Resources.FindObjectsOfTypeAll<CocosUiBinding>()
                .Where(item => item != null
                    && item.gameObject.scene.IsValid()
                    && !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0
                    && (!excludeBackup || item.Source.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0))
                .OrderByDescending(item => item.gameObject.activeInHierarchy)
                .ThenBy(item => item.GetInstanceID())
                .FirstOrDefault();
            return binding == null
                ? assets?.FindOrLoadBySource(sourceToken, excludeBackup)
                : new CocosUiView(binding);
        }

        public void SetExclusiveVisibleBySource(string sourceToken, CocosUiView selected, bool visible)
        {
            foreach (CocosUiBinding binding in Resources.FindObjectsOfTypeAll<CocosUiBinding>()
                .Where(item => item != null && item.gameObject.scene.IsValid()
                    && !string.IsNullOrEmpty(item.Source)
                    && item.Source.IndexOf(sourceToken, StringComparison.OrdinalIgnoreCase) >= 0))
            {
                binding.gameObject.SetActive(visible && selected != null && binding == selected.Binding);
            }
        }
    }
}
