#ifndef _UTILITY_H_
#define _UTILITY_H_

#if !defined(_WIN32)
#include <iconv.h>
#endif
#include <string>
#include <vector>
#include <list>
#if defined(_WIN32)
#include <windows.h>
#endif
#include "pet.h"
#include "monster.h"
#include "item.h"
#include "online_user.h"
#include "self_typedef.h"

#define ISSPACE(c) isspace((unsigned char)(c))

using namespace std;

/*
#ifndef min
#define min(a, b)  (((a) < (b)) ? (a) : (b)) 
#endif

#ifndef max
#define max(a, b)  (((a) > (b)) ? (a) : (b))
#endif
*/

const uint8 ZHEN_FA_POS_NUM = 5;

const uint32 Mail_Time_Limit = 3*24*3600;

const int MAX_LEVEL = 100;
const int WORLD_LEVEL_LIMIT_LV = 38;
const int WORLD_LEVEL_DEFAULT = 38;
const int SHI_LIAN_COST_YB2 = 10;
const int SHI_LIAN_COST_YB3 = 30;
const uint8 SHI_LIAN_SHOW_AWARD_NUM = 5;
const uint16 YUANBAO_BILV = 10;
struct SHuoDongAward;
struct HDExchangeInfo;
struct SKuaFu1V1UserData;
struct SChongZhi2OtherAward;
struct Goods;
struct HDPeiZhiInfo;
struct SShenQiConfig;
struct SShenQiPeiYang;
struct SPet;

enum EServerType
{
	EST_LONG = 1,
	EST_MATCH = 2,

	EST_ZoneSerStart = 100,
};

enum EJsonParaType
{
	EJPT_INT = 0,		// int
	EJPT_STRING = 1,	// string
	EJPT_ARRAY = 2,		// array
	EJPT_ARRAYS = 3,	// arrays
	EJPT_INT64 = 4,		// int64
};

enum UniqueIdType
{
	EIT_PET = 1,
	EIT_FABAO = 2,
};

enum EBigMapType
{
	EBMT_BangPaiCopy = 5,	// 帮派副本
};

struct SReplaceStringData
{
	SReplaceStringData(const char *k,const char *val)
	{
		key = (k == NULL) ? "" : k;
		replaceString = (val == NULL) ? "" : val;
	}
	string key;
	string replaceString;
};

struct SBangPaiLog
{
	SBangPaiLog()
	{
		option_roleId = 0;
		time = 0;
		type = 0;
		log.clear();
		time_str.clear();
	}
	uint32 option_roleId;
	uint32 time;
	uint16 type;
	string log;
	string time_str;
};

struct SSystemDoubleExpCfg
{
	SSystemDoubleExpCfg()
	{
		Clear();
	}

	void Clear()
	{
		startHour = 0;
		startMinute = 0;
		stopHour = 0;
		stopMinute = 0;
		expRatio = 0;
	}
	int startHour;
	int startMinute;
	int stopHour;
	int stopMinute;
	int expRatio;	// 系统经验活动倍数
};

struct FestivalRecord {
	FestivalRecord()
	{
		type = 0;
		role_id = 0;
		role_name.clear();
		bang_name.clear();
		level = 0;
		xiang = 0;
		sex = 0;
		num[0] = 0;
		num[1] = 0;
		score = 0;
		isFirst = false;
	}
	uint8 type;
	uint32 role_id;
	string role_name;
	string bang_name;
	uint32 level;
	uint32 xiang;
	uint32 sex;
	uint32 num[2];
	uint32 score;
	bool isFirst;
};

enum EUserMineType
{
	EUMT_Money = 0,
	EUMT_QiangHua = 1,
	EUMT_ShengJie = 2,
	EUMT_CuiLian = 3,
	EUMT_QianNeng = 4,
	EUMT_MAX,
	EUMT_NUM = EUMT_MAX,
};

enum EKF1V1State
{
	EKF_1V1_View = 1,	// 查看
	EKF_1V1_CanVote = 2,	// 可投注(绿)
	EKF_1V1_CannotVote = 3,	// 不可投注(红)
	EKF_1V1_NotInTime = 4,	// 时间未到(灰)
	EKF_1V1_Vote = 5,	// 已投注
};

struct KuaFu1V1VoteData
{
	KuaFu1V1VoteData()
	{
		Clear();
	}
	void Clear()
	{
		voteRoleId = 0;
		money = 0;
	}
	uint32 voteRoleId;	// 投注方id
	uint32 money;		// 投注金额
};

enum EMinePutOutType
{
	EMPOT_Money = 1,
	EMPOT_QianNeng = 2,
	EMPOT_Item = 3,
};

enum GongGaoColorType
{
	GGCT_WHITE = 16,	// 白
	GGCT_GREEN = 3,		// 绿
	GGCT_BLUE = 2,		// 蓝
	GGCT_PURPLE = 7,	// 紫
	GGCT_ORANGE = 8,	// 橙
	GGCT_GOLD = 4,		// 金
	GGCT_PINK = 5,		// 粉
	GGCT_RED = 1,		// 红
	GGCT_WINE_RED = 9,	// 酒红
	GGCT_BROWN = 10,	// 棕
	GGCT_GRAY_SHADOW = 11,	// 灰1
	GGCT_GREEN_SHADOW = 12,	// 绿1
	GGCT_BLUE_SHADOW = 13,	// 蓝1
	GGCT_PURPLE_SHADOW = 14,// 紫1
	GGCT_ORANGE_SHADOW = 15,// 橙1
	GGCT_NUM = 17,
};

enum EExchangeHDType
{
	EEHDT_WildFight = 1,	// 野外挂机
	EEHDT_XunChong = 2,		// 寻神将
	EEHDT_ShiMen = 3,		// 师门
	EEHDT_YaBiao = 4,		// 押镖
	EEHDT_JieBiao = 5,		// 劫镖
	EEHDT_ZhuoGui = 6,		// 捉鬼
	EEHDT_JinBiFB = 7,		// 金币副本
	EEHDT_QiangHuaFB = 8,	// 强化副本
	EEHDT_ShenJieFB = 9,	// 升阶副本
	EEHDT_DangYuan = 10,	// 维护丹园
	EEHDT_Treasure = 11,	// 藏宝图
	EEHDT_CuiLianFB = 12,	// 淬炼副本
	EEHDT_ShiLian = 13,		// 试炼
	EEHDT_ZhanKaiFB = 14,	// 站铠副本
	EEHDT_Fish = 15,		// 钓鱼
	EEHDT_ShuangBeiHuSong = 16,	// 双倍护送
	EEHDT_KunLunShan = 17,	// 诸天幻境
	EEHDT_BP_LingMo = 18,	// 帮派灵魔
	EEHDT_BP_LueDuo = 19,	// 帮派掠夺
	EEHDT_FeiXian = 20,		// 飞仙战场
};

enum WeiXinShareAwardType
{
	WXS_ChongWuShop = 1,	//神将商店
	WXS_Arena		= 2,	//竞技场
	WXS_WeiWoDuXian = 3,	//惟我独仙(天元争霸)
	WXS_ServerList	= 4,	//服务器列表
	WXS_TongTianTa	= 5,	//通天塔成功通关
	WXS_FuBen		= 6,	//副本成功通关
	WXS_PlayerAttr	= 7,	//人物属性
	WXS_YunBiao		= 8,	//运镖结束
	WXS_PetInfo		= 9,	//神将信息页
	WXS_XianYuanCard= 10,	//仙缘卡抽取
	WXS_PurplePet	= 11,	//副本获得紫神将
	WXS_MAX,
	WXS_NUM = WXS_MAX - 1,
};

struct SYaoLingAttr
{
	SYaoLingAttr()
	{
		addAttack = 0;
		addAttackPer = 0;
		addMingZhong = 0;
		addMingZhongPer = 0;
		addRecovery = 0;
		addRecoveryPer = 0;
		addRenXing= 0;
		addRenXingPer = 0;
		addMaxHp = 0;
		addMaxHpPer= 0;
		addShanBi = 0;
		addShanBiPer = 0;
		addBaoJi = 0;
		addBaoJiPer = 0;
		addFanShang = 0;
		addFanShangPer = 0;
		addJianShang = 0;
		addJianShangPer = 0;
		addSpeed = 0;
		addSpeedPer = 0;
	}
	int addAttack;
	int addAttackPer;
	int addMingZhong;
	int addMingZhongPer;
	int addRecovery;
	int addRecoveryPer;
	int addRenXing;
	int addRenXingPer;
	int addMaxHp;
	int addMaxHpPer;
	int addShanBi;
	int addShanBiPer;
	int addBaoJi;
	int addBaoJiPer;
	int addFanShang;
	int addFanShangPer;
	int addJianShang;
	int addJianShangPer;
	int addSpeed;
	int addSpeedPer;
};

struct SMountCollectData
{
	SMountCollectData()
	{
		addAttack = 0;
		addRecovery = 0;
		addMaxHp = 0;
		addSpeed = 0;
		addShanBi = 0;
		addMingZhong = 0;
		addBaoJi = 0;
		addRenXing = 0;
		addFanShang = 0;
		addJianShang = 0;
		zhandouli = 0;
	}
	int addAttack;
	int addRecovery;
	int addMaxHp;
	int addSpeed;
	int addShanBi;
	int addMingZhong;
	int addBaoJi;
	int addRenXing;
	int addFanShang;
	int addJianShang;
	int zhandouli;
};

const int NPC_Distance = 150;

const int TeamLevelLimit = 28;

const int KunLunShanLevelLimit = 30;
const int BaiHuaLevelLimit = 27;
const int HuSongLevelLimit = 29;
const int DailyBossLevelLimit = 40;
const int SaoDangLevelLimit = 35;
const int LingMoLevelLimit = 30;
const int KunLunShanTeamLevelLimit = 50;

const int DAILY_BOSS_MAX_NUM = 12;
const int TONG_TIAN_TA_FLOOR_NUM = 200;
const int TreasureMapNumLimit = 5;
const int TreasureMapLevelLimit = 36;

const int MAX_VIP_LEVEL = 15;

const int FeiXian_LevelLimit = 43;
const int FeiXian_Hour = 21;
const uint8 FeiXian_UpFloorNum = 3;
const uint8 FeiXian_DownFloorNum = 3;
const uint8 OPEN_CHONGZHI_MONEY = 0;	// 0不开启充值1开启充值

const uint8 CREATE_BANGPAI_LEVEL = 22;	// 创建帮派等级限制
const uint8 JOIN_BANGPAI_LEVEL = 22;
const int BANG_PAI_ROB_HOUR = 19;
const int BANG_PAI_ROB_MINUTE_NOTIFY = 5;
const int BANG_PAI_ROB_MINUTE_START = 35;
const int BANG_PAI_ROB_MINUTE_END = 50;
const int BANG_PAI_ENTER_LV = 29;

const int BP_FIGHT_READY_HOUR = 19;
const int BP_FIGHT_READY_START = 1955;	// 19:55
const int BP_FIGHT_READY_END = 2000;	// 20:00
const int BP_FIGHT_START = 2000;		// 20:00
const int BP_FIGHT_END = 2025;			// 20:25
const int BP_FIGHT_BOX_START = 2026;	// 20:26
const int BP_FIGHT_BOX_END = 2030;		// 20:30
const int BP_FIGHT_EXIT_SID = 11;
const int BP_FIGHT_EXIT_X = 1600;
const int BP_FIGHT_EXIT_Y = 1300;

const int KUAFU_EXIT_SID = 70;
const int KUAFU_EXIT_X = 2105;
const int KUAFU_EXIT_Y = 189;

const int BP_FIGHT_XING_DONG_LI_LIMIT = 100;
const int BP_FIGHT_XING_DONG_LI_ENTER = 300;

const int XIUXIAN_PER_NODE_FNUM = 1;	// 修仙每关战斗次数限制
const int XIUXIAN_ROLE_LV_LIMIT = 50;

const int YAO_LING_MAX_LV = 10;
const int YAO_LING_LEVEL_LIMIT = 35;	// 妖灵开启等级

const uint32 OptionTimeSpace = 1;

const int KUAFU_1V1_VOTE_RATIO_H = 150;
const int KUAFU_1V1_VOTE_RATIO_M = 200;
const int KUAFU_1V1_VOTE_RATIO_L = 250;
const int VOTE_NEED_MONEY = 10000;

// 收集数量,伤害,防御,气血,速度,命中,闪避,暴击,韧性,反伤,减伤
const int MOUNT_COLLECT_DATA[][11] = {
	{2,0,50,300,50,225,225,0,0,0,0},
	{3,200,100,0,75,0,0,225,225,0,0},
	{4,300,0,900,100,0,0,0,0,225,225},
	{5,0,0,1200,125,325,0,325,0,325,0},
	{6,0,200,0,150,0,325,0,325,0,325},
	{7,500,250,0,175,425,425,0,0,0,0},
	{8,0,250,1500,200,0,0,425,425,0,0},
	{9,500,0,1500,225,0,0,0,0,425,425},
	{10,1100,450,2400,450,0,0,0,0,0,0},
	{11,0,400,2400,240,0,425,0,425,0,0},
	{12,800,400,0,240,425,0,425,0,0,0},
	{13,800,0,2400,240,0,0,0,0,425,425},
	{14,0,0,3000,300,0,425,0,425,0,425},
	{15,0,500,0,300,425,0,425,0,425,0},
	{16,1000,500,0,300,425,425,0,0,0,0},
	{17,0,500,3000,300,0,0,425,425,0,0},
	{18,1000,0,3000,300,0,0,0,0,425,425},
	{19,1200,600,3600,600,0,0,0,0,0,0},
	{20,1500,750,4500,0,0,500,0,0,0,0},
	};

const int PrivilegePrice[] = {25,128};

const int TeamKunLunShan_EnemyTaskNum = 3;
const int TeamKunLunShan_MonsterTaskNum = 3;
const int TeamKunLunShan_KillEnemyNum[TeamKunLunShan_EnemyTaskNum] = {1,4,7};
const int TeamKunLunShan_KillMonsterNum[TeamKunLunShan_MonsterTaskNum] = {1,3,6};

// 矿时间间隔
const int MINE_TIME_NUM = 8;
const int MINE_TIME[MINE_TIME_NUM] = {1*60,3*60,5*60,8*60,15*60,30*60,8*3600,14*3600};
static const int MINE_MAX_LEVEL = 20;

const uint8 MOBAI_SHOW_NUM = 3;
const uint32 PET_COPY_TIMEOUT_LIMIT = 30;
const int TIPS_SUCCESS_COLOR = GGCT_GREEN_SHADOW;
const int TIPS_FAILURE_COLOR = GGCT_RED;
const int TIPS_WARNING_COLOR = GGCT_GOLD;

const int BANG_NAME_COLOR = GGCT_GOLD;
const int ROLE_NAME_COLOR = GGCT_BLUE_SHADOW;	// 系统公告，角色名
const int ITEM_NAME_COLOR = GGCT_GREEN_SHADOW;	// 系统公告，物品
//const int HUODONE_NAME_COLOR = GGCT_BLUE;	// 系统公告，活动

//                                        1         2           3            4              5            6          7
const int PetQualityColor[GGCT_NUM] = {0,GGCT_BLUE,GGCT_PURPLE,GGCT_ORANGE,GGCT_ORANGE,GGCT_ORANGE,GGCT_ORANGE,GGCT_RED};
const string QualityColorName[GGCT_NUM] = {LANGUAGE_CHY_115,LANGUAGE_CHY_117,LANGUAGE_CHY_118,LANGUAGE_CHY_119,LANGUAGE_CHY_119,LANGUAGE_CHY_119,LANGUAGE_CHY_119,LANGUAGE_CHY_122};

const int TreeQualityColor[GGCT_NUM] = {0,GGCT_GREEN,GGCT_BLUE,GGCT_PURPLE,GGCT_ORANGE};
const string TreeColorName[GGCT_NUM] = {LANGUAGE_CHY_115,LANGUAGE_CHY_116,LANGUAGE_CHY_117,LANGUAGE_CHY_118,LANGUAGE_CHY_119};

const uint8 MAX_FIGHT_SPEED_LEVEL = 4;

const uint8 DrawPetId_Q1[][2] = {{1,12},{2,13},{3,12},{4,13},{5,12},{6,13},{7,12},{8,13}};	// 绿
const uint8 DrawPetId_Q2[][2] = {{9,11},{10,11},{11,11},{12,11},{13,10},{14,10},{15,10},{16,10},{17,8},{120,8}};	// 蓝
const uint8 DrawPetId_Q3[][2] = {{19,16},{20,16},{21,16},{22,16},{115,6},{117,6},{114,6},{26,6},{119,6},{112,2},{113,2},{111,2}};	// 紫
const uint8 DrawPetId_Q4[][2] = {{31,12},{32,12},{33,12},{34,12},{110,8},{109,8},{118,8},{101,8},{108,8},{105,4},{107,4},{106,4}};// 橙

const uint8 JUMP_NOTICE_YB = 1;	// 元宝跳转

const uint8 MAX_PAIMING_NUM = 2;

class CUser;
class CCallScript;
class CScene;
struct SItemInstance;
struct SMonsterInst;

enum EChatType
{
	ECT_World = 1,	// 世界
	ECT_Near = 2,	// 附近
	ECT_Team = 3,	// 队伍
	ECT_BangPai = 4,	// 帮派
	ECT_Private = 7,	// 私聊
	ECT_KuaFu = 11,		// 跨服聊天
	ECT_KuaFuBroadCast = 20,	// 跨服铃铛
	ECT_World_SameZone = 21,		// 世界聊天相同区推送
};


enum EM_WEEKDAY
{
	EM_SUNDAY = 0,
	EM_MONDAY = 1,
	EM_TUESDAY = 2,
	EM_WEDNESDAY = 3,
	EM_THURSDAY = 4,
	EM_FRIDAY = 5,
	EM_SATURDAY = 6,
};

enum HDAwardType
{
	HDAT_MONEY = 60000,  // 金币
	HDAT_BANG_YB = 60001,// 绑元
	HDAT_PET = 60002,
	HDAT_YB = 60003,    // 元宝
	HDAT_EQUIP = 60005,
	HDAT_EXP = 60006,
	HDAT_QIANNENG = 60007,
	HDAT_CHENGHAO = 60008,
	HDAT_WING = 60009,
	HDAT_MOUNT = 60010,
	HDAT_SHENQI = 60011,
	HDAT_CHRISTMASTREE_GROW_VALUE = 60012,				// 圣诞树成长值  只在圣诞活动有效
	HDAT_CHRISTMASTREE_PERSON_VALUE = 60013,			// 圣诞树个人贡献值，只在圣诞活动有效
	HDAT_SHEN_HUN = 60014,  // 神将魂魄
	HDAT_VIP_EXP = 60015,  // 贵族经验
	HDAT_LEITAI_JIFEN = 60016,  // 擂台积分
	HDAT_JINGLIAN_EXP = 60017,  // 精炼经验
	HDAT_BANGPAI_MONEY = 60020,	// 帮派资金
	HDAT_BANG_GONG = 60021,		// 帮贡
	HDAT_AttrType = 60022,	    // 角色属性
	HDAT_PetEquip = 60024,	    // 宠物装备
	HDAT_XingXiuJingHua = 60025,  // 星宿精华
	HDAT_TiLi = 60026,			// 体力
	HDAT_ArenaCnt = 60027,		// 竞技场挑战次数
	HDAT_FaBao = 60028,			// 法宝
	HDAT_FaBaoSS = 60029,		// 搜索次数
	HDAT_HuoYue = 60030,		// 活跃度
	HDAT_BANG_Exp = 60031,		// 帮派经验

	HDAT_JJCMoney = 60050,		// 竞技场货币
	HDAT_KunLunMoney = 60051,	// 昆仑币
	HDAT_RoleExp = 60052,		// 主角经验
	HDAT_ZhuanPanJiFen = 60056,	// 转盘几分
	HDAT_NumType = 60099,	    // 数量类别
};

struct SJumpTo
{
	SJumpTo()
	{
		x = 0;
		y = 0;
		face = 0;
		sceneId = 0;
	}
	SJumpTo(uint16 x1,uint16 y1,uint8 f1,uint16 s1)
	{
		x = x1;
		y = y1;
		face = f1;
		sceneId = s1;
	}
	uint16 x;
	uint16 y;
	uint8 face;
	uint16 sceneId;
};

struct SFootPrintShopData
{
	SFootPrintShopData()
	{
		id = 0;
		name = "";
		buy_type = 0;
		price = 0;
		time = 0;
		rank = 0;
		desc = "";
	}

	int id;
	string name;
	uint8 buy_type;	// 1元宝 2绑元 3金币
	int price;
	int time;	// -1永久 >0秒数
	int rank;
	string desc;
};

struct SFlowerData
{
	SFlowerData()
	{
		itemId = 0;
		buy_type = 0;
		price = 0;
		meili = 0;
		qinmi = 0;
	}
	
	int itemId;
	uint8 buy_type;	// 1元宝 2绑元 3金币
	int price;
	int meili;
	int qinmi;
};

struct SMeiLiData
{
	SMeiLiData()
	{
		Clear();
	}

	void Clear()
	{
		role_id = 0;
		name.clear();
		mei_li = 0;
		title = 0;
	}

	uint32 role_id;
	string name;
	int mei_li;
	uint16 title;
};

typedef vector<SMeiLiData> meiliDatas;
typedef map<int, meiliDatas> sessionMeili;
typedef map<int, meiliDatas>::iterator sessionMeiliIt;

struct SSortMeiLi
{
	bool operator()(SMeiLiData const &b1,SMeiLiData const &b2)
	{
		return b1.mei_li > b2.mei_li;
	}
};

struct SkillInfo
{
	uint16 id;
	uint16 level;
	uint8 tarNum;
};

struct SkillNode
{
	uint16 id;
	uint8 tarNum;
	bool operator>(const SkillNode& data) const
	{
		return tarNum > data.tarNum;
	}
	bool operator<(const SkillNode& data) const		// 默认使用
	{
		return tarNum < data.tarNum;
	}
};

struct SkillSortTarNum
{
	bool operator()(const SkillInfo &s1,const SkillInfo &s2)
	{
		return s1.tarNum > s2.tarNum;
	}
};

struct UserMysteryItem
{
	uint16 id;		//唯一标示id
	uint16 itemId;	
	uint16 itemNum;
	uint8 extValue;
	uint16 price;	//单个价格	
	uint16 rate[9];  //9个位置出现概率
};

struct UserYaoShiItem
{
	uint32 id;		//唯一标示id
	uint32 itemId;	
	uint32 itemNum;
	uint32 price;	//单个价格	
	uint32 rate[12];  //12个位置出现概率
};


struct MinePutoutInfo
{
	MinePutoutInfo()
	{
		setCDYb = 0;
		money = 0;
		qianneng = 0;
		memset(itemId,0,sizeof(itemId));
		memset(itemNum,0,sizeof(itemNum));
	}
	static const int ITEM_NUM = 3;
	int setCDYb;
	int money;
	int qianneng;
	int itemId[ITEM_NUM];
	int itemNum[ITEM_NUM];
};

typedef pair<uint16, uint32> huobiTV;

struct SMailData
{
	SMailData()
	{
		awards.clear();
	}
	void AddAward(uint16 type, uint16 typeId, uint32 num);
	MultiAward awards;
};

enum ETouchItemType
{
	ETIT_Pet = 1,
	ETIT_Item = 2,
};

enum ETouchItemUnlockType
{
	ETIUT_Money = 1,
	ETIUT_YB = 2,
	ETIUT_Item = 3,
};

enum ETouchItemLockType
{
	ETILT_Unlock = 0,
	ETILT_Lock = 1,
};

struct VipConfig
{
	uint8 yaoqianshuNum[2];// 摇钱树免费次数
  	uint8 lingqi;		// 灵气捐献次数
	uint8 arenabuy;		// 竞技场购买次数
	uint8 bossbuy;		// boss挑战购买次数
	uint8 bosstz;		// boss可调整次数
	uint8 openshop;		// 神秘商店各数
	uint8 fxdown;		// 飞仙战场掉层失败场数
	int fxexp;			// 飞仙战场经验加成系数
	uint16 offline;		// 离线经验系数
	uint32 yuanbao;		// 需要的元宝
	uint8 bpzhongzhi;	// 帮派种植个数
	uint8 fengShenNum;	// 封神次数
	uint8 seedtype[4];	// 可种植次数
	uint16 arenatz;		// 竞技场可挑战次数
	uint16 awardt[3];	// 奖励类型
	uint32 awardn[3];	// 奖励数量
	set<int> sweepCopys; // 可扫荡副本
};

extern VipConfig G_VipConfig[16];
uint8 GetVipLevel(int tb);
int GetMysteryOpenlv(int pos);
uint32 GetYaoShiLimitScore(uint32 pos,vector<HDPeiZhiInfo> &peizhiInfo);
bool InitVipConfig();

void SetNextMysteryUpdateTime(uint32 time);
uint32 GetNextMysteryUpdateTime();

void SetNextShenhunUpdateTime(uint32 time);
uint32 GetNextShenhunUpdateTime();

void SetNextYaoShiUpdateTime(uint32 time);
uint32 GetNextYaoShiUpdateTime();
uint32 GetYaoShiItemNum();

int StrToHex(const char *str,uint8 *pHex,int hexLen);
void HexToStr(uint8 *pHex,int hexLen,string &str);
int SplitLine(char **templa, int templatecount, char *pkt);
int SplitLine(char **templa,char *pkt);
int SplitLine(char **templa,char *pkt, char sep);
bool SplitString(const std::string & _src, std::vector<std::string>& _vec, char _ch);
bool SplitString(const std::string& _src, std::vector<std::string>& _vec, const char* chs);

int split_line (char **tem,int temcount, char *pkt);

string SQLFilter(string &sql);
string SQLFilter(const char *sql);

int Random(int min,int max);
bool RandomSequence(int *array,int arrayLen,int max);

string IntToStr(int value);
void GetServerIdList(vector<int> &idList);
void SetServerIdList(vector<int> &idList);

uint32 WritePetBuf(SPet *pPet,uint8 *buf,uint32 bufLen);
uint32 ReadPetBuf(SPet *pPet,uint8 *buf,uint32 bufLen,bool useDefName=false, uint8 extNum = 0);
uint32 ReadItemBuf(SItemInstance *item,uint8 *buf,uint32 bufLen);
uint32 WriteItemBuf(SItemInstance *item,uint8 *buf,uint32 bufLen);

void AddTongBao(unsigned int roleId,int tongbao,int type=0);

uint64 GetTime();

const char *GetProfessionName(uint32 profession);
const char *GetSexName(uint32 sex);

const char *GetTitleName(int tid);
const char *GetShenqiName(int id);
const char *GetFaBaoName(int id);

void SendPKNotice(CUser *pUser);
void SendSysInfo(CUser*,const char *info);
void SendSysInfoRD(CUser*,const char *info); // 发右下角的系统信息
void SendSysInfoFightEnd(CUser*, const char *info); // 发送系统信息，战斗后显示
void SendSysNotice(CUser*, uint8 op = 1); // 发送通知

void SendUserPos(CUser*);
void SendUserPos(CUser *pUser,list<uint32> &userList);

void SendPopMsg(CUser *pUser,const char *info);
void SendSysChannelMsg(CUser *pUser,const char *info);

bool ReadSkillConfig();
bool HuoDongExpInfo();

bool ReadMonsterDistribution();
bool ReadItem();

int GetMonsterFindPathSidById(int monsterId);
bool GetMonsterFindPathPosById(uint16 monsterId,uint16 &x,uint16 &y);
void ClearMonsterDistributionList();

const char *GetCMissionName(uint16 id);

CCallScript *GetScript();

int64 GetLevelUpExp(uint16 level);
int64 GetPetLevelUpExp(uint16 level);

CCallScript *GetScript30000();
CCallScript *GetScript176();
CCallScript *GetScript235();
CCallScript *GetScript250();

bool MakeItemInfo(SItemInstance *item,CNetMessage &msg);

void SetSysYDay(int t);
int GetSysYDay();
void SetSysWDay(int t);
int GetSysWDay();
void SetSysYear(int t);
int GetSysYear();
void SetSysMonth(int t);
int GetSysMonth();
void SetSysMDay(int t);
int GetSysMDay();
void SetSysHour(int t);
int GetSysHour();
void SetSysMinute(int t);
int GetSysMinute();
void SetSysSecond(int t);
int GetSysSecond();

void SetSysTime(time_t t);
void SetSysTimeMs(time_t t);
time_t GetSysTimeMs();
time_t GetSysTime();
uint32_t GetTodayZero();
uint32_t GetTomorrow();
uint32_t GetTomorrowMillsec();
uint32_t GetTodayMillsec();

const char *GetScriptDir();

template<typename Type>
inline Type RandSelect(Type *arr,int num)
{
	return arr[Random(0,num-1)];
}

template<typename Type>
inline Type CalculateRate(Type src,Type numerator,Type denominator)
{
	double temp = numerator;
	temp /= denominator;
	return (Type)(src * temp);
}

template<typename Bit>
inline void BitsetToHex(Bit &bit,uint8 *hex)
{
	for (int i = 0; i < (int)bit.size(); i++)
	{
		if(bit.test(i))
			hex[i/8] |= 1<<(i%8);
	}
}

template<typename Bit>
inline void HexToBitset(uint8 *hex,Bit &bit)
{
	for(int i = 0; i < (int)bit.size(); i++)
	{
		if(hex[i/8] & (1<<(i%8)))
			bit.set(i);
	}
}

template<typename Type>
inline void HexToStr(Type &data,string &toStr)
{
	HexToStr((uint8*)&data,sizeof(data),toStr);
}

void ItemHexToStr(SItemInstance *pItem,string &toStr);
void PetHexToStr(SPet *pPet,string &toStr);

void SaveTrade(uint32 user1,int money1,string &item1,string &pet1,uint32 user2,int money2,string &item2,string pet2);

void SaveUserShopItem(uint32 buyer,uint32 seller,int money,string &item);
void SaveUserShopPet(uint32 buyer,uint32 seller,int money,string &pet);
void ItemCurrencyLog(uint32 userId, int itemId, int num, int moneyType, int useMoney, int lessMoney, int uerType);
void SaveBuyShopItem(uint8 type, uint32 userId, SAwardData& award, SCostData& cost, uint32 lessMoney);
void SaveUseItem(uint32 userId,uint32 itemId,const char *reason,uint8 num,string before = "",string end = "");

struct SPet;
void SaveDelPet(uint32 userId,SPet *pPet);

bool ExchangeIgnoreCharacter(string &str);
bool HaveIgnoreCharacter(string &str);
bool IllegalStr(string &str);

void BeginFightHuoDong();
void EndFightHuoDong();
bool InFightHuoDong();

void NeedUpdatePetDraw();
void NotNeedUpdatePetDraw();
bool isNeedUpdatePetDraw();

int GetLeftDropNum();
void SetLeftDropNum(int num);

int UTF8ToUnicode(char *to,size_t toLen,char *from,size_t fromLen);
int UnicodeToUTF8(char *to,size_t toLen,char *from,size_t fromLen);
int GbkToUnicode(char *to,size_t toLen,char *from,size_t fromLen);
int UnicodeToGbk(char *to,size_t toLen,char *from,size_t fromLen);
int GbkToUTF8(char *to,size_t toLen,char *from,size_t fromLen);
int UTF8ToGbk(char *to,size_t toLen,char *from,size_t fromLen);

void SetClearDayTime(time_t t);
time_t GetClearDayTime();
void SetClearWeekTime(time_t t);
time_t GetClearWeekTime();
void SetClearMonthTime(time_t t);
time_t GetClearMonthTime();

bool IsIllegalMsg(const char *msg);
void IllegalMsgDeal(string &msg);
void SendSysInfoToGroup(int sceneGroup,const char *info);
void SysInfoToGroupUser(int sceneGroup,const char *info);

string MakeStringColor(const char *pStr,int color=GGCT_WHITE);
string MakeStringColor(string str,int color=GGCT_WHITE);

uint8 GetQuality(int fen,uint8 num);

uint8 GetChongKaiQuality(SItemInstance *pItem);

void SendMsgToAllUser(CNetMessage &msg);
void SendSceneMsg(CNetMessage &msg,int sceneId);
void SendSceneMsg(CNetMessage &msg,CScene *pScene);

uint8 GetPetSpeed(int qinmi);

uint8 GetRoleName(uint32 id,char *name);

uint32 GetRoleId(const char *name,uint8 &level);

void AddMoney(uint32 roleId,int money);

//字符串转换十六进制
int UnHexify(unsigned char *obuf, const char *ibuf);

//十六进制转化字符串
void Hexify(unsigned char *obuf, const unsigned char *ibuf, int len);

bool Compress(uint8 *pInBuf,uint32 inLen,string &compress);

bool UnCompress(const char *inStr, uint8 *pOutBuf, uint32 &outLen);
int UnCompressEx(const char *inStr, uint8 *pOutBuf, uint32 outLen);

bool AddPackage(uint32 roleId,SItemInstance &item);

void SetBitSet(uint32 roleId,uint16 bitset,bool set);

inline int atomic_exchange_and_add( int * pw, int dv )
{
#if defined(_WIN32)
	return (int)InterlockedExchangeAdd((volatile LONG*)pw, (LONG)dv);
#else
	int r;

	__asm__ __volatile__
		(
		"lock\n\t"
		"xadd %1, %0":
	"=m"( *pw ), "=r"( r ): // outputs (%0, %1)
	"m"( *pw ), "1"( dv ): // inputs (%2, %3 == %1)
	"memory", "cc" // clobbers
		);

	return r;
#endif
}

inline void atomic_increment( int * pw )
{
#if defined(_WIN32)
	InterlockedIncrement((volatile LONG*)pw);
#else
	__asm__
		(
		"lock\n\t"
		"incl %0":
	"=m"( *pw ): // output (%0)
	"m"( *pw ): // input (%1)
	"cc" // clobbers
		);
#endif
}

inline int atomic_conditional_increment( int * pw )
{
#if defined(_WIN32)
	for(;;)
	{
		LONG oldValue = *(volatile LONG*)pw;
		if(oldValue == 0)
			return 0;
		LONG newValue = oldValue + 1;
		LONG prev = InterlockedCompareExchange((volatile LONG*)pw, newValue, oldValue);
		if(prev == oldValue)
			return oldValue;
	}
#else
	int rv, tmp;

	__asm__
		(
		"movl %0, %%eax\n\t"
		"0:\n\t"
		"test %%eax, %%eax\n\t"
		"je 1f\n\t"
		"movl %%eax, %2\n\t"
		"incl %2\n\t"
		"lock\n\t"
		"cmpxchgl %2, %0\n\t"
		"jne 0b\n\t"
		"1:":
	"=m"( *pw ), "=&a"( rv ), "=&r"( tmp ): // outputs (%0, %1, %2)
	"m"( *pw ): // input (%3)
	"cc" // clobbers
		);

	return rv;
#endif
}

void BeginELong();
void EndELong();
bool InELong();

void UpdateUserInfo(CUser *pUser,uint8 uType);
void GetLoginLogTab(char *buf,size_t);

string GetUserInfoTab(int serverId);

uint64 GetMillisecond();

void ToUpper(string &str);
void ToLower(string &str);

void Sha256(string &str);
char *ToURL(char *des,const char *src);
void ChatCharacterLimit(string &str,int limit);
void oauth_hmac_sha1(const char *date,const size_t ldate,const char *key,const size_t lkey,char *out);
char oauth_b64_encode(unsigned char u);
void oauth_encode_base64(int size, const unsigned char *src,char *out);
void GetQQOauthURL(string hostName,string &token,string &tokenSecret,string &nonce,char *time,string &result);
void GetUserSuperQQInfo(string &openid,string hostName,string &token,string &tokenSecret,string &nonce,char *time,string &superUrl);
void GetJsonValue(string& data, string key, string& value, bool hasColon = false);
void GetJsonData(string& src, string& data);
int Connect(const char *ip,uint16 port);
void GeeBuyShopTab(char *buf,size_t bufSize);

bool IsItemCanMerge(uint16 type);

void SendBangPai_TreeRobAward(CUser *pUser,SMailData *pMail);

void SendHuoDongFlag(uint8 type,uint8 flag);
void SendHuoDongFlag_Single(CUser *pUser,uint8 type,uint8 flag,uint32 time=0);
void SendTongTianTaInfo(CUser *pUser);
void SendTongTianTaFirstCompleteInfo(CUser *pUser,uint16 level,int item1,int num1,int item2=0,int num2=0,int item3=0,int num3=0);

int GetItemDieJiaNum(int itemId); // 获取道具叠加上限
int GetItemDieJiaNum(int itemId,int itemType); // 获取道具叠加上限

int64 GetHuoDongRobExpRatio(int64 exp,uint16 srcLv,uint8 robberLv);
void GetYaYunBiaoCheRobExp(CUser *pSrcUser,uint8 robberLevel,int64 &exp,int &money);

uint8 GetHeChengItemNum(uint16 itemId);
uint16 GetHeChengTargetItemId(uint16 itemId);

void ReSetAddPetLevel(uint16 &level);
uint16 GetFightLimitTurn(uint16 fightType);

int GetEquipQualityByItemLevel(int itemLv);
int GetEquipQiangHuaLevelQuality(int qhLevel);

void GetHuoYueDuInfo(CUser *pUser);

void LoadSysDoubleExpCfg();
bool InSysDoubleExp();
int GetSysDoubleExpNotifyTime();
int GetSysDoubleExpStartTime();
int GetSysDoubleExpEndTime();
int GetSysDoubleExpRatio();

uint16 GetVipDailyYB(uint8 vipLevel);

void GetPetCopyDropData_Primary(CUser* pUser,uint8 &type,uint16 &Id,uint8 &quality);

void GetPetCopyDropData(CUser *pUser,int difficulty,uint8 &type,uint16 &id,uint8 &quality,uint8 &qualityLevel);

void RiChangFuBenCheckStageGoal(CUser* pUser);

void MakePetMsg(CUser* pUser,CNetMessage& msg,int petId,int level=1,int star=1);

void MakePetDiffInfo(SPet *pSrcPet,SPet *pNewPet,CNetMessage &msg);

bool IsSeedItem(uint16 itemId);

bool LoadMoBaiLog();
void SaveMoBaiLog(int option_roleId,int roleId,const char *pStr);
void GetMoBaiLogList(int roleId,list<SBangPaiLog> &log);

void ChangeClientGuaJiState(CUser *pUser,uint8 state);	// state 1 开始挂机 2 停止挂机
void ShowReviveChooseInCopy(CUser *pUser,uint8 difficulty);
int GetPetCopyReviveYB(uint8 difficulty,uint8 dieNum);
void PushClientConfigFile(CUser *pUser);
int GetPetCopyMonsterId(uint8 difficulty,bool specPet=false);

int AccelerateSaoDangCostYB(int leftTime);

void GetFastRoleName(int sex,string &name);
vector<uint16> GetFeiXianAward(int floor);

void GetExchangeTarItem(uint8 type,uint16 id,uint8 &srcNum,uint16 &tarItemId,uint16 &tarItemNum);
int GetFeiXianExpByFloor(int floor,int level);

bool IsCanReturnTeamScene(int sceneId);
void NoticeClientChargeResult(uint32 roleId,uint8 res,int money,const char *str);
uint8 GetXunChaShiNpcPos(int npcId);
int GetXunChaShiNpcId(uint8 pos);
int GetXunChaShiLevel();

uint8 GetLogonDayNum();

bool MakeExchangeMsg(CUser *pUser,CNetMessage &msg);
bool ExchangeItem(CUser *pUser,CNetMessage &msg);
bool GetExchangeAward(CUser *pUser,CNetMessage &msg);
int GetDropExItemDayIdx();

void UpdateWorldLevel();
int GetWorldLevel();
void SetWorldLevel(int lv);
int GetPrimaryPetCopyRatio(CUser *pUser);

void ShowJumpNotice(CUser *pUser,uint8 type);

bool InDoubleExpHuoDong();
bool InDoubleMoneyHuoDong();
bool InDoubleItemNumHuoDong();

void AddHuoDongAward(CUser *pUser,int type,uint32 awardType,uint32 awardNum,uint16 petQuality=0,uint16 petQualityLv=0,bool isShow = true,bool isSave = true,char *pStr=NULL);
void AddHuoDongRewardDirect( CUser *pUser, uint32 type,uint32 idx,bool isShow = true);
void SendHuoDongAwardMail(uint32 roleId,int level,SHuoDongAward &hdData,const char *pStr,int type,double ratio = 1.0);

void GetXCDSJArrayInfo(uint8 &max_stage,uint8 &item_num);
uint16 GetXCDSJRewardInfo(int i, int j, int k);
uint16 GetXCDSJConditionInfo(int i, int j);

void GetQZLHLArrayInfo(uint8 &max_stage,uint8 &item_num);
uint16 GetQZLHLRewardInfo(int i, int j, int k);
uint16 GetQZLHLConditionInfo(int i, int j);

void NoticeHuoDongHotPoint(CUser *pUser, uint32 huodongId);

void MakeHuoDongList(CNetMessage &msg, CUser *pUser);
bool GetHuoDongHotPoint(uint32 id, CUser *pUser);

CDatabaseSql* GetLoginDb(); // 获取登陆服务器数据库

void SaveDate(CUser *pUser,int type,int data,const char *str=NULL);
void SaveDate(int user_id,int type,int data,const char *str=NULL);
void SaveDate(int user_id,int type,vector<int> &data,vector<string> &str);

void MakeMountCollectMsg(CNetMessage &msg);

void MakeTitleRoleData(uint32 roleId,CNetMessage &msg);

uint32 GetAttrPower(vector<SAttrData>& atts);
void SetOffLineTitle(uint32 roleId,uint8 title);

void UniversalMakeAwardMsg(uint16 type, uint32 value, uint16 ext1, uint16 ext2, CNetMessage &msg);
void MakePetMsg(uint32 petId, uint8 star, uint8 level, CNetMessage &msg);
void MakeWingMsg(uint8 wingId, CNetMessage &msg);
void MakeTitleMsg(uint32 title,CNetMessage &msg);
void MakeMountMsg(uint32 title,CNetMessage &msg);

void GiveFestivalPresent(CUser *pUser,uint32 roleId, vector<struct GoodsInfo> &info, CNetMessage &msg);
uint32 GetRoleIdByName(string name);
bool GetHuoDongNewSign(uint32 huodongType);
string GetMonthCardLastTime(time_t lastGetTime);
void SetShaoDangString(stringstream &stringAward, struct SShaoDangAward &award);
uint8 MakeAwardMsg(CUser *pUser,SHuoDongAward &award,uint32 huodong_type,CNetMessage &msg, uint32 *totalYB = NULL);
void MakeExchangeInfoMsg(CUser *pUser,HDExchangeInfo &info,CNetMessage &msg,uint32 type,map<uint32,uint32> *goods=NULL);
bool MakeDoExchangeMsg(CUser *pUser,HDExchangeInfo &info,CNetMessage &msg, uint32 type, uint8 materialIdx);


bool LoadRandomBoxCfg();  //加载随机宝箱配置
bool TeamCanEnterBangPai(CUser *pUser);
bool TeamCanEnterBangPaiFightScene(CUser *pUser);

int GetNewTimeSecond(int curTime,int endTime);
//void UpdateBZXingDongLi(CUser *pUser);
void AddBangZhanFightWinAward(CUser *pUser);
void ShowBangZhanIcon_Single(CUser *pUser);

bool CanJoinTeamInBangPaiScene(CUser *pHead,CUser *pJoin,string &str);
void GetXiuXianRobotData(int idx,uint8 &xiang,uint8 &sex);
ShareUserPtr GetXiuXianRobotByIdx(int idx);
void LeaveBangPaiTransport(CUser *pUser);
bool GetChongZhiFanYBDataId(uint32 huodongType, uint32 &totalCZDataId,uint32 &maskDataId);
bool GetHongLiJiFenDataId(uint32 huodongType, uint32 &timeDataId, uint32 &jifenDataId);
void GetHongLiJiFenHDs(vector<uint32> &HDlist);
bool GetHongLiDataId(uint32 huodongType, uint32 &timeDataId, uint32 &leijiDataId,uint32 &maskDataId);
bool GetLevelFanLiDataId(uint32 huodongType, uint32 &totalCZDataId, uint32 &maskDataId);

bool GetMeiRiXiaoFeiYBDataId(uint32 huodongType,uint32 &totalXFDataId,uint32 &maskDataId);

bool IsIOSAD(int ad);
int GetYB_ByMoney(int money);
int GetMoney_ByYB(int yb);

int GetCharacterNum(string &name);

ShareUserPtr GetShiLianRobotByZhandouli(int zhandouli);

uint32 CurlZeroTime(uint32 time);
void AddBoxAward(CUser *pUser,uint32 item_id ,uint32 awardType,uint32 awardNum,uint16 petLevel,uint16 petStar, bool isShow);

void MakeXinShiError(const char *str,CNetMessage &msg);

int CopyDataToBuf( char* buf,const void* data,size_t size,int off );
void CopyDataToBuf(char *buf,const void *data,size_t size,uint32 &off,uint32 maxLen);
int CopyCharToBuf( char* buf,const char* data,int &off );
int ReadDataFromBuf( char* buf,void* data,size_t size,int off );
void ReadDataFromBuf(char *buf,void *data,size_t size,uint32 &off,uint32 maxLen);
int ReadCharFromBuf( char* buf,char* data,int off );
bool SendInfoToMe(CUser *pUser,int type,const char *pattern,...);
bool SendSysInfoToMe(CUser *pUser,int type,const char *pattern,...);
void SendSysInfoToAll(bool checkTime,int type,const char *pattern,...);

bool InFuncionLevelReadyTime(int sysId);
bool InFuncionLevelTime(int sysId);

void EnterTeamKunLunShan(CUser *pUser);

bool InKuaFu1V1FinalsTime();
int GetKuaFu1V1FinalsTimeIndex();
int GetKuaFu1V1TurnStartTime();
string GetKuaFu1V1MailString(bool win);
void GetKuaFuPaiMingList(int timeIdx, SKuaFu1V1UserData(*&p)[MAX_PAIMING_NUM], int &size);
void GetKuaFuPaiMingListOld(int timeIdx,SKuaFu1V1UserData (*&p)[MAX_PAIMING_NUM],int &size);
bool InKuaFu1V1FinalsPaiMingByIdx(int roleId,int timeIdx,int &roomIdx);
int GetKuaFu1V1VoteStateIdByNode(int type,int nodeIdx,int roleId,KuaFu1V1VoteData &data);
int GetKuaFu1V1VoteStateIdByNodeOld(int type,int nodeIdx,int roleId,KuaFu1V1VoteData &data);
void GetKuaFu1V1TotolMoneyByNode(int type,int nodeIdx,KuaFu1V1VoteData &role1,KuaFu1V1VoteData &role2);
void GetKuaFu1V1TotolMoneyByNodeOld(int type,int nodeIdx,KuaFu1V1VoteData &role1,KuaFu1V1VoteData &role2);
int GetKuaFu1V1TotolMoneyByRoleId(int roleId);
bool AddKuaFu1V1VoteDataByNode(CUser *pUser,int type,int nodeIdx,int voteId,uint32 money);
void GetKuaFu1V1FightPlayers(int timeIdx,int roomIdx,SKuaFu1V1UserData &player1,SKuaFu1V1UserData &player2);
void AddKuaFu1V1PlayerWinNum(int timeIdx,int roleId);
void PushKuaFu1V1TurnRankData();
void SetKuaFu1V1WinnerData(int timeIdx,int roomIdx,int winnerId);
void Enter1V1FinalsScene(CUser *pUser);
void MakeKuaFu1V1PanelInfo(CUser *pUser,uint8 type,CNetMessage &msg);
void MakeKuaFu1V1PanelInfoOld(CUser *pUser,uint8 type,CNetMessage &msg);
void MakeKuaFu1V1NodeInfo(CUser *pUser,uint8 type,uint8 nodeIdx,CNetMessage &msg);
void MakeKuaFu1V1NodeInfoOld(CUser *pUser,uint8 type,uint8 nodeIdx,CNetMessage &msg);
void KuaFu1V1Vote(CUser *pUser,uint8 type,uint8 nodeIdx,uint32 voteId,CNetMessage &msg);
void SendKuaFu1V1LeftTime(CUser *pUser=NULL);
void SendKuaFu1V1SceneLeftTime(CScene *pScene,CUser *pUser=NULL);
void SendKuaFu1V1SceneScore(CUser *pUser);
void UpdateKuaFu1V1SceneScore(CScene *pScene);
void SendKuaFu1V1Award();
void ReSetKuaFu1V1Data();
void CheckKuaFu1V1Players();
void AddUserTitle(int roleId,int title);
bool CheckKuaFu1V1_FirstResult();
#ifdef KUA_FU
void LoadKuaFu1V1FinalUserData();
bool ReadKuaFu1V1FinalDataFromDB();
void SaveKuaFu1V1FinalData();
#endif

void AddKuaFu1V1RoleData_TEST(CUser *pUser);

void CheckBangPaiId();
void GetKuaFuConfig(string &ip,int &port);
bool SendKuaFuData(int serverId,int sigId,string &signature,int sock);
bool InKuaFu();
void UpdateKuaFuOpenState();
bool IsOpenKuaFu();
bool CanGetKuaFuInfo();
void SendLongQuerySql(const char *sql);
uint16 GetToMapId(int sceneId,int srcSceneId);
bool IsEffectiveKunLunShanPos(int x,int y);

void MsgForwardToServers(CNetMessage &msg);

void SysInfoToAllUserGunDong(CUser *pUser,const char *str);
void SysInfoToAllUserGunDong(uint32 roleId,const char *name, uint8 vipLv,uint8 xiang,uint8 sex,const char *str);


bool CheckPersonalName(string &pStr);
bool CheckPersonalID(const char *pID);








#ifdef KUA_FU
void CopyUserDataToKuaFu(int serverId,int serverZoneId,uint32 id,string &signature,int index,int sock);
void CopyKuaFuDataToGameServer(int roleId,int serverId);
bool SendBackToGameServer(int serverId,int sigId,string &signature,int sock);

void QueryGameServer_BangPaiInfo(int serverId,int bangId);
void QueryGameServer_BangPaiExist(int serverId,int bangPaiId);
void QueryGameServer_BangPaiByBangId(int serverId,int bangId);
void QueryGS_BangZhan_FirstInfo();

void CheckKuaFuQieCuoMission(CUser *pWin,CUser *pOther);
void SendLongQuerySqlToAllDB(const char *sql);
void SysGongGaoToAllServer(const char *msg);

struct StKuaFu1vs1SaveEnemyInfo;
int GetKuaFu1vs1RobotByZhandouli(int zhandouli);
bool CopyKuaFu1vs1RobotInfo(int rank ,StKuaFu1vs1SaveEnemyInfo &info);
ShareUserPtr GetKuaFu1vs1EnemyInfo(StKuaFu1vs1SaveEnemyInfo &info);
int GetKuaFuBangZhanType();

#endif

void GetGameServerData(map<int,SKuaFuServerData> &data);
void GetGameZoneIdList(vector<int> &data);
void ReadGameServerData();

int GetServerZone(int serverId);
void SetSelfZoneId(int zoneId);
int GetSelfZoneId();

void UserMsgToAllServer(CUser *pUser,const char *msg);
void KFChatMsgToAllServer(CNetMessage &msg);

string GetKuaFuRoleName(CUser *pUser);


string GetKuaFuRoleNameByServerID(string name,int serverId);

enum ShenQiType
{   
	SHENQI_NONE			= 0,	//没有神器
	SHENQI_SHUANTIANSUO = 1,	//拴天链
	SHENQI_LIUGUANGQIAN = 2,	//流光琴
	SHENQI_BUGUIYAN		= 3,	//不归砚
	SHENQI_HUANSILING	= 4,	//幻思铃
	SHENQI_MINSHENGJIAN = 5,	//悯生剑
	SHENQI_HAOTIANTA	= 6,	//昊天塔
	SHENQI_FUCHENZHU	= 7,	//浮沉珠
	SHENQI_XUANSHUIYU	= 8,	//玄水玉
	SHENQI_ZHEXIANSAN	= 9,	//谪仙伞
	SHENQI_XUANZHENCHI	= 10,	//玄镇尺
	SHENQI_MAX,					//最大值
	SHENQI_NUM = SHENQI_MAX-1,
};
enum ShenQiState
{   
	SHENQI_NOT_GET	= 0,	//未获得
	SHENQI_NOT_USE	= 1,	//休息
	SHENQI_USE		= 2,	//使用
};

struct StShenQiItemActiveInfo
{
	void init()
	{
		shenqi_id = 0;
		item_id = 0;
		item_num = 0;
	}
	int shenqi_id;
	int item_id;
	int item_num;
};

const int SHENQI_MAX_LEVEL = 10; //神器培养等级 1~SHENQI_MAX_LEVEL
const int SHENQI_MAX_STAR = 5;	//神器培养星数 0~SHENQI_MAX_STAR

const StShenQiItemActiveInfo shenQiItemActiveInfo[] ={
//	shenqi_id	item_id	num
	{ 8	,	2848	,	50	},
	{ 9 ,	2887	,	50	},
	{ 10 ,	2908	,	50	}

};
bool GetShenQiEnhanceInfo( int level ,int star,SShenQiPeiYang &info);
bool GetShenQiItemActiveInfo(int shenqi_id, StShenQiItemActiveInfo &info);
bool AddPackageByID( CUser* pUser,int id,int num,bool isShow= false,bool isFightEnd=false);

void MakeShenQiMsg(uint32 shenqiId,CNetMessage &msg);

string GetQinMiStr(uint32 role1,uint32 role2);
void GetQinMiRoleId(string &str,uint32 &role1,uint32 &role2);
void AddRoleTitle(uint32 roleId, int titleId);
void DeleteRoleTitle(uint32 roleId, int titleId);

// 1 鲜花特效
void ShowSpecialCartoon(int op,int type);

int GetMoGuCurrentDayIdx(uint32 startTime);

void SaveChatLog(CUser    *pUser,int channel,const char *pStr);




double round(const double data,int digits);



enum INIT_ATTR_TYPE
{
	ATTR_NONE		= 0,
	ATTR_TIZHI		= 1,	//体质
	ATTR_LILIANG	= 2,	//力量
	ATTR_MINJIE		= 3,	//敏捷
	ATTR_LINGLI		= 4,    //灵力
	ATTR_NAILI		= 5,    //耐力
	ATTR_DAM		= 6,	//攻击
	ATTR_DEF		= 7,	//防御
	ATTR_HP			= 8,	//气血
	ATTR_SPEED		= 9,	//速度
	ATTR_MINGZHONG	= 10,	//命中
	ATTR_LIANJI		= 11,	//连击
	ATTR_BANG		= 12,	//暴击
	ATTR_FANJI		= 13,	//反击
	ATTR_FANSHANG	= 14,	//反伤
	ATTR_JIANSHANG	= 15,	//减伤
	ATTR_GEDANG		= 16,	//格挡
	ATTR_RENXING	= 17,	//韧性
	ATTR_ZHAOJIA	= 18,	//招架
	ATTR_SHANBI		= 19,	//闪避

	ATTR_TIZHI_PER		= 20,	//体质提升万分比
	ATTR_LILIANG_PER	= 21,	//力量提升万分比
	ATTR_MINJIE_PER		= 22,	//敏捷提升万分比
	ATTR_LINGLI_PER		= 23,	//灵力提升万分比
	ATTR_NAILI_PER		= 24,	//耐力提升万分比
	ATTR_DAM_PER		= 25,	//攻击提升万分比
	ATTR_DEF_PER		= 26,	//防御提升万分比
	ATTR_HP_PER			= 27,	//气血提升万分比
	ATTR_SPEED_PER		= 28,	//速度提升万分比
	ATTR_MINGZHONG_PER	= 29,	//命中提升万分比
	ATTR_LIANJI_PER		= 30,	//连击提升万分比
	ATTR_BANG_PER		= 31,	//暴击提升万分比
	ATTR_FANJI_PER		= 32,	//反击提升万分比
	ATTR_FANSHANG_PER	= 33,	//反伤提升万分比
	ATTR_JIANSHANG_PER	= 34,	//减伤提升万分比
	ATTR_GEDANG_PER		= 35,	//格挡提升万分比
	ATTR_RENXING_PER	= 36,	//韧性提升万分比
	ATTR_ZHAOJIA_PER	= 37,	//招架提升万分比
	ATTR_SHANBI_PER     = 38,   //闪避提升万分比


	ATTR_P_DAM	= 39,	//物攻
	ATTR_M_DAM	= 40,	//法攻
	ATTR_MAX,
};
struct StInitAttrInfo
{
	public:
	StInitAttrInfo()
	{
		init();
	}
	void init()
	{
		memset(attr,0,sizeof(attr));
	}
	StInitAttrInfo& operator =(const StInitAttrInfo &data);
	StInitAttrInfo operator +(const StInitAttrInfo &data);
	bool set(int type,int value);
	int get( int type);
	bool add(int type,int value);
	void showdetail();
	private:
	int attr[ATTR_MAX-1]; //与enum INIT_ATTR_TYPE 对应

};
inline StInitAttrInfo& StInitAttrInfo::operator =(const StInitAttrInfo &data)
{
	for(int counter = 0; counter <(int)ATTR_MAX-1 ; ++counter)
	{
		attr[counter] = data.attr[counter];  
	}
	return *this;
}

inline StInitAttrInfo StInitAttrInfo::operator +(const StInitAttrInfo &data)
{
	StInitAttrInfo ret;
	for(int counter = 0; counter <(int)ATTR_MAX-1 ; ++counter)
	{
		ret.attr[counter] = attr[counter] + data.attr[counter];  
	}
	return ret;
}
inline bool StInitAttrInfo::set(int type ,int value)
{
	if(type <= ATTR_NONE || type >= ATTR_MAX )
		return false;
	attr[type-1] = value;
	return true;
}

inline int StInitAttrInfo::get(int type)
{
	if(type <= ATTR_NONE || type >= ATTR_MAX )
		return 0;
	return attr[type-1];
}

inline bool StInitAttrInfo::add(int type ,int value)
{
	if(type <= ATTR_NONE || type >= ATTR_MAX )
		return false;
	attr[type-1] = attr[type-1] + value;
	return true;
}
inline void StInitAttrInfo::showdetail()
{
	cout<<"------------------attr show details---------------------"<<endl;
	for(int counter = 0; counter <(int)ATTR_MAX-1 ; ++counter)
	{
		if(attr[counter])
			cout<<counter+1 <<" : "<<attr[counter]<<endl; 
	}
	cout<<"------------------------------------------------------"<<endl;
}
bool ChongZhiToOtherSendAward(int roleId,int friendId,SChongZhi2OtherAward &data);
bool GetJiJinFanLiDataId(uint32 huodongType, uint32 &buyRecordDataId, uint32 &startTimeDataId,uint32 &buyFirstTimeDataId,uint32 &getMaskDataId);
string SendWinXinShareMail(CUser *pUser, uint32 awardType, uint32 awardNum);

void GetZhunXianGeLvUpInfo(int nextLv,int &yingxiangli,int &money,int &ratio);
int GetZXG_MaxMissionNum(int lv);
string GetShangXianTypeName(int type);

void CreateMiJingBossBuff(int buffNum,vector<uint16> &buffList);


float GetQunXianHpRatio(int ratio);
int GetQunXianAwardIdx(int floor);
bool HaveQunXianAwardCanTake(CUser *pUser);

void AddHDShowLog(uint32 giveRoleId, vector<string> &giveLog, uint32 getId, vector<string> &getLog, uint32 huodong_type);

const char *GetWingName(int wingId);
const char *GetMountName(int mountId);

void GetHDMsgGoods(vector<Goods> &goods,CNetMessage &msg);
string CreateJiaoYiRecord(string buyer_name,int sell_yb,int buy_glod,uint32 state);
string GetAwardName(uint32 awardId);
int GetRoleAwardNum(CUser *pUser,uint32 awardId);
void CostAward(CUser *pUser,uint32 awardId,int awardNum);
string GetAwardsName(uint32 *awardIds,uint32 *awardNums,uint32 size);
string GetAwardsString(vector<SAwardData> &award);

void SendHDNotInPaiHangInScoreAward(uint8 festivalType, map<uint32, uint32> &getAwardRole,uint32 hd_type);
void AddFestivalRecord(vector<FestivalRecord> &record,uint32 hd_type);
void HDGivePresent(CUser *pUser,uint32 roleId, vector<GoodsInfo> &info, CNetMessage &msg,uint32 hd_type);
void GetZhenYingPKList(list<uint32> &idList,uint32 myZhenYingId,CNetMessage &msg);
void SysMsgToAllUser(CNetMessage &msg);
void QiangHongBaoZhuDong(uint8 op,CUser *pUser = NULL);
bool IsWeiXin(int type);
uint8 GetHuoYueTaskState(uint32 data);
uint32 GetHuoYueTaskInfo(uint32 data);
uint32 UpdateHuoYueTaskState(uint32 data);
uint32 GetHuoYueTaskCompleteCount(CUser *pUser);

const char *GetFuBenName(int copyId);

void ReplaceString(const string & src, string & out, vector<SReplaceStringData> &para);
void GetTeamMemberList(CUser *pHead,vector<ShareUserPtr> &pMem);

void SendLeaveTeamMsg(CUser *pUser);

void GetCMissionPara(vector<int> &var,vector<string> &str,const char *pInts,const char *pStrs);

bool SetAttrData(vector<SAttrData> &data,string &str);
bool SetAwardData(vector<SAwardData> &reward,string &str);

int GetAttrValue(vector<SAttrData> &attrList,uint16 type);
void AddToAttrList(vector<SAttrData> &tarAttr,SAttrData &src);
void MergeAttrList(vector<SAttrData> &tarAttr,vector<SAttrData> &srcAttr);
void MergeAwardData(vector<SAwardData> &tarAward,SAwardData &src);
void MergeAwardList(vector<SAwardData> &tarAward,vector<SAwardData> &srcAward);

bool SetCostData(vector<SCostData> &data,string &str);

const char *GetEquipAttrName(uint16 type);
int GetCuiLianAttrStar(int value,int maxValue);
const char* GetPetQualityStr(int petId);
int GetPetQualityColor(int petId);
void MakeAwardString(int type, int value, string& outString);

bool LeiTaiLvCheck(int level);
int GetLeiTaiLv();
int GetLeiTaiAId();

void UpdateUserChatTime(uint32 roleId,uint32 time);
uint32 GetUserChatTime(uint32 roleId);

template<typename TYPE>
void RandVector(vector<TYPE>& seqs)
{
	uint32 num = seqs.size();
	for (uint32 i = 0; i < num; ++i)
	{
		uint32 idx = Random(i, num - 1);
		if (idx == i) continue;
		TYPE swapIdx = seqs[idx];
		seqs[idx] = seqs[i];
		seqs[i] = swapIdx;
	}
}


void MakeChatByChannel(CNetMessage &msg,uint8 channel,const char *str);

string MakePetColorStr(uint16 petId);
string MakeJiHuoMa(int type);
uint32 MakeUniqueId(CUser* pUser, int type);

int SaveFightNetMsg(CNetMessage &msg, int type, uint32 roleId, uint32 tarRoleId=0, string notice="");
bool DecodeFightPlayData(CNetMessage &msg, const char *pStr);
bool GetFightNetMsgFromDB(CNetMessage &msg, int fightId);
void PlayFightCG(CUser *pUser, int id);

bool CheckUserCond(CUser* pUser, TypeValue& tv);
bool CheckUserCond(CUser* pUser, MultiTypeValue& tvs);
string MakeColorString(int quality, const string& inStr);

void UpdateUserRecord(uint32 roleId, uint32 type, uint32 typeId, uint32 typeValue, bool isUpdate = false);
#endif
