using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json.Linq;
using Spine.Unity;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;
using ProjectX.UI;
using ProjectX.Data;

namespace ProjectX.Editor
{
    public static class JingJieSpineAssetBuilder
    {
        [MenuItem("Tools/ProjectX 资源/构建境界 Spine 展示预制体")]
        public static void Build()
        {
            if (EditorApplication.isPlaying) throw new InvalidOperationException("Build Spine assets in Edit mode.");
            string output = "Assets/Prefabs/Spine/UI/Role";
            foreach (string guid in AssetDatabase.FindAssets("t:Texture2D", new[] { "Assets/Art/Spine" }))
            {
                var importer = (TextureImporter)AssetImporter.GetAtPath(AssetDatabase.GUIDToAssetPath(guid));
                string directory = Path.GetDirectoryName(AssetDatabase.GUIDToAssetPath(guid)).Replace('\\', '/');
                var material = AssetDatabase.FindAssets("t:Material", new[] { directory })
                    .Select(AssetDatabase.GUIDToAssetPath).Select(AssetDatabase.LoadAssetAtPath<Material>).First();
                bool straight = material.GetFloat("_StraightAlphaInput") > 0;
                if (importer.alphaIsTransparency == straight) continue;
                importer.alphaIsTransparency = straight;
                importer.SaveAndReimport();
            }
            Directory.CreateDirectory(output);
            AssetDatabase.Refresh();
            Material uiMaterial = AssetDatabase.LoadAssetAtPath<Material>(
                "Assets/Plugins/Spine/Runtime/spine-unity/Materials/SkeletonGraphicDefault.mat");
            if (uiMaterial == null) throw new InvalidOperationException("Spine UI material is missing.");
            Directory.CreateDirectory("Assets/Art/Spine/Materials");
            string materialPath = "Assets/Art/Spine/Materials/JingJieSkeletonGraphicStraightAlpha.mat";
            Material straightMaterial = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
            if (straightMaterial == null)
            {
                straightMaterial = new Material(uiMaterial);
                straightMaterial.SetFloat("_StraightAlphaInput", 1);
                straightMaterial.EnableKeyword("_STRAIGHT_ALPHA_INPUT");
                AssetDatabase.CreateAsset(straightMaterial, materialPath);
            }
            string settings = Path.GetFullPath("ProjectSettings/ProjectXAssetReferences.json");
            JArray references = JArray.Parse(File.ReadAllText(settings));
            var rows = new List<object>();
            foreach (string path in AssetDatabase.FindAssets("t:Prefab", new[] { "Assets/Prefabs/Spine/Role", "Assets/Prefabs/Spine/Wings" })
                .Select(AssetDatabase.GUIDToAssetPath).OrderBy(value => value, StringComparer.Ordinal))
            {
                GameObject source = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                SkeletonAnimation skeleton = source.GetComponentInChildren<SkeletonAnimation>(true);
                if (skeleton == null || skeleton.skeletonDataAsset == null)
                    throw new InvalidOperationException("Missing Spine component/data: " + path);
                if (source.name == "zmls_001")
                {
                    rows.Add(new { path, passed = false, reason = "Source package omits zmls_001.png; not used by JingJie." });
                    continue;
                }
                var data = skeleton.skeletonDataAsset.GetSkeletonData(false);
                if (data == null || data.Animations.Count == 0)
                    throw new InvalidOperationException("Spine asset cannot play: " + path);
                string animation = skeleton.AnimationName;
                if (string.IsNullOrEmpty(animation) || data.FindAnimation(animation) == null)
                    animation = data.Animations.Items[0].Name;
                if (skeleton.skeletonDataAsset.atlasAssets.Any(atlas => atlas.Materials.Any(
                    material => material == null || material.mainTexture == null)))
                    throw new InvalidOperationException("Missing Spine texture/material: " + path);
                // Imported MeshRenderers refer to an omitted shared material; use the skeleton's own atlas.
                GameObject contents = PrefabUtility.LoadPrefabContents(path);
                try
                {
                    foreach (SkeletonAnimation component in contents.GetComponentsInChildren<SkeletonAnimation>(true))
                    {
                        component.GetComponent<MeshRenderer>().sharedMaterials = component.skeletonDataAsset.atlasAssets
                            .SelectMany(atlas => atlas.Materials).ToArray();
                        component.AnimationName = animation;
                        component.loop = true;
                    }
                    PrefabUtility.SaveAsPrefabAsset(contents, path);
                }
                finally { PrefabUtility.UnloadPrefabContents(contents); }
                rows.Add(new { path, passed = true, animation, duration = data.FindAnimation(animation).Duration });
                if (!source.name.StartsWith("role_m_", StringComparison.Ordinal)
                    && !source.name.StartsWith("role_w_", StringComparison.Ordinal)) continue;
                var node = new GameObject(source.name, typeof(RectTransform), typeof(CanvasRenderer));
                try
                {
                    SkeletonGraphic graphic = node.AddComponent<SkeletonGraphic>();
                    graphic.skeletonDataAsset = skeleton.skeletonDataAsset;
                    var visual = RoleVisualCatalog.Current.Items.Single(row => row.MalePrefab == source.name || row.FemalePrefab == source.name);
                    if (data.FindAnimation(visual.Animation) == null)
                        throw new InvalidOperationException("role_visual animation is missing: " + source.name + "/" + visual.Animation);
                    bool straight = skeleton.skeletonDataAsset.atlasAssets[0].Materials.First().GetFloat("_StraightAlphaInput") > 0;
                    graphic.material = straight ? straightMaterial : uiMaterial;
                    graphic.raycastTarget = false;
                    graphic.startingAnimation = visual.Animation;
                    graphic.startingLoop = true;
                    graphic.initialSkinName = skeleton.initialSkinName;
                    graphic.Initialize(true);
                    graphic.rectTransform.sizeDelta = new Vector2(200, 260);
                    string prefabPath = output + "/" + source.name + ".prefab";
                    PrefabUtility.SaveAsPrefabAsset(node, prefabPath);
                    string key = "Prefabs/Spine/UI/Role/" + source.name;
                    references.Where(entry => (string)entry["key"] == key).ToList().ForEach(entry => entry.Remove());
                    references.Add(new JObject { ["key"] = key, ["guid"] = AssetDatabase.AssetPathToGUID(prefabPath) });
                }
                finally { UnityEngine.Object.DestroyImmediate(node); }
            }
            foreach (string guid in AssetDatabase.FindAssets("t:Texture2D", new[] { "Assets/Art/Portraits/Players" }))
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                string key = "Art/Portraits/Players/" + Path.GetFileNameWithoutExtension(path);
                references.Where(entry => (string)entry["key"] == key).ToList().ForEach(entry => entry.Remove());
                references.Add(new JObject { ["key"] = key, ["guid"] = guid });
            }
            EnsureAnchors("Assets/Prefabs/Login/RoleCreateLayer.prefab", "RoleCreateUI/Role");
            EnsureAnchors("Assets/Prefabs/Main/UImainLayer_new.prefab", "Bg/btn_jingjie/temp_bg/role");
            EnsureAnchors("Assets/Prefabs/OneLevel/JingjieLayer.prefab",
                "JingjieUI/Panel/Panel_L/bg_L/Icon", "JingjieUI/Panel/Panel_R/bg_L/Icon", "JingjieUI/Panel/Panel_End/bg_L/Icon");
            File.WriteAllText(settings, references.ToString(Newtonsoft.Json.Formatting.Indented) + "\n");
            AssetDatabase.SaveAssets();
            foreach (JToken entry in references.Where(entry => ((string)entry["key"]).StartsWith("Prefabs/Spine/UI/Role/")
                || ((string)entry["key"]).StartsWith("Art/Portraits/Players/")))
                UnityNativeUiAssetValidator.RebuildResourceReference((string)entry["key"]);
            string evidence = Path.GetFullPath("../.local/jingjie-spine/assets-validated.json");
            File.WriteAllText(evidence, Newtonsoft.Json.JsonConvert.SerializeObject(rows, Newtonsoft.Json.Formatting.Indented));
            Debug.Log($"Spine import validated: {rows.Count - 1} playable assets, shared role UI prefabs and player avatars. zmls_001 source texture missing.");
        }

        private static void EnsureAnchors(string prefabPath, params string[] parents)
        {
            GameObject contents = PrefabUtility.LoadPrefabContents(prefabPath);
            bool changed = false;
            try
            {
                foreach (string path in parents)
                {
                    Transform parent = contents.transform.Find(path);
                    if (parent == null) throw new InvalidOperationException("Spine anchor parent is missing: " + prefabPath + "/" + path);
                    Transform anchor = parent.Find("SpineAnchor");
                    if (anchor == null)
                    {
                        var node = new GameObject("SpineAnchor", typeof(RectTransform));
                        node.transform.SetParent(parent, false);
                        anchor = node.transform;
                        changed = true;
                    }
                    if (anchor.GetComponentInChildren<SkeletonGraphic>(true) == null)
                    {
                        var preview = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Spine/UI/Role/"
                            + RoleVisualCatalog.Current.CreationDefault.Prefab(0) + ".prefab");
                        if (preview == null) throw new InvalidOperationException("Default Spine preview prefab missing.");
                        PrefabUtility.InstantiatePrefab(preview, anchor);
                        changed = true;
                    }
                    Image oldImage = parent.GetComponent<Image>();
                    if (oldImage != null && oldImage.enabled) { oldImage.enabled = false; changed = true; }
                }
                // Existing anchors belong to the artist/user. Never reset their layout.
                if (changed) PrefabUtility.SaveAsPrefabAsset(contents, prefabPath);
            }
            finally { PrefabUtility.UnloadPrefabContents(contents); }
        }
    }
}
