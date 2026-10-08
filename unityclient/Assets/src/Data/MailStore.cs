using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

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
        private readonly Dictionary<uint, MailRecord> history = new Dictionary<uint, MailRecord>();
        private uint accountId;

        public event Action Changed;
        public int Count => records.Count;
        public bool HasUnread => records.Values.Any(item => !item.IsRead);
        public bool HasClaimable => records.Values.Any(item => !item.IsRead && item.HasAttachments);
        public bool HasHistory => history.Count > 0;
        public IReadOnlyList<MailRecord> Items => records.Values
            .OrderByDescending(item => item.ExpireAt)
            .ThenByDescending(item => item.Id)
            .ToArray();

        public void ConfigureAccount(uint value)
        {
            if (accountId == value) return;
            accountId = value;
            records.Clear();
            history.Clear();
            if (accountId != 0) LoadHistory();
            foreach (MailRecord item in history.Values) records[item.Id] = item;
            Changed?.Invoke();
        }

        public void Replace(IEnumerable<MailRecord> values)
        {
            records.Clear();
            foreach (MailRecord value in values ?? Array.Empty<MailRecord>())
                records[value.Id] = value;
            foreach (MailRecord value in history.Values)
                records[value.Id] = value;
            Changed?.Invoke();
        }

        public bool TryGet(uint id, out MailRecord value) => records.TryGetValue(id, out value);

        public bool MoveToHistory(uint id)
        {
            if (!records.TryGetValue(id, out MailRecord value)) return false;
            MailRecord stored = new MailRecord(value.Id, value.FromId, value.Sender, value.ExpireAt,
                value.Message, Array.Empty<RewardRecord>(), true);
            history[id] = stored;
            records[id] = stored;
            SaveHistory();
            Changed?.Invoke();
            return true;
        }

        public bool DeleteHistory(uint id)
        {
            bool removed = history.Remove(id);
            if (removed) records.Remove(id);
            SaveHistory();
            if (removed) Changed?.Invoke();
            return removed;
        }

        public int DeleteAllHistory()
        {
            if (history.Count == 0) return 0;
            uint[] ids = history.Keys.ToArray();
            foreach (uint id in ids) records.Remove(id);
            int count = history.Count;
            history.Clear();
            SaveHistory();
            Changed?.Invoke();
            return count;
        }

        public void Clear()
        {
            records.Clear();
            history.Clear();
            accountId = 0;
            Changed?.Invoke();
        }

        private string Key(string suffix) => $"ProjectX.Mail.{accountId}.{suffix}";

        private void LoadHistory()
        {
            string ids = PlayerPrefs.GetString(Key("Ids"), string.Empty);
            foreach (string token in ids.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
            {
                if (!uint.TryParse(token, out uint id)) continue;
                if (!uint.TryParse(PlayerPrefs.GetString(Key($"{id}.FromId"), "0"), out uint fromId)) fromId = 0;
                if (!uint.TryParse(PlayerPrefs.GetString(Key($"{id}.ExpireAt"), "0"), out uint expireAt)) expireAt = 0;
                string sender = PlayerPrefs.GetString(Key($"{id}.Sender"), string.Empty);
                string message = PlayerPrefs.GetString(Key($"{id}.Message"), string.Empty);
                history[id] = new MailRecord(id, fromId, sender, expireAt, message,
                    Array.Empty<RewardRecord>(), true);
            }
        }

        private void SaveHistory()
        {
            if (accountId == 0) return;
            string prefix = Key(string.Empty);
            string previous = PlayerPrefs.GetString(Key("Ids"), string.Empty);
            foreach (string token in previous.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
            {
                PlayerPrefs.DeleteKey(prefix + token + ".FromId");
                PlayerPrefs.DeleteKey(prefix + token + ".ExpireAt");
                PlayerPrefs.DeleteKey(prefix + token + ".Sender");
                PlayerPrefs.DeleteKey(prefix + token + ".Message");
            }
            PlayerPrefs.SetString(Key("Ids"), string.Join(",", history.Keys.OrderBy(id => id)));
            foreach (MailRecord value in history.Values)
            {
                PlayerPrefs.SetString(Key($"{value.Id}.FromId"), value.FromId.ToString());
                PlayerPrefs.SetString(Key($"{value.Id}.ExpireAt"), value.ExpireAt.ToString());
                PlayerPrefs.SetString(Key($"{value.Id}.Sender"), value.Sender);
                PlayerPrefs.SetString(Key($"{value.Id}.Message"), value.Message);
            }
            PlayerPrefs.Save();
        }
    }
}
