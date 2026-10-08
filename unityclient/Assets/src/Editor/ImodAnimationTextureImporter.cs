using System;
using UnityEditor;

namespace ProjectX.Editor
{
    public sealed class ImodAnimationTextureImporter : AssetPostprocessor
    {
        private const string AnimationRoot = "Assets/Resources/ProjectXAnimation/";
        private static readonly string[] LegacyAnimationRoots =
        {
            AnimationRoot + "CopyRes/",
            AnimationRoot + "hero/",
            AnimationRoot + "item/",
            AnimationRoot + "Monster/",
            AnimationRoot + "NPC/",
            AnimationRoot + "res2/",
            AnimationRoot + "UI/"
        };
        private static readonly string[] LegacyStandaloneTextures =
        {
            AnimationRoot + "jiazaiquan.png"
        };

        private void OnPreprocessTexture()
        {
            if (!IsLegacyAnimationAsset(assetPath)) return;
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

        private static bool IsLegacyAnimationAsset(string path)
        {
            foreach (string texturePath in LegacyStandaloneTextures)
                if (string.Equals(path, texturePath, StringComparison.OrdinalIgnoreCase)) return true;
            foreach (string root in LegacyAnimationRoots)
                if (path.StartsWith(root, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }
    }
}
