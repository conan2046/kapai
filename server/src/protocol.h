#ifndef _JIANGHU_PROTOCOL_H_
#define _JIANGHU_PROTOCOL_H_

#include "self_typedef.h"

const uint8 PRO_ERROR         = 0;
const uint8 PRO_SUCCESS       = 1;

//性别
const uint8 GENDER_MALE     = 0;
const uint8 GENDER_FEMALE   = 1;

//向性
const uint8 XIANG_JIN       = 1;
const uint8 XIANG_MU        = 2;
const uint8 XIANG_SHUI      = 3;
const uint8 XIANG_HUO       = 4;
const uint8 XIANG_TU        = 5;

//最大角色数
const int MAX_ROLE_NUM      = 1;

//最大用户数
const int MAX_CON_USER      = 4096;

//协议命令字
const int PRO_USER_LOGIN    = 1001;
const int PRO_ROLE_NAME_CHECK = 1002;
const int PRO_CREATE_ROLE   = 1003;
const int PRO_SELECT_ROLE   = 1004;
const int PRO_NPC_LIST      = 5;
const int PRO_USER_LIST     = 6;

const int PRO_ROLE_PACKAGE  = 8;
const int PRO_ROLE_MOVE     = 9;
const int PRO_JUMP_SCENE    = 10;
const int PRO_IN_OUT_SCENE  = 11;
const int PRO_OPEN_INTERACT = 12;

//30神将仓库,神将信息
//31师徒榜,(byte)数量 roleid(int) name(char*) 门派（byte） sex（byte）level（byte）可收徒弟数（byte）
//32 输入两个字符串，内容要匹配
const int PRO_INTERACT      = 13;

const int PRO_CLOSE_INTERACT    = 14;

//0 丢弃，1使用 2 移动 3 绑定 4 锁定 5 解锁 6 整理 7 卖出
const int PRO_UPDATE_PACK   = 15;		// return back op = 1 addItem, op = 2 updateItem or deleteItem

const int PRO_GET_ITEM_INFO = 16;

const int PRO_UPDATE_CHAR   = 18;

const int PRO_OTHER_ITEM_INFO = 19;	//查询其他玩家物品信息

const int PRO_IGNORE_DIALOG = 20;	// 跳过剧情对话

const int PRO_ENTER_BATTLE  = 21;	//进入战斗
const int PRO_BATTLE        = 22;	//战斗过程
const int PRO_BATTLE_OVER   = 23;	//战斗结束

const int PRO_PET = 24;	// 神将相关操作

const int PRO_UPDATE_PET    = 25;	//客户端神将操作，服务器端更新神将列表

const int PRO_MSG_CHAT      = 26;	//聊天

const int PRO_Friend = 27;			// 好友协议

const int PRO_USER_TEAM     = 29;	// 队伍

const int PRO_UPDATE_TEAM   = 30;	//更新队伍

const int PRO_SYS_INFO      = 31;	//系统消息

const int PRO_USER_PK       = 32;	//玩家pk

const int PRO_PLYAER_MATCH  = 33;	//玩家切磋

const int PRO_PLAYER_INFO   = 34;	//查询玩家信息

const int PRO_NEAR_PLAYER_LIST = 35;//附近玩家列表

const int PRO_UPDATE_PLAYER = 36;	//更新玩家状态

const int PRO_TASK_LIST     = 37;	//任务列表

const int PRO_FIGHT_OPTION = 38;	// 战斗相关(跳过战斗, 战斗回放)

const int PRO_UPDATE_TASK   = 39;	//更新任务

const int PRO_PET_SKILL     = 40;

const int PRO_UPDATE_PET_SKILL = 41;//更新神将技能

const int PRO_HOT_ONLINE    = 45;	//好友上下线通知

const int PRO_CHONG_ZHI = 46;		// 充值界面信息

const int PRO_USE_ITEM = 47;		// 使用道具，带字符串

const int PRO_ZHEN_FA = 48;	// 阵法

const int PRO_FINISHED_MISSION = 49;	// 获取完成任务列表

const int PRO_QUERY_PET_INFO = 51;	// 请求玩家单个宠物数据

const int PRO_FIND_RESOURCE = 52;	// 资源找回

const int PRO_FENGSHEN_SHILIAN = 53;	// 封神试炼

const int PRO_BANGPAI = 54;	//帮派

const int PRO_YAO_LING = 55;	// 妖灵属性

const int PRO_BANG_ZHAN = 56;	// 帮战

const int PRO_UPDTAE_HP_IN_FIGHT = 57;	// 战斗内血量更新

const int PRO_UPDATE_NPC = 58;

const int PRO_ADD_NPC = 59;		//添加npc

const int PRO_DEL_NPC = 60;		//del npc

const int PRO_SYNC_POS  = 61;	//同步角色位置

const int PRO_SYSTEM_INFO  = 62;//系统消息

const int PRO_SCENE_SYSTEM_INFO = 63;//场景系统消息

const int PRO_BANGPAI_COPY = 64;	// 帮派副本

const int PRO_Func_HotPoint = 65;	// 各功能小红点

const int PRO_SKILL_DESC = 68;		//查询技能描述

const int PRO_OTHER_PET = 69;		//查询玩家神将

const int PRO_UPDATE_PET_INFO = 70;	//更新神将信息

const int PRO_SWITCH_CHANNEL = 73;	//开关聊天频道

const int PRO_SWITCH_INFO = 74;		//查询聊天通道是否关闭

const int PRO_SYS_POP_MSG = 75;		//系统弹出消息

const int PRO_SERVER_UPDATE_EQUIP = 77;	//更新装备

const int PRO_PSHOP_SOLD    = 79;//购买物品，给卖出着放松更新消息

const int PRO_MY_BANG       = 80;//我的帮派

const int PRO_CHANGE_FACE   = 81;//更新角色方向

const int PRO_ITEM_DESC = 83;	//物品描述

const int PRO_CHARGE = 84;		//客户端充值

const int PRO_GONGGAO   = 88;	//系统公告

const int PRO_AVAILABLE_TASK = 89;//可接任务

const int PRO_SCENE_POS = 90;	//脱离卡死坐标

const int PRO_SERVER_VERSION = 91;

const int PRO_SPEC_CHAT = 92;

const int MSG_SERVER_MONSTER = 96;		//场景明怪

const int MSG_SERVER_ADD_MONSTER = 97;	//增加明怪

const int MSG_SERVER_REMOVE_MONSTER = 98;	//删除明怪

const int MSG_CLIENT_MONSTER_BATTLE = 99;	//明怪战斗

const int MSG_QUERY_SCENE   = 100;		//获取场景文件

const int MSG_CLIENT_ITEM_DEF = 101;

const int MSG_SERVER_HEART_BEAT = 102;	// 心跳包

const int PRO_CHAT_CHANNEL = 103;	// 系统信息发送聊天频道

const int PRO_GET_TITLE_LIST = 105;

const int PRO_TITLE_OPTION = 106;

const int MSG_SERVER_JUMP_POINT = 107;

const int MSG_BANGPAI_ZHONGZHI = 110;

const int MSG_SERVER_ADD_OBJECT = 111;

const int MSG_SERVER_UPDATE_OBJECT = 112;

const int MSG_SERVER_REMOVE_OBJECT = 113;

const int MSG_SERVER_USE_RESULT = 115;

const int MSG_CLIENT_LIST_FUQI = 117;

const int MSG_SERVER_VISUAL_EFFECT = 119;

const int MSG_CLIENT_DEL_CHAR = 118;

const int MSG_SERVER_NPC_MOVE = 125;

const int MSG_SERVER_NPC_EFFECT = 126;

const int MSG_SERVER_NPC_SAY = 127;

const int MSG_SERVER_XINSHI = 128;

const int MSG_SERVER_LIST_SKILL = 129;

const int GUANZHAN_ENTER_BATTLE  = 133;	// 观战进入战斗
const int LEAVE_GUANZHAN = 134;			// 退出观战
const int ENTER_GUANZHAN = 135;			// 观战战斗开始
const int GUAGNZHAN_BATTLE        = 136;// 观战战斗过程
const int GUANGZHAN_BATTLE_OVER   = 137;// 观战战斗结束

//师徒榜玩家信息
//客户端发送内容(byte)0师傅榜，1徒弟榜
//服务器返回(char*)info,文字中|做为换行符
const int MSG_SHI_TU_USER_INFO = 142;

//客户端需要保存数据
//(byte)ind (int)val
const int MSG_CLIENT_SAVE_VAL = 145;

//客户端得到保存的数据
//客户端发送(byte)ind
//服务器返回(byte)ind (int)val
const int MSG_CLIENT_GET_SAVE_VAL = 146;

const int MSG_NPC_POS = 148;

const int MSG_HUODONG = 152;
const int MSG_YINDAO = 153;
const int MSG_GUAJI = 154;

const int MSG_JUMP_POINT = 158;
const int MSG_CLIENT_JUMP = 159;

const int MSG_XIU_XIAN_LI_LIAN = 160;	// 修仙历练

const int MSG_ARENA = 161;
const int MSG_ARENA_VIDIO_START = 162;
const int MSG_ARENA_VIDIO = 163;
const int MSG_ARENA_VIDIO_STOP = 164;
const int MSG_DOPTION_CALLBACK = 168;	//Doption回调

const int MSG_CLIENT_NET_CHECK = 175;	// client ping检测

const int MSG_GOOGLEPLAY = 176;			//googleplay

const int MSG_CLIENT_CALLBACK_FROM_SHOP = 177;	// client商城回调
const int MSG_GET_360_TOKEN = 178;		// 获取360token

const int MSG_WING = 180;		// 翅膀

const int MSG_CHANGE_PASSWORD = 181;	// 修改密码

const int MSG_TASK_TRACK = 182;		// 任务追踪
const int MSG_MONSTER_MOVE = 183;	// 明怪
const int MSG_MONSTER_OPTION = 184;	// op 1 list 2 add 3 delete

const int MSG_MOUNT = 185;			// 坐骑

const int MSG_NPC_AUTO_TRANSPORT = 189;	// NPC自动传送
const int MSG_FUBEN_OPTION = 190;		// 副本

const int MSG_XINSHOUYINDAO = 191;		// 新手引导
const int MSG_HE_CHENG_OPTION = 192;	// 装备合成,升级

const int MSG_USER_RANK = 193;			// 排行榜
const int MSG_USER_PACKAGE_ITEM = 194;	// 其他玩家背包物品
const int MSG_WORLD_MAP_TRANSPORT = 195;// 大地图世界传送

const int MSG_PACKAGE_OPTION = 197;	// 15号协议返回

const int MSG_ANSWER_QUESION = 198; // 答题活动

const int MSG_HUODONG_OPTION = 199;	// 活动，百花仙子

const int MSG_OPEN_PACKAGE_OPTION = 200;	// 背包开启

const int PRO_PLAYER_DETAIL = 201;	// 查看玩家信息

const int MSG_FUBEN_DROP = 203; 	// 副本掉落

const int MSG_MEET_MONSTER = 204;	// 遇怪开关

const int MSG_FIRST_LOGIN_PANEL = 205;	// 角色第一次登陆提示

const int MSG_SYNC_TIME = 206;		// 客户端同步获取服务器时间

const int PRO_SYS_INFO_RIGHT_DOWN = 207; // 系统信息 右下角

const int MSG_HELP = 208;		// 帮助

const int MSG_DAILY_ACTIVITY = 209;		// 玩法
const int MSG_FIGHT_END_MSG = 210;		// 战斗结束后的提示信息

const int MSG_PLAY_ANIMATION = 211;		// 播放动画

const int MSG_CHUANG_GUAN = 213;	// 多人闯关

const int MSG_TONG_TIAN_TA = 214;	// 通天塔霸主显示, 1添加,2更新

const int MSG_GET_CHARGE_ORDER = 216;// 获得服务器生成的充值订单号

const int MSG_FISH = 217;		// 钓鱼

const int MSG_OFFLINE_EXP  = 219;	// 离线经验

const int MSG_VIP_OPTION = 220;	// VIP功能

const int MSG_SHOP = 221;		// 商城功能

const int MSG_TMP_HUODONG = 222;// 临时活动，开服活动等

const int MSG_STAGE_GOAL = 223;	// 阶段目标

const int MSG_PET_RANDOM_DRAW = 224;	//随机抽神将

const int MSG_DailyBoss_TASK = 225;		// 每日Boss任务

const int MSG_UPDATE_USER_LEVELUP_INFO = 226;	// 更新角色升级信息(等级，战斗力)

const int MSG_ANTI_ADDICTION = 227;		// 防沉迷

const int MSG_LEI_TAI_SAI = 228;		// 擂台赛

const int MSG_HU_SONG = 229;			// 护送任务

const int MSG_MULTI_EXP_TIME = 230;		// 5倍经验持续时间

const int MSG_PUSH_CLIENT_INFO = 231;	// 推送活动信息

const int MSG_CAI_QUAN = 232;			// 猜拳活动

const int MSG_GET_SERVER_ID = 233;		// 获取充值serverId

const int MSG_NOTICE_TO_UPDATE_CLIENTDATA = 234;	// 通知客户端重新获取数据24点更新

const int MSG_CHONGZHI_RET = 235;		// 充值返回数据

const int MSG_PET_CARTOON = 236;		// 播放获得神将动画

const int MSG_FIGHT_END_PUSH_MSG = 237;	// 战斗失败推送信息

const int MSG_USER_MSG_TO_WORLD = 238;	// 玩家公告缓存，客户端请求再公告

const int MSG_MOBAI = 239;		// 膜拜

const int MSG_CHANGE_GUAJI_STATE = 240;	// 更改客户端挂机状态

const int MSG_PET_COPY = 243;		// 神将副本界面协议，无限刷怪

const int MSG_TREASURE_MAP = 244;	// 藏宝图

const int MSG_SHI_LIAN = 245;	// 英勇试炼

const int MSG_FEI_XIAN = 246;	// 飞仙战场

const int MSG_CILENT_CHARGE = 247;	// 通知客户端充值结果

const int MSG_QUERY_ROLE_BY_NAME = 248;	// 通过角色名或ID获取角色信息,好友，黑名单

const int MSG_GET_WORLD_LEVEL = 249; //  获取世界等级信息

const int MSG_JUMP_NOTICE = 250;	// 道具，元宝，金币等不足跳转

const int MSG_HUODONG_HOTPOINT = 251;   //活动小红点信息推送

const int MSG_KUN_LUN_SHAN_TEAM = 253;	// 组队昆仑山(跨服)

const int MSG_SYSTEM_INFO = 254; // 滚动系统公告

const int MSG_KUA_FU_1V1 = 255;	// 跨服1v1

const int MSG_SHENJIE_MIJING = 256; //神界秘境

const int MSG_KOREA_MONEY_GIFT = 257;	//韩版直购

const int MSG_LINGSHOU	= 258;//灵兽功能，不用了

const int MSG_TRANSFORM = 259;	//变身功能

//const int MSG_ZHUZHAN_PET = 260;    //神将助战  弃用

const int MSG_IGNORE_QIECUO = 261;	//屏蔽切磋

const int MSG_PK_NOTICE = 262;	// pk提示

const int MSG_IGNORE_FUNC = 263;	// 屏蔽功能


const int MSG_MEIRI_SHOUCHONG = 300;   //每日首充推送消息

const int MSG_CLIENT_CONFIG_FILE = 301;	// 推送客户端配置文件信息


const int MSG_XTMAS_TREE = 303;	//圣诞树图标

const int MSG_STOP_PROGRESSBAR = 304;	//中断进度条

const int MSG_XIANYUAN = 305;	//六界仙缘

const int MSG_JINGJIE = 306;	//境界

const int MSG_NEW_SHENQI = 307;	//新神器

const int MSG_DEL_ACCOUNT = 308;	//删除账号

const int MSG_CHONGZHI_TO_OTHER = 309;	// 给朋友充值

const int MSG_WEIXIN_SHARE_REWARD = 310;	// 发送每天微信分享奖励

const int MSG_QUNXIANZHENGBA = 311;		// 群仙争霸

const int MSG_MIANZHANPAI_TIME = 312;		// 获取免战牌CD时间

const int MSG_JIAOYI_HANG = 313;		// 交易行

const int MSG_FLOWER = 314;		// 鲜花

const int MSG_SPECIAL_CARTOON = 315;	// 特效

const int MSG_HUODONG_PAIHANG = 316;	// 活动排行榜
const int MSG_SERVER_NOTICE = 318;      // 服务器通知

const int PET_EQUIP_OPERATE = 319;      //宠物装备

const int MSG_GUANQIA = 320;      // 关卡
const int MSG_SPIRIT = 321;       // 体力
const int MSG_HERO_BOOK = 322;       // 图鉴
const int MSG_BLOOD_FIGHT = 323;       // 血战



const int MSG_REAL_NAME_REG = 330;	// 实名制和绑定账号
const int MSG_CLIENT_STRING_DATA_OPRATETION = 331;	// 客户端数据存储
const int MSG_CLIENT_GETMISSIONAWARD = 332;	// 前端领取任务奖励

const int MSG_KUAFU_ICON = 333;	// 跨服图标显示

const int MSG_QUERY_KF_STATE = 334;	// 请求跨服状态
const int MSG_YOU_LI = 335;	// 游历三界
const int MSG_JIJIN = 336;	// 基金


const int MSG_KUA_FU = 400;	// 跨服
const int MSG_SERVER_KF_BANG_PAI = 401;	// 跨服请求帮派信息
const int MSG_SERVER_SYSINFO = 402;		// 跨服发送滚动信息
const int MSG_SERVER_KF_BANGZHAN_INFO = 403;	// 跨服帮战

const int PRO_SERVER_QUERY_ONLINE_NUM = 601;	// 请求在线人数

// 测试协议号
const int PRO_CLIENT_TEST = 4000;	// 客户端测试网络包协议


// 服务器消息
const int PRO_SERVER_SAVE_PET = 10000;
const int MSG_SERVER_RANK = 10001;
const int MSG_SERVER_TONGTIANTA = 10002;
const int MSG_SERVER_SAVE_USE_ITEM = 10003;
const int MSG_SERVER_SAVE_BUY_ITEM = 10004;
const int MSG_SERVER_SERVER_XINSHI = 10005;
const int MSG_SERVER_ARENA = 10006;
const int MSG_SERVER_ROLE_NAME = 10009;
const int MSG_SERVER_SAVE_DATA = 10010;

const int MSG_SERVER_QUERY_SQL = 10020;
const int MSG_SERVER_QUERY_SQL_ALL_DB = 10021;

const int MSG_SERVER_USER_POWER = 10022; // 同步玩家战力

const int MSG_SERVER_FORWARD = 10023; // 转发


#ifdef KUA_FU
const int MSG_KF_LOGIN = 20001;
const int MSG_KF_LOGOUT = 20002;
#endif

const int MSG_MGR = 0xfffe;

#endif

