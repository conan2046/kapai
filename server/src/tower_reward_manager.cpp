#include "tower_reward_manager.h"
#include "user.h"
#include "xml.h"
#include "script_call.h"
#include "utility.h"
#include <string.h>

TowerRewardManager::TowerRewardManager()
{
}

TowerRewardManager::~TowerRewardManager()
{
}

bool TowerRewardManager::Init()
{
	m_firstRewards.clear();
	m_normalRewards.clear();

	//                      0          1               2               3
	const char *keys[] = { "id", "first_reward", "normal_reward", "target_reward"};
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("tongtiantower.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		towerRewards first;
		towerRewards normal;
		int floorId = atoi(data[i][keys[0]].c_str());
		ReadReward(data[i][keys[1]].c_str(), first);
		ReadReward(data[i][keys[2]].c_str(), normal);
		ReadReward(data[i][keys[3]].c_str(), first);
		if (!first.empty())
		{
			m_firstRewards[floorId] = first;
		}
		if (!normal.empty())
		{
			m_normalRewards[floorId] = normal;
		}
	}
	return true;
}

// 首通奖励
void TowerRewardManager::SendFirstReward(CUser *pUser, int floorId)
{
	towerReardMapIt it = m_firstRewards.find(floorId);
	if (it == m_firstRewards.end())
		return;

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TONG_TIAN_TA);
	msg << (uint8)9 << (uint16)floorId;
	SendReward(pUser, it->second, msg);

	char buf[128];
	for (size_t i = 0; i < it->second.size(); ++i)
	{
		const towerSingleReward& reward = it->second[i];
		if (reward.first == HDAT_PET)
		{
			snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0036, pUser->GetName(), floorId, MakePetColorStr(reward.second).c_str());
			SysInfoToAllUser(buf);
			return;
		}
	}
	if (floorId % 10 == 0)
	{
		snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0035, pUser->GetName(), floorId);
		SysInfoToAllUser(buf);
	}
}

// 普通奖励
void TowerRewardManager::SendNormalReward(CUser *pUser, int floorId)
{
	towerReardMapIt it = m_normalRewards.find(floorId);
	if (it == m_normalRewards.end())
		return;

	CNetMessage msg;
	msg.ReWrite();
	msg.SetType(MSG_TONG_TIAN_TA);
	msg << (uint8)11 << (uint16)floorId;
	SendReward(pUser, it->second, msg);
}

// 扫荡奖励
void TowerRewardManager::SendSweepReward(CUser *pUser, CNetMessage& msg)
{
	map<uint32, uint32> allRewards;
	GetRewardFromCfg(pUser,allRewards);
	if(allRewards.empty())
		return;
	
	msg << (uint8)allRewards.size();
	for (map<uint32, uint32>::iterator ait = allRewards.begin(); ait != allRewards.end(); ++ait)
	{
		msg << (uint16)ait->first << ait->second;
		pUser->AddMaterial(ait->first, ait->second);
	}
}

void TowerRewardManager::GetRewardFromCfg(CUser *pUser,map<uint32, uint32> &allRewards)
{
	allRewards.clear();
	if(pUser == NULL)
		return;
	
	int starFloor = pUser->GetExtData16(51);
	int roleTopFloor = pUser->GetExtData16(52);
	for (towerReardMapIt it = m_normalRewards.begin(); it != m_normalRewards.end(); ++it)
	{
		if (it->first < starFloor)
			continue;
		if(it->first > roleTopFloor)
			break;
		towerRewards rewards = it->second;
		for (size_t i = 0; i < rewards.size(); ++i)
		{
			towerSingleReward& reward = rewards[i];
			pair<map<uint32, uint32>::iterator, bool> itb = allRewards.insert(make_pair(reward.first, reward.second));
			if (!itb.second)
			{
				// 插入失败 需要累加
				itb.first->second += reward.second;
			}
		}
	}
}

void TowerRewardManager::ReadReward(const char* str, towerRewards& rewards)
{
	char buf[128];
	char buf1[128];
	char *p[10];
	char *p1[10];
	strncpy(buf, str, sizeof(buf));
	int num = SplitLine(p, buf, ';');
	for (int i = 0; i < num; ++i)
	{
		strncpy(buf1, p[i], sizeof(buf1));
		int mCnt = SplitLine(p1, buf1, '-');
		towerSingleReward reward;
		reward.first = atoi(p1[0]);
		reward.second = atoi(p1[1]);
		if (reward.first == HDAT_PET && mCnt > 3)
		{
			reward.ex1 = atoi(p1[2]);
			reward.ex2 = atoi(p1[3]);
		}
		if (reward.second != 0)
		{
			rewards.push_back(reward);
		}
	}
}

void TowerRewardManager::SendReward(CUser *pUser, const towerRewards& rewards, CNetMessage& msg)
{
	uint8 count = rewards.size();
	msg << count;
	for (size_t i = 0; i < rewards.size(); ++i)
	{
		const towerSingleReward& reward = rewards[i];
		msg << (uint16)reward.first << reward.second;
		if (reward.first == HDAT_PET)
		{
			AddPet(pUser, reward.second, reward.ex2, reward.ex1);
		}
		else
		{
			pUser->AddMaterial(reward.first, reward.second, true);
		}
	}
	SingletonSocket::instance().SendMsg(pUser->GetSock(), msg);
}
