using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GuildPresenter : IDisposable
    {
        private const string ListRoot = "Layer/Panel/ApplyGuild";
        private const string InfoRoot = "Layer/Bangpai/GuildNews/BasicNews";
        private const string MemberRoot = "Layer/Panel/Member";
        private readonly GuildStore store;
        private readonly PlayerStore player;
        private readonly CocosUiView hostView;
        private readonly CocosUiView infoView;
        private readonly CocosUiView memberView;
        private readonly CocosUiView createView;
        private readonly Action<string> create;
        private readonly Action requestMembers;
        private readonly Action leave;
        private readonly VirtualList<GuildRecord> guildList;
        private readonly VirtualList<GuildMemberRecord> memberList;
        private bool showingMembers;
        private bool showingCreate;

        public GuildPresenter(CocosUiView hostView, CocosUiView infoView, CocosUiView memberView,
            CocosUiView createView, GuildStore store, PlayerStore player, Action<string> create,
            Action requestMembers, Action leave)
        {
            this.hostView = hostView ?? throw new ArgumentNullException(nameof(hostView));
            this.infoView = infoView ?? throw new ArgumentNullException(nameof(infoView));
            this.memberView = memberView ?? throw new ArgumentNullException(nameof(memberView));
            this.createView = createView ?? throw new ArgumentNullException(nameof(createView));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.create = create ?? throw new ArgumentNullException(nameof(create));
            this.requestMembers = requestMembers ?? throw new ArgumentNullException(nameof(requestMembers));
            this.leave = leave ?? throw new ArgumentNullException(nameof(leave));

            ReparentOverlay(infoView);
            ReparentOverlay(memberView);
            ReparentOverlay(createView);
            guildList = new VirtualList<GuildRecord>(Require(hostView, $"{ListRoot}/TheCharts/List"),
                Require(hostView, $"{ListRoot}/TheCharts/Name"), 72f, BindGuildRow);
            memberList = new VirtualList<GuildMemberRecord>(Require(memberView, $"{MemberRoot}/Bg/List"),
                Require(memberView, $"{MemberRoot}/Bg/Name"), 72f, BindMemberRow);

            Bind(hostView, $"{ListRoot}/Btn2", ShowCreate);
            SetButtonLabel(hostView, $"{ListRoot}/Btn1", "申请加入");
            SetButtonLabel(hostView, $"{ListRoot}/Btn2", "创建帮派");
            SetButtonLabel(hostView, $"{ListRoot}/Btn3", "进入领地");
            Bind(createView, "Layer/FoundGuild/CancelBtn", () => { showingCreate = false; Render(); });
            Bind(createView, "Layer/FoundGuild/EnterBtn", SubmitCreate);
            Bind(infoView, "Layer/Bangpai/BtnList/Btn3", () => ShowMembers());
            SetButtonLabel(infoView, "Layer/Bangpai/BtnList/Btn3", "成 员");
            Bind(memberView, $"{MemberRoot}/BtnList/Btn4", leave);
            SetButtonLabel(memberView, $"{MemberRoot}/BtnList/Btn1", "申请列表");
            SetButtonLabel(memberView, $"{MemberRoot}/BtnList/Btn2", "邀请入帮");
            SetButtonLabel(memberView, $"{MemberRoot}/BtnList/Btn3", "职位奖励");
            SetButtonLabel(memberView, $"{MemberRoot}/BtnList/Btn4", "脱离帮派");
            store.Changed += Render;
            player.Changed += Render;
            Render();
        }

        public int RenderedGuildCount => guildList.Count;
        public int RenderedMemberCount => memberList.Count;
        public bool ShowingMembers => showingMembers && store.HasGuild;

        public void Render()
        {
            if (!store.HasGuild) showingMembers = false;
            GameObject listPanel = Require(hostView, ListRoot);
            listPanel.SetActive(!store.HasGuild && !showingCreate);
            infoView.GameObject.SetActive(store.HasGuild && !showingMembers && !showingCreate);
            memberView.GameObject.SetActive(store.HasGuild && showingMembers && !showingCreate);
            createView.GameObject.SetActive(showingCreate);
            guildList.SetItems(store.Items);
            memberList.SetItems(store.Members);

            GuildInfo info = store.Info;
            SetText(infoView, $"{InfoRoot}/TitleBg/TitleName", info == null ? "帮派" : $"{info.Name}  Lv.{info.Level}");
            SetText(infoView, $"{InfoRoot}/GuildImageBg/Level", info == null ? "Lv.0" : $"Lv.{info.Level}");
            SetText(infoView, $"{InfoRoot}/Information1/Name/Text", info == null ? "--" : info.Id.ToString());
            SetText(infoView, $"{InfoRoot}/Information2/Name/Text", info == null ? "0" : info.MemberCount.ToString());
            SetText(infoView, $"{InfoRoot}/Information3/Name/Text", CurrentRankName());
            SetText(infoView, $"{InfoRoot}/NoticeBg/TitleBg/TitleName", "帮派公告");
            SetInputText(infoView, $"{InfoRoot}/TextField", info?.Notice ?? string.Empty);
            SetText(hostView, $"{ListRoot}/GuildNotice/Text", store.Items.Count == 0 ? "暂无可加入帮派" : "选择帮派查看公告");
        }

        public void Dispose()
        {
            store.Changed -= Render;
            player.Changed -= Render;
            guildList.Dispose();
            memberList.Dispose();
        }

        public void ShowMembers(bool refresh = true)
        {
            if (!store.HasGuild) return;
            showingMembers = true;
            showingCreate = false;
            Render();
            if (refresh) requestMembers();
        }

        public void ShowInfo()
        {
            showingMembers = false;
            showingCreate = false;
            Render();
        }

        private void ShowCreate()
        {
            showingCreate = true;
            Render();
        }

        private void SubmitCreate()
        {
            InputField input = Find(createView, "Layer/FoundGuild/SearchBg/TextField")?.GetComponent<InputField>();
            string name = input?.text?.Trim();
            if (string.IsNullOrEmpty(name)) return;
            showingCreate = false;
            create(name);
        }

        private void BindGuildRow(RectTransform row, GuildRecord item, int index)
        {
            SetNamedText(row, "PlaceNum", item.Level.ToString());
            SetNamedText(row, "PlaceName", item.Name);
            SetNamedText(row, "PeopleNum", $"{item.MemberCount}/{item.MaximumMembers}");
            SetNamedText(row, "PlantNum", item.PlantedCount.ToString());
            SetNamedText(row, "LeaderName", item.LeaderName);
            SetNamedText(row, "AddLv", item.AutoAcceptLevel == 0 ? "审核" : item.AutoAcceptLevel.ToString());
            SetNamedActive(row, "AppliedImage", item.HasApplied);
        }

        private void BindMemberRow(RectTransform row, GuildMemberRecord item, int index)
        {
            PlayerSummary summary = item.Player;
            SetNamedText(row, "RoleName", summary?.Name ?? string.Empty);
            SetNamedText(row, "PositionName", RankName(item.Rank));
            SetNamedText(row, "LevelNum", (summary?.Level ?? 0).ToString());
            SetNamedText(row, "PowerNum", (summary?.Power ?? 0).ToString());
            SetNamedText(row, "ContributionNum", item.Contribution.ToString());
            SetNamedText(row, "Huoyue", item.DailyActivity.ToString());
            SetNamedText(row, "OnlineTime", FormatOffline(item.LastOfflineSeconds));
            SetNamedText(row, "Text_82", (summary?.Head ?? 0).ToString());
        }

        private string CurrentRankName()
        {
            uint roleId = player.RoleId;
            foreach (GuildMemberRecord item in store.Members)
                if (item.Player?.Id == roleId) return RankName(item.Rank);
            return store.HasGuild ? "成员" : "--";
        }

        private static string RankName(byte rank)
        {
            switch (rank)
            {
                case 1: return "帮主";
                case 2: return "长老";
                case 3: return "护法";
                case 4: return "帮众";
                default: return "成员";
            }
        }

        private static string FormatOffline(uint seconds)
        {
            if (seconds == 0) return "在线";
            if (seconds < 3600) return $"{Math.Max(1, seconds / 60)}分钟前";
            if (seconds < 86400) return $"{seconds / 3600}小时前";
            return $"{seconds / 86400}天前";
        }

        private void ReparentOverlay(CocosUiView view)
        {
            view.GameObject.transform.SetParent(hostView.GameObject.transform, false);
            view.GameObject.SetActive(false);
        }

        private static void Bind(CocosUiView view, string path, Action callback)
        {
            GameObject target = Require(view, path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
        }

        private static void SetInputText(CocosUiView view, string path, string value)
        {
            GameObject target = Find(view, path);
            InputField input = target?.GetComponent<InputField>();
            if (input != null) input.text = value ?? string.Empty;
            else
            {
                Text text = target?.GetComponent<Text>();
                if (text != null) text.text = value ?? string.Empty;
            }
        }

        private static void SetButtonLabel(CocosUiView view, string path, string value)
        {
            Text text = Find(view, path)?.GetComponentInChildren<Text>(true);
            if (text == null) return;
            text.gameObject.SetActive(true);
            text.text = value;
            text.color = new Color32(92, 48, 38, 255);
            text.fontSize = 22;
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.transform.SetAsLastSibling();
        }

        private static void SetText(CocosUiView view, string path, string value)
        {
            Text text = Find(view, path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
            {
                if (text.name != name) continue;
                text.text = value ?? string.Empty;
                if (name == "PositionName")
                {
                    text.fontSize = 18;
                    text.rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, 80f);
                    text.horizontalOverflow = HorizontalWrapMode.Overflow;
                }
            }
        }

        private static void SetNamedActive(Transform root, string name, bool active)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) child.gameObject.SetActive(active);
        }

        private static GameObject Find(CocosUiView view, string path) => view.Binding.Find(path);
        private static GameObject Require(CocosUiView view, string path) => Find(view, path)
            ?? throw new InvalidOperationException($"Guild UI node was not found: {path}");
    }
}
