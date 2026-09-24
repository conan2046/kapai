#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    /// <summary>
    /// One-time cleanup for migrated shared UI sprites. Replaces all prefab references
    /// to border variants with the named canonical Sprite, then keeps only that Sprite
    /// in the source texture's Multiple importer data.
    /// </summary>
    public static class NormalizeSharedUiSprites
    {
        private const string ReportRelativePath = "../.local/ui-shared-sprite-normalization-report.txt";

        private sealed class Rule
        {
            public string AssetPath;
            public string CanonicalName;
            public Vector4 CanonicalBorder;
            public string[] VariantNames;
        }

        private sealed class Replacement
        {
            public string PrefabPath;
            public string Component;
            public string Property;
            public string OldName;
            public string NewName;
        }

        private static readonly Rule[] Rules =
        {
            new Rule
            {
                AssetPath = "Assets/ProjectX/res/res/UI/ui_common_new2/ui_common_hecheng_bg.png",
                CanonicalName = "ui_common_hecheng_bg",
                CanonicalBorder = new Vector4(15f, 15f, 14f, 14f),
                VariantNames = new[]
                {
                    "ui_common_hecheng_bg__L9_B9_R9_T9",
                    "ui_common_hecheng_bg__L13_B13_R13_T13",
                    "ui_common_hecheng_bg__L14_B14_R14_T14",
                    "ui_common_hecheng_bg__L15_B15_R14_T14",
                },
            },
            new Rule
            {
                AssetPath = "Assets/ProjectX/res/res/UI/ui_common_new2/ui_common_icon_kuang_01.png",
                CanonicalName = "ui_common_icon_kuang_01",
                CanonicalBorder = new Vector4(15f, 11f, 15f, 11f),
                VariantNames = new[] { "ui_common_icon_kuang_01__L5_B5_R5_T5" },
            },
            new Rule
            {
                AssetPath = "Assets/ProjectX/res/res/UI/ui_common/ui_xunchong_xuankuang_01.png",
                CanonicalName = "ui_xunchong_xuankuang_01",
                CanonicalBorder = new Vector4(15f, 11f, 15f, 11f),
                VariantNames = new[]
                {
                    "ui_xunchong_xuankuang_01__L19_B19_R19_T19",
                    "ui_xunchong_xuankuang_01__L9_B9_R9_T9",
                },
            },
        };

        [MenuItem("Tools/ProjectX 界面/归并共享九宫格 Sprite/预览")]
        public static void PreviewMenu() => Run(false);

        [MenuItem("Tools/ProjectX 界面/归并共享九宫格 Sprite/执行")]
        public static void ExecuteMenu()
        {
            if (!EditorUtility.DisplayDialog(
                "归并共享九宫格 Sprite",
                "将按已配置规则批量修改 Prefab 引用，并重导入对应 UI 图片。\n\n建议先确认工作树可回退。继续？",
                "执行",
                "取消"))
                return;

            Run(true);
        }

        public static void ExecuteBatch() => Run(true);

        private static void Run(bool execute)
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            var replacements = new List<Replacement>();
            var output = new List<string>
            {
                "=== Shared UI Sprite normalization " + (execute ? "EXECUTE" : "DRY RUN") + " " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===",
                "规则：ui_common_hecheng_bg -> L15_B15_R14_T14；ui_common_icon_kuang_01 -> L15_B11_R15_T11；ui_xunchong_xuankuang_01 -> L15_B11_R15_T11",
            };

            var loaded = new List<Tuple<Rule, Sprite, Dictionary<string, Sprite>>>();
            foreach (var rule in Rules)
            {
                var sprites = LoadSprites(rule.AssetPath);
                Sprite canonical = FindSprite(sprites, rule.CanonicalName);
                if (canonical == null)
                    throw new InvalidOperationException("Canonical Sprite missing: " + rule.AssetPath + "#" + rule.CanonicalName);

                var variants = new Dictionary<string, Sprite>(StringComparer.Ordinal);
                foreach (string name in rule.VariantNames)
                {
                    Sprite variant = FindSprite(sprites, name);
                    if (variant == null)
                    {
                        output.Add("ALREADY NORMALIZED " + rule.AssetPath + "#" + name);
                        continue;
                    }
                    variants.Add(name, variant);
                }

                loaded.Add(Tuple.Create(rule, canonical, variants));
                output.Add("TARGET " + rule.AssetPath + " canonical=" + rule.CanonicalName + " border=" + rule.CanonicalBorder);
            }

            string[] prefabGuids = AssetDatabase.FindAssets("t:Prefab", new[] { "Assets/ProjectX" });
            int prefabCount = 0;
            int changedPrefabCount = 0;
            foreach (string guid in prefabGuids)
            {
                string prefabPath = AssetDatabase.GUIDToAssetPath(guid);
                if (string.IsNullOrEmpty(prefabPath) || prefabPath.StartsWith("Packages/", StringComparison.OrdinalIgnoreCase))
                    continue;

                prefabCount++;
                GameObject root = PrefabUtility.LoadPrefabContents(prefabPath);
                bool changed = false;
                try
                {
                    foreach (Component component in root.GetComponentsInChildren<Component>(true))
                    {
                        if (component == null) continue;
                        var serialized = new SerializedObject(component);
                        SerializedProperty property = serialized.GetIterator();
                        bool componentChanged = false;
                        while (property.NextVisible(true))
                        {
                            if (property.propertyType != SerializedPropertyType.ObjectReference || property.objectReferenceValue == null)
                                continue;

                            foreach (var entry in loaded)
                            {
                                if (!entry.Item3.ContainsValue(property.objectReferenceValue as Sprite))
                                    continue;

                                Sprite oldSprite = property.objectReferenceValue as Sprite;
                                property.objectReferenceValue = entry.Item2;
                                replacements.Add(new Replacement
                                {
                                    PrefabPath = prefabPath,
                                    Component = component.GetType().FullName,
                                    Property = property.propertyPath,
                                    OldName = oldSprite.name,
                                    NewName = entry.Item2.name,
                                });
                                componentChanged = true;
                                changed = true;
                                break;
                            }
                        }

                        if (componentChanged)
                        {
                            serialized.ApplyModifiedPropertiesWithoutUndo();
                            EditorUtility.SetDirty(component);
                        }
                    }

                    if (changed)
                    {
                        changedPrefabCount++;
                        if (execute)
                            PrefabUtility.SaveAsPrefabAsset(root, prefabPath);
                    }
                }
                finally
                {
                    PrefabUtility.UnloadPrefabContents(root);
                }
            }

            output.Add("PREFABS scanned=" + prefabCount + " changed=" + changedPrefabCount + " replacements=" + replacements.Count);
            foreach (Replacement replacement in replacements)
                output.Add("REPLACE " + replacement.PrefabPath + " | " + replacement.Component + " | " + replacement.Property + " | " + replacement.OldName + " -> " + replacement.NewName);

            if (execute)
            {
                foreach (var entry in loaded)
                {
                    SetCanonicalBorder(entry.Item1);
                    AssetDatabase.ImportAsset(entry.Item1.AssetPath, ImportAssetOptions.ForceSynchronousImport);
                }
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
                output.Add("IMPORTER normalized and reimported; non-canonical sprite entries removed from importer data.");
            }
            else
            {
                output.Add("DRY RUN: no Prefab or importer changes were saved.");
            }

            string reportPath = Path.GetFullPath(Path.Combine(Application.dataPath, ReportRelativePath));
            Directory.CreateDirectory(Path.GetDirectoryName(reportPath));
            File.WriteAllLines(reportPath, output);
            Debug.Log("Shared UI Sprite normalization report: " + reportPath);
        }

        private static Dictionary<string, Sprite> LoadSprites(string assetPath)
        {
            var result = new Dictionary<string, Sprite>(StringComparer.Ordinal);
            foreach (UnityEngine.Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
            {
                if (asset is Sprite sprite)
                    result[sprite.name] = sprite;
            }
            return result;
        }

        private static Sprite FindSprite(Dictionary<string, Sprite> sprites, string name)
        {
            sprites.TryGetValue(name, out Sprite sprite);
            return sprite;
        }

        private static void SetCanonicalBorder(Rule rule)
        {
            var importer = AssetImporter.GetAtPath(rule.AssetPath) as TextureImporter;
            if (importer == null)
                throw new InvalidOperationException("Texture importer missing: " + rule.AssetPath);

            SpriteMetaData[] sheet = importer.spritesheet;
            bool found = false;
            var kept = new List<SpriteMetaData>();
            for (int i = 0; i < sheet.Length; i++)
            {
                SpriteMetaData data = sheet[i];
                if (data.name == rule.CanonicalName)
                {
                    data.border = rule.CanonicalBorder;
                    kept.Add(data);
                    found = true;
                }
                else
                {
                    bool remove = false;
                    foreach (string variant in rule.VariantNames)
                        if (data.name == variant) remove = true;
                    if (!remove) kept.Add(data);
                }
            }

            if (!found)
                throw new InvalidOperationException("Canonical Sprite metadata missing: " + rule.AssetPath + "#" + rule.CanonicalName);

            importer.spriteImportMode = SpriteImportMode.Multiple;
            importer.spritesheet = kept.ToArray();
            EditorUtility.SetDirty(importer);
            // Unity 2022.3 can retain removed sub-sprite IDs in the serialized
            // name/file-ID lookup table even after spritesheet is replaced.
            // Clear that bookkeeping table as well so the .meta contains only
            // the canonical Sprite entry.
            SerializedObject serializedImporter = new SerializedObject(importer);
            SerializedProperty nameFileIdTable = serializedImporter.FindProperty("m_SpriteSheet.m_NameFileIdTable");
            if (nameFileIdTable != null)
            {
                nameFileIdTable.ClearArray();
                serializedImporter.ApplyModifiedPropertiesWithoutUndo();
            }
            importer.SaveAndReimport();
        }
    }
}
#endif
