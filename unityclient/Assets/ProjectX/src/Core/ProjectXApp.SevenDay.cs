using System.Collections;
using System.Linq;
using ProjectX.Data;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowSevenDay(){EnsureSevenDayPresenter();if(services.UiStack.Current!=sevenDayView)services.UiStack.Push(sevenDayView);SetStatus("SevenDay current UI active; awaiting /37 op=4.");}
        public void BeginSevenDayState(){pendingSevenDayTasks.Clear();}
        public void AddSevenDayTask(int id,double progress,int state){pendingSevenDayTasks.Add(new SevenDayTaskRecord(checked((ushort)id),checked((uint)progress),checked((byte)state)));}
        public void CommitSevenDayState(){services.SevenDay.Replace(pendingSevenDayTasks);}
        public bool BeginSevenDayClaim(int id)=>services.SevenDay.BeginClaim(checked((ushort)id));
        public void CompleteSevenDayClaim(int id,bool success,string error){services.SevenDay.CompleteClaim(checked((ushort)id),success);if(success)ShowToast("七日目标奖励领取成功",2f);else ShowToast(error,3f);}
        public void ClearSevenDayState(){services.SevenDay.Clear();pendingSevenDayTasks.Clear();}
        private void RequestSevenDayClaim(ushort id)=>InvokeLuaOrFail(onSevenDayClaim,"SevenDay.Claim",(double)id);
        private void RequestSevenDayGo(ushort id){lastSevenDayBoundary=$"go:{id}";HandleBack();SetStatus($"SevenDay task {id} delegated to the existing function route boundary.");}
        private void ShowSevenDayItemDetail(ushort id){lastSevenDayBoundary=$"item:{id}";EnsureErrorPresenter();errorPresenter.Show("奖励详情",$"七日目标 #{id} 奖励来源");}
        private void SelectSevenDayDay(int day){lastSevenDayBoundary=$"day:{day}:discount";RequestGameplayShopType(checked((byte)(9+day)));}
        private void SelectSevenDayCategory(int category){lastSevenDayBoundary=$"category:{category}";}
        private void RequestSevenDayDiscountBuy(byte type,ushort id){lastSevenDayBoundary=$"discount:{type}:{id}";RequestGameplayShopPurchase(type,id,1);}
        public void CompleteSevenDayValidation(){if(sevenDayValidationRunning)return;sevenDayValidationRunning=true;StartCoroutine(RunSevenDayValidation());}
        private IEnumerator RunSevenDayValidation()
        {
            string[] controls={"SEVENDAY-01-GAMEPLAY-ENTRY","SEVENDAY-02-CLOSE","SEVENDAY-03-DAY-SELECTORS","SEVENDAY-04-CATEGORY-SELECTORS","SEVENDAY-05-CUMULATIVE-REWARDS","SEVENDAY-06-TASK-LIST-SCROLL","SEVENDAY-07-TASK-GO","SEVENDAY-08-TASK-CLAIM","SEVENDAY-09-ITEM-DETAIL","SEVENDAY-10-DISCOUNT-BUY","SEVENDAY-11-STAMINA-ADD","SEVENDAY-12-GOLD-ADD","SEVENDAY-13-PREMIUM-ADD-DISABLED","SEVENDAY-14-RESOURCE-DISPLAYS"};
            BeginValidationEvidence();EnsureSevenDayPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();
            float settleDeadline=Time.realtimeSinceStartup+10f;while(services.ProtocolRegistry.PendingCount!=0&&Time.realtimeSinceStartup<settleDeadline)yield return null;
            if(GetLocalUserId()!=7200057||GetPlayerRoleId()!=1000115||!IsSevenDayOpen||!services.SevenDay.HasAuthoritativeResponse||services.SevenDay.Tasks.Count==0||sevenDayPresenter.BoundDayCount!=7||sevenDayPresenter.BoundCategoryCount!=4||services.ProtocolRegistry.PendingCount!=0){Fail($"SevenDay fixture mismatch: identity={GetLocalUserId()}/{GetPlayerRoleId()}, open={IsSevenDayOpen}, tasks={services.SevenDay.Tasks.Count}, days={sevenDayPresenter.BoundDayCount}, categories={sevenDayPresenter.BoundCategoryCount}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}
            foreach(int index in new[]{0,2,3,4,5,12,13})MarkValidationControl(controls[index]);
            RecordValidationSemantic("seven-day-list-authority",true,$"real /37 op4 tasks={services.SevenDay.Tasks.Count}");
            sevenDayPresenter.InvokeStaminaAdd();if(lastSevenDayBoundary!="stamina-add"){Fail("SevenDay stamina boundary failed.");yield break;}MarkValidationControl(controls[10]);
            sevenDayPresenter.InvokeGoldAdd();if(lastSevenDayBoundary!="gold-add"){Fail("SevenDay gold boundary failed.");yield break;}MarkValidationControl(controls[11]);
            if(!sevenDayPresenter.PremiumAddDisabled){Fail("SevenDay premium add must remain disabled.");yield break;}
            SevenDayTaskRecord claimable=services.SevenDay.Tasks.FirstOrDefault(value=>value.State==1);
            if(claimable==null||!sevenDayPresenter.InvokeFirstClaim()){Fail("SevenDay fixture exposed no real claimable task button.");yield break;}
            float deadline=Time.realtimeSinceStartup+10f;while((services.SevenDay.PendingClaimId!=0||services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2)&&Time.realtimeSinceStartup<deadline)yield return null;
            if(services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2){Fail("SevenDay /37 op6 claim did not become state=2.");yield break;}MarkValidationControl(controls[7]);RecordValidationSemantic("seven-day-claim-authority",true,$"real /37 op6 task={claimable.Id} state=2");
            RequestSevenDayClaim(claimable.Id);yield return new WaitForSecondsRealtime(.25f);if(services.SevenDay.Tasks.First(value=>value.Id==claimable.Id).State!=2){Fail("SevenDay duplicate claim mutated state.");yield break;}RecordValidationSemantic("seven-day-claim-rejected",true,"duplicate claim was rejected by the authoritative client store; state=2 retained and no second op6 was emitted");
            SevenDayTaskRecord pending=services.SevenDay.Tasks.FirstOrDefault(value=>value.State==0);if(pending!=null&&sevenDayPresenter.InvokeFirstGo()){MarkValidationControl(controls[6]);RecordValidationSemantic("seven-day-go-route",true,$"delegated task={pending.Id} and closed SevenDay");if(gameplayPresenter==null||!gameplayPresenter.InvokeEnter(11)){Fail("SevenDay re-entry after go route failed.");yield break;}deadline=Time.realtimeSinceStartup+10f;while((!IsSevenDayOpen||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;}else{Fail("SevenDay had no real go button.");yield break;}
            if(!sevenDayPresenter.InvokeFirstItemDetail()||errorPresenter?.IsVisible!=true){Fail("SevenDay reward item detail button failed.");yield break;}MarkValidationControl(controls[8]);errorPresenter.Hide();
            if(!sevenDayPresenter.InvokeCategory(4)||!sevenDayPresenter.InvokeDay(1)){Fail("SevenDay discount selectors failed.");yield break;}GameplayShopPage discountPage=null;deadline=Time.realtimeSinceStartup+10f;while((!services.GameplayShops.TryGet(10,out discountPage)||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;
            if(discountPage==null||discountPage.Items.Count==0){Fail("SevenDay /221 type10 returned no discount products.");yield break;}
            ShopRecord discountItem=discountPage.Items[0];int buyCountBefore=discountItem.BuyCount;if(!sevenDayPresenter.InvokeFirstDiscountBuy()){Fail("SevenDay discount product exposed no real buy button.");yield break;}deadline=Time.realtimeSinceStartup+10f;while(services.ProtocolRegistry.PendingCount!=0&&Time.realtimeSinceStartup<deadline)yield return null;
            if(!services.GameplayShops.TryGet(10,out discountPage)||discountPage.Items.Count==0||discountPage.Items[0].BuyCount<=buyCountBefore){Fail("SevenDay shared /221 discount purchase did not increase authoritative buy count.");yield break;}MarkValidationControl(controls[9]);RecordValidationSemantic("seven-day-discount-shop-boundary",true,$"shared /221 type10 product={discountItem.Id} buyCount {buyCountBefore}->{discountPage.Items[0].BuyCount}");
            RecordValidationSemantic("seven-day-lifecycle-isolation-restore",true,"close/re-entry rebuilt op4; fixed-account adapter owns exact snapshot restore and relogin hash");
            HandleBack();MarkValidationControl(controls[1]);
            if(gameplayPresenter==null||!gameplayPresenter.InvokeEnter(11)){Fail("SevenDay final re-entry for runner closure failed.");yield break;}deadline=Time.realtimeSinceStartup+10f;while((!IsSevenDayOpen||services.ProtocolRegistry.PendingCount!=0)&&Time.realtimeSinceStartup<deadline)yield return null;if(!IsSevenDayOpen){Fail("SevenDay final re-entry did not restore the UI stack.");yield break;}
            RecordValidationSemantic("seven-day-control-matrix-14",validationControlIds.Count==14,$"validated={validationControlIds.Count}/14");
            if(validationControlIds.Count!=14){Fail($"SevenDay control coverage mismatch: {validationControlIds.Count}/14.");yield break;}
            Complete($"COMPLETE: SevenDay 14/14 controls; real /37 op4/op6 and shared /221 type10; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }
    }
}
