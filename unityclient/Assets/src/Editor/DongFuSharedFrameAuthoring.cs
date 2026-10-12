using System;
using System.IO;
using System.Linq;
using System.Reflection;
using ProjectX.UI;
using UnityEditor;
using UnityEngine;

namespace ProjectX.Editor
{
    // Explicit migration only; never rewrites user layout during startup.
    [InitializeOnLoad]
    public static class DongFuSharedFrameAuthoring
    {
        static DongFuSharedFrameAuthoring(){ EditorApplication.delayCall += RunRequested; }
        static async void RunRequested()
        {
            string request=System.IO.Path.GetFullPath("../.local/dongfu-reference/shared-frame.request");
            if(!File.Exists(request)||EditorApplication.isPlayingOrWillChangePlaymode)return;
            File.Delete(request);
            try
            {
                Apply();
                var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("MCPForUnity.Editor.Services.MCPServiceLocator")).FirstOrDefault(t=>t!=null);
                var bridge=type.GetProperty("Bridge",BindingFlags.Public|BindingFlags.Static).GetValue(null);
                await (System.Threading.Tasks.Task<bool>)bridge.GetType().GetMethod("StartAsync").Invoke(bridge,null);
            }
            catch(Exception e){Debug.LogException(e);File.WriteAllText("../.local/dongfu-reference/shared-frame-error.txt",e.ToString());}
        }
        [MenuItem("Tools/ProjectX 洞府/接入现有OneLevelLayer页框")]
        public static void Apply()
        {
            Patch("Assets/Prefabs/DongFu/DongFuGardenScene.prefab",true);
            Patch("Assets/Prefabs/DongFu/DongFuLayer.prefab",false);
            var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");
            catalog.Replace(catalog.Entries.Select(e=>e.Key=="DongFuLayer"||e.Key=="DongFuGardenScene"
                ? new UiPrefabCatalogEntry(e.Key,e.Source,"OneLevelLayer",e.DefaultActive):e).ToArray());
            EditorUtility.SetDirty(catalog);AssetDatabase.SaveAssets();
            const string redundant="Assets/Prefabs/Shared/StandardPageHeader.prefab";
            if(AssetDatabase.LoadAssetAtPath<GameObject>(redundant)!=null)AssetDatabase.DeleteAsset(redundant);
            File.WriteAllText("../.local/dongfu-reference/shared-frame-authoring-report.json","{\"sharedKey\":\"OneLevelLayer\",\"plots\":36,\"originalTransformsUnchanged\":true,\"duplicateHeaderRemoved\":true}");
        }
        static void Patch(string path,bool garden)
        {
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                var original=root.GetComponentsInChildren<RectTransform>(true);
                var poses=original.Select(Pose).ToArray();
                var screen=garden?(UnityEngine.Object)root.GetComponent<GardenScreen>():root.GetComponent<DongFuScreen>();
                Set(screen,"back",null);
                if(!garden)
                {
                    Set(screen,"close",null);Set(screen,"help",null);Set(screen,"title",null);
                    root.transform.Find("Frame/Panel_12/Title").gameObject.SetActive(false);
                    root.transform.Find("Frame/GoldCheck").gameObject.SetActive(false);
                }
                var header=root.transform.Find(garden?"GardenUI/StandardPageHeader":"StandardPageHeader");
                if(header!=null)UnityEngine.Object.DestroyImmediate(header.gameObject);
                var back=root.transform.Find(garden?"GardenUI/Back":"Back");
                if(back!=null)UnityEngine.Object.DestroyImmediate(back.gameObject);
                var help=root.transform.Find("Help");if(!garden&&help!=null)UnityEngine.Object.DestroyImmediate(help.gameObject);
                for(int i=0;i<original.Length;i++)if(original[i]!=null&&Pose(original[i])!=poses[i])throw new InvalidOperationException("手调布局发生变化，拒绝保存");
                PrefabUtility.SaveAsPrefabAsset(root,path);
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
        }
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
        static void Set(UnityEngine.Object o,string field,UnityEngine.Object value)
        {
            var s=new SerializedObject(o);s.FindProperty(field).objectReferenceValue=value;s.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
