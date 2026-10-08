using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>Unity-authored control references required by the message box presenter.</summary>
    [DisallowMultipleComponent]
    public sealed class GameErrorViewBindings : MonoBehaviour
    {
        [SerializeField] private Text title;
        [SerializeField] private Text message;
        [SerializeField] private Button closeButton;
        [SerializeField] private Button singleConfirm;
        [SerializeField] private Button cancelButton;
        [SerializeField] private Button confirmButton;
        [SerializeField] private GameObject iconBg1;
        [SerializeField] private GameObject spend;
        [SerializeField] private GameObject goldNum;
        [SerializeField] private GameObject desBg1;
        [SerializeField] private GameObject checkBox;
        [SerializeField] private GameObject confirm3;
        [SerializeField] private GameObject confirm2Time;

        public Text Title => title;
        public Text Message => message;
        public Button CloseButton => closeButton;
        public Button SingleConfirm => singleConfirm;
        public Button CancelButton => cancelButton;
        public Button ConfirmButton => confirmButton;
        public GameObject IconBg1 => iconBg1;
        public GameObject Spend => spend;
        public GameObject GoldNum => goldNum;
        public GameObject DesBg1 => desBg1;
        public GameObject CheckBox => checkBox;
        public GameObject Confirm3 => confirm3;
        public GameObject Confirm2Time => confirm2Time;
    }
}
