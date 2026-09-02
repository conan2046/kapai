using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public enum HeroEquipmentKind
    {
        Equipment = 1,
        FaBao = 2,
    }

    public readonly struct CultivationLevel
    {
        public CultivationLevel(int type, int level) { Type = type; Level = level; }
        public int Type { get; }
        public int Level { get; }
    }

    public readonly struct HeroEquipmentAffix
    {
        public HeroEquipmentAffix(uint seed, int id, int tier, int lockMask, string key, string name,
            string description, int value1, int value2)
        {
            Seed = seed;
            Id = id;
            Tier = tier;
            LockMask = lockMask;
            Key = key ?? string.Empty;
            Name = name ?? string.Empty;
            Description = description ?? string.Empty;
            Value1 = value1;
            Value2 = value2;
        }

        public uint Seed { get; }
        public int Id { get; }
        public int Tier { get; }
        public int LockMask { get; }
        public string Key { get; }
        public string Name { get; }
        public string Description { get; }
        public int Value1 { get; }
        public int Value2 { get; }
        public bool IsValid => Id > 0 && Tier > 0;
        public static HeroEquipmentAffix None => default;
    }

    public readonly struct HeroEquipmentRecord
    {
        public HeroEquipmentRecord(uint uid, int templateId, int formationPosition, uint experience,
            IReadOnlyList<CultivationLevel> cultivation, int baseAttributeType, uint baseAttributeValue,
            int strengthAttributeType, uint strengthAttributeValue, EquipmentDefinition definition,
            HeroEquipmentAffix affix)
        {
            Uid = uid;
            TemplateId = templateId;
            FormationPosition = formationPosition;
            Experience = experience;
            Cultivation = cultivation ?? Array.Empty<CultivationLevel>();
            BaseAttributeType = baseAttributeType;
            BaseAttributeValue = baseAttributeValue;
            StrengthAttributeType = strengthAttributeType;
            StrengthAttributeValue = strengthAttributeValue;
            Definition = definition ?? EquipmentDefinition.Missing(templateId, HeroEquipmentKind.Equipment);
            Affix = affix;
        }

        public uint Uid { get; }
        public int TemplateId { get; }
        public int FormationPosition { get; }
        public int Slot => Definition.Part;
        public uint Experience { get; }
        public IReadOnlyList<CultivationLevel> Cultivation { get; }
        public int BaseAttributeType { get; }
        public uint BaseAttributeValue { get; }
        public int StrengthAttributeType { get; }
        public uint StrengthAttributeValue { get; }
        public EquipmentDefinition Definition { get; }
        public HeroEquipmentAffix Affix { get; }
        public int GetLevel(int type) => Cultivation.FirstOrDefault(item => item.Type == type).Level;

        public HeroEquipmentRecord WithFormation(int formationPosition)
            => new HeroEquipmentRecord(Uid, TemplateId, formationPosition, Experience, Cultivation,
                BaseAttributeType, BaseAttributeValue, StrengthAttributeType, StrengthAttributeValue, Definition, Affix);
    }

    public readonly struct FaBaoRecord
    {
        public FaBaoRecord(uint uid, int templateId, int formationPosition, int slot, uint experience,
            IReadOnlyList<CultivationLevel> cultivation, EquipmentDefinition definition)
        {
            Uid = uid;
            TemplateId = templateId;
            FormationPosition = formationPosition;
            Slot = slot;
            Experience = experience;
            Cultivation = cultivation ?? Array.Empty<CultivationLevel>();
            Definition = definition ?? EquipmentDefinition.Missing(templateId, HeroEquipmentKind.FaBao);
        }

        public uint Uid { get; }
        public int TemplateId { get; }
        public int FormationPosition { get; }
        public int Slot { get; }
        public uint Experience { get; }
        public IReadOnlyList<CultivationLevel> Cultivation { get; }
        public EquipmentDefinition Definition { get; }
        public int GetLevel(int type) => Cultivation.FirstOrDefault(item => item.Type == type).Level;

        public FaBaoRecord WithFormation(int formationPosition, int slot)
            => new FaBaoRecord(Uid, TemplateId, formationPosition, slot, Experience, Cultivation, Definition);
    }

    public sealed class HeroEquipmentStore
    {
        private readonly Dictionary<uint, HeroEquipmentRecord> records = new Dictionary<uint, HeroEquipmentRecord>();
        public event Action Changed;
        public int Count => records.Count;
        public IReadOnlyList<HeroEquipmentRecord> Items => records.Values
            .OrderBy(item => item.FormationPosition == 0 ? int.MaxValue : item.FormationPosition)
            .ThenBy(item => item.Slot).ThenByDescending(item => item.Definition.Quality).ThenBy(item => item.Uid)
            .ToArray();

        public void Replace(IEnumerable<HeroEquipmentRecord> values)
        {
            records.Clear();
            foreach (HeroEquipmentRecord value in values ?? Array.Empty<HeroEquipmentRecord>())
                if (value.Uid > 0) records[value.Uid] = value;
            Changed?.Invoke();
        }

        public void Upsert(HeroEquipmentRecord value)
        {
            if (value.Uid == 0) return;
            records[value.Uid] = value;
            Changed?.Invoke();
        }

        public bool SetFormation(uint uid, int formationPosition)
        {
            if (!records.TryGetValue(uid, out HeroEquipmentRecord value)) return false;
            records[uid] = value.WithFormation(formationPosition);
            Changed?.Invoke();
            return true;
        }

        public bool TryGet(uint uid, out HeroEquipmentRecord value) => records.TryGetValue(uid, out value);
        public void Clear() { records.Clear(); Changed?.Invoke(); }
    }

    public sealed class FaBaoStore
    {
        private readonly Dictionary<uint, FaBaoRecord> records = new Dictionary<uint, FaBaoRecord>();
        public event Action Changed;
        public int Count => records.Count;
        public IReadOnlyList<FaBaoRecord> Items => records.Values
            .OrderBy(item => item.FormationPosition == 0 ? int.MaxValue : item.FormationPosition)
            .ThenBy(item => item.Slot).ThenByDescending(item => item.Definition.Quality).ThenBy(item => item.Uid)
            .ToArray();

        public void Replace(IEnumerable<FaBaoRecord> values)
        {
            records.Clear();
            foreach (FaBaoRecord value in values ?? Array.Empty<FaBaoRecord>())
                if (value.Uid > 0) records[value.Uid] = value;
            Changed?.Invoke();
        }

        public void Upsert(FaBaoRecord value)
        {
            if (value.Uid == 0) return;
            records[value.Uid] = value;
            Changed?.Invoke();
        }

        public bool SetFormation(uint uid, int formationPosition, int slot)
        {
            if (!records.TryGetValue(uid, out FaBaoRecord value)) return false;
            records[uid] = value.WithFormation(formationPosition, slot);
            Changed?.Invoke();
            return true;
        }

        public bool TryGet(uint uid, out FaBaoRecord value) => records.TryGetValue(uid, out value);
        public void Clear() { records.Clear(); Changed?.Invoke(); }
    }
}
