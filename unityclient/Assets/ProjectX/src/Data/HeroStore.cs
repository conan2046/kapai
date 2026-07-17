using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjectX.Data
{
    public readonly struct HeroRecord
    {
        public HeroRecord(int id, int fightPosition, string name, int star, int breakLevel, int level,
            uint experience, uint maxExperience, ulong power, uint attack, uint physicalDefense,
            uint magicDefense, ulong health, uint speed)
        {
            Id = id;
            FightPosition = fightPosition;
            Name = string.IsNullOrEmpty(name) ? $"神将 #{id}" : name;
            Star = star;
            BreakLevel = breakLevel;
            Level = level;
            Experience = experience;
            MaxExperience = maxExperience;
            Power = power;
            Attack = attack;
            PhysicalDefense = physicalDefense;
            MagicDefense = magicDefense;
            Health = health;
            Speed = speed;
        }

        public int Id { get; }
        public int FightPosition { get; }
        public string Name { get; }
        public int Star { get; }
        public int BreakLevel { get; }
        public int Level { get; }
        public uint Experience { get; }
        public uint MaxExperience { get; }
        public ulong Power { get; }
        public uint Attack { get; }
        public uint PhysicalDefense { get; }
        public uint MagicDefense { get; }
        public ulong Health { get; }
        public uint Speed { get; }
    }

    public sealed class HeroStore
    {
        private readonly Dictionary<int, HeroRecord> records = new Dictionary<int, HeroRecord>();
        public event Action Changed;
        public int FollowHeroId { get; private set; }
        public int Count => records.Count;
        public IReadOnlyList<HeroRecord> Items => records.Values
            .OrderBy(hero => hero.FightPosition <= 0 ? int.MaxValue : hero.FightPosition)
            .ThenByDescending(hero => hero.Power)
            .ThenBy(hero => hero.Id)
            .ToArray();

        public void Replace(int followHeroId, IEnumerable<HeroRecord> values)
        {
            FollowHeroId = followHeroId;
            records.Clear();
            foreach (HeroRecord value in values ?? Array.Empty<HeroRecord>()) records[value.Id] = value;
            Changed?.Invoke();
        }

        public void SetFightPositions(IReadOnlyDictionary<int, int> positions)
        {
            foreach (int id in records.Keys.ToArray())
            {
                HeroRecord old = records[id];
                int position = positions != null && positions.TryGetValue(id, out int value) ? value : 0;
                records[id] = new HeroRecord(old.Id, position, old.Name, old.Star, old.BreakLevel, old.Level,
                    old.Experience, old.MaxExperience, old.Power, old.Attack, old.PhysicalDefense,
                    old.MagicDefense, old.Health, old.Speed);
            }
            Changed?.Invoke();
        }

        public bool TryGet(int id, out HeroRecord value) => records.TryGetValue(id, out value);
        public void Clear() { FollowHeroId = 0; records.Clear(); Changed?.Invoke(); }
    }

    public readonly struct FormationRecord
    {
        public FormationRecord(int id, int level) { Id = id; Level = level; }
        public int Id { get; }
        public int Level { get; }
    }

    public sealed class FormationStore
    {
        private readonly List<FormationRecord> formations = new List<FormationRecord>();
        private readonly List<int> displayHeroes = new List<int>();
        private readonly List<int> combatHeroes = new List<int>();
        public event Action Changed;
        public int ActiveFormationId { get; private set; }
        public IReadOnlyList<FormationRecord> Formations => formations;
        public IReadOnlyList<int> DisplayHeroes => displayHeroes;
        public IReadOnlyList<int> CombatHeroes => combatHeroes;

        public void Replace(int activeId, IEnumerable<FormationRecord> values,
            IEnumerable<int> display, IEnumerable<int> combat)
        {
            ActiveFormationId = activeId;
            formations.Clear(); formations.AddRange(values ?? Array.Empty<FormationRecord>());
            displayHeroes.Clear(); displayHeroes.AddRange(display ?? Array.Empty<int>());
            combatHeroes.Clear(); combatHeroes.AddRange(combat ?? Array.Empty<int>());
            Changed?.Invoke();
        }

        public int GetCombatPosition(int heroId)
        {
            int index = combatHeroes.IndexOf(heroId);
            return index < 0 ? 0 : index + 1;
        }

        public void Clear()
        {
            ActiveFormationId = 0;
            formations.Clear(); displayHeroes.Clear(); combatHeroes.Clear();
            Changed?.Invoke();
        }
    }
}
