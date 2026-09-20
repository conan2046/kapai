#include "../../../server/src/hero_build.h"
#include <cassert>

int main()
{
    // Persisted values remain lossless, including the newly assigned 4/5 IDs.
    for (unsigned char branch = 0; branch <= 2; ++branch)
        for (unsigned char strategy = 0; strategy <= 5; ++strategy)
        {
            unsigned char saved = HeroBuild::Encode(branch, strategy);
            assert(HeroBuild::Branch(saved) == branch);
            assert(HeroBuild::Strategy(saved) == strategy);
            assert(HeroBuild::Valid(branch, strategy));
        }
    assert(!HeroBuild::Valid(3, 0));
    assert(!HeroBuild::Valid(0, 6));
    // Burst: a discounted 35-cost tactic costs 23; 43 is the exact threshold.
    assert(HeroBuild::CanSpend(4, 43, 23, false));
    assert(!HeroBuild::CanSpend(4, 42, 23, false));
    // Rescue bypasses reserve, never the actual resource requirement.
    assert(HeroBuild::CanSpend(1, 60, 60, true));
    assert(!HeroBuild::CanSpend(1, 59, 60, true));
    assert(!HeroBuild::CanSpend(1, 99, 60, false));
    assert(HeroBuild::CanSpend(1, 100, 60, false));
    // Unmigrated saves retain tactic affordability without a new reserve.
    assert(HeroBuild::CanSpend(0, 35, 35, false));
    assert(!HeroBuild::CanSpend(0, 34, 35, false));
    assert(!HeroBuild::CanSpend(0, 100, -1, false));
    return 0;
}
