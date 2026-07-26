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
            cancelButton = Bind("Layer/MessageBoxUI/Btn_Confirm1", Hide);
            confirmButton = Bind("Layer/MessageBoxUI/Btn_Confirm2", Confirm);
            SetOptionalVisible("Layer/MessageBoxUI/IconBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/Spend", false);
            SetOptionalVisible("Layer/MessageBoxUI/GoldNum", false);
            SetOptionalVisible("Layer/MessageBoxUI/DesBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/CheckBox", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm3", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm2/Time", false);
            Hide();
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;

        public void Show(string heading, string detail)
        {
            confirmation = null;
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

        public void ShowConfirmation(string heading, string detail, Action onConfirm)
        {
            confirmation = onConfirm ?? throw new ArgumentNullException(nameof(onConfirm));
            title.text = string.IsNullOrEmpty(heading) ? "购买确认" : heading;
            message.text = detail ?? string.Empty;
            message.gameObject.SetActive(true);
            singleConfirm.gameObject.SetActive(false);
            cancelButton.gameObject.SetActive(true);
            confirmButton.gameObject.SetActive(true);
            SetButtonText(cancelButton, "取消");
            SetButtonText(confirmButton, "确定");
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Confirm()
        {
            Action callback = confirmation;
            Hide();
            callback?.Invoke();
        }

        public void Hide()
        {
            confirmation = null;
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

        private void SetOptionalVisible(string path, bool visible)
        {
            view.Binding.Find(path)?.SetActive(visible);
        }
    }
}
