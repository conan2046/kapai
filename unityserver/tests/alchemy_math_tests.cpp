#include "../src/spirit_math.h"
#include <cassert>
#include <iostream>
int main()
{
    spirit::Wallet online;online.last=1;online.rate=3;online.bonus=5000;
    spirit::Accrue(online,5001);assert(online.amount==4&&online.gainFraction==5000);
    spirit::Accrue(online,10001);assert(online.amount==9&&online.gainFraction==0);
    spirit::Wallet offline;offline.last=1;offline.rate=3;offline.bonus=5000;
    spirit::Accrue(offline,10001);assert(offline.amount==online.amount&&offline.gainFraction==online.gainFraction);
    spirit::Wallet small;small.last=1;small.rate=1;small.bonus=1;
    spirit::Accrue(small,5001);assert(small.amount==1&&small.gainFraction==1);
    spirit::Accrue(small,50000001);assert(small.amount==10001&&small.gainFraction==0);
    spirit::Wallet capped; capped.last=1;capped.rate=3;capped.bonus=5000;capped.capacity=8;
    spirit::Accrue(capped,10001);assert(capped.amount==8&&capped.remainder==0&&capped.gainFraction==0);
    spirit::Wallet boundary;boundary.last=1;boundary.rate=1;boundary.bonus=9999;
    spirit::Accrue(boundary,INT64_MAX);assert(boundary.amount>0&&boundary.amount<INT64_MAX);
    assert(spirit::Duration(20000,0)==20000&&spirit::Duration(20000,5000)==10000);
    bool rejected=false;try{spirit::Duration(20000,10000);}catch(const std::exception&){rejected=true;}assert(rejected);
    std::cout<<"alchemy: fractional bonuses, online/offline equivalence, capacity, 64-bit elapsed boundary and craft duration passed\n";
}
