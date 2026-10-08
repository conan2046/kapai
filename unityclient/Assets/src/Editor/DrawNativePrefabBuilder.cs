#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>Read-only validation of Unity-owned Draw result Prefabs and animation assets.</summary>
    public static class DrawNativeAssetValidator
    {
        private static readonly AnimationEntry[] Entries =
        {
            new AnimationEntry(
                "Assets/Prefabs/Draw/dancichouka.prefab",
                "Assets/Animations/Draw/DrawSingleResult.controller",
                "Assets/Animations/Draw/DrawSingleResult.anim"),
            new AnimationEntry(
                "Assets/Prefabs/Draw/shilianchouka.prefab",
                "Assets/Animations/Draw/DrawTenResult.controller",
                "Assets/Animations/Draw/DrawTenResult.anim")
        };

        [MenuItem("Tools/ProjectX/Validate Unity Draw Native Assets")]
        public static void ValidateAll()
        {
            foreach (AnimationEntry entry in Entries) Validate(entry);
            Debug.Log("Unity-native Draw result Prefabs, Animator Controllers, and AnimationClips validated.");
        }

        private static void Validate(AnimationEntry entry)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(entry.PrefabPath);
            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(entry.ControllerPath);
            AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(entry.ClipPath);
            if (prefab == null) throw new FileNotFoundException("Unity Draw result Prefab is missing: " + entry.PrefabPath);
            if (controller == null) throw new FileNotFoundException("Unity Draw Animator Controller is missing: " + entry.ControllerPath);
            if (clip == null) throw new FileNotFoundException("Unity Draw AnimationClip is missing: " + entry.ClipPath);

            Animator animator = prefab.GetComponent<Animator>();
            if (animator == null || animator.runtimeAnimatorController != controller)
                throw new InvalidDataException("Draw Prefab Animator does not reference its Unity Controller: " + entry.PrefabPath);
            if (!ControllerContainsClip(controller, entry.ClipPath))
                throw new InvalidDataException("Draw Controller does not reference its Unity AnimationClip: " + entry.ControllerPath);
            ValidateClipTargets(prefab, clip, entry.ClipPath);

            foreach (string dependency in AssetDatabase.GetDependencies(entry.PrefabPath, true))
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Unity Draw Prefab depends on the legacy resource tree: "
                        + entry.PrefabPath + " -> " + dependency);

            GameObject root = PrefabUtility.LoadPrefabContents(entry.PrefabPath);
            try
            {
                foreach (Component component in root.GetComponentsInChildren<Component>(true))
                {
                    if (component == null)
                        throw new InvalidDataException("Unity Draw Prefab contains a missing script: " + entry.PrefabPath);
                    string typeName = component.GetType().Name;
                    if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer" || typeName == "CocosUiBinding")
                        throw new InvalidDataException("Unity Draw Prefab contains Cocos component " + typeName
                            + ": " + entry.PrefabPath);
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static bool ControllerContainsClip(AnimatorController controller, string clipPath)
        {
            foreach (AnimatorControllerLayer layer in controller.layers)
                foreach (ChildAnimatorState child in layer.stateMachine.states)
                {
                    AnimationClip stateClip = child.state.motion as AnimationClip;
                    if (stateClip != null && string.Equals(AssetDatabase.GetAssetPath(stateClip), clipPath,
                        StringComparison.OrdinalIgnoreCase)) return true;
                }
            return false;
        }

        private static void ValidateClipTargets(GameObject prefab, AnimationClip clip, string clipPath)
        {
            EditorCurveBinding[] floatBindings = AnimationUtility.GetCurveBindings(clip);
            EditorCurveBinding[] objectBindings = AnimationUtility.GetObjectReferenceCurveBindings(clip);
            if (floatBindings.Length + objectBindings.Length == 0)
                throw new InvalidDataException("Unity Draw AnimationClip contains no curves: " + clipPath);

            foreach (EditorCurveBinding binding in floatBindings)
            {
                Transform target = string.IsNullOrEmpty(binding.path) ? prefab.transform : prefab.transform.Find(binding.path);
                if (target == null)
                    throw new InvalidDataException("Draw AnimationClip target is absent from its Unity Prefab: "
                        + clipPath + " -> " + binding.path);
                AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                if (curve == null)
                    throw new InvalidDataException("Draw AnimationClip curve is missing: " + clipPath + " -> " + binding.path);
                foreach (Keyframe key in curve.keys)
                    if (float.IsNaN(key.value) || float.IsInfinity(key.value))
                        throw new InvalidDataException("Draw AnimationClip contains a non-finite key: "
                            + clipPath + " -> " + binding.path);
            }

            foreach (EditorCurveBinding binding in objectBindings)
            {
                Transform target = string.IsNullOrEmpty(binding.path) ? prefab.transform : prefab.transform.Find(binding.path);
                if (target == null)
                    throw new InvalidDataException("Draw object-reference curve target is absent from its Unity Prefab: "
                        + clipPath + " -> " + binding.path);
                if (AnimationUtility.GetObjectReferenceCurve(clip, binding) == null)
                    throw new InvalidDataException("Draw object-reference curve is missing: " + clipPath + " -> " + binding.path);
            }
        }

        private sealed class AnimationEntry
        {
            public AnimationEntry(string prefabPath, string controllerPath, string clipPath)
            {
                PrefabPath = prefabPath;
                ControllerPath = controllerPath;
                ClipPath = clipPath;
            }

            public string PrefabPath { get; }
            public string ControllerPath { get; }
            public string ClipPath { get; }
        }
    }
}
#endif
