using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameErrorPresenter
    {
        private readonly UnityUiView view;
        private readonly Text title;
        private readonly Text message;
        private readonly Vector2 defaultMessagePosition;
        private readonly Vector2 defaultMessageSize;
        private readonly TextAnchor defaultMessageAlignment;
        private readonly Button singleConfirm;
        private readonly Button cancelButton;
        private readonly Button confirmButton;
        private Action confirmation;
        private Action cancellation;

        public GameErrorPresenter(UnityUiView view)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            GameErrorViewBindings bindings = view.GameObject.GetComponent<GameErrorViewBindings>();
            if (bindings == null)
                throw new InvalidOperationException("MessageBoxLayer is missing its Unity-authored view bindings.");
            title = bindings.Title;
            message = bindings.Message;
            if (title == null || message == null)
                throw new InvalidOperationException("MessageBoxLayer title and message bindings are required.");
            defaultMessagePosition = message.rectTransform.anchoredPosition;
            defaultMessageSize = message.rectTransform.sizeDelta;
            defaultMessageAlignment = message.alignment;
            view.BindClickNode(RequireButton(bindings.CloseButton, "close").gameObject, Hide);
            singleConfirm = view.BindClickNode(RequireButton(bindings.SingleConfirm, "single confirm").gameObject, Hide);
            cancelButton = view.BindClickNode(RequireButton(bindings.CancelButton, "cancel").gameObject, Cancel);
            confirmButton = view.BindClickNode(RequireButton(bindings.ConfirmButton, "confirm").gameObject, Confirm);
            SetOptionalVisible(bindings.IconBg1, false, "icon background");
            SetOptionalVisible(bindings.Spend, false, "spend panel");
            SetOptionalVisible(bindings.GoldNum, false, "gold amount");
            SetOptionalVisible(bindings.DesBg1, false, "description background");
            SetOptionalVisible(bindings.CheckBox, false, "checkbox");
            SetOptionalVisible(bindings.Confirm3, false, "third confirmation button");
            SetOptionalVisible(bindings.Confirm2Time, false, "confirmation timer");
            Hide();
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public Button SingleConfirmationButton => singleConfirm;
        public Button ConfirmationButton => confirmButton;

        public bool InvokeCancel()
        {
            if (!IsVisible || !cancelButton.gameObject.activeSelf || !cancelButton.interactable) return false;
            cancelButton.onClick.Invoke();
            return true;
        }

        public bool InvokeConfirmation()
        {
            if (!IsVisible || !confirmButton.gameObject.activeSelf || !confirmButton.interactable) return false;
            confirmButton.onClick.Invoke();
            return true;
        }

        public bool InvokeSingleConfirmation()
        {
            if (!IsVisible || !singleConfirm.gameObject.activeSelf || !singleConfirm.interactable) return false;
            singleConfirm.onClick.Invoke();
            return true;
        }

        public void Show(string heading, string detail)
        {
            confirmation = null;
            cancellation = null;
            ResetMessageLayout();
            title.text = string.IsNullOrEmpty(heading) ? "提示" : heading;
            message.text = detail ?? string.Empty;
            message.gameObject.SetActive(true);
            singleConfirm.gameObject.SetActive(true);
            cancelButton.gameObject.SetActive(false);
            confirmButton.gameObject.SetActive(false);
            view.ShowPopup();
        }

        public void ShowHelp(string detail)
        {
            Show("提示", detail);
            RectTransform rect = message.rectTransform;
            rect.anchoredPosition = new Vector2(0f, 20f);
            rect.sizeDelta = new Vector2(470f, 230f);
            message.alignment = TextAnchor.UpperLeft;
        }

        public void ShowDismissOnly(string heading, string detail)
        {
            Show(heading, detail);
            singleConfirm.gameObject.SetActive(false);
            RectTransform rect = message.rectTransform;
            rect.anchoredPosition = new Vector2(0f, 6f);
            rect.sizeDelta = new Vector2(500f, 230f);
            message.alignment = TextAnchor.UpperLeft;
        }

        public void ShowConfirmation(string heading, string detail, Action onConfirm,
            string confirmLabel = "确定", string cancelLabel = "取消", bool alignTopLeft = false,
            Action onCancel = null)
        {
            confirmation = onConfirm ?? throw new ArgumentNullException(nameof(onConfirm));
            cancellation = onCancel;
            ResetMessageLayout();
            title.text = string.IsNullOrEmpty(heading) ? "购买确认" : heading;
            message.text = detail ?? string.Empty;
            bool useTopLeft = alignTopLeft
                || message.text.StartsWith("无法连接服务器", StringComparison.Ordinal);
            if (useTopLeft)
            {
                message.alignment = TextAnchor.UpperLeft;
                message.rectTransform.anchoredPosition = new Vector2(0f, 53f);
                message.rectTransform.sizeDelta = new Vector2(490f, 180f);
            }
            message.gameObject.SetActive(true);
            singleConfirm.gameObject.SetActive(false);
            cancelButton.gameObject.SetActive(true);
            confirmButton.gameObject.SetActive(true);
            SetButtonText(cancelButton, cancelLabel);
            SetButtonText(confirmButton, confirmLabel);
            view.ShowPopup();
        }

        public void Confirm()
        {
            Action callback = confirmation;
            Hide();
            callback?.Invoke();
        }

        public void Cancel()
        {
            Action callback = cancellation;
            Hide();
            callback?.Invoke();
        }

        public void Hide()
        {
            confirmation = null;
            cancellation = null;
            view.SetVisible(false);
        }

        private void ResetMessageLayout()
        {
            message.rectTransform.anchoredPosition = defaultMessagePosition;
            message.rectTransform.sizeDelta = defaultMessageSize;
            message.alignment = defaultMessageAlignment;
        }

        private static void SetButtonText(Button button, string value)
        {
            Text label = button.GetComponentInChildren<Text>(true);
            if (label != null) label.text = value;
        }

        private static Button RequireButton(Button value, string label)
        {
            return value != null
                ? value
                : throw new InvalidOperationException($"MessageBox binding is missing: {label}.");
        }

        private static GameObject Require(GameObject value, string label)
        {
            return value != null
                ? value
                : throw new InvalidOperationException($"MessageBox binding is missing: {label}.");
        }

        private static void SetOptionalVisible(GameObject node, bool visible, string label)
        {
            Require(node, label).SetActive(visible);
        }
    }
}
