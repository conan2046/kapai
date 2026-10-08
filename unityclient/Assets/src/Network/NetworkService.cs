using System;
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

        public event Action<ushort, LegacyTcpMessage> PacketReceived;
        public event Action<ProtocolPacketTrace> PacketObserved;
        public event Action<NetworkState> StateChanged;
        public event Action<string> Disconnected;

        public NetworkState State { get; private set; } = NetworkState.Idle;
        public bool IsConnected => State == NetworkState.Connected && client.IsConnected;

        public async Task ConnectAsync(string host, int port, int timeoutSeconds = 8)
        {
            if (State == NetworkState.Connecting) throw new InvalidOperationException("A connection attempt is already running.");
            lastHost = host;
            lastPort = port;
            SetState(NetworkState.Connecting);
            try
            {
                Task connectTask = client.ConnectAsync(host, port);
                Task completed = await Task.WhenAny(connectTask, Task.Delay(TimeSpan.FromSeconds(timeoutSeconds)));
                if (completed != connectTask)
                {
                    client.Disconnect();
                    throw new TimeoutException($"Connection timed out after {timeoutSeconds} seconds.");
                }
                await connectTask;
                SetState(NetworkState.Connected);
            }
            catch
            {
                SetState(NetworkState.Faulted);
                throw;
            }
        }

        public Task ReconnectAsync(int timeoutSeconds = 8)
        {
            if (string.IsNullOrEmpty(lastHost) || lastPort <= 0)
                throw new InvalidOperationException("No previous endpoint is available for reconnect.");
            client.Disconnect();
            return ConnectAsync(lastHost, lastPort, timeoutSeconds);
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
            client.Pump((command, message, error) =>
            {
                if (command != 0)
                {
                    byte[] body = message.SnapshotPayload();
                    PacketObserved?.Invoke(new ProtocolPacketTrace(ProtocolPacketDirection.Received, command, body, FrameIncoming(command, body), DateTime.UtcNow));
                    PacketReceived?.Invoke(command, message);
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
            bool changed = State != NetworkState.Disconnected;
            client.Disconnect();
            SetState(NetworkState.Disconnected);
            if (changed && !disposing)
                Disconnected?.Invoke(reason);
        }

        public void Dispose()
        {
            disposing = true;
            client.Dispose();
            SetState(NetworkState.Idle);
        }

        private void SetState(NetworkState state)
        {
            if (State == state) return;
            State = state;
            StateChanged?.Invoke(state);
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
