using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct FriendRecord
    {
        public FriendRecord(uint id, string name, ushort level, byte sex, byte head, ulong power,
            uint offlineSeconds, uint guildId, string guildName, uint intimacy = 0, byte sendFlag = 0)
        {
            Player = new PlayerSummary(id, name, level, sex, head, power, guildId: guildId);
            OfflineSeconds = offlineSeconds;
            GuildName = guildName ?? string.Empty;
            Intimacy = intimacy;
            SendFlag = sendFlag;
        }

        public PlayerSummary Player { get; }
        public uint Id => Player.Id;
        public string Name => Player.Name;
        public ushort Level => Player.Level;
        public byte Sex => Player.Sex;
        public byte Head => Player.Head;
        public ulong Power => Player.Power;
        public uint OfflineSeconds { get; }
        public uint GuildId => Player.GuildId;
        public string GuildName { get; }
        public uint Intimacy { get; }
        public byte SendFlag { get; }
        public bool IsOnline => OfflineSeconds == 0;
    }

    public sealed class FriendStore
    {
        private readonly Dictionary<uint, FriendRecord> friends = new Dictionary<uint, FriendRecord>();
        private readonly Dictionary<uint, FriendRecord> applications = new Dictionary<uint, FriendRecord>();

        public event Action Changed;
        public int FriendCount => friends.Count;
        public int ApplicationCount => applications.Count;
        public byte MaxFriends { get; private set; }
        public byte MaxApplications { get; private set; }
        public IReadOnlyList<FriendRecord> Friends => Order(friends.Values);
        public IReadOnlyList<FriendRecord> Applications => Order(applications.Values);

        public void ReplaceFriends(byte maximum, IEnumerable<FriendRecord> values)
        {
            MaxFriends = maximum;
            Replace(friends, values);
        }

        public void ReplaceApplications(byte maximum, IEnumerable<FriendRecord> values)
        {
            MaxApplications = maximum;
            Replace(applications, values);
        }

        public bool RemoveFriend(uint id)
        {
            bool removed = friends.Remove(id);
            if (removed) Changed?.Invoke();
            return removed;
        }

        public bool RemoveApplication(uint id)
        {
            bool removed = applications.Remove(id);
            if (removed) Changed?.Invoke();
            return removed;
        }

        public void Clear()
        {
            friends.Clear();
            applications.Clear();
            MaxFriends = 0;
            MaxApplications = 0;
            Changed?.Invoke();
        }

        private void Replace(Dictionary<uint, FriendRecord> target, IEnumerable<FriendRecord> values)
        {
            target.Clear();
            foreach (FriendRecord value in values ?? Array.Empty<FriendRecord>()) target[value.Id] = value;
            Changed?.Invoke();
        }

        private static IReadOnlyList<FriendRecord> Order(IEnumerable<FriendRecord> values) => values
            .OrderBy(item => item.OfflineSeconds)
            .ThenByDescending(item => item.Power)
            .ThenBy(item => item.Id)
            .ToArray();
    }
}
