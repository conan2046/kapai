#include "fight.h"
#include <algorithm>

bool CFight::ApplyCombatControl(uint8 target,uint16& buff,int& duration,vector<int>& parameters)
{
    const auto& catalog=CombatData::Current();
    const auto* policy=catalog.ControlFor(buff);
    if(!policy) return true;
    const auto* monster=GetMonster(target);
    const bool boss=m_members[target-1].isWorldBoss || (monster && monster->type==EMTTongLing);
    if(boss && policy->bossMode!="normal") {
        if(policy->bossMode=="ignore") return false;
        auto& budget=m_combatState.bossControls[target];
        if(budget.turn!=m_fightTurn) { budget.turn=m_fightTurn; budget.inTurn=0; }
        if(budget.inTurn>=catalog.Rule("boss_control_per_turn")) return false;
        ++budget.inTurn;
        buff=policy->replacement; duration=policy->duration; parameters.assign(1,policy->value);
        return true;
    }
    if(!policy->diminishing) return true;
    auto& history=m_combatState.controls[{target,buff}];
    if(m_fightTurn<history.immuneUntil) return false;
    if((history.immuneUntil>=0 && m_fightTurn>=history.immuneUntil) ||
        m_fightTurn>=history.lastEnd+catalog.Rule("control_reset_gap")) {
        history.count=0; history.immuneUntil=-1;
    }
    ++history.count;
    if(history.count>=catalog.Rule("control_immunity_threshold")) {
        history.immuneUntil=m_fightTurn+static_cast<int>(catalog.Rule("control_immunity_turns")); return false;
    }
    if(history.count>=catalog.Rule("control_reduce_threshold"))
        duration=std::max<int>(static_cast<int>(catalog.Rule("control_min_duration")),static_cast<int>(duration*catalog.Rule("control_duration_bp")/10000));
    history.lastEnd=m_fightTurn+duration;
    return true;
}

bool CFight::CombatCanRevive(uint8 target,uint8 source,uint16 skill)
{
    if(!GetFightMember(target) || HaveBuff(target,ESBUFF_ForbidFuHuo)) return false;
    const auto& catalog=CombatData::Current();
    if(m_combatState.revives[target]>=catalog.Rule("revive_per_target") ||
        m_combatState.reviveSources[{target,source}]>=catalog.Rule("revive_per_source_target"))return false;
    if(!skill)return true;
    auto* member=GetFightMember(source);if(!member)return false;
    CombatData::Modifiers query;query.parameters.push_back(1);
    CombatEvent("before_revive_eligibility",source,target,skill,0,std::max<int>(1,member->GetSkillLevel(skill)),{},&query);
    return query.parameters[0]!=0;
}

void CFight::CombatRecordRevive(uint8 target,uint8 source)
{
    ++m_combatState.revives[target]; ++m_combatState.reviveSources[{target,source}];
    m_combatState.revivedAt[target]=m_fightTurn;
}

bool CFight::CombatHaveReviveTarget(uint8 source,uint16 skill)
{
    const int first=source<=GROUP2_BEGIN ? 1 : GROUP2_BEGIN+1,last=source<=GROUP2_BEGIN ? GROUP2_BEGIN : MAX_MEMBER;
    for(int target=first;target<=last;++target)
        if(GetFightMember(target) && !IsAlive(target) && CombatCanRevive(target,source,skill)) return true;
    return false;
}

bool CFight::CombatTryExtraAttack(uint8 source)
{
    if(!GetFightMember(source) || !IsAlive(source)) return false;
    const auto& catalog=CombatData::Current();
    const auto revived=m_combatState.revivedAt.find(source);
    if(revived!=m_combatState.revivedAt.end() && m_fightTurn<revived->second+catalog.Rule("revived_extra_block_turns")) return false;
    auto& budget=m_combatState.extraAttacks[source];
    if(budget.turn!=m_fightTurn) { budget.turn=m_fightTurn; budget.inTurn=0; }
    if(budget.inTurn>=catalog.Rule("extra_attack_per_turn")) return false;
    ++budget.inTurn; return true;
}

bool CFight::CombatShieldAllowsLegacy(uint8 target,const SFightBuffData& shield,bool expired)
{
    CombatData::Modifiers query;query.parameters.push_back(1);
    CombatEvent("before_shield_passive",shield.srcPos,target,shield.originSkill,shield.id,shield.originLevel,
        {{"expired",expired?1:0},{"broken",expired?0:1}},&query);
    return query.parameters[0]!=0;
}

void CFight::CombatShieldLost(uint8 target,uint8 attacker,const SFightBuffData& shield,const char* reason)
{
    const int remaining=shield.paraList.empty() ? 0 : std::max(0,shield.paraList[0]);
    const int original=shield.paraList.size()>1 ? shield.paraList[1] : remaining;
    CombatEvent("shield_lost",shield.srcPos,target,shield.originSkill,shield.id,shield.originLevel,
        {{"shield_remaining",remaining},{"shield_absorbed",std::max(0,original-remaining)},
        {"shield_parameter_count",static_cast<int64>(shield.paraList.size())},
        {"shield_loss_basis",std::string(reason)=="expired"?remaining/2:std::max(0,original-remaining)},
        {"secondary_damage",m_combatDepth>0?1:0},
        {"broken",std::string(reason)=="broken"},{"expired",std::string(reason)=="expired"},
        {"dispelled",std::string(reason)=="dispelled"},{"attacker_position",attacker}});
}
