using UnityEngine;

namespace ProjectX.UI
{
    /// <summary>
    /// Stable Unity-owned key for locating a Prefab instance already present in a scene.
    /// This is independent of Cocos source tokens and node identity data.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class UiPrefabKey : MonoBehaviour
    {
        public const string MainHud = "UImainLayer_new";
        public const string FengShenStoryMain = "fengshenliezhuanlLayer";
        public const string FengShenStoryLevel = "fengshenliezhuanlevel";

        [SerializeField] private string key;

        public string Key => key;
    }
}
