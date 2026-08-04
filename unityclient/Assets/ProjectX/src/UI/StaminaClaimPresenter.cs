using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class StaminaClaimPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly StaminaClaimStore store;
        private readonly StaminaClaimCatalog catalog;
        private readonly CurrencyStore currencies;
        private readonly Action<byte, bool> requestClaim;
        private readonly Action<byte> requestPaidConfirmation;
        private readonly Action<byte, string> rejectLocally;
        private readonly Action<bool> setRedDot;
        private readonly Action close;
        private readonly Dictionary<byte, Button> buttons = new Dictionary<byte, Button>();

        public StaminaClaimPresenter(CocosUiView view, StaminaClaimStore store,
            StaminaClaimCatalog catalog, CurrencyStore currencies,
            Action<byte, bool> requestClaim, Action<byte> requestPaidConfirmation,
            Action<byte, string> rejectLocally, Action<bool> setRedDot, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.requestClaim = requestClaim ?? throw new ArgumentNullException(nameof(requestClaim));
            this.requestPaidConfirmation = requestPaidConfirmation ?? throw new ArgumentNullException(nameof(requestPaidConfirmation));
            this.rejectLocally = rejectLocally ?? throw new ArgumentNullException(nameof(rejectLocally));
            this.setRedDot = setRedDot ?? (_ => { });
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            Normalize(view.GameObject.transform);
            BindClaimButtons();
            store.Changed += Render;
            currencies.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && store.Items.Count == 3;
        public int BoundButtonCount => buttons.Count;
        public bool InvokeSlot(byte index)
        {
            if (!buttons.TryGetValue(index, out Button button) || !button.gameObject.activeInHierarchy) return false;
            button.onClick.Invoke();
            return true;
        }
        public void InvokeClose() => close();

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= Render;
        }

        private void BindClaimButtons()
        {
            Transform root = view.GameObject.transform;
            foreach (StaminaClaimDefinition definition in catalog.Items)
            {
                byte index = definition.Id;
                Button button = root.Find($"Panel_lingtili/Panel_{index + 2}/Button_bg")?.GetComponent<Button>();
                if (button == null) continue;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => OnSlotClicked(index));
                button.interactable = true;
                buttons[index] = button;
            }
        }

        private void OnSlotClicked(byte index)
        {
            StaminaClaimDefinition definition = null;
            foreach (StaminaClaimDefinition item in catalog.Items)
                if (item.Id == index) { definition = item; break; }
            if (definition == null || store.ClaimPending) return;
            byte state = store.StateOf(index);
            if (state != 1 && state != 2) return;
            if (currencies.Stamina + definition.AuthoritativeStamina > 1000)
            {
                rejectLocally(index, "体力补充后会超出1000上限，请先使用体力后再进行补充");
                return;
            }
            if (state == 2) requestPaidConfirmation(index);
            else requestClaim(index, false);
        }

        private void Render()
        {
            Transform root = view.GameObject.transform;
            bool redDot = false;
            foreach (StaminaClaimDefinition definition in catalog.Items)
            {
                Transform panel = root.Find($"Panel_lingtili/Panel_{definition.Id + 2}");
                if (panel == null) continue;
                byte state = store.StateOf(definition.Id);
                redDot |= state == 1 || state == 2;
                SetText(panel, "Panel_1/Text_tili", $"体力+{definition.DisplayStamina}");
                SetText(panel, "Panel_1/Text_time", definition.TimeText);
                SetVisible(panel.Find("Panel_1"), state != 3);
                SetVisible(panel.Find("Button_bg"), state != 3);
                SetVisible(panel.Find("Image_gaizi"), state == 0);
                SetVisible(panel.Find("Text_1"), state == 1);
                SetVisible(panel.Find("Text_2"), state == 2);
                SetText(panel, "Text_1", "点击领取");
                SetText(panel, "Text_2", $"花费{definition.PremiumCost}元宝补领");
                if (buttons.TryGetValue(definition.Id, out Button button))
                    button.interactable = !store.ClaimPending && (state == 1 || state == 2);
            }
            setRedDot(redDot);
        }

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }
        private static void SetVisible(Transform target, bool visible)
        {
            if (target != null) target.gameObject.SetActive(visible);
        }
        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }
}
