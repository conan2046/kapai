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
        private void EnsureMailPresenter()
        {
            mailView = mailView ?? services.UiRouter.FindBySource("MailLayer");
            EnsureOneLevelFrame();
            if (mailView == null || oneLevelFrameView == null)
                throw new InvalidOperationException("MailLayer/OneLevelLayer CocosUiBinding was not found.");
            EnsureBagPresenter();
            mailPresenter = mailPresenter ?? new MailPresenter(mailView, oneLevelFrameView, services.Mails, services.Resources,
                id => InvokeLuaOrFail(onMailClaimClicked, "Mail.OnClaimClicked", (double)id),
                id => InvokeLuaOrFail(onMailReadClicked, "Mail.OnReadClicked", (double)id),
                id => InvokeLuaOrFail(onMailDeleteClicked, "Mail.OnDeleteClicked", (double)id),
                () => InvokeLuaOrFail(onMailClaimAllClicked, "Mail.OnClaimAllClicked"),
                () => InvokeLuaOrFail(onMailDeleteAllClicked, "Mail.OnDeleteAllClicked"),
                () =>
                {
                    bagFlowPresenter.CloseAll();
                    SetOneLevelFrameVisible(false);
                    HandleBack();
                },
                item => bagFlowPresenter.ShowMailAttachment(item));
        }

        private void ConfigureMailFrame()
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            CocosUiBinding binding = oneLevelFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null)
            {
                title.text = "邮件";
                title.alignment = TextAnchor.MiddleLeft;
                title.horizontalOverflow = HorizontalWrapMode.Overflow;
            }
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform tabs = binding.Find("Layer/Panel_12/Bg/Btn_ListView")?.transform;
            if (tabs != null) tabs.gameObject.SetActive(true);
            Transform first = tabs?.Find("Panel_10/Button1");
            if (first != null) SetTabText(first, "邮件", true);
            Transform second = tabs?.Find("Panel_10/Button2_Runtime");
            if (second != null) second.gameObject.SetActive(false);
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private void UpdateMailRedDot()
        {
            if (mainView == null) return;
            GameObject prompt = mainView.Binding.Find($"{MailPath}/Prompt");
            if (prompt != null) prompt.SetActive(services.Mails.HasUnread);
        }


    }
}

