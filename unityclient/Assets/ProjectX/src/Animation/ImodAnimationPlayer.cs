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
        private readonly List<ImodAnimationPlayer> additionalLayers = new List<ImodAnimationPlayer>();
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
        public bool IsFlippedX => flippedX;
        public bool IsFlippedY => flippedY;
        public string CurrentAnimationSource => data?.source ?? string.Empty;
        public bool CurrentFrameBelongsToCurrentAction
        {
            get
            {
                if (!IsLoaded || actionIndex < 0 || actionIndex >= data.actions.Length) return false;
                ImodAction action = data.actions[actionIndex];
                return action.frames != null && Array.Exists(action.frames, item => item.frame == CurrentFrame);
            }
        }

        public float GetActionDurationSeconds(int requestedAction = 0)
        {
            if (!IsLoaded || requestedAction < 0 || requestedAction >= data.actions.Length) return 0f;
            ImodAction action = data.actions[requestedAction];
            if (action.frames == null || action.frames.Length == 0) return 0f;
            int ticks = 0;
            foreach (ImodActionFrame frame in action.frames) ticks += Mathf.Max(1, frame.durationTicks);
            return ticks / (float)Mathf.Max(1, data.frameRate) * speed;
        }

        private void Awake()
        {
            EnsureRenderer();
            if (animationJson != null && texture != null) Load(animationJson, texture);
        }

        private void OnEnable()
        {
            if (!IsLoaded) return;
            EnsureSpriteCache();
            if (playOnEnable) Play(initialAction, loop);
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

        public bool LoadLegacy(string legacyPath)
        {
            if (!ImodAnimationResources.TryLoad(legacyPath, out ImodAnimationAssets assets))
                return false;
            Load(assets.Animation, assets.Texture);
            return true;
        }

        public bool LoadLegacy(string texturePath, string animationPath)
        {
            if (!ImodAnimationResources.TryLoad(texturePath, animationPath, out ImodAnimationAssets assets))
                return false;
            Load(assets.Animation, assets.Texture);
            return true;
        }

        public bool AddLegacyLayer(
            string texturePath,
            string animationPath,
            int zOrder = 1,
            Color? layerColor = null)
        {
            if (!ImodAnimationResources.TryLoad(texturePath, animationPath, out ImodAnimationAssets assets))
                return false;
            var layerObject = new GameObject(
                $"__ImodLayer_{additionalLayers.Count + 1}", typeof(RectTransform));
            RectTransform rect = layerObject.GetComponent<RectTransform>();
            rect.SetParent(transform, false);
            rect.SetSiblingIndex(Mathf.Clamp(zOrder, 0, transform.childCount - 1));
            ImodAnimationPlayer player = layerObject.AddComponent<ImodAnimationPlayer>();
            player.playOnEnable = false;
            player.Load(assets.Animation, assets.Texture);
            player.SetColor(layerColor ?? Color.white);
            player.SetSpeedScale(speed);
            player.SetFlippedX(flippedX);
            player.SetFlippedY(flippedY);
            additionalLayers.Add(player);
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
            actionIndex = -1;
            sequenceIndex = 0;
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
            foreach (ImodAnimationPlayer layer in additionalLayers)
                if (requestedAction < layer.data.actions.Length)
                    layer.Play(requestedAction, repeat);
        }

        public void Stop()
        {
            playing = false;
            remaining = 0f;
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.Stop();
        }

        public void SetSpeedScale(float value)
        {
            speed = Mathf.Max(0.01f, value);
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetSpeedScale(speed);
        }

        public void SetPlayOnEnable(bool value)
        {
            playOnEnable = value;
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetPlayOnEnable(value);
        }

        public void SetFlippedX(bool value)
        {
            flippedX = value;
            RenderFrame(CurrentFrame);
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetFlippedX(value);
        }

        public void SetFlippedY(bool value)
        {
            flippedY = value;
            RenderFrame(CurrentFrame);
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetFlippedY(value);
        }

        public void SetColor(Color value)
        {
            color = value;
            if (partImage != null) partImage.color = color;
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetColor(value);
        }

        public void SetVisualScale(float value)
        {
            EnsureRenderer();
            float scale = Mathf.Max(.01f, value);
            if (partTransform != null) partTransform.localScale = Vector3.one * scale;
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.SetVisualScale(scale);
        }

        public void SetOpacity(int opacity)
        {
            Color value = color;
            value.a = Mathf.Clamp01(opacity / 255f);
            SetColor(value);
        }

        public void PlayNewAction(int requestedAction, bool repeat = false) => Play(requestedAction, repeat);
        public void PlayAction(int requestedAction, float ignoredDuration = 0.1f) => Play(requestedAction, false);
        public void PlayActionRepeat(
            int requestedAction,
            float ignoredDuration = 0.1f,
            bool runTimerNow = false) => Play(requestedAction, true);

        public void SetCurrentAction(int requestedAction)
        {
            Play(requestedAction, false);
            Stop();
        }

        public void PlayFirstFrameIndex(int requestedAction) => SetCurrentAction(requestedAction);

        public void StopCurrentAnimation()
        {
            Stop();
            int firstFrame = actionIndex >= 0 && actionIndex < data.actions.Length
                && data.actions[actionIndex].frames != null && data.actions[actionIndex].frames.Length > 0
                ? data.actions[actionIndex].frames[0].frame
                : 0;
            RenderFrame(firstFrame);
            foreach (ImodAnimationPlayer layer in additionalLayers) layer.StopCurrentAnimation();
        }

        public void Advance(float deltaSeconds)
        {
            if (!playing || deltaSeconds <= 0f || actionIndex < 0) return;
            // Legacy ImodAnim multiplies its scheduled frame interval by _playScale.
            // Values below 1 therefore play faster, values above 1 play slower.
            remaining -= deltaSeconds / speed;
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

        private void EnsureSpriteCache()
        {
            if (data == null || texture == null) return;
            bool complete = moduleSprites.Count == data.modules.Length;
            if (complete)
                for (int index = 0; index < moduleSprites.Count; index++)
                    if (moduleSprites[index] == null)
                    {
                        complete = false;
                        break;
                    }
            if (!complete) BuildSprites();
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
            EnsureSpriteCache();
            if (part.module >= moduleSprites.Count || moduleSprites[part.module] == null)
                throw new InvalidOperationException(
                    $"Imod frame {frameIndex} module {part.module} has no rendered sprite.");
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
            if ((part.flags & FlipX) != 0) x -= module.width;
            if ((part.flags & FlipY) != 0) y -= module.height;
            partTransform.anchoredPosition = new Vector2(x, y);
            partTransform.localScale = new Vector3(
                flippedX ? -1f : 1f,
                flippedY ? -1f : 1f,
                1f);
        }
    }
}
