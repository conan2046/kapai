#ifndef _BLOOD_FIGHT_MANAGER_H_
#define _BLOOD_FIGHT_MANAGER_H_
#include "self_typedef.h"
#include <map>
#include <set>
#include <vector>
#include "hero_cfg_manager.h"
#include "fight.h"
using namespace std;

struct BloodNodeCfg
{
	uint8 chapterId;
	uint8 easyId;
	uint8 normalId;
	uint8 hardId;
	double ratio;
	StarCond conds;
	MultiAward awards;		// 首通奖励
};

typedef map<uint16, BloodNodeCfg> BloodNodeCfgMap;
typedef map<uint16, BloodNodeCfg>::iterator BloodNodeCfgMapIt;

struct BloodChapter
{
	BloodNodeCfgMap nodes;
	map<uint16, U8tU32Map> fixIds;

	U8tU32Map* GetFixIds(uint16 nodeId)
	{
		map<uint16, U8tU32Map>::iterator it = fixIds.find(nodeId);
		if (it == fixIds.end())
			return NULL;

		return &it->second;
	}
};

typedef map<uint8, BloodChapter> ChapterBloodCfgMap;
typedef map<uint8, BloodChapter>::iterator ChapterBloodCfgMapIt;

struct BloodBuff
{
	uint8 jiage;
	uint16 buffId;
	SAttrData attr;
};

struct BloodTypeBuffs
{
	U16tU16Map buffWeight;
	uint32 sumWeight;
	uint16 GetBuffId();
};
typedef map<uint8, BloodTypeBuffs> BloodTypeBuffMap;
typedef map<uint8, BloodTypeBuffs>::iterator BloodTypeBuffMapIt;
typedef map<uint8, BloodBuff> BloodBuffMap;
typedef map<uint8, BloodBuff>::iterator BloodBuffMapIt;

struct BloodFight
{
	uint8 formation;
	uint32 show;
	vector<uint32> monster;
};

struct BloodTypeFights
{
	U16tU16Map fightWeight;
	uint32 sumWeight;

	uint16 GetFightId();
};
typedef map<uint8, BloodTypeFights> BloodTypeFightMap;
typedef map<uint8, BloodTypeFights>::iterator BloodTypeFightMapIt;
typedef map<uint8, BloodFight> BloodFightMap;
typedef map<uint8, BloodFight>::iterator BloodFightMapIt;

struct BloodCntCfg
{
	uint8 tryTimes;
	uint8 fuhuoTimes;
};
typedef map<uint8, BloodCntCfg> BloodTypeCntCfgMap;
typedef map<uint8, BloodCntCfg>::iterator BloodTypeCntCfgMapIt;

typedef map<uint8, MultiAward> ChapterAllAwardMap;
typedef map<uint8, MultiAward>::iterator ChapterAllAwardMapIt;

class CBloodFightCfgManager
{
public:
	CBloodFightCfgManager();
	~CBloodFightCfgManager();

public:
	bool InitBloodFightCfg();
	bool InitBloodNodeCfg();
	bool InitBloodBuffCfg();
	bool InitBloodFormationCfg();
	bool InitBloodCntCfg();
	bool InitChapterAllAward();

public:
	uint16 GetChapterFirstNode(uint8 chapter);
	uint16 GetBloodNodeChpterId(uint16 nodeId);
	BloodChapter* GetBloodChapterCfg(uint8 chapterId);
	BloodNodeCfg* GetBloodNodeCfg(uint16 nodeId);
	void MakeBloodBuff(vector<BloodBuff>& buff);
	
	BloodCntCfg* GetCntCfg(uint8 type);
	uint16 MakeBloodFightId(uint8 type);


	BloodBuff* GetBloodBuffCfg(uint16 buffId);
	BloodFight* GetBloodFightCfg(uint16 buffId);
	U8tU32Map* GetBloodFixCfg(uint16 nodeId);

	MultiAward* GetBloodChaterAward(uint8 chapter);

	uint16 GetMaxNodeId() { return m_maxNodeId; }
private:
	U16tU8Map m_nodeChapter;
	U16tU16Map m_firstNodes;
	ChapterBloodCfgMap m_chapterBloodCfgs;
	BloodTypeBuffMap m_allBuff;
	BloodBuffMap m_bloodBuffs;
	BloodTypeFightMap m_allFights;
	BloodFightMap m_bloodFights;
	BloodTypeCntCfgMap m_bloodCnts;
	ChapterAllAwardMap m_chapterAllAwards;
	uint16 m_maxNodeId;
};
#define sCBloodFightCfgManager boost::details::pool::singleton_default<CBloodFightCfgManager>::instance()

struct NodeNormalAward
{
	NodeNormalAward()
		: star(0)
	{
	}
	uint8 star;
	U8tU8Map getstate;
};
typedef map<uint16, NodeNormalAward> NodeNormalAwardMap;
typedef map<uint16, NodeNormalAward>::iterator NodeNormalAwardMapIt;

enum BloodState
{
	BS_Fight = 1,
	BS_Dead = 2,
	BS_DeadEnd = 3,
	BS_End = 4,
	BS_Ready = 5,
	BS_SaoDangBuff = 7,
	BS_SaoDangBuffEnd = 8,
};

class CUserBloodFight
{
public:
	CUserBloodFight();
	~CUserBloodFight();

public:
	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(const char *str);

public:
	void InitUserBloodFight();
	void ResetUserBloodFight();
	void NewUserBloodFight();

	void GetBloodMsg(CUser* pUser, CNetMessage& msg);
	void SendBFHotPointStatus(CUser* pUser);
	void GetFiveFixMsg(CUser* pUser, CNetMessage& msg);
	void TrapCurFightMsg(CUser *pUser);
	StarCond& GetWinCond() { return m_conds; }
	void BloodFightResult(CUser* pUser, uint8 star);
	void NewBloodFight(CUser* pUser, CNetMessage& msg);
	void TryBloodFight(CUser* pUser, CNetMessage& msg);
	void RetryBloodFight(CUser* pUser, CNetMessage& msg);
	void ReviveBloodFight(CUser* pUser, CNetMessage& msg);
	void BloodFightSaoDang(CUser* pUser, CNetMessage& msg);
	void SelectBloodBuff(CUser* pUser, CNetMessage& msg);
	void GetRankAward(CUser* pUser, CNetMessage& msg);
	void SetAutoSltBuff(CNetMessage& msg);
	void SelectSaoDangBloodBuff(CUser* pUser, CNetMessage& msg);
	uint16 GetMaxFloor() { return m_firstAward; }
	uint16 GetMaxHardFloor() { return m_maxHardNode; }
	NodeNormalAward& GetFiveAwardState(uint16 nodeId);
	void GetSomeRecord(CUser* pUser, CNetMessage& msg);
	
	void GetTodayInfo(uint16 &star, uint16 &nodeId);
	bool IsTry();
	
private:
	void MakeFight();
	void tryMakeNextBlood(CUser *pUser);
	void SendChapterAward(CUser *pUser);
	void SendSaoDangBuff(CUser *pUser);
	void TrapSaoDangBuff(CUser *pUser);
	void TrapBuffAttr(CUser *pUser);

	void AddStar(CUser *pUser, uint16 addStar);

private:
	uint8 m_curTryType;
	uint8 m_tryTimes;
	uint8 m_fuhuoTimes;
	uint8 m_state;				// 1 战斗 2 死亡 3 领取奖励 4全通状态
	uint8 m_rankState;			// 排行奖励领取状态
	uint8 m_curChapter;			// 当前章节
	uint8 m_bufIdx;				// 当前章节
	uint8 m_fiveStar;			// 五关总星
	uint8 m_SltIdx;				// 扫荡buff选择索引
	int m_SltSet;				// buff选择设置
	uint16 m_curNodeId;			// 当前关卡
	uint16 m_maxHardNode;		// 最高困难关
	uint16 m_highStar;			// 总星
	uint16 m_allStar;			// 总星
	uint16 m_todayMaxStar;		// 今日最高星总星
	uint16 m_todayMaxNode;		// 今日最高关卡
	uint16 m_curStar;			// 剩余星
	uint16 m_firstAward;		// 首通奖励领取记录

	uint16 m_easyFight;			// 简单
	uint16 m_normalFight;		// 普通
	uint16 m_hardFight;			// 困难

	StarCond m_conds;		// 困难条件
	vector<BloodBuff> m_sltBuff;		// 当前可选buff
	MultiAttr m_buffs;			// buf
	NodeNormalAwardMap m_normalAwards;
};

#endif