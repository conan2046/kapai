#if UNITY_EDITOR
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class UnityNativeFishAnimationValidator
    {
        private const string AssetRoot = "Assets/Animations/Fish";
        private const string AnimationRoot = AssetRoot;

        public static string ValidateForMcp()
        {
            string[] paths = AssetDatabase.FindAssets("t:AnimatorController", new[] { AnimationRoot })
                .Select(AssetDatabase.GUIDToAssetPath)
                .OrderBy(path => path, StringComparer.Ordinal)
                .ToArray();
            if (paths.Length != 1 || Path.GetFileNameWithoutExtension(paths[0]) != "btm2000_zd")
                throw new InvalidOperationException($"Expected one Fish controller, found {paths.Length}.");

            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(paths[0]);
            AnimatorStateMachine machine = controller != null && controller.layers.Length > 0
                ? controller.layers[0].stateMachine
                : null;
            AnimatorState state = machine?.states.Select(item => item.state)
                .FirstOrDefault(item => item != null && item.name == "Action_2");
            AnimationClip clip = state?.motion as AnimationClip;
            if (clip == null || machine.defaultState != state)
                throw new InvalidOperationException("Fish controller default state is not Action_2.");
            if (!AnimationUtility.GetAnimationClipSettings(clip).loopTime)
                throw new InvalidOperationException("Fish Action_2 clip is not looping.");

            EditorCurveBinding spriteBinding = AnimationUtility.GetObjectReferenceCurveBindings(clip)
                .FirstOrDefault(binding => binding.path == "Visual" && binding.propertyName == "m_Sprite");
            ObjectReferenceKeyframe[] keys = string.IsNullOrEmpty(spriteBinding.path)
                ? Array.Empty<ObjectReferenceKeyframe>()
                : AnimationUtility.GetObjectReferenceCurve(clip, spriteBinding);
            if (keys.Length != 8 || keys.Any(key => key.value == null
                || !AssetDatabase.GetAssetPath(key.value).StartsWith(
                    AssetRoot + "/Art/", StringComparison.Ordinal)))
                throw new InvalidOperationException($"Fish Action_2 has invalid Sprite keys: {keys.Length}.");

            string atlasPath = AssetRoot + "/Art/Monster/btm2000_zd.png";
            int sprites = AssetDatabase.LoadAllAssetsAtPath(atlasPath).OfType<Sprite>().Count();
            if (sprites != 40)
                throw new InvalidOperationException($"Expected 40 Fish atlas Sprites, found {sprites}.");
            if (AssetDatabase.GetDependencies(paths[0], true).Any(path =>
                path.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase)
                || path.Contains("/ProjectXAnimation/")))
                throw new InvalidOperationException("Fish native animation depends on legacy Cocos animation resources.");

            ValidateHiddenPageInitialization();
            return $"Validated Fish Unity Animator: 1 controller, Action_2 looping clip, {keys.Length} Sprite keys, {sprites} atlas Sprites; hidden-page initialization passed; no Cocos animation dependency.";
        }

        private static void ValidateHiddenPageInitialization()
        {
            GameObject page = new GameObject("FishHiddenPageValidation", typeof(RectTransform));
            page.SetActive(false);
            try
            {
                GameObject model = new GameObject("FishModel", typeof(RectTransform));
                model.transform.SetParent(page.transform, false);
                var animation = model.AddComponent<ProjectX.UI.UnityNativeFishAnimation>();
                if (!animation.LoadFishingShape())
                    throw new InvalidOperationException("Fish Action_2 cannot initialize beneath a hidden page.");
                var image = model.GetComponentInChildren<UnityEngine.UI.Image>(true);
                if (image == null || image.sprite == null || image.rectTransform.rect.height <= 0f)
                    throw new InvalidOperationException("Fish hidden-page first frame is missing Sprite or geometry.");
                page.SetActive(true);
                Animator animator = model.GetComponent<Animator>();
                animator.Update(0f);
                if (!animator.GetCurrentAnimatorStateInfo(0).IsName("Action_2"))
                    throw new InvalidOperationException("Fish page activation does not retain Action_2.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(page);
            }
        }
    }
}
#endif
