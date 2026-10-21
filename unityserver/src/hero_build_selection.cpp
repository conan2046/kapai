#include "hero_build_selection.h"
#include "user.h"
#include "skill.h"
#include "utility.h"
#include "protocol.h"
#include "gyu/g_database.h"
#include <exception>
#include <chrono>
#include <filesystem>
#include <sqlite3.h>

namespace {
constexpr uint16 SaveKeyBase=61000;
constexpr uint8 SelectionMask=0x1f;
bool KnownHero(uint16 hero) {
    if(hero==0 || hero>65535-SaveKeyBase)return false;
    return SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(hero)!=nullptr;
}
uint8 Normalize(uint8 packed) {
    const uint8 strategy=(packed>>2)&7;
    // Retire only branch bits. Invalid strategies fall back independently.
    return static_cast<uint8>((packed&~SelectionMask)|(strategy<=5 ? strategy<<2 : 0));
}
void Decode(uint8 packed,uint8& branch,uint8& strategy) {
    branch=0;strategy=(Normalize(packed)>>2)&7;
}
bool BackupSqlite(const std::string& path) {
    const auto stamp=std::chrono::duration_cast<std::chrono::microseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    const std::string target=path+".before-ab-retirement-"+std::to_string(stamp)+".db";
    if(std::filesystem::exists(target))return false;
    sqlite3 *source=nullptr,*destination=nullptr;
    bool ok=sqlite3_open_v2(path.c_str(),&source,SQLITE_OPEN_READONLY,nullptr)==SQLITE_OK;
    if(ok)ok=sqlite3_open_v2(target.c_str(),&destination,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE,nullptr)==SQLITE_OK;
    if(ok) {
        sqlite3_backup* backup=sqlite3_backup_init(destination,"main",source,"main");
        ok=backup!=nullptr;
        if(backup) {
            const int step=sqlite3_backup_step(backup,-1);
            const int finish=sqlite3_backup_finish(backup);
            ok=step==SQLITE_DONE && finish==SQLITE_OK;
        }
    }
    if(destination)sqlite3_close(destination);
    if(source)sqlite3_close(source);
    if(ok)std::cout<<"[local] Hero selection backup="<<target<<std::endl;
    return ok;
}
}

bool CUnityHeroBuildService::MigrateLegacySelections(gyu::db::CDatabaseSql& database,const std::string& sqlitePath) {
    if(!database.IsSqlite() || SingletonCSkillMgr::instance().GetHeroSkillRoleCfgs().empty())return false;
    if(!database.Query("BEGIN IMMEDIATE"))return false;
    auto fail=[&]() {database.Query("ROLLBACK");return false;};
    try {
        if(!database.Query("SELECT id,bank_item FROM role_info ORDER BY id"))return fail();
        std::vector<std::pair<std::string,std::string>> updates;
        unsigned selections=0;
        while(char** row=database.GetRow()) {
            const std::string id=row[0] ? row[0] : "";
            const std::string bank=row[1] ? row[1] : "";
            if(bank.empty())continue;
            std::vector<uint8> bytes(10240);
            const int length=(bank.size()%2==0 && bank.find_first_not_of("0123456789abcdefABCDEF")==std::string::npos)
                ? UnCompressEx(bank.c_str(),bytes.data(),static_cast<uint32>(bytes.size())) : 0;
            if(id.empty() || id.find_first_not_of("0123456789")!=std::string::npos || length<2)return fail();
            const unsigned count=bytes[0]|(bytes[1]<<8);
            if(2+count*3>static_cast<unsigned>(length))return fail();
            unsigned changed=0;
            for(unsigned i=0;i<count;++i) {
                const unsigned offset=2+i*3;
                const uint16 key=bytes[offset]|(bytes[offset+1]<<8);
                if(key<=SaveKeyBase || !KnownHero(key-SaveKeyBase))continue;
                const uint8 normalized=Normalize(bytes[offset+2]);
                if(normalized!=bytes[offset+2]) {bytes[offset+2]=normalized;++changed;}
            }
            if(!changed)continue;
            std::string serialized;
            if(!Compress(bytes.data(),length,serialized))return fail();
            updates.emplace_back(id,serialized);selections+=changed;
        }
        // Back up committed data before the first mutation, under the writer lock.
        if(!updates.empty() && !BackupSqlite(sqlitePath))return fail();
        for(const auto& update:updates) {
            const std::string sql="UPDATE role_info SET bank_item='"+update.second+"' WHERE id="+update.first;
            if(!database.Query(sql.c_str()))return fail();
        }
        if(!database.Query("COMMIT"))return fail();
        std::cout<<"[local] Hero selections retired roles="<<updates.size()<<" selections="<<selections
            <<" strategies=preserved"<<std::endl;
        return true;
    }catch(const std::exception&) {return fail();}
}

bool CUnityHeroBuildService::ValidateOwner(CUser* user,uint16 hero,std::string& error) {
    if(!user || !user->GetRoleId()){error="请先登录角色";return false;}
    if(!KnownHero(hero)){error="该神将不支持自动策略配置";return false;}
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
    Decode(user->NoLockGetExtData8(SaveKeyBase+hero),savedBranch,savedStrategy);
    branch=savedBranch;strategy=savedStrategy;
    return true;
}

bool CUnityHeroBuildService::Save(CUser* user,uint16 hero,uint8 branch,uint8 strategy,std::string& error) {
    if(!user){error="请先登录角色";return false;}
    boost::recursive_mutex::scoped_lock lock(user->m_mutex);
    if(!ValidateOwner(user,hero,error))return false;
    if(branch!=0){error="A/B流派已停用，请使用原版技能并选择自动策略";return false;}
    if(strategy>5){error="无效的自动策略";return false;}
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
