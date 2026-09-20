#include "fight.h"
#include "protocol.h"
#include <algorithm>
#include "singleton.h"
#include <iostream>
#ifdef _MSC_VER
#include <crtdbg.h>
#include <cstdlib>
#include <dbghelp.h>
#pragma comment(lib,"dbghelp.lib")
static int __cdecl HeroBuildAssertTrace(int,char*,int*)
{
    HANDLE process=GetCurrentProcess();SymSetOptions(SYMOPT_LOAD_LINES|SYMOPT_UNDNAME);SymInitialize(process,NULL,TRUE);
    void *frames[24];USHORT count=CaptureStackBackTrace(0,24,frames,NULL);
    char storage[sizeof(SYMBOL_INFO)+512]={0};SYMBOL_INFO *symbol=reinterpret_cast<SYMBOL_INFO*>(storage);symbol->SizeOfStruct=sizeof(SYMBOL_INFO);symbol->MaxNameLen=511;
    for(USHORT i=0;i<count;++i){DWORD64 address=(DWORD64)frames[i],offset=0;DWORD lineOffset=0;IMAGEHLP_LINE64 line={0};line.SizeOfStruct=sizeof(line);
        if(SymFromAddr(process,address,&offset,symbol))std::cerr<<"STACK "<<symbol->Name;
        if(SymGetLineFromAddr64(process,address,&lineOffset,&line))std::cerr<<" "<<line.FileName<<":"<<line.LineNumber;
        std::cerr<<std::endl;
    }
    SymCleanup(process);return FALSE;
}
#endif

bool CFight::IsHeroBuild(uint8 pos,uint16 hero,uint8 branch)
{
    SFightMember *member = GetFightMember(pos);
    return member != NULL && member->heroBuildBranch == branch && GetHeroId(pos) == hero;
}

bool CFight::HeroBuildBoss(uint8 pos)
{
    SFightMember *member=GetFightMember(pos);if(!member)return false;
    SMonsterInst *monster=GetMonster(pos);
    return member->isWorldBoss || (monster && monster->type==EMTTongLing);
}

// Secondary branch healing has its own protocol action; it must not re-enter
// primary-heal passives, overheal conversion or resource generation.
void CFight::HeroBuildHpAction(uint8 src,uint8 target,int healing,uint16 skillId)
{
    if (healing <= 0 || !IsAlive(target)) return;
    if (HaveBuff(target,ESBUFF_JinLiaoShu))
        healing = (int)((int64)healing * std::max(0,10000-GetStatePara1(target,ESBUFF_JinLiaoShu))/10000);
    int before = (int)GetHp(target), absorption = 0;
    int delta = -healing;
    DecreaseHp(target,src,delta,absorption,true);
    int actual = (int)GetHp(target) - before;
    if (actual <= 0) return;
    m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
    m_extActionMsg << (uint8)EFOT_Passive << src << skillId << string("") << (uint8)1;
    m_extActionMsg << target << actual << (int)0 << (int)0;
    MakeBuffList(target,m_extActionMsg);
}

void CFight::HeroBuildAfterHeal(uint8 src,uint8 target,uint16 skillId,int beforeHp,int overheal,bool wasAlive)
{
    SFightMember *member = GetFightMember(src);
    int reservedOverheal=0;
    if(IsAlive(target) && (!wasAlive || GetHp(target)>beforeHp))HeroBuildEquipmentHeal(src,target,!wasAlive);
    if(!wasAlive && IsHeroBuild(src,35,2) && skillId==352 && IsAlive(target))
        GetFightMember(target)->heroBuildRevivedTurn=m_fightTurn;
    if(wasAlive && GetHeroId(src)==31 && member!=NULL && member->heroBuildBranch!=0)
    {
        int effective=std::max(0,(int)GetHp(target)-beforeHp);
        if(member->heroBuildBranch==1 && effective>0)
        {
            HeroBuildState(target,31401)=m_fightTurn+2;
            if(skillId==311 && (int64)beforeHp*100<GetMaxHp(target)*35)
            {vector<int> guard(1,1200);AddBuff(target,src,ESBUFF_MianShangTemp,1,&guard,311);}
            if(skillId==312)
            {
                uint8 allies[GROUP_MEMBER],count=0;GetMeGroupExceptSelf(src,allies,count);
                GetSkillTargetSelCondition(allies,count,ESkill_Select_MinCurHp);
                if(count>0)HeroBuildHpAction(src,allies[0],effective*30/100,312);
            }
        }
        if(overheal>0)
        {
            uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(src,allies,count);
            vector<uint8> recipients;
            GetSkillTargetSelCondition(allies,count,ESkill_Select_MinCurHp);
            for(uint8 i=0;i<count;++i)if(allies[i]!=target && IsAlive(allies[i]))recipients.push_back(allies[i]);
            if(member->heroBuildBranch==1 && recipients.size()>2)recipients.resize(2);
            reservedOverheal=overheal*(member->heroBuildBranch==1?30:60)/100;
            if(!recipients.empty())
            {
                int perTarget=reservedOverheal/(int)recipients.size();
                if(member->heroBuildBranch==2)perTarget=std::min(perTarget,(effective+overheal)/4);
                for(size_t i=0;i<recipients.size();++i)HeroBuildHpAction(src,recipients[i],perTarget,313);
            }
        }
    }
    // Merge conversions from the same primary heal before refreshing its
    // shield. Separate AddBuff calls would replace one another.
    if (wasAlive && overheal > 0)
    {
        int64 shieldBudget = 0;
        if (skillId == 101 && IsHeroBuild(src,10,1))
            shieldBudget = std::min<int64>((int64)overheal*2000,GetMaxHp(target)*1500);
        if (TryTriggerAffix(src,5))
        {
            int64 equipmentShield = (int64)overheal*GetAffixValue(src,5,1);
            int64 cap = GetMaxHp(target)*GetAffixValue(src,5,2);
            if (cap > 0) equipmentShield = std::min(equipmentShield,cap);
            shieldBudget += std::min(equipmentShield,(int64)(overheal-reservedOverheal)*10000-shieldBudget);
        }
        AddAffixShield(src,target,(int)(shieldBudget/10000),2,0);
    }
    if (member == NULL || GetHeroId(src) != 10 || member->heroBuildBranch == 0) return;
    if (!wasAlive && IsAlive(target) && skillId == 102)
    {
        member->heroBuildRevivedTargets[target-1] = true;
        GetFightMember(target)->heroBuildRevivedTurn = m_fightTurn;
        if (member->heroBuildBranch == 1)
        {
            vector<int> guard(1,2000);
            AddBuff(target,src,ESBUFF_MianShangTemp,1,&guard);
        }
        return;
    }
    if (!wasAlive || skillId != 101) return;
    if (member->heroBuildBranch == 2 && GetHp(target) > beforeHp)
    {
        if (member->heroBuildHealCdTurn != m_fightTurn)
        {
            member->heroBuildHealCdTurn = m_fightTurn;
            member->DecSkillCD(102,1);
        }
        if (member->heroBuildHealRageTurn != m_fightTurn)
        {
            member->heroBuildHealRageTurn = m_fightTurn;
            member->heroBuildHealRage = 0;
        }
        if ((int64)beforeHp*2 < GetMaxHp(target) && member->heroBuildHealRage < 9)
        {
            member->heroBuildHealRage += 3;
            AddTeamRage(src,3);
        }
    }
}

bool CFight::RunHeroBuildRegression()
{
#ifdef _MSC_VER
    _CrtSetReportHook(HeroBuildAssertTrace);
    _CrtSetReportMode(_CRT_ASSERT,_CRTDBG_MODE_FILE);_CrtSetReportFile(_CRT_ASSERT,_CRTDBG_FILE_STDERR);
    _CrtSetReportMode(_CRT_ERROR,_CRTDBG_MODE_FILE);_CrtSetReportFile(_CRT_ERROR,_CRTDBG_FILE_STDERR);
    _set_abort_behavior(0,_WRITE_ABORT_MSG|_CALL_REPORTFAULT);
#endif
    if (!SingletonCSkillMgr::instance().Init())
    {
        std::cerr << "FAIL hero build: skill config initialization" << std::endl;
        return false;
    }
    if (!sCItemCfgManager.InitEquipAffixCfg()) return false;
    CFight fight;
    for (uint8 pos=1;pos<=2;++pos)
    {
        SharePetPtr pet(new SPet);
        pet->id = pos == 1 ? 10 : 23;
        SFightMember &member = fight.m_members[pos-1];
        member.memPtr = pet;
        member.type = EFMT_PET;
        member.unitAttr.maxHp = 10000;
        member.unitAttr.attack = 10000;
        member.hp = 1000;
        member.level = 1;
    }
    SFightMember &nuwa = fight.m_members[0];
    nuwa.heroBuildBranch = 2;
    SSkillData revive(102,1); revive.leftCD=6; revive.CD=6;
    nuwa.skill_list.push_back(revive);
    // Exercise the production post-heal event, not a duplicate policy formula.
    fight.m_members[1].hp=4000;
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    if (fight.GetTeamRage(1)!=3 || nuwa.skill_list[0].leftCD!=5) return false;
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    if (fight.GetTeamRage(1)!=9 || nuwa.skill_list[0].leftCD!=5) return false;
    fight.m_fightTurn++;
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    if (fight.GetTeamRage(1)!=12 || nuwa.skill_list[0].leftCD!=4) return false;
    // A full-health target did not receive effective healing: no CD/rage.
    fight.m_fightTurn++;
    fight.HeroBuildAfterHeal(1,2,101,4000,6000,true);
    if (fight.GetTeamRage(1)!=12 || nuwa.skill_list[0].leftCD!=4) return false;
    nuwa.heroBuildBranch=1;
    fight.HeroBuildAfterHeal(1,2,101,4000,10000,true);
    if (fight.GetStatePara1(2,ESBUFF_Shield)!=1500) return false;
    fight.HeroBuildAfterHeal(1,2,101,4000,10000,true);
    int sameSourceShields=0;
    for (list<SFightBuffData>::const_iterator it=fight.m_members[1].buff_list.begin();it!=fight.m_members[1].buff_list.end();++it)
        if(it->id==ESBUFF_Shield && it->srcPos==1) ++sameSourceShields;
    if(sameSourceShields!=1) return false;
    vector<int> largeShield(2,9000);
    fight.AddBuff(2,2,ESBUFF_Shield,2,&largeShield);
    int totalShield=0;
    for (list<SFightBuffData>::const_iterator it=fight.m_members[1].buff_list.begin();it!=fight.m_members[1].buff_list.end();++it)
        if(fight.IsShieldBuff(it->id) && !it->paraList.empty()) totalShield+=it->paraList[0];
    if(totalShield!=5000) return false;
    fight.m_members[1].buff_list.clear();
    nuwa.passive_skill.push_back(SSkillData(5005,3));
    fight.HeroBuildAfterHeal(1,2,101,4000,5000,true);
    if(fight.GetStatePara1(2,ESBUFF_Shield)!=2500)
    {
        std::cerr << "FAIL Nuwa A + HEAL-01 must merge 1000+1500 shield" << std::endl;
        return false;
    }
    nuwa.passive_skill.pop_back();
    nuwa.passive_skill.push_back(SSkillData(5005,3));
    nuwa.affixTurnCount[5]=0;
    fight.HeroBuildAfterHeal(1,2,101,4000,4803,true);
    if(fight.GetStatePara1(2,ESBUFF_Shield)!=2401)return false;
    nuwa.passive_skill.pop_back();
    fight.HeroBuildAfterHeal(1,2,102,0,0,false);
    if (!nuwa.heroBuildRevivedTargets[1] || fight.m_members[1].heroBuildRevivedTurn!=fight.m_fightTurn) return false;
    if (fight.GetStatePara1(2,ESBUFF_MianShangTemp)!=2000) return false;
    // Distinct heroes sharing mechanics cannot inherit Nuwa branch hooks.
    boost::any_cast<SharePetPtr>(nuwa.memPtr)->id=23;
    nuwa.heroBuildBranch=2;
    fight.m_fightTurn++;
    fight.HeroBuildAfterHeal(1,2,101,1000,0,true);
    if (fight.GetTeamRage(1)!=12) return false;
    boost::any_cast<SharePetPtr>(nuwa.memPtr)->id=10;
    nuwa.heroBuildBranch=1;
    nuwa.passive_skill.push_back(SSkillData(103,1));
    nuwa.unitAttr.baojiLv=-10000;
    for(uint8 pos=1;pos<=2;++pos)
    {
        fight.m_members[pos-1].buff_list.clear();
        fight.m_members[pos-1].hp=1000;
    }
    fight.CalculateSkill_AddHp(1,101,1);
    if(fight.GetHp(2)!=7885)
    {
        std::cerr << "FAIL Nuwa A primary heal expected 7885 hp, actual " << fight.GetHp(2) << std::endl;
        return false;
    }
    fight.m_members[1].hp=1000;
    vector<int> healReduction(2,0);healReduction[0]=5000;
    fight.AddBuff(2,2,ESBUFF_JinLiaoShu,2,&healReduction);
    fight.CalculateSkill_AddHp(1,101,1);
    if(fight.GetHp(2)!=4442){std::cerr<<"FAIL noncritical primary healing must obey antiheal"<<std::endl;return false;}
    fight.m_members[1].buff_list.clear();
    fight.m_members[1].hp=0;
    fight.SetState(2,EFST_STATE_Die);
    nuwa.heroBuildRevivedTargets[1]=false;
    fight.HeroBuildState(2,200070)=0;fight.HeroBuildState(2,260001)=0;
    fight.CalculateSkill_AddHp(1,102,10);
    if(fight.GetHp(2)!=2500)
    {
        std::cerr << "FAIL Nuwa A revive must replace level growth: " << fight.GetHp(2) << std::endl;
        return false;
    }
    nuwa.heroBuildBranch=2;
    nuwa.heroBuildRevivedTargets[1]=false;
    fight.HeroBuildState(2,200070)=0;fight.HeroBuildState(2,260001)=0;
    fight.m_members[1].hp=0;
    fight.SetState(2,EFST_STATE_Die);
    int rageBefore=fight.GetTeamRage(1);
    fight.CalculateSkill_AddHp(1,102,10);
    if(fight.GetHp(2)!=4000 || fight.GetTeamRage(1)!=rageBefore+12)
    {
        std::cerr << "FAIL Nuwa B revive/refund" << std::endl;
        return false;
    }
    nuwa.hp=10000; fight.m_members[1].hp=9300;
    if(fight.IsRoleSkillUseful(1,101))return false;
    fight.m_members[1].hp=5000;
    if(!fight.IsRoleSkillUseful(1,101))return false;
    SSkillAdditiveEffect *selfRevive=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(104);
    if(selfRevive==NULL)return false;
    int originalChance=selfRevive->para[0];
    // Deterministically exercise successful revival; chance is not a branch
    // override in production, and the original config is restored below.
    selfRevive->para[0]=10000;
    nuwa.passive_skill.push_back(SSkillData(104,1));
    for(int branch=1;branch<=2;++branch)
    {
        nuwa.heroBuildBranch=(uint8)branch;nuwa.heroBuildSelfRevived=false;
        nuwa.hp=0;fight.SetState(1,EFST_STATE_Die);
        fight.m_dieList.clear();fight.AddDieUnit(1);
        fight.m_members[1].hp=1000;
        nuwa.skill_list[0].leftCD=4;
        CNetMessage output;
        fight.DiePassiveAcion(output);
        int expectedSelf=branch==1?6500:3500;
        int expectedAlly=branch==1?6000:1000;
        if(fight.GetHp(1)!=expectedSelf || fight.GetHp(2)!=expectedAlly || !nuwa.heroBuildSelfRevived
            || nuwa.heroBuildRevivedTurn!=fight.m_fightTurn || nuwa.skill_list[0].leftCD!=4)
        {
            std::cerr << "FAIL Nuwa self revival branch " << branch << ": " << fight.GetHp(1) << '/' << fight.GetHp(2) << std::endl;
            selfRevive->para[0]=originalChance;
            return false;
        }
        nuwa.hp=0;fight.SetState(1,EFST_STATE_Die);
        fight.m_dieList.clear();fight.AddDieUnit(1);
        fight.DiePassiveAcion(output);
        if(fight.IsAlive(1)) { selfRevive->para[0]=originalChance; return false; }
    }
    selfRevive->para[0]=originalChance;
    bool jieyinPassed = []() -> bool
    {
        CFight battle;
        for(uint8 pos=1;pos<=2;++pos)
        {
            SharePetPtr pet(new SPet);pet->id=pos==1?11:23;
            SFightMember &unit=battle.m_members[pos-1];
            unit.type=EFMT_PET;unit.memPtr=pet;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.level=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;
        caster.passive_skill.push_back(SSkillData(113,1));
        vector<int> mark;mark.push_back(2000);mark.push_back(1000);
        battle.AddBuff(2,1,ESBUFF_JinGuZhou,4,&mark);
        if(battle.HeroBuildDotDamage(1,2,ESBUFF_JinGuZhou,1000)!=1230)return false;
        battle.HeroBuildAfterHit(1,2,112);
        if(battle.GetHp(2)!=9262)return false;
        vector<int> antiheal;antiheal.push_back(5000);antiheal.push_back(20000);
        battle.AddBuff(2,1,ESBUFF_JinLiaoShu,3,&antiheal);
        SSkillAdditiveEffect *effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(113);
        int chance=effect->para[0];effect->para[0]=10000;
        bool ok=battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100)==240
            && battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100)==240
            && battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100)==0;
        battle.m_fightTurn++;
        ok=ok && battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100)==240;
        caster.heroBuildBranch=2;
        battle.HeroBuildDebuffApplied(1,2,112,ESBUFF_JinLiaoShu);
        ok=ok && battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100)==200
            && battle.GetStatePara1(2,ESBUFF_SpeedDes)==1000;
        int expiry=0;
        for(list<SFightBuffData>::const_iterator it=battle.m_members[1].buff_list.begin();it!=battle.m_members[1].buff_list.end();++it)
            if(it->id==ESBUFF_JinLiaoShu)expiry=it->leftTurn;
        ok=ok && expiry==4;
        battle.HeroBuildDotDamage(1,2,ESBUFF_JinLiaoShu,100);
        for(list<SFightBuffData>::const_iterator it=battle.m_members[1].buff_list.begin();it!=battle.m_members[1].buff_list.end();++it)
            if(it->id==ESBUFF_JinLiaoShu)ok=ok && it->leftTurn==4;
        effect->para[0]=chance;
        battle.HeroBuildDebuffResisted(1,ESBUFF_JinLiaoShu);
        battle.HeroBuildDebuffResisted(1,ESBUFF_JinLiaoShu);
        ok=ok && battle.GetTeamRage(1)==5;
        battle.m_fightTurn++;
        battle.HeroBuildDebuffResisted(1,ESBUFF_JinLiaoShu);
        ok=ok && battle.GetTeamRage(1)==10;
        battle.HeroBuildAfterHit(1,2,111);
        ok=ok && battle.GetStatePara1(2,ESBUFF_JinLiaoShu)==5000;
        return ok;
    }();
    if(!jieyinPassed)
    {
        std::cerr<<"FAIL Jieyin: DOT burst/counter limits/extension/slow/refund/strong antiheal preservation"<<std::endl;
        return false;
    }
    bool zhuntiPassed=[]()->bool
    {
        CFight battle;
        const uint8 enemy=GROUP2_BEGIN+1;
        const uint8 positions[]={1,2,enemy};
        for(int i=0;i<3;++i)
        {
            SharePetPtr pet(new SPet);pet->id=i==0?12:23;
            SFightMember &unit=battle.m_members[positions[i]-1];
            unit.type=EFMT_PET;unit.memPtr=pet;unit.hp=unit.unitAttr.maxHp=10000;
            unit.unitAttr.attack=1000;unit.level=1;
        }
        SFightMember &caster=battle.m_members[0];caster.heroBuildBranch=1;
        vector<int> personal(2,2000);personal.push_back(2500);
        battle.AddBuff(1,1,ESBUFF_ShieldMianShang,2,&personal,121);
        if(battle.GetStatePara1(1,ESBUFF_ShieldMianShang)!=2740 || battle.GetStatePara3(1,ESBUFF_ShieldMianShang)!=3300)return false;
        vector<int> group(2,2500);
        battle.AddBuff(2,1,ESBUFF_Shield,2,&group,122);
        if(battle.GetStatePara1(2,ESBUFF_Shield)!=3300 || battle.m_members[1].buff_list.back().leftTurn!=3)return false;
        battle.m_members[1].hp=5000;
        battle.DecAllStateEffectTurn(2);battle.DecAllStateEffectTurn(2);battle.DecAllStateEffectTurn(2);
        if(battle.GetHp(2)!=5250 || battle.GetHp(enemy)!=10000)return false;
        battle.AddBuff(2,1,ESBUFF_Shield,1,&group,0);
        battle.DecAllStateEffectTurn(2);
        if(battle.GetHp(2)!=5250)return false;
        caster.heroBuildBranch=2;
        battle.m_members[0].buff_list.clear();battle.m_members[1].buff_list.clear();
        group.assign(2,1000);
        battle.AddBuff(2,1,ESBUFF_Shield,2,&group,122);
        if(battle.GetStatePara1(2,ESBUFF_Shield)!=800)return false;
        int damage=1000,absorbed=0;
        battle.ShieldAbsorptionDamage(2,damage,absorbed);
        battle.ShieldBrokenCheck(2,enemy);
        if(absorbed!=800 || battle.GetHp(enemy)!=9576 || caster.heroBuildShieldExplosions!=1)return false;
        if(battle.GetStatePara1(2,ESBUFF_Shield)!=63)return false;
        // Converted shield expiry has no explosion or conversion feedback.
        battle.DecAllStateEffectTurn(2);battle.DecAllStateEffectTurn(2);
        if(battle.GetHp(enemy)!=9576)return false;
        battle.AddBuff(2,1,ESBUFF_Shield,1,&group,122);
        battle.DecAllStateEffectTurn(2);
        if(battle.GetHp(enemy)!=9436 || caster.heroBuildShieldExplosions!=2)return false;
        battle.AddBuff(2,1,ESBUFF_Shield,1,&group,122);
        battle.DecAllStateEffectTurn(2);
        if(battle.GetHp(enemy)!=9436)return false;
        // A different hero using the shared 122 must retain its base shield.
        boost::any_cast<SharePetPtr>(caster.memPtr)->id=53;
        battle.m_members[1].buff_list.clear();
        battle.AddBuff(2,1,ESBUFF_Shield,2,&group,122);
        return battle.GetStatePara1(2,ESBUFF_Shield)==1000;
    }();
    if(!zhuntiPassed){std::cerr<<"FAIL Zhunti shield branches"<<std::endl;return false;}
    if(!RunHeroBuildControlRegression()){std::cerr<<"FAIL Kongxuan control branches"<<std::endl;return false;}
    if(!RunHeroBuildBurstRegression()){std::cerr<<"FAIL Duobao burst branches"<<std::endl;return false;}
    if(!RunHeroBuildEquipmentRegression()){std::cerr<<"FAIL equipment V2 regression"<<std::endl;return false;}
    std::cout << "PASS Nuwa A/B: primary heal, fixed revive HP/refund, self-revive HP/party heal/once-per-battle/CD, AI thresholds, round limits, shield refresh/cap, hero isolation" << std::endl;
    std::cout << "PASS Jieyin A/B: DOT burst/counter limits/extension/slow/refund/strong antiheal preservation" << std::endl;
    std::cout << "PASS Zhunti A/B: shield amount/guard/duration/heal replacement/break vs expiry/counter caps/conversion isolation/shared skill isolation" << std::endl;
    return true;
}

int CFight::HeroBuildDotDamage(uint8 src,uint8 target,uint16 buffId,int damage)
{
    SFightMember *member=GetFightMember(src);
    if(member==NULL || GetHeroId(src)!=11 || member->heroBuildBranch==0)
        return buffId==ESBUFF_JinLiaoShu ? (int)((int64)damage*GetStatePara2(target,buffId)/10000) : damage;
    if(buffId==ESBUFF_JinGuZhou && member->heroBuildBranch==1)
    {
        int marked=0;
        for(uint8 pos=1;pos<=MAX_MEMBER;++pos)
            if(IsAlive(pos) && HaveBuff(pos,ESBUFF_JinGuZhou) && GetStateSrcPos(pos,ESBUFF_JinGuZhou)==src) ++marked;
        return (int)((int64)damage*(11800+std::min(marked,4)*500)/10000);
    }
    if(buffId!=ESBUFF_JinLiaoShu || damage<=0) return damage;
    int index=target-1;
    if(member->heroBuildBranch==2 && !member->heroBuildAntihealSlowed[index]
        && m_fightTurn-member->heroBuildAntihealApplied[index]<2)
    {
        member->heroBuildAntihealSlowed[index]=true;
        vector<int> slow(1,1000);
        AddBuff(target,src,ESBUFF_SpeedDes,1,&slow);
    }
    int level=0;
    for(size_t i=0;i<member->passive_skill.size();++i)
        if(member->passive_skill[i].id==113)level=member->passive_skill[i].level;
    SSkillAdditiveEffect *effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(113);
    if(level==0 || effect==NULL || Random(1,10000)>effect->para[0]+(level-1)*effect->para_levelAdd[0])return 0;
    damage=(int)((int64)damage*(effect->para[1]+(level-1)*effect->para_levelAdd[1])/10000);
    if(member->heroBuildCounterTurn[index]!=m_fightTurn)
    {
        member->heroBuildCounterTurn[index]=m_fightTurn;
        member->heroBuildCounterCount[index]=0;
    }
    if(member->heroBuildBranch==1)
    {
        if(member->heroBuildCounterCount[index]>=2)return 0;
        ++member->heroBuildCounterCount[index];
        return (int)((int64)damage*120/100);
    }
    if(m_fightTurn-member->heroBuildExtendTurn[index]>=2)
    {
        member->heroBuildExtendTurn[index]=m_fightTurn;
        SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
            if(it->id==ESBUFF_JinLiaoShu && it->srcPos==src && it->leftTurn>0)
                it->leftTurn=std::min<int>(5,it->leftTurn+1);
    }
    return damage;
}

void CFight::HeroBuildDebuffApplied(uint8 src,uint8 target,uint16 skillId,uint16 buffId)
{
    if(IsHeroBuild(src,63,1) && skillId==634 && GetStateSrcPos(target,buffId)==src)HeroBuildState(src,63400)=m_fightTurn+1;
    if(IsHeroBuild(src,60,1) && skillId==601 && buffId==ESBUFF_ShiDu)
    {
        int stacks=0;SFightMember *victim=GetFightMember(target);vector<int> poison;uint8 duration=0;
        for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
        {
            if(it->id==ESBUFF_ShiDu || it->id==ESBUFF_FuDu || it->id==ESBUFF_ShiXinDu)++stacks;
            if(it->id==ESBUFF_ShiDu && it->srcPos==src){poison=it->paraList;duration=it->leftTurn;}
        }
        if(stacks>=3 && !poison.empty())
        {
            uint8 enemies[GROUP_MEMBER],count=0;GetAnotherGroup(src,enemies,count);
            for(uint8 i=0;i<count;++i)if(!HaveZhongDuState(enemies[i]) && !GetFightMember(enemies[i])->InNotEffectBuff(ESBUFF_ShiDu))
            {AddBuff(enemies[i],src,ESBUFF_ShiDu,duration,&poison,601);break;}
        }
    }
    if(IsHeroBuild(src,60,1) && skillId==602 && buffId==ESBUFF_GetDamageAdd && GetStateSrcPos(target,buffId)==src)
    {
        uint8 enemies[GROUP_MEMBER],count=0;GetAnotherGroup(src,enemies,count);vector<int> vulnerable(1,2000);
        for(uint8 i=0;i<count;++i)if(enemies[i]!=target && (enemies[i]-1)%GROUP_POS_STEP/3==(target-1)%GROUP_POS_STEP/3
            && !GetFightMember(enemies[i])->InNotEffectBuff(ESBUFF_GetDamageAdd))AddBuff(enemies[i],src,ESBUFF_GetDamageAdd,2,&vulnerable,602);
    }
    if(IsHeroBuild(src,46,1) && skillId==462 && GetStateSrcPos(target,buffId)==src)HeroBuildState(src,46200+target)=1;
    if(IsHeroBuild(src,34,1) && skillId==341 && buffId==ESBUFF_ChaoFeng && GetStateSrcPos(target,buffId)==src && HeroBuildState(src,34101)<4)
    {++HeroBuildState(src,34101);HeroBuildHpAction(src,src,(int)(GetMaxHp(src)*3/100),341);}
    if(IsHeroBuild(src,33,2) && skillId==333 && buffId==ESBUFF_MeiHuo && GetStateSrcPos(target,buffId)==src)
        HeroBuildState(src,33300)=m_fightTurn+1;
    if(IsHeroBuild(src,30,2) && skillId==302 && buffId==ESBUFF_DamagePercentDes && GetStateSrcPos(target,buffId)==src)
    {
        uint8 allies[GROUP_MEMBER],count=0;GetMeGroup(src,allies,count);vector<int> guard(1,500);
        for(uint8 i=0;i<count;++i)AddBuff(allies[i],src,ESBUFF_JianShangLvAdd,1,&guard,302);
    }
    if(IsHeroBuild(src,16,2) && skillId==162 && GetStateSrcPos(target,buffId)==src)
        HeroBuildState(src,163)=std::min(3,HeroBuildState(src,163)+1);
    if(IsHeroBuild(src,13,1) && skillId==132 && buffId==ESBUFF_GetDamageAdd)
    {
        vector<int> slow(1,800);
        if(!GetFightMember(target)->InNotEffectBuff(ESBUFF_SpeedDes))AddBuff(target,src,ESBUFF_SpeedDes,2,&slow,132);
    }
    if(!IsHeroBuild(src,11,2) || buffId!=ESBUFF_JinLiaoShu || skillId!=112)return;
    SFightMember *member=GetFightMember(src);
    member->heroBuildAntihealApplied[target-1]=m_fightTurn;
    member->heroBuildAntihealSlowed[target-1]=false;
}

void CFight::HeroBuildDebuffResisted(uint8 src,uint16 buffId)
{
    if(!IsHeroBuild(src,11,2) || buffId!=ESBUFF_JinLiaoShu)return;
    SFightMember *member=GetFightMember(src);
    if(member->heroBuildResistRefundTurn==m_fightTurn)return;
    member->heroBuildResistRefundTurn=m_fightTurn;
    AddTeamRage(src,5);
}

void CFight::HeroBuildDamageAction(uint8 src,uint8 target,int damage,uint16 skillId)
{
    if(damage<=0 || !IsAlive(target))return;
    bool previousSecondary=m_heroBuildSecondaryDamage;
    m_heroBuildSecondaryDamage=true;
    int before=(int)GetHp(target),absorbed=0,revived=0;
    DecreaseHp(target,src,damage,absorbed,false,&revived,false);
    m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
    m_extActionMsg<<(uint8)EFOT_Passive<<src<<skillId<<string("")<<(uint8)1;
    m_extActionMsg<<target<<(int)(GetHp(target)-before)<<absorbed<<revived;
    MakeBuffList(target,m_extActionMsg);
    ShieldBrokenCheck(target,src);
    m_heroBuildSecondaryDamage=previousSecondary;
}

bool CFight::HeroBuildShieldLost(uint8 target,uint8 attacker,const SFightBuffData &shield,bool expired)
{
    uint8 src=shield.srcPos;
    if(IsHeroBuild(src,34,2) && shield.originSkill==342)
    {if(!expired && IsAlive(target))HeroBuildHpAction(src,target,(int)(GetMaxHp(target)*8/100),342);return true;}
    if(!IsHeroBuild(src,12,1) && !IsHeroBuild(src,12,2))return false;
    // Conversion shields and shields broken by secondary damage cannot start
    // a new explosion chain. Refreshes never enter this function.
    if(m_heroBuildSecondaryDamage || shield.originSkill==124 || !IsAlive(src))return true;
    SFightMember *member=GetFightMember(src);
    if(member->heroBuildBranch==1)
    {
        if(member->heroBuildShieldHealTurn[target-1]!=m_fightTurn)
        {
            member->heroBuildShieldHealTurn[target-1]=m_fightTurn;
            HeroBuildHpAction(src,target,(int)((GetMaxHp(target)-GetHp(target))*5/100),123);
        }
        return true;
    }
    if(shield.paraList.size()<2)return true;
    if(member->heroBuildShieldTurn!=m_fightTurn)
    {
        member->heroBuildShieldTurn=m_fightTurn;
        member->heroBuildShieldExplosions=member->heroBuildShieldConverted=0;
    }
    int basis=expired ? shield.paraList[0]/2 : std::max(0,shield.paraList[1]-shield.paraList[0]);
    if(basis<=0)return true;
    int64 actual=0;
    if(!expired && shield.originSkill==121 && IsAlive(attacker))
    {
        int64 before=GetHp(attacker);
        HeroBuildDamageAction(src,attacker,(int)((int64)basis*30/100),121);
        actual+=std::max<int64>(0,before-GetHp(attacker));
    }
    int coefficient=(!expired && shield.originSkill==122)?1800:0;
    if(member->heroBuildShieldExplosions<2)
    {
        ++member->heroBuildShieldExplosions;
        coefficient+=3500;
    }
    uint8 enemies[GROUP_MEMBER],count=0;
    GetAnotherGroup(src,enemies,count);
    for(uint8 i=0;i<count;++i)
    {
        int64 before=GetHp(enemies[i]);
        HeroBuildDamageAction(src,enemies[i],(int)((int64)basis*coefficient/10000),123);
        actual+=std::max<int64>(0,before-GetHp(enemies[i]));
    }
    int cap=(int)(GetMaxHp(src)*12/100);
    int converted=(int)std::min<int64>(actual*15/100,std::max(0,cap-member->heroBuildShieldConverted));
    uint8 allies[GROUP_MEMBER],allyCount=0,lowest=0;
    GetMeGroup(src,allies,allyCount);
    for(uint8 i=0;i<allyCount;++i)
        if(IsAlive(allies[i]) && (lowest==0 || GetHp(allies[i])*GetMaxHp(lowest)<GetHp(lowest)*GetMaxHp(allies[i])))lowest=allies[i];
    if(converted>0 && lowest>0)
    {
        member->heroBuildShieldConverted+=converted;
        vector<int> parameters(2,converted);
        AddBuff(lowest,src,ESBUFF_Shield,2,&parameters,124);
        m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
        m_extActionMsg<<(uint8)EFOT_Passive<<src<<(uint16)124<<string("")<<(uint8)1;
        m_extActionMsg<<lowest<<(int)0<<(int)0<<(int)0;
        MakeBuffList(lowest,m_extActionMsg);
    }
    return true;
}

void CFight::HeroBuildAfterHit(uint8 src,uint8 target,uint16 skillId)
{
    if(IsHeroBuild(src,49,2) && skillId==492 && HeroBuildState(src,49200)==0)
    {
        SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
            if(it->id==ESBUFF_ZhuoShao && it->srcPos==src && !it->paraList.empty())
            {
                int damage=(int)std::min<int64>((int64)it->paraList[0]*it->leftTurn*60/100,(int64)GetUnitAttack(src)*150/100);
                victim->buff_list.erase(it);if(!HaveBuff(target,ESBUFF_ZhuoShao))SpecialBuffPassAttr(target,ESBUFF_ZhuoShao,false);
                HeroBuildState(src,49200)=1;HeroBuildDamageAction(src,target,damage,492);break;
            }
    }
    if(IsHeroBuild(src,32,2) && skillId==322 && HeroBuildState(src,32200+target)!=m_fightTurn+1)
    {
        int64 total=0;SFightMember *victim=GetFightMember(target);
        for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
            if(it->id==ESBUFF_ZhuoShao && !it->paraList.empty())total+=(int64)it->paraList[0]*it->leftTurn;
        if(total>0){HeroBuildState(src,32200+target)=m_fightTurn+1;HeroBuildDamageAction(src,target,(int)(total*30/100),322);}
    }
    if(skillId==112 && IsHeroBuild(src,11,1) && HaveBuff(target,ESBUFF_JinGuZhou))
    {
        uint8 origin=GetStateSrcPos(target,ESBUFF_JinGuZhou);
        int damage=HeroBuildDotDamage(origin,target,ESBUFF_JinGuZhou,GetStatePara2(target,ESBUFF_JinGuZhou));
        HeroBuildDamageAction(src,target,(int)((int64)damage*60/100),112);
    }
    if(skillId==111 && IsHeroBuild(src,11,2) && IsAlive(target))
    {
        // A stronger existing antiheal keeps its owner and magnitude.
        if(HaveBuff(target,ESBUFF_JinLiaoShu) && GetStatePara1(target,ESBUFF_JinLiaoShu)>=2000)return;
        SFightMember *victim=GetFightMember(target);
        if(victim->InNotEffectBuff(ESBUFF_JinLiaoShu))return;
        vector<SAttrData> attributes;
        vector<ESkillTriggerType> triggers(1,ESkill_Trigger_AddHpJinLiaoShu);
        CalculatePassiveSkill_ExtValue(src,0,triggers,attributes,skillId,1);
        vector<int> parameters;
        parameters.push_back(2000);
        parameters.push_back(GetAttrValue(attributes,ESkill_PassAttr_JinLiaoShuDamRatio));
        AddBuff(target,src,ESBUFF_JinLiaoShu,2,&parameters);
        m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
        m_extActionMsg<<(uint8)EFOT_Passive<<src<<skillId<<string("")<<(uint8)1;
        m_extActionMsg<<target<<(int)0<<(int)0<<(int)0;
        MakeBuffList(target,m_extActionMsg);
    }
}
