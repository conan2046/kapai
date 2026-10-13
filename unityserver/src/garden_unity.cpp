#include "garden_unity.h"
#include "garden_growth.h"
#include "spirit_unity.h"
#include "spirit_math.h"
#include "jingjie_unity.h"
#include "user.h"
#include "init.h"
#include "singleton.h"
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"
#include <fstream>
#include <sstream>
#include <map>
#include <vector>
#include <stdexcept>

namespace
{
    using rapidjson::Value;
    using Alloc=rapidjson::Document::AllocatorType;
    constexpr int GardenCommand=324;
    struct Crop { int id=0,seed=0,extensionBp=0,middleBp=0,seedPrice=0;int64 duration=0,waterDelay=0,bugDelay=0;std::string name;std::vector<std::pair<int,int>> outputs; };
    struct Plot { int id=0,realm=0,crop=0,yieldBp=0;int64 revision=0,duration=0;garden::Growth growth; };
    std::string Quote(const std::string& text){std::string s="'";for(char c:text){s+=c;if(c=='\'')s+='\'';}return s+"'";}
    std::string Encode(const Value& value){rapidjson::StringBuffer b;rapidjson::Writer<rapidjson::StringBuffer> w(b);value.Accept(w);return b.GetString();}
    void String(Value& value,const char* key,const std::string& text,Alloc& a){value.AddMember(Value(key,a),Value(text.c_str(),a),a);}
    int Number(const Value& row,const char* key){if(!row.IsObject()||!row.HasMember(key)||!row[key].IsInt())throw std::runtime_error(std::string("灵园字段错误：")+key);return row[key].GetInt();}
    rapidjson::Document Read(const char* path){std::ifstream f(path);if(!f)throw std::runtime_error("灵园配置缺失");std::ostringstream s;s<<f.rdbuf();rapidjson::Document d;d.Parse(s.str().c_str());if(d.HasParseError()||!d.IsArray())throw std::runtime_error("灵园配置格式错误");return d;}
    void Send(CUser* user,const std::string& json){CNetMessage m;m.SetType(GardenCommand);m<<static_cast<uint8>(128)<<json;SingletonSocket::instance().SendMsg(user->GetSock(),m);}
    void Bag(CUser* user){CNetMessage m;m.SetType(PRO_ROLE_PACKAGE);user->MakePack(m);SingletonSocket::instance().SendMsg(user->GetSock(),m);}
    void Execute(gyu::db::CDatabaseSql* db,const std::string& sql){if(!db->Query(sql.c_str()))throw std::runtime_error("灵园存档操作失败");}
    const char* Schema=
        "CREATE TABLE IF NOT EXISTS unity_garden_plot(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,plot_id INTEGER NOT NULL CHECK(plot_id BETWEEN 1 AND 36),crop_id INTEGER NOT NULL DEFAULT 0,progress INTEGER NOT NULL DEFAULT 0,last_ms INTEGER NOT NULL DEFAULT 0,water_at INTEGER NOT NULL DEFAULT 0,bug_at INTEGER NOT NULL DEFAULT 0,needs_water INTEGER NOT NULL DEFAULT 0,has_bugs INTEGER NOT NULL DEFAULT 0,revision INTEGER NOT NULL DEFAULT 0,progress_scale INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(role_id,plot_id));"
        "CREATE TABLE IF NOT EXISTS unity_garden_request(role_id INTEGER NOT NULL REFERENCES role_info(id) ON DELETE CASCADE,request_id TEXT NOT NULL,operation INTEGER NOT NULL,payload TEXT NOT NULL,response TEXT NOT NULL,PRIMARY KEY(role_id,request_id));";
    void Save(gyu::db::CDatabaseSql* db,uint32 role,const Plot& p)
    {
        std::ostringstream s;s<<"INSERT INTO unity_garden_plot(role_id,plot_id,crop_id,progress,last_ms,water_at,bug_at,needs_water,has_bugs,revision,progress_scale,spirit_duration_ms,spirit_yield_bp) VALUES("<<role<<","<<p.id<<","<<p.crop<<","<<p.growth.progress<<","<<p.growth.last<<","<<p.growth.waterAt<<","<<p.growth.bugAt<<","<<p.growth.water<<","<<p.growth.bug<<","<<p.revision<<","<<p.growth.scale<<","<<p.duration<<","<<p.yieldBp<<") ON CONFLICT(role_id,plot_id) DO UPDATE SET crop_id=excluded.crop_id,progress=excluded.progress,last_ms=excluded.last_ms,water_at=excluded.water_at,bug_at=excluded.bug_at,needs_water=excluded.needs_water,has_bugs=excluded.has_bugs,revision=excluded.revision,progress_scale=excluded.progress_scale,spirit_duration_ms=excluded.spirit_duration_ms,spirit_yield_bp=excluded.spirit_yield_bp";
        Execute(db,s.str());
    }
    std::string Envelope(CUser* user,const std::vector<Plot>& plots,const std::map<int,Crop>& crops,int64 now,const std::string& request,const std::string& error="",int operation=0)
    {
        rapidjson::Document d;d.SetObject();auto& a=d.GetAllocator();d.AddMember("schema",1,a);d.AddMember("operation",operation,a);String(d,"request_id",request,a);String(d,"error",error,a);String(d,"server_ms",std::to_string(now),a);d.AddMember("realm_id",user->GetJingJie(),a);
        Value rows(rapidjson::kArrayType);
        for(const auto& p:plots){Value r(rapidjson::kObjectType);r.AddMember("id",p.id,a);r.AddMember("required_realm",p.realm,a);r.AddMember("unlocked",user->GetJingJie()>=p.realm,a);r.AddMember("crop_id",p.crop,a);r.AddMember("water",p.growth.water,a);r.AddMember("bugs",p.growth.bug,a);String(r,"revision",std::to_string(p.revision),a);String(r,"progress_units",std::to_string(p.growth.progress),a);
            auto it=crops.find(p.crop);int64 duration=p.duration>0?p.duration:(it==crops.end()?0:it->second.duration);int middle=it==crops.end()?0:it->second.middleBp,extension=it==crops.end()?0:it->second.extensionBp;int scale=p.growth.scale>0?p.growth.scale:10000+extension;int64 target=duration*scale,middleAt=(target/10000)*middle+(target%10000)*middle/10000;r.AddMember("duration_ms",duration,a);r.AddMember("spirit_yield_bp",p.yieldBp,a);r.AddMember("progress_scale",scale,a);r.AddMember("stage",p.crop==0?0:(p.growth.progress>=target?3:(p.growth.progress>=middleAt?2:1)),a);String(r,"remaining_ms",std::to_string(garden::Remaining(p.growth,duration,extension)),a);rows.PushBack(r,a);}
        d.AddMember("plots",rows,a);Value stock(rapidjson::kArrayType);for(const auto& entry:crops){Value s(rapidjson::kObjectType);s.AddMember("crop_id",entry.first,a);s.AddMember("seed_item_id",entry.second.seed,a);s.AddMember("count",user->GetItemNum(entry.second.seed),a);stock.PushBack(s,a);}d.AddMember("stock",stock,a);return Encode(d);
    }
}

void CUnityGardenService::Handle(CUser* user,unsigned char operation,const std::string& payload)
{
    if(!user)return;
    boost::recursive_mutex::scoped_lock lock(user->m_mutex);
    CGetDbConnect connection;auto* db=connection.GetDbConnect();
    if(!db||!db->IsSqlite())return;
    bool transaction=false,committed=false,bagChanged=false,moneyChanged=false;uint32 beforeMoney=user->GetMoney();std::string before,request;std::vector<Plot> plots;std::vector<int> gained;std::map<int,Crop> crops;int64 now=CUnityJingJieService::NowMs();
    try
    {
        if(operation>6||payload.size()>1024)throw std::runtime_error("不支持的灵园操作");
        if(!db->ExecuteScript(Schema))throw std::runtime_error("灵园存档初始化失败");
        Execute(db,"PRAGMA table_info(unity_garden_plot)");bool hasDuration=false,hasYield=false;while(char** r=db->GetRow()){hasDuration|=std::string(r[1])=="spirit_duration_ms";hasYield|=std::string(r[1])=="spirit_yield_bp";}
        if(!hasDuration)Execute(db,"ALTER TABLE unity_garden_plot ADD COLUMN spirit_duration_ms INTEGER NOT NULL DEFAULT 0");
        if(!hasYield)Execute(db,"ALTER TABLE unity_garden_plot ADD COLUMN spirit_yield_bp INTEGER NOT NULL DEFAULT 0");
        rapidjson::Document input;input.Parse(payload.c_str());if(input.HasParseError()||!input.IsObject())throw std::runtime_error("灵园请求格式错误");
        if(operation!=0){if(!input.HasMember("request_id")||!input["request_id"].IsString())throw std::runtime_error("缺少请求标识");request=input["request_id"].GetString();if(request.empty()||request.size()>64)throw std::runtime_error("请求标识错误");}
        auto config=Read("json/dongfu_garden_plot.json");std::map<int,int> realms;
        for(rapidjson::SizeType i=0;i<config.Size();++i){const auto& r=config[i];int id=Number(r,"id"),realm=Number(r,"unlock_realm_id");if(id<1||id>36||realm<1||realm>550||realms.count(id)||Number(r,"enabled")!=1)throw std::runtime_error("灵园地块配置错误");realms[id]=realm;}
        if(realms.size()!=36)throw std::runtime_error("灵园需配置36块地");
        auto definitions=Read("json/dongfu_crop.json");
        for(rapidjson::SizeType i=0;i<definitions.Size();++i){const auto& r=definitions[i];if(Number(r,"enabled")!=1)continue;Crop c;c.id=Number(r,"id");c.seed=Number(r,"seed_item_id");c.duration=static_cast<int64>(Number(r,"grow_seconds"))*1000;c.waterDelay=static_cast<int64>(Number(r,"water_after_seconds"))*1000;c.bugDelay=static_cast<int64>(Number(r,"bug_after_seconds"))*1000;c.extensionBp=Number(r,"abnormal_extension_bp");c.middleBp=Number(r,"middle_progress_bp");if(c.id<1||c.seed<1||c.duration<1||c.duration>86400000000LL||c.waterDelay<0||c.bugDelay<0||c.extensionBp<0||c.extensionBp>100000||c.middleBp<=0||c.middleBp>=10000||crops.count(c.id))throw std::runtime_error("灵植成长配置错误");
            c.seedPrice=Number(r,"seed_price_gold");if(c.seedPrice<0)throw std::runtime_error("种子售价配置错误");if(!r.HasMember("outputs")||!r["outputs"].IsArray())throw std::runtime_error("灵植产出格式错误");for(rapidjson::SizeType n=0;n<r["outputs"].Size();++n){const auto& pair=r["outputs"][n];if(!pair.IsArray()||pair.Size()!=2||!pair[0].IsInt()||!pair[1].IsInt()||pair[0].GetInt()<1||pair[1].GetInt()<1||pair[1].GetInt()>999)throw std::runtime_error("灵植产出配置错误");c.outputs.emplace_back(pair[0].GetInt(),pair[1].GetInt());}if(c.outputs.empty())throw std::runtime_error("灵植未配置产物");crops[c.id]=c;}
        if(crops.empty())throw std::runtime_error("暂无已启用的灵植");
        Execute(db,"BEGIN IMMEDIATE");transaction=true;
        if(operation!=0){Execute(db,"SELECT operation,payload,response FROM unity_garden_request WHERE role_id="+std::to_string(user->GetRoleId())+" AND request_id="+Quote(request));char** row=db->GetRow();if(row){if(atoi(row[0])!=operation||std::string(row[1])!=payload)throw std::runtime_error("重复请求内容不一致");std::string saved=row[2];Execute(db,"COMMIT");transaction=false;Send(user,saved);Bag(user);return;}}
        std::map<int,Plot> saved;
        Execute(db,"SELECT plot_id,crop_id,progress,last_ms,water_at,bug_at,needs_water,has_bugs,revision,progress_scale,spirit_duration_ms,spirit_yield_bp FROM unity_garden_plot WHERE role_id="+std::to_string(user->GetRoleId()));
        while(char** r=db->GetRow()){Plot p;p.id=atoi(r[0]);p.crop=atoi(r[1]);p.growth.progress=atoll(r[2]);p.growth.last=atoll(r[3]);p.growth.waterAt=atoll(r[4]);p.growth.bugAt=atoll(r[5]);p.growth.water=atoi(r[6])!=0;p.growth.bug=atoi(r[7])!=0;p.revision=atoll(r[8]);p.growth.scale=atoi(r[9]);p.duration=atoll(r[10]);p.yieldBp=atoi(r[11]);saved[p.id]=p;}
        for(const auto& item:realms){Plot p=saved.count(item.first)?saved[item.first]:Plot();p.id=item.first;p.realm=item.second;if(p.crop){if(!crops.count(p.crop))throw std::runtime_error("已种植作物配置失效");const auto& c=crops.at(p.crop);garden::Advance(p.growth,now,p.duration>0?p.duration:c.duration,c.extensionBp);}plots.push_back(p);}
        if(operation!=0)
        {
            user->GetPackage(before);if(before.empty())throw std::runtime_error("背包存档读取失败");
            if(operation==6){int crop=Number(input,"crop_id");if(!crops.count(crop))throw std::runtime_error("种子不存在");const Crop& c=crops.at(crop);int quantity=input.HasMember("quantity")?Number(input,"quantity"):1;if(quantity<1)throw std::runtime_error("购买数量错误");if(c.seedPrice<=0)throw std::runtime_error("该种子不可购买");int64 cost=static_cast<int64>(c.seedPrice)*quantity;if(cost>user->GetMoney())throw std::runtime_error("金币不足");bagChanged=true;for(int remaining=quantity;remaining>0;){SItemInstance seed;seed.tmplId=c.seed;seed.num=static_cast<uint16>(std::min(remaining,static_cast<int>(EItemDieJiaNum)));if(!user->NoLockAddPackage(seed))throw std::runtime_error("背包空间不足");remaining-=seed.num;}gained.push_back(c.seed);moneyChanged=true;user->m_money=beforeMoney-static_cast<uint32>(cost);}
            else {
            int id=Number(input,"plot_id");if(id<1||id>36)throw std::runtime_error("地块不存在");Plot& p=plots[id-1];if(user->GetJingJie()<p.realm)throw std::runtime_error("境界不足，地块未解锁");
            if(!input.HasMember("revision")||!input["revision"].IsString()||std::to_string(p.revision)!=input["revision"].GetString())throw std::runtime_error("地块状态已变化，请重新选择");
            if(operation==1){int crop=Number(input,"crop_id");if(p.crop)throw std::runtime_error("请先铲除或收获已有作物");if(!crops.count(crop))throw std::runtime_error("灵植不可种植");const Crop& c=crops.at(crop);if(user->GetItemNum(c.seed)<1)throw std::runtime_error("种子不足");bagChanged=true;if(!user->DelPackageById(c.seed,1))throw std::runtime_error("种子扣除失败");auto bonus=CUnitySpiritService::Bonus(user);p.duration=spirit::Duration(c.duration,bonus.growth);p.yieldBp=bonus.yield;p.crop=crop;p.growth=garden::Growth();p.growth.last=now;p.growth.waterAt=c.waterDelay?now+c.waterDelay:0;p.growth.bugAt=c.bugDelay?now+c.bugDelay:0;}
            else{if(!p.crop)throw std::runtime_error("当前地块为空");const Crop& c=crops.at(p.crop);bool mature=p.growth.progress>=(p.duration>0?p.duration:c.duration)*p.growth.scale;
                if(operation==2){if(mature||!p.growth.water)throw std::runtime_error("当前无需浇水");p.growth.water=false;p.growth.waterAt=0;}
                if(operation==3){if(mature||!p.growth.bug)throw std::runtime_error("当前无需除虫");p.growth.bug=false;p.growth.bugAt=0;}
                if(operation==4||operation==5){if(operation==5){if(!mature)throw std::runtime_error("作物尚未成熟");for(auto reward:c.outputs){
                    int64 amount=spirit::HarvestCount(reward.second,p.yieldBp);
                    if(reward.first==HDAT_MONEY){if(amount>INT_MAX||amount>UINT_MAX-user->GetMoney())throw std::runtime_error("金币数量超出上限");moneyChanged=true;user->AddMaterial(reward.first,static_cast<int>(amount),false,false);}
                    else{if(amount>INT_MAX)throw std::runtime_error("收获数量超出上限");bagChanged=true;while(amount>0){SItemInstance item;item.tmplId=reward.first;item.num=static_cast<uint16>(std::min<int64>(amount,EItemDieJiaNum));if(!user->NoLockAddPackage(item))throw std::runtime_error("背包空间不足，未收获");amount-=item.num;}gained.push_back(reward.first);}
                }}p.crop=0;p.duration=0;p.yieldBp=0;p.growth=garden::Growth();p.growth.last=now;}}
            ++p.revision;
            }
        }
        for(const auto& p:plots)Save(db,user->GetRoleId(),p);
        if(bagChanged){std::string package;user->GetPackage(package);if(package.empty())throw std::runtime_error("背包存档失败");Execute(db,"UPDATE role_info SET package="+Quote(package)+" WHERE id="+std::to_string(user->GetRoleId()));}
        if(moneyChanged)Execute(db,"UPDATE role_info SET money="+std::to_string(user->GetMoney())+" WHERE id="+std::to_string(user->GetRoleId()));
        std::string response=Envelope(user,plots,crops,now,request,"",operation);
        if(operation!=0)Execute(db,"INSERT INTO unity_garden_request VALUES("+std::to_string(user->GetRoleId())+","+Quote(request)+","+std::to_string(operation)+","+Quote(payload)+","+Quote(response)+")");
        Execute(db,"COMMIT");transaction=false;committed=true;if(bagChanged)Bag(user);if(moneyChanged)user->SendUpdateInfo(EUUT_Money);Send(user,response);
        for(int item:gained)SingletonCMissionManager::instance().UpdateCMissionItemState(user,item);
    }
    catch(const std::exception& error)
    {
        if(transaction)db->Query("ROLLBACK");
        if(!committed&&bagChanged&&!before.empty()){user->SetPackage(&before[0]);Bag(user);}
        if(!committed&&moneyChanged){user->m_money=beforeMoney;user->SendUpdateInfo(EUUT_Money);}
        Send(user,Envelope(user,{},crops,now,request,error.what(),operation));
    }
}
