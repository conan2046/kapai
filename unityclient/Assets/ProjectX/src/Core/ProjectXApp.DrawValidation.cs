using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private IEnumerator RequestValidationDrawNextFrame()
        {
            yield return null;
            if (services.Draw.Count != 3)
            {
                Fail($"Draw validation expected 3 current pools, got {services.Draw.Count}.");
                yield break;
            }
            DrawPoolRecord normal = services.Draw.Pools.FirstOrDefault(value => value.Kind == 1);
            if (normal == null || normal.FreeTimes == 0 || normal.FreeCooldownSeconds != 0)
            {
                Fail($"Draw validation isolated role has no free normal draw: free={normal?.FreeTimes ?? 0}, cd={normal?.FreeCooldownSeconds ?? 0}.");
                yield break;
            }
            InvokeLuaOrFail(onDrawRequested, "Draw.ValidationSingle", 1d, 1d);
        }

        private IEnumerator BeginDrawG4SequenceNextFrame()
        {
            yield return null;
            if (drawG4SequenceRunning) yield break;
            drawG4SequenceRunning = true;
            drawG4LastError = string.Empty;
            drawG4ExpectedFailureCompleted = false;
            try
            {
                if (!IsDrawOpen || services.Draw.Count != 3 || !services.ServerTime.IsSynchronized)
                {
                    Fail("Draw G4 main state is not backed by three authoritative pools and server time.");
                    yield break;
                }
                MarkValidationControl("DRAW-01-MAIN-ENTRY");
                MarkValidationControl("DRAW-08-FREE-COUNTDOWN");
                MarkValidationControl("DRAW-09-RED-DOTS");
                MarkValidationControl("DRAW-10-MATERIAL-COUNTS");
                yield return CaptureDrawG5Evidence("DRAW-MAIN");

                // Header and navigation controls are exercised before any draw mutates
                // the authoritative pool state.
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon1/AddBtn", "DRAW-11-COUPON-INFO");
                if (!IsErrorVisible) { Fail("Draw coupon information did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-11-COUPON-INFO");
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon2/AddBtn", "DRAW-12-HIGH-EXCHANGE");
                if (!IsErrorVisible) { Fail("Draw high coupon exchange feedback did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-12-HIGH-EXCHANGE");
                ClickDrawButton(drawView, "Layer/Title/TitleName/Button_1", "DRAW-16-HELP");
                if (!IsErrorVisible) { Fail("Draw help did not open."); yield break; }
                errorPresenter.Hide(); MarkValidationControl("DRAW-16-HELP");
                ClickDrawButton(drawView, "Layer/Title/CloseBtn", "DRAW-17-CLOSE");
                if (IsDrawOpen) { Fail("Draw close did not return to main."); yield break; }
                ClickDrawButton(mainView, DrawPath, "DRAW-01-MAIN-ENTRY");
                float reopenDeadline = Time.realtimeSinceStartup + 8f;
                while (!IsDrawOpen && Time.realtimeSinceStartup < reopenDeadline) yield return null;
                if (!IsDrawOpen || services.Draw.Count != 3) { Fail("Draw did not reopen with authoritative pools."); yield break; }
                MarkValidationControl("DRAW-17-CLOSE");
                ClickDrawButton(drawView, "Layer/GoldCheck/GoldIcon3/AddBtn", "DRAW-13-FRIEND-SHORTCUT");
                float friendDeadline = Time.realtimeSinceStartup + 8f;
                while (!IsFriendOpen && Status.IndexOf("Friend is excluded", StringComparison.Ordinal) < 0
                    && Time.realtimeSinceStartup < friendDeadline) yield return null;
                if (!IsFriendOpen && Status.IndexOf("Friend is excluded", StringComparison.Ordinal) < 0)
                { Fail("Draw friend shortcut produced neither the Friend route nor explicit unavailable feedback."); yield break; }
                MarkValidationControl("DRAW-13-FRIEND-SHORTCUT");
                if (IsFriendOpen)
                {
                    // Friend opens with separate friend/application responses. Allow both
                    // real /27 callbacks to settle before returning, otherwise a delayed
                    // callback can repush Friend over the subsequently opened soul shop.
                    yield return new WaitForSecondsRealtime(0.5f);
                    HandleBack();
                    while (!IsDrawOpen && Time.realtimeSinceStartup < friendDeadline) yield return null;
                    if (!IsDrawOpen) { Fail("Draw friend shortcut did not return to Draw."); yield break; }
                }
                else if (!IsDrawOpen) { Fail("Draw excluded Friend feedback left the Draw page."); yield break; }
                ClickDrawButton(drawView, "Layer/Shop", "DRAW-14-SOUL-SHOP");
                float shopDeadline = Time.realtimeSinceStartup + 10f;
                while (!IsErrorVisible && (!IsGameplayShopOpen || GameplayShopRenderedCount <= 0)
                    && Time.realtimeSinceStartup < shopDeadline) yield return null;
                if (!IsErrorVisible && (!IsGameplayShopOpen || GameplayShopRenderedCount <= 0))
                { Fail("Draw soul shop produced neither rendered data nor explicit unavailable feedback."); yield break; }
                MarkValidationControl("DRAW-14-SOUL-SHOP");
                if (IsErrorVisible) errorPresenter.Hide();
                else CloseGameplayShops();
                while (!IsDrawOpen && Time.realtimeSinceStartup < shopDeadline) yield return null;
                if (!IsDrawOpen) { Fail("Draw soul shop did not return to Draw."); yield break; }
                ClickDrawButton(drawView, "Layer/RewardPreview", "DRAW-15-REWARD-PREVIEW");
                if (drawPreviewView?.GameObject.activeSelf != true) { Fail("Draw reward preview did not open."); yield break; }
                MarkValidationControl("DRAW-15-REWARD-PREVIEW");
                for (byte tab = 1; tab <= 3; tab++)
                {
                    Button button = drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab" + tab)?.GetComponent<Button>();
                    if (button == null) { Fail($"Draw preview tab {tab} is missing."); yield break; }
                    button.onClick.Invoke();
                    yield return null;
                    if (drawPresenter.PreviewPoolKind != tab || drawPresenter.PreviewRenderedCount <= 0)
                    {
                        Fail($"Draw preview tab {tab} did not render its configured pool."); yield break;
                    }
                }
                MarkValidationControl("DRAW-18-PREVIEW-TABS");
                drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab2")?.GetComponent<Button>()?.onClick.Invoke();
                yield return null;
                if (drawPresenter.PreviewPoolKind != 2) { Fail("Draw high reward preview tab did not remain selectable."); yield break; }
                if (!drawPresenter.ScrollPreviewToEnd()) { Fail("Draw high reward preview did not create a scrollable list."); yield break; }
                MarkValidationControl("DRAW-19-PREVIEW-SCROLL");
                drawPreviewView.GameObject.transform.Find("FirstClassBg/Tab1")?.GetComponent<Button>()?.onClick.Invoke();
                yield return null;
                if (drawPresenter.PreviewPoolKind != 1) { Fail("Draw normal reward preview tab did not remain selectable for Cocos parity capture."); yield break; }
                yield return CaptureDrawG5Evidence("DRAW-REWARD-PREVIEW");
                Button heroPreview = drawPreviewView.GameObject.transform.Find("PreviewViewport/IllustrationsList/Hero_35")?.GetComponent<Button>();
                if (heroPreview == null) { Fail("Draw normal reward preview hero entry is missing."); yield break; }
                heroPreview.onClick.Invoke();
                if (!drawPresenter.IsPreviewHeroDetailVisible) { Fail("Draw preview hero detail did not open."); yield break; }
                drawPresenter.HidePreviewHeroDetail(); MarkValidationControl("DRAW-20-PREVIEW-HERO-DETAIL");
                Button previewClose = drawPreviewView.GameObject.transform.Find("RuntimePreviewClose")?.GetComponent<Button>()
                    ?? drawPreviewView.Binding.Find("Layer/CloseBtn")?.GetComponent<Button>()
                    ?? drawPreviewView.Binding.Find("Layer/Btn_Close")?.GetComponent<Button>();
                previewClose?.onClick.Invoke();
                if (drawPreviewView.GameObject.activeSelf) { Fail("Draw reward preview did not close."); yield break; }

                // This must remain the first high-pool draw: the reversible server fixture
                // guarantees hero 64 only for that real /224 request. Run the cross-module
                // closure immediately afterwards so its visual state is not contaminated by
                // heroes obtained while exercising the remaining pool controls.
                yield return InvokeDrawAndDismiss("Layer/Popup2/Btn_Recruit_2", "DRAW-04-HIGH-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM", keepResult:true);
                DrawResultRecord targetResult = services.Draw.LastResult;
                if (targetResult == null || !targetResult.Rewards.Any(value => value.Id == DrawClosureTargetHeroId))
                {
                    Fail("Draw G4 deterministic high free draw did not return target hero 64.");
                    yield break;
                }
                yield return CaptureDrawG5Evidence("DRAW-RESULT-NEW");
                DismissDrawResult(drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
                StartCoroutine(RequestDrawClosureHeroNextFrame());
            }
            finally { drawG4SequenceRunning = false; }
        }

        private IEnumerator InvokeDrawAndDismiss(string requestPath, string requestControl,
            CocosUiView resultView, string dismissPath, string dismissControl, bool keepResult = false)
        {
            services.Draw.ClearResult();
            ClickDrawButton(drawView, requestPath, requestControl);
            float deadline = Time.realtimeSinceStartup + 12f;
            while (services.Draw.LastResult == null && Time.realtimeSinceStartup < deadline) yield return null;
            if (services.Draw.LastResult == null || !resultView.GameObject.activeSelf)
            {
                Fail($"Draw G4 request did not render an authoritative result: {requestControl}.");
                yield break;
            }
            MarkValidationControl(requestControl);
            if (!keepResult) DismissDrawResult(resultView, dismissPath, dismissControl);
        }

        private void DismissDrawResult(CocosUiView resultView, string path, string control)
        {
            ClickDrawButton(resultView, path, control);
            if (resultView.GameObject.activeSelf)
                throw new InvalidOperationException($"Draw result control did not dismiss its authoritative result: {control}.");
            MarkValidationControl(control);
        }

        private static void ClickDrawButton(CocosUiView view, string path, string control)
        {
            GameObject node = view?.Binding.Find(path);
            Button button = node?.GetComponent<Button>();
            if (button == null || !button.interactable)
                throw new InvalidOperationException($"Draw G4 control is missing or disabled: {control} ({path}).");
            button.onClick.Invoke();
        }

        private IEnumerator CaptureDrawG5Evidence(string evidenceId)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) yield break;
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Draw", "unity", "g5-20260730", "run-copy");
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, evidenceId + ".png");
            if (File.Exists(path)) File.Delete(path);
            // Cocos result timelines begin with a short reveal phase. Capture only
            // after the stable frame so the G5 original contains the authoritative
            // reward node rather than the empty initial animation frame.
            yield return new WaitForSecondsRealtime(3.5f);
            Canvas.ForceUpdateCanvases();
            if (evidenceId == "DRAW-HERO-LIST")
            {
                Button target = FindHeroBagButton("郑伦");
                Transform viewport = heroBagView?.Binding.Find("Layer/yingxiongbeibaoUI/TableView")?.transform;
                int activeRows = viewport == null ? -1 : viewport.GetComponentsInChildren<Transform>(false)
                    .Count(value => value.name.StartsWith("VirtualRow_", StringComparison.Ordinal));
                ProjectX.Diagnostics.ClientLog.Verbose($"[ProjectX][DrawG5] hero-list bag={heroBagView?.GameObject.activeSelf}/"
                    + $"{heroBagView?.GameObject.activeInHierarchy} target={target?.gameObject.activeSelf}/"
                    + $"{target?.gameObject.activeInHierarchy} rows={activeRows} heroes={services.Heroes.Count} "
                    + $"entry={pendingHeroEntry} current={services.UiStack.Current?.GameObject?.name}");
            }
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Draw G5 screenshot was not written: {path}");
            if (evidenceId == "DRAW-MAIN")
            {
                string manifestScreenshot = Path.Combine(repositoryRoot, "build", "ui-migration", "bootstrap-draw.png");
                Directory.CreateDirectory(Path.GetDirectoryName(manifestScreenshot));
                File.Copy(path, manifestScreenshot, true);
            }
        }

        private IEnumerator CaptureDrawInsufficientThenRequestHero()
        {
            yield return CaptureDrawG5Evidence("DRAW-RESOURCE-INSUFFICIENT");
            if (drawCompleteRemainingAfterInsufficient)
            {
                drawCompleteRemainingAfterInsufficient = false;
                HideDrawExchange();
                if (drawTenResultView?.GameObject.activeSelf == true)
                    DismissDrawResult(drawTenResultView, "Layer/btn_Close", "DRAW-26-TEN-CONFIRM");
                StartCoroutine(CompleteBasicFriendDrawControlsThenReconnect());
                yield break;
            }
            if (drawClosureHeroMounted)
                StartCoroutine(ValidateDrawClosureReconnect());
            else
                StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        private IEnumerator RequestDrawClosureHeroNextFrame()
        {
            yield return null;
            pendingHeroEntry = HeroEntry.Bag;
            InvokeLuaOrFail(onHeroClicked, "Draw.ClosureHeroEntry");
        }

        public void BeginDrawClosureBagRefresh()
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            InvokeLuaOrFail(onDrawClosureBagRefresh, "Draw.ClosureBagRefresh");
        }

        public void CompleteDrawClosureBagRefresh(int serverCount)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            int current = GetBagQuantityByItemId(DrawClosureLevelMaterialId);
            if (drawClosureInitialLevel == 0)
            {
                if (!services.Heroes.TryGet(DrawClosureTargetHeroId, out HeroRecord hero)
                    || hero.Name != "郑伦" || hero.Star <= 0 || hero.Level <= 0 || hero.Attack <= 0
                    || hero.Health <= 0 || hero.FightPosition != 0 || serverCount <= 0 || current < 1)
                {
                    Fail($"Draw closure initial bag/hero snapshot mismatch: hero={hero.Id}, name={hero.Name}, star={hero.Star}, level={hero.Level}, pos={hero.FightPosition}, bag={serverCount}, material={current}.");
                    return;
                }
                drawClosureInitialLevel = hero.Level;
                drawClosureInitialExperience = hero.Experience;
                drawClosureInitialMaterial = current;
                StartCoroutine(CultivateDrawClosureHeroThroughUi());
                return;
            }
            if (serverCount <= 0 || current >= drawClosureInitialMaterial)
            {
                Fail($"Draw closure level material was not authoritatively deducted: serverCount={serverCount}, current={current}, before={drawClosureInitialMaterial}.");
                return;
            }
            StartCoroutine(MountDrawClosureHeroThroughUi());
        }

        public void CompleteDrawClosureHeroLevelUp(int heroId, int beforeLevel, int afterLevel,
            double beforeExperience, double afterExperience)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (heroId != DrawClosureTargetHeroId || beforeLevel != drawClosureInitialLevel
                || (afterLevel <= beforeLevel && afterExperience <= beforeExperience))
            {
                Fail($"Draw closure cultivation snapshot mismatch: hero={heroId}, level={beforeLevel}/{afterLevel}, exp={beforeExperience}/{afterExperience}.");
                return;
            }
            if (heroCultivationView?.GameObject.activeSelf != true
                || heroLevelUpView?.GameObject.activeSelf != true
                || heroListView?.GameObject.activeSelf == true
                || heroDetailView?.GameObject.activeSelf == true
                || heroBagView?.GameObject.activeSelf == true)
            {
                Fail("Draw closure cultivation refresh reopened formation/list layers over the active cultivation UI.");
                return;
            }
            drawClosureHeroCultivated = true;
        }

        public void CompleteDrawClosureFormation(int heroId, int position, int level, double attack, double health)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (heroId != DrawClosureTargetHeroId || position != DrawClosureFormationPosition
                || !drawClosureHeroCultivated || attack <= 0 || health <= 0
                || services.Formation.GetCombatPosition(heroId) != position)
            {
                Fail($"Draw closure formation snapshot mismatch: hero={heroId}, position={position}, level={level}, attack={attack}, health={health}.");
                return;
            }
            drawClosureHeroMounted = true;
            pendingHeroEntry = HeroEntry.Formation;
            StartCoroutine(CaptureMountedDrawFormationThenReenter());
        }

        private IEnumerator CultivateDrawClosureHeroThroughUi()
        {
            yield return null;
            EnsureHeroPresenter();
            // /8 is refreshed for Draw ticket counts and can leave the ordinary
            // item-bag content active behind the shared OneLevelLayer.  Enter the
            // Hero bag exactly as the native client does before locating or
            // capturing the recruited hero.
            bagFlowPresenter?.CloseAll();
            bagView?.SetVisible(false);
            bagInputView?.SetVisible(false);
            bagPopupFrameView?.SetVisible(false);
            bagGiftView?.SetVisible(false);
            bagSourceView?.SetVisible(false);
            bagEquipmentInfoView?.SetVisible(false);
            pendingHeroEntry = HeroEntry.Bag;
            heroListView.SetVisible(false);
            heroDetailView.SetVisible(false);
            heroBagView.SetVisible(true);
            SetOneLevelFrameVisible(true);
            Transform heroBagTransform = heroBagView.GameObject.transform;
            if (heroBagTransform.parent != oneLevelFrameView.GameObject.transform)
                heroBagTransform.SetParent(oneLevelFrameView.GameObject.transform, false);
            heroBagTransform.SetAsLastSibling();
            ConfigureHeroFrame(true);
            heroPresenter.Render();
            if (services.UiStack.Current != oneLevelFrameView)
                services.UiStack.Push(oneLevelFrameView);
            Canvas.ForceUpdateCanvases();
            Button target = FindHeroBagButton("郑伦");
            if (target == null) { Fail("Draw closure target hero was not rendered in the hero list."); yield break; }
            yield return CaptureDrawG5Evidence("DRAW-HERO-LIST");
            target.onClick.Invoke();
            if (heroPresenter.SelectedId != DrawClosureTargetHeroId)
            {
                Fail("Draw closure target hero row did not select hero 64.");
                yield break;
            }
            SetOneLevelFrameVisible(true);
            heroBagView.SetVisible(false);
            heroListView.SetVisible(true);
            heroDetailView.SetVisible(true);
            ConfigureHeroFrame(false);
            oneLevelFrameView.GameObject.transform.SetAsLastSibling();
            RequireBoundButton(heroDetailView, "Layer/EquipUI/Bg/bg/Image_bg/Btn_3_1_0", "Draw closure cultivate").onClick.Invoke();
            if (heroCultivationView?.GameObject.activeSelf != true || heroLevelUpView?.GameObject.activeSelf != true)
            {
                Fail("Draw closure cultivate control did not open the level-up UI.");
                yield break;
            }
            // Capture while the actual cultivation shell is stable.  The /24
            // material refresh may otherwise transition into formation before
            // the asynchronous screen capture executes.
            yield return CaptureDrawG5Evidence("DRAW-HERO-CULTIVATE");
            RequireBoundButton(heroLevelUpView, "Layer/shenjiangInfoUI/Info/cailiao/btn_shengji", "Draw closure level-up").onClick.Invoke();
        }

        private IEnumerator MountDrawClosureHeroThroughUi()
        {
            yield return null;
            EnsureHeroPresenter();
            if (heroCultivationView?.GameObject.activeSelf == true)
                RestoreHeroFormationView();
            if (services.Formation.GetCombatPosition(DrawClosureTargetHeroId) != 0)
            {
                Fail("Draw closure target hero was already mounted before the UI mount action.");
                yield break;
            }
            InvokeLuaOrFail(onDrawClosurePrepareMount, "Draw.ClosurePrepareFormationMount");
            int currentHeroId = GetFormationHeroAt(DrawClosureFormationPosition);
            ShowHeroReplacement(DrawClosureFormationPosition, currentHeroId);
            if (heroReplacementView?.GameObject.activeSelf != true)
            {
                Fail("Draw closure replacement UI did not open.");
                yield break;
            }
            yield return CaptureDrawG5Evidence("DRAW-FORMATION-SELECTION");
            Button action = heroReplacementView.GameObject.GetComponentsInChildren<Button>(true).FirstOrDefault(button =>
                button.gameObject.name == "Button" && button.transform.parent?.Find("Name")?.GetComponent<Text>()?.text.StartsWith("郑伦", StringComparison.Ordinal) == true);
            if (action == null)
            {
                Fail("Draw closure replacement UI did not render target hero 64.");
                yield break;
            }
            action.onClick.Invoke();
        }

        private Button FindHeroBagButton(string heroName)
        {
            if (heroBagView == null) return null;
            return heroBagView.GameObject.GetComponentsInChildren<Button>(true).FirstOrDefault(button =>
                button.transform.Find("Name")?.GetComponent<Text>()?.text.StartsWith(heroName, StringComparison.Ordinal) == true);
        }

        private IEnumerator CaptureMountedDrawFormationThenReenter()
        {
            // The Cocos Draw closure returns to the hero formation summary after the
            // /48 response.  Do not substitute the separate tactical formation map
            // here: it is a different user-facing screen and made the visual sample
            // incomparable even though the authoritative position was correct.
            formationPopupView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            SetOneLevelFrameVisible(true);
            heroListView?.SetVisible(true);
            heroDetailView?.SetVisible(true);
            heroBagView?.SetVisible(false);
            ConfigureHeroFrame(false);
            heroPresenter?.Render();
            oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
            yield return CaptureDrawG5Evidence("DRAW-FORMATION-MOUNTED");
            StartCoroutine(RequestDrawClosureModuleReentryNextFrame());
        }

        private void ShowDrawExchange()
        {
            drawExchangeView = drawExchangeView ?? services.UiRouter.FindBySource("common/daojuduihuan");
            if (drawExchangeView == null)
                throw new InvalidOperationException("Draw insufficient-resource exchange CocosUiBinding was not found.");
            drawExchangeView.BindClick("Layer/Popup/Btn_close", HideDrawExchange, true);
            if (drawExchangeDimmer == null)
            {
                drawExchangeDimmer = new GameObject("DrawExchangeDimmer", typeof(RectTransform), typeof(Image));
                RectTransform rect = drawExchangeDimmer.GetComponent<RectTransform>();
                rect.SetParent(drawExchangeView.GameObject.transform, false);
                rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                drawExchangeDimmer.GetComponent<Image>().color = new Color(0f, 0f, 0f, .82f);
                drawExchangeDimmer.GetComponent<Image>().raycastTarget = false;
                rect.SetAsFirstSibling();
            }
            drawExchangeDimmer.SetActive(true);
            SetBoundText(drawExchangeView, "Layer/Popup/Title/Title", "道具兑换");
            SetExchangeRuntimeText(drawExchangeView.Binding.Find("Layer/Popup/Title")?.transform,
                "RuntimeExchangeTitle", "道具兑换", TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, 27);
            Text exchangeTitle = drawExchangeView.Binding.Find("Layer/Popup/Title")?.transform
                .Find("RuntimeExchangeTitle")?.GetComponent<Text>();
            if (exchangeTitle != null) exchangeTitle.color = new Color(.96f, .80f, .60f, 1f);
            RenderDrawExchangeRows();
            drawExchangeView.SetVisible(true);
            drawExchangeView.GameObject.transform.SetAsLastSibling();
        }

        private void HideDrawExchange()
        {
            if (drawExchangeDimmer != null) drawExchangeDimmer.SetActive(false);
            drawExchangeView?.SetVisible(false);
        }

        private void RenderDrawExchangeRows()
        {
            Transform list = drawExchangeView.Binding.Find("Layer/Popup/ListView")?.transform;
            Transform template = drawExchangeView.Binding.Find("Layer/Popup/kuang")?.transform;
            if (list == null || template == null)
                throw new InvalidOperationException("Draw exchange imported ListView template was not found.");
            template.SetParent(list, false);
            for (int index = 0; index < 2; index++)
            {
                Transform row = index == 0 ? template : Instantiate(template.gameObject, list).transform;
                row.name = $"DrawExchangeRow{index + 1}";
                row.gameObject.SetActive(true);
                RectTransform rect = row as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = new Vector2(0.5f, 1f);
                    rect.anchorMax = new Vector2(0.5f, 1f);
                    rect.pivot = new Vector2(0.5f, 1f);
                    rect.anchoredPosition = new Vector2(0f, -12f - index * 128f);
                }
                // Cocos ItemExchangeUI reads shop 1014/1015: the price is
                // 60001 (pic 3012, YuanBao), while the output is item 1001
                // (pic 3028, advanced draw coupon).
                SetExchangeIcon(row.Find("Icon1"), 3012);
                SetExchangeIcon(row.Find("Icon2"), 3028);
                SetExchangeRuntimeText(row.Find("Icon1"), "RuntimeExchangeAmount", index == 0 ? "150" : "2700",
                    TextAnchor.LowerRight, new Vector2(.10f, .04f), new Vector2(.96f, .34f), 20);
                SetExchangeRuntimeText(row.Find("Icon2"), "RuntimeExchangeAmount", index == 0 ? "1" : "10",
                    TextAnchor.LowerRight, new Vector2(.10f, .04f), new Vector2(.96f, .34f), 20);
                Text button = row.Find("Btn_Confirm/Text")?.GetComponent<Text>();
                if (button != null) button.text = "兑 换";
                Text discount = row.Find("Discount/Value")?.GetComponent<Text>();
                if (discount != null)
                {
                    discount.transform.parent.gameObject.SetActive(index == 0);
                    discount.text = "5折";
                }
            }
        }

        private void SetExchangeIcon(Transform target, int picture)
        {
            Image image = target?.GetComponent<Image>();
            if (image == null) return;
            bool placeholder;
            image.sprite = services.Resources.LoadItemIcon(picture, out placeholder);
            image.enabled = image.sprite != null;
            image.preserveAspect = true;
        }

        private static void SetExchangeRuntimeText(Transform parent, string name, string value,
            TextAnchor alignment, Vector2 anchorMin, Vector2 anchorMax, int fontSize)
        {
            if (parent == null) return;
            Transform existing = parent.Find(name);
            GameObject instance = existing != null ? existing.gameObject
                : new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(Outline));
            RectTransform rect = instance.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin; rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = instance.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = fontSize; text.alignment = alignment; text.text = value;
            text.color = Color.white; text.raycastTarget = false;
            instance.transform.SetAsLastSibling();
        }

        private IEnumerator RequestDrawClosureModuleReentryNextFrame()
        {
            yield return null;
            InvokeLuaOrFail(onHeroClicked, "Draw.ClosureHeroReentry");
        }

        public void CompleteDrawClosureModuleReentry(int heroId, int position, int level)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (!drawClosureHeroMounted || heroId != DrawClosureTargetHeroId
                || position != DrawClosureFormationPosition || !drawClosureHeroCultivated)
            {
                Fail($"Draw closure module reentry mismatch: mounted={drawClosureHeroMounted}, hero={heroId}, position={position}, level={level}.");
                return;
            }
            StartCoroutine(CompleteRemainingDrawControlsThenReconnect());
        }

        private IEnumerator CompleteRemainingDrawControlsThenReconnect()
        {
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before remaining Draw controls.");
                yield break;
            }
            ClickDrawButton(mainView, DrawPath, "DRAW-01-MAIN-ENTRY");
            float openDeadline = Time.realtimeSinceStartup + 8f;
            while (!IsDrawOpen && Time.realtimeSinceStartup < openDeadline) yield return null;
            if (!IsDrawOpen) { Fail("Draw did not reopen after cross-module visual capture."); yield break; }

            drawG4SequenceRunning = true;
            try
            {
                // Preserve the Cocos baseline's authoritative 20/0/200 ticket
                // snapshot: consume the prepared ten high tickets and capture the
                // following real insufficiency before exercising basic/friend draws.
                yield return InvokeDrawAndDismiss("Layer/Popup2/Btn_Recruit_1", "DRAW-05-HIGH-TEN",
                    drawTenResultView, "Layer/btn_Continue", "DRAW-27-TEN-CONTINUE", keepResult:true);
                DrawResultRecord tenResult = services.Draw.LastResult;
                if (tenResult == null || !tenResult.Rewards.Concat(tenResult.GuaranteedRewards)
                    .Any(value => value.TransformItemId > 0 || value.TransformAmount > 0))
                {
                    Fail("Draw G4 high ten draw did not expose an authoritative duplicate conversion.");
                    yield break;
                }
                MarkValidationControl("DRAW-28-RESULT-TRANSFORM");
                yield return CaptureDrawG5Evidence("DRAW-RESULT-DUPLICATE");

                drawCompleteRemainingAfterInsufficient = true;
                drawG4ExpectFailure = true;
                drawG4LastError = string.Empty;
                ClickDrawButton(drawTenResultView, "Layer/btn_Continue", "DRAW-27-TEN-CONTINUE");
                float failureDeadline = Time.realtimeSinceStartup + 8f;
                while (string.IsNullOrWhiteSpace(drawG4LastError) && Time.realtimeSinceStartup < failureDeadline)
                    yield return null;
                drawG4ExpectFailure = false;
                if (drawG4ExpectedFailureCompleted) yield break;
                if (string.IsNullOrWhiteSpace(drawG4LastError))
                {
                    Fail("Draw G4 expected high-pool insufficient-resource response was not returned.");
                    yield break;
                }
                MarkValidationControl("DRAW-27-TEN-CONTINUE");
            }
            finally { drawG4SequenceRunning = false; }
        }

        private IEnumerator CompleteBasicFriendDrawControlsThenReconnect()
        {
            drawG4SequenceRunning = true;
            try
            {
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/Bg", "DRAW-21-SINGLE-TIMELINE-SKIP");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_1", "DRAW-03-BASIC-TEN",
                    drawTenResultView, "Layer/dancichoukaUI/bg", "DRAW-25-TEN-TIMELINE-SKIP");
                yield return InvokeDrawAndDismiss("Layer/Popup3/Btn_Recruit_2", "DRAW-06-FRIEND-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
                yield return InvokeDrawAndDismiss("Layer/Popup3/Btn_Recruit_1", "DRAW-07-FRIEND-TEN",
                    drawTenResultView, "Layer/btn_Close", "DRAW-26-TEN-CONFIRM");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/Skill_1", "DRAW-24-SINGLE-SKILL");
                yield return InvokeDrawAndDismiss("Layer/Popup1/Btn_Recruit_2", "DRAW-02-BASIC-SINGLE",
                    drawSingleResultView, "Layer/dancichoukaUI/btn_Continue", "DRAW-23-SINGLE-CONTINUE", keepResult:true);
                ClickDrawButton(drawSingleResultView, "Layer/dancichoukaUI/btn_Continue", "DRAW-23-SINGLE-CONTINUE");
                float continueDeadline = Time.realtimeSinceStartup + 12f;
                while (services.Draw.LastResult == null && Time.realtimeSinceStartup < continueDeadline) yield return null;
                if (services.Draw.LastResult == null || !drawSingleResultView.GameObject.activeSelf)
                {
                    Fail("Draw G4 single continue did not trigger a new authoritative /224 result.");
                    yield break;
                }
                MarkValidationControl("DRAW-23-SINGLE-CONTINUE");
                DismissDrawResult(drawSingleResultView, "Layer/dancichoukaUI/btn_Close", "DRAW-22-SINGLE-CONFIRM");
            }
            finally { drawG4SequenceRunning = false; }
            StartCoroutine(ValidateDrawClosureReconnect());
        }

        private IEnumerator ValidateDrawClosureReconnect()
        {
            InvokeLuaOrFail(onDrawClosurePrepareReconnect, "Draw.ClosurePrepareReconnect");
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before deliberate disconnect.");
                yield break;
            }
            services.Network.Disconnect();
            HandleDisconnected("Draw closure deliberate disconnect");
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected || services.Heroes.Count != 0
                || services.Formation.CombatHeroes.Count != 0 || services.Bag.Count != 0 || IsHeroOpen)
            {
                Fail("Draw closure disconnect did not clear authoritative Hero/Formation/Bag state.");
                yield break;
            }
            Reconnect();
            float deadline = Time.realtimeSinceStartup + 20f;
            while ((services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main)
            {
                Fail("Draw closure reconnect timed out.");
                yield break;
            }
            StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        public void CompleteDrawClosureReconnect(int heroId, int position, int level, double experience)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (!drawClosureHeroMounted || !drawClosureHeroCultivated || heroId != DrawClosureTargetHeroId
                || position != DrawClosureFormationPosition || level < drawClosureInitialLevel
                || experience <= drawClosureInitialExperience)
            {
                Fail($"Draw closure reconnect snapshot mismatch: hero={heroId}, position={position}, level={level}, exp={experience}.");
                return;
            }
            RecordValidationSemantic("draw-authority", true, "/224 and authoritative /24,/48 snapshots");
            RecordValidationSemantic("draw-target-hero", true, "hero 64 returned by /224 and /24");
            RecordValidationSemantic("hero-level-up", true, "authoritative material deduction and experience increase");
            RecordValidationSemantic("formation-mounted", true, "authoritative /48 position 1");
            RecordValidationSemantic("draw-reconnect", true, "reconnect reloaded hero cultivation and formation");
            StartCoroutine(ValidateDrawClosureAccountIsolation());
        }

        private IEnumerator ValidateDrawClosureAccountIsolation()
        {
            uint isolationUserId = services.Options.DrawIsolationUserId;
            if (isolationUserId == 0 || isolationUserId == GetLocalUserId())
            {
                Fail("Draw closure requires a distinct -projectXDrawIsolationUserId.");
                yield break;
            }
            InvokeLuaOrFail(onDrawClosurePrepareAccountIsolation, "Draw.ClosurePrepareAccountIsolation");
            services.Config.LocalUserId = isolationUserId;
            if (IsHeroOpen && !HandleBack())
            {
                Fail("Draw closure could not close Hero before alternate-account login.");
                yield break;
            }
            ReturnToLogin();
            yield return new WaitForSecondsRealtime(0.25f);
            if (!IsLoginVisible || services.Heroes.Count != 0 || services.Formation.CombatHeroes.Count != 0)
            {
                Fail($"Draw closure account-switch cleanup mismatch: login={IsLoginVisible}, heroes={services.Heroes.Count}, combat={services.Formation.CombatHeroes.Count}, activeFormation={services.Formation.ActiveFormationId}.");
                yield break;
            }
            Reconnect();
            float deadline = Time.realtimeSinceStartup + 20f;
            while ((services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || services.ProtocolRegistry.PendingCount != 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (services.Network.State != NetworkState.Connected || CurrentAppState != AppState.Main
                || GetLocalUserId() != isolationUserId)
            {
                Fail($"Draw closure alternate-account login failed: expected={isolationUserId}, actual={GetLocalUserId()}.");
                yield break;
            }
            StartCoroutine(RequestDrawClosureHeroNextFrame());
        }

        public void CompleteDrawClosureAccountIsolation(int heroCount, int mountedTargetPosition)
        {
            if (!HasCommandLineFlag("-projectXDrawClosureValidation")) return;
            if (services.Options.DrawIsolationUserId == 0 || GetLocalUserId() != services.Options.DrawIsolationUserId
                || services.Heroes.TryGet(DrawClosureTargetHeroId, out _) || mountedTargetPosition != 0)
            {
                Fail($"Draw closure alternate account inherited target state: user={GetLocalUserId()}, heroes={heroCount}, targetPosition={mountedTargetPosition}.");
                return;
            }
            RecordValidationSemantic("draw-account-isolation", true,
                $"alternate user={GetLocalUserId()} has no hero {DrawClosureTargetHeroId} or formation position");
            Complete($"COMPLETE: /224 high free deterministic target {DrawClosureTargetHeroId} -> /24 authoritative cultivation -> /48 position {DrawClosureFormationPosition} -> reconnect persistence -> alternate account {GetLocalUserId()} isolation");
        }


    }
}

