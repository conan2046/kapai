#if UNITY_EDITOR
using System;
using System.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    /// <summary>
    /// Checks the Unity-owned Main HUD resource chain and native hierarchy bindings.
    /// </summary>
    public static class MainHudNativeAssetValidator
    {
        private const string PrefabPath = "Assets/Prefabs/Main/UImainLayer_new.prefab";
        private const string ReferencePath = "Assets/Prefabs/Catalog/UImainLayer_new.asset";
        private const string NativeVisualRoot = "Assets/Art/UI/";
        private static readonly string[] RequiredUnityPaths =
        {
            "Layer/Main_UI/Head/name_bg/name",
            "Layer/Main_UI/Head/bg_Level/Value",
            "Layer/Main_UI/Head/bg_VIP/Value",
            "Layer/Main_UI/Head/bg_CombatEffetiveness/Value",
            "Layer/Main_UI/ButtonGroup6/Icon_jinbi/NumBg/Num",
            "Layer/Main_UI/ButtonGroup6/Icon_yuanbao/GoldNumBg/Num",
            "Layer/Main_UI/ButtonGroup6/Icon_tili/NumBg/Num",
            "Layer/Main_UI/Head/Icon",
            "Layer/Main_UI/Head/EXPBar",
            "Layer/Main_UI/Head/bg_CombatEffetiveness/Value/Wan"
        };

        [MenuItem("Tools/ProjectX 界面/验证 Main HUD Unity 资源链")]
        public static void Validate()
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(PrefabPath);
            UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(ReferencePath);
            if (prefab == null || reference == null || reference.Prefab != prefab)
                throw new InvalidOperationException("Main HUD UiPrefabReference does not resolve to its Unity-owned Prefab.");

            GameObject root = PrefabUtility.LoadPrefabContents(PrefabPath);
            try
            {
                ValidateUnityOwnedBehaviours(root);
                UiPrefabKey prefabKey = root.GetComponent<UiPrefabKey>();
                if (prefabKey == null || !string.Equals(prefabKey.Key, UiPrefabKey.MainHud, StringComparison.Ordinal))
                    throw new InvalidOperationException("Main HUD Unity Prefab key is missing or incorrect.");
                Transform buttonGroupTransform = root.transform.Find("Layer/Main_UI/ButtonGroup1")
                    ?? root.transform.Find("Main_UI/ButtonGroup1");
                HorizontalLayoutGroup buttonLayout = buttonGroupTransform != null
                    ? buttonGroupTransform.GetComponent<HorizontalLayoutGroup>()
                    : null;
                ContentSizeFitter buttonFitter = buttonGroupTransform != null
                    ? buttonGroupTransform.GetComponent<ContentSizeFitter>()
                    : null;
                if (buttonLayout == null || buttonFitter == null
                    || !Mathf.Approximately(buttonLayout.spacing, 10f)
                    || buttonLayout.childAlignment != TextAnchor.MiddleRight
                    || buttonFitter.horizontalFit != ContentSizeFitter.FitMode.PreferredSize
                    || buttonFitter.verticalFit != ContentSizeFitter.FitMode.Unconstrained
                    || !Mathf.Approximately(((RectTransform)buttonGroupTransform).pivot.x, 1f)
                    || !Mathf.Approximately(((RectTransform)buttonGroupTransform).pivot.y, 0.5f))
                    throw new InvalidOperationException("Main HUD native horizontal button layout is missing or changed.");
                string[] missingPaths = RequiredUnityPaths.Where(path => FindUnityPath(root.transform, path) == null).ToArray();
                if (missingPaths.Length != 0)
                    throw new InvalidOperationException($"Main HUD Unity Transform bindings are missing: {string.Join(", ", missingPaths)}.");
                MainHudPromptBindings promptBindings = root.GetComponent<MainHudPromptBindings>();
                if (promptBindings == null || promptBindings.StablePrompts.Length != 6)
                    throw new InvalidOperationException("Main HUD serialized Unity prompt bindings are missing or incomplete.");
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }

            string[] dependencies = AssetDatabase.GetDependencies(PrefabPath, true);
            string[] oldDependencies = dependencies.Where(path =>
                path.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase)).ToArray();
            string[] nativeVisuals = dependencies.Where(path =>
                path.StartsWith(NativeVisualRoot, StringComparison.OrdinalIgnoreCase)).ToArray();
            if (oldDependencies.Length != 0 || nativeVisuals.Length != 58)
                throw new InvalidOperationException($"Main HUD resource chain is not isolated: old={oldDependencies.Length}, nativeVisuals={nativeVisuals.Length}.");

            Debug.Log("Main HUD Unity resource chain validated: only Unity Engine and approved Unity-owned behaviours, 10 required Unity Transform paths, serialized prompt bindings, 58 Unity-owned visual assets, and 0 imported res dependencies.");
        }

        private static void ValidateUnityOwnedBehaviours(GameObject root)
        {
            MonoBehaviour[] behaviours = root.GetComponentsInChildren<MonoBehaviour>(true);
            foreach (MonoBehaviour behaviour in behaviours)
            {
                if (behaviour == null) continue;
                Type type = behaviour.GetType();
                string typeNamespace = type.Namespace;
                bool unityEngineBehaviour = typeNamespace != null
                    && typeNamespace.StartsWith("UnityEngine.", StringComparison.Ordinal);
                bool approvedUnityBehaviour = type == typeof(UiPrefabKey)
                    || type == typeof(MainHudPromptBindings);
                if (!unityEngineBehaviour && !approvedUnityBehaviour)
                    throw new InvalidOperationException("Main HUD Prefab contains an unapproved custom behaviour: " + type.FullName);
            }
        }

        private static Transform FindUnityPath(Transform root, string path)
        {
            Transform target = root.Find(path);
            if (target == null && path.StartsWith("Layer/", StringComparison.Ordinal))
                target = root.Find(path.Substring("Layer/".Length));
            return target;
        }
    }
}
#endif
