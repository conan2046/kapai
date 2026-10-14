using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using Newtonsoft.Json.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace ProjectX.Editor
{
    public static class AlchemyPrefabBindings
    {
        [MenuItem("ProjectX/DongFu/Bind Alchemy Realm Selection Sprite")]
        public static void BindRealmSelectionSprite()
        {
            BindGroupedListPrefab("Assets/Prefabs/DongFu/DongFuAlchemy.prefab");
        }
        [MenuItem("ProjectX/DongFu/Bind Shared Group Lists")]
        public static void BindSharedGroupLists()
        {
            foreach(string name in new[]{"DongFuAlchemy","DongFuLibrary","DongFuForge"})
                BindGroupedListPrefab("Assets/Prefabs/DongFu/"+name+".prefab");
        }
        static void BindGroupedListPrefab(string path)
        {
            if(EditorApplication.isPlayingOrWillChangePlaymode)throw new InvalidOperationException("境界图片绑定需非Play编辑器。");
            var stage=PrefabStageUtility.GetCurrentPrefabStage();
            if(stage!=null&&stage.scene.isDirty)throw new InvalidOperationException("请先保存当前预制体修改。");
            var sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_login/ui_btn_fuwuqi_xuanzhong.png");
            if(sprite==null)throw new InvalidOperationException("境界选中图片不存在。");
            string authored=File.ReadAllText(path);
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                var list=root.GetComponent<GroupedTemplateList>()??root.AddComponent<GroupedTemplateList>();
                var serialized=new SerializedObject(list);serialized.FindProperty("selectedHeaderSprite").objectReferenceValue=sprite;
                serialized.ApplyModifiedPropertiesWithoutUndo();
                MonoBehaviour screen=root.GetComponent<AlchemyScreen>();
                if(screen==null)screen=root.GetComponent<LibraryScreen>();
                if(screen!=null){var binding=new SerializedObject(screen);binding.FindProperty("groupedList").objectReferenceValue=list;binding.ApplyModifiedPropertiesWithoutUndo();}
                PrefabUtility.SaveAsPrefabAsset(root,path,out bool success);if(!success)throw new InvalidOperationException("境界图片绑定保存失败。");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
            PreserveAuthoredRects(path,authored);
        }
        static void PreserveAuthoredRects(string path,string authored)
        {
            // Loading a prefab into an isolated scene can recompute its root localPosition.
            // Component-only binding must preserve every authored RectTransform verbatim.
            var pattern=new Regex(@"^--- !u!224 &(\d+)(?: stripped)?\r?\n.*?(?=^--- !u!|\z)",RegexOptions.Multiline|RegexOptions.Singleline);
            var original=pattern.Matches(authored).Cast<Match>().ToDictionary(x=>x.Groups[1].Value,x=>x.Value);
            string saved=File.ReadAllText(path);
            string preserved=pattern.Replace(saved,m=>original.TryGetValue(m.Groups[1].Value,out string block)?block:m.Value);
            if(preserved==saved)return;
            File.WriteAllText(path,preserved,new UTF8Encoding(false));
            AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceUpdate);
        }
        [MenuItem("ProjectX/DongFu/Bind Alchemy Authored Templates")]
        public static void Apply()
        {
            if(EditorApplication.isPlayingOrWillChangePlaymode)throw new InvalidOperationException("炼丹绑定需非Play编辑器。");
            var stage=PrefabStageUtility.GetCurrentPrefabStage();
            if(stage!=null&&stage.scene.isDirty)throw new InvalidOperationException("请先保存当前预制体修改。");
            const string path="Assets/Prefabs/DongFu/DongFuAlchemy.prefab";
            bool reopen=stage!=null&&stage.assetPath==path;if(reopen)StageUtility.GoToMainStage();
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                foreach(string node in new[]{"Workbench/FurnaceArt/item/Icon","Workbench/Materials/Material/Icon","Workbench/Materials/Material/value","Workbench/Panel_3/Count/Value","States/Popup/shuxing/bg/Attribute"})
                    if(root.transform.Find(node)==null)throw new InvalidOperationException("炼丹绑定节点缺失："+node);
                if(!root.GetComponent<AlchemyScreen>())root.AddComponent<AlchemyScreen>();
                PrefabUtility.SaveAsPrefabAsset(root,path,out bool success);if(!success)throw new InvalidOperationException("炼丹绑定保存失败。");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
            BindRealmSelectionSprite();RegisterReward();RegisterIcons();AssetDatabase.SaveAssets();
            if(reopen)AssetDatabase.OpenAsset(AssetDatabase.LoadAssetAtPath<GameObject>(path));
        }
        static void RegisterReward()
        {
            var prefab=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Retained/common/ItemGet.prefab");
            const string referencePath="Assets/Prefabs/Catalog/ItemGet.asset";
            var reference=AssetDatabase.LoadAssetAtPath<UiPrefabReference>(referencePath);
            if(!reference){reference=ScriptableObject.CreateInstance<UiPrefabReference>();AssetDatabase.CreateAsset(reference,referencePath);}
            reference.SetPrefab(prefab);EditorUtility.SetDirty(reference);
            var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");
            catalog.Replace(catalog.Entries.Where(x=>x.Key!="ItemGet").Concat(new[]{new UiPrefabCatalogEntry("ItemGet","Unity/ItemGet","",false)}).ToArray());EditorUtility.SetDirty(catalog);
            AddReference("UiPrefabs/ItemGet",referencePath);
        }
        static void RegisterIcons()
        {
            foreach(string path in Directory.GetFiles("Assets/Art/Icons/Items","equip5????.png"))
            {
                int picture;if(!int.TryParse(Path.GetFileNameWithoutExtension(path).Substring(5),out picture)||picture<50000||picture>=52000)continue;
                AddReference("Art/Icons/Items/"+Path.GetFileNameWithoutExtension(path),path.Replace('\\','/'));
            }
        }
        static void AddReference(string key,string path)
        {
            const string settings="ProjectSettings/ProjectXAssetReferences.json";var entries=JArray.Parse(File.ReadAllText(settings));
            if(!entries.OfType<JObject>().Any(x=>(string)x["key"]==key)){entries.Add(new JObject{["key"]=key,["guid"]=AssetDatabase.AssetPathToGUID(path)});File.WriteAllText(settings,entries+"\n");}
            UnityNativeUiAssetValidator.RebuildResourceReference(key);
        }
    }
}
