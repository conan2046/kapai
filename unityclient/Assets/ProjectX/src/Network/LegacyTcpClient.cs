using System;
using System.Collections.Concurrent;
using System.IO;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace ProjectX.Network
{
    public sealed class LegacyTcpClient : IDisposable
    {
        private const int HeaderSize = 6;
        private const int MaxBodySize = 16 * 1024 * 1024;

        private readonly ConcurrentQueue<ReceivedPacket> received = new ConcurrentQueue<ReceivedPacket>();
        private readonly object sendLock = new object();
        private TcpClient tcpClient;
        private NetworkStream stream;
        private CancellationTokenSource cancellation;
        private Task receiveTask;

        public bool IsConnected => tcpClient != null && tcpClient.Connected;

        public async Task ConnectAsync(string host, int port)
        {
            DisposeTransport();
            tcpClient = new TcpClient { NoDelay = true };
            await tcpClient.ConnectAsync(host, port);
            stream = tcpClient.GetStream();
            cancellation = new CancellationTokenSource();
            receiveTask = ReceiveLoopAsync(cancellation.Token);
        }

        public void Send(LegacyTcpMessage message)
        {
            if (message == null)
            {
                throw new ArgumentNullException(nameof(message));
            }

            byte[] payload = message.ToPayload();
            if (payload.Length < sizeof(ushort))
            {
                throw new InvalidDataException("Legacy outgoing messages must begin with a 2-byte command.");
            }

            ushort command = (ushort)(payload[0] | payload[1] << 8);
            int bodyLength = payload.Length - sizeof(ushort);
            byte[] packet = new byte[HeaderSize + bodyLength];
            WriteUInt32(packet, 0, unchecked((uint)bodyLength));
            packet[4] = unchecked((byte)command);
            packet[5] = unchecked((byte)(command >> 8));
            if (bodyLength > 0)
            {
                Buffer.BlockCopy(payload, sizeof(ushort), packet, HeaderSize, bodyLength);
            }

            lock (sendLock)
            {
                if (stream == null)
                {
                    throw new InvalidOperationException("TCP client is not connected.");
                }

                stream.Write(packet, 0, packet.Length);
            }
        }

        public void Pump(Action<ushort, LegacyTcpMessage, Exception> handler)
        {
            while (received.TryDequeue(out ReceivedPacket packet))
            {
                handler(packet.Command, new LegacyTcpMessage(packet.Body), packet.Error);
            }
        }

        public void Disconnect()
        {
            DisposeTransport();
        }

        public void Dispose()
        {
            DisposeTransport();
        }

        private async Task ReceiveLoopAsync(CancellationToken token)
        {
            byte[] header = new byte[HeaderSize];
            try
            {
                while (!token.IsCancellationRequested)
                {
                    await ReadExactlyAsync(stream, header, HeaderSize, token);
                    uint bodyLengthValue = ReadUInt32(header, 0);
                    if (bodyLengthValue > MaxBodySize)
                    {
                        throw new InvalidDataException($"Invalid packet body length: {bodyLengthValue}.");
                    }

                    int bodyLength = checked((int)bodyLengthValue);
                    ushort command = (ushort)(header[4] | header[5] << 8);
                    byte[] body = new byte[bodyLength];
                    if (bodyLength > 0)
                    {
                        await ReadExactlyAsync(stream, body, bodyLength, token);
                    }

                    received.Enqueue(new ReceivedPacket(command, body));
                }
            }
            catch (OperationCanceledException)
            {
            }
            catch (ObjectDisposedException)
            {
            }
            catch (Exception exception)
            {
                if (!token.IsCancellationRequested)
                {
                    received.Enqueue(new ReceivedPacket(0, Array.Empty<byte>(), exception));
                }
            }
        }

        private static async Task ReadExactlyAsync(NetworkStream source, byte[] buffer, int count, CancellationToken token)
        {
            int offset = 0;
            while (offset < count)
            {
                int read = await source.ReadAsync(buffer, offset, count - offset, token);
                if (read == 0)
                {
                    throw new EndOfStreamException("The game server closed the connection.");
                }

                offset += read;
            }
        }

        private void DisposeTransport()
        {
            cancellation?.Cancel();
            stream?.Dispose();
            tcpClient?.Close();
            cancellation?.Dispose();
            cancellation = null;
            stream = null;
            tcpClient = null;
            receiveTask = null;
            while (received.TryDequeue(out _))
            {
            }
        }

        private static uint ReadUInt32(byte[] bytes, int offset)
        {
            return (uint)(bytes[offset]
                | bytes[offset + 1] << 8
                | bytes[offset + 2] << 16
                | bytes[offset + 3] << 24);
        }

        private static void WriteUInt32(byte[] bytes, int offset, uint value)
        {
            bytes[offset] = unchecked((byte)value);
            bytes[offset + 1] = unchecked((byte)(value >> 8));
            bytes[offset + 2] = unchecked((byte)(value >> 16));
            bytes[offset + 3] = unchecked((byte)(value >> 24));
        }

        private readonly struct ReceivedPacket
        {
            public ReceivedPacket(ushort command, byte[] body, Exception error = null)
            {
                Command = command;
                Body = body;
                Error = error;
            }

            public ushort Command { get; }
            public byte[] Body { get; }
            public Exception Error { get; }
        }
    }
}
