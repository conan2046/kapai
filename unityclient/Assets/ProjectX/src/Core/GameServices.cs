using System;
using ProjectX.Data;
using ProjectX.LuaRuntime;
using ProjectX.Network;
using ProjectX.UI;

namespace ProjectX.Core
{
    public sealed class GameServices : IDisposable
    {
        public GameServices(object luaBridge, AppLaunchOptions options = null)
        {
            Options = options ?? AppLaunchOptions.Current();
            State = new AppStateMachine();
            Config = AppConfig.LocalTest(Options);
            Configs = new ConfigService();
            Tasks = new TaskStore(Configs);
            Player = new PlayerStore();
            Currencies = new CurrencyStore();
            Bag = new BagStore();
            Rewards = new RewardStore();
            Mails = new MailStore();
            ShopCatalog = new ShopCatalog();
            Shop = new ShopStore();
            Friends = new FriendStore();
            Chat = new ChatStore();
            Team = new TeamStore();
            Guild = new GuildStore();
            Heroes = new HeroStore();
            Formation = new FormationStore();
            EquipmentCatalog = new EquipmentCatalog();
            HeroEquipment = new HeroEquipmentStore();
            FaBao = new FaBaoStore();
            Resources = new ResourceService();
            ServerTime = new ServerTimeService();
            Network = new NetworkService();
            ProtocolRegistry = ProtocolRegistry.CreateDefault();
            Protocols = new ProtocolDispatcher(ProtocolRegistry);
            UiRouter = new UiRouter();
            UiStack = new UiStack();
            Lua = new LuaRuntimeService(luaBridge);
            Network.PacketReceived += Protocols.Dispatch;
            Network.Disconnected += _ => ProtocolRegistry.ClearPending();
        }

        public AppLaunchOptions Options { get; }
        public AppStateMachine State { get; }
        public AppConfig Config { get; }
        public ConfigService Configs { get; }
        public TaskStore Tasks { get; }
        public PlayerStore Player { get; }
        public CurrencyStore Currencies { get; }
        public BagStore Bag { get; }
        public RewardStore Rewards { get; }
        public MailStore Mails { get; }
        public ShopCatalog ShopCatalog { get; }
        public ShopStore Shop { get; }
        public FriendStore Friends { get; }
        public ChatStore Chat { get; }
        public TeamStore Team { get; }
        public GuildStore Guild { get; }
        public HeroStore Heroes { get; }
        public FormationStore Formation { get; }
        public EquipmentCatalog EquipmentCatalog { get; }
        public HeroEquipmentStore HeroEquipment { get; }
        public FaBaoStore FaBao { get; }
        public ResourceService Resources { get; }
        public ServerTimeService ServerTime { get; }
        public NetworkService Network { get; }
        public ProtocolRegistry ProtocolRegistry { get; }
        public ProtocolDispatcher Protocols { get; }
        public UiRouter UiRouter { get; }
        public UiStack UiStack { get; }
        public LuaRuntimeService Lua { get; }

        public void Tick()
        {
            Network.Tick();
            ProtocolRegistry.Tick();
            Lua.Tick();
        }

        public void Dispose()
        {
            UiStack.Clear();
            ProtocolRegistry.ClearPending();
            Lua.Dispose();
            Network.Dispose();
            Resources.Dispose();
            EquipmentCatalog.Clear();
            HeroEquipment.Clear();
            FaBao.Clear();
            Mails.Clear();
            Shop.Clear();
            Friends.Clear();
            Chat.Clear();
            Team.Clear();
            Guild.Clear();
            ShopCatalog.Clear();
            ServerTime.Reset();
            Configs.Clear();
        }
    }
}
