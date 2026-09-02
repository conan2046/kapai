#include "skill.h"
#include "xml.h"
#include "utility.h"
#include <math.h>
#include <algorithm>
#include <fstream>
#include "rapidjson/document.h"

int SSkillEffectCfg::GetEffectId()
{
	if(effectIdList.empty())
		return 0;
	uint8 size = effectIdList.size();
	return effectIdList[Random(1,size)-1];
}


////////////////////////////////////////////////////////////////////////////////////////

bool CSkillMgr::Init()
{
	m_skills.clear();
	m_activeEffects.clear();
	m_additiveEffects.clear();
	m_buffs.clear();
	m_enBuffs.clear();
	m_deBuffs.clear();
	m_zhongduBuffs.clear();

	{
		//                  0   1     2      3    4
		const char *keys[] = {"id","type","name","effect","cd"};
		vector<map<string, string> > data;
		uint16 size = sizeof(keys) / sizeof(keys[0]);
		CXMLReader reader("skill_basic.xml");
		if (!reader.GetAllElements(data, keys, size))
			return false;
		
		for (uint32 i = 0; i < data.size(); i++)
		{
			SSkillCfgData t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.type = atoi(data[i][keys[1]].c_str());
			t.name = data[i][keys[2]];
			SetEffectData(t.activeEffect,t.passiveEffect,data[i][keys[3]]);
			t.CD = atoi(data[i][keys[4]].c_str());
			m_skills.insert(make_pair(t.id,t));
		}
	}

	{
		//                  0    1        2          3            4           5        6      7       8       9      10      11     12
		const char *keys[] = {"id","type","target_type","target_range","target_select","target_num","buffid","para1","para1_lv","para2","para2_lv","para3","para3_lv"};
		vector<map<string, string> > data;
		uint16 size = sizeof(keys) / sizeof(keys[0]);
		CXMLReader reader("skill_active_effect.xml");
		if (!reader.GetAllElements(data, keys, size))
			return false;
		
		for(uint32 i = 0; i < data.size(); i++)
		{
			SSkillActiveEffect t;
			t.effectId = atoi(data[i][keys[0]].c_str());
			t.effect_type = atoi(data[i][keys[1]].c_str());
			t.target_group = atoi(data[i][keys[2]].c_str());
			t.target_range = atoi(data[i][keys[3]].c_str());
			t.target_select = atoi(data[i][keys[4]].c_str());
			t.target_num = atoi(data[i][keys[5]].c_str());
			t.buffId = atoi(data[i][keys[6]].c_str());
			for(uint8 k=0;k < 3;k++)
			{
				t.para[k] = atoi(data[i][keys[7+2*k]].c_str());
				t.para_levelAdd[k] = atoi(data[i][keys[8+2*k]].c_str());
			}
			m_activeEffects.insert(make_pair(t.effectId,t));
		}
	}

	{
		//                  0    1      2     3      4      5       6       7       8       9      10     11       12      13      14
		const char *keys[] = {"id","trigger","type","buffid","para1","para1_lv","para2","para2_lv","para3","para3_lv","para4","para4_lv","para5","para5_lv","show_str"};
		vector<map<string, string> > data;
		uint16 size = sizeof(keys) / sizeof(keys[0]);
		CXMLReader reader("skill_additive_effect.xml");
		if (!reader.GetAllElements(data, keys, size))
			return false;
		
		for(uint32 i = 0; i < data.size(); i++)
		{
			SSkillAdditiveEffect t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.trigger = atoi(data[i][keys[1]].c_str());
			t.type = atoi(data[i][keys[2]].c_str());
			t.buffId = atoi(data[i][keys[3]].c_str());
			for(uint8 k=0;k < 5;k++)
			{
				t.para[k] = atoi(data[i][keys[4+2*k]].c_str());
				t.para_levelAdd[k] = atoi(data[i][keys[5+2*k]].c_str());
			}
			t.showStr = data[i][keys[14]];
			m_additiveEffects.insert(make_pair(t.id,t));
		}
	}

	{
		char buf[256];
		char *p[512];
		int num = 0;
		//                  0    1     2        3            4          5
//		const char *keys[] = {"id","name","type","Issuperpose","mutex_buffid","activeType"};
		const char *keys[] = {"id","name","type","Issuperpose","mutex_buffid"};
		vector<map<string, string> > data;
		uint16 size = sizeof(keys) / sizeof(keys[0]);
		CXMLReader reader("skill_buff.xml");
		if (!reader.GetAllElements(data, keys, size))
			return false;
		
		for(uint32 i = 0; i < data.size(); i++)
		{
			SSkillBuff t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.name = atoi(data[i][keys[1]].c_str());
			t.type = atoi(data[i][keys[2]].c_str());
			t.canMerge = atoi(data[i][keys[3]].c_str());
//			t.active_type = atoi(data[i][keys[5]].c_str());
			
			string buffList = data[i][keys[4]];
			if(!buffList.empty())
			{
				strncpy(buf,buffList.c_str(),sizeof(buf));
				num = SplitLine(p,buf,';');
				for(uint16 k=0;k < num;k++)
				{
					int buffId = atoi(p[k]);
					if(buffId > 0)
						t.mutex_buffId.push_back(buffId);
				}
			}
			m_buffs.insert(make_pair(t.id,t));
			if(t.type == 1)
				m_enBuffs.push_back(t.id);
			else
				m_deBuffs.push_back(t.id);
		}
	}


	m_zhongduBuffs.push_back(ESBUFF_ShiXinDu);
	m_zhongduBuffs.push_back(ESBUFF_ShiDu);
	m_zhongduBuffs.push_back(ESBUFF_FuDu);
	return InitHeroSkillRoleCfg();
}

bool CSkillMgr::InitHeroSkillRoleCfg()
{
	const string fileName = "./json/hero_skill_role.json";
	std::ifstream f(fileName.c_str());
	if (!f.is_open())
	{
		cout << "CSkillMgr::InitHeroSkillRoleCfg >> open file error: " << fileName << endl;
		return false;
	}
	std::string jsonStr((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
	f.close();
	rapidjson::Document d;
	if (d.Parse(jsonStr.c_str()).HasParseError() || !d.IsArray())
	{
		cout << "CSkillMgr::InitHeroSkillRoleCfg >> invalid JSON array" << endl;
		return false;
	}
	m_heroSkillRoles.clear();
	for (rapidjson::SizeType i = 0; i < d.Size(); ++i)
	{
		const rapidjson::Value& row = d[i];
		const char* required[] = { "hero_id", "regular_skill_id", "tactic_skill_id", "tactic_cost", "build_a", "build_b" };
		for (size_t k = 0; k < sizeof(required) / sizeof(required[0]); ++k)
		{
			if (!row.HasMember(required[k]))
			{
				cout << "CSkillMgr::InitHeroSkillRoleCfg >> missing " << required[k] << " at row " << i << endl;
				return false;
			}
		}
		HeroSkillRoleCfg cfg;
		cfg.heroId = row["hero_id"].GetInt();
		cfg.regularSkillId = row["regular_skill_id"].GetInt();
		cfg.tacticSkillId = row["tactic_skill_id"].GetInt();
		cfg.tacticCost = row["tactic_cost"].GetInt();
		cfg.buildA = row["build_a"].GetString();
		cfg.buildB = row["build_b"].GetString();
		if (cfg.heroId == 0 || cfg.regularSkillId == 0 || cfg.tacticSkillId == 0
			|| cfg.tacticCost < 20 || cfg.tacticCost > 100
			|| GetSkillCfg(cfg.regularSkillId) == NULL || GetSkillCfg(cfg.tacticSkillId) == NULL
			|| m_heroSkillRoles.find(cfg.heroId) != m_heroSkillRoles.end())
		{
			cout << "CSkillMgr::InitHeroSkillRoleCfg >> invalid/duplicate row " << i << endl;
			return false;
		}
		m_heroSkillRoles[cfg.heroId] = cfg;
	}
	if (m_heroSkillRoles.size() != 59)
	{
		cout << "CSkillMgr::InitHeroSkillRoleCfg >> expected 59 rows, got " << m_heroSkillRoles.size() << endl;
		return false;
	}
	cout << "hero_skill_role.json >> loaded 59 hero role mappings" << endl;
	return true;
}

HeroSkillRoleCfg* CSkillMgr::GetHeroSkillRoleCfg(uint16 heroId)
{
	HeroSkillRoleCfgMap::iterator it = m_heroSkillRoles.find(heroId);
	return it == m_heroSkillRoles.end() ? NULL : &it->second;
}

SSkillCfgData *CSkillMgr::GetSkillCfg(int skillId)
{
	if(skillId == 0)
		return NULL;
	
	map<int, SSkillCfgData>::iterator it = m_skills.find(skillId);
	if(it == m_skills.end())
		return NULL;
	return &(it->second);
}

SSkillActiveEffect *CSkillMgr::GetActiveEffectCfg(int effectId)
{
	if(effectId == 0)
		return NULL;
	
	map<int, SSkillActiveEffect>::iterator it = m_activeEffects.find(effectId);
	if(it == m_activeEffects.end())
		return NULL;
	return &(it->second);
}

SSkillAdditiveEffect *CSkillMgr::GetAdditiveEffectCfg(int effectId)
{
	if(effectId == 0)
		return NULL;
	
	map<int, SSkillAdditiveEffect>::iterator it = m_additiveEffects.find(effectId);
	if(it == m_additiveEffects.end())
		return NULL;
	return &(it->second);
}

SSkillBuff *CSkillMgr::GetBuffCfg(int buffId)
{
	if(buffId == 0)
		return NULL;
	
	map<int, SSkillBuff>::iterator it = m_buffs.find(buffId);
	if(it == m_buffs.end())
		return NULL;
	return &(it->second);
}

void CSkillMgr::GetEnBuffList(vector<int> &buffList)
{
	buffList.assign(m_enBuffs.begin(),m_enBuffs.end());
}

void CSkillMgr::GetDeBuffList(vector<int> &buffList)
{
	buffList.assign(m_deBuffs.begin(),m_deBuffs.end());
}

void CSkillMgr::GetZhongDuBuffList(vector<int> &buffList)
{
	buffList.assign(m_zhongduBuffs.begin(),m_zhongduBuffs.end());
}

void CSkillMgr::GetSkillPassiveData(int skillId,uint16 triggerId,vector<int> &passiveList)
{
	passiveList.clear();
	SSkillCfgData *pSkill = GetSkillCfg(skillId);
	if(pSkill == NULL || pSkill->passiveEffect.empty())
		return;

	for(uint8 i=0;i < pSkill->passiveEffect.size();i++)
	{
		int effectId = pSkill->passiveEffect[i].GetEffectId();
		SSkillAdditiveEffect *p = GetAdditiveEffectCfg(effectId);
		if(p == NULL)
			continue;
		if(p->trigger == triggerId)
		{
			passiveList.push_back(effectId);
		}
	}
}

bool CSkillMgr::IsEnBuff(uint16 buffId)
{
	if(buffId == 0)
		return false;
	if(std::find(m_enBuffs.begin(),m_enBuffs.end(),buffId) == m_enBuffs.end())
		return false;
	return true;
}

void CSkillMgr::SetEffectData(SSkillEffectCfg &active,vector<SSkillEffectCfg> &passive,string &str)
{
	active.Clear();
	passive.clear();
	if(str.empty())
		return;

	char buf[1024];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		char tbuf[64];
		int tnum = 0;
		char *tp[10];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'-');
		int type = atoi(tp[0]);
		if(type <= 2)
		{
			if(tnum != 2)
			{
				cout<<"CSkillMgr::SetEffectData error , str = "<<str;
				return;
			}

			SSkillEffectCfg v;
			v.effectType = atoi(tp[0]);
			v.effectIdList.push_back(atoi(tp[1]));
			if(v.effectType == 1)	// 主动效果
				active = v;
			else
				passive.push_back(v);
		}
		else if(type == 3)
		{
			if(tnum < 2)
			{
				cout<<"CSkillMgr::SetEffectData error , str = "<<str;
				return;
			}
			SSkillEffectCfg v;
			v.effectType = atoi(tp[0]);
			for(uint16 j=1;j < tnum;j++)
				v.effectIdList.push_back(atoi(tp[j]));
			passive.push_back(v);
		}
	}
}
















