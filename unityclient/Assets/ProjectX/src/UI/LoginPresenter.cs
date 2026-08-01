using System;
using System.Collections.Generic;
using ProjectX.Animation;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class LoginPresenter : IDisposable
    {
        private const string Root = "Layer/Login";
        private readonly CocosUiView background;
        private readonly CocosUiView login;
        private readonly CocosUiView serverList;
        private readonly CocosUiView roleCreate;
        private ImodAnimationPlayer backgroundAnimation;
        private ImodAnimationPlayer roleBackgroundAnimation;
        private ImodAnimationPlayer roleAnimation;
        private int selectedSex = 1;
        private InputField accountInput;
        private InputField signatureInput;
        private InputField roleNameInput;
        private Action enterAction;
        private Action roleCreateAction;
        private Action roleRandomAction;
        private Action roleBackAction;
        private Action<string> validationError;
        private readonly List<string> randomNames = new List<string>();
        private int randomNameIndex;
        private bool serverSelected = true;
        private GameObject serverAreaRow;
        private GameObject serverRow;

        public LoginPresenter(CocosUiView background, CocosUiView login, CocosUiView serverList, CocosUiView roleCreate)
        {
            this.background = background ?? throw new ArgumentNullException(nameof(background));
            this.login = login ?? throw new ArgumentNullException(nameof(login));
            this.serverList = serverList;
            this.roleCreate = roleCreate;
            StartLegacyAnimation(background, "Layer/UI_Login/effect_chuangjue_1", ref backgroundAnimation);
        }

        public int PlayingAnimationCount =>
            (backgroundAnimation != null && backgroundAnimation.IsPlaying ? 1 : 0)
            + (roleBackgroundAnimation != null && roleBackgroundAnimation.IsPlaying ? 1 : 0)
            + (roleAnimation != null && roleAnimation.IsPlaying ? 1 : 0);
        public bool IsRoleCreateVisible => roleCreate?.GameObject != null && roleCreate.GameObject.activeSelf;
        public int SelectedSex => selectedSex;
        public string RoleName => roleNameInput == null ? string.Empty : roleNameInput.text.Trim();
        public string LoginSignature => signatureInput == null ? "local" : signatureInput.text.Trim();
        public bool IsHandoverVisible => FindLogin("Btn_Login")?.activeInHierarchy == true;
        public bool IsServerListVisible => serverList?.GameObject != null && serverList.GameObject.activeSelf;

        public void ShowLocalServer(string serverName)
        {
            background.SetVisible(true);
            SetText(background, "Layer/UI_Login/Versions", "102600");
            login.SetVisible(true);
            serverList?.SetVisible(false);
            roleCreate?.SetVisible(false);
            SetActive("InputField_user", false);
            SetActive("InputField_ps", false);
            SetActive("Btn_Register", false);
            SetActive("Btn_Login", false);
            SetActive("Btn_Login_sdk", false);
            SetActive("Btn_Login_qq", false);
            SetActive("Btn_Login_wx", false);
            SetActive("bg", false);
            SetActive("Btn_Sever", true);
            SetActive("Btn_Play", true);
            SetActive("Btn_handover", true);
            Text label = FindLogin("Btn_Sever/SeverName")?.GetComponent<Text>();
            if (label != null) label.text = string.IsNullOrWhiteSpace(serverName) ? "本地测试服" : serverName;
        }

        public void BindLoginControls(Action enter, Action<uint, string> accountSubmit, Action<string> showError)
        {
            enterAction = enter ?? throw new ArgumentNullException(nameof(enter));
            validationError = showError ?? throw new ArgumentNullException(nameof(showError));
            login.BindClick(Root + "/Btn_Play", enterAction, true);
            login.BindClick(Root + "/Btn_handover", ShowHandover, true);
            login.BindClick(Root + "/Btn_Login", () =>
            {
                accountInput = ConfigureInputField(login, Root + "/InputField_user/TextField", false);
                signatureInput = ConfigureInputField(login, Root + "/InputField_ps/TextField_Copy", true);
                if (accountInput == null || !uint.TryParse(accountInput.text.Trim(), out uint userId) || userId == 0)
                {
                    validationError("请输入有效账号");
                    return;
                }
                string signature = string.IsNullOrWhiteSpace(LoginSignature) ? "local" : LoginSignature;
                accountSubmit(userId, signature);
            }, true);
        }

        public void ShowHandover()
        {
            SetActive("Btn_Sever", false);
            SetActive("Btn_Play", false);
            SetActive("Btn_handover", false);
            SetActive("bg", true);
            SetActive("InputField_user", true);
            SetActive("InputField_ps", true);
            SetActive("Btn_Login", true);
            accountInput = ConfigureInputField(login, Root + "/InputField_user/TextField", false);
            signatureInput = ConfigureInputField(login, Root + "/InputField_ps/TextField_Copy", true);
            if (accountInput != null && string.IsNullOrWhiteSpace(accountInput.text)) accountInput.text = "7200057";
            if (signatureInput != null && string.IsNullOrWhiteSpace(signatureInput.text)) signatureInput.text = "local";
        }

        public void SetAccountCredentials(uint userId, string signature)
        {
            if (!IsHandoverVisible) ShowHandover();
            accountInput = accountInput ?? ConfigureInputField(login, Root + "/InputField_user/TextField", false);
            signatureInput = signatureInput ?? ConfigureInputField(login, Root + "/InputField_ps/TextField_Copy", true);
            if (accountInput != null) accountInput.text = userId.ToString();
            if (signatureInput != null) signatureInput.text = string.IsNullOrWhiteSpace(signature) ? "local" : signature;
        }

        public void ShowServerList(Action enterSelectedServer, Action back)
        {
            if (serverList == null) return;
            login.SetVisible(false);
            serverList.SetVisible(true);
            serverSelected = true;
            EnsureServerRows();
            SetNamedText(serverAreaRow.transform, "Text", "推荐服");
            SetNamedText(serverRow.transform, "SeverName", "本地测试服");
            SetNamedText(serverRow.transform, "Name", "");
            SetServerSelected(true);
            BindSelectable(serverAreaRow, () => SetServerSelected(true));
            BindSelectable(serverRow, () => SetServerSelected(true));
            serverList.BindClick("Layer/SeverList/Btn_Play", () =>
            {
                if (!serverSelected) { validationError?.Invoke("请选择服务器"); return; }
                ShowLocalServer("本地测试服");
                enterSelectedServer?.Invoke();
            }, true);
            serverList.BindClick("Layer/SeverList/Panel_1/btn_Exit", () =>
            {
                ShowLocalServer("本地测试服");
                back?.Invoke();
            }, true);
        }

        public void ShowRoleCreate(Action createRole, Action randomRoleName, Action back, Action<string> showError,
            bool autoInvoke)
        {
            login.SetVisible(false);
            serverList?.SetVisible(false);
            if (roleCreate == null) throw new InvalidOperationException("Login/RoleCreateLayer was not imported.");
            roleCreate.SetVisible(true);
            StartLegacyAnimation(roleCreate, "Layer/RoleCreateUI/effect_chuangjue_1", ref roleBackgroundAnimation);
            roleCreateAction = createRole ?? throw new ArgumentNullException(nameof(createRole));
            roleRandomAction = randomRoleName ?? throw new ArgumentNullException(nameof(randomRoleName));
            roleBackAction = back ?? throw new ArgumentNullException(nameof(back));
            validationError = showError ?? throw new ArgumentNullException(nameof(showError));
            roleNameInput = ConfigureInputField(roleCreate, "Layer/RoleCreateUI/Role_Layout/TextField", false);
            ShowRole(1);
            BindSex("Layer/RoleCreateUI/man", 1);
            BindSex("Layer/RoleCreateUI/woman", 2);
            roleCreate.BindClick("Layer/RoleCreateUI/Image/btn_Exit", () => roleBackAction(), true);
            roleCreate.BindClick("Layer/RoleCreateUI/Role_Layout/btn_Random", () =>
            {
                if (randomNames.Count > 0) CycleRandomName();
                else roleRandomAction();
            }, true);
            Button button = roleCreate.BindClick("Layer/RoleCreateUI/btn_Start", () =>
            {
                string value = RoleName;
                if (string.IsNullOrEmpty(value)) { validationError("请输入角色名"); return; }
                if (value.Length > 6) { validationError("所填写账号超过6位"); return; }
                roleCreateAction();
            }, true);
            if (autoInvoke) button.onClick.Invoke();
        }

        public void ApplyRandomNames(IReadOnlyList<string> values)
        {
            randomNames.Clear();
            if (values != null)
                foreach (string value in values)
                    if (!string.IsNullOrWhiteSpace(value)) randomNames.Add(value.Trim());
            randomNameIndex = 0;
            if (randomNames.Count > 0) SetRoleName(randomNames[0]);
        }

        public void CycleRandomName()
        {
            if (randomNames.Count == 0) { roleRandomAction?.Invoke(); return; }
            randomNameIndex = (randomNameIndex + 1) % randomNames.Count;
            SetRoleName(randomNames[randomNameIndex]);
        }

        public void SetRoleName(string value)
        {
            roleNameInput = roleNameInput ?? ConfigureInputField(roleCreate, "Layer/RoleCreateUI/Role_Layout/TextField", false);
            if (roleNameInput != null) roleNameInput.text = value ?? string.Empty;
        }

        public bool ValidateRoleAnimations(out string detail)
        {
            if (!IsRoleCreateVisible) { detail = "RoleCreateLayer is not visible"; return false; }
            ShowRole(1);
            if (roleAnimation == null || !roleAnimation.IsPlaying)
            { detail = "male Create_5 action 0 is not playing"; return false; }
            ShowRole(2);
            if (roleAnimation == null || !roleAnimation.IsPlaying)
            { detail = "female Create_4 action 0 is not playing"; return false; }
            ShowRole(1);
            detail = "Create_5/Create_4 action 0 loop playback passed";
            return true;
        }

        public void InvokeRoleCreate()
        {
            Button button = roleCreate?.Binding.Find("Layer/RoleCreateUI/btn_Start")?.GetComponent<Button>();
            if (button == null) throw new InvalidOperationException("RoleCreateLayer btn_Start was not bound.");
            button.onClick.Invoke();
        }

        public bool InvokeHandover() => InvokeButton(login, Root + "/Btn_handover");
        public bool InvokeAccountSubmit() => InvokeButton(login, Root + "/Btn_Login");
        public bool InvokeServerSelector() => InvokeButton(login, Root + "/Btn_Sever");
        public bool InvokeServerArea() => InvokeSelectable(serverAreaRow);
        public bool InvokeServerRow() => InvokeSelectable(serverRow);
        public bool InvokeServerPlay() => InvokeButton(serverList, "Layer/SeverList/Btn_Play");
        public bool InvokeServerBack() => InvokeButton(serverList, "Layer/SeverList/Panel_1/btn_Exit");
        public bool InvokeRoleBack() => InvokeButton(roleCreate, "Layer/RoleCreateUI/Image/btn_Exit");
        public bool InvokeRoleRandom() => InvokeButton(roleCreate, "Layer/RoleCreateUI/Role_Layout/btn_Random");
        public bool InvokeRoleMale() => InvokeToggleOrButton("Layer/RoleCreateUI/man", true);
        public bool InvokeRoleFemale() => InvokeToggleOrButton("Layer/RoleCreateUI/woman", true);

        public void HideAll()
        {
            login.SetVisible(false);
            background.SetVisible(false);
            serverList?.SetVisible(false);
            roleCreate?.SetVisible(false);
        }

        public void Dispose()
        {
            if (backgroundAnimation != null) UnityEngine.Object.Destroy(backgroundAnimation.gameObject);
            if (roleBackgroundAnimation != null) UnityEngine.Object.Destroy(roleBackgroundAnimation.gameObject);
            if (roleAnimation != null) UnityEngine.Object.Destroy(roleAnimation.gameObject);
            if (serverAreaRow != null) UnityEngine.Object.Destroy(serverAreaRow);
            if (serverRow != null) UnityEngine.Object.Destroy(serverRow);
        }

        private GameObject FindLogin(string relativePath) => login.Binding.Find(Root + "/" + relativePath);
        private void SetActive(string relativePath, bool active)
        {
            GameObject node = FindLogin(relativePath);
            if (node != null) node.SetActive(active);
        }

        private static void SetText(CocosUiView view, string path, string value)
        {
            Text text = view?.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static InputField ConfigureInputField(CocosUiView view, string path, bool password)
        {
            GameObject node = view?.Binding.Find(path);
            if (node == null) return null;
            InputField input = node.GetComponent<InputField>() ?? node.AddComponent<InputField>();
            Text text = node.GetComponent<Text>() ?? node.GetComponentInChildren<Text>(true);
            if (text == null)
            {
                var textNode = new GameObject("RuntimeText", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                RectTransform rect = textNode.GetComponent<RectTransform>();
                rect.SetParent(node.transform, false);
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                text = textNode.GetComponent<Text>();
                text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                text.fontSize = 24;
                text.color = new Color32(93, 55, 48, 255);
                text.alignment = TextAnchor.MiddleLeft;
            }
            input.textComponent = text;
            input.contentType = password ? InputField.ContentType.Password : InputField.ContentType.Standard;
            input.lineType = InputField.LineType.SingleLine;
            return input;
        }

        private void SetServerSelected(bool selected)
        {
            serverSelected = selected;
            GameObject chosen = serverRow == null ? null : FindNamed(serverRow.transform, "Choose")?.gameObject;
            if (chosen != null) chosen.SetActive(selected);
        }

        private static bool InvokeButton(CocosUiView view, string path)
        {
            Button button = view?.Binding.Find(path)?.GetComponent<Button>();
            if (button == null || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        private bool InvokeToggleOrButton(string path, bool selected)
        {
            GameObject node = roleCreate?.Binding.Find(path);
            Toggle toggle = node?.GetComponent<Toggle>();
            if (toggle != null && toggle.interactable)
            {
                toggle.isOn = selected;
                return true;
            }
            Button button = node?.GetComponent<Button>();
            if (button == null || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        private void EnsureServerRows()
        {
            GameObject areaTemplate = serverList?.Binding.Find("Layer/SeverList/Item_1");
            GameObject serverTemplate = serverList?.Binding.Find("Layer/SeverList/Item_2");
            Transform areaContent = serverList?.Binding.Find("Layer/SeverList/Panel_1/ListView_1")?.transform;
            Transform serverContent = serverList?.Binding.Find("Layer/SeverList/Panel_1/ListView_2")?.transform;
            if (areaTemplate == null || serverTemplate == null || areaContent == null || serverContent == null)
                throw new InvalidOperationException("SeverListLayer templates or list views were not imported.");
            areaTemplate.SetActive(false);
            serverTemplate.SetActive(false);
            if (serverAreaRow == null)
            {
                serverAreaRow = UnityEngine.Object.Instantiate(areaTemplate, areaContent, false);
                serverAreaRow.name = "RuntimeAreaRow";
                serverAreaRow.SetActive(true);
                ConfigureRuntimeRow(serverAreaRow, 210f, 68f);
            }
            if (serverRow == null)
            {
                serverRow = UnityEngine.Object.Instantiate(serverTemplate, serverContent, false);
                serverRow.name = "RuntimeServerRow";
                serverRow.SetActive(true);
                ConfigureRuntimeRow(serverRow, 640f, 130f);
            }
        }

        private static void ConfigureRuntimeRow(GameObject row, float width, float height)
        {
            RectTransform rect = row.GetComponent<RectTransform>();
            if (rect != null)
            {
                rect.anchorMin = new Vector2(0f, 1f);
                rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(0f, 1f);
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = new Vector2(width, height);
            }
            Toggle toggle = row.GetComponent<Toggle>();
            if (toggle != null) toggle.interactable = true;
            Button button = row.GetComponent<Button>();
            if (button != null) button.interactable = true;
        }

        private static void BindSelectable(GameObject node, Action callback)
        {
            if (node == null) throw new InvalidOperationException("Selectable row is missing.");
            Toggle toggle = node.GetComponent<Toggle>();
            if (toggle != null)
            {
                toggle.onValueChanged.RemoveAllListeners();
                toggle.onValueChanged.AddListener(selected => { if (selected) callback(); });
                return;
            }
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
        }

        private static bool InvokeSelectable(GameObject node)
        {
            Toggle toggle = node?.GetComponent<Toggle>();
            if (toggle != null && toggle.interactable)
            {
                toggle.isOn = false;
                toggle.isOn = true;
                return true;
            }
            Button button = node?.GetComponent<Button>();
            if (button == null || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        private static Transform FindNamed(Transform root, string name)
        {
            if (root == null) return null;
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) return child;
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            Text text = FindNamed(root, name)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void StartLegacyAnimation(CocosUiView view, string path, ref ImodAnimationPlayer player)
        {
            if (player != null) return;
            Transform host = view?.Binding.Find(path)?.transform;
            if (host == null) return;
            var node = new GameObject("RuntimeImod_effect_chuangjue_1", typeof(RectTransform));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(512f, 512f);
            player = node.AddComponent<ImodAnimationPlayer>();
            if (!player.LoadLegacy("res2/animation/effect_chuangjue_1"))
            {
                UnityEngine.Object.Destroy(node);
                player = null;
                return;
            }
            player.PlayActionRepeat(0);
        }

        private void BindSex(string path, int sex)
        {
            GameObject node = roleCreate?.Binding.Find(path);
            if (node == null) return;
            Toggle toggle = node.GetComponent<Toggle>();
            if (toggle != null)
            {
                toggle.onValueChanged.RemoveAllListeners();
                toggle.onValueChanged.AddListener(selected => { if (selected) ShowRole(sex); });
                return;
            }
            Button button = node.GetComponent<Button>();
            if (button == null) button = node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => ShowRole(sex));
        }

        private void ShowRole(int sex)
        {
            selectedSex = sex == 2 ? 2 : 1;
            Toggle man = roleCreate?.Binding.Find("Layer/RoleCreateUI/man")?.GetComponent<Toggle>();
            Toggle woman = roleCreate?.Binding.Find("Layer/RoleCreateUI/woman")?.GetComponent<Toggle>();
            if (man != null) man.SetIsOnWithoutNotify(selectedSex == 1);
            if (woman != null) woman.SetIsOnWithoutNotify(selectedSex == 2);
            if (roleAnimation != null)
            {
                UnityEngine.Object.Destroy(roleAnimation.gameObject);
                roleAnimation = null;
            }
            Transform host = roleCreate?.Binding.Find("Layer/RoleCreateUI/Role")?.transform;
            if (host == null) return;
            var node = new GameObject(selectedSex == 1 ? "RuntimeImod_Create_5" : "RuntimeImod_Create_4", typeof(RectTransform));
            RectTransform rect = node.GetComponent<RectTransform>();
            rect.SetParent(host, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(640f, 720f);
            roleAnimation = node.AddComponent<ImodAnimationPlayer>();
            string resource = selectedSex == 1 ? "res2/create/Create_5" : "res2/create/Create_4";
            if (!roleAnimation.LoadLegacy(resource))
            {
                UnityEngine.Object.Destroy(node);
                roleAnimation = null;
                return;
            }
            roleAnimation.PlayNewAction(0, true);
        }
    }
}
