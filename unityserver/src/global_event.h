#pragma once
#include <algorithm>
#include <cstdint>
#include <map>
#include <set>
#include <string>

struct GlobalEventDefinition
{
    std::uint32_t id=0, num=0, param1=0, param2=0;
    std::uint16_t type=0;
    std::uint8_t countStart=2, cycle=0;
};

// Stateless rules: progress belongs to each task/story subscriber, never a global flag.
namespace GlobalEventRules
{
inline bool IsStateQuery(std::uint16_t t)
{
    return t==1006||t==1008||t==20||t==21||t==25||t==41||t==42||t==45||t==48||t==49;
}
inline bool Supported(std::uint16_t t)
{
    switch(t) {
    case 1:case 2:case 3:case 4:case 5:case 6:case 7:case 8:case 9:case 10:
    case 11:case 12:case 13:case 14:case 16:case 17:case 18:case 20:case 21:
    case 25:case 30:case 31:case 32:case 33:case 34:case 35:case 36:case 37:
    case 38:case 39:case 40:case 41:case 42:case 43:case 44:case 45:case 46:
    case 47:case 48:case 49:case 50:case 51:case 52:case 54:case 55:case 56:
    case 57:case 59:case 60:case 1002:case 1003:case 1004:case 1005:case 1006:case 1007:case 1008:case 1010:return true;
    default:return false;
    }
}
inline bool Advance(const GlobalEventDefinition& e,std::uint32_t& progress,int value,int parameter,
                    bool hasState=false,std::uint32_t state=0)
{
    if(!e.num||value<0||parameter<0)return false;
    if(IsStateQuery(e.type)){if(!hasState)return false;progress=state;return true;}
    bool add=false;
    switch(e.type) {
    case 1:case 2:case 3:case 4:case 5:case 6:case 7:case 8:case 9:case 10:
    case 11:case 12:case 13:case 14:case 16:case 17:case 18:case 32:case 35:
    case 36:case 40:case 54:case 55:case 56:case 59:case 60:
        if(e.param1!=static_cast<std::uint32_t>(parameter))return false;add=true;break;
    case 34:case 46:case 50:
        if(static_cast<std::uint32_t>(parameter)<e.param1)return false;add=true;break;
    case 37:
        if(static_cast<std::uint32_t>(parameter)>e.param1)return false;add=true;break;
    case 30:case 31:case 33:case 38:case 39:case 44:case 47:case 51:case 52:case 57:
        if(progress>static_cast<std::uint32_t>(value))return false;
        progress=static_cast<std::uint32_t>(value);return true;
    case 1002:case 1003:case 1004:case 1005:case 1007:case 1010:
        if(e.param1!=0&&e.param1!=static_cast<std::uint32_t>(parameter))return false;add=true;break;
    case 43:
        if(static_cast<std::uint32_t>(value)>e.num)return false;
        progress=e.num;return true;
    default:return false;
    }
    if(add)progress=static_cast<std::uint32_t>(std::min<std::uint64_t>(
        static_cast<std::uint64_t>(progress)+value,UINT32_MAX));
    return true;
}
}
class CUser;
class CGlobalEventManager
{
public:
    bool Init();
    bool ReadCurrent(CUser* user,const GlobalEventDefinition& event,std::uint32_t& progress)const;
    const std::set<std::uint16_t>& SnapshotTypes()const{return snapshotTypes;}
    void Publish(CUser* user,std::uint16_t type,int value=1,int parameter=0)const;
    const GlobalEventDefinition* Get(std::uint32_t id)const;
    std::size_t Size()const{return events.size();}
    bool Advance(CUser* user,const GlobalEventDefinition& event,std::uint32_t& progress,int value,int parameter)const;
    bool Advance(CUser* user,std::uint32_t id,std::uint32_t& progress,int value,int parameter)const;
private:
    std::map<std::uint32_t,GlobalEventDefinition> events;
    std::set<std::uint16_t> snapshotTypes;
};
CGlobalEventManager& GlobalEvents();
int ValidateGlobalEventConfiguration();
