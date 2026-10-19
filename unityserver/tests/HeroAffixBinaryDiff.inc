// Included only inside the explicit offline regression entry in each engine.
// The reference engine defines HERO_AFFIX_BINARY_DIFF_LEGACY; battle code stays
// unchanged. Both executables receive the same units, seed and ordered inputs.
{
    const char* scopeValue=std::getenv("HERO_AFFIX_DIFF_SCOPE");
    const std::string diffScope=scopeValue?scopeValue:"nuwa";
    CNetMessage::SetNetMsgEncodeType(gyu::net::MET_UTF8);
    CFight specimen;
    const uint8 opponent=GROUP2_BEGIN+1;
    auto addUnit=[&](uint8 pos,int hero,int branch,int hp,int maximum=10000) {
        SharePetPtr pet(new SPet);pet->ClearSkill();pet->id=hero;
        auto& member=specimen.m_members[pos-1];member.memPtr=pet;member.type=EFMT_PET;
        member.level=1;member.unitAttr.maxHp=maximum;member.unitAttr.attack=1000;member.hp=hp;
        member.unitAttr.maxHpBase=maximum;member.unitAttr.attackBase=1000;
        member.unitAttr.maxHpRatio=member.unitAttr.attackRatio=member.unitAttr.wufangRatio=member.unitAttr.fafangRatio=10000;
        pet->basicAttr=member.unitAttr;pet->hp=hp;pet->level=1;
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
        member.heroBuildBranch=branch;member.heroBuildStrategy=1;
#else
        member.combatBranch=branch;member.combatStrategy=1;
#endif
    };
    auto setup=[&](int branch,int seed,int hp=4000) {
        specimen.Clear();addUnit(1,10,branch,10000);addUnit(2,23,0,hp);addUnit(opponent,23,0,10000);
        specimen.m_curActionPos=0;specimen.m_actionList.clear();specimen.m_dieList.clear();
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
        specimen.m_heroBuildSecondaryDamage=false;
#else
        specimen.m_combatDepth=0;
#endif
        specimen.m_members[0].skill_list.push_back(SSkillData(101,1));
        specimen.m_members[0].skill_list.push_back(SSkillData(102,1));
        specimen.m_members[0].skill_list.back().leftCD=6;
        for(CNetMessage* message:{&specimen.m_actionMsg,&specimen.m_extActionMsg,&specimen.m_otherMsg}){message->ReWrite();message->SetType(0);}
        std::srand(seed);
    };
    auto packet=[&](CNetMessage& message) {
        static const char digits[]="0123456789abcdef";std::string hex;
        message.SetDataLen();for(unsigned char byte:*message.GetMsgData()){hex+=digits[byte>>4];hex+=digits[byte&15];}
        return hex;
    };
    auto emit=[&](int branch,int seed,const std::string& scenario,int selection=0,CNetMessage* death=nullptr) {
        const int nextRandom=std::rand();std::string units="[",buffs="[",cooldowns="[";bool unitComma=false,buffComma=false,cdComma=false;
        for(uint8 pos=1;pos<=MAX_MEMBER;++pos) {
            auto& member=specimen.m_members[pos-1];if(member.memPtr.empty())continue;
            if(unitComma)units+=",";unitComma=true;
            units+="["+std::to_string(pos)+","+std::to_string(member.hp)+","+std::to_string(specimen.GetMaxHp(pos))+","+std::to_string(member.state)
                +","+std::to_string(specimen.GetUnitAttack(pos))+","+std::to_string(specimen.GetUnitSpeed(pos))
                +","+std::to_string(specimen.GetUnitFangYu(pos,1))+","+std::to_string(specimen.GetUnitFangYu(pos,2))+","+std::to_string(member.unitAttr.fumianAdd)+","+std::to_string(member.unitAttr.famianLv)+"]";
            for(const auto& skill:member.skill_list){if(cdComma)cooldowns+=",";cdComma=true;cooldowns+="["+std::to_string(pos)+","+std::to_string(skill.id)+","+std::to_string(skill.leftCD)+"]";}
            for(const auto& buff:member.buff_list) {
                if(buffComma)buffs+=",";buffComma=true;
                buffs+="["+std::to_string(pos)+","+std::to_string(buff.id)+","+std::to_string(buff.srcPos)+","+std::to_string(buff.leftTurn)+","+std::to_string(buff.originSkill)+",[";
                for(size_t i=0;i<buff.paraList.size();++i){if(i)buffs+=",";buffs+=std::to_string(buff.paraList[i]);}buffs+="]]";
            }
        }
        units+="]";buffs+="]";cooldowns+="]";
        std::cout<<"BINARY_DIFF_RESULT {\"id\":\""<<diffScope<<"_"<<branch<<"_"<<scenario<<"_"<<seed<<"\",\"branch\":"<<branch<<",\"seed\":"<<seed
            <<",\"units\":"<<units<<",\"buffs\":"<<buffs<<",\"cooldowns\":"<<cooldowns<<",\"rage\":"<<specimen.GetTeamRage(1)
            <<",\"enemy_rage\":"<<specimen.GetTeamRage(opponent)<<",\"attack\":"<<specimen.GetUnitAttack(1)<<",\"selection\":"<<selection<<",\"next_random\":"<<nextRandom
            <<",\"primary_packet\":\""<<packet(specimen.m_actionMsg)<<"\",\"extra_packet\":\""<<packet(specimen.m_extActionMsg)
            <<"\",\"other_packet\":\""<<packet(specimen.m_otherMsg)<<"\",\"death_packet\":\""<<(death?packet(*death):std::string())<<"\"}"<<std::endl;
    };
    if(diffScope=="all_heroes_battle") {
        const char* profileText=std::getenv("HERO_AFFIX_BATTLE_PROFILE");
        const bool closure=profileText && std::string(profileText)=="closure";
        const bool loadout=profileText && std::string(profileText)=="loadout";
        if(loadout && !sCItemCfgManager.InitAllCfg()){std::cerr<<"LOADOUT_PREFLIGHT: formal equipment configuration failed"<<std::endl;return false;}
        bool Compress(uint8*,uint32,std::string&);
        int GetAttrValue(std::vector<SAttrData>&,uint16);
        std::map<std::pair<int,int>,uint16> formalEquipment;
        std::map<int,std::vector<uint16>> formalArtifacts;
        if(loadout)for(int id=1;id<=65535;++id) {
            if(const auto* cfg=sCItemCfgManager.GetEquipCfg(static_cast<uint16>(id)))
                if(cfg->suit>=1 && cfg->suit<=10 && cfg->part>=1 && cfg->part<=4)
                    formalEquipment.emplace(std::make_pair(cfg->suit,cfg->part),cfg->id);
            if(const auto* cfg=sCItemCfgManager.GetFaBaoCfg(static_cast<uint16>(id)))
                if(id>=1001 && id<=1414 && id%100>=1 && id%100<=14)formalArtifacts[id%100].push_back(cfg->id);
        }
        if(loadout && (formalEquipment.size()!=40 || formalArtifacts.size()!=14)){std::cerr<<"LOADOUT_PREFLIGHT: parts="<<formalEquipment.size()<<" families="<<formalArtifacts.size()<<std::endl;return false;}
        const char* traceText=std::getenv("HERO_AFFIX_DIFF_TRACE");const bool trace=traceText && std::string(traceText)=="1";
        const char* startText=std::getenv("HERO_AFFIX_ENCOUNTER_START"),*countText=std::getenv("HERO_AFFIX_ENCOUNTER_COUNT");
        const int start=startText?std::atoi(startText):0,count=countText?std::atoi(countText):1;
        if(start<0 || count<1 || start+count>720)return false;
        for(int encounter=start;encounter<start+count;++encounter) {
            int choice=encounter;const int variant=choice%2;choice/=2;const int strategy=choice%5+1;choice/=5;
            const int seeds[]={1,1729,7907};const int seed=seeds[choice%3];choice/=3;const int branchMode=choice%2;choice/=2;const int roster=choice;
            setup(0,seed);specimen.Clear();
            std::vector<ShareUserPtr> owners;
            std::string loadoutRows;
            specimen.showFightLog=trace;
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
            specimen.m_heroBuildSecondaryDamage=false;
#else
            specimen.m_combatDepth=0;
            std::map<std::tuple<int,int,int,std::string>,int> observed;
            specimen.m_combatObserver=[&](uint8 actor,const char* kind,int skill,int) {
                if(actor && skill)++observed[{specimen.GetHeroId(actor),specimen.m_members[actor-1].combatBranch,skill,kind}];
            };
#endif
            for(int slot=0;slot<10;++slot) {
                const uint8 pos=static_cast<uint8>(slot<5?slot+1:opponent+slot-5);
                // Shared 5v5 roster: shield admission, healing auras and lethal pressure.
                // No direct passive/Presenter invocation or fabricated trigger record.
                const int closureHeroes[]={14,36,38,57,67,12,10,36,38,67};
                const int hero=closure?closureHeroes[slot]:10+(roster*5+slot)%59,branch=(slot<5?branchMode:1-branchMode)+1;
                addUnit(pos,hero,branch,closure && hero==36 && variant?300:(variant?9000:40000),variant?12000:40000);
                auto& member=specimen.m_members[pos-1];member.level=variant?75:10;member.attackType=slot%2+1;
                member.unitAttr.attack=member.unitAttr.attackBase=variant?2200:1500;
                member.unitAttr.wufang=member.unitAttr.fafang=member.unitAttr.wufangBase=member.unitAttr.fafangBase=400;
                member.unitAttr.speed=100+slot;member.unitAttr.baojiAdd=15000;
                member.unitAttr.fanjiAdd=member.unitAttr.lianjiAdd=10000;
                auto pet=boost::any_cast<SharePetPtr>(member.memPtr);pet->basicAttr=member.unitAttr;pet->hp=member.hp;pet->level=member.level;pet->attackType=member.attackType;
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                member.heroBuildStrategy=strategy;
#else
                member.combatStrategy=strategy;
#endif
                for(int suffix=1;suffix<=4;++suffix) {
                    const int skill=hero*10+suffix;const auto* cfg=SingletonCSkillMgr::instance().GetSkillCfg(skill);if(!cfg)return false;
                    pet->skill[suffix-1]=skill;pet->skillLevel[suffix-1]=member.level;
                }
            }
            if(loadout)for(int slot=0;slot<10;++slot) {
                const uint8 pos=static_cast<uint8>(slot<5?slot+1:opponent+slot-5);
                auto pet=boost::any_cast<SharePetPtr>(specimen.m_members[pos-1].memPtr);
                ShareUserPtr owner(new CUser);owners.push_back(owner);
                std::vector<uint8> bytes;
                auto append=[&](const auto& value){const auto* first=reinterpret_cast<const uint8*>(&value);bytes.insert(bytes.end(),first,first+sizeof(value));};
                // Same legacy formation/equipment decoders as the real load route.
                append(uint8(0xff));append(uint8(0));append(uint8(0));append(uint8(1));append(uint16(pet->id));
                std::string serialized;if(!Compress(bytes.data(),static_cast<uint32>(bytes.size()),serialized))return false;
                owner->SetZhenFa(&serialized[0]);if(owner->GetChuZhanIdx(pet->id)!=1)return false;
                const int suit=slot+1,family=1+(roster*10+slot)%14;
                const auto& artifacts=formalArtifacts.at(family);
                const int qualityIndex=(roster*10+slot)/14;
                const uint16 firstArtifact=artifacts[qualityIndex%artifacts.size()];
                const auto& secondFamily=formalArtifacts.at(family%14+1);
                const uint16 secondArtifact=secondFamily[(qualityIndex+(variant?0:2))%secondFamily.size()];
                bytes.clear();append(uint16(4));
                for(int part=1;part<=4;++part){append(uint32(2121300000+encounter*100+slot*10+part));append(formalEquipment.at({suit,part}));append(uint32(0));append(uint32(0));append(uint8(1));append(uint8(0));}
                append(uint16(2));
                for(int part=5;part<=6;++part){append(uint32(2121300000+encounter*100+slot*10+part));append(part==5?firstArtifact:secondArtifact);append(uint32(0));append(uint8(1));append(uint8(part));append(uint8(0));}
                append(uint32(0));append(uint16(0));
                if(!Compress(bytes.data(),static_cast<uint32>(bytes.size()),serialized))return false;
                auto& equipment=owner->GetPetEquipMgr();equipment.LoadData(&serialized[0]);
                FormationEquipMap worn;equipment.GetWornEquipment(1,worn);
                if(worn.size()!=6)return false;
                MultiAttr attributes;equipment.GetEquipAttr(1,attributes);
                const int initialMax=pet->basicAttr.maxHp;
                // Persist the same flat/ratio inputs used by SPet::CalcAttr.
                // SetUnitBasicData recalculates core stats from these inputs.
                auto& basic=pet->basicAttr;
                basic.attackEx+=GetAttrValue(attributes,EAT_Attack);basic.attackRatio+=GetAttrValue(attributes,EAT_AttackAdd);
                basic.wufangEx+=GetAttrValue(attributes,EAT_WuFang);basic.wufangRatio+=GetAttrValue(attributes,EAT_WuFangAdd);
                basic.fafangEx+=GetAttrValue(attributes,EAT_FaFang);basic.fafangRatio+=GetAttrValue(attributes,EAT_FaFangAdd);
                basic.maxHpEx+=GetAttrValue(attributes,EAT_QiXue);basic.maxHpRatio+=GetAttrValue(attributes,EAT_QiXueAdd);
                basic.speed=static_cast<int>((basic.speed+GetAttrValue(attributes,EAT_SuDu))*(1.0+GetAttrValue(attributes,EAT_SuDuAdd)/10000.0));
                MultiAttr noncore;
                for(const auto& attr:attributes)if(attr.attrType!=EAT_Attack && attr.attrType!=EAT_AttackAdd
                    && attr.attrType!=EAT_WuFang && attr.attrType!=EAT_WuFangAdd && attr.attrType!=EAT_FaFang && attr.attrType!=EAT_FaFangAdd
                    && attr.attrType!=EAT_QiXue && attr.attrType!=EAT_QiXueAdd && attr.attrType!=EAT_SuDu && attr.attrType!=EAT_SuDuAdd)noncore.push_back(attr);
                basic.AddAttrValue(noncore);
                pet->hp=static_cast<int>(static_cast<int64>(pet->hp)*pet->basicAttr.maxHp/initialMax);
                equipment.GetSuitSkills(1,pet->otherSkill);
                if(slot)loadoutRows+=",";
                loadoutRows+="{\"pos\":"+std::to_string(pos)+",\"hero\":"+std::to_string(pet->id)+",\"suit\":"+std::to_string(suit)+",\"equipment\":[";
                for(int part=1;part<=4;++part){auto* value=equipment.GetEqiup(worn.at(part));auto* cfg=value?sCItemCfgManager.GetEquipCfg(value->id):nullptr;
                    if(!cfg || cfg->part!=part || cfg->suit!=suit)return false;
                    if(part>1)loadoutRows+=",";
                    loadoutRows+="["+std::to_string(part)+","+std::to_string(value->uid)+","+std::to_string(value->id)+","+std::to_string(value->specialAffixId)+","+std::to_string(value->specialAffixTier)+"]";
                }
                loadoutRows+="],\"artifacts\":["+std::to_string(firstArtifact)+","+std::to_string(secondArtifact)
                    +"],\"core_inputs\":["+std::to_string(basic.attackEx)+","+std::to_string(basic.attackRatio)+","+std::to_string(basic.maxHpEx)+","+std::to_string(basic.maxHpRatio)+"]}";
            }
            for(uint8 pos=1;pos<=MAX_MEMBER;++pos)if(!specimen.m_members[pos-1].memPtr.empty())specimen.SetUnitBasicData(pos);
            if(loadout)for(int slot=0;slot<10;++slot) {
                const uint8 pos=static_cast<uint8>(slot<5?slot+1:opponent+slot-5);
                const int hero=specimen.GetHeroId(pos);
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.HeroBuildSnapshotEquipment(pos,owners[slot].get(),hero);
                if(specimen.HeroBuildSetPieces(pos,slot+1)!=4)return false;
#else
                specimen.CombatSnapshotEquipment(pos,owners[slot].get(),hero);
                if(specimen.m_members[pos-1].combatLoadout.pieces[slot+1]!=4)return false;
#endif
            }
            if(loadout)std::cout<<"BINARY_DIFF_LOADOUT {\"encounter\":"<<encounter<<",\"units\":["<<loadoutRows<<"]}"<<std::endl;
            if(closure) {
                // Explicit business precondition, not a cast/coverage credit:
                // a living enemy starts with a real shield committed by AddBuff.
                std::vector<int> shield(2,20000);
                specimen.AddBuff(opponent,opponent,ESBUFF_Shield,3,&shield);
                if(!specimen.IsAlive(opponent) || !specimen.HaveShieldState(opponent))return false;
            }
            specimen.AddTeamRage(1,80,false);specimen.AddTeamRage(opponent,80,false);std::srand(seed);
#ifdef _WIN32
            LARGE_INTEGER performanceFrequency;if(!QueryPerformanceFrequency(&performanceFrequency))return false;
            std::vector<double> roundMilliseconds;
#endif
            for(int turn=0;turn<12;++turn) {
                if(trace)std::cout<<"BINARY_DIFF_TRACE_BEGIN encounter="<<encounter<<" turn="<<turn<<std::endl;
                CNetMessage round;round.SetType(0);
                const bool active=!specimen.OneGroupAllDie();
#ifdef _WIN32
                LARGE_INTEGER beforeCalculation,afterCalculation;QueryPerformanceCounter(&beforeCalculation);
#endif
                if(active)specimen.CalculateFight(round);
#ifdef _WIN32
                QueryPerformanceCounter(&afterCalculation);
                if(active)roundMilliseconds.push_back(1000.0*(afterCalculation.QuadPart-beforeCalculation.QuadPart)/performanceFrequency.QuadPart);
#endif
                emit(branchMode+1,seed,"encounter"+std::to_string(encounter)+"_turn"+std::to_string(turn),specimen.m_fightTurn,&round);
            }
#ifdef _WIN32
            if(loadout) {
                double total=0;for(double value:roundMilliseconds)total+=value;
                std::cout<<"BINARY_DIFF_PERF {\"encounter\":"<<encounter<<",\"calculation_ms\":"<<total<<",\"round_ms\":[";
                for(size_t i=0;i<roundMilliseconds.size();++i){if(i)std::cout<<",";std::cout<<roundMilliseconds[i];}
                std::cout<<"]}"<<std::endl;
            }
#endif
#ifndef HERO_AFFIX_BINARY_DIFF_LEGACY
            specimen.m_combatObserver={};
            std::cout<<"BINARY_DIFF_COVERAGE {\"encounter\":"<<encounter<<",\"expected\":[";
            bool comma=false;
            for(uint8 pos=1;pos<=MAX_MEMBER;++pos)if(!specimen.m_members[pos-1].memPtr.empty()) {
                const auto& member=specimen.m_members[pos-1];
                for(int suffix=1;suffix<=4;++suffix) {
                    if(comma)std::cout<<",";comma=true;
                    std::cout<<"["<<specimen.GetHeroId(pos)<<","<<static_cast<int>(member.combatBranch)<<","<<specimen.GetHeroId(pos)*10+suffix<<"]";
                }
            }
            std::cout<<"],\"observed\":[";comma=false;
            for(const auto& row:observed) {
                if(comma)std::cout<<",";comma=true;
                std::cout<<"["<<std::get<0>(row.first)<<","<<std::get<1>(row.first)<<","<<std::get<2>(row.first)<<",\""<<std::get<3>(row.first)<<"\","<<row.second<<"]";
            }
            std::cout<<"]}"<<std::endl;
#endif
        }
        return true;
    }
    if(diffScope=="hero15b_battle" || diffScope=="hero15a_battle" || diffScope=="hero61a_battle" || diffScope=="hero61b_battle" || diffScope=="hero65a_battle" || diffScope=="hero65b_battle") {
        for(int branch:{0,(diffScope=="hero15b_battle" || diffScope=="hero61b_battle" || diffScope=="hero65b_battle")?2:1})for(int seed:{1,1729,7907})for(int strategy=1;strategy<=5;++strategy)for(int variant=0;variant<2;++variant) {
            setup(0,seed);specimen.Clear();
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
            specimen.m_heroBuildSecondaryDamage=false;
#else
            specimen.m_combatDepth=0;
#endif
            for(int slot=0;slot<6;++slot) {
                const uint8 pos=static_cast<uint8>(slot<3?slot+1:opponent+slot-3);
                const int hero=slot==0?((diffScope=="hero61a_battle" || diffScope=="hero61b_battle")?61:(diffScope=="hero65a_battle" || diffScope=="hero65b_battle")?65:15):23;addUnit(pos,hero,slot==0?branch:0,variant?6000:20000,variant?6000:20000);
                auto& member=specimen.m_members[pos-1];member.level=10;member.attackType=slot%2+1;
                member.unitAttr.attack=member.unitAttr.attackBase=variant?2000:1500;
                member.unitAttr.wufang=member.unitAttr.fafang=member.unitAttr.wufangBase=member.unitAttr.fafangBase=400;
                member.unitAttr.speed=100+slot;member.unitAttr.baojiAdd=15000;
                member.unitAttr.fanjiAdd=member.unitAttr.lianjiAdd=10000;
                auto pet=boost::any_cast<SharePetPtr>(member.memPtr);pet->basicAttr=member.unitAttr;pet->hp=member.hp;pet->level=10;pet->attackType=member.attackType;
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                member.heroBuildStrategy=slot==0?strategy:1;
#else
                member.combatStrategy=slot==0?strategy:1;
#endif
                for(int suffix=1;suffix<=4;++suffix) {
                    const int skill=hero*10+suffix;auto* cfg=SingletonCSkillMgr::instance().GetSkillCfg(skill);if(!cfg)return false;
                    pet->skill[suffix-1]=skill;pet->skillLevel[suffix-1]=10;
                    SSkillData data(skill,10);data.CD=cfg->CD;
                    if(cfg->type==ESKILL_Passive)member.passive_skill.push_back(data);else member.skill_list.push_back(data);
                }
            }
            // Use the actual unit initializer, including trigger-30 attributes.
            for(uint8 pos=1;pos<=MAX_MEMBER;++pos)if(!specimen.m_members[pos-1].memPtr.empty())specimen.SetUnitBasicData(pos);
            specimen.AddTeamRage(1,80,false);specimen.AddTeamRage(opponent,80,false);std::srand(seed);
            for(int turn=0;turn<8;++turn) {
                CNetMessage round;round.SetType(0);
                if(!specimen.OneGroupAllDie())specimen.CalculateFight(round);
                emit(branch,seed,"strategy"+std::to_string(strategy)+"_variant"+std::to_string(variant)+"_turn"+std::to_string(turn),specimen.m_fightTurn,&round);
            }
        }
        return true;
    }
    if(diffScope=="hero61b") {
        for(int branch:{0,2})for(int seed:{1,1729,7907})for(int scenario=0;scenario<18;++scenario) {
            setup(0,seed);addUnit(1,61,branch,0);addUnit(opponent,23,0,100000,100000);addUnit(opponent+1,23,0,100000,100000);
            auto& source=specimen.m_members[0];source.skill_list.clear();const int level=scenario==1?100:1;
            source.state=static_cast<uint8>(1<<(EFST_STATE_Die-1));source.passive_skill.push_back(SSkillData(613,level));
            auto blast=[&](int trigger=ESkill_Trigger_DieAndAddToOtherUnit) {std::vector<ESkillTriggerType> triggers{static_cast<ESkillTriggerType>(trigger)};return specimen.CalculatePassiveSkill_ExtUnitAndBuff(1,0,triggers,0,0);};
            CNetMessage output;output.SetType(0);int selection=0;
            if(scenario==3)source.affixSummoned=true;
            if(scenario==4 || scenario==5){specimen.m_members[opponent-1].memPtr=boost::any();specimen.m_members[opponent].memPtr=boost::any();}
            if(scenario==6)source.passive_skill.clear();
            if(scenario==8)boost::any_cast<SharePetPtr>(source.memPtr)->id=23;
            if(scenario==9) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
            }
            if(scenario==11){std::vector<int> shield(2,3000);specimen.AddBuff(opponent,opponent,ESBUFF_Shield,3,&shield);}
            if(scenario==14)source.passive_skill.push_back(SSkillData(613,1));
            if(scenario==17) {
                auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(613);std::vector<int> p;specimen.GetPassivePara(1,p,effect,level);
#ifndef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.CombatPassiveParameters(1,0,613,effect,level,ESkill_Trigger_DieAndAddToOtherUnit,p);
#endif
                selection=p[1]+p[2];
            } else if(scenario==10 || scenario==15 || scenario==16) {
                source.state=0;source.hp=10000;int damage=20000,absorbed=0;specimen.DecreaseHp(1,opponent,damage,absorbed);
                if(scenario==15)source.state|=static_cast<uint8>(1<<(EFST_STATE_Escape-1));
                selection=specimen.DiePassiveAcion(output);
                if(scenario==16){source.state=0;source.hp=10000;damage=20000;specimen.DecreaseHp(1,opponent,damage,absorbed);selection+=specimen.DiePassiveAcion(output);}
            } else selection=blast(scenario==7?ESkill_Trigger_TurnBegin:ESkill_Trigger_DieAndAddToOtherUnit);
            if(scenario==2 || scenario==13){if(scenario==13)++specimen.m_fightTurn;selection+=blast();}
            if(scenario==5){addUnit(opponent,23,0,100000,100000);selection+=blast();}
            if(scenario==12){std::vector<ESkillTriggerType> triggers{ESkill_Trigger_DieAndAddToOtherUnit,ESkill_Trigger_DieAndAddToOtherUnit};selection+=specimen.CalculatePassiveSkill_ExtUnitAndBuff(1,0,triggers,0,0);}
            emit(branch,seed,"case"+std::to_string(scenario),selection,&output);
        }
        return true;
    }
    if(diffScope=="hero65b") {
        for(int branch:{0,2})for(int seed:{1,1729,7907})for(int scenario=0;scenario<16;++scenario) {
            setup(0,seed);addUnit(1,65,branch,10000);addUnit(opponent,23,0,1000000,1000000);auto& source=specimen.m_members[0];
            const int level=scenario==1 || scenario==3?75:1;source.skill_list.clear();auto pet=boost::any_cast<SharePetPtr>(source.memPtr);
            for(int suffix=1;suffix<=4;++suffix){const int skill=650+suffix;pet->skill[suffix-1]=skill;pet->skillLevel[suffix-1]=level;}
            source.attackType=1;source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            specimen.m_members[opponent-1].unitAttr.baojikangLv=10000;
            if(scenario==6)pet->id=23;
            if(scenario==11)pet->skill[3]=0;
            pet->basicAttr=source.unitAttr;pet->hp=source.hp;pet->attackType=source.attackType;specimen.SetUnitBasicData(1);
            int selection=0;CNetMessage output;output.SetType(0);
            if(scenario<2 || scenario==14) {
                auto* effect=SingletonCSkillMgr::instance().GetAdditiveEffectCfg(654);std::vector<int> p;specimen.GetPassivePara(1,p,effect,level);
#ifndef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.CombatPassiveParameters(1,0,654,effect,level,ESkill_Trigger_AddAttrBeginFight,p);
#endif
                selection=p[1];
            }
            if(scenario==7)specimen.m_members[opponent-1].notEffectBuff.push_back(ESBUFF_FaFangDes);
            if(scenario==8) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
            }
            if(scenario==9){source.hp=0;specimen.SetState(1,EFST_STATE_Die);}
            if(scenario==10)specimen.m_members[opponent-1].memPtr=boost::any();
            if(scenario==15){std::vector<ESkillTriggerType> triggers{ESkill_Trigger_FightBegin};std::vector<ESkillPassitiveType> types{ESkill_Pass_Attr};specimen.CalculatePassiveSkill_ExtAttrEffect(1,0,triggers,types);}
            if(scenario>=4)selection+=specimen.CalculateSkill_DamageHp(1,scenario==5?651:652,level);
            if(scenario==12){++specimen.m_fightTurn;specimen.DecAllStateEffectTurn(opponent);}
            if(scenario==13)selection+=specimen.CalculateSkill_DamageHp(1,652,level);
            emit(branch,seed,"case"+std::to_string(scenario),selection,&output);
        }
        return true;
    }
    if(diffScope=="hero65a") {
        for(int branch:{0,1})for(int seed:{1,1729,7907})for(int scenario=0;scenario<14;++scenario) {
            setup(0,seed);addUnit(1,65,branch,10000);addUnit(opponent,23,0,1000000,1000000);addUnit(opponent+1,23,0,1000000,1000000);
            auto& source=specimen.m_members[0];source.skill_list.clear();const int level=scenario==1 || scenario==3?75:1;
            for(int skill:{651,652}){SSkillData data(skill,level);data.CD=SingletonCSkillMgr::instance().GetSkillCfg(skill)->CD;source.skill_list.push_back(data);}
            if(scenario!=11)source.passive_skill.push_back(SSkillData(653,level));
            source.attackType=1;source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            for(uint8 pos:{opponent,static_cast<uint8>(opponent+1)})specimen.m_members[pos-1].unitAttr.baojikangLv=10000;
            auto aura=[&]() {std::vector<ESkillTriggerType> triggers{ESkill_Trigger_FightBegin};std::vector<ESkillPassitiveType> types{ESkill_Pass_Attr};specimen.CalculatePassiveSkill_ExtAttrEffect(1,0,triggers,types);};
            if(scenario==6)boost::any_cast<SharePetPtr>(source.memPtr)->id=23;
            if(scenario==9){source.hp=0;specimen.SetState(1,EFST_STATE_Die);}
            if(scenario==10){specimen.m_members[opponent-1].hp=0;specimen.SetState(opponent,EFST_STATE_Die);}
            if(scenario==7)specimen.m_members[opponent-1].notEffectBuff.push_back(ESBUFF_ShiDu);
            aura();int selection=0;CNetMessage output;output.SetType(0);
            if(scenario==5) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
            }
            if(scenario>=2 && scenario!=9 && scenario!=10)selection=specimen.CalculateSkill_DamageHp(1,scenario==4?652:651,level);
            if(scenario==8){specimen.m_curActionPos=opponent;specimen.DecAllStateEffectTurn(opponent);}
            if(scenario==12)selection+=specimen.CalculateSkill_DamageHp(1,651,level);
            if(scenario==13)for(int tick=0;tick<3;++tick){++specimen.m_fightTurn;specimen.UnitPassiveAction(opponent,EFStep_UserActBegin,output,0);specimen.DecAllStateEffectTurn(opponent);}
            emit(branch,seed,"case"+std::to_string(scenario),selection,&output);
        }
        return true;
    }
    if(diffScope=="hero61a") {
        for(int branch:{0,1})for(int seed:{1,1729,7907})for(int scenario=0;scenario<12;++scenario) {
            setup(0,seed);addUnit(1,61,branch,10000);auto& source=specimen.m_members[0];source.skill_list.clear();
            for(int skill:{611,612}){SSkillData data(skill,1);data.CD=SingletonCSkillMgr::instance().GetSkillCfg(skill)->CD;source.skill_list.push_back(data);}
            source.attackType=1;source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=source.unitAttr.fanjiAdd=10000;
            source.unitAttr.baojikangLv=specimen.m_members[opponent-1].unitAttr.baojikangLv=10000;
            specimen.m_members[opponent-1].unitAttr.fanjiAdd=10000;
            auto cast=[&](int skill=611,int level=1){return specimen.CalculateSkill_DamageHp(1,skill,level);};
            CNetMessage output;output.SetType(0);int selection=0;
            if(scenario==0)selection=cast();
            if(scenario==1)selection=cast(611,75);
            if(scenario==2)selection=cast(612);
            if(scenario==3) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
                selection=cast();
            }
            if(scenario==4 || scenario==11){source.hp=1;specimen.m_members[opponent-1].unitAttr.fanjiLv=20000;selection=cast();}
            if(scenario==5){specimen.m_members[opponent-1].memPtr=boost::any();selection=cast();}
            if(scenario==6){boost::any_cast<SharePetPtr>(source.memPtr)->id=23;selection=cast();}
            if(scenario==7){source.notEffectBuff.push_back(ESBUFF_JianShangLvAdd);selection=cast();}
            if(scenario==8){specimen.m_curActionPos=1;selection=cast();specimen.DecAllStateEffectTurn(1);}
            if(scenario==9){selection=cast();selection+=cast();}
            if(scenario==10){selection=cast();++specimen.m_fightTurn;specimen.DecAllStateEffectTurn(1);}
            if(scenario==11){source.passive_skill.push_back(SSkillData(613,1));specimen.DiePassiveAcion(output);}
            emit(branch,seed,"case"+std::to_string(scenario),selection,&output);
        }
        return true;
    }
    if(diffScope=="hero15b" || diffScope=="hero15a") {
        for(int branch:{0,diffScope=="hero15a"?1:2})for(int seed:{1,1729,7907})for(int scenario=0;scenario<(diffScope=="hero15a"?36:20);++scenario) {
            setup(0,seed);addUnit(1,15,branch,10000);addUnit(opponent+1,23,0,3000);
            auto& source=specimen.m_members[0];source.option=EOTNormal;
            source.skill_list.clear();source.skill_list.push_back(SSkillData(151,1));source.skill_list.push_back(SSkillData(152,1));
            for(auto& skill:source.skill_list)skill.CD=SingletonCSkillMgr::instance().GetSkillCfg(skill.id)->CD;
            source.unitAttr.mingzhongLv=10000;source.unitAttr.lianjiAdd=10000;source.unitAttr.fanjiAdd=10000;
            for(uint8 pos:{opponent,static_cast<uint8>(opponent+1)})specimen.m_members[pos-1].unitAttr.baojikangLv=10000;
            CNetMessage output;output.SetType(0);int selection=0;
            auto death=[&](uint8 target,bool escaped=false) {
                specimen.m_members[target-1].hp=0;specimen.SetState(target,EFST_STATE_Die);
                if(escaped)specimen.m_members[target-1].state|=static_cast<uint8>(1<<(EFST_STATE_Escape-1));
                std::vector<ESkillTriggerType> triggers{ESkill_Trigger_UnitDied};std::vector<ESkillPassitiveType> types{ESkill_Pass_Attr};
                specimen.CalculatePassiveSkill_ExtAttrEffect(1,target,triggers,types);
            };
            auto chase=[&]() {source.AddKillUnit(opponent);selection+=specimen.KilledAction(1,output);};
            if(scenario<9)source.passive_skill.push_back(SSkillData(154,scenario==4?75:1));
            if(scenario==0 || scenario==4)death(opponent);
            if(scenario==1)death(2);
            if(scenario==2)for(int i=0;i<7;++i)death(i%2?2:opponent);
            if(scenario==3){specimen.m_members[opponent-1].affixSummoned=true;death(opponent);}
            if(scenario==5)death(opponent,true);
            if(scenario==6){death(opponent);++specimen.m_fightTurn;death(opponent);}
            if(scenario==7){for(int i=0;i<5;++i)death(opponent);specimen.m_members[opponent-1].affixSummoned=true;death(opponent);}
            if(scenario==8){int damage=20000,absorbed=0;specimen.DecreaseHp(opponent,1,damage,absorbed);specimen.DiePassiveAcion(output);}
            if(scenario==9)chase();
            if(scenario==10 || scenario==11){source.passive_skill.push_back(SSkillData(153,scenario==11?75:1));chase();}
            if(scenario==12){chase();chase();}
            if(scenario==13){chase();++specimen.m_fightTurn;chase();}
            if(scenario==14) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                source.heroBuildRevivedTurn=specimen.m_fightTurn;
#else
                specimen.m_combatState.revivedAt[1]=specimen.m_fightTurn;
#endif
                chase();
            }
            if(scenario==15) {
                for(int i=0;i<4;++i) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                    specimen.HeroBuildTryExtraAttack(1);
#else
                    specimen.CombatTryExtraAttack(1);
#endif
                }
                chase();chase();
            }
            if(scenario==16){specimen.m_members[opponent-1].hp=0;specimen.SetState(opponent,EFST_STATE_Die);
                specimen.m_members[opponent].hp=0;specimen.SetState(opponent+1,EFST_STATE_Die);chase();}
            if(scenario==17)selection=specimen.KilledAction(1,output);
            if(scenario==18){source.hp=0;specimen.SetState(1,EFST_STATE_Die);chase();}
            if(scenario==19){specimen.m_members[opponent].hp=1;chase();chase();}
            auto hit=[&](int skill,bool first=true,bool counter=false,int level=1) {
                std::vector<SAttrData> own,other;int self=0;specimen.BasicFightAction(1,opponent,skill,level,self,own,other,counter,first);
            };
            auto vulnerability=[&](int amount){std::vector<int> p{amount};specimen.AddBuff(opponent,1,ESBUFF_GetWuDamageAdd,3,&p);};
            if(scenario==20)hit(151);
            if(scenario==21)hit(151,true,false,75);
            if(scenario==22)hit(152);
            if(scenario==23){vulnerability(500);hit(152);}
            if(scenario==24){vulnerability(1500);hit(152);}
            if(scenario==25){vulnerability(800);hit(152);}
            if(scenario==26)hit(152,false);
            if(scenario==27)hit(152,true,true);
            if(scenario==28) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
                hit(152);
            }
            if(scenario==29 || scenario==30) {
                source.option=EOTSkill;source.para=scenario==29?152:151;source.target=opponent;
                selection=specimen.NotKilledAction(1,output);
            }
            if(scenario>=31) {
                source.option=EOTSkill;source.para=scenario==32?151:152;source.target=opponent;
                source.passive_skill.push_back(SSkillData(153,1));
                if(scenario==34)for(int i=0;i<4;++i) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                    specimen.HeroBuildTryExtraAttack(1);
#else
                    specimen.CombatTryExtraAttack(1);
#endif
                }
                if(scenario==35) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                    source.heroBuildRevivedTurn=specimen.m_fightTurn;
#else
                    specimen.m_combatState.revivedAt[1]=specimen.m_fightTurn;
#endif
                }
                chase();if(scenario==33 || scenario==34)chase();
            }
            emit(branch,seed,"case"+std::to_string(scenario),selection,&output);
        }
        return true;
    }
    if(diffScope=="pursuit") {
        for(int branch:{0,2})for(int seed:{1,1729,7907})for(int scenario=0;scenario<22;++scenario) {
            setup(0,seed);addUnit(1,15,branch,10000);
            specimen.m_members[0].unitAttr.attack=1001;specimen.m_members[0].unitAttr.mingzhongLv=10000;
            specimen.m_members[0].unitAttr.lianjiAdd=10000;specimen.m_members[0].unitAttr.fanjiAdd=10000;
            specimen.m_members[opponent-1].unitAttr.baojikangLv=10000;
            auto hit=[&](int skill=151,bool first=true,bool counter=false) {
                std::vector<SAttrData> own,other;int self=0;
                specimen.BasicFightAction(1,opponent,skill,1,self,own,other,counter,first);
            };
            auto event=[&](int amount) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.HeroBuildAfterDirectHit(1,opponent,151,false,amount);
#else
                specimen.CombatEvent("after_primary_hit",1,opponent,151,0,1,
                    {{"amount",amount},{"event_target_alive",specimen.IsAlive(opponent)?1:0}});
#endif
            };
            auto exhaust=[&]() {
                for(int i=0;i<4;++i) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                    specimen.HeroBuildTryExtraAttack(1);
#else
                    specimen.CombatTryExtraAttack(1);
#endif
                }
            };
            auto shield=[&](int amount){std::vector<int> p{amount,amount};specimen.AddBuff(opponent,opponent,ESBUFF_Shield,3,&p);};
            if(scenario==0)hit();
            if(scenario==1){shield(5000);hit();}
            if(scenario==2)hit(151,false);
            if(scenario==3)hit(151,true,true);
            if(scenario==4){hit();hit();}
            if(scenario==5){hit();++specimen.m_fightTurn;hit();}
            if(scenario==6){exhaust();hit();}
            if(scenario==7){event(0);event(1000);}
            if(scenario==8){specimen.SetState(opponent,EFST_STATE_Die);specimen.m_members[opponent-1].hp=0;event(0);
                specimen.ClearState(opponent,EFST_STATE_Die);specimen.m_members[opponent-1].hp=10000;event(1000);}
            if(scenario==9) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
                hit();
            }
            if(scenario==10){specimen.m_members[opponent-1].hp=3999;hit(152);}
            if(scenario==11){specimen.m_members[opponent-1].hp=4000;hit(152);}
            if(scenario==12){specimen.m_members[opponent-1].hp=1;hit();}
            if(scenario==13){specimen.m_members[opponent-1].hp=1600;hit();}
            if(scenario==14){shield(350);hit();}
            if(scenario==15){addUnit(opponent,12,2,10000);addUnit(opponent+1,23,0,10000);shield(350);hit();}
            if(scenario==16){exhaust();event(0);++specimen.m_fightTurn;event(1000);}
            if(scenario==17){addUnit(1,23,branch,10000);hit();}
            if(scenario==18){specimen.SetState(1,EFST_STATE_Die);specimen.m_members[0].hp=0;event(1000);}
            if(scenario==19){shield(1000);hit();}
            if(scenario==20)specimen.CalculateSkill_DamageHp(1,151,75);
            if(scenario==21){specimen.m_members[opponent-1].hp=3999;specimen.CalculateSkill_DamageHp(1,152,75);}
            emit(branch,seed,"case"+std::to_string(scenario));
        }
        return true;
    }
    if(diffScope=="shield_full") {
        for(int branch:{1,2})for(int seed:{1,1729,7907})for(int scenario=0;scenario<31;++scenario) {
            setup(0,seed);addUnit(1,12,branch,10000);addUnit(2,23,0,4000);addUnit(opponent+1,23,0,10000);
            std::vector<int> p{1001,1001,2500};
            auto shield=[&](uint16 origin,int duration=2,uint8 target=2){specimen.AddBuff(target,1,ESBUFF_Shield,duration,&p,origin);};
            auto remove=[&](uint16 origin,bool expired=false,int remaining=0) {
                SFightBuffData b;b.id=ESBUFF_Shield;b.srcPos=1;b.originSkill=origin;b.leftTurn=expired?1:2;b.paraList={remaining,1001};
                specimen.m_members[1].buff_list.push_back(b);specimen.SpecialBuffPassAttr(2,b.id,true);
                if(expired)specimen.DecAllStateEffectTurn(2);else specimen.ShieldBrokenCheck(2,opponent);
            };
            if(scenario==0)specimen.AddBuff(2,1,ESBUFF_ShieldMianShang,2,&p,121);
            if(scenario==1)shield(122);
            if(scenario==2){addUnit(3,12,1,10000);addUnit(2,12,1,4000);shield(0);}
            if(scenario==3){addUnit(3,12,1,0);specimen.SetState(3,EFST_STATE_Die);shield(0);}
            if(scenario==4){addUnit(opponent,12,1,10000);shield(0);}
            if(scenario==5){addUnit(opponent,12,1,10000);specimen.AddBuff(opponent,1,ESBUFF_Shield,2,&p,121);}
            if(scenario==6){p={7,7};shield(121);}
            if(scenario==7){specimen.m_members[0].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(2)->passiveSkillId,3));shield(122,255,1);}
            if(scenario==8)remove(121);
            if(scenario==9)remove(122);
            if(scenario==10)remove(122,true,601);
            if(scenario==11)remove(122,true,1001);
            if(scenario==12){shield(122);int damage=400,absorb=0;specimen.ShieldAbsorptionDamage(2,damage,absorb);specimen.ClearBuff(2,ESBUFF_Shield);}
            if(scenario==13){remove(122);remove(122);remove(122);}
            if(scenario==14){remove(121);remove(121);++specimen.m_fightTurn;remove(121);}
            if(scenario==15){std::vector<int> defense{500,500};specimen.AddBuff(opponent,opponent,ESBUFF_Shield,2,&defense);remove(121);}
            if(scenario==16){specimen.m_members[opponent-1].hp=7;specimen.m_members[opponent].hp=11;remove(121);}
            if(scenario==17){specimen.m_members[0].unitAttr.maxHp=100;specimen.m_members[0].hp=100;remove(122);remove(122);remove(122);}
            if(scenario==18){specimen.m_members[1].hp=0;specimen.SetState(2,EFST_STATE_Die);remove(122);specimen.ClearState(2,EFST_STATE_Die);specimen.m_members[1].hp=4000;remove(122);}
            if(scenario==19){specimen.m_members[0].hp=0;specimen.SetState(1,EFST_STATE_Die);remove(122);}
            if(scenario==20){
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
                remove(122);
            }
            if(scenario==21)remove(124);
            if(scenario==22){std::vector<int> anti{5000};specimen.AddBuff(2,opponent,ESBUFF_JinLiaoShu,2,&anti);remove(121);}
            if(scenario==23){addUnit(1,23,0,10000);shield(122);}
            if(scenario==24){shield(122);int damage=100000,absorb=0;specimen.ShieldAbsorptionDamage(2,damage,absorb);specimen.ShieldBrokenCheck(2,opponent);}
            if(scenario==25){specimen.CalculateSkill_AddBuff(1,121,1);}
            if(scenario==26){specimen.CalculateSkill_AddBuff(1,122,75);}
            if(scenario==27){specimen.m_members[0].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(44)->passiveSkillId,3));shield(122,255);specimen.m_members[0].unitAttr.mingzhongLv=10000;std::vector<SAttrData> own,other;int self=0;specimen.BasicFightAction(1,2,0,1,self,own,other,false,true);}
            if(scenario==28){addUnit(3,12,1,10000);specimen.AddBuff(2,0,ESBUFF_Shield,2,&p);}
            if(scenario==29 || scenario==30){SFightBuffData b;b.id=ESBUFF_Shield;b.srcPos=1;b.originSkill=122;b.leftTurn=1;b.paraList={scenario==29?601:0};specimen.m_members[1].buff_list.push_back(b);specimen.SpecialBuffPassAttr(2,b.id,true);if(scenario==29)specimen.DecAllStateEffectTurn(2);else specimen.ShieldBrokenCheck(2,opponent);}
            emit(branch,seed,"case"+std::to_string(scenario));
        }
        return true;
    }
    if(diffScope=="shield_core") {
        for(int seed:{1,1729,7907}) {
            setup(0,seed);specimen.m_curActionPos=1;std::vector<int> p{1000,1000};
            specimen.AddBuff(1,1,ESBUFF_FanZhengAllAdd,2,&p);specimen.DecAllStateEffectTurn(1);
            ++specimen.m_fightTurn;specimen.DecAllStateEffectTurn(1);emit(0,seed,"timing_self");
            setup(0,seed);specimen.m_curActionPos=1;specimen.AddBuff(2,1,ESBUFF_FanZhengAllAdd,2,&p);specimen.DecAllStateEffectTurn(2);emit(0,seed,"timing_other");
            setup(0,seed);addUnit(1,23,0,10000);addUnit(2,12,0,10000);specimen.m_members[1].passive_skill.push_back(SSkillData(123,1));
            SFightBuffData shield;shield.srcPos=1;shield.id=ESBUFF_Shield;shield.leftTurn=1;shield.paraList={400,1000};
            specimen.m_members[1].buff_list.push_back(shield);specimen.SpecialBuffPassAttr(2,shield.id,true);
            specimen.DecAllStateEffectTurn(2);emit(0,seed,"expired_legacy_absorbed");
            setup(0,seed);addUnit(1,23,0,10000);specimen.m_members[0].unitAttr.attack=1001;specimen.m_members[0].unitAttr.mingzhongLv=10000;
            specimen.m_members[opponent-1].unitAttr.baojikangLv=10000;
            specimen.m_members[0].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(44)->passiveSkillId,3));
            std::vector<int> forbid{1000};specimen.AddBuff(opponent,1,ESBUFF_ForbidFuHuo,255,&forbid);
            std::vector<SAttrData> own,other;int self=0;specimen.BasicFightAction(1,opponent,0,1,self,own,other,false,true);emit(0,seed,"affix44_int_duration");
        }
        for(int branch:{1,2})for(int seed:{1,1729,7907})for(int variant=0;variant<3;++variant) {
            setup(0,seed);addUnit(1,12,branch,variant==1?0:10000);addUnit(2,12,0,10000);
            if(variant==1)specimen.SetState(1,EFST_STATE_Die);
            specimen.m_members[1].passive_skill.push_back(SSkillData(123,1));
            SFightBuffData shield;shield.srcPos=1;shield.id=ESBUFF_Shield;shield.leftTurn=2;shield.originSkill=variant==2?0:124;shield.paraList={0,1000};
            specimen.m_members[1].buff_list.push_back(shield);specimen.SpecialBuffPassAttr(2,shield.id,true);
            if(variant==2) {
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
                specimen.m_heroBuildSecondaryDamage=true;
#else
                specimen.m_combatDepth=1;
#endif
            }
            specimen.ShieldBrokenCheck(2,opponent);
#ifdef HERO_AFFIX_BINARY_DIFF_LEGACY
            specimen.m_heroBuildSecondaryDamage=false;
#else
            specimen.m_combatDepth=0;
#endif
            emit(branch,seed,variant==0?"conversion_suppressed":variant==1?"dead_source_suppressed":"secondary_suppressed");
        }
        return true;
    }
    for(int branch:{1,2})for(int seed:{1,1729,7907}) {
        setup(branch,seed);specimen.CalculateSkill_AddHp(1,101,1);emit(branch,seed,"heal_l1");
        setup(branch,seed);specimen.CalculateSkill_AddHp(1,101,75);emit(branch,seed,"heal_l75");
        setup(branch,seed,9903);specimen.m_members[0].hp=9000;
        specimen.m_members[0].passive_skill.push_back(SSkillData(sCItemCfgManager.GetEquipAffixCfg(5)->passiveSkillId,3));
        specimen.CalculateSkill_AddHp(1,101,1);emit(branch,seed,"overheal_affix5");
        setup(branch,seed,0);specimen.SetState(2,EFST_STATE_Die);specimen.CalculateSkill_AddHp(1,102,75);emit(branch,seed,"revive_l75");
        setup(branch,seed,0);specimen.SetState(2,EFST_STATE_Die);specimen.CalculateSkill_AddHp(1,102,1);
        int damage=100000,absorbed=0;specimen.DecreaseHp(2,opponent,damage,absorbed,true);specimen.CalculateSkill_AddHp(1,102,1);emit(branch,seed,"repeat_revive");
        setup(branch,seed,1000);addUnit(3,23,0,11000,100000);specimen.CalculateSkill_AddHp(1,101,1);emit(branch,seed,"reselect");
        setup(branch,seed,1000);specimen.m_members[0].passive_skill.push_back(SSkillData(104,75));
        damage=100000;absorbed=0;specimen.DecreaseHp(1,opponent,damage,absorbed,true);CNetMessage death;death.SetType(0);specimen.DiePassiveAcion(death);emit(branch,seed,"self_revive",0,&death);
        setup(branch,seed,0);specimen.SetState(2,EFST_STATE_Die);specimen.m_members[0].skill_list.back().leftCD=0;specimen.m_teamRage[0]=80;
        const int before=specimen.GetUnitAISkillId(1);specimen.CalculateSkill_AddHp(1,102,1);
        damage=100000;absorbed=0;specimen.DecreaseHp(2,opponent,damage,absorbed,true);const int after=specimen.GetUnitAISkillId(1);
        emit(branch,seed,"ai_repeat",before*1000+after);
    }
    return true;
}
