#include "pet.h"
#include "utility.h"
#include "skill.h"
#include "init.h"


/////////////////////////////////////////////////////////////////////////////////////////////

bool CPetCfgManager::Init()
{
	m_petMaxLevel = 0;
	m_basicData.clear();
	m_LvUpExp.clear();
	m_userLvUpExp.clear();
	m_skillCost.clear();
	m_skillBook.clear();
	m_upStar_qualityCost.clear();
	m_upStar_star.clear();
	m_upStar_step.clear();
	m_xiulianData.clear();
	m_petTypeRatio.clear();
	for(uint8 i=0;i < PET_BORN_SKILL_NUM;i++)
		m_bornSkillCost[i].clear();
	{
		const string file = "hero.json";
		//                           0     1       2      3          4               5          6                7        8         9         10
		const char *titleArrs[] = {"id", "name", "pic", "feature", "HeroClass", "attack_type", "SubType", "initstar", "quality", "itemId", "skills",
		//            11         12           13       14       15     16         17         18        19         20          21         22
			  "trans_itemnum", "face", "skill_cv", "dialogue", "cv", "gongji", "wufang", "fashang", "qixue", "gongji_lv", "wufang_lv", "fafang_lv",
		//         23       24       25
			  "qixue_lv", "attr", "breakattr"};
		const int typeArrs[] = { 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2};  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CPetCfgManager::Init hero json >> LoadJosnValue error " << endl;
			return false;
		}
		MultiAttr selfAttr;
		MultiAttr teamAttr;
		for(uint32 i=0;i < _para.Size();i++)
		{
			const rapidjson::Value &data = _para[i];
			SPetBasicData t;
			t.id = data[titleArrs[0]].GetInt();
			t.name = data[titleArrs[1]].GetString();
			t.pic = data[titleArrs[2]].GetInt();
			t.desc = data[titleArrs[3]].GetString();
			// 4 英雄定位
			t.type = data[titleArrs[5]].GetInt();
			t.race = data[titleArrs[6]].GetInt();
			t.initStar = data[titleArrs[7]].GetInt();
			t.quality = data[titleArrs[8]].GetInt();			
			t.shengxingItemId = data[titleArrs[9]].GetInt();
			
			const rapidjson::Value &skillAttr = data[titleArrs[10]];
			uint8 si = skillAttr.Size();
			for (uint8 sai = 0; sai < si; ++sai)
			{
				t.bornSkill.push_back(skillAttr[sai].GetInt());
			}
			t.transferItemNum = data[titleArrs[11]].GetInt();
			t.attack = data[titleArrs[16]].GetInt();
			t.wufang = data[titleArrs[17]].GetInt();
			t.fafang = data[titleArrs[18]].GetInt();
			t.qixue = data[titleArrs[19]].GetInt();
			t.attackCZ = data[titleArrs[20]].GetInt();
			t.wufangCZ = data[titleArrs[21]].GetInt();
			t.fafangCZ = data[titleArrs[22]].GetInt();
			t.qixueCZ = data[titleArrs[23]].GetInt();
			ReadMultiAttr(data[titleArrs[24]], t.attrList);
			ReadTupoAttr(data[titleArrs[25]], t.topoAttrs);
			m_basicData.insert(make_pair(t.id,t));
		}
	}

	{
		const string file = "exp.json";
		//                            0       1        2            3
		const char *titleArrs[] = { "level", "exp", "exp_hero", "stamina" };
		const int typeArrs[] = { 0, 0, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CPetCfgManager::Init exp json >> LoadJosnValue error " << endl;
			return false;
		}
		m_petMaxLevel = 0;
		for(uint32 i=0;i < _para.Size();i++)
		{
			LvCfg cfg;
			const rapidjson::Value &data = _para[i];
			cfg.lv = data[titleArrs[0]].GetInt();
			cfg.exp = data[titleArrs[1]].GetInt();
			uint32 exp = data[titleArrs[2]].GetInt();
			cfg.tili = data[titleArrs[3]].GetInt();
			m_LvUpExp.push_back(exp);
			m_userLvUpExp[cfg.lv] = cfg;
			if (m_petMaxLevel < cfg.lv) m_petMaxLevel = cfg.lv;
		}
	}

	{
		vector<map<string,string> > data;
		//                     0      1        2      3
		const char *keys[] = {"skill_idx","level","learn_level","cost"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_born_skill_LvUp.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			SSkillLvCost t;
			uint8 idx = atoi(data[i][keys[0]].c_str());
			if(idx == 0 || idx > PET_BORN_SKILL_NUM)
				continue;
			t.tarLevel = atoi(data[i][keys[1]].c_str());
			t.learnLv_limit = atoi(data[i][keys[2]].c_str());
			if(!SetCostData(t.costList,data[i][keys[3]]))
				cout<<"CPetCfgManager::Init() SetCostData error: "<<data[i][keys[3]]<<endl;
			m_bornSkillCost[idx-1].push_back(t);
		}
		for(uint8 i=0;i < PET_BORN_SKILL_NUM;i++)
		{
			SSort_SkillCost sortFun;
			std::sort(m_bornSkillCost[i].begin(),m_bornSkillCost[i].end(),sortFun);
		}
	}

	{
		vector<map<string,string> > data;
		//                  0     1      2
		const char *keys[] = {"id","srclevel","cost"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_skill_LvUp.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			SSkillLvCost t;
			uint16 skillId = atoi(data[i][keys[0]].c_str());
			t.tarLevel = atoi(data[i][keys[1]].c_str());
			if(!SetCostData(t.costList,data[i][keys[2]]))
				cout<<"CPetCfgManager::Init() SetCostData error: "<<data[i][keys[2]]<<endl;
			
			map<uint16,vector<SSkillLvCost> >::iterator it = m_skillCost.find(skillId);
			if(it == m_skillCost.end())
			{
				pair<map<uint16,vector<SSkillLvCost> >::iterator,bool> res = m_skillCost.insert(make_pair(skillId,vector<SSkillLvCost>()));
				if(!res.second)
					return false;
				it = res.first;
			}
			it->second.push_back(t);
		}
		for(map<uint16,vector<SSkillLvCost> >::iterator it = m_skillCost.begin(); it != m_skillCost.end(); it++)
		{
			SSort_SkillCost sortFun;
			std::sort(it->second.begin(),it->second.end(),sortFun);
		}
	}

	{
		vector<map<string,string> > data;
		//                    0       1        2
		const char *keys[] = {"item_id","skill_id","skill_level"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_skill_add.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			SSkillBookData t;
			t.itemId = atoi(data[i][keys[0]].c_str());
			t.skillId = atoi(data[i][keys[1]].c_str());
			t.skillLv = atoi(data[i][keys[2]].c_str());
			m_skillBook.insert(make_pair(t.itemId,t));
			m_skillBookItem.insert(make_pair(t.skillId, t.itemId));
		}
	}

	{
		vector<map<string,string> > data;
		//                    0          1
		const char *keys[] = {"quality","total_cost_ratio"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_quality.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			int quality = atoi(data[i][keys[0]].c_str());
			int cost_ratio = atoi(data[i][keys[1]].c_str());
			m_upStar_qualityCost.insert(make_pair(quality,cost_ratio));
		}
	}

	{
		vector<map<string,string> > data;
		//                    0      1        2          3         4
		const char *keys[] = {"star","star_ratio","step_ratio","total_cost","level_limit"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_star.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			SPetStarData t;
			t.star = atoi(data[i][keys[0]].c_str());
			t.star_ratio = atoi(data[i][keys[1]].c_str());
			t.step_ratio = atoi(data[i][keys[2]].c_str());
			t.total_cost = atoi(data[i][keys[3]].c_str());
			t.level_limit = atoi(data[i][keys[4]].c_str());
			m_upStar_star.insert(make_pair(t.star,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                    0   1       2         3
		const char *keys[] = {"step","attr","attr_ratio","cost_ratio"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_star_step.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(int i=0;i < (int)data.size();i++)
		{
			SPetStarStepData t;
			t.step = atoi(data[i][keys[0]].c_str());
			t.attrType = atoi(data[i][keys[1]].c_str());
			t.attr_ratio = atoi(data[i][keys[2]].c_str());
			t.cost_ratio = atoi(data[i][keys[3]].c_str());
			m_upStar_step.insert(make_pair(t.step,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                    0      1       2            3          4           5           6           7            8          9          10          11         12
		const char *keys[] = {"quality","level","index1_attr","index1_level","index2_attr","index2_level","index3_attr","index3_level","index4_attr","index4_level","index5_attr","index5_level","cost_item"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_xiulian.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(uint8 i=0;i < data.size();i++)
		{
			uint8 quality = atoi(data[i][keys[0]].c_str());
			uint8 level = atoi(data[i][keys[1]].c_str());
			SPetXiuLianData t;
			for(uint8 j=0;j < PET_XIU_LIAN_MAX_NUM;j++)
			{
				t.xiulianData[j].level_limit = atoi(data[i][keys[2*j+3]].c_str());
				SetAttrData(t.xiulianData[j].attrList, data[i][keys[2*j+2]]);
			}
			if(!SetCostData(t.cost,data[i][keys[12]]))
				cout<<"CPetCfgManager::Init() SetCostData error: "<<data[i][keys[12]]<<endl;
			uint32 key = (quality<<8) | level;
			m_xiulianData.insert(make_pair(key,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0       1           2           3          4         5            6             7          8          9
		const char *keys[] = {"type","attackRatio","wufangRatio","fafangRatio","suduRatio","qixueRatio","mingzhongRatio","shanbiRatio","baojiRatio","kangbaoRatio"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_type_attr_ratio.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		for(uint8 i=0;i < data.size();i++)
		{
			uint8 type = atoi(data[i][keys[0]].c_str());
			SPetTypeRatioData t;
			t.attackRatio = atoi(data[i][keys[1]].c_str())/10000.0;
			t.wufangRatio = atoi(data[i][keys[2]].c_str())/10000.0;
			t.fafangRatio = atoi(data[i][keys[3]].c_str())/10000.0;
			t.suduRatio = atoi(data[i][keys[4]].c_str())/10000.0;
			t.qixueRatio = atoi(data[i][keys[5]].c_str())/10000.0;
			t.mingzhongRatio = atoi(data[i][keys[6]].c_str())/10000.0;
			t.shanbiRatio = atoi(data[i][keys[7]].c_str())/10000.0;
			t.baojiRatio = atoi(data[i][keys[8]].c_str())/10000.0;
			t.baojiKangRatio = atoi(data[i][keys[9]].c_str())/10000.0;
			m_petTypeRatio.insert(make_pair(type,t));
		}
	}
	

	return true;
}

SPetBasicData *CPetCfgManager::GetPetCfg(uint16 id)
{
	map<uint16,SPetBasicData>::iterator it = m_basicData.find(id);
	if(it != m_basicData.end())
		return &(it->second);
	return NULL;
}

bool CPetCfgManager::InitBasicData(SPet *pPet)
{
	if(pPet == NULL || pPet->id == 0)
		return false;
	
	SPetBasicData *pCfg = GetPetCfg(pPet->id);
	if(pCfg == NULL)
		return false;
	pPet->quality = pCfg->quality;
	pPet->type = pCfg->type;
	pPet->attackType = pCfg->attackType;
	pPet->pic = pCfg->pic;
	return true;
}

uint32 CPetCfgManager::GetLevelUpExp(uint16 nextLv)
{
	if(nextLv == 0 || nextLv > m_petMaxLevel)
		return 0;
	return m_LvUpExp[nextLv-1];
}

LvCfg* CPetCfgManager::GetLvCfgCfg(uint16 nextLv)
{
	LvCfgMapIt it = m_userLvUpExp.find(nextLv);
	if (it == m_userLvUpExp.end())
		return NULL;
	return &it->second;
}

uint16 CPetCfgManager::GetPetMaxLevel()
{
	return m_petMaxLevel;
}

SSkillLvCost *CPetCfgManager::GetSkillCostData_Normal(uint16 skillId,uint16 skillLv)
{
	map<uint16,vector<SSkillLvCost> >::iterator it = m_skillCost.find(skillId);
	if(it == m_skillCost.end())
		return NULL;
	vector<SSkillLvCost> &skills = it->second;
	if((uint16)(skillLv-1) >= skills.size())
		return NULL;
	return &skills[skillLv-1];
}

SSkillLvCost *CPetCfgManager::GetSkillCostData_Born(uint8 skillPos,uint16 skillLv)
{
	if(skillPos >= PET_BORN_SKILL_NUM)
		return NULL;
	vector<SSkillLvCost> &bornSkill = m_bornSkillCost[skillPos];
	if((uint16)(skillLv-1) >= bornSkill.size())
		return NULL;
	return &bornSkill[skillLv-1];
}

SSkillBookData *CPetCfgManager::GetSkillBookData(uint16 itemId)
{
	if(itemId == 0)
		return NULL;
	map<uint16,SSkillBookData>::iterator it = m_skillBook.find(itemId);
	if(it == m_skillBook.end())
		return NULL;
	return &(it->second);
}

uint16 CPetCfgManager::GetSkillBookid(uint16 skillId)
{
	if (skillId == 0)
		return 0;
	map<uint16, uint16>::iterator it = m_skillBookItem.find(skillId);
	if (it == m_skillBookItem.end())
		return 0;
	return it->second;
}

void CPetCfgManager::GetSkillAllCost(uint16 skillId, uint16 maxLv, map<uint16, int>& cost, float rate)
{
	map<uint16, vector<SSkillLvCost> >::iterator it = m_skillCost.find(skillId);
	if (it == m_skillCost.end())
		return;
	vector<SSkillLvCost> &skills = it->second;
	if ((uint16)(maxLv - 1) >= skills.size())
		return;

	for (uint16 i = 0; i < maxLv - 1; ++i)
	{
		vector<SCostData>& curCost = skills[i].costList;
		for (size_t ci = 0; ci < curCost.size(); ++ci)
		{
			cost[curCost[ci].costType] += curCost[ci].costValue;
		}
	}
}

void CPetCfgManager::GetXiulianAllCost(uint16 quality, uint8 level, map<uint16, int>& cost)
{
	if (quality == 0) return;
	for (uint8 i = 0; i < level; ++i)
	{
		uint32 key = (quality << 8) | i;
		map<uint32, SPetXiuLianData>::iterator it = m_xiulianData.find(key);
		if (it == m_xiulianData.end())
			continue;
		vector<SCostData>& curCost = it->second.cost;
		for (size_t ci = 0; ci < curCost.size(); ++ci)
		{
			cost[curCost[ci].costType] += curCost[ci].costValue;
		}

	}
}

int CPetCfgManager::GetUpStarCost(uint8 quality,uint8 star,uint8 step)
{
	map<int,int>::iterator qIt = m_upStar_qualityCost.find(quality);
	if(qIt == m_upStar_qualityCost.end())
		return -1;
	map<int,SPetStarData>::iterator sIt = m_upStar_star.find(star);
	if(sIt == m_upStar_star.end())
		return -1;
	map<int,SPetStarStepData>::iterator pIt = m_upStar_step.find(step+1);
	if(pIt == m_upStar_step.end())
		return -1;
	int cost = sIt->second.total_cost * (qIt->second/10000.0) * (pIt->second.cost_ratio/10000.0);
	if(cost < 0)
		cost = 0;
	return cost;
}

bool CPetCfgManager::GetStarAttr(vector<SAttrData> &attr,uint16 petId,uint8 star, uint16 lv)
{
	attr.clear();
	
	HeroStarCfg* starCfg = sCHeroCfgManager.GetHeroStarCfg(star);
	if (starCfg == NULL)
		return false;
	SPetBasicData *pCfg = GetPetCfg(petId);
	if(pCfg == NULL)
		return false;

	double starRatio = starCfg->attrRate/10000.0;
	if(starRatio > 0)
	{
		SAttrData t;
		t.attrType = EAT_Attack;
		t.attrValue = pCfg->attackCZ * starRatio * lv + pCfg->attackCZ * starCfg->attrExSum;
		AddToAttrList(attr,t);
		
		t.attrType = EAT_WuFang;
		t.attrValue = pCfg->wufangCZ * starRatio * lv + pCfg->wufangCZ * starCfg->attrExSum;
		AddToAttrList(attr,t);

		t.attrType = EAT_FaFang;
		t.attrValue = pCfg->fafangCZ * starRatio * lv + pCfg->fafangCZ * starCfg->attrExSum;
		AddToAttrList(attr,t);

		t.attrType = EAT_QiXue;
		t.attrValue = pCfg->qixueCZ * starRatio * lv + pCfg->qixueCZ * starCfg->attrExSum;
		AddToAttrList(attr,t);
	}
	return true;
}

bool CPetCfgManager::GetBreakAttr(vector<SAttrData> &attr, uint16 petId, uint16 blv)
{
	if (blv == 0)
		return true;
	attr.clear();
	uint16 attrAdd = sCHeroCfgManager.GetBreakAttrAdd(blv);
	if (attrAdd == 0)
		return false;
	SPetBasicData *pCfg = GetPetCfg(petId);
	if (pCfg == NULL)
		return false;

	SAttrData t;
	t.attrType = EAT_Attack;
	t.attrValue = pCfg->attackCZ * attrAdd;
	AddToAttrList(attr, t);

	t.attrType = EAT_WuFang;
	t.attrValue = pCfg->wufangCZ * attrAdd;
	AddToAttrList(attr, t);

	t.attrType = EAT_FaFang;
	t.attrValue = pCfg->fafangCZ * attrAdd;
	AddToAttrList(attr, t);

	t.attrType = EAT_QiXue;
	t.attrValue = pCfg->qixueCZ * attrAdd;
	AddToAttrList(attr, t);
	for (uint8 bi = 0; bi < blv; ++bi)
		MergeAttrList(attr, pCfg->topoAttrs[bi].selfAttrs);
	return true;
}

int CPetCfgManager::GetUpStarLevelLimit(uint8 star)
{
	map<int,SPetStarData>::iterator it = m_upStar_star.find(star);
	if(it == m_upStar_star.end())
		return -1;
	return it->second.level_limit;
}

SPetTypeRatioData *CPetCfgManager::GetPetTypeAttrRatio(uint8 type)
{
	if(type == 0)
		return NULL;
	map<uint8,SPetTypeRatioData>::iterator it = m_petTypeRatio.find(type);
	if(it == m_petTypeRatio.end())
		return NULL;
	return &(it->second);
}

void CPetCfgManager::SetBornSkill(vector<uint16> &skill,string &str)
{
	if(str.empty())
		return;
	
	char buf[64];
	int num = 0;
	char *p[4] = {NULL,NULL,NULL,NULL};
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		if(strlen(p[i]) == 0)
			continue;
		skill.push_back(atoi(p[i]));
	}
}

void CPetCfgManager::MergeCost(map<uint16, int>& allCost, vector<SCostData>& addCost)
{
	for (size_t i = 0; i < addCost.size(); ++i)
	{
		allCost[addCost[i].costType] += addCost[i].costValue;
	}
}

void CPetCfgManager::SubCost(map<uint16, int>& allCost, vector<SCostData>& subCost)
{
	for (size_t i = 0; i < subCost.size(); ++i)
	{
		allCost[subCost[i].costType] -= subCost[i].costValue;
		if (allCost[subCost[i].costType] < 0)
			allCost[subCost[i].costType] = 0;
	}
}

static const uint16 PetBornSkill[] = {177,183,186,210,219,222,231,232,233};

struct PetZiZhiBasic
{
	uint16 attack;
	uint16 attackStep;
	uint16 defence;
	uint16 defenceStep;
	uint16 maxHp;
	uint16 maxHpStep;
	uint16 speed;
	uint16 speedStep;
};


// level,exp,item1,itemNum1,item2,itemNum2
static const int NeedItem[][6] = {
	{0,0,613,4,614,4},
	{1,0,613,6,614,6},
	{2,0,613,7,614,7},
	{3,0,613,8,614,8},
	{4,0,613,11,614,11},
	{5,0,613,14,614,14},
	{6,0,613,16,614,16},
	{6,1,613,19,614,19},
	{7,0,613,23,614,23},
	{7,1,613,26,614,26},
	{8,0,613,29,614,29},
	{8,1,613,33,614,33},
	{9,0,613,38,614,38},
	{9,1,613,42,614,42},
	{10,0,613,47,614,47},
	{10,1,613,51,614,51},
	{11,0,613,57,614,57},
	{11,1,613,62,614,62},
	{11,2,613,68,614,68},
	{12,0,613,73,614,73},
	{12,1,613,80,614,80},
	{12,2,613,87,614,87},
	{13,0,613,93,614,93},
	{13,1,613,100,614,100},
	{13,2,613,108,614,108},
	{14,0,613,115,614,115},
	{14,1,613,124,614,124},
	{14,2,613,130,614,130},
	{15,0,613,140,614,140},
	{15,1,613,149,614,149},
	{15,2,613,157,614,157},
	{16,0,613,167,614,167},
	{16,1,613,176,614,176},
	{16,2,613,186,614,186},
	{16,3,613,196,614,196},
	{17,0,613,207,614,207},
	{17,1,613,218,614,218},
	{17,2,613,229,614,229},
	{17,3,613,239,614,239},
	{18,0,613,252,614,252},
	{18,1,613,263,614,263},
	{18,2,613,276,614,276},
	{18,3,613,288,614,288},
	{19,0,613,301,614,301},
	{19,1,613,314,614,314},
	{19,2,613,328,614,328},
	{19,3,613,341,614,341},
	{20,0,613,356,614,356},
	{20,1,613,369,614,369},
	{20,2,613,377,614,377},
	{20,3,613,379,614,379},
	{21,0,613,381,614,381},
	{21,1,613,383,614,383},
	{21,2,613,385,614,385},
	{21,3,613,387,614,387},
	{21,4,613,389,614,389},
	{22,0,613,391,614,391},
	{22,1,613,393,614,393},
	{22,2,613,395,614,395},
	{22,3,613,397,614,397},
	{22,4,613,399,614,399},
	{23,0,613,401,614,401},
	{23,1,613,403,614,403},
	{23,2,613,405,614,405},
	{23,3,613,407,614,407},
	{23,4,613,409,614,409},
	{24,0,613,411,614,411},
	{24,1,613,413,614,413},
	{24,2,613,415,614,415},
	{24,3,613,417,614,417},
	{24,4,613,419,614,419},
	{25,0,613,421,614,421},
	{25,1,613,423,614,423},
	{25,2,613,425,614,425},
	{25,3,613,427,614,427},
	{25,4,613,429,614,429},
	{26,0,613,431,614,431},
	{26,1,613,433,614,433},
	{26,2,613,435,614,435},
	{26,3,613,437,614,437},
	{26,4,613,439,614,439},
	{27,0,613,441,614,441},
	{27,1,613,443,614,443},
	{27,2,613,445,614,445},
	{27,3,613,447,614,447},
	{27,4,613,449,614,449},
	{28,0,613,451,614,451},
	{28,1,613,453,614,453},
	{28,2,613,455,614,455},
	{28,3,613,457,614,457},
	{28,4,613,459,614,459},
	{29,0,613,461,614,461},
	{29,1,613,463,614,463},
	{29,2,613,465,614,465},
	{29,3,613,467,614,467},
	{29,4,613,469,614,469},
	{30,0,613,471,614,471},
	{30,1,613,473,614,473},
	{30,2,613,475,614,475},
	{30,3,613,477,614,477}};

uint8 SPet::extNum = 1;
void SPet::Clear()
{
	type = 0;
	attackType = 0;
	quality = 0;
	star = 0;
	breakLevel = 0;
	chuzhanFlag = 0;

	id = 0;
	level = 0;
	celue = 0;
	exp = 0;
	zhanDouli = 0;

	hp = 0;
	basicAttr.Clear();
	name.clear();

	xiuLianLevel = 0;
	curXiuLianCnts.clear();
	for(int i=0;i < PET_MAX_SKILL_NUM;i++)
	{
		skill[i] = 0;
		skillLevel[i] = 0;
	}
}
uint8 SPet::GetSkillNum()
{
	uint8 num = 0;
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] != 0)
			num++;
	}
	return num;
}

uint8 SPet::GetSkillNum(bool isZhuDong)
{
	uint8 num = 0;
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if (skill[i] == 0)
		{

		}
		else if (isZhuDong)
		{
			if (skill[i] <= 105)
			{
				++num;
			}
		}
		else
		{
			if (skill[i] > 105)
			{
				++num;
			}
		}
	}
	return num;
}

uint16 SPet::GetSkillLevel(uint16 id)
{
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] == id || (id == 34 && skill[i] == 31) || (id == 35 && skill[i] == 28) || (id == 36 && skill[i] == 29))
		{
			return skillLevel[i];
		}
	}
	return 0;
}


int SPet::VerifyLevelAndNum(uint32 level){
	#if 0
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		cout<<"EMISS_DC_22 verify pet skill level , require = "<<level<<", petskilllevel = "<<skillLevel[i]<<endl;		
	}
	#endif

	int cnt = 0;
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skillLevel[i] >= level)
			cnt++;
	}
	return cnt;
}

int SPet::VerifyXueMaiLevelAndNum(uint32 level){
	
	int cnt = 0;
	if(xiuLianLevel >= level)
	{
		cnt++;
	}
	return cnt;
}


void SPet::GetSuitSkills(vector<SSkillData> &skillList)
{
	skillList = otherSkill;
}

uint8 SPet::GetSkillPos(uint16 id)
{
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] == id)
		{
			return i;
		}
	}
	return 0xff;
}

void SPet::ForgetSkill(uint8 pos)
{
	if(pos < PET_BORN_SKILL_NUM ||  pos >= PET_MAX_SKILL_NUM)
		return;
	skill[pos] = 0;
	skillLevel[pos] = 0;
}

void SPet::GetSkillInfoByPos(uint8 pos,uint16 &skillId,uint16 &skillLv)
{
	skillId = 0;
	skillLv = 0;
	if(pos >= PET_MAX_SKILL_NUM)
		return;
	skillId = skill[pos];
	skillLv = skillLevel[pos];
}

bool SPet::AddSkillByPos(uint8 pos,uint16 skillId,uint16 skillLv)
{
	if(pos < PET_BORN_SKILL_NUM || pos >= PET_MAX_SKILL_NUM)
		return false;
	skill[pos] = skillId;
	skillLevel[pos] = skillLv;
	return true;
}

uint8 SPet::GetSkillLevel_ALL(uint16 id)
{
	return 0;
}

void SPet::DelSkill(uint16 id)
{
	for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] == id)
		{
			skill[i] = 0;
			skillLevel[i] = 0;
			return;
		}
	}
}

uint8 SPet::AddSkill(uint16 id,bool fuGai,int *pFugaiId)
{
	if(fuGai)
	{
		//gailv skillId
		int skillFuGai[] = {10,160,  40,161,  80,162,  80,163,  10,164,  50,165,  70,166,  80,167,  20,168,  60,169,  60,170,  10,171,  90,172,  10,173,  40,174,  80,175,  80,176,  10,177,  50,178,  70,179,  80,180,  20,181,  60,182,  60,183,  10,184,  90,185,  60,51,  20,55,  90,59,  20,63,  20,67,  20,151,  80,152,  60,153,  20,154,  20,158,  20,101,  20,105,  50,109,  20,113,  50,117,  95,155,  95,156,  95,157,  95,3,  95,7,  95,11,  95,15,  95,19};
		int size = sizeof(skillFuGai)/sizeof(int);
		int tol = 0;
		int gailv[PET_MAX_SKILL_NUM] = {0};
		for(uint8 i = 3; i < PET_MAX_SKILL_NUM; i++)
		{
			if(skill[i] != 0)
			{
				for(int j = 1; j < size; j += 2)
				{
					if(skill[i] == skillFuGai[j])
					{
						tol += skillFuGai[j-1];
						gailv[i] = tol;
						break;
					}
				}
			}
		}
		if(tol == 0)
		{
			if(pFugaiId != NULL)
				*pFugaiId = skill[3];
			skill[3] = id;
			skillLevel[3] = 1;
			return 1;
		}
		int r = Random(0,tol);
		for(uint8 i = 3; i < PET_MAX_SKILL_NUM; i++)
		{
			if((skill[i] != 0) && (r <= gailv[i]))
			{
				if(pFugaiId != NULL)
					*pFugaiId = skill[i];
				skill[i] = id;
				skillLevel[i] = 1;
				return 1;
			}
		}
	}
	for(uint8 i = 3; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] == id)
		{
			skillLevel[i]++;
			return skillLevel[i];
		}
	}
	for(uint8 i = 3; i < PET_MAX_SKILL_NUM; i++)
	{
		if(skill[i] == 0)
		{
			skill[i] = id;
			skillLevel[i] = 1;
			return skillLevel[i];
		}
	}
	return 0;
}

void SPet::GetXueMaiAddVal(int type,int XMLevel,int XMExp,int &attack,int &recovery,int &hp,int &speed)
{
	static vector<vector<int> > ADD_VAL;
	if(ADD_VAL.empty())
	{
		vector<map<string,string> > data;
		//                   0    1        2          3           4          5            6            7            8             9           10           11           12           13           14            15             16            17
		const char *keys[] = {"level","exp","baihu_type1","baihu_val1","baihu_type2","baihu_val2","xuanwu_type1","xuanwu_val1","xuanwu_type2","xuanwu_val2","zhuque_type1","zhuque_val1","zhuque_type2","zhuque_val2","qinglong_type1","qinglong_val1","qinglong_type2","qinglong_val2"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_xuemai.xml");
		if(!reader.GetAllElements(data,keys,size))
			return;
		for(uint16 i=0;i < data.size();i++)
		{
			vector<int> t;
			for(uint16 j=0; j < size; j++)
				t.push_back(atoi(data[i][keys[j]].c_str()));
			ADD_VAL.push_back(t);
		}
	}

 	if(type > PET_XUEMAI_MAX_NUM-1)
		return;
	uint16 size = ADD_VAL.size();
	if(XMLevel >= size)
		return;
	attack = 0;
	recovery = 0;
	hp = 0;
	speed = 0;

	uint8 idx = 0xff;
	for(uint8 i=0;i < size;i++)
	{
		if(ADD_VAL[i][0] == XMLevel)
		{
			if(ADD_VAL[i][1] == XMExp)
			{
				idx = i;
				break;
			}
			else if(ADD_VAL[i][1] > XMExp)
				break;
		}
		else if(ADD_VAL[i][0] > XMLevel)
			break;
	}

	if(idx == 0xff)
		return;
	uint8 pos = 2;
	if(type == 0)
		pos = 2;
	else if(type == 1)
		pos = 6;
	else if(type == 2)
		pos = 10;
	else if(type == 3)
		pos = 14;

	if(ADD_VAL[idx][pos] == 1)
		attack = ADD_VAL[idx][pos+1];
	else if(ADD_VAL[idx][pos] == 2)
		recovery = ADD_VAL[idx][pos+1];
	else if(ADD_VAL[idx][pos] == 3)
		hp = ADD_VAL[idx][pos+1];
	else if(ADD_VAL[idx][pos] == 4)
		speed = ADD_VAL[idx][pos+1];
	
	if(ADD_VAL[idx][pos+2] == 1)
		attack = ADD_VAL[idx][pos+3];
	else if(ADD_VAL[idx][pos+2] == 2)
		recovery = ADD_VAL[idx][pos+3];
	else if(ADD_VAL[idx][pos+2] == 3)
		hp = ADD_VAL[idx][pos+3];
	else if(ADD_VAL[idx][pos+2] == 4)
		speed = ADD_VAL[idx][pos+3];
}

int SPet::GetXueMaiDiffPrice(uint8 hLv,uint8 hExp,uint8 lLv,uint8 lExp)
{
	if(hLv < lLv || (hLv == lLv && hExp <= lExp))
		return 0;
	uint8 size = sizeof(NeedItem)/sizeof(NeedItem[0]);
	if(hLv > NeedItem[size-1][0] || (hLv == NeedItem[size-1][0] && hExp > NeedItem[size-1][1]))
		return 0;

	uint8 hIdx = 0xff;
	uint8 lIdx = 0xff;
	for(uint8 i=0;i < size;i++)
	{
		if(NeedItem[i][0] == hLv)
		{
			if(NeedItem[i][1] == hExp)
			{
				hIdx = i;
				break;
			}
			else if(NeedItem[i][1] > hExp)
				break;
		}
		else if(NeedItem[i][0] > hLv)
			break;
	}
	for(uint8 i=0;i < size;i++)
	{
		if(NeedItem[i][0] == lLv)
		{
			if(NeedItem[i][1] == lExp)
			{
				lIdx = i;
				break;
			}
			else if(NeedItem[i][1] > lExp)
				break;
		}
		else if(NeedItem[i][0] > lLv)
			break;
	}

	if(hIdx == 0xff || lIdx == 0xff)
		return 0;
	int price = 0;
	for(uint8 i=lIdx;i < hIdx;i++)
		price += NeedItem[i][3];
	return price;
}

void SPet::GetXueMaiLevelUpItem(uint8 xMLevel,uint8 xMExp,uint8 &nextLv,uint8 &nextExp,int &item1,int &itemNum1,int &item2,int &itemNum2)
{
	uint8 size = sizeof(NeedItem)/sizeof(NeedItem[0]);
	if(xMLevel > NeedItem[size-1][0] || (xMLevel == NeedItem[size-1][0] && xMExp > NeedItem[size-1][1]))
		return;

	item1 = 0;
	itemNum1 = 0;
	item2 = 0;
	itemNum2 = 0;
	nextLv = 0;
	nextExp = 0;

	uint8 idx = 0xff;
	for(uint8 i=0;i < size;i++)
	{
		if(NeedItem[i][0] == xMLevel)
		{
			if(NeedItem[i][1] == xMExp)
			{
				idx = i;
				break;
			}
			else if(NeedItem[i][1] > xMExp)
				break;
		}
		else if(NeedItem[i][0] > xMLevel)
			break;
	}

	if(idx != 0xff)
	{
		item1 = NeedItem[idx][2];
		itemNum1 = NeedItem[idx][3];
		item2 = NeedItem[idx][4];
		itemNum2 = NeedItem[idx][5];
		if(idx != size - 1)
		{
			nextLv = (uint8)NeedItem[idx+1][0];
			nextExp = (uint8)NeedItem[idx+1][1];
		}
		else
		{
			nextLv = (uint8)NeedItem[idx][0];
			nextExp = (uint8)NeedItem[idx][1]+1;
		}
	}
}

// 获取技能数量上限
int SPet::GetSkilLimitCount()
{
	int count = level/8;
	if (count < 2)
		return 2;
	if (count > PET_MAX_SKILL_NUM)
		return PET_MAX_SKILL_NUM;
	return count;
}

// 获取技能id
int SPet::GetSkillId(int pos)
{
	if (pos < 0 || pos >= PET_MAX_SKILL_NUM)
		return 0;
	return skill[pos];
}

// 学习技能
int SPet::LearnSkill(int skillId,int pos)
{
	if (pos < 0 || pos >= PET_MAX_SKILL_NUM)
		return 0;
	if (skill[pos] == skillId)
	{
		skillLevel[pos]++;
	}
	else
	{
		skill[pos] = skillId;
		skillLevel[pos] = 1;
	}

	//	if(skillId >= 151 && skillId < 160)
	//		zhanDouli += 50;
	//	else if(skillId == 3 || skillId == 7 || skillId == 11 || skillId == 15 || skillId == 19)
	//		zhanDouli += 30;
	//	else if(skillId >= 160)
	//		zhanDouli += 15;
	return skillLevel[pos];
}

// 初始化神将技能
void SPet::InitSkill()
{
	// 三个天生技能
	uint16 skillId1 = 0,skillId2 = 0,skillId3 = 0;
	switch(type)
	{
	case EXJinXiang:
		skillId1 = 32;
		skillId2 = 33;
		skillId3 = 10;
		break;
	case EXMuXiang:
		skillId1 = 11;
		skillId2 = 12;
		skillId3 = 13;
		break;
	case EXShuiXiang:
		skillId1 = 14;
		skillId2 = 15;
		skillId3 = 16;
		break;
	case EXHuoXiang:
		skillId1 = 22;
		skillId2 = 23;
		skillId3 = 0;
		break;
	case EXTuXiang:
		skillId1 = 24;
		skillId2 = 25;
		skillId3 = 0;
		break;
	default: // 不是法神将，没有技能
		return;
	}

	for (int i = 0; i < PET_MAX_SKILL_NUM; ++i)
	{
		if(skill[i] == skillId1)
			skillLevel[i] = (level + 1)/2;
		else if(skill[i] == skillId2)
			skillLevel[i] = (level - 38)/2;
		else
		{
			if(skillId3 != 0 && skill[i] == skillId3)
				skillLevel[i] = (level - 58)/2;
		}	
		//		if ((skill[i] == skillId1) || (skill[i] == skillId2) || (skill[i] == skillId3))
		//			skillLevel[i] = level;
	}
	/*
	skill[0] = skillId1;
	skillLevel[0] = level;
	if(level >= 30)
	{
	skill[1] = skillId2;
	skillLevel[1] = level;
	}
	if(level >= 60)
	{
	skill[2] = skillId3;
	skillLevel[2] = level;
	}
	*/
}

// 学习天生技能 特殊处理
void SPet::LearnBornSkill()
{
	if (!((level == 1) || (level == 40) || (level == 60)))
		return;

	// 三个天生技能
	uint16 skillId1 = 0,skillId2 = 0,skillId3 = 0;
	switch(type)
	{
	case EXJinXiang:
		skillId1 = 32;
		skillId2 = 33;
		skillId3 = 10;
		break;
	case EXMuXiang:
		skillId1 = 11;
		skillId2 = 12;
		skillId3 = 13;
		break;
	case EXShuiXiang:
		skillId1 = 14;
		skillId2 = 15;
		skillId3 = 16;
		break;
	case EXHuoXiang:
		skillId1 = 22;
		skillId2 = 23;
		skillId3 = 0;
		break;
	case EXTuXiang:
		skillId1 = 24;
		skillId2 = 25;
		skillId3 = 0;
		break;
	default: // 不是法神将，没有技能
		return;
	}

	int curZhuDongNum = GetSkillNum(true); // 当前主动技能数量

	// 找空位置，学习技能
	for (int i = 0; i < PET_MAX_SKILL_NUM; ++i)
	{
		//		if ((level == 1) && (skill[i] == skillId1)) // 灯笼鬼 天生火球术技能特殊处理
		//		{
		//			skillLevel[i] = (level + 1)/2;
		//			break;
		//		}
		if ((skill[i] == 0) && (curZhuDongNum < 6)) // 空位置
		{
			if (level == 1)
			{
				skill[i] = skillId1;
				skillLevel[i] = 1;;
			}
			else if (level == 40)
			{
				skill[i] = skillId2;
				skillLevel[i] = 1;
			}
			else if (level == 60)
			{
				if (skillId3 != 0)
				{
					skill[i] = skillId3;
					skillLevel[i] = 1;
				}
			}
			break;
		}
	}
}

// 学习天生技能 野怪处理
void SPet::LearnBornSkillWild()
{
	// 三个天生技能
	uint16 skillId1 = 0,skillId2 = 0,skillId3 = 0;
	switch(type)
	{
	case EXJinXiang:
		skillId1 = 32;
		skillId2 = 33;
		skillId3 = 10;
		break;
	case EXMuXiang:
		skillId1 = 11;
		skillId2 = 12;
		skillId3 = 13;
		break;
	case EXShuiXiang:
		skillId1 = 14;
		skillId2 = 15;
		skillId3 = 16;
		break;
	case EXHuoXiang:
		skillId1 = 22;
		skillId2 = 23;
		skillId3 = 0;
		break;
	case EXTuXiang:
		skillId1 = 24;
		skillId2 = 25;
		skillId3 = 0;
		break;
	default: // 不是法神将，没有技能
		return;
	}

	// 技能处理标志
	bool skillFlag1 = false;
	bool skillFlag2 = false;
	bool skillFlag3 = false;

	// 已经学习的技能升级
	for (int i = 0; i < PET_MAX_SKILL_NUM; ++i)
	{
		if (skill[i] == skillId1)
		{
			skillFlag1 = true;
			skillLevel[i] = (level + 1)/2;
		}
		if (skill[i] == skillId2)
		{
			skillFlag2 = true;
			skillLevel[i] = (level - 38)/2;
		}
		if (skill[i] == skillId3)
		{
			skillFlag3 = true;
			skillLevel[i] = (level - 58)/2;
		}
	}

	// 没有达到学习等级
	if (level < 60)
		skillFlag3 = true;
	if (level < 40)
		skillFlag2 = true;

	// 学习新技能
	for (int i = 0; i < PET_MAX_SKILL_NUM; ++i)
	{
		if (skill[i] == 0) // 空位置
		{
			if (!skillFlag1)
			{
				skillFlag1 = true;
				skill[i] = skillId1;
				skillLevel[i] = (level + 1)/2;
				//cout << "野怪宝宝学习技能1" << endl;
			}
			else if (!skillFlag2)
			{
				skillFlag2 = true;
				skill[i] = skillId2;
				skillLevel[i] = (level - 38)/2;
				//cout << "野怪宝宝学习技能2" << endl;
			}
			else if (!skillFlag3)
			{
				skillFlag3 = true;
				if (skillId3 != 0)
				{
					skill[i] = skillId3;
					skillLevel[i] = (level - 58)/2;
				}
				//cout << "野怪宝宝学习技能3" << endl;
			}
		}
		if (skillFlag1 && skillFlag2 && skillFlag3)
			break;
	}
}

// 技能升级
void SPet::UpgradeSkill(int skillId, int cnt/* = 1*/)
{
	for (int i = 0; i < PET_MAX_SKILL_NUM; ++i)
	{
		if (skill[i] == skillId)
		{
			skillLevel[i] += cnt;
			return;
		}
	}
}

int SPet::GetWuFang()
{
	return basicAttr.wufang;
}

int SPet::GetFaFang()
{
	return basicAttr.fafang;
}


// 将神将重置到1级，等级转移功能用
void SPet::ResetToLv1(CUser *pUser)
{
	level = 1; // 等级
	skill[1] = 0; // 30级技能
	skillLevel[1] = 0;
	skill[2] = 0; // 60级技能
	skillLevel[2] = 0;

	// 已没有用到，如需使用需要加上神将铠index参数
	Init(pUser); // 属性初始化
	hp = basicAttr.maxHp; // hp回满
};

// basicQuality>=1
double SPet::GetBasicValueRatioByQuality(int basicQuality,int curQuality,int curQuaLevel)
{
	const double ratio[] = {1.05,1.075,1.085,1.095,1.1,1.106,1.039};
	double t = 1.0;
	int basicLevel = 0;
	while(basicQuality < curQuality || (basicQuality == curQuality && basicLevel < curQuaLevel))
	{
		t *= ratio[basicQuality-1];
		if(basicLevel >= 3)
		{
			basicQuality++;
			basicLevel = 0;
		}
		else
		{
			basicLevel++;
		}
	}
	return t;
}

/*
SPet::SPet()
{
	level = 0;
	type = 0;
	xiang = 0;
	chuzhanFlag = 0;
	quality = 0;
	qualityLevel = 0;
	qualityLevelExp = 0;
	memset(name,0,sizeof(name));

	hpCZ = 0;
	defenceCZ = 0
	speedCZ = 0;
	attackCZ = 0
	skillAttackCZ = 0;

	gedang = 0;
	gedangQiangHua = 0;
	fanshang = 0;
	fanshangadd = 0;
	fanjiQiangHua = 0;
	renxingQiangHua = 0;
	lianjiQiangHua = 0;
	zhaojiaQiangHua = 0;
	lianji = 0;
	zhaojia = 0;
	fanJiLv = 0;
	jianshang = 0;
	shanbi = 0;
	renxing = 0;
	mingZhong = 0;
	jianShangDamage = 0;
	zhanDouli = 0;
	baojilv = 0;
	baojiQiangHua = 0;
	celue = 0;

	jiaQiangSeal = 0;
	jiaQiangZhongDu = 0;
	jiaQiangBingDong = 0;
	jiaQiangHunShui = 0;
	jiaQiangHunLuan = 0;
	kangSeal = 0;
	kangZhongDu = 0;
	kangBingDong = 0;
	kangHunShui = 0;
	kangHunLuan = 0;

	maxHp = 0;
	maxMp = 0;
	hp = 0;
	mp = 0;
	speed = 0;
	attack = 0;
	fashuAttack = 0;
	recovery = 0;
	xiuWei = 0;
	tmplId = 0;
	memset(skill,0,sizeof(skill));
	memset(skillLevel,0,sizeof(skillLevel));
	memset(defaultSkill,0,sizeof(defaultSkill));
}
*/

bool SPet::GetAttrList(CUser *pUser, vector<SAttrData> &baseAttr, vector<SAttrData> &extAttr)
{
	baseAttr.clear();
	extAttr.clear();
	// 神将升星+修炼属性+天书
	// 升星属性
	CPetCfgManager &petCfg = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petCfg.GetPetCfg(id);
	if(pCfg == NULL)
		return false;
	MultiAttr tmpAttr;
	if(!petCfg.GetStarAttr(tmpAttr,id,star, level))
		return false;
	MergeAttrList(baseAttr, tmpAttr);
	MergeAttrList(baseAttr, pCfg->attrList);
	tmpAttr.clear();
	if (!petCfg.GetBreakAttr(tmpAttr, id, breakLevel))
		return false;
	MergeAttrList(baseAttr, tmpAttr);
	MultiAttr& teamAttr = pUser->GetTeamBreak();
	MergeAttrList(baseAttr, teamAttr);

	tmpAttr.clear();
	UserBook* book = pUser->GetUserBook();
	if (book != NULL)
	{
		book->GetBookAttr(tmpAttr);
		MergeAttrList(extAttr, tmpAttr);
	}
	CEquipManeger& emgr = pUser->GetPetEquipMgr();
	uint8 czPos = pUser->GetChuZhanIdx(id);
	emgr.GetEquipAttr(czPos, extAttr);
	emgr.GetSuitSkills(czPos, otherSkill);
	map<uint16, SSkillData> tmpSkills;
	for (uint8 i = 1; i < breakLevel; ++i)
	{
		MultiAttr& skills = pCfg->topoAttrs[i].skillAttrs;
		for (uint8 j = 0; j < skills.size(); ++j)
		{
			SSkillData data;
			data.id = skills[j].attrType;
			data.level = skills[j].attrValue;
			tmpSkills[data.id] = data;
		}
	}

	for (map<uint16, SSkillData>::iterator tit = tmpSkills.begin(); tit != tmpSkills.end(); ++tit)
		otherSkill.push_back(tit->second);

	// 境界
	SJingJieCfg cfg;
	CJingJieManager &mgr = SingletonCJingJieMgr::instance();
	if (mgr.GetCfg(pUser->GetJingJie(), cfg))
	{
		MergeAttrList(extAttr, cfg.attr);
	}
	// 修炼skill
	CHeroCfgManager &hmgr = sCHeroCfgManager;
	XiuLianCfg* xcfg = hmgr.GetXiuLianCfg(xiuLianLevel);
	MultiAttr xiuLianAttr;

	for (U8tU16MapIt xit = curXiuLianCnts.begin(); xit != curXiuLianCnts.end(); ++xit)
	{
		SAttrData attr;
		attr.attrType = xit->first;
		U8tU16MapIt ait = CHeroCfgManager::g_xiuLianAttrAdd.find(xit->first);
		if (ait != CHeroCfgManager::g_xiuLianAttrAdd.end())
		{
			attr.attrValue = ait->second * xit->second;

			if (xcfg != NULL)
			{
				attr.attrValue += ait->second * xcfg->sumCnt;
			}
		}
		xiuLianAttr.push_back(attr);
	}
	MergeAttrList(extAttr, xiuLianAttr);
	if (xcfg == NULL)
		return true;

	MergeAttrList(extAttr, xcfg->sumAttrs);
	for (size_t i = 0; i < xcfg->skill.size(); i++)
		otherSkill.push_back(xcfg->skill[i]);
	return true;
}

// kaijiaIndex 0-4
bool SPet::Init(CUser *pUser,bool updateBreak)
{
	//const float userAttrRatio = 0.8;
	if(id == 0 || star == 0 || level == 0)
		return false;
	CPetCfgManager &petCfg = SingletonCPetCfgMgr::instance();
	SPetBasicData *pCfg = petCfg.GetPetCfg(id);
	if (pCfg == NULL)
		return false;
	type = pCfg->type;
	attackType = pCfg->attackType;
	quality = pCfg->quality;
	int oldMaxHp = basicAttr.maxHp;

	SPetTypeRatioData *pTypeAttr = petCfg.GetPetTypeAttrRatio(type);
	if(pTypeAttr == NULL)
		return false;
	vector<SAttrData> baseAttr;	// 计算加成的属性
	vector<SAttrData> extAttrs; // 额外属性
	vector<SAttrData> bangSkillAttrs; // 帮派技能属性
	GetAttrList(pUser, baseAttr, extAttrs);

	if (pUser != NULL)
	{
		pUser->GetBangSkillAttr(2,bangSkillAttrs);
		MergeAttrList(extAttrs, bangSkillAttrs);
		uint8 zcPos = pUser->GetChuZhanIdx(id);
		if (updateBreak && zcPos > 0 && breakLevel > 0)
		{
			pUser->AddTeamBreakAttr(pCfg->topoAttrs[breakLevel - 1].teamAttrs);
		}
	}

	basicAttr.attackRatio = 10000 + GetAttrValue(baseAttr, EAT_AttackAdd) + GetAttrValue(extAttrs, EAT_AttackAdd);
	basicAttr.wufangRatio = 10000 + GetAttrValue(baseAttr, EAT_WuFangAdd) + GetAttrValue(extAttrs, EAT_WuFangAdd);
	basicAttr.fafangRatio = 10000 + GetAttrValue(baseAttr, EAT_FaFangAdd) + GetAttrValue(extAttrs, EAT_FaFangAdd);
	basicAttr.maxHpRatio = 10000 + GetAttrValue(baseAttr, EAT_QiXueAdd) + GetAttrValue(extAttrs, EAT_QiXueAdd);
	basicAttr.attackBase = (pCfg->attack + GetAttrValue(baseAttr, EAT_Attack));
	basicAttr.attackEx = GetAttrValue(extAttrs, EAT_Attack);
	basicAttr.wufangBase = (pCfg->wufang + GetAttrValue(baseAttr, EAT_WuFang));
	basicAttr.wufangEx = GetAttrValue(extAttrs, EAT_WuFang);
	basicAttr.fafangBase = (pCfg->fafang + GetAttrValue(baseAttr, EAT_FaFang));
	basicAttr.fafangEx = GetAttrValue(extAttrs, EAT_FaFang);
	basicAttr.maxHpBase = (pCfg->qixue + GetAttrValue(baseAttr, EAT_QiXue));
	basicAttr.maxHpEx = GetAttrValue(extAttrs, EAT_QiXue);

	basicAttr.attack = basicAttr.attackBase * (basicAttr.attackRatio / 10000.0) + basicAttr.attackEx;
	basicAttr.wufang = basicAttr.wufangBase * (basicAttr.wufangRatio / 10000.0) + basicAttr.wufangEx;
	basicAttr.fafang = basicAttr.fafangBase * (basicAttr.fafangRatio / 10000.0) + basicAttr.fafangEx;
	basicAttr.maxHp = basicAttr.maxHpBase * (basicAttr.maxHpRatio / 10000.0) + basicAttr.maxHpEx;
	basicAttr.speed = GetAttrValue(extAttrs, EAT_SuDu) + GetAttrValue(extAttrs, EAT_SuDu);
	basicAttr.mingzhong = GetAttrValue(baseAttr, EAT_MingZhong) + GetAttrValue(extAttrs, EAT_MingZhong);
	basicAttr.shanbi = GetAttrValue(baseAttr, EAT_ShanBi) + GetAttrValue(extAttrs, EAT_ShanBi);
	basicAttr.baoji = GetAttrValue(baseAttr, EAT_BaoJi) + GetAttrValue(extAttrs, EAT_BaoJi);
	basicAttr.baojikang = GetAttrValue(baseAttr, EAT_BaoJiKang) + GetAttrValue(extAttrs, EAT_BaoJiKang);
	basicAttr.mingzhongLv = GetAttrValue(baseAttr, EAT_MingZhongLv) + GetAttrValue(extAttrs, EAT_MingZhongLv);
	basicAttr.shanbiLv = GetAttrValue(baseAttr, EAT_ShanBiLv) + GetAttrValue(extAttrs, EAT_ShanBiLv);
	basicAttr.baojiLv = GetAttrValue(baseAttr, EAT_BaoJiLv) + GetAttrValue(extAttrs, EAT_BaoJiLv);
	basicAttr.baojikangLv = GetAttrValue(baseAttr, EAT_BaoJiKangLv) + GetAttrValue(extAttrs, EAT_BaoJiKangLv);
	basicAttr.zengshangLv = GetAttrValue(baseAttr, EAT_ZengShangLv) + GetAttrValue(extAttrs, EAT_ZengShangLv);
	basicAttr.wumianLv = GetAttrValue(baseAttr, EAT_WuMianLv) + GetAttrValue(extAttrs, EAT_WuMianLv);
	basicAttr.famianLv = GetAttrValue(baseAttr, EAT_FaMianLv) + GetAttrValue(extAttrs, EAT_FaMianLv);
	basicAttr.baojiAdd = GetAttrValue(baseAttr, EAT_BaoJiAdd) + GetAttrValue(extAttrs, EAT_BaoJiAdd);
	basicAttr.fanjiLv = GetAttrValue(baseAttr, EAT_FanJiLv) + GetAttrValue(extAttrs, EAT_FanJiLv);
	basicAttr.fanjikangLv = GetAttrValue(baseAttr, EAT_FanJiKangLv) + GetAttrValue(extAttrs, EAT_FanJiKangLv);
	basicAttr.fanjiAdd = GetAttrValue(baseAttr, EAT_FanJiAdd) + GetAttrValue(extAttrs, EAT_FanJiAdd);
	basicAttr.lianjiLv = GetAttrValue(baseAttr, EAT_LianJiLv) + GetAttrValue(extAttrs, EAT_LianJiLv);
	basicAttr.lianjikangLv = GetAttrValue(baseAttr, EAT_LianJiKangLv) + GetAttrValue(extAttrs, EAT_LianJiKangLv);
	basicAttr.lianjiAdd = GetAttrValue(baseAttr, EAT_LianJiAdd) + GetAttrValue(extAttrs, EAT_LianJiAdd);
	basicAttr.fanzhenLv = GetAttrValue(baseAttr, EAT_FanZhenLv) + GetAttrValue(extAttrs, EAT_FanZhenLv);
	basicAttr.fanzhenkangLv = GetAttrValue(baseAttr, EAT_FanZhenKangLv) + GetAttrValue(extAttrs, EAT_FanZhenKangLv);
	basicAttr.fanzhenAdd = GetAttrValue(baseAttr, EAT_FanZhenAdd) + GetAttrValue(extAttrs, EAT_FanZhenAdd);
	basicAttr.fumianAdd = GetAttrValue(baseAttr, EAT_FuMianAdd) + GetAttrValue(extAttrs, EAT_FuMianAdd);
	basicAttr.fumianKangAdd = GetAttrValue(baseAttr, EAT_FuMianKangAdd) + GetAttrValue(extAttrs, EAT_FuMianKangAdd);
	
	// 暴击伤害
	uint8 sklv = 0;
	HeroStarCfg* starCfg = sCHeroCfgManager.GetHeroStarCfg(star);
	if (starCfg != NULL)
		sklv = starCfg->skillLevel;
	for (uint8 i = 0; i < 1 && i < pCfg->bornSkill.size(); i++)
	{
		if (skill[i] == 0)
		{
			skill[i] = pCfg->bornSkill[i];
			skillLevel[i] = sklv;
		}
	}
	CAttrCfgMgr &mgr = SingletonCAttrCfgMgr::instance();
	zhanDouli = mgr.CalulateZhanDouLi(basicAttr);
	zhanDouli -= mgr.CalulateZhanDouLi(pCfg->attrList);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_25);
	if(oldMaxHp == 0)
	{
		hp = basicAttr.maxHp;
	}
	else
	{
		hp += basicAttr.maxHp - oldMaxHp;
		if(hp > basicAttr.maxHp)
			hp = basicAttr.maxHp;
		if(hp < 1)
			hp = 1;
	}
	return true;
}

void SPet::AddLevel(CUser *pUser,uint8 kaijiaIndex,int addCount)
{
	if (addCount == 1)
		level++;
	else
		level += addCount;

	Init(pUser,kaijiaIndex);
	hp = basicAttr.maxHp;
}

void SPet::AttrToZero()
{
/*
	hpCZ = 0;//气血成长
	defenceCZ = 0;//法术成长
	speedCZ = 0;//速度成长
	attackCZ = 0;//物攻成长
	skillAttackCZ = 0;//技能功能成长

	gedang = 0;		// 格挡率
	gedangQiangHua = 0;
	fanshang = 0;//反伤率
	fanshangadd = 0;//

	fanshangDiKang = 0;	// 反伤抵抗率
	fanshangDiKangQiangHua = 0;	// 反伤抵抗强化
	
	fanjiQiangHua = 0;
	renxingQiangHua = 0;
	lianjiQiangHua = 0;	// 连击强化
	zhaojiaQiangHua = 0;	
	lianji = 0;	// 连击率
	ex_lianji = 0;	//add by chy，他人请勿随意使用
	zhaojia = 0;	// 招架率
	ex_zhaojia = 0;	//add by chy，他人请勿随意使用
	fanJiLv = 0;//反击率
	ex_fanJiLv = 0; //add by chy，他人请勿随意使用
	jianshang = 0;		// 减伤百分比
	shanbi = 0;
	ex_shanbi = 0;	//add by chy，他人请勿随意使用
	renxing = 0;
	ex_renxing = 0; //add by chy，他人请勿随意使用
	mingZhong = 0;
	ex_mingZhong = 0; //add by chy，他人请勿随意使用
	jianShangDamage = 0;	// 减伤强化
	zhanDouli = 0;		// 战斗力
	baojilv = 0;		// 暴击率
	ex_baojilv = 0; //add by chy，他人请勿随意使用
	baojiQiangHua = 0;	// 暴击强化

	jiaQiangSeal = 0;		// 加强封印
	jiaQiangZhongDu = 0;	// 加强中毒
	jiaQiangBingDong = 0;	// 加强冰冻
	jiaQiangHunShui = 0;	// 加强昏睡
	jiaQiangHunLuan = 0;	// 加强混乱
	kangSeal = 0;		// 抗封印
	kangZhongDu = 0;	// 抗中毒
	kangBingDong = 0;	// 抗冰冻
	kangHunShui = 0;	// 抗昏睡
	kangHunLuan = 0;	// 抗混乱

	maxHp = 0;
	maxMp = 0;
	speed = 0;//速度
	attack = 0;	// 物攻
	fashuAttack = 0;	// 法攻
	recovery = 0;	//防御
	xiuWei = 0;	//同人物道行
*/
}

void SPet::UpdateSuitAttrs()
{
	suitSkills.clear();
	// sCItemCfgManager.GetSuitAttr(equips, suitSkills);
}

void SPet::GetChongShengCost(MultiCost& allCost)
{
	uint64 sumExp = exp;

	CPetCfgManager& pmgr = sCPetCfgManager;
	CHeroCfgManager& hmgr = sCHeroCfgManager;
	SPetBasicData* pData = pmgr.GetPetCfg(id);
	if (pData == NULL)
		return;

	for (size_t i = 1; i < level; i++)
	{
		sumExp += pmgr.GetLevelUpExp(i);
	}

	static U16tU32Map itemExp;
	static uint32 minExp = 100000;
	static SCostData minCost;
	if (itemExp.size() == 0)
	{
		CItemTemplateManager& imgr = SingletonItemManager::instance();
		vector<uint16>* vec = imgr.GetTypeItem(3);
		if (vec == NULL)
			return;
		for (uint8 i = 0; i < vec->size(); ++i)
		{
			uint16 itemId = (*vec)[i];
			SItemTemplate *pItem = imgr.GetItem(itemId);
			if (pItem == NULL)
				continue;
			itemExp[itemId] = pItem->subValue;
			if (minExp > pItem->subValue)
			{
				minExp = pItem->subValue;
				minCost.costType = itemId;
				minCost.costValue = 1;
			}
		}
	}

	for (U16tU32Map::reverse_iterator it = itemExp.rbegin(); it != itemExp.rend(); ++it)
	{
		SCostData cost;
		cost.costType = it->first;
		cost.costValue = sumExp / it->second;
		sumExp -= cost.costValue * it->second;
		if (cost.costValue > 0)
			MergeSigleCost(allCost, cost);
		if (sumExp == 0)
			break;
		if (sumExp <= minExp)
		{
			MergeSigleCost(allCost, minCost);
			break;
		}
	}

	for (size_t i = 1; i <= breakLevel; i++)
	{
		MultiCost* costs = hmgr.GetBreakCost(pData->quality, i);
		if (costs == NULL)
			continue;
		MergeMultiCost(allCost, *costs);
	}
	XiuLianCfg* xcfg = NULL;
	for (size_t i = 1; i <= xiuLianLevel; i++)
	{
		xcfg = hmgr.GetXiuLianCfg(i);
		if (xcfg == NULL)
			continue;
		MergeMultiCost(allCost, xcfg->costs);
	}
	SCostData cost;
	cost.costType = 853;
	cost.costValue = 0;
	for (U8tU16MapIt uit = curXiuLianCnts.begin(); uit != curXiuLianCnts.end(); ++uit)
	{
		cost.costValue += uit->second;
	}

	if (xcfg == NULL)
	{
		MergeSigleCost(allCost, cost);
		return;
	}
	cost.costValue += xcfg->sumCnt * 4;
	MergeSigleCost(allCost, cost);
}














