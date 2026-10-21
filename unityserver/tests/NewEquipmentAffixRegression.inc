// Included inside the native combat regression: production catalog, worn passive
// resolution, event dispatch, HP/buff/cooldown paths; no player save or database.
{
    auto attachNew=[&](int id,int tier,uint8 pos=1) {
        const auto* cfg=sCItemCfgManager.GetEquipAffixCfg(id);
        if(!cfg)throw std::runtime_error("missing new equipment affix");
        fight.m_members[pos-1].passive_skill.push_back(SSkillData(cfg->passiveSkillId,tier));
    };
    auto setupNew=[&](int id,int tier) {
        fight.Clear();fight.m_combatObserver={};fight.m_fightTurn=1;
        unit(1,10,0,5000);unit(2,23,0,2000);unit(3,23,0,8000);
        unit(enemy,23,0,10000);unit(otherEnemy,23,0,10000);
        for(auto& member:fight.m_members){member.unitAttr.attack=1000;member.unitAttr.wufang=1000;}
        attachNew(id,tier);
    };
    auto emitNew=[&](const char* event,uint8 target,CombatData::Values facts={},uint16 buff=0,uint8 actor=1) {
        fight.CombatEvent(event,actor,target,0,buff,1,std::move(facts));
    };
    int checked=0;
    for(int tier=1;tier<=3;++tier)for(int id=49;id<=68;++id) {
        setupNew(id,tier);
        const auto* cfg=sCItemCfgManager.GetEquipAffixCfg(id);
        const int v1=cfg->GetValue1(tier),v2=cfg->GetValue2(tier);
        bool ok=true;
        switch(id) {
        case 49:
            emitNew("after_heal",2,{{"effective_heal",500},{"hp_before_bp",3500}});
            ok=fight.GetTeamRage(1)==0;
            emitNew("after_heal",2,{{"effective_heal",500},{"hp_before_bp",3499}});
            emitNew("after_heal",2,{{"effective_heal",500},{"hp_before_bp",1000}});
            ok=ok && fight.GetTeamRage(1)==v1;break;
        case 50:
            emitNew("after_cleanse_batch",2,{{"removed_negative_count",0},{"removed_count",1}});
            ok=fight.GetStatePara1(1,ESBUFF_ZengShangLvAdd)==0;
            emitNew("after_cleanse_batch",2,{{"removed_negative_count",1},{"removed_count",1}});
            ok=ok && fight.GetStatePara1(1,ESBUFF_ZengShangLvAdd)==v1;break;
        case 51:
            emitNew("after_dispel_batch",enemy,{{"removed_count",0}});
            ok=!fight.HaveShieldState(2);
            emitNew("after_dispel_batch",enemy,{{"removed_count",1}});
            ok=ok && fight.GetStatePara1(2,ESBUFF_Shield)==v1;break;
        case 52:
            emitNew("after_guard_hp",enemy);
            ok=fight.GetStatePara1(1,ESBUFF_Shield)==v1;break;
        case 53: case 54:
            emitNew("after_thorns",enemy,{{"amount",0},{"absorbed",100}});
            ok=fight.GetTeamRage(1)==0 && fight.GetHp(2)==2000;
            emitNew("after_thorns",enemy,{{"amount",500},{"absorbed",0}});
            if(id==53)ok=ok && fight.GetTeamRage(1)==v1;
            else ok=ok && fight.GetHp(2)==2000+v1;
            break;
        case 55: {
            emitNew("after_primary_hit",enemy,{{"amount",500},{"event_target_alive",1}});
            ok=fight.GetTeamRage(1)==0;
            std::vector<int> p{100};fight.AddBuff(enemy,1,ESBUFF_Blooding,3,&p);
            emitNew("after_primary_hit",enemy,{{"amount",500},{"event_target_alive",1}});
            ok=ok && fight.GetTeamRage(1)==v1;break;
        }
        case 56:
            emitNew("after_primary_hit",enemy,{{"amount",500},{"event_target_alive",1}});
            ok=fight.GetTeamRage(1)==0;
            fight.m_members[enemy-1].hp=0;fight.SetState(enemy,EFST_STATE_Die);
            emitNew("after_primary_hit",enemy,{{"amount",500},{"event_target_alive",0}});
            ok=ok && fight.GetTeamRage(1)==v1;break;
        case 57:
            attachNew(57,tier,2);
            emitNew("secondary_attack_observed",enemy);
            emitNew("secondary_attack_observed",enemy,{},0,2);
            ok=fight.GetTeamRage(1)==v1;break;
        case 58:
            emitNew("buff_attempt_applied",enemy,{{"event_buff_owned",0}},21);
            ok=fight.GetStatePara1(enemy,ESBUFF_SpeedDes)==0;
            emitNew("buff_attempt_applied",enemy,{{"event_buff_owned",1}},21);
            ok=ok && fight.GetStatePara1(enemy,ESBUFF_SpeedDes)==v1;break;
        case 59:
            emitNew("buff_attempt_applied",enemy,{{"event_buff_owned",1}},26);
            ok=fight.GetStatePara1(1,ESBUFF_JianShangLvAdd)==v1 && fight.GetStatePara1(2,ESBUFF_JianShangLvAdd)==v1;break;
        case 60:
            emitNew("after_heal",2,{{"effective_heal",0},{"hp_before_bp",2000}});
            ok=fight.GetUnitFangYu(2,1)==1000;
            emitNew("after_heal",2,{{"effective_heal",500},{"hp_before_bp",2000}});
            ok=ok && fight.GetUnitFangYu(2,1)==1000+v1/10;
            attachNew(60,1,3);emitNew("after_heal",2,{{"effective_heal",500},{"hp_before_bp",2000}},0,3);
            ok=ok && fight.GetUnitFangYu(2,1)==1000+v1/10;
            fight.m_fightTurn+=cfg->duration;ok=ok && fight.GetUnitFangYu(2,1)==1000;break;
        case 61: case 63: {
            SSkillData regular(101,1),revive(102,1);regular.CD=regular.leftCD=6;revive.CD=revive.leftCD=6;
            fight.m_members[0].skill_list={regular,revive};
            const char* event=id==61?"after_primary_hit":"after_heal";
            CombatData::Values facts=id==61?CombatData::Values{{"had_shield",0},{"amount",500},{"event_target_alive",1}}:CombatData::Values{{"effective_heal",0},{"hp_before_bp",2000}};
            emitNew(event,id==61?enemy:2,facts);
            ok=fight.m_members[0].skill_list[0].leftCD==6 && fight.m_members[0].skill_list[1].leftCD==6;
            if(id==61)facts["had_shield"]=1;else facts["effective_heal"]=500;
            bool proc=false;
            for(int attempt=0;attempt<64 && !proc;++attempt){++fight.m_fightTurn;emitNew(event,id==61?enemy:2,facts);proc=fight.m_members[0].skill_list[id==61?0:1].leftCD==6-v2;}
            ok=ok && proc && fight.m_members[0].skill_list[id==61?1:0].leftCD==6;
            int before=fight.m_members[0].skill_list[id==61?0:1].leftCD;
            emitNew(event,id==61?enemy:2,facts);
            ok=ok && fight.m_members[0].skill_list[id==61?0:1].leftCD==before;break;
        }
        case 62:
            emitNew("after_primary_hit",enemy,{{"amount",1000},{"had_shield",0},{"event_target_alive",1}});
            ok=fight.GetHp(otherEnemy)==10000;
            emitNew("after_primary_hit",enemy,{{"amount",1000},{"had_shield",1},{"event_target_alive",1}});
            ok=ok && fight.GetHp(otherEnemy)==10000-v1/10;break;
        case 64: case 65: {
            emitNew("after_landed_skill",enemy);
            ok=fight.GetHp(enemy)==10000;
            std::vector<int> p{1000};fight.AddBuff(enemy,1,ESBUFF_ZhuoShao,3,&p);
            emitNew("after_landed_skill",enemy);
            bool burn=false;for(const auto& b:fight.m_members[enemy-1].buff_list)if(b.id==ESBUFF_ZhuoShao && b.srcPos==1)burn=true;
            ok=ok && fight.GetHp(enemy)<10000 && 10000-fight.GetHp(enemy)<=1000*v2/10000 && (id==64?burn:!burn);
            const int64 hp=fight.GetHp(enemy);emitNew("after_landed_skill",enemy);ok=ok && fight.GetHp(enemy)==hp;break;
        }
        case 66:
            attachNew(66,tier,2);
            emitNew("after_direct_hp_loss",enemy,{{"amount",0}});
            ok=fight.GetStatePara1(2,ESBUFF_DamagePercentAdd)==0;
            emitNew("after_direct_hp_loss",enemy,{{"amount",500}});
            emitNew("after_direct_hp_loss",enemy,{{"amount",500}},0,2);
            emitNew("after_direct_hp_loss",enemy,{{"amount",500}});
            ok=ok && fight.GetStatePara1(2,ESBUFF_DamagePercentAdd)==v1;
            for(int n=0;n<4;++n){++fight.m_fightTurn;emitNew("after_direct_hp_loss",enemy,{{"amount",500}});}
            ok=ok && fight.GetStatePara1(2,ESBUFF_DamagePercentAdd)==v1*v2;break;
        case 67:
            emitNew("after_primary_hit",enemy,{{"had_shield",0},{"amount",500},{"event_target_alive",1}});
            ok=fight.GetUnitAttack(1)==1000;
            for(int n=0;n<7;++n){++fight.m_fightTurn;emitNew("after_primary_hit",enemy,{{"had_shield",1},{"amount",500},{"event_target_alive",1}});}
            ok=ok && fight.GetUnitAttack(1)==1000+v1*v2/10;break;
        case 68: {
            for(int n=0;n<5;++n)emitNew("buff_attempt_applied",enemy,{{"event_buff_owned",1}},21);
            CombatData::Modifiers bonus;emitNew("action_end",enemy);
            fight.CombatEvent("before_direct_damage",1,enemy,101,0,1,{},&bonus);
            ok=bonus.amountBonus==v1*v2;
            emitNew("action_start",enemy);CombatData::Modifiers cleared;
            fight.CombatEvent("before_direct_damage",1,enemy,101,0,1,{},&cleared);
            ok=ok && cleared.amountBonus==0;break;
        }
        }
        if(!ok){std::cerr<<"FAIL new equipment affix id="<<id<<" tier="<<tier<<" value1="<<v1<<" rage="<<fight.GetTeamRage(1)<<" ally_hp="<<fight.GetHp(2)<<" source_attack="<<fight.GetUnitAttack(1)<<std::endl;return false;}
        ++checked;
    }
    std::set<int> rolled;
    for(int quality=1;quality<=7;++quality)for(int part=1;part<=4;++part)for(uint32 seed=1;seed<=4096;++seed){
        uint16 id=0;uint8 tier=0;bool valid=sCItemCfgManager.RollEquipAffix(part,quality,seed,id,tier);
        if(!valid)continue;
        const auto* cfg=sCItemCfgManager.GetEquipAffixCfg(id);
        if(!cfg || quality<cfg->qualityMin || !cfg->IsPartAllowed(part) || tier<1 || tier>3)return false;
        rolled.insert(id);
    }
    if(rolled.size()!=68){std::cerr<<"FAIL crafting pool coverage "<<rolled.size()<<std::endl;return false;}
    std::cout<<"PASS new equipment affixes: "<<checked<<" id/tier trigger cases; 68 crafting candidates; quality/part gates"<<std::endl;
}
