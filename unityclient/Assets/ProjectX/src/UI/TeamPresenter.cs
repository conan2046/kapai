using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class TeamPresenter : IDisposable
    {
        private const string Root = "Layer/Panel/TeamMembers";
        private readonly CocosUiView view;
        private readonly TeamStore store;
        private readonly PlayerStore player;
        private readonly Action create;
        private readonly Action<uint> invite;
        private readonly Action leave;
        private readonly GameObject createButtons;
        private readonly GameObject teamButtons;
        private readonly GameObject invitePopup;
        private readonly InputField inviteInput;

        public TeamPresenter(CocosUiView view, TeamStore store, PlayerStore player,
            Action create, Action<uint> invite, Action leave)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.player = player ?? throw new ArgumentNullException(nameof(player));
            this.create = create ?? throw new ArgumentNullException(nameof(create));
            this.invite = invite ?? throw new ArgumentNullException(nameof(invite));
            this.leave = leave ?? throw new ArgumentNullException(nameof(leave));

            EnsureBackdrop();
            createButtons = Require($"{Root}/BtnList/List1");
            teamButtons = Require($"{Root}/BtnList/List2");
            SetButtonText($"{Root}/BtnList/List1/Btn1", "创建队伍");
            SetButtonText($"{Root}/BtnList/List1/Btn2", "便捷组队");
            SetButtonText($"{Root}/BtnList/List2/Btn1", "邀请队员");
            SetButtonText($"{Root}/BtnList/List2/Btn4", "离开队伍");
            Bind($"{Root}/BtnList/List1/Btn1", create);
            Bind($"{Root}/BtnList/List2/Btn1", () => invitePopup.SetActive(true));
            Bind($"{Root}/BtnList/List2/Btn4", leave);
            invitePopup = CreateInvitePopup();
            inviteInput = invitePopup.GetComponentInChildren<InputField>(true);
            store.Changed += Render;
            player.Changed += Render;
            Render();
        }

        public int RenderedPlayerCount { get; private set; }

        public void Render()
        {
            createButtons.SetActive(!store.HasTeam);
            teamButtons.SetActive(store.HasTeam);
            IReadOnlyList<TeamMemberRecord> members = store.Members;
            RenderedPlayerCount = 0;
            for (int slot = 1; slot <= 5; slot++)
            {
                TeamMemberRecord member = FindForSlot(members, slot);
                if (member == null && !store.HasTeam && slot == 1)
                {
                    member = new TeamMemberRecord
                    {
                        Kind = TeamMemberKind.Player,
                        SourcePosition = 1,
                        Player = player.Summary
                    };
                }
                RenderMember(slot, member);
                if (member?.Kind == TeamMemberKind.Player) RenderedPlayerCount++;
            }
            SetText($"{Root}/SetupList/SetupBg/Target/Name", store.HasTeam ? "普通队伍" : "尚未组队");
            SetText($"{Root}/SetupList/SetupBg/Level/Num", store.HasTeam ? $"成员 {store.PlayerCount}/5" : "点击创建队伍");
            GameObject tips = Find($"{Root}/SetupList/TipsBg");
            if (tips != null) tips.SetActive(!store.HasTeam);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            player.Changed -= Render;
        }

        private static TeamMemberRecord FindForSlot(IReadOnlyList<TeamMemberRecord> members, int slot)
        {
            TeamMemberRecord pet = null;
            for (int index = 0; index < members.Count; index++)
            {
                TeamMemberRecord member = members[index];
                if (member.SourcePosition != slot) continue;
                if (member.Kind == TeamMemberKind.Player) return member;
                pet = member;
            }
            return pet;
        }

        private void RenderMember(int slot, TeamMemberRecord member)
        {
            string path = $"{Root}/MembersList/Btn{slot}";
            GameObject slotRoot = Require(path);
            bool visible = member != null && member.Id != 0;
            SetAllNamed(slotRoot, "Bg1", true);
            SetAllNamed(slotRoot, "Bg2", false);
            SetAllNamedText(slotRoot, "RoleName", visible, visible ? member.Name : string.Empty);
            SetAllNamedText(slotRoot, "LeveNum", visible, visible ? $"{member.Level}级" : string.Empty);
            SetAllNamedText(slotRoot, "StationNum", visible, visible ? $"{slot}号位" : string.Empty);
            SetAllNamed(slotRoot, "TeamLeader", visible && member.IsLeader);
            SetAllNamed(slotRoot, "LeaveImage", visible && member.IsTemporarilyAway);
            SetAllNamed(slotRoot, "PetStar", visible && member.Kind == TeamMemberKind.Pet);
            SetAllNamed(slotRoot, "CareerImage", false);
            SetAllNamed(slotRoot, "Node", false);
        }

        private static void SetAllNamed(GameObject root, string name, bool visible)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) child.gameObject.SetActive(visible);
        }

        private static void SetAllNamedText(GameObject root, string name, bool visible, string value)
        {
            foreach (Text text in root.GetComponentsInChildren<Text>(true))
            {
                if (text.name != name) continue;
                text.text = value ?? string.Empty;
                text.gameObject.SetActive(visible);
            }
        }

        private GameObject CreateInvitePopup()
        {
            var popup = new GameObject("RuntimeTeamInvite", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            popup.transform.SetParent(view.GameObject.transform, false);
            RectTransform rect = popup.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(520f, 220f);
            popup.GetComponent<Image>().color = new Color32(246, 226, 190, 255);

            GameObject inputObject = CreateTextObject("RoleId", popup.transform, new Vector2(0f, 25f), new Vector2(380f, 58f));
            InputField input = inputObject.AddComponent<InputField>();
            input.textComponent = inputObject.GetComponent<Text>();
            input.contentType = InputField.ContentType.IntegerNumber;
            input.placeholder = null;
            inputObject.GetComponent<Text>().text = string.Empty;

            GameObject buttonObject = CreateTextObject("Invite", popup.transform, new Vector2(0f, -60f), new Vector2(180f, 58f));
            buttonObject.GetComponent<Text>().text = "发送邀请";
            Button button = buttonObject.AddComponent<Button>();
            button.targetGraphic = buttonObject.GetComponent<Text>();
            button.onClick.AddListener(() =>
            {
                if (uint.TryParse(input.text, out uint id) && id != 0) invite(id);
                popup.SetActive(false);
            });
            popup.SetActive(false);
            return popup;
        }

        private static GameObject CreateTextObject(string name, Transform parent, Vector2 position, Vector2 size)
        {
            var target = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            target.transform.SetParent(parent, false);
            RectTransform rect = target.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;
            Text text = target.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 26;
            text.color = new Color32(80, 48, 36, 255);
            text.alignment = TextAnchor.MiddleCenter;
            return target;
        }

        private void EnsureBackdrop()
        {
            var backdrop = new GameObject("RuntimeTeamBackdrop", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            backdrop.transform.SetParent(view.GameObject.transform, false);
            backdrop.transform.SetAsFirstSibling();
            RectTransform rect = backdrop.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(1334f, 750f);
            backdrop.GetComponent<Image>().color = new Color32(25, 18, 16, 255);
        }

        private void Bind(string path, Action callback)
        {
            GameObject target = Require(path);
            Button button = target.GetComponent<Button>() ?? target.AddComponent<Button>();
            button.targetGraphic = target.GetComponent<Graphic>() ?? target.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => callback());
        }

        private void SetButtonText(string path, string value)
        {
            GameObject button = Require(path);
            Text text = button.GetComponentInChildren<Text>(true);
            if (text == null) return;
            RectTransform buttonRect = button.GetComponent<RectTransform>();
            if (path.Contains("/List1/") && buttonRect != null && buttonRect.rect.width < 190f)
                buttonRect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, 190f);
            RectTransform textRect = text.rectTransform;
            if (textRect.rect.width < 190f)
                textRect.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, 190f);
            text.horizontalOverflow = HorizontalWrapMode.Overflow;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.text = value;
        }

        private GameObject Find(string path) => view.Binding.Find(path);
        private GameObject Require(string path) => Find(path) ?? throw new InvalidOperationException($"Team UI node was not found: {path}");
        private void SetText(string path, string value) { Text text = Find(path)?.GetComponent<Text>(); if (text != null) text.text = value ?? string.Empty; }
        private void SetVisible(string path, bool visible) { GameObject target = Find(path); if (target != null) target.SetActive(visible); }
    }
}
