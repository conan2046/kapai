using System;
using UnityEditor;

namespace ProjectX.Editor
{
    public sealed class ImodAnimationTextureImporter : AssetPostprocessor
    {
        private const string AnimationRoot = "Assets/ProjectX/Resources/ProjectXAnimation/";

        private void OnPreprocessTexture()
        {
            if (!assetPath.StartsWith(AnimationRoot, StringComparison.OrdinalIgnoreCase)) return;
            if (!(assetImporter is TextureImporter importer)) return;
            importer.textureType = TextureImporterType.Default;
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
