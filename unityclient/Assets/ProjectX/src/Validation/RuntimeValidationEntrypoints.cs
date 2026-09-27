#if UNITY_EDITOR || DEVELOPMENT_BUILD
using System;
using ProjectX.Foundation;

namespace ProjectX.Validation
{
    /// <summary>Validation assembly facade for Editor automation; runtime never calls back into this assembly.</summary>
    public static class RuntimeValidationEntrypoints
    {
        public static void BeginFishValidation(IRuntimeValidationEntrypoints host) => host?.BeginFishValidation();
        public static void BeginJingJieValidation(IRuntimeValidationEntrypoints host) => host?.BeginJingJieValidation();
        public static void BeginLoginClosureValidation(IRuntimeValidationEntrypoints host) => host?.BeginLoginClosureValidation();
        public static string[] GetFailedValidationSemanticAssertions(IRuntimeValidationEntrypoints host)
            => host?.GetFailedValidationSemanticAssertions() ?? Array.Empty<string>();
        public static string[] GetPassedValidationSemanticKeys(IRuntimeValidationEntrypoints host)
            => host?.GetPassedValidationSemanticKeys() ?? Array.Empty<string>();
        public static uint GetValidationRoleId(IRuntimeValidationEntrypoints host)
            => host?.GetValidationRoleId() ?? 0;
        public static bool InvokeHeroCloseForValidation(IRuntimeValidationEntrypoints host)
            => host != null && host.InvokeHeroCloseForValidation();
        public static bool InvokeHeroEntryForReconnectValidation(IRuntimeValidationEntrypoints host)
            => host != null && host.InvokeHeroEntryForReconnectValidation();
        public static void InvokeLoginForValidation(IRuntimeValidationEntrypoints host) => host?.InvokeLoginForValidation();
        public static void InvokeRoleCreateForValidation(IRuntimeValidationEntrypoints host) => host?.InvokeRoleCreateForValidation();
        public static bool RunHeroG4FromCurrentSnapshotForReconnectValidation(IRuntimeValidationEntrypoints host)
            => host != null && host.RunHeroG4FromCurrentSnapshotForReconnectValidation();
        public static void RunSettingsAccountValidation(IRuntimeValidationEntrypoints host) => host?.RunSettingsAccountValidation();
        public static void RunSettingsValidation(IRuntimeValidationEntrypoints host) => host?.RunSettingsValidation();
    }
}
#endif
