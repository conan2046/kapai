#ifndef __PET_EQUIP_MANAGE_H__
#define __PET_EQUIP_MANAGE_H__
#include "self_typedef.h"
#include "hero_cfg_manager.h"
#include <vector>
#include <map>
#include <string>
#include <utility>
#include "skill.h"

using std::vector;
using std::map;
using std::string;
using std::pair;
using std::make_pair;
struct SAttrData;
class CEquip;
class CUser;
struct SPet;
struct SAwardData;
class CEquipManeger;

typedef map<uint16, MultiCost> MultiCostMap;
typedef map<uint16, MultiCost>::iterator MultiCostMapIt;
typedef map<uint16, uint32> PECostMap;
typedef map<uint16, uint32>::iterator PECostMapIt;
typedef map<uint16, uint32>::const_iterator PECostMapCIt;

typedef PECostMap AttrSumMap;
typedef PECostMap::iterator AttrSumMapIt;

enum PET_EQUIP_ATTR_TYPE
{
	PEAT_BASE = 1,
	PEAT_EXTERN = 2,
	PEAT_EXTERN_STRONG = 3,
};

struct ComposeCfg
{
	MultiCost costs;
	SAwardData tar;
};
typedef map<uint16, ComposeCfg> ComposeCfgMap;
typedef map<uint16, ComposeCfg>::iterator ComposeCfgMapIt;

typedef map<uint16, ComposeCfgMap> TypeComposeCfgMap;
typedef map<uint16, ComposeCfgMap>::iterator TypeComposeCfgMapIt;

typedef vector<uint16> ComposeIds;
typedef map<uint16, ComposeIds> ComposeIdMap;
typedef map<uint16, ComposeIds>::iterator ComposeIdMapIt;

// 出生属性配置
struct CEquipCfg
{
	CEquipCfg()
		: id(0)
		, part(0)
		, suit(0)
		, quality(0)
		, szCost(0)
		, name("")
	{
	}

	uint16 id;
	uint8 part;
	uint8 suit;
	uint8 quality;
	uint16 szCost;
	string name;
	SAttrData baseAttr;
	MultiAttr qhAttr;
	MultiAttr jlAttr;
	MultiAttr jxAttr;
	MultiAttr szAttr;
};
typedef map<uint16, CEquipCfg> EquipCfgMap;
typedef map<uint16, CEquipCfg>::iterator EquipCfgMapIt;
typedef map<uint16, CEquipCfg>::const_iterator EquipCfgMapCIt;

// 星级属性配置
struct CEquipStarCfg
{
	CEquipStarCfg()
		: star(0)
		, quatily(0)
		, maxLevel(0)
		, costPercent(0)
		, cntRandId(0)
		, typeRandId(0)
	{
		fenJieCost.clear();
	}

	uint8 star;
	uint8 quatily;
	uint8 maxLevel;
	uint32 costPercent;
	uint32 cntRandId;
	bool isRepeat;
	uint32 typeRandId;
	PECostMap fenJieCost;
};
typedef map<uint8, CEquipStarCfg> PEStarCfgMap;
typedef map<uint8, CEquipStarCfg>::iterator PEStarCfgMapIt;
typedef map<uint8, CEquipStarCfg>::const_iterator PEStarCfgMapCIt;

// 强化配置
struct CEquipStrongCfg
{
	CEquipStrongCfg()
		: level(0)
		, fenJiePercent(0)
		, strongPercent(0)
	{
		strongCost.clear();
	}

	uint8 level;
	uint32 fenJiePercent;
	uint32 strongPercent;
	PECostMap strongCost;
	uint32 typeRandId;
	bool isRepeat;
	uint8 addCnt;
};
typedef map<uint8, CEquipStrongCfg> PEStrongCfgMap;
typedef map<uint8, CEquipStrongCfg>::iterator PEStrongCfgMapIt;
typedef map<uint8, CEquipStrongCfg>::const_iterator PEStrongCfgMapCIt;

typedef pair<uint16, uint16> ValueRand; // 随机区间
typedef vector<ValueRand> StarValueRands; // 值星级随机区间
typedef map<uint8, StarValueRands> StarAttrValueRands; // 属性值星级随机区间
typedef map<uint8, StarValueRands>::iterator StarAttrValueRandsIt;

typedef map<uint32, SSkillData> PESAttrs;
typedef map<uint32, SSkillData>::iterator PESAttrsIt;
typedef map<uint32, SSkillData>::const_iterator PESAttrsCIt;

enum COMPOSE_TYPE
{
	CPT_ITEM_HC = 1,			// 道具合成
	CPT_HERO_HC = 2,			// 神将合成
	CPT_HERO_ITEM_FJ = 3,	// 神将碎片分解
	CPT_EQUIP_HC = 4,		// 装备合成
	CPT_EQUIP_FJ = 5,		// 装备分解
	CPT_EQUIP_CS = 6,		// 装备重生为碎片
	CPT_TREASURE_FJ = 7,	// 法宝碎片分解
	CPT_FABAO_HC = 8,		// 法宝合成
	CPT_FABAO_FJ = 9,		// 法宝分解
};

struct SuitAttr
{
	U8MultiAttrMap cntAttrs;			// 套装属性
	map<uint8, SSkillData> cntSkill;	// 套装技能
};

typedef map<uint16, SuitAttr> SuitMap;				// 套装属性
typedef map<uint16, SuitAttr>::iterator SuitMapIt;

// 觉醒配置
struct JueXingCfg
{
	MultiCost cost;
	string name;
	U8AttrMap curAddAttr;
	U8MultiAttrMap subAddAttr;
};
typedef map<uint16, JueXingCfg> JueXingCfgMap;
typedef map<uint16, JueXingCfg>::iterator JueXingCfgMapIt;

// 强化配置
struct QiangHuaCfg
{
	QiangHuaCfg():ratioSum(0)
	{
	}
	SCostData cost;
	U8tU16Map ratio; // 暴击比率
	uint16 ratioSum;
	uint8 GetRatioLevel();
};
typedef map<uint16, QiangHuaCfg> QiangHuaCfgMap;
typedef map<uint16, QiangHuaCfg>::iterator QiangHuaCfgMapIt;

// 神铸配置
struct ShenZhuCfg
{
	MultiCost cost;
	uint16 itemNum;
	string name;
	map<uint8, SSkillData> posSkill;
};
typedef map<uint16, ShenZhuCfg> ShenZhuCfgMap;
typedef map<uint16, ShenZhuCfg>::iterator ShenZhuCfgMapIt;

struct FaBaoCfg
{
	uint8 quality;
	uint16 id;
	int exp;
	SAttrData attr;
	SAttrData qhAttr;
	MultiAttr jlAttr;
	string name;
};
typedef map<uint16, FaBaoCfg> FaBaoCfgMap;
typedef map<uint16, FaBaoCfg>::iterator FaBaoCfgMapIt;

struct QiangHuaDaShiCfg
{
	uint8 lv;
	uint16 cndBegin;
	MultiAttr attrs;
};

typedef map<uint8, QiangHuaDaShiCfg> QHDSCfgMap;
typedef map<uint8, QiangHuaDaShiCfg>::iterator QHDSCfgMapIt;
typedef map<uint8, QHDSCfgMap> TypeQHDSCfgMap;
typedef map<uint8, QHDSCfgMap>::iterator TypeQHDSCfgMapIt;

// 装备特殊词条。T1/T2/T3百分比统一使用万分比保存。
struct EquipAffixCfg
{
	EquipAffixCfg()
		: id(0)
		, qualityMin(6)
		, passiveSkillId(0)
		, duration(0)
		, perTurnLimit(0)
		, perBattleLimit(0)
	{
		memset(value1, 0, sizeof(value1));
		memset(value2, 0, sizeof(value2));
	}

	bool IsPartAllowed(uint8 part) const
	{
		for (size_t i = 0; i < parts.size(); ++i)
		{
			if (parts[i] == part)
				return true;
		}
		return false;
	}

	int GetValue1(uint8 tier) const { return tier >= 1 && tier <= 3 ? value1[tier - 1] : 0; }
	int GetValue2(uint8 tier) const { return tier >= 1 && tier <= 3 ? value2[tier - 1] : 0; }

	uint16 id;
	uint8 qualityMin;
	uint16 passiveSkillId;
	uint8 duration;
	uint8 perTurnLimit;
	uint8 perBattleLimit;
	string key;
	string name;
	string event;
	string conflictGroup;
	string desc;
	vector<uint8> parts;
	int value1[3];
	int value2[3];
};
typedef map<uint16, EquipAffixCfg> EquipAffixCfgMap;
typedef map<uint16, EquipAffixCfg>::iterator EquipAffixCfgMapIt;
typedef map<uint16, EquipAffixCfg>::const_iterator EquipAffixCfgMapCIt;

class CItemCfgManager
{
public:
	CItemCfgManager();
	~CItemCfgManager();
	
public:
	bool InitAllCfg();
	// 装备配置
	bool InitEquipCfg();
	// 合成配置
	bool InitComposeCfg();
	// 套装属性值
	bool InitSuitAttrCfg();
	// 精炼配置
	bool InitJingLianCfg();
	// 觉醒配置
	bool InitJueXingCfg();
	// 强化配置
	bool InitQiangHuaCfg();
	// 神铸配置
	bool InitShenZhuCfg();
	// 法宝
	bool InitFaBaoCfg();
	// 强化大师
	bool InitQiangHuaDaShiCfg();
	// 装备特殊词条
	bool InitEquipAffixCfg();
public:
	// 获取装备配置
	CEquipCfg* GetEquipCfg(uint16 id);
	// 获取合成配置
	ComposeCfgMap* GetComposeCfgMap(uint8 type);
	ComposeCfg* GetComposeCfg(uint8 type, uint16 id);
	// 获取套装属性
	SuitAttr* GetSuitAttr(uint8 type);
	// 获取部位名称
	const char* GetPosName(uint8 pos);
	// 获取装备名称
	const char* GetEquipName(uint16 id);
	// 获取装备颜色
	int GetEquipColor(uint16 id);
	// 获取套装属性
	void GetSuitAttr(uint16 type, uint16 cnt, skillVec& skills);
	// 强化配置
	QiangHuaCfg* GetQiangHuaCfg(uint16 level);
	// 精炼需要经验
	uint32 GetJingLianExp(uint16 level);
	// 觉醒配置
	JueXingCfg* GetJueXinCfg(uint16 level);
	// 神铸配置
	ShenZhuCfg* GetShenZhuCfg(uint16 level);
	// 法宝配置
	FaBaoCfg* GetFaBaoCfg(uint16 tid);

	string GetEquipColorName(uint16);
	string GetFaBaoColorName(uint16);
	// 法宝强化经验
	uint32 GetFaBaoExp(uint16 level);
	// 获取法宝合成配置
	ComposeIds* GetFaBaoComposeIds(uint16);
	// 获取法宝搜索概率
	uint16 GetFaBaoSouSuo(uint16);
	// 法宝精炼消耗
	MultiCost* GetFaBaoJlCost(uint16 level);
	QHDSCfgMap* GetQHDSMap(uint8 type);
	QiangHuaDaShiCfg* GetQHDSCfg(uint8 type, uint8 lv);
	QiangHuaDaShiCfg* GetQhdsCfg(QHDSCfgMap* qmap, uint8 lv);
	EquipAffixCfg* GetEquipAffixCfg(uint16 id);
	const EquipAffixCfgMap& GetEquipAffixCfgs() const { return m_equipAffixCfgs; }
	bool RollEquipAffix(uint8 part, uint8 quality, uint32 seed, uint16& affixId, uint8& tier) const;
	uint8 MaxFaBaoQhLevel() { return m_fbqhMax; }
	uint8 MaxFaBaoJlLevel() { return m_fbjlMax; }
	U16tU32Map& GetFaBaoJY() { return m_faBaoJY; }
private:
	TypeComposeCfgMap m_typeComposeCfgs;
	ComposeIdMap m_composeIdCfgs;
	
	EquipCfgMap m_equipCfgs;     // 装备配置
	SuitMap m_Suits;			// 套装
	U16tU32Map m_jlNeedExp;		// 精炼需要经验
	JueXingCfgMap m_jxCfgs;		// 觉醒配置
	QiangHuaCfgMap m_qhCfgs;	// 强化配置
	ShenZhuCfgMap m_szCfgs;		// 神铸配置
	FaBaoCfgMap m_fbCfg;
	U8tU32Map m_fbQhCfg;
	MultiCostMap m_fbJlCfg;
	uint16 m_fbqhMax;
	uint16 m_fbjlMax;
	TypeQHDSCfgMap m_qhdsCfg;
	U16tU16Map m_faBaoSS;
	U16tU32Map m_faBaoJY;
	EquipAffixCfgMap m_equipAffixCfgs;

public:
	static uint16 CfgFBMaxCnt;
	static uint16 CfgFBStartCnt;
	static uint16 CfgFBAddSec;
	static uint16 CfgMaxJlLv;
};
typedef boost::details::pool::singleton_default<CItemCfgManager> SingletonItemCfgManager;
#define sCItemCfgManager SingletonItemCfgManager::instance()

enum EQUIP_STRONG_TYPE
{
	EST_QIANGHUA = 1,
	EST_JINGLIAN = 2,
	EST_JUEXING = 3,
	EST_SHENZHU = 4,
	EST_FBQIANGHUA = 5,
	EST_FBJINGLIAN = 6,
};

class CEquip
{
public:
	CEquip();
	virtual ~CEquip();

public:
	// 属性初始化
	bool InitAttr();
	void AddAttr(int type, const SAttrData& tv);
	void PeekAttrs(AttrSumMap& sums);
	int SaveData(uint8 *outBuf, uint32& pos, uint32 maxLen);
	int LoadData(uint8 *intBuf, uint32& pos, uint32 maxLen);
	void MakeMsg(CNetMessage &msg);
	void InitSpecialAffix();
	void MakeAffixMsg(CNetMessage &msg) const;
	SSkillData GetAffixSkill() const;

	uint16 GetYangChengLevel(uint8 type);
	void GetChongSheng(MultiCost& costs, uint8 sp);
public:
	uint32 uid;	// 存
	uint16 id;	// 存
	uint8 wpos;
	uint8 fpos; // 站位
	uint32 curExp;
	U8tU16Map strongLevel; // 存
	uint32 strongCost;
	SAttrData baseAttr;
	MultiAttr qhAttr;
	MultiAttr jlAttr;
	MultiAttr jxAttr;
	MultiAttr szAttr;
	uint32 affixSeed;
	uint16 specialAffixId;
	uint8 specialAffixTier;
	uint8 affixLockMask;
};
typedef map<uint32, CEquip> EquipMap;
typedef map<uint32, CEquip>::iterator EquipMapIt;
typedef map<uint32, CEquip>::const_iterator EquipMapCIt;
typedef map<uint8, uint32> PetEquipPos;
typedef map<uint8, uint32>::iterator PetEquipPosIt;
typedef map<uint8, uint32>::reverse_iterator PetEquipPosCIt;
typedef map<uint8, uint32> FormationEquipMap;
typedef map<uint8, uint32>::iterator FormationEquipMapIt;

struct QHDSAttr
{
	uint8 curLv;
	MultiAttr attrs;
};

typedef map<uint8, QHDSAttr> QHDSAttrMap;
typedef map<uint8, QHDSAttr>::iterator QHDSAttrMapIt;

struct WearEquipSuit
{
	WearEquipSuit()
	{
		wearEquips[1] = 0;
		wearEquips[2] = 0;
		wearEquips[3] = 0;
		wearEquips[4] = 0;
		wearEquips[5] = 0;
		wearEquips[6] = 0;
		suitAttrs.clear();
	}
	FormationEquipMap wearEquips;
	SuitMap suitAttrs;
	QHDSAttrMap qhdsAttr;
	MultiAttr sumAttr;
	vector<SSkillData> skill;

	uint32 GetOtherFaBaoId(uint8 curPos);
	uint32 GetFaBaoId(uint8 curPos);
	QHDSAttr* GetQHDSAttr(uint8 type);
	void MakeQHDSMsg(CNetMessage& msg, uint8 type = 0);
	void CalcAttr(CEquipManeger& mgr);
};

typedef map<uint8, WearEquipSuit> AllWearEquipSuitMap;
typedef map<uint8, WearEquipSuit>::iterator AllWearEquipSuitMapIt;

struct FaBao
{
	FaBao()
		: uid(0)
		, id(0)
		, fpos(0)
		, wpos(0)
		, exp(0)
	{
		jlAttr.clear();
		ycLv.clear();
	}
	uint32 uid;
	uint16 id;
	uint8 fpos;
	uint8 wpos;
	uint32 exp;
	SAttrData attr;
	SAttrData qhAttr;
	MultiAttr jlAttr;
	U8tU8Map ycLv;
	void MakeMsg(CNetMessage &msg);
	bool InitAttr();
	uint8 GetYangChengLevel(uint8 type);
	void GetChongSheng(MultiCost& costs, uint8 sp);
};
typedef map<uint32, FaBao> FaBaoMap;
typedef map<uint32, FaBao>::iterator FaBaoMapIt;

// 用户神将装备管理
class CEquipManeger
{
public:
	CEquipManeger();
	~CEquipManeger();

public:
	// 添加装备
	bool AddEquip(CUser* pUser, uint16 equipId);
	void DelEquip(CUser* pUser, uint32 equipId);
	CEquip* GetEqiup(uint32 id);
	void TakeOffAllEquip(CUser* pUser, SPet& pet);

	void InitSuitAndQHDS();

	void MakeEquipMsg(CNetMessage& msg);

public:
	bool AddFaBao(CUser* pUser, uint16 tid);
	void DelFaBao(CUser* pUser, uint32 fid);
	FaBao* GetFaBao(uint32 id);

	// LS大法
public:
	void SaveData(string& outStr);
	void LoadData(char* inStr);

	// 协议处理
public:
	// 装备合成
	void EquipHeCheng(CUser* pUser, CNetMessage& msg);
	// 强化
	void StrongEquip(CUser* pUser, CNetMessage& msg);
	void StrongAllEquip(CUser* pUser, CNetMessage& msg);
	// 精炼
	void JingLianEquip(CUser* pUser, CNetMessage& msg);
	// 觉醒
	void JueXingEquip(CUser* pUser, CNetMessage& msg);
	// 神铸
	void ShenZhuEquip(CUser* pUser, CNetMessage& msg);
	// 发送装备列表
	void SendPetEquipList(CUser* pUser, CNetMessage& msg);
	void SendPetEquipAffixList(CUser* pUser);
	void WearPetEquip(CUser* pUser, CNetMessage& msg);
	void TakeOffPetEquip(CUser* pUser, CNetMessage& msg);
	void CFenJiePetEquip(CUser* pUser, CNetMessage& msg);
	void MutilFenJiePetEquip(CUser* pUser, CNetMessage& msg);

	// 发送法宝列表
	void SendFaBaoList(CUser* pUser, CNetMessage& msg);
	void WearFaBao(CUser* pUser, CNetMessage& msg);
	void TakeOffFaBao(CUser* pUser, CNetMessage& msg);
	void StrongFaBao(CUser* pUser, CNetMessage& msg);
	void JingLianFaBao(CUser* pUser, CNetMessage& msg);
	EquipMap& GetPetEquips() { return m_petEquips; }
	void UpdateEquip(CUser* pUser, CEquip* equip);
	void UpdateFabao(CUser* pUser, FaBao* fabao);

	void GetQHDSMsg(CNetMessage& msg);
	void CheckQHDS(uint8 pos, uint8 type, CUser* pUser = NULL);
	void CheckEquipQHDS(uint8 pos, CUser* pUser = NULL);
	void CheckFBQHDS(uint8 pos, CUser* pUser = NULL);

	void FaBaoSouSuo(CUser* pUser, CNetMessage& msg);
	void FaBaoAutoSouSuo(CUser* pUser, CNetMessage& msg);
	void FaBaoHeCheng(CUser* pUser, CNetMessage& msg);
	void AutoHeChengFaBao(CUser* pUser, CNetMessage& msg);
	void EChongShengChaXun(CUser* pUser, CNetMessage& msg);
	void EChongSheng(CUser* pUser, CNetMessage& msg);
	void FChongShengChaXun(CUser* pUser, CNetMessage& msg);
	void FChongSheng(CUser* pUser, CNetMessage& msg);

	void TrapSouSuoCnt(CUser* pUser);


	void ClearJingLian(CUser* pUser);

#if _DEBUG
	void QiangHuaAllEquip(CUser* pUser, uint8 type, uint8 lv);
#endif
public:
	void CheckCnt(CUser* pUser);
	void AddSouSuoCnt(CUser* pUser, uint16 cnt);
	void GetEquipAttr(uint8 pos, MultiAttr& attrs);

	void GetSuitSkills(uint8 fpos, vector<SSkillData> &skillList);

public:
	uint8 GetYCLevelCnt(uint8 type, uint16 lv);

private:
	void CalcEquipSuitAttr(uint8 fpos);

	void GetFenjieCost(CEquip* equip, map<uint16, uint32>& costBack);
	WearEquipSuit* GetWearEquipSuit(uint8 pos);
private:
	EquipMap m_petEquips;
	AllWearEquipSuitMap m_formationEquips;
	FaBaoMap m_allFaBao;

private:
	uint32 m_lastCntTime;		// 搜索次数恢复时间
	uint16 m_faBaoCnt;			// 次数
};

#endif // __PET_EQUIP_MANAGE_H__
