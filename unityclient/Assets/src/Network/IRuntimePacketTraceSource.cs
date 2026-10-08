#if UNITY_EDITOR || DEVELOPMENT_BUILD
using System;

namespace ProjectX.Network
{
    /// <summary>Read-only packet observations exposed to runtime validation tooling.</summary>
    public interface IRuntimePacketTraceSource
    {
        event Action<ProtocolPacketTrace> PacketObserved;
    }
}
#endif
