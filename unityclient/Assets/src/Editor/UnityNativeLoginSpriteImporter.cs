using System;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public sealed class UnityNativeLoginSpriteImporter : AssetPostprocessor
    {
        private const string SpriteRoot = "Assets/Art/AnimationFrames/Login/SpriteFrames/";

        private void OnPreprocessTexture()
        {
            if (!assetPath.StartsWith(SpriteRoot, StringComparison.OrdinalIgnoreCase)) return;
            if (!(assetImporter is TextureImporter importer)) return;

            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.spritePixelsPerUnit = 100f;
            importer.spritePivot = new Vector2(0.5f, 0.5f);
            importer.npotScale = TextureImporterNPOTScale.None;
            importer.maxTextureSize = 4096;
            importer.mipmapEnabled = false;
            importer.alphaSource = TextureImporterAlphaSource.FromInput;
            importer.alphaIsTransparency = true;
            importer.sRGBTexture = true;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.isReadable = false;
        }
    }
}
