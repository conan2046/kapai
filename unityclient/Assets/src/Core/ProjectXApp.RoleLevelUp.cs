using System.Collections;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const string PlayerLevelUpPopupKey = "PlayerLevelUpPopup";
        private UnityUiView playerLevelUpPopup;
        private Coroutine playerLevelUpCoroutine;
        private int pendingLevelUpValue;
        private int pendingStaminaBefore;
        private int pendingStaminaAfter;

        public void NotifyPlayerLevelUp(int previousLevel, int currentLevel,
            double staminaBefore, double staminaAfter)
        {
            if (currentLevel <= previousLevel) return;
            if (playerLevelUpCoroutine == null)
                pendingStaminaBefore = Mathf.Max(0, (int)staminaBefore);
            pendingLevelUpValue = currentLevel;
            pendingStaminaAfter = Mathf.Max(0, (int)staminaAfter);
            if (playerLevelUpCoroutine == null)
                playerLevelUpCoroutine = StartCoroutine(ShowPlayerLevelUpWhenBattleCloses());
        }

        private IEnumerator ShowPlayerLevelUpWhenBattleCloses()
        {
            yield return null;
            while (IsBattlePresentationActive || CurrentAppState != AppState.Main)
                yield return null;

            int currentLevel = pendingLevelUpValue;
            int staminaBefore = pendingStaminaBefore;
            int staminaAfter = pendingStaminaAfter;
            playerLevelUpCoroutine = null;
            if (services == null || services.UiAssets == null) yield break;
            if (playerLevelUpPopup != null) services.UiAssets.Release(playerLevelUpPopup);

            UnityUiView view = services.UiAssets.InstantiateUnity(
                PlayerLevelUpPopupKey, GetDynamicUiRoot());
            playerLevelUpPopup = view;
            PlayerLevelUpPopupView presenter = new PlayerLevelUpPopupView(view, () =>
            {
                services?.UiAssets?.Release(view);
                if (playerLevelUpPopup == view) playerLevelUpPopup = null;
            });
            presenter.Show(currentLevel, staminaBefore, staminaAfter);
        }
    }
}
