#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Kept under the historic script identity so existing Unity metadata remains stable.
    // XunBao Prefabs and clips are now authored directly in Unity; this entry point is validation-only.
    public static class XunBaoNativePrefabBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity XunBao Main Assets")]
        public static void Validate()
        {
            XunBaoNativeAnimationAssetValidator.ValidateMain();
        }
    }
}
#endif
