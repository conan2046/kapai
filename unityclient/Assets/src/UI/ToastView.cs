using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ToastView : MonoBehaviour
    {
        [SerializeField] private CanvasGroup presentation;
        [SerializeField] private Text label;
        [SerializeField, Min(0f)] private float fadeSeconds = .25f;
        private float measuredWidth = -1f;

        public CanvasGroup Presentation => presentation != null ? presentation
            : throw new InvalidOperationException("Toast prefab CanvasGroup reference is missing.");
        public Text Label => label != null ? label
            : throw new InvalidOperationException("Toast prefab Text reference is missing.");
        public float FadeSeconds => fadeSeconds;

        private void LateUpdate()
        {
            if (label != null && !Mathf.Approximately(label.rectTransform.rect.width, measuredWidth))
                ResizeToText();
        }

        public void ResizeToText()
        {
            measuredWidth = Label.rectTransform.rect.width;
            var settings = Label.GetGenerationSettings(new Vector2(measuredWidth, 0f));
            Label.cachedTextGeneratorForLayout.Populate(Label.text, settings);
            int lines = Math.Max(1, Label.cachedTextGeneratorForLayout.lineCount);
            ((RectTransform)transform).SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, 8f + Label.fontSize * lines);
        }
    }
}
