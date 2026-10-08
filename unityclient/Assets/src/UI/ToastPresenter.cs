using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public static class CocosRichText
    {
        // Formal Cocos palette: client/ProjectX/src/core/AppUIDef.lua and
        // server/src/utility.h (GGCT_*). Shadow variants retain their base hue.
        private static readonly IReadOnlyDictionary<int, string> Colors = new Dictionary<int, string>
        {
            [0] = "FFFFFF", [1] = "FF5A27", [2] = "017FFF", [3] = "2FB500",
            [4] = "FFDA0E", [5] = "FF7C99", [6] = "9AFFFF", [7] = "CC31FF",
            [8] = "FF5A00", [9] = "B22222", [10] = "703B33", [11] = "B0B0B0",
            [12] = "2FB500", [13] = "017FFF", [14] = "CC31FF", [15] = "FF5A00",
            [16] = "FFFFFF", [32] = "28EA1C", [36] = "FFFFFF"
        };

        public static string ToUnity(string source)
        {
            if (string.IsNullOrEmpty(source)) return source ?? string.Empty;
            StringBuilder output = new StringBuilder(source.Length + 32);
            int openColors = 0;
            for (int index = 0; index < source.Length;)
            {
                if (source[index] != '[')
                {
                    output.Append(source[index++]);
                    continue;
                }

                int end = source.IndexOf(']', index + 1);
                if (end < 0)
                {
                    output.Append(source[index++]);
                    continue;
                }

                string token = source.Substring(index + 1, end - index - 1);
                if (TryReadOpenColor(token, out int color))
                {
                    output.Append("<color=#").Append(ColorHex(color)).Append('>');
                    openColors++;
                    index = end + 1;
                    continue;
                }
                if (IsCloseColor(token))
                {
                    if (openColors > 0)
                    {
                        output.Append("</color>");
                        openColors--;
                    }
                    index = end + 1;
                    continue;
                }
                if (string.Equals(token, "c/n", StringComparison.OrdinalIgnoreCase))
                {
                    output.Append('\n');
                    index = end + 1;
                    continue;
                }

                output.Append(source, index, end - index + 1);
                index = end + 1;
            }
            while (openColors-- > 0) output.Append("</color>");
            return output.ToString();
        }

        private static bool TryReadOpenColor(string token, out int color)
        {
            color = 0;
            return token.Length > 1
                && (token[0] == 'c' || token[0] == 'C')
                && int.TryParse(token.Substring(1), out color);
        }

        private static bool IsCloseColor(string token)
        {
            if (string.Equals(token, "c/", StringComparison.OrdinalIgnoreCase)) return true;
            if (!token.StartsWith("/c", StringComparison.OrdinalIgnoreCase)) return false;
            if (token.Length == 2) return true;
            return int.TryParse(token.Substring(2), out _);
        }

        private static string ColorHex(int color) => Colors.TryGetValue(color, out string hex) ? hex : "FFFFFF";
    }

    public sealed class ToastPresenter : IDisposable
    {
        private readonly Queue<string> pending = new Queue<string>();
        private readonly GameObject root;
        private readonly CanvasGroup group;
        private readonly Text label;
        private float remaining;
        private float duration;

        public ToastPresenter(Transform parent)
        {
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            root = new GameObject("RuntimeToast", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(CanvasGroup));
            root.transform.SetParent(parent, false);
            RectTransform rect = root.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.25f, 0.68f);
            rect.anchorMax = new Vector2(0.75f, 0.78f);
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Image background = root.GetComponent<Image>();
            background.color = new Color(0f, 0f, 0f, 0.78f);
            background.raycastTarget = false;
            group = root.GetComponent<CanvasGroup>();

            GameObject textNode = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            textNode.transform.SetParent(root.transform, false);
            RectTransform textRect = textNode.GetComponent<RectTransform>();
            textRect.anchorMin = Vector2.zero;
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = new Vector2(20f, 6f);
            textRect.offsetMax = new Vector2(-20f, -6f);
            label = textNode.GetComponent<Text>();
            label.font = UnityEngine.Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.fontSize = 24;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = Color.white;
            label.supportRichText = true;
            label.raycastTarget = false;
            root.SetActive(false);
        }

        public bool IsVisible => root != null && root.activeSelf;
        public int PendingCount => pending.Count;
        public Transform Parent => root != null ? root.transform.parent : null;
        public bool IsLastSibling => root != null && root.transform.GetSiblingIndex() == root.transform.parent.childCount - 1;
        public string CurrentText => label != null ? label.text : string.Empty;

        public void SetParent(Transform parent)
        {
            if (parent == null) throw new ArgumentNullException(nameof(parent));
            if (root.transform.parent != parent) root.transform.SetParent(parent, false);
            root.transform.SetAsLastSibling();
        }

        public void Show(string text, float visibleSeconds = 2f)
        {
            if (string.IsNullOrWhiteSpace(text)) return;
            pending.Enqueue(text);
            if (!IsVisible) BeginNext(Mathf.Max(0.25f, visibleSeconds));
        }

        public void Tick()
        {
            if (!IsVisible) return;
            // Equipment cultivation refreshes its base/subpage siblings after
            // successful writes. Keep the toast below them in the Hierarchy
            // (last sibling) for the whole visible lifetime, not only at show time.
            root.transform.SetAsLastSibling();
            remaining -= Time.unscaledDeltaTime;
            if (remaining <= 0f) { BeginNext(duration); return; }
            float fadeWindow = Mathf.Min(0.25f, duration * 0.25f);
            group.alpha = fadeWindow <= 0f ? 1f : Mathf.Clamp01(remaining / fadeWindow);
        }

        public void Clear()
        {
            pending.Clear();
            remaining = 0f;
            if (root != null) root.SetActive(false);
        }

        public void Dispose()
        {
            Clear();
            if (root != null) UnityEngine.Object.Destroy(root);
        }

        private void BeginNext(float visibleSeconds)
        {
            if (pending.Count == 0)
            {
                root.SetActive(false);
                return;
            }
            duration = Mathf.Max(0.25f, visibleSeconds);
            remaining = duration;
            label.text = CocosRichText.ToUnity(pending.Dequeue());
            group.alpha = 1f;
            root.SetActive(true);
            root.transform.SetAsLastSibling();
        }
    }
}
