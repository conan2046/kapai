using System;
using System.Collections.Generic;

namespace ProjectX.Core
{
    public sealed class AppLaunchOptions
    {
        private readonly HashSet<string> flags;

        private AppLaunchOptions(HashSet<string> flags, uint localUserId, uint teamPeerRoleId, uint drawIsolationUserId,
            uint worldIsolationUserId, uint loginCreateUserId, uint loginIsolationUserId, uint playerHudIsolationUserId)
        {
            this.flags = flags;
            LocalUserId = localUserId;
            TeamPeerRoleId = teamPeerRoleId;
            DrawIsolationUserId = drawIsolationUserId;
            WorldIsolationUserId = worldIsolationUserId;
            LoginCreateUserId = loginCreateUserId;
            LoginIsolationUserId = loginIsolationUserId;
            PlayerHudIsolationUserId = playerHudIsolationUserId;
        }

        public uint LocalUserId { get; }
        public uint TeamPeerRoleId { get; }
        public uint DrawIsolationUserId { get; }
        public uint WorldIsolationUserId { get; }
        public uint LoginCreateUserId { get; }
        public uint LoginIsolationUserId { get; }
        public uint PlayerHudIsolationUserId { get; }
        public bool Automation => HasFlag("-projectXAutomation");
        public bool ManualReconnectValidation => HasFlag("-projectXManualReconnectValidation");
        public bool DrawClosureValidation => HasFlag("-projectXDrawClosureValidation");
        public bool WorldBattleValidation => HasFlag("-projectXWorldBattleValidation");
        public bool LoginClosureValidation => HasFlag("-projectXLoginClosureValidation");
        public bool PlayerHudValidation => HasFlag("-projectXPlayerHudValidation");
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
            uint loginCreateUserId = 0;
            uint loginIsolationUserId = 0;
            uint playerHudIsolationUserId = 0;
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
                const string loginCreatePrefix = "-projectXLoginCreateUserId=";
                if (argument.StartsWith(loginCreatePrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(loginCreatePrefix.Length), out uint loginCreateValue)
                    && loginCreateValue > 0)
                    loginCreateUserId = loginCreateValue;
                const string loginIsolationPrefix = "-projectXLoginIsolationUserId=";
                if (argument.StartsWith(loginIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(loginIsolationPrefix.Length), out uint loginIsolationValue)
                    && loginIsolationValue > 0)
                    loginIsolationUserId = loginIsolationValue;
                const string playerHudIsolationPrefix = "-projectXPlayerHudIsolationUserId=";
                if (argument.StartsWith(playerHudIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(playerHudIsolationPrefix.Length), out uint playerHudIsolationValue)
                    && playerHudIsolationValue > 0)
                    playerHudIsolationUserId = playerHudIsolationValue;
            }
            return new AppLaunchOptions(parsedFlags, localUserId, teamPeerRoleId, drawIsolationUserId, worldIsolationUserId,
                loginCreateUserId, loginIsolationUserId, playerHudIsolationUserId);
        }

        public static AppLaunchOptions Current() => Parse(Environment.GetCommandLineArgs());
    }
}
