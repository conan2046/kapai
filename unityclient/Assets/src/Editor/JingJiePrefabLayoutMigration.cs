using System;
using System.IO;
using System.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    // Explicit one-time migration. Never called on startup or when entering Play.
    public static class JingJiePrefabLayoutMigration
    {
        private const string RealmPath = "Assets/Prefabs/OneLevel/JingjieLayer.prefab";
        private const string PreviewPath = "Assets/Prefabs/OneLevel/Jingjieyulan.prefab";
        [MenuItem("ProjectX/JingJie/Migrate Layout Into Prefabs")]
        public static void Run()
        {
            if (EditorApplication.isPlaying) throw new InvalidOperationException("Exit Play before migrating prefabs.");
            if (AssetDatabase.LoadAssetAtPath<GameObject>(RealmPath).transform.Find("JingjieUI/Panel/AttributeComparison") != null)
                throw new InvalidOperationException("Realm comparison layout is already authored. Edit the prefab directly; do not rerun the legacy migration.");
            string backup = Path.GetFullPath(Path.Combine(Application.dataPath, "../../.local/jingjie-rework/prefab-layout-before"));
            Directory.CreateDirectory(backup);
            foreach (string path in new[] { RealmPath, PreviewPath })
                foreach (string suffix in new[] { "", ".meta" })
                {
                    string copy = Path.Combine(backup, Path.GetFileName(path) + suffix);
                    if (!File.Exists(copy)) File.Copy(path + suffix, copy);
                }
            MigrateRealm();
            MigratePreview();
            AssetDatabase.SaveAssets();
        }

        private static void MigrateRealm()
        {
            GameObject root = PrefabUtility.LoadPrefabContents(RealmPath);
            try
            {
                if (root.GetComponent<PrefabAuthoredLayout>() == null) root.AddComponent<PrefabAuthoredLayout>();
                Transform panel = root.transform.Find("JingjieUI/Panel");
                Transform limit = panel.Find("Panel_tupo/bg_limit");
                if (limit.Find("ExperienceRequirement") == null)
                {
                    GameObject node = UnityEngine.Object.Instantiate(limit.Find("Panel_level/Text/value").gameObject, limit, false);
                    node.name = "ExperienceRequirement";
                    Text text = node.GetComponent<Text>();
                    text.alignment = TextAnchor.MiddleCenter;
                    text.horizontalOverflow = HorizontalWrapMode.Wrap;
                    text.verticalOverflow = VerticalWrapMode.Overflow;
                    text.raycastTarget = false;
                    text.text = "修为 0 / 6,000";
                    Center(text.rectTransform, Vector2.zero, new Vector2(520f, 100f));
                }
                foreach (string path in new[] { "Panel_level", "Panel_zhanli", "Text" }) limit.Find(path).gameObject.SetActive(false);
                panel.Find("Panel_tupo/bg_cost").gameObject.SetActive(false);
                panel.Find("Panel_End").gameObject.SetActive(false);
                Scrollbar bar = panel.Find("expect").GetComponent<Scrollbar>();
                bar.interactable = false;
                bar.navigation = new Navigation { mode = Navigation.Mode.None };
                if (root.GetComponent<JingJieIncomeView>() == null) root.AddComponent<JingJieIncomeView>();
                foreach (string name in new[] { "Panel_L", "Panel_R", "Panel_End" })
                {
                    Transform stage = panel.Find(name);
                    Text title = stage.Find("bg_L/Panel_name/name").GetComponent<Text>();
                    title.horizontalOverflow = HorizontalWrapMode.Overflow;
                    title.verticalOverflow = VerticalWrapMode.Overflow;
                    Transform attributes = stage.Find("Panel_shuxing");
                    Transform list = attributes.Find("Attr_List");
                    Transform template = name == "Panel_End" ? list.Find("Attribute1") : attributes.Find("Attribute1");
                    template.gameObject.SetActive(false);
                    for (int index = 0; index < 7; index++)
                    {
                        if (list.Find("Attribute" + (index + 1)) != null) continue;
                        GameObject row = UnityEngine.Object.Instantiate(template.gameObject, list, false);
                        row.name = "Attribute" + (index + 1);
                        var rect = row.GetComponent<RectTransform>();
                        rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0f, 1f);
                        rect.anchoredPosition = new Vector2(6f, -28f * index);
                        row.SetActive(true);
                    }
                    Transform anchor = stage.Find("bg_L/Icon/SpineAnchor");
                    var aura = anchor.GetComponent<RoleCultivationAura>() ?? anchor.gameObject.AddComponent<RoleCultivationAura>();
                    if (anchor.Find("SmallStageAura") == null)
                    {
                        var node = new GameObject("SmallStageAura", typeof(RectTransform), typeof(CanvasRenderer), typeof(RawImage));
                        node.transform.SetParent(anchor, false);
                        node.transform.SetAsFirstSibling();
                        RawImage glow = node.GetComponent<RawImage>();
                        glow.texture = UnityAssetReference.LoadAsset<Texture2D>("Art/Effects/Textures/fx_glow_01");
                        if (glow.texture == null) throw new InvalidOperationException("Aura texture missing.");
                        glow.raycastTarget = false;
                        glow.color = new Color(1f, .88f, .35f, .2f);
                        Center(glow.rectTransform, new Vector2(0f, 60f), Vector2.one * 225f);
                        var serialized = new SerializedObject(aura);
                        serialized.FindProperty("glow").objectReferenceValue = glow;
                        serialized.ApplyModifiedPropertiesWithoutUndo();
                    }
                }
                GameObject effect = panel.Find("effect_jingjietupo_1").gameObject;
                if (effect.transform.Find("UnityNativeBreakthroughEffect") == null)
                {
                    var native = new GameObject("UnityNativeBreakthroughEffect", typeof(RectTransform), typeof(Animator));
                    var rect = native.GetComponent<RectTransform>();
                    rect.SetParent(effect.transform, false);
                    rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
                    rect.offsetMin = rect.offsetMax = Vector2.zero;
                    Animator animator = native.GetComponent<Animator>();
                    animator.runtimeAnimatorController = UnityAssetReference.LoadAsset<RuntimeAnimatorController>("Animations/JingJie/JingJieBreakthrough");
                    if (animator.runtimeAnimatorController == null) throw new InvalidOperationException("Breakthrough controller missing.");
                    animator.applyRootMotion = false; animator.enabled = false;
                    Sprite[] sprites = UnityAssetReference.LoadAll<Sprite>("Art/UI/JingJie/JingJieBreakthroughAtlas").OrderBy(s => s.name, StringComparer.Ordinal).ToArray();
                    if (sprites.Length != 19) throw new InvalidOperationException("Breakthrough sprites missing.");
                    var part = new GameObject("Part", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                    part.transform.SetParent(native.transform, false);
                    Image image = part.GetComponent<Image>();
                    image.sprite = sprites[0]; image.preserveAspect = true; image.raycastTarget = false;
                    Center(image.rectTransform, Vector2.zero, sprites[0].rect.size);
                }
                if (effect.GetComponent<JingJieEffectLifetime>() == null) effect.AddComponent<JingJieEffectLifetime>();
                effect.SetActive(false);
                PrefabUtility.SaveAsPrefabAsset(root, RealmPath);
            }
            finally { PrefabUtility.UnloadPrefabContents(root); }
        }

        private static void MigratePreview()
        {
            GameObject root = PrefabUtility.LoadPrefabContents(PreviewPath);
            try
            {
                if (root.GetComponent<PrefabAuthoredLayout>() == null) root.AddComponent<PrefabAuthoredLayout>();
                Transform popup = root.transform.Find("Popup");
                Transform list = popup.Find("ListView");
                Transform template = popup.Find("Panel_1");
                template.gameObject.SetActive(false);
                Image hit = list.GetComponent<Image>() ?? list.gameObject.AddComponent<Image>();
                hit.color = Color.clear; hit.raycastTarget = true;
                if (list.GetComponent<JingJiePreviewScroller>() == null) list.gameObject.AddComponent<JingJiePreviewScroller>();
                for (int index = 0; index < 8; index++)
                {
                    if (list.Find("PreviewRow" + (index + 1)) != null) continue;
                    GameObject row = UnityEngine.Object.Instantiate(template.gameObject, list, false);
                    row.name = "PreviewRow" + (index + 1); row.SetActive(true);
                    var rect = row.GetComponent<RectTransform>();
                    rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, 1f);
                    rect.anchoredPosition = new Vector2(0f, -150f * index);
                    Text title = row.transform.Find("title_bg/value").GetComponent<Text>();
                    Center(title.rectTransform, Vector2.zero, title.rectTransform.sizeDelta);
                    title.horizontalOverflow = HorizontalWrapMode.Overflow;
                    title.verticalOverflow = VerticalWrapMode.Overflow;
                    title.alignment = TextAnchor.MiddleCenter;
                }
                PrefabUtility.SaveAsPrefabAsset(root, PreviewPath);
            }
            finally { PrefabUtility.UnloadPrefabContents(root); }
        }
        private static Text NewText(string name, Transform parent, Text source)
        {
            var node = new GameObject(name, typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            node.transform.SetParent(parent, false);
            Text text = node.GetComponent<Text>(); text.font = source.font; text.raycastTarget = false;
            return text;
        }
        private static void Center(RectTransform rect, Vector2 position, Vector2 size)
        {
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = position; rect.sizeDelta = size;
        }
    }
}
