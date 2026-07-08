#ifndef __FROG_20190125_MATCH_MANAGER_H__
#define __FROG_20190125_MATCH_MANAGER_H__

#include <set>
#include <vector>
#include <map>
#include "self_typedef.h"

using namespace std;

struct aFight
{
	uint32 id;
	int fight;

	bool operator>(const aFight& other) const
	{
		return fight > other.fight;
	}

	bool operator<(const aFight& other) const
	{
		return fight < other.fight;
	}

	bool operator>=(const aFight& other) const
	{
		return fight >= other.fight;
	}

	bool operator<=(const aFight& other) const
	{
		return fight <= other.fight;
	}
};

class MatchManage
{
public:
	MatchManage()
	{

	}

	~MatchManage()
	{

	}

public:
	bool Init();
	void UpdatePower(uint32 id, int power);
	void AddUpdatePower(uint32 id, int power);
	int FindIdx(uint32 id);
	void FindIds(uint32 id, uint32 basePower, CNetMessage &msg);
	void FindIds(uint32 id, uint32 basePower, uint8 cnt, CNetMessage &msg);
	void FindIds(uint32 id, uint32 startPower, uint32 endPower, uint8 cnt, CNetMessage &msg);
	int FindPowerIdx(int power);
	void FindSingleId(uint32 id, uint32 findPower, CNetMessage &msg);
private:
	// 检查是否需要排序
	void CheckSort();

private:
	vector<aFight> ids; // 排序过的战力
	map<uint32, int> idxs; // 当前战力
	map<uint32, int> m_updatePowers; // 需要更新的列表
};

#endif
