using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowMainUi()
        {
            mainView = services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null) { Fail("UImainLayer CocosUiBinding was not found."); return; }
            mainCloudView = mainCloudView ?? services.UiRouter.FindBySource("UImain_cloudLayer", true);
            DestroyLoginEntryViews();
            DestroyBackupMainView();
            if (singlePlayerTitleEnabled) DestroySinglePlayerChatViews();
            services.UiStack.SetRoot(mainView);
            if (mainCloudView != null)
            {
                mainCloudView.SetVisible(true);
                CocosTimelinePlayer timeline = mainCloudView.GameObject.GetComponent<CocosTimelinePlayer>();
                if (timeline != null) timeline.GotoFrameAndPlay(0, true);
                NormalizeMainUiSiblingOrder();
            }
            HideHudSubmenus();
            chatView?.SetVisible(false);
            chatMiniView?.SetVisible(true);
            HideLoading("connect");
            HideLoading("reconnect");
            HideLoading("auto-reconnect");
            errorPresenter?.Hide();
            EnsureMainHudPresenter();
            BindPlayerHudControls();
            ApplySteamFeatureExclusions();
            ApplySteamHudFunctionUnlocks();
            if (HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
                StartCoroutine(CaptureSteamHudExclusionAcceptance());
            EnsureMainTaskTracker();
            services.State.Change(AppState.Main, "Main UI shown");
            if (!IsSteamExcludedModule("KunLun"))
                InvokeLuaOrFail(onSharedGameplayHotPointRefresh, "Shared.GameplayHotPointRefresh");
            SetStatus("Main UI active.");
        }

        private void DestroyLoginEntryViews()
        {
            loginPresenter?.Dispose();
            loginPresenter = null;
            DestroyLoginEntryView(ref roleCreateView);
            DestroyLoginEntryView(ref loginServerListView);
            DestroyLoginEntryView(ref loginView);
            DestroyLoginEntryView(ref loginBackgroundView);
        }

        private static void DestroyLoginEntryView(ref CocosUiView view)
        {
            GameObject target = view?.GameObject;
            view = null;
            if (target != null) UnityEngine.Object.Destroy(target);
        }

        private void NormalizeMainUiSiblingOrder()
        {
            Transform mainTransform = mainView?.GameObject?.transform;
            Transform cloudTransform = mainCloudView?.GameObject?.transform;
            Transform canvasRoot = mainTransform?.parent;
            if (mainTransform == null || cloudTransform == null || canvasRoot == null) return;

            if (cloudTransform.parent != canvasRoot)
                cloudTransform.SetParent(canvasRoot, false);
            mainTransform.SetSiblingIndex(0);
            cloudTransform.SetSiblingIndex(Mathf.Min(1, canvasRoot.childCount - 1));
        }

        private void DestroySinglePlayerChatViews()
        {
            chatPresenter?.Dispose();
            chatPresenter = null;
            DestroyLoginEntryView(ref chatView);
            DestroyLoginEntryView(ref chatMiniView);
        }

        private void DestroyBackupMainView()
        {
            CocosUiView backup = services.UiRouter.FindBySource("UImainLayer_backup");
            if (backup?.GameObject != null) UnityEngine.Object.Destroy(backup.GameObject);
        }
    }
}
