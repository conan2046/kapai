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
            if (!assetPath.StartsWith("Assets/ProjectX/Resources/HeroUI/")) return;
            if (!(assetImporter is TextureImporter importer)) return;
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
