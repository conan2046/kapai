using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ChatPresenter : IDisposable
    {
        private readonly ChatStore store;
        private readonly Action<byte, string, uint> send;
        private readonly GameObject runtimeRoot;
        private readonly RectTransform content;
        private readonly InputField input;
        private readonly Text errorText;
        private readonly Font font;
        private ChatChannel selectedChannel = ChatChannel.World;

        public ChatPresenter(CocosUiView view, ChatStore store, Action<byte, string, uint> send)
        {
            if (view?.GameObject == null) throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.send = send ?? throw new ArgumentNullException(nameof(send));
            font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            runtimeRoot = CreateRect("ChatRuntime", view.GameObject.transform, Vector2.zero, Vector2.one).gameObject;
            runtimeRoot.AddComponent<Image>().color = new Color(0.055f, 0.075f, 0.11f, 0.98f);

            Text title = CreateText("Title", runtimeRoot.transform, "聊天", 30, TextAnchor.MiddleCenter);
            SetRect(title.rectTransform, new Vector2(0f, 0.90f), new Vector2(1f, 1f), new Vector2(0f, 0f), new Vector2(0f, -6f));

            RectTransform channels = CreateRect("Channels", runtimeRoot.transform, new Vector2(0.04f, 0.82f), new Vector2(0.96f, 0.90f));
            string[] names = { "世界", "队伍", "帮派", "私聊" };
            ChatChannel[] values = { ChatChannel.World, ChatChannel.Team, ChatChannel.Guild, ChatChannel.Private };
            for (int index = 0; index < names.Length; index++)
            {
                int captured = index;
                Button button = CreateButton(names[index], channels, names[index], () => SelectChannel(values[captured]));
                RectTransform rect = button.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(index / 4f + 0.01f, 0.08f);
                rect.anchorMax = new Vector2((index + 1) / 4f - 0.01f, 0.92f);
                rect.offsetMin = rect.offsetMax = Vector2.zero;
            }

            RectTransform viewport = CreateRect("Viewport", runtimeRoot.transform, new Vector2(0.05f, 0.22f), new Vector2(0.95f, 0.81f));
            viewport.gameObject.AddComponent<Image>().color = new Color(0.025f, 0.035f, 0.055f, 0.9f);
            viewport.gameObject.AddComponent<RectMask2D>();
            ScrollRect scroll = viewport.gameObject.AddComponent<ScrollRect>();
            content = CreateRect("Content", viewport, new Vector2(0f, 1f), new Vector2(1f, 1f));
            content.pivot = new Vector2(0.5f, 1f);
            content.anchoredPosition = Vector2.zero;
            VerticalLayoutGroup layout = content.gameObject.AddComponent<VerticalLayoutGroup>();
            layout.padding = new RectOffset(16, 16, 10, 10);
            layout.spacing = 8f;
            layout.childControlHeight = true;
            layout.childForceExpandHeight = false;
            ContentSizeFitter fitter = content.gameObject.AddComponent<ContentSizeFitter>();
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;

            errorText = CreateText("Error", runtimeRoot.transform, string.Empty, 18, TextAnchor.MiddleLeft);
            errorText.color = new Color(1f, 0.55f, 0.45f);
            SetRect(errorText.rectTransform, new Vector2(0.06f, 0.15f), new Vector2(0.94f, 0.21f), Vector2.zero, Vector2.zero);

            RectTransform inputPanel = CreateRect("InputPanel", runtimeRoot.transform, new Vector2(0.05f, 0.04f), new Vector2(0.95f, 0.15f));
            RectTransform inputRect = CreateRect("Input", inputPanel, new Vector2(0f, 0f), new Vector2(0.82f, 1f));
            inputRect.gameObject.AddComponent<Image>().color = new Color(0.12f, 0.15f, 0.20f, 1f);
            Text inputText = CreateText("Text", inputRect, string.Empty, 20, TextAnchor.MiddleLeft);
            SetRect(inputText.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 4f), new Vector2(-14f, -4f));
            Text placeholder = CreateText("Placeholder", inputRect, "输入聊天内容", 20, TextAnchor.MiddleLeft);
            placeholder.color = new Color(0.65f, 0.68f, 0.72f, 1f);
            SetRect(placeholder.rectTransform, Vector2.zero, Vector2.one, new Vector2(14f, 4f), new Vector2(-14f, -4f));
            input = inputRect.gameObject.AddComponent<InputField>();
            input.textComponent = inputText;
            input.placeholder = placeholder;
            input.lineType = InputField.LineType.SingleLine;

            Button sendButton = CreateButton("Send", inputPanel, "发送", SendCurrent);
            RectTransform sendRect = sendButton.GetComponent<RectTransform>();
            sendRect.anchorMin = new Vector2(0.84f, 0f);
            sendRect.anchorMax = Vector2.one;
            sendRect.offsetMin = sendRect.offsetMax = Vector2.zero;

            store.Changed += Render;
            Render();
        }

        public int RenderedCount { get; private set; }

        public void Render()
        {
            for (int index = content.childCount - 1; index >= 0; index--) UnityEngine.Object.Destroy(content.GetChild(index).gameObject);
            RenderedCount = 0;
            foreach (ChatMessageRecord message in store.Messages)
            {
                if (selectedChannel != ChatChannel.Combined && message.Channel != selectedChannel) continue;
                string channel = ChatCatalog.GetName(message.Channel);
                string sender = string.IsNullOrWhiteSpace(message.Sender?.Name) ? "系统" : message.Sender.Name;
                Text row = CreateText($"Message_{RenderedCount}", content, $"[{channel}] {sender}：{message.Content}", 20, TextAnchor.MiddleLeft);
                row.color = message.IsLocalEcho ? new Color(0.55f, 0.85f, 1f) : Color.white;
                row.horizontalOverflow = HorizontalWrapMode.Wrap;
                row.verticalOverflow = VerticalWrapMode.Overflow;
                LayoutElement element = row.gameObject.AddComponent<LayoutElement>();
                element.minHeight = 42f;
                element.preferredHeight = 50f;
                RenderedCount++;
            }
            errorText.text = store.LastError;
            Canvas.ForceUpdateCanvases();
        }

        public void SelectChannel(ChatChannel channel)
        {
            selectedChannel = channel;
            Render();
        }

        public void Dispose()
        {
            store.Changed -= Render;
            if (runtimeRoot != null) UnityEngine.Object.Destroy(runtimeRoot);
        }

        private void SendCurrent()
        {
            string value = input.text?.Trim();
            if (string.IsNullOrEmpty(value)) return;
            send((byte)selectedChannel, value, 0);
            input.text = string.Empty;
        }

        private RectTransform CreateRect(string name, Transform parent, Vector2 anchorMin, Vector2 anchorMax)
        {
            GameObject gameObject = new GameObject(name, typeof(RectTransform));
            RectTransform rect = gameObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            SetRect(rect, anchorMin, anchorMax, Vector2.zero, Vector2.zero);
            return rect;
        }

        private Text CreateText(string name, Transform parent, string value, int size, TextAnchor alignment)
        {
            RectTransform rect = CreateRect(name, parent, Vector2.zero, Vector2.one);
            Text text = rect.gameObject.AddComponent<Text>();
            text.font = font;
            text.fontSize = size;
            text.alignment = alignment;
            text.color = Color.white;
            text.text = value;
            return text;
        }

        private Button CreateButton(string name, Transform parent, string label, Action callback)
        {
            RectTransform rect = CreateRect(name, parent, Vector2.zero, Vector2.one);
            Image image = rect.gameObject.AddComponent<Image>();
            image.color = new Color(0.18f, 0.32f, 0.48f, 1f);
            Button button = rect.gameObject.AddComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(() => callback());
            Text text = CreateText("Label", rect, label, 20, TextAnchor.MiddleCenter);
            SetRect(text.rectTransform, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            return button;
        }

        private static void SetRect(RectTransform rect, Vector2 anchorMin, Vector2 anchorMax, Vector2 offsetMin, Vector2 offsetMax)
        {
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = offsetMin;
            rect.offsetMax = offsetMax;
        }
    }
}
