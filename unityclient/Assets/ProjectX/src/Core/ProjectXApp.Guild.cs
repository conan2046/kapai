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
        public void BeginGuildList(int expectedCount)
        {
            pendingGuildRecords.Clear();
            if (expectedCount > pendingGuildRecords.Capacity) pendingGuildRecords.Capacity = expectedCount;
        }

        public void AddGuildRecord(int rank, double id, string name, int level, string leaderName,
            int memberCount, int maximumMembers, int plantedCount, string notice, bool applied, int autoAcceptLevel)
        {
            pendingGuildRecords.Add(new GuildRecord
            {
                Rank = checked((ushort)rank),
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                Level = checked((byte)level),
                LeaderName = leaderName ?? string.Empty,
                MemberCount = checked((ushort)memberCount),
                MaximumMembers = checked((ushort)maximumMembers),
                PlantedCount = checked((ushort)plantedCount),
                Notice = notice ?? string.Empty,
                HasApplied = applied,
                AutoAcceptLevel = checked((ushort)autoAcceptLevel)
            });
        }

        public void EndGuildList()
        {
            services.Guild.ReplaceList(pendingGuildRecords);
            EnsureGuildPresenter();
        }

        public void SetGuildInfo(double id, string name, string leaderName, int level, int legacyId,
            int memberCount, double prosperity, string notice, string slogan, int autoAcceptLevel)
        {
            services.Guild.SetInfo(new GuildInfo
            {
                Id = checked((uint)id),
                Name = name ?? string.Empty,
                LeaderName = leaderName ?? string.Empty,
                Level = checked((byte)level),
                LegacyId = checked((ushort)legacyId),
                MemberCount = checked((ushort)memberCount),
                Prosperity = checked((uint)prosperity),
                Notice = notice ?? string.Empty,
                Slogan = slogan ?? string.Empty,
                AutoAcceptLevel = checked((ushort)autoAcceptLevel)
            });
            EnsureGuildPresenter();
            guildPresenter.ShowInfo();
            SetStatus($"Guild/54 info: {name}, {memberCount} members.");
        }

        public void BeginGuildMembers(int expectedCount)
        {
            pendingGuildMembers.Clear();
            if (expectedCount > pendingGuildMembers.Capacity) pendingGuildMembers.Capacity = expectedCount;
        }

        public void AddGuildMember(double roleId, string name, int level, int rank, int head,
            double contribution, int sex, double power, int vip, double lastOfflineSeconds, double dailyActivity)
        {
            uint guildId = services.Guild.Info?.Id ?? 0;
            pendingGuildMembers.Add(new GuildMemberRecord
            {
                Player = new PlayerSummary(checked((uint)roleId), name, checked((ushort)level),
                    checked((byte)sex), checked((byte)head), checked((ulong)power), guildId: guildId),
                Rank = checked((byte)rank),
                Contribution = checked((uint)contribution),
                VipLevel = checked((byte)vip),
                LastOfflineSeconds = checked((uint)lastOfflineSeconds),
                DailyActivity = checked((uint)dailyActivity)
            });
        }

        public void EndGuildMembers()
        {
            services.Guild.ReplaceMembers(pendingGuildMembers);
            EnsureGuildPresenter();
            guildPresenter.ShowMembers(false);
            SetStatus($"Guild/54 member list: {services.Guild.MemberCount} players.");
        }

        public void ClearGuildState()
        {
            services.Guild.ClearGuild();
            guildPresenter?.ShowInfo();
        }

        public string MakeGuildValidationName() => $"验{GetLocalUserId() % 100000:D5}";
        public void SetGuildError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureGuildAndLeaveValidation() => StartCoroutine(CaptureGuildAndLeave());

        public void CompleteGuildValidation(string expectedName)
        {
            EnsureGuildPresenter();
            if (GetLocalUserId() == 1 || !IsGuildOpen || services.Guild.HasGuild
                || services.Guild.MemberCount != 0 || guildPresenter.ShowingMembers)
            {
                Fail($"Guild final state mismatch: user={GetLocalUserId()}, open={IsGuildOpen}, hasGuild={services.Guild.HasGuild}, members={services.Guild.MemberCount}, memberView={guildPresenter.ShowingMembers}.");
                return;
            }
            Complete($"COMPLETE: /54 empty/list -> create {expectedName} -> guild info -> PlayerSummary member list -> leave/dismiss -> persisted empty state");
        }

        private IEnumerator CaptureGuildAndLeave()
        {
            yield return new WaitForSecondsRealtime(1.5f);
            EnsureGuildPresenter();
            uint roleId = services.Player.RoleId;
            if (!services.Guild.HasGuild || services.Guild.MemberCount != 1
                || !services.Guild.ContainsMember(roleId) || guildPresenter.RenderedMemberCount != 1)
            {
                Fail($"Guild joined-state mismatch: guild={services.Guild.Info?.Id ?? 0}, role={roleId}, members={services.Guild.MemberCount}, rendered={guildPresenter.RenderedMemberCount}.");
                yield break;
            }
            guildPresenter.ShowMembers(false);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-guild-members.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onGuildLeave, "Guild.OnLeave");
        }

        private void EnsureGuildPresenter()
        {
            guildView = guildView ?? services.UiRouter.FindBySource("bangpai/GangsApplyLayer");
            guildInfoView = guildInfoView ?? services.UiRouter.FindBySource("bangpai/GangsLayer");
            guildMemberView = guildMemberView ?? services.UiRouter.FindBySource("bangpai/GangsMemberLayer");
            guildCreateView = guildCreateView ?? services.UiRouter.FindBySource("bangpai/GangsfoundLayer");
            if (guildView == null || guildInfoView == null || guildMemberView == null || guildCreateView == null)
                throw new InvalidOperationException("Guild imported CocosUiBindings were not found.");
            guildPresenter = guildPresenter ?? new GuildPresenter(guildView, guildInfoView, guildMemberView,
                guildCreateView, services.Guild, services.Player,
                name => InvokeLuaOrFail(onGuildCreate, "Guild.Create", name),
                () => InvokeLuaOrFail(onGuildRequestMembers, "Guild.RequestMembers"),
                () => InvokeLuaOrFail(onGuildLeave, "Guild.Leave"));
        }
    }
}
