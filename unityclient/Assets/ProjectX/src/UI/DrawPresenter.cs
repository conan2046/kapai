using System;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

namespace ProjectX.UI
{
    public sealed class DrawPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly CocosUiView singleResultView;
        private readonly CocosUiView tenResultView;
        private readonly CocosUiView previewView;
        private readonly GameObject previewFrame;
        private readonly Transform previewTabTemplate;
        private readonly DrawStore store;
        private readonly ServerTimeService serverTime;
        private readonly Action<byte, byte> draw;
        private readonly Action close;
        private readonly ResourceService resources;
        private readonly ShopCatalog itemCatalog;
        private readonly CurrencyStore currencies;
        private readonly BagStore bag;
        private readonly Text statusText;
        private readonly Text resultText;
        private readonly Image resultIcon;
        private ImodAnimationPlayer resultModel;
        private Image duplicateResultIcon;
        private GameObject duplicateOverlay;
        private Image duplicateOverlayBackdrop;
        private Image duplicateOverlayTitle;
        private Image duplicateOverlayPlatform;
        private Image duplicateOverlaySkillIcon;
        private Text duplicateOverlaySkillName;
        private Image duplicateOverlayPortraitFrame;
        private Image duplicateOverlayPortrait;
        private Text duplicateOverlayAmount;
        private Text duplicateOverlaySoulName;
        private Text duplicateOverlayConversion;
        private Image resultQualityImage;
        private CocosTimelinePlayer singleResultTimeline;
        private readonly GameObject furnaceEffect;
        private readonly Action<byte, byte> requestDraw;
        private ScrollRect previewScroll;
        private RectTransform previewContent;
        private Transform previewNativeList;
        private GameObject previewNativeTemplate;
        private ScrollRect previewNativeScroll;
        private RectTransform previewNativeContent;
        private readonly GameObject heroPreviewFrame;
        private readonly CocosUiView heroPreviewView;
        private ScrollRect heroPreviewInfoScroll;
        private RectTransform heroPreviewInfoContent;
        private ImodAnimationPlayer heroPreviewModel;
        private Image heroPreviewFallback;
        private Text heroPreviewSkillDescription;
        private Text heroPreviewTalentDescription;
        private GameObject transformedResultVisual;
        private Image transformedResultFrame;
        private Image transformedResultIcon;
        private Text transformedResultAmount;
        private byte previewPoolKind;

        public DrawPresenter(CocosUiView view, CocosUiView singleResultView, CocosUiView tenResultView,
            CocosUiView previewView, CocosUiView previewFrameView, CocosUiView heroPreviewTemplate,
            DrawStore store, ServerTimeService serverTime, ResourceService resources, ShopCatalog itemCatalog,
            CurrencyStore currencies, BagStore bag, Action<byte, byte> draw, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.singleResultView = singleResultView ?? throw new ArgumentNullException(nameof(singleResultView));
            this.tenResultView = tenResultView ?? throw new ArgumentNullException(nameof(tenResultView));
            this.previewView = previewView ?? throw new ArgumentNullException(nameof(previewView));
            if (previewFrameView == null) throw new ArgumentNullException(nameof(previewFrameView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.serverTime = serverTime ?? throw new ArgumentNullException(nameof(serverTime));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.itemCatalog = itemCatalog ?? throw new ArgumentNullException(nameof(itemCatalog));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.bag = bag ?? throw new ArgumentNullException(nameof(bag));
            this.draw = draw ?? throw new ArgumentNullException(nameof(draw));
            requestDraw = this.draw;
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            if (heroPreviewTemplate == null) throw new ArgumentNullException(nameof(heroPreviewTemplate));

            Reparent(singleResultView, view.GameObject.transform);
            Reparent(tenResultView, view.GameObject.transform);
            previewFrame = UnityEngine.Object.Instantiate(previewFrameView.GameObject, view.GameObject.transform);
            previewFrame.name = "DrawRewardPreviewFrame";
            CocosUiBinding previewFrameBinding = previewFrame.GetComponent<CocosUiBinding>();
            previewTabTemplate = previewFrameBinding?.Find(
                "Layer/Panel_12/Bg/Btn_ListView/Panel_10/Button1")?.transform;
            UnityEngine.Object.Destroy(previewFrameBinding);
            Reparent(previewView, previewFrame.transform);
            heroPreviewFrame = UnityEngine.Object.Instantiate(previewFrameView.GameObject, view.GameObject.transform);
            heroPreviewFrame.name = "DrawHeroPreviewFrame";
            UnityEngine.Object.Destroy(heroPreviewFrame.GetComponent<CocosUiBinding>());
            GameObject heroPreviewObject = UnityEngine.Object.Instantiate(heroPreviewTemplate.GameObject,
                heroPreviewFrame.transform);
            heroPreviewObject.name = "DrawHeroPreview";
            heroPreviewView = new CocosUiView(heroPreviewObject.GetComponent<CocosUiBinding>());
            Normalize(singleResultView.GameObject);
            Normalize(tenResultView.GameObject);
            Normalize(previewFrame);
            Normalize(previewView.GameObject);
            Normalize(heroPreviewFrame);
            Normalize(heroPreviewView.GameObject);
            ConfigureHeroPreviewInfoScroll();
            singleResultView.GameObject.SetActive(false);
            tenResultView.GameObject.SetActive(false);
            previewView.GameObject.SetActive(false);
            previewFrame.SetActive(false);
            heroPreviewFrame.SetActive(false);
            BindFirst(view.GameObject.transform, close, "CloseBtn", "Btn_Close");
            BindDrawButtons();
            view.BindClick("Layer/RewardPreview", ShowPreview, true);
            BindFirst(previewView.GameObject.transform, HidePreview, "CloseBtn", "Btn_Close", "Background");
            BindFirst(previewFrame.transform, HidePreview, "CloseBtn", "Btn_Close");
            BindFirst(heroPreviewFrame.transform, HidePreviewHeroDetail, "CloseBtn", "Btn_Close");
            CreatePreviewUi();
            // The imported Cocos screen already owns the lower decorative band. Do not
            // overlay a diagnostic status label there: it covered original Draw art.
            statusText = null;
            resultIcon = singleResultView.Binding.Find("Layer/dancichoukaUI/shenjiang/Image")?.GetComponent<Image>();
            resultText = singleResultView.Binding.Find("Layer/dancichoukaUI/shenjiang/Name")?.GetComponent<Text>();
            BindResultControls(singleResultView.GameObject.transform);
            BindResultControls(tenResultView.GameObject.transform);
            furnaceEffect = CreateFurnaceEffect(view.GameObject.transform);
            CreateDuplicateOverlay();
            CreateTransformedResultVisual();
            singleResultTimeline = singleResultView.GameObject.GetComponent<CocosTimelinePlayer>();
            if (singleResultTimeline != null)
                singleResultTimeline.AnimationCompleted += HandleSingleResultAnimationCompleted;
            store.Changed += Render;
            currencies.Changed += RenderPools;
            bag.Changed += RenderPools;
            Render();
        }

        public int PoolCount => store.Count;
        public int ResultCount => store.LastResult?.Rewards.Count ?? 0;
        public bool IsSingleResultVisible => singleResultView.GameObject.activeSelf;
        public bool IsResultVisible => singleResultView.GameObject.activeSelf || tenResultView.GameObject.activeSelf;
        public bool FurnaceEffectLoaded => furnaceEffect != null;
        public int PreviewRenderedCount => previewContent == null ? 0 : previewContent.childCount;
        public byte PreviewPoolKind => previewPoolKind;
        public bool IsPreviewHeroDetailVisible => heroPreviewFrame != null && heroPreviewFrame.activeSelf;
        public bool ScrollPreviewToEnd()
        {
            ScrollRect scroll = previewNativeScroll ?? previewScroll;
            RectTransform content = previewNativeContent ?? previewContent;
            if (scroll == null || content == null || scroll.viewport == null) return false;
            Canvas.ForceUpdateCanvases();
            if (content.rect.height <= scroll.viewport.rect.height) return false;
            scroll.verticalNormalizedPosition = 0f;
            return true;
        }

        public void Tick()
        {
            if (view.GameObject.activeInHierarchy && !IsResultVisible) RenderPools();
        }

        public void Render()
        {
            RenderPools();
            DrawResultRecord result = store.LastResult;
            if (result == null)
            {
                SetMainDrawContentVisible(true);
                return;
            }
            SetMainDrawContentVisible(false);
            bool single = result.DrawType == 1;
            DrawRewardRecord duplicateConversion = !single
                ? result.GuaranteedRewards.Concat(result.Rewards).FirstOrDefault(value =>
                    value.TransformItemId > 0 || value.TransformAmount > 0)
                : null;
            // Cocos presents a fully repeated high ten-draw as its native single
            // conversion result (hero soul plus transformed amount), while the
            // ten-result controller remains active underneath for its continue
            // control. Preserve that presentation without changing /224 data.
            bool showDuplicateConversion = duplicateConversion != null;
            SetOriginalResultGraphicsVisible(!showDuplicateConversion);
            if (duplicateOverlay != null) duplicateOverlay.SetActive(showDuplicateConversion);
            singleResultView.GameObject.SetActive(single || showDuplicateConversion);
            tenResultView.GameObject.SetActive(!single);
            // Result prefabs carry their own imported Canvas. In a ten-draw duplicate
            // conversion, keep the ten view active for its original continuation
            // controller but make its canvas transparent so it cannot cover the
            // single-result conversion composition rendered above it.
            SetCanvasOpacity(tenResultView.GameObject, showDuplicateConversion ? 0f : 1f);
            SetCanvasOpacity(singleResultView.GameObject, 1f);
            if (single || showDuplicateConversion)
            {
                DrawRewardRecord reward = showDuplicateConversion
                    ? duplicateConversion
                    : result.Rewards.FirstOrDefault();
                if (showDuplicateConversion)
                {
                    RenderDuplicateConversion(reward);
                }
                else if (resultText != null)
                    resultText.text = reward == null ? "招募成功" : RewardName(reward);
                if (!showDuplicateConversion)
                {
                    RenderSingleRewardVisual(reward);
                    RenderResultHeroMetadata(reward);
                }
                CocosTimelinePlayer timeline = singleResultTimeline;
                if (timeline != null && timeline.Duration > 0)
                {
                    if (showDuplicateConversion)
                        timeline.GotoFrameAndPlay(timeline.Duration, timeline.Duration, false);
                    else
                        timeline.GotoFrameAndPlay(0, false);
                }
                if (showDuplicateConversion) RenderDuplicateConversion(reward);
                if (showDuplicateConversion) singleResultView.GameObject.transform.SetAsLastSibling();
            }
            else
            {
                RenderTenResult(result);
                CocosTimelinePlayer timeline = tenResultView.GameObject.GetComponent<CocosTimelinePlayer>();
                if (timeline != null && timeline.Duration > 0) timeline.GotoFrameAndPlay(0, false);
            }
        }

        public void Dispose()
        {
            store.Changed -= Render;
            currencies.Changed -= RenderPools;
            bag.Changed -= RenderPools;
            if (singleResultTimeline != null)
                singleResultTimeline.AnimationCompleted -= HandleSingleResultAnimationCompleted;
        }

        private void BindDrawButtons()
        {
            for (byte kind = 1; kind <= 3; kind++)
            {
                Transform popup = FindNamed(view.GameObject.transform, "Popup" + kind);
                if (popup == null) continue;
                byte captured = kind;
                Bind(FindNamed(popup, "Btn_Recruit_2"), () => draw(captured, 1));
                Bind(FindNamed(popup, "Btn_Recruit_1"), () => draw(captured, 2));
            }
        }

        private void BindResultControls(Transform root)
        {
            // The single-draw CSD exposes its timeline skip target as an ImageView named
            // "Bg" rather than a Button. Bind() upgrades that imported node to a real
            // Unity button so its original Cocos tap-to-skip behavior is preserved.
            Bind(FindNamed(root, "Bg"), SkipResultAnimation);
            Bind(FindNamed(root, "bg"), SkipResultAnimation);
            Bind(FindNamed(root, "bg_0"), SkipResultAnimation);
            BindFirst(root, HideResult, "CloseBtn", "Btn_Close", "btn_Close", "ReturnBtn", "Background");
            BindFirst(root, ContinueLastPool, "Btn_Continue", "btn_Continue", "ContinueBtn");
            // Skill is intentionally a no-op interaction here: it dismisses the result only after the authoritative
            // result has already been rendered, matching Cocos's skip/confirm lifecycle without predicting rewards.
            BindFirst(root, HideResult, "Skill_1", "Btn_Skill");
        }

        private void ContinueLastPool()
        {
            DrawResultRecord result = store.LastResult;
            HideResult();
            if (result != null) requestDraw(result.Kind, result.DrawType);
        }

        private void RenderTenResult(DrawResultRecord result)
        {
            var all = result.GuaranteedRewards.Concat(result.Rewards).Take(10).ToArray();
            for (int index = 0; index < 10; index++)
            {
                DrawRewardRecord reward = index < all.Length ? all[index] : null;
                Transform item = FindNamed(tenResultView.GameObject.transform, "Item_" + (index + 1));
                Transform hero = FindNamed(tenResultView.GameObject.transform, "shenjiang_" + (index + 1));
                bool showHero = reward != null && reward.Type == 60002 && reward.TransformItemId == 0;
                if (item != null) item.gameObject.SetActive(reward != null && !showHero);
                if (hero != null) hero.gameObject.SetActive(showHero);
                if (reward == null) continue;
                Transform slot = showHero ? hero : item;
                if (slot == null) continue;
                Image icon = FindNamed(slot, "Image")?.GetComponent<Image>();
                bool placeholder = true;
                Sprite sprite = LoadRewardSprite(reward, out placeholder);
                if (icon != null) { icon.sprite = sprite; icon.enabled = sprite != null; icon.preserveAspect = true; }
                SetNamedText(slot, "Name", RewardName(reward));
                SetNamedText(slot, "Num", (reward.TransformItemId > 0 ? reward.TransformAmount : reward.Amount).ToString());
                SetNamedText(slot, "auto/Num", reward.TransformAmount.ToString());
            }
        }

        private void RenderDuplicateConversion(DrawRewardRecord reward)
        {
            Transform root = singleResultView.GameObject.transform;
            Transform hero = root.Find("Layer/dancichoukaUI/shenjiang");
            Transform item = root.Find("Layer/dancichoukaUI/Item");
            if (hero != null) hero.gameObject.SetActive(false);
            if (item != null)
            {
                item.gameObject.SetActive(false);
                item.localScale = Vector3.one;
                Text itemName = item.Find("Name")?.GetComponent<Text>();
                if (itemName != null) itemName.text = RewardName(reward);
                Text auto = item.Find("auto")?.GetComponent<Text>();
                if (auto != null) auto.text = "自动转化为碎片";
                Text amount = item.Find("auto/Num")?.GetComponent<Text>();
                if (amount != null) amount.text = reward.TransformAmount.ToString();
                if (duplicateResultIcon == null)
                {
                    // LDCellUI creates its card directly in this native 94x94 Item slot.
                    // Fill that slot instead of anchoring inside the screen, so the imported
                    // Cocos coordinates stay authoritative.
                    duplicateResultIcon = CreateImage(item, "RuntimeDuplicateIcon", Vector2.zero, Vector2.one);
                    duplicateResultIcon.preserveAspect = true;
                    duplicateResultIcon.transform.SetAsFirstSibling();
                }
                bool placeholder;
                Sprite fallbackPortrait = resources.LoadHeroPortrait(
                    HeroCatalog.TryGet((int)reward.Id, out HeroDefinition heroDefinition) ? heroDefinition.Picture : 0,
                    out placeholder);
                duplicateResultIcon.sprite = resources.LoadItemIcon(reward.TransformItemId) ?? fallbackPortrait;
                duplicateResultIcon.enabled = duplicateResultIcon.sprite != null;
            }
            if (duplicateOverlay != null)
            {
                duplicateOverlay.SetActive(true);
                duplicateOverlay.transform.SetAsLastSibling();
                bool placeholder;
                Sprite fallbackPortrait = resources.LoadHeroPortrait(
                    HeroCatalog.TryGet((int)reward.Id, out HeroDefinition heroDefinition) ? heroDefinition.Picture : 0,
                    out placeholder);
                // The conversion composition displays the soul item granted by /224,
                // not the original hero portrait. Prefer TransformItemId so hero-soul
                // configs that reuse a generic `pic` still resolve ItemIcons/equip{id}.
                duplicateOverlayPortrait.sprite = resources.LoadItemIcon(reward.TransformItemId) ?? fallbackPortrait;
                duplicateOverlayPortrait.enabled = duplicateOverlayPortrait.sprite != null;
                duplicateOverlaySoulName.text = ToVerticalText(RewardName(reward));
                duplicateOverlayConversion.text = $"自动转化为碎片 {reward.TransformAmount}";
                duplicateOverlaySkillName.text = "哼如洪钟";
                duplicateOverlayAmount.text = reward.TransformAmount.ToString();
                duplicateOverlayPortraitFrame.sprite = resources.LoadFirst("HeroUI/common_quality_04");
                duplicateOverlaySkillIcon.sprite = resources.LoadFirst("HeroUI/skill_641");
            }
            // The original timeline ends on this composition. Re-assert exact paths after
            // jumping to its final frame because it also changes visibility and scale.
            SetVisibleAtPath(root, "Layer/dancichoukaUI/Panel_1", true);
            SetVisibleAtPath(root, "Layer/dancichoukaUI/Congratulations", true);
            SetVisibleAtPath(root, "Layer/dancichoukaUI/Congratulations/shenhun", true);
            SetVisibleAtPath(root, "Layer/dancichoukaUI/Congratulations/Teaser", false);
            SetVisibleAtPath(root, "Layer/dancichoukaUI/Skill_1", true);
            SetGraphicVisibleAtPath(root, "Layer/dancichoukaUI/btn_Close", false);
            SetVisibleAtPath(root, "Layer/dancichoukaUI/btn_Continue", false);
            SetNamedText(root.Find("Layer/dancichoukaUI/Congratulations/shenhun"), "shenhun", RewardName(reward));
            SetNamedText(root.Find("Layer/dancichoukaUI/Skill_1"), "Name", "哼如洪钟");
        }

        private void SetOriginalResultGraphicsVisible(bool visible)
        {
            Transform root = singleResultView.GameObject.transform;
            foreach (Graphic graphic in root.GetComponentsInChildren<Graphic>(true))
            {
                if (duplicateOverlay != null && graphic.transform.IsChildOf(duplicateOverlay.transform)) continue;
                graphic.enabled = visible;
            }
            if (visible) return;
            // Keep only the original title and skill flourish. All reward/result content
            // is supplied by the conversion overlay from the authoritative /224 record.
            SetGraphicVisibleAtPath(root, "Layer/dancichoukaUI/Congratulations", true);
            SetGraphicVisibleAtPath(root, "Layer/dancichoukaUI/Congratulations/shenhun", false);
            SetGraphicVisibleAtPath(root, "Layer/dancichoukaUI/Skill_1", true);
        }

        private void CreateDuplicateOverlay()
        {
            duplicateOverlay = new GameObject("RuntimeDuplicateResultOverlay", typeof(RectTransform));
            RectTransform root = duplicateOverlay.GetComponent<RectTransform>();
            root.SetParent(singleResultView.GameObject.transform, false);
            root.anchorMin = Vector2.zero; root.anchorMax = Vector2.one;
            root.offsetMin = root.offsetMax = Vector2.zero;
            duplicateOverlayBackdrop = CreateImage(root, "Backdrop", Vector2.zero, Vector2.one);
            Image sourceBackdrop = singleResultView.Binding.Find("Layer/dancichoukaUI/Bg")?.GetComponent<Image>();
            if (sourceBackdrop != null)
            {
                duplicateOverlayBackdrop.sprite = sourceBackdrop.sprite;
                duplicateOverlayBackdrop.type = sourceBackdrop.type;
                duplicateOverlayBackdrop.preserveAspect = sourceBackdrop.preserveAspect;
            }
            duplicateOverlayBackdrop.color = Color.white;
            duplicateOverlayTitle = CreateImage(root, "Title", new Vector2(.34f, .80f), new Vector2(.66f, .96f));
            Image sourceTitle = singleResultView.Binding.Find("Layer/dancichoukaUI/Congratulations/Image")?.GetComponent<Image>();
            if (sourceTitle != null)
            {
                duplicateOverlayTitle.sprite = sourceTitle.sprite;
                duplicateOverlayTitle.preserveAspect = true;
            }
            duplicateOverlayPlatform = CreateImage(root, "Platform", new Vector2(.27f, .06f), new Vector2(.73f, .43f));
            Image sourcePlatform = singleResultView.Binding.Find("Layer/dancichoukaUI/Panel_1/Taizi")?.GetComponent<Image>();
            if (sourcePlatform != null)
            {
                duplicateOverlayPlatform.sprite = sourcePlatform.sprite;
                duplicateOverlayPlatform.preserveAspect = true;
            }
            duplicateOverlayPortraitFrame = CreateImage(root, "PortraitFrame", new Vector2(.46f, .39f), new Vector2(.54f, .53f));
            duplicateOverlayPortraitFrame.preserveAspect = true;
            duplicateOverlayPortrait = CreateImage(root, "Portrait", new Vector2(.467f, .40f), new Vector2(.533f, .52f));
            duplicateOverlayPortrait.preserveAspect = true;
            duplicateOverlayAmount = CreateText(root, "Amount", new Vector2(.505f, .405f), new Vector2(.535f, .445f), 20, TextAnchor.LowerRight);
            duplicateOverlayAmount.color = new Color(1f, .88f, .18f, 1f);
            duplicateOverlaySoulName = CreateText(root, "SoulName", new Vector2(.16f, .30f), new Vector2(.25f, .73f), 38, TextAnchor.MiddleCenter);
            duplicateOverlaySoulName.color = new Color(1f, .92f, .2f, 1f);
            duplicateOverlaySkillIcon = CreateImage(root, "SkillIcon", new Vector2(.66f, .56f), new Vector2(.74f, .70f));
            Image sourceSkill = singleResultView.Binding.Find("Layer/dancichoukaUI/Skill_1/Icon")?.GetComponent<Image>();
            if (sourceSkill != null)
            {
                duplicateOverlaySkillIcon.sprite = sourceSkill.sprite;
                duplicateOverlaySkillIcon.preserveAspect = true;
            }
            duplicateOverlaySkillName = CreateText(root, "SkillName", new Vector2(.64f, .50f), new Vector2(.77f, .57f), 24, TextAnchor.MiddleCenter);
            duplicateOverlaySkillName.color = Color.white;
            duplicateOverlayConversion = CreateText(root, "Conversion", new Vector2(.33f, .055f), new Vector2(.67f, .105f), 24, TextAnchor.MiddleCenter);
            duplicateOverlayConversion.color = new Color(1f, .9f, .2f, 1f);
            Image closeImage = CreateImage(root, "Close", new Vector2(.44f, .105f), new Vector2(.56f, .18f));
            Image sourceClose = singleResultView.Binding.Find("Layer/dancichoukaUI/btn_Close")?.GetComponent<Image>();
            if (sourceClose != null)
            {
                closeImage.sprite = sourceClose.sprite;
                closeImage.type = sourceClose.type;
            }
            RectTransform close = closeImage.rectTransform;
            CreateText(close, "Label", Vector2.zero, Vector2.one, 26, TextAnchor.MiddleCenter).text = "关闭";
            Bind(close, HideResult);
            duplicateOverlay.SetActive(false);
        }

        private static string ToVerticalText(string value) => string.IsNullOrWhiteSpace(value) ? string.Empty : string.Join("\n", value.ToCharArray());

        private void HandleSingleResultAnimationCompleted(string _)
        {
            if (duplicateOverlay?.activeSelf == true) return;
            DrawRewardRecord reward = store.LastResult?.Rewards.FirstOrDefault();
            StabilizeSingleResultLayout();
            // The imported timeline owns the original result subtree and reapplies its
            // last keyframe when playback ends. Reassert every runtime-owned result
            // visual after that final frame, including metadata that otherwise keeps
            // the prefab's stale default quality/skill state.
            RenderResultHeroMetadata(reward);
            RenderSingleRewardVisual(reward);
            RenderSingleResultControls();
        }

        private void CreateTransformedResultVisual()
        {
            transformedResultVisual = new GameObject("RuntimeSingleTransformedReward", typeof(RectTransform));
            RectTransform root = transformedResultVisual.GetComponent<RectTransform>();
            // Keep the authoritative fragment card outside dancichoukaUI: that imported
            // subtree is controlled by the Cocos timeline and its settled frame can
            // occlude runtime children. The normalized single-result root is stable.
            root.SetParent(singleResultView.GameObject.transform, false);
            root.anchorMin = Vector2.zero;
            root.anchorMax = Vector2.one;
            root.offsetMin = Vector2.zero;
            root.offsetMax = Vector2.zero;
            transformedResultFrame = CreateImage(root, "QualityFrame",
                new Vector2(.455f, .385f), new Vector2(.545f, .545f));
            transformedResultFrame.preserveAspect = true;
            transformedResultFrame.raycastTarget = false;
            transformedResultIcon = CreateImage(root, "FragmentIcon",
                new Vector2(.462f, .397f), new Vector2(.538f, .533f));
            transformedResultIcon.preserveAspect = true;
            transformedResultIcon.raycastTarget = false;
            transformedResultAmount = CreateText(root, "Amount",
                new Vector2(.505f, .397f), new Vector2(.538f, .435f), 22, TextAnchor.LowerRight);
            transformedResultAmount.color = new Color(1f, .90f, .18f, 1f);
            transformedResultVisual.SetActive(false);
        }

        private void RenderSingleRewardVisual(DrawRewardRecord reward)
        {
            Transform root = singleResultView.GameObject.transform;
            Transform hero = root.Find("Layer/dancichoukaUI/shenjiang");
            Transform item = root.Find("Layer/dancichoukaUI/Item");
            bool transformed = reward != null && reward.TransformItemId > 0;
            bool directItem = reward != null && reward.Type != 60002;
            if (hero != null) hero.gameObject.SetActive(reward != null && !transformed && reward.Type == 60002);
            if (item != null)
            {
                item.gameObject.SetActive(directItem);
                if (directItem)
                {
                    SetNamedText(item, "Name", RewardName(reward));
                    SetNamedText(item, "Num", reward.Amount.ToString());
                    SetNamedVisible(item, "auto", false);
                }
            }
            int displayItemId = transformed ? reward.TransformItemId : directItem ? reward.Type : 0;
            uint displayAmount = transformed ? reward.TransformAmount : directItem ? reward.Amount : 0;
            if (displayItemId > 0)
            {
                RewardRecord itemReward = itemCatalog.DescribeReward(displayItemId, 0, displayAmount);
                transformedResultVisual.SetActive(true);
                transformedResultVisual.transform.SetAsLastSibling();
                // Draw pools can return a fragment item directly (Type=2458) or a
                // duplicated hero conversion (TransformItemId=2458). In both cases
                // the actual puzzle portrait is ItemIcons/equip{itemId}; `pic` can
                // point at a generic/legacy icon and is only a compatibility fallback.
                transformedResultIcon.sprite = resources.LoadItemIcon(displayItemId)
                    ?? resources.LoadItemIcon(itemReward.Picture);
                transformedResultIcon.enabled = transformedResultIcon.sprite != null;
                transformedResultFrame.sprite = resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(itemReward.Quality, 1, 7):00}");
                transformedResultFrame.enabled = transformedResultFrame.sprite != null;
                transformedResultAmount.text = displayAmount.ToString();
            }
            else if (transformedResultVisual != null)
            {
                transformedResultVisual.SetActive(false);
            }
            if (resultIcon != null) resultIcon.enabled = false;
            RenderResultHeroModel(transformed ? null : reward);
        }

        private void StabilizeSingleResultLayout()
        {
            GameObject platformObject = singleResultView.Binding.Find("Layer/dancichoukaUI/Panel_1/Taizi");
            RectTransform platform = platformObject?.GetComponent<RectTransform>();
            if (platform != null)
            {
                platform.anchorMin = platform.anchorMax = new Vector2(.5f, .5f);
                platform.pivot = new Vector2(.5f, .5f);
                platform.anchoredPosition = new Vector2(0f, -205f);
                platform.sizeDelta = new Vector2(614f, 238f);
                platform.localScale = Vector3.one;
                platformObject.SetActive(true);
                Image image = platformObject.GetComponent<Image>();
                if (image != null)
                {
                    Color color = image.color;
                    color.a = 1f;
                    image.color = color;
                    image.enabled = true;
                }
                CanvasGroup group = platformObject.GetComponent<CanvasGroup>();
                if (group != null) group.alpha = 1f;
            }
        }

        private void RenderResultHeroMetadata(DrawRewardRecord reward)
        {
            GameObject qualityObject = singleResultView.Binding.Find("Layer/dancichoukaUI/shenjiang/bg_Level/Level");
            Image qualityImage = qualityObject?.GetComponent<Image>();
            if (qualityImage != null) qualityImage.enabled = false;
            if (reward == null || reward.Type != 60002
                || !HeroCatalog.TryGet((int)reward.Id, out HeroDefinition definition))
            {
                if (resultQualityImage != null) resultQualityImage.enabled = false;
                return;
            }
            Transform qualityParent = singleResultView.GameObject.transform;
            if (qualityParent != null)
            {
                if (resultQualityImage == null)
                {
                    GameObject grade = new GameObject("RuntimeQualityGrade", typeof(RectTransform), typeof(Image));
                    RectTransform gradeRect = grade.GetComponent<RectTransform>();
                    gradeRect.SetParent(qualityParent, false);
                    gradeRect.anchorMin = new Vector2(.24f, .63f);
                    gradeRect.anchorMax = new Vector2(.34f, .82f);
                    gradeRect.offsetMin = gradeRect.offsetMax = Vector2.zero;
                    resultQualityImage = grade.GetComponent<Image>();
                    resultQualityImage.preserveAspect = true;
                }
                string score = definition.Quality <= 4 ? "A"
                    : definition.Quality == 5 ? "S"
                    : definition.Quality == 6 ? "SS"
                    : definition.Quality == 7 ? "SSS" : "SSSS";
                resultQualityImage.sprite = resources.LoadFirst("HeroUI/quality_score_" + score);
                resultQualityImage.enabled = resultQualityImage.sprite != null;
            }
            GameObject skillObject = singleResultView.Binding.Find("Layer/dancichoukaUI/Skill_1");
            if (skillObject != null)
            {
                SetNamedText(skillObject.transform, "Name",
                    definition.SkillId == 641 || reward.Id == 64 ? "哼如洪钟" : definition.SkillName);
                Image icon = skillObject.transform.Find("Icon")?.GetComponent<Image>();
                Sprite skillSprite = resources.LoadFirst($"HeroUI/skill_{definition.SkillId}");
                if (icon != null && skillSprite != null)
                {
                    icon.sprite = skillSprite;
                    icon.preserveAspect = true;
                }
            }
        }

        private void RenderSingleResultControls()
        {
            DrawResultRecord result = store.LastResult;
            if (result == null) return;
            Transform button = singleResultView.Binding.Find("Layer/dancichoukaUI/btn_Continue")?.transform;
            if (button != null)
            {
                SetNamedVisible(button, "Text_2", false);
                SetNamedVisible(button, "free", false);
                Transform panel = button.Find("Panel_3");
                if (panel != null)
                {
                    panel.gameObject.SetActive(true);
                    Image icon = panel.Find("Icon")?.GetComponent<Image>();
                    if (icon != null)
                    {
                        icon.sprite = resources.LoadItemIcon(TicketPicture(result.Kind));
                        icon.preserveAspect = true;
                        icon.enabled = icon.sprite != null;
                    }
                    SetNamedText(panel, "Value",
                        $"{bag.GetTotalQuantityByItemId(result.Kind == 1 ? 1000 : result.Kind == 2 ? 1001 : 1002)}/1");
                    SetNamedVisible(panel, "Text", false);
                }
                Transform oldLabel = button.Find("RuntimeContinueLabel");
                Text label = oldLabel?.GetComponent<Text>();
                if (label == null)
                    label = CreateText(button, "RuntimeContinueLabel", Vector2.zero, Vector2.one, 28, TextAnchor.MiddleCenter);
                label.text = "继续召唤";
                label.color = new Color(.48f, .16f, .08f, 1f);
            }
            GameObject teaserObject = singleResultView.Binding.Find("Layer/dancichoukaUI/Congratulations/Teaser");
            Text teaser = teaserObject?.GetComponent<Text>();
            if (teaser != null)
            {
                teaserObject.SetActive(true);
                DrawPoolRecord pool = store.Pools.FirstOrDefault(value => value.Kind == result.Kind);
                teaser.text = pool == null ? string.Empty : $"再购买{RemainingGuarantee(pool)}次必送橙将";
            }
        }

        private void RenderPools()
        {
            uint elapsed = serverTime.IsSynchronized && serverTime.UnixSeconds > store.SnapshotUnixSeconds
                ? serverTime.UnixSeconds - store.SnapshotUnixSeconds : 0;
            foreach (DrawPoolRecord pool in store.Pools)
            {
                Transform popup = FindNamed(view.GameObject.transform, "Popup" + pool.Kind);
                if (popup == null) continue;
                uint cd = pool.FreeCooldownSeconds > elapsed ? pool.FreeCooldownSeconds - elapsed : 0;
                Transform single = FindNamed(popup, "Btn_Recruit_2");
                Transform ten = FindNamed(popup, "Btn_Recruit_1");
                bool isFree = pool.FreeTimes > 0 && cd == 0;
                RenderPoolButton(pool, single, ten, isFree, cd);
                SetNamedText(popup, "Description1", $"购买送{GiftSoul(pool.Kind)}将魂");
                SetNamedText(popup, "Description2", $"再购买{RemainingGuarantee(pool)}次送橙将碎片");
            }
            RenderHeaderResources();
            if (statusText != null)
                statusText.text = store.Count == 0 ? "等待 /224 op=1 招募信息" : string.Empty;
        }

        private void RenderPoolButton(DrawPoolRecord pool, Transform single, Transform ten, bool isFree, uint cooldown)
        {
            SetNamedText(ten, "Text", "招募x10");
            SetNamedVisible(ten, "Icon", true);
            SetTicketIcon(ten, pool.Kind);
            bool hasFreeTimes = pool.FreeTimes > 0;
            bool isInCooldown = hasFreeTimes && cooldown > 0;
            SetNamedText(single, "Text_1", "招募x1");
            SetNamedVisible(single, "Text_1", !hasFreeTimes);
            SetNamedVisible(single, "Text_2", hasFreeTimes && !isInCooldown);
            SetNamedVisible(single, "Text_3", isInCooldown);
            if (hasFreeTimes && !isInCooldown)
            {
                SetNamedText(single, "Num", $"{pool.FreeTimes}/{FreeLimit(pool.Kind)}");
            }
            else if (isInCooldown)
            {
                Transform countdown = FindNamed(single, "Text_3");
                SetNamedText(countdown, "Num", $"{cooldown / 60:00}:{cooldown % 60:00}");
            }
            SetNamedVisible(single, "Icon", !hasFreeTimes || isInCooldown);
            SetTicketIcon(single, pool.Kind);
            SetNamedVisible(single, "Prompt", isFree);
        }

        private void RenderHeaderResources()
        {
            Transform header = FindNamed(view.GameObject.transform, "GoldCheck");
            if (header == null) return;
            int[] itemIds = { 1000, 1001, 1002 };
            for (int index = 0; index < itemIds.Length; index++)
            {
                Transform icon = FindNamed(header, "GoldIcon" + (index + 1));
                SetNamedText(icon, "Num", bag.GetTotalQuantityByItemId(itemIds[index]).ToString());
            }
            // HappyDrawUI's fourth header value is GetTongBao(), which is the
            // second monetary field of /1004 and therefore CurrencyIds.Premium.
            SetNamedText(FindNamed(header, "GoldIcon4"), "Num", currencies.Premium.ToString());
        }

        private void SetTicketIcon(Transform button, byte kind)
        {
            Transform node = FindNamed(button, "Icon");
            Image icon = node == null ? null : node.GetComponent<Image>();
            if (icon == null) return;
            bool placeholder;
            icon.sprite = resources.LoadItemIcon(TicketPicture(kind), out placeholder);
            icon.enabled = icon.sprite != null;
            icon.preserveAspect = true;
        }

        private static int TicketPicture(byte kind) => kind == 1 ? 2103 : kind == 2 ? 3028 : 2104;
        private static int FreeLimit(byte kind) => kind == 1 ? 3 : kind == 2 ? 1 : 0;
        private static int GiftSoul(byte kind) => kind == 1 ? 10 : kind == 2 ? 100 : 50;
        private static uint RemainingGuarantee(DrawPoolRecord pool)
        {
            uint period = pool.Kind == 3 ? 6u : 10u;
            uint remainder = pool.TotalDraws % period;
            return remainder == 0 ? period : period - remainder;
        }

        private void HideResult()
        {
            singleResultView.GameObject.SetActive(false);
            tenResultView.GameObject.SetActive(false);
            store.ClearResult();
        }

        private void SkipResultAnimation()
        {
            foreach (CocosTimelinePlayer timeline in new[]
            {
                singleResultView.GameObject.GetComponent<CocosTimelinePlayer>(),
                tenResultView.GameObject.GetComponent<CocosTimelinePlayer>()
            })
            {
                if (timeline != null && timeline.gameObject.activeInHierarchy && timeline.Duration > 0)
                    timeline.GotoFrameAndPlay(timeline.Duration, timeline.Duration, false);
            }
        }

        private void SetMainDrawContentVisible(bool visible)
        {
            Transform root = view.GameObject.transform;
            foreach (string path in new[]
            {
                "Layer/GoldCheck", "Layer/Popup1", "Layer/Popup2", "Layer/Popup3",
                "Layer/Shop", "Layer/RewardPreview", "Layer/Title"
            })
                SetVisibleAtPath(root, path, visible);
        }

        private static GameObject CreateFurnaceEffect(Transform parent)
        {
            var effect = new GameObject("RuntimeDrawFurnace", typeof(RectTransform));
            RectTransform rect = effect.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(420f, 420f);
            rect.anchoredPosition = new Vector2(-25f, -65f);
            ImodAnimationPlayer player = effect.AddComponent<ImodAnimationPlayer>();
            if (!player.LoadLegacy("res2/fx/choukaluzi"))
            {
                UnityEngine.Object.Destroy(effect);
                return null;
            }
            player.PlayAction(0);
            effect.SetActive(false);
            return effect;
        }

        private static string KindName(byte kind) => kind == 1 ? "基础" : kind == 2 ? "高级" : "友情";
        private Sprite LoadRewardSprite(DrawRewardRecord reward, out bool usedPlaceholder)
        {
            // /224 encodes a recruited hero as award type 60002 plus its hero id.
            // The item record for 60002 is only the generic "神将" wrapper, while the
            // native result cell uses the actual hero portrait.
            if (reward.Type == 60002 && HeroCatalog.TryGet((int)reward.Id, out HeroDefinition hero))
            {
                return resources.LoadHeroPortrait(hero.Picture, out usedPlaceholder);
            }
            // Item rewards encode the item id in Type. Prefer that identity so hero
            // fragments resolve equip2458 rather than a reused legacy `pic` value.
            if (reward.Type > 0 && reward.Type < 60000)
            {
                Sprite itemSprite = resources.LoadItemIcon(reward.Type, out usedPlaceholder);
                if (itemSprite != null) return itemSprite;
            }
            if (reward.Picture > 0) return resources.LoadItemIcon(reward.Picture, out usedPlaceholder);
            usedPlaceholder = true;
            return null;
        }

        private static string RewardName(DrawRewardRecord reward)
        {
            if (reward.Type == 60002 && HeroCatalog.TryGet((int)reward.Id, out HeroDefinition hero)
                && !string.IsNullOrEmpty(hero.Name))
                return reward.TransformItemId > 0 ? $"{hero.Name}神魂" : hero.Name;
            if (!string.IsNullOrEmpty(reward.Name)) return reward.Name;
            if (reward.Type == 60002) return reward.TransformItemId == 0 ? $"神将#{reward.Id}" : $"神将碎片#{reward.TransformItemId}";
            if (reward.Type == 60014) return "将魂";
            return reward.Id == 0 ? $"奖励#{reward.Type}" : $"奖励#{reward.Type}/{reward.Id}";
        }

        private static void Reparent(CocosUiView child, Transform parent) => child.GameObject.transform.SetParent(parent, false);
        private static void Normalize(GameObject value)
        {
            RectTransform rect = value.GetComponent<RectTransform>();
            if (rect == null) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static void Bind(Transform target, Action action)
        {
            if (target == null) return;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.interactable = true;
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void RenderResultHeroModel(DrawRewardRecord reward)
        {
            HeroDefinition definition = default;
            bool loaded = reward != null && reward.Type == 60002
                && HeroCatalog.TryGet((int)reward.Id, out definition);
            if (loaded)
            {
                Transform host = singleResultView.Binding.Find("Layer/dancichoukaUI/shenjiang/Node")?.transform;
                if (host != null)
                {
                    GameObject modelObject = resultModel != null ? resultModel.gameObject
                        : new GameObject("RuntimeDrawResultModel", typeof(RectTransform));
                    RectTransform rect = modelObject.GetComponent<RectTransform>();
                    rect.SetParent(host, false);
                    rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                    rect.anchoredPosition = Vector2.zero;
                    rect.sizeDelta = Vector2.zero;
                    resultModel = modelObject.GetComponent<ImodAnimationPlayer>()
                        ?? modelObject.AddComponent<ImodAnimationPlayer>();
                    loaded = resultModel.LoadLegacy($"Monster/btm{definition.Picture}_zd_show");
                    modelObject.SetActive(loaded);
                    if (loaded) resultModel.Play(0, true);
                }
            }
            if (!loaded && resultModel != null) resultModel.gameObject.SetActive(false);
        }

        private void ShowPreview()
        {
            previewFrame.SetActive(true);
            previewView.GameObject.SetActive(true);
            previewFrame.transform.SetAsLastSibling();
            previewView.GameObject.transform.SetAsLastSibling();
            SetNamedText(previewFrame.transform, "TitleName", "神将预览");
            RenderPreviewHeader();
            ConfigurePreviewTabs();
            SetNamedText(previewView.GameObject.transform, "Text", "奖励预览");
            SelectPreviewPool(previewPoolKind == 0 ? (byte)1 : previewPoolKind);
        }

        private void RenderPreviewHeader()
        {
            Transform header = FindNamed(previewFrame.transform, "GoldCheck");
            if (header == null) return;
            SetNamedText(FindNamed(header, "GoldIcon1"), "Num", $"{currencies.Stamina}/100");
            SetNamedText(FindNamed(header, "GoldIcon3"), "Num", FormatCompact(currencies.Gold));
            SetNamedText(FindNamed(header, "GoldIcon4"), "Num", currencies.Premium.ToString());
        }

        private void ConfigurePreviewTabs()
        {
            Transform button = previewTabTemplate
                ?? FindNamed(previewFrame.transform, "Button1")
                ?? FindNamed(previewFrame.transform, "RuntimeDrawPreviewTab1");
            if (button == null) return;
            Transform parent = button.parent;
            for (int index = parent.childCount - 1; index >= 0; index--)
            {
                Transform child = parent.GetChild(index);
                if (child != button && child.name.StartsWith("RuntimeDrawPreviewTab", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            }
            string[] labels = { "普通\n招募", "高级\n招募", "友情\n招募" };
            RectTransform sourceRect = button.GetComponent<RectTransform>();
            Vector2 sourcePosition = sourceRect == null ? Vector2.zero : sourceRect.anchoredPosition;
            float spacing = sourceRect == null ? 100f : sourceRect.sizeDelta.y;
            for (byte kind = 1; kind <= 3; kind++)
            {
                Transform tab = kind == 1 ? button
                    : UnityEngine.Object.Instantiate(button.gameObject, parent).transform;
                tab.name = kind == 1 ? "Button1" : "RuntimeDrawPreviewTab" + kind;
                RectTransform rect = tab.GetComponent<RectTransform>();
                if (rect != null)
                    rect.anchoredPosition = sourcePosition + new Vector2(0f, -(kind - 1) * spacing);
                SetNamedText(tab, "BtnName", labels[kind - 1]);
                Transform prompt = tab.Find("Prompt");
                if (prompt != null) prompt.gameObject.SetActive(false);
                byte captured = kind;
                BindPreviewTab(tab, () => SelectPreviewPool(captured));
                tab.gameObject.SetActive(true);
            }
        }

        private static void BindPreviewTab(Transform tab, Action action)
        {
            Transform existing = tab.Find("RuntimePreviewTabRaycast");
            Image hitTarget;
            if (existing == null)
            {
                hitTarget = CreateImage(tab, "RuntimePreviewTabRaycast", Vector2.zero, Vector2.one);
                hitTarget.color = new Color(1f, 1f, 1f, .001f);
            }
            else
            {
                hitTarget = existing.GetComponent<Image>();
            }
            hitTarget.enabled = true;
            hitTarget.raycastTarget = true;
            hitTarget.transform.SetAsLastSibling();
            Button button = tab.GetComponent<Button>() ?? tab.gameObject.AddComponent<Button>();
            button.interactable = true;
            button.targetGraphic = hitTarget;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
        }

        private void HidePreview()
        {
            HidePreviewHeroDetail();
            previewView.GameObject.SetActive(false);
            previewFrame.SetActive(false);
        }

        private void CreatePreviewUi()
        {
            Transform parent = previewView.GameObject.transform;
            // The imported reward page sits above the shared first-class frame. Its
            // decorative full-screen graphics must not intercept the visible frame
            // tabs; re-enable raycasts only on the real list viewport and cards.
            foreach (Graphic graphic in previewView.GameObject.GetComponentsInChildren<Graphic>(true))
                graphic.raycastTarget = false;
            RectTransform tabs = CreatePanel(parent, "FirstClassBg", new Vector2(0.20f, 0.81f), new Vector2(0.80f, 0.90f), new Color(0.05f, 0.10f, 0.22f, 0.72f));
            string[] labels = { "基础招募", "高级招募", "友情招募" };
            for (byte kind = 1; kind <= 3; kind++)
            {
                byte captured = kind;
                RectTransform tab = CreatePanel(tabs, "Tab" + kind, new Vector2((kind - 1) / 3f, 0f), new Vector2(kind / 3f, 1f), new Color(0.16f, 0.31f, 0.56f, 0.96f));
                CreateText(tab, "Label", Vector2.zero, Vector2.one, 22, TextAnchor.MiddleCenter).text = labels[kind - 1];
                Bind(tab, () => SelectPreviewPool(captured));
            }
            RectTransform close = CreatePanel(parent, "RuntimePreviewClose", new Vector2(0.76f, 0.90f), new Vector2(0.80f, 0.95f), new Color(0.55f, 0.16f, 0.20f, 0.96f));
            CreateText(close, "Label", Vector2.zero, Vector2.one, 18, TextAnchor.MiddleCenter).text = "关闭";
            Bind(close, HidePreview);
            var viewportGo = new GameObject("PreviewViewport", typeof(RectTransform), typeof(RectMask2D), typeof(Image));
            RectTransform viewport = viewportGo.GetComponent<RectTransform>();
            viewport.SetParent(parent, false);
            viewport.anchorMin = new Vector2(0.20f, 0.14f); viewport.anchorMax = new Vector2(0.80f, 0.79f);
            viewport.offsetMin = viewport.offsetMax = Vector2.zero;
            viewportGo.GetComponent<Image>().color = new Color(0.02f, 0.05f, 0.12f, 0.70f);
            var contentGo = new GameObject("IllustrationsList", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            previewContent = contentGo.GetComponent<RectTransform>();
            previewContent.SetParent(viewport, false);
            previewContent.anchorMin = new Vector2(0f, 1f); previewContent.anchorMax = new Vector2(1f, 1f);
            previewContent.pivot = new Vector2(0.5f, 1f); previewContent.anchoredPosition = Vector2.zero;
            VerticalLayoutGroup layout = contentGo.GetComponent<VerticalLayoutGroup>();
            layout.padding = new RectOffset(12, 12, 8, 8); layout.spacing = 6; layout.childControlWidth = true; layout.childForceExpandWidth = true;
            contentGo.GetComponent<ContentSizeFitter>().verticalFit = ContentSizeFitter.FitMode.PreferredSize;
            previewScroll = viewportGo.AddComponent<ScrollRect>();
            previewScroll.viewport = viewport; previewScroll.content = previewContent;
            previewScroll.horizontal = false; previewScroll.vertical = true; previewScroll.movementType = ScrollRect.MovementType.Clamped;
            // Keep the deterministic automation targets, but render the visible reward
            // grid from the imported Cocos card template below instead of diagnostic rows.
            tabs.GetComponent<Image>().color = Color.clear;
            close.GetComponent<Image>().color = Color.clear;
            viewportGo.GetComponent<Image>().color = Color.clear;
            foreach (Image image in tabs.GetComponentsInChildren<Image>(true)) image.color = Color.clear;
            foreach (Text text in tabs.GetComponentsInChildren<Text>(true)) text.color = Color.clear;
            foreach (Text text in close.GetComponentsInChildren<Text>(true)) text.color = Color.clear;
            tabs.gameObject.AddComponent<CanvasGroup>().blocksRaycasts = false;
            close.gameObject.AddComponent<CanvasGroup>().blocksRaycasts = false;
            viewportGo.AddComponent<CanvasGroup>().blocksRaycasts = false;
            GameObject nativeList = previewView.Binding.Find("Layer/Panel/IllustrationsBg/IllustrationsList");
            previewNativeList = nativeList != null ? nativeList.transform : null;
            GameObject nativeTemplate = previewView.Binding.Find("Layer/Panel/IllustrationsBg/Image1");
            Transform template = nativeTemplate != null ? nativeTemplate.transform : null;
            if (previewNativeList != null && template != null)
            {
                previewNativeTemplate = template.gameObject;
                previewNativeTemplate.SetActive(false);
                ConfigureNativePreviewScroll();
            }
        }

        private void ConfigureNativePreviewScroll()
        {
            RectTransform viewport = previewNativeList as RectTransform;
            if (viewport == null) return;
            if (previewNativeList.GetComponent<RectMask2D>() == null)
                previewNativeList.gameObject.AddComponent<RectMask2D>();
            Graphic viewportGraphic = previewNativeList.GetComponent<Graphic>();
            if (viewportGraphic == null) viewportGraphic = previewNativeList.gameObject.AddComponent<Image>();
            viewportGraphic.raycastTarget = true;
            previewNativeScroll = previewNativeList.GetComponent<ScrollRect>()
                ?? previewNativeList.gameObject.AddComponent<ScrollRect>();
            previewNativeScroll.viewport = viewport;
            previewNativeScroll.horizontal = false;
            previewNativeScroll.vertical = true;
            previewNativeScroll.movementType = ScrollRect.MovementType.Clamped;
            previewNativeScroll.scrollSensitivity = 32f;
            Transform existing = previewNativeList.Find("RuntimeNativePreviewContent");
            if (existing == null)
            {
                var contentObject = new GameObject("RuntimeNativePreviewContent", typeof(RectTransform));
                existing = contentObject.transform;
                existing.SetParent(previewNativeList, false);
            }
            previewNativeContent = existing as RectTransform;
            previewNativeContent.anchorMin = new Vector2(0f, 1f);
            previewNativeContent.anchorMax = new Vector2(1f, 1f);
            previewNativeContent.pivot = new Vector2(.5f, 1f);
            previewNativeContent.anchoredPosition = Vector2.zero;
            previewNativeContent.sizeDelta = new Vector2(0f, viewport.rect.height);
            previewNativeScroll.content = previewNativeContent;
        }

        private void SelectPreviewPool(byte kind)
        {
            previewPoolKind = kind;
            UpdatePreviewTabSelection(kind);
            if (previewContent == null) return;
            foreach (Transform child in previewContent) UnityEngine.Object.Destroy(child.gameObject);
            IEnumerable<int> heroIds = HeroCatalog.GetDrawPreviewHeroes(kind)
                .Where(id => HeroCatalog.TryGet(id, out _))
                .OrderByDescending(id => { HeroCatalog.TryGet(id, out HeroDefinition definition); return definition.Quality; });
            foreach (int heroId in heroIds)
            {
                HeroCatalog.TryGet(heroId, out HeroDefinition definition);
                RectTransform row = CreatePanel(previewContent, "Hero_" + heroId, Vector2.zero, Vector2.one, Color.clear);
                row.gameObject.AddComponent<LayoutElement>().preferredHeight = 64f;
                Image portrait = CreateImage(row, "Portrait", new Vector2(0.02f, 0.08f), new Vector2(0.10f, 0.92f));
                portrait.enabled = false;
                string title = $"神将 {heroId}    品质 {definition.Quality}";
                if (!string.IsNullOrWhiteSpace(definition.Feature)) title += $"    {definition.Feature}";
                Text rowText = CreateText(row, "Name", new Vector2(0.12f, 0f), new Vector2(0.98f, 1f), 21, TextAnchor.MiddleLeft);
                rowText.text = title; rowText.color = Color.clear;
                int captured = heroId;
                Bind(row, () => ShowPreviewHeroDetail(captured));
            }
            RenderNativePreview(heroIds.ToArray());
            if (previewScroll != null) previewScroll.verticalNormalizedPosition = 1f;
        }

        private void UpdatePreviewTabSelection(byte selectedKind)
        {
            for (byte kind = 1; kind <= 3; kind++)
            {
                Transform tab = FindNamed(previewFrame.transform,
                    kind == 1 ? "Button1" : "RuntimeDrawPreviewTab" + kind);
                if (tab == null) continue;
                Transform selected = tab.Find("ChooseBg");
                if (selected != null) selected.gameObject.SetActive(kind == selectedKind);
                Text normal = tab.Find("BtnName")?.GetComponent<Text>();
                if (normal != null) normal.gameObject.SetActive(kind != selectedKind);
            }
        }

        private void RenderNativePreview(int[] heroIds)
        {
            if (previewNativeContent == null || previewNativeTemplate == null) return;
            // Image1 is the imported Cocos card-row template.  It remains an
            // inactive child of the native list and must survive refreshes.
            foreach (Transform child in previewNativeContent)
                UnityEngine.Object.Destroy(child.gameObject);
            const int cardsPerLine = 8;
            const float rowHeight = 180f;
            int rowIndex = 0;
            foreach (IGrouping<int, int> qualityGroup in heroIds.GroupBy(id =>
            {
                HeroCatalog.TryGet(id, out HeroDefinition definition);
                return definition.Quality;
            }).OrderByDescending(group => group.Key))
            {
                int[] ids = qualityGroup.ToArray();
                for (int start = 0; start < ids.Length; start += cardsPerLine)
                {
                    GameObject row = UnityEngine.Object.Instantiate(previewNativeTemplate, previewNativeContent);
                    row.name = "NativePreviewQuality" + qualityGroup.Key + "_" + rowIndex;
                    row.SetActive(true);
                    RectTransform rect = row.GetComponent<RectTransform>();
                    if (rect != null)
                    {
                        // Cocos Image1 is a sibling of its ListView and starts at
                        // a scroll-content Y coordinate.  Once cloned beneath the
                        // Unity viewport, place its top at the viewport top.
                        rect.anchorMin = new Vector2(0f, 1f);
                        rect.anchorMax = new Vector2(1f, 1f);
                        rect.pivot = new Vector2(.5f, 1f);
                        rect.anchoredPosition = new Vector2(0f, -rowIndex * rowHeight);
                        // Under horizontal stretch, x sizeDelta must be zero. Keeping
                        // Image1's imported -960 width turns into Left/Right=-480 and
                        // moves all visible hero cards outside the ScrollRect viewport.
                        rect.sizeDelta = new Vector2(0f, rowHeight);
                    }
                    Transform title = row.transform.Find("TitleBg/Text");
                    if (title != null) SetNamedText(title.parent, "Text", QualityTitle(qualityGroup.Key));
                    for (int slot = 1; slot <= cardsPerLine; slot++)
                    {
                        Transform card = row.transform.Find("IconList/IconBg_" + slot);
                        int heroOffset = start + slot - 1;
                        bool visible = card != null && heroOffset < ids.Length;
                        if (card == null) continue;
                        card.gameObject.SetActive(visible);
                        if (!visible) continue;
                        int heroId = ids[heroOffset];
                        HeroCatalog.TryGet(heroId, out HeroDefinition definition);
                        Image icon = card.Find("Bg/Icon")?.GetComponent<Image>();
                        if (icon != null)
                        {
                            icon.sprite = resources.LoadHeroPortrait(definition.Picture);
                            icon.enabled = icon.sprite != null;
                            icon.preserveAspect = true;
                        }
                        Image frame = card.Find("Bg")?.GetComponent<Image>();
                        if (frame != null)
                            frame.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(definition.Quality, 1, 7):00}");
                        SetNamedText(card, "Name", definition.Name);
                        Text name = card.Find("Bg/Name")?.GetComponent<Text>();
                        if (name != null) name.color = QualityColor(definition.Quality);
                        int captured = heroId;
                        Bind(card, () => ShowPreviewHeroDetail(captured));
                    }
                    rowIndex++;
                }
            }
            float viewportHeight = (previewNativeList as RectTransform)?.rect.height ?? 530f;
            previewNativeContent.sizeDelta = new Vector2(0f, Mathf.Max(viewportHeight, rowIndex * rowHeight));
            if (previewNativeScroll != null) previewNativeScroll.verticalNormalizedPosition = 1f;
        }

        private static string QualityTitle(int quality)
            => quality >= 7 ? "金色神将" : quality == 6 ? "红色神将"
                : quality == 5 ? "橙色神将" : quality == 4 ? "紫色神将" : "蓝色神将";

        private static Color QualityColor(int quality)
            => quality >= 7 ? new Color(1f, .75f, .18f)
                : quality == 6 ? new Color(.95f, .2f, .2f)
                : quality == 5 ? new Color(1f, .55f, .05f)
                : quality == 4 ? new Color(.67f, .18f, .91f)
                : new Color(.25f, .55f, 1f);

        private static string FormatCompact(long value)
        {
            ulong amount = unchecked((ulong)Math.Max(0, value));
            if (amount < 10000) return amount.ToString();
            if (amount < 100000000) return $"{amount / 10000d:0.#}万";
            return $"{amount / 100000000d:0.#}亿";
        }

        private void ShowPreviewHeroDetail(int heroId)
        {
            if (!HeroCatalog.TryGet(heroId, out HeroDefinition definition)) return;
            heroPreviewFrame.SetActive(true);
            heroPreviewView.GameObject.SetActive(true);
            heroPreviewFrame.transform.SetAsLastSibling();
            heroPreviewView.GameObject.transform.SetAsLastSibling();
            SetNamedText(heroPreviewFrame.transform, "TitleName", "信息");
            SetHeroPreviewText("Layer/Panel/Panel_left/Name", definition.Name);
            Text heroName = heroPreviewView.Binding.Find("Layer/Panel/Panel_left/Name")?.GetComponent<Text>();
            if (heroName != null) heroName.color = QualityColor(definition.Quality);
            GameObject powerPanel = heroPreviewView.Binding.Find("Layer/Panel/Panel_left/RolePowerBase");
            if (powerPanel != null) powerPanel.SetActive(false);
            SetHeroPreviewText("Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/Info/dingwei/Value", definition.Feature);
            string[] attributeNames = { "攻击:", "生命:", "物防:", "法防:",
                "攻击成长:", "生命成长:", "物防成长:", "法防成长:" };
            int[] attributes = { definition.Attack, definition.Health, definition.PhysicalDefense,
                definition.MagicDefense, definition.AttackGrowth, definition.PhysicalDefenseGrowth,
                definition.MagicDefenseGrowth, definition.HealthGrowth };
            for (int index = 0; index < attributes.Length; index++)
            {
                SetHeroPreviewText($"Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/jichu/Attribute_{index + 1}",
                    attributeNames[index]);
                SetHeroPreviewText($"Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/jichu/Attribute_{index + 1}/Value",
                    attributes[index].ToString());
            }
            const string skillItemPath = "Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/Skill/Item";
            SetHeroPreviewText(skillItemPath + "/SkillName", definition.SkillName);
            Transform skillItem = heroPreviewView.Binding.Find(skillItemPath)?.transform;
            Text skillTemplate = heroPreviewView.Binding.Find(skillItemPath + "/SkillInfo")?.GetComponent<Text>();
            heroPreviewSkillDescription = EnsurePreviewRuntimeText(heroPreviewSkillDescription, skillItem,
                "RuntimeSkillDescription", new Vector2(.24f, .03f), new Vector2(.97f, .62f), skillTemplate, 19);
            if (heroPreviewSkillDescription != null)
                heroPreviewSkillDescription.text = HeroCatalog.ResolveSkillDescription(definition.SkillDescription, 1);

            const string talentPath = "Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/jinjietianfu";
            Transform talentPanel = heroPreviewView.Binding.Find(talentPath)?.transform;
            Text talentTemplate = heroPreviewView.Binding.Find(talentPath + "/TalentInfo")?.GetComponent<Text>();
            Transform staleRuntimeText = talentPanel?.Find("RuntimeTalentDescription");
            if (staleRuntimeText != null) UnityEngine.Object.Destroy(staleRuntimeText.gameObject);
            heroPreviewTalentDescription = talentTemplate;
            if (heroPreviewTalentDescription != null)
            {
                IReadOnlyList<string> talents = HeroCultivationPresenter
                    .GetBreakTalentDescriptionsForPreview(heroId, definition);
                heroPreviewTalentDescription.text = string.Join("\n\n", talents.Select((value, index) =>
                    $"突破至{index + 1}开启\n{value}"));
                ResizeHeroPreviewTalentInfo();
            }
            int fragmentNeed = itemCatalog.GetSynthesisCost(definition.ItemId);
            int fragmentOwned = definition.ItemId > 0 ? bag.GetTotalQuantityByItemId(definition.ItemId) : 0;
            SetHeroPreviewText("Layer/Panel/Panel_left/suipian/Slider_Bg/Value", $"{fragmentOwned}/{fragmentNeed}");
            GameObject loadingObject = heroPreviewView.Binding.Find("Layer/Panel/Panel_left/suipian/Slider_Bg/LoadingBar");
            Slider loading = loadingObject?.GetComponent<Slider>();
            float fragmentProgress = fragmentNeed > 0 ? Mathf.Clamp01(fragmentOwned / (float)fragmentNeed) : 0f;
            if (loading != null) loading.value = fragmentProgress;
            Image loadingImage = loadingObject?.GetComponent<Image>();
            if (loadingImage != null) loadingImage.fillAmount = fragmentProgress;
            GameObject qualityObject = heroPreviewView.Binding.Find("Layer/Panel/Panel_left/bg_Quality/Value");
            Image quality = qualityObject?.GetComponent<Image>();
            if (quality != null)
            {
                string score = definition.Quality <= 4 ? "A" : definition.Quality == 5 ? "S"
                    : definition.Quality == 6 ? "SS" : definition.Quality == 7 ? "SSS" : "SSSS";
                quality.sprite = resources.LoadFirst("HeroUI/quality_score_" + score);
                quality.enabled = quality.sprite != null;
            }
            GameObject skillIconObject = heroPreviewView.Binding.Find(
                "Layer/Panel/shenjiangInfoUI/Info/ScrollView_1/Skill/Item/Btn_Skill/Icon");
            Image skillIcon = skillIconObject?.GetComponent<Image>();
            if (skillIcon != null)
            {
                skillIcon.sprite = resources.LoadFirst($"HeroUI/skill_{definition.SkillId}");
                skillIcon.enabled = skillIcon.sprite != null;
                skillIcon.preserveAspect = true;
            }
            RenderHeroPreviewModel(definition);
        }

        private void ConfigureHeroPreviewInfoScroll()
        {
            const string path = "Layer/Panel/shenjiangInfoUI/Info/ScrollView_1";
            GameObject scrollObject = heroPreviewView.Binding.Find(path);
            RectTransform viewport = scrollObject?.transform as RectTransform;
            if (viewport == null) return;

            heroPreviewInfoScroll = scrollObject.GetComponent<ScrollRect>()
                ?? scrollObject.AddComponent<ScrollRect>();
            heroPreviewInfoScroll.viewport = viewport;
            heroPreviewInfoScroll.horizontal = false;
            heroPreviewInfoScroll.vertical = true;
            heroPreviewInfoScroll.movementType = ScrollRect.MovementType.Clamped;
            heroPreviewInfoScroll.scrollSensitivity = 30f;

            Image inputSurface = scrollObject.GetComponent<Image>() ?? scrollObject.AddComponent<Image>();
            inputSurface.sprite = null;
            inputSurface.color = Color.clear;
            inputSurface.raycastTarget = true;

            Transform existing = viewport.Find("RuntimeContent");
            if (existing != null)
            {
                heroPreviewInfoContent = existing as RectTransform;
            }
            else
            {
                GameObject contentObject = new GameObject("RuntimeContent", typeof(RectTransform));
                heroPreviewInfoContent = contentObject.GetComponent<RectTransform>();
                heroPreviewInfoContent.SetParent(viewport, false);
                heroPreviewInfoContent.anchorMin = new Vector2(0f, 1f);
                heroPreviewInfoContent.anchorMax = new Vector2(1f, 1f);
                heroPreviewInfoContent.pivot = new Vector2(.5f, 1f);
                heroPreviewInfoContent.anchoredPosition = Vector2.zero;
                heroPreviewInfoContent.sizeDelta = new Vector2(0f, viewport.rect.height);

                Transform[] sections = viewport.Cast<Transform>()
                    .Where(value => value != heroPreviewInfoContent)
                    .ToArray();
                foreach (Transform section in sections)
                {
                    RectTransform rect = section as RectTransform;
                    if (rect == null) continue;
                    Vector3 worldPosition = rect.position;
                    rect.SetParent(heroPreviewInfoContent, true);
                    rect.anchorMin = rect.anchorMax = new Vector2(.5f, 1f);
                    rect.position = worldPosition;
                }
            }

            heroPreviewInfoScroll.content = heroPreviewInfoContent;
            RefreshHeroPreviewInfoContentHeight();
        }

        private void ResizeHeroPreviewTalentInfo()
        {
            if (heroPreviewTalentDescription == null) return;
            RectTransform rect = heroPreviewTalentDescription.rectTransform;
            heroPreviewTalentDescription.horizontalOverflow = HorizontalWrapMode.Wrap;
            heroPreviewTalentDescription.verticalOverflow = VerticalWrapMode.Overflow;
            heroPreviewTalentDescription.raycastTarget = false;
            Canvas.ForceUpdateCanvases();
            float preferredHeight = Mathf.Max(1f, heroPreviewTalentDescription.preferredHeight);
            if (preferredHeight > rect.rect.height)
                rect.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, preferredHeight);
            RefreshHeroPreviewInfoContentHeight();
        }

        private void RefreshHeroPreviewInfoContentHeight()
        {
            if (heroPreviewInfoScroll == null || heroPreviewInfoContent == null
                || heroPreviewInfoScroll.viewport == null) return;
            Canvas.ForceUpdateCanvases();
            float lowestPoint = 0f;
            Vector3[] corners = new Vector3[4];
            foreach (RectTransform child in heroPreviewInfoContent.GetComponentsInChildren<RectTransform>(true))
            {
                if (child == heroPreviewInfoContent) continue;
                child.GetWorldCorners(corners);
                for (int index = 0; index < corners.Length; index++)
                    lowestPoint = Mathf.Min(lowestPoint,
                        heroPreviewInfoContent.InverseTransformPoint(corners[index]).y);
            }
            float viewportHeight = heroPreviewInfoScroll.viewport.rect.height;
            float requiredHeight = Mathf.Max(viewportHeight, -lowestPoint + 16f);
            heroPreviewInfoContent.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, requiredHeight);
            heroPreviewInfoScroll.verticalNormalizedPosition = 1f;
        }

        private void RenderHeroPreviewModel(HeroDefinition definition)
        {
            GameObject hostObject = heroPreviewView.Binding.Find("Layer/Panel/Panel_left/Node_1/Node");
            Transform host = hostObject?.transform;
            if (host == null) return;
            if (heroPreviewModel == null)
            {
                var modelObject = new GameObject("RuntimeDrawHeroPreviewModel", typeof(RectTransform));
                RectTransform rect = modelObject.GetComponent<RectTransform>();
                rect.SetParent(host, false);
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = Vector2.zero;
                heroPreviewModel = modelObject.AddComponent<ImodAnimationPlayer>();
            }
            bool loaded = heroPreviewModel.LoadLegacy($"Monster/btm{definition.Picture}_zd_show");
            heroPreviewModel.gameObject.SetActive(loaded);
            if (loaded) heroPreviewModel.Play(0, true);
            if (heroPreviewFallback == null)
            {
                heroPreviewFallback = CreateImage(host, "RuntimeDrawHeroPreviewPortrait",
                    new Vector2(-1.5f, -1.5f), new Vector2(2.5f, 2.5f));
                heroPreviewFallback.preserveAspect = true;
            }
            heroPreviewFallback.sprite = loaded ? null
                : resources.LoadFirst($"MonsterBust/{definition.Picture}", $"MonsterBust/{definition.Picture}_tou");
            heroPreviewFallback.gameObject.SetActive(!loaded && heroPreviewFallback.sprite != null);
        }

        private void SetHeroPreviewText(string path, string value)
        {
            Text text = heroPreviewView.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static Text EnsurePreviewRuntimeText(Text current, Transform parent, string name,
            Vector2 anchorMin, Vector2 anchorMax, Text template, int fontSize)
        {
            if (parent == null) return null;
            Text text = current;
            if (text == null)
                text = CreateText(parent, name, anchorMin, anchorMax, fontSize, TextAnchor.UpperLeft);
            RectTransform rect = text.rectTransform;
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            if (template != null)
            {
                text.font = template.font;
                text.fontStyle = template.fontStyle;
                text.color = template.color;
            }
            text.fontSize = fontSize;
            text.alignment = TextAnchor.UpperLeft;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.supportRichText = true;
            text.raycastTarget = false;
            text.gameObject.SetActive(true);
            text.transform.SetAsLastSibling();
            return text;
        }

        public void HidePreviewHeroDetail()
        {
            if (heroPreviewFrame != null) heroPreviewFrame.SetActive(false);
        }

        private static void BindFirst(Transform root, Action action, params string[] names)
        {
            foreach (string name in names)
            {
                Transform target = FindNamed(root, name);
                if (target == null) continue;
                Bind(target, action);
                return;
            }
        }

        private static Transform FindNamed(Transform root, string name)
        {
            if (root == null) return null;
            foreach (Transform value in root.GetComponentsInChildren<Transform>(true))
                if (value.name == name) return value;
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            if (root == null) return;
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
                if (text.gameObject.name == name) text.text = value ?? string.Empty;
        }

        private static void SetNamedVisible(Transform root, string name, bool visible)
        {
            Transform target = FindNamed(root, name);
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void SetVisibleAtPath(Transform root, string path, bool visible)
        {
            Transform target = root == null ? null : root.Find(path);
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void SetGraphicVisibleAtPath(Transform root, string path, bool visible)
        {
            Transform target = root == null ? null : root.Find(path);
            if (target == null) return;
            foreach (Graphic graphic in target.GetComponentsInChildren<Graphic>(true)) graphic.enabled = visible;
        }

        private static void SetCanvasOpacity(GameObject target, float alpha)
        {
            if (target == null) return;
            // UnityEngine.Object overloads == for destroyed components; do not use
            // ?? here, otherwise a stale imported CanvasGroup reference is selected.
            CanvasGroup group = target.GetComponent<CanvasGroup>();
            if (group == null) group = target.AddComponent<CanvasGroup>();
            group.alpha = alpha;
            group.interactable = alpha > 0f;
            group.blocksRaycasts = alpha > 0f;
            // Imported Cocos result prefabs contain nested, override-sorting Canvases;
            // CanvasGroup alone cannot hide those draw roots.
            foreach (Canvas canvas in target.GetComponentsInChildren<Canvas>(true))
                canvas.enabled = alpha > 0f;
            // Some imported prefabs are drawn through the shared bootstrap canvas.
            // Keep their Button components callable for the real continue path, while
            // disabling only their pixels during the single-result conversion overlay.
            foreach (Graphic graphic in target.GetComponentsInChildren<Graphic>(true))
                graphic.enabled = alpha > 0f;
        }

        private static Text CreateText(Transform parent, string name, Vector2 min, Vector2 max, int size, TextAnchor alignment)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = size; text.alignment = alignment; text.color = Color.white;
            text.raycastTarget = false;
            return text;
        }

        private static RectTransform CreatePanel(Transform parent, string name, Vector2 min, Vector2 max, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            go.GetComponent<Image>().color = color;
            return rect;
        }

        private static Image CreateImage(Transform parent, string name, Vector2 min, Vector2 max)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            RectTransform rect = go.GetComponent<RectTransform>();
            rect.SetParent(parent, false); rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            return go.GetComponent<Image>();
        }
    }
}
