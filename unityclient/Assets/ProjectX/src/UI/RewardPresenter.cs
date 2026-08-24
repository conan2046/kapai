using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class RewardPresenter : IDisposable
    {
        private const string BasePath = "Layer/Popup";
        private readonly CocosUiView view;
        private readonly RewardStore store;
        private readonly Text title;
        private readonly Text tips;
        private readonly GameObject[] cells = new GameObject[4];
        private readonly GameObject[] runtimeCells = new GameObject[4];
        private readonly Image[] runtimeIcons = new Image[4];
        private readonly Text[] runtimeNames = new Text[4];
        private readonly Text[] runtimeAmounts = new Text[4];
        private readonly GameObject runtimeContent;
        private readonly Core.ResourceService resources;
        private readonly Button confirmButton;
        private readonly Button closeButton;
        private Action confirmAction;
        private Action<RewardRecord> itemClick;

        public RewardPresenter(CocosUiView view, RewardStore store, Core.ResourceService resources)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            title = Require("Title/Title_1").GetComponent<Text>();
            tips = Require("tips").GetComponent<Text>();
            for (int index = 0; index < cells.Length; index++)
                cells[index] = Require($"ItemList/itemlayer_{index + 1}");
            runtimeContent = CreateRuntimeContentLayer();
            closeButton = BindClose("Btn_close");
            GameObject confirmNode = Require("btn_lingqu");
            confirmButton = confirmNode.GetComponent<Button>() ?? confirmNode.AddComponent<Button>();
            confirmButton.targetGraphic = confirmNode.GetComponent<Graphic>();
            Text confirm = Require("btn_lingqu/Text1").GetComponent<Text>();
            if (confirm != null) confirm.text = "确 定";
            store.Changed += Render;
            Render();
        }

        public bool IsVisible => view.GameObject != null && view.GameObject.activeSelf;
        public int RenderedCount { get; private set; }
        public string TitleText => title?.text ?? string.Empty;
        public Button CloseControl => closeButton;
        public IReadOnlyList<RewardRecord> Items => store.Items;
        public bool CanConfirm => confirmButton != null && confirmButton.gameObject.activeSelf
            && confirmButton.interactable;

        public bool ValidateVisibleRewards(string expectedTitle,
            IReadOnlyDictionary<uint, uint> expected, out string detail)
        {
            if (!IsVisible || !string.Equals(TitleText, expectedTitle, StringComparison.Ordinal))
            {
                detail = $"visible={IsVisible}, title='{TitleText}'/'{expectedTitle}'";
                return false;
            }
            if (expected == null || expected.Count == 0 || Items.Count != expected.Count
                || Items.Any(item => !expected.TryGetValue(item.Id, out uint amount) || amount != item.Amount))
            {
                string expectedDetail = expected == null ? string.Empty
                    : string.Join(",", expected.Select(pair => $"{pair.Key}x{pair.Value}"));
                detail = $"store={string.Join(",", Items.Select(item => $"{item.Id}x{item.Amount}"))}; "
                    + $"expected={expectedDetail}";
                return false;
            }
            for (int index = 0; index < Math.Min(Items.Count, cells.Length); index++)
            {
                RewardRecord item = Items[index];
                GameObject cell = cells[index];
                string renderedName = cell.transform.Find("Name")?.GetComponent<Text>()?.text ?? string.Empty;
                string renderedAmount = cell.transform.Find("RuntimeAmount")?.GetComponent<Text>()?.text ?? string.Empty;
                if (!cell.activeSelf || renderedName != item.Name || renderedAmount != $"×{item.Amount}")
                {
                    detail = $"cell={index}, active={cell.activeSelf}, name='{renderedName}'/'{item.Name}', "
                        + $"amount='{renderedAmount}'/'×{item.Amount}'";
                    return false;
                }
                string visibleName = runtimeNames[index]?.text ?? string.Empty;
                string visibleAmount = runtimeAmounts[index]?.text ?? string.Empty;
                Sprite visibleIcon = runtimeIcons[index]?.sprite;
                if (runtimeCells[index]?.activeInHierarchy != true || visibleIcon == null
                    || visibleName != item.Name || visibleAmount != $"×{item.Amount}")
                {
                    detail = $"runtimeCell={index}, active={runtimeCells[index]?.activeInHierarchy}, "
                        + $"icon={visibleIcon != null}, name='{visibleName}'/'{item.Name}', "
                        + $"amount='{visibleAmount}'/'×{item.Amount}'";
                    return false;
                }
            }
            foreach (RewardRecord item in Items.Skip(cells.Length))
            {
                if (tips == null || !tips.text.Contains($"{item.Name}×{item.Amount}"))
                {
                    detail = $"overflow reward missing: {item.Name}×{item.Amount}; tips='{tips?.text}'";
                    return false;
                }
            }
            detail = string.Join(",", Items.Select(item => $"{item.Name}×{item.Amount}"));
            return true;
        }

        public void SetItemClickHandler(Action<RewardRecord> callback)
        {
            itemClick = callback;
            Render();
        }

        public bool InvokeFirstItem()
        {
            if (!IsVisible || RenderedCount <= 0) return false;
            Button button = cells[0].GetComponent<Button>();
            if (button == null || !button.interactable) return false;
            button.onClick.Invoke();
            return true;
        }

        public bool InvokeClose()
        {
            if (!IsVisible || closeButton == null || !closeButton.interactable) return false;
            closeButton.onClick.Invoke();
            return true;
        }

        public bool InvokeConfirm()
        {
            if (!CanConfirm) return false;
            confirmButton.onClick.Invoke();
            return true;
        }

        public void Show()
        {
            Show(null, false);
        }

        public void Show(Action onConfirm, bool allowConfirm)
        {
            confirmAction = onConfirm;
            confirmButton.gameObject.SetActive(allowConfirm);
            confirmButton.onClick.RemoveAllListeners();
            if (allowConfirm)
                confirmButton.onClick.AddListener(() =>
                {
                    Action action = confirmAction;
                    confirmAction = null;
                    Hide();
                    action?.Invoke();
                });
            Render();
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Hide()
        {
            confirmAction = null;
            view.SetVisible(false);
        }

        public void Render()
        {
            IReadOnlyList<RewardRecord> items = store.Items;
            RenderedCount = Mathf.Min(items.Count, cells.Length);
            if (title != null) title.text = store.Title;
            if (tips != null)
            {
                tips.text = items.Count > cells.Length
                    ? "其他获得：" + string.Join("、", items.Skip(cells.Length)
                        .Select(item => $"{item.Name}×{item.Amount}"))
                    : string.Empty;
            }
            for (int index = 0; index < cells.Length; index++)
            {
                bool occupied = index < items.Count;
                GameObject cell = cells[index];
                cell.SetActive(occupied);
                GameObject runtimeCell = runtimeCells[index];
                runtimeCell.SetActive(occupied);
                if (!occupied) continue;
                RewardRecord item = items[index];
                Text name = cell.transform.Find("Name")?.GetComponent<Text>();
                if (name != null) name.text = item.Name;
                Image icon = cell.transform.Find("item")?.GetComponent<Image>();
                ApplyIcon(icon, item.Picture);
                AddOrUpdateAmount(cell.transform, item.Amount);
                Button itemButton = cell.GetComponent<Button>() ?? cell.AddComponent<Button>();
                itemButton.targetGraphic = cell.GetComponent<Graphic>()
                    ?? cell.GetComponentInChildren<Graphic>(true);
                itemButton.onClick.RemoveAllListeners();
                itemButton.interactable = itemClick != null;
                if (itemClick != null)
                {
                    RewardRecord captured = item;
                    itemButton.onClick.AddListener(() => itemClick(captured));
                }
                runtimeNames[index].text = item.Name;
                runtimeAmounts[index].text = $"×{item.Amount}";
                ApplyIcon(runtimeIcons[index], item.Picture);
            }
            LayoutRuntimeCells(RenderedCount);
        }

        public void Dispose()
        {
            store.Changed -= Render;
            itemClick = null;
            if (runtimeContent != null) UnityEngine.Object.Destroy(runtimeContent);
        }

        private GameObject CreateRuntimeContentLayer()
        {
            GameObject listView = Require("ListView");
            GameObject layer = new GameObject("BagRewardRuntimeContent", typeof(RectTransform));
            layer.transform.SetParent(listView.transform, false);
            RectTransform layerRect = layer.GetComponent<RectTransform>();
            layerRect.anchorMin = Vector2.zero;
            layerRect.anchorMax = Vector2.one;
            layerRect.offsetMin = Vector2.zero;
            layerRect.offsetMax = Vector2.zero;

            Text template = cells[0].transform.Find("Name")?.GetComponent<Text>() ?? tips;
            for (int index = 0; index < runtimeCells.Length; index++)
            {
                GameObject cell = new GameObject($"Reward_{index + 1}", typeof(RectTransform));
                cell.transform.SetParent(layer.transform, false);
                runtimeCells[index] = cell;

                GameObject iconObject = new GameObject("Icon", typeof(RectTransform),
                    typeof(CanvasRenderer), typeof(Image));
                iconObject.transform.SetParent(cell.transform, false);
                RectTransform iconRect = iconObject.GetComponent<RectTransform>();
                iconRect.anchorMin = new Vector2(0.14f, 0.33f);
                iconRect.anchorMax = new Vector2(0.86f, 0.98f);
                iconRect.offsetMin = Vector2.zero;
                iconRect.offsetMax = Vector2.zero;
                runtimeIcons[index] = iconObject.GetComponent<Image>();

                runtimeNames[index] = CreateRuntimeText(cell.transform, "Name", template,
                    new Vector2(0f, 0.03f), new Vector2(1f, 0.33f), TextAnchor.MiddleCenter);
                runtimeAmounts[index] = CreateRuntimeText(cell.transform, "Amount", template,
                    new Vector2(0.48f, 0.31f), new Vector2(0.91f, 0.54f), TextAnchor.LowerRight);
                runtimeAmounts[index].color = Color.white;
                Shadow shadow = runtimeAmounts[index].gameObject.AddComponent<Shadow>();
                shadow.effectColor = new Color(0f, 0f, 0f, 0.85f);
                shadow.effectDistance = new Vector2(1f, -1f);
            }
            return layer;
        }

        private static Text CreateRuntimeText(Transform parent, string name, Text template,
            Vector2 anchorMin, Vector2 anchorMax, TextAnchor alignment)
        {
            GameObject textObject = new GameObject(name, typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Text));
            textObject.transform.SetParent(parent, false);
            RectTransform rect = textObject.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            Text text = textObject.GetComponent<Text>();
            text.font = template != null ? template.font : Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = template != null ? template.fontSize : 18;
            text.fontStyle = template != null ? template.fontStyle : FontStyle.Normal;
            text.color = template != null ? template.color : Color.white;
            text.alignment = alignment;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = 12;
            text.resizeTextMaxSize = Mathf.Max(18, text.fontSize);
            text.raycastTarget = false;
            return text;
        }

        private void LayoutRuntimeCells(int count)
        {
            int visibleCount = Mathf.Clamp(count, 1, runtimeCells.Length);
            float cellWidth = 1f / runtimeCells.Length;
            float start = (1f - cellWidth * visibleCount) * 0.5f;
            for (int index = 0; index < runtimeCells.Length; index++)
            {
                RectTransform rect = runtimeCells[index].GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(start + cellWidth * index, 0f);
                rect.anchorMax = new Vector2(start + cellWidth * (index + 1), 1f);
                rect.offsetMin = new Vector2(5f, 2f);
                rect.offsetMax = new Vector2(-5f, -2f);
            }
        }

        private Button BindClose(string relativePath)
        {
            GameObject node = Require(relativePath);
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(Hide);
            return button;
        }

        private static void AddOrUpdateAmount(Transform cell, uint amount)
        {
            Transform existing = cell.Find("RuntimeAmount");
            Text label;
            if (existing == null)
            {
                GameObject labelObject = new GameObject("RuntimeAmount", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
                labelObject.transform.SetParent(cell, false);
                RectTransform rect = labelObject.GetComponent<RectTransform>();
                rect.anchorMin = new Vector2(0.45f, 0.18f);
                rect.anchorMax = new Vector2(0.95f, 0.48f);
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                label = labelObject.GetComponent<Text>();
                label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                label.fontSize = 18;
                label.alignment = TextAnchor.LowerRight;
                label.color = Color.white;
            }
            else label = existing.GetComponent<Text>();
            label.text = $"×{amount}";
        }

        private void ApplyIcon(Image image, int picture)
        {
            if (image == null) return;
            Sprite sprite = resources.LoadItemIcon(picture);
            image.sprite = sprite;
            image.enabled = sprite != null;
            image.preserveAspect = true;
        }

        private GameObject Require(string relativePath)
        {
            GameObject result = view.Binding.Find($"{BasePath}/{relativePath}");
            return result ?? throw new InvalidOperationException($"Reward UI node was not found: {BasePath}/{relativePath}");
        }
    }
}
