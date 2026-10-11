#ifndef _HERO_CFG_MANAGER_H_
#define _HERO_CFG_MANAGER_H_
#include "self_typedef.h"
#include <map>
#include <set>
#include <vector>
#include "skill.h"

using namespace std;

class CUser;

// 消耗
struct SCostData
{
	SCostData()
		: costType(0)
		, typeId(0)
		, costValue(0)
	{
	}

	void Clear()
	{
		costType = 0;
		typeId = 0;
		costValue = 0;
	}
	uint16 costType;
	uint32 typeId;
	int costValue;
};
typedef vector<SCostData> MultiCost;
typedef map<uint8, SCostData> U8KCostMap;
typedef map<uint8, SCostData>::iterator U8KCostMapIt;

// 属性
struct SAttrData
{
	SAttrData()
	{
		attrType = 0;
		attrValue = 0;
	}
	SAttrData(uint16 type,int val):attrType(type),attrValue(val){}
	uint16 attrType;
	int attrValue;
	void MakeMsg(CNetMessage& msg);
};

typedef vector<SAttrData> MultiAttr;
typedef map<uint8, SAttrData> U8AttrMap;
typedef map<uint8, SAttrData>::iterator U8AttrMapIt;
typedef map<uint8, MultiAttr> U8MultiAttrMap;
typedef map<uint8, MultiAttr>::iterator U8MultiAttrMapIt;
void MakeMultiAttrMsg(MultiAttr& attrs, CNetMessage& msg);

struct TupoAttr
{
	MultiAttr selfAttrs;
	MultiAttr teamAttrs;
	MultiAttr skillAttrs;
};
typedef vector<TupoAttr> TupoAttrVec;

typedef map<uint8, MultiCost> CostMap;
typedef map<uint8, MultiCost>::iterator CostMapIt;

typedef map<uint8, CostMap> QualityBreakCostMap;
typedef map<uint8, CostMap>::iterator QualityBreakCostMapIt;

// 修炼成功概率
struct XiuLianSuccRatio
{
	uint16 startPercent;
	uint16 endPercent;
	uint16 ratio;
};
typedef vector<XiuLianSuccRatio> XiuLianSuccRatioVec;

struct XiuLianLevelCfg
{
	uint16 costType;
	uint16 singleCost;
	uint16 fullCost;
	XiuLianSuccRatioVec succRatios;
	MultiAttr addAttrs;
	
	bool CheckSucc(uint32 curCnt);
};
typedef map<uint8, XiuLianLevelCfg> XiuLianLevelCfgMap;
typedef map<uint8, XiuLianLevelCfg>::iterator XiuLianLevelCfgMapIt;

struct HeroStarCfg
{
	uint8 skillLevel;	// 技能等级
	uint32 attrRate;	// 属性成长  百分比
	uint32 attrEx;		// 额外增加属性
	uint32 attrExSum;	// 增加总属性
	U8tU16Map starUpCost;
	U8tU16Map qualityAttr;
};
typedef map<uint8, HeroStarCfg> HeroStarCfgMap;
typedef map<uint8, HeroStarCfg>::iterator HeroStarCfgMapIt;

struct BookStarCfg
{
	uint8 condLevel;	// 条件
	uint32 bookAttr;	// 当前星级图鉴属性
	uint32 bookAttrSum;	// 当前总图鉴属性(1星-N星)
	U8KCostMap starUpCost;
	U8tU16Map qualityBookScore;
	U8tU16Map qualityBookSumScore;
	SCostData* GetCost(uint8 quality);
	uint16 GetScore(uint8 quality);
	uint16 GetSumScore(uint8 quality);
};
typedef map<uint8, BookStarCfg> BookStarCfgMap;
typedef map<uint8, BookStarCfg>::iterator BookStarCfgMapIt;

// 图鉴属性
struct BookLevelCfg
{
	uint8 level;
	uint32 starValue;
	uint32 endValue;
	MultiAttr curAttrs;
	MultiAttr curSumAttrs;
};
typedef map<uint8, BookLevelCfg> BookLevelCfgMap;
typedef map<uint8, BookLevelCfg>::iterator BookLevelCfgMapIt;

struct SingleBookSocre
{
	uint8 star;
	uint16 curScore;
};
typedef map<uint16, SingleBookSocre> HeroBookSocreMap;
typedef map<uint16, SingleBookSocre>::iterator HeroBookSocreMapIt;

struct XiuLianCfg
{
	XiuLianCfg()
		: level(0)
		, name("")
		, condLv(0)
		, xiuLianCnt(0)
		, sumCnt(0)
	{

	}
	uint8 level;
	string name;
	uint8 condLv;
	uint16 xiuLianCnt;
	uint32 sumCnt;

	MultiCost costs;
	MultiAttr sumAttrs;
	vector<SSkillData> skill;
};
typedef map<uint16, XiuLianCfg> XiuLianCfgMap;
typedef map<uint16, XiuLianCfg>::iterator XiuLianCfgMapIt;

class CHeroCfgManager
{
public:
	CHeroCfgManager();
	~CHeroCfgManager();
	
public:
	bool InitHeroCfg();
	// 品质
	bool InitHeroQualityCfg();
	// 突破
	bool InitHeroBreakCfg();
	// 星星
	bool InitHeroStarCfg();
	// 修炼
	//bool InitHeroXiulianCfg();
	// 图鉴
	bool InitBookCfg();
	// 修炼
	bool InitXiuLianCfg();
	
public:
	// 获取星级配置
	HeroStarCfg* GetHeroStarCfg(uint8 star);
	// 获取星级配置
	BookStarCfg* GetBookStarCfg(uint8 star);
	// 获取突破消耗
	MultiCost* GetBreakCost(uint8 quality, uint8 breakLevel);
	// 获取修炼配置
	XiuLianLevelCfg* GetXiulianCfg(uint8 xiulianLevel);
	// 获取图鉴品质系数
	double GetBookSumRatio(uint8 quality);
	// 获取图鉴进度id
	uint8 GetBookLevel(uint32 score);
	// 获取当前等级属性
	MultiAttr* GetBookLevelAttr(uint8 level);
	// 获取当前总属性
	MultiAttr* GetBookLevelSumAttr(uint8 level);
	// 获取图鉴配置
	BookLevelCfg* GetBookLevelCfg(uint8 level);
	// 修炼
	XiuLianCfg *GetXiuLianCfg(uint8 level);
	// 获取精炼系数
	double GetJingLianRatio(uint8 quality);
	// 获取强化系数
	double GetQiangHuaRatio(uint8 quality);
	// 获取法宝强化系数
	double GetFaBaoQiangHuaRatio(uint8 quality);
	uint8 GetBreakLvCond(uint8 lv);
	uint16 GetBreakAttrAdd(uint8 lv);
	uint8 GetMaxStar() { return m_bookStarCfg.size(); }

public:
	static U8tU16Map g_xiuLianAttrAdd;
	static uint16 g_xlItemId;

private:
	QualityBreakCostMap m_breakCost;
	U16tDblMap m_costRatio;
	U16tDblMap m_bookRatio;
	U16tDblMap m_qhRatio;
	U16tDblMap m_jlRatio;
	U16tDblMap m_fbjlRatio;
	U8tU8Map m_breakLvCond;
	U8tU16Map m_breakAttrAdd;
	XiuLianLevelCfgMap m_xiuLianLevelCfg;
	HeroStarCfgMap m_heroStarCfg;
	BookStarCfgMap m_bookStarCfg;
	BookLevelCfgMap m_bookCfg;
	XiuLianCfgMap m_xiuLianCfg;
};
typedef boost::details::pool::singleton_default<CHeroCfgManager> SingletonHeroCfgManager;
#define sCHeroCfgManager SingletonHeroCfgManager::instance()

// 用户图鉴
class UserBook
{
public:
	UserBook();
	~UserBook();
	
public:
	// 数据保存
	void SaveData(string &str);
	// 数据加载
	void LoadData(const char *str);
	
public:
	// 获取当前属性
	const MultiAttr& GetBookAttr();
	void GetBookAttr(MultiAttr& allAttr);
	// 获取图鉴信息
	bool GetBookMsg(CNetMessage& msg);
	// 升级图鉴
	bool BookStarLevelUp(CUser* user, CNetMessage& msg);
	void SendTuJianHotPointStatus(CUser* pUser);

	uint32 GetBookScore() { return m_bookScore; }
private:
	MultiAttr m_bookAttrs;
	MultiAttr m_bookScoreAttrs;
	HeroBookSocreMap m_heroScores;
	uint32 m_bookScore;
	uint8 m_level;
};

#endif