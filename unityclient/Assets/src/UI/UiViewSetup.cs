using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    internal static class UiViewSetup
    {
        public static void Initialize(GameObject root)
        {
            if (root == null) return;
            if (root.GetComponent<UiButtonFeedbackScope>() == null)
                root.AddComponent<UiButtonFeedbackScope>();

            foreach (Text text in root.GetComponentsInChildren<Text>(true))
            {
                if (text == null || string.IsNullOrEmpty(text.text)
                    || text.verticalOverflow != VerticalWrapMode.Truncate) continue;

                RectTransform rect = text.rectTransform;
                float currentHeight = rect.rect.height;
                float preferredHeight = text.preferredHeight;
                float canvasScale = text.canvas != null ? Mathf.Max(0.01f, text.canvas.scaleFactor) : 1f;
                float shortfall = preferredHeight - currentHeight;
                if (shortfall <= 0f || shortfall > 1f / canvasScale) continue;

                rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, preferredHeight + 1f / canvasScale);
                text.SetVerticesDirty();
            }
        }
    }
}
