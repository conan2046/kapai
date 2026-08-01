using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;
using UnityEngine;

namespace ProjectX.Data
{
    public sealed class WorldChapterVisualDefinition
    {
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int BundleId { get; set; }
        public string Background { get; set; } = string.Empty;
        public string ButtonImage { get; set; } = string.Empty;
        public Vector2 Position { get; set; }
    }

    public sealed class WorldMapVisualDefinition
    {
        public int Id { get; set; }
        public string Folder { get; set; } = string.Empty;
        public Vector2[] RoleCoordinates { get; set; } = Array.Empty<Vector2>();
        public Vector2[] MonsterCoordinates { get; set; } = Array.Empty<Vector2>();
        public Vector2[] CameraCoordinates { get; set; } = Array.Empty<Vector2>();
        public Vector2 Size { get; set; }
    }

    public sealed class WorldStageVisualDefinition
    {
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int Quality { get; set; }
        public int MonsterPicture { get; set; }
        public float MonsterScale { get; set; } = 1f;
        public int Hope { get; set; }
        public int MaxAttempts { get; set; }
        public WorldConfiguredReward[] ShowRewards { get; set; } = Array.Empty<WorldConfiguredReward>();
    }

    public readonly struct WorldConfiguredReward
    {
        public WorldConfiguredReward(int type, int id, int amount)
        {
            Type = type;
            Id = id;
            Amount = amount;
        }

        public int Type { get; }
        public int Id { get; }
        public int Amount { get; }
    }

    public static class WorldVisualCatalog
    {
        private sealed class StageSource
        {
            public string Name;
            public string Description;
            public int Quality;
            public int FightId;
            public int Hope;
            public int MaxAttempts;
            public WorldConfiguredReward[] ShowRewards;
        }

        private readonly struct MonsterSource
        {
            public MonsterSource(int picture, float scale)
            {
                Picture = picture;
                Scale = scale;
            }

            public int Picture { get; }
            public float Scale { get; }
        }

        private static readonly Dictionary<uint, WorldChapterVisualDefinition> Chapters =
            new Dictionary<uint, WorldChapterVisualDefinition>();
        private static readonly Dictionary<int, WorldMapVisualDefinition> Maps =
            new Dictionary<int, WorldMapVisualDefinition>();
        private static readonly Dictionary<uint, WorldStageVisualDefinition> Stages =
            new Dictionary<uint, WorldStageVisualDefinition>();
        private static readonly Dictionary<int, int> PlayerExperienceLimits = new Dictionary<int, int>();
        private static bool loaded;

        public static bool TryGetChapter(uint id, out WorldChapterVisualDefinition value)
        {
            EnsureLoaded();
            return Chapters.TryGetValue(id, out value);
        }

        public static bool TryGetMap(int id, out WorldMapVisualDefinition value)
        {
            EnsureLoaded();
            return Maps.TryGetValue(id, out value);
        }

        public static bool TryGetStage(uint id, out WorldStageVisualDefinition value)
        {
            EnsureLoaded();
            return Stages.TryGetValue(id, out value);
        }

        public static int GetPlayerExperienceLimit(int level)
        {
            EnsureLoaded();
            return PlayerExperienceLimits.TryGetValue(level, out int value) ? value : 0;
        }

        private static void EnsureLoaded()
        {
            if (loaded) return;
            loaded = true;

            string bigMap = Load("bigmap_dat");
            string mapRes = Load("map_res_dat");
            string mapList = Load("maplist_dat");
            string fightConfig = Load("fight_config_dat");
            string monsters = Load("monster_boss_basic_dat");
            string experience = Load("exp_dat");
            if (string.IsNullOrEmpty(bigMap) || string.IsNullOrEmpty(mapRes)
                || string.IsNullOrEmpty(mapList) || string.IsNullOrEmpty(fightConfig)
                || string.IsNullOrEmpty(monsters))
            {
                Debug.LogError("[World] Original Cocos visual configuration is missing from Resources/WorldUI/Config.");
                return;
            }

            ParseChapters(bigMap);
            ParseMaps(mapRes);
            if (!string.IsNullOrEmpty(experience)) ParseExperience(experience);

            var fightMonsters = new Dictionary<int, int>();
            foreach (string entry in SplitEntries(fightConfig))
            {
                if (TryGetInt(entry, "id", out int id) && TryGetInt(entry, "show", out int show))
                    fightMonsters[id] = show;
            }

            var monsterPictures = new Dictionary<int, MonsterSource>();
            foreach (string entry in SplitEntries(monsters))
            {
                if (TryGetInt(entry, "id", out int id) && TryGetInt(entry, "pic", out int picture)
                    && TryGetInt(entry, "scale", out int scale))
                    monsterPictures[id] = new MonsterSource(picture, scale / 100f);
            }

            var stageSources = new Dictionary<uint, StageSource>();
            foreach (string entry in SplitEntries(mapList))
            {
                if (!TryGetInt(entry, "ID", out int id) || !TryGetInt(entry, "quality", out int quality)
                    || !TryGetInt(entry, "fightID", out int fightId)) continue;
                TryGetString(entry, "Des", out string description);
                TryGetString(entry, "Name", out string name);
                TryGetInt(entry, "Hope", out int hope);
                TryGetInt(entry, "AttackCount", out int maxAttempts);
                stageSources[(uint)id] = new StageSource
                {
                    Name = name ?? string.Empty,
                    Quality = quality,
                    Description = description ?? string.Empty,
                    FightId = fightId,
                    Hope = hope,
                    MaxAttempts = maxAttempts,
                    ShowRewards = ParseTriples(GetBraceField(entry, "show_reward"))
                };
            }

            foreach (KeyValuePair<uint, StageSource> pair in stageSources)
            {
                fightMonsters.TryGetValue(pair.Value.FightId, out int monsterId);
                monsterPictures.TryGetValue(monsterId, out MonsterSource monster);
                Stages[pair.Key] = new WorldStageVisualDefinition
                {
                    Id = pair.Key,
                    Name = pair.Value.Name,
                    Description = pair.Value.Description,
                    Quality = pair.Value.Quality,
                    MonsterPicture = monster.Picture,
                    MonsterScale = monster.Scale <= 0f ? 1f : monster.Scale,
                    Hope = pair.Value.Hope,
                    MaxAttempts = pair.Value.MaxAttempts,
                    ShowRewards = pair.Value.ShowRewards ?? Array.Empty<WorldConfiguredReward>()
                };
            }
        }

        private static void ParseChapters(string source)
        {
            foreach (string entry in SplitEntries(source))
            {
                if (!TryGetInt(entry, "Id", out int rawId) || !TryGetInt(entry, "BundleId", out int bundleId)
                    || !TryGetString(entry, "World_bg", out string background)
                    || !TryGetString(entry, "btn_Image", out string buttonImage)
                    || !TryGetPair(entry, "Position_btn", out Vector2 position)) continue;
                TryGetString(entry, "Name", out string name);
                uint id = (uint)rawId;
                Chapters[id] = new WorldChapterVisualDefinition
                {
                    Id = id,
                    Name = name ?? string.Empty,
                    BundleId = bundleId,
                    Background = background,
                    Position = position,
                    ButtonImage = buttonImage
                };
            }
        }

        private static void ParseMaps(string source)
        {
            foreach (string entry in SplitEntries(source))
            {
                if (!TryGetInt(entry, "id", out int id) || !TryGetString(entry, "name", out string folder))
                    continue;
                Vector2[] size = ParsePairs(GetBraceField(entry, "map_size"));
                Maps[id] = new WorldMapVisualDefinition
                {
                    Id = id,
                    Folder = folder,
                    RoleCoordinates = ParsePairs(GetBraceField(entry, "role_coor")),
                    MonsterCoordinates = ParsePairs(GetBraceField(entry, "monster_coor")),
                    CameraCoordinates = ParsePairs(GetBraceField(entry, "camera_coor")),
                    Size = size.Length == 0 ? new Vector2(5500f, 1500f) : size[0]
                };
            }
        }

        private static void ParseExperience(string source)
        {
            foreach (string entry in SplitEntries(source))
                if (TryGetInt(entry, "level", out int level) && TryGetInt(entry, "exp", out int amount))
                    PlayerExperienceLimits[level] = amount;
        }

        private static IEnumerable<string> SplitEntries(string source)
        {
            int depth = 0;
            int entryStart = -1;
            bool inString = false;
            bool escaped = false;
            for (int index = 0; index < source.Length; index++)
            {
                char value = source[index];
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (value == '\\') escaped = true;
                    else if (value == '"') inString = false;
                    continue;
                }
                if (value == '"')
                {
                    inString = true;
                    continue;
                }
                if (value == '{')
                {
                    depth++;
                    if (depth == 2) entryStart = index;
                    continue;
                }
                if (value != '}') continue;
                if (depth == 2 && entryStart >= 0)
                {
                    yield return source.Substring(entryStart, index - entryStart + 1);
                    entryStart = -1;
                }
                if (depth > 0) depth--;
            }
        }

        private static bool TryGetInt(string entry, string name, out int value)
        {
            Match match = Regex.Match(entry, @"\b" + Regex.Escape(name) + @"\s*=\s*(-?\d+)");
            value = match.Success ? ParseInt(match.Groups[1].Value) : 0;
            return match.Success;
        }

        private static bool TryGetString(string entry, string name, out string value)
        {
            Match match = Regex.Match(entry, @"\b" + Regex.Escape(name) + @"\s*=\s*""((?:\\.|[^""])*)""");
            value = match.Success ? UnescapeLua(match.Groups[1].Value) : null;
            return match.Success;
        }

        private static bool TryGetPair(string entry, string name, out Vector2 value)
        {
            Match match = Regex.Match(entry, @"\b" + Regex.Escape(name)
                + @"\s*=\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}");
            value = match.Success
                ? new Vector2(ParseFloat(match.Groups[1].Value), ParseFloat(match.Groups[2].Value))
                : Vector2.zero;
            return match.Success;
        }

        private static WorldConfiguredReward[] ParseTriples(string source)
        {
            if (string.IsNullOrEmpty(source)) return Array.Empty<WorldConfiguredReward>();
            var values = new List<WorldConfiguredReward>();
            foreach (Match match in Regex.Matches(source,
                @"\{\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\}"))
            {
                values.Add(new WorldConfiguredReward(ParseInt(match.Groups[1].Value),
                    ParseInt(match.Groups[2].Value), ParseInt(match.Groups[3].Value)));
            }
            return values.ToArray();
        }

        private static string GetBraceField(string entry, string name)
        {
            Match match = Regex.Match(entry, @"\b" + Regex.Escape(name) + @"\s*=\s*\{");
            if (!match.Success) return string.Empty;
            int start = entry.IndexOf('{', match.Index);
            int depth = 0;
            for (int index = start; index < entry.Length; index++)
            {
                if (entry[index] == '{') depth++;
                else if (entry[index] == '}' && --depth == 0)
                    return entry.Substring(start, index - start + 1);
            }
            return string.Empty;
        }

        private static Vector2[] ParsePairs(string value)
        {
            var result = new List<Vector2>();
            foreach (Match match in Regex.Matches(value,
                         @"\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}"))
                result.Add(new Vector2(ParseFloat(match.Groups[1].Value), ParseFloat(match.Groups[2].Value)));
            return result.ToArray();
        }

        private static string Load(string name) =>
            Resources.Load<TextAsset>("WorldUI/Config/" + name)?.text ?? string.Empty;

        private static int ParseInt(string value) =>
            int.Parse(value, NumberStyles.Integer, CultureInfo.InvariantCulture);

        private static float ParseFloat(string value) =>
            float.Parse(value, NumberStyles.Float, CultureInfo.InvariantCulture);

        private static string UnescapeLua(string value) => value
            .Replace("\\n", "\n")
            .Replace("\\\"", "\"")
            .Replace("\\\\", "\\");
    }
}
