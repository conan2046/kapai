using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private void EnsureWorldPresenter()
        {
            // 副本根 = WorldMapNewLayer（承载 chapterPage 章节选择；旧 bg 在加载后隐藏）。
            // World Prefabs are resolved by Unity Catalog keys and searched by their Unity Transform hierarchy.
            worldView = worldView ?? services.UiRouter.FindByKey("WorldMapNewLayer");
            worldStageView = worldStageView ?? services.UiRouter.FindByKey("kapaiguaiwuLayer");
            worldMapView = worldMapView ?? services.UiRouter.FindByKey("DadituuiLayer");
            worldDetailView = worldDetailView ?? services.UiRouter.FindByKey("guanqiaxiangxiLayer");
            if (worldView == null || worldStageView == null || worldMapView == null || worldDetailView == null)
                throw new InvalidOperationException("Unity World Catalog Prefabs were not found.");
            worldPresenter = worldPresenter ?? new WorldPresenter(worldView, worldStageView, worldMapView, worldDetailView,
                services.World, services.Heroes, services.Formation, services.Player, services.Resources, services.Currencies,
                services.ShopCatalog, services.EquipmentCatalog,
                id => { RememberLastWorldChapter(checked((uint)id)); InvokeLuaOrFail(onWorldRequestChapter, "World.RequestChapter", (double)id); },
                id => { services.World.SelectStage(id); InvokeLuaOrFail(onWorldRequestStage, "World.RequestStage", (double)id); },
                HandleWorldChallengeRequest,
                () => InvokeLuaOrFail(onWorldSweep, "World.Sweep"),
                ShowWorldResetConfirmation,
                id => InvokeLuaOrFail(onWorldClaimBox, "World.ClaimBox", (double)id),
                ShowWorldNormalBox,
                HandleWorldFormationPopupClick,
                returnToDetail =>
                {
                    worldFormationReturnPending = true;
                    worldFormationReturnToDetail = returnToDetail;
                    // 快照打开阵容前的章节页状态：从章节选择页点 btn_zhenrong 进入时，
                    // 关闭阵容必须回到章节页（btn_1..5 / Button_1 / Button_2 保持可见），
                    // 不能像从大底图进入那样回落 ShowStages()。
                    worldFormationReturnToChapters = worldPresenter != null && worldPresenter.ShowingChapters;
                    HandleFormationClick();
                },
                ShowWorldAchievement,
                HandleWorldYouLiClick,
                () => HandleBack(),
                controlId =>
                {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
                    if (services.Options.WorldBattleValidation) MarkValidationControl(controlId);
#endif
                },
                // 龙崖副本模式：`bg/CheckBox_1`「自动挑战」/ `bg/CheckBox_2`「自动挑战下一章」→ 通知 Lua
                setChainAuto: enabled => SetWorldChainAuto(enabled),
                setChainAutoNext: enabled => SetWorldChainAutoNext(enabled),
                leaveCurrentChapter: BackgroundWorldBattle);
            // 关键：op=1 到达时 worldPresenter 可能尚未创建（模式下发早于
            // EndWorldChapterList → EnsureWorldPresenter），因此在这里补一次。
            worldPresenter.SetChainMode(worldChainMode);
        }

        private void RestoreWorldAfterHeroFormation()
        {
            bool restoreDetail = worldFormationReturnToDetail;
            bool restoreChapters = worldFormationReturnToChapters;
            worldFormationReturnPending = false;
            worldFormationReturnToDetail = false;
            worldFormationReturnToChapters = false;
            formationPopupView?.SetVisible(false);
            if (restoreDetail) worldPresenter?.ShowSelectedStage();
            else if (restoreChapters) worldPresenter?.ShowChapterPage();
            else worldPresenter?.ShowStages();
            StartCoroutine(RefreshWorldInteractionsAfterVisibilityChange());
        }

        private void HandleWorldYouLiClick()
        {
            worldYouLiReturnPending = true;
            try
            {
                InvokeLuaOrFail(onYouLiClicked, "World.YouLi");
            }
            catch
            {
                worldYouLiReturnPending = false;
                throw;
            }
        }

        private void HandleWorldFormationPopupClick()
        {
            if (worldFormationPopupRequestPending) return;
            worldFormationPopupRequestPending = true;
            pendingHeroEntry = HeroEntry.Formation;
            heroEntryRequestPending = true;
            try { CallLua(onHeroClicked, "World.FormationPopup"); }
            catch (Exception exception)
            {
                worldFormationPopupRequestPending = false;
                heroEntryRequestPending = false;
                Fail($"World formation popup open failed: {exception.Message}");
            }
        }

        private IEnumerator RefreshWorldInteractionsAfterVisibilityChange()
        {
            yield return null;
            yield return new WaitForEndOfFrame();
            if (IsWorldOpen) worldPresenter?.RefreshInteractionButtons();
        }

        private void EnsureWorldBoxAwardView()
        {
            EnsureWorldPresenter();
            worldBoxAwardView = worldBoxAwardView ?? services.UiRouter.FindByKey("guaiwubaoxiangLayer");
            if (worldBoxAwardView == null) throw new InvalidOperationException("Unity World box award Prefab was not found.");
            if (worldBoxAwardView.GameObject.transform.parent != worldView.GameObject.transform)
            {
                worldBoxAwardView.GameObject.transform.SetParent(worldView.GameObject.transform, false);
                RectTransform rect = worldBoxAwardView.GameObject.transform as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = Vector2.zero;
                    rect.anchorMax = Vector2.one;
                    rect.offsetMin = rect.offsetMax = Vector2.zero;
                    rect.localScale = Vector3.one;
                }
            }
            RefreshWorldBoxButtonBindings();
        }

        private void RefreshWorldBoxButtonBindings()
        {
            BindWorldBoxButton("Layer/Cangbaotu/bg/Title/Button_1", HideWorldBoxAward);
            BindWorldBoxButton("Layer/Cangbaotu/bg/ButtonOwn", HideWorldBoxAward);
            BindWorldBoxButton("Layer/Cangbaotu/bg/Button", ClaimSelectedWorldBox);
        }

        private void BindWorldBoxButton(string path, Action action)
        {
            GameObject target = worldBoxAwardView.FindNode(path);
            if (target == null) throw new InvalidOperationException($"World box award control is missing: {path}");
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            Graphic surface = target.GetComponent<Graphic>();
            if (surface == null)
            {
                Image image = target.AddComponent<Image>();
                image.color = new Color(1f, 1f, 1f, 0.001f);
                surface = image;
            }
            surface.enabled = false;
            surface.enabled = true;
            surface.canvasRenderer.cullTransparentMesh = false;
            if (surface.color.a <= 0f)
                surface.color = new Color(surface.color.r, surface.color.g, surface.color.b, 0.001f);
            surface.raycastTarget = true;
            surface.SetAllDirty();
            button.targetGraphic = surface;
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());

            if (!worldBoxAwardView.GameObject.activeInHierarchy || !target.activeInHierarchy) return;
            string proxyName = path.EndsWith("/ButtonOwn", StringComparison.Ordinal)
                ? "RuntimeWorldBoxCloseHitSurface"
                : path.EndsWith("/Button_1", StringComparison.Ordinal)
                    ? "RuntimeWorldBoxTitleCloseHitSurface"
                    : "RuntimeWorldBoxClaimHitSurface";
            Button hitButton = CreateWorldBoxRootProxy(target, proxyName, action);
            if (proxyName == "RuntimeWorldBoxClaimHitSurface") worldBoxClaimInteractionButton = hitButton;
            else if (proxyName == "RuntimeWorldBoxCloseHitSurface") worldBoxCloseInteractionButton = hitButton;
            else worldBoxTitleCloseInteractionButton = hitButton;
        }

        private Button CreateWorldBoxRootProxy(GameObject target, string proxyName, Action action)
        {
            RectTransform rootRect = worldView.GameObject.transform as RectTransform;
            RectTransform targetRect = target.transform as RectTransform;
            if (rootRect == null || targetRect == null) return null;
            Transform existing = rootRect.Find(proxyName);
            GameObject proxy = existing != null
                ? existing.gameObject
                : new GameObject(proxyName, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(Button));
            RectTransform proxyRect = proxy.GetComponent<RectTransform>();
            proxyRect.SetParent(rootRect, false);
            proxyRect.anchorMin = proxyRect.anchorMax = new Vector2(.5f, .5f);
            proxyRect.pivot = new Vector2(.5f, .5f);
            proxyRect.localScale = Vector3.one;
            proxy.SetActive(true);
            Canvas.ForceUpdateCanvases();
            Vector3[] corners = new Vector3[4];
            targetRect.GetWorldCorners(corners);
            Vector3 localBottomLeft = rootRect.InverseTransformPoint(corners[0]);
            Vector3 localTopRight = rootRect.InverseTransformPoint(corners[2]);
            proxyRect.sizeDelta = new Vector2(Mathf.Abs(localTopRight.x - localBottomLeft.x),
                Mathf.Abs(localTopRight.y - localBottomLeft.y));
            proxyRect.position = targetRect.TransformPoint(targetRect.rect.center);
            Image image = proxy.GetComponent<Image>();
            image.color = new Color(1f, 1f, 1f, .01f);
            image.raycastTarget = true;
            image.canvasRenderer.cullTransparentMesh = false;
            image.enabled = false;
            image.enabled = true;
            image.SetAllDirty();
            Canvas canvas = image.canvas;
            if (canvas != null)
            {
                GraphicRegistry.RegisterGraphicForCanvas(canvas, image);
                GraphicRegistry.RegisterRaycastGraphicForCanvas(canvas, image);
            }
            Button button = proxy.GetComponent<Button>();
            button.targetGraphic = image;
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
            proxy.transform.SetAsLastSibling();
            return button;
        }

        private void ShowWorldNormalBox(WorldStageRecord stage)
        {
            if (stage == null || stage.RewardBoxId == 0) return;
            EnsureWorldBoxAwardView();
            selectedWorldBoxStageId = stage.Id;
            bool claimable = stage.RewardBoxState == 1;
            bool claimed = stage.RewardBoxState >= 2;
            Text title = worldBoxAwardView.FindNode("Layer/Cangbaotu/bg/Title/TitleBg")?.GetComponentInChildren<Text>(true);
            if (title != null) title.text = "关卡宝箱";
            Text hint = worldBoxAwardView.FindNode("Layer/Cangbaotu/bg/Image_bg/Text_2")?.GetComponent<Text>();
            if (hint != null) hint.text = claimable ? $"{stage.Name} 宝箱可领取" : claimed ? "该宝箱已领取" : $"通关 {stage.Name} 后可领取";
            if (!WorldVisualCatalog.TryGetBoxRewards(stage.RewardBoxId, out WorldConfiguredReward[] configuredRewards))
            {
                SetWorldError($"宝箱 {stage.RewardBoxId} 的奖励配置缺失。");
                return;
            }
            RenderWorldBoxRewards(configuredRewards);
            if (hint != null)
            {
                hint.rectTransform.anchorMin = hint.rectTransform.anchorMax = new Vector2(.5f, 0f);
                hint.rectTransform.anchoredPosition = new Vector2(0f, 30f);
                hint.rectTransform.sizeDelta = new Vector2(650f, 50f);
                hint.fontSize = 24;
                hint.alignment = TextAnchor.MiddleCenter;
            }
            GameObject claim = worldBoxAwardView.FindNode("Layer/Cangbaotu/bg/Button");
            GameObject close = worldBoxAwardView.FindNode("Layer/Cangbaotu/bg/ButtonOwn");
            if (claim != null) claim.SetActive(claimable);
            if (close != null) close.SetActive(!claimable);
            Text claimText = claim?.GetComponentInChildren<Text>(true);
            Text closeText = close?.GetComponentInChildren<Text>(true);
            if (claimText != null) claimText.text = "领取";
            if (closeText != null) closeText.text = "关闭";
            worldBoxAwardView.ShowPopup();
            SetWorldBoxRootProxiesVisible(false);
            // The imported dialog is normally inactive while its bindings are
            // prepared. Re-register its Graphics after activation so the
            // player-facing confirmation participates in GraphicRaycaster.
            RefreshWorldBoxButtonBindings();
            Canvas.ForceUpdateCanvases();
        }

        private void RenderWorldBoxRewards(WorldConfiguredReward[] rewards)
        {
            Transform panel = worldBoxAwardView.FindNode("Cangbaotu/bg/Image_bg").transform;
            Transform originals = panel.Find("IconList");
            GameObject template = originals.Find("Icon_Bg1").gameObject;
            originals.gameObject.SetActive(false);
            Transform existing = panel.Find("RuntimeBoxRewards");
            GameObject viewportObject = existing != null ? existing.gameObject
                : new GameObject("RuntimeBoxRewards", typeof(RectTransform), typeof(CanvasRenderer),
                    typeof(Image), typeof(RectMask2D), typeof(ScrollRect));
            RectTransform viewport = viewportObject.GetComponent<RectTransform>();
            viewport.SetParent(panel, false);
            viewport.anchorMin = Vector2.zero;
            viewport.anchorMax = Vector2.one;
            viewport.offsetMin = new Vector2(18f, 70f);
            viewport.offsetMax = new Vector2(-18f, -12f);
            Image surface = viewportObject.GetComponent<Image>();
            surface.color = new Color(1f, 1f, 1f, .001f);
            surface.raycastTarget = true;
            Transform oldContent = viewport.Find("Content");
            RectTransform content = oldContent != null ? oldContent as RectTransform
                : new GameObject("Content", typeof(RectTransform)).GetComponent<RectTransform>();
            content.SetParent(viewport, false);
            content.anchorMin = content.anchorMax = new Vector2(.5f, 1f);
            content.pivot = new Vector2(.5f, 1f);
            Canvas.ForceUpdateCanvases();
            float width = viewport.rect.width;
            content.sizeDelta = new Vector2(width, Mathf.CeilToInt(rewards.Length / 4f) * 180f);
            foreach (Transform child in content) child.gameObject.SetActive(false);
            for (int index = 0; index < rewards.Length; index++)
            {
                string cellName = "Reward_" + index;
                Transform found = content.Find(cellName);
                GameObject cell = found != null ? found.gameObject : Instantiate(template, content, false);
                cell.name = cellName;
                cell.SetActive(true);
                RectTransform rect = cell.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(.5f, 1f);
                rect.anchoredPosition = new Vector2((index % 4 + .5f) * width / 4f, -index / 4 * 180f);
                rect.sizeDelta = new Vector2(145f, 175f);
                Image cellImage = cell.GetComponent<Image>();
                if (cellImage != null) cellImage.enabled = false;
                RewardRecord reward = DescribeWorldConfiguredReward(rewards[index]);
                Text label = cell.transform.Find("Name")?.GetComponent<Text>();
                if (label != null)
                {
                    label.text = reward.Name;
                    label.fontSize = 20;
                    label.rectTransform.anchorMin = label.rectTransform.anchorMax = new Vector2(.5f, 0f);
                    label.rectTransform.anchoredPosition = new Vector2(0f, 22f);
                    label.rectTransform.sizeDelta = new Vector2(145f, 44f);
                    label.alignment = TextAnchor.MiddleCenter;
                }
                RectTransform icon = cell.transform.Find("IconBg") as RectTransform;
                if (icon != null)
                {
                    icon.anchorMin = icon.anchorMax = new Vector2(.5f, 1f);
                    icon.pivot = new Vector2(.5f, 1f);
                    icon.anchoredPosition = Vector2.zero;
                    icon.sizeDelta = new Vector2(125f, 125f);
                }
                RenderWorldRewardIcon(icon, reward);
            }
            ScrollRect scroll = viewportObject.GetComponent<ScrollRect>();
            scroll.viewport = viewport;
            scroll.content = content;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.StopMovement();
            scroll.verticalNormalizedPosition = 1f;
        }

        private void ClaimSelectedWorldBox()
        {
            WorldStageRecord stage = services.World.Stages.FirstOrDefault(value => value.Id == selectedWorldBoxStageId);
            if (stage == null || stage.RewardBoxId == 0 || stage.RewardBoxState != 1)
            {
                SetWorldError("该宝箱当前不可领取。");
                return;
            }
            HideWorldBoxAward();
            InvokeLuaOrFail(onWorldClaimBox, "World.ClaimBox", (double)stage.RewardBoxId);
        }

        private void HideWorldBoxAward()
        {
            if (worldBoxAwardView != null) worldBoxAwardView.GameObject.SetActive(false);
            SetWorldBoxRootProxiesVisible(false);
        }

        private void SetWorldBoxRootProxiesVisible(bool visible)
        {
            if (worldBoxClaimInteractionButton != null) worldBoxClaimInteractionButton.gameObject.SetActive(visible);
            if (worldBoxCloseInteractionButton != null) worldBoxCloseInteractionButton.gameObject.SetActive(visible);
            if (worldBoxTitleCloseInteractionButton != null) worldBoxTitleCloseInteractionButton.gameObject.SetActive(visible);
        }

        private RewardRecord DescribeWorldConfiguredReward(WorldConfiguredReward configured)
        {
            uint amount = checked((uint)Math.Max(0, configured.Amount));
            if (configured.Type == 60002 && HeroCatalog.TryGet(configured.Id, out HeroDefinition hero))
                return new RewardRecord(configured.Type, checked((uint)configured.Id), amount,
                    hero.Name, hero.Picture, hero.Quality);
            if (configured.Type == 60005)
            {
                EquipmentDefinition equipment = services.EquipmentCatalog.GetEquipment(configured.Id);
                return new RewardRecord(configured.Type, checked((uint)Math.Max(0, configured.Id)), amount,
                    equipment.Name, 0, equipment.Quality);
            }
            return services.ShopCatalog.DescribeServerReward(configured.Type, configured.Id, amount);
        }

        private void RenderWorldRewardIcon(Transform host, RewardRecord reward)
        {
            if (host == null) return;
            Image frame = host.GetComponent<Image>();
            if (frame != null)
            {
                frame.sprite = services.Resources.LoadFirst(
                    $"Art/Hero/common_quality_{Mathf.Clamp(reward.Quality, 1, 7):00}");
                frame.enabled = frame.sprite != null;
            }
            Transform existing = host.Find("RuntimeIcon");
            GameObject iconObject = existing != null ? existing.gameObject
                : new GameObject("RuntimeIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform iconRect = iconObject.GetComponent<RectTransform>();
            iconRect.SetParent(host, false);
            iconRect.anchorMin = new Vector2(.12f, .14f);
            iconRect.anchorMax = new Vector2(.88f, .92f);
            iconRect.offsetMin = iconRect.offsetMax = Vector2.zero;
            Image icon = iconObject.GetComponent<Image>();
            icon.sprite = reward.Type == 60005
                ? services.Resources.LoadEquipmentIcon(services.EquipmentCatalog.GetEquipment(checked((int)reward.Id)).Picture)
                : reward.Type == 60002
                    ? services.Resources.LoadHeroPortrait(reward.Picture)
                    : reward.Picture > 0 ? services.Resources.LoadItemIcon(reward.Picture) : null;
            icon.enabled = icon.sprite != null;
            icon.preserveAspect = true;
            icon.raycastTarget = false;
            Transform amountExisting = host.Find("RuntimeAmount");
            Text amount;
            if (amountExisting == null)
            {
                GameObject amountObject = new GameObject("RuntimeAmount", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                RectTransform amountRect = amountObject.GetComponent<RectTransform>();
                amountRect.SetParent(host, false);
                amountRect.anchorMin = new Vector2(.45f, 0f);
                amountRect.anchorMax = new Vector2(1f, .32f);
                amountRect.offsetMin = amountRect.offsetMax = Vector2.zero;
                amount = amountObject.GetComponent<Text>();
                amount.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                amount.fontSize = 18;
                amount.alignment = TextAnchor.MiddleRight;
                amount.color = Color.white;
            }
            else amount = amountExisting.GetComponent<Text>();
            if (amount != null) amount.text = reward.Amount.ToString();
        }

        private void ShowWorldAchievement()
        {
            EnsureWorldAchievementView();
            AttachWorldAchievementToWorldRoot();
            worldAchievementAuthoritativeResponse = false;
            worldAchievementView.ShowPopup();
            RectTransform content = worldAchievementView.FindNode(
                "Layer/zhuxianchengjiu_layer")?.transform as RectTransform;
            if (content != null) content.anchoredPosition = Vector2.zero;
            Animator animator = worldAchievementView.GameObject.GetComponent<Animator>();
            if (animator != null)
                animator.Play("WorldAchievement", 0, 0f);
            if (worldAchievementLayoutCoroutine != null)
                StopCoroutine(worldAchievementLayoutCoroutine);
            worldAchievementLayoutCoroutine = StartCoroutine(FitWorldAchievementAfterOpen(animator));
            RenderWorldAchievement();
            InvokeLuaOrFail(onWorldAchievementRequest, "World.AchievementRequest");
        }

        private void EnsureWorldAchievementView()
        {
            EnsureWorldPresenter();
            worldAchievementView = worldAchievementView ?? services.UiAssets.GetUnityOrCreate("zhuxianchengjiu");
            if (worldAchievementView == null)
                throw new InvalidOperationException("World achievement Unity Prefab was not found in the UI catalog.");
            AttachWorldAchievementToWorldRoot();
            GameObject mask = worldAchievementView.FindNode("Layer/Mask");
            if (mask != null)
            {
                mask.SetActive(true);
                RectTransform maskRect = mask.transform as RectTransform;
                if (maskRect != null)
                {
                    maskRect.anchorMin = Vector2.zero;
                    maskRect.anchorMax = Vector2.one;
                    maskRect.offsetMin = Vector2.zero;
                    maskRect.offsetMax = Vector2.zero;
                }
                mask.transform.SetAsFirstSibling();
                BindWorldAchievementButton("Layer/Mask", () => worldAchievementView.SetVisible(false));
            }
            BindWorldAchievementButton("Layer/zhuxianchengjiu_layer/Btn_Close", () => worldAchievementView.SetVisible(false));
            for (int index = 1; index <= 6; index++)
            {
                int claimIndex = index;
                BindWorldAchievementButton(
                    $"Layer/zhuxianchengjiu_layer/jiangli_layer/Item_layer/Item{index}",
                    () => ClaimWorldAchievement(claimIndex));
            }
        }

        private void AttachWorldAchievementToWorldRoot()
        {
            worldAchievementView.GameObject.transform.SetParent(worldView.GameObject.transform, false);
            RectTransform rect = worldAchievementView.GameObject.transform as RectTransform;
            if (rect == null) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = Vector2.zero;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localRotation = Quaternion.identity;
            rect.localScale = Vector3.one;
        }

        private IEnumerator FitWorldAchievementAfterOpen(Animator animator)
        {
            float deadline = Time.realtimeSinceStartup + 2f;
            while (animator != null && animator.GetCurrentAnimatorStateInfo(0).normalizedTime < 1f
                && Time.realtimeSinceStartup < deadline)
                yield return null;
            yield return new WaitForEndOfFrame();
            FitWorldAchievementToScreen();
            worldAchievementLayoutCoroutine = null;
        }

        private void FitWorldAchievementToScreen()
        {
            RectTransform root = worldAchievementView?.GameObject.transform as RectTransform;
            RectTransform content = worldAchievementView?.FindNode(
                "Layer/zhuxianchengjiu_layer")?.transform as RectTransform;
            if (root == null || content == null) return;
            Canvas.ForceUpdateCanvases();
            Bounds bounds = RectTransformUtility.CalculateRelativeRectTransformBounds(root, content);
            Rect available = root.rect;
            float x = bounds.size.x > available.width
                ? available.center.x - bounds.center.x
                : Mathf.Clamp(0f, available.xMin - bounds.min.x, available.xMax - bounds.max.x);
            float y = bounds.size.y > available.height
                ? available.yMax - 55f - bounds.max.y
                : Mathf.Clamp(0f, available.yMin - bounds.min.y, available.yMax - bounds.max.y);
            content.anchoredPosition += new Vector2(x, y);
            RectTransform close = worldAchievementView.FindNode(
                "Layer/zhuxianchengjiu_layer/Btn_Close")?.transform as RectTransform;
            if (close != null)
            {
                close.SetParent(root, false);
                close.anchorMin = close.anchorMax = new Vector2(.5f, 0f);
                close.pivot = new Vector2(.5f, 0f);
                close.anchoredPosition = new Vector2(0f, 16f);
                close.sizeDelta = new Vector2(300f, 50f);
                Image closeSurface = close.GetComponent<Image>();
                if (closeSurface != null)
                {
                    Color color = closeSurface.color;
                    color.a = .001f;
                    closeSurface.color = color;
                    closeSurface.raycastTarget = true;
                    closeSurface.canvasRenderer.cullTransparentMesh = false;
                }
                CanvasGroup closeGroup = close.GetComponent<CanvasGroup>();
                if (closeGroup != null) closeGroup.alpha = 1f;
                Text closeLabel = close.GetComponentInChildren<Text>(true);
                if (closeLabel != null)
                {
                    closeLabel.text = "点击屏幕关闭";
                    Color labelColor = closeLabel.color;
                    labelColor.a = 1f;
                    closeLabel.color = labelColor;
                    closeLabel.raycastTarget = false;
                }
                close.SetAsLastSibling();
            }
            Canvas.ForceUpdateCanvases();
        }

        private void BindWorldAchievementButton(string path, Action action)
        {
            GameObject target = worldAchievementView.FindNode(path);
            if (target == null) throw new InvalidOperationException($"World achievement control is missing: {path}");
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            Graphic surface = target.GetComponent<Graphic>();
            if (surface == null)
            {
                Image image = target.AddComponent<Image>();
                image.color = new Color(1f, 1f, 1f, 0.001f);
                surface = image;
            }
            surface.enabled = false;
            surface.enabled = true;
            surface.canvasRenderer.cullTransparentMesh = false;
            if (surface.color.a <= 0f)
                surface.color = new Color(surface.color.r, surface.color.g, surface.color.b, 0.001f);
            surface.raycastTarget = true;
            surface.SetAllDirty();
            button.targetGraphic = surface;
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void ClaimWorldAchievement(int index)
        {
            IReadOnlyList<WorldAchievementDefinition> values = WorldVisualCatalog.GetAchievements(worldAchievementType);
            WorldAchievementDefinition achievement = index > 0 && index <= values.Count ? values[index - 1] : null;
            int stars = services.World.Chapters.Sum(value => (int)value.OwnedStars);
            bool claimed = (worldAchievementBitmap & (1 << index)) != 0;
            if (achievement == null || claimed || stars < achievement.Condition) return;
            InvokeLuaOrFail(onWorldAchievementClaim, "World.AchievementClaim", index);
        }

        public void SetWorldAchievementState(double type, double bitmap)
        {
            worldAchievementType = checked((byte)Math.Max(1, (int)type));
            worldAchievementBitmap = checked((byte)Math.Max(0, (int)bitmap));
            worldAchievementAuthoritativeResponse = true;
            RenderWorldAchievement();
        }

        public void ApplyWorldAchievementClaim(double index, double type, double bitmap, double rewardType, double amount)
        {
            SetWorldAchievementState(type, bitmap);
            RewardRecord reward = services.ShopCatalog.DescribeReward(checked((int)rewardType), 0,
                checked((uint)Math.Max(0, (long)amount)));
            ShowToast($"已领取 {reward.Name} ×{reward.Amount}", 2f);
        }

        private void RenderWorldAchievement()
        {
            if (worldAchievementView == null) return;
            IReadOnlyList<WorldAchievementDefinition> values = WorldVisualCatalog.GetAchievements(worldAchievementType);
            int stars = services.World.Chapters.Sum(value => (int)value.OwnedStars);
            int previousGoal = WorldVisualCatalog.GetAchievements(worldAchievementType - 1).LastOrDefault()?.Condition ?? 0;
            int finalGoal = values.Count > 0 ? values[values.Count - 1].Condition : Math.Max(1, stars);
            Text starText = worldAchievementView.FindNode(
                "Layer/zhuxianchengjiu_layer/jiangli_layer/xing/xing_num")?.GetComponent<Text>();
            if (starText != null) starText.text = $"{stars}/{finalGoal}";
            Text goal = worldAchievementView.FindNode(
                "Layer/zhuxianchengjiu_layer/jiangli_layer/yilingqu_0")?.GetComponent<Text>();
            if (goal != null)
            {
                goal.gameObject.SetActive(stars < finalGoal);
                goal.text = stars < finalGoal ? $"再获得 {finalGoal - stars} 星可完成本阶段" : string.Empty;
            }
            Image progress = worldAchievementView.FindNode(
                "Layer/zhuxianchengjiu_layer/jiangli_layer/bar_layer/EXPBar")?.GetComponent<Image>();
            if (progress != null)
            {
                progress.type = Image.Type.Filled;
                progress.fillMethod = Image.FillMethod.Horizontal;
                progress.fillOrigin = 0;
                progress.fillAmount = finalGoal <= previousGoal ? 1f
                    : Mathf.Clamp01((float)(stars - previousGoal) / (finalGoal - previousGoal));
            }
            for (int index = 1; index <= 6; index++)
            {
                string root = $"Layer/zhuxianchengjiu_layer/jiangli_layer/Item_layer/Item{index}";
                GameObject slot = worldAchievementView.FindNode(root);
                WorldAchievementDefinition achievement = index <= values.Count ? values[index - 1] : null;
                if (slot != null) slot.SetActive(achievement != null);
                if (achievement == null) continue;
                bool claimed = (worldAchievementBitmap & (1 << index)) != 0;
                bool claimable = !claimed && stars >= achievement.Condition;
                Text condition = worldAchievementView.FindNode(root + "/xingshu_layer/Num")?.GetComponent<Text>();
                if (condition != null) condition.text = achievement.Condition.ToString();
                GameObject claimedObject = worldAchievementView.FindNode(root + "/yilingqu");
                GameObject prompt = worldAchievementView.FindNode(root + "/Prompt");
                GameObject particle = worldAchievementView.FindNode(root + "/Particle_1");
                if (claimedObject != null) claimedObject.SetActive(claimed);
                if (prompt != null) prompt.SetActive(claimable);
                if (particle != null) particle.SetActive(claimable);
                Button button = slot?.GetComponent<Button>();
                if (button != null) button.interactable = claimable;
                RenderWorldRewardIcon(worldAchievementView.FindNode(root + "/bg_icon")?.transform,
                    DescribeWorldConfiguredReward(achievement.Reward));
            }
        }

        private void EnsureWorldOutcomePresenter()
        {
            EnsureWorldPresenter();
            worldSweepView = worldSweepView ?? services.UiRouter.FindByKey("saodangLayer");
            worldBattleResultView = worldBattleResultView ?? services.UiRouter.FindByKey("zhandoujiesuanLayer");
            worldBattleStatisticsView = worldBattleStatisticsView ?? services.UiRouter.FindByKey("zhandoutongji");
            UnityUiView statisticsFrameView = services.UiRouter.FindByKey("WorldBattleStatisticsFrame");
            GameObject statisticsFrameTemplate = statisticsFrameView?.FindNode("Layer/shopBg");
            if (worldSweepView == null || worldBattleResultView == null || worldBattleStatisticsView == null
                || statisticsFrameTemplate == null)
                throw new InvalidOperationException("Unity World result Prefabs were not found.");
            worldOutcomePresenter = worldOutcomePresenter ?? new WorldOutcomePresenter(worldView, worldSweepView,
                worldBattleResultView, worldBattleStatisticsView, statisticsFrameTemplate,
                services.Rewards, services.Resources, services.Player, services.Heroes,
                ActiveBattleReplayStore,
                () => InvokeLuaOrFail(onWorldSweep, "World.SweepAgain"),
                OnWorldBattleResultContinue,
                ReplayBattleOutcomeControl,
                ShowWorldBattleStatisticsUnavailable, ShowWorldBattleReviveUnavailable,
                controlId =>
                {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
                    if (services.Options.WorldBattleValidation) MarkValidationControl(controlId);
#endif
                });
            // 同步模式（结算层 C5/C12 依赖）
            worldOutcomePresenter.SetChainMode(worldChainMode);
            worldOutcomePresenter.SetReplayStore(ActiveBattleReplayStore);
        }

        private void EnsureWorldBattlePlaybackPresenter()
        {
            EnsureWorldPresenter();
            Transform overlayParent = worldView.GameObject.transform.parent ?? worldView.GameObject.transform;
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            bool automatedBattleValidation = services.Options.BattleFengShenStoryValidation
                || services.Options.WorldBattleValidation;
#else
            const bool automatedBattleValidation = false;
#endif
            if (battlePlaybackContext == BattlePlaybackContext.FengShenStory)
            {
                fengShenBattlePlaybackView = fengShenBattlePlaybackView
                    ?? services.UiAssets.InstantiateUnity("BattleFightLayer", overlayParent);
                fengShenBattlePlaybackPresenter = fengShenBattlePlaybackPresenter ?? new WorldBattlePlaybackPresenter(
                    overlayParent, services.FengShenBattleReplay, services.Resources, services.UiAssets,
                    fengShenBattlePlaybackView,
                    message => ShowToast(message, 2f),
                    automatedBattleValidation ? null : (Func<int>)LoadWorldBattleSpeedStep,
                    automatedBattleValidation ? null : (Action<int>)SaveWorldBattleSpeedStep);
                worldBattlePlaybackPresenter = fengShenBattlePlaybackPresenter;
                return;
            }
            if (battlePlaybackContext == BattlePlaybackContext.Monopoly)
            {
                monopolyBattlePlaybackView = monopolyBattlePlaybackView
                    ?? services.UiAssets.InstantiateUnity("BattleFightLayer", overlayParent);
                monopolyBattlePlaybackPresenter = monopolyBattlePlaybackPresenter ?? new WorldBattlePlaybackPresenter(
                    overlayParent, services.MonopolyBattleReplay, services.Resources, services.UiAssets,
                    monopolyBattlePlaybackView,
                    message => ShowToast(message, 2f),
                    automatedBattleValidation ? null : (Func<int>)LoadWorldBattleSpeedStep,
                    automatedBattleValidation ? null : (Action<int>)SaveWorldBattleSpeedStep);
                worldBattlePlaybackPresenter = monopolyBattlePlaybackPresenter;
                return;
            }
            worldBattlePlaybackView = worldBattlePlaybackView
                ?? services.UiAssets.InstantiateUnity("BattleFightLayer", overlayParent);
            worldBattleWorldPresenter = worldBattleWorldPresenter ?? new WorldBattlePlaybackPresenter(
                overlayParent, services.WorldBattleReplay, services.Resources, services.UiAssets,
                worldBattlePlaybackView,
                message => ShowToast(message, 2f),
                automatedBattleValidation ? null : (Func<int>)LoadWorldBattleSpeedStep,
                automatedBattleValidation ? null : (Action<int>)SaveWorldBattleSpeedStep);
            worldBattlePlaybackPresenter = worldBattleWorldPresenter;
        }

        private string WorldBattleSpeedPreferenceKey()
            => $"ProjectX.WorldBattle.SpeedStep.{services.Player.RoleId}";

        private int LoadWorldBattleSpeedStep()
            => Mathf.Clamp(PlayerPrefs.GetInt(WorldBattleSpeedPreferenceKey(), 0), 0, 5);

        private void SaveWorldBattleSpeedStep(int value)
        {
            PlayerPrefs.SetInt(WorldBattleSpeedPreferenceKey(), Mathf.Clamp(value, 0, 5));
            PlayerPrefs.Save();
        }

    }
}
