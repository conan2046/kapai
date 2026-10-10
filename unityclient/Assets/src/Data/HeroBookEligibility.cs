namespace ProjectX.Data
{
    public static class HeroBookEligibility
    {
        public static bool CanActivate(int level, int openLevel, bool owned, bool firstDefinition,
            bool authoritative, bool pending) => authoritative && !pending && level >= openLevel
            && owned && firstDefinition;

        public static bool CanUpgrade(int level, int openLevel, bool owned, int heroStar, int requiredStar,
            bool hasNext, bool hasCost, int ownedMaterial, int requiredMaterial, bool authoritative, bool pending)
            => authoritative && !pending && level >= openLevel && owned && hasNext && hasCost
            && heroStar >= requiredStar && requiredMaterial >= 0 && ownedMaterial >= requiredMaterial;
    }
}
