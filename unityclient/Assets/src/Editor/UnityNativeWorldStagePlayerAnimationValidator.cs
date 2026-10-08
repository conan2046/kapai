#if UNITY_EDITOR
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class UnityNativeWorldStagePlayerAnimationValidator
    {
        private const string AssetRoot = "Assets/Animations/World/StagePlayer";
        private const string AnimationRoot = AssetRoot + "/Animations";
        private static readonly string[] ExpectedModels = { "H_0_fd", "K_0_fd", "H_0_pb", "K_0_pb" };

        public static string ValidateForMcp()
        {
            int controllers = 0;
            int clips = 0;
            int spriteKeys = 0;
            foreach (string model in ExpectedModels)
            {
                string path = AnimationRoot + "/" + model + ".controller";
                AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(path);
                if (controller == null || controller.layers.Length == 0)
                    throw new InvalidOperationException($"Missing World stage player controller: {model}");
                AnimatorStateMachine machine = controller.layers[0].stateMachine;
                AnimatorState[] states = machine.states.Select(item => item.state).Where(item => item != null).ToArray();
                if (states.Length != 5 || machine.defaultState == null || machine.defaultState.name != "Action_4")
                    throw new InvalidOperationException($"{model} must contain actions 0-4 with Action_4 as default.");
                foreach (AnimatorState state in states)
                {
                    AnimationClip clip = state.motion as AnimationClip;
                    if (clip == null || !AnimationUtility.GetAnimationClipSettings(clip).loopTime)
                        throw new InvalidOperationException($"{model}/{state.name} is not a looping AnimationClip.");
                    EditorCurveBinding binding = AnimationUtility.GetObjectReferenceCurveBindings(clip)
                        .FirstOrDefault(value => value.path == "FacingRoot/Visual" && value.propertyName == "m_Sprite");
                    ObjectReferenceKeyframe[] keys = string.IsNullOrEmpty(binding.path)
                        ? Array.Empty<ObjectReferenceKeyframe>()
                        : AnimationUtility.GetObjectReferenceCurve(clip, binding);
                    if (keys.Length == 0 || keys.Any(key => key.value == null
                        || !AssetDatabase.GetAssetPath(key.value).StartsWith(
                            AssetRoot + "/Art/hero/", StringComparison.Ordinal)))
                        throw new InvalidOperationException($"{model}/{state.name} has invalid native Sprite keys.");
                    EditorCurveBinding[] geometry = AnimationUtility.GetCurveBindings(clip);
                    if (!geometry.Any(binding => binding.path == "FacingRoot/Visual" && binding.propertyName == "m_SizeDelta.x")
                        || !geometry.Any(binding => binding.path == "FacingRoot/Visual" && binding.propertyName == "m_SizeDelta.y")
                        || !geometry.Any(binding => binding.path == "FacingRoot/Visual" && binding.propertyName == "m_AnchoredPosition.x")
                        || !geometry.Any(binding => binding.path == "FacingRoot/Visual" && binding.propertyName == "m_AnchoredPosition.y"))
                        throw new InvalidOperationException($"{model}/{state.name} is missing frame geometry curves.");
                    spriteKeys += keys.Length;
                    clips++;
                }
                int expectedSprites = model.StartsWith("H_", StringComparison.Ordinal) ? 40 : 35;
                int actualSprites = AssetDatabase.LoadAllAssetsAtPath(
                        AssetRoot + "/Art/hero/" + model + ".png")
                    .OfType<Sprite>().Count();
                if (actualSprites != expectedSprites)
                    throw new InvalidOperationException($"{model} expected {expectedSprites} atlas Sprites, found {actualSprites}.");
                if (AssetDatabase.GetDependencies(path, true).Any(dependency =>
                    dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase)
                    || dependency.Contains("/ProjectXAnimation/")))
                    throw new InvalidOperationException($"{model} still depends on legacy animation resources.");
                controllers++;
            }

            if (controllers != 4 || clips != 20 || spriteKeys != 150)
                throw new InvalidOperationException(
                    $"Unexpected World stage player assets: {controllers} controllers, {clips} clips, {spriteKeys} Sprite keys.");
            return $"Validated {controllers} Unity-native World stage-player controllers, {clips} looping Actions, and {spriteKeys} Sprite keys; no Cocos resource dependency.";
        }
    }
}
#endif
