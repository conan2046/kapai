#if UNITY_EDITOR || DEVELOPMENT_BUILD
namespace ProjectX.Foundation
{
    /// <summary>Development-only hooks that an external validation runner may request from the runtime host.</summary>
    public interface IRuntimeValidationEntrypoints
    {
        void BeginFishValidation();
        void BeginJingJieValidation();
        void BeginLoginClosureValidation();
        string[] GetFailedValidationSemanticAssertions();
        string[] GetPassedValidationSemanticKeys();
        uint GetValidationRoleId();
        bool InvokeHeroCloseForValidation();
        bool InvokeHeroEntryForReconnectValidation();
        void InvokeLoginForValidation();
        void InvokeRoleCreateForValidation();
        bool RunHeroG4FromCurrentSnapshotForReconnectValidation();
        void RunSettingsAccountValidation();
        void RunSettingsValidation();
    }
}
#endif
