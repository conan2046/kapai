#include "../src/reward_rules.h"
#include "../src/chapter_reward_rules.h"
#include <set>
#include <iostream>
#include <fstream>
#include <iterator>
#include <stdexcept>
struct Award {int type=0,typeId=0,num=0;};
using Group=UnityRewards::Group<Award>;
using Row=UnityRewards::Row<Award>;
#define CHECK(x) do { if(!(x)) throw std::runtime_error(#x); } while(false)
Row row(const char* json,int& mode) {
    rapidjson::Document d; d.Parse(json); CHECK(!d.HasParseError());
    Row r;std::string e;CHECK(UnityRewards::ReadRow(d,r,mode,e));return r;
}
bool valid(const char* json) {
    rapidjson::Document d;d.Parse(json);Row r;int m;std::string e;
    return !d.HasParseError() && UnityRewards::ReadRow(d,r,m,e);
}
int main(int argc,char** argv) {
 try {
    const std::map<int,int> chapter{{3,100},{6,200}};
    const std::set<int> oldPending{100,999};
    CHECK(ChapterRewardRules::Contains(chapter,100));
    CHECK(!ChapterRewardRules::Contains(chapter,999));
    CHECK(!ChapterRewardRules::Contains(chapter,0));
    CHECK(ChapterRewardRules::PendingCount(chapter,oldPending,3)==1);
    CHECK(ChapterRewardRules::PendingCount(chapter,std::set<int>{999},6)==0);
    CHECK(!ChapterRewardRules::Eligible(chapter,100,2));
    CHECK(ChapterRewardRules::Eligible(chapter,100,3));
    CHECK(ChapterRewardRules::PendingCount(chapter,oldPending,2)==0);
    Group g;int mode;std::vector<Award> out;
    CHECK(UnityRewards::AppendRow(g,row(R"({"rewardid":1,"drop_type":1,"reward":[[60000,0,10,100],[60006,0,20]],"weight":0})",mode),1));
    auto low=[](int a,int){return a;};auto high=[](int,int b){return b;};
    CHECK(UnityRewards::Roll(g,1,true,true,out,low));CHECK(out.size()==2&&out[0].num==10&&out[1].num==20);
    CHECK(UnityRewards::Roll(g,1,true,true,out,high));CHECK(out[0].num==100);
    CHECK(UnityRewards::Roll(g,3,true,true,out,low));CHECK(out.size()==6); // fixed-only group needs no random row
    Group random;
    auto a=row(R"({"rewardid":1,"drop_type":2,"reward":[[611,0,7],[851,0,8]],"weight":10})",mode);
    auto b=row(R"({"rewardid":1,"drop_type":2,"reward":[[836,0,1]],"weight":30})",mode);
    CHECK(UnityRewards::AppendRow(random,a,2));CHECK(UnityRewards::AppendRow(random,b,2));
    for(int ticket=1;ticket<=40;ticket++) {
        auto draw=[ticket](int lo,int hi){return lo==hi?lo:ticket;};
        CHECK(UnityRewards::Roll(random,1,true,true,out,draw));
        CHECK(out[0].type==(ticket<=10?611:836));CHECK(out.size()==(ticket<=10?2:1));
    }
    g.awards=random.awards;g.weightSum=random.weightSum;
    CHECK(UnityRewards::Roll(g,1,true,true,out,low));CHECK(out.size()==4&&out[0].type==60000&&out[2].type==611);
    CHECK(UnityRewards::Roll(random,2,true,true,out,low));CHECK(out.size()==3&&out.back().type==836);
    CHECK(!UnityRewards::Roll(random,3,true,true,out,low));
    CHECK(UnityRewards::Roll(random,5,false,true,out,low));CHECK(out.size()==10);
    CHECK(!valid(R"({"rewardid":1,"drop_type":2,"reward":[],"weight":1})"));
    CHECK(!valid(R"({"rewardid":1,"drop_type":2,"reward":[[60000,0,100,10]],"weight":1})"));
    CHECK(!valid(R"({"rewardid":1,"drop_type":1,"reward":[[60000,0,1]],"weight":1})"));
    CHECK(!valid(R"({"rewardid":1,"drop_type":2,"reward":[[60000,0,1]],"weight":0})"));
    CHECK(!valid(R"({"rewardid":1,"drop_type":3,"reward":[[60000,0,1]],"weight":1})"));
    CHECK(!valid(R"({"rewardid":1,"drop_type":2,"reward":[[60000,0,1.5]],"weight":1})"));
    CHECK(valid(R"({"rewardid":1,"reward":[[60000,0,1]],"weight":1})")); // staged compatibility
    std::vector<Award> merged{{60000,0,INT_MAX}};
    CHECK(!UnityRewards::MergeChecked(merged,std::vector<Award>{{60000,0,1}}));CHECK(merged[0].num==INT_MAX);
    std::srand(42);bool minSeen=false,maxSeen=false,wideSeen=false;
    for(int i=0;i<20000;i++){int n=UnityRewards::RandomInclusive(10,100);CHECK(n>=10&&n<=100);minSeen|=n==10;maxSeen|=n==100;wideSeen|=UnityRewards::RandomInclusive(0,1000000)>32767;}
    CHECK(minSeen&&maxSeen&&wideSeen);CHECK(UnityRewards::RandomInclusive(INT_MAX,INT_MAX)==INT_MAX);
    if(argc==3) {
        std::ifstream f(argv[1]);std::string text((std::istreambuf_iterator<char>(f)),{});rapidjson::Document d;d.Parse(text.c_str());CHECK(d.IsArray());
        std::map<int,Group> groups;
        for(auto it=d.Begin();it!=d.End();++it){Row r;int m;std::string error;CHECK(UnityRewards::ReadRow(*it,r,m,error));CHECK(UnityRewards::AppendRow(groups[(*it)["rewardid"].GetInt()],r,m));}
        std::ifstream mf(argv[2]);text.assign(std::istreambuf_iterator<char>(mf),{});rapidjson::Document maps;maps.Parse(text.c_str());CHECK(maps.IsArray());
        int used=0;
        for(auto it=maps.Begin();it!=maps.End();++it){int id=(*it)["rewardID"].GetInt();if(!id)continue;CHECK(groups.count(id));CHECK(UnityRewards::Roll(groups[id],1,true,true,out,low));CHECK(UnityRewards::Roll(groups[id],1,true,true,out,high));used++;}
        std::cout<<"Actual config parsed rows="<<d.Size()<<" maps="<<maps.Size()<<" rewardGroupsUsed="<<used<<"\n";
    }
    std::cout<<"reward rules: fixed-only, random-only, mixed, weighted boundaries, bundles, ranges, unique draws, invalid data, overflow passed\n";
    return 0;
 } catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}
}
