using System;
using ProjectX.Data;
using ProjectX.Gameplay;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private void SetMainHudSurfaceVisible(bool visible)
        {
            mainView?.FindNode("Layer/Main_UI")?.SetActive(visible);
            if (!visible)
            {
                mainView?.FindNode("Layer/Bg")?.SetActive(true);
                mainCloudView?.SetVisible(true);
            }
        }

        public void EnterGameplay(int functionId)
        {
            GameplayRouteDecision decision = GameplayRoutePlanner.Resolve(
                services.GameplayCatalog, functionId, services.Player.Level,
                HasCommandLineFlag("-projectXGameplayValidation"));
            GameplayDefinition definition = decision.Definition;
            if (decision.Status == GameplayRouteDecisionStatus.MissingDefinition)
            { Fail($"Gameplay route config is missing id={functionId}."); return; }
            if (decision.Status == GameplayRouteDecisionStatus.LockedByLevel)
            {
                ShowToast($"{definition.OpenLevel}级开启", 2f);
                return;
            }
            if (decision.Status == GameplayRouteDecisionStatus.ValidationBoundary)
            {
                int pendingBefore = services.ProtocolRegistry.PendingCount;
                lastGameplayBoundaryId = functionId;
                HandleBack();
                // A server announcement may already occupy the shared toast queue. The route
                // boundary is the state under test, so make that feedback immediately visible.
                toastPresenter?.Clear();
                ShowToast($"{definition.Name}属于{GameplayRouteOwner(decision.Route)}；本轮仅验证路由边界。", 3f);
                SetStatus($"Gameplay route boundary: id={functionId}, name={definition.Name}, pending={pendingBefore}->{services.ProtocolRegistry.PendingCount}.");
                return;
            }
            gameplayPresenter?.HideDetail();
            FunctionRouteDefinition route = decision.Route;
            switch (route.Target)
            {
                case "Task": InvokeLuaOrFail(onTaskClicked, "Gameplay.DailyTask"); return;
                case "YouLi": InvokeLuaOrFail(onYouLiClicked, "Gameplay.YouLi"); return;
                case "FengShenStory": InvokeLuaOrFail(onFengShenStoryClicked, "Gameplay.FengShenStory"); return;
                case "Arena": InvokeLuaOrFail(onArenaClicked, "Gameplay.Arena"); return;
                case "XunBao": InvokeLuaOrFail(onXunBaoClicked, "Gameplay.XunBao"); return;
                case "MoneyTree": InvokeLuaOrFail(onMoneyTreeClicked, "Gameplay.MoneyTree", (double)functionId); return;
                case "Fish": InvokeLuaOrFail(onFishClicked, "Gameplay.Fish", (double)functionId); return;
                case "Answer": InvokeLuaOrFail(onAnswerClicked, "Gameplay.Answer", (double)functionId); return;
                case "Monopoly": InvokeLuaOrFail(onMonopolyClicked, "Gameplay.Monopoly", (double)functionId); return;
                case "HappyWheel": InvokeLuaOrFail(onHappyWheelClicked, "Gameplay.HappyWheel", (double)functionId); return;
                case "GameplayShop": HandleCommerceRoute(functionId); return;
                case "ImportedPrefab": OpenConfiguredGameplayPrefab(definition, route); return;
                default:
                    Fail($"Gameplay route target is missing: id={functionId}, target={route.Target}.");
                    return;
            }
        }

        private static string GameplayRouteOwner(FunctionRouteDefinition route)
        {
            return string.IsNullOrWhiteSpace(route.Target) ? route.Kind.ToString() : route.Target;
        }

        private void OpenConfiguredGameplayPrefab(GameplayDefinition definition, FunctionRouteDefinition route)
        {
            if (string.IsNullOrWhiteSpace(route.PrefabKey))
            {
                Fail($"Configured Gameplay prefab is missing: id={definition.Id}.");
                return;
            }
            Transform parent = string.Equals(route.Presentation, "gameplay-frame", StringComparison.OrdinalIgnoreCase)
                ? gameplayView.GameObject.transform : GetDynamicUiRoot();
            if (!configuredGameplayViews.TryGetValue(route.PrefabKey, out CocosUiView view) || view?.GameObject == null)
            {
                view = UiPrefabLoader.Load(route.PrefabKey, parent);
                configuredGameplayViews[route.PrefabKey] = view;
                if (!string.IsNullOrWhiteSpace(route.ClosePath))
                    view.BindClick(route.ClosePath, () => HandleBack(), true);
            }
            if (string.Equals(route.Presentation, "gameplay-frame", StringComparison.OrdinalIgnoreCase))
                gameplayContentView?.SetVisible(false);
            if (services.UiStack.Current != view)
                services.UiStack.Push(view, !string.Equals(route.Presentation, "gameplay-frame", StringComparison.OrdinalIgnoreCase));
            SetStatus($"Gameplay route active: id={definition.Id}, prefab={route.PrefabKey}.");
        }
    }
}
