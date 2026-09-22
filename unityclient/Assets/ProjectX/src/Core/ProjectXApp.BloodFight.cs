using System.Collections;
using ProjectX.Data;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowBloodFight(){EnsureBloodFightPresenter();if(services.UiStack.Current!=bloodFightView)services.UiStack.Push(bloodFightView);SetStatus("BloodFight current UI active; awaiting /323 op=1.");}
        public void SetBloodFightState(int remaining,int revives,int state,int rewardState,int chapter,int level,int todayMaxLevel,int historicalMaxStar,int totalStar,int todayMaxStar,int currentStar){services.BloodFight.Replace(checked((byte)remaining),checked((byte)revives),checked((byte)state),checked((byte)rewardState),checked((byte)chapter),checked((ushort)level),checked((ushort)todayMaxLevel),checked((ushort)historicalMaxStar),checked((ushort)totalStar),checked((ushort)todayMaxStar),checked((ushort)currentStar));}
        public void CompleteBloodFightValidation(){StartCoroutine(CompleteBloodFightValidationAfterLayout());}
        private IEnumerator CompleteBloodFightValidationAfterLayout(){EnsureBloodFightPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsBloodFightOpen||!services.BloodFight.HasAuthoritativeResponse||!IsBloodFightAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"BloodFight state mismatch: open={IsBloodFightOpen}, authoritative={services.BloodFight.HasAuthoritativeResponse}, visible={IsBloodFightAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=8 -> XueZhan.XueZhanMainUI -> csd/xuezhan/XuezhanMain.csb -> /323 op=1 chapter={services.BloodFight.Chapter}, level={services.BloodFight.Level}, remaining={services.BloodFight.Remaining}; isolated user={GetLocalUserId()}");}
    }
}
