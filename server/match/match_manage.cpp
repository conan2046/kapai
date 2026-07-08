#include "match_manage.h"
#include <iostream>
#include "utility.h"

extern char *gConfigFile;

void MatchManage::CheckSort()
{
	if (m_updatePowers.empty())
		return;

	for (map<uint32, int>::iterator it = m_updatePowers.begin(); it != m_updatePowers.end(); ++it)
	{
		UpdatePower(it->first, it->second);
	}
	m_updatePowers.clear();
}

bool MatchManage::Init()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	int idx = 0;
	int queryRow = 100;
	char **row = NULL;
	bool isBreak = false;
	set<aFight> sortPowers;
	while (!isBreak)
	{
		char sql[256];
		snprintf(sql, sizeof(sql), "select id, zhanDouLi from role_info where model > 0 order by id limit %d, %d", idx++ * queryRow, queryRow);
		if (!pDb->Query(sql))
		{
			cout << "Error:GetHelpTitleList." << endl;
			return false;
		}

		if (pDb->GetRowNum() == 0)
		{
			break;
		}

		for (int i = 0; i < queryRow; ++i)
		{
			if ((row = pDb->GetRow()) == NULL)
			{
				isBreak = true;
				break;
			}
			aFight power;
			power.id = (uint32)atoi(row[0]);
			power.fight = (uint32)atoi(row[1]);
			sortPowers.insert(power);
		}
	}

	for (set<aFight>::iterator sIt = sortPowers.begin(); sIt != sortPowers.end(); ++sIt)
	{
		ids.insert(ids.begin(), *sIt);
		idxs[sIt->id] = sIt->fight;
	}

	for (size_t xi = 0; xi < ids.size(); ++xi)
	{
		//cout << "user id 1" << ids[xi].id << " power " << ids[xi].fight << endl;
	}
	return true;
}

int MatchManage::FindIdx(uint32 id)
{
	map<uint32, int>::iterator it = idxs.find(id);
	if (it == idxs.end())
	{
		return -1;
	}
	int findPower = it->second;
	int top = 0;
	int end = ids.size() - 1;
	for (;;)
	{
		int idx = (top + end) / 2;
		aFight& cur = ids[idx];
		if (cur.fight > findPower)
		{
			top = idx;
		}
		else if (cur.fight < findPower)
		{
			end = idx;
		}
		else
		{
			return idx;
		}

		if (end - top <= 1)
		{
			if (ids[top].id == id)
			{
				return top;
			}
			else if (ids[end].id == id)
			{
				return end;
			}
			else
			{
				printf("error !!! role %d is not found!!!\n", id);
				return idx;
			}
		}
	}
}

void MatchManage::FindIds(uint32 id, uint32 basePower, CNetMessage &msg)
{
	CheckSort();
	vector<float> ratios;
	int percent = 0;
	msg >> percent;
	float baseRatio = percent / 100.0;
	for (int i = 0; i < 8; ++i)
	{
		ratios.push_back(baseRatio + i * 0.05);
	}

	set<uint32> matchIdxs;
	int maxIdx = ids.size();
	for (size_t vi = 0; vi < ratios.size(); ++vi)
	{
		int findPower = basePower * ratios[vi];
		int findIdx = FindPowerIdx(findPower);
		// 波动
		int rd = Random(0, 9);
		findIdx += rd;
		while (true)
		{
			if (findIdx < maxIdx && ids[findIdx].id == id)
			{
				findIdx++;
			}
			pair<set<uint32>::iterator, bool> in = matchIdxs.insert(findIdx++);
			if (in.second)
				break;
		}
	}
	msg << (uint8)matchIdxs.size();
	//printf("role %u match chuang guan result :\n", id);
	for (set<uint32>::iterator mIt = matchIdxs.begin(); mIt != matchIdxs.end(); ++mIt)
	{
		uint32 idx = *mIt;
		if (idx > ids.size())
		{
			msg << (uint32)0; // 0 补充机器人
		}
		else
		{
			msg << ids[idx].id;
		}
	}
	return;
}

void MatchManage::FindIds(uint32 id, uint32 basePower, uint8 cnt, CNetMessage &msg)
{
	CheckSort();
	set<uint32> matchIdxs;
	int maxIdx = ids.size();
	for (size_t vi = 0; vi < cnt; ++vi)
	{
		int findPower = basePower;
		int findIdx = FindPowerIdx(findPower);
		// 波动
		int rd = Random(0, 9);
		findIdx += rd;
		while (true)
		{
			if (findIdx < maxIdx && ids[findIdx].id == id)
			{
				findIdx++;
			}
			pair<set<uint32>::iterator, bool> in = matchIdxs.insert(findIdx++);
			if (in.second)
				break;
		}
	}
	msg << (uint8)matchIdxs.size();
	//printf("role %u match chuang guan result :\n", id);
	for (set<uint32>::iterator mIt = matchIdxs.begin(); mIt != matchIdxs.end(); ++mIt)
	{
		uint32 idx = *mIt;
		if (idx > ids.size())
		{
			msg << (uint32)0; // 0 补充机器人
		}
		else
		{
			msg << ids[idx].id;
		}
	}
	return;
}

void MatchManage::FindIds(uint32 id, uint32 startPower, uint32 endPower, uint8 cnt, CNetMessage &msg)
{
	CheckSort();
	int startIdx = FindPowerIdx(startPower);
	int endIdx = FindPowerIdx(endPower);
	set<uint32> matchIdxs;
	if (endIdx - startIdx > cnt)
	{
		while (matchIdxs.size() < cnt)
		{
			int rd = Random(startIdx, endIdx);
			if (ids[rd].id == id)
				continue;
			pair<set<uint32>::iterator, bool> in = matchIdxs.insert(rd);
			if (in.second)
				continue;
		}
	}
	else
	{
		for (int i = startIdx; i < endIdx; i++)
		{
			if (ids[i].id == id)
				continue;
			pair<set<uint32>::iterator, bool> in = matchIdxs.insert(i);
			if (in.second)
				continue;
		}
		int maxIdx = ids.size();
		while (matchIdxs.size() < cnt)
		{
			endIdx++;
			if (endIdx < maxIdx && ids[endIdx].id == id)
				continue;
			matchIdxs.insert(endIdx);
		}
	}
	msg << (uint8)matchIdxs.size();
	for (set<uint32>::iterator mIt = matchIdxs.begin(); mIt != matchIdxs.end(); ++mIt)
	{
		uint32 idx = *mIt;
		if (idx > ids.size())
		{
			msg << (uint32)0; // 0 补充机器人
		}
		else
		{
			msg << ids[idx].id;
		}
	}

}

int MatchManage::FindPowerIdx(int power)
{
	if (ids.empty())
	{
		return 0;
	}
	int top = 0;
	int end = ids.size() - 1;
	int findIdx = -1;
	for (;;)
	{
		int idx = (top + end) / 2;
		aFight& cur = ids[idx];
		if (cur.fight > power)
		{
			top = idx;
		}
		else if (cur.fight < power)
		{
			end = idx;
		}
		else if (cur.fight == power)
		{
			findIdx = idx + 1;
			break;
		}
		
		if (end - top <= 1)
		{
			if (ids[end].fight >= power)
			{
				findIdx = end + 1;
			}
			else if (ids[top].fight < power)
			{
				findIdx = top;
			}
			else
			{
				findIdx = top + 1;
			}
			break;
		}
	}
	return findIdx;
}


void MatchManage::UpdatePower(uint32 id, int power)
{
	map<uint32, int>::iterator it = idxs.find(id);
//	int findPower = power;
	int oldIdx = -1;
	if (it != idxs.end())
	{
//		findPower = it->second;
		oldIdx = FindIdx(id);
	}

	int changePos = FindPowerIdx(power);
	if (changePos == oldIdx)
	{
		return;
	}

	aFight fight;
	fight.id = id;
	fight.fight = power;
	if (oldIdx != -1)
	{
		ids.erase(ids.begin() + oldIdx);
		if (oldIdx < changePos) // 在后面更新
		{
			changePos--;
		}
	}
	ids.insert(ids.begin() + changePos, fight);
	idxs[id] = power;
}

void MatchManage::AddUpdatePower(uint32 id, int power)
{
	m_updatePowers[id] = power;
}

void MatchManage::FindSingleId(uint32 id, uint32 findPower, CNetMessage &msg)
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return;

	uint32 findIdx = FindPowerIdx(findPower);
	char sql[256];
	bool hasSql = false;
	char **row = NULL;
	if (ids[findIdx].id == id)
	{
		findIdx++;
	}

	snprintf(sql, sizeof(sql), "select name, level, model, sex from role_info where id = %u", ids[findIdx].id);
	do
	{
		if (findIdx > ids.size())
		{
			break;
		}
		if (!pDb->Query(sql))
		{
			cout << "Error:GetHelpTitleList." << endl;
			break;
		}

		if (pDb->GetRowNum() == 0)
		{
			break;
		}

		if ((row = pDb->GetRow()) == NULL)
		{
			break;
		}
		hasSql = true;
		msg << ids[findIdx].id << ids[findIdx].fight << row[0] << (uint16)atoi(row[1]) << (uint8)atoi(row[2]) << (uint8)atoi(row[3]) << "";
		cout << "role [" << id  << "] match power [" << findPower << "] match ying yong shi lian, result : name [" << row[0] << "] id is [" << ids[findIdx].id << "] power is [" << ids[findIdx].fight << "]" << endl;
	} while (false);

	if (!hasSql)
	{
		//printf("role %u match ying yong shi lian faild ! push robot!\n", id);
		msg << (uint32)0; // 0 数据库查询失败 补充机器人
	}
}
