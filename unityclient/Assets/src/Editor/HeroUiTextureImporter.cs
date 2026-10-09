using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    public sealed class HeroUiTextureImporter : AssetPostprocessor
    {
        public static void Import()
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            UnityEngine.Debug.Log("HeroUiImportComplete");
        }

        private void OnPreprocessTexture()
        {
            if (!assetPath.StartsWith("Assets/Art/Icons/Hero/")) return;
            if (!(assetImporter is TextureImporter importer)) return;
            // Existing .meta files own their settings; defaults apply only to new assets.
            if (!importer.importSettingsMissing) return;
            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Single;
            importer.alphaSource = TextureImporterAlphaSource.FromInput;
            importer.alphaIsTransparency = true;
            importer.mipmapEnabled = false;
            importer.wrapMode = TextureWrapMode.Clamp;
            importer.filterMode = FilterMode.Bilinear;
            importer.textureCompression = TextureImporterCompression.Uncompressed;
            importer.spritePixelsPerUnit = 100f;
        }
    }
}
