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
            title = RequireText(-1672122010, "title");
            message = RequireText(2115435706, "message");
            ConfigureMessageText();
            RectTransform titleRect = title.GetComponent<RectTransform>();
            if (titleRect != null) titleRect.sizeDelta = new Vector2(220f, Math.Max(32f, titleRect.sizeDelta.y));
            Bind(349721155, Hide);
            singleConfirm = Bind(721860561, Hide);
            cancelButton = Bind(-181194337, Cancel);
            confirmButton = Bind(-1524456559, Confirm);
            SetOptionalVisible(321242196, false);
            SetOptionalVisible(-1538001884, false);
            SetOptionalVisible(-1250625782, false);
            SetOptionalVisible(149624163, false);
            SetOptionalVisible(-1822849710, false);
            SetOptionalVisible(-1018098735, false);
            SetOptionalVisible(963490538, false);
            SetOptionalVisible(375334442, false);
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

        private Button Bind(int actionTag, Action callback)
        {
            GameObject node = view.GetSerializedNodeByActionTag(actionTag);
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

        private Text RequireText(int actionTag, string label)
        {
            GameObject node = view.GetSerializedNodeByActionTag(actionTag);
            Text value = node.GetComponent<Text>();
            return value ?? throw new InvalidOperationException($"MessageBox text was not found: {label}");
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
            Transform layer = view.GameObject.transform;
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

        private void SetOptionalVisible(int actionTag, bool visible)
        {
            view.GetSerializedNodeByActionTag(actionTag).SetActive(visible);
        }
    }
}
