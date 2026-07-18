#include "xun_bao_manage.h"
#include "init.h"
#include "call_script.h"
#include "chuangguan_reward_manager.h"
#include "utility.h"
#include <vector>
#include "rapidjson/document.h"
#include "arena.h"
#include "role_simple_mgr.h"

extern const char *gConfigFile;

int CXunBaoManage::XUNBAO_FIGHT_CNT = 0; // 寻宝战斗次数
vector<int> CXunBaoManage::BuyCost = vector<int>();

void KunLunFight::MakeLessHpMsg(CNetMessage& msg)
{
	msg << (uint8)hpPercent.size();
	for (size_t i = 0; i < hpPercent.size(); i++)
	{
		lessUnit& unit = hpPercent[i];
		msg << unit.pos << unit.hp << unit.maxHp;
	}
}

CChuangGuanMapManager::CChuangGuanMapManager()
{
	set<uint8> vec;
	vec.insert(1);
	vec.insert(2);
	vec.insert(3);
	m_fightPos[0] = vec;

	vec.clear();
	vec.insert(4);
	vec.insert(2);
	vec.insert(3);
	m_fightPos[1] = vec;

	vec.insert(1);
	vec.insert(5);
	vec.insert(3);
	m_fightPos[2] = vec;

	vec.insert(1);
	vec.insert(2);
	vec.insert(6);
	m_fightPos[3] = vec;

	vec.insert(2);
	vec.insert(3);
	vec.insert(5);
	vec.insert(7);
	m_fightPos[4] = vec;

	vec.insert(1);
	vec.insert(3);
	vec.insert(3);
	vec.insert(6);
	vec.insert(8);
	m_fightPos[5] = vec;

	vec.insert(1);
	vec.insert(2);
	vec.insert(5);
	vec.insert(9);
	m_fightPos[6] = vec;
}

bool CChuangGuanMapManager::Init()
{
	m_chuangGuanMaps.clear();
	//                       0        1         2         3
	const char *keys[] = { "map", "position", "etype", "rand" };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("chuangguan.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		uint8 mapId = (uint8_t)atoi(data[i][keys[0]].c_str());
		allEvts tmp;
		pair<allMapsIt, bool> itb = m_chuangGuanMaps.insert(make_pair(mapId, tmp));
		allEvts& evts = itb.first->second;
		cell_pos postions;

		char buf[128];
		int num = 0;
		char *p[10];
		char *p1[10];

		// 位置
		string str = data[i][keys[1]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ',');
		if (num < 2)
		{
			return false;
		}
		postions.start = (uint8_t)atoi(p[0]);
		postions.end = (uint8_t)atoi(p[1]);

		// 事件类型
		str = data[i][keys[2]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, ';');
		for (int ei = 0; ei < num; ++ei)
		{
			uint8 evt = (uint8)atoi(p[ei]);
			postions.evts.push_back((uint8_t)atoi(p[ei]));
			if (evt == 5)
			{
				m_chuangGuanCellCnts.insert(make_pair(mapId, postions.end));
			}
		}

		// 事件数量
		str = data[i][keys[3]];
		strncpy(buf, str.c_str(), sizeof(buf));
		num = SplitLine(p, buf, '|');
		for (int ri = 0; ri < num; ++ri)
		{
			int cnt = SplitLine(p1, p[ri], ',');
			if (cnt < 2)
			{
				continue;
			}
			postions.rands.push_back(make_pair(atoi(p1[0]), atoi(p1[1])));
		}
		evts.push_back(postions);
	}
	return InitKunLun() && InitSanJie();
}

bool CChuangGuanMapManager::InitKunLun()
{
	const string file = "kunlun.json";
	//                            0       1         2        3           4
	const char* titleArrs[] = { "id", "chapter", "ratio", "reward", "level_reward" };
	const int typeArrs[] = { 0, 0, 2, 2, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CChuangGuanMapManager::Init >> LoadJosnValue kunlun.json error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		KunlunCfg cfg;
		uint8 tid = data[titleArrs[1]].GetInt();
		const rapidjson::Value &_pArr = data[titleArrs[2]];
		if (_pArr.Size() >= 2)
		{
			cfg.powerPercent = _pArr[1].GetInt() / 10000.0;
			cfg.epowerPercent = _pArr[0].GetInt() / 10000.0;
		}
		ReadMultiAward(data[titleArrs[3]], cfg.finishAward);
		cfg.fightAwardId = data[titleArrs[4]].GetInt();
		m_kunlunCfgs[tid] = cfg;
	}
	return true;
}

bool CChuangGuanMapManager::InitSanJie()
{
	{
		const string file = "sanjie.json";
		//                            0     1          2        3         4          5              6            7         8
		const char* titleArrs[] = { "id", "name", "quality", "unlock", "reward", "fix_reward", "add_fragment", "show", "dialogue" };
		const int typeArrs[] = { 0, 1, 0, 0, 0, 2, 2, 2, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CChuangGuanMapManager::InitSanJie >> LoadJosnValue sanjie.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			YouLiCfg cfg;
			cfg.id = data[titleArrs[0]].GetInt();
			cfg.quality = data[titleArrs[2]].GetInt();
			cfg.level = data[titleArrs[3]].GetInt();
			cfg.rewardId = data[titleArrs[4]].GetInt();
			cfg.sumWeight = 0;
			ReadMultiAward(data[titleArrs[5]], cfg.normalReward);
			const rapidjson::Value &sarr = data[titleArrs[7]];
			for (size_t si = 0; si < sarr.Size(); si++)
			{
				const rapidjson::Value &arr = sarr[si];
				if (arr.Size() == 2)
				{
					uint16 num = arr[0].GetInt();
					uint16 weight = arr[1].GetInt();
					cfg.sumWeight += weight;
					weight = cfg.sumWeight;
					cfg.suiPianRatio[num] = weight;
				}
			}
			cfg.dlgId = data[titleArrs[8]].GetInt();
			m_youLiCfgs[cfg.id] = cfg;
		}
	}
	{
		const string file = "sanjie_cost.json";
		//                            0     1         2         3
		const char* titleArrs[] = { "id", "name", "interval", "cost" };
		const int typeArrs[] = { 0, 0, 0, 2 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CChuangGuanMapManager::InitSanJie >> LoadJosnValue sanjie_cost.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			YouLiCost cfg;
			cfg.id = data[titleArrs[0]].GetInt();
			cfg.smallSec = data[titleArrs[2]].GetInt() * 60;
			cfg.bigSec = 3600 * 4;
			ReadMultiCost(data[titleArrs[3]], cfg.costs);
			m_youLiCosts[cfg.id] = cfg;
		}
	}
	{
		const string file = "sanjie_dialogue.json";
		//                            0     1
		const char* titleArrs[] = { "id", "type" };
		const int typeArrs[] = { 0, 0 };  // 0-int 1-string 2-array
		rapidjson::Document d;
		rapidjson::Value _para;
		if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
		{
			cout << "CChuangGuanMapManager::InitSanJie >> LoadJosnValue sanjie_dialogue.json error " << endl;
			return false;
		}

		for (uint32 i = 0; i < _para.Size(); i++)
		{
			const rapidjson::Value &data = _para[i];
			uint8 id = data[titleArrs[0]].GetInt();
			uint16 type = data[titleArrs[1]].GetInt();
			YouLiDlgCfg* cfg = GetYouLiDlgCfg(type);
			if (cfg == NULL)
			{
				YouLiDlgCfg tmp;
				tmp.push_back(id);
				m_youLiDlgs[type] = tmp;
			}
			else
			{
				cfg->push_back(id);
			}
		}
	}
	return true;
}

allEvts* CChuangGuanMapManager::GetMapById(uint8_t mapId)
{
	allMapsIt it = m_chuangGuanMaps.find(mapId);
	if (it == m_chuangGuanMaps.end())
	{
		return NULL;
	}
	return &it->second;
}

uint8 CChuangGuanMapManager::GetMapCellCnt(uint8_t mapId)
{
	cellCntMapIt it = m_chuangGuanCellCnts.find(mapId);
	if (it == m_chuangGuanCellCnts.end())
	{
		return 0;
	}
	return it->second;
}

KunlunCfg* CChuangGuanMapManager::GetKunLunCfg(uint8 id)
{
	KunlunCfgMapIt it = m_kunlunCfgs.find(id);
	if (it == m_kunlunCfgs.end())
		return NULL;
	return &it->second;
}

bool CChuangGuanMapManager::CanAttack(uint8 cpos, uint8 apos)
{
	KLFightPosMapIt it = m_fightPos.find(cpos);
	if (it == m_fightPos.end())
		return false;

	return it->second.find(apos) != it->second.end();
}

YouLiCost * CChuangGuanMapManager::GetYouLiCost(uint8 type)
{
	YouLiCostMapIt it = m_youLiCosts.find(type);
	if (it == m_youLiCosts.end())
		return NULL;
	return &it->second;
}

YouLiCfg * CChuangGuanMapManager::GetYouLiCfg(uint8 id)
{
	YouLiCfgMapIt it = m_youLiCfgs.find(id);
	if (it == m_youLiCfgs.end())
		return NULL;
	return &it->second;
}

YouLiDlgCfg * CChuangGuanMapManager::GetYouLiDlgCfg(uint8 id)
{
	YouLiDlgMapIt it = m_youLiDlgs.find(id);
	if (it == m_youLiDlgs.end())
		return NULL;
	return &it->second;
}

uint8 CChuangGuanMapManager::RandDlgId(uint8 type)
{
	YouLiDlgCfg* cfg = GetYouLiDlgCfg(type);
	if (cfg == NULL)
		return 0;
	uint8 id = Random(0, cfg->size() - 1);
	return (*cfg)[id];
}

CXunBaoManage::CXunBaoManage(CUser* pUser)
	: m_pUser(pUser)
	, m_hasMatch(false)
	, m_floor(1)
{
}

bool CXunBaoManage::CreateMap()
{
	if (!m_xunBao.empty())
		return true;
	allEvts* evts = sCChuangGuanMapManager.GetMapById(1);
	if (evts == NULL)
	{
		return false;
	}
	uint8 cellCt = sCChuangGuanMapManager.GetMapCellCnt(1);
	if (cellCt == 0)
	{
		return false;
	}

	ClearMap();
	m_xunBao.resize(cellCt);

	allEvts& mapEvt = *evts;
	for (size_t i = 0; i < mapEvt.size(); i++)
	{
		cell_pos& curPos = mapEvt[i];
		/*if (curPos.start == curPos.end)
		{

			AddEvent(curPos.start, curPos.evts[0]);
			continue;
		}*/

		if (curPos.evts.size() != curPos.rands.size())
		{
			return false;
		}

		uint32 allCellNums = curPos.end - curPos.start + 1; // 总格子
		std::vector<uint32> lessNums;   // 最小事件数
		for (size_t ri = 0; ri < curPos.rands.size(); ++ri)
		{
			evt_rand erand = curPos.rands[ri];
			lessNums.push_back(erand.first);
		}

		std::vector<uint32> evts;			// 本次随机出来的事件
		for (size_t ri = 0; ri < curPos.rands.size(); ++ri)
		{
			evt_rand& erand = curPos.rands[ri];
			// 预留格子
			int desNums = evts.size();
			for (size_t di = ri + 1; di < lessNums.size(); ++di)
			{
				desNums += lessNums[di];
			}
			int curNums = allCellNums - desNums; // 当前可以用的格子
			int randMax = erand.second > curNums ? curNums : erand.second; // 可以用的格子较少 则不能超过可用格子 否则就用配置最大数
			int num = Random(erand.first, randMax);
			for (; num > 0; --num)
			{
				evts.push_back(curPos.evts[ri]);
			}
		}

		// 剩余格子填空
		int nilNums = allCellNums - evts.size();
		for (; nilNums > 0; --nilNums)
		{
			evts.push_back(0);
		}

		// 随即发牌
		int allCnt = evts.size();
		int pos = curPos.start;
		if (allCnt == 1)
		{
			AddEvent(pos++, evts[0]);
		}
		else
		{
			while (allCnt > 0)
			{
				int idx = Random(0, --allCnt);
				int left = evts[idx];
				evts[idx] = evts[allCnt];
				evts[allCnt] = left;
				AddEvent(pos++, left);
			}
		}
	}
	m_pUser->SetExtData32(443, 0);
	m_pUser->SetExtData8(94, m_pUser->GetExtData8(94) + 1);
	SingletonCMissionManager::instance().VerifyNewBranchMissionFinish(m_pUser, EMISS_DC_32);
	m_pUser->SetBitSet(607);
	return true;
}

void CXunBaoManage::AddEvent(uint8 cellId, uint8 evt)
{
	m_xunBao[cellId - 1] = evt;
	if (evt == 2)
	{
		xunBaoFight fight;
		fight.cid_ = cellId;
		m_fights.push_back(fight);
	}
}

void CXunBaoManage::ClearMap(bool clearSum/* = false*/)
{
	// 所有事件清空
	m_xunBao.clear();
	m_fights.clear();
	if (clearSum)
	{
		m_award.exp_ = 0;
		m_award.coin_ = 0;
		m_award.gold_ = 0;
	}

	m_report.killer_ = 0;
	m_report.enemys_ = 8;
	m_curIdx = 1;
	m_stopIdx = 1;

	m_pUser->SetExtData32(443, 0);  // 使用次数
	m_pUser->SetExtData32(449, 0);  // 购买筛子次数
	m_hasMatch = false;
	m_state = 0;

	m_klFight.clear();
	m_floor = 1;
	m_curPos = 0;
	m_fightCnt = XUNBAO_FIGHT_CNT;
	m_buyCnt = 0;
	m_fightPos = 0;
}

void CXunBaoManage::ResetMap()
{
	if(m_pUser->GetExtData8(21) >= CXunBaoManage::JOIN_LIMIT)
		return;
	ClearMap();
	m_pUser->SetExtData8(21, m_pUser->GetExtData8(21) + 1);	// 完成次数+1
	NotifyMapInfo();
}

void CXunBaoManage::LoadMatchFights(CNetMessage& msg)
{
#ifdef KUA_FU
	m_pUser->ClearBitSet(614);
#else
	m_pUser->SetBitSet(614);
#endif
	uint8 num = 0;
	msg >> num;
	const int robotSize = 20;
	int robots[robotSize + 1];
	bool ret = RandomSequence(robots, robotSize, robotSize);
	if (!ret) return;

	int robotCnt = 0;
	CRobotMgr& mgr = SingletonCRobotMgr::instance();
	CSimpleRoleDataMgr& rmgr = SingletonCSimpleRoleDataMgr::instance();
	for (uint8 i = 0; i < num; ++i)
	{
		uint32 id = 0;
		msg >> id;

		xunBaoFight match;
		if (id == 0)
		{
			// 读机器人
			SRobotData robot;
			mgr.GetRobot(EROT_KunLun, 2000 + robots[robotCnt++], robot);

			match.uid_ = robot.id;
			match.name_ = robot.name;
			match.lv_ = 1;
			match.career_ = robot.head;
			match.sex_ = robot.sex;
			match.robot_ = 1;
			match.pwoer = robot.power;
			m_fights[i] = match;
		}
		else
		{
			match.uid_ = id;
			SRoleSimpleData sdata;
			if (rmgr.GetRoleData(match.uid_, sdata))
			{
				match.pwoer = sdata.power;
				match.name_ = sdata.name;
				match.lv_ = sdata.level;
				match.career_ = sdata.head;
				match.sex_ = sdata.sex;
				match.robot_ = 0;
			}
			else
			{
				SRobotData robot;
				mgr.GetRobot(EROT_KunLun, 2000 + robots[robotCnt++], robot);

				match.uid_ = robot.id;
				match.name_ = robot.name;
				match.lv_ = 1;
				match.career_ = robot.head;
				match.sex_ = robot.sex;
				match.robot_ = 1;
				match.pwoer = robot.power;
			}
			m_fights[i] = match;
		}
	}

	sort(m_fights.begin(), m_fights.end());
}

void CXunBaoManage::NotifyMapInfo()
{
#ifdef KUA_FU
	if (m_pUser->HaveBitSet(614))
		m_hasMatch = false;
#else
	if (!m_pUser->HaveBitSet(614))
		m_hasMatch = false;
#endif
	if (!m_hasMatch)
	{
		if (m_hasMatch)
		{
			return;
		}
		int day = m_pUser->GetExtData32(455);
		int percent = 75;
		if (day < 3)
		{
			percent = 45;
		}
		// 根据最高总战力 请求匹配数据
		CNetMessage synsMsg;
		synsMsg.SetType(MSG_SERVER_USER_POWER);
		synsMsg << (uint8)2 << m_pUser->GetRoleId() << m_pUser->GetExtData32(118) << percent;
		SingletonSocket::instance().SendServerMsg(EST_MATCH, synsMsg);

		m_hasMatch = true;
		return;
	}
	
	CNetMessage msg;
	uint32_t userid = m_pUser->GetRoleId();
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_QueryInfo; // op =15

	uint32 timediff = GetTomorrowMillsec();
	msg << timediff << m_award.exp_ << m_award.coin_ << m_award.gold_;
	// 筛子
	uint32 rollmax = 25;
	m_pUser->SetExtData32(442, rollmax);

	uint32 userolltimes = m_pUser->GetExtData32(443);  // 已经使用的次数
	//      上限              当前
	msg << (uint32)rollmax << rollmax - userolltimes << m_report.enemys_ << m_report.killer_;
	msg << (uint32)m_xunBao.size() << (uint32)m_curIdx;

	uint8 fightInd = m_report.killer_;
	for (size_t mi = 0; mi < m_xunBao.size(); ++mi)
	{
		msg << (uint32) mi + 1 << (uint32)m_xunBao[mi] << (uint32)1;
		if (m_xunBao[mi] == 2)
		{
			if (fightInd >= m_fights.size())
			{
				cout << "NotifyMapInfo to " << userid << " error !!!, fightInd is overload!!!" << endl;
				return;
			}

			xunBaoFight& fight = m_fights[fightInd++];
			msg << (uint32)fight.uid_;
			msg << (uint32)fight.career_;
			msg << (uint32)fight.lv_;
			msg << (uint32)fight.sex_;
			msg << (uint32)fight.pwoer;
			msg << fight.name_;
			msg << (uint8) 1 << (uint16)60000 << (uint16)100;
		}
	}

	CSocketServer &sock = SingletonSocket::instance();
	sock.SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::UserBuyRollTimes()
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_BuyRollTimes; // op = 21

	uint32 buyrolltimes = 1; // TODO 
	uint32 currroll = m_pUser->GetExtData32(442);
	uint32 userolltimes = m_pUser->GetExtData32(443); // 使用次数累计

	if (userolltimes <= 0)
	{
		// 一次也没有使用 
		msg << (uint8)PRO_ERROR;
		msg << CXunBaoManage::HAVE_FULL_ROLLTIMES;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}

	CCallScript *pScript = GetScript();//script("10000.lua");
	char *pInfo = NULL;
	if (pScript == NULL)
	{
		return;
	}
	char fun[64];
	snprintf(fun, sizeof(fun), "QueryChuangGuanConfig");
	pScript->Call(fun, "u>s", m_pUser, &pInfo);

	if (pInfo == NULL)
	{
		msg << (uint8)PRO_ERROR;
		msg << CXunBaoManage::HAVE_FULL_ROLLTIMES;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}
	std::vector<std::string> vec;
	std::string str(pInfo);
	SplitString(str, vec, '-');
	uint32 curbuytimes = m_pUser->GetExtData32(449);
	if (curbuytimes >= (uint32)atoi(vec[2].c_str()))
	{
		msg << (uint8)PRO_ERROR;
		msg << CXunBaoManage::ROLL_BUYTIMES_MAXLIMIT;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}
	static int buyCost = 50;
	if (m_pUser->GetTongBao() < buyCost)
	{
		msg << (uint8)PRO_ERROR;
		msg << CXunBaoManage::NOT_ENOUGH_MONEY;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}
	m_pUser->AddTongBao(-buyCost); // 扣5个元宝

	// ======================
	// 2.加次数
	uint32 diff = currroll - userolltimes;          // 剩余的次数
	uint32 newdiff = buyrolltimes + diff;           // 新的剩余次数
	if (buyrolltimes + diff >= currroll) {
		newdiff = currroll;
	}

	if (userolltimes - buyrolltimes <= 0)
	{
		m_pUser->SetExtData32(443, 0);  // 使用次数归零 
	}
	else
	{
		m_pUser->SetExtData32(443, userolltimes - buyrolltimes); // 使用次数减 
	}

	msg << (uint8)PRO_SUCCESS;
	msg << currroll;
	msg << newdiff;

	sock.SendMsg(m_pUser->GetSock(), msg);
	m_pUser->SetExtData32(449, curbuytimes + 1);
}

void CXunBaoManage::UserQueryBuyRollInfo()
{
	if (m_xunBao.empty())
		return;
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_QueryBuyRollInfo;
	
	// op = 22 0.是否是vip 1.扣钱 2.加次数
	CCallScript *pScript = GetScript();//script("10000.lua");
	char *pInfo = NULL;
	if (pScript != NULL)
	{
		char fun[64];
		snprintf(fun, sizeof(fun), "QueryChuangGuanConfig");
		pScript->Call(fun, "u>s", m_pUser, &pInfo);
	}

	if (pInfo != NULL)
	{
		std::vector<std::string> vec;
		std::string str(pInfo);
		SplitString(str, vec, '-');
		uint32 curbuytimes = m_pUser->GetExtData32(449);
		msg << (uint8)PRO_SUCCESS;
		msg << (uint32)atoi(vec[3].c_str()); // 60000 金币 60001 绑定元宝 60003元宝  
		msg << (uint32)atoi(vec[4].c_str()); // 5个元宝
		msg << curbuytimes;
		msg << (uint32)atoi(vec[2].c_str()); // 购买次数上限
		CSocketServer &sock = SingletonSocket::instance();
		sock.SendMsg(m_pUser->GetSock(), msg);
		//	cout<<"UserQueryBuyRollInfo uid  = "<< userid <<endl;
	}
}

// 玩石头剪刀布
void CXunBaoManage::PlayHand()
{
	if (m_xunBao.empty())
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	int res = Random(0, 2);
	msg << (uint8)CXunBaoManage::ECGOp_Hand << PRO_SUCCESS << (uint8)res;
	if (res == 1)
	{
		m_state = 0;
		AddChuangguanMaterial(XBE_Hand);
	}
	if (res == 2)
	{
		msg << MakeStringColor(LANGUAGE_TRANSFORM_18, TIPS_WARNING_COLOR);
	}
	else
	{
		m_state = 0;
		msg << MakeStringColor(LANGUAGE_TRANSFORM_19, TIPS_WARNING_COLOR);
	}
	sock.SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::AddChuangguanMaterial(int type, bool isFight/* = false*/, MultiAward* awards/* = NULL*/)
{
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_RewardSum;
	do
	{
		std::vector<SAwardData> awvec;
		//if (type == 0) // 增加经验
		//{
		//	int addexp = SingletonHuoDongExpManager::instance().GetHuoDongExp(6, m_pUser->GetLevel(), 1.0 / 25);
		//	m_pUser->AddExp(addexp, true, isFight);
		//	m_award.exp_ += addexp;
		//}
		//else
		{
			int dropId = sChuangguanRewardManager.GetDropId(type);
			if (dropId == 0)
			{
				break;
			}
			sAwardManager.GetLevelAward(dropId, m_pUser->GetLevel(), awvec);
			for (size_t i = 0; i < awvec.size(); ++i)
			{
				SAwardData& award = awvec[i];
				switch (awvec[i].type)
				{
				case HDAT_MONEY:
					m_award.coin_ += award.num;
					break;
				case HDAT_BANG_YB:
					m_award.gold_ += award.num;
					break;
				default:
					break;
				}
				//SaveBuyShopItem(m_pUser->GetRoleId(), MUT_XunBaoAd, 1, award.type, award.num, m_pUser->GetMaterial(award.type), MUT_XunBaoAd);
			}
			if (XBE_Robber != type)
				m_pUser->AddMutilMaterial(awvec);
			if (awards != NULL)
				*awards = awvec;
		}
		msg << (uint32)m_award.exp_;
		msg << (uint32)m_award.coin_;
		msg << (uint32)m_award.gold_;
		SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
		return;
	} while (false);
	msg << (uint32)0 << (uint32)0 << (uint32)0;
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
}

// roll点 返回成功或者出错类型
void CXunBaoManage::Roll()
{
	if (m_xunBao.empty())
		return;
	// zqxchuangguan
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_Roll;

	// 处理 当前位置未处理的事件
	DoStopEvt();
	if (m_state == 1)
	{
		msg << (uint8)PRO_ERROR;
		msg << (uint32)CXunBaoManage::FIGHT_CELL;
		msg << MakeStringColor(LANGUAGE_TRANSFORM_2958, TIPS_FAILURE_COLOR);
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}
	else if (m_state == 2)
	{
		msg << (uint8)PRO_ERROR;
		msg << (uint32)3;  // 猜拳
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}
	// ======================
	// 1. 验证掷筛子次数是否受限？
	uint32 currroll = m_pUser->GetExtData32(442); // 当前总次数
	uint32 userolltimes = m_pUser->GetExtData32(443);  // 已经使用的次数
	if (userolltimes >= currroll)
	{
		// 没有次数了
		msg << PRO_ERROR;
		msg << (uint32)CXunBaoManage::ROLL_TIMES_LIMIT; // 筛子次数受限  
		msg << MakeStringColor(LANGUAGE_TRANSFORM_1576, TIPS_FAILURE_COLOR);
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}

	userolltimes = userolltimes + 1;
	m_pUser->SetExtData32(443, userolltimes);

	// 2. 随机数
	int roll = Random(1, 6);
	m_stopIdx = m_curIdx + roll;
	CalcStopCell();
	msg << PRO_SUCCESS;
	msg << (uint32)m_curIdx << roll;
	msg << (uint32_t)currroll;  // 筛子总数
	msg << currroll - userolltimes;  // 筛子剩余次数
	sock.SendMsg(m_pUser->GetSock(), msg);
	//AddChuangguanMaterial(0);
}

void CXunBaoManage::CalcStopCell()
{
	if (m_stopIdx > m_xunBao.size())
	{
		m_stopIdx = m_xunBao.size();
	}
	if (m_fights.empty() || m_fights.size() <= m_report.killer_)
	{
		m_curIdx = m_stopIdx;
		return;
	}
	uint8 fightCid = m_fights[m_report.killer_].cid_;
	if ((m_curIdx < fightCid && m_stopIdx >= fightCid) || m_stopIdx == fightCid - 1)
	{
		m_state = 1;
		m_curIdx = fightCid - 1;
	}
	else
	{
		m_curIdx = m_stopIdx;
	}
}

void CXunBaoManage::DoStopEvt()
{
	if (m_xunBao.empty())
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	uint8 evtId = m_xunBao[m_curIdx - 1];
	msg << (uint8)CXunBaoManage::ECGOp_MoveEnd << (uint8)evtId;
	switch (evtId)
	{
	case XBE_Box:
		AddChuangguanMaterial(XBE_Box);
		break;

	case XBE_Goal:
		AddChuangguanMaterial(XBE_Goal);
		break;

	case XBE_Coin:
		AddChuangguanMaterial(XBE_Coin);
		break;

	case XBE_Random:
		ClearEvt(m_curIdx);
		DoRandomEvent();
		CalcStopCell();
		msg << (uint32_t)m_curIdx;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;

	case XBE_End:
		AddChuangguanMaterial(XBE_End);
		ClearMap();
		m_pUser->SetExtData8(21, m_pUser->GetExtData8(21) + 1);	// 完成次数+1
		char infoMsg[512];
		snprintf(infoMsg, sizeof(infoMsg), LANGUAGE_TRANSFORM_12, ROLE_NAME_COLOR, m_pUser->GetName());
		SysInfoToAllUser(infoMsg);
		break;

	case XBE_Hand:
		m_state = 2;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;

	default:
		break;
	}
	ClearEvt(m_curIdx);
	sock.SendMsg(m_pUser->GetSock(), msg);
}

KunLunFight* CXunBaoManage::GetKunLunFight(uint8 pos)
{
	KLFightMapIt it = m_klFight.find(pos);
	if (it == m_klFight.end())
		return NULL;

	return &it->second;
}

void CXunBaoManage::LoadKunLunFights(CNetMessage & msg)
{
	uint8 num = 0;
	msg >> num >> num;
	const int robotSize = 20;
	int robots[robotSize + 1];
	bool ret = RandomSequence(robots, robotSize, robotSize);
	if (!ret) return;

	int robotCnt = 0;
	CRobotMgr& mgr = SingletonCRobotMgr::instance();
	CSimpleRoleDataMgr& rmgr = SingletonCSimpleRoleDataMgr::instance();
	for (uint8 i = 0; i < num; ++i)
	{
		uint32 id = 0;
		msg >> id;

		KunLunFight match;
		if (id == 0)
		{
			// 读机器人
			SRobotData robot;
			mgr.GetRobot(EROT_KunLun, 2000 + robots[robotCnt++], robot);

			match.uid_ = robot.id;
			match.name_ = robot.name;
			match.lv_ = 1;
			match.career_ = robot.head;
			match.sex_ = robot.sex;
			match.robot_ = 1;
			match.pwoer = robot.power;
			m_klFight[i + 1] = match;
		}
		else
		{
			match.uid_ = id;
			SRoleSimpleData sdata;
			if (rmgr.GetRoleData(match.uid_, sdata))
			{
				match.pwoer = sdata.power;
				match.name_ = sdata.name;
				match.lv_ = sdata.level;
				match.career_ = sdata.head;
				match.sex_ = sdata.sex;
				match.robot_ = 0;
			}
			else
			{
				SRobotData robot;
				mgr.GetRobot(EROT_KunLun, 2000 + robots[robotCnt++], robot);

				match.uid_ = robot.id;
				match.name_ = robot.name;
				match.lv_ = 1;
				match.career_ = robot.head;
				match.sex_ = robot.sex;
				match.robot_ = 1;
				match.pwoer = robot.power;
			}

			m_klFight[i + 1] = match;
		}
	}
	m_lastPos = 0;
	m_curPos = 0;
	m_fightPos = 0;
	CNetMessage trap;
	trap.SetType(MSG_CHUANG_GUAN);
	trap << (uint8)ECGOp_KunLunInfo;
	GetKunLunMsg(trap);
}

void CXunBaoManage::GetKunLunMsg(CNetMessage& msg)
{
	if (m_klFight.empty())
	{
		// The production path asks the standalone match server to provide nine
		// opponents. local_test intentionally has no match server, so return the
		// authoritative empty state instead of leaving the client waiting forever.
		if (gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) == "1")
		{
			uint8 lessCnt = BuyCost.size() - m_buyCnt;
			msg << m_floor << m_fightCnt << lessCnt << m_curPos << (uint8)0;
			SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
			return;
		}
		KunlunCfg* cfg = sCChuangGuanMapManager.GetKunLunCfg(m_floor);
		if (cfg == NULL)
			return;

		uint32 matchPower = m_pUser->GetExtData32(111) * cfg->powerPercent;
		uint32 ematchPower = m_pUser->GetExtData32(111) * cfg->epowerPercent;
		m_pUser->MatchFight(matchPower, ematchPower, 9);
		return;
	}
	uint8 lessCnt = BuyCost.size() - m_buyCnt;
	msg << m_floor << m_fightCnt << lessCnt << m_curPos << (uint8)m_klFight.size();
	for (KLFightMapIt it = m_klFight.begin(); it != m_klFight.end(); ++it)
	{
		KunLunFight& fight = it->second;
		msg << it->first << fight.uid_ << fight.name_ << fight.career_ << fight.sex_ << fight.lv_ << fight.pwoer << fight.robot_;
		msg << fight.state << (uint8)fight.hpPercent.size();
		for (size_t i = 0; i < fight.hpPercent.size(); i++)
		{
			lessUnit& unit = fight.hpPercent[i];
			msg << unit.pos << unit.hp << unit.maxHp;
		}
	}
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::TryKunLunFight(CNetMessage& msg)
{
	uint8 pos;
	msg >> pos;
	KunLunFight* fight = GetKunLunFight(pos);
	if (fight == NULL || fight->state == 3)
		return;
	if (fight->state == 1 && !sCChuangGuanMapManager.CanAttack(m_curPos, pos))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0199, TIPS_FAILURE_COLOR);
		return;
	}
	ShareUserPtr ptr2;
	msg << PRO_SUCCESS;
	ShareUserPtr Userptr = SingletonOnlineUser::instance().GetUserByRoleId(m_pUser->GetRoleId());
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTJueZhanKunLunFight);
	pFight->SetFightChooseMode();
	pFight->AddUserGroupToFight(Userptr);
	m_fightPos = pos;
	if (fight->robot_)	// 机器人
	{
		if (!SingletonCRobotMgr::instance().AddRobotToFight(pFight.get(), EROT_KunLun, fight->uid_))
		{
			return;
		}

		if (!fight->hpPercent.empty())
		{
			vector<SFastFightUnit> lessHp;
			for (size_t j = 0; j < fight->hpPercent.size(); j++)
			{
				lessUnit& tmp = fight->hpPercent[j];
				SFastFightUnit unit;
				unit.pos = tmp.pos;
				unit.hp = tmp.hp;
				unit.maxHp = tmp.maxHp;
				lessHp.push_back(unit);
			}
			pFight->SetUnitPercentData(lessHp);
		}
	}
	else	// 玩家
	{
		CUser *tarUser = new CUser;
		if (tarUser == NULL)
			return;
		tarUser->SetSock(-1);
		if (!tarUser->CopyUserData(fight->uid_))
		{
			delete tarUser;
			return;
		}
		tarUser->SetExtData8(85, 0);
		ptr2.reset(tarUser);
		pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);

		if (!fight->hpPercent.empty())
		{
			vector<SFastFightUnit> lessHp;
			for (size_t j = 0; j < fight->hpPercent.size(); j++)
			{
				lessUnit& tmp = fight->hpPercent[j];
				SFastFightUnit unit;
				unit.pos = tmp.pos;
				unit.hp = tmp.hp;
				unit.maxHp = tmp.maxHp;
				lessHp.push_back(unit);
			}
			pFight->SetUnitPercentData(lessHp);
		}
	}
	m_fightCnt--;
	SFastFightResult result;
	pFight->BeginFastFight(result, true, m_pUser->GetSock());
	if (result.win)
	{
		pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
		KunLunFightCallBack();
	}
	else
	{
		fight->hpPercent.clear();
		for (size_t i = 0; i < result.group2.size(); i++)
		{
			SFastFightUnit& unit = result.group2[i];
			lessUnit tmp;
			tmp.pos = unit.pos;
			tmp.hp = unit.hp;
			tmp.maxHp = unit.maxHp;
			fight->hpPercent.push_back(tmp);
		}
		fight->state = 2;
		CNetMessage trap;
		trap.SetType(MSG_CHUANG_GUAN);
		trap << (uint8)ECGOp_KunLunFightFaild << (uint8)m_fightPos << fight->state << m_fightCnt;
		fight->MakeLessHpMsg(trap);
		SingletonSocket::instance().SendMsg(m_pUser->GetSock(), trap);
	}
	sCMissionManager.UpdateQuestState(m_pUser, EMQCT_56);
	m_fightPos = pos;
}

void CXunBaoManage::BuyFightCnt(CNetMessage& msg)
{
	do 
	{
		uint8 buyCnt = 0;
		msg >> buyCnt;
		if (m_buyCnt + buyCnt > BuyCost.size())
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0225, TIPS_FAILURE_COLOR);
			break;
		}

		uint16 cost = 0;
		for (size_t i = m_buyCnt; i < m_buyCnt + buyCnt; i++)
		{
			cost += BuyCost[i];

		}
		if (!m_pUser->SubMaterial(HDAT_YB, cost))
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_TRANSFORM_2123, TIPS_FAILURE_COLOR);
			break;
		}
		ItemCurrencyLog(m_pUser->GetRoleId(), MUT_KunLun, buyCnt, HDAT_YB, cost, m_pUser->GetMaterial(HDAT_YB), MUT_KunLun);
		m_fightCnt += buyCnt;
		m_buyCnt += buyCnt;
		uint8 lessCnt = BuyCost.size() - m_buyCnt;
		msg << PRO_SUCCESS << m_fightCnt << lessCnt;
	} while (false);
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::LianXuFight(CNetMessage& msg)
{
	uint8 starPos;
	uint8 powerStop;
	uint8 cntStop;

	uint8 fightCnt = 0;
	msg >> starPos >> powerStop >> cntStop;
	msg.ReWrite();
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)ECGOp_KunLunLianChuang;
	if (starPos > 9)
		return;

	CChuangGuanMapManager& mgr = sCChuangGuanMapManager;
	do 
	{
		uint8 fcnt = 0;
		for (uint8 pi = 7; pi <= 9; ++pi)
		{
			KunLunFight* fight = GetKunLunFight(pi);
			if (fight == NULL || fight->state == 3)
				fcnt++;
		}
		if (fcnt > 1)
			break;

		if (!mgr.CanAttack(m_curPos, starPos))
			return;
	} while (false);
	KunlunCfg* cfg = mgr.GetKunLunCfg(m_floor);
	if (cfg == NULL)
		return;
	MultiAward faward;
	vector<uint8> path;
	for (size_t i = starPos; i <= (uint8)9 && m_fightCnt > 0; i += 3)
	{
		KunLunFight* fight = GetKunLunFight(i);
		if (fight->state == 3)
			continue;
		if (powerStop == 1 && fight->pwoer > m_pUser->GetZhanDouLi())
			break;


		bool win = false;
		vector<SFastFightUnit> lessHp;
		lessHp.clear();
		do 
		{
			// 战力高 直接胜利
			if (fight->pwoer < m_pUser->GetZhanDouLi())
			{
				fightCnt++;
				m_fightCnt--;
				m_curPos = i;
				fight->state = 2;
				path.push_back(m_curPos);
				win = true;
				break;
			}

			// 战力停止
			if (powerStop == 1)
				break;

			bool jixu = false;
			do 
			{
				jixu = false;
				ShareUserPtr ptr2;
				ShareUserPtr Userptr = SingletonOnlineUser::instance().GetUserByRoleId(m_pUser->GetRoleId());
				ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
				pFight->SetFightType(CFight::EFTJueZhanKunLunFight);
				pFight->SetFightChooseMode();
				pFight->AddUserGroupToFight(Userptr);
				if (fight->robot_)	// 机器人
				{
					if (!SingletonCRobotMgr::instance().AddRobotToFight(pFight.get(), EROT_KunLun, fight->uid_))
						break;
				}
				else	// 玩家
				{
					CUser *tarUser = new CUser;
					if (tarUser == NULL)
						break;
					tarUser->SetSock(-1);
					if (!tarUser->CopyUserData(fight->uid_))
					{
						delete tarUser;
						break;
					}
					tarUser->SetExtData8(85, 0);
					ptr2.reset(tarUser);
					pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);
				}
				if (!lessHp.empty())
					pFight->SetUnitPercentData(lessHp);
				SFastFightResult result;
				pFight->BeginFastFight(result);
				fightCnt++;
				m_fightCnt--;
				win = result.win;
				if (win)
				{
					pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
					KunLunFightCallBack();
					m_curPos = i;
					path.push_back(m_curPos);
					fight->state = 2;
					break;
				}
				else
					lessHp = result.group2;

				if (cntStop == 1 && m_fightCnt > 0)
					jixu = true;
			} while (jixu);
		} while (false);
		if (!win)
		{
			fight->hpPercent.clear();
			fight->state = 3;
			for (size_t j = 0; j < lessHp.size(); j++)
			{
				SFastFightUnit& unit = lessHp[j];
				lessUnit tmp;
				tmp.pos = unit.pos;
				tmp.hp = unit.hp;
				tmp.maxHp = unit.maxHp;
				fight->hpPercent.push_back(tmp);
			}
			fight->state = 2;
			CNetMessage trap;
			trap.SetType(MSG_CHUANG_GUAN);
			trap << (uint8)ECGOp_KunLunFightFaild << (uint8)i << fight->state << m_fightCnt;
			fight->MakeLessHpMsg(trap);
			SingletonSocket::instance().SendMsg(m_pUser->GetSock(), trap);
			break;
		}
		sAwardManager.GetLevelAward(cfg->fightAwardId, m_pUser->GetLevel(), faward);
		sCMissionManager.UpdateQuestState(m_pUser, EMQCT_56);
	}
	m_lastPos = m_curPos;
	msg << PRO_SUCCESS << m_fightCnt << fightCnt << m_curPos << (uint8)path.size();
	for (size_t i = 0; i < path.size(); i++)
	{
		msg << path[i];
	}
	m_pUser->AddMutilMaterial(faward, &msg);
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
	CheckFinishAward(false);
}

void CXunBaoManage::GetRobotMsg(CNetMessage& msg)
{
	uint32 uid;
	msg >> uid;
	CRobotMgr& mgr = SingletonCRobotMgr::instance();
	// 读机器人
	SRobotData robot;
	mgr.GetRobot(EROT_KunLun, uid, robot);
	if (robot.id == 0)
		return;
	msg << robot.zhenfaId << robot.zhenfaLv << (uint8)5;
	for (size_t i = 0; i < 5; i++)
		msg << robot.monsterId[i];
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::KunLunFightCallBack()
{
	if (m_fightPos > m_klFight.size())
		return;
	KunlunCfg* cfg = sCChuangGuanMapManager.GetKunLunCfg(m_floor);
	if (cfg == NULL)
		return;
	m_curPos = m_fightPos;
	m_lastPos = m_fightPos;
	m_klFight[m_fightPos].state = 3;
	m_fightPos = 0;
	MultiAward faward;
	sAwardManager.GetLevelAward(cfg->fightAwardId, m_pUser->GetLevel(), faward);
	CNetMessage trap;
	trap.SetType(MSG_CHUANG_GUAN);
	trap << (uint8)ECGOp_KunLunFightResut << m_fightCnt << m_curPos;
	MakeFightEndMsg(m_pUser, 3, trap, &faward, MUT_KunLunAd);
	SingletonSocket::instance().SendMsg(m_pUser->GetSock(), trap);
	CheckFinishAward(true);
}

void CXunBaoManage::YouLiAwardCheck()
{
	uint32 nowTime = GetSysTime();
	for (YouLiDataMapIt it = m_youLi.begin(); it != m_youLi.end(); ++it)
	{
		YouLiData& data = it->second;
		YouLiCost* ccfg = sCChuangGuanMapManager.GetYouLiCost(data.type);
		if (ccfg == NULL)
			continue;
		YouLiCfg* ycfg = sCChuangGuanMapManager.GetYouLiCfg(data.id);
		if (ycfg == NULL)
			continue;
		uint32 smallTime = nowTime - data.lastTime;
		uint8 lastCnt = ceil((data.endTime - data.lastTime) / ccfg->bigSec);
		uint8 nowCnt = ceil((data.endTime - nowTime) / ccfg->bigSec);
		uint8 cnt = smallTime / ccfg->bigSec;
		if (cnt == 0)
			continue;
		for (size_t i = 0; i < cnt; i++)
		{
			MultiAward ads;
			sAwardManager.GetAwardById(ycfg->rewardId, ads);
			data.smallAwards.push_back(ads);
			uint16 dlgId = sCChuangGuanMapManager.RandDlgId(ycfg->dlgId);
			data.dlgs.push_back(dlgId);
		}
		for (size_t i = 0; i < uint8(lastCnt - nowCnt); i++)
			data.suiPianCnt += ycfg->RankCnt();

		data.lastTime = nowTime;
	}
}

void CXunBaoManage::GetYouLiMsg(CNetMessage & msg)
{
	msg << (uint8)m_youLi.size();
	for (YouLiDataMapIt it = m_youLi.begin(); it != m_youLi.end(); ++it)
	{
		YouLiData& data = it->second;
		msg << data.id << data.type << data.cnt << data.heroId << data.lastTime << data.endTime << data.suiPianCnt;
		msg << (uint8)data.smallAwards.size();
		for (size_t i = 0; i < data.smallAwards.size(); i++)
		{
			MultiAward& ads = data.smallAwards[i];
			MakeMultiAwardMsg(ads, msg);
		}
		msg << (uint8)data.dlgs.size();
		for (size_t i = 0; i < data.dlgs.size(); i++)
			msg << data.dlgs[i];
	}
}

void CXunBaoManage::StartYouLi(CNetMessage & msg)
{
	uint8 cnt;
	msg >> cnt;
	CChuangGuanMapManager& mgr = sCChuangGuanMapManager;
	for (size_t i = 0; i < cnt; i++)
	{
		YouLiData newData;
		msg >> newData.heroId >> newData.id >> newData.type >> newData.cnt;
		if (newData.cnt == 0 || newData.cnt > 3)
			continue;

		YouLiData* data = GetYouLiData(newData.id);
		if (data != NULL)
			continue;

		if (!m_pUser->HavePet(newData.heroId))
			continue;

		YouLiCfg* ycfg = mgr.GetYouLiCfg(newData.id);
		if (ycfg == NULL)
			continue;
		YouLiCost* ccfg = mgr.GetYouLiCost(newData.type);
		if (ccfg == NULL)
			continue;
		if (ycfg->level > m_pUser->GetLevel())
			continue;

		int quality = GetPetDefaultQuality(newData.heroId);
		if (quality > ycfg->quality)
			continue;

		MultiCost cost = ccfg->costs;
		for (size_t i = 0; i < cost.size(); i++)
		{
			cost[i].costValue *= newData.cnt;
		}
		if (!m_pUser->UseMultiCost(cost))
			continue;

		uint32 nowTime = GetSysTime();
		newData.endTime = nowTime + ccfg->bigSec * newData.cnt;
		newData.lastTime = nowTime;
		m_youLi[newData.id] = newData;
	}
	msg.ReWrite();
	msg.SetType(MSG_YOU_LI);
	msg << (uint8)2<< PRO_SUCCESS;
}

void CXunBaoManage::GetYouLiAward(CNetMessage & msg)
{
	uint8 cnt;
	msg >> cnt;
	CChuangGuanMapManager& mgr = sCChuangGuanMapManager;
	MultiAward awards;
	uint32 now = GetSysTime();
	for (size_t i = 0; i < cnt; i++)
	{
		uint8 id;
		msg >> id;
		YouLiAwardCheck();
		YouLiData* data = GetYouLiData(id);
		if (data == NULL)
			continue;

		YouLiCfg* ycfg = mgr.GetYouLiCfg(data->id);
		if (ycfg == NULL)
			continue;

		if (data->endTime > now)
			continue;
		for (size_t i = 0; i < data->smallAwards.size(); i++)
		{
			MergeAwardList(awards, data->smallAwards[i]);
		}
		for (size_t i = 0; i < data->cnt; i++)
		{
			MergeAwardList(awards, ycfg->normalReward);
		}
		SPetBasicData* pData = SingletonCPetCfgMgr::instance().GetPetCfg(data->heroId);
		if (pData != NULL)
		{
			SAwardData ad;
			ad.type = pData->shengxingItemId;
			ad.num = data->suiPianCnt;
			MergeAwardData(awards, ad);
		}
	}
	msg.ReWrite();
	msg.SetType(MSG_YOU_LI);
	msg << (uint8)3 << PRO_SUCCESS;
	SendAndMakeAwardMsg(m_pUser, awards, msg);
}

YouLiData* CXunBaoManage::GetYouLiData(uint8 id)
{
	YouLiDataMapIt it = m_youLi.find(id);
	if (it == m_youLi.end())
		return NULL;

	return &it->second;
}


void CXunBaoManage::CheckFinishAward(bool isFight)
{
	if (m_curPos == 7
		|| m_curPos == 8
		|| m_curPos == 9)
	{
		uint8 fcnt = 0;
		for (uint8 pi = 7; pi <= 9; ++pi)
		{
			KunLunFight* fight = GetKunLunFight(pi);
			if (fight == NULL || fight->state == 3)
				fcnt++;
		}
		if (fcnt > 1)
			return;
		KunlunCfg* cfg = sCChuangGuanMapManager.GetKunLunCfg(m_floor);
		if (cfg == NULL)
			return;
		CNetMessage msg;
		msg.SetType(MSG_CHUANG_GUAN);
		msg << (uint8)ECGOp_KunLunAward;
		m_pUser->AddMutilMaterial(cfg->finishAward, &msg, isFight, false, MUT_KunLunAd);
		SingletonSocket::instance().SendMsg(m_pUser->GetSock(), msg);

		cfg = sCChuangGuanMapManager.GetKunLunCfg(m_floor + 1);
		if (cfg == NULL)
		{
			char buf[128];
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0238, m_pUser->GetName());
			SysInfoToAllUser(buf);
			return;
		}
		m_floor++;
		uint32 matchPower = m_pUser->GetExtData32(111) * cfg->powerPercent;
		uint32 ematchPower = m_pUser->GetExtData32(111) * cfg->epowerPercent;
		m_pUser->MatchFight(matchPower, ematchPower, 9);
	}
}

void CXunBaoManage::DoRandomEvent()
{
	int randomcell = Random(1, 5);
	int r = Random(1, 3569);
	if (r % 2)
	{
		randomcell = m_stopIdx < randomcell ? m_stopIdx - 1 : -randomcell;
	}

	m_stopIdx += randomcell;
}

void CXunBaoManage::ClearEvt(uint8 cellId)
{
	m_xunBao[cellId - 1] = 0;
}

void CXunBaoManage::FightPvP()
{
	if (m_xunBao.empty())
		return;
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	// ========================
	// 1. 判定当前格子是否是战斗格子
	if (m_xunBao[m_curIdx] != 2)
	{
		msg << CXunBaoManage::ECGOp_Robber << PRO_ERROR;
		sock.SendMsg(m_pUser->GetSock(), msg);
		return;
	}

	xunBaoFight& fight = m_fights[m_report.killer_];
	ShareUserPtr Userptr = SingletonOnlineUser::instance().GetUserByRoleId(m_pUser->GetRoleId());
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	pFight->SetFightType(CFight::EFTXunBaoFight);
	pFight->SetFightChooseMode();
	pFight->AddUserGroupToFight(Userptr);
	if (fight.robot_)	// 机器人
	{
		if (!SingletonCRobotMgr::instance().AddRobotToFight(pFight.get(), EROT_KunLun, fight.uid_))
		{
			return;
		}
	}
	else	// 玩家
	{
		CUser *tarUser = new CUser;
		if (tarUser == NULL)
			return;
		tarUser->SetSock(-1);
		if (!tarUser->CopyUserData(fight.uid_))
		{
			delete tarUser;
			return;
		}
		tarUser->SetExtData8(85, 0);
		ShareUserPtr ptr2;
		ptr2.reset(tarUser);
		pFight->AddUserGroupToFight(ptr2, CFight::EGT_GROUP2);
	}
	SFastFightResult result;
	pFight->BeginFastFight(result, true, m_pUser->GetSock());
	uint8 star = 0;
	if (result.win)
		star = pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
	PvPFightCallBack(star);
}

void CXunBaoManage::PvPFightCallBack(uint8 star)
{
	CSocketServer &sock = SingletonSocket::instance();
	CNetMessage msg;
	msg.SetType(MSG_CHUANG_GUAN);
	msg << (uint8)CXunBaoManage::ECGOp_FightReport;

	MultiAward awards;
	if (star)
	{
		m_report.killer_++;
		msg << (uint8)1;  // 战斗胜利
		ClearEvt(m_curIdx + 1); //战斗在前面一个格子
		m_curIdx = m_stopIdx;
		m_state = 0;
		AddChuangguanMaterial(XBE_Robber, true, &awards);
	}
	else
	{
		msg << (uint8)0;  // 战斗失利
	}
	msg << (uint32)m_curIdx;
	msg << (uint32)m_award.exp_;
	msg << (uint32)m_award.coin_;
	msg << (uint32)m_award.gold_;
	msg << (uint32)m_report.enemys_;  // 上限
	msg << (uint32)m_report.killer_;
	MakeFightEndMsg(m_pUser, star, msg, &awards, MUT_XunBaoAd);
	sock.SendMsg(m_pUser->GetSock(), msg);
}

void CXunBaoManage::LoadMap(const char *row)
{
	if (row == NULL || strlen(row) == 0)
	{
		ClearMap(true);
		return;
	}
	uint32 len = 4096 * 2;
	uint8 data[4096 * 2] = { 0 };
	uint32 pos = 0;

	if (!UnCompress(row, data, len))
		return;
	{
		// 所有事件
		uint8 eNum = data[pos++];
		for (uint8 ei = 0; ei < eNum; ++ei)
		{
			m_xunBao.push_back(data[pos++]);
		}

		// 战斗信息
		uint8 fNum = data[pos++];
		char fName[64];
		for (uint8 fi = 0; fi < fNum; ++fi)
		{
			xunBaoFight fight;
			pos = ReadDataFromBuf((char *)data, &fight.uid_, sizeof(fight.uid_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.cid_, sizeof(fight.cid_), pos);
			/*uint8 len = 0;
			pos = ReadDataFromBuf((char *)data, &len, sizeof(len), pos);
			pos = ReadDataFromBuf((char *)data, &fName, len, pos);*/
			pos = ReadCharFromBuf((char *)data, fName, pos);
			fight.name_ = fName;
			pos = ReadDataFromBuf((char *)data, &fight.lv_, sizeof(fight.lv_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.career_, sizeof(fight.career_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.sex_, sizeof(fight.sex_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.weapon_, sizeof(fight.weapon_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.effect_, sizeof(fight.effect_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.robot_, sizeof(fight.robot_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.pwoer, sizeof(fight.pwoer), pos);
			m_fights.push_back(fight);
		}

		// 当日奖励
		pos = ReadDataFromBuf((char *)data, &m_award.exp_, sizeof(m_award.exp_), pos);
		pos = ReadDataFromBuf((char *)data, &m_award.gold_, sizeof(m_award.gold_), pos);
		pos = ReadDataFromBuf((char *)data, &m_award.coin_, sizeof(m_award.coin_), pos);

		// 当局击杀
		pos = ReadDataFromBuf((char *)data, &m_report.enemys_, sizeof(m_report.enemys_), pos);
		pos = ReadDataFromBuf((char *)data, &m_report.killer_, sizeof(m_report.killer_), pos);

		// 当前格子
		pos = ReadDataFromBuf((char *)data, &m_curIdx, sizeof(m_curIdx), pos);

		// 战斗通过后的格子
		pos = ReadDataFromBuf((char *)data, &m_stopIdx, sizeof(m_stopIdx), pos);
		pos = ReadDataFromBuf((char *)data, &m_state, sizeof(m_state), pos);
	}

	{
		m_floor = data[pos++];
		m_curPos = data[pos++];
		m_fightCnt = data[pos++];
		m_buyCnt = data[pos++];
		m_fightPos = data[pos++];
		m_lastPos = data[pos++];

		uint8 fNum = data[pos++];
		char fName[64];
		for (uint8 fi = 0; fi < fNum; ++fi)
		{
			KunLunFight fight;
			pos = ReadDataFromBuf((char *)data, &fight.uid_, sizeof(fight.uid_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.cid_, sizeof(fight.cid_), pos);
			/*uint8 len = 0;
			pos = ReadDataFromBuf((char *)data, &len, sizeof(len), pos);
			pos = ReadDataFromBuf((char *)data, &fName, len, pos);*/
			pos = ReadCharFromBuf((char *)data, fName, pos);
			fight.name_ = fName;
			pos = ReadDataFromBuf((char *)data, &fight.lv_, sizeof(fight.lv_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.career_, sizeof(fight.career_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.sex_, sizeof(fight.sex_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.weapon_, sizeof(fight.weapon_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.effect_, sizeof(fight.effect_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.robot_, sizeof(fight.robot_), pos);
			pos = ReadDataFromBuf((char *)data, &fight.pwoer, sizeof(fight.pwoer), pos);
			pos = ReadDataFromBuf((char *)data, &fight.state, sizeof(fight.state), pos);
			uint8 hnum = data[pos++];
			for (size_t j = 0; j < hnum; j++)
			{
				lessUnit unit;
				pos = ReadDataFromBuf((char *)data, &unit.pos, sizeof(unit.pos), pos);
				pos = ReadDataFromBuf((char *)data, &unit.hp, sizeof(unit.hp), pos);
				pos = ReadDataFromBuf((char *)data, &unit.maxHp, sizeof(unit.maxHp), pos);
				fight.hpPercent.push_back(unit);
			}
			m_klFight[fi + 1] = fight;
		}
	}

	{
		uint8 ysize = data[pos++];
		for (size_t i = 0; i < ysize; i++)
		{
			YouLiData yldata;
			pos = ReadDataFromBuf((char *)data, &yldata.id, sizeof(yldata.id), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.type, sizeof(yldata.type), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.cnt, sizeof(yldata.cnt), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.heroId, sizeof(yldata.heroId), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.lastTime, sizeof(yldata.lastTime), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.endTime, sizeof(yldata.endTime), pos);
			pos = ReadDataFromBuf((char *)data, &yldata.suiPianCnt, sizeof(yldata.suiPianCnt), pos);
			uint8 asize = data[pos++];
			for (size_t si = 0; si < asize; si++)
			{
				MultiAward ad;
				uint8 sasize = data[pos++];
				for (size_t adi = 0; adi < sasize; adi++)
				{
					SAwardData sad;
					pos = ReadDataFromBuf((char *)data, &sad.type, sizeof(sad.type), pos);
					pos = ReadDataFromBuf((char *)data, &sad.num, sizeof(sad.num), pos);
					ad.push_back(sad);
				}
				yldata.smallAwards.push_back(ad);
			}
			asize = data[pos++];
			for (size_t si = 0; si < asize; si++)
			{
				uint16 dlgId;
				pos = ReadDataFromBuf((char *)data, &dlgId, sizeof(dlgId), pos);
				yldata.dlgs.push_back(dlgId);
			}
		}
	}
	return;
}

void CXunBaoManage::SaveMap(string& str)
{
	int pos = 0;
	uint8 data[4096 * 2] = {0};

	{
		// 所有事件
		uint8 eNum = m_xunBao.size();
		pos = CopyDataToBuf((char*)data, &eNum, sizeof(eNum), pos);
		for (uint8 ei = 0; ei < eNum; ++ei)
		{
			pos = CopyDataToBuf((char*)data, &m_xunBao[ei], sizeof(m_xunBao[ei]), pos);
		}
		// 战斗信息
		uint8 fNum = m_fights.size();
		pos = CopyDataToBuf((char*)data, &fNum, sizeof(fNum), pos);
		for (uint8 fi = 0; fi < fNum; ++fi)
		{
			xunBaoFight& fight = m_fights[fi];
			pos = CopyDataToBuf((char *)data, &fight.uid_, sizeof(fight.uid_), pos);
			pos = CopyDataToBuf((char *)data, &fight.cid_, sizeof(fight.cid_), pos);
			pos = CopyCharToBuf((char *)data, fight.name_.c_str(), pos);
			pos = CopyDataToBuf((char *)data, &fight.lv_, sizeof(fight.lv_), pos);
			pos = CopyDataToBuf((char *)data, &fight.career_, sizeof(fight.career_), pos);
			pos = CopyDataToBuf((char *)data, &fight.sex_, sizeof(fight.sex_), pos);
			pos = CopyDataToBuf((char *)data, &fight.weapon_, sizeof(fight.weapon_), pos);
			pos = CopyDataToBuf((char *)data, &fight.effect_, sizeof(fight.effect_), pos);
			pos = CopyDataToBuf((char *)data, &fight.robot_, sizeof(fight.robot_), pos);
			pos = CopyDataToBuf((char *)data, &fight.pwoer, sizeof(fight.pwoer), pos);
		}

		// 当日奖励
		pos = CopyDataToBuf((char *)data, &m_award.exp_, sizeof(m_award.exp_), pos);
		pos = CopyDataToBuf((char *)data, &m_award.gold_, sizeof(m_award.gold_), pos);
		pos = CopyDataToBuf((char *)data, &m_award.coin_, sizeof(m_award.coin_), pos);

		// 当局击杀
		pos = CopyDataToBuf((char *)data, &m_report.enemys_, sizeof(m_report.enemys_), pos);
		pos = CopyDataToBuf((char *)data, &m_report.killer_, sizeof(m_report.killer_), pos);

		// 当前格子
		pos = CopyDataToBuf((char *)data, &m_curIdx, sizeof(m_curIdx), pos);

		// 战斗通过后的格子
		pos = CopyDataToBuf((char *)data, &m_stopIdx, sizeof(m_stopIdx), pos);

		// 需要战斗
		pos = CopyDataToBuf((char *)data, &m_state, sizeof(m_state), pos);

	}
	{
		data[pos++] = m_floor;
		data[pos++] = m_curPos;
		data[pos++] = m_fightCnt;
		data[pos++] = m_buyCnt;
		data[pos++] = m_fightPos;
		data[pos++] = m_lastPos;

		data[pos++] = m_klFight.size();
		for (KLFightMapIt it = m_klFight.begin(); it != m_klFight.end(); it++)
		{
			KunLunFight& fight = it->second;
			pos = CopyDataToBuf((char *)data, &fight.uid_, sizeof(fight.uid_), pos);
			pos = CopyDataToBuf((char *)data, &fight.cid_, sizeof(fight.cid_), pos);
			/*uint8 len = fight.name_.length();
			pos = CopyDataToBuf((char *)data, &len, sizeof(len), pos);
			pos = CopyDataToBuf((char *)data, fight.name_.c_str(), len, pos);*/
			pos = CopyCharToBuf((char *)data, fight.name_.c_str(), pos);
			pos = CopyDataToBuf((char *)data, &fight.lv_, sizeof(fight.lv_), pos);
			pos = CopyDataToBuf((char *)data, &fight.career_, sizeof(fight.career_), pos);
			pos = CopyDataToBuf((char *)data, &fight.sex_, sizeof(fight.sex_), pos);
			pos = CopyDataToBuf((char *)data, &fight.weapon_, sizeof(fight.weapon_), pos);
			pos = CopyDataToBuf((char *)data, &fight.effect_, sizeof(fight.effect_), pos);
			pos = CopyDataToBuf((char *)data, &fight.robot_, sizeof(fight.robot_), pos);
			pos = CopyDataToBuf((char *)data, &fight.pwoer, sizeof(fight.pwoer), pos);
			pos = CopyDataToBuf((char *)data, &fight.state, sizeof(fight.state), pos);
			data[pos++] = fight.hpPercent.size();
			for (size_t fpi = 0; fpi < fight.hpPercent.size(); fpi++)
			{
				lessUnit& unit = fight.hpPercent[fpi];
				pos = CopyDataToBuf((char *)data, &unit.pos, sizeof(unit.pos), pos);
				pos = CopyDataToBuf((char *)data, &unit.hp, sizeof(unit.hp), pos);
				pos = CopyDataToBuf((char *)data, &unit.maxHp, sizeof(unit.maxHp), pos);
			}
		}
	}

	{
		data[pos++] = (uint8)m_youLi.size();
		for (YouLiDataMapIt it = m_youLi.begin(); it != m_youLi.end(); ++it)
		{
			YouLiData& ydata = it->second;
			pos = CopyDataToBuf((char *)data, &ydata.id, sizeof(ydata.id), pos);
			pos = CopyDataToBuf((char *)data, &ydata.type, sizeof(ydata.type), pos);
			pos = CopyDataToBuf((char *)data, &ydata.cnt, sizeof(ydata.cnt), pos);
			pos = CopyDataToBuf((char *)data, &ydata.heroId, sizeof(ydata.heroId), pos);
			pos = CopyDataToBuf((char *)data, &ydata.lastTime, sizeof(ydata.lastTime), pos);
			pos = CopyDataToBuf((char *)data, &ydata.endTime, sizeof(ydata.endTime), pos);
			pos = CopyDataToBuf((char *)data, &ydata.suiPianCnt, sizeof(ydata.suiPianCnt), pos);
			data[pos++] = ydata.smallAwards.size();
			for (size_t si = 0; si < ydata.smallAwards.size(); si++)
			{
				MultiAward& ad = ydata.smallAwards[si];
				data[pos++] = ad.size();
				for (size_t adi = 0; adi < ad.size(); adi++)
				{
					SAwardData& sad = ad[adi];
					pos = CopyDataToBuf((char *)data, &sad.type, sizeof(sad.type), pos);
					pos = CopyDataToBuf((char *)data, &sad.num, sizeof(sad.num), pos);
				}

			}
			data[pos++] = ydata.dlgs.size();
			for (size_t bi = 0; bi < ydata.dlgs.size(); bi++)
			{
				pos = CopyDataToBuf((char *)data, &ydata.dlgs[bi], sizeof(ydata.dlgs[bi]), pos);
			}
		}
	}

	Compress(data, pos, str);
}
