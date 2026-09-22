using System;
using System.Collections;
using System.Collections.Generic;
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
        public void BeginMailUpdate(int expectedCount)
        {
            pendingMails.Clear();
            if (expectedCount > pendingMails.Capacity) pendingMails.Capacity = expectedCount;
        }

        public void BeginMailRecord(double id, double fromId, string sender, double expireAt,
            string message, int expectedAttachmentCount)
        {
            pendingMailId = checked((uint)id);
            pendingMailFromId = checked((uint)fromId);
            pendingMailSender = sender ?? string.Empty;
            pendingMailExpireAt = checked((uint)expireAt);
            pendingMailMessage = message ?? string.Empty;
            pendingMailAttachments.Clear();
            if (expectedAttachmentCount > pendingMailAttachments.Capacity)
                pendingMailAttachments.Capacity = expectedAttachmentCount;
        }

        public void AddMailAttachment(int type, double id, double amount, string name, int picture, int quality)
        {
            pendingMailAttachments.Add(new RewardRecord(type, checked((uint)id), checked((uint)amount),
                name, picture, quality));
        }

        public void EndMailRecord()
        {
            pendingMails.Add(new MailRecord(pendingMailId, pendingMailFromId, pendingMailSender,
                pendingMailExpireAt, pendingMailMessage, pendingMailAttachments.ToArray()));
        }

        public void EndMailUpdate()
        {
            services.Mails.Replace(pendingMails);
            UpdateMailRedDot();
            EnsureMailPresenter();
            ShowMail();
        }

        public bool SelectMail(double id)
        {
            EnsureMailPresenter();
            return mailPresenter.Select(checked((uint)id));
        }

        public bool IsMailRead(double id) =>
            services.Mails.TryGet(checked((uint)id), out MailRecord value) && value.IsRead;

        public int GetMailAttachmentCount(double id) =>
            services.Mails.TryGet(checked((uint)id), out MailRecord value) ? value.Attachments.Count : 0;

        public bool HasMail(double id) => services.Mails.TryGet(checked((uint)id), out _);
        public bool MoveMailToHistory(double id)
        {
            bool moved = services.Mails.MoveToHistory(checked((uint)id));
            UpdateMailRedDot();
            return moved;
        }
        public bool DeleteLocalMail(double id)
        {
            bool deleted = services.Mails.DeleteHistory(checked((uint)id));
            UpdateMailRedDot();
            return deleted;
        }
        public int DeleteAllLocalMails()
        {
            if (services.Mails.HasHistory) mailPresenter?.SuppressNextAutomaticRead();
            int count = services.Mails.DeleteAllHistory();
            UpdateMailRedDot();
            return count;
        }

        public void CompleteMailClaimValidation(double claimedId, int rewardCount)
        {
            uint id = checked((uint)claimedId);
            bool claimedHistory = services.Mails.TryGet(id, out MailRecord claimed)
                && claimed.IsRead && !claimed.HasAttachments;
            if (!claimedHistory || rewardCount <= 0 || !ValidateRewardPresentation(rewardCount, true)
                || services.ProtocolRegistry.PendingCount != 0 || !IsMailOpen)
            {
                Fail($"Mail validation mismatch: claimedHistory={claimedHistory}, rewards={rewardCount}, pending={services.ProtocolRegistry.PendingCount}, open={IsMailOpen}.");
                return;
            }
            MarkValidationControl("MAIL-10-SINGLE-CLAIM");
            if (!mailPresenter.Select(id) || mailPresenter.SingleActionLabel != "删除"
                || !mailPresenter.InvokeSingleAction() || services.Mails.TryGet(id, out _))
            {
                Fail("Mail G4 single-delete control did not remove the claimed local-history mail.");
                return;
            }
            MarkValidationControl("MAIL-11-SINGLE-DELETE");
            InvokeLuaOrFail(onMailValidationRepeat, "Mail.ValidationRepeat", (double)id);
        }

        public void BeginMailG4Validation(double mailId)
        {
            BeginValidationEvidence();
            StartCoroutine(RunMailG4Validation(checked((uint)mailId)));
        }

        public void CompleteMailRepeatValidation(double mailId)
        {
            SetStatus($"Mail/128 repeated claim rejected explicitly: id={checked((uint)mailId)}.");
            InvokeLuaOrFail(onMailValidationClaimAll, "Mail.ValidationClaimAll");
        }

        public void CompleteMailClaimAllValidation()
        {
            if (services.Mails.HasClaimable || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Mail G4 claim-all mismatch: claimable={services.Mails.HasClaimable}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            rewardPresenter?.Hide();
            MarkValidationControl("MAIL-12-CLAIM-ALL");
            InvokeLuaOrFail(onMailValidationReadAll, "Mail.ValidationReadAll");
        }

        public void CompleteMailReadAllValidation()
        {
            if (services.Mails.Items.Any(item => !item.IsRead || item.HasAttachments)
                || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Mail G4 read-all mismatch: unread={services.Mails.Items.Count(item => !item.IsRead)}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            if (!mailPresenter.InvokeDeleteAll() || services.Mails.Count != 0 || !mailPresenter.IsEmptyVisible)
            {
                Fail("Mail G4 delete-all did not reach the real empty state.");
                return;
            }
            MarkValidationControl("MAIL-13-DELETE-ALL");
            StartCoroutine(FinalizeMailG4Validation());
        }


    }
}

