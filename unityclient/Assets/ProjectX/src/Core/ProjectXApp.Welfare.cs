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
        public void BeginWelfareSignUpdate(bool signedToday, int signedDays, int expectedCount)
        {
            pendingWelfareSignedToday = signedToday;
            pendingWelfareSignedDays = checked((byte)signedDays);
            pendingWelfareSigns.Clear();
            if (expectedCount > pendingWelfareSigns.Capacity) pendingWelfareSigns.Capacity = expectedCount;
        }

        public void AddWelfareSign(int day, int rewardType, double rewardId, double amount, double rewardValue,
            int vipLevel, int vipMultiple, string name, int picture, int quality)
        {
            pendingWelfareSigns.Add(new WelfareSignRecord
            {
                Day = checked((byte)day),
                Reward = new RewardRecord(rewardType, checked((uint)rewardId), checked((uint)amount), name, picture, quality),
                VipLevel = checked((byte)vipLevel),
                VipMultiple = checked((byte)vipMultiple)
            });
        }

        public void EndWelfareSignUpdate()
        {
            services.Welfare.ReplaceSigns(pendingWelfareSignedToday, pendingWelfareSignedDays, pendingWelfareSigns);
            RefreshWelfareHotPoint();
            EnsureWelfarePresenter();
            SetStatus($"Welfare /199 sign: today={pendingWelfareSignedToday}, days={pendingWelfareSignedDays}, rewards={pendingWelfareSigns.Count}.");
        }

        public void BeginWelfareOnlineUpdate(int claimedCount, double accumulatedSeconds, int expectedCount)
        {
            pendingWelfareOnlineClaimed = checked((byte)claimedCount);
            pendingWelfareOnlineSeconds = checked((uint)accumulatedSeconds);
            pendingWelfareOnline.Clear();
            if (expectedCount > pendingWelfareOnline.Capacity) pendingWelfareOnline.Capacity = expectedCount;
        }

        public void AddWelfareOnline(int id, int cumulativeMinutes, double requiredSeconds, int rewardType,
            double rewardId, double amount, string name, int picture, int quality)
        {
            pendingWelfareOnline.Add(new WelfareOnlineRecord
            {
                Id = checked((byte)id), CumulativeMinutes = checked((ushort)cumulativeMinutes),
                RequiredSeconds = checked((uint)requiredSeconds),
                Reward = new RewardRecord(rewardType, checked((uint)rewardId), checked((uint)amount), name, picture, quality)
            });
        }

        public void EndWelfareOnlineUpdate()
        {
            services.Welfare.ReplaceOnline(pendingWelfareOnlineClaimed, pendingWelfareOnlineSeconds,
                services.ServerTime.UnixSeconds, pendingWelfareOnline);
            RefreshWelfareHotPoint();
            EnsureWelfarePresenter();
            SetStatus($"Welfare /222 online: claimed={pendingWelfareOnlineClaimed}, elapsed={pendingWelfareOnlineSeconds}s, rewards={pendingWelfareOnline.Count}.");
        }

        public void SetWelfareError(string message) { ShowToast(message, 3f); SetStatus(message); }
        public void CaptureWelfareAndClaim() => StartCoroutine(CaptureWelfareTabsAndClaim());

        public void CompleteWelfareValidation(int signedDays)
        {
            EnsureWelfarePresenter();
            if (GetLocalUserId() == 1 || !IsWelfareOpen || !services.Welfare.SignedToday
                || services.Welfare.SignedDays != signedDays || services.Welfare.Signs.Count == 0
                || services.Welfare.Online.Count == 0 || services.ProtocolRegistry.PendingCount != 0
                || IsWelfareHotPointVisible != services.Welfare.HasClaimable)
            {
                Fail($"Welfare final state mismatch: user={GetLocalUserId()}, open={IsWelfareOpen}, today={services.Welfare.SignedToday}, days={services.Welfare.SignedDays}/{signedDays}, sign={services.Welfare.Signs.Count}, online={services.Welfare.Online.Count}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            rewardPresenter?.Hide();
            welfarePresenter.SelectTab(0);
            Complete($"COMPLETE: /199 sign list -> single daily claim -> authoritative re-pull days={signedDays}; /222 online status={services.Welfare.OnlineClaimedCount}/{services.Welfare.Online.Count}; /223 unavailable empty state; isolated user={GetLocalUserId()}");
        }

        private IEnumerator CaptureWelfareTabsAndClaim()
        {
            EnsureWelfarePresenter();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            welfarePresenter.SelectTab(0);
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-sign.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(1);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-online.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(2);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-welfare-stage-empty.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            welfarePresenter.SelectTab(0);
            InvokeLuaOrFail(onWelfareClaimSign, "Welfare.ClaimSign");
        }

        private void EnsureWelfarePresenter()
        {
            welfareView = welfareView ?? services.UiRouter.FindBySource("WelfareLayer");
            welfareSignView = welfareSignView ?? services.UiRouter.FindBySource("SignLayer");
            welfareOnlineView = welfareOnlineView ?? services.UiRouter.FindBySource("huodong/LoginGiftLayer");
            if (welfareView == null || welfareSignView == null || welfareOnlineView == null)
                throw new InvalidOperationException("Welfare imported CocosUiBindings were not found.");
            welfarePresenter = welfarePresenter ?? new WelfarePresenter(welfareView, welfareSignView, welfareOnlineView,
                services.Welfare, services.ServerTime, services.Resources,
                () => InvokeLuaOrFail(onWelfareClaimSign, "Welfare.ClaimSign"), () => HandleBack());
        }
    }
}
