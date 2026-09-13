using System;
using System.Collections;
using System.IO;
using ProjectX.Data;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public const string JingJiePath = "Layer/Main_UI/ButtonGroup1/btn_jingjie";
        public const string JingJieHeadPath = "Layer/Main_UI/Head";
        private LuaFunction onJingJieClicked;
        private LuaFunction onJingJieUpgrade;
        private CocosUiView jingJieFrameView;
        private CocosUiView jingJieView;
        private CocosUiView jingJiePreviewView;
        private JingJieRenderBridge jingJieRenderBridge;
        private JingJieConfigData jingJieConfig;
        private bool jingJieEntrySubscribed;
        private bool jingJieValidationRunning;

        public bool IsJingJieOpen => jingJieView?.GameObject.activeInHierarchy == true;
        public bool IsJingJiePreviewOpen => jingJieRenderBridge?.IsPreviewVisible == true;
        public int JingJieCurrentId => services?.JingJie.CurrentId ?? 0;

        public void BeginJingJieValidation()
        {
            if (jingJieValidationRunning) return;
            jingJieValidationRunning = true;
            StartCoroutine(RunJingJieValidation());
        }

        private IEnumerator RunJingJieValidation()
        {
            BeginValidationEvidence();
            try
            {
                float deadline = Time.realtimeSinceStartup + 20f;
                while ((!services.JingJie.HasAuthoritativeState || services.ProtocolRegistry.PendingCount != 0)
                       && Time.realtimeSinceStartup < deadline)
                    yield return null;
                long goldBefore = services.Currencies.Gold;
                if (!services.JingJie.HasAuthoritativeState || services.JingJie.CurrentId != 0
                    || goldBefore != 100000 || services.Player.Power < 50000)
                {
                    Fail($"JingJie fixture mismatch: authority={services.JingJie.HasAuthoritativeState}, current={services.JingJie.CurrentId}, gold={goldBefore}, power={services.Player.Power}.");
                    yield break;
                }

                Button entry = mainView?.Binding.Find(JingJiePath)?.GetComponent<Button>();
                if (!InvokeEventSystemRaycastClick(entry))
                {
                    Fail("JingJie HUD entry did not accept a real EventSystem/raycast click.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-01-ENTRY");
                yield return WaitForJingJieState(() => IsJingJieOpen, "entry");
                if (CurrentAppState == AppState.Failed) yield break;
                if (!ValidateJingJieCurrencyHeader(out string currencyDetail))
                {
                    Fail("JingJie GoldCheck authority mismatch: " + currencyDetail);
                    yield break;
                }
                RecordValidationSemantic("jingjie-authoritative-goldcheck", true, currencyDetail);
                yield return CaptureJingJieFrame("jingjie-main.png");

                Button frameClose = jingJieFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
                if (!InvokeEventSystemRaycastClick(frameClose) || IsJingJieOpen)
                {
                    Fail("JingJie frame close did not return to HUD through EventSystem.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-02-CLOSE");
                // UiStack reactivates Main_UI in the close-click frame. Allow the
                // GraphicRegistry one frame to re-register Head before auditing a
                // second real EventSystem/raycast entry.
                yield return null;
                Canvas.ForceUpdateCanvases();

                Button headEntry = mainView?.Binding.Find(JingJieHeadPath)?.GetComponent<Button>();
                if (!InvokeEventSystemRaycastClick(headEntry))
                {
                    Fail("JingJie HUD Head entry did not accept a real EventSystem/raycast click.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-07-HEAD-ENTRY");
                yield return WaitForJingJieState(() => IsJingJieOpen, "Head entry");
                if (CurrentAppState == AppState.Failed) yield break;

                if (!InvokeEventSystemRaycastClick(jingJieRenderBridge.PreviewControl))
                {
                    Fail("JingJie preview control did not accept a real EventSystem/raycast click.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-03-PREVIEW");
                yield return WaitForJingJieState(() => IsJingJiePreviewOpen, "preview open");
                if (CurrentAppState == AppState.Failed) yield break;
                if (jingJieRenderBridge.PreviewRowCount != 20)
                {
                    Fail($"JingJie preview row count mismatch: {jingJieRenderBridge.PreviewRowCount}/20.");
                    yield break;
                }
                yield return CaptureJingJieFrame("jingjie-preview.png");
                if (!InvokeEventSystemRaycastClick(jingJieRenderBridge.PreviewCloseControl) || IsJingJiePreviewOpen)
                {
                    Fail("JingJie preview close did not return to the main page through EventSystem.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-04-PREVIEW-CLOSE");

                if (!InvokeEventSystemRaycastClick(jingJieRenderBridge.UpgradeControl))
                {
                    Fail("JingJie breakthrough did not accept a real EventSystem/raycast click.");
                    yield break;
                }
                MarkValidationControl("JINGJIE-06-UPGRADE");
                deadline = Time.realtimeSinceStartup + 15f;
                while ((services.JingJie.CurrentId != 1 || services.JingJie.UpgradePending
                        || services.Currencies.Gold != 90000 || services.ProtocolRegistry.PendingCount != 0)
                       && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (services.JingJie.CurrentId != 1 || services.JingJie.UpgradePending
                    || services.Currencies.Gold != 90000
                    || services.ProtocolRegistry.PendingCount != 0 || !jingJieRenderBridge.IsUpgradeEffectVisible)
                {
                    Fail($"JingJie breakthrough mismatch: current={services.JingJie.CurrentId}, pending={services.JingJie.UpgradePending}, gold={services.Currencies.Gold}, protocol={services.ProtocolRegistry.PendingCount}, effect={jingJieRenderBridge.IsUpgradeEffectVisible}.");
                    yield break;
                }
                yield return CaptureJingJieFrame("jingjie-upgrade-success.png");

                RecordValidationSemantic("jingjie-config-20-rows", true, "20 formal rows rendered from jingjie.json");
                RecordValidationSemantic("jingjie-authoritative-upgrade", true, "real /306 op=4 advanced 0->1 only after server op=1 authority");
                RecordValidationSemantic("jingjie-cost-deduction", true, "gold 100000->90000; no unavailable item dependency");
                RecordValidationSemantic("jingjie-upgrade-effect", true, "effect_jingjietupo_1 action0 visible after authority");

                deadline = Time.realtimeSinceStartup + 5f;
                while (jingJieRenderBridge.IsUpgradeEffectVisible && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (jingJieRenderBridge.IsUpgradeEffectVisible)
                {
                    Fail("JingJie breakthrough effect did not finish its three-second lifetime.");
                    yield break;
                }

                if (!InvokeEventSystemRaycastClick(frameClose) || IsJingJieOpen)
                {
                    Fail("JingJie frame close did not return to HUD through EventSystem.");
                    yield break;
                }

                uint roleId = GetPlayerRoleId();
                services.Network.Disconnect("JingJie deliberate reconnect validation");
                yield return new WaitForSecondsRealtime(.25f);
                Reconnect();
                deadline = Time.realtimeSinceStartup + 25f;
                while ((CurrentAppState != AppState.Main || services.Network.State != ProjectX.Network.NetworkState.Connected
                        || !services.JingJie.HasAuthoritativeState || services.JingJie.CurrentId != 1
                        || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                    yield return null;
                if (CurrentAppState != AppState.Main || GetPlayerRoleId() != roleId
                    || !services.JingJie.HasAuthoritativeState || services.JingJie.CurrentId != 1)
                {
                    Fail($"JingJie reconnect mismatch: state={CurrentAppState}, role={GetPlayerRoleId()}/{roleId}, authority={services.JingJie.HasAuthoritativeState}, current={services.JingJie.CurrentId}.");
                    yield break;
                }
                entry = mainView?.Binding.Find(JingJiePath)?.GetComponent<Button>();
                if (!InvokeEventSystemRaycastClick(entry))
                {
                    Fail("JingJie reconnect entry did not accept a real EventSystem/raycast click.");
                    yield break;
                }
                yield return WaitForJingJieState(() => IsJingJieOpen, "reconnect entry");
                if (CurrentAppState == AppState.Failed) yield break;
                yield return CaptureJingJieFrame("jingjie-reconnect.png");
                RecordValidationSemantic("jingjie-reconnect-authority", true, "reconnect restored role and current=1 from /306 op=1");
                Complete($"COMPLETE: JingJie 6/6 controls; /306 op=1/op=4; current=1; gold=90000; role={roleId}");
            }
            finally
            {
                jingJieValidationRunning = false;
            }
        }

        private IEnumerator WaitForJingJieState(Func<bool> predicate, string label)
        {
            float deadline = Time.realtimeSinceStartup + 10f;
            while (!predicate() && Time.realtimeSinceStartup < deadline) yield return null;
            if (!predicate()) Fail("JingJie timed out waiting for " + label + ".");
        }

        private IEnumerator CaptureJingJieFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string repositoryRoot = Directory.GetParent(Directory.GetParent(Application.dataPath).FullName).FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            string path = Path.Combine(directory, fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            long previousLength = -1;
            int stableFrames = 0;
            while (Time.realtimeSinceStartup < deadline)
            {
                long length = File.Exists(path) ? new FileInfo(path).Length : 0;
                if (length >= 4096 && length == previousLength)
                {
                    if (++stableFrames >= 2)
                    {
                        WriteJingJieResourceMap(path);
                        yield break;
                    }
                }
                else
                {
                    previousLength = length;
                    stableFrames = 0;
                }
                yield return null;
            }
            throw new IOException("JingJie screenshot was not written or stable: " + path);
        }

        private static void WriteJingJieResourceMap(string screenshotPath)
        {
            string mapPath = Path.Combine(Path.GetDirectoryName(screenshotPath),
                Path.GetFileNameWithoutExtension(screenshotPath) + "-ui-resource-map.md");
            string content = string.Join("\n", new[]
            {
                "# JingJie UI resource map", "",
                $"- Screenshot: `{Path.GetFileName(screenshotPath)}`",
                "- Cocos Lua: `client/ProjectX/src/View/JingJie/jingjieUI.lua`, `JingJiePreViewUI.lua`",
                "- Cocos CSB: `client/ProjectX/res/csd/zhujue/JingjieLayer.csb`, `Jingjieyulan.csb`",
                "- Unity Prefab: `unityclient/Assets/ProjectX/res/csd/Prefabs/zhujue/JingjieLayer.prefab`, `Jingjieyulan.prefab`",
                "- Unity runtime: `ProjectXApp.JingJie.cs`, `JingJieRenderBridge.cs`",
                "- Protocol: `/306 op=1/4`",
                "- Formal table: `concept/data/excel/xml配置表/新表/jingjie_config.xlsx`",
                "- Cost policy: unavailable item 861-865 is removed; current config consumes gold only.",
                "- Known unresolved assets: formal icons `ui_jingjie_icon_jingjie_05/06` are absent; no placeholder used.", ""
            });
            File.WriteAllText(mapPath, content, new System.Text.UTF8Encoding(false));
        }

        private void HandleJingJieClick()
        {
            if (services.Player.Level < 10)
            {
                ShowToast("10级开启主角境界", 2f);
                return;
            }
            InvokeLuaOrFail(onJingJieClicked, "JingJie.Open");
        }

        private void BindJingJieEntry()
        {
            if (mainView == null) return;
            mainView.BindClick(JingJiePath, HandleJingJieClick, true);
            mainView.BindClick(JingJieHeadPath, HandleJingJieClick, true);
            if (!jingJieEntrySubscribed)
            {
                services.Player.Changed += RefreshJingJieEntry;
                jingJieEntrySubscribed = true;
            }
            RefreshJingJieEntry();
        }

        private void RefreshJingJieEntry()
        {
            GameObject entry = mainView?.Binding.Find(JingJiePath);
            if (entry != null) entry.SetActive(services?.Player.Level >= 10);
        }

        private bool ValidateJingJieCurrencyHeader(out string detail)
        {
            CocosUiBinding binding = jingJieFrameView?.Binding;
            if (binding == null || services == null)
            {
                detail = "shared OneLevelLayer or services are unavailable";
                return false;
            }
            Text stamina = binding.Find("Layer/GoldCheck/GoldIcon1/GoldNumBg/Num")?.GetComponent<Text>();
            Text gold = binding.Find("Layer/GoldCheck/GoldIcon3/GoldNumBg/Num")?.GetComponent<Text>();
            Text premium = binding.Find("Layer/GoldCheck/GoldIcon4/GoldNumBg/Num")?.GetComponent<Text>();
            string expectedStamina = $"{services.Currencies.Stamina}/100";
            string expectedGold = FormatHeaderCurrency(services.Currencies.Gold);
            string expectedPremium = services.Currencies.Premium.ToString();
            bool valid = services.Currencies.Has(CurrencyIds.Stamina)
                && stamina?.text == expectedStamina && gold?.text == expectedGold
                && premium?.text == expectedPremium;
            detail = $"/18 stamina={stamina?.text}/{expectedStamina}; /1004 gold={gold?.text}/{expectedGold}, premium={premium?.text}/{expectedPremium}";
            return valid;
        }

        public void ShowJingJie()
        {
            EnsureJingJieBridge();
            HideOtherOneLevelChildren();
            ConfigureJingJieFrame();
            jingJieFrameView.SetVisible(true);
            jingJieRenderBridge.Show();
            jingJieFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != jingJieFrameView) services.UiStack.Push(jingJieFrameView);
            SetStatus(services.JingJie.HasAuthoritativeState
                ? $"JingJie UI active: current={services.JingJie.CurrentId}."
                : "JingJie UI active: awaiting /306 op=1 authority.");
        }

        public void ApplyJingJieCurrent(int id)
        {
            if (id < 0 || id > (jingJieConfig ?? (jingJieConfig = new JingJieConfigData())).Count)
            {
                Fail($"JingJie /306 op=1 returned invalid id={id}.");
                return;
            }
            services.JingJie.ApplyCurrent(id);
            SetStatus($"JingJie /306 op=1 synchronized: current={id}.");
        }

        public bool BeginJingJieUpgrade()
        {
            EnsureJingJieBridge();
            return jingJieRenderBridge.TryBeginUpgrade();
        }

        public void CompleteJingJieUpgrade(int id, string serverMessage)
        {
            services.JingJie.FinishUpgrade();
            if (jingJieConfig.TryGet(id, out JingJieDefinition definition))
                ShowToast($"恭喜，境界提升至{definition.Name}", 3f);
            else if (!string.IsNullOrWhiteSpace(serverMessage)) ShowToast(serverMessage, 3f);
            SetStatus($"JingJie /306 op=4 completed: id={id}.");
        }

        public void FailJingJieUpgrade(string message)
        {
            services.JingJie.FinishUpgrade();
            ShowToast(string.IsNullOrWhiteSpace(message) ? "境界突破失败" : message, 3f);
            SetStatus("JingJie /306 op=4 rejected by server.");
        }

        public void ClearJingJieState() => services?.JingJie.Clear();

        private void RequestJingJieUpgrade() =>
            InvokeLuaOrFail(onJingJieUpgrade, "JingJie.Upgrade");

        private bool TryHandleJingJieBack()
        {
            if (jingJieRenderBridge?.IsPreviewVisible == true)
            {
                jingJieRenderBridge.HidePreview();
                return true;
            }
            if (!IsJingJieOpen || services?.UiStack.Current != jingJieFrameView) return false;
            jingJieRenderBridge.Hide();
            return PopUiStackWithHudRefresh();
        }

        private void EnsureJingJieBridge()
        {
            if (jingJieRenderBridge != null) return;
            jingJieFrameView = services.UiRouter.FindBySource("OneLevelLayer");
            if (jingJieFrameView == null)
                throw new InvalidOperationException("JingJie shared OneLevelLayer was not found.");
            jingJieView = services.UiRouter.FindBySource("zhujue/JingjieLayer")
                ?? UiPrefabLoader.Load("JingjieLayer", jingJieFrameView.GameObject.transform);
            jingJiePreviewView = services.UiRouter.FindBySource("zhujue/Jingjieyulan")
                ?? UiPrefabLoader.Load("Jingjieyulan", jingJieFrameView.GameObject.transform);
            if (jingJieView == null || jingJiePreviewView == null)
                throw new InvalidOperationException("JingJie imported Prefabs were not found.");
            jingJieConfig = jingJieConfig ?? new JingJieConfigData();
            jingJieRenderBridge = new JingJieRenderBridge(jingJieView, jingJiePreviewView,
                services.JingJie, jingJieConfig, services.Player, services.Currencies, services.Bag,
                services.Resources, RequestJingJieUpgrade, ShowJingJieMaterial, message => ShowToast(message, 2f));
            jingJieFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true);
            jingJiePreviewView.SetVisible(false);
        }

        private void ShowJingJieMaterial(JingJieDefinition definition)
        {
            EnsureBagPresenter();
            RewardRecord item = services.ShopCatalog.DescribeReward(definition.MaterialId,
                definition.MaterialId, checked((uint)services.Bag.GetTotalQuantityByItemId(definition.MaterialId)));
            bagFlowPresenter.ShowMailAttachment(item);
        }

        private void HideOtherOneLevelChildren()
        {
            Transform frame = jingJieFrameView?.GameObject.transform;
            if (frame == null) return;
            foreach (Transform child in frame)
                if (child.name.StartsWith("DynamicUi_", StringComparison.Ordinal)
                    && child.gameObject != jingJieView?.GameObject
                    && child.gameObject != jingJiePreviewView?.GameObject)
                    child.gameObject.SetActive(false);
        }

        private void ConfigureJingJieFrame()
        {
            CocosUiBinding binding = jingJieFrameView.Binding;
            RectTransform root = binding.transform as RectTransform;
            if (root != null)
            {
                root.pivot = new Vector2(0f, 1f);
                root.anchorMin = root.anchorMax = new Vector2(0f, 1f);
                root.anchoredPosition = Vector2.zero;
                root.localScale = Vector3.one;
            }
            Text title = binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            Transform help = title?.transform.Find("Button_1");
            if (help != null) help.gameObject.SetActive(false);
            Transform first = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            if (first != null) SetTabText(first, "境界", true);
            Transform second = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            if (second != null) second.gameObject.SetActive(false);
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private void DisposeJingJie()
        {
            if (jingJieEntrySubscribed && services?.Player != null)
            {
                services.Player.Changed -= RefreshJingJieEntry;
                jingJieEntrySubscribed = false;
            }
            jingJieRenderBridge?.Dispose();
            jingJieRenderBridge = null;
            onJingJieClicked?.Dispose();
            onJingJieClicked = null;
            onJingJieUpgrade?.Dispose();
            onJingJieUpgrade = null;
        }
    }
}
