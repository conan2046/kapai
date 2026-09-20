#include "fight.h"
#include "singleton.h"
#include "protocol.h"
#include <algorithm>
#include <iostream>

int CFight::HeroBuildOpeningEffect(uint8 src)
{
    uint8 enemies[GROUP_MEMBER],count=0,highest=0;
    GetAnotherGroup(src,enemies,count);
    for(uint8 i=0;i<count;++i)
        if(IsAlive(enemies[i]) && (highest==0 || GetUnitAttack(enemies[i])>GetUnitAttack(highest)))highest=enemies[i];
    if(highest==0)return 138;
    SFightMember *enemy=GetFightMember(highest);
    if(enemy->unitAttr.lianjiLv+GetStatePara1(highest,ESBUFF_LianJiLvAdd)>=2500)return 135;
    if(enemy->unitAttr.baojiLv+GetStatePara1(highest,ESBUFF_BaoJiLvAdd)>=2500)return 134;
    if(enemy->unitAttr.fumianAdd+GetStatePara1(highest,ESBUFF_FuMianQiangHuaAdd)>=2000)return 137;
    if(enemy->unitAttr.fanjiLv>=2000)return 136;
    return 138;
}

bool CFight::HeroBuildVulnerable(uint8 target)
{
    return HaveBuff(target,ESBUFF_GetDamageAdd)||HaveBuff(target,ESBUFF_GetWuDamageAdd)||HaveBuff(target,ESBUFF_GetFaDamageAdd);
}

int CFight::HeroBuildDamagePercent(uint8 src,uint8 target,uint16 skillId)
{
    int bonus=0;
    if(IsHeroBuild(src,62,1) && skillId==621)bonus+=2000;
    if(IsHeroBuild(src,64,2) && skillId==642 && HaveBuff(target,ESBUFF_FaFangDes))bonus+=2000;
    if(IsHeroBuild(src,68,2) && skillId==682 && GetHp(target)*100<GetMaxHp(target)*40)bonus+=2000;
    if(IsHeroBuild(src,59,1) && skillId==592)bonus+=2000;
    if(IsHeroBuild(src,59,2) && skillId==591 && GetHp(target)*100<GetMaxHp(target)*35)bonus+=2500;
    if(IsHeroBuild(src,60,2) && (skillId==601 || skillId==602))
    {
        int stacks=0;SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
            if(it->id==ESBUFF_ShiDu || it->id==ESBUFF_FuDu || it->id==ESBUFF_ShiXinDu)++stacks;
        bonus+=std::min(5,stacks)*(skillId==601?500:800);
    }
    if(IsHeroBuild(src,51,2) && skillId==511)bonus+=2000;
    if(IsHeroBuild(src,52,2) && skillId==522)bonus+=1800;
    if(IsHeroBuild(src,54,1) && skillId==541)bonus+=2500;
    if(IsHeroBuild(src,54,2) && skillId==542)bonus+=1500;
    if(IsHeroBuild(src,56,1) && skillId==562)bonus-=1000;
    if(IsHeroBuild(src,56,2) && (skillId==561 || skillId==562))bonus+=1000;
    if(IsHeroBuild(src,46,2) && skillId==461 && HaveDeBuffState(target))bonus+=2000;
    if(IsHeroBuild(src,48,1) && skillId==481 && HaveBuff(target,ESBUFF_ChenMo))bonus+=2500;
    if(IsHeroBuild(src,49,1) && skillId==491)bonus-=1500;
    if(IsHeroBuild(src,43,1) && skillId==431 && !HaveBuff(target,ESBUFF_HunShui))bonus+=1500;
    if(IsHeroBuild(src,38,1))
    {
        if(skillId==381)bonus+=2000;
        if(GetFightMember(src)->attackType==2 && HeroBuildState(src,38200)>m_fightTurn)bonus+=1200;
    }
    if(IsHeroBuild(src,31,2) && skillId==312 && GetHp(target)*100>GetMaxHp(target)*70)bonus+=2000;
    if(IsHeroBuild(src,32,2) && skillId==321)bonus-=1000;
    if(IsHeroBuild(src,24,1) && skillId==241 && GetHp(target)*100>GetMaxHp(target)*70)bonus+=2000;
    if(IsHeroBuild(src,25,1))
    {if(skillId==252)bonus+=1500;if(skillId==251 && GetHp(target)*100<GetMaxHp(target)*35)bonus+=2000;}
    if(IsHeroBuild(src,26,1) && skillId==262)bonus+=1000;
    if(IsHeroBuild(src,26,2) && skillId==261)bonus-=1000;
    if(IsHeroBuild(src,27,1) && skillId==271 && GetHp(target)*100>GetMaxHp(target)*70)bonus+=2000;
    if(IsHeroBuild(src,27,2) && skillId==272 && GetHp(target)*100<GetMaxHp(target)*50)bonus+=2500;
    if(IsHeroBuild(src,28,1) && skillId==281 && HaveDeBuffState(target))bonus+=2000;
    if(IsHeroBuild(src,29,1) && skillId==291 && HaveBuff(target,ESBUFF_FaFangDes))bonus+=2000;
    if(IsHeroBuild(src,19,2) && skillId==191)bonus+=2000;
    if(IsHeroBuild(src,21,1) && skillId==211 && GetHp(target)*100<GetMaxHp(target)*40)bonus+=2000;
    if(IsHeroBuild(src,18,2) && skillId==181 && HaveBuff(target,ESBUFF_FaFangDes))bonus+=2000;
    if(IsHeroBuild(src,16,1))
    {
        if(skillId==162)bonus+=1500+(GetHp(target)*100<GetMaxHp(target)*30?1500:0);
        if(skillId==161)bonus+=3000;
    }
    if(IsHeroBuild(src,16,2) && (skillId==161 || skillId==162))bonus+=std::min(3,HeroBuildState(src,163))*800;
    if(IsHeroBuild(src,15,2) && skillId==152 && GetHp(target)*100<GetMaxHp(target)*40)bonus+=2000;
    if(IsHeroBuild(src,14,1))
    {
        if(skillId==141 && GetHp(target)*100>GetMaxHp(target)*70)bonus+=2000;
        if(skillId==142)bonus+=1500;
    }
    if(IsHeroBuild(src,13,2))
    {
        if(skillId==131)bonus+=2000;
        if(skillId==132 && HeroBuildVulnerable(target))bonus+=2500;
        if(HeroBuildVulnerable(target)||HaveBuff(target,ESBUFF_ChenMo)||HaveBuff(target,ESBUFF_HunShui)
            ||HaveBuff(target,ESBUFF_FengYin)||HaveBuff(target,ESBUFF_HunLuan)||HaveBuff(target,ESBUFF_MeiHuo)
            ||HaveBuff(target,ESBUFF_NOT_MOVE)||HaveBuff(target,ESBUFF_FanJian)||HaveBuff(target,ESBUFF_ChaoFeng))bonus+=1000;
    }
    return bonus;
}

void CFight::HeroBuildControlBuff(uint8 src,uint8 target,uint16 skillId,uint16 buffId,int &ratio,uint8 &turn,vector<int> &parameters)
{
    if(IsHeroBuild(src,61,1) && skillId==612 && buffId==ESBUFF_ChaoFeng)turn=2;
    if(IsHeroBuild(src,62,1) && skillId==621 && buffId==ESBUFF_ShanBiLvAdd){parameters.assign(1,4000);turn=1;}
    if(IsHeroBuild(src,62,2) && skillId==624 && buffId==ESBUFF_AddSpeed){ratio=6000;parameters.assign(1,1500);turn=2;}
    if(IsHeroBuild(src,63,1) && skillId==631 && buffId==ESBUFF_ReduceMingZhongLv){parameters.assign(1,3500);turn=3;}
    if(IsHeroBuild(src,63,1) && skillId==634 && buffId==ESBUFF_ReduceMingZhongLv)
    {ratio=HeroBuildState(src,63400)==m_fightTurn+1?-100000:4000;parameters.assign(1,1500);turn=1;}
    if(IsHeroBuild(src,63,2) && skillId==632 && buffId==ESBUFF_HunLuan){ratio=6500;turn=1;}
    if(IsHeroBuild(src,64,1) && skillId==641 && buffId==ESBUFF_FaFangDes){ratio=8000;parameters.assign(1,3500);turn=2;}
    if(IsHeroBuild(src,64,2) && skillId==642 && buffId==ESBUFF_ChenMo){ratio=4500;turn=1;}
    if(IsHeroBuild(src,65,1) && skillId==651 && buffId==ESBUFF_ShiDu)
    {for(size_t i=0;i<parameters.size();++i)parameters[i]=parameters[i]*120/100;turn=3;}
    if(IsHeroBuild(src,65,2) && skillId==652 && buffId==ESBUFF_FaFangDes){parameters.assign(1,4000);turn=2;}
    if(IsHeroBuild(src,66,1) && skillId==661 && buffId==ESBUFF_Blooding && !parameters.empty()){parameters[0]=parameters[0]*120/100;turn=3;}
    if(IsHeroBuild(src,66,1) && skillId==663 && buffId==ESBUFF_AddSpeed){parameters.assign(1,1500);turn=1;}
    if(IsHeroBuild(src,66,2) && skillId==662)
    {if(buffId==ESBUFF_SpeedDes)parameters.assign(1,2000);if(buffId==ESBUFF_AddSpeed)parameters.assign(1,1500);turn=2;}
    if(IsHeroBuild(src,66,2) && skillId==664 && buffId==ESBUFF_SpeedDes){parameters.assign(1,2000);turn=2;}
    if(IsHeroBuild(src,67,2) && skillId==672 && buffId==ESBUFF_ReduceMingZhongLv){ratio=7000;parameters.assign(1,3500);turn=1;}
    if(IsHeroBuild(src,68,2) && skillId==682 && buffId==ESBUFF_ForbidFuHuo){ratio=7000;turn=2;}
    if(IsHeroBuild(src,57,1) && skillId==571 && buffId==ESBUFF_WuMianLvAdd && !parameters.empty()){parameters[0]+=800;turn=2;}
    if(IsHeroBuild(src,57,1) && skillId==572 && buffId==ESBUFF_GetDamageAdd && !parameters.empty())parameters[0]+=500;
    if(IsHeroBuild(src,58,1) && skillId==581 && buffId==ESBUFF_FuMianKangDes && !parameters.empty()){parameters[0]=2500;turn=2;}
    if(IsHeroBuild(src,58,2) && skillId==582 && buffId==ESBUFF_FanJian){ratio=6000;turn=1;}
    if(IsHeroBuild(src,59,1) && skillId==593 && buffId==ESBUFF_DamagePercentAdd && !parameters.empty())parameters[0]+=800;
    if(IsHeroBuild(src,60,1) && skillId==601 && buffId==ESBUFF_ShiDu)ratio+=1500;
    if(GetHeroId(src)==60 && GetFightMember(src)->heroBuildBranch!=0 && skillId==602 && buffId==ESBUFF_GetDamageAdd && !parameters.empty())
    {ratio=20000;parameters[0]=IsHeroBuild(src,60,1)?2000:3000;turn=2;}
    if(IsHeroBuild(src,51,1) && skillId==512 && buffId==ESBUFF_FuMianKangDes && !parameters.empty())
    {parameters[0]=3000;turn=2;}
    if(IsHeroBuild(src,53,1) && skillId==531 && buffId==ESBUFF_FuDu){ratio=7500;turn=3;}
    if(IsHeroBuild(src,55,2) && skillId==552 && buffId==ESBUFF_MeiHuo && HaveBuff(target,ESBUFF_ChenMo))ratio+=2000;
    if(IsHeroBuild(src,45,2) && skillId==452 && buffId==ESBUFF_SpeedDes && !parameters.empty())
    {parameters[0]+=800;turn=2;}
    if(IsHeroBuild(src,46,1) && skillId==462 && !parameters.empty())
    {parameters[0]=1500;turn=2;}
    if(IsHeroBuild(src,46,2) && skillId==464 && buffId==ESBUFF_DamagePercentAdd && !parameters.empty())
    {
        parameters[0]+=800;uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(src,allies,count);
        for(uint8 i=0;i<count;++i)if(GetHeroId(allies[i])==45){parameters[0]+=400;break;}
    }
    if(IsHeroBuild(src,47,1) && skillId==471 && buffId==ESBUFF_JianShangLvAdd && !parameters.empty())
    {parameters[0]=2500;turn=2;}
    if(IsHeroBuild(src,48,1) && skillId==483 && buffId==ESBUFF_FuMianQiangHuaAdd && !parameters.empty())
    {
        if(GetStateSrcPos(src,buffId)!=src)HeroBuildState(src,48301)=0;
        HeroBuildState(src,48301)=std::min(5,HeroBuildState(src,48301)+1);parameters[0]+=HeroBuildState(src,48301)*300;turn=2;
    }
    if(IsHeroBuild(src,48,2) && skillId==482 && buffId==ESBUFF_MeiHuo)ratio+=1500;
    if(IsHeroBuild(src,49,1) && skillId==491 && buffId==ESBUFF_ZhuoShao && !parameters.empty())parameters[0]=parameters[0]*115/100;
    if(IsHeroBuild(src,41,1) && skillId==411 && buffId==ESBUFF_BaoJiKangDes && !parameters.empty())
    {parameters[0]+=1000;turn=2;}
    if(IsHeroBuild(src,41,2) && skillId==412 && buffId==ESBUFF_Blooding && !parameters.empty())
    {parameters[0]=parameters[0]*125/100;++turn;}
    if(IsHeroBuild(src,43,1) && skillId==431 && buffId==ESBUFF_HunShui)ratio+=2000;
    if(IsHeroBuild(src,43,2) && skillId==432 && buffId==ESBUFF_LianJiLvAdd && !parameters.empty())parameters[0]+=800;
    if(IsHeroBuild(src,44,2) && skillId==442 && buffId==ESBUFF_LianJiLvShangHaiAdd && !parameters.empty())parameters[0]+=1500;
    if(IsHeroBuild(src,37,1) && skillId==371 && buffId==ESBUFF_FaMianLvAdd && !parameters.empty())
    {parameters[0]+=1000;turn=2;}
    if(IsHeroBuild(src,38,2) && skillId==382 && buffId==ESBUFF_BaoJiShangHaiAdd && !parameters.empty())
    {parameters[0]+=1500;turn=2;}
    if(IsHeroBuild(src,40,2) && skillId==402 && buffId==ESBUFF_DamagePercentDes && !parameters.empty())
    {parameters[0]=2000;turn=2;}
    if(IsHeroBuild(src,34,2) && skillId==341 && buffId==ESBUFF_ChaoFeng)turn=1;
    if(IsHeroBuild(src,32,1) && skillId==321 && buffId==ESBUFF_ZhuoShao)++turn;
    if(IsHeroBuild(src,32,1) && skillId==324 && buffId==ESBUFF_ZengShangLvAdd && !parameters.empty())
    {parameters[0]+=500;turn=2;}
    if(IsHeroBuild(src,33,1) && skillId==331 && buffId==ESBUFF_MeiHuo)ratio+=1500;
    if(IsHeroBuild(src,33,1) && skillId==332 && buffId==ESBUFF_FuMianKangDes && !parameters.empty())
    {parameters[0]+=800;turn=2;}
    if(IsHeroBuild(src,33,2) && skillId==333 && buffId==ESBUFF_MeiHuo)
        ratio=HeroBuildState(src,33300)==m_fightTurn+1?-100000:ratio+1500;
    if(IsHeroBuild(src,27,2) && skillId==274 && buffId==ESBUFF_SpeedDes && !parameters.empty())
    {HeroBuildState(src,277)=std::min(2000,HeroBuildState(src,277)+parameters[0]);parameters[0]=HeroBuildState(src,277);}
    if(IsHeroBuild(src,23,1) && skillId==231 && buffId==ESBUFF_JianShangLvAdd && !parameters.empty())parameters[0]+=1000;
    if(IsHeroBuild(src,24,1) && skillId==242 && src==target && buffId==ESBUFF_BaoJiLvAdd && !parameters.empty())parameters[0]+=1200;
    if(IsHeroBuild(src,26,1) && skillId==261 && buffId==ESBUFF_GetWuDamageAdd && !parameters.empty())
    {parameters[0]+=500;++turn;}
    if(IsHeroBuild(src,28,2) && skillId==282 && buffId==ESBUFF_GetFaDamageAdd && !parameters.empty())
    {parameters[0]+=800;turn=2;}
    if(IsHeroBuild(src,29,2) && skillId==292 && buffId==ESBUFF_GetWuDamageAdd && !parameters.empty())parameters[0]+=800;
    if(IsHeroBuild(src,30,1) && skillId==301 && buffId==ESBUFF_SpeedDes && !parameters.empty())
    {parameters[0]+=1000;turn=2;}
    if(IsHeroBuild(src,30,2) && skillId==302 && buffId==ESBUFF_DamagePercentDes && !parameters.empty())
    {parameters[0]+=1000;turn=2;}
    if(IsHeroBuild(src,20,1) && skillId==201 && buffId==ESBUFF_FanJian)ratio+=1500;
    if(IsHeroBuild(src,20,2) && skillId==202 && buffId==ESBUFF_FangYuDes && !parameters.empty())
    {parameters[0]+=1000;turn=2;}
    if(IsHeroBuild(src,22,1) && skillId==221 && buffId==ESBUFF_FengYin)ratio+=2000;
    if(IsHeroBuild(src,22,1) && skillId==223 && buffId==ESBUFF_FengYin)ratio+=1000;
    if(IsHeroBuild(src,18,2) && skillId==182 && buffId==ESBUFF_FaFangDes && !parameters.empty())parameters[0]+=1000;
    if(IsHeroBuild(src,15,1) && skillId==151 && buffId==ESBUFF_GetWuDamageAdd && !parameters.empty())
    {parameters[0]=1500;turn=3;}
    if(IsHeroBuild(src,13,1) && skillId==131 && buffId==ESBUFF_ChenMo)
    {
        ratio+=1500;
        if(HaveDeBuffState(target) && Random(1,10000)<=4000)++turn;
    }
    if(IsHeroBuild(src,13,2) && skillId==132 && buffId==ESBUFF_GetDamageAdd && !parameters.empty())parameters[0]+=500;
}

void CFight::HeroBuildControlFailed(uint8 src,uint8 target,uint16 skillId,uint16 buffId)
{
    if(IsHeroBuild(src,30,1) && skillId==301 && buffId==ESBUFF_FengYin
        && !GetFightMember(target)->InNotEffectBuff(buffId) && HeroBuildState(src,30100)!=m_fightTurn+1)
    {HeroBuildState(src,30100)=m_fightTurn+1;AddTeamRage(src,5);}
    if(!IsHeroBuild(src,13,2) || skillId!=131 || buffId!=ESBUFF_ChenMo)return;
    if(GetFightMember(target)->InNotEffectBuff(ESBUFF_GetDamageAdd))return;
    if(GetStatePara1(target,ESBUFF_GetDamageAdd)>=1000)return;
    vector<int> vulnerable(1,1000);
    AddBuff(target,src,ESBUFF_GetDamageAdd,2,&vulnerable,131);
    m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
    m_extActionMsg<<(uint8)EFOT_Passive<<src<<(uint16)131<<string("")<<(uint8)1;
    m_extActionMsg<<target<<(int)0<<(int)0<<(int)0;
    MakeBuffList(target,m_extActionMsg);
}

bool CFight::RunHeroBuildControlRegression()
{
    CFight battle;
    uint8 enemy=GROUP2_BEGIN+1;
    for(uint8 i=0;i<4;++i)
    {
        uint8 pos=i==0?1:enemy+i-1;
        SharePetPtr pet(new SPet);pet->id=i==0?13:23;
        SFightMember &unit=battle.m_members[pos-1];
        unit.memPtr=pet;unit.type=EFMT_PET;unit.hp=unit.unitAttr.maxHp=10000;
        unit.unitAttr.attack=i==1?1000:500;unit.unitAttr.speed=100;unit.level=1;
    }
    SFightMember &caster=battle.m_members[0],&strongest=battle.m_members[enemy-1];
    caster.heroBuildBranch=1;
    strongest.unitAttr.lianjiLv=2500;strongest.unitAttr.baojiLv=3000;
    if(battle.HeroBuildOpeningEffect(1)!=135)return false;
    strongest.unitAttr.lianjiLv=0;
    if(battle.HeroBuildOpeningEffect(1)!=134)return false;
    strongest.unitAttr.baojiLv=0;strongest.unitAttr.fumianAdd=2000;
    if(battle.HeroBuildOpeningEffect(1)!=137)return false;
    strongest.unitAttr.fumianAdd=0;strongest.unitAttr.fanjiLv=2000;
    if(battle.HeroBuildOpeningEffect(1)!=136)return false;
    strongest.unitAttr.fanjiLv=0;
    if(battle.HeroBuildOpeningEffect(1)!=138)return false;
    vector<int> parameters;
    battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(134),1);
    if(parameters.size()<2 || parameters[1]!=-1320)return false;
    if(battle.GetUnitSpeed(1)!=115)return false;
    battle.m_fightTurn=2;
    if(battle.GetUnitSpeed(1)!=100)return false;
    int ratio=3000;uint8 duration=2;
    parameters.clear();battle.HeroBuildControlBuff(1,enemy,131,ESBUFF_ChenMo,ratio,duration,parameters);
    if(ratio!=4500 || duration!=2)return false;
    battle.HeroBuildDebuffApplied(1,enemy,132,ESBUFF_GetDamageAdd);
    if(battle.GetStatePara1(enemy,ESBUFF_SpeedDes)!=800)return false;
    caster.heroBuildBranch=2;
    battle.InitTeamRageFromAffixes();
    if(battle.GetTeamRage(1)!=10 || battle.HeroBuildDamagePercent(1,enemy,131)!=2000)return false;
    battle.HeroBuildControlFailed(1,enemy,131,ESBUFF_ChenMo);
    if(battle.GetStatePara1(enemy,ESBUFF_GetDamageAdd)!=1000 || battle.HeroBuildDamagePercent(1,enemy,132)!=3500)return false;
    parameters.assign(1,2000);ratio=10000;duration=2;
    battle.HeroBuildControlBuff(1,enemy,132,ESBUFF_GetDamageAdd,ratio,duration,parameters);
    if(parameters[0]!=2500)return false;
    battle.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&parameters,132);
    if(battle.GetStatePara1(enemy,ESBUFF_GetDamageAdd)!=2500)return false;
    vector<int> weaker(1,1000);battle.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&weaker,131);
    if(battle.GetStatePara1(enemy,ESBUFF_GetDamageAdd)!=2500)return false;
    uint8 targets[GROUP_MEMBER],count=0;
    battle.GetSkillTargetRange(1,132,1,targets,count);
    if(count!=1 || targets[0]==enemy)return false;
    if(!battle.IsRoleSkillUseful(1,131))return false;
    vector<int> silence;
    battle.AddBuff(enemy,1,ESBUFF_ChenMo,2,&silence);
    if(battle.IsRoleSkillUseful(1,131))return false;
    boost::any_cast<SharePetPtr>(caster.memPtr)->id=23;
    if(battle.HeroBuildDamagePercent(1,enemy,132)!=0)return false;
    std::cout<<"PASS Kongxuan A/B: weighted opening/strength/speed expiry/silence odds/slow/fallback vulnerability/damage/target priority/AI/hero isolation"<<std::endl;
    return true;
}
