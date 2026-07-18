using System;
using UnityEngine;

namespace ProjectX.UI.Migration
{
    [Serializable]
    public sealed class CocosTimelineDefinition
    {
        public int duration;
        public float speed = 1f;
        public int frameRate = 60;
        public string currentAnimationName;
        public CocosTimelineClip[] clips = Array.Empty<CocosTimelineClip>();
        public CocosTimelineTrack[] timelines = Array.Empty<CocosTimelineTrack>();
    }

    [Serializable]
    public sealed class CocosTimelineClip
    {
        public string name;
        public int startFrame;
        public int endFrame;
    }

    [Serializable]
    public sealed class CocosTimelineTrack
    {
        public int actionTag;
        public string property;
        public CocosTimelineFrame[] frames = Array.Empty<CocosTimelineFrame>();
    }

    [Serializable]
    public sealed class CocosTimelineFrame
    {
        public int frame;
        public float x;
        public float y;
        public float value;
        public bool visible = true;
        public bool tween = true;
        public int easingType;
        public string eventName;
    }

    [DisallowMultipleComponent]
    public sealed class CocosTimelinePlayer : MonoBehaviour
    {
        [SerializeField] private CocosTimelineDefinition definition;
        [SerializeField] private bool playOnEnable;
        [SerializeField] private bool loop;

        private CocosUiBinding binding;
        private float currentFrame;
        private float timeSpeed = 1f;
        private int startFrame;
        private int endFrame;
        private bool playing;
        private string currentClip = string.Empty;

        public event Action<string> FrameEvent;
        public event Action<string> AnimationCompleted;

        public bool IsPlaying => playing;
        public float CurrentFrame => currentFrame;
        public int Duration => definition != null ? definition.duration : 0;
        public string CurrentClip => currentClip;
        public CocosTimelineDefinition Definition => definition;

        public void Initialize(CocosTimelineDefinition value)
        {
            definition = value;
            binding = GetComponent<CocosUiBinding>();
        }

        private void Awake() => binding = GetComponent<CocosUiBinding>();

        private void OnEnable()
        {
            if (!playOnEnable || definition == null || definition.duration <= 0) return;
            if (!string.IsNullOrEmpty(definition.currentAnimationName)
                && TryPlay(definition.currentAnimationName, loop)) return;
            Play(0, definition.duration, loop);
        }

        private void Update() => Advance(Time.deltaTime);

        public void Play(int fromFrame, int toFrame, bool repeat = false)
        {
            if (definition == null) throw new InvalidOperationException("Timeline is not initialized.");
            currentClip = string.Empty;
            BeginPlayback(fromFrame, toFrame, repeat);
        }

        public void GotoFrameAndPlay(int fromFrame, int toFrame, bool repeat = false) =>
            Play(fromFrame, toFrame, repeat);

        public void GotoFrameAndPlay(int fromFrame, bool repeat = false) =>
            Play(fromFrame, Duration, repeat);

        public void Play(string clipName, bool repeat = false)
        {
            if (!TryPlay(clipName, repeat))
                throw new ArgumentException($"Timeline clip does not exist: {clipName}", nameof(clipName));
        }

        public bool TryPlay(string clipName, bool repeat = false)
        {
            if (definition == null) throw new InvalidOperationException("Timeline is not initialized.");
            CocosTimelineClip clip = Array.Find(
                definition.clips ?? Array.Empty<CocosTimelineClip>(),
                item => string.Equals(item.name, clipName, StringComparison.Ordinal));
            if (clip == null) return false;
            currentClip = clip.name ?? string.Empty;
            BeginPlayback(clip.startFrame, clip.endFrame, repeat);
            return true;
        }

        private void BeginPlayback(int fromFrame, int toFrame, bool repeat)
        {
            startFrame = Mathf.Clamp(fromFrame, 0, definition.duration);
            endFrame = Mathf.Clamp(toFrame, startFrame, definition.duration);
            loop = repeat;
            currentFrame = startFrame;
            playing = endFrame > startFrame;
            Apply(currentFrame);
            DispatchFrameEvents(startFrame - 0.001f, startFrame);
            if (!playing) AnimationCompleted?.Invoke(currentClip);
        }

        public void Pause() => playing = false;
        public void Stop() => playing = false;
        public void SetTimeSpeed(float value) => timeSpeed = Mathf.Max(0f, value);

        public void Advance(float deltaSeconds)
        {
            if (!playing || deltaSeconds <= 0f) return;
            float previousFrame = currentFrame;
            currentFrame += deltaSeconds * Mathf.Max(1, definition.frameRate)
                            * Mathf.Max(0.01f, definition.speed) * timeSpeed;
            if (currentFrame >= endFrame)
            {
                DispatchFrameEvents(previousFrame, endFrame);
                Apply(endFrame);
                if (loop)
                {
                    float length = Mathf.Max(1f, endFrame - startFrame);
                    currentFrame = startFrame + (currentFrame - startFrame) % length;
                    DispatchFrameEvents(startFrame - 0.001f, currentFrame);
                    Apply(currentFrame);
                }
                else
                {
                    currentFrame = endFrame;
                    playing = false;
                    AnimationCompleted?.Invoke(currentClip);
                }
                return;
            }
            DispatchFrameEvents(previousFrame, currentFrame);
            Apply(currentFrame);
        }

        public void Apply(float frame)
        {
            if (definition?.timelines == null) return;
            binding = binding != null ? binding : GetComponent<CocosUiBinding>();
            foreach (CocosTimelineTrack track in definition.timelines)
            {
                if (string.Equals(track.property, "FrameEvent", StringComparison.Ordinal)) continue;
                GameObject target = binding != null ? binding.FindActionTag(track.actionTag) : null;
                if (target == null || track.frames == null || track.frames.Length == 0) continue;
                Evaluate(track, target, frame);
            }
        }

        private void DispatchFrameEvents(float previousFrame, float nextFrame)
        {
            if (definition?.timelines == null || FrameEvent == null) return;
            foreach (CocosTimelineTrack track in definition.timelines)
            {
                if (!string.Equals(track.property, "FrameEvent", StringComparison.Ordinal)
                    || track.frames == null) continue;
                foreach (CocosTimelineFrame frame in track.frames)
                    if (frame.frame > previousFrame && frame.frame <= nextFrame
                        && !string.IsNullOrEmpty(frame.eventName))
                        FrameEvent.Invoke(frame.eventName);
            }
        }

        private static void Evaluate(CocosTimelineTrack track, GameObject target, float frame)
        {
            CocosTimelineFrame first = track.frames[0];
            CocosTimelineFrame last = track.frames[track.frames.Length - 1];
            CocosTimelineFrame left = first;
            CocosTimelineFrame right = last;
            for (int index = 1; index < track.frames.Length; index++)
            {
                if (track.frames[index].frame < frame) left = track.frames[index];
                else { right = track.frames[index]; break; }
            }
            if (frame <= first.frame) left = right = first;
            else if (frame >= last.frame) left = right = last;
            float t = left.frame == right.frame ? 0f : Mathf.InverseLerp(left.frame, right.frame, frame);
            if (!left.tween) t = 0f;
            else t = Ease(t, left.easingType);

            string property = track.property ?? string.Empty;
            RectTransform rect = target.transform as RectTransform;
            switch (property)
            {
                case "Position" when rect != null:
                    rect.anchoredPosition = Vector2.LerpUnclamped(
                        new Vector2(left.x, left.y), new Vector2(right.x, right.y), t);
                    break;
                case "Scale" when rect != null:
                    rect.localScale = Vector3.LerpUnclamped(
                        new Vector3(left.x, left.y, 1f), new Vector3(right.x, right.y, 1f), t);
                    break;
                case "Rotation" when rect != null:
                case "RotationSkew" when rect != null:
                    rect.localEulerAngles = new Vector3(0f, 0f, Mathf.LerpAngle(left.x, right.x, t));
                    break;
                case "AnchorPoint" when rect != null:
                    rect.pivot = Vector2.LerpUnclamped(
                        new Vector2(left.x, left.y), new Vector2(right.x, right.y), t);
                    break;
                case "Alpha":
                    CanvasGroup group = target.GetComponent<CanvasGroup>();
                    if (group == null) group = target.AddComponent<CanvasGroup>();
                    group.alpha = Mathf.LerpUnclamped(left.value, right.value, t) / 255f;
                    break;
                case "VisibleForFrame":
                case "Visible":
                    target.SetActive(t < 1f ? left.visible : right.visible);
                    break;
            }
        }

        private static float Ease(float t, int type)
        {
            t = Mathf.Clamp01(t);
            switch (type)
            {
                case 1: return 1f - Mathf.Cos(t * Mathf.PI * 0.5f);
                case 2: return Mathf.Sin(t * Mathf.PI * 0.5f);
                case 3: return -(Mathf.Cos(Mathf.PI * t) - 1f) * 0.5f;
                case 4: return t * t;
                case 5: return 1f - (1f - t) * (1f - t);
                case 6: return t < 0.5f ? 2f * t * t : 1f - Mathf.Pow(-2f * t + 2f, 2f) * 0.5f;
                case 7: return t * t * t;
                case 8: return 1f - Mathf.Pow(1f - t, 3f);
                case 9: return t < 0.5f ? 4f * t * t * t : 1f - Mathf.Pow(-2f * t + 2f, 3f) * 0.5f;
                case 10: return t * t * t * t;
                case 11: return 1f - Mathf.Pow(1f - t, 4f);
                case 12: return t < 0.5f ? 8f * Mathf.Pow(t, 4f) : 1f - Mathf.Pow(-2f * t + 2f, 4f) * 0.5f;
                case 13: return Mathf.Pow(t, 5f);
                case 14: return 1f - Mathf.Pow(1f - t, 5f);
                case 15: return t < 0.5f ? 16f * Mathf.Pow(t, 5f) : 1f - Mathf.Pow(-2f * t + 2f, 5f) * 0.5f;
                case 16: return t == 0f ? 0f : Mathf.Pow(2f, 10f * t - 10f);
                case 17: return t == 1f ? 1f : 1f - Mathf.Pow(2f, -10f * t);
                case 19: return 1f - Mathf.Sqrt(1f - t * t);
                case 20: return Mathf.Sqrt(1f - Mathf.Pow(t - 1f, 2f));
                case 21: return t < 0.5f
                    ? (1f - Mathf.Sqrt(1f - Mathf.Pow(2f * t, 2f))) * 0.5f
                    : (Mathf.Sqrt(1f - Mathf.Pow(-2f * t + 2f, 2f)) + 1f) * 0.5f;
                case 22: return t == 0f ? 0f : t == 1f ? 1f
                    : -Mathf.Pow(2f, 10f * t - 10f) * Mathf.Sin((t * 10f - 10.75f) * (2f * Mathf.PI / 3f));
                case 25: return 2.70158f * t * t * t - 1.70158f * t * t;
                case 26:
                    float u = t - 1f; return 1f + 2.70158f * u * u * u + 1.70158f * u * u;
                case 27:
                    const float c = 2.5949095f;
                    return t < 0.5f
                        ? Mathf.Pow(2f * t, 2f) * ((c + 1f) * 2f * t - c) * 0.5f
                        : (Mathf.Pow(2f * t - 2f, 2f) * ((c + 1f) * (t * 2f - 2f) + c) + 2f) * 0.5f;
                default: return t;
            }
        }
    }
}
