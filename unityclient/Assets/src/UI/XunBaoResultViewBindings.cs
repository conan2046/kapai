using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class XunBaoResultViewBindings : MonoBehaviour
    {
        [SerializeField] private RectTransform listView;
        [SerializeField] private GameObject rewardTemplate;
        [SerializeField] private GameObject itemTemplate;
        [SerializeField] private GameObject legacyBottomButton;
        [SerializeField] private Button closeButton;

        public RectTransform ListView => listView;
        public GameObject RewardTemplate => rewardTemplate;
        public GameObject ItemTemplate => itemTemplate;
        public GameObject LegacyBottomButton => legacyBottomButton;
        public Button CloseButton => closeButton;
    }
}
