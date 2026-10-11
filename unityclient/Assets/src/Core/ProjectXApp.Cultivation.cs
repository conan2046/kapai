using System;
using System.Globalization;
using Newtonsoft.Json;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private JingJieOfflineNotice cultivationOfflineNotice;
        private JingJieTrial cultivationTrial;
        private JingJieTrial cultivationResult;
        private JingJieRuntimeRules cultivationRules;
        private ulong cultivationLastGain;
        private string cultivationLastKind;
        private string cultivationLastResultHandled;
        private string cultivationOfflineShown;
        private UnityUiView cultivationTrialView;
        private DuJiePresenter cultivationPresenter;

        public void ApplyJingJieEnvelope(string json)
        {
            JingJieEnvelope envelope=JsonConvert.DeserializeObject<JingJieEnvelope>(json);
            if(envelope==null || envelope.Schema!=2 || envelope.State==null)
                throw new InvalidOperationException("Invalid Unity realm protocol envelope.");
            jingJieConfig=jingJieConfig??new JingJieConfigData();
            JingJieDefinition definition=jingJieConfig.Get(envelope.State.Id);
            if(definition.NextId!=envelope.State.NextId || definition.RequiredExperience.ToString(CultureInfo.InvariantCulture)!=envelope.State.NeedExperience
                || definition.ExperiencePerSecond!=envelope.State.Rate)
                throw new InvalidOperationException("Unity realm client/server configuration differs.");
            if(envelope.Trial?.Big==true)services.JingJie.BeginUpgrade();
            int previous=services.JingJie.CurrentId;
            if(services.JingJie.ApplySnapshot(envelope.State,envelope.Trial?.Big==true))
            {
                services.Player.ApplyCultivation(checked((ushort)envelope.State.Id),services.JingJie.Experience,services.JingJie.Power);
                if(previous!=envelope.State.Id && services.Player.IsLoaded && singlePlayerTitleEnabled && activeSaveSlotId>0)
                    singlePlayerSaves.UpdatePlayer(activeSaveSlotId,services.Player.RoleId,services.Player.Name,
                        services.Player.Model,services.Player.Level,services.Player.Power);
            }
            cultivationOfflineNotice=envelope.Offline;
            cultivationTrial=envelope.Trial;
            cultivationResult=envelope.Result;
            cultivationLastKind=envelope.Kind;
            cultivationLastGain=ulong.TryParse(envelope.Gain,NumberStyles.None,CultureInfo.InvariantCulture,out ulong gain)?gain:0;
            if(envelope.Kind=="settlement" && cultivationLastGain>0 && jingJieRenderBridge?.IsVisible==true
                && cultivationPresenter?.IsRunning!=true)
                ShowToast($"+{cultivationLastGain:N0}经验");
            if(envelope.Kind=="upgrade")
            {
                if(!string.IsNullOrEmpty(envelope.Error))FailJingJieUpgrade(envelope.Error);
                else if(envelope.Result!=null && !envelope.Result.Big)
                {
                    services.JingJie.FinishUpgrade();
                    if(cultivationLastResultHandled!=envelope.Result.Id)
                    {cultivationLastResultHandled=envelope.Result.Id;CompleteJingJieUpgrade(envelope.State.Id,string.Empty);}
                }
            }
        }

        private void TickCultivationPresentation()
        {
            if(services==null || CurrentAppState!=AppState.Main)return;
            if(cultivationOfflineNotice!=null && cultivationOfflineNotice.Id!=cultivationOfflineShown
                && errorPresenter?.IsVisible!=true)
            {
                EnsureErrorPresenter();
                if(errorPresenter==null)return;
                JingJieOfflineNotice notice=cultivationOfflineNotice;
                TimeSpan duration=TimeSpan.FromSeconds(notice.Seconds);
                string elapsed=$"{(int)duration.TotalHours}小时{duration.Minutes}分{duration.Seconds}秒";
                ulong earned=ulong.Parse(notice.Experience,CultureInfo.InvariantCulture);
                errorPresenter.Show("离线收益",$"离线时长：{elapsed}\n获得经验：{earned:N0}\n经验已自动到账");
                cultivationOfflineShown=notice.Id;
                AcknowledgeCultivation(notice.Id,true);
            }
            if(errorPresenter?.IsVisible==true || cultivationTrial?.Big!=true
                || cultivationTrial.Id==cultivationLastResultHandled || cultivationPresenter?.IsRunning==true)return;
            cultivationTrialView=cultivationTrialView??services.UiAssets.InstantiateUnity("DuJieLayer",GetDynamicUiRoot());
            cultivationPresenter=cultivationTrialView.GameObject.GetComponent<DuJiePresenter>()
                ??cultivationTrialView.GameObject.AddComponent<DuJiePresenter>();
            cultivationTrialView.ShowPopup();
            toastPresenter?.Clear();
            JingJieTrial trial=cultivationTrial;
            cultivationPresenter.Begin(trial,CultivationRules,services.Player.Sex,services.Player.Name,()=>
            {
                cultivationLastResultHandled=trial.Id;
                cultivationTrialView.SetVisible(false);
                AcknowledgeCultivation(trial.Id,false);
                services.JingJie.FinishUpgrade();
                if(trial.Success)CompleteJingJieUpgrade(services.JingJie.CurrentId,string.Empty);
                else ShowToast("渡劫失败，继续修炼后可再次尝试",3f);
            });
        }

        private void ResetCultivationPresentation()
        {
            cultivationTrialView?.SetVisible(false);
            cultivationOfflineNotice=null;
            cultivationTrial=null;
            cultivationResult=null;
            cultivationLastGain=0;
            cultivationLastKind=null;
            cultivationLastResultHandled=null;
            cultivationOfflineShown=null;
        }

        public void SendJingJieUpgradeRequest()
        {
            var packet=LegacyTcpMessage.New();packet.WriteWord(306);packet.WriteByte(4);
            packet.WriteString(Guid.NewGuid().ToString("N"));packet.WriteWord(services.JingJie.CurrentId);Send(packet);
        }
        private void AcknowledgeCultivation(string id,bool offline)
        {
            var packet=LegacyTcpMessage.New();packet.WriteWord(306);packet.WriteByte(offline?6:5);
            packet.WriteString(id);Send(packet);
        }
        private JingJieRuntimeRules CultivationRules
        {
            get
            {
                if(cultivationRules!=null)return cultivationRules;
                var asset=ProjectX.Foundation.ResourceLoader.Load<UnityEngine.TextAsset>("ProjectXData/Configs/jingjie-rules");
                if(asset==null)throw new InvalidOperationException("Unity realm runtime rules missing.");
                return cultivationRules=JsonConvert.DeserializeObject<JingJieRuntimeRules>(asset.text);
            }
        }
    }
}
