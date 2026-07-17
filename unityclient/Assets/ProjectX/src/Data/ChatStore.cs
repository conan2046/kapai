using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public enum ChatChannel : byte
    {
        Combined = 0,
        World = 1,
        Near = 2,
        Team = 3,
        Guild = 4,
        Private = 7,
        System = 9,
        CrossServer = 11
    }

    public sealed class ChatStore
    {
        public const int MaximumMessages = 200;
        private readonly List<ChatMessageRecord> messages = new List<ChatMessageRecord>();

        public event Action Changed;
        public IReadOnlyList<ChatMessageRecord> Messages => messages;
        public int Count => messages.Count;
        public string LastError { get; private set; } = string.Empty;

        public void Add(ChatMessageRecord message)
        {
            if (message == null || string.IsNullOrWhiteSpace(message.Content)) return;
            for (int index = messages.Count - 1; index >= 0; index--)
            {
                ChatMessageRecord existing = messages[index];
                if (existing.Channel != message.Channel || existing.Sender.Id != message.Sender.Id
                    || existing.Content != message.Content) continue;
                if (existing.IsLocalEcho && !message.IsLocalEcho)
                {
                    messages[index] = message;
                    Changed?.Invoke();
                    return;
                }
                if (!existing.IsLocalEcho && !message.IsLocalEcho
                    && existing.RecipientRoleId == message.RecipientRoleId
                    && existing.ServerTime == message.ServerTime) return;
            }
            messages.Add(message);
            if (messages.Count > MaximumMessages) messages.RemoveRange(0, messages.Count - MaximumMessages);
            Changed?.Invoke();
        }

        public void SetError(string message)
        {
            LastError = message ?? string.Empty;
            Changed?.Invoke();
        }

        public bool Contains(ChatChannel channel, string content)
        {
            for (int index = 0; index < messages.Count; index++)
                if (messages[index].Channel == channel && messages[index].Content == content) return true;
            return false;
        }

        public void Clear()
        {
            messages.Clear();
            LastError = string.Empty;
            Changed?.Invoke();
        }
    }

    public sealed class ChatMessageRecord
    {
        public ChatChannel Channel { get; set; }
        public PlayerSummary Sender { get; set; } = new PlayerSummary();
        public byte VipLevel { get; set; }
        public uint RecipientRoleId { get; set; }
        public uint ServerTime { get; set; }
        public string Content { get; set; } = string.Empty;
        public bool IsLocalEcho { get; set; }
    }
}
