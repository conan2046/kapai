using System;
using System.Collections.Generic;
using System.Linq;
using ProjectX.Data;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.UI
{
    public sealed class GardenScreen : MonoBehaviour
    {
        [SerializeField] private GardenPlotView[] plots;
        [SerializeField] private Button back;
        [SerializeField] private GameObject planting;
        [SerializeField] private Button plantingClose;
        [SerializeField] private Animation drawerAnimation;
        [SerializeField] private RectTransform selectionFrame;
        [SerializeField] private GameObject cropRowTemplate;
        [SerializeField] private Transform cropRows;
        [SerializeField] private GameObject actions;
        [SerializeField] private Text actionTitle;
        [SerializeField] private Text actionStatus;
        [SerializeField] private Button actionsClose;
        [SerializeField] private Button water;
        [SerializeField] private Button bugs;
        [SerializeField] private Button remove;
        [SerializeField] private Button harvest;
        [SerializeField] private GameObject confirmation;
        [SerializeField] private Button confirm;
        [SerializeField] private Button cancel;
        [SerializeField] private Text notice;
        [SerializeField] private GameObject loading;
        [SerializeField] private GameObject modalBlocker;
        [SerializeField] private GameObject seedPurchase;
        [SerializeField] private Text seedPurchaseTitle;
        [SerializeField] private Text seedPurchaseDescription;
        [SerializeField] private Button seedPurchaseConfirm;
        [SerializeField] private Button seedPurchaseCancel;
        [SerializeField] private Button seedPurchaseClose;
        [SerializeField] private Image seedPurchaseIcon;
        [SerializeField] private Text seedPurchaseName;
        [SerializeField] private Text seedPurchaseQuantity;
        [SerializeField] private Text seedPurchaseTotal;
        [SerializeField] private Button seedPurchaseMinus;
        [SerializeField] private Button seedPurchasePlus;
        [SerializeField] private Button seedPurchaseMinus10;
        [SerializeField] private Button seedPurchasePlus10;
        private readonly Dictionary<int, GardenPlotSnapshot> states = new Dictionary<int, GardenPlotSnapshot>();
        private readonly Dictionary<int, GameObject> rows = new Dictionary<int, GameObject>();
        private GardenConfig config;
        private Func<string, Sprite> loadSprite;
        private Func<int, string> realmName;
        private Action<int, int, int, string, int> request;
        private Func<long> availableGold;
        private bool pending;
        private int selected;
        private int purchaseCrop;
        private int purchaseQuantity=1;
        public event Action CloseRequested;
        public event Action BecameVisible;
        private void OnEnable() => BecameVisible?.Invoke();
        public bool HasState => states.Count == 36;
        private void LateUpdate()
        {
            RefreshSelection();
            if(modalBlocker!=null)modalBlocker.SetActive(actions.activeSelf||confirmation.activeSelf||(seedPurchase!=null&&seedPurchase.activeSelf));
        }
        public void Back()
        {
            if(seedPurchase!=null&&seedPurchase.activeSelf)seedPurchase.SetActive(false);
            else if(confirmation.activeSelf){confirmation.SetActive(false);actions.SetActive(true);}
            else if(actions.activeSelf)actions.SetActive(false);
            else if(planting.activeSelf)ShowPlanting(false);
            else CloseRequested?.Invoke();
        }

        public void Bind(GardenConfig configuration, Func<string, Sprite> sprites, Func<int, string> realm, Action<int,int,int,string,int> send,Func<long> gold)
        {
            if (config != null) return;
            config = configuration; loadSprite = sprites; realmName = realm; request = send;availableGold=gold;
            if (plots.Length != 36 || plots.Select(p => p.Id).Distinct().Count() != 36) throw new InvalidOperationException("灵园必须绑定36个唯一地块");
            if(back!=null)back.onClick.AddListener(() => CloseRequested?.Invoke());
            plantingClose.onClick.AddListener(TogglePlanting);
            seedPurchaseConfirm.onClick.AddListener(()=>Act(6,purchaseCrop));
            seedPurchaseCancel.onClick.AddListener(()=>seedPurchase.SetActive(false));
            seedPurchaseClose.onClick.AddListener(()=>seedPurchase.SetActive(false));
            seedPurchaseMinus.onClick.AddListener(()=>ChangePurchaseQuantity(-1));
            seedPurchasePlus.onClick.AddListener(()=>ChangePurchaseQuantity(1));
            seedPurchaseMinus10.onClick.AddListener(()=>ChangePurchaseQuantity(-10));
            seedPurchasePlus10.onClick.AddListener(()=>ChangePurchaseQuantity(10));
            actionsClose.onClick.AddListener(() => actions.SetActive(false));
            cancel.onClick.AddListener(() => {confirmation.SetActive(false);actions.SetActive(true);});
            remove.onClick.AddListener(() => {actions.SetActive(false);confirmation.SetActive(true);});
            confirm.onClick.AddListener(() => Act(4));
            water.onClick.AddListener(() => Act(2));bugs.onClick.AddListener(() => Act(3));harvest.onClick.AddListener(() => Act(5));
            foreach (GardenPlotView plot in plots){int id=plot.Id;plot.Button.onClick.AddListener(() => Select(id));}
            foreach (GardenCropDefinition crop in config.Crops.Values.OrderBy(c=>c.Id))
            {
                GameObject row = Instantiate(cropRowTemplate, cropRows, false);
                row.name = "Crop_" + crop.Id;
                int id = crop.Id;
                row.GetComponent<GardenCropRowView>().Bind(crop,loadSprite(crop.IconResource),()=>Act(1,id),()=>ShowSeedPurchase(id));
                rows[id] = row;row.SetActive(true);
            }
            cropRowTemplate.SetActive(false);
            ShowPlanting(false);actions.SetActive(false);confirmation.SetActive(false);seedPurchase.SetActive(false);
            SetPending(true);
        }
        public void Apply(GardenEnvelope envelope)
        {
            pending = false;
            loading.SetActive(false);
            if(!string.IsNullOrEmpty(envelope.Error)||envelope.Operation!=0)notice.text = envelope.Error ?? "";
            if (!string.IsNullOrEmpty(envelope.Error)){Refresh();return;}
            if (envelope.Schema != 1 || envelope.Plots == null || envelope.Plots.Length != 36
                || envelope.Plots.Select(p=>p.Id).Distinct().Count()!=36 || envelope.Plots.Any(p=>p.Id<1||p.Id>36))
                throw new InvalidOperationException("灵园权威地块快照错误");
            states.Clear();foreach (GardenPlotSnapshot p in envelope.Plots) states[p.Id] = p;
            foreach (GameObject row in rows.Values) row.GetComponent<GardenCropRowView>().SetStock(0);
            foreach (GardenSeedStock seed in envelope.Stock ?? Array.Empty<GardenSeedStock>())
                if(rows.TryGetValue(seed.CropId,out GameObject row))row.GetComponent<GardenCropRowView>().SetStock(seed.Count);
            if(envelope.Operation==1){notice.text="种植成功";}
            if(envelope.Operation==4){confirmation.SetActive(false);actions.SetActive(false);ShowPlanting(true);notice.text="已铲除，可重新种植";}
            if(envelope.Operation==5){actions.SetActive(false);notice.text="收获成功";}
            if(envelope.Operation==6){seedPurchase.SetActive(false);notice.text="已购买种子，点击灵植即可种植";}
            Refresh();
        }
        public void SetPending(bool value){pending=value;loading.SetActive(value);Refresh();}
        public void Fail(string message){pending=false;loading.SetActive(false);notice.text=message;Refresh();}
        private void Refresh()
        {
            RefreshSelection();
            foreach(GardenPlotView view in plots)
            {
                if(!states.TryGetValue(view.Id,out GardenPlotSnapshot p)){view.Button.interactable=false;continue;}
                Sprite[] sprites=null;
                if(p.CropId>0 && config.Crops.TryGetValue(p.CropId,out GardenCropDefinition crop))sprites=new[]{loadSprite(crop.InitialResource),loadSprite(crop.MiddleResource),loadSprite(crop.MatureResource)};
                view.Render(p,sprites,realmName(p.RequiredRealm),pending);
            }
            if(selected>0 && states.TryGetValue(selected,out GardenPlotSnapshot state))
            {
                actionTitle.text=state.CropId>0 && config.Crops.TryGetValue(state.CropId,out GardenCropDefinition crop)?crop.Name:"空地";
                actionStatus.text=state.Stage==3?"已成熟，可收获":"预计剩余 "+Math.Ceiling(long.Parse(state.RemainingMs)/1000d)+"秒";
                water.interactable=!pending&&state.Water&&state.Stage!=3;
                bugs.interactable=!pending&&state.Bugs&&state.Stage!=3;
                remove.interactable=!pending&&state.CropId>0;
                harvest.interactable=!pending&&state.Stage==3;
            }
            confirm.interactable=!pending;
            seedPurchaseConfirm.interactable=!pending;
            seedPurchaseCancel.interactable=!pending;
            if(seedPurchase.activeSelf)RefreshPurchase();
            foreach(GameObject row in rows.Values)row.GetComponent<GardenCropRowView>().SetPending(pending);
        }
        private void RefreshSelection()
        {
            if(selectionFrame==null)return;
            GardenPlotView target=selected>0?plots.FirstOrDefault(p=>p.Id==selected):null;
            selectionFrame.gameObject.SetActive(target!=null);
            if(target!=null)
            {
                var rect=(RectTransform)target.transform;
                // The shared overlay follows selection and the authored drawer animation.
                // Size, scale, artwork and draw order stay in the prefab.
                selectionFrame.position=rect.TransformPoint(rect.rect.center);
            }
        }
        private void Select(int id)
        {
            if(pending||!states.TryGetValue(id,out GardenPlotSnapshot p))return;
            if(!p.Unlocked){notice.text=realmName(p.RequiredRealm)+"解锁第"+id+"块灵田";return;}
            selected=id;notice.text="";
            if(p.CropId>0&&p.Stage==3)
            {
                actions.SetActive(false);confirmation.SetActive(false);
                Act(5);return;
            }
            ShowPlanting(true);actions.SetActive(p.CropId>0);confirmation.SetActive(false);Refresh();
        }
        private void TogglePlanting()
        {
            bool open=!planting.activeSelf;
            if(!open){actions.SetActive(false);confirmation.SetActive(false);}
            ShowPlanting(open);
        }
        private void ShowSeedPurchase(int cropId)
        {
            if(pending||!config.Crops.TryGetValue(cropId,out GardenCropDefinition crop)||crop.SeedPriceGold<=0)return;
            purchaseCrop=cropId;
            purchaseQuantity=1;
            seedPurchaseTitle.text="购买种子";
            seedPurchaseDescription.text="选择购买数量";
            seedPurchaseName.text=crop.Name+"种子";
            seedPurchaseIcon.sprite=loadSprite(crop.IconResource);
            seedPurchase.SetActive(true);
            RefreshPurchase();
        }
        private void ChangePurchaseQuantity(int delta)
        {
            long limit=Math.Max(1,Math.Min(int.MaxValue,availableGold()/config.Crops[purchaseCrop].SeedPriceGold));
            purchaseQuantity=(int)Math.Max(1,Math.Min(limit,(long)purchaseQuantity+delta));RefreshPurchase();
        }
        private void RefreshPurchase()
        {
            long price=config.Crops[purchaseCrop].SeedPriceGold;
            long limit=Math.Max(1,Math.Min(int.MaxValue,availableGold()/price));
            purchaseQuantity=(int)Math.Min(limit,purchaseQuantity);
            seedPurchaseQuantity.text=purchaseQuantity.ToString();seedPurchaseTotal.text=(price*purchaseQuantity).ToString();
            seedPurchaseConfirm.interactable=!pending&&availableGold()>=price*purchaseQuantity;
            seedPurchaseMinus.interactable=seedPurchaseMinus10.interactable=!pending&&purchaseQuantity>1;
            seedPurchasePlus.interactable=seedPurchasePlus10.interactable=!pending&&purchaseQuantity<limit;
        }
        private void ShowPlanting(bool open)
        {
            planting.SetActive(open);
            if(!open){selected=0;RefreshSelection();}
            if(drawerAnimation!=null)
            {
                // Position and arrow states are authored in the prefab's clips.
                drawerAnimation.Play(open?"GardenDrawerOpen":"GardenDrawerClosed");
                drawerAnimation.Sample();
            }
        }
        private void Act(int operation,int cropId=0)
        {
            if(operation==6){if(pending)return;SetPending(true);request(operation,0,cropId,"0",purchaseQuantity);return;}
            if(pending)return;
            if(!states.TryGetValue(selected,out GardenPlotSnapshot p)){notice.text="请先点击已解锁的空地";return;}
            if(operation==1&&(!p.Unlocked||p.CropId>0)){notice.text="请选择已解锁的空地进行种植";return;}
            SetPending(true);request(operation,selected,cropId,p.Revision,1);
        }
    }
}
