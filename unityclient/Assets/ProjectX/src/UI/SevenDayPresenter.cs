using System;
using System.Linq;
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
        private readonly Action<ushort> claim;
        private readonly CurrencyStore currencies;
        private readonly GameplayShopStore shops;
        private readonly Action<int> dayChanged;
        private readonly Action<int> categoryChanged;
        private readonly Action<ushort> go;
        private readonly Action<ushort> itemDetail;
        private readonly Action staminaAdd;
        private readonly Action goldAdd;
        private readonly Action<byte,ushort> discountBuy;
        private readonly Button[] dayButtons=new Button[7];
        private readonly Button[] categoryButtons=new Button[4];
        private Button staminaButton,goldButton,premiumButton;
        private Button firstItemDetail;
        private int selectedDay=1,selectedCategory=1;

        public SevenDayPresenter(CocosUiView view, SevenDayStore store, CurrencyStore currencies, GameplayShopStore shops,
            Action<ushort> claim, Action<ushort> go, Action<int> dayChanged, Action<int> categoryChanged,
            Action<ushort> itemDetail, Action<byte,ushort> discountBuy, Action staminaAdd, Action goldAdd, Action close)
        {
            this.view=view??throw new ArgumentNullException(nameof(view));this.store=store??throw new ArgumentNullException(nameof(store));this.currencies=currencies??throw new ArgumentNullException(nameof(currencies));this.shops=shops??throw new ArgumentNullException(nameof(shops));this.claim=claim??throw new ArgumentNullException(nameof(claim));this.go=go??throw new ArgumentNullException(nameof(go));this.itemDetail=itemDetail??throw new ArgumentNullException(nameof(itemDetail));this.dayChanged=dayChanged??throw new ArgumentNullException(nameof(dayChanged));this.categoryChanged=categoryChanged??throw new ArgumentNullException(nameof(categoryChanged));this.discountBuy=discountBuy??throw new ArgumentNullException(nameof(discountBuy));this.staminaAdd=staminaAdd??throw new ArgumentNullException(nameof(staminaAdd));this.goldAdd=goldAdd??throw new ArgumentNullException(nameof(goldAdd));
            Transform root=view.GameObject.transform;Normalize(root);SetVisible(root.Find("Panel"),true);ShowFinalLayout(root);
            status=RequireText(root,"Panel/Renwu/Tips");progress=RequireText(root,"Panel/Reward/LoadingBg/Num");
            list=root.Find("Panel/Renwu/bg/Image2/ListView")??throw new InvalidOperationException("SevenDay imported ListView was not found.");
            template=root.Find("Panel/Renwu/Item")?.gameObject??throw new InvalidOperationException("SevenDay imported item template was not found.");
            template.SetActive(false);BindClose(root,close);BindSelectors(root);BindResources(root);store.Changed+=Render;shops.Changed+=Render;currencies.Changed+=RenderCurrencies;RenderCurrencies();Render();
        }

        public bool IsAuthoritativeVisible=>store.HasAuthoritativeResponse&&status!=null&&progress!=null;
        public int BoundDayCount=>Array.FindAll(dayButtons,value=>value!=null).Length;
        public int BoundCategoryCount=>Array.FindAll(categoryButtons,value=>value!=null).Length;
        public bool PremiumAddDisabled=>premiumButton==null||!premiumButton.interactable;
        public bool InvokeDay(int day){if(day<1||day>7||dayButtons[day-1]==null)return false;dayButtons[day-1].onClick.Invoke();return selectedDay==day;}
        public bool InvokeCategory(int category){if(category<1||category>4||categoryButtons[category-1]==null)return false;categoryButtons[category-1].onClick.Invoke();return selectedCategory==category;}
        public bool InvokeFirstGo()=>InvokeFirst("Panel_2/Btn");
        public bool InvokeFirstClaim()=>InvokeFirst("Panel_2/Btn_0");
        public bool InvokeFirstItemDetail(){if(firstItemDetail==null||!firstItemDetail.interactable)return false;firstItemDetail.onClick.Invoke();return true;}
        public bool InvokeFirstDiscountBuy()=>InvokeFirst("Panel_1/Btn");
        public void InvokeStaminaAdd()=>staminaButton?.onClick.Invoke();
        public void InvokeGoldAdd()=>goldButton?.onClick.Invoke();
        public void Dispose(){store.Changed-=Render;shops.Changed-=Render;currencies.Changed-=RenderCurrencies;}

        private void Render()
        {
            for(int i=list.childCount-1;i>=0;i--)if(list.GetChild(i).name.StartsWith("SevenDayRuntimeItem",StringComparison.Ordinal))UnityEngine.Object.Destroy(list.GetChild(i).gameObject);
            if(!store.HasAuthoritativeResponse){status.text="正在同步七日目标";progress.text="--";return;}
            if(selectedCategory==4){RenderDiscounts();return;}
            int finished=0;foreach(SevenDayTaskRecord task in store.Tasks)if(task.State>0)finished++;
            status.text=$"七日目标：已同步 {store.Tasks.Count} 项";progress.text=$"{finished}/{store.Tasks.Count}";
            Image bar=view.GameObject.transform.Find("Panel/Reward/LoadingBg/LoadingBar")?.GetComponent<Image>();if(bar!=null)bar.fillAmount=store.Tasks.Count==0?0f:(float)finished/store.Tasks.Count;
            SevenDayTaskRecord[] visibleTasks=store.Tasks
                .OrderByDescending(value=>value.State==1)
                .ThenBy(value=>value.State==2)
                .ThenBy(value=>value.Id)
                .Take(12).ToArray();
            int shown=visibleTasks.Length;
            for(int i=0;i<shown;i++)CreateRow(visibleTasks[i],i);
            if(shown==0)status.text="七日目标：当前暂无任务数据";
        }

        private void CreateRow(SevenDayTaskRecord task,int index)
        {
            GameObject row=UnityEngine.Object.Instantiate(template,list,false);row.name=$"SevenDayRuntimeItem_{index}";row.SetActive(true);
            RectTransform rect=(RectTransform)row.transform;rect.anchorMin=new Vector2(0,1);rect.anchorMax=new Vector2(1,1);rect.pivot=new Vector2(.5f,1);rect.anchoredPosition=new Vector2(0,-index*152f);rect.sizeDelta=new Vector2(0,150);
            Transform root=row.transform;SetVisible(root.Find("Panel_1"),false);SetVisible(root.Find("Panel_2"),true);SetVisible(root.Find("Panel_2/Panel_weikaiqi"),false);
            SetText(root,"Panel_2/TitleBg/Text",$"七日目标 #{task.Id}");SetText(root,"Panel_2/Times",$"进度：{task.Progress}");
            SetVisible(root.Find("Panel_2/Get"),task.State==2);Button goButton=root.Find("Panel_2/Btn")?.GetComponent<Button>();Button claimButton=root.Find("Panel_2/Btn_0")?.GetComponent<Button>();
            if(goButton!=null){goButton.onClick.RemoveAllListeners();goButton.gameObject.SetActive(task.State==0);goButton.interactable=task.State==0;goButton.onClick.AddListener(()=>go(task.Id));}
            if(claimButton!=null){claimButton.onClick.RemoveAllListeners();claimButton.gameObject.SetActive(task.State==1);claimButton.interactable=task.State==1&&store.PendingClaimId==0;claimButton.onClick.AddListener(()=>claim(task.Id));}
            Button detail=root.GetComponentsInChildren<Button>(true).FirstOrDefault(value=>value!=goButton&&value!=claimButton);if(detail==null){GameObject target=new GameObject("SevenDayItemDetail",typeof(RectTransform),typeof(Image),typeof(Button));target.transform.SetParent(root.Find("Panel_2"),false);detail=target.GetComponent<Button>();}else detail.name="SevenDayItemDetail";detail.onClick.RemoveAllListeners();detail.interactable=true;detail.onClick.AddListener(()=>itemDetail(task.Id));if(index==0)firstItemDetail=detail;
            SetText(root,"Panel_2/Btn/Text",task.State==0?"前往":"已完成");SetText(root,"Panel_2/Btn_0/Text",task.State==1?"可领取":task.State==2?"已领取":"未完成");
        }

        private void BindSelectors(Transform root)
        {
            for(int i=1;i<=7;i++){int day=i;Button button=root.Find($"Panel/Renwu/bg/DaysList/Btn_{i}")?.GetComponent<Button>();dayButtons[i-1]=button;if(button!=null){button.onClick.RemoveAllListeners();button.interactable=true;button.onClick.AddListener(()=>SelectDay(root,day));}}
            for(int i=1;i<=4;i++){int category=i;Button button=root.Find($"Panel/Renwu/bg/Image2/CheckList/Type{i}")?.GetComponent<Button>();categoryButtons[i-1]=button;if(button!=null){button.onClick.RemoveAllListeners();button.interactable=true;button.onClick.AddListener(()=>SelectCategory(root,category));}}
            SelectDay(root,1);SelectCategory(root,1);
        }

        private void RenderDiscounts()
        {
            byte type=checked((byte)(9+selectedDay));status.text=$"第{selectedDay}天限时贩售";progress.text="折扣";
            if(!shops.TryGet(type,out GameplayShopPage page)){status.text+="：同步中";return;}
            int shown=Math.Min(page.Items.Count,8);for(int i=0;i<shown;i++)CreateShopRow(page.Items[i],type,i);
            if(shown==0)status.text+="：暂无商品";
        }
        private void CreateShopRow(ShopRecord item,byte type,int index)
        {
            GameObject row=UnityEngine.Object.Instantiate(template,list,false);row.name=$"SevenDayRuntimeItem_{index}";row.SetActive(true);RectTransform rect=(RectTransform)row.transform;rect.anchorMin=new Vector2(0,1);rect.anchorMax=new Vector2(1,1);rect.pivot=new Vector2(.5f,1);rect.anchoredPosition=new Vector2(0,-index*152f);rect.sizeDelta=new Vector2(0,150);Transform root=row.transform;SetVisible(root.Find("Panel_2"),false);SetVisible(root.Find("Panel_1"),true);SetText(root,"Panel_1/TitleBg/Text",item.Name);SetText(root,"Panel_1/Times",item.IsSoldOut?"已售罄":$"剩余 {item.RemainingLimit}");Button buy=root.Find("Panel_1/Btn")?.GetComponent<Button>();if(buy!=null){buy.onClick.RemoveAllListeners();buy.interactable=!item.IsSoldOut;buy.onClick.AddListener(()=>discountBuy(type,item.Id));}
        }
        private void SelectDay(Transform root,int day){selectedDay=day;for(int i=1;i<=7;i++){SetVisible(root.Find($"Panel/Renwu/bg/DaysList/Btn_{i}/Choose"),i==day);SetVisible(root.Find($"Panel/Renwu/bg/DaysList/Btn_{i}/Lock"),false);}if(selectedCategory==4)dayChanged(day);Render();}
        private void SelectCategory(Transform root,int category){selectedCategory=category;for(int i=1;i<=4;i++)SetVisible(root.Find($"Panel/Renwu/bg/Image2/CheckList/Type{i}/Choose"),i==category);categoryChanged(category);if(category==4)dayChanged(selectedDay);Render();}
        private void BindResources(Transform root){staminaButton=Bind(root.Find("Panel/GoldCheck/GoldIcon1/AddBtn"),staminaAdd);goldButton=Bind(root.Find("Panel/GoldCheck/GoldIcon3/AddBtn"),goldAdd);premiumButton=root.Find("Panel/GoldCheck/GoldIcon4/AddBtn")?.GetComponent<Button>();Disable(premiumButton);}
        private void RenderCurrencies(){Transform root=view.GameObject.transform;SetText(root,"Panel/GoldCheck/GoldIcon1/GoldNumBg/Num",$"{currencies.Stamina}/100");SetText(root,"Panel/GoldCheck/GoldIcon3/GoldNumBg/Num",currencies.Gold.ToString());SetText(root,"Panel/GoldCheck/GoldIcon4/GoldNumBg/Num",currencies.Premium.ToString());}
        private bool InvokeFirst(string path){for(int i=0;i<list.childCount;i++){Button b=list.GetChild(i).Find(path)?.GetComponent<Button>();if(b!=null&&b.gameObject.activeInHierarchy&&b.interactable){b.onClick.Invoke();return true;}}return false;}
        private static void ShowFinalLayout(Transform root)
        {
            Transform reward=root.Find("Panel/Reward");Transform tasks=root.Find("Panel/Renwu");SetVisible(reward,true);SetVisible(tasks,true);
            if(reward is RectTransform left)left.anchoredPosition=Vector2.zero;
            if(tasks is RectTransform right)right.anchoredPosition=new Vector2(1334,0);
            SetOpaque(reward);SetOpaque(tasks);
        }
        private static void SetOpaque(Transform target){if(target==null)return;CanvasGroup group=target.GetComponent<CanvasGroup>();if(group==null)group=target.gameObject.AddComponent<CanvasGroup>();group.alpha=1;group.interactable=true;group.blocksRaycasts=true;}
        private static void BindClose(Transform root,Action close){Button b=root.Find("Panel/Title/CloseBtn")?.GetComponent<Button>();if(b==null)return;b.onClick.RemoveAllListeners();b.onClick.AddListener(()=>close?.Invoke());}
        private static Button Bind(Transform target,Action action){Button b=target?.GetComponent<Button>();if(b==null)return null;b.onClick.RemoveAllListeners();b.interactable=true;b.onClick.AddListener(()=>action?.Invoke());return b;}
        private static void Disable(Button b){if(b==null)return;b.onClick.RemoveAllListeners();b.interactable=false;}
        private static Text RequireText(Transform root,string path)=>root.Find(path)?.GetComponent<Text>()??throw new InvalidOperationException($"SevenDay imported text was not found: {path}");
        private static void SetText(Transform root,string path,string value){Text t=root.Find(path)?.GetComponent<Text>();if(t!=null)t.text=value;}
        private static void SetVisible(Transform target,bool visible){if(target!=null)target.gameObject.SetActive(visible);}
        private static void Normalize(Transform root){if(!(root is RectTransform r))return;r.anchorMin=Vector2.zero;r.anchorMax=Vector2.one;r.pivot=new Vector2(.5f,.5f);r.offsetMin=r.offsetMax=Vector2.zero;r.anchoredPosition=Vector2.zero;r.localScale=Vector3.one;r.localRotation=Quaternion.identity;}
    }
}
