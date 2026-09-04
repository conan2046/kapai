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
    public readonly struct HeroRebirthReward
    {
        public HeroRebirthReward(int type, uint id, uint quantity)
        {
            Type = type;
            Id = checked((int)id);
            Quantity = quantity;
        }

        public int Type { get; }
        public int Id { get; }
        public uint Quantity { get; }
    }

    public sealed class HeroRebirthPresenter : IDisposable
    {
        private const int RebirthCost = 50;
        private readonly CocosUiView view;
        private readonly CocosUiView chooseFrame;
        private readonly CocosUiView chooseView;
        private readonly CocosUiView confirmView;
        private readonly HeroStore heroes;
        private readonly FormationStore formation;
        private readonly CurrencyStore currencies;
        private readonly EquipmentCatalog items;
        private readonly ResourceService resources;
        private readonly Action<int> requestPreview;
        private readonly Action<int> confirmRebirth;
        private readonly Action<string> feedback;
        private readonly Action<HeroRebirthReward> showItemDetail;
        private readonly VirtualList<CandidateRow> candidateList;
        private readonly VirtualList<RewardRow> rewardList;
        private readonly VirtualList<RewardRow> confirmRewardList;
        private readonly List<HeroRebirthReward> pendingRewards = new List<HeroRebirthReward>();
        private readonly List<HeroRebirthReward> rewards = new List<HeroRebirthReward>();
        private readonly Dictionary<int, Button> candidateButtons = new Dictionary<int, Button>();
        private readonly List<Button> rewardButtons = new List<Button>();
        private readonly List<Button> confirmRewardButtons = new List<Button>();
        private readonly ImodAnimationPlayer model;
        private readonly Image fallbackPortrait;
        private int selectedHeroId;
        private int pendingOperation;
        private int pendingHeroId;
        private bool previewReady;

        public HeroRebirthPresenter(CocosUiView view, CocosUiView chooseFrame, CocosUiView chooseView,
            CocosUiView confirmView, HeroStore heroes, FormationStore formation, CurrencyStore currencies,
            EquipmentCatalog items, ResourceService resources, Action<int> requestPreview,
            Action<int> confirmRebirth, Action<string> feedback, Action<HeroRebirthReward> showItemDetail)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.chooseFrame = chooseFrame ?? throw new ArgumentNullException(nameof(chooseFrame));
            this.chooseView = chooseView ?? throw new ArgumentNullException(nameof(chooseView));
            this.confirmView = confirmView ?? throw new ArgumentNullException(nameof(confirmView));
            this.heroes = heroes ?? throw new ArgumentNullException(nameof(heroes));
            this.formation = formation ?? throw new ArgumentNullException(nameof(formation));
            this.currencies = currencies ?? throw new ArgumentNullException(nameof(currencies));
            this.items = items ?? throw new ArgumentNullException(nameof(items));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.requestPreview = requestPreview ?? throw new ArgumentNullException(nameof(requestPreview));
            this.confirmRebirth = confirmRebirth ?? throw new ArgumentNullException(nameof(confirmRebirth));
            this.feedback = feedback ?? throw new ArgumentNullException(nameof(feedback));
            this.showItemDetail = showItemDetail ?? throw new ArgumentNullException(nameof(showItemDetail));

            GameObject candidateViewport = Require(chooseView, "Layer/ChooseUI/Popup/TableView");
            GameObject candidateTemplate = Require(chooseView, "Layer/ChooseUI/Popup/ItemList");
            candidateList = new VirtualList<CandidateRow>(candidateViewport, candidateTemplate,
                Mathf.Max(150f, candidateTemplate.GetComponent<RectTransform>().rect.height), BindCandidateRow);

            GameObject rewardViewport = Require(view, "Layer/shenjiangchongshengUI/chongsheng/fanhuan/TableView");
            GameObject rewardTemplate = Require(view, "Layer/shenjiangchongshengUI/chongsheng/fanhuan/ItemList");
            rewardList = new VirtualList<RewardRow>(rewardViewport, rewardTemplate,
                Mathf.Max(90f, rewardTemplate.GetComponent<RectTransform>().rect.height),
                (row, value, index) => BindRewardRow(row, value, index,
                    Require(view, "Layer/shenjiangchongshengUI/chongsheng/fanhuan/Item"), rewardButtons));

            GameObject confirmViewport = Require(confirmView, "Layer/Popup/fanhuan/TableView");
            GameObject confirmTemplate = Require(confirmView, "Layer/Popup/fanhuan/ItemList");
            confirmRewardList = new VirtualList<RewardRow>(confirmViewport, confirmTemplate,
                Mathf.Max(90f, confirmTemplate.GetComponent<RectTransform>().rect.height),
                (row, value, index) => BindRewardRow(row, value, index,
                    Require(confirmView, "Layer/Popup/fanhuan/Item"), confirmRewardButtons));

            Transform modelHost = Require(view, "Layer/shenjiangchongshengUI/bg/Image/ModelNode").transform;
            GameObject modelObject = new GameObject("RuntimeHeroRebirthModel", typeof(RectTransform));
            RectTransform modelRect = modelObject.GetComponent<RectTransform>();
            modelRect.SetParent(modelHost, false);
            modelRect.anchorMin = modelRect.anchorMax = new Vector2(.5f, .5f);
            modelRect.anchoredPosition = Vector2.zero;
            modelRect.sizeDelta = Vector2.zero;
            model = modelObject.AddComponent<ImodAnimationPlayer>();
            fallbackPortrait = CreateImage(modelHost, "RuntimeHeroRebirthPortrait");

            view.BindClick("Layer/shenjiangchongshengUI/bg/Btn_add", ShowCandidates, true);
            view.BindClick("Layer/shenjiangchongshengUI/bg/Btn_Change", ShowCandidates, true);
            view.BindClick("Layer/shenjiangchongshengUI/chongsheng/Btn_chongsheng", OpenConfirmation, true);
            chooseFrame.BindClick("Layer/shopBg/Popup/Btn_close", CloseCandidates, true);
            confirmView.BindClick("Layer/Popup/Btn_close", CloseConfirmation, true);
            confirmView.BindClick("Layer/Popup/Btn_Cancel", CloseConfirmation, true);
            confirmView.BindClick("Layer/Popup/Btn_Confirm", Confirm, true);
            heroes.Changed += HandleHeroSnapshot;
            currencies.Changed += RenderCurrency;
            Reset();
        }

        public int EligibleCount => GetCandidates().Count;
        public int SelectedHeroId => selectedHeroId;
        public int RefundCount => rewards.Count;
        public bool PreviewReady => previewReady;
        public bool IsPending => pendingOperation != 0;
        public IReadOnlyList<HeroRebirthReward> Rewards => rewards;
        public bool IsCandidateOpen => chooseFrame.GameObject.activeSelf && chooseView.GameObject.activeSelf;
        public bool IsConfirmOpen => confirmView.GameObject.activeSelf;
        public bool IsModelLoaded => model != null && model.IsLoaded;
        public Button AddButton => view.Binding.Find("Layer/shenjiangchongshengUI/bg/Btn_add")?.GetComponent<Button>();
        public Button ChangeButton => view.Binding.Find("Layer/shenjiangchongshengUI/bg/Btn_Change")?.GetComponent<Button>();
        public Button RebirthButton => view.Binding.Find("Layer/shenjiangchongshengUI/chongsheng/Btn_chongsheng")?.GetComponent<Button>();
        public Button CandidateCloseButton => chooseFrame.Binding.Find("Layer/shopBg/Popup/Btn_close")?.GetComponent<Button>();
        public Button ConfirmCloseButton => confirmView.Binding.Find("Layer/Popup/Btn_close")?.GetComponent<Button>();
        public Button ConfirmCancelButton => confirmView.Binding.Find("Layer/Popup/Btn_Cancel")?.GetComponent<Button>();
        public Button ConfirmButton => confirmView.Binding.Find("Layer/Popup/Btn_Confirm")?.GetComponent<Button>();
        public Button FirstRewardButton => rewardButtons.FirstOrDefault(button => button != null);
        public Button FirstConfirmRewardButton => confirmRewardButtons.FirstOrDefault(button => button != null);
        public ScrollRect CandidateScroll => chooseView.Binding.Find("Layer/ChooseUI/Popup/TableView")?.GetComponent<ScrollRect>();
        public ScrollRect RewardScroll => view.Binding.Find("Layer/shenjiangchongshengUI/chongsheng/fanhuan/TableView")?.GetComponent<ScrollRect>();
        public ScrollRect ConfirmRewardScroll => confirmView.Binding.Find("Layer/Popup/fanhuan/TableView")?.GetComponent<ScrollRect>();
        public Button GetCandidateButton(int heroId)
            => candidateButtons.TryGetValue(heroId, out Button button) ? button : null;
        public bool ScrollCandidatesToBottom() => candidateList.ScrollToBottom();
        public bool ScrollRewardsToBottom() => rewardList.ScrollToBottom();

        public bool ValidateEarlyPlayRuntime(out string detail)
        {
            IReadOnlyList<HeroRecord> candidates = GetCandidates();
            bool controlsReady = AddButton != null && ChangeButton != null && RebirthButton != null
                && CandidateCloseButton != null && ConfirmCloseButton != null
                && ConfirmCancelButton != null && ConfirmButton != null;
            bool candidateBoundaryReady = candidates.Count >= 7
                && candidates.All(hero => formation.GetCombatPosition(hero.Id) == 0)
                && candidates.All(hero => hero.Level > 1 || hero.BreakLevel > 0 || hero.CultivationLevel > 0);
            bool fixedProfilesReady = heroes.TryGet(64, out HeroRecord maximum)
                && maximum.Level == 100 && maximum.BreakLevel == 15 && maximum.CultivationLevel == 20
                && heroes.TryGet(62, out HeroRecord initial)
                && initial.Level == 1 && initial.BreakLevel == 0 && initial.CultivationLevel == 0
                && !candidates.Any(hero => hero.Id == 62);
            detail = $"controls={controlsReady}; candidates={candidates.Count}; fixedProfiles={fixedProfilesReady}; boundPremium={currencies.BoundPremium}";
            return controlsReady && candidateBoundaryReady && fixedProfilesReady;
        }

        public void Show()
        {
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
            Render();
        }

        public void Hide()
        {
            CloseConfirmation();
            CloseCandidates();
            view.SetVisible(false);
        }

        public void Reset()
        {
            selectedHeroId = 0;
            pendingOperation = 0;
            pendingHeroId = 0;
            previewReady = false;
            rewards.Clear();
            pendingRewards.Clear();
            CloseConfirmation();
            CloseCandidates();
            Render();
        }

        public void BeginResponse(int operation, int heroId, int expectedCount)
        {
            pendingOperation = operation;
            pendingHeroId = heroId;
            pendingRewards.Clear();
            if (expectedCount > pendingRewards.Capacity) pendingRewards.Capacity = expectedCount;
        }

        public void AddResponseReward(int type, uint id, uint quantity)
            => pendingRewards.Add(new HeroRebirthReward(type, id, quantity));

        public void EndResponse(int operation, int heroId, bool success, string error)
        {
            if (operation != pendingOperation || heroId != pendingHeroId)
            {
                feedback("神将重生响应与当前请求不一致");
                ClearPending();
                return;
            }
            if (!success)
            {
                feedback(string.IsNullOrWhiteSpace(error) ? "神将重生失败" : error);
                ClearPending();
                return;
            }
            rewards.Clear();
            rewards.AddRange(pendingRewards);
            if (operation == 8)
            {
                selectedHeroId = heroId;
                previewReady = true;
                Render();
            }
            else if (operation == 9)
            {
                selectedHeroId = 0;
                previewReady = false;
                CloseConfirmation();
                feedback("神将重生成功");
                Render();
            }
            ClearPending();
        }

        public void Dispose()
        {
            heroes.Changed -= HandleHeroSnapshot;
            currencies.Changed -= RenderCurrency;
            candidateList.Dispose();
            rewardList.Dispose();
            confirmRewardList.Dispose();
        }

        private void ClearPending()
        {
            pendingOperation = 0;
            pendingHeroId = 0;
            pendingRewards.Clear();
        }

        private void ShowCandidates()
        {
            IReadOnlyList<HeroRecord> candidates = GetCandidates();
            candidateButtons.Clear();
            candidateList.SetItems(ToCandidateRows(candidates));
            SetText(chooseFrame, "Layer/shopBg/Popup/Title/Title", "选择神将");
            GameObject tabs = chooseFrame.Binding.Find("Layer/shopBg/Btn_ListView");
            if (tabs != null) tabs.SetActive(false);
            chooseFrame.SetVisible(true);
            chooseView.SetVisible(true);
            chooseFrame.GameObject.transform.SetAsLastSibling();
            chooseView.GameObject.transform.SetAsLastSibling();
            if (candidates.Count == 0) feedback("暂无可重生神将");
        }

        private void CloseCandidates()
        {
            chooseView.SetVisible(false);
            chooseFrame.SetVisible(false);
        }

        private void SelectHero(int heroId)
        {
            if (pendingOperation != 0) return;
            CloseCandidates();
            selectedHeroId = heroId;
            previewReady = false;
            rewards.Clear();
            Render();
            pendingOperation = 8;
            pendingHeroId = heroId;
            pendingRewards.Clear();
            requestPreview(heroId);
        }

        private void OpenConfirmation()
        {
            if (!previewReady || selectedHeroId <= 0) return;
            if (currencies.BoundPremium < RebirthCost)
            {
                feedback("元宝不足");
                return;
            }
            SetText(confirmView, "Layer/Popup/Title/Title", "重生确认");
            SetText(confirmView, "Layer/Popup/fanhuan/Title/Title", "返还物品");
            SetText(confirmView, "Layer/Popup/Btn_Cancel/Text", "取消");
            SetText(confirmView, "Layer/Popup/Btn_Confirm/Text", "确定");
            confirmRewardList.SetItems(ToRewardRows(rewards));
            confirmView.SetVisible(true);
            confirmView.GameObject.transform.SetAsLastSibling();
        }

        private void CloseConfirmation() => confirmView.SetVisible(false);

        private void Confirm()
        {
            if (!previewReady || selectedHeroId <= 0 || pendingOperation != 0) return;
            int heroId = selectedHeroId;
            CloseConfirmation();
            pendingOperation = 9;
            pendingHeroId = heroId;
            pendingRewards.Clear();
            confirmRebirth(heroId);
        }

        public bool BeginValidationRequest(int operation, int heroId)
        {
            if (pendingOperation != 0 || (operation != 8 && operation != 9) || heroId <= 0) return false;
            pendingOperation = operation;
            pendingHeroId = heroId;
            pendingRewards.Clear();
            return true;
        }

        private void HandleHeroSnapshot()
        {
            if (selectedHeroId > 0 && !heroes.TryGet(selectedHeroId, out _)) Reset();
            else Render();
        }

        private void Render()
        {
            HeroRecord hero = default;
            bool selected = selectedHeroId > 0 && heroes.TryGet(selectedHeroId, out hero);
            SetVisible(view, "Layer/shenjiangchongshengUI/Text", !selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/bg/Btn_add", !selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/bg/Btn_Change", selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/bg/Name", selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/bg/StarList", selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/bg/Image1", !selected);
            SetVisible(view, "Layer/shenjiangchongshengUI/chongsheng", selected);
            model.gameObject.SetActive(selected);
            fallbackPortrait.gameObject.SetActive(false);
            SetText(view, "Layer/shenjiangchongshengUI/Text",
                "重生后：\n神将等级重置为1级\n神将突破重置为初始状态\n神将星级保持不变\n返还所有的养成资源");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/Title_1/Title", "重生属性");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/Title_2/Title", "返还物品");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/Btn_chongsheng/Text", "重生");
            SetText(view, "Layer/shenjiangchongshengUI/bg/Btn_Change/Text", "更换");
            RenderCurrency();
            if (!selected)
            {
                rewardList.SetItems(Array.Empty<RewardRow>());
                return;
            }

            SetText(view, "Layer/shenjiangchongshengUI/bg/Name", hero.Name);
            SetStars(Require(view, "Layer/shenjiangchongshengUI/bg/StarList").transform, hero.Star);
            SetStars(Require(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_3/StarList").transform, hero.Star);
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_1/Value_1", hero.Level.ToString());
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_1/Value_2", "1");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_2/Value_1", $"+{hero.BreakLevel}");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_2/Value_2", "+0");
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_3/Value_1", hero.Star.ToString());
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/shuxing/Atrribute_3/Value_2", hero.Star.ToString());
            SetVisible(view, "Layer/shenjiangchongshengUI/chongsheng/fanhuan/Tips", !previewReady || rewards.Count == 0);
            SetText(view, "Layer/shenjiangchongshengUI/chongsheng/fanhuan/Tips", previewReady ? "无可返还物品" : "正在获取返还信息");
            rewardList.SetItems(previewReady ? ToRewardRows(rewards) : Array.Empty<RewardRow>());
            RenderModel(hero.Id);
        }

        private void RenderCurrency()
            => SetText(view, "Layer/shenjiangchongshengUI/chongsheng/ConsumeBg/Value", RebirthCost.ToString());

        private void RenderModel(int heroId)
        {
            bool loaded = HeroCatalog.TryGet(heroId, out HeroDefinition definition)
                && model.LoadLegacy($"Monster/btm{definition.Picture}_zd_show");
            model.gameObject.SetActive(loaded);
            fallbackPortrait.gameObject.SetActive(!loaded);
            if (loaded) model.Play(0, true);
            else
            {
                fallbackPortrait.sprite = HeroCatalog.TryGet(heroId, out definition)
                    ? resources.LoadHeroPortrait(definition.Picture) : resources.LoadHeroPortrait(heroId);
                fallbackPortrait.preserveAspect = true;
            }
        }

        private IReadOnlyList<HeroRecord> GetCandidates() => heroes.Items
            .Where(hero => formation.GetCombatPosition(hero.Id) == 0
                && (hero.Level > 1 || hero.BreakLevel > 0 || hero.CultivationLevel > 0))
            .OrderByDescending(hero => hero.Level)
            .ThenByDescending(hero => hero.BreakLevel)
            .ThenByDescending(hero => hero.CultivationLevel)
            .ThenBy(hero => hero.Id)
            .ToArray();

        private void BindCandidateRow(RectTransform row, CandidateRow value, int rowIndex)
        {
            BindCandidate(row.Find("Item1"), value.First);
            BindCandidate(row.Find("Item2"), value.Second);
        }

        private void BindCandidate(Transform cell, HeroRecord? value)
        {
            if (cell == null) return;
            cell.gameObject.SetActive(value.HasValue);
            if (!value.HasValue) return;
            HeroRecord hero = value.Value;
            SetText(cell, "Name", hero.Name);
            SetText(cell, "Atrribute_1", $"等级:{hero.Level}");
            SetText(cell, "Atrribute_2", $"突破:+{hero.BreakLevel}");
            SetVisible(cell, "Atrribute_3", false);
            SetVisible(cell, "Recommend", false);
            SetVisible(cell, "zhujue", false);
            SetVisible(cell, "zhuzhen", false);
            Image portrait = cell.Find("Icon")?.GetComponent<Image>();
            if (portrait != null && HeroCatalog.TryGet(hero.Id, out HeroDefinition definition))
            {
                portrait.sprite = resources.LoadHeroPortrait(definition.Picture);
                portrait.preserveAspect = true;
            }
            Button button = cell.Find("Btn_Choose")?.GetComponent<Button>();
            if (button == null) button = cell.Find("Btn_Choose")?.gameObject.AddComponent<Button>();
            if (button != null)
            {
                button.interactable = true;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => SelectHero(hero.Id));
                candidateButtons[hero.Id] = button;
            }
        }

        private void BindRewardRow(RectTransform row, RewardRow value, int rowIndex, GameObject itemTemplate,
            List<Button> boundButtons)
        {
            if (rowIndex == 0) boundButtons.Clear();
            foreach (Transform child in row.Cast<Transform>().ToArray())
                if (child.name.StartsWith("RuntimeRebirthReward", StringComparison.Ordinal))
                    UnityEngine.Object.Destroy(child.gameObject);
            for (int index = 0; index < value.Items.Count; index++)
            {
                HeroRebirthReward reward = value.Items[index];
                GameObject item = UnityEngine.Object.Instantiate(itemTemplate, row, false);
                item.name = $"RuntimeRebirthReward{index + 1}";
                item.SetActive(true);
                RectTransform rect = item.GetComponent<RectTransform>();
                rect.anchorMin = rect.anchorMax = new Vector2(0f, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = new Vector2(52f + index * 98f, 0f);
                int itemId = reward.Type != 0 ? reward.Type : reward.Id;
                EquipmentMaterialDefinition definition = items.GetItem(itemId);

                GameObject frameObject = new GameObject("Quality", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform frameRect = frameObject.GetComponent<RectTransform>();
                frameRect.SetParent(item.transform, false);
                frameRect.anchorMin = frameRect.anchorMax = new Vector2(.5f, .5f);
                frameRect.pivot = new Vector2(.5f, .5f);
                frameRect.anchoredPosition = Vector2.zero;
                frameRect.sizeDelta = new Vector2(84f, 84f);
                Image frame = frameObject.GetComponent<Image>();
                frame.sprite = resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(definition?.Quality ?? 1, 1, 7):00}");
                frame.enabled = frame.sprite != null;
                frame.preserveAspect = true;
                frame.raycastTarget = true;

                GameObject iconObject = new GameObject("Icon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.SetParent(item.transform, false);
                iconRect.anchorMin = iconRect.anchorMax = new Vector2(.5f, .5f);
                iconRect.pivot = new Vector2(.5f, .5f);
                iconRect.anchoredPosition = Vector2.zero;
                iconRect.sizeDelta = new Vector2(68f, 68f);
                Image icon = iconObject.GetComponent<Image>();
                icon.sprite = definition == null ? null : resources.LoadItemIcon(definition.Picture);
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
                icon.raycastTarget = false;

                GameObject quantityObject = new GameObject("Quantity", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text), typeof(Outline));
                RectTransform quantityRect = quantityObject.GetComponent<RectTransform>();
                quantityRect.SetParent(item.transform, false);
                quantityRect.anchorMin = Vector2.zero;
                quantityRect.anchorMax = Vector2.one;
                quantityRect.offsetMin = new Vector2(4f, 3f);
                quantityRect.offsetMax = new Vector2(-5f, -3f);
                Text quantity = quantityObject.GetComponent<Text>();
                quantity.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                quantity.fontSize = 17;
                quantity.alignment = TextAnchor.LowerRight;
                quantity.color = Color.white;
                quantity.text = reward.Quantity.ToString();
                quantity.raycastTarget = false;
                Outline outline = quantityObject.GetComponent<Outline>();
                outline.effectColor = new Color(0f, 0f, 0f, .75f);
                outline.effectDistance = new Vector2(1f, -1f);

                Button button = item.GetComponent<Button>() ?? item.AddComponent<Button>();
                button.targetGraphic = frame.enabled ? frame : icon;
                button.interactable = true;
                button.onClick.RemoveAllListeners();
                button.onClick.AddListener(() => showItemDetail(reward));
                boundButtons.Add(button);
            }
        }

        private string RewardName(HeroRebirthReward reward)
        {
            int itemId = reward.Type != 0 ? reward.Type : reward.Id;
            if (itemId == CurrencyIds.Gold) return "铜钱";
            if (itemId == CurrencyIds.BoundPremium) return "绑定元宝";
            return items.GetItem(itemId)?.Name ?? $"物品 #{itemId}";
        }

        public string DescribeReward(HeroRebirthReward reward)
            => $"{RewardName(reward)} ×{reward.Quantity}";

        private static CandidateRow[] ToCandidateRows(IReadOnlyList<HeroRecord> source)
        {
            var rows = new List<CandidateRow>();
            for (int index = 0; index < source.Count; index += 2)
                rows.Add(new CandidateRow(source[index], index + 1 < source.Count ? source[index + 1] : (HeroRecord?)null));
            return rows.ToArray();
        }

        private static RewardRow[] ToRewardRows(IReadOnlyList<HeroRebirthReward> source)
        {
            var rows = new List<RewardRow>();
            for (int index = 0; index < source.Count; index += 5)
                rows.Add(new RewardRow(source.Skip(index).Take(5).ToArray()));
            return rows.ToArray();
        }

        private static void SetText(CocosUiView owner, string path, string value)
        {
            Text text = owner.Binding.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetText(Transform owner, string path, string value)
        {
            Text text = owner?.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(CocosUiView owner, string path, bool visible)
        {
            GameObject target = owner.Binding.Find(path);
            if (target != null) target.SetActive(visible);
        }

        private static void SetVisible(Transform owner, string path, bool visible)
        {
            Transform target = owner?.Find(path);
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void SetStars(Transform root, int count)
        {
            if (root == null) return;
            Transform template = root.Find("Star");
            if (template == null) return;
            foreach (Transform child in root.Cast<Transform>().Where(child => child.name.StartsWith("RuntimeStar", StringComparison.Ordinal)).ToArray())
                UnityEngine.Object.Destroy(child.gameObject);
            template.gameObject.SetActive(count > 0);
            for (int index = 1; index < Math.Max(0, count); index++)
            {
                Transform star = UnityEngine.Object.Instantiate(template.gameObject, root, false).transform;
                star.name = $"RuntimeStar{index + 1}";
                RectTransform source = template as RectTransform;
                RectTransform target = star as RectTransform;
                if (source != null && target != null)
                    target.anchoredPosition = source.anchoredPosition + new Vector2(source.rect.width * index, 0f);
            }
        }

        private static Image CreateImage(Transform parent, string name)
        {
            GameObject value = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = value.GetComponent<RectTransform>();
            rect.SetParent(parent, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = value.GetComponent<Image>();
            image.raycastTarget = false;
            return image;
        }

        private static GameObject Require(CocosUiView owner, string path)
            => owner.Binding.Find(path) ?? throw new InvalidOperationException($"HeroRebirth UI node was not found: {path}");

        private readonly struct CandidateRow
        {
            public CandidateRow(HeroRecord first, HeroRecord? second) { First = first; Second = second; }
            public HeroRecord First { get; }
            public HeroRecord? Second { get; }
        }

        private sealed class RewardRow
        {
            public RewardRow(IReadOnlyList<HeroRebirthReward> values) { Items = values; }
            public IReadOnlyList<HeroRebirthReward> Items { get; }
        }
    }
}
