using System;
using System.Collections.Generic;
using System.Linq;
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
        private readonly RewardStore rewards;
        private readonly ResourceService resources;
        private readonly PlayerStore player;
        private readonly Action requestSweepAgain;
        private readonly Action requestContinue;
        private readonly Action requestReplay;
        private readonly Action showStatisticsUnavailable;
        private readonly Action showReviveUnavailable;
        private readonly Action<string> validationControl;
        private int renderedRewardCount;
        private int renderedSweepCount;
        private bool returnBattleAfterStatistics;

        public WorldOutcomePresenter(CocosUiView worldView, CocosUiView sweepView, CocosUiView battleView,
            CocosUiView statisticsView, RewardStore rewards, ResourceService resources, PlayerStore player,
            Action requestSweepAgain, Action requestContinue,
            Action requestReplay, Action showStatisticsUnavailable, Action showReviveUnavailable,
            Action<string> validationControl = null)
        {
            if (worldView == null) throw new ArgumentNullException(nameof(worldView));
            this.sweepView = sweepView ?? throw new ArgumentNullException(nameof(sweepView));
            this.battleView = battleView ?? throw new ArgumentNullException(nameof(battleView));
            this.statisticsView = statisticsView ?? throw new ArgumentNullException(nameof(statisticsView));
            this.rewards = rewards ?? throw new ArgumentNullException(nameof(rewards));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.requestSweepAgain = requestSweepAgain ?? throw new ArgumentNullException(nameof(requestSweepAgain));
            this.requestContinue = requestContinue ?? throw new ArgumentNullException(nameof(requestContinue));
            this.requestReplay = requestReplay ?? throw new ArgumentNullException(nameof(requestReplay));
            this.showStatisticsUnavailable = showStatisticsUnavailable ?? throw new ArgumentNullException(nameof(showStatisticsUnavailable));
            this.showReviveUnavailable = showReviveUnavailable ?? throw new ArgumentNullException(nameof(showReviveUnavailable));
            this.validationControl = validationControl;

            Reparent(sweepView, worldView.GameObject.transform);
            Reparent(battleView, worldView.GameObject.transform);
            Reparent(statisticsView, worldView.GameObject.transform);
            Bind(sweepView, "Layer/bg/Btn_close", () => { HideSweep(); Mark("WORLD-19-SWEEP-RESULT-CLOSE"); });
            Bind(sweepView, "Layer/bg/Image/Button", () => { HideSweep(); Mark("WORLD-19-SWEEP-RESULT-CLOSE"); });
            Bind(sweepView, "Layer/bg/Image/Button1", () => { SweepAgain(); Mark("WORLD-20-SWEEP-AGAIN"); });
            Bind(battleView, "Layer/Panel", () => { Continue(); Mark("WORLD-21-BATTLE-RESULT-CONTINUE"); });
            Bind(battleView, "Layer/Panel/victorypanel/Button_Replay", () => { Replay(); Mark("WORLD-22-BATTLE-RESULT-REPLAY"); });
            Bind(battleView, "Layer/Panel/victorypanel/Button_tongji", () => { ShowStatistics(); Mark("WORLD-23-BATTLE-STATISTICS"); });
            Bind(battleView, "Layer/Panel/firPanel/tontguanxinxilayer/Button_reborn", () => { Revive(); Mark("WORLD-24-BATTLE-REVIVE"); });
            Bind(statisticsView, "Layer/Panel", CloseStatistics);
            EnsureBattleBackdrop();
            rewards.Changed += Render;
            HideAll();
        }

        public bool IsSweepVisible => sweepView.GameObject.activeSelf;
        public bool IsBattleVisible => battleView.GameObject.activeSelf;
        public bool IsStatisticsVisible => statisticsView.GameObject.activeSelf;
        public int RenderedRewardCount => renderedRewardCount;

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

        public void ShowBattle(int stars)
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
            battleView.GameObject.transform.SetAsLastSibling();
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
            // The old statistics UI needs per-unit battle telemetry. /320 op=8 does
            // not send it, so expose the real imported page with an explicit boundary.
            returnBattleAfterStatistics = IsBattleVisible;
            HideBattle();
            SetText(statisticsView, "Layer/Panel/Panel_zhandoutongji/Panel_title_1/Panel_1/txt1", "当前结算包未提供单位战报");
            statisticsView.GameObject.SetActive(true);
            statisticsView.GameObject.transform.SetAsLastSibling();
            showStatisticsUnavailable();
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
            RewardRecord gold = values.FirstOrDefault(value => value.Type == 60000);
            RewardRecord heroExperience = values.FirstOrDefault(value => value.Type == 60052);
            if (gold.Amount > 0)
                CreateRewardEntry(host, "RuntimeBattleReward_Gold", gold,
                    new Vector2(-330f, 115f), new Vector2(380f, 58f), 25,
                    new Color(1f, 0.9f, 0.55f, 1f), string.Empty);
            if (heroExperience.Amount > 0) CreatePlayerExperienceEntry(host, heroExperience);
            RewardRecord[] items = values.Where(value => value.Type != 60000 && value.Type != 60052).Take(2).ToArray();
            for (int index = 0; index < items.Length; index++)
                CreateRewardEntry(host, "RuntimeBattleReward_Item" + index, items[index],
                    new Vector2(-278f, -75f - index * 70f), new Vector2(380f, 64f), 23,
                    new Color(1f, 0.9f, 0.55f, 1f), string.Empty);
        }

        private void CreatePlayerExperienceEntry(Transform parent, RewardRecord reward)
        {
            GameObject entry = new GameObject("RuntimeBattleReward_HeroExperience", typeof(RectTransform));
            RectTransform rect = entry.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0f, 0.5f);
            rect.anchoredPosition = new Vector2(-280f, 34f);
            rect.sizeDelta = new Vector2(420f, 88f);

            Sprite portrait = resources.LoadPlayerRoundPortrait(player.Head);
            if (portrait != null)
            {
                GameObject iconObject = new GameObject("Portrait", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(rect, false);
                iconRect.anchorMin = iconRect.anchorMax = new Vector2(0f, 0.5f);
                iconRect.pivot = new Vector2(0f, 0.5f);
                iconRect.anchoredPosition = Vector2.zero;
                iconRect.sizeDelta = new Vector2(76f, 76f);
                Image image = iconObject.GetComponent<Image>();
                image.sprite = portrait;
                image.preserveAspect = true;
                image.raycastTarget = false;
            }

            CreateBattleText(rect, "Level", $"{player.Level}级", new Vector2(84f, 18f),
                new Vector2(92f, 30f), 24, new Color(0.2f, 1f, 0.25f, 1f), TextAnchor.MiddleLeft);
            CreateBattleText(rect, "Gain", $"经验+{reward.Amount}", new Vector2(278f, 18f),
                new Vector2(135f, 30f), 22, new Color(1f, 0.9f, 0.55f, 1f), TextAnchor.MiddleRight);

            int limit = Math.Max(1, WorldVisualCatalog.GetPlayerExperienceLimit(player.Level));
            // PRO_UPDATE_CHAR/502 is sent before the World settlement packet and
            // PlayerStore already contains this battle's experience gain here.
            ulong current = player.Experience;
            GameObject bar = new GameObject("ExperienceBar", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform barRect = bar.GetComponent<RectTransform>();
            barRect.SetParent(rect, false);
            barRect.anchorMin = barRect.anchorMax = new Vector2(0f, 0.5f);
            barRect.pivot = new Vector2(0f, 0.5f);
            barRect.anchoredPosition = new Vector2(84f, -21f);
            barRect.sizeDelta = new Vector2(330f, 22f);
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
                new Vector2(330f, 22f), 18, new Color(0.18f, 0.13f, 0.10f, 1f), TextAnchor.MiddleCenter);
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
            if (root.Find("WorldBattleBackdrop") != null) return;
            Sprite background = LoadWorldSprite("WorldUI/battle_victory_bg");
            Sprite title = LoadWorldSprite("WorldUI/battle_victory");
            Sprite scene = LoadWorldSprite("WorldUI/battle_scene_bg");
            if (background == null && title == null && scene == null) return;
            GameObject layer = new GameObject("WorldBattleBackdrop", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            layer.transform.SetParent(root, false);
            RectTransform rect = layer.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = layer.GetComponent<Image>();
            image.sprite = scene;
            image.color = Color.white;
            image.preserveAspect = false;
            image.raycastTarget = false;
            layer.transform.SetAsLastSibling();
            GameObject tint = new GameObject("BattleTint", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform tintRect = tint.GetComponent<RectTransform>();
            tintRect.SetParent(layer.transform, false);
            tintRect.anchorMin = Vector2.zero;
            tintRect.anchorMax = Vector2.one;
            tintRect.offsetMin = tintRect.offsetMax = Vector2.zero;
            Image tintImage = tint.GetComponent<Image>();
            // Match the gamma-space darkening used by the Cocos result layer.
            tintImage.color = new Color(0f, 0f, 0f, 0.92f);
            tintImage.raycastTarget = false;
            CreateBattlePanelShade(layer.transform);
            if (background != null)
                CreateBattleImage(layer.transform, "VictoryCrest", background,
                    new Vector2(0.035f, 0.19f), new Vector2(0.40f, 0.86f));
            if (title != null)
                CreateBattleImage(layer.transform, "VictoryTitle", title,
                    new Vector2(0.035f, 0.29f), new Vector2(0.38f, 0.70f));
            Sprite star = Find(battleView, "Layer/Panel/victorypanel/win_bg/starlayer/Star1")?.GetComponent<Image>()?.sprite;
            if (star != null)
                for (int index = 0; index < 3; index++)
                    CreateBattleImage(layer.transform, "VictoryStar" + index, star,
                        new Vector2(0.06f + index * 0.105f, 0.22f),
                        new Vector2(0.145f + index * 0.105f, 0.40f));

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
                CreateBattleImage(parent, "ReplayVisual", replay,
                    new Vector2(0.145f, 0.035f), new Vector2(0.267f, 0.115f));
            CreateAnchoredBattleText(parent, "StatisticsLabel", "统计",
                new Vector2(0.055f, 0.035f), new Vector2(0.105f, 0.115f), 19);
            CreateAnchoredBattleText(parent, "ReplayLabel", "回 放",
                new Vector2(0.145f, 0.035f), new Vector2(0.267f, 0.115f), 28);
            CreateAnchoredBattleText(parent, "ContinueLabel", "点击屏幕继续",
                new Vector2(0.39f, 0.015f), new Vector2(0.61f, 0.085f), 24);
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

        private static void CreateBattleImage(Transform parent, string name, Sprite sprite,
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

        private static void Bind(CocosUiView view, string path, Action action)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => action());
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
