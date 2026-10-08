namespace ProjectX.Foundation
{
    public interface IProtocolMessageReader
    {
        int Remaining { get; }
        byte ReadByte();
        ushort ReadUShort();
        uint ReadUInt();
        int ReadInt();
        ulong ReadULongInt();
        string ReadString();
        byte[] ReadBytes(int count);
        IProtocolNestedPacket ReadNestedPacket();
    }

    public interface IProtocolNestedPacket
    {
        ushort Command { get; }
        IProtocolMessageReader OpenBody();
    }
}
