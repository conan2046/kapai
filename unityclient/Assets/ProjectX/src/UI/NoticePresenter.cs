using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class NoticePresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly VirtualList<NoticeRecord> list;
        private readonly Text contentText;
        private IReadOnlyList<NoticeRecord> notices = Array.Empty<NoticeRecord>();
        private int selectedIndex;

        public NoticePresenter(CocosUiView view)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            GameObject viewport = Require("Layer/Panel/BtnList/ListBg/List");
            GameObject template = Require("Layer/Panel/BtnList/ListBg/Btn");
            list = new VirtualList<NoticeRecord>(viewport, template, 82f, BindRow);
            Require("Layer/Panel/NoticeBg_2").SetActive(false);
            Require("Layer/Panel/Btn").SetActive(false);
            GameObject contentNode = Require("Layer/Panel/NoticeBg_1/Text");
            contentText = contentNode.GetComponent<Text>() ?? contentNode.AddComponent<Text>();
            contentText.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            contentText.fontSize = 26;
            contentText.color = new Color(0.32f, 0.16f, 0.09f, 1f);
            contentText.alignment = TextAnchor.UpperLeft;
            contentText.horizontalOverflow = HorizontalWrapMode.Wrap;
            contentText.verticalOverflow = VerticalWrapMode.Overflow;
            contentText.raycastTarget = false;
            RectTransform contentRect = contentText.rectTransform;
            contentRect.anchorMin = new Vector2(0.04f, 0.04f);
            contentRect.anchorMax = new Vector2(0.96f, 0.96f);
            contentRect.offsetMin = contentRect.offsetMax = Vector2.zero;
        }

        public int Count => list.Count;
        public int SelectedIndex => selectedIndex;

        public void Show(IReadOnlyList<NoticeRecord> values)
        {
            notices = values ?? Array.Empty<NoticeRecord>();
            selectedIndex = 0;
            list.SetItems(notices);
            RenderSelected();
            view.SetVisible(true);
        }

        public void Dispose() => list.Dispose();

        private void BindRow(RectTransform row, NoticeRecord value, int index)
        {
            SetNamedText(row, "Name", value.Title);
            SetNamedText(row, "Text", value.Title);
            foreach (Text text in row.GetComponentsInChildren<Text>(true))
            {
                if (text.name != "Name" && text.name != "Text") continue;
                text.text = value.Title ?? string.Empty;
                text.color = new Color(0.32f, 0.16f, 0.09f, 1f);
                text.fontSize = 20;
                text.alignment = TextAnchor.MiddleCenter;
            }
            Transform chosen = FindNamed(row, "ChooseBg");
            if (chosen != null) chosen.gameObject.SetActive(index == selectedIndex);
            Button button = row.GetComponent<Button>() ?? row.gameObject.AddComponent<Button>();
            button.targetGraphic = row.GetComponent<Graphic>() ?? row.GetComponentInChildren<Graphic>(true);
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => Select(index));
        }

        private void Select(int index)
        {
            selectedIndex = Mathf.Clamp(index, 0, Math.Max(0, notices.Count - 1));
            list.SetItems(notices);
            RenderSelected();
        }

        private void RenderSelected()
        {
            NoticeRecord selected = notices.Count == 0 ? null : notices[selectedIndex];
            contentText.text = selected?.Text ?? "当前没有有效游戏公告";
        }

        private GameObject Require(string path)
        {
            return view.Binding.Find(path) ?? throw new InvalidOperationException("NoticeLayer node was not found: " + path);
        }

        private static Transform FindNamed(Transform root, string name)
        {
            foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) return child;
            return null;
        }

        private static void SetNamedText(Transform root, string name, string value)
        {
            Text text = FindNamed(root, name)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }
    }
}
