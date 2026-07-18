using System;
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

        public StaminaClaimPresenter(CocosUiView view, StaminaClaimStore store,
            StaminaClaimCatalog catalog, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            Normalize(view.GameObject.transform);
            DisableAllClaimButtons();
            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && store.Items.Count == 3;
        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            Transform root = view.GameObject.transform;
            foreach (StaminaClaimDefinition definition in catalog.Items)
            {
                Transform panel = root.Find($"Panel_lingtili/Panel_{definition.Id + 2}");
                if (panel == null) continue;
                byte state = store.StateOf(definition.Id);
                SetText(panel, "Panel_1/Text_tili", $"领取体力 {definition.Stamina} 点");
                SetText(panel, "Panel_1/Text_time", definition.TimeText);
                SetVisible(panel.Find("Panel_1"), state != 3);
                SetVisible(panel.Find("Button_bg"), state != 3);
                SetVisible(panel.Find("Image_gaizi"), state == 0);
                SetVisible(panel.Find("Text_1"), state == 1);
                SetVisible(panel.Find("Text_2"), state == 2);
                SetText(panel, "Text_1", "可领取（首期只读）");
                SetText(panel, "Text_2", $"{definition.PremiumCost}元宝补领（首期只读）");
            }
        }

        private void DisableAllClaimButtons()
        {
            Transform root = view.GameObject.transform;
            for (int i = 3; i <= 5; i++)
            {
                Button button = root.Find($"Panel_lingtili/Panel_{i}/Button_bg")?.GetComponent<Button>();
                if (button == null) continue;
                button.onClick.RemoveAllListeners();
                button.interactable = false;
            }
        }

        private static void SetText(Transform root, string path, string value) { Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value; }
        private static void SetVisible(Transform target, bool visible) { if (target != null) target.gameObject.SetActive(visible); }
        private static void Normalize(Transform root) { if (!(root is RectTransform rect)) return; rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(0.5f, 0.5f); rect.offsetMin = rect.offsetMax = Vector2.zero; rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity; }
    }
}
