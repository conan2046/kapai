using System.Collections.Generic;

namespace ProjectX.Data
{
    public static class ChatCatalog
    {
        private static readonly Dictionary<ChatChannel, string> Names = new Dictionary<ChatChannel, string>
        {
            { ChatChannel.Combined, "综合" }, { ChatChannel.World, "世界" },
            { ChatChannel.Near, "附近" }, { ChatChannel.Team, "队伍" },
            { ChatChannel.Guild, "帮派" }, { ChatChannel.Private, "私聊" },
            { ChatChannel.System, "系统" }, { ChatChannel.CrossServer, "跨服" }
        };

        public static string GetName(ChatChannel channel) => Names.TryGetValue(channel, out string name) ? name : $"频道{(byte)channel}";
    }
}
