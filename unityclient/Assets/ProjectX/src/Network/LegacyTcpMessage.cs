using System;
using System.IO;
using System.Text;

namespace ProjectX.Network
{
    /// <summary>
    /// Binary stream compatible with the legacy Cocos LTCPMsg payload API.
    /// Integers are little-endian and strings are length-prefixed UTF-16LE.
    /// </summary>
    public sealed class LegacyTcpMessage
    {
        private readonly MemoryStream stream;
        private readonly BinaryReader reader;
        private readonly BinaryWriter writer;

        public LegacyTcpMessage()
        {
            stream = new MemoryStream(256);
            writer = new BinaryWriter(stream, Encoding.UTF8);
        }

        internal LegacyTcpMessage(byte[] body)
        {
            stream = new MemoryStream(body ?? Array.Empty<byte>(), false);
            reader = new BinaryReader(stream, Encoding.UTF8);
        }

        public static LegacyTcpMessage New()
        {
            return new LegacyTcpMessage();
        }

        public int Remaining => checked((int)(stream.Length - stream.Position));

        public ushort OutgoingCommand
        {
            get
            {
                byte[] payload = ToPayload();
                if (payload.Length < sizeof(ushort))
                    throw new InvalidDataException("Legacy outgoing messages must begin with a 2-byte command.");
                return (ushort)(payload[0] | payload[1] << 8);
            }
        }

        public void Reset()
        {
            stream.Position = 0;
            stream.SetLength(0);
        }

        public void WriteByte(int value)
        {
            EnsureWriter();
            writer.Write(unchecked((byte)value));
        }

        public void WriteWord(int value)
        {
            WriteUShort(value);
        }

        public void WriteUShort(int value)
        {
            EnsureWriter();
            writer.Write(unchecked((ushort)value));
        }

        public void WriteUInt(uint value)
        {
            EnsureWriter();
            writer.Write(value);
        }

        public void WriteString(string value)
        {
            EnsureWriter();
            byte[] bytes = Encoding.Unicode.GetBytes(value ?? string.Empty);
            if (bytes.Length > ushort.MaxValue)
            {
                throw new ArgumentOutOfRangeException(nameof(value), "Legacy strings cannot exceed 65535 encoded bytes.");
            }

            writer.Write((ushort)bytes.Length);
            writer.Write(bytes);
        }

        public byte ReadByte()
        {
            EnsureReadable(sizeof(byte));
            return reader.ReadByte();
        }

        public ushort ReadWord()
        {
            return ReadUShort();
        }

        public ushort ReadUShort()
        {
            EnsureReadable(sizeof(ushort));
            return reader.ReadUInt16();
        }

        public uint ReadUInt()
        {
            EnsureReadable(sizeof(uint));
            return reader.ReadUInt32();
        }

        public int ReadInt()
        {
            EnsureReadable(sizeof(int));
            return reader.ReadInt32();
        }

        public ulong ReadULongInt()
        {
            EnsureReadable(sizeof(ulong));
            return reader.ReadUInt64();
        }

        public string ReadString()
        {
            ushort byteLength = ReadUShort();
            EnsureReadable(byteLength);
            return Encoding.Unicode.GetString(reader.ReadBytes(byteLength));
        }

        internal byte[] ToPayload()
        {
            EnsureWriter();
            writer.Flush();
            return stream.ToArray();
        }

        private void EnsureWriter()
        {
            if (writer == null)
            {
                throw new InvalidOperationException("This message is read-only.");
            }
        }

        private void EnsureReadable(int count)
        {
            if (reader == null)
            {
                throw new InvalidOperationException("This message is write-only.");
            }

            if (count < 0 || stream.Position + count > stream.Length)
            {
                throw new EndOfStreamException($"Packet body underflow: need {count} bytes, remaining {Remaining}.");
            }
        }
    }
}
