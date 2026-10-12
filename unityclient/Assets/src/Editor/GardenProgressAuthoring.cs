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
    public static class GardenProgressAuthoring
    {
        [MenuItem("Tools/ProjectX 洞府/同步Plot01进度条")]
        public static void Apply()
        {
            if(EditorApplication.isPlaying)throw new InvalidOperationException("请先退出Play");
            var stage=PrefabStageUtility.GetCurrentPrefabStage();
            if(stage!=null&&stage.scene.isDirty)throw new InvalidOperationException("请先保存预制体修改");
            const string path="Assets/Prefabs/DongFu/DongFuGardenScene.prefab";
            var root=PrefabUtility.LoadPrefabContents(path);
            try
            {
                var plots=root.GetComponentsInChildren<GardenPlotView>(true);
                if(plots.Length!=36)throw new InvalidOperationException("地块数量不是36");
                var first=plots.Single(p=>p.Id==1);
                var template=first.GetComponentsInChildren<Scrollbar>(true).Single(p=>p.name=="Scrollbar");
                var parentPath=AnimationUtility.CalculateTransformPath(template.transform.parent,first.transform);
                var retained=root.GetComponentsInChildren<RectTransform>(true).Where(r=>
                    !r.GetComponentsInParent<Transform>(true).Any(t=>t.name=="Progress"||t.name=="Status")).ToArray();
                var poses=retained.Select(Pose).ToArray();
                int added=0,removedProgress=0,removedStatus=0;
                foreach(var plot in plots)
                {
                    foreach(var node in plot.GetComponentsInChildren<Transform>(true).Where(t=>t.name=="Progress"||t.name=="Status").ToArray())
                    {
                        if(node.name=="Progress")removedProgress++;else removedStatus++;
                        UnityEngine.Object.DestroyImmediate(node.gameObject);
                    }
                    var scrollbar=plot.GetComponentsInChildren<Scrollbar>(true).SingleOrDefault(t=>t.name=="Scrollbar");
                    if(scrollbar==null)
                    {
                        var parent=string.IsNullOrEmpty(parentPath)?plot.transform:plot.transform.Find(parentPath);
                        if(parent==null)throw new InvalidOperationException("缺少进度条父节点:"+plot.name);
                        var clone=UnityEngine.Object.Instantiate(template.gameObject,parent,false);
                        clone.name="Scrollbar";scrollbar=clone.GetComponent<Scrollbar>();added++;
                    }
                    scrollbar.interactable=false;scrollbar.transition=Selectable.Transition.None;
                    scrollbar.navigation=new Navigation{mode=Navigation.Mode.None};
                    foreach(var graphic in scrollbar.GetComponentsInChildren<Graphic>(true))graphic.raycastTarget=false;
                    var data=new SerializedObject(plot);
                    data.FindProperty("progress").objectReferenceValue=scrollbar;
                    data.FindProperty("mature").objectReferenceValue=plot.GetComponentsInChildren<Transform>(true).Single(t=>t.name=="Ready").gameObject;
                    data.ApplyModifiedPropertiesWithoutUndo();
                }
                for(int i=0;i<retained.Length;i++)if(poses[i]!=Pose(retained[i]))throw new InvalidOperationException("原布局发生变化，拒绝保存");
                PrefabUtility.SaveAsPrefabAsset(root,path);AssetDatabase.SaveAssets();
                File.WriteAllText("../.local/dongfu-reference/garden-scrollbar-authoring.json",JsonConvert.SerializeObject(new{
                    plots=36,added,removedProgress,removedStatus,manualTransformsUnchanged=true,
                    template=AnimationUtility.CalculateTransformPath(template.transform,root.transform)
                },Formatting.Indented));
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
        }
        static string Pose(RectTransform r)=>r.anchoredPosition+"|"+r.sizeDelta+"|"+r.anchorMin+"|"+r.anchorMax+"|"+r.pivot+"|"+r.localScale+"|"+r.localRotation;
    }
}
