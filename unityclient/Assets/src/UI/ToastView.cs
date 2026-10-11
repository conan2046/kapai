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

        public CanvasGroup Presentation => presentation != null ? presentation
            : throw new InvalidOperationException("Toast prefab CanvasGroup reference is missing.");
        public Text Label => label != null ? label
            : throw new InvalidOperationException("Toast prefab Text reference is missing.");
        public float FadeSeconds => fadeSeconds;

        public void ResizeToText()
        {
            var settings = Label.GetGenerationSettings(new Vector2(Label.rectTransform.rect.width, 0f));
            Label.cachedTextGeneratorForLayout.Populate(Label.text, settings);
            int lines = Math.Max(1, Label.cachedTextGeneratorForLayout.lineCount);
            ((RectTransform)transform).SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, 8f + Label.fontSize * lines);
        }
    }
}
