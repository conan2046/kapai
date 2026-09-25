using System;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BindFriendClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Friend"))
                {
                    mainView.Binding.Find(FriendPath)?.SetActive(false);
                    return;
                }
                Button button = mainView.BindClick(FriendPath, HandleFriendClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindChatClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Chat"))
                {
                    mainView.FindNode(ChatPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("ChatEntryRuntime")?.gameObject.SetActive(false);
                    chatMiniView?.SetVisible(false);
                    return;
                }
                Button button = mainView.FindNode(ChatPath) != null
                    ? mainView.BindClick(ChatPath, HandleChatClick, true)
                    : EnsureRuntimeChatEntry();
                MakeButtonVisualTransparent(button);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTeamClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Team"))
                {
                    mainView.FindNode(TeamLegacyPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("TeamEntryRuntime")?.gameObject.SetActive(false);
                    return;
                }
                Button button = EnsureRuntimeTeamEntry();
                MakeButtonVisualTransparent(button);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGuildClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Guild"))
                {
                    mainView.Binding.Find(GuildPath)?.SetActive(false);
                    return;
                }
                if (mainView.Binding.Find(GuildPath) == null)
                    return; // Legacy guild group removed from UImainLayer_new.
                Button button = mainView.BindClick(GuildPath, HandleGuildClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindWorldClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(WorldPath, HandleWorldClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }
    }
}
