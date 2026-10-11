#ifndef _PET_H_
#define _PET_H_

#include <boost/shared_ptr.hpp>
#include "xml.h"
#include "self_typedef.h"
#include "unit_basic_attr.h"
#include "pet_equip_manage.h"
#include "hero_cfg_manager.h"

struct SPet;

const int PET_MAX_SKILL_NUM = 12;
const int PET_INIT_SKILL_NUM = 2;
const int PET_XUEMAI_MAX_NUM = 5;	// 血脉个数
const float PET_WING_RATIO = 0.6f;
const uint8 PET_BORN_SKILL_NUM = 4;
const uint8 PET_XIU_LIAN_MAX_NUM = 5;
const uint8 PET_ADD_BORN_SKILL_NUM = 2;
const uint8 PET_EQUIP_NUM = 6; // 装备最大件数


struct SPetBasicData
{
	SPetBasicData()
	{
		type = 0;
		race = 0;
		quality = 0;
		attackType = 0;
		
		id = 0;
		chuzhanLevel = 0;
		initStar = 0;
		shengxingItemId = 0;
		transferItemNum = 0;
		pic = 0;
		attack = 0;
		wufang = 0;
		fafang = 0;
		qixue = 0;
		sudu = 0;
		
		mingzhong = 0;
		shanbi = 0;
		baoji = 0;
		baojikang = 0;
		
		attackCZ = 0;
		wufangCZ = 0;
		fafangCZ = 0;
		qixueCZ = 0;
		suduCZ = 0;
		mingzhongCZ = 0;
		shanbiCZ = 0;
		baojiCZ = 0;
		baojikangCZ = 0;
		
		attrList.clear();
		topoAttrs.clear();
		bornSkill.clear();
		name.clear();
		desc.clear();
	}

	uint8 type;		// 1物2法3肉4辅5控6灵
	uint8 race;		// 种族
	uint8 quality;		// 1蓝2紫3橙4红
	uint8 attackType;	// 1物攻2法攻
	
	uint16 id;
	uint16 chuzhanLevel;
	uint16 initStar;
	uint16 shengxingItemId;
	uint16 transferItemNum;
	uint32 pic;
	int attack;	// 攻击
	int wufang;	// 物防
	int fafang;	// 法防
	int qixue;	// 气血
	int sudu;	// 速度
	
	int mingzhong;	// 命中，最后转化为命中率
	int shanbi;	// 闪避，最后转化为闪避率
	int baoji;	// 暴击，最后转化为暴击率
	int baojikang;	// 抗暴击，最后转化为抗暴击率
	
	int attackCZ;	// 攻击成长
	int wufangCZ;	// 物防成长
	int fafangCZ;	// 法防成长
	int qixueCZ;	// 气血成长
	int suduCZ;		// 速度成长
	int mingzhongCZ;	// 命中成长
	int shanbiCZ;	// 闪避成长
	int baojiCZ;	// 暴击成长
	int baojikangCZ;	// 抗暴击成长

	// 实际生效(val/100)%
	MultiAttr attrList;
	TupoAttrVec topoAttrs;

	vector<uint16> bornSkill;
	string name;
	string desc;
};

struct SSkillLvCost
{
	SSkillLvCost()
	{
		tarLevel = 0;
		learnLv_limit = 0;
		costList.clear();
	}
	uint16 tarLevel;
	uint16 learnLv_limit;	// 学习等级限制,0不限制
	vector<SCostData> costList;
};

struct SSort_SkillCost
{
	bool operator()(SSkillLvCost const &v1,SSkillLvCost const &v2)
	{
		return v1.tarLevel < v2.tarLevel;
	}
};

struct SSkillBookData
{
	SSkillBookData()
	{
		itemId = 0;
		skillId = 0;
		skillLv = 0;
	}
	uint16 itemId;
	uint16 skillId;
	uint16 skillLv;
};

struct SPetStarData
{
	SPetStarData()
	{
		star = 0;
		star_ratio = 0;
		step_ratio = 0;
		total_cost = 0;
		level_limit = 0;
	}
	int star;
	int star_ratio;
	int step_ratio;
	int total_cost;
	int level_limit;
};

struct SPetStarStepData
{
	SPetStarStepData()
	{
		step = 0;
		attrType = 0;
		attr_ratio = 0;
		cost_ratio = 0;
	}
	int step;
	int attrType;
	int attr_ratio;
	int cost_ratio;
};

struct SPetXiuLianAttr
{
	SPetXiuLianAttr()
	{
		Clear();
	}
	void Clear()
	{
		level_limit = 0;
		attrList.clear();
	}
	uint16 level_limit;
	vector<SAttrData> attrList;
};

struct SPetXiuLianData
{
	SPetXiuLianData()
	{
		cost.clear();
		for(uint8 i=0;i < sizeof(xiulianData)/sizeof(xiulianData[0]);i++)
		{
			xiulianData[i].Clear();
		}
	}
	vector<SCostData> cost;
	SPetXiuLianAttr xiulianData[PET_XIU_LIAN_MAX_NUM];
};

struct SPetTypeRatioData
{
	SPetTypeRatioData()
	{
		attackRatio = 0.0;
		wufangRatio = 0.0;
		fafangRatio = 0.0;
		suduRatio = 0.0;
		qixueRatio = 0.0;
		mingzhongRatio = 0.0;
		shanbiRatio = 0.0;
		baojiRatio = 0.0;
		baojiKangRatio = 0.0;
	}
	float attackRatio;
	float wufangRatio;
	float fafangRatio;
	float suduRatio;
	float qixueRatio;
	float mingzhongRatio;
	float shanbiRatio;
	float baojiRatio;
	float baojiKangRatio;
};

struct LvCfg
{
	uint8 tili;
	uint16 lv;
	uint32 exp;
};
typedef map<uint16, LvCfg> LvCfgMap;
typedef map<uint16, LvCfg>::iterator LvCfgMapIt;

class CPetCfgManager
{
public:
	CPetCfgManager()
	{
		m_petMaxLevel = 0;
		m_basicData.clear();
		m_LvUpExp.clear();
		m_skillCost.clear();
		m_upStar_qualityCost.clear();
		m_upStar_star.clear();
		m_upStar_step.clear();
		m_xiulianData.clear();
		m_petTypeRatio.clear();
		for(uint8 i=0;i < PET_BORN_SKILL_NUM;i++)
			m_bornSkillCost[i].clear();
	}
	
	~CPetCfgManager()
	{
		m_basicData.clear();
	}
	
	bool Init();
	SPetBasicData *GetPetCfg(uint16 id);
	bool InitBasicData(SPet *pPet);

	// 升级
	uint32 GetLevelUpExp(uint16 nextLv);
	LvCfg* GetLvCfgCfg(uint16 nextLv);
	uint16 GetPetMaxLevel();

	// 技能
	SSkillLvCost *GetSkillCostData_Normal(uint16 skillId, uint16 skillLv);
	SSkillLvCost *GetSkillCostData_Born(uint8 skillPos,uint16 skillLv);
	SSkillBookData *GetSkillBookData(uint16 itemId);
	uint16 GetSkillBookid(uint16 skillId);

	void GetSkillAllCost(uint16 skillId, uint16 maxLv, map<uint16, int>& cost, float rate);
	// 升星
	int GetUpStarCost(uint8 quality,uint8 star,uint8 step);
	bool GetStarAttr(vector<SAttrData> &attr, uint16 petId, uint8 star, uint16 lv);
	bool GetBreakAttr(vector<SAttrData> &attr, uint16 petId, uint16 blv);
	int GetUpStarLevelLimit(uint8 star);
	
	void GetXiulianAllCost(uint16 quality, uint8 level, map<uint16, int>& cost);
	
	// 神将类型属性值
	SPetTypeRatioData *GetPetTypeAttrRatio(uint8 type);
	void MergeCost(map<uint16, int>& allCost, vector<SCostData>& addCost);
	void SubCost(map<uint16, int>& allCost, vector<SCostData>& subCost);

	map<uint16, SPetBasicData>& GetAllCfg() { return m_basicData; }
private:
	typedef vector<vector<SCostData> > Skill_t;
	void SetBornSkill(vector<uint16> &skill,string &str);

	// 基础配置
	map<uint16,SPetBasicData> m_basicData;	// petId,data
	// 升级经验
	vector<uint32> m_LvUpExp;	// [level-1]
	LvCfgMap m_userLvUpExp;	// [level-1]
	uint16 m_petMaxLevel;
	// 技能配置
	vector<SSkillLvCost> m_bornSkillCost[PET_BORN_SKILL_NUM];	// 天生技能消耗，消耗列表=[idx][level-1]
	map<uint16,vector<SSkillLvCost> > m_skillCost;	// 天书技能消耗<id,lv_list>
	map<uint16, SSkillBookData> m_skillBook;	// 神将天书 <itemId,data>
	map<uint16, uint16> m_skillBookItem;	// 神将天书 <skill,item>
	// 升星
	map<int,int> m_upStar_qualityCost;	// 品质消耗
	map<int,SPetStarData> m_upStar_star;	// 星级系数
	map<int,SPetStarStepData> m_upStar_step;  // 阶段系数
	
	// 修炼
	map<uint32,SPetXiuLianData> m_xiulianData;
	// 神将类型属性值
	map<uint8,SPetTypeRatioData> m_petTypeRatio;
};

typedef boost::details::pool::singleton_default<CPetCfgManager> SingletonCPetCfgMgr;
#define sCPetCfgManager SingletonCPetCfgMgr::instance()

struct SPet
{
	SPet()
	{
		type = 0;
		attackType = 0;
		quality = 0;
		star = 0;
		breakLevel = 0;
		chuzhanFlag = 0;
		id = 0;
		level = 0;
		celue = 0;
		exp = 0;
		zhanDouli = 0;
		pic = 0;
		hp = 0;
		basicAttr.Clear();
	}
	static uint8 extNum;		// 1  读取修炼数据
	uint8 type;		// 1物2法3肉4辅5控6灵,不存储
	uint8 attackType;	// 1物攻2法攻,不存储
	uint8 quality;	// 1蓝2紫3橙4红
	uint8 star;		// 星
	uint8 breakLevel;	// 突破登记
	uint8 chuzhanFlag;	// 1 出战 0 未出战
	uint8 xiuLianLevel; // 修炼等级
	U8tU16Map curXiuLianCnts;	// 当前修炼值
	uint16 id;
	uint16 level;	// 等级
	uint16 celue;	// 策略id,不存储
	uint32 exp;		// 经验
	uint64 zhanDouli;	// 战斗力
	int pic;
	int hp;
	SUnitBasicAttr basicAttr;
	vector<SSkillData> otherSkill;

	uint16 skill[PET_MAX_SKILL_NUM];
	uint16 skillLevel[PET_MAX_SKILL_NUM];
	string name;
	skillVec suitSkills;

	void Clear();

	uint8 GetAttackType(){return attackType;}
	int GetAttack(){return basicAttr.attack;}
	int GetWuFang();
	int GetFaFang();
		
	uint64 GetZhanDouLi()
	{
		return zhanDouli;
	}

	static double GetBasicValueRatioByQuality(int basicQuality,int curQuality,int curQuaLevel);

	uint8 AddSkill(uint16 id,bool fuGai=false,int *pFugaiId=NULL);
	uint8 GetSkillNum();
	uint8 GetSkillNum(bool isZhuDong);
	uint16 GetSkillLevel(uint16 id);
	uint8 GetSkillPos(uint16 id);
	void ForgetSkill(uint8 pos);
	void GetSkillInfoByPos(uint8 pos,uint16 &skillId,uint16 &skillLv);
	bool AddSkillByPos(uint8 pos,uint16 skillId,uint16 skillLv);
	
	uint8 GetSkillLevel_ALL(uint16 id);
	void DelSkill(uint16 id);

	int VerifyLevelAndNum(uint32 level);
	int VerifyXueMaiLevelAndNum(uint32 level );
	void GetSuitSkills(vector<SSkillData> &skillList);
	void ClearSkill()
	{
		for(uint8 i = 0; i < PET_MAX_SKILL_NUM; i++)
		{
			skill[i] = 0;
			skillLevel[i] = 0;
		}
	}

	void AddLevel(CUser *pUser=NULL,uint8 kaijiaIndex=0xff,int addCount = 1); // 增加默认提升的等级数

	bool GetAttrList(CUser *pUser,vector<SAttrData> &baseAttr,vector<SAttrData> &extAttr);
	bool Init(CUser *pUser=NULL,bool updateBreak=false);
	
	void ResetToLv1(CUser *pUser=NULL); // 将神将重置到1级，等级转移功能用

	void GetXueMaiAddVal(int type,int XMLevel,int XMExp,int &attack,int &recovery,int &hp,int &speed);
	void GetXueMaiLevelUpItem(uint8 xMLevel,uint8 xMExp,uint8 &nextLv,uint8 &nextExp,int &item1,int &itemNum1,int &item2,int &itemNum2);

	static int GetXueMaiDiffPrice(uint8 hLv,uint8 hExp,uint8 lLv,uint8 lExp);

	int GetSkilLimitCount(); // 获取技能数量上限
	int GetSkillId(int pos); // 获取技能id
	int LearnSkill(int skillId,int pos); // 学习技能
	void InitSkill(); // 初始化神将技能
	void LearnBornSkill(); // 学习天生技能 特殊处理
	void LearnBornSkillWild(); // 学习天生技能 野怪处理
	void UpgradeSkill(int skillId, int cnt = 1); // 技能升级
	void AttrToZero();//属性值归零处理

	void GetChongShengCost(MultiCost& allCost);
	enum PetCultureType
	{
		PCT_Level = 0,				// 升级
		PCT_Star = 1,				// 升星
		PCT_Xiulian = 2,			// 修炼
		PCT_BornSkillLevel = 3,		// 出生技能升级
		PCT_BookSkillLevel4 = 4,	// 天书技能升级
		PCT_BookSkillLevel5 = 5,
		PCT_BookSkillLevel6 = 6,
		PCT_BookSkillLevel7 = 7,
		PCT_BookSkillLevel8 = 8,
		PCT_BookSkillLevel9 = 9,
		PCT_BookSkillLevel10 = 10,
		PCT_BookSkillLevel11 = 11,
		PCT_BreakLevel = 12,		// 突破

	};
	void UpdateSuitAttrs();
};


typedef boost::shared_ptr<SPet> SharePetPtr;
typedef map<uint16,SharePetPtr> CPetMap;
typedef map<uint16,SharePetPtr>::iterator CPetMapIt;

#endif

