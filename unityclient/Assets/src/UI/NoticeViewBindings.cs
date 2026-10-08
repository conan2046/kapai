using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Unity-authored references for the Notice screen. These replace lookups
    /// through the imported Cocos node-name hierarchy.
    /// </summary>
    public sealed class NoticeViewBindings : MonoBehaviour
    {
        [SerializeField] private RectTransform listViewport;
        [SerializeField] private RectTransform listTemplate;
        [SerializeField] private Text contentText;
        [SerializeField] private Button closeButton;

        public GameObject Root => gameObject;
        public GameObject ListViewport => listViewport != null ? listViewport.gameObject : null;
        public GameObject ListTemplate => listTemplate != null ? listTemplate.gameObject : null;
        public Text ContentText => contentText;
        public Button CloseButton => closeButton;
    }
}
