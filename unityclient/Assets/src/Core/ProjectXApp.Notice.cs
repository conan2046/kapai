using System;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private void RequestGameNotice()
        {
            LegacyTcpMessage message = LegacyTcpMessage.New();
            message.WriteUShort(88);
            Send(message);
        }

        private void HandleGameNoticeResponse(LegacyTcpMessage message)
        {
            try
            {
                BeginGameNotice(0);
                if (message == null) throw new ArgumentNullException(nameof(message));
                if (message.Remaining == 0)
                {
                    if (HasCommandLineFlag("-projectXLoginValidation")
                        && HasCommandLineFlag("-projectXRequireNoticeResponse"))
                        Fail("Required PRO_GONGGAO/88 response was empty.");
                    return;
                }

                int count = message.ReadByte();
                BeginGameNotice(count);
                for (int i = 0; i < count; i++)
                    AddGameNotice(message.ReadString(), message.ReadString(), message.ReadByte(), message.ReadByte());
                if (message.Remaining != 0)
                    throw new InvalidOperationException($"PRO_GONGGAO/88 has {message.Remaining} unread bytes.");

                ShowGameNotice();
#if UNITY_EDITOR || DEVELOPMENT_BUILD
                if (HasCommandLineFlag("-projectXLoginValidation")
                    && HasCommandLineFlag("-projectXRequireNoticeResponse"))
                    CompleteLoginValidation(loginCreatedRole);
#endif
            }
            catch (Exception exception)
            {
                Fail($"PRO_GONGGAO/88 response failed: {exception.Message}");
            }
        }

        public void BeginGameNotice(int expectedCount)
        {
            pendingGameNotices.Clear();
            if (expectedCount > 0) pendingGameNotices.Capacity = Math.Max(pendingGameNotices.Capacity, expectedCount);
        }

        public void AddGameNotice(string title, string text, int id, int operationType)
        {
            pendingGameNotices.Add(new NoticeRecord
            {
                Title = title ?? string.Empty,
                Text = text ?? string.Empty,
                Id = checked((byte)id),
                OperationType = checked((byte)operationType)
            });
        }

        public void ShowGameNotice()
        {
            noticeView = noticeView ?? services.UiAssets.GetUnityOrCreate("NoticeLayer");
            if (noticeView == null) { Fail("NoticeLayer Unity UI catalog entry was not found."); return; }
            NoticeViewBindings bindings = noticeView.GameObject.GetComponent<NoticeViewBindings>();
            if (bindings == null) { Fail("NoticeLayer Unity view bindings are missing."); return; }
            noticePresenter = noticePresenter ?? new NoticePresenter(bindings, CloseGameNotice);
            noticePresenter.Show(pendingGameNotices);
            noticeView.ShowPopup();
            services.UiStack.Push(noticeView, false);
        }

        public void CloseGameNotice()
        {
            if (services?.UiStack.Current == noticeView) services.UiStack.Pop();
            noticeView?.SetVisible(false);
        }

        public bool InvokeGameNoticeClose() => noticePresenter?.InvokeClose() == true;
    }
}
