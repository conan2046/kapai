#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>Read-only validation for the Unity-owned World Prefabs and animation source assets.</summary>
    public static class WorldNativeAssetValidator
    {
        private static readonly string[] PrefabPaths =
        {
            "Assets/Prefabs/World/WorldMapNewLayer.prefab",
            "Assets/Prefabs/World/kapaiguaiwuLayer.prefab",
            "Assets/Prefabs/World/DadituuiLayer.prefab",
            "Assets/Prefabs/World/guanqiaxiangxiLayer.prefab",
            "Assets/Prefabs/World/saodangLayer.prefab",
            "Assets/Prefabs/World/zhandoujiesuanLayer.prefab",
            "Assets/Prefabs/World/zhandoutongji.prefab",
            "Assets/Prefabs/World/guaiwubaoxiangLayer.prefab",
            "Assets/Prefabs/World/WorldBattleStatisticsFrame.prefab",
            "Assets/Prefabs/World/zhuxianchengjiu.prefab"
        };

        private static readonly string[] ClipPaths =
        {
            "Assets/Animations/World/DadituuiLayerNative.anim",
            "Assets/Animations/World/zhandoujiesuanLayerNative.anim",
            "Assets/Animations/World/WorldAchievement.anim"
        };

        [MenuItem("Tools/ProjectX/Validate Unity World Native Assets")]
        public static void ValidateAll()
        {
            foreach (string path in PrefabPaths) ValidatePrefab(path);
            ValidateControllerAndClip(
                "Assets/Prefabs/World/DadituuiLayer.prefab",
                "Assets/Animations/World/DadituuiLayerNative.controller",
                ClipPaths[0]);
            ValidateControllerAndClip(
                "Assets/Prefabs/World/zhandoujiesuanLayer.prefab",
                "Assets/Animations/World/zhandoujiesuanLayerNative.controller",
                ClipPaths[1]);
            ValidateControllerAndClip(
                "Assets/Prefabs/World/zhuxianchengjiu.prefab",
                "Assets/Animations/World/WorldAchievement.controller",
                ClipPaths[2]);
            Debug.Log("Unity-native World Prefabs and animation assets validated: 10 Prefabs, 3 Animator/Clip pairs.");
        }

        public static void ValidateAchievement()
        {
            ValidatePrefab(PrefabPaths[9]);
            ValidateControllerAndClip(PrefabPaths[9],
                "Assets/Animations/World/WorldAchievement.controller", ClipPaths[2]);
            Debug.Log("Unity-native World achievement Prefab and animation validated.");
        }

        private static void ValidatePrefab(string path)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if (prefab == null) throw new FileNotFoundException("Unity-owned World Prefab is missing: " + path);
            foreach (string dependency in AssetDatabase.GetDependencies(path, true))
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Unity-owned World Prefab depends on the legacy resource tree: " + path + " -> " + dependency);

            GameObject root = PrefabUtility.LoadPrefabContents(path);
            try
            {
                foreach (Component component in root.GetComponentsInChildren<Component>(true))
                {
                    if (component == null)
                        throw new InvalidDataException("Unity-owned World Prefab contains a missing script: " + path);
                    string typeName = component.GetType().Name;
                    if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer" || typeName == "CocosUiBinding")
                        throw new InvalidDataException("Unity-owned World Prefab contains Cocos component " + typeName + ": " + path);
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static void ValidateControllerAndClip(string prefabPath, string controllerPath, string clipPath)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(controllerPath);
            AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(clipPath);
            if (prefab == null) throw new FileNotFoundException("World animation Prefab is missing: " + prefabPath);
            if (controller == null) throw new FileNotFoundException("Unity World Animator Controller is missing: " + controllerPath);
            if (clip == null) throw new FileNotFoundException("Unity World AnimationClip is missing: " + clipPath);

            Animator animator = prefab.GetComponent<Animator>();
            if (animator == null || animator.runtimeAnimatorController != controller)
                throw new InvalidDataException("World Prefab Animator does not reference the expected Controller: " + prefabPath);
            var controllerClips = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (AnimatorControllerLayer layer in controller.layers)
                foreach (ChildAnimatorState child in layer.stateMachine.states)
                {
                    AnimationClip stateClip = child.state.motion as AnimationClip;
                    if (stateClip != null) controllerClips.Add(AssetDatabase.GetAssetPath(stateClip));
                }
            if (!controllerClips.Contains(clipPath))
                throw new InvalidDataException("World Animator Controller does not reference its authored Clip: " + controllerPath + " -> " + clipPath);
            if (clip.length <= 0f)
                throw new InvalidDataException("Unity World AnimationClip has zero duration: " + clipPath);

            EditorCurveBinding[] bindings = AnimationUtility.GetCurveBindings(clip);
            if (bindings.Length == 0) throw new InvalidDataException("Unity World AnimationClip has no transform curves: " + clipPath);
            foreach (EditorCurveBinding binding in bindings)
            {
                Transform target = string.IsNullOrEmpty(binding.path) ? prefab.transform : prefab.transform.Find(binding.path);
                if (target == null)
                    throw new InvalidDataException("World animation target is absent from its Unity Prefab: " + clipPath + " -> " + binding.path);
                AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                if (curve == null) throw new InvalidDataException("World animation curve is missing: " + clipPath + " -> " + binding.path);
                foreach (Keyframe key in curve.keys)
                    if (float.IsNaN(key.value) || float.IsInfinity(key.value))
                        throw new InvalidDataException("World animation curve contains a non-finite value: " + clipPath + " -> " + binding.path);
            }
        }
    }
}
#endif
