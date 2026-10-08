using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.UI.Migration;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class CocosUiImporter
    {
        private const string ManifestPath =
            "Assets/ProjectX/res/csd/UnityMigration/unity-import-manifest.json";
        private const string PreviewScenePath = "Assets/ProjectX/Scenes/UIMigrationPreview.unity";
        [Serializable] private sealed class ImportManifest
        {
            public ImportDocument[] documents;
            public SpriteBorderDefinition[] spriteBorders;
            public string previewScene;
        }

        [Serializable] private sealed class SpriteBorderDefinition
        {
            public string assetPath;
            public string sourceAssetPath;
            public string spriteName;
            public bool canonical;
            public UiVector4 border;
        }

        [Serializable] private sealed class ImportDocument
        {
            public string name;
            public string source;
            public bool preview;
            public bool pathOnly;
            public string documentAssetPath;
            public string prefabAssetPath;
        }

        [Serializable] private sealed class UiDocument
        {
            public string name;
            public string source;
            public UiNode root;
            public JObject animation;
        }

        [Serializable] private sealed class UiNode
        {
            public string name;
            public string nodePath;
            public string nodeType;
            public int tag;
            public int actionTag;
            public bool visible = true;
            public bool touchEnabled;
            public bool clip;
            public bool scale9;
            public bool @checked;
            public float progress = 1f;
            public string text;
            public string placeholder;
            public int fontSize = 20;
            public string fontAssetPath;
            public string alignment;
            public UiColor color;
            public UiColor textColor;
            public bool outlineEnabled;
            public float outlineSize = 1f;
            public UiColor outlineColor;
            public bool shadowEnabled;
            public UiVector2 shadowOffset;
            public UiColor shadowColor;
            public UiRect rect;
            public UiResource[] resources;
            public UiNode[] children;
        }

        [Serializable] private sealed class UiColor
        {
            public float r = 1f;
            public float g = 1f;
            public float b = 1f;
            public float a = 1f;
            public Color Value => new Color(r, g, b, a);
        }

        [Serializable] private sealed class UiRect
        {
            public UiVector2 anchorMin;
            public UiVector2 anchorMax;
            public UiVector2 pivot;
            public UiVector2 sizeDelta;
            public UiVector2 anchoredPosition;
            public UiVector3 localScale;
            public UiVector3 localEulerAngles;
        }

        [Serializable] private sealed class UiVector2
        {
            public float x;
            public float y;
            public Vector2 Value => new Vector2(x, y);
        }

        [Serializable] private sealed class UiVector3
        {
            public float x;
            public float y;
            public float z;
            public Vector3 Value => new Vector3(x, y, z);
        }

        [Serializable] private sealed class UiVector4
        {
            public float x;
            public float y;
            public float z;
            public float w;
            public Vector4 Value => new Vector4(x, y, z, w);
        }

        [Serializable] private sealed class UiResource
        {
            public string property;
            public string path;
            public string type;
            public string assetPath;
            public string spriteName;
        }

        [Serializable] private sealed class SlicedSpriteMigrationPlan
        {
            public SlicedSpriteMigrationEntry[] entries;
        }

        [Serializable] private sealed class SlicedSpriteMigrationEntry
        {
            public string oldAssetPath;
            public string sourceAssetPath;
            public string spriteName;
        }

        public static void ImportBaselinesMenu()
        {
            ImportBaselines(true);
        }

        public static void ImportBaselinesBatch()
        {
            ImportBaselines(true);
        }

        public static void ImportAllPrefabsBatch()
        {
            ImportBaselines(true);
        }

        public static void MigrateSlicedSpritesBatch()
        {
            if (IsNativeMaintenance())
                throw new InvalidOperationException("Cocos sprite migration is retired. Maintain native Sprite import settings directly.");
            string projectRoot = Path.GetFullPath(Path.Combine(Application.dataPath, ".."));
            string repoRoot = Path.GetFullPath(Path.Combine(projectRoot, ".."));
            string planPath = Path.Combine(repoRoot, ".local", "ui-sliced-multiple-plan.json");
            string reportPath = Path.Combine(repoRoot, ".local", "ui-sliced-multiple-report.json");
            if (!File.Exists(planPath))
                throw new FileNotFoundException("Sliced sprite migration plan is missing", planPath);

            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(ToAbsolutePath(ManifestPath)));
            SlicedSpriteMigrationPlan plan = JsonConvert.DeserializeObject<SlicedSpriteMigrationPlan>(
                File.ReadAllText(planPath));
            if (manifest?.spriteBorders == null || plan?.entries == null)
                throw new InvalidDataException("Invalid sliced sprite migration input.");
            EnsureManifestExcludesUnityOwnedPrefabs(manifest, ManifestPath);
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);

            var oldGuids = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (SlicedSpriteMigrationEntry entry in plan.entries)
            {
                string oldGuid = AssetDatabase.AssetPathToGUID(entry.oldAssetPath);
                if (string.IsNullOrWhiteSpace(oldGuid))
                    throw new MissingReferenceException(
                        $"Legacy sliced sprite is missing: {entry.oldAssetPath}");
                oldGuids[entry.oldAssetPath] = oldGuid;
            }

            ConfigureReferencedTextures(manifest);

            var replacements = new List<object>();
            foreach (SlicedSpriteMigrationEntry entry in plan.entries)
            {
                Sprite sprite = LoadSpriteAtPath(entry.sourceAssetPath, entry.spriteName);
                if (sprite == null)
                    throw new MissingReferenceException(
                        $"Multiple sprite sub-asset is missing: {entry.sourceAssetPath}#{entry.spriteName}");
                if (!AssetDatabase.TryGetGUIDAndLocalFileIdentifier(sprite, out string newGuid, out long newFileId))
                    throw new InvalidDataException(
                        $"Cannot resolve sprite identifier: {entry.sourceAssetPath}#{entry.spriteName}");
                string oldReference = $"fileID: 21300000, guid: {oldGuids[entry.oldAssetPath]}";
                string newReference = $"fileID: {newFileId}, guid: {newGuid}";
                replacements.Add(new
                {
                    entry.oldAssetPath,
                    entry.sourceAssetPath,
                    entry.spriteName,
                    oldReference,
                    newReference,
                });
            }
            Directory.CreateDirectory(Path.GetDirectoryName(reportPath));
            File.WriteAllText(
                reportPath,
                JsonConvert.SerializeObject(
                    new
                    {
                        ok = true,
                        entries = plan.entries.Length,
                        replacements,
                    },
                    Formatting.Indented));
            Debug.Log(
                $"ProjectX sliced sprite mapping completed: {plan.entries.Length} entries.");
        }

        public static void ValidateBaselinesBatch()
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(ToAbsolutePath(ManifestPath)));
            ValidationSummary summary = ValidateBaselines(manifest, collectAllFailures: true);
            Debug.Log(
                $"ProjectX UI validation completed: {summary.prefabs} prefabs, "
                + $"{summary.nodes} nodes, {summary.sprites} sprites, "
                + $"{summary.slicedSprites} sliced variants, {summary.texts} texts, "
                + $"{summary.outlinedTexts} outlines, {summary.shadowedTexts} shadows, "
                + $"{summary.spriteBindings} sprite bindings, 0 errors.");
        }

        // Diagnosis only: collect every affected node in one manifest pass while
        // keeping ValidateBaselinesBatch's strict fail-fast result unchanged.
        public static string DiagnoseBaselineDifferencesBatch()
        {
            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(ToAbsolutePath(ManifestPath)));
            var findings = new List<string>();
            var summary = new ValidationSummary();
            foreach (ImportDocument item in manifest.documents)
            {
                try
                {
                    UiDocument document = ReadDocument(item.documentAssetPath);
                    GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(item.prefabAssetPath);
                    if (prefab == null)
                    {
                        findings.Add(item.prefabAssetPath + " | missing prefab");
                        continue;
                    }
                    UiPrefabIdentity identity = prefab.GetComponent<UiPrefabIdentity>();
                    if (item.pathOnly && identity != null)
                    {
                        findings.Add(item.prefabAssetPath + " | path-only prefab has UiPrefabIdentity");
                        continue;
                    }
                    if (!item.pathOnly && identity == null)
                    {
                        findings.Add(item.prefabAssetPath + " | missing UiPrefabIdentity");
                        continue;
                    }
                    int expectedNodes = CountNodes(document.root);
                    if (!item.pathOnly && identity.Nodes.Count != expectedNodes)
                        findings.Add(item.prefabAssetPath + " | identity nodes "
                            + identity.Nodes.Count + "/" + expectedNodes);
                    if (prefab.GetComponent<CocosUiBinding>() != null)
                        findings.Add(item.prefabAssetPath + " | legacy CocosUiBinding remains");
                    int metadataCount = prefab.GetComponentsInChildren<CocosNodeMetadata>(true).Length;
                    if (metadataCount != 0)
                        findings.Add(item.prefabAssetPath + " | legacy Metadata count " + metadataCount);
                    if (identity != null)
                        foreach (CocosNodeReference reference in identity.Nodes)
                            if (reference.target == null)
                                findings.Add(item.prefabAssetPath + " | null target " + reference.path);
                    foreach (Transform transform in prefab.GetComponentsInChildren<Transform>(true))
                        if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(transform.gameObject) != 0)
                            findings.Add(item.prefabAssetPath + " | missing script " + transform.name);
                    try
                    {
                        if (HasTimelineTracks(document.animation))
                            findings.Add(item.prefabAssetPath + " | Cocos Timeline source data is not supported");
                    }
                    catch (Exception exception)
                    {
                        findings.Add(item.prefabAssetPath + " | timeline " + exception.Message);
                    }
                    if (!item.pathOnly)
                        CollectNodeValidationFailures(document.root, identity, item.prefabAssetPath, summary, findings);
                }
                catch (Exception exception)
                {
                    findings.Add(item.prefabAssetPath + " | document " + exception.Message);
                }
            }
            string output = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..",
                ".local", "unity-validation", "w6-importer-all-differences-20260926.txt"));
            Directory.CreateDirectory(Path.GetDirectoryName(output));
            File.WriteAllLines(output, findings, new System.Text.UTF8Encoding(false));
            Debug.Log($"UI baseline diagnostic: {manifest.documents.Length} documents, "
                + $"{findings.Count} observations. Report: {output}");
            return output;
        }

        private static void CollectNodeValidationFailures(UiNode node, UiPrefabIdentity identity,
            string prefabPath, ValidationSummary summary, List<string> findings)
        {
            try { ValidateTextStyles(node, identity, summary, false); }
            catch (Exception exception)
            {
                findings.Add(prefabPath + " | text " + exception.Message);
            }
            try { ValidateSpriteBindings(node, identity, summary, false, false); }
            catch (Exception exception)
            {
                findings.Add(prefabPath + " | sprite " + exception.Message);
            }
            if (node.children != null)
                foreach (UiNode child in node.children)
                    CollectNodeValidationFailures(child, identity, prefabPath, summary, findings);
        }

        private static void ImportBaselines(bool createPreview)
        {
            RunManifestImport(ManifestPath, createPreview);
        }

        private static void ReconcileEmptyGraphics(UiNode node, UiPrefabIdentity identity)
        {
            GameObject target = identity.Find(node.nodePath, node.nodeType, node.actionTag);
            if (target != null && node.nodeType == "PanelObjectData"
                               && !HasRenderableResource(FindResource(node, "FileData")))
            {
                Image image = target.GetComponent<Image>();
                if (image != null) UnityEngine.Object.DestroyImmediate(image);
            }
            if (target != null && node.nodeType == "ButtonObjectData"
                               && !HasRenderableResource(FindResource(node, "NormalFileData")))
            {
                Image image = target.GetComponent<Image>();
                if (image != null)
                    image.color = new Color(image.color.r, image.color.g, image.color.b, 0f);
            }
            if (node.children != null)
                foreach (UiNode child in node.children)
                    ReconcileEmptyGraphics(child, identity);
        }

        private static void RunManifestImport(string manifestPath, bool createPreview)
        {
            if (IsNativeMaintenance())
                throw new InvalidOperationException("Cocos import is retired. Maintain Unity Prefabs and AnimationClips directly.");
            string manifestFile = ToAbsolutePath(manifestPath);
            if (!File.Exists(manifestFile))
                throw new FileNotFoundException("Unity migration manifest is missing", manifestFile);

            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(manifestFile));
            if (manifest.documents == null || manifest.documents.Length == 0)
                throw new InvalidDataException("Unity migration manifest contains no documents.");
            EnsureManifestExcludesUnityOwnedPrefabs(manifest, manifestPath);
            if (createPreview) EnsurePreviewSceneIsLegacyScoped(manifest);

            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ConfigureReferencedTextures(manifest);
            var createdPrefabs = new List<GameObject>();
            foreach (ImportDocument item in manifest.documents)
            {
                UiDocument document = ReadDocument(item.documentAssetPath);
                EnsureAssetFolder(Path.GetDirectoryName(item.prefabAssetPath)?.Replace('\\', '/'));
                GameObject root = BuildDocument(document, !item.pathOnly);
                GameObject prefab = PrefabUtility.SaveAsPrefabAsset(root, item.prefabAssetPath);
                UnityEngine.Object.DestroyImmediate(root);
                if (prefab == null)
                    throw new InvalidOperationException($"Failed to save prefab: {item.prefabAssetPath}");
                createdPrefabs.Add(prefab);
            }

            if (createPreview)
                CreatePreviewScene(manifest);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ValidateBaselines(manifest);
            Debug.Log($"ProjectX UI import completed: {createdPrefabs.Count} prefabs.");
        }

        private static void EnsureManifestExcludesUnityOwnedPrefabs(
            ImportManifest manifest, string manifestPath)
        {
            if (manifest?.documents == null)
                throw new InvalidDataException($"Cocos import manifest has no documents: {manifestPath}");
            foreach (ImportDocument item in manifest.documents)
            {
                if (item == null) continue;
                string prefabName = Path.GetFileNameWithoutExtension(item.prefabAssetPath);
                if (BootstrapSceneBuilder.IsUnityOwnedPrefabPath(item.prefabAssetPath)
                    || BootstrapSceneBuilder.IsUnityOwnedPrefabName(item.name)
                    || BootstrapSceneBuilder.IsUnityOwnedPrefabName(prefabName))
                    throw new InvalidDataException(
                        $"Cocos importer refuses to write Unity-owned Prefab '{item.name}' at '{item.prefabAssetPath}' "
                        + $"from manifest '{manifestPath}'. Remove the entry or migrate its source first.");
                if (!BootstrapSceneBuilder.IsLegacyCocosPrefabPath(item.prefabAssetPath))
                    throw new InvalidDataException(
                        $"Cocos importer only writes Prefabs under Assets/ProjectX/res/csd/Prefabs/: "
                        + $"'{item.prefabAssetPath}' in '{manifestPath}'.");
            }
        }

        private static void EnsurePreviewSceneIsLegacyScoped(ImportManifest manifest)
        {
            string normalized = manifest?.previewScene?.Replace('\\', '/');
            if (!string.Equals(normalized, PreviewScenePath, StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException(
                    $"Cocos importer preview output must remain at '{PreviewScenePath}', actual: '{manifest?.previewScene}'.");
        }

        private sealed class ValidationSummary
        {
            public int prefabs;
            public int nodes;
            public int sprites;
            public int slicedSprites;
            public int texts;
            public int outlinedTexts;
            public int shadowedTexts;
            public int spriteBindings;
        }

        private static ValidationSummary ValidateBaselines(
            ImportManifest manifest, bool collectAllFailures = false)
        {
            var summary = new ValidationSummary();
            var spritePaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var failures = new List<string>();
            foreach (ImportDocument item in manifest.documents)
            {
                try
                {
                UiDocument document = ReadDocument(item.documentAssetPath);
                int expectedNodes = CountNodes(document.root);
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(item.prefabAssetPath);
                if (prefab == null)
                    throw new InvalidDataException($"Generated prefab is missing: {item.prefabAssetPath}");
                UiPrefabIdentity identity = prefab.GetComponent<UiPrefabIdentity>();
                if (item.pathOnly)
                {
                    if (identity != null)
                        throw new InvalidDataException(
                            $"Path-only prefab must not contain UiPrefabIdentity: {item.prefabAssetPath}");
                }
                else if (identity == null || identity.Nodes.Count != expectedNodes)
                    throw new InvalidDataException(
                        $"Identity count mismatch in {item.prefabAssetPath}: "
                        + $"expected {expectedNodes}, actual {identity?.Nodes.Count ?? 0}");
                if (HasTimelineTracks(document.animation))
                    throw new InvalidDataException(
                        $"Cocos Timeline source data is not supported: {item.prefabAssetPath}");
                if (prefab.GetComponent<CocosUiBinding>() != null)
                    throw new InvalidDataException($"Legacy Binding remains in {item.prefabAssetPath}");
                int metadataCount = prefab.GetComponentsInChildren<CocosNodeMetadata>(true).Length;
                if (metadataCount != 0)
                    throw new InvalidDataException(
                        $"Generated prefab must not contain legacy node Metadata in {item.prefabAssetPath}: "
                        + $"found {metadataCount}");
                if (identity != null)
                    foreach (CocosNodeReference reference in identity.Nodes)
                        if (reference.target == null)
                            throw new MissingReferenceException(
                                $"Null binding target in {item.prefabAssetPath}: {reference.path}");
                foreach (Transform transform in prefab.GetComponentsInChildren<Transform>(true))
                    if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(transform.gameObject) != 0)
                        throw new MissingReferenceException(
                            $"Missing script in {item.prefabAssetPath}: {transform.name}");
                CollectTexturePaths(document.root, spritePaths);
                if (!item.pathOnly)
                {
                    ValidateTextStyles(document.root, identity, summary);
                    ValidateSpriteBindings(document.root, identity, summary);
                }
                summary.prefabs++;
                summary.nodes += expectedNodes;
                }
                catch (Exception exception)
                {
                    if (!collectAllFailures) throw;
                    failures.Add($"{item.prefabAssetPath}: {exception.GetType().Name}: {exception.Message}");
                }
            }

            if (failures.Count != 0)
                throw new InvalidDataException(
                    $"UI baseline failed in {failures.Count} documents:\n"
                    + string.Join("\n", failures));

            foreach (string assetPath in spritePaths)
                if (LoadSpriteAtPath(assetPath, null) == null)
                    throw new MissingReferenceException($"Sprite import failed: {assetPath}");
            summary.sprites = spritePaths.Count;
            if (manifest.spriteBorders != null)
            {
                foreach (SpriteBorderDefinition definition in manifest.spriteBorders)
                {
                    Sprite sprite = LoadSpriteAtPath(definition.assetPath, definition.spriteName);
                    if (sprite == null)
                        throw new MissingReferenceException(
                            $"Sliced sprite import failed: {definition.assetPath}#{definition.spriteName}");
                    Vector4 expected = ExpectedSpriteBorder(definition);
                    if (expected == Vector4.zero || sprite.border != expected)
                        throw new InvalidDataException(
                            $"Sprite border mismatch in {definition.assetPath}#{definition.spriteName}: "
                            + $"expected {expected}, actual {sprite.border}");
                    summary.slicedSprites++;
                }
            }
            if (!File.Exists(ToAbsolutePath(manifest.previewScene)))
                throw new FileNotFoundException("Preview scene is missing", manifest.previewScene);
            return summary;
        }

        private static bool HasTimelineTracks(JObject animation)
        {
            JToken timelines = animation?["timelines"];
            if (timelines == null || timelines.Type == JTokenType.Null) return false;
            JArray tracks = timelines as JArray;
            return tracks == null || tracks.Count > 0;
        }

        private static void ValidateTextStyles(
            UiNode node,
            UiPrefabIdentity identity,
            ValidationSummary summary,
            bool recurseChildren = true)
        {
            GameObject target = identity.Find(node.nodePath, node.nodeType, node.actionTag);
            Text text = null;
            Color expectedColor = node.color?.Value ?? Color.white;
            switch (node.nodeType)
            {
                case "TextObjectData":
                case "TextAtlasObjectData":
                    text = target != null ? target.GetComponent<Text>() : null;
                    break;
                case "TextFieldObjectData":
                    text = target != null ? target.GetComponent<InputField>()?.textComponent : null;
                    break;
                case "ButtonObjectData" when !string.IsNullOrWhiteSpace(node.text):
                    text = target != null
                        ? target.transform.Find("__Label")?.GetComponent<Text>()
                        : null;
                    expectedColor = node.textColor?.Value ?? Color.white;
                    break;
            }

            if (text != null || node.nodeType == "TextObjectData"
                             || node.nodeType == "TextAtlasObjectData"
                             || node.nodeType == "TextFieldObjectData")
            {
                if (text == null)
                    throw new MissingReferenceException($"Text component is missing: {node.nodePath}");
                string actualFont = AssetDatabase.GetAssetPath(text.font);
                if (!string.Equals(actualFont, node.fontAssetPath, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException(
                        $"Font mismatch in {node.nodePath}: expected {node.fontAssetPath}, actual {actualFont}");
                if (text.fontSize != Mathf.Max(1, node.fontSize))
                    throw new InvalidDataException(
                        $"Font size mismatch in {node.nodePath}: expected {node.fontSize}, actual {text.fontSize}");
                if (!Approximately(text.color, expectedColor))
                    throw new InvalidDataException(
                        $"Text color mismatch in {node.nodePath}: expected {expectedColor}, actual {text.color}");

                Outline outline = text.GetComponent<Outline>();
                if (node.outlineEnabled)
                {
                    Vector2 expectedDistance = new Vector2(node.outlineSize, -node.outlineSize);
                    if (outline == null
                        || !Approximately(outline.effectColor, node.outlineColor?.Value ?? Color.black)
                        || outline.effectDistance != expectedDistance)
                        throw new InvalidDataException($"Outline mismatch in {node.nodePath}");
                    summary.outlinedTexts++;
                }
                else if (outline != null)
                    throw new InvalidDataException($"Unexpected outline in {node.nodePath}");

                Shadow explicitShadow = Array.Find(
                    text.GetComponents<Shadow>(), item => item.GetType() == typeof(Shadow));
                if (node.shadowEnabled)
                {
                    if (explicitShadow == null
                        || !Approximately(
                            explicitShadow.effectColor,
                            node.shadowColor?.Value ?? new Color(0f, 0f, 0f, 0.5f))
                        || explicitShadow.effectDistance
                           != (node.shadowOffset?.Value ?? new Vector2(2f, -2f)))
                        throw new InvalidDataException($"Shadow mismatch in {node.nodePath}");
                    summary.shadowedTexts++;
                }
                else if (explicitShadow != null)
                    throw new InvalidDataException($"Unexpected shadow in {node.nodePath}");
                summary.texts++;
            }

            if (recurseChildren && node.children != null)
                foreach (UiNode child in node.children)
                    ValidateTextStyles(child, identity, summary);
        }

        private static bool Approximately(Color first, Color second)
        {
            return Mathf.Abs(first.r - second.r) < 0.001f
                   && Mathf.Abs(first.g - second.g) < 0.001f
                   && Mathf.Abs(first.b - second.b) < 0.001f
                   && Mathf.Abs(first.a - second.a) < 0.001f;
        }

        private static void ValidateSpriteBindings(
            UiNode node,
            UiPrefabIdentity identity,
            ValidationSummary summary,
            bool namedSpritesOnly = false,
            bool recurseChildren = true)
        {
            GameObject target = identity.Find(node.nodePath, node.nodeType, node.actionTag);
            switch (node.nodeType)
            {
                case "ImageViewObjectData":
                case "SpriteObjectData":
                    ValidateResourceSprite(node, "FileData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    break;
                case "PanelObjectData" when FindResource(node, "FileData") != null:
                    ValidateResourceSprite(node, "FileData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    break;
                case "LoadingBarObjectData":
                    ValidateResourceSprite(node, "ImageFileData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    break;
                case "ButtonObjectData":
                    Button button = target?.GetComponent<Button>();
                    ValidateResourceSprite(node, "NormalFileData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    ValidateResourceSprite(
                        node, "PressedFileData", button != null ? button.spriteState.pressedSprite : null, summary, namedSpritesOnly);
                    ValidateResourceSprite(
                        node, "DisabledFileData", button != null ? button.spriteState.disabledSprite : null, summary, namedSpritesOnly);
                    break;
                case "CheckBoxObjectData":
                    Toggle toggle = target?.GetComponent<Toggle>();
                    ValidateResourceSprite(node, "NormalBackFileData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "NodeNormalFileData",
                        target?.transform.Find("__Checkmark")?.GetComponent<Image>()?.sprite,
                        summary,
                        namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "PressedBackFileData",
                        toggle != null ? toggle.spriteState.pressedSprite : null,
                        summary,
                        namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "DisableBackFileData",
                        toggle != null ? toggle.spriteState.disabledSprite : null,
                        summary,
                        namedSpritesOnly);
                    break;
                case "SliderObjectData":
                    Slider slider = target?.GetComponent<Slider>();
                    ValidateResourceSprite(node, "BackGroundData", target?.GetComponent<Image>()?.sprite, summary, namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "ProgressBarData",
                        target?.transform.Find("__Fill")?.GetComponent<Image>()?.sprite,
                        summary,
                        namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "BallNormalData",
                        target?.transform.Find("__Handle")?.GetComponent<Image>()?.sprite,
                        summary,
                        namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "BallPressedData",
                        slider != null ? slider.spriteState.pressedSprite : null,
                        summary,
                        namedSpritesOnly);
                    ValidateResourceSprite(
                        node,
                        "BallDisabledData",
                        slider != null ? slider.spriteState.disabledSprite : null,
                        summary,
                        namedSpritesOnly);
                    break;
            }

            if (recurseChildren && node.children != null)
                foreach (UiNode child in node.children)
                    ValidateSpriteBindings(child, identity, summary, namedSpritesOnly);
        }

        private static void ValidateResourceSprite(
            UiNode node,
            string property,
            Sprite actual,
            ValidationSummary summary,
            bool namedSpritesOnly = false)
        {
            UiResource resource = FindResource(node, property);
            if (namedSpritesOnly && string.IsNullOrWhiteSpace(resource?.spriteName))
                return;
            if (resource == null
                || string.Equals(resource.type, "Default", StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrWhiteSpace(resource.path)
                || !resource.path.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                return;
            if (string.IsNullOrWhiteSpace(resource.assetPath))
                throw new MissingReferenceException(
                    $"Sprite asset path is empty in {node.nodePath}/{property}: {resource.path}");
            Sprite expected = LoadSpriteAtPath(resource.assetPath, resource.spriteName);
            if (expected == null)
                throw new MissingReferenceException(
                    $"Sprite asset is missing in {node.nodePath}/{property}: "
                    + $"{resource.assetPath}#{resource.spriteName}");
            if (actual != expected)
                throw new MissingReferenceException(
                    $"Sprite binding mismatch in {node.nodePath}/{property}: "
                    + $"expected {resource.assetPath}, actual {AssetDatabase.GetAssetPath(actual)}");
            summary.spriteBindings++;
        }

        private static int CountNodes(UiNode node)
        {
            int count = 1;
            if (node.children != null)
                foreach (UiNode child in node.children)
                    count += CountNodes(child);
            return count;
        }

        private static UiDocument ReadDocument(string assetPath)
        {
            UiDocument document = JsonConvert.DeserializeObject<UiDocument>(
                File.ReadAllText(ToAbsolutePath(assetPath)));
            if (document?.root == null)
                throw new InvalidDataException($"Invalid normalized UI document: {assetPath}");
            return document;
        }

        public static void ValidateSlicedSpritesBatch()
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(ToAbsolutePath(ManifestPath)));
            if (manifest?.documents == null || manifest.spriteBorders == null)
                throw new InvalidDataException("Invalid UI migration manifest.");

            int definitions = 0;
            foreach (SpriteBorderDefinition definition in manifest.spriteBorders)
            {
                Sprite sprite = LoadSpriteAtPath(definition.assetPath, definition.spriteName);
                if (sprite == null)
                    throw new MissingReferenceException(
                        $"Sliced sprite import failed: {definition.assetPath}#{definition.spriteName}");
                Vector4 expected = ExpectedSpriteBorder(definition);
                if (expected == Vector4.zero || sprite.border != expected)
                    throw new InvalidDataException(
                        $"Sprite border mismatch in {definition.assetPath}#{definition.spriteName}: "
                        + $"expected {expected}, actual {sprite.border}");
                definitions++;
            }

            Debug.Log(
                $"ProjectX sliced Sprite validation completed: {definitions} definitions, 0 errors.");
        }

        private static void ConfigureReferencedTextures(ImportManifest manifest)
        {
            var texturePaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var borderGroups = new Dictionary<string, List<SpriteBorderDefinition>>(
                StringComparer.OrdinalIgnoreCase);
            if (manifest.spriteBorders != null)
                foreach (SpriteBorderDefinition definition in manifest.spriteBorders)
                {
                    texturePaths.Add(definition.assetPath);
                    if (!borderGroups.TryGetValue(
                            definition.assetPath,
                            out List<SpriteBorderDefinition> definitions))
                    {
                        definitions = new List<SpriteBorderDefinition>();
                        borderGroups[definition.assetPath] = definitions;
                    }
                    definitions.Add(definition);
                }
            foreach (ImportDocument item in manifest.documents)
                CollectTexturePaths(ReadDocument(item.documentAssetPath).root, texturePaths);

            foreach (string assetPath in texturePaths)
                if (BootstrapSceneBuilder.IsUnityOwnedAssetPath(assetPath))
                    throw new InvalidDataException(
                        $"Cocos texture import refuses to change Unity-owned asset '{assetPath}'. "
                        + "Use Unity's native asset workflow instead.");
                else if (!BootstrapSceneBuilder.IsLegacyCocosAssetPath(assetPath))
                    throw new InvalidDataException(
                        $"Cocos texture import only writes assets under Assets/ProjectX/res/: '{assetPath}'.");

            foreach (string assetPath in texturePaths)
            {
                TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                if (importer == null)
                    continue;
                borderGroups.TryGetValue(assetPath, out List<SpriteBorderDefinition> definitions);
                bool useMultiple = definitions != null
                                   && definitions.Exists(
                                       definition => !string.IsNullOrWhiteSpace(definition.spriteName));
                Vector4 desiredBorder = !useMultiple && definitions != null && definitions.Count > 0
                    ? definitions[0].border?.Value ?? Vector4.zero
                    : Vector4.zero;
                bool changed = importer.textureType != TextureImporterType.Sprite
                               || importer.spriteImportMode != (
                                   useMultiple ? SpriteImportMode.Multiple : SpriteImportMode.Single)
                               || importer.mipmapEnabled
                               || importer.spriteBorder != desiredBorder;
                importer.textureType = TextureImporterType.Sprite;
                importer.spriteImportMode = useMultiple
                    ? SpriteImportMode.Multiple
                    : SpriteImportMode.Single;
                importer.spriteBorder = desiredBorder;
                importer.alphaIsTransparency = true;
                importer.mipmapEnabled = false;
                importer.wrapMode = TextureWrapMode.Clamp;
                importer.filterMode = FilterMode.Bilinear;
                if (useMultiple)
                {
                    Texture2D texture = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                    if (texture == null)
                        throw new MissingReferenceException($"Texture import failed: {assetPath}");
                    definitions.Sort((left, right) => string.CompareOrdinal(
                        left.spriteName, right.spriteName));
                    var sprites = new SpriteMetaData[definitions.Count];
                    for (int index = 0; index < definitions.Count; index++)
                    {
                        SpriteBorderDefinition definition = definitions[index];
                        sprites[index] = new SpriteMetaData
                        {
                            name = definition.spriteName,
                            rect = new Rect(0f, 0f, texture.width, texture.height),
                            alignment = (int)SpriteAlignment.Center,
                            pivot = new Vector2(0.5f, 0.5f),
                            border = definition.border?.Value ?? Vector4.zero,
                        };
                    }
#pragma warning disable 0618
                    importer.spritesheet = sprites;
#pragma warning restore 0618
                    changed = true;
                }
                if (changed)
                    importer.SaveAndReimport();
            }
        }

        private static void CollectTexturePaths(UiNode node, HashSet<string> paths)
        {
            if (node.resources != null)
                foreach (UiResource resource in node.resources)
                    if (!string.IsNullOrWhiteSpace(resource.assetPath)
                        && resource.assetPath.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                        paths.Add(resource.assetPath);
            if (node.children != null)
                foreach (UiNode child in node.children)
                    CollectTexturePaths(child, paths);
        }

        private static GameObject BuildDocument(UiDocument document, bool addCocosIdentity = true)
        {
            if (HasTimelineTracks(document.animation))
                throw new InvalidDataException(
                    $"Cocos Timeline generation is retired; author animation in Unity: {document.name}");

            var bindings = new List<CocosNodeReference>();
            GameObject root = BuildNode(document.root, null, bindings);
            root.name = document.name;
            if (addCocosIdentity)
            {
                root.AddComponent<UiPrefabIdentity>().Initialize(document.source, bindings);
            }
            return root;
        }

        private static GameObject BuildNode(
            UiNode node,
            RectTransform parent,
            List<CocosNodeReference> bindings)
        {
            var gameObject = new GameObject(SafeName(node.name), typeof(RectTransform));
            var rect = (RectTransform)gameObject.transform;
            if (parent != null)
                rect.SetParent(parent, false);
            ApplyRect(rect, node.rect);
            gameObject.SetActive(node.visible);
            bindings.Add(new CocosNodeReference
            {
                path = node.nodePath,
                nodeType = node.nodeType,
                tag = node.tag,
                actionTag = node.actionTag,
                target = gameObject,
            });

            AddUiComponent(gameObject, node);
            if (node.children != null)
                foreach (UiNode child in node.children)
                    BuildNode(child, rect, bindings);
            return gameObject;
        }

        private static void ApplyRect(RectTransform rect, UiRect source)
        {
            if (source == null)
                return;
            rect.anchorMin = source.anchorMin?.Value ?? Vector2.zero;
            rect.anchorMax = source.anchorMax?.Value ?? Vector2.zero;
            rect.pivot = source.pivot?.Value ?? new Vector2(0.5f, 0.5f);
            rect.sizeDelta = source.sizeDelta?.Value ?? Vector2.zero;
            rect.anchoredPosition = source.anchoredPosition?.Value ?? Vector2.zero;
            rect.localScale = source.localScale?.Value ?? Vector3.one;
            rect.localEulerAngles = source.localEulerAngles?.Value ?? Vector3.zero;
        }

        private static void AddUiComponent(GameObject target, UiNode node)
        {
            switch (node.nodeType)
            {
                case "ImageViewObjectData":
                case "SpriteObjectData":
                    AddImage(target, node, "FileData");
                    break;
                case "PanelObjectData":
                    if (HasRenderableResource(FindResource(node, "FileData")))
                        AddImage(target, node, "FileData");
                    if (node.clip)
                        target.AddComponent<RectMask2D>();
                    break;
                case "ButtonObjectData":
                    AddButton(target, node);
                    break;
                case "CheckBoxObjectData":
                    AddToggle(target, node);
                    break;
                case "LoadingBarObjectData":
                    Image loading = AddImage(target, node, "ImageFileData");
                    loading.type = Image.Type.Filled;
                    loading.fillMethod = Image.FillMethod.Horizontal;
                    loading.fillAmount = Mathf.Clamp01(node.progress);
                    break;
                case "TextObjectData":
                case "TextAtlasObjectData":
                    AddText(target, node, node.text, false);
                    break;
                case "TextFieldObjectData":
                    AddInputField(target, node);
                    break;
                case "ListViewObjectData":
                case "ScrollViewObjectData":
                case "PageViewObjectData":
                    target.AddComponent<RectMask2D>();
                    target.AddComponent<ScrollRect>().viewport = target.GetComponent<RectTransform>();
                    break;
                case "SliderObjectData":
                    AddSlider(target, node);
                    break;
                case "ParticleObjectData":
                    target.AddComponent<ParticleSystem>();
                    break;
            }
        }

        private static Image AddImage(GameObject target, UiNode node, string preferredProperty)
        {
            Image image = target.AddComponent<Image>();
            image.color = node.color?.Value ?? Color.white;
            image.raycastTarget = node.touchEnabled;
            UiResource resource = FindResource(node, preferredProperty) ?? FindFirstImage(node);
            if (HasRenderableResource(resource))
                image.sprite = LoadSpriteAtPath(resource.assetPath, resource.spriteName);
            else
                image.color = new Color(image.color.r, image.color.g, image.color.b, 0f);
            image.type = node.scale9 ? Image.Type.Sliced : Image.Type.Simple;
            return image;
        }

        private static bool HasRenderableResource(UiResource resource)
        {
            return resource != null
                   && !string.IsNullOrWhiteSpace(resource.path)
                   && !string.Equals(resource.type, "Default", StringComparison.OrdinalIgnoreCase)
                   && !string.IsNullOrWhiteSpace(resource.assetPath);
        }

        private static void AddButton(GameObject target, UiNode node)
        {
            Image image = AddImage(target, node, "NormalFileData");
            Button button = target.AddComponent<Button>();
            button.targetGraphic = image;
            button.interactable = node.touchEnabled;
            SpriteState state = button.spriteState;
            state.pressedSprite = LoadSprite(node, "PressedFileData");
            state.disabledSprite = LoadSprite(node, "DisabledFileData");
            button.spriteState = state;
            if (!string.IsNullOrWhiteSpace(node.text))
                AddLabelChild(target.transform, node);
        }

        private static void AddToggle(GameObject target, UiNode node)
        {
            Image image = AddImage(target, node, "NormalBackFileData");
            Image checkmark = AddChildImage(target.transform, "__Checkmark", node, "NodeNormalFileData");
            Toggle toggle = target.AddComponent<Toggle>();
            toggle.targetGraphic = image;
            toggle.graphic = checkmark;
            toggle.isOn = node.@checked;
            toggle.interactable = node.touchEnabled;
            SpriteState state = toggle.spriteState;
            state.pressedSprite = LoadSprite(node, "PressedBackFileData");
            state.disabledSprite = LoadSprite(node, "DisableBackFileData");
            toggle.spriteState = state;
        }

        private static void AddSlider(GameObject target, UiNode node)
        {
            Image background = AddImage(target, node, "BackGroundData");
            Image fill = AddChildImage(target.transform, "__Fill", node, "ProgressBarData");
            Image handle = AddChildImage(target.transform, "__Handle", node, "BallNormalData");
            Slider slider = target.AddComponent<Slider>();
            slider.fillRect = fill.rectTransform;
            slider.handleRect = handle.rectTransform;
            slider.targetGraphic = handle;
            slider.interactable = node.touchEnabled;
            slider.value = Mathf.Clamp01(node.progress);
            SpriteState state = slider.spriteState;
            state.pressedSprite = LoadSprite(node, "BallPressedData");
            state.disabledSprite = LoadSprite(node, "BallDisabledData");
            slider.spriteState = state;
            background.raycastTarget = false;
        }

        private static Image AddChildImage(
            Transform parent,
            string name,
            UiNode node,
            string property)
        {
            var child = new GameObject(name, typeof(RectTransform));
            RectTransform rect = (RectTransform)child.transform;
            rect.SetParent(parent, false);
            Stretch(rect, 0f);
            Image image = child.AddComponent<Image>();
            image.sprite = LoadSprite(node, property);
            image.color = node.color?.Value ?? Color.white;
            image.raycastTarget = false;
            return image;
        }

        private static Text AddText(GameObject target, UiNode node, string value, bool raycast)
        {
            Text text = target.AddComponent<Text>();
            text.text = value ?? string.Empty;
            text.font = AssetDatabase.LoadAssetAtPath<Font>(node.fontAssetPath);
            if (text.font == null)
                throw new MissingReferenceException(
                    $"Font import failed for {node.nodePath}: {node.fontAssetPath}");
            text.fontSize = Mathf.Max(1, node.fontSize);
            text.color = node.color?.Value ?? Color.white;
            text.raycastTarget = raycast;
            if (Enum.TryParse(node.alignment, out TextAnchor anchor))
                text.alignment = anchor;
            if (node.outlineEnabled)
            {
                Outline outline = target.AddComponent<Outline>();
                outline.effectColor = node.outlineColor?.Value ?? Color.black;
                float size = Mathf.Max(0f, node.outlineSize);
                outline.effectDistance = new Vector2(size, -size);
                outline.useGraphicAlpha = true;
            }
            if (node.shadowEnabled)
            {
                Shadow shadow = target.AddComponent<Shadow>();
                shadow.effectColor = node.shadowColor?.Value ?? new Color(0f, 0f, 0f, 0.5f);
                shadow.effectDistance = node.shadowOffset?.Value ?? new Vector2(2f, -2f);
                shadow.useGraphicAlpha = true;
            }
            return text;
        }

        private static void AddInputField(GameObject target, UiNode node)
        {
            Image background = target.AddComponent<Image>();
            background.color = new Color(1f, 1f, 1f, 0.05f);
            InputField field = target.AddComponent<InputField>();
            field.targetGraphic = background;
            field.interactable = node.touchEnabled;

            var textObject = new GameObject("Text", typeof(RectTransform));
            RectTransform textRect = (RectTransform)textObject.transform;
            textRect.SetParent(target.transform, false);
            Stretch(textRect, 4f);
            field.textComponent = AddText(textObject, node, node.text, true);

            var placeholderObject = new GameObject("Placeholder", typeof(RectTransform));
            RectTransform placeholderRect = (RectTransform)placeholderObject.transform;
            placeholderRect.SetParent(target.transform, false);
            Stretch(placeholderRect, 4f);
            Text placeholder = AddText(placeholderObject, node, node.placeholder, false);
            placeholder.color = new Color(1f, 1f, 1f, 0.5f);
            field.placeholder = placeholder;
        }

        private static void AddLabelChild(Transform parent, UiNode node)
        {
            var labelObject = new GameObject("__Label", typeof(RectTransform));
            RectTransform rect = (RectTransform)labelObject.transform;
            rect.SetParent(parent, false);
            Stretch(rect, 0f);
            Text label = AddText(labelObject, node, node.text, false);
            label.color = node.textColor?.Value ?? Color.white;
        }

        private static void Stretch(RectTransform rect, float inset)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(inset, inset);
            rect.offsetMax = new Vector2(-inset, -inset);
        }

        private static UiResource FindResource(UiNode node, string property)
        {
            if (node.resources == null)
                return null;
            return Array.Find(node.resources, item =>
                string.Equals(item.property, property, StringComparison.OrdinalIgnoreCase));
        }

        private static UiResource FindFirstImage(UiNode node)
        {
            if (node.resources == null)
                return null;
            return Array.Find(node.resources, item =>
                !string.IsNullOrWhiteSpace(item.assetPath)
                && item.assetPath.EndsWith(".png", StringComparison.OrdinalIgnoreCase));
        }

        private static Sprite LoadSprite(UiNode node, string property)
        {
            UiResource resource = FindResource(node, property);
            return resource == null || string.IsNullOrWhiteSpace(resource.assetPath)
                ? null
                : LoadSpriteAtPath(resource.assetPath, resource.spriteName);
        }

        private static Sprite LoadSpriteAtPath(string assetPath, string spriteName)
        {
            if (string.IsNullOrWhiteSpace(assetPath))
                return null;
            if (string.IsNullOrWhiteSpace(spriteName))
                return AssetDatabase.LoadAssetAtPath<Sprite>(assetPath);
            foreach (UnityEngine.Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
                if (asset is Sprite sprite
                    && string.Equals(sprite.name, spriteName, StringComparison.Ordinal))
                    return sprite;

            if (NormalizeSharedUiSprites.TryResolveNormalizedAlias(
                    assetPath, spriteName, out string canonicalName, out Vector4 canonicalBorder))
            {
                foreach (UnityEngine.Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
                    if (asset is Sprite sprite
                        && string.Equals(sprite.name, canonicalName, StringComparison.Ordinal)
                        && sprite.border == canonicalBorder)
                        return sprite;
            }
            return null;
        }

        private static Vector4 ExpectedSpriteBorder(SpriteBorderDefinition definition)
        {
            return NormalizeSharedUiSprites.TryResolveNormalizedAlias(
                definition.assetPath, definition.spriteName,
                out _, out Vector4 canonicalBorder)
                ? canonicalBorder
                : definition.border?.Value ?? Vector4.zero;
        }

        private static void CreatePreviewScene(ImportManifest manifest)
        {
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var canvasObject = new GameObject(
                "Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            Canvas canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1334f, 750f);
            scaler.matchWidthOrHeight = 0.5f;
            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var previewPrefabs = new List<GameObject>();
            foreach (ImportDocument item in manifest.documents)
            {
                if (!item.preview)
                    continue;
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(item.prefabAssetPath);
                if (prefab != null)
                    previewPrefabs.Add(prefab);
            }

            bool hasMain = previewPrefabs.Exists(item => item.name == "UImainLayer_new");
            for (int index = 0; index < previewPrefabs.Count; index++)
            {
                GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(
                    previewPrefabs[index], canvasObject.transform);
                instance.SetActive(instance.name == "UImainLayer_new" || (!hasMain && index == 0));
            }

            EnsureAssetFolder(Path.GetDirectoryName(manifest.previewScene)?.Replace('\\', '/'));
            EditorSceneManager.SaveScene(scene, manifest.previewScene);
        }

        private static string SafeName(string value)
        {
            return string.IsNullOrWhiteSpace(value)
                ? "Node"
                : value.Replace('/', '_').Replace('\\', '_');
        }

        private static bool IsNativeMaintenance()
        {
            string settings = ToAbsolutePath("ProjectSettings/ProjectXUiMaintenance.json");
            if (File.Exists(settings)
                && (string)JObject.Parse(File.ReadAllText(settings))["maintenanceMode"] == "unity-native-only")
                return true;
            string manifest = ToAbsolutePath(ManifestPath);
            return File.Exists(manifest)
                && (string)JObject.Parse(File.ReadAllText(manifest))["maintenanceMode"] == "unity-native-only";
        }

        private static string ToAbsolutePath(string assetPath)
        {
            string projectRoot = Directory.GetParent(Application.dataPath)?.FullName
                                 ?? throw new InvalidOperationException("Unity project root is unavailable.");
            return Path.Combine(projectRoot, assetPath.Replace('/', Path.DirectorySeparatorChar));
        }

        private static void EnsureAssetFolder(string assetFolder)
        {
            if (string.IsNullOrWhiteSpace(assetFolder) || AssetDatabase.IsValidFolder(assetFolder))
                return;
            string parent = Path.GetDirectoryName(assetFolder)?.Replace('\\', '/');
            EnsureAssetFolder(parent);
            AssetDatabase.CreateFolder(parent, Path.GetFileName(assetFolder));
        }
    }
}
