using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public static class RedDotVisual
    {
        // Clone the authored common dot only when a new entry/tab lacks one.
        public static void Set(Transform owner, bool visible, Transform template)
        {
            if (owner == null) return;
            Transform dot = owner.Find("Prompt");
            if (dot == null && visible)
            {
                if (template == null || template.GetComponent<Image>()?.sprite == null)
                    throw new InvalidOperationException("An authored red-dot Sprite is required.");
                dot = UnityEngine.Object.Instantiate(template.gameObject, owner, false).transform;
                dot.name = "Prompt";
                RectTransform rect = dot as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = rect.anchorMax = Vector2.one;
                    rect.pivot = new Vector2(.5f, .5f);
                    rect.anchoredPosition = new Vector2(-8f, -8f);
                    rect.localScale = Vector3.one;
                }
                foreach (Graphic graphic in dot.GetComponentsInChildren<Graphic>(true))
                    graphic.raycastTarget = false;
            }
            if (dot != null) dot.gameObject.SetActive(visible);
        }
    }
}
