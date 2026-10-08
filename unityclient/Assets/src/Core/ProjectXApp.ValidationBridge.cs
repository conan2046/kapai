#if UNITY_EDITOR || DEVELOPMENT_BUILD
using ProjectX.Foundation;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp : IRuntimeValidationEntrypoints
    {
        void IRuntimeValidationEntrypoints.BeginFishValidation() => BeginFishValidation();
        void IRuntimeValidationEntrypoints.BeginJingJieValidation() => BeginJingJieValidation();
        void IRuntimeValidationEntrypoints.BeginLoginClosureValidation() => BeginLoginClosureValidation();
        string[] IRuntimeValidationEntrypoints.GetFailedValidationSemanticAssertions() => GetFailedValidationSemanticAssertions();
        string[] IRuntimeValidationEntrypoints.GetPassedValidationSemanticKeys() => GetPassedValidationSemanticKeys();
        uint IRuntimeValidationEntrypoints.GetValidationRoleId() => GetValidationRoleId();
        bool IRuntimeValidationEntrypoints.InvokeHeroCloseForValidation() => InvokeHeroCloseForValidation();
        bool IRuntimeValidationEntrypoints.InvokeHeroEntryForReconnectValidation() => InvokeHeroEntryForReconnectValidation();
        void IRuntimeValidationEntrypoints.InvokeLoginForValidation() => InvokeLoginForValidation();
        void IRuntimeValidationEntrypoints.InvokeRoleCreateForValidation() => InvokeRoleCreateForValidation();
        bool IRuntimeValidationEntrypoints.RunHeroG4FromCurrentSnapshotForReconnectValidation()
            => RunHeroG4FromCurrentSnapshotForReconnectValidation();
        void IRuntimeValidationEntrypoints.RunSettingsAccountValidation() => RunSettingsAccountValidation();
        void IRuntimeValidationEntrypoints.RunSettingsValidation() => RunSettingsValidation();
    }
}
#endif
