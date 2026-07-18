using System;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class SevenDayPresenter : IDisposable
    {
        private readonly CocosUiView view;
        private readonly SevenDayStore store;
        private readonly Text status;
        private readonly Text progress;
        private readonly Transform list;
        private readonly GameObject template;

        public SevenDayPresenter(CocosUiView view, SevenDayStore store, Action close)
        {
            this.view=view??throw new ArgumentNullException(nameof(view));this.store=store??throw new ArgumentNullException(nameof(store));
            Transform root=view.GameObject.transform;Normalize(root);SetVisible(root.Find("Panel"),true);ShowFinalLayout(root);
            status=RequireText(root,"Panel/Renwu/Tips");progress=RequireText(root,"Panel/Reward/LoadingBg/Num");
            list=root.Find("Panel/Renwu/bg/Image2/ListView")??throw new InvalidOperationException("SevenDay imported ListView was not found.");
            template=root.Find("Panel/Renwu/Item")?.gameObject??throw new InvalidOperationException("SevenDay imported item template was not found.");
            template.SetActive(false);BindClose(root,close);DisableActions(root);SelectFirstDay(root);store.Changed+=Render;Render();
        }

        public bool IsAuthoritativeVisible=>store.HasAuthoritativeResponse&&status!=null&&progress!=null;
        public void Dispose()=>store.Changed-=Render;

        private void Render()
        {
            for(int i=list.childCount-1;i>=0;i--)if(list.GetChild(i).name.StartsWith("SevenDayRuntimeItem",StringComparison.Ordinal))UnityEngine.Object.Destroy(list.GetChild(i).gameObject);
            if(!store.HasAuthoritativeResponse){status.text="正在同步七日目标";progress.text="--";return;}
            int finished=0;foreach(SevenDayTaskRecord task in store.Tasks)if(task.State>0)finished++;
            status.text=$"七日目标：已同步 {store.Tasks.Count} 项";progress.text=$"{finished}/{store.Tasks.Count}";
            Image bar=view.GameObject.transform.Find("Panel/Reward/LoadingBg/LoadingBar")?.GetComponent<Image>();if(bar!=null)bar.fillAmount=store.Tasks.Count==0?0f:(float)finished/store.Tasks.Count;
            int shown=Math.Min(store.Tasks.Count,5);
            for(int i=0;i<shown;i++)CreateRow(store.Tasks[i],i);
            if(shown==0)status.text="七日目标：当前暂无任务数据";
        }

        private void CreateRow(SevenDayTaskRecord task,int index)
        {
            GameObject row=UnityEngine.Object.Instantiate(template,list,false);row.name=$"SevenDayRuntimeItem_{index}";row.SetActive(true);
            RectTransform rect=(RectTransform)row.transform;rect.anchorMin=new Vector2(0,1);rect.anchorMax=new Vector2(1,1);rect.pivot=new Vector2(.5f,1);rect.anchoredPosition=new Vector2(0,-index*152f);rect.sizeDelta=new Vector2(0,150);
            Transform root=row.transform;SetVisible(root.Find("Panel_1"),false);SetVisible(root.Find("Panel_2"),true);SetVisible(root.Find("Panel_2/Panel_weikaiqi"),false);
            SetText(root,"Panel_2/TitleBg/Text",$"七日目标 #{task.Id}");SetText(root,"Panel_2/Times",$"进度：{task.Progress}");
            SetVisible(root.Find("Panel_2/Get"),task.State==2);Button go=root.Find("Panel_2/Btn")?.GetComponent<Button>();Button claim=root.Find("Panel_2/Btn_0")?.GetComponent<Button>();Disable(go);Disable(claim);
            SetText(root,"Panel_2/Btn/Text",task.State==0?"前往":"已完成");SetText(root,"Panel_2/Btn_0/Text",task.State==1?"可领取":task.State==2?"已领取":"未完成");
        }

        private static void SelectFirstDay(Transform root)
        {
            for(int i=1;i<=7;i++){Transform day=root.Find($"Panel/Renwu/bg/DaysList/Btn_{i}");SetVisible(day?.Find("Choose"),i==1);SetVisible(day?.Find("Lock"),i>1);Disable(day?.GetComponent<Button>());}
            for(int i=1;i<=4;i++)Disable(root.Find($"Panel/Renwu/bg/Image2/CheckList/Type{i}")?.GetComponent<Button>());
        }
        private static void ShowFinalLayout(Transform root)
        {
            Transform reward=root.Find("Panel/Reward");Transform tasks=root.Find("Panel/Renwu");SetVisible(reward,true);SetVisible(tasks,true);
            if(reward is RectTransform left)left.anchoredPosition=Vector2.zero;
            if(tasks is RectTransform right)right.anchoredPosition=new Vector2(1334,0);
            SetOpaque(reward);SetOpaque(tasks);
        }
        private static void SetOpaque(Transform target){if(target==null)return;CanvasGroup group=target.GetComponent<CanvasGroup>();if(group==null)group=target.gameObject.AddComponent<CanvasGroup>();group.alpha=1;group.interactable=true;group.blocksRaycasts=true;}
        private static void BindClose(Transform root,Action close){Button b=root.Find("Panel/Title/CloseBtn")?.GetComponent<Button>();if(b==null)return;b.onClick.RemoveAllListeners();b.onClick.AddListener(()=>close?.Invoke());}
        private static void DisableActions(Transform root){foreach(string p in new[]{"Panel/GoldCheck/GoldIcon1/AddBtn","Panel/GoldCheck/GoldIcon3/AddBtn","Panel/GoldCheck/GoldIcon4/AddBtn"})Disable(root.Find(p)?.GetComponent<Button>());}
        private static void Disable(Button b){if(b==null)return;b.onClick.RemoveAllListeners();b.interactable=false;}
        private static Text RequireText(Transform root,string path)=>root.Find(path)?.GetComponent<Text>()??throw new InvalidOperationException($"SevenDay imported text was not found: {path}");
        private static void SetText(Transform root,string path,string value){Text t=root.Find(path)?.GetComponent<Text>();if(t!=null)t.text=value;}
        private static void SetVisible(Transform target,bool visible){if(target!=null)target.gameObject.SetActive(visible);}
        private static void Normalize(Transform root){if(!(root is RectTransform r))return;r.anchorMin=Vector2.zero;r.anchorMax=Vector2.one;r.pivot=new Vector2(.5f,.5f);r.offsetMin=r.offsetMax=Vector2.zero;r.anchoredPosition=Vector2.zero;r.localScale=Vector3.one;r.localRotation=Quaternion.identity;}
    }
}
