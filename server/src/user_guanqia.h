#ifndef _USER_GUANQIA_H_
#define _USER_GUANQIA_H_
#include "self_typedef.h"
#include <map>
#include <set>
#include <vector>
using namespace std;


class CUser;

struct MapNodeCfg
{
	uint8 type;
	uint8 maxTimes;	
	uint8 spiritCost;
	uint32 mapId;
	uint32 nodeId;
	uint16 levelLimit;
	uint32 nextNodeId;
	uint32 rewardId;
	uint32 fixId;
	uint32 fightId;
	int allUserAwardId;	// 帮派副本通关奖励
	string name;
	MultiAward firstAward;
	MultiAward normalAward;
	MultiAward moneyAward;
	MultiAward fightAward;		// 每次挑战奖励
	MultiAward finalKillAward;	// 击杀者奖励
	MultiAward firstRankAward;	// 伤害第一奖励
};
typedef map<uint32, uint32> CurNodeMapIdMap;
typedef map<uint32, uint32>::iterator CurNodeMapIdMapIt;
typedef map<uint32, MapNodeCfg> CurMapNodeCfgMap;
typedef map<uint32, MapNodeCfg>::iterator CurMapNodeCfgMapIt;

typedef map<uint8, uint32> StarFixMap;
typedef map<uint8, uint32>::iterator StarFixMapIt;

typedef map<uint32, MultiAward> FixAwardMap;
typedef map<uint32, MultiAward>::iterator FixAwardMapIt;

struct SingleZhangJieCfg
{
	uint8 type;
	uint32 id;
	uint16 openLv;
	string name;
	set<uint8> openWeek;
	CurMapNodeCfgMap nodes;
	StarFixMap starFix;
};
typedef map<uint32, SingleZhangJieCfg> CAllZhangJieMap;
typedef map<uint32, SingleZhangJieCfg>::iterator CAllZhangJieMapIt;

typedef vector<uint32> CMapIdVec;
typedef map<uint8, CMapIdVec> CTypeMaps;
typedef map<uint8, CMapIdVec>::iterator CTypeMapsIt;

struct ChengJiuCfg
{
	uint8 type;
	uint16 star;
	SAwardData award;
};

typedef vector<ChengJiuCfg> ChengJiuCfgVec;
typedef map<uint8, ChengJiuCfgVec> ChengJiuCfgMap;
typedef map<uint8, ChengJiuCfgVec>::iterator ChengJiuCfgMapIt;

class CGuanQiaCfgMgr
{
public:
	CGuanQiaCfgMgr()
	{
		m_typeMaps.clear();
		m_allMapCfg.clear();
		m_chengJiuCfg.clear();
	}
	~CGuanQiaCfgMgr()
	{
		m_typeMaps.clear();
		m_allMapCfg.clear();
		m_chengJiuCfg.clear();
	}
	
public:
	bool InitMap();
	// 大地图数据
	bool LoadBigMapCfg();
	// 战斗节点数据
	bool LoadMapNodeCfg();
	// 宝箱数据
	bool LoadFixCfg();
	bool InitChengJiuCfg();
	// 获取地图节点
	MapNodeCfg* GetMapNodeCfg(uint32 mapId, uint32 nodeId);
	MapNodeCfg* GetMapNodeCfg(uint32 nodeId);
	// 获取当前地图所有章节
	SingleZhangJieCfg* GetZhangJieCfg(uint32 mapId);
	// 查询宝箱奖励
	MultiAward* QueryFixAward(uint32 fixId);
	// 获取宝箱信息
	void MakeFixMsg(uint32 fixId, CNetMessage &msg);
	// 获取重置消耗
	uint16 GetResetCost(uint8 times);
	// 地图信息
	void MakeMapMsg(uint8 type, CNetMessage &msg);
	// 获取章节地图Id
	uint32 GetNodeMapId(uint32 nodeId);
	// 获取当前类型所有地图
	CMapIdVec* GetTypeMapIds(uint8 type);
	ChengJiuCfgVec* GetChengJiuCfgVec(uint8 type);
	ChengJiuCfg* GetChengJiuCfg(uint8 type, uint8 idx);

public:
	static uint8 g_LieZhuanCnt;
	static uint8 g_MaxReSetCnt;
private:
	CTypeMaps m_typeMaps;			// 地图分组
	CAllZhangJieMap m_allMapCfg;	// 所有主线
	CurNodeMapIdMap m_allNodeIds;
	FixAwardMap m_allFixs;
	vector<uint16> m_resetCost;		// 重置消耗
	ChengJiuCfgMap m_chengJiuCfg;
};
typedef boost::details::pool::singleton_default<CGuanQiaCfgMgr> SingletonCGuanQiaCfgMgr;
#define sCGuanQiaCfgMgr SingletonCGuanQiaCfgMgr::instance()

// 已经挑战过的关卡被挑战的次数
typedef map<uint32, uint8> NodeBeAttackCnt;
typedef map<uint32, uint8>::iterator NodeBeAttackCntIt;

// 关卡重置记录
typedef map<uint32, uint8> NodeResetCntMap;
typedef map<uint32, uint8>::iterator NodeResetCntMapIt;

// 每个章节里面 关卡的星星
typedef map<uint32, uint8> NodeStarMap;
typedef map<uint32, uint8>::iterator NodeStarMapIt;

// 宝箱领取状态
typedef NodeStarMap FixGetState;
typedef NodeStarMap::iterator FixGetStateIt;
// 角色关卡信息
struct SingleGuanQiaScore
{
	uint16 sumStar;	// 总星
	NodeStarMap nodeStars;	// 节点星星
	set<uint32> fixIds;		// 未领取宝箱
	FixGetState fixState;
};

typedef map<uint32, SingleGuanQiaScore> GuanQiaMap;
typedef map<uint32, SingleGuanQiaScore>::iterator GuanQiaMapIt;
struct UserGuanQia
{
	UserGuanQia()
		: curMapId(0)
		, curNodeId(0)
		, allStar(0)
	{

	}
	uint32 curMapId;
	uint32 curNodeId;	// 当前节点
	uint16 allStar;
	GuanQiaMap guanQiaScores;
};

struct ShiLianGuanQia
{
	ShiLianGuanQia()
		: cnt(0)
		, isOpen(false)
		, sdNodeId(0)
		, tzNodeId(0)
	{

	}
	uint8 cnt;
	bool isOpen;
	uint32 sdNodeId;
	uint32 tzNodeId;
};
typedef map<uint32, ShiLianGuanQia> ShiLianGuanQiaMap;
typedef map<uint32, ShiLianGuanQia>::iterator ShiLianGuanQiaMapIt;


struct LieZhuanGuanQia
{
	uint8 cnt;						// 挑战次数
	uint32 curMapIdx;				// 当前章节序号
	uint32 curNodeId;				// 当前章节序号
};

class CUserGuanQia
{
public:
	CUserGuanQia();
	~CUserGuanQia();

public:
	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(const char *str);
	// 初始化
	void InitGuanQia();
	// 数据清理
	void ResetGuanQia();
	void MakeUserGuanQiaMsg(uint8 type, CNetMessage &msg);
	void MakeSinggleGuanQiaMsg(uint8 type, uint32 mapId, CNetMessage &msg);
	int8_t GetNodeStar(uint8 type, uint32 mapId, uint32 nodeId);
	void MakeNodeMsg(CUser* pUser, CNetMessage &msg);
	void MakeFixMsg(uint32 fixId, CNetMessage &msg);
	void GetFixAward(CUser* pUser, uint8 type, uint32 mapId, uint32 fixId, CNetMessage &msg);
	void EnterGuanQiaFight(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId, CNetMessage &msg);
	SingleGuanQiaScore* GetUserGuanQia(uint8 type, uint32 mapId);
	uint32 GetGuanQiaStar(uint8 type);
	void GuanQiaSaoDang(CUser* pUser, uint8 type, uint32 mapId, uint32 nodeId, CNetMessage &msg);
	void GuanQiaReset(CUser* pUser, uint32 nodeId, CNetMessage &msg);
	void GuanQiaWin(CUser* pUser, uint8 star);
	void AddNewSinggleGuanQia(uint8 type, uint32 mapId, uint32 nodeId);

	// 获取试炼信息
	void GetShiLianMsg(CUser* pUser, CNetMessage &msg);
	// 挑战试炼
	void TiaoZhanShiLian(CUser* pUser, CNetMessage &msg);
	// 扫荡试炼
	void SaoDangShiLian(CUser* pUser, CNetMessage &msg);

	// 获取列传信息
	void GetLieZhuanMsg(CUser* pUser, CNetMessage &msg);
	// 挑战列传
	void TiaoZhanLieZhuan(CUser* pUser, CNetMessage &msg);

	void GetChengJiuMsg(CUser* pUser, CNetMessage &msg);
	void GetChengJiuAward(CUser* pUser, CNetMessage &msg);
	uint8 SendCJHotPointStatus(CUser* pUser);
	uint8 SendFixHotPointStatus(CUser* pUser);
	uint8 SendShiLianHotPointStatus(CUser* pUser);
	void SendFuBenHotPointStatus(CUser* pUser);

	int GetShiLianCnt(uint8 type, bool part);
	int GetLieZhuanCnt(bool part);
#ifdef _DEBUG
	void GuanQiaGM(CUser* pUser, uint8 type, uint16 num);
#endif // _DEBUG

private:
	void SaveGuanQia(UserGuanQia& gq, uint8* data, int& pos);
	void LoadGuanQia(UserGuanQia& gq, uint8* data, int& pos);
	int GetCurAttackCnt(uint32 nodeId);

private:
	UserGuanQia m_guanQiaZhuScore;
	UserGuanQia m_guanQiaZhiScore;
	NodeBeAttackCnt m_nodeBeAttackCnt;
	NodeResetCntMap m_nodeResetCnt;
	ShiLianGuanQiaMap m_slGuanQia;
	LieZhuanGuanQia m_lzGuanQia;
	uint8 m_curType;
	uint32 m_curMapId;
	uint32 m_curNodeId;
	uint8 m_achId;
	uint8 m_achState;
};

#endif