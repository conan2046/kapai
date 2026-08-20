using System;
using System.Collections;
using System.IO;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using XLua;

namespace ProjectX.LuaRuntime
{
    [LuaCallCSharp]
    public sealed class FirstPlayableLoopBridge : MonoBehaviour
    {
        public const string BagPath = "Layer/Main_UI/ButtonGroup1/btn_Bag";
        public const string LoginButtonPath = "Layer/Login/Btn_Login";

        private NetworkService network;
        private ProtocolDispatcher protocols;
        private LuaRuntimeService lua;
        private UiRouter uiRouter;
        private LuaFunction onConnected;
        private LuaFunction onPacket;
        private LuaFunction onLoginClicked;
        private LuaFunction onBagClicked;
        private CocosUiView loginBackgroundView;
        private CocosUiView loginView;
        private CocosUiView mainView;
        private string status = "Starting reusable C# + Lua runtime...";
        private bool completed;

        public static FirstPlayableLoopBridge Instance { get; private set; }
        public static bool LastRunCompleted { get; private set; }
        public static bool LastRunFailed { get; private set; }
        public static string LastRunStatus { get; private set; }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
        {
            if (!SceneManager.GetActiveScene().path.EndsWith("/FirstPlayableLoop.unity", StringComparison.OrdinalIgnoreCase)
                || Instance != null)
                return;
            GameObject host = new GameObject("ProjectX_FirstPlayableLoop");
            DontDestroyOnLoad(host);
            host.AddComponent<FirstPlayableLoopBridge>();
        }

        private void Awake()
        {
            Instance = this;
            LastRunCompleted = false;
            LastRunFailed = false;
            LastRunStatus = status;
            uiRouter = new UiRouter();
            protocols = new ProtocolDispatcher(ProtocolRegistry.CreateDefault());
            network = new NetworkService();
            network.PacketReceived += protocols.Dispatch;
            network.Disconnected += reason => Fail($"Disconnected: {reason}");
            foreach (ushort command in new ushort[] { 8, 1001, 1003, 1004 })
            {
                ushort registeredCommand = command;
                protocols.Register(command, message => DispatchToLua(registeredCommand, message));
            }
            protocols.UnhandledPacket += DispatchToLua;
            InitializeLua();
        }

        private void Update()
        {
            network?.Tick();
            lua?.Tick();
        }

        private void OnDestroy()
        {
            onConnected?.Dispose();
            onPacket?.Dispose();
            onLoginClicked?.Dispose();
            onBagClicked?.Dispose();
            network?.Dispose();
            lua?.Dispose();
            if (Instance == this) Instance = null;
        }

        private void OnGUI()
        {
            GUI.depth = -1000;
            Color previous = GUI.color;
            GUI.color = completed ? new Color(0.65f, 1f, 0.65f) : Color.white;
            GUI.Box(new Rect(12f, 12f, 700f, 54f), $"ProjectX reusable C# + Lua runtime\n{status}");
            GUI.color = previous;
        }

        public async void Connect(string host, int port)
        {
            try
            {
                SetStatus($"Connecting to {host}:{port}...");
                await network.ConnectAsync(host, port);
                SetStatus("Connected. Lua is sending PRO_USER_LOGIN/1001...");
                onConnected?.Call();
            }
            catch (Exception exception) { Fail($"Connect failed: {exception.Message}"); }
        }

        public void Send(LegacyTcpMessage message)
        {
            try { network.Send(message); }
            catch (Exception exception) { Fail($"Send failed: {exception.Message}"); }
        }

        public bool IsAutomation() => true;

        public void ShowLoginUi()
        {
            loginView = uiRouter.FindBySource("Login/loginLayer");
            loginBackgroundView = uiRouter.FindBySource("Login/LoginBgLayer");
            mainView = uiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            loginBackgroundView?.SetVisible(true);
            loginView?.SetVisible(true);
            mainView?.SetVisible(false);
            if (loginView == null) { Fail("Login/loginLayer CocosUiBinding was not found."); return; }
            SetStatus("Login UI is active. Waiting for the enter-game button.");
        }

        public void BindLoginClick(bool autoInvoke)
        {
            try
            {
                Button button = loginView.BindClick(LoginButtonPath, HandleLoginClick);
                SetStatus("Login UI ready. Btn_Login click is bound to LoginController.");
                ScreenCapture.CaptureScreenshot(GetArtifactPath("first-playable-loop-login.png"));
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowMainUi()
        {
            mainView = uiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            if (mainView == null) { Fail("UImainLayer CocosUiBinding was not found."); return; }
            mainView.SetVisible(true);
            loginView?.SetVisible(false);
            loginBackgroundView?.SetVisible(false);
            SetStatus("PRO_SELECT_ROLE/1004 succeeded. UImainLayer is active.");
        }

        public void BindBagClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? uiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(BagPath, HandleBagClick, true);
                SetStatus("Main UI ready. Bag click is bound to BagController.");
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void SetStatus(string value)
        {
            status = value ?? string.Empty;
            LastRunStatus = status;
            Debug.Log($"[FirstPlayableLoop] {status}");
        }

        public void Complete(string value)
        {
            completed = true;
            LastRunCompleted = true;
            LastRunFailed = false;
            SetStatus(value);
            ScreenCapture.CaptureScreenshot(GetArtifactPath("first-playable-loop-main.png"));
            WriteResult(true, value);
            Debug.Log("[FirstPlayableLoop] COMPLETE");
        }

        public void Fail(string value)
        {
            if (completed) return;
            completed = false;
            LastRunCompleted = false;
            LastRunFailed = true;
            SetStatus(value);
            WriteResult(false, value);
            Debug.LogError($"[FirstPlayableLoop] FAILED: {value}");
        }

        private void InitializeLua()
        {
            try
            {
                lua = new LuaRuntimeService(this);
                lua.ExecuteResource("Lua/Bootstrap", "Bootstrap.lua");
                onConnected = lua.GetFunction("OnConnected");
                onPacket = lua.GetFunction("OnPacket");
                onLoginClicked = lua.GetFunction("OnLoginClicked");
                onBagClicked = lua.GetFunction("OnBagClicked");
                using (LuaFunction begin = lua.GetFunction("Begin")) begin?.Call();
            }
            catch (Exception exception) { Fail($"Lua bootstrap failed: {exception.Message}"); }
        }

        private void DispatchToLua(ushort command, LegacyTcpMessage message)
        {
            if (command == 0) { if (!completed) Fail("TCP receive loop stopped unexpectedly."); return; }
            try { onPacket?.Call((int)command, message); }
            catch (Exception exception) { Fail($"Lua packet handler failed for command {command}: {exception.Message}"); }
        }

        private void HandleBagClick() { SetStatus("Unity Button.onClick entered BagController; requesting PRO_ROLE_PACKAGE/8..."); onBagClicked?.Call(); }
        private void HandleLoginClick() { SetStatus("Unity Btn_Login.onClick entered LoginController; connecting to the local game server..."); onLoginClicked?.Call(); }
        private static IEnumerator InvokeButtonNextFrame(Button button) { yield return null; button.onClick.Invoke(); }

        private static string GetArtifactPath(string fileName)
        {
            string repositoryRoot = Directory.GetParent(Directory.GetParent(Application.dataPath).FullName).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            return Path.Combine(directory, fileName);
        }

        private static void WriteResult(bool success, string value)
        {
            string escaped = (value ?? string.Empty).Replace("\\", "\\\\").Replace("\"", "\\\"");
            File.WriteAllText(GetArtifactPath("first-playable-loop-result.json"),
                "{\n" + $"  \"success\": {(success ? "true" : "false")},\n"
                + $"  \"status\": \"{escaped}\",\n" + $"  \"utc\": \"{DateTime.UtcNow:O}\"\n" + "}\n");
        }
    }
}
