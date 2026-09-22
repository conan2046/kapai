using System;
using System.Collections;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowFunds(int functionId){EnsureFundsPresenter();taskView?.SetVisible(false);staminaClaimView?.SetVisible(false);resourceRecoveryView?.SetVisible(false);FundKind kind=functionId==26?FundKind.Active:FundKind.Growth;fundsPresenter.Show(kind);welfareActivityFramePresenter.Select(functionId);if(services.UiStack.Current!=taskBackgroundView)services.UiStack.Push(taskBackgroundView);SetStatus($"{(kind==FundKind.Growth?"Growth":"Active")} fund current UI active; awaiting /222.");}
        public void BeginFundsPage(int rawKind,double endTime,int boughtPlanId){pendingFundKind=(FundKind)checked((byte)rawKind);pendingFundEndTime=checked((uint)endTime);pendingFundBoughtPlanId=checked((byte)boughtPlanId);pendingFundPlans.Clear();}
        public void BeginFundPlan(int id,int bought,double buyTime,int progress,double rate,double price,double total){pendingFundPlanId=checked((byte)id);pendingFundPlanBought=checked((byte)bought);pendingFundBuyTime=checked((uint)buyTime);pendingFundPlanProgress=checked((byte)progress);pendingFundRate=checked((uint)rate);pendingFundPrice=checked((uint)price);pendingFundTotal=checked((uint)total);pendingFundTiers.Clear();}
        public void BeginFundTier(int condition,int state){pendingFundTierCondition=checked((byte)condition);pendingFundTierState=checked((byte)state);pendingFundRewards.Clear();}
        public void AddFundReward(int itemId,double amount){pendingFundRewards.Add(new FundReward(checked((ushort)itemId),checked((uint)amount)));}
        public void EndFundTier(){pendingFundTiers.Add(new FundTier(pendingFundTierCondition,pendingFundTierState,pendingFundRewards.ToArray()));}
        public void EndFundPlan(){pendingFundPlans.Add(new FundPlan(pendingFundPlanId,pendingFundPlanBought,pendingFundBuyTime,pendingFundPlanProgress,pendingFundRate,pendingFundPrice,pendingFundTotal,pendingFundTiers.ToArray()));}
        public void CommitFundsPage(){services.Funds.Replace(new FundPage(pendingFundKind,pendingFundEndTime,pendingFundBoughtPlanId,pendingFundPlans.ToArray(),true));}
        public void CompleteFundsValidation(){StartCoroutine(CompleteFundsValidationAfterLayout());}
        private IEnumerator CompleteFundsValidationAfterLayout(){EnsureFundsPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();FundPage growth=services.Funds.Get(FundKind.Growth),active=services.Funds.Get(FundKind.Active);if(!IsFundsOpen||!services.Funds.HasAllAuthoritativeResponses||!IsFundsAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"Funds mismatch: open={IsFundsOpen}, growth={growth.Plans.Count}, active={active.Plans.Count}, visible={IsFundsAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: function_id=25/26 -> WelfareActivityUI -> ChengZhangLayer/HuoyueLayer -> /222 op=83/94 growthPlans={growth.Plans.Count}, activePlans={active.Plans.Count}; read-only first phase");}
        private void EnsureFundsPresenter(){EnsureWelfareActivityFramePresenter();growthFundView=growthFundView??services.UiRouter.FindBySource("huodong/ChengZhangLayer");activeFundView=activeFundView??services.UiRouter.FindBySource("huodong/HuoyueLayer");if(growthFundView==null||activeFundView==null)throw new InvalidOperationException("Current fund CocosUiBinding was not found: ChengZhangLayer/HuoyueLayer.");fundsPresenter=fundsPresenter??new FundsPresenter(growthFundView,activeFundView,services.Funds,services.FundsCatalog);}
    }
}
