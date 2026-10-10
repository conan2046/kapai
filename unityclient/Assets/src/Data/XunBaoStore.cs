using System;
using System.Linq;

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
        public int PendingOperation { get; private set; }
        public int PendingFaBaoId { get; private set; }
        private double recoveryDueAt;

        public uint RecoveryRemaining(double now) => recoveryDueAt > 0
            ? (uint)Math.Max(0, Math.Ceiling(recoveryDueAt - now)) : RecoverySeconds;

        public bool BeginOperation(int operation, int faBaoId)
        {
            if (PendingOperation != 0) return false;
            PendingOperation = operation; PendingFaBaoId = faBaoId; Changed?.Invoke(); return true;
        }

        public bool CanSearch(FaBaoSearchDefinition search, EquipmentCatalog catalog, BagStore bag)
        {
            if (!HasAuthoritativeResponse || Remaining == 0 || search?.FragmentIds == null
                || PendingOperation == 28 || PendingOperation == 29) return false;
            var definition = catalog.GetFaBao(search.FaBaoId);
            return definition != null && search.FaBaoId != 615
                && (definition.Quality == 3 || search.FragmentIds.Any(id => bag.GetTotalQuantityByItemId(id) > 0))
                && search.FragmentIds.Any(id => bag.GetTotalQuantityByItemId(id) == 0);
        }

        public bool CanCompose(FaBaoSearchDefinition search, BagStore bag, int playerLevel)
        {
            if (!HasAuthoritativeResponse || search?.FragmentIds == null || search.FragmentCosts == null
                || search.FragmentIds.Length == 0 || search.FragmentIds.Length != search.FragmentCosts.Length
                || playerLevel < FunctionUnlockCatalog.Resolve(1180).OpenLevel
                || PendingOperation == 36 || (PendingOperation == 30 && PendingFaBaoId == search.FaBaoId)) return false;
            for (int i = 0; i < search.FragmentIds.Length; i++)
                if (search.FragmentCosts[i] <= 0 || bag.GetTotalQuantityByItemId(search.FragmentIds[i]) < search.FragmentCosts[i]) return false;
            return true;
        }

        public void Replace(ushort remaining, uint recoverySeconds, double now = 0)
        {
            Remaining = remaining;
            RecoverySeconds = recoverySeconds;
            recoveryDueAt = now > 0 && recoverySeconds > 0 ? now + recoverySeconds : 0;
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void SetOperationResult(bool succeeded, string message, ushort? remaining = null, uint? recoverySeconds = null, double now = 0)
        {
            LastOperationSucceeded = succeeded;
            LastMessage = string.IsNullOrWhiteSpace(message) ? (succeeded ? "操作成功" : "操作失败") : message;
            if (remaining.HasValue) Remaining = remaining.Value;
            if (recoverySeconds.HasValue)
            {
                RecoverySeconds = recoverySeconds.Value;
                recoveryDueAt = now > 0 && RecoverySeconds > 0 ? now + RecoverySeconds : 0;
            }
            PendingOperation = PendingFaBaoId = 0;
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
            PendingOperation = PendingFaBaoId = 0;
            recoveryDueAt = 0;
            Changed?.Invoke();
        }
    }
}
