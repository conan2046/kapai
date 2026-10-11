#ifndef _USER_SPIRIT_H_
#define _USER_SPIRIT_H_

#include "self_typedef.h"
#include <map>
using namespace std;

typedef map<uint8, uint8> CFreeSpiritStateMap;
typedef map<uint8, uint8>::iterator CFreeSpiritStateMapIt;

class CUser;

struct SpiritCfg
{
	uint8 id;
	uint16 start;
	uint16 end;
	uint16 add;
	SAwardData cost;
};
typedef map<uint8, SpiritCfg> SpiritCfgMap;
typedef map<uint8, SpiritCfg>::iterator SpiritCfgMapIt;

class CUserSpiritCfg
{
public:
	CUserSpiritCfg();
	~CUserSpiritCfg();

	bool InitSpiritCfg();

	bool InHuoDongTime();
	bool AfterHuoDongTime();

	SpiritCfg* GetSpiritCfg(uint8 id);
private:
	SpiritCfgMap m_spritCfgs;
};
#define sCUserSpiritCfg boost::details::pool::singleton_default<CUserSpiritCfg>::instance()

class CUserSpirit
{
public:
	CUserSpirit();
	~CUserSpirit();

	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(const char *str);
public:
	// 领取状态重置
	void FreeSpiritReset();
	// 检测定时增加体力
	void CheckAddSpirit(CUser* pUser = NULL);
	// 增加体力
	bool AddSpirit(CUser* pUser, uint16 spirit, bool isLv = false);
	// 扣除体力
	bool SubSpirit(CUser*, uint16 spirit);
	// 领取免费体力
	void GetFreeSpirit(CUser* pUser, CNetMessage &msg);
	// 能否领取判断
	bool CheckGetFreeSpiritState();
	// 体力领取状态
	int GetFreeSpiritState(uint8 idx);
	// 体力信息获取
	void MakeSpiritMsg(CNetMessage &msg);
	// 体力领取信息获取
	void MakeFreeSpiritMsg(CNetMessage &msg);
	void SendTiLiHotPointStatus(CUser* pUser);
	uint8 GetSpiritCnt();
public:
	// 获取当前体力
	inline uint16 GetCurSpirit() { return m_spirit; }
	
public:
	static uint16 MAX_SPIRIT;
	static uint16 FREE_SPIRIT;
	static uint16 SPIRIT_MONEY;
	static uint16 FULL_SPIRIT;
	static uint16 SPIRIT_LINGQU;
private:
	uint16 m_spirit;
	uint32 m_lastSpiritTime;
	CFreeSpiritStateMap m_freeGetState;
};

#endif