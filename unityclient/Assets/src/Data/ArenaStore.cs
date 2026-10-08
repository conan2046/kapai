using System;

namespace ProjectX.Data
{
    public sealed class ArenaStore
    {
        public event Action Changed;
        public int OpponentCount { get; private set; }
        public uint Rank { get; private set; }
        public ushort Remaining { get; private set; }
        public ushort Challenged { get; private set; }
        public byte Bought { get; private set; }
        public uint Score { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }
        public void Replace(int opponents, uint rank, ushort remaining, ushort challenged, byte bought, uint score)
        { OpponentCount=opponents; Rank=rank; Remaining=remaining; Challenged=challenged; Bought=bought; Score=score; HasAuthoritativeResponse=true; Changed?.Invoke(); }
        public void Clear() { OpponentCount=0; Rank=Score=0; Remaining=Challenged=0; Bought=0; HasAuthoritativeResponse=false; Changed?.Invoke(); }
    }
}
