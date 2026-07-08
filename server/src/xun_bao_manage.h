#ifndef  _XUN_BAO_DATA_H_
#define _XUN_BAO_DATA_H_

#include "self_typedef.h"
#include <vector>
#include <map>
#include <set>
#include "utility.h"
using namespace std;

// 闯关地图管理
typedef pair<uint8, uint8> evt_rand;
struct cell_pos
{
	uint8 start;
	uint8 end;
	vector<uint8> evts;
	vector<evt_rand> rands;
};
typedef vector<cell_pos> allEvts;					// 当前地图所有事件
typedef vector<cell_pos>::iterator allEvtsIt;

typedef map<uint8, allEvts> allMaps;
typedef map<uint8, allEvts>::iterator allMapsIt;	// 所有地图

typedef map<uint8, uint8> cellCntMap;
typedef map<uint8, uint8>::iterator cellCntMapIt;   // 地图格子总数

typedef map<uint8, set<uint8> > KLFightPosMap;
typedef KLFightPosMap::iterator KLFightPosMapIt;

struct KunlunCfg
{
	double powerPercent;
	double epowerPercent;
	MultiAward finishAward;
	uint16 fightAwardId;
};
typedef map<uint8, KunlunCfg> KunlunCfgMap;
typedef map<uint8, KunlunCfg>::iterator KunlunCfgMapIt;

struct YouLiCfg
{
	uint8 id;
	uint8 quality;
	uint16 level;
	uint16 rewardId;
	uint16 sumWeight;
	uint16 dlgId;
	MultiAward normalReward;
	U16tU16Map suiPianRatio;

	uint8 RankCnt()
	{
		uint16 rd = Random(0, sumWeight);
		for (U16tU16MapIt it = suiPianRatio.begin(); it != suiPianRatio.end(); ++it)
		{
			if (rd <= it->second)
				return it->first;
		}
		return 0;
	}
};
typedef map<uint8, YouLiCfg> YouLiCfgMap;
typedef map<uint8, YouLiCfg>::iterator YouLiCfgMapIt;

typedef vector<uint16> YouLiDlgCfg;
typedef map<uint8, YouLiDlgCfg> YouLiDlgMap;
typedef map<uint8, YouLiDlgCfg>::iterator YouLiDlgMapIt;

struct YouLiCost
{
	uint8 id;
	uint16 bigSec;
	uint16 smallSec;
	MultiCost costs;
};
typedef map<uint8, YouLiCost> YouLiCostMap;
typedef map<uint8, YouLiCost>::iterator YouLiCostMapIt;

class CChuangGuanMapManager
{
public:
	CChuangGuanMapManager();
	~CChuangGuanMapManager()
	{
	}

	bool Init();
	bool InitKunLun();
	bool InitSanJie();
	allEvts* GetMapById(uint8_t);
	uint8 GetMapCellCnt(uint8_t);
	KunlunCfg* GetKunLunCfg(uint8);
	bool CanAttack(uint8 cpos, uint8 apos);
	YouLiCost* GetYouLiCost(uint8 type);
	YouLiCfg* GetYouLiCfg(uint8 id);
	YouLiDlgCfg* GetYouLiDlgCfg(uint8 id);
	uint8 RandDlgId(uint8 type);
private:
	KLFightPosMap m_fightPos;
	allMaps m_chuangGuanMaps;
	cellCntMap m_chuangGuanCellCnts;
	KunlunCfgMap m_kunlunCfgs;
	YouLiCfgMap m_youLiCfgs;
	YouLiDlgMap m_youLiDlgs;
	YouLiCostMap m_youLiCosts;
};

#define sCChuangGuanMapManager boost::details::pool::singleton_default<CChuangGuanMapManager>::instance()

// 战斗信息
struct xunBaoFight
{
	xunBaoFight()
		: cid_(0)
		, career_(0)
		, sex_(0)
		, effect_(0)
		, robot_(0)
		, lv_(0)
		, weapon_(0)
		, pwoer(0)
		, uid_(0)
		, name_("")
	{
	}
	uint8 cid_;
	uint8 career_;
	uint8 sex_;
	uint8 effect_;
	uint8 robot_;
	uint16 lv_;
	uint16 weapon_;
	uint32 pwoer;
	uint32 uid_;
	string name_;

	bool operator<(const xunBaoFight& other) const
	{
		return pwoer < other.pwoer;
	}

	void operator=(const xunBaoFight& other)
	{
		uid_ = other.uid_;
		name_ = other.name_;
		lv_ = other.lv_;
		career_ = other.career_;
		sex_ = other.sex_;
		weapon_ = other.weapon_;
		effect_ = other.effect_;
		robot_ = other.robot_;
		pwoer = other.pwoer;
	}
};

struct lessUnit
{
	lessUnit()
	{
		pos = 0;
		hp = 0;
		maxHp = 0;
	}
	uint8 pos;
	uint64 hp;
	uint64 maxHp;
};

struct KunLunFight : public xunBaoFight
{
	KunLunFight()
		: xunBaoFight()
		, state(0)
	{
		hpPercent.clear();
	}
	uint8 state; // 状态 1 战斗前   2 战斗中 3 已经通过
	vector<lessUnit> hpPercent;		// 血量百分比，  状态2才会有
	void MakeLessHpMsg(CNetMessage& msg);
};

// 奖励
struct xunBaoAwardSum
{
	uint32 exp_;
	uint32 gold_;
	uint32 coin_;
};

struct xunBaoKills
{
	uint32 enemys_;  // 对手数量
	uint32 killer_;  // 当前杀敌
};


typedef vector<uint8> XunBaoVec;
typedef vector<xunBaoFight> FightVec;
typedef map<uint8, KunLunFight> KLFightMap;
typedef map<uint8, KunLunFight>::iterator KLFightMapIt;

enum XunBaoEvent {
	XBE_Empty = 0, // 空
	XBE_Begin,    // 起点
	XBE_Robber,    // 战斗
	XBE_Box,       // 宝箱
	XBE_Hand,      // 猜拳
	XBE_End,       // 终点 
	XBE_Goal,      // 元宝
	XBE_Coin,      // 金币
	XBE_Random,    // 问号
};

struct YouLiData
{
	YouLiData()
		: id(0)
		, type(0)
		, cnt(0)
		, heroId(0)
		, lastTime(0)
		, endTime(0)
		, suiPianCnt(0)
	{
		smallAwards.clear();
		dlgs.clear();
	}
	uint8 id;
	uint8 type;
	uint8 cnt;
	uint16 heroId;
	uint32 lastTime;
	uint32 endTime;
	uint16 suiPianCnt;
	vector<MultiAward> smallAwards;
	vector<uint16> dlgs;
};
typedef map<uint8, YouLiData> YouLiDataMap;
typedef map<uint8, YouLiData>::iterator YouLiDataMapIt;

class CXunBaoManage
{
public:
	enum ECGOp
	{
		ECGOp_Join = 1, // 加入
		ECGOp_Sync = 2, // 同步数据
		ECGOp_Roll = 3, // roll点
		ECGOp_MoveEnd = 4, // 移动完成
		ECGOp_Msg = 5, // 提示消息
		ECGOp_Hand = 6, // 手头剪刀布协议消息
		ECGOp_Goal = 7, // 获得元宝 与原协议一样
		ECGOp_Reset = 8, // 重置闯关数据
		ECGOp_ResetRollCd = 9, // 重置roll点cd时间
		ECGOp_FightReport = 10, // 前端发起战斗
		ECGOp_Box = 11,     // 获得宝箱 与原协议一样ECGOp_End
		ECGOp_Robber = 12, // 小贼战斗
		ECGOp_SyncCD = 13, // 第一次进房间同步cd时间
		ECGOp_EnableCount = 14, // 剩余有效进入次数
		ECGOp_QueryInfo = 15, // 查询地图数据 15
		ECGOp_RandomEvent = 16, // 随机事件 前进或者后退
		ECGOp_EmptyEvent = 17,  // 走到没有事件的格子
		ECGOp_Coin = 18,        //    获得金币
		ECGOp_End = 19,         //    通关
		ECGOp_QueryEnemy = 20,  //    获取敌人数据 名字 等级 战斗力 奖励等
		ECGOp_BuyRollTimes = 21,  //  购买筛子次数
		ECGOp_QueryBuyRollInfo = 22,  //  购买筛子次数
		ECGOp_RewardSum = 23,  //  奖励统计
		ECGOp_Quit = 24,  // 离开昆仑寻宝
		ECGOp_KunLunInfo = 25,  // 昆仑信息
		ECGOp_KunLunFight = 26,  // 昆仑战斗
		ECGOp_KunLunFightResut = 27,  // 昆仑战斗结果
		ECGOp_KunLunBuy = 28,  // 昆仑次数购买
		ECGOp_KunLunLianChuang = 29,  // 昆仑连闯
		ECGOp_KunLunAward = 30,  // 宝箱奖励
		ECGOp_KunLunFightFaild = 31,
		ECGOp_KunLunRobot = 32,
		ECGOp_XunBaoFight = 33,  // 寻宝战斗
	};
	enum BUY_ROLL_TIMES_ERRCODE
	{
		NOT_ENOUGH_MONEY = 1,
		HAVE_FULL_ROLLTIMES = 2,
		ROLL_BUYTIMES_MAXLIMIT = 3,
	};

	enum ROLL_ERRCODE
	{
		FIGHT_CELL = 1,
		ROLL_TIMES_LIMIT = 2,
	};
public:
	CXunBaoManage(CUser* pUser);

	virtual ~CXunBaoManage()
	{

	}

public:
	bool CreateMap();
	void LoadMap(const char *row);
	void SaveMap(string& str);
	void ClearMap(bool clearSum = false);
	void ResetMap();
	void LoadMatchFights(CNetMessage& msg);

	// 通知地图信息给客户端
	void NotifyMapInfo();

	void UserBuyRollTimes();
	void UserQueryBuyRollInfo();
	void PlayHand();
	void Roll();
	void AddChuangguanMaterial(int type, bool isFight = false, MultiAward* awards = NULL);
	void FightPvP();
	void PvPFightCallBack(uint8 star);
	void DoStopEvt();

public:
	KunLunFight* GetKunLunFight(uint8 pos);
	void LoadKunLunFights(CNetMessage& msg);
	void GetKunLunMsg(CNetMessage& msg);
	void TryKunLunFight(CNetMessage& msg);
	void BuyFightCnt(CNetMessage& msg);
	void LianXuFight(CNetMessage& msg);
	void GetRobotMsg(CNetMessage& msg);
	void KunLunFightCallBack();

public:
	void YouLiAwardCheck();
	void GetYouLiMsg(CNetMessage& msg);
	void StartYouLi(CNetMessage& msg);
	void GetYouLiAward(CNetMessage& msg);
	YouLiData* GetYouLiData(uint8 id);
	bool IsTry() { return m_fightCnt != CXunBaoManage::XUNBAO_FIGHT_CNT; }

private:
	void AddEvent(uint8 cellId, uint8 evt);
	void DoRandomEvent();
	void CalcStopCell();
	void ClearEvt(uint8 cellId);

	void CheckFinishAward(bool isFight);
private:
	XunBaoVec m_xunBao;     // 所有事件
	FightVec m_fights;      // 战斗信息
	xunBaoAwardSum m_award;    // 当日奖励
	xunBaoKills m_report; // 当局击杀
	uint8 m_curIdx; // 当前格子
	uint8 m_stopIdx; // 目标格子格子
	CUser* m_pUser;
	uint8 m_state; // 0 roll 1 战斗 2 猜拳
	bool m_hasMatch;

private:
	KLFightMap m_klFight;		// 昆仑信息
	uint8 m_floor;
	uint8 m_curPos;
	uint8 m_fightCnt;
	uint8 m_buyCnt;
	uint8 m_fightPos;
	uint8 m_lastPos;

	YouLiDataMap m_youLi;

private:


public:
	static const int JOIN_LIMIT = 2; // 每日参加次数
	static const int CHUANG_GUAN_ENTER_LEVEL = 28; // 多人闯关进入等级
	static int XUNBAO_FIGHT_CNT; // 寻宝战斗次数
	static vector<int> BuyCost; // 寻宝战斗次数
};

#endif
