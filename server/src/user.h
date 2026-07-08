#ifndef _USER_H_
#define _USER_H_

#include "self_typedef.h"
#include "protocol.h"
#include "item.h"
#include "skill.h"
#include "monster.h"
//#include "scene_manager.h"
#include "npc_manager.h"
#include "mission_manager.h"
#include "unit_basic_attr.h"
#include "xun_bao_manage.h"
#include <string.h>
#include <string>
#include <boost/thread.hpp>
#include <boost/shared_ptr.hpp>
#include <bitset>
#include <map>
#include "award_manager.h"
#include "user_spirit.h"
#include "user_guanqia.h"
using namespace std;

const int SAVE_DATA_SPACE = 60*30;
const int CHAT_SPACE = 10;
const int ANSWER_QUESTION_TIME = 60;

const int WEEK_SECONDS = 7*24*3600; // 每周的秒数
const int DAY_SECONDS = 24*3600; // 每天的秒数

const uint8 MAX_HOT_NUM = 50;

// 客户端设置的自动、挂机功能 客户端标志位
const uint8 AUTO_USER_DOUBLE = 19;
const uint8 AUTO_PET_DOUBLE = 20;
const uint8 AUTO_FOLLOW_LEAD = 22;
const uint8 AUTO_PET_LOYALTY = 24;
const uint8 AUTO_GUAJI = 25;
const uint8 AUTO_USER_HP = 26;
const uint8 AUTO_USER_MP = 27;
const uint8 AUTO_PET_HP = 28;
const uint8 AUTO_PET_MP = 29;

const int AUTO_DEFAULT_HP_MP_SET = 50;
const uint16 AUTO_DEFAULT_FIGHT_NUM_SET = 450;

const uint32 UpdateMysteryTimeStep = 6*3600;	// 神秘商店刷新时间间隔
const uint32 UpdateYaoShiTimeStep = 2 * 3600;	// 神秘商店刷新时间间隔
const uint32 UpdateShenhunTimeStep = 4 * 3600;	// 神魂商店刷新时间间隔

const uint32 FIRE_STATE_TIME_LIMIT = 10;	// 角色帮派放火状态时间
const uint32 STEAL_STATE_TIME_LIMIT = 60;	// 角色菜地偷窃状态时间

const int HUOYUE_MAX_TASK = 10;
const int HUOYUE_TASK_DATA_ID[HUOYUE_MAX_TASK] = {410,411,412,413,414,415,416,417,418,419};
const int HUOYUE_TASK_FLUSH_YB = 30;

class CScene;
class SVisibleMonsterBossDrop;
class CFishRoom;

struct SVisibleMonster;
struct SNpcPos;
struct SShenQiConfig;
struct SZhenFaMemData;
struct SZhenFaData;
struct SRankPet;
struct SAttrTypeValue;
class UserBook;
class CChouKaManager;
class CUserBloodFight;
class UserShopManager;

typedef map<uint16, uint32> titleMap;
typedef map<uint16, uint32>::iterator titleMapIt;
typedef map<uint16, uint32>::const_iterator titleMapCIt;

typedef set<uint16> titleSet;
typedef set<uint16>::iterator titleSetIt;
typedef set<uint16>::const_iterator titleSetCIt;

enum
{
    ESITPet = 2,
};

enum
{
	EKFS_IN_LOCAL = 0,	// 在当前服(游戏服内)
	EKFS_IN_KUAFU = 1,	// 在跨服(游戏服内)
	EKFS_RETURN_GAME = 2,	// 返回游戏服(跨服)
	EKFS_ALREADY_IN_KUAFU = 3,	// 在跨服中(跨服)
};

enum ENearRoleState
{
	ENRS_FIGHT = 0x01,		// 战斗

	ENRS_CAN_KILL = 0x04,	// PK强杀
	ENRS_BANGPAI_STEAL = 0x08,	// 帮派偷窃
	ENRS_BANGPAI_FIRE = 0x10,	// 帮派魔火
	ENRS_FEI_XIAN = 0x20,		// 飞仙状态
	ENRS_COLLECT_TOWER = 0x40,		// 占塔
};

enum EEquipmentType
{
    EETMaoZi = 0,	// 帽子
    EETKuiJia = 1,	// 盔甲
    EETYaoDai = 2,	// 腰带
    EETXieZi = 3,	// 鞋子
    EETWuQi = 4,	// 武器
    EETXiangLian = 5,// 项链
    EETJieZhi = 6,	// 戒指
    EETHuWan = 7,	// 护腕
    EETShouZhuo2  = 8,// 护腕
};

enum EUserTitle
{
    EUTZhuangYuan   = 1,	//状元
    EUTBangYan      = 2,	// 榜眼
    EUTTanHua       = 3,	// 探花
    EUTShiFu        = 4,	// 师父
    EUT5            = 5,	// 文状元
    EUT6            = 6,	// 文榜眼
    EUT7            = 7,	// 文探花
    EUT8            = 8,	// 文举人
    EUT9            = 9,	//TID=9 英雄 TID=10 MM  TID=11 GG
    EUT10           = 10,
    EUT11           = 11,
    EUT12			= 12,	//英雄王冠
    EUT13			= 13,	//明日之星
    EUT14			= 14,	//蓝魅新月
    EUT15			= 15,	//妖泣滴血
};

enum EUserFindResType
{
	EFRT_ShiMen = 1,		// 师门任务
	EFRT_ZhuoYao = 2,		// 捉妖任务
	EFRT_Arena = 3,			// 竞技场
	EFRT_LingQiJuanXian = 4,	// 灵气捐献
	EFRT_KunLunXunBao = 5,	// 昆仑寻宝（闯关）
	EFRT_DailyBoss = 6,		// 日常boss
	EFRT_LiLianTa = 7,		// 历练塔
	EFRT_HuSong = 8,		// 护送神兽
	EFRT_ShaDiDuoBao = 9,	// 杀敌夺宝
	EFRT_WeiHuDanYuan = 10,	// 维护丹园
	EFRT_XunBao = 11,		// 寻宝任务(藏宝图)
	EFRT_ShiLian = 12,		// 英勇试炼
	EFRT_Copy_Pet_1 = 13,	// 蓬莱仙山(神将副本,低级)
	EFRT_Copy_Pet_2 = 14,	// 岱屿结界(神将副本,中级)
	EFRT_Copy_Book = 15,	// 诛仙绝地(神将副本,天书)
	EFRT_Copy_ShengJie = 16,	// 升阶副本
	EFRT_Copy_QiangHua = 17,	// 强化副本
	EFRT_Copy_JinBi = 18,		// 金币副本
	EFRT_Copy_CuiLian = 19,		// 淬炼副本
	EFRT_BangPaiMission = 20,	// 帮派任务
};

enum EMD2UserTitle	// 荣誉称号
{
	E2UT_JIUTIANZHIZUN = 1,		// 六界战神
	E2UT_WEIZHENSANJIE = 2,		// 众仙之首
	E2UT_MINGDONGBAFANG = 3,	// 富甲天下
	E2UT_BUMIESHENGHUANG = 4,	// 万兽主宰
	E2UT_XIANWANGJIANGHSI = 5,	// 天下第一
	E2UT_TIANJUNJIANGSHI = 6,	// 天下第二
	E2UT_WANGZHEJIANGSHI = 7,	// 天下第三
	E2UT_ZHANWUBUSHENG = 8,		// 竞技仙尊-------
	E2UT_ZHENYAOYINGHAO = 9,	// 通天王者
	E2UT_ZHENYAODIHAO = 10,		// 通天尊者
	E2UT_TIANXIADIYIBANG = 11,	// 天下第一帮
	E2UT_WOSHIGAOFUSHUAI = 12,	// 珠光宝气
	E2UT_JUESHISHENCHONG = 13,	// 绝世神将-------
	E2UT_WANSHOUZHIWANG = 14,	// 驭兽之王
	E2UT_QIYUXIUXING = 15,		// 聆音小仙-------
	E2UT_XIUXINGDAREN = 16,		// 知微灵仙-------
	E2UT_LIANJIKUANGREN = 17,	// 飞升上仙-------
	E2UT_ZHUGUANGBAOQI = 18,	// 尊贵VIP -------
	E2UT_TIANXIAWUSHUANG = 19,	// 竞技仙圣-------
	E2UT_SHIDAGAOSHOU = 20,		// 十大高手
	E2UT_QIPINXIANCHONG = 21,	// 极品仙神将-------
	E2UT_LIUGUANYICAI = 22,		// 流光溢彩-------
	E2UT_XIANGYAOZUNZHE = 23,	// 通天圣者-------
	E2UT_DENGFENGZAOJI = 24,	// 竞技新秀-------
	E2UT_ZHENYAOSHIZHE = 25,	// 通天使者-------
	E2UT_XIAOSHINIUDAO = 26,	// 师门修勤-------
	E2UT_TAPOCANGQIONG = 27,	// 擂台斗神
	E2UT_YUNEIWUDI = 28,		// 擂台斗师
	E2UT_BINITIANXIA = 29,		// 擂台斗者
	E2UT_GUOFENGDIYIMENG = 30,	//国风第一猛
	E2UT_TIANLINGSHENCHONG = 31,//天灵神将
	E2UT_DIBAOXIANCHONG = 32,	//地宝仙神将
	E2UT_ZHISHIYUNQIHAO = 33,	//只是运气好
	E2UT_JIANGXINDUYUN = 34,	//匠心独运
	E2UT_LUHUOCHUNQING = 35,	//炉火纯青
	E2UT_FEIYIBANGANJUE = 36,	//飞一般感觉
	E2UT_AOSHIQUNXIONG = 37,	//傲视群雄
	E2UT_DENGLINGJUEDING = 38,	//登凌绝顶
	E2UT_GEBUSHICHUANSHUO = 39,	//哥不是传说
	E2UT_WEIWODUXIAN = 40,		//唯我独仙(天元争霸)
	E2UT_WEIZHENLIUJIE = 41,	//威震六界
	E2UT_QIONGDEZHISHENQIAN = 42,	//穷得只剩钱
	E2UT_FUKEDIGUO = 43,		//富可敌国
	E2UT_YAOCANWANGUAN = 44,	//腰缠万贯
	E2UT_YUSHANGJIUTIAN = 45,	//欲上九重天
	E2UT_FENGYITIANXIANG = 46,	//凤翼天翔
	E2UT_ZHIYOUZHIYI = 47,		//自由之翼
	E2UT_TTSCD = 48,	//天天食茶蛋
	E2UT_RRPQG = 49,	//日日品切糕
	E2UT_BBSL = 50,		//步步生莲
	E2UT_HQZGJ = 51,	//欢庆中国节
	E2UT_LJDYR = 52,	//六界第一人
	E2UT_YARS = 53,		//有爱人生
	E2UT_YRXHW = 54,	//有人喜欢我
	E2UT_WSZS = 55,		//无双战神
	E2UT_YJTX = 56,		//勇绝天下
	E2UT_YGSJ = 57,		//勇敢三军
	E2UT_JDFH = 58,		//绝代风华
	E2UT_CMSQ = 59,		//才貌双全
	E2UT_WWEY = 60,		//温文尔雅
	E2UT_YRGY = 61,		//颜如冠玉
	E2UT_QYXA = 62,		//器宇轩昂
	E2UT_YBTT = 63,		//仪表堂堂
	E2UT_TongTianWangZhe = 64,	//通天王者, 历练塔排行第一名
	E2UT_TongTianZunZhe = 65,	//通天尊者
	E2UT_TongTianShiZhe = 66,	//通天使者
	E2UT_LiLianWangZhe = 67,	//历练王者, 修仙历练排行第一名
	E2UT_LiLianZunZhe = 68,		//历练尊者
	E2UT_LiLianShiZhe = 69,		//历练使者

	E2UT_70 = 70,	// 招宝天尊	充值活动
	E2UT_71 = 71,	// 纳珍天尊	充值活动
	E2UT_72 = 72,	// 招财使者	充值活动
	E2UT_73 = 73,	// 利市仙官	充值活动
	E2UT_74 = 74,	// 增长天王	充值活动
	E2UT_75 = 75,	// 广目天王	充值活动
	E2UT_76 = 76,	// 多闻天王	充值活动
	E2UT_77 = 77,	// 持国天王	充值活动
	E2UT_88 = 88,	// 逍遥仙尊	充值活动
	
	E2UT_NUM,
	E2UT_MAX = E2UT_NUM,		// 极值
};

enum ESceneRoleUpdateType
{
	ESRT_State = 1,		// state
	ESRT_Name = 2,		// name
	ESRT_BangPai = 3,	// bangpai
	

	ESRT_JingJie = 6,	// 境界信息

	ESRT_Title = 8,		// 称号
	ESRT_ShenQi = 9,	// 神器
	ESRT_Vip = 10,		// vip
	ESRT_Pet_Follow = 11,	// 神将跟随
	ESRT_Mount_State = 12,	// 坐骑骑乘
	ESRT_Fish_State = 13,	// 钓鱼状态
	ESRT_Wing = 14,		// 翅膀
	ESRT_HuSong = 15,	// 护送
	ESRT_TransormShape = 16,	// 外形变身
	ESRT_Foot = 17,	// 脚印
	
	ESRT_LIMIT,	// 
	ESRT_MAX = ESRT_LIMIT-1,	// 最大值
};

enum EExpItemType
{
	EET_NoTimes = 0,
	EET_TwoTimes = 1,
	EET_FiveTimes = 2,
	EET_TenTimes = 3,
	EET_TenTimesFestival = 4,
};

enum UserPrivilegeType
{
	UPT_White_Gold = 0,	// 白金特权
	UPT_Diamond = 1,	// 永久月卡
	UPT_King = 2,		// 王者特权
	UPT_TiYan = 3,		// 体验特权
	UPT_MAX = UPT_TiYan,
};

// 切图读条类型
enum ETransportLoadingType
{
	ETLT_None = 0, // 默认
	ETLT_MoBaoFB = 1, // 进入退出魔豹副本
};

struct HotInfo
{
    uint32 hotId;
    uint32 hotVal;
};

struct QuestionInfo
{
	string ques;
	string ans[4];
};

struct SResource
{
	SResource()
	{
		Clear();
	}
	void Clear()
	{
		level = 0;
		initTime = 0;
		findList.clear();
	}

	uint16 level;	// 昨天角色等级
	uint32 initTime;	// 最后统计时间
	map<int, uint16> findList;	// [funcId]--times
};

const int MAX_OptionNum=10;
struct CMultiTreeDoptionNode
{
	CMultiTreeDoptionNode()
	{
		have_op = 0;
		callback = 0;
		parent = NULL;
		for(uint8 i=0;i<MAX_OptionNum;i++)
			child[i] = NULL;
	}
	int id;
	int parentid;
	string title;
	string label;
	string content;
	uint8 have_op;			// 0不带选项,1带选项
	uint8 callback;			// 0不回调,1回调
	CMultiTreeDoptionNode *parent;
	CMultiTreeDoptionNode *child[MAX_OptionNum];
};

struct CDoptionCallBack
{
	int id;
	string script_call;
};

struct HdShowHistoryNode
{
	HdShowHistoryNode()
	{
		time = 0;
		data = "";
	}
	
	uint32 time;
	string data;
};

struct SXiuXianData
{
	SXiuXianData()
	{
		fightNum = 0;
		winFlag = 0;
	}

	uint8 winFlag;		// 1 已经战胜过，0 还未战胜
	uint8 fightNum;	// 战斗次数
};

struct SFootPrintData
{
	SFootPrintData()
	{
		Clear();
	}
	void Clear()
	{
		id = 0;
		get_time = 0;
		end_time = 0;
		rank = 0;
	}

	int id;
	int get_time;
	int end_time;
	int rank;
};

struct SSortFootPrintData
{
	bool operator()(SFootPrintData const &b1,SFootPrintData const &b2)
	{
		return b1.rank < b2.rank;
	}
};

bool CanAddShuXing(SItemTemplate *pItem,SItemInstance *pInst);

struct HuoYueTaskInfo
{
	HuoYueTaskInfo()
	{
		taskName = "";
		taskInfo = "";
		taskCount = 0;
		level = 0;
		document = "";
		taskNeedCount = 0;
		pic = 0;
	}
	
	string taskName;
	string taskInfo;
	uint32 taskCount;
	uint8 level;
	string document;
	uint32 taskNeedCount;
	uint32 pic;
};

struct PetPosJewelInfo
{
	PetPosJewelInfo()
	{
		kind = 0;
		level = 0;
	}
	uint8 kind;
	uint8 level;
};
//站位宝石
struct PetJewelPos
{
	PetPosJewelInfo jewel[5];
};
const int MAX_PET_POS_JEWEL_LEVEL = 9; //宝石最高等级
const int PET_POS_JEWEL_COMPOSE_NEED_NUM = 3;	//合成系数


const int XIANYUAN_OPEN_LEVEL = 50;
const uint8 XIANYUAN_OPEN_CHAPTER = 9;

const int XY_MARKET_ONCE_COST_YB = 100;
const int XY_MARKET_TEN_COST_YB = 950;
const int XY_MARKET_ONCE_COST_XY = 100;
const int XY_MARKET_TEN_COST_XY = 950;

class CXianYuan
{
	public:
	CXianYuan();
	uint32  xy_value;
	std::map<uint32,uint32> cardMap;	//卡片信息表
	std::vector<uint32> chapterVec;	//章节信息表
};

//角色身上记录的敌人信息
struct StKuaFu1vs1SaveEnemyInfo
{
	StKuaFu1vs1SaveEnemyInfo()
	{    
		kind = 0; 
		role_id = 0;
		name = " ";
		level = 0;
		xiang = 0;
		sex = 0; 
		super_level = 0;
		wing_id = 0;
		weapon_id = 0; 
		weapon_level = 0;
		zhandouli = 0;
		score = 0;
		server_id = 0;
	}
	int kind;       //ememy类型 0 角色 1机器人
	int role_id;        //角色ID
	string name;        //名字
	int level;          //等级
	int xiang;          //职业
	int sex;            //性别
	int super_level;    //至尊等级
	int wing_id;        //翅膀ID
	int weapon_id;      //武器ID
	int weapon_level;   //武器level
	int zhandouli;      //战斗力
	int score;			//积分
	int server_id;      //服务器id
};

class CNewShenQi
{
	public:
	CNewShenQi();
	int carry_id;	//携带的神器ID
	int sq_level;		//培养等级
	int sq_star;		//培养星数
	int sq_exp;		//培养经验
	std::vector<int> activedVec; //已经激活的神器

};
const int NEW_SHENQI_OPEN_LEVEL = 10;


struct StMoneyGiftBagHuoDongInfo
{
	public:
	StMoneyGiftBagHuoDongInfo()
	{
		init();
	}
	void init()
	{
		huodong_charge = 0;
		huodong_start_time = 0;
		gift_huodong_map.clear();
	}
	int huodong_charge;	//活动期间充值数目
	int huodong_start_time;//记录的当次活动开始时间
	map<int ,int> gift_huodong_map; //key gift_id ,value 活动礼包购买数目
};

class CUser
{
public:
    CUser();
    ~CUser();
    void SetSock(int);
    int GetSock();
    void SetRoleId(uint32 id);
    void SetPos(uint16 x,uint16 y);
    uint32 GetUserId();
    uint32 GetRoleId();
    void SetUserId(uint32);
	bool Move(uint16 x,uint16 y);//DIR=2 向上 DIR=4 向左 DIR=6 向右 DIR=8 向下
    void SetFace(uint8 face);
	void SetOrigPos(uint16 pos_x,uint16 pos_y);
	void GetOrigPos(uint16 &pos_x,uint16 &pos_y);
    uint8 GetFace();
    void GetPos(uint16 &x,uint16 &y);
    void GetFacePos(uint8 &x,uint8 &y);
    void EnterScene(CScene*);
    void EnterFuBen(uint16 sceneId);
	uint16 GetMoveSpeed();
	void EnterFuBen_IfExit(uint16 &sceneId);
	void ExitFubenToDefaultPos(uint16 &sceneId);
	void ExitBangZhanScene(uint16 &sceneId);
	void EnterLastScene(uint16& sceneId);
	void NoLockBackLastScene();

    CScene *GetScene();

    int GetSceneId();
    uint16 GetMapId();
	uint16 GetSrcSceneId();
	uint8 GetCanDoRingBossNum();
	uint16 GetArenaFightMaxNum();

    void SetRole(uint32 *roles);
    void AddRole(uint32 roleId)
    {
        for(uint8 i = 0; i < MAX_ROLE_NUM;i++)
        {
            if(m_role[i] == 0)
            {
                m_role[i] = roleId;
                return;
            }
        }
    }
		bool HaveRole()
		{
	        for(uint8 i = 0; i < MAX_ROLE_NUM;i++)
	        {
	            if(m_role[i] >0)
	            {
	                return true;
	            }
	        }
			return false;
		}
    bool HaveRole(uint32 roleId)
    {
        for (int i = 0; i < MAX_ROLE_NUM; i++)
        {
            if(m_role[i] == roleId)
                return true;
        }
        return false;
    }
    int GetRoleNum()
    {
        int num = 0;
        for (int i = 0; i < MAX_ROLE_NUM; i++)
        {
            if(m_role[i] != 0)
                num++;
        }
        return num;
    }

    bool Init(bool updateSimpleData=false);
	void ResetPower(bool updateSimpleData=true);

	void NoLockInitAndUpdate();
	void InitAndUpdate();

	void UpdateSGState();

	void InitZhaDanHistory();
	int GetAllZhenFaPower();
	void SetZhaDanHistory(vector<string> &history);
	void GetZhaDanHistory(vector<string> &history);
	void ClearZhaDanHistory() { m_zhaDanHistory.clear(); }

	//add by zhudaolong 2017.11.02  桃花羹制作历史
	void InitTHGHistory();
	void AddTHGHistory(uint32 item, uint32 item_num);
	void GetTHGHistory(vector<HdShowHistoryNode> &history);
	
	void InitHDShowHIstory(uint32 hd_type);
	void GetHDShowHIstory(uint8 type, vector<HdShowHistoryNode> &history,uint32 hd_type);
	void SetHDShowHIstory(uint8 type, vector<string> &history,uint32 hd_type);

	void InitJiaoYiHangRecord();
	void AddJiaoYiHangRecord(HdShowHistoryNode record,uint32 state);
	void MakeJiaoYiHangRecord(CNetMessage &msg);

	bool CanWorldTransPort(int trans_sceneId);
    uint32 GetFightId();

    const char *GetName();
    uint8 GetSex();
    uint16 GetX();
    uint16 GetY();
    uint16 GetLevel();
    int64 GetExp();
	const char *GetExpStr();

    uint32 GetStep();

	uint8 GetHead();
	void SetHead(uint8 head);

	uint8 GetModel();
	void SetModel(uint8 model);

    void SetName(const char *name);
    void SetSex(uint8 sex);
    void SetLevel(uint16 level);
    void SetExp(int64 exp);
    void SetFight(uint32 fightId);
	void SetFightEndTime();
	void SetClientFightEndTime();

	uint8 GetVipLevel();
	void SetVipLevel(int lv){m_vipLevel=(uint8)lv;}
    void UpdateVipInfo();
	void GiveVipAward(uint8 newLv);
	void GiveVipNewAward();
	void UpdateVipInfoEx();

	bool AddBaiHuaChip(uint8 type,int num=1,uint8 fightend=0);

	uint8 GetShopDiscountBuyNum(uint8 idx);
	void AddShopDiscountBuyNum(uint8 idx);
	void ClearShopDiscountBuyNum();
	uint16 GetShopDiscountTotolNum();

	void SendMysterItemsInfo();
	void ShowMysteryItems(const vector<UserMysteryItem> &itemList);
	void CreateMysteryItem(const vector<UserMysteryItem> &itemList);
	bool FindMysteryItem(int id);
	void BuyMysteryItems(uint16 buyId,uint8 showIndex);
	void SetMysteryBitSet(uint16 idx);
	bool CanBuyMysteryItem(uint16 idx);
	void ClearAllMysteryBitSet();

	// 神魂商店
	void SendShenhunItemsInfo();
	void ShowShenhunItems(const vector<UserMysteryItem> &itemList);
	void CreateShenhunItem(const vector<UserMysteryItem> &itemList);
	bool FindShenhunItem(int id);
	void BuyShenhunItems(uint16 buyId, uint8 showIndex);
	void SetShenhunBitSet(uint16 idx);
	bool CanBuyShenhunItem(uint16 idx);
	void ClearAllShenhunBitSet();

	void ShowFootPrintItems(const vector<SFootPrintShopData> &itemList);
	void BuyFootPrint(const vector<SFootPrintShopData> &itemList,int id,CNetMessage &msg);
	void EquipFootPrint(int id,CNetMessage &msg);
	void UnEquipFootPrint(int id,CNetMessage &msg);
	int GetUseFootPrintID(){return NoLockGetExtData32(421);}
	void SetUseFootPrintID(int id);

	void SendYaoShiItemsInfo(vector<HDPeiZhiInfo> &peizhiInfo);
	void ShowYaoShiItems(const vector<UserYaoShiItem> &itemList,vector<HDPeiZhiInfo> &peizhiInfo);
	void CreateYaoShiItem(const vector<UserYaoShiItem> &itemList);
	bool FindYaoShiItem(uint32 id);
	void BuyYaoShiItems(uint32 buyId,uint32 showIndex,uint32 buyNum);
	void SetYaoShiBitSet(uint32 idx);
	bool CanBuyYaoShiItem(uint32 idx);
	uint32 GetYaoShi();
	uint32 NoLockGetYaoShi();
	uint32 GetCostYaoShi();
	uint32 NoLockGetCostYaoShi();
	void SetYaoShi(uint32 yaoshi);
	void NoLockSetYaoShi(uint32 yaoshi);
	void SetCostYaoShi(uint32 costYaoshi);
	void NoLockSetCostYaoShi(uint32 costYaoshi);

	void BuyExchangeItem(CNetMessage &msg);

    void SetPackage(char *pPack);
    void SetBankItem(char *pBankItem);
    void GetBankItem(string &str);
    void MakeBankItemList(CNetMessage &msg);
    bool MoveItemToBank(uint8 packPos,uint8 num);
    bool MoveItemToPack(uint8 bankPos,uint8 num);

    void SetCall(int script,const char *call);
    void SetCallScript(int script);
    void SetCallFun(const char *call);

	void MakeOtherChuZhanPet(CNetMessage &msg);
	void MakeOtherMount(CNetMessage &msg);
	void MakeOtherWing(CNetMessage &msg);
	
	void MakeOtherTitle(CNetMessage &msg);

    void MakePack(CNetMessage &msg);
	void MakePackageItemByPos(uint16 pos,CNetMessage &msg);

	void SendMailByLevel();
    void AddLevel(uint8 tili = 0);         //等级
	int AddExp(int64 exp, bool isSend = false, bool fightEnd = false, int shuangbei = 0);            //经验
	int AddPetExp(int64 exp);            //经验
	void UptoLevel(int level); // 直升等级到多少级，不会降级

    void AddHp(int hp,int maxHp=0);              //气血
    void AddStep(int step);
    void SetMoveTime(uint64 t);
    uint64 GetMoveTime();
    void SetErrMoveTimes(uint8 t);
	uint8 GetMoveErrTimes();

	void GetBasicAttr(SUnitBasicAttr &basicAttr);
	uint8 GetAttackType();
	int GetAttack();	// 伤害
	int GetWuFang();	// 物防
	int GetFaFang();	// 法防
	int GetMaxHp();
    int GetSpeed();		//速度
	int GetMingZhong();
	int GetShanBi();
	int GetBaoJi();
	int GetBaoJiKang();
	int GetMingZhongLv();
	int GetShanBiLv();
	int GetBaoJiLv();
	int GetBaoJiKangLv();
	int GetZengShangLv();
	int GetWuMianLv();
	int GetFaMianLv();
	int GetBaoJiAdd();
	int GetFanJiLv();
	int GetFanJiKangLv();
	int GetFanJiAdd();
	int GetLianJiLv();
	int GetLianJiKangLv();
	int GetLianJiAdd();
	int GetFanZhenLv();
	int GetFanZhenKangLv();
	int GetFanZhenAdd();
	int GetFuMianAdd();
	int GetFuMianKangAdd();
	
	void AddDamage(int damage);
    void AddSkillDamage(int skillDamage);
    void AddRecovery(int recovery);
    void AddSpeed(int speed);

    bool AddPackage(SItemInstance &item,const char *name = NULL,const char *mailMsg=NULL);
    bool AddPackage(int itemId,uint16 num = 1, const char *name = NULL,const char *mailMsg=NULL);
    bool DelPackage(uint8 pos,uint16 num = 1);

    int GetMoney()
    {
        return m_money;
    }
    void SetMoney(uint32 money)
    {
        m_money = money;
        SendUpdateInfo(EUUT_Money);
    }
	
	bool CanMeetEnemy();

    bool MakePackInfo(uint8 pos,CNetMessage &msg);
    void MakePlayerInfo(CNetMessage &msg,CUser *pUser);

	void SaveEnterPos(int sceneId, int posX, int posY); // 进入副本前位置信息 设置
	void GetEnterPos(int& sceneId, int& posX, int& posY); // 进入副本前位置信息 获取
	void SetCurPos(int sceneId, int posX, int posY); // 设置当前玩家为之

	int GetTeamMemberNum(); // 获取队伍人数

    uint32 GetTeam()
    {
        return m_teamId;
    }
	bool HaveTeam()
	{
		if(GetTeam() > 0 || TempLeaveTeam() > 0)
			return true;
		else
			return false;
	}
	bool IsTeamLeader()
	{
		if(m_teamId > 0 && m_teamId == m_roleId)
			return true;
		return false;
	}
	bool FindAskForJoinTeam(uint32 teamId)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<AskForJoinTeamData>::iterator it=m_askForJoinTeam.begin();it != m_askForJoinTeam.end();it++)
		{
			if(it->teamId == teamId)
				return true;
		}
		return false;
	}
	void AddAskForJoinTeam(uint32 teamId)
	{
		if(teamId < 0)
			return;
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		bool find = false;
		for(list<AskForJoinTeamData>::iterator it=m_askForJoinTeam.begin();it != m_askForJoinTeam.end();it++)
		{
			if(it->teamId == teamId)
			{
				it->joinTime = (uint32)GetSysTime();
				find = true;
				break;
			}
		}
		if(!find)
		{
			AskForJoinTeamData temp;
			temp.teamId = teamId;
			temp.joinTime = (uint32)GetSysTime();
			m_askForJoinTeam.push_front(temp);
		}
	}
	void ClearAskForJoinTeam();
	void DelAskForJoinTeam(uint32 teamId)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		for(list<AskForJoinTeamData>::iterator it=m_askForJoinTeam.begin();it != m_askForJoinTeam.end();it++)
		{
			if(it->teamId == teamId)
			{
				m_askForJoinTeam.erase(it);
				return;
			}
		}
	}
	
    void SetTeam(uint32 id)
    {
        m_teamId = id;
		ClearAskForJoinTeam();
    }

    void AddAskForMatchUser(uint32 id)//邀请者id
    {
        boost::recursive_mutex::scoped_lock lk(m_mutex);
        m_askForMatchUser.push_back(id);
    }

    void ClearAskForMatchUser()
    {
        boost::recursive_mutex::scoped_lock lk(m_mutex);
        m_askForMatchUser.clear();
    }

    void DelAskForMatchUser(uint32 id)
    {
        boost::recursive_mutex::scoped_lock lk(m_mutex);
        m_askForMatchUser.remove(id);
    }

    bool InAskForMatchUser(uint32 id)
    {
        boost::recursive_mutex::scoped_lock lk(m_mutex);
        list<uint32>::iterator i = m_askForMatchUser.begin();
        for(; i != m_askForMatchUser.end(); i++)
        {
            if(*i == id)
                return true;
        }
        return false;
    }


    bool AddPet(SharePetPtr &pPet,uint16 *toItemId=NULL,uint16 *toItemNum=NULL);
    void SetPet(char *pPet,bool useDefName=false);
	void InitTeamBreakAttr();
	
	void GetZhenFa(string &str);
	void SetZhenFa(char *pStr);
	void CheckZhenFa();
	uint16 GetUseZhenFaId();
	uint16 GetUseZhenFaLevel();
	uint16 GetZhenFaLevel(uint16 zhenfaId=0);
	bool HaveZhenFa(uint16 zhenfaId);

	void SetWing(char *pWing);
	void GetWing(string &str);
	void MakeWing(CNetMessage &msg);	// 翅膀信息
	void StrengthenWing(uint8 type,uint16 itemId,uint16 num,CNetMessage& msg);
	void BuyWing(uint8 buyId,int useYB,CNetMessage &msg);
	void BuyWingByItem(uint8 buyId,int itemId,int itemNum,CNetMessage &msg);
	
	void AddMount(uint8 mountId = 1); // 增加基础坐骑
	void SetMount(char *pMount); // 数据库读写
	void MakeMount(CNetMessage& msg); // 坐骑信息 发消息用
	void MakeMountStrengthenMsg(CNetMessage& msg);//坐骑强化信息 发消息用
	bool StrengthenMount(CNetMessage& msg,int materialID ,int num); // 坐骑强化 发消息用
	bool UpgradeMount(CNetMessage& msg); // 坐骑进阶 发消息用
	void UseMount(int mountId);
	void SetMountState(CNetMessage& msg,int index); // 设置乘骑状态 发消息用
	void BuyMount(uint8 buyId,uint32 time,int useYB,CNetMessage &msg);
	void BuyMountByItem(uint8 buyId,int itemId,int itemNum,uint32 time,CNetMessage &msg);
	void MakeMountCollect(CNetMessage &msg);

	void AddWing(int id);
	uint8 GetWingId();
	uint8 GetWingIdxById(int wingId);
	void UseWing(int wingId);
	void SetWingState(CNetMessage& msg,int index);
	void QueryWingQiangHuaMsg(CNetMessage &msg);
	void SendWingMsg();
	void SendNewWingMsg(uint8 wid);
	int GetWingZhanDouLi(bool show=false);
	
	int GetMountMoveSpeed() { return m_mount.GetMoveSpeed(); } // 坐骑 速度 比率
//	int GetMountAddQiXue() { return m_mount.GetBasicAddQiXue(GetExtData8(144)) + m_mount.GetAddQiXue(); } // 坐骑 气血 值
//	int GetMountAddShangHai() { return m_mount.GetBasicAddShangHai(GetExtData8(144)) + m_mount.GetAddShangHai(); } // 坐骑 伤害 值
//	int GetMountAddFangYu() { return m_mount.GetBasicAddFangYu(GetExtData8(144)) + m_mount.GetAddFangYu(); } // 坐骑 防御 值
	uint8 GetMountId();
	int GetMountIndex();
	uint8 GetMountIdByIdx(int idx);
	uint8 GetMountIdxById(int mountId);
	void AddHuoDongMount(); // 开服活动 坐骑
	bool IsAddHuoDongMountEnable() // 开服活动 是否可以升阶坐骑
	{
		return (m_mount.m_num > 0);
	}

    void MakePet(CNetMessage &msg);

	void InitChuZhanPet();

	bool SetGenSuiPet(uint16 petId);

	void SetPetHide(uint16 petId); // 召回（取消观看）
    bool UseItemToPet(uint16 petId,uint8 itemPos,int *pAddHp = NULL,int *pAddMp = NULL,int val = 0);
	bool PetCanLearnSkillBook(SPet *pPet,int skillId,uint8 skillPos);
	uint8 GetPetMaxSkillNumByQuality(uint8 petQuality);

	void UseItem(uint8 pos, int *pAddHp = NULL, int *pAddMp = NULL, uint8 val = 0, uint8 val1 = 0, uint8 num = 1);
	void UseItem(uint8 pos, uint8 num, uint8 tar);
	bool ResetPet(uint8 petPos); // 洗神将功能

	uint8 GetFightMaxSpeedLevel();

	bool PetXiuLianLevelUp(uint16 petId,uint8 xiulianIdx,CNetMessage &msg);
	bool PetForgetSkill(uint16 petId,uint8 skillPos,CNetMessage &msg);
	bool MakeZhenFaMsg(CNetMessage &msg);
	bool ZhenFaLevelUp(uint16 zhenfaId,CNetMessage &msg);
	bool SwitchZhenFa(uint16 zhenfaId,CNetMessage &msg);
	void GetUseZhenFa(SZhenFaData &data);
	void GetZhenFaMember(vector<SZhenFaMemData> &zhenfaMembers);
	bool ZhenFa_SetPetState(uint16 petId,uint8 pos,bool synPower=true);
	bool ZhenFa_ChangeUnitPos(uint8 srcPos,uint8 tarPos,bool synTeam=true);
	void TrapShangZhenMsg();
	void PetXueMai(uint16 petId,uint8 xueMaiIdx,CNetMessage &msg);

	bool PetLevelUp(uint16 petId,uint16 costItemId,uint8 costItemNum,CNetMessage &msg);
	bool AllPetLevelUpToMax();
	void InitAllPet();
	void RecoveryAllPetHp();
	int GetPetNextLevelZhanDouLi(uint16 petId);		// 下一等级战斗力

	void SaveEnter2FuBen(int fuBenIdx); // 记录进入部分信息
	void SaveEnter2FuBen(CUser *pUser, int fuBenIdx); // 记录进入部分信息
	void ExitFuBen(int loadingType = 0); // 退出副本

	// 日常副本
	void RiChangFuBenSaveEnter(int fuBenId); // 记录进入信息

    void DelPet(uint16 petId,bool sendMsg=true);	// 默认发送神将删除协议
	bool DelPetWithNoLock(uint16 petId);
    void MakeUpdateInfo(CNetMessage &msg,CUser *pUser,uint8 uType);

	uint8 GetYaoLingLevel(){ return GetExtData8(384); }
	void SetYaoLingLevel(uint8 lv){ SetExtData8(384,lv); }

	// 炼体
	int GetLianTiShuXing(EAttrType type); // 获取加成属性
	int GetLianTiLevel(EAttrType type); // 获取等级
	int GetLianTiJingYan(EAttrType type); // 获取经验
	int GetLianTiQuanLevel(); // 获取全属性等级
	int GetLianTiQuanJingYan(); // 获取全属性经验
	int GetLianTiNeedExp(int level); // 获取升级所需经验
	int GetLianTiQuanNeedExp(int level); // 获取全属性升级所需经验
	void AddLianTiJingYan(EAttrType type, int exp); // 增加炼体经验
	void AddLianTiLevel(EAttrType type); // 增加炼体等级
	void AddLianTiQuanLevel(); // 增加全属性炼体等级
	void MakeLianTiInfo(CNetMessage &msg); // 获取炼体信息
	void UpgredeLianTi(CNetMessage &msg, EAttrType type, int itemPos); // 升级炼体

	// 多人闯关
	int GetChuangGuanKey()
	{
		return GetExtData8(22); // 获取
	}
	void SetChuangGuanKey(uint8 key)
	{
		SetExtData8(22,key); // 设置
	}
	void ResetChuangGuanNotify(); // 重置闯关通知
	void CheckDengLuLiBao(); // 登陆礼包处理

	// 英勇试炼
	void SendShiLianGetAwardPanel();
	bool GetShiLianAwardByIdx(int idx,CNetMessage &msg);
	bool ExitChooseShiLianAward(CNetMessage &msg);

	// 阶段目标
	void GetStageGoalAttr(int& addDamage, int& addRecovery, int& addHp); // 获取阶段目标属性奖励
	void FinishStageGoalSection(int stage,int section); // 完成阶段目标 小节
	void FinishStageGoalStage(int stage); // 完成阶段目标 段落
	bool VerifyPetLevelAndNum(uint32 num, uint32 level, uint32& rawnum); // 验证是否有num个神将等级>=level 的神将
	bool VerifyPetSkillLevelAndNum(uint32 num, uint32 level, uint32& rawnum); //验证是否有num个神将的技能等级>=level 
	bool VerifyPetStarLevelAndNum(uint32 num, uint32 level,uint32& rawnum); //验证是否有num个神将的技能等级>=level
	bool VerifyPetXueMaiLevelAndNum(uint32 num, uint32 level,uint32& rawnum); //验证是否有num个神将的技能等级>=level
	bool VerifyUserPetQualityAndNum(uint32 num, uint32 quality, uint32& verifyNum); // num个quality品质的神将
	bool VerifyUserLevelFormationNum(uint32 num, uint32 level, uint32& verifyNum); // num个level级阵法
	bool VerifyUserPetPowerNum(uint32 num, uint32 power, uint32& verifyNum); // num个power战力神将
	bool VerifyUserPetEquipStrongLevelNum(uint32 nums, uint32 level, uint32& verifyNum); // 神将装备x件强化超过y级
	
	bool HaveTitle(uint16 title);
	void SetViewTitle(uint16 title,uint8 show,CNetMessage *msg);
	bool SetUseTitle(uint16 title,uint8 use,CNetMessage *msg);
	bool InsertTitle(uint16 title, titleSet *pRemoveTitle, bool *haveNewAdd, uint32 endTime = 0);
	void RemoveNotForeveryTitle(titleSet *removeTitle);
    void AddTitle(uint16 title, uint32 time = 0);
	void DelTitle(uint16 title);
	void AddSpecialTitle();
	bool CheckAddTitle(uint16 title);
	bool IsUseTitle(uint16 id);
	void GetTitleMsg(CNetMessage &msg);
	void GetUseTitleMsg(CNetMessage &msg);
	bool IsAddHpItem(uint16 itemid);
	uint16 GetHpItem();
    void ReadTitle(const char *pStr);
    void GetTitleStr(string &str);

	bool CheckInvalidTitle(titleSet *removeTitle=NULL); // 检测称号有效性

	void GetPetQualityNum(int& quality3,int& quality4); // 获取神将品质的数量
	int GetPetQualityNum(int quality); // 获取玩家目标品质的神将数量

	int GetPetNumByLimitQuality(int quality);
	string GetPetMaxFightName(); // 获取玩家战斗力最强的神将的名字
	void GetPetMaxFightId(SRankPet &info);//获取玩家战斗力最强的神将信息（id,战斗力）
	void GetPetsPower(vector<SRankPet> &vecData);//获取玩家的神将战斗力

    void SetQianNeng(int qianNeng)
    {
        m_qianneng = qianNeng;
    }
    int GetQianNeng()
    {
        return m_qianneng;
    }
    void AddQianNeng(int qianNeng)
    {
        m_qianneng += qianNeng;
        SendUpdateInfo(EUUT_QianNeng);
    }

	void GetChuZhanPetList(vector<SharePetPtr> &petList);	// 获得出战神将列表
	void GetQXChuZhanPetList(vector<SharePetPtr> &petList);
	bool IsQXPetDie(uint8 pos);

    const char *GetCall(int &script);

	uint16 GetTeamLevel();
	bool IsXunChaShiKilled(int npcId,int index);
	void SetXunChaShiKilled(int npcId,int index);

	bool AcceptCMission(int id,const char *pInts="",const char *pStrs="");
	bool AcceptCMission(int id,vector<int> &var,vector<string> &str);
	bool GetCMissionInts(int id,vector<int> &ints);
	const char *GetCMissionContent(CUser *pUser, int id);
	bool GetCMissionStrs(int id,vector<string> &strs);
	bool UpdateCMission(int id, const char *pInts, const char *pStrs);
	bool UpdateCMissionEx(int id, const char *pInts, const char *pStrs, int idx);
	bool UpdateCMission(int id,vector<int> &var,vector<string> &str);
	bool HaveCMission(int id);
	bool NoLockHaveCMission(int id);
	bool AddTeamCMission(int id,const char *pInts="",const char *pStrs="");
	bool DelCMission(int id);
	void UpdateCMissionState(int missId,int state);
	bool IsCMissionFinished(int missId);
	void DeleteFinishMissionById(int mid);
	
    void MakeMission(CNetMessage &msg);
    void DelBangpaiMission();//离开帮派时，删除帮派任务
	void AddBangpaiMission();//进入帮派时，添加帮派任务

	void ClearDataEveryDay();
	void ClearDataEveryWeek();
	void ClearFuBenData();
	void DoTaskEveryDay();
	void ResetQunXianData();

	void HuoYueDataChange();

	void NoticeClientToQueryNewData(uint8 type);

    SharePetPtr GetPet(uint16 petId);
	SharePetPtr NoLockGetPet(uint16 petId);
	void GetPetIdList(vector<uint16> &petList);
	
    void SetBitSet(char*);

    //188秒杀、189充值100反通宝
    void SetBitSet(int ind)
    {
        if(ind >= MAX_BITSET)
            return;
        m_bitset.set(ind);
    }
    void ClearBitSet(int ind)
    {
        if(ind >= MAX_BITSET)
            return;
        m_bitset.set(ind,false);
    }

    bool HaveBitSet(int ind)
    {
        if(ind >= MAX_BITSET)
            return false;
        return m_bitset.test(ind);
    }

	void SetMysteryData(const char *pStr);
	void GetMysteryData(string &str);

	void SetShenhunShopData(const char *pStr);
	void GetShenhunShopData(string &str);

	void SetYaoShiData(string saveData);
	void GetYaoShiData(string &str);

	// 阶段目标位变量相关
	void SetSGBitSet(const char*);
	void GetSGBitSet(string &str);
	void SetSGBitSet(int ind)
	{
		if (ind >= MAX_STAGE_GOAL_BITSET)
			return;
		m_stageGoalBitSet.set(ind);
	}
	void ClearSGBitSet(int ind)
	{
		if (ind >= MAX_STAGE_GOAL_BITSET)
			return;
		m_stageGoalBitSet.reset(ind);
	}
	bool HaveSGBitSet(int ind)
	{
		if (ind >= MAX_STAGE_GOAL_BITSET)
			return false;
		return m_stageGoalBitSet.test(ind);
	}

	uint8 InHuSongMission();
	uint8 NoLockInHuSongMission();
	bool InTreasure();
	uint8 GetHuSongMissionQuality();

    uint16 GetGenSuiPetId();
    void SetBangPai(uint32 bangpai,uint8 rank=0,const char *name=NULL);
	void SetBangPaiName(string name);
	void ReadBangPai();
	void AfterJoinBangPai();
    uint32 GetBangPai(){ return m_bangpai; }
	uint8 GetBangPaiRank(){ return m_bangpaiRank; }
	string GetBangPaiName(){ return m_bangpaiName; }
	uint8 GetBangPaiShowInfo(){ return GetExtData8(379); }
	void ReSetBangPaiShow(){ return SetExtData8(379,0); }
	void SetBangPaiShow(){ SetExtData8(379,1); }
	
	int GetBangState();
	int GetBangRank();
	string GetBangName();
	void DismissBang();// 解散帮派
	void UndismissBang();// 解除解散状态
	void SendBangPaiPlantCnt();//发送帮派种植次数
	void UpdateBangHuoYue(int type,int num = 0);
	int AddBangHuoYue(int value);
	bool GetBangHuoYueDesc(int type,SAttrTypeValue &val);

	bool UpBangSkillLv(CNetMessage &msg,int id,bool isAuto);
	void SetBangSkill(const char *skills);
	void GetBangSkill(string &str);
	bool MakeBangSkill(CNetMessage &msg);
	void GetBangSkillAttr(int type,vector<SAttrData> &attr);

	void SetVal(int id,int val);
	int GetVal(int id);

	bool SetDataStr(int type, const char* data); // 保存记录信息 每个玩家的type具有唯一性会覆盖
	const char* GetDataStr(int type); // 获取已经保存的记录
	const char* GetDataStr(int roleId, int type); // 获取已经保存的记录 玩家初始化的时候，存在没有roleid就读取数据的可能

	void SendUpdateInfo(int type, int addValue = 0);
	void SendUpdateMoney(int type);
	void UpdateJifenInfo();
	void UpdateAllPetInfo(int type=0);
	void UpdatePetInfo(uint16 petId);
	void UpdateZhenFaPetInfo(uint8 pos, bool notify = true);
	void SendPetUpdateInfo(uint16 petId,int type);
	void UpdateUserLevelUpInfo(uint64 oldZhanDouLi, uint64 oldPetZhanDouLi);

    SItemInstance *GetItem(uint16 pos)
    {
        if((pos >= MAX_PACKAGE_NUM) || (m_package[pos].tmplId == 0))
            return NULL;
        return m_package + pos;
    }

    SItemInstance *GetItemById(int id);

	int GetItemPosById(int id);
    void AddMoney(int add);

    uint16 GetGenSuiPet()
    {
        return m_gensuiPet;
    }
    void SaveData(CDatabaseSql *pDb,bool lock = true);

	void SaveLoginLog();
	void SaveLoginLog(CDatabaseSql *pDb);

	void GetPetDrawRatio(double &chengRatio,double &zi3Ratio,double &zi2Ratio);
	void SetPetDrawRatio(bool drawSpecPet,uint8 type=0);

    bool IsAutoFight()
    {
        return m_autoFightTurn > 0;
    }
    void GetAutoFightOp(uint8 &userOp,int &userPara)
    {
        userOp = m_userOp;
        userPara = m_userPara;
    }

    void SetAutoFightTurn(int turn)
    {
        m_autoFightTurn = turn;
    }
    int GetAutoFightTurn()
    {
        return m_autoFightTurn;
    }
    void SaveAutoFight(uint8 userOp,int userPara)
    {
        m_userOp = userOp;
        m_userPara = userPara;
    }

    bool ModifyPetName(uint16 petId,string &name,string &errMsg);
    void UpdatePet(uint16 petId);
	void NoLockUpdatePet(uint16 petId);

    void SetSaveVal(uint8 index,int val);
    int GetSaveVal(uint8 index);
    void SetSaveVal(char *msg);
    bool DelPackageById(int id,int num);
	bool NoLockDelPackageById(int id,int num);

	bool DelBankPackageById(int id,int num);
    int GetItemNum(int id, int level = 0);
	int NoLockGetItemNum(int id, int level=0);

	bool UseMultiCost(MultiCost& cost);

	bool NolockUpdateItemNumMap(uint16 itemId,uint32 num,bool add);

	bool DelPackageByIdLevel(int id, int level, int num); // 删除特定等级的物品数量
	int GetWeiJianDingShuiJingNum(); // 蓝水晶未绑定数量特殊处理
	bool DelWeiJianDingShuiJing(int num); // 删除未鉴定水晶的数量
	int GetmissDay();

	int AddCollect(int npcId,int npcIdx,int sceneId,int x,int y); // 添加采集npc
	int DelCollect(int npcId,int npcIdx,int sceneId); // 删除采集npc
	int GetCollectIndex() // 获取当前采集npc的索引
	{
		return m_collectIdx;
	}
	void SetCollectIndex(uint16 npcIdx) //设置当前采集npc的索引
	{
		m_collectIdx = npcIdx;
	}
	int AddCollectInfo(int sceneId,CNetMessage &msg); // 登陆显示npc用

	int MeetMonster(string &monsterName);
	int MakeMonsterInfo(int scenseId,CNetMessage &msg);
    int AddNpcInfo(int sceneId,CNetMessage &msg);
    int AddNpc(int scecseId,SNpcInstance &npc);

	void DelMonster(int monsterType,int sceneId);
	int AddMonster(SVisibleMonster &monster);
    uint16 DelNpc(int npcId,SNpcInstance &npc,int index=0);
    bool FindNpcNear(SNpcInstance &npc);
    bool MakeNpc(int ncpId,CNetMessage &msg);

	const char *GetBossMissionStarInfo();
	void GetBossMissionStar(string &str);
	uint8 GetBossMissionStarNum(int index);
	uint8 GetBossMissionTotolStarNum();

	void GetXiuXianInfo(string &str);
	void SetXiuXianInfo(char *str);
	bool IsOpenXiuXianByIdx(int idx);
	bool CanFightXiuXianByIdx(int idx);
	bool IsXiuXianWinByIdx(int idx);
	void SetXiuXianData(int idx,bool win);
	void MakeXiuXianMsg(CNetMessage &msg);
	void UpdateXiuXian(int idx);

	void SetBossMissionStar(char *str);
	void SetBossMissionData(int index,int starNum);
	void SetMonster(char *row);
    void SetNpc(char *row);
	void SetCollect(char *row);
    void UserJump(bool inJump)
    {
        m_inJump = inJump;
    }
    bool InJump()
    {
        return m_inJump;
    }
    void TimeOut(int &saveNum,const int limitSaveNum);
    void Clear();

	int GetBangGong();
	void AddBangGong(int banggong)
	{
		int value = GetExtData32(91);
		value += banggong;
		SetExtData32(91,value);
	}
	void ClearBangGong(){ SetExtData32(91,0); }
	
	bool GetNpc(int npcId,SNpcInstance &npc);
    const char *GetNpcName(int npcId);
    uint32 GetHumanNcpRoleId(int npcId);
    bool ReadData(uint32 roleId);
	
	bool ReadMirrorRoleData(int type);

	bool ReadBangPaiGuardData();
	void SaveBangPaiGuardData(uint8 guardIdx);
	bool CopyUserData(uint32 roleId,uint8 robotType=0);
	bool ReadDataSimple(uint32 roleId);

    void MakePetSkill(uint16 petId,CNetMessage &msg);

    void SetPetZhongCheng(uint8 pos,int zhongcheng);

	void SetUserDouble(int hour);
	void SetUserDoubleTime(int time);

    bool UserDouble()	// 多倍修炼丹时间
    {
        return time(NULL) < m_userDoubleEnd;
    }
	uint16 GetUseDoubleType()
	{
		return m_useDoubleType;
	}

    bool HaveItem(int id);
	bool HaveItem_PackageBank(int id);
	uint8 HaveEmptyPack();
	bool HaveLevelItem(int id,int level);

	bool HavePet(uint16 petId);
	bool NoLockHavePet(uint16 petId);
	bool HaveWing(uint8 id);

	void SendCgInfo(const char *animation); // 播放动画
	void Send_Anti_Addiction();		// 防沉迷
	void Send_HuoDongMsg();
	void CheckChongZhiHuoDong(bool isOnLine,uint32 money,uint32 tongbao,uint32 type = 0); // 校验充值活动
	bool ChongZhiJiJinFanli(uint32 money);
	bool ChongZhiLevelJiJinFanli(uint32 money, int addTongBao);
	bool ChongZhiHuoYueJinFanli(uint32 money, int addTongBao);
	void CheckMeiRiShouChong(bool isOnLine,int type);
	void NoticeChongZhiRet(bool isShouChong,uint32 money); // 通知客户端充值消息
	void NoticeMeiRiShouChong(); // 通知客户端每日首充消息
	void LianXuChongZhi(uint32 tongbao, uint32 huodongType);
	bool RoundZheKouHuoDong(uint32 money);   // 循环折扣
	void CheckFestivalDrop(int itemNum,bool isMail = false);

    void GetDropItem(string &item);
    void SetChatChannel(uint8 val)
    {
        m_chatChannel = val;
    }
    uint8 GetChatChannel()
    {
        return m_chatChannel;
    }
    void SetMaxHp(int maxHp)
    {
        m_attr.maxHp = maxHp;
    }

    void MoveItem(uint8 srcPos,uint8 tarPos);

	SNpcPos FindNpcPos(int npcId);
    CCallScript *FindNpcScript(int npcId);

	//int InitYaoLingAttr();
    void UpdateInfo();

    //type 0元宝，1绑定元宝
    int GetTongBao(uint8 type = 0)
    {
        if(type == 1)
            return m_bdTongBao;
        return m_tongBao;
    }
    void SetTongBao(int tongbao,uint8 type = 0)
    {
        if(type == 1)
            m_bdTongBao = tongbao;
        else
            m_tongBao = tongbao;
    }
	int GetMoBao()
	{
		return m_bdTongBao;
	}
    // 0元宝1绑定元宝
	bool AddTongBao(int tongbao, uint8 type = 0, int serverId = 0, bool huodongAdd = true);
	bool AddTongBaoEx(int tongbao, uint8 type = 0, int addtype = 1);

	// 增加竞技场积分
	void AddArenaJiFen(int addJiFen);

	// 获取当前竞技场积分
	int GetArenaJiFen()
	{
		return GetExtData32(97);
	}

    bool IsLogout()
    {
        return m_logout;
    }
    void UserLogout(bool flag)
    {
        m_logout = flag;
    }
    void GetRoles(uint32 *roles)
    {
        memcpy(roles,m_role,sizeof(m_role));
    }
    bool CanDelPackage(uint8 pos);
    int CanSellPackage(uint8 pos,uint8 num);

    void SendItemTimeOut();
    void UpdateBangPai();

    //给予绑定物品
    bool AddBangDingPackage(int itemId,int num = 1,const char *name = NULL,const char *mailMsg=NULL);
	bool AddBangDingPackageToBank(int itemId,uint8 num);

    //给予指定等级强化装备
    bool AddLevelPackage(int itemId,int level);

    void SetScene(CScene *p)
    {
        m_pScene = p;
    }
    int EmptyPackage();
    void SaveSellItem(uint8 pos,uint8 num);
    void SaveSellItem1(uint8 pos,uint8 num);
    void SaveDelItem(uint8 pos,uint8 num);

    int CanChat();
    void SetChatTime(time_t t)
    {
        m_chatTime = t;
    }
    uint32 GetChatTime()
    {
        return m_chatTime;
    }

    void SendMsgToTeamMember(const char *msg);
	uint64 GetChuZhanPet_AllZhanDouLi();
	void SendChuZhanPetId(CNetMessage &msg);

	void AddExpByItemWithTips(int64 exp,bool sendTipsFightEnd=false);

    uint8 AdminLevel()
    {
        return m_admin;
    }
	void SetAdminLevel(uint8 level)
	{
		m_admin = level;
	}
    void SetPkTime(time_t t)
    {
        m_pkTime = t;
    }
    bool CanPk()
    {
        return GetSysTime() - m_pkTime > 5*60;
    }
    bool UserInfoIsOpen()
    {
        return (m_chatChannel & 32) != 0;
    }
    bool CanFightHuoDong(int space);
    void SetHuoDongFightTime(time_t t)
    {
        m_huodongTime = t;
    }
    time_t GetLastHeartTime()
    {
        return m_lastHeartTime;
    }
    void SetLastHeartTime(time_t t)
    {
        m_lastHeartTime = t;
    }
    void SetHeartTimes(uint8 t)
    {
        m_heartTimes = t;
    }
    uint8 GetHeartTimes()
    {
        return m_heartTimes;
    }
    void SetHBErrTimes(uint8 t)
    {
        m_heartErrTimes = t;
    }
    uint8 GetHBErrTimes()
    {
        return m_heartErrTimes;
    }


    // 0师傅等级
    // 1比赛死亡次数
    // 2领取礼盒剩余时间
    // 3出师徒弟数量
    // 4,5,8脚本使用
    // 6 婚礼礼服状态
    // 7,8脚本使用
    // 9 被pk次数
    // 10,11,12,13,14世界大战金木水火土
    // 15脚本使用
    void SetData8(uint8 pos,uint8 data)
    {
        if(pos < UINT8_NUM)
            m_save8[pos] = data;
    }
    uint8 GetData8(uint8 pos)
    {
        if(pos < UINT8_NUM)
            return m_save8[pos];
        return 0;
    }

    // 0 声望（善恶）
    // 1 比赛积分
    // 2,5 脚本使用
    // 3 世界大战积分
    // 4 每天在线时间
    // 6 周积分
    // 7 每日积分
    // 8 挑战十妖使用时间 英雄
    // 10,11脚本使用
    // 12 端午活动积分
    // 13 放烟花数量
    // 14 自动升级物品信息，高位为物品类型，地位为等级
    void SetData16(uint8 pos,uint16 data)
    {
        if(pos < UINT16_NUM)
        {
        	if((pos == 0) && (data > 30000))
        		data = 30000;
            m_save16[pos] = data;
        }
    }
    void SetAutoLevelUp(uint8 type,uint8 level,int endTime)
    {
    	m_save16[14] = type<<8 | level;
    	m_save32[15] = endTime;
    }

	uint16 GetOriAd(); // 获取注册ad
    int GetDieTimes()
    {
        return GetData8(1);
    }
    uint16 GetData16(uint8 pos)
    {
        if(pos < UINT16_NUM)
        {
        	if((pos == 0) && (m_save16[pos] > 30000))
        		m_save16[pos] = 30000;
            return m_save16[pos];
        }
        return 0;
    }

    // 0 解散师徒关系时间
    // 1 状元、探花、榜眼title时间
    // 2 离开帮派时间
    // 3 副本id
    // 4 偷菜时间
    // 5 帮贡
    // 6 结婚roleid
    // 7 离婚时间
    // 8 结婚时间
    // 9 种菜积分（帮贡）
    // 10 恩爱值
    // 11 进入副本306时间
    // 12 魅力值
    // 13 结拜解散时间
    // 14 自动升级加经验时间
    // 15 自动升级结束时间
    void SetData32(uint8 pos,uint32 data)
    {
        if(pos < UINT32_NUM)
		{
            m_save32[pos] = data;
            if(pos == 6)
                m_save32[10] = 0;
        }
    }
    uint32 GetData32(uint8 pos)
    {
        if(pos < UINT32_NUM)
            return m_save32[pos];
        return 0;
    }
    int GetShengWang()
    {
        return GetData16(0);
    }
    void SetShengWang(int sw);

    void SetShiFu();

    const static uint8 UINT8_NUM = 16;
    const static uint8 UINT16_NUM = 16;
    const static uint8 UINT32_NUM = 16;

    void ReadSaveData(char *);
    const static int MAX_BITSET = 1024 * 8;
	const static int MAX_STAGE_GOAL_BITSET = 128 * 8;
    void GetBitSet(string &str);
    void WriteSaveData(string&);

    //神将学习技能
    bool PetStudySkill(uint16 petId,uint16 skillId,CNetMessage &msg);
	bool PetStudyBornSkill(uint16 petId, uint8 skillPos, CNetMessage &msg);
	bool PetStudySkillToMax(uint16 petId, uint8 skillPos, CNetMessage &msg);
	bool PetReplaceSkill(uint16 petId,uint16 itemId,uint8 skillPos,CNetMessage &msg);
	bool PetQualityLevelUp(uint16 petId,CNetMessage &msg);
	
	bool HeroLevelUp(CNetMessage &msg);
	bool HeroAutoLevelUp(CNetMessage &msg);
	bool HeroBreak(CNetMessage &msg);
	bool HeroXiuLian(CNetMessage &msg);
	bool HeroXiuLianJiHuo(CNetMessage &msg);
	bool HeroStarUp(CNetMessage &msg);
	bool HeroHeCheng(CNetMessage &msg);
	bool HeroCChongSheng(CNetMessage &msg);
	bool HeroChongSheng(CNetMessage &msg);
	uint8 GetHeroBreakNum(uint8 level);
	uint8 GetQualityPetCnt(uint8 quality);
	uint8 GetHeroStarNum(uint8 star);
	uint8 GetPowerPetCnt(uint32 power);

    //装备神将铠甲
    bool PetKaiJia(uint8 petPos,uint8 kaiJiaPos);

    bool HaveNameItem(uint16 itemId,const char *name);

    uint32 TempLeaveTeam()
    {
        return m_tempLeaveTeam;
    }
    void SetTempLeaveTeam(uint32 teamId)
    {
        m_tempLeaveTeam = teamId;
    }
    time_t GetActivityTime()
    {
        return m_activityTime;
    }
    void SetActivityTime(time_t t)
    {
        m_activityTime = t;
    }
	time_t GetTeamCallTime()
	{
		return m_teamCallTime;
	}
	void SetTeamCallTime(time_t t)
	{
		m_teamCallTime = t;
	}
	
	uint8 GetPetNum();

	void GetPackage(string &str);
	void GetPet(string &str);
	void GetMount(string &str);
	//add by zhudaolong
	bool HaveMount(uint8 id);
	void SetGuanZhan(uint32 fightId)
    {
        m_guanFight = fightId;
    }
    uint32 GetGuanZhan()
    {
        return m_guanFight;
    }
	uint32 GetTodayBangGong()
	{
		return m_todayBangGong;
	}
	void AddTodayBangGong(uint32 val)
	{
		m_todayBangGong += val;
	}

	uint32 GetMCEndTime(uint8 type);
	void BuyMonthCard(uint8 type = UPT_White_Gold);
	void ClearMonthCard(uint8 type);
	void SetMonthCard(uint8 type, uint32 countineTime = 0);	// 0白金 1钻石 2王者

    //0第四背包扩容、1 仓库扩容，2 神将仓库扩容
    //3【月夜除妖】每日领取次数，每日清
    //4超q礼盒领取等级
    //5每天完成pk任务次数
    //6月饼兑换百花礼盒个数,每日清楚
    //7 签到礼积分
    //8怪物攻城积分
    //9怪物攻城全属性增加
    //10领取超q礼包次数，每日清
    //11超Q主题日，强化装备的数量，每日清
	//12额龙潭4是否可以进入,1可进入
	//13春节活动脚本记录各玩家物品种类
    uint8 GetExtData8(uint16 pos);
    void SetExtData8(uint16 pos,uint8 val);
	uint16 GetDCMissExtData8Id(int miss);
	uint8 GetDCMissExtData8(int miss, int level = 0);
	uint32 GetDailyMissData8Id(int missId);
	uint8 GetDailyMissCompleteCnt(int missId);
	void AddDailyMissCompleteCnt(int missId);
	uint8 GetLingqiJuanxian(){return NoLockGetExtData8(69);}
	void IncLingqiJuanxian(){SetExtData8(69,GetLingqiJuanxian()+1);}
	uint8 GetMonthCard(){return GetExtData8(70);}
	
    uint8 GetBossTZNum(){return NoLockGetExtData8(74);}
	uint8 GetBossBuyNum(){return NoLockGetExtData8(109);}
	void IncBossBuyNum(){SetExtData8(109,GetBossBuyNum()+1);}
    uint8 GetArenaBuyNum(){return NoLockGetExtData8(110);}
	void IncArenaBuyNum(){SetExtData8(110,GetArenaBuyNum()+1);}
	void ClearArenaBuyNum(){SetExtData8(110,0);}
	uint8 GetFBQianghuaLevel(){return NoLockGetExtData8(126);}
	void IncFBQianghuaLevel(){SetExtData8(126,GetFBQianghuaLevel()+1);}
	uint8 GetFBJingbiLevel(){return NoLockGetExtData8(127);}
	void IncFBJingbiLevel(){SetExtData8(127,GetFBJingbiLevel()+1);}
	uint8 GetFBShengjieLevel(){return NoLockGetExtData8(128);}
	void IncFBShengjieLevel(){SetExtData8(128,GetFBShengjieLevel()+1);}
	uint8 GetFBQiannengLevel(){return NoLockGetExtData8(129);}
	void IncFBQiannengLevel(){SetExtData8(129,GetFBQiannengLevel()+1);}
	uint8 GetFBCuilianLevel(){return NoLockGetExtData8(130);}
	void IncFBCuilianLevel(){SetExtData8(130,GetFBCuilianLevel()+1);}
	uint8 GetFBZhankaiLevel(){return NoLockGetExtData8(131);}
	void IncFBZhankaiLevel(){SetExtData8(131,GetFBZhankaiLevel()+1);}

    //0礼盒物品
    //1充值积分
    //3【月夜除妖】积分
    uint16 GetExtData16(uint16 pos);
	void SetExtData16(uint16 pos, uint16 val);
	uint8 AddExtData8(uint16 pos, uint8 val);
	uint16 AddExtData16(uint16 pos, uint16 val);
	uint16 SubExtData16(uint16 pos, uint16 val);

    //0第四背包扩容、1 仓库扩容，2 神将仓库扩容结束时间
    //3怪物攻城失败时间,4怪物攻城战斗时间
    //4怪物攻城全属性增加结束时间
    //5 万圣节活动领取时间
    //6超Q礼包领取时间
    uint32 GetExtData32(uint16 pos);
	void SetExtData32(uint16 pos, uint32 val);
	uint64 GetExtData64(uint16 pos);
	void SetExtData64(uint16 pos, uint64 val);
	void AddExVipExp(uint32 val) { SetExtData32(457, GetExtData32(457) + val); }
	uint32 GetExVipExp() { return GetExtData32(457); }
	uint32 GetChongzhiTotal() { return GetExtData32(13); }
	void AddChongzhiTotal(int tb){SetExtData32(13,GetChongzhiTotal()+tb);}
    uint32 GetArenaTime(){return NoLockGetExtData32(24);}
	void SetArenaTime(uint32 t){SetExtData32(24,t);}
	
	void SetClientData(uint8 ind,int val)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_clientSave[ind] = val;
	}
	int GetClientData(uint8 ind)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint8,int>::iterator i = m_clientSave.find(ind);
		if(i != m_clientSave.end())
			return i->second;
		return 0;
	}

	void SetClientStrData(uint8 ind, string val)
	{
		if (ind == 73)
		{
			string old = GetClientStrData(ind);
			if (!old.empty() && atoi(old.c_str()) >= atoi(val.c_str()))
				return;
		}
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		m_clientData[ind] = val;
	}

	string GetClientStrData(uint8 ind)
	{
		boost::recursive_mutex::scoped_lock lk(m_mutex);
		map<uint8, string>::iterator i = m_clientData.find(ind);
		if (i != m_clientData.end())
			return i->second;
		return "";
	}

	map<uint8, string>& GetClientStrData()
	{
		return m_clientData;
	}

	void UpdatePackage(uint8 pos);
	void StopGuaJi();
	const char *GetLockPass()
	{
		return m_lockPass.c_str();
	}
	void SetLockPass(const char *pass)
	{
		if(pass != NULL)
			m_lockPass = pass;
	}
	void SetStrVal(const char *val)
    {
    	if(val != NULL)
    		m_strVal = val;
    }
    const char *GetStrVal()
    {
    	return m_strVal.c_str();
    }
    void SetDelPassTime(int t)
    {
    	m_delLockPassTime = (time_t)t;
    }
    int GetLeftDelPassTime()
    {
    	if(m_delLockPassTime == 0)
    		return 0;
    	int left = m_delLockPassTime - GetSysTime();
    	if(left > 0)
    		return left;
    	return 0;
    }

	// 获得玩家登陆时间长度
	int GetOnlineSecond()
	{
		return (GetSysTime() - m_loginTime);
	}
	
	time_t Get_RegTime(){return reg_time;}
	int GetRegTime() {return (int)reg_time;}
	bool IsInRegDay(int day);
	int GetRegDay();  // 获取创角自然天, 1日23时创角, 2日1时就是创角两天
	int GetRegDayToAfterDaySec(int day);
	bool InScriptCall();
	void Set_InScriptCall(bool flag);
	void SetInteractNpc(SNpcInstance *pNpc)
	{
		m_Npc = *pNpc;
	}
	SNpcInstance &GetInteractNpc()
	{
		return m_Npc;
	}
	SNpcInstance *GetInteractNpc(int npcId, int npcIdx);
	
	void SetYinDaoItem(bool val){have_yindao_item = val;}
	bool GetYinDaoItem(){return have_yindao_item;}
	void SetAd(uint16 ad)
	{
		m_ad = ad;
	}
	uint16 GetAd()
	{
		return m_ad;
	}
	void SetMobileType(uint16 mobileType)
	{
		m_mobileType = mobileType;
	}
	int GetMobileType()
	{
		return m_mobileType;
	}
	void SetMobileInfo(string &info)
	{
		m_mobileInfo = info;
	}
	string GetMobileInfo()
	{
		return m_mobileInfo;
	}
	
	void SetVersion(int version)
	{
		m_version = version;
	}
	int GetVersion()
	{
		return m_version;
	}
	bool SetFightData(char *str);
	bool SendFightData();
	void ClearFightData();

	int InsertDoptionNode(int pid,const char *selectop,const char *name,const char *src,const char *op,uint8 call);
	bool AddDoptionSubNode(CMultiTreeDoptionNode **pnode,const string op);
	CMultiTreeDoptionNode *findDoptionNodeById(int pid);
	void DoptionClear();
	void DoptionPrint();
	void DoptionEnd();
	void SetDoptionCall(int nodeId,const char *call);
	bool DoptionCall(int nodeId);
	int DoptionBegin(const char *name,const char *src,const char *op,uint8 call);
	int Doption(int pid,const char *selectop,const char *name,const char *src,const char *op,uint8 call);

	void SendShopCanDrawPetInfo(bool show=true);

	bool TryKuaFuZhanShengLingZhiYi(); // 是否可以显示跨服战第一名圣灵之翼奖励

	int GetOtherTitle(){return m_OtherTitle;}
	bool InScriptCallOption(int val);
	void GetScriptCallOption(list<int> &val);
	void SetScriptCallOption(list<int> *val=NULL);
	void ClearScriptCallOption() { m_scriptOption.clear(); };
	bool IsScriptCallOptionEmpty(){return m_scriptOption.empty();}

	void SetPersonalID(string &personal_ID);
	bool IsRealNameRegistration();
	void GetPersonalID(string& personal_ID);
	void GetAccountName(string& accountName); // 获取账号名
	int GetAccountBinding(); // 获取绑定信息
	int GetAccountRecordPhone();
	void GetAccountInfo();
	void SetAccountName(const char *accountName);
	void SetAccountBinding(int binding);
	void SetRecordPhoneState(int state);
	bool BackLibaoInfoExist(const char *name);
	bool CanGetBackLibao(const char *name);
	void UpdateBackLibaoInfo(const char *name);

	void Set360Id(int id360)
	{
		m_360_id = id360;
	}
	int Get360Id()
	{
		return m_360_id;
	}
	void Set360ExpiresInTime(time_t time360)
	{
		m_360_expires_in_time = time360;
	}
	time_t Get360ExpiresInTime()
	{
		return m_360_expires_in_time;
	}
	void Set360AccessToken(string& token)
	{
		m_360_access_token = token;
	}
	void Get360AccessToken(string& token)
	{
		token = m_360_access_token;
	}
	void Set360RefreshToken(string& token)
	{
		m_360_refresh_token = token;
	}
	void Get360RefreshToken(string& token)
	{
		token = m_360_refresh_token;
	}
	void Get360LoginInfo();

	void SetFuBenBackPoint(SJumpTo &val){m_FuBenBackPoint = val;}
	SJumpTo GetFuBenBackPoint(){return m_FuBenBackPoint;}

	void ItemHeCheng(int pos, int isAll = 0); // 材料合成
	void ItemHeChengNum(uint16 itemId, int num); // 材料合成
	void ItemFenjie(vector<uint8> poss);// 分解

	uint32 GetYaoLingZhanDouLi(){	return m_yaolingZhanDouLi;}
	uint64 GetZhanDouLi(){return m_zhanDouLi;}
	
	void SetZhanDouLi(uint64 zhanDouLi) { m_zhanDouLi = zhanDouLi; }
	int GetPetZhanDouLi();
	void Multi_Exp_UpdateActiveTime();	// 5倍经验时间更新
	void Multi_Exp_DelActiveTime();
	void Multi_Exp_Notice();
	time_t GetLastSendMailTime(){return sendMailTime;}
	void UpdateSendMailTime(){sendMailTime = GetSysTime();}
	void SendYaBiaoMissionState(uint8 type,uint8 quality);

	const static int EQUIPMENT_NUM = 8;
	const static int ShowMysteryItemNum = 9;
	const static int ShowShenjiangItemNum = 9;
	const static int MAX_MONEY = 2000000000;
	const static int MAX_SHEN_HUN = 2000000000;

public:
	void TimeOutUpdateUserData();
	void SaveDataSimple();
	void UpdateShopPetDrawState();
	void SetBasicAttrOff();
	bool CopyOnlineUserData(CUser* pSrcUser);
	void SaveData();

    uint8 NoLockGetExtData8(uint16 pos);
    uint16 NoLockGetExtData16(uint16 pos);
	uint32 NoLockGetExtData32(uint16 pos);
	uint64 NoLockGetExtData64(uint16 pos);

	void JieRiLiBaoClearData(uint32 huodongType);

	int GetMoGuCZ();
	void SetMoGuCZ(int cz);
	int GetMoGuWaterTimes();
	void DelMoGuWaterTimes();
	int GetMoGuBugTimes();
	void DelMoGuBugTimes();

	void GetAllUseTitleAttr(vector<SAttrData> &attr);
	void UpdateLianXuChongZhiState(uint32 huodongType);
	void FestivalClearData();
	void ZhenYingPKClearData();
	void QiangHongBaoClearData();
	uint32 GetTeamUIQueryTime(){return m_teamUIQTime;}
	void SetTeamUIQueryTime(uint32 val){m_teamUIQTime = val;}
	uint16 GetTeamUIQueryType(){return m_teamUIQType;}
	void SetTeamUIQueryType(uint16 val){m_teamUIQType = val;}
	void SetCangBaotuId(uint32 id ){cangbaotuid_ = id ;}
	uint32 GetCangBaotuId(){return cangbaotuid_;}

	uint16 m_lastSrcSceneId;
	uint8 m_autoMatchTeamType;	// 自动匹配快捷组队类型
	time_t entergametime_;  // 玩家进入游戏的时间戳
	uint32 checkOnLineTime_; //检测在线时间的时间戳
	uint32 cangbaotuid_;

private:
	int getValueByPos(int n,int m);
	void HuoDongClearDataTimeOut();
	void HuoDongClearDataEveryDay();
	void ChongZhiBangClearData();
	void SendLeiJiChongZhiAward(uint32 huodongType);
	void LeiJiChongZhiClearData(uint32 huodongType);
	void ChristmasTreeClearData();
	void XinChunHappyClearData();
	void SendLeiJiXiaoFeiAward(uint32 huodongType);
	void LeiJiXiaoFeiClearData(uint32 huodongType);
	void SendMeiRiShouChongAward(bool isWeiXin = false);
	void MeiRiShouChongClearData();
	void ChongZhiFanYBClearData(uint32 huodongType);
	void MeiRiXiaoFeiClearData(uint32 huodongType);
	void SendMeiRiXiaoFeiMail(uint32 huodongType);

	void HuanLeShengYanClearData();
	void HongLiClearData(uint32 type);
	void MoGuClearData();
	void HongLiJiFenClearData(uint32 type);
	void QinaghuaKuanghuanClearData();
	void ShengjieLetianClearData();
	void HDClearItem(uint32 hd_type);
	void MeiRiHuanHaoLiClearData();
	void LianXuChongZhiClearData(uint32 huodongType, bool isEveryDay = false);
	void SendLianXuChongZhiAward(uint32 huodongType);
	void SendChongZhiFanYBMail(uint32 huodongType);
	void JijinFanliClearData(uint32 type);
	void SendJijinFanliAward(uint32 type);
	void XianShiChouClearData();
	void SendXianShiChouAward();
	void ZhuanPanLiJiFenClearData();

    void ClearGuaJi();
	void SetVipAddAttr(bool sendUpdate=false);
	void ClearVipAddAttr();

	bool CopyOfflineUserData(uint32 roleId,uint8 robot=0);	// robot: 0 正常 1 竞技场机器人 2 试炼机器人 3 修仙机器人

    void NoLockSetExtData8(uint16 pos,uint8 val);
    void NoLockSetExtData16(uint16 pos,uint16 val);
	void NoLockSetExtData32(uint16 pos, uint32 val);
	void NoLockSetExtData64(uint16 pos, uint64 val);

    void NoLockMakePetSkill(uint16 petId,CNetMessage &msg);

	void HuoyueJijinClearData();
	void DailyFanliData();

	SNpcInstance m_Npc;
    time_t m_huodongTime;
    time_t m_saveDataTime;
    time_t m_loginTime;
    time_t m_chatTime;
    time_t m_lastHeartTime;
    time_t m_activityTime;
	time_t m_teamCallTime;
	uint16 m_curMonthDay;
	
	time_t reg_time;
	uint32 m_teamUIQTime;	// 队伍界面请求操作时间戳
	uint16 m_teamUIQType;	// 请求发布队伍类型

    uint8 m_heartTimes;
    uint8 m_admin;
    uint8 m_heartErrTimes;
	bool inscriptcall;
	bool have_yindao_item;
	vector<CNetMessage> m_fightdata;
	vector<UserMysteryItem> m_mysteryItem;
	vector<UserYaoShiItem> m_yaoshiItem;
	vector<UserMysteryItem> m_shenhunItem;
	uint32 m_fightdata_pos;

    void NoLockSaveData(CDatabaseSql *pDb);

    bool m_callLevelScript;
    bool m_logout;

	uint32 m_mysteryTime;
	uint32 m_yaoshiTime;
	uint32 m_shenhunTime;

    //如果是使用脚本，返回脚本id
    CCallScript *NoLockUseItem(uint8 pos,int *pAddHp,int *pAddMp,uint8 val,uint8 val1,uint8 num);
	void NoLockUseItem(uint8 pos, uint8 num, uint8 tar);

    bool m_inJump;
	SJumpTo m_FuBenBackPoint;

	CCallScript *GetTimeOutNpcScript();
    bool NoLockAddBankItem(SItemInstance &item,uint8 &tolSaveNum);
    void NoLockDelBankItem(uint8 bankPos);
    bool NoLockAddPackage(SItemInstance &item,const char *mailMsg=NULL);
    bool NoLockDelPackage(uint8 pos,uint16 num = 1);
    void NoLockDelPet(uint16 petId,bool sendMsg=true);
    bool NoLockAddPet(SharePetPtr &ptr,uint16 *toItemId,uint16 *toItemNum);

public:
	const static int MAX_TRADE_NUM  = 3;
	const static int MAX_CHAR_MSG_NUM = 5;
	const static int MAX_USE_TITLE_NUM = 5;
	int m_errProtocolNum;
	void SetRobot(uint8 value){m_robot = value;}
	uint8 GetRobot(){return m_robot;}
	void InsertChatMsg(string &str);
	bool IsSendChatMsg(string &str);
	void SortPackage();
	void PrintPackage();

	bool MakePetById(uint16 petId,CNetMessage &msg);
	bool NoLockMakePetById(uint16 petId,CNetMessage &msg);
	bool MakePetData(SPet *pPet, CNetMessage &msg);
	uint8 GetPetZhenFaIdx(uint16 petId);
	uint8 GetChuZhanIdx(uint16 petId);
	void ShowFindResourceMsg(CNetMessage &msg);
	bool BuyFindResource(CNetMessage &msg, uint16 funcId, uint16 findNum);
	bool BuyAllFindResource(CNetMessage &msg,uint8 findType);
	void AddTeamBreakAttr(MultiAttr& attr);
	void SendZhaoHuiHotPointStatus();
	MultiAttr& GetTeamBreak();
private:
    void MakePack(SItemInstance &item,uint16 pos,CNetMessage &msg);
    bool CanSavePackage(SItemInstance **pItem,uint8 num);
	void ClearTimeoutTitle();
	void CalculateFindResource();

    uint16 m_xPos;
    uint16 m_yPos;
	uint16 m_xOrig;
	uint16 m_yOrig;

    uint8 m_face;
    uint8 m_sex;	// 0男1女
	uint8 m_head;	// 头像
	uint8 m_model;	// 模型
    uint16 m_level;

    uint8 m_fightPos;	// 准备弃用
    uint16 m_autoFightTurn;
	
    bool m_isLoadMiss;

    const static int MAX_TITLE_NUM = 100;
    const static int TITLE_ARRAY_SIZE = 110;	// 61-70 1个可见称号和5个使用称号
    //STitleData m_titleList[TITLE_ARRAY_SIZE];
	titleMap m_titleList;
	titleSet m_useTitle;

    int m_qianneng;
	time_t sendMailTime;
    uint32 m_userId;
    uint32 m_roleId;
	uint32 m_role[MAX_ROLE_NUM];
    int m_sock;
    int64 m_exp;
	char m_expStr[32]; // 显示用

	uint8 m_attackType;
	SUnitBasicAttr m_attr;
		
    uint32 m_fightId;
    int ex_shanbi;		//闪避的有符号处理，他人请勿轻易使用 add by chy
    int m_money;
    int m_tongBao;
    int m_bdTongBao;

    uint32 m_step;
    uint64 m_moveTime;
    uint8 m_moveErrTimes;
	uint16 m_moveSpeed;

	struct AskForJoinTeamData
	{
		uint32 teamId;
		uint32 joinTime;
	};
    list<AskForJoinTeamData> m_askForJoinTeam;
	list<string> m_chatMsg;
    uint32 m_teamId;
    uint32 m_bangpai;
	uint32 m_todayBangGong;
	uint8 m_bangpaiRank;
	string m_bangpaiName;

    //自动战斗保存数据
    uint8 m_userOp;
    int  m_userPara;

    uint8 m_save8[UINT8_NUM];
    uint16 m_save16[UINT16_NUM];
    uint32 m_save32[UINT32_NUM];

    //0第四背包扩容、1 仓库扩容，2 神将仓库扩容
    map<uint16,uint8> m_saveData8;
    map<uint16,uint16> m_saveData16;
    //0第四背包扩容、1 仓库扩容，2 神将仓库扩容结束时间
	map<uint16, uint32> m_saveData32;
	map<uint16, uint64> m_saveData64;
	//客户端需要服务器保存的数据
	map<uint8, int> m_clientSave;
	map<uint8, string> m_clientData;

    uint32 m_guanFight;	//观战的战斗
    CScene *m_pScene;
	char m_name[MAX_NAME_LEN];

	list<string> m_zhaDanHistory;

	//add by zhudaolong 2017.11.02
	//桃花羹制作历史
	bool isInitTHGHistory;
	vector<HdShowHistoryNode> m_THGHistory;

	struct HDShowHistoryList
	{
		list<struct HdShowHistoryNode> showHistory[2];
	};
	map<uint32,HDShowHistoryList>  m_showHistory;

	list<struct HdShowHistoryNode> m_jiaoYiRecord[2];

	struct SScriptCall
	{
		int scriptId;
		string func;
	};
	string m_scriptCall;
	int m_script;
	MultiAttr m_breakAttr;

public:
	const static int MAX_PACKAGE_NUM2 = 500;
	const static int MIN_PACKAGE_NUM = 40;
	const static int MAX_XIU_XIAN_NUM = 40;
	const static int MAX_QX_ATTR_NUM = 16;
	const static int MAX_QX_PET_NUM = 10;
	bool AddMaxPackageNum(int num=1)
	{
		if(MAX_PACKAGE_NUM >= MAX_PACKAGE_NUM2)
			return false;
		if(num == 0)
			return false;
		if(num > MAX_PACKAGE_NUM2 - MAX_PACKAGE_NUM)
			num = MAX_PACKAGE_NUM2 - MAX_PACKAGE_NUM;
		MAX_PACKAGE_NUM += num;
		m_nextOpenPackageTime = (MAX_PACKAGE_NUM - MIN_PACKAGE_NUM + 1)*40*60;
		SendUpdateInfo(EUUT_OpenPackageNum);
		SendUpdateInfo(EUUT_NextOpenPackageTime);
		return true;
	}
	void SetMaxPackageNum(){MAX_PACKAGE_NUM = MAX_PACKAGE_NUM2;}
	uint16 GetMaxPackageNum(){return MAX_PACKAGE_NUM;}
	uint32 GetNextOpenPackageTime(){return m_nextOpenPackageTime;}
	void SetMeetEnemy(bool canMeet){m_meetEnemy = canMeet;}
	void RecoveryAllHp();
	int GetScriptId(){return m_script;}
	
	uint8 GetFeiXianState();
	void SetFeiXianState(uint8 val);
	uint8 GetPrenticeLevel(){return GetExtData8(386);}
	uint32 GetMasterExp(){return GetExtData32(16);}
	uint8 GetMasterLevel(){return GetExtData8(385);}

	uint8 GetPlantWateringCount();	// 获取浇水次数
	void AddPlantWateringCount();
	uint8 GetPlantKillBugCount();	// 获取除虫次数
	void AddPlantKillBugCount();
	uint8 GetPlantStealCount();		// 获取偷窃次数
	void AddPlantStealCount();
	uint8 GetKillPlayerCount();
	void AddKillPlayerCount();
	uint8 GetPlantPlantsCount();	// 获取种植次数
	uint8 GetPlantSeedTypeCount(uint8 type);	// 按种子类型获取种菜次数
	void AddPlantSeedTypeCount(uint8 type);
	bool HaveGetBangPaiTaskReward(uint8 type);	// 是否领取帮派任务对应的奖励,1种植2浇水3除虫4偷窃
	void SetBangPaiTaskReward(uint8 type);

	uint8 GetJiaoYouCount();	// 交游
	void AddJiaoYouCount();
	uint8 GetCheckYanShengShiCount();	// 查验生石
	void AddCheckYanShengShiCount();
	uint8 GetCheckDuoXianYinCount();	// 查堕仙印
	void AddCheckDuoXianYinCount();
	uint8 GetQiMouCount();	// 奇谋
	void AddQiMouCount();
	uint32 GetJuanXianMoney();	// 捐献金币
	void AddJuanXianMoney(int money);
	bool IsGetBangPaiTaskAward(int taskId);	// 新版获得帮派任务奖励是否领取
	void SetBangPaiTaskAward(int taskId);

	uint8 GetBangPaiYBPrayNum();
	void AddBangPaiYBPrayNum();
	void ClearBangPaiYBPrayNum();
	uint8 GetBangPaiNormalPrayNum();
	void AddBangPaiNormalPrayNum();
	void ClearBangPaiNormalPrayNum();

	uint8 GetBangPaiRobNum();
	void AddBangPaiRobNum();
	void ClearBangPaiRobNum();

	uint32 GetShenhun();
	uint32 NoLockGetShenhun();
	void AddShenhun(int addNum);

	uint32 GetJifen();
	uint32 NoLockGetJifen();
	void AddJifen(int addNum);

	void AddEquip(uint16 id, uint8 star);
	void AddEquipMoney(int addNum);
	uint32 GetPetEquipMoney();

	uint8 GetMoBaiBowNum();
	void AddMoBaiBowNum();
	uint8 GetMoBaiEggNum();
	void AddMoBaiEggNum();

	void SetBangPaiFireTime();
	uint32 GetBangPaiFireTime();
	void ClearBangPaiFireTime();
	void SetBangPaiStealTime();
	uint32 GetBangPaiStealTime();
	void ClearBangPaiStealTime();

	void PushGongGao(const char *pStr);
	bool PopGongGao(string &out);

	void SetQunXianData(const char *row);
	void GetQunXianDataStr(string &str);

	void SetClientString(char *pStr);
	void GetClientString(string& str);

	void GetFindResource(string &str);
	void SetFindResource(const char *pStr);

	// 答题信息
	void SetQuestionStr(const char *pStr);
	void GetQuestionStr(string& str);
	void ClearQuestionId();
	int GetQuestionId(size_t maxIdx);

	int GetServerId(){return m_serverId;}
	void SetServerId(int value){m_serverId = value;}
	void SetLogInfo(string &netInfo,string &mac,string &IMEI,string &IDFA)
	{
		m_netInfo = netInfo;
		m_mac = mac;
		m_IMEI = IMEI;
		m_IDFA = IDFA;
	}

	void CheckFBLevel();
	void SendTreasureMapMsg();
	void NotifyUserShowCangBaoTuPanel();
	void NotifyTreasureMapUseResult(); // 藏宝图的使用结果
	uint16 GetPetExchangeList(CNetMessage &msg);
	uint16 GetItemChipExchangeList(CNetMessage &msg);
	void UpdateFeiXianData();
	void MakeFeiXianData(CNetMessage &msg);
	void AddFeiXianFirstAward(int minute);

	void MountTimer();

	// 通天塔扫荡
	int m_curTongTianTaFightFloor;	// 当前通天塔战斗层数
	void TongTianTaSaoDang(CNetMessage &msg);		// 扫荡

	// 钓鱼相关
	CFishRoom* GetFishRoom() { return m_pFishRoom; } // 获取钓鱼房间
	void SetFishRoom(CFishRoom* pFishRoom) { m_pFishRoom = pFishRoom; } // 设置钓鱼房间
	void TryFishTimeout();	// 钓鱼定时器
	time_t GetFishTime();	// 获取钓鱼开始的时间
	void ExitFishRoom();	// 离开钓鱼房间
	uint8 m_fishState;		// 玩家钓鱼的状态
	uint8 m_fishSceneSrcId;	// 记录玩家的钓鱼的srcid，切换地图用
	time_t m_grabedTime;	// 标记玩家被抢夺的时间
	time_t m_grabedProtectTime;	// 被抢夺保护时间

	// 离线经验相关
	void UpdateOfflineExpTime();	// 更新离线经验时间
	time_t GetOfflineExpTime();		// 获取离线经验时间
	void ResetOfflineExpTime();		// 重置离线经验时间
	int GetOfflineExp(int type);	// 获取某种类型的离线经验
	enum EOfflineExpType
	{
		EOET_FREE, // 免费
		EOET_CURRENCY, // 不绑定金
		EOET_VIP, // VIP
	};

	// 副本扫荡
	void SetSaoDangFuBenId(int fubenId) // 设置扫荡副本id
	{
		SetExtData8(36,fubenId);
	}
	int GetSaoDangFuBenId() // 获取扫荡副本id
	{
		return GetExtData8(36);
	}
	void SetSaoDangFuBenCiShu(int count) // 设置扫荡副本次数
	{
		SetExtData8(37,count);
	}
	int GetSaoDangFuBenCiShu() // 获取扫荡副本次数
	{
		return GetExtData8(37);
	}
	void SetSaoDangFuBenPerTime(int perTime) // 设置扫荡副本单次用时
	{
		SetExtData16(37,perTime);
	}
	int GetSaoDangFuBenPerTime() // 获取扫荡副本单次用时
	{
		return GetExtData16(37);
	}
	void SetSaoDangFuBenTime(time_t time) // 设置扫荡副本时间
	{
		SetExtData32(5,time);
	}
	time_t GetSaoDangFuBenTime() //获取扫荡副本时间
	{
		return GetExtData32(5);
	}
	void GetSaoDangFuBenInfo(); //获取扫荡信息
	void SaoDangFuBen(uint16 fbId, int cnt, CNetMessage& msg);
	void ContinueSaoDang();
	void AccelerateSaoDangFuBen();
	bool GetFBTongGuan(int fbid);
	bool GetPetFBTongGuan(int idx);
	uint8 GetFBLevel(int fbid);
	int GetFBDorpId(uint32 sceneId);
	int GetEnterFBMoney(int fbId,bool isExtra=false);
	
    void UpgradeFBLevel(int fbid);
	void ShowHuoDongIcon();
	
	//猜拳
	void SetCaiQuanCiShu(int cishu) //设置猜拳次数
	{
		SetExtData8(38,cishu);
	}
	int GetCaiQuanCiShu() //获取猜拳次数
	{
		return GetExtData8(38);
	}
	void SetCaiQuanEndTime(time_t time) //设置猜拳冷却结束时间
	{
		SetExtData32(8,time);
	}
	time_t GetCaiQuanEndTime() //获取猜拳冷却结束时间
	{
		return GetExtData32(8);
	}
	int AddCaiQuanReward(bool isWin, int rewardType); //获取猜拳奖励 返回奖励的数值
	void AddGongGao(const char *str);

	// 任务校验
	void CheckMissionHuoYueDu(bool isAdd = true); // 活跃度次数+1并任务完成校验
	void CheckMissionZiPet(int ziPetNum = -1); // 紫神将数量任务校验

	void AddBangAreaContinuousKillNum(){m_bangArea_killNum++;}
	void ClearBangAreaContinuousKillNum(){m_bangArea_killNum = 0;}
	uint16 GetBangAreaContinuousKillNum(){return m_bangArea_killNum;}

	void SetCeLue(uint16 cl){m_celue = cl;}
	uint16 GetCeLue(){return m_celue;}

	void SetLoginSig(uint32 sigId,string &sigStr);
	uint8 GetKuaFuState(){return m_kuafuState;}

	void AddQunXianBufferState(int type,uint32 value);

	float GetQunXianRoleHpRatio();
	float GetQunXianPetHpRatio(uint8 pos);
	void SetQunXianHpRatio(uint8 type,uint8 pos,float &val,bool die);	// type 1神将 2人
	void CopyQunXianAttrVal(uint32 *addAttrVal,int vsize,uint16 *addAttrPercent,int psize);
	bool SetQunXianPets(uint16 *petId,int size);
	void SetQunXianPetChuZhan(uint8 type,uint16 petId,uint8 zhanweiPos,CNetMessage &msg);
	void MakeQunXianPetMsg(CNetMessage &msg);
	bool HaveGetQunXianAward(int idx);
	void SetQunXianAwardFlag(int idx);
	void SendQunXianPetList();
	void MakeQunXianBuffMsg(CNetMessage &msg);
	void SetQunXianCurFloor(uint8 floor);

	void SetHuoYueTaskList(vector<HuoYueTaskInfo> &infos);
	void GetHuoYueTaskList(vector<HuoYueTaskInfo> &infos);
	void CreateHuoYueTask();
	void CreateHuoYueTaskById(uint8 id);
	void SetHuoYueTaskMax(uint32 taskMax);

	void GetCurrentZhenFaData(vector<SZhenFaMemData> &userData);

	void GetAllPartAttr(vector<SAttrData> &attr);
	bool CheckCostMaterial(vector<SAwardData> &materials,string &error);
	bool NoLockCheckCostMaterial(vector<SAwardData> &materials,string &error);
	bool DelCostMaterial(vector<SAwardData> &materials);
	bool NoLockDelCostMaterial(vector<SAwardData> &materials);
	bool CheckCostMaterial(vector<SCostData> &materials,string &error);	
	bool NoLockCheckCostMaterial(vector<SCostData> &materials,string &error);
	bool DelCostMaterial(vector<SCostData> &materials);
	bool NoLockDelCostMaterial(vector<SCostData> &materials);
	bool AddMutilMaterial(vector<SAwardData> &materials, CNetMessage* msg = NULL, bool isFight = false, bool showMsg = true, int addType = 0);
	bool AddMaterial(uint32 type, int value, bool isFight = false, bool showMsg = true, int star = 1);
	void AddMaterial(SAwardData& ad, bool isFight = false, bool showMsg = true, uint8 num = 1);
	bool SubMaterial(uint32 type, uint32 value, bool showMsg = true);
	void AddMultiAward(MultiAward& award, bool isFight = false, bool showMsg = true, int addType = 0);
	bool AddMutilMaterial(uint32 type, int value, int star, int num);
	void AddMultiCost(MultiCost& cost, bool isFight = false, bool showMsg = true);
	void AddSingleCost(SCostData& cost, bool isFight = false, bool showMsg = true);
	int AddArenaRankAward(uint32 rank);

	uint32 GetMaterial(uint32 type);
	void GetAutoUseItemAward(uint16 itemId,uint16 itemNum,vector<SAwardData> &awardList);
	void SyncPowerToMatch();
	void MatchYingYongRobot(int floor);
	void MatchFight(int startPower, int endPower, uint8 cnt);
	void AddYingYongShiLianNpc();
	void SendLeiTaiJifen();
	void SendKuaFuIconState(bool show);
	bool IsShiLianRandAwardEmpty(){ return m_shilianRandAward.empty();}
	void ClearShiLianRandAward(){ m_shilianRandAward.clear();}
	void SetShiLianRandAward(vector<SAwardData> &val){ m_shilianRandAward.assign(val.begin(),val.end());}

	time_t m_zaiXianLingHaoLiTime; // 开服活动 在线领好礼 上次领取时间

	bool m_isInDaTi; // 是否在答题活动状态中

	vector<struct HuoYueTaskInfo> m_huoyueTaskList;
	uint32 m_huoyueTaskMax;

	CUserMission m_missList;

	CUserMission& GetUserMission() { return m_missList; }

	void GetBangPaiCopyStr(string &val);
	void SetBangPaiCopy(const char *pStr);
	bool HaveGetBangPaiCopyAward(int copyId);
	void SetBangPaiCopyAward(int copyId);
	void AddHuoYue(int huoyue);
	void AddBangExp(int value);
	bool HaveGetBangPaiHuoYueAward(int id);
	void SetBangPaiHuoYueAward(int id);
	
private:
    uint16 MAX_PACKAGE_NUM;		// 当前最大开启背包格子数
    uint32 m_nextOpenPackageTime;
    SItemInstance m_package[MAX_PACKAGE_NUM2];
	map<uint16,uint32> m_itemNumMap;
	map<uint32, uint8> m_bpCopyAward;	// 帮派副本领奖信息, [copyId]-0未领奖1领奖
	map<uint16, uint8> m_bpHuoYueAward;	// 帮派活跃领奖信息, [id]-0未领奖1领奖

//    const static int MAX_BANK_ITEM_NUM  = 80;
//    SItemInstance m_bankItem[MAX_BANK_ITEM_NUM];

    vector<SPet> m_bankPet;

    const static int MAX_SHOP_ITEM_NUM = 6;
	const static int MAX_CHU_ZHAN_NUM = 5;
	const static int MAX_ZHEN_RONG_NUM = 2;
    uint16 m_gensuiPet;		//跟随神将
    CPetMap m_pet;
	vector<SZhenFaData> m_zhenfa;	// 阵法
	uint8 m_useZhenFaIdx;	// 使用阵法idx
	vector<SZhenFaMemData> m_zhenfaMember;
	vector<uint16> m_chuzhan;	// 出战位置

	SResource m_findResouce;

    uint16 m_qx_petlist[MAX_QX_PET_NUM];		// 群仙，神将pos
    uint16 m_qx_chuzhan[MAX_CHU_ZHAN_NUM];	// 群仙，出战神将
	uint16 m_qx_hpRatio[MAX_QX_PET_NUM+1];	// 群仙，血量比例，10神将+人, val /= 10000
	uint16 m_qx_dieFlag;	// 群仙，神将死亡标记,位标记，1死亡, (pos 0~9神将，10 人)
	uint64 m_qx_awardFlag;	// 群仙，首通奖励领取标志, 位标记 1 已领取 0 未领取

	// 值: 		1攻击 2暴击 3闪避 4反击 5连击 6防御 7速度 8抗性       16血
	// 百分比:	17攻击18暴击19闪避20反击21连击22防御23速度24抗性      32血
	uint32 m_qx_addAttrVal[MAX_QX_ATTR_NUM];	// 群仙，值加成
	uint16 m_qx_addAttrPercent[MAX_QX_ATTR_NUM];// 群仙，比例加成，比例val /= 10000
	
    uint8 m_FX_FirstState;	// 飞仙状态
    time_t m_FX_SetTime;	// 设置飞仙状态的时间

    const static int MAX_NORMAL_MISS_NUM = 10;

    const static int MD5_RESULT_SIZE    = 16;
	SXiuXianData m_xiuxian[MAX_XIU_XIAN_NUM];

    time_t m_userDoubleEnd;	// 5倍经验时间
    uint16 m_useDoubleType;

    time_t m_pkTime;
	time_t m_multiExpTime;
	uint8 m_NPCState;
	uint16 m_bangArea_killNum;	// 在本帮派领地连续击杀敌人的数量

    uint32 m_tempLeaveTeam;	//暂时离开队伍

    uint8 m_chatChannel;
    const static int MAX_SAVE_NUM = 12;

    uint32 m_shortArray[MAX_SAVE_NUM];
	// 2 师门任务完成次数
	// 3 师门任务跨天标记
    //MAX_SAVE_NUM-2:为更新日期
    //MAX_SAVE_NUM-1,为记录每周一需要更新的变量

    bitset<MAX_BITSET> m_bitset;
	bitset<MAX_STAGE_GOAL_BITSET> m_stageGoalBitSet; // 阶段目标位变量集
    map<int,int> m_intMap;
	list<SNpcInstance> m_npcList;
	list<SNpcInstance> m_collectList;
    list<uint32> m_askForMatchUser;
	list<SVisibleMonster> m_monsterList;

	bool isInit;
	bool isLoadAccountInfo;

	map<uint32, bool> m_isLoadHistory;
	bool m_isLoadJiaoYiHangRecord;
	string m_accountName;
	int m_binding;
	int m_recordPhone;
	string m_personal_id;

	SMount m_mount; // 坐骑
	SWing m_wing;	// 翅膀

	list<string> m_gonggao;

    struct SSavePos
    {
        uint16 sceneId;
        uint16 x;
        uint16 y;
    };
    string m_dropItem;
    boost::recursive_mutex m_mutex;
   	string m_lockPass;
   	string m_strVal;
   	time_t m_delLockPassTime;
	uint16 m_ad;
	int m_serverId;
	string m_netInfo;
	string m_mac;
	string m_IMEI;
	string m_IDFA;
	string m_mobileInfo;
	
	uint64 m_zhanDouLi;
	uint32 m_yaolingZhanDouLi;
	uint16 m_mobileType;
	int m_version;
	bool m_meetEnemy;
	CMultiTreeDoptionNode *m_Doption_root;
	int maxNodeId;
	list<CDoptionCallBack> m_Doption_call;
	int m_OtherTitle;
	list<int> m_scriptOption;
	time_t m_lastFightTime;
	time_t m_clientFightEndTime;
	uint8 m_kuafuState;
	uint32 m_sigId;
	string m_sigStr;
	bool m_checkNpc;

	int m_360_id;
	time_t m_360_expires_in_time; // 不是expires_in,是access_token的有效值
	string m_360_access_token;
	string m_360_refresh_token;

	uint8 m_bossMissionStar[DAILY_BOSS_MAX_NUM];

	string m_fuBenDrop; // 副本掉落
	uint8 m_curFuBenId; // 当前参与的副本id
	time_t m_curFuBenFinishTime; // 当前参与副本的完成时间

	uint16 m_collectIdx; // 当前采集npc索引

	time_t m_lastCheckTitleTime; // 上次校验称号更新时间

	CFishRoom* m_pFishRoom; // 钓鱼房间指针
	uint32 m_lastLoginOutTime;
	uint16 m_celue;	// 策略
	uint8 m_robot;
    uint8 m_vipLevel;
	vector<SFootPrintData> m_footData;

	vector<uint16> m_questionIds;
	
	time_t m_pwoerSynsTime;
	bool m_kuafu_IconState;	// true 显示 false不显示

	CXunBaoManage m_xunBaoManage;
	CEquipManeger m_petEquipMgr;
	vector<SAwardData> m_shilianRandAward;
	map<int,int> m_bangSkills;//帮派技能
	bool m_loginHuoYueSign;//登录活跃处理标识
	CUserGuanQia m_userGuanQia;
	CUserSpirit m_userSpirit;
	UserBook* m_userBook;
	CChouKaManager* m_chouKa;
	CUserBloodFight* m_bloodFight;
	UserShopManager* m_shop;
	
public:
	int m_maxHpAddTmp; // 英雄幻灭城副本临时的血上限提升值
	int m_npcInteractTimeout; // 设置npc交互超时时间
	bool m_isCreatedRole; // 是否是新创建的角色
	
	void UpdatePetAttrInfo( uint8 pos );
	void ClearAllPackage();
	void sendXtmasTreeInfo();

	CXianYuan m_xianyuan; //仙缘
	void LoadXianYuan(char *pStr);	//读档
	void SaveXianYuan(string &str);	//存档
	void MakeXianYuanCardMsg(CNetMessage &msg);
	void MakeXianYuanChapterMsg(CNetMessage &msg);
	void SendAllXianYuanInfo();		//发送仙缘信息
	bool ActiveXianYuanChapter(uint32 chapter_id); //激活章节
	bool DecomposeXianYuanCard(uint32 card_id,uint32 num);//分解卡片
	bool LotteryXianYuanCard(uint8 type,uint8 useYB);	//抽取卡片
	uint32 GetXianYuanValue();
	uint32 AddXianYuanValue(uint32 value);
	uint32 SubXianYuanValue(uint32 value);
	uint32 GetXianYuanCardNum(uint32 card_id);
	uint32 AddXianYuanCard(uint32 card_id,uint32 num);
	uint32 SubXianYuanCard(uint32 card_id,uint32 num);
	int GetXianYuanAttrValue(uint32 attr_type);
	bool isXianYuanActived();
	void MakeXianYuanMarketMsg(CNetMessage &msg);
	
	void GetNextSrcSceneId(uint16 &srcSceneId);

	bool NoticeClientToKuaFuServer();
	bool NoticeClientToGameServer();


	void InitJingJie();
	int GetJingJie();
	void SetJingJie(int jingjieID);
	void ActiveJingJie();
	void SendJingJieInfo();
	void GetJingJieDailyAward();
	void UpgradeJingJie();
	bool ChangeJingJieNameShowState(bool isShow,CNetMessage &msg);
	void MakeJingJieTitleMsg(CNetMessage &msg);

	uint8 GetKuaFu1V1VoteState(uint8 idx);
	void SetKuaFu1V1VoteState(uint8 idx);

	CNewShenQi m_shenqi;
	void InitNewShenQi();
	int GetNewShenQiCarryID();
	void SetNewShenQiCarryID(int shenq_id);
	int GetNewShenQiLevel();
	void SetNewShenQiLevel(int level);
	int GetNewShenQiStar();
	void SetNewShenQiStar(int star);
	int GetNewShenQiExp();
	void SetNewShenQiExp(int exp);
	void InitFromOldShenQi();
	void LoadNewShenQi(char *pStr);	//读档
	void SaveNewShenQi(string &str);	//存档
	bool ActiveNewShenQi(int shenqi_id);
	bool isNewAShenQiActived(int shenqi_id);
	bool AddNewShenQiExp(int exp);
	bool ChangeNewShenQiCarryState(int id);
	bool EnhanceNewShenQi(int item_id,int item_num);
	void SendNewShenQiBaseInfo();
	void MakeNewShenQiBaseInfo(CNetMessage &msg);
	void SendNewShenQiEnhanceInfo();
	void SendNewShenQiActiveInfo(int shenqi_id);
	void ItemActiveNewShenQi(int shenqi_id);

	StKuaFu1vs1SaveEnemyInfo kuaFu1vs1SaveEnemyInfo[5];
	void LoadKuaFu1vs1SaveEnemy(char *pStr);	//读档
	void SaveKuaFu1vs1SaveEnemy(string &str);	//存档	
	bool IsApplyForKuaFu1vs1Preliminary();
	int GetKuaFu1vs1PreliminaryChallengueCDTime();
	void SetKuaFu1vs1PreliminaryChallengueCDTime(int data);
	int GetKuaFu1vs1PreliminaryUsedChallengueNum();
	void SetKuaFu1vs1PreliminaryUsedChallengueNum(int data);
	int GetKuaFu1vs1PreliminaryRefreshHeroNum();
	void SetKuaFu1vs1PreliminaryRefreshHeroNum(int data);
	int GetKuaFu1vs1PreliminarySortID();
	void SetKuaFu1vs1PreliminarySortID(int data);
#ifdef KUA_FU
	void MakeKuaFu1vs1SaveEnemyInfo(CNetMessage &msg);
#endif
	int GetKuaFu1vs1PreliminaryFightEnemySeq();
	void SetKuaFu1vs1PreliminaryFightEnemySeq(int data);
	int GetKuaFu1vs1PreliminaryUsedChallengueTotalNum();
	void SetKuaFu1vs1PreliminaryUsedChallengueTotalNum(int data);
	
	map<int ,StMoneyGiftBagHuoDongInfo> moneyGiftBagHuoDongMap;//key huodong_type
	typedef  map<int ,StMoneyGiftBagHuoDongInfo>::iterator MoneyGiftBagHuoDongMapIter; 
	void LoadMoneyGiftBagHuoDongMap(char *pStr);
	void SaveMoneyGiftBagHuoDongMap(string &str);
	int GetMoneyGiftBagBuyNum(int hd_type,int gift_id);
	void AddMoneyGiftBagBuyNum(int hd_type,int gift_id);
	int GetMoneyGiftBagChargeNum(int hd_type);
	void AddMoneyGiftBagChargeNum(int hd_type,int add_value);

	map<int,int> m_transformCardMap;//变身卡 key:item_id valuer: num
	void SendTransFormCardInfo();
	void SendCurTransFormTimeInfo();
	void SendUpdateTransFormInfo();
	void UseTransFormCard(int item_id,uint8 pos,int num);
	void ClearTransForm();
	bool ActiveTransForm(int item_id); 
	void GetTransFormAttr(StInitAttrInfo &info,bool isForPet = false);
	int GetCurTransFormID();
	void SetCurTransFormID(int item_id);
	int GetCurTranFormEndTime();
	void SetCurTranFormEndTime(int last_time);
	int GetTransFormMonsterID(int item_id);
	void LoadTransFormCard(char *pStr);
	void SaveTransFormCard(string &str);
	void TransFormLeftTimeCheck();
	void GetTransFormDrop();
	bool CoverCurTransFormCheck(int item_id);

	void SetIgnoreVip(uint8 flag);
	bool GetIgnoreVip();
	void SendIgnoreVipInfo();

	void SetIgnoreQieCuo(uint8 type);
	bool GetIgnoreQieCuo();
	void SendIgnoreQieCuoInfo();

	CXunBaoManage& GetXunbaoManage() { return m_xunBaoManage; }
	CEquipManeger& GetPetEquipMgr() { return m_petEquipMgr; }
	void RoleOnlineUpdateRank();
	
	// 推图相关
public:
	CUserGuanQia& GetGuanQia();
	uint8 GetResetCnt() { return 5; }
	// 体力相关
public:
	// 是否有免费体力领取
	bool CheckGetFreeSpiritState();
	CUserSpirit& GetUserSpirit();
	
	// 图鉴
public:
	UserBook* GetUserBook();
	CChouKaManager* GetChouKa();
	CUserBloodFight* GetBloodFight();
	UserShopManager* GetShop();
};

inline void CUser::SetRoleId(uint32 id)
{
    m_roleId = id;
}
inline void CUser::SetPos(uint16 x,uint16 y)
{
    m_xPos = x;
    m_yPos = y;
}
inline uint32 CUser::GetUserId()
{
    return m_userId;
}
inline uint32 CUser::GetRoleId()
{
    return m_roleId;
}
inline void CUser::SetUserId(uint32 id)
{
    m_userId = id;
}

inline uint8 CUser::GetFace()
{
    return m_face;
}
inline void CUser::GetPos(uint16 &x,uint16 &y)
{
    x = m_xPos;
    y = m_yPos;
}
inline CScene *CUser::GetScene()
{
    return m_pScene;
}

inline void CUser::SetSock(int sock)
{
    m_sock = sock;
}
inline int CUser::GetSock()
{
    return m_sock;
}

inline void CUser::SetRole(uint32 *roles)
{
    memcpy(m_role,roles,sizeof(m_role));
}

inline const char *CUser::GetName()
{
    return m_name;
}

inline uint8 CUser::GetSex()
{
    return m_sex;
}

inline uint8 CUser::GetHead()
{
	return m_head;
}

inline uint8 CUser::GetModel()
{
	return m_model;
}

inline void CUser::SetModel(uint8 model)
{
	m_model = model;
}

inline void CUser::SetHead(uint8 head)
{
	m_head = head;
}

inline uint16 CUser::GetX()
{
    return m_xPos;
}
inline uint16 CUser::GetY()
{
    return m_yPos;
}
inline uint16 CUser::GetLevel()
{
    return m_level;
}
inline int64 CUser::GetExp()
{
    return m_exp;
}

inline void CUser::SetSex(uint8 sex)
{
    m_sex = sex;
}

inline void CUser::SetLevel(uint16 level)
{
    m_level = level;
}

inline void CUser::SetExp(int64 exp)
{
    m_exp = exp;
}

inline uint32 CUser::GetStep()
{
    return m_step;
}

inline void CUser::AddStep(int step)
{
    atomic_exchange_and_add((int*)&m_step,step);
}

inline uint32 CUser::GetFightId()
{
    return m_fightId;
}


#endif


