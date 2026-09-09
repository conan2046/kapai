using System;
using ProjectX.Core;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GameplayShopItemInfoPresenter
    {
        private readonly CocosUiView view;
        private readonly ResourceService resources;
        private readonly ShopCatalog catalog;
        private readonly Action openDraw;

        public GameplayShopItemInfoPresenter(CocosUiView view, ResourceService resources,
            ShopCatalog catalog, Action openDraw)
        {
            this.view = view ?? throw new ArgumentNullException(nameof(view));
            this.resources = resources ?? throw new ArgumentNullException(nameof(resources));
            this.catalog = catalog ?? throw new ArgumentNullException(nameof(catalog));
            this.openDraw = openDraw ?? throw new ArgumentNullException(nameof(openDraw));
            BindClose();
            Hide();
        }

        public bool IsVisible => view.GameObject.activeSelf;

        public void ShowSoul()
        {
            RewardRecord soul = catalog.DescribeReward(CurrencyIds.Soul, 0, 1);
            catalog.TryGetItemPresentation(CurrencyIds.Soul,
                out string description, out string source);
            SetVisible(Node("Layer/Panel/Panel_1_0/Type_2"), false);
            SetVisible(Node("Layer/Panel/Panel_1_0/Type_3"), false);
            SetVisible(Node("Layer/Panel/Panel_1_0/Image_3"), false);
            SetVisible(Node("Layer/Panel/Panel_1_0/Image_4"), true);
            SetVisible(Node("Layer/Panel/Panel_1_0/Btn_ListView"), true);
            SetVisible(Node("Layer/Panel/Panel_1_0/powerLabel"), false);
            SetText("Layer/Panel/Panel_1_0/nameLabel", soul.Name);
            SetText("Layer/Panel/Panel_1_0/typeLabel", string.Empty);
            SetText("Layer/Panel/Panel_1_0/Btn_ListView/Text", "来源：");
            ConfigureInformation(
                string.IsNullOrWhiteSpace(description) ? "神将魂魄" : description,
                string.IsNullOrWhiteSpace(source) ? "来源：抽卡" : source);
            ConfigureSourceButton();
            GameObject iconHost = Node("Layer/Panel/Panel_1_0/Image_2");
            Image quality = iconHost?.GetComponent<Image>();
            if (quality != null)
            {
                quality.sprite = resources.LoadFirst(
                    $"HeroUI/common_quality_{Mathf.Clamp(soul.Quality, 1, 7):00}");
                quality.enabled = quality.sprite != null;
                quality.preserveAspect = true;
            }
            GameObject iconNode = Node("Layer/Panel/Panel_1_0/Image_4");
            Image icon = iconNode?.GetComponent<Image>();
            if (icon != null)
            {
                icon.sprite = resources.LoadFirst($"ItemIcons/equip{soul.Picture}");
                icon.enabled = icon.sprite != null;
                icon.preserveAspect = true;
                icon.raycastTarget = false;
                iconNode.transform.SetAsLastSibling();
            }
            Text name = Node("Layer/Panel/Panel_1_0/nameLabel")?.GetComponent<Text>();
            if (name != null) name.color = new Color32(206, 40, 202, 255);
            view.SetVisible(true);
            view.GameObject.transform.SetAsLastSibling();
        }

        public void Hide() => view.SetVisible(false);

        private void BindClose()
        {
            GameObject node = view.Binding.Find("Layer/Panel/Panel_1_0/closeBtn")
                ?? throw new InvalidOperationException("Gameplay shop SourceLayer close button is missing.");
            Button button = node.GetComponent<Button>() ?? node.AddComponent<Button>();
            button.targetGraphic = node.GetComponent<Graphic>();
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(Hide);
        }

        private void ConfigureInformation(string description, string source)
        {
            GameObject list = Node("Layer/Panel/Panel_1_0/infoListView");
            if (list == null) return;
            Transform old = list.transform.Find("GameplayShopSoulInformation");
            if (old != null) UnityEngine.Object.Destroy(old.gameObject);
            GameObject node = new GameObject("GameplayShopSoulInformation",
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(list.transform, false);
            RectTransform rect = (RectTransform)node.transform;
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(0f, -5f);
            rect.sizeDelta = new Vector2(305f, 90f);
            Text text = node.GetComponent<Text>();
            Text template = Node("Layer/Panel/Panel_1_0/Btn_ListView/Text")?.GetComponent<Text>();
            text.font = template?.font;
            text.fontSize = 22;
            text.color = template != null ? template.color : new Color(0.52f, 0.35f, 0.18f, 1f);
            text.alignment = TextAnchor.UpperLeft;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            text.raycastTarget = false;
            text.text = description + "\n\n" + source;
        }

        private void ConfigureSourceButton()
        {
            RectTransform sourcePanel = Node("Layer/Panel/Panel_1_0/Btn_ListView")
                ?.GetComponent<RectTransform>();
            if (sourcePanel != null)
                sourcePanel.sizeDelta = new Vector2(136f, 190f);
            GameObject list = Node("Layer/Panel/Panel_1_0/Btn_ListView/List");
            GameObject template = Node("Layer/Panel/Panel_1_0/SystemBtn");
            if (list == null || template == null) return;
            Transform old = list.transform.Find("GameplayShopSoulDrawSource");
            if (old != null) UnityEngine.Object.Destroy(old.gameObject);
            template.SetActive(false);
            GameObject source = UnityEngine.Object.Instantiate(template, list.transform, false);
            source.name = "GameplayShopSoulDrawSource";
            source.SetActive(true);
            RectTransform rect = source.transform as RectTransform;
            if (rect != null)
            {
                rect.anchorMin = rect.anchorMax = Vector2.zero;
                rect.pivot = Vector2.zero;
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = new Vector2(88f, 88f);
                rect.localScale = Vector3.one;
            }
            Image image = source.GetComponent<Image>();
            if (image != null)
            {
                image.sprite = resources.LoadFirst("GameplayIcons/ui_icon_choukarukou");
                image.enabled = image.sprite != null;
                image.preserveAspect = true;
                image.raycastTarget = true;
            }
            Text name = source.transform.Find("Name")?.GetComponent<Text>();
            if (name != null)
            {
                name.text = "神将招募";
                name.gameObject.SetActive(false);
            }
            Button button = source.GetComponent<Button>() ?? source.AddComponent<Button>();
            button.targetGraphic = image;
            button.interactable = true;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() =>
            {
                Hide();
                openDraw();
            });
        }

        private GameObject Node(string path) => view.Binding.Find(path);

        private void SetText(string path, string value)
        {
            Text text = Node(path)?.GetComponent<Text>();
            if (text != null) text.text = value ?? string.Empty;
        }

        private static void SetVisible(GameObject node, bool visible)
        {
            if (node != null) node.SetActive(visible);
        }
    }
}
