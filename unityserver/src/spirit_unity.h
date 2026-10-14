#pragma once
#include "self_typedef.h"
#include <vector>
#include <array>
#include "hero_cfg_manager.h"
#include "spirit_math.h"
class CUser;
struct SUnitySpiritBonus { int growth=0,yield=0;std::array<std::vector<SAttrData>,6> positionAttributes; };
class CUnitySpiritService
{
public:
    static void Load(CUser* user);
    static bool ChangeResource(CUser* user,int64 amount);
    static int64 Resource(CUser* user);
    static SUnitySpiritBonus Bonus(CUser* user);
    static int CraftReduction(CUser* user);
    static std::vector<SAttrData> CombatAttributes(CUser* user,int position);
    static void Handle(CUser* user,unsigned char operation,const std::string& payload);
};
