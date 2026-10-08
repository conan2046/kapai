#if UNITY_EDITOR
using System;
using System.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    /// <summary>
    /// Validates the Unity-authored Main cloud animation chain. Edit CloudLoop.anim
    /// in Unity's Animation window; this validator never regenerates assets.
    /// </summary>
    public static class MainCloudAnimationAssetBuilder
    {
        private const string NativePrefabPath = "Assets/Prefabs/Main/UImain_cloudLayer.prefab";
        private const string SpriteRoot = "Assets/Art/UI/";
        private const string ClipPath = "Assets/Animations/Main/CloudLoop.anim";
        private const string ControllerPath = "Assets/Animations/Main/CloudLoop.controller";
        private const string ReferencePath = "Assets/Prefabs/Catalog/UImain_cloudLayer.asset";
        private const string ClipName = "CloudLoop";

        private static readonly string[] ExpectedPaths =
        {
            "CloudPanel/Image_1",
            "CloudPanel/Image_2",
            "CloudPanel/Image_3",
            "CloudPanel/Image_4"
        };

        private static readonly string[] ExpectedProperties =
        {
            "m_AnchorMin.x",
            "m_AnchorMin.y",
            "m_AnchorMax.x",
            "m_AnchorMax.y",
            "m_AnchoredPosition.x",
            "m_AnchoredPosition.y"
        };

        [MenuItem("Tools/ProjectX 界面/验证 Main 云层 Unity 动画资源")]
        public static void ValidateAssets()
        {
            AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(ClipPath);
            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(ControllerPath);
            GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(NativePrefabPath);
            UiPrefabReference reference = AssetDatabase.LoadAssetAtPath<UiPrefabReference>(ReferencePath);
            if (clip == null || controller == null || prefab == null || reference == null || reference.Prefab != prefab)
                throw new InvalidOperationException("Unity-native Main cloud resource chain is incomplete.");
            if (!AnimationUtility.GetAnimationClipSettings(clip).loopTime
                || Mathf.Abs(clip.frameRate - 30f) > 0.001f)
                throw new InvalidOperationException("Main cloud Clip must be a looping 30 FPS Unity AnimationClip.");

            EditorCurveBinding[] bindings = AnimationUtility.GetCurveBindings(clip);
            string[] paths = bindings.Select(binding => binding.path)
                .Distinct(StringComparer.Ordinal).OrderBy(path => path, StringComparer.Ordinal).ToArray();
            string[] expectedPaths = ExpectedPaths.OrderBy(path => path, StringComparer.Ordinal).ToArray();
            if (!paths.SequenceEqual(expectedPaths) || bindings.Length != ExpectedPaths.Length * ExpectedProperties.Length)
                throw new InvalidOperationException("Main cloud Clip bindings do not match its four Unity Image nodes.");
            foreach (string path in ExpectedPaths)
            {
                EditorCurveBinding[] pathBindings = bindings.Where(binding => binding.path == path).ToArray();
                string[] properties = pathBindings.Select(binding => binding.propertyName)
                    .Distinct(StringComparer.Ordinal).OrderBy(value => value, StringComparer.Ordinal).ToArray();
                string[] expectedProperties = ExpectedProperties.OrderBy(value => value, StringComparer.Ordinal).ToArray();
                if (pathBindings.Any(binding => binding.type != typeof(RectTransform))
                    || !properties.SequenceEqual(expectedProperties))
                    throw new InvalidOperationException("Main cloud Clip has an unexpected Unity curve set: " + path);
                foreach (EditorCurveBinding binding in pathBindings)
                {
                    AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                    int minimumKeys = binding.propertyName.StartsWith("m_AnchoredPosition.", StringComparison.Ordinal)
                        ? 1 : 2;
                    if (curve == null || curve.length < minimumKeys)
                        throw new InvalidOperationException("Main cloud Clip curve is empty: " + path + "/" + binding.propertyName);
                }
            }

            AnimatorStateMachine machine = controller.layers[0].stateMachine;
            AnimatorState expectedState = machine.states.Select(item => item.state)
                .FirstOrDefault(state => state != null && state.name == ClipName);
            if (expectedState == null || machine.defaultState != expectedState || expectedState.motion != clip)
                throw new InvalidOperationException("Unity-native Main cloud Animator Controller has the wrong default state.");

            GameObject root = PrefabUtility.LoadPrefabContents(NativePrefabPath);
            try
            {
                Animator animator = root.GetComponent<Animator>();
                MonoBehaviour[] scripts = root.GetComponentsInChildren<MonoBehaviour>(true);
                if (animator == null || animator.runtimeAnimatorController != controller
                    || scripts.Any(component => component != null
                        && (component.GetType().Namespace == null
                            || !component.GetType().Namespace.StartsWith("UnityEngine.", StringComparison.Ordinal))))
                    throw new InvalidOperationException("Unity-native Main cloud Prefab must use the Unity Animator and Unity Engine components only.");

                foreach (string path in ExpectedPaths)
                {
                    Transform target = root.transform.Find(path);
                    Image image = target != null ? target.GetComponent<Image>() : null;
                    if (image == null || image.sprite == null
                        || !AssetDatabase.GetAssetPath(image.sprite).StartsWith(SpriteRoot, StringComparison.Ordinal))
                        throw new InvalidOperationException("Main cloud Sprite is missing or outside Unity-owned assets: " + path);
                }
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }

            string[] dependencies = AssetDatabase.GetDependencies(NativePrefabPath, true);
            foreach (string dependency in dependencies)
                if (dependency.StartsWith("Assets/ProjectX/res/", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("Unity-native Main cloud Prefab still depends on imported Cocos asset: " + dependency);
            Debug.Log("Unity-native Main cloud resource chain validated. Edit CloudLoop.anim in the Unity Animation window; this check does not regenerate it.");
        }
    }
}
#endif
