using System;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void BindWelfareClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Welfare"))
                {
                    mainView.FindNode("Layer/Main_UI/ButtonGroup1/btn_fuli")?.SetActive(false);
                    mainView.FindNode(WelfareLegacyPath)?.SetActive(false);
                    mainView.GameObject.transform.Find("WelfareEntryRuntime")?.gameObject.SetActive(false);
                    mainHudPresenter?.SetWelfareVisible(false);
                    return;
                }
                Button button = EnsureRuntimeWelfareEntry();
                MakeButtonVisualTransparent(button);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindActivityClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                if (IsSteamExcludedModule("Activity"))
                {
                    mainView.FindNode(ActivityPath)?.SetActive(false);
                    return;
                }
                Button button = mainView.BindClick(ActivityPath, HandleActivityClick, true);
                EnsureActivityHotPoint(button.transform);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindDrawClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                Button button = mainView.BindClick(DrawPath, HandleDrawClick, true);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(button));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }

        public void BindGameplayClick(bool autoInvoke)
        {
            try
            {
                mainView = mainView ?? services.UiRouter.FindBySource(UiRouter.MainHudSourceToken, true);
                GameObject gameplayNode = FindMainHudNode(GameplayPath);
                if (gameplayNode == null) throw new InvalidOperationException($"UI node was not found: {GameplayPath}");
                gameplayButton = mainView.BindClickNode(gameplayNode, HandleGameplayClick, true, GameplayPath);
                if (autoInvoke) StartCoroutine(InvokeButtonNextFrame(gameplayButton));
            }
            catch (Exception exception) { Fail(exception.Message); }
        }
    }
}
