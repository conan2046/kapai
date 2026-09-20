#include "fight.h"
#include <algorithm>

uint8 CFight::HeroBuildPeriodicActions(uint8 target,CNetMessage &msg)
{
    SFightMember *victim=GetFightMember(target);
    if(!victim || !IsAlive(target))return 0;
    // Freeze instances: damage may break a shield, revive, cleanse or add a buff.
    map<std::pair<uint8,uint16>,vector<SFightBuffData> > groups;
    for(list<SFightBuffData>::const_iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
        if(it->leftTurn>0 && !it->paraList.empty() && (it->id==ESBUFF_ShiXinDu || it->id==ESBUFF_ShiDu
            || it->id==ESBUFF_FuDu || it->id==ESBUFF_ZhuoShao || it->id==ESBUFF_JinGuZhou
            || it->id==ESBUFF_AddHpContinue || it->id==ESBUFF_Blooding))
            groups[std::make_pair(it->srcPos,it->id)].push_back(*it);
    uint8 events=0;
    for(map<std::pair<uint8,uint16>,vector<SFightBuffData> >::const_iterator group=groups.begin();group!=groups.end();++group)
    {
        if(!IsAlive(target))break;
        uint8 src=group->first.first;uint16 id=group->first.second;
        if(!GetFightMember(src))continue;
        int64 total=0;bool firstHot=false;
        for(size_t index=0;index<group->second.size();++index)
        {
            const SFightBuffData &buff=group->second[index];
            if(id==ESBUFF_AddHpContinue && !buff.periodicTicked)firstHot=true;
            int first=buff.paraList[0],second=buff.paraList.size()>1?buff.paraList[1]:0;
            int64 tick=0;
            if(id==ESBUFF_ShiXinDu)tick=std::min<int64>(GetMaxHp(target)*first/10000,second);
            else if(id==ESBUFF_FuDu)tick=std::min<int64>(GetHp(target)*first/10000,second);
            else if(id==ESBUFF_ShiDu)tick=first+second;
            else if(id==ESBUFF_JinGuZhou)tick=HeroBuildDotDamage(src,target,id,second);
            else tick=first;
            if(id==ESBUFF_Blooding && HaveBuff(target,ESBUFF_DamagePercentDes))tick=tick*120/100;
            if(id!=ESBUFF_JinGuZhou && id!=ESBUFF_AddHpContinue)
                tick=tick*(10000+std::min(10000,HeroBuildArtifactValue(src,10)+GetAffixValue(src,35,1)))/10000;
            total+=std::max<int64>(0,tick);
        }
        bool healing=id==ESBUFF_AddHpContinue;
        if(healing)for(list<SFightBuffData>::iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
            if(it->srcPos==src && it->id==id)it->periodicTicked=true;
        if(healing)
        {
            int bonus=HeroBuildArtifactValue(src,2)+(HeroBuildSetPieces(src,10)>=2?1000:0);
            if(HeroBuildSetPieces(target,5)>=4 && GetHp(target)*100<GetMaxHp(target)*40)bonus+=1000;
            total=total*(10000+std::min(10000,bonus))/10000;
            total=total*std::max(0,10000-GetStatePara1(target,ESBUFF_JinLiaoShu))/10000;
        }
        else
        {
            if(HeroBuildState(src,200020)!=m_fightTurn+1)
            {HeroBuildState(src,200020)=m_fightTurn+1;HeroBuildState(src,200021)=0;}
            total=std::min<int64>(total,std::max(0,GetUnitAttack(src)*2-HeroBuildState(src,200021)));
            HeroBuildState(src,200021)+=(int)total;
        }
        if(total<=0){if(healing)HeroBuildState(src,104000+target)=1;continue;}
        int value=healing?-(int)total:(int)total,absorbed=0,revived=0;
        int64 before=GetHp(target);bool previous=m_heroBuildSecondaryDamage;m_heroBuildSecondaryDamage=true;
        DecreaseHp(target,src,value,absorbed,false,&revived,false);
        m_heroBuildSecondaryDamage=previous;
        msg<<target<<-value<<absorbed<<revived;MakeBuffList(target,msg);++events;
        int actual=(int)(before-GetHp(target));
        if(healing && actual<0 && firstHot)HeroBuildEquipmentHeal(src,target,false,false);
        if(healing)HeroBuildState(src,104000+target)=1;
        if(!healing && actual>0 && GetAffixTier(src,36)>0 && IsAlive(src))
        {
            int cap=(int)(GetMaxHp(src)*GetAffixValue(src,36,2)/10000);
            int heal=std::min(actual*GetAffixValue(src,36,1)/10000,std::max(0,cap-GetFightMember(src)->affixTurnValue[36]));
            if(heal>0){GetFightMember(src)->affixTurnValue[36]+=heal;AddAffixHpAction(src,src,-heal,36,true);}
        }
        if(!healing && actual>0 && IsHeroBuild(src,60,1) && Random(1,10000)<=3000)
            for(list<SFightBuffData>::iterator it=victim->buff_list.begin();it!=victim->buff_list.end();++it)
                if(it->srcPos==src && it->originSkill==604)it->leftTurn=std::min(3,(int)it->leftTurn+1);
    }
    return events;
}
