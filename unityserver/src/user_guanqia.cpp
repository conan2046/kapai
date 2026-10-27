#include "user_guanqia.h"
#include "chapter_reward_rules.h"
#include "library_unity.h"
#include "user.h"
#include "scene_manager.h"
#include "init.h"
#include "user_spirit.h"
#include "award_manager.h"
#include "rank.h"
#include "config_para.h"
#include <cstdlib>
#include <algorithm>

extern const char *gConfigFile;

namespace
{
	bool ApplyLocalTestFightSeed(uint32 nodeId)
	{
		if(gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) != "1")
			return false;
		const string seedText = gyu::util::CIniFile::GetValue(
			"local_test_fight_seed", "server", gConfigFile);
		if(seedText.empty())
			return false;
		char *end = NULL;
		const unsigned long parsed = strtoul(seedText.c_str(), &end, 10);
		if(end == seedText.c_str() || *end != '\0')
		{
			cout << "[local][fight-seed] invalid value=" << seedText << endl;
			return false;
		}
		const uint32 seed = static_cast<uint32>(parsed);
		srand(seed);
		cout << "[local][fight-seed] context=GuanQia node=" << nodeId
			<< " seed=" << seed << endl;
		return true;
	}

	void LogLocalTestMessageFingerprint(const char *label, CNetMessage &msg)
	{
		if(gyu::util::CIniFile::GetValue("local_test", "server", gConfigFile) != "1")
			return;
		const std::string *data = msg.GetMsgData();
		if(data == NULL)
			return;
		cout << "[local][fight-packet] label=" << label
			<< " len=" << data->size()
			<< " fnv1a32=" << gyu::util::Fnv1a32(*data) << endl;
	}
}

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
	const char* titleArrs[] = { "Id", "MapType", "Name", "Desc", "OpenLv", "BundleId", "OpenTime", "boss_reward" };
	const int typeArrs[] = { 0, 0, 1, 1, 0, 0, 2, 0 };  // 0-int 1-string 2-array
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
			
			cfg.bossRewardId = data[titleArrs[7]].GetUint();
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
    const char* titles[] = {"ID","mapid","Name","Des","type","fightID","Levellimit","UnlockID","Hope","rewardID","show_reward","DialogueId"};
    const int types[] = {0,0,1,1,0,0,0,0,0,0,2,0};
    rapidjson::Document document; rapidjson::Value rows;
    if (!LoadJosnValue("maplist.json", titles, types, 12, document, rows)) return false;
    for (rapidjson::SizeType i = 0; i < rows.Size(); ++i) {
        const auto& data = rows[i];
        SingleZhangJieCfg* chapter = GetZhangJieCfg(data["mapid"].GetInt());
        if (!chapter) { cout << "maplist.json missing chapter: " << data["mapid"].GetInt() << endl; return false; }
        MapNodeCfg node{};
        node.type = data["type"].GetInt();
        node.maxTimes = 255; // Removed AttackCount means unlimited attempts, using the existing protocol sentinel.
        node.spiritCost = data["Hope"].GetInt();
        node.nodeId = data["ID"].GetInt(); node.mapId = data["mapid"].GetInt();
        node.fightId = data["fightID"].GetInt(); node.levelLimit = data["Levellimit"].GetInt();
        node.nextNodeId = data["UnlockID"].GetInt(); node.rewardId = data["rewardID"].GetInt();
        node.name = data["Name"].GetString();
        if (!ReadMultiAward(data["show_reward"], node.showAward)) return false;
        m_allNodeIds[node.nodeId] = node.mapId;
        chapter->nodes[node.nodeId] = node;
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
	for (const auto& entry : m_allMapCfg) {
		const auto& cfg = entry.second;
		if (cfg.type != 1) continue;
		if (cfg.bossRewardId == 0 || !QueryFixAward(cfg.bossRewardId)
			|| cfg.nodes.empty() || cfg.nodes.rbegin()->second.type != 3) {
			cout << "Invalid final boss package for chapter " << cfg.id << endl;
			return false;
		}
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
		msg << cfg->id << score.sumStar << (uint8)ChapterRewardRules::PendingCount(cfg->starFix, score.fixIds, score.sumStar);
	}
	// 龙崖改造：模式下发（方案甲）—— op=1 载荷末尾带回 fuben_AB，客户端据此切 UI
	msg << (uint8)GetFubenMode();
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
		msg << curCnt << ncfg.spiritCost << (uint8)(maxReset - curReset) << cost << ncfg.nextNodeId << (uint32)0;
        msg << (uint8)0; // No separate money/first-win list in the unified reward schema.
        MultiAward preview = ncfg.showAward;
        uint32 packageId = ChapterRewardRules::BossPackage(GetFubenMode(), ncfg.type, cfg->bossRewardId);
        if (packageId != 0) {
            MultiAward* package = sCGuanQiaCfgMgr.QueryFixAward(packageId);
            if (package != NULL) MergeAwardList(preview, *package);
        }
        MakeMultiAwardMsg(preview, msg);
	}
	
	msg << (uint8)0; // No star boxes; the final boss has one repeatable package.
	msg << (uint32)(GetFubenMode() == FUBEN_MODE_LONGYA ? cfg->bossRewardId : 0);
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
    SingleZhangJieCfg* chapter = sCGuanQiaCfgMgr.GetZhangJieCfg(mapId);
    if (!chapter || !ChapterRewardRules::Eligible(chapter->starFix, fixId, userGuanqia->sumStar)) {
        msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0153, TIPS_FAILURE_COLOR); return;
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
	// op=5 是普通副本入口。龙崖模式必须由 op=28 显式进入，不能由全局开关
	// 改写普通挑战的次数、体力和记录语义。
	RunSingleNodeFight(pUser, type, mapId, nodeId, FUBEN_MODE_DEFAULT, 0, 0, msg);
}

// 龙崖副本模式开关：config.fuben_AB（1=默认副本模式 2=龙崖副本模式）
uint8 CUserGuanQia::GetFubenMode()
{
	int mode = SingletonCParaMgr::instance().GetInt("fuben_AB");
	if (mode == FUBEN_MODE_LONGYA)
		return FUBEN_MODE_LONGYA;
	return FUBEN_MODE_DEFAULT;
}

// 本章第一关：nodes 是 map<uint32, MapNodeCfg>（按 nodeId 升序），首项即第一关
uint32 CUserGuanQia::GetChapterFirstNodeId(uint32 mapId)
{
	SingleZhangJieCfg* zcfg = sCGuanQiaCfgMgr.GetZhangJieCfg(mapId);
	if (zcfg == NULL || zcfg->nodes.empty())
		return 0;
	return zcfg->nodes.begin()->first;
}

int CUserGuanQia::RunSingleNodeFight(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId,
	uint8 mode, uint8 chainIndex, uint8 chainTotal, CNetMessage &msg)
{
	SingleGuanQiaScore* gqScore = GetUserGuanQia(type, mapId);
	if (gqScore == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return ENFR_Error;
	}

	if (gqScore->nodeStars.find(nodeId) == gqScore->nodeStars.end())
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return ENFR_Error;
	}
	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, nodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151,TIPS_FAILURE_COLOR);
		return ENFR_Error;
	}
	// 模式 2（龙崖）：豁免次数与体力门槛；模式 1 保持原样
	if (mode != FUBEN_MODE_LONGYA)
	{
		uint8 curCnt = GetCurAttackCnt(nodeId);
		if (cfg->maxTimes != 255 && curCnt >= cfg->maxTimes)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0163,TIPS_FAILURE_COLOR);
			return ENFR_Error;
		}
		// 体力判断
		CUserSpirit& sp = pUser->GetUserSpirit();
		if (sp.GetCurSpirit() < cfg->spiritCost)
		{
			msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150,TIPS_FAILURE_COLOR);
			return ENFR_Error;
		}
	}

	ApplyLocalTestFightSeed(nodeId);
	ShareFightPtr pFight = SingletonFightManager::instance().CreateFight();
	if (pFight.get() == NULL)
		return ENFR_Error;

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
		// BOSS（type==3）视为本章通关 → 不下发下一关（chainNextNodeId = 0）
		uint32 chainNextNodeId = (cfg->type == 3) ? 0 : cfg->nextNodeId;
        if (!GuanQiaWin(pUser, star, mode, chainIndex, chainTotal, chainNextNodeId)) {
            msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR);
            return ENFR_Error;
        }
		sCMissionManager.UpdateQuestState(pUser, EMQCT_13, 1, type);
		UpdateUserRecord(pUser->GetRoleId(), ERT_GuanQia, nodeId, star);
		return ENFR_Win;
	}
	// 模式 2 失败不写入记录；模式 1 保持现状（无条件写入）
	if (mode != FUBEN_MODE_LONGYA)
		UpdateUserRecord(pUser->GetRoleId(), ERT_GuanQia, nodeId, star);
	return ENFR_Lose;
}

void CUserGuanQia::GuanQiaAutoChain(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId, uint8 chainTotal, CNetMessage &msg)
{
	if (GetFubenMode() != FUBEN_MODE_LONGYA)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}

	uint32 firstNodeId = GetChapterFirstNodeId(mapId);
	if (firstNodeId == 0)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}
	uint32 curNodeId = (nodeId == 0) ? firstNodeId : nodeId;
	// 本场序号：从本章第一关沿 nextNodeId 走到当前关（上限 255 防死循环）
	uint8 chainIndex = 1;
	uint32 walk = firstNodeId;
	while (walk != 0 && walk != curNodeId && chainIndex < 255)
	{
		MapNodeCfg* wc = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, walk);
		if (wc == NULL || wc->nextNodeId == 0)
			break;
		walk = wc->nextNodeId;
		++chainIndex;
	}
	if (walk != curNodeId)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0152,TIPS_FAILURE_COLOR);
		return;
	}

	MapNodeCfg* cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(mapId, curNodeId);
	if (cfg == NULL)
	{
		msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151,TIPS_FAILURE_COLOR);
		return;
	}

	int ret = RunSingleNodeFight(pUser, type, mapId, curNodeId, FUBEN_MODE_LONGYA, chainIndex, chainTotal, msg);
	if (ret == ENFR_Error)
		return;			// 硬前置失败，msg 已写入错误帧
	if (ret == ENFR_Win)
		return;			// 胜利：GuanQiaWin 已下发 op=8（含下一关）

	// 失败：不弹结算，下发轻量回包 → 客户端等 2 秒后从本章第一关重跑
	MakeChainLoseMsg(pUser, mapId, curNodeId, firstNodeId, chainIndex, chainTotal);
}

void CUserGuanQia::MakeChainLoseMsg(CUser* pUser, uint32 mapId, uint32 nodeId, uint32 nextNodeId,
	uint8 chainIndex, uint8 chainTotal)
{
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_GUANQIA);
	msg << (uint8)28 << mapId << nodeId << nextNodeId << chainIndex << chainTotal;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
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
		lessCnt = 5;
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
	// 龙崖改造：模式 2 下体力消耗按 0 处理 → 这里必须防除零（原 R13 的坑）。
	// 模式 1 的 `spiritCost` 恒 > 0，行为与改前完全一致。
    const int affordable = cfg->spiritCost > 0 ? sp.GetCurSpirit() / cfg->spiritCost : lessCnt;
    const uint8 realCnt = static_cast<uint8>(std::min(5, std::min(lessCnt, affordable)));
    if (realCnt == 0) {
        msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150, TIPS_FAILURE_COLOR); return;
    }
    std::vector<MultiAward> results;
    MultiAward awards;
    for (uint8 ci = 0; ci < realCnt; ++ci) {
        MultiAward one;
        if (!sAwardManager.GetAwardById(cfg->rewardId, one)) {
            msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR); return;
        }
        CUnityLibraryService::AddSourceAward(pUser, "world_sweep", one);
        if (!UnityRewards::MergeChecked(awards, one)) {
            msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR); return;
        }
        results.push_back(one);
    }
    if (!sp.SubSpirit(pUser, realCnt * cfg->spiritCost)) {
        msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0150, TIPS_FAILURE_COLOR); return;
    }
    m_nodeBeAttackCnt[nodeId] = curCnt + realCnt;
    msg << PRO_SUCCESS << realCnt;
    for (uint8 ci = 0; ci < realCnt; ++ci) {
        msg << ci << (uint8)0; // Preserve the empty legacy separate-money array.
        MakeMultiAwardMsg(results[ci], msg);
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

bool CUserGuanQia::GuanQiaWin(CUser* pUser, uint8 star, uint8 mode, uint8 chainIndex, uint8 chainTotal, uint32 chainNextNodeId)
{
	SingleZhangJieCfg* zcfg = sCGuanQiaCfgMgr.GetZhangJieCfg(m_curMapId);
	if (zcfg == NULL)
		return false;
	
	MapNodeCfg * cfg = sCGuanQiaCfgMgr.GetMapNodeCfg(m_curMapId, m_curNodeId);
	if (cfg == NULL)
		return false;
	
	SingleGuanQiaScore* userGuanqia = GetUserGuanQia(m_curType, m_curMapId);
	if (userGuanqia == NULL)
		return false;
	
	uint32 nextNodeId = 0;
	uint32 nextMapId = 0;
	uint32 fixId = 0;
	uint32 starFixId = 0;
	uint8 addStar = 0;
	bool firstClear = false;
	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_GUANQIA);
	msg << (uint8)8;
	NodeStarMapIt nit = userGuanqia->nodeStars.find(m_curNodeId);
	if (nit == userGuanqia->nodeStars.end())
	{
		return false;
	}
	MultiAward awards;
    if (!sAwardManager.GetAwardById(cfg->rewardId, awards)) {
        cout << "Missing/invalid map reward " << cfg->rewardId << endl; return false;
    }
    MultiAward chapterBoxAwards;
    uint32 bossPackage = ChapterRewardRules::BossPackage(mode, cfg->type, zcfg->bossRewardId);
    if (bossPackage != 0) {
        MultiAward* package = sCGuanQiaCfgMgr.QueryFixAward(bossPackage);
        if (package == NULL || package->empty()) return false;
        chapterBoxAwards = *package;
    }
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
	if (nit->second == 0)
	{		
		// 首通
		firstClear = true;
		nit->second = star;
		addStar = star;
		// 记录下一关
		nextNodeId = cfg->nextNodeId;
		nextMapId = sCGuanQiaCfgMgr.GetNodeMapId(cfg->nextNodeId);

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
    CUnityLibraryService::AddSourceAward(pUser, "world", awards);
    if (firstClear) AddNewSinggleGuanQia(m_curType, nextMapId, nextNodeId);

	sCMissionManager.UpdateQuestState(pUser, EMQCT_40, 1, m_curNodeId);
	// Open the final box for every authoritative boss win. Historical star-box
	// claim states do not grant packages or suppress repeat wins.
	// 主角经验：按产品口径从副本产出中移除（改由后续「修炼系统」供给）
	// 连战序号：chainIndex / chainTotal（0 表示非连战），chainNextNodeId = 下一关（0 = 本章已通关）
	msg << star << chainIndex << chainTotal << chainNextNodeId;
	MultiAward displayedAwards = awards;
	MergeAwardList(displayedAwards, chapterBoxAwards);
	MakeMultiAwardMsg(displayedAwards, msg);
	LogLocalTestMessageFingerprint("guanqia-result", msg);
	m_curNodeId = 0;
	m_curMapId = 0;
	m_curType = 0;
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
	CUserSpirit& sp = pUser->GetUserSpirit();
	// 龙崖改造：**模式 2 仍然扣除体力**（不清调用），只是扣除数量在模式 2 下取 0
	// —— 等价于把配置表 `maplist.Hope` 在模式 2 下按 0 处理；模式 1 保持原值。
	uint32 realSpiritCost = (mode == FUBEN_MODE_LONGYA) ? 0 : cfg->spiritCost;
	sp.SubSpirit(pUser, (uint16)realSpiritCost);
	pUser->AddMultiAward(awards, true, false, MUT_GuanQiaNode);
	if (!chapterBoxAwards.empty())
		pUser->AddMultiAward(chapterBoxAwards, true, false, MUT_GuanQiaFix);

    return true;
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
		MultiAward awards;
        if (!sAwardManager.GetAwardById(cfg->rewardId, awards)) return;
		CNetMessage trap;
		trap.ReWrite();
		trap.SetType(MSG_GUANQIA);
		trap << (uint8)9;
		sl.sdNodeId = sl.tzNodeId;
		sl.tzNodeId = cfg->nextNodeId;
		sl.cnt = cfg->maxTimes;
		trap << id << cfg->nextNodeId << sl.cnt;
		m_curMapId = 0;

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
    MultiAward awards;
    if (!sAwardManager.GetAwardById(cfg->rewardId, awards)) {
        msg << PRO_ERROR << MakeStringColor(LANGUAGE_ZQX_0151, TIPS_FAILURE_COLOR); return;
    }
    if (cfg->maxTimes != 255) --sl.cnt;
    msg << PRO_SUCCESS << sl.cnt << (uint8)0;
    SendAndMakeAwardMsg(pUser, awards, msg, false, MUT_ShiLian);
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
		MultiAward awards;
        if (!sAwardManager.GetAwardById(cfg->rewardId, awards)) return;
		m_lzGuanQia.cnt--;
		msg << m_lzGuanQia.cnt;
		m_lzGuanQia.curNodeId = cfg->nextNodeId;
		MapNodeCfg* ncfg = mgr.GetMapNodeCfg(m_lzGuanQia.curNodeId);
		if (ncfg != NULL && cfg->mapId != ncfg->mapId)
		{
			m_lzGuanQia.curMapIdx++;
		}
		msg << m_lzGuanQia.curMapIdx << m_lzGuanQia.curNodeId;


		// 主角经验：按产品口径从副本产出中移除（改由后续「修炼系统」供给）
        CUnityLibraryService::AddSourceAward(pUser,"liezhuan",awards);
		MakeFightEndMsg(pUser, 3, msg, &awards, MUT_GuanQiaLieZhuan);
		SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);


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
            SingleZhangJieCfg* chapter = sCGuanQiaCfgMgr.GetZhangJieCfg(it->first);
            if (chapter && ChapterRewardRules::PendingCount(chapter->starFix, it->second.fixIds, it->second.sumStar) > 0)
			{
				state = 1;
				break;
			}
		}

		GuanQiaMap& zhi = m_guanQiaZhiScore.guanQiaScores;
		for (GuanQiaMapIt it = zhi.begin(); it != zhi.end(); ++it)
		{
            SingleZhangJieCfg* chapter = sCGuanQiaCfgMgr.GetZhangJieCfg(it->first);
            if (chapter && ChapterRewardRules::PendingCount(chapter->starFix, it->second.fixIds, it->second.sumStar) > 0)
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
