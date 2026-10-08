using System;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeBattleEffectPlayer : MonoBehaviour
    {
        private Animator animator;
        private RectTransform visualRoot;
        private Image image;
        private RuntimeAnimatorController controller;
        private AnimationClip clip;
        private string currentSource = string.Empty;
        private float speedScale = 1f;
        private bool flippedX;

        public bool IsLoaded => animator != null && controller != null && image != null;
        public bool IsPlaying => IsLoaded && clip != null
            && (clip.isLooping || animator.GetCurrentAnimatorStateInfo(0).normalizedTime < 1f);
        public string CurrentAnimationSource => currentSource;

        private void Awake() => EnsureVisual();

        public bool LoadAnimation(string sourcePath)
        {
            if (!TryResolveController(sourcePath, out RuntimeAnimatorController resolved,
                    out string resourcePath)) return false;
            string animationName = resourcePath.Substring(resourcePath.LastIndexOf('/') + 1);
            AnimationClip resolvedClip = resolved.animationClips.FirstOrDefault(value => value != null
                && value.name == animationName + "_Action_0");
            if (resolvedClip == null) return false;

            EnsureVisual();
            controller = resolved;
            clip = resolvedClip;
            currentSource = sourcePath;
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;
            ApplyVisualFlip();
            return true;
        }

        public void Play(int action = 0, bool repeat = false)
        {
            if (action != 0 || !IsLoaded)
                throw new InvalidOperationException("Battle effect action 0 is not loaded.");
            animator.Rebind();
            animator.Play("Action_0", 0, 0f);
            animator.Update(0f);
            animator.speed = 1f / Mathf.Max(.01f, speedScale);
            if (repeat != clip.isLooping)
                Debug.LogWarning("Battle effect loop setting differs from its native clip: " + currentSource, this);
        }

        public void SetSpeedScale(float value)
        {
            speedScale = Mathf.Max(.01f, value);
            if (animator != null) animator.speed = 1f / speedScale;
        }

        public void SetFlippedX(bool value)
        {
            flippedX = value;
            ApplyVisualFlip();
        }

        public static bool Preload(string sourcePath)
        {
            return TryResolveController(sourcePath, out _, out _);
        }

        public static bool TryGetActionDuration(string sourcePath, out float duration)
        {
            duration = 0f;
            if (!TryResolveController(sourcePath, out RuntimeAnimatorController resolved,
                    out string resourcePath)) return false;
            string animationName = resourcePath.Substring(resourcePath.LastIndexOf('/') + 1);
            AnimationClip resolvedClip = resolved.animationClips.FirstOrDefault(value => value != null
                && value.name == animationName + "_Action_0");
            if (resolvedClip == null || resolvedClip.length <= 0f) return false;
            duration = resolvedClip.length;
            return true;
        }

        private static bool TryResolveController(string sourcePath,
            out RuntimeAnimatorController resolved, out string resourcePath)
        {
            resolved = null;
            resourcePath = string.Empty;
            if (string.IsNullOrWhiteSpace(sourcePath)) return false;
            if (!sourcePath.StartsWith("Animations/World/BattleEffects/Skills/", StringComparison.OrdinalIgnoreCase)
                && !sourcePath.StartsWith("Animations/World/BattleEffects/Buffs/", StringComparison.OrdinalIgnoreCase))
                return false;
            resourcePath = sourcePath;
            resolved = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(resourcePath);
            return resolved != null;
        }

        private void EnsureVisual()
        {
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            Transform visual = transform.Find("Visual");
            if (visual == null)
            {
                GameObject visualObject = new GameObject("Visual", typeof(RectTransform));
                visualObject.transform.SetParent(transform, false);
                visual = visualObject.transform;
            }
            visualRoot = (RectTransform)visual;
            Transform part = visual.Find("FrameVisual");
            if (part == null)
            {
                GameObject partObject = new GameObject("FrameVisual", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                partObject.transform.SetParent(visual, false);
                part = partObject.transform;
            }
            RectTransform partRect = (RectTransform)part;
            partRect.anchorMin = partRect.anchorMax = new Vector2(.5f, .5f);
            partRect.pivot = new Vector2(.5f, .5f);
            image = part.GetComponent<Image>();
            image.preserveAspect = true;
            image.raycastTarget = false;
            ApplyVisualFlip();
        }

        private void ApplyVisualFlip()
        {
            if (visualRoot != null)
                visualRoot.localScale = new Vector3(flippedX ? -1f : 1f, 1f, 1f);
        }
    }
}
