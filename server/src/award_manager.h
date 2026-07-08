#ifndef award_manager_h
#define award_manager_h

#include <list>
#include <vector>
#include <map>

#include "xml.h"
#include "utility.h"
#include "self_typedef.h"

struct LvAwardData
{
	int aid;
	int num;			// 掉落
	bool isRepeat;		// 数量
};

struct SingleAward
{
	uint32 weight;
	vector<SAwardData> awards;
};

struct AwardWeight
{
	AwardWeight()
	{
		weightSum = 0;
		awards.clear();
	}
    uint32 weightSum;
	vector<SingleAward> awards;
};

typedef pair<uint32, uint32> levelInterval;
struct levelReward
{
	vector<levelInterval> levels;
	vector<LvAwardData> rewards;
};

// ------------------------------
// 活跃度奖励结构
typedef struct ActivityAwardData_t
{
    uint32 aid_; 
    uint32 activity_;
}ActivityAwardData;

typedef map<int, levelReward> lvRewardMap;
typedef map<int, levelReward>::iterator lvRewardMapIt;

typedef map<int, AwardWeight> awardWeightMap;
typedef map<int, AwardWeight>::iterator awardWeightMapIt;

typedef map<int, int> vitalityAIdMap;
typedef map<int, int>::iterator vitalityAIdMapIt;
typedef map<int, int>::const_iterator vitalityAIdMapCIt;

struct DropNotic
{
	set<uint16> itemIds;
	string notic;
};

typedef map<int, DropNotic> DropNoticMap;
typedef map<int, DropNotic>::iterator DropNoticMapIt;
typedef map<int, DropNotic>::const_iterator DropNoticMapCIt;

// 排名奖励
typedef levelInterval rankInterval;
struct typeRankRewards
{
	vector<rankInterval> ranks;
	vector<MultiAward> rewards;
	
	//rank 从低到高排序
	bool operator <(const typeRankRewards other) const
	{
		if(ranks.empty() || other.ranks.empty())
			return false;
		if(ranks[0] < other.ranks[0])
			return true;
		return false;
	}
};
typedef map<int, typeRankRewards> rankRewardMap;
typedef map<int, typeRankRewards>::iterator rankRewardMapIt;

struct OnlineRewardCfg
{
	uint8 id;
	uint16 sec;
	SAwardData reward;
};
typedef map<int, OnlineRewardCfg> OnlineRewardCfgMap;
typedef map<int, OnlineRewardCfg>::iterator OnlineRewardCfgMapIt;

//enum EM_RANK_AWARD
//{
//	EMRA_JING_JI = 1, //竞技场排名奖励
//	EMRA_XueZhan = 2, // 血战排名奖励
//	EMRA_ZHU_TIAN_HUAN_JING = 3, // 诸天幻境排名奖励
//	EMRA_FENG_SHEN_ZHAN_CHANG = 4, // 封神战场排名奖励
//	EMRA_KUN_LUN_SHAN_TEAM = 5,	// 组队昆仑山
//	EMRA_MI_JING = 6,	// 神界秘境
//	EMRA_BANG_ZHAN_ROLE = 7,	// 帮战帮派个人积分
//	EMRA_BANG_ZHAN_GUILD = 8,	// 帮战帮派榜
//	EMRA_KUN_LUN_SHAN_TEAM_Server = 9,	// 组队昆仑山服务器奖励
//	EMRA_KF_1V1_Preliminary = 10,	// 跨服1V1 惟我独仙 预赛
//	EMRA_KF_1V1_Final = 11,	// 跨服1V1 惟我独仙 决赛
//};

class AwardManager
{

public:
    AwardManager();

public:
    bool InitAwardManager();
	void GetLevelAward(uint32 aid, uint32 userlv, std::vector<SAwardData> &awvec, bool clear = true);
	void GetLevelRandAward(uint32 aid, uint32 userlv, std::vector<SAwardData> &awvec,int num);
	int GetRankAward(uint32 type, uint32 rank, std::vector<SAwardData> &awvec);
	typeRankRewards* GetAllRankAwards(uint32 type);
	OnlineRewardCfg* GetOnlineRewardCfg(uint8 idx);
	// 获取转盘数据
	int GetAwardPanal(uint32 aid, uint32 userlv, uint32 num, std::vector<SAwardData> &awvec);
	void MakeAwardMsgAndSendAward(CUser* pUser, uint32 sceneId, CNetMessage& msg);
	void ActivityMakeAwardMsgAndSendAward(CUser* pUser, uint32 activityId, CNetMessage& msg, int type = 1);
	void GetActivityDrop(CUser* pUser, uint32 activityId, int type, std::vector<SAwardData> &awvec);
    bool GetAwardById(uint32 aid, std::vector<SAwardData> &awvec, int num = 1, bool isRepeat = true, bool clear = true, bool isMerge=true);

    void SendVitalityAward(CUser *pUser, uint32 vitality, CNetMessage* msg = NULL);
	const vitalityAIdMap& GetVitalityAIds() { return m_vitalityAIds; }
	void SendLevelAward(CUser *pUser, int aid, CNetMessage* msg = NULL);
	void SendRankAward(CUser *pUser, uint32 type, uint32 rank, CNetMessage* msg = NULL);
	void SendRankAwardMail(uint32 type, uint32 userId, uint32 rank, const char* buf);
	void SendRankAwardMailExHb(uint32 type, uint32 userId, uint32 rank, const char* buf, SAwardData award);
	void SendNotic(CUser *pUser, const char* fromStr, uint32 dropId, uint16 type, uint16 val, uint16 ext);
	void SendAndMakeAwardMsg(CUser *pUser, uint16 aid, CNetMessage& msg, bool showMsg = false, uint16 addType = 0);

public:
	static void XiPai(uint32 baseNum, uint32 num, std::vector<uint32>& seqs);

private:
	bool LoadAwardXmlConfig();
	bool LoadRewardConfig();
	bool LoadVitalityConfig();
	bool LoadRankAwardConfig();
	bool LoadDropNotic();
	bool LoadOnlineAward();

private:
	lvRewardMap m_levelRewards;
	rankRewardMap m_rankAwards;   // 排名奖励 不随机
	awardWeightMap m_weightRewards;
	vitalityAIdMap m_vitalityAIds;
	DropNoticMap m_dropNotics;
	OnlineRewardCfgMap m_onlineRewardCfg;
};
typedef boost::details::pool::singleton_default<AwardManager> SingletonAwardManager;
#define sAwardManager SingletonAwardManager::instance()

class CDropMatchingMgr
{
public:
	CDropMatchingMgr();
	virtual ~CDropMatchingMgr();

public:
	bool Init();
	int GetInstanceDropId(int insId, int type);
	int GetActivityDropId(int actId, int type = 1);
	int GetItemDropId(int itemId, int type = 1);

private:
	void AddInstanceDrop(int id, int stype, int rid);
	void AddActivtiyDrop(int id, int stype, int rid);
	void AddItemDrop(int id, int stype, int rid);

private:
	typedef std::map<int, int> DorpIds;
	typedef std::map<int, int>::iterator DorpIdsIt;
	typedef std::map<int, DorpIds> InsDropIds;
	typedef std::map<int, DorpIds>::iterator InsDropIdsIt;
	InsDropIds m_insDropIds;		// 副本掉落id
	InsDropIds m_activityDorpIds;      // 玩法掉落id
	InsDropIds m_itemDorpIds;          // 物品掉落id
};

#define sCDropMatchingMgr boost::details::pool::singleton_default<CDropMatchingMgr>::instance()

#endif 