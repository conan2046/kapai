#include "hero_build_selection.h"
#include "user.h"
#include "combat_data.h"
#include "protocol.h"
#include "gyu/g_database.h"
#include <exception>

namespace {
constexpr uint16 SaveKeyBase=61000;
constexpr uint8 SelectionMask=0x1f;
bool KnownHero(uint16 hero) {
    if(hero==0 || hero>65535-SaveKeyBase)return false;
    const auto& catalog=CombatData::Current();
    return catalog.Supports(hero,1,false) || catalog.Supports(hero,2,false);
}
bool Decode(uint8 packed,uint8& branch,uint8& strategy) {
    branch=packed&3;strategy=(packed>>2)&7;
    if(branch>2 || strategy>5){branch=strategy=0;return false;}
    return true;
}
}

bool CUnityHeroBuildService::ValidateOwner(CUser* user,uint16 hero,std::string& error) {
    if(!user || !user->GetRoleId()){error="请先登录角色";return false;}
    if(!KnownHero(hero)){error="该神将不支持流派选择";return false;}
    if(!user->GetPet(hero)){error="尚未招募该神将";return false;}
    return true;
}

bool CUnityHeroBuildService::ReadBattleSelection(CUser* user,uint16 hero,uint8& branch,uint8& strategy) {
    branch=strategy=0;
    if(!user)return false;
    boost::recursive_mutex::scoped_lock lock(user->m_mutex);
    std::string error;
    if(!ValidateOwner(user,hero,error))return false;
    uint8 savedBranch=0,savedStrategy=0;
    if(!Decode(user->NoLockGetExtData8(SaveKeyBase+hero),savedBranch,savedStrategy))return false;
    if(savedBranch && !CombatData::Current().Supports(hero,savedBranch))return false;
    branch=savedBranch;strategy=savedStrategy;
    return true;
}

bool CUnityHeroBuildService::Save(CUser* user,uint16 hero,uint8 branch,uint8 strategy,std::string& error) {
    if(!user){error="请先登录角色";return false;}
    boost::recursive_mutex::scoped_lock lock(user->m_mutex);
    if(!ValidateOwner(user,hero,error))return false;
    if(branch>2 || strategy>5){error="无效的流派或策略";return false;}
    if(branch && !CombatData::Current().Supports(hero,branch)){error="该流派尚未开放";return false;}
    const uint16 key=SaveKeyBase+hero;
    const auto previous=user->m_saveData8.find(key);
    const bool existed=previous!=user->m_saveData8.end();
    const uint8 old=existed?previous->second:0;
    const uint8 packed=static_cast<uint8>((old&~SelectionMask)|branch|(strategy<<2));
    if(packed==old)return true;
    user->m_saveData8[key]=packed;
    auto restore=[&]() {if(existed)user->m_saveData8[key]=old;else user->m_saveData8.erase(key);};
    try {
        // ExtData maps use the legacy bank_item codec, not fixed save_data arrays.
        std::string serialized;user->GetBankItem(serialized);
        if(serialized.empty() || serialized.find_first_not_of("0123456789abcdefABCDEF")!=std::string::npos){
            restore();error="保存失败，请重试";return false;
        }
        gyu::db::CGetDbConnect connection;
        auto* database=connection.GetDbConnect();
        const std::string sql="UPDATE role_info SET bank_item='"+serialized+"' WHERE id="+std::to_string(user->GetRoleId());
        if(!database || !database->Query(sql.c_str())){restore();error="保存失败，请重试";return false;}
    }catch(const std::exception&) {restore();error="保存失败，请重试";return false;}
    return true;
}

void CUnityHeroBuildService::Reply(CUser* user,uint8 operation,uint16 hero,bool success,const std::string& error,CNetMessage& message) {
    uint8 branch=0,strategy=0,available=0,effectiveBranch=0,effectiveStrategy=0;
    if(user) {
        boost::recursive_mutex::scoped_lock lock(user->m_mutex);
        std::string ownerError;
        if(ValidateOwner(user,hero,ownerError)) {
            Decode(user->NoLockGetExtData8(SaveKeyBase+hero),branch,strategy);
            available=1;
            if(CombatData::Current().Supports(hero,1))available|=2;
            if(CombatData::Current().Supports(hero,2))available|=4;
            ReadBattleSelection(user,hero,effectiveBranch,effectiveStrategy);
        }
    }
    message.ReWrite();message.SetType(PET_EQUIP_OPERATE);
    message<<operation<<static_cast<uint8>(success?1:0)<<hero<<branch<<strategy<<available<<effectiveBranch<<effectiveStrategy<<error;
}

void CUnityHeroBuildService::Handle(CUser* user,uint8 operation,CNetMessage& message) {
    const bool query=operation==QueryOperation;
    const bool validOperation=query || operation==SaveOperation;
    const bool validLength=message.GetDataLenExceptHead()==(query?3:5);
    uint16 hero=0;uint8 branch=0,strategy=0;
    if(validOperation && validLength){message>>hero;if(!query)message>>branch>>strategy;}
    std::string error;
    bool success=false;
    if(!validOperation || !validLength)error="无效的选择请求";
    else if(query)success=ValidateOwner(user,hero,error);
    else success=Save(user,hero,branch,strategy,error);
    Reply(user,operation,hero,success,error,message);
}
