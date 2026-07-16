using System;
using System.Collections.Generic;
using ProjectX.Diagnostics;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class ConfigService
    {
        private readonly Dictionary<string, object> cache = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);

        public T Load<T>(string resourcePath) where T : class
        {
            if (string.IsNullOrWhiteSpace(resourcePath)) throw new ArgumentException("Config resource path is required.", nameof(resourcePath));
            if (cache.TryGetValue(resourcePath, out object cached)) return (T)cached;
            TextAsset asset = Resources.Load<TextAsset>(resourcePath);
            if (asset == null) throw new InvalidOperationException($"Config resource is missing: Resources/{resourcePath}.json");
            T value = JsonUtility.FromJson<T>(asset.text);
            if (value == null) throw new InvalidOperationException($"Config resource could not be parsed: {resourcePath}");
            cache[resourcePath] = value;
            ClientLog.Info("Config", $"Loaded {resourcePath}", typeof(T).Name);
            return value;
        }

        public void Clear() => cache.Clear();
    }
}
