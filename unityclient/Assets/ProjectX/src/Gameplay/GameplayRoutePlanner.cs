using ProjectX.Data;

namespace ProjectX.Gameplay
{
    public enum GameplayRouteDecisionStatus
    {
        MissingDefinition,
        LockedByLevel,
        ValidationBoundary,
        Dispatch,
    }

    public readonly struct GameplayRouteDecision
    {
        internal GameplayRouteDecision(GameplayRouteDecisionStatus status,
            GameplayDefinition definition, FunctionRouteDefinition route)
        {
            Status = status;
            Definition = definition;
            Route = route;
        }

        public GameplayRouteDecisionStatus Status { get; }
        public GameplayDefinition Definition { get; }
        public FunctionRouteDefinition Route { get; }
    }

    public static class GameplayRoutePlanner
    {
        public static GameplayRouteDecision Resolve(GameplayCatalog catalog, int functionId,
            int playerLevel, bool validationBoundary)
        {
            GameplayDefinition definition = catalog?.Find(functionId);
            if (definition == null)
                return new GameplayRouteDecision(GameplayRouteDecisionStatus.MissingDefinition,
                    null, default);

            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            if (playerLevel < definition.OpenLevel)
                return new GameplayRouteDecision(GameplayRouteDecisionStatus.LockedByLevel,
                    definition, route);

            return new GameplayRouteDecision(validationBoundary
                    ? GameplayRouteDecisionStatus.ValidationBoundary
                    : GameplayRouteDecisionStatus.Dispatch,
                definition, route);
        }
    }
}
