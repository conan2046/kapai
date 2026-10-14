using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    // Owns interaction only. Modules clone their authored templates and supply business data.
    public sealed class GroupedTemplateList : MonoBehaviour
    {
        [SerializeField] private Sprite selectedHeaderSprite;

        private sealed class Group
        {
            public GameObject Content;
            public Image Header;
            public Sprite DefaultSprite;
            public Button Button;
        }

        private readonly Dictionary<int, Group> groups = new Dictionary<int, Group>();
        public int SelectedGroup { get; private set; }
        public bool HasSelection { get; private set; }

        public void RegisterGroup(int id, GameObject root, Action<int> selectionChanged)
        {
            if (id <= 0 || groups.ContainsKey(id)) throw new ArgumentException("Group IDs must be positive and unique.", nameof(id));
            if (root == null) throw new ArgumentNullException(nameof(root));
            if (selectedHeaderSprite == null) throw new InvalidOperationException("Grouped list has no selected header sprite.");
            Transform headerNode = root.transform.Find("HeaderBackground");
            Transform nameNode = root.transform.Find("Name");
            Transform contentNode = root.transform.Find("VirtualContent");
            Image header = headerNode == null ? null : headerNode.GetComponent<Image>();
            if (header == null || nameNode == null || contentNode == null)
                throw new InvalidOperationException("Grouped template requires HeaderBackground/Image, Name and VirtualContent.");

            Button button = nameNode.GetComponent<Button>() ?? nameNode.gameObject.AddComponent<Button>();
            button.targetGraphic = nameNode.GetComponent<Graphic>();
            if (button.targetGraphic != null) button.targetGraphic.raycastTarget = true;
            button.transition = Selectable.Transition.None;
            button.onClick.RemoveAllListeners();
            button.onClick.AddListener(() => { ToggleGroup(id); selectionChanged?.Invoke(SelectedGroup); });
            groups.Add(id, new Group { Content = contentNode.gameObject, Header = header, DefaultSprite = header.sprite, Button = button });
            Refresh();
        }

        public bool InitializeSelection(int id)
        {
            if (HasSelection) return false;
            SelectGroup(id);
            return true;
        }

        public void ToggleGroup(int id)
        {
            if (!groups.ContainsKey(id)) throw new ArgumentOutOfRangeException(nameof(id));
            SelectGroup(SelectedGroup == id ? 0 : id);
        }

        public void SelectGroup(int id)
        {
            if (id != 0 && !groups.ContainsKey(id)) throw new ArgumentOutOfRangeException(nameof(id));
            SelectedGroup = id;
            HasSelection = true;
            Refresh();
        }

        public void ResetSelection()
        {
            SelectedGroup = 0;
            HasSelection = false;
            Refresh();
        }

        public IEnumerator ScrollToSelection(ScrollRect scroll)
        {
            int selected=SelectedGroup;
            yield return null;
            if(scroll==null||!scroll.gameObject.activeInHierarchy||selected==0||SelectedGroup!=selected||!groups.TryGetValue(selected,out var group))yield break;
            Canvas.ForceUpdateCanvases();
            float excess=scroll.content.rect.height-scroll.viewport.rect.height;
            if(excess<=0f)yield break;
            var bounds=RectTransformUtility.CalculateRelativeRectTransformBounds(scroll.content,group.Button.transform);
            scroll.StopMovement();
            scroll.verticalNormalizedPosition=1f-Mathf.Clamp01((scroll.content.rect.yMax-bounds.max.y)/excess);
        }

        public void SetInteractable(bool value)
        {
            foreach (Group group in groups.Values) group.Button.interactable = value;
        }

        public void Refresh()
        {
            foreach (var pair in groups)
            {
                bool selected = pair.Key == SelectedGroup;
                pair.Value.Content.SetActive(selected);
                pair.Value.Header.sprite = selected ? selectedHeaderSprite : pair.Value.DefaultSprite;
            }
        }
    }
}
