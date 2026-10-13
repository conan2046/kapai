using System;
using System.IO;
using ProjectX.UI;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class LibraryPrefabAuthoring
    {
        const string AssetPath="Assets/Prefabs/DongFu/DongFuLibrary.prefab";
        [MenuItem("ProjectX/DongFu/Bind Library Authored Templates")]
        public static void Apply()
        {
            if(EditorApplication.isPlaying)throw new InvalidOperationException("Library authoring requires non-Play Editor.");
            var stage=PrefabStageUtility.GetCurrentPrefabStage();bool reopen=stage!=null&&stage.assetPath==AssetPath;
            if(reopen&&stage.scene.isDirty)throw new InvalidOperationException("Save current Library prefab edits before binding.");
            var backup=Path.Combine(Application.dataPath,"../../.local/dongfu-library-audit/DongFuLibrary.before-binding.prefab");
            if(!File.Exists(backup))File.Copy(AssetPath,backup);
            if(reopen)StageUtility.GoToMainStage();
            var root=PrefabUtility.LoadPrefabContents(AssetPath);
            try
            {
                foreach(var t in root.GetComponentsInChildren<Transform>(true))
                    if(GameObjectUtility.GetMonoBehavioursWithMissingScriptCount(t.gameObject)>0)throw new InvalidOperationException("Library missing script: "+t.name);
                var screen=Get<LibraryScreen>(root);
                var left=root.transform.Find("Sets/Scroll View").GetComponent<ScrollRect>();
                var content=root.transform.Find("Sets/Scroll View/Viewport/Content").GetComponent<RectTransform>();left.content=content;
                var layout=content.GetComponent<VerticalLayoutGroup>();layout.childControlHeight=true;layout.childForceExpandHeight=false;
                Get<ContentSizeFitter>(content.gameObject).verticalFit=ContentSizeFitter.FitMode.PreferredSize;
                var group=content.Find("Set0").gameObject;var groupLayout=Get<VerticalLayoutGroup>(group);
                // A root Image also reports its sprite's natural preferred height.
                // Keep the authored header art on an ignored child so collapsed groups
                // measure only their header, rather than the source sprite's full size.
                var groupImage=group.GetComponent<Image>();
                if(groupImage!=null&&groupImage.enabled)
                {
                    var art=new GameObject("HeaderBackground",typeof(RectTransform),typeof(CanvasRenderer),typeof(Image),typeof(LayoutElement));
                    var rect=art.GetComponent<RectTransform>();rect.SetParent(group.transform,false);rect.SetAsFirstSibling();
                    rect.anchorMin=new Vector2(0,1);rect.anchorMax=new Vector2(1,1);rect.pivot=new Vector2(0.5f,1);
                    rect.anchoredPosition=Vector2.zero;rect.sizeDelta=new Vector2(0,40);
                    EditorUtility.CopySerialized(groupImage,art.GetComponent<Image>());
                    art.GetComponent<LayoutElement>().ignoreLayout=true;groupImage.enabled=false;
                }
                groupLayout.padding=new RectOffset(10,10,2,2);groupLayout.childAlignment=TextAnchor.UpperCenter;
                groupLayout.childControlWidth=true;groupLayout.childControlHeight=true;groupLayout.childForceExpandWidth=true;groupLayout.childForceExpandHeight=false;
                var header=group.transform.Find("Name").GetComponent<Text>();header.raycastTarget=true;
                var headerElement=Get<LayoutElement>(header.gameObject);headerElement.preferredHeight=40;headerElement.preferredWidth=234.76f;
                var headerButton=Get<Button>(header.gameObject);headerButton.targetGraphic=header;
                headerButton.navigation=new Navigation{mode=Navigation.Mode.None};
                var rows=group.transform.Find("VirtualContent");var rowLayout=rows.GetComponent<VerticalLayoutGroup>();
                rowLayout.childControlHeight=true;rowLayout.childForceExpandHeight=false;
                var setRow=rows.Find("VirtualRow_0").GetComponent<RectTransform>();
                var setElement=Get<LayoutElement>(setRow.gameObject);setElement.preferredHeight=50;setElement.preferredWidth=236.6912f;
                var book=root.transform.Find("Details/Book/Book_0").GetComponent<RectTransform>();
                var bg=book.Find("bg").GetComponent<RectTransform>();var bookSize=Get<LayoutElement>(book.gameObject);
                bookSize.preferredWidth=bg.sizeDelta.x;bookSize.preferredHeight=bg.sizeDelta.y;
                var bookLayout=book.parent.GetComponent<HorizontalLayoutGroup>();
                bookLayout.childScaleWidth=true;bookLayout.childScaleHeight=true;bookLayout.childControlWidth=true;bookLayout.childControlHeight=true;
                bookLayout.childForceExpandWidth=false;bookLayout.childForceExpandHeight=false;
                bookLayout.spacing=(((RectTransform)book.parent).rect.width-4*bg.sizeDelta.x*book.localScale.x)/3f;
                book.GetComponent<Button>().targetGraphic=bg.GetComponent<Image>();
                var reward=(root.transform.Find("Details/Reward")??root.transform.Find("Details/RewardViewport/Reward")).GetComponent<RectTransform>();
                var template=reward.Find("Reward0").GetComponent<RectTransform>();template.gameObject.SetActive(false);
                var rewardElement=Get<LayoutElement>(template.gameObject);rewardElement.preferredHeight=template.sizeDelta.y;rewardElement.preferredWidth=template.sizeDelta.x;
                var wrapper=root.transform.Find("Details/RewardViewport") as RectTransform;
                if(wrapper==null)
                {
                    wrapper=new GameObject("RewardViewport",typeof(RectTransform),typeof(CanvasRenderer),typeof(Image),typeof(RectMask2D),typeof(ScrollRect)).GetComponent<RectTransform>();
                    wrapper.SetParent(reward.parent,false);wrapper.anchorMin=reward.anchorMin;wrapper.anchorMax=reward.anchorMax;
                    wrapper.pivot=reward.pivot;wrapper.anchoredPosition=reward.anchoredPosition;wrapper.sizeDelta=reward.sizeDelta;wrapper.localScale=reward.localScale;
                    wrapper.SetSiblingIndex(reward.GetSiblingIndex());reward.SetParent(wrapper,false);
                    reward.anchorMin=new Vector2(0,1);reward.anchorMax=new Vector2(1,1);reward.pivot=new Vector2(0.5f,1);
                    reward.anchoredPosition=Vector2.zero;reward.sizeDelta=Vector2.zero;
                }
                wrapper.GetComponent<Image>().color=Color.clear;wrapper.GetComponent<Image>().raycastTarget=true;
                var rewardLayout=reward.GetComponent<VerticalLayoutGroup>();rewardLayout.childControlHeight=true;rewardLayout.childForceExpandHeight=false;
                Get<ContentSizeFitter>(reward.gameObject).verticalFit=ContentSizeFitter.FitMode.PreferredSize;
                var scroll=wrapper.GetComponent<ScrollRect>();scroll.viewport=wrapper;scroll.content=reward;
                scroll.horizontal=false;scroll.vertical=true;scroll.movementType=ScrollRect.MovementType.Clamped;
                scroll.scrollSensitivity=30;
                left.scrollSensitivity=30;
                var obsolete=root.transform.Find("States");if(obsolete!=null)UnityEngine.Object.DestroyImmediate(obsolete.gameObject);
                var bindings=new SerializedObject(screen);
                Set(bindings,"realmScroll",left);Set(bindings,"realmTemplate",group);Set(bindings,"bookTemplate",book);Set(bindings,"rewardTemplate",template);
                Set(bindings,"rewardScroll",scroll);Set(bindings,"empty",root.transform.Find("Sets/Empty").GetComponent<Text>());
                Set(bindings,"attributes",root.transform.Find("Sets/Attributes").GetComponent<Button>());bindings.ApplyModifiedPropertiesWithoutUndo();
                PrefabUtility.SaveAsPrefabAsset(root,AssetPath,out bool success);if(!success)throw new InvalidOperationException("Library prefab save failed.");
            }
            finally{PrefabUtility.UnloadPrefabContents(root);}
            if(reopen)AssetDatabase.OpenAsset(AssetDatabase.LoadAssetAtPath<GameObject>(AssetPath));
        }
        static T Get<T>(GameObject node)where T:Component=>node.GetComponent<T>()??node.AddComponent<T>();
        static void Set(SerializedObject value,string field,UnityEngine.Object reference)
        {if(reference==null)throw new InvalidOperationException("Library binding missing: "+field);value.FindProperty(field).objectReferenceValue=reference;}
    }
}
