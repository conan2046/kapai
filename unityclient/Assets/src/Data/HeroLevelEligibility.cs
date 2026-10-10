namespace ProjectX.Data
{
    public static class HeroLevelEligibility
    {
        public static bool CanFeed(int heroLevel, int playerLevel, int openLevel, int quantity,
            int experience, bool authoritative, bool knownLevel) => authoritative && knownLevel
            && heroLevel > 0 && heroLevel < playerLevel && playerLevel >= openLevel
            && quantity > 0 && experience > 0;

        public static bool CanAutoLevel(int heroLevel, int targetLevel, int playerLevel, int openLevel,
            ulong requiredExperience, ulong availableExperience, bool authoritative, bool knownLevels)
            => authoritative && knownLevels && heroLevel > 0 && targetLevel > heroLevel
            && targetLevel <= playerLevel && playerLevel >= openLevel
            && availableExperience >= requiredExperience;
    }
}
