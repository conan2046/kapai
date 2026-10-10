using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private bool equipmentRedDotsSubscribed;
        private uint equipmentDotPendingUid;
        private int equipmentDotPendingKind;
        private int equipmentDotPendingFragment;
        private void InitializeEquipmentRedDots()
        {
            redDots.Define("equipment");
            redDots.Define("equipment.gear", "equipment");
            redDots.Define("equipment.fabao", "equipment");
            redDots.Define("equipment.fragments", "equipment");
            foreach (string key in new[] { "strength", "refine", "awaken", "divine" }) redDots.Define("equipment.gear." + key, "equipment.gear");
            foreach (string key in new[] { "strength", "refine" }) redDots.Define("equipment.fabao." + key, "equipment.fabao");
            services.HeroEquipment.Changed += RefreshEquipmentRedDots;
            services.FaBao.Changed += RefreshEquipmentRedDots;
            services.Bag.Changed += RefreshEquipmentRedDots;
            services.Currencies.Changed += RefreshEquipmentRedDots;
            services.Player.Changed += RefreshEquipmentRedDots;
            equipmentRedDotsSubscribed = true;
            RefreshEquipmentRedDots();
        }
        private bool CanCultivateEquipment(uint uid, HeroEquipmentKind kind, int mode)
        {
            bool pending = equipmentDotPendingUid == uid && equipmentDotPendingKind == (int)kind;
            if (kind == HeroEquipmentKind.Equipment) return services.HeroEquipment.TryGet(uid, out HeroEquipmentRecord item)
                && EquipmentRedDotEligibility.Equipment(item, mode, services.Player.Level, services.EquipmentCatalog,
                    services.Bag, services.Currencies, services.HeroEquipment.HasAuthoritativeState, pending);
            return services.FaBao.TryGet(uid, out FaBaoRecord fabao) && EquipmentRedDotEligibility.FaBao(fabao, mode,
                services.Player.Level, services.EquipmentCatalog, services.FaBao, services.Bag, services.Currencies,
                services.FaBao.HasAuthoritativeState, pending);
        }
        private bool CanComposeEquipmentFragment(BagItemRecord item) => services.EquipmentCatalog.IsEquipmentFragment(item.ItemId)
            && equipmentDotPendingFragment != item.ItemId && services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId) > 0
            && services.Bag.GetTotalQuantityByItemId(item.ItemId) >= services.EquipmentCatalog.GetEquipmentComposeCost(item.ItemId);
        public void SetEquipmentRedDotPending(uint uid, int kind, bool pending)
        {
            equipmentDotPendingUid = pending ? uid : 0; equipmentDotPendingKind = pending ? kind : 0;
            RefreshEquipmentRedDots();
        }
        public void SetEquipmentFragmentPending(int itemId, bool pending)
        {
            equipmentDotPendingFragment = pending ? itemId : 0; RefreshEquipmentRedDots();
        }
        private void RefreshEquipmentRedDots()
        {
            if (!equipmentRedDotsSubscribed) return;
            redDots.SetEnabled("equipment", services.Player.Level >= FunctionUnlockCatalog.Resolve(1110).OpenLevel);
            string[] modes = { "strength", "refine", "awaken", "divine" };
            for (int mode = 0; mode < 4; mode++)
            {
                int captured = mode;
                redDots.Set("equipment.gear." + modes[mode], services.HeroEquipment.Items.Any(x => CanCultivateEquipment(x.Uid, HeroEquipmentKind.Equipment, captured)));
                if (mode < 2) redDots.Set("equipment.fabao." + modes[mode], services.FaBao.Items.Any(x => CanCultivateEquipment(x.Uid, HeroEquipmentKind.FaBao, captured)));
            }
            redDots.Set("equipment.fragments", services.Bag.GetItemsByType(7).Any(CanComposeEquipmentFragment));
            RedDotVisual.Set(FindMainHudNode(EquipmentMenuPath)?.transform, redDots.IsVisible("equipment"), RedDotTemplate);
            ApplyEquipmentHubDots();
            heroEquipmentPresenter?.ApplyRedDots();
        }
        private void ApplyEquipmentHubDots()
        {
            if (heroEquipmentListView?.GameObject.activeInHierarchy != true && heroEquipmentFragmentView?.GameObject.activeInHierarchy != true) return;
            Transform panel = oneLevelFrameView?.FindNode("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            string[] names = { "Button1", "Button2_Runtime", "Button3_Runtime" };
            string[] keys = { "equipment.gear", "equipment.fabao", "equipment.fragments" };
            for (int i = 0; i < 3; i++) RedDotVisual.Set(panel?.Find(names[i]), redDots.IsVisible(keys[i]), RedDotTemplate);
        }
        private void DisposeEquipmentRedDots()
        {
            if (!equipmentRedDotsSubscribed) return;
            services.HeroEquipment.Changed -= RefreshEquipmentRedDots; services.FaBao.Changed -= RefreshEquipmentRedDots;
            services.Bag.Changed -= RefreshEquipmentRedDots; services.Currencies.Changed -= RefreshEquipmentRedDots;
            services.Player.Changed -= RefreshEquipmentRedDots; equipmentRedDotsSubscribed = false;
            equipmentDotPendingUid = 0; equipmentDotPendingKind = 0; equipmentDotPendingFragment = 0;
        }
    }
}
