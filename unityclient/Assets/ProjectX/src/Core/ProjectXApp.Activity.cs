using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BeginActivityListUpdate(int expectedCount)
        {
            pendingActivityItems.Clear();
            if (expectedCount > pendingActivityItems.Capacity) pendingActivityItems.Capacity = expectedCount;
        }

        public void AddActivityListItem(double rawTag, string name, bool hotPoint, bool isNew, double rawRemainingSeconds)
        {
            pendingActivityItems.Add(new ActivityListRecord
            {
                Tag = checked((uint)rawTag), Name = name ?? string.Empty,
                HasHotPoint = hotPoint, IsNew = isNew,
                RemainingSeconds = checked((uint)rawRemainingSeconds)
            });
        }

        public void EndActivityListUpdate()
        {
            services.Activity.ReplaceList(pendingActivityItems, services.ServerTime.UnixSeconds);
            RefreshActivityHotPoint();
            EnsureActivityPresenter();
            SetStatus($"Activity /222 op=0xFF list: {services.Activity.Count} entries.");
        }

        public void SelectActivity(double rawTag)
        {
            services.Activity.Select(checked((uint)rawTag));
        }

        public void BeginActivityDailyRechargeUpdate(bool weChatVisible, bool recharged, bool claimed,
            bool weChatRecharged, bool weChatClaimed, int expectedCount)
        {
            pendingDailyRecharge = new DailyRechargeActivityState
            {
                WeChatRewardVisible = weChatVisible, Recharged = recharged, Claimed = claimed,
                WeChatRecharged = weChatRecharged, WeChatClaimed = weChatClaimed
            };
            if (expectedCount > pendingDailyRecharge.Rewards.Capacity)
                pendingDailyRecharge.Rewards.Capacity = expectedCount;
        }

        public void AddActivityReward(int rewardType, double rawAmount, string name, int picture, int quality)
        {
            if (pendingDailyRecharge == null) throw new InvalidOperationException("Activity daily recharge update was not started.");
            pendingDailyRecharge.Rewards.Add(new ActivityRewardRecord
            {
                Type = checked((ushort)rewardType), Amount = checked((uint)rawAmount),
                Name = name ?? string.Empty, Picture = picture, Quality = quality
            });
        }

        public void EndActivityDailyRechargeUpdate(bool validation)
        {
            if (pendingDailyRecharge == null) throw new InvalidOperationException("Activity daily recharge update was not started.");
            services.Activity.SetDailyRecharge(pendingDailyRecharge);
            EnsureActivityPresenter();
            SetStatus($"Activity /222 op=18 subOp=1: rewards={services.Activity.DailyRecharge.Rewards.Count}, recharged={services.Activity.DailyRecharge.Recharged}, claimed={services.Activity.DailyRecharge.Claimed}.");
            if (validation) StartCoroutine(CaptureActivityValidationStates());
        }

        public void SetActivityError(string message) { ShowToast(message, 3f); SetStatus(message); }

        public void CompleteActivityValidation()
        {
            EnsureActivityPresenter();
            bool hasUnsupportedTab = services.Activity.Items.Any(value => value.Tag != ActivityPresenter.DailyRechargeTag);
            if (GetLocalUserId() == 1 || !IsActivityOpen || services.Activity.Count < 2
                || !hasUnsupportedTab || !IsActivityDailyRechargeVisible || ActivityRewardCount == 0
                || !activityPresenter.HasCountdown || services.ProtocolRegistry.PendingCount != 0
                || IsActivityHotPointVisible != services.Activity.HasHotPoint)
            {
                Fail($"Activity final state mismatch: user={GetLocalUserId()}, open={IsActivityOpen}, list={services.Activity.Count}, daily={IsActivityDailyRechargeVisible}, rewards={ActivityRewardCount}, countdown={activityPresenter.HasCountdown}, pending={services.ProtocolRegistry.PendingCount}, hot={IsActivityHotPointVisible}/{services.Activity.HasHotPoint}.");
                return;
            }
            Complete($"COMPLETE: Activity /222 op=0xFF list -> real tabs/hot-point/countdown -> op=18 subOp=1 daily recharge state/rewards -> unsupported real tab empty boundary; isolated user={GetLocalUserId()}");
        }


        private void EnsureActivityHotPoint(Transform button)
        {
            Transform existing = button.Find("ActivityHotPointRuntime");
            if (existing == null)
            {
                GameObject go = new GameObject("ActivityHotPointRuntime", typeof(RectTransform), typeof(Image));
                RectTransform rect = go.GetComponent<RectTransform>();
                rect.SetParent(button, false); rect.anchorMin = new Vector2(0.82f, 0.72f);
                rect.anchorMax = new Vector2(0.98f, 0.94f); rect.offsetMin = rect.offsetMax = Vector2.zero;
                go.GetComponent<Image>().color = new Color(0.95f, 0.08f, 0.04f, 1f);
            }
            RefreshActivityHotPoint();
        }

        private void RefreshActivityHotPoint()
        {
            GameObject button = mainView?.FindNode(ActivityPath);
            Transform hotPoint = button?.transform.Find("ActivityHotPointRuntime");
            if (hotPoint != null) hotPoint.gameObject.SetActive(services?.Activity.HasHotPoint == true);
        }

        private IEnumerator CaptureActivityValidationStates()
        {
            EnsureActivityPresenter();
            services.Activity.Select(ActivityPresenter.DailyRechargeTag);
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-activity-detail.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            ActivityListRecord unsupported = services.Activity.Items.FirstOrDefault(value => value.Tag != ActivityPresenter.DailyRechargeTag);
            if (unsupported == null)
            {
                Fail("Activity validation did not receive the real unsupported-tab fixture.");
                yield break;
            }
            services.Activity.Select(unsupported.Tag);
            yield return new WaitForEndOfFrame();
            if (!activityPresenter.EmptyStateVisible)
            {
                Fail($"Activity unsupported tab #{unsupported.Tag} did not render the first-phase empty boundary.");
                yield break;
            }
            ScreenCapture.CaptureScreenshot(Path.Combine(directory, "bootstrap-activity-empty.png"));
            yield return new WaitForSecondsRealtime(0.8f);
            services.Activity.Select(ActivityPresenter.DailyRechargeTag);
            yield return new WaitForEndOfFrame();
            CompleteActivityValidation();
        }


        private void EnsureActivityPresenter()
        {
            activityRootView = activityRootView ?? services.UiRouter.FindBySource("huodong/ActivityRankingLayer");
            activityBackgroundView = activityBackgroundView ?? services.UiRouter.FindBySource("huodong/ActivityLevelLayer");
            activityDailyRechargeView = activityDailyRechargeView ?? services.UiRouter.FindBySource("DailyChargeLayer");
            if (activityRootView == null || activityBackgroundView == null || activityDailyRechargeView == null)
                throw new InvalidOperationException("Current Activity imported CocosUiBindings were not found by full relative path.");
            activityPresenter = activityPresenter ?? new ActivityPresenter(activityRootView, activityBackgroundView,
                activityDailyRechargeView, services.Activity, services.ServerTime,
                tag => InvokeLuaOrFail(onActivitySelected, "Activity.Selected", (double)tag), () => HandleBack());
        }

    }
}

