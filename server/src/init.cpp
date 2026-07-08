#include "init.h"
#include "pet.h"
#include "pack_deal.h"
#include "mission_manager.h"
#include "tower_reward_manager.h"
#include "chuangguan_reward_manager.h"
#include "user_guanqia.h"
#include "hero_cfg_manager.h"
#include "chou_ka_manager.h"
#include "blood_fight_manage.h"
#include "user_shop_manage.h"
#include "utility.h"
#include "arena.h"
#include "config_para.h"
#include "user_spirit.h"
#include <math.h>
#include <sstream>
#include <fstream>
#include <iostream>

bool InitJsonConfig()
{
	gyu::util::TimePrint t("InitJsonConfig()");

	cout << "[local] InitJsonConfig: CParaMgr" << endl;
	if(!SingletonCParaMgr::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CRobotMgr" << endl;
	if(!SingletonCRobotMgr::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CArenaCfgMgr" << endl;
	if(!SingletonCArenaCfgMgr::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CFightCfgManager" << endl;
	if(!SingletonCFightCfgManager::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CMissionManager" << endl;
	if(!SingletonCMissionManager::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CBP_CfgMgr" << endl;
	if(!SingletonCBP_CfgMgr::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: CFindResourceMgr" << endl;
	if(!SingletonCFindResourceMgr::instance().Init())
		return false;
	cout << "[local] InitJsonConfig: done" << endl;
	return true;
}

bool InitXMLConfig()
{
	gyu::util::TimePrint t("InitXMLConfig()");
	if(!SingletonMountCfgMgr::instance().Init())
		return false;
	if(!SingletonWingCfgMgr::instance().Init())
		return false;
	if(!SingletonShenQiCfgMgr::instance().Init())
		return false;
	if(!SingletonTeamFaBuCfgMgr::instance().Init())
		return false;
	if(!SingletonCPetDrawCfgMgr::instance().Init())
		return false;
	if(!SingletonCYaoQianShuMgr::instance().Init())
		return false;
	if(!SingletonCZhenFaCfgMgr::instance().Init())
		return false;
	if(!SingletonCAttrCfgMgr::instance().Init())
		return false;
	if(!SingletonCUserCfgMgr::instance().Init())
		return false;
	if(!SingletonCEquipCfgMgr::instance().Init())
		return false;
	if(!SingletonCJingJieMgr::instance().Init())
		return false;
	
	if(!SingletonCPetCfgMgr::instance().Init())
		return false;
	if(!SingletonCFengShenMgr::instance().Init())
		return false;

	if(!SingletonMonsterBossManager::instance().Init())
		return false;
	if (!sTitltAttrCfgManager.Init())
		return false;
	if (!sSystemOpenCfgMananger.Init())
		return false;
	if (!sRoleSkillLvUpCfgMananger.Init())
		return false;
	if (!sTowerRewardManager.Init())
		return false;
	if(!SingletonCSkillMgr::instance().Init())
		return false;
	if (!sChuangguanRewardManager.Init())
		return false;
	if (!sCChuangGuanMapManager.Init())
		return false;
	if(!SingletonCBPHuoYueCfgMgr::instance().Init())
		return false;
	if(!SingletonCBPRewardCfgMgr::instance().Init())
		return false;
	if(!sCBPLianQiCfgMgr.Init())
		return false;
	if(!sCBPSkillCfgMgr.Init())
		return false;
	if(!sCGuanQiaCfgMgr.InitMap())
		return false;
	if(!sCHeroCfgManager.InitHeroCfg())
		return false;
	if (!sCItemCfgManager.InitAllCfg())
		return false;
	if (!sCChouKaCfgManager.InitChouKaCfg())
		return false;
	if (!sCBloodFightCfgManager.InitBloodFightCfg())
		return false;
	if (!sShopCfgManager.InitCfg())
		return false;
	if (!sCUserSpiritCfg.InitSpiritCfg())
		return false;
	if (!sCHuoDongManage.InitHuoDongCfg())
		return false;
	return true;
}

///////////////////////////////////////////////////////////////////////////////////////////
bool LoadJosnValue(const string& file, const char** titleArrs, const int* typeArrs, int size, rapidjson::Document& d, rapidjson::Value &_para)
{
	const string JSON_PATH = "./json/";
	string fileName = JSON_PATH + file;
	std::ifstream f(fileName.c_str());
	if (!f.is_open()) {
		cout << file << " >> open file error : " << fileName << endl;
		return false;
	}
	cout << file << " >> load : " << fileName << endl;
	std::string jsonStr((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
	f.close();
	if (d.Parse(jsonStr.c_str()).HasParseError())
	{
		cout << file << " >> Parse Json error " << endl;
		return false;
	}
	// if (!d.HasMember(file.c_str()))
	// {
		// cout << file << " >> HasMember() args=" << file << "  error " << endl;
		// return false;
	// }
	_para = (rapidjson::Value&)d;
	if (!_para.IsArray())
	{
		cout << fileName << " >> JsonCheck IsArray()  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		for (int ci = 0; ci < size; ++ci)
		{
			const char* tmp = titleArrs[ci];
			if (tmp == NULL)
			{
				cout << fileName << " >> titleArrs error at row " << ci << endl;
				return false;
			}
			switch (typeArrs[ci])
			{
			case EJPT_INT:
				if (!data.HasMember(tmp) || !data[tmp].IsInt())
				{
					cout << fileName << " >> JsonCheck " << tmp << " cfg  error , idx " << i << endl;
					return false;
				}
				break;
			case EJPT_STRING:
				if (!data.HasMember(tmp) || !data[tmp].IsString())
				{
					cout << fileName << " >> JsonCheck " << tmp << " cfg  error, idx " << i << endl;
					return false;
				}
				break;
			case EJPT_ARRAY:
			case EJPT_ARRAYS:
				if (!data.HasMember(tmp) || !data[tmp].IsArray())
				{
					cout << fileName << " >> JsonCheck " << tmp << " cfg  error, idx " << i << endl;
					return false;
				}
				break;
			case EJPT_INT64:
				if (!data.HasMember(tmp) || !data[tmp].IsInt64())
				{
					cout << fileName << " >> JsonCheck " << tmp << " cfg  error , idx " << i << endl;
					return false;
				}
				break;
			}
		}
	}
	return true;
}

bool ReadSingleAward(const rapidjson::Value &_arr, SAwardData& award)
{
	if (!_arr.IsArray())
	{
		cout << ">> ReadSingleAward cfg  error " << endl;
		return false;
	}
	uint32 size = _arr.Size();
	if (size != 3)
	{
		cout << ">> ReadSingleAward cfg size error " << endl;
		return false;
	}
	award.type = _arr[0].GetInt();
	award.typeId = _arr[1].GetInt();
	award.num = _arr[2].GetInt();
	return true;
}

bool ReadMultiAward(const rapidjson::Value &_arr, MultiAward& awards)
{
	if (!_arr.IsArray())
	{
		cout<<">> ReadMultiAward cfg  error "<<endl;
		return false;
	}
	for(uint32 j=0; j < _arr.Size() ; j++)
	{
		const rapidjson::Value &_pArr = _arr[j];
		if(!_pArr.IsArray())
		{
			cout<<">> ReadMultiAward cfg  error , j="<<j<<endl;
			continue;
		}
		uint32 size = _pArr.Size();
		if(size != 3)
		{
			cout<<">> ReadMultiAward cfg size error , j="<<j<<endl;
			continue;
		}
		SAwardData v;
		v.type = _pArr[0].GetInt();
		v.typeId = _pArr[1].GetInt();
		v.num = _pArr[2].GetInt();
		if(v.type > 0)
			awards.push_back(v);
	}
	return true;
}

bool ReadSingleCost(const rapidjson::Value &_pArr, SCostData& v)
{
	if (!_pArr.IsArray())
		return false;
	uint32 size = _pArr.Size();
	if (size != 3)
		return false;
	v.costType = _pArr[0].GetInt();
	v.typeId = _pArr[1].GetInt();
	v.costValue = _pArr[2].GetInt();
	return true;
}

bool ReadMultiCost(const rapidjson::Value &_arr, MultiCost& costs)
{
	if (!_arr.IsArray())
	{
		cout<<">> ReadMultiCost cfg  error "<<endl;
		return false;
	}
	for(uint32 j=0; j < _arr.Size() ; j++)
	{
		SCostData v;
		if (ReadSingleCost(_arr[j], v))
			costs.push_back(v);
	}
	return true;
}

bool ReadSingleAttr(const rapidjson::Value &_arr, SAttrData& attr)
{
	if (!_arr.IsArray())
	{
		return false;
	}
	if (_arr.Size() == 2)
	{
		attr.attrType = _arr[0].GetInt();
		attr.attrValue = _arr[1].GetInt();
	}
	return true;
}

bool ReadMultiAttr(const rapidjson::Value &_arr, MultiAttr& attrs)
{
	if (!_arr.IsArray())
	{
		cout<<">> ReadMultiAttr cfg  error "<<endl;
		return false;
	}
	for(uint32 j=0; j < _arr.Size() ; j++)
	{
		const rapidjson::Value &_pArr = _arr[j];
		if(!_pArr.IsArray())
		{
			cout<<">> ReadMultiAttr cfg  error , j="<<j<<endl;
			continue;
		}
		uint32 size = _pArr.Size();
		if(size != 2)
		{
			cout<<">> ReadMultiAttr cfg size error , j="<<j<<endl;
			continue;
		}
		SAttrData attr;
		attr.attrType = _pArr[0].GetInt();
		attr.attrValue = _pArr[1].GetInt();
		attrs.push_back(attr);
	}
	return true;
}

bool ReadTupoAttr(const rapidjson::Value &_arr, TupoAttrVec& attrs)
{
	if (!_arr.IsArray())
	{
		cout<<">> ReadTupoAttr cfg  error "<<endl;
		return false;
	}
	for(uint32 j = 0; j < _arr.Size() ; j++)
	{
		const rapidjson::Value &sTupo = _arr[j];
		if(!sTupo.IsArray())
		{
			cout << ">> ReadTupoAttr sTupo  error , sTupo idx " << j <<endl;
			continue;
		}
		TupoAttr tAttr;
		for (uint32 ai = 0; ai < sTupo.Size(); ++ai)
		{
			const rapidjson::Value &sattr = sTupo[ai];
			if(!sattr.IsArray())
			{
				cout << ">> ReadTupoAttr sattr  error , sTupo idx " << j << "sattr Idx" << ai <<endl;
				continue;
			}
			
			if(sattr.Size() != 3)
			{
				cout << ">> ReadTupoAttr sattr size error , sTupo idx " << j << "sattr Idx" << ai <<endl;
				continue;
			}
			int type = sattr[0].GetInt();
			SAttrData attr;
			attr.attrType = sattr[1].GetInt();
			attr.attrValue = sattr[2].GetInt();
			switch (type)
			{
			case 1:
				tAttr.selfAttrs.push_back(attr);
				break;

			case 2:
				tAttr.teamAttrs.push_back(attr);
				break;

			case 3:
				tAttr.skillAttrs.push_back(attr);
				break;

			default:
				continue;
			}
		}
		attrs.push_back(tAttr);
	}
	return true;
}

bool ReadMultiSkill(const rapidjson::Value &_arr, vector<SSkillData>& skills)
{
	if (!_arr.IsArray())
	{
		cout << ">> ReadMultiSkill cfg  error " << endl;
		return false;
	}
	for (uint32 j = 0; j < _arr.Size(); j++)
	{
		const rapidjson::Value &sarr = _arr[j];
		if (!sarr.IsArray()|| sarr.Size() != 2)
		{
			cout << ">> ReadMultiSkill sarr  error , sarr idx " << j << endl;
			continue;
		}
		SSkillData sk;
		sk.id = sarr[0].GetInt();
		sk.level = sarr[1].GetInt();
		skills.push_back(sk);
	}
	return true;
}

bool ReadMultiTypeValue(const rapidjson::Value &_arr, MultiTypeValue& tvs)
{
	if (!_arr.IsArray())
	{
		cout << ">> ReadMultiTypeValue cfg  error " << endl;
		return false;
	}
	for (uint8 i = 0; i < _arr.Size(); ++i)
	{
		TypeValue tv;
		ReadSingleTypeValue(_arr[i], tv);
		if (tv.type != 0)
			tvs.push_back(tv);
	}
	return true;
}

bool ReadSingleTypeValue(const rapidjson::Value &_arr, TypeValue& tv)
{
	if (!_arr.IsArray() || _arr.Size() != 2)
	{
		return false;
	}
	tv.type = _arr[0].GetInt();
	tv.value = _arr[1].GetInt();
	return true;
}

void MakeFightEndMsg(CUser* pUser, uint8 star, CNetMessage& msg, MultiAward* awards /*= NULL*/, int addType/* = 0*/)
{
	msg << star;
	if (awards == NULL)
		msg << (uint8)0;
	else
		SendAndMakeAwardMsg(pUser, *awards, msg, false, addType);
}

void MakeMultiAwardMsg(std::vector<SAwardData> &awvec, CNetMessage& msg)
{
	msg << (uint8)awvec.size();
	for (uint16 i = 0; i < awvec.size(); ++i)
	{
		MakeAwardMsg(awvec[i], msg);
	}
}

void MakeSingleAwardMsg(CUser* pUser, SAwardData& award, CNetMessage& msg)
{
	MakeAwardMsg(award, msg);
	if (award.type == HDAT_PET)
	{
		if (pUser->HavePet(award.typeId))
		{
			SPetBasicData* pData = SingletonCPetCfgMgr::instance().GetPetCfg(award.typeId);
			if (pData != NULL)
			{
				msg << pData->shengxingItemId << (uint32)pData->transferItemNum;
			}
			else
				msg << (uint16)0 << (uint32)0;
		}
		else
			msg << (uint16)0 << (uint32)0;
	}
}

void MergeMultiCost(MultiCost &inCost, MultiCost &outCosts)
{
	for (uint16 i = 0; i < outCosts.size(); i++)
	{
		MergeSigleCost(inCost, outCosts[i]);
	}
}

void MergeSigleCost(MultiCost &inCost, SCostData &outCost)
{
	bool find = false;
	for (uint16 j = 0; j < inCost.size(); j++)
	{
		SCostData &left = inCost[j];
		if (left.costType != outCost.costType)
			continue;
		find = true;
		switch (left.costType)
		{
		case HDAT_PET:
		case HDAT_SHENQI:
		//case HDAT_FaBao:
			inCost.push_back(outCost);
			return;
		default:
			left.costValue += outCost.costValue;
			return;
		}
	}
	inCost.push_back(outCost);
}

void MakeSingleCostMsg(SCostData& cost, CNetMessage& msg)
{
	msg << cost.costType << cost.typeId << cost.costValue;
}

void MakeMultiCostMsg(MultiCost& costs, CNetMessage& msg)
{
	msg << (uint8)costs.size();
	for (size_t i = 0; i < costs.size(); i++)
	{
		SCostData& cost = costs[i];
		MakeSingleCostMsg(cost, msg);
	}
}

void MakeAwardMsg(SAwardData& ad, CNetMessage& msg)
{
	msg << (uint16)ad.type << ad.typeId << ad.num;
}

// 发送奖励并拼接消息
void SendAndMakeAwardMsg(CUser *pUser, std::vector<SAwardData> &awvec, CNetMessage& msg, bool showMsg/* = false*/, int addType/* = 0*/)
{
	msg << (uint8)awvec.size();
	for (uint16 i = 0; i < awvec.size(); ++i)
	{
		SAwardData& award = awvec[i];
		MakeAwardMsg(award, msg);
		pUser->AddMaterial(award, true, showMsg);
		if (addType > 0 && award.type >= HDAT_MONEY)
		{
			ItemCurrencyLog(pUser->GetRoleId(), addType, 1, award.type, award.num, pUser->GetMaterial(award.type), addType);
		}
	}
}


bool CMountConfigMgr::Init()
{
	m_mountList.clear();

	{
		vector<map<string,string> > data;
		//                     0       1        2           3             4             5          6     7    8       9           10          11
		const char *keys[] = {"mount_id","name","getway_type","getway_num","getway_itemid","buy_time_limit","speed","attr","desc","error_msg","target_jinjieid","jinjie_cost"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("mount_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SMountConfig t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.name = data[i][keys[1]];
			t.getWay = atoi(data[i][keys[2]].c_str());
			t.getWay_num = atoi(data[i][keys[3]].c_str());
			t.getWay_itemId = atoi(data[i][keys[4]].c_str());
			t.buy_time_limit = atoi(data[i][keys[5]].c_str());
			t.moveSpeed = atoi(data[i][keys[6]].c_str());
			SetAttrData(t.attrList,data[i][keys[7]]);
			t.desc = data[i][keys[8]];
			t.error_msg = data[i][keys[9]];
			t.jinjieId = atoi(data[i][keys[10]].c_str());
			SetAwardData(t.jinjie_cost,data[i][keys[11]]);
			m_mountList.insert(make_pair(t.id,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0      1       2
		const char *keys[] = {"level","needExp","attr"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("mount_qianghua.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SMountQH t;
			t.level = atoi(data[i][keys[0]].c_str());
			t.needExp = atoi(data[i][keys[1]].c_str());
			SetAttrData(t.attrList,data[i][keys[2]]);
			m_qhList.insert(make_pair(t.level,t));
		}
	}
	return true;
}

SMountConfig *CMountConfigMgr::GetCfg(int id)
{
	map<int,SMountConfig>::iterator it = m_mountList.find(id);
	if(it != m_mountList.end())
		return &(it->second);
	return NULL;
}

SMountQH *CMountConfigMgr::GetQHCfg(int lv)
{
	map<int,SMountQH>::iterator it = m_qhList.find(lv);
	if(it != m_qhList.end())
		return &(it->second);
	return NULL;
}

void CMountConfigMgr::GetMountList(vector<int> &var)
{
	var.clear();
	for(map<int,SMountConfig>::iterator it = m_mountList.begin(); it != m_mountList.end(); it++)
		var.push_back(it->first);
}


///////////////////////////////////////////////////////////////////////////////////////

bool CWingConfigMgr::Init()
{
	m_wingList.clear();

	{
		vector<map<string,string> > data;
		//                     0      1        2           3             4        5     6       7
		const char *keys[] = {"wing_id","name","getway_type","getway_num","getway_itemid","attr","desc","error_msg"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("wing_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SWingConfig t;
			t.wing_id = atoi(data[i][keys[0]].c_str());
			t.name = data[i][keys[1]];
			t.getWay = atoi(data[i][keys[2]].c_str());
			t.getWay_Num = atoi(data[i][keys[3]].c_str());
			t.getWay_itemId = atoi(data[i][keys[4]].c_str());
			SetAttrData(t.attrList,data[i][keys[5]]);
			t.des_info = data[i][keys[6]];
			t.err_info = data[i][keys[7]];
			m_wingList.insert(make_pair(t.wing_id,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0    1      2       3
		const char *keys[] = {"level","star","needExp","attr"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("wing_qianghua.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SWingQH t;
			t.level = atoi(data[i][keys[0]].c_str());
			t.star = atoi(data[i][keys[1]].c_str());
			t.needExp = atoi(data[i][keys[2]].c_str());
			SetAttrData(t.attrList,data[i][keys[3]]);
			int key = t.level*100 + t.star;
			m_qhList.insert(make_pair(key,t));
		}
	}
	return true;
}

SWingConfig *CWingConfigMgr::GetCfg(int id)
{
	map<int,SWingConfig>::iterator it = m_wingList.find(id);
	if(it != m_wingList.end())
		return &(it->second);
	return NULL;
}

SWingQH *CWingConfigMgr::GetQHCfg(int lv,int star)
{
	int key = lv*100 + star;
	map<int,SWingQH>::iterator it = m_qhList.find(key);
	if(it != m_qhList.end())
		return &(it->second);
	return NULL;
}

void CWingConfigMgr::GetWingList(vector<int> &var)
{
	var.clear();
	for(map<int,SWingConfig>::iterator it = m_wingList.begin(); it != m_wingList.end(); it++)
		var.push_back(it->first);
}


///////////////////////////////////////////////////////////////////////////////////


bool CShenQiConfigMgr::Init()
{
	m_shenqiList.clear();

	{
		vector<map<string,string> > data;
		//                  0    1     2    3
		const char *keys[] = {"id","name","attr","desc"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("shenqi_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SShenQiConfig t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.name = data[i][keys[1]];
			SetAttrData(t.attrList,data[i][keys[2]]);
			t.desc = data[i][keys[3]];
			m_shenqiList.insert(make_pair(t.id,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                   0     1      2        3           4          5        6
		const char *keys[] = {"level","star","needExp","cur_shenqi","next_shenqi","add_shenqi","attr"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("shenqi_peiyang.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			SShenQiPeiYang t;
			t.level = atoi(data[i][keys[0]].c_str());
			t.star = atoi(data[i][keys[1]].c_str());
			t.needExp = atoi(data[i][keys[2]].c_str());
			t.cur_shenqi = atoi(data[i][keys[3]].c_str());
			t.next_shenqi = atoi(data[i][keys[4]].c_str());
			t.add_shenqi = atoi(data[i][keys[5]].c_str());
			SetAttrData(t.attrList,data[i][keys[6]]);
			int key = t.level*100 + t.star;
			m_pyList.insert(make_pair(key,t));
		}
	}
	return true;
}

SShenQiConfig *CShenQiConfigMgr::GetCfg(int id)
{
	map<int,SShenQiConfig>::iterator it = m_shenqiList.find(id);
	if(it != m_shenqiList.end())
		return &(it->second);
	return NULL;
}

const string& CShenQiConfigMgr::GetShenQiName(int id) const
{
	map<int, SShenQiConfig>::const_iterator it = m_shenqiList.find(id);
	if (it != m_shenqiList.end())
		return it->second.name;
	return m_nilStr;
}

SShenQiPeiYang *CShenQiConfigMgr::GetPYCfg(int lv,int star)
{
	int key = lv*100 + star;
	map<int,SShenQiPeiYang>::iterator it = m_pyList.find(key);
	if(it != m_pyList.end())
		return &(it->second);
	return NULL;
}

void CShenQiConfigMgr::GetShenQiList(vector<int> &var)
{
	var.clear();
	for(map<int,SShenQiConfig>::iterator it = m_shenqiList.begin(); it != m_shenqiList.end(); it++)
		var.push_back(it->first);
}


//////////////////////////////////////////////////////////////////////////////////////////////


bool CTeamFaBuConfigMgr::Init()
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	m_cfgList.clear();

	{
		vector<map<string,string> > data;
		//                   0     1      2
		const char *keys[] = {"type","name","openLv"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("team_fabu.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			STeamFaBuCfgData t;
			t.type = atoi(data[i][keys[0]].c_str());
			t.name = data[i][keys[1]];
			t.openLv = atoi(data[i][keys[2]].c_str());
			m_cfgList.insert(make_pair(t.type,t));
		}
	}
	
	return true;
}

STeamFaBuCfgData *CTeamFaBuConfigMgr::GetCfg(int id)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,STeamFaBuCfgData>::iterator it = m_cfgList.find(id);
	if(it != m_cfgList.end())
		return &(it->second);
	return NULL;
}

void CTeamFaBuConfigMgr::GetCfgList(vector<int> &var)
{
	var.clear();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	for(map<int,STeamFaBuCfgData>::iterator it = m_cfgList.begin(); it != m_cfgList.end(); it++)
		var.push_back(it->first);
}

bool CTeamFaBuConfigMgr::InsertFaBuList(int type,uint32 teamId,uint16 minLv,uint16 maxLv)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockInsertFaBuList(type,teamId,minLv,maxLv);
}

bool CTeamFaBuConfigMgr::NoLockInsertFaBuList(int type,uint32 teamId,uint16 minLv,uint16 maxLv)
{
	if(teamId == 0)
		return false;
	
	map<uint32,int>::iterator it = m_teamList.find(teamId);
	if(it != m_teamList.end())
		return false;
	map<int,STeamFaBuCfgData>::iterator cfg = m_cfgList.find(type);
	if(cfg == m_cfgList.end())
		return false;

	m_teamList.insert(make_pair(teamId,type));
	map<int,list<STeamFaBuData> >::iterator r = m_fabuList.find(type);
	if(r == m_fabuList.end())
	{
		pair<map<int,list<STeamFaBuData> >::iterator,bool> res = m_fabuList.insert(make_pair(type,list<STeamFaBuData>()));
		if(res.second)
			r = res.first;
		else
			return false;
	}
	STeamFaBuData data;
	data.teamId = teamId;
	data.minLevel = minLv;
	data.maxLevel = maxLv;
	r->second.push_front(data);
	return true;
}

void CTeamFaBuConfigMgr::RemoveFaBuTeam(int type,uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NoLockRemoveFaBuTeam(type,teamId);
}

void CTeamFaBuConfigMgr::NoLockRemoveFaBuTeam(int type,uint32 teamId)
{
	map<uint32,int>::iterator it = m_teamList.find(teamId);
	if(it != m_teamList.end())
		m_teamList.erase(it);
	
	map<int,list<STeamFaBuData> >::iterator r = m_fabuList.find(type);
	if(r == m_fabuList.end())
		return;
	STeamFaBuData temp;
	temp.teamId = teamId;
	list<STeamFaBuData> &data = r->second;
	list<STeamFaBuData>::iterator res = find(data.begin(),data.end(),temp);
	if(res != data.end())
		data.erase(res);
}

bool CTeamFaBuConfigMgr::GetFaBuList(int type,list<STeamFaBuData> &var)
{
	var.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,list<STeamFaBuData> >::iterator it = m_fabuList.find(type);
	if(it == m_fabuList.end())
	{
		map<int,STeamFaBuCfgData>::iterator t = m_cfgList.find(type);
		if(t == m_cfgList.end())
			return false;
		
		pair<map<int,list<STeamFaBuData> >::iterator,bool> res = m_fabuList.insert(make_pair(type,list<STeamFaBuData>()));
		if(!res.second)
			return false;
		it = res.first;
	}
	var = it->second;
	return true;
}

bool CTeamFaBuConfigMgr::GetFaBuListBackward(int type,list<STeamFaBuData> &var)
{
	var.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,list<STeamFaBuData> >::iterator it = m_fabuList.find(type);
	if(it == m_fabuList.end())
	{
		map<int,STeamFaBuCfgData>::iterator t = m_cfgList.find(type);
		if(t == m_cfgList.end())
			return false;
		
		pair<map<int,list<STeamFaBuData> >::iterator,bool> res = m_fabuList.insert(make_pair(type,list<STeamFaBuData>()));
		if(!res.second)
			return false;
		it = res.first;
	}
	
	for(list<STeamFaBuData>::iterator i = it->second.begin(); i != it->second.end(); i++)
		var.push_front(*i);
	return true;
}

bool CTeamFaBuConfigMgr::FindTeamByType(int type,uint32 teamId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,int>::iterator it = m_teamList.find(teamId);
	if(it == m_teamList.end())
		return false;
	if(it->second != type)
		return false;
	return true;
}

bool CTeamFaBuConfigMgr::GetFaBuTeamInfo(int type,uint32 teamId,STeamFaBuData &var)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	return NoLockGetFaBuTeamInfo(type,teamId,var);
}

bool CTeamFaBuConfigMgr::GetFaBuTeamInfo(uint32 teamId,STeamFaBuData &var,int &type)
{
	if(teamId == 0)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,int>::iterator it = m_teamList.find(teamId);
	if(it == m_teamList.end())
		return false;
	type = it->second;
	return NoLockGetFaBuTeamInfo(type,teamId,var);
}

bool CTeamFaBuConfigMgr::NoLockGetFaBuTeamInfo(int type,uint32 teamId,STeamFaBuData &var)
{
	map<int,list<STeamFaBuData> >::iterator it = m_fabuList.find(type);
	if(it == m_fabuList.end())
		return false;

	STeamFaBuData temp;
	temp.teamId = teamId;
	list<STeamFaBuData> &data = it->second;
	list<STeamFaBuData>::iterator res = find(data.begin(),data.end(),temp);
	if(res != data.end())
	{
		var = *res;
		return true;
	}
	return false;
}

void CTeamFaBuConfigMgr::ChangeTeamIdByType(int type,uint32 srcTeamId,uint32 tarTeamId)
{
	STeamFaBuData srcData;
	if(GetFaBuTeamInfo(type,srcTeamId,srcData))
	{
		RemoveFaBuTeam(type,srcTeamId);
		InsertFaBuList(type,tarTeamId,srcData.minLevel,srcData.maxLevel);
	}
}

void CTeamFaBuConfigMgr::ChangeTeamInfo(int type,uint32 teamId,uint16 minLv,uint16 maxLv)
{
	if(GetCfg(type) == NULL)
		return;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,int>::iterator it = m_teamList.find(teamId);
	if(it == m_teamList.end())
		return;
	int srcType = it->second;
	if(srcType == type)
	{
		map<int,list<STeamFaBuData> >::iterator it = m_fabuList.find(type);
		if(it == m_fabuList.end())
			return;
		STeamFaBuData temp;
		temp.teamId = teamId;
		list<STeamFaBuData> &data = it->second;
		list<STeamFaBuData>::iterator res = find(data.begin(),data.end(),temp);
		if(res != data.end())
		{
			res->minLevel = minLv;
			res->maxLevel = maxLv;
		}
	}
	else
	{
		STeamFaBuData teamData;
		if(!NoLockGetFaBuTeamInfo(srcType,teamId,teamData))
			return;
		NoLockRemoveFaBuTeam(srcType,teamId);
		NoLockInsertFaBuList(type,teamId,minLv,maxLv);
	}
}

void CTeamFaBuConfigMgr::GetMatchRoleList(int type,list<uint32> &var)
{
	var.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,list<uint32> >::iterator it = m_matchRoleList.find(type);
	if(it != m_matchRoleList.end())
		var = it->second;
}

void CTeamFaBuConfigMgr::InsertMatchUser(int type,uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<int,list<uint32> >::iterator it = m_matchRoleList.find(type);
	if(it == m_matchRoleList.end())
	{
		map<int,STeamFaBuCfgData>::iterator t = m_cfgList.find(type);
		if(t == m_cfgList.end())
			return;
		
		pair<map<int,list<uint32> >::iterator,bool> res = m_matchRoleList.insert(make_pair(type,list<uint32>()));
		if(!res.second)
			return;
		it = res.first;
	}

	list<uint32> &matchList = it->second;
	list<uint32>::iterator t = find(matchList.begin(),matchList.end(),roleId);
	if(t == matchList.end())
	{
		matchList.push_back(roleId);
		m_roleMap.insert(make_pair(roleId,type));
	}
}

void CTeamFaBuConfigMgr::RemoveMatchUser(int type,uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	map<uint32,int>::iterator r = m_roleMap.find(roleId);
	if(r != m_roleMap.end())
		m_roleMap.erase(r);
	
	map<int,list<uint32> >::iterator it = m_matchRoleList.find(type);
	if(it == m_matchRoleList.end())
		return;
	list<uint32> &matchList = it->second;
	list<uint32>::iterator t = find(matchList.begin(),matchList.end(),roleId);
	if(t != matchList.end())
		matchList.erase(t);
}

bool CTeamFaBuConfigMgr::PlayerMatchFaBuTeam(int type,uint32 roleId,bool isInsert)
{
	COnlineUser &online = SingletonOnlineUser::instance();
	ShareUserPtr p = online.GetUserByRoleId(roleId);
	if(p.get() == NULL)
		return false;
	uint16 level = p->GetLevel();

	list<STeamFaBuData> teamList;
	if(!GetFaBuListBackward(type,teamList))
		return false;
	for(list<STeamFaBuData>::iterator t = teamList.begin(); t != teamList.end(); t++)
	{
		if(level < t->minLevel || level > t->maxLevel)
			continue;

		ShareUserPtr leader = online.GetUserByRoleId(t->teamId);
		CUser *pLeader = leader.get();
		if(pLeader == NULL)
		{
			RemoveFaBuTeam(type,t->teamId);
			continue;
		}
		CScene *pScene = pLeader->GetScene();
		if(pScene == NULL)
			continue;
		if(!pScene->AllowJoinTeamWithNoNotice(pLeader,roleId))
			continue;
		RemoveMatchUser(type,roleId);
		p->m_autoMatchTeamType = 0;
		return true;
	}

	if(isInsert)
	{
		InsertMatchUser(type,roleId);
		return true;
	}
	return false;
}

bool CTeamFaBuConfigMgr::TeamMatchPlayerList(int type,uint32 teamId)
{
	COnlineUser &online = SingletonOnlineUser::instance();
	ShareUserPtr leader = online.GetUserByRoleId(teamId);
	CUser *pLeader = leader.get();
	if(pLeader == NULL)
		return false;
	CScene *pScene = pLeader->GetScene();
	if(pScene == NULL)
		return false;
	STeamFaBuData teamData;
	if(!GetFaBuTeamInfo(type,teamId,teamData))
		return false;
	
	list<uint32> roleList;
	GetMatchRoleList(type,roleList);
	bool res = false;
	for(list<uint32>::iterator it = roleList.begin(); it != roleList.end(); it++)
	{
		ShareUserPtr p = online.GetUserByRoleId(*it);
		CUser *pU = p.get();
		if(pU == NULL)
		{
			RemoveMatchUser(type,*it);
			continue;
		}

		if(pU->GetLevel() < teamData.minLevel || pU->GetLevel() > teamData.maxLevel)
			continue;
		if(!pScene->AllowJoinTeamWithNoNotice(pLeader,*it))
			continue;
		RemoveMatchUser(type,*it);
		pU->m_autoMatchTeamType = 0;
		res = true;
		if(pScene->GetTeamMemNum(teamId) >= MAX_TEAM_MEMBER)
			return true;
	}
	return res;
}

void CTeamFaBuConfigMgr::MatchTimer()
{
	vector<int> cfgList;
	GetCfgList(cfgList);
	for(uint32 i=0;i < cfgList.size();i++)
	{
		list<STeamFaBuData> teamList;
		int type = cfgList[i];
		GetFaBuList(type,teamList);
		for(list<STeamFaBuData>::iterator it = teamList.begin(); it != teamList.end(); it++)
			TeamMatchPlayerList(type,it->teamId);
	}
}


/////////////////////////////////////////////////////////////////////////////////////////////

bool CPetDrawCfgMgr::Init()
{
	m_cfgList.clear();

	{
		vector<map<string,string> > data;
		//                   0     1       2        3        4             5              6               7                8               9
		const char *keys[] = {"kind","name","open_level","type","need_item_id","need_item_num","need_yuanbao","must_be_out_times","orange_pet_num","save_times_ext8"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_draw_basic.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			uint16 kind = atoi(data[i][keys[0]].c_str());			
			map<uint16,SPetDrawCfgData>::iterator it = m_cfgList.find(kind);
			if(it == m_cfgList.end())
			{
				SPetDrawCfgData cfgData;
				pair<map<uint16,SPetDrawCfgData>::iterator,bool> res = m_cfgList.insert(make_pair(kind,cfgData));
				if(!res.second)
					return false;
				it = res.first;
			}
			it->second.name = data[i][keys[1]];
			it->second.openLv = atoi(data[i][keys[2]].c_str());

			uint16 type = atoi(data[i][keys[3]].c_str());
			map<uint16,SPetDrawPoolData>::iterator poolIt = it->second.awardPool.find(type);
			if(poolIt == it->second.awardPool.end())
			{
				SPetDrawPoolData poolData;
				pair<map<uint16,SPetDrawPoolData>::iterator,bool> res = it->second.awardPool.insert(make_pair(type,poolData));
				if(!res.second)
					return false;
				poolIt = res.first;
			}
			poolIt->second.needItemId = atoi(data[i][keys[4]].c_str());
			poolIt->second.needItemNum = atoi(data[i][keys[5]].c_str());
			poolIt->second.need_YB = atoi(data[i][keys[6]].c_str());
			poolIt->second.must_be_orange_times = atoi(data[i][keys[7]].c_str());
			poolIt->second.orange_pet_num = atoi(data[i][keys[8]].c_str());
			poolIt->second.save_times_ext8 = atoi(data[i][keys[9]].c_str());
		}
	}

	{
		vector<map<string,string> > data;
		//                   0    1       2      3
		const char *keys[] = {"kind","type","award","quanzhong"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("pet_draw_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			uint16 kind = atoi(data[i][keys[0]].c_str());
			uint16 type = atoi(data[i][keys[1]].c_str());
			map<uint16,SPetDrawCfgData>::iterator it = m_cfgList.find(kind);
			if(it == m_cfgList.end())
			{
				cout<<"SPetDrawCfgMgr::Init() cannot find kind="<<kind<<endl;
				continue;
			}
			SPetDrawCfgData &cfg = it->second;
			map<uint16,SPetDrawPoolData>::iterator poolIt = cfg.awardPool.find(type);
			if(poolIt == cfg.awardPool.end())
			{
				SPetDrawPoolData poolData;
				pair<map<uint16,SPetDrawPoolData>::iterator,bool> res = cfg.awardPool.insert(make_pair(type,poolData));
				if(!res.second)
				{
					cout<<"SPetDrawCfgMgr::Init() insert kind="<<kind<<" error!"<<endl;
					continue;
				}
				poolIt = res.first;
			}
			
			SPetDrawPoolData &pool = poolIt->second;
			SPetDrawPoolBasicData basicData;
			SetAward(basicData,data[i][keys[2]]);
			basicData.ratio = atoi(data[i][keys[3]].c_str());
			if(basicData.awardType == 0)
				continue;
			pool.awardList.push_back(basicData);
		}
	}
	return true;
}

bool CPetDrawCfgMgr::MakePetDrawMsg(CUser *pUser,CNetMessage &msg)
{
	if(pUser == NULL)
		return false;
	uint16 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	uint16 level = pUser->GetLevel();
	uint32 curTime = GetSysTime();
	uint32 lastTime = pUser->GetExtData32(92);
	uint32 leftCD = (curTime < lastTime) ? (lastTime - curTime) : 0;
	for(map<uint16,SPetDrawCfgData>::iterator it = m_cfgList.begin(); it != m_cfgList.end(); it++)
	{
		uint16 kind = it->first;
		SPetDrawCfgData &cfg = it->second;
		uint8 isOpen = (level >= cfg.openLv) ? 1 : 0; // 1开启 0未开启
		num++;
		msg<<kind<<isOpen;
		
		uint16 showPetNum = 0;
		uint16 petNumPos = msg.GetDataLen();
		msg<<showPetNum;
		map<uint16,SPetDrawPoolData>::iterator poolIt = cfg.awardPool.find(1);
		if(poolIt == cfg.awardPool.end())
			continue;
		SPetDrawPoolData &poolData = poolIt->second;
		for(uint16 i=0;i < poolData.awardList.size();i++)
		{
			if(poolData.awardList[i].awardType == HDAT_PET)
			{
				msg<<poolData.awardList[i].id;
				showPetNum++;
			}
		}
		msg.WriteData(petNumPos,&showPetNum,sizeof(showPetNum));

		uint16 typeNumPos = msg.GetDataLen();
		uint8 typeNum = 0;
		msg<<typeNum;
		for(poolIt = cfg.awardPool.begin(); poolIt != cfg.awardPool.end(); poolIt++)
		{
			uint16 type = poolIt->first;
			if(type > EPDT_Time10)
				continue;
			uint32 CD = (type == EPDT_Single) ? leftCD : 0;
			SPetDrawPoolData &data = poolIt->second;
			msg<<type<<data.needItemId<<data.needItemNum<<data.need_YB*data.needItemNum;
			if(type == EPDT_Single)
			{
				msg<<CD;
			}
			else if(type == EPDT_Time10)
			{
				int curDraw10Times = pUser->GetExtData8(data.save_times_ext8);
				int mustBeOrangeLeftTimes = (int)data.must_be_orange_times - curDraw10Times;
				if(mustBeOrangeLeftTimes <= 0)
					mustBeOrangeLeftTimes = data.must_be_orange_times;
				msg<<mustBeOrangeLeftTimes;
				msg<<(uint8)(pUser->HaveBitSet(608) ? 0 : 1);	// 是否首次10连抽，1是 0 否
			}
			else
				return false;
			typeNum++;
		}
		msg.WriteData(typeNumPos,&typeNum,sizeof(typeNum));
	}
	msg.WriteData(pos,&num,sizeof(num));
	return true;
}

 bool CPetDrawCfgMgr::DoPetDraw(CUser *pUser,uint16 kind,uint16 type,CNetMessage &msg)
{
	if(pUser == NULL || kind == 0 || type == 0)
		return false;
	map<uint16,SPetDrawCfgData>::iterator it = m_cfgList.find(kind);
	if(it == m_cfgList.end())
		return false;
	SPetDrawCfgData &cfg = it->second;
	if(cfg.openLv > pUser->GetLevel())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0413,TIPS_FAILURE_COLOR);
		return true;
	}

	map<uint16,SPetDrawPoolData>::iterator poolIt = cfg.awardPool.find(type);
	if(poolIt == cfg.awardPool.end())
		return false;
	SPetDrawPoolData &poolData = poolIt->second;
	bool isFree = false;
	if(type == EPDT_Single)	// 判定免费次数
	{
		uint32 curTime = GetSysTime();
		uint32 lastTime = pUser->GetExtData32(92);
		if(curTime >= lastTime)
		{
			isFree = true;
			pUser->SetExtData32(92,curTime+SingleTimeLimit);
		}
	}
	if(!isFree)
	{
		// 扣除道具或元宝
		uint16 itemNum = pUser->GetItemNum(poolData.needItemId);
		if(itemNum >= poolData.needItemNum)	// 优先使用道具抽神将
		{
			pUser->DelPackageById(poolData.needItemId,poolData.needItemNum);
		}
		else	// 道具不足，元宝补充
		{
			int YB = (poolData.needItemNum - itemNum)*poolData.need_YB;
			if(pUser->GetTongBao() >= YB)	// 元宝抽神将
			{
				pUser->AddTongBao(-YB);
				pUser->DelPackageById(poolData.needItemId,itemNum);
			}
			else
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0414,TIPS_FAILURE_COLOR);
				return true;
			}
		}
	}

	bool isOrange = false;
	msg<<PRO_SUCCESS;
	if(type == EPDT_Single)	// 单抽
	{
		uint32 curTime = GetSysTime();
		uint32 lastTime = pUser->GetExtData32(92);
		uint32 leftCD = (curTime < lastTime) ? (lastTime - curTime) : 0;
		msg<<leftCD;

		// 第一次抽神将
		if(!pUser->HaveBitSet(187))
		{
			int petId = 40;
			int level = 25;
			int star = -1;
			uint16 itemId = 0;
			uint16 itemNum = 0;
			if(!AddPet(pUser,petId,level,star,true,NULL,&itemId, &itemNum))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			pUser->SetBitSet(187);
			uint8 transfer = (itemId != 0) ? 0 : 1;
			msg<<(uint8)1<<(uint16)HDAT_PET<<transfer<<(uint16)petId<<GetPetName(petId)<<(uint16)star;
			if (itemId != 0)
				msg<<itemId<<itemNum;
			SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_9); // TODO 
			return true;
		}
		// 第二次抽神将
		if(!pUser->HaveBitSet(188))
		{
			int petIdList[] = {41,49,58,59,61,64,65};
			int level = (pUser->GetLevel() > 30) ? 30 : pUser->GetLevel();
			int star = -1;
			uint16 itemId = 0;
			uint16 itemNum = 0;
			uint8 size = sizeof(petIdList)/sizeof(petIdList[0]);
			int petId = petIdList[Random(1,size)-1];
			if(!AddPet(pUser,petId,level,star,true,NULL,&itemId, &itemNum))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			pUser->SetBitSet(188);
			uint8 transfer = (itemId != 0) ? 0 : 1;
			msg<<(uint8)1<<(uint16)HDAT_PET<<transfer<<(uint16)petId<<GetPetName(petId)<<(uint16)star;
			if (itemId != 0)
				msg<<itemId<<itemNum;
			SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_9); // TODO 
			return true;
		}
/*		// 第三次抽神将
		if(!pUser->HaveBitSet(189))
		{
			map<uint16,SPetDrawPoolData>::iterator poolIt_10 = cfg.awardPool.find(EPDT_Time10);
			if(poolIt_10 == cfg.awardPool.end())
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			if(!SinglePetDraw(pUser,poolIt_10->second,isOrange,msg))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			pUser->SetBitSet(189);
			SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_9); // TODO 
			return true;
		}
*/
		// 正常抽取
		uint8 num = 1;
		msg<<num;
		if(!SinglePetDraw(pUser,poolData,isOrange,msg))
		{
			SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
			return false;
		}
		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_9); // TODO 
	}
	else if(type == EPDT_Time10)	// 十连
	{
		poolIt = cfg.awardPool.find(EPDT_Single);
		if(poolIt == cfg.awardPool.end())
			return false;
		SPetDrawPoolData &poolData1 = poolIt->second;
		uint8 curDraw10Times = pUser->GetExtData8(poolData.save_times_ext8);
		int mustBeOrangeLeftTimes = poolData.must_be_orange_times - curDraw10Times;
		msg<<(int)(((mustBeOrangeLeftTimes-1) > 0) ? (mustBeOrangeLeftTimes-1) : poolData.must_be_orange_times);
		
		const int drawTimes = 10;
		uint16 numPos = msg.GetDataLen();
		uint8 num = 0;
		msg<<num;

		int errors = 0;
		bool canDrawOrange = true;
		uint8 orangeNum = 0;
		for(int i=0;i < drawTimes-1;)
		{
			if(!SinglePetDraw(pUser,poolData1,isOrange,msg,canDrawOrange, false))
			{
				errors++;
				if(errors >= 100)
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
					return false;
				}
				continue;
			}
			i++;
			num++;
			if(isOrange)
				orangeNum++;
			if(orangeNum >= poolData.orange_pet_num)
				canDrawOrange = false;
		}

		if(orangeNum >= poolData.orange_pet_num || mustBeOrangeLeftTimes > 1)
		{
			num++;
			if(!SinglePetDraw(pUser,poolData1,isOrange,msg,canDrawOrange, false))
			{
				SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
				return false;
			}
			pUser->SetExtData8(poolData.save_times_ext8,curDraw10Times+1);
		}
		else if(orangeNum < poolData.orange_pet_num && mustBeOrangeLeftTimes <= 1)	// 必出橙色
		{
			num++;
			if(!pUser->HaveBitSet(608))	// 抽次十连
			{
				map<uint16,SPetDrawPoolData>::iterator first10Pool = cfg.awardPool.find(EPDT_First10);
				if(first10Pool == cfg.awardPool.end())
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
					return false;
				}
				SPetDrawPoolData &first10pool = first10Pool->second;
				if(!SinglePetDraw(pUser,first10pool,isOrange,msg,canDrawOrange, false))
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
					return false;
				}
				pUser->SetBitSet(608);
			}
			else
			{
				if(!SinglePetDraw(pUser,poolData,isOrange,msg,canDrawOrange, false))
				{
					SendSysInfo(pUser,MakeStringColor(LANGUAGE_SSJ_0415,TIPS_FAILURE_COLOR).c_str());
					return false;
				}
			}
			pUser->SetExtData8(poolData.save_times_ext8,0);	// 重置
		}
		msg.WriteData(numPos,&num,sizeof(num));

		SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(pUser, EMISS_DC_9, num, 0); // TODO 
	}
	else
	{
		return false;
	}
	return true;
}

void CPetDrawCfgMgr::SetAward(SPetDrawPoolBasicData &data,string &str)
{
	data.Clear();
	if(str.empty())
		return;
	
	char buf[128];
	int num = 0;
	char *p[10];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,'-');
	if(num < 2)
		return;
	int type = atoi(p[0]);
	if(type == HDAT_PET)
	{
		if(num != 4)
		{
			cout<<">> SPetDrawCfgMgr::SetAward award error ... str="<<str<<endl;
			return;
		}
		data.awardType = type;
		data.id = atoi(p[1]);
		data.petstar = atoi(p[2]);
		data.petLevel = atoi(p[3]);
	}
	else if(type < HDAT_MONEY)
	{
		if(num != 2)
		{
			cout<<">> SPetDrawCfgMgr::SetAward award error ... str="<<str<<endl;
			return;
		}
		data.awardType = type;
		data.id = type;
		data.itemNum = atoi(p[1]);
	}
	else
	{
		return;
	}
}

bool CPetDrawCfgMgr::SinglePetDraw(CUser *pUser,SPetDrawPoolData &poolData,bool &isOrange,CNetMessage &msg,bool canDrawOrange, bool isSingel/* = false*/)
{
	isOrange = false;
	if(pUser == NULL)
		return false;
	do
	{
		int runTimes = 0;
		int idx = RandFromPool(poolData.awardList);
		if(idx == -1)
			return false;
		
		SPetDrawPoolBasicData &curData = poolData.awardList[idx];
		if(curData.awardType == HDAT_PET)
		{
			SPetBasicData *pPetCfg = SingletonCPetCfgMgr::instance().GetPetCfg(curData.id);
			if(pPetCfg == NULL || (pPetCfg->quality >= PQT_ORANGE && !canDrawOrange))
			{
				if((++runTimes) >= 100)
					return false;
				continue;
			}
			uint16 itemId = 0;
			uint16 itemNum = 0;
			if(!AddPet(pUser,curData.id,curData.petLevel,curData.petstar, isSingel, NULL, &itemId, &itemNum))
				return false;
			if(pPetCfg->quality >= PQT_ORANGE)
				isOrange = true;
			uint8 transfer = (itemId != 0) ? 0 : 1;
			msg << curData.awardType << transfer << curData.id << pPetCfg->name << curData.petstar;
			if (itemId != 0)
			{
				msg << itemId << itemNum;
			}

			if(isOrange)
			{
				char buf[512];
				snprintf(buf,sizeof(buf),LANGUAGE_TRANSFORM_1820,ROLE_NAME_COLOR,pUser->GetName(),GetPetName(curData.id));
				SysInfoToAllUser(buf);
			}
			break;
		}
		else if(curData.awardType < HDAT_MONEY)
		{
			if(!pUser->AddPackage(curData.id,curData.itemNum))
				return false;
			msg<<curData.id<<curData.itemNum;
			if (isSingel)
			{
				PlayItemDrawCartoon(pUser, curData.id, curData.itemNum);
			}
			break;
		}
		else
		{
			return false;
		}
	}while(!canDrawOrange);
	return true;
}

int CPetDrawCfgMgr::RandFromPool(vector<SPetDrawPoolBasicData> &pool)
{
	uint32 allRatio = 0;
	for(uint32 i=0;i < pool.size();i++)
		allRatio += pool[i].ratio;
	
	uint32 r = Random(1,allRatio);
	uint32 count = 0;
	for(uint32 i=0;i < pool.size();i++)
	{
		count += pool[i].ratio;
		if(r <= count)
		{
			return i;
		}
	}
	return -1;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////

bool CZhenFaCfgMgr::Init()
{
	m_zhenfaData.clear();
	m_zhenfaUp.clear();

	{
		const string file = "zhenfa_config.json";
		//                            0    1       2            3               4             5            6          7                8           9               10          11              12
		const char* titleArrs[] = { "id","name","index1","index1_openlevel","index2","index2_openlevel","index3","index3_openlevel","index4","index4_openlevel","index5","index5_openlevel","counter" };
		const int typeArrs[] = { 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CZhenFaCfgMgr::Init >> LoadJosnValue zhenfa_level.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			SZhenFaBasicCfg t;
			t.id = data[titleArrs[0]].GetInt();
			t.name = data[titleArrs[1]].GetString();
			for(uint8 j=0;j < ZHEN_FA_POS_NUM;j++)
			{
				t.fightPos[j] = data[titleArrs[j * 2 + 2]].GetInt();
				t.open_level[j] = data[titleArrs[j * 2 + 3]].GetInt();
			}
			const rapidjson::Value &arr = data[titleArrs[12]];
			for (uint8 ai = 0; ai < arr.Size(); ++ai)
			{
				t.restrainList.push_back(arr[ai].GetInt());
			}
			m_zhenfaData.insert(make_pair(t.id,t));
		}
	}

	{
		const string file = "zhenfa_level.json";
		//                            0      1          2              3               4             5               6          7         8
		const char* titleArrs[] = { "id", "level", "index1_attr", "index2_attr", "index3_attr", "index4_attr", "index5_attr", "cost", "zhanli" };
		const int typeArrs[] = { 0, 0, 2, 2, 2, 2, 2, 2, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CZhenFaCfgMgr::Init >> LoadJosnValue zhenfa_level.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			SZhenFaLevelUpData t;
			t.id = data[titleArrs[0]].GetInt();
			t.level = data[titleArrs[1]].GetInt();
			for(uint8 j=0;j < ZHEN_FA_POS_NUM;j++)
			{
				ReadMultiAttr(data[titleArrs[j + 2]], t.attrList[j]);
			}
			ReadMultiCost(data[titleArrs[7]], t.costs);
			t.zhandouli = data[titleArrs[8]].GetInt();
			uint32 key = (t.id << 16) | t.level ;
			m_zhenfaUp.insert(make_pair(key,t));
		}
	}

	return true;
}

SZhenFaBasicCfg *CZhenFaCfgMgr::GetBasicCfg(uint16 id)
{
	if(id == 0)
		return NULL;
	
	map<uint16,SZhenFaBasicCfg>::iterator it = m_zhenfaData.find(id);
	if(it == m_zhenfaData.end())
		return NULL;
	return &(it->second);
}

SZhenFaLevelUpData *CZhenFaCfgMgr::GetLevelUpCfg(uint16 id,uint8 level)
{
	if(id == 0)
		return NULL;

	uint32 key = (id << 16) | level;
	map<uint32,SZhenFaLevelUpData>::iterator it = m_zhenfaUp.find(key);
	if(it == m_zhenfaUp.end())
		return NULL;
	return &(it->second);
}

bool CZhenFaCfgMgr::IsKeZhi(uint16 srcId,uint16 tarId)
{
	if(srcId == 0 || tarId == 0)
		return false;
	
	SZhenFaBasicCfg *pSrcCfg = GetBasicCfg(srcId);
	if(pSrcCfg == NULL)
		return false;
	if(std::find(pSrcCfg->restrainList.begin(),pSrcCfg->restrainList.end(),tarId) != pSrcCfg->restrainList.end())
		return true;
	return false;
}

void CZhenFaCfgMgr::SetRestrainData(vector<uint16> &data,string &str)
{
	data.clear();
	if(str.empty())
		return;

	char buf[1024];
	int num = 0;
	char *p[100];
	strncpy(buf,str.c_str(),sizeof(buf));
	num = SplitLine(p,buf,';');
	for(int i=0;i < num;i++)
	{
		uint16 id = atoi(p[i]);
		if(id > 0)
		{
			data.push_back(id);
		}
	}
}

void CZhenFaCfgMgr::SetAttrData(vector<SAttrData> &data,string &str)
{
	data.clear();
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
		char *tp[2];
		strncpy(tbuf,p[i],sizeof(tbuf));
		tnum = SplitLine(tp,tbuf,'|');
		if(tnum != 2)
		{
			cout<<"CZhenFaCfgMgr::SetAttrData error , str = "<<str;
			return;
		}

		SAttrData v;
		v.attrType = atoi(tp[0]);
		v.attrValue = atoi(tp[1]);
		data.push_back(v);
	}
}

///////////////////////////////////////////////////////////////////////////////

bool CAttrCfgMgr::Init()
{
	m_data.clear();

	const string file = "attr_type.json";
	//                     0           1          2
	const char* fields[] = {"attrType",   "attrName",  "powerRatio"};
	const int types[] = {    EJPT_INT, EJPT_STRING,   EJPT_INT};
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
	{
		cout<< ">> CAttrCfgMgr::Init  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		SAttrTypeData t;
		t.type = data[fields[0]].GetInt();
		t.name = data[fields[1]].GetString();
		t.zhandouliRatio = data[fields[2]].GetInt();
		m_data.insert(make_pair(t.type, t));
	}
	return true;
}

SAttrTypeData *CAttrCfgMgr::GetCfg(int type)
{
	if(type < 1)
		return NULL;
	map<int, SAttrTypeData>::iterator it = m_data.find(type);
	if(it == m_data.end())
		return NULL;
	return &(it->second);
}

int CAttrCfgMgr::GetTypeRatio(int type)
{
	if(type < 1)
		return 0;
	map<int, SAttrTypeData>::iterator it = m_data.find(type);
	if(it == m_data.end())
		return 0;
	return it->second.zhandouliRatio;
}

const char *CAttrCfgMgr::GetTypeName(int type)
{
	if(type < 1)
		return "";
	map<int, SAttrTypeData>::iterator it = m_data.find(type);
	if(it == m_data.end())
		return "";
	return it->second.name.c_str();
}

int CAttrCfgMgr::CalulateZhanDouLi(SUnitBasicAttr &unitAttr)
{
	int zhanDouli = 0;
	zhanDouli += unitAttr.attack * GetTypeRatio(EAT_Attack);
	zhanDouli += unitAttr.wufang * GetTypeRatio(EAT_WuFang);
	zhanDouli += unitAttr.fafang * GetTypeRatio(EAT_FaFang);
	zhanDouli += unitAttr.maxHp * GetTypeRatio(EAT_QiXue);
	zhanDouli += unitAttr.speed * GetTypeRatio(EAT_SuDu);
	zhanDouli += unitAttr.mingzhong * GetTypeRatio(EAT_MingZhong);
	zhanDouli += unitAttr.shanbi * GetTypeRatio(EAT_ShanBi);
	zhanDouli += unitAttr.baoji * GetTypeRatio(EAT_BaoJi);
	zhanDouli += unitAttr.baojikang * GetTypeRatio(EAT_BaoJiKang);
	zhanDouli += unitAttr.mingzhongLv * GetTypeRatio(EAT_MingZhongLv);
	zhanDouli += unitAttr.shanbiLv * GetTypeRatio(EAT_ShanBiLv);
	zhanDouli += unitAttr.baojiLv * GetTypeRatio(EAT_BaoJiLv);
	zhanDouli += unitAttr.baojikangLv * GetTypeRatio(EAT_BaoJiKangLv);
	zhanDouli += unitAttr.zengshangLv * GetTypeRatio(EAT_ZengShangLv);
	zhanDouli += unitAttr.wumianLv * GetTypeRatio(EAT_WuMianLv);
	zhanDouli += unitAttr.famianLv * GetTypeRatio(EAT_FaMianLv);
	zhanDouli += unitAttr.baojiAdd * GetTypeRatio(EAT_BaoJiAdd);
	zhanDouli += unitAttr.fanjiLv * GetTypeRatio(EAT_FanJiLv);
	zhanDouli += unitAttr.fanjikangLv * GetTypeRatio(EAT_FanJiKangLv);
	zhanDouli += unitAttr.fanjiAdd * GetTypeRatio(EAT_FanJiAdd);
	zhanDouli += unitAttr.lianjiLv * GetTypeRatio(EAT_LianJiLv);
	zhanDouli += unitAttr.lianjikangLv * GetTypeRatio(EAT_LianJiKangLv);
	zhanDouli += unitAttr.lianjiAdd * GetTypeRatio(EAT_LianJiAdd);
	zhanDouli += unitAttr.fanzhenLv * GetTypeRatio(EAT_FanZhenLv);
	zhanDouli += unitAttr.fanzhenkangLv * GetTypeRatio(EAT_FanZhenKangLv);
	zhanDouli += unitAttr.fanzhenAdd * GetTypeRatio(EAT_FanZhenAdd);
	zhanDouli += unitAttr.fumianAdd * GetTypeRatio(EAT_FuMianAdd);
	zhanDouli += unitAttr.fumianKangAdd * GetTypeRatio(EAT_FuMianKangAdd);
	zhanDouli /= 10;
	return zhanDouli;
}

int CAttrCfgMgr::CalulateZhanDouLi(vector<SAttrData> &attrList)
{
	int zhanDouli = 0;
	for(uint16 i=0;i < attrList.size();i++)
	{
		zhanDouli += attrList[i].attrValue *GetTypeRatio(attrList[i].attrType);
	}
	zhanDouli /= 10;
	return zhanDouli;
}


/////////////////////////////////////////////////////////////////////////////////////////////


bool CUserCfgMgr::Init()
{
	m_data.clear();
	m_levelData.clear();

	{
		vector<map<string,string> > data;
		//                     0          1           2          3       4        5           6         7        8          9         10       11         12         13      14
		const char *keys[] = {"profession","attack_type","mingzhonglv","shanbilv","baojilv","kangbaolv","zengshanglv","wumianlv","famianlv","baojishanghai","fanjilv","kangfanlv","fanjishanghia","lianjilv","kanglianlv",
		//       15           16         17          18            19             20        21
			"lianjishanghai","fanzhenlv","kangzhenlv","fanzhenshanghai","fumianqianghua","fumiandikang","skill"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("role_basic_config.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			SUserProCfgData t;
			t.profession = atoi(data[i][keys[0]].c_str());
			t.attack_type = atoi(data[i][keys[1]].c_str());
			for(uint16 k=2;k <= 20;k++)
			{
				SAttrData attr;
				attr.attrType = EAT_MingZhongLv + k -2;
				attr.attrValue = atoi(data[i][keys[k]].c_str());
				t.attrList.push_back(attr);
			}
			SetUserSkillData(t.skillList,data[i][keys[21]]);
			m_data.insert(make_pair(t.profession,t));
		}
	}

	{
		vector<map<string,string> > data;
		//                     0        1     2       3       4      5     6        7        8     9      10
		const char *keys[] = {"profession","level","gongji","wufang","fashang","qixue","sudu","mingzhong","shanbi","baoji","kangbao"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("role_level_attr.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			SUserBasicLevelData t;
			t.profession = atoi(data[i][keys[0]].c_str());
			t.level = atoi(data[i][keys[1]].c_str());
			t.attack = atoi(data[i][keys[2]].c_str());
			t.wufang = atoi(data[i][keys[3]].c_str());
			t.fafang = atoi(data[i][keys[4]].c_str());
			t.qixue = atoi(data[i][keys[5]].c_str());
			t.sudu = atoi(data[i][keys[6]].c_str());
			t.mingzhong = atoi(data[i][keys[7]].c_str());
			t.shanbi = atoi(data[i][keys[8]].c_str());
			t.baoji = atoi(data[i][keys[9]].c_str());
			t.baojiKang = atoi(data[i][keys[10]].c_str());
			int key = (t.profession << 16) | t.level;
			m_levelData.insert(make_pair(key,t));
		}
	}

	return true;
}

SUserProCfgData *CUserCfgMgr::GetBasicCfg(int profession)
{
	if(profession == 0)
		return NULL;
	
	map<int,SUserProCfgData>::iterator it = m_data.find(profession);
	if(it == m_data.end())
		return NULL;
	return &(it->second);
}

SUserBasicLevelData *CUserCfgMgr::GetLevelAttr(int profession,int level)
{
	if(profession <= 0 || level <= 0)
		return NULL;
	
	int key = (profession << 16) | level;
	map<int,SUserBasicLevelData>::iterator it = m_levelData.find(key);
	if(it == m_levelData.end())
		return NULL;
	return &(it->second);
}

bool CUserCfgMgr::SetUserSkillData(vector<SUserSkillList> &data,string &str)
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
			cout<<"SetUserSkillData() error , str = "<<str;
			return false;
		}

		SUserSkillList v;
		v.skillId = atoi(tp[0]);
		v.openLevel = atoi(tp[1]);
		data.push_back(v);
	}
	return true;
}

/////////////////////////////////////  找回资源    //////////////////////////////////////////////////


bool CFindResourceManager::Init()
{
	m_findList.clear();

	const string file = "revert.json";
	//                       0        1      2         3            4              5
	const char* fields[] = {"function_id", "revert", "type",        "cost",            "level",         "revert_reward"};
	const int types[] = {     EJPT_INT, EJPT_INT, EJPT_INT, EJPT_ARRAY,   EJPT_ARRAYS,    EJPT_ARRAYS};
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, fields, types, sizeof(types)/sizeof(types[0]), d, _para))
	{
		cout<< ">> CFindResourceManager::Init  error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		int isOpen = data[fields[1]].GetInt();
		if(isOpen == 0)
			continue;

		int funcId = data[fields[0]].GetInt();
		SFindResCfg cfg;
		cfg.type = data[fields[2]].GetInt();

		const rapidjson::Value &cost = data[fields[3]];
		if(cost.Size() != 3)
		{
			cout<<">> CFindResourceManager::Init  cost.Size() != 3  error...  idx="<<i<<endl;
			continue;
		}
		cfg.cost.costType = cost[0].GetInt();
		cfg.cost.typeId = cost[1].GetInt();
		cfg.cost.costValue = cost[2].GetInt();

		const rapidjson::Value &level = data[fields[4]];
		for(uint8 j=0; j < level.Size(); j++)
		{
			const rapidjson::Value &v = level[j];
			if(v.Size() != 2)
				continue;
			vector<uint16> tmp;
			tmp.push_back(v[0].GetInt());
			tmp.push_back(v[1].GetInt());
			cfg.level.push_back(tmp);
		}

		const rapidjson::Value &award = data[fields[5]];
		for(uint8 j=0; j < award.Size(); j++)
		{
			MultiAward a;
			const rapidjson::Value &v = award[j];
			if(!ReadMultiAward(v, a))
				continue;
			cfg.award.push_back(a);
		}

		if(cfg.level.size() != cfg.award.size())
		{
			cout<<">> CFindResourceManager::Init  cfg.level.size() != cfg.award.size()  error..."<<endl;
			continue;
		}
		m_findList[funcId] = cfg;
	}
	return true;
}

bool CFindResourceManager::GetResourceCfg(int funcId, SFindResCfg &val)
{
	val.Clear();
	if(funcId < 1)
		return false;
	map<int, SFindResCfg>::iterator it = m_findList.find(funcId);
	if(it == m_findList.end())
		return false;
	val = it->second;
	return true;
}

void CFindResourceManager::GetFindResFuncIds(vector<int> &vec)
{
	vec.clear();
	for(map<int, SFindResCfg>::iterator it = m_findList.begin(); it != m_findList.end(); it++)
	{
		vec.push_back(it->first);
	}
}

bool CFindResourceManager::GetAwardInfo(int funcId, uint16 level, SCostData &cost, vector<SAwardData> &award)
{
	cost.Clear();
	award.clear();

	map<int, SFindResCfg>::iterator it = m_findList.find(funcId);
	if(it == m_findList.end())
		return false;
	
	SFindResCfg &cfg = it->second;
	cost = cfg.cost;
	for(uint16 i = 0; i < cfg.level.size(); i++)
	{
		uint16 minLv = cfg.level[i][0];
		uint16 maxLv = cfg.level[i][1];
		if(level >= minLv && level <= maxLv)
		{
			award.assign(cfg.award[i].begin(), cfg.award[i].end());
			return true;
		}
	}
	return false;
}

bool CTitltAttrCfgManager::Init()
{
	m_allTitleAttrs.clear();
	//                       0     1      2        3      4          5             6
	const char *keys[] = { "id", "name", "desc", "attr", "Isshow", "is_forever", "continue_time"  };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("title_config.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		int showState = atoi(data[i][keys[4]].c_str());
		if (showState == 0)
		{
			continue;
		}
		STitleAttrs sTitle;
		uint16 id = atoi(data[i][keys[0]].c_str());
		SetAttrData(sTitle,data[i][keys[3]]);
		m_needRecalcs[id] = true;
		m_names[id] = data[i][keys[1]];
		m_allTitleAttrs.insert(std::make_pair(id, sTitle));
		if (atoi(data[i][keys[5]].c_str()) == 0)
		{
			m_notForeveryTitle.insert(id);
		}

		uint32 sec = atoi(data[i][keys[6]].c_str());
		if (sec != 0)
		{
			m_continueTime.insert(make_pair(id, sec));
		}
	}
	return true;
}

STitleAttrs* CTitltAttrCfgManager::GetTitleAttrs(uint16 titleId)
{
	SAllTitleAttrsIt it = m_allTitleAttrs.find(titleId);
	if (it == m_allTitleAttrs.end())
	{
		return NULL;
	}
	return &it->second;
}

// 获取称号属性加成
uint32 CTitltAttrCfgManager::GetTitleAddPower(uint16 title)
{
	STitleAttrs* attrs = GetTitleAttrs(title);
	if (attrs == NULL) return 0;
	return GetAttrPower(*attrs);
}

bool CTitltAttrCfgManager::IsNeedRecalcPetAttr(uint16 title)
{
	std::map<int, bool>::iterator it = m_needRecalcs.find(title);
	if (it == m_needRecalcs.end()) return false;
	return it->second;
}

const char *CTitltAttrCfgManager::GetTitleName(uint16 title)
{
	map<int, string>::iterator it = m_names.find(title);
	if (it == m_names.end())
		return NULL;
	return it->second.c_str();
}

// 获取称号有效时间
uint32 CTitltAttrCfgManager::GetTitleContinueTime(uint16 title, uint32 time)
{
	map<int, uint32>::iterator it = m_continueTime.find(title);
	if (it != m_continueTime.end())
	{
		if (time != 0)
			return it->second + time;
		return it->second + GetSysTime();
	}
	return 0;
}

bool CTitltAttrCfgManager::IsForeveryTitle(uint16 title)
{
	return m_notForeveryTitle.find(title) == m_notForeveryTitle.end();
}


bool CSystemOpenCfgMananger::Init()
{
	m_allSystemCfgs.clear();
	const string file = "function.json";
	//                                0               1            2
	const char* titleArrs[] = { "function_id", "open_condition", "type"};
	const int typeArrs[] = { 0, 2, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CSystemOpenCfgMananger::Init >> LoadJosnValue error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		CSystemOpenCfg cfg;
		cfg.id = data[titleArrs[0]].GetInt();
		ReadMultiTypeValue(data[titleArrs[1]], cfg.openCond);
		cfg.type = data[titleArrs[2]].GetInt();
		m_allSystemCfgs.insert(std::make_pair(cfg.id, cfg));
	}
	return true;
}

CSystemOpenCfg* CSystemOpenCfgMananger::GetSystemCfg(int id)
{
	CSystemOpenCfgs::iterator it = m_allSystemCfgs.find(id);
	if (it != m_allSystemCfgs.end())
		return &it->second;
	return NULL;
}

bool CSystemOpenCfgMananger::CheckSystemOpen(CUser *pUser, int sysId)
{
	CSystemOpenCfgs::iterator it = m_allSystemCfgs.find(sysId);
	if (it == m_allSystemCfgs.end())
		return true;

	CSystemOpenCfg& cfg = it->second;
	bool isOpen = CheckUserCond(pUser, cfg.openCond);
	return isOpen;
}

bool CSystemOpenCfgMananger::CanShow(int sysId)
{
	int weekDay = GetWeekDay();
	CSystemOpenCfg *cfg = GetSystemCfg(sysId);
	if (cfg == NULL)
		return false;
#ifdef KUA_FU
	return (cfg->show == 2 || cfg->show == 3) && cfg->openWeekday[weekDay] == 1;
#else
	return (cfg->show == 1 || cfg->show == 3) && cfg->openWeekday[weekDay] == 1;
#endif
}

bool CSystemOpenCfgMananger::OpenWeekDay(int sysId)
{
	int weekDay = GetWeekDay();
	CSystemOpenCfg *cfg = GetSystemCfg(sysId);
	if(cfg == NULL)
		return false;
	return (cfg->openWeekday[weekDay] == 1);
}

bool CSystemOpenCfgMananger::GetFuncLvTime(int sysId,uint16 &b_time,uint16 &s_time,uint16 &e_time)
{
	CSystemOpenCfg *cfg = GetSystemCfg(sysId);
	if(cfg == NULL || !cfg->show_icon)
		return false;
	b_time = cfg->before_time;
	s_time = cfg->start_time;
	e_time = cfg->end_time;
	return true;
}

uint32 CSystemOpenCfgMananger::GetFuncOpenLevel(int sysId)
{
	const uint32 DefaultLevel = 0xffff;
	CSystemOpenCfg *cfg = GetSystemCfg(sysId);
	if(cfg == NULL)
		return DefaultLevel;

	for (size_t i = 0; i < cfg->openCond.size(); i++)
	{
		if (cfg->openCond[i].type == 1)
			return cfg->openCond[i].value;
	}
	return 1;
}

bool CRoleSkillLvUpCfgMananger::Init()
{
	m_allLvUpCosts.clear();
	const char *keys[] = { "skill_idx", "level", "learn_level", "cost" };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("role_skill_LvUp.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		tagSkillLvUpCost cost;
		cost.pos = atoi(data[i][keys[0]].c_str());
		cost.level = atoi(data[i][keys[1]].c_str());
		cost.learnLevel = atoi(data[i][keys[2]].c_str());
		string str = data[i][keys[3]];
		int num = 0;
		int num1 = 0;
		char buf[128];
		char buf1[128];
		char *p[10];
		char *p1[10];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for (int j = 0; j < num; ++j)
		{
			strncpy(buf1, p[j], sizeof(buf1));
			num1 = SplitLine(p1, buf1, '-');
			if(num1 != 2)
			{
				cout<<"role_skill_LvUp.xml  skill_idx="<<cost.pos<<", level="<<cost.level<<", cost="<<str<<", error !!!"<<endl;
				continue;
			}
			int type = atoi(p1[0]);
			if (type == HDAT_MONEY)
			{
				cost.moneyCost = atoi(p1[1]);
			}
			else if (type == HDAT_QIANNENG)
			{
				cost.qiannengCost = atoi(p1[1]);
			}
		}
		AddCostCfg(cost);
	}
	return true;
}

void CRoleSkillLvUpCfgMananger::AddCostCfg(tagSkillLvUpCost cost)
{
	roleSkillLvUps::iterator it = m_allLvUpCosts.find(cost.pos);
	if (it == m_allLvUpCosts.end())
	{
		MSkillLvCosts costs;
		std::pair<roleSkillLvUps::iterator, bool> bit = m_allLvUpCosts.insert(std::make_pair(cost.pos, costs));
		it = bit.first;
	}
	it->second.insert(std::make_pair(cost.level, cost));
	
}

tagSkillLvUpCost* CRoleSkillLvUpCfgMananger::GetSkillLvUpCost(int pos, int level)
{
	roleSkillLvUps::iterator it = m_allLvUpCosts.find(pos);
	if (it == m_allLvUpCosts.end())
	{
		return NULL;
	}
	MSkillLvCosts::iterator mit = it->second.find(level);
	if (mit == it->second.end())
	{
		return NULL;
	}
	return &mit->second;
}

/////////////////////////////////////////////////////////////////////////////////


bool CFengShenMgr::Init()
{
	m_cfg.clear();

	//                  0	   1      2           3              4            5             6             7              8         9
	const char *keys[] = {"id","boss_id","fight_id","recommend_pets","open_weekday","reward_show","level_reward_1","level_reward_2","level_reward_3","desc"};
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("fengshen_shilian.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	char buf[512];
	int num = 0;
	char *p[100];
	for (uint32 i = 0; i < data.size(); i++)
	{
		SFengShenCfg t;
		t.id = atoi(data[i][keys[0]].c_str());
		t.bossId = atoi(data[i][keys[1]].c_str());
		t.fightId = atoi(data[i][keys[2]].c_str());
		t.index = i;

		string str = data[i][keys[3]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for(int j=0; j < num; j++)
			t.recommend_pets.push_back(atoi(p[j]));

		str = data[i][keys[4]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for(int j=0; j < num && j < 7; j++)
		{
			int weekIdx = atoi(p[j]);
			if(weekIdx == 7)
				weekIdx = 0;
			t.open_weekDay |= 1<<weekIdx;
		}

		str = data[i][keys[5]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for(int j=0; j < num; j++)
			t.show_award.push_back(atoi(p[j]));

		t.level_reward[0] = atoi(data[i][keys[6]].c_str());
		t.level_reward[1] = atoi(data[i][keys[7]].c_str());
		t.level_reward[2] = atoi(data[i][keys[8]].c_str());
		t.desc = data[i][keys[9]];

		m_cfg.push_back(t);
	}
	return true;
}

void CFengShenMgr::SendFengShenBossMsg(CUser *pUser)
{
	if(pUser == NULL)
		return;

	CNetMessage msg;
	msg.SetType(PRO_FENGSHEN_SHILIAN);
	msg<<(uint8)1;
	
	CMonsterBossManager &bossMgr = SingletonMonsterBossManager::instance();
	int weekDay = GetWeekDay();
	uint8 vipLevel = pUser->GetVipLevel();
	uint8 flag = 1 << weekDay;
	uint8 num = 0;
	uint16 numPos = msg.GetDataLen();
	msg<<num;
	for(uint16 i=0;i < m_cfg.size();i++)
	{
		SFengShenCfg &data = m_cfg[i];
		uint8 isOpen = 0;	// 1 open 0 not open
		uint8 times = 0;
		if((data.open_weekDay & flag) > 0)
		{
			isOpen = 1;
			times = CAN_DO_NUM + G_VipConfig[vipLevel].fengShenNum - pUser->GetExtData8(478 + data.index);
		}
		int pic = 0;
		string name;
		if(!bossMgr.GetMonsterBossInfo(data.bossId,pic,name))
			continue;
		num++;
		msg<<data.id<<pic<<name<<data.open_weekDay<<data.desc<<isOpen<<times;

		uint8 size = data.show_award.size();
		msg<<size;
		for(uint8 j=0;j < size;j++)
			msg<<data.show_award[j];
		
		size = data.recommend_pets.size();
		msg<<size;
		for(uint8 j=0;j < size;j++)
			msg<<data.recommend_pets[j];
	}
	if(num > 0)
		msg.WriteData(numPos,&num,sizeof(num));
	SingletonSocket::instance().SendMsg(pUser->GetSock(),msg);
}

SFengShenCfg *CFengShenMgr::GetFengShenBossCfg(uint16 id)
{
	if(id == 0)
		return NULL;

	for(uint16 i=0;i < m_cfg.size();i++)
	{
		if(m_cfg[i].id == id)
			return &m_cfg[i];
	}
	return NULL;
}

int CFengShenMgr::GetFSFightNum()
{
	int count = 0;
	int weekDay = GetWeekDay();
	uint8 flag = 1 << weekDay;
	for(uint16 i=0;i < m_cfg.size();i++)
	{
		if((m_cfg[i].open_weekDay & flag) != 0)
			count += CAN_DO_NUM;
	}
	return count;
}

//////////////////////////////////////////////////////////////////////////////////////////
bool CJingJieManager::Init()
{
	m_cfg.clear();

	const string file = "jingjie_config.json";
	

	//                                0         1         2            3             4              5          6
	const char* titleArrs[] = { "jingjie_id", "name", "quality", "level_limit", "zhanli_limit", "tupo_cost", "attr" };
	const int typeArrs[] = { EJPT_INT, EJPT_STRING, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_ARRAYS, EJPT_ARRAYS };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CJingJieManager::Init >> LoadJosnValue error " << endl;
		return false;
	}

	MultiAttr sumAttrs;
	vector<SSkillData> skills;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &_arr = _para[i];
		SJingJieCfg cfg;
		MultiAttr attrs;
		cfg.lv = _arr[titleArrs[0]].GetInt();
		cfg.name = _arr[titleArrs[1]].GetString();
		cfg.quality = _arr[titleArrs[2]].GetInt();
		cfg.lvCond = _arr[titleArrs[3]].GetInt();
		cfg.powerCond = _arr[titleArrs[4]].GetInt();
		ReadMultiCost(_arr[titleArrs[5]], cfg.costs);
		ReadMultiAttr(_arr[titleArrs[6]], attrs);
		MergeAttrList(sumAttrs, attrs);
		cfg.attr = sumAttrs;
		m_cfg.insert(make_pair(cfg.lv, cfg));
	}
	return true;
}

bool CJingJieManager::GetCfg(int jingjieID,SJingJieCfg &val)
{
	val.Clear();
	if(jingjieID < 0)
		return false;
	map<int,SJingJieCfg>::iterator it = m_cfg.find(jingjieID);
	if(it == m_cfg.end())
		return false;
	val = it->second;
	return true;
}

///////////////////////////////////////////////////////////////////////////////

bool CBangPaiHuoYueMgr::Init()
{
	m_data.clear();

	{
		vector<map<string,string> > data;
		//                     0     1      2       3 
		const char *keys[] = {"id","name","param","value"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("bang_pai_huoyue.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			SBangPaiHuoYueData t;
			t.type = atoi(data[i][keys[0]].c_str());
			t.name = data[i][keys[1]];
			t.param = atoi(data[i][keys[2]].c_str());
			t.huoyue = atoi(data[i][keys[3]].c_str());
			m_data.insert(make_pair(t.type,t));
		}
	}
	return true;
}

bool CBangPaiHuoYueMgr::GetCfg(int type,SBangPaiHuoYueData &val)
{
	val.Clear();
	if(type < 1)
		return false;
	map<int,SBangPaiHuoYueData>::iterator it = m_data.find(type);
	if(it == m_data.end())
		return false;
	val = it->second;
	return true;
}

int CBangPaiHuoYueMgr::GetHuoYue(int type)
{
    SBangPaiHuoYueData cfgData;
	if(!GetCfg(type,cfgData))
		return 0;
	return cfgData.huoyue;
}

int CBangPaiHuoYueMgr::GetParam(int type)
{
    SBangPaiHuoYueData cfgData;
	if(!GetCfg(type,cfgData))
		return 0;
	return cfgData.param;
}

///////////////////////////////////////////////////////////////////////////////

bool CBangPaiHYRewardMgr::Init()
{
	m_data.clear();
    m_singledata.clear();
	{
		vector<map<string,string> > data;
		//                     0               1       2 
		const char *keys[] = {"rewardid","activity","type"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("bang_pai_reward.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

        int cnt = 0;
        int cnt1 = 0;
		for(uint32 i=0;i < data.size();i++)
		{
			SBangPaiHuoYueReward t;
			t.rewardid = atoi(data[i][keys[0]].c_str());
			t.huoyue = atoi(data[i][keys[1]].c_str());
			int type = atoi(data[i][keys[2]].c_str());
			if (type == 1)
			{
				t.idx = 435+cnt;
				++cnt;
				m_singledata.insert(make_pair(t.huoyue,t));
				if(t.huoyue > m_maxSingleHuoYue)
					m_maxSingleHuoYue = t.huoyue;
			}
			else if(type == 2)
			{
				t.idx = 445+cnt1;
				++cnt1;
				m_data.insert(make_pair(t.huoyue,t));
				if(t.huoyue > m_maxHuoYue)
					m_maxHuoYue = t.huoyue;
			}
		}
	}
	return true;
}

bool CBangPaiHYRewardMgr::GetCfg(int type,int huoyue,SBangPaiHuoYueReward &val)
{
	val.Clear();
	if(huoyue < 1)
		return false;
    switch(type)
    {
    	case 1:
    	{
    		map<int,SBangPaiHuoYueReward>::iterator it = m_singledata.find(huoyue);
			if(it == m_singledata.end())
				return false;
			val = it->second;
			break;
    	}
    	case 2:
    	{
    		map<int,SBangPaiHuoYueReward>::iterator it = m_data.find(huoyue);
			if(it == m_data.end())
				return false;
			val = it->second;
			break;
    	}
    	default:
    	    return false;
    }
	return true;
}

int CBangPaiHYRewardMgr::GetMaxHuoYue(int type)
{
	if(type == 1)
		return m_maxSingleHuoYue;
	else if(type == 2)
		return m_maxHuoYue;
	return 0;
}

void CBangPaiHYRewardMgr::GetHuoYueDrawInfo(int type,std::vector<SBangPaiHuoYueReward> &vec)
{
	vec.clear();
	map<int,SBangPaiHuoYueReward>::iterator it;
	if (type == 1)
	{
		for(it = m_singledata.begin();it!=m_singledata.end();it++)
		{
			SBangPaiHuoYueReward& data = it->second;
			SBangPaiHuoYueReward info;
			info.rewardid = data.rewardid;
			info.huoyue = data.huoyue;
			info.idx = data.idx;
			vec.push_back(info);
		}
	}
	else if(type == 2)
	{
		for(it = m_data.begin();it!=m_data.end();it++)
		{
			SBangPaiHuoYueReward& data = it->second;
			SBangPaiHuoYueReward info;
			info.rewardid = data.rewardid;
			info.huoyue = data.huoyue;
			info.idx = data.idx;
			vec.push_back(info);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////

bool CBangPaiLianQiMgr::Init()
{
	m_data.clear();
	m_maxType = 0;
	{
		vector<map<string,string> > data;
		//                     0        1      2      
		const char *keys[] = {"value","add","bangpai_money"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("bang_pai_keji.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			SBangPaiLianQiData t;
			t.level = atoi(data[i][keys[0]].c_str());
			t.money = atoi(data[i][keys[2]].c_str());

			char buf[128];
			char *p[10];
			int num = 0;
			strncpy(buf,data[i][keys[1]].c_str(),sizeof(buf));
			num = SplitLine(p,buf,'|');
			for(int k=0;k < num;k++)
			{
				char tbuf[64];
				int tnum = 0;
				char *tp[2];
				strncpy(tbuf,p[k],sizeof(tbuf));
				tnum = SplitLine(tp,tbuf,'-');
				if (tnum < 2)
					continue;
				t.type = atoi(tp[0]);
				t.addValue = atoi(tp[1]);
				stringstream ss;
				ss<<t.level<<"_"<<t.type;
				m_data.insert(make_pair(ss.str(),t));
			}
			if (num > m_maxType)
			{
				m_maxType = num;
			}
			
		}
	}
	return true;
}

bool CBangPaiLianQiMgr::GetCfg(int level,int type,SBangPaiLianQiData &val)
{
    val.Clear();
	if(level < 0)
		return false;
	stringstream ss;
	ss<<level<<"_"<<type;
	map<string,SBangPaiLianQiData>::iterator it = m_data.find(ss.str());
	if(it == m_data.end())
		return false;
	val = it->second;
	return true;
}

int CBangPaiLianQiMgr::GetValue(int level,int type)
{
	if(level < 0)
		return 0;
	stringstream ss;
	ss<<level<<"_"<<type;
	map<string,SBangPaiLianQiData>::iterator it = m_data.find(ss.str());
	if(it == m_data.end())
		return 0;
	SBangPaiLianQiData& cfg = it->second;
	return cfg.addValue;
}

int CBangPaiLianQiMgr::GetMaxType()
{
	return m_maxType;
}

///////////////////////////////////////////////////////////////////////////////

bool CBangPaiSkillMgr::Init()
{
	m_data.clear();
	{
		vector<map<string,string> > data;
		//                     0        1      2      
		const char *keys[] = {"id","level","value","type","bangpai_cost","cost"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("bang_pai_skill.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;

		for(uint32 i=0;i < data.size();i++)
		{
			SBangPaiSkillData t;
			t.id = atoi(data[i][keys[0]].c_str());
			t.level = atoi(data[i][keys[1]].c_str());
			t.type = atoi(data[i][keys[3]].c_str());

			SetAttrData(t.attrs,data[i][keys[2]]);
			SetCostData(t.cost,data[i][keys[4]]);
			SetCostData(t.singleCost,data[i][keys[5]]);

			m_data[t.id].info.insert(make_pair(t.level,t));
			if (t.level == 0)
			{
				m_skillIds.push_back(t.id);
			}
		}
	}
	return true;
}

bool CBangPaiSkillMgr::GetCfg(int id,int level,SBangPaiSkillData &val)
{
	if(level < 0 || id < 1)
		return false;
	map<int,SBangPaiSkillInfo>::iterator it = m_data.find(id);
	if(it == m_data.end())
		return false;
	SBangPaiSkillInfo &info = it->second;

	map<int,SBangPaiSkillData>::iterator iter = info.info.find(level);
	if(iter == info.info.end())
		return false;
	val = iter->second;
	return true;
}

void CBangPaiSkillMgr::GetSkillIds(vector<int> &skillIds)
{
	skillIds = m_skillIds;
}

///////////////////////////////////////////////////////////////////////////////
