#include "fight.h"
#include "protocol.h"
#include "singleton.h"
#include <algorithm>
#include <iostream>
#include <stdexcept>
#include <cstdlib>
#include <set>
#include <limits>
#include <memory>
#include <fstream>
#include <mutex>
#include "rapidjson/stringbuffer.h"
#include "rapidjson/writer.h"

// Opt-in local diagnostics: read the actual entry object, without queries that
// choose targets, consume RNG, execute effects, or change the combat state.
void CFight::CombatWriteEntryEvidence()
{
    const char* path=std::getenv("PROJECTX_COMBAT_ENTRY_EVIDENCE");
    if(!path || !*path)return;
    try {
        rapidjson::StringBuffer buffer;
        rapidjson::Writer<rapidjson::StringBuffer> out(buffer);
        out.StartObject();
        out.Key("schema");out.Int(1);
        out.Key("phase");out.String("before_first_round");
        out.Key("fight_id");out.Uint(m_id);
        out.Key("fight_type");out.Uint(m_type);
        out.Key("turn");out.Int(m_fightTurn);
        out.Key("members");out.StartArray();
        for(uint8 pos=1;pos<=MAX_MEMBER;++pos) {
            if(IsEmpty(pos))continue;
            const auto& member=m_members[pos-1];
            out.StartObject();
            out.Key("position");out.Uint(pos);
            out.Key("hero");out.Uint(GetHeroId(pos));
            out.Key("owner");out.Uint(member.petOwner);
            out.Key("branch");out.Uint(member.combatBranch);
            out.Key("strategy");out.Uint(member.combatStrategy);
            out.Key("hp");out.Int64(member.hp);
            out.Key("max_hp");out.Int64(member.unitAttr.maxHp);
            out.Key("attack");out.Int(member.unitAttr.attack);
            out.Key("affixes");out.StartArray();
            for(const auto& item:sCItemCfgManager.GetEquipAffixCfgs()) {
                const int tier=GetAffixTier(pos,item.first);
                if(!tier)continue;
                out.StartObject();out.Key("id");out.Uint(item.first);
                out.Key("tier");out.Int(tier);out.EndObject();
            }
            out.EndArray();
            auto pairs=[&](const char* key,const std::map<int,int>& values) {
                out.Key(key);out.StartArray();
                for(const auto& value:values){out.StartArray();out.Int(value.first);out.Int(value.second);out.EndArray();}
                out.EndArray();
            };
            pairs("groups",member.combatLoadout.groups);
            pairs("suit_pieces",member.combatLoadout.pieces);
            out.Key("artifacts");out.StartObject();
            for(const auto& value:member.combatLoadout.artifacts){out.Key(value.first.c_str());out.Int(value.second);}
            out.EndObject();
            out.Key("active_skills");out.StartArray();
            for(const auto& skill:member.skill_list){out.StartArray();out.Uint(skill.id);out.Int(skill.level);out.EndArray();}
            out.EndArray();out.EndObject();
        }
        out.EndArray();out.EndObject();
        static std::mutex evidenceMutex;
        std::lock_guard<std::mutex> lock(evidenceMutex);
        std::ofstream file(path,std::ios::out|std::ios::app|std::ios::binary);
        file<<buffer.GetString()<<'\n';
        if(!file)std::cerr<<"Combat entry evidence write failed"<<std::endl;
    } catch(const std::exception&) {
        std::cerr<<"Combat entry evidence unavailable"<<std::endl;
    }
}

void CFight::CombatSnapshotEquipment(uint8 pos,CUser* owner,uint16 heroId)
{
    if(!owner || !GetFightMember(pos))return;
    std::vector<CombatData::WornItem> items;
    auto& equipment=owner->GetPetEquipMgr();
    FormationEquipMap worn;
    equipment.GetWornEquipment(owner->GetChuZhanIdx(heroId),worn);
    for(const auto& entry:worn) {
        CombatData::WornItem item;item.slot=entry.first;item.instance=entry.second;
        // Slot/instance namespaces are structural; effects and selection use formal data.
        item.artifact=entry.first>4;
        if(item.artifact){auto* artifact=equipment.GetFaBao(entry.second);if(!artifact)continue;item.id=artifact->id;}
        else{auto* value=equipment.GetEqiup(entry.second);auto* cfg=value?sCItemCfgManager.GetEquipCfg(value->id):NULL;
            if(!cfg)continue;item.id=value->id;item.suit=cfg->suit;item.part=cfg->part;}
        items.push_back(item);
    }
    m_members[pos-1].combatLoadout=CombatData::Current().Snapshot(items);
}

bool CFight::ApplyCombatBuffRules(uint8 target,SFightBuffData& data)
{
    auto& buffs=m_members[target-1].buff_list;
    const auto& rules=CombatData::Current();
    std::set<uint16> removedTypes;
    const auto* control=rules.ControlFor(data.id);
    const auto* periodic=rules.PeriodicFor(data.id);
    const bool vulnerability=data.id==ESBUFF_GetDamageAdd || data.id==ESBUFF_GetWuDamageAdd || data.id==ESBUFF_GetFaDamageAdd;
    if(vulnerability && rules.Rule("vulnerability_keep_highest") && !data.paraList.empty()) {
        for(const auto& previous:buffs)
            if(previous.id==data.id && !previous.paraList.empty() && previous.paraList[0]>data.paraList[0])return false;
        for(auto it=buffs.begin();it!=buffs.end();)
            if(it->id==data.id)it=buffs.erase(it);else ++it;
    }
    if(data.originSkill && ((control && control->refresh) || (rules.Rule("buff_refresh_same_origin") &&
        !IsShieldBuff(data.id) && !vulnerability && !(periodic && periodic->stackGroup>0)))) {
        for(auto it=buffs.begin();it!=buffs.end();)
            if(it->srcPos==data.srcPos && it->id==data.id && it->originSkill==data.originSkill) it=buffs.erase(it); else ++it;
    }
    // Refresh/replacement is not a dispel or a broken-shield event.
    if (IsShieldBuff(data.id)) {
        if (data.paraList.empty() || data.paraList[0]<=0) return false;
        CombatData::Modifiers modifier;modifier.duration=data.leftTurn;modifier.parameters=data.paraList;
        CombatEvent("before_shield",data.srcPos,target,data.originSkill,data.id,data.originLevel,
            {{"parameter_count",static_cast<int64>(data.paraList.size())}},&modifier);
        data.leftTurn=modifier.duration;data.paraList=modifier.parameters;
        data.paraList[0]=static_cast<int>(std::max<int64>(0,std::min<int64>(std::numeric_limits<int>::max(),
            static_cast<int64>(data.paraList[0])*(10000+modifier.amountBonus)/10000)));
        int64 other=0;
        for(auto it=buffs.begin();it!=buffs.end();) {
            if(rules.Rule("shield_refresh_same_source") && it->id==data.id && it->srcPos==data.srcPos) {
                removedTypes.insert(it->id); it=buffs.erase(it);
            } else {
                if(IsShieldBuff(it->id) && it->leftTurn>0 && !it->paraList.empty()) other+=std::max(0,it->paraList[0]);
                ++it;
            }
        }
        const int64 room=std::max<int64>(0,GetMaxHp(target)*rules.Rule("shield_cap_bp")/10000-other);
        data.paraList[0]=static_cast<int>(std::min<int64>(data.paraList[0],room));
        if(data.paraList.size()<2) data.paraList.resize(2);
        data.paraList[1]=data.paraList[0];
    }
    if(periodic && periodic->stackGroup>0) {
        data.leftTurn=std::min<int>(data.leftTurn,static_cast<int>(rules.Rule("dot_max_duration")));
        auto sameBudget=[&](const SFightBuffData& existing) {
            const auto* other=rules.PeriodicFor(existing.id);
            return existing.srcPos==data.srcPos && (existing.id==data.id ||
                (rules.Rule("dot_poison_shared_budget") && other && other->stackGroup==periodic->stackGroup));
        };
        int count=0; for(const auto& b:buffs) if(sameBudget(b)) ++count;
        while(count>=rules.Rule("dot_max_stacks")) {
            auto shortest=buffs.end();
            for(auto it=buffs.begin();it!=buffs.end();++it)
                if(sameBudget(*it) && (shortest==buffs.end() || it->leftTurn<shortest->leftTurn)) shortest=it;
            if(shortest==buffs.end()) break;
            removedTypes.insert(shortest->id); buffs.erase(shortest); --count;
        }
    }
    const bool accepted=!IsShieldBuff(data.id) || data.paraList[0]>0;
    for(uint16 id:removedTypes) if((!accepted || id!=data.id) && !HaveBuff(target,id)) SpecialBuffPassAttr(target,id,false);
    return accepted;
}

void CFight::CombatDirectHpDamage(uint8 source,uint8 target,uint16 skill,int level,int& damage,int& absorbed,bool pierce,int* revived,bool allowSharedLink)
{
    if(damage<=0 || !HaveShieldState(target)){DecreaseHp(target,source,damage,absorbed,pierce,revived,allowSharedLink);return;}
    CombatData::Modifiers modifier;
    modifier.parameters.push_back(pierce?static_cast<int>(CombatData::Current().Rule("shield_pierce_success_bp")):0);
    CombatEvent("before_shield_damage",source,target,skill,0,level,{},&modifier);
    const int penetration=std::min(10000,std::max(0,modifier.parameters[0]));
    const int64 multiplier=std::max<int64>(1,10000+modifier.amountBonus);
    if(!penetration && multiplier==10000){DecreaseHp(target,source,damage,absorbed,false,revived,allowSharedLink);return;}
    const int lifePart=static_cast<int>(static_cast<int64>(damage)*penetration/10000);
    const int shieldPart=damage-lifePart;
    int pressure=static_cast<int>(std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(shieldPart)*multiplier/10000));
    int shieldAbsorbed=0;
    ShieldAbsorptionDamage(target,pressure,shieldAbsorbed);
    const int spent=static_cast<int>(std::min<int64>(shieldPart,(static_cast<int64>(shieldAbsorbed)*10000+multiplier-1)/multiplier));
    damage=lifePart+shieldPart-spent;
    int ignored=0;DecreaseHp(target,source,damage,ignored,true,revived,allowSharedLink);
    absorbed=shieldAbsorbed;
    GetFightMember(target)->sum_beDamage+=absorbed;
    GetFightMember(source)->sum_damage+=absorbed;
}

bool CFight::CombatBoss(uint8 pos)
{
    const auto* member=GetFightMember(pos);const auto* monster=GetMonster(pos);
    return member && (member->isWorldBoss || (monster && monster->type==EMTTongLing));
}

int CFight::CombatShareDamage(uint8 guardian,int damage,uint16 skill,int level)
{
    CombatData::Modifiers query;query.amount=damage;
    CombatEvent("before_share_damage",guardian,guardian,skill,0,level,{},&query);
    if(query.amountBonus>=0)return query.amount;
    const int64 value=static_cast<int64>(query.amount)*(10000+query.amountBonus)/10000;
    return static_cast<int>(std::max<int64>(std::numeric_limits<int>::min(),std::min<int64>(std::numeric_limits<int>::max(),value)));
}

int CFight::CombatStat(uint8 pos,int kind,int value)
{
    if(m_combatStatQuery)return value;
    struct Guard {bool& flag;explicit Guard(bool& f):flag(f){flag=true;}~Guard(){flag=false;}} guard(m_combatStatQuery);
    CombatData::Modifiers query;query.amount=value;
    CombatEvent("before_stat",pos,pos,0,0,1,{{"stat_kind",kind}},&query);
    return query.amount;
}

float CFight::CombatDirectMultiplier(uint8 source,uint8 target,uint16 skill,int level,float multiplier)
{
    CombatData::Modifiers modifiers;
    CombatEvent("before_direct_damage",source,target,skill,0,level,{},&modifiers);
    const auto* member=GetFightMember(source);
    // Preserve the original three float stores, each fed by double division.
    // Folding these stages or dividing 8400 by 10000.0f loses a damage point.
    multiplier+=modifiers.parameterBonuses[0]/10000.0;
    multiplier+=modifiers.parameterBonuses[1]/10000.0;
    multiplier+=(member->unitAttr.zengshangLv+GetStatePara1(source,ESBUFF_ZengShangLvAdd)-GetStatePara1(source,ESBUFF_ZengShangLvDes))/10000.0;
    const auto& catalog=CombatData::Current();
    return std::max(catalog.Rule("direct_multiplier_min_bp")/10000.0f,std::min(catalog.Rule("direct_multiplier_max_bp")/10000.0f,multiplier));
}

int CFight::CombatIgnoreDefense(uint8 source,uint8 target,int initial,uint16 skill,int level)
{
    CombatData::Modifiers modifiers;modifiers.amount=initial;
    CombatEvent("before_defense",source,target,skill,0,level,{},&modifiers);
    return static_cast<int>(std::max<int64>(0,std::min<int64>(CombatData::Current().Rule("ignore_defense_cap_bp"),modifiers.amount)));
}

CombatData::Values CFight::CombatTargetFacts(uint8 target,uint8 owner)
{
    CombatData::Values values;
    if (GetFightMember(target) == NULL) return values;
    const int64 hp = GetHp(target), maximum = GetMaxHp(target);
    values["position"] = target;
    values["target_hp"] = hp;
    values["target_max_hp"] = maximum;
    values["target_missing_hp"] = std::max<int64>(0,maximum-hp);
    values["target_hp_bp"] = maximum > 0 ? hp*10000/maximum : 0;
    values["target_hp_bp_ceil"] = maximum > 0 ? (hp*10000+maximum-1)/maximum : 0;
    values["target_hard_control"]=0;
    values["target_alive"] = IsAlive(target) ? 1 : 0;
    values["target_attack_type"]=GetFightMember(target)->attackType;
    values["target_boss"] = CombatBoss(target)?1:0;
    values["target_shield"] = HaveShieldState(target) ? 1 : 0;
    values["target_shield_amount"]=static_cast<int64>(GetStatePara1(target,ESBUFF_Shield))+GetStatePara1(target,ESBUFF_ShieldMianShang);
    values["target_hero_"+std::to_string(GetHeroId(target))]=1;
    for(int buff:GetFightMember(target)->notEffectBuff) {
        values["target_immune_"+std::to_string(buff)]=1;
        const auto* policy=CombatData::Current().ControlFor(buff);
        if(!values["target_boss"] || !policy || policy->bossMode!="replace")values["target_blocks_buff_"+std::to_string(buff)]=1;
    }
    std::set<int> categories;
    for(const auto& buff:GetFightMember(target)->buff_list) {
        if(IsAffixHardControl(buff.id))values["target_hard_control"]=1;
        values["target_buff_"+std::to_string(buff.id)]=1;
        values["target_buff_value_"+std::to_string(buff.id)]=GetStatePara1(target,buff.id);
        const int category=CombatData::Current().BuffCategory(buff.id);
        if(category) {categories.insert(category);values["target_category_"+std::to_string(category)]=1;++values["target_category_count_"+std::to_string(category)];}
        const auto* periodic=CombatData::Current().PeriodicFor(buff.id);
        if(periodic && periodic->outcome=="damage" && !buff.paraList.empty()) {
            auto parameter=[&](int index)->int64{return index>=0 && static_cast<size_t>(index)<buff.paraList.size()?buff.paraList[index]:0;};
            const int64 basis=periodic->basis=="target_max_hp"?maximum:periodic->basis=="target_hp"?hp:1;
            int64 raw=periodic->formula=="sum"?parameter(periodic->paramA)+parameter(periodic->paramB):basis*parameter(periodic->paramA)/10000;
            if(periodic->formula=="percent_cap")raw=std::min(raw,parameter(periodic->capParam));
            if(category)values["target_periodic_remaining_"+std::to_string(category)]+=raw*buff.leftTurn;
            if(owner && buff.srcPos==owner) {
                if(category)values["target_owned_periodic_raw_"+std::to_string(category)]+=raw;
                const std::string instances="target_owned_buff_instances_"+std::to_string(buff.id);
                if(++values[instances]==1)values["target_owned_buff_remaining_"+std::to_string(buff.id)]=raw*buff.leftTurn;
            }
        }
    }
    values["target_debuff_categories"]=static_cast<int>(categories.size());
    values["target_has_debuff"]=HaveDeBuffState(target)?1:0;
    return values;
}

void CFight::CombatAfterHeal(uint8 src,uint8 target,uint16 skill,int level,int beforeHp,int overheal,bool wasAlive)
{
    if (!IsAlive(target)) return;
    const int64 maxHp = GetMaxHp(target);
    CombatEvent(wasAlive ? "after_heal" : "after_revive",src,target,skill,0,level,
        {{"effective_heal",std::max<int64>(0,GetHp(target)-beforeHp)},
         {"overheal",std::max(0,overheal)},
         {"hp_before_bp",maxHp > 0 ? static_cast<int64>(beforeHp)*10000/maxHp : 0}});
}

bool CFight::CombatAllowEffect(uint8 src,uint8 target,uint16 skill,int level,uint16 buff,int kind,int passive,int* duration,int baseDuration,bool defaultAllowed)
{
    CombatData::Modifiers query;query.parameters={defaultAllowed?1:0,duration?*duration:0};
    CombatEvent("before_effect_attempt",src,target?target:src,skill,buff,level,{{"effect_kind",kind},{"passive_effect",passive},{"target_present",target?1:0},{"base_duration",baseDuration}},&query);
    if(duration)*duration=query.parameters[1];
    return query.parameters[0]!=0;
}

int CFight::CombatPassiveValue(uint8 src,uint8 target,uint16 skill,int level,SSkillAdditiveEffect* effect,int trigger,int attribute,int value)
{
    CombatData::Modifiers query;query.amount=value;
    CombatEvent("before_passive_value",src,target?target:src,skill,effect->buffId,level,{{"attribute_type",attribute},{"passive_trigger",trigger},{"passive_effect",effect->id},{"target_present",target?1:0}},&query);
    return query.amount;
}

bool CFight::CombatPassiveHeal(uint8 src,uint8 target,uint16 skill,int level,int& hpChange,bool* notifyAfter)
{
    CombatData::Modifiers query;query.amount=-hpChange;query.parameters={1,0,0};
    CombatEvent("before_passive_heal",src,target,skill,0,level,{},&query);
    if(query.parameters[1])query.amount=static_cast<int>(static_cast<int64>(query.amount)*std::max(0,10000-GetStatePara1(target,ESBUFF_JinLiaoShu))/10000);
    if(notifyAfter)*notifyAfter=query.parameters[2]!=0;
    hpChange=-query.amount;return query.parameters[0]!=0;
}

void CFight::CombatPassiveList(uint8 src,uint8 target,uint16 skill,int level,int trigger,vector<int>& effects)
{
    CombatData::Modifiers query;query.amount=1;query.parameters=effects;
    CombatEvent("before_passive_list",src,target?target:src,skill,0,level,{{"passive_trigger",trigger},{"effect_count",static_cast<int64>(effects.size())},{"target_present",target?1:0}},&query);
    if(!query.amount)effects.clear();else effects=std::move(query.parameters);
}

bool CFight::CombatPassiveParameters(uint8 src,uint8 target,uint16 skill,SSkillAdditiveEffect* effect,int level,int trigger,vector<int>& parameters,bool rolled)
{
    CombatData::Modifiers query;query.amount=1;query.parameters=parameters;
    const auto* victim=GetFightMember(target);
    auto* member=GetFightMember(src);if(!member || !effect)return false;
    int count=0;
    const uint64 key=(static_cast<uint64>(skill)<<32) | (static_cast<uint64>(effect->type)<<16) | effect->buffId;
    const auto previous=member->passSkillLimit.find(key);if(previous!=member->passSkillLimit.end())count=previous->second._count;
    CombatEvent(rolled?"after_passive_attribute_roll":"before_passive_parameters",src,victim?target:src,skill,effect->buffId,level,
        {{"passive_effect",effect->id},{"passive_trigger",trigger},{"passive_count",count},
         {"target_present",victim?1:0},{"target_summoned",victim && victim->affixSummoned?1:0},
         {"same_team",victim && (src<=GROUP2_BEGIN)==(target<=GROUP2_BEGIN)?1:0},
         {"parameter_count",static_cast<int64>(parameters.size())}},&query);
    parameters=std::move(query.parameters);return query.amount!=0;
}

void CFight::CombatEvent(const char* name,uint8 src,uint8 target,uint16 skill,uint16 buff,
                        int level,CombatData::Values values,CombatData::Modifiers* modifiers,const std::vector<int>* parameters)
{
    SFightMember* member = GetFightMember(src);
    const auto& catalog=CombatData::Current();
    const auto& eventEffects=catalog.EffectsForEvent(name);
    if(eventEffects.empty())return;
    // Neutral/environmental shields still receive the recipient team's aura.
    std::unique_ptr<SFightMember> neutralSource;
    if(!member && std::string(name)=="before_shield") {neutralSource.reset(new SFightMember);member=neutralSource.get();}
    if (member == NULL || (!modifiers && m_combatDepth>=CombatData::Current().EventDepthLimit(name))) {
        return;
    }
    const auto ownerGroups=catalog.BoundGroups(GetHeroId(src),member->combatBranch);
    bool relevant=false;
    for(size_t index:eventEffects) {
        const auto& effect=catalog.Effects()[index];
        if((effect.skill && effect.skill!=skill) || (effect.buff && effect.buff!=buff))continue;
        if(effect.bindingScope=="target_team") {
            const int first=target<=GROUP2_BEGIN?1:GROUP2_BEGIN+1;
            for(int pos=first;pos<first+GROUP_MEMBER;++pos)if(IsAlive(pos) && catalog.BoundGroups(GetHeroId(pos),GetFightMember(pos)->combatBranch).count(effect.group)){relevant=true;break;}
            if(relevant)break;
            continue;
        }
        if(effect.bindingScope=="source_buff_owner") {
            const uint8 owner=buff?GetStateSrcPos(src,buff):0;
            if(const auto* origin=GetFightMember(owner))relevant=catalog.BoundGroups(GetHeroId(owner),origin->combatBranch).count(effect.group)>0;
            if(relevant)break;
            continue;
        }
        if(effect.bindingScope=="source_mark" || effect.bindingScope=="target_mark") {
            const int position=effect.bindingScope=="source_mark"?src:target;
            for(const auto& mark:m_combatState.marks)if(mark.first.first==position && mark.second.expires>m_fightTurn && mark.second.group==effect.group){relevant=true;break;}
            if(relevant)break;
            continue;
        }
        if(ownerGroups.count(effect.group) || member->combatLoadout.groups.count(effect.group)) {relevant=true;break;}
        if(effect.affix) {
            const int first=effect.affixScope=="owner"?src:(src<=GROUP2_BEGIN?1:GROUP2_BEGIN+1);
            const int end=effect.affixScope=="owner"?src+1:first+GROUP_MEMBER;
            for(int pos=first;pos<end;++pos)if(!IsEmpty(pos) && (!effect.affixAliveOnly || IsAlive(pos)) && GetAffixTier(pos,effect.affix)>0){relevant=true;break;}
            if(relevant)break;
        }
    }
    if(!relevant)return;
    // One healing operation combines its affix and branch conversion before
    // same-source shield refresh, so one contribution cannot erase the other.
    struct ShieldGrant {int64 amount=0;int duration=0,originSkill=0,originLevel=1,presentation=0;bool emitAction=true;};
    std::map<uint8,ShieldGrant> shields;
    std::map<uint8,int64> overhealShields;
    const int64 overhealLimit=values["overheal"]*CombatData::Current().Rule("overheal_shield_conversion_cap_bp");
    int64 reservedOverheal=0;
    if(std::string(name)=="after_heal")values["healing_total"]=values["effective_heal"]+values["overheal"];
    CombatData::Event event;
    int64 actualHpLoss=0;
    if(parameters)event.parameters=*parameters;
    event.name = name; event.actor = src; event.hero = GetHeroId(src); event.branch = member->combatBranch;
    if(event.name=="owned_buff_hit" && buff) {
        const uint8 owner=GetStateSrcPos(src,buff);
        if(const auto* origin=GetFightMember(owner))event.sourceBuffOwnerGroups=CombatData::Current().BoundGroups(GetHeroId(owner),origin->combatBranch);
    }
    event.target=target;
    for(const auto& fact:CombatTargetFacts(target,src))values[fact.first=="position"?"event_target_position":"event_"+fact.first]=fact.second;
    event.teamActor=src<=GROUP2_BEGIN?1:GROUP2_BEGIN+1;
    for(int pos=event.teamActor;pos<event.teamActor+GROUP_MEMBER;++pos)if(IsAlive(pos))values["source_team_hero_"+std::to_string(GetHeroId(pos))]=1;
    event.action=member->combatActionIndex;
    event.skill = skill; event.buff = buff; event.turn = m_fightTurn; event.level = level;
    event.depth=m_combatDepth;
    event.equipmentGroups=member->combatLoadout.groups;
    if(event.name=="before_shield" || event.name=="before_stat") {
        const int first=target<=GROUP2_BEGIN?1:GROUP2_BEGIN+1;
        for(int pos=first;pos<first+GROUP_MEMBER;++pos)if(IsAlive(pos)) {
            const auto groups=CombatData::Current().BoundGroups(GetHeroId(pos),GetFightMember(pos)->combatBranch);
            event.targetTeamGroups.insert(groups.begin(),groups.end());
            for(int group:groups) {
                auto learned=[&](const std::vector<SSkillData>& skills){for(const auto& owned:skills) {
                    auto& maximum=event.targetTeamValues[group]["team_skill_level_"+std::to_string(owned.id)];maximum=std::max<int64>(maximum,owned.level);
                }};
                learned(GetFightMember(pos)->skill_list);learned(GetFightMember(pos)->passive_skill);
            }
        }
    }
    if(event.name=="battle_begin")for(const auto& group:event.equipmentGroups) {
        uint8 leader=0;
        for(int pos=event.teamActor;pos<event.teamActor+GROUP_MEMBER;++pos) {
            const auto* ally=GetFightMember(pos);
            if(!ally || !IsAlive(pos) || !ally->combatLoadout.groups.count(group.first))continue;
            if(!leader || GetMaxHp(pos)>GetMaxHp(leader))leader=static_cast<uint8>(pos);
        }
        event.contentValues[group.first]["source_is_group_hp_leader"]=leader==src?1:0;
    }
    for(size_t index:eventEffects) {
        const auto& effect=catalog.Effects()[index];
        if(!effect.affix || event.contentValues.count(effect.group))continue;
        uint8 owner=0;int best=-1;
        const int first=effect.affixScope=="owner"?src:event.teamActor;
        const int end=effect.affixScope=="owner"?src+1:event.teamActor+GROUP_MEMBER;
        for(int pos=first;pos<end;++pos) {
            if(IsEmpty(pos) || (effect.affixAliveOnly && !IsAlive(pos)) || GetAffixTier(pos,effect.affix)<=0)continue;
            const int value=GetAffixValue(pos,effect.affix,effect.affixScope=="team_highest_value2"?2:1);
            if(value>best){best=value;owner=static_cast<uint8>(pos);}
        }
        if(!owner)continue;
        const auto* config=sCItemCfgManager.GetEquipAffixCfg(effect.affix);
        if(!config)throw std::runtime_error("missing loaded affix configuration");
        event.contentValues[effect.group]={{"affix_value1",GetAffixValue(owner,effect.affix,1)},{"affix_value2",GetAffixValue(owner,effect.affix,2)},
            {"affix_tier",GetAffixTier(owner,effect.affix)},{"affix_duration",config->duration},{"affix_is_owner",owner==src?1:0}};
    }
    values["turn"]=m_fightTurn;
    if(event.name=="before_direct_damage" || event.name=="before_attack" || event.name=="landed_attack") values["hit_index"]=member->combatHitIndex;
    if(event.name=="before_heal") {
        const auto* periodic=CombatData::Current().PeriodicFor(buff);
        values["periodic_heal"]=periodic && periodic->outcome=="heal"?1:0;
    }
    if(event.name=="after_attack") {
        const auto* role=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(event.hero);
        values["regular_skill"]=skill && role && role->regularSkillId==skill?1:0;
        values["hit_index"]=member->combatHitIndex;
    }
    values["source_alive"]=IsAlive(src) ? 1 : 0;
    values["event_depth"]=m_combatDepth;
    const auto sequence=m_combatState.sequences.find(src);
    values["sequence_fixed"]=sequence!=m_combatState.sequences.end() && sequence->second.fixed?1:0;
    values["sequence_index"]=sequence==m_combatState.sequences.end()?0:sequence->second.index;
    values["sequence_target_index"]=sequence==m_combatState.sequences.end()?0:sequence->second.targetIndex;
    uint8 opponents[GROUP_MEMBER],opponentCount=0;GetAnotherGroup(src,opponents,opponentCount);
    values["enemies_alive"]=opponentCount;
    if(event.name=="before_passive_list") {
        uint8 highest=0;
        for(uint8 i=0;i<opponentCount;++i)if(!highest || GetUnitAttack(opponents[i])>GetUnitAttack(highest))highest=opponents[i];
        values["highest_enemy_combo_bp"]=highest?GetFightMember(highest)->unitAttr.lianjiLv+GetStatePara1(highest,ESBUFF_LianJiLvAdd):0;
        values["highest_enemy_critical_bp"]=highest?GetFightMember(highest)->unitAttr.baojiLv+GetStatePara1(highest,ESBUFF_BaoJiLvAdd):0;
        values["highest_enemy_debuff_bp"]=highest?GetFightMember(highest)->unitAttr.fumianAdd+GetStatePara1(highest,ESBUFF_FuMianQiangHuaAdd):0;
        values["highest_enemy_counter_bp"]=highest?GetFightMember(highest)->unitAttr.fanjiLv:0;
    }
    for(uint8 i=0;i<opponentCount;++i){std::set<int> unique;for(const auto& active:GetFightMember(opponents[i])->buff_list)unique.insert(active.id);for(int id:unique)++values["enemy_buff_units_"+std::to_string(id)];}
    values["source_position"]=src;
    const auto revivedAt=m_combatState.revivedAt.find(src);
    values["source_just_revived"]=revivedAt!=m_combatState.revivedAt.end() && revivedAt->second==m_fightTurn?1:0;
    values["source_attack_type"]=member->attackType;
    values["tactic_used"]=m_tacticUsedThisTurn[src<=GROUP2_BEGIN?EGT_GROUP1:EGT_GROUP2]?1:0;
    values["source_summoned"]=member->affixSummoned ? 1 : 0;
    values["source_hard_control"]=0;for(const auto& active:member->buff_list)if(IsAffixHardControl(active.id)){values["source_hard_control"]=1;break;}
    for(const auto& active:member->buff_list)values["source_owns_buff_"+std::to_string(active.id)]=GetStateSrcPos(src,active.id)==src?1:0;
    for(const auto& active:member->buff_list)values["source_buff_"+std::to_string(active.id)]=1;
    for(const auto& active:member->buff_list)if(active.leftTurn>0 && active.originSkill)values["source_active_buff_"+std::to_string(active.originSkill)+"_"+std::to_string(active.id)]=1;
    values["source_base_attack"]=member->unitAttr.attack;
    for(const auto& learned:member->skill_list)values["source_skill_level_"+std::to_string(learned.id)]=learned.level;
    for(const auto& learned:member->passive_skill) {
        values["source_skill_level_"+std::to_string(learned.id)]=learned.level;
        values["source_passive_skill_"+std::to_string(learned.id)]=1;
    }
    if(event.name=="before_buff" && modifiers)values["parameter_count"]=static_cast<int64>(modifiers->parameters.size());
    if(modifiers)for(size_t index=0;index<modifiers->parameters.size() && index<5;++index)values["parameter_value_"+std::to_string(index+1)]=modifiers->parameters[index];
    if(event.name=="after_buff" || event.name=="buff_attempt_applied") {
        const auto* periodic=CombatData::Current().PeriodicFor(buff);
        const int family=periodic?periodic->stackGroup:0;
        int stacks=0;
        if(family>0 && GetFightMember(target))for(const auto& status:GetFightMember(target)->buff_list) {
            const auto* policy=CombatData::Current().PeriodicFor(status.id);
            if(policy && policy->stackGroup==family)++stacks;
        }
        values["event_stack_group"]=family;values["event_stack_count"]=stacks;
    }
    if(event.name=="before_skill_usefulness") {
        // Materialize only the typed buff facts required by this query's data.
        std::set<int> queriedBuffs;
        for(size_t index:CombatData::Current().EffectsForEvent(event.name)) {
            const auto& definition=CombatData::Current().Effects()[index];
            for(const auto& condition:definition.conditions)for(const auto& field:{condition.field,condition.otherField})
                for(const std::string prefix:{"enemy_unstacked_units_","enemy_unstacked_boss_","enemy_susceptible_unstacked_","enemy_susceptible_unstacked_boss_"})
                    if(field.compare(0,prefix.size(),prefix)==0 && field.size()>prefix.size() && field[prefix.size()]>='0' && field[prefix.size()]<='9')queriedBuffs.insert(std::stoi(field.substr(prefix.size())));
        }
        values["enemies_shielded"]=0;
        for(uint8 i=0;i<opponentCount;++i) {
            const uint8 enemy=opponents[i];
            if(HaveShieldState(enemy))++values["enemies_shielded"];
            for(int queryBuff:queriedBuffs)if(!HaveBuff(enemy,queryBuff)) {
                const std::string suffix=std::to_string(queryBuff);
                ++values["enemy_unstacked_units_"+suffix];
                if(CombatBoss(enemy))++values["enemy_unstacked_boss_"+suffix];
                if(!GetFightMember(enemy)->InNotEffectBuff(queryBuff)) {
                    ++values["enemy_susceptible_unstacked_"+suffix];
                    if(CombatBoss(enemy))++values["enemy_susceptible_unstacked_boss_"+suffix];
                }
            }
        }
        std::vector<int64> ratios;int64 missing=0;
        for(int pos=event.teamActor;pos<event.teamActor+GROUP_MEMBER;++pos)if(IsAlive(pos)) {
            const int64 maximum=GetMaxHp(pos);
            const int64 ratio=maximum>0?GetHp(pos)*10000/maximum:10000;
            ratios.push_back(ratio);missing+=10000-ratio;
        }
        std::sort(ratios.begin(),ratios.end());
        values["source_team_second_hp_bp"]=ratios.size()>1?ratios[1]:10000;
        values["source_team_mean_missing_hp_bp"]=ratios.empty()?0:missing/static_cast<int64>(ratios.size());
    }
    values["source_hp"] = GetHp(src); values["source_max_hp"] = GetMaxHp(src);
    values["event_skill"]=skill;
    values["source_hp_bp"]=GetMaxHp(src)>0 ? GetHp(src)*10000/GetMaxHp(src) : 0;
    values["source_hp_bp_ceil"]=GetMaxHp(src)>0 ? (GetHp(src)*10000+GetMaxHp(src)-1)/GetMaxHp(src) : 0;
    values["source_attack"] = GetUnitAttack(src); values["rage"] = GetTeamRage(src);
    if (modifiers != NULL) values["amount"] = modifiers->amount;
    event.values = values;
    // These selectors represent one chosen recipient for the complete event,
    // so a cleanse followed by healing retains the original selected unit.
    std::map<std::string,uint8> selectedRecipients;
    CombatData::Current().Execute(event,m_combatState,[](int maximum) { return Random(1,maximum); },
        [&](const std::string& selector,int group) {
            std::vector<CombatData::Values> targets;
            if(selector=="other_healed_allies" || selector=="lowest_two_other_healed_allies") {
                uint8 positions[GROUP_MEMBER],count=0;GetMeGroup(src,positions,count);
                if(count>1)GetSkillTargetSelCondition(positions,count,ESkill_Select_MinCurHp);
                for(uint8 i=0;i<count;++i)if(positions[i]!=target && IsAlive(positions[i])) {
                    targets.push_back(CombatTargetFacts(positions[i],src));
                    if(selector=="lowest_two_other_healed_allies" && targets.size()==2)break;
                }
                for(auto& facts:targets)facts["recipient_count"]=static_cast<int64>(targets.size());
                return targets;
            }
            if(selector=="lowest_ally_current_hp" || selector=="lowest_other_ally_current_hp" || selector=="highest_other_ally_base_attack" || selector=="highest_enemy_base_attack") {
                const auto previous=selectedRecipients.find(selector);
                if(previous!=selectedRecipients.end()) {
                    if(previous->second && IsAlive(previous->second))targets.push_back(CombatTargetFacts(previous->second,src));
                    return targets;
                }
                uint8 positions[GROUP_MEMBER],count=0;
                if(selector=="highest_enemy_base_attack")GetAnotherGroup(src,positions,count);else if(selector=="lowest_ally_current_hp")GetMeGroup(src,positions,count);else GetMeGroupExceptSelf(src,positions,count);
                if(count>1)GetSkillTargetSelCondition(positions,count,(selector=="highest_other_ally_base_attack" || selector=="highest_enemy_base_attack")?ESkill_Select_MaxDamage:ESkill_Select_MinCurHp);
                selectedRecipients[selector]=0;
                for(uint8 i=0;i<count;++i)if(IsAlive(positions[i])){selectedRecipients[selector]=positions[i];targets.push_back(CombatTargetFacts(positions[i],src));break;}
                return targets;
            }
            if(selector=="first_other_enemy" || selector=="lowest_other_enemy_current_hp") {
                uint8 positions[GROUP_MEMBER],count=0;GetAnotherGroup(src,positions,count);
                uint8 chosen=0;
                for(uint8 i=0;i<count;++i)if(positions[i]!=target && IsAlive(positions[i])) {
                    if(!chosen || GetHp(positions[i])<GetHp(chosen))chosen=positions[i];
                    if(selector=="first_other_enemy")break;
                }
                if(chosen)targets.push_back(CombatTargetFacts(chosen,src));
                return targets;
            }
            if(selector=="same_row_enemies") {
                uint8 positions[GROUP_MEMBER],count=0;GetAnotherGroup(src,positions,count);
                for(uint8 i=0;i<count;++i)if(positions[i]!=target && IsAlive(positions[i]) && (positions[i]-1)%GROUP_POS_STEP/3==(target-1)%GROUP_POS_STEP/3)targets.push_back(CombatTargetFacts(positions[i],src));
                return targets;
            }
            if(selector=="first_unstacked_enemy" || selector=="first_unstacked_susceptible_enemy") {
                const int family=static_cast<int>(event.values.at("event_stack_group"));
                if(family<=0)return targets;
                uint8 positions[GROUP_MEMBER],count=0;GetAnotherGroup(src,positions,count);
                for(uint8 i=0;i<count;++i)if(IsAlive(positions[i])) {
                    if(selector=="first_unstacked_susceptible_enemy" && GetFightMember(positions[i])->InNotEffectBuff(event.buff))continue;
                    bool occupied=false;
                    for(const auto& status:GetFightMember(positions[i])->buff_list) {
                        const auto* policy=CombatData::Current().PeriodicFor(status.id);
                        if(policy && policy->stackGroup==family){occupied=true;break;}
                    }
                    if(!occupied){targets.push_back(CombatTargetFacts(positions[i],src));break;}
                }
                return targets;
            }
            if(selector=="lowest_enemy_hp") {
                uint8 positions[GROUP_MEMBER],count=0;
                GetAnotherGroupByAttackedOrder(src,positions,count);
                if(count>1)GetSkillTargetSelCondition(positions,count,ESkill_Select_MinCurHp);
                for(uint8 i=0;i<count;++i)if(positions[i]!=target && IsAlive(positions[i])) {
                    targets.push_back(CombatTargetFacts(positions[i],src));break;
                }
                return targets;
            }
            if(selector=="highest_gear_ally") {
                uint8 best=0;int bestValue=0;
                for(int pos=event.teamActor;pos<event.teamActor+GROUP_MEMBER;++pos) {
                    const auto* ally=GetFightMember(pos);if(!ally || !IsAlive(pos))continue;
                    auto value=ally->combatLoadout.groups.find(group);
                    if(value!=ally->combatLoadout.groups.end() && value->second>bestValue){best=static_cast<uint8>(pos);bestValue=value->second;}
                }
                if(best){auto facts=CombatTargetFacts(best,src);facts["gear_value"]=bestValue;targets.push_back(facts);}
                return targets;
            }
            uint8 positions[GROUP_MEMBER], count=0;
            if(selector=="attacker") {positions[0]=static_cast<uint8>(event.values.at("attacker_position"));count=1;}
            else if (selector == "target" || selector=="target_any") { positions[0]=target; count=1; }
            else if (selector == "self" || selector=="self_any") { positions[0]=src; count=1; }
            else if (selector == "enemies") GetAnotherGroup(src,positions,count);
            else if(selector=="lowest_other_ally" || selector=="other_allies")GetMeGroupExceptSelf(src,positions,count);
            else GetMeGroup(src,positions,count);
            uint8 lowest=0;
            for (uint8 i=0;i<count;++i) {
                if (GetFightMember(positions[i]) == NULL || (!IsAlive(positions[i]) && selector!="target_any" && selector!="self_any" && !(modifiers && (selector=="target" || selector=="self")))) continue;
                if(selector=="lowest_other_ally") {
                    if(GetMaxHp(positions[i])<=0)continue;
                    if(!lowest || GetHp(positions[i])*10000/GetMaxHp(positions[i]) < GetHp(lowest)*10000/GetMaxHp(lowest))lowest=positions[i];
                } else if (selector == "lowest_ally") {
                    if (!lowest || GetHp(positions[i])*GetMaxHp(lowest) < GetHp(lowest)*GetMaxHp(positions[i])) lowest=positions[i];
                } else targets.push_back(CombatTargetFacts(positions[i],src));
            }
            if (lowest) targets.push_back(CombatTargetFacts(lowest,src));
            return targets;
        },
        [&](const CombatData::Values& facts,const CombatData::Command& command) {
            const uint8 recipient=static_cast<uint8>(facts.at("position"));
            int amount=static_cast<int>(command.value);
            if(command.op=="reserve_overheal"){reservedOverheal+=static_cast<int64>(amount)*10000;return;}
            if(command.op=="multiply_amount") {
                if(!modifiers)throw std::runtime_error("sequential multiplier has no owning operation");
                const int64 scaled=static_cast<int64>(modifiers->amount)*(10000+static_cast<int64>(amount))/10000;
                const int64 minimum=event.name=="before_stat" || event.name=="before_speed"?std::numeric_limits<int>::min():0;
                modifiers->amount=static_cast<int>(std::max<int64>(minimum,std::min<int64>(std::numeric_limits<int>::max(),scaled)));
                return;
            }
            if(command.op=="combine_remaining") {
                if(!modifiers)throw std::runtime_error("defense modifier has no owning operation");
                modifiers->amount=static_cast<int>(10000-(10000-static_cast<int64>(modifiers->amount))*(10000-amount)/10000);return;
            }
            if(command.op=="add_duration") {
                if(!modifiers)throw std::runtime_error("duration addition has no owning operation");
                modifiers->duration=static_cast<int>(std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(modifiers->duration)+amount));return;
            }
            if(command.op=="add_parameter_flat") {
                if(!modifiers)throw std::runtime_error("parameter addition has no owning operation");
                if(static_cast<size_t>(command.argument)<modifiers->parameters.size())
                    modifiers->parameters[command.argument]=static_cast<int>(std::max<int64>(std::numeric_limits<int>::min(),std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(modifiers->parameters[command.argument])+amount)));
                return;
            }
            if(command.op=="set_parameter") {
                if(!modifiers)throw std::runtime_error("parameter modifier has no owning operation");
                if(modifiers->parameters.size()<=static_cast<size_t>(command.argument))modifiers->parameters.resize(command.argument+1);
                modifiers->parameters[command.argument]=amount;return;
            }
            if(command.op=="replace_buff") {
                if(!modifiers)throw std::runtime_error("buff replacement has no owning attempt");
                modifiers->buff=command.argument;return;
            }
            if(command.op=="replace_passive_list") {
                if(!modifiers)throw std::runtime_error("passive replacement has no owning list");
                modifiers->parameters.assign(1,command.argument);return;
            }
            if(command.op=="add_amount_bonus" || command.op=="add_parameter_bonus") {
                if(!modifiers) throw std::runtime_error("combat bonus has no owning operation");
                if(command.op=="add_amount_bonus") {
                    modifiers->amountBonus+=amount;
                    if(event.name=="before_direct_damage") {
                        const auto* definition=CombatData::Current().EffectById(command.effect);
                        const bool equipment=definition && (definition->affix || event.equipmentGroups.count(definition->group));
                        modifiers->parameterBonuses[equipment?1:0]+=amount;
                    }
                }
                else modifiers->parameterBonuses[command.argument]+=amount;
                return;
            }
            if(command.op=="shield") {
                const int64 raw=static_cast<int64>(amount)*10000+command.fraction;
                const auto* definition=CombatData::Current().EffectById(command.effect);
                const int presentation=definition && definition->presentationSkill>=0?definition->presentationSkill:skill;
                const int origin=definition && definition->originSkill>=0?definition->originSkill:presentation;
                const int originLevel=definition && definition->originLevel?definition->originLevel:level;
                auto& grant=shields[recipient];
                if(grant.amount && (grant.originSkill!=origin || grant.originLevel!=originLevel || grant.presentation!=presentation))
                    throw std::runtime_error("incompatible merged shield origin");
                if(grant.amount && grant.emitAction!=(definition?definition->emitAction:true))throw std::runtime_error("incompatible merged shield presentation");
                grant.amount+=raw;grant.duration=std::max(grant.duration,command.duration);
                grant.originSkill=origin;grant.originLevel=originLevel;grant.presentation=presentation;
                grant.emitAction=definition?definition->emitAction:true;
                if(definition && definition->basis=="overheal")overhealShields[recipient]+=raw;
                return;
            }
            if (command.op == "scale_amount" || command.op == "set_duration" || command.op == "scale_parameters") {
                if (modifiers == NULL) throw std::runtime_error("combat modifier has no owning battle operation");
                if (command.op == "scale_amount") modifiers->amount=amount;
                else if (command.op == "set_duration") modifiers->duration=amount;
                else for (auto& value : modifiers->parameters) value=static_cast<int>(static_cast<int64>(value)*amount/10000);
                return;
            }
            if(command.op=="promote_buff") {
                const auto* definition=CombatData::Current().EffectById(command.effect);
                if(IsAlive(recipient))for(auto& active:GetFightMember(recipient)->buff_list)
                    if(active.id==command.argument && active.originSkill==definition->originSkill && !active.paraList.empty()) {
                        active.paraList[0]=static_cast<int>(std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(active.paraList[0])+amount));
                        active.originSkill=static_cast<uint16>(definition->presentationSkill);break;
                    }
                return;
            }
            if(command.op=="cleanse" || command.op=="dispel") {
                if(IsAlive(recipient) && amount>0) {
                    if(command.op=="cleanse")ClearRandomDeBuff(recipient,static_cast<uint16>(std::min(65535,amount)),src,skill);
                    else ClearRandomEnBuff(recipient,static_cast<uint16>(std::min(65535,amount)),src,skill);
                }
                return;
            }
            if(command.op=="apply_skill_passives") {
                if(IsAlive(recipient)) {
                    std::vector<ESkillTriggerType> triggers(1,ESkill_Trigger_Attacking);
                    CalculatePassiveSkill_ExtUnitAndBuff(src,recipient,triggers,command.argument,std::max(1,static_cast<int>(member->GetSkillLevel(command.argument))),amount);
                }
                return;
            }
            if(command.op=="strike") {
                if(!IsAlive(recipient))return;
                struct RestoreType {int& value;int old;~RestoreType(){value=old;}} restore{member->attackType,member->attackType};
                if(command.argument)member->attackType=command.argument;
                std::vector<SAttrData> attributes,defense;
                attributes.push_back(SAttrData(ESkill_PassAttr_DamagePer,amount-10000));
                amount=CalculateDamage(src,recipient,attributes,defense);
                if(amount<=0)return;
            }
            if(command.op=="consume_periodic") {
                if(!IsAlive(recipient))return;
                auto& statuses=GetFightMember(recipient)->buff_list;bool removed=false;
                for(auto it=statuses.begin();it!=statuses.end();++it)if(it->id==command.argument && it->srcPos==src && !it->paraList.empty()) {
                    statuses.erase(it);removed=true;
                    if(!HaveBuff(recipient,command.argument))SpecialBuffPassAttr(recipient,command.argument,false);
                    break;
                }
                if(!removed || amount<=0)return;
            }
            if(command.op=="trigger_periodic") {
                if(!IsAlive(recipient))return;
                SFightBuffData chosen;bool found=false;int64 raw=0;
                for(const auto& active:GetFightMember(recipient)->buff_list)if(active.id==command.argument) {
                    if(!found){chosen=active;found=true;}
                    raw+=CombatPeriodicRaw(recipient,active,0);
                }
                if(!found)return;
                const int tick=CombatPeriodicValue(chosen.srcPos,recipient,chosen,0,raw);
                amount=static_cast<int>(std::max<int64>(0,std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(tick)*amount/10000)));
                if(amount<=0)return;
            }
            if(command.op=="extend_owned_buff" || command.op=="extend_origin_buffs") {
                for(auto& active:GetFightMember(recipient)->buff_list)if(active.srcPos==src && (command.op=="extend_origin_buffs"?active.originSkill==command.argument:active.id==command.argument && active.leftTurn>0))
                    active.leftTurn=static_cast<int>(std::min<int64>(command.duration,static_cast<int64>(active.leftTurn)+amount));
                return;
            }
            // A scope guard prevents secondary damage/healing from recursively
            // dispatching content events, including on exceptional exits.
            const auto* definition=CombatData::Current().EffectById(command.effect);
            std::vector<int> effectParameters=command.parameters;
            if(definition && definition->queryEffect) {
                if(definition->checkSkillImmunity && GetFightMember(recipient)->InNotEffectBuff(command.argument)) {
                    const auto* policy=CombatData::Current().ControlFor(command.argument);
                    if(!policy || policy->bossMode!="replace" || !CombatBoss(recipient))return;
                }
                const auto* sourceEffect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(definition->queryEffect);
                if(!sourceEffect || static_cast<size_t>(definition->queryParameter)>=effectParameters.size())throw std::runtime_error("invalid loaded passive parameter source");
                std::vector<ESkillTriggerType> triggers(1,static_cast<ESkillTriggerType>(sourceEffect->trigger));std::vector<SAttrData> attributes;
                const int queriedSkill=definition->presentationSkill>=0?definition->presentationSkill:skill;
                CalculatePassiveSkill_ExtValue(src,0,triggers,attributes,queriedSkill,definition->queryLevel?definition->queryLevel:level);
                effectParameters[definition->queryParameter]=GetAttrValue(attributes,definition->queryAttribute);
            }
            CombatData::ScopedDepth secondary(m_combatDepth);
            if (command.op == "rage") { AddTeamRage(recipient,amount); return; }
            if (command.op == "cooldown") {
                if(definition && definition->argumentRole=="all"){member->DecAllSkillCD(amount);return;}
                int skill=command.argument;
                if(definition && definition->argumentRole!="fixed") {
                    const auto* role=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(GetHeroId(src));
                    skill=role?(definition->argumentRole=="regular"?role->regularSkillId:role->tacticSkillId):0;
                }
                if(skill)member->DecSkillCD(skill,amount);return;
            }
            if(command.op=="extend_buff") {
                for(auto& buff:GetFightMember(recipient)->buff_list)if(buff.id==command.argument)
                    buff.leftTurn=static_cast<int>(std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(buff.leftTurn)+amount));
                return;
            }
            const bool allowsDead=definition && (command.op=="buff" || command.op=="copy_buff" || command.op=="heal" || command.op=="restore_hp" || command.op=="damage") && (definition->target=="self_any" || definition->target=="target_any");
            if (!IsAlive(recipient) && !allowsDead) return;
            const int64 before=GetHp(recipient);
            const uint16 presentation=definition && definition->presentationSkill>=0 ? static_cast<uint16>(definition->presentationSkill) : skill;
            int absorption=0, revived=0, delta=0;
            const bool passiveDamage=command.op=="passive_damage" || command.op=="strike" || command.op=="consume_periodic" || command.op=="trigger_periodic";
            if (command.op == "damage" || passiveDamage || command.op == "heal" || command.op=="split_heal" || command.op=="restore_hp") {
                int value=amount;
                if (command.op == "heal" || command.op=="split_heal") value=-static_cast<int>(static_cast<int64>(amount)*std::max(0,10000-GetStatePara1(recipient,ESBUFF_JinLiaoShu))/10000);
                if(command.op=="restore_hp")value=-amount;
                const bool damage=command.op=="damage" || passiveDamage;
                DecreaseHp(recipient,src,value,absorption,!damage,&revived,!passiveDamage);
                delta=static_cast<int>(GetHp(recipient)-before);
                if(m_combatObserver && definition && presentation && (delta || absorption || revived))
                    m_combatObserver(src,damage?"data_damage_applied":"data_heal_applied",presentation,command.effect);
                if(!delta && !absorption && !passiveDamage)return;
                if (!IsAlive(recipient) && !passiveDamage) member->AddKillUnit(recipient);
            } else if (command.op == "buff" || command.op=="copy_buff") {
                if ((!definition || definition->checkSkillImmunity) && GetFightMember(recipient)->InNotEffectBuff(command.argument)) {
                    const auto* policy=CombatData::Current().ControlFor(command.argument);
                    if(!policy || policy->bossMode!="replace" || !CombatTargetFacts(recipient).at("target_boss"))return;
                }
                std::vector<int> parameters=effectParameters;
                const uint16 origin=definition && definition->originSkill>=0?static_cast<uint16>(definition->originSkill):presentation;
                AddBuff(recipient,src,command.argument,command.duration,&parameters,origin,definition && definition->originLevel?definition->originLevel:level,command.effect);
            }
            if(definition && !definition->emitAction)return;
            m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
            m_extActionMsg << (uint8)EFOT_Passive << src << presentation << string("") << (uint8)1;
            m_extActionMsg << recipient << delta << absorption << revived;
            MakeBuffList(recipient,m_extActionMsg);
            if (command.op == "damage" || passiveDamage) {
                ShieldBrokenCheck(recipient,src);
                // Original helpers measure after serialization and shield-loss
                // callbacks, whose nested recovery may offset this target's loss.
                actualHpLoss+=std::max<int64>(0,before-GetHp(recipient));
            }
        },[&](const std::string& budget) { return budget=="none" || CombatTryExtraAttack(src); },[&]() {return actualHpLoss;});
    if(modifiers) {
        auto scale=[](int value,int64 bonus) { return static_cast<int>(std::max<int64>(std::numeric_limits<int>::min(),std::min<int64>(std::numeric_limits<int>::max(),static_cast<int64>(value)*(10000+bonus)/10000))); };
        for(const auto& bonus:modifiers->parameterBonuses) if(bonus.first>=0 && static_cast<size_t>(bonus.first)<modifiers->parameters.size())
            modifiers->parameters[bonus.first]=scale(modifiers->parameters[bonus.first],bonus.second);
    }
    for(const auto& grant:shields) {
        if(!IsAlive(grant.first)) continue;
        const int64 excess=std::max<int64>(0,overhealShields[grant.first]-std::max<int64>(0,overhealLimit-reservedOverheal));
        const int64 whole=(grant.second.amount-excess)/10000;
        if(whole<=0)continue;
        CombatData::ScopedDepth secondary(m_combatDepth);
        std::vector<int> parameters(2,static_cast<int>(std::min<int64>(whole,std::numeric_limits<int>::max())));
        AddBuff(grant.first,src,ESBUFF_Shield,grant.second.duration,&parameters,static_cast<uint16>(grant.second.originSkill),grant.second.originLevel);
        if(!grant.second.emitAction)continue;
        m_extActionMsg.SetType(m_extActionMsg.GetType()+1);
        m_extActionMsg << (uint8)EFOT_Passive << src << static_cast<uint16>(grant.second.presentation) << string("") << (uint8)1;
        m_extActionMsg << grant.first << (int)0 << (int)0 << (int)0;
        MakeBuffList(grant.first,m_extActionMsg);
    }
}

void CFight::CombatSortTargets(uint8 source,uint16 skill,uint8* positions,uint8 count,bool allies)
{
    if(!positions || count<=1)return;
    const auto* role=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(GetHeroId(source));
    const std::string skillRole=role && skill==role->tacticSkillId?"tactic":role && skill==role->regularSkillId?"regular":"other";
    const auto* policy=CombatData::Current().TargetPolicyFor(GetFightMember(source)->combatStrategy,allies,skillRole);
    if(!policy)return;
    auto dots=[&](uint8 target){int result=0;for(const auto& buff:GetFightMember(target)->buff_list)
        if(buff.srcPos==source && std::find(policy->buffs.begin(),policy->buffs.end(),buff.id)!=policy->buffs.end())++result;return result;};
    std::stable_sort(positions,positions+count,[&](uint8 a,uint8 b) {
        if(policy->order=="unshielded_lowest_hp" && HaveShieldState(a)!=HaveShieldState(b))return !HaveShieldState(a);
        if(policy->order=="lowest_hp" || policy->order=="unshielded_lowest_hp") {
            const int64 left=GetHp(a)*GetMaxHp(b),right=GetHp(b)*GetMaxHp(a);if(left!=right)return left<right;
        }else if(policy->order=="highest_attack") {
            const int left=GetUnitAttack(a),right=GetUnitAttack(b);if(left!=right)return left>right;
        }else {const int left=dots(a),right=dots(b);if(left!=right)return policy->order=="most_owned_dots"?left>right:left<right;}
        return policy->tie=="position_desc"?a>b:a<b;
    });
}

uint16 CFight::CombatStrategySkill(uint8 pos,const HeroSkillRoleCfg& role)
{
    SFightMember* member=GetFightMember(pos);
    CSkillMgr& manager=SingletonCSkillMgr::instance();
    auto active=[&](int skill)->SSkillActiveEffect* {
        SSkillCfgData* cfg=manager.GetSkillCfg(skill);
        return cfg ? manager.GetActiveEffectCfg(cfg->activeEffect.GetEffectId()) : NULL;
    };
    auto healing=[](SSkillActiveEffect* effect) {
        return effect && (effect->effect_type==ESkill_Active_AddHpByDam || effect->effect_type==ESkill_Active_AddHpNormal);
    };
    auto reviving=[](SSkillActiveEffect* effect) { return effect && effect->effect_type==ESkill_Active_FuHuo; };
    auto controlled=[&](uint8 target) {
        for (const auto& buff:GetFightMember(target)->buff_list) if(IsAffixHardControl(buff.id)) return true;
        return false;
    };
    SSkillActiveEffect* regular=active(role.regularSkillId);
    SSkillActiveEffect* tactic=active(role.tacticSkillId);
    CombatData::Values facts={
        {"regular_heals",healing(regular)}, {"regular_revives",reviving(regular)},
        {"tactic_heals",healing(tactic)}, {"tactic_revives",reviving(tactic)},
        {"regular_targets",regular ? regular->target_num : 0}, {"tactic_targets",tactic ? tactic->target_num : 0},
        {"allies_dead",CombatHaveReviveTarget(pos)}, {"allies_low",0},
        {"lowest_ally_hp_bp",10000}, {"lowest_ally_protected",0},
        {"source_hp_bp",GetMaxHp(pos)>0 ? GetHp(pos)*10000/GetMaxHp(pos) : 0},
        {"enemies_untaunted",0}, {"highest_enemy_controlled",1}, {"highest_enemy_resistance_down",0},
        {"highest_enemy_boss",0}, {"lowest_enemy_hp_bp",10000}, {"enemy_exposed",0}, {"enemy_dots",0}
    };
    uint8 allies[GROUP_MEMBER],enemies[GROUP_MEMBER],allyCount=0,enemyCount=0,highest=0;
    GetMeGroup(pos,allies,allyCount); GetAnotherGroup(pos,enemies,enemyCount);
    for(uint8 i=0;i<allyCount;++i) {
        const uint8 target=allies[i];
        const int64 ratio=GetMaxHp(target)>0 ? GetHp(target)*10000/GetMaxHp(target) : 0;
        if(ratio < CombatData::Current().Rule("strategy_injured_hp_bp")) ++facts["allies_low"];
        if(ratio < facts["lowest_ally_hp_bp"]) {
            facts["lowest_ally_hp_bp"]=ratio;
            facts["lowest_ally_protected"]=HaveShieldState(target) || HaveBuff(target,ESBUFF_Protect);
        }
    }
    for(uint8 i=0;i<enemyCount;++i) {
        const uint8 target=enemies[i];
        if(!highest || GetUnitAttack(target)>GetUnitAttack(highest)) highest=target;
        if(!HaveBuff(target,ESBUFF_ChaoFeng)) ++facts["enemies_untaunted"];
        if(GetMaxHp(target)>0) facts["lowest_enemy_hp_bp"]=std::min<int64>(facts["lowest_enemy_hp_bp"],GetHp(target)*10000/GetMaxHp(target));
        if(HaveBuff(target,ESBUFF_GetDamageAdd) || HaveBuff(target,ESBUFF_GetWuDamageAdd) || HaveBuff(target,ESBUFF_GetFaDamageAdd)
            || HaveBuff(target,ESBUFF_FaFangDes) || HaveBuff(target,ESBUFF_WuFangDes)) facts["enemy_exposed"]=1;
        int ownedDots=0;
        for(const auto& buff:GetFightMember(target)->buff_list)
            if(buff.srcPos==pos && (buff.id==ESBUFF_ShiDu || buff.id==ESBUFF_FuDu || buff.id==ESBUFF_ShiXinDu || buff.id==ESBUFF_ZhuoShao || buff.id==ESBUFF_Blooding)) ++ownedDots;
        facts["enemy_dots"]=std::max<int64>(facts["enemy_dots"],ownedDots);
    }
    if(highest) {
        facts["highest_enemy_controlled"]=controlled(highest);
        facts["highest_enemy_resistance_down"]=HaveBuff(highest,ESBUFF_FuMianKangDes);
        SMonsterInst* monster=GetMonster(highest);
        facts["highest_enemy_boss"]=GetFightMember(highest)->isWorldBoss || (monster && monster->type==EMTTongLing);
    }
    const CombatData::Strategy* choice=CombatData::Current().ChooseStrategy(member->combatStrategy,GetTeamRage(pos),GetTacticCost(pos,role),facts,
        [&](const std::string& candidate) {
            if(candidate=="normal") return true;
            const uint16 skill=candidate=="tactic" ? role.tacticSkillId : role.regularSkillId;
            return member->CanUseSkill(skill) && (candidate=="regular_ready" || IsRoleSkillUseful(pos,skill));
        });
    if(!choice || choice->role=="normal") return 0;
    return choice->role=="tactic" ? role.tacticSkillId : role.regularSkillId;
}

// No SQLite, network listener or player save is opened by this test entry.
// It runs the same CFight adapter, HP mutation and buff paths used in battle.
bool CFight::RunCombatDataRegression(bool probeOnly)
{
    std::srand(1729);
    if (!SingletonCSkillMgr::instance().Init() || !sCItemCfgManager.InitEquipAffixCfg() || !sCItemCfgManager.InitSuitAttrCfg()) return false;
    const char* binaryDiffMode=std::getenv("HERO_AFFIX_BINARY_DIFF");
    if(binaryDiffMode && std::string(binaryDiffMode)=="1") {
#include "../tests/HeroAffixBinaryDiff.inc"
    }
    {
        // A shield query must inspect the two shield IDs only. The legacy
        // byte-count loop read two entries beyond its uint16 array.
        CFight shieldQuery;
        SharePetPtr queryPet(new SPet);queryPet->ClearSkill();
        shieldQuery.m_members[0].memPtr=queryPet;shieldQuery.m_members[0].type=EFMT_PET;
        if(shieldQuery.HaveShieldState(0) || shieldQuery.HaveShieldState(MAX_MEMBER+1)
            || shieldQuery.HaveZhongDuState(0) || shieldQuery.HaveZhongDuState(MAX_MEMBER+1))return false;
        for(unsigned id=1;id<=65535;++id) {
            shieldQuery.m_members[0].buff_list.clear();
            SFightBuffData buff;buff.id=static_cast<uint16>(id);
            shieldQuery.m_members[0].buff_list.push_back(buff);
            const bool expected=id==ESBUFF_Shield || id==ESBUFF_ShieldMianShang;
            const bool poison=id==ESBUFF_ShiXinDu || id==ESBUFF_ShiDu || id==ESBUFF_FuDu;
            if(shieldQuery.HaveShieldState(1)!=expected || shieldQuery.HaveZhongDuState(1)!=poison) {
                std::cerr<<"FAIL shield/poison query buff ID "<<id<<std::endl;return false;
            }
        }
        shieldQuery.m_members[0].buff_list.clear();
        if(shieldQuery.HaveShieldState(1) || shieldQuery.HaveZhongDuState(1))return false;
        std::cout<<"PASS shield/poison query: all 65535 buff IDs, empty and invalid positions"<<std::endl;
    }
    const auto* suitBase=sCItemCfgManager.GetSuitAttr(1);
    const int baseSuitCounter=suitBase && suitBase->cntAttrs.count(2) ? suitBase->cntAttrs.at(2).front().attrValue : 0;
    const int staleSuitTiers=suitBase?static_cast<int>(suitBase->cntAttrs.count(3)+suitBase->cntAttrs.count(4)):0;
    CFight fight;
    auto unit=[&](uint8 pos,int hero,int branch,int hp) {
        SharePetPtr pet(new SPet); pet->ClearSkill();pet->id=hero;
        SFightMember& m=fight.m_members[pos-1]; m.memPtr=pet; m.type=EFMT_PET;
        m.unitAttr.maxHp=10000; m.unitAttr.attack=10000; m.hp=hp; m.level=1; m.combatBranch=branch;
    };
    unit(1,10,1,10000); unit(2,23,0,4000); unit(GROUP2_BEGIN+1,23,0,10000);
    fight.CombatAfterHeal(1,2,101,1,3000,1000,true);
    const int shield=fight.GetStatePara1(2,ESBUFF_Shield);
    const int sourceShield=fight.GetStatePara1(1,ESBUFF_Shield);
    const int targetHp=static_cast<int>(fight.GetHp(2));
    fight.m_members[0].combatBranch=2;
    SSkillData revive(102,1); revive.leftCD=6; revive.CD=6; fight.m_members[0].skill_list.push_back(revive);
    for (int i=0;i<4;++i) fight.CombatAfterHeal(1,2,101,1,1000,0,true);
    const int rage=fight.GetTeamRage(1), cooldown=fight.m_members[0].skill_list[0].leftCD;
    fight.m_fightTurn++;
    fight.CombatAfterHeal(1,2,101,1,1000,0,true);
    const int nextRage=fight.GetTeamRage(1);
    fight.m_members[0].combatBranch=1;
    fight.CombatAfterHeal(1,2,102,1,0,0,false);
    const int guard=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
    unit(3,15,2,10000);
    fight.CombatEvent("after_primary_hit",3,GROUP2_BEGIN+1,151,0,1,{{"amount",1000},{"event_target_alive",1}});
    const int pursuit=10000-static_cast<int>(fight.GetHp(GROUP2_BEGIN+1));
    fight.CombatEvent("after_primary_hit",3,GROUP2_BEGIN+1,151,0,1,{{"amount",1000},{"event_target_alive",1}});
    const int repeated=10000-static_cast<int>(fight.GetHp(GROUP2_BEGIN+1));
    unit(4,61,1,10000);
    std::vector<int> parameters(1,1000);
    fight.AddBuff(GROUP2_BEGIN+1,4,ESBUFF_ChaoFeng,1,&parameters,612);
    int control=0; for (const auto& b: fight.m_members[GROUP2_BEGIN].buff_list) if(b.id==ESBUFF_ChaoFeng) control=b.leftTurn;
    unit(5,65,1,10000);
    fight.AddBuff(GROUP2_BEGIN+1,5,ESBUFF_ShiDu,1,&parameters,651);
    const int poison=fight.GetStatePara1(GROUP2_BEGIN+1,ESBUFF_ShiDu);
    unit(6,12,2,10000);
    const int64 before=fight.GetHp(GROUP2_BEGIN+1);
    fight.m_members[1].buff_list.clear();
    parameters.assign(2,1000); fight.AddBuff(2,6,ESBUFF_Shield,2,&parameters,121);
    int hit=1000,absorption=0; fight.DecreaseHp(2,GROUP2_BEGIN+1,hit,absorption);
    fight.ShieldBrokenCheck(2,GROUP2_BEGIN+1);
    const int explosion=static_cast<int>(before-fight.GetHp(GROUP2_BEGIN+1));
    HeroSkillRoleCfg* role=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(15);
    if(!role) return false;
    fight.m_members[2].skill_list.push_back(SSkillData(role->regularSkillId,1));
    fight.m_members[2].skill_list.push_back(SSkillData(role->tacticSkillId,1));
    fight.m_members[2].combatStrategy=4;
    fight.m_members[GROUP2_BEGIN].hp=1000;
    fight.m_teamRage[0]=fight.GetTacticCost(3,*role)+20;
    const int strategySkill=fight.GetUnitAISkillId(3);
    const int tacticSkill=role->tacticSkillId, regularSkill=role->regularSkillId;
    // Shared rules apply to branch zero and both teams. Exercise real AddBuff
    // replacement, capacity and per-source stack ownership, not catalog math.
    for(auto& member:fight.m_members) { member.buff_list.clear(); member.combatBranch=0; }
    fight.m_members[GROUP2_BEGIN].hp=10000;
    parameters.assign(2,6000);
    fight.AddBuff(2,1,ESBUFF_Shield,2,&parameters);
    const int ruleShieldCap=fight.GetStatePara1(2,ESBUFF_Shield);
    parameters.assign(2,2000);
    fight.AddBuff(2,1,ESBUFF_Shield,2,&parameters);
    const int ruleShieldRefresh=fight.GetStatePara1(2,ESBUFF_Shield);
    parameters.assign(2,6000);
    fight.AddBuff(2,3,ESBUFF_Shield,2,&parameters);
    const int ruleShieldTotal=fight.GetStatePara1(2,ESBUFF_Shield);
    fight.AddBuff(GROUP2_BEGIN+1,GROUP2_BEGIN+1,ESBUFF_Shield,2,&parameters);
    const int enemyShield=fight.GetStatePara1(GROUP2_BEGIN+1,ESBUFF_Shield);
    parameters.assign(1,100);
    for(int i=0;i<6;++i) fight.AddBuff(GROUP2_BEGIN+1,1,i%2 ? ESBUFF_FuDu : ESBUFF_ShiDu,7,&parameters);
    auto countPoison=[&](uint8 source) {
        int count=0;
        for(const auto& buff:fight.m_members[GROUP2_BEGIN].buff_list)
            if((!source || buff.srcPos==source) && (buff.id==ESBUFF_FuDu || buff.id==ESBUFF_ShiDu)) ++count;
        return count;
    };
    const int ruleDotStacks=countPoison(1);
    int ruleDotDuration=0;
    for(const auto& buff:fight.m_members[GROUP2_BEGIN].buff_list)
        if(buff.id==ESBUFF_FuDu || buff.id==ESBUFF_ShiDu) ruleDotDuration=std::max(ruleDotDuration,buff.leftTurn);
    fight.AddBuff(GROUP2_BEGIN+1,3,ESBUFF_ShiDu,7,&parameters);
    const int ruleDotSources=countPoison(0);
    fight.AddTeamRage(1,std::numeric_limits<int>::max(),false);
    fight.AddTeamRage(GROUP2_BEGIN+1,std::numeric_limits<int>::max(),false);
    const int ruleRageCap=fight.GetTeamRage(1), enemyRageCap=fight.GetTeamRage(GROUP2_BEGIN+1);
    fight.m_members[1].buff_list.clear();
    fight.m_members[0].combatBranch=1;
    fight.m_members[0].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(5)->passiveSkillId,3));
    fight.CombatAfterHeal(1,2,101,1,3000,1000,true);
    fight.m_members[0].passive_skill.pop_back();
    const int combinedShield=fight.GetStatePara1(2,ESBUFF_Shield);
    for(auto& member:fight.m_members) { member.buff_list.clear(); member.combatBranch=0; }
    fight.m_members[0].unitAttr.attack=100; fight.m_members[2].unitAttr.attack=100;
    const uint8 enemy=GROUP2_BEGIN+1,otherEnemy=GROUP2_BEGIN+2;
    unit(otherEnemy,23,0,10000);
    fight.m_members[enemy-1].hp=10000; ++fight.m_fightTurn;
    parameters={120,0}; fight.AddBuff(enemy,1,ESBUFF_ShiDu,3,&parameters); fight.AddBuff(otherEnemy,1,ESBUFF_ShiDu,3,&parameters);
    parameters={80,0}; fight.AddBuff(enemy,3,ESBUFF_ShiDu,3,&parameters); fight.AddBuff(otherEnemy,3,ESBUFF_ShiDu,3,&parameters);
    const int periodicEvents=fight.UnitPassiveAction(enemy,EFStep_UserActBegin,fight.m_extActionMsg,0);
    const int periodicDamage=10000-static_cast<int>(fight.GetHp(enemy));
    fight.UnitPassiveAction(otherEnemy,EFStep_UserActBegin,fight.m_extActionMsg,0);
    const int periodicRemaining=10000-static_cast<int>(fight.GetHp(otherEnemy));
    ++fight.m_fightTurn;
    const int64 beforeNext=fight.GetHp(enemy);
    fight.UnitPassiveAction(enemy,EFStep_UserActBegin,fight.m_extActionMsg,0);
    const int periodicNext=static_cast<int>(beforeNext-fight.GetHp(enemy));
    fight.m_members[enemy-1].buff_list.clear(); ++fight.m_fightTurn;
    parameters={100}; fight.AddBuff(enemy,1,ESBUFF_Blooding,3,&parameters);
    parameters={1}; fight.AddBuff(enemy,3,ESBUFF_DamagePercentDes,3,&parameters);
    const int64 beforeBleed=fight.GetHp(enemy);
    fight.UnitPassiveAction(enemy,EFStep_UserActBegin,fight.m_extActionMsg,0);
    const int periodicBleed=static_cast<int>(beforeBleed-fight.GetHp(enemy));
    fight.m_members[enemy-1].buff_list.clear(); fight.m_members[enemy-1].hp=5000;
    parameters={200}; fight.AddBuff(enemy,1,ESBUFF_AddHpContinue,3,&parameters);
    parameters={100}; fight.AddBuff(enemy,3,ESBUFF_AddHpContinue,3,&parameters);
    parameters={5000,0}; fight.AddBuff(enemy,3,ESBUFF_JinLiaoShu,3,&parameters);
    fight.UnitPassiveAction(enemy,EFStep_UserActBegin,fight.m_extActionMsg,0);
    const int periodicHeal=static_cast<int>(fight.GetHp(enemy))-5000;
    for(auto& member:fight.m_members) { member.buff_list.clear(); member.combatBranch=0; }
    fight.m_combatState=CombatData::State(); fight.m_fightTurn=10;
    parameters={1000};
    auto lastDuration=[&](uint8 target,uint16 buff) {
        int result=0; for(const auto& b:fight.m_members[target-1].buff_list) if(b.id==buff) result=b.leftTurn; return result;
    };
    fight.AddBuff(enemy,1,ESBUFF_ChaoFeng,4,&parameters,612);
    const int controlFirst=lastDuration(enemy,ESBUFF_ChaoFeng);
    fight.AddBuff(enemy,1,ESBUFF_ChaoFeng,4,&parameters,612);
    const int controlSecond=lastDuration(enemy,ESBUFF_ChaoFeng);
    fight.AddBuff(enemy,1,ESBUFF_ChaoFeng,6,&parameters,612);
    const int controlThird=lastDuration(enemy,ESBUFF_ChaoFeng);
    fight.AddBuff(enemy,3,ESBUFF_ChenMo,4,&parameters,622);
    const int controlIndependent=lastDuration(enemy,ESBUFF_ChenMo);
    ++fight.m_fightTurn;
    fight.AddBuff(enemy,1,ESBUFF_ChaoFeng,4,&parameters,612);
    const int controlReset=lastDuration(enemy,ESBUFF_ChaoFeng);
    fight.m_members[otherEnemy-1].isWorldBoss=true;
    fight.AddBuff(otherEnemy,1,ESBUFF_ChaoFeng,4,&parameters,612);
    fight.AddBuff(otherEnemy,3,ESBUFF_ChenMo,4,&parameters,622);
    int bossCount=0;
    for(const auto& b:fight.m_members[otherEnemy-1].buff_list) if(b.id==ESBUFF_SpeedDes) ++bossCount;
    const int bossSlow=fight.GetStatePara1(otherEnemy,ESBUFF_SpeedDes);
    fight.AddBuff(otherEnemy,1,ESBUFF_ForbidFuHuo,2,&parameters,682);
    const int bossForbid=fight.HaveBuff(otherEnemy,ESBUFF_ForbidFuHuo) ? 1 : 0;
    auto kill=[&]() { int damage=100000,absorbed=0; fight.DecreaseHp(2,enemy,damage,absorbed,true); };
    auto reviveBy=[&](uint8 src) { int heal=-1000,absorbed=0; fight.DecreaseHp(2,src,heal,absorbed,true); return static_cast<int>(fight.GetHp(2)); };
    kill(); const int reviveFirst=reviveBy(1);
    const int reviveExtra=fight.CombatTryExtraAttack(2) ? 1 : 0;
    kill(); const int reviveSame=reviveBy(1);
    unit(7,23,0,0); fight.SetState(7,EFST_STATE_Die);
    uint8 reviveTargets[MAX_MEMBER],reviveCount=0;
    fight.GetSkillTargetRange(1,102,1,reviveTargets,reviveCount);
    const int reviveEligibleTarget=reviveCount==1 ? reviveTargets[0] : 0;
    fight.ClearState(7,EFST_STATE_Die); fight.m_members[6].hp=10000;
    const int reviveOther=reviveBy(3);
    kill(); const int reviveThird=reviveBy(4);
    int extras=0,enemyExtras=0;
    for(int i=0;i<5;++i) { if(fight.CombatTryExtraAttack(1)) ++extras; if(fight.CombatTryExtraAttack(enemy)) ++enemyExtras; }
    ++fight.m_fightTurn;
    const int extraNext=fight.CombatTryExtraAttack(1) ? 1 : 0;
    fight.m_members[0].combatBranch=1;
    fight.m_combatDepth=1;
    fight.CombatAfterHeal(1,enemy,101,1,3000,1000,true);
    const int nestedShield=fight.GetStatePara1(enemy,ESBUFF_Shield);
    fight.m_combatDepth=0;
    fight.m_members[5].combatBranch=2;
    parameters.assign(2,1000);
    fight.AddBuff(otherEnemy,6,ESBUFF_Shield,1,&parameters,121);
    const int64 beforeExpiry=fight.GetHp(enemy);
    fight.DecAllStateEffectTurn(otherEnemy);
    const int expiryDamage=static_cast<int>(beforeExpiry-fight.GetHp(enemy));
    fight.AddBuff(otherEnemy,6,ESBUFF_Shield,2,&parameters,121);
    const int64 beforeDispel=fight.GetHp(enemy);
    fight.ClearBuff(otherEnemy,ESBUFF_Shield);
    const int dispelDamage=static_cast<int>(beforeDispel-fight.GetHp(enemy));
    fight.Clear();
    unit(1,10,0,10000); unit(2,23,0,5000); unit(3,23,0,5000); unit(enemy,23,0,10000);
    auto artifact=[](int slot,int id,uint32 instance){CombatData::WornItem w;w.slot=slot;w.id=id;w.instance=instance;w.artifact=true;return w;};
    auto equip=[](int slot,int suit,int part,uint32 instance){CombatData::WornItem w;w.slot=slot;w.suit=suit;w.part=part;w.instance=instance;return w;};
    const auto& catalog=CombatData::Current();
    auto chosen=catalog.Snapshot({artifact(5,1403,51),artifact(6,1010,61)});
    const int chosenArtifact=chosen.artifacts.at("artifact_mechanism");
    const int tieArtifact=catalog.Snapshot({artifact(6,1410,61),artifact(5,1403,51)}).artifacts.at("artifact_mechanism");
    const int selectedGroups=static_cast<int>(catalog.Snapshot({artifact(5,1003,51),artifact(6,1401,61)}).groups.size());
    auto duplicate=catalog.Snapshot({equip(1,9,1,1),equip(2,9,2,1),equip(3,9,4,3)});
    const int validPieces=duplicate.pieces.at(9);
    fight.m_members[0].combatLoadout=chosen;
    fight.CombatAfterHeal(1,2,102,1,0,0,false);
    const int artifactGuard=fight.GetStatePara1(2,ESBUFF_JianShangLvAdd);
    fight.ClearBuff(2,ESBUFF_JianShangLvAdd);
    fight.CombatAfterHeal(1,2,102,1,0,0,false);
    const int repeatedGuard=fight.GetStatePara1(2,ESBUFF_JianShangLvAdd);
    fight.CombatAfterHeal(1,3,102,1,0,0,false);
    const int secondGuard=fight.GetStatePara1(3,ESBUFF_JianShangLvAdd);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1410,51)});
    parameters.assign(2,0);parameters[0]=1000;
    fight.AddBuff(enemy,1,ESBUFF_ShiDu,2,&parameters,651);
    CNetMessage gearPeriodic;
    fight.CombatPeriodicActions(enemy,EFStep_UserActBegin,gearPeriodic,0);
    const int artifactDot=static_cast<int>(10000-fight.GetHp(enemy));
    fight.m_members[0].passive_skill.push_back(SSkillData(5035,3));
    ++fight.m_fightTurn;
    const int combinedBefore=static_cast<int>(fight.GetHp(enemy));
    fight.CombatPeriodicActions(enemy,EFStep_UserActBegin,gearPeriodic,0);
    const int artifactAffixDot=combinedBefore-static_cast<int>(fight.GetHp(enemy));
    fight.ClearBuff(enemy,ESBUFF_ShiDu);
    parameters.assign(2,0);parameters[1]=1000;
    fight.AddBuff(enemy,1,ESBUFF_JinGuZhou,2,&parameters,651);
    ++fight.m_fightTurn;
    const int jinguBefore=static_cast<int>(fight.GetHp(enemy));
    fight.CombatPeriodicActions(enemy,EFStep_UserActBegin,gearPeriodic,0);
    const int artifactExcluded=jinguBefore-static_cast<int>(fight.GetHp(enemy));
    fight.m_members[0].passive_skill.clear();
    fight.m_members[0].combatLoadout=catalog.Snapshot({equip(1,9,1,1),equip(2,9,2,2)});
    parameters.assign(2,1000);fight.AddBuff(2,1,ESBUFF_Shield,2,&parameters,121);
    const int setShield=fight.GetStatePara1(2,ESBUFF_Shield);
    fight.Clear();unit(1,10,0,10000);unit(2,23,0,1000);unit(enemy,23,0,10000);
    fight.m_members[0].unitAttr.attack=1000;
    fight.CalculateSkill_AddHp(1,101,1);
    const int activeHealBase=static_cast<int>(fight.GetHp(2))-1000;
    fight.m_members[1].hp=1000;fight.m_members[1].buff_list.clear();
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1402,51),equip(1,10,1,1),equip(2,10,2,2),equip(3,10,3,3),equip(4,10,4,4)});
    fight.CalculateSkill_AddHp(1,101,1);
    const int activeHealGear=static_cast<int>(fight.GetHp(2))-1000;
    const int activeHealSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    fight.ClearBuff(2,ESBUFF_AddSpeed);fight.m_members[1].hp=1000;
    parameters.assign(1,1000);fight.AddBuff(2,1,ESBUFF_AddHpContinue,3,&parameters,101);
    fight.CombatPeriodicActions(2,EFStep_UserActBegin,gearPeriodic,0);
    const int hotHeal=static_cast<int>(fight.GetHp(2))-1000;
    const int sharedHealSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    ++fight.m_fightTurn;fight.CombatPeriodicActions(2,EFStep_UserActBegin,gearPeriodic,0);
    const int laterHotSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    fight.ClearBuff(2,ESBUFF_AddHpContinue);
    fight.AddBuff(2,1,ESBUFF_AddHpContinue,3,&parameters,101);
    fight.CombatPeriodicActions(2,EFStep_UserActBegin,gearPeriodic,0);
    const int newHotSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    fight.Clear();unit(1,10,0,3000);unit(2,23,0,1000);unit(enemy,23,0,10000);
    fight.m_members[0].unitAttr.attack=1000;
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1414,51),equip(1,9,1,1),equip(2,9,2,2)});
    fight.CombatEvent("action_start",1,1,0,0,1,{});
    const int lowShield=fight.GetStatePara1(1,ESBUFF_Shield);
    fight.ClearBuff(1,ESBUFF_Shield);++fight.m_fightTurn;
    fight.CombatEvent("action_start",1,1,0,0,1,{});
    const int shieldInterval=fight.GetStatePara1(1,ESBUFF_Shield);
    fight.ClearBuff(1,ESBUFF_Shield);++fight.m_fightTurn;
    fight.CombatEvent("action_start",1,1,0,0,1,{});
    const int shieldReady=fight.GetStatePara1(1,ESBUFF_Shield);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1412,51)});
    parameters.assign(2,100);fight.AddBuff(2,enemy,ESBUFF_ShiDu,2,&parameters,651);
    fight.ClearBuff(2,ESBUFF_ShiDu,NULL,1);
    const int cleanseHeal=static_cast<int>(fight.GetHp(2))-1000;
    fight.AddBuff(2,enemy,ESBUFF_ShiDu,2,&parameters,651);fight.ClearBuff(2,ESBUFF_ShiDu,NULL,1);
    const int cleanseRepeated=static_cast<int>(fight.GetHp(2))-1000;
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1404,51),equip(1,1,1,1),equip(2,1,2,2),equip(3,1,3,3),equip(4,1,4,4)});
    fight.CombatEvent("after_share",1,enemy,0,0,1,{});
    const int shareDamage=10000-static_cast<int>(fight.GetHp(enemy));
    fight.CombatEvent("after_share",1,enemy,0,0,1,{});
    const int shareRepeated=10000-static_cast<int>(fight.GetHp(enemy));
    const int shareBudget=(fight.CombatTryExtraAttack(1)?1:0)+(fight.CombatTryExtraAttack(1)?1:0);
    fight.Clear();
    unit(1,23,0,10000);unit(enemy,23,0,3000);
    fight.m_members[0].unitAttr.attack=1001;
    fight.m_members[0].unitAttr.speed=1000;
    fight.m_members[0].attackType=1;
    vector<SAttrData> emptyAttrs;
    const int directBase=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1405,51)});
    const int executeDamage=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[enemy-1].hp=3500;
    const int executeBoundary=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1406,51)});
    const int comboFirst=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatHitIndex=1;
    const int comboSecond=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatHitIndex=3;
    const int comboFourth=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatHitIndex=4;
    const int comboFifth=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1408,51)});
    const int openingSpeed=fight.GetUnitSpeed(1),repeatSpeed=fight.GetUnitSpeed(1);
    fight.m_fightTurn=1;
    const int secondSpeed=fight.GetUnitSpeed(1);
    fight.m_fightTurn=2;
    const int expiredSpeed=fight.GetUnitSpeed(1);
    fight.m_members[0].combatLoadout=CombatData::Loadout();
    fight.m_members[0].unitAttr.zengshangLv=30000;
    const int cappedDirect=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].unitAttr.zengshangLv=-20000;
    const int flooredDirect=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.m_members[0].unitAttr.zengshangLv=0;
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1409,51)});
    parameters.assign(2,100);fight.AddBuff(enemy,1,ESBUFF_ShiDu,2,&parameters,651);
    fight.AddBuff(enemy,1,ESBUFF_FuDu,2,&parameters,531);
    const int weaknessSame=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    parameters.assign(1,1000);fight.AddBuff(enemy,1,ESBUFF_SpeedDes,2,&parameters,621);
    const int weaknessTwo=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.ClearBuff(enemy,ESBUFF_SpeedDes);
    const int weaknessRemoved=fight.CalculateDamage(1,enemy,emptyAttrs,emptyAttrs);
    fight.Clear();
    unit(1,23,0,0);unit(2,23,0,5000);unit(3,23,0,0);unit(4,23,0,0);unit(5,23,0,0);
    for(uint8 dead:{1,3,4,5})fight.SetState(dead,EFST_STATE_Die);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1411,51)});
    fight.m_members[2].combatLoadout=catalog.Snapshot({artifact(5,1011,53)});
    fight.m_members[3].combatLoadout=catalog.Snapshot({artifact(5,1311,54)});
    fight.m_members[4].combatLoadout=catalog.Snapshot({artifact(5,1111,55)});
    fight.m_members[4].affixSummoned=true;
    fight.OnAffixUnitDied(3);
    const int deathLow=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd);
    parameters.assign(1,300);fight.AddBuff(2,2,ESBUFF_DamagePercentAdd,2,&parameters,231);
    fight.OnAffixUnitDied(1);
    const int deathHigh=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd);
    fight.OnAffixUnitDied(4);
    const int deathLower=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd);
    int deathDuration=0,deathOrigin=-1;
    for(const auto& buff:fight.m_members[1].buff_list)if(buff.combatStackKey){deathDuration=buff.leftTurn;deathOrigin=buff.originSkill;}
    fight.ClearBuff(2,ESBUFF_DamagePercentAdd);fight.OnAffixUnitDied(1);
    const int deathRepeated=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd);
    fight.OnAffixUnitDied(5);
    const int summonedDeath=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd);
    fight.Clear();
    unit(1,23,0,10000);unit(2,23,0,5000);unit(3,23,0,10000);
    const auto speedSet=catalog.Snapshot({equip(1,10,1,1),equip(2,10,2,2),equip(3,10,3,3),equip(4,10,4,4)});
    fight.m_members[0].combatLoadout=speedSet;fight.m_members[2].combatLoadout=speedSet;
    fight.CombatAfterHeal(1,2,101,1,4000,0,true);
    ++fight.m_fightTurn;fight.CombatAfterHeal(1,2,421,1,4000,0,true);
    const int refreshedSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    fight.CombatAfterHeal(3,2,101,1,4000,0,true);
    const int differentSourceSpeed=fight.GetStatePara1(2,ESBUFF_AddSpeed);
    fight.Clear();
    unit(1,23,0,10000);unit(2,23,0,10000);unit(3,23,0,10000);unit(enemy,23,0,10000);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1013,51)});
    fight.m_members[1].combatLoadout=catalog.Snapshot({artifact(5,1413,52)});
    fight.m_members[enemy-1].combatLoadout=catalog.Snapshot({artifact(5,1413,53)});
    fight.CombatEvent("after_regular",3,3,0,0,1,{});
    const int nonholderRage=fight.GetTeamRage(1);
    fight.CombatEvent("after_regular",1,1,0,0,1,{});
    const int artifactRage=fight.GetTeamRage(1);
    fight.CombatEvent("after_regular",2,2,0,0,1,{});
    const int repeatedArtifactRage=fight.GetTeamRage(1);
    fight.CombatEvent("after_regular",enemy,enemy,0,0,1,{});
    const int enemyArtifactRage=fight.GetTeamRage(enemy);
    ++fight.m_fightTurn;fight.CombatEvent("after_regular",1,1,0,0,1,{});
    const int nextArtifactRage=fight.GetTeamRage(1);
    fight.Clear();
    unit(1,23,0,10000);unit(2,23,0,0);
    fight.SetState(2,EFST_STATE_Die);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1013,51)});
    fight.m_members[1].combatLoadout=catalog.Snapshot({artifact(5,1413,52)});
    fight.CombatEvent("after_regular",1,1,0,0,1,{});
    const int deadHolderRage=fight.GetTeamRage(1);
    fight.Clear();
    unit(1,23,0,10000);unit(2,23,0,10000);unit(3,23,0,10000);unit(enemy,23,0,10000);
    fight.AddTeamRage(1,100);
    const int extraActorRage=fight.GetTeamRage(1);
    fight.AddTeamRage(1,100);fight.AddTeamRage(2,100);fight.AddTeamRage(3,100);
    const int extraTeamRage=fight.GetTeamRage(1);
    fight.AddTeamRage(enemy,100);
    const int extraEnemyRage=fight.GetTeamRage(enemy);
    ++fight.m_fightTurn;fight.AddTeamRage(1,100);
    const int nextExtraRage=fight.GetTeamRage(1);
    fight.AddTeamRage(1,static_cast<int>(catalog.Rule("rage_normal_hit")),false);
    const int baseRageBypass=fight.GetTeamRage(1)-nextExtraRage;
    fight.m_combatState.openingRage=true;
    fight.AddTeamRage(1,100);fight.AddTeamRage(2,100);
    const int openingRage=fight.GetTeamRage(1)-nextExtraRage-baseRageBypass;
    fight.m_combatState.openingRage=false;
    HeroSkillRoleCfg lowCost=*role;lowCost.tacticCost=1;
    const int tacticCostFloor=fight.GetTacticCost(1,lowCost);
    fight.Clear();unit(1,23,0,10000);
    for(int action=0;action<4;++action){fight.m_members[0].rageDamagedThisAction=false;fight.GrantDamageTakenRage(1);}
    const int damageRage=fight.GetTeamRage(1);
    ++fight.m_fightTurn;fight.m_members[0].rageDamagedThisAction=false;
    fight.m_combatDepth=1;fight.GrantDamageTakenRage(1);
    const int secondaryRage=fight.GetTeamRage(1)-damageRage;
    fight.m_combatDepth=0;fight.GrantDamageTakenRage(1);
    const int nextDamageRage=fight.GetTeamRage(1);
    fight.Clear();
    for(uint8 pos=1;pos<=6;++pos)unit(pos,23,0,10000);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1401,51)});
    auto grantShield=[&](uint8 pos) {
        parameters.assign(3,0);parameters[0]=1000;
        fight.AddBuff(pos,1,pos%2?ESBUFF_Shield:ESBUFF_ShieldMianShang,2,&parameters,121);
    };
    for(uint8 pos=1;pos<=6;++pos)grantShield(pos);
    const int efficientFirst=fight.GetStatePara1(1,ESBUFF_Shield);
    const int efficientFourth=fight.GetStatePara1(4,ESBUFF_ShieldMianShang);
    const int efficientSixth=fight.GetStatePara1(6,ESBUFF_ShieldMianShang);
    grantShield(1);
    const int efficientRepeated=fight.GetStatePara1(1,ESBUFF_Shield);
    ++fight.m_members[0].combatActionIndex;grantShield(6);
    const int efficientNext=fight.GetStatePara1(6,ESBUFF_ShieldMianShang);
    fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1407,51)});
    auto pressureShield=[&](int amount) {
        fight.ClearBuff(enemy,ESBUFF_Shield);fight.m_members[enemy-1].hp=10000;
        parameters.assign(2,amount);fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&parameters,121);
    };
    pressureShield(5000);
    int pressureDamage=1000,pressureAbsorbed=0,pressureRevived=0;
    fight.CombatDirectHpDamage(1,enemy,0,1,pressureDamage,pressureAbsorbed,false,&pressureRevived);
    const int pressureRemaining=fight.GetStatePara1(enemy,ESBUFF_Shield);
    const int pressureLife=10000-static_cast<int>(fight.GetHp(enemy));
    const int pressureStats=fight.m_members[0].sum_damage;
    pressureShield(500);
    int spillDamage=1000,spillAbsorbed=0;
    fight.CombatDirectHpDamage(1,enemy,0,1,spillDamage,spillAbsorbed,false,&pressureRevived);
    const int spillLife=10000-static_cast<int>(fight.GetHp(enemy));
    pressureShield(5000);
    int pierceDamage=1000,pierceAbsorbed=0;
    fight.CombatDirectHpDamage(1,enemy,0,1,pierceDamage,pierceAbsorbed,true,&pressureRevived);
    const int pierceLife=10000-static_cast<int>(fight.GetHp(enemy));
    fight.m_members[0].combatLoadout=CombatData::Loadout();pressureShield(5000);
    int basePierceDamage=1000,basePierceAbsorbed=0;
    fight.CombatDirectHpDamage(1,enemy,0,1,basePierceDamage,basePierceAbsorbed,true,&pressureRevived);
    const int basePierceLife=10000-static_cast<int>(fight.GetHp(enemy));
    fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1407,51)});
    fight.ClearBuff(enemy,ESBUFF_Shield);fight.m_members[enemy-1].hp=10000;
    int unshieldedDamage=1000,unshieldedAbsorbed=0;
    fight.CombatDirectHpDamage(1,enemy,0,1,unshieldedDamage,unshieldedAbsorbed,false,&pressureRevived);
    const int unshieldedLife=10000-static_cast<int>(fight.GetHp(enemy));
    fight.Clear();unit(1,23,0,3000);unit(2,23,0,10000);unit(enemy,23,0,10000);
    auto fullSet=[&](int suit){return catalog.Snapshot({equip(1,suit,1,1),equip(2,suit,2,2),equip(3,suit,3,3),equip(4,suit,4,4)});};
    auto affix=[&](uint8 pos,int id,int tier){fight.m_members[pos-1].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(id)->passiveSkillId,tier));};
    // The base engine floors defense at 1; use 1001 attack for 1000 pre-guard damage.
    fight.m_members[0].combatLoadout=fullSet(2);fight.m_members[enemy-1].unitAttr.attack=1001;
    const int setGuardDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    affix(2,12,3);affix(1,48,3);fight.AddTeamRage(1,50,false);
    const int combinedGuardDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.SetState(2,EFST_STATE_Die);
    const int deadAuraDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.m_tacticUsedThisTurn[0]=true;
    const int spentTacticDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.m_fightTurn=2;
    const int expiredAuraDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.m_members[0].hp=4000;
    const int guardBoundaryDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.m_members[0].unitAttr.wumianLv=9000;fight.m_members[enemy-1].attackType=1;
    const int cappedGuardDamage=fight.CalculateDamage(enemy,1,emptyAttrs,emptyAttrs);
    fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);
    fight.m_members[0].combatLoadout=fullSet(6);fight.m_members[0].attackType=2;affix(1,27,3);
    const int ignoreNoDebuff=fight.CombatIgnoreDefense(1,enemy,0);
    parameters.assign(1,1000);fight.AddBuff(enemy,1,ESBUFF_FaFangDes,2,&parameters,0);
    const int ignoreCombined=fight.CombatIgnoreDefense(1,enemy,0);
    const int ignoreSkill=fight.CombatIgnoreDefense(1,enemy,2000);
    const int ignoreCapped=fight.CombatIgnoreDefense(1,enemy,9000);
    const int ignoreExtremeNegative=fight.CombatIgnoreDefense(1,enemy,std::numeric_limits<int>::min());
    const int ignoreExtremePositive=fight.CombatIgnoreDefense(1,enemy,std::numeric_limits<int>::max());
    fight.m_members[0].attackType=1;
    const int ignorePhysical=fight.CombatIgnoreDefense(1,enemy,0);
    fight.Clear();unit(1,10,0,10000);unit(2,23,0,1000);unit(enemy,23,0,10000);
    fight.m_members[0].unitAttr.attack=1000;fight.m_members[1].combatLoadout=fullSet(5);
    fight.CalculateSkill_AddHp(1,101,1);
    const int receivedHeal=static_cast<int>(fight.GetHp(2))-1000;
    fight.m_members[1].hp=1000;parameters.assign(1,1000);fight.AddBuff(2,1,ESBUFF_AddHpContinue,2,&parameters,101);
    fight.CombatPeriodicActions(2,EFStep_UserActBegin,gearPeriodic,0);
    const int receivedHot=static_cast<int>(fight.GetHp(2))-1000;
    CombatData::Modifiers criticalBonus;fight.CombatEvent("before_critical",2,2,0,0,1,{},&criticalBonus);
    const int lowCritical=static_cast<int>(criticalBonus.amountBonus);
    fight.m_members[1].hp=4000;criticalBonus=CombatData::Modifiers();fight.CombatEvent("before_critical",2,2,0,0,1,{},&criticalBonus);
    const int boundaryCritical=static_cast<int>(criticalBonus.amountBonus);
    fight.Clear();unit(1,10,0,10000);unit(2,23,0,0);unit(enemy,23,0,10000);fight.SetState(2,EFST_STATE_Die);
    fight.m_members[0].unitAttr.attack=1000;fight.CalculateSkill_AddHp(1,102,1);
    const int baseReviveHeal=static_cast<int>(fight.GetHp(2));
    fight.Clear();unit(1,10,0,10000);unit(2,23,0,0);unit(enemy,23,0,10000);fight.SetState(2,EFST_STATE_Die);
    fight.m_members[0].unitAttr.attack=1000;fight.m_members[1].combatLoadout=fullSet(5);
    fight.CalculateSkill_AddHp(1,102,1);
    const int receivedReviveHeal=static_cast<int>(fight.GetHp(2));
    fight.Clear();unit(1,15,0,10000);unit(enemy,23,0,10000);unit(otherEnemy,23,0,10000);
    fight.m_members[0].combatLoadout=fullSet(7);fight.m_members[0].unitAttr.attack=1001;fight.m_members[0].unitAttr.mingzhongLv=10000;
    parameters.assign(2,5000);fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&parameters,0);
    int hitSetSelfDamage=0;
    vector<SAttrData> hitSetSourceAttrs,hitSetTargetAttrs;
    fight.BasicFightAction(1,enemy,role->regularSkillId,1,hitSetSelfDamage,hitSetSourceAttrs,hitSetTargetAttrs,false,true);
    const int shieldedHitLife=10000-static_cast<int>(fight.GetHp(enemy));
    const int shieldedHitSlow=fight.GetStatePara1(enemy,ESBUFF_SpeedDes);
    fight.CombatEvent("after_attack",1,otherEnemy,role->regularSkillId,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int sameActionSlow=fight.GetStatePara1(otherEnemy,ESBUFF_SpeedDes);
    ++fight.m_members[0].combatActionIndex;
    fight.CombatEvent("after_attack",1,otherEnemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int normalHitSlow=fight.GetStatePara1(otherEnemy,ESBUFF_SpeedDes);
    fight.CombatEvent("after_attack",1,otherEnemy,role->regularSkillId,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int nextActionSlow=fight.GetStatePara1(otherEnemy,ESBUFF_SpeedDes);
    fight.ClearBuff(otherEnemy,ESBUFF_SpeedDes);fight.m_members[otherEnemy-1].isWorldBoss=true;++fight.m_members[0].combatActionIndex;
    fight.CombatEvent("after_attack",1,otherEnemy,role->regularSkillId,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int setBossSlow=fight.GetStatePara1(otherEnemy,ESBUFF_SpeedDes);
    int setBossDuration=0;for(const auto& b:fight.m_members[otherEnemy-1].buff_list)if(b.id==ESBUFF_SpeedDes)setBossDuration=b.leftTurn;
    fight.Clear();unit(1,23,0,10000);unit(2,23,0,20000);unit(3,23,0,10000);unit(enemy,23,0,15000);
    fight.m_members[1].unitAttr.maxHp=20000;fight.m_members[enemy-1].unitAttr.maxHp=15000;
    fight.m_members[0].combatLoadout=fullSet(9);fight.m_members[1].combatLoadout=fullSet(9);fight.m_members[enemy-1].combatLoadout=fullSet(9);
    fight.CombatEvent("battle_begin",1,1,0,0,1,{});
    const int nonleaderOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    fight.CombatEvent("battle_begin",2,2,0,0,1,{});
    const int leaderOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    const int leaderSelfShield=fight.GetStatePara1(2,ESBUFF_Shield);
    fight.CombatEvent("battle_begin",enemy,enemy,0,0,1,{});
    const int enemyOpeningShield=fight.GetStatePara1(enemy,ESBUFF_Shield);
    fight.ClearBuff(3,ESBUFF_Shield);fight.CombatEvent("battle_begin",2,2,0,0,1,{});
    const int repeatedOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    fight.Clear();unit(1,23,0,10000);unit(2,23,0,0);unit(3,23,0,10000);
    fight.m_members[1].unitAttr.maxHp=20000;fight.SetState(2,EFST_STATE_Die);
    fight.m_members[0].combatLoadout=fullSet(9);fight.m_members[1].combatLoadout=fullSet(9);
    fight.CombatEvent("battle_begin",1,1,0,0,1,{});
    const int deadLeaderOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(3,23,0,10000);
    fight.m_members[0].combatLoadout=fullSet(9);fight.m_members[1].combatLoadout=fullSet(9);
    fight.CombatEvent("battle_begin",2,2,0,0,1,{});
    const int tieLaterOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    fight.CombatEvent("battle_begin",1,1,0,0,1,{});
    const int tieFirstOpeningShield=fight.GetStatePara1(3,ESBUFF_Shield);
    const auto gatedMetrics=[&]() {
    fight.Clear();unit(1,15,0,5000);unit(enemy,23,0,100);unit(otherEnemy,23,0,100);
    fight.m_members[0].combatLoadout=fullSet(3);fight.m_members[0].unitAttr.attack=1001;fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
    SSkillData regularCooldown(role->regularSkillId,1);regularCooldown.CD=regularCooldown.leftCD=6;
    SSkillData tacticCooldown(role->tacticSkillId,1);tacticCooldown.CD=tacticCooldown.leftCD=6;
    fight.m_members[0].skill_list.push_back(regularCooldown);fight.m_members[0].skill_list.push_back(tacticCooldown);
    auto counterKill=[&](uint8 victim){vector<SAttrData> a,b;int self=0;fight.BasicFightAction(1,victim,0,1,self,a,b,true,true);};
    counterKill(enemy);
    const int counterKillHeal=static_cast<int>(fight.GetHp(1))-5000;
    const int counterKillCooldown=fight.m_members[0].skill_list[0].leftCD;
    const int counterKillTactic=fight.m_members[0].skill_list[1].leftCD;
    counterKill(otherEnemy);
    const int repeatedCounterHeal=static_cast<int>(fight.GetHp(1))-5000;
    const int repeatedCounterCooldown=fight.m_members[0].skill_list[0].leftCD;
    ++fight.m_fightTurn;unit(enemy+2,23,0,100);counterKill(enemy+2);
    const int nextCounterHeal=static_cast<int>(fight.GetHp(1))-5000;
    const int nextCounterCooldown=fight.m_members[0].skill_list[0].leftCD;
    fight.Clear();unit(1,23,0,10000);unit(2,23,0,100);unit(enemy,23,0,100);unit(otherEnemy,23,0,100);
    fight.m_members[0].combatLoadout=fullSet(4);
    auto kill=[&](uint8 victim){int damage=100,absorption=0;fight.DecreaseHp(victim,1,damage,absorption,true);};
    kill(2);const int allyKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    kill(enemy);const int firstKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    kill(enemy);const int repeatedDeathStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    fight.m_members[otherEnemy-1].affixSummoned=true;kill(otherEnemy);
    const int summonKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    unit(enemy+2,23,0,100);kill(enemy+2);const int secondKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    unit(enemy+3,23,0,100);kill(enemy+3);const int thirdKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    for(auto& b:fight.m_members[0].buff_list)if(b.combatStackKey==30044)b.leftTurn=1;
    unit(enemy+4,23,0,100);kill(enemy+4);const int cappedKillStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    int cappedStackDuration=0;for(const auto& b:fight.m_members[0].buff_list)if(b.combatStackKey==30044)cappedStackDuration=b.leftTurn;
    fight.Clear();unit(1,23,0,0);unit(enemy,23,0,100);fight.SetState(1,EFST_STATE_Die);fight.m_members[0].combatLoadout=fullSet(4);
    kill(enemy);const int deadSourceStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    int recover=-1000,recoverAbsorbed=0,recoverRevived=0;fight.DecreaseHp(1,1,recover,recoverAbsorbed,true,&recoverRevived);
    const int revivedSourceStack=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
    CombatData::State gateState;CombatData::Event gateEvent;
    gateEvent.actor=1;gateEvent.teamActor=1;gateEvent.name="after_attack";gateEvent.values={{"hit_index",1}};gateEvent.equipmentGroups[30084]=0;
    bool gateTargetAlive=true,gateTargetBlocked=false,gateSuccess=false;int gateRolls=0,gateApplied=0,gateZeroBuffs=0;
    auto runGate=[&]() {
        catalog.Execute(gateEvent,gateState,[&](int maximum){++gateRolls;return gateSuccess?1:maximum;},
            [&](const std::string& selector,int){
                if(selector=="self_any")return std::vector<CombatData::Values>{{{"position",gateEvent.actor}}};
                if(!gateTargetAlive)return std::vector<CombatData::Values>();
                return std::vector<CombatData::Values>{{{"position",enemy},{"target_blocks_buff_3",gateTargetBlocked?1:0}}};
            },[&](const CombatData::Values&,const CombatData::Command& command){++gateApplied;if(command.op=="buff" && !command.value)++gateZeroBuffs;},[](const std::string&){return true;});
    };
    runGate();runGate();const int failedGateRolls=gateRolls;
    ++gateEvent.turn;gateSuccess=true;runGate();const int successfulGateApplied=gateApplied;
    ++gateEvent.turn;gateTargetAlive=false;runGate();gateTargetAlive=true;runGate();const int deadGateRolls=gateRolls;
    ++gateEvent.turn;gateTargetBlocked=true;runGate();gateTargetBlocked=false;runGate();const int immuneGateRolls=gateRolls;
    fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);fight.m_members[0].combatLoadout=fullSet(8);fight.m_members[0].combatHitIndex=1;
    fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_FengYin);
    fight.CombatEvent("after_attack",1,enemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    fight.m_members[enemy-1].notEffectBuff.clear();
    fight.CombatEvent("after_attack",1,enemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int immuneAttemptSeal=fight.HaveBuff(enemy,ESBUFF_FengYin)?1:0;
    ++fight.m_fightTurn;fight.m_members[enemy-1].isWorldBoss=true;fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_FengYin);
    const int bossEffectiveBlock=static_cast<int>(fight.CombatTargetFacts(enemy).count("target_blocks_buff_3"));
    fight.CombatEvent("after_attack",1,enemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int gatedBossSlow=fight.GetStatePara1(enemy,ESBUFF_SpeedDes);
    ++fight.m_fightTurn;fight.ClearBuff(enemy,ESBUFF_SpeedDes);fight.m_members[enemy-1].isWorldBoss=false;fight.m_members[enemy-1].notEffectBuff.clear();
    fight.CombatEvent("after_attack",1,enemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",0}});
    const int gatedSeal=fight.HaveBuff(enemy,ESBUFF_FengYin)?1:0;
    return CombatData::Values{
        {"counter_kill_heal",counterKillHeal},{"counter_kill_cd",counterKillCooldown},{"counter_kill_tactic_cd",counterKillTactic},
        {"repeat_counter_heal",repeatedCounterHeal},{"repeat_counter_cd",repeatedCounterCooldown},{"next_counter_heal",nextCounterHeal},{"next_counter_cd",nextCounterCooldown},
        {"ally_kill_stack",allyKillStack},{"first_kill_stack",firstKillStack},{"repeat_death_stack",repeatedDeathStack},{"summon_kill_stack",summonKillStack},
        {"second_kill_stack",secondKillStack},{"third_kill_stack",thirdKillStack},{"capped_kill_stack",cappedKillStack},{"capped_stack_duration",cappedStackDuration},
        {"dead_source_stack",deadSourceStack},{"revived_source_stack",revivedSourceStack},
        {"failed_gate_rolls",failedGateRolls},{"successful_gate_applied",successfulGateApplied},{"zero_buff_commands",gateZeroBuffs},
        {"dead_gate_rolls",deadGateRolls},{"immune_gate_rolls",immuneGateRolls},{"immune_attempt_seal",immuneAttemptSeal},
        {"boss_effective_block",bossEffectiveBlock},{"gated_boss_slow",gatedBossSlow},{"gated_seal",gatedSeal},
        {"gated_passed",counterKillHeal==800 && counterKillCooldown==5 && counterKillTactic==6 && repeatedCounterHeal==800 && repeatedCounterCooldown==5 && nextCounterHeal==1600 && nextCounterCooldown==4
            && allyKillStack==0 && firstKillStack==600 && repeatedDeathStack==600 && summonKillStack==600 && secondKillStack==1200 && thirdKillStack==1800 && cappedKillStack==1800 && cappedStackDuration==255 && deadSourceStack==600 && revivedSourceStack==600
            && failedGateRolls==1 && successfulGateApplied==1 && gateZeroBuffs==1 && deadGateRolls==2 && immuneGateRolls==2 && immuneAttemptSeal==0 && bossEffectiveBlock==0 && (gatedBossSlow==0 || gatedBossSlow==1000) ? 1 : 0}
    };
    }();
    std::string gatedFields;
    for(const auto& metric:gatedMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto attackMetrics=[&]() {
        CombatData::Values metrics;
        auto attack=[&](const std::string& label,bool first,bool counter,int hp,int bonus,bool critical) {
            fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,hp);
            auto& actor=fight.m_members[0];actor.unitAttr.attack=1001;actor.unitAttr.mingzhongLv=10000;
            actor.unitAttr.lianjiAdd=10000;actor.unitAttr.fanjiAdd=10000;actor.unitAttr.baojiAdd=15000;actor.unitAttr.zengshangLv=bonus;
            if(critical)actor.unitAttr.baojiLv=10000;else fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
            affix(1,17,3);affix(1,22,3);
            vector<SAttrData> own,other;int self=0;fight.BasicFightAction(1,enemy,0,1,self,own,other,counter,first);
            metrics[label+"_damage"]=hp-fight.GetHp(enemy);
            metrics[label+"_hit"]=GetAttrValue(own,EAT_MingZhongLv);
            metrics[label+"_critical"]=GetAttrValue(own,EAT_BaoJiLv);
            metrics[label+"_critical_damage"]=GetAttrValue(own,EAT_BaoJiAdd);
        };
        attack("low_attack",true,false,2999,0,true);
        attack("boundary_attack",true,false,3000,0,true);
        attack("chase_attack",false,false,10000,5000,false);
        attack("first_attack",true,false,10000,5000,false);
        attack("counter_attack",false,true,10000,5000,false);
        attack("capped_attack",false,false,10000,10000,false);
        std::srand(1729);const int expectedRandom=std::rand();std::srand(1729);
        CombatData::Modifiers query;fight.CombatEvent("before_attack",1,enemy,0,0,1,{{"first_attack",0},{"counter_attack",0}},&query);
        metrics["attack_query_rng_unchanged"]=std::rand()==expectedRandom?1:0;
        metrics["attack_passed"]=metrics["low_attack_critical"]==1600 && metrics["low_attack_critical_damage"]==2400
            && metrics["low_attack_damage"]==1740 && metrics["boundary_attack_critical"]==0 && metrics["boundary_attack_damage"]==1500
            && metrics["chase_attack_hit"]==2000 && metrics["chase_attack_damage"]==1620 && metrics["first_attack_hit"]==0 && metrics["first_attack_damage"]==1500
            && metrics["counter_attack_hit"]==0 && metrics["counter_attack_damage"]==1500 && metrics["capped_attack_damage"]==2000 && metrics["attack_query_rng_unchanged"]==1 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:attackMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hitMetrics=[&]() {
        CombatData::Values metrics;
        for(bool reverse:{false,true})for(bool minimum:{false,true}) {
            const uint8 source=reverse?enemy:1,target=reverse?1:enemy;
            fight.Clear();unit(source,23,0,10000);unit(target,23,0,10000);
            fight.m_members[source-1].unitAttr.attack=1001;
            fight.m_members[source-1].unitAttr.mingzhongLv=minimum?0:10000;
            fight.m_members[target-1].unitAttr.shanbiLv=minimum?20000:0;
            fight.m_members[target-1].unitAttr.baojikangLv=10000;
            std::srand(1729);vector<SAttrData> own,other;int self=0;
            fight.BasicFightAction(source,target,0,1,self,own,other,false,true);
            metrics[std::string(reverse?"enemy_":"direct_")+(minimum?"min_hit":"max_hit")]=10000-fight.GetHp(target);
        }
        return metrics;
    }();
    for(const auto& metric:hitMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto countMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int id){fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);affix(1,id,3);};
        auto buff=[&](uint16 id){vector<int> p(2,1000);fight.AddBuff(enemy,1,id,2,&p);};
        auto query=[&]() {CombatData::Modifiers m;fight.CombatEvent("before_attack",1,enemy,0,0,1,{{"first_attack",0},{"counter_attack",0}},&m);return m;};
        setup(21);
        for(int index:{0,1,2,4}){fight.m_members[0].combatHitIndex=index;metrics["count_combo_"+std::to_string(index)]=query().amountBonus;}
        setup(25);metrics["count_unshielded"]=query().amountBonus;buff(ESBUFF_Shield);metrics["count_shielded"]=query().amountBonus;
        setup(32);buff(ESBUFF_SpeedDes);metrics["count_slow_control"]=query().amountBonus;
        metrics["count_slow_hit"]=query().parameterBonuses[0];
        buff(ESBUFF_ChaoFeng);metrics["count_control_damage"]=query().amountBonus;metrics["count_control_hit"]=query().parameterBonuses[0];
        buff(ESBUFF_ChenMo);metrics["count_multiple_controls"]=query().amountBonus;
        setup(35);buff(ESBUFF_JinGuZhou);metrics["count_curse_dot"]=query().amountBonus;
        buff(ESBUFF_ShiXinDu);metrics["count_poison"]=query().amountBonus;
        buff(ESBUFF_ShiDu);buff(ESBUFF_ZhuoShao);metrics["count_multiple_dots"]=query().amountBonus;
        setup(35);buff(ESBUFF_Blooding);metrics["count_bleed"]=query().amountBonus;
        setup(39);buff(ESBUFF_ShiXinDu);buff(ESBUFF_ShiDu);metrics["count_same_category"]=query().amountBonus;
        buff(ESBUFF_SpeedDes);metrics["count_two_categories"]=query().amountBonus;
        buff(ESBUFF_ZhuoShao);buff(ESBUFF_Blooding);buff(ESBUFF_ChaoFeng);metrics["count_capped_categories"]=query().amountBonus;
        setup(21);fight.m_members[0].combatHitIndex=2;
        auto& actor=fight.m_members[0];actor.unitAttr.attack=1001;actor.unitAttr.mingzhongLv=10000;actor.unitAttr.lianjiAdd=10000;actor.unitAttr.zengshangLv=5000;
        fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
        vector<SAttrData> own,other;int self=0;std::srand(1729);fight.BasicFightAction(1,enemy,0,1,self,own,other,false,false);
        metrics["count_combo_damage"]=10000-fight.GetHp(enemy);
        metrics["count_passed"]=metrics["count_combo_0"]==0 && metrics["count_combo_1"]==800 && metrics["count_combo_2"]==1600 && metrics["count_combo_4"]==2400
            && metrics["count_unshielded"]==0 && metrics["count_shielded"]==2000 && metrics["count_slow_control"]==0 && metrics["count_control_damage"]==1600 && metrics["count_control_hit"]==2000 && metrics["count_multiple_controls"]==1600
            && metrics["count_curse_dot"]==0 && metrics["count_poison"]==1600 && metrics["count_multiple_dots"]==1600 && metrics["count_bleed"]==1600
            && metrics["count_same_category"]==500 && metrics["count_two_categories"]==1000 && metrics["count_capped_categories"]==2000 && metrics["count_combo_damage"]==1660 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:countMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto healingMetrics=[&]() {
        CombatData::Values metrics;
        auto heal=[&](const std::string& label,int hp,bool critical,bool gear,int antiheal,int bonus,bool revive) {
            fight.Clear();unit(1,10,0,10000);unit(2,23,0,hp);unit(enemy,23,0,10000);affix(1,6,3);
            fight.m_members[0].unitAttr.attack=1000;fight.m_members[0].unitAttr.baojiLv=critical?10000:0;fight.m_members[0].unitAttr.baojiAdd=15000;
            if(gear)fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1402,51),equip(1,10,1,1),equip(2,10,2,2),equip(3,10,3,3),equip(4,10,4,4)});
            if(antiheal){vector<int> p{antiheal,0};fight.AddBuff(2,enemy,ESBUFF_JinLiaoShu,2,&p);}
            if(bonus){vector<int> p{bonus};fight.AddBuff(2,1,ESBUFF_ImproveCureHp,2,&p);}
            if(revive) {
                fight.SetState(2,EFST_STATE_Die);
                metrics["healing_death_cleared_antiheal"]=fight.HaveBuff(2,ESBUFF_JinLiaoShu)?0:1;
                // A boundary fixture, not a normal death-retention route.
                // Assert a corpse status explicitly before testing its policy.
                if(antiheal){vector<int> p{antiheal,0};fight.AddBuff(2,enemy,ESBUFF_JinLiaoShu,2,&p);}
                metrics["healing_dead_status_fixture"]=fight.GetStatePara1(2,ESBUFF_JinLiaoShu);
            }
            std::srand(1729);fight.CalculateSkill_AddHp(1,revive?102:101,1);
            metrics[label]=fight.GetHp(2)-hp;
        };
        heal("healing_low",3499,false,false,0,0,false);
        heal("healing_boundary",3500,false,false,0,0,false);
        heal("healing_combined",1000,false,true,0,0,false);
        heal("healing_normal_antiheal",1000,false,false,5000,0,false);
        heal("healing_critical_antiheal",1000,true,false,5000,0,false);
        heal("healing_capped",1000,false,false,0,20000,false);
        heal("healing_floor",1000,false,false,0,-20000,false);
        heal("healing_revive_antiheal",0,false,false,5000,0,true);
        fight.Clear();unit(1,10,0,10000);unit(2,23,0,1000);affix(1,6,3);
        vector<int> p{1000};fight.AddBuff(2,1,ESBUFF_AddHpContinue,2,&p,101);
        CNetMessage message;fight.CombatPeriodicActions(2,EFStep_UserActBegin,message,0);
        metrics["healing_hot_excluded"]=fight.GetHp(2)-1000;
        metrics["healing_passed"]=metrics["healing_low"]==750 && metrics["healing_boundary"]==600 && metrics["healing_combined"]==882
            && metrics["healing_normal_antiheal"]==375 && metrics["healing_critical_antiheal"]==562 && metrics["healing_capped"]==1200 && metrics["healing_floor"]==0
            && metrics["healing_revive_antiheal"]==3250 && metrics["healing_hot_excluded"]==1000 && metrics["healing_death_cleared_antiheal"]==1 && metrics["healing_dead_status_fixture"]==5000 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:healingMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto terminalMetrics=[&]() {
        CombatData::Values metrics;
        fight.Clear();unit(1,23,0,0);unit(enemy,23,0,100);fight.SetState(1,EFST_STATE_Die);fight.m_members[0].combatLoadout=fullSet(4);
        vector<int> poisonParameters{1000,0};fight.AddBuff(enemy,1,ESBUFF_ShiDu,2,&poisonParameters);
        CNetMessage periodicMessage;fight.CombatPeriodicActions(enemy,EFStep_UserActBegin,periodicMessage,0);
        metrics["terminal_dot_kill"]=fight.IsAlive(enemy)?0:1;
        metrics["terminal_dot_stack"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
        auto counterSetup=[&](int suit,int attackerHp) {
            fight.Clear();unit(1,15,0,5000);unit(enemy,23,0,attackerHp);
            fight.m_members[0].combatLoadout=fullSet(suit);fight.m_members[0].unitAttr.attack=1001;
            fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.fanjiLv=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
            fight.m_members[enemy-1].unitAttr.attack=101;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
        };
        counterSetup(3,100);SSkillData cooldown(role->regularSkillId,1);cooldown.CD=cooldown.leftCD=6;fight.m_members[0].skill_list.push_back(cooldown);
        int self=0;std::srand(1729);fight.CalculateOnceAction(enemy,1,0,1,self,true);
        metrics["terminal_counter_kill"]=fight.IsAlive(enemy)?0:1;
        metrics["terminal_counter_heal"]=fight.GetHp(1)-4900;
        metrics["terminal_counter_cd"]=fight.m_members[0].skill_list[0].leftCD;
        counterSetup(8,5000);fight.m_members[0].combatHitIndex=1;self=0;std::srand(1729);fight.CalculateOnceAction(enemy,1,0,1,self,true);
        metrics["terminal_counter_seal"]=fight.HaveBuff(enemy,ESBUFF_FengYin)?1:0;
        metrics["terminal_counter_damage"]=5000-fight.GetHp(enemy);
        auto secondaryCounter=[&](bool withSet) {
            counterSetup(withSet?8:0,5000);fight.m_members[0].combatHitIndex=1;self=0;std::srand(1729);
            for(CNetMessage* message:{&fight.m_actionMsg,&fight.m_extActionMsg,&fight.m_otherMsg}){message->ReWrite();message->SetType(0);}
            {CombatData::ScopedDepth secondary(fight.m_combatDepth);fight.CalculateOnceAction(enemy,1,0,1,self,true);}
            fight.m_actionMsg.SetDataLen();
            return std::make_tuple(*fight.m_actionMsg.GetMsgData(),std::rand(),fight.GetHp(1),fight.GetHp(enemy),fight.HaveBuff(enemy,ESBUFF_FengYin));
        };
        const auto withoutSecondarySet=secondaryCounter(false),withSecondarySet=secondaryCounter(true);
        metrics["terminal_secondary_counter_set_skipped"]=withoutSecondarySet==withSecondarySet && !std::get<4>(withSecondarySet)?1:0;
        int sealSeed=1;
        for(;sealSeed<=100;++sealSeed){std::srand(sealSeed);if(Random(1,10000)<=3500)break;}
        counterSetup(8,5000);fight.m_members[0].combatHitIndex=1;std::srand(sealSeed);
        fight.CombatEvent("after_attack",1,enemy,0,0,1,{{"amount",100},{"absorbed",0},{"counter_attack",1}});
        metrics["terminal_seal_empty_parameters"]=0;
        for(const auto& buff:fight.m_members[enemy-1].buff_list)if(buff.id==ESBUFF_FengYin && buff.paraList.empty())metrics["terminal_seal_empty_parameters"]=1;
        metrics["terminal_passed"]=metrics["terminal_dot_kill"]==1 && metrics["terminal_dot_stack"]==600
            && metrics["terminal_counter_kill"]==1 && metrics["terminal_counter_heal"]==800 && metrics["terminal_counter_cd"]==5 && metrics["terminal_counter_damage"]==1000
            && metrics["terminal_secondary_counter_set_skipped"]==1 && metrics["terminal_seal_empty_parameters"]==1 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:terminalMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto orderMetrics=[&]() {
        CombatData::Values metrics;
        fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);affix(enemy,29,3);
        fight.m_members[0].unitAttr.speed=1100;fight.m_members[enemy-1].unitAttr.speed=1000;
        uint8 ordered[MAX_MEMBER]={},count=0;
        std::srand(1729);const int expectedRandom=std::rand();std::srand(1729);
        metrics["order_opening_speed"]=fight.GetUnitSpeed(enemy);
        fight.GetAllUnitByOrder(ordered,count);metrics["order_opening_enemy_first"]=count==2 && ordered[0]==enemy?1:0;
        fight.GetAllUnitByOrder(ordered,count);metrics["order_repeat_enemy_first"]=ordered[0]==enemy?1:0;
        metrics["order_rng_unchanged"]=std::rand()==expectedRandom?1:0;
        fight.m_fightTurn=1;metrics["order_second_speed"]=fight.GetUnitSpeed(enemy);
        fight.m_fightTurn=2;metrics["order_expired_speed"]=fight.GetUnitSpeed(enemy);
        fight.GetAllUnitByOrder(ordered,count);metrics["order_expired_enemy_first"]=ordered[0]==enemy?1:0;
        fight.m_fightTurn=0;fight.m_members[enemy-1].unitAttr.speed=1006;
        fight.m_members[enemy-1].combatLoadout=catalog.Snapshot({artifact(5,1408,51)});
        metrics["order_combined_speed"]=fight.GetUnitSpeed(enemy);
        fight.m_members[0].unitAttr.speed=2000;fight.SetState(enemy,EFST_STATE_Die);fight.m_ActionFirstGroup=EGT_GROUP2;
        fight.GetAllUnitByOrder(ordered,count);metrics["order_dead_holder_sorts"]=ordered[0]==1?1:0;
        fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);
        fight.m_members[0].unitAttr.speed=1000;fight.m_members[enemy-1].unitAttr.speed=2000;
        fight.GetAllUnitByOrder(ordered,count);metrics["order_unbound_keeps_formation"]=ordered[0]==1?1:0;
        metrics["order_passed"]=metrics["order_opening_speed"]==1160 && metrics["order_second_speed"]==1160 && metrics["order_expired_speed"]==1000
            && metrics["order_opening_enemy_first"]==1 && metrics["order_repeat_enemy_first"]==1 && metrics["order_expired_enemy_first"]==0
            && metrics["order_rng_unchanged"]==1 && metrics["order_combined_speed"]==1305 && metrics["order_dead_holder_sorts"]==1 && metrics["order_unbound_keeps_formation"]==1 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:orderMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto rageAffixMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,15,0,10000);unit(2,23,0,10000);unit(3,23,0,0);unit(enemy,23,0,10000);
            fight.SetState(3,EFST_STATE_Die);
            affix(1,45,1);affix(2,45,2);affix(3,45,3);affix(enemy,45,3);
            affix(1,47,1);affix(2,47,2);affix(3,47,3);affix(enemy,47,3);
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        setup();fight.InitTeamRageFromAffixes();
        metrics["rage_affix_opening"]=fight.GetTeamRage(1);metrics["rage_affix_enemy_opening"]=fight.GetTeamRage(enemy);
        fight.m_extActionMsg.ReRead();uint8 eventType=0,owner=0;fight.m_extActionMsg>>eventType>>owner;
        metrics["rage_affix_presentation_owner"]=owner;
        fight.InitTeamRageFromAffixes();metrics["rage_affix_opening_repeat"]=fight.GetTeamRage(1);
        metrics["rage_affix_cost"]=fight.GetTacticCost(1,*role);metrics["rage_affix_enemy_cost"]=fight.GetTacticCost(enemy,*role);
        std::srand(1729);const int expectedRandom=std::rand();std::srand(1729);
        fight.GetTacticCost(1,*role);fight.GetTacticCost(1,*role);metrics["rage_affix_cost_rng"]=std::rand()==expectedRandom?1:0;
        fight.SetState(2,EFST_STATE_Die);metrics["rage_affix_cost_after_death"]=fight.GetTacticCost(1,*role);
        fight.AddTeamRage(1,100);metrics["rage_affix_extra_budget"]=fight.GetTeamRage(1)-metrics["rage_affix_opening"];
        setup();fight.m_members[2].hp=10000;fight.ClearState(3,EFST_STATE_Die);fight.InitTeamRageFromAffixes();
        metrics["rage_affix_highest_live"]=fight.GetTeamRage(1);
        fight.m_extActionMsg.ReRead();fight.m_extActionMsg>>eventType>>owner;metrics["rage_affix_highest_owner"]=owner;
        metrics["rage_affix_highest_cost"]=fight.GetTacticCost(1,*role);
        metrics["rage_affix_passed"]=metrics["rage_affix_opening"]==8 && metrics["rage_affix_enemy_opening"]==12 && metrics["rage_affix_opening_repeat"]==8
            && metrics["rage_affix_presentation_owner"]==2 && metrics["rage_affix_cost"]==31 && metrics["rage_affix_enemy_cost"]==28
            && metrics["rage_affix_cost_after_death"]==34 && metrics["rage_affix_cost_rng"]==1 && metrics["rage_affix_extra_budget"]==12
            && metrics["rage_affix_highest_live"]==12 && metrics["rage_affix_highest_owner"]==3 && metrics["rage_affix_highest_cost"]==28 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:rageAffixMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto actionRageMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,15,0,10000);unit(enemy,23,0,10000);
            fight.m_members[0].unitAttr.attack=101;fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.lianjiLv=10000;
            fight.m_members[enemy-1].unitAttr.attack=1;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
            std::srand(1729);
        };
        setup();affix(1,24,3);
        fight.CalculateNormal_DamageHp(1,enemy);metrics["action_rage_combo_first"]=fight.GetTeamRage(1);
        fight.CalculateNormal_DamageHp(1,enemy);metrics["action_rage_combo_second"]=fight.GetTeamRage(1);
        fight.CalculateNormal_DamageHp(1,enemy);metrics["action_rage_combo_capped"]=fight.GetTeamRage(1);
        ++fight.m_fightTurn;fight.CalculateNormal_DamageHp(1,enemy);metrics["action_rage_combo_next"]=fight.GetTeamRage(1);
        setup();affix(1,24,3);fight.m_members[0].unitAttr.lianjiLv=0;
        fight.CalculateNormal_DamageHp(1,enemy);metrics["action_rage_single"]=fight.GetTeamRage(1);
        setup();affix(1,24,3);fight.CalculateSkill_DamageHp(1,role->regularSkillId,1);
        metrics["action_rage_skill_combo"]=fight.GetTeamRage(1);
        setup();affix(1,46,3);
        fight.CombatEvent("after_regular",1,1,role->regularSkillId,0,1,{});fight.CombatEvent("after_regular",1,1,role->regularSkillId,0,1,{});
        metrics["action_rage_regular_budget"]=fight.GetTeamRage(1);
        setup();affix(1,4,3);vector<int> shieldParameters{1000,1000};fight.AddBuff(1,1,ESBUFF_Shield,1,&shieldParameters);
        fight.CombatEvent("action_end",1,1,0,0,1,{});metrics["action_rage_shield_end"]=fight.GetTeamRage(1);
        fight.DecAllStateEffectTurn(1);fight.CombatEvent("action_end",1,1,0,0,1,{});metrics["action_rage_shield_expired"]=fight.GetTeamRage(1);
        auto fullTurn=[&](bool equipped) {
            setup();fight.m_members[0].unitAttr.lianjiLv=0;fight.m_members[0].skill_list.push_back(SSkillData(role->regularSkillId,1));
            if(equipped){affix(1,4,3);affix(1,46,3);}
            vector<int> shield{1000,1000};fight.AddBuff(1,1,ESBUFF_Shield,1,&shield);
            CNetMessage message;fight.CalculateFight(message);return fight.GetTeamRage(1);
        };
        const int baselineTurn=fullTurn(false);metrics["action_rage_full_turn_delta"]=fullTurn(true)-baselineTurn;
        metrics["action_rage_passed"]=metrics["action_rage_combo_first"]==4 && metrics["action_rage_combo_second"]==8 && metrics["action_rage_combo_capped"]==8
            && metrics["action_rage_combo_next"]==12 && metrics["action_rage_single"]==0 && metrics["action_rage_skill_combo"]==4
            && metrics["action_rage_regular_budget"]==4 && metrics["action_rage_shield_end"]==4 && metrics["action_rage_shield_expired"]==4
            && metrics["action_rage_full_turn_delta"]==8 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:actionRageMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto passiveReviveMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](bool pair) {
            fight.Clear();unit(1,10,0,10000);unit(enemy,23,0,10000);
            fight.m_members[0].passive_skill.push_back(SSkillData(104,75));
            if(pair){unit(2,10,0,10000);fight.m_members[1].passive_skill.push_back(SSkillData(104,75));}
            std::srand(1729);
        };
        auto die=[&](uint8 target){int damage=100000,absorbed=0;fight.DecreaseHp(target,enemy,damage,absorbed,true);};
        setup(false);die(1);CNetMessage first;fight.DiePassiveAcion(first);
        metrics["passive_revive_first_hp"]=fight.GetHp(1);metrics["passive_revive_first_count"]=fight.m_combatState.revives[1];
        die(1);CNetMessage second;fight.DiePassiveAcion(second);
        metrics["passive_revive_repeat_hp"]=fight.GetHp(1);metrics["passive_revive_repeat_alive"]=fight.IsAlive(1)?1:0;
        setup(true);die(1);die(2);CNetMessage simultaneous;fight.DiePassiveAcion(simultaneous);
        metrics["passive_revive_pair_first"]=fight.GetHp(1);metrics["passive_revive_pair_second"]=fight.GetHp(2);
        fight.Clear();unit(1,35,0,10000);unit(2,35,0,10000);unit(3,23,0,10000);unit(4,23,0,10000);unit(enemy,23,0,10000);
        fight.m_members[0].passive_skill.push_back(SSkillData(354,1));fight.m_members[1].passive_skill.push_back(SSkillData(354,1));
        die(3);die(4);CNetMessage allyRevives;fight.DiePassiveAcion(allyRevives);
        metrics["passive_revive_ally_first"]=fight.GetHp(3);metrics["passive_revive_ally_second"]=fight.GetHp(4);
        metrics["passive_revive_passed"]=metrics["passive_revive_first_hp"]==1500 && metrics["passive_revive_first_count"]==1
            && metrics["passive_revive_repeat_hp"]==0 && metrics["passive_revive_repeat_alive"]==0
            // The source phase advances its index after first revival erases
            // the entry; the shifted second death is not revisited here.
            && metrics["passive_revive_pair_first"]==1500 && metrics["passive_revive_pair_second"]==0
            && metrics["passive_revive_ally_first"]==2500 && metrics["passive_revive_ally_second"]==0 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:passiveReviveMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto nuwaMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch,int allyHp) {
            fight.Clear();unit(1,10,branch,10000);unit(2,23,0,allyHp);unit(enemy,23,0,10000);
            fight.m_members[0].unitAttr.attack=1000;std::srand(1729);
            fight.m_actionMsg.ReWrite();fight.m_actionMsg.SetType(0);
        };
        setup(1,1000);fight.CalculateSkill_AddHp(1,101,1);
        metrics["nuwa_a_heal"]=fight.GetHp(2)-1000;metrics["nuwa_a_guard"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup(2,1000);SSkillData revive(102,1);revive.CD=revive.leftCD=5;fight.m_members[0].skill_list.push_back(revive);
        fight.CalculateSkill_AddHp(1,101,1);metrics["nuwa_b_heal"]=fight.GetHp(2)-1000;
        metrics["nuwa_b_heal_rage"]=fight.GetTeamRage(1);metrics["nuwa_b_heal_cd"]=fight.m_members[0].skill_list[0].leftCD;
        setup(1,9900);fight.CalculateSkill_AddHp(1,101,1);metrics["nuwa_a_overheal_shield"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(1,9903);fight.m_members[0].hp=9000;affix(1,5,3);fight.CalculateSkill_AddHp(1,101,1);
        metrics["nuwa_combined_shield"]=fight.GetStatePara1(2,ESBUFF_Shield);
        metrics["nuwa_combined_duration"]=lastDuration(2,ESBUFF_Shield);
        fight.ClearBuff(2,ESBUFF_Shield);fight.m_members[0].hp=9000;fight.m_members[1].hp=9903;
        fight.CalculateSkill_AddHp(1,101,1);metrics["nuwa_combined_repeat"]=fight.GetStatePara1(2,ESBUFF_Shield);
        ++fight.m_fightTurn;fight.ClearBuff(2,ESBUFF_Shield);fight.m_members[0].hp=9000;fight.m_members[1].hp=9903;
        fight.CalculateSkill_AddHp(1,101,1);metrics["nuwa_combined_next_turn"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(0,9903);fight.m_members[0].hp=9000;affix(1,5,3);fight.CalculateSkill_AddHp(1,101,1);
        metrics["affix_overheal_base"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(1,9903);fight.m_members[0].hp=1000;affix(1,5,3);fight.m_members[0].unitAttr.attack=12000;
        fight.CalculateSkill_AddHp(1,101,1);metrics["nuwa_combined_capped"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(1,9903);fight.m_members[0].hp=9000;affix(1,5,3);
        fight.CombatAfterHeal(1,2,101,1,9903,3,true);metrics["nuwa_fraction_only"]=fight.GetStatePara1(2,ESBUFF_Shield);
        for(int branch:{1,2}) {
            setup(branch,0);fight.SetState(2,EFST_STATE_Die);fight.m_members[0].unitAttr.baojiLv=10000;fight.m_members[0].unitAttr.baojiAdd=20000;
            fight.CalculateSkill_AddHp(1,102,1);
            const std::string prefix=branch==1?"nuwa_a_":"nuwa_b_";
            metrics[prefix+"revive_hp"]=fight.GetHp(2);metrics[prefix+"revive_rage"]=fight.GetTeamRage(1);
            fight.m_actionMsg.ReRead();uint8 type=0,source=0,count=0,target=0,critical=0;uint16 skill=0;
            fight.m_actionMsg>>type>>source>>skill>>count>>target>>critical;
            metrics[prefix+"revive_critical"]=critical;
            setup(branch,1000);fight.m_members[0].passive_skill.push_back(SSkillData(104,75));
            int damage=100000,absorption=0;fight.DecreaseHp(1,enemy,damage,absorption,true);CNetMessage death;fight.DiePassiveAcion(death);
            metrics[prefix+"self_revive_hp"]=fight.GetHp(1);metrics[prefix+"self_revive_ally"]=fight.GetHp(2);
        }
        setup(1,0);unit(3,23,0,0);fight.SetState(2,EFST_STATE_Die);fight.SetState(3,EFST_STATE_Die);affix(1,8,3);
        fight.CalculateSkill_AddHp(1,102,1);
        fight.m_actionMsg.ReRead();uint8 reviveType=0,reviveSource=0,reviveCount=0,firstRevived=0;uint16 reviveSkill=0;
        fight.m_actionMsg>>reviveType>>reviveSource>>reviveSkill>>reviveCount>>firstRevived;
        metrics["revive_guard_first_position"]=firstRevived;
        metrics["revive_guard_first"]=fight.GetStatePara1(firstRevived,ESBUFF_MianShangTemp);
        metrics["revive_guard_second"]=fight.GetStatePara1(firstRevived==2?3:2,ESBUFF_MianShangTemp);
        metrics["revive_guard_duration"]=lastDuration(firstRevived,ESBUFF_MianShangTemp);
        for(const auto& buff:fight.m_members[firstRevived-1].buff_list)if(buff.id==ESBUFF_MianShangTemp){metrics["revive_guard_first_applied"]=buff.paraList[0];break;}
        ++fight.m_fightTurn;unit(4,23,0,0);fight.SetState(4,EFST_STATE_Die);fight.CalculateSkill_AddHp(1,102,1);
        metrics["revive_guard_later_turn"]=fight.GetStatePara1(4,ESBUFF_MianShangTemp);
        setup(0,0);fight.SetState(2,EFST_STATE_Die);affix(1,8,3);fight.CalculateSkill_AddHp(1,102,1);
        metrics["revive_guard_base"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup(2,0);unit(3,23,0,0);fight.SetState(2,EFST_STATE_Die);fight.SetState(3,EFST_STATE_Die);
        fight.CalculateSkill_AddHp(1,102,1);
        metrics["nuwa_b_two_revived_first"]=fight.GetHp(2);metrics["nuwa_b_two_revived_second"]=fight.GetHp(3);
        metrics["nuwa_b_two_revived_rage"]=fight.GetTeamRage(1);
        auto useful=[&](int branch,int hp2,int hp3,int allies) {
            setup(branch,hp2);unit(3,23,0,hp3);for(int pos=4;pos<=allies;++pos)unit(pos,23,0,10000);
            return fight.IsRoleSkillUseful(1,101)?1:0;
        };
        metrics["nuwa_two_injured"]=useful(1,6999,6999,6);
        metrics["nuwa_injured_boundary"]=useful(1,6999,7000,6);
        metrics["nuwa_mean_boundary"]=useful(2,4600,10000,3);
        metrics["nuwa_mean_below"]=useful(2,4601,10000,3);
        metrics["nuwa_base_useful"]=useful(0,4601,10000,3);
        metrics["nuwa_passed"]=metrics["nuwa_a_heal"]==750 && metrics["nuwa_a_guard"]==800 && metrics["nuwa_b_heal"]==540
            && metrics["nuwa_b_heal_rage"]==3 && metrics["nuwa_b_heal_cd"]==4 && metrics["nuwa_a_overheal_shield"]==130 && metrics["nuwa_combined_shield"]==326
            && metrics["nuwa_combined_repeat"]==130 && metrics["nuwa_combined_next_turn"]==326 && metrics["affix_overheal_base"]==150
            && metrics["nuwa_combined_capped"]==3500 && metrics["nuwa_fraction_only"]==1
            && metrics["nuwa_combined_duration"]==2
            && metrics["revive_guard_first"]==6000 && metrics["revive_guard_second"]==2000 && metrics["revive_guard_first_applied"]==2000
            && metrics["revive_guard_duration"]==1 && metrics["revive_guard_later_turn"]==2000 && metrics["revive_guard_base"]==4000
            && metrics["nuwa_b_two_revived_first"]==4000 && metrics["nuwa_b_two_revived_second"]==4000 && metrics["nuwa_b_two_revived_rage"]==0
            && metrics["nuwa_a_revive_hp"]==2500 && metrics["nuwa_b_revive_hp"]==4000 && metrics["nuwa_b_revive_rage"]==12
            && metrics["nuwa_a_revive_critical"]==0 && metrics["nuwa_b_revive_critical"]==0
            && metrics["nuwa_a_self_revive_hp"]==2000 && metrics["nuwa_a_self_revive_ally"]==1500
            && metrics["nuwa_b_self_revive_hp"]==3500 && metrics["nuwa_b_self_revive_ally"]==1000
            && metrics["nuwa_two_injured"]==1 && metrics["nuwa_injured_boundary"]==0 && metrics["nuwa_mean_boundary"]==1 && metrics["nuwa_mean_below"]==0 && metrics["nuwa_base_useful"]==1 ? 1 : 0;
        return metrics;
    }();
    for(const auto& metric:nuwaMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto thornsMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int attack) {
            fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);affix(1,14,3);
            fight.m_members[0].unitAttr.fanzhenLv=10000;fight.m_members[0].unitAttr.fanzhenAdd=10000;
            fight.m_members[enemy-1].unitAttr.attack=attack;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
            std::srand(1729);
        };
        auto hit=[&]() {int self=0;fight.CalculateOnceAction(enemy,1,0,1,self,true);return fight.GetStatePara1(1,ESBUFF_Shield);};
        setup(1001);metrics["thorns_first_shield"]=hit();metrics["thorns_duration"]=lastDuration(1,ESBUFF_Shield);
        fight.ClearBuff(1,ESBUFF_Shield);metrics["thorns_second_shield"]=hit();
        fight.ClearBuff(1,ESBUFF_Shield);metrics["thorns_third_shield"]=hit();
        ++fight.m_fightTurn;metrics["thorns_next_turn"]=hit();
        setup(9001);metrics["thorns_cap"]=hit();
        setup(1001);std::vector<int> shield{2000,2000};fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield);
        metrics["thorns_absorbed_shield"]=hit();metrics["thorns_absorbed_hp"]=fight.GetHp(enemy);
        fight.ClearBuff(enemy,ESBUFF_Shield);fight.ClearBuff(1,ESBUFF_Shield);metrics["thorns_after_absorbed"]=hit();
        fight.ClearBuff(1,ESBUFF_Shield);metrics["thorns_absorbed_budget"]=hit();
        setup(1001);fight.m_members[0].passive_skill.clear();fight.m_members[0].hp=fight.m_members[0].unitAttr.maxHp=100000;
        fight.m_members[enemy-1].hp=fight.m_members[enemy-1].unitAttr.maxHp=100000;
        auto direct=[&]() {std::vector<SAttrData> own,other;int self=0;const int before=fight.GetHp(enemy);fight.BasicFightAction(enemy,1,0,1,self,own,other,false,true);return before-static_cast<int>(fight.GetHp(enemy));};
        metrics["thorns_rule_first"]=direct();direct();direct();direct();metrics["thorns_rule_four_total"]=100000-fight.GetHp(enemy);
        ++fight.m_fightTurn;metrics["thorns_rule_next"]=direct();
        metrics["thorns_passed"]=metrics["thorns_first_shield"]==80 && metrics["thorns_second_shield"]==80 && metrics["thorns_third_shield"]==0
            && metrics["thorns_next_turn"]==80 && metrics["thorns_cap"]==720 && metrics["thorns_duration"]==2
            && metrics["thorns_absorbed_shield"]==0 && metrics["thorns_absorbed_hp"]==10000 && metrics["thorns_after_absorbed"]==80 && metrics["thorns_absorbed_budget"]==0
            && metrics["thorns_rule_first"]==500 && metrics["thorns_rule_four_total"]==1500 && metrics["thorns_rule_next"]==500?1:0;
        return metrics;
    }();
    for(const auto& metric:thornsMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto overkillMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,10000);affix(1,19,3);
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
            fight.m_members[0].unitAttr.attack=1001;fight.m_members[0].unitAttr.mingzhongLv=10000;
            unit(enemy,23,0,100);unit(enemy+1,23,0,1000);unit(enemy+2,23,0,2000);
            fight.m_members[enemy+1].unitAttr.maxHp=100000;
            std::srand(1729);
        };
        setup();int self=0;fight.CalculateOnceAction(1,enemy,0,1,self,true);
        metrics["overkill_primary_hp"]=fight.GetHp(enemy);
        metrics["overkill_first_damage"]=1000-fight.GetHp(enemy+1);
        metrics["overkill_ratio_target_damage"]=2000-fight.GetHp(enemy+2);
        auto event=[&](int amount) {fight.CombatEvent("after_direct_kill",1,enemy,0,0,1,{{"overkill",amount}});};
        event(900);metrics["overkill_repeated_damage"]=1000-fight.GetHp(enemy+1);
        ++fight.m_fightTurn;event(900);metrics["overkill_next_damage"]=1000-fight.GetHp(enemy+1);
        setup();fight.m_members[enemy].hp=9000;fight.m_members[enemy+1].hp=10000;
        event(50000);metrics["overkill_cap"]=9000-fight.GetHp(enemy+1);
        metrics["overkill_no_cascade"]=10000-fight.GetHp(enemy+2);
        setup();event(0);metrics["overkill_zero_budget"]=fight.m_combatState.counts[{1,40190,0}].inBattle;
        event(900);metrics["overkill_after_zero"]=1000-fight.GetHp(enemy+1);
        setup();fight.m_members[enemy].hp=0;fight.m_members[enemy+1].hp=0;
        fight.SetState(enemy+1,EFST_STATE_Die);fight.SetState(enemy+2,EFST_STATE_Die);event(900);
        metrics["overkill_empty_budget"]=fight.m_combatState.counts[{1,40190,0}].inBattle;
        fight.m_members[enemy].hp=1000;fight.ClearState(enemy+1,EFST_STATE_Die);
        event(900);metrics["overkill_after_empty"]=1000-fight.GetHp(enemy+1);
        ++fight.m_fightTurn;event(900);metrics["overkill_empty_next_turn"]=1000-fight.GetHp(enemy+1);
        setup();std::vector<SAttrData> srcAttributes,targetAttributes;
        fight.BasicFightAction(1,enemy,0,1,self,srcAttributes,targetAttributes,true,true);
        metrics["overkill_counter_damage"]=1000-fight.GetHp(enemy+1);
        // A real selector must match the old target order, including equal HP,
        // and leave the fixed-seed random stream unchanged.
        setup();fight.m_members[enemy+1].hp=1000;
        uint8 candidates[GROUP_MEMBER],count=0;fight.GetAnotherGroupByAttackedOrder(1,candidates,count);
        if(count>1)fight.GetSkillTargetSelCondition(candidates,count,ESkill_Select_MinCurHp);
        uint8 expected=0;for(uint8 i=0;i<count;++i)if(candidates[i]!=enemy && fight.IsAlive(candidates[i])){expected=candidates[i];break;}
        const int expectedRandom=std::rand();std::srand(1729);event(900);
        metrics["overkill_tie_parity"]=expected && fight.GetHp(expected)<1000?1:0;
        metrics["overkill_rng_parity"]=std::rand()==expectedRandom?1:0;
        // The real attack also writes base rage actions. Use an isolated event
        // packet to inspect its presentation without treating rage as a hit.
        setup();event(900);fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 presentation=0;
        fight.m_extActionMsg>>type>>source>>presentation;metrics["overkill_presentation"]=presentation;
        // Exercise pre-target gate rejection using an intentionally random
        // selector: the actual lowest-HP selector is deterministic.
        CombatData::State gateState;CombatData::Event gateEvent;
        gateEvent.actor=1;gateEvent.teamActor=1;gateEvent.name="after_direct_kill";
        gateEvent.contentValues[40190]={{"affix_value1",4000},{"affix_value2",10000}};
        gateEvent.values={{"overkill",0},{"source_attack",1000}};
        int selections=0,commands=0;
        auto run=[&]() {catalog.Execute(gateEvent,gateState,[](int max){return Random(1,max);},
            [&](const std::string& selector,int) {
                if(selector=="lowest_enemy_hp"){++selections;std::rand();}
                return std::vector<CombatData::Values>{{{"position",selector=="self_any"?1:enemy+1}}};
            },[&](const CombatData::Values&,const CombatData::Command&){++commands;},[](const std::string&){return true;});};
        run();metrics["overkill_zero_selections"]=selections;
        gateEvent.values["overkill"]=900;run();metrics["overkill_valid_selections"]=selections;
        run();metrics["overkill_exhausted_selections"]=selections;metrics["overkill_gate_commands"]=commands;
        metrics["overkill_passed"]=metrics["overkill_primary_hp"]==0 && metrics["overkill_first_damage"]==360
            && metrics["overkill_ratio_target_damage"]==0 && metrics["overkill_repeated_damage"]==360 && metrics["overkill_next_damage"]==720
            && metrics["overkill_cap"]==1001 && metrics["overkill_no_cascade"]==0 && metrics["overkill_zero_budget"]==0
            && metrics["overkill_after_zero"]==360 && metrics["overkill_empty_budget"]==1 && metrics["overkill_after_empty"]==0
            && metrics["overkill_empty_next_turn"]==360 && metrics["overkill_counter_damage"]==0
            && metrics["overkill_tie_parity"]==1 && metrics["overkill_rng_parity"]==1 && metrics["overkill_zero_selections"]==0
            && metrics["overkill_valid_selections"]==1 && metrics["overkill_exhausted_selections"]==1 && metrics["overkill_gate_commands"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:overkillMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto shieldLossMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int hp=4000) {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,hp);unit(enemy,23,0,10000);unit(enemy+1,23,0,10000);
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
            affix(1,1,3);affix(2,3,3);std::srand(1729);
        };
        auto shield=[&](int amount,int turns=1) {std::vector<int> parameters{amount,amount};fight.AddBuff(2,1,ESBUFF_Shield,turns,&parameters);};
        auto absorb=[&](int amount) {int absorbed=0;fight.DecreaseHp(2,enemy,amount,absorbed,false);};
        auto breakShield=[&]() {shield(1000);absorb(1000);fight.ShieldBrokenCheck(2,enemy);};
        setup();breakShield();metrics["shield_loss_damage"]=10000-fight.GetHp(enemy);
        fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 presentation=0;fight.m_extActionMsg>>type>>source>>presentation;
        metrics["shield_loss_damage_presentation"]=presentation;
        metrics["shield_loss_other_damage"]=10000-fight.GetHp(enemy+1);
        metrics["shield_loss_heal"]=fight.GetHp(2)-4000;
        breakShield();metrics["shield_loss_repeat_damage"]=10000-fight.GetHp(enemy);metrics["shield_loss_repeat_heal"]=fight.GetHp(2)-4000;
        ++fight.m_fightTurn;breakShield();metrics["shield_loss_next_damage"]=10000-fight.GetHp(enemy);metrics["shield_loss_next_heal"]=fight.GetHp(2)-4000;
        setup();shield(1000);fight.DecAllStateEffectTurn(2);
        metrics["shield_loss_unused_damage"]=10000-fight.GetHp(enemy);metrics["shield_loss_unused_heal"]=fight.GetHp(2)-4000;
        breakShield();metrics["shield_loss_after_unused"]=10000-fight.GetHp(enemy);
        setup();shield(1000);absorb(300);metrics["shield_loss_before_expire"]=10000-fight.GetHp(enemy);
        fight.DecAllStateEffectTurn(2);metrics["shield_loss_partial_expire"]=10000-fight.GetHp(enemy);metrics["shield_loss_expire_heal"]=fight.GetHp(2)-4000;
        setup();shield(1000);absorb(300);fight.ClearBuff(2,ESBUFF_Shield);
        metrics["shield_loss_partial_dispel"]=10000-fight.GetHp(enemy);metrics["shield_loss_dispel_heal"]=fight.GetHp(2)-4000;
        setup();fight.m_members[0].unitAttr.maxHp=1000;fight.m_members[0].hp=1000;
        shield(4000);absorb(4000);fight.ShieldBrokenCheck(2,enemy);metrics["shield_loss_cap"]=10000-fight.GetHp(enemy);
        setup(10000);breakShield();metrics["shield_loss_full_hp_budget"]=fight.m_combatState.counts[{2,40030,0}].inBattle;
        metrics["shield_loss_full_hp_actions"]=fight.m_extActionMsg.GetType();
        fight.m_members[1].hp=4000;breakShield();metrics["shield_loss_after_full_hp"]=fight.GetHp(2)-4000;
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;breakShield();
        metrics["shield_loss_dead_owner_damage"]=10000-fight.GetHp(enemy);
        setup();fight.SetState(2,EFST_STATE_Die);fight.m_members[1].hp=0;
        fight.OnAffixShieldLost(2,1,1000,true);metrics["shield_loss_dead_recipient_hp"]=fight.GetHp(2);
        setup();std::vector<int> antiheal{5000};fight.AddBuff(2,enemy,ESBUFF_JinLiaoShu,2,&antiheal);breakShield();metrics["shield_loss_antiheal"]=fight.GetHp(2)-4000;
        setup();fight.m_members[0].passive_skill.clear();breakShield();
        fight.m_extActionMsg.ReRead();fight.m_extActionMsg>>type>>source>>presentation;metrics["shield_loss_heal_presentation"]=presentation;
        setup();
        const int previousDepth=fight.m_combatDepth;fight.m_combatDepth=static_cast<int>(catalog.EventDepthLimit("after_owned_shield_loss"));
        fight.OnAffixShieldLost(2,1,1000,true);fight.m_combatDepth=previousDepth;metrics["shield_loss_recursion_damage"]=10000-fight.GetHp(enemy);
        setup();fight.m_combatDepth=1;breakShield();fight.m_combatDepth=0;
        metrics["shield_loss_nested_damage"]=10000-fight.GetHp(enemy);metrics["shield_loss_nested_heal"]=fight.GetHp(2)-4000;
        setup();fight.m_combatDepth=7;breakShield();fight.m_combatDepth=0;
        metrics["shield_loss_deep_heal"]=fight.GetHp(2)-4000;
        metrics["shield_loss_passed"]=metrics["shield_loss_damage"]==240 && metrics["shield_loss_other_damage"]==240 && metrics["shield_loss_heal"]==400
            && metrics["shield_loss_nested_damage"]==240 && metrics["shield_loss_nested_heal"]==400 && metrics["shield_loss_deep_heal"]==400
            && metrics["shield_loss_repeat_damage"]==240 && metrics["shield_loss_repeat_heal"]==400
            && metrics["shield_loss_next_damage"]==480 && metrics["shield_loss_next_heal"]==800
            && metrics["shield_loss_unused_damage"]==0 && metrics["shield_loss_unused_heal"]==0 && metrics["shield_loss_after_unused"]==240
            && metrics["shield_loss_before_expire"]==0 && metrics["shield_loss_partial_expire"]==72 && metrics["shield_loss_expire_heal"]==400
            && metrics["shield_loss_partial_dispel"]==72 && metrics["shield_loss_dispel_heal"]==400 && metrics["shield_loss_cap"]==300
            && metrics["shield_loss_full_hp_budget"]==1 && metrics["shield_loss_full_hp_actions"]==2 && metrics["shield_loss_after_full_hp"]==0
            && metrics["shield_loss_dead_owner_damage"]==240 && metrics["shield_loss_dead_recipient_hp"]==0 && metrics["shield_loss_antiheal"]==200
            && metrics["shield_loss_recursion_damage"]==0 && metrics["shield_loss_damage_presentation"]==5001
            && metrics["shield_loss_heal_presentation"]==5003 && overkillMetrics.at("overkill_presentation")==5019?1:0;
        return metrics;
    }();
    for(const auto& metric:shieldLossMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto shieldShareMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,100);unit(2,23,0,4000);unit(3,23,0,7000);unit(enemy,23,0,10000);affix(1,2,3);
            std::srand(1729);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto shield=[&](int amount=1000,int duration=3) {std::vector<int> parameters{amount,amount};fight.AddBuff(1,1,ESBUFF_Shield,duration,&parameters);};
        setup();const int expectedRandom=std::rand();std::srand(1729);shield();metrics["share_rng_parity"]=std::rand()==expectedRandom?1:0;
        metrics["share_ally_shield"]=fight.GetStatePara1(2,ESBUFF_Shield);metrics["share_self_shield"]=fight.GetStatePara1(1,ESBUFF_Shield);
        metrics["share_duration"]=lastDuration(2,ESBUFF_Shield);metrics["share_other_ally"]=fight.GetStatePara1(3,ESBUFF_Shield);
        shield(2000);metrics["share_repeat_shield"]=fight.GetStatePara1(2,ESBUFF_Shield);
        ++fight.m_fightTurn;fight.ClearBuff(2,ESBUFF_Shield);shield();metrics["share_next_turn"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup();fight.m_members[1].hp=1000;fight.m_members[2].hp=2000;fight.m_members[2].unitAttr.maxHp=100000;shield();
        metrics["share_low_ratio"]=fight.GetStatePara1(3,ESBUFF_Shield);metrics["share_low_absolute"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup();fight.m_members[1].unitAttr.maxHp=100000;fight.m_members[1].hp=4009;fight.m_members[2].unitAttr.maxHp=100000;fight.m_members[2].hp=4001;shield();
        metrics["share_integer_tie"]=fight.GetStatePara1(2,ESBUFF_Shield);metrics["share_tie_later"]=fight.GetStatePara1(3,ESBUFF_Shield);
        setup();fight.m_members[1].memPtr=boost::any();fight.m_members[2].memPtr=boost::any();shield();
        metrics["share_empty_budget"]=fight.m_combatState.counts[{1,40020,0}].inBattle;
        unit(2,23,0,4000);shield();metrics["share_after_empty"]=fight.GetStatePara1(2,ESBUFF_Shield);
        ++fight.m_fightTurn;shield();metrics["share_empty_next"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup();std::vector<int> direct{1000,1000};fight.AddBuff(2,1,ESBUFF_Shield,3,&direct);
        metrics["share_friend_cast_budget"]=fight.m_combatState.counts[{1,40020,0}].inBattle;
        metrics["share_friend_cast_other"]=fight.GetStatePara1(3,ESBUFF_Shield);shield();metrics["share_after_friend_cast"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup();affix(2,2,3);shield();metrics["share_not_chain"]=fight.GetStatePara1(3,ESBUFF_Shield);
        setup();fight.SetState(2,EFST_STATE_Die);fight.m_members[1].hp=0;shield();metrics["share_skip_dead"]=fight.GetStatePara1(3,ESBUFF_Shield);
        setup();shield(1000,255);metrics["share_duration_255"]=lastDuration(2,ESBUFF_Shield);
        setup();shield(1000,0);metrics["share_duration_zero"]=lastDuration(2,ESBUFF_Shield);metrics["share_zero_turn_amount"]=fight.GetStatePara1(2,ESBUFF_Shield);
        metrics["share_zero_turn_budget"]=fight.m_combatState.counts[{1,40020,0}].inBattle;
        setup();shield(20000);const int own=fight.GetStatePara1(1,ESBUFF_Shield);
        metrics["share_post_cap_ratio"]=own?fight.GetStatePara1(2,ESBUFF_Shield)*10000/own:0;
        setup();unit(1,10,1,9903);fight.m_members[0].unitAttr.attack=1000;fight.m_members[1].hp=fight.m_members[2].hp=10000;
        fight.CalculateSkill_AddHp(1,101,1);metrics["share_nested_primary_heal"]=fight.GetStatePara1(2,ESBUFF_Shield);
        metrics["share_nested_duration"]=lastDuration(2,ESBUFF_Shield);
        metrics["share_invalid_duration"]=0;
        for(int invalid:std::vector<int>{0,256}) {
            CombatData::Event event;CombatData::State state;event.name="after_self_shield";event.actor=event.teamActor=1;
            event.contentValues[40020]={{"affix_value1",3000},{"affix_value2",0}};
            event.values={{"shield_amount",1000},{"event_duration",invalid}};
            try {catalog.Execute(event,state,[](int){return 1;},[](const std::string& selector,int){return std::vector<CombatData::Values>{{{"position",selector=="self_any"?1:2}}};},
                [](const CombatData::Values&,const CombatData::Command&){},[](const std::string&){return true;});}
            catch(const std::runtime_error& error){if(std::string(error.what())=="event duration outside 1..255")++metrics["share_invalid_duration"];}
        }
        metrics["share_passed"]=metrics["share_ally_shield"]==300 && metrics["share_self_shield"]==1000 && metrics["share_duration"]==3
            && metrics["share_other_ally"]==0 && metrics["share_repeat_shield"]==300 && metrics["share_next_turn"]==300
            && metrics["share_low_ratio"]==300 && metrics["share_low_absolute"]==0 && metrics["share_integer_tie"]==300 && metrics["share_tie_later"]==0
            && metrics["share_empty_budget"]==1 && metrics["share_after_empty"]==0 && metrics["share_empty_next"]==300
            && metrics["share_friend_cast_budget"]==0 && metrics["share_friend_cast_other"]==0 && metrics["share_after_friend_cast"]==300
            && metrics["share_not_chain"]==0 && metrics["share_skip_dead"]==300 && metrics["share_duration_255"]==255
            && metrics["share_duration_zero"]==0 && metrics["share_zero_turn_amount"]==0 && metrics["share_zero_turn_budget"]==0 && metrics["share_invalid_duration"]==2 && metrics["share_post_cap_ratio"]==3000
            && metrics["share_nested_primary_heal"]==39 && metrics["share_nested_duration"]==2 && metrics["share_rng_parity"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:shieldShareMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto guardAffixMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(enemy,23,0,10000);
            fight.m_members[0].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.attack=2000;
            fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;fight.m_members[1].unitAttr.baojikangLv=10000;
            affix(1,9,3);affix(1,11,3);std::vector<int> protect{5000,0,1};fight.AddBuff(2,1,ESBUFF_Protect,3,&protect);
            std::srand(1729);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto strike=[&]() {std::vector<SAttrData> own,other;int self=0;fight.BasicFightAction(enemy,2,0,1,self,own,other,false,true);};
        auto event=[&]() {fight.CombatEvent("after_guard_damage",1,enemy,0,0,1,{{"attacker_alive",fight.IsAlive(enemy)?1:0}});};
        setup();metrics["guard_reduced_1001"]=fight.CombatShareDamage(1,1001);
        setup();strike();metrics["guard_real_counter"]=10000-fight.GetHp(enemy);
        metrics["guard_real_guardian_loss"]=10000-fight.GetHp(1);metrics["guard_real_ally_loss"]=10000-fight.GetHp(2);
        const int withAffixRandom=std::rand();
        setup();fight.m_members[0].passive_skill.clear();strike();
        metrics["guard_without_reduction"]=10000-fight.GetHp(1);metrics["guard_rng_parity"]=std::rand()==withAffixRandom?1:0;
        setup();event();event();event();metrics["guard_repeat_damage"]=10000-fight.GetHp(enemy);
        ++fight.m_fightTurn;event();metrics["guard_next_turn_damage"]=10000-fight.GetHp(enemy);
        setup();for(int i=0;i<catalog.Rule("extra_attack_per_turn");++i)fight.CombatTryExtraAttack(1);event();
        metrics["guard_exhausted_damage"]=10000-fight.GetHp(enemy);metrics["guard_exhausted_affix_count"]=fight.m_combatState.counts[{1,40090,0}].inBattle;
        fight.m_combatState.extraAttacks.clear();event();event();metrics["guard_after_exhaustion_damage"]=10000-fight.GetHp(enemy);
        setup();fight.m_members[0].unitAttr.attack=0;event();
        metrics["guard_zero_damage"]=10000-fight.GetHp(enemy);metrics["guard_zero_affix_count"]=fight.m_combatState.counts[{1,40090,0}].inBattle;
        metrics["guard_zero_extra_remaining"]=(fight.CombatTryExtraAttack(1)?1:0)+(fight.CombatTryExtraAttack(1)?1:0);
        setup();fight.SetState(enemy,EFST_STATE_Die);fight.m_members[enemy-1].hp=0;event();
        metrics["guard_dead_attacker_count"]=fight.m_combatState.counts[{1,40090,0}].inBattle;
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;event();
        metrics["guard_dead_owner_damage"]=10000-fight.GetHp(enemy);metrics["guard_dead_owner_count"]=fight.m_combatState.counts[{1,40090,0}].inBattle;
        setup();std::vector<int> shield{10000,10000};fight.AddBuff(1,1,ESBUFF_Shield,3,&shield);strike();
        metrics["guard_absorbed_loss"]=10000-fight.GetHp(1);metrics["guard_absorbed_counter"]=10000-fight.GetHp(enemy);
        setup();fight.m_members[0].hp=1;strike();metrics["guard_lethal_counter"]=10000-fight.GetHp(enemy);
        setup();fight.m_combatDepth=static_cast<int>(catalog.Rule("secondary_depth_max"));event();
        metrics["guard_depth_count"]=fight.m_combatState.counts[{1,40090,0}].inBattle;fight.m_combatDepth=0;
        setup();fight.m_members[0].unitAttr.attack=20000;strike();
        metrics["guard_killed_attacker"]=fight.IsAlive(enemy)?0:1;metrics["guard_primary_after_kill"]=10000-fight.GetHp(2);
        setup();event();fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 presentation=0;
        fight.m_extActionMsg>>type>>source>>presentation;metrics["guard_presentation"]=presentation;
        metrics["guard_passed"]=metrics["guard_reduced_1001"]==800 && metrics["guard_real_counter"]==800
            && metrics["guard_real_guardian_loss"]==399 && metrics["guard_real_ally_loss"]==499 && metrics["guard_without_reduction"]==499
            && metrics["guard_rng_parity"]==1 && metrics["guard_repeat_damage"]==1600 && metrics["guard_next_turn_damage"]==2400
            && metrics["guard_exhausted_damage"]==0 && metrics["guard_exhausted_affix_count"]==1 && metrics["guard_after_exhaustion_damage"]==800
            && metrics["guard_zero_damage"]==0 && metrics["guard_zero_affix_count"]==1 && metrics["guard_zero_extra_remaining"]==2
            && metrics["guard_dead_attacker_count"]==0 && metrics["guard_dead_owner_count"]==0 && metrics["guard_dead_owner_damage"]==0
            && metrics["guard_absorbed_loss"]==0 && metrics["guard_absorbed_counter"]==800 && metrics["guard_lethal_counter"]==0
            && metrics["guard_depth_count"]==0 && metrics["guard_killed_attacker"]==1 && metrics["guard_primary_after_kill"]==499 && metrics["guard_presentation"]==5009?1:0;
        return metrics;
    }();
    for(const auto& metric:guardAffixMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto breakDispelMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(enemy,23,0,10000);
            fight.m_members[0].attackType=1;affix(1,26,3);affix(1,28,3);affix(1,38,3);
            std::srand(1729);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto shield=[&](uint8 owner=0) {std::vector<int> p{100,100};fight.AddBuff(enemy,owner?owner:enemy,ESBUFF_Shield,2,&p);};
        auto breakShield=[&](int amount=100) {int absorbed=0;fight.DecreaseHp(enemy,1,amount,absorbed,false);fight.ShieldBrokenCheck(enemy,1);};
        auto dispel=[&](uint8 target) {std::vector<int> p{1000};fight.AddBuff(target,target,ESBUFF_AddSpeed,2,&p);fight.ClearBuff(target,ESBUFF_AddSpeed,nullptr,1);};
        auto duration=[&](uint8 target,int buff) {int turns=0;for(const auto& b:fight.m_members[target-1].buff_list)if(b.id==buff)turns=b.leftTurn;return turns;};
        setup();const int expectedRandom=std::rand();std::srand(1729);shield();breakShield();
        metrics["break_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetDamageAdd);metrics["break_duration"]=duration(enemy,ESBUFF_GetDamageAdd);
        metrics["break_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);metrics["break_defense_duration"]=duration(enemy,ESBUFF_WuFangDes);
        metrics["break_rage"]=fight.GetTeamRage(1);metrics["break_actions"]=fight.m_extActionMsg.GetType();metrics["break_rng_parity"]=std::rand()==expectedRandom?1:0;
        shield();breakShield();metrics["break_repeat_rage"]=fight.GetTeamRage(1);
        ++fight.m_fightTurn;shield();breakShield();metrics["break_next_rage"]=fight.GetTeamRage(1);
        setup();dispel(enemy);metrics["dispel_rage"]=fight.GetTeamRage(1);shield();breakShield();metrics["dispel_then_break_rage"]=fight.GetTeamRage(1);
        metrics["dispel_shared_count"]=fight.m_combatState.counts[{1,40280,0}].inBattle;
        setup();shield();breakShield();dispel(enemy);metrics["break_then_dispel_rage"]=fight.GetTeamRage(1);
        setup();dispel(2);metrics["dispel_friendly_rage"]=fight.GetTeamRage(1);
        std::vector<int> p{1000};fight.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&p);fight.ClearBuff(enemy,ESBUFF_GetDamageAdd,nullptr,1);
        metrics["dispel_debuff_rage"]=fight.GetTeamRage(1);
        setup();fight.ShieldBrokenCheck(enemy,1);metrics["break_missing_rage"]=fight.GetTeamRage(1);
        shield();int partial=50,absorbed=0;fight.DecreaseHp(enemy,1,partial,absorbed,false);fight.ShieldBrokenCheck(enemy,1);
        metrics["break_partial_rage"]=fight.GetTeamRage(1);metrics["break_partial_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetDamageAdd);
        setup();shield();shield(1);breakShield(200);metrics["break_multiple_count"]=fight.m_combatState.counts[{1,40280,0}].inBattle;
        setup();fight.m_combatDepth=1;shield();breakShield();metrics["break_secondary_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);fight.m_combatDepth=0;
        setup();fight.m_combatDepth=catalog.EventDepthLimit("after_shield_break");shield();breakShield();
        metrics["break_depth_rage"]=fight.GetTeamRage(1);metrics["break_depth_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetDamageAdd);fight.m_combatDepth=0;
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;shield();breakShield();
        metrics["break_dead_source_rage"]=fight.GetTeamRage(1);metrics["break_dead_source_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        setup();fight.SetState(enemy,EFST_STATE_Die);fight.m_members[enemy-1].hp=0;shield();breakShield();
        metrics["break_dead_target_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetDamageAdd);
        metrics["break_dead_target_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        for(int buff:std::vector<int>{ESBUFF_GetDamageAdd,ESBUFF_GetWuDamageAdd,ESBUFF_GetFaDamageAdd})for(int attackType:std::vector<int>{0,1,2}) {
            setup();fight.m_members[0].attackType=attackType;fight.AddBuff(enemy,1,buff,2,&p);
            const std::string key="mark_"+std::to_string(buff)+"_"+std::to_string(attackType);
            metrics[key]=fight.GetStatePara1(enemy,attackType==1?ESBUFF_WuFangDes:ESBUFF_FaFangDes);
            metrics[key+"_other"]=fight.GetStatePara1(enemy,attackType==1?ESBUFF_FaFangDes:ESBUFF_WuFangDes);
        }
        setup();fight.AddBuff(enemy,1,ESBUFF_AddSpeed,2,&p);metrics["mark_unrelated"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        setup();fight.AddBuff(enemy,1,ESBUFF_GetDamageAdd,0,&p);metrics["mark_rejected_duration"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        setup();fight.m_members[0].passive_skill.clear();affix(1,26,3);affix(1,38,3);shield();breakShield();
        metrics["mark_silent_actions"]=fight.m_extActionMsg.GetType();
        setup();fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_GetDamageAdd);
        fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_WuFangDes);shield();breakShield();
        metrics["break_immune_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetDamageAdd);
        metrics["break_immune_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        bool marks=true;for(int buff:std::vector<int>{21,22,23})for(int attackType:std::vector<int>{0,1,2}) {
            const std::string key="mark_"+std::to_string(buff)+"_"+std::to_string(attackType);
            marks=marks && metrics[key]==800 && metrics[key+"_other"]==0;
        }
        metrics["break_dispel_passed"]=marks && metrics["break_vulnerability"]==1200 && metrics["break_duration"]==2
            && metrics["break_defense"]==800 && metrics["break_defense_duration"]==2 && metrics["break_rage"]==7 && metrics["break_actions"]==1
            && metrics["break_rng_parity"]==1 && metrics["break_repeat_rage"]==7 && metrics["break_next_rage"]==14
            && metrics["dispel_rage"]==7 && metrics["dispel_then_break_rage"]==7 && metrics["dispel_shared_count"]==1 && metrics["break_then_dispel_rage"]==7
            && metrics["dispel_friendly_rage"]==0 && metrics["dispel_debuff_rage"]==0 && metrics["break_missing_rage"]==0
            && metrics["break_partial_rage"]==0 && metrics["break_partial_vulnerability"]==0 && metrics["break_multiple_count"]==1
            && metrics["break_secondary_defense"]==800 && metrics["break_depth_rage"]==0 && metrics["break_depth_vulnerability"]==0
            && metrics["break_dead_source_rage"]==7 && metrics["break_dead_source_defense"]==800 && metrics["break_dead_target_vulnerability"]==1200
            && metrics["break_dead_target_defense"]==800 && metrics["mark_unrelated"]==0 && metrics["mark_rejected_duration"]==0 && metrics["mark_silent_actions"]==0
            && metrics["break_immune_vulnerability"]==1200 && metrics["break_immune_defense"]==800?1:0;
        return metrics;
    }();
    for(const auto& metric:breakDispelMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto cleanseDispelMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(enemy,23,0,10000);
            affix(1,7,3);affix(1,40,3);std::srand(1729);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto remove=[&](uint8 target,int buff,uint8 remover=1) {
            std::vector<int> p{1000};fight.AddBuff(target,enemy,buff,2,&p);fight.ClearBuff(target,buff,nullptr,remover);
        };
        auto count=[&](uint8 target,int buff) {int n=0;for(const auto& b:fight.m_members[target-1].buff_list)if(b.id==buff)++n;return n;};
        auto duration=[&](uint8 target,int buff) {int turns=0;for(const auto& b:fight.m_members[target-1].buff_list)if(b.id==buff)turns=b.leftTurn;return turns;};
        setup();const int expectedRandom=std::rand();std::srand(1729);remove(2,ESBUFF_GetDamageAdd);
        metrics["cleanse_guard"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);metrics["cleanse_duration"]=duration(2,ESBUFF_MianShangTemp);
        metrics["cleanse_actions"]=fight.m_extActionMsg.GetType();metrics["cleanse_rng_parity"]=std::rand()==expectedRandom?1:0;
        remove(2,ESBUFF_GetDamageAdd);metrics["cleanse_repeat_count"]=count(2,ESBUFF_MianShangTemp);
        setup();remove(1,ESBUFF_GetDamageAdd);metrics["cleanse_self"]=fight.GetStatePara1(1,ESBUFF_MianShangTemp);
        setup();remove(2,ESBUFF_AddSpeed);metrics["cleanse_friendly_buff"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup();remove(enemy,ESBUFF_GetDamageAdd);metrics["strip_enemy_debuff"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        setup();remove(2,ESBUFF_GetDamageAdd,0);metrics["cleanse_no_remover"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;remove(2,ESBUFF_GetDamageAdd);
        metrics["cleanse_dead_source"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup();fight.SetState(2,EFST_STATE_Die);fight.m_members[1].hp=0;remove(2,ESBUFF_GetDamageAdd);
        metrics["cleanse_dead_target"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup();fight.m_members[1].notEffectBuff.push_back(ESBUFF_MianShangTemp);remove(2,ESBUFF_GetDamageAdd);
        metrics["cleanse_immune_target"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        setup();fight.m_combatDepth=catalog.EventDepthLimit("after_friendly_cleanse");remove(2,ESBUFF_GetDamageAdd);
        metrics["cleanse_depth_guard"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);fight.m_combatDepth=0;
        setup();remove(enemy,ESBUFF_AddSpeed);
        metrics["strip_attack"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);metrics["strip_speed"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        metrics["strip_attack_duration"]=duration(1,ESBUFF_DamagePercentAdd);metrics["strip_speed_duration"]=duration(1,ESBUFF_AddSpeed);
        metrics["strip_actions"]=fight.m_extActionMsg.GetType();metrics["strip_budget"]=fight.m_combatState.counts[{1,40400,0}].inBattle;
        remove(enemy,ESBUFF_AddSpeed);metrics["strip_repeat_count"]=count(1,ESBUFF_DamagePercentAdd);
        ++fight.m_fightTurn;remove(enemy,ESBUFF_AddSpeed);metrics["strip_next_count"]=count(1,ESBUFF_DamagePercentAdd);
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;remove(enemy,ESBUFF_AddSpeed);
        metrics["strip_dead_source"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
        setup();fight.SetState(enemy,EFST_STATE_Die);fight.m_members[enemy-1].hp=0;remove(enemy,ESBUFF_AddSpeed);
        metrics["strip_dead_target"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
        setup();fight.m_members[0].notEffectBuff.push_back(ESBUFF_DamagePercentAdd);fight.m_members[0].notEffectBuff.push_back(ESBUFF_AddSpeed);
        remove(enemy,ESBUFF_AddSpeed);metrics["strip_immune_attack"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
        metrics["strip_immune_speed"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        setup();affix(1,28,3);remove(enemy,ESBUFF_AddSpeed);metrics["strip_with_rage"]=fight.GetTeamRage(1);
        metrics["strip_with_rage_actions"]=fight.m_extActionMsg.GetType();metrics["strip_with_rage_attack"]=fight.GetStatePara1(1,ESBUFF_DamagePercentAdd);
        metrics["cleanse_dispel_passed"]=metrics["cleanse_guard"]==1200 && metrics["cleanse_duration"]==1 && metrics["cleanse_actions"]==0
            && metrics["cleanse_rng_parity"]==1 && metrics["cleanse_repeat_count"]==2 && metrics["cleanse_self"]==1200
            && metrics["cleanse_friendly_buff"]==0 && metrics["strip_enemy_debuff"]==0 && metrics["cleanse_no_remover"]==0
            && metrics["cleanse_dead_source"]==1200 && metrics["cleanse_dead_target"]==1200 && metrics["cleanse_immune_target"]==1200 && metrics["cleanse_depth_guard"]==0
            && metrics["strip_attack"]==1000 && metrics["strip_speed"]==1000 && metrics["strip_attack_duration"]==2 && metrics["strip_speed_duration"]==2
            && metrics["strip_actions"]==0 && metrics["strip_budget"]==1 && metrics["strip_repeat_count"]==1 && metrics["strip_next_count"]==2
            && metrics["strip_dead_source"]==1000 && metrics["strip_dead_target"]==1000 && metrics["strip_immune_attack"]==1000 && metrics["strip_immune_speed"]==1000
            && metrics["strip_with_rage"]==7 && metrics["strip_with_rage_actions"]==1 && metrics["strip_with_rage_attack"]==1000?1:0;
        return metrics;
    }();
    for(const auto& metric:cleanseDispelMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto healBudgetMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int id,int hp=1000) {
            fight.Clear();unit(1,23,0,hp);unit(2,23,0,1000);unit(3,23,0,1000);unit(enemy,23,0,100000);
            fight.m_members[enemy-1].unitAttr.maxHp=100000;fight.m_members[0].unitAttr.attack=10000;
            affix(1,id,3);std::srand(1729);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto taunt=[&]() {fight.CombatEvent("after_buff",1,enemy,0,ESBUFF_ChaoFeng,1,{});};
        auto counter=[&](int amount=10000) {fight.CombatEvent("after_counter_damage",1,enemy,0,0,1,{{"amount",amount}});};
        auto periodic=[&](int amount=10000) {fight.CombatEvent("after_periodic_damage",1,enemy,0,ESBUFF_ZhuoShao,1,{{"amount",amount}});};
        auto nativeTaunt=[&](int duration=2) {std::vector<int> p{1};fight.AddBuff(enemy,1,ESBUFF_ChaoFeng,duration,&p);};
        auto nativeDot=[&]() {CNetMessage msg;fight.CombatPeriodicActions(enemy,EFStep_UserActBegin,msg,0);};
        auto burning=[&]() {std::vector<int> p{10000};fight.AddBuff(enemy,1,ESBUFF_ZhuoShao,3,&p);};
        auto antiheal=[&]() {std::vector<int> p{10000};fight.AddBuff(1,enemy,ESBUFF_JinLiaoShu,2,&p);};
        setup(10);taunt();metrics["budget_taunt_first"]=fight.GetHp(1)-1000;taunt();taunt();
        metrics["budget_taunt_repeat"]=fight.GetHp(1)-1000;metrics["budget_taunt_friend_heal"]=fight.GetHp(2)-1000;
        ++fight.m_fightTurn;taunt();metrics["budget_taunt_next"]=fight.GetHp(1)-1000;
        setup(10);nativeTaunt();metrics["budget_taunt_native"]=fight.GetHp(1)-1000;
        setup(10);nativeTaunt(0);metrics["budget_taunt_rejected"]=fight.GetHp(1)-1000;
        setup(10);antiheal();taunt();metrics["budget_taunt_antiheal"]=fight.GetHp(1)-1000;
        setup(10,10000);taunt();metrics["budget_taunt_full_spent"]=fight.m_combatState.amounts[{1,40100}].spent;
        metrics["budget_taunt_full_actions"]=fight.m_extActionMsg.GetType();fight.m_members[0].hp=1000;taunt();taunt();
        metrics["budget_taunt_after_full"]=fight.GetHp(1)-1000;
        setup(10,0);fight.SetState(1,EFST_STATE_Die);taunt();metrics["budget_taunt_dead_restore"]=fight.GetHp(1);
        setup(10,0);fight.SetState(1,EFST_STATE_Die);std::vector<int> forbid{0};fight.AddBuff(1,enemy,ESBUFF_ForbidFuHuo,2,&forbid);
        taunt();metrics["budget_taunt_failed_revive_spent"]=fight.m_combatState.amounts[{1,40100}].spent;
        fight.ClearBuff(1,ESBUFF_ForbidFuHuo);taunt();taunt();metrics["budget_taunt_after_failed_revive"]=fight.GetHp(1);
        setup(13);counter();metrics["budget_counter_first"]=fight.GetHp(1)-1000;counter();metrics["budget_counter_repeat"]=fight.GetHp(1)-1000;
        ++fight.m_fightTurn;counter();metrics["budget_counter_next"]=fight.GetHp(1)-1000;
        setup(13);counter(0);metrics["budget_counter_zero_spent"]=fight.m_combatState.amounts[{1,40130}].spent;
        setup(13);antiheal();counter();metrics["budget_counter_antiheal"]=fight.GetHp(1)-1000;
        setup(13,10000);counter();fight.m_members[0].hp=1000;counter();metrics["budget_counter_after_full"]=fight.GetHp(1)-1000;
        setup(13,0);fight.SetState(1,EFST_STATE_Die);counter();metrics["budget_counter_dead_restore"]=fight.GetHp(1);
        setup(13);fight.m_members[0].unitAttr.fanjiAdd=10000;fight.m_members[0].unitAttr.mingzhongLv=10000;
        fight.m_members[enemy-1].unitAttr.baojikangLv=10000;std::vector<SAttrData> own,other;int self=0;
        fight.BasicFightAction(1,enemy,0,1,self,own,other,true,true);metrics["budget_counter_native"]=fight.GetHp(1)-1000;
        setup(13);fight.m_members[0].unitAttr.fanjiLv=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
        fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.baojikangLv=10000;
        fight.m_members[enemy-1].unitAttr.attack=1;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
        self=0;fight.CalculateOnceAction(enemy,1,0,1,self,true);
        metrics["budget_counter_natural"]=fight.m_members[0].sum_cure;metrics["budget_counter_natural_extra"]=fight.m_combatState.extraAttacks[1].inTurn;
        setup(36);periodic();metrics["budget_dot_first"]=fight.GetHp(1)-1000;periodic();metrics["budget_dot_repeat"]=fight.GetHp(1)-1000;
        ++fight.m_fightTurn;periodic();metrics["budget_dot_next"]=fight.GetHp(1)-1000;
        setup(36);antiheal();periodic();metrics["budget_dot_antiheal"]=fight.GetHp(1)-1000;
        setup(36);burning();nativeDot();metrics["budget_dot_native"]=fight.GetHp(1)-1000;
        setup(36);fight.m_combatDepth=1;burning();nativeDot();metrics["budget_dot_secondary_native"]=fight.GetHp(1)-1000;fight.m_combatDepth=0;
        setup(36,10000);burning();nativeDot();fight.m_members[0].hp=1000;nativeDot();metrics["budget_dot_after_full"]=fight.GetHp(1)-1000;
        setup(36,0);fight.SetState(1,EFST_STATE_Die);burning();nativeDot();metrics["budget_dot_dead_restore"]=fight.GetHp(1);
        setup(36);std::vector<int> shield{20000,20000};fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&shield);burning();nativeDot();
        metrics["budget_dot_absorbed_heal"]=fight.GetHp(1)-1000;metrics["budget_dot_absorbed_spent"]=fight.m_combatState.amounts[{1,40360}].spent;
        setup(10);taunt();fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 presentation=0;
        fight.m_extActionMsg>>type>>source>>presentation;metrics["budget_taunt_presentation"]=presentation;
        metrics["heal_budget_passed"]=metrics["budget_taunt_first"]==400 && metrics["budget_taunt_repeat"]==800 && metrics["budget_taunt_next"]==1200
            && metrics["budget_taunt_friend_heal"]==0 && metrics["budget_taunt_native"]==400 && metrics["budget_taunt_rejected"]==0
            && metrics["budget_taunt_antiheal"]==0 && metrics["budget_taunt_full_spent"]==400 && metrics["budget_taunt_full_actions"]==0
            && metrics["budget_taunt_after_full"]==400 && metrics["budget_taunt_dead_restore"]==400
            && metrics["budget_taunt_failed_revive_spent"]==400 && metrics["budget_taunt_after_failed_revive"]==400
            && metrics["budget_counter_first"]==800 && metrics["budget_counter_repeat"]==800 && metrics["budget_counter_next"]==1600
            && metrics["budget_counter_zero_spent"]==0 && metrics["budget_counter_antiheal"]==0 && metrics["budget_counter_after_full"]==0
            && metrics["budget_counter_dead_restore"]==800 && metrics["budget_counter_native"]==800 && metrics["budget_counter_natural"]==800 && metrics["budget_counter_natural_extra"]==1
            && metrics["budget_dot_first"]==600 && metrics["budget_dot_repeat"]==600 && metrics["budget_dot_next"]==1200
            && metrics["budget_dot_antiheal"]==0 && metrics["budget_dot_native"]==600 && metrics["budget_dot_secondary_native"]==600 && metrics["budget_dot_after_full"]==0
            && metrics["budget_dot_dead_restore"]==0 && metrics["budget_dot_absorbed_heal"]==0 && metrics["budget_dot_absorbed_spent"]==0
            && metrics["budget_taunt_presentation"]==5010?1:0;
        return metrics;
    }();
    for(const auto& metric:healBudgetMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto chanceMetrics=[&]() {
        CombatData::Values metrics;
        const auto* ownRole=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(15);
        if(!ownRole)throw std::runtime_error("missing chance fixture skill role");
        int successSeed=0,failureSeed=0;
        for(int seed=1;!successSeed || !failureSeed;++seed){std::srand(seed);const int draw=Random(1,10000);if(draw<=2000 && !successSeed)successSeed=seed;if(draw>9000 && !failureSeed)failureSeed=seed;}
        auto setup=[&](int id,bool dead=false) {
            fight.Clear();unit(1,15,0,dead?0:10000);unit(enemy,23,0,100000);
            fight.m_members[enemy-1].unitAttr.maxHp=100000;
            for(uint16 skill:{ownRole->regularSkillId,ownRole->tacticSkillId}){SSkillData data(skill,1);data.leftCD=6;data.CD=6;fight.m_members[0].skill_list.push_back(data);}
            if(id)affix(1,id,3);
            if(dead)fight.SetState(1,EFST_STATE_Die);
        };
        auto trigger=[&](int id){
            if(id==31)fight.OnAffixControlResisted(1,enemy);
            else fight.CombatEvent(id==15?"after_counter_success":"after_kill_rewards",1,enemy,0,0,1,{});
        };
        auto regular=[&](){return 6-fight.m_members[0].skill_list[0].leftCD;};
        auto tactic=[&](){return 6-fight.m_members[0].skill_list[1].leftCD;};
        for(int id:{15,20,31}) {
            const std::string key="chance_"+std::to_string(id);
            setup(id);std::srand(successSeed);const int roll=Random(1,10000),expectedNext=std::rand();
            std::srand(successSeed);trigger(id);metrics[key+"_first"]=id==31?fight.GetTeamRage(1):regular();
            metrics[key+"_tactic"]=tactic();metrics[key+"_rng"]=std::rand()==expectedNext;
            metrics[key+"_roll"]=roll;
            trigger(id);metrics[key+"_repeat"]=id==31?fight.GetTeamRage(1):regular();
            ++fight.m_fightTurn;std::srand(successSeed);trigger(id);metrics[key+"_next"]=id==31?fight.GetTeamRage(1):regular();
            setup(id);std::srand(failureSeed);trigger(id);metrics[key+"_failed"]=id==31?fight.GetTeamRage(1):regular();
            metrics[key+"_failed_attempts"]=fight.m_combatState.counts[{1,40000+id*10,0}].inBattle;
            std::srand(successSeed);trigger(id);metrics[key+"_failed_retry"]=id==31?fight.GetTeamRage(1):regular();
            setup(id,true);std::srand(successSeed);trigger(id);metrics[key+"_dead"]=id==31?fight.GetTeamRage(1):regular();
            setup(id);fight.m_combatDepth=1;std::srand(successSeed);trigger(id);metrics[key+"_secondary"]=id==31?fight.GetTeamRage(1):regular();fight.m_combatDepth=0;
            setup(id);std::srand(successSeed);fight.CombatEvent("after_hit",1,enemy,0,0,1,{{"amount",1}});
            const int untouched=std::rand();std::srand(successSeed);metrics[key+"_unrelated_rng"]=untouched==std::rand();
        }
        auto counterRoute=[&](bool equipped) {
            setup(equipped?15:0);fight.m_members[0].unitAttr.attack=100;
            fight.m_members[0].unitAttr.fanjiLv=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
            fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.baojikangLv=10000;
            fight.m_members[enemy-1].unitAttr.attack=1;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
            std::srand(1729);int self=0;fight.CalculateOnceAction(enemy,1,0,1,self,true);
        };
        counterRoute(false);const int counterRoll=Random(1,10000),counterNext=std::rand();
        counterRoute(true);metrics["chance_counter_native"]=regular();metrics["chance_counter_native_roll"]=counterRoll;
        metrics["chance_counter_native_rng"]=std::rand()==counterNext;
        metrics["chance_counter_native_extra"]=fight.m_combatState.extraAttacks[1].inTurn;
        setup(31);fight.m_members[0].unitAttr.attack=100;fight.m_members[0].unitAttr.mingzhongLv=10000;
        fight.m_members[enemy-1].unitAttr.fumianKangAdd=50000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
        std::srand(1729);fight.CalculateSkill_DamageHp(1,612,1);
        metrics["chance_control_native"]=fight.GetTeamRage(1);
        metrics["chance_control_native_attempts"]=fight.m_combatState.counts[{1,40310,0}].inBattle;
        metrics["chance_control_native_buff"]=fight.HaveBuff(enemy,ESBUFF_ChaoFeng)?1:0;
        auto fullKill=[&](bool equipped,bool summoned=false) {
            setup(equipped?20:0);fight.m_members[0].unitAttr.attack=100000;
            fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[0].unitAttr.baojikangLv=10000;
            fight.m_members[enemy-1].hp=1;fight.m_members[enemy-1].unitAttr.attack=0;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
            fight.m_members[enemy-1].affixSummoned=summoned;
            std::srand(1729);CNetMessage message;fight.CalculateFight(message);
            return fight.m_members[0].skill_list[0].leftCD;
        };
        const int withoutKillAffix=fullKill(false);metrics["chance_kill_native_delta"]=withoutKillAffix-fullKill(true);
        const int withoutSummonAffix=fullKill(false,true);metrics["chance_kill_summon_delta"]=withoutSummonAffix-fullKill(true,true);
        metrics["chance_passed"]=metrics["chance_15_first"]==1 && metrics["chance_15_repeat"]==1 && metrics["chance_15_next"]==2 && metrics["chance_15_tactic"]==0
            && metrics["chance_15_failed"]==0 && metrics["chance_15_failed_retry"]==0 && metrics["chance_15_failed_attempts"]==1
            && metrics["chance_20_first"]==1 && metrics["chance_20_repeat"]==1 && metrics["chance_20_next"]==2 && metrics["chance_20_tactic"]==1
            && metrics["chance_31_first"]==8 && metrics["chance_31_repeat"]==8 && metrics["chance_31_next"]==16
            && metrics["chance_31_failed"]==0 && metrics["chance_31_failed_retry"]==0 && metrics["chance_31_failed_attempts"]==1
            && metrics["chance_15_dead"]==1 && metrics["chance_20_dead"]==1 && metrics["chance_31_dead"]==8
            && metrics["chance_15_secondary"]==1 && metrics["chance_31_secondary"]==8 && metrics["chance_20_secondary"]==0
            && metrics["chance_15_rng"]==1 && metrics["chance_20_rng"]==1 && metrics["chance_31_rng"]==1
            && metrics["chance_15_unrelated_rng"]==1 && metrics["chance_20_unrelated_rng"]==1 && metrics["chance_31_unrelated_rng"]==1
            && metrics["chance_counter_native_rng"]==1 && metrics["chance_counter_native_extra"]==1
            && metrics["chance_control_native_attempts"]==1 && metrics["chance_control_native_buff"]==0
            && metrics["chance_kill_native_delta"]==1 && metrics["chance_kill_summon_delta"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:chanceMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto deathAffixMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](bool stacks=false) {
            fight.Clear();unit(1,23,0,0);unit(2,23,0,10000);unit(3,23,0,0);unit(enemy,23,0,10000);
            fight.SetState(1,EFST_STATE_Die);fight.SetState(3,EFST_STATE_Die);affix(1,41,3);
            if(stacks){affix(2,42,3);affix(enemy,42,3);}
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto died=[&](){fight.OnAffixUnitDied(1);};
        auto guard=[&](int pos){return fight.GetStatePara1(pos,ESBUFF_MianShangTemp);};
        auto stack=[&](int pos){return fight.GetStatePara1(pos,ESBUFF_DamagePercentAdd);};
        auto count=[&](int pos){return fight.m_combatState.counts[{pos,40420,0}].inBattle;};
        setup();died();metrics["death_guard_first"]=guard(2);metrics["death_guard_self"]=guard(1);
        metrics["death_guard_dead_ally"]=guard(3);metrics["death_guard_enemy"]=guard(enemy);
        metrics["death_guard_actions"]=fight.m_extActionMsg.GetType();
        for(const auto& buff:fight.m_members[1].buff_list)if(buff.id==ESBUFF_MianShangTemp){metrics["death_guard_duration"]=buff.leftTurn;metrics["death_guard_source"]=buff.srcPos;}
        fight.ClearBuff(2,ESBUFF_MianShangTemp);died();++fight.m_fightTurn;died();metrics["death_guard_repeat"]=guard(2);
        setup();fight.m_members[1].hp=0;fight.SetState(2,EFST_STATE_Die);died();
        metrics["death_guard_empty_attempts"]=fight.m_combatState.counts[{1,40410,0}].inBattle;
        fight.m_members[1].hp=10000;fight.ClearState(2,EFST_STATE_Die);died();metrics["death_guard_after_empty"]=guard(2);
        setup();fight.m_members[0].hp=1000;fight.ClearState(1,EFST_STATE_Die);died();
        metrics["death_guard_alive_self"]=guard(1);metrics["death_guard_alive_other"]=guard(2);
        setup(true);died();metrics["death_stack_friend"]=stack(2);metrics["death_stack_enemy"]=stack(enemy);
        unit(otherEnemy,23,0,0);fight.SetState(otherEnemy,EFST_STATE_Die);fight.OnAffixUnitDied(otherEnemy);
        metrics["death_stack_enemy_victim_friend"]=stack(2);metrics["death_stack_enemy_victim_enemy"]=stack(enemy);
        for(int i=0;i<8;++i)died();metrics["death_stack_capped"]=stack(2);metrics["death_stack_count"]=count(2);
        metrics["death_stack_capped_enemy"]=stack(enemy);metrics["death_stack_actions"]=fight.m_extActionMsg.GetType();
        setup(true);died();fight.ClearBuff(2,ESBUFF_DamagePercentAdd);for(int i=0;i<8;++i)died();
        metrics["death_stack_after_clear"]=stack(2);metrics["death_stack_after_clear_count"]=count(2);
        setup(true);fight.m_members[0].affixSummoned=true;died();metrics["death_guard_summoned"]=guard(2);
        metrics["death_stack_summoned"]=stack(2);metrics["death_stack_summoned_count"]=count(2);
        setup(true);fight.m_members[1].hp=0;fight.SetState(2,EFST_STATE_Die);died();metrics["death_stack_dead_owner"]=count(2);
        setup(true);const int expected=std::rand();std::srand(1729);died();metrics["death_affix_rng"]=std::rand()==expected;
        setup(true);fight.m_combatDepth=1;died();metrics["death_guard_secondary"]=guard(2);metrics["death_stack_secondary"]=stack(2);fight.m_combatDepth=0;
        setup(true);fight.m_combatDepth=2;died();metrics["death_guard_depth_blocked"]=guard(2);metrics["death_stack_depth_blocked"]=stack(2);fight.m_combatDepth=0;
        setup(true);fight.m_members[0].hp=1000;fight.ClearState(1,EFST_STATE_Die);
        int hit=100000,absorbed=0;fight.DecreaseHp(1,enemy,hit,absorbed,true);CNetMessage msg;fight.DiePassiveAcion(msg);
        metrics["death_guard_native"]=guard(2);metrics["death_stack_native"]=stack(2);metrics["death_stack_native_enemy"]=stack(enemy);
        metrics["death_affix_passed"]=metrics["death_guard_first"]==1600 && metrics["death_guard_self"]==0 && metrics["death_guard_dead_ally"]==0 && metrics["death_guard_enemy"]==0
            && metrics["death_guard_actions"]==0 && metrics["death_guard_duration"]==2 && metrics["death_guard_source"]==1 && metrics["death_guard_repeat"]==0
            && metrics["death_guard_empty_attempts"]==1 && metrics["death_guard_after_empty"]==0 && metrics["death_guard_alive_self"]==0 && metrics["death_guard_alive_other"]==1600
            && metrics["death_stack_friend"]==500 && metrics["death_stack_enemy"]==500 && metrics["death_stack_enemy_victim_friend"]==1000 && metrics["death_stack_enemy_victim_enemy"]==1000
            && metrics["death_stack_capped"]==2500 && metrics["death_stack_count"]==5 && metrics["death_stack_capped_enemy"]==2500 && metrics["death_stack_actions"]==0
            && metrics["death_stack_after_clear"]==2000 && metrics["death_stack_after_clear_count"]==5
            && metrics["death_guard_summoned"]==1600 && metrics["death_stack_summoned"]==0 && metrics["death_stack_summoned_count"]==0 && metrics["death_stack_dead_owner"]==0
            && metrics["death_affix_rng"]==1 && metrics["death_guard_secondary"]==1600 && metrics["death_stack_secondary"]==500
            && metrics["death_guard_depth_blocked"]==0 && metrics["death_stack_depth_blocked"]==0
            && metrics["death_guard_native"]==1600 && metrics["death_stack_native"]==500 && metrics["death_stack_native_enemy"]==500?1:0;
        return metrics;
    }();
    for(const auto& metric:deathAffixMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto removedAntihealMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,100000);fight.m_members[enemy-1].unitAttr.maxHp=100000;affix(1,34,3);
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto removed=[&](int turns=3,int value=1000,int buff=ESBUFF_ZhuoShao) {
            SFightBuffData data;data.srcPos=1;data.id=buff;data.leftTurn=turns;data.paraList={value};
            fight.OnAffixBuffRemoved(enemy,0,data,turns==0);
        };
        auto lost=[&](){return 100000-fight.GetHp(enemy);};
        setup();removed();metrics["removed_burn_first"]=lost();removed();metrics["removed_burn_repeat"]=lost();
        setup();removed(0);metrics["removed_burn_expired"]=lost();
        setup();removed(3,10000);metrics["removed_burn_capped"]=lost();
        setup();removed(255,1000);metrics["removed_burn_max_turns"]=lost();
        setup();removed(3,1000,ESBUFF_ShiDu);metrics["removed_other_buff"]=lost();
        setup();removed(3,0);metrics["removed_zero_parameter"]=lost();metrics["removed_zero_actions"]=fight.m_extActionMsg.GetType();
        setup();fight.m_members[0].hp=0;fight.SetState(1,EFST_STATE_Die);removed();metrics["removed_dead_source"]=lost();
        setup();fight.m_members[enemy-1].hp=0;fight.SetState(enemy,EFST_STATE_Die);removed();
        metrics["removed_dead_target_actions"]=fight.m_extActionMsg.GetType();metrics["removed_dead_target_kills"]=fight.m_members[0].killList.size();
        setup();fight.m_members[enemy-1].hp=0;fight.SetState(enemy,EFST_STATE_Die);std::vector<int> shield{2000,2000};
        fight.AddBuff(enemy,1,ESBUFF_Shield,2,&shield);removed();
        metrics["removed_dead_shield_left"]=fight.GetStatePara1(enemy,ESBUFF_Shield);metrics["removed_dead_shield_actions"]=fight.m_extActionMsg.GetType();
        setup();fight.AddBuff(enemy,1,ESBUFF_Shield,2,&shield);removed();metrics["removed_shield_hp_loss"]=lost();metrics["removed_shield_left"]=fight.GetStatePara1(enemy,ESBUFF_Shield);
        setup();std::vector<int> burn{1000};fight.AddBuff(enemy,1,ESBUFF_ZhuoShao,3,&burn);fight.ClearBuff(enemy,ESBUFF_ZhuoShao);
        metrics["removed_burn_clear_native"]=lost();
        setup();fight.AddBuff(enemy,1,ESBUFF_ZhuoShao,1,&burn);fight.DecAllStateEffectTurn(enemy);metrics["removed_burn_expire_native"]=lost();
        setup();fight.m_combatDepth=1;removed();metrics["removed_burn_secondary"]=lost();fight.m_combatDepth=0;
        setup();removed();fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 presentation=0;fight.m_extActionMsg>>type>>source>>presentation;
        metrics["removed_burn_presentation"]=presentation;
        auto healSetup=[&](int strength=5000,bool dead=false,bool status=true) {
            fight.Clear();unit(1,10,0,10000);unit(2,23,0,1000);unit(enemy,23,0,dead?0:10000);affix(enemy,37,3);
            if(dead)fight.SetState(enemy,EFST_STATE_Die);
            fight.m_members[0].unitAttr.attack=1000;fight.m_members[0].unitAttr.baojiLv=0;
            if(status){std::vector<int> antiheal{strength,0};fight.AddBuff(2,enemy,ESBUFF_JinLiaoShu,3,&antiheal);}
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto heal=[&](){fight.CalculateSkill_AddHp(1,101,1);};
        auto slow=[&](int pos=2){return fight.GetStatePara1(pos,ESBUFF_SpeedDes);};
        healSetup();heal();metrics["antiheal_slow_native"]=slow();metrics["antiheal_slow_owner"]=slow(enemy);
        metrics["antiheal_slow_actions"]=fight.m_extActionMsg.GetType();
        for(const auto& buff:fight.m_members[1].buff_list)if(buff.id==ESBUFF_SpeedDes){metrics["antiheal_slow_duration"]=buff.leftTurn;metrics["antiheal_slow_source"]=buff.srcPos;}
        heal();metrics["antiheal_slow_repeat"]=slow();++fight.m_fightTurn;heal();metrics["antiheal_slow_next"]=slow();
        healSetup(10000);heal();metrics["antiheal_slow_blocked_heal"]=fight.GetHp(2)-1000;metrics["antiheal_slow_blocked"]=slow();
        healSetup(0);heal();metrics["antiheal_slow_zero_strength"]=slow();
        healSetup(5000,true);heal();metrics["antiheal_slow_dead_source"]=slow();
        healSetup(5000,false,false);heal();metrics["antiheal_slow_without_status"]=slow();
        healSetup();fight.m_combatDepth=1;heal();metrics["antiheal_slow_secondary"]=slow();fight.m_combatDepth=0;
        healSetup();fight.m_combatDepth=2;heal();metrics["antiheal_slow_depth_blocked"]=slow();fight.m_combatDepth=0;
        metrics["removed_antiheal_passed"]=metrics["removed_burn_first"]==1200 && metrics["removed_burn_repeat"]==2400 && metrics["removed_burn_expired"]==400
            && metrics["removed_burn_capped"]==8000 && metrics["removed_burn_max_turns"]==8000 && metrics["removed_other_buff"]==0
            && metrics["removed_zero_parameter"]==0 && metrics["removed_zero_actions"]==0 && metrics["removed_dead_source"]==1200
            && metrics["removed_dead_target_actions"]==0 && metrics["removed_dead_target_kills"]==0 && metrics["removed_dead_shield_left"]==800 && metrics["removed_dead_shield_actions"]==1
            && metrics["removed_shield_hp_loss"]==0 && metrics["removed_shield_left"]==800 && metrics["removed_burn_clear_native"]==1200 && metrics["removed_burn_expire_native"]==400
            && metrics["removed_burn_secondary"]==1200 && metrics["removed_burn_presentation"]==5034
            && metrics["antiheal_slow_native"]==1000 && metrics["antiheal_slow_owner"]==0 && metrics["antiheal_slow_actions"]==1 && metrics["antiheal_slow_duration"]==1 && metrics["antiheal_slow_source"]==enemy
            && metrics["antiheal_slow_repeat"]==1000 && metrics["antiheal_slow_next"]==2000 && metrics["antiheal_slow_blocked_heal"]==0 && metrics["antiheal_slow_blocked"]==1000
            && metrics["antiheal_slow_zero_strength"]==1000 && metrics["antiheal_slow_dead_source"]==1000 && metrics["antiheal_slow_without_status"]==0
            && metrics["antiheal_slow_secondary"]==1000 && metrics["antiheal_slow_depth_blocked"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:removedAntihealMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto summonAffixMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](bool equipped=true) {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(3,23,0,5000);unit(enemy,23,0,10000);unit(otherEnemy,23,0,5000);
            fight.m_members[2].unitAttr.attack=1000;fight.m_members[otherEnemy-1].unitAttr.attack=1000;
            if(equipped){affix(1,43,1);affix(2,43,3);affix(enemy,43,2);}
            std::srand(1729);
        };
        setup();const int expected=std::rand();std::srand(1729);fight.ApplyAffixSummonBonus(3);
        metrics["summon_affix_attack"]=fight.m_members[2].unitAttr.attack;metrics["summon_affix_max_hp"]=fight.GetMaxHp(3);metrics["summon_affix_hp"]=fight.GetHp(3);
        metrics["summon_affix_flag"]=fight.m_members[2].affixSummoned?1:0;metrics["summon_affix_rng"]=std::rand()==expected;
        fight.ApplyAffixSummonBonus(otherEnemy);metrics["summon_affix_enemy_attack"]=fight.m_members[otherEnemy-1].unitAttr.attack;
        metrics["summon_affix_enemy_max_hp"]=fight.GetMaxHp(otherEnemy);metrics["summon_affix_enemy_hp"]=fight.GetHp(otherEnemy);
        setup();fight.m_members[1].hp=0;fight.SetState(2,EFST_STATE_Die);fight.ApplyAffixSummonBonus(3);
        metrics["summon_affix_dead_attack"]=fight.m_members[2].unitAttr.attack;metrics["summon_affix_dead_hp"]=fight.GetMaxHp(3);
        setup(false);fight.ApplyAffixSummonBonus(3);metrics["summon_affix_absent_attack"]=fight.m_members[2].unitAttr.attack;
        metrics["summon_affix_absent_hp"]=fight.GetMaxHp(3);metrics["summon_affix_absent_flag"]=fight.m_members[2].affixSummoned?1:0;
        setup();fight.m_members[2].unitAttr.attack=1001;fight.m_members[2].unitAttr.maxHp=10001;fight.m_members[2].hp=5001;fight.ApplyAffixSummonBonus(3);
        metrics["summon_affix_round_attack"]=fight.m_members[2].unitAttr.attack;metrics["summon_affix_round_max_hp"]=fight.GetMaxHp(3);metrics["summon_affix_round_hp"]=fight.GetHp(3);
        setup();fight.m_members[2].unitAttr.attack=2000000;fight.ApplyAffixSummonBonus(3);metrics["summon_affix_large_attack"]=fight.m_members[2].unitAttr.attack;
        setup();fight.m_members[2].unitAttr.attack=std::numeric_limits<int>::max();fight.ApplyAffixSummonBonus(3);metrics["summon_affix_attack_ceiling"]=fight.m_members[2].unitAttr.attack;
        setup();affix(1,42,3);fight.ApplyAffixSummonBonus(3);fight.m_members[2].hp=0;fight.SetState(3,EFST_STATE_Die);fight.OnAffixUnitDied(3);
        metrics["summon_affix_death_not_counted"]=fight.m_combatState.counts[{1,40420,0}].inBattle;
        metrics["summon_affix_passed"]=metrics["summon_affix_attack"]==1240 && metrics["summon_affix_max_hp"]==11600 && metrics["summon_affix_hp"]==6600
            && metrics["summon_affix_flag"]==1 && metrics["summon_affix_rng"]==1 && metrics["summon_affix_enemy_attack"]==1180 && metrics["summon_affix_enemy_max_hp"]==11200 && metrics["summon_affix_enemy_hp"]==6200
            && metrics["summon_affix_dead_attack"]==1240 && metrics["summon_affix_dead_hp"]==11600
            && metrics["summon_affix_absent_attack"]==1000 && metrics["summon_affix_absent_hp"]==10000 && metrics["summon_affix_absent_flag"]==1
            && metrics["summon_affix_round_attack"]==1241 && metrics["summon_affix_round_max_hp"]==11601 && metrics["summon_affix_round_hp"]==6601
            && metrics["summon_affix_large_attack"]==2480000 && metrics["summon_affix_attack_ceiling"]==std::numeric_limits<int>::max() && metrics["summon_affix_death_not_counted"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:summonAffixMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto durationChanceMetrics=[&]() {
        CombatData::Values metrics;
        int successSeed=0,failureSeed=0;
        for(int seed=1;!successSeed || !failureSeed;++seed){std::srand(seed);const int value=Random(1,10000);if(value<=1000 && !successSeed)successSeed=seed;if(value>9000 && !failureSeed)failureSeed=seed;}
        auto setup=[&](int id) {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(enemy,23,0,100000);unit(otherEnemy,23,0,100000);
            fight.m_members[enemy-1].unitAttr.maxHp=100000;fight.m_members[otherEnemy-1].unitAttr.maxHp=100000;
            if(id)affix(1,id,3);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto duration=[&](int pos,int buff)->int{int result=-1;for(const auto& b:fight.m_members[pos-1].buff_list)if(b.id==buff)result=b.leftTurn;return result;};
        auto control=[&](int turns=3,int buff=ESBUFF_ChaoFeng){std::vector<int> p{1000};fight.AddBuff(enemy,1,buff,turns,&p);};
        setup(0);std::srand(successSeed);control();Random(1,10000);const int expectedAfterControl=std::rand();
        setup(30);std::srand(successSeed);control();metrics["duration_control_first"]=duration(enemy,ESBUFF_ChaoFeng);
        metrics["duration_control_rng"]=std::rand()==expectedAfterControl;
        std::srand(successSeed);control(4);metrics["duration_control_second"]=duration(enemy,ESBUFF_ChaoFeng);
        std::srand(successSeed);const int noDraw=std::rand();std::srand(successSeed);control();metrics["duration_control_rejected_rng"]=std::rand()==noDraw;
        setup(30);std::srand(failureSeed);control();metrics["duration_control_failed"]=duration(enemy,ESBUFF_ChaoFeng);
        std::srand(successSeed);control(4);metrics["duration_control_after_failure"]=duration(enemy,ESBUFF_ChaoFeng);
        setup(30);std::srand(successSeed);control(255);metrics["duration_control_wrap"]=duration(enemy,ESBUFF_ChaoFeng);
        setup(30);std::srand(successSeed);control(0);metrics["duration_control_zero_rejected"]=duration(enemy,ESBUFF_ChaoFeng);metrics["duration_control_zero_rng"]=std::rand()==noDraw;
        setup(30);std::srand(successSeed);control(3,ESBUFF_SpeedDes);metrics["duration_control_nonhard"]=duration(enemy,ESBUFF_SpeedDes);metrics["duration_control_nonhard_rng"]=std::rand()==noDraw;
        setup(30);fight.m_members[enemy-1].isWorldBoss=true;std::srand(successSeed);control();
        metrics["duration_control_boss"]=duration(enemy,ESBUFF_SpeedDes);metrics["duration_control_boss_rng"]=std::rand()==noDraw;
        setup(30);fight.m_members[0].hp=0;fight.SetState(1,EFST_STATE_Die);std::srand(successSeed);control();metrics["duration_control_dead_source"]=duration(enemy,ESBUFF_ChaoFeng);
        setup(30);fight.m_combatDepth=2;std::srand(successSeed);control();metrics["duration_control_secondary"]=duration(enemy,ESBUFF_ChaoFeng);fight.m_combatDepth=0;
        setup(30);fight.m_combatDepth=3;std::srand(successSeed);control();metrics["duration_control_depth_blocked"]=duration(enemy,ESBUFF_ChaoFeng);fight.m_combatDepth=0;
        auto setupForbid=[&]() {
            setup(44);std::vector<int> p{0};fight.AddBuff(enemy,2,ESBUFF_ForbidFuHuo,3,&p);fight.AddBuff(enemy,1,ESBUFF_ForbidFuHuo,5,&p);
            fight.AddBuff(otherEnemy,2,ESBUFF_ForbidFuHuo,2,&p);
        };
        auto extend=[&](int target=0){fight.CombatEvent("before_hp_change",1,target?target:enemy,0,0,1,{});};
        auto count=[&](int target=0){return fight.m_combatState.counts[{1,40440,target?target:enemy}].inBattle;};
        setupForbid();std::srand(successSeed);Random(1,10000);const int expectedAfterExtend=std::rand();std::srand(successSeed);extend();
        metrics["duration_forbid_first"]=duration(enemy,ESBUFF_ForbidFuHuo);metrics["duration_forbid_count"]=count();metrics["duration_forbid_rng"]=std::rand()==expectedAfterExtend;
        metrics["duration_forbid_first_instance"]=-1;int instances=0;for(const auto& b:fight.m_members[enemy-1].buff_list)if(b.id==ESBUFF_ForbidFuHuo){if(!instances)metrics["duration_forbid_first_instance"]=b.leftTurn;++instances;}
        metrics["duration_forbid_instances"]=instances;metrics["duration_forbid_actions"]=fight.m_extActionMsg.GetType();
        std::srand(successSeed);extend();metrics["duration_forbid_repeat"]=duration(enemy,ESBUFF_ForbidFuHuo);metrics["duration_forbid_exhausted_rng"]=std::rand()==noDraw;
        ++fight.m_fightTurn;extend();metrics["duration_forbid_next_turn"]=duration(enemy,ESBUFF_ForbidFuHuo);
        std::srand(successSeed);extend(otherEnemy);metrics["duration_forbid_other_target"]=duration(otherEnemy,ESBUFF_ForbidFuHuo);metrics["duration_forbid_other_count"]=count(otherEnemy);
        setupForbid();std::srand(failureSeed);extend();metrics["duration_forbid_failed"]=duration(enemy,ESBUFF_ForbidFuHuo);metrics["duration_forbid_failed_count"]=count();
        std::srand(successSeed);extend();metrics["duration_forbid_retry"]=duration(enemy,ESBUFF_ForbidFuHuo);
        setupForbid();fight.m_members[0].hp=0;fight.SetState(1,EFST_STATE_Die);std::srand(successSeed);extend();metrics["duration_forbid_dead_source"]=duration(enemy,ESBUFF_ForbidFuHuo);
        setupForbid();fight.m_members[enemy-1].hp=0;fight.SetState(enemy,EFST_STATE_Die);std::srand(successSeed);extend();metrics["duration_forbid_dead_target"]=duration(enemy,ESBUFF_ForbidFuHuo);
        setupForbid();fight.ClearBuff(enemy,ESBUFF_ForbidFuHuo);std::srand(successSeed);extend();metrics["duration_forbid_absent_rng"]=std::rand()==noDraw;metrics["duration_forbid_absent_count"]=count();
        setupForbid();for(auto& b:fight.m_members[enemy-1].buff_list)if(b.id==ESBUFF_ForbidFuHuo)b.leftTurn=255;
        std::srand(successSeed);extend();metrics["duration_forbid_wrap"]=duration(enemy,ESBUFF_ForbidFuHuo);
        setupForbid();fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_ForbidFuHuo);std::srand(successSeed);extend();metrics["duration_forbid_immunity"]=duration(enemy,ESBUFF_ForbidFuHuo);
        setupForbid();fight.m_combatDepth=1;std::srand(successSeed);extend();metrics["duration_forbid_secondary"]=duration(enemy,ESBUFF_ForbidFuHuo);fight.m_combatDepth=0;
        setupForbid();fight.m_combatDepth=2;std::srand(successSeed);extend();metrics["duration_forbid_depth_blocked"]=duration(enemy,ESBUFF_ForbidFuHuo);fight.m_combatDepth=0;
        setupForbid();fight.m_members[0].unitAttr.attack=1000;fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;
        std::srand(1729);std::vector<SAttrData> own,other;int self=0;fight.BasicFightAction(1,enemy,0,1,self,own,other,false,true);
        metrics["duration_forbid_native"]=duration(enemy,ESBUFF_ForbidFuHuo);metrics["duration_forbid_native_count"]=count();metrics["duration_forbid_native_damage"]=100000-fight.GetHp(enemy);
        metrics["duration_chance_passed"]=metrics["duration_control_first"]==4 && metrics["duration_control_rng"]==1 && metrics["duration_control_second"]==3 && metrics["duration_control_rejected_rng"]==1
            && metrics["duration_control_failed"]==3 && metrics["duration_control_after_failure"]==3 && metrics["duration_control_wrap"]==0 && metrics["duration_control_zero_rejected"]==-1 && metrics["duration_control_zero_rng"]==1
            && metrics["duration_control_nonhard"]==3 && metrics["duration_control_nonhard_rng"]==1 && metrics["duration_control_boss"]==1 && metrics["duration_control_boss_rng"]==1
            && metrics["duration_control_dead_source"]==4 && metrics["duration_control_secondary"]==4 && metrics["duration_control_depth_blocked"]==3
            && metrics["duration_forbid_first"]==6 && metrics["duration_forbid_first_instance"]==4 && metrics["duration_forbid_instances"]==2 && metrics["duration_forbid_count"]==1
            && metrics["duration_forbid_rng"]==1 && metrics["duration_forbid_actions"]==0 && metrics["duration_forbid_repeat"]==6 && metrics["duration_forbid_exhausted_rng"]==1 && metrics["duration_forbid_next_turn"]==6
            && metrics["duration_forbid_other_target"]==3 && metrics["duration_forbid_other_count"]==1 && metrics["duration_forbid_failed"]==5 && metrics["duration_forbid_failed_count"]==0 && metrics["duration_forbid_retry"]==6
            && metrics["duration_forbid_dead_source"]==6 && metrics["duration_forbid_dead_target"]==6 && metrics["duration_forbid_absent_rng"]==1 && metrics["duration_forbid_absent_count"]==0
            && metrics["duration_forbid_wrap"]==256 && metrics["duration_forbid_immunity"]==6 && metrics["duration_forbid_secondary"]==6 && metrics["duration_forbid_depth_blocked"]==5
            && metrics["duration_forbid_native_damage"]>0 && metrics["duration_forbid_native_count"]<=1 && metrics["duration_forbid_native"]==5+metrics["duration_forbid_native_count"]?1:0;
        return metrics;
    }();
    for(const auto& metric:durationChanceMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto buffPayloadMetrics=[&]() {
        CombatData::Values metrics;
        auto braveSetup=[&](int attack=2001,bool equipped=true) {
            fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,100000);fight.m_members[enemy-1].unitAttr.maxHp=100000;if(equipped)affix(1,16,3);
            fight.m_members[0].unitAttr.fanzhenLv=10000;fight.m_members[0].unitAttr.baojikangLv=10000;
            fight.m_members[enemy-1].unitAttr.attack=attack;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);fight.m_actionMsg.ReWrite();fight.m_actionMsg.SetType(0);std::srand(1729);
        };
        auto hit=[&](bool counter=false) {std::vector<SAttrData> own,other;int self=0;fight.BasicFightAction(enemy,1,0,7,self,own,other,counter,true);};
        auto first=[&](){return fight.GetStatePara1(1,ESBUFF_FanZhengAllAdd);};
        braveSetup(2001,false);hit();const int baseActions=fight.m_extActionMsg.GetType();metrics["payload_brave_baseline_actions"]=baseActions;
        braveSetup();hit();metrics["payload_brave_first"]=first();metrics["payload_brave_second"]=fight.GetStatePara2(1,ESBUFF_FanZhengAllAdd);
        metrics["payload_brave_immediate_thorns"]=100000-fight.GetHp(enemy);
        metrics["payload_brave_total_actions"]=fight.m_extActionMsg.GetType();metrics["payload_brave_actions"]=fight.m_extActionMsg.GetType()-baseActions;
        for(const auto& b:fight.m_members[0].buff_list)if(b.id==ESBUFF_FanZhengAllAdd){metrics["payload_brave_count"]=b.paraList.size();metrics["payload_brave_duration"]=b.leftTurn;metrics["payload_brave_level"]=b.originLevel;}
        hit();metrics["payload_brave_repeat"]=first();
        braveSetup(2000);hit();metrics["payload_brave_below_threshold"]=first();
        braveSetup(100001);hit();metrics["payload_brave_lethal"]=first();
        braveSetup();std::vector<int> shield{3000,3000};fight.AddBuff(1,1,ESBUFF_Shield,2,&shield);hit();metrics["payload_brave_absorbed"]=first();
        braveSetup();fight.m_combatDepth=1;fight.m_members[enemy-1].unitAttr.fanjiAdd=10000;hit(true);metrics["payload_brave_counter"]=first();fight.m_combatDepth=0;
        fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,10000);affix(1,38,3);fight.m_members[0].attackType=1;
        std::vector<int> vulnerable{1000};fight.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&vulnerable,0,9);
        for(const auto& b:fight.m_members[enemy-1].buff_list)if(b.id==ESBUFF_WuFangDes)metrics["payload_raw_origin_level"]=b.originLevel;
        int successSeed=0,failureSeed=0;
        for(int seed=1;!successSeed || !failureSeed;++seed){std::srand(seed);const int value=Random(1,10000);if(value<=1000 && !successSeed)successSeed=seed;if(value>9000 && !failureSeed)failureSeed=seed;}
        const uint8 thirdEnemy=otherEnemy+1;const std::vector<int> payload{101,202,-303,404,505};
        auto spreadSetup=[&](bool equipped=true,bool enough=true,bool burning=false) {
            fight.Clear();unit(1,23,0,10000);unit(2,23,0,10000);unit(enemy,23,0,100000);unit(otherEnemy,23,0,100000);unit(thirdEnemy,23,0,100000);
            for(uint8 pos:{enemy,otherEnemy,thirdEnemy})fight.m_members[pos-1].unitAttr.maxHp=100000;
            std::vector<int> p{50,60};fight.AddBuff(enemy,2,burning?ESBUFF_ZhuoShao:ESBUFF_ShiXinDu,3,&p);
            if(enough)fight.AddBuff(enemy,2,burning?ESBUFF_ZhuoShao:ESBUFF_FuDu,3,&p);
            if(equipped)affix(1,33,3);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);
        };
        auto apply=[&](bool burning=false) {auto p=payload;fight.AddBuff(enemy,1,burning?ESBUFF_ZhuoShao:ESBUFF_ShiDu,6,&p,11,7);};
        auto instances=[&](int pos,int buff=ESBUFF_ShiDu)->int{int count=0;for(const auto& b:fight.m_members[pos-1].buff_list)if(b.id==buff)++count;return count;};
        auto attempts=[&](){return fight.m_combatState.counts[{1,40330,0}].inBattle;};
        spreadSetup(false);std::srand(successSeed);apply();Random(1,10000);const int expectedRandom=std::rand();
        spreadSetup();std::srand(successSeed);apply();metrics["payload_spread_copy"]=instances(otherEnemy);metrics["payload_spread_rng"]=std::rand()==expectedRandom;
        metrics["payload_spread_attempts"]=attempts();metrics["payload_spread_actions"]=fight.m_extActionMsg.GetType();
        for(const auto& b:fight.m_members[otherEnemy-1].buff_list)if(b.id==ESBUFF_ShiDu) {
            metrics["payload_spread_equal"]=b.paraList==payload;metrics["payload_spread_count"]=b.paraList.size();metrics["payload_spread_duration"]=b.leftTurn;
            metrics["payload_spread_origin_skill"]=b.originSkill;metrics["payload_spread_origin_level"]=b.originLevel;metrics["payload_spread_source"]=b.srcPos;
        }
        std::srand(successSeed);apply();metrics["payload_spread_repeat_third"]=instances(thirdEnemy);
        ++fight.m_fightTurn;std::srand(successSeed);apply();metrics["payload_spread_next_third"]=instances(thirdEnemy);
        spreadSetup();std::srand(failureSeed);apply();metrics["payload_spread_failed"]=instances(otherEnemy);metrics["payload_spread_failed_attempts"]=attempts();
        std::srand(successSeed);apply();metrics["payload_spread_failed_retry"]=instances(otherEnemy);
        spreadSetup(true,false);std::srand(successSeed);const int noDraw=std::rand();std::srand(successSeed);apply();
        metrics["payload_spread_below_threshold"]=instances(otherEnemy);metrics["payload_spread_below_rng"]=std::rand()==noDraw;metrics["payload_spread_below_attempts"]=attempts();
        spreadSetup(true,true,true);std::srand(successSeed);apply(true);metrics["payload_spread_wrong_family"]=instances(otherEnemy,ESBUFF_ZhuoShao);metrics["payload_spread_wrong_family_attempts"]=attempts();
        spreadSetup();fight.m_members[otherEnemy-1].hp=0;fight.SetState(otherEnemy,EFST_STATE_Die);std::srand(successSeed);apply();
        metrics["payload_spread_dead_candidate"]=instances(otherEnemy);metrics["payload_spread_skip_to_third"]=instances(thirdEnemy);
        spreadSetup();fight.m_members[0].hp=0;fight.SetState(1,EFST_STATE_Die);std::srand(successSeed);apply();metrics["payload_spread_dead_source"]=instances(otherEnemy);
        spreadSetup();fight.m_members[otherEnemy-1].notEffectBuff.push_back(ESBUFF_ShiDu);std::srand(successSeed);apply();metrics["payload_spread_immunity"]=instances(otherEnemy);
        spreadSetup();std::vector<int> p{50,60};fight.AddBuff(otherEnemy,2,ESBUFF_ShiXinDu,3,&p);fight.AddBuff(thirdEnemy,2,ESBUFF_FuDu,3,&p);
        std::srand(successSeed);apply();metrics["payload_spread_no_candidate_attempts"]=attempts();metrics["payload_spread_no_candidate_rng"]=std::rand()==expectedRandom;
        fight.ClearBuff(otherEnemy,ESBUFF_ShiXinDu);std::srand(successSeed);apply();metrics["payload_spread_after_empty"]=instances(otherEnemy);
        metrics["buff_payload_passed"]=metrics["payload_brave_first"]==1600 && metrics["payload_brave_second"]==1600 && metrics["payload_brave_count"]==2 && metrics["payload_brave_duration"]==2 && metrics["payload_brave_level"]==1
            && metrics["payload_brave_immediate_thorns"]==320 && metrics["payload_brave_actions"]==0 && metrics["payload_brave_repeat"]==3200 && metrics["payload_brave_below_threshold"]==0 && metrics["payload_brave_lethal"]==0 && metrics["payload_brave_absorbed"]==0
            && metrics["payload_brave_counter"]==1600 && metrics["payload_raw_origin_level"]==1
            && metrics["payload_spread_copy"]==1 && metrics["payload_spread_rng"]==1 && metrics["payload_spread_attempts"]==1 && metrics["payload_spread_actions"]==0
            && metrics["payload_spread_equal"]==1 && metrics["payload_spread_count"]==5 && metrics["payload_spread_duration"]==5 && metrics["payload_spread_origin_skill"]==0 && metrics["payload_spread_origin_level"]==1 && metrics["payload_spread_source"]==1
            && metrics["payload_spread_repeat_third"]==0 && metrics["payload_spread_next_third"]==1 && metrics["payload_spread_failed"]==0 && metrics["payload_spread_failed_attempts"]==1 && metrics["payload_spread_failed_retry"]==0
            && metrics["payload_spread_below_threshold"]==0 && metrics["payload_spread_below_rng"]==1 && metrics["payload_spread_below_attempts"]==0
            && metrics["payload_spread_wrong_family"]==0 && metrics["payload_spread_wrong_family_attempts"]==0 && metrics["payload_spread_dead_candidate"]==0 && metrics["payload_spread_skip_to_third"]==1
            && metrics["payload_spread_dead_source"]==1 && metrics["payload_spread_immunity"]==1 && metrics["payload_spread_no_candidate_attempts"]==1 && metrics["payload_spread_no_candidate_rng"]==1 && metrics["payload_spread_after_empty"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:buffPayloadMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto nuwaOriginMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int hp=1000) {
            fight.Clear();unit(1,10,1,10000);unit(2,23,0,hp);unit(enemy,23,0,10000);fight.m_members[0].unitAttr.attack=1000;
            fight.m_actionMsg.ReWrite();fight.m_actionMsg.SetType(0);fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto inspect=[&](uint8 pos,int id,const std::string& key) {
            metrics[key+"_skill"]=0;metrics[key+"_level"]=0;metrics[key+"_amount"]=0;
            for(const auto& b:fight.m_members[pos-1].buff_list)if(b.id==id){metrics[key+"_skill"]=b.originSkill;metrics[key+"_level"]=b.originLevel;metrics[key+"_amount"]=b.paraList.front();}
        };
        setup(0);fight.SetState(2,EFST_STATE_Die);fight.m_members[1].notEffectBuff.push_back(ESBUFF_MianShangTemp);
        fight.CalculateSkill_AddHp(1,102,7);inspect(2,ESBUFF_MianShangTemp,"nuwa_origin_revive_guard");
        metrics["nuwa_origin_revive_actions"]=fight.m_extActionMsg.GetType();metrics["nuwa_origin_revive_hp"]=fight.GetHp(2);
        setup();fight.m_members[1].notEffectBuff.push_back(ESBUFF_MianShangTemp);fight.CalculateSkill_AddHp(1,101,7);
        inspect(2,ESBUFF_MianShangTemp,"nuwa_origin_heal_guard");
        setup();unit(3,23,0,11000);fight.m_members[2].unitAttr.maxHp=100000;
        metrics["nuwa_origin_lowest_before"]=fight.GetHp(2)*fight.GetMaxHp(3)<fight.GetHp(3)*fight.GetMaxHp(2)?2:3;
        fight.CalculateSkill_AddHp(1,101,1);
        metrics["nuwa_origin_lowest_after"]=fight.GetHp(2)*fight.GetMaxHp(3)<fight.GetHp(3)*fight.GetMaxHp(2)?2:3;
        metrics["nuwa_origin_reselect_old_guard"]=fight.GetStatePara1(2,ESBUFF_MianShangTemp);
        metrics["nuwa_origin_reselect_new_guard"]=fight.GetStatePara1(3,ESBUFF_MianShangTemp);
        setup(9903);fight.m_members[0].hp=9000;affix(1,5,3);fight.CalculateSkill_AddHp(1,101,7);inspect(2,ESBUFF_Shield,"nuwa_origin_merged_shield");
        fight.m_extActionMsg.ReRead();uint8 type=0,source=0;uint16 displayed=65535;fight.m_extActionMsg>>type>>source>>displayed;
        metrics["nuwa_origin_shield_display"]=displayed;
        metrics["nuwa_origin_merged_extra_actions"]=fight.m_extActionMsg.GetType();
        metrics["nuwa_origin_passed"]=metrics["nuwa_origin_revive_guard_skill"]==0 && metrics["nuwa_origin_revive_guard_level"]==1 && metrics["nuwa_origin_revive_guard_amount"]==2000
            && metrics["nuwa_origin_revive_actions"]==0 && metrics["nuwa_origin_revive_hp"]==2500
            && metrics["nuwa_origin_heal_guard_skill"]==0 && metrics["nuwa_origin_heal_guard_level"]==1 && metrics["nuwa_origin_heal_guard_amount"]==800
            && metrics["nuwa_origin_lowest_before"]==2 && metrics["nuwa_origin_lowest_after"]==3 && metrics["nuwa_origin_reselect_old_guard"]==0 && metrics["nuwa_origin_reselect_new_guard"]==800
            && metrics["nuwa_origin_merged_shield_skill"]==0 && metrics["nuwa_origin_merged_shield_level"]==1 && metrics["nuwa_origin_shield_display"]==101 && metrics["nuwa_origin_merged_extra_actions"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:nuwaOriginMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto reviveRecordMetrics=[&]() {
        CombatData::Values metrics;
        for(int branch:{1,2}) {
            fight.Clear();unit(1,10,branch,10000);unit(2,23,0,0);unit(3,10,branch,10000);unit(enemy,23,0,10000);
            fight.SetState(2,EFST_STATE_Die);fight.m_members[0].unitAttr.attack=1000;std::srand(1729);
            const auto* healRole=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(10);
            fight.m_members[0].skill_list.push_back(SSkillData(101,1));fight.m_members[0].skill_list.push_back(SSkillData(102,1));
            fight.m_members[0].combatStrategy=1;fight.m_teamRage[0]=fight.GetTacticCost(1,*healRole)+20;
            const std::string key=branch==1?"revive_record_a_":"revive_record_b_";
            auto count=[&](int target){return fight.m_combatState.counts[{1,1017,target}].inBattle;};
            auto query=[&](uint16 skill=102) {CombatData::Modifiers m;m.parameters.push_back(1);fight.CombatEvent("before_revive_eligibility",1,2,skill,0,1,{},&m);return m.parameters[0];};
            metrics[key+"first_eligible"]=fight.CombatCanRevive(2,1,102);metrics[key+"first_ai_skill"]=fight.GetUnitAISkillId(1);fight.CalculateSkill_AddHp(1,102,1);
            metrics[key+"first_hp"]=fight.GetHp(2);metrics[key+"first_count"]=count(2);
            int damage=100000,absorbed=0;fight.DecreaseHp(2,enemy,damage,absorbed,true);
            metrics[key+"public_eligible"]=fight.CombatCanRevive(2,1);metrics[key+"skill_eligible"]=fight.CombatCanRevive(2,1,102);
            metrics[key+"query"]=query();metrics[key+"other_skill_query"]=query(104);metrics[key+"other_source_eligible"]=fight.CombatCanRevive(2,3,102);
            uint8 targets[GROUP_MEMBER],countTargets=0;fight.GetSkillTargetRange(1,102,1,targets,countTargets);
            metrics[key+"targets"]=countTargets;metrics[key+"useful"]=fight.IsRoleSkillUseful(1,102);
            metrics[key+"repeat_ai_skill"]=fight.GetUnitAISkillId(1);
            fight.CalculateSkill_AddHp(1,102,1);metrics[key+"repeat_hp"]=fight.GetHp(2);metrics[key+"repeat_count"]=count(2);
            ++fight.m_fightTurn;metrics[key+"next_turn_query"]=query();
            unit(4,23,0,0);fight.SetState(4,EFST_STATE_Die);metrics[key+"new_target_eligible"]=fight.CombatCanRevive(4,1,102);
            fight.CalculateSkill_AddHp(1,102,1);metrics[key+"new_target_hp"]=fight.GetHp(4);metrics[key+"new_target_count"]=count(4);
            std::srand(1729);const int expectedRandom=std::rand();std::srand(1729);query();fight.CombatCanRevive(4,1,102);
            metrics[key+"query_rng"]=std::rand()==expectedRandom;
        }
        metrics["revive_record_passed"]=1;
        for(const std::string key:{"revive_record_a_","revive_record_b_"}) {
            const int hp=key=="revive_record_a_"?2500:4000;
            if(metrics[key+"first_eligible"]!=1 || metrics[key+"first_ai_skill"]!=102 || metrics[key+"first_hp"]!=hp || metrics[key+"first_count"]!=1
                || metrics[key+"skill_eligible"]!=0 || metrics[key+"query"]!=0 || metrics[key+"other_skill_query"]!=1 || metrics[key+"other_source_eligible"]!=1
                || metrics[key+"targets"]!=0 || metrics[key+"useful"]!=0 || metrics[key+"repeat_ai_skill"]!=0 || metrics[key+"repeat_hp"]!=0 || metrics[key+"repeat_count"]!=1 || metrics[key+"next_turn_query"]!=0
                || metrics[key+"new_target_eligible"]!=1 || metrics[key+"new_target_hp"]!=hp || metrics[key+"new_target_count"]!=1 || metrics[key+"query_rng"]!=1)metrics["revive_record_passed"]=0;
        }
        return metrics;
    }();
    for(const auto& metric:reviveRecordMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto targetPolicyMetrics=[&]() {
        CombatData::Values metrics;
        fight.Clear();unit(1,10,0,9000);unit(2,23,0,3000);unit(3,23,0,4000);unit(enemy,23,0,10000);
        fight.m_members[0].unitAttr.attack=1000;fight.m_members[1].unitAttr.attack=1000;fight.m_members[2].unitAttr.attack=9000;
        uint8 base[GROUP_MEMBER],count=0;std::srand(1729);fight.GetSkillTargetRange(1,101,1,base,count);const int expectedRandom=std::rand();
        auto order=[&](const uint8* p){return p[0]*100+p[1]*10+p[2];};metrics["target_policy_base_order"]=order(base);
        fight.m_members[0].combatStrategy=1;std::srand(1729);fight.GetSkillTargetRange(1,101,1,base,count);
        metrics["target_policy_heal_order"]=order(base);metrics["target_policy_heal_first"]=base[0];metrics["target_policy_heal_rng"]=std::rand()==expectedRandom;
        std::vector<int> shield{500,500};fight.AddBuff(2,1,ESBUFF_Shield,2,&shield);fight.m_members[0].combatStrategy=2;
        fight.GetSkillTargetRange(1,101,1,base,count);metrics["target_policy_guard_order"]=order(base);
        unit(4,23,0,1000);unit(5,23,0,2000);unit(6,23,0,9500);fight.m_members[0].combatStrategy=1;
        fight.GetSkillTargetRange(1,101,1,base,count);metrics["target_policy_trim_count"]=count;
        metrics["target_policy_trim_first"]=base[0];metrics["target_policy_trim_excluded"]=std::find(base,base+count,6)==base+count?1:0;
        const uint8 third=otherEnemy+1;unit(otherEnemy,23,0,1000);unit(third,23,0,1000);
        fight.m_members[enemy-1].unitAttr.maxHp=100000;fight.m_members[enemy-1].hp=20000;fight.m_members[enemy-1].unitAttr.attack=2000;
        fight.m_members[otherEnemy-1].unitAttr.attack=4000;fight.m_members[third-1].unitAttr.attack=4000;
        auto sorted=[&](int strategy,uint16 skill){uint8 p[]{enemy,otherEnemy,third};fight.m_members[0].combatStrategy=strategy;fight.CombatSortTargets(1,skill,p,3,false);return p[0];};
        metrics["target_policy_attack_first"]=sorted(3,101);metrics["target_policy_burst_first"]=sorted(4,101);metrics["target_policy_wrong_side"]=sorted(1,101);
        SharePetPtr actor(new SPet);actor->id=15;fight.m_members[0].memPtr=actor;
        std::vector<int> p{10,10};fight.AddBuff(enemy,1,ESBUFF_ShiXinDu,2,&p);fight.AddBuff(enemy,1,ESBUFF_ShiDu,2,&p);
        fight.AddBuff(otherEnemy,1,ESBUFF_ShiXinDu,2,&p);fight.AddBuff(third,2,ESBUFF_ShiXinDu,2,&p);fight.AddBuff(third,1,27,2,&p);
        const auto* dotRole=SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(15);
        metrics["target_policy_regular_skill"]=dotRole->regularSkillId;metrics["target_policy_tactic_skill"]=dotRole->tacticSkillId;
        metrics["target_policy_dot_regular"]=sorted(5,dotRole->regularSkillId);metrics["target_policy_dot_tactic"]=sorted(5,dotRole->tacticSkillId);
        metrics["target_policy_dot_other"]=sorted(5,612);
        std::srand(1729);const int noDraw=std::rand();std::srand(1729);sorted(5,dotRole->regularSkillId);sorted(3,dotRole->regularSkillId);metrics["target_policy_sort_rng"]=std::rand()==noDraw;
        fight.Clear();unit(enemy,10,0,9000);unit(otherEnemy,23,0,3000);unit(third,23,0,4000);unit(1,23,0,10000);
        fight.m_members[enemy-1].combatStrategy=1;std::srand(1729);fight.GetSkillTargetRange(enemy,101,1,base,count);
        metrics["target_policy_reverse_first"]=base[0];metrics["target_policy_reverse_rng"]=std::rand()==expectedRandom;
        metrics["target_policy_passed"]=metrics["target_policy_heal_order"]==231 && metrics["target_policy_heal_rng"]==1 && metrics["target_policy_guard_order"]==312
            && metrics["target_policy_attack_first"]==otherEnemy && metrics["target_policy_burst_first"]==otherEnemy && metrics["target_policy_wrong_side"]==enemy
            && metrics["target_policy_dot_regular"]==third && metrics["target_policy_dot_tactic"]==enemy && metrics["target_policy_dot_other"]==third && metrics["target_policy_sort_rng"]==1
            && metrics["target_policy_trim_count"]==5 && metrics["target_policy_trim_first"]==4 && metrics["target_policy_trim_excluded"]==1
            && metrics["target_policy_reverse_first"]==otherEnemy && metrics["target_policy_reverse_rng"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:targetPolicyMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto shieldCoreMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int hero=23,int branch=0) {
            fight.Clear();unit(1,hero,branch,10000);unit(2,12,0,10000);unit(enemy,23,0,100000);fight.m_members[enemy-1].unitAttr.maxHp=100000;
            fight.m_members[1].passive_skill.push_back(SSkillData(123,1));fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto duration=[&](int pos){int value=0;for(const auto& b:fight.m_members[pos-1].buff_list)if(b.id==ESBUFF_FanZhengAllAdd)value=b.leftTurn;return value;};
        std::vector<int> p{1000,1000};setup();fight.m_curActionPos=1;fight.AddBuff(1,1,ESBUFF_FanZhengAllAdd,2,&p);fight.DecAllStateEffectTurn(1);
        metrics["shield_core_tick_self"]=duration(1);++fight.m_fightTurn;fight.DecAllStateEffectTurn(1);metrics["shield_core_tick_next"]=duration(1);
        setup();fight.m_curActionPos=1;fight.AddBuff(2,1,ESBUFF_FanZhengAllAdd,2,&p);fight.DecAllStateEffectTurn(2);metrics["shield_core_tick_other"]=duration(2);
        auto install=[&](int remaining,int turns,uint16 origin) {SFightBuffData shield;shield.srcPos=1;shield.id=ESBUFF_Shield;shield.leftTurn=turns;shield.originSkill=origin;shield.paraList={remaining,1000};
            fight.m_members[1].buff_list.push_back(shield);fight.SpecialBuffPassAttr(2,shield.id,true);return shield;};
        setup();auto ordinary=install(0,2,0);metrics["shield_core_ordinary_legacy"]=fight.CombatShieldAllowsLegacy(2,ordinary,false);
        fight.ShieldBrokenCheck(2,enemy);metrics["shield_core_broken_legacy_damage"]=100000-fight.GetHp(enemy);
        setup();install(400,1,0);fight.DecAllStateEffectTurn(2);metrics["shield_core_expired_legacy_damage"]=100000-fight.GetHp(enemy);
        for(int branch:{1,2}) {
            const std::string key=branch==1?"shield_core_a_":"shield_core_b_";
            setup(12,branch);auto shield=install(0,2,124);metrics[key+"legacy_allowed"]=fight.CombatShieldAllowsLegacy(2,shield,false);
            fight.ShieldBrokenCheck(2,enemy);metrics[key+"conversion_damage"]=100000-fight.GetHp(enemy);metrics[key+"conversion_actions"]=fight.m_extActionMsg.GetType();
            setup(12,branch);fight.m_members[0].hp=0;fight.SetState(1,EFST_STATE_Die);install(0,2,124);fight.ShieldBrokenCheck(2,enemy);metrics[key+"dead_actions"]=fight.m_extActionMsg.GetType();
            setup(12,branch);install(0,2,0);fight.m_combatDepth=1;fight.ShieldBrokenCheck(2,enemy);metrics[key+"secondary_actions"]=fight.m_extActionMsg.GetType();fight.m_combatDepth=0;
        }
        metrics["shield_core_passed"]=metrics["shield_core_tick_self"]==2 && metrics["shield_core_tick_next"]==1 && metrics["shield_core_tick_other"]==1
            && metrics["shield_core_ordinary_legacy"]==1 && metrics["shield_core_broken_legacy_damage"]>0 && metrics["shield_core_expired_legacy_damage"]>0 && metrics["shield_core_expired_legacy_damage"]<metrics["shield_core_broken_legacy_damage"]
            && metrics["shield_core_a_legacy_allowed"]==0 && metrics["shield_core_b_legacy_allowed"]==0
            && metrics["shield_core_a_conversion_damage"]==0 && metrics["shield_core_b_conversion_damage"]==0 && metrics["shield_core_a_conversion_actions"]==0 && metrics["shield_core_b_conversion_actions"]==0
            && metrics["shield_core_a_dead_actions"]==0 && metrics["shield_core_b_dead_actions"]==0 && metrics["shield_core_a_secondary_actions"]==0 && metrics["shield_core_b_secondary_actions"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:shieldCoreMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto shieldFullMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=2) {
            fight.Clear();unit(1,12,branch,10000);unit(2,23,0,4000);unit(enemy,23,0,10000);unit(otherEnemy,23,0,10000);
            fight.m_extActionMsg.ReWrite();fight.m_extActionMsg.SetType(0);std::srand(1729);
        };
        auto apply=[&](uint16 origin,uint16 buff=ESBUFF_Shield,int amount=1001,int duration=2,uint8 target=2) {
            std::vector<int> p{amount,amount,2500};fight.AddBuff(target,1,buff,duration,&p,origin);
        };
        auto lose=[&](int origin=122,int remaining=0,bool expired=false) {
            SFightBuffData b;b.id=ESBUFF_Shield;b.srcPos=1;b.originSkill=origin;b.leftTurn=expired?1:2;b.paraList={remaining,1001};
            fight.m_members[1].buff_list.push_back(b);fight.SpecialBuffPassAttr(2,b.id,true);
            if(expired)fight.DecAllStateEffectTurn(2);else fight.ShieldBrokenCheck(2,enemy);
        };
        auto turns=[&](uint8 target){for(const auto& b:fight.m_members[target-1].buff_list)if(b.id==ESBUFF_Shield)return b.leftTurn;return 0;};
        setup(1);apply(121,ESBUFF_ShieldMianShang);metrics["shield_full_a_personal"]=fight.GetStatePara1(2,ESBUFF_ShieldMianShang);metrics["shield_full_a_guard"]=fight.GetStatePara3(2,ESBUFF_ShieldMianShang);
        setup(1);apply(122);metrics["shield_full_a_group"]=fight.GetStatePara1(2,ESBUFF_Shield);metrics["shield_full_a_duration"]=turns(2);
        setup(1);unit(3,12,1,10000);apply(0);metrics["shield_full_aura_once"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(0);unit(3,12,1,10000);apply(0);metrics["shield_full_aura_other_source"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(0);unit(3,12,1,0);fight.SetState(3,EFST_STATE_Die);apply(0);metrics["shield_full_aura_dead"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(2);apply(121);metrics["shield_full_b_personal"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(2);apply(122);metrics["shield_full_b_group"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(1);lose();metrics["shield_full_a_heal"]=fight.GetHp(2);lose();metrics["shield_full_a_repeat"]=fight.GetHp(2);++fight.m_fightTurn;lose();metrics["shield_full_a_next"]=fight.GetHp(2);
        setup(1);fight.m_members[1].hp=0;fight.SetState(2,EFST_STATE_Die);lose();fight.ClearState(2,EFST_STATE_Die);fight.m_members[1].hp=4000;lose();metrics["shield_full_a_dead_budget"]=fight.GetHp(2);
        setup(2);lose(121);metrics["shield_full_b_counter_total"]=10000-fight.GetHp(enemy);metrics["shield_full_b_counter_other"]=10000-fight.GetHp(otherEnemy);metrics["shield_full_b_conversion"]=fight.GetStatePara1(2,ESBUFF_Shield);metrics["shield_full_b_conversion_duration"]=turns(2);
        setup(2);lose();metrics["shield_full_b_burst"]=10000-fight.GetHp(enemy);lose();lose();metrics["shield_full_b_three"]=10000-fight.GetHp(enemy);++fight.m_fightTurn;lose();metrics["shield_full_b_next"]=10000-fight.GetHp(enemy);
        setup(2);lose(122,601,true);metrics["shield_full_b_expiry"]=10000-fight.GetHp(enemy);metrics["shield_full_b_expiry_shield"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(2);fight.m_members[enemy-1].hp=7;fight.m_members[otherEnemy-1].hp=11;lose(121);metrics["shield_full_b_actual_cap"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(2);fight.m_members[0].unitAttr.maxHp=100;fight.m_members[0].hp=100;lose();lose();metrics["shield_full_b_budget_spent"]=fight.m_combatState.amounts[{1,1229}].spent;
        setup(2);fight.m_members[enemy-1].hp=5000;affix(enemy,3,3);
        std::vector<int> enemyShield{100,100};fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&enemyShield);
        lose();metrics["shield_full_b_nested_recovery_hp"]=fight.GetHp(enemy);metrics["shield_full_b_nested_recovery_conversion"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(1);affix(1,2,3);apply(122,ESBUFF_Shield,1001,255,1);metrics["shield_full_a_own_256"]=turns(1);metrics["shield_full_a_share_255"]=turns(2);
        metrics["shield_full_passed"]=metrics["shield_full_a_personal"]==1371 && metrics["shield_full_a_guard"]==3300
            && metrics["shield_full_a_group"]==1321 && metrics["shield_full_a_duration"]==3 && metrics["shield_full_aura_once"]==1121 && metrics["shield_full_aura_other_source"]==1121 && metrics["shield_full_aura_dead"]==1001
            && metrics["shield_full_b_personal"]==850 && metrics["shield_full_b_group"]==800 && metrics["shield_full_a_heal"]==4300 && metrics["shield_full_a_repeat"]==4300 && metrics["shield_full_a_next"]==4585
            && metrics["shield_full_a_dead_budget"]==4000 && metrics["shield_full_b_counter_total"]==650 && metrics["shield_full_b_counter_other"]==350 && metrics["shield_full_b_conversion"]==150
            && metrics["shield_full_b_burst"]==530 && metrics["shield_full_b_three"]==1240 && metrics["shield_full_b_next"]==1770
            && metrics["shield_full_b_expiry"]==105 && metrics["shield_full_b_expiry_shield"]==31 && metrics["shield_full_b_actual_cap"]==2
            && metrics["shield_full_b_budget_spent"]==12 && metrics["shield_full_a_own_256"]==256 && metrics["shield_full_a_share_255"]==255
            && metrics["shield_full_b_nested_recovery_hp"]==4970 && metrics["shield_full_b_nested_recovery_conversion"]==84;
        return metrics;
    }();
    for(const auto& metric:shieldFullMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto reviveOrderMetrics=[&]() {
        fight.Clear();unit(1,10,1,9000);unit(2,23,0,0);unit(enemy,23,0,10000);fight.SetState(2,EFST_STATE_Die);
        fight.m_members[0].combatLoadout=catalog.Snapshot({artifact(5,1303,51)});
        for(CNetMessage* message:{&fight.m_actionMsg,&fight.m_extActionMsg,&fight.m_otherMsg}){message->ReWrite();message->SetType(0);}
        std::srand(1729);fight.CalculateSkill_AddHp(1,102,1);
        std::vector<int> guards;
        for(const auto& buff:fight.m_members[1].buff_list)if(buff.id==ESBUFF_JianShangLvAdd || buff.id==ESBUFF_MianShangTemp)guards.push_back(buff.id);
        return CombatData::Values{{"real_revive_hp",fight.GetHp(2)},
            {"real_revive_guard_count",static_cast<int64>(guards.size())},
            {"real_revive_guard_first",guards.empty()?0:guards[0]},
            {"revive_order_passed",fight.IsAlive(2) && fight.GetHp(2)>0 && guards==std::vector<int>{ESBUFF_JianShangLvAdd,ESBUFF_MianShangTemp}?1:0}};
    }();
    for(const auto& metric:reviveOrderMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto receivedOrderMetrics=[&]() {
        fight.Clear();unit(1,23,0,10000);unit(enemy,57,2,10000);affix(enemy,16,1);
        // The formal affix requires at least20% actual HP loss; stay above it.
        fight.m_members[0].unitAttr.attack=3000;fight.m_members[0].unitAttr.mingzhongLv=10000;
        for(CNetMessage* message:{&fight.m_actionMsg,&fight.m_extActionMsg,&fight.m_otherMsg}){message->ReWrite();message->SetType(0);}
        int selfDamage=0;std::srand(1729);fight.CalculateOnceAction(1,enemy,0,1,selfDamage,true);
        std::vector<int> effects;
        for(const auto& buff:fight.m_members[enemy-1].buff_list)if(buff.id==ESBUFF_DamagePercentAdd || buff.id==ESBUFF_FanZhengAllAdd)effects.push_back(buff.id);
        return CombatData::Values{{"received_order_hp_loss",10000-fight.GetHp(enemy)},
            {"received_order_first",effects.empty()?0:effects[0]},
            {"received_order_passed",fight.GetHp(enemy)<10000 && effects==std::vector<int>{ESBUFF_DamagePercentAdd,ESBUFF_FanZhengAllAdd}?1:0}};
    }();
    for(const auto& metric:receivedOrderMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto pursuitFullMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=2,int hero=15) {
            fight.Clear();unit(1,hero,branch,10000);unit(enemy,23,0,10000);
            fight.m_combatDepth=0;
            fight.m_members[0].unitAttr.attack=1001;fight.m_members[0].unitAttr.mingzhongLv=10000;
            fight.m_members[0].unitAttr.lianjiAdd=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
            fight.m_members[enemy-1].unitAttr.baojikangLv=10000;std::srand(1729);
        };
        auto event=[&](int amount=1000) {fight.CombatEvent("after_primary_hit",1,enemy,151,0,1,
            {{"amount",amount},{"event_target_alive",fight.IsAlive(enemy)?1:0}});};
        auto spent=[&](){return fight.m_combatState.counts[{1,1500,0}].inBattle;};
        auto bonus=[&](int skill=152){CombatData::Modifiers m;fight.CombatEvent("before_direct_damage",1,enemy,skill,0,1,{},&m);return m.amountBonus;};
        auto hit=[&](bool first=true,bool counter=false){std::vector<SAttrData> own,other;int self=0;
            fight.BasicFightAction(1,enemy,151,1,self,own,other,counter,first);};
        setup();const int expectedRandom=std::rand();std::srand(1729);event();
        metrics["pursuit_full_first"]=10000-fight.GetHp(enemy);metrics["pursuit_full_rng"]=std::rand()==expectedRandom;
        event();metrics["pursuit_full_repeat"]=10000-fight.GetHp(enemy);
        ++fight.m_fightTurn;event();metrics["pursuit_full_next"]=10000-fight.GetHp(enemy);
        setup();event(0);metrics["pursuit_full_zero_spent"]=spent();event();metrics["pursuit_full_after_zero"]=10000-fight.GetHp(enemy);
        setup();fight.SetState(enemy,EFST_STATE_Die);fight.m_members[enemy-1].hp=0;event();metrics["pursuit_full_dead_target_spent"]=spent();
        fight.ClearState(enemy,EFST_STATE_Die);fight.m_members[enemy-1].hp=10000;event();metrics["pursuit_full_after_dead"]=10000-fight.GetHp(enemy);
        setup();for(int i=0;i<catalog.Rule("extra_attack_per_turn");++i)fight.CombatTryExtraAttack(1);event();
        metrics["pursuit_full_exhausted_spent"]=spent();metrics["pursuit_full_exhausted_damage"]=10000-fight.GetHp(enemy);
        fight.m_combatState.extraAttacks.clear();event();metrics["pursuit_full_after_exhaustion"]=10000-fight.GetHp(enemy);
        setup();fight.SetState(1,EFST_STATE_Die);fight.m_members[0].hp=0;event();metrics["pursuit_full_dead_source_spent"]=spent();
        setup();fight.m_combatState.revivedAt[1]=fight.m_fightTurn;event();metrics["pursuit_full_revived_spent"]=spent();
        setup();hit(false);metrics["pursuit_full_combo_spent"]=spent();
        setup();hit(true,true);metrics["pursuit_full_counter_spent"]=spent();
        setup();fight.m_combatDepth=1;hit();metrics["pursuit_full_secondary_spent"]=spent();fight.m_combatDepth=0;
        setup();hit();metrics["pursuit_full_primary_spent"]=spent();
        setup();std::vector<int> shield{5000,5000};fight.AddBuff(enemy,enemy,ESBUFF_Shield,3,&shield);hit();
        metrics["pursuit_full_shield_spent"]=spent();metrics["pursuit_full_shield_hp_loss"]=10000-fight.GetHp(enemy);
        setup();fight.m_members[enemy-1].hp=3999;metrics["pursuit_full_low_bonus"]=bonus();
        fight.m_members[enemy-1].hp=4000;metrics["pursuit_full_boundary_bonus"]=bonus();
        fight.m_members[enemy-1].hp=3999;metrics["pursuit_full_wrong_skill"]=bonus(151);
        setup(0);fight.m_members[enemy-1].hp=3999;metrics["pursuit_full_unselected_bonus"]=bonus();event();metrics["pursuit_full_unselected_damage"]=3999-fight.GetHp(enemy);
        setup(2,23);fight.m_members[enemy-1].hp=3999;metrics["pursuit_full_other_hero_bonus"]=bonus();
        setup();std::vector<int> strong{1500},weak{800};
        fight.AddBuff(enemy,1,ESBUFF_GetWuDamageAdd,3,&strong,151);fight.AddBuff(enemy,enemy,ESBUFF_GetWuDamageAdd,2,&weak,152);
        metrics["pursuit_full_vulnerability_value"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        metrics["pursuit_full_vulnerability_count"]=fight.m_members[enemy-1].buff_list.size();
        fight.AddBuff(1,1,ESBUFF_AddSpeed,3,&strong,153);fight.AddBuff(1,1,ESBUFF_AddSpeed,2,&weak,153);
        metrics["pursuit_full_speed_count"]=fight.m_members[0].buff_list.size();
        metrics["pursuit_full_speed_value"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        metrics["pursuit_full_passed"]=metrics["pursuit_full_first"]==600 && metrics["pursuit_full_repeat"]==600 && metrics["pursuit_full_next"]==1200
            && metrics["pursuit_full_rng"]==1 && metrics["pursuit_full_zero_spent"]==1 && metrics["pursuit_full_after_zero"]==0
            && metrics["pursuit_full_dead_target_spent"]==0 && metrics["pursuit_full_after_dead"]==600
            && metrics["pursuit_full_exhausted_spent"]==0 && metrics["pursuit_full_exhausted_damage"]==0 && metrics["pursuit_full_after_exhaustion"]==600
            && metrics["pursuit_full_dead_source_spent"]==0 && metrics["pursuit_full_revived_spent"]==0 && metrics["pursuit_full_combo_spent"]==0
            && metrics["pursuit_full_counter_spent"]==0 && metrics["pursuit_full_secondary_spent"]==0 && metrics["pursuit_full_primary_spent"]==1
            && metrics["pursuit_full_shield_spent"]==1 && metrics["pursuit_full_shield_hp_loss"]==0 && metrics["pursuit_full_low_bonus"]==2000
            && metrics["pursuit_full_boundary_bonus"]==0 && metrics["pursuit_full_wrong_skill"]==0 && metrics["pursuit_full_unselected_bonus"]==0
            && metrics["pursuit_full_other_hero_bonus"]==0 && metrics["pursuit_full_unselected_damage"]==0
            && metrics["pursuit_full_vulnerability_value"]==1500 && metrics["pursuit_full_vulnerability_count"]==1
            && metrics["pursuit_full_speed_count"]==1 && metrics["pursuit_full_speed_value"]==800?1:0;
        return metrics;
    }();
    for(const auto& metric:pursuitFullMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero15bMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&]() {
            fight.Clear();unit(1,15,2,10000);unit(2,23,0,4000);unit(enemy,23,0,10000);unit(otherEnemy,23,0,3000);
            auto& source=fight.m_members[0];source.unitAttr.attack=1000;source.unitAttr.mingzhongLv=10000;
            source.unitAttr.attackBase=1000;source.unitAttr.maxHpBase=10000;
            source.unitAttr.attackRatio=source.unitAttr.maxHpRatio=source.unitAttr.wufangRatio=source.unitAttr.fafangRatio=10000;
            source.unitAttr.lianjiAdd=10000;source.unitAttr.fanjiAdd=10000;source.option=EOTNormal;
            source.passive_skill.push_back(SSkillData(154,1));
            fight.m_members[enemy-1].unitAttr.baojikangLv=10000;fight.m_members[otherEnemy-1].unitAttr.baojikangLv=10000;
            std::srand(1729);
        };
        auto death=[&](uint8 target,bool escaped=false) {
            fight.m_members[target-1].hp=0;fight.SetState(target,EFST_STATE_Die);
            if(escaped)fight.m_members[target-1].state|=static_cast<uint8>(1<<(EFST_STATE_Escape-1));
            std::vector<ESkillTriggerType> triggers{ESkill_Trigger_UnitDied};std::vector<ESkillPassitiveType> types{ESkill_Pass_Attr};
            fight.CalculatePassiveSkill_ExtAttrEffect(1,target,triggers,types);
        };
        auto growth=[&](){return fight.m_members[0].GetPassSkillLimitData(154,ESkill_Pass_Attr,50);};
        auto chase=[&](){CNetMessage output;output.SetType(0);fight.m_members[0].AddKillUnit(enemy);return fight.KilledAction(1,output);};
        auto attempts=[&](){return fight.m_combatState.counts[{1,1521,0}].inBattle;};
        setup();death(enemy);metrics["hero15b_growth_enemy"]=growth()->_value;
        metrics["hero15b_growth_actual_attack"]=fight.GetUnitAttack(1);metrics["hero15b_growth_actual_max_hp"]=fight.GetMaxHp(1);
        setup();death(2);metrics["hero15b_growth_ally"]=growth()->_value;
        setup();for(int i=0;i<7;++i)death(i%2?2:enemy);metrics["hero15b_growth_cap"]=growth()->_count;metrics["hero15b_growth_capped_value"]=growth()->_value;
        setup();fight.m_members[enemy-1].affixSummoned=true;const int untouchedRandom=std::rand();std::srand(1729);death(enemy);
        metrics["hero15b_growth_summoned"]=growth()->_value;metrics["hero15b_summoned_rng"]=std::rand()==untouchedRandom;
        setup();death(enemy,true);metrics["hero15b_growth_escape"]=growth()->_value;
        metrics["hero15b_escape_fixture"]=fight.HaveState(enemy,EFST_STATE_Escape)?1:0;
        setup();auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(154);std::vector<int> raw;
        fight.GetPassivePara(1,raw,effect,75);fight.CombatPassiveParameters(1,enemy,154,effect,75,ESkill_Trigger_UnitDied,raw);
        metrics["hero15b_growth_high_level"]=raw[1];metrics["hero15b_growth_limit_parameter"]=raw[2];
        setup();chase();metrics["hero15b_chase_damage"]=3000-fight.GetHp(otherEnemy);metrics["hero15b_chase_attempts"]=attempts();
        const int afterFirst=fight.GetHp(otherEnemy);chase();metrics["hero15b_chase_repeat_damage"]=afterFirst-fight.GetHp(otherEnemy);
        metrics["hero15b_chase_repeat_attempts"]=attempts();metrics["hero15b_chase_scale_restored"]=fight.m_combatDamageScale;
        ++fight.m_fightTurn;chase();metrics["hero15b_chase_next_attempts"]=attempts();
        setup();for(int i=0;i<catalog.Rule("extra_attack_per_turn");++i)fight.CombatTryExtraAttack(1);chase();
        metrics["hero15b_exhausted_attempts"]=attempts();metrics["hero15b_exhausted_damage"]=3000-fight.GetHp(otherEnemy);
        fight.m_combatState.extraAttacks.clear();chase();metrics["hero15b_exhausted_retry_damage"]=3000-fight.GetHp(otherEnemy);
        setup();fight.m_combatState.revivedAt[1]=fight.m_fightTurn;chase();metrics["hero15b_revived_attempts"]=attempts();
        setup();CombatData::Modifiers plan;plan.parameters={-1,10000};fight.CombatEvent("before_kill_action",1,1,0,0,1,{},&plan);
        metrics["hero15b_plan_kind"]=plan.parameters[0];metrics["hero15b_plan_scale"]=plan.parameters[1];
        auto learn=[&](){auto& source=fight.m_members[0];source.skill_list.push_back(SSkillData(151,1));source.skill_list.back().CD=4;source.skill_list.back().leftCD=2;};
        setup();learn();fight.m_members[enemy-1].hp=fight.m_members[otherEnemy-1].hp=0;
        fight.SetState(enemy,EFST_STATE_Die);fight.SetState(otherEnemy,EFST_STATE_Die);
        metrics["hero15b_failed_cast"]=fight.SkillButtle(1,151);metrics["hero15b_failed_cd"]=fight.m_members[0].skill_list.back().leftCD;
        setup();learn();fight.m_combatDepth=1;fight.SkillButtle(1,151);fight.m_combatDepth=0;
        metrics["hero15b_secondary_cd"]=fight.m_members[0].skill_list.back().leftCD;
        setup();learn();fight.SkillButtle(1,151);metrics["hero15b_success_cd"]=fight.m_members[0].skill_list.back().leftCD;
        setup();learn();fight.m_members[0].skill_list.back().id=152;fight.m_members[0].skill_list.back().leftCD=0;fight.m_members[0].combatStrategy=1;
        fight.m_members[1].memPtr=boost::any();fight.m_members[otherEnemy-1].memPtr=boost::any();fight.m_members[enemy-1].unitAttr.attack=100;
        metrics["hero15b_cd_fixture_skill"]=fight.GetUnitAISkillId(1);
        CNetMessage round;round.SetType(0);fight.CalculateFight(round);metrics["hero15b_natural_cd_first"]=fight.m_members[0].skill_list.back().leftCD;
        setup();fight.m_members[enemy-1].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
        fight.m_members[enemy-1].unitAttr.fanjiLv=20000;fight.m_members[0].unitAttr.baojikangLv=10000;
        int self=0;fight.CalculateOnceAction(1,enemy,0,1,self,true);
        metrics["hero15b_counter_received_rage"]=fight.GetTeamRage(1);metrics["hero15b_counter_budget"]=fight.m_combatState.extraAttacks[enemy].inTurn;
        setup();fight.m_members[enemy-1].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;
        fight.m_members[0].unitAttr.baojikangLv=fight.m_members[1].unitAttr.baojikangLv=10000;
        std::vector<int> protection{5000,0,1};fight.AddBuff(2,1,ESBUFF_Protect,3,&protection);
        std::vector<SAttrData> own,other;fight.BasicFightAction(enemy,2,0,1,self,own,other,false,true);
        metrics["hero15b_guard_damage_rage"]=fight.GetTeamRage(1);
        metrics["hero15b_passed"]=metrics["hero15b_growth_enemy"]==600 && metrics["hero15b_growth_ally"]==300
            && metrics["hero15b_growth_actual_attack"]==1060 && metrics["hero15b_growth_actual_max_hp"]==10000
            && metrics["hero15b_growth_cap"]==5 && metrics["hero15b_growth_capped_value"]==2400 && metrics["hero15b_growth_summoned"]==0
            && metrics["hero15b_summoned_rng"]==1 && metrics["hero15b_growth_escape"]==0 && metrics["hero15b_escape_fixture"]==1 && metrics["hero15b_growth_high_level"]==600
            && metrics["hero15b_growth_limit_parameter"]==5 && metrics["hero15b_chase_damage"]>0 && metrics["hero15b_chase_attempts"]==1
            && metrics["hero15b_chase_repeat_damage"]==0 && metrics["hero15b_chase_repeat_attempts"]==1 && metrics["hero15b_chase_next_attempts"]==2
            && metrics["hero15b_chase_scale_restored"]==10000 && metrics["hero15b_exhausted_attempts"]==1 && metrics["hero15b_exhausted_damage"]==0
            && metrics["hero15b_exhausted_retry_damage"]==0 && metrics["hero15b_revived_attempts"]==0
            && metrics["hero15b_plan_kind"]==1 && metrics["hero15b_plan_scale"]==8000 && metrics["hero15b_failed_cast"]==0
            && metrics["hero15b_failed_cd"]==2 && metrics["hero15b_secondary_cd"]==2 && metrics["hero15b_success_cd"]==4
            && metrics["hero15b_cd_fixture_skill"]==152 && metrics["hero15b_natural_cd_first"]==4
            && metrics["hero15b_counter_received_rage"]==3 && metrics["hero15b_counter_budget"]==1 && metrics["hero15b_guard_damage_rage"]==3?1:0;
        return metrics;
    }();
    for(const auto& metric:hero15bMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero15aMetrics=[&]() {
        CombatData::Values metrics;
        int successSeed=1,failureSeed=1;
        for(;;++successSeed){std::srand(successSeed);if(Random(1,10000)<=5000)break;}
        for(;;++failureSeed){std::srand(failureSeed);if(Random(1,10000)>5000)break;}
        auto setup=[&](bool learned=true,int level=1,int branch=1) {
            fight.Clear();unit(1,15,branch,10000);unit(2,23,0,4000);unit(enemy,23,0,10000);unit(otherEnemy,23,0,3000);
            auto& source=fight.m_members[0];source.unitAttr.attack=source.unitAttr.attackBase=1000;source.unitAttr.maxHpBase=10000;
            source.unitAttr.maxHpRatio=source.unitAttr.attackRatio=source.unitAttr.wufangRatio=source.unitAttr.fafangRatio=10000;
            source.unitAttr.speed=100;source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            source.skill_list.push_back(SSkillData(151,1));source.skill_list.push_back(SSkillData(152,1));
            source.skill_list[0].CD=4;source.skill_list[1].CD=3;
            source.passive_skill.push_back(SSkillData(154,1));if(learned)source.passive_skill.push_back(SSkillData(153,level));
            source.option=EOTSkill;source.para=152;source.target=enemy;
            for(uint8 pos:{enemy,otherEnemy})fight.m_members[pos-1].unitAttr.baojikangLv=10000;
            auto pet=boost::any_cast<SharePetPtr>(source.memPtr);pet->basicAttr=source.unitAttr;std::srand(successSeed);
        };
        auto hit=[&](int skill,bool first=true,bool counter=false){std::vector<SAttrData> own,other;int self=0;fight.BasicFightAction(1,enemy,skill,1,self,own,other,counter,first);};
        auto vulnerability=[&](int value){std::vector<int> p{value};fight.AddBuff(enemy,1,ESBUFF_GetWuDamageAdd,3,&p);};
        auto chase=[&](){CNetMessage output;output.SetType(0);fight.m_members[0].AddKillUnit(enemy);fight.KilledAction(1,output);};
        auto count=[&](){return fight.m_combatState.counts[{1,1537,0}].inBattle;};
        setup();CombatData::Modifiers query;query.parameters={4000};query.duration=7;
        fight.CombatEvent("before_buff",1,enemy,151,ESBUFF_GetWuDamageAdd,1,{},&query);
        metrics["hero15a_query_vulnerability"]=query.parameters[0];metrics["hero15a_query_duration"]=query.duration;
        query.parameters.clear();query.duration=7;fight.CombatEvent("before_buff",1,enemy,151,ESBUFF_GetWuDamageAdd,1,{},&query);
        metrics["hero15a_empty_parameters"]=query.parameters.size();metrics["hero15a_empty_duration"]=query.duration;
        setup();hit(151);metrics["hero15a_real_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);metrics["hero15a_real_duration"]=lastDuration(enemy,ESBUFF_GetWuDamageAdd);
        setup();hit(152);metrics["hero15a_after_primary"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);metrics["hero15a_after_duration"]=lastDuration(enemy,ESBUFF_GetWuDamageAdd);
        setup();vulnerability(500);hit(152);metrics["hero15a_weak_replaced"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup();vulnerability(1500);hit(152);metrics["hero15a_strong_kept"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup();vulnerability(800);hit(152);metrics["hero15a_equal_kept_duration"]=lastDuration(enemy,ESBUFF_GetWuDamageAdd);
        setup();hit(152,false);metrics["hero15a_combo_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup();hit(152,true,true);metrics["hero15a_counter_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup();fight.m_combatDepth=1;hit(152);fight.m_combatDepth=0;metrics["hero15a_secondary_vulnerability"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup();fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_GetWuDamageAdd);hit(152);metrics["hero15a_direct_immunity_bypass"]=fight.GetStatePara1(enemy,ESBUFF_GetWuDamageAdd);
        setup(false);fight.m_members[0].option=EOTNormal;chase();metrics["hero15a_speed_without_passive"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        setup(true,75);fight.m_members[0].option=EOTNormal;chase();metrics["hero15a_speed_high_level"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        setup();metrics["hero15a_fixture_force_end"]=fight.m_forceEnd?1:0;metrics["hero15a_fixture_alive"]=fight.IsAlive(1)?1:0;
        metrics["hero15a_fixture_option"]=fight.m_members[0].option;metrics["hero15a_fixture_depth"]=fight.m_combatDepth;
        CombatData::Modifiers eligibility;eligibility.parameters={-1,10000};fight.CombatEvent("before_kill_action",1,1,152,0,1,{},&eligibility);
        metrics["hero15a_fixture_plan"]=eligibility.parameters[0];metrics["hero15a_fixture_record_age"]=fight.m_fightTurn-fight.m_combatState.counts[{1,1537,0}].lastTriggered;
        chase();metrics["hero15a_speed_known"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);metrics["hero15a_speed_duration"]=lastDuration(1,ESBUFF_AddSpeed);
        metrics["hero15a_permanent_speed_count"]=fight.m_members[0].GetPassSkillLimitData(153,ESkill_Pass_Attr,54)->_count;
        metrics["hero15a_chase_success_count"]=count();metrics["hero15a_chase_extra_count"]=fight.m_combatState.extraAttacks[1].inTurn;
        std::srand(1729);const int repeatRandom=std::rand();std::srand(1729);chase();metrics["hero15a_repeat_rng"]=std::rand()==repeatRandom;metrics["hero15a_same_turn_count"]=count();
        ++fight.m_fightTurn;std::srand(successSeed);chase();metrics["hero15a_next_turn_count"]=count();
        setup();std::srand(failureSeed);chase();metrics["hero15a_chance_failure_record"]=count();
        setup();fight.m_members[enemy-1].hp=0;fight.SetState(enemy,EFST_STATE_Die);
        std::vector<ESkillTriggerType> killTriggers{ESkill_Trigger_KillTarget};std::vector<ESkillPassitiveType> attrPass{ESkill_Pass_Attr};
        fight.CalculatePassiveSkill_ExtAttrEffect(1,enemy,killTriggers,attrPass,152,1);
        metrics["hero15a_legacy_speed_filtered"]=fight.m_members[0].GetPassSkillLimitData(153,ESkill_Pass_Attr,54)->_count;
        setup();for(int i=0;i<catalog.Rule("extra_attack_per_turn");++i)fight.CombatTryExtraAttack(1);chase();
        metrics["hero15a_exhausted_success_record"]=count();metrics["hero15a_exhausted_damage"]=10000-fight.GetHp(enemy)+3000-fight.GetHp(otherEnemy);
        setup();fight.m_combatState.revivedAt[1]=fight.m_fightTurn;
        std::srand(1729);const int revivedRandom=std::rand();std::srand(1729);chase();metrics["hero15a_revived_rng"]=std::rand()==revivedRandom;
        metrics["hero15a_revived_count"]=count();metrics["hero15a_revived_speed"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        auto repeat=[&](int branch){setup(true,1,branch);CNetMessage output;output.SetType(0);const int before=fight.GetHp(enemy)+fight.GetHp(otherEnemy);fight.NotKilledAction(1,output);return before-static_cast<int>(fight.GetHp(enemy)+fight.GetHp(otherEnemy));};
        metrics["hero15a_repeat_raw"]=repeat(0);metrics["hero15a_repeat_damage"]=repeat(1);metrics["hero15a_repeat_scale_restored"]=fight.m_combatDamageScale;
        setup();CombatData::Modifiers scale;scale.parameters={10000};fight.CombatEvent("before_action_repeat",1,1,152,0,1,{},&scale);metrics["hero15a_repeat_scale"]=scale.parameters[0];
        auto death=[&](uint8 target){fight.m_members[target-1].hp=0;fight.SetState(target,EFST_STATE_Die);std::vector<ESkillTriggerType> trigger{ESkill_Trigger_UnitDied};std::vector<ESkillPassitiveType> pass{ESkill_Pass_Attr};fight.CalculatePassiveSkill_ExtAttrEffect(1,target,trigger,pass);};
        auto growth=[&](){return fight.m_members[0].GetPassSkillLimitData(154,ESkill_Pass_Attr,50);};
        setup();death(enemy);metrics["hero15a_growth_enemy"]=growth()->_value;metrics["hero15a_growth_actual_attack"]=fight.GetUnitAttack(1);
        setup();death(2);metrics["hero15a_growth_ally"]=growth()->_value;
        setup();for(int i=0;i<7;++i)death(i%2?2:enemy);metrics["hero15a_growth_cap"]=growth()->_count;metrics["hero15a_growth_capped"]=growth()->_value;
        setup();fight.m_members[enemy-1].affixSummoned=true;death(enemy);metrics["hero15a_growth_summoned"]=growth()->_value;
        metrics["hero15a_passed"]=metrics["hero15a_query_vulnerability"]==1500 && metrics["hero15a_query_duration"]==3
            && metrics["hero15a_empty_parameters"]==0 && metrics["hero15a_empty_duration"]==7 && metrics["hero15a_real_vulnerability"]==1500 && metrics["hero15a_real_duration"]==3
            && metrics["hero15a_after_primary"]==800 && metrics["hero15a_after_duration"]==2 && metrics["hero15a_weak_replaced"]==800 && metrics["hero15a_strong_kept"]==1500
            && metrics["hero15a_equal_kept_duration"]==3 && metrics["hero15a_combo_vulnerability"]==0 && metrics["hero15a_counter_vulnerability"]==0 && metrics["hero15a_secondary_vulnerability"]==0
            && metrics["hero15a_direct_immunity_bypass"]==800 && metrics["hero15a_speed_without_passive"]==2000 && metrics["hero15a_speed_high_level"]==10500
            && metrics["hero15a_speed_known"]==3100 && metrics["hero15a_speed_duration"]==2 && metrics["hero15a_permanent_speed_count"]==0
            && metrics["hero15a_chase_success_count"]==1 && metrics["hero15a_chase_extra_count"]==1 && metrics["hero15a_repeat_rng"]==1 && metrics["hero15a_same_turn_count"]==1
            && metrics["hero15a_next_turn_count"]==2 && metrics["hero15a_chance_failure_record"]==0 && metrics["hero15a_legacy_speed_filtered"]==0
            && metrics["hero15a_exhausted_success_record"]==1 && metrics["hero15a_exhausted_damage"]==0
            && metrics["hero15a_revived_rng"]==1 && metrics["hero15a_revived_count"]==0 && metrics["hero15a_revived_speed"]==3100
            && metrics["hero15a_repeat_raw"]>0 && metrics["hero15a_repeat_damage"]==metrics["hero15a_repeat_raw"]*7000/10000 && metrics["hero15a_repeat_scale_restored"]==10000
            && metrics["hero15a_repeat_scale"]==7000 && metrics["hero15a_growth_enemy"]==400 && metrics["hero15a_growth_ally"]==400 && metrics["hero15a_growth_actual_attack"]==1040
            && metrics["hero15a_growth_cap"]==5 && metrics["hero15a_growth_capped"]==2000 && metrics["hero15a_growth_summoned"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:hero15aMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero61aMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=1) {
            fight.Clear();unit(1,61,branch,10000);unit(2,23,0,4000);unit(enemy,23,0,10000);
            auto& source=fight.m_members[0];source.attackType=1;source.unitAttr.attack=source.unitAttr.attackBase=1000;source.unitAttr.maxHpBase=10000;
            source.unitAttr.maxHpRatio=source.unitAttr.attackRatio=source.unitAttr.wufangRatio=source.unitAttr.fafangRatio=10000;
            source.unitAttr.mingzhongLv=10000;source.unitAttr.baojikangLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            source.skill_list.push_back(SSkillData(611,1));source.skill_list.push_back(SSkillData(612,1));
            fight.m_members[enemy-1].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;fight.m_members[enemy-1].unitAttr.fanjiAdd=10000;
            std::srand(1729);
        };
        auto cast=[&](int skill=611){return fight.CalculateSkill_DamageHp(1,skill,1);};
        setup();const int actionsBefore=fight.m_extActionMsg.GetType();metrics["hero61a_success"]=cast();metrics["hero61a_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);metrics["hero61a_duration"]=lastDuration(1,ESBUFF_JianShangLvAdd);
        metrics["hero61a_enemy_guard"]=fight.GetStatePara1(enemy,ESBUFF_JianShangLvAdd);metrics["hero61a_emitted_actions"]=fight.m_extActionMsg.GetType()-actionsBefore;
        setup();cast(612);metrics["hero61a_taunt"]=lastDuration(enemy,ESBUFF_ChaoFeng);metrics["hero61a_tactic_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        setup();fight.m_combatDepth=1;cast();fight.m_combatDepth=0;metrics["hero61a_secondary_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        setup();fight.m_combatDepth=2;cast();fight.m_combatDepth=0;metrics["hero61a_nested_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        auto counterLoss=[&](int branch){setup(branch);fight.m_members[enemy-1].unitAttr.fanjiLv=20000;cast();return 10000-static_cast<int>(fight.GetHp(1));};
        metrics["hero61a_counter_base_loss"]=counterLoss(0);metrics["hero61a_counter_loss"]=counterLoss(1);
        metrics["hero61a_timing_preserved"]=metrics["hero61a_counter_loss"]==metrics["hero61a_counter_base_loss"]?1:0;
        setup();fight.m_members[0].hp=1;fight.m_members[enemy-1].unitAttr.fanjiLv=20000;cast();
        metrics["hero61a_counter_death"]=fight.IsAlive(1)?0:1;metrics["hero61a_dead_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        setup();fight.m_members[enemy-1].memPtr=boost::any();metrics["hero61a_empty_success"]=cast();metrics["hero61a_empty_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        setup();fight.m_members[0].notEffectBuff.push_back(ESBUFF_JianShangLvAdd);cast();metrics["hero61a_immunity_bypass"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        setup();fight.m_curActionPos=1;cast();fight.DecAllStateEffectTurn(1);metrics["hero61a_same_action_duration"]=lastDuration(1,ESBUFF_JianShangLvAdd);
        ++fight.m_fightTurn;fight.DecAllStateEffectTurn(1);metrics["hero61a_next_duration"]=lastDuration(1,ESBUFF_JianShangLvAdd);
        setup();cast();fight.DecAllStateEffectTurn(1);cast();metrics["hero61a_refresh_duration"]=lastDuration(1,ESBUFF_JianShangLvAdd);metrics["hero61a_refresh_count"]=0;for(const auto& buff:fight.m_members[0].buff_list)if(buff.id==ESBUFF_JianShangLvAdd)++metrics["hero61a_refresh_count"];
        metrics["hero61a_origin"]=0;for(const auto& buff:fight.m_members[0].buff_list)if(buff.id==ESBUFF_JianShangLvAdd)metrics["hero61a_origin"]=buff.originSkill;
        setup(0);cast();metrics["hero61a_unselected_guard"]=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd);
        metrics["hero61a_passed"]=metrics["hero61a_success"]==1 && metrics["hero61a_guard"]==1200 && metrics["hero61a_duration"]==2
            && metrics["hero61a_taunt"]==2 && metrics["hero61a_tactic_guard"]==0 && metrics["hero61a_secondary_guard"]==1200 && metrics["hero61a_nested_guard"]==0
            && metrics["hero61a_counter_base_loss"]>100 && metrics["hero61a_timing_preserved"]==1
            && metrics["hero61a_counter_death"]==1 && metrics["hero61a_dead_guard"]==1200 && metrics["hero61a_empty_success"]==0 && metrics["hero61a_empty_guard"]==0
            && metrics["hero61a_immunity_bypass"]==1200 && metrics["hero61a_same_action_duration"]==2 && metrics["hero61a_next_duration"]==1
            && metrics["hero61a_refresh_count"]==1 && metrics["hero61a_refresh_duration"]==2 && metrics["hero61a_origin"]==611 && metrics["hero61a_unselected_guard"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:hero61aMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero65aMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=1,int level=1) {
            fight.Clear();unit(1,65,branch,10000);unit(2,23,0,10000);unit(enemy,23,0,1000000);unit(otherEnemy,23,0,1000000);
            auto& source=fight.m_members[0];source.attackType=1;source.unitAttr.attack=source.unitAttr.attackBase=1000;
            source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            source.skill_list.push_back(SSkillData(651,level));source.skill_list.push_back(SSkillData(652,level));source.passive_skill.push_back(SSkillData(653,level));
            for(uint8 pos:{enemy,otherEnemy}){fight.m_members[pos-1].unitAttr.maxHp=1000000;fight.m_members[pos-1].unitAttr.baojikangLv=10000;}
            std::srand(1729);
        };
        auto aura=[&]() {std::vector<ESkillTriggerType> triggers{ESkill_Trigger_FightBegin};std::vector<ESkillPassitiveType> types{ESkill_Pass_Attr};fight.CalculatePassiveSkill_ExtAttrEffect(1,0,triggers,types);};
        auto raw=[&](int level,int skill=653) {auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(skill);std::vector<int> p;fight.GetPassivePara(1,p,effect,level);fight.CombatPassiveParameters(1,0,skill,effect,level,ESkill_Trigger_FightBegin,p);return p;};
        setup();metrics["hero65a_raw"]=raw(1)[1];aura();metrics["hero65a_enemy_aura"]=fight.m_members[enemy-1].unitAttr.fumianAdd;
        metrics["hero65a_other_enemy_aura"]=fight.m_members[otherEnemy-1].unitAttr.fumianAdd;metrics["hero65a_self_aura"]=fight.m_members[0].unitAttr.fumianAdd;metrics["hero65a_ally_aura"]=fight.m_members[1].unitAttr.fumianAdd;
        setup(1,75);metrics["hero65a_high_raw"]=raw(75)[1];aura();metrics["hero65a_high_aura"]=fight.m_members[enemy-1].unitAttr.fumianAdd;
        setup(0);aura();metrics["hero65a_unselected_aura"]=fight.m_members[enemy-1].unitAttr.fumianAdd;
        setup();metrics["hero65a_other_passive"]=raw(1,654)[1];
        setup();metrics["hero65a_cast"]=fight.CalculateSkill_DamageHp(1,651,1);metrics["hero65a_poison"]=fight.GetStatePara1(enemy,ESBUFF_ShiDu);metrics["hero65a_poison_duration"]=lastDuration(enemy,ESBUFF_ShiDu);
        metrics["hero65a_poison_flat"]=0;for(const auto& buff:fight.m_members[enemy-1].buff_list)if(buff.id==ESBUFF_ShiDu && buff.paraList.size()>1)metrics["hero65a_poison_flat"]=buff.paraList[1];
        setup(1,75);fight.CalculateSkill_DamageHp(1,651,75);metrics["hero65a_high_poison"]=fight.GetStatePara1(enemy,ESBUFF_ShiDu);
        setup(0);fight.CalculateSkill_DamageHp(1,651,1);metrics["hero65a_unselected_poison"]=fight.GetStatePara1(enemy,ESBUFF_ShiDu);
        setup();fight.CalculateSkill_DamageHp(1,652,1);metrics["hero65a_tactic_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);
        metrics["hero65a_passed"]=metrics["hero65a_raw"]==-1900 && metrics["hero65a_enemy_aura"]==-1900 && metrics["hero65a_other_enemy_aura"]==-1900
            && metrics["hero65a_self_aura"]==0 && metrics["hero65a_ally_aura"]==0 && metrics["hero65a_high_raw"]==-9300 && metrics["hero65a_high_aura"]==-9300
            && metrics["hero65a_unselected_aura"]==-1100 && metrics["hero65a_other_passive"]==1100 && metrics["hero65a_cast"]==1
            && metrics["hero65a_poison"]==732 && metrics["hero65a_poison_flat"]==120 && metrics["hero65a_poison_duration"]==3
            && metrics["hero65a_high_poison"]==1620 && metrics["hero65a_unselected_poison"]==610 && metrics["hero65a_tactic_defense"]==3000?1:0;
        return metrics;
    }();
    for(const auto& metric:hero65aMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero65bMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=2,int level=1) {
            fight.Clear();unit(1,65,branch,10000);unit(2,23,0,10000);unit(enemy,23,0,1000000);
            auto& source=fight.m_members[0];source.attackType=1;source.unitAttr.attack=source.unitAttr.attackBase=1000;
            source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            source.skill_list.push_back(SSkillData(651,level));source.skill_list.push_back(SSkillData(652,level));source.passive_skill.push_back(SSkillData(654,level));
            fight.m_members[enemy-1].unitAttr.maxHp=1000000;fight.m_members[enemy-1].unitAttr.baojikangLv=10000;std::srand(1729);
        };
        auto raw=[&](int level) {auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(654);std::vector<int> p;fight.GetPassivePara(1,p,effect,level);fight.CombatPassiveParameters(1,0,654,effect,level,ESkill_Trigger_AddAttrBeginFight,p);return p;};
        auto initialize=[&](int level) {auto& source=fight.m_members[0];auto pet=boost::any_cast<SharePetPtr>(source.memPtr);pet->basicAttr=source.unitAttr;pet->hp=source.hp;pet->level=1;pet->attackType=source.attackType;pet->skill[0]=654;pet->skillLevel[0]=level;fight.SetUnitBasicData(1);};
        setup();metrics["hero65b_raw"]=raw(1)[1];initialize(1);metrics["hero65b_initialized_magic_immunity"]=fight.m_members[0].unitAttr.famianLv;
        setup(2,75);metrics["hero65b_high_raw"]=raw(75)[1];initialize(75);metrics["hero65b_high_initialized"]=fight.m_members[0].unitAttr.famianLv;
        setup(0);metrics["hero65b_unselected_raw"]=raw(1)[1];initialize(1);metrics["hero65b_unselected_initialized"]=fight.m_members[0].unitAttr.famianLv;
        setup();metrics["hero65b_cast"]=fight.CalculateSkill_DamageHp(1,652,1);metrics["hero65b_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);metrics["hero65b_duration"]=lastDuration(enemy,ESBUFF_FaFangDes);
        setup(2,75);fight.CalculateSkill_DamageHp(1,652,75);metrics["hero65b_high_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);
        setup();fight.CalculateSkill_DamageHp(1,651,1);metrics["hero65b_regular_poison"]=fight.GetStatePara1(enemy,ESBUFF_ShiDu);
        setup(0);fight.CalculateSkill_DamageHp(1,652,1);metrics["hero65b_unselected_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);
        setup();fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_FaFangDes);fight.CalculateSkill_DamageHp(1,652,1);metrics["hero65b_immune_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);
        setup();fight.m_combatDepth=1;fight.CalculateSkill_DamageHp(1,652,1);fight.m_combatDepth=0;metrics["hero65b_secondary_defense"]=fight.GetStatePara1(enemy,ESBUFF_FaFangDes);
        metrics["hero65b_passed"]=metrics["hero65b_raw"]==1900 && metrics["hero65b_high_raw"]==9300 && metrics["hero65b_unselected_raw"]==1100
            && metrics["hero65b_initialized_magic_immunity"]==1100 && metrics["hero65b_high_initialized"]==8500 && metrics["hero65b_unselected_initialized"]==1100
            && metrics["hero65b_cast"]==1 && metrics["hero65b_defense"]==4000 && metrics["hero65b_high_defense"]==4000 && metrics["hero65b_duration"]==2
            && metrics["hero65b_regular_poison"]==610 && metrics["hero65b_unselected_defense"]==3000 && metrics["hero65b_immune_defense"]==0 && metrics["hero65b_secondary_defense"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:hero65bMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto hero61bMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int branch=2,int level=1,bool summoned=false) {
            fight.Clear();unit(1,61,branch,0);unit(2,23,0,10000);unit(enemy,23,0,100000);unit(otherEnemy,23,0,100000);
            auto& source=fight.m_members[0];source.unitAttr.attack=source.unitAttr.attackBase=1000;source.state=static_cast<uint8>(1<<(EFST_STATE_Die-1));source.affixSummoned=summoned;
            source.passive_skill.push_back(SSkillData(613,level));std::srand(1729);
            for(uint8 pos:{enemy,otherEnemy})fight.m_members[pos-1].unitAttr.maxHp=100000;
        };
        auto blast=[&](int trigger=ESkill_Trigger_DieAndAddToOtherUnit) {std::vector<ESkillTriggerType> triggers{static_cast<ESkillTriggerType>(trigger)};return fight.CalculatePassiveSkill_ExtUnitAndBuff(1,0,triggers,0,0);};
        auto raw=[&](int level) {auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(613);std::vector<int> p;fight.GetPassivePara(1,p,effect,level);fight.CombatPassiveParameters(1,0,613,effect,level,ESkill_Trigger_DieAndAddToOtherUnit,p);return p;};
        setup();auto p=raw(1);metrics["hero61b_life_parameter"]=p[1];metrics["hero61b_cap_parameter"]=p[2];blast();metrics["hero61b_damage"]=100000-fight.GetHp(enemy);metrics["hero61b_other_damage"]=100000-fight.GetHp(otherEnemy);metrics["hero61b_rage"]=fight.GetTeamRage(1);
        const int firstHp=fight.GetHp(enemy);std::srand(7907);const int nextRandom=std::rand();std::srand(7907);blast();metrics["hero61b_repeat_damage"]=firstHp-fight.GetHp(enemy);metrics["hero61b_repeat_rng"]=std::rand()==nextRandom;metrics["hero61b_repeat_rage"]=fight.GetTeamRage(1);
        setup(2,100);blast();metrics["hero61b_capped_damage"]=100000-fight.GetHp(enemy);
        setup(2,1,true);std::srand(7907);const int summonedRandom=std::rand();std::srand(7907);blast();metrics["hero61b_summoned_damage"]=100000-fight.GetHp(enemy);metrics["hero61b_summoned_rage"]=fight.GetTeamRage(1);metrics["hero61b_summoned_rng"]=std::rand()==summonedRandom;
        setup();fight.m_members[enemy-1].memPtr=boost::any();fight.m_members[otherEnemy-1].memPtr=boost::any();blast();metrics["hero61b_empty_rage"]=fight.GetTeamRage(1);unit(enemy,23,0,100000);fight.m_members[enemy-1].unitAttr.maxHp=100000;blast();metrics["hero61b_after_empty_damage"]=100000-fight.GetHp(enemy);
        setup();fight.m_members[0].passive_skill.clear();blast();metrics["hero61b_missing_skill_rage"]=fight.GetTeamRage(1);
        setup();blast(ESkill_Trigger_TurnBegin);metrics["hero61b_wrong_trigger_rage"]=fight.GetTeamRage(1);
        setup(0);blast();metrics["hero61b_unselected_damage"]=100000-fight.GetHp(enemy);metrics["hero61b_unselected_rage"]=fight.GetTeamRage(1);
        setup();fight.m_combatDepth=1;blast();fight.m_combatDepth=0;metrics["hero61b_secondary_damage"]=100000-fight.GetHp(enemy);metrics["hero61b_secondary_rage"]=fight.GetTeamRage(1);
        setup();fight.m_members[0].state=0;fight.m_members[0].hp=10000;int damage=20000,absorbed=0;fight.DecreaseHp(1,enemy,damage,absorbed);const int rageBefore=fight.GetTeamRage(1);CNetMessage output;output.SetType(0);fight.DiePassiveAcion(output);
        metrics["hero61b_real_death_damage"]=100000-fight.GetHp(enemy);metrics["hero61b_real_death_rage"]=fight.GetTeamRage(1)-rageBefore;
        metrics["hero61b_passed"]=metrics["hero61b_life_parameter"]==687 && metrics["hero61b_cap_parameter"]==20000 && metrics["hero61b_damage"]==687 && metrics["hero61b_other_damage"]==687
            && metrics["hero61b_rage"]==8 && metrics["hero61b_repeat_damage"]==0 && metrics["hero61b_repeat_rng"]==1 && metrics["hero61b_repeat_rage"]==8
            && metrics["hero61b_capped_damage"]==2000 && metrics["hero61b_summoned_damage"]==0 && metrics["hero61b_summoned_rage"]==0 && metrics["hero61b_summoned_rng"]==1
            && metrics["hero61b_empty_rage"]==8 && metrics["hero61b_after_empty_damage"]==0 && metrics["hero61b_missing_skill_rage"]==0 && metrics["hero61b_wrong_trigger_rage"]==0
            && metrics["hero61b_unselected_damage"]==550 && metrics["hero61b_unselected_rage"]==0 && metrics["hero61b_secondary_damage"]==0 && metrics["hero61b_secondary_rage"]==8
            && metrics["hero61b_real_death_damage"]==687 && metrics["hero61b_real_death_rage"]==8?1:0;
        return metrics;
    }();
    for(const auto& metric:hero61bMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto stateAffixMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int id) {
            fight.Clear();unit(1,23,0,10000);unit(enemy,23,0,100000);unit(otherEnemy,23,0,100000);affix(1,id,3);
            fight.m_members[0].unitAttr.attack=1001;fight.m_members[0].unitAttr.mingzhongLv=10000;
            fight.m_members[0].unitAttr.lianjiAdd=10000;fight.m_members[0].unitAttr.fanjiAdd=10000;
            for(uint8 pos:{enemy,otherEnemy}){fight.m_members[pos-1].unitAttr.maxHp=100000;fight.m_members[pos-1].unitAttr.baojikangLv=10000;}
            std::srand(1729);
        };
        auto hit=[&](bool first=true,bool counter=false,uint8 target=0) {
            if(!target)target=enemy;
            const int before=fight.GetHp(target);std::vector<SAttrData> own,other;int self=0;
            fight.BasicFightAction(1,target,0,1,self,own,other,counter,first);return before-static_cast<int>(fight.GetHp(target));
        };
        auto count=[&](int id){return fight.m_combatState.counts[{1,id,0}].inBattle;};
        auto criticalBonus=[&](){CombatData::Modifiers m;fight.CombatEvent("before_attack",1,enemy,0,0,1,{},&m);return m.parameterBonuses[1];};
        setup(18);hit();metrics["state_critical_first"]=criticalBonus();metrics["state_critical_repeat_query"]=criticalBonus();
        hit();metrics["state_critical_second"]=criticalBonus();hit();hit();metrics["state_critical_cap"]=criticalBonus();metrics["state_critical_count"]=count(40180);
        fight.m_members[0].unitAttr.baojiLv=20000;
        // A saturated stat still obeys the original80% cap. Select a successful
        // real hit/critical sequence instead of assuming that stat means100%.
        int resetSeed=0;
        for(int seed=0;seed<1000;++seed){std::srand(seed);Random(1,10000);const int roll=Random(1,10000);if(roll<=CombatData::Current().Rule("critical_chance_cap_bp")){resetSeed=seed;metrics["state_critical_reset_roll"]=roll;break;}}
        std::srand(resetSeed);hit();metrics["state_critical_reset"]=criticalBonus();metrics["state_critical_reset_count"]=count(40180);
        setup(18);hit();fight.m_members[0].unitAttr.mingzhongLv=0;fight.m_members[enemy-1].unitAttr.shanbiLv=20000;
        metrics["state_critical_miss_damage"]=hit();metrics["state_critical_miss_count"]=count(40180);
        setup(18);fight.m_combatDepth=1;hit(true,true);metrics["state_critical_counter"]=criticalBonus();fight.m_combatDepth=0;
        setup(18);std::srand(1729);const int queryRandom=std::rand();std::srand(1729);criticalBonus();metrics["state_critical_query_rng"]=std::rand()==queryRandom;
        auto prime=[&](){fight.CombatEvent("after_direct_kill",1,enemy,0,0,1,{{"amount",1000}});};
        auto pending=[&](){return count(40232);};
        setup(23);metrics["state_kill_base_damage"]=hit(false);
        std::vector<SAttrData> reference{SAttrData(ESkill_PassAttr_DamagePer,3000)},other;
        metrics["state_kill_reference_damage"]=fight.CalculateDamage(1,otherEnemy,reference,other);
        setup(23);fight.m_members[0].unitAttr.attack=20001;fight.m_members[enemy-1].hp=1;hit();
        metrics["state_kill_native_pending"]=pending();metrics["state_kill_native_attempts"]=count(40230);
        fight.m_members[0].unitAttr.attack=1001;
        metrics["state_kill_native_damage"]=hit(false,false,otherEnemy);metrics["state_kill_native_consumed"]=pending();
        metrics["state_kill_second_damage"]=hit(false,false,otherEnemy);prime();metrics["state_kill_same_turn_rearm"]=pending();metrics["state_kill_same_turn_attempts"]=count(40230);
        ++fight.m_fightTurn;prime();metrics["state_kill_next_rearm"]=pending();metrics["state_kill_next_attempts"]=count(40230);
        setup(23);prime();hit();metrics["state_kill_first_kept"]=pending();hit(true,true);metrics["state_kill_counter_kept"]=pending();
        fight.m_members[0].unitAttr.mingzhongLv=0;fight.m_members[enemy-1].unitAttr.shanbiLv=20000;metrics["state_kill_miss_damage"]=hit(false);metrics["state_kill_miss_kept"]=pending();
        fight.m_members[0].unitAttr.mingzhongLv=10000;fight.m_members[enemy-1].unitAttr.shanbiLv=0;
        metrics["state_kill_after_skips_damage"]=hit(false);metrics["state_kill_after_skips_pending"]=pending();
        setup(23);prime();++fight.m_fightTurn;metrics["state_kill_next_turn_damage"]=hit(false);metrics["state_kill_next_turn_consumed"]=pending();
        setup(23);prime();fight.m_fightTurn+=2;metrics["state_kill_expired_damage"]=hit(false);metrics["state_kill_expired_pending"]=pending();
        prime();metrics["state_kill_refreshed_pending"]=pending();metrics["state_kill_refreshed_damage"]=hit(false);
        setup(23);prime();fight.m_combatDepth=1;metrics["state_kill_secondary_damage"]=hit(false);metrics["state_kill_secondary_pending"]=pending();fight.m_combatDepth=0;
        setup(23);std::srand(1729);const int primeRandom=std::rand();std::srand(1729);prime();metrics["state_kill_prime_rng"]=std::rand()==primeRandom;
        metrics["state_affix_passed"]=metrics["state_critical_first"]==800 && metrics["state_critical_repeat_query"]==800 && metrics["state_critical_second"]==1600
            && metrics["state_critical_cap"]==2400 && metrics["state_critical_count"]==3 && metrics["state_critical_reset"]==0 && metrics["state_critical_reset_count"]==0
            && metrics["state_critical_miss_damage"]==0 && metrics["state_critical_miss_count"]==1 && metrics["state_critical_counter"]==800 && metrics["state_critical_query_rng"]==1
            && metrics["state_kill_native_pending"]==1 && metrics["state_kill_native_attempts"]==1 && metrics["state_kill_native_damage"]==metrics["state_kill_reference_damage"]
            && metrics["state_kill_native_consumed"]==0 && metrics["state_kill_second_damage"]==metrics["state_kill_base_damage"]
            && metrics["state_kill_same_turn_rearm"]==0 && metrics["state_kill_same_turn_attempts"]==1 && metrics["state_kill_next_rearm"]==1 && metrics["state_kill_next_attempts"]==2
            && metrics["state_kill_first_kept"]==1 && metrics["state_kill_counter_kept"]==1 && metrics["state_kill_miss_damage"]==0 && metrics["state_kill_miss_kept"]==1
            && metrics["state_kill_after_skips_damage"]==metrics["state_kill_reference_damage"] && metrics["state_kill_after_skips_pending"]==0
            && metrics["state_kill_next_turn_damage"]==metrics["state_kill_reference_damage"] && metrics["state_kill_next_turn_consumed"]==0
            && metrics["state_kill_expired_damage"]==metrics["state_kill_base_damage"] && metrics["state_kill_expired_pending"]==1
            && metrics["state_kill_refreshed_pending"]==1 && metrics["state_kill_refreshed_damage"]==metrics["state_kill_reference_damage"]
            && metrics["state_kill_secondary_damage"]==metrics["state_kill_reference_damage"] && metrics["state_kill_secondary_pending"]==0 && metrics["state_kill_prime_rng"]==1?1:0;
        return metrics;
    }();
    for(const auto& metric:stateAffixMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    const auto unifiedMechanismMetrics=[&]() {
        CombatData::Values metrics;
        auto setup=[&](int hero,int branch,int hp=10000) {
            fight.Clear();unit(1,hero,branch,hp);unit(2,23,0,10000);unit(enemy,23,0,10000);
            fight.m_members[0].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.attack=10000;
        };
        auto transfer=[&]() {
            fight.m_members[0].passive_skill={SSkillData(684,1)};
            std::vector<ESkillTriggerType> triggers{ESkill_Trigger_FightBegin_MaxAttackEnemy};
            std::vector<ESkillPassitiveType> kinds{ESkill_Pass_DescAttackAndAddToSelf};
            fight.CalculatePassiveSkill_ExtAttrEffect(1,0,triggers,kinds);
        };
        setup(68,1);fight.CombatEvent("opening_snapshot",1,1,0,0,1,{});
        fight.m_members[0].unitAttr.attack=2000;transfer();metrics["unified_transfer_snapshot"]=fight.m_members[0].unitAttr.attack-2000;
        metrics["unified_transfer_enemy_loss"]=10000-fight.m_members[enemy-1].unitAttr.attack;
        setup(68,1);fight.m_members[0].unitAttr.attack=2000;transfer();metrics["unified_transfer_fallback"]=fight.m_members[0].unitAttr.attack-2000;
        setup(40,2);fight.m_members[0].passive_skill={SSkillData(404,1)};
        std::vector<ESkillTriggerType> action{ESkill_Trigger_Action};std::vector<ESkillPassitiveType> attr{ESkill_Pass_Attr};
        fight.CalculatePassiveSkill_ExtAttrEffect(1,0,action,attr);
        metrics["unified_action_buff"]=fight.GetStatePara1(1,ESBUFF_ShanBiLvAdd);
        metrics["unified_action_duration"]=fight.m_members[0].buff_list.empty()?0:fight.m_members[0].buff_list.back().leftTurn;
        setup(19,1);fight.m_members[0].passive_skill={SSkillData(193,1)};
        auto growthValue=[&](){return fight.CombatPassiveValue(1,enemy,193,1,SingletonCSkillMgr::instance().GetAdditiveEffectCfg(193),ESkill_Trigger_Attacking,ESkill_PassAttr_Damage,100);};
        metrics["unified_growth_before"]=growthValue();
        for(int i=0;i<3;++i) {
            fight.CombatEvent("landed_attack",1,enemy,0,0,1,{{"counter_attack",0}});
            if(i==1)metrics["unified_growth_after_two"]=growthValue();
        }
        metrics["unified_growth_capped"]=growthValue();++fight.m_members[0].combatActionIndex;
        metrics["unified_growth_next_action"]=growthValue();fight.m_combatDepth=1;metrics["unified_growth_secondary"]=growthValue();fight.m_combatDepth=0;
        setup(25,1,1000);int healing=-1001,absorbed=0;fight.DecreaseHp(1,2,healing,absorbed,true);
        metrics["unified_hp_restore"]=fight.GetHp(1)-1000;
        setup(47,2);std::vector<int> linked{1};fight.AddBuff(1,1,ESBUFF_GongTongShengSi,2,&linked);
        int damage=1000;absorbed=0;fight.DecreaseHp(1,enemy,damage,absorbed,true);
        metrics["unified_link_excluded_loss"]=10000-fight.GetHp(1);metrics["unified_link_excluded_ally"]=10000-fight.GetHp(2);
        setup(23,0);unit(3,23,0,5000);fight.m_members[1].hp=2000;fight.AddBuff(1,1,ESBUFF_GongTongShengSi,2,&linked);
        damage=1000;absorbed=0;fight.DecreaseHp(1,enemy,damage,absorbed,true);
        metrics["unified_link_primary"]=10000-fight.GetHp(1);metrics["unified_link_lowest"]=2000-fight.GetHp(2);metrics["unified_link_other"]=5000-fight.GetHp(3);
        setup(23,1);for(int i=0;i<3;++i)fight.CombatEvent("before_guard_damage",1,enemy,0,0,1,{});
        CombatData::Modifiers candidate;candidate.parameters={1};fight.CombatEvent("before_guard_candidate",1,2,0,0,1,{},&candidate);
        metrics["unified_guard_capped"]=candidate.parameters[0];++fight.m_fightTurn;candidate.parameters={1};fight.CombatEvent("before_guard_candidate",1,2,0,0,1,{},&candidate);
        metrics["unified_guard_next_turn"]=candidate.parameters[0];
        setup(34,2,2900);healing=-1000;absorbed=0;fight.DecreaseHp(1,2,healing,absorbed,true);
        auto threshold=[&]() {auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(344);std::vector<int> parameters;fight.GetPassivePara(1,parameters,effect,1);fight.CombatPassiveParameters(1,0,344,effect,1,ESkill_Trigger_DefAdd,parameters);return parameters.at(1);};
        metrics["unified_low_water_memory"]=threshold();++fight.m_fightTurn;metrics["unified_low_water_next"]=threshold();
        setup(23,0);fight.m_fightTurn=1;
        for(uint8 pos:{uint8(1),uint8(2),enemy})fight.m_members[pos-1].unitAttr.attack=1;
        SSkillData waiting(231,1);waiting.leftCD=5;fight.m_members[0].skill_list.push_back(waiting);
        fight.CombatRecordRevive(1,2);
        CNetMessage reviveRound;reviveRound.SetType(0);fight.CalculateFight(reviveRound);
        metrics["unified_revived_action_cd"]=fight.m_members[0].skill_list[0].leftCD;
        metrics["unified_revived_action_present"]=std::find(fight.m_actionList.begin(),fight.m_actionList.end(),1)!=fight.m_actionList.end()?1:0;
        CNetMessage nextRound;nextRound.SetType(0);fight.CalculateFight(nextRound);
        metrics["unified_revived_next_cd"]=fight.m_members[0].skill_list[0].leftCD;
        setup(13,2);fight.InitTeamRageFromAffixes();metrics["unified_opening_branch_rage"]=fight.GetTeamRage(1);
        setup(17,1);fight.m_members[0].notEffectBuff.push_back(ESBUFF_MianShangTemp);fight.InitTeamRageFromAffixes();
        metrics["unified_opening_branch_guard"]=fight.GetStatePara1(1,ESBUFF_MianShangTemp);
        metrics["unified_opening_guard_duration"]=0;metrics["unified_opening_guard_origin"]=0;
        for(const auto& active:fight.m_members[0].buff_list)if(active.id==ESBUFF_MianShangTemp){metrics["unified_opening_guard_duration"]=active.leftTurn;metrics["unified_opening_guard_origin"]=active.originSkill;}
        setup(16,1);std::vector<int> cleanseNegative{1000,0};fight.AddBuff(1,enemy,ESBUFF_JinGuZhou,3,&cleanseNegative,111);
        fight.m_members[0].notEffectBuff.push_back(ESBUFF_ZengShangLvAdd);fight.ClearRandomDeBuff(1,1,1,164);
        metrics["unified_cleanse_success_bonus"]=fight.GetStatePara1(1,ESBUFF_ZengShangLvAdd);
        metrics["unified_cleanse_success_duration"]=0;metrics["unified_cleanse_success_origin"]=0;
        for(const auto& active:fight.m_members[0].buff_list)if(active.id==ESBUFF_ZengShangLvAdd){metrics["unified_cleanse_success_duration"]=active.leftTurn;metrics["unified_cleanse_success_origin"]=active.originSkill;}
        setup(16,1);std::vector<int> cleansePositive{1000};fight.AddBuff(1,1,ESBUFF_AddSpeed,3,&cleansePositive);
        fight.AddBuff(1,enemy,ESBUFF_JinGuZhou,3,&cleanseNegative,111);fight.ClearRandomDeBuff(1,1,1,164);
        metrics["unified_cleanse_mixed_bonus"]=fight.GetStatePara1(1,ESBUFF_ZengShangLvAdd);
        metrics["unified_cleanse_mixed_negative_retained"]=fight.HaveBuff(1,ESBUFF_JinGuZhou)?1:0;
        metrics["unified_cleanse_mixed_positive_retained"]=fight.HaveBuff(1,ESBUFF_AddSpeed)?1:0;
        setup(16,1);fight.AddBuff(1,1,ESBUFF_AddSpeed,3,&cleansePositive);fight.ClearRandomDeBuff(1,1,1,164);
        metrics["unified_cleanse_without_negative_loss"]=fight.GetStatePara1(1,ESBUFF_ZengShangLvAdd);
        setup(37,2);fight.m_members[0].passive_skill.push_back(SSkillData(373,75));
        fight.AddBuff(enemy,1,ESBUFF_FangYuDes,3,&cleanseNegative);fight.AddBuff(enemy,enemy,ESBUFF_AddSpeed,3,&cleansePositive);
        std::srand(1);fight.ClearRandomEnBuff(enemy,1,1);
        metrics["unified_dispel_negative_retained"]=fight.HaveBuff(enemy,ESBUFF_FangYuDes)?1:0;metrics["unified_dispel_positive_retained"]=fight.HaveBuff(enemy,ESBUFF_AddSpeed)?1:0;
        metrics["unified_dispel_copied_positive"]=fight.GetStatePara1(1,ESBUFF_AddSpeed);
        setup(37,1);fight.m_curActionPos=1;fight.m_members[0].passive_skill.push_back(SSkillData(373,75));
        fight.AddBuff(enemy,1,ESBUFF_FangYuDes,3,&cleanseNegative);fight.AddBuff(enemy,enemy,ESBUFF_AddSpeed,3,&cleansePositive);
        std::srand(1);fight.ClearRandomEnBuff(enemy,1,1);
        auto copyDuration=[&]() {for(const auto& active:fight.m_members[0].buff_list)if(active.id==ESBUFF_AddSpeed)return static_cast<int>(active.leftTurn);return 0;};
        metrics["unified_copy_buff_initial"]=copyDuration();fight.DecAllStateEffectTurn(1);metrics["unified_copy_buff_same_action"]=copyDuration();
        ++fight.m_fightTurn;fight.DecAllStateEffectTurn(1);metrics["unified_copy_buff_next_action"]=copyDuration();
        setup(23,2);fight.m_members[0].unitAttr.fanzhenLv=10000;fight.m_members[0].unitAttr.fanzhenAdd=2500;
        std::vector<SAttrData> thornsAttributes;metrics["unified_thorns_without_buff"]=fight.CalculateFanShang(enemy,1,1001,thornsAttributes);
        fight.m_members[0].unitAttr.fanzhenAdd=0;std::vector<int> thornsParameters{0,2500};fight.AddBuff(1,1,ESBUFF_FanZhengAllAdd,3,&thornsParameters,232);
        metrics["unified_thorns_with_buff"]=fight.CalculateFanShang(enemy,1,1001,thornsAttributes);
        std::vector<int> mitigation{1000};fight.AddBuff(1,1,ESBUFF_JianShangLvAdd,3,&mitigation);
        CombatData::Modifiers thornsChance;fight.CombatEvent("before_thorns_roll",1,enemy,0,0,1,{},&thornsChance);
        metrics["unified_thorns_guard_chance"]=thornsChance.amountBonus;
        setup(22,2);fight.m_fightTurn=1;fight.m_curActionPos=enemy;
        fight.m_members[0].passive_skill.push_back(SSkillData(223,75));
        fight.m_members[1].unitAttr.attack=1;fight.m_members[enemy-1].unitAttr.attack=1;metrics["unified_round_begin_buff_action"]=999;metrics["unified_round_begin_buff_initial_duration"]=0;metrics["unified_round_begin_buff_duration"]=0;
        fight.m_combatObserver=[&](uint8,const char* kind,int origin,int buff) {
            if(std::string(kind)=="buff_applied" && origin==223 && buff==3)
                for(const auto& active:fight.m_members[enemy-1].buff_list)if(active.id==3 && active.originSkill==223){metrics["unified_round_begin_buff_action"]=active.appliedDuringRound;metrics["unified_round_begin_buff_initial_duration"]=active.leftTurn;}
        };
        std::srand(1);CNetMessage openingRound;openingRound.SetType(0);fight.CalculateFight(openingRound);fight.m_combatObserver={};
        metrics["unified_round_begin_target_alive"]=fight.IsAlive(enemy)?1:0;
        for(const auto& active:fight.m_members[enemy-1].buff_list)if(active.id==3 && active.originSkill==223)metrics["unified_round_begin_buff_duration"]=active.leftTurn;
        auto passivePlan=[&](int skill,int effect,int trigger) {CombatData::Modifiers plan;plan.parameters={0,-1,0,1};fight.CombatEvent("after_passive_targets",1,1,skill,0,1,{{"passive_trigger",trigger},{"passive_effect",effect}},&plan);return plan.parameters;};
        setup(22,1);auto firstPlan=passivePlan(223,223,ESkill_Trigger_TurnBegin);metrics["unified_passive_target_mode"]=firstPlan[0];metrics["unified_passive_target_excluded"]=firstPlan[2];metrics["unified_passive_target_first"]=firstPlan[3];
        metrics["unified_passive_target_repeat"]=passivePlan(223,223,ESkill_Trigger_TurnBegin)[3];++fight.m_fightTurn;metrics["unified_passive_target_next"]=passivePlan(223,223,ESkill_Trigger_TurnBegin)[3];
        setup(66,1);metrics["unified_passive_target_highest"]=passivePlan(663,663,0)[0];
        setup(45,1);metrics["unified_passive_target_cap_two"]=passivePlan(453,455,0)[1];
        setup(26,2);metrics["unified_passive_target_cap_three"]=passivePlan(262,262,0)[1];
        setup(67,1);metrics["unified_passive_target_once_first"]=passivePlan(674,674,0)[3];metrics["unified_passive_target_once_repeat"]=passivePlan(674,674,0)[3];
        ++fight.m_fightTurn;metrics["unified_passive_target_once_later"]=passivePlan(674,674,0)[3];
        ++fight.m_members[0].combatActionIndex;metrics["unified_passive_target_once_next_action"]=passivePlan(674,674,0)[3];
        setup(34,2);fight.m_curActionPos=1;fight.m_members[0].skill_list.push_back(SSkillData(342,10));
        fight.CalculateSkill_AddBuff(1,342,10);
        auto activeDuration=[&]() {for(const auto& active:fight.m_members[0].buff_list)if(active.originSkill==342 && active.id==ESBUFF_Shield)return static_cast<int>(active.leftTurn);return 0;};
        metrics["unified_active_buff_initial"]=activeDuration();fight.DecAllStateEffectTurn(1);metrics["unified_active_buff_same_action"]=activeDuration();
        ++fight.m_fightTurn;fight.DecAllStateEffectTurn(1);metrics["unified_active_buff_next_action"]=activeDuration();
        setup(34,1);unit(3,23,0,5000);fight.m_curActionPos=1;fight.m_members[0].skill_list.push_back(SSkillData(342,10));
        fight.m_members[2].notEffectBuff.push_back(ESBUFF_Shield);fight.CalculateSkill_AddBuff(1,342,10);
        metrics["unified_shield_branch_self"]=fight.GetStatePara1(1,ESBUFF_Shield);metrics["unified_shield_branch_lowest"]=fight.GetStatePara1(3,ESBUFF_Shield);metrics["unified_shield_branch_other"]=fight.GetStatePara1(2,ESBUFF_Shield);
        setup(36,1);std::vector<int> inheritedShield{1000,1000};fight.AddBuff(1,1,ESBUFF_Shield,2,&inheritedShield,122);
        metrics["unified_shield_branch_origin"]=fight.GetStatePara1(1,ESBUFF_Shield);
        setup(23,0);fight.m_members[0].unitAttr.attack=2200;fight.m_members[0].attackType=1;
        fight.m_members[enemy-1].unitAttr.wufang=fight.m_members[enemy-1].unitAttr.fafang=400;
        std::vector<int> preciseBonus{8400};fight.AddBuff(1,1,ESBUFF_ZengShangLvAdd,2,&preciseBonus);
        std::vector<SAttrData> preciseSource,preciseTarget;
        metrics["unified_direct_bonus_precision"]=fight.CalculateDamage(1,enemy,preciseSource,preciseTarget);
        fight.ClearBuff(1,ESBUFF_ZengShangLvAdd);std::vector<int> vulnerabilityAll{6000},vulnerabilityPhysical{2000};
        fight.AddBuff(enemy,1,ESBUFF_GetDamageAdd,2,&vulnerabilityAll);fight.AddBuff(enemy,1,ESBUFF_GetWuDamageAdd,2,&vulnerabilityPhysical);
        metrics["unified_vulnerability_cap_damage"]=fight.CalculateDamage(1,enemy,preciseSource,preciseTarget);
        setup(43,2);auto linkedFollowup=[&]() {CombatData::Modifiers plan;plan.parameters={1,10000,0,0};fight.CombatEvent("before_kill_followup",1,enemy,431,0,1,{{"action_kind",1}},&plan);return plan.parameters[1];};
        metrics["unified_team_hero_absent"]=linkedFollowup();unit(3,44,0,10000);metrics["unified_team_hero_present"]=linkedFollowup();
        fight.SetState(3,EFST_STATE_Die);metrics["unified_team_hero_dead"]=linkedFollowup();
        setup(10,1);unit(2,10,1,10000);
        fight.m_members[0].passive_skill.push_back(SSkillData(104,75));fight.m_members[1].passive_skill.push_back(SSkillData(104,75));
        fight.m_members[0].hp=fight.m_members[1].hp=0;fight.SetState(1,EFST_STATE_Die);fight.SetState(2,EFST_STATE_Die);fight.AddDieUnit(1);fight.AddDieUnit(2);
        std::srand(1);CNetMessage deathRound;deathRound.SetType(0);fight.DiePassiveAcion(deathRound);
        metrics["unified_death_index_first_alive"]=fight.IsAlive(1)?1:0;metrics["unified_death_index_shifted_alive"]=fight.IsAlive(2)?1:0;
        setup(47,2);
        auto& deltaMember=fight.m_members[0];
        deltaMember.unitAttr.attack=deltaMember.unitAttr.attackBase=1500;
        deltaMember.unitAttr.wufang=deltaMember.unitAttr.wufangBase=400;
        deltaMember.unitAttr.fafang=deltaMember.unitAttr.fafangBase=400;
        deltaMember.unitAttr.maxHp=deltaMember.unitAttr.maxHpBase=40000;deltaMember.hp=40000;
        deltaMember.unitAttr.attackRatio=deltaMember.unitAttr.wufangRatio=deltaMember.unitAttr.fafangRatio=deltaMember.unitAttr.maxHpRatio=10000;
        auto deltaPet=boost::any_cast<SharePetPtr>(deltaMember.memPtr);deltaPet->basicAttr=deltaMember.unitAttr;deltaPet->hp=40000;
        deltaPet->skill[0]=473;deltaPet->skill[1]=474;deltaPet->skillLevel[0]=deltaPet->skillLevel[1]=10;
        fight.SetUnitBasicData(1);metrics["unified_delta_initialized_defense"]=fight.GetUnitFangYu(1,1);
        auto teamAura=[&](int level) {
            deltaMember.passive_skill={SSkillData(474,level)};
            std::vector<ESkillTriggerType> trigger{ESkill_Trigger_FightBeginAddToAllUnit};
            fight.CalculatePassiveSkill_ExtAttrEffect(1,0,trigger,attr);
        };
        teamAura(10);metrics["unified_aura_first"]=deltaMember.unitAttr.wumianLv;
        teamAura(75);teamAura(10);metrics["unified_aura_strongest"]=deltaMember.unitAttr.wumianLv;
        metrics["unified_delta_aura_defense"]=fight.GetUnitFangYu(1,1);
        deltaMember.AddPassSkillLimitAttrData(900,ESkill_Pass_Attr,EAT_AttackAdd,1000,1,2);
        deltaMember.AddPassSkillLimitAttrData(901,ESkill_Pass_Attr,EAT_BaoJiLv,1000,1,2);
        metrics["unified_delta_preserved_attack"]=fight.GetUnitAttack(1);
        metrics["unified_delta_preserved_defense"]=fight.GetUnitFangYu(1,1);
        deltaMember.DecPassSkillLimitAttrData(900,ESkill_Pass_Attr,EAT_AttackAdd,1000,1);
        metrics["unified_delta_removed_attack"]=fight.GetUnitAttack(1);
        deltaMember.SetPassSkillLimitAttrData(902,ESkill_Pass_Attr,EAT_QiXueAdd,-2500,1);
        metrics["unified_delta_hp_clamp"]=fight.GetHp(1);
        setup(53,1);fight.m_members[0].unitAttr.attack=1501;
        std::vector<int> convertedPoison{1000,3000};fight.AddBuff(enemy,1,ESBUFF_FuDu,2,&convertedPoison,531);
        metrics["unified_stored_buff_type"]=fight.m_members[enemy-1].buff_list.back().id;
        metrics["unified_stored_buff_amount"]=fight.m_members[enemy-1].buff_list.back().paraList[0];
        metrics["unified_stored_buff_tail"]=fight.m_members[enemy-1].buff_list.back().paraList[1];
        metrics["unified_stored_buff_duration"]=fight.m_members[enemy-1].buff_list.back().leftTurn;
        metrics["unified_stored_buff_origin"]=fight.m_members[enemy-1].buff_list.back().originSkill;
        setup(53,2);fight.AddBuff(enemy,1,ESBUFF_FuDu,2,&convertedPoison,531);
        metrics["unified_stored_buff_other_branch"]=fight.m_members[enemy-1].buff_list.back().id;
        setup(53,1);fight.AddBuff(enemy,1,ESBUFF_FuDu,2,&convertedPoison);
        metrics["unified_stored_buff_other_origin"]=fight.m_members[enemy-1].buff_list.back().id;
        setup(60,2);fight.m_members[0].passive_skill={SSkillData(603,10),SSkillData(604,10)};
        CombatData::Modifiers openingPlan;fight.CombatEvent("before_opening_action",1,1,0,0,1,{},&openingPlan);
        metrics["unified_opening_action_plan"]=openingPlan.amount;
        if(openingPlan.amount)fight.CombatEvent("action_start",1,1,0,0,1,{});
        metrics["unified_opening_action_defense"]=fight.GetStatePara1(enemy,ESBUFF_WuFangDes);
        metrics["unified_opening_action_weakness"]=fight.GetStatePara1(enemy,ESBUFF_DamagePercentDes);
        setup(23,0);CombatData::Modifiers noOpeningPlan;fight.CombatEvent("before_opening_action",1,1,0,0,1,{},&noOpeningPlan);
        metrics["unified_opening_action_other"]=noOpeningPlan.amount;
        setup(67,1);fight.m_members[0].unitAttr.attack=1501;fight.CalculateSkill_AddBuff(1,671,10);
        metrics["unified_active_hot_self"]=fight.GetStatePara1(1,ESBUFF_AddHpContinue);
        metrics["unified_active_hot_ally"]=fight.GetStatePara1(2,ESBUFF_AddHpContinue);
        setup(67,2);fight.m_members[0].unitAttr.attack=1501;fight.CalculateSkill_AddBuff(1,671,10);
        metrics["unified_active_hot_other_branch"]=fight.GetStatePara1(1,ESBUFF_AddHpContinue);
        setup(11,2);fight.m_members[0].passive_skill={SSkillData(113,1)};
        std::vector<int> timerAntiheal{2000,20000};fight.AddBuff(enemy,1,ESBUFF_JinLiaoShu,2,&timerAntiheal);
        auto timerTick=[&](){std::srand(1);auto active=fight.m_members[enemy-1].buff_list.front();return fight.CombatPeriodicValue(1,enemy,active,100,200);};
        metrics["unified_periodic_first_damage"]=timerTick();metrics["unified_periodic_unapplied_slow"]=fight.GetStatePara1(enemy,ESBUFF_SpeedDes);
        metrics["unified_periodic_first_extension"]=fight.m_members[enemy-1].buff_list.front().leftTurn;
        timerTick();++fight.m_fightTurn;timerTick();metrics["unified_periodic_extension_gap"]=fight.m_members[enemy-1].buff_list.front().leftTurn;
        ++fight.m_fightTurn;timerTick();metrics["unified_periodic_next_extension"]=fight.m_members[enemy-1].buff_list.front().leftTurn;
        fight.CombatEvent("buff_attempt_applied",1,enemy,112,ESBUFF_JinLiaoShu,1,{});timerTick();
        metrics["unified_periodic_applied_slow"]=fight.GetStatePara1(enemy,ESBUFF_SpeedDes);
        setup(14,1);metrics["unified_useful_no_shield"]=fight.IsRoleSkillUseful(1,142);
        std::vector<int> usefulShield{1000,1000};fight.AddBuff(enemy,enemy,ESBUFF_Shield,2,&usefulShield);
        metrics["unified_useful_live_shield"]=fight.IsRoleSkillUseful(1,142);fight.SetState(enemy,EFST_STATE_Die);
        metrics["unified_useful_dead_shield"]=fight.IsRoleSkillUseful(1,142);
        setup(14,0);metrics["unified_useful_unselected"]=fight.IsRoleSkillUseful(1,142);
        setup(11,1);metrics["unified_useful_one_enemy"]=fight.IsRoleSkillUseful(1,111);
        fight.m_members[enemy-1].isWorldBoss=true;metrics["unified_useful_unmarked_boss"]=fight.IsRoleSkillUseful(1,111);
        std::vector<int> usefulMark{1000,100};fight.AddBuff(enemy,1,ESBUFF_JinGuZhou,2,&usefulMark);
        metrics["unified_useful_marked_boss"]=fight.IsRoleSkillUseful(1,111);unit(enemy+1,23,0,10000);
        metrics["unified_useful_two_enemies"]=fight.IsRoleSkillUseful(1,111);
        setup(13,2);unit(enemy+1,23,0,10000);unit(enemy+2,23,0,10000);
        metrics["unified_useful_three_susceptible"]=fight.IsRoleSkillUseful(1,131);
        fight.m_members[enemy-1].notEffectBuff.push_back(ESBUFF_ChenMo);
        metrics["unified_useful_two_susceptible"]=fight.IsRoleSkillUseful(1,131);
        fight.m_members[enemy].isWorldBoss=true;metrics["unified_useful_susceptible_boss"]=fight.IsRoleSkillUseful(1,131);
        fight.m_members[enemy].notEffectBuff.push_back(ESBUFF_ChenMo);
        fight.AddBuff(enemy+2,1,ESBUFF_ChenMo,2,&usefulMark);
        metrics["unified_useful_immune_marked"]=fight.IsRoleSkillUseful(1,131);
        setup(17,2);fight.m_curActionPos=1;fight.CalculateSkill_AddBuff(1,171,10);
        metrics["unified_active_duration_override"]=fight.m_members[0].buff_list.back().leftTurn;
        fight.DecAllStateEffectTurn(1);metrics["unified_active_duration_same_action"]=fight.m_members[0].buff_list.back().leftTurn;
        ++fight.m_fightTurn;fight.DecAllStateEffectTurn(1);metrics["unified_active_duration_expired"]=fight.HaveBuff(1,ESBUFF_WuMianAndGetFaDamageAdd)?0:1;
        setup(17,1);fight.CalculateSkill_AddBuff(1,171,10);metrics["unified_active_duration_other_branch"]=fight.m_members[0].buff_list.back().leftTurn;
        metrics["unified_active_parameter_reduction"]=fight.GetStatePara1(1,ESBUFF_WuMianAndGetFaDamageAdd);
        setup(17,1);fight.CalculateSkill_AddBuff(1,171,20);metrics["unified_active_parameter_floor"]=fight.GetStatePara1(1,ESBUFF_WuMianAndGetFaDamageAdd);
        setup(17,1);fight.CalculateSkill_AddBuff(1,171,75);metrics["unified_active_parameter_absent"]=fight.m_members[0].buff_list.back().paraList.empty()?1:0;
        setup(12,2);std::vector<int> accumulatorShield{1000,1000};
        auto expirePersonal=[&](){fight.AddBuff(2,1,ESBUFF_Shield,1,&accumulatorShield,121);const auto before=fight.GetHp(enemy);fight.DecAllStateEffectTurn(2);return before-fight.GetHp(enemy);};
        metrics["unified_event_bonus_first"]=expirePersonal();expirePersonal();metrics["unified_event_bonus_empty_third"]=expirePersonal();
        auto breakRestoration=[&](int depth=0){setup(34,2,5000);fight.CalculateSkill_AddBuff(1,342,10);fight.m_combatDepth=depth;int pressure=100000,absorbed=0;fight.ShieldAbsorptionDamage(1,pressure,absorbed);fight.ShieldBrokenCheck(1,enemy);fight.m_combatDepth=0;return fight.GetHp(1)-5000;};
        metrics["unified_break_restore"]=breakRestoration();metrics["unified_break_restore_secondary"]=breakRestoration(1);
        setup(34,2,5000);fight.CalculateSkill_AddBuff(1,342,10);auto restoredShield=fight.m_members[0].buff_list.back();
        metrics["unified_break_restore_legacy"]=fight.CombatShieldAllowsLegacy(1,restoredShield,false)?1:0;
        fight.DecAllStateEffectTurn(1);fight.DecAllStateEffectTurn(1);metrics["unified_break_restore_expiry"]=fight.GetHp(1)-5000;
        setup(34,2,5000);fight.CalculateSkill_AddBuff(1,342,10);fight.ClearRandomEnBuff(1,1,enemy);metrics["unified_break_restore_dispel"]=fight.GetHp(1)-5000;
        setup(34,2,5000);std::vector<int> reducedHeal{5000,0};fight.AddBuff(1,enemy,ESBUFF_JinLiaoShu,2,&reducedHeal);
        fight.CalculateSkill_AddBuff(1,342,10);int breakPressure=100000,breakAbsorbed=0;fight.ShieldAbsorptionDamage(1,breakPressure,breakAbsorbed);fight.ShieldBrokenCheck(1,enemy);
        metrics["unified_break_restore_antiheal"]=fight.GetHp(1)-5000;
        setup(23,0);auto& criticalMember=fight.m_members[0];
        criticalMember.unitAttr.baojiAdd=1000;metrics["unified_critical_minimum"]=fight.GetBaoJiDamage(1,1000,0);
        criticalMember.unitAttr.baojiAdd=100000;metrics["unified_critical_maximum"]=fight.GetBaoJiDamage(1,1000,0);
        metrics["unified_critical_overflow_high"]=fight.GetBaoJiDamage(1,std::numeric_limits<int>::max(),0);
        metrics["unified_critical_overflow_low"]=fight.GetBaoJiDamage(1,std::numeric_limits<int>::min(),0);
        criticalMember.unitAttr.baojiAdd=22000;metrics["unified_critical_interior"]=fight.GetBaoJiDamage(1,1000,0);
        criticalMember.unitAttr.baojiLv=20000;
        int criticalSeed=-1;for(int seed=0;seed<1000;++seed){std::srand(seed);const int roll=Random(1,10000);if(roll>8000 && roll<=9000){criticalSeed=seed;metrics["unified_critical_test_roll"]=roll;break;}}
        if(criticalSeed<0)throw std::runtime_error("missing critical probability boundary seed");
        std::srand(criticalSeed);Random(1,10000);const int afterCriticalRandom=std::rand();
        std::srand(criticalSeed);int criticalDamage=1000;std::vector<SAttrData> criticalAttributes;
        metrics["unified_critical_attack_cap"]=fight.CalculateBaoJiRatio(1,enemy,criticalDamage,criticalAttributes)?1:0;
        metrics["unified_critical_attack_damage"]=criticalDamage;metrics["unified_critical_rng"]=std::rand()==afterCriticalRandom?1:0;
        std::srand(criticalSeed);metrics["unified_critical_heal_cap"]=fight.CalculateBaoJiRatio_AddHp(1,criticalAttributes)?1:0;
        auto tauntSetup=[&](int hp=1000){setup(34,1,hp);for(uint8 offset=0;offset<5;++offset){unit(enemy+offset,23,0,100000);fight.m_members[enemy+offset-1].unitAttr.maxHp=100000;}std::srand(1729);};
        // Isolate the public storage/ownership/budget path. The real341 chance
        // is40%, so full-skill rolls cannot guarantee five successful writes.
        auto tauntCast=[&](){const auto before=fight.GetHp(1);std::vector<int> tauntParameters{1};
            for(uint8 offset=0;offset<5;++offset){const uint8 target=enemy+offset;fight.AddBuff(target,1,ESBUFF_ChaoFeng,2,&tauntParameters,341,10);
                fight.CombatEvent("buff_attempt_applied",1,target,341,ESBUFF_ChaoFeng,10,{{"event_buff_owned",fight.GetStateSrcPos(target,ESBUFF_ChaoFeng)==1?1:0},{"event_duration",2}},nullptr,&tauntParameters);}
            return fight.GetHp(1)-before;};
        tauntSetup();metrics["unified_owned_taunt_first"]=tauntCast();metrics["unified_owned_taunt_repeat"]=tauntCast();
        ++fight.m_members[0].combatActionIndex;metrics["unified_owned_taunt_next"]=tauntCast();
        tauntSetup(5000);std::vector<int> tauntAntiheal{5000,0};fight.AddBuff(1,enemy,ESBUFF_JinLiaoShu,2,&tauntAntiheal);
        metrics["unified_owned_taunt_antiheal"]=tauntCast();
        tauntSetup();for(uint8 offset=0;offset<5;++offset)fight.m_members[enemy+offset-1].isWorldBoss=true;
        metrics["unified_owned_taunt_boss_replacement"]=tauntCast();
        tauntSetup(10000);tauntCast();fight.m_members[0].hp=5000;metrics["unified_owned_taunt_full_hp_budget"]=tauntCast();
        auto counterPresenceSetup=[&](int presence){setup(44,2);unit(2,presence?43:23,0,presence==2?0:10000);if(presence==2)fight.SetState(2,EFST_STATE_Die);
            auto& defender=fight.m_members[0];defender.unitAttr.attack=1000;defender.unitAttr.mingzhongLv=10000;defender.unitAttr.fanjiAdd=10000;defender.unitAttr.fanjiLv=0;
            fight.m_members[enemy-1].hp=100000;fight.m_members[enemy-1].unitAttr.maxHp=100000;fight.m_members[enemy-1].unitAttr.attack=1000;fight.m_members[enemy-1].unitAttr.mingzhongLv=10000;};
        auto counterPresencePlan=[&](int presence){counterPresenceSetup(presence);CombatData::Modifiers plan;plan.parameters={-1,0,0,0};
            fight.CombatEvent("before_counter",1,enemy,0,0,1,{},&plan);return plan.parameters[3];};
        metrics["unified_counter_presence_absent"]=counterPresencePlan(0);metrics["unified_counter_presence_live"]=counterPresencePlan(1);metrics["unified_counter_presence_dead"]=counterPresencePlan(2);
        auto counterPresenceAttack=[&](int presence,int seed){counterPresenceSetup(presence);std::srand(seed);int self=0;
            fight.CalculateOnceAction(enemy,1,0,1,self,true);return 100000-static_cast<int>(fight.GetHp(enemy));};
        int presenceSeed=0;bool presenceCounter=false;for(int seed=0;seed<100;++seed)if(counterPresenceAttack(1,seed)>0){presenceSeed=seed;presenceCounter=true;break;}
        metrics["unified_counter_presence_consumed"]=presenceCounter?1:0;metrics["unified_counter_absent_damage"]=counterPresenceAttack(0,presenceSeed);metrics["unified_counter_dead_damage"]=counterPresenceAttack(2,presenceSeed);
        auto sacrificeCast=[&](int hp,int branch=2){setup(42,branch,hp);std::vector<SAttrData> own,other;int cost=0;
            const int damage=fight.CalculateSkillDamage(1,enemy,422,10,cost,own,other);metrics["unified_sacrifice_last_damage"]=damage;return cost;};
        metrics["unified_sacrifice_normal_cost"]=sacrificeCast(10000);metrics["unified_sacrifice_normal_damage"]=metrics["unified_sacrifice_last_damage"];
        metrics["unified_sacrifice_low_cost"]=sacrificeCast(100);metrics["unified_sacrifice_one_hp_cost"]=sacrificeCast(1);
        metrics["unified_sacrifice_other_cost"]=sacrificeCast(10000,1);
        setup(42,2);CombatData::Modifiers sacrificePlan;sacrificePlan.parameters={2000,10000,10000};fight.CombatEvent("before_sacrifice_damage",1,1,422,0,10,{},&sacrificePlan);
        metrics["unified_sacrifice_multiplier"]=sacrificePlan.parameters[2];
        auto reviveUsefulnessSetup=[&](int hero,int skill){setup(hero,1);fight.m_members[0].skill_list.push_back(SSkillData(skill,75));
            for(uint8 pos=2;pos<=4;++pos){unit(pos,23,0,0);fight.SetState(pos,EFST_STATE_Die);}};
        reviveUsefulnessSetup(35,352);uint8 reviveTargets[GROUP_MEMBER],reviveCount=0;std::srand(1729);fight.GetSkillTargetRange(1,352,75,reviveTargets,reviveCount);const int afterReviveSelection=std::rand();
        std::srand(1729);metrics["unified_revive_usefulness_live"]=fight.IsRoleSkillUseful(1,352)?1:0;metrics["unified_revive_usefulness_rng"]=std::rand()==afterReviveSelection?1:0;
        fight.m_members[0].combatStrategy=2;fight.m_members[0].skill_list.push_back(SSkillData(351,75));fight.m_members[0].skill_list.back().leftCD=5;fight.AddTeamRage(1,100,false);
        std::srand(1729);metrics["unified_revive_strategy_normal"]=fight.GetUnitAISkillId(1);metrics["unified_revive_strategy_rng"]=std::rand()==afterReviveSelection?1:0;
        reviveUsefulnessSetup(10,102);std::srand(1729);const int beforeEligibilityRandom=std::rand();std::srand(1729);
        metrics["unified_revive_scan_useful"]=fight.IsRoleSkillUseful(1,102)?1:0;metrics["unified_revive_scan_rng"]=std::rand()==beforeEligibilityRandom?1:0;
        CombatData::Modifiers reviveRoute;reviveRoute.parameters={1,0};fight.CombatEvent("before_skill_usefulness",1,1,102,0,75,{},&reviveRoute);metrics["unified_revive_scan_mode"]=reviveRoute.parameters[1];
        auto activeLink=[&](int branch){setup(47,branch);for(uint8 offset=0;offset<3;++offset)unit(enemy+offset,23,0,100000);std::srand(1729);
            fight.CalculateSkill_DamageHp(1,471,10);return fight.HaveBuff(1,51)?1:0;};
        metrics["unified_disabled_active_link"]=activeLink(2);metrics["unified_disabled_active_reduction"]=fight.HaveBuff(1,14)?1:0;
        metrics["unified_active_link_other_branch"]=activeLink(1);
        setup(46,1);fight.m_members[0].unitAttr.mingzhongLv=10000;for(uint8 offset=0;offset<3;++offset){unit(enemy+offset,23,0,100000);fight.m_members[enemy+offset-1].unitAttr.maxHp=100000;}
        std::srand(1729);fight.CalculateSkill_DamageHp(1,462,10);int weaponCount=0,weaponMin=1000000,weaponMax=0,weaponDuration=255;
        for(uint8 offset=0;offset<3;++offset)for(const auto& buff:fight.m_members[enemy+offset-1].buff_list)if(buff.originSkill==462 && !buff.paraList.empty()){
            ++weaponCount;weaponMin=std::min(weaponMin,buff.paraList[0]);weaponMax=std::max(weaponMax,buff.paraList[0]);weaponDuration=std::min(weaponDuration,static_cast<int>(buff.leftTurn));}
        metrics["unified_weapon_scope_count"]=weaponCount;metrics["unified_weapon_scope_min"]=weaponMin;metrics["unified_weapon_scope_max"]=weaponMax;metrics["unified_weapon_scope_duration"]=weaponDuration;
        auto highHpCritical=[&](int hp,int branch=1){setup(56,branch);fight.m_members[enemy-1].hp=hp;CombatData::Modifiers plan;plan.parameters={1,0};
            fight.CombatEvent("before_critical",1,enemy,561,0,10,{},&plan);return std::make_pair(plan.parameters[1],static_cast<int>(plan.amountBonus));};
        auto highCritical=highHpCritical(7001);metrics["unified_high_hp_critical_chance"]=highCritical.first;metrics["unified_high_hp_critical_damage"]=highCritical.second;
        auto boundaryCritical=highHpCritical(7000);metrics["unified_boundary_critical_chance"]=boundaryCritical.first;metrics["unified_boundary_critical_damage"]=boundaryCritical.second;
        auto otherCritical=highHpCritical(10000,2);metrics["unified_other_critical_chance"]=otherCritical.first;metrics["unified_other_critical_damage"]=otherCritical.second;
        auto criticalConsumerSetup=[&](){setup(56,1);fight.m_members[0].attackType=2;fight.m_members[0].unitAttr.mingzhongLv=10000;
            fight.m_members[0].unitAttr.baojiLv=20000;fight.m_members[0].unitAttr.baojiAdd=15000;fight.m_members[enemy-1].hp=100000;fight.m_members[enemy-1].unitAttr.maxHp=100000;};
        criticalConsumerSetup();std::vector<SAttrData> criticalOwn,criticalOther;int criticalSelf=0;
        const int highHpRawDamage=fight.CalculateSkillDamage(1,enemy,561,10,criticalSelf,criticalOwn,criticalOther);
        const int expectedHighHpCritical=fight.GetBaoJiDamage(1,highHpRawDamage,highCritical.second);bool criticalConsumerMatched=false;
        for(int seed=0;seed<100 && !criticalConsumerMatched;++seed){criticalConsumerSetup();std::srand(seed);criticalOwn.clear();criticalOther.clear();
            fight.BasicFightAction(1,enemy,561,10,criticalSelf,criticalOwn,criticalOther,false,true);criticalConsumerMatched=100000-static_cast<int>(fight.GetHp(enemy))==expectedHighHpCritical;}
        metrics["unified_high_hp_critical_consumer"]=criticalConsumerMatched?1:0;
        auto zeroBacklash=[&](int firstParameter){setup(11,2);std::vector<int> parameters{firstParameter,1000};fight.AddBuff(2,1,ESBUFF_JinLiaoShu,2,&parameters,112,1);
            CNetMessage packet;const int before=fight.GetHp(2);const int events=fight.CombatPeriodicActions(2,EFStep_CureHp,packet,1000);
            metrics["unified_zero_backlash_last_hp_loss"]=before-fight.GetHp(2);metrics["unified_zero_backlash_last_bytes"]=packet.GetDataLen();return events;};
        metrics["unified_zero_backlash_events"]=zeroBacklash(5000);metrics["unified_zero_backlash_hp_loss"]=metrics["unified_zero_backlash_last_hp_loss"];
        metrics["unified_zero_backlash_bytes"]=metrics["unified_zero_backlash_last_bytes"];metrics["unified_zero_first_parameter_events"]=zeroBacklash(0);
        setup(23,0);std::vector<int> zeroHot{0};fight.AddBuff(1,enemy,ESBUFF_AddHpContinue,2,&zeroHot);CNetMessage zeroHotMessage;
        metrics["unified_zero_periodic_default_events"]=fight.CombatPeriodicActions(1,EFStep_UserActBegin,zeroHotMessage,0);
        auto refundSetup=[&](int branch=2,bool immune=false){setup(11,branch);fight.m_members[0].unitAttr.mingzhongLv=10000;
            for(uint8 offset=0;offset<3;++offset){unit(enemy+offset,23,0,100000);fight.m_members[enemy+offset-1].unitAttr.maxHp=100000;
                fight.m_members[enemy+offset-1].unitAttr.fumianKangAdd=100000;if(immune)fight.m_members[enemy+offset-1].notEffectBuff.push_back(ESBUFF_JinLiaoShu);}std::srand(1729);};
        auto refundCast=[&](){fight.CalculateSkill_DamageHp(1,112,10);return fight.GetTeamRage(1);};
        refundSetup();metrics["unified_resist_refund_first"]=refundCast();metrics["unified_resist_refund_repeat"]=refundCast();++fight.m_fightTurn;metrics["unified_resist_refund_next"]=refundCast();
        refundSetup(2,true);metrics["unified_resist_refund_immune"]=refundCast();refundSetup(1);metrics["unified_resist_refund_other_branch"]=refundCast();
        refundSetup();fight.AddTeamRage(1,100,false);refundCast();fight.AddTeamRage(1,-40,false);metrics["unified_resist_refund_full_budget"]=refundCast();
        auto aggregatedBacklash=[&](int variant,int seed){setup(11,2);fight.m_members[0].passive_skill.push_back(SSkillData(113,1));
            fight.m_members[1].hp=100000;fight.m_members[1].unitAttr.maxHp=100000;std::vector<int> first{2000,24500},second{5000,24500};
            fight.AddBuff(2,variant==3?enemy:1,ESBUFF_JinLiaoShu,2,&first,0,1);
            if(variant)fight.AddBuff(2,variant==2?enemy:1,ESBUFF_JinLiaoShu,4,&second,112,1);
            std::srand(seed);CNetMessage packet;const int events=fight.CombatPeriodicActions(2,EFStep_CureHp,packet,1000);
            return std::make_tuple(events,100000-static_cast<int>(fight.GetHp(2)),std::rand());};
        int aggregateSeed=0;auto aggregateBase=aggregatedBacklash(0,0);
        for(int seed=1;seed<100 && std::get<1>(aggregateBase)<=0;++seed){aggregateSeed=seed;aggregateBase=aggregatedBacklash(0,seed);}
        auto aggregateDuplicate=aggregatedBacklash(1,aggregateSeed),aggregateOther=aggregatedBacklash(2,aggregateSeed),aggregateReverse=aggregatedBacklash(3,aggregateSeed);
        metrics["unified_state_aggregate_base_damage"]=std::get<1>(aggregateBase);metrics["unified_state_aggregate_duplicate_hp_match"]=std::get<1>(aggregateDuplicate)==std::get<1>(aggregateBase)?1:0;
        metrics["unified_state_aggregate_duplicate_rng_match"]=std::get<2>(aggregateDuplicate)==std::get<2>(aggregateBase)?1:0;metrics["unified_state_aggregate_other_sources_events"]=std::get<0>(aggregateOther);
        metrics["unified_state_aggregate_other_sources_hp_match"]=std::get<1>(aggregateOther)==std::get<1>(aggregateBase)?1:0;metrics["unified_state_aggregate_reverse_damage"]=std::get<1>(aggregateReverse);
        auto emergencySetup=[&](int hp=3000,int strategy=1,int cooldown=0){setup(10,1);for(uint8 pos=2;pos<=5;++pos)unit(pos,23,0,pos==2?hp:10000);
            auto& healer=fight.m_members[0];healer.combatStrategy=strategy;healer.skill_list={SSkillData(101,10),SSkillData(102,10)};healer.skill_list[0].leftCD=cooldown;
            fight.AddTeamRage(1,100,false);std::srand(1729);};
        emergencySetup();metrics["unified_emergency_regular_plain_usefulness"]=fight.IsRoleSkillUseful(1,101)?1:0;
        const int emergencyChoice=fight.GetUnitAISkillId(1);metrics["unified_emergency_regular_choice"]=emergencyChoice;
        if(emergencyChoice)fight.SkillButtle(1,emergencyChoice);metrics["unified_emergency_regular_healed"]=fight.GetHp(2)>3000?1:0;
        emergencySetup(3000,1,3);metrics["unified_emergency_regular_cooldown"]=fight.GetUnitAISkillId(1);
        emergencySetup(3500);metrics["unified_emergency_regular_boundary"]=fight.GetUnitAISkillId(1);
        emergencySetup(3000,2);metrics["unified_emergency_regular_other_strategy"]=fight.GetUnitAISkillId(1);
        metrics["unified_mechanisms_passed"]=metrics["unified_transfer_snapshot"]==200 && metrics["unified_transfer_enemy_loss"]==200 && metrics["unified_transfer_fallback"]==400
            && metrics["unified_action_buff"]==1300 && metrics["unified_action_duration"]==1
            && metrics["unified_growth_before"]==100 && metrics["unified_growth_after_two"]==100 && metrics["unified_growth_capped"]==0 && metrics["unified_growth_next_action"]==100 && metrics["unified_growth_secondary"]==0
            && metrics["unified_hp_restore"]==900 && metrics["unified_link_excluded_loss"]==1000 && metrics["unified_link_excluded_ally"]==0
            && metrics["unified_link_primary"]==500 && metrics["unified_link_lowest"]==500 && metrics["unified_link_other"]==0
            && metrics["unified_guard_capped"]==0 && metrics["unified_guard_next_turn"]==1 && metrics["unified_low_water_memory"]==10001 && metrics["unified_low_water_next"]==3000
            && metrics["unified_revived_action_cd"]==5 && metrics["unified_revived_action_present"]==0 && metrics["unified_revived_next_cd"]==4
            && metrics["unified_opening_branch_rage"]==10 && metrics["unified_opening_branch_guard"]==1200 && metrics["unified_opening_guard_duration"]==2 && metrics["unified_opening_guard_origin"]==173
            && metrics["unified_cleanse_success_bonus"]==1000 && metrics["unified_cleanse_success_duration"]==1 && metrics["unified_cleanse_success_origin"]==164
            && metrics["unified_cleanse_without_negative_loss"]==0 && metrics["unified_cleanse_mixed_bonus"]==1000 && metrics["unified_cleanse_mixed_negative_retained"]==0 && metrics["unified_cleanse_mixed_positive_retained"]==1
            && metrics["unified_dispel_negative_retained"]==1 && metrics["unified_dispel_positive_retained"]==0 && metrics["unified_dispel_copied_positive"]==1000
            && metrics["unified_copy_buff_initial"]==3 && metrics["unified_copy_buff_same_action"]==3 && metrics["unified_copy_buff_next_action"]==2
            && metrics["unified_thorns_without_buff"]==300 && metrics["unified_thorns_with_buff"]==362 && metrics["unified_thorns_guard_chance"]==2000
            && metrics["unified_round_begin_buff_action"]==-1 && metrics["unified_round_begin_buff_initial_duration"]>0 && metrics["unified_round_begin_target_alive"]==1
            && metrics["unified_round_begin_buff_duration"]==metrics["unified_round_begin_buff_initial_duration"]-1
            && metrics["unified_passive_target_mode"]==2 && metrics["unified_passive_target_excluded"]==3 && metrics["unified_passive_target_first"]==1 && metrics["unified_passive_target_repeat"]==0 && metrics["unified_passive_target_next"]==1
            && metrics["unified_passive_target_highest"]==1 && metrics["unified_passive_target_cap_two"]==2 && metrics["unified_passive_target_cap_three"]==3
            && metrics["unified_passive_target_once_first"]==1 && metrics["unified_passive_target_once_repeat"]==0 && metrics["unified_passive_target_once_later"]==0 && metrics["unified_passive_target_once_next_action"]==1
            && metrics["unified_active_buff_initial"]==2 && metrics["unified_active_buff_same_action"]==2 && metrics["unified_active_buff_next_action"]==1
            && metrics["unified_shield_branch_self"]==3062 && metrics["unified_shield_branch_lowest"]==918 && metrics["unified_shield_branch_other"]==0 && metrics["unified_shield_branch_origin"]==1200
            && metrics["unified_direct_bonus_precision"]==3312 && metrics["unified_vulnerability_cap_damage"]==2700
            && metrics["unified_team_hero_absent"]==10000 && metrics["unified_team_hero_present"]==12000 && metrics["unified_team_hero_dead"]==10000
            && metrics["unified_death_index_first_alive"]==1 && metrics["unified_death_index_shifted_alive"]==0
            && metrics["unified_delta_initialized_defense"]==458 && metrics["unified_delta_aura_defense"]==458 && metrics["unified_delta_preserved_defense"]==458
            && metrics["unified_aura_first"]==1450 && metrics["unified_aura_strongest"]==4700
            && metrics["unified_delta_preserved_attack"]==1650 && metrics["unified_delta_removed_attack"]==1500 && metrics["unified_delta_hp_clamp"]==30000
            && metrics["unified_stored_buff_type"]==ESBUFF_ShiDu && metrics["unified_stored_buff_amount"]==300 && metrics["unified_stored_buff_tail"]==0
            && metrics["unified_stored_buff_duration"]==3 && metrics["unified_stored_buff_origin"]==531
            && metrics["unified_stored_buff_other_branch"]==ESBUFF_FuDu && metrics["unified_stored_buff_other_origin"]==ESBUFF_FuDu
            && metrics["unified_opening_action_plan"]==1 && metrics["unified_opening_action_defense"]==2000 && metrics["unified_opening_action_weakness"]==3000 && metrics["unified_opening_action_other"]==0
            && metrics["unified_active_hot_self"]==720 && metrics["unified_active_hot_ally"]==720 && metrics["unified_active_hot_other_branch"]==600
            && metrics["unified_periodic_first_damage"]==200 && metrics["unified_periodic_unapplied_slow"]==0
            && metrics["unified_periodic_first_extension"]==3 && metrics["unified_periodic_extension_gap"]==3 && metrics["unified_periodic_next_extension"]==4 && metrics["unified_periodic_applied_slow"]==1000
            && metrics["unified_useful_no_shield"]==0 && metrics["unified_useful_live_shield"]==1 && metrics["unified_useful_dead_shield"]==0 && metrics["unified_useful_unselected"]==1
            && metrics["unified_useful_one_enemy"]==0 && metrics["unified_useful_unmarked_boss"]==1 && metrics["unified_useful_marked_boss"]==0 && metrics["unified_useful_two_enemies"]==1
            && metrics["unified_useful_three_susceptible"]==1 && metrics["unified_useful_two_susceptible"]==0 && metrics["unified_useful_susceptible_boss"]==1 && metrics["unified_useful_immune_marked"]==0
            && metrics["unified_active_duration_override"]==1 && metrics["unified_active_duration_same_action"]==1 && metrics["unified_active_duration_expired"]==1 && metrics["unified_active_duration_other_branch"]==2
            && metrics["unified_active_parameter_reduction"]==1200 && metrics["unified_active_parameter_floor"]==0 && metrics["unified_active_parameter_absent"]==1
            && metrics["unified_event_bonus_first"]>0 && metrics["unified_event_bonus_empty_third"]==0
            && metrics["unified_break_restore"]==800 && metrics["unified_break_restore_secondary"]==800 && metrics["unified_break_restore_legacy"]==0
            && metrics["unified_break_restore_expiry"]==0 && metrics["unified_break_restore_dispel"]==0 && metrics["unified_break_restore_antiheal"]==400
            && metrics["unified_critical_minimum"]==1500 && metrics["unified_critical_maximum"]==3000 && metrics["unified_critical_interior"]==2200
            && metrics["unified_critical_overflow_high"]==std::numeric_limits<int>::max() && metrics["unified_critical_overflow_low"]==std::numeric_limits<int>::min()
            && metrics["unified_critical_attack_cap"]==0 && metrics["unified_critical_heal_cap"]==0 && metrics["unified_critical_attack_damage"]==1000 && metrics["unified_critical_rng"]==1
            && metrics["unified_owned_taunt_first"]==1200 && metrics["unified_owned_taunt_repeat"]==0 && metrics["unified_owned_taunt_next"]==1200
            && metrics["unified_owned_taunt_antiheal"]==600 && metrics["unified_owned_taunt_boss_replacement"]==0 && metrics["unified_owned_taunt_full_hp_budget"]==0
            && metrics["unified_counter_presence_absent"]==0 && metrics["unified_counter_presence_live"]==1000 && metrics["unified_counter_presence_dead"]==0
            && metrics["unified_counter_presence_consumed"]==1 && metrics["unified_counter_absent_damage"]==0 && metrics["unified_counter_dead_damage"]==0
            && metrics["unified_sacrifice_normal_cost"]==1500 && metrics["unified_sacrifice_low_cost"]==99 && metrics["unified_sacrifice_one_hp_cost"]==0
            && metrics["unified_sacrifice_other_cost"]==2000 && metrics["unified_sacrifice_multiplier"]==12500 && metrics["unified_sacrifice_normal_damage"]>0
            && metrics["unified_revive_usefulness_live"]==1 && metrics["unified_revive_usefulness_rng"]==1 && metrics["unified_revive_strategy_normal"]==0 && metrics["unified_revive_strategy_rng"]==1
            && metrics["unified_revive_scan_useful"]==1 && metrics["unified_revive_scan_rng"]==1
            && metrics["unified_disabled_active_link"]==0 && metrics["unified_disabled_active_reduction"]==0 && metrics["unified_active_link_other_branch"]==1
            && metrics["unified_weapon_scope_count"]==3 && metrics["unified_weapon_scope_min"]==1500 && metrics["unified_weapon_scope_max"]==1500 && metrics["unified_weapon_scope_duration"]==2
            && metrics["unified_high_hp_critical_chance"]==1500 && metrics["unified_high_hp_critical_damage"]==1500 && metrics["unified_boundary_critical_chance"]==0 && metrics["unified_boundary_critical_damage"]==0
            && metrics["unified_other_critical_chance"]==0 && metrics["unified_other_critical_damage"]==0 && metrics["unified_high_hp_critical_consumer"]==1
            && metrics["unified_zero_backlash_events"]==1 && metrics["unified_zero_backlash_hp_loss"]==0 && metrics["unified_zero_backlash_bytes"]>4
            && metrics["unified_zero_first_parameter_events"]==0 && metrics["unified_zero_periodic_default_events"]==0
            && metrics["unified_resist_refund_first"]==5 && metrics["unified_resist_refund_repeat"]==5 && metrics["unified_resist_refund_next"]==10
            && metrics["unified_resist_refund_immune"]==0 && metrics["unified_resist_refund_other_branch"]==0 && metrics["unified_resist_refund_full_budget"]==60
            && metrics["unified_state_aggregate_base_damage"]>0 && metrics["unified_state_aggregate_duplicate_hp_match"]==1 && metrics["unified_state_aggregate_duplicate_rng_match"]==1
            && metrics["unified_state_aggregate_other_sources_events"]==1 && metrics["unified_state_aggregate_other_sources_hp_match"]==1 && metrics["unified_state_aggregate_reverse_damage"]==4900
            && metrics["unified_emergency_regular_plain_usefulness"]==0 && metrics["unified_emergency_regular_choice"]==101 && metrics["unified_emergency_regular_healed"]==1
            && metrics["unified_emergency_regular_cooldown"]==0 && metrics["unified_emergency_regular_boundary"]==0 && metrics["unified_emergency_regular_other_strategy"]==0?1:0;
        return metrics;
    }();
    for(const auto& metric:unifiedMechanismMetrics)gatedFields+=",\""+metric.first+"\":"+std::to_string(metric.second);
    fight.Clear();
    const bool cleanReuse=fight.m_combatState.counts.empty() && fight.m_combatState.periodic.empty() && fight.m_combatState.controls.empty()
        && fight.m_actionList.empty() && fight.m_dieList.empty() && fight.m_curActionPos==0 && fight.m_combatDamageScale==10000
        && fight.m_combatState.revives.empty() && fight.m_combatState.reviveSources.empty() && fight.m_combatState.extraAttacks.empty() && fight.m_combatState.amounts.empty() && fight.m_members[0].combatLoadout.groups.empty()
        && fight.m_combatState.rageActors.empty() && fight.m_combatState.rageTeams.empty() && fight.m_combatState.rageOpening.empty() && fight.m_combatState.damageRage.empty();
    std::cout << "COMBAT_DATA_RESULT {\"shield\":"<<shield<<",\"rage\":"<<rage<<",\"cooldown\":"<<cooldown
        <<",\"base_suit_counter\":"<<baseSuitCounter<<",\"stale_suit_tiers\":"<<staleSuitTiers
        <<",\"next_rage\":"<<nextRage<<",\"revive_guard\":"<<guard<<",\"pursuit\":"<<pursuit
        <<",\"repeated_pursuit\":"<<repeated<<",\"control_turns\":"<<control<<",\"poison\":"<<poison<<",\"explosion\":"<<explosion
        <<",\"source_shield\":"<<sourceShield<<",\"target_hp\":"<<targetHp<<",\"strategy_skill\":"<<strategySkill
        <<",\"tactic_skill\":"<<tacticSkill<<",\"regular_skill\":"<<regularSkill
        <<",\"rule_shield_cap\":"<<ruleShieldCap<<",\"rule_shield_refresh\":"<<ruleShieldRefresh
        <<",\"rule_shield_total\":"<<ruleShieldTotal<<",\"enemy_shield\":"<<enemyShield
        <<",\"rule_dot_stacks\":"<<ruleDotStacks<<",\"rule_dot_duration\":"<<ruleDotDuration<<",\"rule_dot_sources\":"<<ruleDotSources
        <<",\"rule_rage_cap\":"<<ruleRageCap<<",\"enemy_rage_cap\":"<<enemyRageCap<<",\"combined_shield\":"<<combinedShield
        <<",\"periodic_events\":"<<periodicEvents<<",\"periodic_damage\":"<<periodicDamage<<",\"periodic_remaining\":"<<periodicRemaining
        <<",\"periodic_next\":"<<periodicNext<<",\"periodic_bleed\":"<<periodicBleed<<",\"periodic_heal\":"<<periodicHeal
        <<",\"control_first\":"<<controlFirst<<",\"control_second\":"<<controlSecond<<",\"control_third\":"<<controlThird
        <<",\"control_independent\":"<<controlIndependent<<",\"control_reset\":"<<controlReset<<",\"boss_count\":"<<bossCount<<",\"boss_slow\":"<<bossSlow<<",\"boss_forbid\":"<<bossForbid
        <<",\"revive_first\":"<<reviveFirst<<",\"revive_same\":"<<reviveSame<<",\"revive_other\":"<<reviveOther<<",\"revive_third\":"<<reviveThird<<",\"revive_extra\":"<<reviveExtra
        <<",\"revive_eligible_target\":"<<reviveEligibleTarget
        <<",\"extra_count\":"<<extras<<",\"enemy_extra_count\":"<<enemyExtras<<",\"extra_next\":"<<extraNext<<",\"nested_shield\":"<<nestedShield
        <<",\"chosen_artifact\":"<<chosenArtifact<<",\"tie_artifact\":"<<tieArtifact<<",\"selected_groups\":"<<selectedGroups<<",\"valid_set_pieces\":"<<validPieces
        <<",\"artifact_guard\":"<<artifactGuard<<",\"artifact_guard_repeat\":"<<repeatedGuard<<",\"artifact_guard_second\":"<<secondGuard<<",\"artifact_dot\":"<<artifactDot<<",\"set_shield\":"<<setShield
        <<",\"artifact_affix_dot\":"<<artifactAffixDot<<",\"artifact_excluded_dot\":"<<artifactExcluded
        <<",\"active_heal_base\":"<<activeHealBase<<",\"active_heal_gear\":"<<activeHealGear<<",\"active_heal_speed\":"<<activeHealSpeed<<",\"hot_heal\":"<<hotHeal
        <<",\"shared_heal_speed\":"<<sharedHealSpeed<<",\"later_hot_speed\":"<<laterHotSpeed<<",\"new_hot_speed\":"<<newHotSpeed
        <<",\"low_shield\":"<<lowShield<<",\"shield_interval\":"<<shieldInterval<<",\"shield_ready\":"<<shieldReady<<",\"cleanse_heal\":"<<cleanseHeal<<",\"cleanse_repeat\":"<<cleanseRepeated
        <<",\"share_damage\":"<<shareDamage<<",\"share_repeat\":"<<shareRepeated<<",\"share_budget_remaining\":"<<shareBudget
        <<",\"direct_base\":"<<directBase<<",\"execute_damage\":"<<executeDamage<<",\"execute_boundary\":"<<executeBoundary
        <<",\"combo_first\":"<<comboFirst<<",\"combo_second\":"<<comboSecond<<",\"combo_fourth\":"<<comboFourth<<",\"combo_fifth\":"<<comboFifth
        <<",\"opening_speed\":"<<openingSpeed<<",\"repeat_speed\":"<<repeatSpeed<<",\"second_speed\":"<<secondSpeed<<",\"expired_speed\":"<<expiredSpeed
        <<",\"capped_direct\":"<<cappedDirect<<",\"floored_direct\":"<<flooredDirect
        <<",\"weakness_same\":"<<weaknessSame<<",\"weakness_two\":"<<weaknessTwo<<",\"weakness_removed\":"<<weaknessRemoved
        <<",\"death_low\":"<<deathLow<<",\"death_high\":"<<deathHigh<<",\"death_lower\":"<<deathLower<<",\"death_repeat\":"<<deathRepeated<<",\"summoned_death\":"<<summonedDeath
        <<",\"death_duration\":"<<deathDuration<<",\"death_origin\":"<<deathOrigin<<",\"refreshed_speed\":"<<refreshedSpeed<<",\"different_source_speed\":"<<differentSourceSpeed
        <<",\"nonholder_rage\":"<<nonholderRage<<",\"artifact_rage\":"<<artifactRage<<",\"repeat_artifact_rage\":"<<repeatedArtifactRage<<",\"next_artifact_rage\":"<<nextArtifactRage<<",\"enemy_artifact_rage\":"<<enemyArtifactRage<<",\"dead_holder_rage\":"<<deadHolderRage
        <<",\"extra_actor_rage\":"<<extraActorRage<<",\"extra_team_rage\":"<<extraTeamRage<<",\"extra_enemy_rage\":"<<extraEnemyRage<<",\"next_extra_rage\":"<<nextExtraRage<<",\"base_rage_bypass\":"<<baseRageBypass<<",\"opening_rage\":"<<openingRage<<",\"tactic_cost_floor\":"<<tacticCostFloor
        <<",\"damage_rage\":"<<damageRage<<",\"secondary_rage\":"<<secondaryRage<<",\"next_damage_rage\":"<<nextDamageRage
        <<",\"efficient_first\":"<<efficientFirst<<",\"efficient_fourth\":"<<efficientFourth<<",\"efficient_sixth\":"<<efficientSixth<<",\"efficient_repeat\":"<<efficientRepeated<<",\"efficient_next\":"<<efficientNext
        <<",\"pressure_absorbed\":"<<pressureAbsorbed<<",\"pressure_remaining\":"<<pressureRemaining<<",\"pressure_life\":"<<pressureLife<<",\"pressure_stats\":"<<pressureStats
        <<",\"spill_life\":"<<spillLife<<",\"spill_absorbed\":"<<spillAbsorbed<<",\"pierce_life\":"<<pierceLife<<",\"pierce_absorbed\":"<<pierceAbsorbed<<",\"base_pierce_life\":"<<basePierceLife<<",\"base_pierce_absorbed\":"<<basePierceAbsorbed<<",\"unshielded_life\":"<<unshieldedLife
        <<",\"set_guard_damage\":"<<setGuardDamage<<",\"combined_guard_damage\":"<<combinedGuardDamage<<",\"dead_aura_damage\":"<<deadAuraDamage<<",\"spent_tactic_damage\":"<<spentTacticDamage<<",\"expired_aura_damage\":"<<expiredAuraDamage
        <<",\"guard_boundary_damage\":"<<guardBoundaryDamage<<",\"capped_guard_damage\":"<<cappedGuardDamage<<",\"ignore_no_debuff\":"<<ignoreNoDebuff<<",\"ignore_combined\":"<<ignoreCombined<<",\"ignore_skill\":"<<ignoreSkill<<",\"ignore_capped\":"<<ignoreCapped<<",\"ignore_physical\":"<<ignorePhysical
        <<",\"received_heal\":"<<receivedHeal<<",\"received_hot\":"<<receivedHot<<",\"low_critical\":"<<lowCritical<<",\"boundary_critical\":"<<boundaryCritical
        <<",\"base_revive_heal\":"<<baseReviveHeal<<",\"received_revive_heal\":"<<receivedReviveHeal
        <<",\"ignore_extreme_negative\":"<<ignoreExtremeNegative<<",\"ignore_extreme_positive\":"<<ignoreExtremePositive
        <<",\"shielded_hit_life\":"<<shieldedHitLife<<",\"shielded_hit_slow\":"<<shieldedHitSlow<<",\"same_action_slow\":"<<sameActionSlow<<",\"normal_hit_slow\":"<<normalHitSlow<<",\"next_action_slow\":"<<nextActionSlow<<",\"set_boss_slow\":"<<setBossSlow<<",\"set_boss_duration\":"<<setBossDuration
        <<",\"nonleader_opening_shield\":"<<nonleaderOpeningShield<<",\"leader_opening_shield\":"<<leaderOpeningShield<<",\"leader_self_shield\":"<<leaderSelfShield<<",\"enemy_opening_shield\":"<<enemyOpeningShield<<",\"repeat_opening_shield\":"<<repeatedOpeningShield
        <<",\"dead_leader_opening_shield\":"<<deadLeaderOpeningShield<<",\"tie_later_opening_shield\":"<<tieLaterOpeningShield<<",\"tie_first_opening_shield\":"<<tieFirstOpeningShield
        <<gatedFields
        <<",\"expiry_damage\":"<<expiryDamage<<",\"dispel_damage\":"<<dispelDamage<<",\"clean_reuse\":"<<(cleanReuse ? 1 : 0)<<",\"seed\":1729}"<<std::endl;
    return probeOnly || (shield==200 && rage==9 && cooldown==5 && nextRage==12 && guard==2000 && baseSuitCounter==1200 && staleSuitTiers==0
        && pursuit==600 && repeated==600 && control==2 && poison==1200 && explosion==552 && strategySkill==tacticSkill
        && ruleShieldCap==5000 && ruleShieldRefresh==2000 && ruleShieldTotal==5000 && enemyShield==5000
        && ruleDotStacks==5 && ruleDotDuration==5 && ruleDotSources==6 && ruleRageCap==100 && enemyRageCap==100 && combinedShield==500
        && periodicEvents==2 && periodicDamage==200 && periodicRemaining==160 && periodicNext==200 && periodicBleed==120 && periodicHeal==150 && cleanReuse
        && controlFirst==4 && controlSecond==2 && controlThird==2 && controlIndependent==4 && controlReset==4
        && bossCount==1 && bossSlow==1000 && bossForbid==0 && reviveFirst==1000 && reviveSame==0 && reviveOther==1000 && reviveThird==0 && reviveExtra==0
        && extras==3 && enemyExtras==3 && extraNext==1 && nestedShield==0 && expiryDamage==148 && dispelDamage==0 && reviveEligibleTarget==7
        && chosenArtifact==1403 && tieArtifact==1403 && selectedGroups==1 && validPieces==1 && artifactGuard==2400 && repeatedGuard==0 && secondGuard==2400 && artifactDot==1180 && setShield==1120 && artifactAffixDot==1340 && artifactExcluded==1000
        && activeHealBase>0 && activeHealGear==activeHealBase*122/100 && activeHealSpeed==800 && hotHeal==1220 && sharedHealSpeed==0 && laterHotSpeed==0 && newHotSpeed==800
        && lowShield==672 && shieldInterval==0 && shieldReady==672 && cleanseHeal==450 && cleanseRepeated==450 && shareDamage==1200 && shareRepeated==1200 && shareBudget==1
        && directBase==1000 && executeDamage==1120 && executeBoundary==1000 && comboFirst==1000 && comboSecond==1120 && comboFourth==1120 && comboFifth==1000
        && openingSpeed==1120 && repeatSpeed==1120 && secondSpeed==1120 && expiredSpeed==1000 && cappedDirect==2000 && flooredDirect==1
        && weaknessSame==1000 && weaknessTwo==1120 && weaknessRemoved==1000 && deathLow==400 && deathHigh==1500 && deathLower==1500 && deathRepeated==0 && summonedDeath==0
        && deathDuration==2 && deathOrigin==10011 && refreshedSpeed==800 && differentSourceSpeed==1600
        && nonholderRage==0 && artifactRage==6 && repeatedArtifactRage==6 && nextArtifactRage==6 && enemyArtifactRage==6 && deadHolderRage==2
        && extraActorRage==12 && extraTeamRage==30 && extraEnemyRage==12 && nextExtraRage==42 && baseRageBypass==8 && openingRage==20 && tacticCostFloor==20
        && damageRage==9 && secondaryRage==0 && nextDamageRage==12
        && efficientFirst==1120 && efficientFourth==1120 && efficientSixth==1000 && efficientRepeated==1120 && efficientNext==1120
        && pressureAbsorbed==1240 && pressureRemaining==3760 && pressureLife==0 && pressureStats==1240 && spillLife==596 && spillAbsorbed==500
        && pierceLife==400 && pierceAbsorbed==744 && basePierceLife==400 && basePierceAbsorbed==600 && unshieldedLife==1000
        // Preserve the source branch's float multiplier followed by truncation.
        && setGuardDamage==850 && combinedGuardDamage==669 && deadAuraDamage==669 && spentTacticDamage==770 && expiredAuraDamage==850 && guardBoundaryDamage==1000 && cappedGuardDamage==399
        && ignoreNoDebuff==1500 && ignoreCombined==2860 && ignoreSkill==4288 && ignoreCapped==6000 && ignorePhysical==1500
        && ignoreExtremeNegative==0 && ignoreExtremePositive==6000
        && receivedHeal==activeHealBase*110/100 && receivedHot==1100 && lowCritical==2500 && boundaryCritical==0
        && baseReviveHeal>0 && receivedReviveHeal==baseReviveHeal*110/100
        && shieldedHitLife==0 && shieldedHitSlow==1200 && sameActionSlow==0 && normalHitSlow==0 && nextActionSlow==1200 && setBossSlow==1000 && setBossDuration==2
        && nonleaderOpeningShield==0 && leaderOpeningShield==1344 && leaderSelfShield==1344 && enemyOpeningShield==1008 && repeatedOpeningShield==0
        && deadLeaderOpeningShield==672 && tieLaterOpeningShield==0 && tieFirstOpeningShield==672
        && gatedMetrics.at("gated_passed")==1 && attackMetrics.at("attack_passed")==1
        && countMetrics.at("count_passed")==1
        && healingMetrics.at("healing_passed")==1
        && terminalMetrics.at("terminal_passed")==1
        && orderMetrics.at("order_passed")==1
        && rageAffixMetrics.at("rage_affix_passed")==1
        && actionRageMetrics.at("action_rage_passed")==1
        && passiveReviveMetrics.at("passive_revive_passed")==1
        && nuwaMetrics.at("nuwa_passed")==1
        && thornsMetrics.at("thorns_passed")==1
        && overkillMetrics.at("overkill_passed")==1
        && shieldLossMetrics.at("shield_loss_passed")==1
        && shieldShareMetrics.at("share_passed")==1
        && guardAffixMetrics.at("guard_passed")==1
        && breakDispelMetrics.at("break_dispel_passed")==1
        && cleanseDispelMetrics.at("cleanse_dispel_passed")==1
        && healBudgetMetrics.at("heal_budget_passed")==1
        && reviveOrderMetrics.at("revive_order_passed")==1
        && receivedOrderMetrics.at("received_order_passed")==1
        && chanceMetrics.at("chance_passed")==1
        && deathAffixMetrics.at("death_affix_passed")==1
        && removedAntihealMetrics.at("removed_antiheal_passed")==1
        && summonAffixMetrics.at("summon_affix_passed")==1
        && durationChanceMetrics.at("duration_chance_passed")==1
        && buffPayloadMetrics.at("buff_payload_passed")==1
        && stateAffixMetrics.at("state_affix_passed")==1
        && nuwaOriginMetrics.at("nuwa_origin_passed")==1
        && reviveRecordMetrics.at("revive_record_passed")==1
        && targetPolicyMetrics.at("target_policy_passed")==1
        && shieldCoreMetrics.at("shield_core_passed")==1
        && shieldFullMetrics.at("shield_full_passed")==1
        && pursuitFullMetrics.at("pursuit_full_passed")==1
        && hero15bMetrics.at("hero15b_passed")==1
        && hero15aMetrics.at("hero15a_passed")==1
        && hero61aMetrics.at("hero61a_passed")==1
        && hero65aMetrics.at("hero65a_passed")==1
        && hero65bMetrics.at("hero65b_passed")==1
        && hero61bMetrics.at("hero61b_passed")==1
        && unifiedMechanismMetrics.at("unified_mechanisms_passed")==1
        && hitMetrics.at("direct_min_hit")==0 && hitMetrics.at("enemy_min_hit")==0 && hitMetrics.at("direct_max_hit")==1000 && hitMetrics.at("enemy_max_hit")==1000);
}
