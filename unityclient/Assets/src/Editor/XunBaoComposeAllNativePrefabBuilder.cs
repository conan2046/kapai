#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Historic script identity retained; compose-all animation maintenance is Unity-native and validation-only.
    public static class XunBaoComposeAllNativePrefabBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity XunBao Compose-All Assets")]
        public static void Validate()
        {
            XunBaoNativeAnimationAssetValidator.ValidateComposeAll();
        }
    }
}
#endif
