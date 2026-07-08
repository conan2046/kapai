#ifndef _ARENA_H_
#define _ARENA_H_

#include <vector>
#include <map>
#include "self_typedef.h"
#include "singleton.h"

class CFight;
class CUser;

enum ERobotType
{
	EROT_Arena = 1,		// 竞技场守卫
	EROT_KunLun = 2,	// 昆仑巡游者
};

struct SRobotData
{
	SRobotData()
	{
		sex = 0;
		head = 0;
		model = 0;
		quality = 0;
		zhenfaId = 0;
		zhenfaLv = 0;
		id = 0;
		memset(monsterId, 0, sizeof(monsterId));
		power = 0;
		name.clear();
	}
	uint8 sex;
	uint8 head;
	uint8 model;
	uint8 quality;
	uint8 zhenfaId;
	uint8 zhenfaLv;
	int id;
	int monsterId[5];	// 怪物配置id
	int power;
	std::string name;
};


typedef map<int, map<int, SRobotData> > _RobotTypeMap;
typedef map<int, map<int, SRobotData> >::iterator _RobotTypeMapIt;
typedef map<int, SRobotData> _RobotMap;
typedef map<int, SRobotData>::iterator _RobotMapIt;

class CRobotMgr
{
public:
	CRobotMgr();

	~CRobotMgr();

	bool Init();

	bool GetRobot(int type, int id, SRobotData &val);

	bool AddRobotToFight(CFight *pFight, int type, int id);

private:
	std::map<int, std::map<int, SRobotData> > m_data;	// [type]-[id]-[data]
};

typedef boost::details::pool::singleton_default<CRobotMgr> SingletonCRobotMgr;


//////////////////////////////////////////////////////

struct SArenaCfg
{
	SArenaCfg()
	{
		Clear();
	}
	void Clear()
	{
		rankBegin = 0;
		rankEnd = 0;
		fightNumBegin = 0;
		fightNumEnd = 0;
		robotId.clear();
	}

	int rankBegin;
	int rankEnd;
	int fightNumBegin;
	int fightNumEnd;
	std::vector<int> robotId;	// 机器人id列表
};

class CArenaCfgMgr
{
public:
	CArenaCfgMgr();

	~CArenaCfgMgr();

	bool Init();

	int GetRobotIdByRank(int rank);

	int GetRandIntervalByRank(int rank);

private:
	std::vector<SArenaCfg> m_cfg;

public:
	static uint8 FreeCnt;
	static uint8 BuyCnt;
};

typedef boost::details::pool::singleton_default<CArenaCfgMgr> SingletonCArenaCfgMgr;


///////////////////////////////////////////////////


enum EUserType
{
	EUT_User = 0,	// 角色
	EUT_Robot = 1,	// 机器人
};

struct SArenaUnit
{
	SArenaUnit()
	{
		type = EUT_User;
		roleId = 0;
	}
	uint8 type;	// 0 玩家 1 机器人
	uint32 roleId;
};

struct ArenaPaiHangData // 竞技场排行
{
	ArenaPaiHangData()
	{
		Clear();
	}

	void Clear()
	{
		type = EUT_User;
		upDown = 0;
		winNum = 0;
		rank = 0;
		roleId = 0;
		bowCount = 0;
		eggCount = 0;
	}
	
	void SetInvalid()
	{
		upDown = 0xff;
		winNum = 0xffff;
		rank = 0xffffffff;
		roleId = 0xffffffff;
		bowCount = 0xffffffff;
		eggCount = 0xffffffff;
	}

	bool operator<(const ArenaPaiHangData& a)
	{
		return this->rank < a.rank;
	}

	uint8 type;
	uint8 upDown;	// 排名升降0- 1上2下
	uint16 winNum;	// 连胜次数
	uint32 rank;	// 排名
	uint32 roleId;
	uint32 bowCount;	// 被膜拜次数
	uint32 eggCount;	// 被扔鸡蛋次数
};

struct ArenaFightData
{
	ArenaFightData()
	{
		state = 0;
		l_type = 0;
		l_VipLv = 0;
		l_Head = 0;
		l_Lv = 0;
		l_roleId = 0;
		l_Power = 0;
		r_type = 0;
		r_VipLv = 0;
		r_Head = 0;
		r_Lv = 0;
		r_roleId = 0;
		r_Power = 0;

		rank1 = 0;
		rank2 = 0;
		fightData = 0;
		time = 0;
		l_Name.clear();
		r_Name.clear();
	}

	uint8 state;

	uint8 l_type;
	uint8 l_VipLv;
	uint8 l_Head;
	uint16 l_Lv;
	uint32 l_roleId;
	uint64 l_Power;

	uint8 r_type;
	uint8 r_VipLv;
	uint8 r_Head;
	uint16 r_Lv;
	uint32 r_roleId;
	uint64 r_Power;

	uint32 rank1;
	uint32 rank2;
	uint32 fightData;
	
	uint32 time;
	string l_Name;
	string r_Name;

	void MakeMsg(CNetMessage& msg);
};

typedef map<uint32, ArenaPaiHangData> _ArenaPHMap;

class CArenaManager
{
public:
	CArenaManager();
	~CArenaManager();

	void AddUser(CUser *pUser);
	void AddUser(ArenaPaiHangData &data);
	void AddRobot(SArenaUnit &data);
	bool NolockChangeUser(uint32 rank1, uint32 rank2);
	bool Init();
	void Save();

	bool GetUserData(uint32 roleId, ArenaPaiHangData &data);
	bool GetUserDataByRank(uint32 rank, ArenaPaiHangData &data);
	bool GetDataByRank(uint32 rank, ArenaPaiHangData &data);
	uint32 GetUserRank(uint32 roleId);
	uint32 GetUserNum();
	void SendAwardToAllUser();
	void UpdateUserData(uint32 roleId,ArenaPaiHangData &data);
	void UpdateUserData(CUser *pUser);
	void AddArenaFightData(ArenaFightData &data);
	void GetTopArenaFightData(CNetMessage& msg);
	string GetDataName(ArenaPaiHangData &data);

	void ArenaSaveData(CUser *pUser, ArenaPaiHangData &self, ArenaPaiHangData &other, bool win, uint8 star=0);
	void SaveArenaLog(CFight *pFight, ArenaPaiHangData &self, ArenaPaiHangData &other, bool win, int srcRank);

	static const uint32 DefaultShowNum = 10000;	// 默认
	
private:
	boost::recursive_mutex m_mutex;
	vector<SArenaUnit> m_rank;
	map<uint32, ArenaPaiHangData> m_userData;

	
//	vector<ArenaPaiHangData *> m_userData;
//	map<uint64,uint32> m_userRank;
	uint32 m_num;
	list<ArenaFightData> m_topFightQue;
};

typedef boost::details::pool::singleton_default<CArenaManager> SingletonCArenaManager;


#endif

