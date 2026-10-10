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
        private Transport transport;
        private bool disposed;

        public bool IsConnected { get { lock (sendLock) return transport?.Stream != null && transport.Client.Connected; } }

        public async Task ConnectAsync(string host, int port, CancellationToken token = default)
        {
            var attempt = new Transport();
            lock (sendLock)
            {
                if (disposed) { attempt.Dispose(); throw new ObjectDisposedException(nameof(LegacyTcpClient)); }
                DisposeTransport();
                transport = attempt;
            }
            try
            {
                using (var linked = CancellationTokenSource.CreateLinkedTokenSource(token, attempt.Cancellation.Token))
                using (linked.Token.Register(attempt.Client.Close))
                {
                    linked.Token.ThrowIfCancellationRequested();
                    await attempt.Client.ConnectAsync(host, port).ConfigureAwait(false);
                    lock (sendLock)
                    {
                        linked.Token.ThrowIfCancellationRequested();
                        if (transport != attempt || disposed) throw new OperationCanceledException();
                        attempt.Stream = attempt.Client.GetStream();
                        attempt.ReceiveTask = ReceiveLoopAsync(attempt, attempt.Stream, attempt.Cancellation.Token);
                    }
                }
            }
            catch
            {
                lock (sendLock)
                {
                    if (transport == attempt) DisposeTransport();
                    else attempt.Dispose();
                }
                throw;
            }
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
                if (transport?.Stream == null)
                {
                    throw new InvalidOperationException("TCP client is not connected.");
                }

                transport.Stream.Write(packet, 0, packet.Length);
            }
        }

        public void Pump(Action<ushort, LegacyTcpMessage, Exception> handler)
        {
            while (received.TryDequeue(out ReceivedPacket packet))
            {
                lock (sendLock) { if (packet.Owner != transport || disposed) continue; }
                handler(packet.Command, new LegacyTcpMessage(packet.Body), packet.Error);
            }
        }

        public void Disconnect()
        {
            lock (sendLock) DisposeTransport();
        }

        public void Dispose()
        {
            lock (sendLock) { disposed = true; DisposeTransport(); }
        }

        private async Task ReceiveLoopAsync(Transport owner, NetworkStream source, CancellationToken token)
        {
            byte[] header = new byte[HeaderSize];
            try
            {
                while (!token.IsCancellationRequested)
                {
                    await ReadExactlyAsync(source, header, HeaderSize, token).ConfigureAwait(false);
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
                        await ReadExactlyAsync(source, body, bodyLength, token).ConfigureAwait(false);
                    }

                    received.Enqueue(new ReceivedPacket(owner, command, body));
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
                    received.Enqueue(new ReceivedPacket(owner, 0, Array.Empty<byte>(), exception));
                }
            }
        }

        private static async Task ReadExactlyAsync(NetworkStream source, byte[] buffer, int count, CancellationToken token)
        {
            int offset = 0;
            while (offset < count)
            {
                int read = await source.ReadAsync(buffer, offset, count - offset, token).ConfigureAwait(false);
                if (read == 0)
                {
                    throw new EndOfStreamException("The game server closed the connection.");
                }

                offset += read;
            }
        }

        private void DisposeTransport()
        {
            Transport previous = transport;
            transport = null;
            previous?.Dispose();
            while (received.TryDequeue(out _))
            {
            }
        }

        private sealed class Transport : IDisposable
        {
            public readonly TcpClient Client = new TcpClient { NoDelay = true };
            public readonly CancellationTokenSource Cancellation = new CancellationTokenSource();
            public NetworkStream Stream;
            public Task ReceiveTask;
            private int disposed;

            public void Dispose()
            {
                if (Interlocked.Exchange(ref disposed, 1) != 0) return;
                try { Cancellation.Cancel(); }
                finally
                {
                    Client.Close();
                    Cancellation.Dispose();
                }
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
            public ReceivedPacket(Transport owner, ushort command, byte[] body, Exception error = null)
            {
                Owner = owner;
                Command = command;
                Body = body;
                Error = error;
            }

            public Transport Owner { get; }
            public ushort Command { get; }
            public byte[] Body { get; }
            public Exception Error { get; }
        }
    }
}
