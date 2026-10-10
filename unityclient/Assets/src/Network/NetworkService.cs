using System;
using System.Threading;
using System.Threading.Tasks;

namespace ProjectX.Network
{
    public enum NetworkState
    {
        Idle,
        Connecting,
        Connected,
        Disconnected,
        Faulted
    }

    public sealed class NetworkService : IDisposable
    {
        private readonly LegacyTcpClient client = new LegacyTcpClient();
        private string lastHost;
        private int lastPort;
        private bool disposing;
        private int connectionVersion;
        private CancellationTokenSource pendingConnection;

        public event Action<ushort, LegacyTcpMessage> PacketReceived;
        public event Action<ProtocolPacketTrace> PacketObserved;
        public event Action<NetworkState> StateChanged;
        public event Action<string> Disconnected;

        public NetworkState State { get; private set; } = NetworkState.Idle;
        public bool IsConnected => State == NetworkState.Connected && client.IsConnected;
        public int SessionVersion => connectionVersion;

        public async Task ConnectAsync(string host, int port, int timeoutSeconds = 8,
            CancellationToken cancellationToken = default)
        {
            if (disposing) throw new ObjectDisposedException(nameof(NetworkService));
            if (State == NetworkState.Connecting) throw new InvalidOperationException("A connection attempt is already running.");
            int version = ++connectionVersion;
            var attempt = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            CancellationToken token = attempt.Token;
            pendingConnection = attempt;
            lastHost = host;
            lastPort = port;
            try
            {
                SetState(NetworkState.Connecting);
                Task connectTask = client.ConnectAsync(host, port, token);
                Task completed = await Task.WhenAny(connectTask, Task.Delay(TimeSpan.FromSeconds(timeoutSeconds), token));
                if (completed != connectTask)
                {
                    _ = ObserveConnectionAsync(connectTask);
                    if (disposing || version != connectionVersion) throw new OperationCanceledException(token);
                    attempt.Cancel();
                    client.Disconnect();
                    cancellationToken.ThrowIfCancellationRequested();
                    throw new TimeoutException($"Connection timed out after {timeoutSeconds} seconds.");
                }
                await connectTask;
                if (disposing || version != connectionVersion) throw new OperationCanceledException(token);
                token.ThrowIfCancellationRequested();
                SetState(NetworkState.Connected);
            }
            catch
            {
                if (!disposing && version == connectionVersion)
                {
                    client.Disconnect();
                    SetState(NetworkState.Faulted);
                }
                throw;
            }
            finally
            {
                if (pendingConnection == attempt) pendingConnection = null;
                attempt.Cancel();
                attempt.Dispose();
            }
        }

        private static async Task ObserveConnectionAsync(Task task)
        {
            try { await task; }
            catch { /* The timeout/cancellation has already been reported to the caller. */ }
        }

        public Task ReconnectAsync(int timeoutSeconds = 8, CancellationToken cancellationToken = default)
        {
            if (disposing) throw new ObjectDisposedException(nameof(NetworkService));
            if (State == NetworkState.Connecting) throw new InvalidOperationException("A connection attempt is already running.");
            if (string.IsNullOrEmpty(lastHost) || lastPort <= 0)
                throw new InvalidOperationException("No previous endpoint is available for reconnect.");
            CancelConnection();
            return ConnectAsync(lastHost, lastPort, timeoutSeconds, cancellationToken);
        }

        public void Send(LegacyTcpMessage message)
        {
            if (State != NetworkState.Connected) throw new InvalidOperationException($"Cannot send while network state is {State}.");
            byte[] payload = message.SnapshotPayload();
            PacketObserved?.Invoke(new ProtocolPacketTrace(ProtocolPacketDirection.Sent, message.OutgoingCommand, payload, FrameOutgoing(payload), DateTime.UtcNow));
            client.Send(message);
        }

        public void Tick()
        {
            if (disposing) return;
            client.Pump((command, message, error) =>
            {
                if (command != 0)
                {
                    int version = connectionVersion;
                    byte[] body = message.SnapshotPayload();
                    PacketObserved?.Invoke(new ProtocolPacketTrace(ProtocolPacketDirection.Received, command, body, FrameIncoming(command, body), DateTime.UtcNow));
                    if (!disposing && version == connectionVersion) PacketReceived?.Invoke(command, message);
                    return;
                }
                if (disposing) return;
                client.Disconnect();
                SetState(NetworkState.Disconnected);
                Disconnected?.Invoke(error?.Message ?? "The game server closed the connection.");
            });
        }

        public void Disconnect(string reason = "Disconnected by client.")
        {
            if (disposing) return;
            bool changed = State != NetworkState.Disconnected;
            CancelConnection();
            SetState(NetworkState.Disconnected);
            if (changed && !disposing)
                Disconnected?.Invoke(reason);
        }

        public void Dispose()
        {
            if (disposing) return;
            disposing = true;
            CancelConnection();
            client.Dispose();
            SetState(NetworkState.Idle);
        }

        private void CancelConnection()
        {
            connectionVersion++;
            pendingConnection?.Cancel();
            client.Disconnect();
        }

        private void SetState(NetworkState state)
        {
            if (State == state) return;
            State = state;
            if (!disposing) StateChanged?.Invoke(state);
        }

        private static byte[] FrameOutgoing(byte[] payload)
        {
            if (payload == null || payload.Length < 2) return Array.Empty<byte>();
            int bodyLength = payload.Length - 2;
            byte[] packet = new byte[payload.Length + 4];
            Buffer.BlockCopy(BitConverter.GetBytes(bodyLength), 0, packet, 0, 4);
            Buffer.BlockCopy(payload, 0, packet, 4, payload.Length);
            return packet;
        }

        private static byte[] FrameIncoming(ushort command, byte[] body)
        {
            body = body ?? Array.Empty<byte>();
            byte[] packet = new byte[body.Length + 6];
            Buffer.BlockCopy(BitConverter.GetBytes(body.Length), 0, packet, 0, 4);
            Buffer.BlockCopy(BitConverter.GetBytes(command), 0, packet, 4, 2);
            Buffer.BlockCopy(body, 0, packet, 6, body.Length);
            return packet;
        }
    }
}
