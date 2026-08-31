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
            public ImodAnimationPlayer QualityEffect;
            public ImodAnimationPlayer Model;
            public Image Portrait;
            public RectTransform HealthRoot;
            public Image HealthFill;
            public BattleUnitHitDefinition HitDefinition;
            public RectTransform NumberRoot;
            public Text StatusLabel;
            public Vector2 NumberBasePosition;
            public bool NumberCritical;
            public Text NameLabel;
            public Text SkillLabel;
            public Image CombatMarker;
            public ulong CurrentHp;
            public string AnimationBase;
            public readonly List<GameObject> BuffVisuals = new List<GameObject>();
        }

        private sealed class ScheduledClip
        {
            public BattleActionClip Clip;
            public float StartSeconds;
            public float DurationSeconds;
            public bool Triggered;
        }

        private sealed class ScheduledShake
        {
            public float StartSeconds;
            public float DurationSeconds;
            public float Strength;
        }

        private readonly WorldBattleReplayStore store;
        private readonly ResourceService resources;
        private readonly BattlePresentationCatalog presentationCatalog;
        private readonly GameObject root;
        private readonly Transform battleLayer;
        private readonly Transform unitLayer;
        private readonly CocosUiView importedView;
        private readonly Dictionary<byte, UnitView> units = new Dictionary<byte, UnitView>();
        private readonly List<ScheduledClip> activeClips = new List<ScheduledClip>();
        private readonly List<ScheduledShake> activeShakes = new List<ScheduledShake>();
        private readonly List<GameObject> activeEffects = new List<GameObject>();
        private readonly Image startShade;
        private readonly ImodAnimationPlayer startEffect;
        private readonly AudioSource battleAudio;
        private readonly Text roundLabel;
        private readonly Text friendlyLabel;
        private readonly Text enemyLabel;
        private readonly Button speedButton;
        private readonly Text speedLabel;
        private readonly Button skipButton;
        private readonly Action<string> showControlMessage;
        private readonly Func<int> loadSpeedStep;
        private readonly Action<int> saveSpeedStep;
        private Sprite[] roundAtlasSprites = Array.Empty<Sprite>();
        private Image[] roundAtlasGlyphs = Array.Empty<Image>();
        private Sprite[] battleNumberAtlasSprites = Array.Empty<Sprite>();
        private UnitView activeSource;
        private UnitView activeTarget;
        private readonly List<UnitView> activeTargets = new List<UnitView>();
        private readonly List<UnitView> activeProtectors = new List<UnitView>();
        private byte activeActionType;
        private WorldBattleActionRecord activeAction;
        private bool impactApplied;
        private float actionDurationSeconds = 1f;
        private float impactProgress = .5f;
        private float recommendedSkillCaptureProgress = .5f;
        private Vector3 moveStart;
        private Vector3 moveEnd;
        private float moveStartProgress;
        private float moveEndProgress;
        private bool moveActive;
        private Vector3 battleRootHome;
        private static readonly float CocosStartShadeOpacity =
            1f - Mathf.GammaToLinearSpace(1f - 150f / 255f);

        public float RecommendedActionDurationSeconds => actionDurationSeconds;
        public float ImpactProgress => impactProgress;
        public float RecommendedSkillCaptureProgress => recommendedSkillCaptureProgress;
        public string LastActionTrace { get; private set; } = string.Empty;
        public bool IsCameraShaking { get; private set; }

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

        private static readonly int[] CocosSpeedLabels = { 1, 2, 3, 5, 10, 15 };
        private static readonly float[] CocosPlaybackFactors = { 1f, 2f, 3f, 3.5f, 4f, 4.5f };
        private int speedStep;
        public float PlaybackSpeed { get; private set; } = 1f;
        public int SpeedDisplayMultiplier => CocosSpeedLabels[Mathf.Clamp(speedStep, 0, CocosSpeedLabels.Length - 1)];
        public bool SkipRequested { get; private set; }
        public int DirectionalModelCount => units.Values.Count(value => value?.Model != null);
        public bool UnitDirectionalActionsCorrect => units.Values
            .Where(value => value?.Model != null)
            .All(value => value.Model.CurrentAction == ResolveUnitActionIndex(value));

        public WorldBattlePlaybackPresenter(Transform parent, WorldBattleReplayStore store, ResourceService resources,
            CocosUiView importedView = null, Action<string> showControlMessage = null,
            Func<int> loadSpeedStep = null, Action<int> saveSpeedStep = null)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.importedView = importedView;
            this.showControlMessage = showControlMessage;
            this.loadSpeedStep = loadSpeedStep;
            this.saveSpeedStep = saveSpeedStep;
            speedStep = Mathf.Clamp(loadSpeedStep?.Invoke() ?? 0, 0, CocosSpeedLabels.Length - 1);
            PlaybackSpeed = CocosPlaybackFactors[speedStep];
            presentationCatalog = BattlePresentationCatalog.LoadFromResources();
            RectTransform rect;
            if (importedView?.GameObject != null)
            {
                root = importedView.GameObject;
                GameObject fightUi = importedView.Binding.Find("Layer/FightUI");
                battleLayer = fightUi != null ? fightUi.transform : root.transform;
                unitLayer = importedView.Binding.Find("Layer/FightUI/Position")?.transform ?? battleLayer;
                rect = battleLayer as RectTransform ?? root.GetComponent<RectTransform>();
                ConfigureImportedFightLayer();
            }
            else
            {
                root = new GameObject("WorldBattlePlayback", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                rect = root.GetComponent<RectTransform>();
                rect.SetParent(parent, false);
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = rect.offsetMax = Vector2.zero;
                Image background = root.GetComponent<Image>();
                background.sprite = resources.LoadSprite("WorldUI/battle_scene_bg");
                background.color = Color.white;
                background.raycastTarget = true;
                battleLayer = rect;
                unitLayer = battleLayer;
            }

            GameObject shade = new GameObject("BattleStartShade", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform shadeRect = shade.GetComponent<RectTransform>();
            shadeRect.SetParent(battleLayer, false);
            shadeRect.anchorMin = Vector2.zero;
            shadeRect.anchorMax = Vector2.one;
            shadeRect.offsetMin = shadeRect.offsetMax = Vector2.zero;
            startShade = shade.GetComponent<Image>();
            // Cocos blends its 150/255 LayerColor in gamma space. Unity's
            // linear UI blend needs the converted opacity for the same pixels.
            startShade.color = new Color(0f, 0f, 0f, CocosStartShadeOpacity);
            startShade.raycastTarget = false;
            shade.SetActive(false);

            GameObject effect = new GameObject("BattleStartEffect", typeof(RectTransform));
            RectTransform effectRect = effect.GetComponent<RectTransform>();
            effectRect.SetParent(battleLayer, false);
            effectRect.anchorMin = effectRect.anchorMax = new Vector2(.5f, .55f);
            effectRect.sizeDelta = new Vector2(560f, 260f);
            startEffect = effect.AddComponent<ImodAnimationPlayer>();
            startEffect.SetPlayOnEnable(false);
            startEffect.Completed += _ => startEffect.gameObject.SetActive(false);
            effect.SetActive(false);
            battleAudio = root.GetComponent<AudioSource>();
            if (battleAudio == null) battleAudio = root.AddComponent<AudioSource>();
            battleAudio.playOnAwake = false;
            battleAudio.loop = false;
            battleAudio.spatialBlend = 0f;

            if (importedView?.GameObject != null)
            {
                roundLabel = RequireImportedComponent<Text>("Layer/FightUI/Round_Special/Num");
                roundLabel.enabled = false;
                CreateRoundAtlas(roundLabel.transform);
                friendlyLabel = RequireImportedComponent<Text>("Layer/FightUI/btn_Formation_Enemy/Text_name");
                enemyLabel = RequireImportedComponent<Text>("Layer/FightUI/btn_Formation_Oneself/Text_name");
                speedButton = RequireImportedComponent<Button>("Layer/FightUI/Buttons/btn_Speed");
                skipButton = RequireImportedComponent<Button>("Layer/FightUI/Buttons/btn_jump");
                speedLabel = null;
                speedButton.onClick.RemoveAllListeners();
                speedButton.onClick.AddListener(ToggleSpeed);
                skipButton.onClick.RemoveAllListeners();
                skipButton.onClick.AddListener(RequestSkip);
            }
            else
            {
                roundLabel = CreateText(rect, "Round", new Vector2(.5f, .965f), new Vector2(260f, 48f), 28,
                    new Color(.87f, .93f, 1f, 1f), TextAnchor.MiddleCenter);
                roundLabel.fontStyle = FontStyle.Bold;
                friendlyLabel = null;
                enemyLabel = null;
                speedButton = CreateControlButton(rect, "Speed", new Vector2(.875f, .075f), "×5\n加速", out speedLabel);
                speedButton.onClick.AddListener(ToggleSpeed);
                skipButton = CreateControlButton(rect, "Skip", new Vector2(.955f, .075f), "跳过", out _);
                skipButton.onClick.AddListener(RequestSkip);
            }
            CreateBattleNumberAtlas();
            battleRootHome = root.transform.localPosition;
            root.SetActive(false);
        }

        private void CreateBattleNumberAtlas()
        {
            Texture2D texture = Resources.Load<Texture2D>("ProjectXBattle/Hud/ui_pk_num");
            if (texture == null || texture.width != 348 || texture.height != 30)
                throw new InvalidOperationException("Cocos battle-number atlas must be the current 348x30 ui_pk_num.png.");
            battleNumberAtlasSprites = new Sprite[12];
            for (int index = 0; index < battleNumberAtlasSprites.Length; index++)
            {
                battleNumberAtlasSprites[index] = Sprite.Create(texture, new Rect(index * 29f, 0f, 29f, 30f),
                    new Vector2(.5f, .5f), 100f);
                battleNumberAtlasSprites[index].name = $"ui_pk_num_{index}";
            }
        }

        private void ConfigureImportedFightLayer()
        {
            string[] hidden =
            {
                "Layer/FightUI/bg", "Layer/FightUI/Head", "Layer/FightUI/Round",
                "Layer/FightUI/CountDown", "Layer/FightUI/Item", "Layer/FightUI/Panel_Shortcut",
                "Layer/FightUI/btn_Locker", "Layer/FightUI/Pupop_zhenfa", "Layer/FightUI/Pupop_Skill",
                "Layer/FightUI/ListBg", "Layer/FightUI/Buttons/btn_Flee",
                "Layer/FightUI/Buttons/btn_Cancel", "Layer/FightUI/Buttons/btn_Auto",
                "Layer/FightUI/Buttons/btn_Skill_1", "Layer/FightUI/Buttons/btn_Skill_2",
                "Layer/FightUI/Buttons/btn_Skill_3", "Layer/FightUI/Buttons/btn_Skill_4",
                "Layer/FightUI/Buttons/btn_Skill_5"
            };
            foreach (string path in hidden)
            {
                GameObject node = importedView.Binding.Find(path);
                if (node != null) node.SetActive(false);
            }
            string[] visible =
            {
                "Layer/FightUI/Scene", "Layer/FightUI/Image_huihe_bg_0",
                "Layer/FightUI/Image_huihe_bg", "Layer/FightUI/Round_Special",
                "Layer/FightUI/btn_Formation_Enemy", "Layer/FightUI/btn_Formation_Oneself",
                "Layer/FightUI/Position",
                "Layer/FightUI/Buttons", "Layer/FightUI/Buttons/btn_Speed", "Layer/FightUI/Buttons/btn_jump"
            };
            foreach (string path in visible)
            {
                GameObject node = importedView.Binding.Find(path);
                if (node != null) node.SetActive(true);
            }
            for (int index = 1; index <= 18; index++)
            {
                GameObject marker = importedView.Binding.Find($"Layer/FightUI/Position/Image_{index}");
                if (marker == null) continue;
                marker.SetActive(false);
                marker.transform.SetAsFirstSibling();
            }
        }

        private void CreateRoundAtlas(Transform parent)
        {
            Texture2D texture = Resources.Load<Texture2D>("ProjectXBattle/Hud/num_lan");
            if (texture == null || texture.width != 720 || texture.height != 75)
                throw new InvalidOperationException("Cocos round atlas must be the current 720x75 num_lan.png.");
            roundAtlasSprites = new Sprite[12];
            for (int index = 0; index < roundAtlasSprites.Length; index++)
            {
                roundAtlasSprites[index] = Sprite.Create(texture, new Rect(index * 60f, 0f, 60f, 75f),
                    new Vector2(.5f, .5f), 100f);
                roundAtlasSprites[index].name = $"num_lan_{index}";
            }
            roundAtlasGlyphs = new Image[5];
            for (int index = 0; index < roundAtlasGlyphs.Length; index++)
            {
                var glyph = new GameObject($"RuntimeGlyph_{index}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform rect = glyph.GetComponent<RectTransform>();
                rect.SetParent(parent, false);
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.sizeDelta = new Vector2(60f, 75f);
                rect.anchoredPosition = new Vector2(-120f + index * 60f, 0f);
                Image image = glyph.GetComponent<Image>();
                image.preserveAspect = true;
                image.raycastTarget = false;
                roundAtlasGlyphs[index] = image;
            }
            GameObject legacyRoundWord = importedView.Binding.Find("Layer/FightUI/Round_Special/Num/Image_huihe");
            if (legacyRoundWord != null) legacyRoundWord.SetActive(false);
        }

        private void UpdateRoundDisplay(int round)
        {
            string value = $"{Mathf.Max(0, round):00}/{Mathf.Max(1, store.MaxTurns):00}";
            roundLabel.text = value;
            if (roundAtlasGlyphs.Length != value.Length) return;
            for (int index = 0; index < value.Length; index++)
            {
                char character = value[index];
                int glyph = character == '.' ? 0 : character == '/' ? 1
                    : character >= '0' && character <= '9' ? character - '0' + 2 : -1;
                roundAtlasGlyphs[index].gameObject.SetActive(glyph >= 0);
                if (glyph >= 0) roundAtlasGlyphs[index].sprite = roundAtlasSprites[glyph];
            }
        }

        private void ConfigureFormationHud()
        {
            if (importedView == null) return;
            HideImportedButtonBackground("Layer/FightUI/btn_Formation_Enemy");
            HideImportedButtonBackground("Layer/FightUI/btn_Formation_Oneself");
            SetFormationIcon("Layer/FightUI/btn_Formation_Enemy/Image", store.Group2FormationId);
            SetFormationIcon("Layer/FightUI/btn_Formation_Oneself/Image", store.Group1FormationId);
        }

        private void HideImportedButtonBackground(string path)
        {
            GameObject node = importedView.Binding.Find(path);
            Image background = node != null ? node.GetComponent<Image>() : null;
            if (background != null)
            {
                Color color = background.color;
                background.color = new Color(color.r, color.g, color.b, 0f);
            }
        }

        private void SetFormationIcon(string path, ushort formationId)
        {
            GameObject node = importedView.Binding.Find(path);
            Image image = node != null ? node.GetComponent<Image>() : null;
            Sprite sprite = Resources.Load<Sprite>($"HeroUI/formation_{formationId}");
            if (image == null || sprite == null)
                throw new InvalidOperationException($"Cocos formation icon is missing: formation={formationId}, path={path}.");
            image.sprite = sprite;
            image.preserveAspect = true;
            image.color = Color.white;
        }

        private void ConfigureFormationMarkers()
        {
            if (importedView == null) return;
            var occupied = new HashSet<int>(units.Keys.Select(value => (int)value));
            for (int original = 1; original <= 18; original++)
            {
                int displayed = ResolveDisplayedPosition(original);
                GameObject marker = importedView.Binding.Find($"Layer/FightUI/Position/Image_{displayed}");
                if (marker == null) continue;
                bool hasUnit = occupied.Contains(original);
                // This presenter uses the current Cocos flipped layout: source
                // positions 1..9 render at imported markers 10..18. Cocos
                // LBattleLogic also swaps formation ownership when deciding
                // which empty slots are valid. The unflipped association here
                // exposed phantom empty rings on both sides.
                ushort formationId = original <= 9 ? store.Group1FormationId : store.Group2FormationId;
                int localPosition = original <= 9 ? original : original - 9;
                bool validEmpty = presentationCatalog.TryGetFormation(formationId, out BattleFormationDefinition formation)
                    && formation.Positions.Contains(localPosition);
                marker.SetActive(hasUnit || validEmpty);
                Image image = marker.GetComponent<Image>();
                if (image != null)
                {
                    Color color = image.color;
                    image.color = new Color(color.r, color.g, color.b, hasUnit ? 1f : 100f / 255f);
                }
            }
        }

        private T RequireImportedComponent<T>(string path) where T : Component
        {
            GameObject node = importedView.Binding.Find(path);
            T value = node != null ? node.GetComponent<T>() : null;
            if (value == null) throw new InvalidOperationException($"Imported FightLayer component is missing: {path}/{typeof(T).Name}.");
            return value;
        }

        private void RefreshImportedSpeedVisual()
        {
            if (importedView == null) return;
            GameObject speedNode = importedView.Binding.Find("Layer/FightUI/Buttons/btn_Speed/X1");
            Text value = speedNode != null ? speedNode.GetComponent<Text>() : null;
            if (value != null) value.text = $"X{SpeedDisplayMultiplier}";
            foreach (string legacy in new[] { "X2", "X3" })
            {
                GameObject node = importedView.Binding.Find("Layer/FightUI/Buttons/btn_Speed/" + legacy);
                if (node != null) node.SetActive(false);
            }
        }

        public bool IsVisible => root.activeSelf;
        public Button SpeedInteractionButton => speedButton;
        public Button SkipInteractionButton => skipButton;
        public bool AutoControlVisible => importedView?.Binding.Find("Layer/FightUI/Buttons/btn_Auto")?.activeInHierarchy == true;
        public int ActiveFormationMarkerCount
        {
            get
            {
                if (importedView == null) return 0;
                int count = 0;
                for (int index = 1; index <= 18; index++)
                    if (importedView.Binding.Find($"Layer/FightUI/Position/Image_{index}")?.activeInHierarchy == true)
                        count++;
                return count;
            }
        }

        public void Show()
        {
            ClearUnits();
            battleRootHome = root.transform.localPosition;
            if (loadSpeedStep != null)
                speedStep = Mathf.Clamp(loadSpeedStep(), 0, CocosSpeedLabels.Length - 1);
            ApplySpeedStep(false);
            SkipRequested = false;
            // Cocos keeps btn_jump visible whenever the account-level feature is
            // unlocked; the packet flag only controls whether this battle may be
            // skipped after the click. The World fixture is level 99, so hiding
            // the button when CanSkip is false is not source-equivalent.
            skipButton.gameObject.SetActive(true);
            Debug.Log($"[ProjectX][World] Battle controls: packetCanSkip={store.CanSkip}, skipVisible={skipButton.gameObject.activeSelf}, maxTurns={store.MaxTurns}.");
            UpdateRoundDisplay(Mathf.Max(1, store.CurrentTurn));
            foreach (WorldBattleUnitRecord unit in store.Units.Take(18))
            {
                UnitView view = CreateUnit(unitLayer, unit, ResolveDisplayedPosition(unit), unit.IsEnemy);
                units[unit.Position] = view;
            }
            ConfigureFormationHud();
            ConfigureFormationMarkers();
            // FightLayer renders positions 10..18 on the left and the local
            // positions 1..9 on the right, matching BattleUI.lua.
            if (friendlyLabel != null) friendlyLabel.text = ResolveSideLabel(true, store.EnemyName);
            if (enemyLabel != null) enemyLabel.text = ResolveSideLabel(false, store.FriendlyName);
            foreach (UnitView unit in units.Values.OrderByDescending(value => value.Root.anchoredPosition.y))
                unit.Root.SetAsLastSibling();
            roundLabel.transform.SetAsLastSibling();
            speedButton.transform.SetAsLastSibling();
            skipButton.transform.SetAsLastSibling();
            startShade.transform.SetAsLastSibling();
            startEffect.transform.SetAsLastSibling();
            root.SetActive(true);
            root.transform.SetAsLastSibling();
            Canvas.ForceUpdateCanvases();
            foreach (UnitView unit in units.Values) unit.Home = unit.Root.localPosition;
            PlayStartEffect();
        }

        private void RequestSkip()
        {
            if (store.CanSkip)
            {
                SkipRequested = true;
                return;
            }
            showControlMessage?.Invoke("精英、BOSS关无法跳过！");
        }

        public void BeginAction(WorldBattleActionRecord action, bool preserveExistingDamage = false)
        {
            // Cocos removes zhandoukaishi before the first action begins.  The
            // Imod player otherwise retains its last non-looping frame, leaving
            // a translucent start banner over every later skill and hit.
            startShade.gameObject.SetActive(false);
            startEffect.gameObject.SetActive(false);
            ClearActionEffects();
            EnsureSummonedUnits(action);
            activeSource = ResolveSource(action);
            activeTarget = ResolveTarget(action, activeSource);
            activeTargets.Clear();
            if (action != null)
                foreach (WorldBattleTargetRecord target in action.Targets)
                    if (units.TryGetValue(target.Position, out UnitView view) && !activeTargets.Contains(view))
                        activeTargets.Add(view);
            if (activeTargets.Count == 0 && activeTarget != null) activeTargets.Add(activeTarget);
            activeProtectors.Clear();
            if (action != null)
            {
                foreach (WorldBattleTargetRecord targetRecord in action.Targets)
                {
                    if (targetRecord.ProtectorPosition == 0
                        || !units.TryGetValue(targetRecord.ProtectorPosition, out UnitView protector)
                        || !units.TryGetValue(targetRecord.Position, out UnitView protectedTarget)
                        || activeProtectors.Contains(protector)) continue;
                    Vector3 direction = (protector.Home - protectedTarget.Home).normalized;
                    protector.Root.localPosition = protectedTarget.Home + direction * 45f;
                    activeProtectors.Add(protector);
                }
            }
            activeActionType = action?.FirstActionType ?? 0;
            activeAction = action;
            impactApplied = false;
            moveActive = false;
            activeClips.Clear();
            activeShakes.Clear();
            if (action != null)
                UpdateRoundDisplay(action.Round);
            if (activeSource == null) return;
            // Cocos consumes one or more BAT_PASSIVE records immediately, waits
            // for their 0.5 second feedback window, then starts the following
            // visible action without clearing the passive floating number.  The
            // number therefore overlaps the next attack's skill-name/pre-roll.
            if (!preserveExistingDamage)
            {
                HideDamage(activeSource);
                foreach (UnitView target in activeTargets) HideDamage(target);
            }
            ShowSkillName(activeSource, action);
            if (action != null && !string.IsNullOrWhiteSpace(action.Message))
                ShowDamage(activeSource, action.Message, new Color(.98f, .88f, .42f, 1f));
            else if (action?.FirstActionType == 5)
                ShowDamage(activeSource, action.FirstTargetHit ? "逃跑成功" : "逃跑失败",
                    action.FirstTargetHit ? new Color(.35f, 1f, .55f, 1f) : new Color(1f, .42f, .32f, 1f));
            BuildActionTimeline(action);
        }

        private void EnsureSummonedUnits(WorldBattleActionRecord action)
        {
            if (action == null || action.SummonedUnits.Count == 0) return;
            foreach (WorldBattleUnitRecord unit in action.SummonedUnits)
            {
                if (units.TryGetValue(unit.Position, out UnitView old) && old?.Root != null)
                    UnityEngine.Object.Destroy(old.Root.gameObject);
                UnitView view = CreateUnit(unitLayer, unit, ResolveDisplayedPosition(unit), unit.IsEnemy);
                units[unit.Position] = view;
                view.Home = view.Root.localPosition;
                PlayUnitAnimation(view, "zd", true);
            }
            ConfigureFormationMarkers();
        }

        public void SetActionProgress(float progress)
        {
            if (activeSource == null) return;
            float clamped = Mathf.Clamp01(progress);
            float elapsed = clamped * actionDurationSeconds;
            foreach (ScheduledClip scheduled in activeClips)
            {
                if (scheduled.Triggered || elapsed < scheduled.StartSeconds) continue;
                scheduled.Triggered = true;
                PlayConfiguredClip(scheduled);
            }
            ApplyCameraShake(elapsed);
            if (!impactApplied && clamped >= impactProgress) ApplyImpact();
            AnimateSkillName(activeSource, clamped);
            foreach (UnitView target in activeTargets) AnimateDamage(target, elapsed);
            if (activeSource != activeTarget) AnimateDamage(activeSource, elapsed);
            if (moveActive)
            {
                float phase = Mathf.InverseLerp(moveStartProgress, moveEndProgress, clamped);
                // Cocos uses cc.MoveTo here: the displacement is linear for the
                // exact configured move time, without easing.
                activeSource.Root.localPosition = Vector3.Lerp(moveStart, moveEnd, phase);
                if (clamped >= moveEndProgress) moveActive = false;
            }
            if (activeTarget != null && activeTarget != activeSource)
            {
                foreach (UnitView target in activeTargets)
                    SetUnitColor(target, clamped >= Mathf.Max(0f, impactProgress - .12f) && clamped <= Mathf.Min(1f, impactProgress + .20f)
                        ? activeActionType == 2
                            ? new Color(.42f, 1f, .48f, 1f)
                            : activeActionType == 3
                                ? new Color(.45f, .72f, 1f, 1f)
                                : new Color(1f, .42f, .35f, 1f)
                        : Color.white);
            }
        }

        public void EndAction(bool preserveDamage = false)
        {
            if (!impactApplied) ApplyImpact();
            if (activeSource != null)
            {
                activeSource.Root.localPosition = activeSource.Home;
                if (!preserveDamage) HideDamage(activeSource);
                HideSkillName(activeSource);
                if (activeAction == null || !activeAction.SourceDead) PlayUnitAnimation(activeSource, "zd", true);
            }
            foreach (UnitView target in activeTargets)
            {
                SetUnitColor(target, Color.white);
                if (!preserveDamage) HideDamage(target);
                WorldBattleTargetRecord record = activeAction?.Targets.FirstOrDefault(value => value.Position == target.Data.Position);
                if (record == null || !record.Dead) PlayUnitAnimation(target, "zd", true);
            }
            foreach (UnitView protector in activeProtectors)
            {
                protector.Root.localPosition = protector.Home;
                if (!preserveDamage) HideDamage(protector);
                PlayUnitAnimation(protector, "zd", true);
            }
            activeSource = activeTarget = null;
            activeActionType = 0;
            activeAction = null;
            activeTargets.Clear();
            activeProtectors.Clear();
            activeClips.Clear();
            activeShakes.Clear();
            ClearActionEffects();
            impactApplied = false;
            moveActive = false;
            root.transform.localPosition = battleRootHome;
            IsCameraShaking = false;
        }

        public void ShowOutcome()
        {
            foreach (UnitView unit in units.Values.Where(value => value.Data.IsEnemy == store.Won))
                PlayUnitAnimation(unit, "sw", false);
        }

        public void Hide()
        {
            startShade.gameObject.SetActive(false);
            startEffect.gameObject.SetActive(false);
            battleAudio.Stop();
            root.SetActive(false);
        }

        public void Dispose()
        {
            foreach (Sprite sprite in roundAtlasSprites)
                if (sprite != null) UnityEngine.Object.Destroy(sprite);
            if (root == null) return;
            if (importedView != null) root.SetActive(false);
            else UnityEngine.Object.Destroy(root);
        }

        private void PlayStartEffect()
        {
            startShade.color = new Color(0f, 0f, 0f, CocosStartShadeOpacity);
            startShade.gameObject.SetActive(true);
            startEffect.gameObject.SetActive(false);
            if (!startEffect.LoadLegacy("res2/fx/zhandoukaishi")) return;
            startEffect.SetSpeedScale(1f / Mathf.Max(1f, PlaybackSpeed));
            startEffect.gameObject.SetActive(true);
            try { startEffect.Play(0, false); }
            catch { startEffect.gameObject.SetActive(false); }
        }

        public void SetBattleStartElapsed(float elapsedSeconds)
        {
            // LBattleLogic:PlayBattleStartAnimate keeps a 150-alpha black
            // LayerColor for 0.9 s and fades it over the following 0.2 s.
            float fade = Mathf.InverseLerp(.9f, 1.1f, Mathf.Max(0f, elapsedSeconds));
            startShade.color = new Color(0f, 0f, 0f, CocosStartShadeOpacity * (1f - fade));
            if (elapsedSeconds >= 1.1f)
            {
                startShade.gameObject.SetActive(false);
                startEffect.gameObject.SetActive(false);
            }
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

        private string ResolveSideLabel(bool enemy, string configured)
        {
            if (!string.IsNullOrWhiteSpace(configured)) return configured.Replace('·', ' ');
            UnitView first = units.Values.FirstOrDefault(value => value.Data.IsEnemy == enemy);
            return (first?.Data.Name ?? string.Empty).Replace('·', ' ');
        }

        private UnitView CreateUnit(Transform parent, WorldBattleUnitRecord unit, int displayedPosition, bool enemy)
        {
            GameObject value = new GameObject($"Unit_{unit.Position}", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            RectTransform importedMarker = importedView?.Binding.Find(
                $"Layer/FightUI/Position/Image_{displayedPosition}")?.GetComponent<RectTransform>();
            if (importedMarker != null && importedMarker.parent == parent)
            {
                rect.anchorMin = importedMarker.anchorMin;
                rect.anchorMax = importedMarker.anchorMax;
                rect.pivot = importedMarker.pivot;
                rect.anchoredPosition = importedMarker.anchoredPosition;
            }
            else
            {
                rect.anchorMin = rect.anchorMax = CocosUnitAnchors[displayedPosition];
            }
            rect.sizeDelta = new Vector2(160f, 200f);
            int picture = checked((int)Math.Min(unit.Picture, (uint)int.MaxValue));
            if (unit.Type == 2 && HeroCatalog.TryGet(picture, out HeroDefinition hero)) picture = hero.Picture;
            var view = new UnitView
            {
                Data = unit,
                Root = rect,
                CurrentHp = unit.CurrentHp,
                HitDefinition = presentationCatalog.ResolveUnitHit(unit.Type, checked((uint)Math.Max(0, picture)))
            };
            string qualityEffectResource = ResolvePetQualityEffectResource(unit.Type, unit.Quality);
            if (!string.IsNullOrEmpty(qualityEffectResource))
            {
                GameObject qualityEffectObject = new GameObject("PetQualityEffect", typeof(RectTransform));
                RectTransform qualityEffectRect = qualityEffectObject.GetComponent<RectTransform>();
                qualityEffectRect.SetParent(rect, false);
                qualityEffectRect.anchorMin = qualityEffectRect.anchorMax = new Vector2(.5f, .5f);
                qualityEffectRect.sizeDelta = new Vector2(220f, 160f);
                view.QualityEffect = qualityEffectObject.AddComponent<ImodAnimationPlayer>();
                view.QualityEffect.SetPlayOnEnable(false);
                if (view.QualityEffect.LoadLegacy(qualityEffectResource))
                {
                    view.QualityEffect.SetSpeedScale(1f / Mathf.Max(1f, PlaybackSpeed));
                    view.QualityEffect.Play(0, true);
                }
                else
                {
                    UnityEngine.Object.Destroy(qualityEffectObject);
                    view.QualityEffect = null;
                }
            }
            if (unit.Type != 1 && picture > 0)
            {
                view.AnimationBase = $"Monster/btm{picture}_";
                view.Model = value.AddComponent<ImodAnimationPlayer>();
                view.Model.SetPlayOnEnable(false);
                view.Model.SetFlippedX(!enemy);
                view.Model.SetVisualScale(unit.ScaleRatio);
                if (!PlayUnitAnimation(view, "zd", true)) view.Model = null;
            }
            if (view.Model == null)
            {
                view.Portrait = value.AddComponent<Image>();
                view.Portrait.sprite = resources.LoadHeroPortrait(picture);
                view.Portrait.preserveAspect = true;
                view.Portrait.raycastTarget = false;
            }
            view.HealthFill = CreateHealthBar(rect, unit, enemy, view.HitDefinition,
                out RectTransform healthRoot, out RectTransform numberRoot);
            view.HealthRoot = healthRoot;
            view.NumberRoot = numberRoot;
            RefreshBuffs(view, unit.BuffIds);
            // BattleUnitNode:InitNameLabel attaches the label to m_pNode at a
            // fixed local Y=-20.  A normalized bottom anchor on this 200px
            // Unity unit rect placed every name about 64px too low, which was
            // most visible when the sw animation fell across the name.
            view.NameLabel = CreateText(rect, "NameLabel", new Vector2(.5f, .5f), new Vector2(200f, 30f), 20,
                enemy ? new Color(.02f, .34f, .62f, 1f) : new Color(.48f, .05f, .42f, 1f), TextAnchor.MiddleCenter);
            view.NameLabel.rectTransform.anchoredPosition = new Vector2(0f, -20f);
            view.NameLabel.text = unit.Name ?? string.Empty;
            view.StatusLabel = CreateText(rect, "BattleStatus", new Vector2(.5f, .7f), new Vector2(220f, 50f), 28,
                new Color(1f, .22f, .12f, 1f), TextAnchor.MiddleCenter);
            view.StatusLabel.fontStyle = FontStyle.Bold;
            view.StatusLabel.gameObject.SetActive(false);
            view.SkillLabel = CreateText(rect, "SkillName", new Vector2(.5f, 1.12f), new Vector2(240f, 42f), 24,
                new Color(1f, .88f, .05f, 1f), TextAnchor.MiddleCenter);
            view.SkillLabel.fontStyle = FontStyle.Bold;
            Outline outline = view.SkillLabel.gameObject.AddComponent<Outline>();
            outline.effectColor = new Color(.30f, .12f, 0f, 1f);
            outline.effectDistance = new Vector2(2f, -2f);
            view.SkillLabel.gameObject.SetActive(false);
            GameObject markerObject = new GameObject("CombatMarker", typeof(RectTransform), typeof(Image));
            RectTransform markerRect = markerObject.GetComponent<RectTransform>();
            markerRect.SetParent(rect, false);
            markerRect.anchorMin = markerRect.anchorMax = new Vector2(.5f, .72f);
            markerRect.sizeDelta = new Vector2(118f, 58f);
            view.CombatMarker = markerObject.GetComponent<Image>();
            view.CombatMarker.preserveAspect = true;
            view.CombatMarker.raycastTarget = false;
            view.CombatMarker.gameObject.SetActive(false);
            return view;
        }

        private static Image CreateHealthBar(Transform parent, WorldBattleUnitRecord unit, bool enemy,
            BattleUnitHitDefinition hitDefinition, out RectTransform healthRoot, out RectTransform numberRoot)
        {
            CocosUiView healthView = UiPrefabLoader.Load("BattleHpNode", parent);
            RectTransform rootRect = healthView.GameObject.GetComponent<RectTransform>();
            healthRoot = rootRect;
            rootRect.anchorMin = rootRect.anchorMax = new Vector2(.5f, .5f);
            rootRect.anchoredPosition = (hitDefinition?.HpBarPosition ?? new Vector2(0f, 100f))
                * unit.ScaleRatio;
            GameObject node = healthView.Binding.Find("Node");
            if (node == null) throw new InvalidOperationException("BattleHpNode is missing Node.");
            foreach (Transform child in node.transform)
                child.gameObject.SetActive(child.name == "bg" || child.name == (enemy ? "HPSp" : "HPSp_0"));
            GameObject qualityBackground = healthView.Binding.Find("Node/Quality_bg");
            GameObject qualityObject = healthView.Binding.Find("Node/Quality_bg/Quality");
            bool showQuality = unit.Type == 2 && unit.Quality > 0;
            if (qualityBackground != null) qualityBackground.SetActive(showQuality);
            if (qualityObject != null)
            {
                qualityObject.SetActive(showQuality);
                Image qualityImage = qualityObject.GetComponent<Image>();
                if (showQuality && qualityImage != null)
                    qualityImage.sprite = Resources.Load<Sprite>(ResolveQualityScoreResource(unit.Quality));
            }
            GameObject background = healthView.Binding.Find("Node/bg");
            GameObject fillObject = healthView.Binding.Find(enemy ? "Node/HPSp" : "Node/HPSp_0");
            if (background == null || fillObject == null)
                throw new InvalidOperationException("BattleHpNode is missing the Cocos health sprites.");
            background.SetActive(true);
            fillObject.SetActive(true);
            Image fill = fillObject.GetComponent<Image>();
            if (fill == null) throw new InvalidOperationException("BattleHpNode health sprite has no Image component.");
            fill.color = Color.white;
            fill.type = Image.Type.Filled;
            fill.fillMethod = Image.FillMethod.Horizontal;
            fill.fillOrigin = (int)Image.OriginHorizontal.Left;
            fill.fillAmount = unit.MaxHp == 0 ? 0f : Mathf.Clamp01((float)((double)unit.CurrentHp / unit.MaxHp));
            fill.raycastTarget = false;
            GameObject damageObject = healthView.Binding.Find("Node/Minus");
            GameObject recoveryObject = healthView.Binding.Find("Node/Plus");
            if (damageObject == null || recoveryObject == null)
                throw new InvalidOperationException("BattleHpNode is missing the Cocos Minus/Plus number templates.");
            damageObject.SetActive(false);
            recoveryObject.SetActive(false);
            GameObject numberObject = new GameObject("CocosBattleNumber", typeof(RectTransform));
            numberRoot = numberObject.GetComponent<RectTransform>();
            numberRoot.SetParent(node.transform, false);
            numberRoot.anchorMin = numberRoot.anchorMax = new Vector2(.5f, .5f);
            numberRoot.anchoredPosition = new Vector2(0f, 30f);
            numberRoot.sizeDelta = new Vector2(348f, 30f);
            numberRoot.localScale = Vector3.zero;
            numberObject.SetActive(false);
            healthView.GameObject.SetActive(true);
            return fill;
        }

        private static string ResolveQualityScoreResource(byte quality)
        {
            // AppHeroDef.Pet.QualityScoreRes: 1..4=A, 5=S, 6=SS,
            // 7=SSS, 8+=SSSS. BattleHeadNode shows it only for Pet/type 2.
            if (quality <= 4) return "HeroUI/quality_score_A";
            if (quality == 5) return "HeroUI/quality_score_S";
            if (quality == 6) return "HeroUI/quality_score_SS";
            if (quality == 7) return "HeroUI/quality_score_SSS";
            return "HeroUI/quality_score_SSSS";
        }

        private static string ResolvePetQualityEffectResource(byte type, byte quality)
        {
            // BattleUnitNode:ShowQuality only attaches the looping background
            // Imod to Pet/type 2 units.
            if (type != 2 || quality <= 1) return string.Empty;
            if (quality == 2) return "res2/animation/battle/quality2";
            if (quality < 7) return "res2/animation/battle/quality3";
            if (quality == 7) return "res2/animation/battle/quality7";
            return "res2/animation/battle/quality8";
        }

        private void BuildActionTimeline(WorldBattleActionRecord action)
        {
            BattleActionDefinition definition = presentationCatalog.ResolveAction(action?.SkillId ?? 0, action?.FirstActionType ?? 0);
            if (definition == null || definition.Clips.Count == 0)
            {
                actionDurationSeconds = 1f;
                impactProgress = .5f;
                recommendedSkillCaptureProgress = .5f;
                PlayUnitAnimation(activeSource, action != null && action.SkillId > 0 ? "sf1" : "gj", false);
                LastActionTrace = $"fallback skill={action?.SkillId ?? 0} type={action?.FirstActionType ?? 0}";
                return;
            }

            float cursor = 0f;
            float previousDuration = .5f;
            float timelineEnd = 0f;
            bool first = true;
            float firstHurtStart = -1f;
            float firstSkillStart = -1f;
            foreach (BattleActionClip clip in definition.Clips)
            {
                if (!first) cursor += clip.DelaySeconds * previousDuration;
                float duration = EstimateClipDuration(clip);
                activeClips.Add(new ScheduledClip
                {
                    Clip = clip,
                    StartSeconds = cursor,
                    DurationSeconds = duration
                });
                if (firstHurtStart < 0f && clip.Type == BattleClipType.HurtAnimation) firstHurtStart = cursor;
                if (firstSkillStart < 0f && clip.Type == BattleClipType.SkillAnimation) firstSkillStart = cursor;
                timelineEnd = Mathf.Max(timelineEnd, cursor + duration);
                previousDuration = duration;
                first = false;
            }
            // LBattleLogic.DoNextAction resets all unit positions after the last
            // clip duration plus 0.1 seconds.
            actionDurationSeconds = Mathf.Max(.35f, timelineEnd + .1f);
            impactProgress = firstHurtStart < 0f ? .5f : Mathf.Clamp01(firstHurtStart / actionDurationSeconds);
            // Capture just after the first configured SkillAni has started. The
            // frozen Cocos skill state is the first visible Imod frame, before
            // the hit atlas expands into its later full-radius water frames.
            recommendedSkillCaptureProgress = firstSkillStart < 0f
                ? impactProgress
                : Mathf.Clamp01((firstSkillStart + .02f) / actionDurationSeconds);
            LastActionTrace = $"config={definition.Id} skill={action?.SkillId ?? 0} type={action?.FirstActionType ?? 0} "
                + $"clips={string.Join(",", definition.Clips.Select(value => $"{(uint)value.Type}:{value.DefinitionId}@{value.DelaySeconds:0.##}"))} "
                + $"duration={actionDurationSeconds:0.###} impact={impactProgress:0.###}";
            SetActionProgress(0f);
        }

        private float EstimateClipDuration(BattleActionClip clip)
        {
            if (clip.Type == BattleClipType.ModelAnimation
                && presentationCatalog.TryGetModelAction(clip.DefinitionId, out BattleModelActionDefinition model))
            {
                if (model.MoveSeconds > 0f) return model.MoveSeconds;
                float duration = ResolveLegacyAnimationDuration(
                    activeSource?.AnimationBase + model.ActionSuffix);
                return duration > 0f ? duration : .5f;
            }
            if (clip.Type == BattleClipType.SkillAnimation
                && presentationCatalog.TryGetSkillEffect(clip.DefinitionId, out BattleSkillEffectDefinition effect))
            {
                if (effect.MoveSeconds > 0f) return effect.MoveSeconds;
                float duration = ResolveLegacyAnimationDuration(ResolveSkillEffectPath(effect));
                return duration > 0f ? duration : .5f;
            }
            return .5f;
        }

        private void PlayConfiguredClip(ScheduledClip scheduled)
        {
            BattleActionClip clip = scheduled.Clip;
            if (clip.Type == BattleClipType.ModelAnimation
                && presentationCatalog.TryGetModelAction(clip.DefinitionId, out BattleModelActionDefinition model))
            {
                if (!string.IsNullOrWhiteSpace(model.ActionSuffix)) PlayUnitAnimation(activeSource, model.ActionSuffix, false);
                PlayBattleSound(model.SoundFile);
                ScheduleCameraShake(model.ShakeId, scheduled);
                if (model.MoveSeconds > 0f)
                {
                    moveStart = ResolveMovePoint(model.MoveStartType);
                    moveEnd = ResolveMovePoint(model.MoveEndType);
                    moveStartProgress = scheduled.StartSeconds / actionDurationSeconds;
                    moveEndProgress = Mathf.Clamp01((scheduled.StartSeconds + model.MoveSeconds) / actionDurationSeconds);
                    activeSource.Root.localPosition = moveStart;
                    moveActive = true;
                }
                else activeSource.Root.localPosition = ResolveMovePoint(model.MoveEndType);
                return;
            }
            if (clip.Type == BattleClipType.SkillAnimation
                && presentationCatalog.TryGetSkillEffect(clip.DefinitionId, out BattleSkillEffectDefinition effect))
            {
                PlaySkillEffect(effect);
                PlayBattleSound(effect.SoundFile);
                ScheduleCameraShake(effect.ShakeId, scheduled);
                return;
            }
            if (clip.Type == BattleClipType.HurtAnimation
                && presentationCatalog.TryGetHurtAction(clip.DefinitionId, out BattleHurtDefinition hurt))
            {
                if (!impactApplied) ApplyImpact();
                foreach (UnitView target in activeTargets)
                {
                    WorldBattleTargetRecord record = activeAction?.Targets.FirstOrDefault(value => value.Position == target.Data.Position);
                    if (record != null && record.Hit && !record.Dead && !string.IsNullOrWhiteSpace(hurt.ActionSuffix))
                        PlayUnitAnimation(target, hurt.ActionSuffix, false);
                }
            }
        }

        private void ScheduleCameraShake(uint shakeId, ScheduledClip clip)
        {
            if (shakeId == 0 || !presentationCatalog.TryGetShake(shakeId, out BattleShakeDefinition shake)) return;
            activeShakes.Add(new ScheduledShake
            {
                StartSeconds = clip.StartSeconds + clip.DurationSeconds * shake.DelayRatio,
                DurationSeconds = Mathf.Max(.01f, shake.DurationSeconds),
                Strength = shake.Strength
            });
            Debug.Log($"WORLD_BATTLE_SHAKE id={shake.Id} start={clip.StartSeconds + clip.DurationSeconds * shake.DelayRatio:0.###} duration={shake.DurationSeconds:0.###} strength={shake.Strength:0.###}");
        }

        private void PlayBattleSound(string soundFile)
        {
            if (string.IsNullOrWhiteSpace(soundFile)) return;
            AudioClip clip = Resources.Load<AudioClip>("ProjectXAudio/battle/" + soundFile);
            if (clip == null)
            {
                Debug.LogWarning($"WORLD_BATTLE_AUDIO_MISSING sound={soundFile}");
                return;
            }
            battleAudio.PlayOneShot(clip);
            Debug.Log($"WORLD_BATTLE_AUDIO sound={soundFile}");
        }

        private void ApplyCameraShake(float elapsedSeconds)
        {
            Vector2 offset = Vector2.zero;
            bool active = false;
            foreach (ScheduledShake shake in activeShakes)
            {
                float phase = (elapsedSeconds - shake.StartSeconds) / shake.DurationSeconds;
                if (phase < 0f || phase > 1f) continue;
                active = true;
                float falloff = 1f - phase;
                float strength = shake.Strength * falloff;
                offset.x += Mathf.Sin(phase * 47.123f) * strength;
                offset.y += Mathf.Sin(phase * 61.731f + 1.17f) * strength;
            }
            IsCameraShaking = active;
            root.transform.localPosition = battleRootHome + new Vector3(offset.x, offset.y, 0f);
        }

        private void PlaySkillEffect(BattleSkillEffectDefinition effect)
        {
            if (effect == null || string.IsNullOrWhiteSpace(effect.File)) return;
            bool rightSide = ResolveSkillEffectRightSide(effect);
            string path = ResolveSkillEffectPath(effect);
            GameObject value = new GameObject($"SkillEffect_{effect.Id}", typeof(RectTransform));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(500f, 500f);
            UnitView attachedUnit = effect.MoveSeconds <= 0f && effect.MoveEndType == 1
                ? activeSource
                : effect.MoveSeconds <= 0f && effect.MoveEndType == 10
                    ? activeTarget
                    : null;
            if (attachedUnit?.Root != null)
            {
                // Cocos parents stationary ActSrcPos/TgtSrcPos effects to the
                // corresponding unit and positions them at that unit's hit point.
                rect.SetParent(attachedUnit.Root, false);
                rect.localPosition = ResolveHitPoint(attachedUnit, effect.HitPoint);
            }
            else
            {
                rect.SetParent(battleLayer, false);
                Vector3 worldPoint = unitLayer.TransformPoint(ResolveMovePoint(effect.MoveEndType));
                rect.localPosition = battleLayer.InverseTransformPoint(worldPoint);
            }
            rect.localScale = Vector3.one * Mathf.Max(.01f, effect.Scale);
            ImodAnimationPlayer player = value.AddComponent<ImodAnimationPlayer>();
            if (!player.LoadLegacy(path))
            {
                UnityEngine.Object.Destroy(value);
                return;
            }
            player.SetFlippedX(effect.ResourceType == 2 && rightSide);
            player.SetSpeedScale(1f / Mathf.Max(1f, PlaybackSpeed));
            player.Play(0, false);
            value.transform.SetAsLastSibling();
            activeEffects.Add(value);
        }

        private bool ResolveSkillEffectRightSide(BattleSkillEffectDefinition effect)
        {
            UnitView orientationUnit = effect.MoveEndType == 1 || effect.MoveEndType == 7 || effect.MoveEndType == 8
                ? activeSource
                : activeTarget;
            return IsInRightSide(orientationUnit?.Data.Position ?? activeSource?.Data.Position ?? 1);
        }

        private string ResolveSkillEffectPath(BattleSkillEffectDefinition effect)
        {
            if (effect == null || string.IsNullOrWhiteSpace(effect.File)) return string.Empty;
            string path = "Skill/" + effect.File;
            if (effect.ResourceType == 3) path += ResolveSkillEffectRightSide(effect) ? "_r" : "_l";
            return path;
        }

        private static float ResolveLegacyAnimationDuration(string path)
        {
            if (string.IsNullOrWhiteSpace(path)
                || !ImodAnimationResources.TryLoad(path, out ImodAnimationAssets assets)) return 0f;
            try
            {
                ImodAnimationData data = ImodAnimationData.Parse(assets.Animation.text);
                if (data.actions == null || data.actions.Length == 0
                    || data.actions[0].frames == null) return 0f;
                int ticks = data.actions[0].frames.Sum(frame => Mathf.Max(1, frame.durationTicks));
                return ticks / (float)Mathf.Max(1, data.frameRate);
            }
            catch
            {
                return 0f;
            }
        }

        private Vector3 ResolveMovePoint(uint moveType)
        {
            Vector3 source = activeSource?.Root != null ? activeSource.Root.localPosition : Vector3.zero;
            Vector3 target = activeTarget?.Root != null ? activeTarget.Root.localPosition : source;
            int sourcePosition = activeSource?.Data.Position ?? 1;
            int targetPosition = activeTarget?.Data.Position ?? sourcePosition;
            bool targetRight = IsInRightSide(targetPosition);
            switch (moveType)
            {
                case 1: return source;
                case 2: return target + (targetRight ? new Vector3(-60f, 35f) : new Vector3(60f, -35f));
                case 3: return target + (targetRight ? new Vector3(60f, -35f) : new Vector3(-60f, 35f));
                case 4: return ResolveColumnPoint(targetPosition);
                case 5: return ResolveLinePoint(targetPosition);
                case 10: return target;
                case 6: return ResolveFightCenterPoint();
                case 7: return ResolveSideCenterPoint(sourcePosition, false);
                case 8: return ResolveSideCenterPoint(sourcePosition, true);
                case 9: return IsInRightSide(sourcePosition)
                    ? new Vector3(60f, -35f)
                    : new Vector3(-60f, 35f);
                case 11:
                {
                    Vector3 column = ResolveColumnPoint(targetPosition);
                    return column + (targetRight ? new Vector3(-60f, 60f) : new Vector3(60f, -60f));
                }
                case 12:
                {
                    Vector3 line = ResolveLinePoint(targetPosition);
                    return line + (targetRight ? new Vector3(-60f, 60f) : new Vector3(60f, -60f));
                }
                default: return source;
            }
        }

        private Vector3 ResolveColumnPoint(int originalPosition)
        {
            int marker;
            switch (originalPosition)
            {
                case 1: case 4: case 7: marker = 1; break;
                case 2: case 5: case 8: marker = 2; break;
                case 3: case 6: case 9: marker = 3; break;
                case 10: case 13: case 16: marker = 10; break;
                case 11: case 14: case 17: marker = 11; break;
                default: marker = 12; break;
            }
            return ResolveFormationPoint(marker);
        }

        private Vector3 ResolveLinePoint(int originalPosition)
        {
            int marker = originalPosition <= 3 ? 2
                : originalPosition <= 6 ? 5
                : originalPosition <= 9 ? 8
                : originalPosition <= 12 ? 11
                : originalPosition <= 15 ? 14
                : 17;
            return ResolveFormationPoint(marker);
        }

        private Vector3 ResolveSideCenterPoint(int sourcePosition, bool opposite)
        {
            bool sourceRight = IsInRightSide(sourcePosition);
            int originalMarker = sourceRight ^ opposite ? 14 : 5;
            return ResolveFormationPoint(originalMarker);
        }

        private Vector3 ResolveFormationPoint(int originalPosition)
        {
            int displayed = ResolveDisplayedPosition(originalPosition);
            RectTransform marker = importedView?.Binding.Find(
                $"Layer/FightUI/Position/Image_{displayed}")?.GetComponent<RectTransform>();
            if (marker != null && marker.parent == unitLayer) return marker.localPosition;

            RectTransform layerRect = unitLayer as RectTransform;
            if (layerRect == null || displayed <= 0 || displayed >= CocosUnitAnchors.Length) return Vector3.zero;
            Vector2 anchor = CocosUnitAnchors[displayed];
            Rect bounds = layerRect.rect;
            return new Vector3(
                (anchor.x - layerRect.pivot.x) * bounds.width,
                (anchor.y - layerRect.pivot.y) * bounds.height,
                0f);
        }

        private Vector3 ResolveFightCenterPoint()
        {
            RectTransform fightRect = battleLayer as RectTransform;
            if (fightRect == null) return Vector3.zero;
            return unitLayer.InverseTransformPoint(fightRect.TransformPoint(fightRect.rect.center));
        }

        private static Vector3 ResolveHitPoint(UnitView unit, uint hitPoint)
        {
            Vector2 point = unit?.HitDefinition?.ResolveHitPoint(hitPoint) ?? Vector2.zero;
            float scale = unit?.Data?.ScaleRatio ?? 1f;
            return new Vector3(point.x * scale, point.y * scale, 0f);
        }

        private static bool IsInRightSide(int originalPosition)
        {
            // Current World input has m_bIsFlipPos=true: original slots 1..9
            // are displayed on the right half.
            return originalPosition >= 1 && originalPosition <= 9;
        }

        private void ClearActionEffects()
        {
            foreach (GameObject effect in activeEffects)
                if (effect != null) UnityEngine.Object.Destroy(effect);
            activeEffects.Clear();
        }

        private void ApplyImpact()
        {
            impactApplied = true;
            if (activeAction == null) return;
            if (activeAction.Targets.Count > 0)
            {
                foreach (WorldBattleTargetRecord record in activeAction.Targets)
                {
                    if (!units.TryGetValue(record.Position, out UnitView target)) continue;
                    if (activeAction.FirstActionType == 1 && record.Hit)
                    {
                        ApplyHpDelta(target, -(long)record.Damage);
                        ShowDamage(target, $"-{record.Damage}", record.Critical
                            ? new Color(1f, .82f, .08f, 1f) : new Color(1f, .22f, .12f, 1f), record.Critical);
                        PlayUnitAnimation(target, record.Dead ? "sw" : "bj", false);
                        ApplyProtectorImpact(record);
                        ApplyRetaliationImpact(record);
                    }
                    else if (activeAction.FirstActionType == 1)
                    {
                        ShowCombatMarker(target, "dodgetext");
                        PlayUnitAnimation(target, "zd", true);
                    }
                    else if (activeAction.FirstActionType == 2)
                    {
                        ApplyHpDelta(target, record.Healing);
                        ShowDamage(target, $"+{record.Healing}", new Color(.2f, 1f, .32f, 1f));
                    }
                    else if (activeAction.FirstActionType == 6)
                    {
                        if (record.Damage > 0)
                        {
                            ApplyHpDelta(target, -(long)record.Damage);
                            ShowDamage(target, $"-{record.Damage}", new Color(1f, .22f, .12f, 1f));
                            PlayUnitAnimation(target, record.Dead ? "sw" : "bj", false);
                        }
                        if (record.Healing > 0)
                        {
                            ApplyHpDelta(target, record.Healing);
                            ShowDamage(target, $"+{record.Healing}", new Color(.2f, 1f, .32f, 1f));
                        }
                    }
                    else if (record.Dead) PlayUnitAnimation(target, "sw", false);
                    RefreshBuffs(target, record.BuffIds);
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
                // BAT_PASSIVE carries only target state in LBattleLogic. When
                // source and target are the same unit, its empty default source
                // array is not authoritative and must not erase the target
                // buffs that DoPassiveBuff has just assigned.
                if (activeAction.FirstActionType != 6)
                    RefreshBuffs(activeSource, activeAction.SourceBuffIds);
            }
        }

        private void ApplyProtectorImpact(WorldBattleTargetRecord record)
        {
            if (record.ProtectorPosition == 0 || !units.TryGetValue(record.ProtectorPosition, out UnitView protector)) return;
            long delta = -(long)record.ProtectorDamage + record.ProtectorHealing;
            ApplyHpDelta(protector, delta);
            if (record.ProtectorDamage > 0)
                ShowDamage(protector, $"-{record.ProtectorDamage}", new Color(1f, .45f, .12f, 1f));
            else if (record.ProtectorHealing > 0)
                ShowDamage(protector, $"+{record.ProtectorHealing}", new Color(.2f, 1f, .32f, 1f));
            PlayUnitAnimation(protector, record.ProtectorDead ? "sw" : "bj", false);
            RefreshBuffs(protector, record.ProtectorBuffIds);
        }

        private void ApplyRetaliationImpact(WorldBattleTargetRecord record)
        {
            if (activeSource == null) return;
            units.TryGetValue(record.Position, out UnitView retaliator);
            if (record.ReflectedDamage > 0 && retaliator != null) ShowCombatMarker(retaliator, "injurytext");
            if (record.Countered && retaliator != null)
            {
                ShowCombatMarker(retaliator, "beatbacktext");
                if (record.CounterHit) PlayUnitAnimation(retaliator, "gj", false);
            }
            uint retaliationDamage = record.ReflectedDamage + (record.CounterHit ? record.CounterDamage : 0u);
            uint retaliationHealing = record.ReflectedHealing + (record.CounterHit ? record.CounterHealing : 0u);
            if (retaliationDamage > 0)
            {
                ApplyHpDelta(activeSource, -(long)retaliationDamage);
                ShowDamage(activeSource, $"-{retaliationDamage}", record.CounterCritical
                    ? new Color(1f, .82f, .08f, 1f) : new Color(1f, .22f, .12f, 1f), record.CounterCritical);
                PlayUnitAnimation(activeSource, "bj", false);
            }
            if (retaliationHealing > 0)
            {
                ApplyHpDelta(activeSource, retaliationHealing);
                ShowDamage(activeSource, $"+{retaliationHealing}", new Color(.2f, 1f, .32f, 1f));
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

        private bool PlayUnitAnimation(UnitView unit, string suffix, bool loop)
        {
            if (unit?.Model == null || string.IsNullOrWhiteSpace(unit.AnimationBase)) return false;
            if (!unit.Model.LoadLegacy(unit.AnimationBase + suffix)) return false;
            unit.Model.SetFlippedX(!unit.Data.IsEnemy);
            unit.Model.SetSpeedScale(1f / Mathf.Max(1f, PlaybackSpeed));
            try
            {
                unit.Model.Play(ResolveUnitActionIndex(unit), loop);
                return true;
            }
            catch { return false; }
        }

        private static void SetUnitColor(UnitView unit, Color color)
        {
            if (unit?.Model != null) unit.Model.SetColor(color);
            if (unit?.Portrait != null) unit.Portrait.color = color;
        }

        private static int ResolveDisplayedPosition(WorldBattleUnitRecord unit)
        {
            return ResolveDisplayedPosition(Mathf.Clamp(unit.Position, 1, 18));
        }

        private static int ResolveUnitActionIndex(UnitView unit)
        {
            // BattleUnitNode.lua uses action group 0 for the left side and
            // action group 1 plus horizontal flip for the local/right side.
            return unit?.Data != null && !unit.Data.IsEnemy ? 1 : 0;
        }

        private static int ResolveDisplayedPosition(int source)
        {
            int displayed = source <= 9 ? source + 9 : source - 9;
            return displayed >= 1 && displayed < CocosUnitAnchors.Length ? displayed : source;
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
            speedStep = (speedStep + 1) % CocosSpeedLabels.Length;
            ApplySpeedStep(true);
        }

        private void ApplySpeedStep(bool persist)
        {
            speedStep = Mathf.Clamp(speedStep, 0, CocosSpeedLabels.Length - 1);
            PlaybackSpeed = CocosPlaybackFactors[speedStep];
            if (speedLabel != null) speedLabel.text = $"×{SpeedDisplayMultiplier}\n加速";
            RefreshImportedSpeedVisual();
            float animationScale = 1f / Mathf.Max(1f, PlaybackSpeed);
            startEffect?.SetSpeedScale(animationScale);
            foreach (UnitView unit in units.Values)
            {
                unit?.Model?.SetSpeedScale(animationScale);
                unit?.QualityEffect?.SetSpeedScale(animationScale);
            }
            foreach (GameObject effect in activeEffects)
                effect?.GetComponent<ImodAnimationPlayer>()?.SetSpeedScale(animationScale);
            if (persist) saveSpeedStep?.Invoke(speedStep);
        }

        private void RefreshBuffs(UnitView unit, IReadOnlyList<byte> buffIds)
        {
            if (unit?.Root == null) return;
            foreach (GameObject visual in unit.BuffVisuals)
            {
                if (visual == null) continue;
                visual.SetActive(false);
                UnityEngine.Object.Destroy(visual);
            }
            unit.BuffVisuals.Clear();
            if (buffIds == null || buffIds.Count == 0)
            {
                BringHealthNodeToFront(unit);
                return;
            }

            int above = 0;
            int below = 0;
            // BattleUnitNode:AddBuff keeps one node per buff id even when the
            // protocol repeats the same state for multiple stack instances.
            foreach (byte buffId in buffIds.Distinct().Take(10))
            {
                if (!presentationCatalog.TryGetBuff(buffId, out BattleBuffDefinition buff)
                    || string.IsNullOrWhiteSpace(buff.ResourceName)) continue;
                GameObject visual = new GameObject($"Buff_{buffId}", typeof(RectTransform));
                RectTransform rect = visual.GetComponent<RectTransform>();
                rect.SetParent(unit.Root, false);
                rect.sizeDelta = new Vector2(28f, 28f);
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                float unitScale = unit.Data?.ScaleRatio ?? 1f;
                if (buff.Hit < 3)
                {
                    Vector3 hitPoint = ResolveHitPoint(unit, buff.Hit + 1);
                    rect.anchoredPosition = new Vector2(hitPoint.x + buff.Offset.x,
                        hitPoint.y + buff.Offset.y * unitScale);
                }
                else
                {
                    Vector2 hpPoint = (unit.HitDefinition?.HpBarPosition ?? new Vector2(0f, 100f)) * unitScale;
                    rect.anchoredPosition = buff.Hit == 3
                        ? hpPoint + new Vector2(-48f + above++ * 32f, 8f)
                        : hpPoint + new Vector2(-33f + below++ * 32f, -15f);
                }

                if (buff.ShowType == 1)
                {
                    Image image = visual.AddComponent<Image>();
                    image.sprite = Resources.Load<Sprite>("ProjectXBattle/BuffTips/" + buff.ResourceName);
                    image.preserveAspect = true;
                    image.raycastTarget = false;
                    if (image.sprite == null) UnityEngine.Object.Destroy(visual);
                    else unit.BuffVisuals.Add(visual);
                }
                else if (buff.ShowType == 2)
                {
                    rect.sizeDelta = new Vector2(180f, 180f);
                    ImodAnimationPlayer player = visual.AddComponent<ImodAnimationPlayer>();
                    if (!player.LoadLegacy("res2/Skill/" + buff.ResourceName)) UnityEngine.Object.Destroy(visual);
                    else
                    {
                        player.Play(0, true);
                        unit.BuffVisuals.Add(visual);
                    }
                }
                else UnityEngine.Object.Destroy(visual);
            }
            BringHealthNodeToFront(unit);
        }

        private static void BringHealthNodeToFront(UnitView unit)
        {
            // BattleHeadNode sets HPNode local Z to 100. Buff nodes are added
            // to the unit at default Z, so Quality_bg/A must cover a hit-3 buff
            // icon when their coordinates overlap. Preserve that hierarchy in
            // the Unity Canvas after every buff refresh.
            Transform healthRoot = unit?.HealthRoot;
            if (healthRoot == null) return;
            healthRoot.SetAsLastSibling();
        }

        private void ShowDamage(UnitView unit, string value, Color color, bool critical = false)
        {
            if (unit == null || string.IsNullOrWhiteSpace(value)) return;
            string trimmed = value.Trim();
            bool healing = trimmed.StartsWith("+", StringComparison.Ordinal);
            string digits = trimmed.TrimStart('+', '-');
            if (ulong.TryParse(digits, out _))
            {
                if (unit.NumberRoot == null) return;
                BuildBattleNumber(unit.NumberRoot, digits,
                    healing ? new Color(43f / 255f, 1f, 0f, 1f) : new Color(1f, 12f / 255f, 12f / 255f, 1f));
                unit.NumberRoot.anchoredPosition = new Vector2(0f, 30f);
                unit.NumberRoot.localScale = Vector3.zero;
                unit.NumberRoot.gameObject.SetActive(true);
                unit.NumberBasePosition = unit.NumberRoot.anchoredPosition;
                unit.NumberCritical = critical;
                if (unit.StatusLabel != null) unit.StatusLabel.gameObject.SetActive(false);
                return;
            }

            if (unit.StatusLabel == null) return;
            unit.StatusLabel.text = value;
            unit.StatusLabel.color = color;
            unit.StatusLabel.rectTransform.anchoredPosition = Vector2.zero;
            unit.StatusLabel.gameObject.SetActive(true);
        }

        private void BuildBattleNumber(RectTransform rootRect, string digits, Color color)
        {
            foreach (Transform child in rootRect) UnityEngine.Object.Destroy(child.gameObject);
            float glyphWidth = 29f;
            float startX = -(digits.Length - 1) * glyphWidth * .5f;
            for (int index = 0; index < digits.Length; index++)
            {
                int digit = digits[index] - '0';
                if (digit < 0 || digit > 9) continue;
                GameObject glyphObject = new GameObject($"Digit_{index}_{digit}", typeof(RectTransform), typeof(Image));
                RectTransform glyphRect = glyphObject.GetComponent<RectTransform>();
                glyphRect.SetParent(rootRect, false);
                glyphRect.anchorMin = glyphRect.anchorMax = new Vector2(.5f, .5f);
                glyphRect.anchoredPosition = new Vector2(startX + index * glyphWidth, 0f);
                glyphRect.sizeDelta = new Vector2(glyphWidth, 30f);
                Image glyph = glyphObject.GetComponent<Image>();
                glyph.sprite = battleNumberAtlasSprites[digit + 2];
                glyph.color = color;
                glyph.raycastTarget = false;
            }
        }

        private static void ShowCombatMarker(UnitView unit, string resourceName)
        {
            if (unit?.CombatMarker == null || string.IsNullOrWhiteSpace(resourceName)) return;
            unit.CombatMarker.sprite = Resources.Load<Sprite>("ProjectXBattle/SkillName/" + resourceName);
            RectTransform rect = unit.CombatMarker.rectTransform;
            if (resourceName == "skill_0")
            {
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.anchoredPosition = new Vector2(IsInRightSide(unit.Data.Position) ? 195f : -195f, 110f);
                rect.sizeDelta = new Vector2(142f, 42f);
            }
            else
            {
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .72f);
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = new Vector2(118f, 58f);
            }
            unit.CombatMarker.gameObject.SetActive(unit.CombatMarker.sprite != null);
        }

        private static void ShowSkillName(UnitView unit, WorldBattleActionRecord action)
        {
            if (unit == null || action == null) return;
            if (action.FirstActionType == 1 && action.SkillId == 0)
            {
                ShowCombatMarker(unit, "skill_0");
                return;
            }
            if (unit.SkillLabel == null || action.SkillId == 0) return;
            if (!HeroCatalog.TryGet((int)unit.Data.Picture, out HeroDefinition hero)
                || hero.SkillId != action.SkillId || string.IsNullOrWhiteSpace(hero.SkillName)) return;
            unit.SkillLabel.text = hero.SkillName;
            unit.SkillLabel.color = new Color(1f, .88f, .05f, 1f);
            unit.SkillLabel.rectTransform.anchoredPosition = Vector2.zero;
            unit.SkillLabel.gameObject.SetActive(true);
        }

        private static void AnimateSkillName(UnitView unit, float progress)
        {
            if (unit?.SkillLabel == null || !unit.SkillLabel.gameObject.activeSelf) return;
            float fade = Mathf.InverseLerp(.72f, .42f, progress);
            Color color = unit.SkillLabel.color;
            color.a = fade;
            unit.SkillLabel.color = color;
            unit.SkillLabel.rectTransform.anchoredPosition = new Vector2(0f, Mathf.Clamp01(progress / .72f) * 28f);
        }

        private static void HideSkillName(UnitView unit)
        {
            if (unit?.SkillLabel != null) unit.SkillLabel.gameObject.SetActive(false);
        }

        private void AnimateDamage(UnitView unit, float elapsed)
        {
            RectTransform label = unit?.NumberRoot;
            if (label == null || !label.gameObject.activeSelf) return;
            float sinceImpact = elapsed - impactProgress * actionDurationSeconds;
            if (sinceImpact < 0f) return;
            float settleStart;
            if (unit.NumberCritical)
            {
                if (sinceImpact < .3f) label.localScale = Vector3.one * Mathf.Lerp(0f, 3f, sinceImpact / .3f);
                else if (sinceImpact < .4f) label.localScale = Vector3.one * Mathf.Lerp(3f, 1.5f, (sinceImpact - .3f) / .1f);
                else label.localScale = Vector3.one * 1.5f;
                settleStart = 1.2f;
            }
            else
            {
                label.localScale = Vector3.one * Mathf.Clamp01(sinceImpact / .1f);
                settleStart = .9f;
            }
            float rise = Mathf.Clamp01((sinceImpact - settleStart) / .3f);
            float eased = 1f - Mathf.Cos(rise * Mathf.PI * .5f);
            label.anchoredPosition = unit.NumberBasePosition + new Vector2(0f, 125f * eased);
            foreach (Image glyph in label.GetComponentsInChildren<Image>(true))
            {
                Color color = glyph.color;
                color.a = 1f - rise;
                glyph.color = color;
            }
            if (rise >= 1f) label.gameObject.SetActive(false);
        }

        private static void HideDamage(UnitView unit)
        {
            if (unit?.NumberRoot != null) unit.NumberRoot.gameObject.SetActive(false);
            if (unit?.StatusLabel != null) unit.StatusLabel.gameObject.SetActive(false);
            if (unit?.CombatMarker != null) unit.CombatMarker.gameObject.SetActive(false);
        }

        private void ClearUnits()
        {
            ClearActionEffects();
            foreach (UnitView view in units.Values)
                if (view?.Root != null) UnityEngine.Object.Destroy(view.Root.gameObject);
            units.Clear();
            activeSource = activeTarget = null;
            activeActionType = 0;
        }
    }
}
