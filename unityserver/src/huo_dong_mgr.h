#ifndef _HUO_DONG_MGR_H_
#define _HUO_DONG_MGR_H_

#include "xml.h"
#include "singleton.h"
#include "self_typedef.h"

struct SYaoQianShuData
{
	SYaoQianShuData()
	{
		Clear();
	}
	void Clear()
	{
		cost_type = 0;
		cost_value = 0;
		get_type = 0;
		get_value = 0;
	}
	uint16 cost_type;
	uint32 cost_value;
	uint16 get_type;
	uint32 get_value;
};

class CYaoQianShuMgr
{
public:
	CYaoQianShuMgr()
	{
		m_data.clear();
		m_defaultTimes = 0;
		m_levelLimit = 0;
	}
	bool Init();
	bool GetCfg(uint8 type, uint16 index, SYaoQianShuData &data);
	uint16 GetTypeTimes(uint8 type);
	uint8 GetMaxDefaultTimes(){return m_defaultTimes;}
	uint16 GetLevelLimit(){return m_levelLimit;}

private:
	map<uint8,map<uint16,SYaoQianShuData> > m_data;	// type,<times, data>
	uint8 m_defaultTimes;
	uint16 m_levelLimit;
};

typedef boost::details::pool::singleton_default<CYaoQianShuMgr> SingletonCYaoQianShuMgr;

struct YaoShiJiage
{
	int num;
	SCostData cost;
	//bool operator>(const YaoShiJiage& other);
};
typedef vector<YaoShiJiage> YaoShiJiageVec;

struct ZhuanPanAward
{
	int weight;
	SAwardData award;
};
typedef vector<ZhuanPanAward> ZhuanPanAwardVec;

struct ZhuanPanRandom
{
	ZhuanPanRandom()
		: sumWeight(0)
	{
	}
	int sumWeight;
	ZhuanPanAwardVec awards;
};

struct ZhuanPanCfg
{
	uint8 type;
	uint8 zkShop;
	uint8 jfShop;
	uint8 rankType;
	YaoShiJiageVec jiage;
	ZhuanPanRandom random;

	void GetJiaGe(SCostData& cost, int curNum, int buyNum);
	void GetAward(MultiAward awards, int cnt);
};
typedef map<uint8, ZhuanPanCfg> ZhuanPanCfgMap;
typedef map<uint8, ZhuanPanCfg>::iterator ZhuanPanCfgMapIt;

struct HuoDongAwardIdx
{
	HuoDongAwardIdx()
		: awradIdx(0)
		, startDay(0)
		, endDay(0)
	{
	}
	uint8 awradIdx;
	uint16 startDay;
	uint16 endDay;
};

struct HuoDongOpenCfg
{
	HuoDongOpenCfg()
		: id(0)
		, name("")
		, openDay(0)
		, finishDay(0)
		, awardIdx(0)
		, startTime(0)
		, endTime(0)
		, finishTime(0)
	{
		awardIdxs.clear();
	}
	uint8 id;
	string name;
	uint8 openDay;
	uint8 finishDay;
	uint8 awardIdx;
	uint32 startTime;
	uint32 endTime;
	uint32 finishTime;
	vector<HuoDongAwardIdx> awardIdxs;
};
typedef map<uint8, HuoDongOpenCfg> HuoDongOpenCfgMap;
typedef map<uint8, HuoDongOpenCfg>::iterator HuoDongOpenCfgMapIt;

struct HuDongTimeCfg
{
	uint16 day;
	U8tU8Map openHuoDong;
};
typedef map<uint8, HuDongTimeCfg> HuDongTimeCfgMap;
typedef map<uint8, HuDongTimeCfg>::iterator HuDongTimeCfgMapIt;

class CHuoDongManage
{
public:
	CHuoDongManage();
	~CHuoDongManage();

public:
	bool InitHuoDongCfg();
	
public:
	U8MultiAwardMap& GetQiRiAwards() { return m_qiRiAwards; }
	MultiAward* GetQiRiAward(uint8 day);
	ZhuanPanCfg* GetZhuanPanCfg(uint8 idx = 0);
	HuoDongOpenCfg* GetHuoDongCfg(uint8 type);

	uint8 GetHuoDongIdx(uint8);
public:
	void InitHuoDong();
	void CheckNewDayHuoDong(uint16 checkDay = 0);

private:
	bool InitHuoDongOpenCfg();
	bool InitQiRiDengLuAward();
	bool InitZhuanPanCfg();

private:
	U8MultiAwardMap m_qiRiAwards;
	ZhuanPanCfgMap m_zhuanPanCfgs;
	HuoDongOpenCfgMap m_huoDongOpenCfg;
	HuDongTimeCfgMap m_huoDongTimeCfg;
	U8tU8Map m_curHuoDong;
	uint8 m_maxChiXuDay;

};
#define sCHuoDongManage boost::details::pool::singleton_default<CHuoDongManage>::instance()

#endif

