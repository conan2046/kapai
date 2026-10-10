using System;
using System.Threading;
using ProjectX.Diagnostics;
using ProjectX.Network;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private CancellationTokenSource connectionOperations = new CancellationTokenSource();

        private void InvalidateConnectionOperations()
        {
            CancellationTokenSource previous = connectionOperations;
            connectionOperations = new CancellationTokenSource();
            previous.Cancel();
            previous.Dispose();
            autoReconnectRunning = false;
        }

        private bool OwnsConnectionOperation(CancellationToken token)
            => this && !applicationDestroyed && !exitRequested && services != null && !services.IsDisposed
                && token == connectionOperations.Token && !token.IsCancellationRequested;

        public async void Connect(string host, int port)
        {
            if (applicationDestroyed || exitRequested || services == null || services.IsDisposed
                || services.Network.State == NetworkState.Connecting) return;
            InvalidateConnectionOperations();
            CancellationToken token = connectionOperations.Token;
            try
            {
                ShowLoading("connect", "正在连接服务器…", 20f);
                disconnectReason = null;
                services.State.Change(AppState.Connecting, $"{host}:{port}");
                await services.Network.ConnectAsync(host, port, services.Config.ConnectTimeoutSeconds, token);
                if (!OwnsConnectionOperation(token) || !services.Network.IsConnected) return;
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Connected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected");
            }
            catch (Exception exception)
            {
                if (!OwnsConnectionOperation(token)) return;
                HideLoading("connect");
                disconnectReason = exception.Message;
                ShowLoginConnectionFailure(exception is TimeoutException);
            }
        }

        public async void Reconnect()
        {
            if (applicationDestroyed || exitRequested || services == null || services.IsDisposed
                || services.Network.State == NetworkState.Connecting) return;
            InvalidateConnectionOperations();
            CancellationToken token = connectionOperations.Token;
            try
            {
                mainHudPresenter?.BeginReconnectChatSummary();
                ShowLoading("reconnect", "正在重新连接…", 25f);
                disconnectReason = null;
                await services.Network.ReconnectAsync(services.Config.ConnectTimeoutSeconds, token);
                if (!OwnsConnectionOperation(token) || !services.Network.IsConnected) return;
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Reconnected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected.AfterReconnect");
            }
            catch (Exception exception)
            {
                if (!OwnsConnectionOperation(token)) return;
                HideLoading("reconnect");
                disconnectReason = exception.Message;
                SetStatus($"Reconnect failed: {exception.Message}");
            }
        }

        public void Send(LegacyTcpMessage message)
        {
            try
            {
                if (message.OutgoingCommand == 88) gameNoticeRequested = true;
                services.ProtocolRegistry.TrackSend(message.OutgoingCommand);
                services.Network.Send(message);
            }
            catch (Exception exception)
            {
                if (singlePlayerTitleEnabled)
                    ClientLog.Error("SinglePlayer", "Protocol send failed", exception.Message);
                else
                    Fail($"Send failed: {exception.Message}");
            }
        }

        public void SendUntracked(LegacyTcpMessage message)
        {
            try
            {
                ClientLog.Info("Protocol", "SEND optional HUD state",
                    $"cmd={message.OutgoingCommand} untracked");
                services.Network.Send(message);
            }
            catch (Exception exception)
            {
                if (singlePlayerTitleEnabled)
                    ClientLog.Error("SinglePlayer", "Optional protocol send failed", exception.Message);
                else
                    Fail($"Send failed: {exception.Message}");
            }
        }
    }
}
