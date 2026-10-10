namespace ProjectX.Data
{
    public enum JingJieUpgradeBlock
    {
        None, Synchronizing, Maximum, Pending, Level, Power, Material, Gold
    }

    public static class JingJieUpgradeEligibility
    {
        public static JingJieUpgradeBlock Evaluate(JingJieViewState state, JingJieDefinition target,
            int level, ulong power, long gold, int materialOwned)
        {
            if (!state.HasAuthoritativeState) return JingJieUpgradeBlock.Synchronizing;
            if (target == null) return JingJieUpgradeBlock.Maximum;
            if (state.UpgradePending) return JingJieUpgradeBlock.Pending;
            if (level < target.LevelLimit) return JingJieUpgradeBlock.Level;
            if (power < (ulong)target.PowerLimit) return JingJieUpgradeBlock.Power;
            if (target.MaterialId > 0 && materialOwned < target.MaterialAmount)
                return JingJieUpgradeBlock.Material;
            if (gold < target.GoldAmount) return JingJieUpgradeBlock.Gold;
            return JingJieUpgradeBlock.None;
        }
    }
}
