using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class WelfareActivityFramePresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly CurrencyStore currencies;
        private readonly GameObject staminaTab;
        private readonly GameObject recoveryTab;
        private readonly GameObject growthTab;
        private readonly GameObject activeTab;

        public WelfareActivityFramePresenter(CocosUiView view, CurrencyStore currencies, Action close,
            Action stamina, Action recovery, Action growth, Action active)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            Transform root = view.GameObject.transform;
            Bind(view.Binding.Find("Layer/Panel_1/Title/CloseBtn")?.transform, close);
            Transform template = view.Binding.Find("Layer/Panel_1/Btn_ListView/Panel_1")?.transform;
            if (template == null) throw new InvalidOperationException("Welfare activity tab template was not found.");
            staminaTab = template.gameObject;
            recoveryTab = UnityEngine.Object.Instantiate(staminaTab, template.parent, false);
            recoveryTab.name = "Panel_ResourceRecovery";
            growthTab = UnityEngine.Object.Instantiate(staminaTab, template.parent, false);
            growthTab.name = "Panel_GrowthFund";
            activeTab = UnityEngine.Object.Instantiate(staminaTab, template.parent, false);
            activeTab.name = "Panel_ActiveFund";
            RectTransform source = staminaTab.GetComponent<RectTransform>();
            RectTransform clone = recoveryTab.GetComponent<RectTransform>();
            if (source != null && clone != null)
                clone.anchoredPosition = source.anchoredPosition + new Vector2(0f, -Mathf.Max(82f, source.rect.height));
            float spacing = Mathf.Max(82f, source?.rect.height ?? 82f);
            RectTransform growthRect=growthTab.GetComponent<RectTransform>(); if(source!=null&&growthRect!=null)growthRect.anchoredPosition=source.anchoredPosition+new Vector2(0f,-spacing*2f);
            RectTransform activeRect=activeTab.GetComponent<RectTransform>(); if(source!=null&&activeRect!=null)activeRect.anchoredPosition=source.anchoredPosition+new Vector2(0f,-spacing*3f);
            ConfigureTab(staminaTab.transform, "体力领取", stamina);
            ConfigureTab(recoveryTab.transform, "资源找回", recovery);
            ConfigureTab(growthTab.transform, "成长基金", growth);
            ConfigureTab(activeTab.transform, "活跃基金", active);
            Disable(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon1/AddBtn")?.transform);
            Disable(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon3/AddBtn")?.transform);
            Disable(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon4/AddBtn")?.transform);
            currencies.Changed += RenderCurrencies;
            RenderCurrencies();
        }

        public void Select(int functionId)
        {
            string title=functionId==19?"资源找回":functionId==25?"成长基金":functionId==26?"活跃基金":"体力领取";
            SetText(view.Binding.Find("Layer/Panel_1/Title/TitleName")?.transform, title);
            SetSelected(staminaTab.transform, functionId == 18);
            SetSelected(recoveryTab.transform, functionId == 19);
            SetSelected(growthTab.transform, functionId == 25);
            SetSelected(activeTab.transform, functionId == 26);
        }

        public void Dispose() => currencies.Changed -= RenderCurrencies;

        private void RenderCurrencies()
        {
            SetText(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon1/GoldNumBg/Num")?.transform, currencies.Stamina.ToString());
            SetText(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon3/GoldNumBg/Num")?.transform, currencies.Gold.ToString());
            SetText(view.Binding.Find("Layer/Panel_1/GoldCheck/GoldIcon4/GoldNumBg/Num")?.transform, currencies.Premium.ToString());
        }

        private static void ConfigureTab(Transform root, string name, Action action)
        {
            SetText(root, "Button/BtnName", name);
            SetText(root, "Button/ChooseBg/BtnName", name);
            Bind(root.Find("Button"), action);
            Transform prompt = root.Find("Button/Prompt");
            if (prompt != null) prompt.gameObject.SetActive(false);
        }

        private static void SetSelected(Transform root, bool selected)
        {
            Transform choose = root.Find("Button/ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Button button = root.Find("Button")?.GetComponent<Button>();
            if (button != null) button.interactable = !selected;
        }

        private static void Bind(Transform target, Action action)
        {
            Button button = target?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action?.Invoke());
        }
        private static void Disable(Transform target)
        {
            Button button = target?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners(); button.interactable = false;
        }
        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value;
        }
        private static void SetText(Transform target, string value)
        {
            Text text = target?.GetComponent<Text>(); if (text != null) text.text = value;
        }
    }
}
