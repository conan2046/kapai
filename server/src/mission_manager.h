#ifndef _MISSION_MANAGER_H_
#define _MISSION_MANAGER_H_

#include <iostream>
#include <list>
#include <vector>
#include <map>
#include <boost/thread.hpp>
#include <boost/unordered_map.hpp>
#include "utility.h"
#include "self_typedef.h"

using namespace std;

class CUser;

const int MISSION_ID_ZhuoGui = 100;
const int MISSION_ID_ShiMen = 101;
const int MISSION_ID_XunBao = 102;
const int MISSION_ID_DanYuan = 103;
const int MISSION_ID_ShaDiDuoBao = 104;
const int MISSION_ID_HuSong = 105;
const int MISSION_ID_ZhouRiChang = 106;
const int MISSION_ID_KuaFuShilian = 10001;
const int MISSION_IDS_BangPai[4] = {321,322,323,324};
const int MISSION_MAX_CNT_KuaFuShilian = 5;
const int MISSION_NPC_XunBao = 300;

enum EMissionType
{
	EMISS_TYPE_MAIN = 1,
	EMISS_TYPE_BRANCH = 2,	
	EMISS_TYPE_DAILY = 3,
	EMISS_TYPE_KUAFU_DAILY = 4,
};

enum EMissionSubType
{
	EMISS_STYPE_ShiMen = 1,
	EMISS_STYPE_YunBiao = 2,
	EMISS_STYPE_CangBaoTu = 3,
	EMISS_STYPE_ShaDiDuoBao = 4,
	EMISS_STYPE_ZhuoGui = 5,
	EMISS_STYPE_DanYuan = 6,
	EMISS_STYPE_HuSongShenJiang = 7,
	EMISS_STYPE_Mubiao = 8,
	EMISS_STYPE_KuaFuRiChang = 9,
	EMISS_YueKaTiYan = 10,
};

enum EMissionStateType
{
	EMISS_STATE_ACCEPT = 0,
	EMISS_STATE_FINISH = 1,
	EMISS_STATE_AWARD = 2,
};

enum EMissionAutoType
{
	EMISS_AUTO_NONE = 0,
	EMISS_AUTO_ACCEPT = 1,
};

enum EMissionFinishType
{
	EMISS_FINISH_NONE = 0,
	EMISS_FINISH_AUTO = 1,
};

enum EMissionAutoRunType
{
	EMISS_RUN_NONE = 0,
	EMISS_RUN_AUTO = 1,	// 自动寻路
};

enum EMissionToDoType
{
	EMISS_TD_ADD_NPC = 1,
	EMISS_TD_DEL_NPC = 2,
	EMISS_TD_ADD_COLLECT = 3,
	EMISS_TD_DEL_COLLECT = 4,
	EMISS_TD_TRANSPORT = 5,
	EMISS_TD_ADDTESTCARD = 6,  // 体验月卡
};

enum EMissionTargetType
{
	EMISS_TT_NPC = 0,	// npc寻路
	EMISS_TT_MONSTER = 1,	// 怪物寻路
	EMISS_TT_PANCL = 2,	// 打开面板
	EMISS_TT_AWARD = 3,	// 任务完成 主动领奖
	EMISS_TT_ROLE = 4,	// 玩家
};


enum EMissionDoingContentType
{
	EMISS_DC_DIALOG = 1,
	EMISS_DC_KILL_MONSTER = 2,
	EMISS_DC_MONSTER_DROP = 3,
	EMISS_DC_BUY_ITEM = 4,
	EMISS_DC_KILL_BOSS = 5,
	EMISS_DC_COLLECT = 6,
	EMISS_DC_COPY = 7,
	
	EMISS_DC_8 = 8,   //  通关寻神将任务类型：8-fubenid（寻神将副本id）-num（通关副本次数）
	EMISS_DC_9 = 9,   //  神将招募任务类型：9-num（神将招募次数）
	EMISS_DC_10 = 10, //  猜拳玩法任务：10-1
	EMISS_DC_16 = 16, //  世界频道发言x次：16-num（次数）
	EMISS_DC_17 = 17, //  添加x个好友：17-num（好友数）
	EMISS_DC_18 = 18, //  加入帮派：18-1
	EMISS_DC_19 = 19, //  完成x个帮派活动：19-x
	EMISS_DC_21 = 21, //  升级x个神将至x级：21-num（神将数量）-level（神将等级）
	EMISS_DC_22 = 22, //  x个神将技能提升至x级：22-num（神将技能数量）-level（技能等级）
	EMISS_DC_23 = 23, //  x个神将血脉修炼至x级：23-num（神将血脉数量）-level（修炼等级）
	EMISS_DC_24 = 24, //  任意神将升星x次：24-num
	EMISS_DC_25 = 25, //  x个人物技能提升至x级：25-num（技能数量）-level（技能等级）
	EMISS_DC_26 = 26, //  x件装备升阶至x级：26-num（装备数量）-level（装备等级）
	EMISS_DC_27 = 27, //  x件装备强化至x级：27-num（装备数量）-level（强化等级）
	EMISS_DC_28 = 28, //  装备淬炼x次：28-num
	EMISS_DC_29 = 29, //  装备洗炼x次：29-num
	EMISS_DC_30 = 30, //  挑战竞技场x：30-num
	EMISS_DC_31 = 31, //  灵气捐献x次：31-num
	EMISS_DC_32 = 32, //  参与多人闯关：32-1
	EMISS_DC_33 = 33, //  通关通天塔至x层：33-num（层数）
	EMISS_DC_34 = 34, //  挑战x次日常boss：34-num（次数）
	EMISS_DC_35 = 35, //  参与六界巡查使：35-1
	EMISS_DC_36 = 36, //  参与英勇试炼：36-1
	EMISS_DC_37 = 37, //  参与修仙历练：37-1
	EMISS_DC_38 = 38, //  x个神将升至x星：24-num（神将数量）-star（星数)
	EMISS_DC_39 = 39, // 捉妖 x 次
	EMISS_DC_40 = 40, // 获得坐骑
	EMISS_DC_41 = 41, // 坐骑强化到 x 级
	EMISS_DC_42 = 42, // 获得神器 x
	EMISS_DC_43 = 43, // 培养羽翼到 x 阶段
	EMISS_DC_44 = 44, // 完成x次宝图任务 
	EMISS_DC_45 = 45, // 使用x次藏宝图
	EMISS_DC_46 = 46, // 使用x次高级藏宝图
	EMISS_DC_47 = 47, // 学习天书技能x次
	EMISS_DC_48 = 48, // 护送神将x次
	EMISS_DC_49 = 49, // 英勇试炼击败第X关守护者
	EMISS_DC_51 = 51, // 膜拜强者x次
	EMISS_DC_52 = 52, // 培养过羽翼
	EMISS_DC_53 = 53, // 开启x次背包
	EMISS_DC_54 = 54, // 帮派捐献
	EMISS_DC_55 = 55, // 帮派种植
	EMISS_DC_56 = 56, // 普通祈福
	EMISS_DC_57 = 57, // 元宝祈福
	EMISS_DC_58 = 58, // 摇钱树
	EMISS_DC_59 = 59, // 完成x次y任务
	EMISS_DC_60 = 60, // 出战x个神将
	EMISS_DC_61 = 61, // 购买物品引导（不用考虑之前购买的）
	EMISS_DC_62 = 62, // 参加过答题活动
	EMISS_DC_63 = 63, // 提升x次神将血脉
	EMISS_DC_64 = 64, // x个装备符文提升到x星
	EMISS_DC_65 = 65, // 装备洗练获x个x星以上属性（保存到身上才算）
	// add at 20190308
	EMISS_DC_66 = 66, // 角色达到x战斗力
	EMISS_DC_67 = 67, // 角色击杀的怪物数量达到x
	EMISS_DC_68 = 68, // 角色拥有x个y品质以上神将
	//EMISS_DC_69 = 69, // 今日活跃度超过x点
	EMISS_DC_70 = 70, // 累计充值超过x元
	EMISS_DC_71 = 71, // x个阵法等级超过y级别
	EMISS_DC_72 = 72, // 购买任意成长基金
	EMISS_DC_73 = 73, // x神将的战力超过y点
	EMISS_DC_74 = 74, // 挑战过封神试炼
	EMISS_DC_75 = 75, // 当前穿戴x件宠装
	EMISS_DC_76 = 76, // 当前穿戴x套y件宠装
	EMISS_DC_77 = 77, // 神将装备强化1次
	EMISS_DC_78 = 78, // 神将装备x件强化超过y级
	EMISS_DC_79 = 79, // 分解x件神将装备
	EMISS_DC_80 = 80, // 获得神将x
	EMISS_DC_81 = 81, // 领取指定天的登录奖励
};

enum EMissionNpcActType
{
	EMISS_ACT_NOR_DIALOG = 1,	// 普通对话
	EMISS_ACT_WIN_DIALOG = 2,	// 战斗胜利对话
	EMISS_ACT_FAIL_DIALOG = 3,	// 战斗失败对话
	EMISS_ACT_FIGHT = 4,
	EMISS_ACT_ITEM = 5,
	EMISS_ACT_COLLECT = 6,
};

enum EMQuestCondType
{
	EMQCT_1 = 1, //体力丹购买数量	1
	EMQCT_2 = 2, //招募次数（包括3种类型招募）	2
	EMQCT_3 = 3, //血战战斗次数	3
	EMQCT_4 = 4, //每日登录游戏	4
	EMQCT_5 = 5, //赠送好友体力次数	5
	EMQCT_6 = 6, //帮派捐献次数	6
	EMQCT_7 = 7, //装备强化次数	7
	EMQCT_8 = 8, //装备精炼次数	8
	EMQCT_9 = 9, //竞技场挑战次数	9
	EMQCT_10 = 10, //游历三界次数	10
	EMQCT_11 = 11, //法宝强化次数	11
	EMQCT_12 = 12, //封神列传次数	12
	EMQCT_13 = 13, //主线战斗胜利次数	13
	EMQCT_14 = 14, //搜索法宝次数	14
	EMQCT_16 = 16, //主线副本总星数	16
	EMQCT_17 = 17, //支线副本总星数	17
	EMQCT_18 = 18, //将魂商店刷新总次数	18
	EMQCT_19 = 19, //N个神将等级	19
	EMQCT_20 = 20, //N个神将突破等级	20
	EMQCT_21 = 21, //N个神将星级	21
	EMQCT_22 = 22, //N个神将修炼重数	22
	EMQCT_23 = 23, //N个神将专属淬炼等级	23
	EMQCT_24 = 24, //N个神将专属重铸等级	24
	EMQCT_25 = 25, //N个神将战力	25
	EMQCT_26 = 26, //N个紫色以上装备强化等级	26
	EMQCT_27 = 27, //N个紫色以上装备精炼等级	27
	EMQCT_28 = 28, //N个紫色以上法宝强化等级	28
	EMQCT_29 = 29, //N个紫色法宝精炼等级	29
	EMQCT_30 = 30, //主角等级	30
	EMQCT_31 = 31, //VIP等级	31
	EMQCT_32 = 32, //游历三界总时长	32
	EMQCT_33 = 33, //血战最高关卡数	33
	EMQCT_34 = 34, //累计法宝合成次数	34
	EMQCT_35 = 35, //每日法宝合成次数	35
	EMQCT_36 = 36, //累计寻宝次数	36
	EMQCT_37 = 37, //服务器开启N天内登陆过游戏
	EMQCT_38 = 38, //活动期间累计充值达到N元
	EMQCT_39 = 39, //每日活跃度值
	EMQCT_40 = 40, //主线通关某关
	EMQCT_41 = 41, //N个橙色弟子上阵
	EMQCT_42 = 42, //上阵角色24件装备强化到N级
	EMQCT_43 = 43, //竞技场排名达到N名
	EMQCT_44 = 44, //血战单次最高星数
	EMQCT_45 = 45, //上阵角色24件装备精炼达到N级
	EMQCT_46 = 46, //合成紫色法宝次数
	EMQCT_47 = 47, //法宝强化等级
	EMQCT_48 = 48, //上阵角色12本法宝强化等级
	EMQCT_49 = 49, //上阵角色12本法宝精炼等级
	EMQCT_50 = 50, //激活图鉴数量
	EMQCT_51 = 51, //激活橙色图鉴数量
	EMQCT_52 = 52, //图鉴值达到某值
	EMQCT_53 = 53, //图鉴星级
	EMQCT_54 = 54, //七日目标任务完成数量
	EMQCT_55 = 55, //封神试炼挑战次数
	EMQCT_56 = 56, //决战昆仑战斗次数 = 次数
	EMQCT_57 = 57, //总战力达到多少
	EMQCT_59 = 59, //加入或建立一个帮派
	EMQCT_60 = 60, //帮派副本挑战次数
	EMQCT_61 = 61, // 购买后登录天数
};

struct SAcceptNpcInfo
{
	SAcceptNpcInfo()
	{
		npcId = 0;
		sceneId = 0;
		posX = 0;
		posY = 0;
	}
	int npcId;
	int sceneId;
	int posX;
	int posY;
};

struct SMissionTodo
{
	SMissionTodo()
	{
		op = 0;
		sceneId = 0;
		posX = 0;
		posY = 0;
		npcId = 0;
		npcIdx = 0;
		direct = 0;
		itemId = 0;
		itemNum = 0;
	}
	int op;
	int sceneId;
	int posX;
	int posY;
	int npcId;
	int npcIdx;
	int direct;
	int itemId;
	int itemNum;
};

struct SMissionDoingContent
{
	SMissionDoingContent()
	{
		op = 0;
		sceneId = 0;
		posX = 0;
		posY = 0;
		npcId = 0;
		dialogId = 0;
		monsterId = 0;
		monsterNum = 0;
		dropRatio = 0;
		itemId = 0;
		itemNum = 0;
		fightId = 0;
		fightPreDialogId = 0;
		fightWinDialogId = 0;
		fightFailDialogId = 0;
		fightRound = 0;
		copyId = 0;
		copyCompleteNum = 0;
		isum = 0;
		level = 0;
		star = 0;
		collectPic = 0;
		collectStr.clear();
	}

	int op;
	int sceneId;
	int posX;
	int posY;
	
	int npcId;
	int dialogId;

	int monsterId;
	int monsterNum;
	
	int dropRatio;
	int itemId;
	int itemNum;

	int fightId;
	int fightPreDialogId;
	int fightWinDialogId;
	int fightFailDialogId;
	int fightRound;

	int copyId;
	int copyCompleteNum;

	int isum;  // 和数要求
	int level; // 级数要求
	int star;  // 星数要求

	int collectPic;
	string collectStr;
};

struct SMissionConfig
{
	SMissionConfig()
	{
		id = 0;
		accept_from_script = 0;
		type = 0;
		sub_type = 0;
		profession_limit = 0;
		sex_limit = 0;
		min_level = 0;
		max_level = 0;

		accept_auto = 0;
		accept_autorun = 0;
		accept_dialog = 0;
		day_finish_times_limit = 0;
		weight = 0;
		finish_auto = 0;
		open_panel_id = 0;
		open_panel_page = 0;
		open_panel_index = 0;
	}

	int id;
	int accept_from_script;	// 0 非脚本 1 脚本接取
	int type;		// 1 主线 2 支线 3 日常
	int sub_type;	// 1 师门 2 运镖 3 藏宝图 4 杀敌夺宝 5 捉鬼
	int profession_limit;	// 0 无限制 > 0 对应职业
	int sex_limit;	// 0 无限制 1 男 2 女
	int min_level;	// 最低接取等级
	int max_level;	// 最高接取等级
	string name;
	vector<int> preMissionId;	// 前置任务id
	
	uint8 accept_auto;		// 0 不自动接取 1自动接取
	uint8 accept_autorun;	// 接取后是否自动寻路 0不寻路 1寻路
	int accept_dialog;		// 对话id
	int day_finish_times_limit;	// 日常任务每日次数限制
	int weight;				// 日常任务随机权重
	SAcceptNpcInfo accept_npc;
	vector<SMissionTodo> accept_todo;
	string accept_desc;
	
	SMissionDoingContent doing_content;
	string doing_desc;
	int open_panel_id;
	int open_panel_page;
	int open_panel_index;

	vector<SMissionTodo> finish_todo;
	uint8 finish_auto;	// 0 不自动完成 1 自动完成
	
	vector<SAwardData> reward1;	// 奖励
	vector<SAwardData> reward2;	// 奖励
};

struct QuestCfg
{
	QuestCfg()
		: id(0)
		, type(0)
		, hdcnd(0)
		, preId(0)
		, num(0)
		, cond(0)
		, condex(0)
	{
		awards.clear();
		nextIds.clear();
	}
	uint16 id;
	uint16 qtype;
	uint16 type;
	uint16 hdcnd;
	uint16 preId;
	uint16 level;
	uint32 num;
	uint32 cond;
	uint32 condex;
	MultiAward awards;
	vector<uint16> nextIds;
};

typedef map<uint16, QuestCfg> QuestCfgMap;
typedef map<uint16, QuestCfg>::iterator QuestCfgMapIt;
typedef map<uint8, QuestCfgMap> TypeQuestCfgMap;
typedef map<uint8, QuestCfgMap>::iterator TypeQuestCfgMapIt;
typedef map<uint8, vector<TypeValue> > CondTypeIdMap;
typedef map<uint8, vector<TypeValue> >::iterator CondTypeIdMapIt;
typedef map<uint8, vector<uint16> > NextQuestMap;
typedef map<uint8, vector<uint16> >::iterator NextQuestMapIt;

struct UserQuest
{
	UserQuest()
		: id(0)
		, num(0)
		, state(0)
		, show(false)
	{

	}
	uint16 id;
	uint32 num;
	uint8 state;
	bool show;
};

struct HuoDongQuest : public UserQuest
{
	uint16 hdId;
	uint16 cond;
};
typedef map<uint16, UserQuest> UserQuestMap;
typedef map<uint16, UserQuest>::iterator UserQuestMapIt;
typedef map<uint8, UserQuestMap> TypeUserQuestMap;
typedef map<uint8, UserQuestMap>::iterator TypeUserQuestMapIt;


typedef map<uint16, HuoDongQuest> HuoDongQuestMap;
typedef map<uint16, HuoDongQuest>::iterator HuoDongQuestMapIt;
typedef map<uint8, HuoDongQuestMap> TypeHuoDongQuestMap;
typedef map<uint8, HuoDongQuestMap>::iterator TypeHuoDongQuestMapIt;

struct SMissionDialog
{
	SMissionDialog()
	{
		id = 0;
		order = 0;
		npcId = 0;
		position = 0;
		scale = 0;
		speed = 0;
		delay = 0;
		showskip = 0;
	}

	int id;
	int order;
	int npcId;
	int position;
	int scale;
	int speed;	// 字播放速度, ms
	int delay;	// 切换下一个对话延时, ms
	int showskip;	// 0不显示跳过 1跳过
	string content;
};

struct SAcceptMission
{
	SAcceptMission()
	{
		missId = 0;
		state = 0;
		time = 0;
		save_var.clear();
		save_str.clear();
	}

	int missId;
	int state;
	uint32 time;
	vector<int> save_var;
	vector<string> save_str;
};

struct SFinishedMission
{
	SFinishedMission()
	{
		missId = 0;
		time = 0;
	}
	
	int missId;
	uint32 time;
};

struct SNPC_ActData
{
	SNPC_ActData()
	{
		act_type = 0;
		act_id = 0;
		num = 0;
		dialogIdx = -1;
		str.clear();
	}
	SNPC_ActData(int type,int id,int _num=0,string s="")
	{
		act_type = type;
		act_id = id;
		num = _num;
		dialogIdx = -1;
		str = s;
	}
	
	int act_type;
	int act_id;	// dialogId, fightId, itemId
	int num;	// dialogMaxNum, itemNum
	int dialogIdx;
	string str;
};

struct SNPCInteracter
{
	SNPCInteracter()
	{
		Clear();
	}
	void Clear()
	{
		all_complete = false;
		single_complete = true;
		npcId = 0;
		npcIndex = 0;
		missId = 0;
		actIndex = -1;
		act_list.clear();
	}
	void SetData(int _npcId,int _npcIndex,int _missId,vector<SNPC_ActData> &_act)
	{
		Clear();
		npcId = _npcId;
		npcIndex = _npcIndex;
		missId = _missId;
		act_list = _act;
	}

	SNPC_ActData *GetActSkipDialog()
	{
		if(all_complete)
			return NULL;
		if(act_list.empty())
		{
			all_complete = true;
			return NULL;
		}
		if(actIndex >= (int)act_list.size()-1)
		{
			all_complete = true;
			return NULL;
		}
		single_complete = false;
		actIndex++;

		SNPC_ActData &data = act_list[actIndex];
		if(data.act_type == EMISS_ACT_NOR_DIALOG || data.act_type == EMISS_ACT_WIN_DIALOG || data.act_type == EMISS_ACT_FAIL_DIALOG)
		{
			data.dialogIdx++;
			if(data.dialogIdx == data.num-1)
				single_complete = true;
		}
		else if(data.act_type == EMISS_ACT_FIGHT || data.act_type == EMISS_ACT_ITEM || data.act_type == EMISS_ACT_COLLECT)
		{
			single_complete = true;
		}
		
		if(single_complete && actIndex >= (int)act_list.size()-1)
			all_complete = true;
		return &act_list[actIndex];
	}

	SNPC_ActData *GetAct()
	{
		if(all_complete)
			return NULL;
		if(act_list.empty())
		{
			all_complete = true;
			return NULL;
		}
		if(single_complete)
		{
			if(actIndex >= (int)act_list.size()-1)
			{
				all_complete = true;
				return NULL;
			}
			single_complete = false;
			actIndex++;
		}

		SNPC_ActData &data = act_list[actIndex];
		if(data.act_type == EMISS_ACT_NOR_DIALOG || data.act_type == EMISS_ACT_WIN_DIALOG || data.act_type == EMISS_ACT_FAIL_DIALOG)
		{
			data.dialogIdx++;
			if(data.dialogIdx == data.num-1)
				single_complete = true;
		}
		else if(data.act_type == EMISS_ACT_FIGHT || data.act_type == EMISS_ACT_ITEM || data.act_type == EMISS_ACT_COLLECT)
		{
			single_complete = true;
		}
		
		if(single_complete && actIndex >= (int)act_list.size()-1)
			all_complete = true;
		return &act_list[actIndex];
	}
	bool AllComplete()
	{
		return all_complete;
	}
	void RemoveAct(int type)
	{
		for(vector<SNPC_ActData>::iterator it = act_list.begin();it != act_list.end(); it++)
		{
			if(it->act_type == type)
			{
				act_list.erase(it);
				break;
			}
		}
	}

	bool all_complete;		// 交互是否完成
	bool single_complete;	// 单个是否完成
	int npcId;
	int npcIndex;
	int missId;
	int actIndex;
	vector<SNPC_ActData> act_list;
};

typedef map<int, uint8> missMap;
typedef map<int, uint8>::const_iterator missMapCIt;
// 目标信息
struct StageTarget
{
	StageTarget()
	{
		Clear();
	}

	void Clear()
	{
		idx = 0;
		minlevel = 0;
		maxlevel = 0;
		state = 0;
	}

	uint8 idx; // 从0开始
	uint8 minlevel;
	uint8 maxlevel; // 等级区间 
	uint8 state; // 0 不能领取 1 可以领取 2 已经领取
	vector<SAwardData> awards;
	missMap missIds;
	string title;
};

class CUserMission
{
public:
	CUserMission();

	SAcceptMission *GetAcceptedCMission(int missionId);
	SAcceptMission *NoLockGetAcceptedCMission(int missionId);

	bool IsCMissionAccepted(int missionId);
	bool IsPreCMissionFinished(SMissionConfig &cfg);
	bool IsCMissionFinished(int missionId);
	bool IsInCMissionFinishedList(int missionId);

	bool AddCMission(int missionId,int type,vector<int> &var, vector<string> &str);
	bool DelCMission(int missionId,int sock);
	void DeleteFinishMissionById(int mid);

	void UpdateCMisstionState(int missionId,int state);
	bool UpdateCMission(int missionId,vector<int> &var,vector<string> &str);

	void GetAcceptCMissList(vector<int> &missList);
	
	void UpdateAvailableCMission(vector<int> &avail_miss);
	void GetAvailableCMissions(vector<int> &avail_miss);
	void DelAvailableCMission(int missId);

	void LoadData(const char *pMission);
	void SaveData(string &str);

	void CheckQuestShow(CUser* pUser);
	void GetCMissionsFinishedList(vector<int> &missList);

	void InitQuest();
	void ResetQuest(CUser* pUser);
	void ChechNewQuest();
	void InitJiJin(CUser* pUser, uint8 type);
	void ApplyTaskValidationFixture(CUser* pUser, uint32 activeValue);

public:
	void GetQuestMessage(CUser* pUser, CNetMessage& msg);
	UserQuestMap* GetUserQuestMap(uint8 type);
	UserQuest* GetUserQuest(uint8 type, uint16 id);
	UserQuest* GetHDQuest(uint16 id);
	UserQuestMap* GetJiJinQuestMap(uint8 type);
	UserQuest* GetJiJinQuest(uint8 type, uint16 id);
	uint32 GetBuyTime(uint8 type);

	void GetQuestAward(CUser* pUser, CNetMessage& msg);
	void GetHDQuestMessage(CNetMessage& msg);
	void GetHDQuestAward(CUser* pUser, CNetMessage& msg);
	void GetJiJinQuestMessage(CNetMessage& msg);
	void GetJiJinQuestAward(CUser* pUser, CNetMessage& msg);
	void SendQuestHotPointStatus(CUser* pUser, uint8 type);
	void SendHDQuestHotPointStatus(CUser* pUser);
	SNPCInteracter npc_act;

	bool IsFinishQuest(uint16 tid);
private:
	boost::recursive_mutex m_mutex;
	TypeUserQuestMap m_curQuest;
	TypeUserQuestMap m_jinJinQuest;
	set<uint16> m_finishQuest;
	UserQuestMap m_hdQuest;
	U8tU32Map m_buyTime;
	bool m_taskValidationFixtureActive;
	uint32 m_taskValidationActiveValue;
};

class CMissionManager
{
public:
	CMissionManager();
	bool Init();
	
	SMissionConfig *GetMissionCfg(int missId);
	list<SMissionDialog> *GetDialogCfg(int dialogId);
	int GetDialogCfgMaxNum(int dialogId);
	SMissionDialog *GetDialogString(int dialogId,int idx);

	bool HaveMainCMission(CUser *pUser);
	
	void AcceptCMission(CUser *pUser,SMissionConfig &cfg,vector<int> *pVar=NULL,vector<string> *pStr=NULL);

	bool FinishCMission(CUser *pUser,int missId,bool inFight=false,int fightRound=0);

	void AddCMissionReward(CUser *pUser,int missId,bool inFight=false,int fightRound=0);

	void AddKillMonsterNum(CUser *pUser,int monsterId,int num);
	void AddCollectNum(CUser *pUser,int npcId,int num);
	void AddCompleteCopyNum(CUser *pUser,int copyId);

	bool CheckCMissionNpcInteract(CUser *pUser,int npcId,int index,int missId);

	void SendAvailableCMissionList(CUser *pUser);
	void SendAvailableCMissionInfo(CUser *pUser,int missId);

	void SendCMissionTrackMsg(CUser *pUser,int missId);
	void SendAddCMissionMsg(CUser *pUser,int missId);

	bool PlayNpcAct(CUser *pUser,bool skipDialog=false);

	void StartCMissionFight(CUser *pUser,int missId,int fightId);
	void UpdateCMissionFightState(CUser *pUser,int missId,int round);
	void UpdateCMissionItemState(CUser *pUser,int itemId);

	void Print();

	
	bool VerifyAndAcceptBranchMission(CUser *pUser,SMissionDoingContent &content, vector<int> &save_var,vector<string>& save_str);
	void SendNewBranchTrackMsg(SMissionDoingContent &con,  SAcceptMission *pMiss,vector<SReplaceStringData>& replace);
	void VerifyNewBranchMissionFinish(CUser *pUser, int mid, int num = 1, int cond = 0);  // 在其他模块调用
	void UpdateQuestState(CUser* pUser, uint16 cond, int num = 1, int condex = 0);
	//bool  AwardNewBranchAndDeleteMission(CUser *pUser, int mid, SMissionConfig &cfg , CNetMessage& msg); // 新分支任务领奖并删除任务
	void DoVerifyNewBranchMission(CUser *pUser, int mid, int cur, int isum);
	int GetSMissionDoingContentLevelVal(CUser *pUser, int mid); // 得到任务完成条件的等级要求
	void GetMissionAward(CUser *pUser, int mid); // 前端手动领取任务奖励
	void GetMissionIdByOp(CUser *pUser,int op, std::vector<uint32>& vec);
	void VerifyNewBranchMissionComplate(CUser *pUser, SMissionDoingContent &con,  SAcceptMission *pMiss); // 验证任务是否已经完成

	void UpdateDCMissionComplate(CUser *pUser, int mid, int num = 1, int cond = 0);
	int GetCMissionBackNpcId(int mid);

	void GetStageGoalInfo(CUser *pUser, CNetMessage& msg);
	void UpdateStageGoalState(CUser *pUser, int missId);
	void GetStageGoalAward(CUser *pUser, uint8 idx, CNetMessage& msg);
	void FinishKuaFuRiChang(CUser *pUser, int type);
	bool CheckCMissionCanAccepted(CUser *pUser,SMissionConfig &cfg);

	bool IsMeiRiQuest(uint16 tid);
	QuestCfgMap& GetAllQuest() { return m_questCfg; }
	QuestCfgMap* GetTypeQuest(uint16 type);
	vector<TypeValue>* GetCondTypeIds(uint8 cond);
	QuestCfg* GetQuestCfg(uint16 id);

public:
	QuestCfgMap& GetHDQuestMap() { return m_hdQuestCfg; }
	QuestCfgMap* GetDayQuestMap(uint8 day);
	QuestCfg* GetHDQuestCfg(uint16 id);
	vector<TypeValue>* GetHDCondTypeIds(uint8 cond);

public:
	QuestCfgMap* GetJiJinQuestMap(uint8 type);
	QuestCfg* GetJiJinQuestCfg(uint16 id);
	vector<TypeValue>* GetJiJinCondTypeIds(uint8 cond);
	void UpdateJJQuestState(CUser* pUser, uint8 type, uint16 qtype, int num, int cond);

private:
	void ReadMissionConfig();
	void ReadMissionDialogConfig();
	void ReadMubiaoConfig();
	bool InitQuestCfg();
	bool InitJiJinCfg();
    
	bool CheckBangPaiMissionCanAccepted(int id,uint32 bangPaiId);//检查帮派任务可接（特殊处理）
	bool IsNextMainCMission(CUser *pUser,SMissionConfig &cfg);
	void CMissionToDo(CUser *pUser,vector<SMissionTodo> &todo);
	int GetStageIdx(int missId);
	void MakeKuaFuRiChangMsg(CUser *pUser, SAcceptMission *pMiss, const SMissionConfig& cfg, CNetMessage& msg);
	void UpdateNormalQuestState(CUser* pUser, uint16 qtype, int num, int cond);
	void UpdateHDQuestState(CUser* pUser, uint16 qtype, int num, int cond);
	void UpdateJJQuestState(CUser* pUser, uint16 qtype, int num, int cond);
	bool CheckQuestState(CUser* pUser, UserQuest* quest, QuestCfg* cfg, int num, int cond);
		//	boost::recursive_mutex m_mutex;
	boost::unordered_map<int,SMissionConfig> m_missions;
	boost::unordered_map<int,list<SMissionDialog> > m_dialogs;

	typedef map<int, StageTarget> stageMap;
	typedef map<int, StageTarget>::iterator stageMapIt;
	stageMap m_allStages;
	QuestCfgMap m_questCfg;
	TypeQuestCfgMap m_typeQuestCfg;
	CondTypeIdMap m_condTypeIds;
	NextQuestMap m_nextQuests;

	QuestCfgMap m_hdQuestCfg;
	TypeQuestCfgMap m_hdDayQuestCfg;
	CondTypeIdMap m_hdCondTypeIds;
	U16tU8Map m_meiRiIds;

	QuestCfgMap m_jjQuestCfg;
	TypeQuestCfgMap m_jjTypeQuestCfg;
	CondTypeIdMap m_jjCondTypeIds;

public:
	static uint16 HDOpenDay;
	static uint16 HDCotinueDay;
};

typedef boost::details::pool::singleton_default<CMissionManager> SingletonCMissionManager;
#define sCMissionManager SingletonCMissionManager::instance()

#endif
