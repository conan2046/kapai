using System;
using System.Collections;
using System.Collections.Generic;
using ProjectX.Animation;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class MonopolyCell
    {
        public uint Id, EventId, EventCount, RoleId, Career, Level, Sex, Power, AwardType, AwardAmount;
        public string Name;
    }

    public sealed class MonopolyPresenter : IDisposable
    {
        private readonly CocosUiView mapView, hudView, handView;
        private readonly Action roll, queryBuy, reset, close, moveEnd, fight;
        private readonly Action<byte> playHand;
        private readonly Action<string> toast;
        private readonly RectTransform map;
        private readonly MonopolyRuntime runtime;
        private readonly Text rollText, killText, expText, coinText, goldText;
        private readonly Button rollButton;
        private readonly Toggle autoToggle;
        private readonly RectTransform handLeft, handRight, handResult;
        private readonly Image handLeftImage, handRightImage, handResultImage;
        private readonly Vector2 handLeftBase, handRightBase, handResultBase;
        private readonly List<GameObject> dynamicNodes = new List<GameObject>();
        private readonly Dictionary<uint, MonopolyCell> cells = new Dictionary<uint, MonopolyCell>();
        private readonly Dictionary<uint, Sprite> eventSprites = new Dictionary<uint, Sprite>();
        private readonly Dictionary<string, Sprite> handSprites = new Dictionary<string, Sprite>();
        private Texture2D atlas, handAtlas;
        private uint current = 1, rollMax, rollUse, monsterMax, monsterKill, exp, coin, gold;
        private byte selectedHand;
        private bool finished;

        public MonopolyPresenter(CocosUiView mapView, CocosUiView hudView, CocosUiView handView, byte playerModel, int playerLevel,
            Action roll, Action queryBuy, Action reset, Action close, Action moveEnd, Action fight,
            Action<byte> playHand, Action<string> toast, Action help)
        {
            this.mapView = mapView ?? throw new ArgumentNullException(nameof(mapView));
            this.hudView = hudView ?? throw new ArgumentNullException(nameof(hudView));
            this.handView = handView ?? throw new ArgumentNullException(nameof(handView));
            this.roll = roll ?? throw new ArgumentNullException(nameof(roll));
            this.queryBuy = queryBuy ?? throw new ArgumentNullException(nameof(queryBuy));
            this.reset = reset ?? throw new ArgumentNullException(nameof(reset));
            this.close = close ?? throw new ArgumentNullException(nameof(close));
            this.moveEnd = moveEnd ?? throw new ArgumentNullException(nameof(moveEnd));
            this.fight = fight ?? throw new ArgumentNullException(nameof(fight));
            this.playHand = playHand ?? throw new ArgumentNullException(nameof(playHand));
            this.toast = toast ?? throw new ArgumentNullException(nameof(toast));
            map = Require(mapView, "Layer/bg").GetComponent<RectTransform>();
            NormalizeRoot(mapView.GameObject.transform);
            NormalizeRoot(hudView.GameObject.transform);
            NormalizeRoot(handView.GameObject.transform);
            BuildMapTiles();
            runtime = mapView.GameObject.GetComponent<MonopolyRuntime>() ?? mapView.GameObject.AddComponent<MonopolyRuntime>();
            runtime.Initialize(map, new Vector2(4000f, 2496f), new Vector2(1334f, 750f));
            CreatePlayer(playerModel);

            rollText = RequireText(hudView, "Layer/Panel/BtnPanel/Times/Value");
            killText = RequireText(hudView, "Layer/Panel/KillBg/Image/Value");
            coinText = RequireText(hudView, "Layer/Panel/Reward/ListView/Coin/Value");
            goldText = RequireText(hudView, "Layer/Panel/Reward/ListView/Gold/Value");
            expText = RequireText(hudView, "Layer/Panel/Reward/ListView/kunlunbi/Value");
            rollButton = hudView.BindClick("Layer/Panel/BtnPanel/EnterBtn", () => { if (!finished) this.roll(); }, true);
            hudView.BindClick("Layer/Panel/BtnPanel/Times/AddBtn", this.queryBuy, true);
            hudView.BindClick("Layer/Panel/Refresh", this.reset, true);
            hudView.BindClick("Layer/Panel/Title/CloseBtn", this.close, true);
            hudView.BindClick("Layer/Panel/Title/TitleName/btn_help", help, true);
            handView.BindClick("Layer/caiquanUI/caiquanbg/btn_Stone", () => ChooseHand(3), true);
            handView.BindClick("Layer/caiquanUI/caiquanbg/btn_Scissor", () => ChooseHand(2), true);
            handView.BindClick("Layer/caiquanUI/caiquanbg/btn_Cloth", () => ChooseHand(1), true);
            handLeft = Require(handView, "Layer/caiquanUI/Image_1").GetComponent<RectTransform>();
            handRight = Require(handView, "Layer/caiquanUI/Image_2").GetComponent<RectTransform>();
            handResult = Require(handView, "Layer/caiquanUI/Result").GetComponent<RectTransform>();
            handLeftImage = handLeft.GetComponent<Image>(); handRightImage = handRight.GetComponent<Image>();
            handResultImage = handResult.GetComponent<Image>();
            handLeftBase = handLeft.anchoredPosition; handRightBase = handRight.anchoredPosition;
            handResultBase = handResult.anchoredPosition;
            handAtlas = Resources.Load<Texture2D>("Monopoly/huodong_chuangguan03");
            if (handAtlas == null) throw new InvalidOperationException("Monopoly formal hand atlas failed to load.");
            ApplyPortrait("Layer/caiquanUI/Npc/Icon", "Monopoly/guess_npc_505", "portrait_npc");
            ApplyPortrait("Layer/caiquanUI/User/Icon", playerModel == 4
                ? "Monopoly/guess_role_4" : "Monopoly/guess_role_5", "portrait_player");
            SetHandControls(true);
            GameObject auto = hudView.Binding.Find("Layer/Panel/BtnPanel/CheckBox_1");
            autoToggle = auto != null ? auto.GetComponent<Toggle>() : null;
            if (autoToggle != null)
            {
                autoToggle.isOn = playerLevel >= 56 && PlayerPrefs.GetInt("ProjectX.Monopoly.AutoPlay", 0) != 0;
                autoToggle.onValueChanged.RemoveAllListeners();
                autoToggle.onValueChanged.AddListener(enabled =>
                {
                    if (enabled && playerLevel < 56)
                    {
                        autoToggle.SetIsOnWithoutNotify(false);
                        toast("56级开启自动闯关");
                        return;
                    }
                    PlayerPrefs.SetInt("ProjectX.Monopoly.AutoPlay", enabled ? 1 : 0);
                    if (enabled) ScheduleAutoRoll(); else runtime.CancelAuto();
                });
            }
            Render();
        }

        public void Dispose()
        {
            ClearDynamic();
            foreach (Sprite sprite in eventSprites.Values) if (sprite != null) UnityEngine.Object.Destroy(sprite);
            eventSprites.Clear();
            foreach (Sprite sprite in handSprites.Values) if (sprite != null) UnityEngine.Object.Destroy(sprite);
            handSprites.Clear();
            handView.SetVisible(false);
            if (runtime != null) runtime.Cancel();
        }

        public void Replace(uint current, uint rollMax, uint rollUse, uint monsterMax, uint monsterKill,
            uint exp, uint coin, uint gold, IEnumerable<MonopolyCell> values)
        {
            this.current = Mathf.Clamp((int)current, 1, 82) > 0 ? (uint)Mathf.Clamp((int)current, 1, 82) : 1;
            this.rollMax = rollMax; this.rollUse = rollUse;
            this.monsterMax = monsterMax; this.monsterKill = monsterKill;
            this.exp = exp; this.coin = coin; this.gold = gold;
            finished = false;
            cells.Clear();
            foreach (MonopolyCell cell in values) cells[cell.Id] = cell;
            RebuildEvents();
            runtime.PlaceAt(Node(this.current), Node((uint)Mathf.Clamp((int)this.current + 1, 1, 82)));
            Render();
        }

        public void RollTo(uint destination, uint dice, uint maximum, uint remaining)
        {
            runtime.CancelAuto();
            rollMax = maximum; rollUse = remaining; Render();
            rollButton.interactable = false;
            runtime.ShowDice(dice, () => MoveTo(destination, () =>
            {
                current = destination;
                rollButton.interactable = !finished && rollUse > 0;
                moveEnd();
            }));
        }

        public void ResolveEvent(uint eventId, uint target)
        {
            if (eventId == 8 && target > 0 && target <= 82)
            {
                ConsumeCell(current);
                int delta = (int)target - (int)current;
                toast(delta >= 0 ? $"随机事件：前进{delta}格" : $"随机事件：后退{-delta}格");
                rollButton.interactable = false;
                MoveTo(target, () => { current = target; moveEnd(); });
                return;
            }
            if (eventId == 2) { rollButton.interactable = false; fight(); return; }
            if (eventId == 4) { ShowHand(); return; }
            if (eventId == 5) { ConsumeCell(current); finished = true; rollButton.interactable = false; toast("本轮闯关完成，可重置后继续"); return; }
            if (eventId == 3 || eventId == 6 || eventId == 7) ConsumeCell(current);
            if (eventId != 0)
                toast(EventMessage(eventId));
            rollButton.interactable = rollUse > 0;
            ScheduleAutoRoll();
        }

        public void BattleResult(bool win, uint destination, uint totalExp, uint totalCoin, uint totalGold,
            uint maximumKills, uint currentKills, uint stars, string rewards)
        {
            exp = totalExp; coin = totalCoin; gold = totalGold;
            monsterMax = maximumKills; monsterKill = currentKills;
            toast(win ? $"守卫挑战胜利  {stars}星  {rewards}" : "守卫挑战失败");
            if (win && destination > current)
            {
                ConsumeCell(current + 1);
                MoveTo(destination, () => { current = destination; Render(); moveEnd(); });
            }
            rollButton.interactable = rollUse > 0 && !finished;
            Render();
        }

        public void UpdateRewards(uint totalExp, uint totalCoin, uint totalGold)
        { exp = totalExp; coin = totalCoin; gold = totalGold; Render(); }

        public void UpdateRolls(uint maximum, uint remaining)
        { rollMax = maximum; rollUse = remaining; rollButton.interactable = remaining > 0 && !finished; Render(); }

        public void CompleteHand(uint result, string detail)
        {
            byte own = selectedHand >= 1 && selectedHand <= 3 ? selectedHand : (byte)3;
            byte opponent = result == 2 ? own : result == 1 ? (byte)(((own + 1) % 3) + 1) : (byte)((own % 3) + 1);
            ApplyHandSprite(handLeftImage, handLeft, HandKey(opponent), handLeftBase);
            ApplyHandSprite(handRightImage, handRight, HandKey(own), handRightBase);
            ApplyHandSprite(handResultImage, handResult, result == 1 ? "win" : result == 2 ? "draw" : "loss", handResultBase);
            handLeft.gameObject.SetActive(true); handRight.gameObject.SetActive(true); handResult.gameObject.SetActive(true);
            toast(!string.IsNullOrWhiteSpace(detail) ? detail : result == 1 ? "猜拳胜利，获得事件奖励" : result == 2 ? "猜拳平局，请重新出拳" : "猜拳失败");
            if (result != 2) ConsumeCell(current);
            runtime.ScheduleHandResult(1.5f, () =>
            {
                if (result == 2) { ShowHand(); return; }
                handView.SetVisible(false);
                rollButton.interactable = rollUse > 0 && !finished;
                ScheduleAutoRoll();
            });
        }

        public void SetBusy(bool busy) => rollButton.interactable = !busy && rollUse > 0 && !finished;

        private void ShowHand()
        {
            rollButton.interactable = false;
            selectedHand = 0;
            SetHandControls(true);
            handView.GameObject.transform.SetAsLastSibling();
            handView.Binding.Find("Layer/caiquanUI/caiquanbg")?.SetActive(true);
            handView.Binding.Find("Layer/caiquanUI/choosebg")?.SetActive(false);
            handLeft.gameObject.SetActive(false); handRight.gameObject.SetActive(false); handResult.gameObject.SetActive(false);
            handView.SetVisible(true);
        }

        private void ChooseHand(byte choice)
        {
            selectedHand = choice;
            SetHandControls(false);
            ApplyHandSprite(handLeftImage, handLeft, "stone", handLeftBase);
            ApplyHandSprite(handRightImage, handRight, "stone", handRightBase);
            handLeft.gameObject.SetActive(true); handRight.gameObject.SetActive(true); handResult.gameObject.SetActive(false);
            runtime.PlayHandAnimation(handLeft, handRight, () => playHand(choice));
        }

        private static string HandKey(byte choice) => choice == 1 ? "cloth" : choice == 2 ? "scissor" : "stone";

        private void ApplyHandSprite(Image image, RectTransform rect, string key, Vector2 basePosition)
        {
            Vector2 offset;
            Sprite sprite = HandSprite(key, out offset);
            image.sprite = sprite; image.preserveAspect = false;
            rect.sizeDelta = new Vector2(sprite.rect.width, sprite.rect.height);
            rect.anchoredPosition = basePosition + offset;
        }

        private Sprite HandSprite(string key, out Vector2 offset)
        {
            Rect topRect;
            switch (key)
            {
                case "cloth": topRect = new Rect(304, 145, 76, 78); offset = new Vector2(0, 1); break;
                case "scissor": topRect = new Rect(526, 145, 76, 60); offset = Vector2.zero; break;
                case "stone": topRect = new Rect(382, 145, 66, 72); offset = new Vector2(-1, 0); break;
                case "draw": topRect = new Rect(155, 145, 147, 81); offset = new Vector2(-1, 1); break;
                case "win": topRect = new Rect(604, 140, 151, 83); offset = new Vector2(0, 1); break;
                default: topRect = new Rect(2, 145, 151, 81); offset = Vector2.zero; break;
            }
            Sprite cached;
            if (handSprites.TryGetValue(key, out cached)) return cached;
            Rect unityRect = new Rect(topRect.x, handAtlas.height - topRect.y - topRect.height, topRect.width, topRect.height);
            Sprite sprite = Sprite.Create(handAtlas, unityRect, new Vector2(.5f, .5f), 100f);
            sprite.name = "MonopolyHand_" + key; handSprites[key] = sprite;
            return sprite;
        }

        private void ApplyPortrait(string path, string resourcePath, string cacheKey)
        {
            Texture2D texture = Resources.Load<Texture2D>(resourcePath);
            if (texture == null) throw new InvalidOperationException($"Monopoly portrait failed to load: {resourcePath}.");
            Image image = Require(handView, path).GetComponent<Image>();
            Sprite sprite = Sprite.Create(texture, new Rect(0f, 0f, texture.width, texture.height),
                new Vector2(.5f, 0f), 100f);
            sprite.name = "MonopolyHand_" + cacheKey;
            handSprites[cacheKey] = sprite;
            image.sprite = sprite;
            image.color = Color.white;
            image.preserveAspect = false;
        }

        private void SetHandControls(bool interactable)
        {
            string[] paths = {
                "Layer/caiquanUI/caiquanbg/btn_Stone",
                "Layer/caiquanUI/caiquanbg/btn_Scissor",
                "Layer/caiquanUI/caiquanbg/btn_Cloth"
            };
            foreach (string path in paths)
            {
                Button button = handView.Binding.Find(path)?.GetComponent<Button>();
                if (button != null) button.interactable = interactable;
            }
        }

        private void Render()
        {
            rollText.text = rollUse.ToString();
            killText.text = $"{monsterKill}/{monsterMax}";
            expText.text = exp.ToString();
            coinText.text = coin.ToString();
            goldText.text = gold.ToString();
            rollButton.interactable = rollUse > 0 && !finished && !runtime.IsMoving;
        }

        private void ScheduleAutoRoll()
        {
            if (autoToggle == null || !autoToggle.isOn || finished || rollUse == 0 || runtime.IsMoving || handView.GameObject.activeSelf)
                return;
            runtime.ScheduleAuto(.65f, () =>
            {
                if (autoToggle != null && autoToggle.isOn && !finished && rollUse > 0 && !runtime.IsMoving)
                    roll();
            });
        }

        private void MoveTo(uint destination, Action done)
        {
            var path = new List<RectTransform>();
            int from = Mathf.Clamp((int)current, 1, 82);
            int to = Mathf.Clamp((int)destination, 1, 82);
            int step = to >= from ? 1 : -1;
            for (int cell = from + step; step > 0 ? cell <= to : cell >= to; cell += step)
            {
                RectTransform node = Node((uint)cell);
                if (node != null) path.Add(node);
            }
            // Standing direction follows the board's next cell, regardless of how the
            // player reached this cell (normal advance, backward event, or relogin).
            int facingCell = Mathf.Clamp(to + 1, 1, 82);
            runtime.MovePath(path, Node((uint)facingCell), done);
        }

        private void BuildMapTiles()
        {
            GameObject hostObject = new GameObject("RuntimeMonopolyMapTiles", typeof(RectTransform));
            RectTransform host = hostObject.GetComponent<RectTransform>();
            host.SetParent(map, false); host.anchorMin = host.anchorMax = host.pivot = Vector2.zero;
            host.sizeDelta = new Vector2(4000f, 2496f); host.SetAsFirstSibling();
            float width = 0f, height = 0f, lastWidth = 0f, lastHeight = 0f;
            for (int index = 0; index < 40; index++)
            {
                Texture2D texture = Resources.Load<Texture2D>($"MonopolyMaps/UI_Scene_{index}");
                if (texture == null) throw new InvalidOperationException($"Monopoly map tile missing: {index}");
                int cocosIndex = index + 1;
                if (lastWidth > 0f)
                {
                    width += lastWidth;
                    if ((cocosIndex - 1) % 8 == 0) width = 0f;
                }
                if (lastHeight > 0f && (cocosIndex - 1) % 8 == 0) height += lastHeight;
                GameObject tile = new GameObject($"UI_Scene_{index}", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage));
                RectTransform rect = tile.GetComponent<RectTransform>();
                rect.SetParent(host, false); rect.anchorMin = rect.anchorMax = rect.pivot = Vector2.zero;
                rect.anchoredPosition = new Vector2(width, height);
                rect.sizeDelta = new Vector2(texture.width, texture.height);
                RawImage image = tile.GetComponent<RawImage>(); image.texture = texture; image.raycastTarget = false;
                lastWidth = texture.width; lastHeight = texture.height;
            }
        }

        private void CreatePlayer(byte model)
        {
            GameObject role = new GameObject("RuntimeMonopolyPlayer", typeof(RectTransform));
            RectTransform rect = role.GetComponent<RectTransform>();
            rect.SetParent(map, false); rect.anchorMin = rect.anchorMax = rect.pivot = Vector2.zero;
            rect.sizeDelta = Vector2.zero; rect.localScale = Vector3.one * .7f; rect.SetAsLastSibling();
            string prefix = HeroPrefix(model);
            string standPath = $"hero/{prefix}_0_fd";
            string runPath = $"hero/{prefix}_0_pb";
            GameObject standObject = new GameObject("StandAnimation", typeof(RectTransform));
            standObject.GetComponent<RectTransform>().SetParent(rect, false);
            ImodAnimationPlayer stand = standObject.AddComponent<ImodAnimationPlayer>();
            stand.SetPlayOnEnable(false);
            GameObject runObject = new GameObject("RunAnimation", typeof(RectTransform));
            runObject.GetComponent<RectTransform>().SetParent(rect, false);
            ImodAnimationPlayer run = runObject.AddComponent<ImodAnimationPlayer>();
            run.SetPlayOnEnable(false);
            bool loaded = stand.LoadLegacy(standPath) && run.LoadLegacy(runPath);
            role.SetActive(loaded);
            runObject.SetActive(false);
            runtime.SetPlayer(rect, stand, run);
            runtimePlayer = rect;
        }

        private RectTransform runtimePlayer;
        private RectTransform Node(uint id)
        {
            GameObject node = mapView.Binding.Find($"Layer/bg/Node_{Mathf.Clamp((int)id, 1, 82)}");
            return node != null ? node.GetComponent<RectTransform>() : null;
        }

        private void RebuildEvents()
        {
            ClearDynamic();
            atlas = Resources.Load<Texture2D>("Monopoly/ui_chuangguanPlist");
            foreach (MonopolyCell cell in cells.Values)
            {
                if (cell.EventId == 0 || cell.EventId == 1) continue;
                // Node_82 already contains the authored endpoint treasure. Do not
                // place a second runtime endpoint icon on top of it.
                if (cell.Id == 82 && cell.EventId == 5) continue;
                RectTransform node = Node(cell.Id);
                if (node == null) continue;
                if (cell.EventId == 2) { CreateGuard(node, cell); continue; }
                Sprite sprite = EventSprite(cell.EventId, out bool rotated);
                if (sprite == null) continue;
                GameObject icon = new GameObject($"RuntimeEvent_{cell.Id}_{cell.EventId}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform rect = icon.GetComponent<RectTransform>(); rect.SetParent(node, false);
                rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = new Vector2(5f, 10f);
                rect.sizeDelta = rotated
                    ? new Vector2(sprite.rect.height, sprite.rect.width)
                    : new Vector2(sprite.rect.width, sprite.rect.height);
                if (rotated) rect.localRotation = Quaternion.Euler(0f, 0f, 90f);
                Image image = icon.GetComponent<Image>(); image.sprite = sprite; image.preserveAspect = true; image.raycastTarget = false;
                dynamicNodes.Add(icon);
            }
        }

        private void CreateGuard(RectTransform node, MonopolyCell cell)
        {
            GameObject guard = new GameObject($"RuntimeGuard_{cell.Id}", typeof(RectTransform));
            RectTransform rect = guard.GetComponent<RectTransform>(); rect.SetParent(node, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f); rect.sizeDelta = Vector2.zero;
            rect.localScale = Vector3.one * .62f;
            ImodAnimationPlayer player = guard.AddComponent<ImodAnimationPlayer>();
            bool loaded = player.LoadLegacy($"hero/{HeroPrefix(cell.Career)}_0_fd");
            guard.SetActive(loaded); if (loaded) { try { player.Play(1, true); } catch { player.Play(0, true); } }
            dynamicNodes.Add(guard);
        }

        private Sprite EventSprite(uint eventId, out bool rotated)
        {
            rotated = false; if (atlas == null) return null;
            Sprite cached;
            if (eventSprites.TryGetValue(eventId, out cached))
            {
                rotated = eventId == 3 || eventId == 7;
                return cached;
            }
            Rect topRect;
            switch (eventId)
            {
                case 3: topRect = new Rect(200, 114, 90, 94); rotated = true; break;
                case 4: topRect = new Rect(296, 114, 82, 75); break;
                case 5: topRect = new Rect(1, 1, 197, 168); break;
                case 6: topRect = new Rect(373, 199, 79, 57); break;
                case 7: topRect = new Rect(296, 191, 69, 75); rotated = true; break;
                case 8: topRect = new Rect(454, 199, 44, 77); break;
                default: return null;
            }
            float packedWidth = rotated ? topRect.height : topRect.width;
            float packedHeight = rotated ? topRect.width : topRect.height;
            Rect unityRect = new Rect(topRect.x, atlas.height - topRect.y - packedHeight, packedWidth, packedHeight);
            Sprite sprite = Sprite.Create(atlas, unityRect, new Vector2(.5f, .5f), 100f);
            sprite.name = "MonopolyEvent_" + eventId;
            eventSprites[eventId] = sprite;
            return sprite;
        }

        private void ClearDynamic()
        {
            foreach (GameObject node in dynamicNodes) if (node != null) UnityEngine.Object.Destroy(node);
            dynamicNodes.Clear();
        }

        private void ConsumeCell(uint id)
        {
            RectTransform node = Node(id);
            if (node != null)
            {
                foreach (Transform child in node)
                    if (child.name.StartsWith("RuntimeEvent_", StringComparison.Ordinal)
                        || child.name.StartsWith("RuntimeGuard_", StringComparison.Ordinal))
                        child.gameObject.SetActive(false);
            }
            MonopolyCell cell;
            if (cells.TryGetValue(id, out cell)) cell.EventId = 0;
        }

        private static string EventMessage(uint eventId) => eventId switch
        {
            0 => string.Empty, 1 => "回到起点", 3 => "获得宝箱奖励", 4 => "完成猜拳事件",
            6 => "获得元宝奖励", 7 => "获得金币奖励", _ => "事件处理完成"
        };
        private static string HeroPrefix(uint model)
        {
            string[] values = { "Z", "B", "Y", "H", "K", "J" };
            return values[Mathf.Clamp((int)model - 1, 0, values.Length - 1)];
        }
        private static GameObject Require(CocosUiView view, string path) => view.Binding.Find(path)
            ?? throw new InvalidOperationException($"Monopoly imported node missing: {path}");
        private static Text RequireText(CocosUiView view, string path) => Require(view, path).GetComponent<Text>()
            ?? throw new InvalidOperationException($"Monopoly imported text missing: {path}");
        private static void NormalizeRoot(Transform value)
        {
            if (!(value is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.pivot = new Vector2(.5f, .5f); rect.localScale = Vector3.one; rect.localRotation = Quaternion.identity;
        }

        public void BindRuntimePlayer()
        {
            runtime.PlaceAt(Node(1), Node(2));
        }
    }

    public sealed class MonopolyRuntime : MonoBehaviour, IBeginDragHandler, IDragHandler
    {
        private RectTransform map, player, dice;
        private ImodAnimationPlayer playerStandAnimation, playerRunAnimation;
        private int playerDirection = 2;
        private ImodAnimationPlayer diceAnimation;
        private RawImage diceResult;
        private Vector2 mapSize, viewport;
        private Coroutine moveRoutine, diceRoutine, autoRoutine, handRoutine, handResultRoutine;
        public bool IsMoving => moveRoutine != null;
        public void Initialize(RectTransform map, Vector2 mapSize, Vector2 viewport)
        { this.map = map; this.mapSize = mapSize; this.viewport = viewport; }
        public void SetPlayer(RectTransform value, ImodAnimationPlayer standAnimation, ImodAnimationPlayer runAnimation)
        {
            player = value;
            playerStandAnimation = standAnimation;
            playerRunAnimation = runAnimation;
            if (playerRunAnimation != null) playerRunAnimation.gameObject.SetActive(false);
            if (playerStandAnimation != null)
            {
                playerStandAnimation.gameObject.SetActive(true);
                PlayFacing(playerStandAnimation, playerDirection);
            }
        }
        public void PlaceAt(RectTransform node, RectTransform facingNode = null)
        {
            if (node == null) return;
            if (player == null) player = transform.Find("Layer/bg/RuntimeMonopolyPlayer") as RectTransform;
            if (player != null) player.anchoredPosition = node.anchoredPosition;
            int previousDirection = playerDirection;
            if (player != null && facingNode != null
                && (facingNode.anchoredPosition - player.anchoredPosition).sqrMagnitude > .01f)
                playerDirection = Direction(player.anchoredPosition, facingNode.anchoredPosition);
            if (!IsMoving && playerStandAnimation != null && playerStandAnimation.IsLoaded)
            {
                if (playerRunAnimation != null) playerRunAnimation.gameObject.SetActive(false);
                playerStandAnimation.gameObject.SetActive(true);
                if (previousDirection != playerDirection || !playerStandAnimation.IsPlaying)
                    PlayFacing(playerStandAnimation, playerDirection);
            }
            Center(node.anchoredPosition);
        }
        public void MovePath(IEnumerable<RectTransform> nodes, RectTransform facingNode, Action done)
        {
            var points = new List<Vector2>();
            if (nodes != null)
                foreach (RectTransform node in nodes) if (node != null) points.Add(node.anchoredPosition);
            if (points.Count == 0) { done?.Invoke(); return; }
            if (moveRoutine != null) StopCoroutine(moveRoutine);
            Vector2? finalFacingPoint = facingNode != null ? facingNode.anchoredPosition : (Vector2?)null;
            moveRoutine = StartCoroutine(MoveRoutine(points, finalFacingPoint, done));
        }
        public void ShowDice(uint value, Action finished)
        {
            Texture2D texture = Resources.Load<Texture2D>($"Monopoly/shaizi_{Mathf.Clamp((int)value, 1, 6)}");
            if (texture == null) return;
            if (dice == null)
            {
                GameObject node = new GameObject("RuntimeMonopolyDice", typeof(RectTransform));
                dice = node.GetComponent<RectTransform>(); dice.SetParent(transform, false);
                dice.anchorMin = dice.anchorMax = new Vector2(.5f, .5f); dice.sizeDelta = new Vector2(150, 150);
                dice.anchoredPosition = new Vector2(-260f, 120f);
                GameObject animationNode = new GameObject("FormalDiceAnimation", typeof(RectTransform));
                RectTransform animationRect = animationNode.GetComponent<RectTransform>();
                animationRect.SetParent(dice, false); animationRect.anchorMin = animationRect.anchorMax = new Vector2(.5f, .5f);
                animationRect.sizeDelta = Vector2.zero;
                diceAnimation = animationNode.AddComponent<ImodAnimationPlayer>();
                diceAnimation.SetPlayOnEnable(false);
                if (!diceAnimation.LoadLegacy("UI/shaizi"))
                    throw new InvalidOperationException("Monopoly formal dice animation UI/shaizi failed to load.");
                diceAnimation.SetSpeedScale(.45f);

                GameObject resultNode = new GameObject("DiceResult", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage));
                RectTransform resultRect = resultNode.GetComponent<RectTransform>();
                resultRect.SetParent(dice, false); resultRect.anchorMin = resultRect.anchorMax = new Vector2(.5f, .5f);
                resultRect.sizeDelta = new Vector2(150f, 150f);
                diceResult = resultNode.GetComponent<RawImage>(); diceResult.raycastTarget = false;
            }
            diceResult.texture = texture; diceResult.color = Color.white; diceResult.gameObject.SetActive(false);
            diceAnimation.gameObject.SetActive(true); dice.gameObject.SetActive(true);
            if (diceRoutine != null) StopCoroutine(diceRoutine);
            diceAnimation.Play(0, false);
            diceRoutine = StartCoroutine(DiceRoutine(finished));
        }
        public void Cancel()
        {
            if (moveRoutine != null) StopCoroutine(moveRoutine); if (diceRoutine != null) StopCoroutine(diceRoutine);
            if (handRoutine != null) StopCoroutine(handRoutine); if (handResultRoutine != null) StopCoroutine(handResultRoutine);
            CancelAuto(); moveRoutine = diceRoutine = handRoutine = handResultRoutine = null;
        }
        public void ScheduleAuto(float delay, Action action)
        {
            CancelAuto();
            autoRoutine = StartCoroutine(AutoRoutine(delay, action));
        }
        public void CancelAuto()
        {
            if (autoRoutine != null) StopCoroutine(autoRoutine);
            autoRoutine = null;
        }
        public void PlayHandAnimation(RectTransform left, RectTransform right, Action send)
        {
            if (handRoutine != null) StopCoroutine(handRoutine);
            if (handResultRoutine != null) { StopCoroutine(handResultRoutine); handResultRoutine = null; }
            handRoutine = StartCoroutine(HandRoutine(left, right, send));
        }
        public void ScheduleHandResult(float delay, Action done)
        {
            if (handResultRoutine != null) StopCoroutine(handResultRoutine);
            handResultRoutine = StartCoroutine(HandResultRoutine(delay, done));
        }
        public void OnBeginDrag(PointerEventData eventData) { }
        public void OnDrag(PointerEventData eventData)
        {
            if (map == null || IsMoving) return;
            map.anchoredPosition = Clamp(map.anchoredPosition + eventData.delta);
        }
        private IEnumerator MoveRoutine(IReadOnlyList<Vector2> points, Vector2? finalFacingPoint, Action done)
        {
            if (player == null) { done?.Invoke(); moveRoutine = null; yield break; }
            if (playerStandAnimation != null) playerStandAnimation.gameObject.SetActive(false);
            if (playerRunAnimation != null) playerRunAnimation.gameObject.SetActive(true);
            foreach (Vector2 target in points)
            {
                Vector2 start = player.anchoredPosition; float elapsed = 0f;
                int nextDirection = Direction(start, target);
                if (playerRunAnimation != null && playerRunAnimation.IsLoaded
                    && (nextDirection != playerDirection || !playerRunAnimation.IsPlaying))
                    PlayFacing(playerRunAnimation, nextDirection);
                playerDirection = nextDirection;
                const float duration = .5f;
                while (elapsed < duration)
                {
                    elapsed += Time.unscaledDeltaTime; float t = Mathf.Clamp01(elapsed / duration);
                    player.anchoredPosition = Vector2.Lerp(start, target, t); Center(player.anchoredPosition); yield return null;
                }
                player.anchoredPosition = target; Center(target);
            }
            if (finalFacingPoint.HasValue && (finalFacingPoint.Value - player.anchoredPosition).sqrMagnitude > .01f)
                playerDirection = Direction(player.anchoredPosition, finalFacingPoint.Value);
            if (playerRunAnimation != null) playerRunAnimation.gameObject.SetActive(false);
            if (playerStandAnimation != null)
            {
                playerStandAnimation.gameObject.SetActive(true);
                PlayFacing(playerStandAnimation, playerDirection);
            }
            moveRoutine = null; done?.Invoke();
        }
        private static int Direction(Vector2 from, Vector2 to)
        {
            if (to.x > from.x && to.y < from.y) return 0;
            if (to.x < from.x && to.y < from.y) return 2;
            if (to.x < from.x && to.y > from.y) return 4;
            return 6;
        }
        private static void PlayFacing(ImodAnimationPlayer animation, int face)
        {
            if (animation == null || !animation.IsLoaded) return;
            int action;
            bool flipX;
            switch (face)
            {
                case 2: action = 0; flipX = true; break;
                case 4: action = 3; flipX = true; break;
                case 6: action = 3; flipX = false; break;
                default: action = 0; flipX = false; break;
            }
            animation.SetFlippedX(flipX);
            animation.Play(action, true);
        }
        private IEnumerator DiceRoutine(Action finished)
        {
            while (diceAnimation != null && diceAnimation.IsPlaying) yield return null;
            if (diceAnimation != null)
            {
                diceAnimation.Stop();
                diceAnimation.gameObject.SetActive(false);
            }
            if (diceResult != null)
            {
                diceResult.color = Color.white;
                diceResult.gameObject.SetActive(true);
                diceResult.transform.SetAsLastSibling();
            }
            // Keep the authoritative server result still for a readable beat
            // before movement starts.
            yield return new WaitForSecondsRealtime(.35f);
            finished?.Invoke();
            yield return new WaitForSecondsRealtime(1f);
            float elapsed = 0f;
            while (elapsed < .5f)
            {
                elapsed += Time.unscaledDeltaTime;
                if (diceResult != null)
                    diceResult.color = new Color(1f, 1f, 1f, 1f - Mathf.Clamp01(elapsed / .5f));
                yield return null;
            }
            dice.gameObject.SetActive(false); diceRoutine = null;
        }
        private IEnumerator AutoRoutine(float delay, Action action)
        {
            yield return new WaitForSecondsRealtime(Mathf.Max(.05f, delay));
            autoRoutine = null; action?.Invoke();
        }
        private IEnumerator HandRoutine(RectTransform left, RectTransform right, Action send)
        {
            Vector2 leftBase = left.anchoredPosition, rightBase = right.anchoredPosition;
            for (int tick = 0; tick < 6; tick++)
            {
                float offset = tick % 2 == 0 ? -10f : 10f;
                left.anchoredPosition = leftBase + Vector2.up * offset;
                right.anchoredPosition = rightBase + Vector2.up * offset;
                yield return new WaitForSecondsRealtime(.1f);
            }
            left.anchoredPosition = leftBase; right.anchoredPosition = rightBase;
            handRoutine = null; send?.Invoke();
        }
        private IEnumerator HandResultRoutine(float delay, Action done)
        {
            yield return new WaitForSecondsRealtime(Mathf.Max(.05f, delay));
            handResultRoutine = null; done?.Invoke();
        }
        private void Center(Vector2 point) => map.anchoredPosition = Clamp(new Vector2(viewport.x*.5f-point.x, viewport.y*.5f-point.y));
        private Vector2 Clamp(Vector2 value) => new Vector2(Mathf.Clamp(value.x, viewport.x-mapSize.x, 0f), Mathf.Clamp(value.y, viewport.y-mapSize.y, 0f));
    }
}
