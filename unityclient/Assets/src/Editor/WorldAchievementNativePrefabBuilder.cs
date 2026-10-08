#if UNITY_EDITOR
using UnityEditor;

namespace ProjectX.Editor
{
    // Historic script identity retained; this menu validates the authored Unity asset only.
    public static class WorldAchievementNativePrefabBuilder
    {
        [MenuItem("Tools/ProjectX/Validate Unity World Achievement")]
        public static void Validate()
        {
            WorldNativeAssetValidator.ValidateAchievement();
        }
    }
}
#endif
