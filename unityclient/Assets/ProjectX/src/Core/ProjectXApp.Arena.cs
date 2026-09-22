using System.Collections;
using ProjectX.Data;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowArena(){EnsureArenaPresenter();if(services.UiStack.Current!=arenaView)services.UiStack.Push(arenaView);SetStatus("Arena current KaPaiArenaUI active; awaiting /161 op=0.");}
        public void SetArenaState(int opponents,double rank,int remaining,int challenged,int bought,double score){services.Arena.Replace(opponents,checked((uint)rank),checked((ushort)remaining),checked((ushort)challenged),checked((byte)bought),checked((uint)score));}
        public void SetArenaError(string message){ShowToast(message,3f);SetStatus("Arena/161 failed: "+message);}
        public void CompleteArenaValidation(){StartCoroutine(CompleteArenaValidationAfterLayout());}
        private IEnumerator CompleteArenaValidationAfterLayout(){EnsureArenaPresenter();Canvas.ForceUpdateCanvases();yield return new WaitForEndOfFrame();if(!IsArenaOpen||!services.Arena.HasAuthoritativeResponse||!IsArenaAuthoritativeVisible||services.ProtocolRegistry.PendingCount!=0){Fail($"Arena state mismatch: open={IsArenaOpen}, authoritative={services.Arena.HasAuthoritativeResponse}, visible={IsArenaAuthoritativeVisible}, pending={services.ProtocolRegistry.PendingCount}.");yield break;}Complete($"COMPLETE: btn_wanfa -> function_id=6 -> WanFa.KaPaiArenaUI -> csd/common/JingjiLayer.csb -> /161 op=0 rank={services.Arena.Rank}, opponents={services.Arena.OpponentCount}, remaining={services.Arena.Remaining}; isolated user={GetLocalUserId()}");}
    }
}
