#include "spirit_unity.h"
#include "user.h"
#include "init.h"
#include "singleton.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#include <fstream>
#include <sstream>
#include <set>
#include <chrono>

namespace
{
using V=rapidjson::Value;using A=rapidjson::Document::AllocatorType;
using Costs=std::vector<std::pair<int,int64>>;
struct ArrayLevel {int id=0,level=0,next=0,cap=0,rate=0;int64 storage=0;Costs costs;};
struct RootLevel {int id=0,type=0,level=0,next=0,growth=0,yield=0;int64 spiritCost=0;bool maximum=false;std::string name;Costs costs;std::vector<int> positions;std::vector<std::pair<int,int>> attributes;};
struct Config {std::map<int,ArrayLevel> arrays;std::map<int,RootLevel> roots;};
std::string Q(const std::string& text){std::string s="'";for(char c:text){s+=c;if(c=='\'')s+='\'';}return s+"'";}
void SQL(gyu::db::CDatabaseSql* db,const std::string& sql){if(!db->Query(sql.c_str()))throw std::runtime_error("聚灵阵存档失败");}
int N(const V& r,const char* k){if(!r.IsObject()||!r.HasMember(k)||!r[k].IsInt())throw std::runtime_error(std::string("聚灵阵配置字段错误：")+k);return r[k].GetInt();}
int64 L(const V& r,const char* k){if(!r.HasMember(k)||!r[k].IsInt64()||r[k].GetInt64()<0)throw std::runtime_error(std::string("灵根配置字段错误：")+k);return r[k].GetInt64();}
void S(V& o,const char* k,const std::string& s,A& a){o.AddMember(V(k,a),V(s.c_str(),a),a);}
int64 Now(){return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();}
rapidjson::Document Read(const char* path){std::ifstream f(path);if(!f)throw std::runtime_error(std::string("聚灵阵配置缺失：")+path);std::ostringstream s;s<<f.rdbuf();rapidjson::Document d;d.Parse(s.str().c_str());if(d.HasParseError()||!d.IsArray())throw std::runtime_error("聚灵阵配置格式错误");return d;}
Costs ReadCosts(const V& row)
{
    if(!row.HasMember("cost_items")||!row["cost_items"].IsArray())throw std::runtime_error("升级材料配置错误");Costs out;std::set<int> ids;
    for(rapidjson::SizeType i=0;i<row["cost_items"].Size();++i){const auto& p=row["cost_items"][i];if(!p.IsArray()||p.Size()!=2||!p[0].IsInt()||!p[1].IsInt64())throw std::runtime_error("升级材料格式错误");int id=p[0].GetInt();int64 count=p[1].GetInt64();if(id<1||id>65535||(id>=60000&&id!=HDAT_MONEY&&id!=HDAT_BANG_YB&&id!=HDAT_YB&&id!=60054)||count<1||count>INT_MAX||!ids.insert(id).second)throw std::runtime_error("升级材料须为背包物品、金币、元宝或灵气，数量为正整数");out.emplace_back(id,count);}
    return out;
}
Config ReadConfig()
{
    Config out;auto arrays=Read("json/dongfu_spirit_level.json");std::map<int,int> levels;
    for(rapidjson::SizeType i=0;i<arrays.Size();++i){const auto& r=arrays[i];if(N(r,"enabled")!=1)continue;ArrayLevel v;v.id=N(r,"id");v.level=N(r,"level");v.cap=v.level;v.storage=L(r,"storage");v.rate=N(r,"spirit_per_second");v.costs=ReadCosts(r);if(v.id<1||v.level<0||v.level==INT_MAX||v.rate<0||out.arrays.count(v.id)||!levels.emplace(v.level,v.id).second)throw std::runtime_error("聚灵阵等级配置错误");out.arrays[v.id]=v;}
    for(auto& entry:out.arrays){auto& v=entry.second;auto next=levels.find(v.level+1);if(!v.costs.empty()){if(next==levels.end())throw std::runtime_error("聚灵阵缺少下一等级配置");v.next=next->second;if(out.arrays.at(v.next).storage<v.storage)throw std::runtime_error("聚灵阵存储上限不能降低");}else if(next!=levels.end())throw std::runtime_error("满级聚灵阵之后仍有启用等级");}
    if(!levels.empty()){int expected=levels.begin()->first;for(const auto& v:levels)if(v.first!=expected++)throw std::runtime_error("聚灵阵等级必须连续");}
    auto definitions=Read("json/dongfu_spirit_root_level.json");std::map<std::pair<int,int>,int> rootLevels;
    for(rapidjson::SizeType i=0;i<definitions.Size();++i){const auto& r=definitions[i];if(N(r,"enabled")!=1)continue;RootLevel v;v.id=N(r,"id");v.type=N(r,"root_type");v.level=N(r,"level");v.growth=N(r,"growth_reduction_bp");v.yield=N(r,"yield_bonus_bp");v.costs=ReadCosts(r);
        if(!r.HasMember("name")||!r["name"].IsString()||r["name"].GetStringLength()==0)throw std::runtime_error("灵根等级名称不能为空");v.name=r["name"].GetString();
        if(!r.HasMember("spirit_cost"))throw std::runtime_error("灵根缺少spirit_cost");v.maximum=r["spirit_cost"].IsNull();
        if(!v.maximum){const auto& cost=r["spirit_cost"];if(!cost.IsArray()||cost.Size()!=2||!cost[0].IsInt()||cost[0].GetInt()!=60054||!cost[1].IsInt64()||cost[1].GetInt64()<0)throw std::runtime_error("灵根灵气消耗须为[60054,数量]");v.spiritCost=cost[1].GetInt64();}
        for(const auto& cost:v.costs)if(cost.first==60054)throw std::runtime_error("灵根灵气仅配置在spirit_cost，不能重复扣除");
        if(v.id<1||v.type<1||v.type>5||v.level<0||v.level==INT_MAX||v.growth<0||v.growth>=10000||v.yield<0||out.roots.count(v.id)||!rootLevels.emplace(std::make_pair(v.type,v.level),v.id).second)throw std::runtime_error("五行灵根等级配置错误");
        if(!r.HasMember("target_positions")||!r["target_positions"].IsArray()||!r.HasMember("combat_attributes")||!r["combat_attributes"].IsArray())throw std::runtime_error("灵根站位或属性配置错误");
        for(rapidjson::SizeType j=0;j<r["target_positions"].Size();++j){const auto& p=r["target_positions"][j];if(!p.IsInt())throw std::runtime_error("灵根目标站位须为整数1..5");v.positions.push_back(p.GetInt());}
        for(rapidjson::SizeType j=0;j<r["combat_attributes"].Size();++j){const auto& p=r["combat_attributes"][j];if(!p.IsArray()||p.Size()!=2||!p[0].IsInt()||!p[1].IsInt())throw std::runtime_error("灵根属性须为整数ID及值");v.attributes.emplace_back(p[0].GetInt(),p[1].GetInt());}
        spirit::PositionAttributes check;spirit::AddLevelAttributes(check,v.positions,v.attributes);out.roots[v.id]=v;
    }
    for(auto& entry:out.roots){auto& v=entry.second;auto next=rootLevels.find({v.type,v.level+1});if(!v.maximum){if(next==rootLevels.end())throw std::runtime_error("灵根缺少下一等级配置");v.next=next->second;}else if(next!=rootLevels.end())throw std::runtime_error("满级灵根之后仍有启用等级");}
    for(int type=1;type<=5;++type){int expected=-1;for(const auto& v:rootLevels)if(v.first.first==type){if(expected>=0&&v.first.second!=expected)throw std::runtime_error("各灵根等级必须连续");expected=v.first.second+1;}}
    return out;
}
int InitialArray(const Config& c){int id=0,level=INT_MAX;for(const auto& v:c.arrays)if(v.second.level<level){id=v.first;level=v.second.level;}return id;}
int InitialRoot(const Config& c,int type){int id=0,level=INT_MAX;for(const auto& v:c.roots)if(v.second.type==type&&v.second.level<level){id=v.first;level=v.second.level;}return id;}
int OpenLevel(){auto data=Read("json/dongfu_building.json");int level=0;for(rapidjson::SizeType i=0;i<data.Size();++i){const auto& r=data[i];if(N(r,"enabled")!=1||!r.HasMember("function_type")||!r["function_type"].IsString()||std::string(r["function_type"].GetString())!="spirit")continue;if(level||N(r,"open_level")<1)throw std::runtime_error("聚灵阵建筑配置重复或开放等级错误");level=N(r,"open_level");}return level;}
void EnsureSchema(gyu::db::CDatabaseSql* db)
{
    if(!db->ExecuteScript("CREATE TABLE IF NOT EXISTS unity_spirit(role_id INTEGER PRIMARY KEY REFERENCES role_info(id) ON DELETE CASCADE,record_id INTEGER NOT NULL,revision INTEGER NOT NULL DEFAULT 0);CREATE TABLE IF NOT EXISTS unity_spirit_request(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,request_id TEXT NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(role_id,request_id));CREATE TABLE IF NOT EXISTS unity_spirit_root(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,root_type INTEGER NOT NULL,record_id INTEGER NOT NULL,PRIMARY KEY(role_id,root_type));"))throw std::runtime_error("聚灵阵存档初始化失败");
    for(const auto& table:std::vector<std::pair<std::string,std::vector<std::string>>>{{"unity_spirit",{"spirit","last_ms","production_rate","production_remainder","production_period_ms","production_capacity"}},{"unity_spirit_request",{"operation"}}}){SQL(db,"PRAGMA table_info("+table.first+")");std::set<std::string> columns;while(char** row=db->GetRow())columns.insert(row[1]);for(const auto& col:table.second)if(!columns.count(col))SQL(db,"ALTER TABLE "+table.first+" ADD COLUMN "+col+" INTEGER NOT NULL DEFAULT "+(col=="operation"?"1":col=="production_period_ms"?"1000":col=="production_capacity"?"9223372036854775807":"0"));}
}
SUnitySpiritBonus BuildBonus(const Config& c,const std::array<int,6>& records)
{
    SUnitySpiritBonus result;spirit::PositionAttributes totals;int64 growth=0,yield=0;
    for(int type=1;type<=5;++type){if(!records[type])continue;const auto& current=c.roots.at(records[type]);growth+=current.growth;yield+=current.yield;int id=InitialRoot(c,type);while(id){const auto& row=c.roots.at(id);spirit::AddLevelAttributes(totals,row.positions,row.attributes);if(id==current.id)break;id=row.next;}if(id!=current.id)throw std::runtime_error("灵根等级不在对应升级链中");}
    if(growth>=10000||yield>INT_MAX)throw std::runtime_error("五行灵根生产加成总值超出范围");result.growth=static_cast<int>(growth);result.yield=static_cast<int>(yield);
    for(int slot=1;slot<=5;++slot)for(const auto& attr:totals[slot])result.positionAttributes[slot].emplace_back(static_cast<uint16>(attr.first),attr.second);return result;
}
void SaveWallet(CUser* u,gyu::db::CDatabaseSql* db){const auto& w=u->m_unitySpiritWallet;SQL(db,"UPDATE unity_spirit SET spirit="+std::to_string(w.amount)+",last_ms="+std::to_string(w.last)+",production_rate="+std::to_string(w.rate)+",production_remainder="+std::to_string(w.remainder)+",production_period_ms="+std::to_string(w.period)+",production_capacity="+std::to_string(w.capacity)+" WHERE role_id="+std::to_string(u->GetRoleId()));}
void ReadState(CUser* u,gyu::db::CDatabaseSql* db,const Config& c)
{
    EnsureSchema(db);u->m_unitySpiritOpenLevel=OpenLevel();
    SQL(db,"SELECT record_id,revision,spirit,last_ms,production_rate,production_remainder,production_period_ms,production_capacity FROM unity_spirit WHERE role_id="+std::to_string(u->GetRoleId()));char** row=db->GetRow();
    u->m_unitySpiritRecord=row?atoi(row[0]):InitialArray(c);u->m_unitySpiritRevision=row?atoll(row[1]):0;u->m_unitySpiritWallet=spirit::Wallet();
    if(row){u->m_unitySpiritWallet.amount=atoll(row[2]);u->m_unitySpiritWallet.last=atoll(row[3]);u->m_unitySpiritWallet.rate=atoll(row[4]);u->m_unitySpiritWallet.remainder=atoll(row[5]);u->m_unitySpiritWallet.period=atoll(row[6]);u->m_unitySpiritWallet.capacity=atoll(row[7]);}
    if(u->m_unitySpiritRecord==0)u->m_unitySpiritRecord=InitialArray(c);
    if(!c.arrays.empty()&&!c.arrays.count(u->m_unitySpiritRecord))throw std::runtime_error("当前聚灵阵等级配置失效");
    SQL(db,"INSERT OR IGNORE INTO unity_spirit(role_id,record_id,revision) VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(u->m_unitySpiritRecord)+",0)");
    if(u->m_unitySpiritRecord)SQL(db,"UPDATE unity_spirit SET record_id="+std::to_string(u->m_unitySpiritRecord)+" WHERE role_id="+std::to_string(u->GetRoleId())+" AND record_id=0");
    spirit::Accrue(u->m_unitySpiritWallet,Now());
    bool unlocked=c.arrays.count(u->m_unitySpiritRecord)&&u->m_unitySpiritOpenLevel>0&&u->GetLevel()>=u->m_unitySpiritOpenLevel;
    u->m_unitySpiritWallet.rate=unlocked?c.arrays.at(u->m_unitySpiritRecord).rate:0;if(c.arrays.count(u->m_unitySpiritRecord))u->m_unitySpiritWallet.capacity=c.arrays.at(u->m_unitySpiritRecord).storage;u->m_unitySpiritWallet.amount=std::min(u->m_unitySpiritWallet.amount,u->m_unitySpiritWallet.capacity);if(u->m_unitySpiritWallet.period!=5000)u->m_unitySpiritWallet.remainder=0;u->m_unitySpiritWallet.period=5000;if(u->m_unitySpiritWallet.amount>=u->m_unitySpiritWallet.capacity)u->m_unitySpiritWallet.remainder=0;SaveWallet(u,db);
    u->m_unitySpiritRoots.fill(0);
    for(int type=1;type<=5;++type){int initial=InitialRoot(c,type);if(!initial)continue;SQL(db,"INSERT OR IGNORE INTO unity_spirit_root VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(type)+","+std::to_string(initial)+")");SQL(db,"SELECT record_id FROM unity_spirit_root WHERE role_id="+std::to_string(u->GetRoleId())+" AND root_type="+std::to_string(type));char** root=db->GetRow();int id=root?atoi(root[0]):initial;if(!c.roots.count(id)||c.roots.at(id).type!=type)throw std::runtime_error("当前灵根等级配置失效");u->m_unitySpiritRoots[type]=id;}
    u->m_unitySpiritBonus=c.arrays.empty()?SUnitySpiritBonus():BuildBonus(c,u->m_unitySpiritRoots);
}
V Attrs(const std::vector<std::pair<int,int>>& attrs,A& a){V values(rapidjson::kArrayType);for(const auto& x:attrs){V p(rapidjson::kArrayType);p.PushBack(x.first,a);p.PushBack(x.second,a);values.PushBack(p,a);}return values;}
V Materials(CUser* u,const Costs& costs,A& a){V out(rapidjson::kArrayType);for(const auto& x:costs){V p(rapidjson::kArrayType);p.PushBack(x.first,a);p.PushBack(x.second,a);p.PushBack(static_cast<int64>(x.first==60054?u->m_unitySpiritWallet.amount:static_cast<int64>(u->GetMaterial(x.first))),a);out.PushBack(p,a);}return out;}
std::string Envelope(CUser* u,const Config& c,int op,const std::string& request,const std::string& error)
{
    rapidjson::Document d;d.SetObject();auto& a=d.GetAllocator();d.AddMember("schema",2,a);d.AddMember("operation",op,a);S(d,"request_id",request,a);S(d,"revision",std::to_string(u->m_unitySpiritRevision),a);S(d,"error",error,a);
    bool ready=c.arrays.count(u->m_unitySpiritRecord)&&u->m_unitySpiritOpenLevel>0;bool unlocked=ready&&u->GetLevel()>=u->m_unitySpiritOpenLevel;d.AddMember("configured",ready,a);d.AddMember("unlocked",unlocked,a);d.AddMember("open_level",u->m_unitySpiritOpenLevel,a);d.AddMember("record_id",u->m_unitySpiritRecord,a);d.AddMember("level",ready?c.arrays.at(u->m_unitySpiritRecord).level:0,a);d.AddMember("next_id",ready?c.arrays.at(u->m_unitySpiritRecord).next:0,a);d.AddMember("root_level_cap",ready?c.arrays.at(u->m_unitySpiritRecord).cap:0,a);d.AddMember("spirit_per_second",static_cast<int>(u->m_unitySpiritWallet.rate),a);S(d,"spirit",std::to_string(u->m_unitySpiritWallet.amount),a);S(d,"storage",std::to_string(u->m_unitySpiritWallet.capacity),a);d.AddMember("production_period_ms",5000,a);
    const auto& wallet=u->m_unitySpiritWallet;
    int elapsed=wallet.period==5000&&wallet.rate>0&&wallet.amount<wallet.capacity?static_cast<int>((wallet.remainder+std::max<int64>(0,Now()-wallet.last))%5000):0;
    d.AddMember("production_elapsed_ms",elapsed,a);
    d.AddMember("growth_reduction_bp",u->m_unitySpiritBonus.growth,a);d.AddMember("yield_bonus_bp",u->m_unitySpiritBonus.yield,a);d.AddMember("costs",Materials(u,ready?c.arrays.at(u->m_unitySpiritRecord).costs:Costs(),a),a);
    V roots(rapidjson::kArrayType),positions(rapidjson::kArrayType);
    for(int type=1;type<=5;++type){int id=u->m_unitySpiritRoots[type];bool configured=id&&c.roots.count(id);V root(rapidjson::kObjectType);root.AddMember("root_type",type,a);S(root,"name",configured?c.roots.at(id).name:"",a);root.AddMember("configured",configured,a);root.AddMember("record_id",id,a);root.AddMember("level",configured?c.roots.at(id).level:0,a);root.AddMember("next_id",configured?c.roots.at(id).next:0,a);root.AddMember("growth_reduction_bp",configured?c.roots.at(id).growth:0,a);root.AddMember("yield_bonus_bp",configured?c.roots.at(id).yield:0,a);S(root,"spirit_cost",configured?std::to_string(c.roots.at(id).spiritCost):"0",a);root.AddMember("costs",Materials(u,configured?c.roots.at(id).costs:Costs(),a),a);root.AddMember("combat_attributes",configured?Attrs(c.roots.at(id).attributes,a):V(rapidjson::kArrayType),a);V targets(rapidjson::kArrayType);if(configured)for(int slot:c.roots.at(id).positions)targets.PushBack(slot,a);root.AddMember("target_positions",targets,a);bool capped=configured&&c.roots.at(id).next&&(!ready||c.roots.at(c.roots.at(id).next).level>c.arrays.at(u->m_unitySpiritRecord).cap);root.AddMember("capped",capped,a);roots.PushBack(root,a);}d.AddMember("roots",roots,a);
    auto bonus=CUnitySpiritService::Bonus(u);for(int slot=1;slot<=5;++slot){V p(rapidjson::kObjectType);p.AddMember("position",slot,a);std::vector<std::pair<int,int>> attrs;for(const auto& x:bonus.positionAttributes[slot])attrs.emplace_back(x.attrType,x.attrValue);p.AddMember("attributes",Attrs(attrs,a),a);positions.PushBack(p,a);}d.AddMember("position_attributes",positions,a);
    rapidjson::StringBuffer b;rapidjson::Writer<rapidjson::StringBuffer> w(b);d.Accept(w);return b.GetString();
}
void Send(CUser* u,const std::string& s){CNetMessage m;m.SetType(325);m<<static_cast<uint8>(128)<<s;SingletonSocket::instance().SendMsg(u->GetSock(),m);}
void Package(CUser* u){CNetMessage m;m.SetType(PRO_ROLE_PACKAGE);u->MakePack(m);SingletonSocket::instance().SendMsg(u->GetSock(),m);}
void Refresh(CUser* u){for(uint8 i=1;i<=5;++i)u->UpdateZhenFaPetInfo(i);}
void CheckMaterials(CUser* u,const Costs& costs){int64 yuanbao=0;for(const auto& x:costs){if(x.first==HDAT_YB||x.first==HDAT_BANG_YB)yuanbao+=x.second;else if((x.first==60054?u->m_unitySpiritWallet.amount:static_cast<int64>(u->GetMaterial(x.first)))<x.second)throw std::runtime_error("升级材料不足");}if(yuanbao>u->GetTongBao())throw std::runtime_error("元宝不足");}
void Spend(CUser* u,const Costs& costs){for(const auto& x:costs){if(x.first==HDAT_MONEY)u->SetMoney(static_cast<uint32>(u->GetMoney()-x.second));else if(x.first==HDAT_YB||x.first==HDAT_BANG_YB)u->SetTongBao(u->GetTongBao()-static_cast<int>(x.second));else if(x.first==60054)u->m_unitySpiritWallet.amount-=x.second;else if(!u->DelPackageById(x.first,static_cast<int>(x.second)))throw std::runtime_error("升级材料扣除失败");}}
}
void CUnitySpiritService::Load(CUser* u)
{
    u->m_unitySpiritBonus=SUnitySpiritBonus();u->m_unitySpiritRoots.fill(0);u->m_unitySpiritWallet=spirit::Wallet();u->m_unitySpiritRecord=0;u->m_unitySpiritRevision=0;u->m_unitySpiritOpenLevel=0;
    CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;bool transaction=false;
    try{auto c=ReadConfig();SQL(db,"BEGIN IMMEDIATE");transaction=true;ReadState(u,db,c);SQL(db,"COMMIT");transaction=false;Send(u,Envelope(u,c,0,"",""));}catch(const std::exception& e){if(transaction)db->Query("ROLLBACK");u->m_unitySpiritBonus=SUnitySpiritBonus();u->m_unitySpiritWallet.rate=0;cout<<"[UnitySpirit] "<<e.what()<<endl;}
}
bool CUnitySpiritService::ChangeResource(CUser* u,int64 amount)
{
    if(!u)return false;boost::recursive_mutex::scoped_lock lock(u->m_mutex);CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return false;
    auto before=u->m_unitySpiritWallet;bool transaction=false;
    try{auto config=ReadConfig();SQL(db,"SAVEPOINT spirit_resource");transaction=true;ReadState(u,db,config);auto& w=u->m_unitySpiritWallet;
        if(amount<0){if(amount==INT64_MIN||w.amount< -amount)throw std::runtime_error("灵气不足");w.amount+=amount;}
        else w.amount+=std::min(amount,w.capacity-w.amount);
        if(w.amount>=w.capacity)w.remainder=0;SaveWallet(u,db);SQL(db,"RELEASE spirit_resource");transaction=false;Send(u,Envelope(u,config,0,"",""));return true;
    }catch(const std::exception& e){if(transaction){db->Query("ROLLBACK TO spirit_resource");db->Query("RELEASE spirit_resource");}u->m_unitySpiritWallet=before;cout<<"[UnitySpiritResource] "<<e.what()<<endl;return false;}
}
int64 CUnitySpiritService::Resource(CUser* u){return u?u->m_unitySpiritWallet.amount:0;}
SUnitySpiritBonus CUnitySpiritService::Bonus(CUser* u){return u->m_unitySpiritOpenLevel>0&&u->GetLevel()>=u->m_unitySpiritOpenLevel?u->m_unitySpiritBonus:SUnitySpiritBonus();}
std::vector<SAttrData> CUnitySpiritService::CombatAttributes(CUser* u,int position){if(position<1||position>5)return {};return Bonus(u).positionAttributes[position];}
void CUnitySpiritService::Handle(CUser* u,unsigned char op,const std::string& payload)
{
    if(!u)return;boost::recursive_mutex::scoped_lock lock(u->m_mutex);CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;
    bool transaction=false,mutated=false,committed=false;Config config;std::string request,before;uint32 money=u->GetMoney();int tongbao=u->GetTongBao();int oldRecord=u->m_unitySpiritRecord;int64 oldRevision=u->m_unitySpiritRevision;auto oldBonus=u->m_unitySpiritBonus;auto oldRoots=u->m_unitySpiritRoots;auto oldWallet=u->m_unitySpiritWallet;
    try{
        if(op>2||payload.size()>2048)throw std::runtime_error("不支持的聚灵阵操作");config=ReadConfig();rapidjson::Document input;input.Parse(payload.c_str());if(input.HasParseError()||!input.IsObject()||!input.HasMember("request_id")||!input["request_id"].IsString())throw std::runtime_error("聚灵阵请求格式错误");request=input["request_id"].GetString();if(request.empty()||request.size()>64)throw std::runtime_error("请求标识错误");
        SQL(db,"BEGIN IMMEDIATE");transaction=true;ReadState(u,db,config);oldRecord=u->m_unitySpiritRecord;oldRevision=u->m_unitySpiritRevision;oldBonus=u->m_unitySpiritBonus;oldRoots=u->m_unitySpiritRoots;oldWallet=u->m_unitySpiritWallet;
        if(op){
            SQL(db,"SELECT payload,operation FROM unity_spirit_request WHERE role_id="+std::to_string(u->GetRoleId())+" AND request_id="+Q(request));char** replay=db->GetRow();if(replay){if(payload!=replay[0]||op!=atoi(replay[1]))throw std::runtime_error("重复请求内容不一致");SQL(db,"COMMIT");transaction=false;Send(u,Envelope(u,config,op,request,""));Refresh(u);return;}
            if(config.arrays.empty()||u->m_unitySpiritOpenLevel<1)throw std::runtime_error("聚灵阵正式配置尚未启用");if(u->GetLevel()<u->m_unitySpiritOpenLevel)throw std::runtime_error("等级不足，聚灵阵尚未开放");if(!input.HasMember("revision")||!input["revision"].IsString()||std::to_string(u->m_unitySpiritRevision)!=input["revision"].GetString())throw std::runtime_error("阵法状态已变化，请重新同步");
            Costs costs;int type=0,next=0;int64 spiritCost=0;
            if(op==1){const auto& current=config.arrays.at(u->m_unitySpiritRecord);if(!current.next)throw std::runtime_error("聚灵阵已满级");next=current.next;costs=current.costs;}
            else{type=N(input,"root_type");if(type<1||type>5||!u->m_unitySpiritRoots[type])throw std::runtime_error("该灵根正式配置尚未启用");const auto& current=config.roots.at(u->m_unitySpiritRoots[type]);if(!current.next)throw std::runtime_error("该灵根已满级");next=current.next;if(config.roots.at(next).level>config.arrays.at(u->m_unitySpiritRecord).cap)throw std::runtime_error("请先升级聚灵阵，提高灵根等级上限");costs=current.costs;spiritCost=current.spiritCost;if(u->m_unitySpiritWallet.amount<spiritCost)throw std::runtime_error("灵气不足");}
            CheckMaterials(u,costs);u->GetPackage(before);if(before.empty())throw std::runtime_error("背包读取失败");mutated=true;Spend(u,costs);u->m_unitySpiritWallet.amount-=spiritCost;
            if(op==1){u->m_unitySpiritRecord=next;u->m_unitySpiritWallet.rate=config.arrays.at(next).rate;u->m_unitySpiritWallet.capacity=config.arrays.at(next).storage;SQL(db,"UPDATE unity_spirit SET record_id="+std::to_string(next)+" WHERE role_id="+std::to_string(u->GetRoleId()));}
            else{u->m_unitySpiritRoots[type]=next;SQL(db,"UPDATE unity_spirit_root SET record_id="+std::to_string(next)+" WHERE role_id="+std::to_string(u->GetRoleId())+" AND root_type="+std::to_string(type));}
            ++u->m_unitySpiritRevision;u->m_unitySpiritBonus=BuildBonus(config,u->m_unitySpiritRoots);SQL(db,"UPDATE unity_spirit SET revision="+std::to_string(u->m_unitySpiritRevision)+" WHERE role_id="+std::to_string(u->GetRoleId()));SaveWallet(u,db);
            std::string bag;u->GetPackage(bag);SQL(db,"UPDATE role_info SET package="+Q(bag)+",money="+std::to_string(u->GetMoney())+" WHERE id="+std::to_string(u->GetRoleId()));SQL(db,"UPDATE "+GetUserInfoTab(u->GetServerId())+" SET money="+std::to_string(u->GetTongBao())+" WHERE id="+std::to_string(u->GetUserId()));SQL(db,"INSERT INTO unity_spirit_request(role_id,request_id,payload,operation) VALUES("+std::to_string(u->GetRoleId())+","+Q(request)+","+Q(payload)+","+std::to_string(op)+")");
        }
        SQL(db,"COMMIT");transaction=false;committed=true;
        if(op){u->SendUpdateInfo(EUUT_YB);u->SendUpdateInfo(EUUT_Money);Package(u);Refresh(u);}Send(u,Envelope(u,config,op,request,""));
    }catch(const std::exception& e){if(transaction)db->Query("ROLLBACK");if(!committed){if(mutated){u->SetPackage(&before[0]);u->m_money=money;u->SetTongBao(tongbao);u->SendUpdateInfo(EUUT_YB);Package(u);u->SendUpdateInfo(EUUT_Money);}u->m_unitySpiritRecord=oldRecord;u->m_unitySpiritRevision=oldRevision;u->m_unitySpiritBonus=oldBonus;u->m_unitySpiritRoots=oldRoots;u->m_unitySpiritWallet=oldWallet;}Send(u,Envelope(u,config,op,request,e.what()));}
}
