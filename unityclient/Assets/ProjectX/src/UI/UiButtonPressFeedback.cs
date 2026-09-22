using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Shared tactile feedback for uGUI buttons. Keeps each button's authored scale
    /// and only applies a temporary press scale while the pointer is down.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class UiButtonPressFeedback : MonoBehaviour,
        IPointerDownHandler, IPointerUpHandler, IPointerExitHandler
    {
        [SerializeField, Range(0.85f, 0.99f)] private float pressedScale = 0.94f;
        [SerializeField, Min(0f)] private float duration = 0.08f;

        private Vector3 baseScale;
        private Coroutine animation;
        private Button button;

        public static UiButtonPressFeedback Ensure(Button target)
        {
            if (target == null) return null;
            UiButtonPressFeedback feedback = target.GetComponent<UiButtonPressFeedback>();
            return feedback != null ? feedback : target.gameObject.AddComponent<UiButtonPressFeedback>();
        }

        private void Awake()
        {
            button = GetComponent<Button>();
            baseScale = transform.localScale;
        }

        private void OnEnable()
        {
            baseScale = transform.localScale;
            SetScale(baseScale);
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (button == null || !button.interactable) return;
            Animate(baseScale * pressedScale);
        }

        public void OnPointerUp(PointerEventData eventData) => Restore();

        public void OnPointerExit(PointerEventData eventData) => Restore();

        private void OnDisable()
        {
            if (animation != null) StopCoroutine(animation);
            animation = null;
            SetScale(baseScale);
        }

        private void Restore() => Animate(baseScale);

        private void Animate(Vector3 target)
        {
            if (animation != null) StopCoroutine(animation);
            animation = duration <= 0f
                ? null
                : StartCoroutine(AnimateScale(target));
            if (duration <= 0f) SetScale(target);
        }

        private IEnumerator AnimateScale(Vector3 target)
        {
            Vector3 start = transform.localScale;
            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                float t = Mathf.Clamp01(elapsed / duration);
                t = t * t * (3f - 2f * t);
                SetScale(Vector3.LerpUnclamped(start, target, t));
                yield return null;
            }
            SetScale(target);
            animation = null;
        }

        private void SetScale(Vector3 value)
        {
            if (transform != null) transform.localScale = value;
        }
    }

    /// <summary>
    /// Covers buttons created after a migrated view is opened, such as list rows
    /// and reward cells instantiated by presenters.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class UiButtonFeedbackScope : MonoBehaviour
    {
        [SerializeField, Min(0.05f)] private float scanInterval = 0.2f;
        private float nextScan;
        private readonly HashSet<Button> known = new HashSet<Button>();

        private void OnEnable()
        {
            nextScan = 0f;
            Scan();
        }

        private void Update()
        {
            if (Time.unscaledTime < nextScan) return;
            Scan();
        }

        private void Scan()
        {
            nextScan = Time.unscaledTime + scanInterval;
            foreach (Button target in GetComponentsInChildren<Button>(true))
            {
                if (target == null || !known.Add(target)) continue;
                UiButtonPressFeedback.Ensure(target);
            }
        }
    }
}
