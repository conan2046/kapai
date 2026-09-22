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
        public const string JingJiePath = "Layer/Bg/btn_jingjie";
        public const string JingJieHeadPath = "Layer/Main_UI/Head";
        private LuaFunction onJingJieClicked;
        private LuaFunction onJingJieUpgrade;
        private CocosUiView jingJieView;
        private CocosUiView jingJiePreviewView;
        private JingJieRenderBridge jingJieRenderBridge;
        private JingJieConfigData jingJieConfig;
        private bool jingJieEntrySubscribed;
        private bool jingJieValidationRunning;
        private enum JingJieSurfaceMode { JingJie, Bag, Mail, Settings }
        private JingJieSurfaceMode jingJieSurfaceMode = JingJieSurfaceMode.JingJie;
        private bool jingJieBagDataRequested;

        // The Jingjie PAGE is open when either of its two surfaces is on screen:
        // the 境界 content itself, or the embedded 背包 tab (which hides
        // jingJieView). Testing only jingJieView reports "closed" while the bag
        // tab is showing, which silently disables IsJingJieBagSurfaceActive and
        // lets the ordinary bag path hijack the shared frame.
        public bool IsJingJieOpen =>
            jingJieView?.GameObject.activeInHierarchy == true
            || (oneLevelFrameView != null && services?.UiStack.Current == oneLevelFrameView
                && ((jingJieSurfaceMode == JingJieSurfaceMode.Bag && bagView?.GameObject.activeInHierarchy == true)
                    || (jingJieSurfaceMode == JingJieSurfaceMode.Settings && settingsView?.GameObject.activeInHierarchy == true)
                    || (jingJieSurfaceMode == JingJieSurfaceMode.Mail && mailView?.GameObject.activeInHierarchy == true)));
        public bool IsJingJiePreviewOpen => jingJieRenderBridge?.IsPreviewVisible == true;
        // True while the Jingjie page is showing its embedded 背包 tab. EndBagUpdate
        // consults this so the /8 response refreshes the store without navigating
        // the shared frame back to the ordinary bag surface.
        public bool IsJingJieBagSurfaceActive =>
            IsJingJieOpen && jingJieSurfaceMode == JingJieSurfaceMode.Bag;
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

                Button frameClose = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/CloseBtn")?.GetComponent<Button>();
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
            FunctionUnlockDefinition unlock = FunctionUnlockCatalog.Resolve(22);
            if (services.Player.Level < unlock.OpenLevel)
            {
                ShowToast($"{unlock.OpenLevel}级开启主角境界", 2f);
                return;
            }
            InvokeLuaOrFail(onJingJieClicked, "JingJie.Open");
        }

        private void BindJingJieEntry()
        {
            if (mainView == null) return;
            GameObject entry = FindMainHudNode(JingJiePath);
            if (entry != null)
                mainView.BindClickNode(entry, HandleJingJieClick, true, JingJiePath);
            GameObject head = FindMainHudNode(JingJieHeadPath);
            if (head != null)
                mainView.BindClickNode(head, HandleJingJieClick, true, JingJieHeadPath);
            if (!jingJieEntrySubscribed)
            {
                services.Player.Changed += RefreshJingJieEntry;
                jingJieEntrySubscribed = true;
            }
            RefreshJingJieEntry();
        }

        private void RefreshJingJieEntry()
        {
            GameObject entry = FindMainHudNode(JingJiePath);
            if (entry == null) return;
            bool locked = services?.Player.Level < FunctionUnlockCatalog.Resolve(22).OpenLevel;
            entry.SetActive(true);
            SetHudFeatureVisual(entry.transform, locked);
        }

        private bool ValidateJingJieCurrencyHeader(out string detail)
        {
            CocosUiBinding binding = oneLevelFrameView?.Binding;
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
            if (heroHubOpen)
            {
                // The shared OneLevelLayer can be reused directly from the
                // hero-fragment page. Clear the hero-hub ownership before
                // configuring the four-tab player hub.
                heroHubOpen = false;
                heroFragmentBagActive = false;
                HideHeroHubContent();
            }
            HideOtherOneLevelChildren();
            ConfigureJingJieFrame();
            SetOneLevelFrameVisible(true);
            jingJieRenderBridge.Show();
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
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
            // The shared OneLevelLayer is also used by the ordinary Bag entry
            // (btn_Bag -> HandleBagClick -> /8 -> ConfigureBagFrame), and by Hero.
            // ShowJingJieBag() rebinds the frame's CloseBtn from BagPresenter's own
            // closeAction to this method. If this method then declines because the
            // 境界 page is not "open", the X button becomes permanently dead and the
            // frame can never be dismissed — the reported "背包界面关不掉".
            //
            // So when the frame is up but is NOT owned by an open Jingjie page,
            // fall back to the ordinary bag close: tear down the bag flow, hide the
            // shared frame, and let HandleBack() unwind the UI stack.
            bool frameVisible = oneLevelFrameView != null && oneLevelFrameView.GameObject.activeInHierarchy;
            if (!IsJingJieOpen || services?.UiStack.Current != oneLevelFrameView)
            {
                if (!frameVisible || bagView == null) return false;
                bagFlowPresenter?.CloseAll();
                SetOneLevelFrameVisible(false);
                HandleBack();
                return true;
            }
            // USER RULING (2026-09-17): the X button dismisses the WHOLE shared frame
            // from either surface. Bag mode used to call ShowJingJieSurface() first,
            // which stepped back to 境界 and required a SECOND press to actually leave
            // (reported defect). Both surfaces now terminate through the same path:
            // tear down the bag surface, hide the jingjie content, pop the frame.
            if (jingJieSurfaceMode == JingJieSurfaceMode.Bag)
            {
                bagFlowPresenter?.CloseAll();
                bagView?.SetVisible(false);
                jingJieBagDataRequested = false;
                RestoreJingJieFrameOrder();
            }
            else if (jingJieSurfaceMode == JingJieSurfaceMode.Mail)
            {
                bagFlowPresenter?.CloseAll();
                mailView?.SetVisible(false);
            }
            else if (jingJieSurfaceMode == JingJieSurfaceMode.Settings)
            {
                settingsView?.SetVisible(false);
            }
            jingJieRenderBridge.Hide();
            if (!PopUiStackWithHudRefresh())
            {
                // Nothing to pop (the frame was never pushed / is the stack root).
                // Dismiss it explicitly rather than leaving a content-less shared
                // frame on screen with no way out.
                SetOneLevelFrameVisible(false);
            }
            return true;
        }

        private void EnsureJingJieBridge()
        {
            if (jingJieRenderBridge != null) return;
            EnsureOneLevelFrame();
            jingJieView = services.UiRouter.FindBySource("zhujue/JingjieLayer")
                ?? UiPrefabLoader.Load("JingjieLayer", oneLevelFrameView.GameObject.transform);
            jingJiePreviewView = services.UiRouter.FindBySource("zhujue/Jingjieyulan")
                ?? UiPrefabLoader.Load("Jingjieyulan", oneLevelFrameView.GameObject.transform);
            if (jingJieView == null || jingJiePreviewView == null)
                throw new InvalidOperationException("JingJie imported Prefabs were not found.");
            jingJieConfig = jingJieConfig ?? new JingJieConfigData();
            jingJieRenderBridge = new JingJieRenderBridge(jingJieView, jingJiePreviewView,
                services.JingJie, jingJieConfig, services.Player, services.Currencies, services.Bag,
                services.Resources, RequestJingJieUpgrade, ShowJingJieMaterial, message => ShowToast(message, 2f));
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true);
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
            Transform frame = oneLevelFrameView?.GameObject.transform;
            if (frame == null) return;
            foreach (Transform child in frame)
                if (child.name.StartsWith("DynamicUi_", StringComparison.Ordinal)
                    && child.gameObject != jingJieView?.GameObject
                    && child.gameObject != jingJiePreviewView?.GameObject)
                    child.gameObject.SetActive(false);
        }

        private void ConfigureJingJieFrame()
        {
            EnsureOneLevelFrame().Apply(OneLevelFrameMode.Standard);
            CocosUiBinding binding = oneLevelFrameView.Binding;
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
            Transform second = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            if (second != null) second.gameObject.SetActive(true);
            SetJingJieTabs(first, second, true);
            // Panel_10 is shared with other first-class pages. Only the four
            // player-hub tabs may remain visible here.
            Transform tabPanel = binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            if (tabPanel != null)
                foreach (Transform child in tabPanel)
                    if (child != first && child.name != "Button2_Runtime"
                        && child.name != "Button3_Runtime" && child.name != "Button4_Runtime")
                        child.gameObject.SetActive(false);
            RefreshStandardCurrencyHeader(binding, "Layer/GoldCheck");
            foreach (Transform child in binding.transform.GetComponentsInChildren<Transform>(true))
                if (child.name == "Prompt") child.gameObject.SetActive(false);
        }

        private void SetJingJieTabs(Transform first, Transform second, bool selectedFirst = true)
        {
            ConfigureMergedTabs(selectedFirst ? 0 : 1);
        }

        private void ConfigureMergedTabs(int selectedIndex)
        {
            Transform panel = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10")?.transform;
            Transform first = panel?.Find("Button1");
            if (first == null) return;
            Transform[] tabs =
            {
                first,
                EnsureRuntimeTab(panel, "Button2_Runtime", first, -100f),
                EnsureRuntimeTab(panel, "Button3_Runtime", first, -200f),
                EnsureRuntimeTab(panel, "Button4_Runtime", first, -300f)
            };
            string[] labels = { "境界", "背包", "邮件", "系统" };
            Action[] actions = { ShowJingJieSurface, ShowJingJieBag, ShowMergedMail, ShowMergedSettings };
            for (int index = 0; index < tabs.Length; index++)
            {
                Transform tab = tabs[index];
                if (tab == null) continue;
                tab.gameObject.SetActive(true);
                SetTabText(tab, labels[index], index == selectedIndex);
                Button button = EnsureTabClick(tab);
                button.onClick.RemoveAllListeners();
                Action action = actions[index];
                button.onClick.AddListener(() => action());
            }
            if (panel != null)
                foreach (Transform child in panel)
                    if (child != tabs[0] && child != tabs[1] && child != tabs[2] && child != tabs[3])
                        child.gameObject.SetActive(false);
            jingJieSurfaceMode = (JingJieSurfaceMode)selectedIndex;
            // Order the frame so this surface's tabs win the raycast against the
            // embedded bag grid (see RaiseJingJieTabs for why not a Canvas).
            RaiseJingJieTabs(selectedIndex == 1);
        }

        private static Transform EnsureRuntimeTab(Transform panel, string name, Transform template, float yOffset)
        {
            if (panel == null || template == null) return null;
            Transform tab = panel.Find(name);
            if (tab == null)
            {
                tab = Instantiate(template.gameObject, panel, false).transform;
                tab.name = name;
            }
            RectTransform source = template as RectTransform;
            RectTransform target = tab as RectTransform;
            if (source != null && target != null)
                target.anchoredPosition = source.anchoredPosition + new Vector2(0f, yOffset);
            return tab;
        }

        // Makes a tab clickable WITHOUT touching the state SetTabText just installed.
        //
        // ⚠️ HISTORY — the previous version called EnableOwnTabGraphic + EnsureRuntimeButton
        // here, which BROKE the selected/unselected artwork (user-reported, see §13):
        //   * EnableOwnTabGraphic() did `own.enabled = true` and
        //     `ChooseBg.SetActive(true)` unconditionally, so the UNSELECTED tab also
        //     showed the "chosen" plate — both tabs looked selected.
        //   * It never applied SetTabText's `background.color = alpha 0` for unselected,
        //     so the unselected tab stayed fully opaque (measured alpha=1.00).
        //   * EnsureRuntimeButton(name collision) + `interactable = true` overrode
        //     SetTabText's `interactable = !selected`, re-enabling the selected tab.
        //
        // The authoritative pattern is SelectHeroEquipmentTab (ProjectXApp.cs:15297),
        // which only calls SetTabText and relies on the tab's own imported artwork for
        // raycasting. That works for Hero because nothing overlaps its tab column.
        // Here the embedded bag grid spans the frame, so an extra *invisible* raycast
        // carrier is added as a child of the tab. It carries no sprite and alpha 0, so
        // it cannot affect the visible selected/unselected state, and it lives inside
        // the tab so it shares the tab's lifetime and disappears with the page.
        private static Button EnsureTabClick(Transform tab)
        {
            Graphic own = tab.GetComponent<Graphic>();
            if (own != null) own.raycastTarget = true;
            Button button = tab.GetComponent<Button>();
            if (button == null) button = tab.gameObject.AddComponent<Button>();
            Transform carrier = tab.Find("RuntimeClickArea");
            Image carrierImage;
            if (carrier == null)
            {
                var go = new GameObject("RuntimeClickArea", typeof(RectTransform), typeof(Image));
                carrier = go.transform;
                carrier.SetParent(tab, false);
                carrierImage = go.GetComponent<Image>();
                RectTransform carrierRect = carrier as RectTransform;
                carrierRect.anchorMin = Vector2.zero;
                carrierRect.anchorMax = Vector2.one;
                carrierRect.offsetMin = Vector2.zero;
                carrierRect.offsetMax = Vector2.zero;
            }
            else
            {
                carrierImage = carrier.GetComponent<Image>();
                if (carrierImage == null) carrierImage = carrier.gameObject.AddComponent<Image>();
            }
            // Fully transparent but still raycastable: an Image with alpha 0 and
            // raycastTarget=true (no CanvasRenderer cull) is a valid raycast target.
            carrierImage.color = new Color(0f, 0f, 0f, 0f);
            carrierImage.raycastTarget = true;
            // Keep it last so it wins against the tab's own children.
            carrier.SetAsLastSibling();
            // ⚠️ Button.transition MUST be turned off and targetGraphic re-pointed.
            // Cocos exports these tabs as ColorTint with targetGraphic = the tab's own
            // Image. In that configuration Selectable drives the tab Image's colour on
            // every state change using normalColor (alpha 1), which OVERWRITES the
            // alpha-0 that SetTabText assigns to the unselected tab — so the unselected
            // tab silently becomes opaque again ("both tabs highlighted").
            // Routing targetGraphic to the invisible carrier keeps the tint harmless:
            // the carrier's own colour is alpha 0, so any tint multiplied into it stays
            // invisible, and the tab's authored selected/unselected artwork is then
            // owned solely by SetTabText.
            button.transition = Selectable.Transition.None;
            button.targetGraphic = carrierImage;
            return button;
        }

        // Keep the shared frame's tab row above embedded content (the bag grid).
        //
        // Two earlier attempts were both wrong and are recorded here so nobody
        // repeats them:
        //   1. Adding a Canvas to Panel_10 left a NON-ROOT canvas nested in the frame.
        //      Unity then fell back to screen-space-overlay sorting and promoted the
        //      whole tab subtree above every layer; the tabs kept painting and
        //      raycasting after the page closed, so the frame could not be dismissed.
        //   2. Adding a Canvas to the frame ROOT would re-sort the frame's own
        //      children and break the Bg / content / Panel_12 order established in
        //      ShowJingJieBag.
        //
        // The bag's per-row RuntimeHitArea is a full-width Image on a later sibling,
        // so it simply wins the raycast inside a shared canvas. The correct fix is
        // plain sibling ordering — no canvases, no sorting overrides, nothing that
        // can outlive the frame.
        //
        // ⚠️ THIRD correction (2026-09-17). Two orderings were tried and both were
        // wrong; the measured frame geometry explains why:
        //
        //   frame root children     World rect
        //   --------------------    ----------------------------------------
        //   Bg                      (full screen backdrop)
        //   DynamicUi_beibao        X[0,1334] Y[0,750] — no layout of its own;
        //                           only beibao_layer/Bag/Image  X[545,1145] Y[90,668]
        //                           and    beibao_layer/Bag/TableView X[552,1137] Y[120,643]
        //                           are actually painted.
        //   GoldCheck               currency header (top strip)
        //   Panel_12                X[0,1334] Y[0,750]
        //     Bg/bg1_0  ui_common_bg              X[108,1226] Y[66,684]   <- frame skin
        //     Bg/bg1_2  ui_common_yangpizhi_bg    X[122,1148] Y[81,669]   <- OPAQUE parchment
        //     Bg/bg1_4  ui_common_diwen_youyeqian X[1145,1224] Y[85,644]
        //     Bg/bg1_3  ui_juee_dizuo             X[108,1226] Y[57,82]
        //     Title/TitleName                     Y[697,750]
        //     Bg/Btn_ListView/Panel_10/Button1    X[1146,1224] Y[566,666]  <- 境界 tab
        //     Bg/Btn_ListView/Panel_10/Button2_*  X[1146,1224] Y[466,566]  <- 背包 tab
        //
        // Panel_12 is the LAST child, so its opaque parchment (bg1_2, 1026x588) paints
        // OVER the bag sheet and the user sees an empty cream box. Pinning Panel_12 to
        // the top (the previous "fix") produced exactly the reported blank screenshot.
        //
        // The ordinary bag entry gets this right by putting the bag LAST:
        //     oneLevelFrameView.SetAsLastSibling();
        //     bagView.SetAsLastSibling();          // ProjectXApp.cs:5901-5902
        // so the bag sheet covers the parchment, and because the bag sheet only spans
        // X[545,1145] Y[90,668] the frame's title (Y 697-750) and the tab column
        // (X 1146-1224) stay outside it — both remain fully visible and hit-testable
        // with no extra canvas or raycast trickery. Mirror that here.
        private void RaiseJingJieTabs(bool raise)
        {
            if (oneLevelFrameView == null) return;
            CocosUiBinding frameBinding = oneLevelFrameView.Binding;
            if (frameBinding == null) return;
            Transform frameRoot = frameBinding.transform;
            Transform panel12 = frameBinding.Find("Layer/Panel_12")?.transform;
            Transform goldCheck = frameBinding.Find("Layer/GoldCheck")?.transform;
            Transform layerBg = frameBinding.Find("Layer/Bg")?.transform;
            Transform bagRoot = bagView?.GameObject != null ? bagView.GameObject.transform : null;
            // Keep the imported order for everything except the bag: Bg(0) < Panel_12(1)
            // < GoldCheck(2) < bag(last).
            if (layerBg != null) layerBg.SetSiblingIndex(0);
            if (panel12 != null) panel12.SetSiblingIndex(Mathf.Min(1, frameRoot.childCount - 1));
            if (goldCheck != null) goldCheck.SetSiblingIndex(Mathf.Min(2, frameRoot.childCount - 1));
            if (raise)
            {
                // bag surface: the bag sheet goes on top (same as the ordinary bag entry).
                if (bagRoot != null) bagRoot.SetAsLastSibling();
            }
            else
            {
                // 境界 surface: the bag is hidden anyway; keep it under the skin.
                if (bagRoot != null) bagRoot.SetSiblingIndex(Mathf.Min(3, frameRoot.childCount - 1));
            }
        }

        // REMOVED (2026-09-17, §13): EnableOwnTabGraphic() forced
        // `own.enabled = true` + `ChooseBg.SetActive(true)` on EVERY tab it was given,
        // including the unselected one. That made both tabs render their "chosen" plate
        // (user-reported: 境界/背包 both highlighted) and left the unselected tab's own
        // Image opaque because it never applied SetTabText's alpha-0 rule.
        // Selected/unselected artwork is now owned exclusively by SetTabText.

        private void ShowJingJieSurface()
        {
            // All player-hub pages share OneLevelLayer. Switching back from
            // Settings/Mail must explicitly hide the previous content; UiStack
            // only owns the shared frame root, not its dynamically attached
            // children.
            settingsView?.SetVisible(false);
            mailView?.SetVisible(false);
            bagView?.SetVisible(false);
            // Allow the next 背包 entry to re-request the authoritative snapshot.
            jingJieBagDataRequested = false;
            // Restore the frame's original sibling order when leaving bag mode so
            // the 境界 content renders over the frame backdrop again.
            RestoreJingJieFrameOrder();
            jingJieView?.SetVisible(true);
            jingJiePreviewView?.SetVisible(false);
            jingJieView?.GameObject.transform.SetAsLastSibling();
            jingJieRenderBridge?.Show();
            Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            Transform first = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            Transform second = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            SetJingJieTabs(first, second, true);
        }

        // Restores the shared frame to its imported child order:
        // Bg(0) / Panel_12(1) / GoldCheck(2).
        private void RestoreJingJieFrameOrder()
        {
            RaiseJingJieTabs(false);
        }

        // Fire the same Lua callback the ordinary main-UI bag entry uses so the
        // server sends /8; EndBagUpdate then fills services.Bag and the bag grid
        // repaints. Without this the embedded bag renders an empty local store.
        private void EnsureJingJieBagDataRequested()
        {
            if (jingJieBagDataRequested) return;
            jingJieBagDataRequested = true;
            InvokeLuaOrFail(onBagClicked, "JingJie.BagSnapshot");
        }

        private void ShowJingJieBag()
        {
            EnsureBagPresenter();
            // If the bag view could not be created, do NOT touch the frame: an
            // earlier version created/hid everything first and only then bailed out
            // on `bagView == null`, leaving the shared frame open with an empty
            // surface and no way to dismiss it (the reported "背包关不掉").
            if (bagView == null) return;
            // BagPresenter's constructor overwrites the frame CloseBtn binding with
            // its own closeAction. Re-assert Jingjie's so X in bag mode returns to
            // the 境界 surface instead of closing the whole frame.
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true);
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            frame.Apply(OneLevelFrameMode.Standard);
            jingJieView?.SetVisible(false);
            jingJiePreviewView?.SetVisible(false);
            // Reparent the bag INSIDE the shared frame (ConfigureBagFrame does the
            // same); otherwise its full-screen root stays a Canvas sibling and is
            // not laid out for the frame.
            frame.AttachContent(bagView);
            bagView.SetVisible(true);
            // AUTHORITATIVE DATA: the ordinary main-UI bag entry (HandleBagClick)
            // fires the Lua callback that requests /8; EndBagUpdate then fills
            // services.Bag and BagPresenter.Render() paints it. Rendering straight
            // from the local store here would always be empty on a fresh session
            // (itemCount=0), which is why the tab previously showed no items.
            // Re-request the snapshot the same way the real bag entry does.
            EnsureJingJieBagDataRequested();
            bagPresenter?.Render();
            SetOneLevelFrameVisible(true);
            CocosUiBinding frameBinding = oneLevelFrameView.Binding;
            Transform frameRoot = frameBinding.transform;
            // LAYERING: the frame root itself is normalised first; then RaiseJingJieTabs
            // (called at the end of SetJingJieTabs) installs Bg < Panel_12 < GoldCheck
            // < bag so the bag sheet paints over the opaque parchment backdrop. See the
            // geometry table on RaiseJingJieTabs — putting Panel_12 on top instead is
            // what produced the blank "empty cream box" screenshot.
            // Same normalisation ConfigureBagFrame performs after AttachContent:
            // without it the frame root keeps a non-zero anchoredPosition and the
            // reparented bag lands at local y=-750 (off-screen), so its rows never
            // become active even though the store has data.
            RectTransform rootRect = frameRoot as RectTransform;
            if (rootRect != null)
            {
                rootRect.pivot = new Vector2(0f, 1f);
                rootRect.anchorMin = rootRect.anchorMax = new Vector2(0f, 1f);
                rootRect.anchoredPosition = Vector2.zero;
                rootRect.localScale = Vector3.one;
            }
            // The BAG's own anchors must be normalised too. Imported prefabs can
            // arrive with pivot/anchorMin/anchorMax = (0,0) (bottom-left), and when
            // a child's anchor does not match its parent's pivot, anchoredPosition
            // (0,0) resolves to localPosition (0,-750) — i.e. one full frame height
            // BELOW the frame, off-screen. The data and the row objects were both
            // fine (rows=49 active=49, itemCount=245) yet nothing was visible, which
            // is why this looked like "没有数据". Mirror the frame root's top-left
            // anchoring so the two agree regardless of the prefab's imported state.
            RectTransform bagRect = bagView.GameObject.transform as RectTransform;
            if (bagRect != null)
            {
                bagRect.pivot = new Vector2(0f, 1f);
                bagRect.anchorMin = bagRect.anchorMax = new Vector2(0f, 1f);
                bagRect.anchoredPosition = Vector2.zero;
                bagRect.localScale = Vector3.one;
            }
            Text title = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "背包";
            Transform first = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            Transform second = oneLevelFrameView?.Binding.Find("Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button2_Runtime")?.transform;
            // SetJingJieTabs ends by calling RaiseJingJieTabs(true), which pins
            // Panel_12 to the top of the frame — the sibling order we want here.
            SetJingJieTabs(first, second, false);
        }

        private void ShowMergedMail()
        {
            EnsureMailPresenter();
            if (mailView == null) return;
            HideOtherOneLevelChildren();
            jingJieView?.SetVisible(false);
            jingJiePreviewView?.SetVisible(false);
            bagView?.SetVisible(false);
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            frame.Apply(OneLevelFrameMode.Standard);
            frame.AttachContent(mailView);
            ConfigureMailFrame();
            mailView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            ConfigureMergedTabs(2);
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            mailView.GameObject.transform.SetAsLastSibling();
            SetStatus($"Merged player hub mail active: {services.Mails.Count} mails.");
        }

        private void ShowMergedSettings()
        {
            EnsureSettingsPresenter();
            if (settingsView == null) return;
            HideOtherOneLevelChildren();
            jingJieView?.SetVisible(false);
            jingJiePreviewView?.SetVisible(false);
            bagView?.SetVisible(false);
            mailView?.SetVisible(false);
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            frame.Apply(OneLevelFrameMode.Standard);
            frame.AttachContent(settingsView);
            settingsPresenter.Refresh();
            settingsView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            oneLevelFrameView.BindClick("Layer/Panel_12/Title/CloseBtn", () => TryHandleJingJieBack(), true);
            Text title = oneLevelFrameView.Binding.Find("Layer/Panel_12/Title/TitleName")?.GetComponent<Text>();
            if (title != null) title.text = "主角";
            ConfigureMergedTabs(3);
            if (services.UiStack.Current != oneLevelFrameView) services.UiStack.Push(oneLevelFrameView);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            settingsView.GameObject.transform.SetAsLastSibling();
            SetStatus("Merged player hub settings active.");
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
