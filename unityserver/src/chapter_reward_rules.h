#pragma once
#include <cstddef>
namespace ChapterRewardRules {
inline unsigned BossPackage(unsigned mode, unsigned nodeType, unsigned packageId) {
    return mode == 2 && nodeType == 3 ? packageId : 0;
}

template<class StarMap, class Id>
bool Contains(const StarMap& configured, Id id) {
    if (id == 0) return false;
    for (const auto& entry : configured) if (entry.second == id) return true;
    return false;
}
template<class StarMap, class Id, class Stars>
bool Eligible(const StarMap& configured, Id id, Stars earned) {
    if (id == 0) return false;
    for (const auto& entry : configured)
        if (entry.second == id && earned >= entry.first) return true;
    return false;
}
template<class StarMap, class IdSet, class Stars>
std::size_t PendingCount(const StarMap& configured, const IdSet& pending, Stars earned) {
    std::size_t count = 0;
    for (const auto id : pending) if (Eligible(configured, id, earned)) ++count;
    return count;
}
}
