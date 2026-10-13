#include "library_unity.h"
#include "library_rules.h"
#include "user.h"
#include "init.h"
#include "singleton.h"
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#include <chrono>
#include <fstream>
#include <sstream>
#include <random>
#include <limits>

namespace {
using V = rapidjson::Value;
using A = rapidjson::Document::AllocatorType;
struct JsonArrayRange {
    const V& value;
    V::ConstValueIterator begin() const { return value.Begin(); }
    V::ConstValueIterator end() const { return value.End(); }
};
JsonArrayRange Array(const V& value) { return {value}; }
struct Book { int id=0, item=0, set=0; };
struct BookSet { int id=0, realm=0, level=0; std::vector<int> books; };
struct Reward { int id=0, set=0, count=0; std::string kind; std::vector<int> required; std::vector<SAttrData> attrs; };
struct Source { int chance=0, quantity=0, current=0, older=0; };
struct Config { int open=0; std::map<int,Book> books; std::map<int,int> itemBooks; std::map<int,BookSet> sets;
    std::map<int,Reward> rewards; std::map<int,std::pair<int,int>> realms; std::map<std::string,Source> sources; };
int64 Now() { return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count(); }
std::string Q(const std::string& s) { std::string r="'";for(char c:s){r+=c;if(c=='\'')r+='\'';}return r+"'"; }
void SQL(gyu::db::CDatabaseSql* db,const std::string& s) { if(!db->Query(s.c_str()))throw std::runtime_error("藏书阁存档失败"); }
rapidjson::Document Read(const char* file) { std::ifstream f(std::string("json/")+file);if(!f)throw std::runtime_error("藏书阁配置缺失");std::ostringstream s;s<<f.rdbuf();rapidjson::Document d;d.Parse(s.str().c_str());if(d.HasParseError()||!d.IsArray())throw std::runtime_error("藏书阁配置格式错误");return d; }
int N(const V& v,const char* key) { if(!v.HasMember(key)||!v[key].IsInt())throw std::runtime_error(std::string("藏书配置整数错误：")+key);return v[key].GetInt(); }
std::string T(const V& v,const char* key) { if(!v.HasMember(key)||!v[key].IsString())throw std::runtime_error("藏书配置文本错误");return v[key].GetString(); }
std::vector<int> IDs(const V& v,const char* key) { if(!v.HasMember(key)||!v[key].IsArray())throw std::runtime_error("藏书书目配置错误");std::vector<int> result;std::set<int> seen;for(const auto& x:Array(v[key])){if(!x.IsInt()||x.GetInt()<1||!seen.insert(x.GetInt()).second)throw std::runtime_error("藏书书目重复或错误");result.push_back(x.GetInt());}return result; }
Config ReadConfig() {
    Config c;auto buildings=Read("dongfu_building.json");
    for(const auto& r:Array(buildings))if(N(r,"enabled")==1&&T(r,"function_type")=="library"){if(c.open)throw std::runtime_error("藏书阁建筑重复");c.open=N(r,"open_level");}
    auto realms=Read("jingjie_realm.json");for(const auto& r:Array(realms))if(N(r,"enabled")==1){int id=N(r,"realm_id"),first=N(r,"first_jingjie_id"),last=N(r,"last_jingjie_id");if(id<1||first<1||last<first||!c.realms.emplace(id,std::make_pair(first,last)).second)throw std::runtime_error("藏书境界配置错误");}
    auto sets=Read("dongfu_book_set.json");for(const auto& r:Array(sets))if(N(r,"enabled")==1){BookSet s;s.id=N(r,"id");s.realm=N(r,"realm_id");s.level=N(r,"open_level");s.books=IDs(r,"book_ids");if(s.books.empty()||s.books.size()>4||!c.realms.count(s.realm)||s.level<1||!c.sets.emplace(s.id,s).second)throw std::runtime_error("藏书套装配置错误");}
    auto books=Read("dongfu_book.json");for(const auto& r:Array(books))if(N(r,"enabled")==1){Book b;b.id=N(r,"id");b.item=N(r,"item_id");b.set=N(r,"set_id");if(b.item<1||b.item>=60000||!c.sets.count(b.set)||!c.books.emplace(b.id,b).second||!c.itemBooks.emplace(b.item,b.id).second)throw std::runtime_error("藏书道具配置错误");auto* item=SingletonItemManager::instance().GetItem(b.item);if(!item||item->jiage<0)throw std::runtime_error("藏书道具或出售价格缺失");}
    for(const auto& e:c.sets)for(int id:e.second.books)if(!c.books.count(id)||c.books.at(id).set!=e.first)throw std::runtime_error("藏书套装归属错误");
    std::set<int> single;auto rewards=Read("dongfu_book_reward.json");for(const auto& r:Array(rewards))if(N(r,"enabled")==1){Reward v;v.id=N(r,"id");v.set=N(r,"set_id");v.count=N(r,"required_count");v.kind=T(r,"condition_kind");v.required=IDs(r,"required_book_ids");if(!c.sets.count(v.set)||T(r,"target_scope")!="lineup"||!r.HasMember("attributes")||!r["attributes"].IsArray())throw std::runtime_error("藏书奖励配置错误");
        std::set<int> attrs;for(const auto& p:Array(r["attributes"])){if(!p.IsArray()||p.Size()!=2||!p[0].IsInt()||!p[1].IsInt()||p[0].GetInt()<1||p[0].GetInt()>33||p[1].GetInt()<1||!attrs.insert(p[0].GetInt()).second)throw std::runtime_error("藏书属性配置错误");SAttrData a;a.attrType=p[0].GetInt();a.attrValue=p[1].GetInt();v.attrs.push_back(a);}
        if(v.attrs.empty())throw std::runtime_error("藏书奖励没有属性");const auto& members=c.sets.at(v.set).books;for(int id:v.required)if(std::find(members.begin(),members.end(),id)==members.end())throw std::runtime_error("奖励书目属于其他套装");
        if(v.kind=="book"){if(v.required.size()!=1||v.count||!single.insert(v.required[0]).second)throw std::runtime_error("每本书必须只有一条激活奖励");}
        else if(v.kind=="count"){if(v.count<1||v.count>static_cast<int>(members.size())||!v.required.empty())throw std::runtime_error("藏书数量奖励错误");}
        else if(v.kind=="combination"){if(v.required.size()<2||v.count)throw std::runtime_error("藏书组合奖励错误");}
        else if(v.kind=="complete"){if(v.count||!v.required.empty())throw std::runtime_error("藏书整套奖励错误");}
        else throw std::runtime_error("未知藏书奖励类型");if(!c.rewards.emplace(v.id,v).second)throw std::runtime_error("藏书奖励ID重复");}
    for(const auto& b:c.books)if(!single.count(b.first))throw std::runtime_error("书籍缺少激活奖励");
    auto sources=Read("dongfu_library_source.json");for(const auto& r:Array(sources))if(N(r,"enabled")==1){Source s;s.chance=N(r,"chance_bp");s.quantity=N(r,"quantity");s.current=N(r,"current_realm_bp");s.older=N(r,"older_realm_bp");std::string kind=T(r,"event_kind");if((kind!="world"&&kind!="world_sweep"&&kind!="liezhuan")||s.chance<0||s.chance>10000||s.quantity!=1||s.current<0||s.older<0||s.current+s.older!=10000||!c.sources.emplace(kind,s).second)throw std::runtime_error("藏书投放配置错误");}
    return c;
}
const Config& Definitions() { static const Config c=ReadConfig();return c; }
int Realm(CUser* u,const Config& c) { for(const auto& r:c.realms)if(u->GetJingJie()>=r.second.first&&u->GetJingJie()<=r.second.second)return r.first;return 0; }
void Ensure(gyu::db::CDatabaseSql* db) {
    if(!db->ExecuteScript("CREATE TABLE IF NOT EXISTS unity_library(role_id INTEGER PRIMARY KEY REFERENCES role_info(id) ON DELETE CASCADE,revision INTEGER NOT NULL DEFAULT 0);CREATE TABLE IF NOT EXISTS unity_library_book(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,book_id INTEGER NOT NULL,obtained_ms INTEGER NOT NULL,activated_ms INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(role_id,book_id));CREATE TABLE IF NOT EXISTS unity_library_reward(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,reward_id INTEGER NOT NULL,activated_ms INTEGER NOT NULL,PRIMARY KEY(role_id,reward_id));CREATE TABLE IF NOT EXISTS unity_library_request(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,request_id TEXT NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(role_id,request_id));"))throw std::runtime_error("藏书阁存档初始化失败");
}
std::vector<SAttrData> Attributes(const Config& c,const std::set<int>& rewards) { std::map<int,int64> totals;for(int id:rewards){auto r=c.rewards.find(id);if(r==c.rewards.end())throw std::runtime_error("已激活藏书奖励配置失效");for(const auto& a:r->second.attrs)totals[a.attrType]+=a.attrValue;}std::vector<SAttrData> out;for(const auto& x:totals){if(x.second>INT_MAX)throw std::runtime_error("藏书属性超出范围");SAttrData a;a.attrType=x.first;a.attrValue=static_cast<int>(x.second);out.push_back(a);}return out; }
SUnityLibraryState State(CUser* u,gyu::db::CDatabaseSql* db,const Config& c) {
    SUnityLibraryState s;std::string role=std::to_string(u->GetRoleId());SQL(db,"INSERT OR IGNORE INTO unity_library(role_id) VALUES("+role+")");SQL(db,"SELECT revision FROM unity_library WHERE role_id="+role);char** row=db->GetRow();s.revision=row?atoll(row[0]):0;
    SQL(db,"SELECT book_id,activated_ms FROM unity_library_book WHERE role_id="+role);while((row=db->GetRow())){int id=atoi(row[0]);if(!c.books.count(id))throw std::runtime_error("已收藏书目配置失效");s.obtained.insert(id);if(atoll(row[1])>0)s.activated.insert(id);}
    SQL(db,"SELECT reward_id FROM unity_library_reward WHERE role_id="+role);while((row=db->GetRow()))s.rewards.insert(atoi(row[0]));s.attributes=Attributes(c,s.rewards);s.ready=true;return s;
}
void Revision(CUser* u,gyu::db::CDatabaseSql* db) { SQL(db,"UPDATE unity_library SET revision="+std::to_string(u->m_unityLibrary.revision)+" WHERE role_id="+std::to_string(u->GetRoleId())); }
void SaveInventory(CUser* u,gyu::db::CDatabaseSql* db) { std::string bag;u->GetPackage(bag);if(bag.empty())throw std::runtime_error("藏书背包读取失败");SQL(db,"UPDATE role_info SET package="+Q(bag)+",money="+std::to_string(u->GetMoney())+" WHERE id="+std::to_string(u->GetRoleId())); }
V IdArray(const std::set<int>& ids,A& a) { V out(rapidjson::kArrayType);for(int id:ids)out.PushBack(id,a);return out; }
void Text(V& o,const char* k,const std::string& value,A& a) { o.AddMember(V(k,a),V(value.c_str(),a),a); }
std::string Envelope(CUser* u,const Config* c,unsigned char op,const std::string& request,const std::string& error) {
    rapidjson::Document d;d.SetObject();auto& a=d.GetAllocator();d.AddMember("schema",1,a);d.AddMember("operation",op,a);Text(d,"request_id",request,a);Text(d,"revision",std::to_string(u->m_unityLibrary.revision),a);Text(d,"error",error,a);Text(d,"gold",std::to_string(u->GetMoney()),a);
    bool configured=c&&c->open>0&&!c->books.empty()&&u->m_unityLibrary.ready;d.AddMember("configured",configured,a);d.AddMember("unlocked",configured&&u->GetLevel()>=c->open,a);d.AddMember("realm_id",c?Realm(u,*c):0,a);
    d.AddMember("obtained",IdArray(u->m_unityLibrary.obtained,a),a);d.AddMember("activated_books",IdArray(u->m_unityLibrary.activated,a),a);d.AddMember("activated_rewards",IdArray(u->m_unityLibrary.rewards,a),a);
    V owned(rapidjson::kArrayType),attrs(rapidjson::kArrayType);if(c)for(const auto& b:c->books){int count=u->GetMaterial(b.second.item);if(count>0){V pair(rapidjson::kArrayType);pair.PushBack(b.first,a);pair.PushBack(count,a);owned.PushBack(pair,a);}}
    for(const auto& x:u->m_unityLibrary.attributes){V pair(rapidjson::kArrayType);pair.PushBack(x.attrType,a);pair.PushBack(x.attrValue,a);attrs.PushBack(pair,a);}d.AddMember("owned",owned,a);d.AddMember("attributes",attrs,a);
    rapidjson::StringBuffer buffer;rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);d.Accept(writer);if(buffer.GetSize()>60000)throw std::runtime_error("藏书状态超过协议容量");return buffer.GetString();
}
void Send(CUser* u,const Config* c,unsigned char op=0,const std::string& request="",const std::string& error="") { CNetMessage m;m.SetType(326);m<<static_cast<uint8>(128)<<Envelope(u,c,op,request,error);SingletonSocket::instance().SendMsg(u->GetSock(),m); }
void Package(CUser* u) { CNetMessage m;m.SetType(PRO_ROLE_PACKAGE);u->MakePack(m);SingletonSocket::instance().SendMsg(u->GetSock(),m); }
void Refresh(CUser* u) { for(uint8 i=1;i<=5;++i)u->UpdateZhenFaPetInfo(i); }
}

void CUnityLibraryService::Load(CUser* u) {
    boost::recursive_mutex::scoped_lock lock(u->m_mutex);
    u->m_unityLibrary=SUnityLibraryState();CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;bool transaction=false;
    try{const auto& c=Definitions();Ensure(db);SQL(db,"SAVEPOINT library_load");transaction=true;u->m_unityLibrary=State(u,db,c);
        for(const auto& b:c.books)if(u->GetMaterial(b.second.item)>0&&!u->m_unityLibrary.obtained.count(b.first)){SQL(db,"INSERT INTO unity_library_book(role_id,book_id,obtained_ms) VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(b.first)+","+std::to_string(Now())+")");u->m_unityLibrary.obtained.insert(b.first);++u->m_unityLibrary.revision;}
        Revision(u,db);SQL(db,"RELEASE library_load");transaction=false;
    }catch(const std::exception& e){if(transaction){db->Query("ROLLBACK TO library_load");db->Query("RELEASE library_load");}u->m_unityLibrary=SUnityLibraryState();cout<<"[UnityLibrary] load: "<<e.what()<<endl;}
}
void CUnityLibraryService::Obtained(CUser* u,int itemId,int count) {
    boost::recursive_mutex::scoped_lock lock(u->m_mutex);
    if(count<1||!u->m_unityLibrary.ready)return;const auto& c=Definitions();auto book=c.itemBooks.find(itemId);if(book==c.itemBooks.end()||u->m_unityLibrary.obtained.count(book->second))return;
    CGetDbConnect connection;auto* db=connection.GetDbConnect();bool transaction=false;auto before=u->m_unityLibrary;
    try{SQL(db,"SAVEPOINT library_obtained");transaction=true;SQL(db,"INSERT OR IGNORE INTO unity_library_book(role_id,book_id,obtained_ms) VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(book->second)+","+std::to_string(Now())+")");u->m_unityLibrary.obtained.insert(book->second);++u->m_unityLibrary.revision;Revision(u,db);SaveInventory(u,db);SQL(db,"RELEASE library_obtained");transaction=false;Send(u,&c);}
    catch(const std::exception& e){if(transaction){db->Query("ROLLBACK TO library_obtained");db->Query("RELEASE library_obtained");}u->m_unityLibrary=before;cout<<"[UnityLibrary] obtained: "<<e.what()<<endl;}
}
bool CUnityLibraryService::AutoSell(CUser* u,int itemId,int count) {
    boost::recursive_mutex::scoped_lock lock(u->m_mutex);
    if(!u->m_unityLibrary.ready)return false;const auto& c=Definitions();auto b=c.itemBooks.find(itemId);if(b==c.itemBooks.end()||!u->m_unityLibrary.activated.count(b->second))return false;
    auto* item=SingletonItemManager::instance().GetItem(itemId);if(!item)throw std::runtime_error("藏书出售道具配置缺失");int64 sale=library::Sale(item->jiage,count);CGetDbConnect connection;auto* db=connection.GetDbConnect();uint32 before=u->m_money;bool transaction=false;
    try{SQL(db,"SAVEPOINT library_sale");transaction=true;u->m_money=static_cast<int>(std::min<int64>(CUser::MAX_MONEY,static_cast<int64>(u->m_money)+sale));SaveInventory(u,db);SQL(db,"RELEASE library_sale");transaction=false;u->SendUpdateInfo(EUUT_Money);Send(u,&c);return true;}
    catch(...){if(transaction){db->Query("ROLLBACK TO library_sale");db->Query("RELEASE library_sale");}u->m_money=before;throw;}
}
std::vector<SAttrData> CUnityLibraryService::CombatAttributes(CUser* u) { return u&&u->m_unityLibrary.ready?u->m_unityLibrary.attributes:std::vector<SAttrData>(); }
void CUnityLibraryService::Handle(CUser* u,unsigned char op,const std::string& payload) {
    boost::recursive_mutex::scoped_lock lock(u->m_mutex);
    CGetDbConnect connection;auto* db=connection.GetDbConnect();if(!db||!db->IsSqlite())return;const Config* config=nullptr;std::string request,bag;auto before=u->m_unityLibrary;bool transaction=false,mutated=false,committed=false;
    try{if(op>1||payload.size()>2048)throw std::runtime_error("不支持的藏书阁操作");config=&Definitions();rapidjson::Document input;input.Parse(payload.c_str());if(input.HasParseError()||!input.IsObject())throw std::runtime_error("藏书阁请求错误");request=T(input,"request_id");if(request.empty()||request.size()>64)throw std::runtime_error("藏书请求标识错误");Ensure(db);SQL(db,"SAVEPOINT library_command");transaction=true;u->m_unityLibrary=State(u,db,*config);before=u->m_unityLibrary;
        if(op){SQL(db,"SELECT payload FROM unity_library_request WHERE role_id="+std::to_string(u->GetRoleId())+" AND request_id="+Q(request));char** replay=db->GetRow();if(replay){if(payload!=replay[0])throw std::runtime_error("重复请求内容不一致");SQL(db,"RELEASE library_command");transaction=false;committed=true;Send(u,config,op,request);return;}
            if(config->open<1||u->GetLevel()<config->open)throw std::runtime_error("藏书阁尚未开放");int id=N(input,"reward_id");auto found=config->rewards.find(id);if(found==config->rewards.end())throw std::runtime_error("藏书奖励不存在");const auto& reward=found->second;const auto& set=config->sets.at(reward.set);
            if(!u->m_unityLibrary.rewards.count(id)){
                if(T(input,"revision")!=std::to_string(u->m_unityLibrary.revision))throw std::runtime_error("藏书状态已变化，请重新同步");if(Realm(u,*config)<set.realm||u->GetLevel()<set.level)throw std::runtime_error("尚未达到该书套境界");
                if(reward.kind=="book"){int book=reward.required.at(0),item=config->books.at(book).item;if(u->m_unityLibrary.activated.count(book))throw std::runtime_error("该书籍已激活");if(u->GetMaterial(item)<1)throw std::runtime_error("当前背包没有该书籍");u->GetPackage(bag);mutated=true;if(!u->DelPackageById(item,1))throw std::runtime_error("书籍扣除失败");SQL(db,"INSERT OR IGNORE INTO unity_library_book(role_id,book_id,obtained_ms) VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(book)+","+std::to_string(Now())+")");SQL(db,"UPDATE unity_library_book SET activated_ms="+std::to_string(Now())+" WHERE role_id="+std::to_string(u->GetRoleId())+" AND book_id="+std::to_string(book));u->m_unityLibrary.obtained.insert(book);u->m_unityLibrary.activated.insert(book);}
                else if(!library::Satisfied(reward.kind,reward.count,reward.required,set.books,u->m_unityLibrary.activated))throw std::runtime_error("请先激活所需书籍");
                SQL(db,"INSERT INTO unity_library_reward VALUES("+std::to_string(u->GetRoleId())+","+std::to_string(id)+","+std::to_string(Now())+")");u->m_unityLibrary.rewards.insert(id);u->m_unityLibrary.attributes=Attributes(*config,u->m_unityLibrary.rewards);++u->m_unityLibrary.revision;Revision(u,db);SaveInventory(u,db);
            }
            SQL(db,"INSERT INTO unity_library_request VALUES("+std::to_string(u->GetRoleId())+","+Q(request)+","+Q(payload)+")");
        }
        SQL(db,"RELEASE library_command");transaction=false;committed=true;if(op){Package(u);Refresh(u);}Send(u,config,op,request);
    }catch(const std::exception& e){if(transaction){db->Query("ROLLBACK TO library_command");db->Query("RELEASE library_command");}if(!committed){if(mutated&&!bag.empty()){u->m_unityLibrary.ready=false;u->SetPackage(&bag[0]);}u->m_unityLibrary=before;}Package(u);Send(u,config,op,request,e.what());}
}
void CUnityLibraryService::AddSourceAward(CUser* u,const std::string& kind,MultiAward& awards) {
    boost::recursive_mutex::scoped_lock lock(u->m_mutex);
    if(!u->m_unityLibrary.ready)return;const auto& c=Definitions();auto source=c.sources.find(kind);if(source==c.sources.end()||c.open<1||u->GetLevel()<c.open)return;const auto& s=source->second;
    static thread_local std::mt19937 rng(std::random_device{}());auto draw=[&](int n){return std::uniform_int_distribution<int>(0,n-1)(rng);};if(draw(10000)>=s.chance)return;int current=Realm(u,c);if(current<1)return;
    std::set<int> old;for(const auto& set:c.sets)if(set.second.realm<current&&std::any_of(set.second.books.begin(),set.second.books.end(),[&](int id){return !u->m_unityLibrary.activated.count(id);}))old.insert(set.second.realm);
    int selected=current;if(!old.empty()&&draw(10000)>=s.current){auto it=old.begin();std::advance(it,draw(static_cast<int>(old.size())));selected=*it;}
    std::vector<int> items;for(const auto& b:c.books){const auto& set=c.sets.at(b.second.set);if(set.realm==selected&&u->GetLevel()>=set.level)items.push_back(b.second.item);}if(items.empty())return;SAwardData award;award.type=items.at(draw(static_cast<int>(items.size())));award.num=s.quantity;awards.push_back(award);
}
