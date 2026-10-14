#ifndef PROJECTX_UNITY_JINGJIE_H
#define PROJECTX_UNITY_JINGJIE_H
#include "self_typedef.h"
#include <boost/thread/recursive_mutex.hpp>
#include <map>
#include <random>
#include <string>

class CUser;
namespace gyu { namespace db { class CDatabaseSql; } }

class CUnityJingJieService
{
public:
    static CUnityJingJieService& Instance();
    bool Create(uint32 roleId,gyu::db::CDatabaseSql* db,int64 createdMs);
    bool Load(CUser* user);
    void Tick(CUser* user);
    void Snapshot(CUser* user);
    void Upgrade(CUser* user,const std::string& requestId,int expectedId);
    void Acknowledge(CUser* user,const std::string& trialId,bool offlineNotice);
    void Flush(CUser* user);
    void Detach(CUser* user);
    bool AddExperience(CUser* user,int64 amount);
    static int64 NowMs();

private:
    struct State
    {
        State():id(1),experience(0),failures(0),lastMs(0),cycleMs(0),fraction(0),revision(0),attempt(0),batchGain(0),entered(false),legacyLevel(1),legacyId(0),legacyExperience(0){}
        uint16 id;
        int64 experience,lastMs,cycleMs,revision,attempt,batchGain;
        uint32 failures,fraction;
        int rateFraction=0;
        bool entered;
        uint16 legacyLevel,legacyId;
        int64 legacyExperience;
        std::string pending,lastRequest,lastResult,offline;
    };
    CUnityJingJieService();
    bool Persist(CUser* user,const State& state);
    bool Accrue(State& state,int64 now,bool offline,CUser* user);
    void Apply(CUser* user,const State& state);
    void Send(CUser* user,const State& state,const char* kind,int64 gain=0,const std::string& result="",const std::string& error="");
    State* Find(CUser* user);
    std::map<uint32,State> m_states;
    boost::recursive_mutex m_mutex;
    std::mt19937 m_random;
};
#endif
