#pragma once
#include <climits>
#include <cstdint>
#include <cstdlib>
#include <map>
#include <string>
#include <utility>
#include <vector>
#include "rapidjson/document.h"

// reward.xlsx: type 1 rows always drop; type 2 rows share one weighted draw.
namespace UnityRewards {
template<class Award> struct Row {
    int weight = 0;
    std::vector<Award> awards;
    std::vector<int> maxAmounts;
};
template<class Award> struct Group {
    int weightSum = 0;
    std::vector<Row<Award>> awards;       // weighted candidates
    std::vector<Row<Award>> fixedAwards;  // optional; never placeholder rows
};
inline int RandomInclusive(int lo, int hi) {
    if (lo == hi) return lo;
    const std::uint64_t span = static_cast<std::uint64_t>(hi) - lo + 1;
    const std::uint64_t domain = std::uint64_t(1) << 45;
    const std::uint64_t limit = domain - domain % span;
    std::uint64_t value;
    do {
        value = (static_cast<std::uint64_t>(std::rand() & 32767) << 30)
              | (static_cast<std::uint64_t>(std::rand() & 32767) << 15)
              | static_cast<std::uint64_t>(std::rand() & 32767);
    } while (value >= limit);
    return lo + static_cast<int>(value % span);
}
template<class Award>
bool ReadRow(const rapidjson::Value& json, Row<Award>& row, int& mode, std::string& error) {
    if (!json.IsObject() || !json.HasMember("rewardid") || !json["rewardid"].IsInt() || json["rewardid"].GetInt() <= 0
        || !json.HasMember("reward") || !json["reward"].IsArray() || json["reward"].Empty()
        || !json.HasMember("weight") || !json["weight"].IsInt()) {
        error = "Invalid reward identity, content or weight"; return false;
    }
    // Older configs can still be read during an explicit, staged deployment.
    mode = 2;
    if (json.HasMember("drop_type")) {
        if (!json["drop_type"].IsInt()) { error = "drop_type must be integer"; return false; }
        mode = json["drop_type"].GetInt();
    }
    row = Row<Award>();
    row.weight = json["weight"].GetInt();
    if ((mode != 1 && mode != 2) || (mode == 1 && row.weight != 0) || (mode == 2 && row.weight <= 0)) {
        error = "Fixed rows require weight 0; random rows require positive weight"; return false;
    }
    for (auto it = json["reward"].Begin(); it != json["reward"].End(); ++it) {
        if (!it->IsArray() || (it->Size() != 3 && it->Size() != 4)) { error = "Reward item requires 3 or 4 integers"; return false; }
        for (rapidjson::SizeType i = 0; i < it->Size(); ++i)
            if (!(*it)[i].IsInt()) { error = "Reward item must contain integers"; return false; }
        Award a{};
        a.type = (*it)[0].GetInt(); a.typeId = (*it)[1].GetInt(); a.num = (*it)[2].GetInt();
        const int max = it->Size() == 4 ? (*it)[3].GetInt() : a.num;
        if (a.type <= 0 || a.typeId < 0 || a.num < 0 || max < a.num) { error = "Invalid reward amount interval"; return false; }
        row.awards.push_back(a); row.maxAmounts.push_back(max);
    }
    return true;
}
template<class Award>
bool AppendRow(Group<Award>& group, const Row<Award>& row, int mode) {
    if (mode == 1) group.fixedAwards.push_back(row);
    else {
        if (row.weight > INT_MAX - group.weightSum) return false;
        group.weightSum += row.weight; group.awards.push_back(row);
    }
    return true;
}
template<class Award, class Rng>
void RollRow(const Row<Award>& row, std::vector<Award>& result, Rng& random, bool allItems = true) {
    for (std::size_t i = 0; i < row.awards.size() && (allItems || i == 0); ++i) {
        Award a = row.awards[i];
        a.num = random(a.num, row.maxAmounts[i]);
        if (a.num > 0) result.push_back(a);
    }
}
template<class Award, class Rng>
bool Roll(const Group<Award>& group, int count, bool uniqueCandidates, bool allItems, std::vector<Award>& result, Rng random) {
    if (count < 1 || (uniqueCandidates && !group.awards.empty() && static_cast<std::size_t>(count) > group.awards.size())) return false;
    std::vector<Award> rolled;
    std::vector<bool> used(group.awards.size(), false);
    int remaining = group.weightSum;
    for (int draw = 0; draw < count; ++draw) {
        for (const auto& row : group.fixedAwards) RollRow(row, rolled, random);
        if (group.awards.empty()) continue;
        if (remaining <= 0) return false;
        int ticket = random(1, remaining);  // closed interval; zero cannot bias the first row
        std::size_t chosen = group.awards.size();
        for (std::size_t i = 0; i < group.awards.size(); ++i) {
            if (uniqueCandidates && used[i]) continue;
            if (ticket <= group.awards[i].weight) { chosen = i; break; }
            ticket -= group.awards[i].weight;
        }
        if (chosen == group.awards.size()) return false;
        RollRow(group.awards[chosen], rolled, random, allItems);
        if (uniqueCandidates) { used[chosen] = true; remaining -= group.awards[chosen].weight; }
    }
    result.swap(rolled); return true;
}
template<class Award>
bool MergeChecked(std::vector<Award>& target, const std::vector<Award>& incoming) {
    std::vector<Award> merged = target;
    for (const auto& award : incoming) {
        bool found = false;
        for (auto& old : merged) if (old.type == award.type && old.typeId == award.typeId) {
            if (award.num > INT_MAX - old.num) return false;
            old.num += award.num; found = true; break;
        }
        if (!found) merged.push_back(award);
    }
    target.swap(merged); return true;
}
} // namespace UnityRewards
