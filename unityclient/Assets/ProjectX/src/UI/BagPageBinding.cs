using System;
using ProjectX.UI.Migration;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Resolves and caches Unity-owned references for the Bag page instance.
    /// The imported Prefab stays untouched; shared-frame ownership remains with
    /// OneLevelFrameCoordinator and PlayerHubTabCoordinator.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class BagPageBinding : MonoBehaviour
    {
        public GameObject ViewportObject { get; private set; }
        public GameObject RowTemplate { get; private set; }
        public Text DetailName { get; private set; }
        public Text DetailDescription { get; private set; }
        public Image DetailIcon { get; private set; }
        public Button UseButton { get; private set; }
        public Button CloseButton { get; private set; }
        public Button TabButton { get; private set; }
        public Text HeaderTitle { get; private set; }
        public Text TabNormalLabel { get; private set; }
        public Text TabSelectedLabel { get; private set; }

        public static BagPageBinding Attach(GameObject pageInstance, Transform sharedFrame,
            Action closeAction, Action tabAction)
        {
            if (pageInstance == null) throw new ArgumentNullException(nameof(pageInstance));
            if (sharedFrame == null) throw new ArgumentNullException(nameof(sharedFrame));

            BagPageBinding binding = pageInstance.GetComponent<BagPageBinding>()
                ?? pageInstance.AddComponent<BagPageBinding>();
            binding.Bind(sharedFrame, closeAction, tabAction);
            return binding;
        }

        private void Bind(Transform sharedFrame, Action closeAction, Action tabAction)
        {
            Transform bag = FindDescendant(transform, "beibao_layer");
            ViewportObject = Require(bag, "Bag/TableView").gameObject;
            RowTemplate = Require(bag, "Bag/ItemCell").gameObject;
            DetailName = Require(bag, "item/Namebg/Name").GetComponent<Text>();
            DetailDescription = Require(bag, "item/miaoshu/Content").GetComponent<Text>();
            DetailIcon = Require(bag, "item/Node/Icon").GetComponent<Image>();
            UseButton = Require(bag, "item/Btn_use").GetComponent<Button>();

            Transform panel = Require(sharedFrame, "Panel_12");
            Transform title = Require(panel, "Title");
            Transform tabs = Require(panel, "Bg/Btn_ListView/Panel_10");
            HeaderTitle = Require(title, "TitleName").GetComponent<Text>();
            Transform tab = Require(tabs, "Button1");
            TabNormalLabel = Require(tab, "BtnName").GetComponent<Text>();
            TabSelectedLabel = Require(tab, "ChooseBg/BtnName").GetComponent<Text>();
            CloseButton = EnsureButton(Require(title, "CloseBtn"), "CloseBtn");
            TabButton = EnsureButton(tab, "Button1");

            CloseButton.onClick.RemoveAllListeners();
            if (closeAction != null) CloseButton.onClick.AddListener(() => closeAction());
            TabButton.onClick.RemoveAllListeners();
            if (tabAction != null) TabButton.onClick.AddListener(() => tabAction());

            RetireLegacyNodeMetadata();
        }

        private void RetireLegacyNodeMetadata()
        {
            // Bag now owns its runtime references through Unity Transform paths.
            // Keep the serialized Prefab untouched, but retire its legacy lookup
            // metadata from this instantiated page while the game is running.
            if (!Application.isPlaying) return;
            CocosUiBinding runtimeBinding = GetComponent<CocosUiBinding>();
            if (runtimeBinding != null)
            {
                runtimeBinding.RetireLegacyNodeMetadataAtRuntime();
                return;
            }

            CocosNodeMetadata[] metadata = GetComponentsInChildren<CocosNodeMetadata>(true);
            for (int index = 0; index < metadata.Length; index++)
            {
                if (metadata[index] == null) continue;
                CocosUiBinding.PreserveRetiredMetadataIdentity(metadata[index]);
                Destroy(metadata[index]);
            }
        }

        private static Transform Require(Transform root, string relativePath)
        {
            Transform result = root.Find(relativePath);
            if (result == null)
                throw new InvalidOperationException($"Bag Unity page binding could not resolve '{root.name}/{relativePath}'.");
            return result;
        }

        private static Transform FindDescendant(Transform root, string nodeName)
        {
            Transform[] descendants = root.GetComponentsInChildren<Transform>(true);
            for (int index = 0; index < descendants.Length; index++)
                if (descendants[index] != root && descendants[index].name == nodeName)
                    return descendants[index];
            throw new InvalidOperationException($"Bag Unity page binding could not resolve semantic node '{nodeName}' below '{root.name}'.");
        }

        private static Button EnsureButton(Transform node, string semanticName)
        {
            Button button = node.GetComponent<Button>();
            if (button != null) return button;
            button = node.gameObject.AddComponent<Button>();
            button.transition = Selectable.Transition.None;
            Image image = node.GetComponent<Image>();
            if (image != null) button.targetGraphic = image;
            return button;
        }
    }
}
