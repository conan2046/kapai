using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class UnityNativeHeroAnimationValidator
    {
        private const string AnimationRoot = "Assets/Animations/HeroModels/Monster";

        [MenuItem("Tools/ProjectX/Animation/Validate Hero Detail Native Assets")]
        public static void ValidateHeroDetailNativeAssets()
        {
            Debug.Log(ValidateHeroDetailNativeAssetsForMcp());
        }

        public static string ValidateHeroDetailNativeAssetsForMcp()
        {
            string[] paths = AssetDatabase.FindAssets("t:AnimatorController", new[] { AnimationRoot })
                .Select(AssetDatabase.GUIDToAssetPath)
                .Where(path => Path.GetFileNameWithoutExtension(path).EndsWith("_zd_show", StringComparison.OrdinalIgnoreCase))
                .OrderBy(path => path, StringComparer.Ordinal)
                .ToArray();
            int clips = 0;
            int spriteKeys = 0;
            foreach (string path in paths)
            {
                AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(path);
                AnimationClip clip = controller != null && controller.layers.Length > 0
                    ? controller.layers[0].stateMachine.defaultState?.motion as AnimationClip
                    : null;
                if (clip == null) throw new InvalidOperationException($"Hero native controller has no default clip: {path}");
                if (!AnimationUtility.GetAnimationClipSettings(clip).loopTime)
                    throw new InvalidOperationException($"Hero native detail clip is not looping: {path}");
                EditorCurveBinding[] objectBindings = AnimationUtility.GetObjectReferenceCurveBindings(clip);
                EditorCurveBinding[] floatBindings = AnimationUtility.GetCurveBindings(clip);
                if (!objectBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_Sprite")
                    || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_SizeDelta.x")
                    || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_SizeDelta.y")
                    || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_AnchoredPosition.x")
                    || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_AnchoredPosition.y"))
                    throw new InvalidOperationException($"Hero native detail clip is missing Sprite or geometry curves: {path}");
                int keys = objectBindings
                    .Where(binding => binding.path == "Visual" && binding.propertyName == "m_Sprite")
                    .Sum(binding => AnimationUtility.GetObjectReferenceCurve(clip, binding)?.Length ?? 0);
                if (keys == 0) throw new InvalidOperationException($"Hero native detail clip has no Sprite keys: {path}");
                spriteKeys += keys;
                clips++;
            }
            if (clips != 69) throw new InvalidOperationException($"Expected 69 Hero native detail controllers, found {clips}.");
            return $"Validated {clips} Unity-native Hero detail controllers and {spriteKeys} Sprite keys. No Cocos source is read.";
        }

        [MenuItem("Tools/ProjectX/Animation/Validate Hero Formation Native Assets")]
        public static void ValidateHeroFormationNativeAssets()
        {
            Debug.Log(ValidateHeroFormationNativeAssetsForMcp());
        }

        public static string ValidateHeroFormationNativeAssetsForMcp()
        {
            string[] paths = AssetDatabase.FindAssets("t:AnimatorController", new[] { AnimationRoot })
                .Select(AssetDatabase.GUIDToAssetPath)
                .Where(path => Path.GetFileNameWithoutExtension(path).EndsWith("_zd", StringComparison.OrdinalIgnoreCase)
                    && !Path.GetFileNameWithoutExtension(path).EndsWith("_zd_show", StringComparison.OrdinalIgnoreCase))
                .OrderBy(path => path, StringComparer.Ordinal)
                .ToArray();
            int clips = 0;
            int spriteKeys = 0;
            int actionOneControllers = 0;
            foreach (string path in paths)
            {
                AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(path);
                AnimatorStateMachine machine = controller != null && controller.layers.Length > 0
                    ? controller.layers[0].stateMachine
                    : null;
                if (machine == null) throw new InvalidOperationException($"Hero formation controller has no state machine: {path}");
                AnimatorState[] states = machine.states.Select(item => item.state).Where(state => state != null).ToArray();
                if (states.Any(state => state.name == "Action_1")) actionOneControllers++;
                if (!states.Any(state => state.name == "Action_0"))
                    throw new InvalidOperationException($"Hero formation controller is missing Action_0: {path}");
                foreach (AnimatorState state in states)
                {
                    AnimationClip clip = state.motion as AnimationClip;
                    if (clip == null) throw new InvalidOperationException($"Hero formation action is not an AnimationClip: {path}/{state.name}");
                    if (!AnimationUtility.GetAnimationClipSettings(clip).loopTime)
                        throw new InvalidOperationException($"Hero formation action is not looping: {clip.name}");
                    EditorCurveBinding spriteBinding = AnimationUtility.GetObjectReferenceCurveBindings(clip)
                        .FirstOrDefault(binding => binding.path == "Visual" && binding.propertyName == "m_Sprite");
                    if (string.IsNullOrEmpty(spriteBinding.path))
                        throw new InvalidOperationException($"Hero formation action has no Sprite curve: {clip.name}");
                    ObjectReferenceKeyframe[] keys = AnimationUtility.GetObjectReferenceCurve(clip, spriteBinding);
                    if (keys == null || keys.Length == 0 || keys.Any(key => key.value == null
                        || !AssetDatabase.GetAssetPath(key.value).StartsWith(
                            "Assets/Art/AnimationFrames/HeroModels/Monster/", StringComparison.Ordinal)))
                        throw new InvalidOperationException($"Hero formation action has invalid Sprite references: {clip.name}");
                    EditorCurveBinding[] floatBindings = AnimationUtility.GetCurveBindings(clip);
                    if (!floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_SizeDelta.x")
                        || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_SizeDelta.y")
                        || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_AnchoredPosition.x")
                        || !floatBindings.Any(binding => binding.path == "Visual" && binding.propertyName == "m_AnchoredPosition.y"))
                        throw new InvalidOperationException($"Hero formation action is missing geometry curves: {clip.name}");
                    spriteKeys += keys.Length;
                    clips++;
                }
                if (AssetDatabase.GetDependencies(path, true).Any(dependency =>
                    dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase)
                    || dependency.Contains("/ProjectXAnimation/")))
                    throw new InvalidOperationException($"Hero formation controller still depends on converted Imod resources: {path}");
            }
            if (paths.Length != 72 || clips != 152 || spriteKeys != 1209 || actionOneControllers != 71)
                throw new InvalidOperationException(
                    $"Unexpected Hero formation asset counts: controllers={paths.Length}, actions={clips}, sprites={spriteKeys}, Action_1={actionOneControllers}.");
            return $"Validated {paths.Length} Unity-native Hero formation controllers, {clips} looping actions, and {spriteKeys} Sprite keys. "
                + "Action_1 is available for 71 controllers; the remaining one uses its only Action_0. No Imod source is read.";
        }
    }
}
