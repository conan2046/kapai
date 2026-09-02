using System;
using System.Collections.Generic;

namespace ProjectX.Core
{
    public sealed class AppLaunchOptions
    {
        private readonly HashSet<string> flags;

        private AppLaunchOptions(HashSet<string> flags, uint localUserId, uint teamPeerRoleId, uint drawIsolationUserId,
            uint worldIsolationUserId, uint loginCreateUserId, uint loginIsolationUserId, uint playerHudIsolationUserId,
            uint gameplayLockedUserId, uint gameplayIsolationUserId, uint fengShenStoryIsolationUserId,
            uint staminaClaimIsolationUserId, uint staminaClaimOverCapUserId)
        {
            this.flags = flags;
            LocalUserId = localUserId;
            TeamPeerRoleId = teamPeerRoleId;
            DrawIsolationUserId = drawIsolationUserId;
            WorldIsolationUserId = worldIsolationUserId;
            LoginCreateUserId = loginCreateUserId;
            LoginIsolationUserId = loginIsolationUserId;
            PlayerHudIsolationUserId = playerHudIsolationUserId;
            GameplayLockedUserId = gameplayLockedUserId;
            GameplayIsolationUserId = gameplayIsolationUserId;
            FengShenStoryIsolationUserId = fengShenStoryIsolationUserId;
            StaminaClaimIsolationUserId = staminaClaimIsolationUserId;
            StaminaClaimOverCapUserId = staminaClaimOverCapUserId;
        }

        public uint LocalUserId { get; }
        public uint TeamPeerRoleId { get; }
        public uint DrawIsolationUserId { get; }
        public uint WorldIsolationUserId { get; }
        public uint LoginCreateUserId { get; }
        public uint LoginIsolationUserId { get; }
        public uint PlayerHudIsolationUserId { get; }
        public uint GameplayLockedUserId { get; }
        public uint GameplayIsolationUserId { get; }
        public uint FengShenStoryIsolationUserId { get; }
        public uint StaminaClaimIsolationUserId { get; }
        public uint StaminaClaimOverCapUserId { get; }
        public bool Automation => HasFlag("-projectXAutomation");
        public bool ManualReconnectValidation => HasFlag("-projectXManualReconnectValidation");
        public bool ScenarioManagedReconnect => HasFlag("-projectXScenarioManagedReconnect");
        public bool DrawClosureValidation => HasFlag("-projectXDrawClosureValidation");
        public bool WorldG3Validation => HasFlag("-projectXWorldG3Validation");
        public bool WorldBattleValidation => HasFlag("-projectXWorldBattleValidation") || WorldG3Validation;
        public bool LoginClosureValidation => HasFlag("-projectXLoginClosureValidation");
        public bool PlayerHudValidation => HasFlag("-projectXPlayerHudValidation");
        public bool UseItemValidation => HasFlag("-projectXUseItemValidation");
        public bool SettingsValidation => HasFlag("-projectXSettingsValidation");
        public bool TaskValidation => HasFlag("-projectXTaskValidation") || HasFlag("-projectXTaskG4Validation");
        public bool WelfareValidation => HasFlag("-projectXWelfareValidation");
        public bool GameplayValidation => HasFlag("-projectXGameplayValidation");
        public bool FengShenStoryValidation => HasFlag("-projectXFengShenStoryValidation");
        public bool BattleFengShenStoryValidation => HasFlag("-projectXBattleFengShenStoryValidation");
        public bool StaminaClaimValidation => HasFlag("-projectXStaminaClaimValidation");
        public bool HeroCultivationG3Validation => HasFlag("-projectXHeroCultivationG3Validation");
        public bool EnhanceMasterG3Validation => HasFlag("-projectXEnhanceMasterG3Validation");

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
            uint gameplayLockedUserId = 0;
            uint gameplayIsolationUserId = 0;
            uint fengShenStoryIsolationUserId = 0;
            uint staminaClaimIsolationUserId = 0;
            uint staminaClaimOverCapUserId = 0;
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
                const string gameplayLockedPrefix = "-projectXGameplayLockedUserId=";
                if (argument.StartsWith(gameplayLockedPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(gameplayLockedPrefix.Length), out uint gameplayLockedValue)
                    && gameplayLockedValue > 0)
                    gameplayLockedUserId = gameplayLockedValue;
                const string gameplayIsolationPrefix = "-projectXGameplayIsolationUserId=";
                if (argument.StartsWith(gameplayIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(gameplayIsolationPrefix.Length), out uint gameplayIsolationValue)
                    && gameplayIsolationValue > 0)
                    gameplayIsolationUserId = gameplayIsolationValue;
                const string fengShenStoryIsolationPrefix = "-projectXFengShenStoryIsolationUserId=";
                if (argument.StartsWith(fengShenStoryIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(fengShenStoryIsolationPrefix.Length), out uint fengShenStoryIsolationValue)
                    && fengShenStoryIsolationValue > 0)
                    fengShenStoryIsolationUserId = fengShenStoryIsolationValue;
                const string staminaClaimIsolationPrefix = "-projectXStaminaClaimIsolationUserId=";
                if (argument.StartsWith(staminaClaimIsolationPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(staminaClaimIsolationPrefix.Length), out uint staminaClaimIsolationValue)
                    && staminaClaimIsolationValue > 0)
                    staminaClaimIsolationUserId = staminaClaimIsolationValue;
                const string staminaClaimOverCapPrefix = "-projectXStaminaClaimOverCapUserId=";
                if (argument.StartsWith(staminaClaimOverCapPrefix, StringComparison.OrdinalIgnoreCase)
                    && uint.TryParse(argument.Substring(staminaClaimOverCapPrefix.Length), out uint staminaClaimOverCapValue)
                    && staminaClaimOverCapValue > 0)
                    staminaClaimOverCapUserId = staminaClaimOverCapValue;
            }
            return new AppLaunchOptions(parsedFlags, localUserId, teamPeerRoleId, drawIsolationUserId, worldIsolationUserId,
                loginCreateUserId, loginIsolationUserId, playerHudIsolationUserId,
                gameplayLockedUserId, gameplayIsolationUserId, fengShenStoryIsolationUserId,
                staminaClaimIsolationUserId, staminaClaimOverCapUserId);
        }

        public static AppLaunchOptions Current() => Parse(Environment.GetCommandLineArgs());
    }
}
