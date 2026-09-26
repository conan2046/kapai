using UnityEngine;

namespace ProjectX.UI
{
    // Native controls added after the imported identity was authored, or sharing
    // an ambiguous imported path, are bound explicitly on the SystemLayer root.
    public sealed class SettingsPageReferences : MonoBehaviour
    {
        [SerializeField] private GameObject activationButton;
        [SerializeField] private GameObject saveDisplayButton;
        [SerializeField] private GameObject musicToggle;
        [SerializeField] private GameObject resolutionDropdown;
        [SerializeField] private GameObject fullScreenToggle;

        public GameObject ActivationButton => activationButton;
        public GameObject SaveDisplayButton => saveDisplayButton;
        public GameObject MusicToggle => musicToggle;
        public GameObject ResolutionDropdown => resolutionDropdown;
        public GameObject FullScreenToggle => fullScreenToggle;
    }
}
