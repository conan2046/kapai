using System;
using ProjectX.Diagnostics;

namespace ProjectX.Core
{
    public enum AppState
    {
        Booting,
        Login,
        Connecting,
        LoadingRole,
        Main,
        Disconnected,
        ShuttingDown,
        Failed
    }

    public sealed class AppStateMachine
    {
        public AppState Current { get; private set; } = AppState.Booting;
        public event Action<AppState, AppState, string> Changed;

        public void Change(AppState next, string reason)
        {
            if (Current == next) return;
            AppState previous = Current;
            Current = next;
            ClientLog.Info("Core", $"App state {previous} -> {next}", reason);
            Changed?.Invoke(previous, next, reason ?? string.Empty);
        }
    }
}
