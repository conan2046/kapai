using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // Templates, dimensions, layout groups, fonts and scroll masks are authored in DongFuLibrary.
    public sealed class LibraryScreen : MonoBehaviour
    {
        [SerializeField] private ScrollRect realmScroll;
        [SerializeField] private GameObject realmTemplate;
        [SerializeField] private RectTransform bookTemplate;
        [SerializeField] private RectTransform rewardTemplate;
        [SerializeField] private ScrollRect rewardScroll;
        [SerializeField] private Text empty;
        [SerializeField] private Button attributes;
        [SerializeField] private GroupedTemplateList groupedList;
        private LibraryCatalogData catalog;
        private LibraryEnvelope state;
        private Func<string, Sprite> sprite;
        private readonly Dictionary<int, GameObject> realmGroups = new Dictionary<int, GameObject>();
        private readonly Dictionary<int, Button> setButtons = new Dictionary<int, Button>();
        private readonly List<GameObject> bookRows = new List<GameObject>();
        private readonly List<GameObject> rewardRows = new List<GameObject>();
        private int selectedRealm => groupedList == null ? 0 : groupedList.SelectedGroup;
        private int selectedSet, renderedSet;
        private bool pending, bound;
        public event Action BecameVisible;
        public event Action CloseRequested;
        public event Action<int> ActivationRequested;
        public event Action<int> BookRequested;
        public event Action AttributesRequested;
        public int SelectedRealm => selectedRealm;
        public int SelectedSet => selectedSet;
        public int RewardCount => rewardRows.Count;
        private void OnEnable() => BecameVisible?.Invoke();
        public void Bind(LibraryCatalogData data, Func<string, Sprite> loadSprite)
        {
            if (bound) return;
            if (groupedList == null) throw new InvalidOperationException("藏书阁缺少公共分组列表绑定。");
            catalog = data; sprite = loadSprite; bound = true;
            realmTemplate.SetActive(false); bookTemplate.gameObject.SetActive(false); rewardTemplate.gameObject.SetActive(false);
            foreach (var realm in catalog.Realms)
            {
                int realmId = realm.Id;
                var group = Instantiate(realmTemplate, realmTemplate.transform.parent, false);
                group.name = "Realm_" + realmId;
                group.transform.Find("Name").GetComponent<Text>().text = realm.Name;
                groupedList.RegisterGroup(realmId, group, RealmSelectionChanged);
                var content = group.transform.Find("VirtualContent");
                var rowTemplate = content.Find("VirtualRow_0"); rowTemplate.gameObject.SetActive(false);
                foreach (var set in catalog.InRealm(realmId))
                {
                    int setId = set.Id;
                    var row = Instantiate(rowTemplate.gameObject, content, false); row.name = "Set_" + setId;
                    row.transform.Find("zhangjie").GetComponent<Text>().text = set.Name;
                    var button = row.GetComponent<Button>(); button.onClick.RemoveAllListeners();
                    button.onClick.AddListener(() => SelectSet(setId));
                    row.SetActive(true); setButtons[setId] = button;
                }
                group.SetActive(true); realmGroups[realmId] = group;
            }
            attributes.onClick.AddListener(() => AttributesRequested?.Invoke());
        }
        public void ResetSelection() { groupedList.ResetSelection(); selectedSet = 0; }
        public void Back() => CloseRequested?.Invoke();
        public void Apply(LibraryEnvelope value)
        {
            state = value; pending = false;
            int initialRealm = catalog.Realms.Any(r => r.Id == value.Realm) ? value.Realm : catalog.Realms.FirstOrDefault()?.Id ?? 0;
            bool fresh = groupedList.InitializeSelection(initialRealm);
            if (fresh) selectedSet = catalog.InRealm(selectedRealm).FirstOrDefault()?.Id ?? 0;
            Refresh();
            if (fresh) StartCoroutine(ScrollToRealm());
        }
        public void SetPending(bool value) { pending = value; Refresh(); }
        public void Loading()
        {
            pending = true; empty.gameObject.SetActive(true); empty.text = "正在同步藏书信息…";
            groupedList.SetInteractable(false);
            foreach (var row in rewardRows) row.transform.Find("Activate").GetComponent<Button>().interactable = false;
        }
        public void Fail(string message) { pending = true; Refresh(); empty.gameObject.SetActive(true); empty.text = "藏书信息同步失败"; }
        public void SelectRealm(int id)
        {
            if (pending) return;
            groupedList.ToggleGroup(id); RealmSelectionChanged(selectedRealm);
        }
        private void RealmSelectionChanged(int id)
        {
            selectedSet = catalog.InRealm(id).FirstOrDefault()?.Id ?? 0; Refresh();
        }
        public void SelectSet(int id)
        {
            if (pending || !catalog.Sets.TryGetValue(id, out var set)) return;
            groupedList.SelectGroup(set.Realm); selectedSet = id; Refresh();
        }
        private void Refresh()
        {
            if (!bound) return;
            groupedList.Refresh(); groupedList.SetInteractable(!pending);
            foreach (var pair in realmGroups)
            {
                var realm = catalog.Realms.First(r => r.Id == pair.Key);
                pair.Value.transform.Find("Name").GetComponent<Text>().text = realm.Name + (state != null && realm.Id > state.Realm ? "·未达" : "");
            }
            foreach (var pair in setButtons)
            {
                var text = pair.Value.transform.Find("zhangjie").GetComponent<Text>();
                var set = catalog.Sets[pair.Key]; int active = state == null ? 0 : set.Books.Count(state.Activated);
                text.text = set.Name + (active > 0 ? " " + active + "/" + set.Books.Length : "");
                text.color = pair.Key == selectedSet ? new Color(0.65f, 0.25f, 0.13f) : new Color(0.26f, 0.16f, 0.12f);
                pair.Value.interactable = !pending;
            }
            var setExists = state != null && state.Configured && catalog.Sets.ContainsKey(selectedSet);
            empty.gameObject.SetActive(!setExists);
            if (!setExists) empty.text = state == null ? "正在同步藏书信息…" : selectedRealm == 0 ? "请选择藏书套装" : state.Configured ? "该境界暂无藏书套装" : "暂无藏书信息";
            if (!setExists) { Clear(bookRows); Clear(rewardRows); renderedSet = 0; return; }
            bool rebuild = renderedSet != selectedSet;
            if (rebuild) { Clear(bookRows); Clear(rewardRows); renderedSet = selectedSet; }
            var selected = catalog.Sets[selectedSet];
            int bookIndex = 0;
            foreach (int id in selected.Books)
            {
                var book = catalog.Books[id];
                var row = rebuild ? Instantiate(bookTemplate.gameObject, bookTemplate.parent, false) : bookRows[bookIndex];
                if (rebuild) { row.name = "Book_" + id; bookRows.Add(row); }
                var icon = row.transform.Find("Icon").GetComponent<Image>(); icon.sprite = sprite(book.Icon);
                bool obtained = state.Obtained.Contains(id);
                icon.color = obtained ? Color.white : new Color(0.45f, 0.45f, 0.45f, 1f);
                row.transform.Find("Not")?.gameObject.SetActive(!obtained);
                var title = row.transform.Find("RewardsTitle").GetComponent<Text>();
                title.text = book.Name.Contains("·") ? book.Name.Substring(book.Name.IndexOf('·') + 1) : book.Name;
                title.color = state.Activated(id) ? new Color(0.18f, 0.53f, 0.22f) : Color.white;
                var button = row.GetComponent<Button>(); button.interactable = !pending;
                button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => BookRequested?.Invoke(id));
                row.SetActive(true); bookIndex++;
            }
            int rewardIndex = 0;
            foreach (var reward in catalog.InSet(selectedSet))
            {
                int id = reward.Id;
                var row = rebuild ? Instantiate(rewardTemplate.gameObject, rewardTemplate.parent, false) : rewardRows[rewardIndex];
                if (rebuild) { row.name = "Reward_" + id; rewardRows.Add(row); }
                var condition = row.transform.Find("Condition").GetComponent<Text>();
                condition.text = reward.Kind == "book" ? "第" + (Array.IndexOf(selected.Books, reward.Required[0]) + 1) + "本:" : reward.Kind == "count" ? reward.Count + "本奖励:" : reward.Kind == "complete" ? "整套奖励:" : "组合奖励:";
                row.transform.Find("Attributes").GetComponent<Text>().text = LibraryCatalogData.AttributeText(reward.Attributes);
                bool claimed = state.Rewards.Contains(id);
                row.transform.Find("Activated").gameObject.SetActive(claimed);
                var button = row.transform.Find("Activate").GetComponent<Button>(); button.gameObject.SetActive(!claimed);
                button.interactable = !pending && catalog.Eligible(state, reward);
                button.onClick.RemoveAllListeners(); button.onClick.AddListener(() => ActivationRequested?.Invoke(id));
                row.SetActive(true); rewardIndex++;
            }
            if (rebuild) rewardScroll.verticalNormalizedPosition = 1f;
        }
        private static void Clear(List<GameObject> rows) { foreach (var row in rows) { row.SetActive(false); Destroy(row); } rows.Clear(); }
        private IEnumerator ScrollToRealm()
        {
            yield return null; Canvas.ForceUpdateCanvases();
            if (!realmGroups.TryGetValue(selectedRealm, out var group)) yield break;
            float excess = realmScroll.content.rect.height - realmScroll.viewport.rect.height;
            if (excess <= 0f) yield break;
            var bounds = RectTransformUtility.CalculateRelativeRectTransformBounds(realmScroll.content, group.transform.Find("Name"));
            realmScroll.verticalNormalizedPosition = 1f - Mathf.Clamp01((realmScroll.content.rect.yMax - bounds.max.y) / excess);
        }
    }
}
