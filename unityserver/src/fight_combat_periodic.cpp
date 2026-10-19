#include "fight.h"
#include <algorithm>
#include <limits>

int64 CFight::CombatPeriodicRaw(uint8 target,const SFightBuffData& buff,int input)
{
    const auto* policy=CombatData::Current().PeriodicFor(buff.id);if(!policy)return 0;
    auto parameter=[&](int index)->int64{return index>=0 && static_cast<size_t>(index)<buff.paraList.size()?buff.paraList[index]:0;};
    const int64 basis=policy->basis=="target_max_hp"?GetMaxHp(target):policy->basis=="target_hp"?GetHp(target):policy->basis=="input"?input:1;
    int64 raw=policy->formula=="sum"?parameter(policy->paramA)+parameter(policy->paramB):basis*parameter(policy->paramA)/10000;
    if(policy->formula=="percent_cap")raw=std::min(raw,parameter(policy->capParam));
    return raw;
}

int CFight::CombatPeriodicValue(uint8 source,uint8 target,const SFightBuffData& buff,int input,int64 raw)
{
    int owned=0;
    for(uint8 pos=1;pos<=MAX_MEMBER;++pos)if(IsAlive(pos) && HaveBuff(pos,buff.id) && GetStateSrcPos(pos,buff.id)==source)++owned;
    CombatData::Modifiers query;query.amount=static_cast<int>(std::max<int64>(0,std::min<int64>(std::numeric_limits<int>::max(),raw)));query.parameters={1};
    CombatEvent("before_periodic_proc",source,target,buff.originSkill,buff.id,buff.originLevel,{{"periodic_input",input},{"live_owned_buff_targets",owned}},&query);
    const int64 scaled=query.parameters[0]?static_cast<int64>(query.amount)*(10000+query.amountBonus)/10000:0;
    CombatData::Modifiers result;result.amount=static_cast<int>(std::max<int64>(0,std::min<int64>(std::numeric_limits<int>::max(),scaled)));
    CombatEvent("after_periodic_proc",source,target,buff.originSkill,buff.id,buff.originLevel,{{"periodic_input",input}},&result);
    return result.amount;
}

uint8 CFight::CombatPeriodicActions(uint8 target,EFightStep step,CNetMessage& msg,int input)
{
    if(!GetFightMember(target) || !IsAlive(target)) return 0;
    const std::string event=step==EFStep_UserActBegin ? "before_action" : step==EFStep_CureHp ? "after_heal" : "";
    if(event.empty()) return 0;
    const auto& catalog=CombatData::Current();
    // Freeze per-source instances. Damage can revive, cleanse or add a buff;
    // those mutations must not invalidate this tick's iteration or ownership.
    std::map<std::pair<uint8,uint16>,std::vector<SFightBuffData>> groups;
    std::set<uint16> mergedStates;
    for(const auto& buff:m_members[target-1].buff_list) {
        const auto* policy=catalog.PeriodicFor(buff.id);
        if(!policy || policy->event!=event)continue;
        if(policy->aggregation=="state_sum") {
            if(!mergedStates.insert(buff.id).second)continue;
            SFightBuffData merged=buff;merged.paraList.clear();
            for(const auto& active:m_members[target-1].buff_list)if(active.id==buff.id) {
                if(merged.paraList.size()<active.paraList.size())merged.paraList.resize(active.paraList.size());
                for(size_t index=0;index<active.paraList.size();++index)
                    merged.paraList[index]=static_cast<int>(std::max<int64>(std::numeric_limits<int>::min(),std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(merged.paraList[index])+active.paraList[index])));
            }
            groups[{buff.srcPos,buff.id}].push_back(std::move(merged));
        } else if(buff.leftTurn>0 && !buff.paraList.empty())
            groups[{buff.srcPos,buff.id}].push_back(buff);
    }
    uint8 events=0;
    for(const auto& group:groups) {
        if(!IsAlive(target)) break;
        const uint8 src=group.first.first;
        if(!GetFightMember(src)) continue;
        const auto& policy=*catalog.PeriodicFor(group.first.second);
        const bool healing=policy.outcome=="heal";
        int64 total=0;
        bool firstHeal=false;
        for(const auto& buff:group.second) {
            if(healing && !buff.periodicTicked) firstHeal=true;
            int64 amount=CombatPeriodicRaw(target,buff,input);
            if(policy.bonusBuff && HaveBuff(target,policy.bonusBuff)) amount=amount*(10000+policy.bonus)/10000;
            if(!healing) {
                amount=CombatPeriodicValue(src,target,buff,input,amount);
                CombatData::Modifiers modifier;
                modifier.amount=static_cast<int>(std::max<int64>(0,std::min<int64>(amount,std::numeric_limits<int>::max())));
                CombatEvent("before_dot",src,target,buff.originSkill,buff.id,buff.originLevel,{{"periodic_damage",policy.turnBudget?1:0}},&modifier);
                const int64 affix=policy.bonusAffix?GetAffixValue(src,policy.bonusAffix,1):0;
                amount=static_cast<int64>(modifier.amount)*(10000+std::min<int64>(policy.bonusCap,modifier.amountBonus+affix))/10000;
            }
            total+=std::max<int64>(0,amount);
        }
        if(healing) {
            for(auto& buff:m_members[target-1].buff_list) if(buff.srcPos==src && buff.id==group.first.second) buff.periodicTicked=true;
            CombatData::Modifiers healModifier;
            CombatEvent("before_heal",src,target,group.second.front().originSkill,group.first.second,group.second.front().originLevel,{},&healModifier);
            CombatEvent("before_received_heal",target,target,group.second.front().originSkill,group.first.second,group.second.front().originLevel,{},&healModifier);
            total=total*(10000+std::min<int64>(policy.bonusCap,healModifier.amountBonus))/10000;
            total=total*std::max(0,10000-GetStatePara1(target,ESBUFF_JinLiaoShu))/10000;
        }
        if(policy.turnBudget) {
            auto& budget=m_combatState.periodic[src];
            if(budget.turn!=m_fightTurn) { budget.turn=m_fightTurn; budget.spent=0; }
            const int64 cap=static_cast<int64>(GetUnitAttack(src))*catalog.Rule("dot_turn_attack_bp")/10000;
            total=std::min(total,std::max<int64>(0,cap-budget.spent));
            budget.spent+=total;
        }
        total=std::min<int64>(total,std::numeric_limits<int>::max());
        bool emitZero=false;
        if(policy.zeroActionParameter>=0)for(const auto& buff:group.second)
            if(static_cast<size_t>(policy.zeroActionParameter)<buff.paraList.size() && buff.paraList[policy.zeroActionParameter]!=0)emitZero=true;
        if(total<=0 && !emitZero) continue;
        int value=static_cast<int>(healing ? -total : total),absorbed=0,revived=0;
        const int64 before=GetHp(target);
        {
            CombatData::ScopedDepth secondary(m_combatDepth);
            DecreaseHp(target,src,value,absorbed,false,&revived,false);
        }
        msg<<target<<-value<<absorbed<<revived;
        MakeBuffList(target,msg); ++events;
        const int actual=static_cast<int>(before-GetHp(target));
        if(healing && actual<0 && firstHeal) CombatEvent("after_periodic_heal",src,target,group.second.front().originSkill,group.first.second,group.second.front().originLevel,
            {{"effective_heal",-actual},{"overheal",std::max<int64>(0,total+actual)},{"hp_before_bp",GetMaxHp(target)>0?before*10000/GetMaxHp(target):0}});
        if(!healing && actual>0)CombatEvent("after_periodic_damage",src,target,group.second.front().originSkill,group.first.second,group.second.front().originLevel,{{"amount",actual}});
    }
    return events;
}
