using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class GuildRecord
    {
        public ushort Rank { get; set; }
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public byte Level { get; set; }
        public string LeaderName { get; set; } = string.Empty;
        public ushort MemberCount { get; set; }
        public ushort MaximumMembers { get; set; }
        public ushort PlantedCount { get; set; }
        public string Notice { get; set; } = string.Empty;
        public bool HasApplied { get; set; }
        public ushort AutoAcceptLevel { get; set; }
    }

    public sealed class GuildInfo
    {
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string LeaderName { get; set; } = string.Empty;
        public byte Level { get; set; }
        public ushort LegacyId { get; set; }
        public ushort MemberCount { get; set; }
        public uint Prosperity { get; set; }
        public string Notice { get; set; } = string.Empty;
        public string Slogan { get; set; } = string.Empty;
        public ushort AutoAcceptLevel { get; set; }
    }

    public sealed class GuildMemberRecord
    {
        public PlayerSummary Player { get; set; }
        public byte Rank { get; set; }
        public uint Contribution { get; set; }
        public byte VipLevel { get; set; }
        public uint LastOfflineSeconds { get; set; }
        public uint DailyActivity { get; set; }
    }

    public sealed class GuildStore
    {
        private readonly List<GuildRecord> items = new List<GuildRecord>();
        private readonly List<GuildMemberRecord> members = new List<GuildMemberRecord>();

        public event Action Changed;
        public IReadOnlyList<GuildRecord> Items => items;
        public IReadOnlyList<GuildMemberRecord> Members => members;
        public GuildInfo Info { get; private set; }
        public bool HasGuild => Info != null && Info.Id != 0;
        public int MemberCount => members.Count;

        public void ReplaceList(IEnumerable<GuildRecord> values)
        {
            items.Clear();
            if (values != null) items.AddRange(values);
            Changed?.Invoke();
        }

        public void SetInfo(GuildInfo value)
        {
            Info = value;
            Changed?.Invoke();
        }

        public void ReplaceMembers(IEnumerable<GuildMemberRecord> values)
        {
            members.Clear();
            if (values != null) members.AddRange(values.OrderBy(item => item.Rank).ThenByDescending(item => item.Player?.Power ?? 0));
            Changed?.Invoke();
        }

        public bool ContainsMember(uint roleId) => members.Any(item => item.Player?.Id == roleId);

        public void ClearGuild()
        {
            Info = null;
            members.Clear();
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear();
            members.Clear();
            Info = null;
            Changed?.Invoke();
        }
    }
}
