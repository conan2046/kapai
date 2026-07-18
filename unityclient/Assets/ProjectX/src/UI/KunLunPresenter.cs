using System;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class KunLunPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly KunLunStore store;
        private readonly Text floor;
        private readonly Text remaining;

        public KunLunPresenter(CocosUiView view, KunLunStore store, Action close)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            Transform root = view.GameObject.transform;
            Normalize(root);
            EnsureBackground(root);
            SetVisible(root.Find("road_layer"), true);
            SetVisible(root.Find("road_layer_2"), false);
            SetVisible(root.Find("Enemy_layer"), true);
            SetVisible(root.Find("Node_role"), false);
            floor = RequireText(root, "cengshulayer/cengshuBg/text2");
            remaining = RequireText(root, "tiaozhancishulayer/tiaozhancishuBg/num");
            DisableActions(root);
            store.Changed += Render;
            Render();
        }

        public bool IsAuthoritativeVisible => store.HasAuthoritativeResponse && floor != null && remaining != null;

        public void Dispose() => store.Changed -= Render;

        private void Render()
        {
            if (!store.HasAuthoritativeResponse)
            {
                floor.text = "第 -- 层";
                remaining.text = "--";
                return;
            }

            floor.text = $"第 {store.Floor} 层";
            remaining.text = store.RemainingFights.ToString();
            Transform root = view.GameObject.transform;
            if (store.Enemies.Count == 0)
            {
                for (int row = 1; row <= 3; row++)
                for (int column = 1; column <= 3; column++)
                {
                    Transform node = root.Find($"Enemy_layer/Button_{row}_{column}");
                    if (node == null) continue;
                    SetVisible(node, true);
                    SetVisible(node.Find("BaseImage/Node"), false);
                    SetVisible(node.Find("info_layer"), true);
                    SetVisible(node.Find("bloodBar"), false);
                    SetVisible(node.Find("Button_lianchuang"), false);
                    SetText(node, "info_layer/Level", "--");
                    SetText(node, "info_layer/Name", "等待匹配");
                    SetText(node, "info_layer/Zhanli/Zhanli_num", "--");
                }
                return;
            }
            foreach (KunLunEnemyRecord enemy in store.Enemies)
            {
                int row = ((enemy.Position - 1) / 3) + 1;
                int column = ((enemy.Position - 1) % 3) + 1;
                Transform node = root.Find($"Enemy_layer/Button_{row}_{column}");
                if (node == null) continue;
                bool cleared = enemy.State == 3;
                SetVisible(node.Find("BaseImage/Node"), false);
                SetVisible(node.Find("info_layer"), !cleared);
                SetVisible(node.Find("bloodBar"), !cleared);
                SetVisible(node.Find("Button_lianchuang"), false);
                SetText(node, "info_layer/Level", enemy.Level.ToString());
                SetText(node, "info_layer/Name", enemy.Name);
                SetText(node, "info_layer/Zhanli/Zhanli_num", enemy.Power.ToString());
                Slider slider = node.Find("bloodBar")?.GetComponent<Slider>();
                if (slider != null) slider.value = enemy.HealthPercent / 100f;
                Image fill = node.Find("bloodBar")?.GetComponent<Image>();
                if (fill != null) fill.fillAmount = enemy.HealthPercent / 100f;
            }

            for (int position = 1; position <= 9; position++)
            {
                if (store.Enemies.Any(value => value.Position == position)) continue;
                int row = ((position - 1) / 3) + 1;
                int column = ((position - 1) % 3) + 1;
                SetVisible(root.Find($"Enemy_layer/Button_{row}_{column}"), false);
            }
        }

        private static void EnsureBackground(Transform root)
        {
            Transform existing = root.Find("KunLunBackgroundRuntime");
            if (existing != null) return;
            Sprite sprite = Resources.Load<Sprite>("Backgrounds/bg_juezhankunlun");
            if (sprite == null)
            {
                Texture2D texture = Resources.Load<Texture2D>("Backgrounds/bg_juezhankunlun");
                if (texture == null) return;
                sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
            }
            GameObject background = new GameObject("KunLunBackgroundRuntime", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            RectTransform rect = (RectTransform)background.transform;
            rect.SetParent(root, false);
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            Image image = background.GetComponent<Image>();
            image.sprite = sprite;
            image.preserveAspect = false;
            image.raycastTarget = false;
            rect.SetAsFirstSibling();
        }

        private static void DisableActions(Transform root)
        {
            string[] paths = { "btn_shangdian", "Box/Button", "Box/Button1", "tiaozhancishulayer/AddBtn" };
            foreach (string path in paths) Disable(root.Find(path)?.GetComponent<Button>());
            for (int row = 1; row <= 3; row++)
            for (int column = 1; column <= 3; column++)
            {
                Transform node = root.Find($"Enemy_layer/Button_{row}_{column}");
                Disable(node?.GetComponent<Button>());
                Disable(node?.Find("Button_lianchuang")?.GetComponent<Button>());
            }
        }

        private static void Disable(Button button)
        {
            if (button == null) return;
            button.onClick.RemoveAllListeners();
            button.interactable = false;
        }

        private static Text RequireText(Transform root, string path) => root.Find(path)?.GetComponent<Text>()
            ?? throw new InvalidOperationException($"KunLun imported text was not found: {path}");

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
