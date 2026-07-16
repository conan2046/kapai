using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
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

        [Serializable] private sealed class ImportManifest
        {
            public ImportDocument[] documents;
            public SpriteBorderDefinition[] spriteBorders;
            public string previewScene;
        }

        [Serializable] private sealed class SpriteBorderDefinition
        {
            public string assetPath;
            public UiVector4 border;
        }

        [Serializable] private sealed class ImportDocument
        {
            public string name;
            public string source;
            public bool preview;
            public string documentAssetPath;
            public string prefabAssetPath;
        }

        [Serializable] private sealed class UiDocument
        {
            public string name;
            public string source;
            public UiNode root;
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
        }

        [MenuItem("Tools/ProjectX UI/Import All Prefabs")]
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

        public static void ValidateBaselinesBatch()
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(ToAbsolutePath(ManifestPath)));
            ValidationSummary summary = ValidateBaselines(manifest);
            Debug.Log(
                $"ProjectX UI validation completed: {summary.prefabs} prefabs, "
                + $"{summary.nodes} nodes, {summary.sprites} sprites, "
                + $"{summary.slicedSprites} sliced variants, {summary.texts} texts, "
                + $"{summary.outlinedTexts} outlines, {summary.shadowedTexts} shadows, "
                + $"{summary.spriteBindings} sprite bindings, 0 errors.");
        }

        private static void ImportBaselines(bool createPreview)
        {
            string manifestFile = ToAbsolutePath(ManifestPath);
            if (!File.Exists(manifestFile))
                throw new FileNotFoundException("Unity migration manifest is missing", manifestFile);

            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            ImportManifest manifest = JsonConvert.DeserializeObject<ImportManifest>(
                File.ReadAllText(manifestFile));
            if (manifest.documents == null || manifest.documents.Length == 0)
                throw new InvalidDataException("Unity migration manifest contains no documents.");

            ConfigurePlayerSettings();
            ConfigureReferencedTextures(manifest);
            var createdPrefabs = new List<GameObject>();
            foreach (ImportDocument item in manifest.documents)
            {
                UiDocument document = ReadDocument(item.documentAssetPath);
                EnsureAssetFolder(Path.GetDirectoryName(item.prefabAssetPath)?.Replace('\\', '/'));
                GameObject root = BuildDocument(document);
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

        private static void ConfigurePlayerSettings()
        {
            PlayerSettings.defaultScreenWidth = 1334;
            PlayerSettings.defaultScreenHeight = 750;
            PlayerSettings.defaultIsNativeResolution = false;
            PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
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

        private static ValidationSummary ValidateBaselines(ImportManifest manifest)
        {
            var summary = new ValidationSummary();
            var spritePaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (ImportDocument item in manifest.documents)
            {
                UiDocument document = ReadDocument(item.documentAssetPath);
                int expectedNodes = CountNodes(document.root);
                GameObject prefab = AssetDatabase.LoadAssetAtPath<GameObject>(item.prefabAssetPath);
                if (prefab == null)
                    throw new InvalidDataException($"Generated prefab is missing: {item.prefabAssetPath}");
                CocosUiBinding binding = prefab.GetComponent<CocosUiBinding>();
                if (binding == null || binding.Nodes.Count != expectedNodes)
                    throw new InvalidDataException(
                        $"Binding count mismatch in {item.prefabAssetPath}: "
                        + $"expected {expectedNodes}, actual {binding?.Nodes.Count ?? 0}");
                int metadataCount = prefab.GetComponentsInChildren<CocosNodeMetadata>(true).Length;
                if (metadataCount != expectedNodes)
                    throw new InvalidDataException(
                        $"Node count mismatch in {item.prefabAssetPath}: "
                        + $"expected {expectedNodes}, actual {metadataCount}");
                foreach (CocosNodeReference reference in binding.Nodes)
                    if (reference.target == null)
                        throw new MissingReferenceException(
                            $"Null binding target in {item.prefabAssetPath}: {reference.path}");
                foreach (Transform transform in prefab.GetComponentsInChildren<Transform>(true))
                    if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(transform.gameObject) != 0)
                        throw new MissingReferenceException(
                            $"Missing script in {item.prefabAssetPath}: {transform.name}");
                CollectTexturePaths(document.root, spritePaths);
                ValidateTextStyles(document.root, binding, summary);
                ValidateSpriteBindings(document.root, binding, summary);
                summary.prefabs++;
                summary.nodes += expectedNodes;
            }

            foreach (string assetPath in spritePaths)
                if (AssetDatabase.LoadAssetAtPath<Sprite>(assetPath) == null)
                    throw new MissingReferenceException($"Sprite import failed: {assetPath}");
            summary.sprites = spritePaths.Count;
            if (manifest.spriteBorders != null)
            {
                foreach (SpriteBorderDefinition definition in manifest.spriteBorders)
                {
                    Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(definition.assetPath);
                    if (sprite == null)
                        throw new MissingReferenceException(
                            $"Sliced sprite import failed: {definition.assetPath}");
                    Vector4 expected = definition.border?.Value ?? Vector4.zero;
                    if (expected == Vector4.zero || sprite.border != expected)
                        throw new InvalidDataException(
                            $"Sprite border mismatch in {definition.assetPath}: "
                            + $"expected {expected}, actual {sprite.border}");
                    summary.slicedSprites++;
                }
            }
            if (!File.Exists(ToAbsolutePath(manifest.previewScene)))
                throw new FileNotFoundException("Preview scene is missing", manifest.previewScene);
            return summary;
        }

        private static void ValidateTextStyles(
            UiNode node,
            CocosUiBinding binding,
            ValidationSummary summary)
        {
            GameObject target = binding.Find(node.nodePath, node.nodeType, node.actionTag);
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

            if (node.children != null)
                foreach (UiNode child in node.children)
                    ValidateTextStyles(child, binding, summary);
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
            CocosUiBinding binding,
            ValidationSummary summary)
        {
            GameObject target = binding.Find(node.nodePath, node.nodeType, node.actionTag);
            switch (node.nodeType)
            {
                case "ImageViewObjectData":
                case "SpriteObjectData":
                    ValidateResourceSprite(node, "FileData", target?.GetComponent<Image>()?.sprite, summary);
                    break;
                case "PanelObjectData" when FindResource(node, "FileData") != null:
                    ValidateResourceSprite(node, "FileData", target?.GetComponent<Image>()?.sprite, summary);
                    break;
                case "LoadingBarObjectData":
                    ValidateResourceSprite(node, "ImageFileData", target?.GetComponent<Image>()?.sprite, summary);
                    break;
                case "ButtonObjectData":
                    Button button = target?.GetComponent<Button>();
                    ValidateResourceSprite(node, "NormalFileData", target?.GetComponent<Image>()?.sprite, summary);
                    ValidateResourceSprite(
                        node, "PressedFileData", button != null ? button.spriteState.pressedSprite : null, summary);
                    ValidateResourceSprite(
                        node, "DisabledFileData", button != null ? button.spriteState.disabledSprite : null, summary);
                    break;
                case "CheckBoxObjectData":
                    Toggle toggle = target?.GetComponent<Toggle>();
                    ValidateResourceSprite(node, "NormalBackFileData", target?.GetComponent<Image>()?.sprite, summary);
                    ValidateResourceSprite(
                        node,
                        "NodeNormalFileData",
                        target?.transform.Find("__Checkmark")?.GetComponent<Image>()?.sprite,
                        summary);
                    ValidateResourceSprite(
                        node,
                        "PressedBackFileData",
                        toggle != null ? toggle.spriteState.pressedSprite : null,
                        summary);
                    ValidateResourceSprite(
                        node,
                        "DisableBackFileData",
                        toggle != null ? toggle.spriteState.disabledSprite : null,
                        summary);
                    break;
                case "SliderObjectData":
                    Slider slider = target?.GetComponent<Slider>();
                    ValidateResourceSprite(node, "BackGroundData", target?.GetComponent<Image>()?.sprite, summary);
                    ValidateResourceSprite(
                        node,
                        "ProgressBarData",
                        target?.transform.Find("__Fill")?.GetComponent<Image>()?.sprite,
                        summary);
                    ValidateResourceSprite(
                        node,
                        "BallNormalData",
                        target?.transform.Find("__Handle")?.GetComponent<Image>()?.sprite,
                        summary);
                    ValidateResourceSprite(
                        node,
                        "BallPressedData",
                        slider != null ? slider.spriteState.pressedSprite : null,
                        summary);
                    ValidateResourceSprite(
                        node,
                        "BallDisabledData",
                        slider != null ? slider.spriteState.disabledSprite : null,
                        summary);
                    break;
            }

            if (node.children != null)
                foreach (UiNode child in node.children)
                    ValidateSpriteBindings(child, binding, summary);
        }

        private static void ValidateResourceSprite(
            UiNode node,
            string property,
            Sprite actual,
            ValidationSummary summary)
        {
            UiResource resource = FindResource(node, property);
            if (resource == null
                || string.Equals(resource.type, "Default", StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrWhiteSpace(resource.path)
                || !resource.path.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
                return;
            if (string.IsNullOrWhiteSpace(resource.assetPath))
                throw new MissingReferenceException(
                    $"Sprite asset path is empty in {node.nodePath}/{property}: {resource.path}");
            Sprite expected = AssetDatabase.LoadAssetAtPath<Sprite>(resource.assetPath);
            if (expected == null)
                throw new MissingReferenceException(
                    $"Sprite asset is missing in {node.nodePath}/{property}: {resource.assetPath}");
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

        private static void ConfigureReferencedTextures(ImportManifest manifest)
        {
            var texturePaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var borders = new Dictionary<string, Vector4>(StringComparer.OrdinalIgnoreCase);
            if (manifest.spriteBorders != null)
                foreach (SpriteBorderDefinition definition in manifest.spriteBorders)
                {
                    texturePaths.Add(definition.assetPath);
                    borders[definition.assetPath] = definition.border?.Value ?? Vector4.zero;
                }
            foreach (ImportDocument item in manifest.documents)
                CollectTexturePaths(ReadDocument(item.documentAssetPath).root, texturePaths);

            foreach (string assetPath in texturePaths)
            {
                TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                if (importer == null)
                    continue;
                Vector4 desiredBorder = borders.TryGetValue(assetPath, out Vector4 configuredBorder)
                    ? configuredBorder
                    : Vector4.zero;
                bool changed = importer.textureType != TextureImporterType.Sprite
                               || importer.spriteImportMode != SpriteImportMode.Single
                               || importer.mipmapEnabled
                               || importer.spriteBorder != desiredBorder;
                importer.textureType = TextureImporterType.Sprite;
                importer.spriteImportMode = SpriteImportMode.Single;
                importer.spriteBorder = desiredBorder;
                importer.alphaIsTransparency = true;
                importer.mipmapEnabled = false;
                importer.wrapMode = TextureWrapMode.Clamp;
                importer.filterMode = FilterMode.Bilinear;
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

        private static GameObject BuildDocument(UiDocument document)
        {
            var bindings = new List<CocosNodeReference>();
            GameObject root = BuildNode(document.root, null, bindings);
            root.name = document.name;
            root.AddComponent<CocosUiBinding>().Initialize(document.source, bindings);
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
            gameObject.AddComponent<CocosNodeMetadata>()
                .Initialize(node.nodePath, node.nodeType, node.tag, node.actionTag);
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
                    if (FindResource(node, "FileData") != null)
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
            if (resource != null)
                image.sprite = AssetDatabase.LoadAssetAtPath<Sprite>(resource.assetPath);
            image.type = node.scale9 ? Image.Type.Sliced : Image.Type.Simple;
            return image;
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
                : AssetDatabase.LoadAssetAtPath<Sprite>(resource.assetPath);
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
