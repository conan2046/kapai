using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class SevenDayTaskRecord
    {
        public SevenDayTaskRecord(ushort id, uint progress, byte state) { Id=id; Progress=progress; State=state; }
        public ushort Id { get; }
        public uint Progress { get; }
        public byte State { get; }
    }

    public sealed class SevenDayStore
    {
        private readonly List<SevenDayTaskRecord> tasks = new List<SevenDayTaskRecord>();
        public event Action Changed;
        public IReadOnlyList<SevenDayTaskRecord> Tasks => tasks;
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(IEnumerable<SevenDayTaskRecord> values)
        {
            tasks.Clear();
            if (values != null) tasks.AddRange(values);
            HasAuthoritativeResponse=true;
            Changed?.Invoke();
        }

        public void Clear(){tasks.Clear();HasAuthoritativeResponse=false;Changed?.Invoke();}
    }
}
