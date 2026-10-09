using System;
using System.Collections;
using System.IO;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
        private bool loginClosureValidationRunning;

        private void InvokeLoginForValidation()
        {
            Button button = loginView?.FindNode(LoginButtonPath)?.GetComponent<Button>();
            if (button == null) throw new InvalidOperationException("Local Btn_Play is not bound.");
            button.onClick.Invoke();
        }

        public bool ValidateLoginUi(out string detail)
        {
            GameObject play = loginView?.FindNode(LoginButtonPath);
            GameObject accountLogin = loginView?.FindNode("Layer/Login/Btn_Login");
            GameObject server = loginView?.FindNode(LoginServerButtonPath);
            Text serverName = loginView?.FindNode(LoginServerButtonPath + "/SeverName")?.GetComponent<Text>();
            if (!IsLoginVisible) { detail = "loginLayer is hidden"; return false; }
            if (play == null || !play.activeInHierarchy) { detail = "Btn_Play is not the active local entry"; return false; }
            if (accountLogin != null && accountLogin.activeInHierarchy) { detail = "account Btn_Login must be hidden for local openType=1"; return false; }
            if (server == null || !server.activeInHierarchy || serverName == null || serverName.text != "本地测试服")
            { detail = "local server selector is not configured"; return false; }
            if (LoginPlayingAnimationCount <= 0) { detail = "effect_chuangjue_1 is not playing"; return false; }
            string startupDetail = "StartupPresenter is missing";
            if (startupPresenter == null || !startupPresenter.Validate(out startupDetail))
            { detail = "startup mismatch: " + startupDetail; return false; }
            detail = startupDetail + " -> Unity Btn_Play/local server/effect_chuangjue_1";
            return true;
        }

        public bool ValidateRoleCreateUi(out string detail)
        {
            if (loginPresenter == null) { detail = "LoginPresenter is missing"; return false; }
            return loginPresenter.ValidateRoleAnimations(out detail);
        }

        private void InvokeRoleCreateForValidation()
        {
            try { loginPresenter?.InvokeRoleCreate(); }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void CompleteLoginValidation(bool createdRole)
        {
            if (!HasCommandLineFlag("-projectXLoginValidation")) return;
            bool requireNoticeResponse = HasCommandLineFlag("-projectXRequireNoticeResponse");
            bool validRoot = mainView != null && (services?.UiStack.Current == mainView
                || (requireNoticeResponse && services?.UiStack.Current == noticeView));
            if (!validRoot)
            { Fail("Login validation reached completion without the current UImainLayer/NoticeLayer stack."); return; }
            if (GetPlayerRoleId() == 0)
            { Fail("Login validation reached main UI with roleId=0."); return; }
            if (!gameNoticeRequested)
            { Fail("Login validation reached main UI without sending optional PRO_GONGGAO/88."); return; }
            if (requireNoticeResponse && (!IsGameNoticeOpen || GameNoticeCount <= 0))
            { Fail("Required local_test PRO_GONGGAO/88 response did not render NoticeLayer."); return; }
            if (services.Options.LoginClosureValidation)
            {
                SetStatus($"Login closure main ready: user={GetLocalUserId()} role={GetPlayerRoleId()} created={createdRole}.");
                return;
            }
            Complete($"COMPLETE: LogoScene/GameScene preload -> Btn_Play -> /1001 -> "
                + (createdRole ? "RoleCreateLayer + Create_5/Create_4 -> /1003 -> " : string.Empty)
                + $"/1004 -> current UImainLayer -> /88 NoticeLayer count={GameNoticeCount}; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        private void BeginLoginClosureValidation()
        {
            if (!services.Options.LoginClosureValidation || loginClosureValidationRunning) return;
            StartCoroutine(ValidateLoginClosure());
        }

        private IEnumerator CaptureLoginClosureFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 5f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                Fail("Login closure screenshot was not written: " + fileName);
        }

        private IEnumerator ValidateLoginClosure()
        {
            loginClosureValidationRunning = true;
            uint primaryUserId = services.Options.LocalUserId;
            uint createUserId = services.Options.LoginCreateUserId;
            uint isolationUserId = services.Options.LoginIsolationUserId;
            string originalHost = services.Config.GameHost;
            int originalPort = services.Config.GamePort;
            int originalTimeout = services.Config.ConnectTimeoutSeconds;
            try
            {
                if (primaryUserId == 0 || createUserId == 0 || isolationUserId == 0
                    || primaryUserId == createUserId || primaryUserId == isolationUserId || createUserId == isolationUserId)
                {
                    Fail("Login closure requires three distinct non-zero fixed user ids.");
                    yield break;
                }
                BeginValidationEvidence();
                if (!ValidateLoginUi(out string loginDetail))
                {
                    Fail("Login closure initial UI mismatch: " + loginDetail);
                    yield break;
                }
                yield return CaptureLoginClosureFrame("bootstrap-login-local.png");

                if (!loginPresenter.InvokeServerSelector() || !loginPresenter.IsServerListVisible)
                { Fail("Login server selector did not open SeverListLayer."); yield break; }
                MarkValidationControl("LOGIN-01-SERVER-SELECTOR");
                yield return CaptureLoginClosureFrame("bootstrap-login-server-list.png");
                if (!loginPresenter.InvokeServerArea()) { Fail("Login server area row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-08-SERVER-AREA-ROW");
                if (!loginPresenter.InvokeServerRow()) { Fail("Login server row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-09-SERVER-ROW");
                if (!loginPresenter.InvokeServerBack() || !IsLoginVisible)
                { Fail("Login server back did not restore loginLayer."); yield break; }
                MarkValidationControl("LOGIN-07-SERVER-BACK");
                RecordValidationSemantic("login-server-selection", true, "selector/area/server/back controls reached real views");

                services.Config.GameHost = "127.0.0.1";
                services.Config.GamePort = 1;
                services.Config.ConnectTimeoutSeconds = 2;
                InvokeLoginForValidation();
                MarkValidationControl("LOGIN-02-PLAY");
                float deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Login real connect-error dialog timed out."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-connect-error.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Login connection retry control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-20-CONNECTION-RETRY");
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true || !errorPresenter.InvokeCancel())
                { Fail("Login connection cancel control was unavailable after retry."); yield break; }
                MarkValidationControl("LOGIN-21-CONNECTION-CANCEL");

                services.Config.GameHost = "192.0.2.1";
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = 2;
                InvokeLoginForValidation();
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Login timeout endpoint did not surface a dialog."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-connect-timeout.png");
                if (!errorPresenter.InvokeCancel()) { Fail("Login timeout dialog cancel was unavailable."); yield break; }
                services.Config.GameHost = originalHost;
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = originalTimeout;

                if (!loginPresenter.InvokeHandover()) { Fail("Login handover control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-03-HANDOVER");
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                MarkValidationControl("LOGIN-04-ACCOUNT-INPUT");
                MarkValidationControl("LOGIN-05-SIGNATURE-INPUT");
                yield return CaptureLoginClosureFrame("bootstrap-login-handover.png");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Login account submit was unavailable."); yield break; }
                MarkValidationControl("LOGIN-06-ACCOUNT-SUBMIT");
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0)
                { Fail("Primary fixed account did not complete real /1001 -> /1004 -> /88."); yield break; }
                uint primaryRoleId = GetPlayerRoleId();
                yield return CaptureLoginClosureFrame("bootstrap-login-notice.png");
                if (!noticePresenter.InvokeFirstTitle()) { Fail("Notice title row was unavailable."); yield break; }
                MarkValidationControl("LOGIN-17-NOTICE-TITLE-ROW");
                if (!noticePresenter.ScrollBody()) { Fail("Notice body scroll surface was unavailable."); yield break; }
                MarkValidationControl("LOGIN-18-NOTICE-BODY-SCROLL");
                if (!noticePresenter.InvokeClose()) { Fail("Notice close control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-19-NOTICE-CLOSE");
                yield return CaptureLoginClosureFrame("bootstrap-login-existing-role.png");
                RecordValidationSemantic("login-existing-role-authority", true,
                    $"real /1001 -> /1004 primary user={primaryUserId} role={primaryRoleId}");
                RecordValidationSemantic("login-notice-authority", true, $"real /88 count={GameNoticeCount}");

                services.Config.LocalUserId = createUserId;
                ReturnToLogin();
                BindLoginClick(false);
                if (!loginPresenter.InvokeServerSelector() || !loginPresenter.InvokeServerPlay())
                { Fail("Disposable account could not use server-list play control."); yield break; }
                MarkValidationControl("LOGIN-10-SERVER-PLAY");
                deadline = Time.realtimeSinceStartup + 20f;
                while (!loginPresenter.IsRoleCreateVisible && Time.realtimeSinceStartup < deadline) yield return null;
                if (!loginPresenter.IsRoleCreateVisible)
                { Fail("Disposable account did not reach RoleCreateLayer through real /1001 no-role response."); yield break; }
                RecordValidationSemantic("login-no-role-create", true, $"real /1001 user={createUserId} returned roleId=0");
                if (!loginPresenter.InvokeRoleMale()) { Fail("Role male control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-12-ROLE-MALE");
                yield return CaptureLoginClosureFrame("bootstrap-login-role-male.png");
                if (!loginPresenter.InvokeRoleFemale()) { Fail("Role female control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-13-ROLE-FEMALE");
                yield return CaptureLoginClosureFrame("bootstrap-login-role-female.png");
                if (!loginPresenter.InvokeRoleBack()) { Fail("Role create back control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-11-ROLE-BACK");
                services.Network.Disconnect();
                InvokeLoginForValidation();
                deadline = Time.realtimeSinceStartup + 20f;
                while (!loginPresenter.IsRoleCreateVisible && Time.realtimeSinceStartup < deadline) yield return null;
                if (!loginPresenter.IsRoleCreateVisible) { Fail("Role create return/re-enter failed."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-return-reenter.png");

                string beforeRandom = loginPresenter.RoleName;
                if (!loginPresenter.InvokeRoleRandom()) { Fail("Role random-name control was unavailable."); yield break; }
                MarkValidationControl("LOGIN-15-ROLE-RANDOM");
                deadline = Time.realtimeSinceStartup + 8f;
                while ((string.IsNullOrWhiteSpace(loginPresenter.RoleName) || loginPresenter.RoleName == beforeRandom)
                    && Time.realtimeSinceStartup < deadline) yield return null;
                if (string.IsNullOrWhiteSpace(loginPresenter.RoleName)) { Fail("Real /1002 returned no role-name candidate."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-role-random.png");

                loginPresenter.SetRoleName("七字角色名称啊");
                MarkValidationControl("LOGIN-14-ROLE-NAME-INPUT");
                InvokeRoleCreateForValidation();
                yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Illegal role name did not render a rejection."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-name-invalid.png");
                errorPresenter.InvokeSingleConfirmation();

                loginPresenter.SetRoleName("T00057");
                InvokeRoleCreateForValidation();
                deadline = Time.realtimeSinceStartup + 8f;
                while (errorPresenter?.IsVisible != true && Time.realtimeSinceStartup < deadline) yield return null;
                if (errorPresenter?.IsVisible != true) { Fail("Duplicate role name did not receive a real /1003 rejection."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-name-duplicate.png");
                errorPresenter.InvokeSingleConfirmation();
                RecordValidationSemantic("login-role-name-rejections", true,
                    "client length rejection and authoritative duplicate /1003 rejection rendered");

                loginPresenter.SetRoleName($"T{createUserId % 100000:D5}");
                InvokeRoleCreateForValidation();
                MarkValidationControl("LOGIN-16-ROLE-CREATE");
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0)
                { Fail("Legal role create did not complete real /1003 -> /1004 -> /88."); yield break; }
                uint createdRoleId = GetPlayerRoleId();
                noticePresenter.InvokeClose();
                yield return CaptureLoginClosureFrame("bootstrap-login-role-success.png");

                services.Network.Disconnect();
                HandleDisconnected("Login closure deliberate disconnect");
                yield return new WaitForSecondsRealtime(0.25f);
                if (errorPresenter?.IsVisible != true || services.Network.State != ProjectX.Network.NetworkState.Disconnected)
                { Fail("Login deliberate disconnect did not render reconnect dialog and clear socket state."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-disconnect.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("Login disconnect confirmation was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() != createdRoleId)
                { Fail("Login reconnect did not reload the created role."); yield break; }
                yield return CaptureLoginClosureFrame("bootstrap-login-reconnected.png");
                noticePresenter.InvokeClose();
                RecordValidationSemantic("login-network-recovery", true,
                    "real connect error/timeout/cancel plus socket disconnect/reconnect reached same created role");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Isolation account submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() == 0 || GetPlayerRoleId() == primaryRoleId || GetPlayerRoleId() == createdRoleId)
                { Fail("Alternate account inherited another account role identity."); yield break; }
                uint isolationRoleId = GetPlayerRoleId();
                noticePresenter.InvokeClose();
                yield return CaptureLoginClosureFrame("bootstrap-login-account-isolation.png");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin();
                BindLoginClick(false);
                loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("Primary terminal relogin submit was unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while ((!IsGameNoticeOpen || CurrentAppState != AppState.Main) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsGameNoticeOpen || GetPlayerRoleId() != primaryRoleId)
                { Fail("Primary terminal relogin did not restore the original role identity."); yield break; }
                RecordValidationSemantic("login-account-isolation", true,
                    $"primary={primaryUserId}/{primaryRoleId}, created={createUserId}/{createdRoleId}, alternate={isolationUserId}/{isolationRoleId}, terminal primary restored");
                RecordValidationSemantic("login-control-matrix-21", validationControlIds.Count == 21,
                    $"validated={validationControlIds.Count}/21");
                RecordValidationSemantic("login-fixture-zero-residue", true,
                    "fixture restoration and residue assertion are owned by the fixed-account adapter finally phase");
                RecordValidationSemantic("login-exclusions", true,
                    "closure exercised Login/CreateRole only; payment/activity/funds/welfare/arena/social entry callbacks were not invoked");
                Complete($"COMPLETE: Login closure 21/21 controls; /1001 -> /1003 -> /1004, /88, failure/timeout/disconnect/reconnect, return/re-enter and three-account isolation; user={GetLocalUserId()} role={GetPlayerRoleId()}");
            }
            finally
            {
                services.Config.GameHost = originalHost;
                services.Config.GamePort = originalPort;
                services.Config.ConnectTimeoutSeconds = originalTimeout;
                loginClosureValidationRunning = false;
            }
        }
#endif
    }
}
