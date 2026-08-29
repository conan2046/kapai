using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Animation;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class WorldBattlePlaybackPresenter : IDisposable
    {
        private sealed class UnitView
        {
            public WorldBattleUnitRecord Data;
            public RectTransform Root;
            public Vector3 Home;
            public ImodAnimationPlayer Model;
            public Image Portrait;
            public Image HealthFill;
            public Text DamageLabel;
            public ulong CurrentHp;
            public string AnimationBase;
        }

        private readonly WorldBattleReplayStore store;
        private readonly ResourceService resources;
        private readonly GameObject root;
        private readonly Dictionary<byte, UnitView> units = new Dictionary<byte, UnitView>();
        private readonly ImodAnimationPlayer startEffect;
        private readonly Text roundLabel;
        private readonly Button speedButton;
        private readonly Text speedLabel;
        private readonly Button skipButton;
        private UnitView activeSource;
        private UnitView activeTarget;
        private byte activeActionType;
        private WorldBattleActionRecord activeAction;
        private bool impactApplied;

        // Exact FightLayer.csb Position/Image_1..18 coordinates, normalized from
        // the authoritative 1334x750 Cocos layout. The legacy World battle flips
        // positions 1..9 to the right when the local formation owns that half.
        private static readonly Vector2[] CocosUnitAnchors =
        {
            Vector2.zero,
            new Vector2(614f / 1334f, 459f / 750f), new Vector2(478f / 1334f, 390f / 750f),
            new Vector2(340f / 1334f, 321.975f / 750f), new Vector2(486f / 1334f, 516f / 750f),
            new Vector2(348f / 1334f, 446.025f / 750f), new Vector2(210f / 1334f, 381.975f / 750f),
            new Vector2(356f / 1334f, 572.025f / 750f), new Vector2(218f / 1334f, 504f / 750f),
            new Vector2(84f / 1334f, 438f / 750f), new Vector2(958f / 1334f, 356.025f / 750f),
            new Vector2(818f / 1334f, 290.025f / 750f), new Vector2(680f / 1334f, 222f / 750f),
            new Vector2(1084f / 1334f, 297.975f / 750f), new Vector2(950f / 1334f, 234f / 750f),
            new Vector2(810f / 1334f, 162f / 750f), new Vector2(1214f / 1334f, 240f / 750f),
            new Vector2(1076f / 1334f, 174f / 750f), new Vector2(942f / 1334f, 105.975f / 750f)
        };

        public float PlaybackSpeed { get; private set; } = 1f;
        public bool SkipRequested { get; private set; }

        public WorldBattlePlaybackPresenter(Transform parent, WorldBattleReplayStore store, ResourceService resources)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            root = new GameObject("WorldBattlePlayback", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = root.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image background = root.GetComponent<Image>();
            background.sprite = resources.LoadSprite("WorldUI/battle_scene_bg");
            background.color = Color.white;
            background.raycastTarget = true;

            GameObject effect = new GameObject("BattleStartEffect", typeof(RectTransform));
            RectTransform effectRect = effect.GetComponent<RectTransform>();
            effectRect.SetParent(rect, false);
            effectRect.anchorMin = effectRect.anchorMax = new Vector2(.5f, .55f);
            effectRect.sizeDelta = new Vector2(560f, 260f);
            startEffect = effect.AddComponent<ImodAnimationPlayer>();
            effect.SetActive(false);

            roundLabel = CreateText(rect, "Round", new Vector2(.5f, .965f), new Vector2(260f, 48f), 28,
                new Color(.87f, .93f, 1f, 1f), TextAnchor.MiddleCenter);
            roundLabel.fontStyle = FontStyle.Bold;
            speedButton = CreateControlButton(rect, "Speed", new Vector2(.875f, .075f), "×3\n加速", out speedLabel);
            speedButton.onClick.AddListener(ToggleSpeed);
            skipButton = CreateControlButton(rect, "Skip", new Vector2(.955f, .075f), "跳过", out _);
            skipButton.onClick.AddListener(() => SkipRequested = true);
            root.SetActive(false);
        }

        public bool IsVisible => root.activeSelf;

        public void Show()
        {
            ClearUnits();
            PlaybackSpeed = 1f;
            SkipRequested = false;
            speedLabel.text = "×3\n加速";
            skipButton.gameObject.SetActive(store.CanSkip);
            roundLabel.text = $"01/{Mathf.Max(1, store.MaxTurns):00}";
            foreach (WorldBattleUnitRecord unit in store.Units.Take(18))
            {
                UnitView view = CreateUnit(root.transform, unit, ResolveCocosAnchor(unit), unit.IsEnemy);
                units[unit.Position] = view;
            }
            root.SetActive(true);
            root.transform.SetAsLastSibling();
            Canvas.ForceUpdateCanvases();
            foreach (UnitView unit in units.Values) unit.Home = unit.Root.localPosition;
            PlayStartEffect();
        }

        public void BeginAction(WorldBattleActionRecord action)
        {
            activeSource = ResolveSource(action);
            activeTarget = ResolveTarget(action, activeSource);
            activeActionType = action?.FirstActionType ?? 0;
            activeAction = action;
            impactApplied = false;
            if (action != null)
                roundLabel.text = $"{Mathf.Max(1, action.Round):00}/{Mathf.Max(1, store.MaxTurns):00}";
            if (activeSource == null) return;
            HideDamage(activeSource);
            HideDamage(activeTarget);
            bool skill = action != null && (action.SkillId > 0 || activeActionType == 2 || activeActionType == 3);
            PlayUnitAnimation(activeSource, skill ? "sf1" : "gj", false);
        }

        public void SetActionProgress(float progress)
        {
            if (activeSource == null) return;
            float clamped = Mathf.Clamp01(progress);
            if (!impactApplied && clamped >= .42f) ApplyImpact();
            AnimateDamage(activeTarget, clamped);
            if (activeSource != activeTarget) AnimateDamage(activeSource, clamped);
            if (activeTarget != null && activeTarget != activeSource)
            {
                if (activeActionType == 1)
                {
                    Vector3 toward = Vector3.Lerp(activeSource.Home, activeTarget.Home, .58f);
                    float lunge = clamped < .42f
                        ? Mathf.SmoothStep(0f, 1f, clamped / .42f)
                        : Mathf.SmoothStep(1f, 0f, (clamped - .42f) / .58f);
                    activeSource.Root.localPosition = Vector3.Lerp(activeSource.Home, toward, lunge);
                }
                if (clamped >= .30f && clamped <= .62f)
                    SetUnitColor(activeTarget, activeActionType == 2
                        ? new Color(.42f, 1f, .48f, 1f)
                        : activeActionType == 3 ? new Color(.45f, .72f, 1f, 1f) : new Color(1f, .42f, .35f, 1f));
                else SetUnitColor(activeTarget, Color.white);
            }
        }

        public void EndAction()
        {
            if (!impactApplied) ApplyImpact();
            if (activeSource != null)
            {
                activeSource.Root.localPosition = activeSource.Home;
                HideDamage(activeSource);
                if (activeAction == null || !activeAction.SourceDead) PlayUnitAnimation(activeSource, "zd", true);
            }
            if (activeTarget != null)
            {
                SetUnitColor(activeTarget, Color.white);
                HideDamage(activeTarget);
                if (activeAction == null || !activeAction.FirstTargetDead) PlayUnitAnimation(activeTarget, "zd", true);
            }
            activeSource = activeTarget = null;
            activeActionType = 0;
            activeAction = null;
            impactApplied = false;
        }

        public void ShowOutcome()
        {
            foreach (UnitView unit in units.Values.Where(value => value.Data.IsEnemy == store.Won))
                PlayUnitAnimation(unit, "sw", false);
        }

        public void Hide()
        {
            startEffect.gameObject.SetActive(false);
            root.SetActive(false);
        }

        public void Dispose()
        {
            if (root != null) UnityEngine.Object.Destroy(root);
        }

        private void PlayStartEffect()
        {
            startEffect.gameObject.SetActive(false);
            if (!startEffect.LoadLegacy("res2/fx/zhandoukaishi")) return;
            startEffect.gameObject.SetActive(true);
            try { startEffect.Play(0, false); }
            catch { startEffect.gameObject.SetActive(false); }
        }

        private UnitView ResolveSource(WorldBattleActionRecord action)
        {
            if (action != null && units.TryGetValue(action.FirstSourcePosition, out UnitView source)) return source;
            return units.Values.FirstOrDefault();
        }

        private UnitView ResolveTarget(WorldBattleActionRecord action, UnitView source)
        {
            if (action != null && units.TryGetValue(action.FirstTargetPosition, out UnitView target)) return target;
            if (source == null) return null;
            return units.Values
                .Where(value => value.Data.IsEnemy != source.Data.IsEnemy)
                .OrderBy(value => Vector3.SqrMagnitude(value.Home - source.Home))
                .FirstOrDefault();
        }

        private UnitView CreateUnit(Transform parent, WorldBattleUnitRecord unit, Vector2 anchor, bool enemy)
        {
            GameObject value = new GameObject($"Unit_{unit.Position}", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = anchor;
            rect.sizeDelta = new Vector2(160f, 200f);
            var view = new UnitView { Data = unit, Root = rect, CurrentHp = unit.CurrentHp };

            int picture = checked((int)Math.Min(unit.Picture, (uint)int.MaxValue));
            if (unit.Type == 2 && HeroCatalog.TryGet(picture, out HeroDefinition hero)) picture = hero.Picture;
            if (unit.Type != 1 && picture > 0)
            {
                view.AnimationBase = $"Monster/btm{picture}_";
                view.Model = value.AddComponent<ImodAnimationPlayer>();
                view.Model.SetFlippedX(!enemy);
                if (!PlayUnitAnimation(view, "zd", true)) view.Model = null;
            }
            if (view.Model == null)
            {
                view.Portrait = value.AddComponent<Image>();
                view.Portrait.sprite = resources.LoadHeroPortrait(picture);
                view.Portrait.preserveAspect = true;
                view.Portrait.raycastTarget = false;
            }
            view.HealthFill = CreateHealthBar(rect, unit, enemy);
            view.DamageLabel = CreateText(rect, "Damage", new Vector2(.5f, .7f), new Vector2(220f, 50f), 28,
                new Color(1f, .22f, .12f, 1f), TextAnchor.MiddleCenter);
            view.DamageLabel.fontStyle = FontStyle.Bold;
            view.DamageLabel.gameObject.SetActive(false);
            return view;
        }

        private static Image CreateHealthBar(Transform parent, WorldBattleUnitRecord unit, bool enemy)
        {
            GameObject backgroundObject = new GameObject("HealthBar", typeof(RectTransform), typeof(Image));
            RectTransform backgroundRect = backgroundObject.GetComponent<RectTransform>();
            backgroundRect.SetParent(parent, false);
            backgroundRect.anchorMin = new Vector2(.13f, .91f);
            backgroundRect.anchorMax = new Vector2(.87f, .96f);
            backgroundRect.offsetMin = backgroundRect.offsetMax = Vector2.zero;
            backgroundObject.GetComponent<Image>().color = new Color(.08f, .06f, .04f, .82f);

            GameObject fillObject = new GameObject("Fill", typeof(RectTransform), typeof(Image));
            RectTransform fillRect = fillObject.GetComponent<RectTransform>();
            fillRect.SetParent(backgroundRect, false);
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = Vector2.one;
            fillRect.offsetMin = new Vector2(2f, 2f);
            fillRect.offsetMax = new Vector2(-2f, -2f);
            Image fill = fillObject.GetComponent<Image>();
            fill.color = enemy ? new Color(.86f, .20f, .16f, 1f) : new Color(.24f, .82f, .26f, 1f);
            fill.type = Image.Type.Filled;
            fill.fillMethod = Image.FillMethod.Horizontal;
            fill.fillOrigin = (int)Image.OriginHorizontal.Left;
            fill.fillAmount = unit.MaxHp == 0 ? 0f : Mathf.Clamp01((float)((double)unit.CurrentHp / unit.MaxHp));
            fill.raycastTarget = false;
            return fill;
        }

        private void ApplyImpact()
        {
            impactApplied = true;
            if (activeAction == null) return;
            if (activeTarget != null)
            {
                if (activeAction.FirstActionType == 1 && activeAction.FirstTargetHit)
                {
                    ApplyHpDelta(activeTarget, -(long)activeAction.FirstTargetDamage);
                    ShowDamage(activeTarget, $"-{activeAction.FirstTargetDamage}",
                        activeAction.FirstTargetCritical ? new Color(1f, .82f, .08f, 1f) : new Color(1f, .22f, .12f, 1f));
                    PlayUnitAnimation(activeTarget, activeAction.FirstTargetDead ? "sw" : "bj", false);
                }
                else if (activeAction.FirstActionType == 2)
                {
                    ApplyHpDelta(activeTarget, activeAction.FirstTargetHealing);
                    ShowDamage(activeTarget, $"+{activeAction.FirstTargetHealing}", new Color(.2f, 1f, .32f, 1f));
                }
                else if (activeAction.FirstTargetDead)
                {
                    PlayUnitAnimation(activeTarget, "sw", false);
                }
            }
            if (activeSource != null)
            {
                long sourceDelta = activeAction.SourceHpChanged + (long)activeAction.SourceHpRecovered;
                if (sourceDelta != 0)
                {
                    ApplyHpDelta(activeSource, sourceDelta);
                    ShowDamage(activeSource, sourceDelta > 0 ? $"+{sourceDelta}" : sourceDelta.ToString(),
                        sourceDelta > 0 ? new Color(.2f, 1f, .32f, 1f) : new Color(1f, .22f, .12f, 1f));
                }
                if (activeAction.SourceDead) PlayUnitAnimation(activeSource, "sw", false);
            }
        }

        private static void ApplyHpDelta(UnitView unit, long delta)
        {
            if (unit == null) return;
            long current = unit.CurrentHp > long.MaxValue ? long.MaxValue : (long)unit.CurrentHp;
            long maximum = unit.Data.MaxHp > long.MaxValue ? long.MaxValue : (long)unit.Data.MaxHp;
            current = Math.Max(0L, Math.Min(maximum, current + delta));
            unit.CurrentHp = (ulong)current;
            if (unit.HealthFill != null)
                unit.HealthFill.fillAmount = maximum <= 0 ? 0f : Mathf.Clamp01((float)((double)current / maximum));
        }

        private static bool PlayUnitAnimation(UnitView unit, string suffix, bool loop)
        {
            if (unit?.Model == null || string.IsNullOrWhiteSpace(unit.AnimationBase)) return false;
            if (!unit.Model.LoadLegacy(unit.AnimationBase + suffix)) return false;
            unit.Model.SetFlippedX(!unit.Data.IsEnemy);
            try
            {
                unit.Model.Play(0, loop);
                return true;
            }
            catch { return false; }
        }

        private static void SetUnitColor(UnitView unit, Color color)
        {
            if (unit?.Model != null) unit.Model.SetColor(color);
            if (unit?.Portrait != null) unit.Portrait.color = color;
        }

        private static Vector2 ResolveCocosAnchor(WorldBattleUnitRecord unit)
        {
            int source = Mathf.Clamp(unit.Position, 1, 18);
            int displayed = unit.IsEnemy ? source - 9 : source + 9;
            if (displayed < 1 || displayed >= CocosUnitAnchors.Length) displayed = source;
            return CocosUnitAnchors[displayed];
        }

        private static Text CreateText(Transform parent, string name, Vector2 anchor, Vector2 size, int fontSize,
            Color color, TextAnchor alignment)
        {
            GameObject value = new GameObject(name, typeof(RectTransform), typeof(Text));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = anchor;
            rect.sizeDelta = size;
            Text text = value.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = fontSize;
            text.alignment = alignment;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static Button CreateControlButton(Transform parent, string name, Vector2 anchor, string caption,
            out Text label)
        {
            GameObject value = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = anchor;
            rect.sizeDelta = new Vector2(88f, 72f);
            Image image = value.GetComponent<Image>();
            image.color = new Color(.48f, .20f, .10f, .92f);
            Button button = value.GetComponent<Button>();
            button.targetGraphic = image;
            label = CreateText(rect, "Label", new Vector2(.5f, .5f), rect.sizeDelta, 20, new Color(1f, .88f, .55f, 1f),
                TextAnchor.MiddleCenter);
            label.fontStyle = FontStyle.Bold;
            label.text = caption;
            return button;
        }

        private void ToggleSpeed()
        {
            PlaybackSpeed = PlaybackSpeed > 1f ? 1f : 3f;
            speedLabel.text = PlaybackSpeed > 1f ? "×1\n减速" : "×3\n加速";
        }

        private static void ShowDamage(UnitView unit, string value, Color color)
        {
            if (unit?.DamageLabel == null || string.IsNullOrWhiteSpace(value)) return;
            unit.DamageLabel.text = value;
            unit.DamageLabel.color = color;
            unit.DamageLabel.rectTransform.anchoredPosition = Vector2.zero;
            unit.DamageLabel.gameObject.SetActive(true);
        }

        private static void AnimateDamage(UnitView unit, float progress)
        {
            if (unit?.DamageLabel == null || !unit.DamageLabel.gameObject.activeSelf || progress < .42f) return;
            float phase = Mathf.Clamp01((progress - .42f) / .58f);
            unit.DamageLabel.rectTransform.anchoredPosition = new Vector2(0f, phase * 42f);
            Color color = unit.DamageLabel.color;
            color.a = 1f - Mathf.SmoothStep(.45f, 1f, phase);
            unit.DamageLabel.color = color;
        }

        private static void HideDamage(UnitView unit)
        {
            if (unit?.DamageLabel != null) unit.DamageLabel.gameObject.SetActive(false);
        }

        private void ClearUnits()
        {
            foreach (UnitView view in units.Values)
                if (view?.Root != null) UnityEngine.Object.Destroy(view.Root.gameObject);
            units.Clear();
            activeSource = activeTarget = null;
            activeActionType = 0;
        }
    }
}
