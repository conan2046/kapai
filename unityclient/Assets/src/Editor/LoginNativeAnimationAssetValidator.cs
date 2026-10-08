#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    /// <summary>
    /// Validates hand-maintained Unity Login animation assets. These clips and
    /// sprites are the authoring source; legacy Imod data is not read here.
    /// </summary>
    public static class LoginNativeAnimationAssetValidator
    {
        private const string ResourceRoot = "Assets/Animations/Login";
        private const string SpriteRoot = "Assets/Art/AnimationFrames/Login/SpriteFrames";
        private const string AnimationRoot = ResourceRoot + "/AnimationClips";
        private const string ControllerRoot = ResourceRoot + "/Controllers";

        [MenuItem("Tools/ProjectX 界面/验证 Login Unity 动画")]
        public static void Validate()
        {
            ValidateClip("LoginTitleEffect", 10);
            ValidateClip("Create_5", 7);
            ValidateClip("Create_4", 8);
            ValidateController("LoginTitleEffect", new Dictionary<string, string>
            {
                ["Loop"] = "LoginTitleEffect"
            });
            ValidateController("RoleCreateEffect", new Dictionary<string, string>
            {
                ["Loop"] = "LoginTitleEffect"
            });
            ValidateController("RoleCreateCharacter", new Dictionary<string, string>
            {
                ["Male"] = "Create_5",
                ["Female"] = "Create_4"
            });
            Debug.Log("Login Unity animation assets validated: native Sprite frames, 3 looping clips, and 3 Animator Controllers.");
        }

        private static void ValidateClip(string name, int expectedFrameCount)
        {
            string path = AnimationRoot + "/" + name + ".anim";
            AnimationClip clip = AssetDatabase.LoadAssetAtPath<AnimationClip>(path);
            if (clip == null) throw new InvalidOperationException("Unity Login animation clip is missing: " + path);
            if (Mathf.Abs(clip.frameRate - 30f) > 0.001f || !AnimationUtility.GetAnimationClipSettings(clip).loopTime)
                throw new InvalidOperationException("Unity Login animation must be a looping 30 FPS clip: " + name);

            ObjectReferenceKeyframe[] keys = AnimationUtility.GetObjectReferenceCurve(clip,
                EditorCurveBinding.PPtrCurve(string.Empty, typeof(Image), "m_Sprite"));
            if (keys == null || keys.Length != expectedFrameCount + 1)
                throw new InvalidOperationException("Unity Login Sprite key count differs for " + name);

            string expectedSpriteRoot = SpriteRoot + "/" + name + "/";
            float previousTime = -1f;
            foreach (ObjectReferenceKeyframe key in keys)
            {
                if (!(key.value is Sprite sprite))
                    throw new InvalidOperationException("Unity Login animation has an empty Sprite key: " + name);
                string spritePath = AssetDatabase.GetAssetPath(sprite);
                if (!spritePath.StartsWith(expectedSpriteRoot, StringComparison.Ordinal))
                    throw new InvalidOperationException("Unity Login animation references a non-native Sprite: " + spritePath);
                if (key.time <= previousTime)
                    throw new InvalidOperationException("Unity Login Sprite keys are not strictly ordered: " + name);
                previousTime = key.time;
            }
            if (Mathf.Abs(keys[0].time) > 0.001f
                || Mathf.Abs(keys[keys.Length - 1].time - (clip.length - 1f / clip.frameRate)) > 0.001f)
                throw new InvalidOperationException("Unity Login animation loop boundary is invalid: " + name);

            RequireCurve(clip, "m_AnchoredPosition.x");
            RequireCurve(clip, "m_AnchoredPosition.y");
            RequireCurve(clip, "m_SizeDelta.x");
            RequireCurve(clip, "m_SizeDelta.y");
        }

        private static void RequireCurve(AnimationClip clip, string property)
        {
            AnimationCurve curve = AnimationUtility.GetEditorCurve(clip,
                EditorCurveBinding.FloatCurve(string.Empty, typeof(RectTransform), property));
            if (curve == null || curve.length == 0)
                throw new InvalidOperationException("Unity Login Transform curve is missing: " + clip.name + "/" + property);
        }

        private static void ValidateController(string name, IReadOnlyDictionary<string, string> expectedStates)
        {
            string path = ControllerRoot + "/" + name + ".controller";
            AnimatorController controller = AssetDatabase.LoadAssetAtPath<AnimatorController>(path);
            if (controller == null || controller.layers.Length == 0)
                throw new InvalidOperationException("Unity Login Animator Controller is missing: " + path);

            ChildAnimatorState[] states = controller.layers[0].stateMachine.states;
            foreach (KeyValuePair<string, string> expected in expectedStates)
            {
                AnimatorState state = null;
                foreach (ChildAnimatorState candidate in states)
                    if (candidate.state != null && candidate.state.name == expected.Key)
                    {
                        state = candidate.state;
                        break;
                    }
                AnimationClip expectedClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(
                    AnimationRoot + "/" + expected.Value + ".anim");
                if (state == null || expectedClip == null || state.motion != expectedClip)
                    throw new InvalidOperationException("Unity Login Animator state references the wrong clip: "
                        + name + "/" + expected.Key);
            }
        }
    }
}
#endif
