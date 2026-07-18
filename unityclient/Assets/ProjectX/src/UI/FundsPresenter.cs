using System;
using System.Collections.Generic;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class FundsPresenter : IDisposable
    {
        private readonly CocosUiView growthView, activeView;
        private readonly FundsStore store;
        private readonly FundsCatalog catalog;
        private FundKind selectedKind = FundKind.Growth;
        private int selectedPlan;
        private int renderedCount;

        public FundsPresenter(CocosUiView growthView, CocosUiView activeView, FundsStore store, FundsCatalog catalog)
        {
            this.growthView=growthView??throw new ArgumentNullException(nameof(growthView));
            this.activeView=activeView??throw new ArgumentNullException(nameof(activeView));
            this.store=store??throw new ArgumentNullException(nameof(store));
            this.catalog=catalog??throw new ArgumentNullException(nameof(catalog));
            Normalize(growthView.GameObject.transform); Normalize(activeView.GameObject.transform);
            store.Changed += Render; DisableMutations(growthView.GameObject.transform); DisableMutations(activeView.GameObject.transform);
        }

        public bool IsAuthoritativeVisible { get { FundPage page=store.Get(selectedKind); return page.HasAuthoritativeResponse && renderedCount==(page.Plans.Count==0?0:page.Plans[Mathf.Clamp(selectedPlan,0,page.Plans.Count-1)].Tiers.Count); } }
        public void Show(FundKind kind) { selectedKind=kind; selectedPlan=0; growthView.SetVisible(kind==FundKind.Growth); activeView.SetVisible(kind==FundKind.Active); Render(); }

        public void Render()
        {
            FundPage page=store.Get(selectedKind); Transform root=(selectedKind==FundKind.Growth?growthView:activeView).GameObject.transform;
            Transform panel=Find(root,"Layer/ChengZhang","ChengZhang"); if(panel==null) return;
            SetText(Find(panel,"Text_1/Time"), page.EndTime==0?"":$"截止时间 {page.EndTime}");
            Transform content=Find(panel,"Content");
            for(int i=0;i<2;i++) BindPlan(content?.Find($"Content_{i+1}"),page,i);
            RenderTiers(content,page);
        }

        private void BindPlan(Transform panel, FundPage page, int index)
        {
            if(panel==null)return; bool exists=index<page.Plans.Count; panel.gameObject.SetActive(exists); if(!exists)return;
            FundPlan plan=page.Plans[index]; SetText(panel.Find("Text"),$"{plan.Rate}%返利");
            SetText(Find(panel,"Image_1/Base/Text/AtlasLabel_1"),plan.Price.ToString()); SetText(Find(panel,"Image_1/Base/Text/AtlasLabel_2"),plan.Total.ToString());
            Button button=panel.GetComponent<Button>(); if(button!=null){button.onClick.RemoveAllListeners();int captured=index;button.onClick.AddListener(()=>{selectedPlan=captured;Render();});}
        }

        private void RenderTiers(Transform content, FundPage page)
        {
            Transform bg=Find(content,"ListBg/Bg"); Transform list=Find(bg,"ListView_1"); Transform template=Find(bg,"Reward_1");
            if(list==null||template==null){renderedCount=0;return;}
            for(int i=list.childCount-1;i>=0;i--) if(list.GetChild(i).name.StartsWith("FundTier_",StringComparison.Ordinal)) UnityEngine.Object.Destroy(list.GetChild(i).gameObject);
            renderedCount=0; if(page.Plans.Count==0){template.gameObject.SetActive(false);return;}
            FundPlan plan=page.Plans[Mathf.Clamp(selectedPlan,0,page.Plans.Count-1)]; template.gameObject.SetActive(false);
            foreach(FundTier tier in plan.Tiers)
            {
                GameObject row=UnityEngine.Object.Instantiate(template.gameObject,list,false); row.name=$"FundTier_{tier.Condition}_{renderedCount}";row.SetActive(true);
                SetText(row.transform.Find("Text"),catalog.Condition(selectedKind,tier.Condition)); SetText(Find(row.transform,"Btn/Text"),catalog.State(tier.State));
                Transform received=row.transform.Find("ImageReceive");if(received!=null)received.gameObject.SetActive(tier.State==3);
                Button claim=row.transform.Find("Btn")?.GetComponent<Button>();if(claim!=null){claim.onClick.RemoveAllListeners();claim.interactable=false;claim.gameObject.SetActive(tier.State!=3);}
                Transform reward=Find(row.transform,"ListView/ItemBg","ItemBg"); if(reward!=null&&tier.Rewards.Count>0) SetText(Find(reward,"Text","Name"),$"{tier.Rewards[0].ItemId} ×{tier.Rewards[0].Amount}");
                renderedCount++;
            }
        }

        private static void DisableMutations(Transform root){foreach(Button b in root.GetComponentsInChildren<Button>(true))if(b.name=="Btn"){b.onClick.RemoveAllListeners();b.interactable=false;}}
        private static Transform Find(Transform root,params string[] paths){if(root==null)return null;foreach(string p in paths){Transform t=root.Find(p);if(t!=null)return t;}return null;}
        private static void SetText(Transform target,string value){Text text=target?.GetComponent<Text>();if(text!=null)text.text=value;}
        private static void Normalize(Transform root){if(root is RectTransform r){r.anchorMin=Vector2.zero;r.anchorMax=Vector2.one;r.offsetMin=r.offsetMax=Vector2.zero;r.localScale=Vector3.one;r.localRotation=Quaternion.identity;}}
        public void Dispose(){store.Changed-=Render;}
    }
}
