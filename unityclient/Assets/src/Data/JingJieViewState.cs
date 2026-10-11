using System;
using System.Globalization;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class JingJieViewState
    {
        public event Action Changed;

        public int CurrentId { get; private set; }
        public bool HasAuthoritativeState { get; private set; }
        public bool UpgradePending { get; private set; }
        public ulong Experience { get; private set; }
        public ulong RequiredExperience { get; private set; }
        public ulong Revision { get; private set; }
        public ulong Power { get; private set; }
        public int FailureCount { get; private set; }
        public int ExperiencePerSecond { get; private set; }
        public int NextId { get; private set; }
        public long ServerMilliseconds { get; private set; }
        public long CycleMilliseconds { get; private set; }
        public int IntervalMilliseconds { get; private set; } = 5000;
        private float observedAt;
        private bool upgradeEffectPending;

        public bool ApplySnapshot(JingJieSnapshot snapshot, bool suppressUpgradeEffect = false)
        {
            if(snapshot==null || snapshot.Id<1 || snapshot.Id>550 || snapshot.IntervalMilliseconds<=0)
                throw new ArgumentException("Invalid Unity realm snapshot.");
            ulong revision=ulong.Parse(snapshot.Revision,CultureInfo.InvariantCulture);
            if(HasAuthoritativeState && revision<Revision)return false;
            ulong experience=ulong.Parse(snapshot.Experience,CultureInfo.InvariantCulture);
            ulong required=ulong.Parse(snapshot.NeedExperience,CultureInfo.InvariantCulture);
            ulong power=ulong.Parse(snapshot.Power,CultureInfo.InvariantCulture);
            long server=long.Parse(snapshot.ServerMilliseconds,CultureInfo.InvariantCulture);
            long cycle=long.Parse(snapshot.CycleMilliseconds,CultureInfo.InvariantCulture);
            bool promoted=HasAuthoritativeState && snapshot.Id>CurrentId;
            CurrentId=snapshot.Id;Experience=experience;RequiredExperience=required;Revision=revision;Power=power;
            FailureCount=snapshot.Failures;ExperiencePerSecond=snapshot.Rate;NextId=snapshot.NextId;
            ServerMilliseconds=server;CycleMilliseconds=cycle;IntervalMilliseconds=snapshot.IntervalMilliseconds;
            observedAt=Time.realtimeSinceStartup;HasAuthoritativeState=true;
            if(promoted && !suppressUpgradeEffect)upgradeEffectPending=true;
            Changed?.Invoke();return true;
        }

        public float CycleProgress => !HasAuthoritativeState?0:Mathf.Clamp01(
            (float)((ServerMilliseconds+(Time.realtimeSinceStartup-observedAt)*1000d-CycleMilliseconds)/IntervalMilliseconds));

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
            Experience=RequiredExperience=Revision=Power=0;FailureCount=ExperiencePerSecond=NextId=0;
            ServerMilliseconds=CycleMilliseconds=0;
            Changed?.Invoke();
        }
    }
}
