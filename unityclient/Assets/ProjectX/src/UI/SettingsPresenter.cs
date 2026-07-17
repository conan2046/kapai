using System;
using ProjectX.UI.Migration;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class SettingsPresenter
    {
        private const string MusicKey = "ProjectX.Settings.MusicVolume";
        private const string EffectsKey = "ProjectX.Settings.EffectsVolume";
        private readonly Toggle musicMuted;
        private readonly CocosUiBinding binding;
        private readonly Slider musicSlider;
        private readonly Toggle effectsMuted;
        private readonly Slider effectsSlider;
        private readonly Button returnToLoginButton;
        private bool refreshing;

        public SettingsPresenter(CocosUiView view, Action returnToLogin, Action<string> setStatus)
        {
            binding = view.Binding;
            musicMuted = Require<Toggle>(binding, "Layer/Panel/SystemBg/CheckBox_1");
            musicSlider = Require<Slider>(binding, "Layer/Panel/SystemBg/CheckBox_1/Slider");
            effectsMuted = Require<Toggle>(binding, "Layer/Panel/SystemBg/CheckBox_2");
            effectsSlider = Require<Slider>(binding, "Layer/Panel/SystemBg/CheckBox_2/Slider");
            ConfigureSlider(musicSlider);
            ConfigureSlider(effectsSlider);
            musicMuted.onValueChanged.RemoveAllListeners();
            musicSlider.onValueChanged.RemoveAllListeners();
            effectsMuted.onValueChanged.RemoveAllListeners();
            effectsSlider.onValueChanged.RemoveAllListeners();
            musicMuted.onValueChanged.AddListener(value => SetMuted(MusicKey, musicSlider, value));
            musicSlider.onValueChanged.AddListener(value => SaveVolume(MusicKey, value));
            effectsMuted.onValueChanged.AddListener(value => SetMuted(EffectsKey, effectsSlider, value));
            effectsSlider.onValueChanged.AddListener(value => SaveVolume(EffectsKey, value));
            view.BindClick("Layer/Panel/BtnList/Btn_1", () => setStatus("Announcement UI is not migrated yet."));
            view.BindClick("Layer/Panel/BtnList/Btn_5", () => setStatus("Activation-code UI is not migrated yet."));
            returnToLoginButton = view.BindClick("Layer/Panel/BtnList/Btn_4", returnToLogin);
        }

        public void Refresh(uint userId)
        {
            SetText("Layer/Panel/SystemBg/ImageBg/Name", $"角色：U{userId}");
            SetText("Layer/Panel/SystemBg/ImageBg/ServerName", "服务器：本地测试服");
            SetText("Layer/Panel/SystemBg/ImageBg/HeadIcon/Text_1", "60");
            LoadValues();
        }

        public bool ValidatePersistence(out string detail)
        {
            float originalMusic = PlayerPrefs.GetFloat(MusicKey, 1f);
            float originalEffects = PlayerPrefs.GetFloat(EffectsKey, 1f);
            musicSlider.value = 0.35f;
            effectsSlider.value = 0.65f;
            PlayerPrefs.Save();
            bool persisted = Mathf.Approximately(PlayerPrefs.GetFloat(MusicKey), 0.35f)
                && Mathf.Approximately(PlayerPrefs.GetFloat(EffectsKey), 0.65f);
            PlayerPrefs.SetFloat(MusicKey, originalMusic);
            PlayerPrefs.SetFloat(EffectsKey, originalEffects);
            PlayerPrefs.Save();
            LoadValues();
            detail = persisted ? string.Empty : "Settings PlayerPrefs persistence validation failed.";
            return persisted;
        }

        public void InvokeReturnToLogin() => returnToLoginButton.onClick.Invoke();

        private void LoadValues()
        {
            refreshing = true;
            float music = Mathf.Clamp01(PlayerPrefs.GetFloat(MusicKey, 1f));
            float effects = Mathf.Clamp01(PlayerPrefs.GetFloat(EffectsKey, 1f));
            musicSlider.SetValueWithoutNotify(music);
            effectsSlider.SetValueWithoutNotify(effects);
            musicMuted.SetIsOnWithoutNotify(music <= 0f);
            effectsMuted.SetIsOnWithoutNotify(effects <= 0f);
            musicSlider.interactable = music > 0f;
            effectsSlider.interactable = effects > 0f;
            refreshing = false;
        }

        private void SetMuted(string key, Slider slider, bool muted)
        {
            if (refreshing) return;
            slider.interactable = !muted;
            slider.value = muted ? 0f : 1f;
            SaveVolume(key, slider.value);
        }

        private void SaveVolume(string key, float value)
        {
            if (refreshing) return;
            PlayerPrefs.SetFloat(key, Mathf.Clamp01(value));
            PlayerPrefs.Save();
        }

        private static void ConfigureSlider(Slider slider)
        {
            slider.minValue = 0f;
            slider.maxValue = 1f;
            slider.wholeNumbers = false;
        }

        private void SetText(string path, string value)
        {
            GameObject node = binding.Find(path);
            TMP_Text text = node != null ? node.GetComponent<TMP_Text>() : null;
            if (text != null) text.text = value;
        }

        private static T Require<T>(CocosUiBinding binding, string path) where T : Component
        {
            GameObject node = binding.Find(path);
            T component = node != null ? node.GetComponent<T>() : null;
            if (component == null) throw new InvalidOperationException($"Settings component {typeof(T).Name} was not found: {path}");
            return component;
        }
    }
}
