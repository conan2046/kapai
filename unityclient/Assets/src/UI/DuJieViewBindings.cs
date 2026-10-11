using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class DuJieViewBindings : MonoBehaviour
    {
        public RectTransform CloudAnchor;
        public RectTransform LightningAnchor;
        public RectTransform RoleAnchor;
        public RectTransform ShieldAnchor;
        public RectTransform ResultAnchor;
        public RawImage CloudViewport;
        public RawImage ShieldViewport;
        public Image HealthFill;
        public Text HealthValue;
        public Text RoleName;
        public Text Status;
        public Button ReturnButton;
        public GameObject CloudPrefab;
        public GameObject LightningPrefab;
        public GameObject ShieldPrefab;
        public GameObject SuccessPrefab;
    }
}
