using System;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BindBagClick(bool autoInvoke)
        {
            // Legacy main-HUD bag entry removed from UImainLayer_new.
        }

        public void BindSettingsClick()
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                settingsButton = mainView.BindClick(SettingsPath, HandleSettingsClick, true);
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindTaskClick(bool autoInvoke)
        {
            // Legacy main-HUD task entry removed from UImainLayer_new.
        }

        public void BindHeroClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button formationButton = mainView.BindClick(FormationPath, HandleFormationClick, true);
                if (autoInvoke)
                {
                    if (!HasCommandLineFlag("-projectXHeroRebirthG4Validation") || !heroRebirthG4ValidationRunning)
                        StartCoroutine(InvokeButtonNextFrame(formationButton));
                }
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        private void RequestHeroRebirthValidationSnapshot()
            => InvokeLuaOrFail(onHeroClicked, "HeroRebirth.ReloginSnapshot");

        public void BindMailClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(MailPath, HandleMailClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void ShowMail()
        {
            ShowMergedMail();
        }
    }
}
