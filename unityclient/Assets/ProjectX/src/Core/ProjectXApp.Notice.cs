using System;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
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
            if (noticeView == null) { Fail("NoticeLayer CocosUiBinding was not found."); return; }
            GameObject closeTemplate = roleCreateView?.Binding.Find("Layer/RoleCreateUI/Image/btn_Exit");
            noticePresenter = noticePresenter ?? new NoticePresenter(noticeView, closeTemplate, CloseGameNotice);
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
