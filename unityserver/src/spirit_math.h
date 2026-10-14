#pragma once
#include <cstdint>
#include <algorithm>
#include <limits>
#include <stdexcept>
#include <array>
#include <map>
#include <set>
#include <vector>
namespace spirit
{
    struct Wallet {int64_t amount=0,last=0,rate=0,remainder=0,period=5000,capacity=INT64_MAX,bonus=0,gainFraction=0;};
    inline void Accrue(Wallet& wallet,int64_t now)
    {
        if(wallet.amount<0||wallet.last<0||wallet.rate<0||wallet.rate>INT32_MAX||wallet.capacity<0||wallet.remainder<0||wallet.bonus<0||wallet.bonus>INT32_MAX||wallet.gainFraction<0||wallet.gainFraction>=10000||(wallet.period!=1000&&wallet.period!=5000)||wallet.remainder>=wallet.period)throw std::runtime_error("Invalid spirit wallet");
        if(wallet.last==0){wallet.last=now;return;}
        if(now<=wallet.last)return;
        if(wallet.period==5000){
            int64_t elapsed=now-wallet.last,ticks=elapsed/5000,partial=elapsed%5000+wallet.remainder;
            ticks+=partial/5000;partial%=5000;
            int64_t room=wallet.capacity> wallet.amount?wallet.capacity-wallet.amount:0;
            int64_t scaled=wallet.rate*(10000+wallet.bonus),whole=scaled/10000,minor=scaled%10000;
            if(whole&&ticks>room/whole){wallet.amount=wallet.capacity;wallet.remainder=0;wallet.gainFraction=0;}
            else{int64_t partialGain=minor*(ticks%10000)+wallet.gainFraction;int64_t base=ticks*whole,extra=(ticks/10000)*minor+partialGain/10000;wallet.amount+=base+std::min(room-base,extra);wallet.gainFraction=wallet.amount>=wallet.capacity?0:partialGain%10000;wallet.remainder=wallet.amount>=wallet.capacity?0:partial;}
            wallet.last=now;return;
        }
        int64_t elapsed=now-wallet.last,seconds=elapsed/1000,partial=elapsed%1000*wallet.rate+wallet.remainder;
        int64_t limit=std::numeric_limits<int64_t>::max()-wallet.amount;
        if(wallet.rate&&seconds>limit/wallet.rate)throw std::overflow_error("Spirit wallet overflow");
        int64_t gain=seconds*wallet.rate;
        if(partial/1000>limit-gain)throw std::overflow_error("Spirit wallet overflow");
        wallet.amount+=gain+partial/1000;wallet.remainder=partial%1000;wallet.last=now;
    }
    using PositionAttributes=std::array<std::map<int,int>,6>;
    inline void AddLevelAttributes(PositionAttributes& totals,const std::vector<int>& positions,const std::vector<std::pair<int,int>>& attributes)
    {
        std::set<int> slots,ids;
        for(int slot:positions)if(slot<1||slot>5||!slots.insert(slot).second)throw std::runtime_error("Invalid spirit target position");
        if(!attributes.empty()&&positions.empty())throw std::runtime_error("Spirit attributes require target positions");
        for(const auto& attr:attributes)if(attr.first<1||attr.first>33||attr.second<1||!ids.insert(attr.first).second)throw std::runtime_error("Invalid spirit level attribute");
        for(int slot:positions)for(const auto& attr:attributes){auto i=totals[slot].find(attr.first);int old=i==totals[slot].end()?0:i->second;if(attr.second>std::numeric_limits<int>::max()-old)throw std::overflow_error("Spirit position attribute overflow");}
        for(int slot:positions)for(const auto& attr:attributes)totals[slot][attr.first]+=attr.second;
    }
    inline int64_t Duration(int64_t base,int bp)
    {
        if(base<1||bp<0||bp>=10000)throw std::runtime_error("Invalid spirit duration");
        return (base/10000)*(10000-bp)+(base%10000*(10000-bp)+9999)/10000;
    }
    inline int64_t HarvestCount(int64_t base,int bp)
    {
        if(base<1||bp<0)throw std::runtime_error("Invalid spirit yield");
        int64_t rate=10000LL+bp;
        if(base>std::numeric_limits<int64_t>::max()/rate)throw std::overflow_error("Spirit yield overflow");
        return base*rate/10000;
    }
}
