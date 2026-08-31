using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // Owns only the imported Cocos result Prefabs.  Data remains in RewardStore,
    // which is populated exclusively after a successful /320 response.
    public sealed class WorldOutcomePresenter : IDisposable
    {
        private readonly CocosUiView sweepView;
        private readonly CocosUiView battleView;
        private readonly CocosUiView statisticsView;
        private readonly GameObject statisticsFrameTemplate;
        private readonly RewardStore rewards;
        private readonly ResourceService resources;
        private readonly PlayerStore player;
        private readonly HeroStore heroes;
        private readonly WorldBattleReplayStore replay;
        private readonly Action requestSweepAgain;
        private readonly Action requestContinue;
        private readonly Action requestReplay;
        private readonly Action showStatisticsUnavailable;
        private readonly Action showReviveUnavailable;
        private readonly Action<string> validationControl;
        private Button replayInteractionButton;
        private Button continueInteractionButton;
        private Button statisticsInteractionButton;
        private Button statisticsCloseInteractionButton;
        private Image replayInteractionGraphic;
        private ImodAnimationPlayer victoryTitleAnimation;
        private BattleResultImodOneShot victoryTitleEffect;
        private int renderedRewardCount;
        private int renderedMoneyRewardCount;
        private int renderedItemRewardCount;
        private int renderedPetExperienceCount;
        private int renderedSweepCount;
        private int renderedFriendlyStatisticsCount;
        private int renderedEnemyStatisticsCount;
        private bool returnBattleAfterStatistics;

        public WorldOutcomePresenter(CocosUiView worldView, CocosUiView sweepView, CocosUiView battleView,
            CocosUiView statisticsView, GameObject statisticsFrameTemplate,
            RewardStore rewards, ResourceService resources, PlayerStore player, HeroStore heroes,
            WorldBattleReplayStore replay,
            Action requestSweepAgain, Action requestContinue,
            Action requestReplay, Action showStatisticsUnavailable, Action showReviveUnavailable,
            Action<string> validationControl = null)
        {
            if (worldView == null) throw new ArgumentNullException(nameof(worldView));
            this.sweepView = sweepView ?? throw new ArgumentNullException(nameof(sweepView));
            this.battleView = battleView ?? throw new ArgumentNullException(nameof(battleView));
            this.statisticsView = statisticsView ?? throw new ArgumentNullException(nameof(statisticsView));
            this.statisticsFrameTemplate = statisticsFrameTemplate
                ?? throw new ArgumentNullException(nameof(statisticsFrameTemplate));
            this.rewards = rewards ?? throw new ArgumentNullException(nameof(rewards));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.replay = replay ?? throw new ArgumentNullException(nameof(replay));
            this.requestSweepAgain = requestSweepAgain ?? throw new ArgumentNullException(nameof(requestSweepAgain));
            this.requestContinue = requestContinue ?? throw new ArgumentNullException(nameof(requestContinue));
            this.requestReplay = requestReplay ?? throw new ArgumentNullException(nameof(requestReplay));
            this.showStatisticsUnavailable = showStatisticsUnavailable ?? throw new ArgumentNullException(nameof(showStatisticsUnavailable));
            this.showReviveUnavailable = showReviveUnavailable ?? throw new ArgumentNullException(nameof(showReviveUnavailable));
            this.validationControl = validationControl;

            Reparent(sweepView, worldView.GameObject.transform);
            Transform overlayParent = worldView.GameObject.transform.parent ?? worldView.GameObject.transform;
            Reparent(battleView, overlayParent);
            Reparent(statisticsView, overlayParent);
            Bind(sweepView, "Layer/bg/Btn_close", () => { HideSweep(); Mark("WORLD-19-SWEEP-RESULT-CLOSE"); });
            Bind(sweepView, "Layer/bg/Image/Button", () => { HideSweep(); Mark("WORLD-19-SWEEP-RESULT-CLOSE"); });
            Bind(sweepView, "Layer/bg/Image/Button1", () => { SweepAgain(); Mark("WORLD-20-SWEEP-AGAIN"); });
            continueInteractionButton = Bind(battleView, "Layer/Panel", () => { Continue(); Mark("WORLD-21-BATTLE-RESULT-CONTINUE"); });
            replayInteractionButton = Bind(battleView, "Layer/Panel/victorypanel/Button_Replay", () => { Replay(); Mark("WORLD-22-BATTLE-RESULT-REPLAY"); });
            statisticsInteractionButton = Bind(battleView, "Layer/Panel/victorypanel/Button_tongji", () => { ShowStatistics(); Mark("WORLD-23-BATTLE-STATISTICS"); });
            Bind(battleView, "Layer/Panel/firPanel/tontguanxinxilayer/Button_reborn", () => { Revive(); Mark("WORLD-24-BATTLE-REVIVE"); });
            rewards.Changed += Render;
            HideAll();
        }

        public bool IsSweepVisible => sweepView.GameObject.activeSelf;
        public bool IsBattleVisible => battleView.GameObject.activeSelf;
        public bool IsStatisticsVisible => statisticsView.GameObject.activeSelf;
        public int RenderedRewardCount => renderedRewardCount;
        public int RenderedMoneyRewardCount => renderedMoneyRewardCount;
        public int RenderedItemRewardCount => renderedItemRewardCount;
        public int RenderedPetExperienceCount => renderedPetExperienceCount;
        public int VictoryTitleVariant { get; private set; }
        public int RenderedFriendlyStatisticsCount => renderedFriendlyStatisticsCount;
        public int RenderedEnemyStatisticsCount => renderedEnemyStatisticsCount;
        public bool IsBattleResultSummaryVisible => battleView.GameObject.transform
            .Find("WorldBattleBackdrop/ResultSummary")?.gameObject.activeSelf == true;
        public Button ReplayInteractionButton => replayInteractionButton;
        public Button ContinueInteractionButton => continueInteractionButton;
        public Button StatisticsInteractionButton => statisticsInteractionButton;
        public Button StatisticsCloseInteractionButton => statisticsCloseInteractionButton;
        public bool IsVictoryTitleEffectVisible => victoryTitleEffect?.IsEffectVisible == true;
        public bool IsVictoryTitleEffectPlaying => victoryTitleEffect?.IsPlaying == true;

        public void ShowSweep(int sweepCount, IEnumerable<IEnumerable<RewardRecord>> groupedRewards)
        {
            returnBattleAfterStatistics = false;
            HideBattle();
            HideStatistics();
            // The protocol still supplies per-fight buckets, but the product result
            // surface is a single summary: merge equal rewards across all N sweeps.
            _ = groupedRewards;
            renderedSweepCount = Math.Max(0, sweepCount);
            SetText(sweepView, "Layer/bg/Title/Title", "扫荡结算");
            SetText(sweepView, "Layer/bg/Image/Button1/Text", $"扫荡{renderedSweepCount}次");
            sweepView.GameObject.SetActive(true);
            sweepView.GameObject.transform.SetAsLastSibling();
            Render();
        }

        public void ShowBattle(int stars, bool showStars = true)
        {
            returnBattleAfterStatistics = false;
            HideSweep();
            HideStatistics();
            SetActive(battleView, "Layer/Panel/victorypanel", true);
            SetActive(battleView, "Layer/Panel/firPanel", false);
            SetActive(battleView, "Layer/Panel/victorypanel/win_bg", false);
            SetText(battleView, "Layer/Panel/victorypanel/win_bg/Name", "战斗胜利");
            for (int index = 1; index <= 3; index++)
                SetActive(battleView, $"Layer/Panel/victorypanel/win_bg/starlayer/Star{index}", index <= stars);
            battleView.GameObject.SetActive(true);
            EnsureBattleBackdrop();
            ApplyVictoryTitle(stars, showStars);
            for (int index = 0; index < 3; index++)
            {
                Transform star = battleView.GameObject.transform.Find($"WorldBattleBackdrop/VictoryStar{index}");
                if (star != null) star.gameObject.SetActive(showStars && index < stars);
            }
            Transform resultSummary = battleView.GameObject.transform.Find("WorldBattleBackdrop/ResultSummary");
            if (resultSummary != null) resultSummary.gameObject.SetActive(showStars);
            battleView.GameObject.transform.SetAsLastSibling();
            RefreshBattleInteractionGraphic();
            Render();
        }

        public bool InvokeContinue()
        {
            if (!IsBattleVisible) return false;
            Continue();
            return true;
        }

        public void Dispose()
        {
            rewards.Changed -= Render;
        }

        private void SweepAgain()
        {
            HideSweep();
            requestSweepAgain();
        }

        private void Continue()
        {
            HideBattle();
            requestContinue();
        }

        private void Replay()
        {
            HideBattle();
            requestReplay();
        }

        private void ShowStatistics()
        {
            returnBattleAfterStatistics = IsBattleVisible;
            statisticsView.GameObject.SetActive(true);
            statisticsView.GameObject.transform.SetAsLastSibling();
            Canvas.ForceUpdateCanvases();
            RenderStatistics();
            Canvas.ForceUpdateCanvases();
        }

        private void RenderStatistics()
        {
            Transform host = Find(statisticsView, "Layer/Panel/Panel_zhandoutongji")?.transform;
            if (host == null) return;
            Transform list = host.Find("ListView");
            Transform template = list?.Find("ActivityList");
            if (list == null || template == null) return;
            ClearRuntimeChildren(list, "RuntimeBattleStatistics_");
            template.gameObject.SetActive(false);
            EnsureStatisticsChrome(host);
            SetText(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_1/name", NormalizeCocosFightName(replay.FriendlyName));
            SetText(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_2/name", NormalizeCocosFightName(replay.EnemyName));
            SetActive(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_1/Panel_win", replay.Won);
            SetActive(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_1/Panel_lose", !replay.Won);
            SetActive(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_2/Panel_win", !replay.Won);
            SetActive(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_2/Panel_2/Panel_lose", replay.Won);

            WorldBattleUnitRecord[] friendly = replay.Units.Where(value => !value.IsEnemy)
                .OrderBy(value => value.Position).Take(5).ToArray();
            WorldBattleUnitRecord[] enemy = replay.Units.Where(value => value.IsEnemy)
                .OrderBy(value => value.Position).Take(5).ToArray();
            renderedFriendlyStatisticsCount = friendly.Length;
            renderedEnemyStatisticsCount = enemy.Length;
            ulong[] maxima =
            {
                Math.Max(1ul, replay.Units.Max(value => value.DamageDealt)),
                Math.Max(1ul, replay.Units.Max(value => value.DamageTaken)),
                Math.Max(1ul, replay.Units.Max(value => value.Healing))
            };
            int rowCount = Math.Max(friendly.Length, enemy.Length);
            for (int index = 0; index < rowCount; index++)
            {
                GameObject row = UnityEngine.Object.Instantiate(template.gameObject, list, false);
                row.name = $"RuntimeBattleStatistics_Row{index}";
                if (row.transform is RectTransform rowRect)
                    rowRect.anchoredPosition = new Vector2(0f, 405f - index * 90f);
                row.SetActive(true);
                PopulateStatisticsSide(row.transform.Find("Panel_1"), index < friendly.Length ? friendly[index] : null,
                    maxima);
                PopulateStatisticsSide(row.transform.Find("Panel_2"), index < enemy.Length ? enemy[index] : null,
                    maxima);
            }
        }

        private void PopulateStatisticsSide(Transform side, WorldBattleUnitRecord unit,
            IReadOnlyList<ulong> maxima)
        {
            if (side == null) return;
            side.gameObject.SetActive(unit != null);
            if (unit == null) return;
            Image portrait = side.Find("IconBg_1/Bg/Icon")?.GetComponent<Image>();
            if (portrait != null)
            {
                int portraitPicture = (int)unit.Picture;
                if (unit.Type == 2 && HeroCatalog.TryGet((int)unit.Picture, out HeroDefinition definition))
                    portraitPicture = definition.Picture;
                portrait.sprite = resources.LoadHeroPortrait(portraitPicture);
                portrait.preserveAspect = true;
                portrait.color = Color.white;
            }
            Image frame = side.Find("IconBg_1/Bg")?.GetComponent<Image>();
            Sprite frameSprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(unit.Quality, 1, 7):00}");
            if (frame != null && frameSprite != null) frame.sprite = frameSprite;
            Text name = side.Find("IconBg_1/Bg/Name")?.GetComponent<Text>();
            if (name != null)
            {
                name.text = unit.Name ?? string.Empty;
                name.color = StatisticsQualityColor(unit.Quality);
            }
            ulong[] values =
            {
                unit.DamageDealt,
                unit.DamageTaken,
                unit.Healing
            };
            for (int metric = 0; metric < values.Length; metric++)
            {
                Transform metricRoot = side.Find($"Image{metric + 1}");
                Text value = metricRoot?.Find("txt2")?.GetComponent<Text>();
                if (value != null) value.text = values[metric].ToString();
                Image progress = metricRoot?.Find("EXPBar")?.GetComponent<Image>();
                if (progress == null) continue;
                progress.type = Image.Type.Filled;
                progress.fillMethod = Image.FillMethod.Horizontal;
                progress.fillOrigin = 0;
                progress.fillAmount = Mathf.Clamp01((float)values[metric] / maxima[metric]);
            }
        }

        private void EnsureStatisticsChrome(Transform host)
        {
            // The source CSB places these two 485px washes on opposite halves.
            // Its first image is left-pivoted from the split point; the imported
            // RectTransform otherwise stacks both washes on the enemy half.
            RectTransform friendlyWash = host.Find("Panel_title_1/Image_1") as RectTransform;
            if (friendlyWash != null)
                friendlyWash.anchoredPosition = new Vector2(0f, friendlyWash.anchoredPosition.y);
            RectTransform enemyWash = host.Find("Panel_title_1/Image_2") as RectTransform;
            if (enemyWash != null)
                enemyWash.anchoredPosition = new Vector2(485f, enemyWash.anchoredPosition.y);
            Transform layer = Find(statisticsView, "Layer")?.transform;
            if (layer == null)
                throw new InvalidOperationException("Imported battle statistics Layer binding is missing.");
            if (layer.Find("RuntimeBattleStatistics_Dimmer") == null)
            {
                GameObject dimmer = new GameObject("RuntimeBattleStatistics_Dimmer", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform rect = dimmer.GetComponent<RectTransform>();
                rect.SetParent(layer, false);
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                Image image = dimmer.GetComponent<Image>();
                image.color = new Color(0f, 0f, 0f, 0.72f);
                image.raycastTarget = false;
                dimmer.transform.SetAsFirstSibling();
            }
            Transform existing = layer.Find("RuntimeBattleStatistics_Frame");
            GameObject frame;
            if (existing == null)
            {
                frame = UnityEngine.Object.Instantiate(statisticsFrameTemplate, layer, false);
                frame.name = "RuntimeBattleStatistics_Frame";
                RectTransform rect = frame.transform as RectTransform;
                if (rect != null)
                {
                    rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                    rect.anchoredPosition = Vector2.zero;
                    rect.localScale = Vector3.one;
                }
                frame.transform.SetSiblingIndex(Math.Min(1, layer.childCount - 1));
            }
            else frame = existing.gameObject;
            frame.SetActive(true);
            Transform mask = frame.transform.Find("Mask");
            if (mask != null) mask.gameObject.SetActive(false);
            Transform tabs = frame.transform.Find("Btn_ListView");
            if (tabs != null) tabs.gameObject.SetActive(false);
            Transform decoration = frame.transform.Find("Image");
            if (decoration != null) decoration.gameObject.SetActive(false);
            Transform sourceTitle = frame.transform.Find("Popup/Title");
            Transform sourceClose = frame.transform.Find("Popup/Btn_close");
            if (sourceTitle == null || sourceClose == null)
                throw new InvalidOperationException("Current Cocos PopFirstClass title or close control is missing from statistics frame.");

            Canvas.ForceUpdateCanvases();
            Transform runtimeTitle = layer.Find("RuntimeBattleStatistics_Title");
            if (runtimeTitle == null)
            {
                GameObject titleClone = UnityEngine.Object.Instantiate(sourceTitle.gameObject, layer, true);
                titleClone.name = "RuntimeBattleStatistics_Title";
                runtimeTitle = titleClone.transform;
            }
            Transform runtimeClose = layer.Find("RuntimeBattleStatistics_Close");
            if (runtimeClose == null)
            {
                GameObject closeClone = UnityEngine.Object.Instantiate(sourceClose.gameObject, layer, true);
                closeClone.name = "RuntimeBattleStatistics_Close";
                runtimeClose = closeClone.transform;
            }
            sourceTitle.gameObject.SetActive(false);
            sourceClose.gameObject.SetActive(false);
            runtimeTitle.gameObject.SetActive(true);
            runtimeClose.gameObject.SetActive(true);
            runtimeTitle.SetAsLastSibling();
            runtimeClose.SetAsLastSibling();

            Text title = runtimeTitle.Find("Title")?.GetComponent<Text>();
            if (title != null) title.text = "战斗统计";
            Transform help = runtimeTitle.Find("Title/Button_1");
            if (help != null) help.gameObject.SetActive(false);
            statisticsCloseInteractionButton = runtimeClose.GetComponent<Button>();
            if (statisticsCloseInteractionButton == null)
                throw new InvalidOperationException("Current Cocos PopFirstClass close control is missing from statistics frame.");
            statisticsCloseInteractionButton.enabled = true;
            statisticsCloseInteractionButton.interactable = true;
            Graphic closeGraphic = statisticsCloseInteractionButton.targetGraphic;
            if (closeGraphic != null) closeGraphic.raycastTarget = true;
            statisticsCloseInteractionButton.onClick.RemoveAllListeners();
            statisticsCloseInteractionButton.onClick.AddListener(CloseStatistics);
        }

        private static Color StatisticsQualityColor(int quality)
        {
            switch (Mathf.Clamp(quality, 1, 7))
            {
                case 2: return new Color(0.25f, 0.85f, 0.35f, 1f);
                case 3: return new Color(0.25f, 0.65f, 1f, 1f);
                case 4: return new Color(0.75f, 0.35f, 1f, 1f);
                case 5: return new Color(1f, 0.64f, 0.16f, 1f);
                case 6: return new Color(1f, 0.24f, 0.24f, 1f);
                default: return Color.white;
            }
        }

        private void Revive()
        {
            showReviveUnavailable();
        }

        private void HideAll()
        {
            returnBattleAfterStatistics = false;
            HideSweep();
            HideBattle();
            HideStatistics();
        }

        private void CloseStatistics()
        {
            HideStatistics();
            if (!returnBattleAfterStatistics) return;
            returnBattleAfterStatistics = false;
            battleView.GameObject.SetActive(true);
            battleView.GameObject.transform.SetAsLastSibling();
            RefreshBattleInteractionGraphic();
        }

        private void RefreshBattleInteractionGraphic()
        {
            if (replayInteractionGraphic == null) return;
            // The statistics flow deactivates the whole imported result view. Restore
            // the runtime-created visible replay Graphic whenever that view returns,
            // so Canvas assigns a valid depth before EventSystem raycasting.
            replayInteractionGraphic.enabled = false;
            replayInteractionGraphic.enabled = true;
            replayInteractionGraphic.SetAllDirty();
            Canvas.ForceUpdateCanvases();
        }

        private void HideSweep() => sweepView.GameObject.SetActive(false);
        private void HideBattle() => battleView.GameObject.SetActive(false);
        private void HideStatistics() => statisticsView.GameObject.SetActive(false);

        private void Render()
        {
            renderedRewardCount = AggregateRewards(rewards.Items).Count;
            SetText(battleView, "Layer/Panel/victorypanel/win_bg/Panel_jiangli/Text", $"本次获得 {renderedRewardCount} 项奖励");
            RenderSweepRewards();
            RenderBattleRewards();
        }

        private void RenderSweepRewards()
        {
            Transform host = Find(sweepView, "Layer/bg/ListView_2")?.transform;
            if (host == null) return;
            ClearRuntimeChildren(host, "RuntimeSweepReward_");
            IReadOnlyList<RewardRecord> values = AggregateRewards(rewards.Items);
            CreateBattleText(host, "RuntimeSweepReward_Header",
                $"扫荡{renderedSweepCount}次收益汇总", new Vector2(0f, 128f),
                new Vector2(560f, 36f), 24, new Color(0.58f, 0.31f, 0.14f, 1f),
                TextAnchor.MiddleCenter);
            for (int index = 0; index < values.Count && index < 8; index++)
            {
                RewardRecord reward = values[index];
                int row = index / 2;
                int column = index % 2;
                CreateRewardEntry(host, "RuntimeSweepReward_" + index, reward,
                    new Vector2(-260f + column * 280f, 72f - row * 72f),
                    new Vector2(270f, 58f), 19,
                    new Color(0.50f, 0.35f, 0.22f, 1f), string.Empty);
            }
        }

        private void RenderBattleRewards()
        {
            Transform host = battleView.GameObject.transform.Find("WorldBattleBackdrop/RewardPanel");
            if (host == null) return;
            ClearRuntimeChildren(host, "RuntimeBattleReward_");
            IReadOnlyList<RewardRecord> values = AggregateRewards(rewards.Items);
            RewardRecord heroExperience = values.FirstOrDefault(value => value.Type == 60052);
            RewardRecord petExperience = values.FirstOrDefault(value => value.Type == 60006);
            Debug.Log($"[ProjectX][World] Settlement render: playerLevel={player.Level}, playerExperience={player.Experience}, playerRewardExperience={heroExperience.Amount}, petRewardExperience={petExperience.Amount}, rewardCount={values.Count}.");
            RewardRecord[] money = values.Where(IsCocosMoneyReward).Take(4).ToArray();
            renderedMoneyRewardCount = money.Length;
            for (int index = 0; index < money.Length; index++)
                CreateMoneyRewardEntry(host, money[index], index);
            if (heroExperience.Amount > 0) CreatePlayerExperienceEntry(host, heroExperience);
            renderedPetExperienceCount = petExperience.Amount > 0
                ? CreatePetExperienceEntries(host, petExperience)
                : 0;
            RewardRecord[] items = values.Where(value => value.Type != 60052 && value.Type != 60006
                && !IsCocosMoneyReward(value)).Take(2).ToArray();
            renderedItemRewardCount = items.Length;
            Transform itemRewardLabel = host.Find("ItemRewardLabel");
            if (itemRewardLabel != null) itemRewardLabel.gameObject.SetActive(items.Length > 0);
            for (int index = 0; index < items.Length; index++)
                CreateBattleItemEntry(host, items[index], index);
        }

        private int CreatePetExperienceEntries(Transform parent, RewardRecord reward)
        {
            HeroRecord[] formationHeroes = heroes.Items
                .Where(value => value.FightPosition > 0)
                .OrderBy(value => value.FightPosition)
                .Take(5)
                .ToArray();
            if (formationHeroes.Length == 0)
            {
                Debug.LogWarning("[ProjectX][World] Settlement returned PetExp/60006 but /24 HeroStore has no deployed hero; no synthetic general data was rendered.");
                return 0;
            }

            CreateBattleText(parent, "RuntimeBattleReward_PetExperienceLabel", "神\n将\n经\n验",
                new Vector2(8f, -78f), new Vector2(40f, 116f), 20,
                new Color(1f, 0.86f, 0.62f, 1f), TextAnchor.MiddleCenter);
            for (int index = 0; index < formationHeroes.Length; index++)
            {
                HeroRecord hero = formationHeroes[index];
                GameObject entry = new GameObject($"RuntimeBattleReward_PetExperience{index}", typeof(RectTransform));
                RectTransform rect = entry.GetComponent<RectTransform>();
                rect.SetParent(parent, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(-210f + index * 104f, -78f);
                rect.sizeDelta = new Vector2(96f, 116f);

                bool hasDefinition = HeroCatalog.TryGet(hero.Id, out HeroDefinition definition);
                Sprite frameSprite = resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(hasDefinition ? definition.Quality : 1, 1, 7):00}");
                GameObject frameObject = new GameObject("QualityFrame", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform frameRect = frameObject.GetComponent<RectTransform>();
                frameRect.SetParent(rect, false);
                frameRect.anchorMin = frameRect.anchorMax = new Vector2(0.5f, 1f);
                frameRect.pivot = new Vector2(0.5f, 1f);
                frameRect.anchoredPosition = Vector2.zero;
                frameRect.sizeDelta = new Vector2(72f, 72f);
                Image frame = frameObject.GetComponent<Image>();
                frame.sprite = frameSprite;
                frame.raycastTarget = false;

                Sprite portrait = resources.LoadHeroPortrait(hasDefinition ? definition.Picture : 0);
                GameObject portraitObject = new GameObject("Portrait", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform portraitRect = portraitObject.GetComponent<RectTransform>();
                portraitRect.SetParent(frameRect, false);
                portraitRect.anchorMin = new Vector2(0.12f, 0.12f);
                portraitRect.anchorMax = new Vector2(0.88f, 0.88f);
                portraitRect.offsetMin = portraitRect.offsetMax = Vector2.zero;
                Image portraitImage = portraitObject.GetComponent<Image>();
                portraitImage.sprite = portrait;
                portraitImage.preserveAspect = true;
                portraitImage.raycastTarget = false;

                CreateBattleText(rect, "Gain", $"经验+{reward.Amount}", new Vector2(0f, -25f),
                    new Vector2(96f, 20f), 15, new Color(1f, 0.88f, 0.48f, 1f), TextAnchor.MiddleCenter);
                uint maximum = Math.Max(1u, hero.MaxExperience);
                GameObject bar = new GameObject("ExperienceBar", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform barRect = bar.GetComponent<RectTransform>();
                barRect.SetParent(rect, false);
                barRect.anchorMin = barRect.anchorMax = new Vector2(0.5f, 0f);
                barRect.pivot = new Vector2(0.5f, 0f);
                barRect.anchoredPosition = new Vector2(0f, 2f);
                barRect.sizeDelta = new Vector2(88f, 15f);
                Image background = bar.GetComponent<Image>();
                background.color = new Color(0.24f, 0.17f, 0.12f, 0.9f);
                background.raycastTarget = false;
                GameObject fill = new GameObject("Fill", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform fillRect = fill.GetComponent<RectTransform>();
                fillRect.SetParent(barRect, false);
                fillRect.anchorMin = Vector2.zero;
                fillRect.anchorMax = new Vector2(Mathf.Clamp01((float)hero.Experience / maximum), 1f);
                fillRect.offsetMin = fillRect.offsetMax = Vector2.zero;
                Image fillImage = fill.GetComponent<Image>();
                fillImage.color = new Color(0.45f, 0.88f, 0.12f, 1f);
                fillImage.raycastTarget = false;
                CreateBattleText(rect, "Level", hero.Level.ToString(), new Vector2(6f, 18f),
                    new Vector2(28f, 20f), 16, Color.white, TextAnchor.MiddleCenter);
            }
            return formationHeroes.Length;
        }

        private void CreateMoneyRewardEntry(Transform parent, RewardRecord reward, int index)
        {
            GameObject entry = new GameObject("RuntimeBattleReward_Money" + index, typeof(RectTransform));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = new Vector2(-326f + index * 165f, 115f);
            rect.sizeDelta = new Vector2(155f, 44f);

            Sprite sprite = LoadRewardSprite(reward);
            if (sprite != null)
            {
                GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(rect, false);
                iconRect.anchorMin = iconRect.anchorMax = new Vector2(0f, 0.5f);
                iconRect.pivot = new Vector2(0f, 0.5f);
                iconRect.anchoredPosition = Vector2.zero;
                iconRect.sizeDelta = new Vector2(31f, 31f);
                Image image = iconObject.GetComponent<Image>();
                image.sprite = sprite;
                image.preserveAspect = true;
                image.raycastTarget = false;
            }

            CreateBattleText(rect, "Amount", reward.Amount.ToString(), new Vector2(37f, 0f),
                new Vector2(112f, 30f), 22, new Color(1f, 0.9f, 0.55f, 1f), TextAnchor.MiddleLeft);
        }

        private static bool IsCocosMoneyReward(RewardRecord value)
        {
            switch (value.Type)
            {
                case 60000: case 60001: case 60003: case 60014:
                case 60021: case 60025: case 60026: case 60030:
                case 60050: case 60051: case 60054: case 60056:
                    return true;
                default:
                    return false;
            }
        }

        private void CreatePlayerExperienceEntry(Transform parent, RewardRecord reward)
        {
            GameObject entry = new GameObject("RuntimeBattleReward_HeroExperience", typeof(RectTransform));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = new Vector2(-267f, 34f);
            rect.sizeDelta = new Vector2(520f, 94f);

            Sprite portrait = resources.LoadPlayerRoundPortrait(player.Head);
            if (portrait != null)
            {
                GameObject iconObject = new GameObject("Portrait", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(rect, false);
                iconRect.anchorMin = iconRect.anchorMax = new Vector2(0f, 0.5f);
                iconRect.pivot = new Vector2(0f, 0.5f);
                iconRect.anchoredPosition = new Vector2(4f, 0f);
                iconRect.sizeDelta = new Vector2(80f, 80f);
                Image image = iconObject.GetComponent<Image>();
                image.sprite = portrait;
                image.preserveAspect = true;
                image.raycastTarget = false;

                Sprite frameSprite = Find(battleView,
                    "Layer/Panel/firPanel/zhujueayer/Icon_touxiangkuang")?.GetComponent<Image>()?.sprite;
                if (frameSprite != null)
                {
                    GameObject frameObject = new GameObject("PortraitFrame", typeof(RectTransform),
                        typeof(CanvasRenderer), typeof(Image));
                    RectTransform frameRect = frameObject.GetComponent<RectTransform>();
                    frameRect.SetParent(rect, false);
                    frameRect.anchorMin = frameRect.anchorMax = new Vector2(0f, 0.5f);
                    frameRect.pivot = new Vector2(0f, 0.5f);
                    frameRect.anchoredPosition = new Vector2(1f, 0f);
                    frameRect.sizeDelta = new Vector2(86f, 86f);
                    Image frame = frameObject.GetComponent<Image>();
                    frame.sprite = frameSprite;
                    frame.type = Image.Type.Sliced;
                    frame.fillCenter = false;
                    frame.raycastTarget = false;
                    frameObject.transform.SetAsLastSibling();
                }
            }

            CreateBattleText(rect, "Level", $"{player.Level}级", new Vector2(100f, 18f),
                new Vector2(92f, 30f), 24, new Color(0.2f, 1f, 0.25f, 1f), TextAnchor.MiddleLeft);
            CreateBattleText(rect, "Gain", $"经验+{reward.Amount}", new Vector2(395f, 18f),
                new Vector2(145f, 30f), 20, new Color(1f, 0.9f, 0.55f, 1f), TextAnchor.MiddleRight);

            int limit = Math.Max(1, WorldVisualCatalog.GetPlayerExperienceLimit(player.Level));
            // PRO_UPDATE_CHAR/502 is sent before the World settlement packet and
            // PlayerStore already contains this battle's experience gain here.
            ulong current = player.Experience;
            GameObject bar = new GameObject("ExperienceBar", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform barRect = bar.GetComponent<RectTransform>();
            barRect.SetParent(rect, false);
            barRect.anchorMin = barRect.anchorMax = new Vector2(0f, 0.5f);
            barRect.pivot = new Vector2(0f, 0.5f);
            barRect.anchoredPosition = new Vector2(100f, -21f);
            barRect.sizeDelta = new Vector2(460f, 22f);
            Image barImage = bar.GetComponent<Image>();
            barImage.color = new Color(0.78f, 0.75f, 0.70f, 1f);
            barImage.raycastTarget = false;
            GameObject fill = new GameObject("Fill", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform fillRect = fill.GetComponent<RectTransform>();
            fillRect.SetParent(barRect, false);
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = new Vector2(Mathf.Clamp01((float)current / limit), 1f);
            fillRect.offsetMin = fillRect.offsetMax = Vector2.zero;
            Image fillImage = fill.GetComponent<Image>();
            fillImage.color = new Color(0.55f, 0.9f, 0.12f, 1f);
            fillImage.raycastTarget = false;
            CreateBattleText(barRect, "Value", $"{current}/{limit}", Vector2.zero,
                new Vector2(460f, 22f), 18, new Color(0.18f, 0.13f, 0.10f, 1f), TextAnchor.MiddleCenter);
        }

        private void CreateBattleItemEntry(Transform parent, RewardRecord reward, int index)
        {
            GameObject entry = new GameObject("RuntimeBattleReward_Item" + index, typeof(RectTransform));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(-225f + index * 110f, -82f);
            rect.sizeDelta = new Vector2(110f, 112f);

            Sprite sprite = LoadRewardSprite(reward);
            Sprite frameSprite = !IsCocosSpecialReward(reward.Type) && reward.Quality > 0
                ? resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(reward.Quality, 1, 7):00}")
                : null;
            Transform iconParent = rect;
            if (frameSprite != null)
            {
                GameObject frameObject = new GameObject("QualityFrame", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                RectTransform frameRect = frameObject.GetComponent<RectTransform>();
                frameRect.SetParent(rect, false);
                frameRect.anchorMin = frameRect.anchorMax = new Vector2(0.5f, 1f);
                frameRect.pivot = new Vector2(0.5f, 1f);
                frameRect.anchoredPosition = Vector2.zero;
                frameRect.sizeDelta = new Vector2(88f, 88f);
                Image frame = frameObject.GetComponent<Image>();
                frame.sprite = frameSprite;
                frame.raycastTarget = false;
                iconParent = frameRect;
            }
            if (sprite != null)
            {
                GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(iconParent, false);
                iconRect.anchorMin = frameSprite == null ? new Vector2(0.5f, 1f) : new Vector2(0.12f, 0.12f);
                iconRect.anchorMax = frameSprite == null ? new Vector2(0.5f, 1f) : new Vector2(0.88f, 0.88f);
                iconRect.pivot = new Vector2(0.5f, frameSprite == null ? 1f : 0.5f);
                iconRect.anchoredPosition = Vector2.zero;
                iconRect.sizeDelta = frameSprite == null ? new Vector2(77f, 77f) : Vector2.zero;
                Image image = iconObject.GetComponent<Image>();
                image.sprite = sprite;
                image.preserveAspect = true;
                image.raycastTarget = false;
            }

            CreateBattleText(rect, "Amount", reward.Amount.ToString(), new Vector2(71f, -22f),
                new Vector2(32f, 20f), 17, Color.white, TextAnchor.MiddleRight);
            CreateBattleText(rect, "Name", reward.Name, new Vector2(0f, -50f),
                new Vector2(110f, 22f), 18, new Color(1f, 0.75f, 0.45f, 1f), TextAnchor.MiddleCenter);
        }

        private void CreateBattleText(Transform parent, string name, string value, Vector2 position,
            Vector2 size, int fontSize, Color color, TextAnchor alignment)
        {
            GameObject textObject = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = textObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Text text = textObject.GetComponent<Text>();
            text.font = FindRuntimeFont();
            text.fontSize = fontSize;
            text.alignment = alignment;
            text.color = color;
            text.text = value;
            text.raycastTarget = false;
        }

        private static IReadOnlyList<RewardRecord> AggregateRewards(IReadOnlyList<RewardRecord> values)
        {
            return values.GroupBy(value => new { value.Type, value.Id })
                .Select(group =>
                {
                    RewardRecord metadata = group.FirstOrDefault(value =>
                        !string.IsNullOrEmpty(value.Name) || value.Picture > 0 || value.Quality > 0);
                    return new RewardRecord(group.Key.Type, group.Key.Id,
                        checked((uint)group.Sum(value => (long)value.Amount)), metadata.Name,
                        metadata.Picture, metadata.Quality);
                })
                .ToArray();
        }

        private void CreateRewardEntry(Transform parent, string name, RewardRecord reward,
            Vector2 position, Vector2 size, int fontSize, Color color, string prefix)
        {
            GameObject entry = new GameObject(name, typeof(RectTransform));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;

            Sprite sprite = LoadRewardSprite(reward);
            float textInset = 0f;
            if (sprite != null)
            {
                float iconSize = size.y - 4f;
                GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(rect, false);
                iconRect.anchorMin = iconRect.anchorMax = new Vector2(0f, 0.5f);
                iconRect.pivot = new Vector2(0f, 0.5f);
                iconRect.anchoredPosition = new Vector2(6f, 0f);
                iconRect.sizeDelta = new Vector2(iconSize, iconSize);
                Image image = iconObject.GetComponent<Image>();
                image.sprite = sprite;
                image.preserveAspect = true;
                image.raycastTarget = false;

                if (!IsCocosSpecialReward(reward.Type) && reward.Quality > 0)
                {
                    Sprite frameSprite = resources.LoadFirst(
                        $"HeroUI/common_quality_{Mathf.Clamp(reward.Quality, 1, 7):00}");
                    if (frameSprite != null)
                    {
                        GameObject frameObject = new GameObject("QualityFrame", typeof(RectTransform),
                            typeof(CanvasRenderer), typeof(Image));
                        RectTransform frameRect = frameObject.GetComponent<RectTransform>();
                        frameRect.SetParent(rect, false);
                        frameRect.anchorMin = frameRect.anchorMax = new Vector2(0f, 0.5f);
                        frameRect.pivot = new Vector2(0f, 0.5f);
                        frameRect.anchoredPosition = new Vector2(6f, 0f);
                        frameRect.sizeDelta = new Vector2(iconSize, iconSize);
                        Image frame = frameObject.GetComponent<Image>();
                        frame.sprite = frameSprite;
                        frame.raycastTarget = false;
                        iconRect.SetParent(frameRect, false);
                        iconRect.anchorMin = new Vector2(0.12f, 0.12f);
                        iconRect.anchorMax = new Vector2(0.88f, 0.88f);
                        iconRect.pivot = new Vector2(0.5f, 0.5f);
                        iconRect.anchoredPosition = Vector2.zero;
                        iconRect.sizeDelta = Vector2.zero;
                    }
                }
                textInset = size.y + 8f;
            }

            GameObject textObject = new GameObject("Text", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(Shadow));
            RectTransform textRect = textObject.GetComponent<RectTransform>();
            textRect.SetParent(rect, false);
            textRect.anchorMin = Vector2.zero;
            textRect.anchorMax = Vector2.one;
            textRect.offsetMin = new Vector2(textInset, 0f);
            textRect.offsetMax = Vector2.zero;
            Text text = textObject.GetComponent<Text>();
            text.font = FindRuntimeFont();
            text.fontSize = fontSize;
            text.alignment = TextAnchor.MiddleLeft;
            text.color = color;
            text.raycastTarget = false;
            text.text = $"{prefix}{reward.Name}×{reward.Amount}";
            Shadow shadow = textObject.GetComponent<Shadow>();
            shadow.effectColor = new Color(0.2f, 0.12f, 0.08f, 0.85f);
            shadow.effectDistance = new Vector2(1.5f, -1.5f);
        }

        private static bool IsCocosSpecialReward(int type)
        {
            switch (type)
            {
                case 60000: case 60001: case 60003: case 60006: case 60007: case 60008:
                case 60009: case 60010: case 60011: case 60014: case 60015: case 60021:
                case 60025: case 60026: case 60027: case 60029: case 60030: case 60050:
                case 60051: case 60052: case 60053:
                    return true;
                default:
                    return false;
            }
        }

        private Sprite LoadRewardSprite(RewardRecord reward)
        {
            if (reward.Picture > 0) return resources.LoadItemIcon(reward.Picture);
            switch (reward.Type)
            {
                case 4601: return resources.LoadEquipmentIcon("petequip_2101");
                case 4602: return resources.LoadEquipmentIcon("petequip_2102");
                case 4603: return resources.LoadEquipmentIcon("petequip_2103");
                case 4604: return resources.LoadEquipmentIcon("petequip_2104");
                default: return null;
            }
        }

        private Font FindRuntimeFont()
        {
            return sweepView.GameObject.GetComponentInChildren<Text>(true)?.font
                ?? battleView.GameObject.GetComponentInChildren<Text>(true)?.font;
        }

        private static void ClearRuntimeChildren(Transform parent, string prefix)
        {
            foreach (Transform child in parent)
            {
                if (!child.name.StartsWith(prefix, StringComparison.Ordinal)) continue;
                child.gameObject.SetActive(false);
                UnityEngine.Object.Destroy(child.gameObject);
            }
        }

        private static void Reparent(CocosUiView view, Transform parent)
        {
            RectTransform rect = view.GameObject.transform as RectTransform;
            view.GameObject.transform.SetParent(parent, false);
            // Match the legacy doLayout result when a standalone outcome layer is
            // attached below WorldMapNewLayer.
            if (rect != null)
            {
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                rect.localScale = Vector3.one;
            }
            view.GameObject.SetActive(false);
        }

        private void EnsureBattleBackdrop()
        {
            Transform root = battleView.GameObject.transform;
            EnsureBattleResultDimmer();
            if (root.Find("WorldBattleBackdrop") != null)
            {
                if (victoryTitleAnimation == null)
                    victoryTitleAnimation = root.Find("WorldBattleBackdrop/VictoryTitleImod")
                        ?.GetComponent<ImodAnimationPlayer>();
                if (victoryTitleAnimation != null)
                {
                    victoryTitleEffect = victoryTitleAnimation.GetComponent<BattleResultImodOneShot>()
                        ?? victoryTitleAnimation.gameObject.AddComponent<BattleResultImodOneShot>();
                    victoryTitleEffect.Configure(victoryTitleAnimation);
                    victoryTitleEffect.Restart(35f / 60f);
                }
                return;
            }
            Sprite background = LoadWorldSprite("WorldUI/battle_victory_bg");
            Sprite title = Find(battleView, "Layer/Panel/victorypanel/win_bg/win3")
                ?.GetComponent<Image>()?.sprite ?? LoadWorldSprite("WorldUI/battle_victory");
            if (background == null && title == null) return;
            // The imported zhandoujiesuanLayer already owns the exact Cocos
            // 1334x550 alpha panel, separator lines and light wash. Keep this
            // runtime layer transparent so the still-live battle and imported
            // result background remain visible instead of replacing both with
            // a clean scene plus duplicate tint approximation.
            GameObject layer = new GameObject("WorldBattleBackdrop", typeof(RectTransform));
            layer.transform.SetParent(root, false);
            RectTransform rect = layer.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            layer.transform.SetAsLastSibling();
            if (background != null)
                CreateBattleImage(layer.transform, "VictoryCrest", background,
                    new Vector2(0.035f, 0.22f), new Vector2(0.40f, 0.89f));
            if (title != null)
                CreateBattleImage(layer.transform, "VictoryTitle", title,
                    new Vector2(0.035f, 0.315f), new Vector2(0.38f, 0.725f));
            GameObject titleEffect = new GameObject("VictoryTitleImod", typeof(RectTransform));
            RectTransform titleRect = titleEffect.GetComponent<RectTransform>();
            titleRect.SetParent(layer.transform, false);
            titleRect.anchorMin = titleRect.anchorMax = Vector2.zero;
            titleRect.pivot = Vector2.zero;
            // Current zhandoujiesuanLayer.csb placeholder transform. The Cocos
            // result callback attaches action 0 of this exact Imod at the node.
            titleRect.anchoredPosition = new Vector2(201.2585f, 283.952f);
            titleRect.sizeDelta = Vector2.zero;
            victoryTitleAnimation = titleEffect.AddComponent<ImodAnimationPlayer>();
            if (!victoryTitleAnimation.LoadLegacy("res2/animation/effect_zhandoujiesuan_2"))
                throw new InvalidOperationException("Current Cocos battle victory Imod is unavailable.");
            foreach (Image part in titleEffect.GetComponentsInChildren<Image>(true))
                part.raycastTarget = false;
            victoryTitleEffect = titleEffect.AddComponent<BattleResultImodOneShot>();
            victoryTitleEffect.Configure(victoryTitleAnimation);
            // FirstFightResultUI starts this one-shot from the CSB frame-35
            // callback. The Imod lasts 0.7 seconds and does not remain over the
            // stable settlement/statistics surfaces after completion.
            victoryTitleEffect.Restart(35f / 60f);
            titleEffect.transform.SetAsLastSibling();
            Sprite star = Find(battleView, "Layer/Panel/victorypanel/win_bg/starlayer/Star1")?.GetComponent<Image>()?.sprite;
            if (star != null)
            {
                CreateBattleImage(layer.transform, "VictoryStar0", star,
                    new Vector2(0.07f, 0.252f), new Vector2(0.155f, 0.432f));
                CreateBattleImage(layer.transform, "VictoryStar1", star,
                    new Vector2(0.16f, 0.19f), new Vector2(0.245f, 0.37f));
                CreateBattleImage(layer.transform, "VictoryStar2", star,
                    new Vector2(0.255f, 0.252f), new Vector2(0.34f, 0.432f));
            }

            GameObject rewardPanel = new GameObject("RewardPanel", typeof(RectTransform));
            RectTransform rewardRect = rewardPanel.GetComponent<RectTransform>();
            rewardRect.SetParent(layer.transform, false);
            rewardRect.anchorMin = new Vector2(0.43f, 0.37f);
            rewardRect.anchorMax = new Vector2(0.93f, 0.86f);
            rewardRect.offsetMin = rewardRect.offsetMax = Vector2.zero;
            CreateBattleHeader(rewardRect);
            CreateBattleText(rewardRect, "HeroRewardLabel", "主\n角\n经\n验", new Vector2(8f, 22f),
                new Vector2(40f, 116f), 20, new Color(1f, 0.86f, 0.62f, 1f), TextAnchor.MiddleCenter);
            CreateBattleText(rewardRect, "ItemRewardLabel", "物\n品\n奖\n励", new Vector2(8f, -106f),
                new Vector2(40f, 116f), 20, new Color(1f, 0.86f, 0.62f, 1f), TextAnchor.MiddleCenter);
            CreateBattleFooter(layer.transform);
        }

        private void EnsureBattleResultDimmer()
        {
            Transform layer = Find(battleView, "Layer")?.transform;
            if (layer == null)
                throw new InvalidOperationException("Imported battle result Layer binding is missing.");
            if (layer.Find("RuntimeBattleResult_Dimmer") != null) return;
            GameObject dimmer = new GameObject("RuntimeBattleResult_Dimmer", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = dimmer.GetComponent<RectTransform>();
            rect.SetParent(layer, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = dimmer.GetComponent<Image>();
            // The popup framework dims the live battle below the imported
            // zhandoujiesuanLayer; the source 550px panel and light wash then
            // render above this full-screen background dimmer.
            image.color = new Color(0f, 0f, 0f, 0.92f);
            image.raycastTarget = false;
            dimmer.transform.SetAsFirstSibling();
        }

        private void ApplyVictoryTitle(int stars, bool showStars)
        {
            VictoryTitleVariant = showStars ? Mathf.Clamp(stars, 1, 3) : 2;
            Sprite title = Find(battleView,
                $"Layer/Panel/victorypanel/win_bg/win{VictoryTitleVariant}")?.GetComponent<Image>()?.sprite;
            Image runtimeTitle = battleView.GameObject.transform
                .Find("WorldBattleBackdrop/VictoryTitle")?.GetComponent<Image>();
            if (runtimeTitle != null && title != null) runtimeTitle.sprite = title;
        }

        private static string NormalizeCocosFightName(string value) =>
            (value ?? string.Empty).Replace('·', ' ');

        private void CreateBattleFooter(Transform parent)
        {
            GameObject value = new GameObject("ResultSummary", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(0.12f, 0.10f);
            rect.anchorMax = new Vector2(0.40f, 0.17f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = value.GetComponent<Text>();
            text.font = FindRuntimeFont();
            text.fontSize = 24;
            text.alignment = TextAnchor.MiddleLeft;
            text.color = Color.white;
            text.text = "3星（无神将阵亡）";
            text.raycastTarget = false;

            Sprite statistics = Find(battleView, "Layer/Panel/victorypanel/Button_tongji")?.GetComponent<Image>()?.sprite;
            if (statistics != null)
                CreateBattleImage(parent, "StatisticsVisual", statistics,
                    new Vector2(0.055f, 0.035f), new Vector2(0.105f, 0.115f));
            Sprite replay = Find(battleView, "Layer/Panel/victorypanel/Button_Replay")?.GetComponent<Image>()?.sprite;
            if (replay != null)
            {
                Image replayVisual = CreateBattleImage(parent, "ReplayVisual", replay,
                    new Vector2(0.145f, 0.035f), new Vector2(0.267f, 0.115f));
                replayVisual.raycastTarget = true;
                replayInteractionGraphic = replayVisual;
                replayInteractionButton = replayVisual.gameObject.AddComponent<Button>();
                replayInteractionButton.targetGraphic = replayVisual;
                replayInteractionButton.onClick.AddListener(() =>
                {
                    Replay();
                    Mark("WORLD-22-BATTLE-RESULT-REPLAY");
                });
            }
            CreateAnchoredBattleText(parent, "StatisticsLabel", "统计",
                new Vector2(0.055f, 0.035f), new Vector2(0.105f, 0.115f), 19);
            CreateAnchoredBattleText(parent, "ReplayLabel", "回 放",
                new Vector2(0.145f, 0.035f), new Vector2(0.267f, 0.115f), 28);
            CreateAnchoredBattleText(parent, "ContinueLabel", "点击屏幕继续",
                new Vector2(0.39f, 0.015f), new Vector2(0.61f, 0.085f), 24);
        }

        private sealed class BattleResultImodOneShot : MonoBehaviour
        {
            private ImodAnimationPlayer player;
            private Image[] renderers = Array.Empty<Image>();
            private Coroutine pending;

            public bool IsEffectVisible => renderers.Any(value => value != null && value.enabled);
            public bool IsPlaying => player != null && player.IsPlaying;

            public void Configure(ImodAnimationPlayer value)
            {
                if (player == value) return;
                if (player != null) player.Completed -= HandleCompleted;
                player = value;
                renderers = GetComponentsInChildren<Image>(true);
                if (player != null) player.Completed += HandleCompleted;
            }

            public void Restart(float delaySeconds)
            {
                if (player == null || !player.IsLoaded)
                    throw new InvalidOperationException("Battle result Imod one-shot is not configured.");
                if (pending != null) StopCoroutine(pending);
                player.Stop();
                SetVisible(false);
                pending = StartCoroutine(PlayAfterDelay(Mathf.Max(0f, delaySeconds)));
            }

            private IEnumerator PlayAfterDelay(float delaySeconds)
            {
                if (delaySeconds > 0f) yield return new WaitForSecondsRealtime(delaySeconds);
                SetVisible(true);
                player.Play(0, false);
                pending = null;
            }

            private void HandleCompleted(int action)
            {
                if (action == 0) SetVisible(false);
            }

            private void SetVisible(bool value)
            {
                foreach (Image renderer in renderers)
                    if (renderer != null) renderer.enabled = value;
            }

            private void OnDisable()
            {
                if (pending != null)
                {
                    StopCoroutine(pending);
                    pending = null;
                }
                player?.Stop();
                SetVisible(false);
            }

            private void OnDestroy()
            {
                if (player != null) player.Completed -= HandleCompleted;
            }
        }

        private static Button CreateBattleHitTarget(Transform parent, string name,
            Vector2 anchorMin, Vector2 anchorMax, Action action)
        {
            GameObject target = new GameObject(name, typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image), typeof(Button));
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = target.GetComponent<Image>();
            // A fully transparent Image may be culled before GraphicRaycaster
            // sees it in batch-mode canvases. Keep an imperceptible alpha so
            // the player-facing replay surface owns real raycast geometry.
            image.color = new Color(0f, 0f, 0f, 0.001f);
            image.raycastTarget = true;
            image.canvasRenderer.cullTransparentMesh = false;
            Button button = target.GetComponent<Button>();
            button.targetGraphic = image;
            button.onClick.AddListener(() => action());
            return button;
        }

        private static void CreateBattlePanelShade(Transform parent)
        {
            GameObject shade = new GameObject("ResultShade", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = shade.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(0f, 0.20f);
            rect.anchorMax = new Vector2(1f, 0.90f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = shade.GetComponent<Image>();
            image.color = new Color(0.34f, 0.18f, 0.10f, 0.58f);
            image.raycastTarget = false;
            CreateBattleLine(parent, "ResultShadeTop", 0.90f);
            CreateBattleLine(parent, "ResultShadeBottom", 0.20f);
        }

        private static void CreateBattleLine(Transform parent, string name, float anchorY)
        {
            GameObject line = new GameObject(name, typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = line.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(0f, anchorY);
            rect.anchorMax = new Vector2(1f, anchorY);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(0f, 2f);
            Image image = line.GetComponent<Image>();
            image.color = new Color(0.85f, 0.69f, 0.50f, 0.45f);
            image.raycastTarget = false;
        }

        private void CreateAnchoredBattleText(Transform parent, string name, string value,
            Vector2 anchorMin, Vector2 anchorMax, int fontSize)
        {
            GameObject textObject = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = textObject.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Text text = textObject.GetComponent<Text>();
            text.font = FindRuntimeFont();
            text.fontSize = fontSize;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = Color.white;
            text.text = value;
            text.raycastTarget = false;
        }

        private static Image CreateBattleImage(Transform parent, string name, Sprite sprite,
            Vector2 anchorMin, Vector2 anchorMax)
        {
            GameObject value = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = value.GetComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = true;
            image.raycastTarget = false;
            return image;
        }

        private void CreateBattleHeader(Transform parent)
        {
            GameObject value = new GameObject("Header", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(1f, 1f);
            rect.pivot = new Vector2(0.5f, 1f);
            rect.anchoredPosition = new Vector2(0f, 0f);
            rect.sizeDelta = new Vector2(0f, 48f);
            Text text = value.GetComponent<Text>();
            text.font = FindRuntimeFont();
            text.fontSize = 28;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = new Color(1f, 0.92f, 0.65f, 1f);
            text.text = "◇ 通关奖励 ◇";
            text.raycastTarget = false;
        }

        private static Sprite LoadWorldSprite(string path)
        {
            Sprite sprite = Resources.Load<Sprite>(path);
            if (sprite != null) return sprite;
            Texture2D texture = Resources.Load<Texture2D>(path);
            return texture == null ? null : Sprite.Create(texture,
                new Rect(0f, 0f, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
        }

        private static Button Bind(CocosUiView view, string path, Action action)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            Graphic graphic = target.GetComponent<Graphic>();
            if (graphic == null && path == "Layer/Panel")
            {
                Image hitTarget = target.AddComponent<Image>();
                hitTarget.color = new Color(0f, 0f, 0f, 0f);
                hitTarget.raycastTarget = true;
                graphic = hitTarget;
            }
            button.targetGraphic = graphic ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
            return button;
        }

        private void Mark(string controlId) => validationControl?.Invoke(controlId);

        private static void SetText(CocosUiView view, string path, string value)
        {
            Text text = Find(view, path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetActive(CocosUiView view, string path, bool active)
        {
            GameObject target = Find(view, path);
            if (target != null) target.SetActive(active);
        }

        private static GameObject Require(CocosUiView view, string path) => Find(view, path)
            ?? throw new InvalidOperationException($"World result UI node was not found: {path}");

        private static GameObject Find(CocosUiView view, string path) => view.Binding.Find(path);
    }
}
