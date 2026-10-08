using System;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Animator))]
    public sealed class UnityNativeBattleModelAnimation : MonoBehaviour
    {
        private Animator animator;
        private RectTransform visualRoot;
        private Image image;
        private Image flatImage;
        private Image spriteImage;
        private RuntimeAnimatorController controller;
        private AnimationClip currentClip;
        private string currentSource = string.Empty;
        private int currentAction = -1;
        private float visualScale = 1f;
        private bool flippedX;
        private Color color = Color.white;
        private bool playOnEnable = true;
        private bool useFlatImage;
        private bool pendingPlayOnEnable;

        public bool IsLoaded => animator != null && controller != null && image != null && image.enabled;
        public bool IsPlaying => IsLoaded && currentClip != null
            && (currentClip.isLooping || animator.GetCurrentAnimatorStateInfo(0).normalizedTime < 1f);
        public int CurrentAction => currentAction;
        public bool IsFlippedX => flippedX;
        public string CurrentAnimationSource => currentSource;
        public int CurrentFrame
        {
            get
            {
                if (currentClip == null || animator == null) return -1;
                float normalized = animator.GetCurrentAnimatorStateInfo(0).normalizedTime;
                if (currentClip.isLooping) normalized = Mathf.Repeat(normalized, 1f);
                return Mathf.Clamp(Mathf.FloorToInt(normalized * currentClip.length * currentClip.frameRate),
                    0, Mathf.Max(0, Mathf.RoundToInt(currentClip.length * currentClip.frameRate) - 1));
            }
        }
        public bool CurrentFrameBelongsToCurrentAction => currentClip != null && currentAction >= 0;

        private void Awake() => EnsureVisual(useFlatImage);

        private void OnEnable()
        {
            if ((playOnEnable || pendingPlayOnEnable) && currentAction >= 0)
                Play(currentAction, currentClip != null && currentClip.isLooping);
        }

        public void SetPlayOnEnable(bool value) => playOnEnable = value;

        public void SetVisualScale(float value)
        {
            visualScale = Mathf.Max(.01f, value);
            ApplyVisualScale();
        }

        public void SetFlippedX(bool value)
        {
            flippedX = value;
            ApplyVisualScale();
        }

        public void SetSpeedScale(float value)
        {
            if (animator != null) animator.speed = 1f / Mathf.Max(.01f, value);
        }

        public void SetColor(Color value)
        {
            color = value;
            if (image != null) image.color = color;
        }

        public bool LoadAnimation(string sourcePath, int requestedAction)
        {
            if (!TryResolveController(sourcePath, out RuntimeAnimatorController resolved,
                    out string resourcePath, out string suffix))
                return false;
            int action = requestedAction;
            string name = resourcePath.Substring(resourcePath.LastIndexOf('/') + 1);
            string clipName = name + "_Action_" + action;
            AnimationClip clip = resolved.animationClips.FirstOrDefault(value => value != null && value.name == clipName);
            if (clip == null && action != 0)
            {
                action = 0;
                clipName = name + "_Action_0";
                clip = resolved.animationClips.FirstOrDefault(value => value != null && value.name == clipName);
            }
            if (clip == null) return false;
            EnsureVisual(suffix.Equals("zd", StringComparison.OrdinalIgnoreCase));
            controller = resolved;
            currentClip = clip;
            currentAction = action;
            currentSource = sourcePath;
            animator.runtimeAnimatorController = controller;
            animator.enabled = true;
            image.enabled = true;
            gameObject.SetActive(true);
            return true;
        }

        public void Play(int action, bool repeat = false)
        {
            if (controller == null || animator == null) throw new InvalidOperationException("Battle model animation is not loaded.");
            string stateName = "Action_" + action;
            AnimationClip clip = controller.animationClips.FirstOrDefault(value => value != null
                && value.name.EndsWith("_" + stateName, StringComparison.Ordinal));
            if (clip == null && action != 0)
            {
                action = 0;
                stateName = "Action_0";
                clip = controller.animationClips.FirstOrDefault(value => value != null
                    && value.name.EndsWith("_" + stateName, StringComparison.Ordinal));
            }
            if (clip == null) throw new InvalidOperationException("Battle model action " + stateName + " is missing.");
            currentAction = action;
            currentClip = clip;
            pendingPlayOnEnable = !gameObject.activeInHierarchy;
            clip.SampleAnimation(gameObject, 0f);
            if (!pendingPlayOnEnable)
            {
                animator.Rebind();
                animator.Play(stateName, 0, 0f);
                animator.Update(0f);
            }
            if (flatImage != null) flatImage.enabled = useFlatImage;
            if (spriteImage != null) spriteImage.enabled = !useFlatImage;
        }

        public bool MatchesAnimation(string sourcePath)
        {
            return string.Equals(currentSource, sourcePath, StringComparison.OrdinalIgnoreCase);
        }

        public static bool TryGetActionDuration(string sourcePath, int requestedAction, out float duration)
        {
            duration = 0f;
            if (!TryResolveController(sourcePath, out RuntimeAnimatorController resolved,
                    out string resourcePath, out _)) return false;
            string prefix = resourcePath.Substring(resourcePath.LastIndexOf('/') + 1) + "_Action_";
            AnimationClip clip = resolved.animationClips.FirstOrDefault(value => value != null
                && value.name == prefix + requestedAction);
            if (clip == null && requestedAction != 0)
                clip = resolved.animationClips.FirstOrDefault(value => value != null && value.name == prefix + "0");
            if (clip == null) return false;
            duration = clip.length;
            return duration > 0f;
        }

        public static bool Preload(string sourcePath)
        {
            return TryResolveController(sourcePath, out _, out _, out _);
        }

        private static bool TryResolveController(string sourcePath, out RuntimeAnimatorController resolved,
            out string resourcePath, out string suffix)
        {
            resolved = null;
            resourcePath = string.Empty;
            suffix = string.Empty;
            if (string.IsNullOrWhiteSpace(sourcePath)
                || !sourcePath.StartsWith("Monster/btm", StringComparison.OrdinalIgnoreCase))
                return false;
            string name = sourcePath.Substring("Monster/".Length);
            int split = name.LastIndexOf('_');
            if (split <= 0 || split == name.Length - 1) return false;
            suffix = name.Substring(split + 1);
            string root = suffix.Equals("zd", StringComparison.OrdinalIgnoreCase)
                ? "Animations/HeroModels/Monster/"
                : "Animations/World/BattleModels/Animations/Monster/";
            resourcePath = root + name;
            resolved = ProjectX.UI.UnityAssetReference.LoadAsset<RuntimeAnimatorController>(resourcePath);
            return resolved != null;
        }

        private void EnsureVisual(bool useFlatImage = false)
        {
            this.useFlatImage = useFlatImage;
            animator = GetComponent<Animator>();
            if (animator == null) animator = gameObject.AddComponent<Animator>();
            Transform root = transform.Find("Visual");
            if (root == null)
            {
                GameObject value = new GameObject("Visual", typeof(RectTransform));
                value.transform.SetParent(transform, false);
                root = value.transform;
            }
            visualRoot = root as RectTransform;
            if (useFlatImage)
            {
                flatImage = root.GetComponent<Image>();
                if (flatImage == null) flatImage = root.gameObject.AddComponent<Image>();
                image = flatImage;
                if (spriteImage != null) spriteImage.enabled = false;
            }
            else
            {
                Transform sprite = root.Find("Sprite");
                if (sprite == null)
                {
                    GameObject value = new GameObject("Sprite", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                    value.transform.SetParent(root, false);
                    sprite = value.transform;
                }
                spriteImage = sprite.GetComponent<Image>();
                if (spriteImage == null) spriteImage = sprite.gameObject.AddComponent<Image>();
                image = spriteImage;
                if (flatImage != null) flatImage.enabled = false;
            }
            image.preserveAspect = true;
            image.raycastTarget = false;
            image.color = color;
            ApplyVisualScale();
        }

        private void ApplyVisualScale()
        {
            // Mirror around the unit origin so authored frame offsets are
            // mirrored and scaled along with the pixels, as in ImodAnim.
            transform.localScale = new Vector3(flippedX ? -visualScale : visualScale, visualScale, 1f);
            if (visualRoot != null)
            {
                visualRoot.localScale = Vector3.one;
                if (!useFlatImage)
                {
                    // Action clips animate Visual/Sprite. Their parent must
                    // not retain the geometry written by flat idle clips.
                    visualRoot.anchoredPosition = Vector2.zero;
                    visualRoot.sizeDelta = Vector2.zero;
                }
            }
        }
    }
}
