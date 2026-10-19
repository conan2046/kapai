#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

// The vocabulary is code; bindings, tuning and combinations live in Excel.
namespace CombatData {
using Values = std::map<std::string, int64_t>;
struct Condition { std::string field, op,otherField; int64_t value = 0; };
struct Effect {
    int id = 0, group = 0, skill = 0, buff = 0, priority = 0;
    std::string event, target, op, basis, capBasis, description, budget, counterScope,ratioSource,capRatioSource;
    int ratio = 0, growth = 0, flat = 0, cap = 0, duration = 0;
    int probability = 0, turnLimit = 0, battleLimit = 0, argument = 0;
    int parameterCount=1;
    int originLevel=0;
    int originSkill=-1;
    int interval=0,counterKey=0,ratioDivisor=10000;
    int stackKey=0,presentationSkill=-1;
    int actionLimit=0,uniqueTargets=0;
    int affix=0;
    int queryEffect=0,queryAttribute=0,queryParameter=0,queryLevel=0;
    bool affixAliveOnly=true;
    bool emitAction=true;
    bool checkSkillImmunity=true;
    std::string affixScope;
    std::string growthBasis,argumentRole,basisCap;
    std::string amountBudget="none";
    std::string probabilitySource="constant";
    std::string bindingScope="owner";
    std::string stackPolicy;
    std::vector<Condition> conditions;
};
struct Binding { int hero = 0, branch = 0; bool enabled = false; std::vector<int> groups; };
struct Artifact { int id=0,family=0,quality=0,rank=0,group=0,value=0; std::string exclusive; bool enabled=false; };
struct SetBonus { int suit=0,pieces=0,group=0,value=0; bool enabled=false; };
struct WornItem { int slot=0,id=0,suit=0,part=0; uint32_t instance=0; bool artifact=false; };
struct Loadout { std::map<int,int> groups,pieces; std::map<std::string,int> artifacts; };
struct Strategy {
    int id = 0, strategy = 0, priority = 0, reserve = 0;
    bool emergency = false;
    std::string role, description;
    std::vector<Condition> conditions;
};
struct TargetPolicy {
    int id=0,strategy=0,priority=0;bool enabled=false;
    std::string side,role,order,tie;
    std::vector<int> buffs;
};
struct Event {
    std::string name;
    int actor = 0, hero = 0, branch = 0, skill = 0, buff = 0, turn = 0, level = 1;
    int teamActor=0;
    int target=0;
    int action=0;
    int depth = 0;
    Values values;
    std::vector<int> parameters;
    std::map<int,int> equipmentGroups;
    std::map<int,Values> contentValues;
    std::map<int,Values> targetTeamValues;
    std::set<int> targetTeamGroups;
    std::set<int> sourceBuffOwnerGroups;
};
struct Periodic {
    int buff=0, paramA=0, paramB=-1, capParam=-1, stackGroup=0, bonusBuff=0, bonus=0, bonusAffix=0, bonusCap=0, zeroActionParameter=-1;
    bool turnBudget=false;
    std::string event,outcome,formula,basis,aggregation;
};
struct Command { int effect = 0, argument = 0, duration = 0; std::string op; int64_t value = 0; int fraction = 0; std::vector<int> parameters; };
struct Counter {
    int turn=-1,inTurn=0,inBattle=0,lastTriggered=-100000,action=-1,inAction=0;
    int64_t value=0;
    std::set<int> actionTargets;
};
struct AmountBudget { int turn=-1; int64_t spent=0; };
struct ControlPolicy { bool diminishing=false,refresh=false; std::string bossMode; int replacement=0,value=0,duration=0; };
struct ControlHistory { int count=0,lastEnd=-100000,immuneUntil=-1; };
struct ScopedDepth { int& value; explicit ScopedDepth(int& depth):value(depth){++value;} ~ScopedDepth(){--value;} };
struct TimedMark {int source=0,group=0,expires=0;int64_t value=0;};
struct Sequence {bool fixed=false;int index=0,hits=1,targetIndex=0;};
struct State {
    std::map<std::pair<int,int>,TimedMark> marks;
    std::map<int,Sequence> sequences;
    std::map<std::tuple<int, int, int>, Counter> counts;
    std::map<int,AmountBudget> periodic,rageActors,rageTeams;
    std::map<std::pair<int,int>,AmountBudget> amounts;
    std::map<int,int> rageOpening;
    std::map<int,Counter> damageRage;
    bool openingRage=false;
    std::map<std::pair<int,int>,ControlHistory> controls;
    std::map<int,Counter> bossControls,extraAttacks;
    std::map<int,int> revives,revivedAt;
    std::map<std::pair<int,int>,int> reviveSources;
};
struct Modifiers {
    int amount = 0, duration = 0, probability = 10000;
    int buff = 0;
    int64_t amountBonus = 0;
    std::map<int,int64_t> parameterBonuses;
    std::vector<int> parameters;
};
class Catalog {
public:
    // Failed reloads preserve the previous complete catalog; no partial publish.
    bool Load(const std::string& directory, std::string& error);
    bool ValidateReferences(const std::function<bool(int)>& heroExists,
                            const std::function<bool(int)>& skillExists,
                            const std::function<bool(int)>& buffExists, std::string& error,
                            const std::function<bool(int)>& additiveExists = {}) const;
    bool Supports(int hero, int branch, bool requireEnabled = true) const;
    int64_t Rule(const std::string& key) const;
    int EventDepthLimit(const std::string& event) const;
    const Periodic* PeriodicFor(int buff) const;
    const ControlPolicy* ControlFor(int buff) const;
    int BuffCategory(int buff) const;
    const Effect* EffectById(int id) const;
    Loadout Snapshot(const std::vector<WornItem>& worn) const;
    const std::vector<Effect>& Effects() const { return effects_; }
    const std::vector<size_t>& EffectsForEvent(const std::string& event) const;
    const std::vector<Strategy>& Strategies() const { return strategies_; }
    const TargetPolicy* TargetPolicyFor(int strategy,bool allies,const std::string& role) const;
    // Budget is charged once per qualifying event, regardless of target count.
    // Caller applies each command through the real battle HP/buff/protocol path.
    void Execute(const Event&, State&, const std::function<int(int)>& random,
                 const std::function<std::vector<Values>(const std::string&,int)>& targets,
                 const std::function<void(const Values&, const Command&)>& apply,
                 const std::function<bool(const std::string&)>& admit,
                 const std::function<int64_t()>& actualHpLoss = {}) const;
    std::set<int> BoundGroups(int hero,int branch) const;
    const Strategy* ChooseStrategy(int strategy, int rage, int tacticCost, const Values& facts,
                                  const std::function<bool(const std::string&)>& usable) const;
private:
    std::vector<Effect> effects_;
    std::map<std::string,std::vector<size_t>> eventEffects_;
    std::vector<Binding> bindings_;
    std::vector<Strategy> strategies_;
    std::vector<TargetPolicy> targetPolicies_;
    std::map<int,Periodic> periodic_;
    std::map<int,ControlPolicy> controls_;
    std::map<int,int> buffCategories_;
    std::map<std::string,int> eventDepthExtensions_;
    std::map<int,Artifact> artifacts_;
    std::vector<SetBonus> sets_;
    std::map<int,std::pair<std::string,int>> slots_;
    Values rules_;
};
Catalog& Current();
}
