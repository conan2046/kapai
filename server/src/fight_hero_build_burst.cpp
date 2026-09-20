#include "fight.h"
#include "protocol.h"
#include "singleton.h"
#include <algorithm>
#include <iostream>

int &CFight::HeroBuildState(uint8 pos,int key)
{
    return m_members[pos-1].heroBuildState[key];
}

void CFight::HeroBuildBeforeAction(uint8 pos)
{
    HeroBuildState(pos,200040)=m_fightTurn;
    HeroBuildEquipmentAction(pos);
    HeroBuildState(pos,200030)=0;
    HeroBuildState(pos,58200)=HeroBuildState(pos,67400)=0;
    if(GetHeroId(pos)==60 && GetFightMember(pos)->heroBuildBranch!=0)
    {
        uint8 enemies[GROUP_MEMBER],count=0;GetAnotherGroup(pos,enemies,count);GetSkillTargetSelCondition(enemies,count,ESkill_Select_MaxDamage);
        if(count>0)
        {
            uint8 target=enemies[0];int defenseLevel=0,attackLevel=0;
            const vector<SSkillData> &skills=GetFightMember(pos)->passive_skill;
            for(size_t i=0;i<skills.size();++i){if(skills[i].id==603)defenseLevel=skills[i].level;if(skills[i].id==604)attackLevel=skills[i].level;}
            if(defenseLevel>0)
            {
                vector<int> defense(1,1100+(defenseLevel-1)*100);AddBuff(target,pos,ESBUFF_WuFangDes,2,&defense,603);
                if(IsHeroBuild(pos,60,1)){vector<int> resistance(1,800);AddBuff(target,pos,ESBUFF_FuMianKangDes,2,&resistance,603);}
            }
            if(attackLevel>0)
            {
                int value=1100+(attackLevel-1)*100;
                if(IsHeroBuild(pos,60,2))
                {
                    value=value*150/100;int stacks=0;SFightMember *victim=GetFightMember(target);
                    for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
                        if(it->id==ESBUFF_ShiDu || it->id==ESBUFF_FuDu || it->id==ESBUFF_ShiXinDu)++stacks;
                    if(defenseLevel>0 && stacks>=3)value+=1000;
                }
                vector<int> weakness(1,value);AddBuff(target,pos,ESBUFF_DamagePercentDes,2,&weakness,604);
            }
        }
    }
    HeroBuildState(pos,51400)=HeroBuildState(pos,54200)=0;
    for(int target=1;target<=MAX_MEMBER;++target)HeroBuildState(pos,53200+target)=0;
    HeroBuildState(pos,172)=0;
    HeroBuildState(pos,193)=0;
    HeroBuildState(pos,192)=0;
    HeroBuildState(pos,241)=0;
    HeroBuildState(pos,252)=0;
    HeroBuildState(pos,34101)=HeroBuildState(pos,34102)=HeroBuildState(pos,35300)=0;
    HeroBuildState(pos,37300)=HeroBuildState(pos,38301)=0;
    HeroBuildState(pos,41100)=HeroBuildState(pos,44401)=0;
    HeroBuildState(pos,49200)=HeroBuildState(pos,50201)=HeroBuildState(pos,50202)=0;
    for(int target=1;target<=MAX_MEMBER;++target)HeroBuildState(pos,46200+target)=0;
    if(IsHeroBuild(pos,29,2))++HeroBuildState(pos,29401);
    if(GetHeroId(pos)==16)HeroBuildState(pos,163)=0;
    if(GetHeroId(pos)!=14 || GetFightMember(pos)->heroBuildBranch==0)return;
    HeroBuildState(pos,14101)=0;
    ++HeroBuildState(pos,14401);
    if(IsHeroBuild(pos,14,2))HeroBuildState(pos,144)=std::min(4,HeroBuildState(pos,144)+1);
}

void CFight::HeroBuildDirectDamage(uint8 src,uint8 target,uint16 skillId,int &damage,int &absorbed,bool ignoreShield,int *revived)
{
    bool nezhaCircle=IsHeroBuild(src,16,2)
        && ((skillId==161 && HeroBuildState(src,16101)==2) || (skillId==162 && HaveDeBuffState(target) && HaveShieldState(target)));
    if((!IsHeroBuild(src,14,2) && !nezhaCircle && HeroBuildArtifactValue(src,7)==0 && !ignoreShield) || damage<=0 || !HaveShieldState(target))
    {
        DecreaseHp(target,src,damage,absorbed,ignoreShield,revived);
        return;
    }
    // Only the shield-facing portion gains shield damage. A successful
    // penetration roll never turns into the legacy 100% shield bypass.
    int pierce=nezhaCircle?0:(ignoreShield?4000:(IsHeroBuild(src,14,2) && skillId==142?2500:0));
    int lifePart=(int)((int64)damage*pierce/10000);
    int shieldPart=damage-lifePart;
    int multiplier=(nezhaCircle?12000:10000+(IsHeroBuild(src,14,2)?HeroBuildState(src,144)*800+(skillId==142?4000:0):0))+HeroBuildArtifactValue(src,7);
    int shieldPressure=(int)((int64)shieldPart*multiplier/10000);
    int shieldAbsorbed=0;
    ShieldAbsorptionDamage(target,shieldPressure,shieldAbsorbed);
    int spent=(int)std::min<int64>(shieldPart,((int64)shieldAbsorbed*10000+multiplier-1)/multiplier);
    damage=lifePart+shieldPart-spent;
    int ignored=0;
    DecreaseHp(target,src,damage,ignored,true,revived);
    absorbed=shieldAbsorbed;
    GetFightMember(target)->sum_beDamage+=absorbed;
    GetFightMember(src)->sum_damage+=absorbed;
}

void CFight::HeroBuildAfterDirectHit(uint8 src,uint8 target,uint16 skillId,bool hadShield,int actualDamage)
{
    if(IsHeroBuild(src,67,2) && skillId==672)
    {uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(src,allies,count);vector<int> speed(1,800);for(uint8 i=0;i<count;++i)AddBuff(allies[i],src,ESBUFF_AddSpeed,1,&speed,672);}
    if(IsHeroBuild(src,58,2) && skillId==582 && HaveBuff(target,ESBUFF_FuMianKangDes) && HeroBuildState(src,58200)==0)
    {HeroBuildState(src,58200)=1;AddTeamRage(src,6);}
    if(IsHeroBuild(src,51,2) && HeroBuildState(src,51400)==0 && actualDamage>0)
    {
        uint8 enemies[GROUP_MEMBER],count=0;GetAnotherGroup(src,enemies,count);
        for(uint8 i=0;i<count;++i)if(enemies[i]!=target)
        {HeroBuildState(src,51400)=1;HeroBuildDamageAction(src,enemies[i],actualDamage*30/100,514);break;}
    }
    if(IsHeroBuild(src,52,1) && skillId==521 && IsAlive(target) && !GetFightMember(target)->InNotEffectBuff(ESBUFF_SpeedDes))
    {vector<int> slow(1,1500);AddBuff(target,src,ESBUFF_SpeedDes,2,&slow,521);}
    if(IsHeroBuild(src,54,2) && skillId==542 && HeroBuildState(src,54200)==0)
    {
        uint8 enemies[GROUP_MEMBER],count=0;GetAnotherGroup(src,enemies,count);
        if(count==1 && enemies[0]==target){HeroBuildState(src,54200)=1;HeroBuildDamageAction(src,target,actualDamage*60/100,542);}
    }
    if(IsHeroBuild(src,53,2) && skillId==532 && HeroBuildState(src,53200+target)==0 && HaveZhongDuState(target))
    {
        HeroBuildState(src,53200+target)=1;int64 tick=0;SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
        {
            if(it->srcPos!=src || it->paraList.empty())continue;
            if(it->id==ESBUFF_ShiDu)tick+=it->paraList[0]+(it->paraList.size()>1?it->paraList[1]:0);
            if((it->id==ESBUFF_FuDu || it->id==ESBUFF_ShiXinDu) && it->paraList.size()>1)
                tick+=std::min<int64>((it->id==ESBUFF_FuDu?GetHp(target):GetMaxHp(target))*it->paraList[0]/10000,it->paraList[1]);
        }
        HeroBuildDamageAction(src,target,(int)(tick/2),532);
    }
    if(IsHeroBuild(src,47,1) && skillId==472)
    {vector<int> shield(2,(int)(GetMaxHp(src)*6/100));AddBuff(src,src,ESBUFF_Shield,2,&shield,472);}
    if(IsHeroBuild(src,41,2) && skillId==411 && HaveBuff(target,ESBUFF_Blooding) && HeroBuildState(src,41100)==0)
    {HeroBuildState(src,41100)=1;AddTeamRage(src,3);}
    if(IsHeroBuild(src,34,2) && skillId==341)
    {HeroBuildState(src,34102)=std::min(4,HeroBuildState(src,34102)+1);vector<int> guard(1,HeroBuildState(src,34102)*500);AddBuff(src,src,ESBUFF_JianShangLvAdd,2,&guard,341);}
    if(IsHeroBuild(src,36,1) && skillId==361 && IsAlive(target) && !GetFightMember(target)->InNotEffectBuff(ESBUFF_DamagePercentDes))
    {vector<int> weakness(1,1000);AddBuff(target,src,ESBUFF_DamagePercentDes,2,&weakness,361);}
    if(IsHeroBuild(src,24,2) && skillId==241 && HeroBuildState(src,241)==0)
    {
        HeroBuildState(src,241)=1;uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(src,allies,count);
        GetSkillTargetSelCondition(allies,count,ESkill_Select_MinCurHp);
        if(count>0)HeroBuildHpAction(src,allies[0],GetUnitAttack(src)*35/100,241);
    }
    if(IsHeroBuild(src,25,2) && skillId==251)
    {vector<int> guard(1,1000);AddBuff(src,src,ESBUFF_JianShangLvAdd,2,&guard,251);}
    if(IsHeroBuild(src,25,2) && skillId==252 && HeroBuildState(src,252)==0)
    {HeroBuildState(src,252)=1;vector<int> shield(2,(int)(GetMaxHp(src)*12/100));AddBuff(src,src,ESBUFF_Shield,2,&shield,252);}
    if(IsHeroBuild(src,19,1) && skillId==192 && IsAlive(target) && HeroBuildState(src,192)==0 && HeroBuildTryExtraAttack(src))
    {
        HeroBuildState(src,192)=1;SFightMember *member=GetFightMember(src);int oldType=member->attackType;member->attackType=2;
        vector<SAttrData> modifiers,defense;modifiers.push_back(SAttrData(ESkill_PassAttr_DamagePer,-4000));
        int damage=CalculateDamage(src,target,modifiers,defense);member->attackType=oldType;
        HeroBuildDamageAction(src,target,damage,192);
    }
    if(IsHeroBuild(src,20,2) && skillId==201 && IsAlive(target)
        && (HaveBuff(target,ESBUFF_FangYuDes)||HaveBuff(target,ESBUFF_FaFangDes)||HaveBuff(target,ESBUFF_WuFangDes)))
        HeroBuildDamageAction(src,target,GetUnitAttack(src)*60/100,201);
    if(IsHeroBuild(src,21,1) && skillId==211 && !IsAlive(target) && HeroBuildState(src,21100)!=m_fightTurn+1)
    {HeroBuildState(src,21100)=m_fightTurn+1;AddTeamRage(src,8);}
    if(IsHeroBuild(src,17,1) && skillId==172 && HeroBuildState(src,172)<4)
    {
        ++HeroBuildState(src,172);
        vector<int> shield(2,(int)(GetMaxHp(src)*HeroBuildState(src,172)*2/100));
        AddBuff(src,src,ESBUFF_Shield,2,&shield,172);
    }
    if(IsHeroBuild(src,18,1) && skillId==182)
    {
        vector<int> shield(2,(int)(GetMaxHp(src)*8/100));AddBuff(src,src,ESBUFF_Shield,2,&shield,182);
    }
    if(IsHeroBuild(src,16,1) && skillId==161 && !IsAlive(target))AddTeamRage(src,12);
    if(IsHeroBuild(src,16,2) && skillId==161 && IsAlive(target))
    {
        vector<ESkillTriggerType> trigger(1,ESkill_Trigger_Attacking);
        int level=GetFightMember(src)->GetSkillLevel(162);
        CalculatePassiveSkill_ExtUnitAndBuff(src,target,trigger,162,std::max(1,level),actualDamage);
    }
    if(IsHeroBuild(src,15,1) && skillId==152 && IsAlive(target) && GetStatePara1(target,ESBUFF_GetWuDamageAdd)<800)
    {
        vector<int> vulnerability(1,800);
        AddBuff(target,src,ESBUFF_GetWuDamageAdd,2,&vulnerability,152);
    }
    if(IsHeroBuild(src,15,2) && skillId==151 && IsAlive(target) && HeroBuildState(src,15101)!=m_fightTurn+1 && HeroBuildTryExtraAttack(src))
    {
        HeroBuildState(src,15101)=m_fightTurn+1;
        HeroBuildDamageAction(src,target,(int)((int64)actualDamage*60/100),151);
    }
    if(GetHeroId(src)!=14 || GetFightMember(src)->heroBuildBranch==0)return;
    if(skillId==141 && hadShield)
    {
        if(IsHeroBuild(src,14,1))HeroBuildState(src,141)=std::min(5,HeroBuildState(src,141)+1);
        if(IsHeroBuild(src,14,2) && HeroBuildState(src,14101)<2)
        {
            ++HeroBuildState(src,14101);
            GetFightMember(src)->DecSkillCD(141,1);
        }
    }
    if(skillId!=142 || !hadShield || GetStatePara1(target,ESBUFF_Shield)+GetStatePara1(target,ESBUFF_ShieldMianShang)>0)return;
    if(IsHeroBuild(src,14,1))
    {
        uint8 enemies[GROUP_MEMBER],count=0,lowest=0;GetAnotherGroup(src,enemies,count);
        for(uint8 i=0;i<count;++i)
            if(enemies[i]!=target && IsAlive(enemies[i]) && (lowest==0 || GetHp(enemies[i])<GetHp(lowest)))lowest=enemies[i];
        if(lowest>0)HeroBuildDamageAction(src,lowest,actualDamage/2,142);
    }
    else if(IsAlive(target) && !GetFightMember(target)->InNotEffectBuff(ESBUFF_GetDamageAdd)
        && GetStatePara1(target,ESBUFF_GetDamageAdd)<1200)
    {
        vector<int> vulnerable(1,1200);
        AddBuff(target,src,ESBUFF_GetDamageAdd,2,&vulnerable,142);
    }
}

bool CFight::RunHeroBuildBurstRegression()
{
    CFight battle;
    uint8 enemy=GROUP2_BEGIN+1;
    const uint8 positions[]={1,enemy,(uint8)(enemy+1)};
    for(int i=0;i<3;++i)
    {
        SharePetPtr pet(new SPet);pet->id=i==0?14:23;
        SFightMember &unit=battle.m_members[positions[i]-1];
        unit.memPtr=pet;unit.type=EFMT_PET;unit.hp=unit.unitAttr.maxHp=10000;
        unit.unitAttr.attack=1000;unit.unitAttr.speed=100;unit.level=1;
    }
    SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;
    vector<int> shield(2,4000);battle.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield);
    int damage=1000,absorbed=0,revived=0;
    battle.HeroBuildDirectDamage(1,enemy,142,damage,absorbed,false,&revived);
    if(battle.GetHp(enemy)!=9750 || absorbed!=1050 || damage!=250)return false;
    damage=1000;
    battle.HeroBuildDirectDamage(1,enemy,142,damage,absorbed,true,&revived);
    if(battle.GetHp(enemy)!=9350 || absorbed!=840 || damage!=400)return false;
    SSkillData regular(141,1);regular.CD=3;regular.leftCD=3;caster.skill_list.push_back(regular);
    battle.HeroBuildBeforeAction(1);
    for(int i=0;i<4;++i)battle.HeroBuildAfterDirectHit(1,enemy,141,true,100);
    if(caster.skill_list[0].leftCD!=1)return false;
    for(int i=0;i<8;++i)battle.HeroBuildBeforeAction(1);
    if(battle.HeroBuildState(1,144)!=4 || battle.GetUnitSpeed(1)!=88)return false;
    caster.heroBuildBranch=1;
    for(int i=0;i<8;++i)battle.HeroBuildAfterDirectHit(1,enemy,141,true,100);
    if(battle.HeroBuildState(1,141)!=5 || battle.GetUnitAttack(1)!=1200)return false;
    battle.m_members[enemy-1].buff_list.clear();
    battle.HeroBuildAfterDirectHit(1,enemy,142,true,1000);
    if(battle.GetHp(enemy+1)!=9500)return false;
    if(battle.HeroBuildDamagePercent(1,enemy,141)!=2000 || battle.HeroBuildDamagePercent(1,enemy,142)!=1500)return false;
    caster.heroBuildBranch=2;
    battle.HeroBuildAfterDirectHit(1,enemy,142,true,1000);
    if(battle.GetStatePara1(enemy,ESBUFF_GetDamageAdd)!=1200)return false;
    bool jinlingPassed=[]()->bool
    {
        CFight battle;
        uint8 enemy=GROUP2_BEGIN+1;
        const uint8 places[]={1,2,enemy,(uint8)(enemy+1)};
        for(int i=0;i<4;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?15:23;
            SFightMember &unit=battle.m_members[places[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.unitAttr.speed=100;unit.level=1;unit.attackType=1;
            unit.unitAttr.attackBase=1000;unit.unitAttr.attackRatio=10000;
            unit.unitAttr.maxHpBase=10000;unit.unitAttr.maxHpRatio=10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
            unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;
        caster.passive_skill.push_back(SSkillData(154,1));
        vector<ESkillTriggerType> triggers(1,ESkill_Trigger_UnitDied);
        vector<ESkillPassitiveType> types(1,ESkill_Pass_Attr);
        battle.m_members[enemy-1].hp=0;battle.SetState(enemy,EFST_STATE_Die);
        battle.m_members[enemy-1].affixSummoned=true;
        battle.CalculatePassiveSkill_ExtAttrEffect(1,enemy,triggers,types);
        if(battle.GetUnitAttack(1)!=1000){std::cerr<<"Jinling checkpoint 22, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        battle.m_members[enemy-1].affixSummoned=false;
        for(int i=0;i<6;++i)battle.CalculatePassiveSkill_ExtAttrEffect(1,enemy,triggers,types);
        if(battle.GetUnitAttack(1)!=1200 || battle.HeroBuildState(1,15400)!=5){std::cerr<<"Jinling checkpoint 25, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        caster.heroBuildBranch=2;caster.unitAttr.attack_percent_fight=0;caster.passSkillLimit.clear();caster.heroBuildState.clear();
        battle.m_members[1].hp=0;battle.SetState(2,EFST_STATE_Die);
        battle.CalculatePassiveSkill_ExtAttrEffect(1,2,triggers,types);
        battle.CalculatePassiveSkill_ExtAttrEffect(1,enemy,triggers,types);
        if(battle.GetUnitAttack(1)!=1090){std::cerr<<"Jinling checkpoint 30, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        battle.m_members[enemy-1].hp=10000;battle.ClearState(enemy,EFST_STATE_Die);
        battle.HeroBuildAfterDirectHit(1,enemy,151,false,1000);
        battle.HeroBuildAfterDirectHit(1,enemy,151,false,1000);
        if(battle.GetHp(enemy)!=9400){std::cerr<<"Jinling checkpoint 34, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        battle.m_members[enemy-1].hp=3999;
        if(battle.HeroBuildDamagePercent(1,enemy,152)!=2000){std::cerr<<"Jinling checkpoint 36, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        battle.m_members[enemy-1].hp=4000;
        if(battle.HeroBuildDamagePercent(1,enemy,152)!=0){std::cerr<<"Jinling checkpoint 38, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        caster.heroBuildBranch=1;
        int ratio=10000;uint8 duration=3;vector<int> effect(1,4000);
        battle.HeroBuildControlBuff(1,enemy,151,ESBUFF_GetWuDamageAdd,ratio,duration,effect);
        if(effect[0]!=1500 || duration!=3){std::cerr<<"Jinling checkpoint 42, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        battle.HeroBuildAfterDirectHit(1,enemy,152,false,1000);
        if(battle.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd)!=800){std::cerr<<"Jinling checkpoint 44, attack="<<battle.GetUnitAttack(1)<<", growth="<<battle.HeroBuildState(1,15400)<<std::endl;return false;}
        caster.heroBuildBranch=2;caster.unitAttr.attack_percent_fight=0;caster.passive_skill.clear();
        caster.unitAttr.lianjiLv=10000;caster.option=EOTNormal;
        battle.m_members[enemy-1].hp=0;battle.SetState(enemy,EFST_STATE_Die);
        battle.m_members[enemy].hp=9000;battle.m_members[enemy].unitAttr.fanjiLv=10000;
        caster.AddKillUnit(enemy);CNetMessage output;battle.KilledAction(1,output);
        // Existing defense floors at 1: floor((1000-1)*80%) = 799.
        if(battle.GetHp(enemy+1)!=8201 || battle.GetHp(1)!=10000)
        {std::cerr<<"FAIL Jinling B kill chase "<<battle.GetHp(enemy+1)<<'/'<<battle.GetHp(1)<<std::endl;return false;}
        caster.AddKillUnit(enemy);battle.KilledAction(1,output);
        return battle.GetHp(enemy+1)==8201 && caster.killList.empty();
    }();
    if(!jinlingPassed){std::cerr<<"FAIL Jinling branch regression"<<std::endl;return false;}
    bool nezhaPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        const uint8 places[]={1,enemy};
        for(int i=0;i<2;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?16:23;
            SFightMember &unit=battle.m_members[places[i]-1];unit.memPtr=pet;unit.type=EFMT_PET;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.maxHpBase=10000;unit.unitAttr.maxHpRatio=10000;
            unit.unitAttr.attack=unit.unitAttr.attackBase=1000;unit.unitAttr.attackRatio=10000;
            unit.unitAttr.speed=100;unit.level=1;unit.attackType=1;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
            unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;
        caster.skill_list.push_back(SSkillData(161,1));caster.skill_list.push_back(SSkillData(162,1));
        if(!battle.CalculateSkill_DamageHp(1,161,1))return false;
        if(battle.HeroBuildState(1,16101)!=2 || battle.HeroBuildState(1,16103)!=0
            || battle.HeroBuildState(1,163)!=3 || battle.GetHp(enemy)>=7500
            || !battle.HaveBuff(enemy,ESBUFF_GetDamageAdd) || !battle.HaveBuff(enemy,ESBUFF_SpeedDes)
            || !battle.HaveBuff(enemy,ESBUFF_FuMianKangDes))
        {std::cerr<<"Nezha triple hp/stacks "<<battle.GetHp(enemy)<<'/'<<battle.HeroBuildState(1,163)<<std::endl;return false;}
        battle.HeroBuildDebuffApplied(1,enemy,162,ESBUFF_GetDamageAdd);
        if(battle.HeroBuildState(1,163)!=3)return false;
        battle.HeroBuildBeforeAction(1);if(battle.HeroBuildState(1,163)!=0)return false;
        vector<int> shield(2,4000);battle.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield);
        int before=battle.GetHp(enemy),damage=1000,absorbed=0;
        battle.HeroBuildDirectDamage(1,enemy,162,damage,absorbed,false,NULL);
        if(damage!=0 || absorbed!=1200 || battle.GetHp(enemy)!=before)return false;
        caster.heroBuildBranch=1;battle.m_members[enemy-1].hp=2999;
        if(battle.HeroBuildDamagePercent(1,enemy,162)!=3000)return false;
        battle.m_members[enemy-1].hp=3000;
        if(battle.HeroBuildDamagePercent(1,enemy,162)!=1500)return false;
        caster.heroBuildBranch=2;caster.option=EOTSkill;caster.para=161;caster.AddKillUnit(enemy);
        CNetMessage output;battle.KilledAction(1,output);
        if(battle.GetHp(enemy)!=3000 || !caster.killList.empty())return false;
        caster.heroBuildBranch=1;caster.passive_skill.push_back(SSkillData(164,81));
        vector<int> slow(1,1000);battle.AddBuff(1,enemy,ESBUFF_SpeedDes,3,&slow);
        vector<ESkillTriggerType> turnBegin(1,ESkill_Trigger_TurnBegin);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,1,turnBegin,0,0);
        if(battle.HaveBuff(1,ESBUFF_SpeedDes) || battle.GetStatePara1(1,ESBUFF_ZengShangLvAdd)!=1000)return false;
        battle.AddBuff(1,enemy,ESBUFF_SpeedDes,3,&slow);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,1,turnBegin,0,0);
        if(!battle.HaveBuff(1,ESBUFF_SpeedDes))return false;
        caster.heroBuildBranch=2;vector<int> control; battle.AddBuff(1,enemy,ESBUFF_ChenMo,2,&control);
        vector<int> parameters;battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(164),1);
        return !parameters.empty() && parameters[0]==7000;
    }();
    if(!nezhaPassed){std::cerr<<"FAIL Nezha branch regression"<<std::endl;return false;}
    bool guardPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<2;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?17:23;uint8 pos=i==0?1:enemy;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.speed=100;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
            unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;
        battle.InitTeamRageFromAffixes();
        if(battle.GetStatePara1(1,ESBUFF_MianShangTemp)!=1200)return false;
        battle.HeroBuildBeforeAction(1);
        for(int i=0;i<6;++i)battle.HeroBuildAfterDirectHit(1,enemy,172,false,100);
        if(battle.GetStatePara1(1,ESBUFF_Shield)!=800)return false;
        battle.CalculateSkill_AddBuff(1,171,1);
        if(battle.GetStatePara1(1,ESBUFF_WuMianAndGetFaDamageAdd)!=3000)return false;
        caster.heroBuildBranch=2;caster.buff_list.clear();caster.passive_skill.push_back(SSkillData(174,1));
        battle.CalculateSkill_AddBuff(1,171,1);
        int unused=0;
        for(int i=0;i<3;++i)battle.CalculateOnceAction(enemy,1,0,0,unused,true);
        if(battle.HeroBuildState(1,17401)!=2 || battle.GetHp(enemy)>=8000)return false;
        SharePetPtr thunder(new SPet);thunder->id=18;caster.memPtr=thunder;caster.heroBuildBranch=1;caster.buff_list.clear();
        battle.HeroBuildAfterDirectHit(1,enemy,182,false,100);
        if(battle.GetStatePara1(1,ESBUFF_Shield)!=800)return false;
        caster.heroBuildBranch=2;vector<int> debuff(1,2000);int chance=20000;uint8 turn=3;
        battle.HeroBuildControlBuff(1,enemy,182,ESBUFF_FaFangDes,chance,turn,debuff);
        if(debuff[0]!=3000)return false;
        battle.AddBuff(enemy,1,ESBUFF_FaFangDes,3,&debuff,182);
        return battle.HeroBuildDamagePercent(1,enemy,181)==2000;
    }();
    if(!guardPassed){std::cerr<<"FAIL Yangjian/Leizhenzi branch regression"<<std::endl;return false;}
    bool strikePassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<3;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?19:23;uint8 pos=i==0?1:enemy+i-1;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=2;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.speed=100;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
            unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;caster.passive_skill.push_back(SSkillData(193,1));
        vector<ESkillTriggerType> attacks(1,ESkill_Trigger_Attacking);vector<SAttrData> attributes;
        for(int i=0;i<4;++i)
        {
            attributes.clear();battle.CalculatePassiveSkill_ExtValue(1,enemy,attacks,attributes);
            if(GetAttrValue(attributes,ESkill_PassAttr_Damage)!=(i<3?172:0))return false;
            int selfDamage=0;vector<SAttrData> defense;
            battle.BasicFightAction(1,enemy,0,0,selfDamage,attributes,defense,false,true);
        }
        battle.HeroBuildAfterDirectHit(1,enemy,192,false,100);
        int after=battle.GetHp(enemy);if(after>=9500)return false;
        battle.HeroBuildAfterDirectHit(1,enemy,192,false,100);if(battle.GetHp(enemy)!=after)return false;
        caster.heroBuildBranch=2;if(battle.HeroBuildDamagePercent(1,enemy,191)!=2000)return false;
        SharePetPtr shen(new SPet);shen->id=20;caster.memPtr=shen;caster.heroBuildBranch=1;
        vector<int> parameters;int chance=5000;uint8 turn=2;
        battle.HeroBuildControlBuff(1,enemy,201,ESBUFF_FanJian,chance,turn,parameters);if(chance!=6500)return false;
        caster.heroBuildBranch=2;parameters.assign(1,5000);
        battle.HeroBuildControlBuff(1,enemy,202,ESBUFF_FangYuDes,chance,turn,parameters);if(parameters[0]!=6000)return false;
        battle.AddBuff(enemy,1,ESBUFF_FangYuDes,2,&parameters,202);
        after=battle.GetHp(enemy);battle.HeroBuildAfterDirectHit(1,enemy,201,false,100);
        if(battle.GetHp(enemy)!=after-600)return false;
        SharePetPtr wen(new SPet);wen->id=21;caster.memPtr=wen;caster.heroBuildBranch=1;
        battle.m_members[enemy-1].hp=3999;if(battle.HeroBuildDamagePercent(1,enemy,211)!=2000)return false;
        battle.m_members[enemy-1].hp=4000;if(battle.HeroBuildDamagePercent(1,enemy,211)!=0)return false;
        battle.m_members[enemy-1].hp=0;battle.SetState(enemy,EFST_STATE_Die);
        int rage=battle.GetTeamRage(1);battle.HeroBuildAfterDirectHit(1,enemy,211,false,100);battle.HeroBuildAfterDirectHit(1,enemy,211,false,100);
        if(battle.GetTeamRage(1)!=rage+8)return false;
        SharePetPtr li(new SPet);li->id=22;caster.memPtr=li;caster.heroBuildBranch=2;
        if(battle.GetUnitSpeed(1)!=95 || battle.GetUnitAttack(1)!=1100)return false;
        battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(222),1);
        if(parameters.size()<2 || parameters[1]!=6250)return false;
        caster.heroBuildBranch=1;caster.passive_skill.clear();caster.passive_skill.push_back(SSkillData(223,91));
        battle.m_members[enemy-1].hp=10000;battle.ClearState(enemy,EFST_STATE_Die);
        vector<int> empty;battle.AddBuff(enemy,1,ESBUFF_FengYin,2,&empty);
        vector<ESkillTriggerType> turnBegin(1,ESkill_Trigger_TurnBegin);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,turnBegin,0,0);
        if(!battle.HaveBuff(enemy+1,ESBUFF_FengYin))return false;
        battle.m_members[enemy].buff_list.clear();battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,turnBegin,0,0);
        return !battle.HaveBuff(enemy+1,ESBUFF_FengYin);
    }();
    if(!strikePassed){std::cerr<<"FAIL Jiang/Shen/Wen/Li branch regression"<<std::endl;return false;}
    bool teamPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        const uint8 positions[]={1,2,enemy,(uint8)(enemy+1),(uint8)(enemy+2),(uint8)(enemy+3),(uint8)(enemy+4)};
        for(int i=0;i<7;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?23:10;SFightMember &unit=battle.m_members[positions[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.unitAttr.speed=100;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;
        auto hero=[&](int id,int branch){SharePetPtr pet(new SPet);pet->id=id;caster.memPtr=pet;caster.heroBuildBranch=branch;caster.passive_skill.clear();caster.buff_list.clear();caster.heroBuildState.clear();};
        vector<int> parameters;battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(233),1);
        if(parameters.size()<2 || parameters[0]!=8000 || parameters[1]!=6000)return false;
        caster.passive_skill.push_back(SSkillData(233,1));battle.HeroBuildState(1,23300)=battle.m_fightTurn+1;battle.HeroBuildState(1,23301)=3;
        if(battle.FindYuanHuPos(2)!=0)return false;
        hero(24,2);battle.m_members[1].hp=1000;battle.HeroBuildAfterDirectHit(1,enemy,241,false,100);
        battle.HeroBuildAfterDirectHit(1,enemy,241,false,100);if(battle.GetHp(2)!=1350)return false;
        battle.CalculateSkill_DamageHp(1,242,1);if(battle.GetStatePara1(2,ESBUFF_DamagePercentAdd)!=1000)return false;
        hero(25,1);caster.hp=5000;int heal=-1000,absorbed=0;battle.DecreaseHp(1,2,heal,absorbed,true);
        if(caster.hp!=5900)return false;
        hero(25,2);battle.HeroBuildAfterDirectHit(1,enemy,252,false,100);battle.HeroBuildAfterDirectHit(1,enemy,252,false,100);
        if(battle.GetStatePara1(1,ESBUFF_Shield)!=1200 || battle.HeroBuildState(1,252)!=1)return false;
        hero(26,2);vector<int> vulnerable(1,2000);
        for(int i=0;i<5;++i){battle.m_members[enemy+i-1].hp=10000;battle.AddBuff(enemy+i,1,ESBUFF_GetWuDamageAdd,2,&vulnerable,261);}
        vector<ESkillTriggerType> attacking(1,ESkill_Trigger_Attacking);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,enemy,attacking,262,1,10000);
        int affected=0;for(int i=1;i<5;++i){int hp=battle.GetHp(enemy+i);if(hp==9200)++affected;else if(hp!=10000)return false;}
        if(affected!=3)return false;
        hero(27,1);if(battle.GetUnitSpeed(1)!=110)return false;battle.m_fightTurn=2;if(battle.GetUnitSpeed(1)!=100)return false;
        caster.heroBuildBranch=2;int chance=20000;uint8 duration=99;
        for(int i=0;i<4;++i){parameters.assign(1,1500);battle.HeroBuildControlBuff(1,1,274,ESBUFF_SpeedDes,chance,duration,parameters);}
        if(parameters[0]!=2000)return false;
        hero(28,1);caster.skill_list.push_back(SSkillData(281,1));
        for(int i=0;i<7;++i)
        {for(int j=0;j<5;++j)battle.m_members[enemy+j-1].hp=10000;battle.CalculateSkill_DamageHp(1,281,1);}
        if(battle.HeroBuildState(1,281)!=5 || battle.GetUnitSpeed(1)!=120)return false;
        hero(29,2);
        for(int i=0;i<6;++i)
        {battle.HeroBuildBeforeAction(1);battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(294),1);if(parameters[1]!=(i<5?600:300))return false;}
        hero(30,1);int rage=battle.GetTeamRage(1);
        battle.HeroBuildControlFailed(1,enemy,301,ESBUFF_FengYin);battle.HeroBuildControlFailed(1,enemy+1,301,ESBUFF_FengYin);
        if(battle.GetTeamRage(1)!=rage+5)return false;
        caster.heroBuildBranch=2;parameters.assign(1,3000);battle.AddBuff(enemy,1,ESBUFF_DamagePercentDes,2,&parameters,302);
        battle.HeroBuildDebuffApplied(1,enemy,302,ESBUFF_DamagePercentDes);
        return battle.GetStatePara1(2,ESBUFF_JianShangLvAdd)==500;
    }();
    if(!teamPassed){std::cerr<<"FAIL heroes 23-30 branch regression"<<std::endl;return false;}
    bool healingPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;const uint8 positions[]={1,2,3,enemy};
        for(int i=0;i<4;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?31:10;SFightMember &unit=battle.m_members[positions[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=2;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.unitAttr.wufang=unit.unitAttr.fafang=1000;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;caster.hp=1000;battle.m_members[2].hp=1000;
        caster.passive_skill.push_back(SSkillData(5005,3));caster.passive_skill.push_back(SSkillData(313,10));
        battle.HeroBuildAfterHeal(1,2,311,10000,5000,true);
        if(battle.GetHp(1)!=2250 || battle.GetHp(3)!=2250 || battle.GetStatePara1(2,ESBUFF_Shield)!=1500)return false;
        vector<ESkillTriggerType> healing(1,ESkill_Trigger_AddHp);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,healing,311,1,5000);
        if(battle.GetHp(1)!=2250 || battle.GetHp(3)!=2250)return false;
        caster.heroBuildBranch=1;battle.m_members[1].hp=4000;battle.HeroBuildAfterHeal(1,2,311,3000,0,true);
        if(battle.GetStatePara1(2,ESBUFF_MianShangTemp)!=1200 || battle.GetUnitFangYu(2,1)!=1080)return false;
        battle.m_fightTurn=2;if(battle.GetUnitFangYu(2,1)!=1000)return false;
        caster.heroBuildBranch=2;caster.passive_skill.push_back(SSkillData(314,1));
        if(battle.GetUnitFangYu(3,2)!=1050)return false;
        SharePetPtr yuding(new SPet);yuding->id=32;caster.memPtr=yuding;caster.passive_skill.clear();
        vector<int> burn(1,800);battle.AddBuff(enemy,1,ESBUFF_ZhuoShao,3,&burn,321);
        battle.HeroBuildAfterHit(1,enemy,322);battle.HeroBuildAfterHit(1,enemy,322);
        if(battle.GetHp(enemy)!=9280 || battle.GetStatePara1(enemy,ESBUFF_ZhuoShao)!=800)return false;
        SharePetPtr daji(new SPet);daji->id=33;caster.memPtr=daji;caster.heroBuildBranch=2;
        int chance=4500;uint8 duration=2;vector<int> empty;
        battle.HeroBuildControlBuff(1,enemy,333,ESBUFF_MeiHuo,chance,duration,empty);if(chance!=6000)return false;
        battle.AddBuff(enemy,1,ESBUFF_MeiHuo,2,&empty,333);battle.HeroBuildDebuffApplied(1,enemy,333,ESBUFF_MeiHuo);
        chance=4500;battle.HeroBuildControlBuff(1,enemy,333,ESBUFF_MeiHuo,chance,duration,empty);
        if(chance>=0)return false;
        float reduction=battle.CalUnitZengShangLv(enemy,1,2,0);
        return reduction>0.969f && reduction<0.971f;
    }();
    if(!healingPassed){std::cerr<<"FAIL Taiyi/Yuding/Daji branch regression"<<std::endl;return false;}
    bool rescuePassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;const uint8 positions[]={1,2,3,enemy};
        for(int i=0;i<4;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?34:10;SFightMember &unit=battle.m_members[positions[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000+i*100;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;caster.hp=8000;battle.m_members[1].hp=1000;
        vector<int> shield(2,2000);battle.AddBuff(1,1,ESBUFF_Shield,2,&shield,342);
        if(battle.GetStatePara1(1,ESBUFF_Shield)!=2500 || battle.GetStatePara1(2,ESBUFF_Shield)!=750)return false;
        caster.buff_list.clear();caster.passive_skill.push_back(SSkillData(343,1));
        vector<ESkillTriggerType> turnBegin(1,ESkill_Trigger_TurnBegin);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,1,turnBegin,0,0);
        if(caster.hp!=8000 || battle.GetStatePara1(1,ESBUFF_Shield)!=500)return false;
        caster.heroBuildBranch=2;caster.buff_list.clear();caster.hp=2000;++battle.m_fightTurn;
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,1,turnBegin,0,0);if(caster.hp!=2800)return false;
        caster.hp=2000;++battle.m_fightTurn;battle.CalculatePassiveSkill_ExtUnitAndBuff(1,1,turnBegin,0,0);if(caster.hp!=2400)return false;
        caster.passive_skill.push_back(SSkillData(344,1));int heal=-1000,absorbed=0;battle.DecreaseHp(1,2,heal,absorbed,true);
        vector<SAttrData> attributes;vector<ESkillTriggerType> defense(1,ESkill_Trigger_DefAdd);
        battle.CalculatePassiveSkill_ExtValue(1,enemy,defense,attributes);
        if(GetAttrValue(attributes,ESkill_PassAttr_ImproveMianShangLv)!=3500)return false;
        battle.AddBuff(1,1,ESBUFF_Shield,2,&shield,342);int damage=2000;
        battle.DecreaseHp(1,enemy,damage,absorbed);int before=caster.hp;battle.ShieldBrokenCheck(1,enemy);
        if(caster.hp!=before+800)return false;
        SharePetPtr wei(new SPet);wei->id=35;caster.memPtr=wei;caster.passive_skill.clear();caster.buff_list.clear();
        for(int i=1;i<3;++i){battle.m_members[i].hp=0;battle.SetState(i+1,EFST_STATE_Die);}
        uint8 targets[GROUP_MEMBER],count=0;battle.GetSkillTargetRange(1,352,1,targets,count);
        if(count!=1 || targets[0]!=3)return false;
        battle.CalculateSkill_AddHp(1,352,1);if(battle.GetHp(3)!=3500 || battle.GetFightMember(3)->heroBuildRevivedTurn!=battle.m_fightTurn)return false;
        caster.passive_skill.push_back(SSkillData(354,1));vector<ESkillTriggerType> death(1,ESkill_Trigger_UnitDied);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,2,death,0,0);if(battle.GetHp(2)!=3000)return false;
        battle.m_members[1].hp=0;battle.SetState(2,EFST_STATE_Die);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,2,death,0,0);
        if(battle.IsAlive(2))return false;
        SharePetPtr wu(new SPet);wu->id=36;caster.memPtr=wu;caster.passive_skill.clear();caster.passive_skill.push_back(SSkillData(363,1));
        int revived=0;if(!battle.CalculateIsFuHuo(1,revived) || revived!=3500)return false;
        return !battle.CalculateIsFuHuo(1,revived);
    }();
    if(!rescuePassed){std::cerr<<"FAIL Dixin/Weihu/Wuji branch regression"<<std::endl;return false;}
    bool supportPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;const uint8 positions[]={1,2,enemy,(uint8)(enemy+1)};
        for(int i=0;i<4;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?37:10;SFightMember &unit=battle.m_members[positions[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=2;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;battle.m_members[1].hp=1000;
        vector<int> value(1,1000);battle.AddBuff(enemy,1,ESBUFF_SpeedDes,2,&value);battle.AddBuff(enemy,enemy,ESBUFF_AddSpeed,2,&value);
        battle.HeroBuildState(1,37200)=1;battle.ClearRandomEnBuff(enemy,1,1);
        if(!battle.HaveBuff(enemy,ESBUFF_SpeedDes) || battle.HaveBuff(enemy,ESBUFF_AddSpeed) || battle.GetStatePara1(2,ESBUFF_Shield)!=800){std::cerr<<"Support checkpoint 14 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        battle.AddBuff(2,2,ESBUFF_AddSpeed,2,&value);battle.AddBuff(2,enemy,ESBUFF_SpeedDes,2,&value);
        battle.ClearRandomDeBuff(2,1,1);
        if(!battle.HaveBuff(2,ESBUFF_AddSpeed) || battle.HaveBuff(2,ESBUFF_SpeedDes) || !battle.HaveBuff(2,ESBUFF_Shield)){std::cerr<<"Support checkpoint 17 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        vector<int> parameters;battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(373),1);
        if(parameters.size()<2 || parameters[0]!=7000 || parameters[1]!=2){std::cerr<<"Support checkpoint 19 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        SharePetPtr mu(new SPet);mu->id=38;caster.memPtr=mu;caster.passive_skill.push_back(SSkillData(383,31));
        battle.AddBuff(2,enemy,ESBUFF_SpeedDes,2,&value);
        vector<ESkillTriggerType> action(1,ESkill_Trigger_Action);battle.HeroBuildBeforeAction(1);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,action,0,0);
        if(battle.HaveBuff(2,ESBUFF_SpeedDes) || battle.GetStatePara1(2,ESBUFF_AddSpeed)!=2000){std::cerr<<"Support checkpoint 23 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        // The original 10% and the branch's independent 10% are both present.
        caster.heroBuildBranch=1;battle.HeroBuildState(1,38200)=battle.m_fightTurn+2;
        if(battle.HeroBuildDamagePercent(1,enemy,381)!=3200){std::cerr<<"Support checkpoint 26 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        SharePetPtr bo(new SPet);bo->id=39;caster.memPtr=bo;caster.heroBuildBranch=1;caster.passive_skill.clear();
        caster.passive_skill.push_back(SSkillData(394,1));battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(394),1);
        if(parameters[0]!=5500){std::cerr<<"Support checkpoint 29 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        battle.HeroBuildState(1,39400)=battle.m_fightTurn+1;battle.HeroBuildState(1,39401)=3;
        int before=battle.GetHp(2);vector<ESkillTriggerType> memberAction(1,ESkill_Trigger_MemberAction);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,2,memberAction,0,0);if(battle.GetHp(2)!=before){std::cerr<<"Support checkpoint 32 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        caster.heroBuildBranch=2;battle.AddBuff(1,enemy,ESBUFF_SpeedDes,2,&value);battle.AddBuff(2,enemy,ESBUFF_SpeedDes,2,&value);
        battle.CalculateSkill_DamageHp(1,392,1);if(battle.HaveBuff(1,ESBUFF_SpeedDes) || battle.HaveBuff(2,ESBUFF_SpeedDes)){std::cerr<<"Support checkpoint 34 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        SharePetPtr tu(new SPet);tu->id=40;caster.memPtr=tu;caster.heroBuildBranch=1;
        battle.GetPassivePara(1,parameters,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(401),1);if(parameters[1]!=4200){std::cerr<<"Support checkpoint 36 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        caster.heroBuildBranch=2;caster.passive_skill.clear();caster.passive_skill.push_back(SSkillData(404,1));
        vector<ESkillPassitiveType> attributes(1,ESkill_Pass_Attr);battle.CalculatePassiveSkill_ExtAttrEffect(1,0,action,attributes);
        if(battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)!=1300){std::cerr<<"Support checkpoint 39 "<<battle.GetStatePara1(1,ESBUFF_AddSpeed)<<"/"<<battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)<<std::endl;return false;}
        int chance=20000;uint8 duration=2;parameters.assign(1,2900);
        battle.HeroBuildControlBuff(1,enemy,402,ESBUFF_DamagePercentDes,chance,duration,parameters);
        return parameters[0]==2000 && duration==2;
    }();

    if(!supportPassed){std::cerr<<"FAIL Jinzha/Muzha/Boyi/Tuxing branch regression"<<std::endl;return false;}
    bool brothersPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;const uint8 positions[]={1,2,enemy};
        for(int i=0;i<3;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?41:10;SFightMember &unit=battle.m_members[positions[i]-1];
            unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;
            unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;
        vector<int> bleed(1,1000);int chance=20000;uint8 duration=3;
        battle.HeroBuildControlBuff(1,enemy,412,ESBUFF_Blooding,chance,duration,bleed);
        if(bleed[0]!=1250 || duration!=4)return false;
        battle.AddBuff(enemy,1,ESBUFF_Blooding,duration,&bleed,412);
        int rage=battle.GetTeamRage(1);battle.HeroBuildAfterDirectHit(1,enemy,411,false,100);battle.HeroBuildAfterDirectHit(1,enemy,411,false,100);
        if(battle.GetTeamRage(1)!=rage+3)return false;
        SharePetPtr bigan(new SPet);bigan->id=42;caster.memPtr=bigan;caster.hp=250;
        vector<SAttrData> attack,defense;int cost=0;
        battle.CalculateSkillDamage(1,enemy,422,1,cost,attack,defense);
        if(cost!=249)return false;
        battle.CalculateSkill_DamageHp(1,422,1);if(caster.hp!=1)return false;
        caster.heroBuildBranch=1;if(battle.IsRoleSkillUseful(1,422))return false;
        caster.heroBuildBranch=2;caster.hp=0;battle.SetState(1,EFST_STATE_Die);battle.m_members[1].hp=1000;
        caster.passive_skill.push_back(SSkillData(423,1));vector<ESkillTriggerType> death(1,ESkill_Trigger_DieAndAddToAllUnit);
        battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,death,0,0);int healed=battle.GetHp(2);
        if(healed!=2000)return false;battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,death,0,0);if(battle.GetHp(2)!=healed)return false;
        SharePetPtr yin(new SPet);yin->id=43;caster.memPtr=yin;caster.heroBuildBranch=1;caster.hp=10000;battle.ClearState(1,EFST_STATE_Die);caster.passive_skill.clear();
        chance=3000;duration=2;vector<int> empty;battle.HeroBuildControlBuff(1,enemy,431,ESBUFF_HunShui,chance,duration,empty);
        if(chance!=5000 || battle.HeroBuildDamagePercent(1,enemy,431)!=1500)return false;
        SharePetPtr jiao(new SPet);jiao->id=44;caster.memPtr=jiao;caster.buff_list.clear();battle.m_members[enemy-1].buff_list.clear();battle.m_members[enemy-1].hp=10000;
        battle.CalculateSkill_DamageHp(1,441,1);
        if(battle.GetHp(enemy)!=8611){std::cerr<<"Yinjiao triple HP "<<battle.GetHp(enemy)<<std::endl;return false;}
        caster.heroBuildBranch=2;vector<int> combo(1,5000);battle.HeroBuildControlBuff(1,2,442,ESBUFF_LianJiLvShangHaiAdd,chance,duration,combo);
        return combo[0]==6500;
    }();
    if(!brothersPassed){std::cerr<<"FAIL Deng/Bigan/brothers branch regression"<<std::endl;return false;}
    bool partnersPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<7;++i)
        {
            uint8 pos=i<4?i+1:enemy+i-4;SharePetPtr pet(new SPet);pet->id=i==0?45:10;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000+i*100;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;caster.passive_skill.push_back(SSkillData(453,1));
        vector<int> burn(1,800);for(int i=2;i<=4;++i)battle.AddBuff(i,enemy,ESBUFF_ZhuoShao,3,&burn,491);
        vector<ESkillTriggerType> action(1,ESkill_Trigger_Action);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,action,0,0);
        int burning=0;for(int i=2;i<=4;++i)if(battle.HaveBuff(i,ESBUFF_ZhuoShao))++burning;
        if(burning!=1){std::cerr<<"Partners checkpoint 15 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        SharePetPtr hong(new SPet);hong->id=46;caster.memPtr=hong;caster.passive_skill.clear();battle.HeroBuildBeforeAction(1);
        battle.CalculateSkill_DamageHp(1,462,1);
        int physical=0,magic=0,slow=0;
        for(int i=0;i<3;++i)
        {physical+=battle.HaveBuff(enemy+i,ESBUFF_WuFangDes);magic+=battle.HaveBuff(enemy+i,ESBUFF_FaFangDes);slow+=battle.HaveBuff(enemy+i,ESBUFF_SpeedDes);}
        if(physical!=1 || magic!=1 || slow!=1){std::cerr<<"Partners checkpoint 21 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        SharePetPtr tiger(new SPet);tiger->id=47;caster.memPtr=tiger;caster.heroBuildBranch=2;
        battle.CalculateSkill_DamageHp(1,471,1);
        if(battle.HeroBuildState(4,47100)!=1 || battle.HaveBuff(2,ESBUFF_GongTongShengSi)){std::cerr<<"Partners checkpoint 24 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        int before=caster.hp,allyBefore=battle.GetHp(4),unused=0;battle.CalculateOnceAction(enemy,4,0,0,unused,true);
        if(caster.hp>=before || battle.GetHp(4)>=allyBefore || before-caster.hp>=allyBefore-battle.GetHp(4)){std::cerr<<"Partners checkpoint 26 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        SharePetPtr hu(new SPet);hu->id=48;caster.memPtr=hu;caster.heroBuildBranch=1;
        int chance=20000;uint8 duration=3;vector<int> power;
        for(int i=0;i<7;++i){power.assign(1,2000);battle.HeroBuildControlBuff(1,1,483,ESBUFF_FuMianQiangHuaAdd,chance,duration,power);battle.AddBuff(1,1,ESBUFF_FuMianQiangHuaAdd,duration,&power,483);}
        if(power[0]!=3500 || duration!=2){std::cerr<<"Partners checkpoint 30 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        SharePetPtr luo(new SPet);luo->id=49;caster.memPtr=luo;caster.heroBuildBranch=1;
        uint8 targets[GROUP_MEMBER],count=0;battle.GetSkillTargetRange(1,491,1,targets,count);if(count!=3){std::cerr<<"Partners checkpoint 32 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        caster.heroBuildBranch=2;burn.assign(1,1000);battle.m_members[enemy-1].hp=10000;battle.m_members[enemy-1].buff_list.clear();
        battle.AddBuff(enemy,1,ESBUFF_ZhuoShao,3,&burn,491);battle.AddBuff(enemy,2,ESBUFF_ZhuoShao,3,&burn,321);
        battle.HeroBuildAfterHit(1,enemy,492);battle.HeroBuildAfterHit(1,enemy,492);
        if(battle.GetHp(enemy)!=8500 || !battle.HaveBuff(enemy,ESBUFF_ZhuoShao) || battle.GetStateSrcPos(enemy,ESBUFF_ZhuoShao)!=2){std::cerr<<"Partners checkpoint 36 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        SharePetPtr spirit(new SPet);spirit->id=50;caster.memPtr=spirit;battle.HeroBuildBeforeAction(1);battle.HeroBuildState(1,50200)=1;
        vector<int> benefit(1,1000);battle.AddBuff(enemy,enemy,ESBUFF_AddSpeed,2,&benefit);battle.AddBuff(enemy,enemy,ESBUFF_DamagePercentAdd,2,&benefit);
        int rage=battle.GetTeamRage(1);battle.ClearRandomEnBuff(enemy,100,1);
        battle.AddBuff(enemy,enemy,ESBUFF_AddSpeed,2,&benefit);battle.ClearRandomEnBuff(enemy,100,1);
        return battle.GetTeamRage(1)==rage+8;
    }();

    if(!partnersPassed){std::cerr<<"FAIL heroes 45-50 branch regression"<<std::endl;return false;}
    bool waterPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<3;++i)
        {
            uint8 pos=i==0?1:enemy+i-1;SharePetPtr pet(new SPet);pet->id=i==0?51:10;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=2;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];
        auto hero=[&](int id,int branch){SharePetPtr pet(new SPet);pet->id=id;caster.memPtr=pet;caster.heroBuildBranch=branch;caster.buff_list.clear();caster.passive_skill.clear();battle.HeroBuildBeforeAction(1);};
        hero(51,2);battle.HeroBuildAfterDirectHit(1,enemy,511,false,1000);battle.HeroBuildAfterDirectHit(1,enemy,511,false,1000);
        if(battle.GetHp(enemy+1)!=9700){std::cerr<<"Water checkpoint 13 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        hero(52,1);battle.HeroBuildAfterDirectHit(1,enemy,521,false,1000);
        if(battle.GetStatePara1(enemy,ESBUFF_SpeedDes)!=1500){std::cerr<<"Water checkpoint 15 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        hero(53,1);vector<int> poison(2,1000);battle.AddBuff(enemy,1,ESBUFF_FuDu,10,&poison,531);
        if(battle.HaveBuff(enemy,ESBUFF_FuDu) || battle.GetStatePara1(enemy,ESBUFF_ShiDu)!=200){std::cerr<<"Water checkpoint 17 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        caster.heroBuildBranch=2;poison[0]=600;poison[1]=100;battle.AddBuff(enemy,enemy+1,ESBUFF_ShiDu,3,&poison,532);
        battle.HeroBuildAfterDirectHit(1,enemy,532,false,100);battle.HeroBuildAfterDirectHit(1,enemy,532,false,100);
        if(battle.GetHp(enemy)!=9900){std::cerr<<"Water checkpoint 20 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        hero(54,2);battle.m_members[enemy].hp=0;battle.SetState(enemy+1,EFST_STATE_Die);battle.HeroBuildAfterDirectHit(1,enemy,542,false,1000);battle.HeroBuildAfterDirectHit(1,enemy,542,false,1000);
        if(battle.GetHp(enemy)!=9300){std::cerr<<"Water checkpoint 22 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        hero(55,1);battle.CalculateSkill_DamageHp(1,551,1);
        if(battle.GetStatePara1(1,ESBUFF_AddSpeed)!=1500){std::cerr<<"Water checkpoint 24 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        hero(56,2);battle.m_members[enemy-1].buff_list.clear();battle.m_members[enemy-1].hp=10000;caster.unitAttr.baojiLv=100000;
        int selfDamage=0;vector<SAttrData> attr,tarAttr;int expected=battle.CalculateSkillDamage(1,enemy,562,1,selfDamage,attr,tarAttr);
        battle.CalculateOnceAction(1,enemy,562,1,selfDamage,true);
        if(battle.GetHp(enemy)!=10000-expected){std::cerr<<"Water checkpoint 28 hp="<<battle.GetHp(enemy)<<" extra="<<battle.GetHp(enemy+1)<<std::endl;return false;}
        return battle.HeroBuildDamagePercent(1,enemy,562)==1000;
    }();
    if(!waterPassed){std::cerr<<"FAIL heroes 51-56 branch regression"<<std::endl;return false;}
    std::cout<<"PASS heroes 51-56: splash once/slow/flat owned poison/foreign poison exclusion/single-target double hit/speed/no-crit branch"<<std::endl;
    bool plaguePassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<5;++i)
        {
            uint8 pos=i<2?i+1:enemy+i-2;SharePetPtr pet(new SPet);pet->id=i==0?57:10;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=2;int unused=0;
        for(int i=0;i<3;++i)battle.CalculateOnceAction(enemy,1,0,0,unused,true);
        if(battle.GetStatePara1(2,ESBUFF_DamagePercentAdd)!=600){std::cerr<<"Plague checkpoint 12 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        ++battle.m_fightTurn;for(int i=0;i<3;++i)battle.CalculateOnceAction(enemy,1,0,0,unused,true);
        if(battle.GetStatePara1(2,ESBUFF_DamagePercentAdd)!=1200){std::cerr<<"Plague checkpoint 14 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        SharePetPtr fei(new SPet);fei->id=58;caster.memPtr=fei;vector<int> weakness(1,2500);battle.AddBuff(enemy,1,ESBUFF_FuMianKangDes,2,&weakness,581);
        battle.HeroBuildBeforeAction(1);int rage=battle.GetTeamRage(1);battle.HeroBuildAfterDirectHit(1,enemy,582,false,100);battle.HeroBuildAfterDirectHit(1,enemy,582,false,100);
        if(battle.GetTeamRage(1)!=rage+6){std::cerr<<"Plague checkpoint 17 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        int chance=4000;uint8 duration=2;vector<int> parameters;battle.HeroBuildControlBuff(1,enemy,582,ESBUFF_FanJian,chance,duration,parameters);
        if(chance!=6000 || duration!=1){std::cerr<<"Plague checkpoint 19 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        SharePetPtr e(new SPet);e->id=59;caster.memPtr=e;caster.passive_skill.push_back(SSkillData(594,100));caster.option=EOTSkill;caster.para=591;
        CNetMessage message;for(int i=0;i<3;++i){caster.AddKillUnit(enemy+1);battle.KilledAction(1,message);}
        if(battle.HeroBuildState(1,59401)!=2){std::cerr<<"Plague checkpoint 22 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        SharePetPtr lu(new SPet);lu->id=60;caster.memPtr=lu;caster.heroBuildBranch=1;caster.buff_list.clear();caster.passive_skill.clear();
        caster.passive_skill.push_back(SSkillData(603,1));caster.passive_skill.push_back(SSkillData(604,1));
        battle.m_members[enemy-1].unitAttr.attack=2000;battle.HeroBuildBeforeAction(1);
        if(battle.GetStatePara1(enemy,ESBUFF_WuFangDes)!=1100 || battle.GetStatePara1(enemy,ESBUFF_FuMianKangDes)<800){std::cerr<<"Plague checkpoint 26 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        vector<int> poison(2,100);for(int i=0;i<3;++i)battle.AddBuff(enemy,1,ESBUFF_ShiDu,3,&poison,601);
        battle.HeroBuildDebuffApplied(1,enemy,601,ESBUFF_ShiDu);
        if(!battle.HaveZhongDuState(enemy+1)){std::cerr<<"Plague checkpoint 29 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        caster.heroBuildBranch=2;battle.HeroBuildBeforeAction(1);
        if(battle.GetStatePara1(enemy,ESBUFF_DamagePercentDes)!=2650){std::cerr<<"Plague checkpoint 31 hp="<<battle.GetHp(1)<<" chase="<<battle.HeroBuildState(1,59401)<<std::endl;return false;}
        return battle.HeroBuildDamagePercent(1,enemy,601)==1500 && battle.HeroBuildDamagePercent(1,enemy,602)==2400;
    }();
    if(!plaguePassed){std::cerr<<"FAIL heroes 57-60 branch regression"<<std::endl;return false;}
    std::cout<<"PASS heroes 57-60: direct-hit team stacks/round cap/refund once/control duration/chase cap/poison spread/highest-attack debuffs/poison scaling"<<std::endl;
    bool finalHeroesPassed=[]()->bool
    {
        CFight battle;uint8 enemy=GROUP2_BEGIN+1;
        for(int i=0;i<4;++i)
        {
            uint8 pos=i<2?i+1:enemy+i-2;SharePetPtr pet(new SPet);pet->id=i==0?61:10;
            SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;unit.attackType=1;
            unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.mingzhongLv=10000;unit.unitAttr.baojiLv=-10000;
            unit.unitAttr.mingzhong=unit.unitAttr.shanbi=unit.unitAttr.baoji=unit.unitAttr.baojikang=1;
        }
        SFightMember &caster=battle.m_members[0];
        auto hero=[&](int id,int branch){SharePetPtr pet(new SPet);pet->id=id;caster.memPtr=pet;caster.heroBuildBranch=branch;caster.buff_list.clear();caster.passive_skill.clear();caster.skill_list.clear();battle.HeroBuildBeforeAction(1);};
        hero(61,2);caster.passive_skill.push_back(SSkillData(613,100));vector<ESkillTriggerType> death(1,ESkill_Trigger_DieAndAddToOtherUnit);
        int rage=battle.GetTeamRage(1);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,death,0,0);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,death,0,0);
        if(battle.GetHp(enemy)!=8000 || battle.GetTeamRage(1)!=rage+8){std::cerr<<"Final heroes checkpoint 14 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(62,1);battle.CalculateSkill_DamageHp(1,621,1);
        if(battle.GetStatePara1(1,ESBUFF_ShanBiLvAdd)!=4000){std::cerr<<"Final heroes checkpoint 16 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        battle.m_members[enemy-1].unitAttr.mingzhongLv=-100000;int hp=battle.GetHp(enemy),unused=0;
        battle.CalculateOnceAction(enemy,1,0,0,unused,true);battle.CalculateOnceAction(enemy,1,0,0,unused,true);
        if(battle.GetHp(enemy)!=hp-600){std::cerr<<"Final heroes checkpoint 19 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(63,1);int chance=5000;uint8 duration=2;vector<int> parameters(1,5000);
        battle.HeroBuildControlBuff(1,enemy,631,ESBUFF_ReduceMingZhongLv,chance,duration,parameters);
        if(parameters[0]!=3500 || duration!=3){std::cerr<<"Final heroes checkpoint 22 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        battle.HeroBuildControlBuff(1,enemy,634,ESBUFF_ReduceMingZhongLv,chance,duration,parameters);
        battle.AddBuff(enemy,1,ESBUFF_ReduceMingZhongLv,duration,&parameters,634);battle.HeroBuildDebuffApplied(1,enemy,634,ESBUFF_ReduceMingZhongLv);
        battle.HeroBuildControlBuff(1,enemy,634,ESBUFF_ReduceMingZhongLv,chance,duration,parameters);if(chance>=0){std::cerr<<"Final heroes checkpoint 25 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(64,2);chance=2000;duration=0;parameters.clear();battle.HeroBuildControlBuff(1,enemy,642,ESBUFF_ChenMo,chance,duration,parameters);
        if(chance!=4500 || duration!=1){std::cerr<<"Final heroes checkpoint 27 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(65,1);parameters.assign(2,100);duration=3;battle.HeroBuildControlBuff(1,enemy,651,ESBUFF_ShiDu,chance,duration,parameters);
        if(parameters[0]!=120 || parameters[1]!=120){std::cerr<<"Final heroes checkpoint 29 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(66,1);caster.passive_skill.push_back(SSkillData(663,1));battle.m_members[1].unitAttr.attack=2000;
        vector<ESkillTriggerType> turn(1,ESkill_Trigger_TurnBegin_RandSelfOne);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,0,turn,0,0);
        if(battle.GetStatePara1(2,ESBUFF_AddSpeed)!=1500 || battle.HaveBuff(1,ESBUFF_AddSpeed)){std::cerr<<"Final heroes checkpoint 32 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(67,1);battle.GetBuffPara(1,parameters,SingletonCSkillMgr::instance().GetActiveEffectCfg(671),1);
        if(parameters.empty() || parameters[0]!=372){std::cerr<<"Final heroes checkpoint 34 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        caster.heroBuildBranch=2;battle.HeroBuildAfterDirectHit(1,enemy,672,false,100);
        if(battle.GetStatePara1(1,ESBUFF_AddSpeed)!=800){std::cerr<<"Final heroes checkpoint 36 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        hero(68,1);caster.skill_list.push_back(SSkillData(681,1));
        for(int i=0;i<7;++i){battle.m_members[enemy-1].hp=battle.m_members[enemy].hp=100000;battle.SkillButtle(1,681);}
        if(caster.GetSkillExtDataPara(681,2)!=5 || caster.GetSkillExtDataPara(681,1)!=10000){std::cerr<<"Final heroes checkpoint 39 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
        caster.heroBuildBranch=2;caster.unitAttr.fumianAdd=100000;battle.m_members[enemy-1].isWorldBoss=true;
        vector<ESkillTriggerType> attacking(1,ESkill_Trigger_Attacking);battle.CalculatePassiveSkill_ExtUnitAndBuff(1,enemy,attacking,682,1);
        return battle.GetStatePara1(enemy,ESBUFF_GetDamageAdd)==1000 && !battle.HaveBuff(enemy,ESBUFF_ForbidFuHuo);
    }();
    if(!finalHeroesPassed){std::cerr<<"FAIL heroes 61-68 branch regression"<<std::endl;return false;}
    std::cout<<"PASS heroes 61-68: death explosion cap/once/rage/dodge chase/control duration/poison multiplier/ally targeting/HOT/team speed/growth cap/boss substitution"<<std::endl;
    std::cout<<"PASS Duobao A/B: partial shield penetration/shield-only bonus/CD cap/stack cap/speed tradeoff/splash/vulnerability"<<std::endl;
    std::cout<<"PASS Jinling A/B: death growth/mixed team weights/summon exclusion/caps/vulnerability/low HP/kill chase/no counter or combo chain"<<std::endl;
    std::cout<<"PASS Nezha A/B: three-hit weapon sequence/stack cap/action reset/shield-only pressure/low HP boundary/no tactic kill chase"<<std::endl;
    std::cout<<"PASS Yangjian/Leizhenzi: opening guard/shield cap/physical guard cost/guaranteed dog counter cap/defense shred synergy"<<std::endl;
    std::cout<<"PASS Jiang/Shen/Wen/Li: whip limit/magic chase/control odds/shred bonus/execute boundary/rage cap/attack-speed tradeoff/seal target and limit"<<std::endl;
    std::cout<<"PASS heroes 23-30: protect quota/heal-on-hit quota/team buff/heal tradeoff/shield quota/splash cap/speed caps/crit growth cap/refund and team guard"<<std::endl;
    std::cout<<"PASS Taiyi/Yuding/Daji: shared overheal budget/recipient cap/no legacy double spread/guard expiry/team magic defense/burn detonation quota/charm quota"<<std::endl;
    std::cout<<"PASS Dixin/Weihu/Wuji: shield spread/regen conversion/two-round double-heal cooldown/retained low-HP guard/shield-break heal/targeted fixed revive/lifetime limits"<<std::endl;
    std::cout<<"PASS Jinzha/Muzha/Boyi/Tuxing: mixed-list cleanse/dispel/shield reward/transfer parameters/cleanse speed/action-heal quota/team cleanse/crit and timed evasion"<<std::endl;
    std::cout<<"PASS Deng/Bigan/brothers: bleed duration/damage/rage quota/sacrifice 1HP floor/death pulse once/sleep chance/three-hit damage/team combo multiplier"<<std::endl;
    std::cout<<"PASS heroes 45-50: burn cleanse target cap/five-element sequence/single-ally protection/share reduction/debuff-power cap/three targets/owned burn consumption/dispel rage cap"<<std::endl;
    return true;
}
