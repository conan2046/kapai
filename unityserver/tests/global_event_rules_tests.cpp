#include "../src/global_event.h"
#include <iostream>
#include <stdexcept>
static void Check(bool v,const char* message){if(!v)throw std::runtime_error(message);}
int main(){
 try{
  GlobalEventDefinition e;e.type=7;e.num=3;
  std::uint32_t p=0;
  Check(GlobalEventRules::Advance(e,p,1,0)&&p==1,"single successful strengthen");
  Check(!GlobalEventRules::Advance(e,p,1,8)&&p==1,"wrong target filter");
  Check(GlobalEventRules::Advance(e,p,2,0)&&p==3,"batch actual successes complete three");
  Check(!GlobalEventRules::Advance(e,p,-1,0)&&p==3,"negative delta rejected");
  e.type=40;e.num=1;e.param1=10006;p=0;
  Check(!GlobalEventRules::Advance(e,p,1,10005)&&p==0,"wrong boss cannot complete");
  Check(GlobalEventRules::Advance(e,p,1,10006)&&p==1,"specified boss completes");
  e.type=34;e.num=2;e.param1=4;p=0;
  Check(!GlobalEventRules::Advance(e,p,1,3)&&p==0,"quality filter lower bound");
  Check(GlobalEventRules::Advance(e,p,2,5)&&p==2,"quality threshold includes higher quality");
  e.type=30;e.num=2;e.param1=0;p=0;
  Check(GlobalEventRules::Advance(e,p,2,0)&&p==2,"realm is a current value");
  Check(!GlobalEventRules::Advance(e,p,1,0)&&p==2,"older snapshot does not roll progress back");
  e.type=1009;p=0;
  Check(!GlobalEventRules::Advance(e,p,1,0)&&p==0,"unimplemented task event fails closed");
  e.type=7;e.num=3;p=UINT32_MAX-1;
  Check(GlobalEventRules::Advance(e,p,5,0)&&p==UINT32_MAX,"counter overflow cannot wrap");
  std::cout<<"global event rules: 12 assertions passed"<<std::endl;return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<std::endl;return 1;}
}
