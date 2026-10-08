namespace ProjectX.Data
{
    public sealed class PlayerSummary
    {
        public PlayerSummary(uint id = 0, string name = "", ushort level = 0, byte sex = 0, byte head = 0,
            ulong power = 0, uint teamId = 0, uint guildId = 0)
        {
            Id = id;
            Name = name ?? string.Empty;
            Level = level;
            Sex = sex;
            Head = head;
            Power = power;
            TeamId = teamId;
            GuildId = guildId;
        }

        public uint Id { get; }
        public string Name { get; }
        public ushort Level { get; }
        public byte Sex { get; }
        public byte Head { get; }
        public ulong Power { get; }
        public uint TeamId { get; }
        public uint GuildId { get; }
    }
}
