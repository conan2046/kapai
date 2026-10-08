#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>
    /// Read-only checks for the Unity-authored XunBao Prefabs, Animator Controllers, and AnimationClips.
    /// Does not import, convert, copy, or compare against Cocos assets.
    /// </summary>
    public static class XunBaoNativeAnimationAssetValidator
    {
        private const string MainPrefab = "Assets/Prefabs/XunBao/XunbaoLayer.prefab";
        private const string PopupPrefab = "Assets/Prefabs/XunBao/Xunbao_popupLayer.prefab";
        private const string ComposeAllPrefab = "Assets/Prefabs/XunBao/saodang.prefab";
        private const string ResultPrefab = "Assets/Prefabs/XunBao/Xunbao_souxunLayer.prefab";
        private const string MainController = "Assets/Animations/XunBao/XunbaoLayer.controller";
        private const string PopupController = "Assets/Animations/XunBao/PopupAnimations/XunbaoPopup.controller";
        private const string ComposeAllController = "Assets/Animations/XunBao/SaoDangComposeAll.controller";
        private const string MainAnimationFolder = "Assets/Animations/XunBao";
        private const string PopupAnimationFolder = "Assets/Animations/XunBao/PopupAnimations";

        private static readonly string[] MainClips =
        {
            "RedOpen", "OrangeOpen", "PurpleOpen", "BlueOpen",
            "RedCompose", "OrangeCompose", "PurpleCompose", "BlueCompose"
        };

        [MenuItem("Tools/ProjectX/Validate Unity XunBao Native Assets")]
        public static void ValidateAll()
        {
            ValidateMain();
            ValidatePopup();
            ValidateComposeAll();
            ValidateResult();
            Debug.Log("Unity-native XunBao Prefabs, Animator Controllers, and AnimationClips validated.");
        }

        public static void ValidateMain()
        {
            ValidatePrefabAndController(MainPrefab, MainController, MainClips
                .Select(name => MainAnimationFolder + "/" + name + ".anim").ToArray());
        }

        public static void ValidatePopup()
        {
            ValidatePrefabAndController(PopupPrefab, PopupController, new[]
            {
                PopupAnimationFolder + "/ComposePopup.anim"
            });
        }

        public static void ValidateComposeAll()
        {
            ValidatePrefabAndController(ComposeAllPrefab, ComposeAllController, new[]
            {
                MainAnimationFolder + "/SaoDangComposeAll.anim"
            });
        }

        public static void ValidateResult()
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(ResultPrefab);
            if (prefab == null) throw new FileNotFoundException("Unity-owned XunBao result Prefab is missing: " + ResultPrefab);
            foreach (string dependency in AssetDatabase.GetDependencies(ResultPrefab, true))
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Unity-owned XunBao result Prefab depends on the legacy resource tree: " + dependency);
            GameObject root = PrefabUtility.LoadPrefabContents(ResultPrefab);
            try
            {
                foreach (Component component in root.GetComponentsInChildren<Component>(true))
                {
                    if (component == null)
                        throw new InvalidDataException("Unity-owned XunBao result Prefab contains a missing script.");
                    string typeName = component.GetType().Name;
                    if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer" || typeName == "CocosUiBinding")
                        throw new InvalidDataException("Unity-owned XunBao result Prefab contains Cocos component " + typeName);
                }
                XunBaoResultViewBindings bindings = root.GetComponent<XunBaoResultViewBindings>();
                if (bindings == null || bindings.ListView == null || bindings.RewardTemplate == null
                    || bindings.ItemTemplate == null || bindings.LegacyBottomButton == null || bindings.CloseButton == null)
                    throw new InvalidDataException("Unity-owned XunBao result Prefab has incomplete serialized bindings.");
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static void ValidatePrefabAndController(string prefabPath, string controllerPath, string[] clipPaths)
        {
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
            if (prefab == null) throw new FileNotFoundException("Unity-owned XunBao Prefab is missing: " + prefabPath);

            RuntimeAnimatorController runtimeController = AssetDatabase.LoadAssetAtPath<RuntimeAnimatorController>(controllerPath);
            if (runtimeController == null) throw new FileNotFoundException("Unity-owned XunBao Animator Controller is missing: " + controllerPath);

            var requiredClips = new HashSet<string>(clipPaths, StringComparer.OrdinalIgnoreCase);
            foreach (string path in clipPaths)
            {
                AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(path);
                if (clip == null) throw new FileNotFoundException("Unity-authored XunBao AnimationClip is missing: " + path);
                ValidateClipAgainstPrefab(prefab, clip, path);
            }

            AnimatorController animatorController = runtimeController as AnimatorController;
            if (animatorController == null)
                throw new InvalidDataException("XunBao controller is not a Unity AnimatorController: " + controllerPath);
            var referencedClips = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (AnimatorControllerLayer layer in animatorController.layers)
            {
                foreach (ChildAnimatorState child in layer.stateMachine.states)
                {
                    AnimationClip stateClip = child.state.motion as AnimationClip;
                    if (stateClip == null) continue;
                    referencedClips.Add(AssetDatabase.GetAssetPath(stateClip));
                }
            }
            foreach (string clipPath in requiredClips)
                if (!referencedClips.Contains(clipPath))
                    throw new InvalidDataException("XunBao Animator Controller does not reference required clip: " + clipPath);

            foreach (string dependency in AssetDatabase.GetDependencies(prefabPath, true))
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Unity-owned XunBao Prefab depends on the legacy resource tree: " + dependency);

            GameObject root = PrefabUtility.LoadPrefabContents(prefabPath);
            try
            {
                Animator animator = root.GetComponent<Animator>();
                if (animator == null || animator.runtimeAnimatorController == null)
                    throw new InvalidDataException("Unity-owned XunBao Prefab has no root Animator/controller: " + prefabPath);
                foreach (Component component in root.GetComponentsInChildren<Component>(true))
                {
                    if (component == null)
                        throw new InvalidDataException("Unity-owned XunBao Prefab has a missing component: " + prefabPath);
                    string typeName = component.GetType().Name;
                    if (typeName == "UiPrefabIdentity" || typeName == "CocosTimelinePlayer" || typeName == "CocosUiBinding")
                        throw new InvalidDataException("Unity-owned XunBao Prefab contains a Cocos component " + typeName + ": " + prefabPath);
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static void ValidateClipAgainstPrefab(GameObject prefab, AnimationClip clip, string clipPath)
        {
            if (clip.length <= 0f)
                throw new InvalidDataException("Unity-authored XunBao AnimationClip is empty: " + clipPath);
            EditorCurveBinding[] bindings = AnimationUtility.GetCurveBindings(clip);
            if (bindings.Length == 0)
                throw new InvalidDataException("Unity-authored XunBao AnimationClip has no transform curves: " + clipPath);
            foreach (EditorCurveBinding binding in bindings)
            {
                Transform target = string.IsNullOrEmpty(binding.path)
                    ? prefab.transform
                    : prefab.transform.Find(binding.path);
                if (target == null)
                    throw new InvalidDataException("XunBao animation target is absent from Unity Prefab: " + clipPath + " -> " + binding.path);
                AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                if (curve == null) throw new InvalidDataException("XunBao animation curve is missing: " + clipPath + " -> " + binding.path);
                foreach (Keyframe key in curve.keys)
                    if (float.IsNaN(key.value) || float.IsInfinity(key.value))
                        throw new InvalidDataException("XunBao animation curve has a non-finite value: " + clipPath + " -> " + binding.path);
            }
        }
    }
}
#endif
