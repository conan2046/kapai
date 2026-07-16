#include "config_para.h"
#include "user_spirit.h"
#include "pet_equip_manage.h"
#include "init.h"
#include "arena.h"
#include "xun_bao_manage.h"
#include "user_guanqia.h"
#include "blood_fight_manage.h"

CParaMgr::CParaMgr()
{

}

bool CParaMgr::Init()
{
	const string file = "config.json";
	//                    0            1              2
	const char* fields[] = {"name",            "type",              "value"};
	const int types[] = {   EJPT_STRING,  EJPT_STRING, EJPT_STRING};
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
	{
		cout<< ">> CParaMgr::Init  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		string key = data[fields[0]].GetString();
		SParaData cfg;
		cfg.type = data[fields[1]].GetString();
		cfg.val = data[fields[2]].GetString();
		if(!CheckFieldType(cfg.type))
		{
			cout<< ">> CParaMgr::Init   type error ,  idx="<< i << ", type=" << cfg.type << endl;
		}
		if (key == "stamina")
			ReadSpirit(cfg.val);
		else if (key == "fabao_counts")
			ReadFaBaoSouSuo(cfg.val);
		else if (key == "arena_counts")
			ReadArena(cfg.val);
		else if (key == "kunlun_counts")
			CXunBaoManage::XUNBAO_FIGHT_CNT = atoi(cfg.val.c_str());
		else if (key == "xianyao_times")
			CGuanQiaCfgMgr::g_LieZhuanCnt = atoi(cfg.val.c_str());
		else if (key == "change_name_cost")
			ReadAward(cfg.val, m_gaiMing);
		else if (key == "change_name_gangs")
			ReadAward(cfg.val, m_bangGaiMing);
		else if (key == "kunlun_buy")
			ReadKunLunBuy(cfg.val);
		else if (key == "xiulian_attr")
			ReadXiuLianAttr(cfg.val);
		else if (key == "xiulian_cost")
			CHeroCfgManager::g_xlItemId = atoi(cfg.val.c_str());
		m_data.insert(make_pair(key, cfg));
	}
	return true;
}

bool CParaMgr::GetData(string key, SParaData &value)
{
	if(key.empty())
		return false;

	map<string, SParaData>::iterator it = m_data.find(key);
	if(it == m_data.end())
		return false;
	value = it->second;
	return true;
}

int CParaMgr::GetInt(string key)
{
	if(key.empty())
		return ErrInt;
	
	SParaData v;
	if(!SingletonCParaMgr::instance().GetData(key, v))
		return ErrInt;
	ToLower(v.type);
	if(v.type == "int" && !v.val.empty())
		return atoi(v.val.c_str());
	else if (v.type == "arrays" && !v.val.empty())
		ReadSpirit(v.val);
	return ErrInt;
}

string CParaMgr::GetString(string key)
{
	if(key.empty())
		return "";
	
	SParaData v;
	if(!SingletonCParaMgr::instance().GetData(key, v))
		return "";
	ToLower(v.type);
	if(v.type == "string" && !v.val.empty())
		return v.val;
	return "";
}

void CParaMgr::ReadSpirit(string & val)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	int fullSpirit = 0;
	int maxSpirit = 0;
	int freeSpirit = 0;
	if (arrt.IsArray() && arrt.Size() == 3)
	{
		fullSpirit = arrt[0].GetInt();
		maxSpirit = arrt[1].GetInt();
		freeSpirit = arrt[2].GetInt();
	}
	else if (sscanf(val.c_str(), "%d,%d,%d", &fullSpirit, &maxSpirit, &freeSpirit) != 3)
	{
		return;
	}
	if (fullSpirit <= 0 || maxSpirit < fullSpirit || freeSpirit <= 0)
		return;
	CUserSpirit::FULL_SPIRIT = (uint16)fullSpirit;
	CUserSpirit::MAX_SPIRIT = (uint16)maxSpirit;
	CUserSpirit::FREE_SPIRIT = (uint16)freeSpirit;
}

void CParaMgr::ReadFaBaoSouSuo(string& val)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	if (!arrt.IsArray() || arrt.Size() != 3)
		return;
	CItemCfgManager::CfgFBStartCnt = arrt[0].GetInt();
	CItemCfgManager::CfgFBAddSec = arrt[1].GetInt() * 60;
	CItemCfgManager::CfgFBMaxCnt = arrt[2].GetInt();
}

void CParaMgr::ReadArena(string& val)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	if (!arrt.IsArray() || arrt.Size() != 2)
		return;
	CArenaCfgMgr::FreeCnt = arrt[0].GetInt();
	CArenaCfgMgr::BuyCnt = arrt[1].GetInt() * 60;
}


bool CParaMgr::CheckFieldType(string &type)
{
	ToLower(type);
	
	const string typeArr[] = {"int", "string", "array", "arrays"};
	for(uint16 i=0; i < sizeof(typeArr)/sizeof(typeArr[0]); i++)
	{
		if(type == typeArr[i])
		{
			return true;
		}
	}
	return false;
}

void CParaMgr::ReadAward(string& val, SAwardData& ad)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	ReadSingleAward(arrt, ad);
}

void CParaMgr::ReadKunLunBuy(string& val)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	if (!arrt.IsArray())
		return;
	for (uint8 i = 0; i<arrt.Size(); ++i)
	{
		int cost = arrt[i].GetInt();
		CXunBaoManage::BuyCost.push_back(cost);
	}
}

void CParaMgr::ReadXiuLianAttr(string& val)
{
	rapidjson::Document d;
	rapidjson::Value& arrt = (rapidjson::Value&)d.Parse(val.c_str());
	if (!arrt.IsArray())
		return;
	CHeroCfgManager::g_xiuLianAttrAdd.clear();
	for (uint8 i = 0; i < arrt.Size(); ++i)
	{
		const rapidjson::Value &sarr = arrt[i];
		if (!sarr.IsArray() || sarr.Size() < 2)
			return;
		uint8 atype = sarr[0].GetInt();
		uint8 avlue = sarr[1].GetInt();
		CHeroCfgManager::g_xiuLianAttrAdd[atype] = avlue;
	}
}
