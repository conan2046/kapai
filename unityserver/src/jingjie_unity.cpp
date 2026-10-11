#include "jingjie_unity.h"
#include "user.h"
#include "init.h"
#include "singleton.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#include <algorithm>
#include <chrono>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <vector>

namespace
{
    typedef rapidjson::Value Json;
    typedef rapidjson::Document::AllocatorType Alloc;
    const char* StateSchema =
        "CREATE TABLE IF NOT EXISTS unity_jingjie_state("
        "role_id INTEGER PRIMARY KEY REFERENCES role_info(id) ON DELETE CASCADE,version INTEGER NOT NULL DEFAULT 2,"
        "current_id INTEGER NOT NULL DEFAULT 1,experience TEXT NOT NULL DEFAULT '0',failure_count INTEGER NOT NULL DEFAULT 0,"
        "last_ms INTEGER NOT NULL DEFAULT 0,cycle_ms INTEGER NOT NULL DEFAULT 0,fraction INTEGER NOT NULL DEFAULT 0,"
        "revision INTEGER NOT NULL DEFAULT 0,attempt INTEGER NOT NULL DEFAULT 0,entered INTEGER NOT NULL DEFAULT 0,"
        "pending TEXT NOT NULL DEFAULT '',last_request TEXT NOT NULL DEFAULT '',last_result TEXT NOT NULL DEFAULT '',"
        "offline TEXT NOT NULL DEFAULT '',legacy_level INTEGER NOT NULL DEFAULT 1,legacy_id INTEGER NOT NULL DEFAULT 0,"
        "legacy_experience TEXT NOT NULL DEFAULT '0');";
    std::string Quote(const std::string& value)
    {
        std::string out="'";for(char c:value){out+=c;if(c=='\'')out+='\'';}return out+"'";
    }
    void String(Json& target,const char* key,const std::string& value,Alloc& allocator)
    { target.AddMember(Json(key,allocator),Json(value.c_str(),allocator),allocator); }
    std::string Encode(const Json& value)
    { rapidjson::StringBuffer buffer;rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);value.Accept(writer);return buffer.GetString(); }
    void Nested(Json& target,const char* key,const std::string& encoded,Alloc& allocator)
    {
        if(encoded.empty()){target.AddMember(Json(key,allocator),Json().SetNull(),allocator);return;}
        rapidjson::Document parsed;
        if(parsed.Parse(encoded.c_str()).HasParseError())throw std::runtime_error("Invalid persisted JingJie JSON");
        Json copy;copy.CopyFrom(parsed,allocator);target.AddMember(Json(key,allocator),copy,allocator);
    }
    bool Sqlite(gyu::db::CDatabaseSql* db){return db!=NULL && db->IsSqlite();}
    int64 SafeAdd(int64 value,int64 delta)
    {
        if(delta>0 && value>std::numeric_limits<int64>::max()-delta)throw std::overflow_error("JingJie experience overflow");
        if(delta<0 && delta < -value)return 0;
        return value+delta;
    }
}

CUnityJingJieService::CUnityJingJieService():m_random(std::random_device()()){}
CUnityJingJieService& CUnityJingJieService::Instance()
{ static CUnityJingJieService* service=new CUnityJingJieService();return *service; }
int64 CUnityJingJieService::NowMs()
{ return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count(); }

bool CUnityJingJieService::Create(uint32 roleId,gyu::db::CDatabaseSql* db,int64 createdMs)
{
    if(!Sqlite(db) || roleId==0 || !db->ExecuteScript(StateSchema))return false;
    std::ostringstream sql;
    sql<<"INSERT OR IGNORE INTO unity_jingjie_state(role_id,last_ms,cycle_ms) VALUES("
       <<roleId<<","<<createdMs<<","<<createdMs<<")";
    return db->Query(sql.str().c_str());
}

bool CUnityJingJieService::Persist(CUser* user,const State& state)
{
    CGetDbConnect connection;CDatabaseSql* db=connection.GetDbConnect();
    if(!Sqlite(db) || !db->Query("BEGIN IMMEDIATE"))return false;
    std::ostringstream sql;
    sql<<"INSERT INTO unity_jingjie_state(role_id,version,current_id,experience,failure_count,last_ms,cycle_ms,fraction,revision,attempt,entered,pending,last_request,last_result,offline,legacy_level,legacy_id,legacy_experience) VALUES("
       <<user->GetRoleId()<<",2,"<<state.id<<","<<Quote(std::to_string(state.experience))<<","<<state.failures<<","<<state.lastMs<<","<<state.cycleMs<<","<<state.fraction<<","<<state.revision<<","<<state.attempt<<","<<(state.entered?1:0)
       <<","<<Quote(state.pending)<<","<<Quote(state.lastRequest)<<","<<Quote(state.lastResult)<<","<<Quote(state.offline)<<","<<state.legacyLevel<<","<<state.legacyId<<","<<Quote(std::to_string(state.legacyExperience))
       <<") ON CONFLICT(role_id) DO UPDATE SET version=2,current_id=excluded.current_id,experience=excluded.experience,failure_count=excluded.failure_count,last_ms=excluded.last_ms,cycle_ms=excluded.cycle_ms,fraction=excluded.fraction,revision=excluded.revision,attempt=excluded.attempt,entered=excluded.entered,pending=excluded.pending,last_request=excluded.last_request,last_result=excluded.last_result,offline=excluded.offline";
    bool ok=db->Query(sql.str().c_str());
    if(ok){sql.str("");sql.clear();sql<<"UPDATE role_info SET level="<<state.id<<",exp="<<Quote(std::to_string(state.experience))<<" WHERE id="<<user->GetRoleId();ok=db->Query(sql.str().c_str());}
    if(ok)ok=db->Query("COMMIT");
    if(!ok)db->Query("ROLLBACK");
    return ok;
}

void CUnityJingJieService::Apply(CUser* user,const State& state)
{ user->SetJingJie(state.id);user->SetLevel(state.id);user->SetExp(state.experience); }

bool CUnityJingJieService::Accrue(State& state,int64 now,bool offline)
{
    SJingJieCfg config;if(!SingletonCJingJieMgr::instance().GetCfg(state.id,config))return false;
    int64 elapsed=std::max<int64>(0,now-state.lastMs);
    const SUnityJingJieRules& rules=SingletonCJingJieMgr::instance().GetRules();
    if(offline)elapsed=std::min<int64>(elapsed,static_cast<int64>(rules.offlineSeconds)*1000);
    int64 produced=elapsed*config.expPerSecond;
    if(offline)produced=produced*rules.offlineRate/10000;
    produced+=state.fraction;
    int64 gain=produced/1000;state.fraction=static_cast<uint32>(produced%1000);
    state.experience=SafeAdd(state.experience,gain);
    if(!offline)state.batchGain=SafeAdd(state.batchGain,gain);
    state.lastMs=now;
    return true;
}

bool CUnityJingJieService::Load(CUser* user)
{
    if(user==NULL || user->GetRoleId()==0)return false;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    CGetDbConnect connection;CDatabaseSql* db=connection.GetDbConnect();
    if(!Sqlite(db) || !db->ExecuteScript(StateSchema))return false;
    std::ostringstream query;
    query<<"SELECT version,current_id,experience,failure_count,last_ms,cycle_ms,fraction,revision,attempt,entered,pending,last_request,last_result,offline,legacy_level,legacy_id,legacy_experience FROM unity_jingjie_state WHERE role_id="<<user->GetRoleId();
    if(!db->Query(query.str().c_str()))return false;
    char** row=db->GetRow();State state;int64 now=NowMs();
    int64 offlineSeconds=0,offlineGain=0;
    if(row!=NULL)
    {
        if(row[0]==NULL || atoi(row[0])!=2)return false;
        state.id=static_cast<uint16>(atoi(row[1]));state.experience=atoll(row[2]);state.failures=static_cast<uint32>(strtoul(row[3],NULL,10));
        state.lastMs=atoll(row[4]);state.cycleMs=atoll(row[5]);state.fraction=atoi(row[6]);state.revision=atoll(row[7]);state.attempt=atoll(row[8]);state.entered=atoi(row[9])!=0;
        state.pending=row[10]?row[10]:"";state.lastRequest=row[11]?row[11]:"";state.lastResult=row[12]?row[12]:"";state.offline=row[13]?row[13]:"";
        state.legacyLevel=atoi(row[14]);state.legacyId=atoi(row[15]);state.legacyExperience=atoll(row[16]);
        if(state.id<1 || state.id>550 || state.experience<0 || state.fraction>=1000)return false;
        offlineSeconds=std::min<int64>(std::max<int64>(0,(now-state.lastMs)/1000),SingletonCJingJieMgr::instance().GetRules().offlineSeconds);
        int64 before=state.experience;
        if(!Accrue(state,now,true))return false;
        if(state.entered)offlineGain=state.experience-before;
    }
    else
    {
        state.legacyLevel=user->GetLevel();state.legacyId=static_cast<uint16>(user->GetJingJie());state.legacyExperience=std::max<int64>(0,user->GetExp());
        // Preserve numeric level/unlock progress and map the old 20 realm milestones to approved anchors.
        int mapped=state.legacyId>0 && state.legacyId<=20?1+((state.legacyId-1)*549+9)/19:1;
        state.id=static_cast<uint16>(std::min(550,std::max<int>(std::max<int>(1,state.legacyLevel),mapped)));
        state.experience=state.legacyExperience;
        // role_info.login_time is the last saved exit time, loaded before InitJingJie.
        // A legacy role without that timestamp can still accrue from its recorded creation time.
        uint32 legacyTime=user->m_lastLoginOutTime>0?user->m_lastLoginOutTime:user->reg_time;
        state.lastMs=legacyTime>0?std::min<int64>(now,static_cast<int64>(legacyTime)*1000):now;
        offlineSeconds=std::min<int64>(std::max<int64>(0,(now-state.lastMs)/1000),SingletonCJingJieMgr::instance().GetRules().offlineSeconds);
        if(!Accrue(state,now,true))return false;
        offlineGain=state.experience-state.legacyExperience;
    }
    if(offlineGain>0)
    {
        rapidjson::Document notice;notice.SetObject();Alloc& a=notice.GetAllocator();
        String(notice,"id",std::to_string(now),a);notice.AddMember("seconds",Json().SetInt64(offlineSeconds),a);
        String(notice,"experience",std::to_string(offlineGain),a);state.offline=Encode(notice);
    }
    state.entered=true;state.cycleMs=now;++state.revision;
    if(!Persist(user,state))return false;
    m_states[user->GetRoleId()]=state;Apply(user,state);return true;
}

CUnityJingJieService::State* CUnityJingJieService::Find(CUser* user)
{
    auto it=m_states.find(user->GetRoleId());
    if(it==m_states.end()){if(!Load(user))return NULL;it=m_states.find(user->GetRoleId());}
    return &it->second;
}

void CUnityJingJieService::Send(CUser* user,const State& state,const char* kind,int64 gain,const std::string& result,const std::string& error)
{
    SJingJieCfg config;if(!SingletonCJingJieMgr::instance().GetCfg(state.id,config))return;
    const SUnityJingJieRules& rules=SingletonCJingJieMgr::instance().GetRules();
    rapidjson::Document envelope;envelope.SetObject();Alloc& a=envelope.GetAllocator();
    envelope.AddMember("schema",2,a);String(envelope,"kind",kind,a);String(envelope,"error",error,a);String(envelope,"gain",std::to_string(gain),a);
    Json snapshot(rapidjson::kObjectType);snapshot.AddMember("id",state.id,a);snapshot.AddMember("failures",state.failures,a);
    snapshot.AddMember("rate",config.expPerSecond,a);snapshot.AddMember("next_id",config.nextId,a);
    String(snapshot,"experience",std::to_string(state.experience),a);String(snapshot,"need_exp",std::to_string(config.needExp),a);
    String(snapshot,"revision",std::to_string(state.revision),a);String(snapshot,"server_ms",std::to_string(NowMs()),a);String(snapshot,"cycle_ms",std::to_string(state.cycleMs),a);
    String(snapshot,"power",std::to_string(user->GetZhanDouLi()),a);snapshot.AddMember("interval_ms",rules.onlineMs,a);
    envelope.AddMember("state",snapshot,a);Nested(envelope,"offline",state.offline,a);
    Nested(envelope,"trial",state.pending,a);Nested(envelope,"result",result,a);
    CNetMessage message;message.SetType(MSG_JINGJIE);message<<static_cast<uint8>(128)<<Encode(envelope);
    SingletonSocket::instance().SendMsg(user->GetSock(),message);
}

void CUnityJingJieService::Snapshot(CUser* user)
{
    if(user==NULL || user->GetRoleId()==0)return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    State* state=Find(user);if(state!=NULL)Send(user,*state,"snapshot");
}

void CUnityJingJieService::Tick(CUser* user)
{
    if(user==NULL || user->GetRoleId()==0 || user->IsLogout())return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    auto found=m_states.find(user->GetRoleId());if(found==m_states.end())return;
    State* state=&found->second;
    int64 now=NowMs();uint32 interval=SingletonCJingJieMgr::instance().GetRules().onlineMs;
    if(now-state->cycleMs<interval)return;
    State next=*state;
    // Keep the schedule at exact interval boundaries; delayed timer callbacks retain the partial next cycle.
    int64 boundary=state->cycleMs+(now-state->cycleMs)/interval*interval;
    if(!Accrue(next,std::max(boundary,next.lastMs),false))return;
    next.cycleMs=boundary;++next.revision;int64 gain=next.batchGain;next.batchGain=0;
    if(!Persist(user,next))return;
    *state=next;Apply(user,next);Send(user,next,"settlement",gain);
}

bool CUnityJingJieService::AddExperience(CUser* user,int64 amount)
{
    if(user==NULL || user->GetRoleId()==0)return false;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    State* state=Find(user);if(state==NULL)return false;
    State next=*state;if(!Accrue(next,NowMs(),false))return false;
    next.experience=SafeAdd(next.experience,amount);++next.revision;
    if(!Persist(user,next))return false;
    *state=next;Apply(user,next);Send(user,next,"reward",amount);return true;
}

void CUnityJingJieService::Upgrade(CUser* user,const std::string& requestId,int expectedId)
{
    if(user==NULL || user->GetRoleId()==0)return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    State* current=Find(user);if(current==NULL)return;
    if(!current->pending.empty()){Send(user,*current,"upgrade",0,current->lastResult);return;}
    if(!requestId.empty() && current->lastRequest==requestId){Send(user,*current,"upgrade",0,current->lastResult);return;}
    if(requestId.empty() || requestId.size()>64 || expectedId!=current->id){Send(user,*current,"upgrade",0,"","境界状态已变化，请重新操作");return;}
    State next=*current;if(!Accrue(next,NowMs(),false))return;
    SJingJieCfg config;if(!SingletonCJingJieMgr::instance().GetCfg(next.id,config))return;
    if(config.nextId==0 || next.experience<config.needExp)
    {
        ++next.revision;if(Persist(user,next)){*current=next;Apply(user,next);}
        Send(user,*current,"upgrade",0,"",config.nextId==0?"已达到最高境界":"修为不足");return;
    }
    bool big=config.stage==10;
    bool guaranteed=big && config.threshold>0 && next.failures>=config.threshold;
    bool success=!big || guaranteed || std::uniform_int_distribution<int>(0,9999)(m_random)<static_cast<int>(config.probability);
    rapidjson::Document outcome;outcome.SetObject();Alloc& a=outcome.GetAllocator();
    ++next.attempt;std::string trialId=std::to_string(user->GetRoleId())+"-"+std::to_string(next.attempt);
    String(outcome,"id",trialId,a);outcome.AddMember("before_id",next.id,a);outcome.AddMember("success",success,a);outcome.AddMember("big",big,a);outcome.AddMember("guaranteed",guaranteed,a);
    String(outcome,"visual",config.icon,a);
    int64 maxHp=std::max(1,user->GetMaxHp());
    if(maxHp<=1)for(const SAttrData& attr:config.attr)if(attr.attrType==4)maxHp=std::max<int64>(1,attr.attrValue);
    String(outcome,"max_hp",std::to_string(maxHp),a);
    Json damages(rapidjson::kArrayType);
    if(big)
    {
        std::vector<int> feasible;
        for(uint32 n=config.thunderMin;n<=config.thunderMax;++n)
            if(success?n*config.damageMin<=100:n*config.damageMax>100)feasible.push_back(n);
        if(feasible.empty()){Send(user,*current,"upgrade",0,"","雷劫配置无法生成本次结果");return;}
        int count=feasible[std::uniform_int_distribution<int>(0,static_cast<int>(feasible.size())-1)(m_random)];
        int low=success?count*config.damageMin:std::max<int>(101,count*config.damageMin);
        int high=success?std::min<int>(100,count*config.damageMax):count*config.damageMax;
        int total=std::uniform_int_distribution<int>(low,high)(m_random);
        for(int i=0;i<count;++i)
        {
            int remaining=count-i-1;
            low=std::max<int>(config.damageMin,total-remaining*config.damageMax);
            high=std::min<int>(config.damageMax,total-remaining*config.damageMin);
            int damage=std::uniform_int_distribution<int>(low,high)(m_random);damages.PushBack(damage,a);total-=damage;
        }
    }
    outcome.AddMember("damages",damages,a);
    if(success){next.experience-=config.needExp;next.id=config.nextId;next.failures=0;}
    else{int64 penalty=config.needExp/10000*config.failPenalty+(config.needExp%10000)*config.failPenalty/10000;next.experience=std::max<int64>(0,next.experience-penalty);++next.failures;}
    next.lastRequest=requestId;next.lastResult=Encode(outcome);if(big)next.pending=next.lastResult;++next.revision;
    if(!Persist(user,next)){Send(user,*current,"upgrade",0,"","境界存档失败，请重试");return;}
    *current=next;Apply(user,next);
    if(success){user->InitChuZhanPet();user->ResetPower();user->SendUpdateInfo(EUUT_TotalZhanDouLi);}
    Send(user,next,"upgrade",0,next.lastResult);
}

void CUnityJingJieService::Acknowledge(CUser* user,const std::string& id,bool offlineNotice)
{
    if(user==NULL || user->GetRoleId()==0)return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    State* state=Find(user);if(state==NULL)return;
    const std::string& encoded=offlineNotice?state->offline:state->pending;
    rapidjson::Document stored;if(encoded.empty() || stored.Parse(encoded.c_str()).HasParseError()
        || !stored.HasMember("id") || id!=stored["id"].GetString())return;
    State next=*state;if(offlineNotice)next.offline.clear();else next.pending.clear();++next.revision;
    if(Persist(user,next)){*state=next;Send(user,next,"ack");}
}

void CUnityJingJieService::Flush(CUser* user)
{
    if(user==NULL || user->GetRoleId()==0)return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    auto it=m_states.find(user->GetRoleId());if(it==m_states.end())return;
    State next=it->second;if(!Accrue(next,NowMs(),false))return;++next.revision;
    if(Persist(user,next)){it->second=next;Apply(user,next);}
}

void CUnityJingJieService::Detach(CUser* user)
{
    if(user==NULL)return;
    boost::recursive_mutex::scoped_lock userLock(user->m_mutex),serviceLock(m_mutex);
    Flush(user);m_states.erase(user->GetRoleId());
}
