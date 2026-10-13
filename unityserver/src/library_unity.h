#pragma once
#include "self_typedef.h"
#include "hero_cfg_manager.h"
#include <set>
#include <vector>
#include <string>
class CUser;
struct SUnityLibraryState {
    bool ready = false;
    int64 revision = 0;
    std::set<int> obtained, activated, rewards;
    std::vector<SAttrData> attributes;
};
class CUnityLibraryService {
public:
    static void Load(CUser* user);
    static void Handle(CUser* user, unsigned char operation, const std::string& payload);
    static void Obtained(CUser* user, int itemId, int count);
    static bool AutoSell(CUser* user, int itemId, int count);
    static void AddSourceAward(CUser* user, const std::string& eventKind, MultiAward& awards);
    static std::vector<SAttrData> CombatAttributes(CUser* user);
};
