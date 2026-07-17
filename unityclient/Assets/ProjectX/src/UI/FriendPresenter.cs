using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FriendPresenter : IDisposable
    {
        private const string Root = "Layer/Friend/FriendList";
        private readonly CocosUiView view;
        private readonly FriendStore store;
        private readonly Action requestFriends;
        private readonly Action requestApplications;
        private readonly Action<uint> apply;
        private readonly Action<uint, bool> deal;
        private readonly Action<uint> delete;
        private readonly VirtualList<FriendRecord> list;
        private readonly GameObject empty;
        private readonly GameObject content;
        private readonly GameObject popup;
        private readonly InputField roleIdInput;
        private readonly Text runtimeEmpty;
        private readonly GameObject navigation;
        private readonly GameObject emptyAddButton;
        private bool showApplications;

        public FriendPresenter(CocosUiView view, FriendStore store, Action requestFriends,
            Action requestApplications, Action<uint> apply, Action<uint, bool> deal, Action<uint> delete)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.requestFriends = requestFriends ?? throw new ArgumentNullException(nameof(requestFriends));
            this.requestApplications = requestApplications ?? throw new ArgumentNullException(nameof(requestApplications));
            this.apply = apply ?? throw new ArgumentNullException(nameof(apply));
            this.deal = deal ?? throw new ArgumentNullException(nameof(deal));
            this.delete = delete ?? throw new ArgumentNullException(nameof(delete));

            EnsureBackdrop();

            empty = Require("Layer/None");
            content = Require($"{Root}/Friend1");
            GameObject viewport = Require($"{Root}/Friend1/Bg/ListView");
            GameObject template = Require($"{Root}/Item");
            runtimeEmpty = CreateEmptyText(viewport.transform);
            float itemHeight = Math.Max(108f, template.GetComponent<RectTransform>()?.rect.height ?? 108f);
            list = new VirtualList<FriendRecord>(viewport, template, itemHeight, BindRow);

            popup = Require($"{Root}/Popup");
            roleIdInput = EnsureInputField(Require($"{Root}/Popup/TextBg/TextField"));
            Bind($"{Root}/Popup/bg/Btn_close", () => popup.SetActive(false));
            Bind($"{Root}/Popup/Btn", SubmitApply);

            navigation = Require($"{Root}/Friend1/TuijianBtn");
            navigation.transform.SetParent(Require(Root).transform, true);
            navigation.transform.SetAsLastSibling();
            navigation.SetActive(true);
            SetButtonText($"{Root}/Friend1/TuijianBtn/Btn_1", "好友列表");
            SetButtonText($"{Root}/Friend1/TuijianBtn/Btn_2", "申请列表");
            SetButtonText($"{Root}/Friend1/TuijianBtn/Btn_3", "添加好友");
            Bind($"{Root}/Friend1/TuijianBtn/Btn_1", () => ShowFriends());
            Bind($"{Root}/Friend1/TuijianBtn/Btn_2", () => ShowApplications());
            Bind($"{Root}/Friend1/TuijianBtn/Btn_3", () => popup.SetActive(true));
            emptyAddButton = CreateEmptyAddButton(navigation.transform.Find("Btn_3")?.gameObject, viewport.transform);
            Button emptyAdd = emptyAddButton.GetComponent<Button>() ?? emptyAddButton.AddComponent<Button>();
            emptyAdd.onClick.RemoveAllListeners();
            emptyAdd.onClick.AddListener(() => popup.SetActive(true));
            Require($"{Root}/Friend1/ShenqingBtn").SetActive(false);
            Require($"{Root}/Friend1/RewardsNum").SetActive(false);
            Require($"{Root}/Friend1/Btn_1").SetActive(false);
            Require($"{Root}/Friend1/Btn_3").SetActive(false);
            popup.SetActive(false);
            empty.SetActive(false);
            store.Changed += Render;
            Render();
        }

        public int RenderedCount => showApplications ? store.ApplicationCount : store.FriendCount;
        public bool ShowingApplications => showApplications;

        public void ShowFriends(bool refresh = true)
        {
            showApplications = false;
            Render();
            if (refresh) requestFriends();
        }

        public void ShowApplications(bool refresh = true)
        {
            showApplications = true;
            Render();
            if (refresh) requestApplications();
        }

        public void Render()
        {
            IReadOnlyList<FriendRecord> items = showApplications ? store.Applications : store.Friends;
            empty.SetActive(false);
            content.SetActive(true);
            runtimeEmpty.gameObject.SetActive(items.Count == 0);
            emptyAddButton.SetActive(items.Count == 0);
            runtimeEmpty.text = showApplications ? "暂无好友申请" : "暂无好友，点击添加好友结识仙友";
            navigation.SetActive(true);
            navigation.transform.SetAsLastSibling();
            Text count = Find($"{Root}/Friend1/FriendsNum/Text")?.GetComponent<Text>();
            if (count != null)
                count.text = showApplications
                    ? $"申请 {store.ApplicationCount}/{store.MaxApplications}"
                    : $"好友 {store.FriendCount}/{store.MaxFriends}";
            list.SetItems(items);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            list.Dispose();
        }

        private void BindRow(RectTransform row, FriendRecord item, int index)
        {
            SetText(row, "Icon_1/Name", item.Name);
            SetText(row, "Icon_1/LevelNum", $"等级 {item.Level}");
            SetText(row, "Icon_1/Name/Time", FormatOffline(item.OfflineSeconds));
            SetText(row, "Power/Value", item.Power.ToString());
            SetVisible(row, "Power/Value/Wan", false);
            SetVisible(row, "Group", item.GuildId != 0);
            SetText(row, "Group/Name", item.GuildName);
            SetVisible(row, "Btn_Give", false);
            SetVisible(row, "Btn_Get", false);
            SetVisible(row, "Btn", false);
            SetVisible(row, "Btn_Jiechu", !showApplications);
            SetVisible(row, "BtnGroup", showApplications);
            if (showApplications)
            {
                BindRowButton(row, "BtnGroup/Btn_1", () => deal(item.Id, false));
                BindRowButton(row, "BtnGroup/Btn_2", () => deal(item.Id, true));
                SetText(row, "BtnGroup/Btn_1/Text", "拒绝");
                SetText(row, "BtnGroup/Btn_2/Text", "同意");
                SetVisible(row, "BtnGroup/Jujue", false);
                SetVisible(row, "BtnGroup/Tongyi", false);
            }
            else
            {
                BindRowButton(row, "Btn_Jiechu", () => delete(item.Id));
                SetText(row, "Btn_Jiechu/Text", "删除");
            }
            row.gameObject.name = $"Friend_{(showApplications ? "Apply" : "List")}_{item.Id}_{index}";
        }

        private void SubmitApply()
        {
            if (!uint.TryParse(roleIdInput?.text, out uint id) || id == 0) return;
            popup.SetActive(false);
            apply(id);
        }

        private InputField EnsureInputField(GameObject target)
        {
            InputField input = target.GetComponent<InputField>() ?? target.GetComponentInParent<InputField>();
            if (input != null) return input;
            input = target.AddComponent<InputField>();
            Text text = target.GetComponent<Text>();
            if (text == null) text = target.AddComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 22;
            text.color = new Color32(86, 50, 42, 255);
            input.textComponent = text;
            input.contentType = InputField.ContentType.IntegerNumber;
            input.placeholder = null;
            return input;
        }

        private static Text CreateEmptyText(Transform parent)
        {
            var target = new GameObject("RuntimeFriendEmpty", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            target.transform.SetParent(parent, false);
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(700f, 100f);
            Text text = target.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 28;
            text.color = new Color32(112, 69, 54, 255);
            text.alignment = TextAnchor.MiddleCenter;
            text.raycastTarget = false;
            return text;
        }

        private static GameObject CreateEmptyAddButton(GameObject source, Transform parent)
        {
            if (source == null) throw new InvalidOperationException("Friend add button template was not found.");
            GameObject target = UnityEngine.Object.Instantiate(source, parent, false);
            target.name = "RuntimeFriendEmptyAdd";
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = new Vector2(0f, -85f);
            rect.sizeDelta = new Vector2(190f, 62f);
            target.SetActive(false);
            return target;
        }

        private void EnsureBackdrop()
        {
            Transform parent = view.GameObject.transform;
            Transform existing = parent.Find("RuntimeFriendBackdrop");
            if (existing != null) return;
            var blocker = new GameObject("RuntimeFriendBackdrop", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            blocker.transform.SetParent(parent, false);
            blocker.transform.SetAsFirstSibling();
            RectTransform rect = blocker.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = Vector2.zero;
            rect.sizeDelta = new Vector2(1334f, 750f);
            Image image = blocker.GetComponent<Image>();
            image.color = Color.black;
            image.raycastTarget = true;
        }

        private void Bind(string path, Action callback)
        {
            GameObject target = Require(path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
        }

        private static void BindRowButton(Transform root, string path, Action callback)
        {
            Transform target = root.Find(path);
            if (target == null) return;
            Button button = target.GetComponent<Button>() ?? target.gameObject.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
        }

        private void SetButtonText(string path, string value)
        {
            GameObject target = Require(path);
            Text text = target.GetComponentInChildren<Text>(true);
            if (text != null) text.text = value;
        }

        private GameObject Find(string path) => view.Binding.Find(path);
        private GameObject Require(string path) => Find(path) ?? throw new InvalidOperationException($"Friend UI node was not found: {path}");
        private static void SetText(Transform root, string path, string value) { Text text = root.Find(path)?.GetComponent<Text>(); if (text != null) text.text = value ?? string.Empty; }
        private static void SetVisible(Transform root, string path, bool visible) { Transform target = root.Find(path); if (target != null) target.gameObject.SetActive(visible); }
        private static string FormatOffline(uint seconds)
        {
            if (seconds == 0) return "在线";
            if (seconds < 3600) return $"{Math.Max(1, seconds / 60)}分钟前";
            if (seconds < 86400) return $"{seconds / 3600}小时前";
            return $"{seconds / 86400}天前";
        }
    }
}
