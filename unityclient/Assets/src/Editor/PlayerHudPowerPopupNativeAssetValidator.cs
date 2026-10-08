#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;
using ProjectX.UI;

namespace ProjectX.Editor
{
    /// <summary>Validates editable Unity-owned PlayerHud power popup assets.</summary>
    public static class PlayerHudPowerPopupNativeAssetValidator
    {
        private const string PrefabPath = "Assets/Prefabs/Runtime/Common/PlayerHud/PowerChangedPopup.prefab";
        private const string NativeRoot = "Assets/Art/UI/";

        private static readonly Dictionary<string, string> ExpectedSprites = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            { "zhanlitisheng/bg_zhanli", "ui_juese_zhanli_di.png" },
            { "zhanlitisheng/bg_zhanli/Image", "ui_juese_zhanli.png" },
            { "zhanlitisheng/Power_bg", "ui_zhandou_bg_zhanlizengjia.png" },
            { "zhanlitisheng/Power_bg/Power_Image", "ui_zhandou_zi_zhanli.png" },
            { "zhanlitisheng/Power_bg/AtlasLabel_1/UPImage", "ui_jineng_shengji.png" }
        };

        [MenuItem("Tools/ProjectX/Validate PlayerHud Power Popup")]
        public static void Validate()
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath);
            if (prefab == null || prefab.GetComponent<PowerChangedPopupView>() == null
                || prefab.GetComponent<CanvasGroup>() == null)
                throw new InvalidOperationException("Unity PlayerHud power popup Prefab or its native view is missing.");

            foreach (string dependency in AssetDatabase.GetDependencies(PrefabPath, true))
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Unity PlayerHud popup still references imported Cocos data: " + dependency);

            GameObject contents = PrefabUtility.LoadPrefabContents(PrefabPath);
            try
            {
                foreach (KeyValuePair<string, string> entry in ExpectedSprites)
                {
                    Transform node = contents.transform.Find(entry.Key);
                    Image image = node != null ? node.GetComponent<Image>() : null;
                    string path = image != null && image.sprite != null ? AssetDatabase.GetAssetPath(image.sprite) : string.Empty;
                    if (string.IsNullOrEmpty(path) || !path.StartsWith(NativeRoot, StringComparison.Ordinal)
                        || !path.EndsWith(entry.Value, StringComparison.Ordinal))
                        throw new InvalidOperationException("PlayerHud popup sprite is missing or outside its Unity-owned root: " + entry.Key);
                }

                ValidateFont(contents.transform.Find("zhanlitisheng/bg_zhanli/Value"), "xiaokaiSJ2.ttf");
                ValidateFont(contents.transform.Find("zhanlitisheng/Power_bg/AtlasLabel_1"), "MicrosoftArial.ttf");
                foreach (Component component in contents.GetComponentsInChildren<Component>(true))
                {
                    if (component == null) throw new InvalidOperationException("PlayerHud popup has a missing component.");
                    string typeName = component.GetType().Name;
                    if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer" || typeName == "CocosUiBinding")
                        throw new InvalidOperationException("PlayerHud popup retains Cocos component " + typeName);
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(contents);
            }
            Debug.Log("Unity-native PlayerHud power popup assets validated.");
        }

        private static void ValidateFont(Transform node, string fileName)
        {
            Text text = node != null ? node.GetComponent<Text>() : null;
            string path = text != null && text.font != null ? AssetDatabase.GetAssetPath(text.font) : string.Empty;
            if (string.IsNullOrEmpty(path) || !path.StartsWith("Assets/Art/Fonts/", StringComparison.Ordinal)
                || !path.EndsWith(fileName, StringComparison.Ordinal))
                throw new InvalidOperationException("PlayerHud popup font is missing or outside its Unity-owned root: " + fileName);
        }
    }
}
#endif
