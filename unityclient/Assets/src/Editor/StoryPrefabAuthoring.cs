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
    public static class StoryPrefabAuthoring
    {
        public static string Build()
        {
            Directory.CreateDirectory("Assets/Prefabs/Story");
            Make("Assets/Prefabs/Retained/DialogLayer.prefab","Assets/Prefabs/Story/StoryDialog.prefab",true);
            Make("Assets/Prefabs/Retained/GuideLayer.prefab","Assets/Prefabs/Story/StoryGuide.prefab",false);
            Reference("UI/StoryDialog","Assets/Prefabs/Story/StoryDialog.prefab");
            Reference("UI/StoryGuide","Assets/Prefabs/Story/StoryGuide.prefab");
            AssetDatabase.SaveAssets();
            return "Story prefabs prepared from retained layouts; originals and existing story layouts preserved.";
        }
        static void Make(string source,string output,bool dialog)
        {
            if(AssetDatabase.LoadAssetAtPath<GameObject>(output)!=null)return;
            var root=PrefabUtility.LoadPrefabContents(source);
            try
            {
                root.name=dialog?"StoryDialog":"StoryGuide";
                if(root.GetComponent<PrefabAuthoredLayout>()==null)root.AddComponent<PrefabAuthoredLayout>();
                foreach(var graphic in root.GetComponentsInChildren<Graphic>(true))graphic.raycastTarget=false;
                if(dialog)
                {
                    var panel=root.transform.Find("DialogUI").gameObject;
                    var image=panel.GetComponent<Image>()??panel.AddComponent<Image>();
                    image.color=Color.clear;image.raycastTarget=true;
                    var button=panel.GetComponent<Button>()??panel.AddComponent<Button>();button.targetGraphic=image;button.transition=Selectable.Transition.None;
                    var skip=panel.transform.Find("Image_1/btn_Skip").GetComponent<Button>();
                    if(skip.targetGraphic!=null)skip.targetGraphic.raycastTarget=true;
                }
                else
                {
                    root.transform.Find("Panel/Panel_1").gameObject.SetActive(false);
                    root.transform.Find("Panel/SelectImage").gameObject.SetActive(false);
                    root.transform.Find("Panel/GuideBg/Text_2").gameObject.SetActive(false);
                    var area=root.transform.Find("Panel/GuideBg").gameObject;
                    var rect=area.GetComponent<RectTransform>();rect.anchorMin=rect.anchorMax=new Vector2(.5f,1f);rect.pivot=new Vector2(.5f,1f);rect.anchoredPosition=new Vector2(0,-105);
                    foreach(var n in new[]{"Image_1","Image_2"}){var child=area.transform.Find(n);if(child!=null)child.gameObject.SetActive(false);}
                    var image=area.GetComponent<Image>()??area.AddComponent<Image>();image.raycastTarget=true;
                    var button=area.GetComponent<Button>()??area.AddComponent<Button>();button.targetGraphic=image;button.transition=Selectable.Transition.None;
                }
                root.SetActive(false);PrefabUtility.SaveAsPrefabAsset(root,output);
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
        }
        static void Reference(string key,string path)
        {
            const string settings="ProjectSettings/ProjectXAssetReferences.json";
            var rows=JArray.Parse(File.ReadAllText(settings));
            var old=rows.OfType<JObject>().FirstOrDefault(x=>(string)x["key"]==key);
            string guid=AssetDatabase.AssetPathToGUID(path);
            if(old!=null&&(string)old["guid"]!=guid)throw new InvalidOperationException("Story resource key already belongs to another asset.");
            if(old==null){rows.Add(new JObject{["key"]=key,["guid"]=guid});File.WriteAllText(settings,rows.ToString()+"\n",new System.Text.UTF8Encoding(false));}
            UnityNativeUiAssetValidator.RebuildResourceReference(key);
        }
    }
}
