#ifndef PROJECTX_HERO_BUILD_H
#define PROJECTX_HERO_BUILD_H

// Persisted in the existing role save_data map. Zero preserves legacy combat.
namespace HeroBuild
{
    inline bool Supported(unsigned short hero)
    {
        return hero >= 10 && hero <= 68;
    }
    inline unsigned short SaveKey(unsigned short hero) { return 61000 + hero; }
    inline bool Valid(unsigned char branch, unsigned char strategy)
    { return branch <= 2 && strategy <= 5; }
    inline unsigned char Encode(unsigned char branch, unsigned char strategy)
    { return branch | (strategy << 2); }
    inline unsigned char Branch(unsigned char value) { return value & 3; }
    inline unsigned char Strategy(unsigned char value) { return (value >> 2) & 7; }
    // 0 = legacy; 1 = rescue; 2 = guard; 3 = control;
    // 4 = burst; 5 = damage over time. These IDs are persisted protocol values.
    inline int Reserve(unsigned char strategy)
    {
        if (strategy == 1) return 40;
        if (strategy == 2 || strategy == 3) return 30;
        if (strategy == 4 || strategy == 5) return 20;
        return 0;
    }
    inline bool CanSpend(unsigned char strategy, int rage, int cost, bool emergency)
    {
        return cost >= 0 && rage >= cost
            && (emergency || rage - cost >= Reserve(strategy));
    }
}
#endif
