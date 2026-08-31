using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;

namespace ProjectX.Data
{
    public enum BattleClipType : uint
    {
        ModelAnimation = 1,
        SkillAnimation = 2,
        HurtAnimation = 3
    }

    public sealed class BattleActionClip
    {
        public uint Sequence { get; internal set; }
        public float DelaySeconds { get; internal set; }
        public BattleClipType Type { get; internal set; }
        public uint DefinitionId { get; internal set; }
    }

    public sealed class BattleActionDefinition
    {
        internal readonly List<BattleActionClip> MutableClips = new List<BattleActionClip>();
        public uint Id { get; internal set; }
        public uint ComboStartIndex { get; internal set; }
        public uint MultiTargetType { get; internal set; }
        public uint MultiTargetStartIndex { get; internal set; }
        public IReadOnlyList<BattleActionClip> Clips => MutableClips;
    }

    public sealed class BattleModelActionDefinition
    {
        public uint Id { get; internal set; }
        public string ActionSuffix { get; internal set; }
        public uint MoveStartType { get; internal set; }
        public uint MoveEndType { get; internal set; }
        public float MoveSeconds { get; internal set; }
        public string SoundFile { get; internal set; }
        public uint ShakeId { get; internal set; }
    }

    public sealed class BattleSkillEffectDefinition
    {
        public uint Id { get; internal set; }
        public string File { get; internal set; }
        public uint ResourceType { get; internal set; }
        public uint MoveStartType { get; internal set; }
        public uint MoveEndType { get; internal set; }
        public float MoveSeconds { get; internal set; }
        public Vector2 LeftOffset { get; internal set; }
        public Vector2 RightOffset { get; internal set; }
        public uint HitPoint { get; internal set; }
        public string SoundFile { get; internal set; }
        public uint ShakeId { get; internal set; }
        public float Scale { get; internal set; }
    }

    public sealed class BattleHurtDefinition
    {
        public uint Id { get; internal set; }
        public string ActionSuffix { get; internal set; }
    }

    public sealed class BattleShakeDefinition
    {
        public uint Id { get; internal set; }
        public float DelayRatio { get; internal set; }
        public float DurationSeconds { get; internal set; }
        public float Strength { get; internal set; }
    }

    public sealed class BattleBuffDefinition
    {
        public uint Id { get; internal set; }
        public string Name { get; internal set; }
        public uint TextType { get; internal set; }
        public uint ShowType { get; internal set; }
        public string ResourceName { get; internal set; }
        public uint Hit { get; internal set; }
        public Vector2 Offset { get; internal set; }
        public string ShowText { get; internal set; }
        public string TipIcon { get; internal set; }
        public string Description { get; internal set; }
    }

    public sealed class BattleUnitHitDefinition
    {
        public uint Id { get; internal set; }
        public Vector2 HpBarPosition { get; internal set; }
        public Vector2 HeadPosition { get; internal set; }
        public Vector2 WaistPosition { get; internal set; }
        public Vector2 FootPosition { get; internal set; }

        public Vector2 ResolveHitPoint(uint hitPoint)
        {
            if (hitPoint == 3) return HeadPosition;
            if (hitPoint == 2) return WaistPosition;
            return FootPosition;
        }
    }

    public sealed class BattleFormationDefinition
    {
        public uint Id { get; internal set; }
        public string Name { get; internal set; }
        public IReadOnlyList<int> Positions { get; internal set; }
    }

    // Shared by every battle entry. This is the direct Unity equivalent of
    // LDataConstMgr:GetBTAction/GetBTModelAct/GetBTSkAct/GetBTHurtAct.
    public sealed class BattlePresentationCatalog
    {
        public const string ResourceRoot = "ProjectXConfig/battle/";

        private readonly Dictionary<uint, BattleActionDefinition> actions;
        private readonly Dictionary<uint, BattleModelActionDefinition> modelActions;
        private readonly Dictionary<uint, BattleSkillEffectDefinition> skillEffects;
        private readonly Dictionary<uint, BattleHurtDefinition> hurtActions;
        private readonly Dictionary<uint, BattleShakeDefinition> shakes;
        private readonly Dictionary<uint, BattleBuffDefinition> buffs;
        private readonly Dictionary<uint, BattleUnitHitDefinition> monsterHits;
        private readonly Dictionary<uint, BattleFormationDefinition> formations;

        private static readonly BattleUnitHitDefinition DefaultHit = new BattleUnitHitDefinition
        {
            Id = 0,
            HpBarPosition = new Vector2(0f, 100f),
            HeadPosition = new Vector2(0f, 70f),
            WaistPosition = new Vector2(0f, 40f),
            FootPosition = new Vector2(0f, 10f)
        };

        // AppDef.HeroHitData, indexed by profession. The /21 player unit does
        // not transmit profession, so profession 1 is the protocol-safe default.
        private static readonly BattleUnitHitDefinition[] HeroHits =
        {
            new BattleUnitHitDefinition { Id = 1, HpBarPosition = new Vector2(0f, 145f), HeadPosition = new Vector2(0f, 113f), WaistPosition = new Vector2(0f, 67f), FootPosition = Vector2.zero },
            new BattleUnitHitDefinition { Id = 2, HpBarPosition = new Vector2(0f, 145f), HeadPosition = new Vector2(0f, 103f), WaistPosition = new Vector2(0f, 56f), FootPosition = Vector2.zero },
            new BattleUnitHitDefinition { Id = 3, HpBarPosition = new Vector2(0f, 140f), HeadPosition = new Vector2(0f, 110f), WaistPosition = new Vector2(0f, 60f), FootPosition = Vector2.zero },
            new BattleUnitHitDefinition { Id = 4, HpBarPosition = new Vector2(0f, 140f), HeadPosition = new Vector2(0f, 100f), WaistPosition = new Vector2(0f, 65f), FootPosition = Vector2.zero },
            new BattleUnitHitDefinition { Id = 5, HpBarPosition = new Vector2(0f, 145f), HeadPosition = new Vector2(0f, 110f), WaistPosition = new Vector2(0f, 65f), FootPosition = Vector2.zero },
            new BattleUnitHitDefinition { Id = 6, HpBarPosition = new Vector2(0f, 140f), HeadPosition = new Vector2(0f, 105f), WaistPosition = new Vector2(0f, 68f), FootPosition = Vector2.zero }
        };

        private BattlePresentationCatalog(
            Dictionary<uint, BattleActionDefinition> actions,
            Dictionary<uint, BattleModelActionDefinition> modelActions,
            Dictionary<uint, BattleSkillEffectDefinition> skillEffects,
            Dictionary<uint, BattleHurtDefinition> hurtActions,
            Dictionary<uint, BattleShakeDefinition> shakes,
            Dictionary<uint, BattleBuffDefinition> buffs,
            Dictionary<uint, BattleUnitHitDefinition> monsterHits,
            Dictionary<uint, BattleFormationDefinition> formations)
        {
            this.actions = actions;
            this.modelActions = modelActions;
            this.skillEffects = skillEffects;
            this.hurtActions = hurtActions;
            this.shakes = shakes;
            this.buffs = buffs;
            this.monsterHits = monsterHits;
            this.formations = formations;
        }

        public int ActionCount => actions.Count;
        public int ModelActionCount => modelActions.Count;
        public int SkillEffectCount => skillEffects.Count;
        public int HurtActionCount => hurtActions.Count;
        public int ShakeCount => shakes.Count;
        public int BuffCount => buffs.Count;
        public int MonsterHitCount => monsterHits.Count;
        public int FormationCount => formations.Count;

        public static BattlePresentationCatalog LoadFromResources()
        {
            return new BattlePresentationCatalog(
                ReadActions(LoadBytes("skill_client.dat"), "skill_client.dat"),
                ReadModelActions(LoadBytes("skill_attack_client.dat"), "skill_attack_client.dat"),
                ReadSkillEffects(LoadBytes("skill_effect_client.dat"), "skill_effect_client.dat"),
                ReadHurtActions(LoadBytes("skill_behit_client.dat"), "skill_behit_client.dat"),
                ReadShakes(LoadBytes("skill_camerashock.dat"), "skill_camerashock.dat"),
                ReadBuffs(LoadBytes("buff_client.dat"), "buff_client.dat"),
                ReadUnitHits(LoadBytes("hit_monster.dat"), "hit_monster.dat"),
                ReadFormations(LoadText("zhenfa_config_dat"), "zhenfa_config_dat.lua"));
        }

        public BattleActionDefinition ResolveAction(uint skillId, byte actionType)
        {
            // Cocos offsets buff action ids by 100000 when that variant exists.
            uint id = actionType == 3 && skillId <= uint.MaxValue - 100000 ? skillId + 100000 : skillId;
            if (actions.TryGetValue(id, out BattleActionDefinition exact)) return exact;
            if (actions.TryGetValue(skillId, out exact)) return exact;
            actions.TryGetValue(0, out BattleActionDefinition fallback);
            return fallback;
        }

        public bool TryGetModelAction(uint id, out BattleModelActionDefinition value) => modelActions.TryGetValue(id, out value);
        public bool TryGetSkillEffect(uint id, out BattleSkillEffectDefinition value) => skillEffects.TryGetValue(id, out value);
        public bool TryGetHurtAction(uint id, out BattleHurtDefinition value) => hurtActions.TryGetValue(id, out value);
        public bool TryGetShake(uint id, out BattleShakeDefinition value)
        {
            if (shakes.TryGetValue(id, out value)) return true;
            return shakes.TryGetValue(1, out value);
        }
        public bool TryGetBuff(uint id, out BattleBuffDefinition value) => buffs.TryGetValue(id, out value);
        public bool TryGetFormation(uint id, out BattleFormationDefinition value) => formations.TryGetValue(id, out value);

        public BattleUnitHitDefinition ResolveUnitHit(byte unitType, uint modelPicture, int profession = 1)
        {
            if (unitType == 1)
                return HeroHits[Mathf.Clamp(profession, 1, HeroHits.Length) - 1];
            return monsterHits.TryGetValue(modelPicture, out BattleUnitHitDefinition value) ? value : DefaultHit;
        }

        private static byte[] LoadBytes(string name)
        {
            TextAsset asset = Resources.Load<TextAsset>(ResourceRoot + name);
            if (asset == null || asset.bytes == null || asset.bytes.Length == 0)
                throw new InvalidDataException($"Battle presentation resource is missing: {ResourceRoot}{name}.bytes");
            return asset.bytes;
        }

        private static string LoadText(string name)
        {
            TextAsset asset = Resources.Load<TextAsset>(ResourceRoot + name);
            if (asset == null || string.IsNullOrWhiteSpace(asset.text))
                throw new InvalidDataException($"Battle presentation resource is missing: {ResourceRoot}{name}.txt");
            return asset.text;
        }

        private static Dictionary<uint, BattleActionDefinition> ReadActions(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader =>
            {
                var value = new BattleActionDefinition { Id = reader.ReadUInt32() };
                string clips = ReadUtf8(reader);
                foreach (string encoded in clips.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    string[] fields = encoded.Split('-');
                    if (fields.Length != 4)
                        throw new InvalidDataException($"{name} action {value.Id} has invalid clip '{encoded}'.");
                    value.MutableClips.Add(new BattleActionClip
                    {
                        Sequence = ParseUInt(fields[0], name),
                        DelaySeconds = ParseUInt(fields[1], name) / 100f,
                        Type = (BattleClipType)ParseUInt(fields[2], name),
                        DefinitionId = ParseUInt(fields[3], name)
                    });
                }
                value.ComboStartIndex = reader.ReadUInt32();
                value.MultiTargetType = reader.ReadUInt32();
                value.MultiTargetStartIndex = reader.ReadUInt32();
                return value;
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleModelActionDefinition> ReadModelActions(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader => new BattleModelActionDefinition
            {
                Id = reader.ReadUInt32(),
                ActionSuffix = ReadUtf8(reader),
                MoveStartType = reader.ReadUInt32(),
                MoveEndType = reader.ReadUInt32(),
                MoveSeconds = reader.ReadUInt32() / 1000f,
                SoundFile = ReadUtf8(reader),
                ShakeId = reader.ReadUInt32()
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleSkillEffectDefinition> ReadSkillEffects(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader => new BattleSkillEffectDefinition
            {
                Id = reader.ReadUInt32(),
                File = ReadUtf8(reader),
                ResourceType = reader.ReadUInt32(),
                MoveStartType = reader.ReadUInt32(),
                MoveEndType = reader.ReadUInt32(),
                MoveSeconds = reader.ReadUInt32() / 1000f,
                LeftOffset = ParsePoint(ReadUtf8(reader), name),
                RightOffset = ParsePoint(ReadUtf8(reader), name),
                HitPoint = reader.ReadUInt32(),
                SoundFile = ReadUtf8(reader),
                ShakeId = reader.ReadUInt32(),
                Scale = reader.ReadUInt32() / 100f
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleHurtDefinition> ReadHurtActions(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader => new BattleHurtDefinition
            {
                Id = reader.ReadUInt32(),
                ActionSuffix = ReadUtf8(reader)
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleShakeDefinition> ReadShakes(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader => new BattleShakeDefinition
            {
                Id = reader.ReadUInt32(),
                DelayRatio = reader.ReadUInt32() / 100f,
                DurationSeconds = reader.ReadUInt32() / 1000f,
                Strength = reader.ReadUInt32()
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleBuffDefinition> ReadBuffs(byte[] bytes, string name)
        {
            return ReadTable(bytes, name, reader => new BattleBuffDefinition
            {
                Id = reader.ReadUInt32(),
                Name = ReadUtf8(reader),
                TextType = reader.ReadUInt32(),
                ShowType = reader.ReadUInt32(),
                ResourceName = ReadUtf8(reader),
                Hit = reader.ReadUInt32(),
                Offset = ParsePoint(ReadUtf8(reader), name),
                ShowText = ReadUtf8(reader),
                TipIcon = ReadUtf8(reader),
                Description = ReadUtf8(reader)
            }, value => value.Id);
        }

        private static Dictionary<uint, BattleUnitHitDefinition> ReadUnitHits(byte[] bytes, string name)
        {
            Dictionary<uint, BattleUnitHitDefinition> values = ReadTable(bytes, name, reader => new BattleUnitHitDefinition
            {
                Id = reader.ReadUInt32(),
                HpBarPosition = new Vector2(reader.ReadSingle(), reader.ReadSingle()),
                HeadPosition = new Vector2(reader.ReadSingle(), reader.ReadSingle()),
                WaistPosition = new Vector2(reader.ReadSingle(), reader.ReadSingle()),
                FootPosition = new Vector2(reader.ReadSingle(), reader.ReadSingle())
            }, value => value.Id);
            // Current Cocos applies this runtime correction after loading the file.
            values[304] = new BattleUnitHitDefinition
            {
                Id = 304,
                HpBarPosition = new Vector2(0f, 145f),
                HeadPosition = new Vector2(0f, 92f),
                WaistPosition = new Vector2(0f, 55f),
                FootPosition = Vector2.zero
            };
            return values;
        }

        private static Dictionary<uint, BattleFormationDefinition> ReadFormations(string text, string name)
        {
            var values = new Dictionary<uint, BattleFormationDefinition>();
            MatchCollection blocks = Regex.Matches(text,
                @"\{\s*id\s*=\s*(?<id>\d+)\s*,(?<body>.*?)counter\s*=\s*\{[^}]*\}\s*\}",
                RegexOptions.Singleline | RegexOptions.CultureInvariant);
            foreach (Match block in blocks)
            {
                uint id = ParseUInt(block.Groups["id"].Value, name);
                string body = block.Groups["body"].Value;
                Match nameMatch = Regex.Match(body, "name\\s*=\\s*\"(?<name>[^\"]+)\"",
                    RegexOptions.CultureInvariant);
                if (!nameMatch.Success)
                    throw new InvalidDataException($"{name} formation {id} has no name.");
                var positions = new int[5];
                for (int index = 1; index <= positions.Length; index++)
                {
                    Match position = Regex.Match(body, $@"index{index}\s*=\s*(?<value>\d+)",
                        RegexOptions.CultureInvariant);
                    if (!position.Success)
                        throw new InvalidDataException($"{name} formation {id} has no index{index}.");
                    positions[index - 1] = checked((int)ParseUInt(position.Groups["value"].Value, name));
                }
                values.Add(id, new BattleFormationDefinition
                {
                    Id = id,
                    Name = nameMatch.Groups["name"].Value,
                    Positions = positions
                });
            }
            if (values.Count == 0) throw new InvalidDataException($"{name} contains no formations.");
            return values;
        }

        private static Dictionary<uint, T> ReadTable<T>(byte[] bytes, string name, Func<BinaryReader, T> read, Func<T, uint> key)
        {
            using (var stream = new MemoryStream(bytes, false))
            using (var reader = new BinaryReader(stream, Encoding.UTF8, false))
            {
                uint count = reader.ReadUInt32();
                var result = new Dictionary<uint, T>(checked((int)count));
                for (uint index = 0; index < count; index++)
                {
                    T value = read(reader);
                    result.Add(key(value), value);
                }
                if (stream.Position != stream.Length)
                    throw new InvalidDataException($"{name} has {stream.Length - stream.Position} unread bytes.");
                return result;
            }
        }

        private static string ReadUtf8(BinaryReader reader)
        {
            ushort length = reader.ReadUInt16();
            byte[] bytes = reader.ReadBytes(length);
            if (bytes.Length != length) throw new EndOfStreamException("Battle config UTF-8 string is truncated.");
            return Encoding.UTF8.GetString(bytes);
        }

        private static uint ParseUInt(string value, string name)
        {
            if (!uint.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out uint result))
                throw new InvalidDataException($"{name} contains invalid unsigned integer '{value}'.");
            return result;
        }

        private static Vector2 ParsePoint(string value, string name)
        {
            if (string.IsNullOrEmpty(value)) return Vector2.zero;
            string[] fields = value.Split('-');
            if (fields.Length != 2
                || !float.TryParse(fields[0], NumberStyles.Float, CultureInfo.InvariantCulture, out float x)
                || !float.TryParse(fields[1], NumberStyles.Float, CultureInfo.InvariantCulture, out float y))
                throw new InvalidDataException($"{name} contains invalid point '{value}'.");
            return new Vector2(x, y);
        }
    }
}
