namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public bool IsAutomation() => services?.Options.Automation ?? false;
        public bool HasCommandLineFlag(string flag) => services?.Options.HasFlag(flag) ?? false;
        public uint GetLocalUserId() => services?.Config.LocalUserId ?? 1;
        public string GetLoginSignature() => string.IsNullOrWhiteSpace(loginSignature) ? "local" : loginSignature;
        public string GetGameHost() => services?.Config.GameHost ?? "127.0.0.1";
        public int GetGamePort() => services?.Config.GamePort ?? 8711;
        public string GetRoleName() => loginPresenter?.RoleName ?? string.Empty;
        public int GetRoleSex() => loginPresenter?.SelectedSex ?? 1;
        public uint GetPlayerRoleId() => services?.Player.RoleId ?? 0;
        public uint GetValidationRoleId() => GetPlayerRoleId() != 0 ? GetPlayerRoleId() : validationRoleIdSnapshot;
        public bool IsFormationPopupOpen => formationPopupView?.GameObject.activeSelf == true;
    }
}
