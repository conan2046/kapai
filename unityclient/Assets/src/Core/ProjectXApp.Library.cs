using System;
using System.Linq;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using ProjectX.Data;
using ProjectX.Network;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        private UnityUiView libraryView;
        private LibraryScreen libraryScreen;
        private LibraryCatalogData libraryCatalog;
        private LibraryEnvelope libraryState;
        private Coroutine libraryPolling;
        private string libraryPending, libraryReportedError;
        private int libraryPendingOperation, librarySession;
        private float libraryDeadline, libraryNextRead;
        public bool IsLibraryOpen => libraryView?.GameObject.activeInHierarchy == true && services?.UiStack.Current == libraryView;
        private void ShowLibrary()
        {
            if (libraryView == null || !libraryView.IsAlive)
            {
                libraryCatalog = new LibraryCatalogData();
                libraryView = services.UiRouter.FindByKey("DongFuLibrary", true);
                libraryScreen = libraryView.GameObject.GetComponent<LibraryScreen>();
                if (libraryScreen == null) throw new InvalidOperationException("藏书阁预制体缺少页面绑定");
                libraryScreen.Bind(libraryCatalog, services.Resources.LoadSprite);
                libraryScreen.CloseRequested += CloseLibrary;
                libraryScreen.BecameVisible += RestoreLibraryFrame;
                libraryScreen.ActivationRequested += ConfirmLibraryReward;
                libraryScreen.BookRequested += ShowLibraryBook;
                libraryScreen.AttributesRequested += ShowLibraryAttributes;
                dongFuPages[4] = libraryView;
            }
            libraryScreen.ResetSelection(); dongFuSubView = libraryView; dongFuBuilding = 4;
            if (services.UiStack.Current != libraryView) services.UiStack.Push(libraryView);
            RestoreLibraryFrame();
        }
        private void RestoreLibraryFrame()
        {
            ConfigureDongFuSharedFrame(libraryView, libraryScreen.Back, ShowLibraryHelp);
            oneLevelFrameView.FindNode("Layer/Panel_12/Title/TitleName").GetComponent<UnityEngine.UI.Text>().text = "藏书阁";
            libraryPending = null; librarySession = services.Network.SessionVersion;
            libraryScreen.Loading(); libraryNextRead = Time.realtimeSinceStartup;
            if (libraryPolling != null) StopCoroutine(libraryPolling);
            libraryPolling = StartCoroutine(PollLibrary());
        }
        private void CloseLibrary()
        {
            if (services.UiStack.Current == libraryView) services.UiStack.Pop(); else libraryView?.SetVisible(false);
            libraryPending = null;
            if (libraryPolling != null) { StopCoroutine(libraryPolling); libraryPolling = null; }
            if (IsDongFuOpen) RestoreDongFuFrame();
        }
        private void ShowLibraryHelp()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowHelp("书籍首次获得即登记收藏。\n激活单本消耗1本，属性永久加成上阵神将。\n多本、整套奖励按已激活书目判断，不再扣书。\n已激活书籍再次获得时，按道具售价自动出售。\n书籍可从世界章节、扫荡和封神列传胜利获得。\n每套最多4本，奖励以该套配置为准。");
        }
        private void ShowLibraryBook(int id)
        {
            if (libraryState == null || !libraryCatalog.Books.TryGetValue(id, out var book)) return;
            var reward = libraryCatalog.InSet(book.Set).FirstOrDefault(r => r.Kind == "book" && r.Required.Contains(id));
            string status = libraryState.Activated(id) ? "已激活，永久生效" : libraryState.Obtained.Contains(id) ? "已收藏，尚未激活" : "尚未收藏";
            EnsureErrorPresenter();
            errorPresenter.Show(book.Name, status + "\n背包数量：" + libraryState.Quantity(id) + "\n" + LibraryCatalogData.AttributeText(reward?.Attributes)
                + "\n来源：世界章节、扫荡、封神列传\n激活消耗1本；已激活后新获得副本自动出售");
        }
        private void ShowLibraryAttributes()
        {
            EnsureErrorPresenter();
            errorPresenter.ShowAttributes("藏书属性总览",
                (libraryState?.Attributes ?? Array.Empty<int[]>()).Select(LibraryCatalogData.Attribute).ToArray(),
                "永久加成当前上阵神将");
        }
        private void ConfirmLibraryReward(int id)
        {
            if (libraryState == null || !libraryCatalog.Rewards.TryGetValue(id, out var reward) || !libraryCatalog.Eligible(libraryState, reward)) return;
            int session = services.Network.SessionVersion;
            string detail = reward.Kind == "book" ? libraryCatalog.Books[reward.Required[0]].Name + "\n消耗书籍：1本" : "激活套装奖励\n不消耗书籍";
            detail += "\n" + LibraryCatalogData.AttributeText(reward.Attributes, "\n") + "\n激活后永久生效";
            EnsureErrorPresenter();
            errorPresenter.ShowConfirmation("藏书激活", detail, () =>
            {
                if (IsLibraryOpen && session == services.Network.SessionVersion && libraryCatalog.Eligible(libraryState, reward)) RequestLibrary(1, id);
            }, "激活", "取消", true);
        }
        private void LibraryFailure(string text)
        {
            libraryScreen?.Fail(text);
            if (libraryReportedError == text) return;
            libraryReportedError = text; EnsureErrorPresenter(); errorPresenter.Show("藏书阁", text);
        }
        private void RequestLibrary(int operation, int reward)
        {
            if (libraryPending != null && (operation == 0 || libraryPendingOperation != 0)) return;
            if (!services.Network.IsConnected) { LibraryFailure("连接已断开，请重新登录"); libraryNextRead = Time.realtimeSinceStartup + 5; return; }
            string id = Guid.NewGuid().ToString("N");
            var payload = new JObject { ["request_id"] = id, ["revision"] = libraryState?.Revision ?? "0" };
            if (operation != 0) payload["reward_id"] = reward;
            var message = LegacyTcpMessage.New(); message.WriteWord(326); message.WriteByte(operation); message.WriteString(payload.ToString(Formatting.None));
            libraryPending = id; libraryPendingOperation = operation; libraryDeadline = Time.realtimeSinceStartup + 8; libraryNextRead = float.PositiveInfinity;
            if (operation != 0) libraryScreen.SetPending(true);
            try { services.Network.Send(message); }
            catch (Exception e) { libraryPending = null; LibraryFailure("藏书请求失败：" + e.Message); libraryNextRead = Time.realtimeSinceStartup + 1; }
        }
        private void ApplyLibraryPacket(LegacyTcpMessage message)
        {
            if (message.ReadByte() != 128) throw new InvalidOperationException("藏书回包版本错误");
            var state = JsonConvert.DeserializeObject<LibraryEnvelope>(message.ReadString());
            if (state == null || state.Schema != 1 || message.Remaining != 0) throw new InvalidOperationException("藏书回包格式错误");
            if (!IsLibraryOpen || librarySession != services.Network.SessionVersion) return;
            bool push = string.IsNullOrEmpty(state.Request) && libraryPending == null;
            if (!push && state.Request != libraryPending) return;
            libraryPending = null;
            if (long.TryParse(state.Gold, out long gold)) services.Currencies.Set(CurrencyIds.Gold, gold);
            libraryState = state; libraryScreen.Apply(state);
            if (!string.IsNullOrEmpty(state.Error)) { LibraryFailure(state.Error); libraryNextRead = Time.realtimeSinceStartup + 2; }
            else { libraryReportedError = null; libraryNextRead = Time.realtimeSinceStartup + 10; }
        }
        private System.Collections.IEnumerator PollLibrary()
        {
            while (IsLibraryOpen)
            {
                if (librarySession != services.Network.SessionVersion) { libraryPending = null; LibraryFailure("连接已变化，请重新进入藏书阁"); yield break; }
                if (libraryPending != null && Time.realtimeSinceStartup >= libraryDeadline) { libraryPending = null; LibraryFailure("请求超时，正在重新同步藏书信息"); libraryNextRead = Time.realtimeSinceStartup + 1; }
                if (libraryPending == null && Time.realtimeSinceStartup >= libraryNextRead) RequestLibrary(0, 0);
                yield return null;
            }
        }
    }
}
