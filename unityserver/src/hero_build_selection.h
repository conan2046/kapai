#pragma once
#include "self_typedef.h"

class CUser;

class CUnityHeroBuildService {
public:
    static constexpr uint8 QueryOperation=43;
    static constexpr uint8 SaveOperation=44;
    static void Handle(CUser* user,uint8 operation,CNetMessage& message);
    // Shared by protocol previews and the production AddPet snapshot.
    static bool ReadBattleSelection(CUser* user,uint16 hero,uint8& branch,uint8& strategy);
private:
    static bool ValidateOwner(CUser* user,uint16 hero,std::string& error);
    static bool Save(CUser* user,uint16 hero,uint8 branch,uint8 strategy,std::string& error);
    static void Reply(CUser* user,uint8 operation,uint16 hero,bool success,const std::string& error,CNetMessage& message);
};
