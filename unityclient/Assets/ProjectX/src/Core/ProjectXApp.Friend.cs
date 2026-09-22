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
        public void BeginFriendListUpdate(int maximum, int expectedCount) => BeginFriendUpdate(maximum, expectedCount);
        public void BeginFriendApplicationUpdate(int maximum, int expectedCount) => BeginFriendUpdate(maximum, expectedCount);

        public void AddFriendRecord(double id, string name, int level, int sex, int head, double power,
            double offlineSeconds, double guildId, string guildName, double intimacy, int sendFlag)
        {
            pendingFriendRecords.Add(new FriendRecord(checked((uint)id), name, checked((ushort)level),
                checked((byte)sex), checked((byte)head), checked((ulong)power), checked((uint)offlineSeconds),
                checked((uint)guildId), guildName, checked((uint)intimacy), checked((byte)sendFlag)));
        }

        public void EndFriendListUpdate()
        {
            services.Friends.ReplaceFriends(pendingFriendMaximum, pendingFriendRecords);
            EnsureFriendPresenter();
            ShowFriend();
        }

        public void EndFriendApplicationUpdate()
        {
            services.Friends.ReplaceApplications(pendingFriendMaximum, pendingFriendRecords);
            EnsureFriendPresenter();
            ShowFriend();
        }

        public bool RemoveFriend(double id) => services.Friends.RemoveFriend(checked((uint)id));
        public bool RemoveFriendApplication(double id) => services.Friends.RemoveApplication(checked((uint)id));

        public void CaptureFriendAndDeleteValidation(double id)
        {
            EnsureFriendPresenter();
            friendPresenter.ShowFriends(false);
            toastPresenter?.Clear();
            StartCoroutine(CaptureFriendAndDelete(checked((uint)id)));
        }

        public void CompleteFriendMutationValidation(double rejectedId, double acceptedId)
        {
            EnsureFriendPresenter();
            friendPresenter.ShowFriends(false);
            if (!IsFriendOpen || services.Friends.FriendCount != 0 || services.Friends.ApplicationCount != 0
                || friendPresenter.RenderedCount != 0)
            {
                Fail($"Friend final state mismatch: open={IsFriendOpen}, friends={services.Friends.FriendCount}, applications={services.Friends.ApplicationCount}, rendered={friendPresenter.RenderedCount}.");
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /27 seeded applications -> reject {checked((uint)rejectedId)} -> add/duplicate-error -> accept {checked((uint)acceptedId)} -> FriendStore/UI -> delete -> persisted empty state");
        }

        private IEnumerator CaptureFriendAndDelete(uint roleId)
        {
            yield return new WaitForSecondsRealtime(2.1f);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-friend-list.png");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.75f);
            InvokeLuaOrFail(onFriendDelete, "Friend.OnDelete", (double)roleId);
        }

        private void EnsureFriendPresenter()
        {
            friendView = friendView ?? services.UiRouter.FindBySource("common/FriendLayer");
            if (friendView == null) throw new InvalidOperationException("common/FriendLayer CocosUiBinding was not found.");
            friendPresenter = friendPresenter ?? new FriendPresenter(friendView, services.Friends,
                () => InvokeLuaOrFail(onFriendRequestList, "Friend.RequestList"),
                () => InvokeLuaOrFail(onFriendRequestApplications, "Friend.RequestApplications"),
                id => InvokeLuaOrFail(onFriendApply, "Friend.Apply", (double)id),
                (id, accept) => InvokeLuaOrFail(onFriendDeal, "Friend.Deal", (double)id, accept),
                id => InvokeLuaOrFail(onFriendDelete, "Friend.Delete", (double)id));
        }

        private void BeginFriendUpdate(int maximum, int expectedCount)
        {
            pendingFriendMaximum = checked((byte)maximum);
            pendingFriendRecords.Clear();
            if (expectedCount > pendingFriendRecords.Capacity) pendingFriendRecords.Capacity = expectedCount;
        }
    }
}
