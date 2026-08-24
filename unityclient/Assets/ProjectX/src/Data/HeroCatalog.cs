using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using UnityEngine;

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
        private readonly struct SkillEffectParameter
        {
            public SkillEffectParameter(int baseValue, int increment)
            {
                BaseValue = baseValue;
                Increment = increment;
            }

            public int BaseValue { get; }
            public int Increment { get; }
        }

        private static bool authoritativeLoaded;
        private static bool missingResourcesLogged;
        private static readonly Dictionary<int, SkillEffectParameter[]> ActiveSkillEffects =
            new Dictionary<int, SkillEffectParameter[]>();
        private static readonly Dictionary<int, SkillEffectParameter[]> AdditiveSkillEffects =
            new Dictionary<int, SkillEffectParameter[]>();
        private static readonly Dictionary<int, HeroDefinition> Definitions =
            new Dictionary<int, HeroDefinition>
            {
                { 10, new HeroDefinition(401, 7) },
                { 11, new HeroDefinition(501, 7, "持续伤害+禁疗", false, 111, "业火焚心",
                    "攻击敌方攻击最高的3个目标，造成伤害并施加紧箍咒，使目标攻击降低并持续受到伤害，冷却3回合。", name: "接引道人") },
                { 12, new HeroDefinition(701, 7) }, { 13, new HeroDefinition(503, 6) },
                { 14, new HeroDefinition(601, 6) }, { 15, new HeroDefinition(402, 6) },
                { 16, new HeroDefinition(204, 5) }, { 17, new HeroDefinition(202, 5) },
                { 18, new HeroDefinition(201, 5) }, { 19, new HeroDefinition(112, 5) },
                { 20, new HeroDefinition(113, 5, name: "申公豹") }, { 21, new HeroDefinition(303, 5) },
                { 22, new HeroDefinition(203, 5, name: "李靖") }, { 23, new HeroDefinition(502, 5, name: "黄飞虎") },
                { 24, new HeroDefinition(703, 5, "单体爆发+追击", false, 241, "天子剑",
                    "攻击敌方当前生命值最高的目标，并对高生命目标造成额外伤害。", name: "姬发") }, { 25, new HeroDefinition(304, 5, name: "袁洪") },
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
                    "攻击敌方随机3个目标，造成攻击<color=#00ff00>2300%+200</color>的伤害，提高友方全体物理免伤<color=#00ff00>12%</color>", name: "苏全忠") },
                { 60, new HeroDefinition(412, 5, "群体中毒", false, 601, "瘟疫钟",
                    "攻击敌方全体并使目标持续受到中毒伤害。", name: "吕岳") },
                { 62, new HeroDefinition(310, 5, "后排群体+闪避", true, 621, "土遁",
                    "攻击敌方后排全体，并提升自身闪避率。", name: "张奎") }, { 63, new HeroDefinition(606, 5, name: "高兰英") },
                { 64, new HeroDefinition(907, 4, "控制", false, 641, "哼如洪钟", name: "郑伦") },
                { 65, new HeroDefinition(114, 4, name: "陈奇") },
                { 68, new HeroDefinition(913, 7) }, { 69, new HeroDefinition(914, 7) }
            };

        static HeroCatalog()
        {
            LoadAuthoritativeDefinitions();
        }

        private static void LoadAuthoritativeDefinitions()
        {
            if (authoritativeLoaded) return;
            TextAsset petAsset = Resources.Load<TextAsset>("Configs/pet_basic_config");
            TextAsset skillAsset = Resources.Load<TextAsset>("Configs/skill_basic");
            TextAsset activeEffectAsset = Resources.Load<TextAsset>("Configs/skill_active_effect");
            TextAsset additiveEffectAsset = Resources.Load<TextAsset>("Configs/skill_additive_effect");
            if (petAsset == null || skillAsset == null || activeEffectAsset == null || additiveEffectAsset == null)
            {
                if (!missingResourcesLogged)
                {
                    missingResourcesLogged = true;
                    Debug.LogError("[ProjectX][HeroCatalog] Authoritative pet/skill XML resources are missing.");
                }
                return;
            }
            try
            {
                LoadSkillEffects(activeEffectAsset.text, ActiveSkillEffects, 3);
                LoadSkillEffects(additiveEffectAsset.text, AdditiveSkillEffects, 5);
                Dictionary<int, XElement> skills = XDocument.Parse(skillAsset.text)
                    .Root?.Elements("CONTENT")
                    .Select(element => new { Element = element, Id = ParseInt(element.Attribute("id")?.Value) })
                    .Where(value => value.Id > 0)
                    .ToDictionary(value => value.Id, value => value.Element)
                    ?? new Dictionary<int, XElement>();
                foreach (XElement pet in XDocument.Parse(petAsset.text).Root?.Elements("CONTENT")
                             ?? Enumerable.Empty<XElement>())
                {
                    int id = ParseInt(pet.Attribute("id")?.Value);
                    if (id <= 0) continue;
                    int skillId = ParsePrimarySkillId(pet.Attribute("skill")?.Value);
                    skills.TryGetValue(skillId, out XElement skill);
                    string description = StripCocosColorTags(skill?.Attribute("desc")?.Value ?? "");
                    Definitions[id] = new HeroDefinition(
                        ParseInt(pet.Attribute("pic")?.Value),
                        ParseInt(pet.Attribute("quality")?.Value),
                        pet.Attribute("feature")?.Value ?? "",
                        ParseInt(pet.Attribute("attack_type")?.Value) == 1,
                        skillId,
                        skill?.Attribute("name")?.Value ?? "",
                        description,
                        pet.Attribute("name")?.Value ?? "");
                }
                authoritativeLoaded = true;
                missingResourcesLogged = false;
            }
            catch (Exception exception)
            {
                Debug.LogError($"[ProjectX][HeroCatalog] Authoritative hero config parse failed: {exception.Message}");
            }
        }

        private static int ParsePrimarySkillId(string value)
        {
            string first = (value ?? "").Split(';').FirstOrDefault();
            return ParseInt(first);
        }

        private static int ParseInt(string value)
            => int.TryParse(value, out int parsed) ? parsed : 0;

        private static string StripCocosColorTags(string value)
            => Regex.Replace(value ?? "", @"\[/?c\d*\]", string.Empty);

        private static void LoadSkillEffects(string xml,
            IDictionary<int, SkillEffectParameter[]> target, int parameterCount)
        {
            target.Clear();
            foreach (XElement element in XDocument.Parse(xml).Root?.Elements("CONTENT")
                         ?? Enumerable.Empty<XElement>())
            {
                int id = ParseInt(element.Attribute("id")?.Value);
                if (id <= 0) continue;
                var parameters = new SkillEffectParameter[parameterCount];
                for (int index = 1; index <= parameterCount; index++)
                {
                    parameters[index - 1] = new SkillEffectParameter(
                        ParseInt(element.Attribute($"para{index}")?.Value),
                        ParseInt(element.Attribute($"para{index}_lv")?.Value));
                }
                target[id] = parameters;
            }
        }

        public static string ResolveSkillDescription(string template, int skillLevel)
        {
            LoadAuthoritativeDefinitions();
            int level = Math.Max(1, skillLevel);
            string resolved = Regex.Replace(template ?? "", @"\{([12])-(\d+)-(\d+)\}", match =>
            {
                int type = ParseInt(match.Groups[1].Value);
                int effectId = ParseInt(match.Groups[2].Value);
                int parameterIndex = ParseInt(match.Groups[3].Value);
                IDictionary<int, SkillEffectParameter[]> source = type == 1
                    ? (IDictionary<int, SkillEffectParameter[]>)ActiveSkillEffects
                    : AdditiveSkillEffects;
                if (!source.TryGetValue(effectId, out SkillEffectParameter[] parameters)
                    || parameterIndex <= 0 || parameterIndex > parameters.Length)
                    return "0";
                SkillEffectParameter parameter = parameters[parameterIndex - 1];
                long raw = Math.Abs((long)parameter.BaseValue + (long)(level - 1) * parameter.Increment);
                bool percentage = type == 1 ? parameterIndex <= 2 : parameterIndex <= 3;
                string valueText;
                if (!percentage)
                {
                    valueText = raw.ToString(CultureInfo.InvariantCulture);
                }
                else
                {
                    double value = raw / 100d;
                    valueText = value.ToString(
                        Math.Abs(value - Math.Round(value)) < 0.0001d ? "0" : "0.##",
                        CultureInfo.InvariantCulture) + "%";
                }
                // LSkillBasicCfg:SetDesc wraps every dynamic value in [c3].
                // CCAysLabel maps c3/COL_GREEN to UICOLOR_GREEN (#0BE500).
                return $"<color=#0BE500>{valueText}</color>";
            });
            return resolved.Replace("%%", "%");
        }

        public static bool TryGet(int heroId, out HeroDefinition definition)
        {
            LoadAuthoritativeDefinitions();
            return Definitions.TryGetValue(heroId, out definition);
        }

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
