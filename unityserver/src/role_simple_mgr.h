#ifndef _ROLE_SIMPLE_MGR_H_
#define _ROLE_SIMPLE_MGR_H_

#include "singleton.h"

class CUser;

struct SRoleSimpleData
{
	SRoleSimpleData()
	{
		Clear();
	}
	
	void Clear()
	{
		sex = 0;
		head = 0;
		model = 0;
		vipLv = 0;
		level = 0;
		roleId = 0;
		bangpaiId = 0;
		power = 0;
		huoyue_week = 0;
		huoyue_day = 0;
		lastLoginTime = 0xffffffff;
		name.clear();
		bpName.clear();
	}

	uint8 sex;
	uint8 head;
	uint8 model;
	uint8 vipLv;
	uint8 jingJie;  // 境界等级
	uint16 level;
	uint32 roleId;
	uint32 bangpaiId;	// 帮派id
	uint64 power;
	uint32 huoyue_week;	// 周活跃
	uint32 huoyue_day;	// 日活跃
	uint32 lastLoginTime;	// 0 在线, > 0 最后下线时间
	std::string name;
	std::string bpName;	// 帮派名
};

class CSimpleRoleDataMgr
{
public:
	CSimpleRoleDataMgr();
	
	~CSimpleRoleDataMgr();

	bool Init();

	void Save();

	void UpdateRoleData(CUser *pUser);

	void UpdateLastLoginTime(uint32 roleId);

	bool GetRoleData(uint32 roleId, SRoleSimpleData &data);

	void Timer();

	void GetRandRoleIdList(uint32 roleId, uint16 level, int maxNum, vector<uint32> &vec, vector<uint32> &friendList); // 获取等级相近的角色id列表，自己id和好友除外

	void MakeRoleDetails(CNetMessage &msg, uint32 roleId, uint8 type=0);	// 查看玩家详细信息

	string GetUserColorName(uint32 id);

private:
	boost::recursive_mutex m_mutex;
	std::map<uint32, SRoleSimpleData> m_data;	// [roleId]-data
};

typedef boost::details::pool::singleton_default<CSimpleRoleDataMgr> SingletonCSimpleRoleDataMgr;


#endif

