#ifndef _CHOU_KA_NANAGER_H_
#define _CHOU_KA_NANAGER_H_
#include "self_typedef.h"
#include <map>
#include <set>
#include <vector>
using namespace std;

class CUser;

struct ChouKaBase
{
	uint8 openLevel;
	uint8 bemustCnt;
	uint8 freeCnt;
	uint16 normalDrop;
	uint16 mustDrop;
	uint16 costId;
	uint16 costNum;
	uint32 freeCd;
	MultiAward awards;
};
typedef map<uint8, ChouKaBase> ChouKaBaseMap;
typedef map<uint8, ChouKaBase>::iterator ChouKaBaseMapIt;

struct SingleChouKaDrop
{
	SAwardData award;
	uint32 weight;
};

struct ChouKaDrop
{
	vector<SingleChouKaDrop> multiDrop;
	uint32 allWeight;
};

typedef map<uint8, ChouKaDrop> ChouKaDropMap;
typedef map<uint8, ChouKaDrop>::iterator ChouKaDropMapIt;

class CChouKaCfgManager
{
public:
	CChouKaCfgManager();
	~CChouKaCfgManager();

public:
	bool InitChouKaCfg();
	bool InitChouKaBaseCfg();
	bool InitChouKaDropCfg();
	ChouKaBase* GetChouKaBase(uint8 type);
	ChouKaDrop* GetChouKaDrop(uint8 type);

public:
	void SingleChouKa(uint8 type, SAwardData& heroAward);
	void MultiChouKa(uint8 type, uint8 cnt, MultiAward& heroAward);

private:
	ChouKaBaseMap m_chouKaBase;
	ChouKaDropMap m_chouKaDrop;
};
#define sCChouKaCfgManager boost::details::pool::singleton_default<CChouKaCfgManager>::instance()

struct ChouKaJiLu
{
	ChouKaJiLu()
		: allCnt(0)
		, freeCd(0)
		, freeTimes(0)
	{

	}
	uint32 allCnt;
	uint32 freeCd;
	uint8 freeTimes;
};

typedef map<uint8, ChouKaJiLu> ChouKaJiLuMap;
typedef map<uint8, ChouKaJiLu>::iterator ChouKaJiLuMapIt;

// 用户图鉴
class CChouKaManager
{
public:
	CChouKaManager();
	~CChouKaManager();

public:
	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(const char *str);

public:
	void InitChouKa();
	void ResetChouKa();
	// 获取当前属性
	bool GetChouKaMsg(CNetMessage& msg);
	// 抽卡
	bool ChouKa(CUser* user, CNetMessage& msg);

	ChouKaJiLu* GetChouKaJiLu(uint8 type);
private:
	ChouKaJiLuMap m_chouKa;
};

#endif