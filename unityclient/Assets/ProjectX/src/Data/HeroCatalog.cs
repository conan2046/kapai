using System.Collections.Generic;

namespace ProjectX.Data
{
    public readonly struct HeroDefinition
    {
        public HeroDefinition(int picture, int quality) { Picture = picture; Quality = quality; }
        public int Picture { get; }
        public int Quality { get; }
    }

    public static class HeroCatalog
    {
        private static readonly IReadOnlyDictionary<int, HeroDefinition> Definitions =
            new Dictionary<int, HeroDefinition>
            {
                { 10, new HeroDefinition(401, 7) }, { 11, new HeroDefinition(501, 7) },
                { 12, new HeroDefinition(701, 7) }, { 13, new HeroDefinition(503, 6) },
                { 14, new HeroDefinition(601, 6) }, { 15, new HeroDefinition(402, 6) },
                { 16, new HeroDefinition(204, 5) }, { 17, new HeroDefinition(202, 5) },
                { 18, new HeroDefinition(201, 5) }, { 19, new HeroDefinition(112, 5) },
                { 20, new HeroDefinition(113, 5) }, { 21, new HeroDefinition(303, 5) },
                { 22, new HeroDefinition(203, 5) }, { 23, new HeroDefinition(502, 5) },
                { 24, new HeroDefinition(703, 5) }, { 25, new HeroDefinition(304, 5) },
                { 26, new HeroDefinition(504, 5) }, { 27, new HeroDefinition(301, 6) },
                { 28, new HeroDefinition(602, 6) }, { 29, new HeroDefinition(603, 6) },
                { 30, new HeroDefinition(604, 6) }, { 31, new HeroDefinition(403, 6) },
                { 32, new HeroDefinition(404, 6) }, { 33, new HeroDefinition(302, 5) },
                { 34, new HeroDefinition(101, 5) }, { 35, new HeroDefinition(803, 5) },
                { 36, new HeroDefinition(905, 4) }, { 37, new HeroDefinition(704, 5) },
                { 38, new HeroDefinition(804, 5) }, { 39, new HeroDefinition(901, 5) },
                { 40, new HeroDefinition(801, 5) }, { 41, new HeroDefinition(802, 5) },
                { 42, new HeroDefinition(909, 5) }, { 43, new HeroDefinition(902, 5) },
                { 44, new HeroDefinition(903, 5) }, { 45, new HeroDefinition(904, 5) },
                { 46, new HeroDefinition(105, 5) }, { 47, new HeroDefinition(906, 5) },
                { 48, new HeroDefinition(908, 4) }, { 49, new HeroDefinition(702, 5) },
                { 57, new HeroDefinition(103, 4) }, { 60, new HeroDefinition(412, 5) },
                { 62, new HeroDefinition(310, 5) }, { 63, new HeroDefinition(606, 5) },
                { 64, new HeroDefinition(907, 4) }, { 65, new HeroDefinition(114, 4) },
                { 68, new HeroDefinition(913, 7) }, { 69, new HeroDefinition(914, 7) }
            };

        public static bool TryGet(int heroId, out HeroDefinition definition)
            => Definitions.TryGetValue(heroId, out definition);
    }
}
