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
        public int GetShopDisplayItemId(double id) =>
            services.ShopCatalog.GetDisplayItemId(checked((ushort)id));

        public void BeginShopUpdate(int type, int refreshTimes, int freeRefreshTimes,
            int refreshRemainingSeconds, int expectedCount)
        {
            pendingShopType = checked((byte)type);
            pendingShopRefreshTimes = checked((ushort)refreshTimes);
            pendingShopFreeTimes = checked((byte)freeRefreshTimes);
            pendingShopRefreshRemaining = checked((ushort)refreshRemainingSeconds);
            pendingShopRecords.Clear();
            if (expectedCount > pendingShopRecords.Capacity) pendingShopRecords.Capacity = expectedCount;
        }



        public void AddShopRecord(int grid, double id, int buyCount, string name,
            string description, int picture, int quality)
        {
            pendingShopRecords.Add(services.ShopCatalog.Build(checked((byte)grid), checked((ushort)id),
                checked((ushort)buyCount), name, description, picture, quality));
        }

        public void EndShopUpdate()
        {
            services.Shop.Replace(pendingShopType, pendingShopRefreshTimes, pendingShopFreeTimes,
                pendingShopRefreshRemaining, services.ServerTime.UnixSeconds, pendingShopRecords);
            if (IsShopOpen) EnsureShopPresenter();
        }

        private uint shopExpiryRequested;
        private bool shopSnapshotNeedsTime;
        public bool IsSoulShopReminderOpen() => FunctionRouteCatalog.CanOpen(15)
            && services.Player.Level >= FunctionUnlockCatalog.Resolve(15).OpenLevel;
        public void SetGameplayShopPending(int op) => services.GameplayShops.SetPending(op);
        private void InitializeShopRedDots()
        {
            redDots.Define("shop");
            redDots.Define("shop.soul.refresh", "shop");
            services.GameplayShops.Changed += RefreshShopRedDots;
        }
        private void RefreshShopRedDots()
        {
            redDots.SetEnabled("shop", IsSoulShopReminderOpen());
            redDots.Set("shop.soul.refresh", services.GameplayShops.HasFreeSoulRefresh);
            RedDotVisual.Set(FindMainHudNode(ShopPath)?.transform, redDots.IsVisible("shop"), RedDotTemplate);
            RedDotVisual.Set(bagPopupFrameView?.FindNode("Layer/shopBg/Btn_ListView/ShopHubPanel2_Runtime/Button")?.transform,
                redDots.IsVisible("shop.soul.refresh"), RedDotTemplate);
            gameplayShopsPresenter?.RefreshRedDots(redDots.IsVisible("shop.soul.refresh"), RedDotTemplate);
        }
        private void TickShopRedDots()
        {
            if (shopSnapshotNeedsTime && services.ServerTime.IsSynchronized && services.GameplayShops.PendingOp == 0)
            {
                shopSnapshotNeedsTime = false;
                using (var refresh = services.Lua.GetFunction("OnShopRedDotRefresh")) InvokeLuaOrFail(refresh, "Shop.TimeSynchronized");
            }
            if (services.GameplayShops.PendingOp == 0 && services.GameplayShops.TryGet(2, out var page)
                && page.FreeRefreshTimes == 0 && page.RefreshDeadlineUnix > 0
                && services.ServerTime.UnixSeconds >= page.RefreshDeadlineUnix && shopExpiryRequested != page.RefreshDeadlineUnix)
            {
                shopExpiryRequested = page.RefreshDeadlineUnix;
                using (var refresh = services.Lua.GetFunction("OnShopRedDotRefresh")) InvokeLuaOrFail(refresh, "Shop.FreeRefreshRecovery");
            }
            RefreshShopRedDots();
        }


    }
}

