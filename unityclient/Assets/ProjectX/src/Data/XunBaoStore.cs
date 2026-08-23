using System;

namespace ProjectX.Data
{
    public sealed class XunBaoStore
    {
        public event Action Changed;
        public ushort Remaining { get; private set; }
        public uint RecoverySeconds { get; private set; }
        public bool HasAuthoritativeResponse { get; private set; }
        public string LastMessage { get; private set; }
        public bool LastOperationSucceeded { get; private set; }

        public void Replace(ushort remaining, uint recoverySeconds)
        {
            Remaining = remaining;
            RecoverySeconds = recoverySeconds;
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void SetOperationResult(bool succeeded, string message, ushort? remaining = null, uint? recoverySeconds = null)
        {
            LastOperationSucceeded = succeeded;
            LastMessage = string.IsNullOrWhiteSpace(message) ? (succeeded ? "操作成功" : "操作失败") : message;
            if (remaining.HasValue) Remaining = remaining.Value;
            if (recoverySeconds.HasValue) RecoverySeconds = recoverySeconds.Value;
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void Clear()
        {
            Remaining = 0;
            RecoverySeconds = 0;
            HasAuthoritativeResponse = false;
            LastMessage = null;
            LastOperationSucceeded = false;
            Changed?.Invoke();
        }
    }
}
