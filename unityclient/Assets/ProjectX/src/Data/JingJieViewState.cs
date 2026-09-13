using System;

namespace ProjectX.Data
{
    public sealed class JingJieViewState
    {
        public event Action Changed;

        public int CurrentId { get; private set; }
        public bool HasAuthoritativeState { get; private set; }
        public bool UpgradePending { get; private set; }
        private bool upgradeEffectPending;

        public void ApplyCurrent(int id)
        {
            if (id < 0) throw new ArgumentOutOfRangeException(nameof(id));
            bool promoted = HasAuthoritativeState && id > CurrentId;
            CurrentId = id;
            HasAuthoritativeState = true;
            if (promoted) upgradeEffectPending = true;
            Changed?.Invoke();
        }

        public bool BeginUpgrade()
        {
            if (UpgradePending) return false;
            UpgradePending = true;
            Changed?.Invoke();
            return true;
        }

        public void FinishUpgrade()
        {
            if (!UpgradePending) return;
            UpgradePending = false;
            Changed?.Invoke();
        }

        public bool ConsumeUpgradeEffect()
        {
            bool value = upgradeEffectPending;
            upgradeEffectPending = false;
            return value;
        }

        public void Clear()
        {
            CurrentId = 0;
            HasAuthoritativeState = false;
            UpgradePending = false;
            upgradeEffectPending = false;
            Changed?.Invoke();
        }
    }
}
