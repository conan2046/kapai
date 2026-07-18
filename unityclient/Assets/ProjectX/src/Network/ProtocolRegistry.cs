using System;
using System.Collections.Generic;
using ProjectX.Diagnostics;

namespace ProjectX.Network
{
    public sealed class ProtocolDefinition
    {
        public ProtocolDefinition(ushort command, string name, string module, double timeoutSeconds = 8d,
            bool expectsResponse = true)
        {
            Command = command;
            Name = name ?? command.ToString();
            Module = module ?? "Unknown";
            TimeoutSeconds = Math.Max(0.1d, timeoutSeconds);
            ExpectsResponse = expectsResponse;
        }

        public ushort Command { get; }
        public string Name { get; }
        public string Module { get; }
        public double TimeoutSeconds { get; }
        public bool ExpectsResponse { get; }
    }

    public sealed class RequestContext
    {
        internal RequestContext(long id, ProtocolDefinition protocol, DateTime sentUtc)
        {
            Id = id;
            Protocol = protocol;
            SentUtc = sentUtc;
        }

        public long Id { get; }
        public ProtocolDefinition Protocol { get; }
        public DateTime SentUtc { get; }
        public double ElapsedSeconds => (DateTime.UtcNow - SentUtc).TotalSeconds;
    }

    public sealed class ProtocolRegistry
    {
        private readonly Dictionary<ushort, ProtocolDefinition> definitions = new Dictionary<ushort, ProtocolDefinition>();
        private readonly Dictionary<ushort, Queue<RequestContext>> pending = new Dictionary<ushort, Queue<RequestContext>>();
        private long nextRequestId;

        public event Action<RequestContext> RequestTimedOut;
        public int PendingCount
        {
            get
            {
                int count = 0;
                foreach (Queue<RequestContext> queue in pending.Values) count += queue.Count;
                return count;
            }
        }

        public void Register(ProtocolDefinition definition)
        {
            if (definition == null) throw new ArgumentNullException(nameof(definition));
            definitions[definition.Command] = definition;
        }

        public ProtocolDefinition Get(ushort command)
        {
            return definitions.TryGetValue(command, out ProtocolDefinition value)
                ? value
                : new ProtocolDefinition(command, $"Command/{command}", "Unregistered");
        }

        public RequestContext TrackSend(ushort command)
        {
            ProtocolDefinition definition = Get(command);
            if (!definition.ExpectsResponse)
            {
                ClientLog.Info("Protocol", $"SEND {definition.Name}", $"cmd={command} one-way");
                return null;
            }
            var context = new RequestContext(++nextRequestId, definition, DateTime.UtcNow);
            if (!pending.TryGetValue(command, out Queue<RequestContext> queue))
            {
                queue = new Queue<RequestContext>();
                pending[command] = queue;
            }
            queue.Enqueue(context);
            ClientLog.Info("Protocol", $"SEND {definition.Name}", $"cmd={command} request={context.Id}");
            return context;
        }

        public RequestContext Complete(ushort command)
        {
            ProtocolDefinition definition = Get(command);
            RequestContext context = null;
            if (pending.TryGetValue(command, out Queue<RequestContext> queue) && queue.Count > 0)
            {
                context = queue.Dequeue();
                if (queue.Count == 0) pending.Remove(command);
            }
            ClientLog.Info("Protocol", $"RECV {definition.Name}", context == null
                ? $"cmd={command} unsolicited"
                : $"cmd={command} request={context.Id} elapsed={context.ElapsedSeconds:F3}s");
            return context;
        }

        public void Tick()
        {
            if (pending.Count == 0) return;
            var expired = new List<RequestContext>();
            var emptyCommands = new List<ushort>();
            foreach (KeyValuePair<ushort, Queue<RequestContext>> pair in pending)
            {
                Queue<RequestContext> queue = pair.Value;
                while (queue.Count > 0 && queue.Peek().ElapsedSeconds >= queue.Peek().Protocol.TimeoutSeconds)
                    expired.Add(queue.Dequeue());
                if (queue.Count == 0) emptyCommands.Add(pair.Key);
            }
            foreach (ushort command in emptyCommands) pending.Remove(command);
            foreach (RequestContext context in expired)
            {
                ClientLog.Warning("Protocol", $"TIMEOUT {context.Protocol.Name}",
                    $"cmd={context.Protocol.Command} request={context.Id} elapsed={context.ElapsedSeconds:F3}s");
                RequestTimedOut?.Invoke(context);
            }
        }

        public void ClearPending() => pending.Clear();

        public static ProtocolRegistry CreateDefault()
        {
            var registry = new ProtocolRegistry();
            registry.Register(new ProtocolDefinition(8, "PRO_ROLE_PACKAGE", "Bag"));
            registry.Register(new ProtocolDefinition(13, "PRO_INTERACT", "Interaction", expectsResponse: false));
            registry.Register(new ProtocolDefinition(15, "PRO_UPDATE_PACK", "Bag"));
            registry.Register(new ProtocolDefinition(18, "PRO_UPDATE_CHAR", "Player", expectsResponse: false));
            registry.Register(new ProtocolDefinition(24, "PRO_PET", "Hero"));
            registry.Register(new ProtocolDefinition(26, "PRO_MSG_CHAT", "Chat", expectsResponse: false));
            registry.Register(new ProtocolDefinition(27, "PRO_FRIEND", "Friend"));
            registry.Register(new ProtocolDefinition(29, "PRO_USER_TEAM", "Team"));
            registry.Register(new ProtocolDefinition(30, "PRO_UPDATE_TEAM", "Team", expectsResponse: false));
            registry.Register(new ProtocolDefinition(37, "PRO_TASK_LIST", "Task"));
            registry.Register(new ProtocolDefinition(39, "PRO_UPDATE_TASK", "Task"));
            registry.Register(new ProtocolDefinition(48, "PRO_ZHEN_FA", "Formation"));
            registry.Register(new ProtocolDefinition(54, "PRO_BANGPAI", "Guild"));
            registry.Register(new ProtocolDefinition(65, "PRO_FUNC_HOT_POINT", "Task", expectsResponse: false));
            registry.Register(new ProtocolDefinition(88, "PRO_GONGGAO", "LoginMain", expectsResponse: false));
            registry.Register(new ProtocolDefinition(128, "MSG_CLIENT_XINSHI", "Mail"));
            registry.Register(new ProtocolDefinition(199, "MSG_HUODONG_OPTION", "Welfare"));
            registry.Register(new ProtocolDefinition(206, "MSG_SYNC_TIME", "Core"));
            registry.Register(new ProtocolDefinition(221, "MSG_SHOP", "Shop"));
            registry.Register(new ProtocolDefinition(222, "MSG_TMP_HUODONG", "Welfare"));
            registry.Register(new ProtocolDefinition(223, "MSG_STAGE_GOAL", "Welfare"));
            registry.Register(new ProtocolDefinition(226, "MSG_UPDATE_USER_LEVELUP_INFO", "Player", expectsResponse: false));
            registry.Register(new ProtocolDefinition(321, "MSG_SPIRIT", "Player"));
            registry.Register(new ProtocolDefinition(319, "PET_EQUIP_OPERATE", "HeroEquipment"));
            registry.Register(new ProtocolDefinition(320, "MSG_GUANQIA", "WorldBattleDungeon"));
            registry.Register(new ProtocolDefinition(1001, "PRO_USER_LOGIN", "Login"));
            registry.Register(new ProtocolDefinition(1003, "PRO_CREATE_ROLE", "Login"));
            registry.Register(new ProtocolDefinition(1004, "PRO_SELECT_ROLE", "Login"));
            return registry;
        }
    }
}
