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
        public float ScaleRatio { get; set; } = 1f;
        public string Name { get; set; }
        public ushort Level { get; set; }
        public ulong MaxHp { get; set; }
        public ulong CurrentHp { get; set; }
        public byte Quality { get; set; }
        public byte State { get; set; }
        public byte[] BuffIds { get; set; } = Array.Empty<byte>();
        public ulong DamageDealt { get; set; }
        public ulong DamageTaken { get; set; }
        public ulong Healing { get; set; }
        public bool HasStatistics { get; set; }
        public bool IsEnemy => Position > 9;
    }

    public sealed class WorldBattleActionRecord
    {
        private readonly List<WorldBattleTargetRecord> targets = new List<WorldBattleTargetRecord>();
        private readonly List<WorldBattleUnitRecord> summonedUnits = new List<WorldBattleUnitRecord>();
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
        public byte[] SourceBuffIds { get; set; } = Array.Empty<byte>();
        public string Message { get; set; } = string.Empty;
        public bool FirstTargetDead => (FirstTargetState & 0x01) != 0;
        public bool SourceDead => (SourceState & 0x01) != 0;
        public IReadOnlyList<WorldBattleTargetRecord> Targets => targets;
        public IReadOnlyList<WorldBattleUnitRecord> SummonedUnits => summonedUnits;
        internal void AddTarget(WorldBattleTargetRecord target) => targets.Add(target);
        internal void AddSummonedUnit(WorldBattleUnitRecord unit) => summonedUnits.Add(unit);
    }

    public sealed class WorldBattleTargetRecord
    {
        public byte Position { get; set; }
        public bool Hit { get; set; }
        public bool Critical { get; set; }
        public uint Damage { get; set; }
        public uint Healing { get; set; }
        public byte State { get; set; }
        public byte[] BuffIds { get; set; } = Array.Empty<byte>();
        public byte ProtectorPosition { get; set; }
        public uint ProtectorDamage { get; set; }
        public uint ProtectorHealing { get; set; }
        public byte ProtectorState { get; set; }
        public byte[] ProtectorBuffIds { get; set; } = Array.Empty<byte>();
        public uint ReflectedDamage { get; set; }
        public uint ReflectedHealing { get; set; }
        public bool Countered { get; set; }
        public bool CounterHit { get; set; }
        public bool CounterCritical { get; set; }
        public uint CounterDamage { get; set; }
        public uint CounterHealing { get; set; }
        public bool Dead => (State & 0x01) != 0;
        public bool ProtectorDead => (ProtectorState & 0x01) != 0;
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
        public ushort CurrentTurn { get; private set; }
        public ushort Group1FormationId { get; private set; }
        public byte Group1FormationLevel { get; private set; }
        public ushort Group2FormationId { get; private set; }
        public byte Group2FormationLevel { get; private set; }
        public string FriendlyName { get; private set; } = string.Empty;
        public string EnemyName { get; private set; } = string.Empty;
        public bool Won { get; private set; }
        public IReadOnlyList<WorldBattleUnitRecord> Units => units;
        public IReadOnlyList<WorldBattleActionRecord> Actions => actions;
        public int StatisticsCount => units.Count(value => value.HasStatistics);
        public bool HasAuthoritativeReplay { get; private set; }

        public void Load(LegacyTcpMessage message, byte expectedOperation = 5)
        {
            if (message == null) throw new ArgumentNullException(nameof(message));
            Clear(false);
            byte operation = message.ReadByte();
            if (operation != expectedOperation)
                throw new InvalidDataException($"Battle replay expected /38 op={expectedOperation}, got op={operation}.");
            ushort packetCount = message.ReadUShort();
            for (int index = 0; index < packetCount; index++)
            {
                LegacyNestedPacket packet = message.ReadNestedPacket();
                if (packet.Command == 21) ReadEnter(packet.OpenBody());
                else if (packet.Command == 22) ReadAction(packet.OpenBody());
                else if (packet.Command == 23) ReadResult(packet.OpenBody());
            }
            if (message.Remaining != 0)
                throw new InvalidDataException($"Battle /38 op={expectedOperation} replay has {message.Remaining} unread bytes.");
            HasAuthoritativeReplay = FightId != 0 && units.Count > 0 && actions.Count > 0;
            if (!HasAuthoritativeReplay)
                throw new InvalidDataException($"Battle /38 op={expectedOperation} replay is incomplete: fight={FightId}, units={units.Count}, actions={actions.Count}.");
            Changed?.Invoke();
        }

        public void Clear() => Clear(true);

        private void Clear(bool notify)
        {
            FightId = 0;
            FightType = 0;
            CanSkip = false;
            MaxTurns = 0;
            CurrentTurn = 0;
            Group1FormationId = Group2FormationId = 0;
            Group1FormationLevel = Group2FormationLevel = 0;
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
            CurrentTurn = message.ReadUShort();
            Group1FormationId = message.ReadUShort();
            Group1FormationLevel = message.ReadByte();
            Group2FormationId = message.ReadUShort();
            Group2FormationLevel = message.ReadByte();
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
            unit.ScaleRatio = Math.Max(.01f, message.ReadUInt() / 100f);
            unit.Name = message.ReadString();
            unit.Level = message.ReadUShort();
            if (unit.Type == 0)
            {
                unit.MaxHp = message.ReadULongInt();
                unit.CurrentHp = message.ReadULongInt();
                message.ReadByte();
                message.ReadByte();
                unit.State = ReadState(message, out byte[] buffs);
                unit.BuffIds = buffs;
                unit.Quality = message.ReadByte();
                message.ReadByte();
            }
            else if (unit.Type == 2)
            {
                unit.MaxHp = message.ReadULongInt();
                unit.CurrentHp = message.ReadULongInt();
                unit.State = ReadState(message, out byte[] buffs);
                unit.BuffIds = buffs;
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
                unit.State = ReadState(message, out byte[] buffs);
                unit.BuffIds = buffs;
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
                if (action.FirstActionType >= 1 && action.FirstActionType <= 7)
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
                            AttackDamage damage = default;
                            if (hit)
                            {
                                damage = ReadAttackDamage(message);
                                if (targetPosition == action.FirstTargetPosition)
                                {
                                    action.FirstTargetHit = true;
                                    action.FirstTargetCritical = damage.Critical;
                                    action.FirstTargetDamage = damage.Damage;
                                }
                            }
                            byte targetState = ReadState(message, out byte[] targetBuffs);
                            action.AddTarget(new WorldBattleTargetRecord
                            {
                                Position = targetPosition,
                                Hit = hit,
                                Critical = hit && damage.Critical,
                                Damage = hit ? damage.Damage : 0,
                                State = targetState,
                                BuffIds = targetBuffs,
                                ProtectorPosition = damage.ProtectorPosition,
                                ProtectorDamage = damage.ProtectorDamage,
                                ProtectorHealing = damage.ProtectorHealing,
                                ProtectorState = damage.ProtectorState,
                                ProtectorBuffIds = damage.ProtectorBuffIds,
                                ReflectedDamage = damage.ReflectedDamage,
                                ReflectedHealing = damage.ReflectedHealing,
                                Countered = damage.Countered,
                                CounterHit = damage.CounterHit,
                                CounterCritical = damage.CounterCritical,
                                CounterDamage = damage.CounterDamage,
                                CounterHealing = damage.CounterHealing
                            });
                            if (targetPosition == action.FirstTargetPosition) action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceHpChanged = message.ReadInt();
                    message.ReadInt();
                    action.SourceHpRecovered = message.ReadInt();
                    action.SourceState = ReadState(message, out byte[] sourceBuffs1);
                    action.SourceBuffIds = sourceBuffs1;
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
                        byte targetState = ReadState(message, out byte[] targetBuffs);
                        action.AddTarget(new WorldBattleTargetRecord
                        {
                            Position = targetPosition,
                            Hit = true,
                            Critical = critical,
                            Healing = healing,
                            State = targetState,
                            BuffIds = targetBuffs
                        });
                        if (targetPosition == action.FirstTargetPosition)
                        {
                            action.FirstTargetHit = true;
                            action.FirstTargetCritical = critical;
                            action.FirstTargetHealing = healing;
                            action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceState = ReadState(message, out byte[] sourceBuffs2);
                    action.SourceBuffIds = sourceBuffs2;
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
                        byte targetState = ReadState(message, out byte[] targetBuffs);
                        action.AddTarget(new WorldBattleTargetRecord
                        {
                            Position = targetPosition,
                            Hit = active,
                            State = targetState,
                            BuffIds = targetBuffs
                        });
                        if (targetPosition == action.FirstTargetPosition)
                        {
                            action.FirstTargetHit = active;
                            action.FirstTargetState = targetState;
                        }
                    }
                    action.SourceState = ReadState(message, out byte[] sourceBuffs3);
                    action.SourceBuffIds = sourceBuffs3;
                    SkipAddedBuffs(message);
                    break;
                case 4:
                    int summonedCount = message.ReadByte();
                    for (int summoned = 0; summoned < summonedCount; summoned++)
                    {
                        WorldBattleUnitRecord unit = ReadUnit(message);
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = unit.Position;
                        if (action.FirstSourcePosition == 0) action.FirstSourcePosition = unit.Position;
                        action.AddSummonedUnit(unit);
                    }
                    break;
                case 5:
                    action.FirstSourcePosition = message.ReadByte();
                    action.FirstTargetPosition = action.FirstSourcePosition;
                    action.FirstTargetHit = message.ReadByte() == 1;
                    int runawayBuffCount = message.ReadByte();
                    if (runawayBuffCount > 0) message.ReadBytes(runawayBuffCount);
                    break;
                case 6:
                    action.FirstSourcePosition = message.ReadByte();
                    action.SkillId = message.ReadUShort();
                    action.Message = message.ReadString();
                    int passiveTargetCount = message.ReadByte();
                    for (int target = 0; target < passiveTargetCount; target++)
                    {
                        byte targetPosition = message.ReadByte();
                        if (action.FirstTargetPosition == 0) action.FirstTargetPosition = targetPosition;
                        int hpChanged = message.ReadInt();
                        message.ReadInt();
                        uint recovered = message.ReadUInt();
                        byte targetState = ReadState(message, out byte[] targetBuffs);
                        uint damage = hpChanged < 0 ? checked((uint)-(long)hpChanged) : 0;
                        uint healing = hpChanged > 0 ? checked((uint)hpChanged) : 0;
                        healing = checked(healing + recovered);
                        action.AddTarget(new WorldBattleTargetRecord
                        {
                            Position = targetPosition,
                            Hit = true,
                            Damage = damage,
                            Healing = healing,
                            State = targetState,
                            BuffIds = targetBuffs
                        });
                        if (targetPosition == action.FirstTargetPosition)
                        {
                            action.FirstTargetHit = true;
                            action.FirstTargetDamage = damage;
                            action.FirstTargetHealing = healing;
                            action.FirstTargetState = targetState;
                        }
                    }
                    break;
                case 7:
                    action.FirstSourcePosition = message.ReadByte();
                    action.FirstTargetPosition = action.FirstSourcePosition;
                    message.ReadByte();
                    action.Message = message.ReadString();
                    break;
                default:
                    throw new InvalidDataException($"Unsupported World battle action type {action.FirstActionType}.");
            }
            return action;
        }

        private readonly struct AttackDamage
        {
            public AttackDamage(byte protectorPosition, uint protectorDamage, uint protectorHealing,
                byte protectorState, byte[] protectorBuffIds, bool critical, uint damage, uint reflectedDamage,
                uint reflectedHealing, bool countered, bool counterHit, bool counterCritical,
                uint counterDamage, uint counterHealing)
            {
                ProtectorPosition = protectorPosition;
                ProtectorDamage = protectorDamage;
                ProtectorHealing = protectorHealing;
                ProtectorState = protectorState;
                ProtectorBuffIds = protectorBuffIds ?? Array.Empty<byte>();
                Critical = critical;
                Damage = damage;
                ReflectedDamage = reflectedDamage;
                ReflectedHealing = reflectedHealing;
                Countered = countered;
                CounterHit = counterHit;
                CounterCritical = counterCritical;
                CounterDamage = counterDamage;
                CounterHealing = counterHealing;
            }

            public byte ProtectorPosition { get; }
            public uint ProtectorDamage { get; }
            public uint ProtectorHealing { get; }
            public byte ProtectorState { get; }
            public byte[] ProtectorBuffIds { get; }
            public bool Critical { get; }
            public uint Damage { get; }
            public uint ReflectedDamage { get; }
            public uint ReflectedHealing { get; }
            public bool Countered { get; }
            public bool CounterHit { get; }
            public bool CounterCritical { get; }
            public uint CounterDamage { get; }
            public uint CounterHealing { get; }
        }

        private static AttackDamage ReadAttackDamage(LegacyTcpMessage message)
        {
            byte protectorPosition = message.ReadByte();
            uint protectorDamage = 0;
            uint protectorHealing = 0;
            byte protectorState = 0;
            byte[] protectorBuffIds = Array.Empty<byte>();
            if (protectorPosition > 0)
            {
                protectorDamage = message.ReadUInt();
                message.ReadUInt();
                protectorHealing = message.ReadUInt();
                protectorState = ReadState(message, out protectorBuffIds);
            }
            bool critical = message.ReadByte() == 1;
            uint damage = message.ReadUInt();
            message.ReadUInt();
            message.ReadUInt();
            uint reflectedDamage = 0;
            uint reflectedHealing = 0;
            if (message.ReadByte() == 1)
            {
                reflectedDamage = message.ReadUInt();
                message.ReadUInt();
                reflectedHealing = message.ReadUInt();
            }
            bool countered = message.ReadByte() == 1;
            bool counterHit = false;
            bool counterCritical = false;
            uint counterDamage = 0;
            uint counterHealing = 0;
            if (countered)
            {
                counterHit = message.ReadByte() == 1;
                if (counterHit)
                {
                    counterCritical = message.ReadByte() == 1;
                    counterDamage = message.ReadUInt();
                    message.ReadUInt();
                    counterHealing = message.ReadUInt();
                }
            }
            return new AttackDamage(protectorPosition, protectorDamage, protectorHealing,
                protectorState, protectorBuffIds, critical, damage, reflectedDamage, reflectedHealing,
                countered, counterHit, counterCritical, counterDamage, counterHealing);
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
            uint fightId = message.ReadUInt();
            if (FightId != 0 && fightId != FightId)
                throw new InvalidDataException($"Battle /23 result fight id mismatch: enter={FightId}, result={fightId}.");
            Won = message.ReadByte() == 1;
            int count = message.ReadByte();
            for (int index = 0; index < count; index++)
            {
                byte position = message.ReadByte();
                ulong damageDealt = message.ReadULongInt();
                ulong damageTaken = message.ReadULongInt();
                ulong healing = message.ReadULongInt();
                WorldBattleUnitRecord unit = units.FirstOrDefault(value => value.Position == position);
                if (unit == null)
                    throw new InvalidDataException($"Battle /23 statistics references unknown unit position {position}.");
                unit.DamageDealt = damageDealt;
                unit.DamageTaken = damageTaken;
                unit.Healing = healing;
                unit.HasStatistics = true;
            }
            if (message.Remaining != 0)
                throw new InvalidDataException($"Battle /23 result has {message.Remaining} unread bytes.");
        }

        private static void SkipState(LegacyTcpMessage message)
        {
            ReadState(message);
        }

        private static byte ReadState(LegacyTcpMessage message)
        {
            return ReadState(message, out _);
        }

        private static byte ReadState(LegacyTcpMessage message, out byte[] buffIds)
        {
            byte state = message.ReadByte();
            int count = message.ReadByte();
            buffIds = count > 0 ? message.ReadBytes(count) : Array.Empty<byte>();
            return state;
        }

        private static void SkipByteList(LegacyTcpMessage message)
        {
            int count = message.ReadByte();
            if (count > 0) message.ReadBytes(count);
        }
    }
}
