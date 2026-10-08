#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Historic script identity retained; popup animation maintenance is Unity-native and validation-only.
    public static class XunBaoPopupNativePrefabBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity XunBao Popup Assets")]
        public static void Validate()
        {
            XunBaoNativeAnimationAssetValidator.ValidatePopup();
        }
    }
}
#endif
