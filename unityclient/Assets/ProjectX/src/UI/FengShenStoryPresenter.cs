using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FengShenStoryPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly FengShenStoryStore store;
        private readonly Text remaining;
        private readonly Text chapter;
        private readonly Text chapterTitle;

        public FengShenStoryPresenter(CocosUiView view, FengShenStoryStore store, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            Normalize(view.GameObject.transform);
            Transform root = view.GameObject.transform;
            SetVisible(root.Find("Panel_1"), true);
            SetVisible(root.Find("Panel_2"), true);
            remaining = RequireText(root, "Panel_1/today/num");
            chapter = RequireText(root, "Panel_1/Image_78/list");
            chapterTitle = RequireText(root, "Panel_1/Image_78/text1");
            DisableButton(root, "Panel_1/Box1/Button");
            DisableButton(root, "Panel_1/Box1/Button1");
            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && remaining != null;

        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            if (!store.HasAuthoritativeResponse)
            {
                remaining.text = "--/5";
                return;
            }
            int displayChapter = checked((int)store.ChapterId + 1);
            remaining.text = $"{store.RemainingChallenges}/5";
            chapter.text = displayChapter.ToString();
            chapterTitle.text = $"第\n{displayChapter}\n章";

            Transform panel = view.GameObject.transform.Find("Panel_1");
            for (int group = 1; group <= 4; group++)
            for (int level = 1; level <= 3; level++)
            {
                Transform node = panel?.Find($"chapter_{group}{level}");
                if (node == null) continue;
                bool current = store.LevelId % 10 == level && displayChapter == group;
                SetVisible(node.Find("Image_4"), current);
            }
        }

        private static void DisableButton(Transform root, string path)
        {
            Button button = root.Find(path)?.GetComponent<Button>();
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = false;
        }

        private static Text RequireText(Transform root, string path) => root.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"FengShenStory imported text was not found: {path}");

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
