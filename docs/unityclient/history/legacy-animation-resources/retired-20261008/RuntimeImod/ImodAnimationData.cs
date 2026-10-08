using System;
using Newtonsoft.Json;

namespace ProjectX.Animation
{
    [Serializable]
    public sealed class ImodAnimationData
    {
        public int schemaVersion;
        public string format;
        public string source;
        public int frameRate = 30;
        public ImodModule[] modules = Array.Empty<ImodModule>();
        public ImodFrame[] frames = Array.Empty<ImodFrame>();
        public ImodAction[] actions = Array.Empty<ImodAction>();

        public static ImodAnimationData Parse(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
                throw new ArgumentException("Imod animation JSON is empty.", nameof(json));
            ImodAnimationData value = JsonConvert.DeserializeObject<ImodAnimationData>(json);
            if (value == null || value.schemaVersion != 1)
                throw new InvalidOperationException("Unsupported Imod animation schema.");
            if (value.frameRate <= 0 || value.modules == null || value.frames == null || value.actions == null)
                throw new InvalidOperationException("Imod animation data is incomplete.");
            return value;
        }
    }

    [Serializable]
    public sealed class ImodModule
    {
        public int id;
        public int x;
        public int y;
        public int width;
        public int height;
    }

    [Serializable]
    public sealed class ImodFrame
    {
        public int id;
        public ImodPart[] parts = Array.Empty<ImodPart>();
    }

    [Serializable]
    public sealed class ImodPart
    {
        public int x;
        public int y;
        public int module;
        public int flags;
    }

    [Serializable]
    public sealed class ImodAction
    {
        public int id;
        public ImodActionFrame[] frames = Array.Empty<ImodActionFrame>();
    }

    [Serializable]
    public sealed class ImodActionFrame
    {
        public int frame;
        public int durationTicks;
        public int sourceDurationTicks;
    }
}
