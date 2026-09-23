using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Core

{
    public sealed partial class ProjectXApp
    {
        private void ConfigureShopFrame()
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            CocosUiBinding binding = oneLevelFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            shopFramePanel = binding.Find("Layer/Panel_12");
            if (shopFramePanel == null)
                throw new InvalidOperationException("Shop shared frame panel was not found: OneLevelLayer/Layer/Panel_12.");
            if (!shopFramePanelStateCaptured)
            {
                shopFramePanelWasActive = shopFramePanel.activeSelf;
                shopFramePanelStateCaptured = true;
            }
            shopFramePanel.SetActive(false);

            shopGoldCheck = binding.Find("Layer/GoldCheck");
            if (shopGoldCheck != null)
            {
                if (!shopGoldCheckStateCaptured)
                {
                    shopGoldCheckWasActive = shopGoldCheck.activeSelf;
                    shopGoldCheckStateCaptured = true;
                }
                shopGoldCheck.SetActive(false);
            }
        }

        private void CloseShop()
        {
            shopHubOpen = false;
            shopPresenter?.ResetTransientState();
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
            bagPopupFrameView?.SetVisible(false);
            RestoreShopFramePanel();
            SetOneLevelFrameVisible(false);
            HandleBack();
        }

        private void RestoreShopFramePanel()
        {
            if (shopFramePanelStateCaptured && shopFramePanel != null)
                shopFramePanel.SetActive(shopFramePanelWasActive);
            if (shopGoldCheckStateCaptured && shopGoldCheck != null)
                shopGoldCheck.SetActive(shopGoldCheckWasActive);
            shopFramePanel = null;
            shopFramePanelStateCaptured = false;
            shopGoldCheck = null;
            shopGoldCheckStateCaptured = false;
        }

        private void EnsureGameplayShopsPresenter()
        {
            EnsureBagPresenter();
            soulShopView = soulShopView ?? services.UiRouter.FindBySource("shop/jianghunshop");
            multiShopView = multiShopView ?? services.UiRouter.FindBySource("shop/wanfashop");
            bagPopupFrameView = bagPopupFrameView ?? services.UiRouter.FindBySource("shop/shop_bg");
            if (soulShopView == null || multiShopView == null || bagPopupFrameView == null)
                throw new InvalidOperationException("GameplayShops Cocos bindings were not found.");
            NormalizeShopLayerOrder();
            gameplayShopsPresenter = gameplayShopsPresenter ?? new GameplayShopsPresenter(
                soulShopView, multiShopView, services.GameplayShops, services.Currencies,
                services.ShopCatalog, services.Bag, services.Resources, services.ServerTime,
                RequestGameplayShopType,
                RequestGameplayShopPurchase,
                () => InvokeLuaOrFail(onGameplayShopRefresh, "Gameplay.Shops.Refresh"),
                ShowGameplayShopItemDetail,
                ShowGameplayShopSoulDetail,
                message => ShowToast(message, 2f),
                CloseGameplayShops,
                () => services.Player.Level);
        }

        private void EnsureGameplayShopItemInfoPresenter()
        {
            gameplayShopItemInfoView = gameplayShopItemInfoView
                ?? services.UiRouter.FindBySource("common/SourceLayer");
            if (gameplayShopItemInfoView == null)
                throw new InvalidOperationException(
                    "GameplayShops imported CocosUiBinding was not found: common/SourceLayer.");
            gameplayShopItemInfoPresenter = gameplayShopItemInfoPresenter
                ?? new GameplayShopItemInfoPresenter(gameplayShopItemInfoView,
                    services.Resources, services.ShopCatalog, () =>
                    {
                        CloseGameplayShops();
                        EnsureDrawPresenter();
                        HandleDrawClick();
                    });
        }

        private void CloseGameplayShops()
        {
            shopHubOpen = false;
            bagFlowPresenter?.HideGameplayShopSource();
            gameplayShopItemInfoPresenter?.Hide();
            bagPopupFrameView?.SetVisible(false);
            // ActivityLayer is shared with the gameplay shell and may have been
            // active before the shop opened. It must not be restored as part of
            // closing the shop; otherwise the hidden activity page remains live
            // behind the next screen. OneLevelLayer is likewise hidden by
            // default and explicitly restored below only for a real Bag/Hero
            // parent flow.
            gameplayContentView?.SetVisible(false);
            gameplayShopActivityLayer?.gameObject.SetActive(false);
            SetOneLevelFrameVisible(false);
            services?.UiStack.Pop();
            if (restoreBagFrameAfterGameplayShop && IsBagOpen)
            {
                ConfigureBagFrame();
                SetOneLevelFrameVisible(true);
                oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
                bagView?.GameObject.transform.SetAsLastSibling();
            }
            if (restoreChatMiniAfterGameplayShop) chatMiniView?.SetVisible(true);
            if (restoreHeroEquipmentAfterGameplayShop)
            {
                SetOneLevelFrameVisible(true);
                heroEquipmentFragmentView?.SetVisible(true);
                oneLevelFrameView?.BindClick("Layer/Panel_12/Title/CloseBtn", () => HandleBack(), true);
                oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
                heroEquipmentFragmentView?.GameObject.transform.SetAsLastSibling();
            }
            restoreChatMiniAfterGameplayShop = false;
            restoreBagFrameAfterGameplayShop = false;
            restoreHeroEquipmentAfterGameplayShop = false;
            gameplayShopActivityLayer = null;
            gameplayShopActivityLayerWasActive = false;
            gameplayShopActivityLayerStateCaptured = false;
        }

        private void ConfigureShopHubTabs(ShopHubTab selected)
        {
            if (bagPopupFrameView == null) return;
            CocosUiBinding binding = bagPopupFrameView.Binding;
            Transform tabs = binding.Find("Layer/shopBg/Btn_ListView")?.transform;
            Transform template = tabs?.Find("Panel_1");
            Transform popup = binding.Find("Layer/shopBg/Popup")?.transform;
            Transform mask = binding.Find("Layer/shopBg/Mask")?.transform;
            Transform image = binding.Find("Layer/shopBg/Image")?.transform;
            if (tabs == null || template == null) return;

            tabs.gameObject.SetActive(true);
            if (selected == ShopHubTab.Shop)
            {
                // The shared shop frame stays open for the merged mall entry.
                // Only its mask/image remain hidden because shangcheng owns the
                // mall content surface.
                popup?.gameObject.SetActive(true);
                mask?.gameObject.SetActive(false);
                image?.gameObject.SetActive(false);
                bagPopupFrameView.BindClick("Layer/shopBg/Popup/Btn_close", CloseShop, true);
            }
            else
            {
                popup?.gameObject.SetActive(true);
                mask?.gameObject.SetActive(false);
                image?.gameObject.SetActive(false);
                Text title = binding.Find("Layer/shopBg/Popup/Title/Title")?.GetComponent<Text>();
                if (title != null) title.text = "将魂商店";
                bagPopupFrameView.BindClick("Layer/shopBg/Popup/Btn_close", CloseGameplayShops, true);
            }

            Transform secondPanel = tabs.Find("ShopHubPanel2_Runtime");
            if (secondPanel == null)
            {
                secondPanel = Instantiate(template.gameObject, tabs, false).transform;
                secondPanel.name = "ShopHubPanel2_Runtime";
            }
            RectTransform templateRect = template as RectTransform;
            RectTransform secondRect = secondPanel as RectTransform;
            if (templateRect != null && secondRect != null)
                secondRect.anchoredPosition = templateRect.anchoredPosition + new Vector2(0f, -100f);

            foreach (Transform child in tabs)
                if (child != template && child != secondPanel)
                    child.gameObject.SetActive(false);
            template.gameObject.SetActive(true);
            secondPanel.gameObject.SetActive(true);

            ConfigureShopHubTab(template.Find("Button"), "商城", selected == ShopHubTab.Shop,
                () => ShowShop());
            ConfigureShopHubTab(secondPanel.Find("Button"), "将魂商店", selected == ShopHubTab.Soul,
                ShowShopHubSoulTab);
        }

        private static void ConfigureShopHubTab(Transform tab, string label, bool selected, Action onClick)
        {
            if (tab == null) return;
            SetGameplayShopTabText(tab, label, selected);
            Button button = tab.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = !selected;
            if (!selected && onClick != null) button.onClick.AddListener(() => onClick());
        }

        private void ConfigureGameplayShopsFrame()
        {
            CocosUiBinding binding = bagPopupFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = Vector2.zero;
                root.anchorMin = root.anchorMax = Vector2.zero;
                root.anchoredPosition = Vector2.zero;
                root.sizeDelta = new Vector2(1334f, 750f);
                root.localScale = Vector3.one;
                root.localRotation = Quaternion.identity;
            }
            Transform activityLayer = binding.transform.Find("ActivityLayer");
            if (activityLayer != null) activityLayer.gameObject.SetActive(false);
            Text title = binding.Find("Layer/shopBg/Popup/Title/Title")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = gameplayShopsPresenter.SelectedType == 2 ? "将魂商店" : "玩法商店";
                title.alignment = TextAnchor.MiddleCenter;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            Transform help = title?.transform.Find("Button_1");
            if (help != null)
            {
                help.gameObject.SetActive(gameplayShopsPresenter.SelectedType == 2);
                BindTaskFrameButton(help, ShowGameplayShopHelp, true);
            }
            Transform tabs = binding.Find("Layer/shopBg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(gameplayShopsPresenter.SelectedType != 2);
            Transform template = tabs?.Find("Panel_1");
            var buttons = new List<Button>();
            if (template != null)
            {
                string[] labels = { "竞技商店", "血战商店", "帮派商店", "昆仑商店", "转盘商店" };
                RectTransform templateRect = template as RectTransform;
                for (int index = 0; index < labels.Length; index++)
                {
                    Transform panel = index == 0 ? template : tabs.Find($"GameplayShopPanel{index + 1}");
                    if (panel == null)
                    {
                        panel = Instantiate(template.gameObject, tabs, false).transform;
                        panel.name = $"GameplayShopPanel{index + 1}";
                    }
                    if (panel is RectTransform panelRect && templateRect != null)
                        panelRect.anchoredPosition =
                            templateRect.anchoredPosition + new Vector2(0f, -100f * index);
                    panel.gameObject.SetActive(true);
                    Transform tab = panel.Find("Button");
                    SetGameplayShopTabText(tab, labels[index],
                        index == gameplayShopsPresenter.SelectedGroupIndex);
                    Button button = tab?.GetComponent<Button>();
                    if (button != null) buttons.Add(button);
                }
            }
            if (buttons.Count == 5) gameplayShopsPresenter.AttachFrameCategoryButtons(buttons);
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
            bagPopupFrameView.BindClick("Layer/shopBg/Popup/Btn_close", CloseGameplayShops, true);
        }

        private static void SetGameplayShopTabText(Transform tab, string value, bool selected)
        {
            if (tab == null) return;
            Text normal = tab.Find("BtnName")?.GetComponent<Text>();
            Text chosen = tab.Find("ChooseBg/BtnName")?.GetComponent<Text>();
            if (normal != null) normal.text = value;
            if (chosen != null) chosen.text = value;
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Transform prompt = tab.Find("Prompt");
            if (prompt != null) prompt.gameObject.SetActive(false);
            Image background = tab.GetComponent<Image>();
            if (background != null) background.color = Color.white;
            Button button = tab.GetComponent<Button>();
            if (button != null) button.interactable = !selected;
        }
    }
}
