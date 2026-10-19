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
        private readonly Dictionary<int, Queue<Request>> replies = new Dictionary<int, Queue<Request>>();
        private readonly struct Request
        {
            public Request(int token, bool save) { Token = token; Save = save; }
            public int Token { get; }
            public bool Save { get; }
        }
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
            if (!replies.TryGetValue(hero, out Queue<Request> queue))
                replies[hero] = queue = new Queue<Request>();
            queue.Enqueue(new Request(token, save));
            Changed?.Invoke(); return token;
        }
        public bool Cancel(int hero, int token, string error)
        {
            if (!pending.TryGetValue(hero, out int current) || current != token) return false;
            pending.Remove(hero); saving.Remove(hero); errors[hero] = error;
            Changed?.Invoke(); return true;
        }
        public bool Abandon(int hero, int token, string error)
        {
            // A failed send has no reply to drain. A timeout, in contrast, keeps its place.
            if (replies.TryGetValue(hero, out Queue<Request> queue))
            {
                int count = queue.Count;
                while (count-- > 0)
                {
                    Request request = queue.Dequeue();
                    if (request.Token != token) queue.Enqueue(request);
                }
                if (queue.Count == 0) replies.Remove(hero);
            }
            return Cancel(hero, token, error);
        }
        public bool Apply(HeroBuildSelection value, bool save, bool success, string error)
        {
            // Replies use the same ordered TCP stream as requests. Keep timed-out entries
            // until their replies arrive, including retries of the same operation.
            if (!replies.TryGetValue(value.HeroId, out Queue<Request> queue)
                || queue.Count == 0 || queue.Peek().Save != save) return false;
            Request request = queue.Dequeue();
            if (queue.Count == 0) replies.Remove(value.HeroId);
            if (!pending.TryGetValue(value.HeroId, out int token) || token != request.Token) return false;
            pending.Remove(value.HeroId); saving.Remove(value.HeroId);
            if (value.Available != 0) records[value.HeroId] = value;
            else records.Remove(value.HeroId);
            if (success) errors.Remove(value.HeroId); else errors[value.HeroId] = error ?? "保存失败，请重试";
            Changed?.Invoke();
            return true;
        }
        public void Clear()
        {
            records.Clear(); pending.Clear(); errors.Clear(); saving.Clear(); replies.Clear(); Changed?.Invoke();
        }
    }
}
