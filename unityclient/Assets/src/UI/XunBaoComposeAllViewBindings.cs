using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class XunBaoComposeAllViewBindings : MonoBehaviour
    {
        [SerializeField] private RectTransform tableView;
        [SerializeField] private GameObject rowTemplate;
        [SerializeField] private Button panelDismissButton;
        [SerializeField] private Button closeButton;

        public RectTransform TableView => tableView;
        public GameObject RowTemplate => rowTemplate;
        public Button PanelDismissButton => panelDismissButton;
        public Button CloseButton => closeButton;
    }
}
