#include "award_manager.h"
#include "utility.h"
#include "user.h"
#include "script_call.h"
#include "singleton.h"
#include "pet_equip_manage.h"
#include <algorithm>
#include <iostream>
#include <math.h>
#include <set>
#include <iosfwd>
#include "rapidjson/document.h"
#include "init.h"

AwardManager::AwardManager()
{

}

bool AwardManager::InitAwardManager()
{
	return LoadAwardXmlConfig()
		&& LoadRewardConfig()
		&& LoadVitalityConfig()
		&& LoadRankAwardConfig()
		&& LoadDropNotic()
		&& LoadOnlineAward();
}

bool AwardManager::LoadAwardXmlConfig()
{
	m_levelRewards.clear();
	const string file = "level_reward.json";
	//                                    0           1         2
	const char* titleArrs[] = { "level_reward_id", "level", "reward" };
	const int typeArrs[] = { 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "AwardManager::LoadAwardXmlConfig >> LoadJosnValue level_reward.json error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		levelReward reward;
		int id = data[titleArrs[0]].GetInt();

		const rapidjson::Value &lvArr = data[titleArrs[1]];
		const rapidjson::Value &awArr = data[titleArrs[2]];


		if (lvArr.Size() != awArr.Size())
			continue;
		for (uint8 i = 0; i < lvArr.Size(); ++i)
		{
			const rapidjson::Value &lv = lvArr[i];
			if (lv.Size() != 2) continue;
			levelInterval level;
			level.first = lv[0].GetInt();
			level.second = lv[1].GetInt();
			reward.levels.push_back(level);
		}
		for (uint8 i = 0; i < awArr.Size(); ++i)
		{
			LvAwardData award;
			const rapidjson::Value &aw = awArr[i];
			if (aw.Size() != 3) continue;
			award.aid = aw[0].GetInt();
			award.isRepeat = aw[1].GetInt() == 1;
			award.num = aw[2].GetInt();
			reward.rewards.push_back(award);
		}
		m_levelRewards.insert(make_pair(id, reward));
	}
	return true;
}

bool AwardManager::LoadRankAwardConfig()
{
	m_rankAwards.clear();
	const string file = "reward_rank.json";
	//                            0       1         2
	const char* titleArrs[] = { "type", "rank", "reward" };
	const int typeArrs[] = { 0, 2, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "AwardManager::LoadRankAwardConfig >> LoadJosnValue level_reward.json error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		typeRankRewards tmp;
		int id = data[titleArrs[0]].GetInt();
		pair<rankRewardMapIt, bool> binsert = m_rankAwards.insert(make_pair(id, tmp));
		typeRankRewards& tRkRwds = binsert.first->second;

		const rapidjson::Value &ranArr = data[titleArrs[1]];
		if (ranArr.Size() != 2)
			continue;
		rankInterval rank;
		MultiAward reward;
		// 等级区间

		rank.first = ranArr[0].GetInt();
		rank.second = ranArr[1].GetInt();
		if(rank.first > rank.second)
		{
			cout<<"AwardManager::LoadRankAwardConfig rank error , rank="<< rank.first <<endl;
			continue;
		}
		// 奖励
		ReadMultiAward(data[titleArrs[2]], reward);
		tRkRwds.ranks.push_back(rank);
		tRkRwds.rewards.push_back(reward);
	}
	return true;
}

bool AwardManager::LoadRewardConfig()
{
	m_weightRewards.clear();
	const string file = "reward.json";
	//                             0            1        2
	const char* titleArrs[] = { "rewardid", "reward", "weight" };
	const int typeArrs[] = { 0, 2, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "AwardManager::LoadRewardConfig >> LoadJosnValue error " << endl;
		return false;
	}

	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		int id = data[titleArrs[0]].GetInt();
		AwardWeight rewardTmp;
		pair<awardWeightMapIt, bool> bInsert = m_weightRewards.insert(make_pair(id, rewardTmp));
		AwardWeight& reward = bInsert.first->second;

		SingleAward saward;
		ReadMultiAward(data[titleArrs[1]], saward.awards);
		saward.weight = data[titleArrs[2]].GetInt();
		reward.weightSum += saward.weight;
		reward.awards.push_back(saward);
	}
	return true;
}

bool AwardManager::LoadVitalityConfig()
{
	m_vitalityAIds.clear();
	//                             0        1
	const char *keys[] = { "activity", "rewardid"};
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("activityreward.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		m_vitalityAIds.insert(make_pair(atoi(data[i][keys[0]].c_str()), atoi(data[i][keys[1]].c_str())));
	}
	return true;
}

bool AwardManager::LoadDropNotic()
{
	m_dropNotics.clear();
	//                      0        1        2
	const char *keys[] = { "id", "item_id", "notice" };
	vector<map<string, string> > data;
	uint16 size = sizeof(keys) / sizeof(keys[0]);
	CXMLReader reader("reward_notice.xml");
	if (!reader.GetAllElements(data, keys, size))
		return false;

	for (uint32 i = 0; i < data.size(); i++)
	{
		DropNotic note;
		int dropId = atoi(data[i][keys[0]].c_str());
		vector<string> splitStr;
		SplitString(data[i][keys[1]], splitStr, ';');
		for (uint8 j = 0; j < splitStr.size(); j++)
		{
			note.itemIds.insert(atoi(splitStr[j].c_str()));
		}
		note.notic = data[i][keys[2]];
		m_dropNotics.insert(make_pair(dropId, note));
	}
	return true;
}

bool AwardManager::LoadOnlineAward()
{
	m_onlineRewardCfg.clear();
	const string file = "online_reward.json";
	//                            0      1        2
	const char* titleArrs[] = { "id", "time", "reward" };
	const int typeArrs[] = { 0, 0, 2 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "AwardManager::LoadOnlineAward >> LoadJosnValue online_reward.json error " << endl;
		return false;
	}
	uint16 lastSec = 0;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		OnlineRewardCfg cfg;
		cfg.id = data[titleArrs[0]].GetInt();
		uint16 curSec = data[titleArrs[1]].GetInt() * 60;
		cfg.sec = curSec - lastSec;
		lastSec = curSec;
		ReadSingleAward(data[titleArrs[2]], cfg.reward);
		m_onlineRewardCfg[cfg.id] = cfg;
	}
	return true;
}


void AwardManager::SendNotic(CUser *pUser, const char* fromStr, uint32 dropId, uint16 type, uint16 val, uint16 ext)
{
	DropNoticMapCIt it = m_dropNotics.find(dropId);
	if (it == m_dropNotics.end())
		return;

	if (it->second.itemIds.find(type) == it->second.itemIds.end())
		return;

	if (type > HDAT_MONEY)
		return;
	char buf[256];
	char notic[512];
	snprintf(buf, sizeof(buf), LANGUAGE_ZQX_0095, GetItemColor(type), GetItemName(type), val);
	snprintf(notic, sizeof(buf), it->second.notic.c_str(), pUser->GetName(), fromStr, buf);
	SysInfoToAllUser(notic);
}

// ---------------------------------------
// 外部调用接口 
void AwardManager::GetLevelAward(uint32 aid, uint32 userlv, std::vector<SAwardData> &awvec, bool clear/* = true*/)
{
	do 
	{
		lvRewardMapIt it = m_levelRewards.find(aid);
		if (it == m_levelRewards.end())
			break;

		levelReward& lvReward = it->second;
		if (lvReward.levels.size() != lvReward.rewards.size())
			break;

		LvAwardData* lvAwardData = NULL;
		for (size_t li = 0; li < lvReward.levels.size(); li++)
		{
			levelInterval& interval = lvReward.levels[li];
			if (userlv >= interval.first && userlv <= interval.second)
			{
				lvAwardData = &lvReward.rewards[li];
				break;
			}
		}

		if (lvAwardData == NULL)
			break;

		GetAwardById(lvAwardData->aid, awvec, lvAwardData->num, lvAwardData->isRepeat, clear);
	} while (false);
}

void AwardManager::GetLevelRandAward(uint32 aid, uint32 userlv, std::vector<SAwardData> &awvec,int num)
{
	awvec.clear();
	if(num < 1)
		return;
	lvRewardMapIt it = m_levelRewards.find(aid);
	if (it == m_levelRewards.end())
		return;
	levelReward& lvReward = it->second;
	if (lvReward.levels.size() != lvReward.rewards.size())
		return;
	
	LvAwardData* lvAwardData = NULL;
	for (size_t li = 0; li < lvReward.levels.size(); li++)
	{
		levelInterval& interval = lvReward.levels[li];
		if (userlv >= interval.first && userlv <= interval.second)
		{
			lvAwardData = &lvReward.rewards[li];
			break;
		}
	}

	if (lvAwardData == NULL)
		return;
	GetAwardById(lvAwardData->aid, awvec, num,true,true,false);
}

int AwardManager::GetRankAward(uint32 type, uint32 rank, std::vector<SAwardData> &awvec)
{
	rankRewardMapIt it = m_rankAwards.find(type);
	if (it == m_rankAwards.end())
		return -1;

	typeRankRewards& rkReward = it->second;
	if (rkReward.ranks.size() != rkReward.rewards.size())
		return -1;

	int idx = 0;
	for (size_t li = 0; li < rkReward.ranks.size(); li++)
	{
		idx++;
		rankInterval& interval = rkReward.ranks[li];
		if (rank >= interval.first && rank <= interval.second)
		{
			awvec = rkReward.rewards[li];
			break;
		}
	}
	return idx;
}

typeRankRewards* AwardManager::GetAllRankAwards(uint32 type)
{
	rankRewardMapIt it = m_rankAwards.find(type);
	if (it == m_rankAwards.end())
		return NULL;

	return &it->second;
}

OnlineRewardCfg* AwardManager::GetOnlineRewardCfg(uint8 idx)
{
	OnlineRewardCfgMapIt it = m_onlineRewardCfg.find(idx);
	if (it == m_onlineRewardCfg.end())
		return NULL;

	return &it->second;
}


void AwardManager::XiPai(uint32 baseNum, uint32 num, std::vector<uint32>& seqs)
{
	// 如果要轮2.5圈 先 取2圈
	for (uint32 i = 0; i < num / baseNum; ++i)
	{
		for (uint32 i = 0; i < baseNum; ++i)
		{
			seqs.push_back(i);
		}
	}

	// 再取不重复的0.5圈
	uint32 otherNeed = num - seqs.size();
	if (otherNeed > 0)
	{
		std::vector<uint32> tmp;
		for (uint32 i = 0; i < baseNum; ++i)
		{
			tmp.push_back(i);
		}

		for (uint32 i = 0; i < otherNeed; ++i)
		{
			uint32 idx = Random(i, baseNum - 1);
			if (idx != i)
			{
				uint32 swapIdx = tmp[idx];
				tmp[idx] = tmp[i];
				tmp[i] = swapIdx;
			}
			seqs.push_back(tmp[i]);
		}
	}

	for (uint32 i = 0; i < num; ++i)
	{
		uint32 idx = Random(i, num - 1);
		if (idx == i) continue;
		uint32 swapIdx = seqs[idx];
		seqs[idx] = seqs[i];
		seqs[i] = swapIdx;
	}
}

// 获取转盘数据
int AwardManager::GetAwardPanal(uint32 aid, uint32 userlv, uint32 num, std::vector<SAwardData> &awvec)
{
	do 
	{
		lvRewardMapIt it = m_levelRewards.find(aid);
		if (it == m_levelRewards.end())
			break;

		levelReward& lvReward = it->second;
		if (lvReward.levels.size() != lvReward.rewards.size())
			break;

		LvAwardData* lvAwardData = NULL;
		for (size_t li = 0; li < lvReward.levels.size(); li++)
		{
			levelInterval& interval = lvReward.levels[li];
			if (userlv >= interval.first && userlv <= interval.second)
			{
				lvAwardData = &lvReward.rewards[li];
				break;
			}
		}

		if (lvAwardData == NULL)
			break;

		awardWeightMapIt wIt = m_weightRewards.find(lvAwardData->aid);
		if (wIt == m_weightRewards.end())
			break;

		AwardWeight& aweight = wIt->second;
		int tarWeight = Random(0, aweight.weightSum);
		int curWeight = 0;
		std::vector<SAwardData> randPool;
		SAwardData realAward;
		bool isGet = false;
		for (size_t wi = 0; wi < aweight.awards.size(); ++wi)
		{
			SingleAward& saward = aweight.awards[wi];
			if (saward.awards.empty())
			{
				continue;
			}

			curWeight += saward.weight;
			if (!isGet && curWeight >= tarWeight)
			{
				realAward = saward.awards[0];
				isGet = true;
			}
			else
			{
				randPool.push_back(saward.awards[0]);
			}
		}

		std::vector<uint32> seqs;
		XiPai(randPool.size(), num - 1, seqs);
		int iIdx = Random(0, seqs.size() - 1);
		seqs.insert(seqs.begin() + iIdx, -1);

		for (size_t i = 0; i < seqs.size(); ++i)
		{
			if (seqs[i] == (uint32)-1)
			{
				awvec.push_back(realAward);
			}
			else
			{
				awvec.push_back(aweight.awards[seqs[i]].awards[0]);
			}
		}
		return iIdx;
	} while (false);
	return 0;
}

// ---------------------------------------
// 发送奖励并拼接消息
void AwardManager::MakeAwardMsgAndSendAward(CUser* pUser, uint32 sceneId, CNetMessage& msg)
{
	std::vector<SAwardData> awvec;
	int aid = pUser->GetFBDorpId(sceneId);
	GetLevelAward(aid, pUser->GetLevel(), awvec);
	// msg << (uint8)awvec.size();
	// for (size_t i = 0; i < awvec.size(); ++i)
	// {
		// msg << (uint16)awvec[i].type << (uint32)awvec[i].num;
		// pUser->AddMaterial(awvec[i].type, awvec[i].num, true, true, awvec[i].petStar);
	// }
	::SendAndMakeAwardMsg(pUser, awvec, msg);
}

void AwardManager::SendAndMakeAwardMsg(CUser *pUser, uint16 aid, CNetMessage& msg, bool showMsg/* = false*/, uint16 addType/* = 0*/)
{
	std::vector<SAwardData> awvec;
	if (GetAwardById(aid, awvec))
	{
		::SendAndMakeAwardMsg(pUser, awvec, msg, showMsg, addType);
	}
}


void AwardManager::ActivityMakeAwardMsgAndSendAward(CUser* pUser, uint32 activityId, CNetMessage& msg, int type/* = 1*/)
{
	int aid = sCDropMatchingMgr.GetActivityDropId(activityId, type);
	SendLevelAward(pUser, aid, &msg);
}

void AwardManager::GetActivityDrop(CUser* pUser, uint32 activityId, int type, std::vector<SAwardData> &awvec)
{
	int aid = sCDropMatchingMgr.GetActivityDropId(activityId, type);
	GetLevelAward(aid, pUser->GetLevel(), awvec);
}


// ---------------------------------------
// 通过奖励id获取奖励
bool AwardManager::GetAwardById(uint32 aid, std::vector<SAwardData> &awvec, int num/* = 1*/, bool isRepeat/* = true*/, bool clear/* = true*/, bool isMerge)
{
	if (clear)
		awvec.clear();
	vector<SAwardData> award;
	awardWeightMapIt wIt = m_weightRewards.find(aid);
	if (wIt == m_weightRewards.end())
		return false;

	AwardWeight& aweight = wIt->second;
	int size = aweight.awards.size();
	if(num > size)
		return false;
	set<int> repeat;
	int errorNum = 0;
	for (int di = 0; di < num;)
	{
		bool isFind = false;
		int tarWeight = Random(0, aweight.weightSum);
		int curWeight = 0;
		for (int wi = 0; wi < size; ++wi)
		{
			SingleAward& saward = aweight.awards[wi];
			curWeight += saward.weight;

			if (curWeight >= tarWeight)
			{
				if (!isRepeat || (isRepeat && repeat.insert(wi).second))
				{
					if(isMerge)
						MergeAwardList(award, saward.awards);
					else
					{
						if(!saward.awards.empty())
							award.push_back(saward.awards[0]);
					}
					isFind = true;
					++di;
				}
				break;
			}
		}
		if(!isFind)
			errorNum++;
		if(errorNum >= 200)
			return false;
	}
	if(isMerge)
		MergeAwardList(awvec, award);
	else
		awvec.assign(award.begin(),award.end());
	return true;
}

// ---------------------------------------
// 通过活跃度获取奖励数据
void AwardManager::SendVitalityAward(CUser *pUser, uint32 vitality, CNetMessage* msg/* = NULL*/)
{
	vitalityAIdMapIt it = m_vitalityAIds.find(vitality);
	if (it == m_vitalityAIds.end())
	{
		return;
	}
	std::vector<SAwardData> award;
	GetAwardById(it->second, award);
	if (msg != NULL)
		*msg << (uint8)award.size();
	for (uint16 i = 0; i < award.size(); ++i)
	{
		if (msg != NULL)
			*msg << (uint32)award[i].type << (uint32)award[i].num;

		pUser->AddMaterial(award[i], true, true);
	}
}

void AwardManager::SendLevelAward(CUser *pUser, int aid, CNetMessage* msg/* = NULL*/)
{
	std::vector<SAwardData> award;
	GetLevelAward(aid, pUser->GetLevel(), award);
	if (msg != NULL)
		*msg << (uint8)award.size();
	for (uint16 i = 0; i < award.size(); ++i)
	{
		if(msg != NULL)
			MakeAwardMsg(award[i], *msg);
		pUser->AddMaterial(award[i], true, true);
	}
}

void AwardManager::SendRankAward(CUser *pUser, uint32 type, uint32 rank, CNetMessage* msg/* = NULL*/)
{
	std::vector<SAwardData> award;
	GetRankAward(type, rank, award);
	if (msg != NULL)
		*msg << (uint8)award.size();
	for (uint16 i = 0; i < award.size(); ++i)
	{
		if (msg != NULL)
			MakeAwardMsg(award[i], *msg);
		pUser->AddMaterial(award[i], true, true);
	}
}

void AwardManager::SendRankAwardMail(uint32 type, uint32 roleId, uint32 rank, const char* buf)
{
	stringstream str;
	str << buf;
	SMailData mdata;
	GetRankAward(type, rank, mdata.awards);
	SendSystemMail(roleId, str.str().c_str(), &mdata);
}

void AwardManager::SendRankAwardMailExHb(uint32 type, uint32 roleId, uint32 rank, const char* buf, SAwardData award)
{
	stringstream str;
	str << buf;
	SMailData mail;
	GetRankAward(type, rank, mail.awards);
	MergeAwardData(mail.awards, award);
	SendSystemMail(roleId, str.str().c_str(), &mail);
}

CDropMatchingMgr::CDropMatchingMgr()
{
}

CDropMatchingMgr::~CDropMatchingMgr()
{
	m_insDropIds.clear();
	m_activityDorpIds.clear();
	m_itemDorpIds.clear();
}

bool CDropMatchingMgr::Init()
{
	m_insDropIds.clear();
	m_activityDorpIds.clear();
	m_itemDorpIds.clear();

	const string file = "drop_matching.json";
	//                            0      1        2             3
	const char* titleArrs[] = { "type", "id", "sub_type", "level_reward_id" };
	const int typeArrs[] = { 0, 0, 0, 0 };  // 0-int 1-string 2-array
	rapidjson::Document d;
	rapidjson::Value _para;
	if (!LoadJosnValue(file, titleArrs, typeArrs, sizeof(typeArrs) / sizeof(int), d, _para))
	{
		cout << "CDropMatchingMgr::Init >> LoadJosnValue drop_matching.json error " << endl;
		return false;
	}

	int type = 0;
	int id = 0;
	int stype = 0;
	int rid = 0;
	for (uint32 i = 0; i < _para.Size(); i++)
	{
		const rapidjson::Value &data = _para[i];
		type = data[titleArrs[0]].GetInt();
		id = data[titleArrs[1]].GetInt();
		stype = data[titleArrs[2]].GetInt();
		rid = data[titleArrs[3]].GetInt();
		switch (type)
		{
		case 1:
			AddInstanceDrop(id, stype, rid);
			break;

		case 2:
			AddActivtiyDrop(id, stype, rid);
			break;

		case 3:
			AddItemDrop(id, stype, rid);
			break;
		}
	}
	return true;
}

void CDropMatchingMgr::AddInstanceDrop(int id, int stype, int rid)
{
	DorpIds drops;
	std::pair<InsDropIdsIt, bool> bit = m_insDropIds.insert(make_pair(id, drops));
	bit.first->second.insert(make_pair(stype, rid));
}

void CDropMatchingMgr::AddActivtiyDrop(int id, int stype, int rid)
{
	DorpIds drops;
	std::pair<InsDropIdsIt, bool> bit = m_activityDorpIds.insert(make_pair(id, drops));
	bit.first->second.insert(make_pair(stype, rid));
}

void CDropMatchingMgr::AddItemDrop(int id, int stype, int rid)
{
	DorpIds drops;
	std::pair<InsDropIdsIt, bool> bit = m_itemDorpIds.insert(make_pair(id, drops));
	bit.first->second.insert(make_pair(stype, rid));
}

int CDropMatchingMgr::GetInstanceDropId(int insId, int type)
{
	int dropId = 0;
	do 
	{
		InsDropIdsIt it = m_insDropIds.find(insId);
		if (it == m_insDropIds.end())
		{
			break;
		}

		DorpIdsIt tIt = it->second.find(type);
		if (tIt == it->second.end())
		{
			break;
		}
		dropId = tIt->second;
	} while (false);
	return dropId;
}

int CDropMatchingMgr::GetActivityDropId(int actId, int type/* = 1*/)
{
	int dropId = 0;
	do
	{
		InsDropIdsIt it = m_activityDorpIds.find(actId);
		if (it == m_activityDorpIds.end())
		{
			break;
		}

		DorpIdsIt tIt = it->second.find(type);
		if (tIt == it->second.end())
		{
			break;
		}
		dropId = tIt->second;
	} while (false);
	return dropId;
}

int CDropMatchingMgr::GetItemDropId(int itemId, int type/* = 1*/)
{
	int dropId = 0;
	do
	{
		InsDropIdsIt it = m_itemDorpIds.find(itemId);
		if (it == m_itemDorpIds.end())
		{
			break;
		}

		DorpIdsIt tIt = it->second.find(type);
		if (tIt == it->second.end())
		{
			break;
		}
		dropId = tIt->second;
	} while (false);
	return dropId;
}


