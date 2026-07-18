using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class StaminaClaimRecord
    {
        public StaminaClaimRecord(byte index, byte state) { Index = index; State = state; }
        public byte Index { get; }
        public byte State { get; }
    }

    public sealed class StaminaClaimStore
    {
        private readonly List<StaminaClaimRecord> items = new List<StaminaClaimRecord>();
        public event Action Changed;
        public IReadOnlyList<StaminaClaimRecord> Items => items;
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(IEnumerable<StaminaClaimRecord> values)
        {
            items.Clear();
            if (values != null) items.AddRange(values);
            items.Sort((left, right) => left.Index.CompareTo(right.Index));
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public byte StateOf(byte index)
        {
            foreach (StaminaClaimRecord item in items) if (item.Index == index) return item.State;
            return 0;
        }

        public void Clear()
        {
            items.Clear();
            HasAuthoritativeResponse = false;
            Changed?.Invoke();
        }
    }
}
