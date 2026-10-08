using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    /// <summary>Unity-authored references required by the loading presenter.</summary>
    [DisallowMultipleComponent]
    public sealed class LoadingViewBindings : MonoBehaviour
    {
        [SerializeField] private Text message;

        public Text Message => message;
    }
}
