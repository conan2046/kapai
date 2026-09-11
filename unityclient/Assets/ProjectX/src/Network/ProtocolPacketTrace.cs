using System;

namespace ProjectX.Network
{
    public enum ProtocolPacketDirection
    {
        Sent,
        Received
    }

    public sealed class ProtocolPacketTrace
    {
        public ProtocolPacketTrace(ProtocolPacketDirection direction, ushort command, byte[] payload, byte[] rawPacket, DateTime timestampUtc)
        {
            Direction = direction;
            Command = command;
            Payload = payload ?? Array.Empty<byte>();
            RawPacket = rawPacket ?? Array.Empty<byte>();
            TimestampUtc = timestampUtc;
        }

        public ProtocolPacketDirection Direction { get; }
        public ushort Command { get; }
        public byte[] Payload { get; }
        public byte[] RawPacket { get; }
        public DateTime TimestampUtc { get; }
    }
}
