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
        public ushort PendingClaimId { get; private set; }

        public void Replace(IEnumerable<SevenDayTaskRecord> values)
        {
            tasks.Clear();
            if (values != null) tasks.AddRange(values);
            HasAuthoritativeResponse=true;
            PendingClaimId=0;
            Changed?.Invoke();
        }

        public bool BeginClaim(ushort id)
        {
            SevenDayTaskRecord task=tasks.Find(value=>value.Id==id);
            if(PendingClaimId!=0||task==null||task.State!=1)return false;
            PendingClaimId=id;Changed?.Invoke();return true;
        }

        public void CompleteClaim(ushort id,bool success)
        {
            if(PendingClaimId!=id)return;
            PendingClaimId=0;
            if(success)
            {
                int index=tasks.FindIndex(value=>value.Id==id);
                if(index>=0){SevenDayTaskRecord old=tasks[index];tasks[index]=new SevenDayTaskRecord(old.Id,old.Progress,2);}
            }
            Changed?.Invoke();
        }

        public void Clear(){tasks.Clear();HasAuthoritativeResponse=false;PendingClaimId=0;Changed?.Invoke();}
    }
}
