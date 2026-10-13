#include "../src/spirit_math.h"
#include "../src/garden_growth.h"
#include <iostream>
int main()
{
    auto require=[](bool b){if(!b)throw std::runtime_error("Spirit bonus test failed");};
    require(spirit::Duration(1200000,2000)==960000);
    require(spirit::Duration(1,9999)==1);
    require(spirit::Duration(10001,1)==10000);
    require(spirit::HarvestCount(150,2500)==187); // floor each output once
    require(spirit::HarvestCount(1,1)==1);
    garden::Growth online,offline;online.last=offline.last=1000;
    const auto snapshot=spirit::Duration(1200000,2000);
    for(int i=1;i<=960;i++)garden::Advance(online,1000+i*1000,snapshot,2000);
    garden::Advance(offline,961000,snapshot,2000);
    require(online.progress==offline.progress&&garden::Remaining(offline,snapshot,2000)==0);
    garden::Growth old;old.last=1000;garden::Advance(old,961000,1200000,2000);
    require(garden::Remaining(old,1200000,2000)==240000); // pre-upgrade plant is unchanged
    bool rejected=false;try{spirit::Duration(1000,10000);}catch(...){rejected=true;}require(rejected);
    rejected=false;try{spirit::HarvestCount(INT64_MAX,1);}catch(...){rejected=true;}require(rejected);
    spirit::PositionAttributes totals;
    for(int level=1;level<=10;++level){
        std::vector<int> slots=level%2?std::vector<int>{1,3,5}:std::vector<int>{2,4};
        spirit::AddLevelAttributes(totals,slots,{{1,level},{4,level*10}});
    }
    require(totals[1][1]==25&&totals[3][1]==25&&totals[5][4]==250);
    require(totals[2][1]==30&&totals[4][4]==300&&totals[0].empty());
    // Arbitrary, overlapping selections must follow the rows, not parity.
    spirit::AddLevelAttributes(totals,{4,1},{{1,7},{10,100}});
    require(totals[1][1]==32&&totals[4][1]==37&&totals[3][1]==25&&totals[2].count(10)==0);
    auto snapshotTotals=totals;
    for(const auto& slots:std::vector<std::vector<int>>{{0},{6},{1,1},{}}){rejected=false;try{spirit::AddLevelAttributes(totals,slots,{{1,1}});}catch(...){rejected=true;}require(rejected&&totals==snapshotTotals);}
    spirit::PositionAttributes overflow;spirit::AddLevelAttributes(overflow,{1},{{1,INT32_MAX}});
    rejected=false;try{spirit::AddLevelAttributes(overflow,{2,1},{{1,1}});}catch(...){rejected=true;}require(rejected&&overflow[2].empty()&&overflow[1][1]==INT32_MAX);
    spirit::Wallet onlineWallet,offlineWallet;onlineWallet.period=offlineWallet.period=1000;onlineWallet.last=offlineWallet.last=1000;onlineWallet.rate=offlineWallet.rate=7;
    for(int64_t now=1123;now<11000;now+=123)spirit::Accrue(onlineWallet,now);
    spirit::Accrue(onlineWallet,11000);spirit::Accrue(offlineWallet,11000);
    require(onlineWallet.amount==70&&onlineWallet.amount==offlineWallet.amount&&onlineWallet.remainder==offlineWallet.remainder);
    spirit::Accrue(onlineWallet,10000);require(onlineWallet.amount==70&&onlineWallet.last==11000);
    spirit::Wallet rateChange;rateChange.period=1000;rateChange.last=1000;rateChange.rate=1;spirit::Accrue(rateChange,1500);rateChange.rate=3;spirit::Accrue(rateChange,2000);require(rateChange.amount==2&&rateChange.remainder==0);
    spirit::Wallet large;large.period=1000;large.last=1000;large.rate=1;large.amount=9007199254740993LL;spirit::Accrue(large,2000);require(large.amount==9007199254740994LL);
    large.amount=INT64_MAX;rejected=false;try{spirit::Accrue(large,3000);}catch(...){rejected=true;}require(rejected&&large.amount==INT64_MAX&&large.last==2000);
    spirit::Wallet ticksOnline,ticksOffline;ticksOnline.last=ticksOffline.last=1000;ticksOnline.rate=ticksOffline.rate=7;ticksOnline.capacity=ticksOffline.capacity=100;
    spirit::Accrue(ticksOnline,5999);require(ticksOnline.amount==0&&ticksOnline.remainder==4999);
    spirit::Accrue(ticksOnline,6000);require(ticksOnline.amount==7&&ticksOnline.remainder==0);
    for(int64_t now=6123;now<71000;now+=123)spirit::Accrue(ticksOnline,now);
    spirit::Accrue(ticksOnline,71000);spirit::Accrue(ticksOffline,71000);
    require(ticksOnline.amount==98&&ticksOffline.amount==98&&ticksOnline.remainder==ticksOffline.remainder);
    spirit::Accrue(ticksOnline,100000);require(ticksOnline.amount==100&&ticksOnline.remainder==0);
    ticksOnline.amount-=60;spirit::Accrue(ticksOnline,104999);require(ticksOnline.amount==40);spirit::Accrue(ticksOnline,105000);require(ticksOnline.amount==47); // no hoarded production at full capacity
    spirit::Wallet veryLong;veryLong.last=1;veryLong.rate=INT32_MAX;veryLong.capacity=10244582;spirit::Accrue(veryLong,INT64_MAX);require(veryLong.amount==10244582&&veryLong.remainder==0);
    spirit::Wallet upgrade;upgrade.last=1000;upgrade.rate=1;upgrade.capacity=10;spirit::Accrue(upgrade,4000);upgrade.rate=3;upgrade.capacity=20;spirit::Accrue(upgrade,6000);require(upgrade.amount==3);
    spirit::Wallet zero;zero.last=1000;zero.rate=7;zero.capacity=0;spirit::Accrue(zero,10000);require(zero.amount==0&&zero.remainder==0);
    std::cout<<"Spirit growth snapshots, arbitrary position gains, ten-level accumulation, online/offline accrual, rate changes, exact 64-bit balances and overflow passed\n";
}
