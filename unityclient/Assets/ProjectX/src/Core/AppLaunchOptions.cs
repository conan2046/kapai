using System;
using System.Collections.Generic;

namespace ProjectX.Core
{
    public sealed class AppLaunchOptions
    {
        private readonly HashSet<string> flags;

        private AppLaunchOptions(HashSet<string> flags, uint localUserId)
        {
            this.flags = flags;
            LocalUserId = localUserId;
        }

        public uint LocalUserId { get; }
        public bool Automation => HasFlag("-projectXAutomation");
        public bool ManualReconnectValidation => HasFlag("-projectXManualReconnectValidation");
        public bool UseItemValidation => HasFlag("-projectXUseItemValidation");
        public bool SettingsValidation => HasFlag("-projectXSettingsValidation");
        public bool TaskValidation => HasFlag("-projectXTaskValidation");

        public bool HasFlag(string flag) => !string.IsNullOrEmpty(flag) && flags.Contains(flag);

        public static AppLaunchOptions Parse(IEnumerable<string> arguments)
        {
            var parsedFlags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            uint localUserId = 1;
            foreach (string raw in arguments ?? Array.Empty<string>())
            {
                string argument = raw ?? string.Empty;
                parsedFlags.Add(argument);
                const string userPrefix = "-projectXUserId=";
                if (argument.StartsWith(userPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(userPrefix.Length), out uint value)
                    && value > 0)
                    localUserId = value;
            }
            return new AppLaunchOptions(parsedFlags, localUserId);
        }

        public static AppLaunchOptions Current() => Parse(Environment.GetCommandLineArgs());
    }
}
