#ifndef _HUO_DONG_H_
#define _HUO_DONG_H_
#include <iostream>
#include <list>
#include <vector>
#include <queue>
#include <map>
#include <string>
#include <set>
#include <boost/thread.hpp>
#include "self_typedef.h"
#include "utility.h"

using namespace std;

const int MIAO_SHA_TIME = 23;
const int MING_GUAI_TIME = 21;
static const int LEI_TAI_SAI_TIME = 22; // 擂台赛时间

const int KUN_LUN_SHAN_TIME = 21;
const int KUN_LUN_SHAN_NOTIFY = 2035;
const int KUN_LUN_SHAN_MIN = 2100;
const int KUN_LUN_SHAN_MAX = 2120;
const int KUN_LUN_SHAN_BERFRO_1 = 2050; //诸天幻境通知时间
const int KUN_LUN_SHAN_BERFRO_2 = 2055; //诸天幻境通知时间

const int FENGSHEN_BERFRO_1 = 2120; //封神战场通知时间
const int FENGSHEN_BERFRO_2 = 2125; //封神战场通知时间
const int FENGSHEN_END_HOUR = 21; //封神战场结束时小时
const int FENGSHEN_NOTIFY = 2105; //封神战场开始时间
const int FENGSHEN_MIN = 2130; //封神战场开始时间
const int FENGSHEN_MAX = 2150; //封神战场结束时间

const int LINGMO_NOTIFY = 1535; //灵魔通知时间
const int LINGMO_MIN = 1600; //灵魔通知时间
const int LINGMO_MAX = 1630; //灵魔通知时间

const int HUSONG_NOTIFY = 1130; //护送神将通知时间
const int HUSONG_MIN = 1200; //护送神将开始时间
const int HUSONG_MAX = 1230; //护送神将结束时间

const int NIANSHOU_NOTIFY = 1335; //年兽通知时间
const int NIANSHOU_MIN = 1400; //年兽通知时间
const int NIANSHOU_MAX = 1430; //年兽通知时间

const int KUA_FU_FINALS_START_TIME = 2030;	// hour*100+min
const int KUA_FU_FINALS_END_TIME = 2145;

const int LEI_TAI_SAI_NOTIFY = 2130;
const int LEI_TAI_SAI_MIN = 2200;
const int LEI_TAI_SAI_MAX = 2230;

const int BANG_ZHAN_NOTIFY = 1925;
const int BANG_ZHAN_MIN = 1955;
const int BANG_ZHAN_MAX = 2020;
const int ZHEKOU_HUODONG_BITSET = 611;
const int ZHEKOU_HUODONG_CLEAR = 570;

const int ROUND_ZHEKOU_HUODONG_BITSET = 618;
const int ROUND_ZHEKOU_HUODONG_CLEAR = 573;

const int SHEN_JIE_MI_JING_NOTIFY = 1925;
const int SHEN_JIE_MI_JING_MIN = 1955;
const int SHEN_JIE_MI_JING_MAX = 2020;

#define HUODONG_FILE "./config_hd"
#define EXIT_HUODONG_FILE "./config_hd_exit"
#define HUODONG_SIZE 8
const int MAX_FUBEN_LEVEL=4;

struct CheckCodeInfo
{
	int id;
	string ans;
	time_t time;
};

struct ExitHuoDongInfo
{
	string taskname;
	string taskcontect;
	string time;
	int min_time;
	int max_time;
	string NPCname;
	string taskaward;
	short mapid;
	int x;
	int y;
	uint8 min_lv;
	uint8 max_lv;
	char weekday[8];
};

struct HuoDongInfo
{
	string name;
	string time;
	uint8 min_lv;
	uint8 max_lv;
	string NPC_name;
	short mapid;
	int x;
	int y;
	int min_time;
	int max_time;
};

struct DengJiLiBaoInfo
{
	uint8 id;
	uint16 level;
	uint32 goods[3][3];   // {{id,num},{id,num}}
};

struct HD_7RiDengLu // 7日登陆奖励内容
{
	static const uint8 AWARD_NUM = 3;
	HD_7RiDengLu()
	{
		memset(type,0,sizeof(type));
		memset(num,0,sizeof(num));
	}
	uint16 type[AWARD_NUM];
	uint32 num[AWARD_NUM];
	uint32 value[AWARD_NUM];
};

//设置攻城总绑定通宝
void SetTolBDMoeny(int money);
int GetLeftBDMoeny();

//设置战神祝福
void SetZhanShen(time_t endTime);
bool InZhanShen();

struct HuoDongAddExpInfo
{
	static const uint16 ExpMaxNum = 130;
	//	type = 1 神将副本
	//	type = 2 强化副本
	//	type = 3 金币副本
	//	type = 4 道具副本
	//	type = 5 潜能副本
	//	type = 6 多人闯关
	//	type = 7 通天塔
	//	type = 8 灵气捐献
	//	type = 9 师门任务
	//	type = 10 每日答题
	//	type = 11 钓鱼
	//	type = 12 昆仑山
	//	type = 13 竞技场
	//	type = 14 积分任务
	//	type = 15 奇袭鬼域
	//	type = 16 伏妖镇魔
	//	type = 17 护送任务
	//	type = 18 押运镖车
	//	type = 19 杀敌夺宝
	uint8 type;
	double expRatio[ExpMaxNum];
};

struct SDailySignData
{
	SDailySignData()
	{
		monType = 0;
		dayIdx = 0;
		vipLv = 0;
		vipMultiple = 0;
		awardType = 0;
		awardNum = 0;
	}	
	uint8 monType;
	uint8 dayIdx;
	uint8 vipLv;
	uint8 vipMultiple;
	uint32 awardType;
	uint32 awardNum;
	uint32 awardValue;
};

class CHuoDongExpManage
{
public:
	CHuoDongExpManage(){}
	~CHuoDongExpManage(){}

	void AddHuoDongExpNode(HuoDongAddExpInfo &data)
	{
		m_expList.push_back(data);
	}

	double GetExpRatio(uint8 type,uint16 level)
	{
		double ratio = 0.0;
		if(type == 0 || type > m_expList.size() || level > MAX_LEVEL || level <= 0)
			return ratio;
		if(level <= MAX_LEVEL)
			ratio = m_expList[type-1].expRatio[level-1];
		else
			ratio = m_expList[type-1].expRatio[MAX_LEVEL - 1];
		return ratio;
	}
	int64 GetHuoDongExp(uint8 type,uint16 level,double ratio)
	{
		if(ratio < 0.0)
			return 0;
		int64 exp = GetLevelUpExp(level);
		double huoDongRatio = GetExpRatio(type,level);
		exp = (int64)(exp * huoDongRatio * ratio);
		return exp;
	}

private:
	vector<HuoDongAddExpInfo> m_expList;
};

// 钓鱼数据
class CFishData
{
public:
	CFishData():m_roleId(0),m_fishTime(0) { memset(m_fishList,0,sizeof(m_fishList)); memset(m_name,0,sizeof(m_name)); }
	void AddFish(CUser* pUser,int fishId); // 增加鱼于鱼篓
	void RemoveFish(int fishIdx); // 删除鱼篓中的某条鱼
	void GetFish(CUser* pUser,int fishIdx); // 领取鱼篓中的某条鱼
	void GetFishAll(CUser* pUser); // 获取鱼篓中的所有鱼
	int GetLeftFishTime(); // 获取钓鱼剩余时间
private:
	void SortFish(); // 排序剔除零
public:
	static const int CAPACITY = 4; // 鱼篓容量
	static const int FISH_TIME = 60; // 每次钓鱼时间1.5分钟可以收获 180
	static const int FISH_GRAB_TIMEOUT = 120; // 被抢夺鱼的超时时间
public:
	int m_roleId;
	char m_name[MAX_NAME_LEN]; // 名字
	time_t m_fishTime; // 下杆时间
	int m_fishList[CAPACITY]; // 鱼篓列表
};

// 钓鱼房间
class CFishRoom
{
public:
	typedef list<CFishData> fishDataL_t; // 钓鱼数据列表
	typedef fishDataL_t::iterator itFishDataL_t; // 钓鱼数据列表
	typedef fishDataL_t freemManL_t; // 没有钓鱼的人
	typedef itFishDataL_t itFreemManL_t; // 没有钓鱼的人

	static const int MAX_FISHER = 20; // 房间捕鱼人上限
	static const int MAX_MAN = 25; // 房间人数上限
	static const int MAX_GRAB_COUNT = 5; // 每日抢夺他人的次数上限
	static const int MAX_BE_GRABED_COUNT = 10; // 每日被抢夺成功的次数上限

	enum ERoleState {
		ERS_ERR, // 玩家不在房间内
		ERS_FREE, // 没有钓鱼的人的状态
		ERS_FISHING, // 钓鱼状态
	};

public:
	CFishRoom():m_sceneId(0),m_id(0){}
	CFishRoom(const CFishRoom& room); // 复制构造函数 只是空房间而已
	bool IsEnterable(); // 玩家是否可以进入这个房间
	bool IsFishable(); // 玩家是否可以钓鱼
	void EnterRoom(int roleId, const char* name); // 进入房间
	bool IsFisher(CUser* pUser); // 是否是在钓鱼状态
	bool IsInRoom(CUser* pUser); // 是否是在房间内
	void SyncPlayerList(CUser* pTarUser, int isAdd = 1); // 同步玩家列表给所有房间内成员 user为空则同步全房间数据 不为空则为同步这个玩家给所有人，isadd为1是新增，0为减少
	void SyncFisherList(CUser* pTarUser, int isAdd = 1); // 同步玩家列表给所有房间内成员 user为空则同步全房间数据 不为空则为同步这个玩家给所有人，isadd为1是新增，0为减少

public:
	int GetManNum(); // 获取房间人数
	int GetFisherNum(); // 获取钓鱼的人数
	void StartFish(CUser* pUser,uint8 face); // 开始钓鱼
	void StopFish(CUser* pUser); // 停止钓鱼
	void GetFishList(CUser* pUser, int tarRoleId); // 获取鱼篓数据
	void GrabFish(CUser* pUser, int tarRoleId, int tarFishIdx); // 抢夺鱼篓
	int GrabFishSuccess(CUser* pUser, int tarRoleId, int tarFishIdx); // 成功抢夺对方鱼篓
	void GetFish(CUser* pUser, int fishIdx); // 领取某条鱼
	int Exit(CUser* pUser, bool clearRoom = true); // 退出房间 是否需要删除房间内角色的数据 返回删除的角色数
	void ExitByUserLogout(CUser *pUser);
	int SwitchExit(CUser* pUser); // 切换房间的退出房间
	void AllExit(); // 清空房间
	void GetPlayerList(CUser* pUser); // 获取玩家列表
	void GetFisherList(CUser* pUser); // 获取玩家列表 只显示钓鱼的玩家列表
	void SyncFishTime(CUser* pUser); // 同步钓鱼时间
	CFishData* GetFishData(int roleId); // 获取玩家的鱼篓信息

private:
	int GetRoleState(int roleId); // 获取玩家状态

public:
	fishDataL_t m_fishDataL; // 钓鱼数据列表
	freemManL_t m_freeManL; // 没有钓鱼的人
	int m_sceneId; // 房间对应的场景id
	int m_id; // 房间id
	boost::mutex m_fishDataLMutex; // 互斥量
	boost::mutex m_freeManLMutex; // 互斥量
};

// 钓鱼管理7
class CFishManager
{
public:
	typedef map<int,CFishRoom> fishRoomM_t; // 钓鱼数据管理
	typedef fishRoomM_t::iterator itFishRoomM_t; // 钓鱼数据管理迭代器

public:
	enum EFOP_FISH {
		EFOP_ErrorInfo = 0, // 错误信息
		EFOP_RoomList = 1, // 获取房间列表
		EFOP_Join = 2, // 加入房间
		EFOP_FisherList = 3, // 房间内钓鱼的玩家列表
		EFOP_FishList = 4, // 鱼篓数据
		EFOP_Fish = 5, // 开始钓鱼
		EFOP_GetFish = 6, // 收获鱼
		EFOP_GrabFish = 7, // 抢夺鱼
		EFOP_FishTime = 8, // 通知客户端收获鱼的倒计时
		EFOP_Exit = 9, // 离开房间
		EFOP_StopFish = 10, // 停止钓鱼
		EFOP_FishSuccess = 11, // 钓到鱼了
		EFOP_HuoDongBegin = 12, // 活动开始了
		EFOP_HuoDongEnd = 13, // 活动结束了
		EFOP_UpdateFisherList = 14, // 更新钓鱼玩家列表
		EFOP_PlayerList = 15, // 房间内玩家列表
		EFOP_UpdatePlayerList = 16, // 更新玩家列表
	};

	static const int HUO_DONG_TIME = 12; // 活动时间
	static const int HUO_DONG_TIME_MIN = 30; // 活动时间 分钟
	static const int HUO_DONG_TIME_MAX = 50; // 活动时间 分钟
	static const int HUO_DONG_LEVEL = 27; // 参与活动等级

	static const int FISH_POS_X = 790; // 进入副本坐标x
	static const int FISH_POS_Y = 289; // 进入副本坐标y

public:
	CFishManager():m_curId(0),m_manNum(0){}

	bool IsInHuoDongTime(); // 是否是活动时间

	void SendErrorInfo(CUser* pUser, const char* info); // 发送错误信息
	void GetRoomList(CUser* pUser); // 获取房间列表
	CFishRoom* JoinRoom(CUser* pUser, int roomId); // 加入房间
	void SwitchRoom(CUser* pUser, CFishRoom* pCurRoom, int tarRoomId); // 切换房间
	void ExitRoom(CUser* pUser); // 退出房间
	void ExitSubPlayer() { --m_manNum;} // 退出房间减少总玩家数
	void GetRoomPlayerList(CUser* pUser, int roomId); // 获取房间内的玩家列表
	void GetRoomFisherList(CUser* pUser); // 获取房间内的钓鱼玩家列表

	void CleanRoom(); // 清空房间(活动结束)
	void CheckCreateRoom(); // 检查是否需要创建房间

private:
	CFishRoom* CreateRoom(); // 创建房间
	CFishRoom* GetRoom(int roomId); // 查找房间

public:
	fishRoomM_t m_fishRoomM; // 钓鱼数据管理
	boost::mutex m_fishRoomMMutex; // 互斥量

private:
	int m_curId; // 当前房间id号(同房间数目)
	int m_manNum;
};

// 商店物品
class CShopItem
{
public:
	CShopItem() : m_id(0),m_itemId(0),m_price(0),m_offPrice(0),m_type(0),m_tag(0),m_startTime(0),m_endTime(0),m_limit(0),m_count(0) {}
public:
	int m_id; // 数据库id
	int m_itemId; // 物品id
	uint16 value;    // 类型值
	uint16 extValue; // 附加值
	int m_price; // 物品价格
	int m_offPrice; // 特价
	uint8 m_type; // 页数类型
	int m_tag; // 标签 热卖/促销等
	time_t m_startTime; // 开始售卖时间
	time_t m_endTime; // 结束售卖时间
	int m_limit; // 出售数量上限
	int m_count; // 当前出售数量
};

class CShopManager
{
public:
	typedef list<CShopItem> shopItems_t;
	typedef shopItems_t::iterator itShopItems_t;

public:
	static const int LOAD_SHOP_ITEM_TIMEOUT = 60*10;	// 刷新商城道具时间间隔
	static const uint8 MAX_DISCOUNT_AWARDNUM = 3;		// 折扣礼包物品种类数量上限
	static const uint8 WEEK_DAY_NUM = 7;
	static const uint8 SHOW_DISCOUNT_NUM = 8;	// 显示上限
	static const uint16 REFRESH_MYSTERY_YB = 20;	// 神秘商店刷新元宝
	static const uint16 REFRESH_SHENHUN_YB = 20;	// 神魂商店刷新元宝
	static const int NEW_USER_DISCOUNT_TIME = 7*24*3600;	// 新手特惠时间限制
	static const uint16 REFRESH_YAOSHI_YB = 20;	// 妖石商店刷新元宝

	enum EShopOp
	{
		ESOP_Show = 1, 			// 获取某页的道具
		ESOP_Buy = 2, 			// 购买某页的道具
		ESOP_RefreshCount = 3,	// 刷新抢购道具的购买数量
		ESOP_DiscountShow = 4,	// 折扣商店显示
		ESOP_DiscountBuy = 5,	// 折扣商店购买
		ESOP_MysteryShow = 6,	// 神秘商店显示
		ESOP_MysteryBuy = 7,	// 神秘商店购买
		ESOP_MysteryRefresh = 8,// 神秘商店刷新
		ESOP_ExchangeShow = 9,	// 兑换商店列表
		ESOP_ExchangeBuy = 10,	// 兑换商店购买
		ESOP_ZaDanShow = 11,	// 砸蛋商店显示
		ESOP_ZaDanBuy = 12,		// 砸蛋兑换
		ESOP_HongLiJiFenShow = 13,	// 红利积分商店显示
		ESOP_HongLiJiFenBuy = 14,		// 红利积分兑换
		ESOP_Rmb= 15,			//RMB直买商店
		ESOP_YaoShiShow = 16,	// 妖石商店显示
		ESOP_YaoShiBuy = 17,	// 妖石商店购买
		ESOP_YaoShiRefresh = 18,//妖石商店刷新
		ESOP_FootPrintShow = 19,//脚印商店显示
		ESOP_FootPrintBuy = 20,	//脚印商店购买
		ESOP_FootPrintEquip = 21,	//脚印商店装备
		ESOP_FootPrintUnEquip = 22,	//脚印商店卸载

		ESOP_ShenhunShow = 23,	  // 神魂商店显示
		ESOP_ShenhunBuy = 24,	  // 神魂商店购买
		ESOP_ShenhunRefresh = 25, // 神魂商店刷新

		

		ESOP_INFO = 255,	// 获取实名，是否是游客信息
	};

	struct EShopDiscountItem
	{
		uint8 type;		// 1新手2折扣
		uint8 vipLimit;	// 购买vip等级限制 0-3
		uint8 awardCount;	// 礼包物品数量
		uint8 awardType[MAX_DISCOUNT_AWARDNUM];	// 1物品2神将3神将蛋4非指定技能书
		uint8 vipCanBuyNum[16];			// vip0-vip3
		uint8 discount[WEEK_DAY_NUM];	// 折扣 1-100
		uint8 weekdayInfo[WEEK_DAY_NUM];// 周日-周六 0不生效1生效
		uint16 id;
		uint8 def;
		uint16 srcPrice;
		uint16 awardId[MAX_DISCOUNT_AWARDNUM];	// type=1 物品id, =2 神将id, =3 神将品质, =4 没用
		uint8 awardNum[MAX_DISCOUNT_AWARDNUM];
		string name;
		string desc;
	};

public:
	bool LoadShopItems();	// 加载商城数据
	bool ReloadShenjiangShopItems();	// 加载新的神将数据
	void Timeout(); 		// 定时器

public:
	void ShowShopItems(CUser* pUser, int type); // 获取商城物品
	void Buy(CUser* pUser, int type, int itype, uint16 ivalue, uint16 exvalue, uint8 num); // 购买商城物品
	void RefreshCount(CUser* pUser); // 刷新抢购道具的购买数量

	void ShowDiscountItems(CUser *pUser);	// 获取折扣商店信息
	void BuyDiscountItems(CUser *pUser,uint16 itemId);
	void ReSetDiscountItems_Effect();

	void ShowZaDanShopItems(CUser *pUser);
	void BuyZaDanShopItems(CUser *pUser,int itemId,int itemNum);

	void ShowHongLiJiFenShopItems(CUser *pUser,uint32 huodongType);
	void BuyHongLiJiFenShopItems(CUser *pUser,int itemId,int itemNum,uint32 huodongType);

	void ReFreshMysteryItems(CUser *pUser);
	void ShowMysteryItems(CUser *pUser);
	void UpdateUserMysteryData();
	vector<UserMysteryItem> &GetMysteryData(){return m_MysteryItem;}

	void ReFreshShenhunItems(CUser *pUser);
	void ShowShenhunItems(CUser *pUser);

	//vector<UserMysteryItem> &GetShenhunData() { return m_MysteryItem; }

	void ReFreshYaoShiItems(CUser *pUser);
	void ShowYaoShiItems(CUser *pUser);
	void ShowFootPrintShopItems(CUser *pUser);
	void BuyFootPrint(CUser *pUser,int id,CNetMessage &msg);
	void EquipFootPrint(CUser *pUser,int id,CNetMessage &msg);
	void UnEquipFootPrint(CUser *pUser,int id,CNetMessage &msg);

	SFlowerData* GetFlowerCfg(int id);
	void ShowFlowerShopItems(CUser *pUser, CNetMessage &msg);
	void BuyFlower(CUser *pUser,int itemId,int buyNum,CNetMessage &msg);
	void ShowSelfFlower(CUser *pUser,CNetMessage &msg);
	bool SendFlowerToFriend(CUser *pUser,uint16 itemId,int itemNum,int roleId,CNetMessage &msg);
	void AddMeiLiValue(uint32 role_id, string &name, int value);
	void ShowMeiLiPaiHang(CUser *pUser, CNetMessage &msg);
	void ShowHistoryPaiHang(CUser *pUser, CNetMessage &msg);
	void SetRoleName(uint32 role_id,const char *name);
	void SendMeiLiPaiAward();
	int GetQinMiValue(uint32 roleId1,uint32 roleId2);
	int GetMeiLiValue(uint32 roleId);
	void RequestFlowerShopAndSelfFlower(CUser *pUser);
	void Save();
	bool IsMeiliHuodongOpen();
private:
	CShopItem* GetShopItem(int stype, int itype, int value = 0, int extValue = 0); // 获取商品
	void SaveLog(CUser* pUser, int type, int itemId, int itemNum, int costMoney); // 保存购买记录
	void SaveLimitItemBuyCount(int id, int itemNum); // 保存限制数量道具的购买数量

private:
	enum EShopItemType // 页数类型
	{
		ESIT_XIANSHI = 0, 	// 限时抢购
		ESIT_CHANGYONG = 1, // 常用道具
		ESIT_ZHUANGBEI = 2, // 装备锻造
		ESIT_CHONGWU = 3,	// 神将坐骑
		ESIT_BANGDING = 4,	// 绑定元宝
		ESIT_JINGJIJIFEN = 5,// 竞技场积分
		ESIT_MYSTERY = 6,	// 神秘商店
		ESIT_BANGGONG = 7,	// 帮贡商店
		ESIT_ZaDanJiFen = 8,	// 砸蛋积分兑换
		ESIT_HongLiJiFen = 9,	// 红利积分兑换
		ESIT_YAOSHI = 10,	// 妖石商店
		ESIT_LEITAIJIFEN = 11,	// 擂台积分商店
		ESIT_ZaDanJiFenCopy = 12,	// 砸蛋积分兑换
	};
	enum EShopBuyError // 购买错误信息
	{
		ESBE_ERROR_NUM = 0,	// 购买数量错误
		ESBE_NO_ITEM,		// 该商品已经下架
		ESBE_ITEM_LESS,		// 库存不足
		ESBE_TONGBAO_LESS,	// 元宝不足
		ESBE_BDTONGBAO_LESS,// 绑定元宝不足
		ESBE_PACKAGE_LESS,	// 背包空间不足
		ESBE_SYSTEM_BUSY,	// 购买道具失败
		ESBE_JINGJIJIFEN_LESS,	// 竞技场积分不足
	};

	vector<EShopDiscountItem> m_discountItems; // 打折商店物品
	vector<EShopDiscountItem> m_discountItems_NewUser;	// 新手特惠
	vector<uint16> m_discountItems_Effect;	// 生效的打折列表
	map<uint16,uint8> m_discountMap_Effect;	// pos,id

	typedef vector<UserMysteryItem> M9RateShopItems;
	vector<UserYaoShiItem> m_YaoShiItem;	//妖石商店物品
	M9RateShopItems m_MysteryItem;	//神秘商店物品
	typedef std::map<std::pair<int, int>, M9RateShopItems> ShenjiangShopItemMap;
	typedef std::map<std::pair<int, int>, M9RateShopItems>::iterator ShenjiangShopItemMapIt;
	ShenjiangShopItemMap m_ShenhunItems; //神将商店物品

	vector<SFootPrintShopData> m_footShop;

	vector<SFlowerData> m_flowerShop;
	map<string,int> m_qinmiData;

	typedef vector<SMeiLiData> meiliDatas;
	typedef map<int, meiliDatas> sessionMeili;
	typedef map<int, meiliDatas>::iterator sessionMeiliIt;
	meiliDatas m_meiliData;
	sessionMeili m_allRoundDatas;

	shopItems_t m_shopItems; // 商城物品
	boost::mutex m_shopItemsMutex; // 互斥量
};

// 各种活动
enum ESendType {
	EST_Festival = 1,
};

// 各种活动
enum EMD2_HuoDong {
	HD_HAOHUALIBAO = 1,		// 豪华礼包
	HD_MEIRIGONGZI = 2,		// 每日工资
	HD_MIANFEIZUOQI = 3,	// 免费坐骑
	HD_ZAIXIANLINGHAOLI = 4,// 在线领好礼
	HD_LIANXUDENGLUJIANGLI = 5,	// 7日登陆奖励
	HD_CHENGZHANGLIBAO = 6,	// 成长礼包
	HD_SHENGJILIBAO = 7,	// 升级礼包
	HD_SHOUCHONG = 9,		// 首充
	HD_TAOCAN = 10,			// 付费套餐
	HD_DENGLULIBAO = 11,	// 连续登陆奖励 登陆礼包
	HD_CHONGZHISONGLI = 12,	// 充值送礼
	HD_KAIFUCHONGJI = 13,	// 开服冲级赛
	HD_XINFUZHANLIBANG = 14,// 新服战力榜
	HD_XIANCHONGDASHOUJI = 15,		// 仙神将大收集
	HD_QIANGZHUANGLINGHAOLI = 16,	// 强装领好礼
	HD_YAO_QIAN_SHU = 17,	// 摇钱树
	HD_MEIRI_SHOUCHONG = 18, //每日首充
	HD_JIERI_LIBAO = 19, //节日礼包
	HD_LEI_JI_CHONGZHI = 20,	// 累计充值
	HD_LEI_JI_XIAO_FEI = 21,	// 累计消费
	HD_ZHENGDIANZAIXIAN = 22,	//整点在线礼包
	HD_CHONGZHIFANYB = 23, //每日大返利
	HD_HONGLICHONGZHI = 24, //红利大放送 充值
	HD_HONGLIXIAOFEI = 25,  //红利大放送 消费
	HD_SHEN_CHONG_BANG = 26,	// 最强神将榜
	HD_EQUIP_QIANG_HUA = 27,	// 仙甲强化榜
	HD_ROLE_LEVEL_BANG = 28,	// 等级冲刺榜
	HD_ZHAN_LI_BANG = 29,		// 群仙战力榜
	HD_CHONG_ZHI_BANG = 30,		// 新服充值榜
	HD_QIANGHUA_KUANGHUAN = 31,		// 强化狂欢礼
	HD_SHENGJIE_LETIAN = 32,		// 升阶乐翻天
	HD_ZHA_DAN = 33,		// 砸蛋
	HD_FESTIVAL = 34,		// 节日
	HD_LIANXU_CHONGZHI_ORI = 35,// 连续充值-普通
	HD_LIANXU_CHONGZHI_DELUXE = 36,// 连续充值-豪华
	HD_JIERI_LIBAO2 = 37, //节日礼包2
	HD_LEI_JI_CHONGZHI2 = 38,	//累计充值2
	HD_LEI_JI_XIAO_FEI2 = 39,	//累计消费2
	HD_CHONGZHIFANYB2 = 40,		//每日大返利2
	HD_CHONGZHIFANYB3 = 41,		//每日大返利3
	HD_CICHONG = 42,			// 次充
	HD_CHONGZHIFANYB4 = 43,		//每日大返利4
	HD_CHONGZHIFANYB5 = 44,		//每日大返利5
	HD_WING_BANG = 45,			//神级羽翼榜
	HD_HONGLICHONGZHI_RMB = 46, //红利大放送 充值 RMB
	HD_HONGLI_JIFEN = 47, //红利积分
	HD_JIJIN_FANLI = 48, //基金返利
	HD_DAOJUHUISHOU = 49,	//道具回收
	HD_MEIRI_HUAN_HAOLI = 50, //每日换好礼
	HD_XIAN_SHI_CHOU = 51, //限时抽活动
	HD_CHONGZHIFANYB6 = 52,		//每日大返利6
	HD_CHONGZHIFANYB7 = 53,		//每日大返利7
	HD_CHONGZHIFANYB8 = 54,		//每日大返利8
	HD_CHONGZHIFANYB9 = 55,		//每日大返利9
	HD_CHONGZHIFANYB10 = 56,	//每日大返利10
	HD_HONGLI_JIFEN2 = 57, //红利积分2
	HD_HONGLI_JIFEN3 = 58, //红利积分3
	HD_HONGLI_JIFEN4 = 59, //红利积分4
	HD_HONGLI_JIFEN5 = 60, //红利积分5
	HD_HONGLICHONGZHI2 = 61, //红利大放送 充值2
	HD_HONGLICHONGZHI3 = 62, //红利大放送 充值3
	HD_HONGLICHONGZHI4 = 63, //红利大放送 充值4
	HD_HONGLICHONGZHI5 = 64, //红利大放送 充值5
	HD_HONGLIXIAOFEI2 = 65,  //红利大放送 消费2
	HD_HONGLIXIAOFEI3 = 66,  //红利大放送 消费3
	HD_HONGLIXIAOFEI4 = 67,  //红利大放送 消费4
	HD_HONGLIXIAOFEI5 = 68,  //红利大放送 消费5
	HD_JIJIN_FANLI2 = 69, //基金返利2
	HD_JIJIN_FANLI3 = 70, //基金返利3

	HD_XINCHUN_HAPPY = 72,//新春快乐
	HD_ZHENYING_PK = 73,// 阵营PK
	HD_QIANG_HONGBAO = 74,// 抢红包
	HD_HUOYUE_TASK = 75,// 活跃任务
	HD_MEIRI_XIAOHAO1 = 76,	// 每日消耗1
	HD_MEIRI_XIAOHAO2 = 77,	// 每日消耗2
	HD_MEIRI_XIAOHAO3 = 78,	// 每日消耗3
	HD_MEIRI_XIAOHAO4 = 79,	// 每日消耗4
	HD_MEIRI_XIAOHAO5 = 80,	// 每日消耗5

	HD_MOGU = 81,	// 蘑菇
	//add by zhudaolong 2017.11.03
	HD_TAOHUAGENG = 82,	//桃花羹
	
	HD_LEVEL_JIJIN1 = 83, //等级基金返利
	HD_SHENJIANG_ZHEKOU = 84, //神将折扣
	HD_MEILI_HUODONG = 85, //魅力活动
	HD_ZHEKOU_LIBAO1 = 86, // 折扣礼包
	HD_ZHEKOU_LIBAO2 = 87,
	HD_ZHEKOU_LIBAO3 = 88,

	HD_ROUND_ZHEKOU_LIBAO1 = 89, // 折扣礼包
	HD_ROUND_ZHEKOU_LIBAO2 = 90,
	HD_ROUND_ZHEKOU_LIBAO3 = 91,
	HD_ZHA_DAN_COPY = 92,		// 砸蛋
	HD_ROUND_ZHEKOU_LIBAO4 = 93,

	HD_HUOUE_JIJIN1 = 94,

	HD_ROLE_INFO = 0xfe,		// 角色称号显示必须信息
	HD_ALL_LIST = 0xff,			// 所有活动列表
};

// 元宝使用记录
enum EMD2_YuanBaoLog { // 物品id:0元宝，1:绑定元宝，2:元宝+绑定元宝
	YBL_OPENPACKAGE = 101, // 开背包
	YBL_QIANDAO = 102, // 签到
	YBL_JIATONGBAO = 103, // 加通宝
	YBL_VIP = 104,		// vip购买
	YBL_CHUANGGUANHAND = 105, // 闯关猜拳
	YBL_QIANGHUA = 106, 	// 强化
	YBL_PETSHENGJIE = 107, // 神将升阶
	YBL_PETSHENGXING = 108, // 神将铠强化
	YBL_CHUANGGUANCD = 109, // 闯关cd重置
	YBL_ARENACD = 110, // 竞技场cd重置
	YBL_PETDRAW = 111, // 神将抽取
	YBL_TILI = 112,		// 体力重置
	YBL_TAOCAN = 113,	// 套餐购买
	YBL_SHOP_DISCOUNT = 114,	// 折扣商店
	YBL_SHOP_NEW_USER = 115,	// 新手特惠
	YBL_SHOP_MYSTERY = 116,		// 神秘商店
	YBL_SHOP_MYSTERY_REFRESH = 117,	// 刷新神秘商店
	YBL_PETCOPY_REVIVE = 118,	// 神将副本复活

	YBL_PETCOPY = 120,	// 高级寻神将消耗元宝
	YBL_SEEDSHOP = 121,	// 种子商人消耗
	YBL_ARENA_ENTERNUM = 122,	// 竞技场次数购买
	YBL_ACC_SHAODANG = 123,	// 扫荡加速
	YBL_BUY_BOSS_NUM = 124,	// 日常boss次数购买
	YBL_SHENG_JIE = 125,	// 升阶消耗
	YBL_YAO_LING = 126,		// 提升妖灵
	YBL_JIERI_LIBAO = 127,	// 节日礼包
	YBL_ZADAN_CHUIZI = 128, // 锤子砸蛋
	YBL_ZADAN_YB = 129,		// 元宝砸蛋
	YBL_BUY_FOX = 130,		// 购买九尾狐
	YBL_JIERI_LIBAO2 = 131,	// 节日礼包2
	YBL_BUY_WING = 132,		// 购买翅膀
	YBL_BUY_XIANYUAN_CARD = 133,	//仙缘抽卡元宝
	YBL_BUY_XIANYUAN_CARD_XY = 134,    //仙缘抽卡元宝
	YBL_KUA_FU_1VS1_PRELIMINARY_REFRESH = 135,	//跨服1vs1预赛刷新敌人
	YBL_KUA_FU_1VS1_PRELIMINARY_ADD_NUM = 136,	//跨服1vs1预赛增加挑战次数
	YBL_KUA_FU_1VS1_PRELIMINARY_CLEAR_CD = 137,	//跨服1vs1预赛刷新CD
	YBL_XIAN_SHI_CHOU = 138,	//限时抽活动
	YBL_CREATE_BANGPAI = 139,	//创建公会
	YBL_QI_FU = 140,	//元宝祈福
	YBL_CAI_QUAN = 141,	//猜拳
	YBL_STRENG_WING = 142,	//元宝培养翅膀
	YBL_LINGSHOU_LEVEL_UP = 143,	//灵兽升级
	YBL_WEDDING_SongZhuFu = 144,	// 婚礼送祝福
	YBL_WEDDING_FangYanHua = 145,	// 婚礼放烟花
	YBL_FIND_YOUYUANREN = 146,	//寻找有缘人
	YBL_CHRISTMASTREE = 147,	//圣诞节活动
	YBL_ORDER_WEDDING = 148,	//预约婚礼
	YBL_SHOP_YAOSHI = 149,	//妖石头商城
	YBL_SHOP_YAOSHI_REFRESH = 150,	// 刷新妖石商店
	YBL_HUOYUE_PASS = 151,	// 活跃任务跳过
	YBL_BUY_FLOWER = 152,	// 购买鲜花
	YBL_BUY_FOOT_PRINT1 = 153,	// 足迹元宝
	YBL_BUY_FOOT_PRINT2 = 154,	// 足迹绑元
	YBL_BUY_FOOT_PRINT3 = 155,	// 足迹金币

	YBL_SHOP_SHENHUN_REFRESH = 119,	// 刷新神魂商店
};

// 全局变量使用记录
enum E_GlobalVarible { 
	EGV_KFCJS = 1, // 开服冲级赛
	EGV_XFZLB = 2, // 新服战力榜
	EGV_ZQSCB = 3, // 最强神将榜
	EGV_XJQHB = 4,	// 仙甲强化榜
	EGV_DJCCB = 5,	// 等级冲刺榜
	EGV_QXZLB = 6,		// 群仙战力榜
	EGV_XFCZB = 7,		// 新服充值榜
	EGV_FESTIVAL_GIVE = 8,	// 节日赠送
	EGV_FESTIVAL_GET = 9,	// 节日受赠
	EGV_WING = 10,	// 神级羽翼榜
	EGV_XSC = 11,	// 限时抽活动榜
	EGV_JH = 12,	// 结婚排行榜
	EGV_BPZ = 13,	// 周六帮派战排名

	EGV_HLSY = 100,	// 周年庆欢乐盛宴
	EGV_BWZ = 101,	// 周年庆蛋糕保卫战boss
};

struct ERiChangFuBen
{
	ERiChangFuBen():id(0),type(0),level(0),enterLimit(0),extdata8(0),mopTime(0),sceneId(0){}

	uint16 id;
	string name;
	uint8 type;		// 0普通1精英
	uint16 level;	// 进入人物等级限制
	uint8 enterLimit;	// 默认进入次数
	uint16 extdata8;	// 记录默认进入次数
	uint16 mopTime;		// 每场扫荡时间
	uint16 sceneId;
	string mobs;		// 
	string desc_title;	// 描述
	string desc_ratio[2];	// 概率描述
	
	uint8 lvuptype[MAX_FUBEN_LEVEL];	// 升级需求类型
	string condes[MAX_FUBEN_LEVEL];		// 升级需求描述
	int lvupvalue[MAX_FUBEN_LEVEL];		// 升级需求值
	string reward[MAX_FUBEN_LEVEL];		// 奖励
};

class CRiChangFuBenManager
{
public:
	CRiChangFuBenManager();
	~CRiChangFuBenManager();
	
	bool Load();
	void ListFuBen(CUser *pUser,CNetMessage &msg);
	void QueryFuBenCiShu(CUser *pUser,CNetMessage &msg);
	ERiChangFuBen *FindFuBen(int id);
	void CheckFuBenLevel(CUser *pUser);
private:
	list<ERiChangFuBen> m_eRiChangFuBenList;
};

class PracticeTemple
{
public:
	static const int TYPE_NUM = 3;
	static const int USER_LIMIT_NUM = 5;

	PracticeTemple();
	~PracticeTemple();
	void Init();
	ShareUserPtr GetPracticeUser(int type,int uIdx);
	void SetPracticeUser(int type,int uIdx,CUser *pUser);

private:
	boost::mutex m_mutex;
	ShareUserPtr m_userList[TYPE_NUM][USER_LIMIT_NUM];
};

struct HD_Exchange_Drop
{
	HD_Exchange_Drop()
	{
		hd_id = 0;
		itemId = 0;
		itemNum = 0;
		ratio = 0;
		dropNum_limit = 0;
		ext8_idx = 0;
		hd_type.clear();
	}
	
	uint16 dropNum_limit;
	uint16 ext8_idx;
	uint32 hd_id;
	uint32 itemId;
	uint32 itemNum;
	uint16 ratio;
	string hd_name;
	vector<int> hd_type;
};

struct HD_Exchange_Drop_New
{
	HD_Exchange_Drop_New()
	{
		hd_id = 0;
		dropNum_limit = 0;
		ext8_idx = 0;
		hd_type.clear();
		drop_id = 0;
	}
	
	uint16 dropNum_limit;//0-表示没有限制
	uint16 ext8_idx;
	uint32 hd_id;
	string hd_name;
	int drop_id;
	vector<int> hd_type;
};

struct HD_Exchange_Data
{
	HD_Exchange_Data()
	{
		saveExt8 = 0;
		id = 0;
		exchangeNumLimit = 0;
		targetId = 0;
		targetNum = 0;
		memset(material,0,sizeof(material));
		memset(materialNum,0,sizeof(materialNum));
	}
	static const int MATERIAL_NUM = 3;
	uint8 exchangeNumLimit;
	uint16 saveExt8;	
	uint32 materialNum[MATERIAL_NUM];
	uint32 targetId;
	uint32 targetNum;
	uint32 id;
	uint32 material[MATERIAL_NUM];
};

class CHDExchangeManager
{
public:
	typedef map<uint32,HD_Exchange_Data> exchangeMap;
	CHDExchangeManager(){m_totalLimitNum = 0;}
	~CHDExchangeManager(){}
	
	bool Init();
	bool InitHDDrop();
	bool InitExchangeDrop();
	bool InitHDDrop_New();
	bool InitExchangeMap();
	void TimeOut();
	bool DropExchangeItem(CUser *pUser,uint32 hdId);
	bool DropHDItem(CUser *pUser,uint32 hdId);
	bool DropHDItem_New(CUser *pUser,uint32 hdId);
	bool DropFestivalItem(CUser *pUser,uint32 hdId);
	bool DropHuanHaoLiItem(CUser *pUser,uint32 hdId);
	HD_Exchange_Data GetExchangeDataByTargetId(uint16 day,uint32 id);
	void GetExchangeListByDayIdx(uint16 dayIdx,vector<HD_Exchange_Data> &data);
	int GetTotalLimitNum(){return m_totalLimitNum;}
	
	void Print();
	void OpenXtmasBox(CUser *pUser);

private:
	boost::recursive_mutex m_mutex;
	map<uint32,HD_Exchange_Drop> m_dropList;
	map< uint16,exchangeMap > m_exchangeList;
	map<uint32,HD_Exchange_Drop> m_festivalDropList;
	map<uint32,HD_Exchange_Drop_New> m_huanHaoLiDropList;
	map<uint32,HD_Exchange_Drop> m_christmasTreeDropList;
	map<uint32,HD_Exchange_Drop> m_xinchunhappyDropList;
	map<uint32,HD_Exchange_Drop> m_zhenyingPK1DropList;
	map<uint32,HD_Exchange_Drop> m_zhenyingPK2DropList;
	int m_totalLimitNum;
};

struct HDExchangeInfo
{
	HDExchangeInfo()
	{
		exchange_num_limit = 0;
		saveExt8 = 0;
		idx = 0;
		isShow = 0;
		materialIsOr = 0;
		memset(award,0,sizeof(award));
		memset(num,0,sizeof(num));
		memset(petQuality,0,sizeof(petQuality));
		memset(petQualityLv,0,sizeof(petQualityLv));
	}

	static const uint8 AWARD_NUM = 6;
	static const uint8 MATERIAL_NUM = 5;
	uint8 exchange_num_limit;
	uint32 saveExt8;
	uint32 idx;
	uint32 material[MATERIAL_NUM];
	uint32 material_num[MATERIAL_NUM];
	uint16 petQuality[AWARD_NUM];
	uint16 petQualityLv[AWARD_NUM];
	uint32 award[AWARD_NUM];
	uint32 num[AWARD_NUM];
	uint8 isShow;
	uint8 materialIsOr;//材料是否是任一
};

struct SHuoDongAward
{
	SHuoDongAward()
	{
		idx = 0;
		idx2 = 0;
		idx3 = 0;
		needYB = 0;
		memset(award,0,sizeof(award));
		memset(num,0,sizeof(num));
		memset(petQuality,0,sizeof(petQuality));
		memset(petQualityLv,0,sizeof(petQualityLv));
	}

	static const uint8 AWARD_NUM = 6;
	uint32 idx;		// 礼包顺序
	uint32 idx2;	// 不同活动意义不同
	uint32 idx3;	// 不同活动意义不同(红利大放送的天数)
	uint32 needYB;
	uint16 petQuality[AWARD_NUM];	// 星级
	uint16 petQualityLv[AWARD_NUM];	// 等级
	uint32 award[AWARD_NUM];
	uint32 num[AWARD_NUM];
};

struct SHuoDongInfo
{
	SHuoDongInfo()
	{
		type = 0;
		showIdx = 0;
		isShow = 0;
		iStartTime = 0;
		iEndTime = 0;
		pic = 0;
		day = 0;
		timeDesc.clear();
		leijiTime = 0;
		leijiDesc.clear();
		name.clear();
		startHour = 0;
		endHour = 0;
		moguAwardDay = 0;
		zeroStartTime = 0;
	}

	uint32 type;		// 活动类型，1 首充送福利，2 节日大礼包，3 充值送福利，4 消费赢好礼，5 开服冲级赛，6 新服战力榜，7 仙神将大搜集，8 强装领好礼，9 整点在线礼包，10 每日大返利
	uint32 showIdx;
	uint8 isShow;     //0 不显示，1显示
	uint32 iStartTime;
	uint32 iEndTime;
	uint32 pic;
	uint32 day;
	uint32 moguAwardDay;
	uint32 leijiTime;
	string timeDesc;
	string leijiDesc;
	string name;
	uint32 startHour;
	uint32 endHour;
	uint32 zeroStartTime;//开始时间0点时间戳
};

struct JieRiLiBaoInfo
{
	uint8 color;
	uint32 cd;
	uint32 price;
	uint32 firstId;
	uint8 num;
	uint32 saveCountId;
	uint32 saveLastTimeId;
	uint32 type;
};

struct Goods
{
	uint32 id;
	uint32 num;
};

struct HDItemScoreExchangeInfo
{
	HDItemScoreExchangeInfo()
	{
		itemId = 0;
		giveScore = 0;
		getScore = 0;
	}
	uint32 itemId;
	uint32 giveScore;
	uint32 getScore;
};

struct HDPeiZhiInfo
{
	HDPeiZhiInfo()
	{
		type = 0;
		YB = 0;
		index = 0;
		cd = 0;
		price = 0;
		firstId = 0;
		num = 0;
		saveCountId = 0;
		saveLastTimeId = 0;
		count = 0;
		lv = 0;
		zhenYing1Name = "";
		zhenYing2Name = "";
		water_cz = 0;
		bug_cz = 0;
		step1_cz = 0;
		step2_cz = 0;
	}
	
	uint32 type;
	uint32 YB;
	uint32 index;
	uint32 cd;
	uint32 price;
	uint32 firstId;
	uint8 num;
	uint32 saveCountId;
	uint32 saveLastTimeId;
	uint8 count;
	uint32 lv;
	string zhenYing1Name;
	string zhenYing2Name;
	uint32 water_cz;
	uint32 bug_cz;
	uint32 step1_cz;
	uint32 step2_cz;
};

struct HDRandAwardInfo
{
	HDRandAwardInfo()
	{
		award = 0;
		num = 0;
		petQt = 0;
		petQtLv = 0;
		rate = 0;
	}

	uint32 award;
	uint32 num;
	uint16 petQt;
	uint16 petQtLv;
	uint32 rate;
};

struct HDPaiHangInfo
{
	HDPaiHangInfo()
	{
		startId = 0;
		endId = 0;
		idx = 0;
		score = 0;
	}

	uint32 startId;
	uint32 endId;
	uint32 idx;
	uint32 score;
};

struct HDPaiHangRecordInfo
{
	HDPaiHangRecordInfo()
	{
		role_id = 0;
		role_name.clear();
		role_lv = 0;
		role_zhandouli= 0;
		bang_name.clear();
		rank = 0;
		data = 0;
		time = 0;
		xiang = 0;
		sex = 0;
	}

	uint32 role_id;
	string role_name;
	uint32 role_lv;
	uint32 role_zhandouli;
	string bang_name;
	uint32 rank;
	uint32 data;
	uint32 time;
	uint32 xiang;
	uint32 sex;

	HDPaiHangRecordInfo &operator = (struct HDPaiHangRecordInfo &b)
	{
		role_id = b.role_id;
		role_name = b.role_name;
		role_lv = b.role_lv;
		role_zhandouli = b.role_zhandouli;
		bang_name = b.bang_name;
		rank = b.rank;
		data = b.data;
		time = b.time;
		xiang = b.xiang;
		sex = b.sex;
		return *this;
	}
};

struct ZhenYingScoreInfo
{
	ZhenYingScoreInfo()
	{
		score = 0;
		time = 0;
	}

	uint32 score;
	uint32 time;

};

struct HDChouInfo
{
	HDChouInfo()
	{
		role_id = 0;
		role_name.clear();
		level = 0;
		count = 0;
		award = 0;
	}

	uint32 role_id;
	string role_name;
	uint32 level;
	uint32 count;
	uint32 award;
};


struct SSortXianShiChouPaiHang
{
	bool operator()(HDPaiHangRecordInfo const &b1,HDPaiHangRecordInfo const &b2)
	{
		if (b1.data != b2.data)
			return b1.data > b2.data;
		else if (b1.role_lv != b2.role_lv)
			return b1.role_lv > b2.role_lv;
		else if (b1.role_zhandouli != b2.role_zhandouli)
			return b1.role_zhandouli > b2.role_zhandouli;

		return b1.role_id > b2.role_id; 

	}
};

struct SSortChristmasTreePaiHang
{
	bool operator()(HDPaiHangRecordInfo const &b1,HDPaiHangRecordInfo const &b2)
	{
		if (b1.data != b2.data)
			return b1.data > b2.data;

		return b1.time < b2.time; 
	}
};



struct PaiHangBangInfo
{
	PaiHangBangInfo()
	{
		role_id = 0;
		role_name.clear();
		pet_name.clear();
		bang_name.clear();
		data = 0;
		festival_type = 0;
		goods.clear();
		xiang = 0;
		sex = 0;
		wingId = 0;
	}
	
	uint32 role_id;
	string role_name;
	string pet_name;
	uint32 data;
	uint8 festival_type;
	string bang_name;
	vector <struct Goods> goods;
	uint8 xiang;
	uint8 sex;
	uint32 wingId;
};

struct HongLiInfo
{
	uint32 YB;
	uint32 index;
	uint32 type;
};

struct EquipInfo
{
	EquipInfo()
	{
		count = 0;
		lv = 0;
		index = 0;
	}

	uint8 count;
	uint32 lv;
	uint32 index;
};

struct SZhaDanInfo
{
	SZhaDanInfo()
	{
		type = 0;
		award = 0;
		num = 0;
		petQt = 0;
		petQtLv = 0;
		rate = 0;
		isJinPin = 0;
		isShow = 0;
		notice = 0;
	}

	uint8 type;
	uint32 award;
	uint32 num;
	uint16 petQt;
	uint16 petQtLv;
	uint32 rate;
	uint8 isJinPin;
	uint8 isShow;
	uint8 notice;
};

struct SZhaDanCostInfo
{
	SZhaDanCostInfo()
	{
		count = 0;
		YB = 0;
	}
	uint32 count;
	uint32 YB;
};

struct SFestivalAward
{
	SFestivalAward()
	{
		type = 0;
		startId = 0;
		endId = 0;
		idx = 0;
		score = 0;
	}

	uint8 type;
	uint8 startId;
	uint8 endId;
	uint8 idx;
	uint32 score;
};

struct GoodsInfo
{
	GoodsInfo()
	{
		award = 0;
		score_get = 0;
		score_give = 0;
		get_data_id = 0;
		give_data_id = 0;
		num = 0;
	}

	uint32 award;
	uint32 score_get;
	uint32 score_give;
	uint32 get_data_id;
	uint32 give_data_id;
	uint32 score_id;
	uint32 num;
};

struct HDBangGoods
{
	uint32 pic;
	vector<GoodsInfo> info;
};

struct SShaoDangAward
{
	SShaoDangAward()
	{
		type = 0;
		id= 0;
		petQuality= 0;
		petAvoluteStar= 0;
	}
	uint8 type;
	uint16 id;
	uint8 petQuality;
	uint8 petAvoluteStar;
};

struct HDHongBaoPlayerInfo
{
	HDHongBaoPlayerInfo()
	{
		role_id = 0;
		role_name.clear();
		sex = 0;
		xiang = 0;
		end_time = 0;
		yb = 0;
	}

	uint32 role_id;
	string role_name;
	uint8 sex;
	uint8 xiang;
	uint32 end_time;
	uint32 yb;
};

struct HDHongBaoInfo
{
	HDHongBaoInfo()
	{
		renqi_role_id = 0;
		yb_random_chi = 0;
		get_player_infos.clear();
	}
	
	HDHongBaoPlayerInfo send_player_info;
	uint32 renqi_role_id;
	uint32 yb_random_chi;
	vector<HDHongBaoPlayerInfo> get_player_infos;
};

struct HDHongBaoGetRecord
{
	HDHongBaoGetRecord()
	{
		roleId = 0;
		sendHBCount = 0;
		renQiKingCount = 0;
		isDirty = false;
	}
	uint32 roleId;
	uint32 sendHBCount;
	uint32 renQiKingCount;
	bool isDirty;
};

struct HuanLeSYPaiHangData
{
	HuanLeSYPaiHangData()
	{
		Clear();
	}
	void Clear()
	{
		roleId = 0;
		roleName = "";
		jifen = 0;
	}

	uint32 roleId;
	string roleName;
	int jifen;
};

struct SSortHLSY
{
	bool operator()(HuanLeSYPaiHangData const b1,HuanLeSYPaiHangData const b2)
	{
		return b1.jifen > b2.jifen;
	}
};


class CHuoDongAwardManager
{
public:
	typedef vector<SHuoDongAward> HuoDongList;
	typedef vector<HDExchangeInfo> HDExchangeList;	
	typedef vector<HDPaiHangInfo> HDPaiHangList;
	typedef vector<HDRandAwardInfo> HDRandAwardList;
	typedef vector<HDPaiHangRecordInfo> HDPaiHangRecordList;

	static const uint32 MEIRI_SHOUCHONG = 1;	//每日首充
	static const uint32 JIERI_LIBAO = 2;		// 节日礼包
	static const uint32 LEI_JI_CHONGZHI = 3;	// 累计充值
	static const uint32 LEI_JI_XIAOFEI = 4;		// 累计消费
	static const uint32 KAI_FU_CHONGJISAI = 5;	// 开服冲级赛
	static const uint32 XIN_FU_ZHANLIBANG = 6;	// 新服战力榜
	static const uint32 XIAN_CHONG_DASHOUJI = 7;	// 仙神将大搜集
	static const uint32 QIANG_ZHUANG_LINGHAOLI = 8;	// 强装领好礼
	static const uint32 ZHENG_DIAN_ZAIXIAN = 9;		//整点在线礼包
	static const uint32 CHONG_ZHI_FAN_YUANBAO = 10;	//每日大返利
	static const uint32 HONGLI_CHONGZHI = 11;  		//红利大放送 充值
	static const uint32 HONGLI_XIAOFEI = 12;		//红利大放送 消费
	static const uint32 SHEN_CHONG_BANG = 13;		// 最强神将榜
	static const uint32 EQUIP_QIANGHUA_BANG = 14;	// 仙甲强化榜
	static const uint32 ROLE_LEVEL_BANG = 15;	// 等级冲刺榜
	static const uint32 ZHAN_LI_BANG = 16;		// 群仙战力榜
	static const uint32 CHONG_ZHI_BANG = 17;	// 新服充值榜
	static const uint32 QIANGHUA_KUANGHUAN = 18;	// 强化狂欢礼
	static const uint32 SHENGJIE_LETIAN = 19;	// 升阶乐翻天
	static const uint32 ZHA_DAN = 20;	// 砸蛋
	static const uint32 FESTIVAL = 21;	//节日
	static const uint32 LIANXU_CHONGZHI_ORI = 22; //连续充值-普通
	static const uint32 LIANXU_CHONGZHI_DELUXE = 23; //连续充值-豪华
	static const uint32 JIERI_LIBAO2 = 24;			// 节日礼包2
	static const uint32 LEI_JI_CHONGZHI2 = 25;		// 累计充值2
	static const uint32 LEI_JI_XIAOFEI2 = 26;		// 累计消费2
	static const uint32 CHONG_ZHI_FAN_YUANBAO2 = 27;	// 每日大返利2
	static const uint32 CHONG_ZHI_FAN_YUANBAO3 = 28;	// 每日大返利3
	static const uint32 SHOU_CHONG = 29;	// 首充
	static const uint32 CI_CHONG = 30;	// 次充
	static const uint32 CHONG_ZHI_FAN_YUANBAO4 = 31;	// 每日大返利4
	static const uint32 CHONG_ZHI_FAN_YUANBAO5 = 32;	// 每日大返利5
	static const uint32 WING_BANG = 33;	// 神级羽翼榜
	static const uint32 HONGLI_CHONGZHI_RMB = 34;  		//红利大放送 充值 RMB
	static const uint32 HONGLI_JIFEN = 35;  		//红利积分
	static const uint32 JIJIN_FANLI = 36;  		//基金返利
	static const uint32 DAOJUHUISHOU = 37;	//道具回收
	static const uint32 MEIRI_HUANHAOLI = 38;  		//每日换好礼
	static const uint32 SHENGDAN_FENGSHOU = 39;  		//圣诞大丰收
	static const uint32 EXP_TEN_REWARD = 40;	//经验10倍送
	static const uint32 XTMAS_BOX = 41;	//圣诞宝箱
	static const uint32 XIANSHI_CHOU = 42;	// 限时抽活动
	static const uint32 KOREA_MONEY_GIFT_BAG_1 = 43; //韩版直购活动1
	static const uint32 KOREA_MONEY_GIFT_BAG_2 = 44;	//韩版直购活动2
	static const uint32 CHONG_ZHI_FAN_YUANBAO6 = 45;	// 每日大返利6
	static const uint32 CHONG_ZHI_FAN_YUANBAO7 = 46;	// 每日大返利7
	static const uint32 CHONG_ZHI_FAN_YUANBAO8 = 47;	// 每日大返利8
	static const uint32 CHONG_ZHI_FAN_YUANBAO9 = 48;	// 每日大返利9
	static const uint32 CHONG_ZHI_FAN_YUANBAO10 = 49;	// 每日大返利10
	static const uint32 HONGLI_JIFEN2 = 50;	// 红利积分2
	static const uint32 HONGLI_JIFEN3 = 51;	// 红利积分3
	static const uint32 HONGLI_JIFEN4 = 52;	// 红利积分4
	static const uint32 HONGLI_JIFEN5 = 53;	// 红利积分5
	static const uint32 HONGLI_CHONGZHI2 = 54;		//红利大放送 充值2
	static const uint32 HONGLI_CHONGZHI3 = 55;  	//红利大放送 充值3
	static const uint32 HONGLI_CHONGZHI4 = 56;  	//红利大放送 充值4
	static const uint32 HONGLI_CHONGZHI5 = 57;  	//红利大放送 充值5
	static const uint32 HONGLI_XIAOFEI2 = 58;		//红利大放送 消费2
	static const uint32 HONGLI_XIAOFEI3 = 59;		//红利大放送 消费3
	static const uint32 HONGLI_XIAOFEI4 = 60;		//红利大放送 消费4
	static const uint32 HONGLI_XIAOFEI5 = 61;		//红利大放送 消费5
	static const uint32 JIJIN_FANLI2 = 62;  		//基金返利2
	static const uint32 JIJIN_FANLI3 = 63;  		//基金返利3
	static const uint32 DUOBAO_CHOU = 64;  		//欢乐"夺宝" 大奖抽抽抽

	static const uint32 FIND_YOUYUANREN = 66;  	//寻找有缘人
	static const uint32 XINCHUN_HAPPY = 67;  	//新春快乐
	static const uint32 ZHENYING_PK = 68;  		//阵营PK
	static const uint32 QIANG_HONGBAO = 69;  	//抢红包
	static const uint32 YAOSHI_SHANGDIAN = 70;  //妖石商店
	static const uint32 HUOYUE_TASK = 71;  		//活跃任务
	static const uint32 MEIRI_XIAOFEI1 = 72;  	//每日消费1
	static const uint32 MEIRI_XIAOFEI2 = 73;  	//每日消费2
	static const uint32 MEIRI_XIAOFEI3 = 74;  	//每日消费3
	static const uint32 MEIRI_XIAOFEI4 = 75;  	//每日消费4
	static const uint32 MEIRI_XIAOFEI5 = 76;  	//每日消费5
	static const uint32 MOGU = 77;  			//蘑菇
	static const uint32 ZHOU_NIAN_QING_1 = 78;	//周年庆-欢乐盛宴
	static const uint32 ZHOU_NIAN_QING_2 = 79;	//周年庆-保卫战
	//add by zhudaolong
	static const uint32 TAOHUAGENG = 80;		//桃花羹
	static const uint32 LEVEL_JIJIN1_FANLI = 83;//等级基金返利
	static const uint32 SHENJIANG_ZHEKOU = 84;//神将折扣
	static const uint32 XIANHUA_MEILI = 85;//魅力排行
	static const uint32 ZHEKOU_HUODONG1 = 86;//折扣活动
	static const uint32 ZHEKOU_HUODONG2 = 87;//折扣活动
	static const uint32 ZHEKOU_HUODONG3 = 88;//折扣活动
	static const uint32 ROUND_ZHEKOU_HUODONG1 = 89;//折扣活动
	static const uint32 ROUND_ZHEKOU_HUODONG2 = 90;//折扣活动
	static const uint32 ROUND_ZHEKOU_HUODONG3 = 91;//折扣活动
	static const uint32 ZHA_DAN_COPY = 92;	// 砸蛋

	static const uint32 HUOYUE_JIJIN_FANLI = 94;	// 活跃基金
	static const uint32 DAILY_CHONGZHI_FANLI = 95;	// 每日充值返利

	static const uint32 EXP_TEN_REWARD_START = 19;
	static const uint32 EXP_TEN_REWARD_END = 21;
	static const uint32 CHOU_MIN = 40;
	static const uint32 CHOU_MIN_CLEAR = 50;
	static const uint32 CHOU_NOT_START = 0;
	static const uint32 CHOU_START = 1;
	static const uint32 CHOU_DOING = 2;
	static const uint32 CHOU_END = 3;
	static const uint32 CHOU_AWARD = 1;
	static const uint32 CHOU_AWARD2 = 2;
	static const uint32 CHOU_AWARD_NONE = 0;
	static const uint32 CHOU_JIANG_COST_IDX2 = 0;
	static const uint32 CHOU_JIANG_COST_IDX3 = 0;

	static const int YOUYUANREN_TIME = 10;
	static const int YOUYUANREN_NPC_ID = 234;
	static const int YOUYUANREN_AWARD_RANK = 3;

	static const int SHOUCHONG_AWARD_NUM = 3;  	//	每日首冲奖励个数
	static const int SHOUCHONG_WEIXIN_IDX = 4;  // 每日微信首冲奖励idx

	//圣诞活动
	static const uint32 CHRISTMAS_TREE_ID = 221;
	static const uint32 CHRISTMAS_TREE_IDX2_CHENGZHANG = 1;
	static const uint32 CHRISTMAS_TREE_IDX2_PERSON = 2;
	static const uint32 CHRISTMAS_TREE_IDX2_PAIHANG = 3;

	// 新春快乐
	static const uint32 XINCHUN_HAPPY_IDX2_ZITI = 1;
	static const uint32 XINCHUN_HAPPY_IDX2_JIFEN = 2;
	static const uint32 XINCHUN_HAPPY_IDX2_PAIHANG = 3;

	//阵营PK
	static const uint32 ZHENYING_PK1 = 6801;  		//阵营PK1
	static const uint32 ZHENYING_PK2 = 6802;  		//阵营PK2
	static const uint32 ZHENYING_PK_ALL_IDX2 = 1;	// 全阵营奖励idx2
	static const uint32 ZHENYING_PK_MEM_IDX2 = 2;	// 阵营奖励idx2

	//抢红包
	static const uint32 MOUNT_SEND_HB = 10;  		//元宝儿
	static const uint32 WING_SEND_HB = 5;
	static const uint32 WING_RENQI_KING = 10;

	static const uint8 QIANGHB_HONGDIAN = 1;
	static const uint8 QIANGHB_UP = 2;
	static const uint8 QIANGHB_DOWN = 3;

	//活跃任务
	static const uint8 HUOYUE_TASK_COMPLETE_IDX2 = 1; //任务完成奖励
	static const uint8 HUOYUE_TASK_BOX_IDX2 = 2; //宝箱任务奖励

	CHuoDongAwardManager();
	~CHuoDongAwardManager(){}

	bool Init();
	bool InitHDPaiHangRecord();
	void SaveHDPaiHangRecord(bool isSave = false);
	bool InitHDSave();
	bool InitHDQiangHongBao();
	void SetFindYouYuanRenStr(string &save_data);
	void SaveHDPaiHangRecordInfo(uint32 type, vector<HDPaiHangRecordInfo> &info,bool isSendAward = false);
	void TimeOut();
	void HuanLeShengYanTimer();
	void FindYouYuanRenTimer();
	void Save();
	void GetFindYouYuanRenStr(string &str);
	void GetAwardData(uint32 type, uint32 idx, SHuoDongAward &awardList);
	void GetAwardDataByRange(uint32 type, uint32 idx, uint32 range, SHuoDongAward &awardList);
	void GetAwardDataList(uint32 type,vector<uint32> idxs,vector<SHuoDongAward> &awardList);
	void GetAwardIdxList(uint32 type,vector<uint32> &idxList);
	void GetAwardIdxList(uint32 type,uint32 idx2,vector<uint32> &idxList);
	void GetNoLockAwardIdxList(uint32 type,uint32 idx2,vector<uint32> &idxList);
	uint32 GetAwardIdx(uint32 type, uint32 idx2, uint32 idx3);
	uint32 GetLevelJiJinAwardIdx(uint32 type, uint32 jjlv, uint32 getindex, uint32 userLevel);
	int GetFestivalAwardIdxCnt(uint16 festivalType);
	int GetNeedYB(uint32 type,uint32 idx);
	int GetIdx3(uint32 type,uint32 idx);
	bool CheckHuoDongShow(uint32 type);
	int GetHuoDongInfo(uint32 type, SHuoDongInfo &info);
	int GetHuoDongList(vector<uint32> &list);
	bool InHuoDongTime(uint32 type);
	bool InHuoDongHour(uint32 type);
	void GetHuoDongHour(uint32 type,uint32 &startHour,uint32 &endHour);
	bool InHuodongLimit(CUser *pUser,uint32 type);
	uint32 GetHuoDongZeroStartTime(uint32 type);
	uint32 GetHuoDongStartTime(uint32 type);
	uint32 GetHuoDongEndTime(uint32 type);
	string GetHuoDongTimeDesc(uint32 type);
	uint32 GetHuoDongIconEndTime();
	uint32 GetHuoDongPic(uint32 type);
	uint32 GetHuoDongLeijiTime(uint32 type);
	bool InHuoDongLeijiTime(uint32 type);
	string GetHuoDongLeiJiTimeDesc(uint32 type);
	void GetZhaDanShowInfo(vector<struct SZhaDanInfo> &info, int type);
	bool AddZhaDanAward(CUser *pUser, uint32 count, uint8 type, vector<string> &myHisTory, vector<string> &publicHistory, uint32 costYB, int& idx);
	void GetZhaDanPubHistory(vector<string> &publicHistory);
	void AddZhaDanPubHistory(uint32 role_id, vector<string> &publicHistory);
	string GetHuoDongName(uint32 type);
	void GetFestivalAward(uint8 festivalType, vector<SFestivalAward> &award);
	void GetHDBangGoods(uint32 pic, vector<GoodsInfo> &info,uint32 hd_type);
	uint32 GetFestivalMinScore(uint32 festivalType);
	uint32 GetFestivalAwardIdx3(uint32 festivalType, uint32 paiHang, uint32 score);
	void GetPeiZhiInfo(vector<HDPeiZhiInfo> &info, uint32 type);
	void GetPeiZhiInfo(HDPeiZhiInfo &info, uint32 type, uint32 idx);
	bool GetDailyFanliCfg(uint32 yb, HDPeiZhiInfo& cfg);
	bool GetExchangeInfo(uint32 type, uint32 idx, HDExchangeInfo &info);
	void GetExchangeInfo(uint32 type, HDExchangeList &info);
	void GetHDPaiHangInfo(uint32 type, HDPaiHangList &info);
	void GetHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info);
	void SendHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info);
	void GetNoLockHDPaiHangRecord(uint32 type, vector<HDPaiHangRecordInfo> &info);
	uint32 GetHDPaiHangAwardIdxByRank(uint32 type, uint32 rank);
	bool AddHDRandAward(CUser *pUser,  uint32 huodong_type, uint32 count, uint32 costYB);
	void UpdatePaiHang(CUser *pUser,uint32 type,uint32 data);
	uint32 GetPaiHangLimitScore(uint32 type);
	uint32 GetPaiHangSize(uint32 type);
	bool GetPaiHangState(uint32 type);
	void SetPaiHangState(uint32 type);
	void ClearPaiHangState(uint32 type);
	void PaiHangBangTimer();
	//add by zhudaolong 2017.11.01
	void GetMaterialInfo(map<uint32,uint32> &materialinfo);
	
	void Print();
	void CheckXtmasTree();
	void CheckXtmasBox();
	void CheckKuaFuXueLian();
	void AddXueLianIndex(int index);

	void ClearXtmasBox_New();
	void CheckXtmasBox_New();
	void ClearFestivalPaiHang();

	void SetMoGuAwardDay(uint32 type, uint32 sTime, uint32 eTime,uint32 waterDay,uint32 &moguDay);
	uint32 GetMoGuWaterDay();
	uint32 GetMoGuAwardDay();
	uint32 GetMoGuWaterCZ();
	uint32 GetMoGuBugCZ();
	uint32 GetMoGuStep1CZ();
	uint32 GetMoGuStep2CZ();

	void HDChouTimer();
	uint8 GetChouState(uint32 curMin);
	uint32 GetChouCount(uint32 time,uint32 role_id);
	string GetChouWinPlayName(uint32 time);
	void GetChouInfo(map<uint32,HDChouInfo> &chouInfo,uint32 time);
	void HDChouSendAward(uint32 time,uint32 curHour);
	bool HDBetChou(CUser *pUser,uint32 curTime);
	void SetChouInfo(HDChouInfo &chouInfo,uint32 time);
	bool GetChouAwardInfo(uint32 &costId,int &costNum,uint32 &awardId,int &awardNum,string &errStr);
	int GetFindYouYuanRenCount();
	void AddFindYouYuanRenCount(int count = 1);
	uint32 MakeFindYouYuanRenCurTime();

	void SetChristmasTreeStr(string &save_data);
	void GetChristmasTreeStr(string &str);
	uint32 GetChristmasChengZhangZhi();
	void AddChristmasChengZhangZhi(uint32 value);
	uint32 GetChristmasStartTime();
	void SetChristmasStartTime(uint32 time);
	void ClearChristmasInfo();
	bool GetHDExchangeScoreInfoByItem(uint32 itemId, struct HDItemScoreExchangeInfo &info);
	uint32 GetZhenYingScore(uint32 zhenYingType);
	uint32 AddZhenYingScore(uint32 zhenYingType,uint32 score);
	struct ZhenYingScoreInfo GetZhenYingScoreInfo(uint32 zhenYingType);
	uint32 GetZhenYingWinId();
	void SetZhenYingPKStr(string &save_data);
	void GetZhenYingPKStr(string &str);

	uint32 FaBuHongBao(CUser *pUser,HDPeiZhiInfo &info);
	void GetHongBaoList(vector<HDHongBaoInfo> &infos);
	void ClickHongBao(HDPeiZhiInfo &info,uint32 role_id,CUser *pUser,CNetMessage &msg);
	void NoLockAddRenqiRecord(uint32 role_id,CUser *pUser);
	void GetHDHongBaoRecord(uint32 role_id,HDHongBaoGetRecord &record);
	void DelInvalidHongBao();
	void GetQiangHongBaoStr(string &str);
	void SetQiangHongBaoStr(string &save_data);
	void NoLockSetSaveQiangHongBao();
	void SaveQiangHongBaoRecord(bool save = false);
	void UpdateHLSY_PaiHangData(int roleId,string name,int jifen);
	bool MakeHLSYPaiHangData(CUser *pUser,CNetMessage &msg,vector<SHuoDongAward> &awardList);
	bool CheckServerOpenInDay(int day);
	uint16 ServerOpenDay();
	uint32 ServerOpenZeroTime();
	
	void GetHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg);
	void BuyHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg);
	void GetXunHuanHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg);
	void BuyXunHuanHDSingleAwardMsg(CUser *pUser, int type, CNetMessage& msg);
	int GetHuoDongZhouQi(int type);
	void GetFestivalRankAward(int type,int rank,int score,SHuoDongAward &award);
	void MakeFestivalItem(CNetMessage &msg);
	bool SendItemToFriend(CUser *pUser,uint16 itemId,int itemNum,int roleId,CNetMessage &msg);
	bool GetMeilLiSendLog(int roleId,int type,CNetMessage &msg);
	int GetFestivalItemScore(int isGet,int itemId);

private:
	bool InitAward();
	bool InitInfo();

	bool InitZhaDan();
	bool InitZhaDanInfo();
	bool InitZhaDanHistory();
	
	bool InitFestivalAward();
	bool InitHDBangGoods();

	bool InitPeiZhiInfo();
	bool InitExchangInfo();

	bool InitHDPaiHangInfo();
	bool InitHDRandAwardInfo();

	bool InitHDChouInfo();

	bool InitHDItemScoreExChange();
	//add by zhudaolong 2017.11.01
	bool InitHDTaoHuaGengInfo();
	
	
    int GetZeroTime(const char *srcTime);//获取到当天0点的秒数
	void ChargeTime(const char *srcTime, string &dstTime);
	void ChargeBangTime(const char *srcTime, string &sTime,string &eTime);
	void GetTimeDesc(uint32 type, const char *sTime, const char *eTime, string &timeDesc);
	void GetHistory(CUser *pUser, SZhaDanInfo *info, vector<string> &myHisTory, vector<string> &publicHistory);

	uint32 GetHDRandAwardIdx(HDRandAwardList &info, uint32 maxRate);
	void GetHDRandAwardInfo(uint32 type,HDRandAwardList &info);

	bool FindYouYuanRenNpcExist();
	uint32 GetFindYouYuanRenNpcFlushTime();
	bool FindYouYuanRenNpcCreate(int pos_index);
	void FindYouYuanRenNpcDisappear();

	bool HDPaiHangCompare(struct HDPaiHangRecordInfo &a,struct HDPaiHangRecordInfo &b,uint32 hd_type);

private:
	boost::recursive_mutex m_mutex;
	boost::recursive_mutex m_paiHang_mutex;
	map<uint32,HuoDongList> m_award;
	map<uint32,SHuoDongInfo> m_info;
	vector<uint32> m_list;

	// 砸蛋
	vector<SZhaDanInfo> m_ybZhaDan;	// 1 
	uint32 m_ybMaxRate;
	vector<SZhaDanInfo> m_copyZhaDan;
	uint32 m_copyMaxRate;
	list<string> m_zhaDanPublicHistory;

	// 限时抽活动的最大概率
	uint32 m_XianShiChouMaxRate;

	//节日活动
	vector<struct SFestivalAward> m_festival_award[2];
	uint32 m_festival_min_score[2];
	map<uint32, HDBangGoods> m_hd_bang_goods;

	// 活动配置
	map<uint32, vector<struct HDPeiZhiInfo> > m_peizhi_info;

	// 活动随机表
	map<uint32, HDRandAwardList> m_randAward_info;

	//add by zhudaolong 2017.11.01
	//桃花羹活动配置信息
	map<uint32, uint32> m_THG_material_info;
	//正确的菜单顺序
	HDExchangeList m_THG_correct_material;

	// 活动排行配置信息
	map<uint32, HDPaiHangList> m_paiHang_info;

	// 活动排行榜记录
	map<uint32, HDPaiHangRecordList> m_paiHang_record;	//	排行榜记录
	map<uint32 ,uint32> m_paiHang_size;
	map<uint32 ,uint32> m_paiHang_state;

	// 活动兑换
	map<uint32,HDExchangeList> m_exchange_info;
	vector<int> xtmasbox_index_vec;
	vector<int> xuelian_index_vec;
	map<int,vector<int> > m_xtmasbox_map;//key-场景ID

	// 欢乐盛宴排行
	vector<HuanLeSYPaiHangData> m_hlsy_paihang;
	bool m_needSort;

	// 抽大奖
	//   time       role_id
	map<uint32, map<uint32,HDChouInfo> > m_chou_info;
	map<uint32,vector<uint32> > m_chou_list;

	//寻找有缘人
	uint32 m_npc_flush_time;//数据:年+月+日+小时
	int m_npc_index;
	int m_count;

	// 圣诞活动
	uint32 m_christmas_changzhangzhi;	//圣诞树成长值
	uint32 m_christmas_starttime;		// 活动开始时间

	map<uint32,struct HDItemScoreExchangeInfo> m_item_score_exchange; // item 和 积分兑换表

	map<uint32,map<uint32,struct ZhenYingScoreInfo> > m_zhenyingPK_socre;

	//抢红包
	list<HDHongBaoInfo> m_hongbao_list; // 红包列表
	map<uint32,HDHongBaoGetRecord> m_hongbao_record;
	bool m_save_hb_data;
	uint32 m_startSec;

	bool m_box_refresh_sign;//类型41 圣诞宝箱活动 刷新Box标识
	int m_box_index;//宝箱生成索引,用于Npc删除
};

#define sCHuoDongAwardManager boost::details::pool::singleton_default<CHuoDongAwardManager>::instance()

struct SCardReqData
{
	SCardReqData()
	{
		xiang = 0;
		sex = 0;
		level = 0;
		roleId = 0;
		name.clear();
	}
	uint8 xiang;
	uint8 sex;
	uint16 level;
	uint32 roleId;
	string name;
};

struct WaintingUser
{
	WaintingUser()
	{
		npc_id = 0;
		npc_index = 0;
		user_id = 0;
	}
	bool operator==(const WaintingUser &info)
	{
		if( info.user_id == user_id && info.npc_id == npc_id && info.npc_index == npc_index)
			return true;
		return false;
	}
	int npc_id;
	int npc_index;
	int user_id;
};
class CWaitForFightManager
{
	public:
	CWaitForFightManager();
	void EnterWaitingList(int user_id,int npc_id,int index);
	void StartToFight( CUser *pUser ,int npc_id,int index,int des=1);
	bool FightCheck( int user_id);
	void ClearNpcInfo(int npc_id);
	void ClearUserInfo(uint32 user_id);
	private:
	boost::recursive_mutex m_mutex;
	std::vector<WaintingUser> waitForFightList;
	typedef std::vector<WaintingUser>::iterator WaitForFightIter;
};

struct FestivalRandomBoxCfg
{
	FestivalRandomBoxCfg()
	{
		box_id = 0;
		item_id = 0;
		odds = 0;
		num = 0;
		quality = 0;
		quality_level = 0;
		notice = 0;
		day_limit = 0;
	}
	uint32 box_id;
	uint32 item_id;
	uint32 odds;
	uint32 num;
	uint32 quality;
	uint32 quality_level;
	uint32 notice;
	uint32 day_limit;
};
struct FestivalRandomBoxAward
{
	FestivalRandomBoxAward()
	{
		id = 0;
		item_id = 0;
		num = 0;
		quality = 0;
		quality_level = 0;
		notice = 0;
	}
	uint32 id;
	uint32 item_id;
	uint32 num;
	uint32 quality;
	uint32 quality_level;
	uint32 notice;
};
typedef std::vector<FestivalRandomBoxAward> FestivalAwardVec;
class CFestivalRandomBoxManager
{
	public:
	CFestivalRandomBoxManager();
	bool Init();
	void TimeOut();
	bool LoadCfg();
	bool UseBox( CUser *pUser,uint32 item_id,uint8 pos, int num );
	bool isFestivalRandomBox( uint32 item_id);
	void DoOnceRandom( uint32 box_id , FestivalAwardVec &award_vec);
	void AddAllAward(CUser *pUser,uint32 item_id, FestivalAwardVec &award_vec);
	private:
	boost::recursive_mutex m_mutex;
	int last_fresh_day;
	int randombox_stamp;//随机宝箱数据库刷新时间戳  
	std::vector<uint32> boxIdVec;
	std::map<uint32,uint32> limitSaveMap;
	std::map<uint32,FestivalRandomBoxCfg> randombox_cfg;//随机宝箱配置
};


struct XianYuanCardInfo
{
	XianYuanCardInfo()
	{
		card_id = 0;
		name="";
		quality = 0;
		xy_value = 0;
		single_odds = 0;
		ten_odds = 0;
		isNotice = 0;
		item_id = 0;
	}
	uint32 card_id;
	string name;
	uint32 quality;
	uint32 xy_value;
	uint32 single_odds;
	uint32 ten_odds;
	uint32 isNotice;
	uint32 item_id;
};
struct XianYuanChapterInfo
{
	XianYuanChapterInfo()
	{
		chapter_id = 0;
		need_card1 = 0;
		need_card2 = 0;
		need_card3 = 0;
		need_card4 = 0;
		need_card5 = 0;
		attr_type1 = 0;
		attr_value1 = 0;
		attr_type2 = 0;
		attr_value2 = 0;
		attr_type3 = 0;
		attr_value3 = 0;
		attr_type4 = 0;
		attr_value4 = 0;
	}
	uint32 chapter_id;
	uint32 need_card1;
	uint32 need_card2;
	uint32 need_card3;
	uint32 need_card4;
	uint32 need_card5;
	uint32 attr_type1;
	uint32 attr_value1;
	uint32 attr_type2;
	uint32 attr_value2;
	uint32 attr_type3;
	uint32 attr_value3;
	uint32 attr_type4;
	uint32 attr_value4;
};

class CXianYuanManager
{
	public:
	CXianYuanManager();
	bool Init();
	void TimeOut();
	bool GetXianYuanCardInfoByID(uint32 card_id,XianYuanCardInfo &info);
	bool GetXianYuanChapterInfoByID(uint32 chapter_id,XianYuanChapterInfo &info);
	bool DoCardRandom(CUser *pUser,uint32 &card_id ,uint8 type,uint32 &quality);
	bool DoTenCardRandom(CUser *pUser,std::vector<uint32> &card_map);
	bool LoadXianYuanCardDB();
	bool LoadXianYuanChapterDB();
	int GetXianYuanCardQualityColor( uint32 quality);
	void MakeDisPlayCardMsg( CNetMessage &msg);
	uint32 GetRandomCardByQuality( uint32 quality);
	bool InitDisPlayCard();
	bool isCardItemID( uint32 id);
	bool XianYuanItemToCard( CUser *pUser,uint32 item_id ,uint8 pos,int num);
	private:
	uint32 totalOdds;
	uint32 totalTenOdds;
	uint32 display_card[6];
	std::map<uint32,XianYuanCardInfo> cardMap;
	typedef std::map<uint32,XianYuanCardInfo>::iterator CardMapIter;
	std::map<uint32,XianYuanChapterInfo> chapterMap;
	typedef std::map<uint32,XianYuanChapterInfo>::iterator ChapterMapIter;

};

enum XianYuanAttrType
{
	XIANYUAN_ATTR_USER_DAM			=	1	,//	人物伤害	
	XIANYUAN_ATTR_USER_DEF			=	2	,//	人物防御	
	XIANYUAN_ATTR_USER_HP			=	3	,//	人物气血	
	XIANYUAN_ATTR_USER_SPEED		=	4	,//	人物速度	
	XIANYUAN_ATTR_USER_HIT			=	5	,//	人物命中	
	XIANYUAN_ATTR_USER_SHANBI		=	6	,//	人物闪避	
	XIANYUAN_ATTR_USER_BANG			=	7	,//	人物暴击	
	XIANYUAN_ATTR_USER_RENXING		=	8	,//	人物韧性	
	XIANYUAN_ATTR_USER_FANSHANG		=	9	,//	人物反伤	
	XIANYUAN_ATTR_USER_JIANSHANG	=	10	,//	人物减伤	
	XIANYUAN_ATTR_EQUIP_BASE_DAM	=	11	,//	装备基础伤害	(百分比)
	XIANYUAN_ATTR_EQUIP_BASE_DEF	=	12	,//	装备基础防御	(百分比)
	XIANYUAN_ATTR_EQUIP_BASE_HP		=	13	,//	装备基础气血	(百分比)
	XIANYUAN_ATTR_EQUIP_S_DAM		=	14	,//	装备强化伤害	(百分比)
	XIANYUAN_ATTR_EQUIP_S_DEF		=	15	,//	装备强化防御	(百分比)
	XIANYUAN_ATTR_EQUIP_S_HP		=	16	,//	装备强化气血	(百分比)
	XIANYUAN_ATTR_PET_DAM			=	17	,//	神将伤害	
	XIANYUAN_ATTR_PET_DEF			=	18	,//	神将防御	
	XIANYUAN_ATTR_PET_HP			=	19	,//	神将气血	
	XIANYUAN_ATTR_PET_SPEED			=	20	,//	神将速度	
	XIANYUAN_ATTR_PET_HIT			=	21	,//	神将命中	
	XIANYUAN_ATTR_PET_SHANBI		=	22	,//	神将闪避	
	XIANYUAN_ATTR_PET_BANG			=	23	,//	神将暴击	
	XIANYUAN_ATTR_PET_RENXING		=	24	,//	神将韧性	
	XIANYUAN_ATTR_PET_FANSHANG		=	25	,//	神将反伤	
	XIANYUAN_ATTR_PET_JIANSHANG		=	26	,//	神将减伤	
	XIANYUAN_ATTR_PET_BASE_DAM		=	27	,//	神将本体伤害	(百分比)
	XIANYUAN_ATTR_PET_BASE_DEF		=	28	,//	神将本体防御	(百分比)
	XIANYUAN_ATTR_PET_BASE_HP		=	29	,//	神将本体气血	(百分比)
	XIANYUAN_ATTR_PET_BLOOD_DAM		=	30	,//	神将血脉伤害	(百分比)
	XIANYUAN_ATTR_PET_BLOOD_DEF		=	31	,//	神将血脉防御	(百分比)
	XIANYUAN_ATTR_PET_BLOOD_HP		=	32	//	神将血脉气血	(百分比)
};


//榜的key
struct StKuaFu1Vs1SortKey
{
	StKuaFu1Vs1SortKey()
	{
		score = 0;
		zhandouli = 0;
		role_id = 0;
	}
	//比较规则：积分按从高到低顺序排列 排序优先级：积分>战斗力>角色ID
	bool operator <(const StKuaFu1Vs1SortKey other) const
	{
		if( score > other.score)
		{
			return true;
		}
		else if( score == other.score && zhandouli > other.zhandouli)
		{
			return true;
		}
		else if ( score == other.score && zhandouli == other.zhandouli  && role_id < other.role_id)
		{
			return true;
		}
		return false;
	}
	bool operator ==(const StKuaFu1Vs1SortKey other) const
	{
		if( role_id == other.role_id )
		{
			return true;
		}
		return false;
	}
	int score;		//积分
	int zhandouli;	//战斗力
	int role_id;	//角色ID
};
//榜的内容
struct StKuaFu1Vs1SortUserInfo
{
	StKuaFu1Vs1SortUserInfo()
	{    
		Clear();
	}
	void Clear()
	{
		role_id = 0; 
		name.clear();
		level = 0;
		xiang = 0; 
		sex = 0; 
		super_level = 0;
		wing_id = 0;
		weapon_id = 0;
		weapon_level = 0; 
		zhandouli = 0;
		winNum = 0;
		server_id = 0;
	}
	int role_id;		//角色ID
	string name;		//名字
	int level;			//等级
	int xiang;			//职业
	int sex;			//性别
	int super_level;	//至尊等级
	int wing_id;		//翅膀ID
	int weapon_id;		//武器ID
	int weapon_level;	//武器level
	int zhandouli;		//战斗力
	int winNum;			//决赛胜利次数
	int server_id;		//服务器id
};
//分配的本组内敌人序号
struct StKuaFu1vs1SelectEnemySeq
{
	StKuaFu1vs1SelectEnemySeq()
	{
		isFind = false;
		rank = 0;
		kind  = 0;
	}
	int kind;	//ememy类型 0 角色 1机器人
	int rank;	//本组内排名
	bool isFind;//是否已被查找到
};

struct SSortKuaFu1V1Data
{
	bool operator()(StKuaFu1Vs1SortUserInfo const &b1,StKuaFu1Vs1SortUserInfo const &b2)
	{
		return b1.zhandouli < b2.zhandouli;
	}
};

struct SKuaFu1V1UserData
{
	SKuaFu1V1UserData()
	{
		Clear();
	}
	void Clear()
	{
		data.Clear();
		rank = 0;
	}
	StKuaFu1Vs1SortUserInfo data;
	uint8 rank;	// 原始排名
};

#ifdef KUA_FU

const int SORT_MAX_NUM = 8;//1号-乾字组、2号-兑字组、3号-离字组、4号-震字组、5号-坤字组、6号-艮字组、7号-坎字组、8号-巽字组
const int MAX_CHALLENGUE_NUM =  5;	//最大挑战次数
typedef map<StKuaFu1Vs1SortKey,StKuaFu1Vs1SortUserInfo> Sort;
typedef map<StKuaFu1Vs1SortKey,StKuaFu1Vs1SortUserInfo>::iterator SortIter;
class CKuaFu1vs1PreliminaryManager
{
public:
	CKuaFu1vs1PreliminaryManager();
	bool LoadDB();
	void SaveDB();
	void SendSingleSortInfo(CUser* pUser ,int sort_id);
	int SearchUserSortID(CUser* pUser,SortIter *it=NULL);
	int SearchUserRankFromSort(CUser* pUser);
	void RearrangeToRandomSort();
	bool IsInKuaFu1vs1PreliminaryTime();
	int MakeUserRankScoreInfo(CUser* pUser,CNetMessage &msg);
	void MakeRankRewardInfo(int rank ,CNetMessage &msg);
	void SendKuaFu1vs1PreliminaryPanelInfo(CUser* pUser);
	void ApplyForKuaFu1vs1Preliminary(CUser* pUser);
	void HandleKuaFu1vs1PreliminaryReq(CUser* pUser);
	int GetLeastKuaFu1vs1PreliminarySortID();
	bool ChooseFiveEnemyFromSort(CUser* pUser);
	bool ChooseOneDifficultyEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info);
	bool ChooseTwoNormalEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info);
	bool ChooseTwoSimpleEnemy(int rank ,int maxNum ,int zhandouli,StKuaFu1vs1SelectEnemySeq *info);
	bool IsChooseRepeatEnemy( int rank , StKuaFu1vs1SelectEnemySeq *info);
	int GetChooseRangeRandomPercentage( int maxNum );
	bool FillUserEnemyInfo(CUser* pUser,int sort_id, StKuaFu1vs1SelectEnemySeq *info);
	bool FillRobotEnemyInfo(CUser* pUser,StKuaFu1vs1SelectEnemySeq *info);
	void SelectEnemyToFight(CUser* pUser,int enemy_seq);
	void AddUserScore( CUser* pUser,bool isWin);
	int GetRewardKind( int rank);
	void SendDayReward();
	void TimeOut();
	void AddChallengeNum( CUser *pUser);
	void RefreshEnemy( CUser *pUser);
	void ClearChallengeCDTime( CUser *pUser);
	int GetAddChallengeNumSpendYB( int total);
	int GetEnemyScoreReward( int pos,bool isWin);
	void FillFinalUserInfo(SKuaFu1V1UserData (*info)[MAX_PAIMING_NUM]);
	void SaveDBByLong();

	static const int LOSE_SCORE = 50;
	
private:
	Sort sortlist[SORT_MAX_NUM];
	int last_rewad_day;
	int last_rearrange_day;
	int day_save;
	boost::recursive_mutex m_mutex;
};
#endif

//榜的key
struct StShenJieMiJingSortKey
{
	StShenJieMiJingSortKey()
	{
		score = 0;
		zhandouli = 0;
		role_id = 0;
	}
	//比较规则：积分按从高到低顺序排列 排序优先级：积分>战斗力>角色ID
	bool operator <(const StShenJieMiJingSortKey other) const
	{
		if(score > other.score)
		{
			return true;
		}
		else if(score == other.score)
		{
			if(zhandouli > other.zhandouli)
			{
				return true;
			}
			else if(zhandouli == other.zhandouli)
			{
				if(role_id < other.role_id)
					return true;
			}
		}
		return false;
	}
	bool operator ==(const StShenJieMiJingSortKey other) const
	{
		if(role_id == other.role_id)
		{
			return true;
		}
		return false;
	}
	uint32 score;		//积分
	uint32 zhandouli;	//战斗力
	uint32 role_id;	//角色ID
};

//榜的内容
struct StShenJieMiJingSortUserInfo
{
	StShenJieMiJingSortUserInfo()
	{    
		Clear();
	}
	void Clear()
	{
		name.clear();
		bangPai = 0;
	}
	string name;		//名字
	int bangPai;		//服务器id
};

struct StBossState
{
//	static const int MAX_BUFF_NUM = 2;
	StBossState()
	{
		init();
		ratio = 0;
	}
	void init()
	{
		boss_id = 0;
		state = 0;
//		for(int i=0;i < MAX_BUFF_NUM;i++)
//		{
//			buff[i] = 0;
//			buffTurn[i] = 0;
//		}
	}
	int boss_id;
	int state;
	int ratio;
	int refresh_day;
//	int buff[MAX_BUFF_NUM];
//	int buffTurn[MAX_BUFF_NUM];
};
enum EBossState
{
	STATE_NEXT			= 0,
	STATE_NOW_FIGFHT	= 1,
	STATE_BEFOR			= 2,
	STATE_TAOPAO		= 3,
};
class CShenJieMiJingManager
{
public:
	CShenJieMiJingManager();
	void JoinIn(CUser *pUser);
	void GetSort(CUser *pUser);
	void GetRoomInfo(CUser *pUser);
	void SwitchRoom(CUser *pUser,int room_id);
	void SummonBoss(int id,CScene *pSceneOne = NULL);
	void ClearCurrentBoss(int state = STATE_BEFOR);
	void SendSortReward();
	void SendSortMail(const char* str, SMailData& mdata);
	void TimeOut(int setHour=-1 ,int setMin=-1);
	bool Init();
	bool LoadDB();
	void SaveDB();
	int GetCurrentBossHp();
	void SetCurrentBossHp(int hp);
	int GetCurrentBossID();
	void HandleBossFightEnd( CUser *pUser,int boss_id,int redeceHp);
	void AddUserScore(CUser *pUser,int score);
	void ClearSort();
	bool CanFight(CUser *pUser);
	void SendPanelInfo(CUser *pUser);
	void FightPunish(CUser *pUser);
	void SendWinReward(CUser *pUser);
	void RefreshBossHp();
	bool MakeBossHpInfo( CNetMessage &msg);
	int GetBossMaxHp();
	void ClearMapBossHpShow();
	void AskClearReliveTime(CUser* pUser);
	void ShowReliveTime(CUser* pUser);
	void ShowReliveTimeClearPanel(CUser* pUser);
	void InitBossState();
	int GetNextBossID();
	void ChangeBoss();
	void GetBossBuffData(int boss_id,StBossState &buff);
	void SetBossStateID(int seq,int boss_id);
	void SetBossState(int id,int state);
	int GetBossState(int id);
	int GetBossID(int seq);
	int GetBossPic(int bossId);
	void SendRedPointInfo(CUser *pUser);
	void AddRedPointInfoToAll();
	void ClearRedPointInfoToAll();
	void SetBossRatio(int seq,int ratio);
	int GetBossRatio();
	void UpBossRatio(int seq);
	void DownBossRatio(int seq);
	void SendBossHpInfoToUser(CUser* pUser);
	void ClearReliveTime(CUser* pUser);
	int GetCurrentBossMaxHp();
	int GetCurBossState();

public:
	void TryBossFight(CUser *pUser);
	
private:
	int currentBossID;
	int currentBossHp;
	int currentBossMaxHp;
	StBossState bossState;	
	typedef map<StShenJieMiJingSortKey,StShenJieMiJingSortUserInfo> Sort;
	typedef map<StShenJieMiJingSortKey,StShenJieMiJingSortUserInfo>::iterator SortIter;
	Sort m_sort;
	bool boss_10_mins_check;
	bool boss_20_mins_check;
	bool isSendReward;
	bool isInitState;
	int boss_dead_time;
	boost::recursive_mutex m_mutex;
};
#define sCShenJieMiJingManager boost::details::pool::singleton_default<CShenJieMiJingManager>::instance()


struct StMoneyGiftBagInfo
{
	StMoneyGiftBagInfo()
	{
		gift_name = "";
		money = 0;
		pay_id ="";
		start_time = 0;
		end_time = 0;
		limit_buy_num = 0;
		limit_type = 0;
		limit_data1 = 0;
		limit_data2 = 0;
		award1 = 0;
		num1 = 0;
		petQt1 = 0;
		petQtLv1 = 0;
		award2 = 0;
		num2 = 0;
		petQt2 = 0;
		petQtLv2 = 0;
		award3 = 0;
		num3 = 0;
		petQt3 = 0;
		petQtLv3 = 0;
	}
	string gift_name;
	int money;
	string pay_id;	// 弃用，每次重新查找
	int start_time;
	int end_time;
	int limit_buy_num;
	int limit_type;
	int limit_data1;
	int limit_data2;
	int award1;
	int num1;
	int petQt1;
	int petQtLv1;
	int award2;
	int num2;
	int petQt2;
	int petQtLv2;
	int award3;
	int num3;
	int petQt3;
	int petQtLv3;
};
struct StHuoDongMoneyGiftInfo
{
	StHuoDongMoneyGiftInfo()
	{
		init();
	}
	void init()
	{
		hd_type = 0;
		giftMap.clear();
	}
	int hd_type;
	map<int,StMoneyGiftBagInfo> giftMap; //key gift_id
};
class CHuoDongMoneyGiftBag
{
public:
	CHuoDongMoneyGiftBag();
	bool MakeHuoDongList(CNetMessage &msg);
	bool MakeHuoDongDeatilInfo(CNetMessage &msg,int hd_type,CUser *pUser);
	bool CheckMoneyGiftBagBuyData(CUser *pUser,int money);
	void ReqCheckBuyLimit(CUser *pUser,int hd_type,int gift_id);
	void GetPayId(int ad,int money,string &payStr);
	bool CheckBuyLimit(CUser *pUser,int limit_type,int limit_data1,int limit_data2,int hd_type,bool isShow = true);
	void SendIconInfo(CUser *pUser);
	int GetMinHuoDongSecondLeft();
	int GetHuoDongSecondLeft(int hd_type);
	void AddUserPayRecordInHuoDongTime(CUser *pUser, int value);
	bool LoadDB();
	void MakeGiftLimitMsg(CNetMessage &msg,CUser *pUser,int limit_type,int limit_data1,int limit_data2,int hd_type);
	void AddRewardToMail(CUser *pUser, SMailData &mdata,int award,int num,int petLevel,int petStar);
private:
	map<int,StHuoDongMoneyGiftInfo> hd_gift_map;
	map< int,map<int,string> > hd_money_map;	// <ad,<money, payId>>
	typedef map<int,StHuoDongMoneyGiftInfo>::iterator HdGiftMapIter;
	typedef map<int,StMoneyGiftBagInfo>::iterator GiftMapIter;
	boost::recursive_mutex m_mutex;
};

struct StTransFormCardInfo
{
	StTransFormCardInfo()
	{
		item_id = 0;
		name = "";
		quality = 0;
		last_time = 0;
		target_type = 0;
		monster_id = 0;
		monster_name = "";
		memset(attr_type,0,sizeof(attr_type));
		memset(attr_value,0,sizeof(attr_value));
	}
	int item_id;
	string name;
	int quality;		//品质-1绿、2蓝、3紫、4橙
	int last_time;		//minutes
	int target_type;	//提升对象-1人物、2上阵神将、3人物和上阵神将
	int monster_id;
	string monster_name;
	int attr_type[8];
	int attr_value[8];
};
class CTransFormManager
{
	public:
	CTransFormManager();
	bool LoadDB();
	bool IsTransFormCardID( int item_id );
	bool GetTransFormCardInfoByID( int item_id ,StTransFormCardInfo &info);
	int GetRandomDropTransFormCardID();
	private:
	map<int,StTransFormCardInfo> transformMap;//key item_id
	typedef map<int,StTransFormCardInfo>::iterator TransformMapIter;
	vector<int> blue_quality_vec;	//所有蓝色品质的item_id
	vector<int> green_quality_vec;	//所有绿色品质的item_id
};
struct SChongZhi2OtherAward
{
	SChongZhi2OtherAward()
	{
		Clear();
	}
	void Clear()
	{
		RMB = 0;
		for(int i=0;i < AWARD_NUM;i++)
		{
			self_award[i] = 0;
			self_num[i] = 0;
			friend_award[i] = 0;
			friend_num[i] = 0;
		}
	}
	
	static const int AWARD_NUM = 4;
	int RMB;
	int self_award[AWARD_NUM];
	int self_num[AWARD_NUM];
	int friend_award[AWARD_NUM];
	int friend_num[AWARD_NUM];
};



struct SQunXianZhengBa_Buff
{
	void Clear()
	{
		index = 0;
		type1 = 0;
		value1 = 0;
		star1 = 0;
		type2 = 0;
		value2 = 0;
		star2 = 0;
		type3 = 0;
		value3 = 0;
		star3 = 0;
	}
	
	uint8 index;
	uint8 type1;
	int value1;
	int star1;
	uint8 type2;
	int value2;
	int star2;
	uint8 type3;
	int value3;
	int star3;
};

struct SQunXianZhengBa_Box
{
	void Clear()
	{
		index = 0;
		memset(freeItemId,0,sizeof(freeItemId));
		memset(freeNum,0,sizeof(freeNum));
		memset(YB,0,sizeof(YB));
		memset(YB_Item,0,sizeof(YB_Item));
		memset(YB_Num,0,sizeof(YB_Num));
		memset(quality,0,sizeof(quality));
		memset(ratio,0,sizeof(ratio));
	}
	
	uint8 index;
	int freeItemId[3];
	int freeNum[3];
	// 元宝开启奖励
	int YB[5];	// 需要元宝
	int YB_Item[20];
	int YB_Num[20];
	int quality[20];
	int ratio[20];	// 1~10000
};

struct SQunXianZhengBa_Role
{
	void Clear()
	{
		index = 0;
		s_minPercent = 0;
		s_maxPercent = 0;
		s_star = 0;
		m_minPercent = 0;
		m_maxPercent = 0;
		m_star = 0;
		h_minPercent = 0;
		h_maxPercent = 0;
		h_star = 0;
		gainRatio = 0.0;
		itemId = 0;
		itemNum = 0;
		YB = 0;
	}
	
	uint8 index;
	int s_minPercent;
	int s_maxPercent;
	int s_star;
	int m_minPercent;
	int m_maxPercent;
	int m_star;
	int h_minPercent;
	int h_maxPercent;
	int h_star;
	double gainRatio;	// 增益

	int itemId;
	int itemNum;
	int YB;	// 元宝价值
};

struct SQunXianZhengBaConig
{
	void Clear()
	{
		type = 0;
		t_index = 0;
	}
	
	uint8 type;	// 1玩家 2buff 3宝箱
	uint8 t_index;	// 类型对应index
};

struct SQunXianPowerPaiHang
{
	SQunXianPowerPaiHang()
	{
		Clear();
	}
	void Clear()
	{
		xiang = 0;
		sex = 0;
		vipLv = 0;
		zhandouli = 0;
		weapon = 0;
		roleId = 0;
		name.clear();
	}
	
	uint8 xiang;
	uint8 sex;
	uint8 vipLv;
	int zhandouli;
	int weapon;
	int roleId;
	string name;
};

struct SQunXianFloorPaiHang
{
	SQunXianFloorPaiHang()
	{
		Clear();
	}
	void Clear()
	{
		xiang = 0;
		roleId = 0;
		floor = 0;
		serverId = 0;
		name.clear();
	}

	uint8 xiang;
	int serverId;
	uint32 roleId;
	int floor;
	string name;
};

struct JiaoYiInfo {
	JiaoYiInfo()
	{
		id = 0;
		time = 0;
		seller_id = 0;
		seller_name = "";
		sell_yb = 0;
		buy_gold = 0;
		already_sell_yb = 0;
	}
	
	int id;
	uint32 time;
	uint32 seller_id;
	string seller_name;
	int sell_yb;
	int buy_gold;
	int already_sell_yb;
};

struct SQunXianSortRank
{
	bool operator()(const SQunXianFloorPaiHang &m1, const SQunXianFloorPaiHang &m2)
	{
		return m1.floor > m2.floor;
	}
};

class CQunXianZhengBaManager
{
public:
	const static int MAX_FLOOR = 60;
	const static int MAX_RESET_NUM = 1;
	const static int OPEN_ROLE_NUM = 10;
	const static uint8 SHOW_BUFF_NUM = 3;
	const static uint8 SHOW_ROLE_NUM = 3;
	const static uint16 SHOW_RANK_NUM = 30;
	CQunXianZhengBaManager();
	~CQunXianZhengBaManager();
	void Timer();
	bool LoadRankData();
	bool ReadData();
	bool InitPaiHang();
	void SavePaiHang();
	bool IsOpen();
	void SendPaiHangAward();

	void GetFloorConfig(uint8 floor,SQunXianZhengBaConig &data);
	void GetBuffCfgByIdx(uint8 index,SQunXianZhengBa_Buff &data);
	void GetBoxCfgByIdx(uint8 index,SQunXianZhengBa_Box &data);
	void GetRoleCfgByIdx(uint8 index,SQunXianZhengBa_Role &data);
	void GetMatchRole(uint8 floor,uint32 &s_role,uint32 &m_role,uint32 &h_role);
	void GetRoleDataById(uint32 roleId,SQunXianPowerPaiHang &info);
	void UpdateRoleFloor(CUser *pUser,int floor);
	void MakeRoleFloorHaiHang(CNetMessage &msg);

private:
	boost::recursive_mutex m_mutex;
	vector<SQunXianPowerPaiHang> m_rankList;
	map<uint32,uint32> m_roleIdMap;	// roleId,pos
	vector<SQunXianFloorPaiHang> m_floorRank;
	bool m_sortFlag;
};

class CJiaoYiHangManager
{
public:
	const static uint32 SELL = 1;
	const static uint32 CHANNEL_SELL = 2;
	const static uint32 OVER_TIME = 3;
	const static uint32 BUY = 4;

	const static uint32 BUY_RECORD = 0;
	const static uint32 SELL_RECORD = 1;

	inline static const double GOLD_RATIO = 0.5;		//寄卖元宝单价的浮动范围
	inline static const double BUY_GOLD_RATIO = 0.05;	//购买元宝的手续费
	const static int MIN_GOLD_YUZHI = 30000;	//最小金币阈值
	const static int MAX_SELL_COUNT = 10;		//最大寄卖数
	const static uint32 MAX_TIME = 24 * 3600;	//超时间隔

	CJiaoYiHangManager();
	~CJiaoYiHangManager();
	
	void JiaoYiBuyYB(CUser *pUser,int id,int yb,CNetMessage &msg);
	void ShowJiaoYiInfo(CNetMessage &msg,uint32 role_id = 0);
	void AddJiaoYiInfo(CUser *pUser,int sell_yb,int buy_gold,CNetMessage &msg);
	void ChannelJiaoYiInfo(CUser *pUser,int id,CNetMessage &msg);
	int GetJiaoYiGoldYuZhi();

	bool Init();
	void Timer();
private:
	bool InitJiaoYiInfo();
	bool InitJiaoYiGoldYuZhi();
	void OverTimeJiaoYiInfo();
	void CalJiaoYiGoldYuZhi();
	void AddJiaoYiRecord(JiaoYiInfo &info,uint32 buyer_id,string buyer_name,int buy_yb,int buy_gold,uint32 state,int poundage = 0);
	void InsertJiaoYiInfo(JiaoYiInfo &info);
	void NoLockInsertJiaoYiInfo(JiaoYiInfo &info);
	void AddJiaoYiSellCount(uint32 role_id);
	void NoLockAddJiaoYiSellCount(uint32 role_id);
	int GetJiaoYiSellCount(uint32 role_id);
	void NoLockDelJiaoYiSellCount(uint32 role_id);
	void UpdateJiaoYiInfo(int id,int already_sell_yb,bool end);
	

	boost::recursive_mutex m_mutex;

	int m_jiaoyiGoldYuZhi;						//推荐单价阈值
	uint32 m_jiaoyiGoldYuZhiTime;					//推荐单价阈值刷新时间
	
	list<JiaoYiInfo> m_jiaoyiInfo;			//交易记录信息
	map<uint32,int> m_jiaoyiSellCount;	//玩家寄卖的订单数
};


class CFunctionSwitchManager
{
public:
	const static uint32 JIAOYI_SHOP = 1; //交易行

	const static uint32 ACTIVITY = 1;

	CFunctionSwitchManager();
	~CFunctionSwitchManager();

	bool Init();
	void Timer();
	bool IsFunctionSwitchActivity(uint32 function_type);
private:

	boost::recursive_mutex m_mutex;
	map<uint32,uint32> m_function_switch;
};

#endif
