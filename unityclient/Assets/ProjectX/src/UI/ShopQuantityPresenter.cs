using System;
using System.Linq;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ShopQuantityPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly InputField quantityInput;
        private readonly Text valueText;
        private readonly Button[] digitButtons = new Button[10];
        private readonly Button deleteButton;
        private readonly Button confirmButton;
        private readonly Button closeButton;
        private Action<int> accepted;
        private int quantity;
        private int maximum;

        public ShopQuantityPresenter(CocosUiView source)
        {
            if (source?.GameObject == null) throw new ArgumentNullException(nameof(source));
            GameObject clone = UnityEngine.Object.Instantiate(source.GameObject,
                source.GameObject.transform.parent, false);
            clone.name = "RuntimeShopQuantityInput";
            CocosUiBinding binding = clone.GetComponent<CocosUiBinding>()
                ?? throw new InvalidOperationException("EnterNumLayer clone has no CocosUiBinding.");
            view = new CocosUiView(binding);
            GameObject inputNode = Require("Layer/Panel/Bg/Num/TextField");
            quantityInput = inputNode.GetComponent<InputField>();
            valueText = quantityInput?.textComponent
                ?? inputNode.transform.Find("Text")?.GetComponent<Text>()
                ?? inputNode.GetComponentsInChildren<Text>(true)
                    .FirstOrDefault(text => text.gameObject.name == "Text")
                ?? throw new InvalidOperationException("Shop quantity input text was not found.");
            if (quantityInput != null) quantityInput.interactable = false;
            for (int digit = 0; digit <= 9; digit++)
            {
                int captured = digit;
                digitButtons[digit] = Bind($"Layer/Panel/Bg/BtnList/Btn{digit}", () =>
                {
                    quantity = Mathf.Clamp(quantity * 10 + captured, 0, maximum);
                    Render();
                });
            }
            deleteButton = Bind("Layer/Panel/Bg/BtnList/Btn10", () =>
            {
                quantity /= 10;
                Render();
            });
            confirmButton = Bind("Layer/Panel/Bg/BtnList/Btn12", Confirm);
            closeButton = Bind("Layer/Panel/Bg/Close", Hide);
            view.SetVisible(false);
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public int Quantity => quantity;

        public bool InvokeDigit(int digit)
        {
            if (!IsVisible || digit < 0 || digit >= digitButtons.Length) return false;
            digitButtons[digit].onClick.Invoke();
            return true;
        }

        public bool InvokeDelete()
        {
            if (!IsVisible) return false;
            deleteButton.onClick.Invoke();
            return true;
        }

        public bool InvokeConfirm()
        {
            if (!IsVisible) return false;
            confirmButton.onClick.Invoke();
            return true;
        }

        public bool InvokeClose()
        {
            if (!IsVisible) return false;
            closeButton.onClick.Invoke();
            return true;
        }

        public void Show(int current, int max, Action<int> onAccepted)
        {
            maximum = Mathf.Max(1, max);
            quantity = Mathf.Clamp(current, 1, maximum);
            accepted = onAccepted ?? throw new ArgumentNullException(nameof(onAccepted));
            Render();
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Hide()
        {
            accepted = null;
            view.SetVisible(false);
        }

        public void Dispose()
        {
            accepted = null;
            if (view.GameObject != null) UnityEngine.Object.Destroy(view.GameObject);
        }

        private void Confirm()
        {
            Action<int> callback = accepted;
            int result = quantity;
            Hide();
            if (result > 0) callback?.Invoke(result);
        }

        private void Render()
        {
            string value = quantity == 0 ? string.Empty : quantity.ToString();
            if (quantityInput != null)
                quantityInput.SetTextWithoutNotify(value);
            else
                valueText.text = value;
        }

        private Button Bind(string path, Action callback)
        {
            GameObject node = Require(path);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>() ?? node.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
            return button;
        }

        private GameObject Require(string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException($"Shop quantity node was not found: {path}");
    }
}
