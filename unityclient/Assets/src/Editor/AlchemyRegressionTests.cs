using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ProjectX.Editor
{
    public static class AlchemyRegressionTests
    {
        public static string Configuration()
        {
            var c=new AlchemyCatalog();Require(c.Recipes.Count==495,"495 formal recipes");Require(c.Effects.Count==495,"495 formal effects");
            foreach(var r in c.Recipes.Values){Require(c.Items.ContainsKey(r.LearnItem)&&c.Items.ContainsKey(r.Output),"item references");Require(r.Costs.All(x=>c.Items.ContainsKey(x[0])),"material references");Require(c.Realms.Any(x=>x.Id==r.Realm&&r.Level>=x.First&&r.Level<=x.Last),"jingjie usage ID");}
            foreach(var e in c.Effects.Values)Require(e.Positions.Contains(0)?e.Attributes.All(x=>x[0]==34||x[0]==35):e.Positions.All(x=>x>=1&&x<=5)&&e.Attributes.All(x=>x[0]>=1&&x[0]<=33),"combat/production scope");
            foreach(var item in c.Items.Values)Require(item.MaxStack>=1&&item.MaxStack<=65000,"formal per-item stack limit");
            Require(c.Items[10001].MaxStack==99&&c.Items[11803].MaxStack==999,"legacy pill stack limits");
            return "PASS: 495 recipes/effects, item/material references, realm IDs, production attribute scope";
        }
        public static string Click(Transform target)
        {
            if(!Application.isPlaying||target==null||!target.gameObject.activeInHierarchy)throw new InvalidOperationException("Target is not an active Play control.");
            var selectable=target.GetComponent<Selectable>();if(selectable!=null&&!selectable.IsInteractable())throw new InvalidOperationException("Target is disabled: "+target.name);
            var rect=target as RectTransform;var canvas=target.GetComponentInParent<Canvas>();if(rect==null||canvas==null)throw new InvalidOperationException("Target has no UI Rect/Canvas.");
            Camera camera=canvas.renderMode==RenderMode.ScreenSpaceOverlay?null:canvas.worldCamera;
            var p=RectTransformUtility.WorldToScreenPoint(camera,rect.TransformPoint(rect.rect.center));
            var data=new PointerEventData(EventSystem.current){position=p,button=PointerEventData.InputButton.Left};
            var hits=new List<RaycastResult>();EventSystem.current.RaycastAll(data,hits);
            if(hits.Count==0||!(hits[0].gameObject.transform==target||hits[0].gameObject.transform.IsChildOf(target)))throw new InvalidOperationException("Raycast blocked: "+target.name+" by "+(hits.Count==0?"none":hits[0].gameObject.name));
            var hit=hits[0].gameObject;ExecuteEvents.ExecuteHierarchy(hit,data,ExecuteEvents.pointerDownHandler);ExecuteEvents.ExecuteHierarchy(hit,data,ExecuteEvents.pointerUpHandler);ExecuteEvents.ExecuteHierarchy(hit,data,ExecuteEvents.pointerClickHandler);
            return "Raycast click "+target.name+" -> "+hit.name+" @ "+p;
        }
        public static string BagStacks()
        {
            var store=new BagStore();store.Replace(new[]{
                new BagItemRecord(1,10001,99,"pill","",50001,2,2,0,1,11,maxStack:99),
                new BagItemRecord(2,10001,2,"pill","",50001,2,2,0,1,11,maxStack:99),
                new BagItemRecord(3,11803,999,"pill","",51803,2,2,0,1,11,maxStack:999),
                new BagItemRecord(4,11803,2,"pill","",51803,2,2,0,1,11,maxStack:999)});
            Require(store.Items.Count==4,"physical stack count");
            Require(store.Items.All(x=>x.Quantity<=x.MaxStack),"per-slot display cap");
            Require(store.Items.Select(x=>x.Slot).Distinct().Count()==4,"unique source slots for selection/use");
            Require(store.GetTotalQuantityByItemId(10001)==101&&store.GetTotalQuantityByItemId(11803)==1001,"business total counts remain complete");
            Require(store.GetItemsByType(11).Count==4,"filtered display retains stacks");
            return "PASS: 99+2 and 999+2 display separately, preserve source slots and total counts";
        }
        public static string AlchemyQuantityLimits()
        {
            var recipe=new AlchemyCatalog().Recipes[1];var state=new AlchemyEnvelope();
            Require(ProjectX.UI.AlchemyScreen.GetMaximumBatches(null,recipe)==0,"no snapshot cannot craft");
            Require(ProjectX.UI.AlchemyScreen.GetMaximumBatches(state,recipe)==0,"missing materials cannot craft one batch");
            state.Owned=recipe.Costs.Select(x=>new[]{x[0],x[1]*3}).ToArray();
            Require(ProjectX.UI.AlchemyScreen.GetMaximumBatches(state,recipe)==3,"all ingredients cover three batches");
            state.Owned[0][1]=recipe.Costs[0][1]-1;
            Require(ProjectX.UI.AlchemyScreen.GetMaximumBatches(state,recipe)==0,"one insufficient ingredient blocks crafting");
            state.Owned=recipe.Costs.Select(x=>new[]{x[0],x[1]*(recipe.Limit+1)}).ToArray();
            Require(ProjectX.UI.AlchemyScreen.GetMaximumBatches(state,recipe)==recipe.Limit,"formal batch cap remains enforced");
            return "PASS: empty snapshot, missing/bottleneck materials, three batches and formal batch cap";
        }
        public static string SharedGroupedList()
        {
            foreach(string name in new[]{"DongFuAlchemy","DongFuLibrary","DongFuForge"})
            {
                var prefab=UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/DongFu/"+name+".prefab");
                var root=UnityEngine.Object.Instantiate(prefab);root.hideFlags=HideFlags.HideAndDontSave;root.SetActive(false);
                try
                {
                    var list=root.GetComponent<ProjectX.UI.GroupedTemplateList>();Require(list!=null,"shared component on "+name);
                    var template=root.transform.Find("Sets/Scroll View/Viewport/Content/Set0");
                    var a=UnityEngine.Object.Instantiate(template.gameObject,template.parent,false);
                    var b=UnityEngine.Object.Instantiate(template.gameObject,template.parent,false);
                    var rect=a.transform as RectTransform;var position=rect.anchoredPosition;var size=rect.sizeDelta;var scale=rect.localScale;
                    var original=a.transform.Find("HeaderBackground").GetComponent<Image>().sprite;
                    list.RegisterGroup(1,a,null);list.RegisterGroup(2,b,null);
                    Require(list.InitializeSelection(1)&&a.transform.Find("VirtualContent").gameObject.activeSelf,"initial expansion");
                    Require(a.transform.Find("HeaderBackground").GetComponent<Image>().sprite.name=="ui_btn_fuwuqi_xuanzhong","selected resource");
                    list.ToggleGroup(1);
                    Require(list.HasSelection&&list.SelectedGroup==0&&!a.transform.Find("VirtualContent").gameObject.activeSelf,"explicit collapse remains initialized");
                    Require(!list.InitializeSelection(2)&&list.SelectedGroup==0,"snapshot cannot reopen collapsed group");
                    Require(a.transform.Find("HeaderBackground").GetComponent<Image>().sprite==original,"authored default restored");
                    list.ToggleGroup(2);list.ToggleGroup(1);
                    Require(a.transform.Find("VirtualContent").gameObject.activeSelf&&!b.transform.Find("VirtualContent").gameObject.activeSelf,"one expanded group");
                    list.SetInteractable(false);Require(!a.transform.Find("Name").GetComponent<Button>().IsInteractable(),"pending input guard");
                    list.ResetSelection();Require(!list.HasSelection&&list.InitializeSelection(2),"new entry can initialize again");
                    Require(rect.anchoredPosition==position&&rect.sizeDelta==size&&rect.localScale==scale,"authored geometry retained");
                }
                finally{UnityEngine.Object.DestroyImmediate(root);}
            }
            return "PASS: all three prefabs share expansion, collapse, sprites, snapshot persistence, pending guard and authored geometry";
        }
        static void Require(bool value,string message){if(!value)throw new InvalidOperationException(message);}
    }
}
