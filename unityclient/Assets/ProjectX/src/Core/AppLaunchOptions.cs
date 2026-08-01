using System;
using System.Collections.Generic;

namespace ProjectX.Core
{
    public sealed class AppLaunchOptions
    {
        private readonly HashSet<string> flags;

        private AppLaunchOptions(HashSet<string> flags, uint localUserId, uint teamPeerRoleId, uint drawIsolationUserId,
            uint worldIsolationUserId)
        {
            this.flags = flags;
            LocalUserId = localUserId;
            TeamPeerRoleId = teamPeerRoleId;
            DrawIsolationUserId = drawIsolationUserId;
            WorldIsolationUserId = worldIsolationUserId;
        }

        public uint LocalUserId { get; }
        public uint TeamPeerRoleId { get; }
        public uint DrawIsolationUserId { get; }
        public uint WorldIsolationUserId { get; }
        public bool Automation => HasFlag("-projectXAutomation");
        public bool ManualReconnectValidation => HasFlag("-projectXManualReconnectValidation");
        public bool DrawClosureValidation => HasFlag("-projectXDrawClosureValidation");
        public bool WorldBattleValidation => HasFlag("-projectXWorldBattleValidation");
        public bool UseItemValidation => HasFlag("-projectXUseItemValidation");
        public bool SettingsValidation => HasFlag("-projectXSettingsValidation");
        public bool TaskValidation => HasFlag("-projectXTaskValidation") || HasFlag("-projectXTaskG4Validation");
        public bool WelfareValidation => HasFlag("-projectXWelfareValidation");

        public bool HasFlag(string flag) => !string.IsNullOrEmpty(flag) && flags.Contains(flag);

        public static AppLaunchOptions Parse(IEnumerable<string> arguments)
        {
            var parsedFlags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            uint localUserId = 1;
            uint teamPeerRoleId = 0;
            uint drawIsolationUserId = 0;
            uint worldIsolationUserId = 0;
            foreach (string raw in arguments ?? Array.Empty<string>())
            {
                string argument = raw ?? string.Empty;
                parsedFlags.Add(argument);
                const string userPrefix = "-projectXUserId=";
                if (argument.StartsWith(userPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(userPrefix.Length), out uint value)
                    && value > 0)
                    localUserId = value;
                const string teamPeerPrefix = "-projectXTeamPeerRoleId=";
                if (argument.StartsWith(teamPeerPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(teamPeerPrefix.Length), out uint peerValue)
                    && peerValue > 0)
                    teamPeerRoleId = peerValue;
                const string drawIsolationPrefix = "-projectXDrawIsolationUserId=";
                if (argument.StartsWith(drawIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(drawIsolationPrefix.Length), out uint isolationValue)
                    && isolationValue > 0)
                    drawIsolationUserId = isolationValue;
                const string worldIsolationPrefix = "-projectXWorldIsolationUserId=";
                if (argument.StartsWith(worldIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(worldIsolationPrefix.Length), out uint worldIsolationValue)
                    && worldIsolationValue > 0)
                    worldIsolationUserId = worldIsolationValue;
            }
            return new AppLaunchOptions(parsedFlags, localUserId, teamPeerRoleId, drawIsolationUserId, worldIsolationUserId);
        }

        public static AppLaunchOptions Current() => Parse(Environment.GetCommandLineArgs());
    }
}
