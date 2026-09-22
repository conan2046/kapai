using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;
using UnityEngine.UI;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void ShowXunBao(){EnsureXunBaoPresenter();if(services.UiStack.Current!=xunBaoView)services.UiStack.Push(xunBaoView);SetStatus("XunBao current UI active; awaiting /319 op=31.");}
        public void SetXunBaoState(int remaining,double recoverySeconds){services.XunBao.Replace(checked((ushort)remaining),checked((uint)recoverySeconds));}
        public void SetXunBaoOperationResult(bool succeeded,string message,double remaining,double recoverySeconds)
        {
            services.XunBao.SetOperationResult(succeeded,message,remaining>=0?(ushort?)checked((ushort)remaining):null,recoverySeconds>=0?(uint?)checked((uint)recoverySeconds):null);
            if (!string.IsNullOrWhiteSpace(message)) ShowToast(message, succeeded ? 2f : 3f);
        }
        public void PlayXunBaoComposeFeedback()
        {
            EnsureXunBaoPresenter();
            StartCoroutine(ShowXunBaoComposePopupAfterTimeline(xunBaoPresenter.PlayComposeFeedback()));
        }
        private IEnumerator ShowXunBaoComposePopupAfterTimeline(bool timelineStarted)
        {
            if (timelineStarted)
                while (xunBaoPresenter != null && xunBaoPresenter.IsAnimationPlaying) yield return null;
            EnsureXunBaoPopupPresenter();
            EquipmentDefinition definition = services.EquipmentCatalog.GetFaBao(xunBaoPresenter.SelectedFaBaoId);
            if (definition != null) xunBaoPopupPresenter.ShowCompose(definition);
            else ShowToast("法宝合成成功",2f);
        }
        public void BeginXunBaoRewardUpdate()
        {
            pendingXunBaoRewards.Clear();
            pendingXunBaoRewardBatches.Clear();
        }
        public void BeginXunBaoRewardBatch() => pendingXunBaoRewards.Clear();
        public void AddXunBaoReward(int type, double id, double amount)
        {
            uint rewardId = checked((uint)id);
            uint rewardAmount = checked((uint)amount);
            if (rewardAmount == 0) return;
            (int Type, uint Id) key = (type, rewardId);
            RewardRecord described = services.ShopCatalog.DescribeReward(type, checked((int)rewardId), rewardAmount);
            if (pendingXunBaoRewards.TryGetValue(key, out RewardRecord current))
                described = new RewardRecord(described.Type, described.Id, checked(current.Amount + rewardAmount),
                    described.Name, described.Picture, described.Quality);
            pendingXunBaoRewards[key] = described;
        }
        public void EndXunBaoRewardBatch()
        {
            pendingXunBaoRewardBatches.Add(pendingXunBaoRewards.Values.ToArray());
            pendingXunBaoRewards.Clear();
        }
        public void EndXunBaoRewardUpdate(int searchCount, int resultMode, double faBaoId, double suiId)
        {
            if (pendingXunBaoRewards.Count > 0) EndXunBaoRewardBatch();
            if (searchCount <= 0 || pendingXunBaoRewardBatches.Count == 0)
            {
                pendingXunBaoRewards.Clear();
                pendingXunBaoRewardBatches.Clear();
                return;
            }
            if (resultMode == 2)
            {
                EnsureXunBaoComposeAllPresenter();
                xunBaoComposeAllPresenter.Show(pendingXunBaoRewardBatches.SelectMany(value => value).ToArray());
            }
            else
            {
                EnsureXunBaoResultPresenter();
                bool continueToToken = ShouldOpenTokenAfterXunBaoResult(resultMode == 1,
                    checked((int)faBaoId), checked((int)suiId));
                xunBaoResultPresenter.Show(pendingXunBaoRewardBatches.ToArray(), continueToToken,
                    OpenXunBaoSearchTokenBag);
            }
            int rewardCount = pendingXunBaoRewardBatches.Sum(value => value.Count);
            pendingXunBaoRewards.Clear();
            pendingXunBaoRewardBatches.Clear();
            SetStatus($"XunBao source result active: searches={searchCount}, rewards={rewardCount}.");
        }
        public void CompleteXunBaoValidation(){if(xunBaoValidationRunning)return;xunBaoValidationRunning=true;StartCoroutine(CompleteXunBaoValidationAfterLayout());}
        private IEnumerator CaptureXunBaoFrame(string fileName)
        {
            loadingPresenter?.Clear();
            loadingView?.SetVisible(false);
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
                        WriteXunBaoResourceMap(path);
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
            throw new IOException($"XunBao screenshot was not written or stable: {path}");
        }

        private static void WriteXunBaoResourceMap(string screenshotPath)
        {
            string fileName = Path.GetFileName(screenshotPath);
            string cocosLua = "client/ProjectX/src/View/WanFa/XunBaoMainUI.lua";
            string cocosCsb = "client/ProjectX/res/csd/wanfa/XunbaoLayer.csb";
            string unityPrefab = "unityclient/Assets/ProjectX/res/csd/Prefabs/wanfa/XunbaoLayer.prefab";
            string unityPresenter = "unityclient/Assets/ProjectX/src/UI/XunBaoPresenter.cs";
            string dynamicNote = "法宝、碎片、图标和数量由同轮权威状态与正式配置解析。";
            if (fileName.Contains("compose-all", StringComparison.Ordinal))
            {
                cocosLua = "client/ProjectX/src/View/Common/SaoDangUI.lua";
                cocosCsb = "client/ProjectX/res/csd/common/saodang.csb";
                unityPrefab = "unityclient/Assets/ProjectX/res/csd/Prefabs/common/saodang.prefab";
                unityPresenter = "unityclient/Assets/ProjectX/src/UI/XunBaoOverlayPresenter.cs::XunBaoComposeAllPresenter";
                dynamicNote = "动态奖励具体ID：未解析；以同轮 xunbao-latest.json 与服务器 op36 奖励批次为准。";
            }
            else if (fileName.Contains("search-result", StringComparison.Ordinal)
                     || fileName.Contains("search-all-result", StringComparison.Ordinal))
            {
                cocosLua = "client/ProjectX/src/View/WanFa/XunBaoResultUI.lua";
                cocosCsb = "client/ProjectX/res/csd/wanfa/Xunbao_souxunLayer.csb";
                unityPrefab = "unityclient/Assets/ProjectX/res/csd/Prefabs/wanfa/Xunbao_souxunLayer.prefab";
                unityPresenter = "unityclient/Assets/ProjectX/src/UI/XunBaoOverlayPresenter.cs::XunBaoResultPresenter";
                dynamicNote = "动态奖励具体ID：未解析；以同轮 xunbao-latest.json 与服务器 op28/op29 奖励批次为准。";
            }
            else if (fileName.Contains("task", StringComparison.Ordinal)
                     || fileName.Contains("compose", StringComparison.Ordinal)
                     || fileName.Contains("search-confirm", StringComparison.Ordinal))
            {
                cocosLua = "client/ProjectX/src/View/WanFa/XunBaoPopUI.lua";
                cocosCsb = "client/ProjectX/res/csd/wanfa/Xunbao_popupLayer.csb";
                unityPrefab = "unityclient/Assets/ProjectX/res/csd/Prefabs/wanfa/Xunbao_popupLayer.prefab";
                unityPresenter = "unityclient/Assets/ProjectX/src/UI/XunBaoOverlayPresenter.cs::XunBaoPopupPresenter";
            }
            string mapPath = Path.Combine(Path.GetDirectoryName(screenshotPath) ?? string.Empty,
                Path.GetFileNameWithoutExtension(screenshotPath) + "-ui-resource-map.md");
            string content = string.Join("\n", new[]
            {
                "# XunBao UI resource map",
                "",
                $"- Screenshot: `{fileName}`",
                $"- Cocos Lua: `{cocosLua}`",
                $"- Cocos CSB: `{cocosCsb}`",
                $"- Unity Prefab: `{unityPrefab}`",
                $"- Unity Presenter: `{unityPresenter}`",
                "- Protocol: `/319 op=28/29/30/31/36`",
                "- Formal tables: `concept/data/excel/xml配置表/新表/fabao_looting.xlsx`, `item.xlsx`",
                "- Runtime configs: `server/config/json/fabao_looting.json`, `hecheng.json`, `fabao.json`, `item.json`",
                $"- Dynamic mapping: {dynamicNote}",
                ""
            });
            File.WriteAllText(mapPath, content, new System.Text.UTF8Encoding(false));
        }
        private IEnumerator CompleteXunBaoValidationAfterLayout()
        {
            toastPresenter?.Clear();
            BeginValidationEvidence();
            EnsureXunBaoPresenter();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            float settleDeadline = Time.realtimeSinceStartup + 10f;
            while (services.ProtocolRegistry.PendingCount != 0 && Time.realtimeSinceStartup < settleDeadline)
                yield return null;
            if (!IsXunBaoOpen || !services.XunBao.HasAuthoritativeResponse || !IsXunBaoAuthoritativeVisible
                || xunBaoPresenter.ActionBindingCount < 7 || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"XunBao state mismatch: open={IsXunBaoOpen}, authoritative={services.XunBao.HasAuthoritativeResponse}, visible={IsXunBaoAuthoritativeVisible}, actions={xunBaoPresenter.ActionBindingCount}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            if (xunBaoPresenter.VisibleTreasureCount < 3)
            {
                Fail($"XunBao dynamic search list is incomplete: visible={xunBaoPresenter.VisibleTreasureCount}, expected at least 3.");
                yield break;
            }
            if (xunBaoPresenter.RemainingText != services.XunBao.Remaining.ToString())
            {
                Fail($"XunBao remaining count is not authoritative: ui={xunBaoPresenter.RemainingText}, store={services.XunBao.Remaining}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-03-REMAINING-TIMES");
            string expectedRecovery = services.XunBao.RecoverySeconds > 0 ? "恢复倒计时" : "搜索次数已满";
            if (!xunBaoPresenter.RecoveryText.Contains(expectedRecovery, StringComparison.Ordinal))
            {
                Fail($"XunBao recovery text mismatch: ui={xunBaoPresenter.RecoveryText}, expected={expectedRecovery}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-04-RECOVERY-COUNTDOWN");
            if (xunBaoPresenter.VisibleQualityPanelCount != 1)
            {
                Fail($"XunBao must render exactly one quality panel, actual={xunBaoPresenter.VisibleQualityPanelCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-19-DYNAMIC-QUALITY-PANELS");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-main.png");

            Button help = xunBaoPresenter.GetButton("Panel/Title/TitleName/btn_help");
            if (!InvokeEventSystemRaycastClick(help) || errorPresenter?.IsVisible != true)
            {
                Fail("XunBao help button did not accept a real EventSystem raycast click.");
                yield break;
            }
            MarkValidationControl("XUNBAO-06-HELP");
            errorPresenter.Hide();

            Button staminaAdd = xunBaoPresenter.GetButton("Panel/GoldCheck/GoldIcon1/AddBtn");
            if (!InvokeEventSystemRaycastClick(staminaAdd))
            {
                Fail("XunBao stamina add did not accept a real EventSystem raycast click.");
                yield break;
            }
            MarkValidationControl("XUNBAO-07-STAMINA-ADD");
            toastPresenter?.Clear();
            yield return null;
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();

            Button task = xunBaoPresenter.GetButton("Panel/XunbaoBg/Btn_1");
            if (!InvokeEventSystemRaycastClick(task) || xunBaoPopupPresenter?.Mode != 3)
            {
                Fail("XunBao task entry did not open Xunbao_popupLayer mode=3 through a real raycast click.");
                yield break;
            }
            MarkValidationControl("XUNBAO-10-TASK-ENTRY");
            float taskDeadline = Time.realtimeSinceStartup + 12f;
            while ((services.ProtocolRegistry.PendingCount != 0 || services.Tasks.XunBaoCount == 0
                    || xunBaoPopupPresenter.RenderedTaskCount == 0)
                   && Time.realtimeSinceStartup < taskDeadline) yield return null;
            if (services.ProtocolRegistry.PendingCount != 0 || services.Tasks.XunBaoCount == 0
                || xunBaoPopupPresenter.RenderedTaskCount == 0
                || xunBaoPopupPresenter.RenderedRewardCount == 0)
            {
                Fail($"XunBao /37 type=3 reward list stayed empty: records={services.Tasks.XunBaoCount}, rows={xunBaoPopupPresenter.RenderedTaskCount}, rewards={xunBaoPopupPresenter.RenderedRewardCount}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-20-TASK-REWARD-LIST");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-task.png");
            Button taskClaim = xunBaoPopupPresenter.GetFirstClaimableControl(out int claimTaskId);
            if (taskClaim == null || !InvokeEventSystemRaycastClick(taskClaim))
            {
                Fail("XunBao formal task fixture exposed no claimable real Button.");
                yield break;
            }
            taskDeadline = Time.realtimeSinceStartup + 12f;
            while ((!services.Tasks.TryGet(3, claimTaskId, out TaskRecord claimedTask)
                    || claimedTask.State != 2 || services.ProtocolRegistry.PendingCount != 0
                    || rewardPresenter?.IsVisible != true)
                   && Time.realtimeSinceStartup < taskDeadline) yield return null;
            if (!services.Tasks.TryGet(3, claimTaskId, out TaskRecord claimedTaskResult)
                || claimedTaskResult.State != 2 || services.Rewards.Count == 0
                || rewardPresenter?.IsVisible != true)
            {
                Fail($"XunBao /37 type=3 claim did not settle: task={claimTaskId}, state={claimedTaskResult.State}, rewards={services.Rewards.Count}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-21-TASK-CLAIM");
            rewardPresenter.Hide();
            if (!InvokeEventSystemRaycastClick(xunBaoPopupPresenter.TaskCloseControl) || xunBaoPopupPresenter.IsVisible)
            {
                Fail("XunBao task popup close did not accept a real EventSystem raycast click.");
                yield break;
            }

            Button premium = xunBaoPresenter.GetButton("Panel/GoldCheck/GoldIcon4/AddBtn");
            bool premiumDisabled = xunBaoPresenter.IsButtonDisabled("Panel/GoldCheck/GoldIcon4/AddBtn")
                || (premium != null && !premium.gameObject.activeInHierarchy);
            if (!premiumDisabled)
            {
                Fail($"XunBao premium add must remain hidden/disabled: found={premium != null}, active={premium?.gameObject.activeInHierarchy}, interactable={premium?.interactable}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-09-PREMIUM-ADD-DISABLED");

            Button addTimes = xunBaoPresenter.GetButton("Panel/XunbaoBg/TimesBg/AddBtn");
            if (!InvokeEventSystemRaycastClick(addTimes))
            {
                Fail("XunBao search-count add did not accept a real EventSystem raycast click.");
                yield break;
            }
            float tokenBagDeadline = Time.realtimeSinceStartup + 15f;
            while ((!IsBagOpen || bagPresenter?.SelectedItemId != 402 || services.ProtocolRegistry.PendingCount > 0)
                && Time.realtimeSinceStartup < tokenBagDeadline)
                yield return null;
            if (!IsBagOpen || bagPresenter?.SelectedItemId != 402 || services.ProtocolRegistry.PendingCount > 0)
            {
                Fail($"XunBao search-count add did not open/select authoritative item 402: bag={IsBagOpen}, selected={bagPresenter?.SelectedItemId}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-05-ADD-TIMES");
            if (!HandleBack() || !IsXunBaoOpen)
            {
                Fail("XunBao validation could not return from the item-402 bag boundary.");
                yield break;
            }

            Button close = xunBaoPresenter.GetButton("Panel/Title/CloseBtn");
            if (!InvokeEventSystemRaycastClick(close) || IsXunBaoOpen)
            {
                Fail("XunBao close did not accept a real EventSystem raycast click.");
                yield break;
            }
            MarkValidationControl("XUNBAO-02-CLOSE");
            EnsureGameplayPresenter();
            Canvas.ForceUpdateCanvases();
            yield return new WaitForEndOfFrame();
            if (!InvokeEventSystemRaycastClick(gameplayPresenter.GetEnterButton(9)))
            {
                Fail("XunBao gameplay entry did not accept a real EventSystem raycast click.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 10f;
            while ((!IsXunBaoOpen || services.ProtocolRegistry.PendingCount != 0)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            if (!IsXunBaoOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail("XunBao gameplay entry did not complete /319 op=31.");
                yield break;
            }
            MarkValidationControl("XUNBAO-01-ENTRY");

            Button alternateCard = xunBaoPresenter.GetTreasureCardButton(1);
            if (alternateCard != null && xunBaoPresenter.SelectedFaBaoId == 1001)
            {
                if (!InvokeEventSystemRaycastClick(alternateCard))
                {
                    Fail("XunBao alternate dynamic card did not accept a real raycast click.");
                    yield break;
                }
                while (xunBaoPresenter.IsAnimationPlaying) yield return null;
            }
            Button blueCard = xunBaoPresenter.GetTreasureCardButtonByFaBaoId(1001);
            if (blueCard == null || !InvokeEventSystemRaycastClick(blueCard))
            {
                Fail("XunBao formal target 1001 card did not accept a real EventSystem raycast click.");
                yield break;
            }
            while (xunBaoPresenter.IsAnimationPlaying) yield return null;
            if (xunBaoPresenter.SelectedFaBaoId != 1001
                || !xunBaoPresenter.CurrentAnimationClip.EndsWith("Open", StringComparison.Ordinal))
            {
                Fail($"XunBao card selection mismatch: selected={xunBaoPresenter.SelectedFaBaoId}, clip={xunBaoPresenter.CurrentAnimationClip}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-11-TREASURE-CARD");

            ushort remainingBeforeSearch = services.XunBao.Remaining;
            string messageBeforeSearch = services.XunBao.LastMessage;
            if (!InvokeEventSystemRaycastClick(xunBaoPresenter.GetFragmentButton(1)))
            {
                Fail("XunBao fragment source did not accept a real EventSystem raycast click.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 12f;
            while ((services.ProtocolRegistry.PendingCount != 0
                    || string.Equals(services.XunBao.LastMessage, messageBeforeSearch, StringComparison.Ordinal)
                    || xunBaoResultPresenter?.IsVisible != true
                    || !xunBaoResultPresenter.IsSequenceComplete)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            if (!services.XunBao.LastOperationSucceeded || services.XunBao.Remaining >= remainingBeforeSearch
                || xunBaoResultPresenter?.IsVisible != true || !xunBaoResultPresenter.IsSequenceComplete)
            {
                Fail($"XunBao op28/result mismatch: success={services.XunBao.LastOperationSucceeded}, remaining={remainingBeforeSearch}->{services.XunBao.Remaining}, result={xunBaoResultPresenter?.IsVisible}, batches={xunBaoResultPresenter?.RenderedBatchCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-12-FRAGMENT-SOURCE");
            MarkValidationControl("XUNBAO-17-SEARCH-RESULT");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-search-result.png");
            if (!InvokeEventSystemRaycastClick(xunBaoResultPresenter.CloseControl))
            {
                Fail("XunBao result close did not accept a real EventSystem raycast click.");
                yield break;
            }

            Button composeCard = xunBaoPresenter.GetTreasureCardButtonByFaBaoId(1002);
            if (composeCard == null || !InvokeEventSystemRaycastClick(composeCard))
            {
                Fail("XunBao compose fixture target 1002 was not selectable by real raycast.");
                yield break;
            }
            while (xunBaoPresenter.IsAnimationPlaying) yield return null;
            string messageBeforeCompose = services.XunBao.LastMessage;
            if (!InvokeEventSystemRaycastClick(xunBaoPresenter.ComposeButton))
            {
                Fail("XunBao single compose did not accept a real EventSystem raycast click.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 12f;
            while ((services.ProtocolRegistry.PendingCount != 0
                    || string.Equals(services.XunBao.LastMessage, messageBeforeCompose, StringComparison.Ordinal)
                    || xunBaoPopupPresenter?.Mode != 1)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            string composeToast = toastPresenter?.CurrentText ?? string.Empty;
            if (!services.XunBao.LastOperationSucceeded || xunBaoPopupPresenter?.Mode != 1
                || !string.Equals(xunBaoPopupPresenter.ComposeAttributeText, "攻击+400", StringComparison.Ordinal)
                || !xunBaoPopupPresenter.ComposeAttributeFits
                || xunBaoPresenter.RecoveryText.Contains("[c") || xunBaoPresenter.RecoveryText.Contains("[/c")
                || composeToast.Contains("[c") || composeToast.Contains("[/c")
                || composeToast.Contains("�") || !composeToast.Contains("获得法宝：")
                || !composeToast.Contains("蓝色法宝2") || !composeToast.Contains("<color=#FFDA0E>"))
            {
                Fail($"XunBao op30/compose feedback mismatch: success={services.XunBao.LastOperationSucceeded}, popup={xunBaoPopupPresenter?.Mode}, attribute={xunBaoPopupPresenter?.ComposeAttributeText}, recovery={xunBaoPresenter.RecoveryText}, toast={composeToast}, clip={xunBaoPresenter.CurrentAnimationClip}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-14-SINGLE-COMPOSE");
            MarkValidationControl("XUNBAO-18-COMPOSE-FEEDBACK");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-compose.png");
            if (!InvokeEventSystemRaycastClick(xunBaoPopupPresenter.ComposeCloseControl))
            {
                Fail("XunBao compose popup close did not accept a real EventSystem raycast click.");
                yield break;
            }

            string messageBeforeComposeAll = services.XunBao.LastMessage;
            if (xunBaoPresenter.ComposeAllButton == null
                || !xunBaoPresenter.ComposeAllButton.gameObject.activeInHierarchy
                || !InvokeEventSystemRaycastClick(xunBaoPresenter.ComposeAllButton))
            {
                Fail("XunBao one-key compose fixture did not expose a real enabled source button after single compose.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 12f;
            while ((services.ProtocolRegistry.PendingCount != 0
                    || string.Equals(services.XunBao.LastMessage, messageBeforeComposeAll, StringComparison.Ordinal)
                    || xunBaoComposeAllPresenter?.IsVisible != true
                    || xunBaoComposeAllPresenter.IsAnimationPlaying)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            if (!services.XunBao.LastOperationSucceeded || xunBaoComposeAllPresenter?.IsVisible != true
                || xunBaoComposeAllPresenter.RenderedRewardCount < 1
                || xunBaoComposeAllPresenter.IsAnimationPlaying)
            {
                Fail("XunBao op36 did not produce its authoritative source SaoDang reward surface.");
                yield break;
            }
            MarkValidationControl("XUNBAO-15-ONEKEY-COMPOSE");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-compose-all.png");
            if (!InvokeEventSystemRaycastClick(xunBaoComposeAllPresenter.CloseControl))
            {
                Fail("XunBao source SaoDang reward close did not accept a real EventSystem raycast click.");
                yield break;
            }

            if (!InvokeEventSystemRaycastClick(xunBaoPresenter.OneKeySearchButton)
                || xunBaoPopupPresenter?.Mode != 2)
            {
                Fail("XunBao one-key search did not open source confirmation mode=2 through a real raycast click.");
                yield break;
            }
            MarkValidationControl("XUNBAO-13-ONEKEY-SEARCH");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-search-confirm.png");
            if (!InvokeEventSystemRaycastClick(xunBaoPopupPresenter.SuppressControl)
                || !xunBaoPopupPresenter.SuppressSearchConfirmation
                || !InvokeEventSystemRaycastClick(xunBaoPopupPresenter.AutoUseControl)
                || xunBaoPopupPresenter.AutoUseSearchToken
                || !InvokeEventSystemRaycastClick(xunBaoPopupPresenter.AutoUseControl)
                || !xunBaoPopupPresenter.AutoUseSearchToken
                || !InvokeEventSystemRaycastClick(xunBaoPopupPresenter.ConfirmControl))
            {
                Fail("XunBao source confirmation toggles/confirm did not accept real EventSystem raycast clicks.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 20f;
            while ((services.ProtocolRegistry.PendingCount != 0 || xunBaoResultPresenter?.IsVisible != true
                    || !xunBaoResultPresenter.IsSequenceComplete)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            if (!services.XunBao.LastOperationSucceeded || xunBaoResultPresenter?.IsVisible != true
                || !xunBaoResultPresenter.IsSequenceComplete)
            {
                Fail("XunBao op29 did not produce the source progressive result surface.");
                yield break;
            }
            MarkValidationControl("XUNBAO-16-AUTO-SEARCH-CONFIRM");
            yield return CaptureXunBaoFrame("bootstrap-xunbao-search-all-result.png");
            if (!InvokeEventSystemRaycastClick(xunBaoResultPresenter.CloseControl))
            {
                Fail("XunBao one-key result close did not accept a real EventSystem raycast click.");
                yield break;
            }
            if (IsBagOpen && (!HandleBack() || !IsXunBaoOpen))
            {
                Fail("XunBao one-key result continuation did not return from the item-402 bag boundary.");
                yield break;
            }

            Button goldAdd = xunBaoPresenter.GetButton("Panel/GoldCheck/GoldIcon3/AddBtn");
            lastGameplayBoundaryId = 0;
            if (!InvokeEventSystemRaycastClick(goldAdd) || lastGameplayBoundaryId != 13)
            {
                Fail($"XunBao gold add did not route the formal shop boundary: boundary={lastGameplayBoundaryId}.");
                yield break;
            }
            settleDeadline = Time.realtimeSinceStartup + 12f;
            while ((!IsShopOpen || services.ProtocolRegistry.PendingCount != 0)
                   && Time.realtimeSinceStartup < settleDeadline) yield return null;
            if (!IsShopOpen || services.ProtocolRegistry.PendingCount != 0)
            {
                Fail($"XunBao gold add shop boundary did not settle: shop={IsShopOpen}, pending={services.ProtocolRegistry.PendingCount}.");
                yield break;
            }
            MarkValidationControl("XUNBAO-08-GOLD-ADD");
            if (!HandleBack() || !IsXunBaoOpen)
            {
                Fail("XunBao validation could not return from the formal gold-shop boundary.");
                yield break;
            }

            RecordValidationSemantic("xunbao-authoritative-state", true,
                $"user={GetLocalUserId()} role={GetPlayerRoleId()} remaining={services.XunBao.Remaining} seconds={services.XunBao.RecoverySeconds}");
            RecordValidationSemantic("xunbao-write-bindings", true,
                $"op28/29/30/36 completed through source Button raycasts; bindings={xunBaoPresenter.ActionBindingCount}");
            RecordValidationSemantic("xunbao-dynamic-quality-and-fragment-closure", true,
                $"visibleSearches={xunBaoPresenter.VisibleTreasureCount}, selectedFaBao={xunBaoPresenter.SelectedFaBaoId}, quality panels and fragment slots rendered from hecheng.type=8");
            RecordValidationSemantic("xunbao-task-reward-authority", true,
                $"/37 type=3 records={services.Tasks.XunBaoCount}, renderedRows={xunBaoPopupPresenter.RenderedTaskCount}, renderedRewards={xunBaoPopupPresenter.RenderedRewardCount}");
            RecordValidationSemantic("xunbao-control-matrix-21", validationControlIds.Count == 21,
                $"validated={validationControlIds.Count}/21");
            RecordValidationSemantic("xunbao-source-audit-21", true,
                "each control was marked only after its own state/raycast/protocol/result assertion");
            if (validationControlIds.Count != 21)
            {
                Fail($"XunBao control coverage mismatch: {validationControlIds.Count}/21.");
                yield break;
            }
            yield return CaptureXunBaoFrame("bootstrap-xunbao.png");
            Complete($"COMPLETE: XunBao 21/21 controls; /319 op31 remaining={services.XunBao.Remaining}, seconds={services.XunBao.RecoverySeconds}; /37 type3 list+claim; op28/29/30/36 bound; user={GetLocalUserId()} role={GetPlayerRoleId()}");
        }


        private void EnsureXunBaoPresenter(){xunBaoView=xunBaoView??services.UiRouter.FindBySource("wanfa/XunbaoLayer");if(xunBaoView==null)throw new InvalidOperationException("Current XunBao imported CocosUiBinding was not found: wanfa/XunbaoLayer.");xunBaoPresenter=xunBaoPresenter??new XunBaoPresenter(xunBaoView,services.XunBao,services.Bag,services.Resources,services.EquipmentCatalog,()=>HandleBack(),(faBao,sui)=>InvokeLuaOrFail(onXunBaoSearch,"XunBao.Search",(double)faBao,(double)sui),ShowXunBaoSearchConfirmation,faBao=>InvokeLuaOrFail(onXunBaoCompose,"XunBao.Compose",(double)faBao),()=>InvokeLuaOrFail(onXunBaoComposeAll,"XunBao.ComposeAll"),OpenXunBaoSearchTokenBag,()=>{EnsureErrorPresenter();errorPresenter.ShowHelp("1、法宝搜索消耗搜索次数获得碎片；\n2、收集齐所需碎片后可合成法宝；\n3、次数不足时可使用搜宝令补充。");},()=>{SetStatus("XunBao stamina boundary -> UseItemUI(500,1)");ShowToast("体力补充入口属于道具使用功能",2f);},()=>{lastGameplayBoundaryId=13;HandleCommerceRoute(13);},ShowXunBaoTaskBoundary,message=>ShowToast(message,3f));}

        private void EnsureXunBaoResultPresenter()
        {
            xunBaoResultView = xunBaoResultView ?? services.UiRouter.FindBySource("wanfa/Xunbao_souxunLayer");
            if (xunBaoResultView == null)
                throw new InvalidOperationException("Current XunBao result CocosUiBinding was not found: wanfa/Xunbao_souxunLayer.");
            xunBaoPopupView = xunBaoPopupView ?? services.UiRouter.FindBySource("wanfa/Xunbao_popupLayer");
            GameObject closeTemplate = xunBaoPopupView?.Binding.Find("Layer/Rewards/Popup/Btn_close");
            xunBaoResultPresenter = xunBaoResultPresenter
                ?? new XunBaoResultPresenter(xunBaoResultView, services.Resources, closeTemplate);
        }

        private void EnsureXunBaoPopupPresenter()
        {
            xunBaoPopupView = xunBaoPopupView ?? services.UiRouter.FindBySource("wanfa/Xunbao_popupLayer");
            if (xunBaoPopupView == null)
                throw new InvalidOperationException("Current XunBao popup CocosUiBinding was not found: wanfa/Xunbao_popupLayer.");
            xunBaoPopupPresenter = xunBaoPopupPresenter
                ?? new XunBaoPopupPresenter(xunBaoPopupView, services.Resources, services.Tasks,
                    item => InvokeLuaOrFail(onTaskClaimClicked, "XunBao.TaskClaim", item.Type, item.Id));
        }

        private void EnsureXunBaoComposeAllPresenter()
        {
            xunBaoComposeAllView = xunBaoComposeAllView ?? services.UiRouter.FindBySource("common/saodang");
            if (xunBaoComposeAllView == null)
                throw new InvalidOperationException("Current XunBao compose-all CocosUiBinding was not found: common/saodang.");
            xunBaoComposeAllPresenter = xunBaoComposeAllPresenter
                ?? new XunBaoComposeAllPresenter(xunBaoComposeAllView, services.Resources);
        }

        private void ShowXunBaoSearchConfirmation(ushort faBaoId)
        {
            EnsureXunBaoPopupPresenter();
            EquipmentDefinition definition = services.EquipmentCatalog.GetFaBao(faBaoId);
            if (definition == null)
            {
                ShowToast($"法宝配置缺失：{faBaoId}", 3f);
                return;
            }
            if (xunBaoPopupPresenter.SuppressSearchConfirmation)
            {
                InvokeLuaOrFail(onXunBaoSearchAll, "XunBao.SearchAll", (double)faBaoId,
                    xunBaoPopupPresenter.AutoUseSearchToken ? 1d : 0d);
                return;
            }
            xunBaoPopupPresenter.ShowSearchConfirm(definition,
                autoUse => InvokeLuaOrFail(onXunBaoSearchAll, "XunBao.SearchAll", (double)faBaoId,
                    autoUse ? 1d : 0d));
        }

        private void ShowXunBaoTaskBoundary()
        {
            EnsureXunBaoPopupPresenter();
            xunBaoPopupPresenter.ShowTaskBoundary();
            InvokeLuaOrFail(onXunBaoTaskClicked, "XunBao.TaskList");
            SetStatus("XunBao task entry opened; /37 op=1 type=3 requested.");
        }

        private bool ShouldOpenTokenAfterXunBaoResult(bool oneKey, int faBaoId, int suiId)
        {
            if (!oneKey) return suiId > 0 && services.Bag.GetTotalQuantityByItemId(suiId) < 1;
            FaBaoSearchDefinition search = services.EquipmentCatalog.GetFaBaoSearches()
                .FirstOrDefault(value => value.FaBaoId == faBaoId);
            if (search?.FragmentIds == null || search.FragmentCosts == null) return false;
            for (int index = 0; index < Math.Min(search.FragmentIds.Length, search.FragmentCosts.Length); index++)
                if (services.Bag.GetTotalQuantityByItemId(search.FragmentIds[index]) < search.FragmentCosts[index])
                    return true;
            return false;
        }

        public void OpenXunBaoSearchTokenBag()
        {
            services.XunBao.SetOperationResult(false, "搜索次数不足，请在背包使用搜宝令");
            EnsureBagPresenter();
            pendingBagSelectionItemId = 402;
            InvokeLuaOrFail(onXunBaoSearchTokenBagRequested, "XunBao.SearchTokenPackageSnapshot");
        }
    }
}
