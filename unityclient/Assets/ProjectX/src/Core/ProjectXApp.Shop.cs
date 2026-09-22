using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
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
            EnsureShopPresenter();
            ShowShop();
        }


    }
}

