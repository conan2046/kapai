#include "global_event.h"
#include "story_unity.h"
#include "utility.h"
#include "init.h"
#include "user_guanqia.h"
#include "user.h"
#include "mission_manager.h"
#include "pet_equip_manage.h"
#include <iostream>

void CGlobalEventManager::Publish(CUser* user,std::uint16_t type,int value,int parameter)const
{sCMissionManager.OnGlobalEvent(user,type,value,parameter);CUnityStoryService::OnEvent(user,type,value,parameter);}

CGlobalEventManager& GlobalEvents(){static CGlobalEventManager manager;return manager;}
bool CGlobalEventManager::Init()
{
    const char* keys[]={"id","type","num","param1","param2","count_start","cycle","enabled"};
    const int types[]={0,0,0,0,0,0,0,0};
    rapidjson::Document doc;rapidjson::Value rows;
    if(!LoadJosnValue("event.json",keys,types,8,doc,rows))return false;
    std::map<std::uint32_t,GlobalEventDefinition> loaded;
    for(rapidjson::SizeType i=0;i<rows.Size();++i){
        const auto& r=rows[i];GlobalEventDefinition e;
        e.id=r["id"].GetUint();e.type=static_cast<std::uint16_t>(r["type"].GetUint());
        e.num=r["num"].GetUint();e.param1=r["param1"].GetUint();e.param2=r["param2"].GetUint();
        e.countStart=static_cast<std::uint8_t>(r["count_start"].GetUint());
        e.cycle=static_cast<std::uint8_t>(r["cycle"].GetUint());
        if(r["enabled"].GetInt()!=1||!e.id||!e.num||!GlobalEventRules::Supported(e.type)
            ||(e.param2!=0&&e.type!=1006&&e.type!=1008)||(e.type==1006&&e.param2>5)||(e.type==1008&&e.param2>4)||e.cycle>1||e.countStart<1||e.countStart>3
            ||(e.countStart==1 && !(e.type==30 || e.type==1006 || e.type==1008 || (e.type==40&&e.num==1)))
            ||(e.cycle==1)!=(e.countStart==3)||!loaded.emplace(e.id,e).second){
            std::cerr<<"Invalid/unsupported global event "<<e.id<<std::endl;return false;
        }
    }
    if(loaded.empty())return false;events.swap(loaded);snapshotTypes.clear();
    for(const auto& entry:events)if(entry.second.countStart==1)snapshotTypes.insert(entry.second.type);
    return true;
}
bool CGlobalEventManager::ReadCurrent(CUser* user,const GlobalEventDefinition& e,std::uint32_t& progress)const
{
    if(!user)return false;
    if(e.type==1006){progress=0;if(e.param1){progress=user->HavePet(e.param1)&&(!e.param2||user->GetPetZhenFaIdx(e.param1)==e.param2)?1:0;}else{std::vector<SZhenFaMemData> members;user->GetZhenFaMember(members);for(const auto& m:members){auto pos=user->GetPetZhenFaIdx(m.mem_id);if(pos&&(!e.param2||pos==e.param2))++progress;}}return true;}
    if(e.type==1008){progress=0;for(const auto& x:user->GetPetEquipMgr().GetPetEquips()){const auto& v=x.second;if(v.fpos&&(!e.param1||v.fpos==e.param1)&&(!e.param2||v.wpos==e.param2))++progress;}return true;}
    if(e.type==30){progress=user->GetLevel();return true;}
    if(e.type==40 && e.num==1){
        auto map=sCGuanQiaCfgMgr.GetNodeMapId(e.param1);
        auto chapter=sCGuanQiaCfgMgr.GetZhangJieCfg(map);
        progress=chapter && user->GetGuanQia().GetNodeStar(chapter->type,map,e.param1)>0 ? 1 : 0;
        return true;
    }
    return false;
}
const GlobalEventDefinition* CGlobalEventManager::Get(std::uint32_t id)const
{auto it=events.find(id);return it==events.end()?nullptr:&it->second;}
bool CGlobalEventManager::Advance(CUser* user,std::uint32_t id,std::uint32_t& progress,int value,int parameter)const
{auto e=Get(id);return e&&Advance(user,*e,progress,value,parameter);}
bool CGlobalEventManager::Advance(CUser* user,const GlobalEventDefinition& e,std::uint32_t& progress,int value,int parameter)const
{
    if(e.type==1006||e.type==1008)return ReadCurrent(user,e,progress);
    std::uint32_t state=0;bool hasState=GlobalEventRules::IsStateQuery(e.type);
    if(hasState){
        if(!user)return false;
        switch(e.type){
        case 20:state=user->GetHeroBreakNum(e.param1);break;
        case 21:state=user->GetHeroStarNum(e.param1);break;
        case 25:state=user->GetPowerPetCnt(e.param1);break;
        case 41:state=user->GetQualityPetCnt(e.param1);break;
        case 42:state=user->GetPetEquipMgr().GetYCLevelCnt(EST_QIANGHUA,e.param1);break;
        case 45:state=user->GetPetEquipMgr().GetYCLevelCnt(EST_JINGLIAN,e.param1);break;
        case 48:state=user->GetPetEquipMgr().GetYCLevelCnt(EST_FBQIANGHUA,e.param1);break;
        case 49:state=user->GetPetEquipMgr().GetYCLevelCnt(EST_FBJINGLIAN,e.param1);break;
        }
    }
    return GlobalEventRules::Advance(e,progress,value,parameter,hasState,state);
}
int ValidateGlobalEventConfiguration()
{
    // Run before main's InitDB: config loading and pure counters only.
    if(!sCMissionManager.Init())return 1;
    auto& tasks=sCMissionManager.GetAllQuest();
    for(const auto& entry:tasks){
        const auto& task=entry.second;auto e=GlobalEvents().Get(task.eventId);
        if(!e||e->type!=task.type||e->num!=task.num||e->param1!=task.cond||e->param2!=task.condex)return 2;
    }
    auto sample=GlobalEvents().Get(1001);
    std::cout<<"{\"events\":"<<GlobalEvents().Size()<<",\"tasks\":"<<tasks.size()
        <<",\"sample_1001_target\":"<<(sample?sample->num:0)<<",\"inline_conditions\":0}"<<std::endl;
    return 0;
}
