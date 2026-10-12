using System;
using System.IO;
using System.Linq;
using System.Reflection;
using Newtonsoft.Json.Linq;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    // One-shot authoring; no runtime layout code and no changes to existing RectTransforms.
    public static class GardenPrefabSetup
    {
        const string Path="Assets/Prefabs/DongFu/DongFuGardenScene.prefab";
        static Font font;
        static GameObject buttonTemplate;
        static Sprite panelSprite;
        [MenuItem("Tools/ProjectX 洞府/接入灵园状态与弹窗（仅首次）")]
        public static void Build()
        {
            var stage=PrefabStageUtility.GetCurrentPrefabStage();
            if(stage!=null && stage.scene.isDirty)throw new InvalidOperationException("请先保存正在编辑的预制体，再接入灵园。");
            var root=PrefabUtility.LoadPrefabContents(Path);
            try
            {
                if(root.GetComponent<GardenScreen>())throw new InvalidOperationException("灵园已接入，不覆盖现有UI布局。");
                var originals=root.GetComponentsInChildren<RectTransform>(true);
                var poses=originals.Select(Pose).ToArray();
                font=AssetDatabase.LoadAssetAtPath<Font>("Assets/Art/Fonts/xiaokaiSJ2.ttf");
                buttonTemplate=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/DongFu/Components/ActionButton.prefab");
                var panel=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/DongFu/Components/ContentPanel.prefab");
                panelSprite=panel.GetComponentsInChildren<Image>(true).First(i=>i.sprite!=null).sprite;
                var key=root.AddComponent<UiPrefabKey>();Set(key,"key","DongFuGardenScene");root.AddComponent<PrefabAuthoredLayout>();
                var screen=root.AddComponent<GardenScreen>();
                var plots=root.GetComponentsInChildren<RectTransform>(true).Where(t=>t.name.StartsWith("Plot_")).OrderBy(t=>t.name).ToArray();
                if(plots.Length!=36)throw new InvalidOperationException("必须存在36个手调地块。");
                var views=new GardenPlotView[36];
                for(int i=0;i<plots.Length;i++)
                {
                    var p=plots[i];int id=int.Parse(p.name.Substring(5));if(id!=i+1)throw new InvalidOperationException("地块ID必须连续1..36。");
                    var image=p.GetComponent<Image>();image.raycastTarget=true;
                    var b=p.gameObject.AddComponent<Button>();b.targetGraphic=image;b.transition=Selectable.Transition.ColorTint;
                    var view=p.gameObject.AddComponent<GardenPlotView>();views[i]=view;Set(view,"plotId",id);Set(view,"button",b);
                    GameObject lockState=Node("Locked",p,0,0,160,160);var shade=lockState.AddComponent<Image>();shade.color=new Color(0,0,0,.45f);shade.raycastTarget=false;
                    Set(view,"locked",lockState);Set(view,"lockLabel",Label(lockState.transform,"Realm","境界解锁",0,0,150,56,18));
                    var crops=new Image[3];for(int n=0;n<3;n++){var g=Node(new[]{"Initial","Middle","Mature"}[n],p,0,15,72,80);crops[n]=g.AddComponent<Image>();crops[n].raycastTarget=false;crops[n].preserveAspect=true;g.SetActive(false);}Array(view,"stages",crops);
                    var water=Label(p,"NeedsWater","缺水",-43,55,56,26,16);water.color=new Color(.35f,.8f,1);Set(view,"water",water.gameObject);water.gameObject.SetActive(false);
                    var bugs=Label(p,"HasBugs","虫害",43,55,56,26,16);bugs.color=new Color(1,.65f,.35f);Set(view,"bugs",bugs.gameObject);bugs.gameObject.SetActive(false);
                    var mature=Label(p,"Ready","点击收获",0,55,130,26,16);mature.color=new Color(1,.9f,.3f);Set(view,"mature",mature.gameObject);mature.gameObject.SetActive(false);
                    var bar=Node("Scrollbar",p,0,-30,110,8);var track=bar.AddComponent<Image>();track.color=new Color(0,0,0,.5f);track.raycastTarget=false;
                    var fill=Node("Handle",bar.transform,0,0,110,8).AddComponent<Image>();fill.sprite=image.sprite;fill.color=new Color(.4f,.9f,.35f);fill.raycastTarget=false;
                    fill.rectTransform.anchorMin=Vector2.zero;fill.rectTransform.anchorMax=Vector2.one;fill.rectTransform.offsetMin=Vector2.zero;fill.rectTransform.offsetMax=Vector2.zero;
                    var scrollbar=bar.AddComponent<Scrollbar>();scrollbar.handleRect=fill.rectTransform;scrollbar.targetGraphic=fill;scrollbar.direction=Scrollbar.Direction.LeftToRight;scrollbar.interactable=false;scrollbar.transition=Selectable.Transition.None;scrollbar.navigation=new Navigation{mode=Navigation.Mode.None};Set(view,"progress",scrollbar);bar.SetActive(false);
                    var overlay=Node("StateOverlay",p,0,0,160,160).transform;overlay.rotation=root.transform.rotation;overlay.localScale=new Vector3(Mathf.Sign(p.lossyScale.x),Mathf.Sign(p.lossyScale.y),1);
                    foreach(string state in new[]{"Locked","Initial","Middle","Mature","NeedsWater","HasBugs","Ready","Scrollbar"})p.Find(state).SetParent(overlay,false);
                }
                Array(screen,"plots",views);
                var ui=Node("GardenUI",root.transform,0,0,1334,750);
                Set(screen,"notice",Label(ui.transform,"Notice","",0,-333,950,42,22));
                var loading=Label(ui.transform,"Loading","正在同步灵园…",0,320,360,45,22);Set(screen,"loading",loading.gameObject);
                var blocker=Node("ModalBlocker",ui.transform,0,0,1334,750);blocker.AddComponent<Image>().color=new Color(0,0,0,.45f);blocker.SetActive(false);Set(screen,"modalBlocker",blocker);
                var planting=Dialog(ui.transform,"Planting","选择种植物",660,440);Set(screen,"planting",planting);Set(screen,"plantingClose",Button(planting.transform,"Close","关闭",255,167,105,45));
                var scroll=Node("CropScroll",planting.transform,0,-10,590,290);var scrollRect=scroll.AddComponent<ScrollRect>();scrollRect.horizontal=false;scrollRect.vertical=true;
                var viewport=Node("Viewport",scroll.transform,0,0,590,290);viewport.AddComponent<RectMask2D>();var viewportImage=viewport.AddComponent<Image>();viewportImage.color=new Color(1,1,1,.01f);viewportImage.raycastTarget=true;scrollRect.viewport=viewport.GetComponent<RectTransform>();
                var rows=Node("Rows",viewport.transform,0,0,570,120);var rowsRect=rows.GetComponent<RectTransform>();rowsRect.anchorMin=new Vector2(.5f,1);rowsRect.anchorMax=new Vector2(.5f,1);rowsRect.pivot=new Vector2(.5f,1);
                var layout=rows.AddComponent<VerticalLayoutGroup>();layout.childControlWidth=false;layout.childControlHeight=false;layout.childForceExpandHeight=false;layout.childForceExpandWidth=false;layout.spacing=10;
                var fitter=rows.AddComponent<ContentSizeFitter>();fitter.verticalFit=ContentSizeFitter.FitMode.PreferredSize;scrollRect.content=rowsRect;Set(screen,"cropRows",rows.transform);
                var row=Node("CropRowTemplate",rows.transform,0,0,570,112);row.AddComponent<LayoutElement>().preferredHeight=112;var rowImage=row.AddComponent<Image>();rowImage.sprite=panelSprite;rowImage.type=Image.Type.Sliced;var choose=row.AddComponent<Button>();choose.targetGraphic=rowImage;
                var icon=Node("Icon",row.transform,-234,0,64,80).AddComponent<Image>();icon.preserveAspect=true;icon.raycastTarget=false;
                Label(row.transform,"Name","灵植名称",-90,28,195,32,22);Label(row.transform,"Details","成长时长",-90,-9,195,30,18);Label(row.transform,"Stock","种子×0",-90,-39,195,25,18);Button(row.transform,"Buy","购种",163,0,190,60);
                Set(screen,"cropRowTemplate",row);row.SetActive(false);
                var actions=Dialog(ui.transform,"Actions","灵植操作",660,350);Set(screen,"actions",actions);Set(screen,"actionsClose",Button(actions.transform,"Close","关闭",255,125,105,45));
                Set(screen,"actionTitle",Label(actions.transform,"CropName","灵植",0,77,500,38,26));Set(screen,"actionStatus",Label(actions.transform,"GrowthStatus","成长状态",0,32,540,35,20));
                Set(screen,"water",Button(actions.transform,"Water","浇水",-215,-53,125,65));Set(screen,"bugs",Button(actions.transform,"Bugs","除虫",-72,-53,125,65));Set(screen,"remove",Button(actions.transform,"Remove","铲除",72,-53,125,65));Set(screen,"harvest",Button(actions.transform,"Harvest","收获",215,-53,125,65));
                var confirmation=Dialog(ui.transform,"RemoveConfirm","确认铲除",580,280);Set(screen,"confirmation",confirmation);Label(confirmation.transform,"Warning","铲除后不返还种子，本次作物将无法收获。",0,12,500,74,22);Set(screen,"confirm",Button(confirmation.transform,"Confirm","铲除",135,-77,185,55));Set(screen,"cancel",Button(confirmation.transform,"Cancel","取消",-135,-77,185,55));
                for(int i=0;i<originals.Length;i++)if(Pose(originals[i])!=poses[i])throw new InvalidOperationException("手调布局被改动，拒绝保存。");
                GameObject prefab=PrefabUtility.SaveAsPrefabAsset(root,Path);Register(prefab);
                File.WriteAllText(System.IO.Path.GetFullPath("../.local/dongfu-reference/garden-prefab-report.json"),"{\"plots\":36,\"manualTransformsUnchanged\":true,\"dialogCount\":3}");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
            FixMainEntry();AssetDatabase.SaveAssets();DongFuSharedFrameAuthoring.Apply();GardenDrawerAuthoring.Apply();
            Debug.Log("GARDEN_PREFAB_READY: 36 authored plots preserved; 3 prefab dialogs registered.");
        }
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
        static GameObject Node(string name,Transform parent,float x,float y,float w,float h){var g=new GameObject(name,typeof(RectTransform));g.layer=5;var r=g.GetComponent<RectTransform>();r.SetParent(parent,false);r.anchorMin=r.anchorMax=r.pivot=new Vector2(.5f,.5f);r.anchoredPosition=new Vector2(x,y);r.sizeDelta=new Vector2(w,h);return g;}
        static Text Label(Transform parent,string name,string text,float x,float y,float w,float h,int size){var t=Node(name,parent,x,y,w,h).AddComponent<Text>();t.font=font;t.text=text;t.fontSize=size;t.alignment=TextAnchor.MiddleCenter;t.color=Color.white;t.raycastTarget=false;t.resizeTextForBestFit=false;return t;}
        static Button Button(Transform parent,string name,string text,float x,float y,float w,float h){var g=(GameObject)PrefabUtility.InstantiatePrefab(buttonTemplate,parent);g.name=name;var r=g.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=r.pivot=new Vector2(.5f,.5f);r.localScale=Vector3.one;r.anchoredPosition=new Vector2(x,y);r.sizeDelta=new Vector2(w,h);var b=g.GetComponent<Button>();b.transition=Selectable.Transition.ColorTint;b.onClick.RemoveAllListeners();var t=g.GetComponentInChildren<Text>(true);if(!t)t=Label(g.transform,"Label",text,0,0,w-12,h-8,20);t.text=text;return b;}
        static GameObject Dialog(Transform parent,string name,string title,float w,float h){var g=Node(name,parent,0,0,w,h);g.AddComponent<Image>().color=new Color(.38f,.3f,.22f,1);var frame=Node("Frame",g.transform,0,0,w,h).AddComponent<Image>();frame.sprite=panelSprite;frame.type=Image.Type.Sliced;frame.raycastTarget=false;Label(g.transform,"Title",title,0,h/2-43,w-190,44,28);g.SetActive(false);return g;}
        static void Set(UnityEngine.Object obj,string key,UnityEngine.Object value){var s=new SerializedObject(obj);s.FindProperty(key).objectReferenceValue=value;s.ApplyModifiedPropertiesWithoutUndo();}
        static void Set(UnityEngine.Object obj,string key,string value){var s=new SerializedObject(obj);s.FindProperty(key).stringValue=value;s.ApplyModifiedPropertiesWithoutUndo();}
        static void Set(UnityEngine.Object obj,string key,int value){var s=new SerializedObject(obj);s.FindProperty(key).intValue=value;s.ApplyModifiedPropertiesWithoutUndo();}
        static void Array(UnityEngine.Object obj,string key,UnityEngine.Object[] values){var s=new SerializedObject(obj);var p=s.FindProperty(key);p.arraySize=values.Length;for(int i=0;i<values.Length;i++)p.GetArrayElementAtIndex(i).objectReferenceValue=values[i];s.ApplyModifiedPropertiesWithoutUndo();}
        static void Register(GameObject prefab)
        {
            const string referencePath="Assets/Prefabs/Catalog/DongFuGardenScene.asset";
            var reference=ScriptableObject.CreateInstance<UiPrefabReference>();reference.SetPrefab(prefab);AssetDatabase.CreateAsset(reference,referencePath);
            var catalog=AssetDatabase.LoadAssetAtPath<UiPrefabCatalog>("Assets/Prefabs/Catalog/Catalog.asset");if(!catalog.Entries.Any(e=>e.Key=="DongFuGardenScene")){catalog.Replace(catalog.Entries.Concat(new[]{new UiPrefabCatalogEntry("DongFuGardenScene","Unity/DongFu/DongFuGardenScene",null,false)}).ToArray());EditorUtility.SetDirty(catalog);}
            var refs=JArray.Parse(File.ReadAllText("ProjectSettings/ProjectXAssetReferences.json"));
            refs.Add(new JObject{["key"]="UiPrefabs/DongFuGardenScene",["guid"]=AssetDatabase.AssetPathToGUID(referencePath)});
            File.WriteAllText("ProjectSettings/ProjectXAssetReferences.json",refs.ToString()+"\n");
            UnityNativeUiAssetValidator.RebuildResourceReference("UiPrefabs/DongFuGardenScene");GardenResourceReferences.Sync();
        }
        static void FixMainEntry()
        {
            const string path="Assets/Prefabs/Main/UImainLayer_new.prefab";var root=PrefabUtility.LoadPrefabContents(path);
            try{var rects=root.GetComponentsInChildren<RectTransform>(true);var poses=rects.Select(Pose).ToArray();var b=root.GetComponentsInChildren<Button>(true).Single(x=>x.name=="btn_donfu");var image=b.GetComponent<Image>();if(!image){image=b.gameObject.AddComponent<Image>();image.color=Color.clear;}image.raycastTarget=true;b.targetGraphic=image;for(int i=0;i<rects.Length;i++)if(Pose(rects[i])!=poses[i])throw new InvalidOperationException("主界面布局被改动");PrefabUtility.SaveAsPrefabAsset(root,path);}finally{PrefabUtility.UnloadPrefabContents(root);}
        }
    }
    public sealed class GardenResourceReferences : AssetPostprocessor
    {
        static bool running;
        static void OnPostprocessAllAssets(string[] imported,string[] deleted,string[] moved,string[] oldPaths)
        {
            if(!running && imported.Contains("Assets/Resources/ProjectXData/Configs/dongfu_crop.json"))EditorApplication.delayCall+=Sync;
        }
        [MenuItem("Tools/ProjectX 洞府/同步灵植表资源引用")]
        public static void Sync()
        {
            if(running)return;running=true;
            try
            {
                var crops=JArray.Parse(File.ReadAllText("Assets/Resources/ProjectXData/Configs/dongfu_crop.json"));
                var keys=crops.OfType<JObject>().Where(c=>(int)c["enabled"]==1).SelectMany(c=>new[]{(string)c["icon_key"],(string)c["initial_resource_key"],(string)c["middle_resource_key"],(string)c["mature_resource_key"]}).Distinct().ToArray();
                var refs=JArray.Parse(File.ReadAllText("ProjectSettings/ProjectXAssetReferences.json"));bool changed=false;
                foreach(string key in keys)
                {
                    if(refs.OfType<JObject>().Any(e=>(string)e["key"]==key))continue;
                    string asset=new[]{".png",".jpg",".jpeg"}.Select(extension=>"Assets/"+key+extension).FirstOrDefault(File.Exists);
                    if(asset==null||AssetDatabase.LoadAssetAtPath<Sprite>(asset)==null)throw new InvalidOperationException("灵植资源未正确导入为Sprite："+key);
                    refs.Add(new JObject{["key"]=key,["guid"]=AssetDatabase.AssetPathToGUID(asset)});changed=true;
                }
                if(changed)File.WriteAllText("ProjectSettings/ProjectXAssetReferences.json",refs.ToString()+"\n");
                foreach(string key in keys)UnityNativeUiAssetValidator.RebuildResourceReference(key);
            }
            finally{running=false;}
        }
    }
    [InitializeOnLoad]
    internal static class GardenAuthoringRequest
    {
        static GardenAuthoringRequest(){EditorApplication.delayCall+=Run;}
        static async void Run()
        {
            string request=System.IO.Path.GetFullPath("../.local/dongfu-reference/garden-authoring.request");
            if(!File.Exists(request))return;
            if(EditorApplication.isPlayingOrWillChangePlaymode)return;
            File.Delete(request);
            try{GardenPrefabSetup.Build();var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("MCPForUnity.Editor.Services.MCPServiceLocator")).FirstOrDefault(t=>t!=null);if(type!=null){var bridge=type.GetProperty("Bridge",BindingFlags.Public|BindingFlags.Static).GetValue(null);await (System.Threading.Tasks.Task<bool>)bridge.GetType().GetMethod("StartAsync").Invoke(bridge,null);}}
            catch(Exception error){Debug.LogException(error);File.WriteAllText(System.IO.Path.GetFullPath("../.local/dongfu-reference/garden-authoring-error.txt"),error.ToString());}
        }
    }
}
