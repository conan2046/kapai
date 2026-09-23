using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Core

{
    public sealed partial class ProjectXApp
    {
        public void BeginBagUpdate(int expectedCount)
        {
            pendingBagItems.Clear();
            if (expectedCount > pendingBagItems.Capacity) pendingBagItems.Capacity = expectedCount;
        }

        public void AddBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType, string itemFrom, string choices, string sources)
        {
            pendingBagItems.Add(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority, itemType, itemFrom, choices, sources));
        }

        public void EndBagUpdate()
        {
            services.Bag.Replace(pendingBagItems);
            if (services.Options.HeroCultivationG3Validation
                && heroCultivationView?.GameObject.activeSelf == true)
            {
                CompleteHeroCultivationG3Validation();
                return;
            }
            // /8 is also an authoritative background source for Draw tickets and
            // Hero cultivation materials. A delayed response must update the
            // store without navigating either active business screen to the
            // ordinary item bag.
            if (IsDrawOpen || IsHeroOpen || IsHeroEquipmentSurfaceVisible || heroEquipmentOpenPending
                || IsFishOpen) return;
            // Jingjie's 背包 tab requests /8 for its own embedded bag surface.
            // The store was already replaced above; do NOT let the response run
            // ConfigureBagFrame(), which would retitle the shared frame to
            // 道具背包 and disable the 境界 tab, hijacking the Jingjie surface.
            //
            // But we must still REPAINT. ShowJingJieBag() runs when the tab is
            // clicked — before this response arrives — so its own Render() paints
            // the still-empty store. Returning here without rendering left the
            // embedded bag permanently blank even though the data had arrived
            // (the reported "从头像打开背包没有数据").
            if (IsJingJieBagSurfaceActive)
            {
                EnsureBagPresenter();
                bagPresenter?.Render();
                return;
            }
            EnsureBagPresenter();
            if (!bagInitialSelectionApplied)
            {
                bagPresenter.ResetSelection();
                bagInitialSelectionApplied = true;
            }
            // Imported Prefabs can retain their serialized active state from the
            // last editor build. A real Bag entry must explicitly isolate itself
            // from every Hero surface before becoming the UiStack top.
            heroListView?.SetVisible(false);
            heroDetailView?.SetVisible(false);
            heroBagView?.SetVisible(false);
            heroBookView?.SetVisible(false);
            heroRecycleView?.SetVisible(false);
            heroReplacementView?.SetVisible(false);
            HideHeroCultivationForNavigation();
            heroEnhanceMasterView?.SetVisible(false);
            heroAttributesView?.SetVisible(false);
            heroItemSourceView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(false);
            heroEquipmentDetailView?.SetVisible(false);
            heroEquipmentChangeView?.SetVisible(false);
            heroEquipmentCultivateView?.SetVisible(false);
            heroEquipmentStrengthView?.SetVisible(false);
            heroEquipmentFragmentView?.SetVisible(false);
            gameplayContentView?.SetVisible(false);
            gameplayDetailView?.SetVisible(false);
            // Main HUD Bag and the player-hub Bag tab share the same frame and
            // four-tab contract. The response already populated the Store, so
            // enter the shared surface without issuing a second /8 request.
            ShowJingJieBag(false);
            if (pendingBagSelectionItemId > 0)
            {
                int itemId = pendingBagSelectionItemId;
                pendingBagSelectionItemId = 0;
                if (!bagPresenter.SelectItem(itemId))
                {
                    ShowToast("背包中没有搜宝令（道具 402）", 3f);
                    SetStatus("XunBao search token item 402 is not available in the authoritative bag.");
                }
                else ShowToast("已定位搜宝令，请点击使用补充搜索次数", 3f);
            }
            WriteBagGraphicCensusOnce();
            SetStatus($"Bag UI active: {bagPresenter.ItemCount} item stacks, {bagPresenter.MissingIconCount} missing icons.");
        }

        private void WriteBagGraphicCensusOnce()
        {
            if (bagGraphicCensusWritten
                || (!HasCommandLineFlag("-projectXBagG3Validation")
                    && !HasCommandLineFlag("-projectXBagG4Validation"))) return;
            bagGraphicCensusWritten = true;
            Canvas.ForceUpdateCanvases();

            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string path = Path.Combine(repositoryRoot, ".local", "unity-validation", "bag-runtime-graphic-census-latest.json");
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            Canvas canvas = FindObjectOfType<Canvas>();
            Graphic[] graphics = canvas == null
                ? Array.Empty<Graphic>()
                : canvas.GetComponentsInChildren<Graphic>(true);
            var entries = graphics.Select(graphic =>
            {
                RectTransform rect = graphic.rectTransform;
                var corners = new Vector3[4];
                rect.GetWorldCorners(corners);
                float inheritedAlpha = 1f;
                for (Transform current = graphic.transform; current != null; current = current.parent)
                {
                    CanvasGroup group = current.GetComponent<CanvasGroup>();
                    if (group != null) inheritedAlpha *= group.alpha;
                }
                Image image = graphic as Image;
                Text text = graphic as Text;
                Sprite sprite = image == null ? null : image.sprite;
                Font font = text == null ? null : text.font;
                Material material = graphic.material;
                return new
                {
                    path = GetTransformPath(graphic.transform, canvas?.transform),
                    type = graphic.GetType().Name,
                    activeSelf = graphic.gameObject.activeSelf,
                    activeInHierarchy = graphic.gameObject.activeInHierarchy,
                    enabled = graphic.enabled,
                    colorAlpha = graphic.color.a,
                    inheritedCanvasAlpha = inheritedAlpha,
                    canvasRendererCull = graphic.canvasRenderer.cull,
                    canvasRendererAlpha = graphic.canvasRenderer.GetAlpha(),
                    siblingIndex = graphic.transform.GetSiblingIndex(),
                    screenMin = new[] { corners[0].x, corners[0].y },
                    screenMax = new[] { corners[2].x, corners[2].y },
                    spriteMissingReference = !ReferenceEquals(sprite, null) && sprite == null,
                    sprite = sprite == null ? string.Empty : sprite.name,
                    texture = sprite == null || sprite.texture == null ? string.Empty : sprite.texture.name,
                    fontMissingReference = !ReferenceEquals(font, null) && font == null,
                    font = font == null ? string.Empty : font.name,
                    text = text?.text ?? string.Empty,
                    materialMissingReference = !ReferenceEquals(material, null) && material == null,
                    material = material == null ? string.Empty : material.name,
                    shader = material == null || material.shader == null ? string.Empty : material.shader.name,
                };
            }).ToArray();
            var roots = canvas == null
                ? Array.Empty<object>()
                : canvas.transform.Cast<Transform>().Select(root => (object)new
                {
                    name = root.name,
                    activeSelf = root.gameObject.activeSelf,
                    activeInHierarchy = root.gameObject.activeInHierarchy,
                    siblingIndex = root.GetSiblingIndex(),
                    graphicCount = root.GetComponentsInChildren<Graphic>(true).Length,
                    activeGraphicCount = root.GetComponentsInChildren<Graphic>(false).Length,
                }).ToArray();
            File.WriteAllText(path, JsonConvert.SerializeObject(new
            {
                schemaVersion = 1,
                screenWidth = Screen.width,
                screenHeight = Screen.height,
                canvasRenderMode = canvas?.renderMode.ToString() ?? string.Empty,
                canvasSortingOrder = canvas?.sortingOrder ?? 0,
                roots,
                graphics = entries,
                utc = DateTime.UtcNow.ToString("O"),
            }, Formatting.Indented));
            ProjectX.Diagnostics.ClientLog.Verbose($"[BagG5] Runtime graphic census written: {path}; graphics={entries.Length}.");
        }

        private static string GetTransformPath(Transform target, Transform stop)
        {
            var names = new Stack<string>();
            for (Transform current = target; current != null && current != stop; current = current.parent)
                names.Push(current.name);
            return string.Join("/", names);
        }

        // HappyDrawUI needs the authoritative recruitment-ticket counts from /8,
        // but that refresh must not steal the UI stack from the recruitment screen.
        public void BeginBagHeaderUpdate(int expectedCount)
        {
            pendingBagItems.Clear();
        }

        public void EndBagHeaderUpdate()
        {
            services.Bag.Replace(pendingBagItems);
        }

        public void UpsertBagItem(int slot, int itemId, int quantity, string itemName, string description,
            int picture, int quality, int useType, int useJump, int sortPriority,
            int itemType, string itemFrom, string choices, string sources)
        {
            services.Bag.Upsert(new BagItemRecord(slot, itemId, quantity, itemName, description,
                picture, quality, useType, useJump, sortPriority, itemType, itemFrom, choices, sources));
        }

        public void RemoveBagItem(int slot) => services.Bag.Remove(slot);
        public int GetBagCount() => services.Bag.Count;
        public int GetBagQuantity(int slot) => services.Bag.GetQuantity(slot);
        public int GetBagItemId(int slot) => services.Bag.TryGet(slot, out BagItemRecord item) ? item.ItemId : 0;

        public void QueueBagUseReward(int itemId, int amount, string itemName, int picture, int quality, int itemType)
        {
            if (!capturingBagUseRewards || Time.realtimeSinceStartup > bagUseRewardCaptureUntil)
            {
                capturingBagUseRewards = false;
                bagUseRewardFilterItemId = 0;
                pendingBagUseRewards.Clear();
                return;
            }
            if (amount <= 0 || itemId <= 0) return;
            if (bagUseRewardFilterItemId > 0 && itemId != bagUseRewardFilterItemId) return;
            uint added = checked((uint)amount);
            if (pendingBagUseRewards.TryGetValue(itemId, out RewardRecord current))
                added = checked(current.Amount + added);
            pendingBagUseRewards[itemId] = new RewardRecord(itemType, checked((uint)itemId), added,
                itemName, picture, quality);
            lastBagUseRewardAt = Time.realtimeSinceStartup;
            if (bagUseRewardRoutine == null)
                bagUseRewardRoutine = StartCoroutine(ShowBagUseRewardsWhenStable());
        }

        private bool IsHeroEquipmentSubpageVisible =>
            heroEquipmentChangeView?.GameObject.activeSelf == true
            || heroEquipmentFragmentView?.GameObject.activeSelf == true
            || heroEquipmentCultivateView?.GameObject.activeSelf == true
            || heroEquipmentStrengthView?.GameObject.activeSelf == true
            || heroEquipmentRefineView?.GameObject.activeSelf == true
            || heroEquipmentAwakenView?.GameObject.activeSelf == true
            || heroEquipmentDivineView?.GameObject.activeSelf == true
            || heroEquipmentAutoRefineView?.GameObject.activeSelf == true
            || heroEquipmentExchangeView?.GameObject.activeSelf == true
            || heroEquipmentAutoStarView?.GameObject.activeSelf == true
            || heroEquipmentAutoDivineView?.GameObject.activeSelf == true
            || heroEquipmentDivineEffectView?.GameObject.activeSelf == true;

        private void RestoreHeroEquipmentBagView()
        {
            EnsureHeroEquipmentPresenter();
            heroEquipmentPresenter.HideDetails();
            heroEquipmentFragmentView?.SetVisible(false);
            heroEquipmentListView?.SetVisible(true);
            SetOneLevelFrameVisible(true);
            ConfigureHeroEquipmentFrame(HeroEquipmentKind.Equipment);
            oneLevelFrameView?.GameObject.transform.SetAsLastSibling();
            heroEquipmentListView?.GameObject.transform.SetAsLastSibling();
        }

        private void BeginBagUseRewardCapture(BagItemRecord item)
        {
            if (bagUseRewardRoutine != null)
            {
                StopCoroutine(bagUseRewardRoutine);
                bagUseRewardRoutine = null;
            }
            pendingBagUseRewards.Clear();
            // Both random equipment boxes (type 5) and selectable gift boxes
            // (type 6) produce authoritative /15 additions that need visible
            // post-open feedback. Other direct-use items keep their existing
            // lightweight update behavior.
            capturingBagUseRewards = item.ItemType == 5 || item.ItemType == 6;
            // A selectable gift has one authoritative selected reward. Restrict
            // its feedback to that item so unrelated concurrent positive /15
            // updates cannot pollute the visible reward popup.
            bagUseRewardFilterItemId = item.ItemType == 6
                ? bagFlowPresenter?.SelectedChoiceId ?? 0
                : 0;
            lastBagUseRewardAt = Time.realtimeSinceStartup;
            bagUseRewardCaptureUntil = lastBagUseRewardAt + 8.5f;
        }

        private IEnumerator ShowBagUseRewardsWhenStable()
        {
            while (capturingBagUseRewards && Time.realtimeSinceStartup - lastBagUseRewardAt < 0.2f)
                yield return null;
            bagUseRewardRoutine = null;
            if (!capturingBagUseRewards || pendingBagUseRewards.Count == 0) yield break;
            RewardRecord[] rewards = pendingBagUseRewards.Values.OrderBy(value => value.Id).ToArray();
            pendingBagUseRewards.Clear();
            capturingBagUseRewards = false;
            bagUseRewardFilterItemId = 0;
            services.Rewards.Replace("开启获得", rewards);
            EnsureRewardPresenter();
            rewardPresenter.SetItemClickHandler(reward =>
            {
                EnsureErrorPresenter();
                errorPresenter.Show("奖励详情", $"{reward.Name}\n数量：{reward.Amount}");
            });
            rewardPresenter.Show();
            SetStatus($"Bag box rewards shown: {rewards.Length} types.");
        }
        public bool IsBagInputOpen => bagFlowPresenter?.IsInputOpen == true;
        public bool IsBagGiftOpen => bagFlowPresenter?.IsGiftOpen == true;
        public bool IsBagSourceOpen => bagFlowPresenter?.IsSourceOpen == true;
        public bool IsBagEquipmentInfoOpen => bagFlowPresenter?.IsEquipmentInfoOpen == true;
        public int BagModalQuantity => bagFlowPresenter?.Quantity ?? 0;
        public string BagModalDisplayText => bagFlowPresenter?.InputDisplayText ?? string.Empty;
        public int BagChoiceCount => bagFlowPresenter?.ChoiceCount ?? 0;
        public bool BagHasChoice => bagFlowPresenter?.HasSelection == true;
        public bool SelectBagItem(int itemId)
        {
            bool invoked = bagPresenter?.SelectItem(itemId) == true;
            if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl("BAG-04-LIST-ITEM");
            return invoked;
        }

        public bool InvokeBagControl(string controlId)
        {
            bool invoked = bagPresenter?.InvokeControl(controlId) == true
                || bagFlowPresenter?.InvokeControl(controlId) == true;
            if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl(controlId);
            return invoked;
        }

        private bool InvokeBagInputDigit(int digit)
        {
            bool invoked = bagFlowPresenter?.InvokeInputDigit(digit) == true;
            if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))
                MarkValidationControl("BAG-08-INPUT-DIGITS");
            return invoked;
        }
        public bool ValidateBagStatic(out string detail)
        {
            EnsureBagPresenter();
            bool bagOk = bagPresenter.Validate(out string bagDetail);
            bool flowOk = bagFlowPresenter.Validate(out string flowDetail);
            detail = bagDetail + " | " + flowDetail;
            return bagOk && flowOk;
        }
        public void CompleteBagG3Validation()
        {
            if (!ValidateBagStatic(out string detail))
            {
                Fail("Bag G3 static validation failed: " + detail);
                return;
            }
            Complete("COMPLETE: Bag G3 real Prefabs + 26-control bindings + scroll/modal lifecycle | " + detail);
        }

        public void BeginBagG4Validation()
        {
            StartCoroutine(BeginBagG4ValidationRoutine());
        }

        private IEnumerator BeginBagG4ValidationRoutine()
        {
            bagG4DirectUseScheduled = false;
            validationRoleIdSnapshot = GetPlayerRoleId();
            bool staticValid = ValidateBagStatic(out string detail);
            if (GetLocalUserId() != 1 || validationRoleIdSnapshot != 1000001
                || !IsBagOpen || services.Bag.Count < 20 || !staticValid)
            {
                Fail($"Bag G4 fixture/static mismatch: user={GetLocalUserId()}, open={IsBagOpen}, "
                    + $"count={services.Bag.Count}, detail={detail}.");
                yield break;
            }
            bagG4InitialBatchQuantity = GetBagQuantityByItemId(500);
            bagG4InitialGiftQuantity = GetBagQuantityByItemId(1111);
            bagG4InitialDirectQuantity = GetBagQuantityByItemId(3201);
            bagG4InitialRewardQuantity = GetBagQuantityByItemId(4621);
            bagG4InitialBoxQuantities.Clear();
            foreach (int boxItemId in new[] { 512, 513, 514 })
                bagG4InitialBoxQuantities[boxItemId] = GetBagQuantityByItemId(boxItemId);
            bagG4ExpectedFragmentQuantities.Clear();
            for (int fragmentId = 4621; fragmentId <= 4644; fragmentId++)
                bagG4ExpectedFragmentQuantities[fragmentId] = GetBagQuantityByItemId(fragmentId);
            if (bagG4InitialBatchQuantity < 20 || bagG4InitialGiftQuantity != 3)
            {
                Fail($"Bag G4 fixture lacks batch/gift items: 500={bagG4InitialBatchQuantity}, "
                    + $"1111={bagG4InitialGiftQuantity}.");
                yield break;
            }
            if (bagG4InitialBoxQuantities.Any(pair => pair.Value < 2))
            {
                Fail("Bag G4 fixture lacks random equipment boxes: "
                    + string.Join(",", bagG4InitialBoxQuantities.Select(pair => $"{pair.Key}={pair.Value}")));
                yield break;
            }

            RecordValidationSemantic("bag-current-main-entry", true,
                $"real btn_Bag opened current Bag stack for role={validationRoleIdSnapshot}");
            int visibleBatchStacks = services.Bag.Items.Count(item => item.ItemId == 500);
            bool aggregated = visibleBatchStacks == 1
                && services.Bag.Items.First(item => item.ItemId == 500).Quantity == bagG4InitialBatchQuantity;
            RecordValidationSemantic("bag-duplicate-slot-aggregation", aggregated,
                $"item500 visibleStacks={visibleBatchStacks} total={bagG4InitialBatchQuantity}");
            if (!aggregated) { Fail("Bag G4 duplicate-slot aggregation was not preserved."); yield break; }

            if (!SelectBagItem(500))
            { Fail("Bag G4 entry fixture could not select the Cocos baseline item 500."); yield break; }
            if (!bagInitialG5DisconnectCaptured)
            {
                yield return WaitForBagTransientOverlayToSettle("BAG-01-ENTRY");
                if (CurrentAppState == AppState.Failed) yield break;
                yield return CaptureBagG5Evidence("BAG-01-ENTRY");
                bagInitialG5DisconnectCaptured = true;
                if (!InvokeBagControl("BAG-02-CLOSE") || IsBagOpen)
                { Fail("Bag G5 initial reenter setup could not close Bag."); yield break; }
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button initialReenter = mainView?.Binding.Find(BagPath)?.GetComponent<Button>();
                if (initialReenter == null)
                { Fail("Bag G5 initial reenter setup could not find the real main entry."); yield break; }
                bagInitialG5ReenterRequested = true;
                initialReenter.onClick.Invoke();
                yield break;
            }
            if (bagInitialG5ReenterRequested && !bagInitialG5ReenterCaptured)
            {
                bagInitialG5ReenterCaptured = true;
                yield return CaptureBagG5Evidence("BAG-01-REENTER");
            }
            if (!InvokeBagControl("BAG-03-TAB")) { Fail("Bag G4 tab binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-03-TAB");
            if (!SelectBagItem(500)) { Fail("Bag G4 could not select batch item 500."); yield break; }
            yield return CaptureBagG5Evidence("BAG-04-LIST-ITEM");
            if (!SelectBagItem(1001)) { Fail("Bag G5 scrolled state could not select the frozen high recruit ticket 1001."); yield break; }
            if (!InvokeBagControl("BAG-05-LIST-SCROLL")) { Fail("Bag G4 list scroll failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-05-LIST-SCROLL");
            if (!InvokeBagControl("BAG-06-DETAIL-ICON")) { Fail("Bag G4 detail icon binding failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-06-DETAIL-ICON");
            RecordValidationSemantic("bag-selection-scroll-refresh", true,
                "real item selection, selected-tab callback, list scroll and detail-icon callback completed without authority mutation");

            if (!SelectBagItem(500))
            { Fail("Bag G4 could not restore batch item 500 after the frozen scrolled-state capture."); yield break; }
            if (!InvokeBagControl("BAG-07-USE") || !IsBagInputOpen)
            { Fail("Bag G4 batch item did not open EnterNumLayer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-07-USE-BATCH");
            if (!InvokeBagControl("BAG-08-INPUT-DIGITS") || BagModalQuantity != 10 || BagModalDisplayText != "10")
            { Fail($"Bag G4 input digits did not render quantity=10: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            yield return CaptureBagG5Evidence("BAG-08-INPUT-DIGITS");
            InvokeBagControl("BAG-09-INPUT-DELETE");
            if (BagModalQuantity != 1 || BagModalDisplayText != "1")
            { Fail($"Bag G4 input delete did not render 10 -> 1: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            yield return CaptureBagG5Evidence("BAG-09-INPUT-DELETE");
            InvokeBagControl("BAG-09-INPUT-DELETE");
            if (BagModalQuantity != 0 || BagModalDisplayText != "请输入数量")
            { Fail($"Bag G4 second input delete did not clear display: internal={BagModalQuantity}, display='{BagModalDisplayText}'."); yield break; }
            InvokeBagControl("BAG-10-INPUT-CONFIRM");
            if (IsBagInputOpen || GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity)
            { Fail("Bag G4 zero confirmation changed authoritative state."); yield break; }
            yield return CaptureBagG5Evidence("BAG-10-INPUT-ZERO");

            SelectBagItem(500);
            InvokeBagControl("BAG-07-USE");
            InvokeBagControl("BAG-11-INPUT-CLOSE");
            if (IsBagInputOpen) { Fail("Bag G4 input close did not close the modal."); yield break; }
            yield return CaptureBagG5Evidence("BAG-11-INPUT-CLOSE");

            SelectBagItem(500);
            InvokeBagControl("BAG-07-USE");
            if (!InvokeBagControl("BAG-08-INPUT-DIGITS") || BagModalQuantity != 10)
            { Fail($"Bag G4 batch quantity setup failed: actual={BagModalQuantity}."); yield break; }
            InvokeBagControl("BAG-10-INPUT-CONFIRM");
        }

        public void ContinueBagG4AfterBatchUse()
        {
            StartCoroutine(ContinueBagG4AfterBatchUseRoutine());
        }

        private IEnumerator ContinueBagG4AfterBatchUseRoutine()
        {
            if (GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 10 || !IsBagOpen)
            {
                Fail($"Bag G4 batch consume mismatch: item500={GetBagQuantityByItemId(500)}/"
                    + $"{bagG4InitialBatchQuantity - 10}, open={IsBagOpen}.");
                yield break;
            }
            RecordValidationSemantic("bag-authoritative-full-and-incremental", true,
                $"real /8 total={bagG4InitialBatchQuantity}; /15 reduced aggregate to {GetBagQuantityByItemId(500)}");
            RecordValidationSemantic("bag-batch-use-bounds", true,
                "0-9 callbacks reached; entered 10, deleted to 1 then 0, zero-confirm was inert, authoritative batch consumed exactly 10");
            yield return CaptureBagG5Evidence("BAG-10-BATCH-SUCCESS");

            foreach (int ticketItemId in new[] { 1000, 1001 })
            {
                int initialTicketQuantity = GetBagQuantityByItemId(ticketItemId);
                if (!SelectBagItem(ticketItemId) || !InvokeBagControl("BAG-07-USE") || !IsDrawOpen)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} did not open Draw through use_jump=1010.");
                    yield break;
                }
                if (!HandleBack() || IsBagOpen || IsDrawOpen)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} left Bag in the navigation stack after Draw closed.");
                    yield break;
                }
                if (GetBagQuantityByItemId(ticketItemId) != initialTicketQuantity)
                {
                    Fail($"Bag G4 recruit-ticket item {ticketItemId} changed quantity on a pure use_jump route.");
                    yield break;
                }
                // BAG-01 and the initial /8 already prove the real entry and
                // authoritative store. Reuse that snapshot between the two ticket
                // cases; issuing another /8 in automation would restart the whole
                // Bag G4 state machine after its mandatory sort response.
                if (!ReopenBagForRecruitRouteValidation())
                {
                    Fail("Bag G4 recruit-ticket route could not restore Bag from the loaded snapshot.");
                    yield break;
                }
            }
            RecordValidationSemantic("bag-use-jump-closes-origin", true,
                "item1000 and item1001 opened current HappyDraw/1010 without consumption; one Draw Back returned to main instead of reopening Bag");

            if (!SelectBagItem(1111) || !InvokeBagControl("BAG-07-USE") || !IsBagGiftOpen)
            { Fail("Bag G4 gift item did not open OpenBox_1Layer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-12-GIFT-OPEN");
            InvokeBagControl("BAG-18-GIFT-CONFIRM");
            if (!IsBagGiftOpen || GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity)
            { Fail("Bag G4 no-selection gift confirmation mutated or closed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-18-GIFT-NO-SELECTION");
            InvokeBagControl("BAG-19-GIFT-CLOSE");
            if (IsBagGiftOpen) { Fail("Bag G4 gift close failed."); yield break; }
            yield return CaptureBagG5Evidence("BAG-19-GIFT-CLOSE");

            SelectBagItem(1111);
            InvokeBagControl("BAG-07-USE");
            InvokeBagControl("BAG-12-GIFT-OPTION");
            if (!BagHasChoice) { Fail("Bag G4 gift choice did not select."); yield break; }
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");
            yield return CaptureBagG5Evidence("BAG-12-GIFT-OPTION");
            InvokeBagControl("BAG-14-GIFT-SUB-ONE");
            ScrollRect giftScroll = bagGiftView?.Binding.Find(
                "Layer/OpenBox/Panel/Bg/ListView")?.GetComponent<ScrollRect>();
            Canvas.ForceUpdateCanvases();
            if (giftScroll?.content == null || giftScroll.viewport == null
                || giftScroll.content.rect.width <= giftScroll.viewport.rect.width + 1f)
            {
                Fail("Bag G4 gift list did not create horizontal overflow for all eight choices.");
                yield break;
            }
            Graphic giftDragSurface = giftScroll.viewport.GetComponent<Graphic>();
            if (giftDragSurface == null || !giftDragSurface.raycastTarget)
            {
                Fail("Bag G4 gift viewport has no raycast surface for real pointer dragging.");
                yield break;
            }
            float giftScrollStartX = giftScroll.content.anchoredPosition.x;
            if (!InvokeEventSystemHorizontalDrag(giftScroll))
            {
                Fail("Bag G4 gift list did not accept real EventSystem horizontal drag input.");
                yield break;
            }
            yield return null;
            Canvas.ForceUpdateCanvases();
            if (Mathf.Abs(giftScroll.content.anchoredPosition.x - giftScrollStartX) < 1f)
            {
                Fail("Bag G4 gift list accepted callbacks but did not move horizontally.");
                yield break;
            }
            if (!InvokeBagControl("BAG-13-GIFT-SCROLL"))
            {
                Fail("Bag G4 gift list could not reach the final choices after real dragging.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-13-GIFT-SCROLL");
            bagFlowPresenter.ResetGiftScroll();
            InvokeBagControl("BAG-15-GIFT-ADD-ONE");
            yield return CaptureBagG5Evidence("BAG-15-GIFT-ADD-ONE");
            InvokeBagControl("BAG-14-GIFT-SUB-ONE");
            yield return CaptureBagG5Evidence("BAG-14-GIFT-SUB-ONE");
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");
            yield return CaptureBagG5Evidence("BAG-17-GIFT-ADD-TEN");
            InvokeBagControl("BAG-16-GIFT-SUB-TEN");
            yield return CaptureBagG5Evidence("BAG-16-GIFT-SUB-TEN");
            InvokeBagControl("BAG-17-GIFT-ADD-TEN");

            if (!InvokeBagControl("BAG-20-GIFT-REWARD-DETAIL") || !IsBagSourceOpen)
            { Fail("Bag G4 gift reward detail did not open source UI."); yield break; }
            yield return CaptureBagG5Evidence("BAG-20-GIFT-REWARD-DETAIL");
            InvokeBagControl("BAG-23-SOURCE-SCROLL");
            yield return CaptureBagG5Evidence("BAG-23-SOURCE-SCROLL");
            InvokeBagControl("BAG-21-SOURCE-CLOSE");
            if (!IsBagGiftOpen || IsBagSourceOpen)
            { Fail("Bag G4 source close did not return to gift."); yield break; }
            yield return CaptureBagG5Evidence("BAG-21-SOURCE-CLOSE");

            InvokeBagControl("BAG-19-GIFT-CLOSE");
            if (!SelectBagItem(1111)
                || !InvokeBagControl("BAG-07-USE") || !IsBagGiftOpen
                || !InvokeBagControl("BAG-12-GIFT-OPTION")
                || bagFlowPresenter?.SelectedChoiceId != 4621
                || !InvokeBagControl("BAG-20-GIFT-REWARD-DETAIL")
                || !IsBagSourceOpen || bagFlowPresenter.SourceChoiceId != 4621)
            { Fail("Bag G4 equipment-fragment source did not preserve frozen gift1111 choice0 fragment4621."); yield break; }
            yield return CaptureBagG5Evidence("BAG-20-EQUIPMENT-SOURCE");
            if (!InvokeBagControl("BAG-22-SOURCE-ICON") || !IsBagEquipmentInfoOpen
                || bagFlowPresenter.SourceChoiceId != 4621)
            { Fail("Bag G4 source icon did not open equipment info for frozen fragment4621."); yield break; }
            yield return CaptureBagG5Evidence("BAG-22-SOURCE-ICON");
            InvokeBagControl("BAG-26-EQUIP-INFO-SCROLL");
            yield return CaptureBagG5Evidence("BAG-26-EQUIP-INFO-SCROLL");
            InvokeBagControl("BAG-25-EQUIP-INFO-CLOSE");
            if (!IsBagSourceOpen || IsBagEquipmentInfoOpen)
            { Fail("Bag G4 equipment info close did not return one layer."); yield break; }
            yield return CaptureBagG5Evidence("BAG-25-EQUIP-INFO-CLOSE");
            if (!InvokeBagControl("BAG-24-SOURCE-ACTION"))
            { Fail("Bag G4 source action did not invoke its target."); yield break; }
            float sourceDeadline = Time.realtimeSinceStartup + 8f;
            while ((!IsGameplayShopOpen || GameplayShopRenderedCount <= 0)
                && Time.realtimeSinceStartup < sourceDeadline) yield return null;
            if (!IsGameplayShopOpen || GameplayShopRenderedCount <= 0)
            { Fail("Bag G4 source action did not open populated migrated GameplayShops destination."); yield break; }
            if (oneLevelFrameView.GameObject.activeSelf || bagView.GameObject.activeSelf
                || bagSourceView.GameObject.activeSelf || bagEquipmentInfoView.GameObject.activeSelf
                || !bagPopupFrameView.GameObject.activeSelf)
            {
                Fail("Bag G4 source action retained a Bag surface behind GameplayShops or omitted its shop frame.");
                yield break;
            }
            yield return CaptureBagG5Evidence("BAG-24-SOURCE-ACTION");
            HandleBack();
            yield return null;
            if (!IsBagOpen || IsBagSourceOpen || IsGameplayShopOpen
                || !oneLevelFrameView.GameObject.activeSelf || bagPopupFrameView.GameObject.activeSelf)
            { Fail("Bag G4 source action did not return from GameplayShops to Bag cleanly."); yield break; }

            RecordValidationSemantic("bag-source-route-boundary", true,
                "functionId=17 hid every Bag surface, opened framed GameplayShops, and back restored the framed Bag");
            RecordValidationSemantic("bag-disabled-excluded-target", !CanOpenBagSource(2125),
                "excluded functionId=2125 is rejected by the shared Bag route availability policy");

            SelectBagItem(1111);
            InvokeBagControl("BAG-07-USE");
            bagFlowPresenter.SelectGiftChoice(0);
            InvokeBagControl("BAG-15-GIFT-ADD-ONE");
            if (BagModalQuantity != 2)
            { Fail($"Bag G4 choice quantity did not reach frozen acceptance value 2: {BagModalQuantity}."); yield break; }
            InvokeBagControl("BAG-18-GIFT-CONFIRM");
        }

        private bool ReopenBagForRecruitRouteValidation()
        {
            if (services?.UiStack.Current != mainView) return false;
            EnsureBagPresenter();
            bagPresenter.Render();
            ShowJingJieBag(false);
            return IsBagOpen;
        }

        public bool RunBagG4DirectUse()
        {
            if (GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity - 2
                || GetBagQuantityByItemId(4621) != bagG4InitialRewardQuantity + 2)
            {
                Fail("Bag G4 gift authority was not confirmed before direct-use validation.");
                return false;
            }
            if (bagG4DirectUseScheduled) return true;
            bagG4DirectUseScheduled = true;
            bagG4ExpectedFragmentQuantities[4621] = GetBagQuantityByItemId(4621);
            // This entry is invoked from Lua's /15 packet callback. Defer the
            // real UI interaction until Lua has returned; otherwise the use or
            // quantity-confirm button re-enters the same Lua state synchronously.
            StartCoroutine(RunBagG4DirectUseRoutine());
            return true;
        }

        private IEnumerator RunBagG4DirectUseRoutine()
        {
            Dictionary<uint, uint> expectedChoicePopup = new Dictionary<uint, uint>
            {
                { 4621u, 2u }
            };
            float rewardDeadline = Time.realtimeSinceStartup + 12f;
            while (rewardPresenter?.IsVisible != true && Time.realtimeSinceStartup < rewardDeadline)
                yield return null;
            string choicePopupDetail = "reward presenter unavailable";
            bool choiceFeedback = rewardPresenter != null
                && rewardPresenter.ValidateVisibleRewards("开启获得", expectedChoicePopup, out choicePopupDetail);
            if (!choiceFeedback)
            {
                Fail($"Bag G4 selectable gift reward popup mismatch: {choicePopupDetail}.");
                yield break;
            }
            yield return WaitForBagTransientOverlayToSettle("BAG-18-GIFT-SUCCESS");
            if (CurrentAppState == AppState.Failed) yield break;
            yield return CaptureBagG5Evidence("BAG-18-GIFT-SUCCESS");
            if (!InvokeEventSystemClick(rewardPresenter.CloseControl) || rewardPresenter.IsVisible)
            {
                Fail("Bag G4 selectable gift reward popup did not close through EventSystem.");
                yield break;
            }
            RecordValidationSemantic("bag-choice-use-authority", true,
                $"real /15 consumed item1111, added reward4621={GetBagQuantityByItemId(4621)}, rendered complete 开启获得 name/quantity, and closed through EventSystem");
            if (!SelectBagItem(3201))
            {
                Fail("Bag G4 injected direct-use item could not be selected through the real item button.");
                yield break;
            }
            yield return null;
            if (!InvokeBagControl("BAG-07-USE"))
            {
                Fail("Bag G4 injected direct-use item could not open its use flow through the real button.");
                yield break;
            }
            yield return null;
            // The reversible fixture intentionally retains one 3201 so injection
            // proves an authoritative add before consume. Quantity therefore
            // becomes two and the real Cocos rule opens EnterNumLayer. Confirm
            // quantity one through imported digit/confirm buttons instead of
            // bypassing the modal or calling Lua directly. EnterNumLayer starts
            // at zero, where confirm intentionally closes without sending /15.
            if (!IsBagInputOpen || !InvokeBagInputDigit(1)
                || BagModalQuantity != 1 || BagModalDisplayText != "1")
            {
                Fail($"Bag G4 injected direct-use item did not enter quantity one through EnterNumLayer: "
                    + $"open={IsBagInputOpen}, quantity={BagModalQuantity}, display='{BagModalDisplayText}'.");
                yield break;
            }
            yield return null;
            if (!InvokeBagControl("BAG-10-INPUT-CONFIRM") || IsBagInputOpen)
            {
                Fail("Bag G4 injected direct-use item did not confirm quantity one through EnterNumLayer.");
                yield break;
            }
        }

        public void BeginBagReloadValidation()
        {
            StartCoroutine(BeginBagReloadValidationRoutine());
        }

        private IEnumerator BeginBagReloadValidationRoutine()
        {
            if (GetBagQuantityByItemId(3201) != bagG4InitialDirectQuantity)
            { Fail("Bag G4 direct-use authority did not settle to the original quantity after injection and consume."); yield break; }
            RecordValidationSemantic("bag-direct-use-authority", true,
                "real injected item3201 quantity changed 1->2->1 through the quantity modal and authoritative /15");
            RecordValidationSemantic("bag-type-dispatch", true,
                "no-action, quantity input, choice gift, equipment info and direct-use paths were reached through configured item types");
            yield return ValidateBagRandomEquipmentBoxes();
            if (CurrentAppState == AppState.Failed) yield break;
            if (!InvokeBagControl("BAG-02-CLOSE") || IsBagOpen)
            { Fail("Bag G4 close button did not return to main."); yield break; }
            yield return CaptureBagG5Evidence("BAG-02-CLOSE");
            mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
            Button entry = mainView?.Binding.Find(BagPath)?.GetComponent<Button>();
            if (entry == null) { Fail("Bag G4 real main entry was unavailable after close."); yield break; }
            entry.onClick.Invoke();
        }

        private IEnumerator ValidateBagRandomEquipmentBoxes()
        {
            int[][] pools =
            {
                Enumerable.Range(4621, 8).ToArray(),
                Enumerable.Range(4629, 8).ToArray(),
                Enumerable.Range(4637, 8).ToArray()
            };
            int[] boxItemIds = { 512, 513, 514 };
            for (int index = 0; index < boxItemIds.Length; index++)
            {
                int boxItemId = boxItemIds[index];
                string prefix = $"BAG-BOX-{boxItemId}";
                Dictionary<int, int> beforeFragments = Enumerable.Range(4621, 24)
                    .ToDictionary(fragmentId => fragmentId, GetBagQuantityByItemId);
                Button itemControl = bagPresenter?.GetItemControl(boxItemId);
                if (!InvokeEventSystemClick(itemControl))
                {
                    Fail($"Bag G4 box {boxItemId} could not traverse its item EventSystem control.");
                    yield break;
                }
                yield return null;
                if (bagPresenter?.SelectedItemId != boxItemId)
                {
                    Fail($"Bag G4 box {boxItemId} selection did not settle before its BEFORE capture: "
                        + $"selected={bagPresenter?.SelectedItemId ?? 0}.");
                    yield break;
                }
                yield return CaptureBagG5Evidence(prefix + "-BEFORE");
                if (!InvokeEventSystemClick(bagPresenter?.UseControl))
                {
                    Fail($"Bag G4 box {boxItemId} could not traverse its use EventSystem control.");
                    yield break;
                }
                yield return null;
                if (!IsBagInputOpen
                    || !InvokeEventSystemClick(bagFlowPresenter?.GetInputDigitControl(1))
                    || BagModalQuantity != 1 || BagModalDisplayText != "1")
                {
                    Fail($"Bag G4 box {boxItemId} did not enter quantity one through the real EventSystem number control: "
                        + $"open={IsBagInputOpen}, quantity={BagModalQuantity}, display='{BagModalDisplayText}'.");
                    yield break;
                }
                MarkValidationControl("BAG-08-INPUT-DIGITS");
                yield return null;
                if (!InvokeEventSystemClick(bagFlowPresenter?.InputConfirmControl) || IsBagInputOpen)
                {
                    Fail($"Bag G4 box {boxItemId} did not confirm quantity one through the real EventSystem control.");
                    yield break;
                }
                MarkValidationControl("BAG-10-INPUT-CONFIRM");
                float deadline = Time.realtimeSinceStartup + 12f;
                while ((GetBagQuantityByItemId(boxItemId) != bagG4InitialBoxQuantities[boxItemId] - 1
                        || rewardPresenter?.IsVisible != true)
                    && Time.realtimeSinceStartup < deadline) yield return null;

                Dictionary<int, int> deltas = beforeFragments.ToDictionary(pair => pair.Key,
                    pair => GetBagQuantityByItemId(pair.Key) - pair.Value);
                int[] pool = pools[index];
                bool sourceDeducted = GetBagQuantityByItemId(boxItemId)
                    == bagG4InitialBoxQuantities[boxItemId] - 1;
                bool poolDelta = pool.Sum(fragmentId => deltas[fragmentId]) == 1
                    && pool.Count(fragmentId => deltas[fragmentId] == 1) == 1
                    && deltas.Where(pair => !pool.Contains(pair.Key)).All(pair => pair.Value == 0)
                    && deltas.Values.All(value => value == 0 || value == 1);
                Dictionary<uint, uint> expectedPopup = deltas.Where(pair => pair.Value > 0)
                    .ToDictionary(pair => checked((uint)pair.Key), pair => checked((uint)pair.Value));
                string popupDetail = "reward presenter unavailable";
                bool feedback = rewardPresenter != null
                    && rewardPresenter.ValidateVisibleRewards("开启获得", expectedPopup, out popupDetail);
                if (!sourceDeducted || !poolDelta || !feedback)
                {
                    Fail($"Bag G4 box {boxItemId} transaction mismatch: source={sourceDeducted}, "
                        + $"pool={poolDelta}, feedback={feedback}, popup={popupDetail}.");
                    yield break;
                }
                foreach (KeyValuePair<int, int> pair in deltas)
                    bagG4ExpectedFragmentQuantities[pair.Key] += pair.Value;
                yield return WaitForBagTransientOverlayToSettle(prefix + "-REWARD");
                if (CurrentAppState == AppState.Failed) yield break;
                yield return CaptureBagG5Evidence(prefix + "-REWARD");
                if (!InvokeEventSystemClick(rewardPresenter.CloseControl) || rewardPresenter.IsVisible)
                {
                    Fail($"Bag G4 box {boxItemId} reward popup did not close through EventSystem.");
                    yield break;
                }
            }
            RecordValidationSemantic("bag-random-equipment-box-authority", true,
                "real EventSystem use consumed 512/513/514 exactly once and each authoritative /15 result added exactly one in-pool fragment");
            RecordValidationSemantic("bag-random-equipment-box-feedback", true,
                "each authoritative box result rendered complete 开启获得 name and quantity, then closed through EventSystem");
            RecordValidationSemantic("bag-random-equipment-box-config-family", true,
                "512/513/514 results stayed within 4621-4628/4629-4636/4637-4644 and all out-of-pool fragments were atomic");
        }

        public void BeginBagDisconnectValidation()
        {
            if (!IsBagOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Bag G4 pre-disconnect mismatch: open={IsBagOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            StartCoroutine(BeginBagDisconnectValidationRoutine());
        }

        private IEnumerator BeginBagDisconnectValidationRoutine()
        {
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-REENTER");
            services.Network.Disconnect();
            yield return null;
            yield return new WaitForSecondsRealtime(0.25f);
            if (services.Network.State != NetworkState.Disconnected)
            {
                Fail($"Bag G4 disconnect was not observed: state={services.Network.State}.");
                yield break;
            }
            yield return WaitForBagTransientOverlayToSettle("BAG-01-PERSISTENCE-DISCONNECTED");
            if (CurrentAppState == AppState.Failed) yield break;
            yield return CaptureBagG5Evidence("BAG-01-DISCONNECTED");
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-DISCONNECTED");
            // The Bag gate owns this deliberate disconnect. Trigger the real
            // reconnect entry after the disconnected state is observable instead
            // of depending on the general delayed retry policy.
            Reconnect();
        }

        public void CompleteBagG4Validation()
        {
            StartCoroutine(CompleteBagG4ValidationRoutine());
        }

        private IEnumerator CompleteBagG4ValidationRoutine()
        {
            if (!IsBagOpen || services.ProtocolRegistry.PendingCount != 0
                || GetBagQuantityByItemId(500) != bagG4InitialBatchQuantity - 10
                || GetBagQuantityByItemId(1111) != bagG4InitialGiftQuantity - 2
                || GetBagQuantityByItemId(3201) != bagG4InitialDirectQuantity
                || GetBagQuantityByItemId(4621) < bagG4InitialRewardQuantity + 1
                || bagG4InitialBoxQuantities.Any(pair => GetBagQuantityByItemId(pair.Key) != pair.Value - 1)
                || bagG4ExpectedFragmentQuantities.Any(pair => GetBagQuantityByItemId(pair.Key) != pair.Value)
                || IsBagInputOpen || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 persisted/reconnect mismatch: open={IsBagOpen}, pending={services.ProtocolRegistry.PendingCount}, "
                    + $"500={GetBagQuantityByItemId(500)}/{bagG4InitialBatchQuantity - 10}, "
                    + $"1111={GetBagQuantityByItemId(1111)}/{bagG4InitialGiftQuantity - 2}, "
                    + $"3201={GetBagQuantityByItemId(3201)}/{bagG4InitialDirectQuantity}, "
                    + $"4621={GetBagQuantityByItemId(4621)}/{bagG4InitialRewardQuantity + 1}, "
                    + $"modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
            ShowToast("重新连接成功", 2f);
            yield return CaptureBagG5Evidence("BAG-01-PERSISTENCE-RECONNECT");
            RecordValidationSemantic("bag-network-recovery", true,
                $"deliberate disconnect/reconnect restored Bag for role={GetPlayerRoleId()} with pending=0");
            validationRoleIdSnapshot = GetPlayerRoleId();
            ReturnToLogin();
            if (!IsLoginVisible || services.Bag.Count != 0 || IsBagOpen || IsBagInputOpen
                || IsBagGiftOpen || IsBagSourceOpen || IsBagEquipmentInfoOpen)
            {
                Fail($"Bag G4 account-switch cleanup mismatch: login={IsLoginVisible}, count={services.Bag.Count}, "
                    + $"open={IsBagOpen}, modals={IsBagInputOpen}/{IsBagGiftOpen}/{IsBagSourceOpen}/{IsBagEquipmentInfoOpen}.");
                yield break;
            }
            RecordValidationSemantic("bag-account-isolation", true,
                "return-to-login cleared Bag store and every Bag modal while preserving the fixed role snapshot");
            RecordValidationSemantic("bag-fixture-exact-restore", true,
                "outer fixed-account runner owns finally restore, relogin hash equality and backup residue assertions");
            RecordValidationSemantic("bag-control-matrix-26", validationControlIds.Count == 26,
                $"validated={validationControlIds.Count}/26 through real callbacks");
            Complete("COMPLETE: Bag G4 real controls -> batch/gift/direct use -> authoritative add/update/delete/sort "
                + "-> invalid/repeat rejection -> close/reload -> disconnect/reconnect persistence -> account-switch cleanup");
        }

        private int GetBagQuantityByItemId(int itemId)
        {
            return services.Bag.GetTotalQuantityByItemId(itemId);
        }

        private IEnumerator CaptureBagG5Evidence(string controlId)
        {
            string repositoryRoot = Directory.GetParent(Application.dataPath).Parent.FullName;
            string outputDirectory = Path.Combine(repositoryRoot, ".local", "ui-fidelity", "Bag", "unity", "g5-20260824");
            Directory.CreateDirectory(outputDirectory);
            string path = Path.Combine(outputDirectory, controlId + ".png");
            if (File.Exists(path)) File.Delete(path);
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            while ((!File.Exists(path) || new FileInfo(path).Length == 0) && Time.realtimeSinceStartup < deadline)
                yield return null;
            if (!File.Exists(path) || new FileInfo(path).Length == 0)
                throw new IOException($"Bag G5 screenshot was not written: {path}");
            string artifactName = null;
            switch (controlId)
            {
                case "BAG-01-ENTRY": artifactName = "bootstrap-bag.png"; break;
                case "BAG-01-RECONNECT":
                    artifactName = "bootstrap-bag-reconnected.png";
                    break;
                case "BAG-05-LIST-SCROLL": artifactName = "bootstrap-bag-scrolled.png"; break;
                case "BAG-07-USE-BATCH": artifactName = "bootstrap-bag-input.png"; break;
                case "BAG-12-GIFT-OPEN": artifactName = "bootstrap-bag-gift.png"; break;
                case "BAG-13-GIFT-SCROLL": artifactName = "bootstrap-bag-gift-scrolled.png"; break;
                case "BAG-20-EQUIPMENT-SOURCE": artifactName = "bootstrap-bag-source.png"; break;
                case "BAG-22-SOURCE-ICON": artifactName = "bootstrap-bag-equipment-info.png"; break;
                case "BAG-01-DISCONNECTED": artifactName = "bootstrap-bag-disconnected.png"; break;
                case "BAG-01-REENTER": artifactName = "bootstrap-bag-reenter.png"; break;
                case "BAG-BOX-512-BEFORE": artifactName = "bootstrap-bag-box-512-before.png"; break;
                case "BAG-BOX-512-REWARD": artifactName = "bootstrap-bag-box-512-reward.png"; break;
                case "BAG-BOX-513-BEFORE": artifactName = "bootstrap-bag-box-513-before.png"; break;
                case "BAG-BOX-513-REWARD": artifactName = "bootstrap-bag-box-513-reward.png"; break;
                case "BAG-BOX-514-BEFORE": artifactName = "bootstrap-bag-box-514-before.png"; break;
                case "BAG-BOX-514-REWARD": artifactName = "bootstrap-bag-box-514-reward.png"; break;
            }
            if (!string.IsNullOrEmpty(artifactName))
                File.Copy(path, BuildUiMigrationPath(artifactName), true);
        }

        private IEnumerator WaitForBagTransientOverlayToSettle(string captureId)
        {
            const float quietSeconds = 0.5f;
            float deadline = Time.realtimeSinceStartup + 15f;
            float quietSince = -1f;
            while (Time.realtimeSinceStartup < deadline)
            {
                bool obstructed = IsToastVisible
                    || mainHudPresenter?.HasVisibleSystemChatSummary == true;
                if (obstructed) quietSince = -1f;
                else if (quietSince < 0f) quietSince = Time.realtimeSinceStartup;
                else if (Time.realtimeSinceStartup - quietSince >= quietSeconds) yield break;
                yield return null;
            }
            Fail($"Bag G5 transient overlay did not settle naturally before {captureId}; "
                + $"toastVisible={IsToastVisible}, "
                + $"systemChatSummary={mainHudPresenter?.HasVisibleSystemChatSummary == true}.");
        }
    }
}
