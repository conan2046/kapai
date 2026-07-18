using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class StaminaClaimDefinition
    {
        public StaminaClaimDefinition(byte id, int start, int end, int stamina, int premiumCost)
        { Id = id; Start = start; End = end; Stamina = stamina; PremiumCost = premiumCost; }
        public byte Id { get; }
        public int Start { get; }
        public int End { get; }
        public int Stamina { get; }
        public int PremiumCost { get; }
        public string TimeText => $"{Start / 100}:00-{End / 100}:00";
    }

    public sealed class StaminaClaimCatalog
    {
        private readonly List<StaminaClaimDefinition> items = new List<StaminaClaimDefinition>
        {
            new StaminaClaimDefinition(1, 1200, 1400, 50, 20),
            new StaminaClaimDefinition(2, 1800, 2000, 50, 20),
            new StaminaClaimDefinition(3, 2100, 2200, 50, 20),
        };
        public IReadOnlyList<StaminaClaimDefinition> Items => items;
    }
}
