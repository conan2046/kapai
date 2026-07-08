#ifndef _ITEM_H_
#define _ITEM_H_
#include <string>
#include <map>
#include <vector>
#include "self_typedef.h"

using namespace std;
class CCallScript;
struct SAttrData;
struct SCostData;

const float ATTR_RATIO = 10000.0;

enum EAttrType
{
	EAT_Attack = 1,	// 1 攻击
	EAT_WuFang,		// 2 物防
	EAT_FaFang,		// 3 法防
	EAT_QiXue,		// 4 生命
	EAT_SuDu,		// 5 速度
	EAT_MingZhong,	// 6 命中
	EAT_ShanBi,		// 7 闪避
	EAT_BaoJi,		// 8 暴击
	EAT_BaoJiKang,	// 9 抗暴
	EAT_AttackAdd,	//10 攻击加成

	EAT_WuFangAdd, // 11 物防加成
	EAT_FaFangAdd,	// 12 法防加成
	EAT_QiXueAdd,	// 13 生命加成
	EAT_SuDuAdd,	// 14 速度加成
	
	EAT_MingZhongLv,	// 15 命中率
	EAT_ShanBiLv,		// 16 闪避率
	EAT_BaoJiLv,		// 17 暴击率
	EAT_BaoJiKangLv,	// 18 抗暴率
	EAT_ZengShangLv,	// 19 增伤率
	EAT_WuMianLv,	// 20 物免率
	
	EAT_FaMianLv,	// 21 法免率
	EAT_BaoJiAdd,	// 22 暴击伤害
	EAT_FanJiLv,	// 23 反击率
	EAT_FanJiKangLv,	// 24 抗反率
	EAT_FanJiAdd,	// 25 反击伤害
	EAT_LianJiLv,	// 26 连击率
	EAT_LianJiKangLv,	// 27 抗连率
	EAT_LianJiAdd,		// 28 连击伤害
	EAT_FanZhenLv,		// 29 反震率
	EAT_FanZhenKangLv,	// 30 抗震率

	EAT_FanZhenAdd,		// 31 反震伤害
	EAT_FuMianAdd,		// 32 负面强化
	EAT_FuMianKangAdd,	// 33 负面抵抗


	EAT_AttackAdd_Fight = 50,	//50 攻击加成
	EAT_WuFangAdd_Fight = 51, // 51 物防加成
	EAT_FaFangAdd_Fight = 52,	// 52 法防加成
	EAT_QiXueAdd_Fight = 53,	// 53 生命加成
	EAT_SuDuAdd_Fight = 54,	// 54 速度加成
	EAT_MAX_NUM,
};

enum EUserUpdateType
{
	EUUT_AllAttrType = 500,	// attr属性类型
	EUUT_QianNeng = 501,
	EUUT_Exp = 502,
	EUUT_HP = 503,
	EUUT_Money = 504,
	EUUT_YB = 505,
	EUUT_BangDingYB = 506,	// 绑定元宝
	EUUT_ZhanDouLi = 507,
	EUUT_OpenPackageNum = 508,
	EUUT_NextOpenPackageTime = 509,
	EUUT_ArenaScore = 510,
	EUUT_LightEffect = 511,	// 武器特效
	EUUT_HuSongState = 512,	// 护送状态
	EUUT_TotalZhanDouLi = 513,	// 总战力
	EUUT_Shenhun = 514,	// 神魂
	EUUT_MeiLi = 515,	// 魅力值
	EUUT_Jifen = 516,	// 擂台积分
	EUUT_XingXiuJingHua = 517,	// 星宿精华
};

enum EItemType
{
	/*
	1 普通道具
	2 神将碎片
	3 神将经验丹
	4 精炼经验道具
	5 普通宝箱
	6 N选1宝箱
	7 神将装备碎片
	8 法宝碎片
	9 坐骑碎片
	10 翅膀碎片
	11 活动道具
	12 称号道具
	13 资源道具
	*/
	EItemDieJiaNum = 65000,//物品叠加数量
	EBankItemDieJIaNum = 65000	//
};

struct SItemTemplate
{
    SItemTemplate()
    {
		quality = 0;
		useType = 0;
		level = 0;
		id = 0;
		type = 0;
		pic = 0;
		activityId = 0;
		jiage = 0;
		sortPriority = 0;
		limitTime = 0;
		subValue = 0;
		name.clear();
		describe.clear();
		subVec.clear();
		pScript = NULL;
    }
    
    uint8 quality;	// 品质
    uint8 useType;  // 使用类型
    uint16 level;   // 需求等级
    uint16 id;      // 物品id
    uint16 type;    // 种类
    uint16 pic;     // 图片
	uint16 activityId;  // 活动id
    int jiage;      	// 价格
    int sortPriority;	// 从小到大排序
	uint32 limitTime;	// 额外存在时间
	uint32 subValue;	// 额外数值
    string name;		// 名字
    string describe;	// 说明
	vector<pair<uint16, uint16> > subVec;	// 奖励
	MultiAward subAward;	// 奖励
    CCallScript *pScript;// 特殊物品脚本
};

struct SItemInstance
{
	const static int MAX_XILIAN_ATTR_NUM = 4;
	const static int MAX_CUILIAN_ATTR_NUM = 5;

	const static int MAX_ADD_ATTR_NUM = 8;
	const static int MAX_KAIJIA_ATTR_NUM = 9;

	uint16 num;	
	uint8 level;	//强化等级
	uint8 quality;	//品质
	uint16 tmplId;	// 物品id
	uint8 addAttrNum;	//附加属性数量
	uint8 addAttrStar[MAX_CUILIAN_ATTR_NUM];
	uint16 addAttrType[MAX_CUILIAN_ATTR_NUM];//附加属性类型
	uint32 addAttrVal[MAX_CUILIAN_ATTR_NUM];//附加属性值
	uint32 cuilianUseYB[MAX_CUILIAN_ATTR_NUM];	// 淬炼累计消耗元宝数(炼化石对应元宝)
	
	uint8 xilianStar[MAX_XILIAN_ATTR_NUM];
	uint16 xilianType[MAX_XILIAN_ATTR_NUM];
	uint32 xilianVal[MAX_XILIAN_ATTR_NUM];
	uint8 xilianSaveStar[MAX_XILIAN_ATTR_NUM];
	uint16 xilianSaveType[MAX_XILIAN_ATTR_NUM];
	uint32 xilianSaveVal[MAX_XILIAN_ATTR_NUM];
	char name[MAX_NAME_LEN];	// 1仙器标记
	int extData;

	SItemInstance()
	{
		Clear();
	}
	
	void Clear()
	{
		level = 0;
		quality = 0;
		tmplId = 0;
		addAttrNum = 0;
		extData = 0;
		num = 0;
		memset(addAttrStar,0,sizeof(addAttrStar));
		memset(addAttrType,0,sizeof(addAttrType));
		memset(addAttrVal,0,sizeof(addAttrVal));
		memset(xilianStar,0,sizeof(xilianStar));
		memset(xilianType,0,sizeof(xilianType));
		memset(xilianVal,0,sizeof(xilianVal));
		memset(xilianSaveStar,0,sizeof(xilianSaveStar));
		memset(xilianSaveType,0,sizeof(xilianSaveType));
		memset(xilianSaveVal,0,sizeof(xilianSaveVal));
		memset(cuilianUseYB,0,sizeof(cuilianUseYB));
		memset(name,0,sizeof(name));
	}
	
	bool operator == (const SItemInstance &item)
	{
		if(level == item.level
			&& quality == item.quality
			&& tmplId == item.tmplId
			&& addAttrNum == item.addAttrNum
			&& extData == item.extData
			&& memcmp(addAttrStar,item.addAttrStar,sizeof(addAttrStar)) == 0
			&& memcmp(addAttrType,item.addAttrType,sizeof(addAttrType)) == 0
			&& memcmp(addAttrVal,item.addAttrVal,sizeof(addAttrVal)) == 0
			&& memcmp(xilianStar,item.xilianStar,sizeof(xilianStar)) == 0
			&& memcmp(xilianType,item.xilianType,sizeof(xilianType)) == 0
			&& memcmp(xilianVal,item.xilianVal,sizeof(xilianVal)) == 0
			&& memcmp(xilianSaveStar,item.xilianSaveStar,sizeof(xilianSaveStar)) == 0
			&& memcmp(xilianSaveType,item.xilianSaveType,sizeof(xilianSaveType)) == 0
			&& memcmp(xilianSaveVal,item.xilianSaveVal,sizeof(xilianSaveVal)) == 0
			&& memcmp(cuilianUseYB,item.cuilianUseYB,sizeof(cuilianUseYB)) == 0
			&& memcmp(name,item.name,sizeof(name)) == 0
			)
			return true;
		return false;
	}

	int GetAddAttrType(uint8 pos)
	{
		if(pos < MAX_KAIJIA_ATTR_NUM)
			return addAttrType[pos];
		return 0;
	}
	
	int GetAddAttrVal(uint8 pos)
	{
		if(pos < MAX_KAIJIA_ATTR_NUM)
			return addAttrVal[pos];
		return 0;
	}
	
	void SetAddAttrType(uint8 pos,uint16 val)
	{
		if(pos < MAX_KAIJIA_ATTR_NUM)
			addAttrType[pos] = val;
	}
	
	void SetAddAttrVal(uint8 pos,uint16 val)
	{
		if(pos < MAX_KAIJIA_ATTR_NUM)
			addAttrVal[pos] = val;
	}
	
	int GetItemValue()
	{
		int *p = (int*)addAttrVal;
		return *p;
	}
};

class CItemTemplateManager
{
public:
    //pItem必须是使用new分配出来的
    void AddItem(SItemTemplate *pItem)
    {
        m_itemTemplate.Insert(pItem->id,pItem);
		map<uint8, vector<uint16> >::iterator it = m_typeItem.find(pItem->type);
		if (it == m_typeItem.end())
		{
			vector<uint16> vec;
			vec.push_back(pItem->id);
			m_typeItem[pItem->type] = vec;
		}
		else
		{
			it->second.push_back(pItem->id);
		}
    }
    SItemTemplate *GetItem(uint16 id)
    {
        SItemTemplate *pItem = NULL;
        m_itemTemplate.Find(id,pItem);
        return pItem;
    }
	
	vector<uint16>* GetTypeItem(uint8 type)
	{
		map<uint8, vector<uint16> >::iterator it = m_typeItem.find(type);
		if (it == m_typeItem.end())
			return NULL;
		
		return &it->second;
	}
private:
    CHashTable<uint16,SItemTemplate*> m_itemTemplate;
	map<uint8, vector<uint16> > m_typeItem;
};

///////////////////////////////////////////////////////////////////////////////////////////

struct SLuckyItemData
{
	SLuckyItemData()
	{
		itemId = 0;
		extSuccRatio = 0;
	}
	int itemId;
	int extSuccRatio;
};

struct SEquipQiangHua
{
	SEquipQiangHua()
	{
		equip_pos = 0;
		qh_level = 0;
		basicSuccRatio = 0;
		costList.clear();
		itemSuccRatio.clear();
	}
	int equip_pos;
	int qh_level;
	int basicSuccRatio;
	vector<SCostData> costList;
	vector<SLuckyItemData> itemSuccRatio;
};

struct SEquipQiangHuaAttr
{
	SEquipQiangHuaAttr()
	{
		type = 0;
		qh_level = 0;
		attrList.clear();
	}
	int type;
	int qh_level;
	vector<SAttrData> attrList;
};

struct SEquipShengJieCfg
{
	SEquipShengJieCfg()
	{
		equip_pos = 0;
		equip_level = 0;
		costList.clear();
	}
	int equip_pos;
	int equip_level;	// 人物需求等级
	vector<SCostData> costList;
};

const uint8 CUI_LIAN_ATTR_MAX_NUM = 5;

struct SEquipCuiLianCfg
{
	SEquipCuiLianCfg()
	{
		type = 0;
		for(uint8 i=0;i < sizeof(openLevel)/sizeof(openLevel[0]);i++)
		{
			openLevel[i] = 0;
			attrType[i] = 0;
			attrMaxValue[i] = 0;
		}
	}

	int type;
	int openLevel[CUI_LIAN_ATTR_MAX_NUM];
	int attrType[CUI_LIAN_ATTR_MAX_NUM];
	int attrMaxValue[CUI_LIAN_ATTR_MAX_NUM];
};

struct SRandomAttrNum
{
	SRandomAttrNum()
	{
		attr_num = 0;
		ratio = 0;
	}
	int attr_num;
	int ratio;
};

struct SEquipXLAttrRatio
{
	SEquipXLAttrRatio()
	{
		ratio = 0;
		star = 0;
		min_attrVal = 0;
		max_attrVal = 0;
	}
	int ratio;
	int star;
	int min_attrVal;
	int max_attrVal;
};

struct SEquipXiLian
{
	SEquipXiLian()
	{
		equip_pos = 0;
		costList.clear();
		random_attr.clear();
		ratio_pool.clear();
	}
	int equip_pos;
	vector<SCostData> costList;
	vector<SRandomAttrNum> random_attr;
	vector<SEquipXLAttrRatio> ratio_pool;
};

struct SEquipXiLianAttr
{
	SEquipXiLianAttr()
	{
		type = 0;
		attrList.clear();
	}
	int type;
	vector<SAttrData> attrList;
};

class CEquipCfgMgr
{
public:
	CEquipCfgMgr()
	{
		m_qhBasic.clear();
		m_qhAttr.clear();
		m_shengjieCost.clear();
		m_cuilianCfg.clear();
		m_xilianCfg.clear();
		m_xilianAttrPool.clear();
	}
	~CEquipCfgMgr()
	{
		m_qhBasic.clear();
		m_qhAttr.clear();
		m_shengjieCost.clear();
		m_cuilianCfg.clear();
		m_xilianCfg.clear();
		m_xilianAttrPool.clear();
	}

	bool Init();
	// 强化
	SEquipQiangHua *GetQiangHuaBasicCfg(int equip_pos,int qh_level);
	SEquipQiangHuaAttr *GetQiangHuaAttrCfg(int type,int qh_level);
	// 升阶
	SEquipShengJieCfg *GetShengJieCfg(int equip_pos,int equip_level);
	// 淬炼
	SEquipCuiLianCfg *GetCuiLianCfg(int type);
	// 洗炼
	SEquipXiLian *GetXiLianBasicCfg(int equip_pos,int itemId);
	SEquipXiLianAttr *GetXiLianAttrPool(int type);
	
private:
	bool SetLuckyData(vector<SLuckyItemData> &data,string &str);
	bool SetRandomAttrData(vector<SRandomAttrNum> &data,string &str);
	bool SetRatioPoolData(vector<SEquipXLAttrRatio> &data,string &str);
	int GetCostItemId(vector<SCostData> &data);

	// 强化
	map<int,SEquipQiangHua> m_qhBasic;	// 强化消耗, key=equip_pos|qh_level
	map<int,SEquipQiangHuaAttr> m_qhAttr;	// 强化属性, key=type|qh_level
	// 升阶
	map<int,SEquipShengJieCfg> m_shengjieCost;	// 升阶消耗, key=equip_pos|role_level
	// 淬炼
	map<int,SEquipCuiLianCfg> m_cuilianCfg;	// 淬炼, key=type
	// 洗炼
	map<int,SEquipXiLian> m_xilianCfg;	// 洗炼，key=equip_pos
	map<int,SEquipXiLianAttr> m_xilianAttrPool;	// 洗炼属性池, key=type
};

typedef boost::details::pool::singleton_default<CEquipCfgMgr> SingletonCEquipCfgMgr;



#endif

