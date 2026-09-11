using ProjectX.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    internal static class ItemQualityVisual
    {
        public static void ApplyFrame(Image frame, int quality, ResourceService resources)
        {
            if (frame == null || resources == null) return;
            frame.sprite = resources.LoadFirst(
                $"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}");
            frame.enabled = frame.sprite != null;
            frame.preserveAspect = true;
            frame.color = Color.white;
            frame.raycastTarget = false;
        }

        public static Image EnsureIcon(Transform frame, string name = "Icon")
        {
            if (frame == null) return null;
            Transform existing = frame.Find(name);
            Image image = existing?.GetComponent<Image>();
            if (image != null) return image;

            var iconObject = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = iconObject.GetComponent<RectTransform>();
            rect.SetParent(frame, false);
            rect.anchorMin = new Vector2(0.08f, 0.08f);
            rect.anchorMax = new Vector2(0.92f, 0.92f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            image = iconObject.GetComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
            return image;
        }
    }
}
