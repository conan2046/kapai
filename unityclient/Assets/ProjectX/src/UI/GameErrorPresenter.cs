using System;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameErrorPresenter
    {
        private readonly CocosUiView view;
        private readonly Text title;
        private readonly Text message;
        private readonly Button singleConfirm;
        private readonly Button cancelButton;
        private readonly Button confirmButton;
        private Action confirmation;
        private Action cancellation;

        public GameErrorPresenter(CocosUiView view)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            title = RequireText("Layer/MessageBoxUI/bg/Title");
            message = RequireText("Layer/MessageBoxUI/TipsText");
            ConfigureMessageText();
            RectTransform titleRect = title.GetComponent<RectTransform>();
            if (titleRect != null) titleRect.sizeDelta = new Vector2(220f, Math.Max(32f, titleRect.sizeDelta.y));
            BindDismiss("Layer/MessageBoxUI/bg/Btn_close");
            singleConfirm = Bind("Layer/MessageBoxUI/Btn_Confirm", Hide);
            cancelButton = Bind("Layer/MessageBoxUI/Btn_Confirm1", Cancel);
            confirmButton = Bind("Layer/MessageBoxUI/Btn_Confirm2", Confirm);
            SetOptionalVisible("Layer/MessageBoxUI/IconBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/Spend", false);
            SetOptionalVisible("Layer/MessageBoxUI/GoldNum", false);
            SetOptionalVisible("Layer/MessageBoxUI/DesBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/CheckBox", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm3", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm2/Time", false);
            EnsureModalMask();
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
            ConfigureMessageText();
            title.text = string.IsNullOrEmpty(heading) ? "提示" : heading;
            message.text = detail ?? string.Empty;
            message.gameObject.SetActive(true);
            singleConfirm.gameObject.SetActive(true);
            cancelButton.gameObject.SetActive(false);
            confirmButton.gameObject.SetActive(false);
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void ShowHelp(string detail)
        {
            Show("提示", detail);
            RectTransform rect = message.rectTransform;
            rect.anchoredPosition = new Vector2(0f, 20f);
            rect.sizeDelta = new Vector2(470f, 230f);
            message.alignment = TextAnchor.UpperLeft;
        }

        public void ShowConfirmation(string heading, string detail, Action onConfirm,
            string confirmLabel = "确定", string cancelLabel = "取消", bool alignTopLeft = false,
            Action onCancel = null)
        {
            confirmation = onConfirm ?? throw new ArgumentNullException(nameof(onConfirm));
            cancellation = onCancel;
            ConfigureMessageText();
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
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
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

        private void BindDismiss(string path)
        {
            Bind(path, Hide);
        }

        private Button Bind(string path, Action callback)
        {
            GameObject node = view.Binding.Find(path)
                ?? throw new InvalidOperationException($"MessageBox button was not found: {path}");
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private static void SetButtonText(Button button, string value)
        {
            Text label = button.GetComponentInChildren<Text>(true);
            if (label != null) label.text = value;
        }

        private Text RequireText(string path)
        {
            GameObject node = view.Binding.Find(path);
            Text value = node == null ? null : node.GetComponent<Text>();
            return value ?? throw new InvalidOperationException($"MessageBox text was not found: {path}");
        }

        private void ConfigureMessageText()
        {
            message.gameObject.SetActive(true);
            RectTransform rect = message.GetComponent<RectTransform>();
            if (rect != null)
            {
                rect.anchorMin = new Vector2(0.5f, 0.5f);
                rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(0f, 35f);
                rect.sizeDelta = new Vector2(470f, 150f);
            }
            message.fontSize = 22;
            message.color = new Color32(105, 58, 48, 255);
            message.alignment = TextAnchor.MiddleCenter;
            message.horizontalOverflow = HorizontalWrapMode.Wrap;
            message.verticalOverflow = VerticalWrapMode.Truncate;
            message.raycastTarget = false;
        }

        private void EnsureModalMask()
        {
            Transform layer = view.Binding.Find("Layer")?.transform ?? view.GameObject.transform;
            Transform existing = layer.Find("RuntimeModalMask");
            GameObject maskObject = existing == null
                ? new GameObject("RuntimeModalMask", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image))
                : existing.gameObject;
            RectTransform rect = maskObject.GetComponent<RectTransform>();
            rect.SetParent(layer, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = maskObject.GetComponent<Image>();
            image.color = new Color(0f, 0f, 0f, 0.40f);
            image.raycastTarget = true;
            maskObject.transform.SetAsFirstSibling();
        }

        private void SetOptionalVisible(string path, bool visible)
        {
            view.Binding.Find(path)?.SetActive(visible);
        }
    }
}
