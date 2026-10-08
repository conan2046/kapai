using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeFishAnimation : MonoBehaviour
    {
        private Animator animator;

        public bool LoadFishingShape()
        {
            RuntimeAnimatorController controller = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(
                "Animations/Fish/btm2000_zd");
            if (controller == null) return false;
            AnimationClip clip = controller.animationClips.FirstOrDefault(
                value => value != null && value.name == "btm2000_zd_Action_2");
            if (clip == null) return false;
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;

            Transform visual = transform.Find("Visual");
            if (visual == null)
            {
                GameObject child = new GameObject("Visual", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                child.transform.SetParent(transform, false);
                RectTransform rect = child.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                visual = child.transform;
            }
            Image image = visual.GetComponent<Image>();
            if (image == null) image = visual.gameObject.AddComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
            visual.localScale = new Vector3(-.72f, .72f, 1f);
            gameObject.SetActive(true);
            animator.Rebind();
            animator.Play("Action_2", 0, 0f);
            // The presenter creates this model before its parent page is shown.
            // Sample the native clip so hidden pages also have their first frame.
            clip.SampleAnimation(gameObject, 0f);
            if (gameObject.activeInHierarchy) animator.Update(0f);
            return image.sprite != null;
        }
    }
}
