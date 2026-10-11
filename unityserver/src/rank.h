#ifndef _RANK_H_
#define _RANK_H_

#include "self_typedef.h"
#include "singleton.h"
#include <map>
#include <vector>
using namespace std;

struct SRankPet
{
	SRankPet()
	{
		pet_id = 0;
		power = 0;
		level = 0;
	}
	uint64 power;
	uint16 level;
	uint16 pet_id;
};

struct SLRankData
{
	SLRankData()
	{
		role_id = 0;
		data = 0;
		data1 = 0;
		bang_id = 0;
        festival_num1 = 0;
        festival_num2 = 0;
		pet_id = 0;
		rank = 0;
		level = 0;
		xiang = 0;
		vipLv = 0;
		role_name = "";
		pet_name = "";
	}
	bool operator()(const SLRankData& l,const SLRankData& r){   
	   if (l.data == r.data)
	   {
	   		return l.data1 > r.data1;
	   } 
	   return l.data > r.data;  
	}  

	void SetData(SLRankData &right)
	{
		role_id = right.role_id;
		data = right.data;
		data1 = right.data1;
		bang_id = right.bang_id;
        festival_num1 = right.festival_num1;
        festival_num2 = right.festival_num2;
		pet_id = right.pet_id;
		rank = right.rank;
		level = right.level;
		xiang = right.xiang;
		vipLv = right.vipLv;
		role_name = right.role_name;
		pet_name = right.pet_name;
	}

	uint32 role_id;
	uint32 data;	//排序值
	uint32 data1;	//排序值附加
	uint32 bang_id;//帮派Id
    uint32 festival_num1;//活动赠送Or受赠物品数量
    uint32 festival_num2;//活动赠送Or受赠物品数量
	uint16 pet_id;
	uint16 rank;//排行
	uint16 level;//等级
	uint8 xiang;//职业
	uint8 vipLv;
	string role_name;
	string pet_name;
};

//////////////////////////////////////////////////////////////////////////////


struct SRankData
{
	SRankData()
	{
		Clear();
	}
	
	bool operator<(const SRankData &a) const
	{
		if(this->data1 == a.data1)
		{
			if(this->data2 == a.data2)
				return this->time < a.time;
			return this->data2 > a.data2;
		}
		return this->data1 > a.data1;
	}

	void Clear()
	{
		role_id = 0;
		value1 = 0;
		time = 0;
		data1 = 0;
		data2 = 0;
	}

	uint32 role_id;
	int value1;		// 保存值1
	uint32 time;	// 更新时间
	uint64 data1;	// 排序值1
	uint64 data2;	// 排序值2

	/*
		ERT_Level:	data1:等级, data2:exp
		ERT_Pet:	data1:战力, value1: petId
		ERT_Power:	data1:总战力

		ERT_Blood_Today:		data1:星数, value1: nodeId
		ERT_Blood_Yesterday:	data1:星数, value1: nodeId
		ERT_GuanKa_Zhu:			data1:星数
		ERT_GuanKa_Zhi:			data1:星数
	*/
};

struct SRankList
{
	SRankList()
	{
		Clear();
	}

	void Clear()
	{
		needSort = false;
		minVal = 0;
		data.clear();
	}

	void Sort();

	void Update(int type, uint32 roleId, uint64 data1, uint64 data2=0, int value1=0);

	bool needSort;
	uint64 minVal;	// 入榜最低值
	list<SRankData> data;
};

class CRankMgr
{
public:
	enum ERankType
	{
		ERT_Level = 1,	// 等级榜
		ERT_Pet = 2,	// 神将榜
		ERT_Power = 3,	// 总战力榜

		ERT_Blood_Today = 21,		// 血战榜即时
		ERT_Blood_Yesterday = 22,	// 血战榜昨天
		ERT_GuanKa_Zhu = 23,		// 推图主线
		ERT_GuanKa_Zhi = 24,		// 推图支线
		ERT_BookScore = 25,			// 图鉴

		ERT_BossGeRen = 31,			// boss个人榜
		ERT_BossBangPai = 32,		// boss帮派帮
		ERT_DaTiZhengQueShu = 41,	// 答题数量  不是排行，用于发放奖励用

		EMRA_JING_JI = 999,			// 竞技场排名   --占用
		ERT_MAX,
	};


	CRankMgr()
	{
		m_rank.clear();
	}

	~CRankMgr()
	{
		m_rank.clear();
	}

	bool Init();
	void Save();
	
	void UpdateData(int type, uint32 roleId, uint64 data1, uint64 data2=0, int value1=0);
    
	uint16 GetRankIdx(int type,uint32 roleId);
	
	void MakeRankMsg(int type, SRankData &selfData, CNetMessage &msg, int showNum=MAX_SHOW_NUM);

	void RemoveRankByValue(int type, uint32 roleId, int value1);	// 适用于roleId不唯一排行榜(神将榜), 删除roleId对应value1的记录
	
	void RemoveRank(int type, uint32 roleId);	// 适用于roleId唯一的排行榜
	
	void Clear(int type);
	
	void Timer();

	static const int MAX_SHOW_NUM = 100;
	static const int MAX_SAVE_NUM = 1000;
	static const int MAX_ForceSort_NUM = 1500;

private:
    void GetRankData(int type, uint32 roleId, SRankData &sData);

	void BloodRankToYesterday();

	boost::recursive_mutex m_mutex;
	map<int, SRankList> m_rank;	// type, set
};

typedef boost::details::pool::singleton_default<CRankMgr> SingletonCRankMgr;



#endif


