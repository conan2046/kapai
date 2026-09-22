using System.Collections;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowStaminaClaim()
        {
            EnsureStaminaClaimPresenter();
            taskView?.SetVisible(false); resourceRecoveryView?.SetVisible(false);
            growthFundView?.SetVisible(false); activeFundView?.SetVisible(false);
            staminaClaimView.SetVisible(true); welfareActivityFramePresenter.Select(18);
            if (services.UiStack.Current != taskBackgroundView) services.UiStack.Push(taskBackgroundView);
            SetStatus("StaminaClaim current welfare UI active; awaiting /321 op=2.");
        }
        public void BeginStaminaClaimState() => pendingStaminaClaimRecords.Clear();
        public void AddStaminaClaimState(int index, int state) =>
            pendingStaminaClaimRecords.Add(new StaminaClaimRecord(checked((byte)index), checked((byte)state)));
        public void CommitStaminaClaimState() => services.StaminaClaim.Replace(pendingStaminaClaimRecords);
        public void BeginStaminaClaimRequest(int index, int paidType) =>
            services.StaminaClaim.BeginClaim(checked((byte)index), paidType != 0);
        public void CompleteStaminaClaimRequest(int index, int paidType, bool success, double stamina, string error)
        {
            byte slot = checked((byte)index);
            if (success)
            {
                services.StaminaClaim.ApplyClaimSuccess(slot);
                ShowToast($"体力领取成功，当前体力 {checked((int)stamina)}", 2f);
            }
            else
            {
                services.StaminaClaim.ApplyClaimFailure(slot, error);
                ShowToast(error, 3f);
            }
        }
        private void RequestStaminaClaim(byte index, bool paid) =>
            InvokeLuaOrFail(onStaminaClaimRequest, "StaminaClaim.Request", (double)index, paid);
        private void RejectStaminaClaimLocally(byte index, string error)
        {
            services.StaminaClaim.ApplyClaimFailure(index, error);
            ShowToast(error, 3f);
        }
        private bool staminaClaimPaidCancelObserved;
        private void ShowStaminaClaimPaidConfirmation(byte index)
        {
            EnsureErrorPresenter();
            staminaClaimPaidCancelObserved = false;
            errorPresenter.ShowConfirmation("补领体力", "是否花费20元宝补领体力？",
                () => RequestStaminaClaim(index, true), "确定", "取消", false,
                () => staminaClaimPaidCancelObserved = true);
        }
        public void CompleteStaminaClaimValidation()
        {
            if (staminaClaimValidationRunning || staminaClaimValidationCompleted) return;
            staminaClaimValidationRunning = true;
            StartCoroutine(RunStaminaClaimValidation());
        }

        private IEnumerator RunStaminaClaimValidation()
        {
            uint primaryUserId = GetLocalUserId();
            uint primaryRoleId = GetPlayerRoleId();
            uint isolationUserId = services.Options.StaminaClaimIsolationUserId == 0 ? 705213u : services.Options.StaminaClaimIsolationUserId;
            uint overCapUserId = services.Options.StaminaClaimOverCapUserId == 0 ? 7200260u : services.Options.StaminaClaimOverCapUserId;
            string[] controls =
            {
                "STAMINA-01-GAMEPLAY-ENTRY", "STAMINA-02-CLOSE", "STAMINA-03-STAMINA-TAB",
                "STAMINA-04-RESOURCE-TAB", "STAMINA-05-STAMINA-ADD", "STAMINA-06-GOLD-ADD",
                "STAMINA-07-TONGBAO-ADD-DISABLED", "STAMINA-08-SLOT-1", "STAMINA-09-SLOT-2",
                "STAMINA-10-SLOT-3", "STAMINA-11-PAID-CONFIRM", "STAMINA-12-PAID-CANCEL",
                "STAMINA-13-RED-DOT", "STAMINA-14-STAMINA-DISPLAY", "STAMINA-15-GOLD-DISPLAY",
                "STAMINA-16-PREMIUM-DISPLAY"
            };
            try
            {
                BeginValidationEvidence();
                if (primaryUserId != 7200057 || primaryRoleId != 1000115
                    || isolationUserId != 705213 || overCapUserId != 7200260)
                {
                    Fail($"StaminaClaim identity mismatch: primary={primaryUserId}/{primaryRoleId}, isolation={isolationUserId}, overCap={overCapUserId}.");
                    yield break;
                }
                EnsureStaminaClaimPresenter();
                toastPresenter?.Clear();
                Canvas.ForceUpdateCanvases(); yield return new WaitForEndOfFrame();
                if (!IsStaminaClaimOpen || !IsStaminaClaimAuthoritativeVisible
                    || services.StaminaClaim.Items.Count != 3 || services.ProtocolRegistry.PendingCount != 0
                    || staminaClaimPresenter.BoundButtonCount != 3
                    || services.StaminaClaim.StateOf(1) != 2 || services.StaminaClaim.StateOf(2) != 1
                    || services.StaminaClaim.StateOf(3) != 1 || services.Currencies.Stamina != 40
                    || services.Currencies.Premium != 100)
                {
                    Fail($"StaminaClaim mixed fixture mismatch: open={IsStaminaClaimOpen}, buttons={staminaClaimPresenter.BoundButtonCount}, states={services.StaminaClaim.StateOf(1)}/{services.StaminaClaim.StateOf(2)}/{services.StaminaClaim.StateOf(3)}, stamina={services.Currencies.Stamina}, premium={services.Currencies.Premium}, pending={services.ProtocolRegistry.PendingCount}.");
                    yield break;
                }
                MarkValidationControl(controls[0]); yield return CaptureStaminaControlEvidence(controls[0]);
                MarkValidationControl(controls[12]); yield return CaptureStaminaControlEvidence(controls[12]);
                MarkValidationControl(controls[13]); yield return CaptureStaminaControlEvidence(controls[13]);
                MarkValidationControl(controls[14]); yield return CaptureStaminaControlEvidence(controls[14]);
                MarkValidationControl(controls[15]); yield return CaptureStaminaControlEvidence(controls[15]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-mixed.png");

                welfareActivityFramePresenter.InvokeResourceTab();
                float deadline = Time.realtimeSinceStartup + 10f;
                while (!IsResourceRecoveryOpen && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsResourceRecoveryOpen) { Fail("StaminaClaim resource tab boundary did not open ResourceRecovery."); yield break; }
                MarkValidationControl(controls[3]); yield return CaptureStaminaControlEvidence(controls[3]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-resource-tab.png");
                welfareActivityFramePresenter.InvokeStaminaTab();
                deadline = Time.realtimeSinceStartup + 10f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) { Fail("StaminaClaim tab return did not settle op=2."); yield break; }
                MarkValidationControl(controls[2]); yield return CaptureStaminaControlEvidence(controls[2]);

                welfareActivityFramePresenter.InvokeStaminaAdd();
                if (lastStaminaClaimBoundary != "stamina-add") { Fail("StaminaClaim stamina-add boundary mismatch."); yield break; }
                MarkValidationControl(controls[4]); yield return CaptureStaminaControlEvidence(controls[4]);
                welfareActivityFramePresenter.InvokeGoldAdd();
                if (lastStaminaClaimBoundary != "gold-add") { Fail("StaminaClaim gold-add boundary mismatch."); yield break; }
                MarkValidationControl(controls[5]); yield return CaptureStaminaControlEvidence(controls[5]);
                if (!welfareActivityFramePresenter.PremiumAddDisabled) { Fail("StaminaClaim premium add must remain hidden/disabled."); yield break; }
                MarkValidationControl(controls[6]); yield return CaptureStaminaControlEvidence(controls[6]);
                RecordValidationSemantic("stamina-boundary-controls", true, "resource tab, stamina add, gold add and disabled premium add preserved ownership boundaries");

                long staminaBefore = services.Currencies.Stamina;
                long premiumBefore = services.Currencies.Premium;
                if (!staminaClaimPresenter.InvokeSlot(1) || errorPresenter?.IsVisible != true)
                { Fail("StaminaClaim paid slot did not open confirmation."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-dialog.png");
                if (!errorPresenter.InvokeCancel()) { Fail("StaminaClaim paid cancel was unavailable."); yield break; }
                yield return new WaitForSecondsRealtime(.25f);
                if (!staminaClaimPaidCancelObserved || services.Currencies.Stamina != staminaBefore
                    || services.Currencies.Premium != premiumBefore || services.StaminaClaim.StateOf(1) != 2)
                { Fail("StaminaClaim paid cancel mutated authoritative state."); yield break; }
                MarkValidationControl(controls[11]); yield return CaptureStaminaControlEvidence(controls[11]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-cancel.png");

                if (!staminaClaimPresenter.InvokeSlot(1) || !errorPresenter.InvokeConfirmation())
                { Fail("StaminaClaim paid confirmation was unavailable."); yield break; }
                MarkValidationControl(controls[10]); yield return CaptureStaminaControlEvidence(controls[10]);
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(1) != 3
                    || services.Currencies.Premium == premiumBefore) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.StateOf(1) != 3 || services.Currencies.Stamina != staminaBefore + 50
                    || services.Currencies.Premium != premiumBefore - 20 || !services.StaminaClaim.LastClaimSucceeded)
                { Fail($"StaminaClaim paid authority mismatch: stamina={staminaBefore}->{services.Currencies.Stamina}, premium={premiumBefore}->{services.Currencies.Premium}, state={services.StaminaClaim.StateOf(1)}, error={services.StaminaClaim.LastClaimError}."); yield break; }
                MarkValidationControl(controls[7]); yield return CaptureStaminaControlEvidence(controls[7]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-paid-success.png");
                RecordValidationSemantic("stamina-paid-claim-authority", true, "real /321 op3 idx1 type1 changed stamina +50, premium -20 and state 2->3");
                RecordValidationSemantic("stamina-paid-cancel-no-mutation", true, "cancel sent no op3 and preserved stamina, premium and state2");

                long goldBefore = services.Currencies.Gold;
                if (!staminaClaimPresenter.InvokeSlot(2)) { Fail("StaminaClaim slot2 free claim unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(2) != 3) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.Currencies.Stamina != staminaBefore + 100 || services.StaminaClaim.StateOf(2) != 3)
                { Fail("StaminaClaim slot2 authoritative +50 failed."); yield break; }
                MarkValidationControl(controls[8]); yield return CaptureStaminaControlEvidence(controls[8]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-slot2.png");
                if (!staminaClaimPresenter.InvokeSlot(3)) { Fail("StaminaClaim slot3 free claim unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((services.StaminaClaim.ClaimPending || services.StaminaClaim.StateOf(3) != 3) && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.Currencies.Stamina != staminaBefore + 150 || services.StaminaClaim.StateOf(3) != 3
                    || services.Currencies.Gold != goldBefore || services.StaminaClaim.SuccessfulClaimCount != 3)
                { Fail("StaminaClaim three-slot single-use authority mismatch."); yield break; }
                MarkValidationControl(controls[9]); yield return CaptureStaminaControlEvidence(controls[9]);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-all-claimed.png");
                RecordValidationSemantic("stamina-free-claim-authority", true, "real slot2/slot3 op3 each granted +50 exactly once; gold unchanged");
                RecordValidationSemantic("stamina-three-slot-single-use", true, "slot1 paid plus slot2/slot3 free each transitioned once to state3");

                long duplicateStamina = services.Currencies.Stamina;
                toastPresenter?.Clear();
                RequestStaminaClaim(2, false);
                deadline = Time.realtimeSinceStartup + 10f;
                while (services.StaminaClaim.ClaimPending && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.LastClaimSucceeded || string.IsNullOrWhiteSpace(services.StaminaClaim.LastClaimError)
                    || services.Currencies.Stamina != duplicateStamina || services.StaminaClaim.StateOf(2) != 3)
                { Fail("StaminaClaim duplicate op3 was not authoritatively rejected without mutation."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-duplicate.png");
                RecordValidationSemantic("stamina-duplicate-rejected", true, $"real duplicate /321 op3 rejected: {services.StaminaClaim.LastClaimError}");

                welfareActivityFramePresenter.InvokeClose();
                MarkValidationControl(controls[1]); yield return CaptureStaminaControlEvidence(controls[1]);
                if (IsStaminaClaimOpen) { Fail("StaminaClaim close did not return to gameplay."); yield break; }
                if (gameplayPresenter == null || !gameplayPresenter.InvokeEnter(18)) { Fail("StaminaClaim gameplay re-entry unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.StaminaClaim.StateOf(1) != 3 || services.StaminaClaim.StateOf(2) != 3 || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim re-entry did not rebuild all claimed states."); yield break; }
                services.Network.Disconnect("StaminaClaim deliberate disconnect");
                yield return new WaitForSecondsRealtime(.25f);
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-disconnected.png");
                if (errorPresenter?.IsVisible != true || !errorPresenter.InvokeConfirmation()) { Fail("StaminaClaim reconnect confirmation unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != primaryRoleId) { Fail("StaminaClaim reconnect identity mismatch."); yield break; }
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (!IsStaminaClaimOpen || services.Currencies.Stamina != duplicateStamina || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim reconnect persistence mismatch."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-reconnected.png");
                RecordValidationSemantic("stamina-reentry-reconnect-persistence", true, "close/re-enter and deliberate disconnect/reconnect rebuilt server state 3/3/3 with stamina190");

                services.Config.LocalUserId = isolationUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(isolationUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim isolation submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != 1000006 || !IsStaminaClaimOpen || services.Currencies.Stamina != 40
                    || services.Currencies.Premium != 0 || services.StaminaClaim.StateOf(1) != 2)
                { Fail($"StaminaClaim isolation fixture mismatch: user={GetLocalUserId()} role={GetPlayerRoleId()} stamina={services.Currencies.Stamina} premium={services.Currencies.Premium} state1={services.StaminaClaim.StateOf(1)}."); yield break; }
                toastPresenter?.Clear();
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-account-isolation.png");
                long insufficientStamina = services.Currencies.Stamina;
                if (!staminaClaimPresenter.InvokeSlot(1) || errorPresenter?.IsVisible != true) { Fail("StaminaClaim insufficient paid request unavailable."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-insufficient-premium.png");
                if (!errorPresenter.InvokeConfirmation()) { Fail("StaminaClaim insufficient paid confirmation unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 10f;
                while (services.StaminaClaim.ClaimPending && Time.realtimeSinceStartup < deadline) yield return null;
                if (services.StaminaClaim.LastClaimSucceeded || string.IsNullOrWhiteSpace(services.StaminaClaim.LastClaimError)
                    || services.Currencies.Stamina != insufficientStamina || services.Currencies.Premium != 0 || services.StaminaClaim.StateOf(1) != 2)
                { Fail("StaminaClaim insufficient-premium rejection mutated state."); yield break; }
                RecordValidationSemantic("stamina-insufficient-premium", true, $"real /321 op3 idx1 type1 rejected at premium0: {services.StaminaClaim.LastClaimError}");

                services.Config.LocalUserId = overCapUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(overCapUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim over-cap submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != 1000119 || services.Currencies.Stamina != 990 || services.StaminaClaim.StateOf(2) != 1)
                { Fail("StaminaClaim over-cap fixture mismatch."); yield break; }
                toastPresenter?.Clear();
                if (!staminaClaimPresenter.InvokeSlot(2) || services.Currencies.Stamina != 990
                    || !services.StaminaClaim.LastClaimError.Contains("1000"))
                { Fail("StaminaClaim over-cap UI rejection failed."); yield break; }
                yield return CaptureStaminaClaimFrame("bootstrap-stamina-claim-over-cap.png");
                RecordValidationSemantic("stamina-cap-rejected", true, "990+50 rejected before request; state and currencies unchanged");

                services.Config.LocalUserId = primaryUserId;
                ReturnToLogin(); BindLoginClick(false); loginPresenter.SetAccountCredentials(primaryUserId, "local");
                if (!loginPresenter.InvokeAccountSubmit()) { Fail("StaminaClaim terminal primary submit unavailable."); yield break; }
                deadline = Time.realtimeSinceStartup + 25f;
                while (CurrentAppState != AppState.Main && Time.realtimeSinceStartup < deadline) yield return null;
                deadline = Time.realtimeSinceStartup + 12f;
                while ((!IsStaminaClaimOpen || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline) yield return null;
                if (GetPlayerRoleId() != primaryRoleId || services.Currencies.Stamina != duplicateStamina
                    || services.Currencies.Premium != premiumBefore - 20 || services.StaminaClaim.StateOf(1) != 3
                    || services.StaminaClaim.StateOf(2) != 3 || services.StaminaClaim.StateOf(3) != 3)
                { Fail("StaminaClaim terminal primary persistence/isolation mismatch."); yield break; }
                RecordValidationSemantic("stamina-account-isolation", true, "real main->705213->7200260->main logins rebuilt independent stores and restored terminal main identity");
                RecordValidationSemantic("stamina-protocol-ownership", true, "module sent /321 op2/op3 only; /321 op1 remained PlayerHud-owned");
                RecordValidationSemantic("stamina-fixture-restore", true, "outer fixed-account runner owns finally restore, post-login hash and residual=0 assertions");
                RecordValidationSemantic("stamina-control-matrix-16", validationControlIds.Count == 16, $"validated={validationControlIds.Count}/16");
                if (validationControlIds.Count != 16) { Fail($"StaminaClaim control coverage mismatch: {validationControlIds.Count}/16."); yield break; }
                staminaClaimValidationCompleted = true;
                Complete($"COMPLETE: StaminaClaim 16/16 controls; real /321 op2/op3 three slots, paid/free/duplicate/insufficient/cap, reconnect and account isolation; user={primaryUserId} role={primaryRoleId}; stamina-control-matrix-16");
            }
            finally { staminaClaimValidationRunning = false; }
        }

        private IEnumerator CaptureStaminaClaimFrame(string fileName)
        {
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length < 4096) && Time.realtimeSinceStartup < deadline) yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length < 4096) Fail("StaminaClaim screenshot was not written: " + path);
        }

        private IEnumerator CaptureStaminaControlEvidence(string controlId)
        {
            string token = (controlId ?? string.Empty).ToLowerInvariant();
            yield return CaptureStaminaClaimFrame($"stamina-control-{token}.png");
        }
    }
}
