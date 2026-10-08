#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Historic script identity retained; search-result maintenance validates the Unity-owned Prefab only.
    public static class XunBaoResultNativePrefabBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity XunBao Search Result")]
        public static void Validate()
        {
            XunBaoNativeAnimationAssetValidator.ValidateResult();
        }
    }
}
#endif
