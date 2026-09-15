using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class FishBasketSlot
    {
        public FishBasketSlot(ushort slotIndex, ushort itemId, ushort quantity)
        {
            SlotIndex = slotIndex;
            ItemId = itemId;
            Quantity = quantity;
        }

        public ushort SlotIndex { get; }
        public ushort ItemId { get; }
        public ushort Quantity { get; }
    }

    public sealed class FishCatchRecord
    {
        public FishCatchRecord(ushort itemId, ushort slotIndex, ushort quantity, bool discarded)
        {
            ItemId = itemId;
            SlotIndex = slotIndex;
            Quantity = quantity;
            Discarded = discarded;
        }

        public ushort ItemId { get; }
        public ushort SlotIndex { get; }
        public ushort Quantity { get; }
        public bool Discarded { get; }
    }

    public sealed class FishStore
    {
        private readonly SortedDictionary<ushort, FishBasketSlot> slots =
            new SortedDictionary<ushort, FishBasketSlot>();

        public event Action Changed;
        public event Action<FishCatchRecord> Caught;

        public bool HasAuthoritativeState { get; private set; }
        public int SceneId { get; private set; }
        public int MapId { get; private set; }
        public int PositionX { get; private set; }
        public int PositionY { get; private set; }
        public byte Direction { get; private set; }
        public bool Flip { get; private set; }
        public int FishingShapeId { get; private set; }
        public uint Gold { get; private set; }
        public uint GoldCost { get; private set; }
        public ushort CycleMinSeconds { get; private set; }
        public ushort CycleMaxSeconds { get; private set; }
        public ushort BasketCapacity { get; private set; }
        public ushort StackLimit { get; private set; }
        public bool IsFishing { get; private set; }
        public byte CurrentDirection { get; private set; }
        public DateTime FinishUtc { get; private set; }
        public IReadOnlyCollection<FishBasketSlot> Slots => slots.Values;
        public int OccupiedSlots => slots.Count;
        public long FishCount => slots.Values.Sum(value => (long)value.Quantity);
        public double RemainingSeconds => IsFishing
            ? Math.Max(0d, (FinishUtc - DateTime.UtcNow).TotalSeconds)
            : 0d;

        public void Configure(int sceneId, int mapId, int x, int y, byte direction, bool flip,
            int shapeId, uint gold, uint goldCost, ushort minSeconds, ushort maxSeconds,
            ushort capacity, ushort stackLimit, bool fishing, ushort remainingSeconds)
        {
            SceneId = sceneId;
            MapId = mapId;
            PositionX = x;
            PositionY = y;
            Direction = direction;
            Flip = flip;
            FishingShapeId = shapeId;
            Gold = gold;
            GoldCost = goldCost;
            CycleMinSeconds = minSeconds;
            CycleMaxSeconds = maxSeconds;
            BasketCapacity = capacity;
            StackLimit = stackLimit;
            CurrentDirection = direction;
            SetFishing(fishing ? remainingSeconds : (ushort)0);
            HasAuthoritativeState = true;
            Changed?.Invoke();
        }

        public void ReplaceBasket(IEnumerable<FishBasketSlot> values)
        {
            slots.Clear();
            if (values != null)
                foreach (FishBasketSlot value in values)
                    if (value != null) slots[value.SlotIndex] = value;
            Changed?.Invoke();
        }

        public void BeginFishing(ushort duration, byte direction, uint gold)
        {
            CurrentDirection = direction;
            Gold = gold;
            SetFishing(duration);
            Changed?.Invoke();
        }

        public void ApplyCatch(ushort itemId, ushort slotIndex, ushort quantity,
            bool discarded, ushort nextDuration, uint gold)
        {
            Gold = gold;
            if (!discarded) slots[slotIndex] = new FishBasketSlot(slotIndex, itemId, quantity);
            SetFishing(nextDuration);
            Changed?.Invoke();
            Caught?.Invoke(new FishCatchRecord(itemId, slotIndex, quantity, discarded));
        }

        public void ApplyCollected(ushort slotIndex) { slots.Remove(slotIndex); Changed?.Invoke(); }
        public void ApplyTime(ushort remainingSeconds) { SetFishing(remainingSeconds); Changed?.Invoke(); }
        public void Stop(uint gold) { Gold = gold; SetFishing(0); Changed?.Invoke(); }

        public void Clear()
        {
            slots.Clear();
            HasAuthoritativeState = false;
            IsFishing = false;
            FinishUtc = default;
            Gold = 0;
            Changed?.Invoke();
        }

        private void SetFishing(ushort duration)
        {
            IsFishing = duration > 0;
            FinishUtc = IsFishing ? DateTime.UtcNow.AddSeconds(duration) : default;
        }
    }
}
