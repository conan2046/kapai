#include "combat_data.h"
#include <algorithm>
#include <set>
#include <stdexcept>

namespace CombatData {
Loadout Catalog::Snapshot(const std::vector<WornItem>& input) const {
    Loadout result;
    auto worn=input;
    std::sort(worn.begin(),worn.end(),[&](const WornItem& a,const WornItem& b){
        auto x=slots_.find(a.slot),y=slots_.find(b.slot);
        return (x==slots_.end()?0:x->second.second)<(y==slots_.end()?0:y->second.second);
    });
    std::set<int> seenSlots;
    std::set<std::pair<bool,uint32_t>> seenInstances;
    std::map<std::string,const Artifact*> winners;
    for(const auto& item:worn) {
        auto slot=slots_.find(item.slot);
        if(slot==slots_.end() || !item.instance) continue;
        if(!seenSlots.insert(item.slot).second) throw std::runtime_error("duplicate combat loadout slot");
        if(!seenInstances.insert({item.artifact,item.instance}).second) continue;
        if(item.artifact) {
            if(slot->second.first!="artifact") continue;
            auto found=artifacts_.find(item.id);
            if(found==artifacts_.end()) throw std::runtime_error("equipped artifact missing combat binding");
            const auto& a=found->second;
            auto& best=winners[a.exclusive];
            if(!best || a.rank>best->rank) best=&a;
        } else if(slot->second.first=="equipment" && item.part==item.slot && item.suit>0) ++result.pieces[item.suit];
    }
    auto add=[&](int group,int value){
        if(!result.groups.emplace(group,value).second) throw std::runtime_error("conflicting equipped effect groups");
    };
    for(const auto& winner:winners) {
        const auto& a=*winner.second; result.artifacts[winner.first]=a.id;
        // Selection happens before activation; an incomplete high-rank item
        // must never silently activate a lower-rank item's different mechanism.
        if(a.enabled) add(a.group,a.value);
    }
    for(const auto& s:sets_) if(s.enabled && result.pieces[s.suit]>=s.pieces) add(s.group,s.value);
    return result;
}
}
