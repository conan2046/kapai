using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public sealed class YouLiRecord
    {
        public YouLiDefinition Definition { get; internal set; }
        public byte Mode { get; internal set; }
        public byte DurationType { get; internal set; }
        public ushort HeroId { get; internal set; }
        public uint LastTime { get; internal set; }
        public uint EndTime { get; internal set; }
        public ushort FragmentCount { get; internal set; }
        public int RewardBatchCount { get; internal set; }
        public int DialogueCount { get; internal set; }
        public bool IsActive => HeroId > 0;
    }

    public sealed class YouLiStore
    {
        private readonly List<YouLiRecord> items = new List<YouLiRecord>();
        private readonly Dictionary<byte, YouLiRecord> incoming = new Dictionary<byte, YouLiRecord>();

        public event Action Changed;
        public IReadOnlyList<YouLiRecord> Items => items;
        public int ServerRecordCount { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }

        public void Initialize(IEnumerable<YouLiDefinition> definitions)
        {
            items.Clear();
            if (definitions != null) items.AddRange(definitions.Select(value => new YouLiRecord { Definition = value }));
            incoming.Clear();
            ServerRecordCount = 0;
            HasAuthoritativeResponse = false;
            Changed?.Invoke();
        }

        public void BeginUpdate(int expectedCount)
        {
            incoming.Clear();
            ServerRecordCount = expectedCount;
        }

        public void Add(byte id, byte mode, byte durationType, ushort heroId, uint lastTime, uint endTime,
            ushort fragmentCount, int rewardBatchCount, int dialogueCount)
        {
            incoming[id] = new YouLiRecord
            {
                Mode = mode, DurationType = durationType, HeroId = heroId, LastTime = lastTime,
                EndTime = endTime, FragmentCount = fragmentCount, RewardBatchCount = rewardBatchCount,
                DialogueCount = dialogueCount
            };
        }

        public void EndUpdate()
        {
            foreach (YouLiRecord item in items)
            {
                if (!incoming.TryGetValue(item.Definition.Id, out YouLiRecord value))
                {
                    item.Mode = item.DurationType = 0; item.HeroId = 0; item.LastTime = item.EndTime = 0;
                    item.FragmentCount = 0; item.RewardBatchCount = item.DialogueCount = 0;
                    continue;
                }
                item.Mode = value.Mode; item.DurationType = value.DurationType; item.HeroId = value.HeroId;
                item.LastTime = value.LastTime; item.EndTime = value.EndTime; item.FragmentCount = value.FragmentCount;
                item.RewardBatchCount = value.RewardBatchCount; item.DialogueCount = value.DialogueCount;
            }
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void Clear()
        {
            items.Clear(); incoming.Clear(); ServerRecordCount = 0; HasAuthoritativeResponse = false; Changed?.Invoke();
        }
    }
}
