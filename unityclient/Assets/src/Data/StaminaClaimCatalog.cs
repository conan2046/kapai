using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class StaminaClaimDefinition
    {
        public StaminaClaimDefinition(byte id, int start, int end, int displayStamina, int authoritativeStamina, int premiumCost)
        { Id = id; Start = start; End = end; DisplayStamina = displayStamina; AuthoritativeStamina = authoritativeStamina; PremiumCost = premiumCost; }
        public byte Id { get; }
        public int Start { get; }
        public int End { get; }
        public int DisplayStamina { get; }
        public int AuthoritativeStamina { get; }
        public int PremiumCost { get; }
        public string TimeText => $"{Start / 100}:00-{End / 100}:00";
    }

    public sealed class StaminaClaimCatalog
    {
        private readonly List<StaminaClaimDefinition> items = new List<StaminaClaimDefinition>
        {
            // Current Cocos stamina_dat.lua renders +100, while the current
            // server stamina.json and op=3 response authoritatively grant +50.
            new StaminaClaimDefinition(1, 1200, 1400, 100, 50, 20),
            new StaminaClaimDefinition(2, 1800, 2000, 100, 50, 20),
            new StaminaClaimDefinition(3, 2100, 2200, 100, 50, 20),
        };
        public IReadOnlyList<StaminaClaimDefinition> Items => items;
    }
}
