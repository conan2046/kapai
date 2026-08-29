#include "user_guanqia.h"
#include "user.h"
#include "scene_manager.h"
#include "init.h"
#include "user_spirit.h"
#include "award_manager.h"
#include "rank.h"

const int SaveDateMaxLen = 1204 * 80;
uint8 CGuanQiaCfgMgr::g_LieZhuanCnt = 0;
uint8 CGuanQiaCfgMgr::g_MaxReSetCnt = 0;

bool CGuanQiaCfgMgr::InitMap()
{
	m_resetCost.push_back(50);
	m_resetCost.push_back(50);
	m_resetCost.push_back(100);
	m_resetCost.push_back(100);
	m_resetCost.push_back(200);
	g_MaxReSetCnt = m_resetCost.size();
	return LoadBigMapCfg()
		&& LoadMapNodeCfg()
		&& LoadFixCfg()
		&& InitChengJiuCfg();
}

// 大地图数据
bool CGuanQiaCfgMgr::LoadBigMapCfg()
{
	const string file = "bigmap.json";
	//                           0        1        2        3        4         5           6            7
	const char* titleArrs[] = { "Id", "MapType", "Name", "Desc", "OpenLv", "BundleId", "OpenTime", "star_reward" };
	const int typeArrs[] = { 0, 0, 1, 1, 0, 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CGuanQiaCfgMgr::LoadBigMapCfg >> LoadJosnValue error " << endl;
		return false;
	}
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		SingleZhangJieCfg cfg;		
		cfg.id = data[titleArrs[0]].GetInt();
		cfg.type = data[titleArrs[1]].GetInt();
		cfg.openLv = data[titleArrs[4]].GetInt();
		cfg.name = data[titleArrs[2]].GetString();
		{
			const rapidjson::Value &_arr = data[titleArrs[6]];
			for (uint32 j = 0; j < _arr.Size(); j++)
			{
				uint8 week = _arr[j].GetInt();
				cfg.openWeek.insert(week);
			}
		}
		{
			
			const rapidjson::Value &_arr = data[titleArrs[7]];
			for(uint32 j=0; j < _arr.Size() ; j++)
			{
				const rapidjson::Value &_pArr = _arr[j];
				if(!_pArr.IsArray())
				{
					cout<<">> CGuanQiaCfgMgr::LoadBigMapCfg cfg  error , j="<<j<<endl;
					continue;
				}
				uint32 size = _pArr.Size();
				if(size != 2)
				{
					cout<<">> CGuanQiaCfgMgr::LoadBigMapCfg cfg size error , j="<<j<<endl;
					continue;
				}
				uint8 star = _pArr[0].GetInt();
				uint16 fixId = _pArr[1].GetInt();
				cfg.starFix[star] = fixId;
				// MultiAward* award = QueryFixAward(_pArr[1].GetInt());
				// if (award != NULL)
					// cfg.fixAwards[fixId] = *award;
			}
		}
		m_allMapCfg.insert(make_pair(cfg.id, cfg));
		
		CTypeMapsIt it = m_typeMaps.find(cfg.type);
		if (it == m_typeMaps.end())
		{
			CMapIdVec vec;
			vec.push_back(cfg.id);
			m_typeMaps.insert(make_pair(cfg.type, vec));
		}
		else
		{
			it->second.push_back(cfg.id);
		}
	}

	for(CTypeMapsIt it = m_typeMaps.begin(); it != m_typeMaps.end(); it++)
	{
		if(it->second.size() > 1)
		{
			std::sort(it->second.begin(), it->second.end());
		}
	}
	return true;
}

// 战斗节点数据
bool CGuanQiaCfgMgr::LoadMapNodeCfg()
{
	const string file = "maplist.json";
	//                           0      1        2      3       4         5           6            7             8
	const char* titleArrs[] = { "ID", "mapid", "Name", "Des", "type", "fightID", "Levellimit", "Suggestpower", "UnlockID",
		// 9       10                11          12           13           14           15            16
		"Hope", "first_reward", "rewardID", "add_reward", "show_reward", "money", "AttackCount", "BattleMapName",
		// 17                18          19         20         21          22
		"DialogueId", "RecommendHero", "fight_reward", "final_kill", "kill_reward", "max_damage" };
	const int typeArrs[] = { 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 2, 0, 1, 0, 2, 2, 2, 0, 2};  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CGuanQiaCfgMgr::LoadMapNodeCfg >> LoadJosnValue error " << endl;
		return false;
	}
	
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		uint16 mid = data[titleArrs[1]].GetInt();
		SingleZhangJieCfg* cfg = GetZhangJieCfg(mid);
		if (cfg == NULL)
		{
			cout << "CGuanQiaCfgMgr::LoadMapNodeCfg >> read map error, mapId: " << mid << endl;
			continue;
		}
		MapNodeCfg nodeCfg;
		nodeCfg.type = data[titleArrs[4]].GetInt();
		nodeCfg.maxTimes = data[titleArrs[15]].GetInt();
		nodeCfg.spiritCost = data[titleArrs[9]].GetInt();
		nodeCfg.nodeId = data[titleArrs[0]].GetInt();
		nodeCfg.fightId = data[titleArrs[5]].GetInt();
		nodeCfg.levelLimit = data[titleArrs[6]].GetInt();
		nodeCfg.nextNodeId = data[titleArrs[8]].GetInt();
		nodeCfg.rewardId = data[titleArrs[11]].GetInt();
		nodeCfg.fixId = data[titleArrs[12]].GetInt();
		nodeCfg.allUserAwardId = data[titleArrs[21]].GetInt();
		m_allNodeIds[nodeCfg.nodeId] = data[titleArrs[1]].GetInt();
		
		// MultiAward* award = QueryFixAward(nodeCfg.fixId);
		// if (award != NULL)
			// cfg->fixAwards[nodeCfg.fixId] = *award;
		nodeCfg.mapId = data[titleArrs[1]].GetInt();
		nodeCfg.name = data[titleArrs[2]].GetString();
		ReadMultiAward(data[titleArrs[10]], nodeCfg.firstAward);
		ReadMultiAward(data[titleArrs[13]], nodeCfg.normalAward);
		ReadMultiAward(data[titleArrs[14]], nodeCfg.moneyAward);
		ReadMultiAward(data[titleArrs[19]], nodeCfg.fightAward);
		ReadMultiAward(data[titleArrs[20]], nodeCfg.finalKillAward);
		ReadMultiAward(data[titleArrs[22]], nodeCfg.firstRankAward);
		cfg->nodes[nodeCfg.nodeId] = nodeCfg;
	}
	return true;
}

// 宝箱数据
bool CGuanQiaCfgMgr::LoadFixCfg()
{
	const string file = "reward_fixed.json";
	//                           0      1
	const char* titleArrs[] = { "ID", "reward" };
	const int typeArrs[] = { 0, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CGuanQiaCfgMgr::LoadNodeFixCfg >> LoadJosnValue error " << endl;
		return false;
	}
	
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		MultiAward awards;
		uint16 fixId = data[titleArrs[0]].GetInt();
		ReadMultiAward(data[titleArrs[1]], awards);
		m_allFixs[fixId] = awards;
	}
	return true;
}

bool CGuanQiaCfgMgr::InitChengJiuCfg()
{
	const string file = "map_achievement.json";
	//                            0          1           2
	const char* titleArrs[] = { "type", "condition", "reward" };
	const int typeArrs[] = { 0, 0, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CGuanQiaCfgMgr::InitChengJiuCfg >> LoadJosnValue map_achievement.json error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		ChengJiuCfg cfg;
		cfg.type = data[titleArrs[0]].GetInt();
		cfg.star = data[titleArrs[1]].GetInt();
		ReadSingleAward(data[titleArrs[2]], cfg.award);
		ChengJiuCfgVec* vec = GetChengJiuCfgVec(cfg.type);
		if (vec != NULL)
			vec->push_back(cfg);
		else
		{
			ChengJiuCfgVec tmp;
			tmp.push_back(cfg);
			m_chengJiuCfg.insert(make_pair(cfg.type, tmp));
		}
	}
	return true;
}


// 获取地图节点
MapNodeCfg* CGuanQiaCfgMgr::GetMapNodeCfg(uint32 mapId, uint32 nodeId)
{	
	SingleZhangJieCfg* cfg = GetZhangJieCfg(mapId);
	if (cfg == NULL)
		return NULL;
	CurMapNodeCfgMapIt cit = cfg->nodes.find(nodeId);
	if (cit == cfg->nodes.end())
		return NULL;
	
	return &cit->second;
}

MapNodeCfg* CGuanQiaCfgMgr::GetMapNodeCfg(uint32 nodeId)
{
	uint32 mapId = GetNodeMapId(nodeId);

	return GetMapNodeCfg(mapId, nodeId);
}



// 获取当前地图所有章节
SingleZhangJieCfg* CGuanQiaCfgMgr::GetZhangJieCfg(uint32 mapId)
{
	CAllZhangJieMapIt it = m_allMapCfg.find(mapId);
	if (it == m_allMapCfg.end())
		return NULL;
	
	return &it->second;
}

// 查询宝箱奖励
MultiAward* CGuanQiaCfgMgr::QueryFixAward(uint32 fixId)
{
	FixAwardMapIt it = m_allFixs.find(fixId);
	if (it == m_allFixs.end())
		return NULL;
	return &it->second;
}
	
// 获取宝箱信息
void CGuanQiaCfgMgr::MakeFixMsg(uint32 fixId, CNetMessage &msg)
{
	MultiAward* aw = QueryFixAward(fixId);
	if (aw == NULL)
	{
		msg << (uint8)0;
	}
	msg << (uint8)aw->size();
	for (size_t i = 0; i < aw->size(); ++i)
	{
		msg << (*aw)[i].type << (*aw)[i].num;
	}
}

// 获取重置消耗
uint16 CGuanQiaCfgMgr::GetResetCost(uint8 times)
{
	if (times >= m_resetCost.size())
		return 0;
	
	return m_resetCost[times];
}

// 地图信息
void CGuanQiaCfgMgr::MakeMapMsg(uint8 type, CNetMessage &msg)
{
	CTypeMapsIt tit = m_typeMaps.find(type);
	if (tit == m_typeMaps.end())
	{
		msg << (uint16)0;
		return;
	}
	CMapIdVec& vec = tit->second;
	msg << (uint16)vec.size();
	for (size_t i = 0; i < vec.size(); ++i)
	{
		SingleZhangJieCfg* cfg = GetZhangJieCfg(vec[i]);
		if (cfg == NULL)
		{
			msg << (uint16)0;
			continue;
		}
		msg << cfg->id << cfg->name << cfg->openLv << (uint8)(cfg->nodes.size()*3);
	}
}

// 获取章节地图Id
uint32 CGuanQiaCfgMgr::GetNodeMapId(uint32 nodeId)
{
	CurNodeMapIdMapIt it = m_allNodeIds.find(nodeId);
	if (it != m_allNodeIds.end())
		return it->second;
	
	return 0;
}

// 获取当前类型所有地图
CMapIdVec* CGuanQiaCfgMgr::GetTypeMapIds(uint8 type)
{
	CTypeMapsIt it = m_typeMaps.find(type);
	if (it == m_typeMaps.end())
		return NULL;

	return &it->second;
}

ChengJiuCfgVec* CGuanQiaCfgMgr::GetChengJiuCfgVec(uint8 type)
{
	ChengJiuCfgMapIt it = m_chengJiuCfg.find(type);
	if (it == m_chengJiuCfg.end())
		return NULL;

	return &it->second;
}

ChengJiuCfg* CGuanQiaCfgMgr::GetChengJiuCfg(uint8 type, uint8 idx)
{
	ChengJiuCfgVec* vec = GetChengJiuCfgVec(type);
	if (vec == NULL)
		return NULL;

	if (vec->size() < idx)
		return NULL;

	return &(*vec)[idx];
}

CUserGuanQia::CUserGuanQia()
{
}

CUserGuanQia::~CUserGuanQia()
{
}

void CUserGuanQia::SaveGuanQia(UserGuanQia& gq, uint8* data, int& pos)
{
	pos = CopyDataToBuf((char *)data, &gq.curMapId, sizeof(gq.curMapId), pos);
	pos = CopyDataToBuf((char *)data, &gq.curNodeId, sizeof(gq.curNodeId), pos);
	uint16 size = gq.guanQiaScores.size();
	pos = CopyDataToBuf((char *)data, &size, sizeof(size), pos);
	for (GuanQiaMapIt sit = gq.guanQiaScores.begin(); sit != gq.guanQiaScores.end(); ++sit)
	{
		pos = CopyDataToBuf((char *)data, &sit->first, sizeof(sit->first), pos);
		SingleGuanQiaScore& gs = sit->second;
		pos = CopyDataToBuf((char *)data, &gs.sumStar, sizeof(gs.sumStar), pos);
		data[pos++] = gs.nodeStars.size();
		for (NodeStarMapIt nit = gs.nodeStars.begin(); nit != gs.nodeStars.end(); ++nit)
		{
			pos = CopyDataToBuf((char *)data, &nit->first, sizeof(nit->first), pos);
			data[pos++] = nit->second;
		}
		data[pos++] = gs.fixIds.size();
		for (set<uint32>::iterator fit = gs.fixIds.begin(); fit != gs.fixIds.end(); ++fit)
		{
			uint32 fixId = *fit;
			pos = CopyDataToBuf((char *)data, &fixId, sizeof(fixId), pos);
		}
		data[pos++] = gs.fixState.size();
		for (FixGetStateIt fsit = gs.fixState.begin(); fsit != gs.fixState.end(); ++fsit)
		{
			pos = CopyDataToBuf((char *)data, &fsit->first, sizeof(fsit->first), pos);
			data[pos++] = fsit->second;
		}
	}
}

void CUserGuanQia::LoadGuanQia(UserGuanQia& gq, uint8* data, int& pos)
{
	pos = ReadDataFromBuf((char *)data, &gq.curMapId, sizeof(gq.curMapId), pos);
	pos = ReadDataFromBuf((char *)data, &gq.curNodeId, sizeof(gq.curNodeId), pos);
	uint16 size = 0;
	pos = ReadDataFromBuf((char *)data, &size, sizeof(size), pos);
	for (uint16 i = 0; i < size; ++i)
	{
		uint32 mapId = 0;
		pos = ReadDataFromBuf((char *)data, &mapId, sizeof(mapId), pos);
		SingleGuanQiaScore sg;
		pos = ReadDataFromBuf((char *)data, &sg.sumStar, sizeof(sg.sumStar), pos);
		uint8 nSize = data[pos++];
		for (uint8 ni = 0; ni < nSize; ++ni)
		{
			uint32 nodeId = 0;
			uint8 star = 0;
			pos = ReadDataFromBuf((char *)data, &nodeId, sizeof(nodeId), pos);
			star = data[pos++];			
			sg.nodeStars[nodeId] = star;
			gq.allStar += star;
		}
		
		nSize = data[pos++];
		for (uint8 ni = 0; ni < nSize; ++ni)
		{
			uint32 fixId = 0;
			pos = ReadDataFromBuf((char *)data, &fixId, sizeof(fixId), pos);	
			sg.fixIds.insert(fixId);
		}
		
		nSize = data[pos++];
		for (uint8 ni = 0; ni < nSize; ++ni)
		{
			uint32 fixId = 0;
			pos = ReadDataFromBuf((char *)data, &fixId, sizeof(fixId), pos);	
			sg.fixState[fixId] = data[pos++];
		}
		gq.guanQiaScores[mapId] = sg;
	}
}

// 数据保存
void CUserGuanQia::SaveData(string &str)
{
	int pos = 0;
	uint8 data[SaveDateMaxLen] = {0};
	// 主线 支线
	SaveGuanQia(m_guanQiaZhuScore, data, pos);
	SaveGuanQia(m_guanQiaZhiScore, data, pos);
	
	// 挑战次数
	uint16 nSize = m_nodeBeAttackCnt.size();;
	pos = CopyDataToBuf((char *)data, &nSize, sizeof(nSize), pos);
	for (NodeBeAttackCntIt ait = m_nodeBeAttackCnt.begin(); ait != m_nodeBeAttackCnt.end(); ++ait)
	{
		pos = CopyDataToBuf((char *)data, &ait->first, sizeof(ait->first), pos);
		data[pos++] = ait->second;
	}
	
	// 重置次数
	nSize = m_nodeResetCnt.size();;
	pos = CopyDataToBuf((char *)data, &nSize, sizeof(nSize), pos);
	for (NodeResetCntMapIt rit = m_nodeResetCnt.begin(); rit != m_nodeResetCnt.end(); ++rit)
	{
		pos = CopyDataToBuf((char *)data, &rit->first, sizeof(rit->first), pos);
		data[pos++] = rit->second;
	}

	data[pos++] = m_slGuanQia.size();;
	for (ShiLianGuanQiaMapIt slit = m_slGuanQia.begin(); slit != m_slGuanQia.end(); ++slit)
	{
		ShiLianGuanQia& sl = slit->second;
		pos = CopyDataToBuf((char *)data, &slit->first, sizeof(slit->first), pos);
		pos = CopyDataToBuf((char *)data, &sl.cnt, sizeof(sl.cnt), pos);
		pos = CopyDataToBuf((char *)data, &sl.sdNodeId, sizeof(sl.sdNodeId), pos);
		pos = CopyDataToBuf((char *)data, &sl.tzNodeId, sizeof(sl.tzNodeId), pos);
	}
	data[pos++] = m_lzGuanQia.cnt;
	pos = CopyDataToBuf((char *)data, &m_lzGuanQia.curMapIdx, sizeof(m_lzGuanQia.curMapIdx), pos);
	pos = CopyDataToBuf((char *)data, &m_lzGuanQia.curNodeId, sizeof(m_lzGuanQia.curNodeId), pos);
	pos = CopyDataToBuf((char *)data, &m_achId, sizeof(m_achId), pos);
	pos = CopyDataToBuf((char *)data, &m_achState, sizeof(m_achState), pos);
	Compress(data, pos, str);
}

// 数据加载
void CUserGuanQia::LoadData(const char *str)
{
	if (str == NULL || strlen(str) == 0)
	{
		InitGuanQia();
		return;
	}
	uint32 len = SaveDateMaxLen;
	uint8 data[SaveDateMaxLen];
	int pos = 0;
	if (!UnCompress(str, data, len))
		return;
	// 主线 支线
	LoadGuanQia(m_guanQiaZhuScore, (uint8*)data, pos);
	LoadGuanQia(m_guanQiaZhiScore, (uint8*)data, pos);
	
	// 挑战次数
	uint16 nSize = 0;
	pos = ReadDataFromBuf((char *)data, &nSize, sizeof(nSize), pos);
	for (uint16 ni = 0; ni < nSize; ++ni)
	{
		uint32 nodeId = 0;
		uint8 cnt = 0;
		pos = ReadDataFromBuf((char *)data, &nodeId, sizeof(nodeId), pos);
		cnt = data[pos++];
		m_nodeBeAttackCnt[nodeId] = cnt;
	}
	
	// 重置次数
	pos = ReadDataFromBuf((char *)data, &nSize, sizeof(nSize), pos);
	for (uint16 ni = 0; ni < nSize; ++ni)
	{
		uint32 nodeId = 0;
		uint8 cnt = 0;
		pos = ReadDataFromBuf((char *)data, &nodeId, sizeof(nodeId), pos);
		cnt = data[pos++];
		m_nodeResetCnt[nodeId] = cnt;
	}
	nSize = data[pos++];
	uint8 week = GetWeekDay();
	if (week == 0) week = 7;
	for (uint8 ni = 0; ni < nSize; ++ni)
	{
		ShiLianGuanQia sl;
		uint32 nodeId = 0;
		pos = ReadDataFromBuf((char *)data, &nodeId, sizeof(nodeId), pos);
		pos = ReadDataFromBuf((char *)data, &sl.cnt, sizeof(sl.cnt), pos);
		pos = ReadDataFromBuf((char *)data, &sl.sdNodeId, sizeof(sl.sdNodeId), pos);
		pos = ReadDataFromBuf((char *)data, &sl.tzNodeId, sizeof(sl.tzNodeId), pos);
		SingleZhangJieCfg* mcfg = sCGuanQiaCfgMgr.GetZhangJieCfg(nodeId);
		if (mcfg == NULL)
			continue;
		if (mcfg->openWeek.find(week) == mcfg->openWeek.end())
			sl.isOpen = false;
		else
			sl.isOpen = true;
		m_slGuanQia[nodeId] = sl;
	}
	CMapIdVec* trialMaps = sCGuanQiaCfgMgr.GetTypeMapIds(3);
	if (trialMaps != NULL)
	{
		for (size_t i = 0; i < trialMaps->size(); ++i)
		{
			uint32 mapId = (*trialMaps)[i];
			if (m_slGuanQia.find(mapId) != m_slGuanQia.end())
				continue;
			SingleZhangJieCfg* mapCfg = sCGuanQiaCfgMgr.GetZhangJieCfg(mapId);
			if (mapCfg == NULL || mapCfg->nodes.empty())
				continue;
			ShiLianGuanQia sl;
			sl.tzNodeId = mapCfg->nodes.begin()->first;
			if (mapCfg->openWeek.find(week) != mapCfg->openWeek.end())
			{
				sl.isOpen = true;
				MapNodeCfg* nodeCfg = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, sl.tzNodeId);
				if (nodeCfg != NULL)
					sl.cnt = nodeCfg->maxTimes;
			}
			m_slGuanQia[mapId] = sl;
		}
	}
	m_lzGuanQia.cnt = data[pos++];
	pos = ReadDataFromBuf((char *)data, &m_lzGuanQia.curMapIdx, sizeof(m_lzGuanQia.curMapIdx), pos);
	pos = ReadDataFromBuf((char *)data, &m_lzGuanQia.curNodeId, sizeof(m_lzGuanQia.curNodeId), pos);
	pos = ReadDataFromBuf((char *)data, &m_achId, sizeof(m_achId), pos);
	pos = ReadDataFromBuf((char *)data, &m_achState, sizeof(m_achState), pos);

	m_curType = 0;
	m_curMapId = 0;
	m_curNodeId = 0;
}

// 推图初始化
void CUserGuanQia::InitGuanQia()
{
	ShiLianGuanQia sl;
	AddNewSinggleGuanQia(1, 1001, 10001);
	CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
	CMapIdVec* mvec = mgr.GetTypeMapIds(3);
	if (mvec != NULL)
	{
		for (uint8 i = 0; i < mvec->size(); ++i)
		{
			uint32 mid = (*mvec)[i];
			SingleZhangJieCfg* mcfg = mgr.GetZhangJieCfg(mid);
			if (mcfg == NULL || mcfg->nodes.empty())
				continue;
			ShiLianGuanQia sl;
			sl.tzNodeId = mcfg->nodes.begin()->first;
			m_slGuanQia[mid] = sl;
		}
	}
	mvec = mgr.GetTypeMapIds(4);
	if (mvec != NULL)
	{
		uint32 mid = (*mvec)[0];
		SingleZhangJieCfg* mcfg = mgr.GetZhangJieCfg(mid);
		if (mcfg != NULL && !mcfg->nodes.empty())
		{
			m_lzGuanQia.curMapIdx = 0;
			m_lzGuanQia.curNodeId = mcfg->nodes.begin()->first;
			m_lzGuanQia.cnt = CGuanQiaCfgMgr::g_LieZhuanCnt;
		}
	}
	m_achId = 1;
	m_achState = 0;
	ResetGuanQia();
}

// 数据清理
void CUserGuanQia::ResetGuanQia()
{
	m_nodeBeAttackCnt.clear();
	m_nodeResetCnt.clear();
	uint8 week = GetWeekDay();
	if (week == 0) week = 7;
	for (ShiLianGuanQiaMapIt it = m_slGuanQia.begin(); it != m_slGuanQia.end(); ++it)
	{
		ShiLianGuanQia& sl = it->second;
		uint32 nodeId = sl.sdNodeId == 0 ? sl.tzNodeId : sl.sdNodeId;
		SingleZhangJieCfg* mcfg = sCGuanQiaCfgMgr.GetZhangJieCfg(it->first);
		if (mcfg == NULL)
			continue;
		if (mcfg->openWeek.find(week) == mcfg->openWeek.end())
		{
			sl.isOpen = false;
			sl.cnt = 0;
			continue;
		}
		MapNodeCfg* ncfg = sCGuanQiaCfgMgr.GetMapNodeCfg(it->first, nodeId);
		if (ncfg == NULL)
			continue;
		sl.cnt = ncfg->maxTimes;
		sl.isOpen = true;
	}
	m_lzGuanQia.cnt = CGuanQiaCfgMgr::g_LieZhuanCnt;
}

void CUserGuanQia::MakeUserGuanQiaMsg(uint8 type, CNetMessage &msg)
{
	UserGuanQia* guanQia = NULL;
	if (type == 1)
	{
		guanQia = &m_guanQiaZhuScore;
	}
	else if (type == 2)
	{
		guanQia = &m_guanQiaZhiScore;
	}
	else
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	msg << PRO_SUCCESS;
	sCGuanQiaCfgMgr.MakeMapMsg(type, msg);
	msg << guanQia->curMapId << guanQia->curNodeId << (uint16)guanQia->guanQiaScores.size();
	for (GuanQiaMapIt it = guanQia->guanQiaScores.begin(); it != guanQia->guanQiaScores.end(); ++it)
	{
		SingleGuanQiaScore& score = it->second;
		// NodeStarMap& stars = score.nodeStars;
		SingleZhangJieCfg* cfg = sCGuanQiaCfgMgr.GetZhangJieCfg(it->first);
		if (cfg == NULL)
			continue;
		msg << cfg->id << score.sumStar << (uint8)score.fixIds.size();
	}
}

void CUserGuanQia::MakeSinggleGuanQiaMsg(uint8 type, uint32 mapId, CNetMessage &msg)
{
	SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
	NodeStarMap* stars = NULL;
	if (gqScore == NULL) return;
	stars = &gqScore->nodeStars;
	// 章节配置
	SingleZhangJieCfg* cfg = sCGuanQiaCfgMgr.GetZhangJieCfg(mapId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	msg << PRO_SUCCESS << cfg->name << (uint8)cfg->nodes.size();
	for (CurMapNodeCfgMapIt nit = cfg->nodes.begin(); nit != cfg->nodes.end(); ++nit)
	{
		MapNodeCfg &ncfg = nit->second;
		uint8 curCnt = m_nodeBeAttackCnt[ncfg.nodeId];
		if (ncfg.maxTimes == 255)
		{
			curCnt = 255;
		}
		else
		{
			curCnt = ncfg.maxTimes - curCnt;
		}
		msg << ncfg.nodeId << ncfg.name;
		if (stars == NULL)
		{
			msg << (uint8)0;
		}
		else
		{
			NodeStarMapIt sit = stars->find(ncfg.nodeId);
			if (sit == stars->end())
			{
				msg << (uint8)0;
			}
			else
			{
				msg << sit->second;
			}
		}
		static uint8 maxReset = 5;
		uint8 curReset = 0;
		NodeResetCntMapIt rIt = m_nodeResetCnt.find(ncfg.nodeId);
		if (rIt != m_nodeResetCnt.end())
			curReset = rIt->second;
		uint16 cost = sCGuanQiaCfgMgr.GetResetCost(curReset);
		msg << curCnt << ncfg.spiritCost << (uint8)(maxReset - curReset) << cost << ncfg.nextNodeId << ncfg.fixId;
		if (ncfg.fixId != 0)
		{
			FixGetStateIt fsit = gqScore->fixState.find(ncfg.fixId);
			if (fsit == gqScore->fixState.end())
			{
				msg << (uint8)0;	// 未获得
			}
			else
			{
				msg << fsit->second;  // 领取状态
			}
		}
		MakeMultiAwardMsg(ncfg.moneyAward, msg);
		MakeMultiAwardMsg(ncfg.normalAward, msg);
	}
	
	msg << (uint8)cfg->starFix.size();
	for (StarFixMapIt fit = cfg->starFix.begin(); fit != cfg->starFix.end(); ++fit)
	{
		msg << fit->first << fit->second;
		FixGetStateIt fsit = gqScore->fixState.find(fit->second);
		if (fsit == gqScore->fixState.end())
		{
			msg << (uint8)0;	// 未获得
		}
		else
		{
			msg << fsit->second;  // 领取状态
		}
	}
}

int8_t CUserGuanQia::GetNodeStar(uint8 type, uint32 mapId, uint32 nodeId)
{
	SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
	if (gqScore == NULL)
		return -1;
	NodeStarMap& stars = gqScore->nodeStars;
	NodeStarMapIt sit = stars.find(nodeId);
	if (sit == stars.end())
		return -1;

	return sit->second;
}

void CUserGuanQia::MakeNodeMsg(CUser* pUser, CNetMessage &msg)
{
	uint8 type;
	uint32 mapId;
	uint32 nodeId;
	msg >> type >> mapId >> nodeId;
	uint8 star = -1;
	uint8 aCnt = 0;
	uint8 rCnt = CGuanQiaCfgMgr::g_MaxReSetCnt;
	
	do 
	{
		SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
		if (gqScore == NULL)
			break;
		NodeStarMap& stars = gqScore->nodeStars;
		NodeStarMapIt sit = stars.find(nodeId);
		if (sit == stars.end())
			break;

		star = GetNodeStar(type, mapId, nodeId);
		NodeBeAttackCntIt ait = m_nodeBeAttackCnt.find(nodeId);
		if (ait != m_nodeBeAttackCnt.end())
			aCnt = ait->second;
		NodeResetCntMapIt rit = m_nodeResetCnt.find(nodeId);
		if (rit != m_nodeResetCnt.end())
			rCnt = CGuanQiaCfgMgr::g_MaxReSetCnt - rit->second;
	} while (false);
	msg << star << aCnt << rCnt;
	return;
}

void CUserGuanQia::MakeFixMsg(uint32 fixId, CNetMessage &msg)
{
	// todo3
	// FixGetStateIt it = m_fixGetState.find(fixId);
	// if (it == m_fixGetState.end())
	// {
		// msg << PRO_SUCCESS << (uint8)0;
	// }
	// else
	// {
		// msg << it->second;
	// }
	// sCGuanQiaCfgMgr.MakeFixMsg(fixId, msg);
}

// 领取宝箱
void CUserGuanQia::GetFixAward(CUser* pUser, uint8 type, uint32 mapId, uint32 fixId, CNetMessage &msg)
{	
	SingleGuanQiaScore* userGuanqia = GetUserGuanQia(type, mapId);
	if (userGuanqia == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	FixGetStateIt fsit = userGuanqia->fixState.find(fixId);
	if (fsit == userGuanqia->fixState.end())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0153,TIPS_FAILURE_COLOR);
		return;
	}
	
	if (fsit->second == 2)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0154,TIPS_FAILURE_COLOR);
		return;
	}
	
	MultiAward* aw = sCGuanQiaCfgMgr.QueryFixAward(fixId);
	if (aw == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0153,TIPS_FAILURE_COLOR);
		return;
	}
	fsit->second = 2;
	userGuanqia->fixIds.erase(fixId);
	msg << PRO_SUCCESS;
	SendAndMakeAwardMsg(pUser, *aw, msg, false, MUT_GuanQiaFix);
}

void CUserGuanQia::EnterGuanQiaFight(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId, CNetMessage &msg)
{
	SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
	if (gqScore == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	
	if (gqScore->nodeStars.find(nodeId) == gqScore->nodeStars.end())
	if (gqScore == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, nodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151,TIPS_FAILURE_COLOR);
		return;
	}
	uint8 curCnt = GetCurAttackCnt(nodeId);
	if (cfg->maxTimes != 255 && curCnt >= cfg->maxTimes)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0163,TIPS_FAILURE_COLOR);
		return;
	}
	// 体力判断
	CUserSpirit& sp = pUser->GetUserSpirit();
	if (sp.GetCurSpirit() < cfg->spiritCost)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150,TIPS_FAILURE_COLOR);
		return;
	}
	
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return;

	bool canSkip = (cfg->type == 1);
	m_curType = type;
	m_curMapId = mapId;
	m_curNodeId = nodeId;
	pFight->SetFightType(CFight::EFT_GuanQia);
	pFight->SetFightChooseMode();
	ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	pFight->AddUserGroupToFight(ptrUser);
	pFight->AddMonsterWithFightId(cfg->fightId);
	pFight->SetCanSkip(canSkip);
//	pFight->SetPlaySpeed(1);

	SFastFightResult result;
	pFight->BeginFastFight(result, true, pUser->GetSock());
	uint8 star = 0;
	if (result.win)
	{
		star = pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
		GuanQiaWin(pUser, star);
		sCMissionManager.UpdateQuestState(pUser, EMQCT_13, 1, type);
	}
	UpdateUserRecord(pUser->GetRoleId(), ERT_GuanQia, nodeId, star);
	
//	CNetMessage fightMsg;
//	if(pFight->GetFightAllNetMsg(fightMsg, EFPT_PlayBack_1))
//		SaveFightNetMsg(fightMsg, 99, pUser->GetRoleId(), 0);
}

int CUserGuanQia::GetCurAttackCnt(uint32 nodeId)
{
	NodeBeAttackCntIt cIt = m_nodeBeAttackCnt.find(nodeId);
	if (cIt != m_nodeBeAttackCnt.end())
	{
		return cIt->second;
	}
	return 0;
}

void CUserGuanQia::GuanQiaSaoDang(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId, CNetMessage &msg)
{
	SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
	if (gqScore == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	
	NodeStarMapIt it = gqScore->nodeStars.find(nodeId);
	if (it == gqScore->nodeStars.end() || it->second == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0155, TIPS_FAILURE_COLOR);
		return;
	}
	
	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, nodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151,TIPS_FAILURE_COLOR);
		return;		
	}
	
	// 扫荡次数获取
	int lessCnt = 0;
	int curCnt = GetCurAttackCnt(nodeId);
	if (cfg->maxTimes == 255)
	{
		curCnt = 255;
	}
	else
	{
		lessCnt = cfg->maxTimes - curCnt;
	}
	if (lessCnt < 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0163,TIPS_FAILURE_COLOR);
		return;
	}
	// 体力判断
	CUserSpirit& sp = pUser->GetUserSpirit();
	uint8 spiritCnt = sp.GetCurSpirit() / cfg->spiritCost;
	uint8 realCnt = lessCnt > spiritCnt ? spiritCnt : lessCnt;
	uint8 scnt = sp.GetCurSpirit() / cfg->spiritCost;
	if (realCnt > scnt)
		realCnt = scnt;
	if (realCnt > 5)
		realCnt = 5;
	if (!sp.SubSpirit(pUser, realCnt * cfg->spiritCost))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150,TIPS_FAILURE_COLOR);
		return;
	}
	m_nodeBeAttackCnt[nodeId] = curCnt + realCnt;
	
	// 发送奖励
	msg << PRO_SUCCESS << (uint8)realCnt;
	AwardManager& amgr = sAwardManager;
	MultiAward awards;
	for (size_t ci = 0; ci < realCnt; ++ci)
	{
		std::vector<SAwardData> awvec;
		SAwardData ad;
		ad.type = HDAT_RoleExp;
		ad.num = pUser->GetLevel() * 2 * cfg->spiritCost;
		amgr.GetAwardById(cfg->rewardId, awvec);
		awvec.push_back(ad);
		msg << (uint8)ci;
		MakeMultiAwardMsg(cfg->moneyAward, msg);
		MakeMultiAwardMsg(awvec, msg);
		awvec.pop_back();
		pUser->AddMaterial(ad);
		MergeAwardList(awards, cfg->moneyAward);
		MergeAwardList(awards, awvec);
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	pUser->AddMultiAward(awards);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_13, realCnt, type);
}

uint32 CUserGuanQia::GetGuanQiaStar(uint8 type)
{
	if (type == 1)
	{
		return m_guanQiaZhuScore.allStar;
	}
	else if (type == 2)
	{
		return m_guanQiaZhiScore.allStar;
	}
	return 0;
}

SingleGuanQiaScore* CUserGuanQia::GetUserGuanQia(uint8 type, uint32 mapId)
{
	UserGuanQia* guanQia = NULL;
	if (type == 1)
	{
		guanQia = &m_guanQiaZhuScore;
	}
	else if (type == 2)
	{
		guanQia = &m_guanQiaZhiScore;
	}
	else
		return NULL;
	
	GuanQiaMapIt it = guanQia->guanQiaScores.find(mapId);
	if (it != guanQia->guanQiaScores.end())
		return &it->second;
	
	return NULL;
}

void CUserGuanQia::GuanQiaReset(CUser* pUser, uint32 nodeId, CNetMessage &msg)
{
	if (nodeId == 0) return;
	uint8 resetCnt = 0;
	NodeResetCntMapIt it = m_nodeResetCnt.find(nodeId);
	if (it != m_nodeResetCnt.end())
	{
		resetCnt = it->second;
	}	
	uint16 cost = sCGuanQiaCfgMgr.GetResetCost(resetCnt);
	if (cost == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0156,TIPS_FAILURE_COLOR);
		return;
	}
	resetCnt++;
	if (!pUser->SubMaterial(HDAT_YB, cost))
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0157,TIPS_FAILURE_COLOR);
		return;
	}
	ItemCurrencyLog(pUser->GetRoleId(), nodeId, 1, HDAT_YB, cost, pUser->GetMaterial(HDAT_YB), MUT_ChongZhi);
	m_nodeResetCnt[nodeId] = resetCnt;
	m_nodeBeAttackCnt.erase(nodeId);
	msg << PRO_SUCCESS << resetCnt << cost;
}

void CUserGuanQia::AddNewSinggleGuanQia(uint8 type, uint32 mapId, uint32 nodeId)
{
	if (mapId == 0)
		return;
	UserGuanQia* guanQia = NULL;
	if (type == 1)
	{
		guanQia = &m_guanQiaZhuScore;
	}
	else if (type == 2)
	{
		guanQia = &m_guanQiaZhiScore;
	}
	else
	{
		return;
	}
	SingleGuanQiaScore* gc = GetUserGuanQia(type, mapId);
	if (gc != NULL)
	{
		gc->nodeStars[nodeId] = 0;
	}
	else
	{
		SingleGuanQiaScore sgqc;
		sgqc.sumStar = 0;
		sgqc.nodeStars.clear();
		sgqc.fixIds.clear();
		sgqc.nodeStars[nodeId] = 0;
		guanQia->guanQiaScores.insert(make_pair(mapId, sgqc));
	}
	guanQia->curMapId = mapId;
	guanQia->curNodeId = nodeId;
}

void CUserGuanQia::GuanQiaWin(CUser* pUser, uint8 star)
{
	// 关卡次数
	NodeBeAttackCntIt it = m_nodeBeAttackCnt.find(m_curNodeId);
	uint8 curCnt = 1;
	if (it != m_nodeBeAttackCnt.end())
	{
		curCnt = ++it->second;
	}
	else
	{
		m_nodeBeAttackCnt[m_curNodeId] = 1;
	}
	SingleZhangJieCfg* zcfg = sCGuanQiaCfgMgr.GetZhangJieCfg(m_curMapId);
	if (zcfg == NULL)
		return;
	
	MapNodeCfg * cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(m_curMapId, m_curNodeId);
	if (cfg == NULL)
		return;
	
	SingleGuanQiaScore* userGuanqia = GetUserGuanQia(m_curType, m_curMapId);
	if (userGuanqia == NULL)
		return;
	
	uint32 nextNodeId = 0;
	uint32 nextMapId = 0;
	uint32 fixId = 0;
	uint32 starFixId = 0;
	uint8 addStar = 0;
	bool firstAward = false;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_GUANQIA);
	msg << (uint8)8;
	NodeStarMapIt nit = userGuanqia->nodeStars.find(m_curNodeId);
	if (nit == userGuanqia->nodeStars.end())
	{
		return;
	}
	if (nit->second == 0)
	{		
		// 首通
		firstAward = true;
		nit->second = star;
		addStar = star;
		// 记录下一关
		nextNodeId = cfg->nextNodeId;
		nextMapId = sCGuanQiaCfgMgr.GetNodeMapId(cfg->nextNodeId);
		fixId = cfg-> fixId;
		if (fixId > 0)
		{
			userGuanqia->fixIds.insert(fixId);
			userGuanqia->fixState[fixId] = 1;
		}
	}
	else
	{
		if (nit->second < star)
		{
			addStar = star - nit->second;
			nit->second = star;
		}
	}
	if (addStar > 0)
	{
		for (uint8 s = 1; s <= addStar; ++s)
		{
			StarFixMapIt fit = zcfg->starFix.find(userGuanqia->sumStar + s);
			if (fit != zcfg->starFix.end())
			{
				starFixId = fit->second;
				userGuanqia->fixIds.insert(starFixId);
				userGuanqia->fixState[starFixId] = 1;
			}
		}
		userGuanqia->sumStar += addStar;
		if (m_curType == 1)
		{
			m_guanQiaZhuScore.allStar += addStar;
			SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_GuanKa_Zhu, pUser->GetRoleId(), m_guanQiaZhuScore.allStar);
			SendCJHotPointStatus(pUser);
		}
		else if (m_curType == 2)
		{
			m_guanQiaZhiScore.allStar += addStar;
			SingletonCRankMgr::instance().UpdateData(CRankMgr::ERT_GuanKa_Zhi, pUser->GetRoleId(), m_guanQiaZhiScore.allStar);
		}
	}
	msg << curCnt << m_curNodeId << nextMapId << nextNodeId << fixId << starFixId;
	MultiAward awards;
	MergeAwardList(awards, cfg->moneyAward);
	if (firstAward)
	{
		AddNewSinggleGuanQia(m_curType, nextMapId, nextNodeId);
		MergeAwardList(awards, cfg->firstAward);
	}
	else
	{
		MultiAward nma;
		sAwardManager.GetAwardById(cfg->rewardId, nma);
		MergeAwardList(awards, nma);
	}
	sCMissionManager.UpdateQuestState(pUser, EMQCT_40, 1, m_curNodeId);
	SAwardData ad;
	ad.type = HDAT_RoleExp;
	ad.num = pUser->GetLevel() * 2 * cfg->spiritCost;
	awards.push_back(ad);
	msg << star;
	MakeMultiAwardMsg(awards, msg);
	m_curNodeId = 0;
	m_curMapId = 0;
	m_curType = 0;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	CUserSpirit& sp = pUser->GetUserSpirit();
	sp.SubSpirit(pUser, cfg->spiritCost);
	pUser->AddMultiAward(awards, true, false, MUT_GuanQiaNode);

}

void CUserGuanQia::GetShiLianMsg(CUser* pUser, CNetMessage &msg)
{
	msg << (uint8)m_slGuanQia.size();
	for (ShiLianGuanQiaMapIt it = m_slGuanQia.begin(); it != m_slGuanQia.end(); ++it)
	{
		msg << it->first;
		ShiLianGuanQia& sl = it->second;
		msg << sl.cnt << (uint8)sl.isOpen << sl.sdNodeId << sl.tzNodeId;
	}
}

void CUserGuanQia::TiaoZhanShiLian(CUser* pUser, CNetMessage &msg)
{
	uint32 id;
	msg >> id;
	ShiLianGuanQiaMapIt it = m_slGuanQia.find(id);
	if (it == m_slGuanQia.end())
	{
		return;
	}

	ShiLianGuanQia& sl = it->second;
	if (!sl.isOpen)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0192, TIPS_FAILURE_COLOR);
		return;
	}

	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(id, sl.tzNodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR);
		return;
	}
	if (cfg->levelLimit > pUser->GetLevel())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0193, TIPS_FAILURE_COLOR);
		return;
	}

	/*if (sl.cnt == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0189, TIPS_FAILURE_COLOR);
		return;
	}*/

	msg << PRO_SUCCESS;
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return;
	pFight->SetFightType(CFight::EFTShiLianFight);
	pFight->SetFightChooseMode();
	ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	pFight->AddUserGroupToFight(ptrUser);
	pFight->AddMonsterWithFightId(cfg->fightId);
	SFastFightResult result;
	pFight->BeginFastFight(result, true, ptrUser->GetSock());
	if (result.win)
	{
		CNetMessage trap;
		trap.ReWrite();
		trap.SetType(MSG_GUANQIA);
		trap << (uint8)9;
		sl.sdNodeId = sl.tzNodeId;
		sl.tzNodeId = cfg->nextNodeId;
		sl.cnt = cfg->maxTimes;
		trap << id << cfg->nextNodeId << sl.cnt;
		m_curMapId = 0;
		MultiAward awards = cfg->moneyAward;
		MergeAwardList(awards, cfg->firstAward);
		MakeFightEndMsg(pUser, 3, trap, &awards, MUT_ShiLian);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), trap);
		sl.cnt = cfg->maxTimes;
	}

	SingletonFightManager::instance().AddFight(pFight);
	m_curMapId = id;
	sCMissionManager.UpdateQuestState(pUser, EMQCT_55);
}

// 扫荡试炼
void CUserGuanQia::SaoDangShiLian(CUser* pUser, CNetMessage &msg)
{
	uint32 id;
	msg >> id;
	ShiLianGuanQiaMapIt it = m_slGuanQia.find(id);
	if (it == m_slGuanQia.end())
	{
		return;
	}

	ShiLianGuanQia& sl = it->second;
	if (!sl.isOpen)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0192, TIPS_FAILURE_COLOR);
		return;
	}

	if (sl.cnt == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0189, TIPS_FAILURE_COLOR);
		return;
	}

	if (sl.sdNodeId == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0226, TIPS_FAILURE_COLOR);
		return;
	}

	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(id, sl.sdNodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR);
		return;
	}
	msg << PRO_SUCCESS << --sl.cnt;
	SendAndMakeAwardMsg(pUser, cfg->moneyAward, msg, false, MUT_ShiLian);
	sAwardManager.SendAndMakeAwardMsg(pUser, cfg->rewardId, msg, false, MUT_ShiLian);
	SendShiLianHotPointStatus(pUser);
	sCMissionManager.UpdateQuestState(pUser, EMQCT_55);
}

// 获取列传信息
void CUserGuanQia::GetLieZhuanMsg(CUser* pUser, CNetMessage &msg)
{
	msg << m_lzGuanQia.curMapIdx << m_lzGuanQia.curNodeId << m_lzGuanQia.cnt;
	/*for (U32tU32MapIt it = m_lzGuanQia.awardState.begin(); it != m_lzGuanQia.awardState.end(); ++it)
	{
		msg << it->first << it->second;
	}*/
}

// 挑战列传
void CUserGuanQia::TiaoZhanLieZhuan(CUser* pUser, CNetMessage &msg)
{
	// 获取章节地图Id
	CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
	MapNodeCfg* cfg = mgr.GetMapNodeCfg(m_lzGuanQia.curNodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR);
		return;
	}
	if (m_lzGuanQia.cnt == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0189, TIPS_FAILURE_COLOR);
		return;
	}
	
	if (cfg->levelLimit > pUser->GetLevel())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0193, TIPS_FAILURE_COLOR);
		return;
	}
	CUserSpirit& sp = pUser->GetUserSpirit();
	if (sp.GetCurSpirit() < cfg->spiritCost)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150, TIPS_FAILURE_COLOR);
		return;
	}

	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return;

	pFight->SetFightType(CFight::EFTLieZhuanFight);
	pFight->SetFightChooseMode();
	ShareUserPtr ptrUser = SingletonOnlineUser::instance().GetUserByRoleId(pUser->GetRoleId());
	pFight->AddUserGroupToFight(ptrUser);
	pFight->AddMonsterWithFightId(cfg->fightId);
	
	SFastFightResult result;
	pFight->BeginFastFight(result, true, pUser->GetSock());
	// op=25 is a request/ack pair.  The battle result and chapter reward are
	// separate op=10/op=26 pushes, but the original request still needs its
	// success byte or DealGuanQia will send an op-only packet to the client.
	msg << PRO_SUCCESS;
	int star = 0;
	if (result.win)
	{
		star = pFight->CalculateFightStar(CFight::EGT_GROUP1, result.win);
		CNetMessage msg;
		msg.ReWrite();
		msg.SetType(MSG_GUANQIA);
		msg << (uint8)10 << m_lzGuanQia.curMapIdx << m_lzGuanQia.curNodeId;
		MapNodeCfg* cfg = mgr.GetMapNodeCfg(m_lzGuanQia.curNodeId);
		if (cfg == NULL)
			return;
		m_lzGuanQia.cnt--;
		msg << m_lzGuanQia.cnt;
		m_lzGuanQia.curNodeId = cfg->nextNodeId;
		MapNodeCfg* ncfg = mgr.GetMapNodeCfg(m_lzGuanQia.curNodeId);
		if (cfg != NULL && cfg->mapId != ncfg->mapId)
		{
			m_lzGuanQia.curMapIdx++;
		}
		msg << m_lzGuanQia.curMapIdx << m_lzGuanQia.curNodeId;
		MultiAward awards = cfg->moneyAward;
		MergeAwardList(awards, cfg->firstAward);

		SAwardData ad;
		ad.type = HDAT_RoleExp;
		ad.num = pUser->GetLevel() * 2 * cfg->spiritCost;
		awards.push_back(ad);

		MakeFightEndMsg(pUser, 3, msg, &awards, MUT_GuanQiaLieZhuan);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);

		MultiAward* award = sCGuanQiaCfgMgr.QueryFixAward(cfg->fixId);
		if (award != NULL)
		{
			msg.ReWrite();
			msg.SetType(MSG_GUANQIA);
			msg << (uint8)26;
			SendAndMakeAwardMsg(pUser, *award, msg, false, MUT_GuanQiaLieZhuan);
			SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
		}
		sp.SubSpirit(pUser, cfg->spiritCost);
		sCMissionManager.UpdateQuestState(pUser, EMQCT_12, 1);
	}
}

void CUserGuanQia::GetChengJiuMsg(CUser * pUser, CNetMessage & msg)
{
	if (m_achId == 0)
		m_achId = 1;
	msg << PRO_SUCCESS << m_achId << m_achState;
	if (m_achState >= 0x7e)
	{
		m_achId++;
		m_achState = 0;
	}
}

void CUserGuanQia::GetChengJiuAward(CUser * pUser, CNetMessage & msg)
{
	uint8 idx;
	msg >> idx;
	ChengJiuCfg* cfg = sCGuanQiaCfgMgr.GetChengJiuCfg(m_achId, idx - 1);
	if (cfg == NULL)
		return;
	if (cfg->star > m_guanQiaZhuScore.allStar)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0207, TIPS_FAILURE_COLOR);
		return;
	}
	if ((m_achState & (1 << idx)) != 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0208, TIPS_FAILURE_COLOR);
		return;
	}
	m_achState |= (1 << idx);
	if (m_achState >= 0x7e)
	{
		m_achId++;
		m_achState = 0;
	}
	msg << PRO_SUCCESS << m_achId << m_achState << (uint16)cfg->award.type << cfg->award.num;
	pUser->AddMaterial(cfg->award, true, true);
	ItemCurrencyLog(pUser->GetRoleId(), m_achId, idx, cfg->award.type, cfg->award.num, pUser->GetMaterial(cfg->award.type), MUT_GuanQiaChengJiu);
}

uint8 CUserGuanQia::SendCJHotPointStatus(CUser* pUser)
{
	uint8 state = 0;
	CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
	for (uint8 i = 1; i < 8; ++i)
	{
		ChengJiuCfg* cfg = mgr.GetChengJiuCfg(m_achId, i - 1);
		if (cfg == NULL)
			break;

		if (cfg->star > m_guanQiaZhuScore.allStar)
			break;

		if ((m_achState & (1 << i)) == 0)
		{
			state = 1;
			break;
		}

	}
	SendHotPointStatus(pUser, EHPoint_ChengJiu, state);
	return state;
}

uint8 CUserGuanQia::SendFixHotPointStatus(CUser* pUser)
{
	uint8 state = 0;
	do
	{
		GuanQiaMap& zhu = m_guanQiaZhuScore.guanQiaScores;
		for (GuanQiaMapIt it = zhu.begin(); it != zhu.end(); ++it)
		{
			if (!it->second.fixIds.empty())
			{
				state = 1;
				break;
			}
		}

		GuanQiaMap& zhi = m_guanQiaZhuScore.guanQiaScores;
		for (GuanQiaMapIt it = zhi.begin(); it != zhi.end(); ++it)
		{
			if (!it->second.fixIds.empty())
			{
				state = 1;
				break;
			}
		}
	} while (false);
	SendHotPointStatus(pUser, EHPoint_XiangZi, state);
	return state;
}

uint8 CUserGuanQia::SendShiLianHotPointStatus(CUser* pUser)
{
	uint8 state = 0;
	for (ShiLianGuanQiaMapIt it = m_slGuanQia.begin(); it != m_slGuanQia.end(); ++it)
	{
		if (it->second.cnt > 0 && it->second.sdNodeId != 0)
		{
			state = 1;
			break;
		}
	}
	SendHotPointStatus(pUser, EHPoint_ShiLian, state);
	return state;
}

void CUserGuanQia::SendFuBenHotPointStatus(CUser* pUser)
{
	uint8 state = 0;
	do
	{
		state = SendCJHotPointStatus(pUser);
		if (state == 1)
			break;
		state = SendFixHotPointStatus(pUser);
		if (state == 1)
			break;
		state = SendShiLianHotPointStatus(pUser);
		if (state == 1)
			break;
	} while (false);
	SendHotPointStatus(pUser, EHPoint_FuBen, state);
}


int CUserGuanQia::GetShiLianCnt(uint8 type, bool part)
{
	uint32 mid = 3000 + type;
	CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
	SingleZhangJieCfg* mcfg = mgr.GetZhangJieCfg(mid);
	if (mcfg == NULL)
		return 0;
	uint8 week = GetWeekDay();
	if (week == 0) week = 7;
	week -= 1;
	if (week == 0)
		week = 7;
	ShiLianGuanQiaMapIt it = m_slGuanQia.find(mid);
	if (it == m_slGuanQia.end())
		return 0;
	ShiLianGuanQia& sl = it->second;
	MapNodeCfg* ncfg = mgr.GetMapNodeCfg(it->first, sl.tzNodeId);
	if (ncfg == NULL)
		return 0;
	if (mcfg->openWeek.find(week) == mcfg->openWeek.end())
		return 0;
	if (!part)
		return ncfg->maxTimes;
	else
		return sl.cnt;
}

int CUserGuanQia::GetLieZhuanCnt(bool part)
{
	if (part)
		return m_lzGuanQia.cnt;
	return CGuanQiaCfgMgr::g_LieZhuanCnt;
}

#ifdef _DEBUG
void CUserGuanQia::GuanQiaGM(CUser* pUser, uint8 type, uint16 num)
{
	UserGuanQia* guanQia = NULL;
	if (type == 1)
	{
		guanQia = &m_guanQiaZhuScore;
	}
	else if (type == 2)
	{
		guanQia = &m_guanQiaZhiScore;
	}
	else
	{
		return;
	}
	uint8 cnt = 0;
	CGuanQiaCfgMgr& mgr = sCGuanQiaCfgMgr;
	while (true)
	{
		uint32 nextMap = 0;
		SingleGuanQiaScore* gc = GetUserGuanQia(type, guanQia->curMapId);
		if (gc != NULL)
		{
			SingleZhangJieCfg* cfg = mgr.GetZhangJieCfg(guanQia->curMapId);
			if (cfg == NULL) break;
			if (cfg != NULL)
			{
				for (StarFixMapIt fit = cfg->starFix.begin(); fit != cfg->starFix.end(); fit++)
				{
					gc->fixIds.insert(fit->second);
					gc->fixState[fit->second] = 1;
				}
				for (CurMapNodeCfgMapIt it = cfg->nodes.begin(); it != cfg->nodes.end(); it++)
				{
					gc->sumStar += 3;
					guanQia->allStar += 3;
					gc->nodeStars[it->first] = 3;
					if (it->second.fixId != 0)
					{
						gc->fixIds.insert(it->second.fixId);
						gc->fixState[it->second.fixId] = 1;
					}
					nextMap = mgr.GetNodeMapId(it->second.nextNodeId);
					if (nextMap != guanQia->curMapId)
					{
						AddNewSinggleGuanQia(type, nextMap, it->second.nextNodeId);
					}
				}
				cnt++;
			}
		}
		if (cnt >= num)
			break;
	}
}
#endif // _DEBUG
