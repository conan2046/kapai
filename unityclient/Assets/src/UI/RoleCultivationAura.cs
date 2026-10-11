using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class RoleCultivationAura : MonoBehaviour
    {
        [SerializeField] private RawImage glow;
        private int stage;
        private Color tint;

        public void Show(int smallStage, Color quality)
        {
            stage = Math.Max(1, Math.Min(10, smallStage));
            tint = quality;
            if (glow == null) throw new InvalidOperationException("Realm prefab stage aura is missing.");
            Refresh();
        }

        private void Update() => Refresh();
        private void Refresh()
        {
            if (glow == null) return;
            float strength = stage / 10f;
            Color color = tint;
            color.a = (.13f + strength * .22f) * (1f + .08f * Mathf.Sin(Time.unscaledTime * 2f));
            glow.color = color;
        }
    }
}
