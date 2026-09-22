using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public bool HandleBack()
        {
            if (oldMemoryPresenter?.IsVisible == true)
            {
                CloseOldMemoryMenu();
                return true;
            }
            // FengShenStory is mounted inside the shared OneLevelLayer, but its
            // close button belongs to the FengShen content view. Handle it
            // before the JingJie/Bag compatibility branch, otherwise that
            // branch can consume the close click while leaving the shared
            // frame visible and blocking the main UI.
            if (IsFengShenStoryOpen)
            {
                fengShenStoryPresenter?.CloseLevelPopup();
                fengShenStoryPresenter?.CloseModal();
                fengShenStoryView?.SetVisible(false);
                SetOneLevelFrameVisible(false);
                return PopUiStackWithHudRefresh();
            }
            if (TryHandleJingJieBack()) return true;
            if (heroHubOpen && formationPopupView?.GameObject.activeSelf == true)
            {
                CloseHeroHub();
                return true;
            }
            if (formationPopupView?.GameObject.activeSelf == true)
            {
                formationPopupView.SetVisible(false);
                return true;
            }
            if (heroItemSourceView?.GameObject.activeSelf == true)
            {
                heroItemSourceView.SetVisible(false);
                return true;
            }
            if (heroAttributesView?.GameObject.activeSelf == true)
            {
                heroAttributesView.SetVisible(false);
                return true;
            }
            if (heroReplacementView?.GameObject.activeSelf == true)
            {
                heroReplacementView.SetVisible(false);
                if (heroHubOpen)
                {
                    // Replacement is opened from the unified hero hub. The
                    // legacy list/detail restore path leaves Panel_10 in the
                    // replacement screen's stale state and loses the Hub
                    // tabs, so restore through the active Hub tab instead.
                    ShowHeroHubTab(heroHubTab);
                    return true;
                }
                heroListView?.SetVisible(true);
                heroDetailView?.SetVisible(true);
                heroBagView?.SetVisible(false);
                return true;
            }
            if (heroEnhanceMasterView?.GameObject.activeSelf == true)
            {
                heroEnhanceMasterView.SetVisible(false);
                gameplayView?.SetVisible(false);
                heroListView?.SetVisible(true);
                heroDetailView?.SetVisible(true);
                SetOneLevelFrameVisible(true);
                ConfigureHeroFrame(false);
                return true;
            }
            if (heroCultivationView?.GameObject.activeSelf == true)
            {
                RestoreHeroFormationView();
                return true;
            }
            if (heroFragmentBagActive && heroEquipmentFragmentView?.GameObject.activeSelf == true)
            {
                CloseHeroBagToMain();
                return true;
            }
            if (IsHeroEquipmentOpen)
            {
                if (IsHeroEquipmentSubpageVisible)
                {
                    RestoreHeroEquipmentBagView();
                    return true;
                }
                heroEquipmentPresenter?.HideDetails();
                heroEquipmentListView?.SetVisible(false);
                heroEquipmentFragmentView?.SetVisible(false);
                if (heroEquipmentOpenedFromHeroDetails)
                {
                    RestoreHeroAfterEquipmentSlot();
                    return true;
                }
                SetOneLevelFrameVisible(false);
                return PopUiStackWithHudRefresh();
            }
            // World remains active underneath the Hero overlay, so this return
            // case must precede the generic IsWorldOpen branch. Otherwise the
            // Hero close click hides World itself before popping the overlay.
            if (worldFormationReturnPending && IsHeroOpen)
            {
                bool worldFormationPopped = PopUiStackWithHudRefresh();
                if (worldFormationPopped)
                {
                    RestoreWorldAfterHeroFormation();
                }
                return worldFormationPopped;
            }
            // DadituuiLayer stays structurally active underneath the YouLi
            // overlay. Handle this route before IsWorldOpen, otherwise the
            // generic World branch hides the map children while popping YouLi.
            if (worldYouLiReturnPending && IsYouLiOpen)
            {
                bool worldYouLiPopped = PopUiStackWithHudRefresh();
                if (worldYouLiPopped)
                {
                    worldYouLiReturnPending = false;
                    worldPresenter?.ShowStages();
                    StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
                }
                return worldYouLiPopped;
            }
            // Monopoly can keep the World map objects active underneath its own
            // board during the return transition. Resolve the topmost Monopoly
            // owner before the generic World branch, otherwise Back hides World
            // presentation and leaves the Monopoly UiStack entry unpopped.
            if (TryHandleMonopolyBack()) return true;
            if (IsWorldOpen)
            {
                HideWorldBoxAward();
                worldAchievementView?.SetVisible(false);
                worldBattlePlaybackPresenter?.Hide();
                worldSweepView?.SetVisible(false);
                worldBattleResultView?.SetVisible(false);
                worldBattleStatisticsView?.SetVisible(false);
                worldDetailView?.SetVisible(false);
                worldStageView?.SetVisible(false);
                worldMapView?.SetVisible(false);
                worldView?.SetVisible(false);
                return PopUiStackWithHudRefresh();
            }
            if (IsShopOpen)
            {
                shopPresenter?.ResetTransientState();
                errorPresenter?.Hide();
                rewardPresenter?.Hide();
                RestoreShopFramePanel();
                SetOneLevelFrameVisible(false);
            }
            if (IsGameplayShopOpen)
            {
                CloseGameplayShops();
                return true;
            }
            if (TryHandleMoneyTreeBack()) return true;
            if (TryHandleFishBack()) return true;
            if (TryHandleHappyWheelBack()) return true;
            if (IsGameplayOpen)
            {
                // shop_bg and ActivityLayer are root-level siblings. Popping
                // only the frame leaves DynamicUi_ActivityLayer active and
                // blocks the main UI behind the closed gameplay screen.
                gameplayContentView?.SetVisible(false);
                gameplayDetailView?.SetVisible(false);
                gameplayView?.SetVisible(false);
                bool popped = PopUiStackWithHudRefresh();
                SetMainHudSurfaceVisible(true);
                return popped;
            }
            if (IsBagOpen)
            {
                bagFlowPresenter?.CloseAll();
                SetOneLevelFrameVisible(false);
            }
            if (IsSettingsOpen) SetOneLevelFrameVisible(false);
            bool restoreWorldFormation = worldFormationReturnPending && IsHeroOpen;
            bool stackPopped = PopUiStackWithHudRefresh();
            if (stackPopped && restoreWorldFormation)
            {
                RestoreWorldAfterHeroFormation();
            }
            return stackPopped;
        }

        private bool PopUiStackWithHudRefresh()
        {
            bool popped = services?.UiStack.Pop() ?? false;
            if (popped && services.UiStack.Current == mainView)
            {
                SetMainHudSurfaceVisible(true);
                mainHudPresenter?.RefreshAfterVisibilityRestore();
                Canvas.ForceUpdateCanvases();
            }
            else if (popped && services.UiStack.Current == gameplayView)
            {
                gameplayContentView?.SetVisible(true);
                gameplayDetailView?.SetVisible(false);
                Canvas.ForceUpdateCanvases();
            }
            return popped;
        }
    }
}
