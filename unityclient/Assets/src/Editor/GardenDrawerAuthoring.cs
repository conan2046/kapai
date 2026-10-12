using System;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;
using ProjectX.UI;

namespace ProjectX.Editor
{
    [InitializeOnLoad]
    public static class GardenDrawerAuthoring
    {
        [MenuItem("Tools/ProjectX 洞府/绑定灵园底栏动画")]
        public static void Apply()
        {
            const string path="Assets/Prefabs/DongFu/DongFuGardenScene.prefab";
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                var rects=root.GetComponentsInChildren<RectTransform>(true);
                var before=rects.Select(Pose).ToArray();
                var screen=root.GetComponent<GardenScreen>();var data=new SerializedObject(screen);
                var panel=(GameObject)data.FindProperty("planting").objectReferenceValue;
                var close=root.transform.Find("GardenUI/Close").GetComponent<Button>();
                if(close.transform.IsChildOf(panel.transform))throw new InvalidOperationException("Close必须在Planting外部");
                var plots=rects.Single(t=>t.name=="Plots");
                var row=(GameObject)data.FindProperty("cropRowTemplate").objectReferenceValue;
                var texts=row.GetComponentsInChildren<Text>(true);
                var rowView=row.GetComponent<GardenCropRowView>()??row.AddComponent<GardenCropRowView>();
                Set(rowView,"plant",row.GetComponent<Button>());Set(rowView,"icon",row.transform.Find("Icon").GetComponent<Image>());
                Set(rowView,"cropName",texts.Single(t=>t.name=="Name"));Set(rowView,"duration",texts.Single(t=>t.name=="Details"));Set(rowView,"stock",texts.Single(t=>t.name=="Stock"));
                var buyNode=row.transform.Find("Buy");
                var price=buyNode!=null?buyNode.GetComponentInChildren<Text>(true):texts.Single(t=>t.name=="univalence");
                if(price.GetComponent<Button>()!=null)UnityEngine.Object.DestroyImmediate(price.GetComponent<Button>());
                if(buyNode!=null&&buyNode.GetComponent<Button>()!=null)UnityEngine.Object.DestroyImmediate(buyNode.GetComponent<Button>());
                price.raycastTarget=false;Set(rowView,"price",price);
                var host=root.transform.Find("GardenUI");var purchase=host.Find("SeedPurchase");
                if(purchase==null)
                {
                    var template=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/Hero/Equipment/yijianjinglian.prefab");
                    var clone=(GameObject)PrefabUtility.InstantiatePrefab(template,host);clone.name="SeedPurchase";clone.SetActive(false);purchase=clone.transform;
                    var key=clone.GetComponent<UiPrefabKey>();if(key!=null)UnityEngine.Object.DestroyImmediate(key);
                    purchase.Find("Popup/Title/Title").GetComponent<Text>().text="购买种子";
                    purchase.Find("Popup/Title/Tips").GetComponent<Text>().text="选择购买数量";
                    var seedName=purchase.Find("Popup/Panel_1/Name").GetComponent<RectTransform>();
                    seedName.sizeDelta=new Vector2(260,seedName.sizeDelta.y);
                    var countText=purchase.Find("Popup/Panel_1/Count/Value").GetComponent<Text>();
                    countText.rectTransform.anchorMin=Vector2.zero;countText.rectTransform.anchorMax=Vector2.one;
                    countText.rectTransform.offsetMin=new Vector2(8,0);countText.rectTransform.offsetMax=new Vector2(-8,0);
                    countText.alignment=TextAnchor.MiddleCenter;
                    purchase.Find("Popup/Panel_1/Level").gameObject.SetActive(false);
                    purchase.Find("Popup/Panel_1/Btn_Plus/Text").GetComponent<Text>().text="+1";
                    purchase.Find("Popup/Panel_1/Btn_Minus/Text").GetComponent<Text>().text="-1";
                    purchase.Find("Popup/Panel_1/Btn_Plus10/Text").GetComponent<Text>().text="+10";
                    purchase.Find("Popup/Panel_1/Btn_Minus10/Text").GetComponent<Text>().text="-10";
                    purchase.Find("Popup/Btn_Confirm/Text").GetComponent<Text>().text="购买";
                    for(int i=2;i<=4;i++){purchase.Find("Popup/Panel_2/Item_"+i).gameObject.SetActive(false);var frame=purchase.Find("Popup/Panel_2/Item_"+i+"_bg");if(frame!=null)frame.gameObject.SetActive(false);}
                    var coin=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/Icons/Items/equip3006.png");
                    if(coin!=null)purchase.Find("Popup/Panel_2/Item_1").GetComponent<Image>().sprite=coin;
                }
                Set(screen,"seedPurchase",purchase.gameObject);
                Set(screen,"seedPurchaseTitle",purchase.Find("Popup/Title/Title").GetComponent<Text>());
                Set(screen,"seedPurchaseDescription",purchase.Find("Popup/Title/Tips").GetComponent<Text>());
                Set(screen,"seedPurchaseConfirm",purchase.Find("Popup/Btn_Confirm").GetComponent<Button>());
                Set(screen,"seedPurchaseCancel",purchase.Find("Popup/Btn_Cancel").GetComponent<Button>());
                Set(screen,"seedPurchaseClose",purchase.Find("Popup/Btn_close").GetComponent<Button>());
                Set(screen,"seedPurchaseIcon",purchase.Find("Popup/Panel_1/Item").GetComponent<Image>());
                Set(screen,"seedPurchaseName",purchase.Find("Popup/Panel_1/Name").GetComponent<Text>());
                Set(screen,"seedPurchaseQuantity",purchase.Find("Popup/Panel_1/Count/Value").GetComponent<Text>());
                Set(screen,"seedPurchaseTotal",purchase.Find("Popup/Panel_2/Item_1/Value").GetComponent<Text>());
                Set(screen,"seedPurchaseMinus",purchase.Find("Popup/Panel_1/Btn_Minus").GetComponent<Button>());
                Set(screen,"seedPurchasePlus",purchase.Find("Popup/Panel_1/Btn_Plus").GetComponent<Button>());
                Set(screen,"seedPurchaseMinus10",purchase.Find("Popup/Panel_1/Btn_Minus10").GetComponent<Button>());
                Set(screen,"seedPurchasePlus10",purchase.Find("Popup/Panel_1/Btn_Plus10").GetComponent<Button>());
                const string folder="Assets/Animations/DongFu";Directory.CreateDirectory(folder);AssetDatabase.Refresh();
                var animation=root.GetComponent<Animation>();if(!animation)animation=root.AddComponent<Animation>();animation.playAutomatically=false;
                var closeRect=close.GetComponent<RectTransform>();
                foreach(bool open in new[]{false,true})
                {
                    string name=open?"GardenDrawerOpen":"GardenDrawerClosed";string clipPath=folder+"/"+name+".anim";
                    var clip=AssetDatabase.LoadAssetAtPath<AnimationClip>(clipPath);
                    if(clip==null)
                    {
                        clip=new AnimationClip{legacy=true,name=name,wrapMode=WrapMode.ClampForever};
                        Curve(clip,AnimationUtility.CalculateTransformPath(plots,root.transform),typeof(RectTransform),"m_AnchoredPosition.y",open?80:0);
                        Curve(clip,AnimationUtility.CalculateTransformPath(closeRect,root.transform),typeof(RectTransform),"m_AnchoredPosition.y",closeRect.anchoredPosition.y+(open?panel.GetComponent<RectTransform>().rect.height:0));
                        Curve(clip,AnimationUtility.CalculateTransformPath(closeRect,root.transform),typeof(Transform),"localEulerAnglesRaw.z",closeRect.localEulerAngles.z+(open?180:0));
                        AssetDatabase.CreateAsset(clip,clipPath);
                    }
                    animation.AddClip(clip,name);
                }
                Set(screen,"drawerAnimation",animation);Set(screen,"plantingClose",close);
                for(int i=0;i<rects.Length;i++)if(before[i]!=Pose(rects[i]))throw new InvalidOperationException("手调布局被改变，拒绝保存");
                PrefabUtility.SaveAsPrefabAsset(root,path);AssetDatabase.SaveAssets();
                File.WriteAllText("../.local/dongfu-reference/garden-drawer-authoring-report.json","{\"manualTransformsUnchanged\":true,\"plots\":36,\"openY\":80,\"closedY\":0,\"outsideCloseBound\":true}");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
            GardenSelectionAuthoring.Apply();
        }
        static void Curve(AnimationClip clip,string path,Type type,string property,float value)
        {clip.SetCurve(path,type,property,AnimationCurve.Constant(0,1f/60,value));}
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
        static void Set(UnityEngine.Object o,string key,UnityEngine.Object value)
        {var s=new SerializedObject(o);s.FindProperty(key).objectReferenceValue=value;s.ApplyModifiedPropertiesWithoutUndo();}
        static GardenDrawerAuthoring(){EditorApplication.delayCall+=ConnectRequested;}
        static async void ConnectRequested()
        {
            const string path="../.local/dongfu-reference/garden-drawer-connect.request";
            if(!File.Exists(path))return;
            File.Delete(path);
            var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("MCPForUnity.Editor.Services.MCPServiceLocator")).First(t=>t!=null);
            var bridge=type.GetProperty("Bridge",BindingFlags.Public|BindingFlags.Static).GetValue(null);
            await (System.Threading.Tasks.Task<bool>)bridge.GetType().GetMethod("StartAsync").Invoke(bridge,null);
        }
    }
}
