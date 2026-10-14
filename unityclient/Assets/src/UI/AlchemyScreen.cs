using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class AlchemyScreen : MonoBehaviour
    {
        [SerializeField] GroupedTemplateList groupedList;
        AlchemyCatalog catalog;AlchemyEnvelope state;IUiResourceProvider resources;
        readonly Dictionary<int,Button> rows=new Dictionary<int,Button>();
        readonly List<GameObject> materials=new List<GameObject>(),attributes=new List<GameObject>();
        Transform work,popup;GameObject materialTemplate,item;Text selected,quantity,empty;
        Image progress;int selectedRecipe,renderedRecipe,batches=1;bool pending;
        float received;long serverAt;
        public event Action BecameVisible,CloseRequested,ShopRequested,CancelRequested,ClaimRequested;
        public event Action SourceShopRequested;
        public event Action<int,int> StartRequested;
        public event Action<string> NoticeRequested;
        public int SelectedRecipe=>selectedRecipe;
        void OnEnable(){BecameVisible?.Invoke();}
        public void Back(){CloseRequested?.Invoke();}
        public void Bind(AlchemyCatalog value,IUiResourceProvider provider)
        {
            if(groupedList==null)throw new InvalidOperationException("炼丹房缺少公共分组列表绑定。");
            catalog=value;resources=provider;work=transform.Find("Workbench");popup=transform.Find("States/Popup");
            selected=work.Find("SelectedRecipe").GetComponent<Text>();quantity=work.Find("Panel_3/Count/Value").GetComponent<Text>();
            progress=work.Find("Progress/LoadingBar").GetComponent<Image>();empty=transform.Find("Sets/Empty").GetComponent<Text>();
            materialTemplate=work.Find("Materials/Material").gameObject;materialTemplate.SetActive(false);
            item=work.Find("FurnaceArt/item").gameObject;Click(item.transform,ShowProduct);
            item.transform.Find("Text").gameObject.SetActive(false);
            Click(work.Find("Panel_3/Btn_Minus"),()=>Adjust(-1));Click(work.Find("Panel_3/Btn_Plus"),()=>Adjust(1));
            Click(work.Find("Panel_3/Btn_Minus10"),()=>Adjust(-10));Click(work.Find("Panel_3/Btn_Plus10"),()=>Adjust(10));
            Click(work.Find("Start"),RequestStart);
            Click(work.Find("Unlearned"),RequestStart);
            Click(work.Find("Working/Cancel"),()=>CancelRequested?.Invoke());Click(work.Find("Ready/Claim"),()=>ClaimRequested?.Invoke());
            Click(popup.Find("Btn_close"),()=>popup.gameObject.SetActive(false));popup.gameObject.SetActive(false);
            Click(popup.Find("Source"),()=>SourceShopRequested?.Invoke());
            popup.Find("shuxing/bg/Attribute").gameObject.SetActive(false);
            var template=transform.Find("Sets/Scroll View/Viewport/Content/Set0").gameObject;template.SetActive(false);
            foreach(var realm in catalog.Realms)
            {
                int realmId=realm.Id;var group=Instantiate(template,template.transform.parent,false);group.name="Realm_"+realmId;
                var title=group.transform.Find("Name");title.GetComponent<Text>().text=realm.Name;
                groupedList.RegisterGroup(realmId,group,id=>{selectedRecipe=0;batches=1;Refresh();});
                var content=group.transform.Find("VirtualContent");var rowTemplate=content.Find("VirtualRow_0").gameObject;rowTemplate.SetActive(false);
                foreach(var recipe in catalog.Recipes.Values.Where(x=>x.Realm==realmId).OrderBy(x=>x.Series))
                {
                    int id=recipe.Id;var row=Instantiate(rowTemplate,content,false);row.name="Recipe_"+id;
                    row.transform.Find("zhangjie").GetComponent<Text>().text=recipe.Name;
                    rows[id]=Click(row.transform,()=>{groupedList.SelectGroup(realmId);selectedRecipe=id;batches=1;Refresh();});row.SetActive(true);
                }
                group.SetActive(true);
            }
            Refresh();
        }
        static Button Click(Transform node,Action action)
        {
            var button=node.GetComponent<Button>()??node.gameObject.AddComponent<Button>();
            button.targetGraphic=node.GetComponent<Graphic>()??node.GetComponentInChildren<Graphic>(true);
            if(button.targetGraphic!=null)button.targetGraphic.raycastTarget=true;
            button.transition=Selectable.Transition.None;button.onClick.RemoveAllListeners();button.onClick.AddListener(()=>action());return button;
        }
        public void Apply(AlchemyEnvelope value)
        {
            state=value;pending=false;received=Time.realtimeSinceStartup;serverAt=long.Parse(value.Server);
            int initialRealm=catalog.Realms.LastOrDefault(x=>x.First<=value.Level)?.Id??1;
            bool fresh=groupedList.InitializeSelection(initialRealm);
            if(fresh&&value.Recipe>0)selectedRecipe=value.Recipe;
            Refresh();
            if(fresh)StartCoroutine(groupedList.ScrollToSelection(transform.Find("Sets/Scroll View").GetComponent<ScrollRect>()));
        }
        public void Pending(bool value){pending=value;Refresh();}
        public void ResetSelection(){groupedList.ResetSelection();selectedRecipe=0;renderedRecipe=0;batches=1;Clear(materials);popup?.gameObject.SetActive(false);}
        bool TryRecipe(out AlchemyRecipe recipe)
        {
            if(!catalog.Recipes.TryGetValue(selectedRecipe,out recipe)){NoticeRequested?.Invoke("请先选择配方");return false;}
            if(pending||state==null){NoticeRequested?.Invoke("正在同步炼丹信息，请稍后再试");return false;}
            if(state.Recipe>0){NoticeRequested?.Invoke(Now>=long.Parse(state.Finish)?"炼制已完成，请先领取丹药":"正在炼制，暂时不能调整配方和数量");return false;}
            return true;
        }
        void RequestStart()
        {
            if(!TryRecipe(out var recipe))return;
            if(state.Level<recipe.Level){NoticeRequested?.Invoke("境界未达到该丹方的使用等级 "+recipe.Level);return;}
            if(!state.Learned.Contains(recipe.Id)){NoticeRequested?.Invoke("尚未学习该丹方，请在背包中使用丹方学习");return;}
            if(Maximum()<batches){NoticeRequested?.Invoke("材料不足，请前往材料商店购买");return;}
            StartRequested?.Invoke(selectedRecipe,batches);
        }
        void Adjust(int n)
        {
            if(!TryRecipe(out var recipe))return;
            if(n<0&&batches<=1){NoticeRequested?.Invoke("最少炼制1份");return;}
            int maximum=Maximum();
            if(n>0&&maximum<1){NoticeRequested?.Invoke("材料不足，无法增加炼制数量，请前往材料商店购买");return;}
            if(n>0&&batches>=maximum){NoticeRequested?.Invoke(maximum>=recipe.Limit?"已达到本次炼制数量上限（"+maximum+"份）":"当前材料最多可炼制"+maximum+"份");return;}
            batches=Mathf.Clamp(batches+n,1,Mathf.Max(1,maximum));Refresh();
        }
        int Maximum()
        {
            return catalog.Recipes.TryGetValue(selectedRecipe,out var r)?GetMaximumBatches(state,r):0;
        }
        public static int GetMaximumBatches(AlchemyEnvelope value,AlchemyRecipe recipe)
        {
            if(value==null||recipe==null)return 0;
            int max=recipe.Limit;foreach(var cost in recipe.Costs)max=Math.Min(max,value.Quantity(cost[0])/cost[1]);return Math.Max(0,max);
        }
        long Now=>serverAt+(long)((Time.realtimeSinceStartup-received)*1000);
        void Update(){if(state!=null&&state.Recipe>0)RefreshTime();}
        void RefreshTime()
        {
            bool active=state!=null&&state.Recipe>0;long remain=active?Math.Max(0,long.Parse(state.Finish)-Now):0;
            work.Find("Working").gameObject.SetActive(active&&remain>0);work.Find("Ready").gameObject.SetActive(active&&remain==0);
            work.Find("Progress/Value").gameObject.SetActive(active&&remain>0);
            work.Find("Progress/Reset").gameObject.SetActive(active&&remain==0);
            work.Find("Progress").gameObject.SetActive(active);if(!active)return;
            var r=catalog.Recipes[state.Recipe];double total=Math.Max(1,(long)r.Seconds*state.Count*1000*(10000-state.Reduction)/10000);
            progress.fillAmount=Mathf.Clamp01(1-(float)(remain/total));
            work.Find("Progress/Value").GetComponent<Text>().text=TimeSpan.FromMilliseconds(remain).ToString(@"hh\:mm\:ss");
            work.Find("Progress/Reset").GetComponent<Text>().text=remain==0?"炼制完成":"炼制中";
            var legacyTime=work.Find("Working/Time")?.GetComponent<Text>();if(legacyTime!=null)legacyTime.text="";
        }
        void Refresh()
        {
            if(catalog==null)return;
            groupedList.Refresh();groupedList.SetInteractable(!pending);
            foreach(var row in rows)
            {
                var r=catalog.Recipes[row.Key];bool learned=state?.Learned.Contains(r.Id)==true;
                var label=row.Value.transform.Find("zhangjie").GetComponent<Text>();label.text=r.Name+(learned?"("+catalog.UsedCount(state,r.Output)+"/"+catalog.Effects[r.Output].Limit+")":"");
                label.color=row.Key==selectedRecipe?new Color(.65f,.25f,.13f):new Color(.26f,.16f,.12f);
                row.Value.interactable=!pending;
            }
            bool chosen=catalog.Recipes.TryGetValue(selectedRecipe,out var recipe),active=state!=null&&state.Recipe>0;
            empty.gameObject.SetActive(state==null);empty.text="正在同步炼丹信息…";
            selected.text=chosen?recipe.Name:"请选择配方";item.SetActive(chosen);quantity.text=batches.ToString();
            bool learnedRecipe=chosen&&state?.Learned.Contains(recipe.Id)==true;
            work.Find("Unlearned").gameObject.SetActive(chosen&&!active&&!learnedRecipe);
            work.Find("Start").gameObject.SetActive(!active&&(!chosen||learnedRecipe));
            // Prerequisites are checked on click so unavailable actions still explain why.
            work.Find("Start").GetComponent<Button>().interactable=true;
            work.Find("Unlearned").GetComponent<Button>().interactable=true;
            foreach(var name in new[]{"Btn_Minus","Btn_Plus","Btn_Minus10","Btn_Plus10"})work.Find("Panel_3/"+name).GetComponent<Button>().interactable=true;
            work.Find("Working/Cancel").GetComponent<Button>().interactable=true;work.Find("Ready/Claim").GetComponent<Button>().interactable=true;
            if(renderedRecipe!=selectedRecipe)
            {
                Clear(materials);renderedRecipe=selectedRecipe;
                if(chosen)foreach(var cost in recipe.Costs)
                {
                    int id=cost[0];var row=Instantiate(materialTemplate,materialTemplate.transform.parent,false);row.name="Material_"+id;
                    var definition=catalog.Items[id];row.transform.Find("Icon").GetComponent<Image>().sprite=resources.LoadItemIcon(definition.Picture,out _);
                    row.transform.Find("Text").GetComponent<Text>().text=definition.Name;
                    ItemQualityVisual.ApplyFrame(row.GetComponent<Image>(),definition.Quality,resources);
                    Click(row.transform,()=>ShopRequested?.Invoke());row.SetActive(true);materials.Add(row);
                }
            }
            if(chosen)
            {
                var learning=catalog.Items[recipe.LearnItem];item.transform.Find("Icon").GetComponent<Image>().sprite=resources.LoadItemIcon(learning.Picture,out _);
                item.transform.Find("Icon").GetComponent<Image>().raycastTarget=true;
                ItemQualityVisual.ApplyFrame(item.GetComponent<Image>(),learning.Quality,resources);
                for(int i=0;i<materials.Count;i++){var c=recipe.Costs[i];materials[i].transform.Find("value").GetComponent<Text>().text=(state?.Quantity(c[0])??0)+"/"+((long)c[1]*batches);}
                if(chosen&&!active&&!learnedRecipe)work.Find("Unlearned/Notice").GetComponent<Text>().text=state!=null&&state.Level<recipe.Level?"境界未达到使用等级 "+recipe.Level:"尚未学习该丹方（背包中使用丹方学习）";
            }
            RefreshTime();
        }
        void ShowProduct()
        {
            if(!catalog.Recipes.TryGetValue(selectedRecipe,out var r))return;var output=catalog.Items[r.Output];
            popup.Find("IconColor/Icon").GetComponent<Image>().sprite=resources.LoadItemIcon(output.Picture,out _);
            popup.Find("IconColor/Name").GetComponent<Text>().text=output.Name;
            ItemQualityVisual.ApplyFrame(popup.Find("IconColor").GetComponent<Image>(),output.Quality,resources);
            var tpl=popup.Find("shuxing/bg/Attribute");Clear(attributes);
            foreach(var effect in catalog.Effects[r.Output].Attributes){var row=Instantiate(tpl.gameObject,tpl.parent,false);row.GetComponent<Text>().text=AlchemyCatalog.Attribute(effect);row.SetActive(true);attributes.Add(row);}
            popup.gameObject.SetActive(true);
        }
        static void Clear(List<GameObject> values){foreach(var x in values){x.SetActive(false);Destroy(x);}values.Clear();}
    }
}
