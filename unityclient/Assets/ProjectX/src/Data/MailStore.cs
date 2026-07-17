using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct MailRecord
    {
        public MailRecord(uint id, uint fromId, string sender, uint expireAt, string message,
            IReadOnlyList<RewardRecord> attachments, bool isRead = false)
        {
            Id = id;
            FromId = fromId;
            Sender = sender ?? string.Empty;
            ExpireAt = expireAt;
            Message = message ?? string.Empty;
            Attachments = attachments ?? Array.Empty<RewardRecord>();
            IsRead = isRead;
        }

        public uint Id { get; }
        public uint FromId { get; }
        public string Sender { get; }
        public uint ExpireAt { get; }
        public string Message { get; }
        public IReadOnlyList<RewardRecord> Attachments { get; }
        public bool IsRead { get; }
        public bool HasAttachments => Attachments.Count > 0;

        public MailRecord WithRead(bool value) =>
            new MailRecord(Id, FromId, Sender, ExpireAt, Message, Attachments, value);
    }

    public sealed class MailStore
    {
        private readonly Dictionary<uint, MailRecord> records = new Dictionary<uint, MailRecord>();

        public event Action Changed;
        public int Count => records.Count;
        public bool HasUnread => records.Values.Any(item => !item.IsRead);
        public IReadOnlyList<MailRecord> Items => records.Values
            .OrderByDescending(item => item.ExpireAt)
            .ThenByDescending(item => item.Id)
            .ToArray();

        public void Replace(IEnumerable<MailRecord> values)
        {
            var readIds = new HashSet<uint>(records.Values.Where(item => item.IsRead).Select(item => item.Id));
            records.Clear();
            foreach (MailRecord value in values ?? Array.Empty<MailRecord>())
                records[value.Id] = value.WithRead(value.IsRead || readIds.Contains(value.Id));
            Changed?.Invoke();
        }

        public bool TryGet(uint id, out MailRecord value) => records.TryGetValue(id, out value);

        public bool MarkRead(uint id)
        {
            if (!records.TryGetValue(id, out MailRecord value)) return false;
            if (!value.IsRead)
            {
                records[id] = value.WithRead(true);
                Changed?.Invoke();
            }
            return true;
        }

        public bool Remove(uint id)
        {
            bool removed = records.Remove(id);
            if (removed) Changed?.Invoke();
            return removed;
        }

        public void Clear()
        {
            records.Clear();
            Changed?.Invoke();
        }
    }
}
