using System;
using System.Linq;
using ProjectX.UI.Migration;
using UnityEngine;

namespace ProjectX.UI
{
    public sealed class UiRouter
    {
        public const string MainHudSourceToken = "common/UImainLayer_new";

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
            return binding == null ? null : new CocosUiView(binding);
        }
    }
}
