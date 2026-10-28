#include "story_unity.h"
#include "global_event.h"
#include "user.h"
#include "singleton.h"
#include "init.h"
#include "script_call.h"
#include "pet_equip_manage.h"
#include "user_guanqia.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#include <set>
#include <map>
#include <stdexcept>
#include <sstream>
#include <iostream>
#include <algorithm>
namespace {
using DB=gyu::db::CDatabaseSql;
struct Step {int id=0,pre=0,trigger=0,dialog=0,action=0,target=0,p1=0,p2=0,complete=0;};
struct State {int step=0,last=0,progress=0,revision=0;bool started=false;uint32 uid=0;};
struct Config {std::map<int,Step> steps;std::map<int,std::pair<int,int>> rewards;int first=0;};
thread_local std::set<uint32> busy;
struct Guard {uint32 role;Guard(uint32 r):role(r){busy.insert(r);}~Guard(){busy.erase(role);}};
std::string Q(const std::string& s){std::string out="'";for(char c:s){out+=c;if(c=='\'')out+='\'';}return out+"'";}
void SQL(DB* db,const std::string& s){if(!db||!db->Query(s.c_str()))throw std::runtime_error("剧情存档写入失败");}
void Ensure(DB* db){SQL(db,"CREATE TABLE IF NOT EXISTS unity_story_state(role_id INTEGER PRIMARY KEY REFERENCES role_info(id) ON DELETE CASCADE,step INTEGER NOT NULL,started INTEGER NOT NULL DEFAULT 0,last_event INTEGER NOT NULL DEFAULT 0,progress INTEGER NOT NULL DEFAULT 0,revision INTEGER NOT NULL DEFAULT 0,equip_uid INTEGER NOT NULL DEFAULT 0)");}
Config LoadConfig(){
 Config c;rapidjson::Document d;rapidjson::Value rows;
 const char* k[]={"id","pre_id","trigger_event_id","dialogid","action_type","action_id","param1","param2","complete_event_id","once","enabled"};
 const int ts[]={0,0,0,0,0,0,0,0,0,0,0};
 if(!LoadJosnValue("story_event.json",k,ts,11,d,rows))throw std::runtime_error("剧情步骤配置缺失");
 std::set<int> successors;
 for(rapidjson::SizeType i=0;i<rows.Size();++i){const auto& r=rows[i];
  if(r["enabled"].GetInt()!=1)continue;
  Step s;s.id=r["id"].GetInt();s.pre=r["pre_id"].GetInt();s.trigger=r["trigger_event_id"].GetInt();s.dialog=r["dialogid"].GetInt();s.action=r["action_type"].GetInt();s.target=r["action_id"].GetInt();s.p1=r["param1"].GetInt();s.p2=r["param2"].GetInt();s.complete=r["complete_event_id"].GetInt();
  if(s.id<1||s.action<0||s.action>6||r["once"].GetInt()!=1||!GlobalEvents().Get(s.trigger)||!GlobalEvents().Get(s.complete)||!c.steps.emplace(s.id,s).second||!successors.insert(s.pre).second)throw std::runtime_error("剧情步骤引用/顺序错误");
  if(!s.pre)c.first=s.id;
 }
 if(!c.first)throw std::runtime_error("缺少开局剧情");
 int previous=0,visited=0;
 while(true){auto it=std::find_if(c.steps.begin(),c.steps.end(),[&](const std::pair<const int,Step>& x){return x.second.pre==previous;});if(it==c.steps.end())break;previous=it->first;if(++visited>(int)c.steps.size())throw std::runtime_error("剧情步骤循环");}
 if(visited!=(int)c.steps.size())throw std::runtime_error("剧情步骤断链");
 const char* rk[]={"ID","reward"};const int rt[]={0,2};
 rapidjson::Document rd;rapidjson::Value rr;
 if(!LoadJosnValue("reward_fixed.json",rk,rt,2,rd,rr))throw std::runtime_error("剧情奖励配置缺失");
 for(rapidjson::SizeType i=0;i<rr.Size();++i){const auto& r=rr[i];
  int id=r["ID"].GetInt();bool referenced=false;for(const auto& s:c.steps)if(s.second.action==3&&s.second.target==id)referenced=true;
  if(!referenced)continue;
  auto& a=r["reward"];if(a.Size()!=1||a[0].Size()!=3||a[0][2].GetInt()!=1)throw std::runtime_error("本版剧情奖励须为单件");
  int type=a[0][0].GetInt(),object=a[0][1].GetInt();if(type!=60002&&type!=60005)throw std::runtime_error("不支持的剧情奖励类型");
  c.rewards[id]={type,object};
 }
 for(const auto& p:c.steps)if(p.second.action==3&&!c.rewards.count(p.second.target))throw std::runtime_error("剧情奖励引用缺失");

 for(const auto& p:c.steps){
  const auto& s=p.second;const auto* e=GlobalEvents().Get(s.complete);
  if((s.action==0&&(e->type!=1004||e->param1!=(uint32)s.dialog))||
     (s.action==1&&((s.target!=22&&s.target!=1030)||e->type!=1003||e->param1!=(uint32)s.target))||
     (s.action==4&&(e->type!=1006||e->param1!=(uint32)s.target||e->param2!=(uint32)s.p1))||
     (s.action==5&&(e->type!=1002||e->param1!=2))||
     (s.action==6&&(s.target!=1030||e->type!=1008||!e->param1||e->param2!=(uint32)s.p2)))throw std::runtime_error("剧情动作与完成事件不一致");
  if(s.action==3){const auto& r=c.rewards.at(s.target);if(e->type!=(r.first==60002?1005:1007)||e->param1!=(uint32)r.second||e->num!=1)throw std::runtime_error("剧情奖励与完成事件不一致");}
 }
 return c;
}
const Config& Definitions(){static Config c=LoadConfig();return c;}
State Read(CUser* u,DB* db){State s;SQL(db,"SELECT step,started,last_event,progress,revision,equip_uid FROM unity_story_state WHERE role_id="+std::to_string(u->GetRoleId()));char** r=db->GetRow();if(r){s.step=atoi(r[0]);s.started=atoi(r[1])!=0;s.last=atoi(r[2]);s.progress=atoi(r[3]);s.revision=atoi(r[4]);s.uid=(uint32)strtoul(r[5],nullptr,10);}else s.step=-1;return s;}
void Persist(CUser* u,DB* db,const State& s){SQL(db,"UPDATE unity_story_state SET step="+std::to_string(s.step)+",started="+std::to_string(s.started)+",last_event="+std::to_string(s.last)+",progress="+std::to_string(s.progress)+",revision="+std::to_string(s.revision)+",equip_uid="+std::to_string(s.uid)+" WHERE role_id="+std::to_string(u->GetRoleId()));}
struct Inventory{
 std::string pet,formation,equipment,save,chapter;
 Inventory(CUser* u){u->GetPet(pet);u->GetZhenFa(formation);u->GetPetEquipMgr().SaveData(equipment);u->WriteSaveData(save);u->GetGuanQia().SaveData(chapter);}
 void Restore(CUser* u){u->SetPet(const_cast<char*>(pet.c_str()));u->SetZhenFa(const_cast<char*>(formation.c_str()));u->GetPetEquipMgr().LoadData(const_cast<char*>(equipment.c_str()));u->ReadSaveData(const_cast<char*>(save.c_str()));}
 void Save(CUser* u,DB* db){Inventory now(u);SQL(db,"UPDATE role_info SET pet="+Q(now.pet)+",zhenfa="+Q(now.formation)+",pet_equip="+Q(now.equipment)+",save_data="+Q(now.save)+",guan_qia="+Q(now.chapter)+" WHERE id="+std::to_string(u->GetRoleId()));}
};
bool Current(CUser* u,const GlobalEventDefinition* e,int& p){
 uint32 value=0;if(!e||!GlobalEvents().ReadCurrent(u,*e,value))return false;p=(int)value;return value>=e->num;
}
bool Match(const GlobalEventDefinition* e,uint16 type,int value,int parameter,int& progress){
 if(!e||e->type!=type)return false;uint32 p=(uint32)progress;
 bool changed=GlobalEventRules::Advance(*e,p,value,parameter);progress=(int)p;return changed&&p>=e->num;
}
void Advance(CUser* u,State& state,uint16 type,int value,int parameter){
 const auto& c=Definitions();
 for(size_t guard=0;state.step>0&&guard<=c.steps.size();++guard){
  auto it=c.steps.find(state.step);if(it==c.steps.end())throw std::runtime_error("剧情步骤已失效");const Step& s=it->second;
  const auto* trigger=GlobalEvents().Get(s.trigger);const auto* complete=GlobalEvents().Get(s.complete);
  if(!state.started){if(state.last!=s.trigger&&!Current(u,trigger,state.progress)&&!Match(trigger,type,value,parameter,state.progress))break;state.started=true;state.progress=0;++state.revision;}
  bool done=false;
  if(s.action==3){
   const auto& r=c.rewards.at(s.target);
   if(r.first==60002){if(!u->HavePet(r.second)&&!AddPet(u,r.second,1,1,false))throw std::runtime_error("神将赠送失败");}
   else{std::set<uint32> old;for(const auto& e:u->GetPetEquipMgr().GetPetEquips())old.insert(e.first);if(!u->GetPetEquipMgr().AddEquip(u,r.second))throw std::runtime_error("装备背包已满，请整理后重试");for(const auto& e:u->GetPetEquipMgr().GetPetEquips())if(!old.count(e.first))state.uid=e.first;if(!state.uid)throw std::runtime_error("教学装备实例缺失");}
   done=true;
  }else if(s.action==4){
   if(!u->HavePet(s.target)||!u->ZhenFa_SetPetState(s.target,(uint8)s.p1))throw std::runtime_error("神将上阵失败");
   int p=0;done=Current(u,complete,p);
  }else{
   done=Current(u,complete,state.progress)||Match(complete,type,value,parameter,state.progress);
   if(done&&s.action==6&&state.uid){auto& es=u->GetPetEquipMgr().GetPetEquips();auto e=es.find(state.uid);done=e!=es.end()&&e->second.fpos==complete->param1&&e->second.wpos==complete->param2&&u->GetPetZhenFaIdx(s.p1)==complete->param1;}
  }
  if(!done)break;
  state.last=s.complete;state.started=false;state.progress=0;++state.revision;
  int next=0;for(const auto& x:c.steps)if(x.second.pre==s.id){next=x.first;break;}state.step=next;
  type=0;value=0;parameter=0; // One input can complete at most one non-automatic step.
 }
}
void Send(CUser* u,const State& s,const std::string& error=""){
 rapidjson::Document d;d.SetObject();auto& a=d.GetAllocator();
 d.AddMember("enabled",s.step>=0,a);d.AddMember("step",std::max(0,s.step),a);d.AddMember("started",s.started,a);d.AddMember("revision",s.revision,a);d.AddMember("equip_uid",s.uid,a);d.AddMember("error",rapidjson::Value(error.c_str(),a),a);
 rapidjson::StringBuffer b;rapidjson::Writer<rapidjson::StringBuffer> w(b);d.Accept(w);CNetMessage msg;msg.SetType(328);msg<<(uint8)128<<std::string(b.GetString());SingletonSocket::instance().SendMsg(u->GetSock(),msg);
}
}
void CUnityStoryService::Process(CUser* u,uint16 type,int value,int parameter,bool reply){
 if(!u)return;boost::recursive_mutex::scoped_lock lock(u->m_mutex);if(busy.count(u->GetRoleId()))return;Guard g(u->GetRoleId());
 CGetDbConnect connection;DB* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;
 State state;Inventory before(u);bool transaction=false;
 try{Ensure(db);state=Read(u,db);if(state.step<0){if(reply)Send(u,state);return;}
  State original=state;SQL(db,"SAVEPOINT story_event");transaction=true;Advance(u,state,type,value,parameter);if(original.revision!=state.revision||original.progress!=state.progress){before.Save(u,db);Persist(u,db,state);}SQL(db,"RELEASE story_event");transaction=false;if(reply||type)Send(u,state);
 }catch(const std::exception& e){if(transaction){db->Query("ROLLBACK TO story_event");db->Query("RELEASE story_event");before.Restore(u);state=Read(u,db);}Send(u,state,e.what());}
}
bool CUnityStoryService::Create(uint32 role,DB* db){
 try{Ensure(db);SQL(db,"INSERT INTO unity_story_state(role_id,step) VALUES("+std::to_string(role)+","+std::to_string(Definitions().first)+")");return true;}catch(const std::exception& e){std::cerr<<e.what()<<std::endl;return false;}
}
bool CUnityStoryService::Enabled(CUser* u){if(!u)return false;CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return false;try{Ensure(db);return Read(u,db).step>=0;}catch(...){return false;}}
void CUnityStoryService::OnEvent(CUser* u,uint16 type,int value,int parameter){Process(u,type,value,parameter,type>=1002&&type<=1004);}
void CUnityStoryService::Handle(CUser* u,unsigned char op,const std::string& payload){
 if(op==0){Process(u,0,0,0,true);return;}
 if(op==2){rapidjson::Document d;d.Parse(payload.c_str());if(!d.HasParseError()&&d.IsObject()&&d.HasMember("type")&&d["type"].IsInt()&&d.HasMember("parameter")&&d["parameter"].IsInt()){int t=d["type"].GetInt(),p=d["parameter"].GetInt();if((t==1002&&p>=0&&p<=2)||(t==1003&&(p==22||p==1030)))GlobalEvents().Publish(u,t,1,p);}return;}
 if(op!=1||payload.size()>512)return;
 rapidjson::Document input;input.Parse(payload.c_str());if(input.HasParseError()||!input.IsObject()||!input.HasMember("event_id")||!input["event_id"].IsInt()||!input.HasMember("step")||!input["step"].IsInt()||!input.HasMember("revision")||!input["revision"].IsInt())return;
 int eid=input["event_id"].GetInt();const auto* event=GlobalEvents().Get(eid);
 if(!event||(event->type!=1002&&event->type!=1003&&event->type!=1004))return;
 CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;
 State s;try{Ensure(db);s=Read(u,db);}catch(...){return;}const auto& c=Definitions();auto step=c.steps.find(s.step);
 if(step==c.steps.end()||input["step"].GetInt()!=s.step||input["revision"].GetInt()!=s.revision||eid!=(s.started?step->second.complete:step->second.trigger)){Send(u,s);return;}
 GlobalEvents().Publish(u,event->type,1,(int)event->param1);
}
bool CUnityStoryService::AllowsChapter(CUser* u,uint32 chapter){
 if(!u)return false;CGetDbConnect c;auto* db=c.GetDbConnect();if(!db||!db->IsSqlite())return true;
 try{Ensure(db);State s=Read(u,db);if(s.step<=0)return true;for(const auto& p:Definitions().steps)if(p.second.action==2&&p.second.target==(int)chapter)return s.step>=p.second.id;return false;}catch(...){return false;}
}
int CUnityStoryService::Validate(){try{if(!GlobalEvents().Init())return 1;const auto& c=Definitions();std::cout<<"{\"story_steps\":"<<c.steps.size()<<",\"first\":"<<c.first<<",\"reward_packages\":"<<c.rewards.size()<<"}"<<std::endl;return 0;}catch(const std::exception& e){std::cerr<<e.what()<<std::endl;return 1;}}

int ValidateStoryCounters(){
 try{
  if(!GlobalEvents().Init())return 1;const auto& c=Definitions();const Step& step=c.steps.at(c.first);
  const auto* e=GlobalEvents().Get(step.trigger);
  if(e->type!=7||e->num!=3||step.action!=0)throw std::runtime_error("Counter fixture requires strengthen3 before a dialogue");
  State s;s.step=c.first;
  Advance(nullptr,s,7,1,0);if(s.started||s.progress!=1)throw std::runtime_error("First trigger increment lost");
  Advance(nullptr,s,7,1,0);if(s.started||s.progress!=2)throw std::runtime_error("Second trigger increment lost");
  Advance(nullptr,s,7,1,8);if(s.started||s.progress!=2)throw std::runtime_error("Wrong filter advanced dialogue");
  Advance(nullptr,s,7,1,0);if(!s.started||s.step!=c.first||s.progress!=0)throw std::runtime_error("Third trigger did not start dialogue");
  std::cout<<"{\"trigger_increments\":3,\"wrong_filter_rejected\":true,\"dialogue_started\":true}"<<std::endl;return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<std::endl;return 1;}
}
