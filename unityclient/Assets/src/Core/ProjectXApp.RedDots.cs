using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const string PlayerDot = "player";
        private static readonly string[] PlayerTabDots =
            { "player.realm", "player.bag", "player.mail", "player.settings" };
        private readonly RedDotStore redDots = new RedDotStore();
        private bool playerRedDotsSubscribed;
        private LuaFunction onMailBackgroundRefresh;
        private LuaFunction onBagRedDotRefresh;

        private void InitializePlayerRedDots()
        {
            if (playerRedDotsSubscribed) return;
            redDots.Define(PlayerDot);
            foreach (string key in PlayerTabDots) redDots.Define(key, PlayerDot);
            redDots.Changed += RenderPlayerRedDots;
            services.Player.Changed += RefreshPlayerRedDots;
            services.Currencies.Changed += RefreshPlayerRedDots;
            services.Bag.Changed += RefreshPlayerRedDots;
            services.JingJie.Changed += RefreshPlayerRedDots;
            services.Mails.Changed += RefreshPlayerRedDots;
            playerRedDotsSubscribed = true;
            RefreshPlayerRedDots();
        }

        private void RefreshPlayerRedDots()
        {
            if (services == null || !playerRedDotsSubscribed) return;
            redDots.SetEnabled(PlayerDot, services.Player.Level >= FunctionUnlockCatalog.Resolve(22).OpenLevel);
            jingJieConfig = jingJieConfig ?? new JingJieConfigData();
            jingJieConfig.TryGet(services.JingJie.CurrentId + 1, out JingJieDefinition next);
            int material = next != null && next.MaterialId > 0
                ? services.Bag.GetTotalQuantityByItemId(next.MaterialId) : 0;
            redDots.SetEnabled(PlayerTabDots[0], services.Player.Level >= FunctionUnlockCatalog.Resolve(22).OpenLevel);
            redDots.Set(PlayerTabDots[0], JingJieUpgradeEligibility.Evaluate(services.JingJie, next,
                services.Player.Level, services.Player.Power, services.Currencies.Gold, material)
                == JingJieUpgradeBlock.None);
            redDots.Set(PlayerTabDots[2], services.Mails.HasUnreadPrompt);
            redDots.Set(PlayerTabDots[1], services.Bag.HasDirectlyUsableItems);
            RenderPlayerRedDots();
        }

        private Transform RedDotTemplate => FindMainHudNode(MailPath)?.transform.Find("Prompt")
            ?? FindMainHudNode(DrawPath)?.transform.Find("Prompt");

        private void RenderPlayerRedDots()
        {
            if (mainView?.GameObject == null) return;
            RedDotVisual.Set(FindMainHudNode(JingJiePath)?.transform, redDots.IsVisible(PlayerDot), RedDotTemplate);
            bool playerUnlocked = services.Player.Level >= FunctionUnlockCatalog.Resolve(1050).OpenLevel;
            RedDotVisual.Set(FindMainHudNode(MainCharacterPath)?.transform,
                playerUnlocked && redDots.IsVisible(PlayerDot), RedDotTemplate);
            RedDotVisual.Set(FindMainHudNode(MailPath)?.transform, redDots.IsVisible(PlayerTabDots[2]), RedDotTemplate);
            if (IsJingJieOpen) ApplyPlayerTabRedDots();
        }

        private void ApplyPlayerTabRedDots() => playerHubTabCoordinator?.SetRedDots(
            tab => redDots.IsVisible(PlayerTabDots[(int)tab]), RedDotTemplate);

        private void DisposePlayerRedDots()
        {
            if (!playerRedDotsSubscribed) return;
            services.Player.Changed -= RefreshPlayerRedDots;
            services.Currencies.Changed -= RefreshPlayerRedDots;
            services.Bag.Changed -= RefreshPlayerRedDots;
            services.JingJie.Changed -= RefreshPlayerRedDots;
            services.Mails.Changed -= RefreshPlayerRedDots;
            redDots.Changed -= RenderPlayerRedDots;
            playerRedDotsSubscribed = false;
            onMailBackgroundRefresh?.Dispose();
            onMailBackgroundRefresh = null;
            onBagRedDotRefresh?.Dispose();
            onBagRedDotRefresh = null;
        }
    }
}
