using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using ProjectX.Data;
using ProjectX.UI;
using ProjectX.Validation;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private LuaFunction onFishClicked;
        private LuaFunction onFishStart;
        private LuaFunction onFishStop;
        private LuaFunction onFishCollect;
        private LuaFunction onFishExit;
        private CocosUiView fishView;
        private FishPresenter fishPresenter;
        private readonly List<FishBasketSlot> pendingFishSlots = new List<FishBasketSlot>();
        private bool fishExitSent;
        private bool fishValidationRunning;

        public void ShowFish(int functionId)
        {
            GameplayDefinition definition = services.GameplayCatalog.Find(functionId);
            FunctionRouteDefinition route = FunctionRouteCatalog.Resolve(functionId);
            if (definition == null || route.Target != "Fish" || string.IsNullOrWhiteSpace(route.PrefabKey))
            {
                Fail($"Fish route config is incomplete: id={functionId}.");
                return;
            }
            EnsureFishPresenter(route);
            fishExitSent = false;
            gameplayPresenter?.HideDetail();
            gameplayView?.SetVisible(false);
            gameplayContentView?.SetVisible(false);
            if (services.UiStack.Current != fishView) services.UiStack.Push(fishView, false);
            fishPresenter.SetModuleVisible(true);
            SetStatus("Fish fake scene 54 active at region 1; awaiting /217 join.");
        }

        public void ConfigureFish(int sceneId, int mapId, int x, int y, int direction, bool flip,
            int shapeId, double gold, double goldCost, int minSeconds, int maxSeconds,
            int capacity, int stackLimit, bool fishing, int remainingSeconds)
        {
            services.Fish.Configure(sceneId, mapId, x, y, checked((byte)direction), flip,
                shapeId, checked((uint)gold), checked((uint)goldCost), checked((ushort)minSeconds),
                checked((ushort)maxSeconds), checked((ushort)capacity), checked((ushort)stackLimit),
                fishing, checked((ushort)remainingSeconds));
            services.Currencies.Set(CurrencyIds.Gold, checked((long)gold));
        }

        public void BeginFishBasket() => pendingFishSlots.Clear();
        public void AddFishBasketSlot(int slotIndex, int itemId, int quantity) =>
            pendingFishSlots.Add(new FishBasketSlot(checked((ushort)slotIndex),
                checked((ushort)itemId), checked((ushort)quantity)));
        public void CommitFishBasket() => services.Fish.ReplaceBasket(pendingFishSlots);

        public void BeginFishCycle(int duration, int direction, double gold)
        {
            services.Fish.BeginFishing(checked((ushort)duration), checked((byte)direction), checked((uint)gold));
            services.Currencies.Set(CurrencyIds.Gold, checked((long)gold));
        }

        public void CompleteFishCatch(int itemId, int slotIndex, int quantity, bool discarded,
            int nextDuration, double gold)
        {
            services.Fish.ApplyCatch(checked((ushort)itemId), checked((ushort)slotIndex),
                checked((ushort)quantity), discarded, checked((ushort)nextDuration), checked((uint)gold));
            services.Currencies.Set(CurrencyIds.Gold, checked((long)gold));
            if (itemId == 0)
            {
                ShowToast("提前收网，未获得鱼", 2.5f);
            }
            else
            {
                RewardRecord item = services.ShopCatalog.DescribeServerReward(itemId, 0, 1);
                ShowToast(discarded
                    ? $"鱼篓已满，{item.Name}已舍弃"
                    : $"钓到{item.Name}，当前格 {quantity}/{services.Fish.StackLimit}", 2.5f);
            }
        }

        public void CompleteFishCollect(int slotIndex, int itemId, int quantity)
        {
            services.Fish.ApplyCollected(checked((ushort)slotIndex));
            RewardRecord item = services.ShopCatalog.DescribeServerReward(itemId, 0, checked((uint)quantity));
            ShowToast($"已收获 {item.Name} ×{quantity}", 2f);

            // Fish op6 moves the authoritative reward into the normal package.
            // Refresh /8 now so the next Bag open sees the server-owned item;
            // EndBagUpdate keeps the response data-only while Fish is visible.
            InvokeLuaOrFail(onBagClicked, "Bag.RefreshAfterFishCollect");
        }

        public void SyncFishTime(int remainingSeconds) =>
            services.Fish.ApplyTime(checked((ushort)remainingSeconds));

        public void CompleteFishStop(double gold)
        {
            services.Fish.Stop(checked((uint)gold));
            services.Currencies.Set(CurrencyIds.Gold, checked((long)gold));
        }

        public void ClearFishState()
        {
            pendingFishSlots.Clear();
            services.Fish.Clear();
        }

        private void RequestFishStart() => InvokeLuaOrFail(onFishStart, "Fish.Start");
        private void RequestFishStop() => InvokeLuaOrFail(onFishStop, "Fish.Stop");
        private void RequestFishCollect(ushort slotIndex) =>
            InvokeLuaOrFail(onFishCollect, "Fish.Collect", (double)slotIndex);

        private void ShowFishHelp()
        {
            int openLevel = FunctionUnlockCatalog.Resolve(32).OpenLevel;
            ShowToast($"{openLevel}级开启；每轮消耗100金币；10~20秒随机完成；可提前收网，成功率=已用时/本轮时长；同鱼单格最多999条；鱼篓最多9999格，满后新增鱼直接舍弃。", 6f);
        }

        private void CloseFish()
        {
            if (!fishExitSent)
            {
                fishExitSent = true;
                InvokeLuaOrFail(onFishExit, "Fish.Exit");
            }
            PopFishView();
        }

        private bool TryHandleFishBack()
        {
            if (fishView == null || services?.UiStack.Current != fishView) return false;
            CloseFish();
            return true;
        }

        private void PopFishView()
        {
            if (fishView == null || services?.UiStack.Current != fishView) return;
            bool popped = PopUiStackWithHudRefresh();
            if (!popped) return;
            fishPresenter?.SetModuleVisible(false);
            gameplayView?.SetVisible(true);
            gameplayContentView?.SetVisible(true);
        }

        private void EnsureFishPresenter(FunctionRouteDefinition route)
        {
            if (fishView == null)
            {
                if (!configuredGameplayViews.TryGetValue(route.PrefabKey, out fishView)
                    || fishView?.GameObject == null)
                {
                    fishView = UiPrefabLoader.Load(route.PrefabKey, gameplayView.GameObject.transform);
                    configuredGameplayViews[route.PrefabKey] = fishView;
                }
            }
            if (fishPresenter != null) return;
            OneLevelFrameCoordinator frame = EnsureOneLevelFrame();
            fishPresenter = new FishPresenter(fishView, frame,
                services.Fish, services.Resources,
                services.ShopCatalog, RequestFishStart, RequestFishStop, RequestFishCollect,
                CloseFish, ShowFishHelp);
        }

        public bool IsFishOpen => fishView != null && services?.UiStack.Current == fishView;

        public void BeginFishValidation()
        {
            if (fishValidationRunning) return;
            fishValidationRunning = true;
            StartCoroutine(RunFishValidation());
        }

        private IEnumerator RunFishValidation()
        {
            BeginValidationEvidence();
            if (GetLocalUserId() != 7200057 || GetPlayerRoleId() != 1000003)
            {
                Fail($"Fish fixed identity mismatch: {GetLocalUserId()}/{GetPlayerRoleId()}.");
                yield break;
            }
            RecordValidationSemantic("fish-authoritative-identity", true,
                "Unity persistentDataPath SQLite user=7200057 role=1000003");

            RuntimeInputDispatchResult entry = RuntimeInputDispatcher.Dispatch(
                GameplayPath, "FISH-01-HUD-ENTRY", "click");
            if (!entry.Dispatched)
            {
                Fail("Fish gameplay entry did not receive an EventSystem/raycast click: " + entry.Error);
                yield break;
            }
            MarkValidationControl("FISH-01-HUD-ENTRY");
            float deadline = Time.realtimeSinceStartup + 5f;
            while (!IsGameplayOpen && Time.realtimeSinceStartup < deadline) yield return null;
            if (!IsGameplayOpen)
            {
                Fail("Fish gameplay hub did not open after the real HUD click.");
                yield break;
            }

            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScrollRect gameplayScroll = gameplayPresenter.ScrollControl;
            Graphic gameplayDragSurface = gameplayScroll?.viewport?.GetComponent<Graphic>();
            float scrollBefore = gameplayPresenter.VerticalNormalizedPosition;
            RuntimeInputDispatchResult gameplayDrag = RuntimeInputDispatcher.Dispatch(
                "Layer/Panel/ActivityBg", "FISH-01-GAMEPLAY-SCROLL", "drag");
            yield return new WaitForEndOfFrame();
            float scrollAfter = gameplayPresenter.VerticalNormalizedPosition;
            bool realScrollWorked = gameplayDrag.Dispatched
                && gameplayScroll?.content != null && gameplayScroll.viewport != null
                && gameplayScroll.content.rect.height > gameplayScroll.viewport.rect.height + 1f
                && gameplayDragSurface != null && gameplayDragSurface.raycastTarget
                && scrollAfter < scrollBefore - 0.01f;
            RecordValidationSemantic("fish-gameplay-real-scroll", realScrollWorked,
                $"raycastSurface={gameplayDragSurface != null && gameplayDragSurface.raycastTarget},normalized={scrollBefore:F2}->{scrollAfter:F2},error={gameplayDrag.Error ?? "none"}");
            if (!realScrollWorked)
            {
                Fail("Fish gameplay list did not accept real EventSystem drag input: " + gameplayDrag.Error);
                yield break;
            }
            RuntimeInputDispatchResult fishEntry = RuntimeInputDispatcher.Dispatch(
                "Function_32/EnterBtn", "FISH-01-ENTER", "click");
            if (!fishEntry.Dispatched)
            {
                Fail("Fish function 32 entry did not receive an EventSystem/raycast click: " + fishEntry.Error);
                yield break;
            }
            MarkValidationControl("FISH-01-ENTER");
            deadline = Time.realtimeSinceStartup + 8f;
            while ((!IsFishOpen || !services.Fish.HasAuthoritativeState) && Time.realtimeSinceStartup < deadline)
                yield return null;
            FishStore fish = services.Fish;
            if (!IsFishOpen || !fish.HasAuthoritativeState)
            {
                Fail("Fish /217 join did not produce an authoritative visible state.");
                yield break;
            }
            bool readyContract = fish.SceneId == 54 && fish.MapId == 33
                && fish.PositionX == 1086 && fish.PositionY == 619
                && fish.Direction == 2 && fish.Flip && fish.FishingShapeId == 2000
                && fish.GoldCost == 100 && fish.CycleMinSeconds == 10 && fish.CycleMaxSeconds == 20
                && fish.BasketCapacity == 9999 && fish.StackLimit == 999
                && !fish.IsFishing && fish.Gold == 1000 && fish.OccupiedSlots == 0;
            RecordValidationSemantic("fish-ready-config-and-pose", readyContract,
                $"scene={fish.SceneId},map={fish.MapId},point=({fish.PositionX},{fish.PositionY}),dir={fish.Direction},flip={fish.Flip},shape={fish.FishingShapeId},gold={fish.Gold},slots={fish.OccupiedSlots}");
            if (!readyContract)
            {
                Fail("Fish Ready contract does not match the fixed single-player configuration.");
                yield break;
            }
            MarkValidationControl("FISH-04-FIXED-POSITION");
            yield return CaptureFishFrame("bootstrap-fish-ready.png");

            RuntimeInputDispatchResult help = RuntimeInputDispatcher.Dispatch(
                "DynamicUi_OneLevelLayer/Panel_12/Title/TitleName/Button_1", "FISH-03-HELP", "click");
            if (!help.Dispatched || fish.IsFishing || fish.Gold != 1000)
            {
                Fail("Fish help click changed business state or missed the EventSystem target: " + help.Error);
                yield break;
            }
            MarkValidationControl("FISH-03-HELP");
            RuntimeInputDispatchResult emptyBasket = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/Panel_caozuo/btn_yulan", "FISH-06-BASKET-OPEN", "click");
            if (!emptyBasket.Dispatched || fishPresenter == null || !fishPresenter.IsBasketVisible)
            {
                Fail("Fish basket did not open from a real click: " + emptyBasket.Error);
                yield break;
            }
            MarkValidationControl("FISH-06-BASKET-OPEN");
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            ScrollRect basketScroll = fishPresenter.BasketScroll;
            Graphic basketDragSurface = basketScroll?.viewport?.GetComponent<Graphic>();
            bool basketScrollStructure = basketScroll != null && basketScroll.viewport != null
                && basketScroll.content != null && basketScroll.vertical && !basketScroll.horizontal
                && basketScroll.viewport.GetComponent<RectMask2D>() != null
                && basketDragSurface != null && basketDragSurface.raycastTarget
                && fishPresenter.HasSourceBasketHierarchy && !fishPresenter.IsOuterFrameVisible;
            RecordValidationSemantic("fish-basket-source-list-scroll", basketScrollStructure,
                $"vertical={basketScroll?.vertical},horizontal={basketScroll?.horizontal},raycast={basketDragSurface?.raycastTarget},viewport={basketScroll?.viewport?.rect.height:F0}");
            if (!basketScrollStructure)
            {
                Fail("Fish basket did not reuse FishUI/yulan/ListView as a clipped vertical ScrollRect with a raycast surface.");
                yield break;
            }
            RuntimeInputDispatchResult basketClose = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/yulan/btn_Close", "FISH-09-BASKET-CLOSE", "click");
            if (!basketClose.Dispatched || fishPresenter.IsBasketVisible)
            {
                Fail("Fish basket close did not receive a real click: " + basketClose.Error);
                yield break;
            }
            MarkValidationControl("FISH-09-BASKET-CLOSE");

            RuntimeInputDispatchResult start = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/Panel_caozuo/btn_shouqi", "FISH-05-ROD-TOGGLE", "click");
            if (!start.Dispatched)
            {
                Fail("Fish start did not receive an EventSystem/raycast click: " + start.Error);
                yield break;
            }
            MarkValidationControl("FISH-05-ROD-TOGGLE");
            deadline = Time.realtimeSinceStartup + 5f;
            while (!fish.IsFishing && Time.realtimeSinceStartup < deadline) yield return null;
            double initialRemaining = fish.RemainingSeconds;
            bool startContract = fish.IsFishing && fish.Gold == 900
                && initialRemaining > 8d && initialRemaining <= 20.5d;
            RecordValidationSemantic("fish-start-authoritative-charge-and-duration", startContract,
                $"gold={fish.Gold},remaining={initialRemaining:F2},range=10..20");
            if (!startContract)
            {
                Fail("Fish start did not atomically charge 100 gold and begin a 10-20 second cycle.");
                yield break;
            }
            yield return CaptureFishFrame("bootstrap-fish-fishing.png");

            deadline = Time.realtimeSinceStartup + 24f;
            while (fish.FishCount == 0 && Time.realtimeSinceStartup < deadline) yield return null;
            bool catchContract = fish.FishCount == 1 && fish.OccupiedSlots == 1
                && fish.Slots.Count == 1 && fish.Gold == 800 && fish.IsFishing
                && fishPresenter != null && fishPresenter.IsBasketVisible && fishPresenter.RenderedSlotCount == 1;
            RecordValidationSemantic("fish-weighted-catch-stack-and-auto-continue", catchContract,
                $"fish={fish.FishCount},slots={fish.OccupiedSlots},gold={fish.Gold},fishing={fish.IsFishing},rendered={fishPresenter?.RenderedSlotCount ?? -1}");
            if (!catchContract)
            {
                Fail("Fish first catch did not persist one stacked slot and charge the next auto-continue cycle.");
                yield break;
            }
            MarkValidationControl("FISH-07-BASKET-SLOT");

            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            if (!fishPresenter.HasRenderableBasketQuantities)
            {
                Fail("Fish basket quantity labels have a zero-sized RectTransform.");
                yield break;
            }
            ushort firstSlot = 0xffff;
            foreach (FishBasketSlot slot in fish.Slots) { firstSlot = slot.SlotIndex; break; }
            RuntimeInputDispatchResult select = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/yulan/ListView/RuntimeFishBasketContent/Row_1/RuntimeHitArea",
                "FISH-07-BASKET-SLOT", "click");
            if (!select.Dispatched)
            {
                Fail("Fish basket slot did not receive an EventSystem/raycast click: " + select.Error);
                yield break;
            }
            RuntimeInputDispatchResult collect = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/yulan/btn_shouhuo", "FISH-08-BASKET-COLLECT", "click");
            if (!collect.Dispatched)
            {
                Fail("Fish collect button did not receive an EventSystem/raycast click: " + collect.Error);
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 5f;
            while (fish.FishCount != 0 && Time.realtimeSinceStartup < deadline) yield return null;
            if (fish.FishCount != 0 || fish.OccupiedSlots != 0)
            {
                Fail("Fish collected slot was not removed from the authoritative basket.");
                yield break;
            }
            MarkValidationControl("FISH-08-BASKET-COLLECT");
            RecordValidationSemantic("fish-collect-whole-stack", true,
                $"slot={firstSlot} removed through /217 op6 after a real cell click");

            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            basketClose = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/yulan/btn_Close", "FISH-09-BASKET-CLOSE", "click");
            if (!basketClose.Dispatched || fishPresenter.IsBasketVisible)
            {
                Fail("Fish basket did not close after collecting the first catch: " + basketClose.Error);
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 24f;
            while (fish.FishCount == 0 && Time.realtimeSinceStartup < deadline) yield return null;
            bool secondCatchContract = fish.FishCount == 1 && fish.OccupiedSlots == 1
                && fish.Gold == 700 && fish.IsFishing && fishPresenter.IsBasketVisible;
            RecordValidationSemantic("fish-second-cycle-independent-duration-and-persistence", secondCatchContract,
                $"fish={fish.FishCount},slots={fish.OccupiedSlots},gold={fish.Gold},remaining={fish.RemainingSeconds:F2}");
            if (!secondCatchContract)
            {
                Fail("Fish second cycle did not preserve one catch and charge the next cycle.");
                yield break;
            }

            RuntimeInputDispatchResult stop = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/Panel_caozuo/btn_shouqi", "FISH-05-ROD-TOGGLE", "click");
            if (!stop.Dispatched)
            {
                Fail("Fish stop did not receive an EventSystem/raycast click: " + stop.Error);
                yield break;
            }
            deadline = Time.realtimeSinceStartup + 5f;
            while (fish.IsFishing && Time.realtimeSinceStartup < deadline) yield return null;
            bool stopContract = !fish.IsFishing && fish.Gold == 700 && fish.FishCount == 1;
            RecordValidationSemantic("fish-stop-keeps-ready-pose-and-basket", stopContract,
                $"fishing={fish.IsFishing},gold={fish.Gold},fish={fish.FishCount}");
            if (!stopContract)
            {
                Fail("Fish stop did not return to Ready without changing the persisted catch.");
                yield break;
            }
            yield return CaptureFishFrame("bootstrap-fish-basket.png");

            RuntimeInputDispatchResult finalBasketClose = RuntimeInputDispatcher.Dispatch(
                "Layer/FishUI/yulan/btn_Close", "FISH-09-BASKET-CLOSE", "click");
            if (!finalBasketClose.Dispatched || fishPresenter.IsBasketVisible)
            {
                Fail("Fish basket did not close before module exit: " + finalBasketClose.Error);
                yield break;
            }
            yield return new WaitForEndOfFrame();

            RuntimeInputDispatchResult close = RuntimeInputDispatcher.Dispatch(
                "DynamicUi_OneLevelLayer/Panel_12/Title/CloseBtn", "FISH-02-EXIT", "click");
            if (!close.Dispatched)
            {
                Fail("Fish exit did not receive an EventSystem/raycast click: " + close.Error);
                yield break;
            }
            MarkValidationControl("FISH-02-EXIT");
            deadline = Time.realtimeSinceStartup + 3f;
            while (IsFishOpen && Time.realtimeSinceStartup < deadline) yield return null;
            bool sharedFrameReleased = oneLevelFrameCoordinator?.Mode == OneLevelFrameMode.Hidden
                && oneLevelFrameView?.GameObject.activeSelf == false
                && gameplayView?.GameObject.transform.parent != oneLevelFrameView?.GameObject.transform;
            if (IsFishOpen || !sharedFrameReleased)
            {
                Fail("Fish exit did not release the shared OneLevelLayer or restore the gameplay hub.");
                yield break;
            }
            RecordValidationSemantic("fish-exit-restores-normal-ui", true,
                "Fish view popped; shared OneLevelLayer is hidden and the gameplay frame remains outside it");
            Complete("COMPLETE: Fish 10/10 controls real-input /217 cycle passed; ready=54/33/1086/619/dir2/shape2000, gold=1000->900->800->700, collect=1, persistedCatch=1, stopped and exited");
        }

        private IEnumerator CaptureFishFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string directory = Path.Combine(repositoryRoot, "build", "ui-migration");
            Directory.CreateDirectory(directory);
            string path = Path.Combine(directory, fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 3f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0)
                && Time.realtimeSinceStartup < deadline) yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                Fail("Fish screenshot was not written: " + fileName);
        }
    }
}
