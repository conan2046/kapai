#ifndef PROJECTX_GARDEN_GROWTH_H
#define PROJECTX_GARDEN_GROWTH_H
#include <algorithm>
#include <cstdint>
#include <limits>

namespace garden
{
    // Integer work units preserve the exact configured duration extension.
    // The scale is persisted, so changing the table does not reinterpret old work.
    struct Growth
    {
        int64_t progress=0,last=0,waterAt=0,bugAt=0;
        int scale=0;
        bool water=false,bug=false;
    };
    inline void Advance(Growth& g,int64_t now,int64_t duration,int extensionBp)
    {
        if(duration<=0)return;
        int nextScale=10000+extensionBp;
        if(g.scale>0 && g.scale!=nextScale)g.progress=(g.progress/g.scale)*nextScale+(g.progress%g.scale)*nextScale/g.scale;
        g.scale=nextScale;
        if(now<=g.last)return;
        int64_t target=duration*g.scale;
        while(g.last<now && g.progress<target)
        {
            if(g.waterAt>0 && g.waterAt<=g.last)g.water=true;
            if(g.bugAt>0 && g.bugAt<=g.last)g.bug=true;
            int64_t end=now;
            if(!g.water && g.waterAt>g.last)end=std::min(end,g.waterAt);
            if(!g.bug && g.bugAt>g.last)end=std::min(end,g.bugAt);
            int64_t remaining=target-g.progress;
            int64_t rate=(g.water || g.bug)?10000:g.scale;
            int64_t elapsed=std::min(end-g.last,(remaining+rate-1)/rate);
            g.progress=std::min(target,g.progress+elapsed*rate);
            g.last+=elapsed;
        }
        g.last=now;
        if(g.progress>=target){g.water=false;g.bug=false;}
        else
        {
            if(g.waterAt>0 && g.waterAt<=now)g.water=true;
            if(g.bugAt>0 && g.bugAt<=now)g.bug=true;
        }
    }
    inline int64_t Remaining(const Growth& g,int64_t duration,int extensionBp)
    { int scale=g.scale>0?g.scale:10000+extensionBp;int64_t n=std::max<int64_t>(0,duration*scale-g.progress),rate=(g.water||g.bug)?10000:scale;return (n+rate-1)/rate; }
}
#endif
