using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeMonopolyDiceAnimation : MonoBehaviour
    {
        private const string ControllerPath = "Animations/Monopoly/MonopolyDice";
        private const string StateName = "MonopolyDiceRoll";
        private Animator animator;
        private bool playing;
        private float elapsed;

        public bool IsPlaying => playing;

        public bool Load()
        {
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            RuntimeAnimatorController controller = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(ControllerPath);
            if (controller == null) return false;
            EnsureVisual();
            animator.runtimeAnimatorController = controller;
            animator.enabled = false;
            return true;
        }

        public bool Play()
        {
            if (animator == null || animator.runtimeAnimatorController == null) return false;
            int stateHash = Animator.StringToHash(StateName);
            if (!animator.HasState(0, stateHash)) return false;
            gameObject.SetActive(true);
            animator.enabled = true;
            animator.speed = 1f;
            animator.Rebind();
            animator.Play(stateHash, 0, 0f);
            animator.Update(0f);
            elapsed = 0f;
            playing = true;
            return true;
        }

        public void Stop()
        {
            playing = false;
            if (animator != null) animator.enabled = false;
        }

        private void Update()
        {
            if (!playing || animator == null || !animator.enabled) return;
            elapsed += Time.deltaTime;
            if (elapsed >= 0.8f) playing = false;
        }

        private void EnsureVisual()
        {
            Transform visual = transform.Find("__UnityNativePart");
            if (visual == null)
            {
                GameObject child = new GameObject("__UnityNativePart", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                child.transform.SetParent(transform, false);
                RectTransform rect = child.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
                visual = child.transform;
            }
            Image image = visual.GetComponent<Image>() ?? visual.gameObject.AddComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
        }
    }
}
