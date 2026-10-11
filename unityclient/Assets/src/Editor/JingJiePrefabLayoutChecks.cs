using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Core;
using ProjectX.Data;
using ProjectX.Foundation;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class JingJiePrefabLayoutChecks
    {
        public static string Run()
        {
            CheckAuthoredAuraPrefabs();
            ResourceLoader.Configure(new UnityResourceLoader());
            var realm = UnityEngine.Object.Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/OneLevel/JingjieLayer.prefab"));
            var preview = UnityEngine.Object.Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/OneLevel/Jingjieyulan.prefab"));
            JingJieRenderBridge bridge = null;
            using (var resources = new ResourceService())
            try
            {
                var config = new JingJieConfigData();
                var state = new JingJieViewState();
                RectTransform requirement = realm.transform.Find("JingjieUI/Panel/Panel_tupo/bg_limit/ExperienceRequirement") as RectTransform;
                // Prove hand edits remain the source of truth after binding and repeated rendering.
                requirement.anchoredPosition += new Vector2(13f, 17f);
                requirement.sizeDelta = new Vector2(481f, 109f);
                requirement.GetComponent<Text>().fontSize = 31;
                Button movedPreview = realm.GetComponentsInChildren<Button>(true).Single(button => button.name == "Btn_xiangxi");
                movedPreview.transform.SetParent(realm.transform, false);
                foreach (Text text in realm.GetComponentsInChildren<Text>(true)) text.color = new Color(.31f, .67f, .83f, 1f);
                foreach (Text text in preview.GetComponentsInChildren<Text>(true)) text.color = new Color(.73f, .29f, .61f, 1f);
                requirement.GetComponent<Text>().color = Color.white;
                var before = Snapshot(realm);
                var previewBefore = Snapshot(preview);
                int realmNodes = realm.GetComponentsInChildren<Transform>(true).Length;
                int previewNodes = preview.GetComponentsInChildren<Transform>(true).Length;
                bridge = new JingJieRenderBridge(new UnityUiView(realm), new UnityUiView(preview), state,
                    config, new PlayerStore(), new CurrencyStore(), new BagStore(), resources, () => {}, _ => {});
                if (bridge.PreviewControl != movedPreview) throw new Exception("Preview binding depends on its old parent path.");
                if (realm.GetComponentsInChildren<Transform>(true).Count(t => t.name == "SpineAnchor") != 1
                    || realm.GetComponentsInChildren<Transform>(true).Count(t => t.name == "Attr_List") != 1)
                    throw new Exception("Realm must contain one role anchor and one comparison list.");
                Transform comparison = realm.transform.Find("JingjieUI/Panel/AttributeComparison");
                foreach (int id in new[] { 1, 10, 100, 550 })
                {
                    var definition = config.Get(id);
                    state.ApplySnapshot(new JingJieSnapshot { Id=id, Experience="9007199254740997", NeedExperience=definition.RequiredExperience.ToString(),
                        Revision=id.ToString(), Power="1", Rate=definition.ExperiencePerSecond, NextId=id==550?0:id+1,
                        IntervalMilliseconds=5000, ServerMilliseconds="1700000000100", CycleMilliseconds="1700000000000" });
                    AssertSame(before, Snapshot(realm), "realm tier " + id);
                    if (comparison.Find("CurrentStage").GetComponent<Text>().text != definition.Name
                        || comparison.Find("NextStage").GetComponent<Text>().text != (id == 550 ? "已达最高境界" : config.Get(id + 1).Name))
                        throw new Exception("Comparison headings do not use current/next realm names.");
                    if (id == 100)
                    {
                        Transform attack = comparison.Find("Attr_List/Attribute1");
                        if (attack.Find("Value_1").GetComponent<Text>().text != "3262"
                            || attack.Find("Value_2").GetComponent<Text>().text != "3317"
                            || attack.Find("Value_3").GetComponent<Text>().text != "55")
                            throw new Exception("Stage 100 attack comparison values are incorrect.");
                        Transform percent = comparison.Find("Attr_List/Attribute5");
                        if (percent.Find("Value_3").GetComponent<Text>().text != "0.04%")
                            throw new Exception("Percent comparison must show percentage-point gain.");
                    }
                    if (id == 550 && comparison.Find("Attr_List/Attribute1/To").gameObject.activeSelf)
                        throw new Exception("Maximum realm must hide the next-stage arrow.");
                    if (requirement.GetComponent<Text>().text.Contains("成功率") || requirement.GetComponent<Text>().text.Contains("保底")
                        || requirement.GetComponent<Text>().text.Contains("失败")) throw new Exception("Retired probability/failure UI remains.");
                }
                var guaranteed = config.Get(10);
                state.ApplySnapshot(new JingJieSnapshot { Id=10, Experience="0", NeedExperience=guaranteed.RequiredExperience.ToString(),
                    Revision="551", Power="1", Rate=guaranteed.ExperiencePerSecond, NextId=11, Failures=guaranteed.FailureThreshold,
                    IntervalMilliseconds=5000, ServerMilliseconds="1700000000100", CycleMilliseconds="1700000000000" });
                AssertSame(before, Snapshot(realm), "insufficient experience with guaranteed trial");
                if (requirement.GetComponent<Text>().text != $"修为 {0:N0} / {guaranteed.RequiredExperience:N0}")
                    throw new Exception("Experience label includes extra trial details.");
                if (requirement.GetComponent<Text>().fontSize != 31) throw new Exception("Runtime changed authored font size.");
                bridge.ShowPreview();
                AssertSame(previewBefore, Snapshot(preview), "preview first open");
                var scroller = preview.GetComponentInChildren<JingJiePreviewScroller>(true);
                scroller.OnScroll(new PointerEventData(null) { scrollDelta=new Vector2(0f, -100000f) });
                if (!preview.GetComponentsInChildren<Text>(true).Any(t => t.gameObject.activeInHierarchy && t.text==config.Get(550).Name))
                    throw new Exception("Virtual preview cannot reach tier 550.");
                bridge.HidePreview(); bridge.ShowPreview();
                AssertSame(previewBefore, Snapshot(preview), "preview reopen after scrolling");
                if (realm.GetComponentsInChildren<Transform>(true).Length != realmNodes || preview.GetComponentsInChildren<Transform>(true).Length != previewNodes)
                    throw new Exception("Renderer created or destroyed authored layout nodes.");
                foreach (GameObject root in new[] { realm, preview })
                    foreach (Transform node in root.GetComponentsInChildren<Transform>(true))
                        if (GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(node.gameObject)>0)
                            throw new Exception("Missing serialized component on " + node.name);
                string report="PASS: reparented preview button binds correctly; one realm role/list; named current/next headings; stage100 3262->3317 gain55 and percentage gain0.04%; maximum hides next arrow; main/realm aura references valid; authored geometry/font/colors preserved across 1/10/100/550 and insufficient/guaranteed trial; no probability/failure UI; no layout nodes spawned; preview reaches550/reopens correctly.";
                System.IO.File.WriteAllText(System.IO.Path.Combine(Application.dataPath,"../../.local/jingjie-rework/prefab-layout-checks.txt"),report);
                return report;
            }
            finally
            {
                bridge?.Dispose();
                UnityEngine.Object.DestroyImmediate(realm);
                UnityEngine.Object.DestroyImmediate(preview);
            }
        }
        // The shared aura is consumed by both the main HUD and the realm panels.
        public static string CheckAuthoredAuraPrefabs()
        {
            int count = 0;
            foreach (string path in new[] { "Assets/Prefabs/Main/UImainLayer_new.prefab", "Assets/Prefabs/OneLevel/JingjieLayer.prefab" })
            {
                GameObject root = UnityEngine.Object.Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>(path));
                try
                {
                    var before = Snapshot(root);
                    RoleCultivationAura[] auras = root.GetComponentsInChildren<RoleCultivationAura>(true);
                    if (auras.Length != 1)
                        throw new Exception("Authored aura consumer missing: " + path);
                    foreach (RoleCultivationAura aura in auras)
                    {
                        var glow = new SerializedObject(aura).FindProperty("glow").objectReferenceValue as RawImage;
                        if (glow == null || glow.texture == null || glow.raycastTarget || glow.transform.parent != aura.transform)
                            throw new Exception("Authored aura glow invalid: " + path);
                        foreach (int stage in new[] { 1, 10 }) aura.Show(stage, Color.yellow);
                        count++;
                    }
                    AssertSame(before, Snapshot(root), "authored aura " + path);
                }
                finally { UnityEngine.Object.DestroyImmediate(root); }
            }
            return "PASS: all " + count + " main/realm aura consumers have serialized graphics; Show preserves authored transforms.";
        }
        private static Dictionary<string,string> Snapshot(GameObject root)
        {
            // Scrollbar owns its handle geometry as the authoritative cycle progresses.
            var drivenHandles = new HashSet<RectTransform>(root.GetComponentsInChildren<Scrollbar>(true)
                .Select(bar => bar.handleRect).Where(rect => rect != null));
            return root.GetComponentsInChildren<RectTransform>(true).Where(t => !drivenHandles.Contains(t))
                .ToDictionary(t => AnimationUtility.CalculateTransformPath(t,root.transform), t => t.anchorMin+"/"+t.anchorMax+"/"+t.pivot+"/"+t.anchoredPosition+"/"+t.sizeDelta+"/"+t.localScale
                    + (t.GetComponent<Text>() is Text text ? "/" + text.color + "/" + text.fontSize : string.Empty));
        }
        private static void AssertSame(Dictionary<string,string> before, Dictionary<string,string> after, string phase)
        {
            foreach (var pair in before)
                if (!after.TryGetValue(pair.Key,out string value) || value!=pair.Value)
                    throw new Exception("Runtime changed prefab geometry at " + phase + ": " + pair.Key);
        }
    }
}
