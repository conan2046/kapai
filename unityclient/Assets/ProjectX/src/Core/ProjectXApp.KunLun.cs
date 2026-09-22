using System.Collections;
using ProjectX.Data;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowKunLun(){EnsureKunLunPresenter();if(services.UiStack.Current!=kunLunView)services.UiStack.Push(kunLunView);SetStatus("KunLun current UI active; awaiting /213 op=25.");}
        public void BeginKunLunState(int floor,int fights,int buys,int position){pendingKunLunFloor=checked((byte)floor);pendingKunLunFights=checked((byte)fights);pendingKunLunBuys=checked((byte)buys);pendingKunLunPosition=checked((byte)position);pendingKunLunEnemies.Clear();}
        public void AddKunLunEnemy(int position,double roleId,string name,int profession,int sex,int level,double power,int robot,int state,int healthPercent){pendingKunLunEnemies.Add(new KunLunEnemyRecord(checked((byte)position),checked((uint)roleId),name,checked((byte)profession),checked((byte)sex),checked((ushort)level),checked((uint)power),robot!=0,checked((byte)state),Mathf.Clamp(healthPercent,0,100)));}
        public void CommitKunLunState(){services.KunLun.Replace(pendingKunLunFloor,pendingKunLunFights,pendingKunLunBuys,pendingKunLunPosition,pendingKunLunEnemies);int currentFloor=(pendingKunLunPosition-1)/3+1;bool visible=services.Player.Level>=34&&pendingKunLunFights>0&&!(currentFloor==3&&pendingKunLunFloor==4);services.Gameplay.SetFunctionHotPoint(7,visible);}
        public void CompleteKunLunValidation(){StartCoroutine(CompleteKunLunValidationAfterLayout());}
        private IEnumerator CompleteKunLunValidationAfterLayout(){EnsureKunLunPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsKunLunOpen||!services.KunLun.HasAuthoritativeResponse||!IsKunLunAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"KunLun state mismatch: open={IsKunLunOpen}, authoritative={services.KunLun.HasAuthoritativeResponse}, visible={IsKunLunAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=7 -> JueZhanKunLun.KunLunJueZhanUI -> csd/kunlun/juezhankunlun.csb -> /213 op=25 floor={services.KunLun.Floor}, enemies={services.KunLun.Enemies.Count}, remaining={services.KunLun.RemainingFights}; isolated user={GetLocalUserId()}");}
    }
}
