using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core

{
    public sealed partial class ProjectXApp
    {
        private UnityUiView bagFlowPopupFrameView;

        private void EnsureBagPresenter()
        {
            bagView = bagView ?? services.UiAssets.GetUnityOrCreate("beibao", GetDynamicUiRoot());
            EnsureOneLevelFrame();
            bagFlowPopupFrameView = bagFlowPopupFrameView ?? services.UiAssets.GetUnityOrCreate("BagPopupFrame", GetDynamicUiRoot());
            bagFlowInputView = bagFlowInputView ?? services.UiAssets.GetUnityOrCreate("BagEnterNumLayer", GetDynamicUiRoot());
            bagGiftView = bagGiftView ?? services.UiAssets.GetUnityOrCreate("BagOpenBox", GetDynamicUiRoot());
            bagSourceView = bagSourceView ?? services.UiAssets.GetUnityOrCreate("BagItemSource", GetDynamicUiRoot());
            bagEquipmentInfoView = bagEquipmentInfoView ?? services.UiAssets.InstantiateUnity("HeroEquipmentDetail", GetDynamicUiRoot());
            if (bagView == null || oneLevelFrameView == null || bagFlowInputView == null || bagFlowPopupFrameView == null
                || bagGiftView == null || bagSourceView == null || bagEquipmentInfoView == null)
                throw new InvalidOperationException("Bag Unity view or a required Bag flow view was not found.");
            bagFlowPresenter = bagFlowPresenter ?? new BagFlowPresenter(
                bagFlowInputView, bagFlowPopupFrameView, bagGiftView, bagSourceView, bagEquipmentInfoView,
                services.Resources, services.EquipmentCatalog, services.ShopCatalog,
                services.Bag.GetTotalQuantityByItemId,
                (item, quantity, target) =>
                {
                    BeginBagUseRewardCapture(item);
                    InvokeLuaOrFail(onBagUseClicked, "Bag.OnUseClicked", item.Slot, quantity, target);
                },
                CloseBagForItemJump,
                HandleBagSourceRoute,
                CanOpenBagSource,
                message => ShowToast(message, 2f));
            bagPresenter = bagPresenter ?? new BagPresenter(bagView.GameObject, oneLevelFrameView.GameObject.transform,
                services.Bag, services.Resources,
                item =>
                {
                    bagFlowPresenter.ShowUseFlow(item);
                    gameplayContentView?.SetVisible(false);
                },
                () =>
                {
                    bagFlowPresenter.CloseAll();
                    SetOneLevelFrameVisible(false);
                    HandleBack();
                });
        }


        private void ConfigureBagFrame()
        {
            // OneLevelLayer is shared with Hero. Reapply its authoritative header
            // and visibility state on every Bag response so no previous module
            // title, hidden frame, tab or placeholder currency survives.
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            frame.Apply(OneLevelFrameMode.Standard);
            // Bag is a OneLevel child page. Keep it inside the shared frame;
            // otherwise its full-screen root becomes a Canvas sibling and draws
            // over the title, tabs and currency nodes even though they are active.
            frame.AttachContent(bagView, keepSiblingOrder: true);
            NormalizePlayerHubSurfaceOrder();
            UnityUiView binding = oneLevelFrameView;
            RectTransform root = binding.GameObject.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.FindNode("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "道具背包";
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform first = binding.FindNode("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            if (first != null)
            {
                SetTabText(first, "全部", true);
                // Bag has one visible category. Keep its selected artwork while
                // preserving the imported Button callback as a real no-op control.
                Button button = first.GetComponent<Button>();
                if (button != null) button.interactable = true;
            }
            Transform second = binding.FindNode("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            if (second != null) second.gameObject.SetActive(false);
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            foreach (Transform child in binding.GameObject.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }
        private void HandleBagClick()
        {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            if (HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl("BAG-01-MAIN-ENTRY");
#endif
            // The imported legacy main layer has an overlapping raycast region:
            // a click on btn_zhaomu can also reach the Bag listener. Prefer the
            // confirmed Draw rectangle so a recruitment entry never emits /8 as
            // a competing navigation action.
            GameObject drawEntry = mainView?.FindNode(DrawPath);
            RectTransform drawRect = drawEntry?.GetComponent<RectTransform>();
            if (drawRect != null && RectTransformUtility.RectangleContainsScreenPoint(drawRect, Input.mousePosition, null))
                return;
            InvokeLuaOrFail(onBagClicked, "Bag.OnBagClicked");
        }

        private static bool CanOpenBagSource(int functionId) => FunctionRouteCatalog.CanOpen(functionId);

        private void HandleBagSourceRoute(int functionId)
        {
            HandleConfiguredFunctionRoute(functionId, "Bag source");
        }

    }
}
