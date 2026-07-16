namespace ProjectX.Core
{
    public sealed class AppConfig
    {
        public string GameHost { get; set; } = "127.0.0.1";
        public int GamePort { get; set; } = 8711;
        public int ConnectTimeoutSeconds { get; set; } = 8;
        public bool AutoReconnect { get; set; } = true;
        public int MaxReconnectAttempts { get; set; } = 3;
        public int ReconnectDelayMilliseconds { get; set; } = 1200;
        public uint LocalUserId { get; set; } = 1;

        public static AppConfig LocalTest(AppLaunchOptions options = null)
        {
            options = options ?? AppLaunchOptions.Current();
            return new AppConfig { LocalUserId = options.LocalUserId };
        }
    }
}
