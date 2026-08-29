using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ProjectX.Network;

namespace ProjectX.Data
{
    public sealed class WorldBattleUnitRecord
    {
        public byte Type { get; set; }
        public byte Position { get; set; }
        public uint Picture { get; set; }
        public string Name { get; set; }
        public ushort Level { get; set; }
        public ulong MaxHp { get; set; }
        public ulong CurrentHp { get; set; }
        public byte Quality { get; set; }
        public bool IsEnemy => Position > 9;
    }

    public sealed class WorldBattleActionRecord
    {
        public int Sequence { get; set; }
        public int Round { get; set; }
        public byte ActionCount { get; set; }
        public byte FirstActionType { get; set; }
        public byte FirstSourcePosition { get; set; }
        public byte FirstTargetPosition { get; set; }
        public ushort SkillId { get; set; }
        public bool FirstTargetHit { get; set; }
        public bool FirstTargetCritical { get; set; }
        public uint FirstTargetDamage { get; set; }
        public uint FirstTargetHealing { get; set; }
        public byte FirstTargetState { get; set; }
        public int SourceHpChanged { get; set; }
        public int SourceHpRecovered { get; set; }
        public byte SourceState { get; set; }
        public bool FirstTargetDead => (FirstTargetState & 0x01) != 0;
        public bool SourceDead => (SourceState & 0x01) != 0;
    }

    public sealed class WorldBattleReplayStore
    {
        private readonly List<WorldBattleUnitRecord> units = new List<WorldBattleUnitRecord>();
        private readonly List<WorldBattleActionRecord> actions = new List<WorldBattleActionRecord>();
        private int parsedRound;

        public event Action Changed;
        public uint FightId { get; private set; }
        public byte FightType { get; private set; }
        public bool CanSkip { get; private set; }
        public ushort MaxTurns { get; private set; }
        public string FriendlyName { get; private set; } = string.Empty;
        public string EnemyName { get; private set; } = string.Empty;
        public bool Won { get; private set; }
        public IReadOnlyList<WorldBattleUnitRecord> Units => units;
        public IReadOnlyList<WorldBattleActionRecord> Actions => actions;
        public bool HasAuthoritativeReplay { get; private set; }

        public void Load(LegacyTcpMessage message)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));
            Clear(false);
            byte operation = message.ReadByte();
            if (operation != 5)
                throw new InvalidDataException($"World battle replay expected /38 op=5, got op={operation}.");
            ushort packetCount = message.ReadUShort();
            for (int index = 0; index < packetCount; index++)
            {
                LegacyNestedPacket packet = message.ReadNestedPacket();
                if (packet.Command == 21) ReadEnter(packet.OpenBody());
                else if (packet.Command == 22) ReadAction(packet.OpenBody());
                else if (packet.Command == 23) ReadResult(packet.OpenBody());
            }
            if (message.Remaining != 0)
                throw new InvalidDataException($"World /38 replay has {message.Remaining} unread bytes.");
            HasAuthoritativeReplay = FightId != 0 && units.Count > 0 && actions.Count > 0;
            if (!HasAuthoritativeReplay)
                throw new InvalidDataException($"World /38 replay is incomplete: fight={FightId}, units={units.Count}, actions={actions.Count}.");
            Changed?.Invoke();
        }

        public void Clear() => Clear(true);

        private void Clear(bool notify)
        {
            FightId = 0;
            FightType = 0;
            CanSkip = false;
            MaxTurns = 0;
            FriendlyName = EnemyName = string.Empty;
            Won = false;
            HasAuthoritativeReplay = false;
            units.Clear();
            actions.Clear();
            parsedRound = 0;
            if (notify) Changed?.Invoke();
        }

        private void ReadEnter(LegacyTcpMessage message)
        {
            FightId = message.ReadUInt();
            FightType = message.ReadByte();
            message.ReadByte();
            message.ReadByte();
            message.ReadByte();
            CanSkip = message.ReadByte() != 0;
            MaxTurns = message.ReadUShort();
            message.ReadUShort();
            message.ReadUShort(); message.ReadByte();
            message.ReadUShort(); message.ReadByte();
            FriendlyName = message.ReadString();
            EnemyName = message.ReadString();
            int count = message.ReadByte();
            for (int index = 0; index < count; index++) units.Add(ReadUnit(message));
            if (message.Remaining != 0)
                throw new InvalidDataException($"World /21 enter battle has {message.Remaining} unread bytes.");
        }

        private static WorldBattleUnitRecord ReadUnit(LegacyTcpMessage message)
        {
            var unit = new WorldBattleUnitRecord
            {
                Type = message.ReadByte(),
                Position = message.ReadByte(),
                Picture = message.ReadUInt()
            };
            message.ReadUInt();
            unit.Name = message.ReadString();
            unit.Level = message.ReadUShort();
            if (unit.Type == 0)
            {
                unit.MaxHp = message.ReadULongInt();
                unit.CurrentHp = message.ReadULongInt();
                message.ReadByte();
                message.ReadByte();
                SkipState(message);
                unit.Quality = message.ReadByte();
                message.ReadByte();
            }
            else if (unit.Type == 2)
            {
                unit.MaxHp = message.ReadULongInt();
                unit.CurrentHp = message.ReadULongInt();
                SkipState(message);
                message.ReadUInt();
                unit.Quality = message.ReadByte();
                message.ReadByte();
                message.ReadByte();
            }
            else
            {
                message.ReadByte();
                unit.MaxHp = message.ReadULongInt();
                unit.CurrentHp = message.ReadULongInt();
                SkipState(message);
                int skills = message.ReadByte();
                for (int skill = 0; skill < skills; skill++) { message.ReadUShort(); message.ReadByte(); }
            }
            return unit;
        }

        private void ReadAction(LegacyTcpMessage message)
        {
            byte operation = message.ReadByte();
            if (operation != 1 || message.Remaining == 0) return;
            parsedRound++;
            byte actionCount = message.ReadByte();
            for (int index = 0; index < actionCount; index++)
            {
                WorldBattleActionRecord action = ReadActionRecord(message, actionCount);
                if (action.FirstActionType >= 1 && action.FirstActionType <= 3)
                {
                    action.Sequence = actions.Count + 1;
                    action.Round = parsedRound;
                    actions.Add(action);
                }
            }
            int turnStateCount = message.ReadByte();
            for (int index = 0; index < turnStateCount; index++)
            {
                message.ReadByte();
                SkipState(message);
            }
            if (message.Remaining != 0)
                throw new InvalidDataException($"World /22 battle action has {message.Remaining} unread bytes.");
        }

        private WorldBattleActionRecord ReadActionRecord(LegacyTcpMessage message, byte actionCount)
        {
            var action = new WorldBattleActionRecord
            {
                ActionCount = actionCount,
                FirstActionType = message.ReadByte()
            };
            switch (action.FirstActionType)
            {
                case 1:
                    action.FirstSourcePosition = message.ReadByte();
                    action.SkillId = message.ReadUShort();
                    int comboCount = message.ReadByte();
                    for (int combo = 0; combo < comboCount; combo++)
                    {
                        int targetCount = message.ReadByte();
                        for (int target = 0; target < targetCount; target++)
                        {
                            byte targetPosition = message.ReadByte();
                            if (action.FirstTargetPosition == 0) action.FirstTargetPosition = targetPosition;
                            bool hit = message.ReadByte() == 1;
                            if (hit)
                            {
                                AttackDamage damage = ReadAttackDamage(message);
                                if (targetPosition == action.FirstTargetPosition)
                                {
                                    action.FirstTargetHit = true;
                                    action.FirstTargetCritical = damage.Critical;
                                    action.FirstTargetDamage = damage.Damage;
                                }
                            }
                            byte targetState = ReadState(message);
                            if (targetPosition == action.FirstTargetPosition) action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceHpChanged = message.ReadInt();
                    message.ReadInt();
                    action.SourceHpRecovered = message.ReadInt();
                    action.SourceState = ReadState(message);
                    SkipAddedBuffs(message);
                    break;
                case 2:
                    action.FirstSourcePosition = message.ReadByte();
                    action.SkillId = message.ReadUShort();
                    int healTargetCount = message.ReadByte();
                    for (int target = 0; target < healTargetCount; target++)
                    {
                        byte targetPosition = message.ReadByte();
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = targetPosition;
                        bool critical = message.ReadByte() == 1;
                        uint healing = message.ReadUInt();
                        byte targetState = ReadState(message);
                        if (targetPosition == action.FirstTargetPosition)
                        {
                            action.FirstTargetHit = true;
                            action.FirstTargetCritical = critical;
                            action.FirstTargetHealing = healing;
                            action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceState = ReadState(message);
                    SkipAddedBuffs(message);
                    break;
                case 3:
                    action.FirstSourcePosition = message.ReadByte();
                    action.SkillId = message.ReadUShort();
                    int buffTargetCount = message.ReadByte();
                    for (int target = 0; target < buffTargetCount; target++)
                    {
                        byte targetPosition = message.ReadByte();
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = targetPosition;
                        bool active = message.ReadByte() == 1;
                        byte targetState = ReadState(message);
                        if (targetPosition == action.FirstTargetPosition)
                        {
                            action.FirstTargetHit = active;
                            action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceState = ReadState(message);
                    SkipAddedBuffs(message);
                    break;
                case 4:
                    int summonedCount = message.ReadByte();
                    for (int summoned = 0; summoned < summonedCount; summoned++)
                    {
                        WorldBattleUnitRecord unit = ReadUnit(message);
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = unit.Position;
                        units.RemoveAll(value => value.Position == unit.Position);
                        units.Add(unit);
                    }
                    break;
                case 5:
                    action.FirstSourcePosition = message.ReadByte();
                    message.ReadByte();
                    int runawayBuffCount = message.ReadByte();
                    if (runawayBuffCount > 0) message.ReadBytes(runawayBuffCount);
                    break;
                case 6:
                    action.FirstSourcePosition = message.ReadByte();
                    action.SkillId = message.ReadUShort();
                    message.ReadString();
                    int passiveTargetCount = message.ReadByte();
                    for (int target = 0; target < passiveTargetCount; target++)
                    {
                        byte targetPosition = message.ReadByte();
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = targetPosition;
                        message.ReadInt();
                        message.ReadInt();
                        message.ReadUInt();
                        SkipState(message);
                    }
                    break;
                case 7:
                    action.FirstSourcePosition = message.ReadByte();
                    message.ReadByte();
                    message.ReadString();
                    break;
                default:
                    throw new InvalidDataException($"Unsupported World battle action type {action.FirstActionType}.");
            }
            return action;
        }

        private readonly struct AttackDamage
        {
            public AttackDamage(bool critical, uint damage)
            {
                Critical = critical;
                Damage = damage;
            }

            public bool Critical { get; }
            public uint Damage { get; }
        }

        private static AttackDamage ReadAttackDamage(LegacyTcpMessage message)
        {
            if (message.ReadByte() > 0)
            {
                message.ReadUInt();
                message.ReadUInt();
                message.ReadUInt();
                SkipState(message);
            }
            bool critical = message.ReadByte() == 1;
            uint damage = message.ReadUInt();
            message.ReadUInt();
            message.ReadUInt();
            if (message.ReadByte() == 1)
            {
                message.ReadUInt();
                message.ReadUInt();
                message.ReadUInt();
            }
            if (message.ReadByte() == 1 && message.ReadByte() == 1)
            {
                message.ReadByte();
                message.ReadUInt();
                message.ReadUInt();
                message.ReadUInt();
            }
            return new AttackDamage(critical, damage);
        }

        private static void SkipAddedBuffs(LegacyTcpMessage message)
        {
            int count = message.ReadByte();
            for (int index = 0; index < count; index++)
            {
                message.ReadByte();
                message.ReadInt();
                message.ReadInt();
                message.ReadInt();
                SkipState(message);
            }
        }

        private void ReadResult(LegacyTcpMessage message)
        {
            message.ReadUInt();
            Won = message.ReadByte() == 1;
        }

        private static void SkipState(LegacyTcpMessage message)
        {
            ReadState(message);
        }

        private static byte ReadState(LegacyTcpMessage message)
        {
            byte state = message.ReadByte();
            SkipByteList(message);
            return state;
        }

        private static void SkipByteList(LegacyTcpMessage message)
        {
            int count = message.ReadByte();
            if (count > 0) message.ReadBytes(count);
        }
    }
}
