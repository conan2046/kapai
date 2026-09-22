using System;
using ProjectX.Diagnostics;
using ProjectX.Network;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public async void Connect(string host, int port)
        {
            try
            {
                ShowLoading("connect", "正在连接服务器…", 20f);
                disconnectReason = null;
                services.State.Change(AppState.Connecting, $"{host}:{port}");
                await services.Network.ConnectAsync(host, port, services.Config.ConnectTimeoutSeconds);
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Connected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected");
            }
            catch (Exception exception)
            {
                HideLoading("connect");
                disconnectReason = exception.Message;
                ShowLoginConnectionFailure(exception is TimeoutException);
            }
        }

        public async void Reconnect()
        {
            if (services == null || services.Network.State == NetworkState.Connecting) return;
            try
            {
                mainHudPresenter?.BeginReconnectChatSummary();
                ShowLoading("reconnect", "正在重新连接…", 25f);
                disconnectReason = null;
                await services.Network.ReconnectAsync(services.Config.ConnectTimeoutSeconds);
                reconnectAttempts = 0;
                services.State.Change(AppState.LoadingRole, "Reconnected; waiting for login handshake");
                CallLua(onConnected, "Login.OnConnected.AfterReconnect");
            }
            catch (Exception exception)
            {
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
