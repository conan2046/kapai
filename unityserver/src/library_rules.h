#pragma once
#include <algorithm>
#include <cstdint>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

namespace library {
inline bool Satisfied(const std::string& kind, int count, const std::vector<int>& required,
                      const std::vector<int>& members, const std::set<int>& activated) {
    const int collected = static_cast<int>(std::count_if(members.begin(), members.end(),
        [&](int id) { return activated.count(id) != 0; }));
    if (kind == "count") return count > 0 && collected >= count;
    if (kind == "complete") return !members.empty() && collected == static_cast<int>(members.size());
    if (kind == "combination") return required.size() >= 2 && std::all_of(required.begin(), required.end(),
        [&](int id) { return activated.count(id) != 0; });
    if (kind == "book") return required.size() == 1 && activated.count(required.front()) != 0;
    throw std::runtime_error("藏书奖励条件类型错误");
}
inline int64_t Sale(int price, int count) {
    if (price < 0 || count < 1) throw std::runtime_error("藏书出售价格或数量错误");
    return static_cast<int64_t>(price) * count;
}
}
