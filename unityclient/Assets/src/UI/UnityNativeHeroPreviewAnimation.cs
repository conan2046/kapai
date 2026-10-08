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
            if (!controller.animationClips.Any(clip => clip != null
                && (clip.name == $"{clipPrefix}_Action_{actionId}"
                    || (actionId == 0 && clip.name == clipPrefix))))
            {
                if (actionId == 1 && controller.animationClips.Any(clip => clip != null
                    && clip.name == $"btm{picture}_{animationSuffix.TrimStart('_')}_Action_0"))
                    stateName = "Action_0";
                else
                    return false;
            }
            EnsureVisual();
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;
            visual.enabled = true;
            gameObject.SetActive(true);
            animator.Rebind();
            animator.Play(stateName, 0, 0f);
            animator.Update(0f);
            return true;
        }

        public void Hide()
        {
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
