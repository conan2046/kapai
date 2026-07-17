using System;
using System.Collections.Generic;

namespace ProjectX.Network
{
    public sealed class ProtocolDispatcher
    {
        private readonly ProtocolRegistry registry;
        private readonly Dictionary<ushort, Action<LegacyTcpMessage>> handlers =
            new Dictionary<ushort, Action<LegacyTcpMessage>>();

        public ProtocolDispatcher(ProtocolRegistry registry)
        {
            this.registry = registry ?? throw new ArgumentNullException(nameof(registry));
        }

        public event Action<ushort, LegacyTcpMessage> UnhandledPacket;

        public void Register(ushort command, Action<LegacyTcpMessage> handler)
        {
            handlers[command] = handler ?? throw new ArgumentNullException(nameof(handler));
        }

        public void Dispatch(ushort command, LegacyTcpMessage message)
        {
            registry.Complete(command);
            if (handlers.TryGetValue(command, out Action<LegacyTcpMessage> handler))
                handler(message);
            else
                UnhandledPacket?.Invoke(command, message);
        }
    }
}
