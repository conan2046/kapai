using System;
using System.IO;
using System.Linq;
using Newtonsoft.Json.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class DongFuHomeAuthoring
    {
        [MenuItem("Tools/ProjectX 洞府/绑定独立DongFuHome入口")]
        public static void Apply()
        {
            if(EditorApplication.isPlayingOrWillChangePlaymode)throw new InvalidOperationException("请退出Play后绑定首页");
            Register("DongFuHome",true);
            foreach(string key in new[]{"DongFuSpirit","DongFuAlchemy","DongFuForge","DongFuLibrary"})Register(key,false);
            AssetDatabase.SaveAssets();
        }
        static void Register(string key,bool home)
        {
            string path="Assets/Prefabs/DongFu/"+key+".prefab";
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                if(home)root.GetComponent<RectTransform>().sizeDelta=new Vector2(1334,750);
                var rects=root.GetComponentsInChildren<RectTransform>(true);var before=rects.Select(Pose).ToArray();
                var identity=root.GetComponent<UiPrefabKey>();if(!identity)identity=root.AddComponent<UiPrefabKey>();
                var keyData=new SerializedObject(identity);keyData.FindProperty("key").stringValue=key;keyData.ApplyModifiedPropertiesWithoutUndo();
                if(home)
                {
                    var screen=root.GetComponent<DongFuHomeScreen>();if(!screen)screen=root.AddComponent<DongFuHomeScreen>();
                    var entries=new Button[5];
                    for(int i=0;i<5;i++)
                    {
                        var building=root.GetComponentsInChildren<Transform>(true).Single(t=>t.name=="Building"+i);
                        entries[i]=building.GetComponent<Button>();
                        if(!entries[i])entries[i]=building.GetComponentsInChildren<Button>(true).Single();
                        if(!entries[i].targetGraphic)entries[i].targetGraphic=entries[i].GetComponent<Graphic>();
                        if(entries[i].targetGraphic)entries[i].targetGraphic.raycastTarget=true;
                    }
                    var data=new SerializedObject(screen);var buttons=data.FindProperty("buildingEntries");buttons.arraySize=5;
                    for(int i=0;i<5;i++)buttons.GetArrayElementAtIndex(i).objectReferenceValue=entries[i];data.ApplyModifiedPropertiesWithoutUndo();
                }
                for(int i=0;i<rects.Length;i++)if(before[i]!=Pose(rects[i]))throw new InvalidOperationException("手调布局发生变化，拒绝保存");
                var prefab=PrefabUtility.SaveAsPrefabAsset(root,path);
                string referencePath="Assets/Prefabs/Catalog/"+key+".asset";
                var reference=AssetDatabase.LoadAssetAtPath<UiPrefabReference>(referencePath);
                if(!reference){reference=ScriptableObject.CreateInstance<UiPrefabReference>();AssetDatabase.CreateAsset(reference,referencePath);}
                reference.SetPrefab(prefab);EditorUtility.SetDirty(reference);
                var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");
                catalog.Replace(catalog.Entries.Where(e=>e.Key!=key).Concat(new[]{new UiPrefabCatalogEntry(key,"Unity/DongFu/"+key,"OneLevelLayer",false)}).ToArray());EditorUtility.SetDirty(catalog);
                var refs=JArray.Parse(File.ReadAllText("ProjectSettings/ProjectXAssetReferences.json"));string loadKey="UiPrefabs/"+key;
                if(!refs.OfType<JObject>().Any(e=>(string)e["key"]==loadKey))
                {
                    refs.Add(new JObject{["key"]=loadKey,["guid"]=AssetDatabase.AssetPathToGUID(referencePath)});
                    File.WriteAllText("ProjectSettings/ProjectXAssetReferences.json",refs.ToString()+"\n");
                }
                UnityNativeUiAssetValidator.RebuildResourceReference(loadKey);
                if(home)File.WriteAllText("../.local/dongfu-reference/dongfu-home-authoring-report.json","{\"entry\":\"DongFuHome\",\"buildingButtons\":5,\"manualTransformsUnchanged\":true}");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
        }
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
    }
}
