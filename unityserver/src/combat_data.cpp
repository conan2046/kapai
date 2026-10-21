#include "combat_data.h"
#include "rapidjson/document.h"
#include <algorithm>
#include <fstream>
#include <limits>
#include <set>
#include <sstream>
#include <stdexcept>

namespace CombatData {
namespace {
using rapidjson::Value;
constexpr const char* EventVocabulary="before_opening_action|after_passive_targets|before_thorns_roll|before_thorns_amount|opening_branch_rage|opening_branch_guard|before_hp_restore|owned_buff_hit|passive_attempt_failed|before_debuff_resistance|after_guard_hp|before_attribute_growth|before_guard_candidate|before_guard_damage|before_passive_heal|after_hp_observed|opening_snapshot|before_attribute_transfer|"
"before_periodic_proc|after_periodic_proc|before_thorns_damage|before_effect_attempt|before_passive_value|after_dispel_batch|after_cleanse_batch|before_kill_followup|kill_followup_damage|before_self_revive|before_skill_cast|after_landed_skill|before_skill_growth|before_passive_list|before_counter|before_target_plan|before_protection|after_dodge|secondary_attack_observed|before_skill_sequence|before_direct_amount|before_combo_amount|before_self_damage|before_sacrifice_damage|before_stat|buff_attempt_applied|before_buff_attempt|buff_attempt_failed|before_passive_raw_parameters|after_passive_sequence|after_skill_damage|kill_confirmed|accepted_kill_action|before_action_repeat|before_passive_parameters|after_passive_attribute_roll|before_kill_action|after_primary_hit|"
"after_heal|after_revive|shield_lost|before_dot|before_buff|after_hit|before_heal|after_periodic_heal|action_start|after_cleanse|after_share|before_direct_damage|before_speed|death|after_regular|before_shield_damage|before_guard|before_critical|before_received_heal|before_defense|after_attack|battle_begin|kill|counter_kill|before_attack|before_action_order|opening_rage|before_tactic_cost|action_end|after_combo|after_skill_heal|finalize_heal|before_passive_revive|after_self_revive|before_skill_usefulness|after_thorns|after_direct_kill|after_owned_shield_loss|after_received_shield_loss|after_self_shield|before_share_damage|after_guard_damage|after_buff|after_shield_break|after_enemy_dispel|after_friendly_cleanse|after_counter_damage|after_periodic_damage|after_counter_success|after_kill_rewards|control_resisted|after_death_guard|death_observed|after_buff_removed|after_heal_with_antiheal|before_summon_attack|before_summon_hp|accepted_control|before_hp_change|after_direct_hp_loss|after_critical_roll|landed_attack|before_revive_eligibility|before_shield_passive|before_shield";
bool In(const std::string& value, const std::string& choices) {
    return ("|" + choices + "|").find("|" + value + "|") != std::string::npos;
}
int FactId(const std::string& field,const std::string& prefix,int maximum) {
    if(field.compare(0,prefix.size(),prefix)!=0 || field.size()<=prefix.size() || field[prefix.size()]=='0')return 0;
    int id=0;
    for(size_t i=prefix.size();i<field.size();++i){if(field[i]<'0' || field[i]>'9' || id>(maximum-(field[i]-'0'))/10)return 0;id=id*10+field[i]-'0';}
    return id;
}
int ActiveBuffFact(const std::string& field,bool skill) {
    const std::string prefix="source_active_buff_";
    if(field.compare(0,prefix.size(),prefix)!=0)return 0;
    const auto split=field.find('_',prefix.size());if(split==std::string::npos)return 0;
    const int origin=FactId("id_"+field.substr(prefix.size(),split-prefix.size()),"id_",65535),buff=FactId("id_"+field.substr(split+1),"id_",65535);
    return origin && buff?(skill?origin:buff):0;
}
int BuffFact(const std::string& field){
    if(field.compare(0,13,"event_target_")==0)return BuffFact(field.substr(6));
    int id=ActiveBuffFact(field,false);
    for(const char* prefix:{"enemy_unstacked_units_","enemy_unstacked_boss_","enemy_susceptible_unstacked_","enemy_susceptible_unstacked_boss_","source_buff_","enemy_buff_units_","source_owns_buff_","target_buff_value_","target_buff_","target_immune_","target_blocks_buff_","target_owned_buff_instances_","target_owned_buff_remaining_"})id=std::max(id,FactId(field,prefix,65535));
    return id;
}
int SkillFact(const std::string& field){return std::max(FactId(field,"source_passive_skill_",65535),std::max(ActiveBuffFact(field,true),std::max(FactId(field,"source_skill_level_",65535),FactId(field,"team_skill_level_",65535))));}
int HeroFact(const std::string& field){if(field.compare(0,13,"event_target_")==0)return HeroFact(field.substr(6));return std::max(FactId(field,"source_team_hero_",65535),FactId(field,"target_hero_",65535));}
int GateFact(const std::string& field){return std::max(FactId(field,"gate_",std::numeric_limits<int>::max()),FactId(field,"gate_count_",std::numeric_limits<int>::max()));}
int CategoryFact(const std::string& field){if(field.compare(0,13,"event_target_")==0)return CategoryFact(field.substr(6));int id=0;for(const char* prefix:{"target_owned_periodic_raw_","target_periodic_remaining_","target_category_","target_category_count_"})id=std::max(id,FactId(field,prefix,65535));return id;}
bool TargetCounterFact(const std::string& field){return field.compare(0,15,"target_counter_")==0;}
int CounterFact(const std::string& field){
    int id=0;for(const char* prefix:{"counter_action_limit_","counter_count_","counter_age_","counter_action_count_","counter_turn_count_","target_counter_count_","target_counter_age_","target_counter_action_count_","target_counter_turn_count_"})id=std::max(id,FactId(field,prefix,std::numeric_limits<int>::max()));return id;
}
int StateFact(const std::string& field){return std::max(FactId(field,"state_value_",std::numeric_limits<int>::max()),FactId(field,"target_state_value_",std::numeric_limits<int>::max()));}
int MarkFact(const std::string& field){int id=0;for(const char* prefix:{"mark_value_","mark_source_","mark_group_","mark_present_","source_mark_value_","source_mark_source_","source_mark_group_","source_mark_present_"})id=std::max(id,FactId(field,prefix,std::numeric_limits<int>::max()));return id;}
bool Field(const std::string& field, const std::string& context) {
    if(context=="after_passive_targets" && In(field,"passive_trigger|passive_effect"))return true;
    if(context=="before_passive_list" && In(field,"highest_enemy_combo_bp|highest_enemy_critical_bp|highest_enemy_debuff_bp|highest_enemy_counter_bp"))return true;
    if(context=="passive_attempt_failed" && In(field,"effect_kind|passive_effect"))return true;
    if(context=="before_debuff_resistance" && field=="hard_control")return true;
    if(field=="source_hp_bp_ceil")return context!="strategy";
    if(context=="before_passive_heal" && field=="amount")return true;
    if(context=="before_attribute_growth" && (field=="passive_effect" || FactId(field,"parameter_value_",5)))return true;
    if(context=="before_attribute_transfer" && In(field,"amount|passive_effect|attribute_type"))return true;
    if(In(context,"before_periodic_proc|after_periodic_proc") && In(field,"amount|periodic_input"))return true;
    if(context=="before_periodic_proc" && field=="live_owned_buff_targets")return true;
    if(context=="before_effect_attempt" && In(field,"effect_kind|passive_effect|target_present|base_duration"))return true;
    if(context=="before_passive_value" && In(field,"amount|attribute_type|passive_effect|passive_trigger|target_present"))return true;
    if(context=="before_thorns_damage" && In(field,"amount|passive_thorns"))return true;
    if(In(context,"after_dispel_batch|after_cleanse_batch") && field=="removed_count")return true;
    if(context=="after_cleanse_batch" && field=="removed_negative_count")return true;
    if(context!="strategy" && field.compare(0,13,"event_target_")==0){const auto target=field.substr(6);return BuffFact(target) || CategoryFact(target) || HeroFact(target) || In(target,"target_position|target_hp|target_max_hp|target_missing_hp|target_hp_bp|target_hp_bp_ceil|target_alive|target_attack_type|target_boss|target_shield|target_shield_amount|target_debuff_categories|target_has_debuff|target_hard_control");}
    if(context=="before_passive_list" && In(field,"passive_trigger|effect_count|target_present"))return true;
    if(context=="before_skill_growth" && field=="passive_effect")return true;
    if(context!="strategy" && In(field,"sequence_fixed|sequence_index|sequence_target_index"))return true;
    if(context=="before_stat" && field=="stat_kind")return true;
    if(context=="before_buff_attempt" && field=="parameter_count")return true;
    if(context=="buff_attempt_failed" && field=="immune")return true;
    if(context=="buff_attempt_applied" && In(field,"event_buff_owned|event_duration|event_stack_group|event_stack_count"))return true;
    if(context=="before_passive_raw_parameters" && In(field,"passive_effect|parameter_path|parameter_count"))return true;
    if(context=="after_passive_sequence" && field=="passive_trigger")return true;
    if(In(context,"before_passive_parameters|after_passive_attribute_roll") && In(field,"passive_effect|passive_trigger|passive_count|parameter_count|target_present|target_summoned|same_team"))return true;
    if(context=="before_kill_action" && field=="source_just_revived")return true;
    if(In(context,"accepted_kill_action|before_kill_followup") && field=="action_kind")return true;
    if(context=="kill_confirmed" && field=="kill_count")return true;
    if(context=="before_buff" && field=="parameter_count")return true;
    if(context=="after_primary_hit" && In(field,"amount|event_target_alive|had_shield"))return true;
    if(context=="after_critical_roll" && In(field,"critical|effect_battle_count"))return true;
    if(context=="landed_attack" && In(field,"first_attack|counter_attack|hit_index"))return true;
    if(context!="strategy" && CounterFact(field))return true;
    if(context!="strategy" && StateFact(field))return true;
    if(context!="strategy" && MarkFact(field))return true;
    if(In(context,"before_buff|before_buff_attempt|before_passive_parameters|before_passive_raw_parameters|before_shield_damage") && FactId(field,"parameter_value_",5))return true;
    if(context!="strategy" && In(field,"event_skill|event_depth"))return true;
    if(context=="before_shield_passive" && In(field,"expired|broken"))return true;
    if(context=="after_direct_hp_loss" && In(field,"amount|received_damage_bp"))return true;
    if(context=="after_buff" && In(field,"event_duration|event_stack_group|event_stack_count"))return true;
    if(context=="accepted_control" && field=="hard_control")return true;
    if(context=="after_buff_removed" && In(field,"buff_param0|remaining_turns"))return true;
    if(context=="death_observed" && In(field,"victim_summoned|effect_battle_count"))return true;
    if (context == "strategy")
        return In(field, "one|allies_dead|allies_low|enemy_dots|tactic_revives|regular_revives|tactic_heals|regular_heals|tactic_targets|regular_targets|lowest_ally_hp_bp|lowest_ally_protected|source_hp_bp|enemies_untaunted|highest_enemy_controlled|highest_enemy_resistance_down|highest_enemy_boss|lowest_enemy_hp_bp|enemy_exposed");
    if(context=="after_guard_damage" && field=="attacker_alive")return true;
    if(In(context,"kill_followup_damage|after_counter_damage|after_periodic_damage") && field=="amount")return true;
    if(context=="after_attack" && In(field,"regular_skill|hit_index|amount|absorbed|counter_attack"))return true;
    if(context=="before_attack" && In(field,"first_attack|counter_attack|hit_index"))return true;
    if(context=="before_heal" && field=="periodic_heal")return true;
    if(context=="after_combo" && field=="segments")return true;
    if(context=="after_thorns" && In(field,"amount|absorbed|passive_thorns"))return true;
    if(context=="after_direct_kill" && field=="overkill")return true;
    if(In(context,"after_owned_shield_loss|after_received_shield_loss") && In(field,"shield_absorbed|broken"))return true;
    if(context=="after_self_shield" && In(field,"shield_amount|event_duration"))return true;
    if(context=="after_skill_heal" && field=="processed_targets")return true;
    if(In(context,"finalize_heal|before_passive_revive") && field=="amount")return true;
    if(context=="before_skill_usefulness" && In(field,"enemies_shielded|source_team_second_hp_bp|source_team_mean_missing_hp_bp"))return true;
    if(In(field,"source_base_attack|source_position|target_has_debuff|source_hard_control|target_hard_control|target_hp_bp_ceil|target_shield_amount|enemies_alive|target_attack_type"))return true;
    if(context=="battle_begin" && field=="source_is_group_hp_leader")return true;
    if(context=="kill" && In(field,"victim_summoned|enemy_kill"))return true;
    if(GateFact(field) || CategoryFact(field) || field=="skill_level")return true;
    if(BuffFact(field) || SkillFact(field) || HeroFact(field) || In(field,"source_attack_type|tactic_used|affix_value1|affix_value2|affix_tier|affix_duration|affix_is_owner"))return true;
    if (In(field, "one|gear_value|turn|source_alive|source_summoned|source_hp|source_hp_bp|source_max_hp|source_attack|rage|target_hp|target_max_hp|target_missing_hp|target_hp_bp|target_alive|target_boss|target_shield|target_debuff_categories|position")) return true;
    if(context=="before_direct_damage" && field=="hit_index") return true;
    if(context=="after_heal" && In(field,"healing_total|recipient_count"))return true;
    if (context == "after_heal" || context == "after_revive" || context=="after_periodic_heal") return In(field,"overheal|effective_heal|hp_before_bp");
    if (context == "shield_lost") return In(field,"shield_absorbed|shield_remaining|shield_parameter_count|shield_loss_basis|event_hp_loss|event_bonus|secondary_damage|expired|broken|dispelled|attacker_position");
    if(context=="before_shield")return In(field,"parameter_count");
    return ((context == "before_dot" || context == "after_hit") && field == "amount") || (context=="before_dot" && field=="periodic_damage");
}
const Value& Member(const Value& row, const char* key) {
    if (!row.IsObject() || !row.HasMember(key)) throw std::runtime_error(std::string("missing field ") + key);
    return row[key];
}
int Int(const Value& row, const char* key, int min = 0, int max = std::numeric_limits<int>::max()) {
    const Value& v = Member(row, key);
    if (!v.IsInt() || v.GetInt() < min || v.GetInt() > max) throw std::runtime_error(std::string("invalid integer ") + key);
    return v.GetInt();
}
std::string Str(const Value& row, const char* key) {
    const Value& v = Member(row, key);
    if (!v.IsString()) throw std::runtime_error(std::string("invalid string ") + key);
    return v.GetString();
}
std::string Token(const Value& row, const char* key, const char* choices) {
    std::string s = Str(row, key);
    if (!In(s, choices)) throw std::runtime_error(std::string("unknown ") + key + ": " + s);
    return s;
}
std::vector<Condition> Conditions(const Value& row, const std::string& context) {
    const Value& list = Member(row, "conditions");
    if (!list.IsArray()) throw std::runtime_error("conditions must be an array");
    std::vector<Condition> result;
    for (rapidjson::SizeType i = 0; i < list.Size(); ++i) {
        Condition c;
        c.field = Str(list[i], "field");
        if (!Field(c.field,context)) throw std::runtime_error("unavailable condition field for " + context + ": " + c.field);
        c.op = Token(list[i], "op", "eq|ne|lt|le|gt|ge");
        c.value = Int(list[i], "value", std::numeric_limits<int>::min());
        if(list[i].HasMember("value_field")) {
            c.otherField=Str(list[i],"value_field");
            if(!Field(c.otherField,context))throw std::runtime_error("unavailable comparison field: "+c.otherField);
        }
        result.push_back(c);
    }
    return result;
}
void Read(const std::string& dir, const std::string& name, const std::function<void(const Value&)>& consume) {
    std::ifstream input(dir + "/" + name + ".json", std::ios::binary);
    if (!input) throw std::runtime_error("cannot open " + dir + "/" + name + ".json");
    std::string content((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    rapidjson::Document doc;
    if (doc.Parse(content.c_str()).HasParseError() || !doc.IsArray() || doc.Empty()) throw std::runtime_error(name + ": expected nonempty JSON array");
    std::set<int> ids;
    for (rapidjson::SizeType i = 0; i < doc.Size(); ++i) {
        try {
            int id = Int(doc[i], "id", 1);
            if (!ids.insert(id).second) throw std::runtime_error("duplicate id");
            consume(doc[i]);
        } catch (const std::exception& e) { throw std::runtime_error(name + " row " + std::to_string(i + 1) + ": " + e.what()); }
    }
}
int64_t Get(const Values& values, const std::string& key) {
    if (key == "one") return 1;
    const auto it = values.find(key);
    if (it == values.end()) {if(BuffFact(key) || SkillFact(key) || HeroFact(key) || GateFact(key) || CategoryFact(key))return 0;throw std::runtime_error("missing battle fact: " + key);}
    return it->second;
}
bool Match(const std::vector<Condition>& conditions, const Values& values) {
    for (const auto& c : conditions) {
        const auto a = Get(values, c.field), b = c.otherField.empty()?c.value:Get(values,c.otherField);
        if ((c.op == "eq" && a != b) || (c.op == "ne" && a == b) || (c.op == "lt" && a >= b)
            || (c.op == "le" && a > b) || (c.op == "gt" && a <= b) || (c.op == "ge" && a < b)) return false;
    }
    return true;
}
}

Catalog& Current() { static Catalog catalog; return catalog; }
bool Catalog::Load(const std::string& dir, std::string& error) {
    try {
        Catalog next;
        std::set<int> affixIds;
        std::map<int,int> affixMaximum;
        std::map<std::pair<int,std::string>,int> chanceMaximum;
        Read(dir,"equipment_affix",[&](const Value& row){
            const int id=Int(row,"id",1);affixIds.insert(id);
            const auto& values=Member(row,"value1");
            if(!values.IsArray() || values.Size()!=3)throw std::runtime_error("invalid affix value curve");
            for(rapidjson::SizeType i=0;i<values.Size();++i){
                if(!values[i].IsInt() || values[i].GetInt()<0)throw std::runtime_error("invalid affix value curve");
                affixMaximum[id]=std::max(affixMaximum[id],values[i].GetInt());
            }
            for(const auto* key:{"value1","value2"}) {
                const auto& curve=Member(row,key);
                if(!curve.IsArray() || curve.Size()!=3)throw std::runtime_error("invalid affix value curve");
                for(rapidjson::SizeType i=0;i<curve.Size();++i) {
                    if(!curve[i].IsInt() || curve[i].GetInt()<0)throw std::runtime_error("invalid affix value curve");
                    auto& maximum=chanceMaximum[{id,std::string("affix_")+key}];maximum=std::max(maximum,curve[i].GetInt());
                }
            }
        });
        Read(dir,"combat_buff_category",[&](const Value& row) {
            if(!next.buffCategories_.emplace(Int(row,"buff_id",1,65535),Int(row,"category",1,65535)).second)
                throw std::runtime_error("conflicting buff category");
        });
        std::set<int> groups;
        Read(dir, "combat_effect", [&](const Value& row) {
            Effect e;
            e.id = Int(row, "id", 1); e.group = Int(row, "group_id", 1); e.priority = Int(row, "priority");
            e.skill = Int(row, "skill_id", 0, 65535); e.buff = Int(row, "buff_id", 0, 65535);
            e.event = Token(row, "event", EventVocabulary);
            e.target = Token(row, "target", "highest_enemy_base_attack|other_healed_allies|lowest_two_other_healed_allies|target|self|allies|enemies|lowest_ally|highest_gear_ally|target_any|self_any|lowest_enemy_hp|lowest_other_ally|other_allies|first_unstacked_enemy|first_unstacked_susceptible_enemy|same_row_enemies|attacker|lowest_ally_current_hp|lowest_other_ally_current_hp|highest_other_ally_base_attack|first_other_enemy|lowest_other_enemy_current_hp");
            if(e.target=="attacker" && e.event!="shield_lost")throw std::runtime_error("attacker selector requires shield loss");
            if(In(e.target,"first_unstacked_enemy|first_unstacked_susceptible_enemy") && !In(e.event,"after_buff|buff_attempt_applied"))throw std::runtime_error("stack selector requires after_buff");
            if(e.target=="same_row_enemies" && e.event!="buff_attempt_applied")throw std::runtime_error("row selector requires an applied buff event");
            e.op = Token(row, "op", "extend_origin_buffs|trigger_periodic|extend_owned_buff|reserve_overheal|split_heal|consume_periodic|promote_buff|cleanse|dispel|strike|apply_skill_passives|replace_passive_list|mark|state_set|state_add|replace_buff|heal|restore_hp|damage|passive_damage|shield|buff|copy_buff|rage|cooldown|scale_amount|set_duration|add_duration|extend_buff|reset_counter|scale_parameters|add_amount_bonus|add_parameter_bonus|add_parameter_flat|add_event_bonus|set_parameter|combine_remaining|gate|chance_gate|multiply_amount");
            e.bindingScope=row.HasMember("binding_scope")?Token(row,"binding_scope","owner|target_team|source_mark|target_mark|source_buff_owner"):"owner";
            if(e.bindingScope=="source_buff_owner" && (e.event!="owned_buff_hit" || !e.buff || !In(e.op,"gate|add_amount_bonus")))throw std::runtime_error("invalid source buff owner binding");
            if(e.bindingScope=="target_team" && ((!((e.event=="before_shield" && e.op=="add_amount_bonus") || (e.event=="before_stat" && e.op=="multiply_amount"))) || e.skill || e.affix))throw std::runtime_error("invalid team binding modifier");
            e.probabilitySource=row.HasMember("probability_source")?Token(row,"probability_source","constant|affix_value1|affix_value2"):"constant";
            e.budget = Token(row,"budget","none|extra_attack");
            e.amountBudget=row.HasMember("amount_budget")?Token(row,"amount_budget","none|source_turn|source_action"):"none";
            e.counterScope = Token(row,"counter_scope","source|target|team");
            e.ratioSource=Token(row,"ratio_source","constant|gear_value|affix_value1|affix_value2|event_bonus");e.interval=Int(row,"interval_turns",0,65535);
            if(e.ratioSource=="event_bonus" && (e.event!="shield_lost" || e.op!="passive_damage"))throw std::runtime_error("invalid event bonus consumer");
            e.capRatioSource=Token(row,"cap_ratio_source","constant|gear_value|affix_value1|affix_value2");
            e.counterKey=Int(row,"counter_key");
            e.stackKey=Int(row,"stack_key");e.stackPolicy=Token(row,"stack_policy","stack|replace_source|highest");
            e.presentationSkill=Int(row,"presentation_skill",-1,65535);
            e.emitAction=!row.HasMember("emit_action") || Int(row,"emit_action",0,1)!=0;
            if(!e.emitAction && !In(e.op,"promote_buff|buff|copy_buff|shield"))throw std::runtime_error("silent effect requires buff or shield operation");
            e.checkSkillImmunity=!row.HasMember("check_skill_immunity") || Int(row,"check_skill_immunity",0,1)!=0;
            if(!e.checkSkillImmunity && !In(e.op,"buff|copy_buff"))throw std::runtime_error("skill immunity policy requires buff operation");
            e.parameterCount=row.HasMember("parameter_count")?Int(row,"parameter_count",0,4):1;
            e.originLevel=row.HasMember("origin_level")?Int(row,"origin_level",0,65535):0;
            if(e.originLevel && !In(e.op,"buff|copy_buff|shield"))throw std::runtime_error("fixed origin level requires buff or shield operation");
            e.originSkill=row.HasMember("origin_skill")?Int(row,"origin_skill",-1,65535):-1;
            if(e.originSkill>=0 && !In(e.op,"promote_buff|buff|copy_buff|shield"))throw std::runtime_error("fixed origin skill requires buff or shield operation");
            if((e.op=="copy_buff" && e.parameterCount) || (!In(e.op,"buff|copy_buff") && e.parameterCount!=1))throw std::runtime_error("invalid buff parameter count");
            e.actionLimit=Int(row,"per_action",0,65535);e.uniqueTargets=Int(row,"unique_targets",0,65535);
            e.affix=Int(row,"affix_id");e.affixScope=Token(row,"affix_scope","owner|team_highest|team_highest_value2");e.affixAliveOnly=Int(row,"affix_alive_only",0,1)!=0;
            if(e.bindingScope!="owner" && e.bindingScope!="source_mark" && e.bindingScope!="target_mark" && e.affix)throw std::runtime_error("invalid team binding modifier");
            e.growthBasis=Str(row,"growth_basis");e.argumentRole=Token(row,"argument_role","fixed|regular|tactic|all|revive");
            e.basisCap=Str(row,"basis_cap");
            e.ratioDivisor=Int(row,"ratio_divisor",1,1000000);
            if(e.ratioSource=="constant" && e.ratioDivisor!=10000)throw std::runtime_error("constant coefficient cannot use a dynamic divisor");
            if(e.basisCap!="none" && !Field(e.basisCap,e.event))throw std::runtime_error("unavailable basis cap");
            if(!Field(e.growthBasis,e.event))throw std::runtime_error("unavailable growth basis");
            if(e.affix && !affixIds.count(e.affix))throw std::runtime_error("unknown effect affix");
            e.basis = Str(row, "basis"); e.capBasis = Str(row, "cap_basis");
            if (!Field(e.basis,e.event) || !Field(e.capBasis,e.event)) throw std::runtime_error("unavailable basis/cap_basis for " + e.event);
            const bool levelRatio=FactId(e.basis,"source_skill_level_",65535) && ((e.event=="before_counter" && e.op=="set_parameter") || (e.event=="before_periodic_proc" && e.op=="add_amount_bonus"));
            const int ratioLimit=levelRatio?10000000:1000000;
            e.ratio = Int(row, "ratio_bp", -ratioLimit, ratioLimit); e.growth = Int(row, "growth_bp", -10000, 10000);
            e.flat = Int(row, "flat", -1000000, 1000000); e.cap = Int(row, "cap_bp", 0, 1000000);
            if(e.op=="buff" && !e.parameterCount && (e.basis!="one" || e.ratio || e.growth || e.flat || e.cap))throw std::runtime_error("invalid buff parameter count");
            if(e.capRatioSource!="constant" && !e.cap)throw std::runtime_error("dynamic cap requires positive cap coefficient");
            e.duration = Int(row, "duration", 0, 255); e.probability = Int(row, "probability_bp", 0, 10000);
            if(e.probabilitySource!="constant" && (e.op!="chance_gate" || !e.affix || static_cast<int64_t>(e.probability)*chanceMaximum.at({e.affix,e.probabilitySource})/10000>10000))throw std::runtime_error("invalid dynamic probability contract");
            const std::string durationSource=row.HasMember("duration_source")?Token(row,"duration_source","constant|event_duration"):"constant";
            if(durationSource!="constant") {
                if(!In(e.op,"shield|buff|copy_buff") || !Field(durationSource,e.event) || e.duration)throw std::runtime_error("invalid dynamic duration source");
                // Internal execution marker; the formal table keeps duration=0
                // and names the event-duration policy explicitly.
                e.duration=-1;
            }
            e.turnLimit = Int(row, "per_turn", 0, 65535); e.battleLimit = Int(row, "per_battle", 0, 65535);
            e.argument = Int(row, "argument", 0,e.op=="reset_counter"?std::numeric_limits<int>::max():65535); e.conditions = Conditions(row,e.event); e.description = Str(row, "description");
            e.queryEffect=row.HasMember("query_effect")?Int(row,"query_effect",0,65535):0;
            e.queryAttribute=row.HasMember("query_attribute")?Int(row,"query_attribute",0,65535):0;
            e.queryParameter=row.HasMember("query_parameter")?Int(row,"query_parameter",0,3):0;
            e.queryLevel=row.HasMember("query_level")?Int(row,"query_level",0,65535):0;
            if(e.queryEffect?(e.op!="buff" || e.queryAttribute<101 || e.queryAttribute>120 || e.queryParameter>=e.parameterCount):(e.queryAttribute || e.queryParameter || e.queryLevel))throw std::runtime_error("invalid passive attribute parameter source");
            if(In(e.op,"cleanse|dispel") && (e.argument || e.duration || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<=0 || e.flat>65535))throw std::runtime_error("invalid buff removal operation");
            if(e.op=="strike" && (e.event!="after_primary_hit" || e.argument>2 || e.duration || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<=0))throw std::runtime_error("invalid computed strike operation");
            if(e.op=="apply_skill_passives" && (e.event!="after_primary_hit" || !e.argument || e.duration))throw std::runtime_error("invalid skill passive operation");
            if(e.op=="promote_buff" && (e.event!="after_counter_success" || e.target!="target" || !e.argument || e.originSkill<=0 || e.presentationSkill<=0 || e.emitAction || e.duration || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<=0))throw std::runtime_error("invalid buff promotion operation");
            if(e.op=="consume_periodic" && (e.event!="after_landed_skill" || e.target!="target" || !e.argument || e.basis!="target_owned_buff_remaining_"+std::to_string(e.argument) || e.probability!=10000 || e.duration || e.flat || e.growth || e.budget!="none"))throw std::runtime_error("invalid periodic consumption operation");
            if(e.op=="trigger_periodic" && (e.event!="after_landed_skill" || e.target!="target" || !e.argument || e.basis!="one" || e.ratio || e.growth || e.cap || e.duration || e.flat<0 || e.budget!="none"))throw std::runtime_error("invalid periodic trigger operation");
            if(e.op=="extend_owned_buff" && (e.event!="after_periodic_proc" || e.target!="target" || !e.argument || e.basis!="one" || e.ratio || e.growth || e.cap || e.duration<1 || e.flat<0 || e.probability!=10000 || e.budget!="none"))throw std::runtime_error("invalid owned buff extension");
            if(e.op=="reserve_overheal" && (e.event!="after_heal" || e.target!="self_any" || e.basis!="overheal" || e.ratio<0 || e.ratio>10000 || e.argument || e.flat || e.duration || e.cap || e.growth || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid overheal reservation");
            if(e.op=="split_heal" && (e.event!="after_heal" || !In(e.target,"other_healed_allies|lowest_two_other_healed_allies") || e.basis!="overheal" || e.argument || e.flat || e.duration || e.growth || e.probability!=10000 || e.budget!="none"))throw std::runtime_error("invalid healing distribution");
            if(In(e.target,"other_healed_allies|lowest_two_other_healed_allies") && e.op!="split_heal")throw std::runtime_error("healing distribution selector requires split healing");
            if(e.amountBudget!="none" && (!In(e.op,"rage|heal|restore_hp|damage|shield") || e.counterScope!="source" || !e.cap))throw std::runtime_error("invalid amount budget contract");
            if(e.op=="copy_buff" && (!In(e.event,"after_buff|buff_attempt_applied") || e.argument || e.duration!=-1 || e.basis!="one" || e.ratio || e.growth || e.flat || e.cap))throw std::runtime_error("invalid buff copy contract");
            if (e.description.empty()) throw std::runtime_error("missing generated description");
            if ((In(e.op,"buff|extend_buff") || (e.op == "cooldown" && e.argumentRole=="fixed")) && !e.argument) throw std::runtime_error("missing effect argument");
            if(e.argumentRole!="fixed" && (e.op!="cooldown" || e.argument))throw std::runtime_error("invalid skill role argument");
            if(e.op=="gate" && (!(e.counterScope=="target"?In(e.target,"target|target_any"):In(e.target,"self|self_any")) || e.probability!=10000 || e.basis!="one" || e.ratio || e.growth || e.flat || e.cap || e.duration || e.argument))throw std::runtime_error("invalid event gate");
            if(e.op=="chance_gate" && (!(e.counterScope=="target"?In(e.target,"target|target_any"):In(e.target,"self|self_any")) || e.basis!="one" || e.ratio || e.growth || e.flat || e.cap || e.duration || e.argument || e.budget!="none"))throw std::runtime_error("invalid chance gate");
            if(e.op=="reset_counter" && (!e.argument || !In(e.target,"self|self_any") || e.counterScope!="source" || e.basis!="one" || e.ratio || e.growth || e.flat || e.cap || e.duration || e.probability!=10000 || e.probabilitySource!="constant" || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid state reset operation");
            if(e.op=="add_duration" && (!In(e.event,"accepted_control|before_shield|before_buff_attempt") || e.target!="target" || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>255 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid duration addition");
            if((e.op=="passive_damage" && !In(e.event,"after_guard_hp|kill_followup_damage|shield_lost|after_primary_hit|after_dodge|after_landed_skill")) || (e.op=="add_event_bonus" && e.event!="shield_lost"))throw std::runtime_error("shield result operation requires shield loss");
            if(e.op=="add_event_bonus" && (e.target!="self" || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid event coefficient addition");
            if(e.op=="add_parameter_flat" && (!In(e.event,"before_attribute_growth|before_buff|before_shield|before_passive_parameters|before_passive_raw_parameters|before_buff_attempt|before_critical") || e.target!="target" || e.argument>(e.event=="before_passive_raw_parameters"?4:e.event=="before_critical"?1:3) || (e.event!="before_buff_attempt" && (e.basis!="one" || e.ratio)) || e.growth || e.cap || (e.event=="before_shield" && e.flat<0)))throw std::runtime_error("invalid parameter addition");
            if(In(e.op,"state_set|state_add") && ((e.counterScope=="source"?!In(e.target,"self|self_any"):e.counterScope=="target"?!In(e.target,"target|target_any"):true) || e.duration || e.probability!=10000 || e.budget!="none" || e.cap))throw std::runtime_error("invalid numeric state operation");
            if(e.op=="mark" && (e.bindingScope!="owner" || e.argument || e.probability!=10000 || e.budget!="none" || e.counterScope!="source"))throw std::runtime_error("invalid timed mark operation");
            if(e.op=="extend_origin_buffs" && (e.event!="after_periodic_damage" || e.target!="target_any" || !e.argument || e.flat<1 || e.flat>255 || e.duration<1 || e.duration>255 || e.basis!="one" || e.ratio || e.growth || e.cap || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid origin buff extension");
            if(e.event=="before_shield" && (!In(e.op,"add_amount_bonus|add_parameter_flat|add_duration") || e.probability!=10000 || e.budget!="none" || (e.bindingScope=="target_team" && (e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets))))throw std::runtime_error("shield query must be deterministic");
            if(e.event=="accepted_control" && !In(e.op,"gate|chance_gate|add_duration"))throw std::runtime_error("accepted control requires gates or duration addition");
            if ((e.op == "buff" || e.op == "shield") && !e.duration) throw std::runtime_error("missing duration");
            if (e.op == "set_duration" && (e.basis != "one" || e.ratio || e.growth || e.flat < 0 || e.flat > 255)) throw std::runtime_error("duration modifier must be a fixed value in 0..255");
            if ((e.op == "set_duration" || e.op == "scale_parameters") && !In(e.event,"before_buff|before_buff_attempt")) throw std::runtime_error("modifier requires before_buff event");
            if ((e.op == "set_duration" || e.op == "scale_parameters" || e.op == "scale_amount") && e.target != "target") throw std::runtime_error("modifier must target its owning battle operation");
            if ((e.op=="cooldown" && !In(e.target,"self|self_any")) || (e.op=="rage" && !In(e.target,"self|self_any|highest_gear_ally"))) throw std::runtime_error("source effect requires self target");
            if (e.op == "scale_amount" && !In(e.event,"before_opening_action|before_passive_heal|before_attribute_transfer|before_periodic_proc|after_periodic_proc|before_passive_value|before_kill_followup|before_self_revive|before_dot|finalize_heal|before_passive_revive|before_passive_parameters|after_passive_attribute_roll|before_buff_attempt|before_passive_list|before_self_damage")) throw std::runtime_error("amount modifier requires an amount query event");
            if(e.event=="before_opening_action" && (e.op!="scale_amount" || e.target!="target" || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("invalid opening action plan");
            if(e.event=="before_attribute_transfer" && (e.op!="scale_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("attribute transfer query must be deterministic");
            if(e.event=="before_attribute_growth") {
                if(!In(e.op,"set_parameter|add_parameter_flat") || e.basis!="one" || e.ratio || e.growth || e.cap || e.duration || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none")throw std::runtime_error("invalid attribute growth plan");
                if(e.op=="add_parameter_flat"?e.argument!=2:e.argument==2 || e.flat<0 || e.flat>(e.argument==0?65535:e.argument==1?255:10000))throw std::runtime_error("invalid attribute growth parameter");
            }
            if(e.event=="before_guard_candidate" && (e.op!="set_parameter" || e.argument || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("invalid guard candidate flag");
            if(e.event=="before_debuff_resistance" && (e.op!="add_amount_bonus" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("resistance query must be deterministic");
            if(e.event=="after_hp_observed" && (e.op!="gate" || e.probability!=10000 || e.budget!="none"))throw std::runtime_error("HP observation may only record deterministic state");
            if(e.event=="before_passive_heal" && !In(e.op,"gate|scale_amount|multiply_amount|set_parameter|buff"))throw std::runtime_error("invalid passive healing plan");
            if(e.event=="before_passive_heal" && In(e.op,"scale_amount|multiply_amount|set_parameter") && (e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || (e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.argument>2 || e.flat<0 || e.flat>1))))throw std::runtime_error("invalid passive healing modifier");
            if(e.op=="combine_remaining" && (e.event!="before_defense" || e.target!="target"))throw std::runtime_error("invalid remaining fraction modifier");
            if(e.op=="combine_remaining" && (e.ratioSource!="constant" || e.growth || e.cap || !(In(e.basis,"gear_value|affix_value1")?e.ratio>=0 && e.ratio<=10000 && !e.flat:e.basis=="one" && !e.ratio && e.flat>=0 && e.flat<=10000)))throw std::runtime_error("invalid remaining fraction coefficient");
            if ((e.op=="add_amount_bonus" && !In(e.event,"before_thorns_roll|owned_buff_hit|before_debuff_resistance|before_share_damage|before_periodic_proc|before_dot|before_heal|before_direct_damage|before_action_order|before_shield_damage|before_guard|before_critical|before_received_heal|before_attack|before_tactic_cost|before_summon_attack|before_summon_hp|landed_attack|before_shield|before_buff_attempt")) || (e.op=="add_parameter_bonus" && !In(e.event,"before_buff|before_attack|before_passive_parameters|before_passive_raw_parameters|before_buff_attempt")) ||
                ((e.op=="add_amount_bonus" || e.op=="add_parameter_bonus") && e.target!="target")) throw std::runtime_error("incompatible bonus modifier");
            if(e.op=="add_parameter_bonus" && e.argument>(e.event=="before_passive_raw_parameters"?4:3)) throw std::runtime_error("invalid modifier parameter index");
            if(e.op=="set_parameter" && (!In(e.event,"after_passive_targets|before_attribute_growth|before_guard_candidate|before_passive_heal|before_periodic_proc|before_effect_attempt|before_kill_followup|before_self_revive|before_skill_growth|before_counter|before_target_plan|before_protection|before_buff|before_shield_damage|finalize_heal|before_skill_usefulness|before_revive_eligibility|before_shield_passive|before_passive_parameters|before_passive_raw_parameters|before_kill_action|before_action_repeat|before_buff_attempt|before_skill_sequence|before_critical|before_combo_amount|before_sacrifice_damage") || e.target!="target" || e.argument>(e.event=="before_passive_raw_parameters"?4:In(e.event,"after_passive_targets|before_attribute_growth|before_kill_followup|before_counter|before_target_plan|before_protection|before_buff|before_passive_parameters|before_buff_attempt|before_skill_sequence")?3:In(e.event,"before_passive_heal|before_sacrifice_damage")?2:In(e.event,"before_effect_attempt|before_skill_growth|before_kill_action|before_skill_usefulness")?1:0)))throw std::runtime_error("invalid set parameter operation");
            if(e.event=="after_passive_targets") {
                if(!In(e.op,"gate|set_parameter") || e.probability!=10000 || e.budget!="none")throw std::runtime_error("invalid passive target plan");
                if(e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.duration || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.flat<0 || e.flat>(e.argument==0?2:e.argument==1?9:e.argument==2?65535:1)))throw std::runtime_error("invalid passive target parameter");
            }
            if(e.event=="before_periodic_proc" && e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.flat<0 || e.flat>1 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid periodic eligibility flag");
            if(e.event=="before_effect_attempt" && (!In(e.op,"gate|set_parameter") || e.probability!=10000 || e.budget!="none" || (e.op=="set_parameter" && (e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.growth || e.cap || e.duration || !(e.argument==0?e.basis=="one" && !e.ratio && e.flat>=0 && e.flat<=1:(e.basis=="base_duration" && e.ratio==10000 && !e.flat) || (e.basis=="one" && !e.ratio && e.flat>=0 && e.flat<=255))))))throw std::runtime_error("invalid effect attempt query");
            if(e.event=="before_passive_value" && (!In(e.op,"scale_amount|multiply_amount") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("invalid passive value query");
            if(e.event=="before_kill_followup" && (!In(e.op,"gate|scale_amount|set_parameter") || e.probability!=10000 || (e.op!="gate" && (e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none")) || (e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>(e.argument==1?1000000:1)))))throw std::runtime_error("invalid kill followup query");
            if(e.event=="before_self_revive" && (!In(e.op,"gate|scale_amount|set_parameter") || e.probability!=10000 || e.budget!="none"))throw std::runtime_error("invalid self revival plan");
            if(e.event=="before_skill_growth" && (e.op!="set_parameter" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || e.basis!="one" || e.ratio || e.cap || e.growth || e.flat<0 || e.flat>65535))throw std::runtime_error("invalid skill growth query");
            if(e.event=="before_counter" && (!In(e.op,"chance_gate|set_parameter") || (e.op=="set_parameter" && (e.argument>3 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || e.cap || e.growth))))throw std::runtime_error("invalid counter query");
            if(e.event=="before_sacrifice_damage" && (e.op!="set_parameter" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || e.cap || e.growth || (e.argument==2 && (e.basis!="one" || e.ratio || e.flat<0 || e.flat>1000000))))throw std::runtime_error("invalid sacrifice damage query");
            if(e.event=="before_protection" && (e.op!="set_parameter" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || e.cap || e.growth))throw std::runtime_error("invalid protection query");
            if(e.event=="before_target_plan" && (e.op!="set_parameter" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.actionLimit || e.interval || e.uniqueTargets || e.budget!="none" || e.duration || e.basis!="one" || e.ratio || e.cap || e.growth || e.flat<0 || (e.argument==0 && e.flat>2) || (e.argument==1 && e.flat>19) || (e.argument==2 && e.flat>9)))throw std::runtime_error("invalid target plan query");
            if(e.event=="before_skill_sequence" && (!In(e.op,"set_parameter|state_set|state_add") || e.probability!=10000 || e.budget!="none" || (e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>(e.argument==0?255:1)))))throw std::runtime_error("invalid skill sequence plan");
            if(e.event=="before_passive_list" && (!In(e.op,"replace_passive_list|scale_amount") || e.target!="target" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none" || e.basis!="one" || e.ratio || e.growth || e.cap || e.duration))throw std::runtime_error("invalid passive list query");
            if(e.op=="replace_passive_list" && (e.event!="before_passive_list" || !e.argument || e.flat))throw std::runtime_error("invalid passive list replacement");
            if(e.event=="before_passive_list" && e.op=="scale_amount" && (e.argument || e.flat<0 || e.flat>1))throw std::runtime_error("passive list flag must be boolean");
            if(e.event=="before_combo_amount" && (e.op!="set_parameter" || e.argument || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1000000 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid combo coefficient query");
            if(e.event=="before_self_damage" && (e.op!="scale_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid self damage limit");
            if(e.op=="replace_buff" && (!In(e.event,"before_buff|before_buff_attempt") || e.target!="target" || !e.argument || e.basis!="one" || e.ratio || e.growth || e.flat || e.cap || e.probability!=10000 || e.budget!="none"))throw std::runtime_error("invalid attempted buff replacement");
            if(e.event=="before_passive_raw_parameters" && (!In(e.op,"set_parameter|add_parameter_flat|add_parameter_bonus") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("raw parameter query must be deterministic");
            if(e.event=="before_action_repeat" && (e.op!="set_parameter" || e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1000000 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid repeated action scale");
            if(e.event=="accepted_kill_action" && (e.op!="gate" || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("accepted kill action requires unlimited deterministic record");
            if(In(e.event,"before_passive_parameters|after_passive_attribute_roll") && (!In(e.op,"set_parameter|scale_amount|add_parameter_flat|add_parameter_bonus") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("passive query must be a deterministic modifier");
            if(In(e.event,"before_passive_parameters|after_passive_attribute_roll") && e.op=="scale_amount" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1))throw std::runtime_error("passive query flag must be a constant boolean");
            if(e.event=="before_kill_action" && (!In(e.op,"gate|chance_gate|set_parameter") || (e.op!="chance_gate" && e.probability!=10000) || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("invalid kill action query");
            if(e.event=="before_kill_action" && e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>(e.argument==0?2:1000000)))throw std::runtime_error("invalid kill action parameter");
            if(In(e.event,"finalize_heal|before_passive_revive|before_skill_usefulness|before_revive_eligibility|before_shield_passive")) {
                const bool allowed=In(e.event,"before_skill_usefulness|before_revive_eligibility|before_shield_passive")?e.op=="set_parameter":e.event=="before_passive_revive"?e.op=="scale_amount":In(e.op,"scale_amount|set_parameter");
                if(!allowed || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none")throw std::runtime_error("healing/usefulness query must be deterministic");
                if(e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1))throw std::runtime_error("query flag must be a constant boolean");
            }
            if((e.actionLimit && e.counterScope=="team") || (e.uniqueTargets && e.counterScope!="source"))throw std::runtime_error("invalid action budget scope");
            if((e.stackKey>0)!=(e.stackPolicy!="stack") || (e.stackKey && e.op!="buff")) throw std::runtime_error("invalid buff stacking policy");
            if(e.op=="multiply_amount" && (!In(e.event,"before_thorns_amount|before_hp_restore|before_passive_heal|before_passive_value|before_speed|before_share_damage|before_stat|before_direct_amount") || e.target!="target"))throw std::runtime_error("invalid sequential multiplier");
            if(In(e.event,"before_thorns_roll|before_thorns_amount") && (e.op!=(e.event=="before_thorns_roll"?"add_amount_bonus":"multiply_amount") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("thorns query must be deterministic");
            if(e.event=="before_hp_restore" && (e.op!="multiply_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none" || e.duration))throw std::runtime_error("HP restoration query must be deterministic");
            if(e.event=="before_direct_amount" && (e.op!="multiply_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("direct amount query must be deterministic");
            if(e.event=="before_stat" && (e.op!="multiply_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("attribute query must be deterministic");
            if(e.event=="before_share_damage" && (!In(e.op,"multiply_amount|add_amount_bonus") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("share query must be a deterministic stat modifier");
            if(e.event=="before_speed" && (e.op!="multiply_amount" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))
                throw std::runtime_error("speed query must be a deterministic stat modifier");
            if(e.event=="before_action_order" && (e.op!="add_amount_bonus" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("order query must be a deterministic modifier");
            if(e.event=="before_tactic_cost" && (e.op!="add_amount_bonus" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("cost query must be a deterministic modifier");
            if(In(e.event,"before_summon_attack|before_summon_hp") && (e.op!="add_amount_bonus" || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("summon query must be a deterministic modifier");
            if(e.event=="before_attack" && (!In(e.op,"add_amount_bonus|add_parameter_bonus") || e.argument>2 || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))
                throw std::runtime_error("attack query must be a deterministic stat modifier");
            if(e.event=="before_critical" && (!In(e.op,"add_amount_bonus|set_parameter|add_parameter_flat") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none" || (e.op=="set_parameter" && (e.basis!="one" || e.ratio || e.growth || e.cap || e.flat<0 || e.flat>1))))throw std::runtime_error("invalid critical plan");
            if(In(e.event,"before_guard|before_defense|before_received_heal") &&
                (e.op!=(e.event=="before_defense"?"combine_remaining":"add_amount_bonus") || e.probability!=10000 || e.turnLimit || e.battleLimit || e.interval || e.actionLimit || e.uniqueTargets || e.budget!="none"))throw std::runtime_error("stat query must be a deterministic modifier");
            groups.insert(e.group); next.effects_.push_back(e);
        });
        Read(dir,"combat_event_policy",[&](const Value& row){
            const auto event=Token(row,"event",EventVocabulary);
            if(!next.eventDepthExtensions_.emplace(event,Int(row,"extra_depth",0,7)).second)throw std::runtime_error("conflicting event policy");
            if(Str(row,"description").empty())throw std::runtime_error("missing event policy description");
        });
        std::map<int,std::pair<int,std::string>> stackContracts;
        std::map<int,std::tuple<int,std::string,bool>> affixContracts;
        std::set<int> affixGroups;
        for(const auto& e:next.effects_) {
            auto hasEarlier=[&](const std::string& op) {
                return std::any_of(next.effects_.begin(),next.effects_.end(),[&](const Effect& producer) {
                    return producer.group==e.group && producer.event==e.event && producer.op==op
                        && std::make_pair(producer.priority,producer.id)<std::make_pair(e.priority,e.id);
                });
            };
            if(e.ratioSource=="event_bonus" && !hasEarlier("add_event_bonus"))throw std::runtime_error("missing prior event coefficient producer");
            if((e.basis=="event_hp_loss" || e.capBasis=="event_hp_loss") && !hasEarlier("passive_damage"))throw std::runtime_error("missing prior HP loss producer");
            const auto signature=std::make_tuple(e.affix,e.affixScope,e.affixAliveOnly);
            const auto inserted=affixContracts.emplace(e.group,signature);
            if(!inserted.second && inserted.first->second!=signature)throw std::runtime_error("conflicting effect group affix binding");
            if(e.affix)affixGroups.insert(e.group);
            auto check=[&](const std::string& field){if(!e.affix && field.compare(0,6,"affix_")==0)throw std::runtime_error("affix fact requires affix binding");};
            check(e.basis);check(e.capBasis);check(e.growthBasis);check(e.basisCap);check(e.ratioSource);check(e.capRatioSource);for(const auto& c:e.conditions){check(c.field);check(c.otherField);}
            auto checkGate=[&](const std::string& field){
                const int id=GateFact(field);if(!id)return;
                const auto* gate=next.EffectById(id);
                if(!gate || !In(gate->op,"gate|chance_gate") || gate->group!=e.group || gate->event!=e.event || std::make_pair(gate->priority,gate->id)>=std::make_pair(e.priority,e.id))throw std::runtime_error("invalid or cyclic event gate reference");
            };
            checkGate(e.basis);checkGate(e.capBasis);checkGate(e.growthBasis);checkGate(e.basisCap);for(const auto& c:e.conditions){checkGate(c.field);checkGate(c.otherField);}
            auto checkCount=[&](const std::string& field){if(field=="effect_battle_count" && e.counterScope!="source")throw std::runtime_error("effect count requires source scope");};
            checkCount(e.basis);checkCount(e.capBasis);checkCount(e.growthBasis);checkCount(e.basisCap);for(const auto& c:e.conditions){checkCount(c.field);checkCount(c.otherField);}
            auto counterReference=[&](int id,bool target=false)->const Effect* {
                const auto* record=next.EffectById(id);
                if(!record || record->op!="gate" || record->counterScope!=(target?"target":"source"))throw std::runtime_error("invalid persistent counter reference");
                return record;
            };
            auto checkCounter=[&](const std::string& field){const int id=CounterFact(field);if(id)counterReference(id,TargetCounterFact(field));};
            checkCounter(e.basis);checkCounter(e.capBasis);checkCounter(e.growthBasis);checkCounter(e.basisCap);for(const auto& c:e.conditions){checkCounter(c.field);checkCounter(c.otherField);}
            auto checkState=[&](const std::string& field) {
                const int id=StateFact(field);if(!id)return;const auto* record=next.EffectById(id);
                const bool target=field.compare(0,7,"target_")==0;
                if(!record || !In(record->op,"state_set|state_add") || record->group!=e.group || record->counterScope!=(target?"target":"source"))throw std::runtime_error("invalid numeric state reference");
            };
            checkState(e.basis);checkState(e.capBasis);checkState(e.growthBasis);checkState(e.basisCap);for(const auto& c:e.conditions){checkState(c.field);checkState(c.otherField);}
            if(In(e.op,"state_set|state_add") && e.counterKey) {
                const auto* record=next.EffectById(e.counterKey);
                if(!record || !In(record->op,"state_set|state_add") || record->group!=e.group || record->counterScope!=e.counterScope)throw std::runtime_error("invalid numeric state alias");
            }
            auto checkMark=[&](const std::string& field){const int id=MarkFact(field);if(!id)return;const auto* record=next.EffectById(id);if(!record || record->op!="mark" || record->group!=e.group)throw std::runtime_error("invalid timed mark reference");};
            checkMark(e.basis);checkMark(e.capBasis);checkMark(e.growthBasis);checkMark(e.basisCap);for(const auto& c:e.conditions){checkMark(c.field);checkMark(c.otherField);}
            if(In(e.bindingScope,"source_mark|target_mark") && std::none_of(next.effects_.begin(),next.effects_.end(),[&](const Effect& r){return r.group==e.group && r.op=="mark";}))throw std::runtime_error("mark binding has no producer");
            if(e.op=="mark" && e.counterKey){const auto* r=next.EffectById(e.counterKey);if(!r || r->op!="mark" || r->group!=e.group)throw std::runtime_error("invalid timed mark alias");}
            if(e.op=="reset_counter") {
                const auto* record=counterReference(e.argument);
                if(record->turnLimit || record->battleLimit || record->interval || record->actionLimit || record->uniqueTargets || record->budget!="none")throw std::runtime_error("state reset requires unlimited source gate");
            }
            auto checkCategory=[&](const std::string& field){
                const int category=CategoryFact(field);if(!category)return;
                if(std::none_of(next.buffCategories_.begin(),next.buffCategories_.end(),[&](const std::pair<const int,int>& p){return p.second==category;}))throw std::runtime_error("unknown buff category fact");
            };
            checkCategory(e.basis);checkCategory(e.capBasis);checkCategory(e.growthBasis);checkCategory(e.basisCap);for(const auto& c:e.conditions){checkCategory(c.field);checkCategory(c.otherField);}
        }
        for(const auto& e:next.effects_) if(e.stackKey) {
            const auto signature=std::make_pair(e.argument,e.stackPolicy);
            const auto inserted=stackContracts.emplace(e.stackKey,signature);
            if(!inserted.second && inserted.first->second!=signature) throw std::runtime_error("conflicting buff stacking contract");
        }
        std::map<int,int> baseArtifacts;
        Read(dir,"fabao",[&](const Value& row){ if(Int(row,"equip",0,1)) baseArtifacts[Int(row,"id",1)]=Int(row,"quality",1); });
        std::set<std::pair<int,int>> artifactKeys;
        std::map<int,std::string> gearGroupOwners;
        Read(dir,"combat_artifact",[&](const Value& row){
            Artifact a; a.id=Int(row,"id",1); a.family=Int(row,"family",1); a.quality=Int(row,"quality",1);
            a.rank=Int(row,"selection_rank"); a.exclusive=Str(row,"exclusive_group"); a.group=Int(row,"effect_group"); a.value=Int(row,"value",0,1000000);
            a.enabled=Int(row,"enabled",0,1)!=0;
            if(a.exclusive.empty() || !baseArtifacts.count(a.id) || baseArtifacts.at(a.id)!=a.quality ||
                (a.group && !groups.count(a.group)) || (a.enabled && (!a.group || Str(row,"status")!="complete"))) throw std::runtime_error("invalid artifact reference/status/quality");
            if(!artifactKeys.insert({a.family,a.quality}).second) throw std::runtime_error("duplicate artifact family/quality");
            if(a.group) {auto inserted=gearGroupOwners.emplace(a.group,"artifact:"+a.exclusive);if(!inserted.second && inserted.first->second!="artifact:"+a.exclusive)throw std::runtime_error("conflicting equipment effect group");}
            next.artifacts_[a.id]=a;
        });
        if(next.artifacts_.size()!=baseArtifacts.size()) throw std::runtime_error("missing equippable artifact binding");
        std::set<int> baseSuits;
        Read(dir,"suit",[&](const Value& row){
            baseSuits.insert(Int(row,"id",1));
            const auto& levels=Member(row,"suit");
            if(!levels.IsArray() || levels.Size()!=3) throw std::runtime_error("invalid suit piece tiers");
            for(rapidjson::SizeType level=0;level<levels.Size();++level) {
                const auto& tier=levels[level];
                if(!tier.IsArray()) throw std::runtime_error("invalid suit tier");
                for(rapidjson::SizeType index=0;index<tier.Size();++index) {
                    const auto& attr=tier[index];
                    if(!attr.IsArray() || attr.Size()!=3 || !attr[0].IsInt() || !attr[1].IsInt() || !attr[2].IsInt()) throw std::runtime_error("invalid suit attribute tuple");
                    // Existing item attribute protocol: 1..33, combat modifiers 50..54.
                    if(attr[0].GetInt()!=1 || !((attr[1].GetInt()>=1 && attr[1].GetInt()<=33) || (attr[1].GetInt()>=50 && attr[1].GetInt()<=54))) throw std::runtime_error("unsupported suit attribute protocol");
                }
            }
        });
        std::set<std::pair<int,int>> setKeys;
        Read(dir,"combat_set",[&](const Value& row){
            SetBonus s; s.suit=Int(row,"suit_id",1); s.pieces=Int(row,"pieces",1,4); s.group=Int(row,"effect_group"); s.value=Int(row,"value",0,1000000); s.enabled=Int(row,"enabled",0,1)!=0;
            if(!baseSuits.count(s.suit) || !setKeys.insert({s.suit,s.pieces}).second || (s.group && !groups.count(s.group)) ||
                (s.enabled && (!s.group || Str(row,"status")!="complete"))) throw std::runtime_error("invalid set reference/status/threshold");
            if(s.group && !gearGroupOwners.emplace(s.group,"set:"+std::to_string(s.suit)).second) throw std::runtime_error("conflicting equipment effect group");
            next.sets_.push_back(s);
        });
        std::set<int> slotPriorities;
        Read(dir,"combat_loadout_slot",[&](const Value& row){
            int slot=Int(row,"id",1,6), priority=Int(row,"priority",1);
            if(!slotPriorities.insert(priority).second) throw std::runtime_error("ambiguous loadout slot priority");
            std::string kind=Token(row,"kind","equipment|artifact");
            if((slot<=4)!=(kind=="equipment")) throw std::runtime_error("loadout kind disagrees with slot protocol");
            next.slots_[slot]={kind,priority};
        });
        if(next.slots_.size()!=6) throw std::runtime_error("missing loadout slot policy");
        std::map<int,std::tuple<std::string,int,int,int,int,int>> counterContracts;
        std::map<int,std::string> amountContracts;
        for(const auto& e:next.effects_) {
            if(e.affix && gearGroupOwners.count(e.group))throw std::runtime_error("affix cannot alias equipment group");
            auto requireEquipmentFact=[&](const std::string& field){if(field=="source_is_group_hp_leader" && !gearGroupOwners.count(e.group))throw std::runtime_error("equipment leader fact requires equipment group");};
            requireEquipmentFact(e.basis);requireEquipmentFact(e.capBasis);requireEquipmentFact(e.growthBasis);requireEquipmentFact(e.basisCap);for(const auto& c:e.conditions){requireEquipmentFact(c.field);requireEquipmentFact(c.otherField);}
            if(e.op=="combine_remaining") {
                int maximum=e.basis=="affix_value1"?affixMaximum[e.affix]:0;
                if(e.basis=="gear_value") {
                    for(const auto& a:next.artifacts_)if(a.second.group==e.group)maximum=std::max(maximum,a.second.value);
                    for(const auto& s:next.sets_)if(s.group==e.group)maximum=std::max(maximum,s.value);
                }
                if(static_cast<int64_t>(maximum)*e.ratio/10000>10000)throw std::runtime_error("remaining fraction outside 0..10000");
            }
            if((e.ratioSource=="gear_value" || e.capRatioSource=="gear_value" || e.basis=="gear_value" || e.capBasis=="gear_value") && !gearGroupOwners.count(e.group)) throw std::runtime_error("gear value requires equipment group");
            if(e.target=="highest_gear_ally" && !gearGroupOwners.count(e.group)) throw std::runtime_error("equipment selector requires equipment group");
            auto signature=std::make_tuple(e.counterScope,e.turnLimit,e.battleLimit,e.interval,e.actionLimit,e.uniqueTargets);
            auto inserted=counterContracts.emplace(e.counterKey?e.counterKey:e.id,signature);
            if(!inserted.second && inserted.first->second!=signature) throw std::runtime_error("incompatible shared counter contract");
            const std::string amountContract=e.amountBudget=="none"?"none":e.amountBudget+":"+std::to_string(e.group)+":"+std::to_string(e.cap)+":"+e.capBasis+":"+e.capRatioSource;
            const auto amountInserted=amountContracts.emplace(e.counterKey?e.counterKey:e.id,amountContract);
            if(!amountInserted.second && amountInserted.first->second!=amountContract)throw std::runtime_error("incompatible shared amount budget contract");
        }
        std::set<std::pair<int,int>> bindings;
        Read(dir, "combat_binding", [&](const Value& row) {
            Binding b; b.hero = Int(row, "hero_id", 1, 65535); b.branch = Int(row, "branch", 1, 2);
            b.enabled = Int(row, "enabled", 0, 1) != 0;
            if (b.enabled && Str(row,"status") != "complete") throw std::runtime_error("incomplete branch cannot be enabled");
            if (!bindings.insert({b.hero, b.branch}).second) throw std::runtime_error("conflicting hero/branch binding");
            const Value& refs = Member(row, "groups");
            if (!refs.IsArray() || refs.Empty()) throw std::runtime_error("empty effect groups");
            std::set<int> unique;
            for (rapidjson::SizeType i = 0; i < refs.Size(); ++i) {
                if (!refs[i].IsInt() || !groups.count(refs[i].GetInt()) || !unique.insert(refs[i].GetInt()).second) throw std::runtime_error("missing/duplicate effect group");
                if(gearGroupOwners.count(refs[i].GetInt()) || affixGroups.count(refs[i].GetInt())) throw std::runtime_error("hero binding cannot alias an equipment group");
                b.groups.push_back(refs[i].GetInt());
            }
            next.bindings_.push_back(b);
        });
        std::set<std::tuple<int,std::string,std::string,int>> targetOrder;std::set<int> targetIds;
        Read(dir,"combat_target_policy",[&](const Value& row) {
            TargetPolicy p;p.id=Int(row,"id",1);p.strategy=Int(row,"strategy_id",1,5);p.priority=Int(row,"priority");p.enabled=Int(row,"enabled",0,1)!=0;
            if(!targetIds.insert(p.id).second)throw std::runtime_error("duplicate target policy id");
            p.side=Token(row,"side","ally|enemy");p.role=Token(row,"role","any|regular|tactic|other");
            p.order=Token(row,"order","lowest_hp|unshielded_lowest_hp|highest_attack|fewest_owned_dots|most_owned_dots");
            p.tie=Token(row,"tie_break","position_asc|position_desc");
            const auto& buffs=Member(row,"count_buff_ids");if(!buffs.IsArray())throw std::runtime_error("target count buffs must be an array");
            std::set<int> unique;for(rapidjson::SizeType i=0;i<buffs.Size();++i) {const auto& buff=buffs[i];
                if(!buff.IsInt() || buff.GetInt()<1 || buff.GetInt()>65535 || !unique.insert(buff.GetInt()).second)throw std::runtime_error("invalid target count buff");
                p.buffs.push_back(buff.GetInt());
            }
            if(In(p.order,"fewest_owned_dots|most_owned_dots")!=!p.buffs.empty())throw std::runtime_error("invalid target count buff contract");
            if(!targetOrder.insert({p.strategy,p.side,p.role,p.priority}).second)throw std::runtime_error("conflicting target policy priority");
            if(Str(row,"description").empty())throw std::runtime_error("missing target policy description");
            next.targetPolicies_.push_back(p);
        });
        std::set<std::pair<int,int>> strategyOrder;
        Read(dir, "combat_strategy", [&](const Value& row) {
            Strategy s; s.id = Int(row, "id", 1); s.strategy = Int(row, "strategy_id", 1, 5); s.priority = Int(row, "priority");
            s.reserve = Int(row, "reserve", 0, 100); s.emergency = Int(row, "emergency", 0, 1) != 0;
            s.role = Token(row, "role", "tactic|regular|normal"); s.conditions = Conditions(row,"strategy"); s.description = Str(row, "description");
            if (!strategyOrder.insert({s.strategy, s.priority}).second) throw std::runtime_error("conflicting strategy priority");
            next.strategies_.push_back(s);
        });
        for (int strategy = 1; strategy <= 5; ++strategy) {
            const Strategy* last = nullptr;
            for (const auto& s : next.strategies_) if (s.strategy == strategy && (!last || s.priority > last->priority)) last = &s;
            if (!last || last->role != "normal" || !last->conditions.empty()) throw std::runtime_error("strategy requires unconditional normal fallback");
        }
        Read(dir,"combat_control",[&](const Value& row) {
            const int buff=Int(row,"buff_id",1,65535);
            ControlPolicy p; p.diminishing=Int(row,"diminishing",0,1)!=0;
            p.refresh=Int(row,"refresh_same_origin",0,1)!=0;
            p.bossMode=Token(row,"boss_mode","normal|replace|ignore");
            p.replacement=Int(row,"replacement_buff",0,65535); p.value=Int(row,"replacement_value",0,1000000); p.duration=Int(row,"replacement_duration",0,255);
            if(p.bossMode=="replace" && (!p.replacement || !p.duration || p.replacement==buff)) throw std::runtime_error("invalid boss control replacement");
            if(!next.controls_.emplace(buff,p).second) throw std::runtime_error("duplicate control buff");
        });
        Read(dir,"combat_periodic",[&](const Value& row) {
            Periodic p;
            p.buff=Int(row,"buff_id",1,65535);
            p.event=Token(row,"event","before_action|after_heal");
            p.outcome=Token(row,"outcome","damage|heal");
            p.formula=Token(row,"formula","sum|percent|percent_cap");
            p.basis=Token(row,"basis","one|target_hp|target_max_hp|input");
            p.paramA=Int(row,"param_a",0,3); p.paramB=Int(row,"param_b",-1,3); p.capParam=Int(row,"cap_param",-1,3);
            p.stackGroup=Int(row,"stack_group"); p.turnBudget=Int(row,"turn_budget",0,1)!=0;
            p.bonusBuff=Int(row,"bonus_buff",0,65535); p.bonus=Int(row,"bonus_bp",0,10000);
            p.bonusAffix=Int(row,"bonus_affix",0,65535);p.bonusCap=Int(row,"bonus_cap_bp",0,10000);
            p.zeroActionParameter=Int(row,"zero_action_parameter",-1,3);
            p.aggregation=Token(row,"aggregation","per_source|state_sum");
            if(p.bonusAffix && (!affixIds.count(p.bonusAffix) || !p.bonusCap)) throw std::runtime_error("invalid periodic affix/cap reference");
            if((p.basis=="input" && p.event!="after_heal") || (p.formula=="sum" && p.basis!="one") ||
                (p.formula!="sum" && p.paramB!=-1) || (p.formula=="percent_cap" && p.capParam<0) ||
                (p.formula!="percent_cap" && p.capParam!=-1) || (p.outcome=="heal" && (p.turnBudget || p.stackGroup)))
                throw std::runtime_error("incompatible periodic policy");
            if(Str(row,"description").empty()) throw std::runtime_error("missing periodic description");
            if(!next.periodic_.emplace(p.buff,p).second) throw std::runtime_error("duplicate periodic buff");
        });
        Read(dir, "combat_rule", [&](const Value& row) {
            const std::string key = Str(row, "key");
            if(In(key,"critical_chance_cap_bp|critical_multiplier_min_bp|critical_multiplier_max_bp")) {
                const bool chance=key=="critical_chance_cap_bp";
                if(!next.rules_.emplace(key,Int(row,"value",chance?0:10000,chance?10000:1000000)).second)throw std::runtime_error("duplicate shared rule");
                if(Str(row,"scope")!="all_units")throw std::runtime_error("shared rule scope must explicitly include base branches and enemies");
                return;
            }
            if(key=="vulnerability_multiplier_max_bp") {
                if(!next.rules_.emplace(key,Int(row,"value",10000,1000000)).second)throw std::runtime_error("duplicate shared rule");
                if(Str(row,"scope")!="all_units")throw std::runtime_error("shared rule scope must explicitly include base branches and enemies");
                return;
            }
            if(In(key,"revived_action_block_turns|shared_link_target_select|shared_link_target_count|action_attribute_stack_cap|boss_attack_weaken_cap_bp|boss_defense_weaken_cap_bp|defense_weaken_cap_bp|overheal_shield_conversion_cap_bp|buff_tick_same_action_skip|thorns_requires_hp_loss|thorns_cap_bp|thorns_per_turn|vulnerability_keep_highest|buff_refresh_same_origin|cooldown_tick_action_begin|rage_from_shared_damage")) {
                const int maximum=In(key,"buff_tick_same_action_skip|thorns_requires_hp_loss|vulnerability_keep_highest|buff_refresh_same_origin|cooldown_tick_action_begin|rage_from_shared_damage")?1:10000;
                if(!next.rules_.emplace(key,Int(row,"value",0,maximum)).second)throw std::runtime_error("duplicate shared rule");
                if(Str(row,"scope")!="all_units")throw std::runtime_error("shared rule scope must explicitly include base branches and enemies");
                return;
            }
            if (!In(key, "rage_max|shield_cap_bp|dot_max_stacks|dot_max_duration|secondary_depth_max|revive_per_target|extra_attack_per_turn|strategy_injured_hp_bp|shield_refresh_same_source|dot_poison_shared_budget|dot_turn_attack_bp|revive_per_source_target|control_reset_gap|control_immunity_threshold|control_reduce_threshold|control_duration_bp|control_min_duration|control_immunity_turns|boss_control_per_turn|revived_extra_block_turns|direct_multiplier_min_bp|direct_multiplier_max_bp|rage_extra_actor_turn|rage_extra_team_turn|rage_opening_team|rage_normal_hit|rage_regular_success|rage_damage_taken|rage_damage_events_turn|rage_kill|rage_first_death|rage_tactic_min_cost|shield_pierce_success_bp|guard_cap_bp|guard_multiplier_min_bp|ignore_defense_cap_bp|direct_hit_min_bp|direct_hit_max_bp|active_heal_bonus_min_bp|active_heal_bonus_max_bp|active_antiheal_enabled|revive_antiheal_enabled")) throw std::runtime_error("unknown shared rule: " + key);
            const bool flag = In(key,"shield_refresh_same_source|dot_poison_shared_budget|active_antiheal_enabled|revive_antiheal_enabled");
            const int maximum = flag ? 1 : key == "secondary_depth_max" ? 8 : In(key,"dot_max_duration|control_min_duration") ? 255 : In(key,"dot_turn_attack_bp|direct_multiplier_min_bp|direct_multiplier_max_bp") ? 1000000 : 10000;
            const int minimum=In(key,"active_heal_bonus_min_bp|active_heal_bonus_max_bp")?-10000:flag || In(key,"revived_extra_block_turns|direct_multiplier_min_bp|shield_pierce_success_bp|direct_hit_min_bp|direct_hit_max_bp")?0:1;
            if (!next.rules_.emplace(key, Int(row, "value", minimum, maximum)).second) throw std::runtime_error("duplicate shared rule");
            if (Str(row, "scope") != "all_units") throw std::runtime_error("shared rule scope must explicitly include base branches and enemies");
        });
        for (const char* key : {"rage_max", "shield_cap_bp", "dot_max_stacks", "dot_max_duration", "secondary_depth_max", "revive_per_target", "extra_attack_per_turn", "strategy_injured_hp_bp", "shield_refresh_same_source", "dot_poison_shared_budget", "dot_turn_attack_bp"})
            if (!next.rules_.count(key)) throw std::runtime_error(std::string("missing shared rule: ") + key);
        for(const char* key:{"revive_per_source_target","control_reset_gap","control_immunity_threshold","control_reduce_threshold","control_duration_bp","control_min_duration","control_immunity_turns","boss_control_per_turn","revived_extra_block_turns"})
            if(!next.rules_.count(key)) throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("control_reduce_threshold")>=next.Rule("control_immunity_threshold")) throw std::runtime_error("control reduction must precede immunity");
        for(const char* key:{"direct_multiplier_min_bp","direct_multiplier_max_bp"})
            if(!next.rules_.count(key)) throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("direct_multiplier_min_bp")>next.Rule("direct_multiplier_max_bp")) throw std::runtime_error("inverted direct multiplier range");
        for(const char* key:{"rage_extra_actor_turn","rage_extra_team_turn","rage_opening_team","rage_normal_hit","rage_regular_success","rage_damage_taken","rage_damage_events_turn","rage_kill","rage_first_death","rage_tactic_min_cost","shield_pierce_success_bp"})
            if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("rage_tactic_min_cost")>next.Rule("rage_max"))throw std::runtime_error("tactic minimum exceeds rage cap");
        for(const char* key:{"guard_cap_bp","guard_multiplier_min_bp","ignore_defense_cap_bp"})
            if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        for(const char* key:{"direct_hit_min_bp","direct_hit_max_bp"})
            if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("direct_hit_min_bp")>next.Rule("direct_hit_max_bp"))throw std::runtime_error("inverted direct hit range");
        for(const char* key:{"active_heal_bonus_min_bp","active_heal_bonus_max_bp","active_antiheal_enabled","revive_antiheal_enabled","overheal_shield_conversion_cap_bp","buff_tick_same_action_skip","thorns_requires_hp_loss","thorns_cap_bp","thorns_per_turn","vulnerability_keep_highest","buff_refresh_same_origin","cooldown_tick_action_begin","rage_from_shared_damage"})
            if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        for(const char* key:{"vulnerability_multiplier_max_bp","revived_action_block_turns","shared_link_target_select","shared_link_target_count","action_attribute_stack_cap","boss_attack_weaken_cap_bp","boss_defense_weaken_cap_bp","defense_weaken_cap_bp"})if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("shared_link_target_select")<1 || next.Rule("shared_link_target_select")>19 || next.Rule("shared_link_target_count")<1 || next.Rule("shared_link_target_count")>9)throw std::runtime_error("invalid shared link target plan");
        if(next.Rule("action_attribute_stack_cap")<1)throw std::runtime_error("action attribute cap must be positive");
        if(next.Rule("active_heal_bonus_min_bp")>next.Rule("active_heal_bonus_max_bp"))throw std::runtime_error("inverted active healing range");
        for(const char* key:{"critical_chance_cap_bp","critical_multiplier_min_bp","critical_multiplier_max_bp"})if(!next.rules_.count(key))throw std::runtime_error(std::string("missing shared rule: ")+key);
        if(next.Rule("critical_multiplier_min_bp")>next.Rule("critical_multiplier_max_bp"))throw std::runtime_error("inverted critical multiplier range");
        std::stable_sort(next.effects_.begin(), next.effects_.end(), [](const Effect& a, const Effect& b) { return std::make_pair(a.priority,a.id) < std::make_pair(b.priority,b.id); });
        for(size_t i=0;i<next.effects_.size();++i)next.eventEffects_[next.effects_[i].event].push_back(i);
        std::stable_sort(next.strategies_.begin(), next.strategies_.end(), [](const Strategy& a, const Strategy& b) { return std::make_pair(a.strategy,a.priority) < std::make_pair(b.strategy,b.priority); });
        std::stable_sort(next.targetPolicies_.begin(),next.targetPolicies_.end(),[](const TargetPolicy& a,const TargetPolicy& b){return std::make_pair(a.priority,a.id)<std::make_pair(b.priority,b.id);});
        *this = std::move(next); error.clear(); return true;
    } catch (const std::exception& e) { error = e.what(); return false; }
}
bool Catalog::ValidateReferences(const std::function<bool(int)>& hero, const std::function<bool(int)>& skill,
                                 const std::function<bool(int)>& buff, std::string& error,const std::function<bool(int)>& additive) const {
    for(const auto& p:buffCategories_) if(!buff(p.first)) {error="invalid category buff reference: "+std::to_string(p.first);return false;}
    for(const auto& p:controls_) if(!buff(p.first) || (p.second.replacement && !buff(p.second.replacement))) {
        error="invalid control buff reference: "+std::to_string(p.first); return false;
    }
    for(const auto& p:periodic_) if(!buff(p.first) || (p.second.bonusBuff && !buff(p.second.bonusBuff))) {
        error="invalid periodic buff reference: "+std::to_string(p.first); return false;
    }
    for (const auto& b : bindings_) if (!hero(b.hero)) { error = "unknown hero: " + std::to_string(b.hero); return false; }
    for(const auto& p:targetPolicies_)for(int id:p.buffs)if(!buff(id)){error="invalid target policy buff reference";return false;}
    for (const auto& e : effects_) {
        if(e.event=="after_passive_targets" && e.op=="set_parameter" && e.argument==2 && e.flat && !buff(e.flat)){error="invalid passive target excluded buff";return false;}
        if(e.op=="extend_origin_buffs" && !skill(e.argument)){error="invalid origin extension skill reference";return false;}
        if(e.event=="before_attribute_growth" && e.op=="set_parameter" && e.argument==0 && e.flat && !buff(e.flat)){error="invalid attribute growth buff reference";return false;}
        if(e.op=="trigger_periodic" && (!buff(e.argument) || !PeriodicFor(e.argument) || PeriodicFor(e.argument)->outcome!="damage")){error="invalid periodic trigger reference";return false;}
        if(e.op=="extend_owned_buff" && !buff(e.argument)){error="invalid owned extension buff reference";return false;}
        if(e.queryEffect && (!additive || !additive(e.queryEffect))){error="invalid passive parameter source effect";return false;}
        if(e.op=="consume_periodic" && (!buff(e.argument) || !PeriodicFor(e.argument))){error="invalid periodic consumption reference";return false;}
        if(e.op=="apply_skill_passives" && !skill(e.argument)){error="invalid invoked skill passive reference";return false;}
        if(e.op=="replace_passive_list" && (!additive || !additive(e.argument))){error="invalid additive effect replacement";return false;}
        auto validFact=[&](const std::string& field){const int id=BuffFact(field);return !id || buff(id);};
        if(!validFact(e.basis) || !validFact(e.capBasis) || !validFact(e.growthBasis) || !validFact(e.basisCap)){error="invalid buff fact reference";return false;}
        for(const auto& c:e.conditions)if(!validFact(c.field) || !validFact(c.otherField)){error="invalid buff fact reference";return false;}
        auto validSkillFact=[&](const std::string& field){const int id=SkillFact(field);return !id || skill(id);};
        if(!validSkillFact(e.basis) || !validSkillFact(e.capBasis) || !validSkillFact(e.growthBasis) || !validSkillFact(e.basisCap)){error="invalid source skill fact reference";return false;}
        for(const auto& c:e.conditions)if(!validSkillFact(c.field) || !validSkillFact(c.otherField)){error="invalid source skill fact reference";return false;}
        auto validHeroFact=[&](const std::string& field){const int id=HeroFact(field);return !id || hero(id);};
        if(!validHeroFact(e.basis) || !validHeroFact(e.capBasis) || !validHeroFact(e.growthBasis) || !validHeroFact(e.basisCap)){error="invalid team hero fact reference";return false;}
        for(const auto& c:e.conditions)if(!validHeroFact(c.field) || !validHeroFact(c.otherField)){error="invalid team hero fact reference";return false;}
        auto gearOrigin=[&](int id) {
            for(const auto& item:artifacts_)if(item.second.group==e.group && id==10000+item.second.family)return true;
            for(const auto& set:sets_)if(set.group==e.group && (id==10000+set.suit || id==11000+set.suit))return true;
            return false;
        };
        if ((e.skill && !skill(e.skill)) || (e.presentationSkill>0 && !skill(e.presentationSkill) && !gearOrigin(e.presentationSkill)) || (e.originSkill>0 && !skill(e.originSkill) && !gearOrigin(e.originSkill)) || (e.buff && !buff(e.buff)) || (In(e.op,"promote_buff|buff|extend_buff|replace_buff") && !buff(e.argument)) || (e.op == "cooldown" && e.argumentRole=="fixed" && !skill(e.argument))) {
            error = "invalid skill/buff reference in effect " + std::to_string(e.id); return false;
        }
    }
    return true;
}
bool Catalog::Supports(int hero, int branch, bool enabled) const {
    for (const auto& b : bindings_) if (b.hero == hero && b.branch == branch) return !enabled || b.enabled;
    return false;
}
std::set<int> Catalog::BoundGroups(int hero,int branch) const {
    std::set<int> groups;
    for(const auto& binding:bindings_)if(binding.hero==hero && binding.branch==branch)groups.insert(binding.groups.begin(),binding.groups.end());
    return groups;
}
const TargetPolicy* Catalog::TargetPolicyFor(int strategy,bool allies,const std::string& role) const {
    for(const auto& p:targetPolicies_)if(p.enabled && p.strategy==strategy && p.side==(allies?"ally":"enemy") && (p.role=="any" || p.role==role))return &p;
    return nullptr;
}
int64_t Catalog::Rule(const std::string& key) const { return Get(rules_, key); }
int Catalog::BuffCategory(int buff) const {
    const auto it=buffCategories_.find(buff);return it==buffCategories_.end()?0:it->second;
}
const std::vector<size_t>& Catalog::EffectsForEvent(const std::string& event) const {
    static const std::vector<size_t> empty;
    const auto it=eventEffects_.find(event);return it==eventEffects_.end()?empty:it->second;
}
const Effect* Catalog::EffectById(int id) const {
    for(const auto& effect:effects_) if(effect.id==id)return &effect;
    return nullptr;
}
const Periodic* Catalog::PeriodicFor(int buff) const {
    const auto it=periodic_.find(buff); return it==periodic_.end() ? nullptr : &it->second;
}
const ControlPolicy* Catalog::ControlFor(int buff) const {
    const auto it=controls_.find(buff); return it==controls_.end() ? nullptr : &it->second;
}
int Catalog::EventDepthLimit(const std::string& event) const {
    const auto policy=eventDepthExtensions_.find(event);
    // Eight is the existing structural recursion bound of secondary_depth_max.
    return static_cast<int>(std::min<int64_t>(8,Rule("secondary_depth_max")+(policy==eventDepthExtensions_.end()?0:policy->second)));
}
void Catalog::Execute(const Event& event, State& state, const std::function<int(int)>& random,
                      const std::function<std::vector<Values>(const std::string&,int)>& targets,
                      const std::function<void(const Values&, const Command&)>& apply,
                      const std::function<bool(const std::string&)>& admit,
                      const std::function<int64_t()>& actualHpLoss) const {
    std::set<int> groups;
    for (const auto& b : bindings_) if (b.hero == event.hero && b.branch == event.branch) groups.insert(b.groups.begin(),b.groups.end());
    for(const auto& g:event.equipmentGroups) groups.insert(g.first);
    for(const auto& g:event.contentValues)groups.insert(g.first);
    std::set<int> sourceMarkGroups,targetMarkGroups;
    for(const auto& entry:state.marks)if(entry.second.expires>event.turn){if(entry.first.first==event.actor)sourceMarkGroups.insert(entry.second.group);if(entry.first.first==event.target)targetMarkGroups.insert(entry.second.group);}
    Values gateFacts;
    if(event.name=="shield_lost")gateFacts["event_bonus"]=0;
    const int depthLimit=EventDepthLimit(event.name);
    for (size_t index : EffectsForEvent(event.name)) {
        const auto& e=effects_[index];
        if((e.skill && e.skill!=event.skill) || (e.buff && e.buff!=event.buff))continue;
        if(!(e.bindingScope=="source_buff_owner"?event.sourceBuffOwnerGroups.count(e.group):e.bindingScope=="target_team"?event.targetTeamGroups.count(e.group):e.bindingScope=="source_mark"?sourceMarkGroups.count(e.group):e.bindingScope=="target_mark"?targetMarkGroups.count(e.group):groups.count(e.group)))continue;
        const bool modifier=In(e.op,"replace_passive_list|replace_buff|scale_amount|set_duration|add_duration|scale_parameters|add_amount_bonus|add_parameter_bonus|add_parameter_flat|set_parameter|combine_remaining|multiply_amount");
        if(event.depth>=depthLimit && !modifier) continue;
        const int counterKey=e.counterKey?e.counterKey:e.id;
        const int counterActor=e.counterScope=="team"?event.teamActor:event.actor;
        Counter& c = state.counts[{counterActor, counterKey, 0}];
        if (c.turn != event.turn) { c.turn = event.turn; c.inTurn = 0; }
        if(c.action!=event.action){c.action=event.action;c.inAction=0;c.actionTargets.clear();}
        if (e.counterScope!="target" && ((e.turnLimit && c.inTurn >= e.turnLimit) || (e.battleLimit && c.inBattle >= e.battleLimit) || (e.interval && event.turn-c.lastTriggered<e.interval) || (e.actionLimit && c.inAction>=e.actionLimit))) continue;
        // Gates are independent of the recipient. Reject them before a selector
        // can consume RNG or perform any other target-selection work.
        bool gateAllowed=true;
        for(const auto& condition:e.conditions) {
            if(!GateFact(condition.field) || (!condition.otherField.empty() && !GateFact(condition.otherField)))continue;
            if(!Match({condition},gateFacts)){gateAllowed=false;break;}
        }
        if(!gateAllowed)continue;
        AmountBudget* amountBudget=nullptr;
        if(e.amountBudget=="source_turn" || e.amountBudget=="source_action") {
            auto& budget=state.amounts[{event.actor,counterKey}];
            const int period=e.amountBudget=="source_action"?event.action:event.turn;
            if(budget.turn!=period){budget.turn=period;budget.spent=0;}
            amountBudget=&budget;
        }
        int64_t reservedAmount=0;
        int64_t probability=e.probability;
        std::vector<std::pair<Values,Command>> pending;
        auto uniqueTargets=c.actionTargets;
        for (const auto& target : targets(e.target,e.group)) {
            Values facts = event.values;
            if(event.name=="shield_lost")facts["event_hp_loss"]=actualHpLoss?actualHpLoss():0;
            if(In(event.name,"death_observed|after_critical_roll"))facts["effect_battle_count"]=c.inBattle;
            facts["skill_level"]=std::max(1,event.level);
            for(const auto& field:gateFacts)facts[field.first]=field.second;
            auto gear=event.equipmentGroups.find(e.group);
            facts["gear_value"]=gear==event.equipmentGroups.end() ? 0 : gear->second;
            const auto content=event.contentValues.find(e.group);
            if(content!=event.contentValues.end())for(const auto& field:content->second)facts[field.first]=field.second;
            if(e.bindingScope=="target_team") {const auto team=event.targetTeamValues.find(e.group);if(team!=event.targetTeamValues.end())for(const auto& field:team->second)facts[field.first]=field.second;}
            for (const auto& v : target) facts[v.first] = v.second;
            auto counterValue=[&](const std::string& field) {
                const int id=CounterFact(field);if(!id)return;
                const auto* record=EffectById(id);if(!record)throw std::runtime_error("missing counter definition");
                if(field.compare(0,21,"counter_action_limit_")==0){facts[field]=record->actionLimit;return;}
                const int recipient=TargetCounterFact(field)?static_cast<int>(Get(facts,"position")):0;
                const auto stored=state.counts.find({event.actor,record->counterKey?record->counterKey:record->id,recipient});
                const Counter empty;const auto& value=stored==state.counts.end()?empty:stored->second;
                facts[field]=field.find("counter_action_count_")!=std::string::npos?(value.action==event.action?value.inAction:0):field.find("counter_turn_count_")!=std::string::npos?(value.turn==event.turn?value.inTurn:0):field.find("counter_age_")!=std::string::npos?event.turn-value.lastTriggered:value.inBattle;
            };
            counterValue(e.basis);counterValue(e.capBasis);counterValue(e.growthBasis);counterValue(e.basisCap);for(const auto& condition:e.conditions){counterValue(condition.field);counterValue(condition.otherField);}
            auto stateValue=[&](const std::string& field) {
                const int id=StateFact(field);if(!id)return;const auto* record=EffectById(id);
                const int recipient=field.compare(0,7,"target_")==0?static_cast<int>(Get(facts,"position")):0;
                const auto stored=state.counts.find({event.actor,record->counterKey?record->counterKey:record->id,recipient});
                facts[field]=stored==state.counts.end()?0:stored->second.value;
            };
            stateValue(e.basis);stateValue(e.capBasis);stateValue(e.growthBasis);stateValue(e.basisCap);for(const auto& condition:e.conditions){stateValue(condition.field);stateValue(condition.otherField);}
            auto markValue=[&](const std::string& field){const int id=MarkFact(field);if(!id)return;const auto* record=EffectById(id);const int bearer=field.compare(0,7,"source_")==0?event.actor:event.target;
                const auto stored=state.marks.find({bearer,record->counterKey?record->counterKey:record->id});const bool present=stored!=state.marks.end() && stored->second.expires>event.turn;
                facts[field]=!present?0:field.find("present_")!=std::string::npos?1:field.find("mark_source_")!=std::string::npos?stored->second.source:field.find("mark_group_")!=std::string::npos?stored->second.group:stored->second.value;
            };
            markValue(e.basis);markValue(e.capBasis);markValue(e.growthBasis);markValue(e.basisCap);for(const auto& condition:e.conditions){markValue(condition.field);markValue(condition.otherField);}
            if (!Match(e.conditions, facts)) continue;
            if(e.probabilitySource!="constant") {
                const int64_t scale=Get(facts,e.probabilitySource);
                if(scale<0 || scale>std::numeric_limits<int>::max())throw std::runtime_error("invalid battle probability scale");
                probability=static_cast<int64_t>(e.probability)*scale/10000;
                if(probability>10000)throw std::runtime_error("battle probability outside 0..10000");
            }
            const int recipient=static_cast<int>(Get(facts,"position"));
            if(e.uniqueTargets && !uniqueTargets.count(recipient) && uniqueTargets.size()>=static_cast<size_t>(e.uniqueTargets))continue;
            if(e.counterScope=="target") {
                Counter& budget=state.counts[{event.actor,counterKey,static_cast<int>(Get(facts,"position"))}];
                if(budget.turn!=event.turn){budget.turn=event.turn;budget.inTurn=0;}
                if(budget.action!=event.action){budget.action=event.action;budget.inAction=0;}
                if((e.turnLimit && budget.inTurn>=e.turnLimit) || (e.battleLimit && budget.inBattle>=e.battleLimit) || (e.interval && event.turn-budget.lastTriggered<e.interval) || (e.actionLimit && budget.inAction>=e.actionLimit)) continue;
            }
            const int64_t growthBase=Get(facts,e.growthBasis);
            if(growthBase<0 || growthBase>std::numeric_limits<int>::max())throw std::runtime_error("growth operand outside supported range");
            int64_t coefficient = e.ratio + (std::max<int64_t>(1,growthBase)-1) * e.growth;
            if(coefficient < -100000000 || coefficient > 100000000)throw std::runtime_error("combat coefficient outside supported range");
            if(e.ratioSource!="constant") {
                const int64_t scale=Get(facts,e.ratioSource);
                if(scale<0 || scale>std::numeric_limits<int>::max())throw std::runtime_error("coefficient scale outside supported range");
                coefficient=coefficient*scale/e.ratioDivisor;
            }
            int64_t basis = Get(facts, e.basis);
            if(e.basisCap!="none") {
                const int64_t limit=Get(facts,e.basisCap);
                if(limit<0 || limit>std::numeric_limits<int>::max())throw std::runtime_error("basis cap outside supported range");
                if(limit>0)basis=std::min(basis,limit);
            }
            // Runtime stats use int32 values; fail before overflowing a corrupt input.
            if (basis < 0 || basis > std::numeric_limits<int>::max() || coefficient < -100000000 || coefficient > 100000000) throw std::runtime_error("combat operand outside supported range");
            int64_t capCoefficient=e.cap;
            if(e.capRatioSource!="constant") {
                const int64_t scale=Get(facts,e.capRatioSource);
                if(scale<0 || scale>std::numeric_limits<int>::max())throw std::runtime_error("cap scale outside supported range");
                capCoefficient=capCoefficient*scale/10000;
            }
            const int64_t capBasis=Get(facts,e.capBasis);
            if(capBasis<0 || capBasis>std::numeric_limits<int>::max() || capCoefficient>100000000)throw std::runtime_error("cap operand outside supported range");
            int64_t amount = basis * coefficient / 10000 + e.flat;
            if(e.op=="split_heal") {
                const int64_t recipients=Get(facts,"recipient_count");
                if(recipients<1 || recipients>9)throw std::runtime_error("invalid healing recipient count");
                amount/=recipients;
            }
            if (capCoefficient) amount = std::min(amount, capBasis * capCoefficient / 10000);
            if(amountBudget)amount=std::min(amount,std::max<int64_t>(0,capBasis*capCoefficient/10000-amountBudget->spent-reservedAmount));
            int fraction=0;
            if(e.op=="shield") {
                // Preserve fractional HP until all contributions from this event combine.
                int64_t raw=basis*coefficient+static_cast<int64_t>(e.flat)*10000;
                if(capCoefficient)raw=std::min(raw,capBasis*capCoefficient);
                raw=std::max<int64_t>(0,std::min<int64_t>(static_cast<int64_t>(std::numeric_limits<int>::max())*10000,raw));
                amount=raw/10000;fraction=static_cast<int>(raw%10000);
                // Cumulative shield budgets reserve whole HP before efficiency.
                if(amountBudget){amount=std::min(amount,std::max<int64_t>(0,capBasis*capCoefficient/10000-amountBudget->spent-reservedAmount));fraction=0;}
            }
            const bool signedBonus=In(e.op,"mark|state_set|state_add|add_amount_bonus|add_parameter_bonus|add_parameter_flat|multiply_amount") || (e.op=="set_parameter" && e.event=="before_passive_raw_parameters") || (e.op=="scale_amount" && e.event=="before_buff_attempt");
            amount = std::max<int64_t>(signedBonus?std::numeric_limits<int>::min():0, std::min<int64_t>(std::numeric_limits<int>::max(),amount));
            if(e.op=="combine_remaining" && amount>10000)throw std::runtime_error("remaining fraction outside 0..10000");
            if (amount || fraction || In(e.op,"consume_periodic|apply_skill_passives|replace_passive_list|mark|state_set|replace_buff|set_duration|scale_amount|scale_parameters|set_parameter|buff|copy_buff|gate|chance_gate|reset_counter")) {
                int duration=e.duration;
                if(duration==-1){const int64_t inherited=Get(facts,"event_duration");if(inherited<1 || inherited>255)throw std::runtime_error("event duration outside 1..255");duration=static_cast<int>(inherited);}
                Command command{e.id,e.op=="copy_buff"?event.buff:e.argument,duration,e.op,amount,fraction};
                if(e.op=="buff")command.parameters.assign(e.parameterCount,static_cast<int>(amount));
                else if(e.op=="copy_buff")command.parameters=event.parameters;
                pending.push_back({target,std::move(command)});
                if(amountBudget)reservedAmount+=amount;
                if(e.uniqueTargets)uniqueTargets.insert(recipient);
            }
        }
        if(pending.empty())continue;
        // Explicit chance gates preserve one draw even at the 0/100% boundaries.
        // An earlier deterministic gate owns the original attempt budget.
        if(e.op=="chance_gate") {if(random(10000)>probability)continue;}
        else if(!probability || (probability<10000 && random(10000)>probability))continue;
        if(!admit(e.budget)) continue;
        // Commit the attempted amount before applying commands. Full HP or a
        // rejected revival does not refund it, and nested events see it spent.
        if(amountBudget)amountBudget->spent+=reservedAmount;
        if(e.counterScope!="target"){++c.inTurn;++c.inBattle;++c.inAction;c.lastTriggered=event.turn;c.actionTargets=std::move(uniqueTargets);}
        for (const auto& command : pending) {
            int gateCount=c.inBattle;
            if(e.counterScope=="target") {auto& budget=state.counts[{event.actor,counterKey,static_cast<int>(Get(command.first,"position"))}];++budget.inTurn;++budget.inBattle;++budget.inAction;budget.lastTriggered=event.turn;gateCount=budget.inBattle;}
            if(In(e.op,"gate|chance_gate")) {
                gateFacts["gate_"+std::to_string(e.id)]=1;
                gateFacts["gate_count_"+std::to_string(e.id)]=gateCount;
            } else if(e.op=="add_event_bonus") {
                gateFacts["event_bonus"]+=command.second.value;
            } else if(e.op=="reset_counter") {
                const auto* record=EffectById(command.second.argument);
                state.counts[{event.actor,record->counterKey?record->counterKey:record->id,0}]=Counter();
            } else if(e.op=="mark") {
                TimedMark mark;mark.source=event.actor;mark.group=e.group;mark.value=command.second.value;mark.expires=command.second.duration?event.turn+command.second.duration:std::numeric_limits<int>::max();
                state.marks[{static_cast<int>(Get(command.first,"position")),counterKey}]=mark;
            } else if(In(e.op,"state_set|state_add")) {
                const int recipient=e.counterScope=="target"?static_cast<int>(Get(command.first,"position")):0;
                auto& value=state.counts[{event.actor,counterKey,recipient}].value;
                int64_t updated=e.op=="state_set"?command.second.value:value+command.second.value;
                if(e.argument)updated=std::min<int64_t>(e.argument,updated);
                value=std::max<int64_t>(std::numeric_limits<int>::min(),std::min<int64_t>(std::numeric_limits<int>::max(),updated));
            } else apply(command.first, command.second);
        }
    }
}
const Strategy* Catalog::ChooseStrategy(int strategy, int rage, int cost, const Values& facts,
                                       const std::function<bool(const std::string&)>& usable) const {
    bool tacticBudget=false;
    for(const auto& s:strategies_)if(s.strategy==strategy && s.role=="tactic" && cost>=0 && rage>=cost &&
        (rage-cost>=s.reserve || (s.emergency && Match(s.conditions,facts))))tacticBudget=true;
    // Original AI evaluates tactic then regular exactly once before choosing.
    // Revival usefulness performs real selection, so eligibility is observable.
    const bool canTactic=tacticBudget && usable("tactic");
    const bool canRegular=usable("regular");
    for (const auto& s : strategies_) {
        if (s.strategy != strategy || !Match(s.conditions,facts)) continue;
        const bool allowed=s.role=="tactic"?canTactic:s.role=="regular"?(canRegular || (s.emergency && usable("regular_ready"))):usable(s.role);
        if(!allowed)continue;
        if (s.role == "tactic" && (cost < 0 || rage < cost || (!s.emergency && rage-cost < s.reserve))) continue;
        return &s;
    }
    return nullptr;
}
}
