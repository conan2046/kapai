using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeWorldStagePlayerAnimation : MonoBehaviour
    {
        private Animator animator;
        private Transform facingRoot;
        private int currentAction = 4;
        private float playbackSpeed = 1f;
        private float playbackNormalizedTime;

        public bool IsLoaded => animator != null && animator.runtimeAnimatorController != null;
        public bool IsPlaying => IsLoaded && animator.enabled;

        private void OnEnable()
        {
            if (!IsLoaded) return;
            animator.Rebind();
            PlayAction(currentAction, playbackSpeed, playbackNormalizedTime);
        }

        public bool Load(bool female, bool walking, bool flippedX, int action = 4)
        {
            string model = (female ? "H" : "K") + "_0_" + (walking ? "pb" : "fd");
            RuntimeAnimatorController controller = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(
                "Animations/World/StagePlayer/Animations/" + model);
            if (controller == null) return false;
            EnsureVisuals();
            SetFacing(flippedX);
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;
            gameObject.SetActive(true);
            animator.Rebind();
            return PlayAction(action);
        }

        public void SetFacing(bool flippedX)
        {
            EnsureVisuals();
            facingRoot.localScale = new Vector3(flippedX ? -1f : 1f, 1f, 1f);
        }

        public bool PlayAction(int action, float speed = 1f, float normalizedTime = 0f)
        {
            if (animator == null || animator.runtimeAnimatorController == null) return false;
            string stateName = "Action_" + action;
            AnimationClip clip = animator.runtimeAnimatorController.animationClips.FirstOrDefault(
                value => value != null && value.name.EndsWith("_" + stateName, System.StringComparison.Ordinal));
            if (clip == null) return false;
            int stateHash = Animator.StringToHash(stateName);
            if (gameObject.activeInHierarchy && !animator.HasState(0, stateHash)) return false;
            currentAction = action;
            playbackSpeed = speed;
            playbackNormalizedTime = normalizedTime;
            animator.speed = speed;
            // Hidden pages have no Animator state machine yet. Initialize their
            // native first frame and defer state playback until they are enabled.
            clip.SampleAnimation(gameObject, Mathf.Repeat(normalizedTime, 1f) * clip.length);
            if (gameObject.activeInHierarchy)
            {
                animator.Play(stateHash, 0, normalizedTime);
                animator.Update(0f);
            }
            return true;
        }

        private void EnsureVisuals()
        {
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            if (animator == null)
                throw new System.InvalidOperationException("World stage player requires a Unity Animator.");

            facingRoot = transform.Find("FacingRoot");
            if (facingRoot == null)
            {
                GameObject facing = new GameObject("FacingRoot", typeof(RectTransform));
                facing.transform.SetParent(transform, false);
                RectTransform facingRect = facing.GetComponent<RectTransform>();
                facingRect.anchorMin = facingRect.anchorMax = new Vector2(.5f, .5f);
                facingRect.pivot = new Vector2(.5f, .5f);
                facingRoot = facing.transform;
            }

            Transform visual = facingRoot.Find("Visual");
            if (visual == null)
            {
                GameObject child = new GameObject("Visual", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                child.transform.SetParent(facingRoot, false);
                RectTransform rect = child.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                visual = child.transform;
            }
            Image image = visual.GetComponent<Image>();
            if (image == null) image = visual.gameObject.AddComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
        }
    }
}
