using System;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class GardenSelectionAuthoring
    {
        [MenuItem("Tools/ProjectX 洞府/选中框移到地块上层")]
        public static void Apply()
        {
            if(EditorApplication.isPlaying)throw new InvalidOperationException("请先退出Play");
            var stage=PrefabStageUtility.GetCurrentPrefabStage();
            if(stage!=null&&stage.scene.isDirty)throw new InvalidOperationException("请先保存预制体");
            const string path="Assets/Prefabs/DongFu/DongFuGardenScene.prefab";
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                var map=root.transform.Find("MapArea");var plots=map.Find("Plots");
                var retained=root.GetComponentsInChildren<RectTransform>(true).Where(r=>
                    !r.GetComponentsInParent<Transform>(true).Any(t=>t.name=="Selection")).ToArray();
                var poses=retained.Select(Pose).ToArray();
                var frame=map.Find("SelectionFrame");
                var old=root.GetComponentsInChildren<GardenPlotView>(true)
                    .SelectMany(p=>p.GetComponentsInChildren<Transform>(true)).Where(t=>t.name=="Selection").ToArray();
                if(frame==null)
                {
                    if(old.Length>0)
                    {
                        var template=old.Single(t=>t.GetComponentInParent<GardenPlotView>().Id==1);
                        var clone=UnityEngine.Object.Instantiate(template.gameObject,template.parent,false);
                        clone.name="SelectionFrame";clone.transform.SetParent(map,true);frame=clone.transform;
                        var rect=(RectTransform)frame;var size=rect.rect.size;
                        rect.anchorMin=rect.anchorMax=new Vector2(.5f,.5f);rect.sizeDelta=size;
                    }
                    else
                    {
                        var node=new GameObject("SelectionFrame",typeof(RectTransform),typeof(Image));
                        node.transform.SetParent(map,false);frame=node.transform;
                        var rect=(RectTransform)frame;rect.sizeDelta=new Vector2(160,160);rect.localScale=plots.localScale;
                        var image=node.GetComponent<Image>();image.type=Image.Type.Sliced;
                        image.sprite=AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/UI/ui_duanzao/ui_juese_icon_xuanzhong.png");
                    }
                }
                foreach(var node in old)UnityEngine.Object.DestroyImmediate(node.gameObject);
                frame.SetAsLastSibling();frame.gameObject.SetActive(false);
                foreach(var graphic in frame.GetComponentsInChildren<Graphic>(true))graphic.raycastTarget=false;
                var data=new SerializedObject(root.GetComponent<GardenScreen>());
                data.FindProperty("selectionFrame").objectReferenceValue=frame.GetComponent<RectTransform>();data.ApplyModifiedPropertiesWithoutUndo();
                for(int i=0;i<retained.Length;i++)if(poses[i]!=Pose(retained[i]))throw new InvalidOperationException("原有布局变化，拒绝保存");
                PrefabUtility.SaveAsPrefabAsset(root,path);AssetDatabase.SaveAssets();
                File.WriteAllText("../.local/dongfu-reference/garden-selection-overlay-authoring.json",JsonConvert.SerializeObject(new{
                    removedPlotMarkers=old.Length,frame="MapArea/SelectionFrame",plotsIndex=plots.GetSiblingIndex(),
                    frameIndex=frame.GetSiblingIndex(),manualTransformsUnchanged=true
                },Formatting.Indented));
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
        }
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
    }
}
