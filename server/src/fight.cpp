#include "fight.h"
#include "utility.h"
#include "protocol.h"
#include "singleton.h"
#include "call_script.h"
#include "script_call.h"
#include "main.h"
#include "huo_dong.h"
#include "init.h"
#include "award_manager.h"
#include "tower_reward_manager.h"
#include "xun_bao_manage.h"
#include "config_para.h"
#include <algorithm>
#include <functional>
#include <boost/format.hpp>
#include <sys/socket.h>
#include "blood_fight_manage.h"
using namespace std;

extern list<ArenaPaiHangData> arenaPaiHang;
extern boost::recursive_mutex tongTianTa_mutex;
extern uint16 tongTianTaBaZhuFloor[5];
extern vector<uint32> tongTianTaBaZhuData;	// 通天塔霸主ID,12/24/36/48/60
extern map<int, int> guaiWuGongChengItemCount;
extern const char *gConfigFile;
const int VIP_PROTECTOR_HUSONG_LEVEL=7;
const int VIP_PROTECTOR_YAPIAO_LEVEL=6;//至尊6护送，押镖不损失
const int KILL_ROLE_TIMES_LIMIT_GAIN = 50;	// 本帮内击杀收益次数限制
const int BANG_GONG_KILL_ROLE = 5;		// 本帮内击杀玩家帮贡

enum FightSideType
{
	FST_ATTACK = 1,	// 攻方
	FST_DEFEND = 2,	// 守方
};

struct SSortData
{
	SSortData()
	{
		data = 0;
		value = 0;
	}
	int data;
	int value;
};

static bool MaxToMinSort(const SSortData &t1,const SSortData &t2)
{
	return t1.value > t2.value;
}

static bool MinToMaxSort(const SSortData &t1,const SSortData &t2)
{
	return t1.value < t2.value;
}

static int GetFightSideRatio(FightSideType type,int level)
{
	int a = 5;
	int b = 20;
	if(level <= 40)
	{
		a = 5;
		b = 20;
	}
	else if(level <= 60)
	{
		a = 10;
		b = -180;
	}
	else if(level <= 70)
	{
		a = 15;
		b = -480;
	}
	else if(level <= 80)
	{
		a = 20;
		b = -830;
	}
	else if(level <= 90)
	{
		a = 25;
		b = -1230;
	}
	else
	{
		a = 30;
		b = -1680;
	}
	return (a*level + b);
}

static int GetParaMingZhong1()
{
	static int mingzhong1 = CParaMgr::ErrInt;
	if(mingzhong1 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("mingzhong_1");
		if(v != CParaMgr::ErrInt)
			mingzhong1 = v;
	}
	return mingzhong1;
}

static int GetParaMingZhong2()
{
	static int mingzhong2 = CParaMgr::ErrInt;
	if(mingzhong2 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("mingzhong_2");
		if(v != CParaMgr::ErrInt)
			mingzhong2 = v;
	}
	return mingzhong2;
}

static int GetParaShanBi1()
{
	static int shanbi1 = CParaMgr::ErrInt;
	if(shanbi1 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("shanbi_1");
		if(v != CParaMgr::ErrInt)
			shanbi1 = v;
	}
	return shanbi1;
}

static int GetParaShanBi2()
{
	static int shanbi2 = CParaMgr::ErrInt;
	if(shanbi2 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("shanbi_2");
		if(v != CParaMgr::ErrInt)
			shanbi2 = v;
	}
	return shanbi2;
}

static int GetParaBaoJi1()
{
	static int baoji1 = CParaMgr::ErrInt;
	if(baoji1 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("baoji_1");
		if(v != CParaMgr::ErrInt)
			baoji1 = v;
	}
	return baoji1;
}

static int GetParaBaoJi2()
{
	static int baoji2 = CParaMgr::ErrInt;
	if(baoji2 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("baoji_2");
		if(v != CParaMgr::ErrInt)
			baoji2 = v;
	}
	return baoji2;
}

static int GetParaKangBao1()
{
	static int kangbao1 = CParaMgr::ErrInt;
	if(kangbao1 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("kangbao_1");
		if(v != CParaMgr::ErrInt)
			kangbao1 = v;
	}
	return kangbao1;
}

static int GetParaKangBao2()
{
	static int kangbao2 = CParaMgr::ErrInt;
	if(kangbao2 == CParaMgr::ErrInt)
	{
		int v = SingletonCParaMgr::instance().GetInt("kangbao_2");
		if(v != CParaMgr::ErrInt)
			kangbao2 = v;
	}
	return kangbao2;
}


////////////////////////////////////////////////////////////////////////////////////

bool CFightCfgManager::Init()
{
	m_fightCfg.clear();
	m_fightSpecCfg.clear();
	m_fightDialog.clear();
	m_zhuzhanCfg.clear();

	{

		const string file = "fight_config.json";
		//                     0     1      2        3         4       5      6      7       8         9
		const char* titleArrs[] = { "id","zhenfa","show","level_reward","index1","index2","index3","index4","index5","fight_dialog_id" };
		const int typeArrs[] = { 0, 2, 0, 0, 0, 0, 0, 0, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CFightCfgManager::Init >> LoadJosnValue fight_config.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			SFightCfgData cfg;

			const rapidjson::Value &zattr = data[titleArrs[1]];
			if (zattr.Size() != 2)
				continue;

			cfg.id = data[titleArrs[0]].GetInt();
			cfg.showId = data[titleArrs[2]].GetInt();
			cfg.zhenfa_id = zattr[0].GetInt();
			SFightZhenFa v;
			v.role_level = 100;
			v.zhenfa_level = zattr[1].GetInt();
			cfg.zhenfaLevel.push_back(v);
			cfg.level_rewardId = data[titleArrs[3]].GetInt();
			for (uint16 j = 0; j < 5; j++)
			{
				cfg.bossId[j] = data[titleArrs[4 + j]].GetInt();
			}
			cfg.fight_dialog_id = data[titleArrs[9]].GetInt();
			cfg.teamBuffActive = 0;
			m_fightCfg.insert(make_pair(cfg.id,cfg));
		}
	}

	{
		vector<map<string,string> > data;
		//                  0      1          2         3       4      5      6       7         8             9               10           11        12
		const char *keys[] = {"id","zhenfa_id","zhenfa_level","index1","index2","index3","index4","index5","fight_dialog_id","user_zhenfa_id","user_zhenfa_level","user_idx","zhuzhan_id"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("fight_special_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(uint32 i=0;i < data.size();i++)
		{
			SFightSpecCfgData cfg;
			cfg.id = atoi(data[i][keys[0]].c_str());
			cfg.zhenfa_id = atoi(data[i][keys[1]].c_str());
			SetFightZhenFaLevel(cfg.zhenfaLv,data[i][keys[2]]);
			for(uint16 j=0; j < sizeof(cfg.bossId)/sizeof(cfg.bossId[0]); j++)
			{
				cfg.bossId[j] = atoi(data[i][keys[j+3]].c_str());
			}
			cfg.fight_dialog_id = atoi(data[i][keys[8]].c_str());
			cfg.user_zhenfa_id = atoi(data[i][keys[9]].c_str());
			SetFightZhenFaLevel(cfg.user_zhenfaLv,data[i][keys[10]]);
			cfg.user_pos = atoi(data[i][keys[11]].c_str());
			cfg.zhuzhanId = atoi(data[i][keys[12]].c_str());
			m_fightSpecCfg.insert(make_pair(cfg.id,cfg));
		}
	}

	{
		vector<map<string,string> > data;
		//                      0           1         2       3        4      5       6        7
		const char *keys[] = {"zhuzhan_id","zhuzhan_turn","group","zhenfa_idx","type","unit_id","pet_star","pet_level"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("fight_zhuzhan.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(uint32 i=0;i < data.size();i++)
		{
			SFightZhuZhanCfg cfg;
			cfg.id = atoi(data[i][keys[0]].c_str());
			cfg.turn = atoi(data[i][keys[1]].c_str());
			cfg.group = atoi(data[i][keys[2]].c_str());
			cfg.zhenfaIdx = atoi(data[i][keys[3]].c_str());
			cfg.type = atoi(data[i][keys[4]].c_str());
			cfg.unit_id = atoi(data[i][keys[5]].c_str());
			cfg.petStar = atoi(data[i][keys[6]].c_str());
			cfg.petLevel = atoi(data[i][keys[7]].c_str());
			
			map<int,vector<SFightZhuZhanCfg> >::iterator it = m_zhuzhanCfg.find(cfg.id);
			if(it == m_zhuzhanCfg.end())
			{
				pair<map<int,vector<SFightZhuZhanCfg> >::iterator,bool> res = m_zhuzhanCfg.insert(make_pair(cfg.id,vector<SFightZhuZhanCfg>()));
				if(!res.second)
				{
					cout<<"CFightCfgManager::Init() Error !!!  insert failed SFightZhuZhanCfg..."<<endl;
					return false;
				}
				it = res.first;
			}
			it->second.push_back(cfg);
		}

		SSortFightZhuZhan sortFun;
		for(map<int,vector<SFightZhuZhanCfg> >::iterator it=m_zhuzhanCfg.begin(); it != m_zhuzhanCfg.end(); it++)
		{
			std::sort(it->second.begin(),it->second.end(),sortFun);
		}
	}

	{
		vector<map<string,string> > data;
		//                     0      1        2       3     4        5       6
		const char *keys[] = {"dialogid","order","zhenfa_idx","dialog","time","show_turn","group"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("fight_dialog.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(uint32 i=0;i < data.size();i++)
		{
			int dialogId = atoi(data[i][keys[0]].c_str());
			SFightDialogCfg cfg;
			cfg.order = atoi(data[i][keys[1]].c_str());
			cfg.zhenfaIdx = atoi(data[i][keys[2]].c_str());
			if(cfg.zhenfaIdx > ZHEN_FA_POS_NUM)
			{
				cout<<"CFightCfgManager::Init() Error !!!  zhenfa_idx="<<cfg.zhenfaIdx<<endl;
				cfg.zhenfaIdx = 0;
			}
			cfg.dialog = data[i][keys[3]].c_str();
			cfg.lastTime = atoi(data[i][keys[4]].c_str());
			cfg.showTurn = atoi(data[i][keys[5]].c_str());
			cfg.group = atoi(data[i][keys[6]].c_str());

			map<int,vector<SFightDialogCfg> >::iterator it = m_fightDialog.find(dialogId);
			if(it == m_fightDialog.end())
			{
				pair<map<int,vector<SFightDialogCfg> >::iterator,bool> res = m_fightDialog.insert(make_pair(dialogId,vector<SFightDialogCfg>()));
				if(!res.second)
				{
					cout<<"CFightCfgManager::Init() Error !!!  insert failed..."<<endl;
					return false;
				}
				it = res.first;
			}
			it->second.push_back(cfg);
		}

		SSortFightDialog sortFun;
		for(map<int,vector<SFightDialogCfg> >::iterator it=m_fightDialog.begin(); it != m_fightDialog.end(); it++)
		{
			std::sort(it->second.begin(),it->second.end(),sortFun);
		}
	}

	return true;
}

bool CFightCfgManager::GetFirstBossInfo(int fightId,int &pic,string &name,int &bossId)
{
	pic = 0;
	name.clear();
	
	SFightCfgData *pCfg = GetFightCfg(fightId);
	if(pCfg == NULL)
		return false;
	for(uint8 i=0;i < sizeof(pCfg->bossId)/sizeof(pCfg->bossId[0]);i++)
	{
		if(pCfg->bossId[i] > 0)
		{
			if(SingletonMonsterBossManager::instance().GetMonsterBossInfo(pCfg->bossId[i],pic,name))
			{
				bossId = pCfg->bossId[i];
				return true;
			}
		}
	}
	return false;
}

int CFightCfgManager::GetFirstBossId(int fightId)
{
	SFightCfgData *pCfg = GetFightCfg(fightId);
	if(pCfg == NULL)
		return -1;
	for(uint8 i=0;i < sizeof(pCfg->bossId)/sizeof(pCfg->bossId[0]);i++)
	{
		if(pCfg->bossId[i] > 0)
			return pCfg->bossId[i];
	}
	return -1;
}

SFightCfgData *CFightCfgManager::GetFightCfg(int id)
{
	if(id < 1 || id >= 500000)
		return NULL;
	
	map<int,SFightCfgData>::iterator it = m_fightCfg.find(id);
	if(it == m_fightCfg.end())
		return NULL;
	return &(it->second);
}

SFightSpecCfgData *CFightCfgManager::GetSpecFightCfg(int id)
{
	if(id < 500000)
		return NULL;
	
	map<int,SFightSpecCfgData>::iterator it = m_fightSpecCfg.find(id);
	if(it == m_fightSpecCfg.end())
		return NULL;
	return &(it->second);
}

bool CFightCfgManager::GetFightDialog(vector<SFightDialogCfg> &dialog,int dialogId)
{
	dialog.clear();
	if(dialogId < 1)
		return false;

	map<int,vector<SFightDialogCfg> >::iterator it = m_fightDialog.find(dialogId);
	if(it == m_fightDialog.end())
		return false;
	dialog.assign(it->second.begin(),it->second.end());
	return true;
}

bool CFightCfgManager::GetZhuZhanCfg(vector<SFightZhuZhanCfg> &zhuzhan,int zhuzhanId)
{
	zhuzhan.clear();
	if(zhuzhanId < 1)
		return false;
	
	map<int,vector<SFightZhuZhanCfg> >::iterator it = m_zhuzhanCfg.find(zhuzhanId);
	if(it == m_zhuzhanCfg.end())
		return false;
	zhuzhan.assign(it->second.begin(),it->second.end());
	return true;
}

bool CFightCfgManager::SetFightZhenFaLevel(vector<SFightZhenFa> &data,string &str)
{
	data.clear();
	if(str.empty())
		return true;

	char buf[2048];
	int num = 0;
	char *p[200];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[2];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		if(tnum != 2)
		{
			cout<<">> CFightCfgManager::SetFightZhenFaLevel() error , str = "<<str;
			return false;
		}

		SFightZhenFa v;
		v.role_level = atoi(tp[0]);
		v.zhenfa_level = atoi(tp[1]);
		data.push_back(v);
	}
	return true;
}



////////////////////////////////////////////////////////////////////////////////////////////////


template<typename Type> uint8 CFight::AddTmpl(Type val,uint8 pos,uint8 zhenfaPos)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return AddTmplNoLock(val,pos,zhenfaPos);
}
template<typename Type> uint8 CFight::AddTmplNoLock(Type val,uint8 pos,uint8 zhenfaPos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(m_members[pos-1].memPtr.empty())
		{
			m_memNum++;
		}
		m_members[pos-1].Clear();
		m_members[pos-1].memPtr = val;
		m_members[pos-1].zhenfaPos = zhenfaPos;
		SetUnitBasicData(pos);
		return pos;
	}
	return 0;
}

template<typename Type> uint8 CFight::ReAddTmplNoLock(Type val,uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty())
		{
			m_members[pos-1].memPtr = val;
//			SetUnitBasicData(pos);
			return pos;
		}
	}
	return 0;
}

bool CFight::ReLoadUserNoLock(ShareUserPtr user)
{
	if(user.get() == NULL)
		return false;
	
	for(uint8 i=0; i < EGT_GROUP2; i++)
	{
		for(uint8 j=0; j < m_groupUser[i].size(); j++)
		{
			if(m_groupUser[i][j]->GetRoleId() == user->GetRoleId())
			{
				m_groupUser[i][j] = user;
				return true;
			}
		}
	}
	return false;
}

void CFight::SetUnitPercentData(vector<SFastFightUnit>& percent, uint8 group/* = CFight::EGT_GROUP2*/)
{
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(m_zhenfaId[group]);
	if (pZhenFa == NULL)
		return;
	for (size_t i = 0; i < percent.size(); i++)
	{
		SFastFightUnit& tmp = percent[i];
		uint8 fpos = pZhenFa->fightPos[tmp.pos] + GROUP_MEMBER * group;
		SFightMember &unit = m_members[fpos - 1];
		double percent = tmp.hp * 1.0 / tmp.maxHp;
		unit.hp = tmp.maxHp * percent;
		if (tmp.hp > 0 && unit.hp == 0)
			unit.hp = 1;

		if (unit.hp == 0)
		{
			unit.Clear();
			m_memNum--;
		}
	}
}

void CFight::SetUnitBasicData(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	SFightMember &unit = m_members[pos-1];
	if(unit.memPtr.type() == typeid(ShareMonsterPtr))	// monster
	{
		SMonsterInst *pMonster = (boost::any_cast<ShareMonsterPtr>(unit.memPtr)).get();
		if(pMonster == NULL)
			return;
		unit.type = EFMT_MONSTER;
		unit.unitAttr = pMonster->attr;
		unit.attackType = pMonster->attackType;
		unit.hp = pMonster->hp;
		unit.level = pMonster->level;
		unit.xiang = pMonster->type;
		
		unit.jiaQiangSeal = pMonster->jiaQiangSeal;
		unit.jiaQiangZhongDu = pMonster->jiaQiangZhongDu;
		unit.jiaQiangBingDong = pMonster->jiaQiangBingDong;
		unit.jiaQiangHunShui = pMonster->jiaQiangHunShui;
		unit.jiaQiangHunLuan = pMonster->jiaQiangHunLuan;
		unit.kangSeal = pMonster->kangSeal;
		unit.kangZhongDu = pMonster->kangZhongDu;
		unit.kangBingDong = pMonster->kangBingDong;
		unit.kangHunShui = pMonster->kangHunShui;
		unit.kangHunLuan = pMonster->kangHunLuan;
		unit.celue = pMonster->celue;
		unit.name = pMonster->name;

		unit.skill_list.clear();
		unit.passive_skill.clear();
		for(uint16 i=0;i < pMonster->skills.size();i++)
		{
			SSkillCfgData *pCfg = skillMgr.GetSkillCfg(pMonster->skills[i].id);
			if(pCfg != NULL)
			{
				SSkillData skill = pMonster->skills[i];
				skill.CD = pCfg->CD;
				if(pCfg->type == 1)	// 主动技能
					unit.skill_list.push_back(skill);
				else
					unit.passive_skill.push_back(skill);
			}
		}
	}
	else if(unit.memPtr.type() == typeid(ShareUserPtr))	// user
	{
		CUser *pUser = (boost::any_cast<ShareUserPtr>(unit.memPtr)).get();
		if(pUser == NULL)
			return;
		unit.type = EFMT_USER;
		pUser->GetBasicAttr(unit.unitAttr);
		unit.attackType = pUser->GetAttackType();
		unit.level = pUser->GetLevel();
	
		unit.jiaQiangSeal = 0;//pUser->GetItemJiaQiangSeal();
		unit.jiaQiangZhongDu = 0;//pUser->GetItemJiaQiangZhongDu();
		unit.jiaQiangBingDong = 0;//pUser->GetItemJiaQiangBingDong();
		unit.jiaQiangHunShui = 0;//pUser->GetItemJiaQiangHunShui();
		unit.jiaQiangHunLuan = 0;//pUser->GetItemJiaQiangHunLuan();
		unit.kangSeal = 0;
		unit.kangZhongDu = 0;//pUser->GetItemKangZhongDu();
		unit.kangBingDong = 0;//pUser->GetItemKangBingDong();
		unit.kangHunShui = 0;//pUser->GetItemKangHunShui();
		unit.kangHunLuan = 0;//pUser->GetItemKangHunLuan();
		unit.celue = pUser->GetCeLue();
		unit.name = pUser->GetName();
	}
	else if(unit.memPtr.type() == typeid(SharePetPtr))	// pet
	{
		SPet *pPet = (boost::any_cast<SharePetPtr>(unit.memPtr)).get();
		if(pPet == NULL)
			return;
		unit.type = EFMT_PET;
		unit.unitAttr = pPet->basicAttr;
		unit.attackType = pPet->attackType;
		unit.hp = pPet->hp;
		unit.level = pPet->level;
		unit.xiang = pPet->type;

		unit.jiaQiangSeal = 0;
		unit.jiaQiangZhongDu = 0;
		unit.jiaQiangBingDong = 0;
		unit.jiaQiangHunShui = 0;
		unit.jiaQiangHunLuan = 0;
		unit.kangSeal = 0;
		unit.kangZhongDu = 0;
		unit.kangBingDong = 0;
		unit.kangHunShui = 0;
		unit.kangHunLuan = 0;
		unit.celue = pPet->celue;
		unit.name = pPet->name;

		unit.skill_list.clear();
		unit.passive_skill.clear();

		for(uint32 i=0;i < sizeof(pPet->skill)/sizeof(pPet->skill[0]);i++)
		{
			if(pPet->skill[i] == 0)
				continue;
			SSkillCfgData *pCfg = skillMgr.GetSkillCfg(pPet->skill[i]);
			if(pCfg != NULL)
			{
				SSkillData s;
				s.id = pPet->skill[i];
				s.level = pPet->GetSkillLevel(s.id);
				s.CD = pCfg->CD;
				if(pCfg->type == 1)	// 主动技能
					unit.skill_list.push_back(s);
				else
					unit.passive_skill.push_back(s);
			}
		}
		
		vector<SSkillData> suitSkill;
		pPet->GetSuitSkills(suitSkill);
		for(uint32 i=0;i < suitSkill.size();i++)	// 套装技能
		{
			SSkillData &sData = suitSkill[i];
			if(sData.id == 0)
				continue;
			SSkillCfgData *pCfg = skillMgr.GetSkillCfg(sData.id);
			if(pCfg != NULL)
			{
				SSkillData s;
				s.id = sData.id;
				s.level = sData.level;
				s.CD = pCfg->CD;
				if(pCfg->type == 1)	// 主动技能
					unit.skill_list.push_back(s);
				else
					unit.passive_skill.push_back(s);
			}
		}
	}

	vector<SAttrData> passSkillAttr;
	for(uint8 i=0;i < unit.passive_skill.size();i++)
	{
		SSkillCfgData *pCfg = skillMgr.GetSkillCfg(unit.passive_skill[i].id);
		if(pCfg == NULL)
			continue;
		int skillLv = unit.passive_skill[i].level;
		for(uint8 j=0;j < pCfg->passiveEffect.size();j++)
		{
			SSkillAdditiveEffect *pAdditive = skillMgr.GetAdditiveEffectCfg(pCfg->passiveEffect[j].GetEffectId());
			if(pAdditive == NULL)
				continue;
			if(pAdditive->trigger == ESkill_Trigger_DefAdd)
			{
				if(pAdditive->buffId > 0)
				{
					if(pAdditive->type == ESkill_Pass_AddZhongDuKang)
					{
						SAttrData attr;
						attr.attrType = ESkill_PassAttr_ZhongDuKang;
						attr.attrValue = pAdditive->para[1] + pAdditive->para_levelAdd[1] * (skillLv-1);
						unit.passive_attr.push_back(attr);
					}
					else if(pAdditive->type == ESkill_Pass_MianYiFuMian)
					{
						unit.notEffectBuff.push_back(pAdditive->buffId);
					}
				}
			}
			else if(pAdditive->trigger == ESkill_Trigger_AddAttrBeginFight)
			{
				if(pAdditive->type == ESkill_Pass_Attr)
				{
					SAttrData attr;
					attr.attrType = pAdditive->buffId;
					attr.attrValue = pAdditive->para[1] + pAdditive->para_levelAdd[1] * (skillLv - 1);
					AddToAttrList(passSkillAttr,attr);
				}
			}
		}
	}
	int64 srcMaxHp = unit.unitAttr.maxHp;
	unit.unitAttr.AddAttrValue(passSkillAttr);
	unit.hp += unit.unitAttr.maxHp - srcMaxHp;

	if(unit.zhenfaPos < ZHEN_FA_POS_NUM)
	{
		int group = (pos <= GROUP2_BEGIN) ? EGT_GROUP1 : EGT_GROUP2;
		SZhenFaLevelUpData *pZhenFaAttr = SingletonCZhenFaCfgMgr::instance().GetLevelUpCfg(m_zhenfaId[group],m_zhenfaLevel[group]);
		if(pZhenFaAttr == NULL)
			return;
		srcMaxHp = unit.unitAttr.maxHp;
		unit.unitAttr.AddAttrValue(pZhenFaAttr->attrList[unit.zhenfaPos]);
		unit.hp += unit.unitAttr.maxHp - srcMaxHp;
	}
}

void CFight::Clear()
{
	m_canSkip = true;
	m_huiCun = false;
	m_visibleMonsterId = 0;
	monsterId1 = 0;
	monsterId2 = 0;
	m_memNum = 0;
	m_userOpTime = 0;
	m_fightIsEnd = false;
	m_useZhaoHuanSkill = false;
	m_beginTime = GetSysTime();
	m_turnBegin = 0;
	m_beginTurnMask = 0;
	m_pScene = NULL;
	m_type = 0;
	m_fightSayPos = 0;

	m_delNpcId = 0;
	m_delNpcIndex = 0;
	m_diaoxiangId = 0;
	m_fightTurn = 0;
	m_teamRage[0] = 0;
	m_teamRage[1] = 0;
	m_tacticUsedThisTurn[0] = false;
	m_tacticUsedThisTurn[1] = false;
	m_cfgFightId = 0;

	m_qx_userPos = 0;
	m_qx_imageIdx = 0;
	memset(m_qx_userAttrVal,0,sizeof(m_qx_userAttrVal));
	memset(m_qx_userAttrPercent,0,sizeof(m_qx_userAttrPercent));
	m_qx_imagePos = 0;
	m_qx_imageGain = 0.0f;

	for(uint8 i = 0; i < MAX_MEMBER; i++)
	{
		m_members[i].Clear();
	}
	for(uint8 i = 0; i < sizeof(m_zhenfaId)/sizeof(m_zhenfaId[0]); i++)
	{
		m_zhenfaId[i] = 0;
		m_zhenfaLevel[i] = 0;
	}
	m_zhaoHuanTimes = 0;
	showFightLog = false;
	m_talkIdx = 0;
	m_talkPos = 0;

	m_IsAutoMode = 1;
	m_playSpeed = 0;
	m_userOperateTime = 20;
	m_taskId = 0;

	m_ActionFirstGroup = EGT_GROUP1;
	m_forceEnd = false;
}

void CFight::SetGroupZhenFaData(uint16 zhenfaId,uint8 zhenfaLevel,uint8 group)
{
	if(group > EGT_GROUP2)
		return;
	m_zhenfaId[group] = zhenfaId;
	m_zhenfaLevel[group] = zhenfaLevel;
}

void CFight::DelMember(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pUser->SetFight(0);
		}
		m_members[pos-1].memPtr = boost::any();
		m_memNum--;
	}
}

bool CFight::AddUser(ShareUserPtr user, uint8 group)
{
	if(group > EGT_GROUP2)
		return false;
	if(user.get() == NULL)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0; i < EGT_GROUP2; i++)
	{
		for(uint8 j=0; j < m_groupUser[i].size(); j++)
		{
			if(m_groupUser[i][j]->GetRoleId() == user->GetRoleId())
				return false;
		}
	}
	m_groupUser[group].push_back(user);
	return true;
}

uint8 CFight::AddMonster(ShareMonsterPtr monster,uint8 pos,uint8 zhenfaPos)
{
	if(monsterId1 == 0)
		monsterId1 = monster->id;
	else if(monsterId1 != monster->id)
		monsterId2 = monster->id;
	return AddTmpl(monster,pos,zhenfaPos);
}

void CFight::AddUnitStateBeforeFight(uint8 pos,uint16 state,uint8 turn,int value)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;
//	AddBuff(pos,state,turn,value);
}

// userPetPos 神将在神将栏的位置0开始
uint8 CFight::AddPet(SharePetPtr pet,uint8 pos,uint32 userId,uint8 zhenfaPos)
{
	if(pos == 0 || pos > MAX_MEMBER || pet.get() == NULL)
		return 0;
	uint8 petPos = AddTmplNoLock(pet,pos,zhenfaPos);
	m_members[pos-1].petOwner = userId;
	return petPos;
}

void CFight::SetBelongToUserWithPos(uint8 fromPos,uint8 userPos)
{
	if((fromPos <= GROUP2_BEGIN && userPos > GROUP2_BEGIN) || (fromPos > GROUP2_BEGIN && userPos <= GROUP2_BEGIN)
		|| fromPos > MAX_MEMBER || userPos > MAX_MEMBER)
		return;
	m_members[fromPos-1].belongUserPos = userPos;
}

CFight::SFightMember *CFight::GetFightMember(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty())
			return &m_members[pos-1];
	}
	return NULL;
}

CUser *CFight::GetUser(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty() && (m_members[pos-1].memPtr.type() == typeid(ShareUserPtr)))
			return (boost::any_cast<ShareUserPtr>(m_members[pos-1].memPtr)).get();
	}
	return NULL;
}

CUser *CFight::GetUserInFight(uint32 roleId, uint8 group)
{
	if(group > EGT_GROUP2)
		return NULL;
	for(uint8 j=0; j < m_groupUser[group].size(); j++)
	{
		CUser *pU = m_groupUser[group][j].get();
		if(pU != NULL && pU->GetRoleId() == roleId)
		{
			return pU;
		}
	}
	return NULL;
}

int CFight::GetUnitSpeed_Rand(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty())
			return m_members[pos-1].speed_rand;
	}
	return 0;
}

int CFight::GetUnitSpeed(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty())
		{
			int speed = m_members[pos-1].unitAttr.speed;
			speed *= (1 + m_members[pos-1].unitAttr.speed_percent_fight/10000.0);
			speed *= (1 - GetStatePara1(pos,ESBUFF_SpeedDes)/10000.0 + GetStatePara1(pos,ESBUFF_AddSpeed)/10000.0);
			return speed;
		}
	}
	return 0;
}

bool CFight::IsUserAllMemberDie(uint8 me)
{
	bool allDie = true;
	int begin = 1;
	int end = GROUP2_BEGIN;
	if(me > GROUP2_BEGIN)
	{
		begin = GROUP2_BEGIN+1;
		end = MAX_MEMBER;
	}
	
	for(int i=begin; i <= end; i++)
	{
		if(i == (int)me)
			continue;
		CUser *pUser = GetUser(i);
		if(pUser != NULL)
		{
			if(IsAlive(i))
			{
				allDie = false;
				break;
			}
		}
	}
	return allDie;
}

int CFight::GetAnotherGroupLevel(uint8 me)
{
	int one_role_lv = 0;
	int lv = 0;
	int begin = 1;
	int end = GROUP2_BEGIN;
	if(me <= GROUP2_BEGIN)
	{
		begin = GROUP2_BEGIN+1;
		end = MAX_MEMBER;
	}

	for(int i=begin; i <= end; i++)
	{
		CUser *pUser = GetUser(i);
		if(pUser != NULL)
		{
			if(one_role_lv == 0)
				one_role_lv = pUser->GetLevel();
			if(pUser->GetRoleId() == pUser->GetTeam())
			{
				lv = pUser->GetLevel();
				break;
			}
			continue;
		}
		SMonsterInst *pMon = GetMonster(i);
		if(pMon != NULL)
		{
			lv = pMon->level;
			break;
		}
	}
	if(lv == 0 && one_role_lv > 0)
		lv = one_role_lv;
	return lv;
}

void CFight::BroadcastMsg(CNetMessage &msg)
{
	CSocketServer &sock = SingletonSocket::instance();
//	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(uint8 i=0; i <= EGT_GROUP2; i++)
	{
		for(uint8 j=0; j < m_groupUser[i].size(); j++)
		{
			CUser *pU = m_groupUser[i][j].get();
			if(pU != NULL && pU->GetSock() > 0)
				sock.SendMsg(pU->GetSock(),msg);
		}
	}
}

SMonsterInst *CFight::GetMonster(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty()	&& (m_members[pos-1].memPtr.type() == typeid(ShareMonsterPtr)))
			return (boost::any_cast<ShareMonsterPtr>(m_members[pos-1].memPtr)).get();
	}
	return NULL;
}

void CFight::SetMonsterHpBeforeFight(uint32 bossId,int hp,int maxHp,int attackRatio,int recoveryRatio)
{
	for(uint8 pos=1;pos <= MAX_MEMBER;pos++)
	{
		SMonsterInst *pMonter = GetMonster(pos);
		if(pMonter == NULL)
			continue;
		if(pMonter->id == (int)bossId)
		{
			m_members[pos-1].hp = hp;
			m_members[pos-1].unitAttr.maxHp = maxHp;
			m_members[pos-1].unitAttr.attack *= 1 + attackRatio/100.0;
			m_members[pos-1].unitAttr.wufang *= 1 + recoveryRatio/100.0;
			m_members[pos-1].unitAttr.fafang *= 1 + recoveryRatio/100.0;
			return;
		}
	}
}

void CFight::SetWorldMonsterFlag(uint32 bossId)
{
	for(uint8 pos=1;pos <= MAX_MEMBER;pos++)
	{
		SMonsterInst *pMonter = GetMonster(pos);
		if(pMonter == NULL)
			continue;
		if(pMonter->id == (int)bossId)
		{
			m_members[pos-1].isWorldBoss = 1;
			return;
		}
	}
}

uint8 CFight::FindMonsterPos(uint32 bossId)
{
	for(uint8 pos=1;pos <= MAX_MEMBER;pos++)
	{
		SMonsterInst *pMonter = GetMonster(pos);
		if(pMonter == NULL)
			continue;
		if(pMonter->id == (int)bossId)
			return pos;
	}
	return 0xff;
}

SPet *CFight::GetPet(uint8 pos)
{
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(!m_members[pos-1].memPtr.empty() && (m_members[pos-1].memPtr.type() == typeid(SharePetPtr)))
			return (boost::any_cast<SharePetPtr>(m_members[pos-1].memPtr)).get();
	}
	return NULL;
}

void CFight::GuanZhan(CUser *pGUser)
{
	CNetMessage msg;
	msg.SetType(ENTER_GUANZHAN);
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	int num = 0;
	msg<<m_id;
	if(m_type == EFTMatch)
		msg<<(uint8)EFTPlayerPk;
	else
		msg<<m_type;

	uint16 pos = msg.GetDataLen();
	msg<<m_memNum;
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		CUser *pUser = GetUser(pos);
		SMonsterInst *pMonster = GetMonster(pos);
		SPet *pPet = GetPet(pos);
		if(pUser != NULL)
		{
			num++;
			msg<<(uint8)1//玩家
				<<(uint8)(pos)<<pUser->GetRoleId()<<pUser->GetName()
				<<pUser->GetLevel()<<pUser->GetSex()
				<<GetMaxHp(pos);
//			<<pUser->GetMaxMp()<<pUser->GetMp();
		}
		else if(pMonster != NULL)
		{
			int hp = pMonster->hp;
			if(!IsAlive(pos))
			{
				continue;
			}
			msg<<(uint8)0//怪
				<<(uint8)(pos)<<pMonster->pic<<pMonster->name
				<<(uint8)pMonster->level<<pMonster->attr.maxHp<<hp;
			if(m_type == EFTScript)
				msg<<(uint8)EMTNormal;
			else
				msg<<pMonster->type;
			num++;
		}
		else if(pPet != NULL)
		{
			int hp = pPet->hp;
			if(!IsAlive(pos))
			{
				continue;
			}
			num++;
			msg<<(uint8)2<<pos<<(int)pPet->id<<pPet->name<<pPet->level<<pPet->basicAttr.maxHp
				<<hp;
//			<<pPet->maxHp;
		}

		if(num == m_memNum)
		{
			break;
		}
	}
	msg.WriteData(pos,&num,1);
	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(pGUser->GetSock(),msg);
	m_guanZhanSock.push_back(pGUser->GetSock());
}

void CFight::LeaveGuanZhan(CUser *pUser)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_guanZhanSock.remove(pUser->GetSock());
}

void CFight::SendGuanZhanOver()
{
	CSocketServer &sock = SingletonSocket::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CNetMessage msg;
	msg.SetType(GUANGZHAN_BATTLE_OVER);
	for(list<int>::iterator i = m_guanZhanSock.begin(); i != m_guanZhanSock.end(); i++)
	{
		sock.SendMsg(*i,msg);
	}
}

bool CFight::ReBegin(CSocketServer &sock,ShareUserPtr pReBeginUser)
{
	if(pReBeginUser.get() == NULL)
		return false;

	CNetMessage msg;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	pReBeginUser->SetAutoFightTurn(0);
	bool ret = ReLoadUserNoLock(pReBeginUser);
	if(ret)
	{
		NoLockMakeEnterFight(msg);
		sock.SendMsg(pReBeginUser->GetSock(),msg);
	}
	return ret;
}

void CFight::NoLockInitUnitsBeforeFight()
{
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		SFightMember *p = GetFightMember(pos);
		if(p == NULL)
			continue;

		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			if(m_type == EFTMatch)
			{

			}
			if((m_type != EFTMeetMonster) && (m_type != EFTScript))
			{
				CancelAutoFight(pUser);
				pUser->SaveAutoFight(0,0);
			}
		}
	}
}

void CFight::NoLockMakeEnterFight(CNetMessage &msg)
{
	msg.ReWrite();
	msg.SetType(PRO_ENTER_BATTLE);
	msg<<m_id;
	
	if(m_type == EFTMatch)
		msg<<(uint8)EFTPlayerPk;
	else
		msg<<m_type;
	msg<<m_IsAutoMode;	// 开始战斗是否自动
	msg<<m_playSpeed;	// 播放速度
	msg<<m_userOperateTime;	// 操作超时时间
	msg<<(uint8)(m_canSkip ? 1 : 0);
	msg<<GetFightLimitTurn(m_type);
	msg<<(uint16)m_fightTurn;
	msg<<m_zhenfaId[0]<<m_zhenfaLevel[0]<<m_zhenfaId[1]<<m_zhenfaLevel[1];
	MakeShowName(msg);

	uint32 numPos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		SFightMember *p = GetFightMember(pos);
		if(p == NULL)
			continue;

		CUser *pUser = GetUser(pos);
		SMonsterInst *pMonster = GetMonster(pos);
		SPet *pPet = GetPet(pos);
		num++;
		if(pUser != NULL)
		{
			msg<<(uint8)1;	//玩家
			msg<<(uint8)(pos)<<pUser->GetRoleId()<<(int)100<<pUser->GetName()<<pUser->GetLevel();
			msg<<pUser->GetSex();
			msg<<GetMaxHp(pos);

			int64 hp = p->hp;
			if(!IsAlive(pos))
				hp = 0;
			msg<<hp;
			MakeBuffList(pos,msg);
			MakeSkillInfoInFight(pos,msg);

			if(showFightLog)
				cout<<"enterFight  pos="<<(int)pos<<", maxHp="<<GetMaxHp(pos)<<", hp="<<p->hp<<endl;
		}
		else if(pMonster != NULL)
		{
			msg<<(uint8)0;	//怪
			msg<<(uint8)(pos)<<pMonster->pic<<pMonster->scale<<pMonster->name<<pMonster->level<<GetMaxHp(pos)<<p->hp;
			uint8 firstCartonType = m_members[pos-1].firstCartonType;
			if(m_fightTurn > 0)
				firstCartonType = 0;
			msg<<firstCartonType;
			if(m_type == EFTScript)
				msg<<(uint8)EMTNormal;
			else
				msg<<pMonster->type;
			MakeBuffList(pos,msg);
			msg<<pMonster->quality<<p->isWorldBoss;

			if(showFightLog)
				cout<<"enterFight  pos="<<(int)pos<<", maxHp="<<GetMaxHp(pos)<<", hp="<<p->hp<<endl;
		}
		else if(pPet != NULL)
		{
			msg<<(uint8)2;	// 神将
			msg<<pos<<(uint32)pPet->id<<(int)100<<pPet->name<<pPet->level<<GetMaxHp(pos)<<p->hp;
			MakeBuffList(pos,msg);
			msg<<m_members[pos-1].petOwner<<pPet->quality;
			msg<<pPet->star<<pPet->breakLevel;
			
			if(showFightLog)
				cout<<"enterFight  pos="<<(int)pos<<", maxHp="<<GetMaxHp(pos)<<", hp="<<p->hp<<endl;
		}
		else
		{
			return;
		}

		if(num == m_memNum)
			break;
	}
	msg.WriteData(numPos, &num, sizeof(num));
}

void CFight::AddTongTianTaSay(CNetMessage &msg,uint8 &addFightUnitNum)
{
	if(m_type != EFTTongTianTa)
		return;
	if(m_fightTurn > 0)
		return;

	const char* SayStr[] = {
		LANGUAGE_TRANSFORM_434,
		LANGUAGE_TRANSFORM_435,
		LANGUAGE_TRANSFORM_436,
		LANGUAGE_TRANSFORM_437,
		LANGUAGE_TRANSFORM_438,
		LANGUAGE_TRANSFORM_439,
		LANGUAGE_TRANSFORM_440,
		LANGUAGE_TRANSFORM_441,
		LANGUAGE_TRANSFORM_442,
		LANGUAGE_TRANSFORM_443,
		LANGUAGE_TRANSFORM_444,
		LANGUAGE_TRANSFORM_445,
		LANGUAGE_TRANSFORM_446,
		LANGUAGE_TRANSFORM_447,
		LANGUAGE_TRANSFORM_448,
		LANGUAGE_TRANSFORM_449,
		LANGUAGE_TRANSFORM_450,
		LANGUAGE_TRANSFORM_451,
		LANGUAGE_TRANSFORM_452,
		LANGUAGE_TRANSFORM_453,
		LANGUAGE_TRANSFORM_454,
		LANGUAGE_TRANSFORM_455,
		LANGUAGE_TRANSFORM_456,
		LANGUAGE_TRANSFORM_457,
		LANGUAGE_TRANSFORM_458,
		LANGUAGE_TRANSFORM_459,
		LANGUAGE_TRANSFORM_460,
		LANGUAGE_TRANSFORM_461,
		LANGUAGE_TRANSFORM_462,
		LANGUAGE_TRANSFORM_463,
		LANGUAGE_TRANSFORM_464,
		LANGUAGE_TRANSFORM_465,
		LANGUAGE_TRANSFORM_466,
		LANGUAGE_TRANSFORM_467,
		LANGUAGE_TRANSFORM_468,
		LANGUAGE_TRANSFORM_469,
		LANGUAGE_TRANSFORM_470,
		LANGUAGE_TRANSFORM_471,
		LANGUAGE_TRANSFORM_472,
		LANGUAGE_TRANSFORM_473};
	const uint8 sayPos[] = {3,4,3,3,1,3,3,3,3,4,3,3,1,3,3,3,3,4,3,3,1,3,3,3,3,4,3,3,1,3,3,3,3,4,3,3,1,3,3,3};
	
	CUser *pUser = GetUser(GROUP2_MAIN_POS);
	if(pUser == NULL)
		return;
	int fbIdx = pUser->GetExtData16(51);	
	if(fbIdx > 0 && fbIdx%5 == 0)
	{
		int size = sizeof(sayPos)/sizeof(sayPos[0]);
		int idx = fbIdx/5 - 1;
		if(idx < 0)
			idx = 0;
		else if(idx > size - 1)
			idx = size - 1;
		msg<<sayPos[idx]<<SayStr[idx];
		addFightUnitNum++;
	}
}

void CFight::SetAllMemberSpeedLevel(uint8 speed)
{
	if(speed == 0 || speed > MAX_FIGHT_SPEED_LEVEL)
		return;
	for(uint8 pos = 1; pos <= MAX_MEMBER;pos++)
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
			m_members[pos-1].speedLevel = speed;
	}
}

void CFight::SetMemberFirstCartonType(uint8 pos,uint8 type)
{
	if(pos < 1 || pos > MAX_MEMBER)
		return;
	m_members[pos-1].firstCartonType = type;
}

void CFight::SetFightEndData(int index,int value)
{
	if(index >= FIGHT_END_DATA_NUM)
		return;
	m_fightEndData[index] = value;
}

void CFight::InitTeamBuff()
{
	if(m_cfgFightId == 0)
		return;
	SFightCfgData *pFightCfg = SingletonCFightCfgManager::instance().GetFightCfg(m_cfgFightId);
	if(pFightCfg == NULL || pFightCfg->teamBuffActive == 0)
		return;
	uint8 userNum = 0;
	uint8 userGroup = EGT_GROUP1;
	for(uint8 pos=1;pos <= MAX_MEMBER;pos++)
	{
		if(GetUser(pos) != NULL)
		{
			userNum++;
			if(pos > GROUP2_BEGIN)
				userGroup = EGT_GROUP2;
		}
	}

	if(userNum < 2)
		return;

	// buffId,value
	const int extBuffVal2 = 1000;
	const int extBuffVal3 = 1500;
	const int desHp2 = 10;	// 10%
	const int desHp3 = 20;	// 20%

	uint8 monBegin = 1;
	uint8 monEnd = GROUP2_BEGIN;
	uint8 userBegin = GROUP2_BEGIN+1;
	uint8 userEnd = MAX_MEMBER;
	if(userGroup == EGT_GROUP1)
	{
		monBegin = GROUP2_BEGIN+1;
		monEnd = MAX_MEMBER;
		userBegin = 1;
		userEnd = GROUP2_BEGIN;
	}
	// monster
	int desHp = (userNum == 2) ? desHp2 : desHp3;
	for(uint8 pos=monBegin;pos <= monEnd;pos++)
	{
		SFightMember *p = GetFightMember(pos);
		if(p != NULL)
		{
			p->unitAttr.maxHp *= (100 - desHp)/100.0;
			p->hp = p->unitAttr.maxHp;
		}
	}
	// user
	int extBuffVal = (userNum == 2) ? extBuffVal2 : extBuffVal3;
	for(uint8 pos=userBegin;pos <= userEnd;pos++)
	{
		SFightMember *p = GetFightMember(pos);
		if(p != NULL)
		{
			p->unitAttr.zengshangLv += extBuffVal;
			p->unitAttr.wumianLv += extBuffVal;
			p->unitAttr.famianLv += extBuffVal;
		}
	}
}

void CFight::BeginFight(CScene *pScene)
{
	InitActionFirstGroup();
	InitTeamBuff();
	RecoverAllUserHp(true);

	m_pScene = pScene;
	m_beginTime = GetSysTime();
	//m_flghtBegin = true;

	CNetMessage msg;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockInitUnitsBeforeFight();
	NoLockMakeEnterFight(msg);
	m_fightMsgList.push_back(msg);
	BroadcastMsg(msg);
}

void CFight::BeginFastFight(SFastFightResult &result, bool isShowFight, int sock)
{
	result.Clear();

	InitActionFirstGroup();
	InitTeamBuff();
	RecoverAllUserHp(true);

	NoLockInitUnitsBeforeFight();

	CNetMessage msg;
	NoLockMakeEnterFight(msg);
	m_fightMsgList.clear();
	m_fightMsgList.push_back(msg);
	
	bool isEnd = false;
	do
	{
		CalculateFightResult(true);
		isEnd = FastFightEnd(result);
	}while(!isEnd);

	if(isShowFight)
	{
		CNetMessage retMsg;
		if(GetFightAllNetMsg(retMsg, EFPT_PlayBack_2))
		{
			SingletonSocket::instance().SendMsg(sock, retMsg);
		}
	}

//	RecoverAllUserHp();
}

uint8 CFight::GetProtecterPos(uint8 mePos,int damage)
{
	if(mePos == 0 || mePos > MAX_MEMBER)
		return 0;
	if(GetHp(mePos) > damage)
		return 0;
	SFightMember *p = GetFightMember(mePos);
	if(p == NULL || p->GetSkillLevel(235) > 0)
		return 0;
	
	uint8 mePet[GROUP2_BEGIN];
	uint8 num = 0;
	uint8 beginPos = 1;
	uint8 endPos = GROUP2_BEGIN;
	if(mePos > GROUP2_BEGIN)
	{
		beginPos = GROUP2_BEGIN+1;
		endPos = MAX_MEMBER;
	}
	for(uint8 i = beginPos; i <= endPos; i++)
	{
		if(i == mePos)
			continue;
		SFightMember *pTemp = GetFightMember(i);
		if(pTemp == NULL || !IsAlive(i))
			continue;
		if(p->GetSkillLevel(235) > 0)
		{
			mePet[num] = i;
			num++;
		}
	}

	// speed max to min
//	SortBySpeed(mePet,num);
	for(uint8 i=0;i < num;i++)
	{
		uint8 pos = mePet[i];
		SFightMember *pTemp = GetFightMember(pos);
		if(pTemp == NULL)
			continue;
		int ratio = 5000 + 75 * (pTemp->GetSkillLevel(235));
		if(Random(1,10000) <= ratio)
			return pos;
	}
	return 0;
}

int CFight::GetUnitAttack(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;
	int attack = p->unitAttr.attack * (1 + p->unitAttr.attack_percent_fight/10000.0) * (1 + GetStatePara1(pos,ESBUFF_DamagePercentAdd)/10000.0 - GetStatePara1(pos,ESBUFF_DamagePercentDes)/10000.0 - GetStatePara1(pos,ESBUFF_JinGuZhou)/10000.0);
	if(attack < 1)
		attack = 1;
	return attack;
}

int CFight::GetUnitFangYu(uint8 pos,uint8 attackType)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;
	int fang = 0;
	if(attackType == 1)	// 物攻
		fang = p->unitAttr.wufang * (1 + p->unitAttr.wufang_percent_fight/10000.0) * (1 - GetStatePara1(pos,ESBUFF_FangYuDes)/10000.0 - GetStatePara1(pos,ESBUFF_WuFangDes)/10000.0);
	else	// 法防
		fang = p->unitAttr.fafang * (1 + p->unitAttr.fafang_percent_fight/10000.0) * (1 - GetStatePara1(pos,ESBUFF_FangYuDes)/10000.0 - GetStatePara1(pos,ESBUFF_FaFangDes )/10000.0);
	if(fang < 1)
		fang = 1;
	return fang;
}

float CFight::CalUnitZengShangLv(uint8 src,uint8 target,uint8 attackType,int extMianshangLv)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTar = GetFightMember(target);
	if(pSrc == NULL || pTar == NULL)
		return 1.0;
	float ratio = 1.0;
	if(attackType == 1)	// 物攻
	{
		ratio += (pSrc->unitAttr.zengshangLv + GetStatePara1(src,ESBUFF_ZengShangLvAdd) - GetStatePara1(src,ESBUFF_ZengShangLvDes))/10000.0;
		ratio -= (pTar->unitAttr.wumianLv + GetStatePara1(target,ESBUFF_JianShangLvAdd) - GetStatePara1(target,ESBUFF_JianShangLvDes) + GetStatePara1(target,ESBUFF_WuMianLvAdd) - GetStatePara1(target,ESBUFF_WuMianLvDes) + GetStatePara3(target,ESBUFF_ShieldMianShang) + GetStatePara1(target,ESBUFF_Protect) + GetStatePara1(target,ESBUFF_MianShangTemp))/10000.0;
	}
	else	// 法防
	{
		ratio += (pSrc->unitAttr.zengshangLv + GetStatePara1(src,ESBUFF_ZengShangLvAdd) - GetStatePara1(src,ESBUFF_ZengShangLvDes))/10000.0;
		ratio -= (pTar->unitAttr.famianLv + GetStatePara1(target,ESBUFF_JianShangLvAdd) - GetStatePara1(target,ESBUFF_JianShangLvDes) + GetStatePara1(target,ESBUFF_FaMianLvAdd) - GetStatePara1(target,ESBUFF_FaMianLvDes) + GetStatePara3(target,ESBUFF_ShieldMianShang) + GetStatePara1(target,ESBUFF_Protect) + GetStatePara1(target,ESBUFF_MianShangTemp))/10000.0;
	}
	ratio -= extMianshangLv/10000.0;
	if(ratio < 0.1)
		ratio = 0.1;

	if(showFightLog)
		cout<<">>> CFight::CalUnitZengShangLv  src="<<(int)src<<", target="<<(int)target<<", 盾para2="<<GetStatePara3(target,ESBUFF_ShieldMianShang)<<", ratio = "<<ratio<<endl;
	return ratio;
}

float CFight::CalUnitAddShangHaiLv(uint8 src,uint8 target,uint8 attackType)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTar = GetFightMember(target);
	if(pSrc == NULL || pTar == NULL)
		return 1.0;
	float ratio = 1.0 - GetStatePara1(src,ESBUFF_DamageDes)/10000.0 + GetStatePara1(src,ESBUFF_FanJian)/10000.0;
	if(attackType == 1)	// 物攻
	{
		ratio += -GetStatePara1(src,ESBUFF_WuGongDes)/10000.0;
	}
	else	// 法防
	{
		ratio += -GetStatePara1(src,ESBUFF_FaGongDes)/10000.0;
	}

	uint16 srcZhenFaId = (src <= GROUP2_BEGIN) ? m_zhenfaId[0] : m_zhenfaId[1];
	int srcZhanFaLv = (src <= GROUP2_BEGIN) ? m_zhenfaLevel[0] : m_zhenfaLevel[1];
	uint16 tarZhenFaId = (target <= GROUP2_BEGIN) ? m_zhenfaId[0] : m_zhenfaId[1];
	int tarZhenFaLv = (target <= GROUP2_BEGIN) ? m_zhenfaLevel[0] : m_zhenfaLevel[1];
	if(SingletonCZhenFaCfgMgr::instance().IsKeZhi(srcZhenFaId,tarZhenFaId))
	{
		ratio *= 1.0 + (0.1 + (srcZhanFaLv - tarZhenFaLv) / 100.0);
		if(showFightLog)
			cout<<",AddShangHai  src="<<(int)src<<", target="<<(int)target<<", srcZFID="<<srcZhenFaId<<", tarZFID="<<tarZhenFaId<<", kezhi+0.1, ratio="<<ratio<<endl;
	}
	else
	{
		if(showFightLog)
			cout<<",AddShangHai  src="<<(int)src<<", target="<<(int)target<<", srcZFID="<<srcZhenFaId<<", tarZFID="<<tarZhenFaId<<", kezhi=0, ratio="<<ratio<<endl;
	}
	if(ratio < 0.1)
		ratio = 0.1;
	return ratio;
}

float CFight::CalUnitShangHaiJianMianLv(uint8 src,uint8 target,uint8 attackType)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTar = GetFightMember(target);
	if(pSrc == NULL || pTar == NULL)
		return 1.0;
	float ratio = 1.0 + GetStatePara1(target,ESBUFF_GetDamageAdd)/10000.0;
	if(attackType == 1)	// 物攻
	{
		ratio -= -GetStatePara1(target,ESBUFF_GetWuDamageAdd)/10000.0;
	}
	else	// 法防
	{
		ratio -= -(GetStatePara1(target,ESBUFF_GetFaDamageAdd) + GetStatePara1(target,ESBUFF_WuMianAndGetFaDamageAdd))/10000.0;
	}

	uint16 srcZhenFaId = (src <= GROUP2_BEGIN) ? m_zhenfaId[0] : m_zhenfaId[1];
	int srcZhanFaLv = (src <= GROUP2_BEGIN) ? m_zhenfaLevel[0] : m_zhenfaLevel[1];
	uint16 tarZhenFaId = (target <= GROUP2_BEGIN) ? m_zhenfaId[0] : m_zhenfaId[1];
	int tarZhenFaLv = (target <= GROUP2_BEGIN) ? m_zhenfaLevel[0] : m_zhenfaLevel[1];
	if(SingletonCZhenFaCfgMgr::instance().IsKeZhi(tarZhenFaId,srcZhenFaId))
	{
		ratio *= 1.0 - (0.1 + (tarZhenFaLv - srcZhanFaLv) / 100.0);
		if(showFightLog)
			cout<<",ShangHaiJianMian  src="<<(int)src<<", target="<<(int)target<<", srcZFID="<<srcZhenFaId<<", tarZFID="<<tarZhenFaId<<", kezhi-0.1, ratio="<<ratio<<endl;
	}
	else
	{
		if(showFightLog)
			cout<<",ShangHaiJianMian  src="<<(int)src<<", target="<<(int)target<<", srcZFID="<<srcZhenFaId<<", tarZFID="<<tarZhenFaId<<", kezhi=0, ratio="<<ratio<<endl;
	}
	if(ratio < 0.1)
		ratio = 0.1;
	return ratio;
}

int CFight::CalculateDamage(uint8 src,uint8 target,vector<SAttrData> &attrList,vector<SAttrData> &tarAttrList)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 1;
	int attackType = pSrc->attackType;
	int damage = GetUnitAttack(src) - GetUnitFangYu(target,attackType) * (1.0 - GetAttrValue(attrList,ESkill_PassAttr_HuShiFang)/10000.0);
	float damRatio = CalUnitZengShangLv(src,target,attackType,GetAttrValue(tarAttrList,ESkill_PassAttr_ImproveMianShangLv));
	float addDamPercent = CalUnitAddShangHaiLv(src,target,attackType);
	float offsetDamRatio = CalUnitShangHaiJianMianLv(src,target,attackType);
	if(attackType == 1)	// 物攻
	{
		// 物理攻击无效
		if(HaveBuff(target,ESBUFF_WuMianAndGetFaDamageAdd))
			return 1;
	}

	if(offsetDamRatio < 0.1)
		offsetDamRatio = 0.1;
//	damage *= 0.8;
	if(damage < 1)
		damage = 1;
	damage += GetAttrValue(attrList,ESkill_PassAttr_Damage);
	addDamPercent += GetAttrValue(attrList,ESkill_PassAttr_DamagePer)/10000.0;
	if(showFightLog)
		cout<<", src="<<(int)src<<",  target="<<(int)target<<", damageB = "<<damage<<", damRatio="<<damRatio<<", addDamPercent="<<addDamPercent<<", offsetDamRatio="<<offsetDamRatio<<endl;

	damage *= damRatio * addDamPercent * offsetDamRatio;
	if(damage < 1)
		damage = 1;
	return damage;
}

void CFight::GetLiveMember(uint8 *arr,uint8 &num)
{
	num = 0;
	for(uint8 i = 0; i < MAX_MEMBER; i++)
	{
		if(!m_members[i].memPtr.empty() && IsAlive(i+1))
		{
			arr[num] = i+1;
			num++;
		}
	}
}

bool CFight::CalculateIsFuHuo(uint8 src,int &fuhuoHp)
{
	vector<SAttrData> attr;
	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_AttackByZhiSi);
	CalculatePassiveSkill_ExtValue(src,0,trigger,attr);
	fuhuoHp	= GetMaxHp(src) * (GetAttrValue(attr,ESkill_PassAttr_AddHpPer) / 10000.0);
	return (fuhuoHp > 0);
}

int CFight::CalculateHitRatio(uint8 src,uint8 target)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 0;

	vector<SAttrData> attrList; 
	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_Attacking);
	CalculatePassiveSkill_ExtValue(src,target,trigger,attrList);

	int basicShanBi = pTarget->unitAttr.shanbi - GetAttrValue(attrList,EAT_ShanBi);
	float shanbiLv = ((float)basicShanBi) / (basicShanBi + pSrc->level*GetParaShanBi1() + GetParaShanBi2()) + pTarget->unitAttr.shanbiLv / 10000.0;
	shanbiLv += GetStatePara1(target,ESBUFF_ShanBiLvAdd) /10000.0;
	shanbiLv += GetAttrValue(attrList,EAT_ShanBiLv) /10000.0;

	int basicMingZhong = pSrc->unitAttr.mingzhong + GetAttrValue(attrList,EAT_MingZhong);
	float mingzhongLv = ((float)basicMingZhong) / (basicMingZhong + pTarget->level*GetParaMingZhong1() + GetParaMingZhong2()) + pSrc->unitAttr.mingzhongLv / 10000.0;
	mingzhongLv += (GetStatePara1(src,ESBUFF_AddMingZhongLv) - GetStatePara1(src,ESBUFF_ReduceMingZhongLv)) / 10000.0;
	mingzhongLv += GetAttrValue(attrList,EAT_MingZhongLv) /10000.0;

	float ratio = 1.0 + mingzhongLv - shanbiLv;
	if(ratio < 0.0)
		ratio = 0.0;
	if(ratio > 1.0)
		ratio = 1.0;
	return ratio*10000;

/*	
	const float a = 3.0;
	const float b = 35.0;
	const float baseMingZhongLv = 0.9;
	int shanbi = pTarget->unitAttr.shanbi * (1 - GetAttrValue(attrList,EAT_ShanBi)/10000.0);
	float mingzhongLv = pSrc->unitAttr.mingzhong * a / (pSrc->unitAttr.mingzhong * a + b * GetFightSideRatio(FST_DEFEND,pTarget->level));
	float shanbiLv = shanbi * a / (shanbi * a + b * GetFightSideRatio(FST_ATTACK,pSrc->level)) ;
	float ratio = baseMingZhongLv + (pSrc->unitAttr.mingzhongLv - GetStatePara1(src,ESBUFF_ReduceMingZhongLv) + GetStatePara1(src,ESBUFF_AddMingZhongLv))/10000.0 + mingzhongLv;
	ratio -= (pTarget->unitAttr.shanbiLv/10000.0 + shanbiLv + GetStatePara1(target,ESBUFF_ShanBiLvAdd)/10000.0)*(1 - GetAttrValue(attrList,EAT_ShanBiLv)/10000.0);
	return ratio*10000;
*/
}

int CFight::GetBaoJiDamage(uint8 src,int damage,int passBaojiAdd)
{
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	damage *= (pSrc->unitAttr.baojiAdd + GetStatePara1(src,ESBUFF_BaoJiShangHaiAdd) + passBaojiAdd)/10000.0;
	return damage;
}

bool CFight::CalculateBaoJiRatio(uint8 src,uint8 target,int &damage,vector<SAttrData> &attrList)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return false;

	int basicBaojiKang = pTarget->unitAttr.baojikang - GetAttrValue(attrList,EAT_BaoJiKang);
	float baojiKangLv = ((float)basicBaojiKang) / (basicBaojiKang + pSrc->level*GetParaKangBao1() + GetParaKangBao2()) + pTarget->unitAttr.baojikangLv / 10000.0;
	baojiKangLv -= GetStatePara1(target,ESBUFF_BaoJiKangDes) / 10000.0;
	baojiKangLv += GetAttrValue(attrList,EAT_BaoJiKangLv)/10000.0;

	int basicBaoji = pSrc->unitAttr.baoji + GetAttrValue(attrList, EAT_BaoJi);
	float baojiLv = ((float)basicBaoji) / (basicBaoji + pTarget->level*GetParaBaoJi1() + GetParaBaoJi2()) + pSrc->unitAttr.baojiLv / 10000.0;
	baojiLv += GetStatePara1(src,ESBUFF_BaoJiLvAdd) / 10000.0;
	baojiLv += GetAttrValue(attrList,EAT_BaoJiLv) / 10000.0 + GetAttrValue(attrList,ESkill_PassAttr_BaoJiLv) / 10000.0;

	float ratio = baojiLv - baojiKangLv;
	if(ratio < 0.0)
		ratio = 0.0;
	else if(ratio > 1.0)
		ratio = 1.0;

	int r = Random(1,10000);
	if(r <= (int)(ratio*10000))
	{
		damage = GetBaoJiDamage(src,damage,GetAttrValue(attrList,EAT_BaoJiAdd));
		if(damage < 1)
			damage = 1;
		return true;
	}
	return false;

/*
	const float a = 3.0;
	const float b = 35.0;
	int baojiKang = pTarget->unitAttr.baojikang * (1 - GetAttrValue(attrList,EAT_BaoJiKang)/10000.0);
	float baojiLv = pSrc->unitAttr.baoji * a / (pSrc->unitAttr.baoji * a + b * GetFightSideRatio(FST_DEFEND,pTarget->level));
	float baojiKangLv = baojiKang * a / (baojiKang * a + b * GetFightSideRatio(FST_ATTACK,pSrc->level));
	float ratio = pSrc->unitAttr.baojiLv/10000.0 + baojiLv - (pTarget->unitAttr.baojikangLv/10000.0 + baojiKangLv)*(1 - GetAttrValue(attrList,EAT_BaoJiKangLv)/10000.0);
	ratio += (GetStatePara1(src,ESBUFF_BaoJiLvAdd) - GetStatePara1(target,ESBUFF_BaoJiKangDes))/10000.0;
	ratio += GetAttrValue(attrList,ESkill_PassAttr_BaoJiLv)/10000.0;
	if(ratio < 0.0)
		return false;

	int r = Random(1,10000);
	if(r <= (int)(ratio*10000))
	{
		damage = GetBaoJiDamage(src,damage,GetAttrValue(attrList,EAT_BaoJiAdd));
		if(damage < 1)
			damage = 1;
		return true;
	}
	else
	{
		return false;
	}
*/
}

bool CFight::CalculateBaoJiRatio_AddHp(uint8 src,vector<SAttrData> &attrList)
{
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return false;

	const float a = 3.0;
	const float b = 35.0;
	float baojiLv = pSrc->unitAttr.baoji * a / (pSrc->unitAttr.baoji * a + b * GetFightSideRatio(FST_DEFEND,pSrc->level));
	float ratio = pSrc->unitAttr.baojiLv/10000.0 + baojiLv;
	ratio += (GetStatePara1(src,ESBUFF_BaoJiLvAdd) + GetAttrValue(attrList,ESkill_PassAttr_BaoJiLv))/10000.0;
	if(ratio < 0.0)
		return false;
	
	int r = Random(1,10000);
	if(r <= (int)(ratio*10000))
		return true;
	return false;
}

// -2 有一方死亡 -1 无反击 > 0 反击值
bool CFight::CalculateFanJiRatio(uint8 src,uint8 target,vector<SAttrData> &attrList,int extFanJiLv)
{
	if(!IsAlive(src) || !IsAlive(target))
		return false;
	
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pSrc == NULL || pTarget == NULL)
		return false;
	
	int fanjiLv = pTarget->unitAttr.fanjiLv*(1 - GetAttrValue(attrList,EAT_FanJiLv)/10000.0) - pSrc->unitAttr.fanjikangLv + extFanJiLv;
	int r = Random(1,10000);
	if(r <= fanjiLv)
		return true;
	return false;
}

// -2 有一方死亡 -1 无连击 > 0 连击值
bool CFight::CalculateLianJiRatio(uint8 src,uint8 target)
{
	if(!IsAlive(src) || !IsAlive(target))
		return false;

	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return false;

	vector<SAttrData> attrList; 
	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_Attacking);
	trigger.push_back(ESkill_Trigger_AttackZhongDu);
	trigger.push_back(ESkill_Trigger_AttackDebuff);
	trigger.push_back(ESkill_Trigger_AttackingZhuoShang);
	CalculatePassiveSkill_ExtValue(src,target,trigger,attrList);
	int lianjiLv = pSrc->unitAttr.lianjiLv - pTarget->unitAttr.lianjikangLv * (1 - GetAttrValue(attrList,EAT_LianJiKangLv)/10000.0) + GetStatePara1(src,ESBUFF_LianJiLvAdd);
	int r = Random(1,10000);
	if(r <= lianjiLv)
	{
		return true;
	}
	return false;
}

uint8 CFight::XunChaShiZhaoHuan(uint8 src,CNetMessage &msg)
{
	uint8 num = 0;
	uint16 numPos = 0xffff;
	for(uint8 i=0;i < CFight::GROUP2_BEGIN;i++)
	{
		SMonsterInst *pMonster = GetMonster(i+1);
		if(pMonster != NULL && !IsAlive(i+1))
		{
			SMonsterInst *pM = new SMonsterInst;
			*pM = *pMonster;
			ShareMonsterPtr ptr(pM);
			pM->hp = pM->attr.maxHp;
			AddTmplNoLock(ptr,i+1,0xff);
			if(num == 0)
			{
				msg<<(uint8)EOTZhaoHuan<<src<<PRO_SUCCESS;
				numPos = msg.GetDataLen();
				msg<<num;
			}

			msg<<(uint8)0	//怪
				<<(uint8)(i+1)<<pM->pic<<pM->name
				<<pM->level<<pM->attr.maxHp<<pM->hp<<pM->scale<<"";
			num++;
		}
	}
	if(num > 0)
	{
		msg.WriteData(numPos,&num,sizeof(num));
		return 1;
	}
	return 0;
}

uint8 CFight::GetUnitSkillLevel(uint8 pos,uint16 skillId)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;

	uint8 skillLevel = p->GetSkillLevel(skillId);
	if(skillLevel == 0 && p->type == EFMT_MONSTER)
		skillLevel = 1;
	return skillLevel;
}

uint8 CFight::NormalButtle(uint8 src,uint8 target)
{
	if(m_forceEnd)
		return 0;
	if(target == 0)
	{
		uint8 allTarget[GROUP2_BEGIN];
		uint8 num = 0;
		GetAnotherGroupByAttackedOrder(src,allTarget,num);
		if(num <= 0)
			return 0;
		target = allTarget[0];
	}

	if(showFightLog)
		cout<<"--- "<<(int)src<<": normal attack , to:"<<(int)target<<endl;

	return CalculateNormal_DamageHp(src,target);
}

int CFight::GetSuccesExp(uint8 pos,int *pMoney)
{
	uint8 begin;
	uint8 end;
	if(pos > GROUP2_BEGIN)
	{
		begin = 1;
		end = GROUP2_BEGIN + 1;
	}
	else
	{
		begin = GROUP2_BEGIN + 1;
		end = MAX_MEMBER + 1;
	}

	CUser *pUser = GetUser(pos);
	int level = 0;
	if(pUser != NULL)
		level = pUser->GetLevel();
	else
		return 0;

	int exp = 0;
	int monsterNum = 0;
	for(uint8 i = begin; i < end; i++)
	{
		SMonsterInst *pMonster = GetMonster(i);
		if(pMonster != NULL)
		{
			if(pUser != NULL && pMonster->level >= level+5)
				exp += (int)((level+Random(0,10)-5) * 0.8);
			else
				exp += (int)(pMonster->level*0.8);
			monsterNum++;
		}
	}
	if(InHuoDong())
	{
		exp *= GetHuoDongBeiLv();
	}

	if(pMoney != NULL)
	{
		*pMoney = 0;
	}
	return exp;
}

uint8 CFight::OneGroupAllDie()
{
	bool group1AllDied = true;
	bool group2AllDied = true;
	for(uint8 pos = 0; pos < GROUP2_BEGIN; pos++)
	{
		if((!m_members[pos].memPtr.empty()) && IsAlive(pos+1))
		{
			group1AllDied = false;
			break;
		}
	}
	for(uint8 pos = GROUP2_BEGIN; pos < MAX_MEMBER; pos++)
	{
		if((!m_members[pos].memPtr.empty()) && IsAlive(pos+1))
		{
			group2AllDied = false;
			break;
		}
	}
	if(group1AllDied && group2AllDied)
		return 3;
	if(group1AllDied)
		return 1;
	if(group2AllDied)
		return 2;
	return 0;
}

uint8 CFight::CalculateWinGroup()
{
	if(m_forceEnd)
		return EGT_GROUP2;
	
	uint8 winGroup = EGT_GROUP1;
	for(uint8 pos = GROUP2_BEGIN; pos < MAX_MEMBER; pos++)
	{
		if((!m_members[pos].memPtr.empty()) && IsAlive(pos+1))
		{
			winGroup = EGT_GROUP2;
			break;
		}
	}
	return winGroup;
}

void CFight::StealBuff(uint8 src,SFightBuffData &buffData)
{
	vector<ESkillTriggerType> triggerList;
	triggerList.push_back(ESkill_Trigger_ClearEnBuff);
	CalculatePassiveSkill_ExtUnitAndBuff(src,0,triggerList,0,0,0,NULL,false,&buffData);
}

void CFight::ClearMulBuff(uint8 pos,uint16 buffId,uint8 src)
{
	if(pos == 0 || pos > MAX_MEMBER || buffId == 0)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	if(buffId >= ESBUFF_MAX)
	{
		vector<int> buffList;
		if(buffId == ESBUFF_AllEnBuff)
			SingletonCSkillMgr::instance().GetEnBuffList(buffList);
		else if(buffId == ESBUFF_AllDeBuff)
			SingletonCSkillMgr::instance().GetDeBuffList(buffList);
		else if(buffId == ESBUFF_AllZhongDu)
			SingletonCSkillMgr::instance().GetZhongDuBuffList(buffList);
		else
			return;

		uint8 size = buffList.size();
		vector<SFightBuffData> dataList;
		for(uint16 i=0; i < size; i++)
		{
			ClearBuff(pos, buffList[i], &dataList);
		}
		
		if(buffId == ESBUFF_AllEnBuff && size > 0)
		{
			if(!dataList.empty())
			{
				uint16 randIdx = Random(1, dataList.size()) - 1;
				StealBuff(src, dataList[randIdx]);
			}
		}
	}
	else
	{
		vector<SFightBuffData> dataList;
		ClearBuff(pos, buffId, &dataList);
		if(dataList.empty())
			return;
		int randIdx = Random(1, dataList.size()) - 1;
		if(SingletonCSkillMgr::instance().IsEnBuff(buffId) && randIdx >= 0)
			StealBuff(src, dataList[randIdx]);
	}
}

void CFight::ClearRandomEnBuff(uint8 pos,uint16 buffNum,uint8 src)
{
	if(pos == 0 || pos > MAX_MEMBER || buffNum == 0)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	vector<int> buffPos;
	vector<int> enbuff;
	SingletonCSkillMgr::instance().GetDeBuffList(enbuff);
	int idx = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(find(enbuff.begin(), enbuff.end(), it->id) != enbuff.end())
			buffPos.push_back(idx);
		idx++;
	}
	if(buffPos.empty())
		return;
	
	uint16 size = buffPos.size();
	vector<int> randSeq(size);
	int delNum = 0;
	RandomSequence(&randSeq[0], size, size);
	uint16 delSize = (size > buffNum) ? buffNum : size;
	if(delSize > 1)
	{
		std::sort(randSeq.begin(), randSeq.begin()+delSize);
	}
	int stealBufIdx = randSeq[Random(1,delSize) - 1];
	idx = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
	{
		if(delNum >= delSize)
			break;
		bool isDel = false;
		for(uint16 i=0; i < delSize; i++)
		{
			if(idx == randSeq[i]-1)
			{
				isDel = true;
				break;
			}
		}

		if(isDel)
		{
			delNum++;
			SFightBuffData data = *it;
			SpecialBuffPassAttr(pos, it->id, false);	// 清除buff触发
			// 删除
			list<SFightBuffData>::iterator del_it = it;
			it++;
			m_members[pos-1].buff_list.erase(del_it);
			if(stealBufIdx-1 == idx)	// 偷增益buff
			{
				StealBuff(src, data);
			}
		}
		else
		{
			it++;
		}
		idx++;
	}
}

void CFight::ClearRandomDeBuff(uint8 pos,uint16 buffNum)
{
	if(pos == 0 || pos > MAX_MEMBER || buffNum == 0)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	vector<int> buffPos;
	vector<int> debuff;
	SingletonCSkillMgr::instance().GetDeBuffList(debuff);
	int idx = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(find(debuff.begin(), debuff.end(), it->id) != debuff.end())
			buffPos.push_back(idx);
		idx++;
	}
	if(buffPos.empty())
		return;
	
	uint16 size = buffPos.size();
	vector<int> randSeq(size);
	int delNum = 0;
	RandomSequence(&randSeq[0], size, size);
	uint16 delSize = (size > buffNum) ? buffNum : size;
	if(delSize > 1)
	{
		std::sort(randSeq.begin(), randSeq.begin()+delSize);
	}
	idx = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
	{
		if(delNum >= delSize)
			break;
		bool isDel = false;
		for(uint16 i=0; i < delSize; i++)
		{
			if(idx == randSeq[i] - 1)
			{
				isDel = true;
				break;
			}
		}

		if(isDel)
		{
			delNum++;
			SpecialBuffPassAttr(pos, it->id, false);	// 清除buff触发
			list<SFightBuffData>::iterator del_it = it;
			it++;
			m_members[pos-1].buff_list.erase(del_it);
		}
		else
		{
			it++;
		}
		idx++;
	}
}

void CFight::ClearBuff(uint8 pos, uint16 buffId, vector<SFightBuffData> *dataList)
{
	if(buffId == 0 || buffId >= ESBUFF_MAX)
		return;
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;
	
	if(HaveBuff(pos,buffId))
		SpecialBuffPassAttr(pos,buffId,false);	// 清除

	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
	{
		if(it->id == buffId)
		{
			if(dataList != NULL)
				dataList->push_back(*it);
			
			list<SFightBuffData>::iterator del_it = it;
			it++;
			m_members[pos-1].buff_list.erase(del_it);
			continue;
		}
		it++;
	}
}

void CFight::SetState(uint8 pos, int state)
{
	if(pos == 0 || pos > MAX_MEMBER || state <= 0 || state >= EFST_STATE_MAX)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	if(state == EFST_STATE_Die)	// 死亡
	{
		SpecialBuffPassAttr(pos,ESBUFF_MeiHuo,false);	// 清除buff时触发

		// 死亡清理buff, 特殊buff不清除
		const uint16 saveBuffList[] = {ESBUFF_ForbidFuHuo};	// 死亡保留的buff
		uint16 nsize = sizeof(saveBuffList)/sizeof(saveBuffList[0]);
		for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
		{
			bool isdel = true;
			for(uint16 i=0; i < nsize; i++)
			{
				if(it->id == saveBuffList[i])
				{
					isdel = false;
					break;
				}
			}
			
			if(isdel)
			{
				list<SFightBuffData>::iterator del_it = it;
				it++;
				m_members[pos-1].buff_list.erase(del_it);
			}
			else
			{
				it++;
			}
		}
	}

	uint8 flag = 1 << (EFST_STATE_Die-1);
	m_members[pos-1].state |= flag;
}

void CFight::ClearState(uint8 pos, int state)
{
	if(pos == 0 || pos > MAX_MEMBER || state <= 0 || state >= EFST_STATE_MAX)
		return;
	if(m_members[pos-1].memPtr.empty())
		return;

	uint8 flag = 1 << (state-1);
	m_members[pos-1].state &= ~flag;
}

bool CFight::HaveState(uint8 pos, int state)
{
	if(pos == 0 || pos > MAX_MEMBER || state <= 0 || state >= EFST_STATE_MAX)
		return false;
	if(m_members[pos-1].memPtr.empty())
		return false;

	uint8 flag = 1 << (state-1);
	if((m_members[pos-1].state & flag) > 0)
		return true;
	return false;
}

void CFight::AddBuff(uint8 pos, uint8 src, uint16 buffId, uint8 effectTurn, vector<int> *para)
{
	if(buffId == 0 || buffId >= ESBUFF_MAX || effectTurn == 0)
		return;
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	if(!HaveBuff(pos, buffId))
		SpecialBuffPassAttr(pos, buffId, true);	// 添加buff时触发

	SFightBuffData data;
	data.srcPos = src;
	data.id = buffId;
	data.leftTurn = effectTurn;
	if(para != NULL)
		data.paraList = *para;
	m_members[pos-1].buff_list.push_back(data);
}

bool CFight::IsShieldBuff(uint16 buffId)
{
	if(buffId == ESBUFF_ShieldMianShang || buffId == ESBUFF_Shield)
	{
		return true;
	}
	return false;
}

void CFight::ShieldAbsorptionDamage(uint8 pos, int &hp, int &absorptionHp)
{
	if(pos == 0 || pos > MAX_MEMBER || hp <= 0)
		return;
	int turn = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(IsShieldBuff(it->id))
		{
			if(it->leftTurn == 0 || it->paraList.empty() || it->paraList[0] <= 0)
				continue;
			if(turn == 0 || it->leftTurn < turn)
				turn = it->leftTurn;
		}
	}
	if(turn == 0)
		return;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(IsShieldBuff(it->id))
		{
			if(it->leftTurn == 0 || it->paraList.empty())
				continue;
			int val = it->paraList[0];
			if(val <= 0)
				continue;
			if(it->leftTurn == turn)
			{
				if(val >= hp)
				{
					val -= hp;
					absorptionHp += hp;
					hp = 0;
				}
				else
				{
					val = 0;
					absorptionHp += val;
					hp -= val;
				}
				it->paraList[0] = val;
			}
			if(hp == 0)
				return;
		}
	}
	if(hp > 0)
	{
		ShieldAbsorptionDamage(pos, hp, absorptionHp);
	}
}

bool CFight::ShieldBrokenCheck(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	bool ret = false;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
	{
		if(IsShieldBuff(it->id))
		{
			if(it->paraList.size() < 2 || it->paraList[0] <= 0)
			{
				list<SFightBuffData>::iterator del_it = it;
				it++;

				int val = del_it->paraList[1];
				vector<ESkillTriggerType> trigger;
				trigger.push_back(ESkill_Trigger_SelfShieldMiss);
				int res = CalculatePassiveSkill_ExtUnitAndBuff(pos, 0, trigger, 0, 0, val);
				m_members[pos-1].buff_list.erase(del_it);
				
				if(res == 1)
					ret = true;
				continue;
			}
		}
		it++;
	}
	return ret;
}

uint8 CFight::GetStateSrcPos(uint8 pos, uint16 buffId)
{
	if(pos == 0 || pos > MAX_MEMBER || buffId == 0)
		return 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
			return it->srcPos;
	}
	return 0;
}

int CFight::GetStatePara1(uint8 pos,uint16 buffId)
{
	if(pos == 0 || pos > MAX_MEMBER || buffId == 0)
		return 0;
	int val = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
		{
			if(it->paraList.empty())
				continue;
			val += it->paraList[0];
		}
	}
	return val;
}

int CFight::GetStatePara2(uint8 pos,uint16 buffId)
{
	if(pos == 0 || pos > MAX_MEMBER || buffId == 0)
		return 0;
	int val = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
		{
			if(it->paraList.size() < 2)
				continue;
			val += it->paraList[1];
		}
	}
	return val;
}

int CFight::GetStatePara3(uint8 pos,uint16 buffId)
{
	if(pos == 0 || pos > MAX_MEMBER || buffId == 0)
		return 0;
	int val = 0;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
		{
			if(it->paraList.size() < 3)
				continue;
			val += it->paraList[2];
		}
	}
	return val;
}

void CFight::DecHunShuiTimes(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == ESBUFF_HunShui)
		{
			if(it->paraList.empty())
				continue;
			it->paraList[0]--;
			if(it->paraList[0] <= 0)
			{
				SpecialBuffPassAttr(pos, ESBUFF_HunShui, false);	// 清除
				
				m_members[pos-1].buff_list.erase(it);
			}
			return;
		}
	}
}

void CFight::DecAllStateEffectTurn(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	for(list<SFightBuffData>::iterator it = m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); )
	{
		it->leftTurn--;
		if(it->leftTurn <= 0)
		{
			// 清除buff
			list<SFightBuffData>::iterator del_it = it;
			if(del_it->id == ESBUFF_ShieldMianShang || del_it->id == ESBUFF_Shield)
			{
				vector<ESkillTriggerType> shieldTrigger;
				shieldTrigger.push_back(ESkill_Trigger_SelfShieldMiss);
				int shieldDamage = del_it->paraList[1];
				if(shieldDamage > 0)
				{
					CalculatePassiveSkill_ExtUnitAndBuff(pos, 0, shieldTrigger, 0, 0, shieldDamage, NULL, true);
				}
			}

			it++;
			m_members[pos-1].buff_list.erase(del_it);
		}
		else
		{
			it++;
		}
	}
}

void CFight::DecAllSkillCD(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p != NULL)
	{
		p->DecAllSkillCD();
	}
}

void CFight::ClearAdditiveSkillTurnData(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p != NULL)
	{
		p->ClearPassSkillTurnData();
	}
}

void CFight::SpecialBuffPassAttr(uint8 pos,uint16 buffId,bool add)
{
	if(!IsAlive(pos))
		return;

	uint8 member[GROUP_MEMBER];
	uint8 num=0;
	vector<ESkillTriggerType> trigger;
	if(buffId == ESBUFF_MeiHuo)
	{
		trigger.push_back(ESkill_Trigger_HaveMeiHuoState);
		vector<ESkillPassitiveType> passList;
		passList.push_back(ESkill_Pass_Attr);
		int addNum = add ? 1 : -1;
		GetAnotherGroup(pos,member,num);
		for(uint8 i=0;i < num;i++)
			CalculatePassiveSkill_ExtAttrEffect(member[i],0,trigger,passList,0,0,addNum);
	}
}

bool CFight::HaveEnBuffState(uint8 pos)
{
	vector<int> enBuff;
	SingletonCSkillMgr::instance().GetEnBuffList(enBuff);
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		for(uint8 i=0;i < enBuff.size();i++)
		{
			if(HaveBuff(pos,enBuff[i]))
				return true;
		}
	}
	return false;
}

bool CFight::HaveDeBuffState(uint8 pos)
{
	vector<int> deBuff;
	SingletonCSkillMgr::instance().GetDeBuffList(deBuff);
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		for(uint8 i=0;i < deBuff.size();i++)
		{
			if(HaveBuff(pos,deBuff[i]))
				return true;
		}
	}
	return false;
}

bool CFight::HaveShieldState(uint8 pos)
{
	const uint16 shieldBuff[] = {ESBUFF_ShieldMianShang,ESBUFF_Shield};
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		for(uint8 i=0;i < sizeof(shieldBuff);i++)
		{
			if(HaveBuff(pos,shieldBuff[i]))
				return true;
		}
	}
	return false;
}

bool CFight::HaveZhongDuState(uint8 pos)
{
	const uint16 BuffList[] = {ESBUFF_ShiXinDu,ESBUFF_ShiDu,ESBUFF_FuDu};
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		for(uint8 i=0;i < sizeof(BuffList);i++)
		{
			if(HaveBuff(pos,BuffList[i]))
				return true;
		}
	}
	return false;
}

bool CFight::FindBuffData(uint8 pos,uint16 buffId)
{
	if(buffId == 0)
		return false;
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	if(m_members[pos-1].memPtr.empty())
		return false;

	for(list<SFightBuffData>::iterator it=m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
			return true;
	}
	return false;
}

bool CFight::HaveBuff(uint8 pos,uint16 buffId)
{
	if(buffId == 0)
		return false;
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	if(m_members[pos-1].memPtr.empty())
		return false;

	for(list<SFightBuffData>::iterator it=m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id == buffId)
			return true;
	}
	return false;
}

bool CFight::HaveHunLuan(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	const int buffId[] = {ESBUFF_HunLuan, ESBUFF_MeiHuo, ESBUFF_FanJian};
	for(list<SFightBuffData>::reverse_iterator it=m_members[pos-1].buff_list.rbegin(); it != m_members[pos-1].buff_list.rend(); it++)
	{
		for(uint16 i=0; i < sizeof(buffId)/sizeof(buffId[0]); i++)
		{
			if(it->id == buffId[i])
			{
				return (buffId[i] == ESBUFF_HunLuan);
			}
		}
	}
	return false;
}

bool CFight::HaveMeiHuo(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	const int buffId[] = {ESBUFF_HunLuan, ESBUFF_MeiHuo, ESBUFF_FanJian};
	for(list<SFightBuffData>::reverse_iterator it=m_members[pos-1].buff_list.rbegin(); it != m_members[pos-1].buff_list.rend(); it++)
	{
		for(uint16 i=0; i < sizeof(buffId)/sizeof(buffId[0]); i++)
		{
			if(it->id == buffId[i])
			{
				return (buffId[i] == ESBUFF_MeiHuo);
			}
		}
	}
	return false;
}

bool CFight::HaveFanJian(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return false;
	const int buffId[] = {ESBUFF_HunLuan, ESBUFF_MeiHuo, ESBUFF_FanJian};
	for(list<SFightBuffData>::reverse_iterator it=m_members[pos-1].buff_list.rbegin(); it != m_members[pos-1].buff_list.rend(); it++)
	{
		for(uint16 i=0; i < sizeof(buffId)/sizeof(buffId[0]); i++)
		{
			if(it->id == buffId[i])
			{
				return (buffId[i] == ESBUFF_FanJian);
			}
		}
	}
	return false;
}

void CFight::MakeBuffList(uint8 pos,CNetMessage &msg)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	msg<<m_members[pos-1].state;

	uint32 numPos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	for(list<SFightBuffData>::iterator it=m_members[pos-1].buff_list.begin(); it != m_members[pos-1].buff_list.end(); it++)
	{
		if(it->id >= ESBUFF_ShowBegin)
			continue;
		msg<<(uint8)it->id;
		num++;
	}
	msg.WriteData(numPos, &num, sizeof(num));
}

void CFight::MakeSkillInfoInFight(uint8 pos,CNetMessage &msg)
{
	uint16 numPos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return;
	for(uint8 i=0;i < p->skill_list.size();i++)
	{
		if(p->skill_list[i].id > 0)
		{
			num++;
			msg<<p->skill_list[i].id<<(uint8)p->skill_list[i].leftCD;
		}
	}
	msg.WriteData(numPos,&num,sizeof(num));
}

int CFight::GiveItemByMonster(CUser *pUser,SMonsterInst *pInst)
{
	if(pUser->HaveBitSet(0))
		return 0;
	if(pInst == NULL)
		return 0;
	SMonsterTmpl *pMonster = NULL;//pInst->pMonster;
	if(pMonster == NULL)
		return 0;
	int monsterLevel = pInst->level;

	double per = 1 - (abs(pUser->GetLevel() - monsterLevel) - 5) * 0.08;
	if(per < 0)
		return 0;
	int end = (int)(10000/per);
	uint8 userNum = 0;
	for(uint8 i = 0; i < MAX_MEMBER; i++)
	{
		if(m_members[i].memPtr.type() == typeid(ShareUserPtr))
			userNum++;
	}

	int num = Random(0,end);
	SDropItem *pDropItem;
	int dropNum;
	if(pInst->type == EMTTongLing)
	{
		dropNum = pMonster->headDropNum;
		pDropItem = pMonster->pHeadDropItem;
	}
	else if(InHuoDong())
	{
		dropNum = pMonster->dropNum;
		pDropItem = pMonster->pDropItem;
	}
	else
	{
		dropNum = pMonster->dropNum;
		pDropItem = pMonster->pDropItem;
	}
	
	if(pDropItem == NULL)
		return 0;
	for(int i = 0; i < dropNum; i++)
	{
		if((num >= pDropItem[i].begin) && (num <= pDropItem[i].end))
		{
			pUser->AddPackage(pDropItem[i].itemId);
			return pDropItem[i].itemId;
		}
	}
	return 0;
}

void CFight::DropItem(CUser *pUser,uint8 pos,CNetMessage &msg)
{
	msg << (uint8)0;
	return;
	bool tcard_drop = false;
	const int tcard_drop_level = 35;
	uint16 len = msg.GetDataLen();
	msg<<(uint8)0;

	uint8 num = 0;
	if(pos < GROUP2_BEGIN)
	{
		for(uint8 pos = GROUP2_BEGIN; pos < MAX_MEMBER; pos++)
		{
			SMonsterInst *pMonster = GetMonster(pos+1);
			if(pMonster != 0)
			{
				uint16 id = GiveItemByMonster(pUser,pMonster);
				if(id > 0)
				{
					num++;
					msg<<id;
				}
				if(pMonster->level >= tcard_drop_level)
					tcard_drop = true;
			}
		}
	}
	else
	{
		for(uint8 pos = 0; pos < GROUP2_BEGIN; pos++)
		{
			SMonsterInst *pMonster = GetMonster(pos+1);
			if(pMonster != 0)
			{
				uint16 id = GiveItemByMonster(pUser,pMonster);
				if(id > 0)
				{
					num++;
					msg<<id;
				}
				if(pMonster->level >= tcard_drop_level)
					tcard_drop = true;
			}
		}
	}
	if(tcard_drop)
		pUser->GetTransFormDrop();

	if(Random(1,1000) <= 15)	// 1.5%的概率掉落白色先锋令
	{
		if(pUser->EmptyPackage() < 1)
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_TRANSFORM_508,TIPS_FAILURE_COLOR).c_str());
		else
		{
			pUser->AddBangDingPackage(2354,1);
			num++;
			msg<<(uint16)2354;
		}
	}
	msg.WriteData(len,&num,1);
}

void CFight::UpdateUserInfo(CUser *pUser,list<uint32> &userList)
{
	if(pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(PRO_UPDATE_PLAYER);

	CSocketServer &sock = SingletonSocket::instance();
	COnlineUser &onlineUser = SingletonOnlineUser::instance();

	list<uint32>::iterator iter = userList.begin();
	for(; iter != userList.end(); iter++)
	{
		ShareUserPtr p = onlineUser.GetUserByRoleId(*iter);
		CUser *pU = p.get();
		if((pU != NULL) && (pU->GetRoleId() != pUser->GetRoleId()))
		{
			msg.ReWrite();
			msg.SetType(PRO_UPDATE_PLAYER);
			pUser->MakeUpdateInfo(msg,pU,ESRT_State);
			sock.SendMsg(pU->GetSock(),msg);
		}
	}
}

void CFight::MakeShowName(CNetMessage &msg)
{
	for(uint8 i=EGT_GROUP1; i <= EGT_GROUP2; i++)
	{
		if(!m_groupUser[i].empty())
			msg<<m_groupUser[i][0]->GetName();
		else
			msg<<m_ShowName[i];
	}
}

void CFight::BaiHuaXianZiJiangLi(CUser *pUser,CNetMessage &msg)
{
	uint8 num = 0;
	/*int r = Random(1,100);
	uint8 num = 2;
	if(r <= 35)
		num = 3;*/
	pUser->SetBitSet(529);	// 百花仙子战斗结束
	//pUser->AddPackage(1099,num);	// 百花碎片
	msg<<num;
	pUser->SetHuoDongFightTime(GetSysTime());
	SaveDate(pUser, 39, num);
	return;
}

void CFight::TongTianTa_BaZhuFightEnd()	// 通天塔挑战
{
	if(m_type != EFTTongTianTa_TiaoZhan)
		return;
	bool win = true;
	CUser *pBaZhu = GetGroupHead(EGT_GROUP2);
	CUser *pUser = GetGroupHead(EGT_GROUP1);
	if(pBaZhu == NULL || pUser == NULL)
		return;
	int tongtiantaLevel = pUser->m_curTongTianTaFightFloor;
	uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
	uint8 bazhuIndex = 0xff;
	for(uint8 i=0;i < bazhuNum;i++)
	{
		if(tongtiantaLevel == tongTianTaBaZhuFloor[i])
		{
			bazhuIndex = i;
			break;
		}
	}
	if(bazhuIndex == 0xff)
		return;

	win = IsFightWithPlayerWin();

	char buf[256];
	if(win)
	{
		bool changeBaZhu = false;
		{
			boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
			if(tongTianTaBaZhuData[bazhuIndex] == pBaZhu->GetRoleId())
			{
				int selfPos = 0xff;
				for(uint8 i=0;i < bazhuNum;i++)
				{
					if(tongTianTaBaZhuData[i] == pUser->GetRoleId())
					{
						selfPos = i;
						break;
					}
				}
				if(selfPos == 0xff)	// 自己不是霸主
				{
					tongTianTaBaZhuData[bazhuIndex] = pUser->GetRoleId();
					changeBaZhu = true;
				}
				else
				{
					if(selfPos < bazhuIndex)
					{
						tongTianTaBaZhuData[selfPos] = 0;
						tongTianTaBaZhuData[bazhuIndex] = pUser->GetRoleId();
						changeBaZhu = true;
					}
				}
			}
			else
			{
				SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_509,TIPS_FAILURE_COLOR).c_str());
				return;
			}
		}

		SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_510,TIPS_WARNING_COLOR).c_str());
		{ // 通知玩家可以更新界面信息了
			CNetMessage msgRet;
			msgRet.SetType(MSG_TONG_TIAN_TA);
			msgRet<<(uint8)7<<PRO_SUCCESS;
			CSocketServer &sock = SingletonSocket::instance();
			sock.SendMsg(pUser->GetSock(),msgRet);
		}
		if(changeBaZhu)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_511,pUser->GetName(),tongtiantaLevel);
			SendSystemMail(pBaZhu->GetRoleId(),buf);

			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_512, pUser->GetName(),pBaZhu->GetName(),tongtiantaLevel);
			SysInfoToAllUser(buf);
		}
	}
	else
	{
		SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_513,TIPS_FAILURE_COLOR).c_str());
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_514,pUser->GetName(),tongtiantaLevel);
		SendSystemMail(pBaZhu->GetRoleId(), buf);
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0038, pUser->GetName(), pBaZhu->GetName());
		SysInfoToAllUser(buf);
	}
}

void CFight::FeiXianFightTaoPao(CUser *pUser, uint8 pos)
{
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if (curSrcId < FEI_XIAN_SID1 || curSrcId > FEI_XIAN_SID5)
		return;
	if (m_type != EFT_FEI_XIAN)
		return;
	if (CSceneManager::IsInActivityTime(SOT_FeiXian))
	{
		bool SYNC_FLAG = true;
		pUser->SetExtData8(139, pUser->GetExtData8(139) + 1);
		int fxdown = G_VipConfig[pUser->GetVipLevel()].fxdown;
		char buf[256];
		if (pUser->GetExtData8(139) >= fxdown)
		{
			if (curSrcId > FEI_XIAN_SID1)
			{
				int nextFloor = curSrcId - FEI_XIAN_SID1 + 1 - 1;
				snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_516, fxdown, nextFloor);
				SendSysInfoFightEnd(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
				EnterFeiXianScene(pUser, nextFloor);
				SYNC_FLAG = false;
			}
		}

		if (SYNC_FLAG)
		{
			uint16 x = 0, y = 0;
			if (m_pScene->GetCanWalkPos(x, y))
			{
				pUser->SetPos(x, y);

				CNetMessage msg;
				msg.SetType(PRO_SYNC_POS);
				msg << pUser->GetRoleId() << x << y << (uint8)0;
				m_pScene->BroadcastMsgExcept(msg, pUser);
			}
			pUser->UpdateFeiXianData();
		}
	}
	else
	{
		int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
		pUser->GetEnterPos(sId, pX, pY);
		SetQiPetUp(pUser);
		SetGenSuiPetUp(pUser);
		TransportUser(pUser, sId, pX, pY, 0);
	}
}

void CFight::FeiXianFightEnd()
{	
	if(m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId < FEI_XIAN_SID1 || curSrcId > FEI_XIAN_SID5)
		return;
	if(m_type != EFT_FEI_XIAN)
		return;

	CUser *pUser_1 = NULL;	// 挑战者
	CUser *pUser_2 = NULL;	// 被挑战者
	bool group1_AllDie = true;
	bool group2_AllDie = true;
	for(uint8 pos=1; pos <= GROUP2_BEGIN; pos++)
	{
		if(IsAlive(pos))
			group1_AllDie = false;
		
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
			pUser_1 = pUser;
	}
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
			group2_AllDie = false;
		
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
			pUser_2 = pUser;
	}

	CUser *pUserAlive = NULL;
	CUser *pUserDie = NULL;
	if(group1_AllDie && !group2_AllDie)	// group2胜利
	{
		pUserAlive = pUser_2;
		pUserDie = pUser_1;
	}
	else if(!group1_AllDie && group2_AllDie)	// group1胜利
	{
		pUserAlive = pUser_1;
		pUserDie = pUser_2;
	}
	else
	{
		return;
	}

	char buf[128];
	if(CSceneManager::IsInActivityTime(SOT_FeiXian))
	{
		if(pUserDie != NULL && pUserDie->GetFeiXianState() > 0)
		{
			if(pUserDie != NULL)
			{
				pUserDie->SetFeiXianState(0);
				m_pScene->UpdateUserInfo(pUserDie,ESRT_State);
			}
			if(pUserAlive != NULL)
			{
				pUserAlive->SetFeiXianState(1);
				m_pScene->UpdateUserInfo(pUserAlive,ESRT_State);
			}
			// 公告
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0061, pUserAlive->GetName());
			SysInfoToAllUser(buf);
		}

		if(pUserAlive != NULL)
		{
			pUserAlive->SetExtData8(138,pUserAlive->GetExtData8(138)+1);
			if(pUserAlive->GetExtData8(138) >= FeiXian_UpFloorNum)
			{
				if(curSrcId < FEI_XIAN_SID5)
				{
					int nextFloor = curSrcId-FEI_XIAN_SID1+1+1;
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_515,(int)FeiXian_UpFloorNum,nextFloor);
					SendSysInfoFightEnd(pUserAlive,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					SaveDate(pUserAlive, 37, nextFloor);
					EnterFeiXianScene(pUserAlive,nextFloor);
				}
				else
				{
					pUserAlive->UpdateFeiXianData();
				}
			}
			else
			{
				pUserAlive->UpdateFeiXianData();
			}

			SingletonCHDExchangeManager::instance().DropExchangeItem(pUserAlive, EEHDT_FeiXian);
			SingletonCHDExchangeManager::instance().DropHDItem(pUserAlive, EEHDT_FeiXian);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pUserAlive, EEHDT_FeiXian);
		}

		if(pUserDie != NULL)
		{
			bool SYNC_FLAG = true;
			pUserDie->SetExtData8(139,pUserDie->GetExtData8(139)+1);
			int fxdown=G_VipConfig[pUserDie->GetVipLevel()].fxdown;
			if(pUserDie->GetExtData8(139) >= fxdown)
			{
				if(curSrcId > FEI_XIAN_SID1)
				{
					int nextFloor = curSrcId-FEI_XIAN_SID1+1-1;
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_516,fxdown,nextFloor);
					SendSysInfoFightEnd(pUserDie,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					EnterFeiXianScene(pUserDie,nextFloor);
					SYNC_FLAG = false;
				}
			}

			if(SYNC_FLAG)
			{
				uint16 x=0,y=0;
				if(m_pScene->GetCanWalkPos(x,y))
				{
					pUserDie->SetPos(x,y);
					
					CNetMessage msg;
					msg.SetType(PRO_SYNC_POS);
					msg<<pUserDie->GetRoleId()<<x<<y<<(uint8)0;
					m_pScene->BroadcastMsgDirect(msg);
//					m_pScene->BroadcastMsgExcept(msg,pUserDie);
				}
				pUserDie->UpdateFeiXianData();
			}
		}
	}
	else
	{
		if(pUser_1 != NULL && pUser_1->GetFightId() == 0)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			pUser_1->GetEnterPos(sId,pX,pY);
			SetQiPetUp(pUser_1);
			SetGenSuiPetUp(pUser_1);
			TransportUser(pUser_1, sId, pX, pY, 0);
		}
		if(pUser_2 != NULL && pUser_2->GetFightId() == 0)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			pUser_2->GetEnterPos(sId,pX,pY);
			SetQiPetUp(pUser_2);
			SetGenSuiPetUp(pUser_2);
			TransportUser(pUser_2, sId, pX, pY, 0);
		}
	}
}

void CFight::RecoverGroupMaxHp(uint8 group)
{
	if(group > EGT_GROUP2)
		return;
	for(uint8 j=0; j < m_groupUser[group].size(); j++)
	{
		CUser *pU = m_groupUser[group][j].get();
		if(pU != NULL)
		{
			pU->RecoveryAllPetHp();
		}
	}
}

void CFight::ResetGroupFightHp(uint8 group)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(group == EGT_GROUP2)
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}
	
	for(int pos=begin;pos <= end;pos++)
	{
		SPet *pPet = GetPet(pos);
		if(pPet != NULL)
		{
			CUser *pOwner = GetUserInFight(m_members[pos-1].petOwner, group);
			if(pOwner != NULL)
			{
				pPet->hp = m_members[pos-1].hp;
				pOwner->SendPetUpdateInfo(pPet->id, EUUT_HP);
			}
		}
	}
}

void CFight::KunLunShanFightEnd()
{
	// 单人
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId < KUN_LUN_SHAN_SCENE_ID || curSrcId >= KUN_LUN_SHAN_SCENE_ID+30)
		return;
	if(m_type != EFTKunLunShan)
		return;

	CUser *pUser_1 = NULL;
	CUser *pUser_2 = NULL;
	SMonsterInst *pMonster = NULL;
	int visableId = 0;
	bool group1_AllDie = true;
	bool group2_AllDie = true;
	for(uint8 pos = 1; pos <= GROUP2_BEGIN; pos++)
	{
		if(IsAlive(pos))
			group1_AllDie = false;
		
		SMonsterInst *pM = GetMonster(pos);
		if(pM != NULL)
		{
			visableId = pM->visableId;
			pMonster = pM;
		}
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pUser_1 = pUser;
		}
	}
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
			group2_AllDie = false;
		
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pUser_2 = pUser;
		}
	}

	char buf[256];
	if(visableId != 0)	// 遇怪
	{
		if(group1_AllDie && !group2_AllDie)	// 胜利
		{
			if(pMonster == NULL)
				return;
			m_pScene->DelVisibleMonster(visableId);

			uint8 level = pUser_2->GetLevel();
			int itemId = 2538;
			int itemNum = 0;
			double expRatio = 0.0f;
			int killMonsterNum = pUser_2->GetExtData16(33)+1;
			pUser_2->SetExtData16(33,killMonsterNum);
			KunLunShan_UpdateRoleMsg(pUser_2,3,killMonsterNum);

			CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
			if(killMonsterNum == 6)
			{
				expRatio = 3.0 / 14;
				itemNum = 6;
				KunLunShan_UpdateRoleMsg(pUser_2,5,0,3);
			}
			else if(killMonsterNum == 3)
			{
				expRatio = 2.0 / 14;
				itemNum = 4;
				KunLunShan_UpdateRoleMsg(pUser_2,5,0,2);
			}
			else if(killMonsterNum == 1)
			{
				expRatio = 2.0 / 14;
				itemNum = 2;
				KunLunShan_UpdateRoleMsg(pUser_2,5,0,1);
			}
			if(InDoubleItemNumHuoDong())
				itemNum *= 2;

			if(killMonsterNum == 1 || killMonsterNum == 3 || killMonsterNum == 6)
			{
				int64 exp = expManager.GetHuoDongExp(12,level,expRatio);
				pUser_2->AddBangDingPackage(itemId,itemNum);
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_517,killMonsterNum,GetItemName(itemId),itemNum);
				SendSysInfoFightEnd(pUser_2,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				pUser_2->AddExp(exp, true, true);
			}
			else
			{
				int64 exp = level*level;
				pUser_2->AddExp(exp, true, true);
			}
			SendFightReward(pUser_2);
			SingletonCHDExchangeManager::instance().DropExchangeItem(pUser_2, EEHDT_KunLunShan);
			SingletonCHDExchangeManager::instance().DropHDItem(pUser_2, EEHDT_KunLunShan);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pUser_2, EEHDT_KunLunShan);

			// 保持当前血量
			ResetGroupFightHp(EGT_GROUP2);
		}
		else	// 失败
		{
			if(m_pScene)
			{
				SVisibleMonsterBoss monster;
				m_pScene->FindVisibleMonsterBoss(visableId,monster,0);

				if(pUser_2 == NULL)
					return;
				uint16 x=0,y=0;
				if(m_pScene->GetCanWalkPos(x,y))
				{
					pUser_2->SetPos(x,y);
					SyncUserScenePos(pUser_2,x,y,0);
				}
			}
			RecoverGroupMaxHp(EGT_GROUP2);
		}
	}
	else	// 遇人
	{
		CUser *pUserAlive = NULL;
		CUser *pUserDie = NULL;
		uint8 winGroup = EGT_GROUP1;
		uint8 failedGroup = EGT_GROUP2;
		if(group1_AllDie && !group2_AllDie)	// group2胜利
		{
			pUserAlive = pUser_2;
			pUserDie = pUser_1;
			winGroup = EGT_GROUP2;
			failedGroup = EGT_GROUP1;
		}
		else if(!group1_AllDie && group2_AllDie)	// group1胜利
		{
			pUserAlive = pUser_1;
			pUserDie = pUser_2;
			winGroup = EGT_GROUP1;
			failedGroup = EGT_GROUP2;
		}
		else
		{
			return;
		}
		if(pUserAlive == NULL || pUserDie == NULL)
			return;
		uint16 continueWinNum = 0;
		if(pUserAlive != NULL)
		{
			continueWinNum= pUserAlive->GetExtData16(43)+1;
			pUserAlive->SetExtData16(31,pUserAlive->GetExtData16(31)+3);
			pUserAlive->SetExtData16(43,continueWinNum);
			KunLunShan_UpdateRoleMsg(pUserAlive,1,pUserAlive->GetExtData16(31));
			AddKunLunShanPaiHangScore(pUserAlive);
			if(continueWinNum == 5)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_518,ROLE_NAME_COLOR,pUserAlive->GetName());
				SysInfoToAllUser(buf,true);
			}
			else if(continueWinNum == 10)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_519,ROLE_NAME_COLOR,pUserAlive->GetName());
				SysInfoToAllUser(buf,true);
			}

			int itemId = 2538;
			int itemNum = 0;
			double expRatio = 0.0f;
			int killNum = pUserAlive->GetExtData16(32)+1;	// 杀人数
			pUserAlive->SetExtData16(32,killNum);
			KunLunShan_UpdateRoleMsg(pUserAlive,2,killNum);
			
			CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
			if(killNum == 7)
			{
				expRatio = 3.0 / 14;
				itemNum = 8;
				KunLunShan_UpdateRoleMsg(pUserAlive,4,0,3);
			}
			else if(killNum == 4)
			{
				expRatio = 2.0 / 14;
				itemNum = 4;
				KunLunShan_UpdateRoleMsg(pUserAlive,4,0,2);
			}
			else if(killNum == 1)
			{
				expRatio = 2.0 / 14;
				itemNum = 2;
				KunLunShan_UpdateRoleMsg(pUserAlive,4,0,1);
			}
			if(InDoubleItemNumHuoDong())
				itemNum *= 2;
			
			if(killNum == 1 || killNum == 4 || killNum == 7)
			{
				int64 exp = expManager.GetHuoDongExp(12,pUserAlive->GetLevel(),expRatio);
				pUserAlive->AddBangDingPackage(itemId,itemNum);
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_522,killNum,GetItemName(itemId),itemNum);
				SendSysInfoFightEnd(pUserAlive,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				pUserAlive->AddExp(exp, true, true);
			}

			// 保持当前血量
			ResetGroupFightHp(winGroup);
		}

		if(pUserDie != NULL)
		{
			continueWinNum = pUserDie->GetExtData16(43);
			pUserDie->SetExtData16(31,pUserDie->GetExtData16(31)+1);
			pUserDie->SetExtData16(43,0);
			KunLunShan_UpdateRoleMsg(pUserDie,1,pUserDie->GetExtData16(31));
			AddKunLunShanPaiHangScore(pUserDie);
			if(pUserAlive != NULL)
			{
				if(continueWinNum >= 10)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_520,ROLE_NAME_COLOR,pUserAlive->GetName(),ROLE_NAME_COLOR,pUserDie->GetName());
					SysInfoToAllUser(buf,true);
				}
				else if(continueWinNum >= 5)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_521,ROLE_NAME_COLOR,pUserAlive->GetName(),ROLE_NAME_COLOR,pUserDie->GetName());
					SysInfoToAllUser(buf,true);
				}
			}

			if(m_pScene && pUserDie != NULL)
			{
				uint16 x=0,y=0;
				if(m_pScene->GetCanWalkPos(x,y))
				{
					pUserDie->SetPos(x,y);
					SyncUserScenePos(pUserDie,x,y,0);
				}
			}
			RecoverGroupMaxHp(failedGroup);
		}
	}

	if (CSceneManager::IsAfterActivityTime(SOT_Kunlunshan))
	{
		if(pUser_1 != NULL && pUser_1->GetFightId() == 0)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			pUser_1->GetEnterPos(sId,pX,pY);
			SetQiPetUp(pUser_1);
			TransportUser(pUser_1, sId, pX, pY, 0);
		}
		if(pUser_2 != NULL && pUser_2->GetFightId() == 0)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			pUser_2->GetEnterPos(sId,pX,pY);
			SetQiPetUp(pUser_2);
			TransportUser(pUser_2, sId, pX, pY, 0);
		}
	}
}

void CFight::KuaFu1V1FightEnd()
{
	if(m_type != EFT_KuaFu_1V1)
		return;
	if(m_pScene == NULL)
		return;

	SFightResultData result;
	GetPVP_FightResult(result);
	if(result.pLeader_1 == NULL || result.pLeader_2 == NULL)
		return;

	int timeIdx = GetKuaFu1V1FinalsTimeIndex();
	int roomIdx = m_pScene->GetId() - KUA_FU_1V1_SCENE_FB_BEGIN + 1;
	string winnerName;
	SKuaFu1V1UserData player1;
	SKuaFu1V1UserData player2;
	GetKuaFu1V1FightPlayers(timeIdx,roomIdx,player1,player2);

	if(result.winGroup == 1 || (result.winGroup != 1 && result.winGroup != 2 && player1.data.zhandouli >= player2.data.zhandouli))
	{
		AddKuaFu1V1PlayerWinNum(timeIdx,player1.data.role_id);
		player1.data.winNum++;
		winnerName = player1.data.name;
//		if(result.pLeader_1 != NULL)
//			SendSysInfoFightEnd(result.pLeader_1,MakeStringColor(LANGUAGE_SSJ_0075,TIPS_WARNING_COLOR).c_str());
//		if(result.pLeader_2 != NULL)
//			SendSysInfoFightEnd(result.pLeader_2,MakeStringColor(LANGUAGE_SSJ_0512,TIPS_FAILURE_COLOR).c_str());
	}
	else
	{
		AddKuaFu1V1PlayerWinNum(timeIdx,player2.data.role_id);
		player2.data.winNum++;
		winnerName = player2.data.name;
//		if(result.pLeader_2 != NULL)
//			SendSysInfoFightEnd(result.pLeader_2,MakeStringColor(LANGUAGE_SSJ_0075,TIPS_WARNING_COLOR).c_str());
//		if(result.pLeader_1 != NULL)
//			SendSysInfoFightEnd(result.pLeader_1,MakeStringColor(LANGUAGE_SSJ_0512,TIPS_FAILURE_COLOR).c_str());
	}
	
	if(player1.data.winNum >= 2 || player2.data.winNum >= 2)	// 结束本场次
	{
		int winnerId = (player1.data.winNum > player2.data.winNum) ? player1.data.role_id : player2.data.role_id;
		int lossId = (player1.data.winNum > player2.data.winNum) ? player2.data.role_id : player1.data.role_id;
		SetKuaFu1V1WinnerData(timeIdx, roomIdx, winnerId);
		int idx = GetKuaFu1V1FinalsTimeIndex();
		if (idx < 5)
		{
			SendSystemMail(winnerId, GetKuaFu1V1MailString(true).c_str());
			SendSystemMail(lossId, GetKuaFu1V1MailString(false).c_str());
		}
		if(m_pScene->GetFBStep() < 6)
		{
			m_pScene->SetFBStep(6);
			m_pScene->m_1V1SceneTime = GetKuaFu1V1TurnStartTime()+15*60;
		}

		if(!winnerName.empty())
		{
			char buf[512];
			if(timeIdx == 4)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0077,ROLE_NAME_COLOR,winnerName.c_str());
				SysInfoToAllUser(buf);
			}
			else if(timeIdx == 5)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0078,ROLE_NAME_COLOR,winnerName.c_str());
				SysInfoToAllUser(buf);
			}
		}
		int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
		if(result.pLeader_1 != NULL)
		{
			result.pLeader_1->GetEnterPos(sId,pX,pY);
			TransportUser(result.pLeader_1,sId,pX,pY,0);
		}
		if(result.pLeader_2 != NULL)
		{
			result.pLeader_2->GetEnterPos(sId,pX,pY);
			TransportUser(result.pLeader_2, sId, pX, pY, 0);
		}
	}
	else
	{
		m_pScene->SetFBStep(m_pScene->GetFBStep()+1);
		m_pScene->m_1V1SceneTime = GetSysTime();
		SendKuaFu1V1SceneLeftTime(m_pScene);
		if(result.pLeader_1 != NULL)
			SendKuaFu1V1SceneScore(result.pLeader_1);
		if(result.pLeader_2 != NULL)
			SendKuaFu1V1SceneScore(result.pLeader_2);
	}
}

void CFight::KunLunShanTeamFightEnd()
{
	if (m_pScene == NULL)
		return;
	if(m_type != EFT_KunLunShanTeam)
		return;
	SFightResultData result;
	GetPVP_FightResult(result);
	if(result.pLeader_2 == NULL)
		return;

	const int ADD_WIN_ROLE_JIFEN = 100;
	const int ADD_LOSE_ROLE_JIFEN = 20;
	const int ADD_WIN_MONSTER_JIFEN = 50;
	const double JIFEN_RATIO[MAX_TEAM_MEMBER] = {1.0,1.1,1.2,1.3,1.4};
	const int MonsterTaskAwardNum[] = {2,4,6};
	const int RoleTaskAwardNum[] = {2,4,8};
	char buf[512];
	if(result.monVisableId != 0)	// 遇怪
	{
		if(result.winGroup == 2)	// 胜利
		{
			if(result.pMonster == NULL)
				return;
			m_pScene->DelVisibleMonster(result.monVisableId);
			
			for(int i=0;i < result.num_2;i++)
			{
				int itemId = 0;
				int itemNum = 0;
				int completeIdx = 0;
				int killMonsterNum = result.pHots_2[i]->GetExtData16(57)+1;
				result.pHots_2[i]->SetExtData16(57,killMonsterNum);
				KunLunShanTeam_UpdateRoleMsg(result.pHots_2[i],3,killMonsterNum);

				for(int idx=0;idx < TeamKunLunShan_MonsterTaskNum;idx++)
				{
					if(TeamKunLunShan_KillMonsterNum[idx] == killMonsterNum)
					{
						itemId = 2798;
						itemNum = MonsterTaskAwardNum[idx];
						completeIdx = idx+1;
						break;
					}
				}
				
				if(itemId == 0)	// 普通怪
				{

				}
				else	// 完成任务
				{
					result.pHots_2[i]->AddBangDingPackage(itemId,itemNum);
					KunLunShanTeam_UpdateRoleMsg(result.pHots_2[i],5,0,completeIdx);
					snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0044,GetItemName(itemId),itemNum);
					SendSysInfoFightEnd(result.pHots_2[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				}
				int jifen = (int)(ADD_WIN_MONSTER_JIFEN * JIFEN_RATIO[result.num_2-1]);
				result.pHots_2[i]->SetExtData32(292,result.pHots_2[i]->GetExtData32(292)+jifen);	// 积分

				if(fabs(JIFEN_RATIO[result.num_2-1] - 1.0) < 0.00001)
				{
					snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0054,jifen);
				}
				else
				{
					jifen = (int)(ADD_WIN_MONSTER_JIFEN * JIFEN_RATIO[0]);
					int addjifen = (int)(ADD_WIN_MONSTER_JIFEN * (JIFEN_RATIO[result.num_2-1] - JIFEN_RATIO[0]));
					snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0055,jifen,addjifen);
				}
				SendSysInfoFightEnd(result.pHots_2[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				AddKunLunShanTeamPaiHangScore(result.pHots_2[i]);
				KunLunShanTeam_UpdateRoleMsg(result.pHots_2[i],1,result.pHots_2[i]->GetExtData32(292));
			}

			// 保持当前血量
			ResetGroupFightHp(EGT_GROUP2);
		}
		else	// 失败
		{
			if(m_pScene)
			{
				SVisibleMonsterBoss monster;
				m_pScene->FindVisibleMonsterBoss(result.monVisableId,monster,0);

				uint16 x=0,y=0;
				if(!m_pScene->GetCanWalkPos(x,y))
					return;
				if(x == 0 || y == 0)
					return;
				for(int i=0;i < result.num_2;i++)
				{
					result.pHots_2[i]->SetPos(x,y);
					SyncUserScenePos(result.pHots_2[i],x,y,0);
				}
			}
			RecoverGroupMaxHp(EGT_GROUP2);
		}
	}
	else	// 遇人
	{
		CUser **pWin = NULL;
		CUser **pLose = NULL;
		CUser *pLoseHead = NULL;
		int loseGroup = EGT_GROUP1;
		int winGroup = EGT_GROUP2;
		int winNum = 0;
		int loseNum = 0;
		if(result.winGroup == 2)	// group2胜利
		{
			pWin = &result.pHots_2[0];
			winNum = result.num_2;
			pLose = &result.pHots_1[0];
			loseNum = result.num_1;
			pLoseHead = result.pLeader_1;
			loseGroup = EGT_GROUP1;
			winGroup = EGT_GROUP2;
		}
		else	// group1胜利
		{
			pWin = &result.pHots_1[0];
			winNum = result.num_1;
			pLose = &result.pHots_2[0];
			loseNum = result.num_2;
			pLoseHead = result.pLeader_2;
			loseGroup = EGT_GROUP2;
			winGroup = EGT_GROUP1;
		}
		if(pWin == NULL || pLose == NULL || pLoseHead == NULL)
			return;

		for(int i=0;i < winNum;i++)
		{
			int jifen = ADD_WIN_ROLE_JIFEN*JIFEN_RATIO[winNum-1];
			uint16 continueWinNum = pWin[i]->GetExtData16(55)+1;
			pWin[i]->SetExtData32(292,pWin[i]->GetExtData32(292)+jifen);	// 积分
			pWin[i]->SetExtData16(55,continueWinNum);
			KunLunShanTeam_UpdateRoleMsg(pWin[i],1,pWin[i]->GetExtData32(292));
			AddKunLunShanTeamPaiHangScore(pWin[i]);

			int itemId = 0;
			int itemNum = 0;
			int completeIdx = 0;
			int killRoleNum = pWin[i]->GetExtData16(56)+1;
			pWin[i]->SetExtData16(56,killRoleNum);
			KunLunShanTeam_UpdateRoleMsg(pWin[i],2,killRoleNum);

			for(int idx=0;idx < TeamKunLunShan_EnemyTaskNum;idx++)
			{
				if(TeamKunLunShan_KillEnemyNum[idx] == killRoleNum)
				{
					itemId = 2798;
					itemNum = RoleTaskAwardNum[idx];
					completeIdx = idx+1;
					break;
				}
			}
				
			if(itemId != 0)	// 完成任务
			{
				pWin[i]->AddBangDingPackage(itemId,itemNum);
				KunLunShanTeam_UpdateRoleMsg(pWin[i],4,0,completeIdx);
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0044,GetItemName(itemId),itemNum);
				SendSysInfoFightEnd(pWin[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}

			if(fabs(JIFEN_RATIO[winNum-1] - 1.0) < 0.00001)
			{
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0054,jifen);
			}
			else
			{
				jifen = (int)(ADD_WIN_ROLE_JIFEN * JIFEN_RATIO[0]);
				int addjifen = (int)(ADD_WIN_ROLE_JIFEN * (JIFEN_RATIO[winNum-1] - JIFEN_RATIO[0]));
				snprintf(buf,sizeof(buf)-1,LANGUAGE_SSJ_0055,jifen,addjifen);
			}
			SendSysInfoFightEnd(pWin[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		uint16 x=0,y=0;
		if(!m_pScene->GetCanWalkPos(x,y))
			return;
		if(x == 0 || y == 0)
			return;
		for(int i=0;i < loseNum;i++)
		{
			pLose[i]->SetPos(x,y);
			pLose[i]->SetExtData32(292,pLose[i]->GetExtData32(292)+(int)(ADD_LOSE_ROLE_JIFEN*JIFEN_RATIO[winNum-1]));	// 积分
			pLose[i]->SetExtData16(55,0);
			KunLunShanTeam_UpdateRoleMsg(pLose[i],1,pLose[i]->GetExtData32(292));
			AddKunLunShanTeamPaiHangScore(pLose[i]);
			SyncUserScenePos(pLose[i],x,y,0);
		}
		RecoverGroupMaxHp(loseGroup);
		ResetGroupFightHp(winGroup);
	}

	if(!InFuncionLevelTime(SOT_KuaFuLunDao))
	{
		if(result.pLeader_1 != NULL && result.pLeader_1->GetFightId() == 0 && result.pLeader_1->GetSrcSceneId() == KUN_LUN_SHAN_TEAM_SCENE_ID)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			result.pLeader_1->GetEnterPos(sId,pX,pY);
			SetQiPetUp(result.pLeader_1);
			TransportUser(result.pLeader_1,sId,pX,pY,0);
		}
		if(result.pLeader_2 != NULL && result.pLeader_2->GetFightId() == 0 && result.pLeader_2->GetSrcSceneId() == KUN_LUN_SHAN_TEAM_SCENE_ID)
		{
			int sId = EXIT_FB_SCENE_ID, pX = EXIT_FB_SCENE_X, pY = EXIT_FB_SCENE_Y;
			result.pLeader_2->GetEnterPos(sId,pX,pY);
			SetQiPetUp(result.pLeader_2);
			TransportUser(result.pLeader_2,sId,pX,pY,0);
		}
	}
}

void CFight::TongTianTaFightEnd()	// 通天塔
{
	if(m_type != EFTTongTianTa)
		return;

	const int MAX_Floor_Num = TONG_TIAN_TA_FLOOR_NUM;
	CUser *pUserSrc = GetGroupHead(EGT_GROUP2);
	if(pUserSrc == NULL)
		return;
	int fubenIndex = pUserSrc->GetExtData16(51);
	bool win = true;
	for(uint8 pos = 1; pos <= GROUP2_BEGIN; pos++)
	{
		SMonsterInst *pMonster = GetMonster(pos);
		if(pMonster != NULL)
		{
			if(IsAlive(pos))
				win = false;
		}
	}

	if (win)
	{
		char buf[256];
		if(fubenIndex <= MAX_Floor_Num)
		{
			if(pUserSrc->GetExtData16(52) < fubenIndex+1)	// 首次通关
			{
				pUserSrc->SetExtData16(52,fubenIndex+1);
				sTowerRewardManager.SendFirstReward(pUserSrc, fubenIndex);
				//SendTongTianTaFirstCompleteInfo(pUserSrc,(uint16)fubenIndex,2370,firstAwardId[fubenIndex-1]);	// 首次通关界面
				//pUserSrc->AddBangDingPackage(2370,firstAwardId[fubenIndex-1]);	// 神将进化丹

				// 称号添加
//				if(fubenIndex >= 20)
//					pUser9->AddTitle(E2UT_ZHENYAOSHIZHE);
//				if(fubenIndex >= 40)
//					pUser9->AddTitle(E2UT_XIANGYAOZUNZHE);
				if(fubenIndex >= 80)
					pUserSrc->AddTitle(E2UT_ZHENYAODIHAO);
				if(fubenIndex >= 120)
					pUserSrc->AddTitle(E2UT_ZHENYAOYINGHAO);

				if((fubenIndex >= 25) && (!pUserSrc->HaveSGBitSet(107)))
					pUserSrc->FinishStageGoalSection(1,4); // 通关通天塔25层
				if((fubenIndex >= 50) && (!pUserSrc->HaveSGBitSet(117)))
					pUserSrc->FinishStageGoalSection(2,4); // 通关通天塔50层
				if((fubenIndex >= 90) && (!pUserSrc->HaveSGBitSet(127)))
					pUserSrc->FinishStageGoalSection(3,4); // 通关通天塔30层

				// 更新通天塔任务
				SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUserSrc, EMISS_DC_33, 1, fubenIndex+1);
			}
			else
			{
				sTowerRewardManager.SendNormalReward(pUserSrc, fubenIndex);
			}
			pUserSrc->SetExtData16(51,fubenIndex+1); // 设置当前玩家所在层数（没有打过）
		}
		else
		{
			return;
		}

		uint8 bazhuIndex = 0xff;
		uint8 bazhuNum = sizeof(tongTianTaBaZhuFloor)/sizeof(tongTianTaBaZhuFloor[0]);
		for(uint8 i=0;i < bazhuNum;i++)
		{
			if(fubenIndex == tongTianTaBaZhuFloor[i])
			{
				char temp[256];
				snprintf(temp, sizeof(temp), LANGUAGE_TRANSFORM_523, ROLE_NAME_COLOR, pUserSrc->GetName(), ROLE_NAME_COLOR, fubenIndex);
				SysInfoToAllUser(temp,true);
				bazhuIndex = i;
			}
		}
		SendTongTianTaInfo(pUserSrc);

		// 通关设置霸主
		if(bazhuIndex != 0xff)
		{
			boost::recursive_mutex::scoped_lock lk(tongTianTa_mutex);
			if(tongTianTaBaZhuData.size() >= bazhuNum)
			{
				int selfPos = 0xff;
				for(uint8 i=0;i < bazhuNum;i++)
				{
					if(tongTianTaBaZhuData[i] == pUserSrc->GetRoleId())
					{
						selfPos = i;
						break;
					}
				}

				bool isSuccess = false;
				if(selfPos == 0xff)		// 自己不是霸主
				{
					if(tongTianTaBaZhuData[bazhuIndex] == 0)
					{
						tongTianTaBaZhuData[bazhuIndex] = pUserSrc->GetRoleId();
						isSuccess = true;
					}
				}
				else
				{
					if(tongTianTaBaZhuData[bazhuIndex] == 0)
					{
						if(selfPos < bazhuIndex)
						{
							tongTianTaBaZhuData[selfPos] = 0;
							tongTianTaBaZhuData[bazhuIndex] = pUserSrc->GetRoleId();
							isSuccess = true;
						}
					}
				}
				if(isSuccess)
				{
					snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_524,fubenIndex);
					SendSystemMail(pUserSrc->GetRoleId(),buf);
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0037, pUserSrc->GetName(), fubenIndex);
					SysInfoToAllUser(buf);
				}
			}
		}
	}
	else	// 失败
	{
//		pUser9->SetExtData8(61,pUser9->GetExtData8(61)+1);
//		SendTongTianTaInfo(pUser9);
//		pUser9->CheckMissionHuoYueDu();
	}
}

void CFight::KuaFuZhuoGuiFightEnd()
{
/*
	if(m_type != EFT_KuaFu_ZhuoGui)
		return;

	const int TASK_NUM_LIMIT = 10;
	bool win = true;
	CUser *pHead = NULL;
	CUser *pHots[MAX_MEMBER] = {NULL};
	int num = 0;
	GetPVE_FightResult(&pHead,pHots,num,win);
	if(pHead == NULL || num == 0)
		return;

	if(win)
	{
		const char *pMission806 = pHead->GetMission(806);
		if(pMission806 == NULL)
			return;
		char *split[8] = {NULL};
		string monsterName;
		if(SplitLine(split,8,(char *)pMission806) == 8)
			monsterName = split[4];

		const float extraAdd[] = {0.0f,0.0f,0.0f};		// 人数附加奖励比例
		//	 				level,itemId,itemNum,ratio
		const int itemAward[][4] = {{30,851,2,5},{30,2370,2,5},{30,506,2,5},{35,613,2,5},{35,614,2,5},{43,610,2,5},{43,611,1,5},{46,2310,2,5},{52,2251,1,5}};
		char buf[1024];
		for(int i=0;i < num;i++)
		{
			uint16 turn = pHots[i]->GetExtData16(60);
			uint16 idx = pHots[i]->GetExtData16(61)+1;
			int times = turn*TASK_NUM_LIMIT + idx;
			DelNpc(pHots[i],231);
			if(idx >= TASK_NUM_LIMIT)
			{
				turn += 1;
				idx = 0;
				SendYinDaoNPCPos(pHead,KUA_FU_SCENE_ID,-1,-1,229);
			}
			pHots[i]->SetExtData16(60,turn);
			pHots[i]->SetExtData16(61,idx);
			if(idx > 0)
				AddKuaFuZhuoGuiMiss(pHots[i]);

//			SaveDate(pHots[i],14,1);

			// 发放奖励
			int level = pHots[i]->GetLevel();
			int totolExp= 0;
			int totolMoney = 0;
			if(times <= 30)
			{
				if(level < 40)
					totolExp = 40*2800 - (40-level)*400;
				else
					totolExp = level*2800;
				totolMoney = 800;
			}
			else if(times <= 60)
			{
				if(level < 40)
					totolExp = 40*1400 - (40-level)*200;
				else
					totolExp = level*1400;
				totolMoney = 400;
			}
			else if(times <= 100)
			{
				if(level < 40)
					totolExp = 40*600 - (40-level)*100;
				else
					totolExp = level*600;
				totolMoney = 200;
			}
			else
			{
				totolExp = 2*level*level;
				totolMoney = 100;
			}
			totolExp /= 2;
			totolMoney /= 2;

			int addExp = totolExp * (1 + extraAdd[num-1]);		// 每次
			int addMoney = totolMoney * (1 + extraAdd[num-1]);
			pHots[i]->AddMoney(addMoney);
			
			if(idx < TASK_NUM_LIMIT)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_527,monsterName.c_str());
				SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				//snprintf(buf,sizeof(buf),"获得%d点经验，%d金钱",addExp,addMoney);
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_528,GetMissionName(806));
				SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
				//snprintf(buf,sizeof(buf),"获得%d点经验，%d金钱",addExp,addMoney);
			}
			
			pHots[i]->AddExp(addExp, true, true);
			// 掉落低级仙羽
			if(times%10 == 0 && times > 0 && times <= 100)
			{
//				pHots[i]->AddBangDingPackage(2538,1);
				const int BossAward1[] = {2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715};
				const int BossAward2[] = {2596,2606,2616,2626,2636,2646,2656,2666,2676,2686,2696,2706,2716};
				const int BossAward3[] = {2597,2607,2617,2627,2637,2647,2657,2667,2677,2687,2697,2707,2717};
				int award1 = BossAward1[Random(1,sizeof(BossAward1)/sizeof(BossAward1[0]))-1];
				int award2 = BossAward2[Random(1,sizeof(BossAward2)/sizeof(BossAward2[0]))-1];
				int award3 = BossAward3[Random(1,sizeof(BossAward3)/sizeof(BossAward3[0]))-1];
				
				pHots[i]->AddBangDingPackage(award1,1);
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_529,addMoney,GetItemName(award1));
				char tempBuf[256];
				if(Random(1,1000) <= 100)
				{
					pHots[i]->AddBangDingPackage(award2,1);
					snprintf(tempBuf,sizeof(tempBuf),LANGUAGE_TRANSFORM_531,GetItemName(award2),1);
					strcat(buf,tempBuf);
				}
				if(Random(1,1000) <= 50)
				{
					pHots[i]->AddBangDingPackage(award3,1);
					snprintf(tempBuf,sizeof(tempBuf),LANGUAGE_TRANSFORM_531,GetItemName(award3),1);
					strcat(buf,tempBuf);
				}
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_530,addMoney);
			}
//			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_ZhuoGui);
//			SingletonCHDExchangeManager::instance().DropFestivalItem(pHots[i],EEHDT_ZhuoGui);
//			SingletonCHDExchangeManager::instance().DropHuanHaoLiItem(pHots[i],EEHDT_ZhuoGui);

			// 额外物品奖励
			if(idx == 0)	// boss
			{
				int r = Random(1,100);
				int sum = 0;
				for(uint8 k=0;k < sizeof(itemAward)/sizeof(itemAward[0]);k++)
				{
					if(level < itemAward[k][0])
						break;
					sum += itemAward[k][3];
					if(r <= sum)
					{
						pHots[i]->AddBangDingPackage(itemAward[k][1],itemAward[k][2]);
						char temp[64];
						snprintf(temp,sizeof(temp),LANGUAGE_TRANSFORM_531,GetItemName(itemAward[k][1]),itemAward[k][2]);
						strcat(buf,temp);
						break;
					}
				}
			}
			SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			pHots[i]->GetTransFormDrop();//掉落变身卡
		}

//		ChangeClientGuaJiState(pHead,2);
		uint16 idx = pHead->GetExtData16(61);
		if(idx > 0)
			SendYinDaoNPCPos(pHead,KUA_FU_SCENE_ID,-1,-1,231);
		else
			SendYinDaoNPCPos(pHead,KUA_FU_SCENE_ID,-1,-1,229);
	}
	else	//  死亡
	{

	}
*/
}

void CFight::ZhuoGuiFightEnd()
{
	if(m_type != EFTZhuoGui)
		return;

	bool win = true;
	CUser *pHead = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	GetPVE_FightResult(&pHead,pHots,num,win);
	if(pHead == NULL || num == 0)
		return;

	if(win)
	{
		if(!pHead->HaveCMission(MISSION_ID_ZhuoGui))
			return;
		
		vector<int> ints;
		vector<string> strs;
		pHead->GetCMissionInts(MISSION_ID_ZhuoGui,ints);
		pHead->GetCMissionStrs(MISSION_ID_ZhuoGui,strs);

		const char *nextInts = NULL;
		const char *nextStrs = NULL;
		int sid=0,x=0,y=0;
		int taskIndex = 0;
		int curMonId = 0;
		string monName;
		if(ints.size() >= 5 && strs.size() >= 1)
		{
			taskIndex = pHead->GetExtData16(50) % TASK_NUM_LIMIT + 1;
			curMonId = ints[3];
			monName = strs[0];
			//if(taskIndex < TASK_NUM_LIMIT)
			{
				CCallScript *pScript = FindScript(184);
				if(pScript == NULL)
					return;
				int nextMonId = 0;
				pScript->Call("GetNextZhuoGuoMissInfo","uii>ssiii",pHead,taskIndex,curMonId,&nextInts,&nextStrs,&nextMonId,&sid,&x,&y);
				if(nextInts == NULL || nextStrs == NULL || nextMonId == 0)
					return;
				curMonId = nextMonId;
			}
		}

		//bool bContinue = taskIndex != TASK_NUM_LIMIT; // 队长次数不是30次就可以继续抓
		const float extraAdd[] = {0.0f,0.03f,0.06f,0.10f,0.15f};		// 人数附加奖励比例
		char buf[256];
		for(int i=0;i < num;i++)
		{
			uint16 turn = pHots[i]->GetExtData16(48)+1;
			uint16 times = pHots[i]->GetExtData16(50)+1;
			if (times > TASK_MAX_LIMIT)
			{
				continue;
			}
			
			pHots[i]->SetExtData16(50, times);
			if (times % TASK_NUM_LIMIT == 0)
			{
				pHots[i]->SetExtData16(48, turn);
			}
			SaveDate(pHots[i],14,1);

			// 发放奖励
			int level = pHots[i]->GetLevel();
			int totolExp= 0;
			int totolMoney = 0;
			GetZhuoGuiExpAndMoney(times,level,totolExp,totolMoney);

			int addExp = totolExp * (1 + extraAdd[num-1]);		// 每次
			int addMoney = totolMoney * (1 + extraAdd[num-1]);
			if (num > 1 && pHead == pHots[i])
			{// 队长额外奖励10%
				addExp += totolExp * 0.05;
				addMoney += totolMoney * 0.05;
			}
			pHots[i]->AddMoney(addMoney);
			
			if(taskIndex < TASK_NUM_LIMIT)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_527,monName.c_str());
				SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}
			else
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_528,GetCMissionName(MISSION_ID_ZhuoGui));
				SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			}
			
			pHots[i]->AddExp(addExp, true, true);
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_530,addMoney);
			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_ZhuoGui);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_ZhuoGui);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_ZhuoGui);

			SendSysInfoFightEnd(pHots[i],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
			pHots[i]->GetTransFormDrop();//掉落变身卡
			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_59, 1, MISSION_ID_ZhuoGui);
		}

		// 更新任务
		CScene *pScene = pHead->GetScene();
		if (pScene == NULL)
			return;
		CUserTeam* team = pScene->GetTeam(pHead->GetTeam());
		if (team != NULL)
		{
			team->UpdateMission(pScene, MISSION_ID_ZhuoGui, nextInts, nextStrs);
		}

		ChangeClientGuaJiState(pHead,2);
		if(taskIndex < TASK_NUM_LIMIT)
			SendYinDaoMonsterPos(pHead,sid,-1,-1,curMonId);
		else
			SendYinDaoNPCPos(pHead,11,-1,-1,184);
	}
	else	//  死亡
	{
		if(pHead != NULL)
			TransportUser(pHead,EXIT_FB_SCENE_ID,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,0);
	}
}

// 英勇试炼战斗结束回调
void CFight::ShiLianFightEnd()
{
	if(m_type != EFTShiLian)
		return;

	// group1 挑战者， group2 被挑战者
	SFightResultData res;
	GetPVP_FightResult(res);

	bool win = (res.winGroup == 1) ? true : false;
	CUser *pUser = res.pLeader_1;
	CUser *pRobot = res.pLeader_2;
	if(pUser == NULL || pRobot == NULL)
		return;

	// 掉落奖励
	if(win)
	{
		int floor = pUser->GetExtData8(136);
		DelDynamicNpcWithIndex(pUser,181,floor+1);
		DelDynamicNpcWithIndex(pUser,182,floor+1);
		DelDynamicNpcWithIndex(pUser,183,floor+1);
		DelDynamicNpcWithIndex(pUser,241,floor+1);
		DelDynamicNpcWithIndex(pUser,242,floor+1);
		DelDynamicNpcWithIndex(pUser,243,floor+1);

//		CScene *pScene = pUser->GetScene();
//		if(pScene == NULL)
//			return;
/*
		const int boxPos[][2] = {{729,413},{990,403},{1195,475},{1222,622},{1074,727}};
		int npcId = 179;	// 未开启的宝箱
		char name[128];
		for(uint8 i=1;i <= 5;i++)
		{
			int pic = 0;
			if(floor < 5)
			{
				pic = 61;
				snprintf(name,sizeof(name),LANGUAGE_TRANSFORM_781,(int)(floor+1));
			}
			else if(floor < 10)
			{
				pic = 63;
				snprintf(name,sizeof(name),LANGUAGE_TRANSFORM_782,(int)(floor+1));
			}
			else
			{
				pic = 65;
				snprintf(name,sizeof(name),LANGUAGE_TRANSFORM_783,(int)(floor+1));
			}
			pScene->AddNpcWithIndex(npcId,pic,boxPos[i-1][0],boxPos[i-1][1],2,floor*10+i,name);
		}
*/
		pUser->SetExtData32(453, 0);
		pUser->MatchYingYongRobot(floor + 1);
		pUser->SetExtData8(136,floor+1);
		pUser->SetExtData32(109,pRobot->GetRoleId());
		pUser->SendShiLianGetAwardPanel();

		SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,EEHDT_ShiLian);
		SingletonCHDExchangeManager::instance().DropHDItem(pUser,EEHDT_ShiLian);
		//SingletonCHDExchangeManager::instance().DropHDItem_New(pUser,EEHDT_ShiLian);
		if (pUser->GetExtData8(604) < floor + 1)
		{
			// 记录的层数比较小才更新
			SingletonCMissionManager::instance().UpdateDCMissionComplate(pUser, EMISS_DC_49); // TODO
		}
	}
	// 更新试炼任务
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_36); // TODO
}

void CFight::TreasureFightEnd()
{
	if (m_pScene == NULL)
		return;
	if(m_type != EFTTreasure)
		return;

	bool win = true;
	CUser *pHead = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	GetPVE_FightResult(&pHead,pHots,num,win);
	if(pHead == NULL || num == 0)
		return;

	int visableId = m_visibleMonsterId;

	// 掉落奖励
	if(win)
	{
		m_pScene->DelVisibleMonster(visableId);
//		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();

		char info[128];
		for(int i=0;i<num;i++)
		{
			int num614 = 4;
			if(InDoubleItemNumHuoDong())
				num614 *= 2;
			pHots[i]->AddBangDingPackage(614,num614);
			snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_532,GetItemName(614),num614);
			SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());

			int64 addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(25,pHots[i]->GetLevel(),1.0/5);
			if(addExp > 0)
			{
				pHots[i]->AddExp(addExp, true, true);
				//snprintf(info,sizeof(info),"获得经验%d",(int)addExp);
				//SendSysInfo(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
			}
		}
	}
	else
	{
//		if(teamloader != NULL)
//			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}
}

void CFight::DailyBossFightEnd()
{
	if(m_type != EFTDailyBoss)
		return;

	SFightResultData res;
	GetPVP_FightResult(res);

	int index = (int)GetVisibleMonsterId();
	int win = 0;	// 0 失败1胜利
	if(res.winGroup == 2)	// group2 人
		win = 1;
	for(int i = 0;i < res.num_2;i++)
	{
		CCallScript *pScript = GetScript30000();
		if(pScript != NULL)
		{
			res.pHots_2[i]->SetCallScript(pScript->GetScriptId());
			pScript->Call("RingTask_FightEnd","uiii",res.pHots_2[i],win,m_fightTurn,index);
		}

		if(win)
		{
			// 更新日常挑战boss任务
			int curCnt = res.pHots_2[i]->GetExtData8(145);
			if (curCnt < 255)
			{
				res.pHots_2[i]->SetExtData8(145, curCnt + 1);
			}
			SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(res.pHots_2[i], EMISS_DC_34);
		}
	}

}

void CFight::FengShenFightEnd()
{
	if(m_type != EFT_FengShen)
		return;
	
	SFightResultData res;
	GetPVP_FightResult(res);

	int bossId = (int)GetVisibleMonsterId();
	AwardManager &awardMgr = SingletonAwardManager::instance();
	CSocketServer &sockServer = SingletonSocket::instance();
	CFengShenMgr &bossMgr = SingletonCFengShenMgr::instance();
	SFengShenCfg *pCfg = SingletonCFengShenMgr::instance().GetFengShenBossCfg(bossId);
	if(pCfg == NULL)
		return;
	int star = 1;
	if(m_fightTurn <= 3)
		star = 3;
	else if(m_fightTurn <= 6)
		star = 2;

	int win = 0;	// 0 失败1胜利
	if(res.winGroup == 2)	// group2 人
		win = 1;
	for(int i = 0;i < res.num_2;i++)
	{
		if(win)
		{
			res.pHots_2[i]->SetExtData8(478 + pCfg->index, res.pHots_2[i]->GetExtData8(478 + pCfg->index) + 1);
			int level_reward_id = pCfg->level_reward[star-1];

			CNetMessage msg;
			msg.SetType(PRO_FENGSHEN_SHILIAN);
			msg<<(uint8)3;
			msg<<(uint8)star;
			awardMgr.SendLevelAward(res.pHots_2[i], level_reward_id, &msg);
			sockServer.SendMsg(res.pHots_2[i]->GetSock(),msg);
			
			bossMgr.SendFengShenBossMsg(res.pHots_2[i]);
		}
	}
}


void CFight::GetFightResult(bool &group1_allDie,bool &group2_allDie,CUser **pUser1,CUser **pUser2,SMonsterInst **pMonster,int *visableId)
{
	group1_allDie = true;
	group2_allDie = true;
	if(pUser1 == NULL || pUser2 == NULL)
		return;
	
	for(int pos = 1;pos <= GROUP2_BEGIN; pos++)
	{
		if(IsAlive(pos))
			group1_allDie = false;

		if(pMonster != NULL)
		{
			SMonsterInst *pM = GetMonster(pos);
			if(pM != NULL)
			{
				if(visableId != NULL)
					*visableId = pM->visableId;
				*pMonster = pM;
			}
		}
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			*pUser1 = pUser;
		}
	}
	for(int pos = GROUP2_BEGIN+1;pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
			group2_allDie = false;
		
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			*pUser2 = pUser;
		}
	}
}

// 是否和玩家战斗成功
bool CFight::IsFightWithPlayerWin()
{
	bool win = true;
	CUser *pUserTar = NULL;
	SPet *pPetTar = NULL;
	for(int i = GROUP2_BEGIN+1;i <= MAX_MEMBER; ++i)
	{
		pUserTar = GetUser(i);
		if(pUserTar != NULL)
		{
			if(IsAlive(i))
			{
				win = false;
				break;
			}
			else
				continue;
		}

		pPetTar = GetPet(i);
		if(pPetTar != NULL)
		{
			if(IsAlive(i))
			{
				win = false;
				break;
			}
			else
				continue;
		}
	}
	return win;
}

void CFight::HuSongShenShouEnd()
{
	if(m_type != EFTHuSong)
		return;

	// group1 抢夺者
	// group2 护送者
	SFightResultData res;
	GetPVP_FightResult(res);

	CUser *pRobber = res.pLeader_1;
	CUser *pProtector = res.pLeader_2;

	char buf[256];
	if(res.winGroup == 2)	// 抢夺失败
	{
		if(pRobber != NULL && pProtector != NULL)
		{
			if(pRobber->GetTeam() > 0)
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_533,pRobber->GetName());
			else
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_534,pRobber->GetName());
			SendSysInfoFightEnd(pProtector,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		}
		
		for(uint8 i=0;i < res.num_1;i++)
		{
			snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_535);
			SendSysInfoFightEnd(res.pHots_1[i],MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
		}
	}
	else if(res.winGroup == 1)	// 抢夺成功
	{
		if(pProtector == NULL)
			return;
		int level = 0;
		for(uint8 i = 0;i < res.num_1;i++)
			level += res.pHots_1[i]->GetLevel();
		level /= (int)res.num_1;

		uint8 type = pProtector->InHuSongMission();
		if(type == 1)	// 护送
		{
			vector<int> ints;	//	quality|exp|loseExp|endTime|state
			vector<string> strs;
			if(!pProtector->GetCMissionInts(MISSION_ID_HuSong,ints))
				return;
			if(!pProtector->GetCMissionStrs(MISSION_ID_HuSong,strs))
				return;
			if(ints.size() < 5)
				return;
			const char *pMission = GetCMissionInts(pProtector, MISSION_ID_HuSong);
			if(pMission != NULL)
			{
				int exp = ints[1];
				int loseExp = ints[2];
				exp = GetHuoDongRobExpRatio(exp*0.25,pProtector->GetLevel(),level);
				int realExp = exp;
				if(pProtector->GetVipLevel() >= VIP_PROTECTOR_HUSONG_LEVEL)
					realExp = 0;
				loseExp += realExp;
				ints[2] = loseExp;
				pProtector->UpdateCMission(MISSION_ID_HuSong,ints,strs);
				pProtector->SetExtData8(80,pProtector->GetExtData8(80)+1);
				if(pRobber != NULL)
				{
					if(pProtector->GetVipLevel() >= VIP_PROTECTOR_HUSONG_LEVEL)
						snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0510,VIP_PROTECTOR_HUSONG_LEVEL,pRobber->GetName(),(pRobber->GetTeam() > 0 ? LANGUAGE_SSJ_0511 : ""));
					else
						snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0509,pRobber->GetName(),(pRobber->GetTeam() > 0 ? LANGUAGE_SSJ_0511 : ""),realExp,VIP_PROTECTOR_HUSONG_LEVEL);
				}
				SendSysInfoFightEnd(pProtector,MakeStringColor(buf,TIPS_FAILURE_COLOR).c_str());
				RecoverGroupUnitHp(GROUP2_BEGIN+1,true);	// 恢复护送者气血

				for(uint8 k=0;k < res.num_1;k++)
				{
					if(res.pHots_1[k]->GetExtData8(79) < 5)
					{
						res.pHots_1[k]->SetExtData8(79,res.pHots_1[k]->GetExtData8(79)+1);
						int exp1 = res.pHots_1[k]->AddExp(exp);
						int worldExpPer = GetWorldExpPercent(res.pHots_1[k]->GetLevel());
						if (worldExpPer > 0)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_538,pProtector->GetName(),exp1,worldExpPer,(int)res.pHots_1[k]->GetExtData8(79));
						else
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_539,pProtector->GetName(),exp1,(int)res.pHots_1[k]->GetExtData8(79));
						SendSysInfoFightEnd(res.pHots_1[k],MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
					}
					else
					{
						SendSysInfoFightEnd(res.pHots_1[k],MakeStringColor(LANGUAGE_TRANSFORM_542,TIPS_FAILURE_COLOR).c_str());
					}
				}
			}
		}
		else if(type == 2)	// 押镖
		{


		}
	}
	if(pProtector != NULL)
		pProtector->SetExtData32(101,(uint32)GetSysTime());
	RecoverGroupUnitHp(1,true);	// 恢复抢夺者气血
}

extern int refreshLingQiValue;
void CFight::LingQiJuanXianEnd()
{
	if (m_pScene == NULL)
		return;
	if(m_type != EFTLingQiJuanXian)
		return;

	bool win = true;
	CUser *pHead = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int monsterType = 1;
	GetPVE_FightResult(&pHead,pHots,num,win,&monsterType);

	for(int i=0; i < num;i++)
	{
		if (!pHots[i]->HaveBitSet(303))
			pHots[i]->CheckMissionHuoYueDu();
		pHots[i]->SetBitSet(303);
	}

	int npcIndex = m_visibleMonsterId;
	int npcId = 157;
	if(monsterType == 1)
		npcId = 154;
	else if(monsterType == 2)
		npcId = 155;
	else if(monsterType == 3)
		npcId = 156;

	if(win)
	{
		for(int i = 0;i < num;i++)
		{
			int exp = 0;
			pHots[i]->AddExp(exp, true, true);
			pHots[i]->SetExtData32(400,pHots[i]->GetExtData32(400) + 1);
			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_BP_LingMo);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_BP_LingMo);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_BP_LingMo);
			SendFightReward(pHots[i]);
		}
		m_pScene->DelNpc(npcId,npcIndex);
	}
	else
	{
		for(int i = 0;i < num;i++)
		{
			SendSysInfoFightEnd(pHots[i],MakeStringColor(LANGUAGE_TRANSFORM_552,TIPS_FAILURE_COLOR).c_str());
		}
		m_pScene->SetNPCMonsterFightFlag(npcId,npcIndex,false);
	}
}

void CFight::XunChaShiFightEnd()
{
	if(m_type != EFT_XunChaShi)
		return;

	bool win = true;
	CUser *loader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	GetPVE_FightResult(&loader,pHots,num,win);
	if(loader == NULL || num == 0)
		return;

	if(win)
	{	
		char buf[256];
		uint16 monIndex = m_visibleMonsterId;
		int npcId = GetXunChaShiNpcId(monIndex/6);
		int index = monIndex%6 + 1;
		for(int i = 0;i < num;i++)
		{
			if(!pHots[i]->IsXunChaShiKilled(npcId,index))
			{
				pHots[i]->SetXunChaShiKilled(npcId,index);
				UpdateNpcHeadState(pHots[i],npcId,index,1);
				pHots[i]->SetExtData32(399, pHots[i]->GetExtData32(399) + 1);
				SendFightReward(pHots[i]);
				SaveDate(pHots[i], 31, 1);
			}
			else
			{
				SendSysInfoFightEnd(pHots[i],MakeStringColor(LANGUAGE_TRANSFORM_555,TIPS_WARNING_COLOR).c_str());
			}
		}

		if(loader != NULL)
		{
			bool allKill = true;
			uint32 data = loader->GetExtData32(116);
			for(uint8 i=0;i < 24;i++)
			{
				if((data & (1<<i)) == 0)
				{
					allKill = false;
					break;
				}
			}
			if(allKill)
			{
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_562,ROLE_NAME_COLOR,loader->GetName());
				SysInfoToAllUser(buf,true);
			}
		}
	}
	else
	{
		for(int i = 0;i < num;i++)
			SendSysInfoFightEnd(pHots[i],MakeStringColor(LANGUAGE_TRANSFORM_563,TIPS_FAILURE_COLOR).c_str());
		TransportUser(loader,EXIT_FB_SCENE_ID,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,0);
	}
}

// 日常 神将副本
void CFight::RiChangChongWuFuBenEnd()
{
	if(m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId < COPY_ID_CHONG_WU_1 || curSrcId > COPY_ID_CHONG_WU_4)
		return;

	const int COPY_ID = 1;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);

	// 掉落奖励
	if(win)
	{
		// 给予奖励
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			if(curSrcId >= COPY_ID_CHONG_WU_1 && curSrcId <= COPY_ID_CHONG_WU_3)
				addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(1,pHots[i]->GetLevel(),1.0/FB_FIGHT_COUNT_RI_CHANG_CHONG_WU/15.0);
			else if(curSrcId == COPY_ID_CHONG_WU_4)
				addExp = SingletonHuoDongExpManager::instance().GetHuoDongExp(24,pHots[i]->GetLevel(),1.0/FB_FIGHT_COUNT_RI_CHANG_CHONG_WU);
			if(addExp > 0)
			{
				addExp = pHots[i]->AddExp(addExp, true, true);
				pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+addExp);
			}
			int difficulty = m_pScene->GetPetCopyDifficulty() + 1;
			if (difficulty == 1)
				pHots[i]->SetBitSet(153);
			else if (difficulty == 2)
				pHots[i]->SetBitSet(154);
			else if (difficulty == 3)
				pHots[i]->SetBitSet(155);
			else if (difficulty == 4)
				pHots[i]->SetBitSet(151);
		}
		// 删除怪
		m_pScene->DelVisibleMonster(visableId);
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());
		
		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	// 副本结算
	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			switch (curSrcId)
			{
			case COPY_ID_CHONG_WU_1:
			case COPY_ID_CHONG_WU_3:
				RiChangChongWuFuBenJieSuan(pHots[i]);
				break;

			case COPY_ID_CHONG_WU_2:
				RiChangChongWu_Middle(pHots[i]);
				break;

			case COPY_ID_CHONG_WU_4:
				RiChangChongWu_Tianshu(pHots[i]);
				break;

			default:
				SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
				break;
			}

			if (win)
			{
				// 更新任务
				SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pHots[i], 0); // TODO
				int dc = m_pScene->GetPetCopyDifficulty() + 1;
				UpdateDCMissionComplate(pHots[i], EMISS_DC_8, 1, dc);
			}
		}
	}
}

// 日常 金币副本
void CFight::RiChangJinBiFuBenEnd()
{
	// data32 201:金币
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_MONEY)
		return;

	const int COPY_ID = 3;
	bool win = true;
	CUser *pHots[5] = {0};
	CUser *teamloader = NULL;
	int num = 0;
	int visableId = 0;
	int dieNum = 0; // 战斗死亡次数

	// 统计战斗数据
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		SMonsterInst *pMonster = GetMonster(pos);
		if(pMonster != NULL)
		{
			visableId = pMonster->visableId;
			if(IsAlive(pos))
				win = false;
			continue;
		}
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pHots[num++] = pUser;
			if(pUser->GetTeam() == 0)
				teamloader = pUser;
			else
			{
				if(pUser->GetTeam() == pUser->GetRoleId())
					teamloader = pUser;
			}
			if(!IsAlive(pos))
				++dieNum;
		}
	}

	m_pScene->AddDieCount(dieNum); // 增加副本死亡次数
	int BossFlag = m_visibleMonsterId;	// 1boss 0小怪

	// 0 小怪 1 boss怪掉落
	const int DropMoney[][2] = {{2000,3000},{3000,4000},{4000,5000},{5000,6000}};

	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();

		for(int i=0;i<num;i++)
		{
//			int level = pHots[i]->GetLevel();
			int64 addExp = expManager.GetHuoDongExp(3,pHots[i]->GetLevel(),1.0/FB_FIGHT_COUNT_RI_CHANG_JIN_QIAN/3.0);
			uint8 moneyLv = pHots[i]->GetFBJingbiLevel();
			if(moneyLv == 0)
				moneyLv = 1;
			else if(moneyLv > MAX_FUBEN_LEVEL)
				moneyLv = MAX_FUBEN_LEVEL;

			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+addExp);

			char info[128];
			//snprintf(info,sizeof(info),"获得：经验%lld",addExp);
			//SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());

			int money = 0;
			if(BossFlag == 1)	// boss
				money = DropMoney[moneyLv-1][1] + Random(15,80);
			else	// 小怪
				money = DropMoney[moneyLv-1][0] + Random(15,80);
			pHots[i]->SetExtData32(201,pHots[i]->GetExtData32(201)+money);
			pHots[i]->AddMoney(money);
			snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_564,money);
			SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	// 副本结算
	if(m_pScene->GetVisibleMonsterBossNum() == 0 && curSrcId == COPY_ID_MONEY)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);

			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)16;
			//			经验				金钱
			msg<<(uint32)addExp<<pHots[i]->GetExtData32(201);

//			uint16 numPos = msg.GetDataLen();
			uint8 num = 0;
			msg<<num;
//			if(pHots[i]->AddBaiHuaChip(1))
//			{
//				num++;
//				msg<<(uint16)1099<<(uint8)1;
//				msg.WriteData(numPos,&num,sizeof(num));
//			}
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			if(!pHots[i]->HaveBitSet(195))
			{
				pHots[i]->SetBitSet(195); // 标记 金币副本 是否通关过
			}
			RiChangFuBenCheckStageGoal(pHots[i]);

			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_JinBiFB);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_JinBiFB);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_JinBiFB);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

// 日常 强化副本
void CFight::RiChangQiangHuaFuBenEnd()
{
	// data8 201:851
	// data8 202:852
	// data8 203:502
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_QIANG_HUA)
		return;

	const int COPY_ID = 2;
//	int dieNum = 0; // 战斗死亡次数
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);

//	for(int i=0;i < num;i++)
//	{
//		if(!IsAlive(pHots[i]))
//			++dieNum;
//	}
//	m_pScene->AddDieCount(dieNum); // 增加副本死亡次数

	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(COPY_ID);
		if(!pfuBen)
			return;
		for(int i=0;i<num;i++)
		{
			uint8 qianghuaLv = pHots[i]->GetFBQianghuaLevel();
			if(qianghuaLv == 0)
				qianghuaLv = 1;
			else if(qianghuaLv > MAX_FUBEN_LEVEL)
				qianghuaLv = MAX_FUBEN_LEVEL;
			
			int level = pHots[i]->GetLevel();
			int64 addExp = expManager.GetHuoDongExp(2,level,1.0/FB_FIGHT_COUNT_RI_CHANG_QIANG_HUA/5.0);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+addExp);
			pHots[i]->AddExp(addExp, true, true);
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	// 副本结算
	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);

			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)15;
			//				经验
			msg<<(uint32)addExp;
			SingletonAwardManager::instance().MakeAwardMsgAndSendAward(pHots[i], COPY_ID_QIANG_HUA, msg);
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			pHots[i]->SetBitSet(194); // 标记 强化副本 是否通关过
			RiChangFuBenCheckStageGoal(pHots[i]);

			/*SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_QiangHuaFB);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_QiangHuaFB);
			SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_QiangHuaFB);*/

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

// 日常 升阶副本
void CFight::RiChangShengJieFuBenEnd()
{
	// data8 201: 506低级装备升阶石
	// data8 202: 507
	// data8 203: 508
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_SHENG_JIE)
		return;

	const int COPY_ID = 4;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);

	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(COPY_ID);
		if(!pfuBen)
			return;
		for(int i=0;i<num;i++)
		{
			uint8 shengjieLv = pHots[i]->GetFBShengjieLevel();
			if(shengjieLv == 0)
				shengjieLv = 1;
			else if(shengjieLv > MAX_FUBEN_LEVEL)
				shengjieLv = MAX_FUBEN_LEVEL;
			
			int level = pHots[i]->GetLevel();
			int64 addExp = expManager.GetHuoDongExp(4,level,1.0/FB_FIGHT_COUNT_RI_CHANG_DAO_JU/3.0);
			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+addExp);
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			pHots[i]->SetExtData8(209,0);
			pHots[i]->SetExtData8(210,0);
		}
	}

	if(m_pScene->GetVisibleMonsterBossNum() == 0 && curSrcId == COPY_ID_SHENG_JIE)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);

			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)17;
			//				经验
			msg<<(uint32)addExp;
			//	物品类型数量
			SingletonAwardManager::instance().MakeAwardMsgAndSendAward(pHots[i], COPY_ID_SHENG_JIE, msg);
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			pHots[i]->SetBitSet(196); // 标记 道具副本 是否通关过
			RiChangFuBenCheckStageGoal(pHots[i]);

			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_ShenJieFB);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_ShenJieFB);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_ShenJieFB);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

void CFight::RiChangChongKaiFuBenEnd()
{
	// data8 201: 2310 1级神将铠升星石
	// data8 202: 2311
	// data8 203: 2312
	// data8 210: 击杀小怪数量
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_CHONG_KAI)
		return;

	const int COPY_ID = 102;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);
		
	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(COPY_ID);
		if(!pfuBen)
			return;
		for(int i=0;i<num;i++)
		{
			uint8 chongkaiLv = pHots[i]->GetFBZhankaiLevel();
			if(chongkaiLv == 0)
				chongkaiLv = 1;
			else if(chongkaiLv > MAX_FUBEN_LEVEL)
				chongkaiLv = MAX_FUBEN_LEVEL;
			
			int level = pHots[i]->GetLevel();
			int64 addExp = expManager.GetHuoDongExp(22,level,1.0/FB_FIGHT_COUNT_RI_CHANG_CHONG_KAI/3.0);
			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+ addExp);
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);
			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)27;
			//				经验
			msg<<(uint32)addExp;
			//	物品类型数量
			SingletonAwardManager::instance().MakeAwardMsgAndSendAward(pHots[i], COPY_ID_CHONG_KAI, msg);
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			pHots[i]->SetBitSet(358);
			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_ZhanKaiFB);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_ZhanKaiFB);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_ZhanKaiFB);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

// 日常 洗炼副本
void CFight::RiChangXiLianFuBenEnd()
{
	// data8 201: 612 圣水晶
	// data8 202: 801 1级炼化石
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_CUI_LIAN)
		return;

	const int COPY_ID = 101;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);

	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
		ERiChangFuBen *pfuBen=SingletonCRiChangFuBenManager::instance().FindFuBen(COPY_ID);
		if(!pfuBen)
			return;
		for(int i=0;i<num;i++)
		{
			uint8 cuilianLv = pHots[i]->GetFBCuilianLevel();
			if(cuilianLv == 0)
				cuilianLv = 1;
			else if(cuilianLv > MAX_FUBEN_LEVEL)
				cuilianLv = MAX_FUBEN_LEVEL;
			
			int level = pHots[i]->GetLevel();
			int64 addExp = expManager.GetHuoDongExp(21,level,1.0/FB_FIGHT_COUNT_RI_CHANG_XI_LIAN/1.0);
			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+addExp);
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);
			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)25;
			//				经验
			msg<<(uint32)addExp;
			SingletonAwardManager::instance().MakeAwardMsgAndSendAward(pHots[i], COPY_ID_CUI_LIAN, msg);
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			pHots[i]->SetBitSet(357);
			SingletonCHDExchangeManager::instance().DropExchangeItem(pHots[i],EEHDT_CuiLianFB);
			SingletonCHDExchangeManager::instance().DropHDItem(pHots[i],EEHDT_CuiLianFB);
			//SingletonCHDExchangeManager::instance().DropHDItem_New(pHots[i],EEHDT_CuiLianFB);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

// 日常 镶嵌副本
void CFight::RiChangXiangQianFuBenEnd()
{
	// data8 201: 519洗髓石
	// data8 209: 每层物品掉落次数
	// data8 210: 击杀小怪数量
	// data32 203:经验
	const uint16 itemList[] = {519};
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_XIANG_QIAN)
		return;

	const int COPY_ID = 100;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);

	int BossFlag = m_visibleMonsterId;	// 1boss 0小怪

	// 掉落奖励
	if(win)
	{
		for(int i=0;i<num;i++)
		{
			int level = pHots[i]->GetLevel();
			int64 addExp = 0;
			CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();
			addExp = expManager.GetHuoDongExp(20,level,1.0/FB_FIGHT_COUNT_RI_CHANG_XIANG_QIAN/3.0);
			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203) + addExp);
			
			char info[128];
			//snprintf(info,sizeof(info),"获得：经验%lld",addExp);
		//	SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());

			uint8 num = 0;
			if(BossFlag == 1)	// boss
			{
				num = 2;
				pHots[i]->SetExtData8(201,pHots[i]->GetExtData8(201)+num);
				pHots[i]->AddBangDingPackage(519,num);
				snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_576,GetItemName(519),(int)num);
			}
			else	// 小怪
			{
				num = (uint8)Random(1,2);
				pHots[i]->SetExtData8(201,pHots[i]->GetExtData8(201)+num);
				pHots[i]->AddBangDingPackage(519,num);
				snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_577,GetItemName(519),(int)num);
			}
			SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
		}

		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	if(m_pScene->GetVisibleMonsterBossNum() == 0)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);
			uint8 itemNum = 0;
			uint16 dataPos = 0;
			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)25;
			//				经验
			msg<<(uint32)addExp;
			//	物品类型数量
			dataPos = msg.GetDataLen();
			msg<<itemNum;
			for(int j=0;j < (int)(sizeof(itemList)/sizeof(itemList[0]));j++)
			{
				if(pHots[i]->GetExtData8(201+j) > 0)
				{
					itemNum++;
					msg<<itemList[j]<<pHots[i]->GetExtData8(201+j);
				}
			}

			msg.WriteData(dataPos,&itemNum,sizeof(itemNum));
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

// 日常 潜能副本
void CFight::RiChangQianNengFuBenEnd()
{
	// data32 202:潜能
	// data32 203:经验
	if (m_pScene == NULL)
		return;
	int curSrcId = m_pScene->GetSrcSceneId();
	if(curSrcId != COPY_ID_QIAN_NENG)
		return;

	const int COPY_ID = 5;
	bool win = true;
	CUser *teamloader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	int visableId = 0;
//	int dieNum = 0;
	GetPVE_FightResult(&teamloader,pHots,num,win,&visableId);
//	for(int i=0;i < num;i++)
//	{
//		if(!IsAlive(pHots[i]))
//			++dieNum;
//	}
//	m_pScene->AddDieCount(dieNum); // 增加副本死亡次数

	int BossFlag = m_visibleMonsterId;	// 1boss 0小怪
	const int QN_Drop[][2] = {{150,250},{250,350},{350,450},{450,550}};

	// 掉落奖励
	if(win)
	{
		// 要删除怪
		m_pScene->DelVisibleMonster(visableId);
		CHuoDongExpManage &expManager = SingletonHuoDongExpManager::instance();

		for(int i=0;i<num;i++)
		{
			uint8 qiannengLv = pHots[i]->GetFBQiannengLevel();
			if(qiannengLv == 0)
				qiannengLv = 1;
			else if(qiannengLv > MAX_FUBEN_LEVEL)
				qiannengLv = MAX_FUBEN_LEVEL;
			
			int64 addExp = expManager.GetHuoDongExp(5,pHots[i]->GetLevel(),1.0/FB_FIGHT_COUNT_RI_CHANG_QIAN_NENG/5.0);
			addExp = pHots[i]->AddExp(addExp, true, true);
			pHots[i]->SetExtData32(203,pHots[i]->GetExtData32(203)+ addExp);
			
			char info[128];
			int qianNeng = 0;
			if(BossFlag == 1)	// boss
				qianNeng = QN_Drop[qiannengLv-1][1] + Random(1,30);
			else				// 小怪
				qianNeng = QN_Drop[qiannengLv-1][0] + Random(10,30);

			pHots[i]->SetExtData32(202,pHots[i]->GetExtData32(202)+qianNeng);
			pHots[i]->AddQianNeng(qianNeng);

			snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_578,qianNeng);
			SendSysInfoFightEnd(pHots[i],MakeStringColor(info,TIPS_WARNING_COLOR).c_str());
		}
	}
	else
	{
		if(teamloader != NULL)
			SyncSceneTeamPos(teamloader,m_pScene->GetX(),m_pScene->GetY());

		SVisibleMonsterBoss vMonster;
		m_pScene->FindVisibleMonsterBoss(visableId,vMonster,0);
	}

	// 副本结算
	if(m_pScene->GetVisibleMonsterBossNum() == 0 && curSrcId == COPY_ID_QIAN_NENG)
	{
		for(int i=0;i<num;i++)
		{
			int64 addExp = 0;
			addExp += pHots[i]->GetExtData32(203);

			CNetMessage msg;
			msg.SetType(MSG_FUBEN_OPTION);
			msg<<(uint8)18;
			//			经验				潜能
			msg<<(uint32)addExp<<pHots[i]->GetExtData32(202);
			uint8 num = 0;
			msg<<num;
			SingletonSocket::instance().SendMsg(pHots[i]->GetSock(),msg);

			pHots[i]->SetBitSet(197); // 标记 潜能副本 是否通关过
			RiChangFuBenCheckStageGoal(pHots[i]);

			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_COPY, 1, COPY_ID);
		}
	}
}

void CFight::RiChangChongWu_Middle(CUser *pUser)
{
	//const uint8 PET_NUM = 3;
	if(pUser == NULL || m_pScene == NULL)
		return;
	//int difficulty = 2;	// 中级神将副本
	//uint8 num = 0;
	//char buf[128];
	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg<<(uint8)33 << pUser->GetExtData32(203);
	SingletonAwardManager::instance().SendLevelAward(pUser, COPY_ID_CHONG_WU_2_DROP, &msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
	SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,EEHDT_XunChong);
	SingletonCHDExchangeManager::instance().DropHDItem(pUser,EEHDT_XunChong);
	//SingletonCHDExchangeManager::instance().DropHDItem_New(pUser,EEHDT_XunChong);
}

// 日常 神将副本 结算
void CFight::RiChangChongWuFuBenJieSuan(CUser* pUser)
{
	if(pUser == NULL || m_pScene == NULL)
		return;
	int sceneId = m_pScene->GetSrcSceneId();
	if(sceneId < COPY_ID_CHONG_WU_1 || sceneId > COPY_ID_CHONG_WU_3)
		return;	
	int difficulty = sceneId - COPY_ID_CHONG_WU_1 + 1;	// 1初级2中级3高级
	if(difficulty < 1 || difficulty > 3)
		return;
	int dorpId = COPY_ID_QIANG_HUA_DROP + difficulty;
	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg << (uint8)14 << pUser->GetExtData32(203);
	SingletonAwardManager::instance().SendLevelAward(pUser, dorpId, &msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);	
	RiChangFuBenCheckStageGoal(pUser);
	
	/*if (petQuality == 3 && type == 1)
	{
		pUser->SetBitSet(507);
	}*/
	
	SingletonCHDExchangeManager::instance().DropExchangeItem(pUser,EEHDT_XunChong);
	SingletonCHDExchangeManager::instance().DropHDItem(pUser,EEHDT_XunChong);
	//SingletonCHDExchangeManager::instance().DropHDItem_New(pUser,EEHDT_XunChong);
}

// 天书副本
void CFight::RiChangChongWu_Tianshu(CUser* pUser)
{
	if(pUser == NULL || m_pScene == NULL)
		return;
	//int dorpId = COPY_ID_CHONG_WU_4;
	CNetMessage msg;
	msg.SetType(MSG_FUBEN_OPTION);
	msg << (uint8)14 << pUser->GetExtData32(203);
	SingletonAwardManager::instance().MakeAwardMsgAndSendAward(pUser, COPY_ID_CHONG_WU_4, msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

// 多人闯关战斗结束
void CFight::ChuangGuanFightEnd()
{
	//if (m_type == EFTChuangGuanUserFight)
	//{
	//	bool win = IsFightWithPlayerWin();
	//	
	//	CUser *pUser = GetGroupHead(EGT_GROUP1); // 自己
	//	if (pUser == NULL)
	//	{
	//		return;
	//	}
	//	CXunBaoManage& xunBao = pUser->GetXunbaoManage();
	//	xunBao.PvPFightCallBack(win);
	//}
}

void CFight::GrabFishTaoPao(CUser *pUser,uint8 pos)
{
	if(m_type != EFTGrabFish)
		return;
	if(pUser == NULL || pos == 0 || pos > MAX_MEMBER)
		return;
	if(pos != GROUP1_MAIN_POS)
		return;
	CUser *pOthUser = GetUser(GROUP2_MAIN_POS); // 对方
	if(pOthUser == NULL)
		return;

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr tarPtr = onlineUser.GetUserByRoleId(pOthUser->GetRoleId());
	CUser *pTarUser = tarPtr.get();
	if(pTarUser != NULL)
		pTarUser->m_grabedTime = 0; // 取消被抢夺的状态
	pUser->SetExtData8(65,0);		// 取消抢夺目标

	if(!SingletonFishManager::instance().IsInHuoDongTime())
	{
		int sId = EXIT_FB_SCENE_ID;
		int posX = EXIT_FB_SCENE_X;
		int posY = EXIT_FB_SCENE_Y;
		pUser->GetEnterPos(sId,posX,posY);
		TransportUser(pUser,sId,posX,posY,0);
	}
}

// 钓鱼 抢夺战斗结束
void CFight::GrabFishFightEnd()
{
	if (m_type != EFTGrabFish)
		return;

	bool group1_allDie = true;
	bool group2_allDie = true;
	CUser *pUser = NULL;
	CUser *pOthUser = NULL;
	GetFightResult(group1_allDie,group2_allDie,&pUser,&pOthUser);
	if(pOthUser == NULL)
		return;
	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	ShareUserPtr tarPtr = onlineUser.GetUserByRoleId(pOthUser->GetRoleId());
	CUser *pTarUser = tarPtr.get();
	if(!group1_allDie && group2_allDie)	// 抢夺成功
	{
		if (pTarUser != NULL)
		{
			pTarUser->SetExtData8(64,pTarUser->GetExtData8(64)+1); // 增加玩家被抢夺的次数
			pTarUser->m_grabedProtectTime = GetSysTime()+60; // 被抢夺保护时间
		}

		if(pUser != NULL)
		{
			int fishId = 0;
			CFishRoom* pFishRoom = pUser->GetFishRoom();
			if(pFishRoom != NULL)
				fishId = pFishRoom->GrabFishSuccess(pUser,pOthUser->GetRoleId(),pUser->GetExtData8(65)); // 成功抢夺处理
			if(fishId != 0)
			{
				pUser->SetExtData8(63,pUser->GetExtData8(63)+1); // 增加玩家当日抢夺次数
				char info[128];
				snprintf(info,sizeof(info),LANGUAGE_TRANSFORM_590,pUser->GetName(),GetItemName(fishId));
				SendSystemMail(pOthUser->GetRoleId(),info);
			}
		}
	}
	else
	{
		if(pUser != NULL)
			SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_591,TIPS_FAILURE_COLOR).c_str());
//		if (pTarUser != NULL)
//			pTarUser->m_grabedProtectTime = GetSysTime()+20; // 被抢夺保护时间
	}
	if(pTarUser != NULL)
		pTarUser->m_grabedTime = 0; // 取消被抢夺的状态

	if(pUser != NULL)
	{
		pUser->SetExtData8(65,0); // 取消抢夺目标
		if(!SingletonFishManager::instance().IsInHuoDongTime())
		{
			int sId = EXIT_FB_SCENE_ID;
			int posX = EXIT_FB_SCENE_X;
			int posY = EXIT_FB_SCENE_Y;
			pUser->GetEnterPos(sId,posX,posY);
			TransportUser(pUser,sId,posX,posY,0);
		}
	}
}

void CFight::RecoverAllUserHp(bool isBegin)
{
	if(m_type == EFT_KunLunShanTeam || m_type == EFTKunLunShan || m_type == EFTHuSong)	// 昆仑山, 护送、押镖例外
	{
		ChangeGroupUnitHpByMaxHp(1,isBegin);
		ChangeGroupUnitHpByMaxHp(GROUP2_BEGIN+1,isBegin);
		return;
	}
	else if(m_type == EFT_QunXianZhengBa)	// 群仙争霸
	{
		ResetQunXianHp(GROUP2_BEGIN+1,isBegin);
		return;
	}
	else if (m_type == EFTJueZhanKunLunFight)
	{
		RecoverGroupUnitHp(1, isBegin);
		return;
	}

	RecoverGroupUnitHp(1,isBegin);
	RecoverGroupUnitHp(GROUP2_BEGIN+1,isBegin);
}

void CFight::ResetQunXianHp(uint8 pos,bool isBegin)
{
	uint8 beginPos = 1;
	uint8 endPos = GROUP2_BEGIN;
	if(pos > GROUP2_BEGIN)
	{
		beginPos = GROUP2_BEGIN+1;
		endPos = MAX_MEMBER;
	}

	CUser *pHots = NULL;
	uint8 hotPos = 0xff;
	uint8 pets[GROUP2_BEGIN] = {0};
	int petNum = 0;
	for(uint8 pos = beginPos; pos <= endPos;pos++)
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pHots = pUser;
			hotPos = pos;
			continue;
		}
		SPet *pPet = GetPet(pos);
		if(pPet != NULL)
			pets[petNum++] = pos;
	}

	if(hotPos == 0xff || pHots == NULL)
		return;
	int hp = GetMaxHp(hotPos)*pHots->GetQunXianRoleHpRatio();
	if(hp < 1)
		hp = 1;
	pHots->SendUpdateInfo(EUUT_HP);

	for(int i=0;i < petNum;i++)
	{
		SPet *pet = GetPet(pets[i]);
		if(pet != NULL)
		{
			float hpRatio = 1; //pHots->GetQunXianPetHpRatio(petPos);
			if(isBegin)
				pet->hp = GetMaxHp(pets[i])*hpRatio;
			else
				pet->hp = pet->basicAttr.maxHp*hpRatio;
			if(pet->hp < 1)
				pet->hp = 1;
			pHots->SendPetUpdateInfo(pet->id,EUUT_HP);
		}
	}
}

void CFight::ChangeGroupUnitHpByMaxHp(uint8 pos,bool isBegin)
{
	uint8 beginPos = 1;
	uint8 endPos = GROUP2_BEGIN;
	uint8 group = EGT_GROUP1;
	if(pos > GROUP2_BEGIN)
	{
		beginPos = GROUP2_BEGIN+1;
		endPos = MAX_MEMBER;
		group = EGT_GROUP2;
	}

	uint8 pets[GROUP2_BEGIN] = {0};
	int petNum = 0;
	for(uint8 pos = beginPos; pos <= endPos;pos++)
	{
		SPet *pPet = GetPet(pos);
		if(pPet != NULL)
		{
			pets[petNum++] = pos;
		}
	}

	int maxHpTar = 0;
	int maxHpSrc = 0;
	for(int i=0;i < petNum;i++)
	{
		if(m_members[pets[i]-1].petOwner == 0)
			continue;
		CUser *pUser = GetUserInFight(m_members[pets[i]-1].petOwner, group);
		if(pUser != NULL)
		{
			SPet *pet = GetPet(pets[i]);
			if(pet != NULL)
			{
				if(isBegin)
				{
					maxHpTar = GetMaxHp(pets[i]);
					maxHpSrc = pet->basicAttr.maxHp;
				}
				else
				{
					maxHpSrc = GetMaxHp(pets[i]);
					maxHpTar = pet->basicAttr.maxHp;
				}
				if(maxHpSrc != maxHpTar)
				{
					int tarHp = pet->hp*(maxHpTar/(double)maxHpSrc);
					if(tarHp < 1)
						tarHp = 1;
					else if(tarHp > maxHpTar)
						tarHp = maxHpTar;
					pet->hp = tarHp;
					pUser->SendPetUpdateInfo(pet->id,EUUT_HP);
				}
			}
		}
	}
}

void CFight::RecoverGroupUnitHp(uint8 pos,bool isBegin)
{
	uint8 beginPos = 1;
	uint8 endPos = GROUP2_BEGIN;
	if(pos > GROUP2_BEGIN)
	{
		beginPos = GROUP2_BEGIN+1;
		endPos = MAX_MEMBER;
	}

	for(uint8 pos = beginPos; pos <= endPos;pos++)
	{
		SPet *pPet = GetPet(pos);
		if(pPet != NULL)
		{
			pPet->hp = pPet->basicAttr.maxHp;
			m_members[pos-1].hp = m_members[pos-1].unitAttr.maxHp;
		}
	}

	if(showFightLog)
	{
		cout<<"========================== beginFight"<<endl;
		for(uint8 pos = beginPos; pos <= endPos;pos++)
		{
			if(!IsEmpty(pos))
				cout<<"pos = "<<(int)pos<<", hp="<<GetHp(pos)<<", maxHp="<<GetMaxHp(pos)<<endl;
		}
	}
}

// 同步坐标
void CFight::SyncSceneTeamPos(CUser* pUser,int x,int y)
{
	if (pUser == NULL)
		return;
	if (m_pScene == NULL)
		return;
	CScene *pCurScene = pUser->GetScene();
	if (pCurScene == NULL)
		return;

	uint32 members[MAX_TEAM_MEMBER];
	uint8 num = m_pScene->GetTeamMem(pUser->GetTeam(),members);
	if (num == 0)
	{
		pUser->SetPos(x,y);
		SyncUserScenePos(pUser,x,y,0);
	}
	else
	{
		if (pUser->GetTeam() != pUser->GetRoleId())
			return;
		COnlineUser &onlineUser = SingletonOnlineUser::instance();
		for (int i = 0; i < num; ++i)
		{
			ShareUserPtr ptr = onlineUser.GetUserByRoleId(members[i]);
			CUser *pUser = ptr.get();
			if (pUser == NULL)
				continue;
			pUser->SetPos(x,y);
			SyncUserScenePos(pUser,x,y,0);
		}
	}
}

void CFight::SpecialFightEnd()
{
	char buf[128];
	snprintf(buf,sizeof(buf),"CFight::SpecialFightEnd fightType=%d",(int)m_type);
	gyu::util::TimePrint aa(buf);

	CMissionFightEnd();
	TongTianTaFightEnd();
	TongTianTa_BaZhuFightEnd();
	//ChuangGuanFightEnd();
	KunLunShanFightEnd();
	FeiXianFightEnd();
	GrabFishFightEnd();
	LingQiJuanXianEnd();

	// 日常副本
	RiChangQiangHuaFuBenEnd();
	RiChangChongWuFuBenEnd();
	//RiChangJinBiFuBenEnd();
	RiChangShengJieFuBenEnd();
	RiChangQianNengFuBenEnd();
	RiChangXiangQianFuBenEnd();
	RiChangXiLianFuBenEnd();
	RiChangChongKaiFuBenEnd();
	
	BangPaiGuardFightEnd();
	BangPaiPKEnd();
	BangZhanEnd();

	HuSongShenShouEnd();
	DailyBossFightEnd();
//	TreasureFightEnd();
	ShiLianFightEnd();
	ZhuoGuiFightEnd();
	XunChaShiFightEnd();
	XiuXianFightEnd();
	FengShenFightEnd();
	
//	XtmasTreeFightEnd();
//	XtmasBoxFightEnd();
//	BaoWeiZhanFightEnd();

#ifdef KUA_FU
	QieCuoFightEnd();
	EFKuaFuXueLianFightEnd();
	KunLunShanTeamFightEnd();
	KuaFu1V1FightEnd();
	KuaFu1vs1PreliminaryEnd();
	ShenJieMiJingNormalFightEnd();
	ShenJieMiJingEliteFightEnd();
	ShenJieMiJingBossFightEnd();
	KuaFuBossPkEnd();
	QunXianZhengBaEnd();
	KuaFuZhuoGuiFightEnd();
#endif

}

void CFight::SendFightReward(CUser* pUser)
{
	SFightCfgData *pFightCfg = SingletonCFightCfgManager::instance().GetFightCfg(m_cfgFightId);
	if (pFightCfg == NULL)
		return;

	sAwardManager.SendLevelAward(pUser, pFightCfg->level_rewardId);
}

void CFight::SetGroupShowName(uint8 group, const char *pName)
{
	if(group != EGT_GROUP1 && group != EGT_GROUP2)
		return;
	if(pName == NULL)
		return;
	m_ShowName[group] = pName;
}

void CFight::XiuXianFightEnd()
{
	if(m_type != EFTXiuXian)
		return;
	
	bool win = true;
	CUser *teamLeader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	GetPVE_FightResult(&teamLeader,pHots,num,win);
	if(teamLeader == NULL || num == 0)
		return;

	int index = GetVisibleMonsterId();
	if(index < 1)
		return;
	for(int i=0;i < num;i++)
	{
		if(pHots[i] != NULL)
		{
			if(win)
			{
				/*if(!pHots[i]->CanFightXiuXianByIdx(index))
					continue;*/
				if(!pHots[i]->IsXiuXianWinByIdx(index))
				{
/*					int dropId = sCDropMatchingMgr.GetActivityDropId(SOT_XiuXianLiLian, index);
					if (dropId != 0)
					{
						std::vector<SAwardData> awvec;
						sAwardManager.GetLevelAward(dropId, pHots[i]->GetLevel(), awvec);
						for (size_t ai = 0; ai < awvec.size(); ++ai)
						{
							pHots[i]->AddMaterial(awvec[ai].type, awvec[ai].num, true);
						}
					}
					else
					{
*/
					SendFightReward(pHots[i]);
//					}
					pHots[i]->SetExtData16(53, pHots[i]->GetExtData16(53) + 1);
					pHots[i]->SetXiuXianData(index, win);
				}
			}
			// 更新修仙历任务
			SingletonCMissionManager::instance().UpdateDCMissionComplate(pHots[i], EMISS_DC_37); // TODO
		}
	}
	if(teamLeader != NULL)
		teamLeader->UpdateXiuXian(index);
}

void CFight::BangZhanEnd()
{
	//const int DEC_XING_DONG_LI = 300;
	const int WIN_JI_FEN = 10;
	const int FAILED_JI_FEN = 3;
	//const int WIN_BANG_GONG = 30;
	int hour = GetHour();
	int minute = GetMinute();
	if(m_type != EFTBangZhan)
		return;

	// group1 挑战者
	// group2 被挑战者
	SFightResultData res;
	GetPVP_FightResult(res);

	CUser *pSrc = res.pLeader_1;
	CUser *pTar = res.pLeader_2;
	CUser **pWinner = NULL;
	CUser **pLoser = NULL;
	CUser *pWLeader = NULL;
	CUser *pLLeader = NULL;
	int winnerNum = 0;
	int loserNum = 0;

	if (pSrc == NULL && pTar == NULL)
		return;

	CScene *pScene = NULL;
	if (pSrc != NULL)
		pScene = pSrc->GetScene();
	else if (pTar != NULL)
		pScene = pTar->GetScene();

	if (pScene == NULL)
		return;
	if(res.winGroup == 1)	// 挑战者胜利
	{
		pWinner = res.pHots_1;
		winnerNum = res.num_1;
		pWLeader = res.pLeader_1;
		pLoser = res.pHots_2;
		loserNum = res.num_2;
		pLLeader = res.pLeader_2;
	}
	else	// 挑战者失败
	{
		pWinner = res.pHots_2;
		winnerNum = res.num_2;
		pWLeader = res.pLeader_2;
		pLoser = res.pHots_1;
		loserNum = res.num_1;
		pLLeader = res.pLeader_1;
	}

	int time = hour*100 + minute;
	if(time >= BP_FIGHT_START && time < BP_FIGHT_END)	// 帮战时间
	{
		char buf[128];
		for (int i = 0; i < winnerNum; i++)	// 挑战者胜利
		{
			if(pWinner[i] != NULL)
			{
				SingletonCBangPaiManager::instance().AddBangPaiJiFen(pWinner[i], WIN_JI_FEN);
				if (pLLeader != NULL)
				{
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0130, pLLeader->GetName(), WIN_JI_FEN);
					SendSysInfoFightEnd(pWinner[i], MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
				}
			}
		}
		for(int i=0;i < loserNum;i++)
		{
			if(pLoser[i] != NULL)
			{
				SingletonCBangPaiManager::instance().AddBangPaiJiFen(pLoser[i], FAILED_JI_FEN);
				if (pLLeader != NULL)
				{
					snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0131, pWLeader->GetName(), FAILED_JI_FEN);
					SendSysInfoFightEnd(pLoser[i], MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
				}
			}
		}
		for(int i=0;i < loserNum;i++)
		{
			if(pLoser[i] != NULL && pLoser[i]->GetBangPai() == 0)
			{
				int teamId = pLoser[i]->GetTeam();
				if(teamId == 0)
					teamId = pLoser[i]->TempLeaveTeam();
				if(teamId > 0)
					pScene->LeaveSceneTeam(teamId,pLoser[i]);
				EnterBPFightSafeArea(pLoser[i]);
			}
		}
		for(int i=0;i < loserNum;i++)
		{
			if(pLoser[i] != NULL && pLoser[i]->GetBangPai() > 0)
			{
				if(pLoser[i]->GetTeam() == 0 || (pLoser[i]->GetTeam() > 0 && pLoser[i]->GetRoleId() == pLoser[i]->GetTeam()))
				{
					EnterBPFightSafeArea(pLoser[i]);
					break;
				}
			}
		}
	}
	else if(time == BP_FIGHT_END || (time >= BP_FIGHT_BOX_START && time < BP_FIGHT_BOX_END))	// 掉宝箱
	{
		for(int i=0;i < winnerNum;i++)
		{
			if(pWinner[i] != NULL)
			{
#ifndef KUA_FU
				if(pWinner[i]->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID())
					continue;
#else
				if(pWinner[i]->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID(SingletonCBangPaiManager::instance().GetKuaFuBangZhanGroupIdx(pWinner[i]->GetBangPai())))
					continue;
#endif
				else
				{
					pScene->LeaveSceneTeam(pWinner[i]->GetTeam(), pWinner[i]);
#ifndef KUA_FU
					TransportUser(pWinner[i],BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
					TransportUser(pWinner[i],KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
				}
				if(pWinner[i]->GetTeam() != 0 && pWinner[i]->GetTeam() != pWinner[i]->GetRoleId())
					continue;
			}
		}
		for(int i=0;i < loserNum;i++)
		{
			if(pLoser[i] != NULL)
			{
#ifndef KUA_FU
				if(pLoser[i]->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID())
					continue;
#else
				if(pLoser[i]->GetBangPai() == (uint32)GetBZ_WIN_BANG_ID(SingletonCBangPaiManager::instance().GetKuaFuBangZhanGroupIdx(pLoser[i]->GetBangPai())))
					continue;
#endif
				else
				{
					pScene->LeaveSceneTeam(pLoser[i]->GetTeam(), pLoser[i]);
#ifndef KUA_FU
					TransportUser(pLoser[i],BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
					TransportUser(pLoser[i],KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
				}
				if(pLoser[i]->GetTeam() != 0 && pLoser[i]->GetTeam() != pLoser[i]->GetRoleId())
					continue;
			}
		}
	}
	else	// 非帮战时间
	{
		for(int i=0;i < winnerNum;i++)
		{
			if(pWinner[i] != NULL)
			{
				if(pWinner[i]->GetTeam() != 0 && pWinner[i]->GetTeam() != pWinner[i]->GetRoleId())
					continue;
				else
#ifndef KUA_FU
					TransportUser(pWinner[i],BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
					TransportUser(pWinner[i],KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
			}
		}
		for(int i=0;i < loserNum;i++)
		{
			if(pLoser[i] != NULL)
			{
				if(pLoser[i]->GetTeam() != 0 && pLoser[i]->GetTeam() != pLoser[i]->GetRoleId())
					continue;
				else
#ifndef KUA_FU
					TransportUser(pLoser[i],BP_FIGHT_EXIT_SID,BP_FIGHT_EXIT_X,BP_FIGHT_EXIT_Y,1);
#else
					TransportUser(pLoser[i],KUAFU_EXIT_SID,KUAFU_EXIT_X,KUAFU_EXIT_Y,1);
#endif
			}
		}
	}
}

void CFight::BangPaiZhanTaoPao(CUser *pUser, uint8 pos)
{
	if (m_type != EFTBangZhan)
		return;
	if (pUser == NULL || pos == 0 || pos > MAX_MEMBER)
		return;
	if (m_pScene == NULL)
		return;

	/*const int DEC_XING_DONG_LI = 300;
	const int FAILED_JI_FEN = 50;*/
	//m_pScene->DecBZXingDongLi(pUser, DEC_XING_DONG_LI);
	//SingletonCBangPaiManager::instance().AddBangPaiJiFen(pUser, FAILED_JI_FEN);
	//UpdateBZXingDongLi(pUser);
	EnterBPFightSafeArea(pUser);
}

void CFight::BangPaiPKTaoPao(CUser *pUser,uint8 pos)
{
	if(m_type != EFTBangPaiPK)
		return;
	if(pUser == NULL || pos == 0 || pos > MAX_MEMBER)
		return;
	if(pos != GROUP1_MAIN_POS && pos != GROUP2_MAIN_POS)
		return;
	if(m_pScene == NULL)
		return;
	int begin = 1;
	int end = GROUP2_BEGIN;
	bool other_alive = false;
	if(pos == GROUP1_MAIN_POS)
	{
		begin = GROUP2_BEGIN+1;
		end = MAX_MEMBER;
	}
	for(int i=begin;i <= end; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			if(IsAlive(i))
			{
				other_alive = true;
				break;
			}
		}
		SPet *pPet = GetPet(i);
		if(pPet != NULL)
		{
			if(IsAlive(i))
			{
				other_alive = true;
				break;
			}
		}
	}
	if(!other_alive)
		return;

	if(CSceneManager::IsInActivityTime(SOT_BangPaiZhan))
	{
		EnterBPFightSafeArea(pUser);
	}
	else
	{
		int sId = 0;
		int posX = 0;
		int posY = 0;
		pUser->GetEnterPos(sId, posX, posY);
		TransportUser(pUser, sId, posX, posY, 0);
	}
}

void CFight::BangPaiPKEnd()
{
	// 多人PK
	if(m_type != EFTBangPaiPK)
		return;
	CUser *pSrc = GetGroupHead(EGT_GROUP1);	// 挑战者
	CUser *pSrcUser[MAX_TEAM_MEMBER] = {NULL,NULL,NULL};
	int srcNum = 0;
	CUser *pTar = GetGroupHead(EGT_GROUP2);	// 被挑战者
	CUser *pTarUser[MAX_TEAM_MEMBER] = {NULL,NULL,NULL};
	int tarNum = 0;
	
	CUser **pWinner = NULL;
	int winNum = 0;
	if(pSrc == NULL || pTar == NULL)
		return;
	CScene *pScene = pSrc->GetScene();
	if(pScene == NULL)
		return;

	uint32 winnerBang = 0;
	uint32 srcBangId = pSrc->GetBangPai();
	uint32 tarBangId = pTar->GetBangPai();
	uint32 sceneBangPaiId = pSrc->GetSceneId() >> 8;
	if(sceneBangPaiId == 0)
		return;

	bool win = false;	// 挑战者是否胜利
	for(int i=1;i <= GROUP2_BEGIN; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			pSrcUser[srcNum++] = pU;
			if(IsAlive(i) && !win)
				win = true;
		}
		SPet *pPet = GetPet(i);
		if(pPet != NULL)
		{
			if(IsAlive(i) && !win)
				win = true;
		}
	}
	for(int i=GROUP2_BEGIN+1;i <= MAX_MEMBER; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
			pTarUser[tarNum++] = pU;
	}
	

	int sId = EXIT_FB_SCENE_ID;
	int posX = EXIT_FB_SCENE_X;
	int posY = EXIT_FB_SCENE_Y;
	char buf[256];
	if(win)	// 挑战者胜利
	{
		for (int i = 0; i < srcNum; i++)
		{
			pSrcUser[i]->AddBangAreaContinuousKillNum();
			if (pSrcUser[i]->GetBangAreaContinuousKillNum() == 3)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0122, pSrcUser[i]->GetName());
				SysInfoToAllUser(MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
			}
			else if (pSrcUser[i]->GetBangAreaContinuousKillNum() == 5)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0123, pSrcUser[i]->GetName());
				SysInfoToAllUser(MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
			}
			else if (pSrcUser[i]->GetBangAreaContinuousKillNum() == 10)
			{
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0124, pSrcUser[i]->GetName());
				SysInfoToAllUser(MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
			}
		}
		/*for(int i=0;i < tarNum;i++)
			pTarUser[i]->ClearBangAreaContinuousKillNum();*/
		if(tarBangId == sceneBangPaiId)	// 本帮派
		{
			SyncSceneTeamPos(pTar,1575,556);
		}
		else	// 其他帮派
		{
			pTar->GetEnterPos(sId,posX,posY);
			TransportUser(pTar,sId,posX,posY,0);
		}

		pWinner = &pSrcUser[0];
		winNum = srcNum;
		winnerBang = srcBangId;
	}
	else	// 挑战者失败
	{
		for(int i=0;i < tarNum;i++)
			pTarUser[i]->AddBangAreaContinuousKillNum();
		for(int i=0;i < srcNum;i++)
			pSrcUser[i]->ClearBangAreaContinuousKillNum();
		if(srcBangId == sceneBangPaiId)	// 本帮派
		{
			SyncSceneTeamPos(pSrc,1575,556);
		}
		else	// 其他帮派
		{
			pSrc->GetEnterPos(sId,posX,posY);
			TransportUser(pSrc,sId,posX,posY,0);
		}

		pWinner = &pTarUser[0];
		winNum = tarNum;
		winnerBang = tarBangId;
	}

	for(int i=0;i < winNum;i++)
	{
		if(pWinner[i] != NULL)
		{
			if(winnerBang == sceneBangPaiId)
			{
				pWinner[i]->AddKillPlayerCount();
				CBangPai::UpdateTaskInfo(pWinner[i],EBTT_KillPlayer);
				pWinner[i]->UpdateBangHuoYue(EBHT_KillPlayer);

				int killNum = pWinner[i]->GetExtData8(140) + 1;
				if(killNum <= KILL_ROLE_TIMES_LIMIT_GAIN)
				{
					SingletonCBangPaiManager::instance().AddBangGong(pWinner[i],BANG_GONG_KILL_ROLE);
					pWinner[i]->SetExtData8(140,killNum);
				}
			}
			
			uint16 continuousKillNum = pWinner[i]->GetBangAreaContinuousKillNum();
			if(continuousKillNum == 1 || continuousKillNum == 3 || continuousKillNum == 5 || continuousKillNum == 10)
			{
				if(winnerBang == sceneBangPaiId)
				{
					if(continuousKillNum == 1)
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_593,ROLE_NAME_COLOR,pWinner[i]->GetName());
					else if(continuousKillNum == 3)
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_594,ROLE_NAME_COLOR,pWinner[i]->GetName());
					else if(continuousKillNum == 5)
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_595,ROLE_NAME_COLOR,pWinner[i]->GetName());
					else if(continuousKillNum == 10)
						snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_596,ROLE_NAME_COLOR,pWinner[i]->GetName());
					else
						return;
					SysInfoToAllUser(buf,true);
				}
				else
				{
					string bangName = GetBangName(sceneBangPaiId);
					if(bangName.size() > 0)
					{
						if(continuousKillNum == 1)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_597,ROLE_NAME_COLOR,pWinner[i]->GetName(),BANG_NAME_COLOR,bangName.c_str());
						else if(continuousKillNum == 3)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_598,ROLE_NAME_COLOR,pWinner[i]->GetName(),BANG_NAME_COLOR,bangName.c_str());
						else if(continuousKillNum == 5)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_599,ROLE_NAME_COLOR,pWinner[i]->GetName(),BANG_NAME_COLOR,bangName.c_str());
						else if(continuousKillNum == 10)
							snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_600,ROLE_NAME_COLOR,pWinner[i]->GetName(),BANG_NAME_COLOR,bangName.c_str());
						else
							return;
						SysInfoToAllUser(buf,true);
					}
				}
			}
		}
	}
}

void CFight::BangPaiGuardFightEnd()
{
	if(m_type != EFTBangPaiGuard)
		return;
	if(m_cacheData.size() < 3)
		return;

	bool group1_allDie = true;
	bool group2_allDie = true;
	CUser *pUser1 = NULL;	// 挑战者
	CUser *pUser2 = NULL;	// 守卫
	SMonsterInst *pMonster = NULL;
	int visableId = 0;
	GetFightResult(group1_allDie,group2_allDie,&pUser1,&pUser2,&pMonster,&visableId);

	if(pUser1 == NULL)
		return;
	bool win = (!group1_allDie && group2_allDie);
	uint32 bangpaiId = m_cacheData[0];
	uint8 plantIdx = m_cacheData[1];
	uint8 cellPos = m_cacheData[2];
	CBangPai *pBangPai = SingletonCBangPaiManager::instance().FindBangPai(bangpaiId);
	if(pBangPai == NULL)
		return;
	pBangPai->StealFightEnd(pUser1,plantIdx,cellPos,win);
}

CUser *CFight::GetGroupHead(int group)
{
	if (group != EGT_GROUP2 && group != EGT_GROUP1)
		return NULL;

	vector<ShareUserPtr>& vec = m_groupUser[group];
	if (vec.empty())
		return NULL;
	return vec[0].get();
}

void CFight::GetPVE_FightResult(CUser **pLeader,CUser **pHots,int &num,bool &isWin,int *type)
{
	// 怪在左边group1，人在右边group2
	if(pLeader == NULL || pHots == NULL)
		return;

	bool group1_allDie = true;
	bool group2_allDie = true;
	CUser *pUser1 = NULL;
	CUser *pUser2 = NULL;
	SMonsterInst *pMonster = NULL;
	int visableId = 0;
	GetFightResult(group1_allDie,group2_allDie,&pUser1,&pUser2,&pMonster,&visableId);

	isWin = (group1_allDie && !group2_allDie);
	if(type != NULL)
		*type = visableId;
	*pLeader = NULL;
	num = 0;
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			pHots[num++] = pUser;
			if(pUser->GetTeam() == 0 || pUser->GetTeam() == pUser->GetRoleId())
			{
				*pLeader = pUser;
			}
		}
	}
}

void CFight::GetPVP_FightResult(SFightResultData &result)
{
	result.Clear();

	bool group1_allDie = true;
	bool group2_allDie = true;
	for(int pos = 1;pos <= GROUP2_BEGIN; pos++)
	{
		if(IsAlive(pos))
			group1_allDie = false;

		SMonsterInst *pM = GetMonster(pos);
		if(pM != NULL)
		{
			result.monVisableId = pM->visableId;
			result.pMonster = pM;
			continue;
		}
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			result.pos_1[result.num_1] = pos;
			result.pHots_1[result.num_1] = pUser;
			result.num_1++;
			if(pUser->GetTeam() == 0 || pUser->GetTeam() == pUser->GetRoleId())
				result.pLeader_1 = pUser;
		}
	}
	for(int pos = GROUP2_BEGIN+1;pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
			group2_allDie = false;
		
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			result.pos_2[result.num_2] = pos;
			result.pHots_2[result.num_2] = pUser;
			result.num_2++;
			if(pUser->GetTeam() == 0 || pUser->GetTeam() == pUser->GetRoleId())
				result.pLeader_2 = pUser;
		}
	}

	if(!group1_allDie && group2_allDie)
		result.winGroup = 1;
	else if(group1_allDie && !group2_allDie)
		result.winGroup = 2;
}

void CFight::CMissionFightEnd()
{
	if(m_type != EFTCMission)
		return;
	
	bool win = true;
	CUser *teamLeader = NULL;
	CUser *pHots[MAX_MEMBER] = {0};
	int num = 0;
	GetPVE_FightResult(&teamLeader,pHots,num,win);
	if(teamLeader == NULL || num == 0)
		return;

	if(win)
	{
		for(int i=0;i<num;i++)
			SingletonCMissionManager::instance().UpdateCMissionFightState(pHots[i],m_taskId,m_fightTurn);
		teamLeader->m_missList.npc_act.RemoveAct(EMISS_ACT_FAIL_DIALOG);
	}
	else
	{
		teamLeader->m_missList.npc_act.RemoveAct(EMISS_ACT_WIN_DIALOG);
	}
	SingletonCMissionManager::instance().CheckCMissionNpcInteract(teamLeader,0,0,0);
}

void CFight::SendMatchInfo(uint8 dieGroup)
{
	if((dieGroup < 1) || (dieGroup > 2))
		return;
	string info;
	dieGroup--;
	
	uint8 nameNum = 0;
	for(uint8 pos = (1-dieGroup)*GROUP2_BEGIN; pos < (2-dieGroup)*GROUP2_BEGIN; pos++)
	{
		CUser *pUser = GetUser(pos+1);
		if(pUser == NULL)
			continue;
		if (nameNum > 0)
			info.append(MakeStringColor("、", ROLE_NAME_COLOR));
		info.append(MakeStringColor(pUser->GetName(), ROLE_NAME_COLOR));
		nameNum++;
	}
	info.append(LANGUAGE_TRANSFORM_603);
	nameNum = 0;
	for(uint8 pos = dieGroup*GROUP2_BEGIN; pos < (dieGroup+1)*GROUP2_BEGIN; pos++)
	{
		CUser *pUser = GetUser(pos+1);
		if(pUser == NULL)
			continue;
		if (nameNum > 0)
			info.append(MakeStringColor("、", ROLE_NAME_COLOR));
		info.append(MakeStringColor(pUser->GetName(), ROLE_NAME_COLOR));
		nameNum++;
	}
	CSceneManager &scene = SingletonSceneManager::instance();
	CScene *pScene = scene.FindScene(LEI_TAI_ID2);
	if (pScene == NULL)
		return;
	CNetMessage sysMsg;
	sysMsg.SetType(PRO_SCENE_SYSTEM_INFO);
	sysMsg << info;
	pScene->BroadcastMsgDirect(sysMsg);
}

void CFight::SendPkInfo(uint8 dieGroup)
{
	uint8 userNum = 0;
	CUser *pUser[2] = {0};
	for(uint8 i = 1; i <= MAX_MEMBER; i++)
	{
		CUser *p = GetUser(i);
		if(p != NULL)
		{
			userNum++;
			if(i <= GROUP2_BEGIN)
				pUser[0] = GetUser(i);
			else
				pUser[1] = GetUser(i);
		}
	}
	if(userNum != 2)
		return;
	if((pUser[0] == NULL) || (pUser[1] == NULL))
		return;
	if(abs(pUser[0]->GetLevel() - pUser[1]->GetLevel()) > 5)
		return;
	if((dieGroup < 1) || (dieGroup > 2))
		return;
	string info;
	dieGroup--;
	for(uint8 pos = (1-dieGroup)*GROUP2_BEGIN; pos < (2-dieGroup)*GROUP2_BEGIN; pos++)
	{
		CUser *pUser = GetUser(pos+1);
		if(pUser != NULL)
		{
			info.append(pUser->GetName());
			info.append(" ");
		}
	}
	if(m_pScene != NULL)
	{
		info.append(LANGUAGE_TRANSFORM_604);
		info.append(m_pScene->GetName());
	}
	info.append(LANGUAGE_TRANSFORM_605);

	for(uint8 pos = dieGroup*GROUP2_BEGIN; pos < (dieGroup+1)*GROUP2_BEGIN; pos++)
	{
		CUser *pUser = GetUser(pos+1);
		if(pUser != NULL)
		{
			info.append(pUser->GetName());
			info.append(" ");
		}
	}

	SysInfoToAllUser(info.c_str(),true);
}

extern CMainClass *gpMain;

void CFight::OtherTypeUserFightEnd(CUser *pUser,uint8 pos,SPet *pPet,list<uint32> &userList,
		int state,int exp,int money,uint8 res, bool isfast)
{
	if(pos >= MAX_MEMBER || pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_BATTLE_OVER);
	msg<<m_id;
	CSocketServer &sock = SingletonSocket::instance();
	if(m_type == EFTMeetMonster || m_type == EFTMission105)
	{
		int beiExp = exp;
		int beiRatio = 0;
		if (InSysDoubleExp())
		{
			beiExp *= GetSysDoubleExpRatio();
			beiRatio = GetSysDoubleExpRatio() - 1;
		}
		CHuoDongAwardManager &awardManager = SingletonCHuoDongAwardManager::instance();
		uint32 type = CHuoDongAwardManager::EXP_TEN_REWARD;
		if (awardManager.InHuodongLimit(pUser, type))
			beiExp *= 10;
		else if(pUser->UserDouble())
		{
			uint16 doubleType = pUser->GetUseDoubleType();
			if(doubleType == EET_TwoTimes)
				beiExp *= 2;
			else if(doubleType == EET_FiveTimes)
				beiExp *= 5;
			else if(doubleType == EET_TenTimes)
				beiExp *= 10;
		}
		beiExp -= exp;

		//[5，20+（等级/10）]随机。按场次掉钱。
//		int worldExp = GetWorldExp(pUser->GetLevel(),exp);
//		double stRatio = 0.0;
//		double stPairRatio = 0.0;
//		CUser *pHots[3] = {NULL,NULL,NULL};
//		uint8 userNum = 0;
		
		msg<<res;
		pUser->AddMaterial(HDAT_MONEY, money, true);

		if(state == 0)	//物品掉落
		{
			if(m_type == EFTMeetMonster)
				SingletonCHDExchangeManager::instance().DropHDItem_New(pUser,EEHDT_WildFight);
		//	DropItem(pUser,pos,msg);
		}
		else if(state == 1) // 角色死亡 发送文字提示
		{
			if(m_type == EFTMeetMonster)
				SendSysInfoFightEnd(pUser,MakeStringColor(LANGUAGE_TRANSFORM_606,TIPS_FAILURE_COLOR).c_str());
		}
		if((monsterId1 != 0) && (state == 0))
			SingletonCMissionManager::instance().AddKillMonsterNum(pUser,monsterId1,GetMonsterNum(monsterId1));
		if((monsterId2 != 0) && (state == 0))
			SingletonCMissionManager::instance().AddKillMonsterNum(pUser,monsterId2,GetMonsterNum(monsterId2));
	}
	else if(m_type == EFTScript)
	{
		msg<<res;

		if((state == 0) && (m_delNpcId != 0) && (m_pScene != NULL))
			m_pScene->DelNpc(m_delNpcId,m_delNpcIndex);
	}
	else if(m_type == EFTBaiHua)
	{
		if(state == 0)	//胜利
		{
			msg<<PRO_SUCCESS;
			BaiHuaXianZiJiangLi(pUser, msg);
			SendFightReward(pUser);
		}
		else
		{
			msg<<PRO_ERROR;
		}
	}
	else if (m_type == EFT_Nianshou)
	{
		if (state == 0)	//胜利
		{
			msg<<PRO_SUCCESS;
			SendFightReward(pUser);
		}
		else
		{
			msg<<PRO_ERROR;
		}
	}
	else
	{
		msg<<res;
		CancelAutoFight(pUser);
		pUser->SaveAutoFight(0,0);
	}

	if(!isfast)
		sock.SendMsg(pUser->GetSock(),msg);

	m_fightMsgList.push_back(msg);
	
	if(m_type == EFTGrabFish)
		return;
	if(!HaveState(pos+1,EFST_STATE_Escape))
	{
		if(m_huiCun)
		{
			CScene *pScene = pUser->GetScene();
			if(pScene != NULL)
			{
//				m_mutex.unlock();
				if(state == 1 && !pUser->HaveBitSet(156))
				{
					if(pScene->GetSrcSceneId() == EXIT_FB_SCENE_ID)
					{
						pUser->SetPos(EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y);
						SyncUserScenePos(pUser,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,1);
					}
					else
					{
						TransportUser(pUser,EXIT_FB_SCENE_ID,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,1);
					}
				}
//				m_mutex.lock();
			}
		}

		if(JiangCheng(state,pUser,pos))
		{
			CScene *pScene = pUser->GetScene();
			if(pScene != NULL)
				pScene->TempLeaveTeam(pUser);
			if(!pUser->HaveBitSet(156))	// 可以传送
			{
				if(pUser->GetSrcSceneId() == EXIT_FB_SCENE_ID)
				{
					pUser->SetPos(EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y);
					SyncUserScenePos(pUser,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,1);
				}
				else
				{
					TransportUser(pUser,EXIT_FB_SCENE_ID,EXIT_FB_SCENE_X,EXIT_FB_SCENE_Y,1);
				}
				pUser->SetMeetEnemy(true);	// 设置遇怪
			}
		}
		else
		{
			SendUserPos(pUser,userList);
		}
		if(pUser->GetSock() > 0)
			UpdateUserInfo(pUser,userList);
	}
}

void CFight::LeiTaiSaiTaoPao(CUser *pUser, uint8 pos)
{
	if (m_type != EFTMatch)
		return;
	if (pUser == NULL || pos == 0 || pos > MAX_MEMBER)
		return;
	if (m_pScene == NULL)
		return;

	static uint8 lossScore = 5;

	int val = pUser->GetVal(0);
	pUser->SetData8(1, pUser->GetData8(1) + 1);
	pUser->SetVal(0, val - 100);
	pUser->SetExtData32(461, GetSysTime() + CScene::MATCH_CD);
	pUser->SetExtData8(639, pUser->GetExtData8(639) + 1);
	if (m_pScene != NULL)
	{
		char buf[64];
		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_616, lossScore);
		SendSysInfoFightEnd(pUser, MakeStringColor(buf, TIPS_WARNING_COLOR).c_str());
		m_pScene->SetUserJiFen(pUser->GetRoleId(), (char*)pUser->GetName(), lossScore);
		// 发送擂台赛积分
		{
			pUser->SendLeiTaiJifen();
		}
	}
	if (pUser->GetData8(1) >= 5 || !CSceneManager::IsInActivityTime(SOT_LeiTaiSai)) // 连输传出地图
	{
		m_mutex.unlock();
		pUser->NoLockBackLastScene();
		m_mutex.lock();
	}
}

void CFight::MatchUserFightEnd(CUser *pUser,uint8 pos,SPet *pPet,list<uint32> &userList,int state,uint8 res, bool isfast)
{
	static uint8 winScore = 20;
	static uint8 lossScore = 5;
	if(pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_BATTLE_OVER);
	msg<<m_id<<res;

	CancelAutoFight(pUser);
	pUser->SaveAutoFight(0,0);

	if(!isfast)
		SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);

	m_fightMsgList.push_back(msg);
	
	SendUserPos(pUser,userList);
	if(pUser->GetSock() > 0)
		UpdateUserInfo(pUser,userList);

	if(pUser->IsLogout())
	{
		//if(gpMain != NULL)
		//	gpMain->UserLogOut(pUser);
	}
	if (BangPaiTiaoZhanSaiState() >= 2)
	{
		BangPaiTiaoZhanSaiFightEnd(pUser,state);
		cout << LANGUAGE_TRANSFORM_615 << pUser->GetName() << endl;
		return;
	}
	short jifen = 0;//pUser->GetData16(1);
	int val = pUser->GetVal(0);
	if(state == 0)
	{
		jifen = winScore;
		pUser->SetVal(0,val+100);
	}
	else
	{
		jifen = lossScore;
		pUser->SetData8(1,pUser->GetData8(1)+1);
		pUser->SetVal(0,val-100);
	}
	pUser->SetData16(1,pUser->GetData16(1)+1);
	pUser->SetExtData32(461, GetSysTime() + CScene::MATCH_CD);
	pUser->SetExtData8(639, pUser->GetExtData8(639) + 1);
	if(m_pScene != NULL)
	{
		char buf[64];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_616,jifen);
		SendSysInfoFightEnd(pUser,MakeStringColor(buf,TIPS_WARNING_COLOR).c_str());
		m_pScene->SetUserJiFen(pUser->GetRoleId(),(char*)pUser->GetName(),jifen);
		// 发送擂台赛积分
		{
			pUser->SendLeiTaiJifen();
		}
	}
	if(pUser->GetData8(1) >= 5 || !CSceneManager::IsInActivityTime(SOT_LeiTaiSai)) // 连输传出地图
	{
		m_mutex.unlock();
		pUser->NoLockBackLastScene();
		m_mutex.lock();
	}

	if(pUser->IsLogout())
	{
		if(gpMain != NULL) // 保存离线玩家数据
			gpMain->UserLogOut(pUser);
	}
}

// 帮派挑战赛战斗结束
void CFight::BangPaiTiaoZhanSaiFightEnd(CUser *pUser,int state)
{
	if (pUser == NULL)
		return;
	int jifen = 0;
	if(state == 0)
		jifen = 5;
	else
		jifen = 3;
	if(m_pScene != NULL)
	{
		int bang = pUser->GetBangPai();
		char buf[64];
		snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_617,jifen);
		SendSysInfo(pUser,buf);
		if (pUser->GetTeam() == pUser->GetRoleId()) // 只有队长加积分
		{
			m_pScene->BangPaiTiaoZhanAddPoint(bang,jifen);
			if (state == 0)
			{
				char msg[128];
				snprintf(msg,sizeof(msg),LANGUAGE_TRANSFORM_618,GetBangName(pUser->GetBangPai()),pUser->GetName());
				SysInfoToAllUser(msg,true);
			}
		}
	}

	if(pUser->IsLogout())
	{
		if(gpMain != NULL) // 保存离线玩家数据
			gpMain->UserLogOut(pUser);
	}
}

int CFight::CalculateFightStar(uint8 selfGroup, bool win)
{
	const int MAX_STAR = 3;
	int star = MAX_STAR;
	if(win)
	{
		uint8 beginPos = (selfGroup == EGT_GROUP1) ? 0 : GROUP2_BEGIN;
		uint8 endPos = (selfGroup == EGT_GROUP1) ? GROUP2_BEGIN : MAX_MEMBER;
		for(uint8 i=beginPos;i < endPos;i++)
		{
			SMonsterInst *pMonst = GetMonster(i+1);
			if(pMonst != NULL && !IsAlive(i+1))
			{
				star--;
				continue;
			}
			SPet *pPet = GetPet(i+1);
			if(pPet != NULL && !IsAlive(i+1))
			{
				star--;
				continue;
			}
			CUser *pU = GetUser(i+1);
			if(pU != NULL && !IsAlive(i+1))
			{
				star--;
				continue;
			}
		}
		if (star < 1)
			star = 1;
	}
	else
	{
		star = 0;
	}
	return star;
}

int CFight::GetLessHp(uint8 selfGroup, vector<uint16>& leesHp)
{
	uint8 beginPos = (selfGroup == EGT_GROUP1) ? 0 : GROUP2_BEGIN;
	uint8 endPos = (selfGroup == EGT_GROUP1) ? GROUP2_BEGIN : MAX_MEMBER;
	uint32 maxHp = 0;
	uint32 lessHp = 0;
	for (uint8 i = beginPos; i < endPos; i++)
	{
		uint32 curMaxHp = 0;
		uint32 curLessHp = 0;
		SPet *pPet = GetPet(i + 1);
		if (pPet != NULL && !IsAlive(i + 1))
		{
			curMaxHp = pPet->basicAttr.maxHp;
			curLessHp = pPet->hp;;
		}
		if (curMaxHp > 0)
		{
			maxHp += curMaxHp;
			lessHp += curLessHp;
			double percent = curLessHp / curMaxHp;
			leesHp.push_back(percent * 100);
		}
		else
			leesHp.push_back(0);
	}
	double percent = lessHp / maxHp;
	return percent * 100;
}


SCallUserScript CFight::UserFightEnd(ShareUserPtr &user, uint8 group, bool win, bool isfast)
{
	SCallUserScript call;
	CUser *pUser = user.get();
	if(pUser == NULL)
		return call;

	if ((m_type == EFTPlayerPk) || (m_type == EFTPlayerQieCuo)) // pk和切磋不会有脚本回调
		pUser->SetCallFun("");

	uint8 res = PRO_ERROR;
	int state = (win ? 0 : 1);	//state:0胜利、1 死亡、2 逃跑

	pUser->SetFight(0);
	if(win)
	{
		res = PRO_SUCCESS;
	}
	call.state = state;
	
	int num_s=0;
	pUser->GetCall(num_s);

	CNetMessage msg;
	msg.SetType(PRO_BATTLE_OVER);
	msg<<m_id;
	if (state == 0)	//胜利
		msg<<PRO_SUCCESS;
	else
		msg<<PRO_ERROR;

	// 战斗统计数据
	uint32 numPos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		SFightMember *p = GetFightMember(pos+1);
		if(p != NULL)
		{
			msg<<(uint8)(pos+1)<<p->sum_damage<<p->sum_beDamage<<p->sum_cure;
			num++;
		}
	}
	if(num > 0)
		msg.WriteData(numPos, &num, sizeof(num));
	
	if(!isfast)
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	
	m_fightMsgList.push_back(msg);
	return call;
}

int CFight::GetShiYaoExp(uint8 pos)
{
	uint8 begin;
	uint8 end;
	if(pos > GROUP2_BEGIN)
	{
		begin = 1;
		end = GROUP2_BEGIN + 1;
	}
	else
	{
		begin = GROUP2_BEGIN + 1;
		end = MAX_MEMBER + 1;
	}

	CUser *pUser = GetUser(pos);
	SPet *pPet = GetPet(pos);
	uint8 level = 0xff;
	int exp = 0;
	if(pUser != NULL)
	{
		level = pUser->GetLevel();
		exp = level * 40;
	}
	else if(pPet != NULL)
	{
		level = pPet->level;
		pUser = GetUser(pos-1);
	}

	if(level == 0xff)
		return 0;

	for(uint8 i = begin; i < end; i++)
	{
		SMonsterInst *pMonster = GetMonster(i);
		if(pMonster != NULL)
		{
			int cha = abs(pMonster->level - level);
			//1-INT(ABS(人等级-怪物等级)/5)*0.1）*怪物经验和物品掉落概率
			if(cha <= 5)
			{
			}
			else
			{
				float per = 1 - (cha-5)*0.06;
				if(per <= 0)
					per = 0.0;
				exp = (int)(per*exp);
			}
			break;
		}
	}
	int userNum = 0;
	for(uint8 i = 1; i <= MAX_MEMBER; i++)
	{
		if(GetUser(i) != NULL)
		{
			userNum++;
			if(userNum > 1)
			{
				exp *= 3;
				break;
			}
		}
	}
	return exp;
}

void CFight::UserFightEndHandle()
{
	for(uint16 g=EGT_GROUP1; g <= EGT_GROUP2; g++)
	{
		for(uint16 i=0; i < m_groupUser[g].size(); i++)
		{
			CUser *pU = m_groupUser[g][i].get();
			if(pU == NULL)
				continue;
			if(pU->IsLogout())
			{
				if(gpMain != NULL)
				{
					gpMain->UserLogOut(pU);
				}
				else
				{
					pU->SetFightEndTime();
					pU->SetCeLue(0);
				}
			}
		}
	}
}

int CFight::GetTurnLimit()
{
	int limitTurn = GetFightLimitTurn(m_type);
	int endTurnNum = GetEndConditionValue(EFET_Turn);
	if(endTurnNum <= 0 || endTurnNum > limitTurn)
		endTurnNum = limitTurn;
	return endTurnNum;
}

bool CFight::IsFightEnd(bool isfast)
{
//	if(m_pScene == NULL)
//		return true;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	if(m_fightIsEnd)
		return true;
	if(m_forceEnd || GetSysTime() - m_beginTime > m_timeOut || m_fightTurn >= GetTurnLimit())
	{
		m_fightIsEnd = true;
		for(uint16 g=EGT_GROUP1; g <= EGT_GROUP2; g++)
		{
			for(uint16 j=0; j < m_groupUser[g].size(); j++)
			{
				UserFightEnd(m_groupUser[g][j], g, false, isfast);
			}
		}

//		SpecialFightEnd();
		RecoverAllUserHp();
		
		UserFightEndHandle();

/*
		for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
		{
			CUser *pUser = GetUser(pos+1);
			if(pUser != NULL)
			{
				if ((m_type == EFTPlayerPk) || (m_type == EFTPlayerQieCuo)) // pk和切磋不会有脚本回调
					pUser->SetCallFun("");
				user_nu++;
//				OnepUser = pUser;
				pUser->SetFight(0);
//				if(!pUser->IsLogout())
//				{
//					sock.SendMsg(pUser->GetSock(),msg);
//					UpdateUserInfo(pUser,userList);
//				}
				pUser->SetExtData32(3,GetSysTime());
				int script = 0;
				string call = pUser->GetCall(script);
				if(!call.empty())
				{
					CCallScript *pCallScript = FindScript(script);//(name);
					if(pCallScript != NULL)
					{
						pUser->SetCallScript(pCallScript->GetScriptId());
						//cout<<"脚本战斗结束"<<script<<":"<<call.c_str()<<state<<endl;
						pCallScript->Call(call.c_str(),"uif",pUser,1,this);
					}
				}

				pUser->SetFightEndTime();
			}
		}

		for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
		{
			pUser = GetUser(pos+1);
			if(pUser != NULL)
			{
				if(pUser->IsLogout())
				{
					if(gpMain != NULL)
						gpMain->UserLogOut(pUser);
				}
				else
				{
					if(!isfast)
						sock.SendMsg(pUser->GetSock(),msg);
					if(pUser->GetSock() > 0)
						UpdateUserInfo(pUser,userList);
				}
			}
		}

		SpecialFightEnd();
		RecoverAllUserHp();
*/
		return true;
	}

	uint8 type = OneGroupAllDie();
	if(type != 0)
	{
		m_fightIsEnd = true;
		if(m_type == EFTPlayerPk)
		{
			SendPkInfo(type);
		}

		if(m_type == EFTMatch)
		{
			SendMatchInfo(type);
		}

		uint16 winGroup = CalculateWinGroup();
		for(uint16 g=EGT_GROUP1; g <= EGT_GROUP2; g++)
		{
			if(g == winGroup)	// 胜利
			{
				for(uint16 j=0; j < m_groupUser[g].size(); j++)
				{
					UserFightEnd(m_groupUser[g][j], g, true, isfast);
				}
			}
			else	// 失败
			{
				for(uint16 j=0; j < m_groupUser[g].size(); j++)
				{
					UserFightEnd(m_groupUser[g][j], g, false, isfast);
				}
			}
		}

/*
		SCallUserScript call;
		for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
		{
			SCallUserScript tmp = UserFightEnd(pos,userList, isfast);
			if(tmp.pUser.get() != NULL)
				call = tmp;
			pUser = GetUser(pos+1);
			if(pUser != NULL)
			{
				user_nu++;
//				OnepUser = pUser;
			}
		}

		if(call.pUser.get() != NULL)
		{
			CCallScript *pCallScript = FindScript(call.scriptId);
			if(pCallScript != NULL)
			{
				call.pUser->SetCallScript(pCallScript->GetScriptId());
				pCallScript->Call(call.scriptFun.c_str(),"uif",call.pUser.get(),call.state,this);
			}
		}
*/

//		SpecialFightEnd();
		RecoverAllUserHp();

		UserFightEndHandle();
		return true;
	}
	return false;
}

bool CFight::FastFightEnd(SFastFightResult &result)
{
	if(m_fightIsEnd)
		return true;

	uint8 type = OneGroupAllDie();
	if(m_forceEnd || m_fightTurn >= GetTurnLimit() || type != 0)
	{
		uint16 winGroup = EGT_GROUP2;
		result.win = false;
		if(m_forceEnd || m_fightTurn >= GetTurnLimit())	// 超时
		{
			winGroup = EGT_GROUP2;
		}
		else	// 正常结束
		{
			// Fast-fight callers place the initiator in group 1. The caller wins
			// only when group 2 is completely dead; mutual destruction is a loss.
			winGroup = (type == 2) ? EGT_GROUP1 : EGT_GROUP2;
			result.win = (winGroup == EGT_GROUP1);
		}

		// 特殊战斗，直接胜利
		if(m_type == EFT_BangPaiCopy)
		{
			winGroup = EGT_GROUP1;
			result.win = true;
		}
		
		// result data
		CZhenFaCfgMgr &zfMgr = SingletonCZhenFaCfgMgr::instance();
		for(uint16 g=EGT_GROUP1; g <= EGT_GROUP2; g++)
		{
			SZhenFaBasicCfg *pCfg = zfMgr.GetBasicCfg(m_zhenfaId[g]);
			if(pCfg == NULL)
				continue;
			for(uint16 pos=1+g*GROUP_MEMBER; pos <= GROUP2_BEGIN+g*GROUP_MEMBER; pos++)
			{
				if(!m_members[pos-1].memPtr.empty())
				{
					uint16 index = pos - g*GROUP_MEMBER;
					uint8 zhenfaPos = 0xff;
					for(uint8 i=0; i < sizeof(pCfg->fightPos)/sizeof(pCfg->fightPos[0]); i++)
					{
						if(pCfg->fightPos[i] == index)
						{
							zhenfaPos = i;
							break;
						}
					}
					
					SFastFightUnit data;
					data.pos = zhenfaPos;
					data.hp = m_members[pos-1].hp;
					data.maxHp = m_members[pos-1].unitAttr.maxHp;
					if(data.hp > data.maxHp)
						data.hp = data.maxHp;
					if(g == EGT_GROUP1)
					{
						result.group1.push_back(data);
					}
					else
					{
						if(!IsAlive(pos))
							data.hp = 0;
						result.group2.push_back(data);
					}
				}
			}
		}

		for(uint8 i = EGT_GROUP1; i <= EGT_GROUP2; i++)
		{
			for(uint16 j=0; j < m_groupUser[i].size(); j++)
			{
				UserFightEnd(m_groupUser[i][j], i, i == winGroup, true);
			}
		}

		m_fightIsEnd = true;
		return true;
	}
	return false;
}


//pos 0-11
bool CFight::IsGongFang(uint8 pos)
{
	return pos < GROUP2_BEGIN;
}

//战斗结束，对玩家进行奖惩,返回是否需要传送
bool CFight::JiangCheng(uint8 state,CUser *pUser,uint8 pos)
{
	if(pUser == NULL)
		return false;
	bool needTransport = false;
	stringstream info;
	if((pUser->GetLevel() <= 10) && (state == 1) && ((m_type == EFTPlayerPk) || (m_type == EFTMeetMonster)))
	{
		return true;
	}
	if((state == 1) && (m_type == EFTScript))
	{
		return false;
	}
	if((state == 1) && (m_type == EFTMeetMonster))
	{
		needTransport = true;
	}
	return needTransport;
}

int CFight::GetPower(uint8 pos)
{
	return 0;
}

void CFight::ClearChaoFeng(uint8 diePos)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(diePos <= GROUP2_BEGIN)
	{
		begin += GROUP_MEMBER;
		end += GROUP_MEMBER;
	}

	for(uint8 pos=begin;pos <= end;pos++)
	{
		// 后添加生效
		for(list<SFightBuffData>::reverse_iterator rit=m_members[pos-1].buff_list.rbegin(); rit != m_members[pos-1].buff_list.rend(); )
		{
			if(rit->id == ESBUFF_ChaoFeng)
			{
				if(rit->paraList.empty() || rit->paraList[0] == (int)diePos)
				{
					SpecialBuffPassAttr(pos, ESBUFF_ChaoFeng, false);	// 清除
					rit++;
					
					list<SFightBuffData>::iterator del_it(rit.base());
					m_members[pos-1].buff_list.erase(del_it);
					continue;
				}
			}
			rit++;
		}
	}
}

int CFight::GetChaoFengTarget(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return -1;
	for(list<SFightBuffData>::reverse_iterator rit=m_members[pos-1].buff_list.rbegin(); rit != m_members[pos-1].buff_list.rend(); rit++)
	{
		if(rit->id == ESBUFF_ChaoFeng)
		{
			if(rit->paraList.empty())
				continue;
			return rit->paraList[0];
		}
	}
	return -1;
}

void CFight::DecreaseHp(uint8 pos, uint8 srcPos, int &hp,int &absorpionHp,bool ignoreDun,int *fuhuoHp,bool activeTongShengGongSi)
{
	absorpionHp = 0;
	int addFuHuoHp = 0;
	if(fuhuoHp != NULL)
		*fuhuoHp = addFuHuoHp;
//	if(!IsAlive(pos))
//		return;
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return;
	SFightMember *pSrc = GetFightMember(srcPos);
	
	// 盾抵消伤害
	if(hp > 0)
	{
		if(!ignoreDun)	// 护盾生效
		{
			ShieldAbsorptionDamage(pos, hp, absorpionHp);
			p->sum_beDamage += absorpionHp;
			if(pSrc != NULL)
				pSrc->sum_damage += absorpionHp;
		}

		if(activeTongShengGongSi && HaveBuff(pos,ESBUFF_GongTongShengSi))
		{
			uint8 member[GROUP_MEMBER];
			uint8 num = 0;
			GetMeGroupExceptSelf(pos,member,num);
			if(num > 0)
			{
				uint8 tarMem[GROUP_MEMBER];
				uint8 tarNum = 0;
				for(uint8 i=0;i < num;i++)
				{
//					if(HaveBuff(member[i],ESBUFF_GongTongShengSi))
					tarMem[tarNum++] = member[i];
				}
				if(tarNum > 0)
				{
					int damage = hp/(tarNum+1);
					if(damage < 1)
						damage = 1;
					hp = damage;
					m_shareDamageMsg.SetType(m_shareDamageMsg.GetType()+1);
					m_shareDamageMsg<<(uint8)EFOT_Passive<<tarMem[0]<<(uint16)0<<""<<tarNum;
					int dam = damage;
					for(uint8 i=0;i < tarNum;i++)
					{
						int tarAbsorpionHp = 0;
						int tarFuhuoHp = 0;
						DecreaseHp(tarMem[i], srcPos, dam, tarAbsorpionHp, ignoreDun, &tarFuhuoHp, false);
						m_shareDamageMsg<<tarMem[i]<<-dam<<tarAbsorpionHp<<tarFuhuoHp;
						MakeBuffList(tarMem[i],m_shareDamageMsg);
					}
				}
			}
		}
	}

	int maxHp = GetMaxHp(pos);
	int val = p->AddHp(-hp,maxHp);
	if(val < 0)
	{
		p->sum_beDamage += -val;
		if(pSrc != NULL)
			pSrc->sum_damage += -val;
	}
	else
	{
		if(pSrc != NULL)
			pSrc->sum_cure += val;
	}

	float percent = ((float)(p->hp) / (p->unitAttr.maxHp)) * 100.0;
	if(pos <= GROUP2_BEGIN) // 判定血量比例
	{
		int val = GetEndConditionValue(EFET_HpPercent);
		if(val >= 0 && percent < (float)val)
			m_forceEnd = true;
	}

	if(IsAlive(pos))
	{
		if(p->hp == 0)
		{
			if(pos <= GROUP2_BEGIN)	// 死亡人数判定
			{
				int val = GetEndConditionValue(EFET_DieNum);
				if(val >= 0 && (GetUserGroupDieNum() + 1) > val)
					m_forceEnd = true;
			}
			if(m_forceEnd || fuhuoHp == NULL || !CalculateIsFuHuo(pos,addFuHuoHp))
			{
				SetState(pos, EFST_STATE_Die);
				AddDieUnit(pos);
				ClearChaoFeng(pos);
			}
			else	// 复活
			{
				p->AddHp(addFuHuoHp,maxHp);
				p->sum_cure += addFuHuoHp;
			}
		}
	}
	else
	{
		if(p->hp > 0)
		{
			ClearState(pos, EFST_STATE_Die);
			DelDieUnit(pos);
		}
	}

	if(!m_forceEnd)
	{
		if(fuhuoHp != NULL)
			*fuhuoHp = addFuHuoHp;
	}

	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_DefAdd);
	vector<ESkillPassitiveType> passList;
	passList.push_back(ESkill_Pass_AddAttrByDecHp);
	CalculatePassiveSkill_ExtAttrEffect(pos,0,trigger,passList);
}

void CFight::ImproveRevovery(uint8 pos,int recovery)
{
	CUser *pUser = GetUser(pos);
	SMonsterInst *pMonster = GetMonster(pos);
	if(pUser != NULL)
	{
		pUser->AddRecovery(recovery);
	}
	else if(pMonster != NULL)
	{
		pMonster->attr.wufang -= recovery;
	}
}

bool CFight::AllUserOption()
{
	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		if(!m_members[pos].memPtr.empty() && (m_members[pos].memPtr.type() == typeid(ShareUserPtr)))
		{
			CUser *pUser = (boost::any_cast<ShareUserPtr>(m_members[pos].memPtr)).get();
			if((pUser != NULL) && (!pUser->IsAutoFight()) && (pUser->GetSock() != -1))
			{
				if(!IsAlive(pos+1))	//人物死亡
				{
					if(!m_members[pos].select)	//神将没死，并且没有选择
						return false;
					continue;
				}
				if(m_members[pos].select)
					continue;
				return false;
			}
		}
	}
	return true;
}

int CFight::GetMonsterNum(int id)
{
	//boost::recursive_mutex::scoped_lock lk(m_mutex);
	int num = 0;
	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		SMonsterInst *pMonster = GetMonster(pos+1);
		if((pMonster != NULL) && (pMonster->id == id))
		{
			num++;
		}
	}
	return num;
}

void CFight::TurnOver(uint8 pos)
{
	m_userOpTime = 0;
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		SFightMember *p = GetFightMember(pos);
		if(p == NULL)
			return;
		if(p->type == EFMT_MONSTER)
		{
			if(p->celue == CL_MONSTER_DIE_END)
			{
				if(!IsAlive(pos))
					SetAllUserDie();
			}
		}

		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			if(pUser->IsAutoFight())
			{
				m_members[pos-1].select = true;
				int turn = pUser->GetAutoFightTurn() -1;
				pUser->SetAutoFightTurn((turn <=0) ? 0 : turn);
			}
			else
			{
				m_members[pos-1].select = false;
			}
		}
		DecAllSkillCD(pos);
//		DecAllStateEffectTurn(pos);
		if(!IsAlive(pos))
			return;
		ClearAdditiveSkillTurnData(pos);
		p->killUnit_ext_IsLimit = false;
	}
}

int CFight::GetSkillAddHpValue(uint8 src,uint8 target,int skillId,int skillLevel)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pSrc == NULL || pTarget == NULL)
		return 1;
	
	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return 1;
	if(pSkillCfg->type == ESKILL_Passive)
		return 1;
	if(pSkillCfg->activeEffect.effectType != 1)	// 配置异常
		return 1;
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL)
		return 1;

	int addHp = 1;
	if(pActive->effect_type == ESkill_Active_AddHpByDam)
	{
		addHp = pSrc->unitAttr.attack * ((pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel-1))/10000.0);
		addHp += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
	}
	else if(pActive->effect_type == ESkill_Active_AddHpNormal)
	{
		addHp = GetMaxHp(target) * ((pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel-1))/10000.0);
		addHp += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
	}
	else if(pActive->effect_type == ESkill_Active_FuHuo)
	{
		addHp = GetMaxHp(target) * ((pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel-1))/10000.0);
		addHp += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
	}
	return addHp;
}

int CFight::CalculateSkillDamage(uint8 src,uint8 target,int skillId,int skillLevel,int &selfDamage,vector<SAttrData> &attrList,vector<SAttrData> &tarAttrList)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 1;

	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return 1;
	if(pSkillCfg->type == ESKILL_Passive)
		return 1;
	if(pSkillCfg->activeEffect.effectType != 1)	// 配置异常
		return 1;
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL)
		return 1;

	int attackType = pSrc->attackType;
	int damage = GetUnitAttack(src) - GetUnitFangYu(target,attackType) * (1.0 - GetAttrValue(attrList,ESkill_PassAttr_HuShiFang)/10000.0);
	if(attackType == 1)	// 物攻
	{
		// 物理攻击无效
		if(HaveBuff(target,ESBUFF_WuMianAndGetFaDamageAdd))
			return 1;
	}
	
	if(damage < 1)
		damage = 1;
	if(pActive->effect_type == ESkill_Active_Attack)
	{
		damage *= (pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel-1))/10000.0;
		damage += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
		selfDamage = 0;
	}
	else if(pActive->effect_type == ESkill_Active_AttackByHpPer)
	{
		damage = (pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel - 1))/10000.0 * pTarget->hp;
		int damageLimit = pSrc->unitAttr.attack * ((pActive->para[1] + pActive->para_levelAdd[1] * (skillLevel - 1))/10000.0);
		if(damage > damageLimit)
			damage = damageLimit;
		damage += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
		selfDamage = 0;
	}
	else if(pActive->effect_type == ESkill_Active_AttackByDesHp)
	{
		int needHp = (pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel - 1))/10000.0 * GetMaxHp(src);
		if(pSrc->hp < needHp)
			needHp = pSrc->hp;
		damage = needHp*((pActive->para[1] + pActive->para_levelAdd[1] * (skillLevel - 1))/10000.0) + pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
		selfDamage = needHp;
	}
	else if(pActive->effect_type == ESkill_Active_Wait)
	{
		damage *= (pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel-1))/10000.0;
		damage += pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel-1);
		selfDamage = 0;
	}
	
	if(damage <= 0)
		damage = 1;
	
	float zhengshangLv = CalUnitZengShangLv(src,target,attackType,GetAttrValue(tarAttrList,ESkill_PassAttr_ImproveMianShangLv));
	float addDamPercent = CalUnitAddShangHaiLv(src,target,attackType);
	float offsetDamRatio = CalUnitShangHaiJianMianLv(src,target,attackType);
	damage += GetAttrValue(attrList,ESkill_PassAttr_Damage);
	addDamPercent += GetAttrValue(attrList,ESkill_PassAttr_DamagePer)/10000.0;
	if(showFightLog)
		cout<<", src="<<(int)src<<",  target="<<(int)target<<", SkillDamageB = "<<damage<<", zhengshangLv="<<zhengshangLv<<", addDamPercent="<<addDamPercent<<", offsetDamRatio="<<offsetDamRatio<<endl;

	damage *= zhengshangLv * addDamPercent * offsetDamRatio;

	int extAddDam = pSrc->GetSkillExtDataPara(skillId,1);
	if(extAddDam > 0)
	{
		int times = pSrc->GetSkillExtDataPara(skillId,2);
		if(times > 0)
			damage *= (1 + (times-1)*(extAddDam/(float)times)/10000.0);
	}
	return damage;
}

int64 CFight::GetMaxHp(uint8 pos)
{
	if((pos < 1) || (pos > MAX_MEMBER))
		return 0;
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;

	int64 maxHp = p->unitAttr.maxHp;
//	CUser *pU = NULL;
//	int myPos = pos;
//	if(pos <= GROUP2_BEGIN)
//	{
//		pU = GetUser(GROUP1_MAIN_POS);
//	}
//	else
//	{
//		myPos -= GROUP2_BEGIN;
//		pU = GetUser(GROUP2_MAIN_POS);
//	}

//	GetQunXianAttrWithGainValue(16,maxHp,pos);
	return maxHp;
}

int64 CFight::GetHp(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;
	return p->hp;
}

int CFight::GetBingDongRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn)
{
	if(skillId != 103)
		return 0;

	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 0;

	int value = pSrc->jiaQiangBingDong - pTarget->kangBingDong;
	if(value < 0)
		value = 0;

	value = (int)(value/10.0 + (8 + 0.5*(skillLevel-1)));
	if(value > 100)
		value = 100;
	skillTurn = 3;
	return value;
}

int CFight::CalculateSealRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn)
{
	if(skillId != 107)
		return 0;
	
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 0;
	
	int value = pSrc->jiaQiangSeal - pTarget->kangSeal + skillLevel*45;
	GetQunXianAttrWithGainValue(8,value,target);

	int ratio = 3500 + value*100/45;	// 1~10000
	if(ratio > 10000)
		ratio = 10000;
	else if(ratio < 0)
		ratio = 0;
	skillTurn = 2;
	return ratio;
}

int CFight::GetHunShuiRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn)
{
	if(skillId != 102 && skillId != 105)
		return 0;

	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 0;

	int value = pSrc->jiaQiangHunShui;
	int kanHunShuiVal = pTarget->kangHunShui;
	GetQunXianAttrWithGainValue(8,kanHunShuiVal,target);
	value -= kanHunShuiVal;
	if(value < 0)
		value = 0;

	if(skillId == 102)	// 102
	{
		value = (int)(value/10.0 + (8 + 0.5*(skillLevel-1)));
		skillTurn = 3;
	}
	else	// 105
	{
		value = (int)(value/10.0 + 20 + 0.75*(skillLevel-1));
		skillTurn = 2;
	}
	if(value > 100)
		value = 100;
	return value;
}

int CFight::GetHunLuanRatio(uint8 src,uint8 target,uint16 skillId,int skillLevel,int &skillTurn)
{
	if(skillId != 101 && skillId != 104 && skillId != 106 && skillId != 71)
		return 0;
	
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return 0;

	int value = pSrc->jiaQiangHunLuan;
	int hunluanVal = pTarget->kangHunLuan;
	GetQunXianAttrWithGainValue(8,hunluanVal,target);
	value -= hunluanVal;
	if(value < 0)
		value = 0;

	if(skillId == 101)	// 101
	{
		value = (int)(value/10.0 + (8 + 0.5*(skillLevel-1)));
		skillTurn = 3;
	}
	else if(skillId == 104 || skillId == 71)	// 104
	{
		value = (int)(value/10.0 + 20 + 0.75*(skillLevel-1));
		skillTurn = 2;
	}
	else if(skillId == 106)
	{
		value = (int)(value/10.0 + (20 + 0.75*(skillLevel-1)));
		skillTurn = 2;
	}
	if(value > 100)
		value = 100;
	return value;
}

int CFight::CalculateFanShang(uint8 src,uint8 target,int damage,vector<SAttrData> &attrList)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
		return -1;

	int fanzhenLv = pTarget->unitAttr.fanzhenLv*(1 - GetAttrValue(attrList,EAT_FanZhenLv)/10000.0) - pSrc->unitAttr.fanzhenkangLv;
	fanzhenLv += GetStatePara1(target,ESBUFF_FanZhengAllAdd) + GetStatePara1(target,ESBUFF_FanZhengLvAdd);
	int r = Random(1,10000);
	if(r <= fanzhenLv)
	{
		damage *= (pTarget->unitAttr.fanzhenAdd + GetStatePara2(target,ESBUFF_FanZhengAllAdd))/10000.0;
		if(damage < 1)
			damage = 1;
		return damage;
	}
	else
	{
		return -1;
	}
}

uint8 CFight::ChangeFightPos(uint8 src)
{
	return src;
}

uint8 CFight::CalculateSkill_AddHp(uint8 src,uint16 skillId,int skillLevel)
{
	if(m_forceEnd)
		return 0;
	if(skillId == 0 || skillLevel == 0)
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	
	uint8 allTarget[GROUP_MEMBER];
	uint8 tarNum = 0;
	GetSkillTargetRange(src,skillId,skillLevel,allTarget,tarNum);
	if(tarNum == 0)
		return 0;

	pSrc->target = allTarget[0];
	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	m_actionMsg<<(uint8)EFOT_AddHp<<src<<skillId;

	// 触发被动技能，加血时
	vector<ESkillTriggerType> triggerList;
	triggerList.push_back(ESkill_Trigger_AddHpSelfRatio);
	vector<SAttrData> selfAttrData;
	CalculatePassiveSkill_ExtValue(src,0,triggerList,selfAttrData,skillId,skillLevel);

	int moreHp = 0;	// 主目标溢出血量
	uint16 numPos = m_actionMsg.GetDataLen();
	uint8 num = 0;
	m_actionMsg<<num;
	for(int i=0;i < tarNum;i++)
	{
		uint8 tar = allTarget[i];
		// 禁止复活
		if(!IsAlive(tar) && HaveBuff(tar,ESBUFF_ForbidFuHuo))
			continue;
		
		// 触发被动技能，加血时
		vector<ESkillTriggerType> triggerList;
		triggerList.push_back(ESkill_Trigger_AddHp);
		vector<SAttrData> attrData;
		CalculatePassiveSkill_ExtValue(src,tar,triggerList,attrData,skillId,skillLevel);
		MergeAttrList(attrData,selfAttrData);

		triggerList.clear();
		triggerList.push_back(ESkill_Trigger_AddHpAndBuff);
		CalculatePassiveSkill_ExtUnitAndBuff(src,tar,triggerList,skillId,skillLevel,moreHp);
		
		int addHpPer = GetAttrValue(attrData,ESkill_PassAttr_AddHpPer);
		bool baoji = CalculateBaoJiRatio_AddHp(src,attrData);
		int addHp = GetSkillAddHpValue(src,tar,skillId,skillLevel);
		if(GetMaxHp(tar) > 0 && GetHp(tar) * 10000 / GetMaxHp(tar) < GetAffixValue(src,6,2))
			addHp = addHp * (10000 + GetAffixValue(src,6,1)) / 10000;
		if(baoji)
		{
			addHp = GetBaoJiDamage(src,addHp);
			if(HaveBuff(tar,ESBUFF_JinLiaoShu))
				addHp *= 1 - GetStatePara1(tar,ESBUFF_JinLiaoShu)/10000.0;
		}
		addHp *= -(1 + addHpPer/10000.0 + GetStatePara1(tar,ESBUFF_ImproveCureHp)/10000.0);

		int sHp = GetHp(tar);
		int absorpionHp = 0;
		DecreaseHp(tar, src, addHp,absorpionHp);
		int tempHp = sHp - GetHp(tar) - addHp;
		if(tempHp > moreHp)
			moreHp = tempHp;
		m_actionMsg<<tar<<(uint8)baoji<<-addHp;
		MakeBuffList(tar,m_actionMsg);
		num++;

		if(showFightLog)
			cout<<">>> addHp  skillId="<<skillId<<", src="<<(int)src<<", skillTarget="<<(int)tar<<", addHp="<<addHp<<", hp="<<GetHp(tar)<<endl;

		// 禁疗术伤血
		if(HaveBuff(tar,ESBUFF_JinLiaoShu))
		{
			PassiveAction(EFStep_CureHp,m_extActionMsg,tar,-addHp);
		}
	}
	m_actionMsg.WriteData(numPos,&num,sizeof(num));
//	MakeBuffList(src,m_actionMsg);

	if(moreHp > 0)
	{
		// 触发主目标回血溢出治疗全体
		vector<ESkillTriggerType> trigger;
		trigger.push_back(ESkill_Trigger_AddHp);
		CalculatePassiveSkill_ExtUnitAndBuff(src,0,trigger,skillId,skillLevel,moreHp);
	}
	return 1;
}

void CFight::ClearBuffNotMerge(uint8 target,SSkillBuff *pBuff)
{
	if(pBuff == NULL)
		return;
	if(GetFightMember(target) == NULL)
		return;
	for(uint16 k=0;k < pBuff->mutex_buffId.size();k++)
	{
		if(HaveBuff(target,pBuff->mutex_buffId[k]))
			ClearBuff(target,pBuff->mutex_buffId[k]);
	}
}

void CFight::GetPassivePara(uint8 src,vector<int> &para,SSkillAdditiveEffect *pActive,int skillLevel)
{
	para.clear();
	if(pActive == NULL)
		return;
	for(uint8 k=0;k < SSkillAdditiveEffect::MAX_PARA_NUM;k++)
	{
		int value = pActive->para[k] + pActive->para_levelAdd[k] * (skillLevel - 1);
		if(value != 0)
			para.push_back(value);
	}
}

void CFight::GetPassiveBuffPara(uint8 src,vector<int> &para,SSkillAdditiveEffect *pActive,int skillLevel)
{
	para.clear();
	if(pActive == NULL)
		return;
	
	for(uint8 k=0;k < SSkillAdditiveEffect::MAX_PARA_NUM;k++)
	{
		if(k == 3)
			continue;
		int value = pActive->para[k] + pActive->para_levelAdd[k] * (skillLevel - 1);
		if(pActive->buffId == ESBUFF_ShiXinDu && para.size() == 2)	// 添加伤害上限
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_ShiDu && para.size() == 1)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_FuDu && para.size() == 2)	// 添加伤害上限
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_ZhuoShao && para.size() == 1)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_JinGuZhou && para.size() == 2)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_AddHpContinue && para.size() == 1)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_Blooding && para.size() == 1)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_ShieldMianShang && para.size() == 1)
		{
			value = GetMaxHp(src) * (value/10000.0);
			para.push_back(value);
		}
		else if(pActive->buffId == ESBUFF_Shield && para.size() == 1)
		{
			value = GetMaxHp(src) * (value/10000.0);
			para.push_back(value);
		}
		if(value > 0)
			para.push_back(value);
	}
	
	if(pActive->buffId == ESBUFF_ChaoFeng)
		para.push_back(src);
	else if(pActive->buffId == ESBUFF_HunShui)
		para.push_back(3);
	else if(pActive->buffId == ESBUFF_Protect)
		para.push_back(src);
}

void CFight::GetBuffPara(uint8 src,vector<int> &para,SSkillActiveEffect *pActive,int skillLevel)
{
	para.clear();
	if(pActive == NULL)
		return;
	
	for(uint8 k=0;k < SSkillActiveEffect::MAX_PARA_NUM;k++)
	{
		if(k == 2)
			continue;
		int value = pActive->para[k] + pActive->para_levelAdd[k] * (skillLevel - 1);
//		if(pActive->buffId == ESBUFF_ShiDu)
//			value = GetUnitAttack(src) * (value/10000.0);
		if(pActive->buffId == ESBUFF_JinGuZhou && para.size() == 1)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_AddHpContinue)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_Blooding)
			value = GetUnitAttack(src) * (value/10000.0);
		else if(pActive->buffId == ESBUFF_ShieldMianShang && para.size() == 0)
		{
			value = GetMaxHp(src) * (value/10000.0);
			para.push_back(value);
		}
		else if(pActive->buffId == ESBUFF_Shield)
		{
			value = GetMaxHp(src) * (value/10000.0);
			para.push_back(value);
		}
		if(value > 0)
			para.push_back(value);
	}
	
	if(pActive->buffId == ESBUFF_ChaoFeng)
		para.push_back(src);
	else if(pActive->buffId == ESBUFF_HunShui)
		para.push_back(3);
	else if(pActive->buffId == ESBUFF_Protect)
		para.push_back(src);
}

uint8 CFight::CalculateSkill_AddBuff(uint8 src,uint16 skillId,int skillLevel)
{
	if(skillId == 0 || skillLevel == 0)
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;

	uint8 allTarget[GROUP_MEMBER];
	uint8 tarNum = 0;
	GetSkillTargetRange(src,skillId,skillLevel,allTarget,tarNum);
	if(tarNum == 0)
		return 0;

	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return 0;
	if(pSkillCfg->type == ESKILL_Passive) // 被动
		return 0;
	if(pSkillCfg->activeEffect.effectType != 1)
		return 0;
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL || pActive->buffId == 0)
		return 0;
	SSkillBuff *pBuff = mgr.GetBuffCfg(pActive->buffId);
	if(pBuff == NULL)
		return 0;
	pSrc->target = allTarget[0];
	uint8 effectTurn = pActive->para[2] + pActive->para_levelAdd[2] * (skillLevel - 1);

	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	m_actionMsg<<(uint8)EFOT_Buff<<src<<skillId;
	uint16 numPos = m_actionMsg.GetDataLen();
	uint8 num = 0;
	m_actionMsg<<num;
	for(uint8 i=0; i < tarNum; i++)
	{
		SFightMember *pTarget = GetFightMember(allTarget[i]);
		if(pTarget == NULL)
			continue;
		uint8 isActive = 0;
		if(!pTarget->InNotEffectBuff(pActive->buffId))
		{
			ClearBuffNotMerge(allTarget[i],pBuff);
			vector<int> para;
			GetBuffPara(src,para,pActive,skillLevel);

			vector<SAttrData> attrData;
			vector<ESkillTriggerType> trigger;
			if(pActive->buffId == ESBUFF_FanJian)
			{
				trigger.push_back(ESkill_Trigger_BeFanJian);
				CalculatePassiveSkill_ExtValue(src,0,trigger,attrData,skillId,skillLevel);
				int fanJianDamageRatio = GetAttrValue(attrData,ESkill_PassAttr_FanJianDamRatio);
				para.push_back(fanJianDamageRatio);
			}
			else if(pActive->buffId == ESBUFF_JinLiaoShu)
			{
				trigger.push_back(ESkill_Trigger_AddHpJinLiaoShu);
				CalculatePassiveSkill_ExtValue(src,0,trigger,attrData,skillId,skillLevel);
				int jinliaoDamageRatio = GetAttrValue(attrData,ESkill_PassAttr_JinLiaoShuDamRatio);
				para.push_back(jinliaoDamageRatio);
			}

			uint8 turn = (allTarget[i] == m_curActionPos) ? effectTurn+1 : effectTurn;
			AddBuff(allTarget[i], src, pActive->buffId, turn, &para);

			if(showFightLog)
				cout<<" src="<<(int)src<<", skillId="<<skillId<<", buffType="<<pActive->buffId<<" , skillTarget="<<(int)allTarget[i]<<endl;

			isActive = 1;	// 主动技能buff 必中
		}
		m_actionMsg<<allTarget[i]<<isActive;
		MakeBuffList(allTarget[i],m_actionMsg);
		num++;
	}
	m_actionMsg.WriteData(numPos,&num,sizeof(num));
//	MakeBuffList(src,m_actionMsg);
	return 1;
}

uint8 CFight::CalculateSkill_ClearBuff(uint8 src,uint16 skillId,int skillLevel)
{
	if(skillId == 0 || skillLevel == 0)
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	uint8 allTarget[GROUP_MEMBER];
	uint8 tarNum = 0;
	GetSkillTargetRange(src,skillId,skillLevel,allTarget,tarNum);
	if(tarNum == 0)
		return 0;

	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return 0;
	if(pSkillCfg->type == ESKILL_Passive) // 被动
		return 0;
	if(pSkillCfg->activeEffect.effectType != 1)
		return 0;
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL || pActive->buffId == 0)
		return 0;

	pSrc->target = allTarget[0];
	int buffId = pActive->buffId;
	int succRatio = pActive->para[0] + pActive->para_levelAdd[0] * (skillLevel - 1);

	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	m_actionMsg<<(uint8)EFOT_Buff<<src<<skillId;
	uint16 numPos = m_actionMsg.GetDataLen();
	uint8 num = 0;
	m_actionMsg<<num;
	for(uint8 i=0; i < tarNum; i++)
	{
		uint8 isActive = 0;
		int r = Random(1,10000);
		if(r <= succRatio)
		{
			isActive = 1;	// 驱散
			ClearMulBuff(allTarget[i],buffId,src);
		}

		m_actionMsg<<allTarget[i]<<isActive;
		MakeBuffList(allTarget[i],m_actionMsg);
		num++;
		
		if(showFightLog)
			cout<<" src="<<(int)src<<", skillId="<<skillId<<", buffType="<<pActive->buffId<<" , skillTarget="<<(int)allTarget[i]<<endl;
	}
	m_actionMsg.WriteData(numPos,&num,sizeof(num));
//	MakeBuffList(src,m_actionMsg);
	return 1;
}

void CFight::CalculatePassiveSkill_ExtAttrEffect(uint8 src,uint8 target,vector<ESkillTriggerType> &triggerList,vector<ESkillPassitiveType> passList,uint16 skillId,uint16 skillLevel,int value)
{
	if(m_forceEnd)
		return;
	if(triggerList.empty())
		return;
	if(!IsAlive(src))
		return;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return;

	vector<SSkillData> skillList;	// 所有被动技能+当前使用的主动技能列表
	if(skillId > 0 && skillLevel > 0)
		skillList.push_back(SSkillData(skillId,skillLevel));
	for(uint8 i=0;i < pSrc->passive_skill.size();i++)
		skillList.push_back(pSrc->passive_skill[i]);

	// 遍历每个被动技能
	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	for(uint16 i=0;i < skillList.size();i++)
	{
		SSkillData &skillData = skillList[i];
		for(uint16 j=0;j < triggerList.size();j++)
		{
			int trigger = triggerList[j];
			vector<int> passiveList;
			skillMgr.GetSkillPassiveData(skillData.id,trigger,passiveList);
			if(passiveList.empty())
				continue;
			for(uint16 k=0;k < passiveList.size();k++)
			{
				int passiveId = passiveList[k];
				SSkillAdditiveEffect *pEffect = skillMgr.GetAdditiveEffectCfg(passiveId);
				if(pEffect == NULL)
					continue;
				vector<int> para;
				GetPassivePara(src,para,pEffect,skillData.level);
				uint16 size = para.size();
				if(size < 1)
					continue;
				int passiveType = pEffect->type;
				if(!passList.empty())
				{
					if(std::find(passList.begin(),passList.end(),passiveType) == passList.end())
						continue;
				}
				if(passiveType != ESkill_Pass_ReduceCD)
				{
					int ratio = para[0];
					int r = Random(1,10000);
					if(r > ratio)	// 未生效
						continue;
				}

				uint16 showPassiveId = 0;
				uint8 showPos = 0;
				switch(trigger)
				{
					case ESkill_Trigger_DefAdd:
						{
							if(passiveType == ESkill_Pass_AddAttrByDecHp)
							{
								if(size < 3)
									break;
								int loseHpPer = 10000.0 * ((GetMaxHp(src) - GetHp(src)) / (float)GetMaxHp(src));
								int addNum = loseHpPer / para[2];
								int attrType = pEffect->buffId;
								pSrc->SetPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],addNum);
							}
						}
						break;
					case ESkill_Trigger_Action:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								int attrType = pEffect->buffId;
								pSrc->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
								showPassiveId = passiveId;
								showPos = src;
							}
							else if(passiveType == ESkill_Pass_DescSelfAllCD)
							{
								if(size < 2)
									break;
								int ratio = para[0];
								int r = Random(1,10000);
								if(r > ratio)	// 未生效
									break;
								pSrc->DecAllSkillCD(para[1]);
								showPassiveId = passiveId;
								showPos = src;
							}
						}
						break;
					case ESkill_Trigger_BeAttacked:
						{
							if(passiveType == ESkill_Pass_AddDamByAttacked)
							{
								if(size < 3)
									break;
								SFightLimitData *pData = pSrc->GetPassSkillLimitData(skillData.id,passiveType);
								if(pData != NULL)
								{
									int basicAttack = pSrc->unitAttr.attack - pData->_value;
									int addAttackLimit = basicAttack * (para[2] / 10000.0);
									if(pData->_value < addAttackLimit)
									{
										pData->_value += value * (para[1] / 10000.0);
										if(pData->_value > addAttackLimit)
											pData->_value = addAttackLimit;
										pSrc->unitAttr.attack = basicAttack + pData->_value;
										showPassiveId = passiveId;
										showPos = src;
									}
								}
							}
						}
						break;
					case ESkill_Trigger_KillTarget:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								if(!IsAlive(target) && !HaveState(target, EFST_STATE_Escape))	// 死亡
								{
									int attrType = pEffect->buffId;
									pSrc->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
									showPassiveId = passiveId;
									showPos = src;
								}
							}
							else if(passiveType == ESkill_Pass_ReduceCD)
							{
								if(size < 2)
									break;
								if(pSrc->option == EOTSkill)
								{
									int ratio = para[0];
									for(uint8 count=0;count < value;count++)
									{
										int r = Random(1,10000);
										if(r > ratio)	// 未生效
											continue;
										pSrc->DecSkillCD(pSrc->para,para[1]);
										showPassiveId = passiveId;
										showPos = src;
									}
								}
							}
						}
						break;
					case ESkill_Trigger_FightBegin:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								uint8 mem[GROUP_MEMBER];
								uint8 num = 0;
								GetAnotherGroup(src,mem,num);
								for(uint8 count=0;count < num;count++)
								{
									if(IsAlive(mem[count]))
									{
										SFightMember *pTar = GetFightMember(mem[count]);
										if(pTar == NULL)
											continue;
										int attrType = pEffect->buffId;
										pTar->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
									}
								}
								showPassiveId = passiveId;
								showPos = src;
							}
						}
						break;
					case ESkill_Trigger_UnitDied:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								if(!IsAlive(target) && !HaveState(target, EFST_STATE_Escape))	// 死亡
								{
									int attrType = pEffect->buffId;
									pSrc->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
									showPassiveId = passiveId;
									showPos = src;
								}
							}
						}
						break;
					case ESkill_Trigger_FightBeginAddToAllUnit:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								if(!IsAlive(src))
									break;
								uint8 mem[GROUP_MEMBER];
								uint8 num = 0;
								GetMeGroup(src,mem,num);
								for(uint8 count=0;count < num;count++)
								{
									if(IsAlive(mem[count]))
									{
										SFightMember *pTar = GetFightMember(mem[count]);
										if(pTar == NULL)
											continue;
										int attrType = pEffect->buffId;
										pTar->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
									}
								}
								showPassiveId = passiveId;
								showPos = src;
							}
						}
						break;
					case ESkill_Trigger_HaveMeiHuoState:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								if(!IsAlive(src))
									break;
								int attrType = pEffect->buffId;
								pSrc->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
								showPassiveId = passiveId;
								showPos = src;
							}
						}
						break;
					case ESkill_Trigger_MemberDied:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								if(IsSameGroup(src,target))
								{
									if(!IsAlive(target) && !HaveState(target, EFST_STATE_Escape))	// 死亡
									{
										int attrType = pEffect->buffId;
										pSrc->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
										showPassiveId = passiveId;
										showPos = src;
									}
								}
							}
						}
						break;
					case ESkill_Trigger_FightBegin_MaxAttackEnemy:
						{
							if(passiveType == ESkill_Pass_Attr)
							{
								if(size < 3)
									break;
								uint8 maxAttackPos = 0;
								uint8 member[GROUP_MEMBER];
								uint8 num = 0;
								GetAnotherGroup(src,member,num);
								if(num > 0)
								{
									GetSkillTargetSelCondition(member,num,ESkill_Select_MaxDamage);
									maxAttackPos = member[0];
								}

								SFightMember *pMem = GetFightMember(maxAttackPos);
								if(pMem != NULL)
								{
									int attrType = pEffect->buffId;
									pMem->AddPassSkillLimitAttrData(skillData.id,passiveType,attrType,para[1],1,para[2]);
									showPassiveId = passiveId;
									showPos = maxAttackPos;
								}
							}
							else if(passiveType == ESkill_Pass_DescAttackAndAddToSelf)
							{
								if(size < 2)
									break;
								uint8 maxAttackPos = 0;
								uint8 member[GROUP_MEMBER];
								uint8 num = 0;
								GetAnotherGroup(src,member,num);
								if(num > 0)
								{
									GetSkillTargetSelCondition(member,num,ESkill_Select_MaxDamage);
									maxAttackPos = member[0];
								}

								SFightMember *pMem = GetFightMember(maxAttackPos);
								if(pMem != NULL)
								{
									int decAttack = pMem->unitAttr.attack * (para[1]/10000.0);
									pMem->unitAttr.attack -= decAttack;
									pSrc->unitAttr.attack += decAttack;
									showPassiveId = passiveId;
									showPos = src;
								}
							}
						}
						break;
					default:
						break;
				}

				if(showPassiveId > 0 && showPos > 0)
				{
					uint16 actionNum = m_extActionMsg.GetType() + 1;
					m_extActionMsg.SetType(actionNum);
					m_extActionMsg<<(uint8)EFOT_Passive<<showPos<<showPassiveId<<pEffect->showStr<<(uint8)0;
				}
			}
		}
	}
}


// 触发被动附加伤害
// 返回值：> 0 附加伤害值，<=0 无附加伤害
void CFight::CalculatePassiveSkill_ExtValue(uint8 src,uint8 target,vector<ESkillTriggerType> &triggerList,vector<SAttrData> &attr,uint16 skillId,uint16 skillLevel,int value)
{
	if(m_forceEnd)
		return;

	attr.clear();
	if(triggerList.empty())
		return;
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pSrc == NULL)
		return;

	vector<SSkillData> skillList;	// 所有被动技能+当前使用的主动技能列表
	if(skillId > 0 && skillLevel > 0)
		skillList.push_back(SSkillData(skillId,skillLevel));
	for(uint8 i=0;i < pSrc->passive_skill.size();i++)
		skillList.push_back(pSrc->passive_skill[i]);

	// 遍历每个被动技能
	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	for(uint16 i=0;i < skillList.size();i++)
	{
		SSkillData &skillData = skillList[i];
		for(uint16 j=0;j < triggerList.size();j++)
		{
			int trigger = triggerList[j];
			vector<int> passiveList;
			skillMgr.GetSkillPassiveData(skillData.id,trigger,passiveList);
			if(passiveList.empty())
				continue;
			for(uint16 k=0;k < passiveList.size();k++)
			{
				int passiveId = passiveList[k];
				SSkillAdditiveEffect *pEffect = skillMgr.GetAdditiveEffectCfg(passiveId);
				if(pEffect == NULL)
					continue;
				vector<int> para;
				GetPassivePara(src,para,pEffect,skillData.level);
				uint16 size = para.size();
				if(size < 1)
					continue;
				int passiveType = pEffect->type;
				int ratio = para[0];
				int r = Random(1,10000);
				if(r > ratio)	// 未生效
					continue;
				SAttrData t;
				switch(trigger)
				{
					case ESkill_Trigger_DefAdd:
						{
							if(passiveType == ESkill_Pass_AddMianShangByHpLimitL)
							{
								if(size < 3)
									break;
								int hpPer = 10000.0 * (pSrc->hp / (float)GetMaxHp(src));
								if(hpPer < para[1])
								{
									t.attrType = ESkill_PassAttr_ImproveMianShangLv;
									t.attrValue = para[2];
								}
							}
						}
						break;
					case ESkill_Trigger_Attacking:
						{
							if(passiveType == ESkill_Pass_AddDamByMaxFang)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_Damage;
								t.attrValue = max(pSrc->unitAttr.fafang,pSrc->unitAttr.wufang) * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_AddDamBySelfHpLimitL)
							{
								if(size < 3)
									break;
								int hpPer = 10000.0 * (pSrc->hp / (float)GetMaxHp(src));
								if(hpPer < para[1])
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[2];
								}
							}
							else if(passiveType == ESkill_Pass_AddDamByTarHpLimitH)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int hpPer = 10000.0 * (pTarget->hp / (float)GetMaxHp(target));
								if(hpPer > para[1])
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[2];
								}
							}
							else if(passiveType == ESkill_Pass_AddBaoJiByHpLimitL)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int hpPer = 10000.0 * (pTarget->hp / (float)GetMaxHp(target));
								if(hpPer < para[1])
								{
									t.attrType = ESkill_PassAttr_BaoJiLv;
									t.attrValue = para[2];
								}
							}
							else if(passiveType == ESkill_Pass_AddDamDun)
							{
								if(size < 2)
									break;
								if(HaveShieldState(target))
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_IgnoreDun)
							{
								t.attrType = ESkill_PassAttr_IgnoreDun;
								t.attrValue = 1;
							}
							else if(passiveType == ESkill_Pass_AddDamBySelfMaxHp)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_Damage;
								t.attrValue = GetMaxHp(src) * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_AddDamByPercent)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_Damage;
								t.attrValue = pSrc->unitAttr.attack * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_IgnoreFang)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_HuShiFang;
								t.attrValue = para[1];
							}
							else if(passiveType == ESkill_Pass_AddDamByHpMoreThanSelf)
							{
								if(size < 2)
									break;
								if(pTarget == NULL)
									break;
								if(pTarget->hp > pSrc->hp)
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_IgnoreOtherAttr)
							{
								if(size < 2)
									break;
								t.attrType = pEffect->buffId;
								t.attrValue = para[1];
							}
							else if(passiveType == ESkill_Pass_AddDamByTarHpLimitL)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int hpPer = 10000.0 * (pTarget->hp / (float)GetMaxHp(target));
								if(hpPer < para[1])
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[2];
								}
							}
							else if(passiveType == ESkill_Pass_AddDamByTarHpPercent)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int damage = pTarget->hp * (para[1] / 10000.0);
								int damLimit = pSrc->unitAttr.attack * (para[2] / 10000.0);
								damage = (damage > damLimit) ? damLimit : damage;
								t.attrType = ESkill_PassAttr_Damage;
								t.attrValue = damage;
							}
							else if(passiveType == ESkill_Pass_CureTarHp)	// 为施法者自己加血
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								t.attrType = ESkill_PassAttr_AddHp;
								t.attrValue = (pTarget->hp) * (para[1] / 10000.0);
								int damLimit = pSrc->unitAttr.attack * (para[2] / 10000.0);
								t.attrValue = (t.attrValue > damLimit) ? damLimit : t.attrValue;
							}
							else if(passiveType == ESkill_Pass_DescAttackUnitHp)	// 先攻击后扣血
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_AddHp;
								t.attrValue = - GetMaxHp(src) * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_AddBaoJiLvByHpLimitH)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int hpPer = 10000.0 * (pTarget->hp / (float)GetMaxHp(target));
								if(hpPer > para[1])
								{
									t.attrType = ESkill_PassAttr_BaoJiLv;
									t.attrValue = para[2];
								}
							}
							else if(passiveType == ESkill_Pass_AddTempAttr)
							{
								if(size < 2)
									break;
								t.attrType = pEffect->buffId;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_TurnBegin:
						{
							if(passiveType == ESkill_Pass_AddSelfHpByLoseHp)
							{
								if(size < 2)
									break;
								int lostHp = GetMaxHp(src) - pSrc->hp;
								t.attrType = ESkill_PassAttr_AddHp;
								t.attrValue = lostHp * (para[1] / 10000.0);
							}

						}
						break;
					case ESkill_Trigger_BeAttacked:
						{
							if(passiveType == ESkill_Pass_AddFanJiRatio)
							{
								if(size < 3)
									break;
								t.attrType = ESkill_PassAttr_FanJiLv;
								t.attrValue = para[1];
								if(HaveBuff(target,ESBUFF_ChaoFeng))
									t.attrValue += para[2];
							}
							else if(passiveType == ESkill_Pass_ZhaoHuan)
							{
								if(size < 3)
									break;
								t.attrType = ESkill_PassAttr_FanJiLv;
								t.attrValue = para[1];
								AddToAttrList(attr,t);
								t.attrType = ESkill_PassAttr_FanJiAdd;
								t.attrValue = para[2];
							}
							else if(passiveType == ESkill_Pass_FanTanBySelfMaxHp)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_FanShang;
								t.attrValue = pSrc->hp * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_ReduceDamage)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_DamagePer;
								t.attrValue = -para[1];
							}
						}
						break;
					case ESkill_Trigger_BeFanJian:
						{
							if(passiveType == ESkill_Pass_AddDamage)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_FanJianDamRatio;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_KillTarget:
						{
							if(passiveType == ESkill_Pass_AddHp)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_AddHp;
								t.attrValue = GetMaxHp(target) * (para[1] / 10000.0);
							}
							else if(passiveType == ESkill_Pass_RandomAttackMinHp)
							{
								if(size < 2)
									break;
								SFightLimitData *pData = pSrc->GetPassSkillLimitData(skillData.id,passiveType,0,true);
								if(pData != NULL && pData->_count < para[1])
								{
									pData->_count++;
									if(pData->_count >= para[1])
										pSrc->killUnit_ext_IsLimit = true;
									t.attrType = ESkill_PassAttr_NormalAttack;
									t.attrValue = 1;
								}
							}
							else if(passiveType == ESkill_Pass_UseSkillAgain)
							{
								if(pSrc->option == EOTSkill)
								{
									t.attrType = ESkill_PassAttr_UseSameSkill;
									t.attrValue = 1;
								}
							}
							else if(passiveType == ESkill_Pass_UseFirstSkillAgain)
							{
								t.attrType = ESkill_PassAttr_UseSameSkill;
								t.attrValue = 1;
								pSrc->option = EOTSkill;
								pSrc->para = pSrc->skill_list[0].id;
							}
						}
						break;
					case ESkill_Trigger_AttackZhongDu:
						{
							if(passiveType == ESkill_Pass_AddDamage)
							{
								if(size < 2)
									break;
								if(HaveZhongDuState(target))
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_AddTempAttr)
							{
								if(size < 2)
									break;
								t.attrType = pEffect->buffId;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_AttackDebuff:
						{
							if(passiveType == ESkill_Pass_AddDamage)
							{
								if(size < 2)
									break;
								if(HaveDeBuffState(target))
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_ImproveFuMian)
							{
								if(size < 2)
									break;
								if(HaveDeBuffState(target))
								{
									t.attrType = ESkill_PassAttr_FuMian;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_AddTempAttr)
							{
								if(size < 2)
									break;
								t.attrType = pEffect->buffId;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_AddHpJinLiaoShu:
						{
							if(passiveType == ESkill_Pass_AddDamByAddHp)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_JinLiaoShuDamRatio;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_AddHp:
						{
							if(passiveType == ESkill_Pass_ImproveCureByTarHpLimitL)
							{
								if(size < 3)
									break;
								if(pTarget == NULL)
									break;
								int hpPer = 10000.0 * (pTarget->hp / (float)GetMaxHp(target));
								if(hpPer < para[1])
								{
									t.attrType = ESkill_PassAttr_AddHpPer;
									t.attrValue = para[2];
								}
							}
						}
						break;
					case ESkill_Trigger_MinHpBeAttacked:
						{
							if(passiveType == ESkill_Pass_ShareDamage)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_protectDamage;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_AttackingZhuoShang:
						{
							if(passiveType == ESkill_Pass_AddDamage)
							{
								if(size < 2)
									break;
								if(HaveBuff(target,ESBUFF_ZhuoShao))
								{
									t.attrType = ESkill_PassAttr_DamagePer;
									t.attrValue = para[1];
								}
							}
							else if(passiveType == ESkill_Pass_AddTempAttr)
							{
								if(size < 2)
									break;
								t.attrType = pEffect->buffId;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_AttackByZhiSi:
						{
							if(passiveType == ESkill_Pass_AddSelfHpToMaxByDieOneTime)
							{
								if(size < 2)
									break;
								SFightLimitData *pData = pSrc->GetPassSkillLimitData(skillData.id,passiveType);
								if(pData != NULL && pData->_count == 0)
								{
									pData->_count++;
									t.attrType = ESkill_PassAttr_AddHpPer;
									t.attrValue = para[1];
								}
							}
						}
						break;
					case ESkill_Trigger_MemberAction:
						{
							if(passiveType == ESkill_Pass_AddHpBySelfAttack)	// 为目标加血
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_AddHp;
								t.attrValue = pSrc->unitAttr.attack * (para[1] / 10000.0);
							}
						}
						break;
					case ESkill_Trigger_AddHpSelfRatio:
						{
							if(passiveType == ESkill_Pass_ImproveAddHpEffect)
							{
								if(size < 2)
									break;
								t.attrType = ESkill_PassAttr_AddHpPer;
								t.attrValue = para[1];
							}
						}
						break;
					case ESkill_Trigger_BeAttackedWuBeforeDecHp:
						{
							if(passiveType == ESkill_Pass_NotBeAttacked)
							{
								t.attrType = ESkill_PassAttr_NotDecHp;
								t.attrValue = 1;
							}
						}
						break;
					case ESkill_Trigger_AfterAttack:
						{
							if(passiveType == ESkill_Pass_FastAttackAgain)
							{
								if(IsAlive(target) && std::find(m_actionList.begin(),m_actionList.end(),target) == m_actionList.end())
								{
									t.attrType = ESkill_PassAttr_AttackActionAgain;
									t.attrValue = 1;
								}
							}
						}
						break;
					default:
						break;
				}

				if(t.attrType > 0 && t.attrValue > 0)
					AddToAttrList(attr,t);
			}
		}
	}
}

void CFight::GetPassiveSkill_Target(vector<uint8> &allTarget,int trigger,int additiveId,uint8 src,uint8 target,uint16 buffId)
{
	allTarget.clear();
	
	uint8 member[GROUP_MEMBER];
	uint8 num=0;
	switch(trigger)
	{
		case ESkill_Trigger_Attacking:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					if(target > 0)
					{
						allTarget.push_back(target);
					}
				}
				else if(additiveId == ESkill_Pass_SameDamToAnother)
				{
					if(target > 0)
					{
						GetAnotherGroupExceptTar(src,target,member,num);
						if(num >= 1)
							allTarget.push_back(member[Random(1,num)-1]);
					}
				}
				else if(additiveId == ESkill_Pass_NotMove)
				{
					allTarget.push_back(src);
				}
				else if(additiveId == ESkill_Pass_ClearBuff)
				{
					if(target > 0)
					{
						allTarget.push_back(target);
					}
				}
				else if(additiveId == ESkill_Pass_DamageToMoreUnit)
				{
					if(buffId == 0)
						return;
					if(target > 0)
					{
						GetAnotherGroupExceptTar(src,target,member,num);
						for(uint8 i=0;i < num;i++)
						{
							if(member[i] == target)
								continue;
							if(HaveBuff(member[i],buffId))
								allTarget.push_back(member[i]);
						}
					}
				}
				else if(additiveId == ESkill_Pass_CureTarHp)
				{
					allTarget.push_back(src);
				}
			}
			break;
		case ESkill_Trigger_Action:
			{
				if(additiveId == ESkill_Pass_AddBuff)
					allTarget.push_back(src);
				else if(additiveId == ESkill_Pass_Attr)
					allTarget.push_back(src);
				else if(additiveId == ESkill_Pass_ClearSpecBuff)
				{
					GetMeGroupExceptSelf(src,member,num);
					if(num > 1)
						GetSkillTargetSelCondition(member,num,ESkill_Select_DeBuff);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
				else if(additiveId == ESkill_Pass_ClearBuff_Self)
				{
					allTarget.push_back(src);
				}
				else if(additiveId == ESkill_Pass_AddBuffForMemberMinHp)
				{
					GetMeGroupExceptSelf(src,member,num);
					if(num > 1)
						GetSkillTargetSelCondition(member,num,ESkill_Select_MinCurHpPer);
					allTarget.push_back(member[0]);
				}
				else if(additiveId == ESkill_Pass_ClearSpecOneBuff)
				{
					if(buffId == 0)
						return;
					GetMeGroupExceptSelf(src,member,num);
					for(uint8 i=0;i < num;i++)
					{
						if(HaveBuff(member[i],buffId))
							allTarget.push_back(member[i]);
					}
				}
				else if(additiveId == ESkill_Pass_CureMinHpUnit)
				{
					GetMeGroup(src,member,num);
					if(num > 1)
						GetSkillTargetSelCondition(member,num,ESkill_Select_MinCurHpPer);
					if(num > 0)
						allTarget.push_back(member[0]);
				}
			}
			break;
		case ESkill_Trigger_TurnBegin:
			{
				if(additiveId == ESkill_Pass_ClearBuff_Self)
				{
					allTarget.push_back(src);
				}
				else if(additiveId == ESkill_Pass_AddBuffByRandom)
				{
					GetAnotherGroup(src,member,num);
					if(num >= 1)
						allTarget.push_back(member[Random(1,num)-1]);
				}
				else if(additiveId == ESkill_Pass_AddSelfHpByLoseHp)
				{
					allTarget.push_back(src);
				}
			}
			break;
		case ESkill_Trigger_BeAttacked:
			{
				if(additiveId == ESkill_Pass_AddBuff)
					allTarget.push_back(src);
				else if(additiveId == ESkill_Pass_AddDamByAttacked)
					allTarget.push_back(src);
				else if(additiveId == ESkill_Pass_AddBuffToAttackUnit)
				{
					if(target > 0)
						allTarget.push_back(target);
				}
			}
			break;
		case ESkill_Trigger_KillTarget:
			{
				if(additiveId == ESkill_Pass_AddHp)
				{
					allTarget.push_back(src);
				}
				else if(additiveId == ESkill_Pass_RandomAttackMinHp)
				{
					GetAnotherGroup(src,member,num);
					if(num > 0)
					{
						if(num > 1)
							GetSkillTargetSelCondition(member,num,ESkill_Select_MinCurHp);
						allTarget.push_back(member[0]);
					}
				}
			}
			break;
		case ESkill_Trigger_SelfDied:
			{
				if(additiveId == ESkill_Pass_FuHuo)
				{
					allTarget.push_back(src);
				}
			}
			break;
		case ESkill_Trigger_AttackingAddSelfBuff:
			{
				if(additiveId == ESkill_Pass_AddBuff)
					allTarget.push_back(src);
			}
			break;
		case ESkill_Trigger_SelfShieldMiss:
			{
				if(additiveId == ESkill_Pass_DunDamage)
				{
					GetAnotherGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		case ESkill_Trigger_DecHpLarge:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					allTarget.push_back(src);
				}
			}
			break;
		case ESkill_Trigger_UnitDied:
			{
				if(additiveId == ESkill_Pass_FuHuoFirstDieMem)	// 复活第一个死亡单位
				{
					if(target > 0)
						allTarget.push_back(target);
				}
			}
			break;
		case ESkill_Trigger_AddHp:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					if(target > 0)
						allTarget.push_back(target);
				}
				else if(additiveId == ESkill_Pass_CureAllMember)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		case ESkill_Trigger_AttackingAddBuff:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					allTarget.push_back(src);
					GetMeGroupExceptSelf(src,member,num);
					if(num >= 1)
						allTarget.push_back(member[Random(1,num)-1]);
				}
			}
			break;
		case ESkill_Trigger_AttackingAddToAllUnit:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		case ESkill_Trigger_FightBeginAddToAllUnit:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
				else if(additiveId == ESkill_Pass_ImproveCure)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		case ESkill_Trigger_ActionAddSelfMaxAttack:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					allTarget.push_back(src);
					GetMeGroupExceptSelf(src,member,num);
					if(num > 0)
					{
						if(num > 1)
							GetSkillTargetSelCondition(member,num,ESkill_Select_MaxDamage);
						allTarget.push_back(member[0]);
					}
				}
			}
			break;
		case ESkill_Trigger_BeAttackedWu:
			{
				if(additiveId == ESkill_Pass_AddBuffToAttackUnit)
				{
					if(target > 0)
						allTarget.push_back(target);
				}
			}
			break;
		case ESkill_Trigger_ClearEnBuff:
			{
				if(additiveId == ESkill_Pass_AddBuffWhenClear)
				{
					allTarget.push_back(src);
				}
			}
			break;
		case ESkill_Trigger_MemberAction:
			{
				if(additiveId == ESkill_Pass_AddHpBySelfAttack)
				{
					if(target > 0)
						allTarget.push_back(target);
				}
			}
			break;
		case ESkill_Trigger_DieAndAddToAllUnit:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
				else if(additiveId == ESkill_Pass_AddHpByPercent)
				{
					GetMeGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		case ESkill_Trigger_AddAttrBeginFight:
			{
				if(additiveId == ESkill_Pass_AddBuff)
					allTarget.push_back(src);
			}
			break;
		case ESkill_Trigger_AfterAttackUnit:
			{
				if(additiveId == ESkill_Pass_DescAttackUnitHp)
					allTarget.push_back(src);
				else if(additiveId == ESkill_Pass_DescAttackUnitHpPercent)
					allTarget.push_back(src);
			}
			break;
		case ESkill_Trigger_TurnBegin_RandSelfOne:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					GetMeGroup(src,member,num);
					if(num > 0)
					{
						uint8 r = Random(1,num) - 1;
						allTarget.push_back(member[r]);
					}
				}
			}
			break;
		case ESkill_Trigger_AddHpAndBuff:
			{
				if(additiveId == ESkill_Pass_AddBuff)
				{
					if(target > 0)
						allTarget.push_back(target);
				}
			}
			break;
		case ESkill_Trigger_DieAndAddToOtherUnit:
			{
				if(additiveId == ESkill_Pass_ExtDamageBySelfMaxHpPercent)
				{
					GetAnotherGroup(src,member,num);
					for(uint8 i=0;i < num;i++)
						allTarget.push_back(member[i]);
				}
			}
			break;
		default:
			break;
	}
}

bool CFight::IsPassiveToBuff(int trigger,int additiveId)
{
	if(trigger < 1 || additiveId < 1)
		return false;
	
	switch(additiveId)
	{
		case ESkill_Pass_AddBuff:
			{
				switch(trigger)
				{
					case ESkill_Trigger_Attacking:
					case ESkill_Trigger_Action:
					case ESkill_Trigger_BeAttacked:
					case ESkill_Trigger_AttackingAddSelfBuff:
					case ESkill_Trigger_DecHpLarge:
					case ESkill_Trigger_AddHp:
					case ESkill_Trigger_AttackingAddBuff:
					case ESkill_Trigger_AttackingAddToAllUnit:
					case ESkill_Trigger_FightBeginAddToAllUnit:
					case ESkill_Trigger_ActionAddSelfMaxAttack:
					case ESkill_Trigger_DieAndAddToAllUnit:
					case ESkill_Trigger_AddAttrBeginFight:
					case ESkill_Trigger_TurnBegin_RandSelfOne:
					case ESkill_Trigger_AddHpAndBuff:
						return true;
					default:
						break;
				}
			}
			break;
		case ESkill_Pass_AddBuffByRandom:
			{
				if(trigger == ESkill_Trigger_TurnBegin)
				{
					return true;
				}
			}
			break;
		case ESkill_Pass_AddBuffForMemberMinHp:
			{
				if(trigger == ESkill_Trigger_Action)
				{
					return true;
				}
			}
			break;
		case ESkill_Pass_AddBuffToAttackUnit:
			{
				if(trigger == ESkill_Trigger_BeAttacked || trigger == ESkill_Trigger_BeAttackedWu)
				{
					return true;
				}
			}
			break;
		default:
			break;
	}

	return false;
}

void CFight::CalculatePassiveSkill_ActionBuff(uint8 src,uint8 target,const vector<ESkillTriggerType> &triggerList)
{
	if(m_forceEnd)
		return;
	if(triggerList.empty())
		return;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return;
	
	vector<SSkillData> skillList;	// 所有被动技能+当前使用的主动技能列表
	for(uint8 i=0;i < pSrc->passive_skill.size();i++)
		skillList.push_back(pSrc->passive_skill[i]);
	
	vector<uint8> extPos;	// otherMsg
	vector<int> extAddHp;	// otherMsg
	vector<int> extAbsorpionHp; // otherMsg
	vector<int> extFuhuoHp; // otherMsg
	
	// 遍历每个被动技能
	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	for(uint16 i=0;i < skillList.size();i++)
	{
		SSkillData &skillData = skillList[i];
		for(uint16 j=0;j < triggerList.size();j++)
		{
			int trigger = triggerList[j];
			vector<int> passiveList;
			skillMgr.GetSkillPassiveData(skillData.id,trigger,passiveList);
			if(passiveList.empty())
				continue;
			for(uint16 k=0;k < passiveList.size();k++)
			{
				vector<uint8> actPos;	// extActionMsg
				vector<int> actAddHp;	// extActionMsg
				vector<int> actAbsorpionHp; // extActionMsg
				vector<int> actFuhuoHp; // extActionMsg
				int passiveId = passiveList[k];
				SSkillAdditiveEffect *pEffect = skillMgr.GetAdditiveEffectCfg(passiveId);
				if(pEffect == NULL)
					continue;
				int additiveId = pEffect->type;
				// 取目标
				vector<uint8> allTarget;
				GetPassiveSkill_Target(allTarget,trigger,additiveId,src,target,pEffect->buffId);
				if(allTarget.empty())
					continue;
	
				vector<int> para;
				// 取配置
				GetPassivePara(src,para,pEffect,skillData.level);
				uint16 size = para.size();
				if(size < 1)
					continue;
				int ratio = para[0];
				int r = Random(1,10000);
				if(r > ratio)	// 未生效
					continue;
	
				for(uint8 k=0;k < allTarget.size();k++)
				{
					uint8 tar = allTarget[k];
					if(tar == 0)
						continue;
					int addType = 0;	// 1 extPos 2 actPos
					uint8 pos = 0;
					int addValue = 0;
					int absorpionHp = 0;
					int fuhuoHp = 0;
					switch(trigger)
					{
						case ESkill_Trigger_Action:
							{
								if(additiveId == ESkill_Pass_ClearBuff_Self)
								{
									if(size < 2)
										break;
									int debuffNum = para[1];
									ClearRandomDeBuff(tar,debuffNum);

									addType = 2;
									pos = tar;
									addValue = 0;
								}
							}
							break;
						default:
							break;
					}
	
					if(addType == 1)	// extPos
					{
						extPos.push_back(pos);
						extAddHp.push_back(addValue);
						extAbsorpionHp.push_back(absorpionHp);
						extFuhuoHp.push_back(fuhuoHp);
					}
					else if(addType == 2)	// actPos
					{
						actPos.push_back(pos);
						actAddHp.push_back(addValue);
						actAbsorpionHp.push_back(absorpionHp);
						actFuhuoHp.push_back(fuhuoHp);
					}
				}
	
				uint8 actSize = actPos.size();
				if(actSize > 0)
				{
					uint16 actionNum = m_extActionMsg.GetType() + 1;
					m_extActionMsg.SetType(actionNum);
					m_extActionMsg<<(uint8)EFOT_Passive<<src<<(uint16)passiveId<<pEffect->showStr<<actSize;
					for(uint8 i=0;i < actSize;i++)
					{
						m_extActionMsg<<actPos[i]<<actAddHp[i]<<actAbsorpionHp[i]<<actFuhuoHp[i];
						MakeBuffList(actPos[i],m_extActionMsg);
					}
				}
			}
		}
	}

	uint8 size = extPos.size();
	uint16 count = 0;
	for(uint8 i=0;i < size;i++)
	{
		if(extPos[i] == 0)
			continue;
		m_otherMsg<<extPos[i]<<extAddHp[i]<<extAbsorpionHp[i]<<extFuhuoHp[i];
		MakeBuffList(extPos[i],m_otherMsg);
		count++;
	}
	if(count > 0)
	{
		uint8 otherNum = m_otherMsg.GetType() + count;
		m_otherMsg.SetType(otherNum);
	}
}

// return 0 normal, 1 破盾并反弹伤害
int CFight::CalculatePassiveSkill_ExtUnitAndBuff(uint8 src,uint8 target,const vector<ESkillTriggerType> &triggerList,uint16 skillId,uint16 skillLevel,int val,vector<SAttrData> *attrData,bool turnEnd,SFightBuffData *buffData)
{
	if(m_forceEnd)
		return 0;
	if(triggerList.empty())
		return 0;
	SFightMember *pSrc = GetFightMember(src);
//	SFightMember *pTarget = GetFightMember(target);
	if(pSrc == NULL)
		return 0;

	int res = 0;
	vector<SSkillData> skillList;	// 所有被动技能+当前使用的主动技能列表
	if(skillId > 0 && skillLevel > 0)
		skillList.push_back(SSkillData(skillId,skillLevel));
	for(uint8 i=0;i < pSrc->passive_skill.size();i++)
		skillList.push_back(pSrc->passive_skill[i]);

	vector<uint8> extPos;	// otherMsg
	vector<int> extAddHp;	// otherMsg
	vector<int> extAbsorpionHp;	// otherMsg
	vector<int> extFuhuoHp;	// otherMsg

	// 遍历每个被动技能
	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	for(uint16 i=0;i < skillList.size();i++)
	{
		SSkillData &skillData = skillList[i];
		for(uint16 j=0;j < triggerList.size();j++)
		{
			int trigger = triggerList[j];
			vector<int> passiveList;
			skillMgr.GetSkillPassiveData(skillData.id,trigger,passiveList);
			if(passiveList.empty())
				continue;
			for(uint16 k=0;k < passiveList.size();k++)
			{
				vector<uint8> actPos;	// extActionMsg
				vector<int> actAddHp;	// extActionMsg
				vector<int> actAbsorpionHp;	// extActionMsg
				vector<int> actFuhuoHp; // extActionMsg
				int passiveId = passiveList[k];
				SSkillAdditiveEffect *pEffect = skillMgr.GetAdditiveEffectCfg(passiveId);
				if(pEffect == NULL)
					continue;
				int additiveId = pEffect->type;
				// 取目标
				vector<uint8> allTarget;
				GetPassiveSkill_Target(allTarget,trigger,additiveId,src,target,pEffect->buffId);
				if(allTarget.empty())
					continue;

				// buff
				vector<int> para;
				if(IsPassiveToBuff(trigger,additiveId))
				{
					if(trigger == ESkill_Trigger_DecHpLarge && additiveId == ESkill_Pass_AddBuff)
					{
						int damLimit = GetMaxHp(src) * 0.3;
						if(val < damLimit)
							continue;
					}
					if(pEffect->buffId == 0)
						continue;
					SSkillBuff *pBuff = skillMgr.GetBuffCfg(pEffect->buffId);
					if(pBuff == NULL)
						continue;
					GetPassiveBuffPara(src,para,pEffect,skillData.level);
					uint16 size = para.size();
					if(size < 1)
						continue;
					uint8 effectTurn = pEffect->para[3] + pEffect->para_levelAdd[3] * (skillData.level - 1);
					int ratio = para[0];	// 概率
					vector<int> passPara;
					if(size > 1)
						passPara.assign(para.begin()+1,para.end());
					for(uint8 k=0;k < allTarget.size();k++)
					{
						uint8 tar = allTarget[k];
						if(tar == 0)
							continue;
						if(pEffect->buffId != ESBUFF_ForbidFuHuo)
						{
							if(!IsAlive(tar))
								continue;
						}
						if(pBuff->type == 1)	// 增益
						{
							if(Random(1,10000) > ratio) // 未生效
								continue;
						}
						else	// 减益
						{
							SFightMember *pOther = GetFightMember(tar);
							if(pOther == NULL)
								continue;
							if(pOther->InNotEffectBuff(pEffect->buffId))
								continue;
							int deRatio = pSrc->unitAttr.fumianAdd + ratio + GetStatePara1(src,ESBUFF_FuMianQiangHuaAdd);
							if(attrData != NULL)
							{
								deRatio += GetAttrValue(*attrData,ESkill_PassAttr_FuMian);
								deRatio -= pOther->unitAttr.fumianKangAdd * (1 - GetAttrValue(*attrData,EAT_FuMianKangAdd)/10000.0);
							}
							else
							{
								deRatio -= pOther->unitAttr.fumianKangAdd;
							}
							deRatio -= GetStatePara1(tar,ESBUFF_FuMianKangAdd) - GetStatePara1(tar,ESBUFF_FuMianKangDes);
							if(pEffect->buffId == ESBUFF_ShiXinDu || pEffect->buffId == ESBUFF_ShiDu || pEffect->buffId == ESBUFF_FuDu)
								deRatio -= GetStatePara1(tar,ESBUFF_ZhongDuKangAdd) + GetAttrValue(pOther->passive_attr,ESkill_Pass_AddZhongDuKang);
							if(Random(1,10000) > deRatio) // 未生效
								continue;
						}
						
						if(pEffect->buffId == ESBUFF_FanJian)
						{
							vector<SAttrData> fanjianAttrData;
							vector<ESkillTriggerType> fanjianTrigger;
							fanjianTrigger.push_back(ESkill_Trigger_BeFanJian);
							CalculatePassiveSkill_ExtValue(src,0,fanjianTrigger,fanjianAttrData,skillId,skillLevel);
							passPara.push_back(GetAttrValue(fanjianAttrData,ESkill_PassAttr_FanJianDamRatio));
						}
						else if(pEffect->buffId == ESBUFF_JinLiaoShu)	// 禁疗术特殊处理
						{
							vector<SAttrData> jinliaoAttrData;
							vector<ESkillTriggerType> jinliaoTrigger;
							jinliaoTrigger.push_back(ESkill_Trigger_AddHpJinLiaoShu);
							CalculatePassiveSkill_ExtValue(src,0,jinliaoTrigger,jinliaoAttrData,skillId,skillLevel);
							passPara.push_back(GetAttrValue(jinliaoAttrData,ESkill_PassAttr_JinLiaoShuDamRatio));
						}
						
//						ClearBuffNotMerge(tar,pBuff);
						uint8 turn = (tar == m_curActionPos) ? effectTurn+1 : effectTurn;
						AddBuff(tar, src, pEffect->buffId, turn, &passPara);
						
						if(additiveId == ESkill_Pass_AddBuffForMemberMinHp
							|| (trigger == ESkill_Trigger_TurnBegin && additiveId == ESkill_Pass_AddBuffByRandom)
							|| (trigger == ESkill_Trigger_Action && additiveId == ESkill_Pass_ClearSpecOneBuff)
							|| (trigger == ESkill_Trigger_AddAttrBeginFight && additiveId == ESkill_Pass_AddBuff))
						{
							if(std::find(actPos.begin(),actPos.end(),tar) == actPos.end())
							{
								actPos.push_back(tar);
								actAddHp.push_back(0);
								actAbsorpionHp.push_back(0);
								actFuhuoHp.push_back(0);
							}
						}
						else if(trigger == ESkill_Trigger_AddHpAndBuff && additiveId == ESkill_Pass_AddBuff) // 加血时加buff，该类型此处不添加至数据包，由调用该接口处处理数据
						{
							continue;
						}
						else
						{
							if(std::find(extPos.begin(),extPos.end(),tar) == extPos.end())
							{
								extPos.push_back(tar);
								extAddHp.push_back(0);
								extAbsorpionHp.push_back(0);
								extFuhuoHp.push_back(0);
							}
						}
					}
				}
				else	// 非buff(伤血，加血等)
				{
					// 取配置
					GetPassivePara(src,para,pEffect,skillData.level);
					uint16 size = para.size();
					if(size < 1)
						continue;
					int ratio = para[0];
					int r = Random(1,10000);
					if(r > ratio)	// 未生效
						continue;

					for(uint8 k=0;k < allTarget.size();k++)
					{
						uint8 tar = allTarget[k];
						if(tar == 0)
							continue;
						int addType = 0;	// 1 extPos 2 actPos
						uint8 pos = 0;
						int addValue = 0;
						int absorpionHp = 0;
						int fuhuoHp = 0;
						switch(trigger)
						{
							case ESkill_Trigger_Attacking:
								{
									if(additiveId == ESkill_Pass_SameDamToAnother)
									{
										DecreaseHp(tar, src, val, absorpionHp, false, &fuhuoHp);

										addType = 1;
										pos = tar;
										addValue = -val;
									}
									else if(additiveId == ESkill_Pass_NotMove)
									{
										if(size < 2)
											break;
										uint8 turn = para[1] + 1;
										AddBuff(tar,ESBUFF_NOT_MOVE,turn);
									}
									else if(additiveId == ESkill_Pass_ClearBuff)
									{
										if(size < 2)
											break;
										ClearRandomEnBuff(tar,para[1],src);
									}
									else if(additiveId == ESkill_Pass_DamageToMoreUnit)
									{
										if(size < 2)
											break;
										int damage = val * (para[1] / 10000.0);
										DecreaseHp(tar, src, damage, absorpionHp, false, &fuhuoHp);

										addType = 1;
										pos = tar;
										addValue = -damage;
									}
									else if(additiveId == ESkill_Pass_CureTarHp)
									{
										if(size < 3)
											break;
										int addHp = GetHp(target) * (para[1] / 10000.0);
										int damLimit = pSrc->unitAttr.attack * (para[2] / 10000.0);
										addHp = -((addHp > damLimit) ? damLimit : addHp);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);

										addType = 1;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_Action:
								{
									if(additiveId == ESkill_Pass_ClearSpecBuff)
									{
										if(size < 3)
											break;
										uint8 maxTarNum = para[1];
										if(k >= maxTarNum)
											break;
										uint8 deBuffNum = para[2];
										ClearRandomDeBuff(tar,deBuffNum);

										addType = 2;
										pos = tar;
										addValue = 0;

										// 额外触发被动效果
//										m_extActionMsg.SetType(m_extActionMsg.GetType() + 1);
//										m_extActionMsg<<(uint8)EFOT_Passive<<src<<(uint16)passiveId<<pEffect->showStr<<(uint8)0;
									}
									else if(additiveId == ESkill_Pass_ClearSpecOneBuff)
									{
										ClearBuff(tar,pEffect->buffId);

										addType = 2;
										pos = tar;
										addValue = 0;
									}
									else if(additiveId == ESkill_Pass_CureMinHpUnit)
									{
										int addHp = -GetMaxHp(tar) * (para[1] / 10000.0);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);
										addType = 1;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_TurnBegin:
								{
									if(additiveId == ESkill_Pass_ClearBuff_Self)
									{
										if(size < 2)
											break;
										int debuffNum = para[1];
										ClearRandomDeBuff(tar,debuffNum);

										addType = 2;
										pos = tar;
										addValue = 0;
									}
									else if(additiveId == ESkill_Pass_AddSelfHpByLoseHp)
									{
										if(size < 2)
											break;
										int loseHp = GetMaxHp(tar) - GetHp(tar);
										int addHp = - loseHp * (para[1] / 10000.0);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);

										addType = 2;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_KillTarget:
								{
									if(additiveId == ESkill_Pass_AddHp)
									{
										if(size < 2)
											break;
										if(HaveState(target, EFST_STATE_Die))
										{
											int addHp = -GetMaxHp(tar) * (para[1] / 10000.0);
											DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);
											addType = 1;
											pos = tar;
											addValue = -addHp;
										}
									}
								}
								break;
							case ESkill_Trigger_SelfDied:
								{
									if(additiveId == ESkill_Pass_FuHuo)
									{
										if(size < 2)
											break;
										if(HaveBuff(tar,ESBUFF_ForbidFuHuo))
											break;
										if(HaveState(tar, EFST_STATE_Die))
										{
											ClearState(tar, EFST_STATE_Die);
											DelDieUnit(tar);

											int hp = -GetMaxHp(tar) * (para[1] / 10000.0);
											DecreaseHp(tar, src, hp, absorpionHp, false, &fuhuoHp);
											addType = 2;
											pos = tar;
											addValue = -hp;
										}
									}
								}
								break;
							case ESkill_Trigger_SelfShieldMiss:
								{
									if(additiveId == ESkill_Pass_DunDamage)
									{
										if(size < 2)
											break;
										int damage = val * (para[1] / 10000.0);
										DecreaseHp(tar, src, damage, absorpionHp, false, &fuhuoHp);

										if(turnEnd)
											addType = 2;
										else
											addType = 1;
										pos = tar;
										addValue = -damage;
										res = 1;	// 破盾
									}
								}
								break;
							case ESkill_Trigger_UnitDied:
								{
									if(additiveId == ESkill_Pass_FuHuoFirstDieMem)
									{
										if(size < 2)
											break;
										if(IsAlive(tar))
											break;
										if(HaveBuff(tar,ESBUFF_ForbidFuHuo))
											break;
										SFightLimitData *pData = pSrc->GetPassSkillLimitData(skillData.id,additiveId);
										if(pData != NULL && pData->_count == 0)
										{
											pData->_count++;
											int addHp = -GetMaxHp(tar) * (para[1] / 10000.0);
											DecreaseHp(tar, src, addHp, absorpionHp);

											addType = 2;
											pos = tar;
											addValue = 0;
											fuhuoHp = -addHp;
										}
									}
								}
								break;
							case ESkill_Trigger_AddHp:
								{
									if(additiveId == ESkill_Pass_CureAllMember)
									{
										if(size < 2)
											break;
										int addHp = - val * (para[1] / 10000.0);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);	// 加血

										addType = 1;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_FightBeginAddToAllUnit:
								{
									if(additiveId == ESkill_Pass_ImproveCure)
									{
										if(size < 2)
											break;
										uint8 turn = 0xff;
										vector<int> statePara;
										statePara.push_back(para[1]);
										AddBuff(tar, src, ESBUFF_ImproveCureHp,turn,&statePara);

										addType = 2;
										pos = tar;
										addValue = 0;
									}
								}
								break;
							case ESkill_Trigger_ClearEnBuff:
								{
									if(additiveId == ESkill_Pass_AddBuffWhenClear)
									{
										if(size < 2)
											break;
										if(buffData != NULL)
										{
											uint8 turn = (tar == m_curActionPos) ? para[1]+1 : para[1];
											AddBuff(tar, src, buffData->id, turn, &(buffData->paraList));

											addType = 2;
											pos = tar;
											addValue = 0;
										}
									}
								}
								break;
							case ESkill_Trigger_MemberAction:
								{
									if(additiveId == ESkill_Pass_AddHpBySelfAttack)
									{
										if(size < 2)
											break;
										int addHp = - pSrc->unitAttr.attack * (para[1] / 10000.0);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);	// 加血

										addType = 2;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_DieAndAddToAllUnit:
								{
									if(additiveId == ESkill_Pass_AddHpByPercent)
									{
										if(size < 2)
											break;
										int addHp = - GetMaxHp(tar) * (para[1] / 10000.0);
										DecreaseHp(tar, src, addHp, absorpionHp, false, &fuhuoHp);	// 加血

										addType = 1;
										pos = tar;
										addValue = -addHp;
									}
								}
								break;
							case ESkill_Trigger_AfterAttackUnit:
								{
									if(additiveId == ESkill_Pass_DescAttackUnitHp)
									{
										if(size < 2)
											break;
										int damage = GetMaxHp(tar) * (para[1] / 10000.0);
										DecreaseHp(tar, src, damage, absorpionHp, false, &fuhuoHp);
									
										addType = 1;
										pos = tar;
										addValue = -damage;
									}
									else if(additiveId == ESkill_Pass_DescAttackUnitHpPercent)
									{
										if(size < 2)
											break;
										int damage = GetHp(tar) * (para[1] / 10000.0);
										DecreaseHp(tar, src, damage, absorpionHp, false, &fuhuoHp);
									
										addType = 1;
										pos = tar;
										addValue = -damage;
									}
								}
								break;
							case ESkill_Trigger_DieAndAddToOtherUnit:
								{
									if(additiveId == ESkill_Pass_ExtDamageBySelfMaxHpPercent)
									{
										if(size < 3)
											break;
										int damage = GetMaxHp(src) * (para[1] / 10000.0);
										int damLimit = GetUnitAttack(src) * (para[2] / 10000.0);
										damage = damage > damLimit ? damLimit : damage;
										DecreaseHp(tar, src, damage, absorpionHp, false, &fuhuoHp);	// 扣血

										addType = 1;
										pos = tar;
										addValue = -damage;
									}
								}
								break;

							default:
								break;
						}

						if(addType == 1)	// extPos
						{
							extPos.push_back(pos);
							extAddHp.push_back(addValue);
							extAbsorpionHp.push_back(absorpionHp);
							extFuhuoHp.push_back(fuhuoHp);
						}
						else if(addType == 2)	// actPos
						{
							actPos.push_back(pos);
							actAddHp.push_back(addValue);
							actAbsorpionHp.push_back(absorpionHp);
							actFuhuoHp.push_back(fuhuoHp);
						}
					}
				}

				uint8 size = actPos.size();
				if(size > 0)
				{
					uint16 actionNum = m_extActionMsg.GetType() + 1;
					m_extActionMsg.SetType(actionNum);
					m_extActionMsg<<(uint8)EFOT_Passive<<src<<(uint16)passiveId<<pEffect->showStr<<size;
					for(uint8 i=0;i < size;i++)
					{
						m_extActionMsg<<actPos[i]<<actAddHp[i]<<actAbsorpionHp[i]<<actFuhuoHp[i];
						MakeBuffList(actPos[i],m_extActionMsg);
					}
				}
			}
		}
	}


	uint8 size = extPos.size();
	uint16 count = 0;
	for(uint8 i=0;i < size;i++)
	{
		if(extPos[i] == 0)
			continue;
		m_otherMsg<<extPos[i]<<extAddHp[i]<<extAbsorpionHp[i]<<extFuhuoHp[i];
		MakeBuffList(extPos[i],m_otherMsg);
		count++;
	}
	if(count > 0)
	{
		uint8 otherNum = m_otherMsg.GetType() + count;
		m_otherMsg.SetType(otherNum);
	}
	return res;
}

// isFanji=false 为第一次攻击，需要额外计算保护和反震伤害
// return 0正常 1闪避，异常也闪避
uint8 CFight::BasicFightAction(uint8 src,uint8 target,uint16 skillId,uint16 skillLevel,int &selfDamage,vector<SAttrData> &attrData,vector<SAttrData> &tarAttrData,bool isFanji,bool firstAttack)
{
	SFightMember *pSrc = GetFightMember(src);
	SFightMember *pTarget = GetFightMember(target);
	if(pTarget == NULL || pSrc == NULL)
	{
		if(showFightLog)
			cout<<"--  src="<<(int)src<<", target="<<(int)target<<", skill="<<skillId<<LANGUAGE_TRANSFORM_620<<endl;
		m_actionMsg<<(uint8)EHIT_ShanBi;
		return 1;
	}

	// V1特殊词条使用既有战斗属性通道，不改写技能/装备老协议。
	// 猎命：低生命目标提高暴击率与暴击伤害。
	if(pTarget->unitAttr.maxHp > 0 && pTarget->hp * 10000 / pTarget->unitAttr.maxHp < 3000)
	{
		int critRate = GetAffixValue(src,17,1);
		int critDamage = GetAffixValue(src,17,2);
		if(critRate > 0)
			attrData.push_back(SAttrData(EAT_BaoJiLv,critRate));
		if(critDamage > 0)
			attrData.push_back(SAttrData(EAT_BaoJiAdd,critDamage));
	}

	// 趁虚而入：受控目标更易命中，伤害加成在基础伤害产生后结算。
	bool targetControlled = HaveBuff(target,ESBUFF_ChaoFeng) || HaveBuff(target,ESBUFF_ChenMo)
		|| HaveBuff(target,ESBUFF_FengYin) || HaveBuff(target,ESBUFF_HunShui)
		|| HaveBuff(target,ESBUFF_HunLuan) || HaveBuff(target,ESBUFF_MeiHuo)
		|| HaveBuff(target,ESBUFF_FanJian) || HaveBuff(target,ESBUFF_NOT_MOVE);
	if(targetControlled)
	{
		int hitAdd = GetAffixValue(src,32,2);
		if(hitAdd > 0)
			attrData.push_back(SAttrData(EAT_MingZhongLv,hitAdd));
	}
	
	// 命中
	int hitRatio = CalculateHitRatio(src,target);
	int r = Random(1,10000);
	if(r > hitRatio)	// 闪避
	{
		if(showFightLog)
			cout<<"--  src="<<(int)src<<", target="<<(int)target<<", skill="<<skillId<<" , random="<<r<<", hitRatio="<<hitRatio<<LANGUAGE_TRANSFORM_620<<endl;
		m_actionMsg<<(uint8)EHIT_ShanBi;
		return 1;
	}

	m_actionMsg<<(uint8)EHIT_MingZhong;

	bool ignoreDun = (GetAttrValue(attrData,ESkill_PassAttr_IgnoreDun) > 0) ? true : false;
	int damage = 0;
	int absorpionHp = 0;
	if(skillId == 0)
	{
		damage = CalculateDamage(src,target,attrData,tarAttrData);
		if(isFanji)	// 计算反击伤害
		{
			damage *= (pSrc->unitAttr.fanjiAdd + GetAttrValue(attrData,ESkill_PassAttr_FanJiAdd))/10000.0;
			if(damage < 1)
				damage = 1;
		}
	}
	else
	{
		damage = CalculateSkillDamage(src,target,skillId,skillLevel,selfDamage,attrData,tarAttrData);
	}

	int damageAdd = 0;
	if(!firstAttack && !isFanji)
		damageAdd += GetAffixValue(src,21,1); // 连击升温
	if(HaveShieldState(target))
		damageAdd += GetAffixValue(src,25,1); // 破盾剑意
	if(HaveBuff(target,ESBUFF_FaFangDes))
	{
		int ignoreDef = GetAffixValue(src,27,1); // 法防穿透
		if(ignoreDef > 0 && pSrc->attackType == 2)
			damage = damage * 10000 / (10000 - (ignoreDef > 9000 ? 9000 : ignoreDef));
	}
	if(targetControlled)
		damageAdd += GetAffixValue(src,32,1); // 趁虚而入
	if(HaveZhongDuState(target) || HaveBuff(target,ESBUFF_ZhuoShao) || HaveBuff(target,ESBUFF_Blooding))
		damageAdd += GetAffixValue(src,35,1); // 病入膏肓
	if(HaveDeBuffState(target))
	{
		int perDebuff = GetAffixValue(src,39,1);
		int maxDebuffs = GetAffixValue(src,39,2);
		int debuffCount = 0;
		for(list<SFightBuffData>::const_iterator it=pTarget->buff_list.begin();it!=pTarget->buff_list.end();++it)
		{
			SSkillBuff *pBuffCfg = SingletonCSkillMgr::instance().GetBuffCfg(it->id);
			if(pBuffCfg != NULL && pBuffCfg->type == 2)
				debuffCount++;
		}
		if(maxDebuffs > 0 && debuffCount > maxDebuffs)
			debuffCount = maxDebuffs;
		damageAdd += perDebuff * debuffCount;
	}
	if(damageAdd > 0)
		damage = damage * (10000 + damageAdd) / 10000;
	if(!firstAttack && !isFanji)	// 连击伤害，第二次攻击，且不是反击
	{
		damage *= (pSrc->unitAttr.lianjiAdd + GetAttrValue(attrData,EAT_LianJiAdd) + GetStatePara1(src,ESBUFF_LianJiLvShangHaiAdd))/10000.0;
	}
	
	if(showFightLog)
		cout<<"-- src="<<(int)src<<", target="<<(int)target<<", skill="<<skillId<<", random="<<r<<", hitRatio="<<hitRatio<<LANGUAGE_TRANSFORM_622<<damage;

	if(pSrc->type != EFMT_PET)
	{
		if(pTarget->celue == CL_ONLY_PET)
			damage /= 10;
		else if(pTarget->celue == ONLY_PET)
			damage = 1;
	}
	
	if(damage < 1)
		damage = 1;

	// 守势：战意达到阈值且本回合尚未释放战法时获得减伤。
	int targetGroup = target <= GROUP2_BEGIN ? EGT_GROUP1 : EGT_GROUP2;
	int guardThreshold = GetAffixValue(target,48,2);
	int guardReduction = GetAffixValue(target,48,1);
	if(guardReduction > 0 && GetTeamRage(target) >= guardThreshold && !m_tacticUsedThisTurn[targetGroup])
	{
		damage = damage * (10000 - guardReduction) / 10000;
		if(damage < 1)
			damage = 1;
	}
	int openingGuard = m_fightTurn < 2 ? GetTeamBestAffixValue(target,12,1) : 0;
	if(openingGuard > 0)
	{
		damage = damage * (10000 - openingGuard) / 10000;
		if(damage < 1)
			damage = 1;
	}

	uint8 protect = 0;
	int proDamage = 0;
	uint8 baoji = 0;	// 0不暴击1暴击
	uint8 fanzhen = 0;	// 0不反震1反震
	int fanzhenDamage = 0;
	int fuhuoHp = 0;
	// 暴击
	if(CalculateBaoJiRatio(src,target,damage,attrData)) // 暴击
	{
		if(pSrc->type != EFMT_PET && pTarget->celue == ONLY_PET)
			damage = 1;
		baoji = 1;
		if(showFightLog)
			cout<<LANGUAGE_TRANSFORM_623<<damage;
	}
	else
	{
		baoji = 0;
		if(showFightLog)
			cout<<LANGUAGE_TRANSFORM_624<<damage;
	}

	// 受击时免疫伤害
	vector<SAttrData> mianshangAttrData;
	vector<ESkillTriggerType> trigger;
	if(pSrc->attackType == 1)
		trigger.push_back(ESkill_Trigger_BeAttackedWuBeforeDecHp);
	CalculatePassiveSkill_ExtValue(target,0,trigger,mianshangAttrData,skillId,skillLevel);
	if(GetAttrValue(mianshangAttrData,ESkill_PassAttr_NotDecHp) > 0)
		damage = 0;

	if (showFightLog) // 显示战斗详细数据
		cout << LANGUAGE_TRANSFORM_627 << (int)src << LANGUAGE_TRANSFORM_628 << (int)target << LANGUAGE_TRANSFORM_629 << (int)skillId << LANGUAGE_TRANSFORM_631 << damage << endl;

	int srcDamage = damage;
	// 保护者计算
	if(!isFanji)	// 主动攻击
	{
		int protectDamagePer = 0;
		if(HaveBuff(target,ESBUFF_Protect))
		{
			protect = GetStatePara3(target,ESBUFF_Protect);
			protectDamagePer = GetStatePara1(target,ESBUFF_Protect);
		}
		// 触发被动分担伤害判定（没有保护者的情况下）
		if(protect == 0)
		{
			uint8 member[GROUP_MEMBER];
			uint8 num = 0;
			GetMeGroup(target, member, num);
			if(num > 0)
			{
				if(num > 1)
 					GetSkillTargetSelCondition(member,num,ESkill_Select_MinCurHp);
				uint8 yuanhuPos = FindYuanHuPos(target);
				if(yuanhuPos > 0 && target != yuanhuPos && target == member[0])
				{
					vector<SAttrData> attr;
					vector<ESkillTriggerType> trigger;
					trigger.push_back(ESkill_Trigger_MinHpBeAttacked);
					CalculatePassiveSkill_ExtValue(yuanhuPos, target, trigger, attr);
					protectDamagePer = GetAttrValue(attr, ESkill_PassAttr_protectDamage);
					if(protectDamagePer > 0)
						protect = yuanhuPos;
				}
 			}
		}
		damage *= (1 + GetAttrValue(tarAttrData,ESkill_PassAttr_DamagePer)/10000.0);
		if(damage < 0)
			damage = 1;
		if(protect > 0 && IsAlive(protect) && !HaveBuff(protect,ESBUFF_HunShui)) // 有保护者,活着,无昏睡
		{
			proDamage = damage * (protectDamagePer/10000.0);
			int shareReduction = GetAffixValue(protect,11,1);
			if(shareReduction > 0)
				proDamage = proDamage * (10000 - shareReduction) / 10000;
			damage *= (1 - protectDamagePer/10000.0);
			if(proDamage < 1)
				proDamage = 1;
			if(damage < 1)
				damage = 1;
			DecreaseHp(protect, src, proDamage, absorpionHp, false, &fuhuoHp);
			if(proDamage > 0)
				GrantDamageTakenRage(protect);
			DecHunShuiTimes(target);
			m_actionMsg<<protect<<proDamage<<absorpionHp<<fuhuoHp;
			MakeBuffList(protect,m_actionMsg);
			DecreaseHp(target, src, damage, absorpionHp, ignoreDun, &fuhuoHp);
			if(damage > 0)
				GrantDamageTakenRage(target);
			if(!IsAlive(protect))
				pSrc->AddKillUnit(protect);
		}
		else	// 无保护者
		{
			DecreaseHp(target, src, damage, absorpionHp, ignoreDun, &fuhuoHp);
			if(damage > 0)
				GrantDamageTakenRage(target);
			DecHunShuiTimes(target);
			protect = 0;
			m_actionMsg<<protect;
		}
		if(!IsAlive(target))
			pSrc->AddKillUnit(target);
	}
	else
	{
		DecreaseHp(target, src, damage, absorpionHp, ignoreDun, &fuhuoHp);
		if(damage > 0)
			GrantDamageTakenRage(target);
		DecHunShuiTimes(target);
	}

	m_actionMsg<<baoji<<damage<<absorpionHp<<fuhuoHp;

	if(!isFanji)	// 主动攻击 触发攻击时被动buff或加血，减血
	{
		if(firstAttack)
		{
			vector<ESkillTriggerType> trigger;
			trigger.push_back(ESkill_Trigger_KillTarget); // 击杀目标时
			vector<ESkillPassitiveType> passList;
			passList.push_back(ESkill_Pass_Attr);
			CalculatePassiveSkill_ExtAttrEffect(src,target,trigger,passList,skillId,skillLevel);

			// 攻击时
			trigger.clear();
			trigger.push_back(ESkill_Trigger_Attacking);
			trigger.push_back(ESkill_Trigger_KillTarget); // 击杀目标时
			trigger.push_back(ESkill_Trigger_AttackingAddSelfBuff);
			trigger.push_back(ESkill_Trigger_AttackingAddBuff);
			trigger.push_back(ESkill_Trigger_AttackingAddToAllUnit);
			CalculatePassiveSkill_ExtUnitAndBuff(src,target,trigger,skillId,skillLevel,srcDamage,&attrData);

			// 受击时
			vector<ESkillTriggerType> tarTrigger;
			tarTrigger.push_back(ESkill_Trigger_BeAttacked);
			vector<ESkillPassitiveType> tarPassList;
			tarPassList.push_back(ESkill_Pass_AddDamByAttacked);
			CalculatePassiveSkill_ExtAttrEffect(target,src,tarTrigger,tarPassList,skillId,skillLevel);
			
			tarTrigger.push_back(ESkill_Trigger_DecHpLarge);
			if(pSrc->attackType == 1)
				tarTrigger.push_back(ESkill_Trigger_BeAttackedWu);
			CalculatePassiveSkill_ExtUnitAndBuff(target,src,tarTrigger,0,0,srcDamage);
		}
	}

	if(!isFanji)	// 反震
	{
		if(m_forceEnd)	// 强制结束，没有反伤
		{
			m_actionMsg<<fanzhen;
		}
		else
		{
			// 反伤
			fanzhenDamage += CalculateFanShang(src,target,srcDamage,attrData) + GetAttrValue(tarAttrData,ESkill_PassAttr_FanShang);
			if(fanzhenDamage > 0)
			{
				fanzhen = 1;
				DecreaseHp(src, target, fanzhenDamage, absorpionHp, false, &fuhuoHp);
				m_actionMsg<<fanzhen<<fanzhenDamage<<absorpionHp<<fuhuoHp;
				if(OneGroupAllDie() == 3)	// all die
				{
					ClearState(src, EFST_STATE_Die);
					DelDieUnit(src);
				}
				if(showFightLog)
					cout<<LANGUAGE_TRANSFORM_632<<fanzhenDamage<<endl;
			}
			else
			{
				m_actionMsg<<fanzhen;
				if(showFightLog)
					cout<<LANGUAGE_TRANSFORM_633<<endl;
			}
		}
	}
	return 0;
}

uint8 CFight::CalculateOnceAction(uint8 src,uint8 target,uint16 skillId,uint16 skillLevel,int &selfDamage,bool firstAttack)
{
//	if(m_forceEnd)
//		return 0;
	if(!IsAlive(target))
		return 0;

	// 触发被动技能，被动增加伤害或特定属性
	vector<ESkillTriggerType> srcTrigger;
	srcTrigger.push_back(ESkill_Trigger_Attacking);
	srcTrigger.push_back(ESkill_Trigger_AttackZhongDu);
	srcTrigger.push_back(ESkill_Trigger_AttackDebuff);
	srcTrigger.push_back(ESkill_Trigger_AttackingZhuoShang);
	vector<SAttrData> srcAttrData;
	CalculatePassiveSkill_ExtValue(src,target,srcTrigger,srcAttrData,skillId,skillLevel);

	// 被击时
	vector<SAttrData> tarAttrData;
	vector<ESkillTriggerType> tarTrigger;
	tarTrigger.push_back(ESkill_Trigger_DefAdd);
	tarTrigger.push_back(ESkill_Trigger_BeAttacked);
	CalculatePassiveSkill_ExtValue(target,src,tarTrigger,tarAttrData);
	
	bool isFanji = false;
	uint8 res = BasicFightAction(src,target,skillId,skillLevel,selfDamage,srcAttrData,tarAttrData,isFanji,firstAttack);
	if(res == 1)
		return 1;

	// 反击
	uint16 fanjiPos = m_actionMsg.GetDataLen();
	uint8 fanji = 0;	// 0 不反击 1 反击
	m_actionMsg<<fanji;
	if(!m_forceEnd)
	{
		if(!IsAlive(target) || HaveBuff(target,ESBUFF_HunShui))
			return 1;
		if(CalculateFanJiRatio(src,target,srcAttrData,GetAttrValue(tarAttrData,ESkill_PassAttr_FanJiLv)))
		{
			fanji = 1;
			if(showFightLog)
				cout<<LANGUAGE_TRANSFORM_506<<(int)target<<endl;

			isFanji = true;
			int damage = 0;
			srcAttrData.clear();
			tarAttrData.clear();
			CalculatePassiveSkill_ExtValue(target,src,srcTrigger,srcAttrData);
			CalculatePassiveSkill_ExtValue(src,target,tarTrigger,tarAttrData);
			res = BasicFightAction(target,src,0,0,damage,srcAttrData,tarAttrData,isFanji,firstAttack);
			if(res == 2)
				fanji = 0;
			if(res == 0 && TryTriggerAffix(target,15) && Random(1,10000) <= GetAffixValue(target,15,1))
			{
				HeroSkillRoleCfg *pRoleCfg = SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(GetHeroId(target));
				if(pRoleCfg != NULL)
					m_members[target-1].DecSkillCD(pRoleCfg->regularSkillId,GetAffixValue(target,15,2));
			}
			m_actionMsg.WriteData(fanjiPos,&fanji,sizeof(fanji));
		}
	}
	return 1;
}

uint8 CFight::CalculateNormal_DamageHp(uint8 src,uint8 target)
{
	if(m_forceEnd)
		return 0;

	uint16 skillId = 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	if(!IsAlive(target))
	{
		uint8 allTarget[GROUP_MEMBER];
		uint8 tarNum = 0;
		GetAnotherGroupByAttackedOrder(src,allTarget,tarNum);
		if(tarNum == 0)
			return 0;
		target = allTarget[0];
	}

	pSrc->target = target;
	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	m_actionMsg<<(uint8)EFOT_DamageHp<<src<<skillId;

	uint16 lianjiPos = m_actionMsg.GetDataLen();
	uint8 lianjishu = 1;
	m_actionMsg<<lianjishu;
	if(CalculateLianJiRatio(src,target))	// 连击
		lianjishu = 2;

	uint8 lianjiNum = 0;
	int selfDamage = 0;
	for(uint8 j=0;j < lianjishu;j++)
	{
		if(m_forceEnd)
			break;
		if(!IsAlive(src) || !IsAlive(target))
			break;
		
		uint8 num = 0;
		uint16 tarNumPos = m_actionMsg.GetDataLen();
		m_actionMsg<<num;
		lianjiNum++;
		m_actionMsg<<target;
		int tSelfDam = 0;
		bool firstAttack = (j == 0 ? true : false);
		if(CalculateOnceAction(src,target,skillId,0,tSelfDam,firstAttack) > 0)
		{
			num++;
			MakeBuffList(target,m_actionMsg);
			if(selfDamage == 0)
				selfDamage = tSelfDam;
		}
		m_actionMsg.WriteData(tarNumPos,&num,sizeof(num));

		if(ShieldBrokenCheck(target))	// 破盾检测
			break;
	}
	m_actionMsg.WriteData(lianjiPos,&lianjiNum,sizeof(lianjiNum));
	if(lianjiNum > 1 && TryTriggerAffix(src,24))
		AddTeamRage(src,GetAffixValue(src,24,1));

	int absorpionHp = 0;
	int fuhuoHp = 0;
	if(!m_forceEnd)
	{
		if(selfDamage > 0)
			DecreaseHp(src, 0, selfDamage, absorpionHp, false, &fuhuoHp);
	}
	m_actionMsg<<-selfDamage<<absorpionHp<<fuhuoHp;
//	MakeBuffList(src,m_actionMsg);
	return 1;
}


uint8 CFight::CalculateSkill_DamageHp(uint8 src,uint16 skillId,int skillLevel)
{
	if(m_forceEnd)
		return 0;
	if(skillId == 0 || skillLevel == 0)
		return 0;
	uint8 allTarget[GROUP_MEMBER];
	uint8 tarNum = 0;
	GetSkillTargetRange(src,skillId,skillLevel,allTarget,tarNum);
	if(tarNum == 0)
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;

	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	m_actionMsg<<(uint8)EFOT_DamageHp<<src<<skillId;

	uint16 lianjiPos = m_actionMsg.GetDataLen();
	uint8 lianjishu = 1;
	m_actionMsg<<lianjishu;

	pSrc->target = allTarget[0];
	if(CalculateLianJiRatio(src,allTarget[0])) // 主单位判定连击数
		lianjishu = 2;

	uint8 lianjiNum = 0;
	int selfDamage = 0;	// 以血换血 扣血值
	for(uint8 j=0;j < lianjishu;j++)
	{
		if(m_forceEnd)
			break;
		if(!IsAlive(src))
			break;
		bool allDie = true;
		for(uint8 i = 0; i < tarNum; i++)
		{
			if(IsAlive(allTarget[i]))
			{
				allDie = false;
				break;
			}
		}
		if(allDie)
			break;
		
		bool isShieldBreak = false;
		uint16 tarNumPos = m_actionMsg.GetDataLen();
		uint8 num = 0;
		lianjiNum++;
		m_actionMsg<<num;
		for(uint8 i = 0; i < tarNum; i++)
		{
			uint8 tar = allTarget[i];
			if(!IsAlive(tar))
				continue;
			m_actionMsg<<tar;

			int tSelfDam = 0;
			bool firstAttack = (j == 0 ? true : false);
			if(CalculateOnceAction(src,tar,skillId,skillLevel,tSelfDam,firstAttack) > 0)
			{
				if(selfDamage == 0)
					selfDamage = tSelfDam;
				num++;
				MakeBuffList(tar,m_actionMsg);
			}

			if(ShieldBrokenCheck(tar))	// 破盾检测
			{
				isShieldBreak = true;
			}
		}
		m_actionMsg.WriteData(tarNumPos,&num,sizeof(num));

		vector<ESkillTriggerType> trigger;
		trigger.push_back(ESkill_Trigger_AfterAttackUnit);
		CalculatePassiveSkill_ExtUnitAndBuff(src,0,trigger,skillId,skillLevel);
		
		if(isShieldBreak)
			break;
	}
	m_actionMsg.WriteData(lianjiPos,&lianjiNum,sizeof(lianjiNum));
	if(lianjiNum > 1 && TryTriggerAffix(src,24))
		AddTeamRage(src,GetAffixValue(src,24,1));

	int absorpionHp = 0;
	int fuhuoHp = 0;
	if(!m_forceEnd)
	{
		if(selfDamage > 0)
			DecreaseHp(src, 0 , selfDamage, absorpionHp, false, &fuhuoHp);
	}
	m_actionMsg<<-selfDamage<<absorpionHp<<fuhuoHp;
//	MakeBuffList(src,m_actionMsg);
	return 1;
}

uint8 CFight::SkillButtle(uint8 src,uint16 skillId)
{
	if(m_forceEnd)
		return 0;
	if(skillId == 0)
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	int skillLevel = pSrc->GetSkillLevel(skillId);
	if(skillLevel == 0)
		return 0;
	pSrc->SetSkillCD(skillId);

	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return 0;
	if(pSkillCfg->type == ESKILL_Passive)
		return 0;
	if(pSkillCfg->activeEffect.effectType != 1)	// 配置异常
		return 0;
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL)
		return 0;
	
	// 检测被动168类型(技能伤害累加)
	vector<SSkillEffectCfg> &passEffect = pSkillCfg->passiveEffect;
	for(uint16 i=0;i < passEffect.size();i++)
	{
		vector<int> &passList = passEffect[i].effectIdList;
		for(uint16 j=0;j < passList.size();j++)
		{
			int passEffId = passList[j];
			SSkillAdditiveEffect *pPassEff = mgr.GetAdditiveEffectCfg(passEffId);
			if(pPassEff == NULL)
				continue;
			if(pPassEff->type == ESkill_Pass_AddTheSkillAttack)
			{
				int val = pPassEff->para[1] + (skillLevel - 1)*pPassEff->para_levelAdd[1];
				int maxTimes = pPassEff->para[2] + (skillLevel - 1)*pPassEff->para_levelAdd[2];
				if(maxTimes > pSrc->GetSkillExtDataPara(skillId,2))
				{
					vector<int> paraList;
					paraList.push_back(val);	// value
					paraList.push_back(1);		// count+1
					pSrc->AddSkillExtData(skillId,paraList);
				}
			}
		}
	}
	
	if(showFightLog)
	{
		cout<<"--- "<<(int)src<<" :use skill: "<<(int)skillId<<" to:"<<endl;
	}
	
	int skillType = pActive->effect_type;
	switch(skillType)
	{
		// 伤血技能
		case ESkill_Active_Attack:
//		case ESkill_Active_MulAttack:
		case ESkill_Active_AttackByHpPer:
		case ESkill_Active_AttackByDesHp:
			{
				return CalculateSkill_DamageHp(src,skillId,skillLevel);
			}
			break;
		// 加血
		case ESkill_Active_AddHpByDam:
		case ESkill_Active_AddHpNormal:
		case ESkill_Active_FuHuo:	// 复活
			{
				return CalculateSkill_AddHp(src,skillId,skillLevel);
			}
			break;
		// 等待一回合
		case ESkill_Active_Wait:
			{
				if(HaveBuff(src,ESBUFF_WaitForTurn))	// 第二回合攻击
				{
					ClearBuff(src,ESBUFF_WaitForTurn);
					pSrc->SetSkillCD(skillId);
					return CalculateSkill_DamageHp(src,skillId,skillLevel);
				}
				else	// 第一回合施放buff并等待
				{
					uint8 targetNum = 1;
					uint8 target = src;
					uint8 isActive = 1;	// 必中
					vector<int> para;
					para.push_back(skillId);
					AddBuff(src, src, ESBUFF_WaitForTurn,2,&para);
					para.clear();
					int extAdd = pActive->para[1]+pActive->para_levelAdd[1]*(skillLevel-1);
					para.push_back(extAdd);
					AddBuff(src, src, ESBUFF_MianShangTemp,1,&para);
					if(showFightLog)
						cout<<"-- src="<<(int)src<<", skillId="<<skillId<<", target="<<(int)target<<endl;
					uint16 actionNum = m_actionMsg.GetType() + 1;
					m_actionMsg.SetType(actionNum);
					m_actionMsg<<(uint8)EFOT_Buff<<src<<skillId<<targetNum<<target<<isActive;
					MakeBuffList(target,m_actionMsg);
//					MakeBuffList(src,m_actionMsg);
					return 1;
				}
			}
			break;
		// buff
		case ESkill_Active_AddBuff:
			{
				return CalculateSkill_AddBuff(src,skillId,skillLevel);
			}
			break;
		// clearBuff
		case ESkill_Active_ClearBuff:
			{
				return CalculateSkill_ClearBuff(src,skillId,skillLevel);
			}
			break;

		default:
			return 0;
	}
	return 0;
}

bool CFight::CanTaoPao(uint8 src)
{
	int r = Random(1,10000);
	int ratio = 10000;
	if(m_type == EFTBangPaiPK)
		ratio = 2500;
	else if(m_type == EFTKunLunShan)
		ratio = 2500;
	else if(m_type == EFT_FEI_XIAN)
		ratio = 2500;
	else if(m_type == EFTHuSong)
	{
		if(src <= GROUP2_BEGIN)
			ratio = 2500;
		else
			ratio = 0;
	}
	return (r <= ratio);
}

uint8 CFight::EscapeAction(uint8 src)
{
	CUser *pUser = GetUser(src);
	if(pUser == NULL || pUser->IsAutoFight())
		return 0;

	uint16 actionNum = m_actionMsg.GetType() + 1;
	m_actionMsg.SetType(actionNum);
	if(m_type == EFTMatch)
	{
		m_actionMsg<<(uint8)EFOT_Escape<<src<<PRO_ERROR<<(uint8)1<<src;
		return 1;
	}
	if(pUser->GetTeam() == pUser->GetRoleId())
	{
		if(!IsUserAllMemberDie(src))
		{
			m_actionMsg<<(uint8)EFOT_Escape<<src<<PRO_ERROR<<(uint8)1<<src;
			return 1;
		}
	}
	if(!CanTaoPao(src))
	{
		m_actionMsg<<(uint8)EFOT_Escape<<src<<PRO_ERROR<<(uint8)1<<src;
		return 1;
	}

	m_actionMsg<<(uint8)EFOT_Escape<<src<<PRO_SUCCESS;
	SetState(src, EFST_STATE_Escape);
	uint8 num = 1;
	uint16 numPos = m_actionMsg.GetDataLen();
	m_actionMsg<<num<<src;

	uint8 beginPos = 1;
	uint8 endPos = GROUP2_BEGIN;
	if(src > endPos)
	{
		beginPos = GROUP2_BEGIN+1;
		endPos = MAX_MEMBER;
	}
	for(uint8 petIdx=beginPos;petIdx <= endPos;petIdx++)
	{
		if(!IsEmpty(petIdx) && (m_members[petIdx-1].petOwner == src) && IsAlive(petIdx)) // 神将
		{
			num++;
			m_actionMsg<<(uint8)petIdx;
			SetState(petIdx, EFST_STATE_Escape);
		}
	}
	if(num > 1)
	{
		m_actionMsg.WriteData(numPos,&num,sizeof(num));
	}

	pUser->SetFightEndTime();
	if ((m_type == EFTPlayerPk) || (m_type == EFTPlayerQieCuo)) // pk和切磋不会有脚本回调
		pUser->SetCallFun("");
	return 1;
}

void CFight::MonsterSkillCeLue(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL || p->type != EFMT_MONSTER)
		return;
	switch(p->celue)
	{
		case CL_FY_XIONG_LANG:
			{
				uint8 skillNum = p->GetSkillNum();
				uint16 skillId = 0;
				p->option = EOTSkill;
				if(skillNum > 0)
				{
					if(Random(0,skillNum) != 0)
					{
						skillId = p->RandSelectSkill();
						p->option = EOTSkill;
						p->para = skillId;
					}
				}
				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
				}
				else
				{
					p->target = 0;
				}
				p->option = EOTSkill;
			}
			break;
		case CL_FIRST_MIN_FANG:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroup(pos+1,target,num);
//				uint32 recovery = 0xffffffff;
				for(uint8 i = 0; i < num; i++)
				{
					SFightMember *pTarget = GetFightMember(target[i]);
					if(pTarget != NULL)
					{
						if(pTarget->type == EFMT_PET || pTarget->type == EFMT_USER)
						{
//							if((uint32)pTarget->recovery < recovery)
//							{
//								p->target = target[i];
//								recovery = pTarget->recovery;
//							}
						}
					}
				}
			}
			break;
		case CE_HUAN_YING:
//			if((p->recovery < MAX_INT) && (!m_useZhaoHuanSkill))
//			{
//				p->option = EOTZhaoHuan;
//				p->para = 0;
//				p->target = 0;
//				m_useZhaoHuanSkill = true;
//			}
			break;
		case CL_TAO_PAO:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
				}
				else
				{
					p->target = 0;
				}
			}
			break;
		case CL_ZI_BAO:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
				}
				else
				{
					p->target = 0;
				}
			}
			break;
		case CL_WUXINGCHUANGGUAN1:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,100);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 10)
						p->para = 1;
					else if(r <= 20)
						p->para = 2;
					else if(r <= 30)
						p->para = 3;
					else if(r <= 70)
						p->para = 4;
					else if(r <= 95)
					{
						p->option = EOTSkill;
						p->para = 0;
					}
					else
						p->para = 54;
				}
				else
					p->target = 0;
			}
			break;
		case CL_WUXINGCHUANGGUAN2:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,100);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 5)
						p->para = 58;
					else if(r <= 45)
						p->para = 21;
					else if(r <= 60)
						p->para = 8;
					else if(r <= 75)
						p->para = 7;
					else
					{
						p->option = EOTSkill;
						p->para = 0;
					}
				}
				else
					p->target = 0;
			}
			break;
		case CL_WUXINGCHUANGGUAN3:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,100);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 5)
						p->para = 62;
					else if(r <= 20)
						p->para = 10;
					else if(r <= 35)
						p->para = 11;
					else if(r <= 75)
						p->para = 12;
					else
					{
						p->option = EOTSkill;
						p->para = 0;
					}
				}
				else
					p->target = 0;
			}
			break;
		case CL_WUXINGCHUANGGUAN4:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,100);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 5)
						p->para = 66;
					else if(r <= 20)
						p->para = 14;
					else if(r <= 35)
						p->para = 15;
					else if(r <= 75)
						p->para = 16;
					else
					{
						p->option = EOTSkill;
						p->para = 0;
					}
				}
				else
					p->target = 0;
			}
			break;
		case CL_WUXINGCHUANGGUAN5:
			{
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,100);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 5)
						p->para = 70;
					else if(r <= 20)
						p->para = 20;
					else if(r <= 35)
						p->para = 19;
					else if(r <= 75)
						p->para = 22;
					else
					{
						p->option = EOTSkill;
						p->para = 0;
					}
				}
				else
					p->target = 0;
			}
			break;
		case CL_QIYIBOLIZHU:
			{
				// 战斗
				uint8 target[GROUP2_BEGIN];
				uint8 num=0;
				uint8 r = Random(1,70);
				GetAnotherGroup(pos+1,target,num);
				if(num > 0)
				{
					p->target = RandSelect(target,num);
					p->option = EOTSkill;
					if(r <= 10)
						p->para = 3;
					else if(r <= 20)
						p->para = 11;
					else if(r <= 30)
						p->para = 15;
					else if(r <= 40)
						p->para = 152;
					else if(r <= 50)
						p->para = 22;
					else if(r <= 60)
						p->para = 21;
					else
					{
						p->option = EOTSkill;
						p->para = 0;
					}
				}
				else
					p->target = 0;
			}
			break;
		case CL_XunChaShi:
			{
				if(m_fightTurn+1 == 5)	// 第5轮出特殊技能
				{
					vector<uint16> skill;
					for(uint8 i=0;i < p->skill_list.size();i++)
						skill.push_back(p->skill_list[i].id);
					uint8 skillNum = skill.size();
					if(skillNum == 0)
						return;
					bool fuhuo = false;
					for(uint8 i=0;i < skillNum;i++)
					{
						if(skill[i] == 67)	// 召唤
						{
							fuhuo = true;
							break;
						}
					}
					if(fuhuo)
					{
						// 检测本方是否可以召唤
						for(uint8 i=0;i < GROUP2_BEGIN;i++)
						{
							if(IsEmpty(i+1) || !IsAlive(i+1))
							{
								p->option = EOTZhaoHuan;
								m_zhaoHuanTimes++;
								return;
							}
						}
					}

					for(uint8 i=0;i < skillNum;i++)
					{
						if(skill[i] != 67)	// 非召唤技能
						{
							p->option = EOTSkill;
							p->para = skill[i];

							uint8 target[GROUP2_BEGIN];
							uint8 num=0;
							if(skill[i] == 65 || skill[i] == 66)
								GetMeGroup(pos+1,target,num);
							else
								GetAnotherGroup(pos+1,target,num);
							if(num > 0)
								p->target = RandSelect(target,num);
							return;
						}
					}
				}
				else if(m_fightTurn+1 == 10)	// 第10轮必杀技
				{
					p->option = EOTSkill;
					p->para = 38;	// 灭绝

					uint8 target[GROUP2_BEGIN];
					uint8 num=0;
					GetAnotherGroup(pos+1,target,num);
					if(num > 0)
						p->target = RandSelect(target,num);
				}
				else	// 普通技能
				{

				}
			}
			break;
		case CL_KuaFu_SJMJ_Boss:
			{
				if(m_fightTurn+1 >= 5)	// 大于等于5轮之后出必杀技
				{
					p->option = EOTSkill;
					p->para = 38;	// 灭绝

					uint8 target[GROUP2_BEGIN];
					uint8 num=0;
					GetAnotherGroup(pos+1,target,num);
					if(num > 0)
						p->target = RandSelect(target,num);
				}
			}
			break;
		case CL_TEST_MONSTER_1:
			{
				p->option = EOTSkill;
				if((m_fightTurn+1)%2 == 1)
					p->para = 24;
				else
					p->para = 35;

				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroupByAttackedOrder(pos,target,num);
				if(num > 0)
					p->target = target[0];
			}
			break;
		case CL_TEST_MONSTER_2:
			{
				p->option = EOTSkill;
				if((m_fightTurn+1)%2 == 1)
					p->para = 17;
				else
					p->para = 36;

				uint8 target[GROUP2_BEGIN];
				uint8 num = 0;
				GetAnotherGroupByAttackedOrder(pos,target,num);
				if(num > 0)
					p->target = target[0];
			}
			break;
	}
}

void CFight::SetAllUserDie()
{
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		if(GetUser(pos) != NULL)
			SetState(pos, EFST_STATE_Die);
		else if(GetPet(pos) != NULL)
			SetState(pos, EFST_STATE_Die);
	}
}

void CFight::CalculateTaoPao(CUser *pUser,uint8 pos)
{
	if(pUser == NULL || pos == 0 || pos > MAX_MEMBER)
		return;

	BangPaiPKTaoPao(pUser,pos);
	GrabFishTaoPao(pUser, pos);
	BangPaiZhanTaoPao(pUser, pos);
	LeiTaiSaiTaoPao(pUser, pos);
	FeiXianFightTaoPao(pUser, pos);
#ifdef KUA_FU
	GuWuXianShiTaoPao(pUser, pos);
	KuaFuQieCuoTaoPao(pUser, pos);
#endif
}

uint8 CFight::UnitPassiveAction(uint8 pos,EFightStep step,CNetMessage &msg,int data)
{
	const int Buff2[] = {ESBUFF_ShiXinDu,ESBUFF_ShiDu,ESBUFF_FuDu,ESBUFF_ZhuoShao,ESBUFF_JinGuZhou,ESBUFF_AddHpContinue,ESBUFF_Blooding}; // 开始行动前
	const int Buff4[] = {ESBUFF_JinLiaoShu}; 

	const int *pBuff = NULL;
	int size = 0;
	if(step == EFStep_TurnBegin)	// 回合开始
	{
		pBuff = NULL;
		size = 0;
	}
	else if(step == EFStep_UserActBegin)	// 开始行动前
	{
		pBuff = Buff2;
		size = sizeof(Buff2)/sizeof(Buff2[0]);
	}
	else if(step == EFStep_UserActEnd)	// 行动后
	{
		pBuff = NULL;
		size = 0;
	}
	else if(step == EFStep_CureHp)	// 加血时
	{
		pBuff = Buff4;
		size = sizeof(Buff4)/sizeof(Buff4[0]);
	}

	if(size == 0)
		return 0;
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;

	uint8 addNum = 0;
	for(uint8 i=0;i < size;i++)
	{
		if(HaveBuff(pos,pBuff[i]))
		{
			int val = GetStatePara1(pos,pBuff[i]);
			uint8 srcPos = GetStateSrcPos(pos, pBuff[i]);
			int damage = 0;
			int addHp = 0;
			if(pBuff[i] == ESBUFF_ShiXinDu)
			{
				int valLimit = GetStatePara2(pos,pBuff[i]);
				damage = GetMaxHp(pos) * (val /10000.0);
				damage = (damage > valLimit) ? valLimit : damage;
			}
			else if(pBuff[i] == ESBUFF_ShiDu)
			{
				damage = val + GetStatePara2(pos,pBuff[i]);
			}
			else if(pBuff[i] == ESBUFF_FuDu)
			{
				int valLimit = GetStatePara2(pos,pBuff[i]);
				damage = p->hp * (val /10000.0);
				damage = (damage > valLimit) ? valLimit : damage;
			}
			else if(pBuff[i] == ESBUFF_ZhuoShao)
				damage = val;
			else if(pBuff[i] == ESBUFF_JinGuZhou)
				damage = GetStatePara2(pos,pBuff[i]);
			else if(pBuff[i] == ESBUFF_JinLiaoShu)
				damage = data * (GetStatePara2(pos,pBuff[i])/10000.0);
			else if(pBuff[i] == ESBUFF_AddHpContinue)
				addHp = val;
			else if(pBuff[i] == ESBUFF_Blooding)
			{
				damage = val;
				if(HaveBuff(pos,ESBUFF_DamagePercentDes))
					damage *= 1.2;
			}

			int v = 0;
			if(damage > 0)
				v = damage;
			else if(addHp > 0)
				v = -addHp;

			if(val != 0)
			{
				int absorpionHp = 0;
				int fuhuoHp = 0;
				DecreaseHp(pos, srcPos, v, absorpionHp, false, &fuhuoHp);
				msg<<pos<<-v<<absorpionHp<<fuhuoHp;
				MakeBuffList(pos,msg);
				addNum++;
				
				if(showFightLog)
					cout<<"====== >>>>	CFight::UnitPassiveAction  pos="<<(int)pos<<(val > 0 ?", 扣血=" : ", 加血=")<<abs(v)<<endl;
				if(!IsAlive(pos))
					break;
			}
		}
	}

	if(showFightLog)
		cout<<"====== >>>>  CFight::UnitPassiveAction  pos="<<(int)pos<<", addNum="<<(int)addNum<<endl;
	return addNum;
}

uint8 CFight::PassiveAction(EFightStep step,CNetMessage &extActionMsg,uint8 pos,int value)
{
	if(m_forceEnd)
		return 0;

	uint8 actionNum = 0;
	uint8 allMem[MAX_MEMBER];
	uint8 num = 0;
	if(pos == 0)
	{
		GetAllUnitByOrder(allMem, num);
//		GetAllMember(allMem,num);
//		SortBySpeed(allMem,num);
	}
	else
	{
		allMem[num++] = pos;
	}
	if(num == 0)
		return 0;

	CNetMessage passiveMsg;
	passiveMsg<<(uint8)EFOT_Passive<<allMem[0]<<(uint16)0<<"";
	uint16 numPos = passiveMsg.GetDataLen();
	passiveMsg<<actionNum;
	for(uint8 i=0;i < num;i++)
	{
		if(!IsAlive(allMem[i]))
			continue;
		actionNum += UnitPassiveAction(allMem[i],step,passiveMsg,value);
	}
	passiveMsg.WriteData(numPos,&actionNum,sizeof(actionNum));

	if(showFightLog)
		cout<<"====== >>  CFight::PassiveAction  pos="<<(int)pos<<", option="<<(int)EFOT_Passive<<", num="<<(int)actionNum<<endl;

	if(actionNum > 0)
	{
		extActionMsg.SetType(extActionMsg.GetType() + 1);
		extActionMsg.AddNetMsgExceptHead(passiveMsg);
		return 1;
	}
	return 0;
}

void CFight::GetOption(uint8 pos,uint8 &option,int &para,uint8 &target)
{
	option = EOTNone;
	para = 0;
	target = 0;
	if(IsEmpty(pos) || !IsAlive(pos))
		return;
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return;
	
	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		if(HaveBuff(pos,ESBUFF_NOT_MOVE))
			return;
		if(HaveBuff(pos,ESBUFF_WaitForTurn))
		{
			option = EOTSkill;
			para = GetStatePara1(pos,ESBUFF_WaitForTurn);
			return;
		}
		
		if(HaveBuff(pos,ESBUFF_HunShui))
			return;
		int tarPos = GetChaoFengTarget(pos);
		if(tarPos > 0)
		{
			if(!IsEmpty(tarPos) && IsAlive(tarPos))
			{
				option = EOTNormal;
				para = 0;
				target = tarPos;
				return;
			}
		}

		if(HaveHunLuan(pos) || HaveMeiHuo(pos))
		{
			option = EOTNormal;
			para = 0;
			
			uint8 member[MAX_MEMBER];
			uint8 num = 0;
			GetAllMemberExceptSelf(pos,member,num);
			if(num == 0)
			{
				option = EOTNone;
				return;
			}
			target = RandSelect(member,num);
			return;
		}
		
		if(HaveFanJian(pos))
		{
			option = EOTNormal;
			para = 0;
			
			uint8 member[MAX_MEMBER];
			uint8 num = 0;
			GetMeGroupExceptSelf(pos,member,num);
			if(num == 0)
				GetAnotherGroup(pos,member,num);
			if(num == 0)
			{
				option = EOTNone;
				return;
			}
			target = RandSelect(member,num);
			return;
		}

		if(m_members[pos-1].option == EOTEscape)
		{
			option = EOTEscape;
			return;
		}
		
		if(HaveBuff(pos,ESBUFF_ChenMo) || HaveBuff(pos,ESBUFF_FengYin))
		{
			option = EOTNormal;
			para = 0;
			
			uint8 member[MAX_MEMBER];
			uint8 num = 0;
			GetGroupByAttackedOrder(pos,member,num,false);
			if(num == 0)
			{
				option = EOTNone;
				return;
			}
			target = member[0];
			return;
		}

		// 14 霸王援护 特殊处理


		CSkillMgr &mgr = SingletonCSkillMgr::instance();

		// 正常选择技能
		int skillId = 0;
		if(p->type == EFMT_MONSTER)
		{
			skillId = p->RandSelectSkill();
//			MonsterSkillCeLue(pos+1);
			vector<uint16> expectSkillList;			
			do
			{
				bool canUse = true;
				SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
				if(pSkillCfg != NULL)
				{
					int activeEffId = pSkillCfg->activeEffect.GetEffectId();
					SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
					if(pActive != NULL)
					{
						if(pActive->effect_type == ESkill_Active_FuHuo) // 复活技能
						{
							if(!HaveDieMember(pos)) // 无死亡队友
							{
								canUse = false;
								expectSkillList.push_back(skillId);
								skillId = p->RandSelectSkill(&expectSkillList);
							}
						}
						else if(pActive->effect_type == ESkill_Active_AddHpByDam || pActive->effect_type == ESkill_Active_AddHpNormal)	// 加血
						{
							if(!HaveLoseHpMember(pos))	// 无队友伤血
							{
								canUse = false;
								expectSkillList.push_back(skillId);
								skillId = p->RandSelectSkill(&expectSkillList);
							}
						}
					}
				}
				
				if(canUse)
					break;
			}while(skillId > 0);
		}
		else if(p->type == EFMT_PET)
		{
			skillId = GetUnitAISkillId(pos);
		}
		else if(p->type == EFMT_USER)
		{
			if(m_members[pos-1].option == EOTSkill)
			{
				skillId = m_members[pos-1].para;
				bool canUse = true;
				if(p->CanUseSkill(skillId))
				{
					SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
					if(pSkillCfg != NULL)
					{
						int activeEffId = pSkillCfg->activeEffect.GetEffectId();
						SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
						if(pActive != NULL)
						{
							if(pActive->effect_type == ESkill_Active_FuHuo) // 复活技能
							{
								if(!HaveDieMember(pos)) // 无死亡队友
									canUse = false;
							}
						}
					}

					if(canUse)
					{
						option = m_members[pos-1].option;
						para = m_members[pos-1].para;
						return;
					}
				}
			}
			else if(m_members[pos-1].option == EOTEscape)
			{
				option = m_members[pos-1].option;
				return;
			}
			skillId = GetUnitAISkillId(pos);
		}

		if(skillId > 0)
		{
			m_members[pos-1].option = EOTSkill;
			m_members[pos-1].para = skillId;
		}
		else
		{
			m_members[pos-1].option = EOTNormal;
			m_members[pos-1].para = 0;
			
			uint8 member[MAX_MEMBER];
			uint8 num = 0;
			GetGroupByAttackedOrder(pos,member,num,false);
			if(num == 0)
			{
				option = EOTNone;
				return;
			}
			m_members[pos-1].target = member[0];
		}

		option = m_members[pos-1].option;
		para = m_members[pos-1].para;
		target = m_members[pos-1].target;
	}
}

uint16 CFight::GetUnitAISkillId(uint8 pos)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return 0;
	if(IsEmpty(pos) || !IsAlive(pos))
		return 0;
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return 0;

	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	uint16 heroId = GetHeroId(pos);
	HeroSkillRoleCfg *pRoleCfg = mgr.GetHeroSkillRoleCfg(heroId);
	if(pRoleCfg != NULL)
	{
		int tacticCost = GetTacticCost(pos,*pRoleCfg);
		if(p->CanUseSkill(pRoleCfg->tacticSkillId) && GetTeamRage(pos) >= tacticCost
			&& IsRoleSkillUseful(pos,pRoleCfg->tacticSkillId))
			return pRoleCfg->tacticSkillId;
		if(p->CanUseSkill(pRoleCfg->regularSkillId) && IsRoleSkillUseful(pos,pRoleCfg->regularSkillId))
			return pRoleCfg->regularSkillId;
		return 0;
	}
	const vector<SSkillData> &skillList = p->GetUnitSkillList();
	vector<SSkillData> fuhuo;
	vector<SSkillData> cure;
	vector<SSkillData> attack_single;	// 单体攻击
	vector<SSkillData> attack_mul;	// 多体攻击
	vector<SSkillData> other;
	// 技能分类
	for(uint16 i=0;i < skillList.size();i++)
	{
		const SSkillData &s = skillList[i];
		if(s.leftCD > 0)
			continue;
		SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(s.id);
		if(pSkillCfg == NULL)
			continue;
		int activeEffId = pSkillCfg->activeEffect.GetEffectId();
		SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
		if(pActive == NULL)
			continue;
		if(pActive->effect_type == ESkill_Active_FuHuo) // 复活技能
			fuhuo.push_back(s);
		else if(pActive->effect_type == ESkill_Active_AddHpByDam || pActive->effect_type == ESkill_Active_AddHpNormal)
			cure.push_back(s);
		else if(pActive->effect_type == ESkill_Active_Attack || pActive->effect_type == ESkill_Active_MulAttack || pActive->effect_type == ESkill_Active_AttackByHpPer 
			|| pActive->effect_type == ESkill_Active_AttackByDesHp || pActive->effect_type == ESkill_Active_Wait)
		{
			if(pActive->target_num == 1)
				attack_single.push_back(s);
			else
				attack_mul.push_back(s);
		}
		else
			other.push_back(s);
	}

	// 复活
	int size = fuhuo.size();
	if(size > 0 && HaveDieMember(pos))	// 有死亡队友
	{
		return fuhuo[Random(1,size) - 1].id;
	}

	// 治疗（只有确有生命损失时才施放，避免满血空转）
	size = cure.size();
	if(size > 0 && HaveLoseHpMember(pos))
	{
		return cure[Random(1,size) - 1].id;
	}

	// 攻击技能
	uint8 member[GROUP_MEMBER];
	uint8 num = 0;
	GetAnotherGroup(pos,member,num);
	if(num == 1)
	{
		size = attack_single.size();
		if(size > 0)
		{
			return attack_single[Random(1,size) - 1].id;
		}
		size = attack_mul.size();
		if(size > 0)
		{
			return attack_mul[Random(1,size) - 1].id;
		}
	}
	else
	{
		size = attack_mul.size();
		if(size > 0)
		{
			return attack_mul[Random(1,size) - 1].id;
		}
		size = attack_single.size();
		if(size > 0)
		{
			return attack_single[Random(1,size) - 1].id;
		}
	}
	
	// 其他
	size = other.size();
	if(size > 0)
	{
		return other[Random(1,size) - 1].id;
	}
	return 0;
}

uint16 CFight::GetHeroId(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL || p->type != EFMT_PET || p->memPtr.type() != typeid(SharePetPtr))
		return 0;
	SPet *pPet = (boost::any_cast<SharePetPtr>(p->memPtr)).get();
	return pPet == NULL ? 0 : pPet->id;
}

bool CFight::IsRoleSkillUseful(uint8 pos,uint16 skillId)
{
	SSkillCfgData *pSkillCfg = SingletonCSkillMgr::instance().GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return false;
	SSkillActiveEffect *pActive = SingletonCSkillMgr::instance().GetActiveEffectCfg(pSkillCfg->activeEffect.GetEffectId());
	if(pActive == NULL)
		return false;
	if(pActive->effect_type == ESkill_Active_FuHuo)
		return HaveDieMember(pos);
	if(pActive->effect_type == ESkill_Active_AddHpByDam || pActive->effect_type == ESkill_Active_AddHpNormal)
		return HaveLoseHpMember(pos);
	return true;
}

int CFight::GetTeamRage(uint8 pos) const
{
	if(pos == 0 || pos > MAX_MEMBER)
		return 0;
	return m_teamRage[pos <= GROUP2_BEGIN ? EGT_GROUP1 : EGT_GROUP2];
}

void CFight::AddTeamRage(uint8 pos,int value)
{
	if(pos == 0 || pos > MAX_MEMBER || value == 0)
		return;
	int group = pos <= GROUP2_BEGIN ? EGT_GROUP1 : EGT_GROUP2;
	m_teamRage[group] += value;
	if(m_teamRage[group] < 0)
		m_teamRage[group] = 0;
	else if(m_teamRage[group] > 100)
		m_teamRage[group] = 100;
}

int CFight::GetAffixTier(uint8 pos,uint16 affixId) const
{
	if(pos == 0 || pos > MAX_MEMBER || affixId == 0 || affixId > 48)
		return 0;
	const SFightMember &member = m_members[pos-1];
	uint16 passiveSkillId = 5000 + affixId;
	for(uint16 i=0;i < member.passive_skill.size();i++)
	{
		if(member.passive_skill[i].id == passiveSkillId)
			return member.passive_skill[i].level > 3 ? 3 : member.passive_skill[i].level;
	}
	return 0;
}

int CFight::GetAffixValue(uint8 pos,uint16 affixId,uint8 valueIndex) const
{
	int tier = GetAffixTier(pos,affixId);
	EquipAffixCfg *pCfg = sCItemCfgManager.GetEquipAffixCfg(affixId);
	if(tier <= 0 || pCfg == NULL)
		return 0;
	return valueIndex == 2 ? pCfg->value2[tier-1] : pCfg->value1[tier-1];
}

int CFight::GetTeamBestAffixValue(uint8 pos,uint16 affixId,uint8 valueIndex)
{
	if(pos == 0 || pos > MAX_MEMBER)
		return 0;
	int begin = pos <= GROUP2_BEGIN ? 1 : GROUP2_BEGIN + 1;
	int end = pos <= GROUP2_BEGIN ? GROUP2_BEGIN : MAX_MEMBER;
	int best = 0;
	for(int memberPos=begin;memberPos<=end;memberPos++)
	{
		if(!IsEmpty(memberPos))
		{
			int value = GetAffixValue(memberPos,affixId,valueIndex);
			if(value > best)
				best = value;
		}
	}
	return best;
}

bool CFight::TryTriggerAffix(uint8 pos,uint16 affixId)
{
	if(pos == 0 || pos > MAX_MEMBER || affixId == 0 || affixId > 48 || GetAffixTier(pos,affixId) == 0)
		return false;
	EquipAffixCfg *pCfg = sCItemCfgManager.GetEquipAffixCfg(affixId);
	if(pCfg == NULL)
		return false;
	SFightMember &member = m_members[pos-1];
	if(pCfg->perTurnLimit > 0 && member.affixTurnCount[affixId] >= pCfg->perTurnLimit)
		return false;
	if(pCfg->perBattleLimit > 0 && member.affixBattleCount[affixId] >= pCfg->perBattleLimit)
		return false;
	member.affixTurnCount[affixId]++;
	member.affixBattleCount[affixId]++;
	return true;
}

int CFight::GetTacticCost(uint8 pos,const HeroSkillRoleCfg &roleCfg)
{
	int cost = roleCfg.tacticCost;
	int begin = pos <= GROUP2_BEGIN ? 1 : GROUP2_BEGIN + 1;
	int end = pos <= GROUP2_BEGIN ? GROUP2_BEGIN : MAX_MEMBER;
	int bestReduction = 0;
	for(int memberPos=begin;memberPos<=end;memberPos++)
	{
		if(!IsAlive(memberPos))
			continue;
		int reduction = GetAffixValue(memberPos,47,1);
		if(reduction > bestReduction)
			bestReduction = reduction;
	}
	cost -= bestReduction;
	return cost < 20 ? 20 : cost;
}

void CFight::InitTeamRageFromAffixes()
{
	for(int group=0;group<2;group++)
	{
		int begin = group == EGT_GROUP1 ? 1 : GROUP2_BEGIN + 1;
		int end = group == EGT_GROUP1 ? GROUP2_BEGIN : MAX_MEMBER;
		int bestOpening = 0;
		for(int pos=begin;pos<=end;pos++)
		{
			if(!IsAlive(pos))
				continue;
			int opening = GetAffixValue(pos,45,1);
			if(opening > bestOpening)
				bestOpening = opening;
		}
		m_teamRage[group] = bestOpening;
	}
}

void CFight::GrantDamageTakenRage(uint8 pos)
{
	SFightMember *pMember = GetFightMember(pos);
	if(pMember == NULL || pMember->rageDamagedThisAction)
		return;
	pMember->rageDamagedThisAction = true;
	AddTeamRage(pos,3);
}

uint8 CFight::AddNewFightUnit(CNetMessage &msg)
{
	if(m_zhuzhan.empty())
		return 0;

	CNetMessage addMsg;
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	addMsg<<(uint8)EFOT_ZhaoHuan;
	uint16 numPos = addMsg.GetDataLen();
	uint8 num = 0;
	addMsg<<num;
	for(uint16 i=0;i < m_zhuzhan.size();i++)
	{
		SFightZhuZhanCfg &zhuzhan = m_zhuzhan[i];
		if(zhuzhan.turn == m_fightTurn+1)
		{
			if(zhuzhan.group < 1 || zhuzhan.group > 2)
				continue;
			uint16 zhenfaId = m_zhenfaId[zhuzhan.group-1];
			SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(zhenfaId);
			if(pZhenFa == NULL)
				continue;
			if(zhuzhan.zhenfaIdx > 0)
			{
				uint8 pos = pZhenFa->fightPos[zhuzhan.zhenfaIdx - 1] + (zhuzhan.group-1)*GROUP_POS_STEP;
				if(zhuzhan.type == 1)	// pet
				{
					SharePetPtr pet = CreatePet(zhuzhan.unit_id,zhuzhan.petLevel,zhuzhan.petStar);
					SPet *pPet = pet.get();
					if(pPet == NULL)
						continue;
					if(AddPet(pet,pos,0xff,zhuzhan.zhenfaIdx - 1) > 0)
					{
//						SetBelongToUserWithPos(pos,9);
						num++;
						addMsg<<(uint8)2<<pos<<(uint32)pPet->id<<(int)100<<pPet->name<<pPet->level<<GetMaxHp(pos)<<GetHp(pos);
						MakeBuffList(pos,addMsg);
						addMsg<<m_members[pos-1].petOwner<<pPet->quality;
					}
				}
				else if(zhuzhan.type == 2)	// monster
				{
					ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateMonsterBossById(zhuzhan.unit_id);
					SMonsterInst *pInst = ptr.get();
					if(pInst == NULL || pInst->id == 0)
						continue;
					if(AddMonster(ptr, pos,zhuzhan.zhenfaIdx - 1) > 0)
					{
						num++;
						addMsg<<(uint8)0<<pos<<pInst->pic<<pInst->scale<<pInst->name
							<<pInst->level<<pInst->attr.maxHp<<pInst->hp<<(uint8)0;
						if(m_type == EFTScript)
							addMsg<<(uint8)EMTNormal;
						else
							addMsg<<pInst->type;
						MakeBuffList(pos,addMsg);
						uint8 isBoss = 0;
						addMsg<<pInst->quality<<isBoss;
					}
				}
			}
		}
		else if(zhuzhan.turn > m_fightTurn+1)
		{
			break;
		}
	}
	if(num > 0)
	{
		addMsg.WriteData(numPos,&num,sizeof(num));
		msg<<addMsg;
		return 1;
	}
	return 0;
}

uint8 CFight::ShowDialog(CNetMessage &msg)
{
	if(m_dialog.empty())
		return 0;

	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	uint8 num = 0;
	for(uint16 i=0;i < m_dialog.size();i++)
	{
		SFightDialogCfg &dialog = m_dialog[i];
		if(dialog.showTurn == m_fightTurn+1)
		{
			if(dialog.group < 1 || dialog.group > 2)
				continue;
			uint16 zhenfaId = m_zhenfaId[dialog.group-1];
			SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(zhenfaId);
			if(pZhenFa == NULL)
				continue;
			if(dialog.zhenfaIdx > 0)
			{
				uint8 pos = pZhenFa->fightPos[dialog.zhenfaIdx - 1] + (dialog.group-1)*GROUP_POS_STEP;
				msg<<(uint8)EFOT_Dialog<<pos<<dialog.lastTime<<dialog.dialog;
				num++;
			}
		}
		else if(dialog.showTurn > m_fightTurn+1)
		{
			break;
		}
	}
	return num;
}

uint8 CFight::NotKilledAction(uint8 src,CNetMessage &msg)
{
	if(m_forceEnd)
		return 0;
	if(!IsAlive(src))
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	if(pSrc->option > EOTSkill)
		return 0;
	
	uint16 skillId = (pSrc->option == EOTSkill) ? pSrc->para : 0;
	uint16 skillLv = (pSrc->option == EOTSkill) ? (pSrc->GetSkillLevel(skillId)) : 0;
	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_AfterAttack);
	vector<SAttrData> attrData;
	CalculatePassiveSkill_ExtValue(src,pSrc->target,trigger,attrData,skillId,skillLv);

	if(GetAttrValue(attrData,ESkill_PassAttr_AttackActionAgain) > 0)
	{
		if(pSrc->option == EOTNormal)
			NormalButtle(src,pSrc->target);
		else
			SkillButtle(src,skillId);
		MakeBuffList(src, m_actionMsg);
	}
	return MergeUnitAcionMsg(msg);
}

uint8 CFight::KilledAction(uint8 src,CNetMessage &msg)
{
	if(m_forceEnd)
		return 0;
	if(!IsAlive(src))
		return 0;
	SFightMember *pSrc = GetFightMember(src);
	if(pSrc == NULL)
		return 0;
	if(pSrc->option > EOTSkill)
		return 0;
	
	// 击杀判定
	if(!pSrc->HaveKillUnit())
		return 0;
	uint8 killNum = pSrc->killList.size();
	pSrc->ClearKillUnit();

	uint8 anotherGroup[MAX_MEMBER];
	uint8 anotherNum = 0;
	GetAnotherGroup(src,anotherGroup,anotherNum);
	if(anotherNum == 0)
		return 0;
	uint16 skillId = (pSrc->option == EOTSkill) ? pSrc->para : 0;
	uint16 skillLv = (pSrc->option == EOTSkill) ? (pSrc->GetSkillLevel(skillId)) : 0;
	// 击杀目标时，属性变化
	vector<ESkillTriggerType> skillTrigger;
	skillTrigger.push_back(ESkill_Trigger_KillTarget);
	vector<ESkillPassitiveType> passList;
	passList.push_back(ESkill_Pass_ReduceCD);
	CalculatePassiveSkill_ExtAttrEffect(src,0,skillTrigger,passList,skillId,skillLv,killNum);
	
	// 击杀目标时, ESkill_Trigger_KillTarget
	vector<SAttrData> attrData;
	CalculatePassiveSkill_ExtValue(src,anotherGroup[0],skillTrigger,attrData,skillId,skillLv,killNum);

	if(GetAttrValue(attrData,ESkill_PassAttr_NormalAttack) > 0)	// 额外普攻
	{
		GetSkillTargetSelCondition(anotherGroup,anotherNum,ESkill_Select_MinCurHp);
		NormalButtle(src,anotherGroup[0]);
	}
	else if(GetAttrValue(attrData,ESkill_PassAttr_UseSameSkill) > 0)  // 额外释放技能
	{
		if(pSrc->option != EOTSkill)
			return 0;
		SkillButtle(src,skillId);
	}
	else
	{
		return 0;
	}
	MakeBuffList(src, m_actionMsg);
	return MergeUnitAcionMsg(msg);
}

uint8 CFight::DiePassiveAcion(CNetMessage &msg)
{
	if(m_forceEnd)
		return 0;
	
	vector<ESkillTriggerType> trigger;
	trigger.push_back(ESkill_Trigger_UnitDied);
	trigger.push_back(ESkill_Trigger_MemberDied);
	vector<ESkillPassitiveType> passList;
	passList.push_back(ESkill_Pass_Attr);
	for(uint8 i = 0;i < m_dieList.size(); i++)
	{
		uint8 pos = m_dieList[i];
		if(!IsAlive(pos) && !HaveState(pos, EFST_STATE_Escape))	// 死亡
		{
			uint8 member[GROUP_MEMBER];
			uint8 num = 0;
			GetAllMemberExceptSelf(pos,member,num);
			for(uint8 j=0;j < num;j++)
				CalculatePassiveSkill_ExtAttrEffect(member[j],pos,trigger,passList);
		}
	}
	
	// 被动死亡判断（复活、加血等）
	trigger.clear();
	trigger.push_back(ESkill_Trigger_SelfDied);
	trigger.push_back(ESkill_Trigger_DieAndAddToAllUnit);
	trigger.push_back(ESkill_Trigger_DieAndAddToOtherUnit);
	for(uint8 i = 0;i < m_dieList.size(); i++)
	{
		uint8 pos = m_dieList[i];
		if(!IsAlive(pos) && !HaveState(pos, EFST_STATE_Escape))
		{
			CalculatePassiveSkill_ExtUnitAndBuff(pos,0,trigger,0,0);
		}
	}

	// 友方为其复活
	trigger.clear();
	trigger.push_back(ESkill_Trigger_UnitDied);
	for(uint8 i = 0;i < m_dieList.size(); i++)
	{
		uint8 pos = m_dieList[i];
		if(!IsAlive(pos) && !HaveState(pos, EFST_STATE_Escape))	// 死亡
		{
			uint8 member[GROUP_MEMBER];
			uint8 num = 0;
			GetMeGroupExceptSelf(pos,member,num);
			for(uint8 j=0;j < num;j++)
			{
				CalculatePassiveSkill_ExtUnitAndBuff(member[j],pos,trigger,0,0);
				if(IsAlive(pos))
					break;
			}
		}
	}
	
	m_dieList.clear();
	return 0;
}

uint8 CFight::MemberActionEffectOther(uint8 src,CNetMessage &msg)
{
	// 友方行动时，触发被动
	uint8 mem[GROUP_MEMBER];
	uint8 num = 0;
	GetMeGroupExceptSelf(src,mem,num);

	m_actionMsg.ReWrite();
	m_otherMsg.ReWrite();
	m_extActionMsg.ReWrite();
	for(uint8 i = 0; i < num; i++)
	{
		uint8 tar = mem[i];
		if(!IsAlive(tar))
			continue;
		vector<ESkillTriggerType> trigger;
		trigger.push_back(ESkill_Trigger_MemberAction);
		CalculatePassiveSkill_ExtUnitAndBuff(tar,src,trigger,0,0);
	}
	return MergeExtActionMsg(msg);
}

uint8 CFight::MergeExtActionMsg(CNetMessage &msg)
{
	uint8 damageNum = 0;
	uint8 extActNum = m_extActionMsg.GetType();
	if(extActNum > 0)
	{
		damageNum += extActNum;
		msg.AddNetMsgExceptHead(m_extActionMsg);
	}
	uint8 shareDamNum = m_shareDamageMsg.GetType();
	if(shareDamNum > 0)
	{
		damageNum += shareDamNum;
		msg.AddNetMsgExceptHead(m_shareDamageMsg);
	}
	m_extActionMsg.ReWrite();
	m_shareDamageMsg.ReWrite();
	return damageNum;
}

uint8 CFight::MergeUnitAcionMsg(CNetMessage &msg,bool addOtherMsg)
{
	uint8 damageNum = 0;
	uint16 actionNum = m_actionMsg.GetType();
	if(actionNum > 0)
	{
		damageNum += actionNum;
		msg.AddNetMsgExceptHead(m_actionMsg);
		if(addOtherMsg)
		{
			uint8 otherNum = m_otherMsg.GetType();
			msg<<otherNum;
			if(otherNum > 0)
				msg.AddNetMsgExceptHead(m_otherMsg);
		}
	}

	m_actionMsg.ReWrite();
	m_otherMsg.ReWrite();
	damageNum += MergeExtActionMsg(msg);
	return damageNum;
}

void CFight::CalculateFight(CNetMessage &msg)
{
	m_turnBegin = GetSysTime();
	m_useSpeekSkill = false;
	m_actionList.clear();
	m_actionMsg.ReWrite();
	m_otherMsg.ReWrite();
	m_extActionMsg.ReWrite();
	m_shareDamageMsg.ReWrite();
	m_tacticUsedThisTurn[0] = false;
	m_tacticUsedThisTurn[1] = false;
	for(uint8 affixPos=1;affixPos<=MAX_MEMBER;affixPos++)
	{
		if(!IsEmpty(affixPos))
			memset(m_members[affixPos-1].affixTurnCount,0,sizeof(m_members[affixPos-1].affixTurnCount));
	}

	msg<<(uint8)1; //战斗结果
	uint8 damageNum = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<damageNum;
//	for(uint8 i=0;i < m_taopaoList.size();i++)
//		damageNum += EscapeAction(m_taopaoList[i]);
	if(damageNum > 0)
	{
		msg.AddNetMsgExceptHead(m_actionMsg);
		m_actionMsg.ReWrite();
	}
	
	damageNum += AddNewFightUnit(msg);
	damageNum += ShowDialog(msg);
	PassiveAction(EFStep_TurnBegin,m_extActionMsg);
	damageNum += MergeExtActionMsg(msg);

	uint8 allMem[MAX_MEMBER];
	uint8 num = 0;
	GetAllUnitByOrder(allMem, num);
//	GetAllMember(allMem,num);
//	SortBySpeed(allMem,num);

	// 战斗开始时,第一回合
	if(m_fightTurn == 0)
	{
		InitTeamRageFromAffixes();
		for(uint8 i = 0; i < num; i++)
		{
			if(!IsAlive(allMem[i]))
				continue;
			vector<ESkillTriggerType> trigger;
			trigger.push_back(ESkill_Trigger_FightBegin);
			trigger.push_back(ESkill_Trigger_FightBeginAddToAllUnit);
			trigger.push_back(ESkill_Trigger_FightBegin_MaxAttackEnemy);
			vector<ESkillPassitiveType> passList;
			passList.push_back(ESkill_Pass_Attr);
			passList.push_back(ESkill_Pass_DescAttackAndAddToSelf);
			CalculatePassiveSkill_ExtAttrEffect(allMem[i],0,trigger,passList);

			trigger.clear();
			trigger.push_back(ESkill_Trigger_FightBeginAddToAllUnit);
			trigger.push_back(ESkill_Trigger_AddAttrBeginFight);
			CalculatePassiveSkill_ExtUnitAndBuff(allMem[i],0,trigger,0,0);
			damageNum += MergeExtActionMsg(msg);
		}
	}

	// 回合开始时，触发被动
	for(uint8 i = 0; i < num; i++)
	{
		if(!IsAlive(allMem[i]))
			continue;
		vector<ESkillTriggerType> trigger;
		trigger.push_back(ESkill_Trigger_TurnBegin);
		trigger.push_back(ESkill_Trigger_TurnBegin_RandSelfOne);
		CalculatePassiveSkill_ExtUnitAndBuff(allMem[i],0,trigger,0,0);
		damageNum += MergeExtActionMsg(msg);
	}

	do
	{
		if(m_forceEnd)
			break;
		// 重新排序
//		SortBySpeed(allMem,num);
		if(OneGroupAllDie() != 0)
			break;
		int src = allMem[0];
		GetExcept(src,allMem,num);
		if(!IsAlive(src))
			continue;
		m_curActionPos = src;

		damageNum += MemberActionEffectOther(src,msg);

		m_actionMsg.ReWrite();
		m_otherMsg.ReWrite();
		m_extActionMsg.ReWrite();

		m_members[src-1].ClearKillUnit();
		m_dieList.clear();
		for(uint8 ragePos=1;ragePos<=MAX_MEMBER;ragePos++)
		{
			if(!IsEmpty(ragePos))
				m_members[ragePos-1].rageDamagedThisAction = false;
		}

		PassiveAction(EFStep_UserActBegin,m_extActionMsg,src);
		damageNum += MergeExtActionMsg(msg);
		if(!IsAlive(src))
			continue;

		vector<ESkillTriggerType> trigger;
		trigger.push_back(ESkill_Trigger_Action);
		vector<ESkillPassitiveType> passList;
		passList.push_back(ESkill_Pass_Attr);
		passList.push_back(ESkill_Pass_DescSelfAllCD);
		CalculatePassiveSkill_ExtAttrEffect(src,0,trigger,passList);

		// 行动时，触发被动
		trigger.clear();
		trigger.push_back(ESkill_Trigger_Action);
		CalculatePassiveSkill_ActionBuff(src,0,trigger);
		damageNum += MergeExtActionMsg(msg);

		uint8 option = EOTNone;
		int para = 0;
		uint8 target = 0;
		GetOption(src,option,para,target);
		SetOption(src,option,para,target);
		if(option == EOTNone)
			continue;
		m_actionList.push_back(src);

		// 行动时，触发被动
		trigger.clear();
		trigger.push_back(ESkill_Trigger_Action);
		trigger.push_back(ESkill_Trigger_ActionAddSelfMaxAttack);
		if(option == EOTSkill)
		{
			SFightMember *pSrc = GetFightMember(src);
			if(pSrc != NULL)
			{
				int skillLevel = pSrc->GetSkillLevel(para);
				CalculatePassiveSkill_ExtUnitAndBuff(src,target,trigger,para,skillLevel);
			}
		}
		else
		{
			CalculatePassiveSkill_ExtUnitAndBuff(src,target,trigger,0,0);
		}
		damageNum += MergeExtActionMsg(msg);

		if(option == EOTNormal)	// 普通攻击
		{
			if(NormalButtle(src,target) > 0)
				AddTeamRage(src,8);
		}
		else if(option == EOTSkill)	// 使用技能
		{
			HeroSkillRoleCfg *pRoleCfg = SingletonCSkillMgr::instance().GetHeroSkillRoleCfg(GetHeroId(src));
			bool isTactic = pRoleCfg != NULL && para == pRoleCfg->tacticSkillId;
			bool isRegular = pRoleCfg != NULL && para == pRoleCfg->regularSkillId;
			if(isTactic)
			{
				AddTeamRage(src,-GetTacticCost(src,*pRoleCfg));
				m_tacticUsedThisTurn[src <= GROUP2_BEGIN ? EGT_GROUP1 : EGT_GROUP2] = true;
			}
			SkillButtle(src,para);
			if(isRegular)
				AddTeamRage(src,12 + GetAffixValue(src,46,1));
		}
		else if(option == EOTEscape)	// 逃跑
		{
//			EscapeAction(src);
		}
		else if(option == EOTZhaoHuan)	// 召唤
		{
			continue;
//			SFightMember *p = GetFightMember(allMem[i]);
//			if(p == NULL)
//				break;
//			if(p->celue == CL_XunChaShi)
//				damageNum += XunChaShiZhaoHuan(allMem[i],msg);
		}
		else
		{
			continue;
		}
		
		if(HaveShieldState(src) && TryTriggerAffix(src,4))
			AddTeamRage(src,GetAffixValue(src,4,1));

		DecAllStateEffectTurn(src);
		MakeBuffList(src, m_actionMsg);

		bool addOtherMsg = false;
		if(option == EOTNormal || option == EOTSkill)
			addOtherMsg = true;
		// 死亡判定
		damageNum += DiePassiveAcion(msg);
		if(!m_members[src-1].killList.empty())
		{
			AddTeamRage(src,10 * (int)m_members[src-1].killList.size());
			if(TryTriggerAffix(src,20) && Random(1,10000) <= GetAffixValue(src,20,1))
				m_members[src-1].DecAllSkillCD(GetAffixValue(src,20,2));
		}
		for(uint16 dieIndex=0;dieIndex<m_dieList.size();dieIndex++)
			AddTeamRage(m_dieList[dieIndex],15);
		damageNum += MergeUnitAcionMsg(msg,addOtherMsg);

		// 非击杀 重新出手判断
		damageNum += NotKilledAction(src,msg);

		// 击杀判定
		while(1)
		{
			uint8 addNum = KilledAction(src,msg);
			if(addNum == 0)
				break;
			damageNum += addNum;
			if(m_members[src-1].killUnit_ext_IsLimit)
				break;
		}
	}while(num > 0);

	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		if(!m_members[pos].memPtr.empty())
			TurnOver(pos+1);
	}
	damageNum += MergeExtActionMsg(msg);

	if(damageNum > 0)
		msg.WriteData(numPos,&damageNum,sizeof(damageNum));

	uint8 membersNum = 0;
	uint16 membersPos = msg.GetDataLen();
	msg<<membersNum;
	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		if(m_members[pos].memPtr.empty())
			continue;
		membersNum++;
		msg<<(uint8)(pos+1);
		MakeBuffList(pos+1,msg);
	}
	msg.WriteData(membersPos,&membersNum,sizeof(membersNum));
	m_fightTurn++;
}

void CFight::ReadBuffListFromMsg(CNetMessage &msg, uint8 &state, vector<uint8> &buffList)
{
	state = 0;
	buffList.clear();

	uint8 buffNum = 0;
	msg>>state>>buffNum;
	cout<<"\n state="<<(int)state<<", buffNum="<<(int)buffNum;
	for(uint8 i=0; i < buffNum; i++)
	{
		uint8 buffId = 0;
		msg>>buffId;
		buffList.push_back(buffId);
		cout<<", buffId="<<(int)buffId;
	}
	cout<<endl;
}

void CFight::PrintMsg(CNetMessage &msg)
{
	cout<<"======= start print netData ====== turn="<<m_fightTurn<<endl;
	CNetMessage m;
	m.AddNetMsgExceptHead(msg);
	m.PrintMsg();
	cout<<"======= msgLen="<<m.GetDataLen()<<endl;

	uint8 op=0;
	uint8 damageNum = 0;
	m>>op>>damageNum;
	cout<<"op="<<(int)op<<", damageNum="<<(int)damageNum<<endl;
	for(uint8 i=0;i < damageNum;i++)
	{
		uint8 action = 0;
		uint8 src = 0;
		uint8 target = 0;
		uint16 skillId = 0;
		uint8 targetNum = 0;
		m>>action;
		cout<<">> read action="<<(int)action<<endl;
		if(action == 1)
		{
			uint8 lianjiNum = 0;
			m>>src>>skillId>>lianjiNum;
			cout<<"技能action="<<(int)action<<", src="<<(int)src<<", skillId="<<skillId<<", lianjiNum="<<(int)lianjiNum<<endl;
			for(uint8 j=0;j < lianjiNum;j++)
			{
				m>>targetNum;
				cout<<", targetNum="<<(int)targetNum<<endl;
				for(uint8 k=0;k < targetNum;k++)
				{
					uint8 hit=0;
					uint8 protect = 0;
					m>>target>>hit;
					cout<<", target = "<<(int)target<<endl;
					if(hit == 0)
						cout<<"闪避";
					else
					{
						m>>protect;
						cout<<"命中"<<", protect="<<(int)protect;
						if(protect > 0)
						{
							int proDamage = 0;
							int absorpionHp = 0;
							int proRDamage = 0;
							m>>proDamage>>absorpionHp>>proRDamage;
							cout<<", proDamage="<<proDamage<<", absorpionHp="<<absorpionHp<<", proRDamage="<<proRDamage;

							cout<<", protect unit";
							uint8 state = 0;
							vector<uint8> buffList;
							ReadBuffListFromMsg(m, state, buffList);
						}
						uint8 baoji = 0;
						uint32 damage = 0;
						int absorpionHp = 0;
						uint32 rdamage = 0;
						uint8 fanzhen = 0;
						m>>baoji>>damage>>absorpionHp>>rdamage>>fanzhen;
						cout<<", baoji="<<(int)baoji<<", damage="<<damage<<", absorpionHp="<<absorpionHp<<", rdamage="<<rdamage<<", fanzhen="<<(int)fanzhen;
						if(fanzhen == 1)
						{
							uint32 fanzhenDam = 0;
							int absorpionHp = 0;
							uint32 frdamage = 0;
							m>>fanzhenDam>>absorpionHp>>frdamage;
							cout<<", fanzhenDam="<<(int)fanzhenDam<<", absorpionHp="<<absorpionHp<<", frdamage="<<frdamage;
						}
						uint8 fanji=0;
						m>>fanji;
						cout<<", fanji="<<(int)fanji;
						if(fanji > 0)
						{
							uint8 fhit = 0;
							m>>fhit;
							cout<<", fhit="<<(int)fhit;
							if(fhit > 0)
							{
								uint8 fbaoji = 0;
								uint32 fdamage2 = 0;
								int absorpionHp = 0;
								uint32 frdamage2 = 0;
								m>>fbaoji>>fdamage2>>absorpionHp>>frdamage2;
								cout<<", fbaoji="<<(int)fbaoji<<", fdamage2="<<fdamage2<<", absorpionHp="<<absorpionHp<<", frdamage2="<<frdamage2;
							}
						}
					}

					cout<<", target unit";
					uint8 state = 0;
					vector<uint8> buffList;
					ReadBuffListFromMsg(m, state, buffList);
				}
			}
			
			int srcDecHp=0;
			int absorpionHp = 0;
			int srcRHp = 0;
			m>>srcDecHp>>absorpionHp>>srcRHp;
			cout<<", srcDecHp="<<srcDecHp<<", absorpionHp="<<absorpionHp<<", srcRHp="<<srcRHp;

			cout<<", src unit";
			uint8 state = 0;
			vector<uint8> buffList;
			ReadBuffListFromMsg(m, state, buffList);

			uint8 otherNum = 0;
			m>>otherNum;
			cout<<", otherNum="<<(int)otherNum;
			for(uint8 t=0;t < otherNum;t++)
			{
				uint8 pos = 0;
				int addHp = 0;
				int absorpionHp = 0;
				int rHp = 0;
				m>>pos>>addHp>>absorpionHp>>rHp;
				cout<<", pos="<<(int)pos<<", addHp="<<addHp<<", absorpionHp="<<absorpionHp<<", rHp="<<rHp;

				cout<<", other unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}
			cout<<endl;
		}
		else if(action == 2)
		{
			m>>src>>skillId>>targetNum;
			cout<<"加血action="<<(int)action<<", src="<<(int)src<<", skillId="<<skillId<<", targetNum="<<(int)targetNum<<endl;
			for(uint8 j=0;j < targetNum;j++)
			{
				uint8 baoji = 0;
				uint32 addHp = 0;
				m>>target>>baoji>>addHp;
				cout<<", target = "<<(int)target<<", baoji="<<(int)baoji<<", addHp="<<addHp<<endl;

				cout<<", target unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}

			cout<<", src unit";
			uint8 state = 0;
			vector<uint8> buffList;
			ReadBuffListFromMsg(m, state, buffList);

			uint8 otherNum = 0;
			m>>otherNum;
			cout<<", otherNum="<<(int)otherNum;
			for(uint8 t=0;t < otherNum;t++)
			{
				uint8 pos = 0;
				int addHp = 0;
				int absorpionHp = 0;
				int rHp = 0;
				m>>pos>>addHp>>absorpionHp>>rHp;
				cout<<", pos="<<(int)pos<<", addHp="<<addHp<<", absorpionHp="<<absorpionHp<<", rHp="<<rHp;

				cout<<", other unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}
			cout<<endl;
		}
		else if(action == 3)
		{
			m>>src>>skillId>>targetNum;
			cout<<"buff action="<<(int)action<<", src="<<(int)src<<", skillId="<<skillId<<", targetNum="<<(int)targetNum<<endl;
			for(uint8 j=0;j < targetNum;j++)
			{
				uint8 isActive = 0;
				m>>target>>isActive;
				cout<<", target = "<<(int)target<<", isActive="<<(int)isActive<<endl;

				cout<<", target unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}

			cout<<", src unit";
			uint8 state = 0;
			vector<uint8> buffList;
			ReadBuffListFromMsg(m, state, buffList);

			uint8 otherNum = 0;
			m>>otherNum;
			cout<<", otherNum="<<(int)otherNum;
			for(uint8 t=0;t < otherNum;t++)
			{
				uint8 pos = 0;
				int addHp = 0;
				int absorpionHp = 0;
				int rHp = 0;
				m>>pos>>addHp>>rHp;
				cout<<", pos="<<(int)pos<<", addHp="<<addHp<<", absorpionHp="<<absorpionHp<<", rHp="<<rHp;

				cout<<", other unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}
			cout<<endl;
		}
		else if(action == 4)
		{
			uint8 targetNum = 0;
			m>>targetNum;
			cout<<"buff action="<<(int)action<<",  targetNum="<<(int)targetNum<<endl;
			for(uint8 i=0;i < targetNum;i++)
			{
				uint8 unitType = 0;
				m>>unitType;
				if(unitType == 0)
				{
					uint8 pos;
					uint32 pic,scale,maxHp,hp;
					string name;
					uint16 level;
					uint8 firstCartonType;
					uint8 monType;
					m>>pos>>pic>>scale>>name>>level>>maxHp>>hp>>firstCartonType>>monType;

					cout<<", add unit";
					uint8 state = 0;
					vector<uint8> buffList;
					ReadBuffListFromMsg(m, state, buffList);

					uint8 quality;
					m>>quality;
					cout<<", unitType=0 ,  pos="<<(int)pos<<", monsterName="<<name<<", quality="<<(int)quality<<endl;
				}
				else if(unitType == 2)
				{
					uint8 pos;
					uint32 petId,scale,maxHp,hp;
					string name;
					uint16 level;
					m>>pos>>petId>>scale>>name>>level>>maxHp>>hp;

					cout<<", add unit";
					uint8 state = 0;
					vector<uint8> buffList;
					ReadBuffListFromMsg(m, state, buffList);

					uint8 quality;
					uint32 petOwner;
					m>>petOwner>>quality;
					cout<<", unitType=2 ,  pos="<<(int)pos<<", petId="<<petId<<", name="<<name<<", quality="<<(int)quality<<endl;
				}
			}
		}
		else if(action == 5)
		{
			uint8 isSuccess=0;
			m>>src>>isSuccess;
			uint8 num = 0;
			m>>num;
			for(uint8 t=0;t < num;t++)
			{
				uint8 target = 0;
				m>>target;
			}
			cout<<"逃跑 action="<<(int)action<<", src="<<(int)src<<", isSuccess="<<(int)isSuccess<<endl;
		}
		else if(action == 6)
		{
			uint8 src = 0;
			uint16 additiveEffectId = 0;
			string showString;
			m>>src>>additiveEffectId>>showString>>targetNum;
			cout<<"被动触发action="<<(int)action<<", src="<<(int)src<<", additiveEffectId="<<additiveEffectId<<", showString="<<showString<<",targetNum="<<(int)targetNum<<endl;
			for(uint8 j=0;j < targetNum;j++)
			{
				int addHp = 0;
				int absorpionHp = 0;
				int rHp = 0;
				m>>target>>addHp>>absorpionHp>>rHp;
				cout<<", target = "<<(int)target<<", addHp="<<(int)addHp<<", absorpionHp="<<absorpionHp<<", rHp="<<rHp<<endl;

				cout<<", target unit";
				uint8 state = 0;
				vector<uint8> buffList;
				ReadBuffListFromMsg(m, state, buffList);
			}
			cout<<endl;
		}
		else if(action == 7)
		{
			m>>src;
			uint8 lastTime = 0;
			string dialog;
			m>>lastTime>>dialog;
			cout<<", src="<<(int)src<<", lastTime="<<(int)lastTime<<", dialog="<<dialog<<endl;
		}
	}

	uint8 memNum = 0;
	m>>memNum;
	cout<<"turnOver ** memNum="<<(int)memNum<<endl;
	for(uint8 i=0;i < memNum;i++)
	{
		uint8 memberPos = 0 ;
		m>>memberPos;
		cout<<", memberPos="<<(int)memberPos;

		cout<<", member unit";
		uint8 state = 0;
		vector<uint8> buffList;
		ReadBuffListFromMsg(m, state, buffList);
	}
	cout<<endl;

	for(uint8 pos = 1; pos <= MAX_MEMBER;pos++)
	{
		if(!IsEmpty(pos))
			cout<<"pos = "<<(int)pos<<", hp="<<GetHp(pos)<<", maxHp="<<GetMaxHp(pos)<<endl;
	}

	cout<<"======= end print netData ======turn="<<m_fightTurn<<endl;
}

void CFight::InitActionFirstGroup()
{
	uint32 zhandouli[2] = {0, 0};
	for(uint8 i=0; i <= EGT_GROUP2; i++)
	{
		uint8 size = m_groupUser[i].size();
		for(uint8 j=0; j < size; j++)
		{
			CUser *pU = m_groupUser[i][j].get();
			if(pU == NULL)
				continue;
			zhandouli[i] += pU->GetZhanDouLi();
		}
	}
	
	m_ActionFirstGroup = (zhandouli[0] > zhandouli[1]) ? EGT_GROUP1 : EGT_GROUP2;
}

void CFight::SetFightEndCondition(vector<SFightEndData> &val)
{
	if(val.empty())
		return;
	m_endCond.assign(val.begin(), val.end());
}

void CFight::AddGroupUnitsAttr(uint8 group, vector<SAttrData> &attr)
{
	if(group != EGT_GROUP1 && group != EGT_GROUP2)
		return;
	if(attr.empty())
		return;
	
	uint8 begin = (group == EGT_GROUP1) ? 0 : GROUP2_BEGIN;
	uint8 end = (group == EGT_GROUP1) ? GROUP2_BEGIN : MAX_MEMBER;
	for(uint8 pos = begin; pos < end; pos++)
	{
		SFightMember *pMem = GetFightMember(pos+1);
		if(pMem == NULL)
			continue;
		int srcMaxHp = pMem->unitAttr.maxHp;
		pMem->unitAttr.AddAttrValue(attr);
		pMem->hp += pMem->unitAttr.maxHp - srcMaxHp;
	}
}

uint8 CFight::AddBossToFight(uint32 bossId, uint8 pos, uint8 zhenfaPos, uint64 &hp, SMonsterInst **ppMonster)
{
	ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateMonsterBossById(bossId);
	SMonsterInst *pInst = ptr.get();
	if(pInst == NULL || pInst->id == 0)
		return 0;
	if(ppMonster != NULL)
		*ppMonster = pInst;
	if(hp != 0)
	{
		pInst->hp = hp;
		if(pInst->hp > pInst->attr.maxHp)
			pInst->hp = pInst->attr.maxHp;
	}
	AddMonster(ptr, pos,zhenfaPos);
	return pInst->level;
}

bool CFight::AddMonsterWithFightId(int fightId, const vector<uint64> &hpList, int group)
{
	if(fightId < 1)
		return false;
	CFightCfgManager &cfgMgr = SingletonCFightCfgManager::instance();
	SFightCfgData *pFightCfg = cfgMgr.GetFightCfg(fightId);
	if(pFightCfg == NULL || pFightCfg->zhenfa_id == 0)
		return false;
	vector<SFightDialogCfg> dialog;
	if(pFightCfg->fight_dialog_id > 0)
	{
		cfgMgr.GetFightDialog(dialog,pFightCfg->fight_dialog_id);
		SetDialog(dialog);
	}
	bool setHp = false;
	if(hpList.size() >= ZHEN_FA_POS_NUM)
		setHp = true;
	
	uint16 zhenfaLevel = pFightCfg->GetZhenFaLv(0);
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(pFightCfg->zhenfa_id);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(pFightCfg->zhenfa_id,zhenfaLevel);
	if(pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	SetCfgFightId(fightId);
	SetGroupZhenFaData(pFightCfg->zhenfa_id,zhenfaLevel,group);
	SetGroupShowName(group, GetMonsterBossName(pFightCfg->showId));
	for(uint16 i=0;i < sizeof(pFightCfg->bossId)/sizeof(pFightCfg->bossId[0]); i++)
	{
		if(pFightCfg->bossId[i] > 0)
		{
			if(setHp && hpList[i] == 0)	// 怪物死亡,不进战斗
				continue;
			uint64 hp = setHp ? hpList[i] : 0;
			SMonsterInst *pMonster = NULL;
			AddBossToFight(pFightCfg->bossId[i], pZhenFa->fightPos[i]+group*CFight::GROUP_MEMBER, i, hp, &pMonster);
		}
	}
	return true;
}

bool CFight::AddBloodFightMonster(BloodFight& fightCfg, double ratio)
{
	CZhenFaCfgMgr &zhenfaMgr = SingletonCZhenFaCfgMgr::instance();
	SZhenFaBasicCfg *pZhenFa = zhenfaMgr.GetBasicCfg(fightCfg.formation);
	SZhenFaLevelUpData *pZhenFaAttr = zhenfaMgr.GetLevelUpCfg(fightCfg.formation, 1);
	if (pZhenFa == NULL || pZhenFaAttr == NULL)
		return false;
	SetGroupZhenFaData(fightCfg.formation, 1, CFight::EGT_GROUP2);
	SetGroupShowName(CFight::EGT_GROUP2, GetMonsterBossName(fightCfg.show));
	for (uint16 i = 0; i < fightCfg.monster.size(); i++)
	{
		if (fightCfg.monster[i] > 0)
		{
			ShareMonsterPtr ptr = SingletonMonsterBossManager::instance().CreateRatioMonster(fightCfg.monster[i], ratio);
			SMonsterInst *pInst = ptr.get();
			if (pInst == NULL || pInst->id == 0)
				return 0;
			AddMonster(ptr, CFight::GROUP2_BEGIN + pZhenFa->fightPos[i], i);
		}
	}
	return true;
}

void CFight::AddSingleUserToFight(ShareUserPtr &user,uint8 group)
{
	CUser *pUser = user.get();
	if(pUser == NULL || (group != EGT_GROUP1 && group != EGT_GROUP2))
		return;

	vector<SZhenFaMemData> zhenfaMem;
	pUser->GetZhenFaMember(zhenfaMem);
	if(zhenfaMem.empty())
		return;

	uint16 zhenFaId = user->GetUseZhenFaId();
	uint16 zhenFaLv = user->GetUseZhenFaLevel();
	SZhenFaLevelUpData *pZhenFaAttr = SingletonCZhenFaCfgMgr::instance().GetLevelUpCfg(zhenFaId,zhenFaLv);
	if(pZhenFaAttr == NULL)
		return;
	SetGroupZhenFaData(zhenFaId,zhenFaLv,group);
	AddUser(user, group);
	pUser->SetFight(GetId());
	for(uint8 i=0;i < zhenfaMem.size();i++)
	{
		SZhenFaMemData &data = zhenfaMem[i];
		if(data.mem_type == EZFMT_NONE)
			continue;
		if(data.mem_type == EZFMT_USER)
		{
//			uint8 fightPos = data.fightPos + begin;
//			pUser->SetFight(pFight->GetId(),pFight->AddUser(user,fightPos,i));
//			pUser->SetFight(pFight->GetId(),pFight->AddUser(user,fightPos,i));
		}
		else if(data.mem_type == EZFMT_PET)
		{
			uint8 fightPos = data.fightPos + group*GROUP_MEMBER;
			uint32 petId = data.mem_id;
			SharePetPtr pet = pUser->GetPet(petId);
			if(pet.get() == NULL)
				continue;
			AddPet(pet,fightPos,pUser->GetRoleId(),i);
		}
	}
}

uint16 CFight::AddUserGroupToFight(ShareUserPtr &pUser,uint8 group)
{
	CUser *pU = pUser.get();
	if(pU == NULL)
		return 0;
	AddSingleUserToFight(pUser, group);
	return pU->GetLevel();
	
/*
	uint32 teamId = pU->GetTeam();
	if(teamId > 0)
	{
		if(teamId == pU->GetRoleId())
		{
			CUserTeam *pTeam = NULL;
			if (m_userTeams.Find(teamId, pTeam))
			{
				uint16 level = AddTeamToFight(pFight, pTeam, beginPos);
				return level;
			}
		}
	}
	else
	{
		AddSingleUserToFight(pFight, pUser, beginPos, isQunXian);
		return pU->GetLevel();
	}
	return 0;
*/
}

int CFight::GetEndConditionValue(int type)
{
	uint16 size = m_endCond.size();
	for(uint16 i=0; i < size; i++)
	{
		if(type == m_endCond[i].type)
			return m_endCond[i].value;
	}
	return -1;
}

int CFight::GetUserGroupDieNum()
{
	int dieNum = 0;
	for(uint8 i = 0; i < GROUP2_BEGIN; i++)
	{
		if(m_members[i].memPtr.empty())
			continue;
		if(HaveState(i+1, EFST_STATE_Die))
			dieNum++;
	}
	return dieNum;
}

void CFight::CalculateFightResult(bool isfast)
{
//	if(GetSysTime() - m_turnBegin < 3)
//		return;
	CNetMessage msg;
	msg.SetType(PRO_BATTLE);
	CalculateFight(msg);

	m_fightMsgList.push_back(msg);

#ifdef KUA_FU
	uint8 worldBossPos = ShenJieMiJingUpdateBossHp();
#endif

	if(showFightLog)
		PrintMsg(msg);

	if(!isfast)
	{
		BroadcastMsg(msg);
	}

/*
	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 pos = 0; pos < MAX_MEMBER; pos++)
	{
		if(!m_members[pos].memPtr.empty() && (m_members[pos].memPtr.type() == typeid(ShareUserPtr)))
		{
			CUser *pUser = (boost::any_cast<ShareUserPtr>(m_members[pos].memPtr)).get();
			if(pUser->GetFightId() == 0)
				continue;
			if(isfast)	// 快速战斗跳过
				continue;
			sock.SendMsg(pUser->GetSock(),msg);
			if(HaveState(pos+1, EFST_STATE_Escape))
			{
				if(pUser->GetSock() > 0)
				{
					CNetMessage nMsg;
					nMsg.SetType(PRO_BATTLE_OVER);
					nMsg<<m_id<<PRO_ERROR;
					sock.SendMsg(pUser->GetSock(),nMsg);
				}
				
				DelMember(pos+1);
				SendUserPos(pUser,userList);
				pUser->SetFight(0);
				if(pUser->GetSock() > 0)
					UpdateUserInfo(pUser,userList);
				CalculateTaoPao(pUser,pos+1);
			}
		}
	}
*/

#ifdef KUA_FU
	UpdateUnitHp(worldBossPos);
#endif

/*
	if(m_type == EFTJingJiChang)
	{
		string str;
		msg.SetType(MSG_ARENA_VIDIO);
		HexToStr((uint8*)(msg.GetMsgData()->c_str()),msg.GetDataLen(),str);
		arenaInfo += "|";
		arenaInfo += str;
	}
*/

/*
	msg.SetType(GUAGNZHAN_BATTLE);
	for(list<int>::iterator i = m_guanZhanSock.begin(); i != m_guanZhanSock.end(); i++)
	{
		sock.SendMsg(*i,msg);
	}
*/
	m_taopaoList.clear();
}

void CFight::Logout(uint8 pos)
{
	if(pos > MAX_MEMBER)
		return;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	SetState(pos, EFST_STATE_Die);
//	SPet *pPet = GetPet(pos+1);
//	if(pPet != NULL)
//	{
//		SetState(pos+1, EFST_STATE_Die);
//	}
	CNetMessage msg;
	msg.SetType(PRO_BATTLE);
	//离开战斗
	msg<<(uint8)2<<pos;

	CSocketServer &sock = SingletonSocket::instance();

	for(uint8 i = 0; i <= MAX_MEMBER; i++)
	{
		if(i != (pos-1))
		{
			CUser *pUser = GetUser(i);
			if(pUser != NULL)
				sock.SendMsg(pUser->GetSock(),msg);
		}
	}
}

void CFight::UserBattle(CNetMessage &msg,CUser *pUser)
{
	char tbuff[128];
	snprintf(tbuff,sizeof(tbuff),"CFight::UserBattle type=%d",(int)m_type);
	gyu::util::TimePrint ttPrint(tbuff);
	
	if(m_userOpTime == 0)
		m_userOpTime = GetSysTime();

	uint8 playOp = 0;
	int playPara = 0;
	msg>>playOp>>playPara;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
//	uint8 pos = pUser->GetFightPos();
//	SetOption(pos, CFight::EOTAuto, 0, 0);
	CalculateFightResult();

/*
	if(playOp == CFight::EOTEscape || playOp == CFight::EOTAuto)	//设置自动战斗
	{
		uint8 pos = pUser->GetFightPos();
		if(pos <= MAX_MEMBER && !m_members[pos-1].select)
		{
			if(playOp == CFight::EOTEscape)
			{
				m_taopaoList.push_back(pos);
				playOp = CFight::EOTAuto;
			}
			SetOption(pos,playOp,0,0);
		}
	}
	else if(playOp == CFight::EOTSkill)
	{
		pUser->SaveAutoFight(playOp,playPara);
		SetOption(pUser->GetFightPos(),playOp,playPara,0);
	}

	SendUserSelect(pUser->GetFightPos());
	
	uint32 mask = 0;
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			if(pUser->GetSock() != -1)
				mask |= 1<<pos;
//			else
//				ArenaAutoFightSet(pUser,pos);
		}
	}
	
	m_beginTurnMask |= (1<<pUser->GetFightPos());
	if(m_beginTurnMask == mask)
	{
		if(AllUserOption())
		{
			CalculateFightResult(userList);
			m_beginTurnMask = 0;
		}
	}
*/
}

bool CFight::GetFightAllNetMsg(CNetMessage &msg, int type)
{
	if(type < EFPT_Jump || type > EFPT_PlayBack_2)
		return false;
	
	msg.ReWrite();
	msg.SetType(PRO_FIGHT_OPTION);
	if(type == EFPT_Jump)
		msg<<(uint8)3;
	else if(type == EFPT_PlayBack_1)
		msg<<(uint8)4;
	else
		msg<<(uint8)5;
	
	uint16 num = 0;
	uint32 pos = msg.GetDataLen();
	uint16 size = m_fightMsgList.size();
	msg<<num;
	for(uint16 i=0; i < size; i++)
	{
		msg<<m_fightMsgList[i];
		num++;
	}

	if(msg.GetDataLen() > 30000)
	{
		cout<<">> CFight::GetFightAllNetMsg MSG_LEN="<<msg.GetDataLen()<<endl;
	}
	if(num > 0)
	{
		msg.WriteData(pos, &num, sizeof(num));
		return true;
	}
	return false;
}

void CFight::CancelAutoFight(CUser *pUser)
{
	if(pUser->IsAutoFight())
	{
		pUser->SetAutoFightTurn(0);
		CNetMessage msg;
		msg.SetType(PRO_BATTLE);
		msg<<(uint8)3;//通知客户端取消战斗
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(pUser->GetSock(),msg);
	}
}

void CFight::SendUserSelect(uint8 pos)
{
	CNetMessage msg;
	msg.SetType(PRO_BATTLE);
	msg<<(uint8)6<<pos;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 i = 0; i < MAX_MEMBER; i++)
	{
		CUser *pUser = GetUser(i+1);
		if(pUser != NULL && !HaveState(i+1, EFST_STATE_Escape))
			sock.SendMsg(pUser->GetSock(),msg);
	}

	// 观战
	msg.SetType(GUAGNZHAN_BATTLE);
	for(list<int>::iterator i = m_guanZhanSock.begin(); i != m_guanZhanSock.end(); i++)
	{
		sock.SendMsg(*i,msg);
	}
}

void CFight::GetAllMember(uint8 *arr,uint8 &num)
{
	num = 0;
	for(uint8 i = 0; i < MAX_MEMBER; i++)
	{
		if(!m_members[i].memPtr.empty())
		{
			arr[num] = i+1;
			num++;
		}
	}
}

void CFight::GetAllUnitByOrder(uint8 *arr, uint8 &num)
{
	const uint8 ORDER_1[] = {EGT_GROUP1, EGT_GROUP2};
	const uint8 ORDER_2[] = {EGT_GROUP2, EGT_GROUP1};
	const uint8 *p = ORDER_1;
	uint8 size = sizeof(ORDER_1)/sizeof(ORDER_1[0]);
	if(m_ActionFirstGroup == EGT_GROUP2)
		p = ORDER_2;

	num = 0;
	for(uint8 i = 0; i < GROUP2_BEGIN; i++)
	{
		for(uint8 j=0; j < size; j++)
		{
			uint8 pos = i + p[j] * GROUP_MEMBER;
			if(!m_members[pos].memPtr.empty())
			{
				arr[num] = pos+1;
				num++;
			}
		}
	}
}

void CFight::GetTargetGroup(uint8 me,uint8 *arr,uint8 &num,bool myGroup)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if((me <= GROUP2_BEGIN && !myGroup) || (me > GROUP2_BEGIN && myGroup))
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}

	num = 0;
	for(uint8 i = begin; i <= end; i++)
	{
		if((!m_members[i-1].memPtr.empty()) && IsAlive(i))
		{
			arr[num] = i;
			num++;
		}
	}
}

void CFight::GetAllMemberExceptSelf(uint8 me,uint8 *arr,uint8 &num)
{
	num = 0;
	for(uint8 i = 1; i <= MAX_MEMBER; i++)
	{
		if(i != me && (!m_members[i-1].memPtr.empty()) && IsAlive(i))
		{
			arr[num] = i;
			num++;
		}
	}
}

void CFight::GetMeGroupExceptSelf(uint8 me,uint8 *arr,uint8 &num)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(me > GROUP2_BEGIN)
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}

	num = 0;
	for(uint8 i = begin; i <= end; i++)
	{
		if((!m_members[i-1].memPtr.empty()) && IsAlive(i) && i != me)
		{
			arr[num] = i;
			num++;
		}
	}
}

void CFight::GetAnotherGroupExceptTar(uint8 me,uint8 target,uint8 *arr,uint8 &num)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(me <= GROUP2_BEGIN)
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}

	num = 0;
	for(uint8 i = begin; i <= end; i++)
	{
		if((!m_members[i-1].memPtr.empty()) && IsAlive(i) && i != target)
		{
			arr[num] = i;
			num++;
		}
	}
}

uint8 CFight::FindYuanHuPos(uint8 groupPos)
{
	if(groupPos < 1 || groupPos > MAX_MEMBER)
		return 0;

	uint8 begin = (groupPos <= GROUP2_BEGIN) ? 1 : (GROUP2_BEGIN+1);
	uint8 end = (groupPos <= GROUP2_BEGIN) ? GROUP2_BEGIN : MAX_MEMBER;
	CSkillMgr &skillMgr = SingletonCSkillMgr::instance();
	for(uint8 pos = begin; pos <= end; pos++)
	{
		SFightMember *pSrc = GetFightMember(pos);
		if(pSrc == NULL)
			continue;
		for(uint16 i=0;i < pSrc->passive_skill.size();i++)
		{
			SSkillData &skillData = pSrc->passive_skill[i];
			vector<int> passiveList;
			skillMgr.GetSkillPassiveData(skillData.id, ESkill_Trigger_MinHpBeAttacked, passiveList);
			if(passiveList.empty())
				continue;
			for(uint16 k=0;k < passiveList.size();k++)
			{
				int passiveId = passiveList[k];
				SSkillAdditiveEffect *pEffect = skillMgr.GetAdditiveEffectCfg(passiveId);
				if(pEffect == NULL)
					continue;
				if(pEffect->type == ESkill_Pass_ShareDamage)
					return pos;
			}
		}
	}
	return 0;
}

bool CFight::HaveDieMember(uint8 me)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(me > GROUP2_BEGIN)
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}

	for(uint8 pos = begin; pos <= end; pos++)
	{
		if((!m_members[pos-1].memPtr.empty()) && !IsAlive(pos))
		{
			return true;
		}
	}
	return false;
}

bool CFight::HaveLoseHpMember(uint8 me)
{
	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	if(me > GROUP2_BEGIN)
	{
		begin += GROUP_POS_STEP;
		end += GROUP_POS_STEP;
	}

	for(uint8 pos = begin; pos <= end; pos++)
	{
		SFightMember *p = GetFightMember(pos);
		if(p != NULL && IsAlive(pos))
		{
			if(p->hp < p->unitAttr.maxHp)
				return true;
		}
	}
	return false;
}

void CFight::GetMeGroup(uint8 me,uint8 *arr,uint8 &num)
{
	GetTargetGroup(me,arr,num,true);
}

void CFight::GetAnotherGroup(uint8 me,uint8 *arr,uint8 &num)
{
	GetTargetGroup(me,arr,num,false);
}

void CFight::GetSkillTargetRange(uint8 me,uint16 skillId,uint16 skillLv,uint8 *array,uint8 &num)
{
	num = 0;
	if(array == NULL)
		return;
	
	CSkillMgr &mgr = SingletonCSkillMgr::instance();
	SSkillCfgData *pSkillCfg = mgr.GetSkillCfg(skillId);
	if(pSkillCfg == NULL)
		return;
	if(pSkillCfg->type == ESKILL_Passive) // 被动
		return;
	if(pSkillCfg->activeEffect.effectType != 1)
		return;
	
	int activeEffId = pSkillCfg->activeEffect.GetEffectId();
	SSkillActiveEffect *pActive = mgr.GetActiveEffectCfg(activeEffId);
	if(pActive == NULL)
		return;

	uint8 begin = 1;
	uint8 end = GROUP2_BEGIN;
	uint8 posOffSet = 0;
	bool alive = true;
	bool myGroup = false;
	if(pActive->effect_type == ESkill_Active_FuHuo)	// 复活技能,寻找死亡单位
	{
		alive = false;
	}
	if(pActive->target_group == ESkill_Target_Self)	// 己方
	{
		myGroup = true;
		if(me > GROUP2_BEGIN)
		{
			posOffSet = GROUP_MEMBER;
			begin += GROUP_MEMBER;
			end += GROUP_MEMBER;
		}
	}
	else	// 敌方
	{
		myGroup = false;
		if(me <= GROUP2_BEGIN)
		{
			posOffSet = GROUP_MEMBER;
			begin += GROUP_MEMBER;
			end += GROUP_MEMBER;
		}
	}

	const uint8 nRow = 3;
	const uint8 nColumn = 3;
	const uint8 PosRow1[nRow][nColumn] = {{1,2,3},{4,5,6},{7,8,9}};	// 每排单位,优先对面单位%3=1
	const uint8 PosRow2[nRow][nColumn] = {{2,1,3},{5,4,6},{8,7,9}};	// 每排单位,优先对面单位%3=2
	const uint8 PosRow3[nRow][nColumn] = {{3,2,1},{6,5,4},{9,8,7}};	// 每排单位,优先对面单位%3=0
	const uint8 RowFront[nRow] = {1,2,3};	// 优先前排，排序号
	const uint8 RowMid[nRow] = {2,1,3};		// 优先中排，排序号
	const uint8 RowBack[nRow] = {3,2,1};	// 优先后排，排序号

	switch(pActive->target_range)
	{
	case ESkill_Range_Normal:
		{
			GetGroupByAttackedOrder(me,array,num,myGroup,alive);
		}
		break;
	case ESkill_Range_FrontRow:
	case ESkill_Range_MidRow:
	case ESkill_Range_BackRow:	// 先选对应的排，无单位选其他排
		{
			uint8 column = me%3;
			const uint8 *rowIdx = NULL;
			const uint8 (*pRow)[nColumn] = NULL;
			if(column == 1)
				pRow = PosRow1;
			else if(column == 2)
				pRow = PosRow2;
			else
				pRow = PosRow3;
			if(pActive->target_range == ESkill_Range_FrontRow)
				rowIdx = RowFront;
			else if(pActive->target_range == ESkill_Range_MidRow)
				rowIdx = RowMid;
			else
				rowIdx = RowBack;
			for(uint8 i=0;i < nRow;i++)
			{
				for(uint8 j=0;j < nColumn;j++)
				{
					uint8 pos = pRow[rowIdx[i]-1][j] + posOffSet;
					if(!m_members[pos-1].memPtr.empty())
					{
						if((alive && IsAlive(pos)) || (!alive && !IsAlive(pos)))
							array[num++] = pos;
					}
				}
				if(num > 0)
					break;
			}
		}
		break;
	case ESkill_Range_FrontMidRow:	// 先前中排，无单位则选后排
	case ESkill_Range_Front2Row:	// 前两排
		{
			uint8 column = me%3;
			const uint8 (*pRow)[nColumn] = NULL;
			if(column == 1)
				pRow = PosRow1;
			else if(column == 2)
				pRow = PosRow2;
			else
				pRow = PosRow3;
			int rowNum = 0;
			for(uint8 i=0;i < nRow;i++)
			{
				bool findUnit = false;
				for(uint8 j=0;j < nColumn;j++)
				{
					uint8 pos = pRow[i][j] + posOffSet;
					if(!m_members[pos-1].memPtr.empty())
					{
						if((alive && IsAlive(pos)) || (!alive && !IsAlive(pos)))
						{
							array[num++] = pos;
							findUnit = true;
						}
					}
				}
				if(findUnit)
					rowNum++;
				if(pActive->target_range == ESkill_Range_FrontMidRow)	// 前中排，未找到单位则选后排
				{
					if(i == 1 && num > 0)
						break;
				}
				else if(pActive->target_range == ESkill_Range_Front2Row)	// 前两排
				{
					if(rowNum >= 2)
						break;
				}
			}
		}
		break;
	case ESkill_Range_Column:	// 列
		{
			const uint8 PosColumn1[nColumn][nRow] = {{1,4,7},{2,5,8},{3,6,9}};
			const uint8 PosColumn2[nColumn][nRow] = {{2,5,8},{1,4,7},{3,6,9}};
			const uint8 PosColumn3[nColumn][nRow] = {{3,6,9},{2,5,8},{1,4,7}};

			const uint8 (*pColumn)[nRow] = NULL;
			uint8 column = me%3;
			if(column == 1)
				pColumn = PosColumn1;
			else if(column == 2)
				pColumn = PosColumn2;
			else
				pColumn = PosColumn3;
			for(uint8 i=0;i < nColumn;i++)
			{
				for(uint8 j=0;j < nRow;j++)
				{
					uint8 pos = pColumn[i][j] + posOffSet;
					if(!m_members[pos-1].memPtr.empty())
					{
						if((alive && IsAlive(pos)) || (!alive && !IsAlive(pos)))
							array[num++] = pos;
					}
				}
				if(num > 0)
					break;
			}
		}
		break;
	case ESkill_Range_AllRand:
		{
			for(uint8 pos=begin;pos <= end;pos++)
			{
				if(!m_members[pos-1].memPtr.empty())
				{
					if((alive && IsAlive(pos)) || (!alive && !IsAlive(pos)))
						array[num++] = pos;
				}
			}
		}
		break;
	case ESkill_Range_Self:
		{
			array[num++] = me;
		}
		break;
	default:
		return;
	}

	GetSkillTargetSelCondition(array,num,pActive->target_select);

	if(num > (uint8)pActive->target_num)
		num = pActive->target_num;
}

void CFight::GetSkillTargetSelCondition(uint8 *array,uint8 &num,int target_select)
{
	if(array == NULL || num <= 1)
		return;

	switch(target_select)
	{
	case ESkill_Select_Normal:
		{
			
		}
		break;
	case ESkill_Select_Rand:
		{
			uint8 temp[GROUP_MEMBER];
			int randSeq[GROUP_MEMBER];
			if(!RandomSequence(randSeq,num,num))
				return;
			for(uint8 i=0;i < num;i++)
				temp[i] = array[randSeq[i]-1];
			for(uint8 i=0;i < num;i++)
				array[i] = temp[i];
		}
		break;
	case ESkill_Select_MaxCurHp:
	case ESkill_Select_MinCurHp:
	case ESkill_Select_MinCurHpPer:
	case ESkill_Select_MaxDamage:
	case ESkill_Select_MaxWuGong:
	case ESkill_Select_MaxFaGong:
	case ESkill_Select_MaxWuFang:
	case ESkill_Select_MinWuFang:
	case ESkill_Select_MaxFaFang:
	case ESkill_Select_MinFaFang:
	case ESkill_Select_MaxSpeed:
	case ESkill_Select_MaxFangYu:
		{
			SSortData temp[GROUP_MEMBER];
			uint8 tNum = 0;
			for(uint8 i=0;i < num;i++)
			{
				temp[tNum].data = array[i];
				SFightMember *p = GetFightMember(array[i]);
				if(p == NULL)
					continue;
				if(target_select == ESkill_Select_MaxCurHp || target_select == ESkill_Select_MinCurHp)
					temp[tNum++].value = p->hp;
				else if(target_select == ESkill_Select_MinCurHpPer)
					temp[tNum++].value = p->hp*10000.0/p->unitAttr.maxHp;
				else if(target_select == ESkill_Select_MaxDamage)
					temp[tNum++].value = p->unitAttr.attack;
				else if(target_select == ESkill_Select_MaxWuGong)
					temp[tNum++].value = (p->attackType == 1) ? (p->unitAttr.attack) : 0;
				else if(target_select == ESkill_Select_MaxFaGong)
					temp[tNum++].value = (p->attackType == 2) ? (p->unitAttr.attack) : 0;
				else if(target_select == ESkill_Select_MaxWuFang || target_select == ESkill_Select_MinWuFang)
					temp[tNum++].value = p->unitAttr.wufang;
				else if(target_select == ESkill_Select_MaxFaFang || target_select == ESkill_Select_MinFaFang)
					temp[tNum++].value = p->unitAttr.fafang;
				else if(target_select == ESkill_Select_MaxSpeed)
					temp[tNum++].value = p->unitAttr.speed;
				else if(target_select == ESkill_Select_MaxFangYu)
					temp[tNum++].value = max(p->unitAttr.wufang,p->unitAttr.fafang);
			}
			if(target_select == ESkill_Select_MinCurHp || target_select == ESkill_Select_MinCurHpPer || target_select == ESkill_Select_MinWuFang || target_select == ESkill_Select_MinFaFang)
				std::sort(temp,temp+tNum,MinToMaxSort);
			else
				std::sort(temp,temp+tNum,MaxToMinSort);
			num = tNum;
			for(uint8 i=0;i < num;i++)
				array[i] = temp[i].data;
		}
		break;
	case ESkill_Select_EnBuff:
	case ESkill_Select_DeBuff:
	case ESkill_Select_Shield:	// 护盾
	case ESkill_Select_DieUnit:	// 死亡
	case ESkill_Select_ZhuoShao:	// 灼烧
	case ESkill_Select_ZhongDu:	// 中毒
		{
			uint8 tarPos[GROUP_MEMBER];
			uint8 tarNum = 0;
			uint8 backPos[GROUP_MEMBER];
			uint8 backNum = 0;
			for(uint8 i=0;i < num;i++)
			{
				if(target_select == ESkill_Select_EnBuff)
				{
					if(HaveEnBuffState(array[i]))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
				else if(target_select == ESkill_Select_DeBuff)
				{
					if(HaveDeBuffState(array[i]))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
				else if(target_select == ESkill_Select_Shield)
				{
					if(HaveShieldState(array[i]))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
				else if(target_select == ESkill_Select_DieUnit)
				{
					if(!IsAlive(array[i]))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
				else if(target_select == ESkill_Select_ZhuoShao)
				{
					if(HaveBuff(array[i],ESBUFF_ZhuoShao))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
				else if(target_select == ESkill_Select_ZhongDu)
				{
					if(HaveZhongDuState(array[i]))
						tarPos[tarNum++] = array[i];
					else
						backPos[backNum++] = array[i];
				}
			}

			// 先随机取符合条件的目标，不够随机再取不符合条件的目标
			int randSeq[GROUP_MEMBER];
			if(!RandomSequence(randSeq,tarNum,tarNum))
				return;
			for(uint8 i=0;i < tarNum;i++)
				array[i] = tarPos[randSeq[i]-1];
			if(!RandomSequence(randSeq,backNum,backNum))
				return;
			for(uint8 i=0;i < backNum;i++)
				array[tarNum+i] = backPos[randSeq[i]-1];
			num = tarNum+backNum;
		}
		break;
	default:
		return;
	}
}

void CFight::GetGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num,bool myGroup,bool alive)
{
	const uint8 userPos1[] = {1,2,3,4,5,6,7,8,9};
	const uint8 userPos2[] = {2,1,3,5,4,6,8,7,9};
	const uint8 userPos3[] = {3,2,1,6,5,4,9,8,7};

	num = 0;
	uint8 pos = 0;
	for(uint8 i = 0; i < GROUP_MEMBER; i++)
	{
		int idx = me % 3;
		if(idx == 1)
			pos = userPos1[i];
		else if(idx == 2)
			pos = userPos2[i];
		else
			pos = userPos3[i];
		if(myGroup)
			pos += (me > GROUP2_BEGIN) ? GROUP_POS_STEP : 0;
		else
			pos += (me <= GROUP2_BEGIN) ? GROUP_POS_STEP : 0;
		if(!m_members[pos-1].memPtr.empty())
		{
			if(alive && IsAlive(pos))
			{
				arr[num] = pos;
				num++;
			}
			else if(!alive && !IsAlive(pos))
			{
				arr[num] = pos;
				num++;
			}
		}
	}
}

void CFight::GetAnotherGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num)
{
	GetGroupByAttackedOrder(me,arr,num,false);
}

void CFight::GetMeGroupByAttackedOrder(uint8 me,uint8 *arr,uint8 &num)
{
	GetGroupByAttackedOrder(me,arr,num,true);
}

void CFight::GetMeGroupUser(uint8 me,CUser **pHots,uint8 &num)
{
	num = 0;
	if(me < GROUP2_BEGIN)
	{
		for(int i = 0; i < GROUP2_BEGIN; i++)
		{
			if(!m_members[i].memPtr.empty() && (m_members[i].memPtr.type() == typeid(ShareUserPtr)))
				pHots[num++] = (boost::any_cast<ShareUserPtr>(m_members[i].memPtr)).get();
		}
	}
	else
	{
		for(int i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if(!m_members[i].memPtr.empty() && (m_members[i].memPtr.type() == typeid(ShareUserPtr)))
				pHots[num++] = (boost::any_cast<ShareUserPtr>(m_members[i].memPtr)).get();
		}
	}
}


struct HpRatio
{
	uint8 pos;
	double ratio;
};

static bool HpScore(const HpRatio &b1,const HpRatio &b2)
{
	return b1.ratio < b2.ratio;
}

void CFight::GetMeGroupByHpRatioMin2Max(uint8 me,uint8 *arr,uint8 &loseHpNum,uint8 &totolNum)
{
	loseHpNum = 0;
	totolNum = 0;
	HpRatio memberList[MAX_MEMBER/2];
	uint8 begin = 0;
	uint8 end = GROUP2_BEGIN;
	if(me > GROUP2_BEGIN)
	{
		begin = GROUP2_BEGIN;
		end = MAX_MEMBER;
	}
	for(uint8 i = begin; i < end; i++)
	{
		if((!m_members[i].memPtr.empty()) && IsAlive(i+1))
		{
			int hp = GetHp(i+1);
			int maxHp = GetMaxHp(i+1);
			if(maxHp == 0)
				continue;
			if(hp < maxHp)
				loseHpNum++;
			memberList[totolNum].pos = i+1;
			memberList[totolNum].ratio = hp/(double)maxHp;
			totolNum++;
		}
	}

	if(totolNum > 0)
	{
		std::sort(memberList,memberList+totolNum,HpScore);
		for(uint8 i=0;i < totolNum;i++)
			arr[i] = memberList[i].pos;
	}
}

uint8 CFight::GetGroup2UnitsNum()
{
	uint8 num = 0;
	for(uint8 i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
	{
		if(!m_members[i].memPtr.empty())
		{
			num++;
		}
	}
	return num;
}

void CFight::SetPetCeLue(uint16 cl)
{
	for(uint8 i=0;i < MAX_MEMBER;i++)
	{
		SPet *pPet = GetPet(i+1);
		if(pPet != NULL)
			pPet->celue = cl;
	}
}

void CFight::SetUserCeLue(uint16 cl)
{
	for(uint8 i=0;i < MAX_MEMBER;i++)
	{
		CUser *pUser = GetUser(i+1);
		if(pUser != NULL)
			pUser->SetCeLue(cl);
	}
}

void CFight::GetAnotherGroup_User(uint8 me,uint8 *arr,uint8 &num)
{
	uint8 i;
	num = 0;
	if(me <= GROUP2_BEGIN)
	{
		for(i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
			{
				arr[num] = i+1;
				num++;
			}
		}
	}
	else
	{
		for(i = 0; i < GROUP2_BEGIN; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
			{
				arr[num] = i+1;
				num++;
			}
		}
	}
}

// 先人再神将最后怪
void CFight::GetAnotherGroup_UserToPetToMonster(uint8 me,uint8 *arr,uint8 &roleNum,uint8 &petNum,uint8 &monsterNum)
{
	roleNum = 0;
	petNum = 0;
	monsterNum = 0;
	if(me <= GROUP2_BEGIN)
	{
		for(uint8 i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
				arr[roleNum++] = i+1;
		}
		for(uint8 i = GROUP2_BEGIN+1; i < MAX_MEMBER; i++)
		{
			if((GetPet(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum] = i+1;
				petNum++;
			}
		}
		for(uint8 i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if((GetMonster(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum + monsterNum] = i+1;
				monsterNum++;
			}
		}
	}
	else
	{
		for(uint8 i = 0; i < GROUP2_BEGIN; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
				arr[roleNum++] = i+1;
		}
		for(uint8 i = 1; i < GROUP2_BEGIN; i++)
		{
			if((GetPet(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum] = i+1;
				petNum++;
			}
		}
		for(uint8 i = 0; i < GROUP2_BEGIN; i++)
		{
			if((GetMonster(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum + monsterNum] = i+1;
				monsterNum++;
			}
		}
	}
}

// 先人再神将最后怪
void CFight::GetMeGroup_UserToPetToMonster(uint8 me,uint8 *arr,uint8 &roleNum,uint8 &petNum,uint8 &monsterNum)
{
	roleNum = 0;
	petNum = 0;
	monsterNum = 0;
	if(me <= GROUP2_BEGIN)
	{
		for(uint8 i = 0; i < GROUP2_BEGIN; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
				arr[roleNum++] = i+1;
		}
		for(uint8 i = 1; i < GROUP2_BEGIN; i++)
		{
			if((GetPet(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum] = i+1;
				petNum++;
			}
		}
		for(uint8 i = 0; i < GROUP2_BEGIN; i++)
		{
			if((GetMonster(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum + monsterNum] = i+1;
				monsterNum++;
			}
		}
	}
	else
	{
		for(uint8 i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if((GetUser(i+1) != NULL) && IsAlive(i+1))
				arr[roleNum++] = i+1;
		}
		for(uint8 i = GROUP2_BEGIN+1; i < MAX_MEMBER; i++)
		{
			if((GetPet(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum] = i+1;
				petNum++;
			}
		}
		for(uint8 i = GROUP2_BEGIN; i < MAX_MEMBER; i++)
		{
			if((GetMonster(i+1) != NULL) && IsAlive(i+1))
			{
				arr[roleNum + petNum + monsterNum] = i+1;
				monsterNum++;
			}
		}
	}
}

void CFight::GetExcept(uint8 except,uint8 *arr,uint8 &num)
{
	for(uint8 i = 0; i < num; i++)
	{
		if(except == arr[i])
		{
			memmove(arr+i,arr+i+1,num-i);
			num--;
			return;
		}
	}
}

struct SSortMemberSpeed
{
	bool operator()(const uint8 &m1,const uint8 &m2)
	{
		int speed1 = pFight->GetUnitSpeed(m1);
		int speed2 = pFight->GetUnitSpeed(m2);
//		pFight->GetQunXianAttrWithGainValue(7,speed1,m1);
//		pFight->GetQunXianAttrWithGainValue(7,speed1,m2);

		bool res = false;
		bool haveState1 = pFight->HaveBuff(m1,ESBUFF_WaitForTurn);
		bool haveState2 = pFight->HaveBuff(m2,ESBUFF_WaitForTurn);
		if(haveState1 && !haveState2)
			return true;
		else if(!haveState1 && haveState2)
			return false;
		if(speed1 > speed2 || (speed1 == speed2 && pFight->GetUnitSpeed_Rand(m1) > pFight->GetUnitSpeed_Rand(m2)))
			res = true;
		return res;
	}
	CFight *pFight;
};

void CFight::SortBySpeed(uint8 *arr,uint8 num)
{
 	SSortMemberSpeed sortSpeed;
	sortSpeed.pFight = this;
	std::sort(arr,arr+num,sortSpeed);
}

bool CFight::AllUserAutoFight(uint16 &userMask)
{
	bool flag = true;
	userMask = 0;
	for(uint8 i = 1; i <= MAX_MEMBER; i++)
	{
		CUser *pUser = GetUser(i);
		if(pUser != NULL)
		{
			if((pUser->IsAutoFight())
					|| (!IsAlive(i) && (GetPet(i+1) == NULL))
					|| (!IsAlive(i) && (GetPet(i+1) != NULL) && !IsAlive(i+1)))
			{
				userMask |= (1<<i);
			}
			else
			{
				flag = false;
			}
		}
	}
	return flag;
}

bool CFight::FightTimeout()
{
	if(m_fightIsEnd)
		return true;
	if(GetSysTime() - m_beginTime > m_timeOut)
		return true;

	bool flag = false;
	{
		int timeOut = FIGHT_TIMEOUT;
		if(m_type == EFTMatch)
			timeOut = 10;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		if(((m_userOpTime != 0) && (GetSysTime() - m_userOpTime > timeOut)) || (OneGroupAllDie() > 0))
		{
			flag = true;
		}
	}
	if(!flag)
		return false;
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	CalculateFightResult();
	return true;
}

ShareFightPtr CFightManager::CreateFight()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareFightPtr ptr;
	{
		CFight *pFight = new CFight;
		pFight->SetId(m_curFightId);
		ptr.reset(pFight);
	}
	atomic_increment((int*)&m_curFightId);
	return ptr;
}

ShareFightPtr CFightManager::FindFight(uint32 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	ShareFightPtr ptr;
	m_fights.Find(id,ptr);
	return ptr;
}

CFightManager::CFightManager():m_curFightId(1),m_onlineUser(SingletonOnlineUser::instance())
{
	CDespatchCommand &despatch = SingletonDespatch::instance();

	SCommand cmdFun[] = {
		{PRO_BATTLE, boost::bind(&CFightManager::UserBattle, this, _1, _2)},
		{PRO_FIGHT_OPTION, boost::bind(&CFightManager::FightOption, this, _1, _2)},
	};
	despatch.AddCommandDeal(cmdFun,sizeof(cmdFun)/sizeof(SCommand));
}

void CFightManager::UserBattle(CNetMessage *pMsg,int sock)
{
	try
	{
		if(pMsg == NULL)
			return;
		CNetMessage &msg = *pMsg;
		ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
		CUser *pUser = ptr.get();
		if(pUser == NULL || pUser->GetRoleId() == 0)
			return;

		int id = pUser->GetFightId();
		if(id == 0)
			return;

		ShareFightPtr fightPtr;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_fights.Find(id,fightPtr);
		}
		CFight *pFight = fightPtr.get();
		if(pFight == NULL)
		{
			uint8 playOp;
			int playPara;
			msg>>playOp>>playPara;
			if(playOp == CFight::EOTAuto)	//设置自动
			{
				if(playPara == 1)	//设置自动战斗
					pUser->SetAutoFightTurn(0xffff);	//自动战斗轮次
				else if(playPara == 0)	//取消自动战斗
					pUser->SetAutoFightTurn(0);
			}
			return;
		}

		pFight->UserBattle(msg,pUser);
		pFight->IsFightEnd();
	}
	catch(...)
	{
		cout<<"catch CFightManager::UserBattle error"<<endl;
	}
}

void CFightManager::FightOption(CNetMessage *pMsg,int sock)
{
	if(pMsg == NULL)
		return;
	
	CNetMessage &msg = *pMsg;
	ShareUserPtr ptr = m_onlineUser.GetUserBySock(sock);
	CUser *pUser = ptr.get();
	if(pUser == NULL || pUser->GetRoleId() == 0)
		return;

	uint8 op = 0;
	msg>>op;
	if(op == 0)
		return;

	if(op == 1)	// 跳过战斗
	{
		int id = pUser->GetFightId();
		if(id == 0)
			return;
		
		ShareFightPtr fightPtr;
		{
			boost::recursive_mutex::scoped_lock lk(m_mutex);
			m_fights.Find(id,fightPtr);
		}
		CFight *pFight = fightPtr.get();
		if(pFight == NULL)
			return;

		bool end = false;
		do
		{
			pFight->CalculateFightResult(true);
			end = pFight->IsFightEnd(true);
		}while(!end);

		CNetMessage retMsg;
		if(pFight->GetFightAllNetMsg(retMsg, EFPT_Jump))
		{
			SingletonSocket::instance().SendMsg(sock, retMsg);
//			SaveFightNetMsg(retMsg, EFPB_ARENA, pUser->GetRoleId());
		}
	}
	else if(op == 2)	// 获取战斗回放
	{
		uint32 fightId = 0;
		msg>>fightId;
		if(fightId == 0)
			return;
		CNetMessage retMsg;
		if(GetFightNetMsgFromDB(retMsg, fightId))
		{
			SingletonSocket::instance().SendMsg(sock, retMsg);
		}
		else
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_TRANSFORM_94, TIPS_FAILURE_COLOR);
			SingletonSocket::instance().SendMsg(sock, msg);
		}
	}
	else if(op == 3)	// 服务器主动推送
	{

	}



}

int CFight::GetUnitDamage(uint8 pos,int damage)
{
	int finalDam = damage;
/*	if((pos > 0) && (pos <= MAX_MEMBER))
	{
		CUser *pU = NULL;
		int myPos = pos;
		if(pos <= GROUP2_BEGIN)
			pU = GetUser(GROUP1_MAIN_POS);
		else
		{
			myPos -= GROUP2_BEGIN;
			pU = GetUser(GROUP2_MAIN_POS);
		}
	}
*/
	return finalDam;
}

void CFightManager::AddFight(ShareFightPtr ptr)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_fights.Insert(ptr->GetId(),ptr);
}

static bool EachFight(uint32 id,list<uint32> *pFightList)
{
	pFightList->push_back(id);
	return true;
}

void CFightManager::RemoveFight(uint32 id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_fights.Erase(id);
}

void CFightManager::RunFightTimeOut()
{
	list<uint32> fightList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_fights.ForEach(boost::bind(EachFight,_1,&fightList));
	}
	for(list<uint32>::iterator i = fightList.begin(); i != fightList.end(); i++)
	{
		ShareFightPtr pFight = FindFight(*i);
		if(pFight.get() != NULL)
		{
			if(pFight->FightTimeout())
			{
				if(pFight->IsFightEnd())
				{
					pFight->SendGuanZhanOver();
					boost::recursive_mutex::scoped_lock lk(m_mutex);
					m_fights.Erase(*i);
				}
			}
		}
	}
}



void CFight::XtmasTreeFightEnd()
{
	if(m_type != EFXtmasTree)
		return;

	bool win = true;
	CUser *p3 = GetGroupHead(EGT_GROUP1);
	CUser *p9 = GetGroupHead(EGT_GROUP2);
	if(p3 == NULL || p9 == NULL)
		return;

	// 统计战斗数据
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
		{
			win = false;
			break;
		}
	}
	
	// 掉落奖励
	uint32 huodong_type = CHuoDongAwardManager::SHENGDAN_FENGSHOU;
	if(win) //3赢
	{
		if( -1 != p3->GetSock())
		{
			//普通奖励
			AddHuoDongRewardDirect(p3,huodong_type,1);
			//额外奖励
			AddHuoDongRewardDirect(p3,huodong_type,2);

			p3->SetExtData32(291,GetSysTime());
			p3->SetExtData8(387,p3->GetExtData8(387)+1);

			p3->sendXtmasTreeInfo();
		}
		if( -1 != p9->GetSock())
		{
			AddHuoDongRewardDirect(p9,huodong_type,1);

			p9->SetExtData32(291,GetSysTime());
			p9->SetExtData8(387,p9->GetExtData8(387)+1);
			p9->sendXtmasTreeInfo();
		}
	}
	else	//9赢
	{
		if( -1 != p9->GetSock())
		{
			AddHuoDongRewardDirect(p9,huodong_type,1);
			AddHuoDongRewardDirect(p9,huodong_type,2);

			p9->SetExtData32(291,GetSysTime());
			p9->SetExtData8(387,p9->GetExtData8(387)+1);
			p9->sendXtmasTreeInfo();
		}
		if( -1 != p3->GetSock())
		{
			AddHuoDongRewardDirect(p3,huodong_type,1);

			p3->SetExtData32(291,GetSysTime());
			p3->SetExtData8(387,p3->GetExtData8(387)+1);
			p3->sendXtmasTreeInfo();
		}
	}
}


void CFight::XtmasBoxFightEnd()
{
	if(m_type != EFXtmasBox)
		return;

	bool win = true;
	CUser *p3 = GetGroupHead(EGT_GROUP1);
	CUser *p9 = GetGroupHead(EGT_GROUP2);
	if(p3 == NULL || p9 == NULL)
		return;

	// 统计战斗数据
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
		{
			win = false;
			break;
		}
	}

	// 掉落奖励
	uint32 huodong_type = CHuoDongAwardManager::XTMAS_BOX;
	if(win) //3赢
	{
		if( -1 != p3->GetSock())
		{
			AddHuoDongRewardDirect(p3,huodong_type,1);
		}
	}
	else	//9赢
	{
		if( -1 != p9->GetSock())
		{
			AddHuoDongRewardDirect(p9,huodong_type,1);
		}
	}
}

void CFight::SetQunXianImageGain(uint8 pos,uint8 imageIdx,float ratio)
{
	m_qx_imagePos = pos;
	m_qx_imageGain = ratio;
	m_qx_imageIdx = imageIdx;
}

void CFight::GetQunXianAttrWithGainValue(int type,int &srcVal,uint8 pos)
{
	if(m_type != EFT_QunXianZhengBa)
		return;
	if(pos == 0 || pos > MAX_MEMBER)
		return;
	if(m_qx_userPos == 0 || m_qx_imagePos == 0 || (type > 16 || type == 0))
		return;
	if((pos <= GROUP2_BEGIN && m_qx_userPos <= GROUP2_BEGIN) || (pos > GROUP2_BEGIN && m_qx_userPos > GROUP2_BEGIN))
	{
		srcVal += (int)m_qx_userAttrVal[type-1];
		srcVal = srcVal*(1 + m_qx_userAttrPercent[type-1]/10000.0);
	}
	else if((pos <= GROUP2_BEGIN && m_qx_imagePos <= GROUP2_BEGIN) || (pos > GROUP2_BEGIN && m_qx_imagePos > GROUP2_BEGIN))
	{
		if(type == 1 || type == 6 || type == 7 || type == 16)
			srcVal = srcVal*(1 + m_qx_imageGain);
	}
}

void CFight::BaoWeiZhanFightEnd()
{
	if(m_type != EFT_BaoWeiZhanBoss)
		return;
	CUser *pTarMain = NULL;
//	CUser *pTarUser[MAX_TEAM_MEMBER] = {NULL,NULL,NULL};//右边的人
//	int tarNum = 0;
	bool win = true;
	for(int i=1;i <= GROUP2_BEGIN; ++i)
	{
		SMonsterInst *pMonster = GetMonster(i);
		if(pMonster != NULL)
		{
			if(IsAlive(i))
				win = false;
		}
	}
	for(int i=GROUP2_BEGIN+1;i <= MAX_MEMBER; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
//			pTarUser[tarNum++] = pU;
			if(i == GROUP2_MAIN_POS)
				pTarMain = pU;
		}
	}
	int reduceHp = 0;
	if( pTarMain != NULL)
	{
		reduceHp = pTarMain->GetExtData32(302);
		pTarMain->SetExtData32(302,0);
	}
	if(!win)
	{
		SMonsterInst *pMonster = GetMonster(3);
		if( pMonster == NULL)
			return;
		if(pMonster->hp <= reduceHp)
			reduceHp -= pMonster->hp;
		else
			reduceHp = 0;
		ReduceBaoWeiZhanBossCurHp(reduceHp);
	}
	else	// 胜利
	{
		ReduceBaoWeiZhanBossCurHp(reduceHp);
	}
}

void CFight::UpdateUnitHp(uint8 pos)
{
	SFightMember *p = GetFightMember(pos);
	if(p == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PRO_UPDTAE_HP_IN_FIGHT);
	msg<<pos<<p->hp;

	CSocketServer &sock = SingletonSocket::instance();
	for(uint8 pos = 1; pos <= MAX_MEMBER; pos++)
	{
		CUser *pUser = GetUser(pos);
		if(pUser != NULL)
		{
			sock.SendMsg(pUser->GetSock(),msg);
		}
	}
}


#ifdef KUA_FU
void CFight::KuaFuBossPkEnd()
{
	if(m_type != EFT_KuaFuBossPK)
		return;

	char buf[512];
	SFightResultData result;
	GetPVP_FightResult(result);
	int curBossId = SingletonCShenJieMiJingManager::instance().GetCurrentBossID();
	if(result.winGroup == 1)	// 左边胜利
	{
		if(result.pLeader_2 != NULL)
		{
			if(result.pLeader_2->GetSrcSceneId() == SHENJIEMIJING_SCENE_ID)
			{
				SingletonCShenJieMiJingManager::instance().FightPunish(result.pLeader_2);
//				SingletonCShenJieMiJingManager::instance().SendWinReward(result.pLeader_1);
			}
			for(uint8 i=0;i < result.num_2;i++)
			{
				if(result.pHots_2[i] != NULL)
				{
					if(result.pHots_2[i]->GetExtData32(464) != (uint32)curBossId)
						result.pHots_2[i]->SetExtData32(464,curBossId);
					result.pHots_2[i]->SetExtData16(66,0);
				}
			}
		}
		if(result.pLeader_1 != NULL)
		{
			for(uint8 i=0;i < result.num_1;i++)
			{
				if(result.pHots_1[i] != NULL)
				{
					if(result.pHots_1[i]->GetExtData32(464) != (uint32)curBossId)
					{
						result.pHots_1[i]->SetExtData32(464,curBossId);
						result.pHots_1[i]->SetExtData16(66,1);
					}
					else
					{
						result.pHots_1[i]->SetExtData16(66,result.pHots_1[i]->GetExtData16(66)+1);
					}
				}
			}
			int winNum = result.pLeader_1->GetExtData16(66);
			if(winNum % 5 == 0)
			{
				if(result.pLeader_1->GetTeam() == 0)
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0520,result.pLeader_1->GetName(),winNum);
				else
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0521,result.pLeader_1->GetName(),winNum);
				SysInfoToAllUser(buf);
			}
		}
	}
	else	// 右边胜利
	{
		if(result.pLeader_1 != NULL)
		{
			if(result.pLeader_1->GetSrcSceneId() == SHENJIEMIJING_SCENE_ID)
			{
				SingletonCShenJieMiJingManager::instance().FightPunish(result.pLeader_1);
//				SingletonCShenJieMiJingManager::instance().SendWinReward(result.pLeader_2);
			}
			for(uint8 i=0;i < result.num_1;i++)
			{
				if(result.pHots_1[i] != NULL)
				{
					if(result.pHots_1[i]->GetExtData32(464) != (uint32)curBossId)
						result.pHots_1[i]->SetExtData32(464,curBossId);
					result.pHots_1[i]->SetExtData16(66,0);
				}
			}
		}
		if(result.pLeader_2 != NULL)
		{
			for(uint8 i=0;i < result.num_2;i++)
			{
				if(result.pHots_2[i] != NULL)
				{
					if(result.pHots_2[i]->GetExtData32(464) != (uint32)curBossId)
					{
						result.pHots_2[i]->SetExtData32(464,curBossId);
						result.pHots_2[i]->SetExtData16(66,1);
					}
					else
					{
						result.pHots_2[i]->SetExtData16(66,result.pHots_2[i]->GetExtData16(66)+1);
					}
				}
			}
			int winNum = result.pLeader_2->GetExtData16(66);
			if(winNum % 5 == 0)
			{
				if(result.pLeader_2->GetTeam() == 0)
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0520,result.pLeader_2->GetName(),winNum);
				else
					snprintf(buf,sizeof(buf),LANGUAGE_SSJ_0521,result.pLeader_2->GetName(),winNum);

				SysInfoToAllUser(buf);
			}
		}
	}
}

void CFight::QunXianZhengBaEnd()
{
	if(m_type != EFT_QunXianZhengBa)
		return;
	const int MAX_Floor_Num = CQunXianZhengBaManager::MAX_FLOOR;
	CUser *pUser9 = GetGroupHead(EGT_GROUP2);
	if(pUser9 == NULL)
		return;
	int floorIndex = pUser9->GetExtData8(486);	// 0~60 
	bool win = false;	// 玩家是否胜利
	int petNum = 0;
	uint8 petPos[GROUP2_BEGIN] = {0xff};
	float petHpRatio[GROUP2_BEGIN] = {0.0f};
	bool petDie[GROUP2_BEGIN] = {false};
	for(uint8 pos=GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		CUser *pU = GetUser(pos);
		if(pU != NULL)
		{
			int maxHp = GetMaxHp(pos);
			float hpRatio = 0.0f;
			if(maxHp != 0)
				hpRatio = GetHp(pos)/(float)maxHp;
			if(IsAlive(pos))
				win = true;

			// 保存血量比例
			pUser9->SetQunXianHpRatio(2,0xff,hpRatio,false);
			continue;
		}
		SPet *pPet = GetPet(pos);
		if(pPet != NULL)
		{
			int maxHp = GetMaxHp(pos);
			if(maxHp != 0)
				petHpRatio[petNum] = GetHp(pos)/(float)maxHp;
//			petPos[petNum] = m_members[pos-1].petOwnerPos;
			if(IsAlive(pos))
			{
				win = true;
				petDie[petNum] = false;
			}
			else
			{
				petDie[petNum] = true;
			}
			petNum++;
		}
	}
//	pUser9->QunXianInitPetAfterFight();
	// 保存血量比例
	for(uint8 i=0;i < petNum;i++)
		pUser9->SetQunXianHpRatio(1,petPos[i],petHpRatio[i],petDie[i]);
	pUser9->SendQunXianPetList();

	if(win)
	{
		CQunXianZhengBaManager &manager = SingletonCQunXianZhengBaManager::instance();
		SQunXianZhengBaConig floorCF;
		manager.GetFloorConfig(floorIndex+1,floorCF);
		if(floorCF.type != 1)
			return;
		SQunXianZhengBa_Role cf;
		manager.GetRoleCfgByIdx(floorCF.t_index,cf);
		if(cf.index == 0)
			return;
		uint8 winStar = 0;
		if(m_qx_imageIdx == 1)
			winStar = cf.s_star;
		else if(m_qx_imageIdx == 2)
			winStar = cf.m_star;
		else if(m_qx_imageIdx == 3)
			winStar = cf.h_star;
		else
			return;
		
		if(floorIndex < MAX_Floor_Num)
		{
			pUser9->SetQunXianCurFloor(floorIndex+1);
			pUser9->SetExtData16(58,pUser9->GetExtData16(58)+winStar);	// 更新剩余星星
			pUser9->SetExtData16(59,pUser9->GetExtData16(59)+winStar);	// 更新获得星星
		}
		else
		{
			return;
		}

		// 更新活动信息
		SendQunXianMsg(pUser9);
	}
	else	// 失败
	{

	}
}

void CFight::QieCuoFightEnd()
{
	if(m_type != EFTPlayerQieCuo)
		return;
	
	SFightResultData result;
	GetPVP_FightResult(result);
	if (result.pLeader_1 == NULL || result.pLeader_2 == NULL)
		return;

	if (result.winGroup == 1) // 1 group1 win, 2 gruop2 win
	{
		for (int i = 0; i < MAX_FIGHT_MAMBER / 2; i++)
		{
			for (int j = 0; j < MAX_FIGHT_MAMBER / 2; j++)
			{
				CheckKuaFuQieCuoMission(result.pHots_1[i], result.pHots_2[j]);
			}
		}
	}
	else
	{
		for (int i = 0; i < MAX_FIGHT_MAMBER / 2; i++)
		{
			for (int j = 0; j < MAX_FIGHT_MAMBER / 2; j++)
			{
				CheckKuaFuQieCuoMission(result.pHots_2[i], result.pHots_1[j]);
			}
		}
	}
}

void CFight::KuaFu1vs1PreliminaryEnd()
{
	if(m_type != EFKuaFu1vs1Preliminary)
		return;

	SFightResultData result;
	GetPVP_FightResult(result);
	if(result.pLeader_1 == NULL || result.pLeader_2 == NULL)
		return;

	// 掉落奖励
	if(result.winGroup == 1) //挑战失败
	{
		if(result.pLeader_2->GetSock() != -1)
		{
			SingletonCKuaFu1vs1PreliminaryManager::instance().AddUserScore(result.pLeader_2,false);	
		}
	}
	else	//挑战成功
	{
		if(result.pLeader_2->GetSock() != -1)
		{
			SingletonCKuaFu1vs1PreliminaryManager::instance().AddUserScore(result.pLeader_2,true);	
		}
	}
	result.pLeader_2->SetKuaFu1vs1PreliminaryFightEnemySeq(0);
	result.pLeader_2->SetKuaFu1vs1PreliminaryChallengueCDTime((int)(GetSysTime()+30));
	SingletonCKuaFu1vs1PreliminaryManager::instance().ChooseFiveEnemyFromSort(result.pLeader_2);
	SingletonCKuaFu1vs1PreliminaryManager::instance().SendKuaFu1vs1PreliminaryPanelInfo(result.pLeader_2);
}

void CFight::EFKuaFuXueLianFightEnd()
{
/*
	if(m_type != EFKuaFuXueLian)
		return;
	const int MISSION_ID = 804;
	bool win = true;
	CUser *p3 = GetGroupHead(EGT_GROUP1);
	CUser *p9 = GetGroupHead(EGT_GROUP2);
	if(p3 == NULL || p9 == NULL)
		return;

	// 统计战斗数据
	for(uint8 pos = GROUP2_BEGIN+1; pos <= MAX_MEMBER; pos++)
	{
		if(IsAlive(pos))
		{
			win = false;
			break;
		}
	}
	
	if(win) //3赢
	{
		if( -1 != p3->GetSock())
		{
			const char *pMission = p3->GetMission(MISSION_ID);
			if( pMission != NULL ) 
			{     
				char buf[256];
				char *split[3];
				string str = pMission;
				if(SplitLine(split,3,(char*)str.c_str()) == 3) 
				{     
					if(atoi(split[2])+1 >= atoi(split[1])) 
					{
						snprintf(buf,sizeof(buf),"1|%d|%d",atoi(split[1]),atoi(split[1]));
					}
					else
					{
						snprintf(buf,sizeof(buf),"0|%d|%d",atoi(split[1]),atoi(split[2])+1);
					}
					p3->UpdateMission(MISSION_ID,buf);
				}     
			}//end of mission     
		}
	}
	else	//9赢
	{
		if( -1 != p9->GetSock())
		{
			const char *pMission = p9->GetMission(MISSION_ID);
			if( pMission != NULL ) 
			{     
				char buf[256];
				char *split[3];
				string str = pMission;
				if(SplitLine(split,3,(char*)str.c_str()) == 3) 
				{     
					if(atoi(split[2])+1 >= atoi(split[1])) 
					{
						snprintf(buf,sizeof(buf),"1|%d|%d",atoi(split[1]),atoi(split[1]));
					}
					else
					{
						snprintf(buf,sizeof(buf),"0|%d|%d",atoi(split[1]),atoi(split[2])+1);
					}
					p9->UpdateMission(MISSION_ID,buf);
				}     
			}//end of mission     
		}
	}
*/
}

void CFight::ShenJieMiJingNormalFightEnd()
{
	if(m_type != EFKuaFuShenJieMiJingNormalPVE)
		return;
/*
	const int MISSION_ID = 805;
	CUser *pSrcMain = NULL;
	CUser *pSrcUser[MAX_TEAM_MEMBER] = {NULL};//左边的人
	int srcNum = 0;
	CUser *pTarMain = NULL;
	CUser *pTarUser[MAX_TEAM_MEMBER] = {NULL};//右边的人
	int tarNum = 0;
	bool win = false;	// 左边是否胜利
	for(int i=1;i <= GROUP2_BEGIN; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			pSrcUser[srcNum++] = pU;
			if(IsAlive(i) && !win)
				win = true;
			if(i == GROUP1_MAIN_POS)
				pSrcMain = pU;
		}
		SPet *pPet = GetPet(i);
		if(pPet != NULL)
		{
			if(IsAlive(i) && !win)
				win = true;
		}
		SMonsterInst *pMonster = GetMonster(i);
		if(pMonster != NULL)
		{
			if(IsAlive(i) && !win)
				win = true;
		}
	}
	for(int i=GROUP2_BEGIN+1;i <= MAX_MEMBER; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			pTarUser[tarNum++] = pU;
			if(i == GROUP2_MAIN_POS)
				pTarMain = pU;
		}
	}
	int addexp = 0;
	if( pTarMain != NULL)
	{
		if(pTarMain->HaveTeam())
		{
			addexp = 15 * pTarMain->GetTeamLevel();
		}
		else
		{
			addexp = 15 * pTarMain->GetLevel();	
		}
	}
	if(win)	// 左边胜利
	{
	}
	else	// 右边胜利
	{
		bool isOut = false;
		for(int counter=0;counter < tarNum;++counter)
		{
			if( pTarUser[counter] == NULL)
				continue;
			if(addexp)
				pTarUser[counter]->AddExp(addexp,true,true);
			const char *pMission = pTarUser[counter]->GetMission(MISSION_ID);
			if( pMission != NULL ) 
			{     
				char buf[256];
				char *split[3];
				string str = pMission;
				if(SplitLine(split,3,(char*)str.c_str()) == 3) 
				{     
					if(atoi(split[2])+1 >= atoi(split[1])) 
					{
						snprintf(buf,sizeof(buf),"1|%d|%d",atoi(split[1]),atoi(split[1]));
						//队长或者单独一人则传出
						if(pTarUser[counter]->HaveTeam())
						{
							if(pTarUser[counter]->GetTeam() == pTarUser[counter]->GetRoleId())
								isOut = true;
						}
						else
						{
							isOut = true;
						}
					}
					else
					{
						snprintf(buf,sizeof(buf),"0|%d|%d",atoi(split[1]),atoi(split[2])+1);
					}
					pTarUser[counter]->UpdateMission(MISSION_ID,buf);
				}     
			}//end of mission 
			pTarUser[counter]->GetTransFormDrop();//掉落变身卡
		}//end of for
		if(isOut)
		{
			uint16 pos_x = 592;
			uint16 pos_y = 944;
			uint16 scene_id = KUA_FU_SCENE_ID;
			TransportUser( pTarMain,scene_id,pos_x,pos_y,1);
		}
	}
*/
}
void CFight::ShenJieMiJingEliteFightEnd() 
{
	if(m_type != EFKuaFuShenJieMiJingElitePVE)
		return;
/*
	const int MISSION_ID = 805;
	CUser *pSrcMain = NULL;
	CUser *pSrcUser[MAX_TEAM_MEMBER] = {NULL};//左边的人
	int srcNum = 0;
	CUser *pTarMain = NULL;
	CUser *pTarUser[MAX_TEAM_MEMBER] = {NULL};//右边的人
	int tarNum = 0;
	bool win = false;	// 左边是否胜利
	for(int i=1;i <= GROUP2_BEGIN; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			pSrcUser[srcNum++] = pU;
			if(IsAlive(i) && !win)
				win = true;
			if(i == GROUP1_MAIN_POS)
				pSrcMain = pU;
		}
		SPet *pPet = GetPet(i);
		if(pPet != NULL)
		{
			if(IsAlive(i) && !win)
				win = true;
		}
		 SMonsterInst *pMonster = GetMonster(i);
		if(pMonster != NULL)
		{
			if(IsAlive(i) && !win)
				win = true;
		}
	}
	for(int i=GROUP2_BEGIN+1;i <= MAX_MEMBER; ++i)
	{
		CUser *pU = GetUser(i);
		if(pU != NULL)
		{
			pTarUser[tarNum++] = pU;
			if(i == GROUP2_MAIN_POS)
				pTarMain = pU;
		}
	}

	int addexp = 0;
	if( pTarMain != NULL)
	{
		if(pTarMain->HaveTeam())
		{
			addexp = 15 * pTarMain->GetTeamLevel();
		}
		else
		{
			addexp = 15 * pTarMain->GetLevel();
		}
	}
	if(win)	// 左边胜利
	{
	}
	else	// 右边胜利
	{
		bool isOut = false;
		for(int counter=0;counter < tarNum;++counter)
		{
			if( pTarUser[counter] == NULL)
				continue;
			if(addexp)
				pTarUser[counter]->AddExp(addexp,true,true);
			const char *pMission = pTarUser[counter]->GetMission(MISSION_ID);
			if( pMission != NULL ) 
			{     
				char buf[256];
				char *split[3];
				string str = pMission;
				if(SplitLine(split,3,(char*)str.c_str()) == 3) 
				{     
					if(atoi(split[2])+1 >= atoi(split[1])) 
					{
						snprintf(buf,sizeof(buf),"1|%d|%d",atoi(split[1]),atoi(split[1]));
						//队长或者单独一人则传出
						if(pTarUser[counter]->HaveTeam())
						{
							if(pTarUser[counter]->GetTeam() == pTarUser[counter]->GetRoleId())
								isOut = true;
						}
						else
						{
							isOut = true;
						}
					}
					else
					{
						snprintf(buf,sizeof(buf),"0|%d|%d",atoi(split[1]),atoi(split[2])+1);
					}
					pTarUser[counter]->UpdateMission(MISSION_ID,buf);
				}     
			}//end of mission 
			pTarUser[counter]->GetTransFormDrop();//掉落变身卡
		}//end of for
		SingletonCShenJieMiJingManager::instance().SendWinReward(pTarMain);
		if(isOut)
		{
			uint16 pos_x = 592;
			uint16 pos_y = 944;
			uint16 scene_id = KUA_FU_SCENE_ID;
			TransportUser( pTarMain,scene_id,pos_x,pos_y,1);
		}
	}
*/
}

void CFight::GuWuXianShiTaoPao(CUser *pUser, uint8 pos)
{
	if (m_type != EFKuaFuShenJieMiJingBossPVE)
		return;

	int addexp = 50 * pUser->GetLevel();
	pUser->AddExp(addexp, true, true);
	pUser->SetExtData32(301, GetSysTime());

	CScene *pScene = pUser->GetScene();
	if (pScene != NULL)
	{
		pScene->GoTo(pUser, pScene->GetX(), pScene->GetY());
	}
	SingletonCShenJieMiJingManager::instance().ShowReliveTimeClearPanel(pUser);
}

void CFight::KuaFuQieCuoTaoPao(CUser *pUser, uint8 pos)
{
	if (m_type != EFTPlayerQieCuo)
		return;
	int startPos = 1;
	int maxPos = GROUP2_BEGIN;
	if (pos <= GROUP2_BEGIN)
	{
		startPos = GROUP2_BEGIN + 1;
		maxPos = MAX_MEMBER;
	}
	for (int i = startPos; i <= maxPos; i++)
	{
		CUser *pMissUser = GetUser(i);
		if (pMissUser != NULL)
		{
			CheckKuaFuQieCuoMission(pMissUser, pUser);
		}
	}
}

void CFight::ShenJieMiJingBossFightEnd()
{
	if(m_type != EFKuaFuShenJieMiJingBossPVE)
		return;
	CUser *pLeader = NULL;
	CUser *pHots[GROUP_MEMBER] = {NULL};
	int num = 0;
	bool isWin = false;
	GetPVE_FightResult(&pLeader,pHots,num,isWin);
	if(pLeader == NULL || num == 0)
		return;

//	int reduceHp = 0;
//	int boss_id = 0;
	if(pLeader != NULL)
	{
//		reduceHp = pLeader->GetExtData32(302);
//		boss_id = pLeader->GetExtData32(303);
		pLeader->SetExtData32(302,0);
		pLeader->SetExtData32(303,0);
	}
//	if(boss_id == 0)
//		return;
//	uint8 monsterPos = FindMonsterPos(boss_id);
//	if(monsterPos == 0xff)
//		return;
//	SFightMember *pMon = GetFightMember(monsterPos);
//	if(pMon == NULL)
//		return;
	CShenJieMiJingManager &shenjieMgr = SingletonCShenJieMiJingManager::instance();
	if(!isWin)	// boss胜利
	{
//		if(pMon->hp <= reduceHp)
//		{
//			reduceHp -= pMon->hp;
//		}
//		else
//		{
//			reduceHp = 0;
//		}
		shenjieMgr.FightPunish(pLeader);
	}
//	shenjieMgr.HandleBossFightEnd(pLeader,boss_id,reduceHp);	// boss扣血
	
	//BOSS不管输赢都给经验
	int addexp = 0;
	if(pLeader != NULL)
	{
		if(pLeader->HaveTeam())
		{
			addexp = 50 * pLeader->GetTeamLevel();
		}
		else
		{
			addexp = 50 * pLeader->GetLevel();
		}
	}
	for(int counter=0;counter < num;++counter)
	{
		if(pHots[counter] == NULL)
			continue;
		if(addexp)
			pHots[counter]->AddExp(addexp,true,true);
//		shenjieMgr.AddUserScore(pHots[counter], reduceHp);
	}
}

uint8 CFight::ShenJieMiJingUpdateBossHp()
{
	if(m_type != EFKuaFuShenJieMiJingBossPVE)
		return 0;
	CUser *pLeader = NULL;
	CUser *pHots[GROUP_MEMBER] = {NULL};
	int num = 0;
	bool isWin = false;
	GetPVE_FightResult(&pLeader,pHots,num,isWin);
	if(pLeader == NULL || num == 0)
		return 0;

	int reduceHp = 0;
	int boss_id = 0;
	if(pLeader != NULL)
	{
		reduceHp = pLeader->GetExtData32(302);
		boss_id = pLeader->GetExtData32(303);
	}
	if(boss_id == 0)
		return 0;
	uint8 monsterPos = FindMonsterPos(boss_id);
	if(monsterPos == 0xff)
		return 0;
	SFightMember *pMon = GetFightMember(monsterPos);
	if(pMon == NULL)
		return 0;
	CShenJieMiJingManager &shenjieMgr = SingletonCShenJieMiJingManager::instance();
	if(pMon->hp <= reduceHp)
		reduceHp -= pMon->hp;
	else
		reduceHp = 0;
	shenjieMgr.HandleBossFightEnd(pLeader,boss_id,reduceHp);	// boss扣血

	// 重置血量
	pMon->hp = shenjieMgr.GetCurrentBossHp();
	if(pMon->hp == 0)
		SetState(monsterPos, EFST_STATE_Die);
	pLeader->SetExtData32(302,pMon->hp);
	
	for(int counter=0;counter < num;++counter)
	{
		if(pHots[counter] != NULL)
			shenjieMgr.AddUserScore(pHots[counter], reduceHp);
	}
	return monsterPos;
}


#endif
