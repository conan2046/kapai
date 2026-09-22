using System;
using System.Collections;
using System.IO;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public uint GetTeamPeerRoleId() => services?.Options.TeamPeerRoleId ?? 0;
        public uint GetTeamLeaderId() => services?.Team.LeaderId ?? 0;
        public int GetTeamPlayerCount() => services?.Team.PlayerCount ?? 0;
        public bool TeamContainsPlayer(double roleId) => services?.Team.ContainsPlayer(checked((uint)roleId)) ?? false;

        public void BeginTeamUpdate(int teamType, int formationId, int expectedCount)
        {
            pendingTeamType = checked((byte)teamType);
            pendingTeamFormationId = checked((ushort)formationId);
            pendingTeamMembers.Clear();
            if (expectedCount > pendingTeamMembers.Capacity) pendingTeamMembers.Capacity = expectedCount;
        }

        public void AddTeamPlayerMember(int sourcePosition, int lineupPosition, bool isLeader, double roleId,
            string name, int level, int sex, int head, double power, bool temporarilyAway,
            double serverZone, double serverId, double shapeId)
        {
            pendingTeamMembers.Add(new TeamMemberRecord
            {
                Kind = TeamMemberKind.Player,
                SourcePosition = checked((byte)sourcePosition),
                LineupPosition = checked((byte)lineupPosition),
                IsLeader = isLeader,
                IsTemporarilyAway = temporarilyAway,
                Player = new PlayerSummary(checked((uint)roleId), name, checked((ushort)level), checked((byte)sex),
                    checked((byte)head), checked((ulong)power)),
                ServerZone = checked((uint)serverZone),
                ServerId = checked((uint)serverId),
                ShapeId = checked((uint)shapeId)
            });
        }

        public void AddTeamPetMember(int sourcePosition, int lineupPosition, double petId, string name,
            int level, int star, int breakLevel, double power)
        {
            pendingTeamMembers.Add(new TeamMemberRecord
            {
                Kind = TeamMemberKind.Pet,
                SourcePosition = checked((byte)sourcePosition),
                LineupPosition = checked((byte)lineupPosition),
                PetId = checked((uint)petId),
                PetName = name ?? string.Empty,
                PetLevel = checked((ushort)level),
                PetStar = checked((byte)star),
                PetBreakLevel = checked((byte)breakLevel),
                PetPower = checked((ulong)power)
            });
        }

        public void EndTeamUpdate()
        {
            services.Team.Replace(pendingTeamType, pendingTeamFormationId, pendingTeamMembers);
            EnsureTeamPresenter();
            ShowTeam();
        }

        public void MarkTeamCreated() => services.Team.MarkCreated(services.Player.RoleId);
        public void ClearTeamState() => services.Team.Leave();
        public void AddTeamInvitation(double id, string name, int level, int sex, int head, double power) =>
            services.Team.AddInvitation(new PlayerSummary(checked((uint)id), name, checked((ushort)level),
                checked((byte)sex), checked((byte)head), checked((ulong)power)));
        public void RemoveTeamInvitation(double id) => services.Team.RemoveInvitation(checked((uint)id));
        public void SetTeamError(string message) { ShowToast(message, 3f); SetStatus(message); }

        public void CaptureTeamAndLeaveValidation(double peerRoleId) =>
            StartCoroutine(CaptureTeamAndLeave(checked((uint)peerRoleId)));

        public void CompleteTeamValidation(double peerRoleId)
        {
            EnsureTeamPresenter();
            if (GetLocalUserId() == 1 || !IsTeamOpen || services.Team.HasTeam || services.Team.PlayerCount != 0
                || teamPresenter.RenderedPlayerCount != 1)
            {
                Fail($"Team final state mismatch: user={GetLocalUserId()}, open={IsTeamOpen}, hasTeam={services.Team.HasTeam}, players={services.Team.PlayerCount}, rendered={teamPresenter.RenderedPlayerCount}.");
                return;
            }
            Complete($"COMPLETE: /29 empty -> create -> invite/peer accept {checked((uint)peerRoleId)} -> 2-player TeamStore/UI -> leave -> persisted empty state; /30 refresh active");
        }

        private IEnumerator CaptureTeamAndLeave(uint peerRoleId)
        {
            yield return new WaitForSecondsRealtime(1.5f);
            EnsureTeamPresenter();
            if (!services.Team.ContainsPlayer(peerRoleId) || services.Team.PlayerCount != 2
                || teamPresenter.RenderedPlayerCount != 2)
            {
                Fail($"Team joined-state mismatch: peer={peerRoleId}, players={services.Team.PlayerCount}, rendered={teamPresenter.RenderedPlayerCount}.");
                yield break;
            }
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-team-members.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onTeamLeave, "Team.OnLeave");
        }

        private void EnsureTeamPresenter()
        {
            teamView = teamView ?? services.UiRouter.FindBySource("TeamMembersLayer");
            if (teamView == null) throw new InvalidOperationException("TeamMembersLayer CocosUiBinding was not found.");
            teamPresenter = teamPresenter ?? new TeamPresenter(teamView, services.Team, services.Player,
                () => InvokeLuaOrFail(onTeamCreate, "Team.Create"),
                id => InvokeLuaOrFail(onTeamInvite, "Team.Invite", (double)id),
                () => InvokeLuaOrFail(onTeamLeave, "Team.Leave"));
        }
    }
}
