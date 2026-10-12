#include "../src/garden_growth.h"
#include <cassert>
#include <iostream>

int main()
{
    garden::Growth normal;garden::Advance(normal,1000,1000,2000);assert(normal.progress==12000000);
    garden::Growth water;water.waterAt=500;garden::Advance(water,500,1000,2000);assert(water.water);garden::Advance(water,1099,1000,2000);assert(water.progress<12000000);garden::Advance(water,1100,1000,2000);assert(water.progress==12000000&&!water.water);
    garden::Growth both;both.waterAt=500;both.bugAt=500;garden::Advance(both,1000,1000,2000);assert(both.water&&both.bug&&both.progress==11000000);both.water=false;both.waterAt=0;garden::Advance(both,1100,1000,2000);assert(both.progress==12000000); // bug alone still slows; penalties do not stack
    garden::Growth treated;treated.waterAt=500;garden::Advance(treated,600,1000,2000);treated.water=false;treated.waterAt=0;garden::Advance(treated,1016,1000,2000);assert(treated.progress<12000000);garden::Advance(treated,1017,1000,2000);assert(treated.progress==12000000);
    garden::Growth online,offline;online.waterAt=offline.waterAt=300;online.bugAt=offline.bugAt=600;for(int t=1;t<=1000;++t)garden::Advance(online,t,2000,2000);garden::Advance(offline,1000,2000,2000);assert(online.progress==offline.progress&&online.water==offline.water&&online.bug==offline.bug);
    garden::Growth changed;garden::Advance(changed,500,1000,2000);garden::Advance(changed,500,1000,3000);assert(changed.progress==6500000);garden::Advance(changed,1000,1000,3000);assert(changed.progress==13000000);
    int64_t before=changed.progress;garden::Advance(changed,1,1000,3000);assert(changed.progress==before);
    garden::Growth huge;garden::Advance(huge,86400000000LL,86400000000LL,100000);assert(huge.progress==9504000000000000LL);
    std::cout<<"Garden growth: normal, exact +20%, nonstacking, treatment, offline equivalence, configurable rescale, clock regression, overflow limits passed.\n";
}
