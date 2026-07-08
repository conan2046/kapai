#ifndef _tower_reward_manager_h_
#define _tower_reward_manager_h_

#include <map>
#include "singleton.h"
#include "self_typedef.h"

class CUser;
struct towerSingleReward
{
	int first;
	int second;
	int ex1;
	int ex2;

	towerSingleReward()
	{
		first = 0;
		second = 0;
		ex1 = 0;
		ex2 = 0;
	}
};
typedef std::vector<towerSingleReward> towerRewards;
typedef map<int, towerRewards> towerReardMap;
typedef map<int, towerRewards>::iterator towerReardMapIt;
class TowerRewardManager
{
public:
	TowerRewardManager();
	~TowerRewardManager();

public:
	bool Init();

public:
	// 首通奖励
	void SendFirstReward(CUser *pUser, int floorId);
	// 普通奖励
	void SendNormalReward(CUser *pUser, int floorId);
	// 扫荡奖励
	void SendSweepReward(CUser *pUser, CNetMessage& msg);

	void GetRewardFromCfg(CUser *pUser,map<uint32, uint32> &allRewards);

private:
	void ReadReward(const char* str, towerRewards& rewards);
	void SendReward(CUser *pUser, const towerRewards& rewards, CNetMessage& msg);

private:
	towerReardMap m_firstRewards;		// 首通奖励
	towerReardMap m_normalRewards;		// 普通奖励
};

#define sTowerRewardManager boost::details::pool::singleton_default<TowerRewardManager>::instance()

#endif // _tower_reward_manager_h_

