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
            loginView?.SetVisible(false);
            loginBackgroundView?.SetVisible(false);
            loginPresenter?.HideAll();
            services.UiStack.SetRoot(mainView);
            if (mainCloudView != null)
            {
                Transform background = mainView.Binding.Find("Layer/Main_UI/Bg")?.transform;
                if (background != null && mainCloudView.GameObject.transform.parent != background)
                    mainCloudView.GameObject.transform.SetParent(background, false);
                mainCloudView.SetVisible(true);
                CocosTimelinePlayer timeline = mainCloudView.GameObject.GetComponent<CocosTimelinePlayer>();
                if (timeline != null) timeline.GotoFrameAndPlay(0, true);
                mainCloudView.GameObject.transform.SetAsFirstSibling();
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
    }
}
