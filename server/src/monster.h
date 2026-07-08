#ifndef _MONSTER_H_
#define _MONSTER_H_

#include "self_typedef.h"
#include "item.h"
#include "pet.h"
#include "skill.h"
#include "unit_basic_attr.h"
#include <string>
#include <map>
#include <boost/shared_ptr.hpp>
using namespace std;

struct SSkillData;

enum EMonsterType
{
	EMTNormal,//普通怪
	EMTBaoBao,//宝宝
	EMTTongLing,//统领

	EMT_Treasure,	// 宝藏怪
};

struct SDropItem
{
	uint16 itemId;
	uint16 begin;
	uint16 end;
};

/*
品种系数=当前增幅总值/最大增幅值
当品种系数>=0.8时，为 顶级
当品种系数>=0.6且<0.8时，为 稀有
当品种系数>=0.4且<0.6时，为 优秀
当品种系数>=0.2且<0.4时，为 普通
当品种系数<0.2时，为 平庸
*/
enum EPetQuality
{
	EPQpingyong = 1,
	EPQputong,
	EPQyouxiu,
	EPQxiyou,
	EPQdingji
};

//技能：幻影术。（进入战斗只有一个怪，从第二回合开始，会释放5只幻影，幻影血无限，攻击低，
//被攻击之掉1点血，每回合6只怪均变换位置。释放技能和变换位置前，使用台词“看我移形换位。”）
const uint16 CE_HUAN_YING = 4;

const uint16 CE_FANZHENG    = 5;

//逃跑，有怪物逃跑成功战斗失败
const uint16 CL_TAO_PAO     = 6;

//自爆，目标单位失去40%血。但目标单位处于防御姿态时，只掉1点血。
const uint16 CL_ZI_BAO      = 7;

//攻击防御最低的
const uint16 CL_FIRST_MIN_FANG = 18;

//舍命一击（153），LV100（只对人使用）
//乾坤罩（155），LV100，增援后第一回合对狼王使用。
const uint16 CL_FY_XIONG_LANG = 21;

//死亡战斗结束
const uint16 CL_MONSTER_DIE_END = 25;

//只有神将才可对它有效的伤血。人体对其造成的伤害为真实伤害的1/10
const uint16 CL_ONLY_PET = 29;

//只有神将才可对它有效的伤血。人体对其造成的伤害为真实伤害的1
const uint16 ONLY_PET = 35;

//使用复活技能
const uint16 USE_SKILL_FUHUO = 49;

// 神将攻击为1
const uint16 PET_ATTACK_DAMAGE_1 = 50;
// 紫神将及以上的神将才会造成伤害
const uint16 PET_ATTACK_DAMAGE_2 = 51;
// 紫色一星以上神将才会造成伤害
const uint16 PET_ATTACK_DAMAGE_3 = 52;
// 人物攻击为1
const uint16 USER_ATTACK_1 = 53;
// 100%暴击
const uint16 CL_BAO_JI = 54;
// 紫色及以上神将输出双倍伤害
const uint16 PET_DOUBLE_ATTACK_1 = 55;
// 紫色一星及以上神将输出双倍伤害
const uint16 PET_DOUBLE_ATTACK_2 = 56;

const uint16 CL_MISSION_12 = 62;	// 有魅妖出战第二回合出大招
const uint16 CL_WUXINGCHUANGGUAN1 = 86;
const uint16 CL_WUXINGCHUANGGUAN2 = 87;
const uint16 CL_WUXINGCHUANGGUAN3 = 88;
const uint16 CL_WUXINGCHUANGGUAN4 = 89;
const uint16 CL_WUXINGCHUANGGUAN5 = 90;
const uint16 CL_WUXINGCHUANGGUAN6 = 91;
const uint16 CL_QIYIBOLIZHU = 100;
const uint16 CL_XunChaShi = 103;
const uint16 CL_KuaFu_SJMJ_Boss = 104;
const uint16 CL_TEST_MONSTER_1 = 1001;
const uint16 CL_TEST_MONSTER_2 = 1002;

struct SMonsterTmpl
{
	static const int HUANHUA_NEED_PET_MAXNUM = 3;
	static const int MAX_SKILL_NUM = 4;
	
	uint8 minLevel;
	uint8 maxLevel;
	uint8 petType;	// 1物攻2法攻3防御4气血5速度
	uint8 xiang;
	uint16 petSkillId[MAX_SKILL_NUM];
	
	uint32 id;
	int minQuality;	// 品质min
	int maxQuality;	// 品质max
	int zizhi;		// 资质
	int exp;
	int maxHp;
	int Defence;
	int Speed;
	int Attack;
	int SkillAttack;
	double maxHpRatio;
	double maxHpStepRatio;
	double DefenceRatio;
	double DefenceStepRatio;
	double SpeedRatio;
	double SpeedStepRatio;
	double AttackRatio;//物攻成长min
	double AttackStepRatio;
	double SkillAttackRatio;//技能成长 min
	double SkillAttackStepRatio;

	string petName;
	string monsterName;

	uint16 dropNum;
	SDropItem *pDropItem;	

	uint16 headDropNum;
	SDropItem *pHeadDropItem;//头领掉落

	SMonsterTmpl()
	{
		pDropItem = NULL;
		pHeadDropItem = NULL;
		dropNum = 0;
		headDropNum = 0;
		petType = 0;
		zizhi = 0;
	}
	~SMonsterTmpl()
	{
		if(pDropItem != NULL)
			delete pDropItem;
		if(pHeadDropItem != NULL)
			delete pHeadDropItem;
	}
};

struct SMonsterBossCfg
{
	SMonsterBossCfg()
	{
		id = 0;
		level = 0;
		pic = 0;
		scale = 0;
		quality = 0;
		type = 0;
		attackType = 0;
		strength_type = 0;
		name.clear();
		skills.clear();	// 主动技能
		passive_skills.clear();	// 被动技能
		attr.Clear();
	}

	int id;
	int level;
	int pic;
	int scale;
	int quality;
	int type;
	int attackType;
	int strength_type;
	string name;
	vector<SSkillData> skills;	// 主动技能
	vector<SSkillData> passive_skills;	// 被动技能
	SUnitBasicAttr attr;
};

struct SMonsterInst
{
	SMonsterInst()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		quality = 0;
		type = 0;
		level = 0;
		scale = 100;
		pic = 0;
		attackType = 0;
		hp = 0;
		attr.Clear();
		
		jiaQiangSeal = 0;
		jiaQiangZhongDu = 0;
		jiaQiangBingDong = 0;
		jiaQiangHunShui = 0;
		jiaQiangHunLuan = 0;
		kangSeal = 0;
		kangZhongDu = 0;
		kangBingDong = 0;
		kangHunShui = 0;
		kangHunLuan = 0;
		
		onlySkill = 0;
		noAdd = 0;
		visableId = 0;
		celue = 0;
		chatMsg.clear();
		name.clear();
		skills.clear();	// 主动技能
		passive_skills.clear();	// 被动技能
	}

	bool onlySkill;
	bool noAdd;
	uint8 quality;	// 怪物品质
	uint8 type;
	uint16 level;

	int id;
	uint32 pic;
	int scale;	// 实际值/100
	int attackType;

	int jiaQiangSeal;		// 加强封印
	int jiaQiangZhongDu;	// 加强中毒
	int jiaQiangBingDong;	// 加强冰冻
	int jiaQiangHunShui;	// 加强昏睡
	int jiaQiangHunLuan;	// 加强混乱
	int kangSeal;		// 抗封印
	int kangZhongDu;	// 抗中毒
	int kangBingDong;	// 抗冰冻
	int kangHunShui;	// 抗昏睡
	int kangHunLuan;	// 抗混乱
	int visableId;
	int celue;	//战斗策略
	int64 hp;

	SUnitBasicAttr attr;
	string chatMsg;
	string name;
	vector<SSkillData> skills;	// 主动技能
	vector<SSkillData> passive_skills;	// 被动技能
	
	void Init();
	void AddZhenFaAttr(vector<SAttrData> &attrList);
};

enum PET_QUALITY_TYPE
{
	PQT_GREEN = 1,	// 绿
	PQT_GOLD = 5,	// 金
	PQT_PINK = 6,	// 粉
	PQT_XIAN = 8,	// 仙
	PQT_SHEN = 9,	// 神

	PQT_BLUE = 1,	// 蓝
	PQT_PURPLE = 2,	// 紫
	PQT_ORANGE = 3,		// 橙1
	PQT_ORANGE2 = 4,	// 橙2
	PQT_ORANGE3 = 5,	// 橙3
	PQT_ORANGE4 = 6,	// 橙4
	PQT_RED = 7,	// 红
	
	PQT_MAX,
	PQT_NUM = PQT_MAX-1,
};


struct SMonsterLevelStrength
{
	SMonsterLevelStrength()
	{
		attack = 0;
		attackRatio = 0.0;
		maxHp = 0;
		maxHpRatio = 0.0;
		recovery = 0;
		recoveryRatio = 0.0;
	}
	uint32 attack;
	float attackRatio;
	uint32 maxHp;
	float maxHpRatio;
	uint32 recovery;
	float recoveryRatio;
};

struct SMount // 坐骑
{
	// 坐骑类型
	enum MountType
	{
		None = 0,		// 没有坐骑
		FeiJian = 1,	// 飞剑
		HuLu = 2,		// 葫芦
		JiuWeiHu = 3,	// 九尾狐
		HuoFengHuang = 4,// 火凤凰
		Panda = 5,		// 熊猫
		HengJiShou = 6,	// 哼唧兽
		HuoYanShi = 7,	// 火焰狮
		LianHuaTai = 8,	// 莲花台
		QingYuNian = 9, // 庆余年
		ZhongGuoJie = 10, // 中国结
		JinLinXianZi = 11,// 金鳞仙子
		ZhiYuan = 12,	// 纸鸢
		YouMing = 13,	// 幽冥
		LanFeng = 14,	//蓝风
		FaJian = 15,	//法剑
		YuanBaoEr = 16,	//珠光宝鸡
		ChouYunSuXue = 17,	// 绸云素雪
		
		MaxType,		// 最大值
		MaxNum = MaxType-1,
	};
	// 乘骑状态
	enum MountState
	{
		XiuXi = 0,		// 休息
		ShiYong = 1,	// 使用
	};

	// 对应属性配置
	static const int MAX_MOUNT_NUM = 30;
	static const int MAX_LEVEL = 100;
	static const int MAX_MATERIAL_KIND_NUM = 7; //最大的强化材料种类数
	static const int itemUsedLevelLimit[MAX_MATERIAL_KIND_NUM][5];//七种道具使用强化等级限制 id,minlevel,maxlevel,addexp,moneybase

	// 初始化
	SMount()
	{
		memset(m_id,0,sizeof(m_id));
		memset(m_timeLimit,0,sizeof(m_timeLimit));
		m_level = 0;
		m_useIndex = 0xff;
		m_num = 0;
		m_exp = 0;
	}

	// 基础属性
	uint8 m_id[MAX_MOUNT_NUM];			// 坐骑ID
	uint32 m_timeLimit[MAX_MOUNT_NUM];	// 坐骑时间限制
	uint8 m_level;	// 强化等级
	uint8 m_useIndex;	// 乘骑ID
	uint8 m_num;
	uint32 m_exp;	//当前等级经验值

	bool AddMount(uint8 id,uint32 time=0);
	bool SetUseMountIndex(uint8 index=0xff);
	void RemoveMount(uint8 id);
	bool HaveMount(uint8 id);

	int GetMoveSpeed(uint8 pos=0xff);	// 速度 比率
	bool GetStrengthenMaterialInfo( int itemId,int &minlevel,int &maxLevel, int &exp ,int &moneyBase);

	// 数据库 读取、存储方法
	void SetMount(char *pMount);	// 读取数据，设置坐骑
	void GetMount(string &str);		// 获取序列化坐骑，保存
};

// 翅膀
struct SWing
{
	// 坐骑类型
	enum WingType
	{
		WT_None = 0,	// 没有翅膀
		WT_Wing_1 = 1,	// 可进阶翅膀,"幻彩凌羽"
		WT_Wing_2 = 2,	// "蓝色魅影"
		WT_Wing_3 = 3,	// "紫羽天翔"
		WT_Wing_4 = 4,	// "琉璃天羽"
		WT_Wing_5 = 5,	// "修罗夜影"
		WT_Wing_6 = 6,	// "北冥逍遥游"
		WT_Wing_7 = 7,	// "孔雀大明王"
		WT_Wing_8 = 8,
		WT_Wing_9 = 9,
		WT_Wing_10 = 10,
		WT_Wing_11 = 11,
		WT_Wing_12 = 12,
		WT_Wing_13 = 13,
		WT_Wing_14 = 14,
		WT_Wing_15 = 15,
		WT_Wing_16 = 16,
		WT_Wing_17 = 17,
		WT_Wing_18 = 18,
		WT_Wing_19 = 19,
		WT_Wing_20 = 20,
		
		WT_Wing_21 = 21,	// 活动获得翅膀,"魔神之翼"
		WT_Wing_22 = 22,	// "火凤燎原羽"
		WT_Wing_23 = 23,	// "通天灵狐翼"
		WT_Wing_24 = 24,	// "窗花之蝶舞"
		WT_Wing_25 = 25,	// "炫彩流光羽"
		WT_Wing_26 = 26,	// "步步生红莲"
		WT_Wing_27 = 27,	// "欢舞闹新春"
		WT_Wing_28 = 28,	// "烟花三月"
		WT_Wing_29 = 29,	// "清明双煞"
		WT_Wing_30 = 30,	// "粉红之刃"
		WT_Wing_31 = 31,	// "仙君法翼"
		WT_Wing_32 = 32,	// "天命不凡"
		WT_Wing_33 = 33,	// "流云四方"

		WT_Max,			// 最大值
		WT_MaxNum = WT_Max-1,
	};
	// 使用状态
	enum WingState
	{
		WS_NOT_USE = 0,
		WS_USE = 1,	// 使用
	};

	// 对应属性配置
	static const int MAX_WING_NUM = WT_MaxNum - 1;
	static const int MAX_LEVEL = 8;	// 等级和id对应
	static const int MAX_STAR = 10;
	
	// 初始化
	SWing()
	{
		memset(m_id,0,sizeof(m_id));
		m_level = 0;
		m_useIndex = 0xff;
		m_num = 0;
		m_star = 0;
		m_qh_exp = 0;
	}

	// 基础属性
	uint8 m_id[MAX_WING_NUM];	// 翅膀id
	uint8 m_level;		// 强化等级
	uint8 m_star;		// 强化星级
	uint8 m_useIndex;	// 使用idx
	uint8 m_num;		// 翅膀数量
	uint32 m_qh_exp;	// 强化经验

	uint8 GetJinJieWingId(uint8 &targetId);
	bool AddWing(uint8 id);
	bool SetUseWingIndex(uint8 index=0xff);
	int AddQiangHuaExp(int exp);
	void RemoveWing(uint8 id);
	bool HaveWing(uint8 id);

	int GetLevelUpExp();

	void SetWing(char *pStr);
	void GetWing(string &str);
};


typedef boost::shared_ptr<SMonsterInst> ShareMonsterPtr;

class CMonsterBossManager
{
public:
	CMonsterBossManager()
	{
		m_basicBoss.clear();
		m_varyBossAttr.clear();
	}
	~CMonsterBossManager()
	{
		m_basicBoss.clear();
		m_varyBossAttr.clear();
	}

	bool Init();
	ShareMonsterPtr CreateMonsterBossById(uint32 bossId, int level = 0);
	ShareMonsterPtr CreateRatioMonster(uint32 bossId, double ratio);
	const char *GetMonsterBossName(uint32 bossId);
	int GetMonsterBossMaxHp(uint32 bossId);
	bool GetMonsterBossInfo(uint32 bossId, int &pic, string &name);
	SMonsterBossCfg* GetMonsterBossCfg(uint32 bossId);
	
private:
	bool SetSkillsData(vector<SSkillData> &data,string &str);

	map<uint32,SMonsterBossCfg> m_basicBoss;	// 固定强度, key=bossId
	map<int,SUnitBasicAttr> m_varyBossAttr;	// 等级强度值	key=strength_type|level
};

typedef boost::details::pool::singleton_default<CMonsterBossManager> SingletonMonsterBossManager;




#endif

