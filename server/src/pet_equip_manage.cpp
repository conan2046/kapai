#include "pet_equip_manage.h"
#include "init.h"
#include "award_manager.h"
#include "pet.h"
#include "utility.h"
#include "user.h"
#include "script_call.h"
#include "item.h"
#include "singleton.h"
#include "mission_manager.h"
#include <fstream>

extern const char *gConfigFile;

uint16 CItemCfgManager::CfgFBMaxCnt = 0;
uint16 CItemCfgManager::CfgFBStartCnt = 0;
uint16 CItemCfgManager::CfgFBAddSec = 0;
uint16 CItemCfgManager::CfgMaxJlLv = 0;

uint8 QiangHuaCfg::GetRatioLevel()
{
	uint32 curNum = Random(0, ratioSum);
	for (U8tU16MapIt it = ratio.begin(); it != ratio.end(); ++it)
	{
		if (curNum <= it->second)
			return it->first;
	}
	return 0;
}

void WearEquipSuit::MakeQHDSMsg(CNetMessage& msg, uint8 type/* = 0*/)
{
	uint16 pos = msg.GetDataLen();
	uint8 size = 0;
	msg << size;
	for (QHDSAttrMapIt it = qhdsAttr.begin(); it != qhdsAttr.end(); ++it)
	{
		if (type == 1 && it->first > EST_SHENZHU)
			continue;
		else if (type == 2 && it->first < EST_SHENZHU)
			continue;
		size++;
		QHDSAttr& qhds = it->second;
		msg << it->first << qhds.curLv;
	}
	msg.WriteData(pos, &size, sizeof(size));
}

uint32 WearEquipSuit::GetOtherFaBaoId(uint8 curPos)
{
	if (curPos == 5)
		return wearEquips[6];
	else if (curPos == 6)
		return wearEquips[5];

	return 0;
}

uint32 WearEquipSuit::GetFaBaoId(uint8 curPos)
{
	if (curPos == 5 || curPos == 6)
		return wearEquips[curPos];

	return 0;
}

QHDSAttr* WearEquipSuit::GetQHDSAttr(uint8 type)
{
	QHDSAttrMapIt it = qhdsAttr.find(type);
	if (it == qhdsAttr.end())
		return NULL;
	return &it->second;
}

void WearEquipSuit::CalcAttr(CEquipManeger& mgr)
{
	sumAttr.clear();
	// 装备与法宝
	for (size_t i = 1; i <= 6; i++)
	{
		switch (i)
		{
		case 1:
		case 2:
		case 3:
		case 4:
		{
			uint32 eid = wearEquips[i];
			CEquip* equip = mgr.GetEqiup(eid);
			if (equip == NULL)
				break;

			AddToAttrList(sumAttr, equip->baseAttr);
			MergeAttrList(sumAttr, equip->qhAttr);
			MergeAttrList(sumAttr, equip->jlAttr);
			MergeAttrList(sumAttr, equip->jxAttr);
			MergeAttrList(sumAttr, equip->szAttr);
		}
		break;

		case 5:
		case 6:
		{
			uint32 fid = wearEquips[i];
			FaBao* fabao = mgr.GetFaBao(fid);
			if (fabao == NULL)
				break;

			AddToAttrList(sumAttr, fabao->attr);
			AddToAttrList(sumAttr, fabao->qhAttr);
			MergeAttrList(sumAttr, fabao->jlAttr);
		}
		break;
		}
	}

	// 套装
	QHDSAttrMap qhdsAttr;
	for (SuitMapIt it = suitAttrs.begin(); it != suitAttrs.end(); ++it)
	{
		SuitAttr& sattr = it->second;
		U8MultiAttrMap& armap = sattr.cntAttrs;
		for (U8MultiAttrMapIt ait = armap.begin(); ait != armap.end(); ++ait)
		{
			MergeAttrList(sumAttr, ait->second);
		}
		for (map<uint8, SSkillData>::iterator sit = sattr.cntSkill.begin(); sit != sattr.cntSkill.end(); ++sit)
		{
			skill.push_back(sit->second);
		}
	}

	// 强化大师
	for (QHDSAttrMapIt it = qhdsAttr.begin(); it != qhdsAttr.end(); ++it)
	{
		QHDSAttr& qattr = it->second;
		MergeAttrList(sumAttr, qattr.attrs);
	}
}

CItemCfgManager::CItemCfgManager()
	: m_fbqhMax(0)
	, m_fbjlMax(0)
{
}

CItemCfgManager::~CItemCfgManager()
{
}

bool CItemCfgManager::InitAllCfg()
{
	return InitEquipCfg()
		&& InitComposeCfg()
		&& InitSuitAttrCfg()
		&& InitJingLianCfg()
		&& InitJueXingCfg()
		&& InitQiangHuaCfg()
		&& InitShenZhuCfg()
		&& InitFaBaoCfg()
		&& InitQiangHuaDaShiCfg();
}

// 基础信息
bool CItemCfgManager::InitEquipCfg()
{
	const string file = "equip.json";
	//                            0    1        2       3        4         5      6         7          8         9
	const char* titleArrs[] = { "id", "name", "part", "suit", "quality", "pic", "des", "item_from", "attr", "atrr_qianghua",
		//         10               11             12               13
			"attr_jinglian", "attr_juexing", "attr_shenzhu", "shenzhu_cost" };
	const int typeArrs[] = { 0, 1, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CEquipCfgMgr::InitEquipCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		CEquipCfg cfg;
		cfg.id = data[titleArrs[0]].GetInt();
		cfg.name = data[titleArrs[1]].GetString();
		cfg.part = data[titleArrs[2]].GetInt();
		cfg.suit = data[titleArrs[3]].GetInt();
		cfg.quality = data[titleArrs[4]].GetInt();
		cfg.szCost = data[titleArrs[13]].GetInt();
		ReadSingleAttr(data[titleArrs[8]], cfg.baseAttr);
		ReadMultiAttr(data[titleArrs[9]], cfg.qhAttr);
		ReadMultiAttr(data[titleArrs[10]], cfg.jlAttr);
		ReadMultiAttr(data[titleArrs[11]], cfg.jxAttr);
		ReadMultiAttr(data[titleArrs[12]], cfg.szAttr);
		m_equipCfgs[cfg.id] = cfg;
	}
	return true;
}

// 合成配置
bool CItemCfgManager::InitComposeCfg()
{
	{
		const string file = "hecheng.json";
		//                            0        1        2
		const char* titleArrs[] = { "type", "item", "target" };
		const int typeArrs[] = { 0, 2, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CItemCfgManager::InitComposeCfg >> LoadJosnValue error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			ComposeCfg cfg;
			const rapidjson::Value &data = _para[i];
			uint8 type = data[titleArrs[0]].GetInt();
			ReadMultiCost(data[titleArrs[1]], cfg.costs);
			if (cfg.costs.empty())
				continue;
			ReadSingleAward(data[titleArrs[2]], cfg.tar);
			SCostData& fc = cfg.costs[0];
			uint16 id = fc.costType < HDAT_MONEY ? fc.costType : fc.costValue;
			if (type == CPT_FABAO_HC)
				id = cfg.tar.typeId;
			else if (type == CPT_EQUIP_FJ || type == CPT_EQUIP_CS || type == CPT_FABAO_FJ)
				id = fc.typeId;
			ComposeCfgMap* ccMap = GetComposeCfgMap(type);
			if (ccMap != NULL)
				(*ccMap)[id] = cfg;
			else
			{
				ComposeCfgMap tmp;
				tmp[id] = cfg;
				m_typeComposeCfgs[type] = tmp;
			}
			if (type == CPT_FABAO_HC)
			{
				ComposeIds cids;
				for (uint8 j = 0; j < cfg.costs.size(); ++j)
				{
					cids.push_back(cfg.costs[j].costType);
				}
				m_composeIdCfgs[id] = cids;
			}
		}
	}

	{
		const string file = "fabao_looting.json";
		std::ifstream lootingFile(("./json/" + file).c_str());
		if (!lootingFile.good()
			&& gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) == "1")
		{
			cout << "[local] CItemCfgManager::InitComposeCfg: " << file
				<< " is unavailable; fabao looting is disabled until its source table is supplied" << endl;
			return true;
		}
		lootingFile.close();
		//                            0     1       2
		const char* titleArrs[] = { "id", "item", "ratio" };
		const int typeArrs[] = { 0, 0, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CItemCfgManager::InitComposeCfg >> LoadJosnValue fabao_looting.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			uint16 id = data[titleArrs[1]].GetInt();
			uint16 raito = data[titleArrs[2]].GetInt();
			m_faBaoSS[id] = raito;
		}
	}
	return true;
}


// 套装属性值
bool CItemCfgManager::InitSuitAttrCfg()
{
	const string file = "suit.json";
	//                            0      1
	const char* titleArrs[] = { "id", "suit" };
	const int typeArrs[] = { 0, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitSuitAttrCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint8 id = data[titleArrs[0]].GetInt();
		const rapidjson::Value &attrs = data[titleArrs[1]];
		// [[1,1,1000]],[[1,1,1000],[1,2,500]],[[2,4062,1]]
		if (!attrs.IsArray())
		{
			cout << "CItemCfgManager::InitComposeCfg >> attrs.IsArray error row " << i << endl;
			return false;
		}
		SuitAttr sa;
		for (uint32 si = 0; si < attrs.Size(); si++)
		{
			// [[1,1,1000],[1,2,500]]
			const rapidjson::Value &attr = attrs[si];
			if (!attr.IsArray())
			{
				cout << "CItemCfgManager::InitComposeCfg >> attr.IsArray error idx " << si << endl;
				return false;
			}
			MultiAttr mAttr;
			SSkillData skill;
			for (uint32 ai = 0; ai < attr.Size(); ++ai)
			{
				// [1,1,1000]
				const rapidjson::Value &sattr = attr[ai];
				if (!sattr.IsArray() || sattr.Size() != 3)
				{
					cout << "CItemCfgManager::InitComposeCfg >> sattr.IsArray error row " << i << " idx " << si << endl;
					return false;
				}
				uint8 atype = sattr[0].GetInt();
				switch (atype)
				{
				case 1:
				{
					SAttrData sad;
					sad.attrType = sattr[1].GetInt();
					sad.attrValue = sattr[2].GetInt();
					mAttr.push_back(sad);
				}
				break;

				case 2:
				{
					skill.id = sattr[1].GetInt();
					skill.level = sattr[2].GetInt();
				}
				break;
				}
			}

			if (mAttr.size() > 0)
				sa.cntAttrs[si + 2] = mAttr;
			if (skill.id != 0)
				sa.cntSkill[si + 2] = skill;
		}
		m_Suits[id] = sa;
	}
	return true;
}

// 精炼配置
bool CItemCfgManager::InitJingLianCfg()
{
	const string file = "equip_jinglian.json";
	//                            0      1
	const char* titleArrs[] = { "level", "exp" };
	const int typeArrs[] = { 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitJingLianCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint8 level = data[titleArrs[0]].GetInt();
		uint32 exp = data[titleArrs[1]].GetInt();
		m_jlNeedExp[level] = exp;
		if (level > CfgMaxJlLv)
			CfgMaxJlLv = level;
	}
	return true;
}

// 觉醒配置
bool CItemCfgManager::InitJueXingCfg()
{
	const string file = "equip_juexing.json";
	//                            0         1      2          3
	const char* titleArrs[] = { "level", "name", "cost", "attr_add" };
	const int typeArrs[] = { 0, 1, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitJueXingCfg >> LoadJosnValue error " << endl;
		return false;
	}
	U8MultiAttrMap sumAttr;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		JueXingCfg cfg;
		const rapidjson::Value &data = _para[i];
		uint8 level = data[titleArrs[0]].GetInt();
		cfg.name = data[titleArrs[1]].GetString();
		ReadMultiCost(data[titleArrs[2]], cfg.cost);
		const rapidjson::Value &attrAdd = data[titleArrs[3]];
		// [1,10,5],[2,11,5],[3,12,5],[4,13,5]
		for (uint32 ai = 0; ai < attrAdd.Size(); ++ai)
		{
			// [1,10,5]
			const rapidjson::Value &singleAttr = attrAdd[ai];
			if (!singleAttr.IsArray() || singleAttr.Size() != 3)
			{
				continue;
			}
			uint8 pos = singleAttr[0].GetInt();
			SAttrData attr;
			MultiAttr sum;
			attr.attrType = singleAttr[1].GetInt();
			attr.attrValue = singleAttr[2].GetInt();
			cfg.curAddAttr[pos] = attr;
			sum.push_back(attr);
			U8MultiAttrMapIt it = sumAttr.find(pos);
			if (it != sumAttr.end())
			{
				MergeAttrList(it->second, sum);
			}
			else
			{
				sumAttr[pos] = sum;
			}
		}
		cfg.subAddAttr = sumAttr;
		m_jxCfgs[level] = cfg;
	}
	return true;
}

// 强化配置
bool CItemCfgManager::InitQiangHuaCfg()
{
	const string file = "equip_qianghua.json";
	//                            0      1      2
	const char* titleArrs[] = { "level", "cost", "crit" };
	const int typeArrs[] = { 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitQiangHuaCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		QiangHuaCfg cfg;
		uint16 level = data[titleArrs[0]].GetInt();
		const rapidjson::Value &cost = data[titleArrs[1]];
		if (cost.Size() != 3)
		{
			cout << ">> CItemCfgManager::InitQiangHuaCfg cost cfg size error , i=" << i << endl;
			continue;
		}
		cfg.cost.costType = cost[0].GetInt();
		cfg.cost.costValue = cost[2].GetInt();
		const rapidjson::Value &ratioArr = data[titleArrs[2]];
		// [2,20],[3,10],[5,10]
		for (uint32 ai = 0; ai < ratioArr.Size(); ++ai)
		{
			// [2,20]
			const rapidjson::Value &singleRatio = ratioArr[ai];
			if (!singleRatio.IsArray() || singleRatio.Size() != 2)
			{
				continue;
			}
			uint8 levelNum = singleRatio[0].GetInt();
			cfg.ratioSum += singleRatio[1].GetInt();
			cfg.ratio[levelNum] = cfg.ratioSum;
		}
		m_qhCfgs[level] = cfg;
	}
	return true;
}

// 神铸配置
bool CItemCfgManager::InitShenZhuCfg()
{
	const string file = "equip_shenzhu.json";
	//                             0       1         2           3           4
	const char* titleArrs[] = { "level", "name", "cost_count", "money", "skill_add" };
	const int typeArrs[] = { 0, 1, 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitShenZhuCfg >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		ShenZhuCfg cfg;
		const rapidjson::Value &data = _para[i];
		uint8 level = data[titleArrs[0]].GetInt();
		cfg.name = data[titleArrs[1]].GetString();
		cfg.itemNum = data[titleArrs[2]].GetInt();
		ReadMultiCost(data[titleArrs[3]], cfg.cost);
		const rapidjson::Value &skillAdd = data[titleArrs[4]];
		// [1,4032,1],[2,4022,1],[3,4012,1],[4,4052,1]
		for (uint32 ai = 0; ai < skillAdd.Size(); ++ai)
		{
			// [1,4032,1]
			const rapidjson::Value &singeSkill = skillAdd[ai];
			if (!singeSkill.IsArray() || singeSkill.Size() != 3)
			{
				continue;
			}
			uint8 pos = singeSkill[0].GetInt();
			SSkillData skill;
			skill.id = singeSkill[1].GetInt();
			skill.level = singeSkill[2].GetInt();
			cfg.posSkill[pos] = skill;
		}
		m_szCfgs[level] = cfg;
	}
	return true;
}

// 法宝
bool CItemCfgManager::InitFaBaoCfg()
{
	{
		const string file = "fabao.json";
		//                             0     1         2       3           4                5            6       7
		const char* titleArrs[] = { "id", "name", "quality", "attr", "atrr_qianghua", "attr_jinglian", "exp", "equip" };
		const int typeArrs[] = { 0, 1, 0, 2, 2, 2, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CItemCfgManager::InitFaBaoCfg >> LoadJosnValue fabao.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			FaBaoCfg cfg;
			const rapidjson::Value &data = _para[i];
			cfg.id = data[titleArrs[0]].GetInt();
			cfg.name = data[titleArrs[1]].GetString();
			cfg.quality = data[titleArrs[2]].GetInt();
			cfg.exp = data[titleArrs[6]].GetInt();
			int equip = data[titleArrs[7]].GetInt();
			ReadSingleAttr(data[titleArrs[3]], cfg.attr);
			ReadSingleAttr(data[titleArrs[4]], cfg.qhAttr);
			ReadMultiAttr(data[titleArrs[5]], cfg.jlAttr);
			m_fbCfg[cfg.id] = cfg;
			if (equip == 0)
				m_faBaoJY[cfg.id] = cfg.exp;
		}
	}

	{
		const string file = "fabao_qianghua.json";
		//                             0      1
		const char* titleArrs[] = { "level", "exp" };
		const int typeArrs[] = { 0, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CItemCfgManager::InitFaBaoCfg >> LoadJosnValue fabao_qianghua.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			uint8 lv = data[titleArrs[0]].GetInt();
			uint32 exp = data[titleArrs[1]].GetInt();
			m_fbQhCfg[lv] = exp;
			m_fbqhMax = m_fbqhMax < lv ? lv : m_fbqhMax;
		}
	}

	{
		const string file = "fabao_jinglian.json";
		//                             0       1
		const char* titleArrs[] = { "level", "cost" };
		const int typeArrs[] = { 0, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CItemCfgManager::InitFaBaoCfg >> LoadJosnValue fabao_jinglian.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			uint8 lv = data[titleArrs[0]].GetInt();
			MultiCost costs;
			ReadMultiCost(data[titleArrs[1]], costs);
			m_fbJlCfg[lv] = costs;
			m_fbjlMax = m_fbjlMax < lv ? lv : m_fbjlMax;
		}
	}
	return true;
}

// 强化大师
bool CItemCfgManager::InitQiangHuaDaShiCfg()
{
	const string file = "master.json";
	//                             0       1         2          3
	const char* titleArrs[] = { "type", "level", "condition", "attr" };
	const int typeArrs[] = { 0, 0, 0, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CItemCfgManager::InitQiangHuaDaShiCfg >> LoadJosnValue master.json error " << endl;
		return false;
	}

	//uint16 cndEnd = 1;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		QiangHuaDaShiCfg cfg;
		uint8 type = data[titleArrs[0]].GetInt();
		cfg.lv = data[titleArrs[1]].GetInt();
		cfg.cndBegin = data[titleArrs[2]].GetInt();
		ReadMultiAttr(data[titleArrs[3]], cfg.attrs);
		QHDSCfgMap* qmap = GetQHDSMap(type);
		if (qmap != NULL)
			(*qmap)[cfg.lv] = cfg;
		else
		{
			QHDSCfgMap tmp;
			tmp[cfg.lv] = cfg;
			m_qhdsCfg[type] = tmp;
		}
	}
	return true;
}

ComposeCfgMap* CItemCfgManager::GetComposeCfgMap(uint8 type)
{
	TypeComposeCfgMapIt it = m_typeComposeCfgs.find(type);
	if (it == m_typeComposeCfgs.end())
		return NULL;
	return &it->second;
}

// 获取配置
ComposeCfg* CItemCfgManager::GetComposeCfg(uint8 type, uint16 id)
{
	ComposeCfgMap* cmap = GetComposeCfgMap(type);
	if (cmap == NULL)
		return NULL;

	ComposeCfgMapIt cit = cmap->find(id);
	if (cit == cmap->end())
		return NULL;
	return &cit->second;
}

// 获取套装属性
SuitAttr* CItemCfgManager::GetSuitAttr(uint8 type)
{
	SuitMapIt it = m_Suits.find(type);
	if (it == m_Suits.end())
		return NULL;

	return &it->second;
}

// 获取装备配置
CEquipCfg* CItemCfgManager::GetEquipCfg(uint16 id)
{
	EquipCfgMapIt it = m_equipCfgs.find(id);
	if (it != m_equipCfgs.end())
		return &it->second;

	return NULL;
}

CEquip::CEquip()
	: uid(0)
	, id(0)
	, wpos(0)
	, fpos(0)
	, curExp(0)
	, strongCost(0)
{
	strongLevel.clear();
	qhAttr.clear();
	jlAttr.clear();
	jxAttr.clear();
	szAttr.clear();
}

CEquip::~CEquip()
{

}

// 属性初始化
bool CEquip::InitAttr()
{
	CItemCfgManager& emgr = sCItemCfgManager;
	CEquipCfg* cfg = emgr.GetEquipCfg(id);
	if (cfg == NULL)
		return false;

	wpos = cfg->part;
	baseAttr = cfg->baseAttr;
	// 计算属性
	qhAttr.clear();
	jlAttr.clear();
	jxAttr.clear();
	szAttr.clear();
	for (U8tU16MapIt lIt = strongLevel.begin(); lIt != strongLevel.end(); ++lIt)
	{
		MultiAttr* cfgAttr = NULL;
		MultiAttr* attr = NULL;
		MultiAttr* addAttr = NULL;
		switch (lIt->first)
		{
		case EST_QIANGHUA:
			cfgAttr = &cfg->qhAttr;
			attr = &qhAttr;
			break;

		case EST_JINGLIAN:
			cfgAttr = &cfg->jlAttr;
			attr = &jlAttr;
			if (lIt->second > CItemCfgManager::CfgMaxJlLv)
				lIt->second = CItemCfgManager::CfgMaxJlLv;
			break;

		case EST_JUEXING:
		{
			cfgAttr = &cfg->jxAttr;
			attr = &jxAttr;

			JueXingCfg* jcfg = emgr.GetJueXinCfg(lIt->second);
			if (jcfg != NULL)
			{
				U8MultiAttrMapIt jsIt = jcfg->subAddAttr.find(wpos);
				if (jsIt != jcfg->subAddAttr.end())
				{
					addAttr = &jsIt->second;
				}
			}
			break;
		}

		case EST_SHENZHU:
			cfgAttr = &cfg->szAttr;
			attr = &szAttr;
			break;

		default:
			break;
		}

		if (attr == NULL || cfgAttr == NULL)
			continue;

		attr->clear();
		for (uint8 ai = 0; ai < cfgAttr->size(); ++ai)
		{
			SAttrData adata = (*cfgAttr)[ai];
			adata.attrValue *= lIt->second;
			attr->push_back(adata);
		}

		if (addAttr != NULL)
			MergeAttrList(*attr, *addAttr);
	}
	return true;
}

void CEquip::AddAttr(int type, const SAttrData& tv)
{

}

int CEquip::SaveData(uint8 *outBuf, uint32& pos, uint32 maxLen)
{
	 CopyDataToBuf((char *)outBuf, &uid, sizeof(uid), pos, maxLen);
	 CopyDataToBuf((char *)outBuf, &id, sizeof(id), pos, maxLen);
	 CopyDataToBuf((char *)outBuf, &curExp, sizeof(curExp), pos, maxLen);
	 CopyDataToBuf((char *)outBuf, &strongCost, sizeof(strongCost), pos, maxLen);
	 outBuf[pos++] = fpos;
	 outBuf[pos++] = strongLevel.size();
	 for (U8tU16MapIt it = strongLevel.begin(); it != strongLevel.end(); ++it)
	 {
		 outBuf[pos++] = it->first;
		 CopyDataToBuf((char *)outBuf, &it->second, sizeof(it->second), pos, maxLen);
	 }
	return pos;
}

int CEquip::LoadData(uint8 *intBuf, uint32& pos, uint32 maxLen)
{
	 ReadDataFromBuf((char *)intBuf, &uid, sizeof(uid), pos, maxLen);
	 ReadDataFromBuf((char *)intBuf, &id, sizeof(id), pos, maxLen);
	 ReadDataFromBuf((char *)intBuf, &curExp, sizeof(curExp), pos, maxLen);
	 ReadDataFromBuf((char *)intBuf, &strongCost, sizeof(strongCost), pos, maxLen);
	 fpos = intBuf[pos++];
	 uint8 size = intBuf[pos++];
	 for (size_t bi = 0; bi < size; ++bi)
	 {
		 uint8 type = intBuf[pos++];
		 uint16 level;
		 ReadDataFromBuf((char *)intBuf, &level, sizeof(level), pos, maxLen);
		 strongLevel[type] = level;
	 }
	 InitAttr();
	 return pos;
}

void CEquip::PeekAttrs(AttrSumMap& sums)
{
}

void CEquip::MakeMsg(CNetMessage &msg)
{
	 msg << uid << id << fpos << curExp;

	 msg << (uint8)strongLevel.size();
	 for (U8tU16MapIt it = strongLevel.begin(); it != strongLevel.end(); ++it)
	 {
		 msg << it->first << it->second;
	 }

	 baseAttr.MakeMsg(msg);
	 msg << (uint8)EST_QIANGHUA;
	 MakeMultiAttrMsg(qhAttr, msg);
	 msg << (uint8)EST_JINGLIAN;
	 MakeMultiAttrMsg(jlAttr, msg);
	 msg << (uint8)EST_JUEXING;
	 MakeMultiAttrMsg(jxAttr, msg);
	 msg << (uint8)EST_SHENZHU;
	 MakeMultiAttrMsg(szAttr, msg);
}

uint16 CEquip::GetYangChengLevel(uint8 type)
{
	U8tU16MapIt it = strongLevel.find(type);
	if (it != strongLevel.end())
		return it->second;

	return 0;
}


void CEquip::GetChongSheng(MultiCost& costs, uint8 sp)
{
	static uint16 qhat = 0;
	static U16tU32Map itemExp;
	static uint16 minExp = 10000;
	CItemCfgManager& cMgr = sCItemCfgManager;
	CHeroCfgManager& hMgr = sCHeroCfgManager;
	CItemTemplateManager& iMgr = SingletonItemManager::instance();
	if (itemExp.size() == 0)
	{
		vector<uint16>* vec = iMgr.GetTypeItem(4);
		if (vec == NULL)
			return;
		for (uint8 i = 0; i < vec->size(); ++i)
		{
			uint16 itemId = (*vec)[i];
			SItemTemplate *pItem = iMgr.GetItem(itemId);
			if (pItem == NULL)
				return;
			itemExp[itemId] = pItem->subValue;
			if (minExp > pItem->subValue)
			{
				minExp = pItem->subValue;
			}
		}
	}

	if (qhat == 0)
	{
		QiangHuaCfg* cfg = cMgr.GetQiangHuaCfg(1);
		if (cfg == NULL)
			return;
		qhat = cfg->cost.costType;
	}
	QiangHuaCfg* cfg = cMgr.GetQiangHuaCfg(1);
	CEquipCfg* ecfg = cMgr.GetEquipCfg(id);
	if (ecfg == NULL)
		return;
	double jxRatio = hMgr.GetJingLianRatio(ecfg->quality);
	if (cfg == NULL)
	{
		return;
	}
	for (U8tU16MapIt it = strongLevel.begin(); it != strongLevel.end(); ++it)
	{
		switch (it->first)
		{
		case EST_QIANGHUA:
		{
			SCostData cost;
			cost.costType = qhat;
			cost.costValue = strongCost;
			MergeSigleCost(costs, cost);
		}
		break;
		case EST_JINGLIAN:
		{
			uint32 sumExp = curExp;
			for (size_t i = 0; i < it->second; i++)
			{
				sumExp += cMgr.GetJingLianExp(i) * jxRatio;
			}
			for (U16tU32MapRit iit = itemExp.rbegin(); iit != itemExp.rend(); ++iit)
			{
				SCostData cost;
				cost.costType = iit->first;
				cost.costValue = sumExp / iit->second;
				if (cost.costValue > 0)
				{
					sumExp -= cost.costValue * iit->second;
					if (cost.costValue == minExp && sumExp > 0)
					{
						sumExp = 0;
						cost.costValue++;
					}
					MergeSigleCost(costs, cost);
				}
				if (sumExp == 0)
					break;
			}
		}
		break;
		case EST_JUEXING:
		{
			for (size_t i = 1; i <= it->second; i++)
			{
				JueXingCfg* cfg = cMgr.GetJueXinCfg(i);
				if (cfg == NULL)
					break;
				MergeMultiCost(costs, cfg->cost);
			}
		}
		break;
		case EST_SHENZHU:
		{
			SCostData cost;
			cost.costType = ecfg->szCost;
			cost.costValue = 0;
			for (size_t i = 1; i <= it->second; i++)
			{
				ShenZhuCfg* cfg = cMgr.GetShenZhuCfg(i);
				if (cfg == NULL)
					break;
				cost.costValue += cfg->itemNum;
				MergeMultiCost(costs, cfg->cost);
			}
			MergeSigleCost(costs, cost);
		}
		break;
		}
	}

	if (sp == 1)
	{
		ComposeCfg* cfg = cMgr.GetComposeCfg(CPT_EQUIP_CS, id);
		if (cfg != NULL)
		{
			SCostData cost;
			cost.costType = cfg->tar.type;
			cost.typeId = cfg->tar.typeId;
			cost.costValue = cfg->tar.num;
			MergeSigleCost(costs, cost);
		}
	}
	else if (sp == 2)
	{
		ComposeCfg* cfg = cMgr.GetComposeCfg(CPT_EQUIP_FJ, id);
		if (cfg != NULL)
		{
			SCostData cost;
			cost.costType = cfg->tar.type;
			cost.typeId = cfg->tar.typeId;
			cost.costValue = cfg->tar.num;
			MergeSigleCost(costs, cost);
		}
	}
}

const char* CItemCfgManager::GetPosName(uint8 pos)
{
	switch (pos)
	{
	case 1:
		return LANGUAGE_ZQX_0054;
	case 2:
		return LANGUAGE_ZQX_0055;
	case 3:
		return LANGUAGE_ZQX_0056;
	case 4:
		return LANGUAGE_ZQX_0057;
	case 5:
		return LANGUAGE_ZQX_0058;
	case 6:
		return LANGUAGE_ZQX_0059;
	default:
		break;
	}
	return "";
}

const char* CItemCfgManager::GetEquipName(uint16 id)
{
	CEquipCfg* cfg = GetEquipCfg(id);
	if (cfg == NULL)
		return "";

	return cfg->name.c_str();
}

int CItemCfgManager::GetEquipColor(uint16 id)
{
	CEquipCfg* cfg = GetEquipCfg(id);
	if (cfg == NULL)
		return 4;

	return GetQualityColor(cfg->quality);
}

void CItemCfgManager::GetSuitAttr(uint16 type, uint16 cnt, skillVec& skills)
{
	// for (uint16 i = 1; i <= cnt; ++i)
	// {
		// suitSkill sskill;
		// sskill.first = MAKEUINT32(type, i);
		// PESAttrsIt it = m_suitAttrCfg.find(sskill.first);
		// if (it == m_suitAttrCfg.end())
			// continue;
		// sskill.second = it->second;
		// skills.push_back(sskill);
	// }
}

// 强化配置
QiangHuaCfg* CItemCfgManager::GetQiangHuaCfg(uint16 level)
{
	QiangHuaCfgMapIt it = m_qhCfgs.find(level);
	if (it == m_qhCfgs.end())
		return NULL;

	return &it->second;
}

// 精炼需要经验
uint32 CItemCfgManager::GetJingLianExp(uint16 level)
{
	U16tU32MapIt it = m_jlNeedExp.find(level);
	if (it == m_jlNeedExp.end())
		return 0;

	return it->second;
}

// 觉醒配置
JueXingCfg* CItemCfgManager::GetJueXinCfg(uint16 level)
{

	JueXingCfgMapIt it = m_jxCfgs.find(level);
	if (it == m_jxCfgs.end())
		return NULL;

	return &it->second;
}

// 神铸配置
ShenZhuCfg* CItemCfgManager::GetShenZhuCfg(uint16 level)
{
	ShenZhuCfgMapIt it = m_szCfgs.find(level);
	if (it == m_szCfgs.end())
		return NULL;

	return &it->second;
}

FaBaoCfg * CItemCfgManager::GetFaBaoCfg(uint16 tid)
{
	FaBaoCfgMapIt it = m_fbCfg.find(tid);
	if (it == m_fbCfg.end())
		return NULL;

	return &it->second;
}

string CItemCfgManager::GetEquipColorName(uint16 tid)
{
	CEquipCfg* cfg = GetEquipCfg(tid);
	if (cfg == NULL)
		return NULL;

	return MakeColorString(cfg->quality, cfg->name);
}

string CItemCfgManager::GetFaBaoColorName(uint16 tid)
{
	FaBaoCfg* fcfg = GetFaBaoCfg(tid);
	if (fcfg == NULL)
		return NULL;

	return MakeColorString(fcfg->quality, fcfg->name);
}

uint32 CItemCfgManager::GetFaBaoExp(uint16 level)
{
	U8tU32MapIt it = m_fbQhCfg.find(level);
	if (it == m_fbQhCfg.end())
		return 0;

	return it->second;
}

ComposeIds* CItemCfgManager::GetFaBaoComposeIds(uint16 id)
{
	ComposeIdMapIt it = m_composeIdCfgs.find(id);
	if (it == m_composeIdCfgs.end())
		return 0;

	return &it->second;
}

uint16 CItemCfgManager::GetFaBaoSouSuo(uint16 id)
{
	U16tU16MapIt it = m_faBaoSS.find(id);
	if (it == m_faBaoSS.end())
		return 0;

	return it->second;
}


MultiCost * CItemCfgManager::GetFaBaoJlCost(uint16 level)
{
	MultiCostMapIt it = m_fbJlCfg.find(level);
	if (it == m_fbJlCfg.end())
		return NULL;

	return &it->second;
}

QHDSCfgMap* CItemCfgManager::GetQHDSMap(uint8 type)
{
	TypeQHDSCfgMapIt it = m_qhdsCfg.find(type);
	if (it == m_qhdsCfg.end())
		return NULL;

	return &it->second;
}

QiangHuaDaShiCfg* CItemCfgManager::GetQHDSCfg(uint8 type, uint8 lv)
{
	QHDSCfgMap* cfgMap = GetQHDSMap(type);
	if (cfgMap == NULL)
		return NULL;

	QHDSCfgMapIt it = cfgMap->find(lv);
	if (it == cfgMap->end())
		return NULL;

	return &it->second;
}

QiangHuaDaShiCfg* CItemCfgManager::GetQhdsCfg(QHDSCfgMap* qmap, uint8 lv)
{
	QiangHuaDaShiCfg* realCfg = NULL;
	for (QHDSCfgMapIt it = qmap->begin(); it != qmap->end(); ++it)
	{
		QiangHuaDaShiCfg& cfg = it->second;
		if (lv < cfg.cndBegin)
			break;
		realCfg = &cfg;
	}
	return realCfg;
}


void FaBao::MakeMsg(CNetMessage &msg)
{
	msg << uid << id << fpos << wpos << exp;
	msg << (uint8)ycLv.size();
	for (U8tU8MapIt it = ycLv.begin(); it != ycLv.end(); it++)
	{
		msg << it->first << it->second;
	}
}

bool FaBao::InitAttr()
{
	FaBaoCfg* cfg = sCItemCfgManager.GetFaBaoCfg(id);
	if (cfg == NULL)
		return false;

	attr = cfg->attr;
	// 计算属性
	for (U8tU8MapIt lIt = ycLv.begin(); lIt != ycLv.end(); ++lIt)
	{
		switch (lIt->first)
		{
		case EST_FBQIANGHUA:
			qhAttr = cfg->qhAttr;
			qhAttr.attrValue *= lIt->second;
			break;

		case EST_FBJINGLIAN:
			jlAttr.clear();
			for (uint8 ai = 0; ai < cfg->jlAttr.size(); ++ai)
			{
				SAttrData adata = cfg->jlAttr[ai];
				adata.attrValue *= lIt->second;
				jlAttr.push_back(adata);
			}
			break;
		}

	}
	return true;
}

uint8 FaBao::GetYangChengLevel(uint8 type)
{
	U8tU8MapIt it = ycLv.find(type);
	if (it != ycLv.end())
		return it->second;

	return 0;
}

void FaBao::GetChongSheng(MultiCost& costs, uint8 sp)
{
	CItemCfgManager& mgr = sCItemCfgManager;
	CHeroCfgManager& hcfg = sCHeroCfgManager;
	FaBaoCfg* fcfg = mgr.GetFaBaoCfg(id);
	if (fcfg == NULL)
		return;
	double ratio = hcfg.GetFaBaoQiangHuaRatio(fcfg->quality);
	for (U8tU8MapIt it = ycLv.begin(); it != ycLv.end(); ++it)
	{
		uint16 curLevel = it->second;
		switch (it->first)
		{
		case EST_FBQIANGHUA:
		{
			uint32 sumExp = exp;
			for (size_t i = 1; i <= curLevel; i++)
				sumExp += mgr.GetFaBaoExp(i) * ratio;
			SCostData moneycost;
			moneycost.costType = HDAT_MONEY;
			moneycost.costValue = sumExp;
			MergeSigleCost(costs, moneycost);
			U16tU32Map& itemExp = mgr.GetFaBaoJY();
			static uint16 minExp = 10000;
			for (U16tU32MapRit it = itemExp.rbegin(); it != itemExp.rend(); ++it)
			{
				SCostData cost;
				cost.costType = HDAT_FaBao;
				cost.typeId = it->first;
				cost.costValue = sumExp / it->second;
				if (cost.costValue > 0)
				{
					sumExp -= cost.costValue * it->second;
					if (cost.costValue == minExp && sumExp > 0)
					{
						sumExp = 0;
						cost.costValue++;
					}
					MergeSigleCost(costs, cost);
				}
				if (sumExp == 0)
					break;
			}
			break;
		}
		case EST_FBJINGLIAN:
		{
			for (size_t i = 1; i <= curLevel; i++)
			{
				MultiCost* cost = mgr.GetFaBaoJlCost(i);
				if (cost != NULL)
					MergeMultiCost(costs, *cost);
			}
			break;
		}
		}
	}
	if (sp == 2)
	{
		ComposeCfg* cfg = mgr.GetComposeCfg(CPT_FABAO_FJ, id);
		if (cfg != NULL)
		{
			SCostData cost;
			cost.costType = cfg->tar.type;
			cost.typeId = cfg->tar.typeId;
			cost.costValue = cfg->tar.num;
			MergeSigleCost(costs, cost);
		}
	}
}

CEquipManeger::CEquipManeger()
	: m_faBaoCnt(CItemCfgManager::CfgFBStartCnt)
{
	WearEquipSuit wearEquips;
	m_formationEquips[1] = wearEquips;
	m_formationEquips[2] = wearEquips;
	m_formationEquips[3] = wearEquips;
	m_formationEquips[4] = wearEquips;
	m_formationEquips[5] = wearEquips;
	m_petEquips.clear();
	m_lastCntTime = GetSysTime();
}

CEquipManeger::~CEquipManeger()
{
	m_petEquips.clear();
	m_formationEquips.clear();
	m_allFaBao.clear();
}

void CEquipManeger::SaveData(string& outStr)
{
	uint8 hexData[1024 * 100];
	uint32 pos = 0;
	uint32 maxLen = 1024 * 100;
	uint16 size = m_petEquips.size();
	CopyDataToBuf((char *)hexData, &size, sizeof(size), pos, maxLen);
	for (EquipMapIt pit = m_petEquips.begin(); pit != m_petEquips.end(); ++pit)
	{
		CEquip& pet = pit->second;
		pet.SaveData(hexData, pos, maxLen);
	}

	size = m_allFaBao.size();
	CopyDataToBuf((char *)hexData, &size, sizeof(size), pos, maxLen);
	for (FaBaoMapIt pit = m_allFaBao.begin(); pit != m_allFaBao.end(); ++pit)
	{
		FaBao& fb = pit->second;
		CopyDataToBuf((char *)hexData, &fb.uid, sizeof(fb.uid), pos, maxLen);
		CopyDataToBuf((char *)hexData, &fb.id, sizeof(fb.id), pos, maxLen);
		CopyDataToBuf((char *)hexData, &fb.exp, sizeof(fb.exp), pos, maxLen);
		hexData[pos++] = fb.fpos;
		hexData[pos++] = fb.wpos;
		hexData[pos++] = fb.ycLv.size();
		for (U8tU8MapIt it = fb.ycLv.begin(); it != fb.ycLv.end(); ++it)
		{
			hexData[pos++] = it->first;
			hexData[pos++] = it->second;
		}
	}
	CopyDataToBuf((char *)hexData, &m_lastCntTime, sizeof(m_lastCntTime), pos, maxLen);
	CopyDataToBuf((char *)hexData, &m_faBaoCnt, sizeof(m_faBaoCnt), pos, maxLen);
	if (!Compress(hexData, pos, outStr))
		outStr.clear();
}

void CEquipManeger::LoadData(char* inStr)
{
	if (inStr == NULL || strlen(inStr) == 0)
		return;
	uint32 maxLen = 1024 * 100;
	uint8 hexData[1024 * 100];
	if (!UnCompress(inStr, hexData, maxLen))
	{
		return;
	}
	uint16 size = 0;
	uint32 pos = 0;
	ReadDataFromBuf((char *)hexData, &size, sizeof(size), pos, maxLen);
	for (uint16 pi = 0; pi < size; ++pi)
	{
		CEquip petEquip;
		petEquip.LoadData(hexData, pos, maxLen);
		m_petEquips.insert(make_pair(petEquip.uid, petEquip));
		AllWearEquipSuitMapIt it = m_formationEquips.find(petEquip.fpos);
		if (it != m_formationEquips.end())
		{
			WearEquipSuit& wearEquips = it->second;
			wearEquips.wearEquips[petEquip.wpos] = petEquip.uid;
		}
		else
		{
			WearEquipSuit wearEquips;
			wearEquips.wearEquips[petEquip.wpos] = petEquip.uid;
			m_formationEquips[petEquip.fpos] = wearEquips;
		}
	}
	ReadDataFromBuf((char *)hexData, &size, sizeof(size), pos, maxLen);
	for (uint16 pi = 0; pi < size; ++pi)
	{
		FaBao fb;
		ReadDataFromBuf((char *)hexData, &fb.uid, sizeof(fb.uid), pos, maxLen);
		ReadDataFromBuf((char *)hexData, &fb.id, sizeof(fb.id), pos, maxLen);
		ReadDataFromBuf((char *)hexData, &fb.exp, sizeof(fb.exp), pos, maxLen);
		fb.fpos = hexData[pos++];
		fb.wpos = hexData[pos++];
		uint8 lsize = hexData[pos++];
		for (size_t li = 0; li < lsize; li++)
		{
			uint8 type = hexData[pos++];
			uint8 lv = hexData[pos++];
			fb.ycLv[type] = lv;
		}
		fb.InitAttr();
		m_allFaBao[fb.uid] = fb;

		AllWearEquipSuitMapIt it = m_formationEquips.find(fb.fpos);
		if (it != m_formationEquips.end())
		{
			WearEquipSuit& wearEquips = it->second;
			wearEquips.wearEquips[fb.wpos] = fb.uid;
		}
		else
		{
			WearEquipSuit wearEquips;
			wearEquips.wearEquips[fb.wpos] = fb.uid;
			m_formationEquips[fb.fpos] = wearEquips;
		}
	}
	ReadDataFromBuf((char *)hexData, &m_lastCntTime, sizeof(m_lastCntTime), pos, maxLen);
	ReadDataFromBuf((char *)hexData, &m_faBaoCnt, sizeof(m_faBaoCnt), pos, maxLen);

	InitSuitAndQHDS();
}

void CEquipManeger::GetSuitSkills(uint8 fpos, vector<SSkillData> &skillList)
{
	WearEquipSuit* suit = GetWearEquipSuit(fpos);
	if (suit != NULL)
	{
		skillList = suit->skill;
		FormationEquipMap& emap = suit->wearEquips;
		CItemCfgManager& imgr = sCItemCfgManager;
		for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
		{
			if (eit->first > 4) continue;
			CEquip* equip = GetEqiup(eit->second);
			if (equip == NULL)
				continue;
			uint16 szLv = equip->GetYangChengLevel(EST_SHENZHU);
			ShenZhuCfg* cfg = imgr.GetShenZhuCfg(szLv);
			if (cfg == NULL)
				continue;

			map<uint8, SSkillData>::iterator sit = cfg->posSkill.find(eit->first);
			if (sit != cfg->posSkill.end())
				skillList.push_back(sit->second);
		}
	}
}

void CEquipManeger::CalcEquipSuitAttr(uint8 fpos)
{
	CItemCfgManager& imgr = sCItemCfgManager;
	AllWearEquipSuitMapIt it = m_formationEquips.find(fpos);
	if (it != m_formationEquips.end())
	{
		WearEquipSuit& wearEquips = it->second;
		FormationEquipMap& emap = wearEquips.wearEquips;
		U8tU8Map suitCnt;
		for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
		{
			if (eit->first > 4) continue;
			CEquip* equip = GetEqiup(eit->second);
			if (equip == NULL)
				continue;
			CEquipCfg* cfg = imgr.GetEquipCfg(equip->id);
			if (cfg == NULL)
				continue;
			suitCnt[cfg->suit] += 1;
		}

		for (U8tU8MapIt it = suitCnt.begin(); it != suitCnt.end(); ++it)
		{
			SuitAttr* sattr = imgr.GetSuitAttr(it->first);
			if (sattr == NULL)
				continue;
			SuitAttr curAttr;
			for (uint8 ci = 1; ci <= it->second; ++ci)
			{
				U8MultiAttrMapIt ait = sattr->cntAttrs.find(ci);
				if (ait != sattr->cntAttrs.end())
					curAttr.cntAttrs[ci] = ait->second;

				map<uint8, SSkillData>::iterator sit = sattr->cntSkill.find(ci);
				if (sit != sattr->cntSkill.end())
					curAttr.cntSkill[ci] = sit->second;
			}
			wearEquips.suitAttrs[it->first] = curAttr;
		}
		wearEquips.CalcAttr(*this);
	}
}

void CEquipManeger::GetEquipAttr(uint8 pos, MultiAttr& attrs)
{
	AllWearEquipSuitMapIt it = m_formationEquips.find(pos);
	if (it != m_formationEquips.end())
	{
		MergeAttrList(attrs, it->second.sumAttr);
		for (QHDSAttrMapIt qit = it->second.qhdsAttr.begin(); qit != it->second.qhdsAttr.end(); ++qit)
			MergeAttrList(attrs, qit->second.attrs);
	}
}


bool CEquipManeger::AddEquip(CUser* user, uint16 equipId)
{
	if (m_petEquips.size() >= 1000)
	{
		SendSysInfo(user, MakeStringColor(LANGUAGE_TRANSFORM_508, TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	CEquip equip;
	equip.id = equipId;
	if (!equip.InitAttr())
	{
		return false;
	}
	equip.uid = MakeUniqueId(user, EIT_PET);
	m_petEquips.insert(make_pair(equip.uid, equip));

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap << (uint8)6;
	trap.SetType(PET_EQUIP_OPERATE);
	equip.MakeMsg(trap);
	sock.SendMsg(user->GetSock(), trap);
	return true;
}

void CEquipManeger::DelEquip(CUser* user, uint32 equipId)
{
	m_petEquips.erase(equipId);
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap << (uint8)7 << equipId;
	trap.SetType(PET_EQUIP_OPERATE);
	sock.SendMsg(user->GetSock(), trap);
}

CEquip* CEquipManeger::GetEqiup(uint32 id)
{
	EquipMapIt it = m_petEquips.find(id);
	if (it == m_petEquips.end())
		return NULL;

	return &it->second;
}

void CEquipManeger::TakeOffAllEquip(CUser* user, SPet& pet)
{
	/*for (EquipMapIt it = pet.equips.begin(); it != pet.equips.end(); ++it)
	{
		AddEquip(user, it->second);
	}*/
}

void CEquipManeger::InitSuitAndQHDS()
{
	for (size_t i = 1; i <= 5; i++)
	{
		CalcEquipSuitAttr(i);
		for (size_t j = 1; j <= 6; j++)
		{
			CheckQHDS(i, j);
		}
	}
}

void CEquipManeger::MakeEquipMsg(CNetMessage& msg)
{
	msg << (uint8)m_formationEquips.size();
	for (AllWearEquipSuitMapIt it = m_formationEquips.begin(); it != m_formationEquips.end(); ++it)
	{
		WearEquipSuit& wearEquips = it->second;
		FormationEquipMap& emap = wearEquips.wearEquips;
		msg << (uint8)emap.size();
		for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
		{
			msg << eit->first;
			if (eit->first < EST_FBQIANGHUA)
			{
				CEquip* equip = GetEqiup(eit->second);
				if (equip == NULL)
				{
					msg << (uint32)0;
					continue;
				}
				equip->MakeMsg(msg);
			}
			else
			{
				FaBao* fabao = GetFaBao(eit->second);
				if (fabao == NULL)
				{
					msg << (uint32)0;
					continue;
				}
				fabao->MakeMsg(msg);
			}
		}
	}
}

bool CEquipManeger::AddFaBao(CUser * user, uint16 tid)
{
	if (m_allFaBao.size() >= 1000)
	{
		SendSysInfo(user, MakeStringColor(LANGUAGE_TRANSFORM_508, TIPS_FAILURE_COLOR).c_str());
		return false;
	}
	FaBao fabao;
	fabao.id = tid;
	if (!fabao.InitAttr())
	{
		return false;
	}
	fabao.uid = MakeUniqueId(user, EIT_FABAO);
	m_allFaBao.insert(make_pair(fabao.uid, fabao));

	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap << (uint8)22;
	trap.SetType(PET_EQUIP_OPERATE);
	fabao.MakeMsg(trap);
	sock.SendMsg(user->GetSock(), trap);
	return true;
}

void CEquipManeger::DelFaBao(CUser * user, uint32 fid)
{
	m_allFaBao.erase(fid);
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap << (uint8)23 << fid;
	trap.SetType(PET_EQUIP_OPERATE);
	sock.SendMsg(user->GetSock(), trap);
}

FaBao * CEquipManeger::GetFaBao(uint32 id)
{
	FaBaoMapIt it = m_allFaBao.find(id);
	if (it == m_allFaBao.end())
		return NULL;

	return &it->second;
}


// 装备合成
void CEquipManeger::EquipHeCheng(CUser* pUser, CNetMessage& msg)
{
	uint16 itemId;
	msg >> itemId;

	ComposeCfg* cfg = sCItemCfgManager.GetComposeCfg(CPT_EQUIP_HC, itemId);
	const bool localTest = gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) == "1";
	if (cfg == NULL)
	{
		if (localTest)
		{
			ComposeCfgMap* localComposeMap = sCItemCfgManager.GetComposeCfgMap(CPT_EQUIP_HC);
			cout << "[local][HeroEquip] EquipHeCheng missing config itemId=" << itemId
				<< " mapSize=" << (localComposeMap == NULL ? 0 : localComposeMap->size()) << endl;
		}
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	if (localTest)
	{
		const uint16 targetId = cfg->tar.type < HDAT_MONEY ? cfg->tar.type : cfg->tar.typeId;
		cout << "[local][HeroEquip] EquipHeCheng request itemId=" << itemId
			<< " costCount=" << cfg->costs.size() << " target=" << targetId;
		for (size_t i = 0; i < cfg->costs.size(); ++i)
			cout << " cost[" << i << "]=" << cfg->costs[i].costType << ":"
				<< cfg->costs[i].typeId << ":" << cfg->costs[i].costValue;
		cout << endl;
	}
	const uint16 targetId = cfg->tar.type < HDAT_MONEY ? cfg->tar.type : cfg->tar.typeId;
	if (targetId == 0 || sCItemCfgManager.GetEquipCfg(targetId) == NULL || m_petEquips.size() >= 1000)
	{
		if (localTest) cout << "[local][HeroEquip] EquipHeCheng invalid target/capacity target=" << targetId << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0001, TIPS_FAILURE_COLOR);
		return;
	}

	if (!pUser->UseMultiCost(cfg->costs))
	{
		if (localTest) cout << "[local][HeroEquip] EquipHeCheng UseMultiCost failed itemId=" << itemId << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0174, TIPS_FAILURE_COLOR);
		return;
	}

	if (!AddEquip(pUser, targetId))
	{
		if (localTest) cout << "[local][HeroEquip] EquipHeCheng AddEquip failed target=" << targetId << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0001, TIPS_FAILURE_COLOR);
		return;
	}
	if (localTest) cout << "[local][HeroEquip] EquipHeCheng success itemId=" << itemId << " target=" << targetId << endl;
	msg << PRO_SUCCESS;
	return;
}

void CEquipManeger::StrongEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint8 type;
	msg >> id >> type;

	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	CItemCfgManager& mgr = sCItemCfgManager;
	CEquipCfg* ecfg = mgr.GetEquipCfg(equip->id);
	if (ecfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 curLevel = equip->GetYangChengLevel(EST_QIANGHUA);
	uint16 maxLevel = user->GetLevel() * 2;
	if (curLevel >= maxLevel)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0176, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 cnt = 0;
	if (type == 1)
		cnt = 5;
	else if (type == 0)
		cnt = 1;
	uint16 realLevel = 0;
	uint8 critCnt = 0;
	uint16 si = curLevel + 1;
	double ratio = sCHeroCfgManager.GetQiangHuaRatio(ecfg->quality);
	for (size_t i = 0; i < cnt && si <= maxLevel; i++)
	{
		QiangHuaCfg* cfg = mgr.GetQiangHuaCfg(si);
		if (cfg == NULL)
			break;
		uint32 cv = ratio * cfg->cost.costValue;
		if (!user->SubMaterial(cfg->cost.costType, cv, false))
			break;
		equip->strongCost += cv;
		// 强化按钮按操作次数逐级提升：单次固定 +1，“强化5次”固定最多 +5。
		// 旧逻辑直接从 crit 配置抽取 2/3/5，遗漏普通 +1，导致单次也会跳级。
		uint8 addLevel = 1;
		realLevel += addLevel;
		si += addLevel;
		if (addLevel > 1)
			critCnt++;
	}
	if (realLevel == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_267, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 lastLevel = curLevel + realLevel;
	equip->strongLevel[EST_QIANGHUA] = lastLevel;
	msg << PRO_SUCCESS << critCnt << realLevel;
	msg << (uint8)ecfg->qhAttr.size();
	for (uint8 i = 0; i < ecfg->qhAttr.size(); ++i)
	{
		msg << ecfg->qhAttr[i].attrType << ecfg->qhAttr[i].attrValue * realLevel;
	}
	equip->InitAttr();
	CalcEquipSuitAttr(equip->fpos);
	UpdateEquip(user, equip);
	CheckQHDS(equip->fpos, EST_QIANGHUA, user);
	sCMissionManager.UpdateQuestState(user, EMQCT_7);
	sCMissionManager.UpdateQuestState(user, EMQCT_42);
	user->UpdateZhenFaPetInfo(equip->fpos);

	if (lastLevel >= 60 && lastLevel / 60 > curLevel / 60)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0234, user->GetName(), mgr.GetEquipColorName(ecfg->id).c_str(), lastLevel / 20 * 20);
		SysInfoToAllUser(buf);
	}
	return;
}

void CEquipManeger::StrongAllEquip(CUser* user, CNetMessage& msg)
{
	uint8 fPos;
	msg >> fPos;
	AllWearEquipSuitMapIt it = m_formationEquips.find(fPos);
	if (it == m_formationEquips.end())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	FormationEquipMap& emap = it->second.wearEquips;
	for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
	{
		CEquip* equip = GetEqiup(eit->second);
		if (equip != NULL && sCItemCfgManager.GetEquipCfg(equip->id) == NULL)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
			return;
		}
	}
	uint16 maxLevel = user->GetLevel() * 2;
	uint8 critCnt = 0;
	msg << PRO_SUCCESS << (uint8)emap.size();
	MultiAttr addAttr;
	CItemCfgManager& imgr = sCItemCfgManager;
	CHeroCfgManager& hmgr = sCHeroCfgManager;
	CMissionManager& mmgr = sCMissionManager;
	uint16 qhCnt = 0;
	for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
	{
		CEquip* equip = GetEqiup(eit->second);
		if (equip == NULL)
		{
			msg << eit->first << eit->second << (uint8)0;
			continue;
		}

		CEquipCfg* ecfg = imgr.GetEquipCfg(equip->id);
		if (ecfg == NULL)
			continue;

		uint16 curLevel = equip->GetYangChengLevel(EST_QIANGHUA);
		if (curLevel >= maxLevel)
		{
			msg << eit->first << eit->second << (uint8)0;
			continue;
		}
		uint16 dstLevel = curLevel + 5;
		uint16 realLevel = 0;
		for (uint16 si = curLevel + 1; si <= dstLevel && si <= maxLevel;)
		{
			QiangHuaCfg* cfg = imgr.GetQiangHuaCfg(si);
			if (cfg == NULL)
				break;
			double ratio = hmgr.GetQiangHuaRatio(ecfg->quality);
			uint32 cv = ratio * cfg->cost.costValue;
			if (!user->SubMaterial(cfg->cost.costType, cv))
				break;
			equip->strongCost += cv;
			uint8 addLevel = cfg->GetRatioLevel();
			realLevel += addLevel;
			si += addLevel;
			if (addLevel > 0)
				critCnt++;
			qhCnt++;
		}
		msg << eit->first << eit->second << (uint8)realLevel;
		if (realLevel == 0)
			continue;
		equip->strongLevel[EST_QIANGHUA] = curLevel + realLevel;
		MultiAttr curAttr;
		for (uint8 i = 0; i < ecfg->qhAttr.size(); ++i)
		{
			SAttrData data;
			data.attrType = ecfg->qhAttr[i].attrValue * realLevel;
			curAttr.push_back(data);
		}
		MergeAttrList(addAttr, curAttr);
		equip->InitAttr();
		UpdateEquip(user, equip);

		if (curLevel + realLevel >= 60 && (curLevel + realLevel) / 60 > curLevel / 60)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0234, user->GetName(), imgr.GetEquipColorName(ecfg->id).c_str(), (curLevel + realLevel) / 20 * 20);
			SysInfoToAllUser(buf);
		}
	}
	CheckQHDS(fPos, EST_QIANGHUA, user);
	CalcEquipSuitAttr(fPos);
	user->UpdateZhenFaPetInfo(fPos);
	mmgr.UpdateQuestState(user, EMQCT_7, qhCnt);
	mmgr.UpdateQuestState(user, EMQCT_42);
	return;
}

// 精炼
void CEquipManeger::JingLianEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint8 itemSize = 0;
	msg >> id >> itemSize;
	const bool localTest = gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) == "1";
	if (localTest)
		cout << "[local][HeroEquip] JingLian request uid=" << id << " itemSize=" << (uint32)itemSize
			<< " equipmentCount=" << m_petEquips.size() << endl;
	static U16tU32Map itemExp;
	if (itemExp.size() == 0)
	{
		vector<uint16>* vec = SingletonItemManager::instance().GetTypeItem(4);
		if (vec == NULL)
		{
			if (localTest) cout << "[local][HeroEquip] JingLian type=4 material config list missing" << endl;
			msg.ReWrite();
			msg.SetType(PET_EQUIP_OPERATE);
			msg << (uint8)13 << id << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
			return;
		}
		for (uint8 i = 0; i < vec->size(); ++i)
		{
			uint16 itemId = (*vec)[i];
			SItemTemplate *pItem = SingletonItemManager::instance().GetItem(itemId);
			if (pItem == NULL)
			{
				if (localTest) cout << "[local][HeroEquip] JingLian material config missing itemId=" << itemId << endl;
				msg.ReWrite();
				msg.SetType(PET_EQUIP_OPERATE);
				msg << (uint8)13 << id << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
				return;
			}
			itemExp[itemId] = pItem->subValue;
		}
	}

	uint16 itemId = 0;
	uint16 itemNum = 0;
	int sumExp = 0;
	MultiCost userCost;
	for (uint8 si = 0; si < itemSize; ++si)
	{
		msg >> itemId >> itemNum;
		if (localTest)
			cout << "[local][HeroEquip] JingLian material itemId=" << itemId << " count=" << itemNum
				<< " owned=" << user->GetMaterial(itemId) << endl;
		U16tU32MapIt uit = itemExp.find(itemId);
		if (uit != itemExp.end())
		{
			SCostData cost;
			sumExp += itemNum * uit->second;
			cost.costType = itemId;
			cost.costValue = itemNum;
			userCost.push_back(cost);
			if (user->GetMaterial(itemId) < itemNum)
			{
				msg.ReWrite();
				msg.SetType(PET_EQUIP_OPERATE);
				msg << (uint8)13 << id;
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0167, GetItemName(uit->first));
				msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0167, TIPS_FAILURE_COLOR);
				return;
			}
		}
	}

	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)13 << id;
	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		if (localTest) cout << "[local][HeroEquip] JingLian equipment uid not found=" << id << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	CItemCfgManager& imgr = sCItemCfgManager;
	CMissionManager& mmgr = sCMissionManager;
	sumExp += equip->curExp;
	CEquipCfg* ecfg = imgr.GetEquipCfg(equip->id);
	if (ecfg == NULL)
	{
		if (localTest) cout << "[local][HeroEquip] JingLian template config missing id=" << equip->id << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 curLevel = equip->GetYangChengLevel(EST_JINGLIAN);
	double jxRatio = sCHeroCfgManager.GetJingLianRatio(ecfg->quality);
	uint16 addlevel = 0;
	while (sumExp > 0)
	{
		int needExp = imgr.GetJingLianExp(curLevel + addlevel) * jxRatio;
		if (needExp == 0 || sumExp < needExp)
			break;
		sumExp -= needExp;
		addlevel++;
		if (addlevel >= CItemCfgManager::CfgMaxJlLv)
			break;
	}
	if (addlevel == 0)
	{
		if (localTest)
			cout << "[local][HeroEquip] JingLian insufficient exp uid=" << id << " sumExp=" << sumExp
				<< " currentLevel=" << curLevel << " quality=" << (uint32)ecfg->quality
				<< " ratio=" << jxRatio << endl;
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0169, TIPS_FAILURE_COLOR);
		return;
	}
	equip->curExp = sumExp;
	user->DelCostMaterial(userCost);
	equip->strongLevel[EST_JINGLIAN] = curLevel + addlevel;
	equip->InitAttr();
	UpdateEquip(user, equip);
	msg << PRO_SUCCESS << addlevel << (uint8)ecfg->jlAttr.size();
	for (uint8 i = 0; i < ecfg->jlAttr.size(); ++i)
	{
		msg << ecfg->jlAttr[i].attrType << ecfg->jlAttr[i].attrValue;
	}
	for (uint16 i = curLevel + 1; i <= curLevel + addlevel; i++)
	{
		if (i >= 20 && i % 10 == 0)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0235, user->GetName(), imgr.GetEquipColorName(ecfg->id).c_str(), i);
			SysInfoToAllUser(buf);
		}
	}
	CheckQHDS(equip->fpos, EST_JINGLIAN, user);
	mmgr.UpdateQuestState(user, EMQCT_8);
	mmgr.UpdateQuestState(user, EMQCT_45);
	CalcEquipSuitAttr(equip->fpos);
	user->UpdateZhenFaPetInfo(equip->fpos);
	return;
}

// 觉醒
void CEquipManeger::JueXingEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint16 level;
	msg >> id >> level ;

	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}

	CEquipCfg* ecfg = sCItemCfgManager.GetEquipCfg(equip->id);
	if (ecfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 curLevel = equip->GetYangChengLevel(EST_JUEXING);
	JueXingCfg* cfg = sCItemCfgManager.GetJueXinCfg(++curLevel);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0178, TIPS_FAILURE_COLOR);
		return;
	}
	if (!user->UseMultiCost(cfg->cost))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0179, TIPS_FAILURE_COLOR);
		return;
	}

	equip->strongLevel[EST_JUEXING] = curLevel;
	msg << PRO_SUCCESS << curLevel << (uint8)ecfg->jxAttr.size();
	for (uint8 i = 0; i < ecfg->jxAttr.size(); ++i)
	{
		msg << ecfg->jxAttr[i].attrType << ecfg->jxAttr[i].attrValue;
	}
	equip->InitAttr();
	UpdateEquip(user, equip);
	CheckQHDS(equip->fpos, EST_JUEXING, user);
	CalcEquipSuitAttr(equip->fpos);
	user->UpdateZhenFaPetInfo(equip->fpos);

	if (curLevel % 10 == 0)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0236, user->GetName(), MakeColorString(ecfg->quality, ecfg->name).c_str(), cfg->name.c_str());
		SysInfoToAllUser(buf);
	}
}

// 神铸
void CEquipManeger::ShenZhuEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint16 level;
	msg >> id >> level;

	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}

	CEquipCfg* ecfg = sCItemCfgManager.GetEquipCfg(equip->id);
	if (ecfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	uint16 curLevel = equip->GetYangChengLevel(EST_SHENZHU);
	ShenZhuCfg* cfg = sCItemCfgManager.GetShenZhuCfg(++curLevel);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0180, TIPS_FAILURE_COLOR);
		return;
	}
	if (user->GetItemNum(ecfg->szCost) < cfg->itemNum)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0179, TIPS_FAILURE_COLOR);
		return;
	}
	if (!user->UseMultiCost(cfg->cost))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0179, TIPS_FAILURE_COLOR);
		return;
	}
	user->SubMaterial(ecfg->szCost, cfg->itemNum);
	equip->strongLevel[EST_SHENZHU] = curLevel;
	msg << PRO_SUCCESS << curLevel << (uint8)ecfg->szAttr.size();
	for (uint8 i = 0; i < ecfg->szAttr.size(); ++i)
	{
		msg << ecfg->szAttr[i].attrType << ecfg->szAttr[i].attrValue;
	}
	map<uint8, SSkillData>::iterator it = cfg->posSkill.find(ecfg->part);
	if (it != cfg->posSkill.end())
	{
		msg << it->second.id << it->second.level;
	}
	else
	{
		msg << (uint16)0 << (uint16)0;
	}
	equip->InitAttr();
	UpdateEquip(user, equip);
	CheckQHDS(equip->fpos, EST_SHENZHU, user);
	CalcEquipSuitAttr(equip->fpos);
	user->UpdateZhenFaPetInfo(equip->fpos);

	if (curLevel % 50 == 0)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0237, user->GetName(), MakeColorString(ecfg->quality, ecfg->name).c_str(), cfg->name.c_str());
		SysInfoToAllUser(buf);
	}
}

void CEquipManeger::SendPetEquipList(CUser* user, CNetMessage& msg)
{
	CSocketServer &sock = SingletonSocket::instance();
	if (m_petEquips.empty())
	{
		msg << (uint16)0;
		sock.SendMsg(user->GetSock(), msg);
		return;
	}
	static uint8 sendMax = 50;
	uint16 sumNum = m_petEquips.size();
	uint8 maxIdx = sumNum / sendMax;
	uint8 lessNum = sumNum % sendMax;
	if (lessNum != 0)
		maxIdx++;
	EquipMapIt it = m_petEquips.begin();
	for (uint8 idx = 0; idx < maxIdx; ++idx)
	{
		CNetMessage listMsg;
		listMsg.SetType(PET_EQUIP_OPERATE);
		listMsg << (uint8)1 << uint16(sumNum) << (uint8)maxIdx << (uint8)idx;
		if (idx == maxIdx - 1 && lessNum != 0)
			listMsg << (uint8)lessNum;
		else
			listMsg << (uint8)sendMax;

		for (uint8 si = 0; si < sendMax && it != m_petEquips.end(); ++si, ++it)
		{
			it->second.MakeMsg(listMsg);
		}
		sock.SendMsg(user->GetSock(), listMsg);
	}
}

void CEquipManeger::WearPetEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint8 fpos;
	msg >> fpos >> id;
	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	if (!sSystemOpenCfgMananger.CheckSystemOpen(user, SOT_1045 + equip->wpos - 1)
		&& gyu::util::CIniFile::GetValue("local_test","server",gConfigFile) != "1")
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_LLD_0072, TIPS_FAILURE_COLOR);
		return;
	}
	if (fpos == 0 || fpos > 5)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	uint8 prePos = equip->fpos;
	uint32 preId = 0;
	AllWearEquipSuitMapIt fit = m_formationEquips.find(fpos);
	if (fit != m_formationEquips.end())
	{
		FormationEquipMap& emap = fit->second.wearEquips;
		FormationEquipMapIt feit = emap.find(equip->wpos);
		if (feit != emap.end())
			preId = feit->second;
		emap[equip->wpos] = equip->uid;
		CalcEquipSuitAttr(fpos);
	}
	else
	{
		WearEquipSuit suit;
		suit.wearEquips[equip->wpos] = equip->uid;
		m_formationEquips[fpos] = suit;
	}
	equip->fpos = fpos;

	if (prePos != 0)
	{
		AllWearEquipSuitMapIt fit = m_formationEquips.find(prePos);
		if (fit != m_formationEquips.end())
		{
			FormationEquipMap& emap = fit->second.wearEquips;
			emap[equip->wpos] = preId;
			CalcEquipSuitAttr(fpos);
		}
	}
	CEquip* preEquip = GetEqiup(preId);
	if (preEquip != NULL)
	{
		preEquip->fpos = prePos;
	}

	msg << PRO_SUCCESS << MakeStringColor(LANGUAGE_TRANSFORM_1991, TIPS_WARNING_COLOR);
	CheckEquipQHDS(fpos, user);
	WearEquipSuit* suit = GetWearEquipSuit(equip->fpos);
	if (suit != NULL)
		suit->CalcAttr(*this);
	user->UpdateZhenFaPetInfo(equip->fpos);
	return;
}

void CEquipManeger::UpdateEquip(CUser* user, CEquip* equip)
{
	if (equip == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap.SetType(PET_EQUIP_OPERATE);
	trap << (uint8)16;
	equip->MakeMsg(trap);
	sock.SendMsg(user->GetSock(), trap);
}

void CEquipManeger::UpdateFabao(CUser* pUser, FaBao* fabao)
{
	if (fabao == NULL)
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage trap;
	trap.SetType(PET_EQUIP_OPERATE);
	trap << (uint8)22;
	fabao->MakeMsg(trap);
	sock.SendMsg(pUser->GetSock(), trap);
}

void CEquipManeger::TakeOffPetEquip(CUser* user, CNetMessage& msg)
{
	uint32 id;
	uint8 fpos;
	msg >> fpos >> id;
	CEquip* equip = GetEqiup(id);
	if (equip == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	if (fpos > 5)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	AllWearEquipSuitMapIt fit = m_formationEquips.find(fpos);
	if (fit != m_formationEquips.end())
	{
		fit->second.wearEquips[equip->wpos] = 0;
		CalcEquipSuitAttr(fpos);
	}
	equip->fpos = 0;
	CheckEquipQHDS(fpos, user);
	msg << PRO_SUCCESS << MakeStringColor(LANGUAGE_TRANSFORM_1990, TIPS_SUCCESS_COLOR);
	user->UpdateZhenFaPetInfo(fpos);
}

WearEquipSuit* CEquipManeger::GetWearEquipSuit(uint8 pos)
{
	AllWearEquipSuitMapIt it = m_formationEquips.find(pos);
	if (it == m_formationEquips.end())
		return NULL;

	return &it->second;
}


void CEquipManeger::GetFenjieCost(CEquip* equip, map<uint16, uint32>& costBack)
{
}

void CEquipManeger::CFenJiePetEquip(CUser* user, CNetMessage& msg)
{
	uint8 num;
	uint32 eid;
	msg >> num;
	map<uint16, uint32> costBack;
	MultiCost sumCost;
	for (uint8 idx = 0; idx < num; ++idx)
	{
		msg >> eid;
		CEquip* equip = GetEqiup(eid);
		if (equip == NULL)
			continue;

		MultiCost costs;
		equip->GetChongSheng(costs, 2);
		MergeMultiCost(sumCost, costs);
	}
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)5 << PRO_SUCCESS;
	MakeMultiCostMsg(sumCost, msg);
	return;
}

void CEquipManeger::MutilFenJiePetEquip(CUser* user, CNetMessage& msg)
{
	uint8 num;
	uint32 eid;
	msg >> num;
	if (user->GetTongBao() < num * 50)
		return;
	map<uint16, uint32> costBack;
	int fenjieCnt = 0;
	MultiCost sumCost;
	for (uint8 idx = 0; idx < num; ++idx)
	{
		msg >> eid;
		CEquip* equip = GetEqiup(eid);
		if (equip == NULL)
			continue;

		MultiCost costs;
		equip->GetChongSheng(costs, 2);
		MergeMultiCost(sumCost, costs);
		fenjieCnt++;
		DelEquip(user, eid);
	}
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)8 << PRO_SUCCESS;
	MakeMultiCostMsg(sumCost, msg);
	user->AddMultiCost(sumCost, &msg);
	user->AddMaterial(HDAT_YB, fenjieCnt * 50);
	return;
}

// 发送法宝列表
void CEquipManeger::SendFaBaoList(CUser* user, CNetMessage& msg)
{
	CSocketServer &sock = SingletonSocket::instance();
	if (m_allFaBao.empty())
	{
		msg << (uint16)0;
		sock.SendMsg(user->GetSock(), msg);
		return;
	}
	static uint8 sendMax = 50;
	uint16 sumNum = m_allFaBao.size();
	uint8 maxIdx = sumNum / sendMax;
	uint8 lessNum = sumNum % sendMax;
	if (lessNum != 0)
		maxIdx++;
	FaBaoMapIt it = m_allFaBao.begin();
	for (uint8 idx = 0; idx < maxIdx; ++idx)
	{
		CNetMessage listMsg;
		listMsg.SetType(PET_EQUIP_OPERATE);
		listMsg << (uint8)17 << uint16(sumNum) << (uint8)maxIdx << (uint8)idx;
		if (idx == maxIdx - 1 && lessNum != 0)
			listMsg << (uint8)lessNum;
		else
			listMsg << (uint8)sendMax;

		for (uint8 si = 0; si < sendMax && it != m_allFaBao.end(); ++si, ++it)
		{
			it->second.MakeMsg(listMsg);
		}
		sock.SendMsg(user->GetSock(), listMsg);
	}
}

void CEquipManeger::WearFaBao(CUser * user, CNetMessage & msg)
{
	uint32 id;
	uint8 fpos;
	uint8 wpos;
	msg >> id >> fpos >> wpos;
	FaBao* fabao = GetFaBao(id);
	if (fabao == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	if (fpos > 5 || (wpos != 5 && wpos != 6))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	if (fabao->fpos != 0 && fabao->wpos != 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0209, TIPS_FAILURE_COLOR);
		return;
	}
	uint32 preId = 0;
	AllWearEquipSuitMapIt fit = m_formationEquips.find(fpos);
	if (fit != m_formationEquips.end())
	{
		WearEquipSuit& wes = fit->second;
		FormationEquipMapIt feit = wes.wearEquips.find(wpos);
		if (feit != wes.wearEquips.end())
			preId = feit->second;
		if (preId == id)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0209, TIPS_FAILURE_COLOR);
			return;
		}
		uint32 nfId = wes.GetOtherFaBaoId(wpos);
		FaBao* nfabao = GetFaBao(nfId);
		if (nfabao != NULL && nfabao->id == fabao->id)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0210, TIPS_FAILURE_COLOR);
			return;
		}
		FaBao* sfabao = GetFaBao(preId);
		if (sfabao != NULL)
		{
			sfabao->wpos = 0;
			sfabao->fpos = 0;
		}
		fabao->wpos = wpos;
		wes.wearEquips[fabao->wpos] = fabao->uid;
	}
	fabao->fpos = fpos;
	fabao->wpos = wpos;
	
	msg << PRO_SUCCESS << preId << MakeStringColor(LANGUAGE_TRANSFORM_1991, TIPS_WARNING_COLOR);
	CheckFBQHDS(fpos, user);
	WearEquipSuit* suit = GetWearEquipSuit(fpos);
	if (suit != NULL)
		suit->CalcAttr(*this);
	user->UpdateZhenFaPetInfo(fpos);
	return;
}

void CEquipManeger::TakeOffFaBao(CUser * user, CNetMessage & msg)
{
	uint32 id;
	msg >> id;
	FaBao* fabao = GetFaBao(id);
	if (fabao == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	if (fabao->fpos == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0209, TIPS_FAILURE_COLOR);
		return;
	}
	uint8 preFpos = fabao->fpos;
	uint8 preWpos = fabao->wpos;
	AllWearEquipSuitMapIt fit = m_formationEquips.find(preFpos);
	if (fit != m_formationEquips.end())
	{
		WearEquipSuit& wes = fit->second;
		wes.wearEquips[preWpos] = 0;
	}
	fabao->fpos = 0;
	fabao->wpos = 0;
	CheckFBQHDS(preFpos, user);
	WearEquipSuit* suit = GetWearEquipSuit(preFpos);
	if (suit != NULL)
		suit->CalcAttr(*this);
	user->UpdateZhenFaPetInfo(preFpos);
	msg << PRO_SUCCESS;
	return;
}

void CEquipManeger::StrongFaBao(CUser * user, CNetMessage & msg)
{
	uint32 id;
	uint8 itemSize = 0;
	msg >> id >> itemSize;

	FaBao* fabao = GetFaBao(id);
	if (fabao == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	CItemCfgManager& mgr = sCItemCfgManager;
	CHeroCfgManager& hcfg = sCHeroCfgManager;
	uint32 fcid = 0;
	int sumExp = 0;
	vector<uint32> fcids;
	MultiCost sumCost;

	for (uint8 si = 0; si < itemSize; ++si)
	{
		msg >> fcid;
		FaBao* tmp = GetFaBao(fcid);
		if (tmp == NULL)
			continue;
		MultiCost tmpCosts;
		tmp->GetChongSheng(tmpCosts, 0);
		MergeMultiCost(sumCost, tmpCosts);
		FaBaoCfg* tcfg = mgr.GetFaBaoCfg(tmp->id);
		if (tcfg != NULL && tcfg->exp > 0)
		{
			sumExp += tcfg->exp;
			fcids.push_back(fcid);
		}
	}

	FaBaoCfg* fcfg = mgr.GetFaBaoCfg(fabao->id);
	if (fcfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0175, TIPS_FAILURE_COLOR);
		return;
	}
	if (!user->SubMaterial(HDAT_MONEY, sumExp))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_939, TIPS_FAILURE_COLOR);
		return;
	}
	sumExp += fabao->exp;
	double ratio = hcfg.GetFaBaoQiangHuaRatio(fcfg->quality);
	uint16 curLevel = fabao->GetYangChengLevel(EST_FBQIANGHUA);
	static uint8 maxLv = mgr.MaxFaBaoQhLevel();
	uint8 realLevel = curLevel;
	for (uint8 si = curLevel + 1; si <= maxLv; ++si)
	{
		int needExp = mgr.GetFaBaoExp(si) * ratio;
		if (sumExp < needExp)
			break;
		sumExp -= needExp;
		realLevel = si;
	}
	fabao->exp = sumExp;
	fabao->ycLv[EST_FBQIANGHUA] = realLevel;
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)20 << PRO_SUCCESS << id << realLevel << fabao->exp << (uint8)fcids.size();
	for (size_t i = 0; i < fcids.size(); i++)
	{
		msg << fcids[i];
		DelFaBao(user, fcids[i]);
	}
	user->AddMultiCost(sumCost);
	fabao->InitAttr();
	CheckQHDS(fabao->fpos, EST_FBQIANGHUA, user);
	WearEquipSuit* suit = GetWearEquipSuit(fabao->fpos);
	if (suit != NULL)
		suit->CalcAttr(*this);
	sCMissionManager.UpdateQuestState(user, EMQCT_11);
	sCMissionManager.UpdateQuestState(user, EMQCT_47, realLevel);
	sCMissionManager.UpdateQuestState(user, EMQCT_48);
	user->UpdateZhenFaPetInfo(fabao->fpos);

	for (uint16 i = curLevel + 1; i <= realLevel; i++)
	{
		if (i == 50
			|| i == 80
			|| i == 100
			|| i == 120)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0234, user->GetName(), MakeColorString(fcfg->quality, fcfg->name).c_str(), i);
			SysInfoToAllUser(buf);
		}
	}
	return;
}

void CEquipManeger::JingLianFaBao(CUser * user, CNetMessage & msg)
{
	uint32 id;
	uint8 level;
	msg >> id >> level;
	FaBao* fabao = GetFaBao(id);
	if (fabao == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_1318, TIPS_FAILURE_COLOR);
		return;
	}
	CItemCfgManager& mgr = sCItemCfgManager;
	static uint8 maxLv = mgr.MaxFaBaoQhLevel();
	uint8 curLevel = fabao->GetYangChengLevel(EST_FBJINGLIAN);
	uint8 reallv = curLevel++;
	for (; curLevel < maxLv && curLevel <= level; curLevel++)
	{
		MultiCost* cost = mgr.GetFaBaoJlCost(curLevel);
		if (cost == NULL)
			break;
		if (!user->UseMultiCost(*cost))
			break;
		reallv = curLevel;
	}
	fabao->ycLv[EST_FBJINGLIAN] = reallv;
	fabao->InitAttr();
	CheckQHDS(fabao->fpos, EST_FBJINGLIAN, user);
	msg << PRO_SUCCESS << reallv;
	WearEquipSuit* suit = GetWearEquipSuit(fabao->fpos);
	if (suit != NULL)
		suit->CalcAttr(*this);
	sCMissionManager.UpdateQuestState(user, EMQCT_49);
	user->UpdateZhenFaPetInfo(fabao->fpos);
	if (reallv % 5 == 0)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0235, user->GetName(), mgr.GetFaBaoColorName(fabao->id).c_str(), reallv);
		SysInfoToAllUser(buf);
	}
}

void CEquipManeger::GetQHDSMsg(CNetMessage& msg)
{
	uint8 pos;
	msg >> pos;
	WearEquipSuit* suit = GetWearEquipSuit(pos);
	if (suit == NULL)
		return;

	suit->MakeQHDSMsg(msg);
}

void CEquipManeger::CheckQHDS(uint8 pos, uint8 type, CUser* pUser/* = NULL*/)
{
	WearEquipSuit* suit = GetWearEquipSuit(pos);
	if (suit == NULL)
		return;
	CItemCfgManager& mgr = sCItemCfgManager;
	QHDSCfgMap* qmap = mgr.GetQHDSMap(type);
	if (qmap == NULL)
		return;
	uint16 minLv = 999;
	switch (type)
	{
	case 1:
	case 2:
	case 3:
	case 4:
	{
		for (size_t i = 1; i <= 4; i++)
		{
			uint32 eid = suit->wearEquips[i];
			CEquip* equip = GetEqiup(eid);
			if (equip == NULL)
				return;
			uint16 level = equip->GetYangChengLevel(type);
			if (level < minLv)
				minLv = level;
		}
	}
	break;

	case 5:
	case 6:
	{
		for (size_t i = 5; i <= 6; i++)
		{
			uint32 id = suit->wearEquips[i];
			FaBao* fb = GetFaBao(id);
			if (fb == NULL)
				return;
			uint16 level = fb->GetYangChengLevel(type);
			if (level < minLv)
				minLv = level;
		}
	}
	break;

	default:
		break;
	}
	QiangHuaDaShiCfg* cfg = mgr.GetQhdsCfg(qmap, minLv);
	if (cfg == NULL)
	{
		QHDSAttr tmp;
		tmp.curLv = 0;
		tmp.attrs.clear();
		suit->qhdsAttr[type] = tmp;
		return;
	}

	QHDSAttr* attr = suit->GetQHDSAttr(type);
	if (attr == NULL || attr->curLv != cfg->lv)
	{
		QHDSAttr tmp;
		tmp.curLv = cfg->lv;
		tmp.attrs = cfg->attrs;
		suit->qhdsAttr[type] = tmp;
		if (pUser != NULL)
		{
			CNetMessage msg;
			msg.SetType(PET_EQUIP_OPERATE);
			msg << (uint8)24 << pos << type << tmp.curLv;
			SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		}
	}
}

void CEquipManeger::CheckEquipQHDS(uint8 pos, CUser* pUser/* = NULL*/)
{
	WearEquipSuit* suit = GetWearEquipSuit(pos);
	if (suit == NULL)
		return;
	CItemCfgManager& mgr = sCItemCfgManager;
	for (size_t i = 1; i <= 5; i++)
	{
		switch (i)
		{
		case 1:
		case 2:
		case 3:
		case 4:
		{
			QHDSCfgMap* qmap = mgr.GetQHDSMap(i);
			if (qmap == NULL)
				continue;

			uint16 minLv = 999;
			for (size_t pi = 1; pi <= 4; pi++)
			{
				uint32 eid = suit->wearEquips[pi];
				uint16 level = 0;
				CEquip* equip = GetEqiup(eid);
				if (equip != NULL)
					level = equip->GetYangChengLevel(i);
				if (level < minLv)
					minLv = level;
			}

			QiangHuaDaShiCfg* cfg = mgr.GetQhdsCfg(qmap, minLv);
			if (cfg == NULL)
			{
				QHDSAttr tmp;
				tmp.curLv = 0;
				tmp.attrs.clear();
				suit->qhdsAttr[i] = tmp;
			}
			else
			{
				QHDSAttr* attr = suit->GetQHDSAttr(i);
				if (attr == NULL || attr->curLv != cfg->lv)
				{
					QHDSAttr tmp;
					tmp.curLv = cfg->lv;
					tmp.attrs = cfg->attrs;
					suit->qhdsAttr[i] = tmp;
				}
			}
		}
		break;
		}
	}
	if (pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)26 << pos;
	suit->MakeQHDSMsg(msg);
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CEquipManeger::CheckFBQHDS(uint8 pos, CUser* pUser/* = NULL*/)
{
	WearEquipSuit* suit = GetWearEquipSuit(pos);
	if (suit == NULL)
		return;
	CItemCfgManager& mgr = sCItemCfgManager;
	for (size_t i = 5; i <= 6; i++)
	{
		QHDSCfgMap* qmap = mgr.GetQHDSMap(i);
		if (qmap == NULL)
			continue;

		uint16 minLv = 999;
		switch (i)
		{
		case 5:
		case 6:
		{
			for (size_t pi = 5; pi <= 6; pi++)
			{
				uint32 id = suit->wearEquips[pi];
				uint16 level = 0;
				FaBao* fb = GetFaBao(id);
				if (fb != NULL)
					level = fb->GetYangChengLevel(i);
				if (level < minLv)
					minLv = level;
			}
			QiangHuaDaShiCfg* cfg = mgr.GetQhdsCfg(qmap, minLv);
			if (cfg == NULL)
			{
				QHDSAttr tmp;
				tmp.curLv = 0;
				tmp.attrs.clear();
				suit->qhdsAttr[i] = tmp;
			}
			else
			{
				QHDSAttr* attr = suit->GetQHDSAttr(i);
				if (attr == NULL || attr->curLv != cfg->lv)
				{
					QHDSAttr tmp;
					tmp.curLv = cfg->lv;
					tmp.attrs = cfg->attrs;
					suit->qhdsAttr[i] = tmp;
				}
			}
			break;
		}
		break;
		}
	}
	if (pUser == NULL)
		return;
	CNetMessage msg;
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)27 << pos;
	suit->MakeQHDSMsg(msg, 2);
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}

void CEquipManeger::FaBaoSouSuo(CUser* pUser, CNetMessage& msg)
{
	uint16 fid;
	uint16 sid;
	msg >> fid >> sid;
	if (pUser->GetItemNum(sid))
		return;
	if (!pUser->HaveBitSet(629))
	{
		fid = 1001;
		sid = 4701;
	}
	CItemCfgManager& mgr = sCItemCfgManager;
	FaBaoCfg* fcfg = mgr.GetFaBaoCfg(fid);
	ComposeIds* ids = mgr.GetFaBaoComposeIds(fid);
	uint16 ratio = mgr.GetFaBaoSouSuo(sid);
	if (fcfg == NULL || ids == NULL || ratio == 0)
		return;
	if (fcfg->quality > 3)
	{
		bool has = false;
		for (size_t i = 0; i < (*ids).size(); i++)
		{
			has = pUser->GetItemNum((*ids)[i]);
			if (has)
				break;
		}
		if (!has) return;
	}
	uint16 cnt = 0;
	msg << PRO_SUCCESS;
	uint16 pos = msg.GetDataLen();
	msg << m_faBaoCnt << cnt << m_lastCntTime;
	MultiAward awards;
	AwardManager& amgr = sAwardManager;
	if (!pUser->HaveBitSet(629))
	{
		// 引导搜索
		for (size_t i = 0; i < (*ids).size(); i++)
		{
			uint16 tmpId = (*ids)[i];
			SAwardData ad;
			ad.type = tmpId;
			ad.num = 1;
			MergeAwardData(awards, ad);
		}
		MakeMultiAwardMsg(awards, msg);
		if (m_faBaoCnt > 0)
			m_faBaoCnt -= 1;
		cnt = 1;
		pUser->SetBitSet(629);
	}
	else
	{
		while (m_faBaoCnt > 0)
		{
			--m_faBaoCnt;
			MultiAward tmp;
			amgr.GetActivityDrop(pUser, 9, 1, tmp);
			cnt++;
			uint16 res = Random(1, 100);
			if (res < ratio)
			{
				SAwardData ad;
				ad.type = sid;
				ad.num = 1;
				MergeAwardData(tmp, ad);
				MakeMultiAwardMsg(tmp, msg);
				MergeAwardList(awards, tmp);
				break;
			}
			MakeMultiAwardMsg(tmp, msg);
			MergeAwardList(awards, tmp);
		}
	}
	uint32 now = GetSysTime();
	if (m_lastCntTime == 0 && m_faBaoCnt < CItemCfgManager::CfgFBMaxCnt)
		m_lastCntTime = now;

	uint32 sec = now + CItemCfgManager::CfgFBAddSec - m_lastCntTime;
	msg.WriteData(pos, &m_faBaoCnt, sizeof(m_faBaoCnt));
	msg.WriteData(pos + 2, &cnt, sizeof(cnt));
	msg.WriteData(pos + 4, &sec, sizeof(sec));
	SendAndMakeAwardMsg(pUser, awards, msg);
	pUser->AddExtData16(ED16_71, cnt);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_14, cnt);
}

void CEquipManeger::FaBaoAutoSouSuo(CUser* pUser, CNetMessage& msg)
{
	uint8 use;
	uint16 fid;
	msg >> use >> fid ;
	CItemCfgManager& mgr = sCItemCfgManager;
	FaBaoCfg* fcfg = mgr.GetFaBaoCfg(fid);
	ComposeIds* ids = mgr.GetFaBaoComposeIds(fid);
	if (fcfg == NULL || ids == NULL)
		return;

	if (fcfg->quality > 3)
	{
		bool has = false;
		for (size_t i = 0; i < (*ids).size(); i++)
		{
			has = pUser->GetItemNum((*ids)[i]);
			if (has)
				break;
		}
		if (!has) return;
	}
	uint16 cnt = 0;
	msg << PRO_SUCCESS;
	MultiAward awards;
	AwardManager& amgr = sAwardManager;
	static uint16 stoneId = 402;
	static uint8 addCnt = 0;
	if (addCnt == 0)
	{
		SItemTemplate* item = SingletonItemManager::instance().GetItem(stoneId);
		if (item != NULL && !item->subVec.empty())
			addCnt = item->subVec[0].second;
	}
	uint16 itemCnt = pUser->GetItemNum(stoneId);
	uint16 useCnt = 0;
	uint16 pos = msg.GetDataLen();
	msg << cnt;
	for (size_t i = 0; i < ids->size() && m_faBaoCnt > 0; i++)
	{
		uint16 sid = (*ids)[i];
		if (pUser->GetItemNum(sid))
			continue;

		while (true)
		{
			MultiAward tmp;
			uint16 ratio = mgr.GetFaBaoSouSuo(sid);
			--m_faBaoCnt;
			amgr.GetActivityDrop(pUser, 9, 1, tmp);
			cnt++;
			uint16 res = Random(1, 100);
			if (res < ratio)
			{
				SAwardData ad;
				ad.type = sid;
				ad.num = 1;
				MergeAwardData(tmp, ad);
				MakeMultiAwardMsg(tmp, msg);
				MergeAwardList(awards, tmp);
				break;
			}
			MakeMultiAwardMsg(tmp, msg);
			MergeAwardList(awards, tmp);
			if (use == 1 && m_faBaoCnt <= 0 && itemCnt > 0)
			{
				useCnt++;
				itemCnt--;
				m_faBaoCnt += addCnt;

			}
			if (m_faBaoCnt <= 0)
				break;
		}
		if (use == 1 && m_faBaoCnt <= 0 && itemCnt > 0)
		{
			useCnt++;
			itemCnt--;
			m_faBaoCnt += addCnt;

		}
	}
	uint32 now = GetSysTime();
	if (m_lastCntTime == 0 && m_faBaoCnt < CItemCfgManager::CfgFBMaxCnt)
		m_lastCntTime = now;

	uint32 sec = now + CItemCfgManager::CfgFBAddSec - m_lastCntTime;
	msg.WriteData(pos, &cnt, sizeof(cnt));
	msg << m_faBaoCnt << sec << useCnt;
	pUser->DelPackageById(stoneId, useCnt);
	pUser->AddMultiAward(awards);
	pUser->AddExtData16(ED16_71, cnt);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_14, cnt);
}

void CEquipManeger::FaBaoHeCheng(CUser* pUser, CNetMessage& msg)
{
	uint16 fid;
	msg >> fid;
	CItemCfgManager& mgr = sCItemCfgManager;
	ComposeCfg* hcCfg = mgr.GetComposeCfg(CPT_FABAO_HC, fid);
	if (hcCfg == NULL)
		return;

	if (!pUser->UseMultiCost(hcCfg->costs))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0174, TIPS_FAILURE_COLOR);
		return;
	}

	AddFaBao(pUser, hcCfg->tar.typeId);
	FaBaoCfg* cfg = mgr.GetFaBaoCfg(hcCfg->tar.typeId);
	if (cfg != NULL)
		sCMissionManager.UpdateQuestState(pUser, EMQCT_34, 1, cfg->quality);
	char buf[256];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0213, GetFaBaoName(hcCfg->tar.typeId));
	msg << PRO_SUCCESS << MakeStringColor(buf, TIPS_WARNING_COLOR);

	if (cfg != NULL && cfg->quality >= 5 && cfg->id != 617)
	{
		char buf[128];
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0233, pUser->GetName(), mgr.GetFaBaoColorName(fid).c_str());
		SysInfoToAllUser(buf);
	}
}

void CEquipManeger::AutoHeChengFaBao(CUser* pUser, CNetMessage& msg)
{
	CItemCfgManager& mgr = sCItemCfgManager;
	ComposeCfgMap* cmap = mgr.GetComposeCfgMap(CPT_FABAO_HC);
	if (cmap == NULL)
		return;
	MultiAward awards;
	for (ComposeCfgMapIt it = cmap->begin(); it != cmap->end(); ++it)
	{
		ComposeCfg& cfg = it->second;
		SAwardData ad;
		ad.type = HDAT_FaBao;
		ad.typeId = cfg.tar.typeId;
		ad.num = 0;
		FaBaoCfg* fcfg = mgr.GetFaBaoCfg(ad.typeId);
		if (fcfg == NULL) continue;
		while (pUser->UseMultiCost(cfg.costs))
		{
			pUser->AddMaterial(cfg.tar.type, ad.typeId);
			if (fcfg->quality >= 5 && ad.typeId != 617)
			{
				char buf[128];
				snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0233, pUser->GetName(), mgr.GetFaBaoColorName(ad.typeId).c_str());
				SysInfoToAllUser(buf);
			}
			ad.num++;
		}
		if (ad.num > 0)
		{
			awards.push_back(ad);
			sCMissionManager.UpdateQuestState(pUser, EMQCT_34, ad.num, fcfg->quality);
		}
	}
	msg << PRO_SUCCESS;
	MakeMultiAwardMsg(awards, msg);
}

void CEquipManeger::EChongShengChaXun(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint8 num;
	msg >> type >> num;
	MultiCost costs;
	for (size_t i = 0; i < num; i++)
	{
		uint32 id;
		msg >> id;
		MultiCost tmp;
		CEquip* equip = GetEqiup(id);
		if (equip == NULL)
			return;

		equip->GetChongSheng(tmp, type);
		MergeMultiCost(costs, tmp);
	}
	
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)32 << type;
	MakeMultiCostMsg(costs, msg);
}

void CEquipManeger::EChongSheng(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint8 num;
	msg >> type >> num;
	MultiCost costs;

	if (type == 1 && pUser->GetTongBao() < 50 * num)
		return;
	for (size_t i = 0; i < num; i++)
	{
		uint32 id;
		msg >> id;
		MultiCost tmp;
		CEquip* equip = GetEqiup(id);
		if (equip == NULL)
			return;

		equip->GetChongSheng(tmp, type);
		MergeMultiCost(costs, tmp);
		DelEquip(pUser, id);
	}
	pUser->AddMultiCost(costs);
	if (type == 1)
	{
		pUser->SubMaterial(HDAT_YB, 50 * num);
		ItemCurrencyLog(pUser->GetRoleId(), MUT_EChongSheng, num, HDAT_YB, 50 * num, pUser->GetMaterial(HDAT_YB), MUT_EChongSheng);
	}
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)33 << type;
	MakeMultiCostMsg(costs, msg);
}

void CEquipManeger::FChongShengChaXun(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint8 num;
	msg >> type >> num;
	if (type == 1 && pUser->GetTongBao() < 50 * num)
		return;
	MultiCost mergeCost;
	uint32 id;
	CItemCfgManager& mgr = sCItemCfgManager;
	for (size_t i = 0; i < num; i++)
	{
		msg >> id;
		FaBao* fabao = GetFaBao(id);
		if (fabao == NULL)
			return;
		ComposeCfg* cfg = mgr.GetComposeCfg(CPT_FABAO_FJ, fabao->id);
		if (cfg == NULL) continue;
		MultiCost costs;
		fabao->GetChongSheng(costs, type);
		MergeMultiCost(mergeCost, costs);
	}
	msg.ReWrite();
	msg.SetType(PET_EQUIP_OPERATE);
	msg << (uint8)34 << type;
	MakeMultiCostMsg(mergeCost, msg);
}

void CEquipManeger::FChongSheng(CUser* pUser, CNetMessage& msg)
{
	uint8 type;
	uint8 num;
	msg >> type >> num;
	if (type == 1 && pUser->GetTongBao() < 50 * num)
		return;
	MultiCost mergeCost;
	uint32 id;
	CItemCfgManager& mgr = sCItemCfgManager;
	for (size_t i = 0; i < num; i++)
	{
		msg >> id;
		FaBao* fabao = GetFaBao(id);
		if (fabao == NULL)
			return;
		MultiCost costs;
		fabao->GetChongSheng(costs, type);
		fabao->exp = 0;
		if (type == 2)
		{
			ComposeCfg* cfg = mgr.GetComposeCfg(CPT_FABAO_FJ, fabao->id);
			if (cfg == NULL) continue;
			DelFaBao(pUser, id);
		}
		else
		{
			fabao->ycLv.clear();
			UpdateFabao(pUser, fabao);
		}
		MergeMultiCost(mergeCost, costs);
	}
	pUser->SubMaterial(HDAT_BANG_YB, 50 * num);
	ItemCurrencyLog(pUser->GetRoleId(), MUT_FChongSheng, num, HDAT_YB, 50 * num, pUser->GetMaterial(HDAT_YB), MUT_FChongSheng);
	pUser->AddMultiCost(mergeCost);
}

void CEquipManeger::CheckCnt(CUser* pUser)
{
	uint32 now = GetSysTime();
	if (m_faBaoCnt >= CItemCfgManager::CfgFBMaxCnt)
		return;

	uint32 sec = now - m_lastCntTime;
	uint8 addCnt = sec / CItemCfgManager::CfgFBAddSec;
	m_faBaoCnt += addCnt;
	if (addCnt > 0)
		m_lastCntTime += addCnt * CItemCfgManager::CfgFBAddSec;
	if (m_faBaoCnt >= CItemCfgManager::CfgFBMaxCnt)
	{
		m_faBaoCnt = CItemCfgManager::CfgFBMaxCnt;
		m_lastCntTime = 0;
	}

	if (addCnt > 0)
		TrapSouSuoCnt(pUser);
}

void CEquipManeger::AddSouSuoCnt(CUser* pUser, uint16 cnt)
{
	m_faBaoCnt += cnt;
	if (m_faBaoCnt >= CItemCfgManager::CfgFBMaxCnt)
		m_lastCntTime = 0;
	TrapSouSuoCnt(pUser);
}

void CEquipManeger::TrapSouSuoCnt(CUser* pUser)
{
	CNetMessage trap;
	trap.SetType(PET_EQUIP_OPERATE);
	trap << (uint8)31;
	uint32 now = GetSystemTime();
	uint32 sec = 0;
	if (m_lastCntTime > 0)
		sec = m_lastCntTime + CItemCfgManager::CfgFBAddSec - now;
	trap << m_faBaoCnt << sec;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), trap);
}

void CEquipManeger::ClearJingLian(CUser* pUser)
{
	for (EquipMapIt it = m_petEquips.begin(); it != m_petEquips.end(); ++it)
	{
		it->second.strongLevel[EST_JINGLIAN] = 0;
	}
	pUser->SubMaterial(610, pUser->GetMaterial(610));
	pUser->SubMaterial(611, pUser->GetMaterial(611));
	pUser->SubMaterial(612, pUser->GetMaterial(612));
	pUser->SubMaterial(613, pUser->GetMaterial(613));
}

#if _DEBUG
void CEquipManeger::QiangHuaAllEquip(CUser* pUser, uint8 type, uint8 lv)
{
	for (AllWearEquipSuitMapIt it = m_formationEquips.begin(); it != m_formationEquips.end(); ++it)
	{
		WearEquipSuit& wearEquips = it->second;
		FormationEquipMap& emap = wearEquips.wearEquips;
		for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
		{
			if (type < EST_FBQIANGHUA)
			{
				CEquip* equip = GetEqiup(eit->second);
				if (equip == NULL)
					continue;
				equip->strongLevel[type] = lv;
				equip->InitAttr();
				UpdateEquip(pUser, equip);
			}
			else
			{
				FaBao* fabao = GetFaBao(eit->second);
				if (fabao == NULL)
					continue;
				fabao->ycLv[type] = lv;
				fabao->InitAttr();
				UpdateFabao(pUser, fabao);
			}
		}
	}
}
#endif

uint8 CEquipManeger::GetYCLevelCnt(uint8 type, uint16 lv)
{
	uint8 cnt = 0;
	for (AllWearEquipSuitMapIt it = m_formationEquips.begin(); it != m_formationEquips.end(); ++it)
	{
		WearEquipSuit& wearEquips = it->second;
		FormationEquipMap& emap = wearEquips.wearEquips;
		for (FormationEquipMapIt eit = emap.begin(); eit != emap.end(); ++eit)
		{
			if (type < EST_FBQIANGHUA)
			{
				CEquip* equip = GetEqiup(eit->second);
				if (equip == NULL)
					continue;
				if (lv <= equip->GetYangChengLevel(type))
					cnt++;
			}
			else
			{
				FaBao* fabao = GetFaBao(eit->second);
				if (fabao == NULL)
					continue;
				if (lv <= fabao->GetYangChengLevel(type))
					cnt++;
			}
		}
	}
	return cnt;
}
