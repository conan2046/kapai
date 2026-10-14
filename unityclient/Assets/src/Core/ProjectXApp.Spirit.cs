using System;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;
namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private UnityUiView spiritView;
        private SpiritScreen spiritScreen;
        private string spiritPending;
        private int spiritPendingOperation;
        private float spiritDeadline,spiritNextPoll;
        private int spiritSession;
        private Coroutine spiritPolling;
        public bool IsSpiritOpen=>spiritView?.GameObject.activeInHierarchy==true&&services?.UiStack.Current==spiritView;
        public bool IsSpiritActive()=>IsSpiritOpen;
        private void ShowSpirit()
        {
            if(spiritView==null||!spiritView.IsAlive){spiritView=services.UiRouter.FindByKey("DongFuSpirit",true);spiritScreen=spiritView.GameObject.GetComponent<SpiritScreen>();
                spiritScreen.Bind(RequestSpirit,id=>id==60000?"金币":services.EquipmentCatalog.GetItem(id)?.Name??("道具"+id));
                spiritScreen.CloseRequested+=CloseSpirit;spiritScreen.BecameVisible+=RestoreSpiritFrame;spiritScreen.ErrorReported+=ShowSpiritError;}
            dongFuSubView=spiritView;dongFuBuilding=1;
            if(services.UiStack.Current!=spiritView)services.UiStack.Push(spiritView);
            RestoreSpiritFrame();
        }
        private void RestoreSpiritFrame()
        {
            ConfigureDongFuSharedFrame(spiritView,spiritScreen.Back,ShowSpiritHelp);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<UnityEngine.UI.Text>().text="聚灵阵";
            spiritPending=null;spiritSession=services.Network.SessionVersion;spiritScreen.ResetSession();spiritNextPoll=Time.realtimeSinceStartup;
            if(spiritPolling!=null)StopCoroutine(spiritPolling);spiritPolling=StartCoroutine(PollSpirit());
        }
        private void ShowSpiritHelp()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowHelp("每5秒产出灵气，离线也结算，达到储量上限后停止。\n"+
                "聚灵阵等级限制五行灵根等级；点击各灵根可独立升级。\n"+
                "成长、收获加成按五根当前等级汇总，仅影响新种植的灵植。\n"+
                "战斗属性按各级指定站位累计，点击站位加成查看。\n"+
                "升级消耗及效果以配置为准。");
        }
        private void ShowSpiritError(string message){EnsureErrorPresenter();errorPresenter.Show("聚灵阵",message);}
        private void CloseSpirit(){if(services.UiStack.Current==spiritView)services.UiStack.Pop();else spiritView?.SetVisible(false);spiritPending=null;if(spiritPolling!=null){StopCoroutine(spiritPolling);spiritPolling=null;}if(IsDongFuOpen)RestoreDongFuFrame();}
        private void RequestSpirit(int operation,int rootType,string revision)
        {
            // A user upgrade may supersede an in-flight read. Its old response
            // is ignored by request ID; reads never change upgrade button state.
            if(spiritPending!=null&&(operation==0||spiritPendingOperation!=0))return;
            spiritNextPoll=float.PositiveInfinity;
            if(!services.Network.IsConnected){spiritScreen.Fail("连接已断开，请重新登录");return;}
            string id=Guid.NewGuid().ToString("N");var payload=new JObject{["request_id"]=id,["revision"]=revision};if(operation==2)payload["root_type"]=rootType;var msg=LegacyTcpMessage.New();msg.WriteWord(325);msg.WriteByte(operation);msg.WriteString(payload.ToString(Formatting.None));
            spiritPending=id;spiritPendingOperation=operation;spiritDeadline=Time.realtimeSinceStartup+8;
            if(operation!=0)spiritScreen.SetPending();
            try{services.Network.Send(msg);}catch(Exception e){spiritPending=null;spiritScreen.Fail("聚灵阵请求失败："+e.Message);spiritNextPoll=Time.realtimeSinceStartup+1;}
        }
        private void ApplySpiritPacket(LegacyTcpMessage message)
        {
            if(message.ReadByte()!=128)throw new InvalidOperationException("聚灵阵回包版本错误");var state=JsonConvert.DeserializeObject<SpiritEnvelope>(message.ReadString());
            if(state==null||state.Schema!=2||message.Remaining!=0)throw new InvalidOperationException("聚灵阵回包格式错误");
            if(HandleDongFuReminderRead(325,state.RequestId,state))return;
            if(long.TryParse(state.Spirit,out long spiritBalance))services.Currencies.Set(CurrencyIds.Spirit,spiritBalance);
            if(spiritScreen!=null&&IsSpiritOpen&&spiritSession==services.Network.SessionVersion&&string.IsNullOrEmpty(state.RequestId)&&spiritPending==null){RecordDongFuReminder(325,state);spiritScreen.Apply(state);ScheduleSpiritProduction(state);return;}
            if(spiritScreen==null||!IsSpiritOpen||spiritSession!=services.Network.SessionVersion||spiritPending==null||state.RequestId!=spiritPending)return;
            spiritPending=null;RecordDongFuReminder(325,state);spiritScreen.Apply(state);ScheduleSpiritProduction(state);
        }
        private void ScheduleSpiritProduction(SpiritEnvelope state)
        {
            spiritNextPoll=float.PositiveInfinity;
            // A rejected upgrade still carries an authoritative snapshot, but
            // its error disables actions until a successful read clears it.
            // Reads failing repeatedly use a slower retry to avoid a tight loop.
            if(!string.IsNullOrEmpty(state.Error)){
                spiritNextPoll=Time.realtimeSinceStartup+(state.Operation==0?5f:1f);
                return;
            }
            if(state.Configured&&state.Unlocked&&string.IsNullOrEmpty(state.Error)
                &&long.TryParse(state.Spirit,out long owned)&&long.TryParse(state.Storage,out long capacity)&&(capacity==0||owned<capacity))
                spiritNextPoll=Time.realtimeSinceStartup+Mathf.Max(0.05f,(state.ProductionPeriodMs-state.ProductionElapsedMs)/1000f);
        }
        private System.Collections.IEnumerator PollSpirit()
        {
            while(IsSpiritOpen){
                if(spiritSession!=services.Network.SessionVersion){spiritPending=null;spiritScreen.Fail("连接已变化，请重新进入聚灵阵");yield break;}
                if(spiritPending!=null&&Time.realtimeSinceStartup>=spiritDeadline){spiritPending=null;spiritScreen.Fail("请求超时，正在重新同步阵法");spiritNextPoll=Time.realtimeSinceStartup+1;}
                if(spiritPending==null&&Time.realtimeSinceStartup>=spiritNextPoll)RequestSpirit(0,0,"0");yield return null;
            }
        }
    }
}
