using System;
using ProjectX.Data;
using ProjectX.UI;
using UnityEngine;

namespace ProjectX.Core
{
    public sealed partial class ProjectXApp
    {
        public void AddLocalChatMessage(int channel, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = checked((ChatChannel)(byte)channel),
                Sender = services.Player.Summary,
                Content = content ?? string.Empty,
                IsLocalEcho = true
            });
        }

        public void AddChatMessage(int channel, double senderId, string senderName, int vip, int head, int sex, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = checked((ChatChannel)(byte)channel),
                Sender = new PlayerSummary(checked((uint)senderId), senderName, sex: checked((byte)sex), head: checked((byte)head)),
                VipLevel = checked((byte)vip),
                Content = content ?? string.Empty
            });
        }

        public void AddPrivateChatMessage(double senderId, string senderName, int vip, int head, int sex,
            int level, double teamId, double guildId, double recipientId, double serverTime, string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = ChatChannel.Private,
                Sender = new PlayerSummary(checked((uint)senderId), senderName, checked((ushort)level),
                    checked((byte)sex), checked((byte)head), teamId: checked((uint)teamId), guildId: checked((uint)guildId)),
                VipLevel = checked((byte)vip),
                RecipientRoleId = checked((uint)recipientId),
                ServerTime = checked((uint)serverTime),
                Content = content ?? string.Empty
            });
        }

        public void SetChatError(int channel, string message)
        {
            services.Chat.SetError(message);
            ShowToast(message, 3f);
        }

        public void CompleteChatValidation(string worldText, string privateText, string error)
        {
            EnsureChatPresenter();
            chatPresenter.SelectChannel(ChatChannel.Combined);
            if (GetLocalUserId() == 1 || !IsChatOpen
                || !services.Chat.Contains(ChatChannel.World, worldText)
                || !services.Chat.Contains(ChatChannel.Private, privateText)
                || string.IsNullOrWhiteSpace(error) || chatPresenter.RenderedCount < 2)
            {
                Fail($"Chat validation mismatch: user={GetLocalUserId()}, open={IsChatOpen}, messages={services.Chat.Count}, rendered={chatPresenter.RenderedCount}, error={error}.");
                return;
            }
            toastPresenter?.Clear();
            Complete($"COMPLETE: /26 world local echo -> self-private server packet -> ChatStore/UI -> invalid-target error ({services.Chat.Count} messages)");
        }

        public void AddSystemChatMessage(string content)
        {
            services.Chat.Add(new ChatMessageRecord
            {
                Channel = ChatChannel.System,
                Sender = new PlayerSummary(),
                Content = content ?? string.Empty
            });
            if (!string.IsNullOrWhiteSpace(content) && !HasCommandLineFlag("-projectXGameplayValidation")
                && !IsBattlePresentationActive)
                ShowToast(content, 3f);
        }

        private void EnsureChatPresenter()
        {
            chatView = chatView ?? services.UiRouter.FindBySource("MainChatLayer");
            if (chatView == null) throw new InvalidOperationException("MainChatLayer CocosUiBinding was not found.");
            chatPresenter = chatPresenter ?? new ChatPresenter(chatView, services.Chat,
                (channel, content, targetId) => InvokeLuaOrFail(onChatSend, "Chat.Send", channel, content, (double)targetId));
        }
    }
}
