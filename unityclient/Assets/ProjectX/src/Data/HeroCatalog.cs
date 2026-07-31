using System.Collections.Generic;

namespace ProjectX.Data
{
    public readonly struct HeroDefinition
    {
        public HeroDefinition(int picture, int quality, string feature = "", bool physicalAttack = false,
            int skillId = 0, string skillName = "", string skillDescription = "", string name = "")
        {
            Picture = picture;
            Quality = quality;
            Feature = feature ?? "";
            PhysicalAttack = physicalAttack;
            SkillId = skillId;
            SkillName = skillName ?? "";
            SkillDescription = skillDescription ?? "";
            Name = name ?? "";
        }
        public int Picture { get; }
        public int Quality { get; }
        public string Feature { get; }
        public bool PhysicalAttack { get; }
        public int SkillId { get; }
        public string SkillName { get; }
        public string SkillDescription { get; }
        public string Name { get; }
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
                { 20, new HeroDefinition(113, 5, name: "申公豹") }, { 21, new HeroDefinition(303, 5) },
                { 22, new HeroDefinition(203, 5, name: "李靖") }, { 23, new HeroDefinition(502, 5, name: "黄飞虎") },
                { 24, new HeroDefinition(703, 5, name: "姬发") }, { 25, new HeroDefinition(304, 5, name: "袁洪") },
                { 26, new HeroDefinition(504, 5, name: "黄天化") }, { 27, new HeroDefinition(301, 6) },
                { 28, new HeroDefinition(602, 6) }, { 29, new HeroDefinition(603, 6) },
                { 30, new HeroDefinition(604, 6) }, { 31, new HeroDefinition(403, 6) },
                { 32, new HeroDefinition(404, 6) }, { 33, new HeroDefinition(302, 5, name: "妲己") },
                { 34, new HeroDefinition(101, 5, name: "帝辛") }, { 35, new HeroDefinition(803, 5, name: "韦护") },
                { 36, new HeroDefinition(905, 4, name: "武吉") }, { 37, new HeroDefinition(704, 5) },
                { 38, new HeroDefinition(804, 5) }, { 39, new HeroDefinition(901, 5) },
                { 40, new HeroDefinition(801, 5) }, { 41, new HeroDefinition(802, 5) },
                { 42, new HeroDefinition(909, 5, name: "比干") }, { 43, new HeroDefinition(902, 5) },
                { 44, new HeroDefinition(903, 5) }, { 45, new HeroDefinition(904, 5) },
                { 46, new HeroDefinition(105, 5) }, { 47, new HeroDefinition(906, 5, name: "崇黑虎") },
                { 48, new HeroDefinition(908, 4, name: "胡喜媚") }, { 49, new HeroDefinition(702, 5, name: "罗宣") },
                { 57, new HeroDefinition(103, 4, "群体物理+免伤辅助", true, 571, "冲锋陷阵",
                    "攻击敌方随机3个目标，造成攻击<color=#00ff00>2300%+200</color>的伤害，提高友方全体物理免伤<color=#00ff00>12%</color>", name: "苏全忠") }, { 60, new HeroDefinition(412, 5, name: "吕岳") },
                { 62, new HeroDefinition(310, 5, name: "张奎") }, { 63, new HeroDefinition(606, 5, name: "高兰英") },
                { 64, new HeroDefinition(907, 4, "控制", false, 641, "哼如洪钟", name: "郑伦") },
                { 65, new HeroDefinition(114, 4, name: "陈奇") },
                { 68, new HeroDefinition(913, 7) }, { 69, new HeroDefinition(914, 7) }
            };

        public static bool TryGet(int heroId, out HeroDefinition definition)
            => Definitions.TryGetValue(heroId, out definition);

        public static IEnumerable<int> GetDrawPreviewHeroes(byte poolKind)
        {
            // Synchronized from server/config/json/draw_config.json. Cocos groups
            // normal=type 1/2, high=3/4 and friend=5/6 in its reward preview.
            // Actual rewards remain exclusively server-authoritative /224 results.
            switch (poolKind)
            {
                case 1: return new[] { 35, 23, 20, 34, 22, 24, 25, 26, 33, 42, 47, 60, 62, 63, 49, 64, 65, 36, 48, 57 };
                case 2: return new[] { 16, 17, 18, 20, 22, 23, 24, 25, 26, 33, 34, 35, 36, 42, 47, 48, 49, 57, 60, 62, 63, 64, 65 };
                case 3: return new[] { 36, 37, 38, 40, 41, 43, 44, 45, 46, 48, 57, 64, 65 };
                default: return System.Array.Empty<int>();
            }
        }
    }
}
