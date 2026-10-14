using System;
using System.Collections;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        UnityUiView alchemyView,alchemyShopView,alchemyRewardView;
        AlchemyScreen alchemyScreen;AlchemyCatalog alchemyCatalog;AlchemyEnvelope alchemyState;
        ShopStore alchemyShopStore;ShopPresenter alchemyShopPresenter;
        Coroutine alchemyPoll;string alchemyPending;int alchemySession;float alchemyDeadline,alchemyNextRead;
        bool IsAlchemyOpen=>alchemyView?.GameObject.activeInHierarchy==true&&services?.UiStack.Current==alchemyView;
        bool IsAlchemyShopOpen=>alchemyShopView?.GameObject.activeInHierarchy==true&&services?.UiStack.Current==alchemyShopView;
        bool alchemyShopFromHub;
        bool alchemyShopFromSource;
        Vector2 alchemyShopDefaultPosition;
        string AlchemyShopTitle=>alchemyShopFromHub||alchemyShopFromSource?"丹方商店":"材料商店";
        void ShowAlchemy()
        {
            if(alchemyView==null||!alchemyView.IsAlive)
            {
                alchemyCatalog=new AlchemyCatalog();alchemyView=services.UiRouter.FindByKey("DongFuAlchemy",true);
                alchemyScreen=alchemyView.GameObject.GetComponent<AlchemyScreen>()??alchemyView.GameObject.AddComponent<AlchemyScreen>();
                alchemyScreen.Bind(alchemyCatalog,services.Resources);alchemyScreen.CloseRequested+=CloseAlchemy;
                alchemyScreen.BecameVisible+=RestoreAlchemyFrame;alchemyScreen.ShopRequested+=ShowAlchemyShop;
                alchemyScreen.SourceShopRequested+=ShowAlchemySourceShop;
                alchemyScreen.NoticeRequested+=ShowAlchemyNotice;
                alchemyScreen.StartRequested+=(id,n)=>RequestAlchemy(2,id,n);
                alchemyScreen.CancelRequested+=ConfirmAlchemyCancel;alchemyScreen.ClaimRequested+=()=>RequestAlchemy(4,0,1);
                dongFuPages[2]=alchemyView;
            }
            alchemyScreen.ResetSelection();dongFuSubView=alchemyView;dongFuBuilding=2;
            if(services.UiStack.Current!=alchemyView)services.UiStack.Push(alchemyView);
            RestoreAlchemyFrame();
        }
        void RestoreAlchemyFrame()
        {
            ConfigureDongFuSharedFrame(alchemyView,alchemyScreen.Back,ShowAlchemyHelp);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<Text>().text="炼丹房";
            alchemySession=services.Network.SessionVersion;alchemyPending=null;alchemyNextRead=Time.realtimeSinceStartup;
            if(alchemyState!=null)alchemyScreen.Apply(alchemyState);else alchemyScreen.Pending(true);
            RestartAlchemyPoll();
        }
        void RestartAlchemyPoll(){if(alchemyPoll!=null)StopCoroutine(alchemyPoll);alchemyPoll=StartCoroutine(PollAlchemy());}
        void CloseAlchemy()
        {
            if(services.UiStack.Current==alchemyView)services.UiStack.Pop();else alchemyView?.SetVisible(false);
            alchemyPending=null;if(alchemyPoll!=null){StopCoroutine(alchemyPoll);alchemyPoll=null;}
            if(IsDongFuOpen)RestoreDongFuFrame();
        }
        void ShowAlchemyHelp()
        {
            EnsureErrorPresenter();errorPresenter.ShowConfirmation("炼丹说明",
                "丹方需达到对应境界，并在背包中消耗1本学习。\n点击配方图标预览丹药；点击材料图标打开材料商店。\n炼制取消返还50%材料；离线继续计时。\n完成后手动领取并自动服用；超过服用上限的产出按道具出售价格转为金币。\n效果永久生效，已学丹方显示累计服用次数与上限。",
                ShowAlchemyShop,"材料商店","关闭",false);
        }
        void ShowAlchemyNotice(string message)
        {
            EnsureErrorPresenter();errorPresenter.Show("炼丹房",message);
        }
        void ConfirmAlchemyCancel()
        {
            if(alchemyState?.Recipe<=0)return;EnsureErrorPresenter();int session=services.Network.SessionVersion;
            errorPresenter.ShowConfirmation("取消炼丹","取消后返还已扣材料的50%，每种材料向下取整。",
                ()=>{if(IsAlchemyOpen&&session==services.Network.SessionVersion)RequestAlchemy(3,0,1);},"取消炼制","继续炼制",true);
        }
        void RequestAlchemy(int operation,int id,int quantity)
        {
            if(alchemyPending!=null){if(operation!=0)ShowAlchemyNotice("正在同步炼丹信息，请稍后再试");return;}
            if(!services.Network.IsConnected){EnsureErrorPresenter();errorPresenter.Show("炼丹房","连接已断开，请重新登录");return;}
            string request=Guid.NewGuid().ToString("N");var payload=new JObject{["request_id"]=request,["revision"]=alchemyState?.Revision??"0",["quantity"]=quantity};
            if(operation==2)payload["recipe_id"]=id;else if(operation==1||operation==5||operation==6)payload["item_id"]=id;
            var packet=LegacyTcpMessage.New();packet.WriteWord(327);packet.WriteByte(operation);packet.WriteString(payload.ToString(Formatting.None));
            alchemyPending=request;alchemyDeadline=Time.realtimeSinceStartup+8;alchemyNextRead=float.PositiveInfinity;
            if(operation!=0){alchemyScreen?.Pending(true);if(IsAlchemyShopOpen)SetAlchemyShopPending(true);}
            try{services.Network.Send(packet);}catch(Exception e){alchemyPending=null;alchemyScreen?.Pending(false);SetAlchemyShopPending(false);alchemyNextRead=Time.realtimeSinceStartup+1;EnsureErrorPresenter();errorPresenter.Show("炼丹房",e.Message);}
        }
        void ApplyAlchemyPacket(LegacyTcpMessage packet)
        {
            if(packet.ReadByte()!=128)throw new InvalidOperationException("炼丹回包版本错误");
            var state=JsonConvert.DeserializeObject<AlchemyEnvelope>(packet.ReadString());
            if(state==null||state.Schema!=1||packet.Remaining!=0)throw new InvalidOperationException("炼丹回包格式错误");
            if(HandleDongFuReminderRead(327,state.Request,state))return;
            bool fromBag=state.Request?.StartsWith("bag-",StringComparison.Ordinal)==true;
            if(!fromBag&&(!IsAlchemyOpen&&!IsAlchemyShopOpen||alchemySession!=services.Network.SessionVersion||state.Request!=alchemyPending))return;
            alchemyState=state;RecordDongFuReminder(327,state);if(!fromBag)alchemyPending=null;
            if(long.TryParse(state.Gold,out long gold))services.Currencies.Set(CurrencyIds.Gold,gold);
            if(IsAlchemyOpen)alchemyScreen.Apply(state);if(IsAlchemyShopOpen)RenderAlchemyShop();
            SetAlchemyShopPending(false);alchemyNextRead=Time.realtimeSinceStartup+2;
            if(!string.IsNullOrEmpty(state.Error)){EnsureErrorPresenter();errorPresenter.Show("炼丹房",state.Error);return;}
            if(fromBag)ShowToast(state.Operation==1?"丹方学习成功":"丹药服用成功",2f);
            if(state.Operation==4&&!string.IsNullOrEmpty(state.Result))ShowAlchemyClaim(JsonConvert.DeserializeObject<AlchemyClaim>(state.Result));
        }
        IEnumerator PollAlchemy()
        {
            while(IsAlchemyOpen||IsAlchemyShopOpen)
            {
                if(alchemySession!=services.Network.SessionVersion){alchemyPending=null;break;}
                if(alchemyPending!=null&&Time.realtimeSinceStartup>=alchemyDeadline){alchemyPending=null;alchemyScreen?.Pending(false);SetAlchemyShopPending(false);alchemyNextRead=Time.realtimeSinceStartup+1;EnsureErrorPresenter();errorPresenter.Show("炼丹房","请求超时，正在重新同步；请勿重复领取。");}
                if(alchemyPending==null&&Time.realtimeSinceStartup>=alchemyNextRead)RequestAlchemy(0,0,1);
                yield return null;
            }
        }
        void ShowAlchemyShop()
        {
            if(alchemyState==null||alchemyPending!=null){ShowAlchemyNotice("正在同步炼丹信息，请稍后再试");return;}
            OpenAlchemyShop(false);
        }
        void ShowAlchemySourceShop()
        {
            if(alchemyState==null||alchemyPending!=null){ShowAlchemyNotice("正在同步炼丹信息，请稍后再试");return;}
            OpenAlchemyShop(false,true);
        }
        void OpenAlchemyShop(bool fromHub,bool fromSource=false)
        {
            alchemyCatalog=alchemyCatalog??new AlchemyCatalog();
            alchemyShopFromHub=fromHub;
            alchemyShopFromSource=fromSource;
            if(alchemyShopView==null||!alchemyShopView.IsAlive)
            {
                alchemyShopView=services.UiAssets.InstantiateUnity("shangcheng",GetDynamicUiRoot());alchemyShopStore=new ShopStore();
                alchemyShopDefaultPosition=((RectTransform)alchemyShopView.GameObject.transform).anchoredPosition;
                bagInputView=bagInputView??services.UiAssets.GetUnityOrCreate("EnterNumLayer",GetDynamicUiRoot());
                alchemyShopPresenter=new ShopPresenter(alchemyShopView,alchemyShopStore,services.Currencies,services.Resources,services.ServerTime,bagInputView,
                    (record,n)=>{EnsureErrorPresenter();errorPresenter.ShowConfirmation(AlchemyShopTitle,record.Name+" ×"+n+"\n消耗金币："+record.TotalCost(n),()=>{if(IsAlchemyShopOpen)RequestAlchemy(6,record.RewardType,n);},"购买","取消",true);},()=>RequestAlchemy(0,0,1));
            }
            if(services.UiStack.Current!=alchemyShopView)services.UiStack.Push(alchemyShopView,fromHub||fromSource);
            if(fromHub)
            {
                alchemyShopView.GameObject.transform.SetParent(GetDynamicUiRoot(),false);
                SetOneLevelFrameVisible(true);ConfigureShopFrame();
                bagPopupFrameView.SetVisible(true);ConfigureShopHubTabs(ShopHubTab.Alchemy);
                NormalizeShopLayerOrder(alchemyShopView);
            }
            else
            {
                ConfigureDongFuSharedFrame(alchemyShopView,CloseAlchemyShop,null,fromSource?null:alchemyView);
                oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<Text>().text=AlchemyShopTitle;
            }
            // The same shop switches between the hub and the authored DongFu frame.
            ((RectTransform)alchemyShopView.GameObject.transform).anchoredPosition=fromHub?alchemyShopDefaultPosition:new Vector2(-50f,38f);
            alchemySession=services.Network.SessionVersion;alchemyPending=null;
            RenderAlchemyShop();alchemyNextRead=Time.realtimeSinceStartup;RestartAlchemyPoll();
        }
        void CloseAlchemyShop()
        {
            if(alchemyShopFromHub)
            {
                LeaveAlchemyShopHub();shopHubOpen=false;bagPopupFrameView?.SetVisible(false);
                SetOneLevelFrameVisible(false);SetMainHudSurfaceVisible(true);
            }
            else
            {
                bool wasSource=alchemyShopFromSource;alchemyShopFromSource=false;
                if(services.UiStack.Current==alchemyShopView)services.UiStack.Pop();else alchemyShopView?.SetVisible(false);
                // Source return re-enables Alchemy, whose OnEnable restores its frame.
                // The material route keeps it active underneath and needs an explicit restore.
                if(!wasSource)RestoreAlchemyFrame();
            }
        }
        void RenderAlchemyShop()
        {
            if(alchemyShopStore==null||alchemyState==null)return;
            var records=alchemyState.Shop.Select(id=>
            {
                var item=alchemyCatalog.Items[id];var price=alchemyCatalog.Shop[id].Price;
                // Item IDs provide stable ordering even when the expanded shop exceeds 255 goods.
                return new ShopRecord(0,checked((ushort)id),0,id,0,1,item.Name,item.Description,item.Picture,item.Quality,CurrencyIds.Gold,3006,"金币",price,-1,new[]{100});
            });
            alchemyShopStore.Replace(1,0,0,0,services.ServerTime.UnixSeconds,records);
            alchemyShopPresenter.Render();var label=alchemyShopView.FindNode("Layer/ShopUI/ListView_left/Panel_button/Button_1/Text");if(label!=null)label.GetComponent<Text>().text=AlchemyShopTitle;
        }
        void SetAlchemyShopPending(bool value){if(alchemyShopView?.IsAlive==true){var button=alchemyShopView.FindNode("Layer/ShopUI/btn_Buy")?.GetComponent<Button>();if(button!=null&&value)button.interactable=false;}}
        void ShowAlchemyClaim(AlchemyClaim claim)
        {
            if(claim==null)return;alchemyRewardView=alchemyRewardView??services.UiAssets.InstantiateUnity("ItemGet",GetDynamicUiRoot());
            var item=alchemyCatalog.Items[claim.Item];Transform root=alchemyRewardView.GameObject.transform.Find("ItemGetUI/Item");
            root.Find("Title").GetComponent<Text>().text="炼丹完成";root.Find("Name").GetComponent<Text>().text=item.Name;
            root.Find("Num").GetComponent<Text>().text="×"+claim.Count;
            var icon=root.Find("Icon").GetComponent<Image>();icon.sprite=services.Resources.LoadItemIcon(item.Picture);icon.gameObject.SetActive(true);
            ItemQualityVisual.ApplyFrame(root.Find("Bg").GetComponent<Image>(),item.Quality,services.Resources);
            string effects=claim.Used>0?"自动服用 "+claim.Used+" 个\n"+string.Join("\n",alchemyCatalog.Effects[claim.Item].Attributes.Select(x=>AlchemyCatalog.Attribute(new[]{x[0],checked(x[1]*claim.Used)}))):"已达到服用上限";
            if(claim.Sold>0)effects+="\n超出上限 "+claim.Sold+" 个，金币 +"+claim.Gold;
            root.Find("Attributes").GetComponent<Text>().text=effects;
            alchemyRewardView.BindClick("ItemGetUI/Mask",()=>alchemyRewardView.SetVisible(false),true);
            alchemyRewardView.BindClick("ItemGetUI/Item",()=>alchemyRewardView.SetVisible(false),true);
            alchemyRewardView.ShowPopup();
        }
    }
}
