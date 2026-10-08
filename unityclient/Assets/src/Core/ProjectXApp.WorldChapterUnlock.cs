using System;
using System.Collections;
using System.Linq;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const uint MainAchievementAutoOpenChapterId = 1003;
        private UnityUiView worldChapterUnlockNoticeView;
        private Coroutine worldChapterUnlockNoticeCoroutine;
        private uint pendingWorldChapterUnlockNoticeChapterId;
        private string pendingWorldChapterUnlockNoticeChapterName;
        private bool pendingWorldAchievementAutoOpen;

        private void RecordWorldChapterUnlockNotice(uint unlockedChapterId)
        {
            pendingWorldChapterUnlockNoticeChapterId = 0;
            pendingWorldChapterUnlockNoticeChapterName = string.Empty;
            pendingWorldAchievementAutoOpen = false;

            uint completedChapterId = services?.World?.SelectedChapterId ?? 0;
            if (unlockedChapterId == 0 || completedChapterId == 0
                || unlockedChapterId == completedChapterId)
                return;

            pendingWorldChapterUnlockNoticeChapterId = completedChapterId;
            pendingWorldChapterUnlockNoticeChapterName = services.World.SelectedChapterName;
            // NormalFuBenUI opens main achievement automatically after the
            // chapter-unlock notice when the newly unlocked chapter is 1003.
            pendingWorldAchievementAutoOpen = unlockedChapterId == MainAchievementAutoOpenChapterId;
            if (string.IsNullOrWhiteSpace(pendingWorldChapterUnlockNoticeChapterName))
            {
                pendingWorldChapterUnlockNoticeChapterName = services.World.Chapters
                    .FirstOrDefault(value => value.Id == completedChapterId)?.Name ?? string.Empty;
            }
        }

        private void OnWorldBattleResultContinue()
        {
            if (battlePlaybackContext == BattlePlaybackContext.World
                && pendingWorldChapterUnlockNoticeChapterId != 0)
            {
                if (worldChapterUnlockNoticeCoroutine == null)
                    worldChapterUnlockNoticeCoroutine = StartCoroutine(ShowWorldChapterUnlockNotice());
                return;
            }

            ContinueBattleOutcomeControl();
        }

        private IEnumerator ShowWorldChapterUnlockNotice()
        {
            worldChapterUnlockNoticeView = worldChapterUnlockNoticeView
                ?? services.UiAssets.GetUnityOrCreate("WorldChapterUnlockNotice", GetDynamicUiRoot());
            if (worldChapterUnlockNoticeView == null)
            {
                Fail("World chapter-unlock Unity view was not found.");
                CompleteWorldChapterUnlockNoticeFallback();
                yield break;
            }

            Text chapterText = worldChapterUnlockNoticeView.FindNode("Panel/Text")?.GetComponent<Text>();
            Animator animator = worldChapterUnlockNoticeView.GameObject.GetComponent<Animator>();
            if (chapterText == null || animator == null)
            {
                Fail("World chapter-unlock Unity view is missing its text binding or native Animator.");
                CompleteWorldChapterUnlockNoticeFallback();
                yield break;
            }

            chapterText.text = $"第{pendingWorldChapterUnlockNoticeChapterId % 1000}章  "
                + pendingWorldChapterUnlockNoticeChapterName + "通关";
            worldChapterUnlockNoticeView.ShowPopup();
            services.UiStack.Push(worldChapterUnlockNoticeView, false);
            animator.Play("WorldChapterUnlockNotice", 0, 0f);

            // The native clip preserves the Cocos 2 second hold and 2 second fade.
            yield return new WaitForSecondsRealtime(4f);

            if (services?.UiStack?.Current == worldChapterUnlockNoticeView)
                services.UiStack.Pop();
            worldChapterUnlockNoticeView?.SetVisible(false);
            pendingWorldChapterUnlockNoticeChapterId = 0;
            pendingWorldChapterUnlockNoticeChapterName = string.Empty;
            worldChapterUnlockNoticeCoroutine = null;
            ContinueWorldChapterUnlockRoute();
        }

        private void CompleteWorldChapterUnlockNoticeFallback()
        {
            pendingWorldChapterUnlockNoticeChapterId = 0;
            pendingWorldChapterUnlockNoticeChapterName = string.Empty;
            worldChapterUnlockNoticeCoroutine = null;
            ContinueWorldChapterUnlockRoute();
        }

        private void ContinueWorldChapterUnlockRoute()
        {
            bool openAchievement = pendingWorldAchievementAutoOpen;
            pendingWorldAchievementAutoOpen = false;
            ContinueBattleOutcomeControl();
            if (openAchievement)
                StartCoroutine(ShowWorldAchievementAfterChapterUnlock());
        }

        private IEnumerator ShowWorldAchievementAfterChapterUnlock()
        {
            // Let Continue close the settlement overlay and restore the World
            // root before presenting the achievement popup on that root.
            yield return null;
            if (battlePlaybackContext != BattlePlaybackContext.World || !IsWorldOpen
                || worldView?.GameObject == null || !worldView.GameObject.activeInHierarchy)
                yield break;
            ShowWorldAchievement();
            SetStatus($"World chapter {MainAchievementAutoOpenChapterId} unlock continued into main achievement.");
        }
    }
}
