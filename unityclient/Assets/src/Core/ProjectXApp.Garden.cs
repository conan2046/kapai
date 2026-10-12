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
        private UnityUiView gardenView;
        private GardenScreen gardenScreen;
        private GardenConfig gardenConfig;
        private JingJieConfigData gardenRealmNames;
        private string gardenPending;
        private float gardenDeadline;
        private float gardenNextPoll;
        private int gardenSession;
        private Coroutine gardenPolling;
        public bool IsGardenOpen => gardenView?.GameObject.activeInHierarchy == true
            && services?.UiStack.Current == gardenView;
        private void ShowGarden()
        {
            if(gardenView==null||!gardenView.IsAlive)
            {
                gardenConfig=new GardenConfig();gardenRealmNames=new JingJieConfigData();
                gardenView=services.UiRouter.FindByKey("DongFuGardenScene",true);
                gardenScreen=gardenView.GameObject.GetComponent<GardenScreen>();
                gardenScreen.Bind(gardenConfig,services.Resources.LoadSprite,
                    id=>gardenRealmNames.Get(id).Name,RequestGarden,()=>services.Currencies.Gold);
                gardenScreen.CloseRequested+=CloseGarden;
                gardenScreen.BecameVisible+=RestoreGardenFrame;
            }
            if(services.UiStack.Current!=gardenView)services.UiStack.Push(gardenView);
            RestoreGardenFrame();
            gardenPending=null;gardenSession=services.Network.SessionVersion;
            RequestGarden(0,0,0,"0");
            if(gardenPolling!=null)StopCoroutine(gardenPolling);
            gardenPolling=StartCoroutine(PollGarden());
        }
        private void RestoreGardenFrame()
        {
            ConfigureDongFuSharedFrame(gardenView,gardenScreen.Back,null);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<UnityEngine.UI.Text>().text="灵园";
            gardenPending=null;gardenSession=services.Network.SessionVersion;
            gardenNextPoll=Time.realtimeSinceStartup;
            if(gardenPolling!=null)StopCoroutine(gardenPolling);
            gardenPolling=StartCoroutine(PollGarden());
        }
        private void CloseGarden()
        {
            if(services.UiStack.Current==gardenView)services.UiStack.Pop();else gardenView?.SetVisible(false);
            gardenPending=null;
            if(gardenPolling!=null){StopCoroutine(gardenPolling);gardenPolling=null;}
            if(IsDongFuOpen)RestoreDongFuFrame();
        }
        private void RequestGarden(int operation,int plot,int crop,string revision,int quantity=1)
        {
            if(!services.Network.IsConnected){gardenScreen.Fail("连接已断开，请重新登录");return;}
            string id=operation==0?"":Guid.NewGuid().ToString("N");
            JObject payload=new JObject{["request_id"]=id,["plot_id"]=plot,["crop_id"]=crop,["revision"]=revision,["quantity"]=quantity};
            var message=LegacyTcpMessage.New();message.WriteWord(324);message.WriteByte(operation);message.WriteString(payload.ToString(Formatting.None));
            gardenPending=id;gardenDeadline=Time.realtimeSinceStartup+8;gardenNextPoll=Time.realtimeSinceStartup+2;
            try{services.Network.Send(message);}catch(Exception e){gardenPending=null;gardenScreen.Fail("灵园请求失败："+e.Message);}
        }
        private void ApplyGardenPacket(LegacyTcpMessage message)
        {
            if(message.ReadByte()!=128)throw new InvalidOperationException("灵园回包版本错误");
            GardenEnvelope envelope=JsonConvert.DeserializeObject<GardenEnvelope>(message.ReadString());
            if(envelope==null||message.Remaining!=0)throw new InvalidOperationException("灵园回包格式错误");
            if(gardenScreen==null)return;
            if(envelope.Operation!=0&&(gardenPending==null||gardenPending!=envelope.RequestId))return;
            if(gardenPending!=null&&gardenPending!=envelope.RequestId)return;
            gardenPending=null;gardenScreen.Apply(envelope);
        }
        private System.Collections.IEnumerator PollGarden()
        {
            while(IsGardenOpen)
            {
                if(gardenSession!=services.Network.SessionVersion){gardenScreen.Fail("连接已变化，请重新进入灵园");yield break;}
                if(gardenPending!=null&&Time.realtimeSinceStartup>=gardenDeadline){gardenPending=null;gardenScreen.Fail("请求超时，正在重新同步地块");gardenNextPoll=Time.realtimeSinceStartup+1;}
                if(gardenPending==null&&Time.realtimeSinceStartup>=gardenNextPoll)RequestGarden(0,0,0,"0");
                yield return null;
            }
        }
    }
}
