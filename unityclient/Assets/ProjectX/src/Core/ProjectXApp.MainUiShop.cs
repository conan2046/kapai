using System;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BindShopClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                GameObject shopNode = FindMainHudNode(ShopPath);
                if (shopNode == null) throw new InvalidOperationException($"UI node was not found: {ShopPath}");
                Button entry = mainView.BindClickNode(shopNode, HandleShopClick, true, ShopPath);
                mainView.BindClick(ShopCoinShortcutPath, HandleShopClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(entry));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowShop()
        {
            if (IsGameplayShopOpen && shopHubOpen)
                CloseGameplayShops();
            shopHubOpen = true;
            EnsureShopPresenter();
            EnsureGameplayShopsPresenter();
            bagView?.SetVisible(false);
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            heroCultivationView?.SetVisible(false);
            heroLevelUpView?.SetVisible(false);
            heroEnhanceMasterView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            heroItemSourceView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentDetailView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentCultivateView?.SetVisible(false);
            heroEquipmentStrengthView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            soulShopView?.SetVisible(false);
            multiShopView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            ConfigureShopFrame();
            NormalizeShopLayerOrder();
            if (services.UiStack.Current != shopView)
            {
                services.UiStack.Push(shopView);
            }
            bagPopupFrameView.SetVisible(true);
            ConfigureShopHubTabs(ShopHubTab.Shop);
            SetStatus($"Shop UI active: {services.Shop.Count} goods.");
        }

        private void NormalizeShopLayerOrder()
        {
            Transform oneLevel = oneLevelFrameView?.GameObject?.transform;
            Transform shopBackground = bagPopupFrameView?.GameObject?.transform;
            Transform shopContent = shopView?.GameObject?.transform;
            if (oneLevel == null || shopBackground == null)
                return;

            Transform parent = oneLevel.parent;
            if (parent == null || shopBackground.parent != parent)
                return;

            int firstIndex = Mathf.Min(oneLevel.GetSiblingIndex(),
                shopBackground.GetSiblingIndex());
            oneLevel.SetSiblingIndex(firstIndex);
            shopBackground.SetSiblingIndex(firstIndex + 1);
            if (shopContent != null && shopContent.parent == parent)
                shopContent.SetSiblingIndex(firstIndex + 2);
        }

        private void ShowShopHubSoulTab()
        {
            shopHubOpen = true;
            if (IsShopOpen)
            {
                shopPresenter?.ResetTransientState();
                RestoreShopFramePanel();
                shopView?.SetVisible(false);
                services.UiStack.Pop();
            }
            ShowGameplayShop(15);
            ConfigureShopHubTabs(ShopHubTab.Soul);
        }
    }
}
