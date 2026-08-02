using System;

namespace ProjectX.Data
{
    public sealed class PlayerStore
    {
        public event Action Changed;

        public uint RoleId { get; private set; }
        public string Name { get; private set; } = string.Empty;
        public byte Sex { get; private set; }
        public byte Model { get; private set; }
        public byte Head { get; private set; }
        public ushort Level { get; private set; }
        public byte VipLevel { get; private set; }
        public ulong Experience { get; private set; }
        public ulong Power { get; private set; }
        public uint Potential { get; private set; }
        public uint Soul { get; private set; }
        public ushort PackageCapacity { get; private set; }
        public bool IsLoaded => RoleId != 0;
        public PlayerSummary Summary => new PlayerSummary(RoleId, Name, Level, Sex, Head, Power);

        public void Initialize(uint roleId, string name, byte sex, byte model, byte head, ushort level,
            ulong experience, ulong power, uint potential, uint soul, ushort packageCapacity)
        {
            RoleId = roleId;
            Name = name ?? string.Empty;
            Sex = sex;
            Model = model;
            Head = head;
            Level = level;
            Experience = experience;
            Power = power;
            Potential = potential;
            Soul = soul;
            PackageCapacity = packageCapacity;
            Changed?.Invoke();
        }

        public void AddExperience(uint amount)
        {
            Experience += amount;
            Changed?.Invoke();
        }

        public void SetLevelAndPower(ushort level, ulong power)
        {
            Level = level;
            Power = power;
            Changed?.Invoke();
        }

        public void SetPower(ulong value)
        {
            Power = value;
            Changed?.Invoke();
        }

        public void SetVipLevel(byte value)
        {
            VipLevel = value;
            Changed?.Invoke();
        }

        public void SetPotential(uint value)
        {
            Potential = value;
            Changed?.Invoke();
        }

        public void SetSoul(uint value)
        {
            Soul = value;
            Changed?.Invoke();
        }

        public void Clear()
        {
            RoleId = 0;
            Name = string.Empty;
            Sex = Model = Head = 0;
            Level = 0;
            VipLevel = 0;
            Experience = Power = 0;
            Potential = Soul = 0;
            PackageCapacity = 0;
            Changed?.Invoke();
        }
    }
}
