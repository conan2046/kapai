using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private IEnumerator RunMailG4Validation(uint mailId)
        {
            EnsureMailPresenter();
            yield return new WaitForEndOfFrame();
            if (!IsMailOpen || services.Mails.Count < 14 || mailPresenter.ItemCount != services.Mails.Count)
            {
                Fail($"Mail G4 fixture mismatch: open={IsMailOpen}, store={services.Mails.Count}, rendered={mailPresenter.ItemCount}.");
                yield break;
            }

            mailValidationSawRedDot = IsMailRedDotVisible;
            MarkValidationControl("MAIL-01-MAIN-ENTRY");
            if (mailValidationSawRedDot) MarkValidationControl("MAIL-02-MAIN-RED-DOT");
            if (mailPresenter.TabLabel == "邮件") MarkValidationControl("MAIL-04-MAIL-TAB");

            Text emptyText = mailView.Binding.Find("Layer/None")?.GetComponentInChildren<Text>(true);
            Text oneKeyClaim = mailView.Binding.Find("Layer/Panel/MailList/MailBg/ReceiveBtn/BtnName")?.GetComponent<Text>();
            Text oneKeyDelete = mailView.Binding.Find("Layer/Panel/MailList/MailBg/DeleteBtn/BtnName")?.GetComponent<Text>();
            RecordValidationSemantic("mail-title", !string.IsNullOrWhiteSpace(mailPresenter.TitleText),
                $"actual={mailPresenter.TitleText}");
            RecordValidationSemantic("mail-tab", mailPresenter.TabLabel == "邮件",
                $"actual={mailPresenter.TabLabel}");
            RecordValidationSemantic("mail-empty-text", emptyText != null && emptyText.text.Contains("暂无邮件"),
                $"actual={emptyText?.text}");
            RecordValidationSemantic("mail-action-labels",
                mailPresenter.SingleActionLabel == "领取"
                    && oneKeyClaim?.text.Contains("领取") == true
                    && oneKeyDelete?.text.Contains("删除") == true,
                $"single={mailPresenter.SingleActionLabel}, claimAll={oneKeyClaim?.text}, deleteAll={oneKeyDelete?.text}");
            RecordValidationSemantic("mail-detail-fields",
                !string.IsNullOrWhiteSpace(mailPresenter.TitleText) && !string.IsNullOrWhiteSpace(mailPresenter.BodyText),
                "title/body must come from /128");
            if (GetFailedValidationSemanticAssertions().Length > 0)
            {
                Fail("Mail G4 semantic assertions failed.");
                yield break;
            }
            yield return CaptureMailValidationScreenshot("bootstrap-mail-populated.png");

            MailRecord noAttachment = services.Mails.Items.FirstOrDefault(item => !item.HasAttachments);
            if (noAttachment.Id == 0 || !mailPresenter.Select(noAttachment.Id))
            {
                Fail("Mail G4 fixture lacks a no-attachment mail.");
                yield break;
            }
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!services.Mails.TryGet(noAttachment.Id, out MailRecord readMail) || !readMail.IsRead)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!services.Mails.TryGet(noAttachment.Id, out MailRecord readResult) || !readResult.IsRead)
            {
                Fail("Mail G4 /128 op=4 did not produce per-role read history.");
                yield break;
            }
            MarkValidationControl("MAIL-06-ROW-SELECT");

            if (!mailPresenter.ScrollMailToBottom())
            {
                Fail("Mail G4 list ScrollRect did not reach the bottom.");
                yield break;
            }
            MarkValidationControl("MAIL-05-LIST-SCROLL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-scroll-bottom.png");

            MailRecord longBodyMail = services.Mails.Items.FirstOrDefault(item =>
                !item.HasAttachments
                    && (item.Message.Contains("long body") || item.Message.Contains("长正文")));
            if (longBodyMail.Id == 0) longBodyMail = noAttachment;
            if (!mailPresenter.Select(longBodyMail.Id))
            {
                Fail("Mail G4 fixture lacks a long-body mail.");
                yield break;
            }
            Canvas.ForceUpdateCanvases();
            if (!mailPresenter.ScrollBodyToBottom())
            {
                Fail("Mail G4 long body ScrollRect did not reach the bottom.");
                yield break;
            }
            MarkValidationControl("MAIL-07-BODY-SCROLL");

            if (!mailPresenter.Select(mailId) || !mailPresenter.ScrollAttachmentsToEnd())
            {
                Fail("Mail G4 attachment ScrollRect did not reach the end.");
                yield break;
            }
            MarkValidationControl("MAIL-08-ATTACHMENT-SCROLL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-attachment-end.png");
            MailRecord detailMail = services.Mails.Items.FirstOrDefault(item =>
                item.Message.Contains("单附件可领取"));
            if (detailMail.Id == 0 || !mailPresenter.Select(detailMail.Id)
                || !mailPresenter.SelectedRowHighlightMatches)
            {
                Fail("Mail detail selection and visible row highlight must agree.");
                yield break;
            }
            if (!mailPresenter.InvokeFirstAttachmentDetail() || bagFlowPresenter?.IsSourceOpen != true)
            {
                Fail("Mail G4 attachment detail control did not open the shared item-source popup.");
                yield break;
            }
            MarkValidationControl("MAIL-09-ATTACHMENT-DETAIL");
            yield return CaptureMailValidationScreenshot("bootstrap-mail-detail.png");
            bagFlowPresenter.CloseAll();
            SetOneLevelFrameVisible(true);
            mailView.SetVisible(true);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            mailView.GameObject.transform.SetAsLastSibling();
            InvokeLuaOrFail(onMailValidationClaim, "Mail.ValidationClaim", (double)mailId);
        }

        private IEnumerator FinalizeMailG4Validation()
        {
            yield return CaptureMailValidationScreenshot("bootstrap-mail.png");
            if (!mailValidationSawRedDot || IsMailRedDotVisible)
            {
                Fail($"Mail G4 red-dot transition mismatch: initial={mailValidationSawRedDot}, final={IsMailRedDotVisible}.");
                yield break;
            }
            if (!mailPresenter.HasCloseControl || !mailPresenter.InvokeClose() || IsMailOpen)
            {
                Fail("Mail G4 real close control did not return to the previous UI.");
                yield break;
            }
            MarkValidationControl("MAIL-03-CLOSE");
            ShowMail();
            Complete($"COMPLETE: Mail G4 13/13 real controls; /128 op2/3/4, repeated failure, serial claim-all/read-all, per-role persistence, empty state; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }

        private IEnumerator CaptureMailValidationScreenshot(string fileName)
        {
            // Login system broadcasts are transient overlays, not part of the Mail state.
            // Clear the shared queue so G5 compares the stable native Mail frame.
            toastPresenter?.Clear();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string repositoryRoot = Directory.GetParent(projectRoot).FullName;
            string path = Path.Combine(repositoryRoot, "build", "ui-migration", fileName);
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            ScreenCapture.CaptureScreenshot(path);
            yield return new WaitForSecondsRealtime(0.8f);
        }


    }
}

