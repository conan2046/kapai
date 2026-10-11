namespace ProjectX.Data
{
    public enum JingJieUpgradeBlock
    {
        None, Synchronizing, Maximum, Pending, Experience
    }

    public static class JingJieUpgradeEligibility
    {
        public static JingJieUpgradeBlock Evaluate(JingJieViewState state, JingJieDefinition target)
        {
            if (!state.HasAuthoritativeState) return JingJieUpgradeBlock.Synchronizing;
            if (target == null) return JingJieUpgradeBlock.Maximum;
            if (state.UpgradePending) return JingJieUpgradeBlock.Pending;
            if (state.Experience < state.RequiredExperience) return JingJieUpgradeBlock.Experience;
            return JingJieUpgradeBlock.None;
        }
    }
}
