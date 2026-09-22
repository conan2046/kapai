using System;
using System.Collections;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowResourceRecovery(){EnsureResourceRecoveryPresenter();taskView?.SetVisible(false);staminaClaimView?.SetVisible(false);growthFundView?.SetVisible(false);activeFundView?.SetVisible(false);resourceRecoveryView.SetVisible(true);welfareActivityFramePresenter.Select(19);if(services.UiStack.Current!=taskBackgroundView)services.UiStack.Push(taskBackgroundView);SetStatus("ResourceRecovery current welfare UI active; awaiting /52 op=1.");}
        public void BeginResourceRecoveryState(){pendingResourceRecoveryRecords.Clear();}
        public void BeginResourceRecoveryRecord(int functionId,int leftTimes,int costId,int costSubtype,double costAmount){pendingResourceRecoveryFunctionId=functionId;pendingResourceRecoveryLeftTimes=checked((ushort)leftTimes);pendingResourceRecoveryCostId=costId;pendingResourceRecoveryCostSubtype=costSubtype;pendingResourceRecoveryCostAmount=checked((uint)costAmount);pendingResourceRecoveryRewards.Clear();}
        public void AddResourceRecoveryReward(int itemId,int subtype,double amount){pendingResourceRecoveryRewards.Add(new ResourceRecoveryReward(itemId,subtype,checked((uint)amount)));}
        public void EndResourceRecoveryRecord(){pendingResourceRecoveryRecords.Add(new ResourceRecoveryRecord(pendingResourceRecoveryFunctionId,pendingResourceRecoveryLeftTimes,pendingResourceRecoveryCostId,pendingResourceRecoveryCostSubtype,pendingResourceRecoveryCostAmount,pendingResourceRecoveryRewards.ToArray()));}
        public void CommitResourceRecoveryState(){services.ResourceRecovery.Replace(pendingResourceRecoveryRecords);}
        public void CompleteResourceRecoveryValidation(){StartCoroutine(CompleteResourceRecoveryValidationAfterLayout());}
        private IEnumerator CompleteResourceRecoveryValidationAfterLayout(){EnsureResourceRecoveryPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsResourceRecoveryOpen||!IsResourceRecoveryAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"ResourceRecovery state mismatch: open={IsResourceRecoveryOpen}, records={services.ResourceRecovery.Items.Count}, visible={IsResourceRecoveryAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=19 -> WelfareActivityUI/FindOfflineExp -> huodong/ziyuanzhaohui -> /52 op=1 records={services.ResourceRecovery.Items.Count}; read-only first phase");}
        private void EnsureResourceRecoveryPresenter(){EnsureWelfareActivityFramePresenter();resourceRecoveryView=resourceRecoveryView??services.UiRouter.FindBySource("huodong/ziyuanzhaohui");if(resourceRecoveryView==null)throw new InvalidOperationException("Current ResourceRecovery imported CocosUiBinding was not found: huodong/ziyuanzhaohui.");resourceRecoveryPresenter=resourceRecoveryPresenter??new ResourceRecoveryPresenter(resourceRecoveryView,services.ResourceRecovery,services.ResourceRecoveryCatalog);}
    }
}
