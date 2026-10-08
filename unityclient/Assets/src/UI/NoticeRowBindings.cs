using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>
    /// Serialized Unity references for one Notice list row.
    /// </summary>
    public sealed class NoticeRowBindings : MonoBehaviour
    {
        [SerializeField] private Text nameText;
        [SerializeField] private Text titleText;
        [SerializeField] private GameObject selectedBackground;
        [SerializeField] private Button button;

        public Text NameText => nameText;
        public Text TitleText => titleText;
        public GameObject SelectedBackground => selectedBackground;
        public Button Button => button;
    }
}
