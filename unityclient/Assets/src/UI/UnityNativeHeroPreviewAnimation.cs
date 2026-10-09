using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeHeroPreviewAnimation : MonoBehaviour
    {
        private Animator animator;
        private Image visual;
        private string currentStateName;
        private bool pendingPlay;

        private void OnEnable()
        {
            pendingPlay = !string.IsNullOrEmpty(currentStateName);
            PlayPendingAction();
        }

        private void PlayPendingAction()
        {
            if (!pendingPlay || animator == null || !animator.isActiveAndEnabled
                || animator.runtimeAnimatorController == null) return;
            pendingPlay = false;
            animator.Rebind();
            animator.Play(currentStateName, 0, 0f);
            animator.Update(0f);
        }

        public bool IsLoaded => animator != null && animator.enabled
            && animator.runtimeAnimatorController != null && visual != null && visual.enabled
            && gameObject.activeSelf;

        public bool LoadStand(int picture)
        {
            return LoadAction(picture, "_zd_show", 0);
        }

        public bool LoadFormationStand(int picture)
        {
            return LoadFormationAction(picture, 1);
        }

        public bool LoadFormationAction(int picture, int actionId)
        {
            return actionId >= 0 && LoadAction(picture, "_zd", actionId);
        }

        private bool LoadAction(int picture, string animationSuffix, int actionId)
        {
            RuntimeAnimatorController controller = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(
                $"Animations/HeroModels/Monster/btm{picture}{animationSuffix}");
            if (controller == null) return false;
            string stateName = $"Action_{actionId}";
            string clipPrefix = $"btm{picture}{animationSuffix}";
            AnimationClip actionClip = controller.animationClips.FirstOrDefault(clip => clip != null
                && (clip.name == $"{clipPrefix}_Action_{actionId}"
                    || (actionId == 0 && clip.name == clipPrefix)));
            if (actionClip == null)
            {
                if (actionId != 1) return false;
                actionClip = controller.animationClips.FirstOrDefault(clip => clip != null
                    && clip.name == $"btm{picture}_{animationSuffix.TrimStart('_')}_Action_0");
                if (actionClip == null) return false;
                stateName = "Action_0";
            }
            EnsureVisual();
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;
            visual.enabled = true;
            currentStateName = stateName;
            pendingPlay = true;
            // Hidden pages still need their first Sprite, but have no active state machine.
            actionClip.SampleAnimation(gameObject, 0f);
            gameObject.SetActive(true);
            PlayPendingAction();
            return true;
        }

        public void Hide()
        {
            currentStateName = null;
            pendingPlay = false;
            if (animator != null) animator.enabled = false;
            if (visual != null) visual.enabled = false;
            gameObject.SetActive(false);
        }

        private void EnsureVisual()
        {
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            if (animator == null)
                throw new System.InvalidOperationException("Hero preview animation requires a Unity Animator component.");
            Transform existing = transform.Find("Visual");
            if (existing == null)
            {
                GameObject child = new GameObject("Visual", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                child.transform.SetParent(transform, false);
                RectTransform rect = child.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                existing = child.transform;
            }
            visual = existing.GetComponent<Image>();
            if (visual == null) visual = existing.gameObject.AddComponent<Image>();
            visual.preserveAspect = true;
            visual.raycastTarget = false;
        }
    }
}
