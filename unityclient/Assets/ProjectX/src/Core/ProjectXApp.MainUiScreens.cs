using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowFriend()
        {
            if (IsSteamExcludedModule("Friend")) { SetStatus("Friend is excluded from the Steam build."); return; }
            EnsureFriendPresenter();
            if (services.UiStack.Current != friendView) services.UiStack.Push(friendView);
            SetStatus($"Friend UI active: {services.Friends.FriendCount} friends, {services.Friends.ApplicationCount} applications.");
        }

        public void ShowChat()
        {
            if (IsSteamExcludedModule("Chat")) { SetStatus("Chat is excluded from the Steam build."); return; }
            EnsureChatPresenter();
            if (services.UiStack.Current != chatView) services.UiStack.Push(chatView);
            SetStatus($"Chat UI active: {services.Chat.Count} messages.");
        }

        public void ShowTeam()
        {
            if (IsSteamExcludedModule("Team")) { SetStatus("Team is excluded from the Steam build."); return; }
            EnsureTeamPresenter();
            if (services.UiStack.Current != teamView) services.UiStack.Push(teamView);
            SetStatus($"Team UI active: {services.Team.PlayerCount} players.");
        }

        public void ShowGuild()
        {
            if (IsSteamExcludedModule("Guild")) { SetStatus("Guild is excluded from the Steam build."); return; }
            EnsureGuildPresenter();
            if (services.UiStack.Current != guildView) services.UiStack.Push(guildView);
            SetStatus(services.Guild.HasGuild
                ? $"Guild UI active: {services.Guild.Info.Name}, {services.Guild.MemberCount} members."
                : $"Guild UI active: no guild, {services.Guild.Items.Count} guilds listed.");
        }

        public void ShowWorld()
        {
            EnsureWorldPresenter();
            bool battleActive = worldBattleInFlight
                || worldBattlePlaybackCoroutine != null
                || worldBattleRuntime.PendingResult;
            worldBattleBackgrounded = false;
            if (!battleActive) worldBattleInFlight = false;
            worldBattleForegroundRequested = false;
            worldFormationReturnPending = false;
            worldFormationReturnToDetail = false;
            worldFormationReturnToChapters = false;
            worldYouLiReturnPending = false;
            worldPresenter.ShowWorld();
            if (services.UiStack.Current != worldView) services.UiStack.Push(worldView);
            StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
            SetStatus($"World UI active: {services.World.ChapterCount} chapters, {services.World.StageCount} stages.");
        }

        public void ShowWelfare()
        {
            if (IsSteamExcludedModule("Welfare")) { SetStatus("Welfare is excluded from the Steam build."); return; }
            EnsureWelfarePresenter();
            welfarePresenter.SelectTab(0);
            if (services.UiStack.Current != welfareView) services.UiStack.Push(welfareView);
            SetStatus($"Welfare UI active: {services.Welfare.Signs.Count} sign rewards, {services.Welfare.Online.Count} online rewards.");
        }

        public void ShowActivity()
        {
            if (IsSteamExcludedModule("Activity")) { SetStatus("Activity is excluded from the Steam build."); return; }
            EnsureActivityPresenter();
            if (services.UiStack.Current != activityRootView) services.UiStack.Push(activityRootView);
            SetStatus($"Activity UI active: {services.Activity.Count} activities.");
        }

        public void ShowDraw()
        {
            EnsureDrawPresenter();
            if (services.UiStack.Current != drawView) services.UiStack.Push(drawView);
            SetStatus($"Draw UI active: {services.Draw.Count} pools.");
        }

        public void ShowGameplay()
        {
            services.Gameplay.Load(services.GameplayCatalog.Items, services.Player.Level);
            EnsureGameplayPresenter();
            // GameplayFramePrefab is now a Canvas-root sibling of ActivityLayer;
            // the shared Hero/Bag OneLevelLayer must stay hidden, including its
            // Panel_12, GoldCheck and any stale child page.
            SetOneLevelFrameVisible(false);
            // GameplayPresenter enables ActivityLayer when it is first
            // constructed. Reassert the gameplay surface on every entry so a
            // previous close cannot leave the hub content hidden.
            gameplayContentView?.SetVisible(true);
            gameplayDetailView?.SetVisible(false);
            // Native PopFirstClassBg hides Main_UI controls, but the full-screen
            // Layer/Bg scene remains underneath the modal frame. Keeping the whole
            // imported main view active preserves that background instead of exposing
            // the camera clear colour around shop_bg.
            SetMainHudSurfaceVisible(false);
            if (services.UiStack.Current != gameplayView) services.UiStack.Push(gameplayView, false);
            gameplayPresenter.ResetScrollToTop();
            SetStatus($"Gameplay current hub active: {services.Gameplay.Count} configured entries.");
        }
    }
}
