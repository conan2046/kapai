using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Animation
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform))]
    public sealed class ImodAnimationPlayer : MonoBehaviour
    {
        private const int FlipY = 0x1;
        private const int FlipX = 0x2;

        [SerializeField] private TextAsset animationJson;
        [SerializeField] private Texture2D texture;
        [SerializeField] private bool playOnEnable = true;
        [SerializeField] private bool loop = true;
        [SerializeField, Min(0.01f)] private float speed = 1f;
        [SerializeField] private int initialAction;

        private readonly List<Sprite> moduleSprites = new List<Sprite>();
        private ImodAnimationData data;
        private RectTransform partTransform;
        private Image partImage;
        private int actionIndex = -1;
        private int sequenceIndex;
        private float remaining;
        private bool playing;
        private bool flippedX;
        private bool flippedY;
        private Color color = Color.white;

        public event Action<int, int> FrameChanged;
        public event Action<int> Completed;

        public bool IsLoaded => data != null && texture != null;
        public bool IsPlaying => playing;
        public int CurrentAction => actionIndex;
        public int CurrentSequenceIndex => sequenceIndex;
        public int CurrentFrame { get; private set; } = -1;
        public float Speed => speed;

        private void Awake()
        {
            EnsureRenderer();
            if (animationJson != null && texture != null) Load(animationJson, texture);
        }

        private void OnEnable()
        {
            if (playOnEnable && IsLoaded) Play(initialAction, loop);
        }

        private void Update()
        {
            Advance(Time.deltaTime);
        }

        private void OnDestroy()
        {
            ClearSprites();
        }

        public bool LoadResource(string resourceKey)
        {
            if (string.IsNullOrWhiteSpace(resourceKey)) return false;
            TextAsset json = Resources.Load<TextAsset>(resourceKey);
            Texture2D image = Resources.Load<Texture2D>(resourceKey);
            if (json == null || image == null) return false;
            Load(json, image);
            return true;
        }

        public void Load(TextAsset json, Texture2D image)
        {
            if (json == null) throw new ArgumentNullException(nameof(json));
            if (image == null) throw new ArgumentNullException(nameof(image));
            animationJson = json;
            texture = image;
            data = ImodAnimationData.Parse(json.text);
            BuildSprites();
            Stop();
            RenderFrame(data.actions.Length > 0 && data.actions[0].frames.Length > 0
                ? data.actions[0].frames[0].frame : -1);
        }

        public void Play(int requestedAction, bool repeat = false)
        {
            if (!IsLoaded) throw new InvalidOperationException("Imod animation is not loaded.");
            if (requestedAction < 0 || requestedAction >= data.actions.Length)
                throw new ArgumentOutOfRangeException(nameof(requestedAction));
            if (data.actions[requestedAction].frames == null
                || data.actions[requestedAction].frames.Length == 0)
                throw new InvalidOperationException($"Imod action {requestedAction} has no frames.");
            actionIndex = requestedAction;
            sequenceIndex = 0;
            remaining = 0f;
            loop = repeat;
            playing = true;
            ApplySequenceFrame();
        }

        public void PlayAction(int requestedAction) => Play(requestedAction, false);
        public void PlayActionRepeat(int requestedAction) => Play(requestedAction, true);

        public void Stop()
        {
            playing = false;
            remaining = 0f;
        }

        public void SetSpeedScale(float value)
        {
            speed = Mathf.Max(0.01f, value);
        }

        public void SetFlippedX(bool value)
        {
            flippedX = value;
            RenderFrame(CurrentFrame);
        }

        public void SetFlippedY(bool value)
        {
            flippedY = value;
            RenderFrame(CurrentFrame);
        }

        public void SetColor(Color value)
        {
            color = value;
            if (partImage != null) partImage.color = color;
        }

        public void Advance(float deltaSeconds)
        {
            if (!playing || deltaSeconds <= 0f || actionIndex < 0) return;
            remaining -= deltaSeconds * speed;
            int guard = 0;
            while (remaining <= 0f && playing && guard++ < 1024)
            {
                ImodAction action = data.actions[actionIndex];
                sequenceIndex++;
                if (sequenceIndex >= action.frames.Length)
                {
                    if (loop) sequenceIndex = 0;
                    else
                    {
                        playing = false;
                        Completed?.Invoke(actionIndex);
                        return;
                    }
                }
                ApplySequenceFrame();
            }
        }

        private void ApplySequenceFrame()
        {
            ImodActionFrame item = data.actions[actionIndex].frames[sequenceIndex];
            RenderFrame(item.frame);
            int ticks = Mathf.Max(1, item.durationTicks);
            remaining += ticks / (float)Mathf.Max(1, data.frameRate);
            FrameChanged?.Invoke(actionIndex, item.frame);
        }

        private void BuildSprites()
        {
            ClearSprites();
            foreach (ImodModule module in data.modules)
            {
                int y = texture.height - module.y - module.height;
                var rect = new Rect(module.x, y, module.width, module.height);
                if (rect.xMin < 0 || rect.yMin < 0 || rect.xMax > texture.width
                    || rect.yMax > texture.height || rect.width <= 0 || rect.height <= 0)
                    throw new InvalidOperationException(
                        $"Imod module {module.id} is outside texture {texture.name}: {rect}");
                Sprite sprite = Sprite.Create(texture, rect, new Vector2(0.5f, 0.5f), 100f);
                sprite.name = $"{texture.name}_ImodModule_{module.id}";
                moduleSprites.Add(sprite);
            }
        }

        private void ClearSprites()
        {
            foreach (Sprite sprite in moduleSprites)
                if (sprite != null)
                {
                    if (Application.isPlaying) Destroy(sprite);
                    else DestroyImmediate(sprite);
                }
            moduleSprites.Clear();
        }

        private void EnsureRenderer()
        {
            if (partImage != null) return;
            Transform existing = transform.Find("__ImodPart");
            GameObject part = existing != null ? existing.gameObject
                : new GameObject("__ImodPart", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            partTransform = part.GetComponent<RectTransform>();
            partTransform.SetParent(transform, false);
            partImage = part.GetComponent<Image>();
            partImage.raycastTarget = false;
            partImage.preserveAspect = true;
        }

        private void RenderFrame(int frameIndex)
        {
            EnsureRenderer();
            CurrentFrame = frameIndex;
            if (data == null || frameIndex < 0 || frameIndex >= data.frames.Length)
            {
                partImage.enabled = false;
                return;
            }
            ImodPart[] parts = data.frames[frameIndex].parts;
            if (parts == null || parts.Length == 0)
            {
                partImage.enabled = false;
                return;
            }
            ImodPart part = parts[0];
            if (part.module < 0 || part.module >= data.modules.Length)
                throw new InvalidOperationException($"Imod frame {frameIndex} has an invalid module.");
            ImodModule module = data.modules[part.module];
            partImage.enabled = true;
            partImage.sprite = moduleSprites[part.module];
            partImage.color = color;
            partTransform.sizeDelta = new Vector2(module.width, module.height);

            float x = part.x + module.width * 0.5f;
            float y = -part.y - module.height * 0.5f;
            if (flippedX) x = -x;
            if (flippedY) y = -y;
            partTransform.anchoredPosition = new Vector2(x, y);
            bool partFlipX = (part.flags & FlipX) != 0;
            bool partFlipY = (part.flags & FlipY) != 0;
            partTransform.localScale = new Vector3(
                partFlipX ^ flippedX ? -1f : 1f,
                partFlipY ^ flippedY ? -1f : 1f,
                1f);
        }
    }
}
