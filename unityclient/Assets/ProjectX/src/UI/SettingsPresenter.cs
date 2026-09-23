using System;
using System.Collections.Generic;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.UI.Migration;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class SettingsPresenter
    {
        public const string MusicClosedKey = "ProjectX.Settings.IsMusicClosed";
        public const string EffectsClosedKey = "ProjectX.Settings.IsEffectClosed";
        public const string MusicVolumeKey = "ProjectX.Settings.MusicVolume";
        public const string EffectsVolumeKey = "ProjectX.Settings.EffectsVolume";
        public const string ResolutionWidthKey = "ProjectX.Settings.ResolutionWidth";
        public const string ResolutionHeightKey = "ProjectX.Settings.ResolutionHeight";
        public const string FullScreenKey = "ProjectX.Settings.FullScreen";

        private readonly CocosUiView view;
        private readonly OneLevelFrameCoordinator oneLevelFrame;
        private readonly CocosUiView frameView;
        private readonly CocosUiBinding binding;
        private readonly CocosUiBinding frameBinding;
        private readonly PlayerStore player;
        private readonly CurrencyStore currencies;
        private readonly ResourceService resources;
        private readonly Action<string> setStatus;
        private readonly bool singlePlayerMode;
        private readonly Toggle musicMuted;
        private readonly Slider musicSlider;
        private readonly Toggle effectsMuted;
        private readonly Slider effectsSlider;
        private readonly Dropdown resolutionDropdown;
        private readonly Toggle fullScreenToggle;
        private readonly List<Vector2Int> resolutionOptions = new List<Vector2Int>();
        private readonly Button saveDisplayButton;
        private readonly Button returnToLoginButton;
        private readonly Button announcementButton;
        private readonly Button activationButton;
        private Button closeButton;
        private Button infoTabButton;
        private Button settingsTabButton;
        private Button staminaAddButton;
        private Button goldAddButton;
        private Button premiumAddButton;
        private bool refreshing;
        private bool refreshingDisplay;
        private bool simulatePersistenceUnavailable;
        private bool simulateAudioUnavailable;

        public SettingsPresenter(CocosUiView view, OneLevelFrameCoordinator oneLevelFrame,
            PlayerStore player,
            CurrencyStore currencies, ResourceService resources, Action close, Action returnToLogin,
            Action<string> setStatus, bool singlePlayerMode = false, Action saveGame = null,
            Action exitGame = null)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.oneLevelFrame = oneLevelFrame ?? throw new ArgumentNullException(nameof(oneLevelFrame));
            frameView = oneLevelFrame.View;
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.setStatus = setStatus ?? (_ => { });
            this.singlePlayerMode = singlePlayerMode;
            binding = view.Binding;
            frameBinding = frameView.Binding;

            musicMuted = Require<Toggle>(binding, "Layer/Panel/SystemBg/CheckBox_1");
            musicSlider = Require<Slider>(binding, "Layer/Panel/SystemBg/CheckBox_1/Slider");
            effectsMuted = Require<Toggle>(binding, "Layer/Panel/SystemBg/CheckBox_2");
            effectsSlider = Require<Slider>(binding, "Layer/Panel/SystemBg/CheckBox_2/Slider");
            ConfigureSlider(musicSlider);
            ConfigureSlider(effectsSlider);
            BindAudioControls();

            resolutionDropdown = Require<Dropdown>(binding, "Layer/Panel/SystemBg/Resolution/Dropdown");
            fullScreenToggle = Require<Toggle>(binding, "Layer/Panel/SystemBg/Resolution/FullScreen");
            BindDisplayControls();
            saveDisplayButton = view.BindClick("Layer/Panel/BtnList/Btn_6", SaveDisplaySelection, true);

            if (singlePlayerMode)
            {
                announcementButton = view.BindClick("Layer/Panel/BtnList/Btn_1",
                    saveGame ?? throw new ArgumentNullException(nameof(saveGame)), true);
                SetText(binding, "Layer/Panel/BtnList/Btn_1/BtnName", "保存游戏");
                activationButton = view.BindClick("Layer/Panel/BtnList/Btn_5", () => { }, true);
                activationButton.gameObject.SetActive(false);
                returnToLoginButton = view.BindClick("Layer/Panel/BtnList/Btn_4",
                    exitGame ?? throw new ArgumentNullException(nameof(exitGame)), true);
                SetText(binding, "Layer/Panel/BtnList/Btn_4/BtnName", "离开游戏");
            }
            else
            {
                announcementButton = view.BindClick("Layer/Panel/BtnList/Btn_1",
                    () => this.setStatus("游戏公告属于 NoticeUI /88 边界；Settings 不读取或伪造公告正文。"), true);
                activationButton = view.BindClick("Layer/Panel/BtnList/Btn_5",
                    () => this.setStatus("兑换码属于 Welfare.NewActiveCodeUI /199 op=18 边界；Settings 不处理兑换。"), true);
                returnToLoginButton = view.BindClick("Layer/Panel/BtnList/Btn_4", returnToLogin, true);
            }
            ConfigureFrame(close);
        }

        public float MusicVolume => musicSlider.value / 100f;
        public float EffectsVolume => effectsSlider.value / 100f;
        public bool MusicClosed => musicMuted.isOn;
        public bool EffectsClosed => effectsMuted.isOn;
        public Vector2Int SelectedResolution => resolutionOptions[resolutionDropdown.value];
        public bool FullScreen => fullScreenToggle.isOn;
        public float AppliedMusicVolume { get; private set; } = 1f;
        public float AppliedEffectsVolume { get; private set; } = 1f;
        public string LastFailure { get; private set; } = string.Empty;
        public bool HasAllControls => closeButton != null && infoTabButton != null && settingsTabButton != null
            && staminaAddButton != null && goldAddButton != null && premiumAddButton != null
            && announcementButton != null && activationButton != null && returnToLoginButton != null
            && resolutionDropdown != null && fullScreenToggle != null && saveDisplayButton != null
            && resolutionOptions.Count > 0;
        public bool PremiumAddDisabled => premiumAddButton != null && !premiumAddButton.interactable;

        public void Refresh()
        {
            SetActive(frameBinding, "Layer/GoldCheck", true);
            SetActive(frameBinding, "Layer/Panel_12/Bg/Btn_ListView", true);
            SetActive(binding, "Layer/Panel/SystemBg/ImageBg", true);
            SetActive(binding, "Layer/Panel/BtnList", true);
            SetActive(binding, "Layer/Panel/BtnList/Btn_6", true);
            if (singlePlayerMode)
            {
                SetActive(binding, "Layer/Panel/BtnList/Btn_1", true);
                SetActive(binding, "Layer/Panel/BtnList/Btn_4", true);
                SetActive(binding, "Layer/Panel/BtnList/Btn_5", false);
            }
            ConfigureFrame(null);
            SetText(binding, "Layer/Panel/SystemBg/ImageBg/Name", $"角色：{player.Name}");
            SetText(binding, "Layer/Panel/SystemBg/ImageBg/ServerName", "存档：本地");
            SetText(binding, "Layer/Panel/SystemBg/ImageBg/HeadIcon/Text_1", player.Level.ToString());
            GameObject headObject = binding.Find("Layer/Panel/SystemBg/ImageBg/HeadIcon/HeadImage");
            Image head = headObject != null ? headObject.GetComponent<Image>() : null;
            if (head != null) head.sprite = resources.LoadPlayerRoundPortrait(player.Head);
            LoadValues();
            RefreshDisplayControls();
        }

        public void RefreshForTitle()
        {
            ConfigureFrame(null);
            SetText(frameBinding, "Layer/Panel_12/Title/TitleName", "游戏设置");
            SetActive(frameBinding, "Layer/GoldCheck", false);
            SetActive(frameBinding, "Layer/Panel_12/Bg/Btn_ListView", false);
            SetActive(binding, "Layer/Panel/SystemBg/ImageBg", false);
            SetActive(binding, "Layer/Panel/BtnList", true);
            SetActive(binding, "Layer/Panel/BtnList/Btn_1", false);
            SetActive(binding, "Layer/Panel/BtnList/Btn_4", false);
            SetActive(binding, "Layer/Panel/BtnList/Btn_5", false);
            SetActive(binding, "Layer/Panel/BtnList/Btn_6", true);
            LoadValues();
            RefreshDisplayControls();
        }

        public void InvokeClose() => closeButton.onClick.Invoke();
        public void InvokeInfoBoundary() => setStatus("角色信息页属于既有角色模块边界；Settings 保持当前页，不扩展角色信息。");
        public void InvokeStaminaBoundary() => staminaAddButton.onClick.Invoke();
        public void InvokeGoldBoundary() => goldAddButton.onClick.Invoke();
        public void InvokeAnnouncementBoundary() => announcementButton.onClick.Invoke();
        public void InvokeActivationBoundary() => activationButton.onClick.Invoke();
        public void InvokeReturnToLogin() => returnToLoginButton.onClick.Invoke();
        public void SetMusicMuted(bool value) => musicMuted.isOn = value;
        public void SetEffectsMuted(bool value) => effectsMuted.isOn = value;
        public void SetMusicPercent(float value) => musicSlider.value = value;
        public void SetEffectsPercent(float value) => effectsSlider.value = value;
        public void ReloadFromDevice() => LoadValues();
        public void SetFailureSimulation(bool persistenceUnavailable, bool audioUnavailable)
        {
            simulatePersistenceUnavailable = persistenceUnavailable;
            simulateAudioUnavailable = audioUnavailable;
            LastFailure = string.Empty;
        }

        public bool ValidateIdentityAndHeader(out string detail)
        {
            bool valid = player.IsLoaded && !string.IsNullOrWhiteSpace(player.Name)
                && ReadText(binding, "Layer/Panel/SystemBg/ImageBg/Name") == $"角色：{player.Name}"
                && ReadText(binding, "Layer/Panel/SystemBg/ImageBg/HeadIcon/Text_1") == player.Level.ToString()
                && ReadText(frameBinding, "Layer/GoldCheck/GoldIcon1/GoldNumBg/Num") == $"{currencies.Stamina}/100"
                && ReadText(frameBinding, "Layer/GoldCheck/GoldIcon3/GoldNumBg/Num") == FormatCurrency(currencies.Gold)
                && ReadText(frameBinding, "Layer/GoldCheck/GoldIcon4/GoldNumBg/Num") == currencies.Premium.ToString();
            detail = valid ? $"role={player.RoleId} name={player.Name} level={player.Level}"
                : "Settings identity/header did not match authoritative PlayerStore/CurrencyStore.";
            return valid;
        }

        public bool ValidateAudioState(float music, float effects, bool musicClosed, bool effectsClosed)
        {
            return Mathf.Approximately(MusicVolume, music) && Mathf.Approximately(EffectsVolume, effects)
                && MusicClosed == musicClosed && EffectsClosed == effectsClosed
                && Mathf.Approximately(AppliedMusicVolume, musicClosed ? 0f : music)
                && Mathf.Approximately(AppliedEffectsVolume, effectsClosed ? 0f : effects);
        }

        private void ConfigureFrame(Action close)
        {
            oneLevelFrame.Apply(OneLevelFrameMode.Standard);
            RectTransform root = frameBinding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            SetText(frameBinding, "Layer/Panel_12/Title/TitleName", "角色信息");
            Transform help = frameBinding.Find("Layer/Panel_12/Title/TitleName")?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);

            // The outer OneLevelLayer tab strip is owned by PlayerHubTabCoordinator.
            // Settings remains a content page; it must not overwrite the shared
            // 境界/背包/邮件/系统 tabs during Refresh(). Keep compatibility
            // handles for existing validation, but leave their visual state and
            // listeners to the shared coordinator.
            Transform panel = frameBinding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (first == null) throw new InvalidOperationException("Settings shared tab template was not found.");
            Transform second = panel.Find("Button2_Runtime");
            if (second == null)
            {
                second = UnityEngine.Object.Instantiate(first.gameObject, panel, false).transform;
                second.name = "Button2_Runtime";
            }
            infoTabButton = EnsureButton(first);
            settingsTabButton = EnsureButton(second);

            SetText(frameBinding, "Layer/GoldCheck/GoldIcon1/GoldNumBg/Num", $"{currencies.Stamina}/100");
            SetText(frameBinding, "Layer/GoldCheck/GoldIcon3/GoldNumBg/Num", FormatCurrency(currencies.Gold));
            SetText(frameBinding, "Layer/GoldCheck/GoldIcon4/GoldNumBg/Num", currencies.Premium.ToString());
            staminaAddButton = BindFrameButton("Layer/GoldCheck/GoldIcon1/AddBtn",
                () => setStatus("体力使用/购买属于外部边界；Settings 未触发购买。"), true);
            goldAddButton = BindFrameButton("Layer/GoldCheck/GoldIcon3/AddBtn",
                () => setStatus("金币商城属于 Shop 边界；Settings 未触发购买或支付。"), true);
            premiumAddButton = BindFrameButton("Layer/GoldCheck/GoldIcon4/AddBtn", null, false);
            foreach (Transform child in frameBinding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);

            if (close != null)
            {
                closeButton = frameView.BindClick("Layer/Panel_12/Title/CloseBtn", () =>
                {
                    oneLevelFrame.SetVisible(false);
                    close();
                }, true);
            }
        }

        private void BindAudioControls()
        {
            musicMuted.onValueChanged.RemoveAllListeners();
            musicSlider.onValueChanged.RemoveAllListeners();
            effectsMuted.onValueChanged.RemoveAllListeners();
            effectsSlider.onValueChanged.RemoveAllListeners();
            musicMuted.onValueChanged.AddListener(value => SetMuted(true, value));
            musicSlider.onValueChanged.AddListener(value => SaveVolume(true, value));
            effectsMuted.onValueChanged.AddListener(value => SetMuted(false, value));
            effectsSlider.onValueChanged.AddListener(value => SaveVolume(false, value));
        }

        private void BindDisplayControls()
        {
            resolutionOptions.Clear();
            for (int index = 0; index < resolutionDropdown.options.Count; index++)
            {
                string label = resolutionDropdown.options[index].text;
                if (!TryParseResolution(label, out Vector2Int resolution))
                    throw new InvalidOperationException($"Settings resolution option is invalid: {label}");
                resolutionOptions.Add(resolution);
            }
            if (resolutionOptions.Count == 0)
                throw new InvalidOperationException("Settings resolution dropdown has no options.");

            resolutionDropdown.onValueChanged.RemoveAllListeners();
            fullScreenToggle.onValueChanged.RemoveAllListeners();
            resolutionDropdown.onValueChanged.AddListener(NormalizePendingResolutionSelection);
            fullScreenToggle.onValueChanged.AddListener(_ =>
            {
                if (!refreshingDisplay) setStatus("显示模式已修改，点击保存后生效。");
            });
            RefreshDisplayControls();
        }

        private void RefreshDisplayControls()
        {
            bool hasSavedResolution = TryReadSavedDisplayPreferences(out Vector2Int savedResolution,
                out bool savedFullScreen);
            Vector2Int requested = hasSavedResolution
                ? savedResolution
                : new Vector2Int(Screen.width, Screen.height);
            int selectedIndex = FindClosestResolutionIndex(requested, GetCurrentDisplayResolution());
            refreshingDisplay = true;
            resolutionDropdown.SetValueWithoutNotify(selectedIndex);
            resolutionDropdown.RefreshShownValue();
            fullScreenToggle.SetIsOnWithoutNotify(hasSavedResolution ? savedFullScreen : Screen.fullScreen);
            refreshingDisplay = false;
        }

        private void NormalizePendingResolutionSelection(int requestedIndex)
        {
            if (refreshingDisplay) return;
            if (requestedIndex < 0 || requestedIndex >= resolutionOptions.Count) return;

            Vector2Int displayLimit = GetCurrentDisplayResolution();
            int resolvedIndex = FindClosestResolutionIndex(resolutionOptions[requestedIndex], displayLimit);
            Vector2Int requested = resolutionOptions[requestedIndex];
            Vector2Int resolved = resolutionOptions[resolvedIndex];
            if (resolvedIndex != requestedIndex)
            {
                refreshingDisplay = true;
                resolutionDropdown.SetValueWithoutNotify(resolvedIndex);
                resolutionDropdown.RefreshShownValue();
                refreshingDisplay = false;
                setStatus($"{requested.x} x {requested.y} 超过当前屏幕 {displayLimit.x} x {displayLimit.y}，已重置为 {resolved.x} x {resolved.y}；点击保存后生效。");
                return;
            }
            setStatus($"已选择 {resolved.x} x {resolved.y}，点击保存后生效。");
        }

        private void SaveDisplaySelection()
        {
            int requestedIndex = resolutionDropdown.value;
            if (requestedIndex < 0 || requestedIndex >= resolutionOptions.Count) return;

            Vector2Int displayLimit = GetCurrentDisplayResolution();
            int resolvedIndex = FindClosestResolutionIndex(resolutionOptions[requestedIndex], displayLimit);
            Vector2Int resolved = resolutionOptions[resolvedIndex];
            if (resolvedIndex != requestedIndex)
            {
                refreshingDisplay = true;
                resolutionDropdown.SetValueWithoutNotify(resolvedIndex);
                resolutionDropdown.RefreshShownValue();
                refreshingDisplay = false;
            }

            try
            {
                if (simulatePersistenceUnavailable)
                    throw new InvalidOperationException("simulated persistence unavailable");
                PlayerPrefs.SetInt(ResolutionWidthKey, resolved.x);
                PlayerPrefs.SetInt(ResolutionHeightKey, resolved.y);
                PlayerPrefs.SetInt(FullScreenKey, fullScreenToggle.isOn ? 1 : 0);
                PlayerPrefs.Save();
                FullScreenMode mode = fullScreenToggle.isOn
                    ? FullScreenMode.FullScreenWindow
                    : FullScreenMode.Windowed;
                Screen.SetResolution(resolved.x, resolved.y, mode);
                ApplyEditorGameViewResolution(resolved.x, resolved.y);
                LastFailure = string.Empty;
                setStatus($"显示设置已保存并生效：{resolved.x} x {resolved.y}（{(fullScreenToggle.isOn ? "全屏" : "窗口")}）。");
            }
            catch (Exception exception)
            {
                LastFailure = "显示设置保存失败：" + exception.Message;
                setStatus(LastFailure);
            }
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void ApplySavedDisplayPreferencesOnLaunch()
        {
            if (Application.isBatchMode
                || !TryReadSavedDisplayPreferences(out Vector2Int savedResolution, out bool savedFullScreen)) return;
            Vector2Int displayLimit = GetCurrentDisplayResolution();
            int width = Mathf.Min(savedResolution.x, displayLimit.x);
            int height = Mathf.Min(savedResolution.y, displayLimit.y);
            FullScreenMode mode = savedFullScreen ? FullScreenMode.FullScreenWindow : FullScreenMode.Windowed;
            Screen.SetResolution(width, height, mode);
            ApplyEditorGameViewResolution(width, height);
        }

        private static void ApplyEditorGameViewResolution(int width, int height)
        {
#if UNITY_EDITOR
            Type runnerType = Type.GetType("ProjectX.Editor.BootstrapAppRunner, Assembly-CSharp-Editor");
            System.Reflection.MethodInfo method = runnerType?.GetMethod(
                "ApplyPlayerSelectedGameViewResolution",
                System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
            method?.Invoke(null, new object[] { width, height });
#endif
        }

        private static bool TryReadSavedDisplayPreferences(out Vector2Int resolution, out bool fullScreen)
        {
            resolution = default;
            fullScreen = Screen.fullScreen;
            if (!PlayerPrefs.HasKey(ResolutionWidthKey) || !PlayerPrefs.HasKey(ResolutionHeightKey))
                return false;
            int width = PlayerPrefs.GetInt(ResolutionWidthKey, 0);
            int height = PlayerPrefs.GetInt(ResolutionHeightKey, 0);
            if (width <= 0 || height <= 0) return false;
            resolution = new Vector2Int(width, height);
            fullScreen = PlayerPrefs.GetInt(FullScreenKey, Screen.fullScreen ? 1 : 0) != 0;
            return true;
        }

        private int FindClosestResolutionIndex(Vector2Int requested, Vector2Int displayLimit)
        {
            int bestIndex = -1;
            long bestDistance = long.MaxValue;
            for (int index = 0; index < resolutionOptions.Count; index++)
            {
                Vector2Int option = resolutionOptions[index];
                if (option.x > displayLimit.x || option.y > displayLimit.y) continue;
                long distance = ResolutionDistance(option, requested);
                if (distance >= bestDistance) continue;
                bestDistance = distance;
                bestIndex = index;
            }
            if (bestIndex >= 0) return bestIndex;

            // Extremely small displays may not fit even the smallest configured option.
            // Keep the selection inside the configured list and choose the nearest one.
            for (int index = 0; index < resolutionOptions.Count; index++)
            {
                long distance = ResolutionDistance(resolutionOptions[index], displayLimit);
                if (distance >= bestDistance) continue;
                bestDistance = distance;
                bestIndex = index;
            }
            return Mathf.Max(0, bestIndex);
        }

        private static Vector2Int GetCurrentDisplayResolution()
        {
            Resolution current = Screen.currentResolution;
            int width = current.width > 0 ? current.width : Screen.width;
            int height = current.height > 0 ? current.height : Screen.height;
            return new Vector2Int(Mathf.Max(1, width), Mathf.Max(1, height));
        }

        private static long ResolutionDistance(Vector2Int left, Vector2Int right)
        {
            long width = left.x - right.x;
            long height = left.y - right.y;
            return width * width + height * height;
        }

        private static bool TryParseResolution(string value, out Vector2Int resolution)
        {
            resolution = default;
            if (string.IsNullOrWhiteSpace(value)) return false;
            string[] parts = value.Split(new[] { 'x', 'X', '×' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length != 2
                || !int.TryParse(parts[0].Trim(), out int width)
                || !int.TryParse(parts[1].Trim(), out int height)
                || width <= 0 || height <= 0) return false;
            resolution = new Vector2Int(width, height);
            return true;
        }

        private void LoadValues()
        {
            refreshing = true;
            bool musicClosed = PlayerPrefs.GetInt(MusicClosedKey, 0) != 0;
            bool effectsClosed = PlayerPrefs.GetInt(EffectsClosedKey, 0) != 0;
            float music = NormalizeVolume(PlayerPrefs.GetFloat(MusicVolumeKey, 1f));
            float effects = NormalizeVolume(PlayerPrefs.GetFloat(EffectsVolumeKey, 1f));
            musicMuted.SetIsOnWithoutNotify(musicClosed);
            effectsMuted.SetIsOnWithoutNotify(effectsClosed);
            musicSlider.SetValueWithoutNotify((musicClosed ? 0f : music) * 100f);
            effectsSlider.SetValueWithoutNotify((effectsClosed ? 0f : effects) * 100f);
            musicSlider.interactable = !musicClosed;
            effectsSlider.interactable = !effectsClosed;
            refreshing = false;
            ApplyAudio(musicClosed ? 0f : music, effectsClosed ? 0f : effects);
        }

        private void SetMuted(bool musicChannel, bool muted)
        {
            if (refreshing) return;
            Slider slider = musicChannel ? musicSlider : effectsSlider;
            slider.interactable = !muted;
            refreshing = true;
            slider.SetValueWithoutNotify(muted ? 0f : 100f);
            refreshing = false;
            string closedKey = musicChannel ? MusicClosedKey : EffectsClosedKey;
            string volumeKey = musicChannel ? MusicVolumeKey : EffectsVolumeKey;
            SavePreferences(closedKey, muted, volumeKey, slider.value / 100f);
            ApplyAudio(musicMuted.isOn ? 0f : MusicVolume, effectsMuted.isOn ? 0f : EffectsVolume);
        }

        private void SaveVolume(bool musicChannel, float percent)
        {
            if (refreshing) return;
            float volume = Mathf.Clamp(percent, 0f, 100f) / 100f;
            string volumeKey = musicChannel ? MusicVolumeKey : EffectsVolumeKey;
            if (!SavePreferences(null, false, volumeKey, volume)) return;
            ApplyAudio(musicMuted.isOn ? 0f : MusicVolume, effectsMuted.isOn ? 0f : EffectsVolume);
        }

        private bool SavePreferences(string closedKey, bool closed, string volumeKey, float volume)
        {
            try
            {
                if (simulatePersistenceUnavailable) throw new InvalidOperationException("simulated persistence unavailable");
                if (!string.IsNullOrEmpty(closedKey)) PlayerPrefs.SetInt(closedKey, closed ? 1 : 0);
                PlayerPrefs.SetFloat(volumeKey, NormalizeVolume(volume));
                PlayerPrefs.Save();
                LastFailure = string.Empty;
                return true;
            }
            catch (Exception exception)
            {
                LastFailure = "设置保存失败：" + exception.Message;
                setStatus(LastFailure);
                return false;
            }
        }

        private bool ApplyAudio(float music, float effects)
        {
            try
            {
                if (simulateAudioUnavailable) throw new InvalidOperationException("simulated audio service unavailable");
                AppliedMusicVolume = Mathf.Clamp01(music);
                AppliedEffectsVolume = Mathf.Clamp01(effects);
                foreach (AudioSource source in UnityEngine.Object.FindObjectsOfType<AudioSource>(true))
                {
                    string token = (source.name + " " + source.gameObject.name).ToLowerInvariant();
                    source.volume = token.Contains("music") || token.Contains("bgm")
                        ? AppliedMusicVolume : AppliedEffectsVolume;
                }
                LastFailure = string.Empty;
                return true;
            }
            catch (Exception exception)
            {
                LastFailure = "音频应用失败：" + exception.Message;
                setStatus(LastFailure);
                return false;
            }
        }

        private Button BindFrameButton(string path, Action action, bool interactable)
        {
            GameObject node = frameBinding.Find(path);
            if (node == null) throw new InvalidOperationException("Settings frame node was not found: " + path);
            Button button = EnsureButton(node.transform);
            button.onClick.RemoveAllListeners();
            button.interactable = interactable;
            if (action != null) button.onClick.AddListener(() => action());
            return button;
        }

        private static Button EnsureButton(Transform target)
        {
            Button button = target.GetComponent<Button>();
            if (button == null)
            {
                button = target.gameObject.AddComponent<Button>();
                button.targetGraphic = target.GetComponent<Graphic>();
            }
            return button;
        }

        private static void SetTab(Transform tab, string value, bool selected)
        {
            Transform normalLabel = tab.Find("BtnName");
            SetText(normalLabel, value);
            if (normalLabel != null) normalLabel.gameObject.SetActive(!selected);
            SetText(tab.Find("ChooseBg/BtnName"), value);
            Transform choose = tab.Find("ChooseBg");
            if (choose != null) choose.gameObject.SetActive(selected);
            Image background = tab.GetComponent<Image>();
            if (background != null) background.color = selected ? Color.white : new Color(1f, 1f, 1f, 0f);
        }

        private static void ConfigureSlider(Slider slider)
        {
            slider.minValue = 0f;
            slider.maxValue = 100f;
            slider.wholeNumbers = false;
            if (slider.handleRect != null)
            {
                Image handleImage = slider.handleRect.GetComponent<Image>();
                Vector2 nativeSize = handleImage != null && handleImage.sprite != null
                    ? handleImage.sprite.rect.size
                    : new Vector2(36f, 38f);
                slider.handleRect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, nativeSize.x);
                slider.handleRect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, nativeSize.y);
            }
            ColorBlock colors = slider.colors;
            colors.disabledColor = Color.white;
            slider.colors = colors;
        }

        private static float NormalizeVolume(float value) =>
            float.IsNaN(value) || float.IsInfinity(value) || value < 0f || value > 1f ? 1f : value;

        private static string FormatCurrency(long value) =>
            value >= 10000 && value % 10000 == 0 ? $"{value / 10000}万" : value.ToString();

        private static void SetText(CocosUiBinding target, string path, string value) =>
            SetText(target.Find(path)?.transform, value);

        private static void SetActive(CocosUiBinding target, string path, bool active)
        {
            GameObject node = target?.Find(path);
            if (node != null) node.SetActive(active);
        }

        private static void SetText(Transform target, string value)
        {
            if (target == null) return;
            Text legacy = target.GetComponent<Text>();
            TMP_Text tmp = target.GetComponent<TMP_Text>();
            if (legacy != null) legacy.text = value ?? string.Empty;
            if (tmp != null) tmp.text = value ?? string.Empty;
        }

        private static string ReadText(CocosUiBinding target, string path)
        {
            Transform node = target.Find(path)?.transform;
            if (node == null) return string.Empty;
            Text legacy = node.GetComponent<Text>();
            TMP_Text tmp = node.GetComponent<TMP_Text>();
            return legacy != null ? legacy.text : tmp != null ? tmp.text : string.Empty;
        }

        private static T Require<T>(CocosUiBinding target, string path) where T : Component
        {
            GameObject node = target.Find(path);
            T component = node != null ? node.GetComponent<T>() : null;
            if (component == null)
                throw new InvalidOperationException($"Settings component {typeof(T).Name} was not found: {path}");
            return component;
        }
    }
}
