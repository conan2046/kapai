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
        private readonly Image[] qualityFrames = new Image[4];
        private readonly Image[] icons = new Image[4];
        private readonly Text[] names = new Text[4];
        private readonly Text[] amounts = new Text[4];
        private readonly Core.ResourceService resources;
        private readonly ShopCatalog catalog;
        private readonly Button confirmButton;
        private readonly Button closeButton;
        private Action confirmAction;
        private Action<RewardRecord> itemClick;
        private Func<RewardRecord, Sprite> itemIconResolver;
        private bool showQualityFrames = true;
        private bool sharedViewRenderingSuspended;

        public RewardPresenter(CocosUiView view, RewardStore store, Core.ResourceService resources,
            ShopCatalog catalog)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            title = Require("Title/Title_1").GetComponent<Text>();
            tips = Require("tips").GetComponent<Text>();
            for (int index = 0; index < cells.Length; index++)
            {
                cells[index] = Require($"ItemList/itemlayer_{index + 1}");
                Transform cell = cells[index].transform;
                qualityFrames[index] = cell.Find("Quality")?.GetComponent<Image>();
                icons[index] = cell.Find("item")?.GetComponent<Image>();
                names[index] = cell.Find("Name")?.GetComponent<Text>();
                amounts[index] = cell.Find("Amount")?.GetComponent<Text>();
                if (qualityFrames[index] == null || icons[index] == null
                    || names[index] == null || amounts[index] == null)
                    throw new InvalidOperationException(
                        $"Reward prefab cell itemlayer_{index + 1} is incomplete.");
            }
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
        public bool IsSharedViewRenderingSuspended => sharedViewRenderingSuspended;

        public void SuspendSharedViewRendering()
        {
            sharedViewRenderingSuspended = true;
            foreach (GameObject cell in cells)
                if (cell != null) cell.SetActive(false);
        }

        public void ResumeSharedViewRendering()
        {
            sharedViewRenderingSuspended = false;
            closeButton.onClick.RemoveAllListeners();
            closeButton.onClick.AddListener(Hide);
            Render();
        }

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
                string renderedName = names[index]?.text ?? string.Empty;
                string renderedAmount = amounts[index]?.text ?? string.Empty;
                if (!cell.activeSelf || renderedName != item.Name || renderedAmount != $"×{item.Amount}")
                {
                    detail = $"cell={index}, active={cell.activeSelf}, name='{renderedName}'/'{item.Name}', "
                        + $"amount='{renderedAmount}'/'×{item.Amount}'";
                    return false;
                }
                int visualQuality = ResolveVisualQuality(item);
                string expectedFrame = $"common_quality_{Mathf.Clamp(visualQuality, 1, 7):00}";
                if (icons[index]?.sprite == null
                    || visualQuality > 0 && (qualityFrames[index]?.sprite == null
                        || qualityFrames[index].sprite.name != expectedFrame))
                {
                    detail = $"cell={index}, icon={icons[index]?.sprite != null}, "
                        + $"qualityFrame='{qualityFrames[index]?.sprite?.name}'/'{expectedFrame}', "
                        + $"quality={item.Quality}/{visualQuality}";
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

        public void ConfigureItemVisuals(Func<RewardRecord, Sprite> iconResolver, bool useQualityFrames)
        {
            itemIconResolver = iconResolver;
            showQualityFrames = useQualityFrames;
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
            ResumeSharedViewRendering();
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
            itemIconResolver = null;
            showQualityFrames = true;
        }

        public void Render()
        {
            IReadOnlyList<RewardRecord> items = store.Items;
            RenderedCount = Mathf.Min(items.Count, cells.Length);
            if (sharedViewRenderingSuspended) return;
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
                if (!occupied) continue;
                RewardRecord item = items[index];
                names[index].text = item.Name;
                amounts[index].text = $"×{item.Amount}";
                ApplyQualityFrame(qualityFrames[index], item);
                ApplyIcon(icons[index], item);
                Button itemButton = cell.GetComponent<Button>() ?? cell.AddComponent<Button>();
                itemButton.transition = Selectable.Transition.None;
                itemButton.targetGraphic = icons[index];
                itemButton.onClick.RemoveAllListeners();
                itemButton.interactable = itemClick != null;
                if (itemClick != null)
                {
                    RewardRecord captured = item;
                    itemButton.onClick.AddListener(() => itemClick(captured));
                }
            }
        }

        public void Dispose()
        {
            store.Changed -= Render;
            itemClick = null;
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

        private void ApplyQualityFrame(Image image, RewardRecord item)
        {
            if (image == null) return;
            int quality = ResolveVisualQuality(item);
            Sprite sprite = showQualityFrames && quality > 0
                ? resources.LoadFirst($"HeroUI/common_quality_{Mathf.Clamp(quality, 1, 7):00}")
                : null;
            image.sprite = sprite;
            image.color = Color.white;
            image.enabled = sprite != null;
        }

        private int ResolveVisualQuality(RewardRecord item)
        {
            RewardRecord configured = catalog.DescribeReward(item.Type, checked((int)item.Id), item.Amount);
            return configured.Quality > 0 ? configured.Quality : item.Quality;
        }

        private void ApplyIcon(Image image, RewardRecord item)
        {
            if (image == null) return;
            Sprite sprite = itemIconResolver?.Invoke(item) ?? resources.LoadItemIcon(item.Picture);
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
