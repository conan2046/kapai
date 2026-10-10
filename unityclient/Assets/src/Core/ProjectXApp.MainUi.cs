using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowMainUi()
        {
            mainView = services.UiRouter.FindByKey(UiPrefabKey.MainHud, true);
            if (mainView == null) { Fail("Unity Main HUD Prefab key was not found."); return; }
            mainCloudView = mainCloudView ?? services.UiAssets.GetUnityOrCreate("UImain_cloudLayer");
            Animator cloudAnimator = mainCloudView?.GameObject?.GetComponent<Animator>();
            if (cloudAnimator == null || cloudAnimator.runtimeAnimatorController == null)
            {
                Fail("Unity-native Main cloud Animator is missing.");
                return;
            }
            DestroyLoginEntryViews();
            if (singlePlayerTitleEnabled) DestroySinglePlayerChatViews();
            services.UiStack.SetRoot(mainView);
            if (mainCloudView != null)
            {
                mainCloudView.SetVisible(true);
                cloudAnimator.Play("CloudLoop", 0, 0f);
                cloudAnimator.Update(0f);
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
            RefreshPlayerRedDots();
            RefreshHeroRedDots();
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            if (HasCommandLineFlag("-projectXSteamHudExclusionAcceptance"))
                StartCoroutine(CaptureSteamHudExclusionAcceptance());
#endif
            EnsureMainTaskTracker();
            services.State.Change(AppState.Main, "Main UI shown");
            if (!IsSteamExcludedModule("KunLun"))
                InvokeLuaOrFail(onSharedGameplayHotPointRefresh, "Shared.GameplayHotPointRefresh");
            SetStatus("Main UI active.");
            RequestGameNotice();
            InvokeLuaOrFail(onMailBackgroundRefresh, "Mail.RedDotSnapshot");
            InvokeLuaOrFail(onBagRedDotRefresh, "Bag.RedDotSnapshot");
            InvokeLuaOrFail(onHeroRedDotRefresh, "Hero.RedDotSnapshot");
            InvokeLuaOrFail(onHeroBookRedDotRefresh, "HeroBook.RedDotSnapshot");
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

        private static void DestroyLoginEntryView(ref UnityUiView view)
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

    }
}
