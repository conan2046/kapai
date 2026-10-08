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
        public bool ClaimPending { get; private set; }
        public byte LastClaimIndex { get; private set; }
        public bool LastClaimPaid { get; private set; }
        public bool LastClaimSucceeded { get; private set; }
        public string LastClaimError { get; private set; } = string.Empty;
        public int SuccessfulClaimCount { get; private set; }

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

        public void BeginClaim(byte index, bool paid)
        {
            ClaimPending = true;
            LastClaimIndex = index;
            LastClaimPaid = paid;
            LastClaimSucceeded = false;
            LastClaimError = string.Empty;
            Changed?.Invoke();
        }

        public void ApplyClaimSuccess(byte index)
        {
            for (int i = 0; i < items.Count; i++)
                if (items[i].Index == index) { items[i] = new StaminaClaimRecord(index, 3); break; }
            ClaimPending = false;
            LastClaimIndex = index;
            LastClaimSucceeded = true;
            LastClaimError = string.Empty;
            SuccessfulClaimCount++;
            Changed?.Invoke();
        }

        public void ApplyClaimFailure(byte index, string error)
        {
            ClaimPending = false;
            LastClaimIndex = index;
            LastClaimSucceeded = false;
            LastClaimError = error ?? string.Empty;
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear();
            HasAuthoritativeResponse = false;
            ClaimPending = false;
            LastClaimIndex = 0;
            LastClaimPaid = false;
            LastClaimSucceeded = false;
            LastClaimError = string.Empty;
            SuccessfulClaimCount = 0;
            Changed?.Invoke();
        }
    }
}
