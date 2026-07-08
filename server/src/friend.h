#ifndef _FRIEND_H_
#define _FRIEND_H_

#include <boost/thread.hpp>
#include "self_typedef.h"
#include "singleton.h"

class CUser;

struct SFriendData
{
	SFriendData()
	{
		award = 0;
		getFlag = 0;
		sendFlag = 0;
		value = 0;
	}
	uint8 award;	// 0没有礼物1有礼物
	uint8 getFlag;	// 0未领取1已领取
	uint8 sendFlag;	// 0未赠送1已赠送
	uint32 value;
};

struct SFriendInfo
{
	SFriendInfo()
	{
		refreshTime = 0;
		friendList.clear();
		blackList.clear();
		applyList.clear();
	}

	uint32 refreshTime;	// 获取推荐好友列表刷新时间
	std::map<uint32, SFriendData> friendList;	// 好友列表	[roleId]-data
	std::map<uint32, uint8> blackList;	// 黑名单	[roleId]-value
	std::list<uint32> applyList;	// 申请列表
};

class CFriendMgr
{
public:
	CFriendMgr();

	~CFriendMgr();

	bool Init();

	void Save();

	void Timer();

	void GetFriendList(CNetMessage &msg, uint32 roleId);	// 获取好友列表

	void GetFriendIDList(uint32 roleId, vector<uint32> &vec);	// 获取好友id列表

	void GetFriendAndBlackIDList(uint32 roleId, vector<uint32> &vec);	// 获取好友和黑名单id列表

	void GetAddApplyList(CNetMessage &msg, uint32 roleId);	// 获取好友申请列表
	
	void ApplyAddFriend(CNetMessage &msg, uint32 selfId, uint32 roleId);	// 好友申请

	void DealFriendAddApply(CNetMessage &msg, uint32 selfId, uint32 roleId, bool accept);	// 处理好友申请

	void DealAllApply(CNetMessage &msg, uint32 selfId, bool accept);

	void SendGift(CUser *pUser, CNetMessage &msg, uint32 selfId, uint32 roleId);	// 赠送礼物

	void SendAllFriendGift(CUser *pUser, CNetMessage &msg, uint32 selfId);	// 一键赠送

	void GetGiftList(CNetMessage &msg, CUser *pUser);	// 获取礼物列表

	void GetGift(CNetMessage &msg, CUser *pUser, uint32 roleId);	// 领取礼物

	void GetAllRecvGift(CNetMessage &msg, CUser *pUser);	// 一键领取礼物

	void DeleteFriend(CNetMessage &msg, uint32 selfId, uint32 roleId);	// 删除好友

	void GetBlackList(CNetMessage &msg, uint32 selfId);	// 获取黑名单列表

	void AddToBlackList(CNetMessage &msg, uint32 selfId, uint32 roleId);	// 添加黑名单

	void DeleteBlackList(CNetMessage &msg, uint32 selfId, uint32 roleId);	// 删除黑名单

	bool IsInBlackList(uint32 selfId, uint32 roleId);

	void GetPushFriendList(CNetMessage &msg, uint32 selfId, uint16 level);	// 获取推荐好友列表

	void CheckHotPoint(uint16 type, uint32 roleId);

private:
	void NoticeFriendListChanged(uint32 roleId, bool isAdd=true);	// 通知客户端好友列表变化(添加或删除)
	
	void NolockDealFriendAddApply(CNetMessage &msg, uint32 selfId, uint32 roleId, bool accept);	// 处理好友申请
	
	void NolockDeleteFriend(CNetMessage &msg, uint32 selfId, uint32 roleId);	// 删除好友
	
	void ReadFriendInfo(const char *info, std::map<uint32, SFriendData> &friendList);
	void ReadApplyList(const char *str, std::list<uint32> &applyList);
	void ReadBlackList(const char *str, map<uint32, uint8> &blackList);
	void GetFriendInfoStr(string &info, std::map<uint32, SFriendData> &friendList);
	void GetApplyListStr(string &apply, std::list<uint32> &applyList);
	void GetBlackListStr(string &blackStr, map<uint32, uint8> &blackList);

	static const uint32 MAX_FriendNum = 50;
	static const uint32 MAX_GetAwardTimes = MAX_FriendNum;
	static const uint32 MAX_ApplyNum = MAX_FriendNum;
	static const uint32 MAX_BlackNum = 100;
	static const uint32 MAX_PushFriendNum = 10;
	static const uint32 ReFreshCD = 5;	// 推荐好友列表刷新cd

	boost::recursive_mutex m_mutex;
	std::map<uint32, SFriendInfo> m_friendList;	// 好友列表, [selfId]=map[info]
};

typedef boost::details::pool::singleton_default<CFriendMgr> SingletonCFriendMgr;



#endif

