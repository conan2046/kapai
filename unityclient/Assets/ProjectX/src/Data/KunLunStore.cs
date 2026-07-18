using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class KunLunEnemyRecord
    {
        public KunLunEnemyRecord(byte position, uint roleId, string name, byte profession, byte sex,
            ushort level, uint power, bool robot, byte state, int healthPercent)
        {
            Position = position;
            RoleId = roleId;
            Name = name ?? string.Empty;
            Profession = profession;
            Sex = sex;
            Level = level;
            Power = power;
            Robot = robot;
            State = state;
            HealthPercent = healthPercent;
        }

        public byte Position { get; }
        public uint RoleId { get; }
        public string Name { get; }
        public byte Profession { get; }
        public byte Sex { get; }
        public ushort Level { get; }
        public uint Power { get; }
        public bool Robot { get; }
        public byte State { get; }
        public int HealthPercent { get; }
    }

    public sealed class KunLunStore
    {
        private readonly List<KunLunEnemyRecord> enemies = new List<KunLunEnemyRecord>();

        public event Action Changed;
        public byte Floor { get; private set; }
        public byte RemainingFights { get; private set; }
        public byte RemainingBuys { get; private set; }
        public byte CurrentPosition { get; private set; }
        public IReadOnlyList<KunLunEnemyRecord> Enemies => enemies;
        public bool HasAuthoritativeResponse { get; private set; }

        public void Replace(byte floor, byte remainingFights, byte remainingBuys, byte currentPosition,
            IEnumerable<KunLunEnemyRecord> values)
        {
            Floor = floor;
            RemainingFights = remainingFights;
            RemainingBuys = remainingBuys;
            CurrentPosition = currentPosition;
            enemies.Clear();
            if (values != null) enemies.AddRange(values);
            HasAuthoritativeResponse = true;
            Changed?.Invoke();
        }

        public void Clear()
        {
            Floor = RemainingFights = RemainingBuys = CurrentPosition = 0;
            enemies.Clear();
            HasAuthoritativeResponse = false;
            Changed?.Invoke();
        }
    }
}
