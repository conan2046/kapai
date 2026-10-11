#include "huo_dong_mgr.h"
#include "init.h"
#include <time.h>
//#include <algorithm>
//
//bool YaoShiJiage::operator>(const YaoShiJiage& other)
//{
//	return num > other.num;
//}
static uint16 daySec = 86400;
void ZhuanPanCfg::GetJiaGe(SCostData& cost, int curNum, int buyNum)
{
	cost.costValue = 0;
	int hasBuy = 0;
	for (size_t i = 0; i < jiage.size(); i++)
	{
		YaoShiJiage& cJg = jiage[i];
		if (cJg.num > curNum + hasBuy)
		{
			// 当前价格区间能买得数量
			int thisBuy = cJg.num - (curNum + hasBuy);

			if (buyNum - hasBuy < thisBuy)
			{
				thisBuy = buyNum - hasBuy;
			}
			cost.costType = cJg.cost.costType;
			cost.costValue += cJg.cost.costValue * thisBuy;
			hasBuy += thisBuy;
		}
		if (buyNum == hasBuy)
			break;
	}
}

void ZhuanPanCfg::GetAward(MultiAward awards, int cnt)
{
	for (int ri = 0; ri < cnt; ++ri)
	{
		int rd = Random(0, random.sumWeight);
		for (size_t i = 0; i < random.awards.size(); i++)
		{
			ZhuanPanAward& zpAward = random.awards[i];
			if (rd <= (int)zpAward.weight)
				awards.push_back(zpAward.award);
		}
	}
}

bool CYaoQianShuMgr::Init()
{
	m_data.clear();
	m_defaultTimes = 3;
	m_levelLimit = 22;

	{
		vector<map<string,string> > data;
		//                   0     1       2          3         4        5
		const char *keys[] = {"type","times","cost_type","cost_value","get_type","get_value"};
		uint16 size = sizeof(keys)/sizeof(keys[0]);
		CXMLReader reader("yaoqianshu.xml");
		if(!reader.GetAllElements(data,keys,size))
			return false;
		
		for(uint32 i=0;i < data.size();i++)
		{
			uint8 type = atoi(data[i][keys[0]].c_str());
			map<uint8,map<uint16,SYaoQianShuData> >::iterator it = m_data.find(type);
			if(it == m_data.end())
			{
				pair<map<uint8,map<uint16,SYaoQianShuData> > ::iterator,bool> res = m_data.insert(make_pair(type,map<uint16,SYaoQianShuData>()));
				if(!res.second)
					return false;
				it = res.first;
			}
			map<uint16,SYaoQianShuData> &timesList = it->second;

			uint16 times = atoi(data[i][keys[1]].c_str());
			SYaoQianShuData yqsData;
			yqsData.cost_type = atoi(data[i][keys[2]].c_str());
			yqsData.cost_value = atoi(data[i][keys[3]].c_str());
			yqsData.get_type = atoi(data[i][keys[4]].c_str());
			yqsData.get_value = atoi(data[i][keys[5]].c_str());
			timesList.insert(make_pair(times,yqsData));
		}
	}
	
	return true;
}

bool CYaoQianShuMgr::GetCfg(uint8 type,uint16 index,SYaoQianShuData &data)
{
	data.Clear();

	map<uint8,map<uint16,SYaoQianShuData> >::iterator it = m_data.find(type);
	if(it == m_data.end())
		return false;

	map<uint16,SYaoQianShuData> &timesList = it->second;
	map<uint16,SYaoQianShuData>::iterator t = timesList.find(index);
	if(t == timesList.end())
		return false;
	data = t->second;
	return true;
}

uint16 CYaoQianShuMgr::GetTypeTimes(uint8 type)
{
	map<uint8, map<uint16, SYaoQianShuData> >::iterator it = m_data.find(type);
	if (it == m_data.end())
		return 0;

	return it->second.size();
}

CHuoDongManage::CHuoDongManage()
{
}

CHuoDongManage::~CHuoDongManage()
{
}

bool CHuoDongManage::InitHuoDongCfg()
{
	return true;
	//return InitHuoDongOpenCfg()
	//	&& InitZhuanPanCfg()
	//	&& InitQiRiDengLuAward();
}

bool CHuoDongManage::InitHuoDongOpenCfg()
{
	CHuoDongAwardManager& hmgr = sCHuoDongAwardManager;
	//uint16 openDay = hmgr.ServerOpenDay();
	uint32 zeroTime = hmgr.ServerOpenZeroTime();
	m_maxChiXuDay = 0;
	{
		const string file = "activity.json";
		//                             0     1      2       3             4               5               6
		const char* titleArrs[] = { "id", "name", "des", "open_time", "duration_time", "finaly_time", "reward_config" };
		const int typeArrs[] = { EJPT_INT, EJPT_STRING, EJPT_STRING, EJPT_INT, EJPT_INT, EJPT_INT, EJPT_ARRAY };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuoDongManage::InitHuoDongOpenCfg >> LoadJosnValue activity.json error " << endl;
			return false;
		}
		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &_arr = _para[i];
			HuoDongOpenCfg cfg;
			cfg.id = _arr[titleArrs[0]].GetInt();
			cfg.name = _arr[titleArrs[1]].GetString();
			int starDay = _arr[titleArrs[3]].GetInt();
			cfg.openDay = _arr[titleArrs[4]].GetInt();
			cfg.finishDay = _arr[titleArrs[5]].GetInt();
			if (starDay > 0)
			{
				cfg.startTime = zeroTime + daySec * (starDay - 1);
				cfg.endTime = cfg.startTime + daySec * cfg.openDay;
				cfg.finishTime = cfg.endTime + daySec * cfg.finishDay;
			}
			m_huoDongOpenCfg[cfg.id] = cfg;

			if (m_maxChiXuDay < cfg.openDay + cfg.finishDay)
				m_maxChiXuDay = cfg.openDay + cfg.finishDay;
		}
	}

	{
		const string file = "timing.json";
		//                             0        1
		const char* titleArrs[] = { "date", "activity" };
		const int typeArrs[] = { EJPT_INT, EJPT_ARRAY };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuoDongManage::InitHuoDongOpenCfg >> LoadJosnValue timing.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &_arr = _para[i];
			HuDongTimeCfg cfg;
			cfg.day = _arr[titleArrs[0]].GetInt();
			const rapidjson::Value &timeArr = _arr[titleArrs[1]];
			if (!timeArr.IsArray())
				continue;

			for (size_t j = 0; j < timeArr.Size(); j++)
			{
				const rapidjson::Value &hdArr = _arr[titleArrs[j]];
				if (!hdArr.IsArray() || hdArr.Size() != 2)
					continue;
				uint8 hdId = hdArr[0].GetInt();
				uint8 hdIdx = hdArr[1].GetInt();
				cfg.openHuoDong[hdId] = hdIdx;
			}
			m_huoDongTimeCfg[cfg.day] = cfg;
		}
	}
	return true;
}

bool CHuoDongManage::InitQiRiDengLuAward()
{
	const string file = "LoginReward.json";

	//                             0       1
	const char* titleArrs[] = { "id", "reward" };
	const int typeArrs[] = { EJPT_INT, EJPT_ARRAY };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CHuoDongManage::InitQiRiDengLuAward >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &_arr = _para[i];
		uint8 day = _arr[titleArrs[0]].GetInt();
		MultiAward award;
		ReadMultiAward(_arr[titleArrs[1]], award);
		m_qiRiAwards[day] = award;
	}
	return true;
}

bool CHuoDongManage::InitZhuanPanCfg()
{
	{
		const string file = "zhuanpan_config.json";

		//                             0       1           2      3
		const char* titleArrs[] = { "type", "yuanbao", "jifen", "rank" };
		const int typeArrs[] = { EJPT_INT, EJPT_INT, EJPT_INT, EJPT_INT };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuoDongManage::InitJiJinCfg >> LoadJosnValue zhuanpan_config.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &_arr = _para[i];
			ZhuanPanCfg cfg;
			cfg.type = _arr[titleArrs[0]].GetInt();
			cfg.zkShop = _arr[titleArrs[1]].GetInt();
			cfg.jfShop = _arr[titleArrs[2]].GetInt();
			cfg.rankType = _arr[titleArrs[3]].GetInt();
			m_zhuanPanCfgs[cfg.type] = cfg;
		}
	}

	{
		const string file = "zhuanpan_key.json";

		//                             0       1        2
		const char* titleArrs[] = { "type", "count", "cost" };
		const int typeArrs[] = { EJPT_INT, EJPT_INT, EJPT_ARRAY };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuoDongManage::InitJiJinCfg >> LoadJosnValue zhuanpan_config.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &_arr = _para[i];
			uint8 type = _arr[titleArrs[0]].GetInt();
			ZhuanPanCfg* cfg = GetZhuanPanCfg(type);
			if (cfg == NULL)
				continue;
			YaoShiJiage jg;
			jg.num = _arr[titleArrs[1]].GetInt();
			ReadSingleCost(_arr[titleArrs[2]], jg.cost);
			cfg->jiage.push_back(jg);
		}
	}

	{
		const string file = "zhuanpan.json";

		//                             0       1        2
		const char* titleArrs[] = { "type", "reward", "weight" };
		const int typeArrs[] = { EJPT_INT, EJPT_ARRAY, EJPT_INT };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CHuoDongManage::InitJiJinCfg >> LoadJosnValue zhuanpan_key.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &_arr = _para[i];
			uint8 type = _arr[titleArrs[0]].GetInt();
			ZhuanPanCfg* cfg = GetZhuanPanCfg(type);
			if (cfg == NULL)
				continue;
			ZhuanPanAward zpad;
			cfg->random.sumWeight += _arr[titleArrs[2]].GetInt();
			ReadSingleAward(_arr[titleArrs[2]], zpad.award);
			cfg->random.awards.push_back(zpad);
		}
	}
	return true;
}

MultiAward* CHuoDongManage::GetQiRiAward(uint8 day)
{
	U8MultiAwardMapIt it = m_qiRiAwards.find(day);
	if (it != m_qiRiAwards.end())
		return &it->second;

	return NULL;
}

ZhuanPanCfg* CHuoDongManage::GetZhuanPanCfg(uint8 idx/* = 0*/)
{
	static uint8 ZhuanPanHdId = 10;
	if (idx == 0)
		idx = GetHuoDongIdx(ZhuanPanHdId);
	ZhuanPanCfgMapIt it = m_zhuanPanCfgs.find(idx);
	if (it != m_zhuanPanCfgs.end())
		return &it->second;

	return NULL;
}

uint8 CHuoDongManage::GetHuoDongIdx(uint8 type)
{
	U8tU8MapIt it = m_curHuoDong.find(type);
	if (it != m_curHuoDong.end())
		return it->second;
	return 0;
}


HuoDongOpenCfg* CHuoDongManage::GetHuoDongCfg(uint8 type)
{
	HuoDongOpenCfgMapIt it = m_huoDongOpenCfg.find(type);
	if (it != m_huoDongOpenCfg.end())
		return &it->second;

	return NULL;
}

//void CHuoDongManage::GetHistory(CUser *pUser, SZhaDanInfo *info, vector<string> &myHisTory, vector<string> &publicHistory)
//{
//	char buf[512];
//
//	char goods[100];
//	if (info->award < 60000)
//	{
//		snprintf(goods, sizeof(goods), "[c%d]%s[/c]*%u", ITEM_NAME_COLOR, GetItemName(info->award), info->num);
//	}
//	else if (info->award == HDAT_MONEY)
//	{
//		snprintf(goods, sizeof(goods), LANGUAGE_TRANSFORM_131, ITEM_NAME_COLOR, info->num);
//	}
//	else if (info->award == HDAT_BANG_YB)
//	{
//		snprintf(goods, sizeof(goods), LANGUAGE_TRANSFORM_132, ITEM_NAME_COLOR, info->num);
//	}
//	else if (info->award == HDAT_PET)
//	{
//		snprintf(goods, sizeof(goods), "[c%d]%s[/c]", ITEM_NAME_COLOR, GetPetName(info->num));
//	}
//	else if (info->award == HDAT_YB)
//	{
//		snprintf(goods, sizeof(goods), LANGUAGE_TRANSFORM_133, ITEM_NAME_COLOR, info->num);
//	}
//	else if (info->award == HDAT_EXP)
//	{
//		snprintf(goods, sizeof(goods), LANGUAGE_TRANSFORM_134, ITEM_NAME_COLOR, info->num);
//	}
//	else if (info->award == HDAT_QIANNENG)
//	{
//		snprintf(goods, sizeof(goods), LANGUAGE_TRANSFORM_135, ITEM_NAME_COLOR, info->num);
//	}
//
//	{
//		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_136, goods);
//		string history = buf;
//		myHisTory.push_back(history);
//	}
//
//	if (info->notice == 1)
//	{
//		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_137, ROLE_NAME_COLOR, pUser->GetName(), goods);
//		string history = buf;
//		publicHistory.push_back(history);
//	}
//
//	if (info->notice == 1)
//	{
//		snprintf(buf, sizeof(buf), LANGUAGE_TRANSFORM_138, ROLE_NAME_COLOR, pUser->GetName(), goods);
//		SysInfoToAllUser(buf);
//	}
//}

void CHuoDongManage::InitHuoDong()
{
	//tm zeroTm;
	time_t startTime = GetSysTime();

	for (size_t i = 0; i < m_maxChiXuDay; --i)
	{
		startTime -= daySec;
		tm* zeroTm = localtime(&startTime);
		uint16 checkDay = zeroTm->tm_mday + zeroTm->tm_mon * 100;
		CheckNewDayHuoDong(checkDay);
	}
}

void CHuoDongManage::CheckNewDayHuoDong(uint16 checkDay/* = 0*/)
{
	if (checkDay == 0)
	{
		time_t startTime = GetSysTime();
		tm* zeroTm = localtime(&startTime);
		checkDay = zeroTm->tm_mday + zeroTm->tm_mon * 100;
	}

	//CHuoDongAwardManager& hmgr = sCHuoDongAwardManager;
	uint32 zeroTime = GetTodayZero();

	for (U8tU8MapIt it = m_curHuoDong.begin(); it != m_curHuoDong.end(); it++)
	{
		uint8 hdId = it->first;
		HuoDongOpenCfg* cfg = GetHuoDongCfg(hdId);
		if (cfg != NULL)
		{
			if (cfg->finishTime <= zeroTime)
				m_curHuoDong.erase(it);
		}
	}

	HuDongTimeCfgMapIt it = m_huoDongTimeCfg.find(checkDay);
	if (it == m_huoDongTimeCfg.end())
		return;

	HuDongTimeCfg& cfg = it->second;
	for (U8tU8MapIt it = cfg.openHuoDong.begin(); it != cfg.openHuoDong.end(); it++)
	{
		uint8 hdId = it->first;
		uint8 hdIdx = it->second;
		HuoDongOpenCfg* cfg = GetHuoDongCfg(hdId);
		if (cfg != NULL)
		{
			cfg->startTime = zeroTime;
			cfg->endTime = cfg->startTime + daySec * cfg->openDay;
			cfg->finishTime = cfg->endTime + daySec * cfg->finishDay;
			m_curHuoDong[hdId] = hdIdx;
		}
	}
}