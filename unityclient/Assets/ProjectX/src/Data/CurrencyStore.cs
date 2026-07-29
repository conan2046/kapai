using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public static class CurrencyIds
    {
        public const int Gold = 60000;
        public const int BoundPremium = 60001;
        public const int Premium = 60003;
        public const int Soul = 60014;
        public const int GuildContribution = 60021;
        public const int StarEssence = 60025;
        public const int Stamina = 60026;
        public const int ArenaAttempts = 60027;
        public const int Activity = 60030;
        public const int Arena = 60050;
        public const int Kunlun = 60051;
        public const int Spirit = 60054;
        public const int Turntable = 60056;
    }

    public sealed class CurrencyStore
    {
        private readonly Dictionary<int, long> values = new Dictionary<int, long>();
        public event Action Changed;

        public long Gold => Get(CurrencyIds.Gold);
        public long Premium => Get(CurrencyIds.Premium);
        public long BoundPremium => Get(CurrencyIds.BoundPremium);
        public long Stamina => Get(CurrencyIds.Stamina);

        public long Get(int id) => values.TryGetValue(id, out long value) ? value : 0;

        public void Initialize(long gold, long premium, long boundPremium, uint soul, uint guildContribution)
        {
            values.Clear();
            values[CurrencyIds.Gold] = gold;
            values[CurrencyIds.Premium] = premium;
            values[CurrencyIds.BoundPremium] = boundPremium;
            values[CurrencyIds.Soul] = soul;
            values[CurrencyIds.GuildContribution] = guildContribution;
            Changed?.Invoke();
        }

        public void Set(int id, long value)
        {
            values[id] = Math.Max(0, value);
            Changed?.Invoke();
        }

        public void Clear()
        {
            values.Clear();
            Changed?.Invoke();
        }
    }
}
