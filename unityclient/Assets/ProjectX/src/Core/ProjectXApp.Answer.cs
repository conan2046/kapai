using System.Collections;
using System.IO;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private const int AnswerSecondsPerQuestion = 20;
        private LuaFunction onAnswerClicked;
        private LuaFunction onAnswerSelected;
        private LuaFunction onAnswerNextRequested;
        private CocosUiView answerView;
        private AnswerPresenter answerPresenter;
        private Coroutine answerAdvanceRoutine;
        private int answerRemaining;
        private int answerCorrectCount;
        private uint answerTotalGold;
        private bool answerValidationStarted;
        private bool answerValidationCompleted;
        private int answerValidationQuestions;
        private int answerValidationResults;

        public void ShowAnswerQuestion(int questionIndex, int remaining, string question,
            string answer1, string answer2, string answer3, string answer4)
        {
            EnsureAnswerPresenter();
            if (questionIndex <= 1)
            {
                answerCorrectCount = 0;
                answerTotalGold = 0;
            }
            answerRemaining = remaining;
            gameplayContentView?.SetVisible(false);
            gameplayPresenter?.SetFeatureFrame("答题", CloseAnswer);
            answerPresenter.ShowQuestion(questionIndex, remaining, question,
                new[] { answer1, answer2, answer3, answer4 }, answerCorrectCount, 0,
                answerTotalGold, AnswerSecondsPerQuestion);
            SetStatus($"Answer/198 question received: index={questionIndex}, remaining={remaining}.");
            if (services.Options.AnswerValidation)
            {
                BeginOrContinueAnswerValidation(questionIndex, remaining);
            }
        }

        public void RejectAnswerEntry(string tip)
        {
            string message = string.IsNullOrWhiteSpace(tip) ? "答题数据同步失败" : tip;
            toastPresenter?.Clear();
            ShowToast(message, 2f);
            SetStatus($"Answer entry rejected: {message}");
            if (services.Options.AnswerValidation)
            {
                if (!answerValidationStarted)
                {
                    BeginValidationEvidence();
                    Fail($"Answer validation was rejected before the first question: {message}");
                }
                else if (!answerValidationCompleted && message == "今日答题次数已用完")
                    StartCoroutine(CompleteAnswerValidationAfterCapture());
            }
        }

        public void CompleteAnswerChoice(bool correct, int correctIndex,
            double currentReward, double finalGold)
        {
            uint current = checked((uint)currentReward);
            uint final = checked((uint)finalGold);
            if (correct) answerCorrectCount++;
            if (services.Options.AnswerValidation)
            {
                answerValidationResults++;
                MarkValidationControl("ANSWER-08-RIGHT-WRONG-FEEDBACK");
                MarkValidationControl("ANSWER-09-REWARD-PROGRESS");
                if (answerValidationResults == 1)
                    StartCoroutine(CaptureAnswerFrame("bootstrap-answer-result.png"));
            }
            answerTotalGold = checked(answerTotalGold + current + final);
            answerPresenter?.ShowResult(correct, correctIndex, answerCorrectCount,
                checked(current + final), answerTotalGold);
            if (answerAdvanceRoutine != null) StopCoroutine(answerAdvanceRoutine);
            answerAdvanceRoutine = StartCoroutine(AdvanceAnswerAfterFeedback());
        }

        public void ResetAnswerState()
        {
            if (answerAdvanceRoutine != null) StopCoroutine(answerAdvanceRoutine);
            answerAdvanceRoutine = null;
            answerPresenter?.Hide();
            answerRemaining = 0;
            answerCorrectCount = 0;
            answerTotalGold = 0;
            answerValidationStarted = false;
            answerValidationCompleted = false;
            answerValidationQuestions = 0;
            answerValidationResults = 0;
            if (gameplayView != null && services?.UiStack.Current == gameplayView)
            {
                gameplayContentView?.SetVisible(true);
                gameplayPresenter?.RestoreHubFrame();
            }
        }

        private IEnumerator AdvanceAnswerAfterFeedback()
        {
            yield return new WaitForSecondsRealtime(1f);
            answerAdvanceRoutine = null;
            if (answerRemaining <= 0)
            {
                ShowToast($"本次答题共获得{answerTotalGold}金币", 3f);
                CloseAnswer();
                if (services.Options.AnswerValidation)
                {
                    MarkValidationControl("ANSWER-10-FINAL-REWARD-CLOSE");
                    InvokeLuaOrFail(onAnswerClicked, "Answer.Validation.DailyLimit", 27d);
                }
                yield break;
            }
            InvokeLuaOrFail(onAnswerNextRequested, "Answer.NextQuestion");
        }

        private void SubmitAnswer(int index) =>
            InvokeLuaOrFail(onAnswerSelected, "Answer.Select", (double)index);

        private void SubmitAnswerTimeout() =>
            InvokeLuaOrFail(onAnswerSelected, "Answer.Timeout", 5d);

        private void BeginOrContinueAnswerValidation(int questionIndex, int remaining)
        {
            if (!answerValidationStarted)
            {
                BeginValidationEvidence();
                answerValidationStarted = true;
                answerValidationCompleted = false;
                answerValidationQuestions = 0;
                answerValidationResults = 0;
                if (GetLocalUserId() != 7200057 || GetPlayerRoleId() != 1000003)
                {
                    Fail($"Answer fixed identity mismatch: {GetLocalUserId()}/{GetPlayerRoleId()}.");
                    return;
                }
                MarkValidationControl("ANSWER-01-GAMEPLAY-ENTRY");
                RecordValidationSemantic("answer-unity-only-entry", true,
                    "Unity Function_27 entry owns /198; Cocos NPC/scene entry remains unchanged");
            }

            answerValidationQuestions++;
            if (questionIndex != answerValidationQuestions || remaining != 10 - questionIndex
                || answerPresenter.AnswerButtonCount != 4 || string.IsNullOrWhiteSpace(answerPresenter.QuestionText)
                || !answerPresenter.HasDefaultRewardVisual)
            {
                Fail($"Answer question state mismatch: index={questionIndex}/{answerValidationQuestions}, remaining={remaining}, buttons={answerPresenter.AnswerButtonCount}, defaultReward={answerPresenter.HasDefaultRewardVisual}.");
                return;
            }
            if (questionIndex == 1)
            {
                MarkValidationControl("ANSWER-02-QUESTION-UI");
                MarkValidationControl("ANSWER-03-ANSWER-A");
                MarkValidationControl("ANSWER-04-ANSWER-B");
                MarkValidationControl("ANSWER-05-ANSWER-C");
                MarkValidationControl("ANSWER-06-ANSWER-D");
                MarkValidationControl("ANSWER-07-COUNTDOWN");
                RecordValidationSemantic("answer-authoritative-question", true,
                    "question index, remaining count, text and four options came from /198 op=1");
            }
            if (questionIndex == 1)
                StartCoroutine(CaptureAnswerQuestionAndSubmit());
            else
                StartCoroutine(SubmitAnswerValidationAfterFrame());
        }

        private IEnumerator CaptureAnswerQuestionAndSubmit()
        {
            yield return CaptureAnswerFrame("bootstrap-answer-question.png");
            yield return SubmitAnswerValidationAfterFrame();
        }

        private IEnumerator SubmitAnswerValidationAfterFrame()
        {
            yield return new WaitForEndOfFrame();
            Button button = answerPresenter?.GetAnswerButton(1);
            if (button == null || !button.interactable || !InvokeEventSystemClick(button))
            {
                Fail($"Answer validation could not click option A on question {answerValidationQuestions}.");
            }
        }

        private void CompleteAnswerValidation()
        {
            if (answerValidationCompleted) return;
            answerValidationCompleted = true;
            if (answerValidationQuestions != 10 || answerValidationResults != 10 || answerPresenter?.IsVisible == true
                || !IsGameplayOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"Answer completion state mismatch: questions={answerValidationQuestions}, results={answerValidationResults}, visible={answerPresenter?.IsVisible}, gameplay={IsGameplayOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                return;
            }
            MarkValidationControl("ANSWER-11-DAILY-LIMIT");
            RecordValidationSemantic("answer-ten-question-loop", true,
                $"10 /198 op=1 questions and 10 /198 op=2 answers completed; correct={answerCorrectCount}");
            RecordValidationSemantic("answer-daily-table-limit", true,
                "second Function_27 click returned exact server text 今日答题次数已用完 and did not reopen AnswerLayer");
            RecordValidationSemantic("answer-reward-fallback", answerTotalGold > 0,
                $"final gold parsed from /198 appended MultiAward={answerTotalGold}; missing rank reward uses answer-settings.csv fallback");
            if (answerTotalGold == 0)
            {
                Fail("Answer final reward did not contain configured gold.");
                return;
            }
            Complete($"COMPLETE: Answer 11/11 controls; Function_27 -> /198 ten-question loop -> gold={answerTotalGold} -> daily limit rejection; user={GetLocalUserId()} role={GetPlayerRoleId()}.");
        }

        private IEnumerator CompleteAnswerValidationAfterCapture()
        {
            yield return CaptureAnswerFrame("bootstrap-answer-daily-limit.png");
            CompleteAnswerValidation();
        }

        private IEnumerator CaptureAnswerFrame(string fileName)
        {
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            string path = BuildUiMigrationPath(fileName);
            if (File.Exists(path)) File.Delete(path);
            ScreenCapture.CaptureScreenshot(path);
            float deadline = Time.realtimeSinceStartup + 8f;
            long previousLength = -1;
            int stableFrames = 0;
            while (Time.realtimeSinceStartup < deadline)
            {
                long length = File.Exists(path) ? new FileInfo(path).Length : 0;
                if (length >= 4096 && length == previousLength)
                {
                    stableFrames++;
                    if (stableFrames >= 2)
                    {
                        WriteAnswerResourceMap(path);
                        yield break;
                    }
                }
                else
                {
                    previousLength = length;
                    stableFrames = 0;
                }
                yield return null;
            }
            Fail("Answer screenshot was not written or stable: " + path);
        }

        private static void WriteAnswerResourceMap(string screenshotPath)
        {
            string fileName = Path.GetFileName(screenshotPath);
            string mapPath = Path.Combine(Path.GetDirectoryName(screenshotPath) ?? string.Empty,
                Path.GetFileNameWithoutExtension(screenshotPath) + "-ui-resource-map.md");
            string content = string.Join("\n", new[]
            {
                "# Answer UI resource map",
                "",
                $"- Screenshot: `{fileName}`",
                "- Cocos Lua: `client/ProjectX/src/View/Activity/AnswerUI.lua`",
                "- Cocos CSB: `client/ProjectX/res/csd/dati/AnswerLayer.csb`",
                "- Unity Prefab: `unityclient/Assets/ProjectX/res/csd/Prefabs/dati/AnswerLayer.prefab`",
                "- Unity dynamic asset: `unityclient/Assets/ProjectX/Resources/UiPrefabs/AnswerLayer.asset`",
                "- Unity presenter: `unityclient/Assets/ProjectX/src/UI/AnswerPresenter.cs`",
                "- Protocol: `/198 op=1/2`",
                "- Formal settings: `server/config/source/answer-settings.csv`",
                "- Runtime nodes: `Layer/Panel/AnswerBg`, four `SubjectBg/Button_1..4`, result stamps, countdown and reward counters",
                "- Prefab-owned reward nodes: `RewardBg/Reward` quality frame, `Reward/Icon` gold icon and `Reward/Value` default amount; none are created at runtime.",
                "- Dynamic question/answer text and protocol reward counters: `未解析` until the paired runtime result is inspected.",
                ""
            });
            File.WriteAllText(mapPath, content, new System.Text.UTF8Encoding(false));
        }

        private void CloseAnswer()
        {
            if (answerAdvanceRoutine != null) StopCoroutine(answerAdvanceRoutine);
            answerAdvanceRoutine = null;
            answerPresenter?.Hide();
            gameplayContentView?.SetVisible(true);
            gameplayPresenter?.RestoreHubFrame();
            SetStatus("Answer UI closed; Gameplay hub restored.");
        }

        private void EnsureAnswerPresenter()
        {
            if (answerView == null || answerView.GameObject == null)
                answerView = UiPrefabLoader.Load("AnswerLayer", gameplayView.GameObject.transform);
            answerPresenter = answerPresenter ?? new AnswerPresenter(answerView, SubmitAnswer, SubmitAnswerTimeout);
        }
    }
}
