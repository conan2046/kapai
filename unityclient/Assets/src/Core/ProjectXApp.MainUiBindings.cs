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
            try
            {
                mainView = mainView ?? services.UiRouter.FindByKey(UiPrefabKey.MainHud, true);
                Button button = mainView.BindClick(BagPath, HandleBagClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindSettingsClick()
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindByKey(UiPrefabKey.MainHud, true);
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
                mainView = mainView ?? services.UiRouter.FindByKey(UiPrefabKey.MainHud, true);
                Button formationButton = mainView.BindClick(FormationPath, HandleFormationClick, true);
                if (autoInvoke)
                {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
                    if (!HasCommandLineFlag("-projectXHeroRebirthG4Validation") || !heroRebirthG4ValidationRunning)
                        StartCoroutine(InvokeButtonNextFrame(formationButton));
#else
                    StartCoroutine(InvokeButtonNextFrame(formationButton));
#endif
                }
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

#if UNITY_EDITOR || DEVELOPMENT_BUILD
#if UNITY_EDITOR || DEVELOPMENT_BUILD
        private void RequestHeroRebirthValidationSnapshot()
            => InvokeLuaOrFail(onHeroClicked, "HeroRebirth.ReloginSnapshot");
#endif
#endif

        public void BindMailClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindByKey(UiPrefabKey.MainHud, true);
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
