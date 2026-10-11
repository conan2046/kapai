#include "friend.h"
#include "role_simple_mgr.h"
#include "init.h"

using namespace std;
typedef map<uint32, SFriendData> _friendData;
typedef map<uint32, SFriendData>::iterator _friendDataIt;
typedef map<uint32, SFriendInfo> _friendMap;
typedef map<uint32, SFriendInfo>::iterator _friendMapIt;

CFriendMgr::CFriendMgr()
{
	m_friendList.clear();
}

CFriendMgr::~CFriendMgr()
{

}

bool CFriendMgr::Init()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
		return false;

	char sql[512];
	int page = 0;
	const int PER_NUM = 500;
	int num = 0;
	do
	{
		snprintf(sql, sizeof(sql), "select role_id,friend_info,apply_list,black_list from friend_list limit %d,%d", page*PER_NUM, PER_NUM);
		if(!pDb->Query(sql))
			break;
		char **row = NULL;
		page++;
		num = pDb->GetRowNum();
		while((row = pDb->GetRow()) != NULL)
		{
			uint32 roleId = atoi(row[0]);
			SFriendInfo tmp;
			ReadFriendInfo(row[1], tmp.friendList);
			ReadApplyList(row[2], tmp.applyList);
			ReadBlackList(row[3], tmp.blackList);
			m_friendList.insert(make_pair(roleId, tmp));
		}
	}while(num == PER_NUM);

	return true;
}

void CFriendMgr::Save()
{
	CGetDbConnect getDb;
	CDatabaseSql *pDb = getDb.GetDbConnect();
	if(pDb == NULL)
	{
		cout<<"CFriendMgr::Save() error"<<endl;
		return;
	}
	pDb->Query("truncate friend_list_save");

	{
		const uint32 size = 1024*10;
		uint8 *buf = new uint8[size];
		boost::scoped_array<uint8> autoDel(buf);
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(_friendMapIt it = m_friendList.begin(); it != m_friendList.end(); it++)
		{
			uint32 roleId = it->first;
			SFriendInfo &info = it->second;
			string infoStr, applyStr, blackStr;
			GetFriendInfoStr(infoStr, info.friendList);
			GetApplyListStr(applyStr, info.applyList);
			GetBlackListStr(blackStr, info.blackList);
			snprintf((char *)buf, size, "insert into friend_list_save (role_id,friend_info,apply_list,black_list) values(%d,'%s','%s','%s')", 
				roleId, infoStr.c_str(), applyStr.c_str(), blackStr.c_str());
			pDb->Query((char *)buf);
		}
	}

	pDb->Query("truncate friend_list");
	pDb->Query("insert into friend_list select * from friend_list_save");
}

void CFriendMgr::Timer()
{
	static bool clearFlag = true;
	int hour = GetHour();
	if(hour == 0 && GetMinute() < 5)
	{
		if(!clearFlag)
			return;
		clearFlag = false;
		
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(_friendMapIt it = m_friendList.begin(); it != m_friendList.end(); it++)
		{
			SFriendInfo &info = it->second;
			for(_friendDataIt dataIt = info.friendList.begin(); dataIt != info.friendList.end(); dataIt++)
			{
				SFriendData &data = dataIt->second;
				data.award = 0;
				data.getFlag = 0;
				data.sendFlag = 0;
			}
		}
	}
	else if(hour == 1 && !clearFlag)
	{
		clearFlag = true;
	}
}

void CFriendMgr::GetFriendList(CNetMessage &msg, uint32 roleId)
{
	msg<<(uint8)MAX_FriendNum;
	uint32 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt it = m_friendList.find(roleId);
	if(it != m_friendList.end())
	{
		SFriendInfo &info = it->second;
		uint32 curTime = GetSysTime();
		for(_friendDataIt i = info.friendList.begin(); i != info.friendList.end(); i++)
		{
			uint32 roleId = i->first;
			SRoleSimpleData data;
			if(!simpleMgr.GetRoleData(roleId, data))
				continue;
			uint32 offLineTime = (data.lastLoginTime == 0) ? 0 : (curTime < data.lastLoginTime ? 0 : (curTime - data.lastLoginTime));
			msg<<data.roleId<<data.name<<data.level<<data.sex<<data.head<<data.power<<offLineTime;
			msg<<data.bangpaiId<<data.bpName;
			msg<<i->second.value;
			msg<<i->second.sendFlag;
			num++;
		}
		msg.WriteData(pos, &num, sizeof(num));
	}
	else
	{
		m_friendList.insert(make_pair(roleId, SFriendInfo()));
	}
}

void CFriendMgr::GetFriendIDList(uint32 roleId, vector<uint32> &vec)
{
	if(roleId == 0)
		return;
	vec.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt it = m_friendList.find(roleId);
	if(it == m_friendList.end())
		return;
	SFriendInfo &info = it->second;
	for(_friendDataIt i = info.friendList.begin(); i != info.friendList.end(); i++)
	{
		uint32 roleId = i->first;
		vec.push_back(roleId);
	}
}

void CFriendMgr::GetFriendAndBlackIDList(uint32 roleId, vector<uint32> &vec)
{
	if(roleId == 0)
		return;
	vec.clear();
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt it = m_friendList.find(roleId);
	if(it == m_friendList.end())
		return;
	SFriendInfo &info = it->second;
	for(_friendDataIt i = info.friendList.begin(); i != info.friendList.end(); i++)
	{
		uint32 roleId = i->first;
		vec.push_back(roleId);
	}
	for(map<uint32, uint8>::iterator it = info.blackList.begin(); it != info.blackList.end(); it++)
	{
		uint32 roleId = it->first;
		vec.push_back(roleId);
	}
}

void CFriendMgr::GetAddApplyList(CNetMessage &msg, uint32 roleId)
{
	msg<<(uint8)MAX_ApplyNum;
	uint32 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt it = m_friendList.find(roleId);
	if(it == m_friendList.end())
		return;
	
	SFriendInfo &selfInfo = it->second;
	uint32 curTime = GetSysTime();
	for(list<uint32>::iterator i = selfInfo.applyList.begin(); i != selfInfo.applyList.end(); i++)
	{
		uint32 roleId = *i;
		SRoleSimpleData data;
		if(!simpleMgr.GetRoleData(roleId, data))
			continue;
		uint32 offLineTime = (data.lastLoginTime == 0) ? 0 : (curTime < data.lastLoginTime ? 0 : (curTime - data.lastLoginTime));
		msg<<data.roleId<<data.name<<data.level<<data.sex<<data.head<<data.power<<offLineTime;
		msg<<data.bangpaiId<<data.bpName;
		num++;
	}
	msg.WriteData(pos, &num, sizeof(num));
}

void CFriendMgr::ApplyAddFriend(CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}
	if(selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0553, TIPS_FAILURE_COLOR);
		return;
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		// 好友检测
		_friendMapIt selfFit = m_friendList.find(selfId);
		if(selfFit == m_friendList.end())
		{
			pair<_friendMapIt, bool> res = m_friendList.insert(make_pair(selfId, SFriendInfo()));
			if(!res.second)
				return;
			selfFit = res.first;
		}
		SFriendInfo &info = selfFit->second;
		_friendDataIt fdit = info.friendList.find(roleId);
		if(fdit != info.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0556, TIPS_FAILURE_COLOR);
			return;
		}
		if(info.friendList.size() >= MAX_FriendNum)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0554, TIPS_FAILURE_COLOR);
			return;
		}

		// 检测自己的申请列表,如果在申请列表中则直接添加好友
		list<uint32>::iterator selfAppIt = std::find(info.applyList.begin(), info.applyList.end(), roleId);
		if(selfAppIt != info.applyList.end())	// 对方已申请,直接加好友
		{
			NolockDealFriendAddApply(msg, selfId, roleId, true);
			return;
		}

		// 对方申请列表检测
		_friendMapIt roleFit = m_friendList.find(roleId);
		if(roleFit == m_friendList.end())
		{
			pair<_friendMapIt, bool> res = m_friendList.insert(make_pair(roleId, SFriendInfo()));
			if(!res.second)
				return;
			roleFit = res.first;
		}
		SFriendInfo &otherInfo = roleFit->second;
		_friendDataIt roleFdit = otherInfo.friendList.find(selfId);
		if(roleFdit != otherInfo.friendList.end())	// 对方有好友,直接加好友
		{
			NolockDealFriendAddApply(msg, selfId, roleId, true);
			return;
		}
		if(std::find(otherInfo.applyList.begin(), otherInfo.applyList.end(), selfId) != otherInfo.applyList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0555, TIPS_FAILURE_COLOR);
			return;
		}
		otherInfo.applyList.push_front(selfId);
		if(otherInfo.applyList.size() > MAX_ApplyNum)
			otherInfo.applyList.pop_back();
	}
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0557, TIPS_FAILURE_COLOR);

	CheckHotPoint(EHPoint_Fri_RecvApply, roleId);
}

void CFriendMgr::DealFriendAddApply(CNetMessage &msg, uint32 selfId, uint32 roleId, bool accept)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NolockDealFriendAddApply(msg, selfId, roleId, accept);
}

void CFriendMgr::NolockDealFriendAddApply(CNetMessage &msg, uint32 selfId, uint32 roleId, bool accept)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	// 申请列表检测
	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}
	SFriendInfo &selfInfo = selfIt->second;
	list<uint32>::iterator selfAppIt = std::find(selfInfo.applyList.begin(), selfInfo.applyList.end(), roleId);
	if(selfAppIt == selfInfo.applyList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0558, TIPS_FAILURE_COLOR);
		return;
	}

	if(accept)
	{
		// 自己好友检测
		_friendDataIt selfFdit = selfInfo.friendList.find(roleId);
		if(selfFdit != selfInfo.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0556, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}
		if(selfInfo.friendList.size() >= MAX_FriendNum)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0554, TIPS_FAILURE_COLOR);
			return;
		}
		if(selfInfo.blackList.find(roleId) != selfInfo.blackList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0580, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}
		
		// 对方好友检测
		_friendMapIt roleIt = m_friendList.find(roleId);
		if(roleIt == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}
		SFriendInfo &roleInfo = roleIt->second;
		_friendDataIt roleFdit = roleInfo.friendList.find(selfId);
		if(roleFdit != roleInfo.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0556, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}
		if(roleInfo.friendList.size() >= MAX_FriendNum)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0570, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}
		// 黑名单
		if(roleInfo.blackList.find(selfId) != roleInfo.blackList.end())
		{
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0581, TIPS_FAILURE_COLOR);
			selfInfo.applyList.erase(selfAppIt);
			return;
		}

		selfInfo.friendList.insert(make_pair(roleId, SFriendData()));
		roleInfo.friendList.insert(make_pair(selfId, SFriendData()));
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0559, TIPS_SUCCESS_COLOR);

		NoticeFriendListChanged(roleId);
	}
	else	// 拒绝
	{
		msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0582, TIPS_SUCCESS_COLOR);
	}

	// 删除请求列表
	selfInfo.applyList.erase(selfAppIt);
}

void CFriendMgr::DealAllApply(CNetMessage &msg, uint32 selfId, bool accept)
{
	vector<uint32> delApplyList;
	vector<uint32> addRoleList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt selfIt = m_friendList.find(selfId);
		if(selfIt == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
			return;
		}
		
		SFriendInfo &selfInfo = selfIt->second;
		if(accept)
		{
			// 自己好友检测
			if(selfInfo.friendList.size() >= MAX_FriendNum)
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0554, TIPS_FAILURE_COLOR);
				return;
			}
			if(selfInfo.applyList.empty())
			{
				msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0573, TIPS_FAILURE_COLOR);
				return;
			}
			
			int canAddNum = MAX_FriendNum - selfInfo.friendList.size();
			for(list<uint32>::iterator appIt = selfInfo.applyList.begin(); appIt != selfInfo.applyList.end(); )
			{
				if(canAddNum == 0)
					break;
				uint32 roleId = *appIt;
				do
				{
					if(selfInfo.blackList.find(roleId) != selfInfo.blackList.end())
						break;
					
					// 对方好友检测
					_friendMapIt roleIt = m_friendList.find(roleId);
					if(roleIt == m_friendList.end())
						break;
					
					SFriendInfo &roleInfo = roleIt->second;
					_friendDataIt roleFdit = roleInfo.friendList.find(selfId);
					if(roleFdit != roleInfo.friendList.end())
						break;
					if(roleInfo.friendList.size() >= MAX_FriendNum)
						break;
					if(roleInfo.blackList.find(selfId) != roleInfo.blackList.end())
						break;

					// 添加
					selfInfo.friendList.insert(make_pair(roleId, SFriendData()));
					roleInfo.friendList.insert(make_pair(selfId, SFriendData()));
					canAddNum--;
					NoticeFriendListChanged(roleId);
					addRoleList.push_back(roleId);
				}while(0);

				delApplyList.push_back(roleId);
				// 删除请求列表
				list<uint32>::iterator delIt = appIt;
				appIt++;
				selfInfo.applyList.erase(delIt);
			}
		}
		else	// 拒绝所有加好友申请
		{
			msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0582, TIPS_SUCCESS_COLOR);
			msg<<(uint8)selfInfo.applyList.size();
			for(list<uint32>::iterator i = selfInfo.applyList.begin(); i != selfInfo.applyList.end(); i++)
				msg<<*i;
			selfInfo.applyList.clear();
			return;
		}
	}

	if(addRoleList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0585, TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0559, TIPS_SUCCESS_COLOR);
	msg<<(uint8)delApplyList.size();
	for(uint8 i=0; i < delApplyList.size(); i++)
		msg<<delApplyList[i];
}

// 赠送礼物
void CFriendMgr::SendGift(CUser *pUser, CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		// 好友检测
		_friendMapIt selfIt = m_friendList.find(selfId);
		if(selfIt == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0561, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendInfo &selfInfo = selfIt->second;
		_friendDataIt selfDit = selfInfo.friendList.find(roleId);
		if(selfDit == selfInfo.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0561, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendData &selfFriendData = selfDit->second;
		if(selfFriendData.sendFlag > 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0562, TIPS_FAILURE_COLOR);
			return;
		}

		// 添加礼物
		_friendMapIt roleIt = m_friendList.find(roleId);
		if(roleIt == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0561, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendInfo &roleInfo = roleIt->second;
		_friendDataIt roleDit = roleInfo.friendList.find(selfId);
		if(roleDit == roleInfo.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0561, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendData &roleFriendData = roleDit->second;
		roleFriendData.award = 1;
		selfFriendData.sendFlag = 1;
		sCMissionManager.UpdateQuestState(pUser, EMQCT_5, 1);
	}
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0563, TIPS_FAILURE_COLOR);
	
	CheckHotPoint(EHPoint_Fri_RecvAward, roleId);
}

void CFriendMgr::SendAllFriendGift(CUser *pUser, CNetMessage &msg, uint32 selfId)
{
	if(selfId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	vector<uint32> addList;
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt selfIt = m_friendList.find(selfId);
		if(selfIt == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0564, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendInfo &selfInfo = selfIt->second;

		for(_friendDataIt it = selfInfo.friendList.begin(); it != selfInfo.friendList.end(); it++)
		{
			uint32 roleId = it->first;
			SFriendData &selfFriData = it->second;
			if(selfFriData.sendFlag > 0)
				continue;

			// 添加礼物
			_friendMapIt roleIt = m_friendList.find(roleId);
			if(roleIt == m_friendList.end())
				continue;
			SFriendInfo &roleInfo = roleIt->second;
			_friendDataIt roleDit = roleInfo.friendList.find(selfId);
			if(roleDit == roleInfo.friendList.end())
				continue;
			SFriendData &roleFriData = roleDit->second;
			roleFriData.award = 1;
			selfFriData.sendFlag = 1;

			addList.push_back(roleId);
		}
	}
	
	if(addList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0564, TIPS_FAILURE_COLOR);
		return;
	}

	msg<<PRO_SUCCESS<<(uint8)addList.size();
	for(uint8 i=0; i < addList.size(); i++)
	{
		msg<<addList[i];
		CheckHotPoint(EHPoint_Fri_RecvAward, addList[i]);
	}
	sCMissionManager.UpdateQuestState(pUser, EMQCT_5, addList.size());
}

void CFriendMgr::GetGiftList(CNetMessage &msg, CUser *pUser)
{
	if(pUser == NULL)
		return;

	uint32 selfId = pUser->GetRoleId();
	int leftTimes = MAX_GetAwardTimes - (uint32)pUser->GetExtData8(EData8_GetFriendGift);
	msg<<(uint8)MAX_GetAwardTimes<<(uint8)leftTimes;
	uint32 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt it = m_friendList.find(selfId);
	if(it == m_friendList.end())
		return;
	SFriendInfo &selfInfo = it->second;
	for(_friendDataIt fit = selfInfo.friendList.begin(); fit != selfInfo.friendList.end(); fit++)
	{
		SFriendData &data = fit->second;
		if(data.getFlag == 0 && data.award > 0)
		{
			msg<<fit->first;
			num++;
		}
	}
	msg.WriteData(pos, &num, sizeof(num));
}

void CFriendMgr::GetGift(CNetMessage &msg, CUser *pUser, uint32 roleId)
{
	if(pUser == NULL)
		return;
	if(pUser->GetExtData8(EData8_GetFriendGift) >= MAX_GetAwardTimes)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0572, TIPS_FAILURE_COLOR);
		return;
	}
	uint32 selfId = pUser->GetRoleId();
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt it = m_friendList.find(selfId);
		if(it == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0565, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendInfo &selfInfo = it->second;
		_friendDataIt fit = selfInfo.friendList.find(roleId);
		if(fit == selfInfo.friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0565, TIPS_FAILURE_COLOR);
			return;
		}
		SFriendData &data = fit->second;
		if(data.getFlag > 0 || data.award == 0)
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0565, TIPS_FAILURE_COLOR);
			return;
		}

		data.getFlag = 1;
	}

	int leftTimes = MAX_GetAwardTimes - (uint32)pUser->GetExtData8(EData8_GetFriendGift);
	msg<<PRO_SUCCESS<<(uint8)leftTimes;
	pUser->SetExtData8(EData8_GetFriendGift, pUser->GetExtData8(EData8_GetFriendGift) + 1);

	// 发奖
	SingletonAwardManager::instance().ActivityMakeAwardMsgAndSendAward(pUser, 12, msg);
}

void CFriendMgr::GetAllRecvGift(CNetMessage &msg, CUser *pUser)
{
	if(pUser == NULL)
		return;
	if(pUser->GetExtData8(EData8_GetFriendGift) >= MAX_GetAwardTimes)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0572, TIPS_FAILURE_COLOR);
		return;
	}
	uint32 selfId = pUser->GetRoleId();
	if(selfId == 0)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	AwardManager &awardMgr = SingletonAwardManager::instance();
	vector<SAwardData> award;
	vector<uint32> roleList;
	int leftTimes = MAX_GetAwardTimes - (uint32)pUser->GetExtData8(EData8_GetFriendGift);
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt it = m_friendList.find(selfId);
		if(it == m_friendList.end())
		{
			msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0565, TIPS_FAILURE_COLOR);
			return;
		}

		SFriendInfo &selfInfo = it->second;
		int aid = sCDropMatchingMgr.GetActivityDropId(12);
		for(_friendDataIt fit = selfInfo.friendList.begin(); fit != selfInfo.friendList.end(); fit++)
		{
			if(leftTimes == 0)
				break;
			SFriendData &data = fit->second;
			if(data.getFlag > 0 || data.award == 0)
				continue;

			data.getFlag = 1;
			leftTimes--;
			roleList.push_back(fit->first);
			
			awardMgr.GetLevelAward(aid, pUser->GetLevel(), award, false);
		}
	}

	if(award.empty() || roleList.empty())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0566, TIPS_FAILURE_COLOR);
		return;
	}
	msg<<PRO_SUCCESS<<(uint8)leftTimes<<(uint8)roleList.size();
	for(uint16 i=0; i < roleList.size(); i++)
		msg<<roleList[i];

	pUser->SetExtData8(EData8_GetFriendGift, MAX_GetAwardTimes - (uint32)leftTimes);
	SendAndMakeAwardMsg(pUser, award, msg);
}

void CFriendMgr::DeleteFriend(CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	NolockDeleteFriend(msg, selfId, roleId);
}

void CFriendMgr::NolockDeleteFriend(CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0567, TIPS_FAILURE_COLOR);
		return;
	}
	SFriendInfo &selfInfo = selfIt->second;
	
	_friendMapIt roleIt = m_friendList.find(roleId);
	if(roleIt == m_friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0567, TIPS_FAILURE_COLOR);
		return;
	}
	SFriendInfo &roleInfo = roleIt->second;
	
	_friendDataIt selfdataIt = selfInfo.friendList.find(roleId);
	if(selfdataIt == selfInfo.friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0568, TIPS_FAILURE_COLOR);
		return;
	}
	_friendDataIt roledataIt = roleInfo.friendList.find(selfId);
	if(roledataIt == roleInfo.friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0568, TIPS_FAILURE_COLOR);
		return;
	}

	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0569, TIPS_SUCCESS_COLOR);
	selfInfo.friendList.erase(selfdataIt);
	roleInfo.friendList.erase(roledataIt);

	NoticeFriendListChanged(roleId, false);
}

void CFriendMgr::GetBlackList(CNetMessage &msg, uint32 selfId)
{
	if(selfId == 0)
		return;
	msg<<(uint8)MAX_BlackNum;
	uint32 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;

	uint32 curTime = GetSysTime();
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
		return;
	SFriendInfo &selfInfo = selfIt->second;
	for(map<uint32, uint8>::iterator it = selfInfo.blackList.begin(); it != selfInfo.blackList.end(); it++)
	{
		uint32 roleId = it->first;
		SRoleSimpleData data;
		if(!simpleMgr.GetRoleData(roleId, data))
			continue;
		uint32 offLineTime = (data.lastLoginTime == 0) ? 0 : (curTime < data.lastLoginTime ? 0 : (curTime - data.lastLoginTime));
		msg<<data.roleId<<data.name<<data.level<<data.sex<<data.head<<data.power<<offLineTime;
		msg<<data.bangpaiId<<data.bpName;
		num++;
	}
	msg.WriteData(pos, &num, sizeof(num));
}

void CFriendMgr::AddToBlackList(CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}

	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
	{
		pair<_friendMapIt, bool> res = m_friendList.insert(make_pair(selfId, SFriendInfo()));
		if(!res.second)
			return;
		selfIt = res.first;
	}
	SFriendInfo &selfInfo = selfIt->second;
	_friendDataIt it = selfInfo.friendList.find(roleId);
	if(it != selfInfo.friendList.end())
	{
		CNetMessage tmp;
		NolockDeleteFriend(tmp, selfId, roleId);
	}

	map<uint32, uint8>::iterator bIt = selfInfo.blackList.find(roleId);
	if(bIt != selfInfo.blackList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0574, TIPS_FAILURE_COLOR);
		return;
	}
	if(selfInfo.blackList.size() >= MAX_BlackNum)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0578, TIPS_FAILURE_COLOR);
		return;
	}
	selfInfo.blackList.insert(make_pair(roleId, 1));
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0575, TIPS_SUCCESS_COLOR);
}

void CFriendMgr::DeleteBlackList(CNetMessage &msg, uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0552, TIPS_FAILURE_COLOR);
		return;
	}
	
	SFriendInfo &selfInfo = selfIt->second;
	map<uint32, uint8>::iterator it = selfInfo.blackList.find(roleId);
	if(it == selfInfo.blackList.end())
	{
		msg<<PRO_ERROR<<MakeStringColor(LANGUAGE_SSJ_0576, TIPS_FAILURE_COLOR);
		return;
	}
	selfInfo.blackList.erase(it);
	msg<<PRO_SUCCESS<<MakeStringColor(LANGUAGE_SSJ_0584, TIPS_SUCCESS_COLOR);
}

bool CFriendMgr::IsInBlackList(uint32 selfId, uint32 roleId)
{
	if(selfId == 0 || roleId == 0 || selfId == roleId)
		return false;
	
	boost::recursive_mutex::scoped_lock lk(m_mutex);
	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
		return false;
	SFriendInfo &info = selfIt->second;
	map<uint32, uint8>::iterator it = info.blackList.find(roleId);
	if(it != info.blackList.end())
		return true;
	return false;
}

void CFriendMgr::GetPushFriendList(CNetMessage &msg, uint32 selfId, uint16 level)
{
	if(selfId == 0 || level == 0)
	{
		msg<<(uint8)0;
		return;
	}

	_friendMapIt selfIt = m_friendList.find(selfId);
	if(selfIt == m_friendList.end())
		return;
	SFriendInfo &info = selfIt->second;
	uint32 curTime = GetSysTime();
	if(info.refreshTime + ReFreshCD > curTime)
		return;
	info.refreshTime = curTime;

	// 获取好友和黑名单列表
	vector<uint32> friendIdList;
	GetFriendAndBlackIDList(selfId, friendIdList);

	vector<uint32> roleList;
	CSimpleRoleDataMgr &simpleMgr = SingletonCSimpleRoleDataMgr::instance();
	simpleMgr.GetRandRoleIdList(selfId, level, MAX_PushFriendNum, roleList, friendIdList);

	uint32 pos = msg.GetDataLen();
	uint8 num = 0;
	msg<<num;
	for(uint8 i=0; i < roleList.size(); i++)
	{
		SRoleSimpleData data;
		if(!simpleMgr.GetRoleData(roleList[i], data))
			continue;
		uint32 offLineTime = (data.lastLoginTime == 0) ? 0 : (curTime < data.lastLoginTime ? 0 : (curTime - data.lastLoginTime));
		msg<<data.roleId<<data.name<<data.level<<data.sex<<data.head<<data.power<<offLineTime;
		msg<<data.bangpaiId<<data.bpName;
		num++;
	}
	msg.WriteData(pos, &num, sizeof(num));
}

void CFriendMgr::CheckHotPoint(uint16 type, uint32 roleId)
{
	uint8 status = EHPointS_NotShow;
	switch(type)
	{
	case EHPoint_Fri_RecvAward:	// 好友收到礼物通知
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt it = m_friendList.find(roleId);
		if(it == m_friendList.end())
			return;
		SFriendInfo &info = it->second;
		for(_friendDataIt fit = info.friendList.begin(); fit != info.friendList.end(); fit++)
		{
			SFriendData &data = fit->second;
			if(data.award == 1 && data.getFlag == 0)
			{
				status = EHPointS_Show;
				break;
			}
		}
		break;
	}
	case EHPoint_Fri_RecvApply:	// 好友收到申请列表
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		_friendMapIt it = m_friendList.find(roleId);
		if(it == m_friendList.end())
			return;
		SFriendInfo &info = it->second;
		if(!info.applyList.empty())
			status = EHPointS_Show;
		break;
	}
	
	default:
		return;
	}

	COnlineUser &onlineUser = SingletonOnlineUser::instance();
	CUser *pU = onlineUser.GetUserByRoleId(roleId).get();
	if(pU != NULL)
		SendHotPointStatus(pU, type, status);
}

void CFriendMgr::NoticeFriendListChanged(uint32 roleId, bool isAdd)
{
	if(roleId == 0)
		return;
	COnlineUser &onlineMgr = SingletonOnlineUser::instance();
	CUser *pU = onlineMgr.GetUserByRoleId(roleId).get();
	if(pU != NULL)
	{
		CNetMessage msg;
		msg.SetType(PRO_Friend);
		uint8 type = isAdd ? 1 : 2;	// 1 添加 2删除
		msg<<(uint8)31<<type<<roleId;
		SingletonSocket::instance().SendMsg(pU->GetSock(), msg);
	}
}

void CFriendMgr::ReadFriendInfo(const char *info, map<uint32, SFriendData> &friendList)
{
	if(info == NULL || strlen(info) == 0)
		return;
	friendList.clear();
	
	uint32 pos = 0;
	uint8 *buf = new uint8[strlen(info)*2];
	boost::scoped_array<uint8> autoDel(buf);
	int len = UnHexify(buf, info);
	uint8 num = buf[pos++];
	for(uint8 i=0; i < num; i++)
	{
		uint32 roleId = 0;
		SFriendData data;
		ReadDataFromBuf((char *)buf, &roleId, sizeof(roleId), pos, len);
		ReadDataFromBuf((char *)buf, &data.award, sizeof(data.award), pos, len);
		ReadDataFromBuf((char *)buf, &data.getFlag, sizeof(data.getFlag), pos, len);
		ReadDataFromBuf((char *)buf, &data.sendFlag, sizeof(data.sendFlag), pos, len);
		ReadDataFromBuf((char *)buf, &data.value, sizeof(data.value), pos, len);
		if(roleId == 0)
			continue;
		friendList.insert(make_pair(roleId, data));
	}
}

void CFriendMgr::ReadApplyList(const char *str, list<uint32> &applyList)
{
	if(str == NULL || strlen(str) == 0)
		return;
	applyList.clear();

	uint32 pos = 0;
	uint8 *buf = new uint8[strlen(str)*2];
	boost::scoped_array<uint8> autoDel(buf);
	int len = UnHexify(buf, str);
	uint8 num = buf[pos++];
	for(uint8 i=0; i < num; i++)
	{
		uint32 roleId = 0;
		ReadDataFromBuf((char *)buf, &roleId, sizeof(roleId), pos, len);
		if(roleId == 0)
			continue;
		applyList.push_back(roleId);
	}
}

void CFriendMgr::ReadBlackList(const char *str, map<uint32, uint8> &blackList)
{
	if(str == NULL || strlen(str) == 0)
		return;
	blackList.clear();

	uint32 pos = 0;
	uint8 *buf = new uint8[strlen(str)*2];
	boost::scoped_array<uint8> autoDel(buf);
	int len = UnHexify(buf, str);
	uint8 num = buf[pos++];
	for(uint8 i=0; i < num; i++)
	{
		uint32 roleId = 0;
		ReadDataFromBuf((char *)buf, &roleId, sizeof(roleId), pos, len);
		if(roleId == 0)
			continue;
		blackList.insert(make_pair(roleId, 1));
	}
}

void CFriendMgr::GetFriendInfoStr(string &info, map<uint32, SFriendData> &friendList)
{
	uint32 size = friendList.size();
	uint8 *buf = new uint8[(sizeof(SFriendData)+4) * size + 10];
	boost::scoped_array<uint8> autoDel(buf);
	uint32 pos = 0;

	buf[pos++] = size;
	for(_friendDataIt it = friendList.begin(); it != friendList.end(); it++)
	{
		uint32 roleId = it->first;
		SFriendData &data = it->second;
		if(roleId == 0)
			continue;
		pos = CopyDataToBuf((char *)buf, &roleId, sizeof(roleId), pos);
		buf[pos++] = data.award;
		buf[pos++] = data.getFlag;
		buf[pos++] = data.sendFlag;
		pos = CopyDataToBuf((char *)buf, &data.value, sizeof(data.value), pos);
	}

	info.resize(2*pos);
	Hexify((uint8*)info.c_str(), buf, pos);
}

void CFriendMgr::GetApplyListStr(string &apply, list<uint32> &applyList)
{
	uint32 size = applyList.size();
	uint8 *buf = new uint8[sizeof(uint32) * size + 10];
	boost::scoped_array<uint8> autoDel(buf);
	uint32 pos = 0;

	buf[pos++] = size;
	for(list<uint32>::iterator it = applyList.begin(); it != applyList.end(); it++)
	{
		uint32 roleId = *it;
		if(roleId == 0)
			continue;
		pos = CopyDataToBuf((char *)buf, &roleId, sizeof(roleId), pos);
	}

	apply.resize(2*pos);
	Hexify((uint8*)apply.c_str(), buf, pos);
}

void CFriendMgr::GetBlackListStr(string &blackStr, map<uint32, uint8> &blackList)
{
	uint32 size = blackList.size();
	uint8 *buf = new uint8[sizeof(uint32) * size + 10];
	boost::scoped_array<uint8> autoDel(buf);
	uint32 pos = 0;

	buf[pos++] = size;
	for(map<uint32,uint8>::iterator it = blackList.begin(); it != blackList.end(); it++)
	{
		uint32 roleId = it->first;
		if(roleId == 0)
			continue;
		pos = CopyDataToBuf((char *)buf, &roleId, sizeof(roleId), pos);
	}

	blackStr.resize(2*pos);
	Hexify((uint8*)blackStr.c_str(), buf, pos);
}


