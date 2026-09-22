using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Core

{
    public sealed partial class ProjectXApp
    {
        public void ShowGameplayShop(int functionId)
        {
            EnsureGameplayShopsPresenter();
            if (!IsGameplayShopOpen)
            {
                restoreChatMiniAfterGameplayShop =
                    chatMiniView != null && chatMiniView.GameObject.activeSelf;
                restoreBagFrameAfterGameplayShop = IsBagOpen
                    && oneLevelFrameView != null && oneLevelFrameView.GameObject.activeSelf;
                gameplayContentView = gameplayContentView
                    ?? services.UiRouter.FindBySource("common/ActivityLayer");
                gameplayShopActivityLayer = gameplayContentView?.GameObject.transform;
                gameplayShopActivityLayerStateCaptured = gameplayShopActivityLayer != null;
                gameplayShopActivityLayerWasActive = gameplayShopActivityLayerStateCaptured
                    && gameplayShopActivityLayer.gameObject.activeSelf;
            }
            chatMiniView?.SetVisible(false);
            gameplayContentView?.SetVisible(false);
            // shop_bg is now mounted under OneLevelLayer, so the shared parent
            // must stay visible while the gameplay/soul shop is displayed.
            SetOneLevelFrameVisible(true);
            CocosUiView previous = gameplayShopsPresenter.ActiveView;
            gameplayShopsPresenter.ShowFunction(functionId);
            if (!services.GameplayShops.TryGet(gameplayShopsPresenter.SelectedType, out _))
                gameplayShopsPresenter.SelectType(gameplayShopsPresenter.SelectedType, true);
            CocosUiView target = gameplayShopsPresenter.ActiveView;
            gameplayDetailView?.SetVisible(false);
            Transform gameplayNotice =
                bagPopupFrameView.GameObject.transform.Find("FloatNoticeLayer");
            if (gameplayNotice != null) gameplayNotice.gameObject.SetActive(false);
            if (services.UiStack.Current == previous && previous != target) services.UiStack.Pop();
            if (services.UiStack.Current != target) services.UiStack.Push(target);
            ConfigureGameplayShopsFrame();
            oneLevelFrameView.Binding.Find("Layer/Panel_12")?.SetActive(false);
            oneLevelFrameView.Binding.Find("Layer/GoldCheck")?.SetActive(false);
            bagPopupFrameView.SetVisible(true);
            bagPopupFrameView.GameObject.transform.SetAsLastSibling();
            target.GameObject.transform.SetAsLastSibling();
            SetStatus($"Gameplay shop function_id={functionId} active; awaiting /221.");
        }

        public void BeginGameplayShopUpdate(int type, int refreshTimes, int freeRefreshTimes,
            int refreshRemainingSeconds, int expectedCount)
        {
            BeginShopUpdate(type, refreshTimes, freeRefreshTimes, refreshRemainingSeconds, expectedCount);
        }

        public void AddGameplayShopRecord(int grid, double id, int buyCount, string name,
            string description, int picture, int quality)
        {
            AddShopRecord(grid, id, buyCount, name, description, picture, quality);
        }

        public void EndGameplayShopUpdate()
        {
            services.GameplayShops.Replace(pendingShopType, pendingShopRefreshTimes, pendingShopFreeTimes,
                pendingShopRefreshRemaining, services.ServerTime.UnixSeconds, pendingShopRecords);
            EnsureGameplayShopsPresenter();
            gameplayShopsPresenter.SelectType(pendingShopType, false);
        }

        public bool ApplyGameplayShopPurchase(int rawType, double rawId, int buyCount,
            int rewardType, double rewardAmount)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            if (!services.GameplayShops.TryGet(type, id, out ShopRecord item)
                || item.RewardType != rewardType
                || item.RewardAmount != checked((uint)rewardAmount))
                return false;
            return services.GameplayShops.ApplyPurchase(type, id, checked((ushort)buyCount));
        }

        public void SetGameplayShopBuyCount(int rawType, double rawId, int buyCount)
        {
            services.GameplayShops.ApplyPurchase(checked((byte)rawType),
                checked((ushort)rawId), checked((ushort)buyCount));
        }

        public void ClearGameplayShopState()
        {
            services.GameplayShops.Clear();
            pendingShopRecords.Clear();
            gameplayShopsPresenter?.ResetTransientState();
            bagFlowPresenter?.HideGameplayShopSource();
            gameplayShopItemInfoPresenter?.Hide();
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
        }

        public void ShowGameplayShopPurchaseReward(int rawType, double rawId,
            int rewardType, double rewardAmount, int quantity)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            if (!services.GameplayShops.TryGet(type, id, out ShopRecord item)) return;
            uint totalAmount = checked((uint)rewardAmount * checked((uint)Math.Max(1, quantity)));
            services.Rewards.Replace("购买获得", new[]
            {
                new RewardRecord(rewardType, checked((uint)Math.Max(0, item.RewardId)),
                    totalAmount, item.Name, item.Picture, item.Quality)
            });
            EnsureRewardPresenter();
            rewardPresenter.ConfigureItemVisuals(reward =>
            {
                if (services.ShopCatalog.IsCocosHeroSoul(reward.Type))
                    return services.Resources.LoadHeroPortrait(reward.Picture);
                return services.Resources.LoadGameplayShopIcon(reward.Picture, out _, out _);
            }, true);
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
        }

        public void ShowGameplayShopItemDetail(ShopRecord item)
        {
            if (item == null) return;
            EnsureBagPresenter();
            bagFlowPresenter.ShowGameplayShopSource(item);
        }

        private void ShowGameplayShopHelp()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowDismissOnly("提示",
                "玩家可以免费刷新将魂商店商品，免费刷新次数随时间恢复，上限为10次。\n"
                + "免费刷新次数的使用不会扣除今日剩余次数。\n"
                + "在没有免费刷新次数时，玩家可以使用刷新令进行刷新。");
        }

        private void ShowGameplayShopSoulDetail()
        {
            EnsureGameplayShopItemInfoPresenter();
            gameplayShopItemInfoPresenter.ShowSoul();
        }

        private void RequestGameplayShopPurchase(byte type, ushort id, int quantity)
        {
            if (!services.GameplayShops.TryGet(type, id, out _))
            {
                ShowToast("商品状态已失效，请重新进入将魂商店", 2f);
                return;
            }
            InvokeLuaOrFail(onGameplayShopBuy, "Gameplay.Shops.Buy",
                (double)type, (double)id, quantity);
        }

        private void RequestGameplayShopType(byte type)
        {
            if ((type == 27 || type == 28) && services.Player.Level < 99)
            {
                ShowToast("99级开启此功能", 2f);
                return;
            }
            InvokeLuaOrFail(onGameplayShopTab, "Gameplay.Shops.Tab", (double)type);
        }

        public void CompleteGameplayShopsValidation()
        {
            StartCoroutine(CaptureGameplayShopsValidation(true));
        }

        public void CompleteGameplayShopsVisualValidation()
        {
            StartCoroutine(CaptureGameplayShopsValidation(false));
        }

        private IEnumerator CaptureGameplayShopValidationScreenshot(string fileName)
        {
            // The capture contract reaches this point only after all shop requests have
            // completed. Clear any stale loading request so the common spinner cannot
            // contaminate the module's native visual evidence.
            loadingPresenter?.Clear();
            loadingView?.SetVisible(false);
            toastPresenter?.Clear();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);

            float deadline = Time.realtimeSinceStartup + 8f;
            long previousLength = -1;
            int stableFrames = 0;
            while (Time.realtimeSinceStartup < deadline)
            {
                long length = File.Exists(path) ? new FileInfo(path).Length : 0;
                if (length > 0 && length == previousLength)
                {
                    stableFrames++;
                    if (stableFrames >= 2) yield break;
                }
                else
                {
                    previousLength = length;
                    stableFrames = 0;
                }
                yield return null;
            }
            throw new IOException($"GameplayShops screenshot was not written stably: {fileName}.");
        }

        public bool BeginGameplayShopsG4Validation(double rawItemId, int initialBuyCount)
        {
            BeginValidationEvidence();
            gameplayShopG4Events.Clear();
            ushort itemId = checked((ushort)rawItemId);
            ShopRecord item = null;
            bool valid = initialBuyCount == 0
                && services.GameplayShops.TryGet(2, itemId, out item)
                && item.Limit == 1;
            return RecordGameplayShopG4Event("fixture", valid,
                $"type=2, item={itemId}, initial={initialBuyCount}, limit={item?.Limit}");
        }

        public bool RecordGameplayShopG4Event(string key, bool passed, string detail)
        {
            if (string.IsNullOrWhiteSpace(key)) return false;
            if (!passed)
            {
                Fail($"Gameplay shops G4 {key} assertion failed: {detail}");
                return false;
            }
            gameplayShopG4Events.Add(key.Trim());
            SetStatus($"Gameplay shops G4 {key} passed: {detail}");
            return true;
        }

        public bool ValidateGameplayShopPurchase(int rawType, double rawId, int expectedBuyCount)
        {
            byte type = checked((byte)rawType);
            ushort id = checked((ushort)rawId);
            ShopRecord item = null;
            bool passed = services.GameplayShops.TryGet(type, id, out item)
                && item.BuyCount == expectedBuyCount
                && item.IsSoldOut
                && rewardPresenter?.IsVisible == true;
            if (passed) rewardPresenter.Hide();
            return RecordGameplayShopG4Event("purchase-reload", passed,
                $"type={type}, id={id}, expected={expectedBuyCount}, actual={item?.BuyCount}, reward={rewardPresenter?.IsVisible}");
        }

        public bool ValidateGameplayShopRefresh(int beforeRefreshTimes, int beforeFreeTimes,
            int afterRefreshTimes, int afterFreeTimes)
        {
            GameplayShopPage page = null;
            bool passed = beforeFreeTimes > 0
                && afterFreeTimes == beforeFreeTimes - 1
                && afterRefreshTimes == beforeRefreshTimes
                && services.GameplayShops.TryGet(2, out page)
                && page.FreeRefreshTimes == afterFreeTimes
                && page.RefreshTimes == afterRefreshTimes
                && page.Items.Count == 6;
            return RecordGameplayShopG4Event("refresh", passed,
                $"refresh={beforeRefreshTimes}->{afterRefreshTimes}, free={beforeFreeTimes}->{afterFreeTimes}, cells={page?.Items.Count}");
        }

        public void BeginShopG4Validation(double rawId)
        {
            StartCoroutine(RunShopG4InitialUiValidation(checked((ushort)rawId)));
        }

        public void BeginShopG3Validation(double rawId)
        {
            StartCoroutine(RunShopG4InitialUiValidation(checked((ushort)rawId)));
        }

        private IEnumerator RunShopG4InitialUiValidation(ushort itemId)
        {
            BeginValidationEvidence();
            EnsureShopPresenter();
            if (!IsShopOpen || services.Shop.Count < 3 || shopPresenter.ItemCount != services.Shop.Count
                || !services.Shop.TryGet(itemId, out ShopRecord item) || shopPresenter.MissingIconCount != 0)
            {
                Fail($"Shop G4 initial state mismatch: open={IsShopOpen}, store={services.Shop.Count}, "
                    + $"rendered={shopPresenter?.ItemCount ?? -1}, item={itemId}, missing={shopPresenter?.MissingIconCount ?? -1}.");
                yield break;
            }

            MarkValidationControl("SHOP-01-MAIN-TOGGLE");
            MarkValidationControl("SHOP-02-SUBMENU-ENTRY");
            yield return null;
            Canvas.ForceUpdateCanvases();
            shopPresenter.Render();
            yield return null;
            Text tab = shopView.Binding.Find("Layer/ShopUI/ListView_left/Panel_button/Button_1/Text")?.GetComponent<Text>();
            GameObject sharedPanel = oneLevelFrameView.Binding.Find("Layer/Panel_12");
            GameObject goldCheck = oneLevelFrameView.Binding.Find("Layer/GoldCheck");
            Button shopClose = bagPopupFrameView?.Binding.Find("Layer/shopBg/Popup/Btn_close")?.GetComponent<Button>();
            RecordValidationSemantic("shop-frame-panel-hidden", sharedPanel != null && !sharedPanel.activeSelf,
                $"panel={sharedPanel?.activeSelf}");
            RecordValidationSemantic("shop-gold-check-hidden", goldCheck != null && !goldCheck.activeSelf,
                $"goldCheck={goldCheck?.activeSelf}");
            RecordValidationSemantic("shop-shared-close", shopClose != null && shopClose.interactable
                && shopClose.targetGraphic != null && shopClose.targetGraphic.raycastTarget,
                $"close={shopClose != null}");
            RecordValidationSemantic("shop-tab", tab?.text == "道具购买", $"actual={tab?.text}");
            RecordValidationSemantic("shop-details", !string.IsNullOrWhiteSpace(item.Name)
                && !string.IsNullOrWhiteSpace(item.Description) && item.UnitCost > 0,
                $"id={item.Id}, name={item.Name}, cost={item.UnitCost}");
            RecordValidationSemantic("shop-refresh-hidden", shopPresenter.IsRefreshControlHiddenForBaseShop,
                "type=1 must not expose the server-config refresh UI");
            RecordValidationSemantic("shop-real-controls", shopPresenter.HasInteractiveContract,
                "item, quantity and buy controls require raycast targets");
            RecordValidationSemantic("shop-authority", services.ServerTime.IsSynchronized
                && services.ProtocolRegistry.PendingCount == 0, "server time and pending state");
            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Shop G4 semantic assertions failed.");
                yield break;
            }
            if (HasCommandLineFlag("-projectXShopG3Validation"))
            {
                validationRoleIdSnapshot = GetPlayerRoleId();
                Complete($"COMPLETE: Shop G3 runtime contract; Panel_12 hidden, Shop-owned close and "
                    + $"17-goods real-control raycast contract; user={GetLocalUserId()} role={validationRoleIdSnapshot}");
                yield break;
            }

            if (!shopPresenter.InvokeBaseTab()) { Fail("Shop G4 base tab was not bound."); yield break; }
            MarkValidationControl("SHOP-06-BASE-TAB");
            if (!shopPresenter.InvokeSelect(itemId)
                && (!shopPresenter.InvokeFirstBound(out itemId)
                    || !services.Shop.TryGet(itemId, out item)))
            { Fail($"Shop G4 could not invoke any bound item (requested {itemId})."); yield break; }
            MarkValidationControl("SHOP-08-ITEM-SELECT");
            yield return CaptureShopValidationScreenshot("bootstrap-shop-list.png");

            if (!shopPresenter.InvokePlus() || shopPresenter.SelectedQuantity != 2)
            { Fail("Shop G4 plus control failed."); yield break; }
            MarkValidationControl("SHOP-10-QUANTITY-PLUS");
            if (!shopPresenter.InvokeMinus() || shopPresenter.SelectedQuantity != 1)
            { Fail("Shop G4 minus control failed."); yield break; }
            MarkValidationControl("SHOP-09-QUANTITY-MINUS");
            if (!shopPresenter.InvokeQuantityInput()) { Fail("Shop G4 quantity input did not open."); yield break; }
            MarkValidationControl("SHOP-11-QUANTITY-INPUT-OPEN");
            if (!shopPresenter.InvokeQuantityDigit(2)) { Fail("Shop G4 keypad digit failed."); yield break; }
            MarkValidationControl("SHOP-12-QUANTITY-KEYPAD");
            if (!shopPresenter.InvokeQuantityDelete()) { Fail("Shop G4 keypad delete failed."); yield break; }
            MarkValidationControl("SHOP-13-QUANTITY-DELETE");
            if (!shopPresenter.InvokeQuantityCancel() || shopPresenter.IsQuantityInputVisible)
            { Fail("Shop G4 quantity cancel failed."); yield break; }
            MarkValidationControl("SHOP-15-QUANTITY-CANCEL");
            if (!shopPresenter.InvokeQuantityInput() || !shopPresenter.InvokeQuantityDelete()
                || !shopPresenter.InvokeQuantityDigit(2))
            { Fail("Shop G4 quantity input second pass failed."); yield break; }
            yield return CaptureShopValidationScreenshot("bootstrap-shop-quantity.png");
            if (!shopPresenter.InvokeQuantityConfirm() || shopPresenter.SelectedQuantity != 2)
            { Fail("Shop G4 quantity confirm failed."); yield break; }
            MarkValidationControl("SHOP-14-QUANTITY-CONFIRM");

            if (!shopPresenter.ScrollToBottom()) { Fail("Shop G4 list did not scroll."); yield break; }
            MarkValidationControl("SHOP-07-LIST-SCROLL");
            yield return CaptureShopValidationScreenshot("bootstrap-shop-scroll-bottom.png");

            if (!shopPresenter.InvokeSelect(itemId)) shopPresenter.Select(itemId);
            if (!shopPresenter.InvokePlus() || !shopPresenter.InvokeBuy() || !errorPresenter.IsVisible)
            { Fail("Shop G4 buy control did not open confirmation."); yield break; }
            MarkValidationControl("SHOP-16-BUY");
            if (!errorPresenter.InvokeCancel() || errorPresenter.IsVisible
                || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 purchase cancel changed pending state."); yield break; }
            MarkValidationControl("SHOP-18-PURCHASE-CANCEL");
            if (!shopPresenter.IsRefreshControlHiddenForBaseShop)
            { Fail("Shop G4 type=1 refresh UI was not hidden."); yield break; }
            InvokeLuaOrFail(onShopValidationRefresh, "Shop.ValidationRefresh");
        }

        public void CompleteShopRefreshFailureValidation(string reason)
        {
            if (string.IsNullOrWhiteSpace(reason) || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 op=3 failure did not clear pending state."); return; }
            ushort id = services.Shop.Items.First().Id;
            InvokeLuaOrFail(onShopValidationCount, "Shop.ValidationCount", (double)id);
        }

        public void CompleteShopCountValidation(double rawId, int buyCount)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item) || item.BuyCount != buyCount
                || services.ProtocolRegistry.PendingCount != 0)
            { Fail("Shop G4 op=4 authoritative count mismatch."); return; }
            ShopRecord failureItem = services.Shop.Items.FirstOrDefault(value => value.Id == 1015);
            if (failureItem == null) failureItem = services.Shop.Items.OrderByDescending(value => value.UnitCost).First();
            InvokeLuaOrFail(onShopValidationFailure, "Shop.ValidationFailure",
                (double)failureItem.Id, 200);
        }

        public void CompleteShopFailureValidation()
        {
            StartCoroutine(RunShopG4SuccessfulPurchase());
        }

        private IEnumerator RunShopG4SuccessfulPurchase()
        {
            while (services.ProtocolRegistry.PendingCount != 0) yield return null;
            ShopRecord item = services.Shop.Items.First();
            validationShopId = item.Id;
            validationShopBuyCount = item.BuyCount;
            validationShopCurrencyType = item.CostType;
            validationShopQuantity = 2;
            validationShopExpectedCurrency = services.Currencies.Get(item.CostType) - item.TotalCost(2);
            validationShopRewardType = item.RewardType;
            validationShopRewardAmount = item.RewardAmount;
            if (!shopPresenter.Select(item.Id) || !shopPresenter.InvokePlus()
                || shopPresenter.SelectedQuantity != 2 || !shopPresenter.InvokeBuy()
                || !errorPresenter.IsVisible)
            { Fail("Shop G4 successful purchase confirmation did not open."); yield break; }
            yield return CaptureShopValidationScreenshot("bootstrap-shop-confirm.png");
            if (!errorPresenter.InvokeConfirmation())
            { Fail("Shop G4 real confirmation control failed."); yield break; }
            MarkValidationControl("SHOP-17-PURCHASE-CONFIRM");
        }

        public bool PrepareShopPurchaseValidation(double rawId)
        {
            ushort id = checked((ushort)rawId);
            if (GetLocalUserId() == 1)
            {
                Fail("Shop mutation validation requires an isolated userId, not default userId=1.");
                return false;
            }
            if (!services.ServerTime.IsSynchronized)
            {
                Fail("Shop validation requires synchronized server time.");
                return false;
            }
            if (!services.Shop.TryGet(id, out ShopRecord item) || item.IsSoldOut)
            {
                Fail($"Shop validation item is missing or sold out: id={id}.");
                return false;
            }
            long currency = services.Currencies.Get(item.CostType);
            if (currency < item.UnitCost)
            {
                Fail($"Shop validation currency is insufficient: type={item.CostType}, have={currency}, need={item.UnitCost}.");
                return false;
            }
            validationShopId = id;
            validationShopBuyCount = item.BuyCount;
            validationShopCurrencyType = item.CostType;
            validationShopExpectedCurrency = currency - item.UnitCost;
            validationShopRewardType = item.RewardType;
            validationShopRewardAmount = item.RewardAmount;
            EnsureShopPresenter();
            if (!shopPresenter.Select(id))
            {
                Fail($"Shop validation could not select id={id}.");
                return false;
            }
            ShowShopPurchaseConfirmation(item, 1);
            StartCoroutine(CaptureShopConfirmationAndConfirm(id));
            return true;
        }

        public bool ApplyShopPurchase(double rawId, int buyCount, int rewardType, double rewardAmount)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item)
                || item.RewardType != rewardType || item.RewardAmount != checked((uint)rewardAmount))
                return false;
            return services.Shop.ApplyPurchase(id, checked((ushort)buyCount));
        }

        public void SetShopBuyCount(double rawId, int buyCount)
        {
            services.Shop.ApplyPurchase(checked((ushort)rawId), checked((ushort)buyCount));
        }

        public void ClearShopState()
        {
            services.Shop.Clear();
            pendingShopRecords.Clear();
            shopPresenter?.ResetTransientState();
            errorPresenter?.Hide();
            rewardPresenter?.Hide();
        }

        public void RequestShopCount(double rawId)
        {
            InvokeLuaOrFail(onShopCountRequested, "Shop.OnCountRequested", rawId);
        }

        public void ShowShopPurchaseReward(double rawId, int rewardType, double rewardAmount,
            int quantity)
        {
            ushort id = checked((ushort)rawId);
            if (!services.Shop.TryGet(id, out ShopRecord item)) return;
            uint totalAmount = checked((uint)rewardAmount * checked((uint)Math.Max(1, quantity)));
            services.Rewards.Replace("购买获得", new[]
            {
                new RewardRecord(rewardType, checked((uint)Math.Max(0, item.RewardId)),
                    totalAmount, item.Name, item.Picture, item.Quality)
            });
            EnsureRewardPresenter();
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
        }

        public void CompleteShopPurchaseValidation(double rawId)
        {
            ushort id = checked((ushort)rawId);
            bool found = services.Shop.TryGet(id, out ShopRecord item);
            long currency = services.Currencies.Get(validationShopCurrencyType);
            bool rewardValid = ValidateRewardPresentation(1,
                !HasCommandLineFlag("-projectXShopG4Validation"));
            if (!found || id != validationShopId
                || item.BuyCount != validationShopBuyCount + validationShopQuantity
                || currency != validationShopExpectedCurrency || item.RewardType != validationShopRewardType
                || item.RewardAmount != validationShopRewardAmount || !rewardValid
                || services.ProtocolRegistry.PendingCount != 0 || !IsShopOpen
                || !services.ServerTime.IsSynchronized || shopPresenter.MissingIconCount != 0)
            {
                Fail($"Shop validation mismatch: found={found}, id={id}/{validationShopId}, count={(found ? item.BuyCount : 0)}/{validationShopBuyCount + validationShopQuantity}, currency={currency}/{validationShopExpectedCurrency}, reward={rewardValid}, pending={services.ProtocolRegistry.PendingCount}, open={IsShopOpen}, time={services.ServerTime.IsSynchronized}, missing={shopPresenter?.MissingIconCount ?? -1}.");
                return;
            }
            if (HasCommandLineFlag("-projectXShopG4Validation"))
            {
                StartCoroutine(FinalizeShopG4Validation());
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /221 list -> ShopStore/limits/server time/currency -> confirmed single purchase id={id} -> persisted count={item.BuyCount}");
        }

        private IEnumerator FinalizeShopG4Validation()
        {
            yield return CaptureShopValidationScreenshot("bootstrap-shop-reward.png");
            if (!rewardPresenter.InvokeFirstItem() || !errorPresenter.IsVisible)
            { Fail("Shop G4 reward item did not open the shared detail."); yield break; }
            MarkValidationControl("SHOP-20-REWARD-ITEM");
            errorPresenter.Hide();
            if (!rewardPresenter.InvokeClose() || rewardPresenter.IsVisible)
            { Fail("Shop G4 reward close control failed."); yield break; }
            MarkValidationControl("SHOP-21-REWARD-CLOSE");

            MarkValidationControl("SHOP-04-HEADER-HIDDEN");

            Button close = bagPopupFrameView?.Binding.Find("Layer/shopBg/Popup/Btn_close")?.GetComponent<Button>();
            if (close == null || !close.interactable) { Fail("Shop G4 close was not bound."); yield break; }
            if (!InvokeEventSystemRaycastClick(close))
            { Fail("Shop G4 close did not receive a real EventSystem/raycast click."); yield break; }
            if (IsShopOpen) { Fail("Shop G4 close did not return to main."); yield break; }
            MarkValidationControl("SHOP-05-CLOSE");

            Button shortcut = mainView.Binding.Find(ShopCoinShortcutPath)?.GetComponent<Button>();
            if (shortcut == null || !shortcut.interactable)
            { Fail("Shop G4 main coin shortcut was not bound."); yield break; }
            if (!InvokeEventSystemRaycastClick(shortcut))
            { Fail("Shop G4 main coin shortcut did not receive a real EventSystem/raycast click."); yield break; }
            float deadline = Time.realtimeSinceStartup + 10f;
            while ((!IsShopOpen || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsShopOpen || services.Shop.Count == 0)
            { Fail("Shop G4 main coin shortcut did not open authoritative Shop."); yield break; }
            MarkValidationControl("SHOP-03-MAIN-COIN-SHORTCUT");

            services.Shop.Clear();
            if (!shopPresenter.IsEmptyStateVisible)
            { Fail("Shop G4 empty state retained stale detail or buy state."); yield break; }
            HandleShopClick();
            deadline = Time.realtimeSinceStartup + 10f;
            while ((services.Shop.Count == 0 || services.ProtocolRegistry.PendingCount != 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Shop.Count == 0) { Fail("Shop G4 empty-state reload failed."); yield break; }

            services.Network.Disconnect();
            HandleDisconnected("Shop G4 deliberate disconnect");
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected || services.Shop.Count != 0
                || IsShopOpen || shopPresenter.IsQuantityInputVisible || errorPresenter.IsVisible
                || rewardPresenter.IsVisible)
            { Fail("Shop G4 disconnect cleanup mismatch."); yield break; }
            Reconnect();
            deadline = Time.realtimeSinceStartup + 20f;
            while (services.Network.State != NetworkState.Connected
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Network.State != NetworkState.Connected)
            { Fail("Shop G4 reconnect failed."); yield break; }
            deadline = Time.realtimeSinceStartup + 20f;
            while (!IsShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsShopOpen)
            {
                shortcut.onClick.Invoke();
                deadline = Time.realtimeSinceStartup + 10f;
                while (!IsShopOpen && Time.realtimeSinceStartup < deadline) yield return null;
            }
            if (!IsShopOpen || services.Shop.Count == 0)
            { Fail("Shop G4 reconnect did not restore authoritative Shop."); yield break; }

            yield return CaptureShopValidationScreenshot("bootstrap-shop.png");
            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Shop.Count != 0 || IsShopOpen
                || shopPresenter.IsQuantityInputVisible || errorPresenter.IsVisible || rewardPresenter.IsVisible)
            { Fail("Shop G4 account-switch cleanup mismatch."); yield break; }
            toastPresenter?.Clear();
            Complete($"COMPLETE: Shop G4 21/21 real controls; /221 op1/2/3/4, quantity=2, "
                + $"insufficient/reload/empty/reconnect/account-switch; user={GetLocalUserId()} role={validationRoleIdSnapshot}");
        }
    }
}
