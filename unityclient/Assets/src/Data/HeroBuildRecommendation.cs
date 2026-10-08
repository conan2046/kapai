using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    // Field names deliberately match the shared JSON contract. Guidance is read-only.
    [Serializable]
    public sealed class HeroBuildProfile
    {
        public int id;
        public int hero_id;
        public string hero_name;
        public string branch;
        public string name;
        public string[] core_affixes;
        public string[] support_tags;
        public string strategy_hint;
    }

    public static class HeroBuildRecommendation
    {
        public static int Score(HeroBuildProfile profile, string key)
        {
            if (profile == null || string.IsNullOrEmpty(key)) return 0;
            if (Array.IndexOf(profile.core_affixes ?? Array.Empty<string>(), key) >= 0) return 100;
            int separator = key.IndexOf('-');
            string tag = separator > 0 ? key.Substring(0, separator) : string.Empty;
            return tag.Length > 0 && tag.All(c => c >= 'A' && c <= 'Z')
                && Array.IndexOf(profile.support_tags ?? Array.Empty<string>(), tag) >= 0 ? 60 : 0;
        }

        public static HeroBuildProfile[] Rank(IEnumerable<HeroBuildProfile> profiles, string key)
            => (profiles ?? Array.Empty<HeroBuildProfile>()).Where(p => Score(p, key) > 0)
                .OrderByDescending(p => Score(p, key)).ThenBy(p => p.id).ToArray();

        private static string MatchText(HeroBuildProfile profile, string key)
        {
            int score = Score(profile, key);
            string label = score == 100 ? "核心" : score == 60 ? "兼容" : "不匹配";
            return $"{score}/100（{label}）";
        }

        public static string Describe(IEnumerable<HeroBuildProfile> profiles, int heroId, string key)
        {
            if (string.IsNullOrEmpty(key)) return "尚无特殊词条，无法计算匹配度。";
            var lines = new List<string>();
            if (heroId > 0)
            {
                HeroBuildProfile[] own = (profiles ?? Array.Empty<HeroBuildProfile>())
                    .Where(p => p != null && p.hero_id == heroId).OrderBy(p => p.id).ToArray();
                if (own.Length == 0) return "该神将尚未配置首批 A/B 配装参考。";
                lines.Add($"配装参考：{own[0].hero_name}（不切换技能）");
                foreach (HeroBuildProfile profile in own)
                {
                    lines.Add($"{profile.branch}·{profile.name}：{MatchText(profile, key)}");
                    lines.Add($"建议：{profile.strategy_hint}");
                }
            }
            else
            {
                HeroBuildProfile[] ranked = Rank(profiles, key);
                if (ranked.Length == 0) return "暂无首批构筑匹配，可参考通用流派说明。";
                lines.Add("适配推荐（配装参考，不切换技能）");
                foreach (HeroBuildProfile profile in ranked.Take(3))
                    lines.Add($"{profile.hero_name}·{profile.name}：{MatchText(profile, key)}");
            }
            lines.Add("仅评单件词条；不计战力、Tier与套装。");
            return string.Join("\n", lines);
        }
    }
}
