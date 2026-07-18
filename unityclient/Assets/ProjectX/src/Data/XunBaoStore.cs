using System;

namespace ProjectX.Data
{
    public sealed class XunBaoStore
    {
        public event Action Changed;
        public ushort Remaining { get; private set; }
        public uint RecoverySeconds { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(ushort remaining, uint recoverySeconds)
        {
            Remaining = remaining;
            RecoverySeconds = recoverySeconds;
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void Clear()
        {
            Remaining = 0;
            RecoverySeconds = 0;
            HasAuthoritativeResponse = false;
            Changed?.Invoke();
        }
    }
}
