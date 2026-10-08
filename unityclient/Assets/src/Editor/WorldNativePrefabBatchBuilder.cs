#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Historic script identity retained. World maintenance now uses Unity-owned Prefabs and animations.
    public static class WorldNativePrefabBatchBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity World Assets")]
        public static void Validate()
        {
            WorldNativeAssetValidator.ValidateAll();
        }
    }
}
#endif
