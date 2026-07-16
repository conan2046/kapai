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

        public GameErrorPresenter(CocosUiView view)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            title = RequireText("Layer/MessageBoxUI/bg/Title");
            message = RequireText("Layer/MessageBoxUI/TipsText");
            BindDismiss("Layer/MessageBoxUI/bg/Btn_close");
            BindDismiss("Layer/MessageBoxUI/Btn_Confirm");
            SetOptionalVisible("Layer/MessageBoxUI/IconBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/Spend", false);
            SetOptionalVisible("Layer/MessageBoxUI/GoldNum", false);
            SetOptionalVisible("Layer/MessageBoxUI/DesBg1", false);
            SetOptionalVisible("Layer/MessageBoxUI/CheckBox", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm1", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm2", false);
            SetOptionalVisible("Layer/MessageBoxUI/Btn_Confirm3", false);
            Hide();
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;

        public void Show(string heading, string detail)
        {
            title.text = string.IsNullOrEmpty(heading) ? "提示" : heading;
            message.text = detail ?? string.Empty;
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Hide() => view.SetVisible(false);

        private void BindDismiss(string path)
        {
            GameObject node = view.Binding.Find(path);
            if (node == null) return;
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(Hide);
        }

        private Text RequireText(string path)
        {
            GameObject node = view.Binding.Find(path);
            Text value = node == null ? null : node.GetComponent<Text>();
            return value ?? throw new InvalidOperationException($"MessageBox text was not found: {path}");
        }

        private void SetOptionalVisible(string path, bool visible)
        {
            view.Binding.Find(path)?.SetActive(visible);
        }
    }
}
