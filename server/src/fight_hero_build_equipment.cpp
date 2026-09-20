#include "fight.h"
#include "user.h"
#include "pet_equip_manage.h"
#include "singleton.h"
#include <algorithm>
#include <set>
#include <iostream>

// 100000: equipped artifact template; 100100..110: distinct set slots.
// 101xxx: equipment event budgets; 200xxx: shared V2 event budgets.
int CFight::HeroBuildArtifactValue(uint8 pos,int family)
{
    if(!GetFightMember(pos))return 0;
    int id=HeroBuildState(pos,100000),quality=(id-1000)/100;
    if(id<1001 || id>1414 || id%100!=family || quality<0 || quality>4)return 0;
    if(family==3 || family==7)return 800+quality*400;
    if(family==4)return 2000+quality*1000;
    if(family==10)return 600+quality*300;
    if(family==12){const int values[]={1500,2200,3000,3700,4500};return values[quality];}
    if(family==13)return 2+quality;
    if(family==14)return 200+quality*100;
    return 400+quality*200;
}

int CFight::HeroBuildSetPieces(uint8 pos,int setId)
{
    return GetFightMember(pos) && setId>=1 && setId<=10?HeroBuildState(pos,100100+setId):0;
}

void CFight::HeroBuildSnapshotEquipment(uint8 pos,CUser *owner,uint16 heroId)
{
    if(!owner)return;
    CEquipManeger &manager=owner->GetPetEquipMgr();
    FormationEquipMap worn;manager.GetWornEquipment(owner->GetChuZhanIdx(heroId),worn);
    std::set<uint32> seen;
    for(FormationEquipMapIt it=worn.begin();it!=worn.end();++it)
    {
        if(it->first<1 || it->first>6 || it->second==0)continue;
        if(it->first<=4)
        {
            if(!seen.insert(it->second).second)continue;
            CEquip *equipment=manager.GetEqiup(it->second);
            CEquipCfg *config=equipment?sCItemCfgManager.GetEquipCfg(equipment->id):NULL;
            if(config && config->suit>=1 && config->suit<=10 && config->part==it->first)
                ++HeroBuildState(pos,100100+config->suit);
        }
        else
        {
            FaBao *artifact=manager.GetFaBao(it->second);
            if(!artifact || artifact->id<1001 || artifact->id>1414 || artifact->id%100<1 || artifact->id%100>14)continue;
            // Two legacy artifact slots retain their base stats. Only the higher
            // quality mechanism is active; ties prefer slot 5 (ordered map).
            int current=HeroBuildState(pos,100000);
            if(current==0 || artifact->id/100>current/100)HeroBuildState(pos,100000)=artifact->id;
        }
    }
}

bool CFight::HeroBuildTryExtraAttack(uint8 pos)
{
    SFightMember *unit=GetFightMember(pos);
    if(!unit || !IsAlive(pos) || unit->heroBuildRevivedTurn==m_fightTurn)return false;
    if(HeroBuildState(pos,200001)!=m_fightTurn+1)
    {HeroBuildState(pos,200001)=m_fightTurn+1;HeroBuildState(pos,200002)=0;}
    if(HeroBuildState(pos,200002)>=3)return false;
    ++HeroBuildState(pos,200002);return true;
}

void CFight::HeroBuildEquipmentOpening()
{
    for(int side=0;side<2;++side)
    {
        int first=side==0?1:GROUP2_BEGIN+1,last=side==0?GROUP2_BEGIN:MAX_MEMBER;
        uint8 strongest=0;
        for(int pos=first;pos<=last;++pos)if(IsAlive(pos) && HeroBuildSetPieces(pos,9)>=4)
            if(strongest==0 || GetMaxHp(pos)>GetMaxHp(strongest))strongest=(uint8)pos;
        if(strongest && HeroBuildState(strongest,101009)==0)
        {
            HeroBuildState(strongest,101009)=1;vector<int> shield(2,(int)(GetMaxHp(strongest)*6/100));
            for(int pos=first;pos<=last;++pos)if(IsAlive(pos))AddBuff(pos,strongest,ESBUFF_Shield,2,&shield,10009);
        }
    }
}

void CFight::HeroBuildEquipmentAction(uint8 pos)
{
    HeroBuildState(pos,101001)=HeroBuildState(pos,101006)=HeroBuildState(pos,101007)=HeroBuildState(pos,101101)=0;
    int value=HeroBuildArtifactValue(pos,14);
    if(value>0 && IsAlive(pos) && GetHp(pos)*100<GetMaxHp(pos)*40
        && (HeroBuildState(pos,101014)==0 || m_fightTurn+1-HeroBuildState(pos,101014)>=2))
    {
        HeroBuildState(pos,101014)=m_fightTurn+1;vector<int> shield(2,(int)(GetMaxHp(pos)*value/10000));
        AddBuff(pos,pos,ESBUFF_Shield,1,&shield,10014);
    }
}

void CFight::HeroBuildEquipmentHeal(uint8 src,uint8 target,bool revived,bool periodic)
{
    if(!IsAlive(target))return;
    int value=HeroBuildArtifactValue(src,3);
    if(revived && value>0 && HeroBuildState(src,102000+target)==0)
    {
        HeroBuildState(src,102000+target)=1;vector<int> guard(1,value);
        AddBuff(target,src,ESBUFF_JianShangLvAdd,1,&guard,10003);
    }
    if(!revived && HeroBuildSetPieces(src,10)>=4 && HeroBuildState(src,103000+target)!=m_fightTurn+1)
    {
        // A HOT instance marks its first successful tick in the periodic path.
        if(periodic && HeroBuildState(src,104000+target)>0)return;
        HeroBuildState(src,103000+target)=m_fightTurn+1;
        if(periodic)HeroBuildState(src,104000+target)=1;
        vector<int> speed(1,800);AddBuff(target,src,ESBUFF_AddSpeed,1,&speed,10010);
    }
}

void CFight::HeroBuildEquipmentCleanse(uint8 src)
{
    int value=HeroBuildArtifactValue(src,12);
    if(value<=0 || m_heroBuildSecondaryDamage || HeroBuildState(src,101012)==m_fightTurn+1)return;
    HeroBuildState(src,101012)=m_fightTurn+1;
    uint8 allies[GROUP_MEMBER],count=0,best=0;GetMeGroup(src,allies,count);
    for(uint8 i=0;i<count;++i)if(!best || GetHp(allies[i])*GetMaxHp(best)<GetHp(best)*GetMaxHp(allies[i]))best=allies[i];
    if(best)HeroBuildHpAction(src,best,GetUnitAttack(src)*value/10000,10012);
}

void CFight::HeroBuildEquipmentShare(uint8 protector,uint8 attacker)
{
    if(m_heroBuildSecondaryDamage || !IsAlive(protector) || !IsAlive(attacker))return;
    int value=HeroBuildArtifactValue(protector,4);
    if(value>0 && HeroBuildState(protector,101004)!=m_fightTurn+1 && HeroBuildTryExtraAttack(protector))
    {HeroBuildState(protector,101004)=m_fightTurn+1;HeroBuildDamageAction(protector,attacker,GetUnitAttack(protector)*value/10000,10004);}
    if(HeroBuildSetPieces(protector,1)>=4 && HeroBuildState(protector,105001)!=m_fightTurn+1 && HeroBuildTryExtraAttack(protector))
    {HeroBuildState(protector,105001)=m_fightTurn+1;HeroBuildDamageAction(protector,attacker,GetUnitAttack(protector)*60/100,11001);}
}

void CFight::HeroBuildEquipmentDeath(uint8 pos)
{
    if(GetFightMember(pos)->affixSummoned)return;
    int value=HeroBuildArtifactValue(pos,11);
    if(value<=0 || HeroBuildState(pos,101011)>0)return;
    HeroBuildState(pos,101011)=1;vector<int> attack(1,value);
    uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(pos,allies,count);
    for(uint8 i=0;i<count;++i)AddBuff(allies[i],pos,ESBUFF_DamagePercentAdd,2,&attack,10011);
}

int CFight::HeroBuildEquipmentDamage(uint8 src,uint8 target)
{
    int bonus=GetHp(target)*100<GetMaxHp(target)*35?HeroBuildArtifactValue(src,5):0;
    int hit=HeroBuildState(src,101006);
    if(hit>=1 && hit<=3)bonus+=HeroBuildArtifactValue(src,6);
    int weakness=HeroBuildArtifactValue(src,9);
    if(weakness>0)
    {
        std::set<int> categories;SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
        {
            uint16 id=it->id;
            if(id==ESBUFF_ShiDu || id==ESBUFF_FuDu || id==ESBUFF_ShiXinDu)categories.insert(1);
            else if(id==ESBUFF_ZhuoShao)categories.insert(2);
            else if(id==ESBUFF_Blooding)categories.insert(3);
            else if(IsAffixHardControl(id))categories.insert(4);
            else if(id==ESBUFF_DamagePercentDes || id==ESBUFF_WuGongDes || id==ESBUFF_FaGongDes || id==ESBUFF_JinGuZhou)categories.insert(5);
            else if(id==ESBUFF_WuFangDes || id==ESBUFF_FaFangDes || id==ESBUFF_FangYuDes)categories.insert(6);
            else if(id==ESBUFF_SpeedDes)categories.insert(7);
            else if(id==ESBUFF_JinLiaoShu)categories.insert(8);
            else if(id==ESBUFF_GetDamageAdd || id==ESBUFF_GetWuDamageAdd || id==ESBUFF_GetFaDamageAdd)categories.insert(9);
            else if(id==ESBUFF_ReduceMingZhongLv)categories.insert(10);
            else if(id==ESBUFF_FuMianKangDes)categories.insert(11);
        }
        if(categories.size()>=2)bonus+=weakness;
    }
    return bonus;
}

void CFight::HeroBuildEquipmentHit(uint8 src,uint8 target,uint16 skillId,int damage)
{
    HeroSkillRoleCfg *role=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(GetHeroId(src));
    if(HeroBuildSetPieces(src,7)>=4 && role && role->regularSkillId==skillId && HeroBuildState(src,101007)==0 && IsAlive(target))
    {
        HeroBuildState(src,101007)=1;
        if(!GetFightMember(target)->InNotEffectBuff(ESBUFF_SpeedDes))
        {vector<int> slow(1,HeroBuildBoss(target)?1000:1200);AddBuff(target,src,ESBUFF_SpeedDes,2,&slow,11007);}
    }
    if(HeroBuildSetPieces(src,8)>=4 && HeroBuildState(src,101006)==1 && HeroBuildState(src,105008)!=m_fightTurn+1)
    {
        HeroBuildState(src,105008)=m_fightTurn+1;
        if(IsAlive(target) && (!GetFightMember(target)->InNotEffectBuff(ESBUFF_FengYin) || HeroBuildBoss(target)) && Random(1,10000)<=3500)
        {vector<int> seal;AddBuff(target,src,ESBUFF_FengYin,1,&seal,11008);}
    }

}

void CFight::HeroBuildEquipmentRegular(uint8 src)
{
    if(HeroBuildArtifactValue(src,13)<=0)return;
    int first=src<=GROUP2_BEGIN?1:GROUP2_BEGIN+1;
    if(HeroBuildState(first,101013)>0)return;
    int best=0;uint8 owner=0;
    for(int pos=first;pos<first+GROUP_MEMBER;++pos)if(IsAlive(pos) && HeroBuildArtifactValue(pos,13)>best)
    {owner=pos;best=HeroBuildArtifactValue(pos,13);}
    if(best>0){HeroBuildState(first,101013)=1;AddTeamRage(owner,best);}
}

bool CFight::RunHeroBuildEquipmentRegression()
{
    CFight battle;uint8 enemy=GROUP2_BEGIN+1;
    for(int i=0;i<4;++i)
    {
        uint8 pos=i<3?i+1:enemy;SharePetPtr pet(new SPet);pet->id=10;
        SFightMember &unit=battle.m_members[pos-1];unit.memPtr=pet;unit.type=EFMT_PET;unit.level=1;
        unit.hp=unit.unitAttr.maxHp=10000;unit.unitAttr.attack=1000;unit.unitAttr.speed=100;
    }
    for(int quality=0;quality<5;++quality)for(int family=1;family<=14;++family)
    {
        battle.HeroBuildState(1,100000)=1000+quality*100+family;
        if(battle.HeroBuildArtifactValue(1,family)<=0 || battle.HeroBuildArtifactValue(1,family%14+1)!=0){std::cerr<<"Equipment checkpoint 12 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    }
    battle.HeroBuildState(1,100000)=1401;battle.HeroBuildState(1,100109)=2;
    vector<int> shield(2,1000);battle.AddBuff(2,1,ESBUFF_Shield,2,&shield,121);
    if(battle.GetStatePara1(2,ESBUFF_Shield)!=1240){std::cerr<<"Equipment checkpoint 16 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.m_members[1].buff_list.clear();battle.HeroBuildState(1,100109)=0;battle.HeroBuildState(1,100000)=1407;
    battle.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield,121);
    int damage=1000,absorbed=0;battle.HeroBuildDirectDamage(1,enemy,101,damage,absorbed,false,NULL);
    if(absorbed!=1000 || battle.GetHp(enemy)!=9807){std::cerr<<"Equipment checkpoint 20 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.m_members[enemy-1].buff_list.clear();battle.m_members[enemy-1].hp=10000;
    battle.HeroBuildState(1,100000)=1410;vector<int> poison(2,0);poison[0]=500;
    for(int i=0;i<7;++i)battle.AddBuff(enemy,1,ESBUFF_ShiDu,9,&poison,531);
    int layers=0;for(list<SFightBuffData>::const_iterator it=battle.m_members[enemy-1].buff_list.begin();it!=battle.m_members[enemy-1].buff_list.end();++it)
    {++layers;if(it->leftTurn>5){std::cerr<<"Equipment checkpoint 25 hp="<<battle.GetHp(enemy)<<std::endl;return false;}}
    if(layers!=5){std::cerr<<"Equipment checkpoint 26 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.AddBuff(enemy,2,ESBUFF_ShiDu,3,&poison,532);CNetMessage periodic;
    battle.HeroBuildPeriodicActions(enemy,periodic);
    if(battle.GetHp(enemy)!=7500 || battle.HeroBuildState(1,200021)!=2000 || battle.HeroBuildState(2,200021)!=500){std::cerr<<"Equipment checkpoint 29 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100000)=1412;battle.m_members[1].hp=1000;
    battle.HeroBuildEquipmentCleanse(1);battle.HeroBuildEquipmentCleanse(1);
    if(battle.GetHp(2)!=1450){std::cerr<<"Equipment checkpoint 32 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100000)=1403;battle.HeroBuildEquipmentHeal(1,2,true);battle.HeroBuildEquipmentHeal(1,2,true);
    if(battle.GetStatePara1(2,ESBUFF_JianShangLvAdd)!=2400){std::cerr<<"Equipment checkpoint 34 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100000)=1413;battle.HeroBuildState(2,100000)=1013;
    int rage=battle.GetTeamRage(1);battle.HeroBuildEquipmentRegular(2);battle.HeroBuildEquipmentRegular(1);
    if(battle.GetTeamRage(1)!=rage+6){std::cerr<<"Equipment checkpoint 37 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100000)=1414;battle.m_members[0].hp=3000;battle.HeroBuildEquipmentAction(1);
    if(battle.GetStatePara1(1,ESBUFF_Shield)!=600){std::cerr<<"Equipment checkpoint 39 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.m_members[0].buff_list.clear();battle.HeroBuildEquipmentAction(1);++battle.m_fightTurn;battle.HeroBuildEquipmentAction(1);
    if(battle.HaveShieldState(1)){std::cerr<<"Equipment checkpoint 41 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    ++battle.m_fightTurn;battle.HeroBuildEquipmentAction(1);if(battle.GetStatePara1(1,ESBUFF_Shield)!=600){std::cerr<<"Equipment checkpoint 42 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100000)=1411;battle.HeroBuildEquipmentDeath(1);battle.HeroBuildEquipmentDeath(1);
    if(battle.GetStatePara1(2,ESBUFF_DamagePercentAdd)!=1200){std::cerr<<"Equipment checkpoint 44 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(3,100000)=1011;battle.HeroBuildEquipmentDeath(3);
    if(battle.GetStatePara1(2,ESBUFF_DamagePercentAdd)!=1200){std::cerr<<"Equipment checkpoint 46 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100110)=4;battle.HeroBuildEquipmentHeal(1,2,false);
    if(battle.GetStatePara1(2,ESBUFF_AddSpeed)!=800){std::cerr<<"Equipment checkpoint 48 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    battle.HeroBuildState(1,100101)=4;battle.HeroBuildState(1,100000)=1404;
    int before=battle.GetHp(enemy);battle.HeroBuildEquipmentShare(1,enemy);battle.HeroBuildEquipmentShare(1,enemy);
    if(battle.GetHp(enemy)!=before-battle.GetUnitAttack(1)*120/100){std::cerr<<"Equipment checkpoint 51 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    if(!battle.HeroBuildTryExtraAttack(1) || battle.HeroBuildTryExtraAttack(1)){std::cerr<<"Equipment checkpoint 52 hp="<<battle.GetHp(enemy)<<std::endl;return false;}
    // Separate fixtures keep equipment effects out of global rule expectations.
    CFight rules;
    for(int i=0;i<4;++i)
    {
        uint8 pos=i<3?i+1:enemy;SharePetPtr pet(new SPet);pet->id=10;
        SFightMember &u=rules.m_members[pos-1];u.memPtr=pet;u.type=EFMT_PET;u.level=1;u.hp=u.unitAttr.maxHp=10000;u.unitAttr.attack=1000;
    }
    rules.AddTeamRage(1,50);rules.AddTeamRage(1,50);rules.AddTeamRage(2,50);rules.AddTeamRage(3,50);
    if(rules.GetTeamRage(1)!=30){std::cerr<<"FAIL global extra-rage budgets"<<std::endl;return false;}
    ++rules.m_fightTurn;rules.AddTeamRage(1,50);if(rules.GetTeamRage(1)!=42)return false;
    rules.m_members[0].unitAttr.baojiAdd=100000;if(rules.GetBaoJiDamage(1,100)!=300)return false;
    rules.m_members[0].unitAttr.baojiAdd=0;if(rules.GetBaoJiDamage(1,100)!=150)return false;
    rules.m_members[enemy-1].unitAttr.shanbiLv=100000;if(rules.CalculateHitRatio(1,enemy)!=1000)return false;
    rules.m_members[enemy-1].unitAttr.wumianLv=10000;
    float guard=rules.CalUnitZengShangLv(1,enemy,1,5000);if(guard<0.399f || guard>0.401f)return false;
    vector<int> exposed(1,4000);rules.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&exposed,151);rules.AddBuff(enemy,1,ESBUFF_GetWuDamageAdd,2,&exposed,292);
    if(rules.CalUnitShangHaiJianMianLv(1,enemy,1)>1.501f)return false;
    rules.m_members[enemy-1].buff_list.clear();rules.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield,121);
    damage=1000;absorbed=0;rules.HeroBuildDirectDamage(1,enemy,0,damage,absorbed,true,NULL);
    if(rules.GetHp(enemy)!=9600 || absorbed!=600){std::cerr<<"FAIL global shield bypass cap"<<std::endl;return false;}
    SFightMember &healer=rules.m_members[0];healer.skill_list.push_back(SSkillData(101,1));healer.skill_list.push_back(SSkillData(102,1));healer.heroBuildStrategy=1;
    rules.AddTeamRage(1,60,false);rules.m_members[1].hp=0;rules.SetState(2,EFST_STATE_Die);
    if(rules.GetUnitAISkillId(1)!=102){std::cerr<<"FAIL rescue AI revive priority"<<std::endl;return false;}
    healer.skill_list[1].leftCD=6;rules.ClearState(2,EFST_STATE_Die);rules.m_members[1].hp=1000;
    if(rules.GetUnitAISkillId(1)!=101){std::cerr<<"FAIL rescue AI emergency heal"<<std::endl;return false;}
    healer.heroBuildState[200040]=rules.m_fightTurn;healer.DecSkillCD(102,10);healer.DecSkillCD(102,10);
    if(healer.skill_list[1].leftCD!=4){std::cerr<<"FAIL passive cooldown budget"<<std::endl;return false;}
    rules.m_members[enemy-1].buff_list.clear();rules.m_members[enemy-1].isWorldBoss=true;
    vector<int> control;rules.AddBuff(enemy,1,ESBUFF_ChenMo,3,&control,201);rules.AddBuff(enemy,2,ESBUFF_FengYin,3,&control,221);
    if(rules.HaveBuff(enemy,ESBUFF_ChenMo) || rules.HaveBuff(enemy,ESBUFF_FengYin) || rules.GetStatePara1(enemy,ESBUFF_SpeedDes)!=1000)return false;
    ++rules.m_fightTurn;rules.AddBuff(enemy,2,ESBUFF_FengYin,3,&control,221);
    if(rules.GetStatePara1(enemy,ESBUFF_SpeedDes)!=2000)return false;
    rules.m_members[enemy-1].isWorldBoss=false;rules.m_members[enemy-1].buff_list.clear();
    rules.AddBuff(enemy,1,ESBUFF_ChenMo,4,&control,201);rules.AddBuff(enemy,2,ESBUFF_ChenMo,4,&control,202);rules.AddBuff(enemy,3,ESBUFF_ChenMo,4,&control,203);
    int controlCount=0;for(list<SFightBuffData>::const_iterator it=rules.m_members[enemy-1].buff_list.begin();it!=rules.m_members[enemy-1].buff_list.end();++it)
    {if(it->id==ESBUFF_ChenMo){++controlCount;if(it->srcPos==2 && it->leftTurn!=2)return false;}}
    if(controlCount!=2){std::cerr<<"FAIL shared repeat-control immunity"<<std::endl;return false;}
    rules.m_members[2].hp=0;rules.SetState(3,EFST_STATE_Die);int healing=-1000;
    rules.DecreaseHp(3,1,healing,absorbed);if(!rules.IsAlive(3))return false;
    rules.m_members[2].hp=0;rules.SetState(3,EFST_STATE_Die);healing=-1000;
    rules.DecreaseHp(3,1,healing,absorbed);if(rules.IsAlive(3))return false;
    healing=-1000;rules.DecreaseHp(3,2,healing,absorbed);if(!rules.IsAlive(3))return false;
    rules.m_members[2].hp=0;rules.SetState(3,EFST_STATE_Die);healing=-1000;
    rules.DecreaseHp(3,enemy,healing,absorbed);if(rules.IsAlive(3)){std::cerr<<"FAIL all-source revival cap"<<std::endl;return false;}
    SFightMember &attributes=rules.m_members[0];attributes.unitAttr.maxHpBase=10000;attributes.unitAttr.maxHp=10000;attributes.hp=10000;
    attributes.SetPassSkillLimitAttrData(234,ESkill_Pass_Attr,EAT_QiXueAdd,1000,1);
    attributes.SetPassSkillLimitAttrData(294,ESkill_Pass_Attr,EAT_BaoJiLv,500,1);
    if(attributes.unitAttr.maxHp!=11000){std::cerr<<"FAIL independent passive attributes"<<std::endl;return false;}
    attributes.SetPassSkillLimitAttrData(234,ESkill_Pass_Attr,EAT_QiXueAdd,2000,1);
    if(attributes.unitAttr.maxHp!=12000)return false;
    rules.m_curActionPos=1;attributes.buff_list.clear();vector<int> speed(1,1000);
    rules.AddBuff(1,1,ESBUFF_AddSpeed,2,&speed,621);rules.DecAllStateEffectTurn(1);
    if(attributes.buff_list.front().leftTurn!=2){std::cerr<<"FAIL newly applied buff duration"<<std::endl;return false;}
    ++rules.m_fightTurn;rules.DecAllStateEffectTurn(1);if(attributes.buff_list.front().leftTurn!=1)return false;
    std::cerr<<"CHECK casting fixture start"<<std::endl;
    CFight casting;
    for(int i=0;i<2;++i)
    {
        uint8 pos=i==0?1:enemy;SharePetPtr pet(new SPet);pet->id=i==0?14:10;SFightMember &u=casting.m_members[pos-1];
        u.memPtr=pet;u.type=EFMT_PET;u.level=1;u.hp=u.unitAttr.maxHp=10000;u.unitAttr.attack=1000;u.unitAttr.mingzhongLv=100000;
    }
    casting.m_members[0].heroBuildBranch=2;SSkillData attackSkill(141,1);attackSkill.CD=3;casting.m_members[0].skill_list.push_back(attackSkill);
    vector<int> barrier(2,5000);casting.AddBuff(enemy,enemy,ESBUFF_Shield,2,&barrier,121);
    std::cerr<<"CHECK casting shield hit"<<std::endl;
    if(!casting.SkillButtle(1,141) || casting.m_members[0].skill_list[0].leftCD!=2){std::cerr<<"FAIL cast preserves shield-hit cooldown reduction"<<std::endl;return false;}
    casting.m_members[0].skill_list.clear();SSkillData reviveSkill(102,1);reviveSkill.CD=6;casting.m_members[0].skill_list.push_back(reviveSkill);
    std::cerr<<"CHECK casting invalid revive"<<std::endl;
    if(casting.SkillButtle(1,102)!=0 || casting.m_members[0].skill_list[0].leftCD!=0){std::cerr<<"FAIL no-target cast cooldown rollback"<<std::endl;return false;}
    std::cerr<<"CHECK casting secondary kill"<<std::endl;
    casting.HeroBuildState(1,100104)=4;casting.m_members[enemy-1].buff_list.clear();casting.m_members[enemy-1].hp=100;
    casting.HeroBuildDamageAction(1,enemy,1000,514);
    if(casting.GetStatePara1(1,ESBUFF_DamagePercentAdd)!=600){std::cerr<<"FAIL secondary kill set growth"<<std::endl;return false;}
    vector<int> deadTaunt(1,enemy),otherTaunt(1,3);
    casting.AddBuff(1,enemy,ESBUFF_ChaoFeng,2,&deadTaunt,611);casting.AddBuff(1,enemy,ESBUFF_ChaoFeng,2,&otherTaunt,612);
    casting.ClearChaoFeng(enemy);
    if(casting.GetChaoFengTarget(1)!=3 || casting.GetStatePara1(1,ESBUFF_DamagePercentAdd)!=600){std::cerr<<"FAIL dead taunter cleanup preserves other buffs"<<std::endl;return false;}
    std::cerr<<"CHECK synthetic rounds begin"<<std::endl;
    // Synthetic stat fixtures exercise the complete round dispatcher. They
    // validate execution and invariants, not balance or player win rates.
    static const uint16 roster[59][5]={
        {10,101,102,103,104},
        {11,111,112,113,114},
        {12,121,122,123,124},
        {13,131,132,133,134},
        {14,141,142,143,144},
        {15,151,152,153,154},
        {16,161,162,163,164},
        {17,171,172,173,174},
        {18,181,182,183,184},
        {19,191,192,193,194},
        {20,201,202,203,204},
        {21,211,212,213,214},
        {22,221,222,223,224},
        {23,231,232,233,234},
        {24,241,242,243,244},
        {25,251,252,253,254},
        {26,261,262,263,264},
        {27,271,272,273,274},
        {28,281,282,283,284},
        {29,291,292,293,294},
        {30,301,302,303,304},
        {31,311,312,313,314},
        {32,321,322,323,324},
        {33,331,332,333,334},
        {34,341,342,343,344},
        {35,351,352,353,354},
        {36,122,361,363,364},
        {37,371,372,373,374},
        {38,381,382,383,384},
        {39,391,392,393,394},
        {40,401,402,403,404},
        {41,411,412,413,414},
        {42,421,422,423,424},
        {43,431,432,433,434},
        {44,441,442,443,444},
        {45,451,452,453,454},
        {46,461,462,463,464},
        {47,471,472,473,474},
        {48,481,482,483,484},
        {49,491,492,493,494},
        {50,501,502,503,504},
        {51,511,512,513,514},
        {52,521,522,523,524},
        {53,531,532,533,534},
        {54,541,542,543,544},
        {55,551,552,553,554},
        {56,561,562,563,564},
        {57,571,572,573,574},
        {58,581,582,583,584},
        {59,591,592,593,594},
        {60,601,602,603,604},
        {61,611,612,613,614},
        {62,621,622,623,624},
        {63,631,632,633,634},
        {64,641,642,643,644},
        {65,651,652,653,654},
        {66,661,662,663,664},
        {67,671,672,673,674},
        {68,681,682,683,684}
    };
    int rounds=0;
    for(int focus=0;focus<59;++focus)for(int branch=1;branch<=2;++branch)
    {
        CFight match;
        for(int slot=0;slot<6;++slot)
        {
            uint8 pos=slot<3?slot+1:enemy+slot-3;
            const uint16 *entry=roster[(focus+slot*11)%59];SharePetPtr pet(new SPet);pet->id=entry[0];
            SFightMember &u=match.m_members[pos-1];u.memPtr=pet;u.type=EFMT_PET;u.level=10;
            u.hp=u.unitAttr.maxHp=50000;u.unitAttr.attack=3000;u.unitAttr.wufang=u.unitAttr.fafang=400;
            u.unitAttr.speed=100+slot;u.unitAttr.baojiAdd=15000;u.unitAttr.fanjiAdd=u.unitAttr.lianjiAdd=10000;
            u.unitAttr.maxHpBase=50000;u.unitAttr.attackBase=3000;u.unitAttr.wufangBase=u.unitAttr.fafangBase=400;
            u.unitAttr.maxHpRatio=u.unitAttr.attackRatio=u.unitAttr.wufangRatio=u.unitAttr.fafangRatio=10000;
            pet->basicAttr=u.unitAttr;pet->hp=u.hp;pet->level=10;
            u.attackType=slot%2+1;pet->attackType=u.attackType;u.heroBuildBranch=branch;u.heroBuildStrategy=(focus+slot)%5+1;
            for(int skill=1;skill<=4;++skill)
            {
                SSkillCfgData *cfg=SingletonCSkillMgr::instance().GetSkillCfg(entry[skill]);if(!cfg)return false;
                SSkillData data(entry[skill],10);data.CD=cfg->CD;
                if(cfg->type==ESKILL_Passive)u.passive_skill.push_back(data);else u.skill_list.push_back(data);
            }
            match.HeroBuildState(pos,100000)=1201+(focus+slot)%14;
            match.HeroBuildState(pos,100101+(focus+slot)%10)=4;
        }
        match.AddTeamRage(1,80,false);match.AddTeamRage(enemy,80,false);
        for(int turn=0;turn<8 && match.OneGroupAllDie()==0;++turn)
        {
            std::cerr<<"ROUND hero="<<roster[focus][0]<<" branch="<<branch<<" turn="<<turn<<std::endl;
            CNetMessage round;match.CalculateFight(round);++rounds;
            for(int slot=0;slot<6;++slot)
            {
                uint8 pos=slot<3?slot+1:enemy+slot-3;SFightMember &u=match.m_members[pos-1];
                if(u.hp<0 || u.hp>match.GetMaxHp(pos) || match.GetTeamRage(pos)<0 || match.GetTeamRage(pos)>100)
                {std::cerr<<"FAIL round invariant hero="<<roster[focus][0]<<" branch="<<branch<<" turn="<<turn<<" pos="<<(int)pos<<" hp="<<u.hp<<" max="<<match.GetMaxHp(pos)<<" rage="<<match.GetTeamRage(pos)<<std::endl;return false;}
                int shields=0;for(list<SFightBuffData>::const_iterator it=u.buff_list.begin();it!=u.buff_list.end();++it)
                    if(match.IsShieldBuff(it->id) && !it->paraList.empty())shields+=it->paraList[0];
                if(shields>match.GetMaxHp(pos)/2){std::cerr<<"FAIL full-round shield cap"<<std::endl;return false;}
                for(size_t k=0;k<u.skill_list.size();++k)if(u.skill_list[k].leftCD<0)return false;
            }
        }
    }
    std::cout<<"PASS full-round smoke: 118 synthetic encounters covering all 59 heroes/A+B, five strategies, gear; rounds="<<rounds<<" (not a balance test)"<<std::endl;
    std::cout<<"PASS shared rules: rage per-person/team/round, crit multiplier, hit floor, DR and vulnerability caps, shield bypass, rescue priority, passive CD budget"<<std::endl;
    std::cout<<"PASS equipment V2: 70 artifact values/combined shield/shield-only damage/owned DOT budgets/cleanse and revive limits/team drum/survival cooldown/death aura maximum/share budget"<<std::endl;
    return true;
}
