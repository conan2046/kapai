using System.Globalization;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>Unity-owned presentation for authoritative PlayerHud power changes.</summary>
    public sealed class PowerChangedPopupView : MonoBehaviour
    {
        private const float Duration = 2.6f;
        private const float CountDuration = 0.55f;
        private CanvasGroup canvasGroup;
        private RectTransform content;
        private Text amount;
        private Image increaseMark;
        private Vector2 startPosition;
        private float elapsed;
        private ulong difference;
        private bool increased;
        private bool playing;
        private bool initialized;

        private void Awake() => EnsureBindings();

        private void EnsureBindings()
        {
            if (initialized) return;
            canvasGroup = GetComponent<CanvasGroup>();
            content = transform.Find("zhanlitisheng") as RectTransform;
            Transform label = transform.Find("zhanlitisheng/Power_bg/AtlasLabel_1");
            amount = label != null ? label.GetComponent<Text>() : null;
            increaseMark = label != null && label.Find("UPImage") != null
                ? label.Find("UPImage").GetComponent<Image>() : null;
            if (canvasGroup == null || content == null || amount == null)
                throw new MissingComponentException("Unity PlayerHud power popup bindings are incomplete.");
            startPosition = content.anchoredPosition;
            initialized = true;
        }

        public void Show(ulong previous, ulong current)
        {
            if (previous == current) return;
            gameObject.SetActive(true);
            EnsureBindings();
            increased = current > previous;
            difference = increased ? current - previous : previous - current;
            amount.text = (increased ? "+" : "-") + "0";
            amount.color = increased
                ? new Color(1f, 0.91f, 0.66f, 1f)
                : new Color(0.73f, 0.86f, 1f, 1f);
            if (increaseMark != null) increaseMark.gameObject.SetActive(increased);

            elapsed = 0f;
            playing = true;
            content.anchoredPosition = startPosition;
            canvasGroup.alpha = 0f;
        }

        private void Update()
        {
            AdvanceAnimation(Time.unscaledDeltaTime);
        }

        private void AdvanceAnimation(float deltaTime)
        {
            if (!playing) return;
            elapsed += deltaTime;
            float progress = Mathf.Clamp01(elapsed / Duration);
            float fadeIn = Mathf.Clamp01(progress / 0.12f);
            float fadeOut = 1f - Mathf.Clamp01((progress - 0.72f) / 0.28f);
            canvasGroup.alpha = fadeIn * fadeOut;
            content.anchoredPosition = startPosition + Vector2.up * (24f * progress);
            float countProgress = Mathf.Clamp01(elapsed / CountDuration);
            ulong shown = countProgress >= 1f ? difference : (ulong)(difference * (double)countProgress);
            amount.text = (increased ? "+" : "-") + shown.ToString(CultureInfo.InvariantCulture);
            if (elapsed < Duration) return;
            playing = false;
            gameObject.SetActive(false);
        }
    }
}
