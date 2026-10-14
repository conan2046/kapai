#pragma once
#include "self_typedef.h"
#include "hero_cfg_manager.h"
#include <array>
#include <vector>
#include <string>
class CUser;
namespace gyu { namespace db { class CDatabaseSql; } }
struct SUnityAlchemyBonus {
    int cultivation=0,spirit=0;
    std::array<std::vector<SAttrData>,6> positions;
};
class CUnityAlchemyService {
public:
    static void Load(CUser* user);
    static void Handle(CUser* user,unsigned char operation,const std::string& payload);
    static bool IsItem(int item);
    static void UseFromBag(CUser* user,int item,int quantity);
    static int CultivationBonus(CUser* user);
    static int SpiritBonus(CUser* user);
    static std::vector<SAttrData> CombatAttributes(CUser* user,int position);
    static bool OverflowMail(CUser* user,int item,int count,const char* message);
};
