using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class ArenaPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly ArenaStore store;
        private readonly Text rank;
        private readonly Text remaining;
        private readonly Text score;

        public ArenaPresenter(CocosUiView view, ArenaStore store, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            Normalize(view.GameObject.transform);
            Transform root = view.GameObject.transform;
            SetVisible(root.Find("Bg1"), true);
            SetVisible(root.Find("ScrollView"), false);
            SetVisible(root.Find("ImageBg"), true);
            SetVisible(root.Find("ImageBg_1"), true);
            SetVisible(root.Find("ImageBg_2"), true);
            SetVisible(root.Find("Panel"), true);
            SetVisible(root.Find("Zhanbao"), false);
            SetVisible(root.Find("Ranking"), false);
            SetVisible(root.Find("Rewards"), false);
            SetVisible(root.Find("Saodang"), false);

            rank = RequireText(root, "Panel/JingjiBg/Tips/MyRanking/Text");
            remaining = RequireText(root, "Panel/JingjiBg/TimesBg/Icon/Num");
            score = RequireText(root, "Panel/JingjiBg/ShengwangBg/Icon/Num");
            BindClose(root, "Panel/Title/CloseBtn", close);
            DisableActions(root);
            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && rank != null;
        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            if (!store.HasAuthoritativeResponse)
            {
                rank.text = remaining.text = score.text = "--";
                return;
            }
            rank.text = store.Rank.ToString();
            remaining.text = store.Remaining.ToString();
            score.text = store.Score.ToString();
            Transform root = view.GameObject.transform;
            SetText(root, "ImageBg_2/RankingBg/Num", store.Rank.ToString());
            for (int index = 1; index <= 3; index++)
            {
                SetText(root, $"ImageBg/Bg/Node{index}/Name", index <= store.OpponentCount ? $"竞技对手{index}" : "暂无对手");
                SetText(root, $"ImageBg/Bg/Node{index}/Power", "战力: --");
            }
            SetText(root, "ImageBg_1/Bg/Node/Name", store.OpponentCount > 3 ? "竞技对手4" : "暂无对手");
            SetText(root, "ImageBg_2/Bg/Node/Name", "我的排名");
        }

        private static void DisableActions(Transform root)
        {
            string[] paths = {
                "ImageBg/Bg/Btn_1", "ImageBg/Bg/Btn_2", "ImageBg/Bg/Btn_3",
                "ImageBg_1/Btn", "ImageBg_2/Btn", "Panel/JingjiBg/TimesBg/AddBtn",
                "Panel/JingjiBg/ArrayBtn", "Panel/JingjiBg/Btn_1", "Panel/JingjiBg/Btn_2",
                "Panel/JingjiBg/Btn_3", "Panel/JingjiBg/Btn_4"
            };
            foreach (string path in paths)
            {
                Button button = root.Find(path)?.GetComponent<Button>();
                if (button == null) continue;
                button.onClick.RemoveAllListeners();
                button.interactable = false;
            }
        }

        private static void BindClose(Transform root, string path, Action close)
        {
            Button button = root.Find(path)?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = true;
            button.onClick.AddListener(() => close());
        }

        private static Text RequireText(Transform root, string path) => root.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"Arena imported text was not found: {path}");

        private static void SetText(Transform root, string path, string value)
        {
            Text text = root.Find(path)?.GetComponent<Text>();
            if (text != null) text.text = value;
        }

        private static void SetVisible(Transform target, bool visible)
        {
            if (target != null) target.gameObject.SetActive(visible);
        }

        private static void Normalize(Transform root)
        {
            if (!(root is RectTransform rect)) return;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }
    }
}
