#if UNITY_EDITOR || DEVELOPMENT_BUILD
namespace ProjectX.Foundation
{
    /// <summary>Read-only runtime facts consumed by optional validation tooling.</summary>
    public interface IRuntimeSnapshotContext
    {
        bool IsSnapshotContextReady { get; }
        string AppStateName { get; }
        uint LocalUserId { get; }
        uint PlayerRoleId { get; }
        string PlayerName { get; }
        bool IsNetworkDisconnectedOrFaulted { get; }
    }
}
#endif
