using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public enum TeamMemberKind : byte { Player = 1, Pet = 2 }

    public sealed class TeamMemberRecord
    {
        public TeamMemberKind Kind { get; set; }
        public byte SourcePosition { get; set; }
        public byte LineupPosition { get; set; }
        public bool IsLeader { get; set; }
        public bool IsTemporarilyAway { get; set; }
        public PlayerSummary Player { get; set; }
        public uint PetId { get; set; }
        public string PetName { get; set; } = string.Empty;
        public ushort PetLevel { get; set; }
        public byte PetStar { get; set; }
        public byte PetBreakLevel { get; set; }
        public ulong PetPower { get; set; }
        public uint ServerZone { get; set; }
        public uint ServerId { get; set; }
        public IReadOnlyList<ushort> Titles { get; set; } = Array.Empty<ushort>();
        public uint ShapeId { get; set; }

        public uint Id => Kind == TeamMemberKind.Player ? Player?.Id ?? 0 : PetId;
        public string Name => Kind == TeamMemberKind.Player ? Player?.Name ?? string.Empty : PetName;
        public ushort Level => Kind == TeamMemberKind.Player ? Player?.Level ?? 0 : PetLevel;
        public ulong Power => Kind == TeamMemberKind.Player ? Player?.Power ?? 0 : PetPower;
    }

    public sealed class TeamInvitationRecord
    {
        public PlayerSummary Inviter { get; set; }
    }

    public sealed class TeamStore
    {
        private readonly List<TeamMemberRecord> members = new List<TeamMemberRecord>();
        private readonly Dictionary<uint, TeamInvitationRecord> invitations = new Dictionary<uint, TeamInvitationRecord>();

        public event Action Changed;
        public bool HasTeam { get; private set; }
        public uint LeaderId { get; private set; }
        public byte TeamType { get; private set; } = byte.MaxValue;
        public ushort FormationId { get; private set; }
        public IReadOnlyList<TeamMemberRecord> Members => members;
        public IReadOnlyList<TeamInvitationRecord> Invitations => invitations.Values.ToArray();
        public int PlayerCount => members.Count(item => item.Kind == TeamMemberKind.Player);

        public void MarkCreated(uint leaderId)
        {
            HasTeam = leaderId != 0;
            LeaderId = leaderId;
            Changed?.Invoke();
        }

        public void Replace(byte teamType, ushort formationId, IEnumerable<TeamMemberRecord> values)
        {
            members.Clear();
            if (values != null) members.AddRange(values);
            TeamType = teamType;
            FormationId = formationId;
            TeamMemberRecord leader = members.FirstOrDefault(item => item.Kind == TeamMemberKind.Player && item.IsLeader);
            LeaderId = leader?.Player?.Id ?? 0;
            HasTeam = LeaderId != 0 || members.Count > 0;
            Changed?.Invoke();
        }

        public void AddInvitation(PlayerSummary inviter)
        {
            if (inviter == null || inviter.Id == 0) return;
            invitations[inviter.Id] = new TeamInvitationRecord { Inviter = inviter };
            Changed?.Invoke();
        }

        public void RemoveInvitation(uint leaderId)
        {
            if (invitations.Remove(leaderId)) Changed?.Invoke();
        }

        public bool ContainsPlayer(uint roleId) => members.Any(item => item.Kind == TeamMemberKind.Player && item.Player?.Id == roleId);

        public void Leave()
        {
            members.Clear();
            invitations.Clear();
            HasTeam = false;
            LeaderId = 0;
            TeamType = byte.MaxValue;
            FormationId = 0;
            Changed?.Invoke();
        }

        public void Clear() => Leave();
    }
}
