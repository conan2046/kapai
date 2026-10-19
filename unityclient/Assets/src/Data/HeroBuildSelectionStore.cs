using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public readonly struct HeroBuildSelection
    {
        public HeroBuildSelection(int heroId, int branch, int strategy, int available,
            int effectiveBranch, int effectiveStrategy)
        {
            HeroId = heroId; Branch = branch; Strategy = strategy; Available = available;
            EffectiveBranch = effectiveBranch; EffectiveStrategy = effectiveStrategy;
        }
        public int HeroId { get; }
        public int Branch { get; }
        public int Strategy { get; }
        public int Available { get; }
        public int EffectiveBranch { get; }
        public int EffectiveStrategy { get; }
        public bool CanSelect(int branch) => branch >= 0 && branch <= 2 && (Available & (1 << branch)) != 0;
    }

    // Only server replies change selections. Pending requests never predict a save.
    public sealed class HeroBuildSelectionStore
    {
        private readonly Dictionary<int, HeroBuildSelection> records = new Dictionary<int, HeroBuildSelection>();
        private readonly Dictionary<int, int> pending = new Dictionary<int, int>();
        private readonly Dictionary<int, string> errors = new Dictionary<int, string>();
        private readonly HashSet<int> saving = new HashSet<int>();
        private int sequence;
        public event Action Changed;
        public bool TryGet(int hero, out HeroBuildSelection value) => records.TryGetValue(hero, out value);
        public bool IsPending(int hero) => pending.ContainsKey(hero);
        public bool IsSaving(int hero) => saving.Contains(hero);
        public string Error(int hero) => errors.TryGetValue(hero, out string value) ? value : string.Empty;
        public int Begin(int hero, bool save)
        {
            int token = unchecked(++sequence); pending[hero] = token; errors.Remove(hero);
            if (save) saving.Add(hero); else saving.Remove(hero);
            Changed?.Invoke(); return token;
        }
        public bool Cancel(int hero, int token, string error)
        {
            if (!pending.TryGetValue(hero, out int current) || current != token) return false;
            pending.Remove(hero); saving.Remove(hero); errors[hero] = error;
            Changed?.Invoke(); return true;
        }
        public void Apply(HeroBuildSelection value, bool success, string error)
        {
            pending.Remove(value.HeroId); saving.Remove(value.HeroId);
            if (value.Available != 0) records[value.HeroId] = value;
            else records.Remove(value.HeroId);
            if (success) errors.Remove(value.HeroId); else errors[value.HeroId] = error ?? "保存失败，请重试";
            Changed?.Invoke();
        }
        public void Clear()
        {
            records.Clear(); pending.Clear(); errors.Clear(); saving.Clear(); Changed?.Invoke();
        }
    }
}
