using System;
using UnityEngine;

namespace ProjectX.UI
{
    public sealed class XunBaoAnimationPlayer : MonoBehaviour
    {
        private static readonly int IdleState = Animator.StringToHash("Idle");
        private Animator animator;
        private string currentClip = string.Empty;
        private string activeClip = string.Empty;

        public event Action<string> AnimationCompleted;

        public string CurrentClip => currentClip;
        public bool IsPlaying => !string.IsNullOrEmpty(activeClip);

        private void Awake()
        {
            animator = GetComponent<Animator>();
            if (animator == null || animator.runtimeAnimatorController == null)
                throw new InvalidOperationException("XunBao native animation player requires an Animator Controller.");
        }

        public bool Play(string clipName)
        {
            if (string.IsNullOrWhiteSpace(clipName) || animator == null || animator.runtimeAnimatorController == null)
                return false;
            int state = Animator.StringToHash(clipName);
            if (!animator.HasState(0, state)) return false;

            currentClip = clipName;
            activeClip = clipName;
            animator.Play(state, 0, 0f);
            return true;
        }

        private void Update()
        {
            if (string.IsNullOrEmpty(activeClip) || animator == null) return;
            AnimatorStateInfo state = animator.GetCurrentAnimatorStateInfo(0);
            if (state.shortNameHash != Animator.StringToHash(activeClip) || state.normalizedTime < 1f) return;

            string completed = activeClip;
            activeClip = string.Empty;
            if (animator.HasState(0, IdleState)) animator.Play(IdleState, 0, 0f);
            AnimationCompleted?.Invoke(completed);
        }
    }
}
