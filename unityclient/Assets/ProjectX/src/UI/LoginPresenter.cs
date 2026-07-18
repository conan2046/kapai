using System;
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

        public void ShowServerList(Action selectLocalServer)
        {
            if (serverList == null) return;
            login.SetVisible(false);
            serverList.SetVisible(true);
            SetText(serverList, "Layer/SeverList/Item_2/SeverName", "本地测试服");
            SetText(serverList, "Layer/SeverList/Item_2/Name", "");
            serverList.BindClick("Layer/SeverList/Item_2", selectLocalServer, true);
            serverList.BindClick("Layer/SeverList/Btn_Play", selectLocalServer, true);
            serverList.BindClick("Layer/SeverList/Panel_1/btn_Exit", selectLocalServer, true);
        }

        public void ShowRoleCreate(Action createRole, bool autoInvoke)
        {
            login.SetVisible(false);
            serverList?.SetVisible(false);
            if (roleCreate == null) throw new InvalidOperationException("Login/RoleCreateLayer was not imported.");
            roleCreate.SetVisible(true);
            StartLegacyAnimation(roleCreate, "Layer/RoleCreateUI/effect_chuangjue_1", ref roleBackgroundAnimation);
            ShowRole(1);
            BindSex("Layer/RoleCreateUI/man", 1);
            BindSex("Layer/RoleCreateUI/woman", 2);
            Button button = roleCreate.BindClick("Layer/RoleCreateUI/btn_Start", createRole, true);
            if (autoInvoke) button.onClick.Invoke();
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
